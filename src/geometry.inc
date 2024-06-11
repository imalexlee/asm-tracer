struc Vec3 x, y, z {
	.x dd x
	.y dd y
	.z dd z
	.w dd 0
}

; takes 2 Vec3 
struc Ray origin, direction {
	.orig = origin
	.dir = direction
}

; takes a Vec3 and float
struc Sphere origin, radius {
	.orig = origin
	.rad dd radius
}
