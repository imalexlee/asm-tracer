; System interfacing functionality
; ---------------------------------------------------------------------------------------

include "math.inc"
include "constants.inc"
include "system.inc"

segment readable writeable

color_scale	dd 255.999

intstr_buf	rb 10
header_buf	rb 20
line_buf	rb 30

segment readable executable

; writes an RGB value in a 3 value single precision vector
; inputs:
;	rdi: file descriptor to write to
;	xmm0: color to write
; outputs:
;	none
write_color:
	movss	xmm1, [color_scale]	
	vec_muls 	xmm0, xmm1	; multiply all values by 255.999
	cvtps2dq 	xmm0, xmm0	
	call	write_img_line
	ret

; writes a line for the image -> "<r> <g> <b>\n"
; inputs:
; 	rdi: file descriptor
; 	xmm0: color
; outputs:
;	none
write_img_line:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 28			; allocate stack space
	mov	[rbp - 4], edi		; save fd
	movups	[rbp - 20], xmm0	; save r,g,b. (and unused last float in register as well)
	lea	r8, [rbp - 20]		; save initial first in r8 for later indexing
	mov	dword [rbp - 24], 0	; i for loop
	mov	dword [rbp - 28], 0	; string length
	cld				; clear direction flag (iterate forward)
.loop:
	; convert r, then g, then b to string	
	xor	rdi, rdi
	mov	edi, [r8]		; move color value into edi
	add	r8, 4			; move to next color on next iter
	call	uitoa
	
	mov	rcx, rdx		; move str len to rcx for string op
	dec	rcx			; don't care about null terminator
	mov	rsi, rax		; move source str to rsi for string op
	xor	rdi, rdi
	mov	rdi, line_buf		; restore rdi to start pos of buffer for string op
	add	edi, [rbp - 28] 	; offset start pos by current str len
	add	[rbp - 28], ecx		; add color string length to total line length 
	rep movsb			; copy int string into buffer
	mov	byte [rdi], ' '
	inc	dword [rbp - 28]	; inc string length for the space ' '
	inc	dword [rbp - 24]	; i++
	cmp	dword [rbp - 24], 3	; while i < 3
	jl	.loop
	mov	byte [rdi], 10		; replace last space char w/ new line
	xor	rdi, rdi
	mov	edi, [rbp - 4]		; restore fd
	mov	rsi, line_buf		
	xor 	rdx, rdx
	mov	edx, [rbp - 28]
	syscall	SYS_WRITE, rdi, rsi, rdx
	leave
	ret

; creates the ppm image header given the current dimensions
; inputs:
;	rdi: file descriptor
; outputs:
;	none
write_ppm_header:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 20			; space for local vars
	mov	[rbp - 20], edi		; save fd
	mov	rdi, header_buf 
	mov	[rbp - 16], rdi		; save start pointer of buffer
	; "P3\n"
	mov 	byte [rdi], 'P'
	mov 	byte [rdi + 1], '3'
	mov 	byte [rdi + 2], 10
	add 	rdi, 3			; offset address for next section
	mov 	r8, 9			; we know we need at least 9 chars
	mov	[rbp - 8], rdi		; save rdi for next fn call	
	; WRITE WIDTH
	mov	rdi, IMAGE_WIDTH	
	call	uitoa
	mov 	rsi, rax		; move string buffer to rsi for string instructions
	mov	rdi, [rbp - 8]		; restore rdi to be the header buffer
	dec 	rdx			; don't care about null terminator in int string
	xor 	rcx, rcx		; zero the counter	
.loop1_start:				; loop to write width to buf
	inc	r8			; add to the total string size
	; move both buffer locations together
 	movs 	byte [rdi], [rsi]
	inc	rcx
	cmp 	rcx, rdx
	jl	.loop1_start
	mov	[rbp - 8], rdi		; save rdi for next fn call	
	; WRITE HEIGHT 
	mov	rdi, IMAGE_HEIGHT
	call	uitoa
	mov	rsi, rax
	mov	rdi, [rbp - 8]		; restore rdi to be the header buffer
	dec 	rdx			; don't care about null terminator in int string
	xor 	rcx, rcx		; zero the counter
	mov	byte [rdi], ' '		; space between w and h
	inc	rdi
.loop2_start:				; loop to write height to buf
	inc	r8			; add to the total string size
	; move both buffer locations together
	movs 	byte [rdi], [rsi]
	inc	rcx
	cmp 	rcx, rdx
	jl	.loop2_start
	; now write final \n255\n
	mov 	byte [rdi], 10
	mov 	byte [rdi + 1], '2'
	mov 	byte [rdi + 2], '5'
	mov 	byte [rdi + 3], '5'
	mov 	byte [rdi + 4], 10
	mov	rsi, [rbp - 16]
	mov	rdx, r8
	syscall SYS_WRITE, [rbp - 20], rsi, rdx
	leave
	ret	

; converts unsigned int to ascii string
; inputs:
;	rdi: number to convert
; outputs:
;	rax: pointer to start of null terminated string
;	rdx: length of string (with null terminator)	
uitoa:
	mov 	rsi, intstr_buf		; store buf ptr in rsi
	add	rsi, 9
	mov 	byte [rsi], 0		; null terminate end of string
	mov 	rax, rdi		; move number to rax for dividing
	mov	rdi, 10			; make rdi now store the divisor
	xor 	rcx, rcx
	add	rcx, 1			; count the terminator
.uitoa_loop:	
	inc	rcx			; increment length counter
	xor	edx, edx		; clear remainder since div uses edx:eax combined 64 bit reg
	div	rdi			; get remainder into edx
	add	edx, '0'		; add 48 ('0') to convert remainder to ascii
	dec	rsi			; move string buffer pointer back a byte
	mov	byte [rsi], dl		; set byte in string
	test	eax, eax		; see if rax is 0 now
	jnz	.uitoa_loop
	mov 	rax, rsi		; move both returns into correct calling convention
	mov	rdx, rcx
	ret
