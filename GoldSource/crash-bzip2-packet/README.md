# Malformed BZip2 payload in GoldSource leads to access violation

# Description

In GoldSource Engine BZip2 is used when a large amount of data needs to be transferred over the network. However, by shaping the data in a special way, an attacker can cause the recipient to crash (in our case - the server-side).

# How to reproduce?

As a PoC, I developed a library that intercepts the BZ2_bzBuffToBuffCompress function. A new handler spoofs the destination data, giving a caller what is in the payload.bin file, which, in turn, contains the malicious bzip2 payload.

The algorithm for reproducing the vulnerability is as follows:

1. Put the TrackerUI.dll and payload.bin files in the `cstrike\bin` folder;
2. Launch HLDS with Counter-Strike 1.6 game;
3. In HLDS, set the sv_lan variable to 1 using the console (needs if you use the same Steam account for server and client);
4. Launch the Counter-Strike 1.6 client;
5. Connect to server.

At the fifth stage, the server will crash.

Also, I recorded a video demonstrating how the vulnerability works.

{F1045865}

# How to fix?

GoldSource Engine is currently uses the outdated BZip2 version - 1.0.2. To fix the problem, I recommend updating to the actual version - 1.0.8, which contains many CVE fixes.

## Impact

An attacker is able to crash the server.