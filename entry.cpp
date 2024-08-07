#include "video.hpp"
#include "vga.hpp"

typedef struct {
	uint32_t base_addr_high;
	uint32_t base_addr_low;
	uint32_t length_high;
	uint32_t length_low;
	uint32_t type;
	uint32_t res;
} __attribute__((packed)) Mem_E820;

typedef struct {
	uint16_t low;
	uint16_t high;	
} __attribute__((packed)) Mem_8A00;

extern "C" int memory_e820(uint32_t ebx, uint32_t addr, uint32_t di);
extern "C" int memory_0000();
extern "C" int memory_8800(); // number of kb
extern "C" int memory_8A00(); // mem & 0xffff, (mem >> 16) & 0xffff
extern "C" void asm_func(void);

extern "C" void kernel_main(void) {
    terminal_clear();

	terminal_printf("Welcome to KerojeyOS!\n");
	terminal_setcolor(VGA_COLOR_RED, VGA_COLOR_BLACK);
	terminal_printf("No loonix fans welcomed\n\n");
	terminal_setcolor(VGA_COLOR_GREEN, VGA_COLOR_BLACK);
	terminal_printf("Memory space detected:\n");

	uint32_t res = 0;
	Mem_E820 mem;
	volatile uint32_t addr = (unsigned int)&mem >> 4;
	volatile uint32_t di = (unsigned int)&mem & 0xf;
	
	while (1) {
		int err = memory_e820(res, addr, di);
		terminal_printf("res: %d | type: %d | addr: %p%p | length: %p%p\n",
								res, mem.type, mem.base_addr_high, mem.base_addr_low, mem.length_high, mem.length_low);
		if (err) {
			terminal_printf("Kernel mem error\n");
			break;
		}
		res = mem.res;
		if (!res)
			break;
	};
	terminal_printf("end\n");

	end();
}
