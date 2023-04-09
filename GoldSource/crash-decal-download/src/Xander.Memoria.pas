unit Xander.Memoria;

{$I Default.inc}

interface

uses
  Winapi.Windows,

  System.SysUtils,
  System.Generics.Collections;

{$POINTERMATH ON}

{.$DEFINE SEARCH_PARANOIA}

(*
  -- Changelog --

  1.0 - ?
    * Initial release.

  1.1 - 07.14.20
    * Add Visual C++ RTTI search functional.

  1.2 - 09.21.20
    * Fix FindReference;
    * Fix FindRelative;
    * Add pfDontCheckBounds pattern flag.
*)

const
  MEMORIA_VERSION_MAJOR = 1;
  MEMORIA_VERSION_MINOR = 1;

const
  GET_MODULE_HANDLE_EX_FLAG_PIN                = $00000001;
  GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT = $00000002;
  GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS       = $00000004;
  GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS_SAFE  =
    GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT or GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS;

function GetModuleHandleExA(Flags: Cardinal; ModuleName: PAnsiChar; out Module: HMODULE): BOOL; stdcall; external kernel32;
function GetModuleHandleExW(Flags: Cardinal; ModuleName: PWideChar; out Module: HMODULE): BOOL; stdcall; external kernel32;

type
  PRTTITypeDescriptor = ^TRTTITypeDescriptor;
  TRTTITypeDescriptor = record
    (* Always points to type_info's VFTable *)
    VFTable: PPointer;
    (* ? *)
    Spare: Pointer;
    (* Class Name *)
    Name: array[0..0] of AnsiChar;
  end;

  PPMD = ^TPMD;
  TPMD = record
    (* VFTable offset (if PMD.PDisp is -1) *)
    MDisp: Integer;
    (* VBTable offset (-1: VFTable is at displacement PMD.MDisp is -1) *)
    PDisp: Integer;
    (* Displacement of the base class VFTable pointer inside the VBTable *)
    VDisp: Integer;
  end;

  PRTTIBaseClassDescriptor = ^TRTTIBaseClassDescriptor;
  TRTTIBaseClassDescriptor = record
    (* TypeDescriptor of this base class *)
    TypeDescriptor: PRTTITypeDescriptor;
    (* Number of direct bases of this base class *)
    NumCintainedBases: LongWord;
    (* Pointer-to-member displacement info *)
    Where: TPMD;
    (* Flags, usually 0 *)
    Attributes: LongWord;
  end;

  PRTTIBaseClassArray = ^TRTTIBaseClassArray;
  TRTTIBaseClassArray = record
    ArrayOfBaseClassDescriptors: array[0..0] of PRTTIBaseClassDescriptor;
  end;

  PRTTIClassHierarchyDescriptor = ^TRTTIClassHierarchyDescriptor;
  TRTTIClassHierarchyDescriptor = record
    (* Always 0? *)
    Signature: LongWord;
    (* Bit 0 - multiple inheritance; Bit 1 - virtual inheritance *)
    Attributes: LongWord;
    (* Number of base classes. Count includes the class itself *)
    NumBaseClasses: LongWord;
    (* Array of RTTIBaseClassDescriptor *)
    BaseClassArray: PRTTIBaseClassArray;
  end;

  PRTTICompleteObjectLocator = ^TRTTICompleteObjectLocator;
  TRTTICompleteObjectLocator = record
    (* Always 0? *)
    Signature: LongWord;
    (* Offset of VFTable within the class *)
    Offset: LongWord;
    (* Constructor displacement offset *)
    CDOffset: LongWord;
    (* Class Information *)
    TypeDescriptor: PRTTITypeDescriptor;
    (* Class Hierarchy information *)
    ClassDescriptor: PRTTIClassHierarchyDescriptor;
  end;

type
  TObjectLocators = TList<PRTTICompleteObjectLocator>;

type
  TPatternFlags = set of
  (
    pfNone = 0,
    pfBack = 1 shl 0,
    pfIgnoreFF = 1 shl 1,
    pfIgnore00 = 1 shl 2,
    pfUnsafe = 1 shl 3,

    // FindXXXString flags
    pfStringRef = 1 shl 4,
    pfStringPart = 1 shl 5,
    pfStringDeep = 1 shl 6,

    //
    pfDontCheckBounds = 1 shl 7
  );

  TWriteFlags = set of
  (
    wfNone = 0,
    wfNoProtect = 1 shl 0
  );

  TMemory = class
  private
    class var TraceCloneChecking: Boolean;
  private
    class function FreeMemory(AData: Pointer): Boolean; static;
    class function GetExecMem(ASize: Cardinal): Pointer; static;

    class function GetInstructionLength(APC: PByte): Integer; static;
    class constructor Create;
  public
    (* Basic Memory *)

    class function &Absolute(AAddr: Pointer): Pointer; static; inline;
    class function Relative(ABase, AFunc: Pointer): Pointer; static; inline;
    class function Bounds(AAddr, ABottom, ATop: Pointer): Boolean; static; inline;

    class function Transpose(AAddr: Pointer; AOffset: Integer): Pointer; overload; inline; static;
    class function Transpose(AAddr: Cardinal; AOffset: Integer): Pointer; overload; inline; static;

    class function Check<T>(AAddr: Pointer; AValue: T; AOffset: Integer = 0): Boolean; static;

    class function ValidateMemory(AAddr: Pointer): Boolean; overload; static;
    class function IsExecutable(AAddr: Pointer): Boolean; static;

    class function GetBaseAddr(AAddr: Pointer): HMODULE; static;
    class function GetRelativeAddr(AAddr: Pointer): Pointer; static;
    class function GetModuleSize(AModule: HMODULE): Cardinal; static;

    (* Reading *)

    class function ReadPrimitive<T>(AAddr: Pointer): T; overload; static;
    class function ReadPattern(AAddr: Pointer; ACount: Cardinal; var ADest): Boolean; overload; static;
    class function ReadPattern(AAddr: Pointer; ACount: Cardinal; var ADest: TArray<Byte>): Boolean; overload; static;

    (* Writing *)

    class procedure WritePrimitive<T>(AAddr: Pointer; AValue: T; AFlags: TWriteFlags = [wfNone]); overload; static;
    class procedure WritePattern(AAddr: Pointer; const AValue: TArray<Byte>; AFlags: TWriteFlags = [wfNone]); overload; static;
    class procedure WritePattern(AAddr: Pointer; AData: Pointer; ASize: Cardinal; AFlags: TWriteFlags = [wfNone]); overload; static;
    class procedure WriteRelative(AAddr, ABase, AValue: Pointer; AFlags: TWriteFlags = [wfNone]); static;

    class procedure Fill(AAddr: Pointer; AData: Byte; ASize: Integer); static;

    (* Searching *)

    class function FindPrimitive<T>(AStart, ALeft, ARight: Pointer; AValue: T; AFlags: TPatternFlags = [pfNone]): Pointer; overload; static;
    class function FindPrimitive<T>(AStart: Pointer; ALimit: Integer; AValue: T; AFlags: TPatternFlags = [pfNone]): Pointer; overload; static;
    class function FindPattern(AStart, ALeft, ARight: Pointer; const AValue: TArray<Byte>; AFlags: TPatternFlags = [pfNone]): Pointer; overload; static;
    class function FindPattern(AStart, ALeft, ARight: Pointer; AValue: Pointer; ASize: Cardinal; AFlags: TPatternFlags = [pfNone]): Pointer; overload; static;
    class function FindRelative(AStart, ALeft, ARight: Pointer; AOpcode: Word; AIndex: Integer = 0; ABack: Boolean = False): Pointer; static;
    class function FindReference(AStart, ALeft, ARight: Pointer; ARefAddr: Pointer; AOpcode: Word = 0; ABack: Boolean = False): Pointer; static;
    class function FindAnsiString(AStart, ALeft, ARight: Pointer; const AData: AnsiString): Pointer; static;

    (* Detouring *)

    class procedure WriteFunc(AAddr, AFunc: Pointer; AOpcode: Byte); static;
    class procedure WriteCall(AAddr, AFunc: Pointer); static;
    class procedure WriteJump(AAddr, AFunc: Pointer); static;

    class function HookRegular(AAddr, AFunc: Pointer): Pointer; static;
    class function HookExport(AModule: HMODULE; const AFuncName: string; AFuncAddr: Pointer): Pointer; static;

    class function RestoreHook(const AAddr): Boolean; static;

    class function HookRefAddr(AAddr, ANewAddr, AStart, AEnd: Pointer; AOpcode: Byte): Integer; static;
    class function HookRefCall(AAddr, ANewAddr, AStart, AEnd: Pointer): Integer; static;
    class function HookRefJump(AAddr, ANewAddr, AStart, AEnd: Pointer): Integer; static;

    (* Sections *)

    class function GetSectionByFlags(AModule: HMODULE; AFlags: Cardinal; APedantic: Boolean = True): PImageSectionHeader; static;
    class function GetSectionByName(AModule: HMODULE; const AName: AnsiString): PImageSectionHeader; static;
    class function GetRDataSection(AModule: HMODULE): PImageSectionHeader; static;
    class function GetMainCodeSection(AModule: HMODULE): PImageSectionHeader; static;
    class function GetSectionBounds(AModule: HMODULE; ASection: PImageSectionHeader; out ASectionStart, ASectionEnd: Pointer): Boolean; overload; static;
    class function GetSectionBounds(ASection: PImageSectionHeader; out ASectionStart, ASectionEnd: Pointer): Boolean; overload; static;

    (* Visual C++ RTTI *)

    class function GetRTTIDescriptor(AStart, ALeft, ARight: Pointer; const AName: AnsiString): PRTTITypeDescriptor; static;
    class function GetVTableForDescriptor(AStart, ALeft, ARight: Pointer; ADesc: PRTTITypeDescriptor): PPointer; static;
    class function GetVTableForClass(AStart, ALeft, ARight: Pointer; const AName: AnsiString): PPointer; static;

    (* Other *)

    class function BeginThread(const AAddr; AArg: Pointer = nil): THandle; static;
    class function BeautifyPointer(AAddr: Pointer): string; static;
  end;

  ISearchPattern = interface
    procedure FindUInt8(AValue: Byte; AFlags: TPatternFlags = [pfNone]);
    procedure FindUInt16(AValue: Word; AFlags: TPatternFlags = [pfNone]);
    procedure FindUInt32(AValue: LongWord; AFlags: TPatternFlags = [pfNone]);

    procedure FindSignature(const AValue: TArray<Byte>; AFlags: TPatternFlags = [pfNone]);
    procedure FindAnsiString(AValue: PAnsiChar; AFlags: TPatternFlags = [pfNone]);
    procedure FindWideString(AValue: PAnsiChar; AFlags: TPatternFlags = [pfNone]);

    procedure FindRelative(AOpcode: Word; AIndex: Integer = 0; ABack: Boolean = False);
    procedure FindReference(ARefAddr: Pointer; ABack: Boolean = False);
    procedure FindCall(AIndex: Integer = 0; ADeref: Boolean = False; ABack: Boolean = False);
    procedure FindJump(AIndex: Integer = 0; ADeref: Boolean = False; ABack: Boolean = False);

    procedure FindVTable(const AName: AnsiString);

    function CheckUInt8(AValue: Byte; AOffset: Integer): Boolean;
    function CheckUInt16(AValue: Word; AOffset: Integer): Boolean;
    function CheckUInt32(AValue: LongWord; AOffset: Integer): Boolean;

    procedure GetProcedure(const Name: string);
    procedure GetInterface(const Name: AnsiString);

    procedure Dereference;
    procedure &Absolute;
    procedure Transpose(AValue: Integer);
    procedure Align;

    procedure ForceOutput(AValue: Pointer);
    function CurrentOutput: Pointer;
  end;

  TSegmentInfo = record
    Name: string;
    Base, LastByte: Pointer;
    Size: Cardinal;
  end;

  IModule = interface
  {$REGION 'Методы для свойств'}
    function GetLoaded: Boolean;

    function GetName: string;
    function GetBase: Pointer;
    function GetSize: Cardinal;
    function GetLastByte: Pointer;

    function GetSegmentCode: TSegmentInfo;
    function GetSegmentData: TSegmentInfo;
    function GetSegmentROData: TSegmentInfo;
  {$ENDREGION}

  {$REGION 'Методы'}
    function CreatePattern(const AOutput; const AName: string = ''): ISearchPattern;

    function HookRefAddr(AAddr, ANewAddr: Pointer; AOpcode: Byte): Integer;
    function HookRefCall(AAddr, ANewAddr: Pointer): Integer;
    function HookRefJump(AAddr, ANewAddr: Pointer): Integer;

    function HookExport(const AFuncName: string; ANewAddr: Pointer): Pointer;

    function Transpose(AOffset: Integer): Pointer;
  {$ENDREGION}

  {$REGION 'Свойства'}
    property Loaded: Boolean read GetLoaded;

    property Name: string read GetName;
    property Base: Pointer read GetBase;
    property Size: Cardinal read GetSize;
    property LastByte: Pointer read GetLastByte;

    property SegmentCode: TSegmentInfo read GetSegmentCode;
    property SegmentData: TSegmentInfo read GetSegmentData;
    property SegmentReadOnlyData: TSegmentInfo read GetSegmentROData;
  {$ENDREGION}
  end;

  TModule = class(TInterfacedObject, IModule)
  strict private
    FName: string;
    FBase: HMODULE;
    FSize: Cardinal;
    FEnd: Pointer;

    FSegmentCode: TSegmentInfo;
    FSegmentData: TSegmentInfo;
    FSegmentROData: TSegmentInfo;
  strict private
    function GetLoaded: Boolean;

    function GetName: string;
    function GetBase: Pointer;
    function GetSize: Cardinal;
    function GetLastByte: Pointer;

    function GetSegmentCode: TSegmentInfo;
    function GetSegmentData: TSegmentInfo;
    function GetSegmentROData: TSegmentInfo;
  public
    (* Конструкторы, деструкторы *)

    constructor Create; overload;
    constructor Create(const AName: string); overload;
    constructor Create(AHandle: HMODULE); overload;
    constructor Create(ABase: Pointer); overload;

    destructor Destroy; override;
  public
    (* API паттернов и перехватов *)

    class function CreateModule(const AName: string): IModule; overload;
    class function CreateModule(AHandle: HMODULE): IModule; overload;
    class function CreateModule(ABase: Pointer): IModule; overload;

    function CreatePattern(const AOutput; const AName: string = ''): ISearchPattern;

    function HookRefAddr(AAddr, ANewAddr: Pointer; AOpcode: Byte): Integer;
    function HookRefCall(AAddr, ANewAddr: Pointer): Integer;
    function HookRefJump(AAddr, ANewAddr: Pointer): Integer;

    function HookExport(const AFuncName: string; ANewAddr: Pointer): Pointer;

    function Transpose(AOffset: Integer): Pointer;
  public
    (* Свойства *)

    property Loaded: Boolean read GetLoaded;

    property Name: string read GetName;
    property Base: Pointer read GetBase;
    property Size: Cardinal read GetSize;
    property LastByte: Pointer read GetLastByte;

    property SegmentCode: TSegmentInfo read GetSegmentCode;
    property SegmentData: TSegmentInfo read GetSegmentData;
    property SegmentReadOnlyData: TSegmentInfo read GetSegmentROData;
  end;

  TSearchPattern = class(TInterfacedObject, ISearchPattern)
  strict private
    FName: string;
    FModule: TModule;
    FOutput: PPointer;
  strict private
    procedure FindPrimitive<T>(AValue: T; AFlags: TPatternFlags = [pfNone]); overload;
    function Check<T>(AValue: T; AOffset: Integer): Boolean;
  public
    procedure FindUInt8(AValue: Byte; AFlags: TPatternFlags = [pfNone]);
    procedure FindUInt16(AValue: Word; AFlags: TPatternFlags = [pfNone]);
    procedure FindUInt32(AValue: LongWord; AFlags: TPatternFlags = [pfNone]);

    procedure FindSignature(const AValue: TArray<Byte>; AFlags: TPatternFlags = [pfNone]);
    procedure FindAnsiString(AValue: PAnsiChar; AFlags: TPatternFlags = [pfNone]);
    procedure FindWideString(AValue: PAnsiChar; AFlags: TPatternFlags = [pfNone]);

    procedure FindRelative(AOpcode: Word; AIndex: Integer = 0; ABack: Boolean = False);
    procedure FindReference(ARefAddr: Pointer; ABack: Boolean = False);
    procedure FindCall(AIndex: Integer = 0; ADeref: Boolean = False; ABack: Boolean = False);
    procedure FindJump(AIndex: Integer = 0; ADeref: Boolean = False; ABack: Boolean = False);

    procedure FindVTable(const AName: AnsiString);

    function CheckUInt8(AValue: Byte; AOffset: Integer): Boolean;
    function CheckUInt16(AValue: Word; AOffset: Integer): Boolean;
    function CheckUInt32(AValue: LongWord; AOffset: Integer): Boolean;

    procedure GetProcedure(const Name: string);
    procedure GetInterface(const Name: AnsiString);

    procedure Dereference;
    procedure &Absolute;
    procedure Transpose(AValue: Integer);
    procedure Align;

    procedure ForceOutput(AValue: Pointer);
    function CurrentOutput: Pointer;

    constructor Create(AModule: TModule; AOutput: Pointer; const AName: string = '');
    destructor Destroy; override;

    property Module: TModule read FModule;
    property Output: PPointer read FOutput;
  end;

implementation

{ TPattern }

class function TMemory.FindPattern(AStart, ALeft, ARight: Pointer; const AValue: TArray<Byte>;
  AFlags: TPatternFlags): Pointer;
begin
  Result := FindPattern(AStart, ALeft, ARight, @AValue[0], Length(AValue), AFlags);
end;

class function TMemory.FindPrimitive<T>(AStart, ALeft, ARight: Pointer; AValue: T;
  AFlags: TPatternFlags): Pointer;
type
  PT = ^T;
var
  Back: Boolean;
begin
  if (ALeft = nil) or (ARight = nil) or (Cardinal(ALeft) > Cardinal(ARight)) then
    Exit(nil);

  if not (pfUnsafe in AFlags) then
    ARight := TMemory.Transpose(ARight, -SizeOf(AValue));

  Back := pfBack in AFlags;
  Result := AStart;

  repeat
    if not TMemory.Bounds(Result, ALeft, ARight) then
      Exit(nil);

    case SizeOf(T) of
      1: if PByte(Result)^ = PByte(@AValue)^ then Exit(Result);

      2: if PWord(Result)^ = PWord(@AValue)^ then Exit(Result);

      4: if PLongWord(Result)^ = PLongWord(@AValue)^ then Exit(Result);

      8: if PUInt64(Result)^ = PUInt64(@AValue)^ then Exit(Result);

    else if CompareMem(Result, @AValue, SizeOf(AValue)) then Exit(Result);
    end;

    if Back then
      Dec(Cardinal(Result))
    else
      Inc(Cardinal(Result));
  until False;

  Exit(nil);
end;

class function TMemory.FindAnsiString(AStart, ALeft, ARight: Pointer;
  const AData: AnsiString): Pointer;
begin
  if (ALeft = nil) or (ARight = nil) or (Cardinal(ALeft) > Cardinal(ARight)) or (AData = '') then
    Exit(nil);

  Result := TMemory.FindPattern(AStart, ALeft, ARight, Pointer(AData), Length(AData));
end;

class function TMemory.FindPattern(AStart, ALeft, ARight, AValue: Pointer;
  ASize: Cardinal; AFlags: TPatternFlags): Pointer;

  function CompareMemory(P1, P2: PByte; Len: Integer; IgnoreFF: Boolean; Ignore00: Boolean): Boolean; stdcall;
  type
    TByteDynArray = array of Byte;
  var
    PEnd: PByte;
    B: Byte;
  begin
    PEnd := TMemory.Transpose(P2, Len);

    repeat
      if P2 = PEnd then
        Break;

      B := P2^;

      if IgnoreFF and (B = $FF) then
      begin
        Inc(P1);
        Inc(P2);
        Continue;
      end;

      if Ignore00 and (B = $00) then
      begin
        Inc(P1);
        Inc(P2);
        Continue;
      end;

      if P1^ <> P2^ then
        Exit(False);

      Inc(P1);
      Inc(P2);
    until False;

    Result := True;
  end;

var
  Back: Boolean;
begin
  if (ALeft = nil) or (ARight = nil) then
    Exit(nil);

  if (AValue = nil) or (ASize = 0) then
    Exit(nil);

  Back := pfBack in AFlags;
  Result := AStart;

  ARight := TMemory.Transpose(ARight, -ASize);

  repeat
    if not TMemory.Bounds(Result, ALeft, ARight) then
      Exit(nil);

    if (PByte(Result)^ = PByte(AValue)[0]) then
    begin
      if CompareMemory(Result, AValue, ASize, pfIgnoreFF in AFlags, pfIgnore00 in AFlags) then
        Exit(Result);
    end;

    if Back then
      Dec(Cardinal(Result))
    else
      Inc(Cardinal(Result));
  until False;

  Exit(nil);
end;

class function TMemory.FindPrimitive<T>(AStart: Pointer; ALimit: Integer; AValue: T;
  AFlags: TPatternFlags): Pointer;
var
  ALeft, ARight: Pointer;
begin
  ALeft := Transpose(AStart, -ALimit);
  ARight := Transpose(AStart, ALimit);

  Result := FindPrimitive<T>(AStart, ALeft, ARight, AValue, AFlags);
end;

class function TMemory.FindReference(AStart, ALeft, ARight, ARefAddr: Pointer;
  AOpcode: Word; ABack: Boolean): Pointer;
var
  Flags: TPatternFlags;
  IsTwoBytes, IsOpcode: Boolean;
  F: Pointer;

  function Transfer(Addr: Pointer; Back: Boolean): Pointer; inline;
  begin
    if Back then
      Dec(Cardinal(Addr))
    else
      Inc(Cardinal(Addr));

    Result := Addr;
  end;

  function IsAbsoluteOpcode(AOpcode: Word): Boolean; inline;
  begin
    Result := AOpcode <> $68;
  end;

begin
  if (ALeft = nil) or (ARight = nil) or (Cardinal(ALeft) > Cardinal(ARight)) or (AStart = nil) then
    Exit(nil);

  IsOpcode := AOpcode <> 0;
  IsTwoBytes := IsOpcode and (AOpcode > 255);

  if ABack then
    Flags := [pfBack, pfUnsafe]
  else
    Flags := [pfUnsafe];

  ARight := TMemory.Transpose(ARight, -SizeOf(Pointer));
  Result := AStart;

  repeat
    if not TMemory.Bounds(Result, ALeft, ARight) then
      Exit(nil);

    if IsOpcode then
    begin
      if IsTwoBytes then
        Result := TMemory.FindPrimitive<Word>(Result, ALeft, ARight, AOpcode, Flags)
      else
        Result := TMemory.FindPrimitive<Byte>(Result, ALeft, ARight, AOpcode, Flags);

      if Result = nil then
        Exit;

      F := Result;

      if IsTwoBytes then
        F := TMemory.Transpose(F, 2)
      else
        F := TMemory.Transpose(F, 1);

      if IsAbsoluteOpcode(AOpcode) then
        F := TMemory.Absolute(F)
      else
        F := PPointer(F)^;
    end
    else
    begin
      F := PPointer(Result)^;
    end;

    if not (pfDontCheckBounds in Flags) and not TMemory.Bounds(F, ALeft, ARight) then
    begin
      Result := Transfer(Result, ABack);
      Continue;
    end;

    if (ARefAddr = nil) or (ARefAddr = F) then
      Exit;

    Result := Transfer(Result, ABack);
  until False;

  Exit(nil);
end;

class function TMemory.FindRelative(AStart, ALeft, ARight: Pointer; AOpcode: Word;
  AIndex: Integer; ABack: Boolean): Pointer;
begin
  Result := AStart;

  repeat
    Result := FindReference(Result, ALeft, ARight, nil, AOpcode, ABack);

    if Result = nil then
      Exit;

    if AIndex <= 0 then
      Exit;

    Dec(AIndex);
    Result := TMemory.Transpose(Result, 1);
  until False;
end;

class function TMemory.FreeMemory(AData: Pointer): Boolean;
begin
  Result := HeapFree(GetProcessHeap, 0, AData);
end;

{ TRead }

class function TMemory.ReadPattern(AAddr: Pointer; ACount: Cardinal; var ADest: TArray<Byte>): Boolean;
begin
  SetLength(ADest, ACount);
  Result := TMemory.ReadPattern(AAddr, ACount, ADest[0]);
end;

class function TMemory.ReadPattern(AAddr: Pointer; ACount: Cardinal;
  var ADest): Boolean;
begin
  if (AAddr = nil) or (ACount = 0) then
    Exit(False);

  Move(AAddr^, ADest, ACount);
  Exit(True);
end;

class function TMemory.ReadPrimitive<T>(AAddr: Pointer): T;
type
  PT = ^T;
var
  Dummy: T;
begin
  if AAddr = nil then
  begin
    ZeroMemory(@Dummy, SizeOf(Dummy));
    Exit(Dummy);
  end;

  Result := PT(AAddr)^;
end;

{ TWrite }

class procedure TMemory.Fill(AAddr: Pointer; AData: Byte; ASize: Integer);
var
  OldProtect: Cardinal;
begin
  if (AAddr = nil) or (ASize <= 0) then
    Exit;

  VirtualProtect(AAddr, ASize, PAGE_EXECUTE_READWRITE, OldProtect);
  FillChar(AAddr^, ASize, AData);
  VirtualProtect(AAddr, ASize, OldProtect, OldProtect);
end;

class procedure TMemory.WritePattern(AAddr: Pointer; const AValue: TArray<Byte>; AFlags: TWriteFlags);
begin
  WritePattern(AAddr, @AValue[0], Length(AValue), AFlags);
end;

class procedure TMemory.WritePattern(AAddr, AData: Pointer; ASize: Cardinal; AFlags: TWriteFlags);
var
  Protect: Cardinal;
begin
  if (AAddr = nil) or (AData = nil) or (ASize = 0) then
    Exit;

  if not (wfNoProtect in AFlags) then
    VirtualProtect(AAddr, ASize, PAGE_EXECUTE_READWRITE, Protect);

  Move(AData^, AAddr^, ASize);

  if not (wfNoProtect in AFlags) then
    VirtualProtect(AAddr, ASize, Protect, Protect);
end;

class procedure TMemory.WritePrimitive<T>(AAddr: Pointer; AValue: T; AFlags: TWriteFlags);
var
  A: TArray<Byte>;
begin
  if AAddr = nil then
    Exit;

  SetLength(A, SizeOf(AValue));
  Move(AValue, A[0], SizeOf(AValue));

  TMemory.WritePattern(AAddr, A, AFlags);
end;

class procedure TMemory.WriteRelative(AAddr, ABase, AValue: Pointer; AFlags: TWriteFlags);
begin
  TMemory.WritePrimitive<Pointer>(AAddr, TMemory.Relative(ABase, AValue));
end;

{ TModule }

constructor TModule.Create(const AName: string);

  function GetModuleSize(Module: HMODULE): Cardinal;
  var
    DOS: PImageDosHeader;
    NT: PImageNtHeaders;
  begin
    if Module = 0 then
      Exit(0);

    DOS := Pointer(Module);
    NT := PImageNtHeaders(Integer(DOS) + DOS._lfanew);

    Result := NT^.OptionalHeader.SizeOfImage;
  end;

var
  Code, Data, ROData: PImageSectionHeader;
begin
  FName := AName;

  if AName = '' then
    FBase := GetModuleHandle(nil)
  else
    FBase := GetModuleHandle(PChar(AName));

  if FBase <> 0 then
  begin
    FSize := GetModuleSize(FBase);
    FEnd  := TMemory.Transpose(FBase, FSize - 1);

    Code := TMemory.GetSectionByFlags(FBase, IMAGE_SCN_CNT_CODE, False);
    Data := TMemory.GetSectionByFlags(FBase, IMAGE_SCN_CNT_INITIALIZED_DATA or IMAGE_SCN_MEM_READ or IMAGE_SCN_MEM_WRITE);
    ROData := TMemory.GetSectionByFlags(FBase, IMAGE_SCN_CNT_INITIALIZED_DATA or IMAGE_SCN_MEM_READ);

    if Code <> nil then
    begin
      FSegmentCode.Name := string(PAnsiChar(@Code.Name[0]));
      TMemory.GetSectionBounds(FBase, Code, FSegmentCode.Base, FSegmentCode.LastByte);
      FSegmentCode.Size := Cardinal(Integer(FSegmentCode.LastByte) - Integer(FSegmentCode.Base) - 1);
    end;

    if Data <> nil then
    begin
      FSegmentData.Name := string(PAnsiChar(@Data.Name[0]));
      TMemory.GetSectionBounds(FBase, Data, FSegmentData.Base, FSegmentData.LastByte);
      FSegmentData.Size := Cardinal(Integer(FSegmentData.LastByte) - Integer(FSegmentData.Base) - 1);
    end;

    if ROData <> nil then
    begin
      FSegmentROData.Name := string(PAnsiChar(@ROData.Name[0]));
      TMemory.GetSectionBounds(FBase, ROData, FSegmentROData.Base, FSegmentROData.LastByte);
      FSegmentROData.Size := Cardinal(Integer(FSegmentROData.LastByte) - Integer(FSegmentROData.Base) - 1);
    end;
  end
  else
  begin
    FSize := 0;
    FEnd := nil;
  end;
end;

function TModule.CreatePattern(const AOutput; const AName: string): ISearchPattern;
begin
  Result := TSearchPattern.Create(Self, @AOutput, AName);
end;

destructor TModule.Destroy;
begin
  FName := '';

  inherited;
end;

function TModule.GetBase: Pointer;
begin
  Result := Pointer(FBase);
end;

function TModule.GetLastByte: Pointer;
begin
  Result := FEnd;
end;

function TModule.GetName: string;
begin
  Result := FName;
end;

function TModule.GetSegmentCode: TSegmentInfo;
begin
  Result := FSegmentCode;
end;

function TModule.GetSegmentData: TSegmentInfo;
begin
  Result := FSegmentData;
end;

function TModule.GetSegmentROData: TSegmentInfo;
begin
  Result := FSegmentROData;
end;

function TModule.GetSize: Cardinal;
begin
  Result := FSize;
end;

function TModule.GetLoaded: Boolean;
begin
  Result := FBase <> 0;
end;

function TModule.HookExport(const AFuncName: string; ANewAddr: Pointer): Pointer;
begin
  if (AFuncName = '') or (ANewAddr = nil) then
    Exit(nil);

  Result := TMemory.HookExport(FBase, AFuncName, ANewAddr);
end;

function TModule.HookRefAddr(AAddr, ANewAddr: Pointer; AOpcode: Byte): Integer;
begin
  Result := TMemory.HookRefAddr(AAddr, ANewAddr, Base, LastByte, AOpcode);
end;

function TModule.HookRefCall(AAddr, ANewAddr: Pointer): Integer;
begin
  Result := TMemory.HookRefAddr(AAddr, ANewAddr, SegmentCode.Base, SegmentCode.LastByte, $E8);
end;

function TModule.HookRefJump(AAddr, ANewAddr: Pointer): Integer;
begin
  Result := TMemory.HookRefAddr(AAddr, ANewAddr, SegmentCode.Base, SegmentCode.LastByte, $E9);
end;

function TModule.Transpose(AOffset: Integer): Pointer;
begin
  if FBase = 0 then
    Exit(nil);

  Result := TMemory.Transpose(FBase, AOffset);
end;

{ TPointer }

class function TMemory.Absolute(AAddr: Pointer): Pointer;
begin
  if AAddr = nil then
    Exit(nil);

  Result := AAddr;
  Result := TMemory.Transpose(Result, PInteger(Result)^ + SizeOf(Pointer));
end;

class function TMemory.BeautifyPointer(AAddr: Pointer): string;
var
  Base: Pointer;
  Name: string;
begin
  if AAddr = nil then
    Exit('null');

  Base := Ptr(TMemory.GetBaseAddr(AAddr));
  if Base = nil then
    Exit(IntToHex(Integer(AAddr), 8));

  Name := GetModuleName(Cardinal(Base));
  Name := ExtractFileName(Name);
  Name := ChangeFileExt(Name, '');

  Result := Format('%s.%.08X', [Name, Integer(AAddr) - Integer(Base)]);
end;

class function TMemory.BeginThread(const AAddr; AArg: Pointer): THandle;
begin
  Result := System.BeginThread(nil, 0, @AAddr, AArg, 0, PCardinal(nil)^);
end;

class function TMemory.Bounds(AAddr, ABottom, ATop: Pointer): Boolean;
begin
  Result := (Cardinal(AAddr) >= Cardinal(ABottom)) and (Cardinal(AAddr) <= Cardinal(ATop));
end;

class function TMemory.Check<T>(AAddr: Pointer; AValue: T;
  AOffset: Integer): Boolean;
type
  PT = ^T;
begin
  if AAddr = nil then
    Exit(False);

  AAddr := TMemory.Transpose(AAddr, AOffset);

  case SizeOf(T) of
    1: if PByte(AAddr)^ = PByte(@AValue)^ then Exit(True);
    2: if PWord(AAddr)^ = PWord(@AValue)^ then Exit(True);
    4: if PLongWord(AAddr)^ = PLongWord(@AValue)^ then Exit(True);
    8: if PUInt64(AAddr)^ = PUInt64(@AValue)^ then Exit(True);
  else if CompareMem(AAddr, @AValue, SizeOf(AValue)) then Exit(True);
  end;
end;

class function TMemory.GetBaseAddr(AAddr: Pointer): HMODULE;
begin
  if not GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS or
    GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, AAddr, Result) then
    Result := 0;
