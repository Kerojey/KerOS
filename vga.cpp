#include "vga.hpp"

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
uint32_t vga_terminal_row = 0;
uint32_t vga_terminal_column = 0;
//uint16_t currv = 0;
//uint16_t currh = 0;
uint8_t vga_terminal_color = (VGA_COLOR_LIGHT_GREEN | VGA_COLOR_BLACK << 4);
volatile uint16_t* vga_terminal_buffer = (volatile uint16_t*) 0xB8000;
 
inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg);
inline uint16_t vga_entry(unsigned char uc, uint8_t color);
size_t strlen(const char* str);
 

inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) 
{
	return fg | bg << 4;
}
 
inline uint16_t vga_entry(unsigned char uc, uint8_t color) 
{
	//return uc << 0 | color << 8;
	return (uc << 0) + (color << 8);
}
 
size_t strlen(const char* str) 
{
	size_t len = 0;
	while (str[len])
		len++;
	return len;
}
 
void terminal_clear(void) 
{
	for (size_t y = 0; y < VGA_HEIGHT; y++) {
		for (size_t x = 0; x < VGA_WIDTH; x++) {
			const size_t index = y * VGA_WIDTH + x;
			vga_terminal_buffer[index] = vga_entry(' ', vga_terminal_color);
		}
	}
}
 
void terminal_setcolor(vga_color fg, vga_color bg) 
{
	vga_terminal_color = vga_entry_color(fg, bg);
}
 
void terminal_putentry_at(char c, uint8_t color, size_t x, size_t y) 
{
	const size_t index = y * VGA_WIDTH + x;
	vga_terminal_buffer[index] = vga_entry(c, color);
}
void terminal_putchar(char c) 
{
	if (c == '\n') {
		for (; vga_terminal_column < VGA_WIDTH; ++vga_terminal_column) {
			terminal_putentry_at(' ', vga_terminal_color, vga_terminal_column, vga_terminal_row);
		}
		--vga_terminal_column;
	} else {
		terminal_putentry_at(c, vga_terminal_color, vga_terminal_column, vga_terminal_row);
	}
	if (++vga_terminal_column == VGA_WIDTH) {
		vga_terminal_column = 0;
		if (++vga_terminal_row == VGA_HEIGHT) {
			vga_terminal_row = 0;
		}
	}
}
 
void terminal_write(const char* data, size_t size) 
{
	for (size_t i = 0; i < size; i++)
		terminal_putchar(data[i]);
}
 
void terminal_writestring(const char* data) 
{
	terminal_write(data, strlen(data));
}

uint8_t kprintu(const uint32_t i, uint8_t base)
{
    uint32_t dividend = i / base, rem = i % base;
    char value;
    uint8_t count = 1;

    if (dividend != 0)
    {
        count += kprintu(dividend, base);
    }

    if (rem > 9)
    {
        value = (char)(rem - 10 + (uint32_t)'A');
    }
    else
    {
        value = (char)(rem + (uint32_t)'0');
    }
    terminal_putchar(value);
    return count;
}


uint8_t kprinti(const int32_t i, uint8_t base)
{
    uint32_t value;
    if (i < 0)
    {
        terminal_putchar('-');
        value = (uint32_t) (~i + 1);
    }
    else
    {
        value = (uint32_t) i;
    }
    return kprintu(value, base) + 1;
}

void pad_pointer(uint32_t p)
{
    if (p == 0)
    {
        terminal_writestring("0000000");
    }
    else if (p < 0x10000000)
    {
        uint32_t mask = 0xf0000000;
        while ((p & mask) == 0)
        {
            terminal_putchar('0');
            mask >>= 4;
        }
    }
}
void terminal_printf(const char* format, ...)
{
    va_list args;
    va_start(args, format);

    for (const char* p = format; *p != '\0'; ++p)
    {
        switch(*p)
        {
            case '%':
                switch(*++p) // read format symbol
                {
                    case 'c': {
                        terminal_putchar((char) va_arg(args, int));
                        continue;
					}
                   case 's': {
                        terminal_writestring(va_arg(args, char*));
                        continue;
				   }
                    case 'd': {
                        kprinti(va_arg(args, int32_t), 10);
                        continue;
					}
                    case 'u': {
                        kprintu(va_arg(args, uint32_t), 10);
                        continue;
					}
                    case 'x': {
                        kprintu(va_arg(args, uint32_t), 16);
                        continue;
					}
                    case 'p': {
                        uint32_t ptr = va_arg(args, uint32_t);
                        pad_pointer(ptr);
                        kprintu(ptr, 16);
                        continue;
					}
                    case '%': {
                        terminal_putchar('%');
                        continue;
					}
                }
        }
        terminal_putchar(*p);
    }
}