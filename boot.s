[bits 16]
[org 0x7c00]

;%define DATA_OFFSET (0x500)
%define DATA_OFFSET 		 (0x500)
;%define DATA_OFFSET 		 (0x600)
%define KERNEL_MAIN_LOCATION ((DATA_OFFSET<<4))
%define BIOS_READ_DISK_FUNC  0x02
ScreenBuffer                 equ (0xB8000)
StackPTR					 equ (0x90000-0x1000)

global boot
boot:
    jmp _main
    ; Fake BPB
    TIMES 3 DB 0x90   ; Support 2 or 3 byte encoded JMPs before BPB.
    TIMES 34 DB 0xAA
_main:
	cli
	mov [drive], dl
	xor ax, ax
	mov ss, ax
    mov ds, ax
	;mov sp, boot
	mov sp, 0x7b00
	sti

	;call enable_a20
	;jc end
	call read_disk
	call LoadGDT
	;mov dword [pmode_ptr], KERNEL_MAIN_LOCATION
	;jmp print
	jmp switch_pm
read_disk:
	mov ax, 0x0201
    mov bx, DATA_OFFSET
	mov es, bx
	mov cx, 0x0002         ; cylinder 0 + starting from sector 2 (1 is boot sector)
	mov dl, [drive]        ; disk drive
    mov dh, 0x00
	xor bx, bx
    ; 1 sector = 512 bytes
	; es = address where to put it
    ;mov cx, 0x0002         ; cylinder 0 + starting from sector 2 (1 is boot sector)
.read_sector_loop:
    int 0x13
    jc end
    ; increment sector number
    inc cx
    mov ax, 0x0201;BIOS_READ_DISK_FUNC << 4 + 1 ; read disk function (0x2) + 1 sector to read
    mov dl, [drive]        ; disk drive
    mov dh, 0x00
	mov bx, es
	add bx, 0x20
	mov es, bx
    xor bx, bx
    cmp cx, (file_sectors + 2)
    jl .read_sector_loop
    ret
;read_disk:
;	; 1 sector = 512 bytes
;	mov ax, (BIOS_READ_DISK_FUNC << 8) + file_sectors   ; read disk function (0x2) + read sectors equals to file size
;	mov cx, 0x0002         ; cylinder 0 + starting from sector 2 (1 is boot sector)
;	mov dl, [drive]        ; disk drive
;	mov dh, 0x00
;	mov bx, DATA_OFFSET
;	mov es, bx
;	xor bx, bx
;	int 0x13
;	jc end
;	ret
; bx = ptr to str
print:
	;xor cx, cx
	;mov di, cx
	;mov si, cx
	
	;mov ax, bx
	;add si, 0
	;mov es, bx;ax
	;mov cx, 0xB800
	;mov ds, cx
	
_printLoop:
	;mov byte al, [bx+1]
	;cmp al, 0x0
	;je _endLoop
	;mov byte [ds:di+0], al
	;mov byte [ds:di+1], 4
	;inc bx
	;add di, 2
	;jmp _printLoop
_endLoop:
	;jmp $
	
end: jmp end

%include "a20.s"
;%include "gdt.s"
[bits 16]
LoadGDT:
	;mov ax, 0x4F02
	;mov bx, 0x101
	;int 0x10
    cli
    lgdt [g_GDTDesc]
    ret
switch_pm:
	mov eax, cr0
    or ax, 1
    mov cr0, eax

    ; far jump into protected mode
    jmp 08h:.pmode

[bits 32]
.pmode:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	
	mov ebp, StackPTR
    mov esp, ebp
	call 0x08:KERNEL_MAIN_LOCATION
    jmp $
	;mov eax, [pmode_ptr]
	;jmp eax

g_GDT:      ; NULL descriptor
            dq 0

            ; 32-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 32-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

g_GDTDesc:  dw g_GDTDesc - g_GDT - 1    ; limit = size of GDT
            dd g_GDT                    ; address of GDT

drive_error_str db "Disk error", 0
drive db 0x00

times 510 - ($-$$) db 0
dw 0xAA55

file_start:
incbin "final.bin"
file_end:
file_size equ file_end - file_start
%assign file_size file_size
%assign file_div (file_size / 512)
%assign file_modulo (1*(file_size %% 512 != 0))
file_sectors equ (file_div + file_modulo)

%warning C++ files: file_size bytes
