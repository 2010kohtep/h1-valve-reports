#pragma once

#include <Windows.h>
#include "..\Common\ntdll.h"

#ifdef FORCEINLINE
	#undef FORCEINLINE
#endif

#ifdef DEBUG
	#define FORCEINLINE
#else
	#define FORCEINLINE __forceinline
#endif

static FORCEINLINE void ZeroMem(void *addr, int count)
{
	auto pAddr = (unsigned char *)addr;

	for (int i = 0; i < count; i++)
		pAddr[i] = 0;
}

static FORCEINLINE int StrICompW(const wchar_t *str1, const wchar_t *str2)
{
	auto p1 = str1;
	auto p2 = str2;

	while (true)
	{
		wchar_t c1, c2;

		if (*p1 >= 'a' && *p1 <= 'z')
			c1 = *p1 ^ 0x20;
		else
			c1 = *p1;

		if (*p2 >= 'a' && *p2 <= 'z')
			c2 = *p2 ^ 0x20;
		else
			c2 = *p2;

		if (c1 != c2 || c1 == '\0')
			return c1 - c2;

		p1++;
		p2++;
	}
}

static FORCEINLINE wchar_t *StrPosW(const wchar_t *str1, const wchar_t *str2)
{
	auto result = nullptr;

	if (!str1 || !*str1 || !str2 || !*str2)
		return result;

	auto matchStart = str1;
	while (*matchStart != '\0')
	{
		if (*matchStart == *str2)
		{
			auto lstr1 = matchStart + 1;
			auto lstr2 = str2 + 1;

			while (true)
			{
				if (*lstr2 == '\0')
					return (wchar_t *)matchStart;

				if (*lstr1 != *lstr2 || *lstr1 == '\0')
					break;

				lstr1++;
				lstr2++;
			}
		}

		matchStart++;
	}

	return result;
}

static FORCEINLINE int StrLenW(const wchar_t *str)
{
	auto ps = str;

	while (*ps)
		ps++;

	return ps - str;
}

static __forceinline void *GetModuleHandlePeb(const wchar_t *moduleName)
{
	TProcessEnvironmentBlock *peb;

	__asm
	{
		mov eax, dword ptr fs : [0x30];
		mov dword ptr[peb], eax;
	}

	if (!moduleName || !*moduleName)
		return peb->ImageBaseAddress;

	auto ldr = peb->Ldr;
	auto list = (TLdrModule *)ldr->InLoadOrder.Flink;
	auto flist = list;

	do
	{
		auto base = (void *)list->BaseAddress;

		if (base)
		{
			auto remoteModule = list->BaseDllName.Buffer;

			if (!StrICompW(remoteModule, moduleName))
				return base;
		}

		list = (TLdrModule *)list->InLoadOrder.Flink;
	} while (list != flist);

	return nullptr;
}

static FORCEINLINE void AnsiToWide(wchar_t *dest, char *source)
{
	while (*source)
	{
		*dest = *source;
		dest++;
		source++;
	}

	*dest = '\0';
}

static FORCEINLINE void *GetProcAddressPeb(const wchar_t *moduleName, const wchar_t *funcName)
{
	auto base = GetModuleHandlePeb(moduleName);

	if (!base)
		return nullptr;

	auto dos = (IMAGE_DOS_HEADER *)base;
	auto nt = (IMAGE_NT_HEADERS *)((int)base + dos->e_lfanew);
	auto dir = (IMAGE_EXPORT_DIRECTORY *)((int)base + nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);

	auto nameTable = (unsigned int *)((int)base + dir->AddressOfNames);
	auto funcTable = (unsigned int *)((int)base + dir->AddressOfFunctions);
	auto ordTable = (unsigned short *)((int)base + dir->AddressOfNameOrdinals);

	for (auto i = 0u; i < dir->NumberOfNames; i++)
	{
		auto curName = ((char *)((int)base + *nameTable));

		wchar_t lcurName[512];
		AnsiToWide(lcurName, curName);

		if (!StrICompW(lcurName, funcName))
		{
			auto funcNum = *ordTable * 4;
			auto funcTableAddr = (int *)((int)funcTable + funcNum);

			auto offset = *funcTableAddr;
			return (void *)((int)base + offset);
		}

		nameTable++;
		ordTable++;
	}

	return nullptr;
}

