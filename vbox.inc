;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2004-2022. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;         Writen by Maxim Logaev (turbocat2001)                ;;
;;                      2022 year                               ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include 'inc/struct.inc'

PCI_VBOX_VENDOR_ID = 0x80EE
PCI_VBOX_DEVICE_ID = 0xCAFE

VBOX_VMMDEV_VERSION         = 0x10003
VBOX_REQUEST_HEADER_VERSION = 0x10001

VBOX_VMM_REPORT_GUEST_INFO      = 50
VBOX_REQUEST_GET_DISPLAY_CHANGE = 51
VBOX_REQUEST_SET_GUEST_CAPS     = 55
VBOX_REQUEST_ACK_EVENTS         = 41
VBOX_REQUEST_GET_MOUSE          = 1
VBOX_REQUEST_SET_MOUSE          = 2

VBOX_VMM_EVENT_DISP  = 4
VBOX_VMM_EVENT_MOUSE = 0x200

VBOX_ABS_MOUSE_WANT = (1 SHL 0)
VBOX_ABS_MOUSE_POS  = (1 SHL 4)


struct VBOX_HEADER
        size            dd ?
        version         dd ?
        request_type    dd ?
        rc              dd ?
        __reserved1     dd ?
        __reserved2     dd ?
ends

struct VBOX_GUEST_INFO
        header          VBOX_HEADER
        version         dd ?
        os_type         dd ?
ends

struct VBOX_GUEST_CAPS
        header          VBOX_HEADER
        caps            dd ?
ends

struct VBOX_ACK_EVENTS
        header          VBOX_HEADER
        events          dd ?
ends

struct VBOX_DISPLAY_CHANGE
        header          VBOX_HEADER
        x_res           dd ?
        y_res           dd ?
        bpp             dd ?
        event_ack       dd ?
ends

struct VBOX_MOUSE
        header          VBOX_HEADER
        features        dd ?
        x               dd ?
        y               dd ?
ends

struct VBOX_RTRECT
        x_left          dd ?
        y_top           dd ?
        x_right         dd ?
        y_bottom        dd ?
ends

struct VBOX_VISIBLE_REGION
        header          VBOX_HEADER
        count           dd ?
        rect            VBOX_HEADER 1
ends

struct VBOX_POINTER_SHAPE
        header          VBOX_HEADER
        flags           dd ?
        x_hot           dd ?
        y_hot           dd ?
        width           dd ?
        height          dd ?
        data            rb 1
ends

; in:      eax - pack phys addr
; corrupt: edx
macro vbox_send_pack
{
        mov     dx, [vbox_device.port]
        out     dx, eax
}
