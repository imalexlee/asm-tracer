

format ELF64 executable 3

include "macros.inc"
include "data.inc"
include "system.s"
include "math.s"
include "geometry.s"
include "material.s"


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



			
