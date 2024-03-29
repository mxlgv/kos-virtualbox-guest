;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2004-2023. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;         Written by Maxim Logaev (turbocat2001)               ;;
;;                      2022-2023 year                          ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format PE DLL native
entry START

DEBUG                   = 1
__DEBUG__               = 1
__DEBUG_LEVEL__         = 2

include 'inc/proc32.inc'
include 'inc/struct.inc'
include 'inc/macros.inc'
include 'inc/pci.inc'
include 'inc/fdo.inc'

include 'vbox.inc'
include 'bga.inc'

KOS_DISP_W_MIN = 640
KOS_DISP_H_MIN = 480

KOS_DISP_W_MAX = 3840
KOS_DISP_H_MAX = 2160

section '.flat' readable writable executable

proc START c, state, cmdline : dword
        push    ebx esi edi
        cmp     [state], DRV_ENTRY
        jne     .fail

        DEBUGF  2,"[vbox]: Start driver\n"

        invoke  GetPCIList
        mov     ebx, eax

  .find_dev:
        cmp     [eax + PCIDEV.vendor_device_id], PCI_VBOX_VENDOR_ID + (PCI_VBOX_DEVICE_ID SHL 16)
        jz      .dev_found
        mov     eax, [eax + PCIDEV.fd]
        cmp     ebx, eax
        jz      .dev_not_found
        jmp     .find_dev

  .dev_found:
        DEBUGF  2,"[vbox]: Device found!\n"

        ; Get address of "display" structure in kernel.
        invoke  GetDisplay
        mov     [kos_display_ptr], eax

        ; Get IRQ number and attach handler.
        mov     ebx, eax
        invoke  PciRead32, dword [ebx + PCIDEV.bus], dword [ebx + PCIDEV.devfn], PCI_header00.interrupt_line
        movzx   eax, al
        invoke  AttachIntHandler, eax, vbox_irq_handler, 0

        ; Get vbox IO port.
        invoke  PciRead32, dword [ebx + PCIDEV.bus], dword [ebx + PCIDEV.devfn], PCI_header00.base_addr_0
        and     al, not 0xF
        DEBUGF  1,"[vbox]: Port %x\n", eax
        mov     [vbox_device.port], ax

        ; Create mapping for MMIO.
        invoke  PciRead32, dword [ebx + PCIDEV.bus], dword [ebx + PCIDEV.devfn], PCI_header00.base_addr_1
        and     al, not 0xF
        DEBUGF  1,"[vbox]: MMIO phy %x\n", eax
        invoke  MapIoMem, eax, 0x1000, PG_NOCACHE + PG_SW
        DEBUGF  1,"[vbox]: MMIO virt %x\n", eax
        mov     [vbox_device.mmio], eax

        ; Sending packets for initialization
        mov     eax, vbox_guest_info
        invoke  GetPhysAddr
        vbox_send_pack

        mov     eax, vbox_guest_caps
        invoke  GetPhysAddr
        vbox_send_pack

        mov     eax, vbox_ack
        mov     [vbox_device.ack_addr.virt], eax
        invoke  GetPhysAddr
        mov     [vbox_device.ack_addr.phys], eax

        mov     eax, vbox_display
        mov     [vbox_device.display_addr.virt], eax
        invoke  GetPhysAddr
        mov     [vbox_device.display_addr.phys], eax

        ; Enable interrupts for declared capabilities (enable all).
        xor     eax, eax
        dec     eax
        mov     ebx, [vbox_device.mmio]
        mov     [ebx + 12], eax

        call    set_display_res

        invoke  RegService, service_name, service_proc
        pop     edi esi ebx
        ret

  .dev_not_found:
        DEBUGF  2,"[vbox]: Device not found!\n"
  .fail:
        pop     edi esi ebx
        xor     eax, eax
        ret
endp


proc service_proc stdcall, ioctl:dword
        xor     eax, eax
        dec     eax
        ret
endp


