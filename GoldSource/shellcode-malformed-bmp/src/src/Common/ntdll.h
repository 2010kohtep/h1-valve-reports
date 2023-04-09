#pragma once

#include <Windows.h>
#include <winternl.h>

struct TUnicodeString
{
	unsigned short Length;
	unsigned short MaximumLength;
	wchar_t *Buffer;
};

struct TListEntry
{
	struct TListEntry *Flink;
	struct TListEntry *Blink;
};

struct TPebLdrData
{
	unsigned int Length;
	bool Initialized;
	void *SsHandle;
	TListEntry InLoadOrder;
	TListEntry InMemoryOrder;
	TListEntry InInitOrder;
	void *EntryInProgress;
};

#pragma pack(push, 4)

struct TLdrModule
{
	TListEntry InLoadOrder;
	TListEntry InMemoryOrder;
	TListEntry InInitOrder;
	int BaseAddress;
	int EntryPoint;
	int SizeOfImage;
	TUnicodeString FullDllName;
	TUnicodeString BaseDllName;
	unsigned int Flags;
	unsigned short LoadCount;
	unsigned short TlsIndex;
	TListEntry HashTableEntry;
	unsigned char TimeDataStamp;
};


struct TProcessEnvironmentBlock
{
	unsigned char InheritedAddressSpace;
	unsigned char ReadImageFileExecOptions;
	unsigned char BeingDebugged;
	unsigned char SpareBool;
	void* Mutant;
	void* ImageBaseAddress;
	TPebLdrData* Ldr;
	struct _RTL_USER_PROCESS_PARAMETERS* ProcessParameters;
	void* SubSystemData;
	void* ProcessHeap;
	struct _RTL_CRITICAL_SECTION* FastPebLock;
	void* FastPebLockRoutine;
	void* FastPebUnlockRoutine;
	unsigned long EnvironmentUpdateCount;
	void* KernelCallbackTable;
	unsigned long SystemReserved[1];
	unsigned long ExecuteOptions : 2; // bit offset: 34, len=2
	unsigned long SpareBits : 30; // bit offset: 34, len=30
	struct _PEB_FREE_BLOCK* FreeList;
	unsigned long TlsExpansionCounter;
	void* TlsBitmap;
	unsigned long TlsBitmapBits[2];
	void* ReadOnlySharedMemoryBase;
	void* ReadOnlySharedMemoryHeap;
	void** ReadOnlyStaticServerData;
	void* AnsiCodePageData;
	void* OemCodePageData;
	void* UnicodeCaseTableData;
	unsigned long NumberOfProcessors;
	unsigned long NtGlobalFlag;
	long long CriticalSectionTimeout;
	unsigned long HeapSegmentReserve;
	unsigned long HeapSegmentCommit;
	unsigned long HeapDeCommitTotalFreeThreshold;
	unsigned long HeapDeCommitFreeBlockThreshold;
	unsigned long NumberOfHeaps;
	unsigned long MaximumNumberOfHeaps;
	void** ProcessHeaps;
	void* GdiSharedHandleTable;
	void* ProcessStarterHelper;
	unsigned long GdiDCAttributeList;
	void* LoaderLock;
	unsigned long OSMajorVersion;
	unsigned long OSMinorVersion;
	unsigned short OSBuildNumber;
	unsigned short OSCSDVersion;
	unsigned long OSPlatformId;
	unsigned long ImageSubsystem;
	unsigned long ImageSubsystemMajorVersion;
	unsigned long ImageSubsystemMinorVersion;
	unsigned long ImageProcessAffinityMask;
	unsigned long GdiHandleBuffer[34];
	void(*PostProcessInitRoutine)();
	void* TlsExpansionBitmap;
	unsigned long TlsExpansionBitmapBits[32];
	unsigned long SessionId;
	unsigned long long AppCompatFlags;
	unsigned long long AppCompatFlagsUser;
	void* pShimData;
	void* AppCompatInfo;
	TUnicodeString CSDVersion;
	void* ActivationContextData;
	void* ProcessAssemblyStorageMap;
	void* SystemDefaultActivationContextData;
	void* SystemAssemblyStorageMap;
	unsigned long MinimumStackCommit;
};

#pragma pack(pop)