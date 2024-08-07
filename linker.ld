OUTPUT_FORMAT(elf32-i386)
ENTRY(kernel_main)

MEM_POS = 0x5000;

MEMORY
{
  RAM (rwx) : ORIGIN = MEM_POS, LENGTH = MEM_POS + end
  STACK (rw) : ORIGIN = MEM_POS + end, LENGTH = 0x400
}

SECTIONS {
  . = MEM_POS;
  .text MEM_POS : AT(MEM_POS)
  {
    code = .;
    entry.o (.text)
    *(.text)
  } > RAM

  .data   : AT(MEM_POS + (data - code))    { data   = .;  *(.data)   } > RAM
  .rodata : AT(MEM_POS + (rodata - code))  { rodata = .;  *(.rodata) } > RAM
  .bss    : AT(MEM_POS + (bss - code))     { bss    = .;  *(.bss)    } > RAM
  end = .;
  .stack : AT(end) { KEEP(*(.stack)); *(.stack); stack = .; } > STACK

  /DISCARD/ :
  {
  	*(.comment)
  	*(.eh_frame)
  	*(.note.gnu.build-id)
  }
}
