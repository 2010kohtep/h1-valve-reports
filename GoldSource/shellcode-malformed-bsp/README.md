# Malformed BSP in GoldSrc Engine may cause shellcode injection

### Introduction

Hello. There's a vulnerability in GoldSrc Engine that allows to run arbitrary assembly code using incorrect BSP format processing.

### Description

The vulnerability is found in the **UTIL_StringToIntArray** function. This function belongs to the game mod library (mp.dll/cs.so) and has the following call chain:

SV_LoadEntities -> ED_LoadFromFile -> ED_ParseEdict -> gEntityInterface.pfnKeyValue -> CGameText::KeyValue -> UTIL_StringToIntArray

The call of this function occurs at server start during processing of the entities of map being loaded. The vulnerability itself is a classic buffer overflow with the possibility of rewriting the return address to the address where the shellcode is located.

Vulnerability was tested on Windows 10 and it works successfully.

### How to reproduce

In order to reproduce the vulnerability, an attacker needs to perform an entity list correction within the BSP itself. As a demonstration, I took a **35hp_2** map, which uses the **game_text** entity, into which we can write the shellcode that runs OS calculator via WinExec function. You can see shellcode implementation on the image below.

{F387197}

When client connects to the HLDS, attacker will send malformed map to it. After client completes download, server will send console command **map 35hp_2_shell** to client, which will start a local server, causing the load of malformed map and the shellcode execution, since this command is not on the stufftext filter list.

To quickly check the work of the shellcode, it is enough just to put the malformed map in the **maps** folder of any mod (I used Counter-Strike 1.6, Steam) and execute the console command 'map 35hp_2_shell' manually.

I attached malformed map to report.

### Possible solutions

The argument **pString** needs to be checked for length. So, if it is larger than the buffer where the string is copied, then the function must be terminated. You can also simply replace the function strcpy with strncpy.

## Impact

An attacker can execute code remotely on a client machine using HLDS, or he can upload a malformed map to web-resources, that can lead to infection of users of the resource.