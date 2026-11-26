//
//  PAXON Packet Radio Terminal
//
//  Copyright 1996-2026 Ulf Haueisen <ulf@paxon.app>, Frankfurt, Germany
//
//  This file is part of PAXON.
//
//  SPDX-License-Identifier: MIT
//  PAXON is licensed under the MIT License; see LICENSE.md in the project root.
//


unit RemoteCommandsU;


interface


uses
  Classes, Windows, SysUtils, Messages, SyncObjs, Registry,
  GlobalU, InterfacesU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TRemoteCommands = class (TInterfacedObject, IRemoteCommands)
  private
    PacketConnection: IConnectionForModule;
    WorkingDir: String;
  public
    constructor create (aConnectionObj: IConnectionForModule); virtual;
    destructor  Destroy; override;
    procedure   call (TextLine: String);
    procedure   Release;
  published
  end;


  TRemoteCommand = class
  protected
    PacketConnection: IConnectionForModule;
    RemoteCommands: TRemoteCommands;
    procedure   SendTextData (S: String; aControlChars: Boolean = false); virtual;
  public
    constructor create (aConnectionObj: IConnectionForModule; aRemoteCommands: TRemoteCommands); virtual;
    class function Help (Long: Boolean): String; virtual;
    procedure   Call (Params: String); virtual; abstract;
  end;


  TRemoteCommandEcho = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandHelp = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandQuit = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandVersion = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandDisconnect = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandSID = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandRing = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandInfo = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandName = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandNews = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandCStatus = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandRTT = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandTalk = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandDir = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandCD = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandRead = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandDelete = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


  TRemoteCommandBinmode = class (TRemoteCommand)
    procedure   Call (Params: String); override;
    class function Help (Long: Boolean): String; override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


  TRemoteCommandClass = class of TRemoteCommand;


  TRemoteCommandsEntry = record
    RemoteCommandClass: TRemoteCommandClass;
    Name: String;
    MinRelevChars: Integer;
  end;


  TRemoteCommandManager = class (TInterfacedObject)
  private

    CriticalSection: TCriticalSection;
    RemoteCommandArray: array of TRemoteCommandsEntry;
    Reg: TRegistry;

    procedure   RegisterBuiltinCommands; virtual;

    procedure   LoadGlobal (const aCommand: String; var State: Boolean); virtual;
    procedure   SaveGlobal (const aCommand: String; State: Boolean); virtual;

    function    LoadCall (Call: String; const aCommand: String; var State: Boolean): Boolean; virtual;
    procedure   SaveCall (Call: String; const aCommand: String; State: Boolean); virtual;

  public

    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   RegisterCommand (RemoteCommandClass: TRemoteCommandClass; const Name: String; MinRelevChars: Cardinal;
                                 DefaultState: Boolean); virtual;
    function    Find (var Command: String): TRemoteCommandClass; virtual;
    procedure   GetList (const SL: TStringList); virtual;

    function    Load (Call: String; const aCommand: String; var State: Boolean): Boolean; virtual;
    procedure   Save (Call: String; const aCommand: String; State: Boolean); virtual;
    procedure   DeleteCall (Call: String; const aCommand: String); virtual;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  RemoteCommandManager: TRemoteCommandManager = nil;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  StrUtils, DebOutU, FolderU, SoundsU, SoundsConstsU, TextsU, TextsConstsU,
  StationDatabaseU, ConnectionsListU, SendFilePreprocessorU, FileStreamUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandManager.AfterConstruction;
begin

  inherited;

  assert (not assigned (RemoteCommandManager));
  RemoteCommandManager := self;

  CriticalSection := TCriticalSection.create;

  Reg := TRegistry.Create (KEY_READ or KEY_WRITE);
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.OpenKey (RootRegKey + '\Remotes', true);

  SetLength (RemoteCommandArray, 0);

  RegisterBuiltinCommands;

end;


procedure   TRemoteCommandManager.BeforeDestruction;
begin

  Reg.CloseKey;
  Reg.free;

  CriticalSection.free;

  inherited;

end;


procedure   TRemoteCommandManager.RegisterCommand (RemoteCommandClass: TRemoteCommandClass; const Name: String;
                                                   MinRelevChars: Cardinal; DefaultState: Boolean);
var
  I: Integer;
