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
	PROCESSENTRY32 lppe = {0}; /* line 26 + 23 in the DllMain.asm */
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
		void *hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
		if(handle == INVALID_HANDLE_VALUE)
			return 12;

		/* loc_10001CB9 */
		lppe.dwSize = 0x128;
		if(Process32First(lppe, hSnapshot) == 0)
		{
			/* loc_10001D24 */
			uint32_t eax = fdwReason;
			uint32_t ecx = fdwReason;
			/* loc_10001D2A */
			if(eax != ecx)
			{
				/* loc_10001D38 */

			}
			return 12
		} else
		{
			char *ecx = &lppe.szExeFile;
			if(stricmp("explorer.exe", ecx) == 0)
			{
				/* loc_10001D16 */
				uint32_t eax = lppe.th32ParentProcessID;
				uint32_t ecx = lppe.th32ProcessID;
				/* loc_10001D2A */
				if(eax != ecx)
				{
					/* loc_10001D38 */
						
				}
				return 12;
			} else
			{
				/* loc_10001CF0 */
				void *edx = &lppe.dwSize;
				if(Process32Next(lppe, hSnapshot) == 0)
				{
					/* loc_10001D24 */
					uint32_t eax = fdwReason;
					uint32_t ecx = fdwReason;
					if(eax != ecx)
					{
						/* loc_10001D38 */
						
					} else { return 12; }
					if(stricmp("explorer.exe", ecx) == 0)
					{
						/* loc_10001D16 */
						uint32_t eax = lppe.th32ParentProcessID;
						uint32_t ecx = lppe.th32ProcessID;
						/* loc_10001D2A */
						if(eax != ecx)
						{
							/* loc_10001D38 */
							uint32_t eax = fdwReason-1;
							if(eax)
							{
								/* loc_10001D53 */
								return 12;
							} else
							{
								return CreateThread(NULL, NULL, NULL, 0x100032D0, NULL, NULL);
							}
						}
						return 12;
					}
				}
			}
		}
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
