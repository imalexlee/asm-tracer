; MACROS
; ---------------------------------------------------------------------------------------

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
