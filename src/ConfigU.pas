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


unit ConfigU;


interface


uses
  Classes, Windows, SysUtils, Messages, SyncObjs, Registry,
  Forms, Graphics, InterfacesU, GlobalU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  MonitorStatus = 2;
  MonitorInformation = 4;
  MonitorInformationContent = 8;
  MonitorUnproto = 16;
  MonitorLocal = 64;
  MonitorInformationBinary = 128;
  MonitorPort = 256;

  MonitorEnabled = MonitorStatus or MonitorInformation or MonitorUnproto;

type
  TColorType = (ct_output_background,
                ct_output_connstat,
                ct_output_received,
                ct_output_sent,
                ct_output_local,
                ct_input_background,
                ct_input_new,
                ct_input_sent,
                ct_monitor_background,
                ct_monitor_header_received,
                ct_monitor_header_sent,
                ct_monitor_data,
                ct_monitor_local);

const
  DefaultColors: array [TColorType] of TColor = ($FFFFFF,
                                                 $000000,
                                                 $7F0000,
                                                 $00009F,
                                                 $7F6C00,
                                                 $FFFFFF,
                                                 $000000,
                                                 $0000C0,
                                                 $FFFFFF,
                                                 $7F0000,
                                                 $00009F,
                                                 $007F00,
                                                 $606060);

type

  TConfig = class
  private

    FMonitor: Cardinal;
    FFontSize: string;

    Registry: TRegistry;

    FCriticalSection: TCriticalSection;

    function    ValueExists  (Root: DWord; const Key: string; const ValueName: string): boolean;

    function    ReadString   (Root: DWord; const Key: string; const ValueName: string): string;
    procedure   WriteString  (Root: DWord; const Key: string; const ValueName: String; const Value: string);

    function    ReadBoolean  (Root: DWord; const Key: string; const ValueName: string; DefaultValue: Boolean = false): Boolean;
    procedure   WriteBoolean (Root: DWord; const Key: string; const ValueName: string; Value: Boolean);

    function    ReadInteger  (Root: DWord; const Key: string; const ValueName: string; DefaultValue: Integer): Integer; overload;
    function    ReadInteger  (Root: DWord; const Key: string; const ValueName: string): Integer; overload;
    procedure   WriteInteger (Root: DWord; const Key: string; const ValueName: string; Value: Integer);

    function    GetSplashScreen: Boolean;
    procedure   SetSplashScreen (Value: Boolean);

    function    GetMonitor: Cardinal;
    procedure   SetMonitor (Value: Cardinal);

    function    GetPGPCollectPublicKeys: Boolean;
    procedure   SetPGPCollectPublicKeys (const Value: Boolean);

    procedure   SetPGPDetailedOutput (const Value: Boolean);
    function    GetPGPDetailedOutput: Boolean;

    function    GetPGPComment: string;
    procedure   SetPGPComment (const Value: string);

    function    GetSendSID: Boolean;
    procedure   SetSendSID (const Value: Boolean);

    function    GetHideSentSID: Boolean;
    procedure   SetHideSentSID (const Value: Boolean);

    function    GetHideReceivedSID: Boolean;
    procedure   SetHideReceivedSID (const Value: Boolean);

    function    GetFontSize: string;
    procedure   SetFontSize (const Value: string);

    function    GetHighColor: Boolean;
    procedure   SetHighColor (const Value: Boolean);

    procedure   SetTimestamp (const Value: Boolean);
    function    GetTimestamp: Boolean;

    procedure   SetChannels (const Value: Integer);
    function    GetChannels: Integer;

    function    GetIncomingConnect: TIncomingConnect;
    procedure   SetIncomingConnect (const Value: TIncomingConnect);

    function    GetColor (ColorType: TColorType): TColor;
    procedure   SetColor (ColorType: TColorType; const Value: TColor);

    function    GetInputHeight: Integer;
    procedure   SetInputHeight (const Value: Integer);

    function    GetMonitorHeight: Integer;
    procedure   SetMonitorHeight (const Value: Integer);


    function    GetToolbarText: Integer;
    procedure   SetToolbarText (const Value: Integer);

    function    GetLocalEcho: Boolean;
    procedure   SetLocalEcho (const Value: Boolean);

    function    GetDirty: Boolean;
    procedure   SetDirty (const Value: Boolean);

    function    GetForceDatabaseCheck: Boolean;
    procedure   SetForceDatabaseCheck (const Value: Boolean);

    function    GetUIDestination: string;
    procedure   SetUIDestination (const Value: string);

    function    GetUIPort: string;
    procedure   SetUIPort (const Value: string);

    function    GetUIMycall: string;
    procedure   SetUIMycall (const Value: string);

    function    GetConsoleRows: Integer;
    procedure   SetConsoleRows (const Value: Integer);

  public

    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;

    property    SplashScreen: Boolean read GetSplashScreen write SetSplashScreen;
    property    Monitor: Cardinal read GetMonitor write SetMonitor;
    property    PGPCollectPublicKeys: Boolean read GetPGPCollectPublicKeys write SetPGPCollectPublicKeys;
    property    PGPDetailedOutput: Boolean read GetPGPDetailedOutput write SetPGPDetailedOutput;
    property    PGPComment: string read GetPGPComment write SetPGPComment;
    property    SendSID: Boolean read GetSendSID write SetSendSID;
    property    HideSentSID: Boolean read GetHideSentSID write SetHideSentSID;
    property    HideReceivedSID: Boolean read GetHideReceivedSID write SetHideReceivedSID;
    property    FontSize: string read GetFontSize write SetFontSize;
    property    HighColor: Boolean read GetHighColor write SetHighColor;
    property    Timestamp: Boolean read GetTimestamp write SetTimestamp;
    property    IncomingConnect: TIncomingConnect read GetIncomingConnect write SetIncomingConnect;
    property    Channels: Integer read GetChannels write SetChannels;
    property    Color [ColorType: TColorType]: TColor read GetColor write SetColor;
    property    MonitorHeight: Integer read GetMonitorHeight write SetMonitorHeight;
    property    InputHeight: Integer read GetInputHeight write SetInputHeight;
    property    ToolbarText: Integer read GetToolbarText write SetToolbarText;
    property    LocalEcho: Boolean read GetLocalEcho write SetLocalEcho;
    property    Dirty: Boolean read GetDirty write SetDirty;
    property    ForceDatabaseCheck: Boolean read GetForceDatabaseCheck write SetForceDatabaseCheck;
    property    UIDestination: String read GetUIDestination write SetUIDestination;
    property    UIPort: String read GetUIPort write SetUIPort;
    property    UIMyCall: String read GetUIMyCall write SetUIMyCall;
    property    ConsoleRows: Integer read GetConsoleRows write SetConsoleRows;

  end;


