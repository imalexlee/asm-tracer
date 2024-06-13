; FUNCTION MACROS
; ---------------------------------------------------------------------------------------

; multiplies all items in a vec holding 3 single precision floats by a scalar float
; inputs:
;	vec_reg1: vec to multiply
;	vec_reg2: scalar float to multiply by in lowest dword
; outputs:
;	vec_reg1: vector holding multiplied data
macro vec_muls vec_reg1, vec_reg2 {
	shufps	vec_reg2, vec_reg2, 11000000b	; copy value to all positions except last
	mulps	vec_reg1, vec_reg2 
}

; divides all items in a vec holding 3 single precision floats by a scalar float
; inputs:
;	vec_reg1: vec to divide 
;	vec_reg2: scalar float to divide by in lowest dword
; outputs:
;	vec_reg1: vector holding divided data
macro vec_divs vec_reg1, vec_reg2 {
	shufps	vec_reg2, vec_reg2, 00000000b	; copy value to all positions to avoid div by 0
	divps	vec_reg1, vec_reg2 
}

; subtracts all items in a vec holding 3 single precision floats by a scalar float
; inputs:
;	vec_reg1: vec to subtract from 
;	vec_reg2: scalar float to subtract by in lowest dword
; outputs:
;	vec_reg1: vector holding subtracted data
macro vec_subs vec_reg1, vec_reg2 {
	shufps	vec_reg2, vec_reg2, 11000000b	; copy value to all positions except last
	subps	vec_reg1, vec_reg2 
}

; adds all items in a vec holding 3 single precision floats by a scalar float
; inputs:
;	vec_reg1: vec to add to
;	vec_reg2: scalar float to add by in lowest dword
; outputs:
;	vec_reg1: vector holding added data
macro vec_adds vec_reg1, vec_reg2 {
	shufps	vec_reg2, vec_reg2, 11000000b	; copy value to all positions except last
	addps	vec_reg1, vec_reg2 
}
