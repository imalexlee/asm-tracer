format ELF64 executable 3

; link source files
include "system.s"
include "math.s"
include "geometry.s"

include "constants.inc"
include "macros.inc"
include "math.inc"
include "geometry.inc"

segment readable writeable

image_file 	db "image.ppm", 0
viewport_h	dd 2.0			; viewport height
focal_len	dd 1.0
cam_center	Vec3 0.0, 0.0, 0.0
viewport_u	Vec3 0.0, 0.0, 0.0
viewport_v	Vec3 0.0, -2.0, 0.0	; this is know ahead of time
pix_du		Vec3 0.0, 0.0, 0.0	; pixel delta u
pix_dv		Vec3 0.0, 0.0, 0.0	; pixel delta v
view_top_left	Vec3 0.0, 0.0, 0.0	; location of top left of viewport
pix00_pos	Vec3 0.0, 0.0, 0.0	; center point of first pixel
sky_blue	Vec3 0.5, 0.7, 1.0
white		Vec3 1.0, 1.0, 1.0

aspect_ratio	rd 1
viewport_w	rd 1			; viewport width



segment readable executable

entry $
	push	rbp
	mov	rbp, rsp
	sub	rsp, 16
	mov	dword [rbp - 4], 0	; i
	mov	dword [rbp - 8], 0	; j
	call	init_data
	syscall	2, image_file, 102o, 700o	; open with read/write permissions
	mov	[rbp - 12], eax		; save file descriptor
	mov	edi, eax
	call write_ppm_header
.i_loop:
	mov	dword [rbp - 8], 0	; reset j
.j_loop:
	; pix_center = pixel00_loc + (i * pixel_delta_u) + (j * pixel_delta_v)
	movups	xmm0, [pix00_pos]
	movups	xmm1, [pix_du]
	cvtsi2ss	xmm2, [rbp - 8] 
	vec_muls	xmm1, xmm2
	addps	xmm0, xmm1
	movups	xmm1, [pix_dv]
	cvtsi2ss	xmm2, [rbp - 4] 
	vec_muls	xmm1, xmm2
	addps	xmm0, xmm1
	; ray_direction = pix_center - cam_center;
	movups	xmm1, [cam_center]
	subps	xmm0, xmm1
	movaps	xmm1, xmm0		; direction
	movups	xmm0, [cam_center]	; origin
	call 	ray_color	
	mov	edi, [rbp - 12]
	call	write_color

	inc	dword [rbp - 8]
	cmp	dword [rbp - 8], IMAGE_WIDTH	
	jl	.j_loop

	inc	dword [rbp - 4]
	cmp	dword [rbp - 4], IMAGE_HEIGHT	; if i < image height 
	jl	.i_loop

	
	leave
  	syscall 60, 0		; exit

; initializes data regarding aspect ratio, viewport, etc.
; based on image height and width defined as a constant
; inputs:
;	none
; outputs:
;	none
init_data:
	pxor	xmm0, xmm0
	pxor	xmm1, xmm1
	mov	eax, IMAGE_WIDTH
	cvtsi2ss	xmm0, eax
	mov	eax, IMAGE_HEIGHT
	cvtsi2ss	xmm1, eax
	divss	xmm0, xmm1		; width / height
	movss	[aspect_ratio], xmm0
	movss	xmm1, [viewport_h]
	mulss	xmm0, xmm1		; viewport_h * aspect_ratio
	movss	[viewport_w], xmm0
	movss	[viewport_u.x], xmm0	; view_u = {view_width, 0.0, 0.0}	
	; horizontal and vertical delta vectors from pixel to pixel
	movups		xmm0, [viewport_v]
	cvtsi2ss	xmm1, eax	; image height to xmm1
	vec_divs xmm0, xmm1		; pix_delta_v = viewport_v / image_height
	movups	[pix_dv], xmm0
	mov	eax, IMAGE_WIDTH
	movups		xmm0, [viewport_u]
	cvtsi2ss	xmm1, eax	; image width to xmm1
	vec_divs xmm0, xmm1		; pix_delta_u = viewport_u / image_width
	movups	[pix_du], xmm0
	; calculate upper left locations
	pxor	xmm0, xmm0
	movups	xmm1, [viewport_u]
	por	xmm0, xmm1
	movups	xmm1, [viewport_v]
	por	xmm0, xmm1
	; divide viewport u and v by 2
	mov	eax, 2.0
	pinsrd	xmm1, eax, 0
	vec_divs	xmm0, xmm1		
	pinsrd	xmm0, [focal_len], 2	; xmm0 = {view_u / 2, view_v / 2, focal}
	movups	xmm1, [cam_center]
	subps	xmm1, xmm0
	movups	[view_top_left], xmm1
	; find pixel 00 location
	pxor	xmm0, xmm0
	pxor	xmm2, xmm2
	movups	xmm2, [pix_du]
	por	xmm0, xmm2
	movups	xmm2, [pix_dv]
	por	xmm0, xmm2
	mov	eax, 0.5
	pinsrd	xmm2, eax, 0
	vec_muls	xmm0, xmm2
	addps	xmm1, xmm0
	movups	[pix00_pos], xmm1
	pxor	xmm0, xmm0
	pxor	xmm1, xmm1
	pxor	xmm2, xmm2
	xor	rax, rax
	ret
