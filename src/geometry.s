; Geometric operations
; ---------------------------------------------------------------------------------------

; Given a sphere center, radius, and max t value, calculate whether or not 8 ray samples 
; hit the sphere. If so, generate 8 hit points, normals, and t values for each.
; inputs:
;	ymm1: 8 ray direction x values
;	ymm2: 8 ray direction y values
;	ymm3: 8 ray direction z values
;	xmm4: sphere center
;	xmm5: sphere radius
;	xmm6: t_max
; outputs:
;	ymm1: t values for all rays. 0 where there is no hit
;	ymm2: hit position x values
;	ymm3: hit position y values
;	ymm4: hit position z values
;	ymm5: normal x values
;	ymm6: normal y values
;	ymm7: normal z values
macro hit_sphere {
	; a = dp(ray_dir, ray_dir)
	vmulps		ymm12, ymm1, ymm1		; [x_1^2, x_2^2...]
	vfmadd231ps	ymm12, ymm2, ymm2		; [... + y_1^2, ...]
	vfmadd231ps	ymm12, ymm3, ymm3		; a = [... + z_1^2, ...]
	; oc = sphere_center - ray_orig
	movups		xmm8, [cam_center]
	vsubps		xmm13, xmm8, xmm4		; oc 
	; b = dp(ray_dir, oc)
	vshufps		ymm14, ymm13, ymm13, 0		; copy oc.x to all elements
	vshufps		ymm7, ymm13, ymm13, 85		; copy oc.y to all elements
	vshufps		ymm15, ymm13, ymm13, 170	; copy oc.x to all elements
	vmulps		ymm13, ymm1, ymm14		; [dir.x_1 * oc.x_1, ...]
	vfmadd231ps	ymm13, ymm2, ymm7		; [... + dir.y_1 * oc.y_1, ...]
	vfmadd231ps	ymm13, ymm3, ymm15		; b = [... + dir.z_1 * oc.z_1, ...]
	; c = dp(oc, oc) - radius^2
	vmulps		ymm14, ymm14, ymm14		; [oc_1.x^2, ...]
	vfmadd231ps	ymm14, ymm7, ymm7		; [... + oc_1.y^2, ...]
	vfmadd231ps	ymm14, ymm15, ymm15		; [... + oc_1.z^2, ...]
	vshufps		ymm5, ymm5, ymm5, 0		; copy radius to all elements
	vmulps		ymm15, ymm5, ymm5		; radius^2
	vsubps		ymm14, ymm14, ymm15		; c
	; discriminant = b^2 - a*c
	vmulps		ymm14, ymm14, ymm12		; a*c
	vfmsub231ps	ymm14, ymm13, ymm13		; discriminant
	; if discriminant < 0, create a mask of hits and no-hits
	vpxor		ymm15, ymm15, ymm15
	vcmpps		ymm15, ymm14, ymm15, 5		; 8 ps mask values: 0 = no hit, 1 = hit
	; sqrtd = sqrt(discriminant). using reciprocal and mulps because less clocks than sqrt
	vrsqrtps	ymm7, ymm15			; 1 / sqrt(discriminant)
	vmulps		ymm14, ymm7, ymm15		; sqrtd
	; root = (b - sqrtd) / a;
	; use our mask from the discriminant comparison to maintain 0's where there's no hit
	vmulps		ymm13, ymm13, ymm15		; mask the current b values
	vmulps		ymm14, ymm14, ymm15		; mask the current sqrtd values
	vrcpps		ymm12, ymm12			; a = 1 / a
	vsubps		ymm15, ymm13, ymm14		; b - sqrtd
	vmulps		ymm15, ymm15, ymm12		; [root_1, root_2, ...]
	; if root >= t_max, no hit
	vshufps		ymm6, ymm6, ymm6, 0		; copy t_max to all elements
	vcmpps		ymm12, ymm15, ymm6, 1		; 8 ps mask values: 0 = no hit, 1 = hit
	vmulps		ymm15, ymm15, ymm12
	; hit_point = ray_orig + t(root)*ray_dir
	vshufps		ymm12, ymm8, ymm8, 0		; copy sphere_origin.x to all elements 
	vshufps		ymm13, ymm8, ymm8, 85		; copy sphere_origin.y to all elements
        vshufps		ymm14, ymm8, ymm8, 170		; copy sphere_origin.z to all elements
	vfmadd231ps	ymm12, ymm1, ymm15		; [hit_point_1.x^2, ...]
	vfmadd231ps	ymm13, ymm2, ymm15		; [... + hit_point_1.y^2, ...]
	vfmadd231ps	ymm14, ymm3, ymm15		; [... + hit_point_1.z^2, ...]
	; outward_normal = (hit_point - sphere_center) / radius
	vrcpps		ymm5, ymm5			; radius = 1 / radius
        vshufps		ymm6, ymm4, ymm4, 0		; copy sphere_center.x to all elements
	vsubps		ymm9, ymm12, ymm6		; [hit_point_1.x - sphere_center, ...]
	vmulps		ymm9, ymm9, ymm5		; [... / radius, ...]
        vshufps		ymm6, ymm4, ymm4, 85		; copy sphere_center.y to all elements
	vsubps		ymm10, ymm13, ymm6		; [hit_point_1.y - sphere_center, ...]
	vmulps		ymm10, ymm10, ymm5		; [... / radius, ...]
        vshufps		ymm6, ymm4, ymm4, 170		; copy sphere_center.z to all elements
	vsubps		ymm11, ymm14, ymm6		; [hit_point_1.z - sphere_center, ...]
	vmulps		ymm11, ymm11, ymm5		; [... / radius, ...]
	; invert normals if the ray is hitting a back face
	; if dp(ray_dir, outward_normal) >= 0, outward_normal *= -1.0
	vmulps		ymm1, ymm1, ymm9		; [ray_dir_1.x * out_norm_1.x, ...]
	vfmadd231ps	ymm1, ymm2, ymm10		; [... + ray_dir_1.y * out_norm_1.y, ...]
	vfmadd231ps	ymm1, ymm3, ymm11		; [... + ray_dir_1.y * out_norm_1.y, ...]
	vpxor		ymm2, ymm2, ymm2
	vcmpps		ymm2, ymm1, ymm2, 1		; 8 ps mask values: 0 = back face, 1 = front face
	vaddps		ymm2, ymm2, ymm2		; 0 = back face, 2 = front face
	mov		eax, 1.0
	movd		xmm3, eax
	vshufps		ymm3, ymm3, ymm3, 0		; copy 1.0 to all elements
	vsubps		ymm2, ymm2, ymm3		; now, -1 = back face, 1 = front face
	vmulps		ymm9, ymm9, ymm2		; invert normal x's that hit a back face
	vmulps		ymm10, ymm10, ymm2		; invert normal y's that hit a back face
	vmulps		ymm11, ymm11, ymm2		; invert normal z's that hit a back face
	; mov registers to correct output order
	vmovaps		ymm1, ymm15			; t values
	vmovaps		ymm2, ymm12			; hit position x's
	vmovaps		ymm3, ymm13			; hit position y's
	vmovaps		ymm4, ymm14			; hit position z's
	vmovaps		ymm5, ymm9			; normal x's
	vmovaps		ymm6, ymm10			; normal y's
	vmovaps		ymm7, ymm11			; normal z's
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
	movaps	xmm0, xmm12				; restore ray origin
	movaps	xmm1, xmm13				; restore ray dir
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