var
  Config: TConfig;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


uses
  DebOutU;


const
  HKCU = HKEY_CURRENT_USER;
  HKLM = HKEY_LOCAL_MACHINE;
  RootKey = 'Software\Ulf Haueisen\' + ApplicationName;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Import old settings from HKEY_LOCAL_MACHINE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    NewestWriteTime (Reg: TRegistry; const Key: string): TFileTime;
// Latest write time of the key and all its subkeys
var
  Info: TRegKeyInfo;
  KeyNames: TStringList;
  F: TFileTime;
  N: Integer;
begin
  result.dwLowDateTime := 0;
  result.dwHighDateTime := 0;
  KeyNames := TStringList.create;
  try
    if (Reg.OpenKey (Key, false)) then begin
      if (Reg.GetKeyInfo (Info)) then result := Info.FileTime;
      Reg.GetKeyNames (KeyNames);
      Reg.CloseKey;
      for N := 0 to KeyNames.Count - 1 do begin
        F := NewestWriteTime (Reg, Key + '\' + KeyNames[N]);
        if (CompareFileTime (F, result) > 0) then result := F;
      end;
    end;
  finally
    KeyNames.free;
  end;
end;


procedure   CopyBranch (SourceReg: TRegistry; const SourceKey: string; TargetReg: TRegistry; const TargetKey: string);
// Copies values of all types and all subkeys. Values already present in the target remain unchanged.
var
  KeyNames: TStringList;
  B: array of Byte;
  T, L: DWord;
  N: Integer;
begin
  KeyNames := TStringList.create;
  try
    if (SourceReg.OpenKey (SourceKey, false)) then begin
      if (TargetReg.OpenKey (TargetKey, true)) then begin
        SourceReg.GetValueNames (KeyNames);
        for N := 0 to KeyNames.Count - 1 do begin
          if (not TargetReg.ValueExists (KeyNames[N])) then begin
            L := 0;
            if (RegQueryValueEx (SourceReg.CurrentKey, PChar(KeyNames[N]), nil, @T, nil, @L) = ERROR_SUCCESS) then begin
              SetLength (B, L + 1);
              if (RegQueryValueEx (SourceReg.CurrentKey, PChar(KeyNames[N]), nil, @T, @B[0], @L) = ERROR_SUCCESS) then begin
                RegSetValueEx (TargetReg.CurrentKey, PChar(KeyNames[N]), 0, T, @B[0], L);
              end;
            end;
          end;
        end;
        TargetReg.CloseKey;
      end;
      SourceReg.GetKeyNames (KeyNames);
      SourceReg.CloseKey;
      for N := 0 to KeyNames.Count - 1 do begin
        CopyBranch (SourceReg, SourceKey + '\' + KeyNames[N], TargetReg, TargetKey + '\' + KeyNames[N]);
      end;
    end;
  finally
    KeyNames.free;
  end;
end;


procedure   CopyFolder (const SourceFolder, TargetFolder: string);
// Copies all files and subfolders. Files already present in the target remain unchanged.
var
  SR: TSearchRec;
  Q, Z: string;
begin
  Q := IncludeTrailingPathDelimiter (SourceFolder);
  Z := IncludeTrailingPathDelimiter (TargetFolder);
  if (not ForceDirectories (Z)) then begin
    DebOut ('CopyFolder: ' + Z + ' kann nicht angelegt werden');
    exit;
  end;
  if (FindFirst (Q + '*', faAnyFile, SR) = 0) then begin
    try
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then begin
          if ((SR.Attr and faDirectory) <> 0) then begin
            CopyFolder (Q + SR.Name, Z + SR.Name);
          end else if (not FileExists (Z + SR.Name)) then begin
            if (not CopyFile (PChar(Q + SR.Name), PChar(Z + SR.Name), true)) then begin
              DebOut ('CopyFolder: ' + Q + SR.Name + ': ' + SysErrorMessage (GetLastError));
            end;
          end;
        end;
      until (FindNext (SR) <> 0);
    finally
      FindClose (SR);
    end;
  end;
end;


const
  OldSoundsKey = '\Klaenge';  // Name before 3.0, see ImportGermanRegistryNames


procedure   ImportVirtualStoreSounds (Reg: TRegistry);
// Without administrator rights, older versions wrote sound files and sound schemes to the program folder\Sound;
// Windows redirected them to %LOCALAPPDATA%\VirtualStore\<program path without drive>\Sound.
// Paxon now runs without file virtualization (manifest asInvoker) and no longer sees them there.
// Copy the files to the application data folder (existing ones are kept) and rewrite sound entries under the
// Klaenge key that point to a file that is missing in the program folder but was copied.
// Runs before ImportGermanRegistryNames, hence still under the old key name.
// Reg: HKEY_CURRENT_USER, writable.
var
  S, ProgSound, VirtSound, TargetSound, FilePathName, NewOne: string;
  KeyNames: TStringList;
  N: Integer;
begin
  try
    S := SysUtils.GetEnvironmentVariable ('LOCALAPPDATA');
    if (S = '') or (ApplicationDataPath = '') then exit;
    ProgSound := ExtractFilePath (ParamStr (0)) + 'Sound\';
    VirtSound := IncludeTrailingPathDelimiter (S) + 'VirtualStore' +
                 Copy (ProgSound, Length (ExtractFileDrive (ProgSound)) + 1, MaxInt);
    if (not DirectoryExists (VirtSound)) then exit;
    TargetSound := ApplicationDataPath + 'Sound\';
    DebOut ('ImportVirtualStoreSounds: ' + VirtSound + ' -> ' + TargetSound);
    CopyFolder (VirtSound, TargetSound);
    KeyNames := TStringList.create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if (Reg.OpenKey (RootRegKey + OldSoundsKey, false)) then begin
        Reg.GetKeyNames (KeyNames);
        Reg.CloseKey;
      end;
      for N := 0 to KeyNames.Count - 1 do begin
        if (Reg.OpenKey (RootRegKey + OldSoundsKey + '\' + KeyNames[N], false)) then begin
          try
            if (Reg.GetDataType ('SignalWavFile') in [rdString, rdExpandString]) then begin
              FilePathName := Reg.ReadString ('SignalWavFile');
              if (AnsiSameText (Copy (FilePathName, 1, Length (ProgSound)), ProgSound)) and
                 (not FileExists (FilePathName)) then begin
                NewOne := TargetSound + Copy (FilePathName, Length (ProgSound) + 1, MaxInt);
                if (FileExists (NewOne)) then begin
                  Reg.WriteString ('SignalWavFile', NewOne);
                  DebOut ('ImportVirtualStoreSounds: ' + FilePathName + ' -> ' + NewOne);
                end;
              end;
            end;
          finally
            Reg.CloseKey;
          end;
        end;
      end;
    finally
      KeyNames.free;
    end;
  except
    on E: Exception do DebOut ('ImportVirtualStoreSounds: ' + E.Message);
  end;
end;


procedure   ImportHKLMSettings;
// Older versions stored the devices (with saved connections) under HKEY_LOCAL_MACHINE;
// without administrator rights, Windows redirected these writes to the user's VirtualStore.
// Import once into HKEY_CURRENT_USER: first the source with the most recent write time,
// older sources only add what is missing. The old sources are kept.
// At the same time, import the sound files redirected to the VirtualStore.
const
  Marker = 'HKLMImported';
  OldMarker = 'HKLMUebernommen';  // Name before 3.0
  KEY_WOW64_64KEY = $0100;  // not declared in Delphi 7
  VirtualStore = '\Software\Classes\VirtualStore\MACHINE\SOFTWARE\';
  SourceRootKey: array [0..2] of HKEY = (HKEY_CURRENT_USER, HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE);
  SourceKey: array [0..2] of string = (
    VirtualStore + 'Wow6432Node\Ulf Haueisen\' + ApplicationName,
    VirtualStore + 'Ulf Haueisen\' + ApplicationName,
    RootRegKey);
  // On Vista/2008 x64, WOW64 redirects HKCU\Software\Classes for 32-bit processes; the VirtualStore
  // is in the 64-bit view. Under HKLM, the redirected (32-bit) view is the right one.
  SourceAccess: array [0..2] of LongWord = (KEY_READ or KEY_WOW64_64KEY, KEY_READ or KEY_WOW64_64KEY, KEY_READ);
var
  SourceReg, TargetReg: TRegistry;
  TimeValue: array [0..2] of TFileTime;
  KeyPresent: array [0..2] of Boolean;
  I, N: Integer;
begin
  SourceReg := TRegistry.create (KEY_READ);
  TargetReg := TRegistry.create (KEY_READ or KEY_WRITE);
  try
    try
      TargetReg.RootKey := HKEY_CURRENT_USER;
      if (TargetReg.OpenKey (RootRegKey, true)) and (not TargetReg.ValueExists (Marker))
      and (not TargetReg.ValueExists (OldMarker)) then begin
        TargetReg.CloseKey;
        for N := 0 to High (SourceKey) do begin
          SourceReg.RootKey := SourceRootKey[N];
          SourceReg.Access := SourceAccess[N];
          // Not KeyExists: it sets its own access rights and loses KEY_WOW64_64KEY
          KeyPresent[N] := SourceReg.OpenKey (SourceKey[N], false);
          if (KeyPresent[N]) then begin
            SourceReg.CloseKey;
            TimeValue[N] := NewestWriteTime (SourceReg, SourceKey[N]);
          end;
        end;
        repeat
          I := -1;
          for N := 0 to High (SourceKey) do begin
            if (KeyPresent[N]) and ((I < 0) or (CompareFileTime (TimeValue[N], TimeValue[I]) > 0)) then I := N;
          end;
          if (I >= 0) then begin
            DebOut ('ImportHKLMSettings: ' + SourceKey[I]);
            SourceReg.RootKey := SourceRootKey[I];
            SourceReg.Access := SourceAccess[I];
            CopyBranch (SourceReg, SourceKey[I], TargetReg, RootRegKey);
            KeyPresent[I] := false;
          end;
        until (I < 0);
        ImportVirtualStoreSounds (TargetReg);
        TargetReg.RootKey := HKEY_CURRENT_USER;
        if (TargetReg.OpenKey (RootRegKey, true)) then begin
          TargetReg.WriteString (Marker, '1');
        end;
      end;
      TargetReg.CloseKey;
    except
      on E: Exception do DebOut ('ImportHKLMSettings: ' + E.Message);
    end;
  finally
    TargetReg.free;
    SourceReg.free;
  end;
end;


procedure   CopyValue (Reg: TRegistry; const OldName, NewName: string; DeleteOld: Boolean);
// Copies a value of any type in the open key under a new name; an existing
// value with the new name remains unchanged.
var
  B: array of Byte;
  T, L: DWord;
begin
  if (not Reg.ValueExists (OldName)) then exit;
  if (not Reg.ValueExists (NewName)) then begin
    L := 0;
    if (RegQueryValueEx (Reg.CurrentKey, PChar(OldName), nil, @T, nil, @L) = ERROR_SUCCESS) then begin
      SetLength (B, L + 1);
      if (RegQueryValueEx (Reg.CurrentKey, PChar(OldName), nil, @T, @B[0], @L) = ERROR_SUCCESS) then begin
        RegSetValueEx (Reg.CurrentKey, PChar(NewName), 0, T, @B[0], L);
      end;
    end;
  end;
  if (DeleteOld) then Reg.DeleteValue (OldName);
end;


procedure   ImportGermanRegistryNames;
// Before 3.0, some keys and values had German names. Copy them once to the English names;
// the old entries are kept so that older versions still find their settings.
// In the copied branches, rename the German value names.
const
  Marker = 'GermanNamesImported';
  OldKey: array [0..8] of string = (
    '\Geraete', '\Windows\GeraeteStatus', OldSoundsKey, '\Ordner', '\Texte', '\Verlauf',
    '\Vorlagen\Senden Text Vorher', '\Vorlagen\Senden Text Nachher', '\Eigene Rufzeichen');
  NewKey: array [0..8] of string = (
    '\Devices', '\Windows\DeviceStatus', '\Sounds', '\Folders', '\Texts', '\History',
    '\Templates\SendTextBefore', '\Templates\SendTextAfter', '\MyCalls');
var
  SourceReg, Reg: TRegistry;
  KeyNames: TStringList;
  N: Integer;
begin
  SourceReg := TRegistry.create (KEY_READ);
  Reg := TRegistry.create (KEY_READ or KEY_WRITE);
  KeyNames := TStringList.create;
  try
    try
      SourceReg.RootKey := HKEY_CURRENT_USER;
      Reg.RootKey := HKEY_CURRENT_USER;
      if (Reg.OpenKey (RootRegKey, true)) and (not Reg.ValueExists (Marker)) then begin
        CopyValue (Reg, 'Sprache', 'Language', false);
        Reg.CloseKey;
        for N := 0 to High (OldKey) do begin
          CopyBranch (SourceReg, RootRegKey + OldKey[N], Reg, RootRegKey + NewKey[N]);
        end;
        if (Reg.OpenKey (RootRegKey + '\History', false)) then begin
          CopyValue (Reg, 'Eigenes Rufzeichen', 'OwnCallsign', true);
          CopyValue (Reg, 'Senden Text Vorher', 'SendTextBefore', true);
          CopyValue (Reg, 'Senden Text Nachher', 'SendTextAfter', true);
          Reg.CloseKey;
        end;
        if (Reg.OpenKey (RootRegKey + '\Folders', false)) then begin
          CopyValue (Reg, 'Empfang', 'Receive', true);
          Reg.CloseKey;
        end;
        if (Reg.OpenKey (RootRegKey + '\Devices', false)) then begin
          Reg.GetKeyNames (KeyNames);
          Reg.CloseKey;
        end;
        for N := 0 to KeyNames.Count - 1 do begin
          if (Reg.OpenKey (RootRegKey + '\Devices\' + KeyNames[N], false)) then begin
            CopyValue (Reg, 'Anschluss', 'ComPort', true);
            Reg.CloseKey;
          end;
        end;
        if (Reg.OpenKey (RootRegKey, true)) then begin
          Reg.WriteString (Marker, '1');
        end;
      end;
      Reg.CloseKey;
    except
      on E: Exception do DebOut ('ImportGermanRegistryNames: ' + E.Message);
    end;
  finally
    KeyNames.free;
    Reg.free;
    SourceReg.free;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConfig.AfterConstruction;
var
  S: string;
  M: Cardinal;
begin

  inherited;

  FCriticalSection := TCriticalSection.Create;
  Registry := TRegistry.create (KEY_READ or KEY_WRITE);

  ImportHKLMSettings;
  ImportGermanRegistryNames;

  M := MonitorStatus or MonitorInformation or MonitorInformationContent or MonitorUnproto or MonitorLocal or MonitorPort;
  S := ReadString (HKCU, '', 'Monitor');
  FMonitor := StrToIntDef (S, M);
  if (FMonitor = 1) then FMonitor := M;

  FFontSize := '';

end;


procedure   TConfig.BeforeDestruction;
begin
  WriteString (HKCU, '', 'Monitor', IntToStr (FMonitor));
  Registry.free;
  FCriticalSection.Free;
  inherited;
end;


function    TConfig.ValueExists (Root: DWord; const Key: string; const ValueName: string): boolean;
begin
  Registry.RootKey := Root;
  Registry.OpenKey (RootRegKey + Key, true);
  result := Registry.ValueExists (ValueName);
  Registry.CloseKey;
end;


function    TConfig.ReadString (Root: DWord; const Key: string; const ValueName: string): string;
begin
  result := '';
  Registry.RootKey := Root;
  if (Registry.OpenKey (RootRegKey + Key, true)) then begin
    try
      result := Registry.ReadString (ValueName);
    except
    end;
    Registry.CloseKey;
  end;
end;


procedure   TConfig.WriteString (Root: DWord; const Key: string; const ValueName: string; const Value: string);
begin
  Registry.RootKey := Root;
  if (Registry.OpenKey (RootRegKey + Key, true)) then begin
    try
      Registry.WriteString (ValueName, Value);
    except
    end;
    Registry.CloseKey;
  end;
end;


function    TConfig.ReadBoolean (Root: DWord; const Key: string; const ValueName: string; DefaultValue: Boolean = false): Boolean;
var
  S: string;
begin
  S := ReadString (Root, Key, ValueName);
  if (S = '') then begin
    Result := DefaultValue;
  end else begin
    Result := (S = '1');
  end;
end;


procedure   TConfig.WriteBoolean (Root: DWord; const Key: string; const ValueName: string; Value: Boolean);
var
  S: string;
begin
  if (Value) then S := '1' else S := '0';
  WriteString (Root, Key, ValueName, S);
end;


function    TConfig.ReadInteger (Root: DWord; const Key: String; const ValueName: string; DefaultValue: Integer): Integer;
begin
  try
    result := ReadInteger (Root, Key, ValueName);
  except
    result := DefaultValue;
  end;
end;


function    TConfig.ReadInteger (Root: DWord; const Key: String; const ValueName: string): Integer;
begin
  Registry.RootKey := Root;
  if (Registry.OpenKey (RootRegKey + Key, true)) then begin
    result := Registry.ReadInteger (ValueName);
    Registry.CloseKey;
  end else begin
    raise ERegistryException.Create ('Can not open key');
  end;
end;


procedure   TConfig.WriteInteger (Root: DWord; const Key: String; const ValueName: string; Value: Integer);
begin
  Registry.RootKey := Root;
  if (Registry.OpenKey (RootRegKey + Key, true)) then begin
    Registry.WriteInteger (ValueName, Value);
    Registry.CloseKey;
  end else begin
    raise ERegistryException.Create ('Can not open key');
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#


function    TConfig.GetSplashScreen: Boolean;
begin
  FCriticalSection.Enter;
  try
    result := ReadBoolean (HKCU, '', 'SplashScreen', true);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetSplashScreen (Value: Boolean);
begin
  FCriticalSection.Enter;
  try
    WriteBoolean (HKCU, '', 'SplashScreen', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetMonitor: Cardinal;
begin
  FCriticalSection.Enter;
  try
    Result := FMonitor;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetMonitor (Value: Cardinal);
begin
  FCriticalSection.Enter;
  try
    if (Value <> FMonitor) then begin
      FMonitor := Value;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetPGPCollectPublicKeys: Boolean;
begin
  FCriticalSection.Enter;
  try
    result := ReadBoolean (HKCU, '\PGP', 'CollectPublicKeys', true);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetPGPCollectPublicKeys (const Value: Boolean);
begin
  FCriticalSection.Enter;
  try
    WriteBoolean (HKCU, '\PGP', 'CollectPublicKeys', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetPGPDetailedOutput: Boolean;
begin
  FCriticalSection.Enter;
  try
    result := ReadBoolean (HKCU, '\PGP', 'DetailedOutput', false);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetPGPDetailedOutput (const Value: Boolean);
begin
  FCriticalSection.Enter;
  try
    WriteBoolean (HKCU, '\PGP', 'DetailedOutput', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetPGPComment: string;
begin
  FCriticalSection.Enter;
  try
    result := ReadString (HKCU, '\PGP', 'Comment');
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetPGPComment (const Value: string);
begin
  FCriticalSection.Enter;
  try
    WriteString (HKCU, '\PGP', 'Comment', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetSendSID: Boolean;
begin
  FCriticalSection.Enter;
  try
    result := ReadBoolean (HKCU, '\SID', 'SendSID', true);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetSendSID (const Value: Boolean);
begin
  FCriticalSection.Enter;
  try
    WriteBoolean (HKCU, '\SID', 'SendSID', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetHideSentSID: Boolean;
begin
  FCriticalSection.Enter;
  try
    result := ReadBoolean (HKCU, '\SID', 'HideSentSID', true);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetHideSentSID (const Value: Boolean);
begin
  FCriticalSection.Enter;
  try
    WriteBoolean (HKCU, '\SID', 'HideSentSID', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetHideReceivedSID: Boolean;
begin
  FCriticalSection.Enter;
  try
    result := ReadBoolean (HKCU, '\SID', 'HideReceivedSID', true);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetHideReceivedSID (const Value: Boolean);
begin
  FCriticalSection.Enter;
  try
    WriteBoolean (HKCU, '\SID', 'HideReceivedSID', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetFontSize: string;
const
  Fonts: array[1..6] of string = ('07x09', '08x09', '08x12', '08x13', '08x15', '10x18');
var
  N: Integer;
  B: Boolean;
begin
  FCriticalSection.Enter;
  try
    if (FFontSize = '') then begin
      FFontSize := ReadString (HKCU, '', 'Font');
      for N := Low(Fonts) to High (Fonts) do begin
        B := false;
        if (FFontSize = Fonts[N]) then begin
          B := true;
          break;
        end;
      end;
      if (not B) then begin
        FFontSize := '08x12';
      end;
    end;
    result := FFontSize;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetFontSize (const Value: string);
begin
  FCriticalSection.Enter;
  try
    FFontSize := Value;
    WriteString (HKCU, '', 'Font', FFontSize);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetHighColor: Boolean;
begin
  result := ReadBoolean (HKCU, '', 'HighColor', GlobalU.HighColor);
end;


procedure   TConfig.SetHighColor (const Value: Boolean);
begin
  WriteBoolean (HKCU, '', 'HighColor', Value);
end;


function    TConfig.GetTimestamp: Boolean;
begin
  result := ReadBoolean (HKCU, '', 'Timestamp', false);
end;


procedure   TConfig.SetTimestamp (const Value: Boolean);
begin
  WriteBoolean (HKCU, '', 'Timestamp', Value);
end;


function    TConfig.GetIncomingConnect: TIncomingConnect;
var
  S: string;
begin
  FCriticalSection.Enter;
  try
    S := ReadString (HKCU, '', 'IncomingConnects');
  finally
    FCriticalSection.Leave;
  end;
  if (S = '2') then begin
    result := ic_ignore;
  end else if (S = '3') then begin
    result := ic_busy;
  end else begin
    result := ic_accept;
  end;
end;


procedure   TConfig.SetIncomingConnect (const Value: TIncomingConnect);
var
  S: string;
begin
  case Value of
    ic_accept: S := '1';
    ic_ignore: S := '2';
    ic_busy:   S := '3';
    else       S := '';
  end;
  FCriticalSection.Enter;
  try
    WriteString (HKCU, '', 'IncomingConnects', S);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetChannels: Integer;
begin
  result := ReadInteger (HKCU, '', 'Channels', 8);
end;


procedure   TConfig.SetChannels (const Value: Integer);
begin
  WriteInteger (HKCU, '', 'Channels', Value);
end;


function    TConfig.GetColor (ColorType: TColorType): TColor;
var
  ValueName: String;
begin
  ValueName := Format ('%2.2d', [Ord (ColorType)]);
  if (ValueExists (HKCU, '\Colors', ValueName)) then begin
    result := TColor (ReadInteger (HKCU, '\Colors', ValueName, DefaultColors [ColorType]));
  end else begin
    result := DefaultColors [ColorType];
  end;
end;


procedure   TConfig.SetColor (ColorType: TColorType; const Value: TColor);
var
  ValueName: String;
begin
  ValueName := Format ('%2.2d', [Ord (ColorType)]);
  WriteInteger (HKCU, '\Colors', ValueName, Integer(Value));
end;


function    TConfig.GetInputHeight: Integer;
begin
  result := ReadInteger (HKCU, '\Windows\Main', 'InputHeight', 64);
end;


procedure   TConfig.SetInputHeight (const Value: Integer);
begin
  WriteInteger (HKCU, '\Windows\Main', 'InputHeight', Value);
end;


function    TConfig.GetMonitorHeight: Integer;
begin
  result := ReadInteger (HKCU, '\Windows\Main', 'MonitorHeight', 64);
end;


procedure   TConfig.SetMonitorHeight (const Value: Integer);
begin
  WriteInteger (HKCU, '\Windows\Main', 'MonitorHeight', Value);
end;


function    TConfig.GetToolbarText: Integer;
begin
  result := ReadInteger (HKCU, '\Toolbar', 'Text', 1);
end;


procedure   TConfig.SetToolbarText(const Value: Integer);
begin
  WriteInteger (HKCU, '\Toolbar', 'Text', Value);
end;


function    TConfig.GetLocalEcho: Boolean;
begin
  result := ReadBoolean (HKCU, '', 'LocalEcho', true);
end;


procedure   TConfig.SetLocalEcho (const Value: Boolean);
begin
  WriteBoolean (HKCU, '', 'LocalEcho', Value);
end;


function    TConfig.GetDirty: Boolean;
begin
  result := ReadBoolean (HKCU, '', 'Dirty', false);
end;


procedure   TConfig.SetDirty (const Value: Boolean);
begin
  WriteBoolean (HKCU, '', 'Dirty', Value);
end;


function    TConfig.GetForceDatabaseCheck: Boolean;
begin
  result := ReadBoolean (HKCU, '', 'ForceDatabaseCheck', false);
end;


procedure   TConfig.SetForceDatabaseCheck (const Value: Boolean);
begin
  WriteBoolean (HKCU, '', 'ForceDatabaseCheck', Value);
end;


function    TConfig.GetUIDestination: string;
begin
  FCriticalSection.Enter;
  try
    result := ReadString (HKCU, '\UI', 'Destination');
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetUIDestination (const Value: string);
begin
  FCriticalSection.Enter;
  try
    WriteString (HKCU, '\UI', 'Destination', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetUIPort: string;
begin
  FCriticalSection.Enter;
  try
    result := ReadString (HKCU, '\UI', 'Port');
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetUIPort (const Value: string);
begin
  FCriticalSection.Enter;
  try
    WriteString (HKCU, '\UI', 'Port', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConfig.GetUIMycall: string;
begin
  FCriticalSection.Enter;
  try
    result := ReadString (HKCU, '\UI', 'MyCall');
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConfig.SetUIMycall (const Value: string);
begin
  FCriticalSection.Enter;
  try
    WriteString (HKCU, '\UI', 'MyCall', Value);
  finally
    FCriticalSection.Leave;
  end;
end;


function TConfig.GetConsoleRows: Integer;
begin
  result := ReadInteger (HKCU, '', 'ConsoleRows', 1250);
end;


procedure TConfig.SetConsoleRows (const Value: Integer);
begin
  WriteInteger (HKCU, '', 'ConsoleRows', Value);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