using TSleep = void(WINAPI *)(_In_ DWORD dwMilliseconds);

using TVirtualQueryEx = SIZE_T(WINAPI *)(_In_ HANDLE hProcess,
	_In_opt_ LPCVOID lpAddress,
	_Out_writes_bytes_to_(dwLength, return) PMEMORY_BASIC_INFORMATION lpBuffer,
	_In_ SIZE_T dwLength);

using TVirtualFreeEx = BOOL(WINAPI *)(_In_ HANDLE hProcess,
	_In_ LPVOID lpAddress,
	_In_ SIZE_T dwSize,
	_In_ DWORD dwFreeType);

using TTerminateProcess = BOOL(WINAPI *)(_In_ HANDLE hProcess,
	_In_ UINT uExitCode);

using TOpenProcess = HANDLE(WINAPI *)(_In_ DWORD dwDesiredAccess,
	_In_ BOOL bInheritHandle,
	_In_ DWORD dwProcessId);

using TReadProcessMemory = BOOL(WINAPI *)(_In_ HANDLE hProcess,
	_In_ LPCVOID lpBaseAddress,
	_In_ LPVOID lpBuffer,
	_In_ SIZE_T nSize,
	_Out_opt_ SIZE_T * lpNumberOfBytesRead);

using TCloseHandle = BOOL(WINAPI *)(_In_ _Post_ptr_invalid_ HANDLE hObject);

using TMessageBoxA = int(WINAPI *)(
	_In_opt_ HWND hWnd,
	_In_opt_ LPCSTR lpText,
	_In_opt_ LPCSTR lpCaption,
	_In_ UINT uType);

using TExitProcess = void(WINAPI *)(
	_In_ UINT uExitCode);

using TMessageBoxW = int(WINAPI *)(
	_In_opt_ HWND hWnd,
	_In_opt_ const wchar_t *lpText,
	_In_opt_ const wchar_t *lpCaption,
	_In_ UINT uType);

using TVirtualAllocEx = LPVOID(WINAPI *)(_In_ HANDLE hProcess,
	_In_opt_ LPVOID lpAddress,
	_In_ SIZE_T dwSize,
	_In_ DWORD flAllocationType,
	_In_ DWORD flProtect);

using TWriteProcessMemory = BOOL(WINAPI *)(_In_ HANDLE hProcess,
	_In_ LPVOID lpBaseAddress,
	_In_reads_bytes_(nSize) LPCVOID lpBuffer,
	_In_ SIZE_T nSize,
	_Out_opt_ SIZE_T * lpNumberOfBytesWritten);

using TQueueUserAPC = DWORD(WINAPI *)(_In_ PAPCFUNC pfnAPC,
	_In_ HANDLE hThread,
	_In_ ULONG_PTR dwData);

using TCreateThread = HANDLE(WINAPI *)(_In_opt_ LPSECURITY_ATTRIBUTES lpThreadAttributes,
	_In_ SIZE_T dwStackSize,
	_In_ LPTHREAD_START_ROUTINE lpStartAddress,
	_In_opt_ __drv_aliasesMem LPVOID lpParameter,
	_In_ DWORD dwCreationFlags,
	_Out_opt_ LPDWORD lpThreadId);

using TGetProcessId = DWORD(WINAPI *)(_In_ HANDLE Process);

using TCreateProcessW = BOOL(WINAPI *)(_In_opt_ LPCWSTR lpApplicationName,
	_Inout_opt_ LPWSTR lpCommandLine,
	_In_opt_ LPSECURITY_ATTRIBUTES lpProcessAttributes,
	_In_opt_ LPSECURITY_ATTRIBUTES lpThreadAttributes,
	_In_ BOOL bInheritHandles,
	_In_ DWORD dwCreationFlags,
	_In_opt_ LPVOID lpEnvironment,
	_In_opt_ LPCWSTR lpCurrentDirectory,
	_In_ LPSTARTUPINFOW lpStartupInfo,
	_Out_ LPPROCESS_INFORMATION lpProcessInformation);

using TWinExec = UINT(WINAPI *)(_In_ LPCSTR lpCmdLine, _In_ UINT uCmdShow);