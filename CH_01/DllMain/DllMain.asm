; BOOL __stdcall DllMain(HINSTANCE hinstDLL, DWORD fdwReason,
; LPVOID lpvReserved)
                _DllMain@12 proc near
55                    push    ebp                           ; push ebp from caller down the stack
8B EC                 mov     ebp, esp						; move esp to ebp, new stack frame
81 EC 30 01 00+       sub     esp, 130h						; subtract 304 bytes from esp, new stack frame used
57                    push    edi							; pushing edi down the stack, what is it?
0F 01 4D F8           sidt    fword ptr [ebp-8]				; store IDTR at ebp-8, Store Interrupt Descriptor Table. Think of the IDT as an array of function pointers to fault/interrupt handlers.
8B 45 FA              mov     eax, [ebp-6]					; The IDT Register consists of 6-bytes. High 2-bytes are the limit, the rest 4 are the base. Hence, we want to load the base; we will load a dword into eax, starting at ebp-6.
															; This excludes the limit bytes.
3D 00 F4 03 80        cmp     eax, 8003F400h				; Compare the IDTR base with 0x8003F400. 0x8003F400 is usually the virtual address of IDT base on Windows XP.
76 10                 jbe     short loc_10001C88			; J (jump) B (below) E (equal); therefore, if eax <= 0x8003F400. cmp affects conditions in EFLAGS register, that's how Jcc knows to navigate based on conditions.
3D 00 74 04 80        cmp     eax, 80047400h				; Same as line 11, with a different value.
73 09                 jnb     short loc_10001C88			; J (jump) N (not) B (beneath); Jump to loc_10001C88 if eax >= 0x80047400.
33 C0                 xor     eax, eax						; null out eax
5F                    pop     edi							; pop edi back into itself
8B E5                 mov     esp, ebp						; move ebp into esp, clearing our the stack
5D                    pop     ebp							; pop old ebp into itself
C2 0C 00              retn    0Ch							; return 0


; By now, we can roughly construct this part of the code segment. There is no function standard function to access the contents of the IDTR in C, so we'll improvise with inline assembly.
; We should put a notice on the cmp instructions above: the conditions they are being supported with only use unsigned arguments.
; The following attempt to reconstruct the code works on 32-bit x86 systems


; #include <stdint.h>
;
; typedef struct
; {
;	uint16_t limit;
;	uint32_t base;
; } __attribute__((packed)) IDT_PTR; /* _attribute__((packed)) means to struct this structure without paddling whatsoever */
;
; int _DllMain(...)
; {
; 	IDT_PTR idtr;
;	asm volatile
;	(
;		"sidt %0":
;		"=m" (idtr)
;	);
;
;	if(idtr.base <= 0x8003F400) goto loc_10001C88;
;	if(idtr.base >= 0x80047400) goto loc_10001C88;
;	return 0;
;
; loc_10001C88:
; 	...
                loc_10001C88:
33 C0                 xor     eax, eax						; null out eax
B9 49 00 00 00        mov     ecx, 49h						; move 74 into ecx
8D BD D4 FE FF+       lea     edi, [ebp-12Ch]				; load address at ebp-300 (?)
C7 85 D0 FE FF+       mov     dword ptr [ebp-130h], 0		; null out 4 bytes starting at ebp-130 (?)
50                    push    eax							; push eax
6A 02                 push    2								; push 2
F3 AB                 rep stosd								; write eax into address stored in edi ecx times and increment the edi pointer by size 4 bytes (stosD -> double)

; Let's take a deeper look. EAX is being set as zero, whilst we move 74 into ecx. Then we load address ebp-300, which seems to be a buffer to a type of 4 bytes.
; 74*4 = 296, therefore we null out 296 bytes down the stack starting at ebp-300.
; As of default on 32-bit systems, 4 bytes is the biggest size, so this is probably size_t. We can't know yet if it's signed or unsigned.

E8 2D 2F 00 00        call    CreateToolhelp32Snapshot		; deserves a separate section
8B F8                 mov     edi, eax						; move what CreateToolhelp32Snapshot returns into edi
83 FF FF              cmp     edi, 0FFFFFFFFh				; compare with -1; see if CreateToolhelp32Snapshot returns a valid table entry
75 09                 jnz     short loc_10001CB9			; J (jump) N (not) Z (zero); jump to loc_10001CB9 if Z flag in EFLAGS isn't on (which will not be on if the cmp above won't be equal)
33 C0                 xor     eax, eax						; proceed to exit if what CreateToolhelp32Snapshot returned is invalid
5F                    pop     edi							; same as above
8B E5                 mov     esp, ebp						; ...
5D                    pop     ebp							; ...
C2 0C 00              retn    0Ch							; ...

; HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
; We can see that we have pushed some values previously on the stack, and as we may know x86 accepts function arguments through it. 
; Roughly the call looks like CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS, 0), which returns a void* with an index to a handle entry within the handle table structure within the kernel-space.
; This "index" is not an address but a literal number for us to use when trying to communicate with our handle entry in the kernel-space; it is an index.
; It is possible to reference it to file descriptors on linux, except that there is no direct "socket" (I suppose?).

                loc_10001CB9:
8D 85 D0 FE FF+       lea     eax, [ebp-130h]				; caluclate start of the stack frame (determine start of LPPROCESSENTRY32 struct)
56                    push    esi							; CreateToolhelp32Snapshot changes something in esi? I don't see that anything changed esi previously
50                    push    eax							; push starting address of the stack frame (LPPROCESSENTRY32)
57                    push    edi							; push what CreateToolhelp32Snapshot returned in loc_10001C88.
C7 85 D0 FE FF+       mov     dword ptr [ebp-130h], 128h	; move 0x128 to start of the stack frame (LPPROCESSENTRY32 e; e.dwSize = sizeof(e);)
E8 FF 2E 00 00        call    Process32First				; retrieve information from given system snapshot and fill given LPPROCESSENTRY32 struct with data.

; BOOL Process32First (
; 	HANDLE hSnapshot,
; 	LPPROCESSENTRY32 lppe
; );
;
; Can be seen that we are first passing what CreateToolhelp32Snapshot returned previously, but next we are passing EAX.
; But turns out EAX is a pointer to a LPPROCESSENTRY32 structure! Now instruction 83 makes total sense!
; Before using an LPPROCESSENTRY32 structure, it is mandatory to set it's dwSize member to sizeof(LPPROCESSENTRY32), which is done in line 83.

85 C0                 test    eax, eax						; AND eax with eax and set appropriate falgs in EFLAGS 
74 4F                 jz      short loc_10001D24			; J (jump) Z (zero); jump to loc_10001D24 if Z flag in EFLAGS is on, which only triggers when Process32First returns FALSE (0).
8B 35 C0 50 00+       mov     esi, ds:_stricmp				; load address of _stricmp macro to esi. data segment is noise here
8D 8D F4 FE FF+       lea     ecx, [ebp-10Ch]				; load address of ebp-268. this should be a statement like *(void*)ecx = &e.some_struct_member;

68 50 7C 00 10        push    10007C50h						; what is this value?
51                    push    ecx							; push address of ebp-268
FF D6                 call    esi ; _stricmp				; call stricmp
83 C4 08              add     esp, 8						; esp += 8
85 C0                 test    eax, eax						; eax & eax; if both are zero, Z in EFLAGS flag is on
74 26                 jz      short loc_10001D16			; jump if stricmp returned 0 in eax

; Let's untangle the LPPROCESSENTRY32 structure to understand what ebp-268 refers to:
; typedef struct tagPROCESSENTRY32 {
; 	DWORD     dwSize;                  	; 4 bytes
;  	DWORD     cntUsage;					; 4 bytes
;  	DWORD     th32ProcessID;			; 4 bytes
;  	ULONG_PTR th32DefaultHeapID;		; 4 bytes
;  	DWORD     th32ModuleID;				; 4 bytes
;  	DWORD     cntThreads;				; 4 bytes
;  	DWORD     th32ParentProcessID;		; 4 bytes
;  	LONG      pcPriClassBase;			; 4 bytes
;  	DWORD     dwFlags;					; 4 byte
;  	CHAR      szExeFile[MAX_PATH];		; 260 bytes (mindwindef.h) = 296 bytes
; } PROCESSENTRY32;
;
; ebp-296 - ebp-268 = *(PROCESSENTRY32 *)(char *)struct_base += 28. Seems to be struct_base->pcPriClassBase.
; We effectively call stricmp(struct_base.pcPriClassBase, 0x10007C60).
; The string was supposed to be filled with data by Process32First, and so if the data filled was the same as 0x10007C60, we would jump to loc_10001D16.
; I see there is no fallback here, so I suppose if it won't be equal it will continue execution as usual.

                loc_10001CF0:
