format ELF64 executable 3

; link source files
include "system.s"
include "math.s"

include "constants.inc"
include "macros.inc"
include "math.inc"
include "types.inc"

segment readable writeable

u vec3 1.0 ,2.0, 3.0
v vec3 4.0 ,5.0, 6.0
color vec3 0.3, 0.8, 0.5

segment readable executable

entry $
	xor	rdi, rdi
	mov	rdi, 1
	call write_ppm_header
	movups	xmm0, [color]
	mov	rdi, 1
	call write_color
  	syscall 60, 0		; exit
