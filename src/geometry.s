; Geometric operations
; ---------------------------------------------------------------------------------------


; return -1 or time t at ray-sphere intersct based on
; if a given ray hits a given sphere
; inputs:
;	xmm1: ray direction
;	xmm2: sphere center
;	xmm3: sphere radius
;	xmm4: t_max
; outputs: 
;	xmm2: normal vector at point that has hit the sphere
;	xmm3: the point at t on the ray if there is a hit
;	xmm4: -1 (no hit) or time t where ray intersects sphere
; mangles:
;	eax, xmm2-8
macro hit_sphere {
	vsubps	xmm5, xmm2, [cam_center]	; oc = center - origin
	vdpps	xmm6, xmm1, xmm1, 01110001b	; a = dp(dir, dir)
	vdpps	xmm7, xmm1, xmm5, 01110001b	; b = dp(dir, oc)
	dpps	xmm5, xmm5, 01110001b		; dp(oc, oc)
	vmulss	xmm8, xmm3, xmm3		; r2 = radius^2
	subss	xmm5, xmm8			; c = dp(oc, oc) - r2
	vmulss	xmm8, xmm7, xmm7		; b * b
	mulss	xmm5, xmm6			; a * c
	vsubss	xmm5, xmm8, xmm5		; discrim = b * b - a * c
	pxor	xmm8, xmm8
	comiss	xmm5, xmm8			; if discrim < 0, no hit
	jb	.no_hit
	rsqrtss	xmm8, xmm5			; 1 / sqrt(descrim)
	mulss	xmm5, xmm8			; sqrtd = (1 / sqrt(descrim)) * a
	rcpss	xmm6, xmm6			; a = 1 / a
	vsubss	xmm8, xmm7, xmm5		; b - sqrtd
	mulss	xmm8, xmm6			; t = (b - sqrtd) / a
	comiss	xmm8, xmm4			; if (t >= t_max) find other root for t
	jb	.hit
	vaddss	xmm8, xmm7, xmm5		; b + sqrtd
	mulss	xmm8, xmm6			; t = (b + sqrtd) / a
	comiss	xmm8, xmm4			; if (t >= t_max) no hit
	jae	.no_hit	
.hit:
	
.no_hit:
	mov	eax, -1.0
	pinsrd	xmm4, eax, 0			; ret -1 for no hit
.end:
}	

; computes the point on a ray at a given time t
; P(t) = A + tb
; inputs:
; 	xmm0: ray starting point
;	xmm1: ray dir. should be normalized 
;	xmm2: t(ime) float in lowest dword
; outputs:
;	xmm0: vec representing position at t along ray
; mangles:
;	xmm0-2
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
; mangles:
;	eax, xmm0-13
ray_color:
	movaps	xmm12, xmm0		
	movaps	xmm13, xmm1	
	movups	xmm2, [sphere.orig]
	movss	xmm3, [sphere.rad]
	hit_sphere
	mov	eax, 0.0
	pinsrd	xmm1, eax, 0
	comiss	xmm0, xmm1
	jbe	.no_sphere_hit
	; N = unit_vector(r.at(t) - vec3(0,0,-1));
	movaps	xmm2, xmm0		; move t
	movaps	xmm0, xmm12		; restore ray origin
	movaps	xmm1, xmm13		; restore ray dir
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
	ret
.no_sphere_hit:
	movaps	xmm0, xmm13
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
	ret

