; MACROINSTRUCTIONS 
; ---------------------------------------------------------------------------------------
macro syscall sys_num, arg1, arg2, arg3, arg4, arg5, arg6 {
  if sys_num eq
  else
    mov rax, sys_num
  end if
  if arg1 eq
  else
    mov rdi, arg1
  end if
  if arg2 eq
  else
    mov rsi, arg2
  end if
  if arg3 eq
  else
    mov rdx, arg3
  end if
  if arg4 eq
  else
    mov r10, arg4
  end if
  if arg5 eq
  else
    mov r8, arg5
  end if
  if arg6 eq
  else
    mov r9, arg6
  end if
  syscall
}
