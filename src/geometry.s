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
	movups	[rbp - 16], xmm0	; save ray origin
	movups	[rbp - 32], xmm1	; save ray dir
	movups	xmm2, [sphere.orig]
	movss	xmm3, [sphere.rad]
	call	hit_sphere
	mov	eax, 0.0
	pinsrd	xmm1, eax, 0
	comiss	xmm0, xmm1
	jbe	.no_sphere_hit
	; N = unit_vector(r.at(t) - vec3(0,0,-1));
	movaps	xmm2, xmm0		; move t
	movups	xmm0, [rbp - 16]	; restore ray origin
	movups	xmm1, [rbp - 32]	; restore ray dir
	call	ray_at
	movups	xmm2, [sphere.orig]
	subps	xmm0, xmm2
	call	vec_norm		; xmm0 <=> N
	; return 0.5*color(N.x()+1, N.y()+1, N.z()+1);
	mov	eax, 1.0
	pinsrd	xmm1, eax, 0
	vec_adds	xmm0, xmm1
	mov	eax, 0.5
	pinsrd	xmm1, eax, 0
	vec_muls	xmm0, xmm1
	leave
	ret
.no_sphere_hit:
	movups	xmm0, [rbp - 32]
	call vec_norm
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

; return -1 or time t at ray-sphere intersct based on
; if a given ray hits a given sphere
; inputs:
;	xmm0: ray origin
;	xmm1: ray direction
;	xmm2: sphere center
;	xmm3: sphere radius
;	xmm4: t_min
;	xmm5: t_max
; outputs: 
;	xmm0: -1 or time t where ray intersects sphere
hit_sphere:
	
	mov	eax, 0.0
	pinsrd	xmm4, eax, 0		; hardcode t_min
	mov	eax, 10000000.0
	pinsrd	xmm5, eax, 0		; hardcode t_max
	subps	xmm2, xmm0		; oc. origin -> center
	; a = dot(r.direction(), r.direction()); = 1.0
	vdpps	xmm0, xmm1, xmm1, 01110001b
	; b = dot(r.direction(), oc);
	vdpps	xmm6, xmm1, xmm2, 01110001b
	; c = dot(oc, oc) - radius*radius;
	vdpps	xmm7, xmm2, xmm2, 01110001b
	mulss	xmm3, xmm3
	subss	xmm7, xmm3		; c
	; discriminant = b*b - a*c;
	vmulps	xmm1, xmm6, xmm6
	vmulss	xmm2, xmm7, xmm0
	subss	xmm1, xmm2		; discriminant
	pxor	xmm8, xmm8
	; if discrimiant >= 0, return true
	comiss	xmm5, xmm8
	jb	.no_hit
	; root = (b - sqrt(discriminant)) / a;
	rsqrtss	xmm8, xmm1
	mulss	xmm8, xmm1		; less clocks w/ rsqrt + mulss
	vsubss	xmm7, xmm6, xmm8
	vdivss	xmm1, xmm7, xmm0	; root
	comiss	xmm1, xmm4
	jbe	.alt_root		; root <= t_min (not in range)
	comiss	xmm5, xmm1
	ja	.in_range		; t_max > root (in range)
.alt_root:
	; root = (b + sqrt(discriminant)) / a;
	vaddss	xmm7, xmm6, xmm8
	vdivss	xmm1, xmm7, xmm0	; root
	comiss	xmm1, xmm4		; root <= t_min (not in range)
	jbe	.no_hit
	comiss	xmm5, xmm1		; t_max <= root (not in range)
	jbe	.no_hit
.in_range:
	movaps	xmm0, xmm1	
	jmp	.end
.no_hit:	
	pxor	xmm0, xmm0
	mov 	eax, -1.0
	pinsrd	xmm0, eax, 0
.end:
	ret
