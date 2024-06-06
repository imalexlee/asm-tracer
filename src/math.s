; Generic primitive math functions
; ---------------------------------------------------------------------------------------

; finds the length of a given vector of 3 single precision floats
; sqrt(x^2 + b^2 + c^2)
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
; (x, y, z) / vec_len
; inputs:
;	xmm0: vector to convert
; outputs:
;	xmm0: converted vector
vec_norm:
	pxor	xmm1, xmm1
	movaps	xmm1, xmm0
	call	vec_len
	vec_divs	xmm1, xmm0
	movaps	xmm0, xmm1
	ret

; cross product of two vectors holding 3 single precision floats
; i(u1v2 - u2v1), j(u2v0 - u0v2), k(u0v1 - u1v0)
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
	subps	xmm3, xmm4		
	movaps	xmm0, xmm3
	ret

