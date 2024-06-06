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

time 	dd 1.3
u Vec3 1.0 ,2.0, 3.0
v Vec3 4.0 ,5.0, 6.0
color Vec3 0.3, 0.8, 0.5
ray Ray u, v


segment readable executable

entry $
	call 	test_vec_norm	
  	syscall SYS_EXIT, 0		; exit

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

        
