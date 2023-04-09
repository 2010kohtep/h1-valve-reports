# Potential buffer overflow in demoplayer module of GoldSource Engine

**Introduction**

Hey. There's a potential vulnerability in the **GoldSource Engine** that allows to write data to stack of arbitrary size, thereby causing a buffer overflow and the ability to execute assembler code using **.dem** files.

**Description**

The problem is located in the **DemoPlayer::ReadDemoMessage** function, which lies in **demoplayer** module, which is called when the **viewdemo** console command is executed. Since this command is not included in the filter list of the **ValidStuffText** function, and the .dem extension is not included in the filter list of the **IsSafeFileToDownload** function, the server can upload the malformed dem-file to the client and run it. Also, it is possible for hackers to spread incorrect dem-files without using HLDS, sending a malformed dem to users on web-resources or using messengers.

The following opcodes are vulnerable: **DemoCmd::PlaySound** (8), **DemoCmd::PayLoad** (9). These opcodes contain a variable responsible for the amount of data that must be read by the **BitBuffer::ReadBuf** function. Since the variable where the read result fits is located in the stack memory, it is possible to overflow the buffer and overwrite the return address on its own code.

At the moment, the vulnerability does not pose a risk, since the limit of any network packet is 4010 (**MAX_UDP_PACKET** constant), which excludes the possibility of a buffer overflow in the DemoCmd::PayLoad command (which is 32767 bytes in size). At the same time, the buffer for DemoCmd::PlaySound is 256 bytes, but this buffer is located in front of the buffer for DemoCmd::PayLoad, which will not allow rewriting the return address on the stack. However, there is a potential danger that in future recompiling of the project, the buffers may be swapped, which will cause a vulnerability for the DemoCmd::PlaySound package.

{F375545}

The hacker has the opportunity to study the dem-files architecture and write his own dem-file assembler. I have my own tool for these purposes, which I once wrote for a long time for educational purposes. It allows to analyze and modify an existing dem-file, injecting or deleting commands.

The attached PNG image shows the vulnerable function DemoPlayer::ExecuteDemoFileCommands, which processes the commands of the dem file. Pseudocode locations circled in red are places where vulnerability can be exploited.

But again, at the moment, the vulnerability cannot be exploited due to the particular arrangement of the stack variables in which data is written and the specifics of command processing (I described it in the first message). However, in the future, the vulnerability may be activated for a number of reasons (changing the project settings, changing the compiler, and so on).

I've also attached modified and original dem-files. Perhaps this will help.

**Possible Solutions**

Create conditions that don't allow to read too much data. For example:

```
size = BitBuffer::ReadLong(buf);
if (size > sizeof(buffer))
  size = sizeof(buffer);
BitBuffer::ReadBuf(buf, size, buffer);
```

## Impact

As said before, an attacker can remotely execute arbitrary assembly code on the clients or player can run malformed dem-file himself with **viewdemo** console command.