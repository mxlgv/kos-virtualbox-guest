rm vbox.sys
fasm vbox.asm
mcopy -D o -i kolibri.img vbox.sys ::drivers/vbox.sys
