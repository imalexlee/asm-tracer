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
	sub	rsp, 16
	movups	[rbp - 16], xmm0	; save ray origin
	movaps	xmm0, xmm1
	call vec_norm
	movaps	xmm1, xmm0 		; save returned unit direction
	movups	xmm0, [rbp - 16]
	movups	xmm2, [sphere.orig]
	movss	xmm3, [sphere.rad]
	call	hit_sphere
	cmp	rax, 0
	je	.no_hit
	movups	xmm0, [red]
	jmp	.end
.no_hit:
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
.end:
	leave
	ret

; return 1 or 0 based on if a given ray hits a given sphere
; inputs:
;	xmm0: ray origin
;	xmm1: ray direction (assumes normalized)
;	xmm2: sphere center (x, y, z, 0)
;	xmm3: sphere radius
; outputs: 
;	rax: 1 or 0 for hit or not hit
hit_sphere:
	subps	xmm2, xmm0		; oc. origin -> center
	; a = dot(r.direction(), r.direction());
	vdpps	xmm0, xmm1, xmm1, 01110001b	; a
	; b = -2.0 * dot(r.direction(), oc);
	vdpps	xmm4, xmm1, xmm2, 01110001b
	mov	eax, -2.0
	pinsrd	xmm5, eax, 0
	mulss	xmm4, xmm5
	; c = dot(oc, oc) - radius*radius;
	vdpps	xmm6, xmm2, xmm2, 01110001b
	mulss	xmm3, xmm3
	subss	xmm6, xmm3		; c
	; discriminant = b*b - 4*a*c;
	mulps	xmm4, xmm4
	mov	eax, 4.0
	pinsrd	xmm5, eax, 0
	mulss	xmm0, xmm5
	mulss	xmm0, xmm6
	subss	xmm4, xmm0		; discriminant
	pxor	xmm1, xmm1
	; if discrimiant >= 0, return true
	comiss	xmm4, xmm1
	jb	.lt_zero
	mov rax, 1
	jmp	.end
.lt_zero:
	mov rax, 0
.end:
	ret
