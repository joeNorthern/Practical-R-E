; 1. Given what you learned about CALL and RET, explain how you would read the value of EIP? Why can't you just do MOV EAX, EIP?

; Didn't really understand the question about "how you would read the value of EIP?". In a running binary, the contents of EIP are supposed to be addresses from the .text section of the ELF (if on Linux). The CALL pushes the address of the
; next instruction into the stack, whilst RET pops the contents that the top of the stack points to, and sets EIP to it.
; Now why can't we MOV EIP to EAX: suppose a simple mov instruction;

mov eax, eax ; 89 c0 // 10001001 11000000

; This instruction moves the lower 32-bits of RAX register into itself, let's break down how the CPU reads it.

; 10001001 11000000
; |      | \____   \__
; the mov opcode\______ The ModR/M, split this one into 2:3:3. 
;                     | 11 -> Register direct, no dereferencing
;                     | 000 -> EAX opcode					   
;                     | 000 -> EAX opcode					   
;                     +----------------------------------------+
; We can notice an interesting thing: both EAX's contain three bits. Let's try seeing something with a different operation.

mov eax, ebx ; 89 d8 // 10001001 11011000

; We can clearly notice that the mov opcode is the same and intact. Let's try inspecting the ModR/M 11011000.
; 11 -> Register direct, no dereferencing
; 011 -> EBX opcode
; 000 -> EAX opcode

; Now to our main question, with basic understanding of the sematics; why can't we move EIP somewhere else like EAX?
; Simply because EIP lacks an opcode. On x64 systems, EIP can only be manipulated with JMP, CALL, RET and the rest. That's it, as simple as it sounds.
; This may be strange for a man coming from ARMv7 background, where PC's opcode is 1111 and may be accessed directly.

; 2. Come up with at least two sequences to set EIP to 0xAABBCCDD.
; The first one is to pop value into it. Suppose we overflowed the stack within a simple BoF:

mov esp, ebp
pop ebp
ret ; we are trusting the stack. if buffer overflow took place, the address may be overwritten according to the attacker.

; Second example may be a simple jmp instruction.

jmp 0xAABBCCDD ; e9 d9 cc bb aa

; Remark on address 0xAABBCCDD itself; it's an odd address and laying on it will mean instruction corruption. The instruction will land on 0xAABBCCDE instead.

; 3. In the example function 'addme', what would happen if the stack pointer were not properly restored before executing RET?

addme:
	push ebp
	mov ebp, esp

	movsx eax, WORD PTR [ebp+0x8]
	movsx ecx, WORD PTR [ebp+0xC]
	add eax, ecx

	mov esp, ebp
	pop ebp
	ret

; It would likely cause undefined behaviour, and if the binary was compiled with frame-pointer omission it would absolutely cause a segfault.

; 4. In all of the calling conventions explained, the return value is stored in 32-bit/64-bit register (EAX/RAX). What happens when the return value does not fit in a 32-bit/64-bit register?
; Let's try building a mul program to showcase mul behavior.

; pwndbg> 
; 0x000000000040100f in _start ()
; LEGEND: STACK | HEAP | CODE | DATA | WX | RODATA
;────────────────────────────────────────────────────────────────────────────────────────────────────[ REGISTERS / show-flags off / show-compact-regs off ]────────────────────────────────────────────────────────────────────────────────────────────────────
;*RAX  0xfffffffffffffffe
; RBX  2
; RCX  0
;*RDX  1
; RDI  0
; RSI  0
; R8   0
; R9   0
; R10  0
; R11  0
; R12  0
; R13  0
; R14  0
; R15  0
; RBP  0
; RSP  0x7fffffffd860 ◂— 1
; *RIP  0x40100f (_start+15) ◂— mov ebx, 0
;─────────────────────────────────────────────────────────────────────────────────────────────────────────────[ DISASM / x86-64 / set emulate on ]─────────────────────────────────────────────────────────────────────────────────────────────────────── ─────
;   0x401000 <_start>       mov    rax, 0xffffffffffffffff     RAX => 0xffffffffffffffff
;   0x401007 <_start+7>     mov    ebx, 2                      EBX => 2
;   0x40100c <_start+12>    mul    rbx
; ► 0x40100f <_start+15>    mov    ebx, 0                      EBX => 0
;   0x401014 <_start+20>    mov    eax, 1                      EAX => 1
;   0x401019 <_start+25>    int    0x80 <SYS_exit>
;   0x40101b                add    byte ptr [rax], al
;   0x40101d                add    byte ptr [rax], al
;   0x40101f                add    byte ptr [rax], al
;   0x401021                add    byte ptr [rax], al
;   0x401023                add    byte ptr [rax], al

; We multiply 0xffffffffffffffff by 0x2. We can see that after the multiplication, RDX changed to one; The real 128-bit result is 0x1FFFFFFFFFFFFFFFE, so we can read the return value of the arithmetic as when reading RDX->RAX.
; RDX is a bit we just pushed out of RAX because we didn't have space, that's it. 
; P.S: I used pwndbg here, so I didn't bother with endianess. But if you're reading raw hex values, you shouldn't forget it.
