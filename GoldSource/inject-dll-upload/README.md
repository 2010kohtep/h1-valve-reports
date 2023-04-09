# Vulnerability in GoldSource Engine allows to upload and run an arbitrary DLL on client

### Introduction

Greetings. In GoldSource Engine there is a vulnerability that allows to run an arbitrary DLL on the client, using the flaws in the file downloading system.

### Description

Part of the problem is hidden in the **CL_BatchResourceRequest** function. This is a client function that is responsible for adding a list of server files to the download queue. Files added to the queue can be of different types: sound, model, decal, generic, eventscript, skin. Before adding to the queue, some types of resources are tested for validity using the **IsSafeFileToDownload** function. This is where the problem arises.

**IsSafeFileToDownload** function is used only in generic resources, all other types rely only on the **CL_CheckFile** check, which has a very poor set of rules, according to IDA pseudocode for 7960 engine build:

```if ( Q_strstr(pFileName, "..") || Q_strstr(pFileName, "server.cfg") )
{
  Con_DPrintf("Refusing to download a path with '..'\n");
  return 1;
}```

As you can see, only the presence of double-dot and the file name server.cfg substrings in the variable pFileName are checked.

File transfer under the server->client scheme can be done in two ways:

* With the help of netchan (UDP);
* Using HTTP.

Of course, if we try to transfer the file using the first method, we will fail, because when the file is downloaded, IsSafeFileToDownload is still will be executed in **Netchan_CopyFileFragments** function, although the progress of the file transfer will be shown.

{F440411}

But this does not apply to the second method, where the file will be downloaded fairly quickly and will not pass any verification function.

Such architecture creates security holes. Thus, the server has the ability to upload any file to the mod folder on the client, bypassing the IsSafeFileToDownload filter. You can upload any file, from the autoexec.cfg script to the TrackerUI.dll library, which is loaded by the client.dll library in the **Initialize** function. There is no such library in the vanilla Half-Life 1 and Counter-Strike 1.6 games, which allows you to upload malware library on the any mod.

### How to reproduce

1. Specify the sv_downloadurl console variable for the client to download the file using the HTTP protocol (http://127.0.0.1 will be enough for local tests).
2. In the **SV_CreateResourceList** function, call the following code: ```SV_AddResource (t_eventscript, filename, FS_FileSize (filename), RES_FATALIFMISSING, 0);```, where **filename** is the name of a file with a forbidden extension, for example, **bin\TrackerUI.dll**.
3. Upload bin\TrackerUI.dll to the hosting specified in sv_downloadurl.
4. Connect to the server.

As a result, client will download the library bin\TrackerUI.dll, which should not be downloaded, following the IsSafeFileToDownload rules, and will be loaded the next time the game starts.

### Possible solutions

Replace the **CL_CheckFile** function code above with the following one:

```if (! IsSafeFileToDownload (pFileName) )
{
Con_DPrintf ("Refusing to download restricted file.\n");
return 1;
}```

## Impact

Server has the ability to arrange a massive infection of the players by spreading a malware library.