end;

class function TMemory.GetMainCodeSection(AModule: HMODULE): PImageSectionHeader;
begin
  Result := GetSectionByFlags(AModule, IMAGE_SCN_CNT_CODE);
end;

class function TMemory.GetModuleSize(AModule: HMODULE): Cardinal;
var
  DOS: PImageDosHeader;
  NT: PImageNtHeaders;
begin
  DOS := Pointer(AModule);
  NT := PImageNtHeaders(Integer(DOS) + DOS._lfanew);

  Result := NT^.OptionalHeader.SizeOfImage;
end;

class function TMemory.GetRDataSection(AModule: HMODULE): PImageSectionHeader;
begin
  Result := GetSectionByFlags(AModule, IMAGE_SCN_CNT_INITIALIZED_DATA or IMAGE_SCN_MEM_READ);
end;

class function TMemory.GetRelativeAddr(AAddr: Pointer): Pointer;
var
  H: HMODULE;
begin
  H := GetBaseAddr(AAddr);
  if H = 0 then
    Exit(AAddr);

  Result := Pointer(Cardinal(AAddr) - H);
end;

class function TMemory.GetRTTIDescriptor(AStart, ALeft, ARight: Pointer; const AName: AnsiString): PRTTITypeDescriptor;
const
  CLASS_SIGNATURE = Ord('V') shl 24 or Ord('A') shl 16 or Ord('?') shl 8 or Ord('.'); // 'VA?.'
