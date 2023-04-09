# Malicious consistency packet in GoldSource Engine causes server crash

The latest GoldSource engine builds contain a flaw that allows to crash the server from the client side with the `SV_ParseConsistencyResponse: invalid length: 0` error.

Dear HackerOne Staff, I cannot find a suitable weakness type because Valve's policy says Denial of Service attacks are prohibited, while client-to-server crash reports are allowed. For this reason, I have to choose Denial of Service (CWE-400), although it is obvious that this type means an attack on the system in the form of a high requests load. The report describes an instant server crash due to a one-time incorrect processing of incoming data. Please set the appropriate weakness type if required.

# How to crash?

I did it in the following way:

1. I wrote a `Cmd_CrashRes_f` function that contained the code for writing `clc_fileconsistency` message to the network buffer and registered it as a callback function for the `rescrash` command.
2. I connected to the original HLDS that was downloaded from Steam.
3. I entered the `rescrash` command into the console.
4. A `Sys_Error` was called on server-side, prompting an instant crash. 

{F992758}

{F992759}

The 'Fatal Error' error occurs when trying to cause a crash on the local server instead of HLDS.

# How to fix?

Obviously, `Sys_Error` must be eliminated by replacing it with a combination of `Con_DPrintf` and `SV_DropClient` function calls, by analogy with the `SV_ParseVoiceData` handler.

## Impact

The client is able to crash the server with an invalid packet.