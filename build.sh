#!/bin/bash

set -e

IMG=kolibri.img
DRV=vbox.sys

check_utils()
{
    printf "%s: " $1
    if command -v $1 &> /dev/null
    then
        echo -e "ok\r"
    else
        echo -e "no\r"
    fi
}

check_utils fasm
check_utils kpack
check_utils mcopy

if [ ! -e "$IMG" ]; then
    echo "File $IMG does not exist"
    exit
fi

fasm vbox.asm
EXENAME=$DRV fasm pestrip.asm $DRV
kpack $DRV
mcopy -D o -i $IMG $DRV ::drivers/$DRV

echo -e "Done.\r"