var
  IsFull: Boolean;
  NameEx: array[0..255] of AnsiChar;
  NameLen: Integer;

  P: Pointer;

  TypeDescriptor: PRTTITypeDescriptor;
begin
  if (AStart = nil) or (ALeft = nil) or (ARight = nil) or (AName = '') then
    Exit(nil);

  StrCopy(NameEx, PAnsiChar(AName));

  if PLongWord(@NameEx)^ = CLASS_SIGNATURE then
  begin
    IsFull := True;
    NameLen := 0;
  end
  else
  begin
    IsFull := False;
    NameLen := StrLen(NameEx);

    PWord(@NameEx[NameLen])^ := Ord(#0) shl 8 or Ord('@');

    Inc(NameLen);
  end;

  P := AStart;
  repeat
    P := TMemory.FindPrimitive<LongWord>(P, ALeft, ARight, CLASS_SIGNATURE);

    if P = nil then
      Exit(nil);

    P := TMemory.Transpose(P, 4);
    TypeDescriptor := Pointer(Integer(P) - 8 - 4); // (int)addr - offsetof(RTTITypeDescriptor, name) - 4

    if IsFull then
    begin
      if StrIComp(TypeDescriptor.Name, NameEx) = 0 then
        Exit(TypeDescriptor);
    end
    else
    begin
      if StrLIComp(@PAnsiChar(@TypeDescriptor.Name[0])[4], NameEx, NameLen) = 0 then
        Exit(TypeDescriptor);
    end;
  until False;
end;

class function TMemory.GetSectionBounds(ASection: PImageSectionHeader; out ASectionStart,
  ASectionEnd: Pointer): Boolean;
var
  Base: HMODULE;
begin
  if not GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS_SAFE, PAnsiChar(ASection), Base) then
  begin
    ASectionStart := nil;
    ASectionEnd := nil;

    Exit(False);
  end;

	Result := GetSectionBounds(Base, ASection, ASectionStart, ASectionEnd);
