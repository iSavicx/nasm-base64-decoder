SECTION .data           ; Section containing initialised data
	Base64Table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

SECTION .bss            ; Section containing uninitialized data
	OutBufLen:	equ 3
	OutBuf:		resb OutBufLen 	; reserve 3 bytes for output

	InBufLen:	equ 4		
	InBuf:		resb InBufLen 	; reserve 4 bytes for input


	
	
SECTION .text           ; Section containing code

global _start           ; Linker needs this to find the entry point!

_start:


	;; r8 and r9 are main registers for byte conversion
	;; r15 is amount of bytes to write.
	;; r11 and r10 are used to find the offset of the base64 table chars
	xor rax, rax	    ; making sure rax is 0
	xor r15, r15		; making sure counter is 0
	call read			; Jump to read and read 4 Bytes of input
	cmp rax, 4			; Check if there was real base64 input
	jb exit				; If there was less than input exit the program
	mov r15, 3			; 3 bytes to write 

	;; preping the registers
	xor r8, r8			; 0ing r8
	xor r9, r9			; 0ing r9
	
	;; masking the bits and saving first byte to output buffer
	mov r8b, byte [InBuf]			; moving  input to to r8
	xor r11, r11 					; needs to be done for b64pos
	call b64pos						; check what position the string has in the table
	mov r9b, r11b					; move position of symbol to r9b
	shl r9, 6						; shift 6 to left as next input will require 6 bits
	xor r8, r8						; clear r8 for next input
	mov r8b, byte [InBuf+1]			; moving next input to r8
	xor r11, r11 					; needs to be done for b64pos
	call b64pos						; getting offset of the input symbol
	mov r8b, r11b					; writing the position number to r8b
	or r9b, r8b						; getting all bits that were set
	shr r9, 4						; removing 4 bits from next symbol
	mov byte [OutBuf], r9b			; moving first symbol to output
	
	;; second byte:
	xor r8, r8 					; clearing register
	xor r9, r9					; clearing register
	mov r8b, byte [InBuf+1]		; move next input byte to r8b
	xor r11, r11				; clear r11 is needed for call to b64pos
	call b64pos					; getting offset of the input symbol
	mov r9b, r11b				; writing the position number to r9b
	and r9, 0x00000f      		; keep only 4 bits
	xor r8, r8
	mov r8b, byte [InBuf+2]
	cmp r8b, '='				; check if = sign was found
	je foundEnd1				; jump to found end to adjust amount of output bytes

	xor r11, r11				; clear r11 is needed for call to b64pos
	call b64pos					; getting offset of the input symbol
	shl r9, 6					; shifting 6 to left to make room for next symbol offset
	or r9, r11					; adding off set to form next char
	ror r9, 2					; rotating out last 2 bits to form a byte in r9b
	mov byte [OutBuf+1], r9b	; writing to byte to output

	;; Byte number 3
	rol r9, 8					; rotate back in the 2 bits that were rotated out
	and r9, 0x0000ff			; mask to only keep the 2 bits at position 7 and 8
	xor r8, r8					; clear r8
	mov r8b, byte [InBuf+3]			; get last input byte
	cmp r8b, '='				; check if = sign was found
	je foundEnd2				; jump to found end to adjust amount of output bytes

	xor r11, r11				; clear r11 is needed for call to b64pos
	call b64pos					; getting offset of the input symbol
	or r9, r11					; add the r11 symbol off set to r9 to form last byte
	mov byte [OutBuf+2], r9b	; writing to byte to output

endOfLoop:		
	call write 			; write output buffer to standard output
	jmp _start 			; loop to check for more input 


exit:	
	mov rax, 60         		; Code for exit
	mov rdi, 0          		; Return a code of zero
	syscall             		; Make kernel call


;;;  Processes are written below

read:
	;;  Read from stdin to InBuf
	mov rax, 0                      ; sys_read
	mov rdi, 0                      ; file descriptor: stdin
	mov rsi, InBuf                  ; destination buffer
	mov rdx, InBufLen               ; maximum # of bytes to read
	syscall				; Make kernal call
	ret

write:
	mov rax, 1                      ; sys_write
	mov rdi, 1                      ; file descriptor: stdout
	mov rsi, OutBuf                 ; source buffer
	mov rdx, r15        	; # of bytes to write
	syscall				; make kernal call
	ret				; return to code right after the call

b64pos:
	xor r10, r10 					; 0ing symbol placeholder
	mov r10b, byte [Base64Table+r11] ; move first base 64 table byte to r9b
	inc r11							; increase the counter
	cmp r8b, r10b					; check if the symbol is the same as stored in r8b
	jne b64pos						; if the symbols didnt match repeat
	dec r11							; decrease counter if match was found as the last increase wasnt needed
	ret								; return to code right after the call


foundEnd1:
	xor r15, r15					; clear amount of bytes to write
	mov r15, 1						; only write 1 byte
	jmp endOfLoop					; go to write 

foundEnd2:
	xor r15, r15					; clear amount of bytes to write
	mov r15, 2						; only write 2 byte
	jmp endOfLoop					; go to write 