format PE GUI 4.0

entry EntryPoint

include 'win32a.inc'
include 'macro\proc32.inc'

proc EntryPoint
  ; Get PEB structure
  xor eax, eax
  mov al, 0x2F
  mov eax, dword [fs:eax + 1]

  ; Get 'InLoadOrder' list fromPEB
  mov edx, [eax + 0x0C] ; edx = pLdr
  mov edx, [edx + 0x0C] ; edx = pFirstElem
  mov eax, edx          ; eax = pElem

  ; Write 'K\0E\0' in ESI
  mov esi, 0x8045804B ;
  and esi, 0x7FFF7FFF

.A:
  mov ecx, [eax + 0x30]
  mov ecx, [ecx]

  cmp ecx, esi
  je .B

  dec eax
  mov eax, [eax + 1]
  jmp .A

.B:
  ; ECX - BaseAddress

  mov ecx, [eax + 0x18] ; pElem->BaseAddress
  mov eax, [ecx + 0x3C] ; nt header
  mov esi, [ecx + eax + 0x78]

  ; EDI - AddressOfNames
  lea edi, [ecx + esi]
  mov edi, [edi + 0x20]
  lea edi, [edi + ecx]
  ; EBX - AddressOfFunctions
  lea ebx, [ecx + esi]
  mov ebx, [ebx + 0x1C]
  lea ebx, [ebx + ecx]
  ; ESI - AddressOfNameOrdinals
  lea esi, [ecx + esi]
  mov esi, [esi + 0x24]
  lea esi, [esi + ecx]

  xor ebp, ebp
.C:
  mov eax, [edi]
  add eax, ecx
  mov edx, [eax]
  cmp edx, 0x456E6957
  je .D
  add edi, 4
  add esi, 2
  jmp .C
.D:
  xor eax, eax
  mov ax, word [esi]
  add eax, eax
  add eax, eax
  add ebx, eax
  mov eax, [ebx] ; offset
  add eax, ecx ; EAX = WinExec

  sub esp, 0x64
  sub esp, 0x64
  sub esp, 0x64
  sub esp, 0x64
  lea ecx, [esp]

  xor edx, edx
  mov byte [ecx+1], 'c'
  mov byte [ecx+2], 'a'
  mov byte [ecx+3], 'l'
  mov byte [ecx+4], 'c'
  mov byte [ecx+5], '.'
  mov byte [ecx+6], 'e'
  mov byte [ecx+7], 'x'
  mov byte [ecx+8], 'e'
  mov byte [ecx+9], dl
  inc ecx

  push SW_SHOW
  push ecx
  call eax

  ret
endp