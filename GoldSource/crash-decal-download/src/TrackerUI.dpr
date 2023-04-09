library TrackerUI;

{$I Default.inc}

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  GoldSrc.SDK in 'GoldSrc.SDK.pas',
  Xander.Memoria in 'Xander.Memoria.pas',
  Main.Global in 'Main.Global.pas',
  Main.Exploits in 'Main.Exploits.pas';

{$R *.res}

function FindRendererLib: IModule;
const
  Modules: array of string = ['hw', 'sw', ''];
var
  Module: string;
begin
  for Module in Modules do
  begin
    Result := TModule.CreateModule(Module);
    if Result.Base <> nil then
      Exit;
  end;

  Result := nil;
end;

procedure EntireSearch;
begin
  with RendererLib do
  begin
    with CreatePattern(CS) do
    begin
      FindSignature([$8B, $0D, $FF, $FF, $FF, $FF, $83, $F8, $05], [pfIgnoreFF]);
      Transpose(-4);
      Dereference;
    end;

    with CreatePattern(Engine) do
    begin
      FindAnsiString('ScreenFade', [pfStringRef, pfStringDeep]);
      Transpose(13);
      Dereference;
    end;

    with CreatePattern(Server) do
    begin
      FindAnsiString('Too many DLLs, ignoring remainder'#10, [pfStringRef, pfStringDeep]);
      FindUInt16($D0FF, [pfBack]);
      Transpose(-4);
      Dereference;
    end;

    with CreatePattern(Client) do
    begin
      FindAnsiString('Couldn''t get client .dll', [pfStringRef, pfStringPart, pfStringDeep]);
      FindUInt16($15FF, [pfBack]);
      Transpose(7);
      Dereference;
      Transpose(-156);
    end;

    with CreatePattern(MSG_WriteByte) do
    begin
      ForceOutput(@Server^.pfnWriteByte);
      FindCall(1, True, False);
    end;

    with CreatePattern(MSG_WriteShort) do
    begin
      ForceOutput(@Server^.pfnWriteShort);
      FindCall(1, True, False);
    end;

    with CreatePattern(MSG_WriteLong) do
    begin
      ForceOutput(@Server^.pfnWriteLong);
      FindCall(1, True, False);
    end;

    with CreatePattern(MSG_WriteString) do
    begin
      ForceOutput(@Server^.pfnWriteString);
      FindCall(1, True, False);
    end;

    with CreatePattern(SZ_GetSpace) do
    begin
      ForceOutput(@Server^.pfnWriteByte);
      FindCall(1, True, False);
      FindCall(0, True, False);
    end;

    with CreatePattern(NET_SendPacket) do
    begin
      FindSignature([$6A, $00, $C7, $85, $FC, $F7, $FF, $FF, $FF, $FF, $FF, $FF]);
      FindCall(0, True, False);
    end;

    with CreatePattern(COM_Munge2) do
    begin
      FindAnsiString('spawn %i %i', [pfStringRef, pfStringDeep]);
      FindCall(0, True, True);
    end;

    with CreatePattern(Netchan_FragSend) do
    begin
      FindSignature([$55, $8B, $EC, $8B, $45, $08, $85, $C0, $74, $41]);
    end;

    with CreatePattern(EI) do
    begin
      FindSignature([$8D, $04, $40, $8D, $04, $80, $8D, $04, $80, $8D, $0C, $80, $C1, $E1, $03, $51, $E8, $FF, $FF, $FF, $FF, $8B, $15], [pfIgnoreFF]);
      Transpose(23);
      Dereference;
    end;

    with CreatePattern(MSG_ReadByte) do
    begin
      FindSignature([$8D, $BD, $5D, $FF, $FF, $FF, $F3, $AB, $66, $AB, $AA, $E8]);
      FindCall(0, True, False);
    end;

    with CreatePattern(MSG_ReadLong) do
    begin
      FindSignature([$8D, $BD, $5D, $FF, $FF, $FF, $F3, $AB, $66, $AB, $AA, $E8]);
      FindCall(1, True, False);
    end;

    with CreatePattern(Netchan_CreateFragments) do
    begin
      FindSignature([$55, $8B, $EC, $56, $8B, $75, $0C, $57, $8B, $7D, $08, $8B, $46, $6C]);
    end;
  end;
end;

procedure HudFrame(time: Double); cdecl;
var
  H: HMODULE;
begin
  Main.Exploits.Init;

  Engine^.Con_Printf('Library successfully loaded.'#10);

  H := GetModuleHandle('client.dll');
  Client^.pHudFrame := GetProcAddress(H, 'HUD_Frame');
end;

procedure Init;
begin
  RendererLib := FindRendererLib;
  if not Assigned(RendererLib) then
    Exit;

  EntireSearch;

  if (CS = nil) or (Engine = nil) or (Server = nil) or (Client = nil) then
    Exit;

  if (@MSG_WriteByte = nil) or (@MSG_WriteShort = nil) then
    Exit;

  Client^.pHudFrame := @HudFrame;
end;

begin
  Init;
end.
