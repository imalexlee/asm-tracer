; Render system

include "math.inc"

; writes an RGB value in a 3 value single precision vector
; inputs:
;	rdi: file descriptor to write to
;	xmm0: color to write
; outputs:
;	none
write_color:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 16
	movss	xmm1, [color_scale]
	vec_muls
	cvtps2dq 	xmm0, xmm0	; multiply all values by 255.999

	movups	[rsp - 16], xmm0

	mov	rdi, line_buf
	mov	rsi, [rsp - 16]		; r
	mov	rdx, [rsp - 12]		; g
	mov	rcx, [rsp - 8]		; b
	call	write_img_line
	; TODO: actually write the line in that function
	leave	
	ret

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
	sub	rsp, 32			; allocate stack space
	mov	[rbp - 8], rdi		; save buffer address
	mov	[rbp - 12], esi		; r
	mov	[rbp - 16], edx		; g
	mov	[rbp - 20], ecx		; b
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

; MACROS 
; ---------------------------------------------------------------------------------------

macro syscall sys_num, arg1, arg2, arg3, arg4, arg5, arg6 {
  if sys_num eq
  else
    mov rax, sys_num
  end if
  if arg1 eq
  else
    mov rdi, arg1
  end if
  if arg2 eq
  else
    mov rsi, arg2
  end if
  if arg3 eq
  else
    mov rdx, arg3
  end if
  if arg4 eq
  else
    mov r10, arg4
  end if
  if arg5 eq
  else
    mov r8, arg5
  end if
  if arg6 eq
  else
    mov r9, arg6
  end if
  syscall
}
