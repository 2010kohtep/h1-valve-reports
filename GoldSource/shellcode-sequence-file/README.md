# Malformed sequences file may cause shellcode injection

#### Introduction

Hey. There is a vulnerability in GoldSrc Engine that allows a server to run an assembler code on a client via buffer overflow, rewriting return address of a function.

#### Description

The problem lies in several functions, but as an example I will take only one - **Sequence_ReadQuotedString**. This function reads data into the stack until it encounters a null terminator. It does not contain any checks on the size of the variable where the data is written, so that we are able to reach the place on the stack where the return address is located and rewrite it.

Since we read a string, we cannot use a null character. This could be a problem, since the stack address in GoldSrc Engine has a pattern 0xXXYYYYYY, where XX is a null character. However, the function writes the null character itself when it stops reading the string. Exploit uses that feature.

In order to achieve the vulnerable function, a sequence script is used that performs the following chain of calls:

CL_Init -> Sequence_Init -> Sequence_ParseFile -> Sequence_ParseBuffer -> Sequence_ParseEntry -> Sequence_ParseLine -> Sequence_ParseCommandLine -> Sequence_ParseCommand -> Sequence_ReadCommandData -> Sequence_ReadQuotedString

After executing the malformed script, the shellcode from it will be written onto the stack, and the return address will be overwritten to the shellcode stack address, which will start the Windows calculator.

The shellcode uses several features of 32-bit OS Windows applications, one of which is the address of the kernel32 library with a specific OS is always static, so the shellcode has the ability to use the absolute address of this library to write a string to the data section and execute WinExec function. For this reason, the shellcode looks quite simplistic, however, it does not violate the policy. If an attacker needs to get an address, for example, a recv function from a ws2_32 module, he will use a more complicated scheme for obtaining a list of modules and functions using PEB (Process Environment Block), which I have already demonstrated in my previous reports #399380 and #410869.

This vulnerability affects the following functions:

* Sequence_ReadQuotedString;
* Sequence_GetNameValueString.

#### How to reproduce

Since the **seq** extension is not included in the **IsSafeFileToDownload** filter, the server can upload sequence file to client in connection stage. It should be uploaded to the **sequences** folder with the name **global.sec**. The script will not be executed immediately, but after the player re-enters the game. The server can force the player to restart the game by executing the command **_restart**, bypassing the filters that I described in report #412430.

Exploit tested on Windows 10 and it works successfully.

I attached a malformed script to report that can run the shellcode, and also, just in case, I attached pure assembler shellcode, written in FASM.

#### Possible solutions

The simplest solution is to add the seq extension to the download files filter. The more difficult solution - to read a limited number of characters.

## Impact

As said before, attacker can perform remote code execution on the client's machine.