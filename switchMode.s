%macro x86_EnterRealMode 0
    [bits 32]
    jmp word 18h:.pmode16         ; 1 - jump to 16-bit protected mode segment

.pmode16:
    [bits 16]
    ; 2 - disable protected mode bit in cr0
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    ; 3 - jump to real mode
    jmp word 00h:.rmode

.rmode:
    ; 4 - setup segments
    mov ax, 0
    mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

    ; 5 - enable interrupts
    sti

%endmacro


%macro x86_EnterProtectedMode 0
    cli

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode


.pmode:
    ; we are now in protected mode!
    [bits 32]
    
    ; 6 - setup segment registers
    mov ax, 0x10
    mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

%endmacro
EnterRealMode:
    [bits 32]
    jmp word 18h:.pmode16         ; 1 - jump to 16-bit protected mode segment

.pmode16:
    [bits 16]
    ; 2 - disable protected mode bit in cr0
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    ; 3 - jump to real mode
    jmp word 00h:.rmode

.rmode:
    ; 4 - setup segments
    mov ax, 0
    mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
    sti
    ret


EnterProtectedMode:
    cli

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode


.pmode:
    ; we are now in protected mode!
    [bits 32]
    
    ; 6 - setup segment registers
    mov ax, 0x10
    mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
    ret

global asm_func
asm_func:
	[bits 32]

    ; make new call frame
    push ebp             ; save old call frame
    mov ebp, esp         ; initialize new call frame

    ;x86_EnterRealMode
    call EnterRealMode


    [bits 16]
    ; save regs
    ;push es
    ;push bx
    ;push esi
    ;push di

	mov ax, 0x4F02
	mov bx, 0x101
	int 0x10

    ; restore regs
    ;pop di
    ;pop esi
    ;pop bx
    ;pop es

    ; return
    ;push eax
    ;x86_EnterProtectedMode
    call EnterProtectedMode

    [bits 32]
    ;pop eax
    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret

outb:
    [bits 32]
    mov dx, [esp + 4]
    mov al, [esp + 8]
    out dx, al
    ret

inb:
    [bits 32]
    mov dx, [esp + 4]
    xor eax, eax
    in al, dx
    ret
global memory_0000
memory_0000:
    [bits 32]
    push ebp
    mov ebp, esp
    call EnterRealMode
    [bits 16]
    clc
    xor eax, eax
    int 0x12
    call EnterProtectedMode
    [bits 32]
    mov esp, ebp
    pop ebp
    ret
    
global memory_e820 
memory_e820: ; SMAP 53 4D 41 50
    [bits 32]
	mov ebx, [esp + 4] ; int ebx
	mov ecx, [esp + 8] ; int addr
	mov edx, [esp + 12] ; int di
    x86_EnterRealMode
    [bits 16]
	mov es, ecx
	mov edi, edx
    mov edx, 0x534d4150
	;mov dword [es:di + 20], 1
    mov ecx, 20
    mov eax, 0x0000E820
	int 0x15
	jc .error
	;cmp eax, 0x534d4150
	;jne .error
	mov [es:di+20], ebx
	x86_EnterProtectedMode
    [bits 32]
	;pop ax
    mov eax, 0
	ret
	[bits 16]
.error:
	mov eax, 0xB8000
	mov byte [eax+10], 'E'
	mov eax, 1
	ret
	[bits 32]

global memory_8800
memory_8800:
    [bits 32]
    push ebp
    mov ebp, esp
    x86_EnterRealMode
    [bits 16]
    mov eax, 0x8800
	int 0x15
	jc .error
.end:
    push eax
    x86_EnterProtectedMode
    [bits 32]
    pop eax
    mov esp, ebp
    pop ebp
    ret
	[bits 16]
.error:
	mov ax, 0
	jmp .end
	[bits 32]

global memory_8A00
memory_8A00:
    [bits 32]
    push ebp
    mov ebp, esp
    x86_EnterRealMode
    [bits 16]
    mov eax, 0x8A00
	int 0x15
	jc .error
.end:
	shl eax, 16
	or eax, edx
    push eax
    x86_EnterProtectedMode
    [bits 32]
    pop eax
    mov esp, ebp
    pop ebp
    ret
	[bits 16]
.error:
	mov ax, 0
	jmp .end
	[bits 32]
