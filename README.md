# kos-virtualbox-guest

VirtualBox Guest Additions driver for KolibriOS.

## Features
Already allows you to automatically adapt the screen resolution when you change the size of the VM window.

## Building
Need [FASM](https://flatassembler.net/). At the output you will get the vbox.sys file.

`fasm vbox.asm`

## Usage
Copy the driver to the /sys/drivers/ folder. Start **SHELL** and run:

`loaddrv vbox`

To load the driver automatically add `/SYS/LOADDRV VBOX 1` to **/sys/settings/autorun.dat**
