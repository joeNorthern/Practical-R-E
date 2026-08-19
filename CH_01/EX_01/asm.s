section .data
	string:
		db 'AAAABBBBCCCCDDDD', 0
section .text
global _start
_start:
	push byte 'a' ; push 0x61 on the stack
	push dword string ; push char* at 'string' symbol
	call func 
	add rsp, 16 ; stack cleanup
	mov ebx, 0
	mov eax, 1
	int 0x80

func:
	push rbp ; function prologue, push our previous base pointer
	mov rbp, rsp ; move stack pointer to current base after push (didn't allocate more memory for the current frame)
;
	mov rdi, [rbp+16] ; load pointer to 'string' into edi
	mov rdx, rdi ; save pointer snippet into rdx
	xor eax, eax ; null-out rax
	or rcx, 0xFFFFFFFFFFFFFFFF ; rcx = -1
	repne scasb ; repeatedly increment the pointer at edi by wanted size until it's value does not match eax.
				; each run, decrement rcx.
	            ; in this scenario, effectively counting lenght of 'string'.
	add rcx, 2  ; compensate the starting-out -1 and the counted null terminator
	neg rcx     ; flip the negative value, get a positive real number
	mov al, [rbp+0x18] ; load 0x61 into al
	mov rdi, rdx ; move the previously saved char* 'string' snippet into rdi
	rep stosb   ; repeatedly start setting values starting at edi with value stored in al ecx times [effective memset()]
	mov rax, rdx ; move snipped to rax, use it as return value 
	mov rsp, rbp ; move effective base pointer to stack pointer
	pop rbp      ; jump to previously stored return address
	ret

; P.S: the original exercise was intended for 32-bit systems, but I am on a 64-bit one. The code was slightly changed
; according to my architecture, but the mechanisms remain the same.
; compiled in NASM 2.16.01
