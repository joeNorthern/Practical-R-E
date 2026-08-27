; BOOL __stdcall DllMain(HINSTANCE hinstDLL, DWORD fdwReason,
; LPVOID lpvReserved)
                _DllMain@12 proc near
55                    push    ebp                           ; push ebp from caller down the stack
8B EC                 mov     ebp, esp						; move esp to ebp, new stack frame
81 EC 30 01 00+       sub     esp, 130h						; subtract 0x130 from esp, new stack frame used
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
; We will use GCC. The following attempt to reconstruct the code works on 32-bit x86 systems


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
;
; loc_10001C88:
; 	...
                loc_10001C88:
33 C0                 xor     eax, eax
B9 49 00 00 00        mov     ecx, 49h
8D BD D4 FE FF+       lea     edi, [ebp-12Ch]
C7 85 D0 FE FF+       mov     dword ptr [ebp-130h], 0
50                    push    eax
6A 02                 push    2
F3 AB                 rep stosd
E8 2D 2F 00 00        call    CreateToolhelp32Snapshot
8B F8                 mov     edi, eax
83 FF FF              cmp     edi, 0FFFFFFFFh
75 09                 jnz     short loc_10001CB9 (line 35)
33 C0                 xor     eax, eax
5F                    pop     edi
8B E5                 mov     esp, ebp
5D                    pop     ebp
C2 0C 00              retn    0Ch
                loc_10001CB9:
8D 85 D0 FE FF+       lea     eax, [ebp-130h]
56                    push    esi
50                    push    eax
57                    push    edi
C7 85 D0 FE FF+       mov     dword ptr [ebp-130h], 128h
E8 FF 2E 00 00        call    Process32First
85 C0                 test    eax, eax
74 4F                 jz      short loc_10001D24 (line 70)
8B 35 C0 50 00+       mov     esi, ds:_stricmp
8D 8D F4 FE FF+       lea     ecx, [ebp-10Ch]
68 50 7C 00 10        push    10007C50h
51                    push    ecx
FF D6                 call    esi ; _stricmp
83 C4 08              add     esp, 8
85 C0                 test    eax, eax
74 26                 jz      short loc_10001D16 (line 66)
                loc_10001CF0:
8D 95 D0 FE FF+       lea     edx, [ebp-130h]
52                    push    edx
57                    push    edi
E8 CD 2E 00 00        call    Process32Next
85 C0                 test    eax, eax
74 23                 jz      short loc_10001D24 (line 70)
8D 85 F4 FE FF+       lea     eax, [ebp-10Ch]
68 50 7C 00 10        push    10007C50h
50                    push    eax
FF D6                 call    esi ; _stricmp
83 C4 08              add     esp, 8
85 C0                 test    eax, eax
75 DA                 jnz     short loc_10001CF0 (line 52)
                loc_10001D16:
8B 85 E8 FE FF+       mov     eax, [ebp-118h]
8B 8D D8 FE FF+       mov     ecx, [ebp-128h]
EB 06                 jmp     short loc_10001D2A (line 73)
                loc_10001D24:
8B 45 0C              mov     eax, [ebp+0Ch]
8B 4D 0C              mov     ecx, [ebp+0Ch]
                loc_10001D2A:
3B C1                 cmp     eax, ecx
5E                    pop     esi
75 09                 jnz     short loc_10001D38 (line 82)
33 C0                 xor     eax, eax
5F                    pop     edi
8B E5                 mov     esp, ebp
5D                    pop     ebp
C2 0C 00              retn    0Ch
                loc_10001D38:
8B 45 0C              mov     eax, [ebp+0Ch]
48                    dec     eax
75 15                 jnz     short loc_10001D53 (line 93)
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
