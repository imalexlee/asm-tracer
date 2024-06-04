

format ELF64 executable 3

include "macros.inc"
include "math.s"

segment readable writeable
; constants
IMAGE_WIDTH = 1080
IMAGE_HEIGHT = 1080

; variables
color_scale	dd 255.999
msg 		db "hello world", 0xA
image_file 	db "image.ppm", 0
intstr_buf	rb 10
header_buf	rb 20
line_buf	rb 12

segment readable executable

entry $
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	
	syscall	2, image_file, 102o, 700o
	mov	[rbp - 24], rax	; save file descriptor
	callfn	write_header, header_buf, IMAGE_WIDTH, IMAGE_HEIGHT
	mov 	rsi, rax	; rax will be overwritten by syscall #	
	; write header to file
  	syscall 1, [rbp - 24], rsi, rdx
	; write contents
	mov	dword [rbp - 16], 0	; i
.i_loop:
	mov	dword [rbp - 12], 0	; j
.j_loop:
	pxor	xmm0, xmm0
	pxor	xmm1, xmm1

	mov	dword [rbp - 8], IMAGE_WIDTH
	dec	dword [rbp - 8]	; we need to divide by width - 1
	cvtsi2ss 	xmm0, dword [rbp - 16]	; cast i to float
	cvtsi2ss 	xmm1, dword [rbp - 8]; cast width - 1 as float
	divss	xmm0, xmm1	; i / width - 1 => r
	movss	xmm1, [color_scale]
	mulss	xmm0, xmm1
	cvtss2si	eax, xmm0 	; cast result to int
	mov	[rbp - 28], eax	; stor ir on the stack

	mov	dword [rbp - 8], IMAGE_HEIGHT
	dec	dword [rbp - 8]	; we need to divide by height - 1
	cvtsi2ss 	xmm0, dword [rbp - 12]; cast j to float
	cvtsi2ss 	xmm1, dword [rbp - 8]; cast height - 1 as float
	divss	xmm0, xmm1	; j / height - 1 => g
	movss	xmm1, [color_scale]	; 255.999
	mulss	xmm0, xmm1
	cvtss2si	eax, xmm0	; cast result to int
	mov	[rbp - 32], eax


	callfn write_img_line, line_buf , [rbp - 28], [rbp - 32] ,0
	mov	rsi, rax	; syscall # will write over rax, so save it in rsi
  	syscall 1, [rbp - 24], rsi, rdx ; write the line to file
	inc	dword [rbp - 12]
	cmp	dword [rbp - 12], IMAGE_WIDTH	; j < image_width
	jl	.j_loop
	inc	dword [rbp - 16]
	cmp	dword [rbp - 16], IMAGE_HEIGHT	; i < image_height
	jl	.i_loop
  	syscall 60, 0		; exit

; writes a line for the image -> "<r> <g> <b> \n"
; inputs:
;	rdi: buffer
;	rsi: r
;	rdx: g
;	rcx: b
; outputs:
;	rax: pointer to start of string
;	rdx: length of string
write_img_line:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32		; allocate stack space
	mov	[rbp - 8], rdi	; save buffer address
	mov	[rbp - 12], esi	; r
	mov	[rbp - 16], edx	; g
	mov	[rbp - 20], ecx	; b
	lea	r8, [rbp - 12]	; save initial address in r8 for later indexing
	mov	dword [rbp - 24], 0	; i for loop
	mov	dword [rbp - 28], 0	; string length

