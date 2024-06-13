format ELF64 executable 3

; link source files
include "system.s"
include "math.s"
include "geometry.s"

include "constants.inc"
include "math.inc"
include "geometry.inc"


segment readable writeable

viewport_h	dd 2.0			; viewport height
focal_len	dd 1.0
sphere_origin	Vec3 0.0, 0.0, -1.0
sphere		Sphere sphere_origin, 0.5
cam_center	Vec3 0.0, 0.0, 0.0
viewport_u	Vec3 0.0, 0.0, 0.0
viewport_v	Vec3 0.0, -2.0, 0.0	; this is know ahead of time
pix_du		Vec3 0.0, 0.0, 0.0	; pixel delta u
pix_dv		Vec3 0.0, 0.0, 0.0	; pixel delta v
view_top_left	Vec3 0.0, 0.0, 0.0	; location of top left of viewport
pix00_pos	Vec3 0.0, 0.0, 0.0	; center point of first pixel
sky_blue	Vec3 0.5, 0.7, 1.0
white		Vec3 1.0, 1.0, 1.0
red		Vec3 1.0, 0.0, 0.0
time 		dd 1.3
message		db "255 255 255", 10
test_image 	db "test.ppm", 0
u 		Vec3 1.0 ,2.0, 3.0
v 		Vec3 4.0 ,5.0, 6.0
color 		Vec3 0.3, 0.8, 0.5
ray 		Ray u, v


segment readable executable

entry $
	call 	test_write
  	syscall SYS_EXIT, 0		; exit

test_write:
	push	rbp
	mov	rbp, rsp
	mov	dword [rbp - 4], 0	; i
	mov	dword [rbp - 8], 0	; j
	syscall SYS_OPEN, test_image, 102o, 700o
	mov	rdi, rax
	syscall	SYS_WRITE, rdi, message, 12
.i_loop:
	mov	dword [rbp - 8], 0	; reset j
.j_loop:
	syscall	SYS_WRITE, rdi, message, 12
	inc	dword [rbp - 8]
	cmp	dword [rbp - 8], IMAGE_WIDTH	
	jl	.j_loop

	inc	dword [rbp - 4]
	cmp	dword [rbp - 4], IMAGE_HEIGHT	; if i < image height 
	jl	.i_loop
	leave
	ret


test_vec_norm:
	movups	xmm0, [v]
	call	vec_norm
	ret	

test_ray_at:	
 	movups	xmm0, [ray.dir]
	call	vec_norm
	movaps	xmm2, xmm0
	movups	xmm0, [ray.orig]
 	movaps	xmm1, xmm2
	movss	xmm2, [time]
	call	ray_at
	ret

        
