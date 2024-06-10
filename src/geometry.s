; Geometric operations
; ---------------------------------------------------------------------------------------

; computes the point on a ray at a given time t
; P(t) = A + tb
; inputs:
; 	xmm0: ray starting point
;	xmm1: ray dir. should be normalized 
;	xmm2: t(ime) float in lowest dword
; outputs:
;	xmm0: vec representing position at t along ray
ray_at:
	vec_muls	xmm1, xmm2
	addps	xmm0, xmm1
	ret

; computes the color of a ray
; blended_value = (1 - a) * startValue + a * endValue
; inputs:
;	xmm0: ray starting point
;	xmm1: ray dir
; outputs:
;	xmm0: ray color (r, g, b, 0)
ray_color:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 32
	movups	[rsp - 16], xmm0
	movups	[rsp - 32], xmm1
	movaps	xmm0, xmm1
	call vec_norm			; unit direction
	shufps	xmm0, xmm0, 11010101b	; copy y to all channels. sky blends in y dir 
	mov	eax, 1.0
	pinsrd	xmm1, eax, 0
	addss	xmm0, xmm1		; unit_dir.y + 1.0
	mov	eax, 0.5
	pinsrd	xmm1, eax, 0
	mulss	xmm0, xmm1		; a = 5.0(unit_dir.y + 1.0)
	movups	xmm1, [sky_blue]
	vec_muls	xmm1, xmm0
	movups	xmm2, [white]
	mov	eax, 1.0
	pinsrd	xmm3, eax, 0
	subss	xmm3, xmm0		; 1.0 - a
	vec_muls	xmm2, xmm3
	vaddps	xmm0, xmm1, xmm2
	leave
	ret