end;

class function TMemory.GetSectionBounds(AModule: HMODULE;
  ASection: PImageSectionHeader; out ASectionStart,
  ASectionEnd: Pointer): Boolean;
begin
	if (AModule = 0) or (ASection = nil) then
  begin
    ASectionStart := nil;
    ASectionEnd := nil;

    Exit(False);
  end;

	ASectionStart := Transpose(AModule, ASection^.VirtualAddress);
	ASectionEnd := Transpose(ASectionStart, ASection^.Misc.VirtualSize - 1);

	Exit(True);
end;

class function TMemory.GetSectionByFlags(AModule: HMODULE; AFlags: Cardinal;
  APedantic: Boolean): PImageSectionHeader;
var
  DOS: PImageDosHeader;
  NT: PImageNtHeaders;

  I: Integer;

  Segment: PImageSectionHeader;
begin
  if AModule = 0 then
    Exit(nil);

  DOS := PImageDosHeader(AModule);
  NT := PImageNtHeaders(Integer(DOS) + DOS._lfanew);

  Segment := Ptr(Integer(@NT.OptionalHeader) + NT.FileHeader.SizeOfOptionalHeader);

  if APedantic then
  begin
    for I := 0 to NT.FileHeader.NumberOfSections - 1 do
    begin
      if Segment.Characteristics = AFlags then
        Exit(Segment);

      Inc(Segment);
    end;
  end
  else
  begin
    for I := 0 to NT.FileHeader.NumberOfSections - 1 do
    begin
      if Segment.Characteristics and AFlags <> 0 then
        Exit(Segment);

      Inc(Segment);
    end;
  end;

  Exit(nil);
