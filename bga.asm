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
include 'bga.inc'


struct  RWSEM
        wait_list       LHEAD
        count           dd ?
ends

struct  DISPLAY
        x               dd ?
        y               dd ?
        width           dd ?
        height          dd ?
        bits_per_pixel  dd ?
        vrefresh        dd ?
        lfb             dd ?
        lfb_pitch       dd ?

        win_map_lock    RWSEM
        win_map         dd ?
        win_map_pitch   dd ?
        win_map_size    dd ?

        modes           dd ?
        ddev            dd ?
        connector       dd ?
        crtc            dd ?

        cr_list.next    dd ?
        cr_list.prev    dd ?

        cursor          dd ?

        init_cursor     dd ?
        select_cursor   dd ?
        show_cursor     dd ?
        move_cursor     dd ?
        restore_cursor  dd ?
        disable_mouse   dd ?
        mask_seqno      dd ?
        check_mouse     dd ?
        check_m_pixel   dd ?

        bytes_per_pixel dd ?
ends


struct FRB
        list            LHEAD
        magic           rd 1
        handle          rd 1
        destroy         rd 1

        width           rd 1
        height          rd 1
        pitch           rd 1
        format          rd 1
        private         rd 1
        pde             rd 8
ends



section '.flat' readable writable executable


proc START stdcall, state, cmdline : dword
        cmp     [state], DRV_ENTRY
        jne     .fail

        cli
        bga_set_video_mode 1024, 768, VBE_DISPI_BPP_32

      ;  invoke  PciRead32,  0x80EE, 0xBEEF, PCI_header00.base_addr_0
      ;  and     al, not 0xF

        sti

        mov     ecx, 1024
        add     ecx, 15
        and     ecx, not 15
        shl     ecx, 2

        invoke  GetDisplay

        mov     dword [eax + DISPLAY.width], 1024
        mov     dword [eax + DISPLAY.height], 768
        mov     dword [eax + 18h], ecx
        ;mov     ebx, [lfb]
        ;mov     [eax + DISPLAY.lfb], ebx

      ;  mov     ecx, [lfb]
       ; mov     [eax + FBR.


       ; call    [SetFramebuffer]

        mov     eax, 1024
        mov     edx, 768

        dec     eax
        dec     edx
        call    [SetScreen]

        ret

  .fail:
        xor     eax, eax
        ret
endp




data fixups
end data

include 'inc/peimport.inc'

service_name: db 'bga', 0

;include_debug_strings
