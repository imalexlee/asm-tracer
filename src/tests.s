format ELF64 executable 3

include "macros.inc"
include "system.s"
include "math.s"
inlclude "math.inc"

segment readable writeable

; variables
color_scale	dd 255.999
msg 		db "hello world", 0xA
image_file 	db "image.ppm", 0
intstr_buf	rb 10
header_buf	rb 20
line_buf	rb 12
u vec3 1.0 ,2.0, 3.0
v vec3 4.0 ,5.0, 6.0

segment readable executable

entry $
	pxor xmm0, xmm0
	pxor xmm1, xmm1
	movups	xmm0, [u]
	movups	xmm1, [v]

	vec_muls

  	syscall 60, 0		; exit
