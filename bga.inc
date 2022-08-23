;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2004-2022. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;         Writen by Maxim Logaev (turboca2001)                 ;;
;;                      2022 year                               ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VBE_DISPI_IOPORT_INDEX = 0x01CE
VBE_DISPI_IOPORT_DATA  = 0x01CF

VBE_DISPI_BPP_4  = 0x04
VBE_DISPI_BPP_8  = 0x08
VBE_DISPI_BPP_15 = 0x0F
VBE_DISPI_BPP_16 = 0x10
VBE_DISPI_BPP_24 = 0x18
VBE_DISPI_BPP_32 = 0x20

VBE_DISPI_DISABLED = 0
VBE_DISPI_ENABLED  = 1

VBE_DISPI_LFB_ENABLED = 0x40

VBE_DISPI_INDEX_ID          = 0
VBE_DISPI_INDEX_XRES        = 1
VBE_DISPI_INDEX_YRES        = 2
VBE_DISPI_INDEX_BPP         = 3
VBE_DISPI_INDEX_ENABLE      = 4
VBE_DISPI_INDEX_BANK        = 5
VBE_DISPI_INDEX_VIRT_WIDTH  = 6
VBE_DISPI_INDEX_VIRT_HEIGHT = 7
VBE_DISPI_INDEX_X_OFFSET    = 8
VBE_DISPI_INDEX_Y_OFFSET    = 9


macro bga_write_reg index_val, data_val
{
        mov eax, index_val
        mov dx, VBE_DISPI_IOPORT_INDEX
        out dx, ax
        mov eax, data_val
        mov dx, VBE_DISPI_IOPORT_DATA
        out dx, ax
}

macro bga_set_video_mode w, h, bpp
{
        bga_write_reg VBE_DISPI_INDEX_ENABLE, VBE_DISPI_DISABLED
        bga_write_reg VBE_DISPI_INDEX_XRES, w
        bga_write_reg VBE_DISPI_INDEX_YRES, h
        bga_write_reg VBE_DISPI_INDEX_BPP, bpp
        bga_write_reg VBE_DISPI_INDEX_ENABLE, VBE_DISPI_ENABLED ;or VBE_DISPI_LFB_ENABLED
}