begin
  CriticalSection.Enter;
  try
    if (not Reg.ValueExists (Name)) then begin
      if (DefaultState) then I := 1 else I := 0;
      Reg.WriteInteger (Name, I);
    end;
    I := Length (RemoteCommandArray);
    SetLength (RemoteCommandArray, I + 1);
    RemoteCommandArray[I].RemoteCommandClass := RemoteCommandClass;
    RemoteCommandArray[I].Name := Name;
    RemoteCommandArray[I].MinRelevChars := MinRelevChars;
    DebOut ('RegisterCommand: %2d: %s', [I, RemoteCommandArray[I].Name]);
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TRemoteCommandManager.RegisterBuiltinCommands;
begin
  RegisterCommand (TRemoteCommandBinmode,    'binmode', 3, true);
  RegisterCommand (TRemoteCommandCD,         'cd', 2, false);
  RegisterCommand (TRemoteCommandCStatus,    'cstatus', 2, false);
  RegisterCommand (TRemoteCommandDelete,     'delete', 3, false);
  RegisterCommand (TRemoteCommandDir,        'dir', 3, false);
  RegisterCommand (TRemoteCommandDisconnect, 'disconnect', 3, true);
  RegisterCommand (TRemoteCommandEcho,       'echo', 1, true);
  RegisterCommand (TRemoteCommandHelp,       'help', 1, true);
  RegisterCommand (TRemoteCommandInfo,       'info', 1, true);
  RegisterCommand (TRemoteCommandName,       'name', 1, true);
  RegisterCommand (TRemoteCommandNews,       'news', 2, true);
  RegisterCommand (TRemoteCommandQuit,       'quit', 1, true);
  RegisterCommand (TRemoteCommandRead,       'read', 1, false);
  RegisterCommand (TRemoteCommandRing,       'ring', 2, true);
  RegisterCommand (TRemoteCommandRtt,        'rtt', 2, true);
  RegisterCommand (TRemoteCommandSID,        'sid', 3, true);
  RegisterCommand (TRemoteCommandVersion,    'version', 1, true);
end;


function   TRemoteCommandManager.Find (var Command: String): TRemoteCommandClass;
var
  I, L: Integer;
begin
  CriticalSection.Enter;
  try
    result := nil;
    L := Length (Command);
    for I := Low (RemoteCommandArray) to High (RemoteCommandArray) do begin
      if (L >= RemoteCommandArray[I].MinRelevChars) then begin
        if (StrLIComp (PChar(Command), PChar(RemoteCommandArray[I].Name), L) = 0) then begin
          Command := RemoteCommandArray[I].Name;
          result := RemoteCommandArray[I].RemoteCommandClass;
          break;
        end;
      end;
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TRemoteCommandManager.GetList (const SL: TStringList);
var
  L, I, N, K: Integer;
  S, T: String;

begin

  CriticalSection.Enter;
  try

    for I := Low (RemoteCommandArray) to High (RemoteCommandArray) do begin

      S := RemoteCommandArray[I].Name;
      L := Length (S);

      N := RemoteCommandArray[I].MinRelevChars;

      for K := Low (RemoteCommandArray) to I - 1 do begin
        if (RemoteCommandArray[K].MinRelevChars <= N) then begin
          while (StrLComp (PChar(S), PChar(RemoteCommandArray[K].Name), N) = 0) do begin
            inc (N);
            if (N > L) then break;
          end;
          if (N > L) then break;
        end;
      end;

      T := AnsiUpperCase (copy (S, 1, N)) + AnsiLowerCase (copy (S, N + 1, MaxInt));

      SL.Add (T);

    end;

    SL.Sort;

  finally
    CriticalSection.Leave;
  end;

end;


function    TRemoteCommandManager.Load (Call: String; const aCommand: String; var State: Boolean): Boolean;
const
  MethodName = 'Load';
begin
  CriticalSection.Enter;
  try
    if (Call = '') then begin
      LoadGlobal (aCommand, State);
      result := true;
    end else begin
      result := LoadCall (Call, aCommand, State);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TRemoteCommandManager.Save (Call: String; const aCommand: String; State: Boolean);
const
  MethodName = 'Save';
begin
  CriticalSection.Enter;
  try
    if (Call = '') then begin
      SaveGlobal (aCommand, State);
    end else begin
      SaveCall (Call, aCommand, State);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TRemoteCommandManager.DeleteCall (Call: String; const aCommand: String);
var
  E: IStationDatabaseEntry;
begin
  CriticalSection.Enter;
  try
    if (Length (Call) > 0) then begin
      E := StationDatabase.Open (Call);
      if (assigned (E)) then begin
        E.DeleteRemoteCommand (aCommand);
      end;
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TRemoteCommandManager.LoadGlobal (const aCommand: String; var State: Boolean);
begin
  CriticalSection.Enter;
  try
    State := false;
    try
      State := (Reg.ReadInteger (UpperCase (aCommand)) <> 0);
    except
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TRemoteCommandManager.SaveGlobal (const aCommand: String; State: Boolean);
var
  I: Integer;