.loop:
	; convert r, then g, then b to string	
	xor	rsi, rsi
	mov	esi, [r8]
	callfn uitoa, intstr_buf, rsi
	sub	r8, 4
	mov	rcx, rdx	; move str len to rcx for string op
	dec	rcx		; remove null terminator
	mov	rsi, rax	; move source str to rsi for string op
	mov	rdi, [rbp - 8]	; restore rdi to start pos of buffer for string op
	add	edi, [rbp - 28] ; offset start pos by current line length
	add	dword [rbp - 28], ecx	; add color channel length to total line length 
	cld			; clear direction flag (iterate forward)
	rep movsb		; copy int string into buffer
	mov	byte [rdi], ' '
	inc	dword [rbp - 28]; inc string length for the space ' '
	inc	dword [rbp - 24]; i++
	cmp	dword [rbp - 24], 3
	jl	.loop
	mov	byte [rdi], 10	; replace last char w/ new line
	dec	dword [rbp - 28]; dec since loop runs and incs size 3 times but only 2 ' ' chars occur
	inc	dword [rbp - 28]
	mov	rax, [rbp - 8]
	xor 	rdx, rdx
	mov	edx, [rbp - 28]
	leave
	ret


; creates the ppm image header given the current dimensions
; inputs:
;	rdi: pointer to buffer
;	rsi: width
;	rdx: height
; outputs:
;	rax: pointer to start of null terminated string
;	rdx: length of string (with null terminator)
write_header:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 16		; space for local vars
	mov	[rbp - 16], rdi	; save start pointer of buffer
	; "P3\n"
	mov 	byte [rdi], 'P'
	mov 	byte [rdi + 1], '3'
	mov 	byte [rdi + 2], 10
	add 	rdi, 3		; offset address for next section
	mov 	r8, 9		; we know we need at least 10 chars (w/ null)	
	mov	[rbp - 8], rdi	; save rdi for next fn call	
	callfn uitoa, intstr_buf, IMAGE_WIDTH
	mov 	rsi, rax	; move string buffer to rsi for string instructions
	mov	rdi, [rbp - 8]	; restore rdi to be the header buffer
	dec 	rdx		; don't care about null terminator in int string
	xor 	rcx, rcx	; zero the counter	
.loop1_start:			; loop to write width to buf
	inc	r8		; add to the total string size
	; move both buffer locations together
 	movs 	byte [rdi], [rsi]
	inc	rcx
	cmp 	rcx, rdx
	jl	.loop1_start
	mov	[rbp - 8], rdi	; save rdi for next fn call	
	callfn uitoa, intstr_buf, IMAGE_HEIGHT
	mov	rsi, rax
	mov	rdi, [rbp - 8]	; restore rdi to be the header buffer
	dec 	rdx		; don't care about null terminator in int string
	xor 	rcx, rcx	; zero the counter
	mov	byte [rdi], ' '	; space between w and h
	inc	rdi
.loop2_start:			; loop to write height to buf
	inc	r8		; add to the total string size
	; move both buffer locations together
	movs 	byte [rdi], [rsi]
	inc	rcx
	cmp 	rcx, rdx
	jl	.loop2_start
	; now write finel \n255\n
	mov 	byte [rdi], 10
	mov 	byte [rdi + 1], '2'
	mov 	byte [rdi + 2], '5'
	mov 	byte [rdi + 3], '5'
	mov 	byte [rdi + 4], 10

	mov 	rax, [rbp - 16]	; send back pointer to buffer
	mov	rdx, r8
	leave
	ret	
			
; converts unsigned int to ascii string
; inputs:
;	rdi: pointer to 10 byte buffer
;	rsi: number to convert
; outputs:
;	rax: pointer to start of null terminated string
;	rdx: length of string (with null terminator)	
uitoa:
	add 	rdi, 9
	mov 	byte [rdi], 0		; null terminate end of string
	mov 	rax, rsi		; move number to rax for dividing
	mov	rsi, 10			; make rsi now store the divisor
	xor 	rcx,rcx
	add	rcx, 1			; count the terminator
.uitoa_loop:	
	inc	rcx			; increment length counter
	xor	edx, edx		; clear remainder since div uses edx:eax combined 64 bit reg
	div	rsi			; get remainder into edx
	add	edx, '0'		; add 48 ('0') to convert remainder to ascii
	dec	rdi			; move string buffer pointer back a byte
	mov	byte [rdi], dl		; set byte in string
	test	eax, eax		; see if rax is 0 now
	jnz	.uitoa_loop
	mov 	rax, rdi		; move both returns into correct calling convention
	mov	rdx, rcx
	ret
