/*

void init_video_mode(void) {
    asm volatile (
        ".intel_syntax\n"
        "mov ah, 0x0\n"
        "mov al, 0x3\n"
        "int 0x10\n"
    );
}
void print(void) {
    
}*/
void sleep(void) {
    for (int i = 0; i <= 599999999; i++) {
		asm volatile("nop\n");
	}
}
void end(void) {
    asm volatile (
        "gg:\n"
//        "hlt\n"
        "jmp gg\n"
    );
}