begin
  CriticalSection.Enter;
  try
    if (State) then I := 1 else I := 0;
    Reg.WriteInteger (UpperCase (aCommand), I);
  finally
    CriticalSection.Leave;
  end;
end;


function    TRemoteCommandManager.LoadCall (Call: String; const aCommand: String; var State: Boolean): Boolean;
var
  E: IStationDatabaseEntry;
begin
  CriticalSection.Enter;
  try
    result := false;
    E := StationDatabase.Open (Call);
    if (assigned (E)) then begin
      result := E.GetRemoteCommand (aCommand, State);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TRemoteCommandManager.SaveCall (Call: String; const aCommand: String; State: Boolean);
var
  E: IStationDatabaseEntry;
begin
  CriticalSection.Enter;
  try
    E := StationDatabase.Open (Call);
    if (assigned (E)) then begin
      E.SetRemoteCommand (aCommand, State);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    RemoteCommandAllowed (const Call, CommandStr: String): Boolean;
// Permissions apply to the exact callsign with SSID. A station entry without SSID stands for SSID 0:
// its grants apply only to SSID 0, its denials to all SSIDs without an entry of their own.
// Otherwise the global setting applies.
var
  BaseCall: String;
  B, State: Boolean;
begin
  State := false;
  BaseCall := StripSSID (Call);
  B := RemoteCommandManager.Load (Call, CommandStr, State);
  if (not B) and (BaseCall <> Call) then begin
    B := RemoteCommandManager.Load (BaseCall, CommandStr, State);
    if (B) and (State) and (Call <> BaseCall + '-0') then B := false;
  end;
  if (not B) then begin
    RemoteCommandManager.Load ('', CommandStr, State);
  end;
  result := State;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TRemoteCommands.create (aConnectionObj: IConnectionForModule);
begin
  inherited create;
  PacketConnection := aConnectionObj;
  WorkingDir := '';
end;


destructor  TRemoteCommands.destroy;
begin
  Release;
  inherited;
end;


procedure   TRemoteCommands.Release;
begin
  PacketConnection := nil;
end;


procedure   TRemoteCommands.call (TextLine: String);
resourcestring
  SInvalidRemoteCommand = 'Ungültiger Fernsteuerbefehl.';
  SRemoteCommandDenied = 'Fernsteuerbefehl gesperrt.';
  SRemoteCommandError = 'Fehler bei der Ausführung des Fernsteuerbefehls.';

const
  MethodName = 'Call';

var
  I, L: Integer;
  CommandStr, Parameter: String;
  RemoteCommandClass: TRemoteCommandClass;
  RemoteCommand: TRemoteCommand;
  State: Boolean;

