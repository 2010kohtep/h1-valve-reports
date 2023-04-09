# Information disclosure using svc_sendextrainfo message

In GoldSource titles, server (attacker) has the ability to guaranteedly find out the connecting client's OS version. With this information, attacker will have a much higher chance of a successful RCE attack, since each OS version has unique values of the key variables for the attack, for example, a different stack pointer. Knowing the version, attacker will be able to choose an RCE that is guaranteed to work on the received OS. This will significantly increase the number of victims.

# How it works?

I will give a short instruction on how it works. If necessary, I am ready to implement the necessary code to demonstrate how it works.

1. Collect the MD5 for C:\Windows\System32\ntdll.dll file
Each OS version has a different MD5 hash for some files. For example, ntdll.dll has these:
Windows 10 (2004) - 56CC5F7B4E5E23380D73FDD5F87DCDF6
Windows 7 (SP 1) - 81601B0A6E0ADCE2DA2343CE65F3DC88
Windows XP (SP 3) - A34B773EF93A080168F0B1ACFDACBFA6
And so on. In the future, attacker will use this list to determine the client's OS version.

2. Set a new search path for the client's FileSystem interface.
Attacker can get consistencies (MD5) for any client folder using the svc_sendextrainfo message. This message contains the fallback_dir value from the liblist.gam file, and client passes it to the IFileSystem::AddSearchPath method when receiving this message. That is, for the attacker to have access to the ntdll.dll file, he must set the fallback_dir value in the liblist.gam file to 'C:\Windows\System32' on server side.

3. Get the MD5 hash for the ntdll.dll file.
Using resource with the RES_CHECKFILE flag, attacker retrieves MD5 for ntdll.dll (see SV_AddResource).

4. Attacker selects the appropriate RCE for the system and sends it to the connecting client (see SV_ParseConsistencyResponse).

# How to fix?

If you refer to the wiki, you can understand that this parameter should be a relative path to the mod folder.

https://developer.valvesoftware.com/wiki/The_liblist.gam_File_Structure#fallback_dir

However, the server has the ability to set any absolute path, which can lead to the consequences described above. Probably, in order not to break the functionality of existing mods, the client should check whether the path is relative and not contain forbidden substrings like '..'?

## Impact

Combined with vulnerabilities like RCE, attacker can significantly increase the likelihood of successful remote code execution on the client side.