end;

class function TMemory.GetSectionByName(AModule: HMODULE;
  const AName: AnsiString): PImageSectionHeader;
var
  DOS: PImageDosHeader;
  NT: PImageNtHeaders;

  I: Integer;

  Segment: PImageSectionHeader;
begin
  if (AModule = 0) or (AName = '') then
    Exit(nil);

  DOS := PImageDosHeader(AModule);
  NT := PImageNtHeaders(Integer(DOS) + DOS._lfanew);

  Segment := Ptr(Integer(@NT.OptionalHeader) + NT.FileHeader.SizeOfOptionalHeader);

  for I := 0 to NT.FileHeader.NumberOfSections - 1 do
  begin
    if StrComp(PAnsiChar(@Segment.Name), PAnsiChar(AName)) = 0 then
      Exit(Segment);

    Inc(Segment);
  end;

  Exit(nil);
end;

class function TMemory.GetVTableForClass(AStart, ALeft, ARight: Pointer; const AName: AnsiString): PPointer;
var
  Desc: PRTTITypeDescriptor;
begin
  if (AStart = nil) or (ALeft = nil) or (ARight = nil) or (AName = '') then
    Exit(nil);

  Desc := TMemory.GetRTTIDescriptor(AStart, ALeft, ARight, AName);
  if Desc = nil then
    Exit(nil);

  Result := TMemory.GetVTableForDescriptor(AStart, ALeft, ARight, Desc);
end;

class function TMemory.GetVTableForDescriptor(AStart, ALeft, ARight: Pointer; ADesc: PRTTITypeDescriptor): PPointer;
var
  P: PByte;
  L: PRTTICompleteObjectLocator;
begin
  if (AStart = nil) or (ALeft = nil) or (ARight = nil) or (ADesc = nil) then
    Exit(nil);

  P := AStart;
  repeat
    P := TMemory.FindReference(P, ALeft, ARight, ADesc);
    if P = nil then
      Exit(nil);

    L := @P[-12]; // offsetof(RTTICompleteObjectLocator, pTypeDescriptor)

    if (L^.Signature = 0) and (L^.Offset = 0) and (L^.CDOffset = 0) then
    begin
      P := TMemory.FindReference(AStart, ALeft, ARight, L);
      if P <> nil then
        Exit(TMemory.Transpose(P, SizeOf(Pointer)));

      Exit(nil);
    end;

    P := TMemory.Transpose(P, 1);
  until False;

  Exit(nil);
end;

class function TMemory.IsExecutable(AAddr: Pointer): Boolean;
var
  Mem: TMemoryBasicInformation;
begin
  if VirtualQuery(AAddr, Mem, SizeOf(Mem)) <> SizeOf(Mem) then
    Exit(False);

  if (Mem.Protect = 0) or (Mem.Protect = PAGE_NOACCESS) then
    Exit(False);

  case Mem.Protect of
    PAGE_EXECUTE,
    PAGE_EXECUTE_READ,
    PAGE_EXECUTE_READWRITE,
    PAGE_EXECUTE_WRITECOPY: Exit(True);
  else
    Exit(False);
  end;
end;

class function TMemory.Relative(ABase, AFunc: Pointer): Pointer;
begin
  if (ABase = nil) or (AFunc = nil) then
    Exit(nil);

  Result := TMemory.Transpose(AFunc, -Integer(ABase) - SizeOf(Pointer));
end;

class function TMemory.Transpose(AAddr: Cardinal; AOffset: Integer): Pointer;
begin
  Result := TMemory.Transpose(Pointer(AAddr), AOffset);
end;

class function TMemory.ValidateMemory(AAddr: Pointer): Boolean;
var
  Mem: TMemoryBasicInformation;
begin
  if AAddr = nil then
    Exit(False);

  if VirtualQuery(AAddr, Mem, SizeOf(Mem)) <> SizeOf(Mem) then
    Exit(False);

  if (Mem.Protect = 0) or (Mem.Protect = PAGE_NOACCESS) then
    Exit(False);

  Exit(True);
end;

class function TMemory.Transpose(AAddr: Pointer; AOffset: Integer): Pointer;
begin
  Result := Ptr(Integer(AAddr) + AOffset);
end;

constructor TModule.Create;
begin
  Create('');
end;

constructor TModule.Create(AHandle: HMODULE);
begin
  FName := GetModuleName(AHandle);
  FName := ExtractFileName(FName);
  Create(FName);
end;

constructor TModule.Create(ABase: Pointer);
begin
  Create(HMODULE(ABase));
end;

class function TModule.CreateModule(const AName: string): IModule;
begin
  Result := TModule.Create(AName);
end;

class function TModule.CreateModule(AHandle: HMODULE): IModule;
begin
  Result := TModule.Create(AHandle);
end;

class function TModule.CreateModule(ABase: Pointer): IModule;
begin
  Result := TModule.Create(ABase);
end;

{ TDetour }

class constructor TMemory.Create;
begin
  TraceCloneChecking := False;
end;

class function TMemory.GetExecMem(ASize: Cardinal): Pointer;
var
  OldProtect: Cardinal;
begin
  Result := HeapAlloc(GetProcessHeap, 0, ASize);

  if Result = nil then
    Exit(nil);

  if not VirtualProtect(Result, ASize, PAGE_EXECUTE_READWRITE, OldProtect) then
  begin
    HeapFree(GetProcessHeap, 0, Result);
    Exit(nil);
  end;