begin

  if (StrLComp (PChar(TextLine), PChar('//'), 2) = 0) then Delete (TextLine, 1, 2);
  L := Length (TextLine);

  RemoteCommandClass := nil;
  State := true;

  if (L >= 1) and (TextLine[1] <> '/') and (TextLine[1] <> ' ') then begin

    if (TextLine[L] = #13) then begin
      Delete (TextLine, L, 1);
      Dec (L);
    end;

    if (L >= 1) then begin

      I := Pos (' ', TextLine);

      if (I = 0) then begin
        CommandStr := TextLine;
        Parameter := '';
      end else begin
        CommandStr := copy (TextLine, 1, I - 1);
        Parameter := Trim (copy (TextLine, I + 1, MaxInt));
      end;

      CommandStr := AnsiUpperCase (CommandStr);

      RemoteCommandClass := RemoteCommandManager.Find (CommandStr);

      if (assigned (RemoteCommandClass)) then begin

        State := RemoteCommandAllowed (PacketConnection.Call, CommandStr);

        if (not State) then RemoteCommandClass := nil;

      end;

    end;

    if (assigned (RemoteCommandClass)) then begin

      RemoteCommand := RemoteCommandClass.create (PacketConnection, self);
      try
        try
          RemoteCommand.Call (Parameter);
        except
          PacketConnection.SendTextData (RemotePrompt + SRemoteCommandError + #13, true, true, false, true);
        end;
      finally
        RemoteCommand.free;
      end;

    end else begin

      if (State) then begin
        PacketConnection.SendTextData (RemotePrompt + SInvalidRemoteCommand + #13, true, true, false, true);
      end else begin
        PacketConnection.SendTextData (RemotePrompt + SRemoteCommandDenied + #13, true, true, false, true);
      end;

    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TRemoteCommand.create (aConnectionObj: IConnectionForModule; aRemoteCommands: TRemoteCommands);
begin
  inherited create;
  PacketConnection := aConnectionObj;
  RemoteCommands := aRemoteCommands;
end;


class function TRemoteCommand.Help (Long: Boolean): String;
begin
  result := '';
end;


procedure   TRemoteCommand.SendTextData (S: String; aControlChars: Boolean = false);
// The output mostly contains data from outside (echo text, file names, names):
// ^ sequences are only interpreted in the station's own texts (aControlChars).
begin
  assert (assigned (PacketConnection));
  PacketConnection.SendTextData (S, true, aControlChars, false, true);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandEcho.Call (Params: String);
begin
  SendTextData (Params + #13);
end;


class function TRemoteCommandEcho.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandEchoHelp = 'Sendet Text zurück';
begin
  result := SRemoteCommandEchoHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandHelp.Call (Params: String);
resourcestring
  SHelpEnabled = 'Verfügbare Fernsteuerbefehle:';
  SHelpDisabled = 'Gesperrte Fernsteuerbefehle:';

var
  I, M, N: Integer;
  H, S, T, U: String;
  SL, SLE, SLD: TStringList;
  State: Boolean;
  RemoteCommandClass: TRemoteCommandClass;

begin

  SLE := TStringList.create;
  SLD := TStringList.create;

  try

    SL := TStringList.create;

    try

      RemoteCommandManager.GetList (SL);

      M := 0;

      for I := 0 to SL.Count - 1 do begin

        N := Length (SL[I]);
        if (N > M) then M := N;

        State := RemoteCommandAllowed (PacketConnection.Call, SL[I]);

        if (State) then begin
          SLE.Add (SL[I]);
        end else begin
          SLD.Add (SL[I]);
        end;

      end;

    finally
      SL.free;
    end;

    U := RemotePrompt;

    if (SLE.Count > 0) then begin

      U := U + SHelpEnabled + #13#13;

      SetLength (T, M);

      for I := 0 to SLE.Count - 1 do begin
        S := SLE[I];
        RemoteCommandClass := RemoteCommandManager.Find (S);
        S := SLE[I];
        if (assigned (RemoteCommandClass)) then begin
          H := RemoteCommandClass.Help (false);
          if (Length (H) > 0) then H := ' - ' + H;
        end else begin
          H := '';
        end;
        FillChar (T[1], M, Ord (' '));
        Move (S[1], T[1], Length (S));
        U := U + '  //' + T + H + #13;
      end;

      U := U + #13;

    end;

    if (SLD.Count > 0) then begin

      U := U + SHelpDisabled + ' ';

      for I := 0 to SLD.Count - 1 do begin
        if (I > 0) then U := U + ', ';
        U := U + SLD[I];
      end;

      U := U + '.' + #13#13;

    end;

    SendTextData (U);

  finally

    SLE.free;
    SLD.free;

  end;

end;


class function TRemoteCommandHelp.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandHelpHelp = 'Zeigt diese Hilfe an';
begin
  result := SRemoteCommandHelpHelp;;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandQuit.Call (Params: String);
begin
  Texts.SendTextItem (te_end, PacketConnection);
  PacketConnection.Disconnect;
end;


class function TRemoteCommandQuit.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandQuitHelp = 'Sendet Abschiedstext und trennt die Verbindung';
begin
  result := SRemoteCommandQuitHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandVersion.Call (Params: String);
resourcestring
  SVersion = 'Version %s';
begin
  SendTextData (RemotePrompt + Format (SVersion, [Version]) + #13);
end;


class function TRemoteCommandVersion.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandVersionHelp = 'Gibt die Version von Paxon aus';
begin
  result := SRemoteCommandVersionHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandDisconnect.Call (Params: String);
begin
  PacketConnection.Disconnect;
end;


class function TRemoteCommandDisconnect.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandDisconnectHelp = 'Trennt die Verbindung';
begin
  result := SRemoteCommandDisconnectHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandSID.Call (Params: String);
begin
  PacketConnection.SendSID;
end;


class function TRemoteCommandSID.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandSIDHelp = 'Sendet die Terminal-Station-ID';
begin
  result := SRemoteCommandSIDHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandRing.Call (Params: String);
resourcestring
  SDidRing = 'Es hat geklingelt.';
  SDidntRing = 'Es hat nicht geklingelt.';
begin
  if (Sounds.PlayEvent (se_ring, PacketConnection)) then begin
    SendTextData (RemotePrompt + SDidRing + #13);
  end else begin
    SendTextData (RemotePrompt + SDidntRing + #13);
  end;
end;


class function TRemoteCommandRing.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandRingHelp = 'Ruft den Benutzer';
begin
  result := SRemoteCommandRingHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandInfo.Call (Params: String);
resourcestring
  SNoInfo = 'Kein Info-Text vorhanden.';
var
  T: String;
begin
  T := Texts.Text (te_info, PacketConnection);
  if (Length (T) = 0) then begin
    T := RemotePrompt + SNoInfo + #13
  end;
  SendTextData (T, true);
end;


class function TRemoteCommandInfo.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandInfoHelp = 'Zeigt Informationen über diese Station';
begin
  result := SRemoteCommandInfoHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandName.Call (Params: String);
resourcestring
  SNameUnknown = 'Name unbekannt.';
  SNameHello = 'Hallo %s.';
  SNameError = 'Fehler.';

const
  MaxNameLength = 30;

var
  E: IStationDatabaseEntry;
  StationCall, BaseCall, N: String;
  IsBase: Boolean;
  I: Integer;

begin

  // The name comes from the remote station: no control characters, limited length.
  N := '';
  for I := 1 to Length (Params) do begin
    if (Params[I] >= ' ') then N := N + Params[I];
  end;
  N := Trim (Copy (Trim (N), 1, MaxNameLength));

  StationCall := PacketConnection.Call;
  BaseCall := StripSSID (StationCall);
  IsBase := (StationCall = BaseCall) or (StationCall = BaseCall + '-0');

  if (N = '') then begin

    E := StationDatabase.Open (StationCall, true);
    if (assigned (E)) and (E.Name <> '') then begin
      SendTextData (Format ('%s' + SNameHello + #13, [RemotePrompt, E.Name]));
    end else begin
      SendTextData (Format ('%s' + SNameUnknown + #13, [RemotePrompt]));
    end;

  end else begin

    // Only the station's own entry is changed. An SSID other than 0 never gets an entry of its
    // own (that would drop the denials of the entry without SSID, see RemoteCommandAllowed) and
    // may only fill in a missing name of the entry without SSID, not overwrite it.
    E := StationDatabase.Open (StationCall, IsBase);
    if (not assigned (E)) then begin
      E := StationDatabase.Open (BaseCall);
      if (not assigned (E)) then begin
        E := StationDatabase.Add (BaseCall);
        // Add returns nil if the station has been created in the meantime: then use that one
        if (not assigned (E)) then E := StationDatabase.Open (BaseCall);
      end;
      if (assigned (E)) and (not IsBase) and (E.Name <> '') and (E.Name <> N) then E := nil;
    end;

    if (assigned (E)) then begin
      E.Name := N;
      SendTextData (Format ('%s' + SNameHello + #13, [RemotePrompt, N]));
    end else begin
      SendTextData (RemotePrompt + SNameError + #13);
    end;

  end;

end;


class function TRemoteCommandName.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandNameHelp = 'Trägt den Namen in die Datenbank ein';
begin
  result := SRemoteCommandNameHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandNews.Call (Params: String);
resourcestring
  SNoNews = 'Keine Neuigkeiten.';
var
  T: String;
begin
  T := Texts.Text (te_news, PacketConnection);
  if (Length (T) = 0) then begin
    T := RemotePrompt + SNoNews + #13
  end;
  SendTextData (T, true);
end;


class function TRemoteCommandNews.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandNewsHelp = 'Zeigt aktuelle Informationen';
begin
  result := SRemoteCommandNewsHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandCStatus.Call (Params: String);
resourcestring
  SCStatusTitle = 'Verbindungs-Status:';
var
  I: Integer;
  S, T: String;
  V: IConnection;
begin
  SendTextData (RemotePrompt + SCStatusTitle + #13#13);
  // Only collect the lines under the lock: sending echoes to the channel window via
  // SendMessage, and the main thread may wait for ConnectionsList.Lock meanwhile.
  S := '';
  ConnectionsList.Lock;
  try
    for I := 0 to ConnectionsList.Count - 1 do begin
      V := ConnectionsList.Items[I];
      if (V.Outgoing) then T := '>' else T := '<';
      S := S + Format ('  %-9s %s %-9s'#13, [V.MyCall, T, V.Call]);
    end;
    V := nil;
  finally
    ConnectionsList.UnLock;
  end;
  SendTextData (S + #13);
end;


class function TRemoteCommandCStatus.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandCStatusHelp = 'Zeigt die bestehenden Verbindungen an';
begin
  result := SRemoteCommandCStatusHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandRTT.Call (Params: String);
resourcestring
  SRttError = 'Fehler.';
  SRttResult = 'Laufzeit: %d sek.';
var
  N: Cardinal;
begin
  if (Params = '') then begin
    SendTextData (Format ('//e //rtt %d'#13, [GetTickCount]));
  end else begin
    N := StrToIntDef (Params, 0);
    if (N > 0) then begin
      N := GetTickCount - N;
      SendTextData (Format ('%s' + SRttResult + #13, [RemotePrompt, Round (N / 1000)]));
    end else begin
      SendTextData (RemotePrompt + SRttError + #13);
    end;
  end;
end;


class function TRemoteCommandRTT.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandRTTHelp = 'Misst die Laufzeit (hin und zurück)';
begin
  result := SRemoteCommandRTTHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandTalk.Call (Params: String);
begin
  SendTextData (RemotePrompt + 'Talk.' + #13);
end;


class function TRemoteCommandTalk.Help (Long: Boolean): String;
begin
  result := '';
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandDir.Call (Params: String);
resourcestring
  SRemoteCommandDirFolderAccessDenied = 'Zugriff verweigert. Ordner: %s';
  SRemoteCommandDirHeader = 'Inhalt von %s%s%s';
  SRemoteCommandDirSummary = '%d Dateien, %.0n Bytes';

var
  Files: TFileEntryArray;
  I, N: Integer;
  S, T, U, V: String;
  C: Currency;
  Folder, Wildcard: String;

begin

  for I := 1 to Length (Params) do if Params[I] in ['\', '/'] then Params[I] := PathDelim;

  S := RemoteCommands.WorkingDir + PathDelim + Params;

  if (Folders.FindRemoteFiles (S, true, Files, Folder, Wildcard)) then begin

    SendTextData (RemotePrompt + Format (SRemoteCommandDirHeader, [Folder, PathDelim, Wildcard]) + #13#13);

    for I := 0 to Length (Files) - 1 do begin

      T := FormatDateTime ('ddddd t', Files[I].Time);

      V := Files[I].Name;

      C := Files[I].Size;
      if (Files[I].Attr and faDirectory = 0) then begin
        U := Format ('%11.0n', [C]);
      end else begin
        U := Format ('%-11s', ['<DIR>']);
        V := V + PathDelim;
      end;

      SendTextData (Format ('%s %s %s'#13, [T, U, V]));

    end;

    C := 0;
    N := 0;
    for I := 0 to Length (Files) - 1 do begin
      if (Files[I].Attr and (faDirectory or faVolumeID) = 0) then begin
        C := C + Files[I].Size;
        inc (N);
      end;
    end;

    if (Length (Files) > 0) then SendTextData (#13);

    SendTextData (Format ('         ' + SRemoteCommandDirSummary + #13, [N, C]));

  end else begin

    SendTextData (RemotePrompt + Format (SRemoteCommandDirFolderAccessDenied, [Folder]) + #13);

  end;

end;


class function TRemoteCommandDir.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandDirHelp = 'Zeigt den Inhalt des aktuellen Ordners an';
begin
  result := SRemoteCommandDirHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandCD.Call (Params: String);
const
  MethodName = 'Call';

resourcestring
  SRemoteCommandCDCurrentDirectory = 'Aktueller Ordner: %s';
  SRemoteCommandCDInvalidParameter = 'Ungültiger Parameter';

var
  I: Integer;
  Folder: String;
  Found: Boolean;
  S, T, U: String;
  SR: TSearchRec;
  RemoteFolder: String;

begin

  if (Params <> '') then begin

    for I := 1 to Length (Params) do if Params[I] in ['\', '/'] then Params[I] := PathDelim;

    RemoteFolder := IncludeTrailingPathDelimiter (ExpandFileName (Folders.Remote));

    Found := false;

    if (Params[1] <> PathDelim) then begin
      S := IncludeTrailingPathDelimiter (RemoteCommands.WorkingDir) + ExcludeTrailingPathDelimiter (Params);
    end else begin
      S := ExcludeTrailingPathDelimiter (Params);
    end;
    if (Length (S) > 0) and (S[1] = PathDelim) then Delete (S, 1, 1);

    DebOut (self, MethodName, RemoteFolder + S);

    if (DirectoryExists (RemoteFolder + S)) then begin

      // Junctions and symbolic links inside the remote folder are not followed.
      T := IncludeTrailingPathDelimiter (ExpandFileName (RemoteFolder + S));
      if (AnsiStartsText (RemoteFolder, T)) and (not ContainsReparsePoint (RemoteFolder, T)) then begin
        Folder := ExtractRelativePath (RemoteFolder, T);
        Found := true;
      end;

    end else begin

      T := ExtractFilePath (RemoteFolder + S);
      DebOut (self, MethodName, 'T: ' + T);

      I := FindFirst (RemoteFolder + S, faAnyFile, SR);
      while (I = 0) do begin

        if (SR.Attr and faDirectory <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then begin
          DebOut (self, MethodName, SR.Name);
          // Only accept folders inside the remote folder (not e.g. ..\..\Win*).
          U := IncludeTrailingPathDelimiter (ExpandFileName (T + SR.Name));
          if (AnsiStartsText (RemoteFolder, U)) and (not ContainsReparsePoint (RemoteFolder, U)) then begin
            Folder := ExtractRelativePath (RemoteFolder, U);
            Found := true;
            break;
          end;
        end;

        I := FindNext (SR);

      end;

      FindClose (SR);

    end;


    if (Found) then begin
      RemoteCommands.WorkingDir := ExcludeTrailingPathDelimiter (Folder);
    end else begin
      SendTextData (RemotePrompt + SRemoteCommandCDInvalidParameter + #13);
    end;

  end else begin

    Found := true;

  end;

  if (Found) then begin
    SendTextData (RemotePrompt + Format (SRemoteCommandCDCurrentDirectory, [Remotecommands.WorkingDir + PathDelim]) + #13);
  end;

end;


class function TRemoteCommandCD.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandCDHelp = 'Wechselt den aktuellen Ordner';
begin
  result := SRemoteCommandCDHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure TRemoteCommandRead.Call (Params: String);
const
  MethodName = 'Call';

resourcestring
  SRemoteCommandReadFolderAccessDenied = 'Zugriff verweigert. Ordner: %s';

const
  // Files of one connection that may wait in the send queue. Each queued file stays
  // open (and locked against writing) until it is sent.
  MaxQueuedFiles = 50;

var
  Files: TFileEntryArray;
  I: Integer;
  S: String;
  Folder, Wildcard, T: String;
  SendFilePreprocessor: TSendFilePreprocessor;
  Stream: TFileStream;
  RemoteFolder: String;
  Queue: ISendFileQueue;

  function QueueFull: Boolean;
  begin
    Queue := PacketConnection.SendFileQueue;
    result := (not assigned (Queue)) or (Queue.Count >= MaxQueuedFiles);
    Queue := nil;
  end;

begin

  for I := 1 to Length (Params) do if Params[I] in ['\', '/'] then Params[I] := PathDelim;

  RemoteFolder := IncludeTrailingPathDelimiter (ExpandFileName (Folders.Remote));

  S := RemoteCommands.WorkingDir + PathDelim + Params;

  // Ein Ordnername wird nicht zu "alle Dateien darin" erweitert: read sendet
  // nur ausdrücklich genannte Dateien oder Platzhalter (sonst bis zu 1000 Dateien).
  // Only checked inside the remote folder: otherwise the answer would tell whether a folder
  // outside exists. FindRemoteFiles rejects those with the same message.
  T := ExpandFileName (RemoteFolder + S);
  if (AnsiStartsText (RemoteFolder, IncludeTrailingPathDelimiter (T))) and (DirectoryExists (T)) then begin
    SendTextData (RemotePrompt + Format (SRemoteCommandReadFolderAccessDenied, [Params]) + #13);
    exit;
  end;

  if (Folders.FindRemoteFiles (S, true, Files, Folder, Wildcard)) then begin

    if (Length (Files) >= 1) then begin

      for I := 0 to Length (Files) - 1 do begin

        if (Files[I].Attr and (faDirectory or faVolumeID) = 0) then begin

          if (QueueFull) then begin
            SendTextData (RemotePrompt + Format (SRemoteCommandReadFolderAccessDenied, [Params]) + #13);
            break;
          end;

          SendFilePreprocessor := TSendFilePreprocessor.create;
          try

            // Use the folder that FindRemoteFiles checked, and check the result again.
            S := ExpandFileName (IncludeTrailingPathDelimiter (RemoteFolder + Folder) + Files[I].Name);

            Stream := nil;
            if (AnsiStartsText (RemoteFolder, S)) then begin
              try
                Stream := TFileStream.create (S, fmOpenRead or
                                              fmShareDenyWrite); // Stream is freed again in SendFilePreprocessor or SendXXX.
              except
                Stream := nil;
              end;
            end;

            if (assigned (Stream)) then begin

              SendFilePreprocessor.Stream := Stream;
              SendFilePreprocessor.PacketConnection := PacketConnection;

              SendFilePreprocessor.FileNameStr := Files[I].Name;

              if (PacketConnection.BinMode = prot_didadit) then begin
                SendFilePreprocessor.TransferProtocol := prot_didadit;
              end else begin
                SendFilePreprocessor.TransferProtocol := prot_autobin;
              end;

              SendFilePreprocessor.TextBefore := '';
              SendFilePreprocessor.TextAfter := '';

              SendFilePreprocessor.SizePerPart := 0;
              SendFilePreprocessor.PartsCount := 0;

              SendFilePreprocessor.PGP := nil;
              SendFilePreprocessor.PGPEnabled := false;
              SendFilePreprocessor.PGPKey := nil;
              SendFilePreprocessor.PGPPassword := '';
              SendFilePreprocessor.PGPCommentText := '';

              SendFilePreprocessor.Execute;

            end else begin

              SendTextData (RemotePrompt + Format (SRemoteCommandReadFolderAccessDenied, [Folder]) + #13);

            end;

          finally

            SendFilePreprocessor.free;

          end;

        end;

      end;

    end else begin

      SendTextData (RemotePrompt + Format (SRemoteCommandReadFolderAccessDenied, [Folder]) + #13);

    end;

  end else begin

    SendTextData (RemotePrompt + Format (SRemoteCommandReadFolderAccessDenied, [Params]) + #13);

  end;

end;


class function TRemoteCommandRead.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandReadHelp = 'Lädt eine Datei herunter';
begin
  result := SRemoteCommandReadHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure TRemoteCommandDelete.Call (Params: String);
const
  MethodName = 'Call';

resourcestring
  SRemoteCommandDeleteNoParam = 'Parameter erforderlich';
  SRemoteCommandDeleteNotFound = 'Datei(en) nicht gefunden';
  SRemoteCommandDeleteFileDeleted = '%s: gelöscht';
  SRemoteCommandDeleteFileAccessDenied = '%s: Zugriff verweigert';

var
  Files: TFileEntryArray;
  I: Integer;
  S: String;
  Folder, Wildcard: String;
  RemoteFolder: String;
  B: Boolean;

begin

  if (length (Params) > 0) then begin

    for I := 1 to Length (Params) do if Params[I] in ['\', '/'] then Params[I] := PathDelim;

    RemoteFolder := IncludeTrailingPathDelimiter (ExpandFileName (Folders.Remote));

    S := RemoteCommands.WorkingDir + PathDelim + Params;

    B := false;

    // Ein Ordnername wird nicht zu "alle Dateien darin" erweitert: delete löscht
    // nur ausdrücklich genannte Dateien oder Platzhalter. Vorher löschte
    // "//del ." oder "//del Ordner" alle Dateien des Ordners.
    if (DirectoryExists (ExpandFileName (RemoteFolder + S))) then begin
      SendTextData (RemotePrompt + SRemoteCommandDeleteNotFound + #13);
      exit;
    end;

    if (Folders.FindRemoteFiles (S, true, Files, Folder, Wildcard)) then begin
      for I := 0 to Length (Files) - 1 do begin

        if (Files[I].Attr and (faDirectory or faVolumeID) = 0) then begin

          // Use the folder that FindRemoteFiles checked, and check the result again.
          S := ExpandFileName (IncludeTrailingPathDelimiter (RemoteFolder + Folder) + Files[I].Name);
          if (AnsiStartsText (RemoteFolder, S)) and (DeleteFile (S)) then begin
            SendTextData (RemotePrompt + Format (SRemoteCommandDeleteFileDeleted, [Files[I].Name]) + #13);
          end else begin
            SendTextData (RemotePrompt + Format (SRemoteCommandDeleteFileAccessDenied, [Files[I].Name]) + #13);
          end;

          B := true;

        end;

      end;
    end;

    if (not B) then begin
      SendTextData (RemotePrompt + SRemoteCommandDeleteNotFound + #13);
    end;

  end else begin
    SendTextData (RemotePrompt + SRemoteCommandDeleteNoParam + #13);
  end;

end;


class function TRemoteCommandDelete.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandDeleteHelp = 'Löscht eine Datei';
begin
  result := SRemoteCommandDeleteHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure TRemoteCommandBinmode.Call (Params: String);
var
  P: TSendFileProtocol;
  S: String;
begin

  if (Length (Params) > 0) then begin
    P := prot_unknown;
    if (AnsiStartsText (Params, 'didadit')) then begin
      P := prot_didadit;
    end else if (AnsiStartsText (Params, 'autobin')) then begin
      P := prot_autobin;
    end;
    if (P <> prot_unknown) then PacketConnection.BinMode := P;
  end;

  case PacketConnection.BinMode of
    prot_didadit: S := 'DIDADIT';
    prot_autobin: S := 'AUTOBIN';
    else S := 'unbekannt';
  end;

  SendTextData (RemotePrompt + 'Übertragungsprotokoll: ' + S + #13);

end;


class function TRemoteCommandBinmode.Help (Long: Boolean): String;
resourcestring
  SRemoteCommandBinmodeHelp = 'Wählt ein Binärübertragungsprotokoll aus';
begin
  result := SRemoteCommandBinmodeHelp;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

