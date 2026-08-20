section .text
	global _start
	
_start:
	mov rax, 0xFFFFFFFFFFFFFFFF
	mov rbx, 2
	mul rbx
	
	mov ebx, 0
	mov eax, 1
	int 0x80
