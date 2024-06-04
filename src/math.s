; types
struc vec3 x, y, z {
	.x dd x
	.y dd y
	.z dd z
	.w dd 0
}

; finds the length of a given vector of 3 single precision floats
; inputs:
;	xmm0: 3 element vector to convert (expects 0 in highest dword)
; outputs:
;	xmm0: single precision float representing length
vec_len:
	mulps	xmm0, xmm0		; a^2, b^2, c^2	
	haddps	xmm0, xmm0		; 2 iterations needed
	haddps	xmm0, xmm0		; sum of squares in lowest dword
	sqrtss	xmm0, xmm0
	ret

; converts vector of 3 single precision floats to unit length
; inputs:
;	xmm0: vector to convert
; outputs:
;	xmm0: converted vector
vec_norm:
	pxor	xmm1, xmm1
	movaps	xmm1, xmm0
	call	vec_len
	shufps	xmm0, xmm0, 00000000b	; copy returned len to all 4 dwords
	divps	xmm1, xmm0		; vec3 / len
	movaps	xmm0, xmm1
	ret

; cross product of two vectors holding 3 single precision floats
; inputs:
;	xmm0: vec u
;	xmm1: vec v
; outputs:
;	xmm0: vector holding cross product
cross_prod:
	shufps	xmm0, xmm0, 11001001b	; u0 u1 u2 -> u1 u2 u0 
	shufps	xmm1, xmm1, 11010010b	; v0 v1 v2 -> v2 v0 v1 
	pxor	xmm3, xmm3
	vmulps	xmm3, xmm0, xmm1	; u1v2 u2v0 u0v1
	shufps	xmm0, xmm0, 11001001b 	; u1 u2 u0 -> u2 u0 u1 
	shufps	xmm1, xmm1, 11010010b 	; v2 v0 v1 -> v1 v2 v0
	pxor	xmm4, xmm4
	vmulps	xmm4, xmm0, xmm1	; u2v1 u0v2 u1v0
	subps	xmm3, xmm4		; u1v2 - u2v1, u2v0 - u0v2, u0v1 - u1v0
	movaps	xmm0, xmm3
	ret

; multiplies all items in a vec holding 3 single precision floats by a scalar float
; inputs:
;	xmm0: vec to multiply
;	xmm1: scalar float to multiply by in lowest dword
; outputs:
;	xmm0: vector holding multiplied data
macro vec_muls  {
	shufps	xmm1, xmm1, 11000000b	; copy value to all positions except last
	mulps	xmm0, xmm1
}
