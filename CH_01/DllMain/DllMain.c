#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>

#define BOOL bool
#define HINSTANCE void * /* base addr of the dll (?) */
#define LPVOID void *
#define TH32CDS_SNAPPROCESS 2
#define INVALID_HANDLE_VALUE -1

typedef struct IDT_PTR
{
	uint16_t limit;
	uint32_t base;
} __attribute__((packed)) IDT_PTR;

BOOL DllMain(HINSTANCE hinstDll, uint32_t fdwReason, LPVOID lpvReserved)
{
	uint32_t edi; /* something here */
	IDT_PTR idtr;
	asm volatile
	(
		"sidt %0"
		: "=m"(idtr)
	);
	if(idtr.base <= 0x8003F400 || idtr.base >= 0x80047400)
	{
		/* loc_10001C88 */
		size_t ecx = 73;
		memset(some_ptr, NULL, ecx*4);
		if(CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL) == INVALID_HANDLE_VALUE)
			return 12;

		/* loc_10001CB9 */
	}

	return 12;
}

int main(int argc, char **argv)
{
	DllMain(NULL, 1, NULL);
	return 0;
}

/*
code is being written as if we are on a 32-bit machine.
i should get an emulator for this later
*/
