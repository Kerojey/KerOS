CC=g++
CC_FLAGS=-nostdlib -nostdlib++ -nodefaultlibs -fno-pic -ffreestanding -Os -m32 -mno-red-zone -fno-stack-protector
BOOT=boot
temp=objcopy -O binary final.bin final.bin &

install:
	nasm -f elf32 -g switchMode.s
	$(CC) $(CC_FLAGS) -c -g entry.cpp
	$(CC) $(CC_FLAGS) -c -g vga.cpp
	$(CC) $(CC_FLAGS) -c -g video.cpp
	$(CC) $(CC_FLAGS) -T linker.ld -masm=intel -lgcc video.o vga.o switchMode.o entry.o -o temp.elf
	objcopy -O binary temp.elf temp.bin
	dd if=temp.bin of=final.bin bs=512 conv=sync
	nasm -f bin $(BOOT).s

run: install
	qemu-system-i386 $(BOOT)

debug: install
	qemu-system-i386 -S -s $(BOOT) &
debugb: debug
	gdb -ex "target remote localhost:1234" -ex "b *0x7c00" -ex "layout asm" -ex "set disassembly-flavor intel"
debugk: debug
	gdb -ex "target remote localhost:1234" -ex "layout src" -ex "file temp.elf" -ex "b kernel_main" -ex "set disassembly-flavor intel"
