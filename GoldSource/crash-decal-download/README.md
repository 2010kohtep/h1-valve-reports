# Multiple decal download request in GoldSource leads to access violation

# Introduction

In the GoldSource engine, when a client connects to a server, the client requests the players' decals from the server to see their sprays. The request is made with the console command dlfile (SV_BeginFileDownload_f), the argument of which is the decal hash value. Upon receiving this command from the player, the server tries to find a spray in its hpak archive, and if it succeeds, it sends the spray using the netchan file protocol (Netchan_CreateFileFragmentsFromBuffer). The data is compressed before sending to save traffic (BZ2_bzBuffToBuffCompress). There are two problems in this scheme, which I am going to describe.

# Description

The first and, perhaps, the most serious problem that exists in the algorithm above is a memory leak. The data allocated for the BZ2_bzBuffToBuffCompress function is not released upon successful compression. For this reason, every time the client requests the decals from the server, there will be a small memory leak on the server side. Over time, the server will crash, but this takes a very long time, since the sprays are usually too small, on average 6 kilobytes.

However, an attacker can speed up this process by sending a large number of dlfile requests at once. Approximately 750,000 requests should be enough for a newly powered-on server to experience a memory overflow.

It would seem that 750,000 requests is a fairly large number of requests, how long does it take for the server to crash? The answer is approximately five minutes using a decal that weighs 6 kilobytes - the weight of a standard gaming spray. The number of requests, and therefore the crash time, can be reduced by increasing the spray size.

The second problem is lags. Compression functions take a long time to work and the server may freeze when compressing large amounts of data. Compression occurs every time the server receives a valid dlfile request, and even with 3,000 requests, the server hangs for a second.

# How to reproduce

I have developed a library that is needed to reproduce the vulnerability. I'll attach it to the post. The algorithm for validating the vulnerability is as follows:

1. Download TrackerUI.dll and put it in cstrike\bin;
2. Start Counter-Strike 1.6;
3. Execute the console command `hpkremove custom.hpk 1` until the message 'Removing final lump from HPAK' appears;
4. Connect to HLDS;
5. Run the console command `hpklist custom.hpk`;
6. Copy the MD5 value of a single element, in my case - f83401d1f1f5e1f6b79361cdeb73fe25;
7. Execute the console command `loop 500 "exploit_big_request !MD5f83401d1f1f5e1f6b79361cdeb73fe25"`.

If all steps are performed correctly, the server will start experiencing lags and the HLDS process will start consuming RAM. After a while, the server will crash due to memory overflow.

Also, I recorded a video showing the vulnerability:
{F1012176}

# How to fix

1. The result of the Mem_Malloc function inside the Netchan_CreateFileFragmentsFromBuffer should be freed if the compression was successful. This will fix the memory leak.
2. The number of calls to SV_BeginFileDownload_f should be limited. This will eliminate lags.

## Impact

An attacker is able to crash the server.