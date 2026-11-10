#include <stdio.h>
#include <stdint.h>

typedef struct IDTR
{
	uint16_t limit;
	uint32_t base;
} __attribute__((packed)) IDTR;

int main()
{
	IDTR idtr;
	asm volatile
	(
		"sidt %0"
		: "=m"(idtr)
	);
	return 0;
}
