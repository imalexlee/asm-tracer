segment readable writeable
; constant immediates
IMAGE_WIDTH = 1080
IMAGE_HEIGHT = 1080
SYS_WRITE = 1
SYS_OPEN = 2
SYS_EXIT = 60

; constants in memory
color_scale	dd 255.999
msg 		db "hello world", 0xA
image_file 	db "image.ppm", 0

; variables
intstr_buf	rb 10
header_buf	rb 20
line_buf	rb 12