proc set_display_res
        ; Request display change information.
        mov     eax, [vbox_device.display_addr.phys]
        vbox_send_pack
        mov     ebx, [vbox_device.display_addr.virt]
        mov     edi, [ebx + VBOX_DISPLAY_CHANGE.x_res]
        mov     esi, [ebx + VBOX_DISPLAY_CHANGE.y_res]
        mov     ecx, [ebx + VBOX_DISPLAY_CHANGE.bpp]

        ; Skip if mode is less than minimum.
        cmp     edi, KOS_DISP_W_MIN
        jb      .skip
        cmp     esi, KOS_DISP_H_MIN
        jb      .skip
        cmp     edi, KOS_DISP_W_MAX
        ja      .skip
        cmp     esi, KOS_DISP_W_MAX
        ja      .skip
        cmp     ecx, VBE_DISPI_BPP_32
        jz      .cont
        cmp     ecx, VBE_DISPI_BPP_24
        jz      .cont
        cmp     ecx, VBE_DISPI_BPP_16
        jz      .cont
        cmp     ecx, VBE_DISPI_BPP_8
        jnz     .skip
  .cont:
        DEBUGF  1,"[vbox]: new %dx%d %d\n", edi, esi, ecx

        ; Change video mode using Bochs Graphics Adapter
        cli
        bga_set_video_mode edi, esi, ecx
        sti

        mov     ebx, ecx
        ; Calculate scanline (x_res*bpp/8)
        shr     ecx, BSF 8
        imul    ecx, edi

        mov     eax, [kos_display_ptr]
        mov     [eax + DISPLAY.width], edi
        mov     [eax + DISPLAY.height], esi
        mov     [eax + DISPLAY.bits_per_pixel], ebx

        mov     eax, edi
        mov     edx, esi
        dec     eax
        dec     edx
        invoke  SetScreen
  .skip:
        ret
endp


proc vbox_irq_handler stdcall
        push    ebx esi edi

        DEBUGF  1,"[vbox]: Interrupt\n"

        mov     eax, [vbox_device.mmio]
        mov     eax, [eax + 8]

        ; Skip non-resolution events
        test    eax, VBOX_VMM_EVENT_DISP
        jz      .skip

        ; Event acknowledgment
        mov     ebx, [vbox_device.ack_addr.virt]
        mov     [ebx + VBOX_ACK_EVENTS.events], eax
        mov     eax, [vbox_device.ack_addr.phys]
        vbox_send_pack

        call    set_display_res

  .skip:
        pop     edi esi ebx
        xor     eax, eax
        inc     eax
        ret
endp


service_name:           db 'VBOX', 0
version_str:            db '1.1', 0

align 4
vbox_device:
  .port                 dw 0
  .mmio                 dd 0
  .ack_addr.virt        dd 0
  .ack_addr.phys        dd 0
  .display_addr.virt    dd 0
  .display_addr.phys    dd 0

kos_display_ptr:        dd ?
; Prepared packages for sending requests to virtual box
vbox_guest_info VBOX_GUEST_INFO \
        <sizeof.VBOX_GUEST_INFO, \
         VBOX_REQUEST_HEADER_VERSION, \
         VBOX_VMM_REPORT_GUEST_INFO, \
         0, \
         0, \
         0>, \
         VBOX_VMMDEV_VERSION, \
         0

vbox_guest_caps VBOX_GUEST_CAPS \
        <sizeof.VBOX_GUEST_CAPS, \
         VBOX_REQUEST_HEADER_VERSION, \
         VBOX_REQUEST_SET_GUEST_CAPS, \
         0, \
         0, \
         0>, \
         1 SHL 2

vbox_ack VBOX_ACK_EVENTS \
        <sizeof.VBOX_ACK_EVENTS, \
         VBOX_REQUEST_HEADER_VERSION, \
         VBOX_REQUEST_ACK_EVENTS, \
         0, \
         0, \
         0>, \
         0

vbox_display VBOX_DISPLAY_CHANGE \
        <sizeof.VBOX_DISPLAY_CHANGE, \
         VBOX_REQUEST_HEADER_VERSION, \
         VBOX_REQUEST_GET_DISPLAY_CHANGE, \
         0, \
         0, \
         0>, \
         0, \
         0, \
         0, \
         1 \

include_debug_strings

data fixups
end data

include 'inc/peimport.inc'
