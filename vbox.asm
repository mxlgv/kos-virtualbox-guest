;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2004-2022. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format PE DLL native
entry START

DEBUG                   = 1
__DEBUG__               = 1
__DEBUG_LEVEL__         = 1

include 'inc/proc32.inc'
include 'inc/struct.inc'
include 'inc/macros.inc'
include 'inc/pci.inc'
include 'inc/fdo.inc'

include 'vbox.inc'

section '.flat' readable writable executable

proc START c, state, cmdline : dword
        cmp     [state], DRV_ENTRY
        jne     .fail

        DEBUGF  1,"[vboxvid]: Start driver\n"

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
        DEBUGF  1,"[vboxvid]: Device found!\n"

        ; Get IRQ number and attach handler.
        mov     ebx, eax
        invoke  PciRead32, dword [ebx + PCIDEV.bus], dword [ebx + PCIDEV.devfn], PCI_header00.interrupt_line
        movzx   eax, al
        invoke  AttachIntHandler, eax, vbox_irq_handler, 0

        ; Get vbox IO port.
        invoke  PciRead32, dword [ebx + PCIDEV.bus], dword [ebx + PCIDEV.devfn], PCI_header00.base_addr_0
        and     al, not 0xF
        DEBUGF  1,"[vboxvid]: Port %x\n", eax
        mov     word [vbox_device.port], ax

        ; Create mapping for MMIO.
        invoke  PciRead32, dword [ebx + PCIDEV.bus], dword [ebx + PCIDEV.devfn], PCI_header00.base_addr_1
        and     al, not 0xF
        DEBUGF  1,"[vboxvid]: MMIO phy %x\n", eax
        invoke  MapIoMem, eax, 0x10000, PG_NOCACHE + PG_SW
        DEBUGF  1,"[vboxvid]: MMIO virt %x\n", eax
        mov     [vbox_device.mmio], eax

        ; Allocate space for packets and send if needed.
        mov     esi, const_vbox_guest_info
        mov     ecx, sizeof.VBOX_GUEST_INFO
        call    create_pack
        call    send_pack

        mov     esi, const_vbox_guest_caps
        mov     ecx, sizeof.VBOX_GUEST_CAPS
        call    create_pack
        call    send_pack

        mov     esi, const_vbox_ack
        mov     ecx, sizeof.VBOX_ACK_EVENTS
        call    create_pack
        mov     [vbox_device.ack_addr.phys], eax
        mov     [vbox_device.ack_addr.virt], ebx

        mov     esi, const_vbox_display
        mov     ecx, sizeof.VBOX_DISPLAY_CHANGE
        call    create_pack
        mov     [vbox_device.display_addr.phys], eax
        mov     [vbox_device.display_addr.virt], ebx

        ; Enable interrupts for declared capabilities (enable all).
        xor     eax, eax
        dec     eax
        mov     ebx, [vbox_device.mmio]
        mov     [ebx + 12], eax
        add     ebx, 12

        invoke  RegService, service_name, service_proc
        ret

  .dev_not_found:
        DEBUGF  1,"[vboxvid]: Device not found!\n"
  .fail:
        xor     eax, eax
        ret
endp


; in:   esi - template
;       ecx - template size
;
; out:  ebx - virt
;       eax - phys

proc create_pack
        push    ecx
        invoke  AllocPage
        mov     ebx, eax
        invoke  MapIoMem, ebx, 0x1000, PG_NOCACHE + PG_SW

        mov     edi, eax
        pop     ecx
        shr     ecx, 2
        rep movsd

        xchg    eax, ebx
        ret
endp


; in:   eax - pack phys addr
proc send_pack
        mov     dx, [vbox_device.port]
        DEBUGF  1,"[vboxvid]: Send pack to port %x data-phys %x\n", dx, eax
        out     dx, eax
        ret
endp


align 4
proc service_proc stdcall, ioctl:dword
        or      eax, -1
        ret
endp


align 4
proc vbox_irq_handler
        pushad

        DEBUGF  1,"[vboxvid]: Interrupt\n"

        mov     eax, [vbox_device.mmio]
        mov     eax, [eax + 8]
        test    eax, eax
        jz      .skip

        mov     ebx, [vbox_device.ack_addr.virt]
        mov     [ebx + VBOX_ACK_EVENTS.events], eax

        mov     eax, [vbox_device.ack_addr.phys]
        call    send_pack

        mov     eax, [vbox_device.display_addr.phys]
        call    send_pack

        mov     ebx, [vbox_device.display_addr.virt]
        DEBUGF  1,"[vboxvid]: New %d x %d - %d\n", [ebx + VBOX_DISPLAY_CHANGE.x_res], [ebx + VBOX_DISPLAY_CHANGE.y_res], [ebx + VBOX_DISPLAY_CHANGE.bpp]


;        mov     eax, [ebx + VBOX_DISPLAY_CHANGE.x_res]
;        mov     edx, [ebx + VBOX_DISPLAY_CHANGE.y_res]
;        mov     ecx, [ebx + VBOX_DISPLAY_CHANGE.bpp]
;        dec     eax
;        dec     edx
;        invoke  SetScreen

  .skip:
        popad
        xor     eax, eax
        inc     eax
        ret
endp


data fixups
end data

include 'inc/peimport.inc'

service_name: db 'vbox', 0

vbox_device:
  .port               dw 0
  .mmio               dd 0
  .ack_addr.virt      dd 0
  .ack_addr.phys      dd 0
  .display_addr.virt  dd 0
  .display_addr.phys  dd 0

const_vbox_guest_info VBOX_GUEST_INFO \
        <sizeof.VBOX_GUEST_INFO, \
         VBOX_REQUEST_HEADER_VERSION, \
         VBOX_VMM_REPORT_GUEST_INFO, \
         0, \
         0, \
         0>, \
         VBOX_VMMDEV_VERSION, \
         0

const_vbox_guest_caps VBOX_GUEST_CAPS \
        <sizeof.VBOX_GUEST_CAPS, \
         VBOX_REQUEST_HEADER_VERSION, \
         VBOX_REQUEST_SET_GUEST_CAPS, \
         0, \
         0, \
         0>, \
         1 SHL 2

const_vbox_ack VBOX_ACK_EVENTS \
        <sizeof.VBOX_ACK_EVENTS, \
         VBOX_REQUEST_HEADER_VERSION, \
         VBOX_REQUEST_ACK_EVENTS, \
         0, \
         0, \
         0>, \
         0

const_vbox_display VBOX_DISPLAY_CHANGE \
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
