# Malformed .WAD file in GoldSource Engine may cause shellcode injection

#### Introduction

Hey. There is a vulnerability in the GoldSource Engine that allows to perform buffer overflow and overwrite the stack and set new return address, that is reference to  custom assembler code. This will allow an attacker to perform remote code execution.

I discovered this vulnerability just yesterday, and today I was able to report it here.

#### Description

The problem lies in the complex of functions, but stack overflow occurs in TEX_LoadLump. This function reads lump from the list of loaded WAD files and writes it to  'dtexdata' variable, which is in Mod_LoadTextures. The problem is that dtexdata is a part of the stack memory, and you can read the data in any quantity. How much to read the data is indicated in the WAD file itself. The WAD file contains data for reading, which will be written to dtexdata. No bounds checks are made, you can read any amount of data. That is, we have a potential danger that when reading WAD, a shellcode can be written to the stack.

#### How to reproduce

I attached the source code of the WAD file compiler to the message, which is able to overwrite the stack and insert the shellcode into it, as well as the modified BSP file that will load this file. Shellcode in compiled WAD files is successfully runned on the Windows 10 operating system.

In the source code of the compiler, you can find a more detailed description of the WAD format structure exploitation.

1. Compile the WAD compiler with Release configuration.
2. Compile the WAD file by running the WAD compiler.
3. Copy the compiled WAD file named "sploit0.wad" to the game directory, for example - cstrike.
4. Copy cs_militia_exploit.bsp to the maps folder.
5. Start the game with the cs_militia_exploit map.

That's it. At the initial stage of loading the map, the WAD file will be loaded, and the TEX_LoadLump function will overwrite the stack, that will run calc.exe.

#### Vector attack

HLDS can act as an attacker, and the victim will be the client that connects to the server. The server will upload the modified map and WAD file to client, and client will download them and execute the shellcode. HLDS itself will not be affected.

#### Possible solutions

Add a check to the TEX_LoadLump function to disksize of the found lump. If it is greater than 348996, then don't read it.

## Impact

As said before, attacker can perform remote code execution on the client's machine.