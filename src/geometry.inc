struc Vec3 x, y, z {
	.x dd x
	.y dd y
	.z dd z
	.w dd 0
}

; takes 2 Vec3 
struc Ray orig, dir {
	.orig = orig
	.dir = dir
}