8D 95 D0 FE FF+       lea     edx, [ebp-130h] 
52                    push    edx
57                    push    edi
E8 CD 2E 00 00        call    Process32Next
85 C0                 test    eax, eax
74 23                 jz      short loc_10001D24
8D 85 F4 FE FF+       lea     eax, [ebp-10Ch]
68 50 7C 00 10        push    10007C50h
50                    push    eax
FF D6                 call    esi ; _stricmp
83 C4 08              add     esp, 8
85 C0                 test    eax, eax
75 DA                 jnz     short loc_10001CF0
                loc_10001D16:
8B 85 E8 FE FF+       mov     eax, [ebp-118h]
; ebp-296 - ebp-280 = *(PROCESSENTRY32 *)(char *)struct_base += 16. struct_base->th32ModuleID.
8B 8D D8 FE FF+       mov     ecx, [ebp-128h]
; ebp-296 - ebp-296 = *(PROCESSENTRY32 *)(char *)struct_base += 0. struct_base->dwSize.
; EAX = struct_base.th32ModuleID;
; ECX = struct_base.dwSize;
EB 06                 jmp     short loc_10001D2A
                loc_10001D24:
8B 45 0C              mov     eax, [ebp+0Ch]
8B 4D 0C              mov     ecx, [ebp+0Ch]
                loc_10001D2A:
3B C1                 cmp     eax, ecx				; we jump here after loc_10001D16. compare struct_base.th32ParentProcessID and struct_base.th32ProcessID.
5E                    pop     esi					; the last manipulation with the stack was either in line 136, if we didn't get a fallback at loc_10001CB9, or inside loc_10001CB9 at line 102.
													; good for us, both these scenarios result in address of struct_base->pcPriClassBase to be pushed to esi.
75 09                 jnz     short loc_10001D38
33 C0                 xor     eax, eax
5F                    pop     edi
8B E5                 mov     esp, ebp
5D                    pop     ebp
C2 0C 00              retn    0Ch
                loc_10001D38:
8B 45 0C              mov     eax, [ebp+0Ch]
48                    dec     eax
75 15                 jnz     short loc_10001D53
6A 00                 push    0
6A 00                 push    0
6A 00                 push    0
68 D0 32 00 10        push    100032D0h
6A 00                 push    0
6A 00                 push    0
FF 15 20 50 00+       call    ds:CreateThread
                loc_10001D53:
B8 01 00 00 00        mov     eax, 1
5F                    pop     edi
8B E5                 mov     esp, ebp
5D                    pop     ebp
C2 0C 00              retn    0Ch
                _DllMain@12 endp

; #include <stdint.h>
;
; typedef struct
; {
;	uint16_t limit;
;	uint32_t base;
; } __attribute__((packed)) IDT_PTR; /* _attribute__((packed)) means to struct this structure without paddling whatsoever */
;
; int _DllMain(...)
; {
; 	IDT_PTR idtr;
;	asm volatile
;	(
;		"sidt %0":
;		"=m" (idtr)
;	);
;	if(idtr.base <= 0x8003F400) goto loc_10001C88;
;	if(idtr.base >= 0x80047400) goto loc_10001C88;
;	return 0;
;
; loc_10001C88:
;	HANDLE current_process_handle;
;	if((current_process_handle = CreateToolhelp32Snapshot(TH32CS_SNAPPROCCESS, 0)) != INVALID_HANDLE_VALUE)
;		goto loc_10001CB9; 
;	return 0;
;
; loc_10001CB9:
;	LPPROCESSENTRY32 lppe;
;	Process32First(current_process_handle, lppe);
; 	if(!stricmp(lppe.szExeFile, 0x10007C60)) goto loc_10001D16;
; 
; loc_10001D16:
;	DWORD eax = lppe.th32ModuleID;
;	DWORD eax = lppe.dwSize;
;	goto loc_10001D2A;
;
; 1loc_10001D2A;
