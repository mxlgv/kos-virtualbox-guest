# kos-virtualbox-guest

[![Build](https://github.com/turbocat2001/kos-virtualbox-guest/actions/workflows/build.yml/badge.svg)](https://github.com/acidicMercury8/kos-virtualbox-guest/actions/workflows/build.yml)

VirtualBox Guest Additions driver for __KolibriOS__

## Features

The driver allows you to automatically adapt the screen resolution on changing the size of the virtual machine window

## Building

- Get [FASM](https://flatassembler.net/)
- Run `fasm vbox.asm`

As a result `vbox.sys` file will be get

## Usage

It's highly recommended __closing `@taskbar` application__. It crashes the OS when changing resolution frequently (should be fixed!)

- Copy the driver to `/sys/drivers/` folder
- Start `SHELL`
- Run `loaddrv vbox`

To load the driver automatically add `/SYS/LOADDRV VBOX 0` to `/sys/settings/autorun.dat`

## License

This project licensed under the terms of __GNU GPL 2.0__ license. See [this](./LICENSE) for details
