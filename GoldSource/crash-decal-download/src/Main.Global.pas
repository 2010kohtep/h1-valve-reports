unit Main.Global;

interface

uses
  Xander.Memoria,
  GoldSrc.SDK;

var
  RendererLib: IModule;

var
  CS: PClientStatic;
  EI: PClientState;

  Engine: PCLEngineFunc;
  Server: PEngineFuncs;
  Client: PCLDLLFunc;

  MSG_WriteByte: procedure(var sb: sizebuf_t; c: Integer); cdecl;
  MSG_WriteShort: procedure(var sb: sizebuf_t; c: Integer); cdecl;
  MSG_WriteLong: procedure(var sb: sizebuf_t; c: Integer); cdecl;
  MSG_WriteString: procedure(var sb: sizebuf_t; c: PAnsiChar); cdecl;

  MSG_ReadByte: function: Byte; cdecl;
  MSG_ReadLong: function: Integer; cdecl;

  SZ_GetSpace: function(var buf: sizebuf_t; length: Integer): Pointer; cdecl;

  COM_Munge2: procedure(data: PByte; len: Integer; seq: Integer); cdecl;

  NET_SendPacket: procedure(sock: netsrc_t; length: Integer; data: Pointer; &to: netadr_t); cdecl;

  Netchan_CreateFragments: procedure(server: qboolean; const chan: netchan_t; const msg: sizebuf_t); cdecl;
  Netchan_FragSend: procedure(const chan: netchan_t) cdecl;

implementation

end.