end;

class function TMemory.GetInstructionLength(APC: PByte): Integer;
label
  Error, ModRM, ModRMFetched;
var
  Opcode, Opcode2: Byte;
  Len: Integer;
  MRM, SIB: Integer;
begin
  if APC = nil then
    Exit(0);

  Len := 0;

  repeat
    Opcode := APC^;
    Inc(APC);

    case Opcode of
      $64, $65, // FS: GS: prefixes
      $36,      // SS: prefix
      $66, $67, // operand size overrides
      $F0, $F2: // LOCK, REPNE prefixes
      begin
        Inc(Len);
      end;

      $2E, // CS: prefix, used as HNT prefix on jumps
      $3E: // DS: prefix, used as HT prefix on jumps
      begin
        Inc(Len);
        // goto process relative jmp
        // tighter check possible here
      end
      else
        Break;
    end;

    Inc(APC);
  until False;

  case Opcode of
    // ONE BYTE OPCODE, move to next opcode without remark
    $27, $2F,
    $37, $3F,
    $40, $41, $42, $43, $44, $45, $46, $47,
    $48, $49, $4A, $4B, $4C, $4D, $4E, $4F,
    $50, $51, $52, $53, $54, $55, $56, $57,
    $58, $59, $5A, $5B, $5C, $5D, $5E, $5F,
    $90, // nop
    $91, $92, $93, $94, $95, $96, $97, // xchg
    $98, $99,
    $9C, $9D, $9E, $9F,
    $A4, $A5, $A6, $A7, $AA, $AB, // string operators
    $AC, $AD, $AE, $AF,
    (* $C3, // RET handled elsewhere *)
    $C9,
    $CC, // int3
    $F5, $F8, $F9, $FC, $FD:
    begin
      Exit(Len + 1); // include opcode
    end;

    $C3: // RET
    begin
      if APC^ = $CC then
        Exit(Len + 1);
      Inc(APC);

      if APC^ = $CC then
        Exit(Len + 2);
      Inc(APC);

      if (APC[0] = $CC) and (APC[1] = $CC) then
        Exit(Len + 5);
      //Inc(APC, 2);

      goto Error;
    end;

    // TWO BYTE INSTRUCTION
    $04, $0C, $14, $1C, $24, $2C, $34, $3C,
    $6A,
    $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7,
    $C2:
    begin
      Exit(Len + 2);
    end;

		// TWO BYTE RELATIVE BRANCH
    $70, $71, $72, $73, $74, $75, $76, $77,
    $78, $79, $7A, $7B, $7C, $7D, $7E, $7F,
    $E0, $E1, $E2, $E3, $EB:
    begin
      Exit(Len + 2);
    end;

    // THREE BYTE INSTRUCTION (NONE!)

    // FIVE BYTE INSTRUCTION,
    $05, $0D, $15, $1D,
    $25, $2D, $35, $3D,
    $68,
    $A9,
    $B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF:
    begin
      Exit(Len + 5);
    end;

    // FIVE BYTE RELATIVE CALL
    $E8:
    begin
      Exit(Len + 5);
    end;

    // FIVE BYTE RELATIVE BRANCH
    $E9:
    begin
      if APC[4] = $CC then
        Exit(Len + 6); // <jmp near ptr ...  int 3>

      Exit(Len + 5); // plain <jmp near ptr>
    end;

    // FIVE BYTE DIRECT ADDRESS
    $A1, $A2, $A3: // MOV AL,AX,EAX moffset...
    begin
      Exit(Len + 5);
    end;

    // ModR/M with no immediate operand
    $00, $01, $02, $03, $08, $09, $0A, $0B,
    $10, $11, $12, $13, $18, $19, $1A, $1B,
    $20, $21, $22, $23, $28, $29, $2A, $2B,
    $30, $31, $32, $33, $38, $39, $3A, $3B,
    $84, $85, $86, $87, $88, $89, $8A, $8B, $8D, $8F,
    $D1, $D2, $D3,
    $FE, $FF: // misinterprets JMP far and CALL far, not worth fixing
    begin
      Inc(Len); // count opcode
      goto ModRM;
    end;

    // ModR/M with immediate 8 bit value
    $80, $82, $83,
    $C0, $C1,
    $C6:  // with r=0?
    begin
      Inc(Len, 2); // count opcode and immediate byte
      goto ModRM;
    end;

    // ModR/M with immediate 32 bit value
    $81,
    $C7:  // with r=0?
    begin
      Inc(Len, 5); // count opcode and immediate byte
      goto ModRM;
    end;

    $9B: // FSTSW AX = 9B DF E0
    begin
      if APC^ = $DF then
      begin
        Inc(APC);
        if APC^ = $E0 then
          Exit(Len + 3);

        //Inc(APC);

        //printf("InstructionLength: Unimplemented 0x9B tertiary opcode %2x at %x\n", *p, p);
        goto Error;
      end
      else
      begin
        //printf("InstructionLength: Unimplemented 0x9B secondary opcode %2x at %x\n", *p, p);
        goto Error;
      end;
    end;

    $D9: // various FP instructions
    begin
      MRM := APC^;
      Inc(APC);
      Inc(Len); //  account for FP prefix

      case MRM of
        $C9, $D0,
        $E0, $E1, $E4, $E5,
        $E8, $E9, $EA, $EB, $EC, $ED, $EE,
        $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF:
        begin
          Exit(Len + 1);
        end
        else  // r bits matter if not one of the above specific opcodes
        begin
          case (MRM and $38) shr 3 of
            0: goto ModRMFetched;  // fld
            1: Exit(Len + 1); // fxch
            2: goto ModRMFetched; // fst
            3: goto ModRMFetched; // fstp
            4: goto ModRMFetched; // fldenv
            5: goto ModRMFetched; // fldcw
            6: goto ModRMFetched; // fnstenv
            7: goto ModRMFetched; // fnstcw
          else goto Error; // unrecognized 2nd byte
          end;
        end;
      end;
    end;

    $DB: // various FP instructions
    begin
      MRM := APC^;
      //Inc(APC);
      Inc(Len); //  account for FP prefix
      case MRM of
      $E3:
        Exit(Len + 1);
      else  // r bits matter if not one of the above specific opcodes
        goto Error; // unrecognized 2nd byte
      end;
    end;

    $DD: // various FP instructions
    begin
      MRM := APC^;
      Inc(APC);
      Inc(Len); //  account for FP prefix
      case MRM of
        $E1, $E9:
          Exit(Len + 1);
        else  // r bits matter if not one of the above specific opcodes
          case (MRM and $38) shr 3 of
            0: goto ModRMFetched;  // fld
            1: Exit(Len + 1); // fisttp
            2: goto ModRMFetched; // fst
            3: goto ModRMFetched; // fstp
            4: Exit(Len + 1); // frstor
            5: Exit(Len + 1); // fucomp
            6: goto ModRMFetched; // fnsav
            7: goto ModRMFetched; // fnstsw
          end;
          goto Error; // unrecognized 2nd byte
      end;
    end;

    $F3: // funny prefix REPE
    begin
      Opcode2 := APC^;  // get second opcode byte
      Inc(APC);
      case Opcode2 of
        $90, // == PAUSE
        $A4, $A5, $A6, $A7, $AA, $AB: // string operators
          Exit(Len + 2);
        $C3: // (REP) RET
        begin
          if APC^ <> $CC then
            Exit(Len + 2); // only (REP) RET

          Inc(APC);
          if APC^ <> $CC then
            goto error;

          Inc(APC);
          if APC^ = $CC then
            Exit(Len + 5); // (REP) RET CLONE IS LONG JUMP RELATIVE

          //Inc(APC);
          goto Error;
        end;

        $66: // operand size override (32->16 bits)
        begin
          if APC^ = $A5 then // "rep movsw"
            Exit(Len + 3);
          //Inc(APC);
          goto Error;
        end;

        else goto Error;
      end;
    end;

    $F6: // funny subblock of opcodes
    begin
      MRM := APC^;
      Inc(APC);

      if (MRM and $20) = 0 then
        Inc(Len); // 8 bit immediate operand
      goto ModRMFetched;
    end;

    $F7: // funny subblock of opcodes
    begin
      MRM := APC^;
      Inc(APC);

      if (MRM and $30) = 0 then
        Inc(Len, 4); // 32 bit immediate operand
      goto ModRMFetched;
    end;

    // Intel's special prefix opcode
    $0F:
    begin
      Inc(Len, 2); // add one for special prefix, and one for following opcode
      Opcode2 := APC^;
      Inc(APC);
      case Opcode2 of
        $31: // RDTSC
          Exit(Len);

        // CMOVxx
        $40, $41, $42, $43, $44, $45, $46, $47,
        $48, $49, $4A, $4B, $4C, $4D, $4E, $4F:
          goto ModRM;

          // JC relative 32 bits
        $80, $81, $82, $83, $84, $85, $86, $87,
        $88, $89, $8A, $8B, $8C, $8D, $8E, $8F:
          Exit(Len + 4); // account for subopcode and displacement

        // SETxx rm32
        $90, $91, $92, $93, $94, $95, $96, $97,
        $98, $99, $9A, $9B, $9C, $9D, $9E, $9F:
          goto ModRM;

        $A2: // CPUID
          Exit(Len + 2);

        $AE: // LFENCE, SFENCE, MFENCE
        begin
          Opcode2 := APC^;
          //Inc(APC);
          case Opcode2 of
            $E8, // LFENCE
            $F0, // MFENCE
            $F8: // SFENCE
              Exit(Len + 1);
            else
            begin
              //printf("InstructionLength: Unimplemented 0x0F, 0xAE tertiary opcode in clone  %2x at %x\n", opcode2, p - 1);
              goto Error;
            end;
          end;
        end;

        $AF, // imul
        $B0: // cmpxchg 8 bits
          goto Error;

        $B1, // cmpxchg 32 bits
        $B6, $B7, // movzx
        $BC, (* bsf *) $BD, // bsr
        // $BE, $BF, // movsx
        $C1, // xadd
        $C7: // cmpxchg8b
          goto ModRM;

        else
        begin
          //printf("InstructionLength: Unimplemented 0x0F secondary opcode in clone %2x at %x\n", opcode, p - 1);
          goto Error;
        end;
      end;
    end;

	 // ALL THE THE REST OF THE INSTRUCTIONS; these are instructions that runtime system shouldn't ever use
	else
		(*
      $26, $36, // ES, SS, prefixes
		  $9A,
		  $C8, $CA, $CB, $CD, $CE, $CF,
		  $D6, $D7,
		  $E4, $E5, $E6, $E7, $EA, $EB, $EC, $ED, $EF,
		  $F4, $FA, $FB:
    *)
		//printf("InstructionLength: Unexpected opcode %2x\n", opcode);
		goto Error;
  end;

ModRM:
  MRM := APC^;
  Inc(APC);

ModRMFetched:
  if TraceCloneChecking then
  begin
    //printf("InstructionLength: ModR/M byte %x %2x\n", pc, modrm);
  end;

  if MRM >= $C0 then
    Exit(Len + 1) // account for modrm opcode
  else
  begin
    (* memory access *)
    if MRM and $7 = $04 then
    begin
      (* instruction with SIB byte *)
      Inc(Len); // account for SIB byte
      SIB := APC^; // fetch the sib byte

      if SIB and $7 = $05 then
      begin
        if MRM and $C0 = $40 then
          Exit(Len + 1 + 1) // account for MOD + byte displacment
        else
          Exit(Len + 1 + 4); // account for MOD + dword displacement
      end;
    end;

    case MRM and $C0 of
      $00:
      begin
        if MRM and $7 = $05 then
          Exit(Len + 5) // 4 byte displacement
        else
          Exit(Len + 1); // zero length offset
      end;

      $80:
      begin
        Exit(Len + 5); // 4 byte offset
      end;

      else
        Exit(Len + 2); // one byte offset
    end;
  end;

Error:
  Exit(0);
end;

class function TMemory.HookExport(AModule: HMODULE; const AFuncName: string;
  AFuncAddr: Pointer): Pointer;
var
  P: Pointer;
begin
  if (AModule = 0) or (AFuncName = '') or (AFuncAddr = nil) then
    Exit(nil);

  P := GetProcAddress(AModule, PChar(AFuncName));
  if P = nil then
    Exit(nil);

  Result := TMemory.HookRegular(P, AFuncAddr);
end;

class function TMemory.HookRefAddr(AAddr, ANewAddr, AStart, AEnd: Pointer;
  AOpcode: Byte): Integer;
var
  OpSize: Integer;
  P: Pointer;
begin
  if (AAddr = nil) or (ANewAddr = nil) or (AStart = nil) or (AEnd = nil) then
    Exit(0);

  if AOpcode > 0 then
    OpSize := 1
  else
    OpSize := 0;

  Result := 0;
  P := AStart;
  AEnd := TMemory.Transpose(AEnd, -5);

  if AOpcode <> 0 then
  begin
    repeat
      P := TMemory.FindRelative(P, AStart, AEnd, AOpcode);
      if P = nil then
        Exit;

      if TMemory.Absolute(TMemory.Transpose(P, 1)) = AAddr then
      begin
        TMemory.WriteFunc(P, ANewAddr, AOpcode);
        Inc(Result);
      end;

      P := TMemory.Transpose(P, OpSize + SizeOf(AAddr));
    until False;
  end
  else
  begin
    repeat
      P := TMemory.FindPrimitive<Pointer>(P, AStart, AEnd, AAddr);
      if P = nil then
        Exit;

      TMemory.WritePrimitive<Pointer>(P, ANewAddr);
      P := TMemory.Transpose(P, SizeOf(AAddr));
      Inc(Result);
    until False;
  end;
end;

class function TMemory.HookRefCall(AAddr, ANewAddr, AStart,
  AEnd: Pointer): Integer;
begin
  Result := HookRefAddr(AAddr, ANewAddr, AStart, AEnd, $E8);
end;

class function TMemory.HookRefJump(AAddr, ANewAddr, AStart,
  AEnd: Pointer): Integer;
begin
  Result := HookRefAddr(AAddr, ANewAddr, AStart, AEnd, $E9);
end;

type
  PDetourInfo = ^TDetourInfo;
  TDetourInfo = record
  public
    const AsmJumpSize = 5;
    const DetourMagicNumber: Cardinal = $01010101;
  public
    Magic: array[0..3] of Byte;
    CodeSize: LongWord;

    class function Create(ACodeSize: Cardinal): PDetourInfo; static;

    function IsValid: Boolean;
    function GetCode: Pointer;
    function GetJump: Pointer;
    function GetSize: Cardinal;

    procedure DeleteThis;
  end;

class function TDetourInfo.Create(ACodeSize: Cardinal): PDetourInfo;
begin
  Result := TMemory.GetExecMem(SizeOf(Result^) + ACodeSize + AsmJumpSize);

  PLongWord(@Result^.Magic)^ := TDetourInfo.DetourMagicNumber;
  Result^.CodeSize := ACodeSize;
end;

procedure TDetourInfo.DeleteThis;
begin
  TMemory.FreeMemory(@Self);
end;

function TDetourInfo.GetCode: Pointer;
begin
  Result := Pointer(Integer(@Self) + SizeOf(Self));
end;

function TDetourInfo.GetJump: Pointer;
begin
  Result := Pointer(Cardinal(GetCode) + CodeSize);
end;

function TDetourInfo.GetSize: Cardinal;
begin
  Result := SizeOf(Self) + CodeSize;
end;

function TDetourInfo.IsValid: Boolean;
begin
  Result := PLongWord(@Self.Magic)^ = DetourMagicNumber;
end;

class function TMemory.HookRegular(AAddr, AFunc: Pointer): Pointer;
var
  Detour: PDetourInfo;

  Size, CodeSize: Integer;
begin
  if (AAddr = nil) or (AFunc = nil) then
    Exit(nil);

  CodeSize := 0;

  while CodeSize < 5 do
  begin
    Size := TMemory.GetInstructionLength(TMemory.Transpose(AAddr, CodeSize));
    if Size = 0 then
      Exit(nil);

    Inc(CodeSize, Size);
  end;

  Detour := TDetourInfo.Create(CodeSize);
  if Detour = nil then
    Exit(nil);

  Move(AAddr^, Detour.GetCode^, CodeSize);
  WriteJump(Detour.GetJump, Transpose(AAddr, CodeSize));
  WriteJump(AAddr, AFunc);

  Exit(Detour.GetCode);
end;

class function TMemory.RestoreHook(const AAddr): Boolean;
var
  Detour: PDetourInfo;
  Original: Pointer;
begin
  if not Assigned(@AAddr) then
    Exit(False);

  Detour := PPointer(@AAddr)^;
  Detour := Transpose(Detour, -SizeOf(Detour^));

  if not Detour.IsValid then
    Exit(False);

  Original := &Absolute(Transpose(Detour.GetJump, 1));
  WritePattern(Transpose(Original, -TDetourInfo.AsmJumpSize), Detour.GetCode, Detour.CodeSize);

  Detour.DeleteThis;

  Exit(True);
end;

class procedure TMemory.WriteCall(AAddr, AFunc: Pointer);
begin
  WriteFunc(AAddr, AFunc, $E8);
end;

class procedure TMemory.WriteFunc(AAddr, AFunc: Pointer; AOpcode: Byte);
begin
  if (AAddr = nil) or (AFunc = nil) then
    Exit;

  TMemory.WritePrimitive<Byte>(AAddr, AOpcode);
  TMemory.WriteRelative(TMemory.Transpose(AAddr, 1), TMemory.Transpose(AAddr, 1), AFunc);
end;

class procedure TMemory.WriteJump(AAddr, AFunc: Pointer);
begin
  WriteFunc(AAddr, AFunc, $E9);
end;

{ TSearchPattern }

procedure TSearchPattern.Absolute;
begin
  if FOutput^ <> nil then
    FOutput^ := TMemory.Absolute(FOutput^);
end;

procedure TSearchPattern.Align;
begin
  if FOutput^ <> nil then
    FOutput^ := Pointer(Integer(FOutput^) and not $F);
end;

function TSearchPattern.Check<T>(AValue: T; AOffset: Integer): Boolean;
begin
  if FOutput^ = nil then
    Exit(False);

  Result := TMemory.Check<T>(FOutput^, AValue, AOffset);
end;

function TSearchPattern.CheckUInt16(AValue: Word; AOffset: Integer): Boolean;
begin
  if FOutput^ = nil then
    Exit(False);

  Result := Check<Word>(AValue, AOffset);
end;

function TSearchPattern.CheckUInt32(AValue: LongWord;
  AOffset: Integer): Boolean;
begin
  if FOutput^ = nil then
    Exit(False);

  Result := Check<LongWord>(AValue, AOffset);
end;

function TSearchPattern.CheckUInt8(AValue: Byte; AOffset: Integer): Boolean;
begin
  if FOutput^ = nil then
    Exit(False);

  Result := Check<Byte>(AValue, AOffset);
end;

constructor TSearchPattern.Create(AModule: TModule; AOutput: Pointer; const AName: string);
begin
  FName := AName;
  FModule := AModule;
  FOutput := AOutput;
  FOutput^ := FModule.Base;
end;

procedure TSearchPattern.Dereference;
begin
  if FOutput^ <> nil then
    FOutput^ := PPointer(FOutput^)^;
end;

destructor TSearchPattern.Destroy;
{$IF DEFINED(DEBUG) AND DEFINED(SEARCH_PARANOIA)}
var
  Msg: string;
begin
  if (FOutput <> nil) and (FOutput^ = nil) then
  begin
    if FName <> '' then
      Msg := Format('TSearchPattern: Pattern "%s" not found.', [FName])
    else
      Msg := Format('TSearchPattern: Unnamed pattern not found.', []);

    MessageBox(HWND_DESKTOP, PChar(Msg), '', MB_ICONWARNING or MB_SYSTEMMODAL);
  end;
{$ELSE}
begin
{$ENDIF}
  inherited;
end;

procedure TSearchPattern.FindReference(ARefAddr: Pointer; ABack: Boolean);
begin
  if FOutput^ = nil then
    Exit;

  FOutput^ := TMemory.FindReference(FOutput^, Module.Base, Module.LastByte, ARefAddr);
end;

procedure TSearchPattern.FindAnsiString(AValue: PAnsiChar; AFlags: TPatternFlags);
var
  Pattern: TArray<Byte>;
  Len: Integer;
begin
  if FOutput^ = nil then
    Exit;

  if (AValue = nil) or (AValue^ = #0) then
  begin
    FOutput^ := nil;
    Exit;
  end;

  Len := StrLen(AValue) * SizeOf(AValue^);

  if not (pfStringPart in AFlags) then
    Inc(Len, SizeOf(AValue^));

  SetLength(Pattern, Len);
  Move(AValue^, Pattern[0], Len);

  if pfStringDeep in AFlags then
  begin
    with Module do
      FOutput^ := TMemory.FindPattern(Base, Base, LastByte, Pattern);
  end
  else
  begin
      with Module.SegmentReadOnlyData do
      FOutput^ := TMemory.FindPattern(Base, Base, LastByte, Pattern);
  end;

  if FOutput^ = nil then
    Exit;

  if pfStringRef in AFlags then
  begin
    if pfStringDeep in AFlags then
    begin
      with Module do
        FOutput^ := TMemory.FindReference(Base, Base, LastByte, FOutput^, $68)
    end
    else
    begin
      with Module.SegmentCode do
        FOutput^ := TMemory.FindReference(Base, Base, LastByte, FOutput^, $68);
    end;
  end;
end;

procedure TSearchPattern.FindCall(AIndex: Integer; ADeref, ABack: Boolean);
begin
  if FOutput^ = nil then
    Exit;

  FOutput^ := TMemory.FindRelative(FOutput^, Module.SegmentCode.Base, Module.SegmentCode.LastByte,
    $E8, AIndex, ABack);

  if (FOutput^ <> nil) and ADeref then
  begin
    FOutput^ := TMemory.Transpose(FOutput^, 1);
    FOutput^ := TMemory.Absolute(FOutput^);
  end;
end;

procedure TSearchPattern.FindJump(AIndex: Integer; ADeref, ABack: Boolean);
begin
  if FOutput^ = nil then
    Exit;

  FOutput^ := TMemory.FindRelative(FOutput^, Module.SegmentCode.Base, Module.SegmentCode.LastByte,
    $E9, AIndex, ABack);

  if (FOutput^ <> nil) and ADeref then
  begin
    FOutput^ := TMemory.Transpose(FOutput^, 1);
    FOutput^ := TMemory.Absolute(FOutput^);
  end;
end;

procedure TSearchPattern.FindSignature(const AValue: TArray<Byte>;
  AFlags: TPatternFlags);
begin
  if FOutput^ = nil then
    Exit;

  FOutput^ := TMemory.FindPattern(FOutput^, FModule.Base, FModule.LastByte, AValue, AFlags);
end;

procedure TSearchPattern.FindPrimitive<T>(AValue: T; AFlags: TPatternFlags);
begin
  if FOutput^ = nil then
    Exit;

  FOutput^ := TMemory.FindPrimitive<T>(FOutput^, FModule.Base, FModule.LastByte, AValue, AFlags);
end;

procedure TSearchPattern.FindRelative(AOpcode: Word; AIndex: Integer;
  ABack: Boolean);
begin
  if FOutput^ = nil then
    Exit;

  FOutput^ := TMemory.FindRelative(FOutput^, Module.SegmentCode.Base, Module.SegmentCode.LastByte,
    AOpcode, AIndex, ABack);
end;

procedure TSearchPattern.FindUInt16(AValue: Word; AFlags: TPatternFlags);
begin
  if FOutput^ = nil then
    Exit;

  FindPrimitive<Word>(AValue, AFlags);
end;

procedure TSearchPattern.FindUInt32(AValue: LongWord; AFlags: TPatternFlags);
begin
  if FOutput^ = nil then
    Exit;

  FindPrimitive<LongWord>(AValue, AFlags);
end;

procedure TSearchPattern.FindUInt8(AValue: Byte; AFlags: TPatternFlags);
begin
  if FOutput^ = nil then
    Exit;

  FindPrimitive<Byte>(AValue, AFlags);
end;

procedure TSearchPattern.FindVTable(const AName: AnsiString);
var
  Desc: PRTTITypeDescriptor;
begin
  if FOutput^ = nil then
    Exit;

  if AName = '' then
  begin
    FOutput^ := nil;
    Exit;
  end;

  with Module.SegmentData do
  	Desc := TMemory.GetRTTIDescriptor(Base, Base, LastByte, AName);

  if Desc = nil then
  begin
    FOutput^ := nil;
    Exit;
  end;

  with Module.SegmentReadOnlyData do
	  FOutput^ := TMemory.GetVTableForDescriptor(Base, Base, LastByte, Desc);
end;

procedure TSearchPattern.FindWideString(AValue: PAnsiChar; AFlags: TPatternFlags);
begin
  if FOutput^ = nil then
    Exit;

  if (AValue = nil) or (AValue^ = #0) then
  begin
    FOutput^ := nil;
    Exit;
  end;

  // TODO: Implement
  FOutput^ := nil;
end;

procedure TSearchPattern.ForceOutput(AValue: Pointer);
begin
  if (AValue = nil) or not TMemory.Bounds(AValue, Module.Base, Module.LastByte) then
  begin
    FOutput^ := nil;
    Exit;
  end;

  FOutput^ := AValue;
end;

procedure TSearchPattern.GetInterface(const Name: AnsiString);
var
  F: function(Name: PAnsiChar; ReturnCode: PInteger): Pointer; cdecl;
begin
  @F := GetProcAddress(HMODULE(Module.Base), 'CreateInterface');
  if @F = nil then
  begin
    FOutput^ := nil;
    Exit;
  end;

  FOutput^ := F(PAnsiChar(Name), nil);
end;

procedure TSearchPattern.GetProcedure(const Name: string);
begin
  FOutput^ := GetProcAddress(HMODULE(Module.Base), PChar(Name));
end;

function TSearchPattern.CurrentOutput: Pointer;
begin
  Result := FOutput^;
end;

procedure TSearchPattern.Transpose(AValue: Integer);
begin
  if FOutput^ = nil then
    Exit;

  FOutput^ := TMemory.Transpose(FOutput^, AValue)
end;

end.
