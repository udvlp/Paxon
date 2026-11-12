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


unit GlobalU;


interface


uses
  Windows, Classes, SysUtils, Messages, SyncObjs, Forms, ShellAPI, ActiveX;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  ApplicationName = 'Paxon';
  WindowCaptionName = 'Paxon Terminal';

  ConsoleFontName = 'Paxon';

  RootRegKey = '\Software\Ulf Haueisen\' + ApplicationName;

  RemotePrompt: String = '<' + ApplicationName + '>: ';

  crAppstarting = 1;

  PackLen = 256;

  IncompleteFiles = 'Incomplete Files\';

  faReadOnly  = $00000001;
  faHidden    = $00000002;
  faSysFile   = $00000004;
  faVolumeID  = $00000008;
  faDirectory = $00000010;
  faArchive   = $00000020;
  faAnyFile   = $0000003F;


var
  Version: String;
  VersionIsPrivate: Boolean;
  DesktopWindow: HWnd;
  ApplicationDataPath: String;
  IncompleteFilesPath: string;
  HighColor: Boolean;   // at least 16-bit color depth
  QuitEvent: TSimpleEvent;


type
  TStationType = (
    st_first,
    st_unknown,
    st_digi,
    st_box,
    st_convers,
    st_terminal,
    st_cluster,
    st_last
  );


type
  TCTextRec = record
    Key: String;
    StationType: TStationType;
  end;


const
  CTextKey: Array[0..38] of TCTextRec = (
    (Key: 'DieBox'; StationType: st_box),
    (Key: 'BayBox'; StationType: st_box),
    (Key: 'OpenBCM'; StationType: st_box),
    (Key: 'BayCom-Mailbox'; StationType: st_box),
    (Key: 'TheBox'; StationType: st_box),
    (Key: 'BBS'; StationType: st_box),
    (Key: 'DVMS '; StationType: st_box),
    (Key: '[FBB'; StationType: st_box),
    (Key: '[DP-'; StationType: st_box),
    (Key: '3NET '; StationType: st_digi),
    (Key: '(3)NET '; StationType: st_digi),
    (Key: 'XNet'; StationType: st_digi),
    (Key: '(X)Net'; StationType: st_digi),
    (Key: 'X-Net'; StationType: st_digi),
    (Key: 'DAMA'; StationType: st_digi),
    (Key: 'DosNET'; StationType: st_digi),
    (Key: 'LinuxNet'; StationType: st_digi),
    (Key: 'PCNet'; StationType: st_digi),
    (Key: '(PC)Net'; StationType: st_digi),
    (Key: 'Digi '; StationType: st_digi),
    (Key: 'TNN '; StationType: st_digi),
    (Key: 'RMNC/FlexNet'; StationType: st_digi),
    (Key: 'PC/FlexNet'; StationType: st_digi),
    (Key: 'TheNetNode'; StationType: st_digi),
    (Key: 'SNET'; StationType: st_digi),
    (Key: 'Digiware'; StationType: st_digi),
    (Key: 'NetCHL'; StationType: st_digi),
    (Key: 'BPQ'; StationType: st_digi),
    (Key: 'TheNet'; StationType: st_digi),
    (Key: 'SuperVozelj'; StationType: st_digi),
    (Key: 'ItaNet'; StationType: st_digi),
    (Key: '[TNOS'; StationType: st_digi),
    (Key: 'Node'; StationType: st_digi),
    (Key: 'network'; StationType: st_digi),
    (Key: 'Interlink'; StationType: st_digi),
    (Key: 'FALCon/DigiWare'; StationType: st_digi),
    (Key: 'Logins:'; StationType: st_box),
    (Key: 'Convers'; StationType: st_convers),
    (Key: 'Mailbox'; StationType: st_box)
  );


type
  PaxonException = class (Exception)
    constructor Create (Obj: TObject; const Method: string; const Text: string); overload;
    constructor Create (Obj: TObject; Method: string; Text: string; const Args: array of const); overload;
  end;


function    WaitForMultipleObjects (const Objects: Array of Integer; Timeout: Cardinal): Integer;
function    Recycle (FileName: String): Boolean;
function    UniqueFilename (Filename: String): String;
procedure   ProcessPaintMessages;
function    GetLastErrorText: String; overload;
function    GetLastErrorText (F: DWord): String; overload;
function    DateTimeToUnixTime (DT: TDateTime): Integer;
function    UnixTimeToDateTime (UT: Integer): TDateTime;
function    SetScrollLock (aValue: Boolean): boolean;
function    ExtractSSID (Call: string): Integer;
function    StripSSID (Call: string): string;
function    MoveFileUlf (ExistingFileName: string; var NewFileName: string; RenameUnique: Boolean): Boolean;
function    WrapTextUlf (const Line, BreakStr: string; BreakChars: TSysCharSet; MaxCol: Integer): string;
function    CreateIncompleteFile: String; overload;
function    CreateIncompleteFile (MD5: String): String; overload;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  Registry, ComCtrls, DebOutU, MD5U, ShlObj;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   InitVersion;
var
  B, P: PChar;
  L: integer;
  S: String;

begin

  Version := '?.?.?';

  VersionIsPrivate := true;
  GetMem (B, 4096);
  try

    if GetFileVersionInfo (PChar(Forms.Application.ExeName), 0, 4096, B) then begin

      VerQueryValue (B, '\', Pointer(P), Cardinal(L));

      with PVSFixedFileInfo(P)^ do begin
        Version := Format ('%d.%d.%d', [dwFileVersionMS shr 16 and $FFFF, dwFileVersionMS and $FFFF, dwFileVersionLS and $FFFF]);
        VersionIsPrivate := (dwFileFlags and VS_FF_PRIVATEBUILD) <> 0;
      end;

      if (VerQueryValue (B, '\StringFileInfo\040704E4\SpecialBuild', Pointer(P), Cardinal(L))) then begin
        if (assigned (P)) and (L > 0) then begin
          if (P[L-1] = #0) then dec (L);
          SetString (S, P, L);
          if (L > 0) then begin
            SetLength (S, StrLen(PChar(S)));
            if (not (S[1] in ['-', '/'])) then Version := Version + ' ';
            Version := Version + S;
          end;
        end;
      end;

    end;

  finally
    FreeMem (B);
  end;

end;


function    WaitForMultipleObjects (const Objects: Array of Integer; Timeout: Cardinal): Integer;
begin
  Result := Windows.WaitForMultipleObjects (High (Objects) - Low (Objects) + 1, PWOHandleArray(@Objects), false, Timeout);
end;


function    Recycle (FileName: String): Boolean;
var
  FileOp: TSHFileOpStruct;
begin
  FillChar (FileOp, SizeOf (FileOp), 0 );
  with FileOp do begin
    wFunc  := FO_DELETE;
    pFrom  := PChar(FileName + #0 + #0);
    pTo    := nil;
    fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT;
  end;
  Result := (ShFileOperation (FileOp) = 0);
end;


function    UniqueFilename (Filename: String): String;
var
  I: Integer;
  S, T, U: String;
begin
  if (FileExists (FileName)) then begin
    I := 1;
    while (true) do begin
      T := ExtractFileName (FileName);
      U := ExtractFileExt (FileName);
      T := Copy (T, 1, Length (T) - Length (U));
      S := ExtractFilePath (FileName) + T + ' (' + IntToStr (I) + ')' + U;
      if (not FileExists (S)) then break;
      Inc (I);
    end;
    result := S;
  end else begin
    result := Filename;
  end;
end;


procedure   ProcessPaintMessages;
var
  Msg: TMsg;
begin
  while PeekMessage (Msg, 0, wm_Paint, wm_Paint, pm_NoRemove) do begin
    case Integer(GetMessage(Msg, 0, wm_Paint, wm_Paint)) of
      -1: Exit;
      0: begin PostQuitMessage(Msg.WParam); Exit; end;
    end;
    DispatchMessage(Msg);
  end;
end;


function    GetLastErrorText: String; overload;
begin
  result := GetLastErrorText (GetLastError);
end;


function    GetLastErrorText (F: DWord): String; overload;
var
  S: Array[0..250] of Char;
begin
  if FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_MAX_WIDTH_MASK, nil, F, 0, S, 100, nil) = 0 then begin
    StrPCopy (S, 'Nr. ' + IntToStr (F));
  end;
  result := String (S);
end;


const
  UnixStartDate: TDateTime = 25569.0;

function    DateTimeToUnixTime (DT: TDateTime): Integer;
begin
  result := Round ((DT - UnixStartDate) * 86400);
end;


function    UnixTimeToDateTime (UT: Integer): TDateTime;
begin
  result := (UT / 86400) + UnixStartDate;
end;


function    SetScrollLock (aValue: Boolean): boolean;
var
  A: TKeyBoardState;
begin
  GetKeyBoardState (A);
  Result := A[vk_scroll] <> 0;
  if (aValue) then A[vk_scroll] := 255 else A[vk_scroll] := 0;
  SetKeyBoardState (A);
end;


function    ExtractSSID (Call: String): Integer;
var
  I: Integer;
begin
  I := Pos ('-', Call);
  if I > 0 then begin
    result := StrToIntDef (copy (Call, i+1, MaxInt), 0)
  end else begin
    result := 0;
  end;
end;


function    StripSSID (Call: string): string;
var
  I: Integer;
begin
  I := Pos ('-', Call);
  if (I > 0) then begin
    result := Copy (Call, 1, I - 1);
  end else begin
    result := Call;
  end;
end;


procedure   InitApplicationDataPath;
resourcestring
  SApplicationDataPathError = 'Fehler beim Erstellen des Ordners Anwendungsdaten.';

const
  AppDataKey = '\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders';
  AppDataValue = 'AppData';

var
  Registry: TRegistry;
  I, L: Integer;
  S: String;

begin

  Registry := TRegistry.create (KEY_READ or KEY_WRITE);

  try

    ApplicationDataPath := '';
    Registry.RootKey := HKEY_CURRENT_USER;

    if (Registry.OpenKey (AppDataKey, true)) then begin

      try
        try

          try
            ApplicationDataPath := Registry.ReadString (AppDataValue);
          except
            ApplicationDataPath := '';
          end;

          if (ApplicationDataPath = '') then begin
            SetLength (ApplicationDataPath, 256);
            SetLength (ApplicationDataPath, GetWindowsDirectory (PChar(ApplicationDataPath), 255));
            I := GetSystemDefaultLangID;
            if ((I and $FF) = $07) then begin
              S := 'Anwendungsdaten';
            end else begin
              S := 'Application Data';
            end;
            ApplicationDataPath := IncludeTrailingPathDelimiter (ApplicationDataPath) + S;
            Registry.WriteString (AppDataValue, ApplicationDataPath);
            ApplicationDataPath := Registry.ReadString (AppDataValue);
          end;

          L := Length (ApplicationDataPath);
          if (L > 0) then begin
            if ApplicationDataPath[L] <> '\' then ApplicationDataPath := ApplicationDataPath + '\';
            ApplicationDataPath := ApplicationDataPath + 'Ulf Haueisen\' + ApplicationName + '\';
          end;

        except
        end;

      finally
        Registry.CloseKey;
      end;

      if (not (ForceDirectories (ApplicationDataPath))) then begin
        MessageBox (GetDesktopWindow, PChar(SApplicationDataPathError), ApplicationName, MB_OK or MB_ICONSTOP);
        Halt (4);
      end;

    end;

  finally
    Registry.free;
  end;

end;


function    MoveFileUlf (ExistingFileName: string; var NewFileName: string; RenameUnique: Boolean): Boolean;
// If RenameUnique = false, the function fails if the target file already exists
const
  DebPrefix = 'MoveFileUlf: ';
var
  B: Boolean;
  E: DWord;
  S: string;
begin
  result := false;
  DebOut (DebPrefix + 'begin...');
  DebOut (DebPrefix + 'Quelle: ' + ExistingFileName);
  DebOut (DebPrefix + 'Ziel (ursprünglich): ' + NewFileName);
  if (Length (ExistingFileName) >= 0) and (Length (NewFileName) >= 0) then begin
    while true do begin
      if RenameUnique then begin
        S := UniqueFileName (NewFileName);
      end else begin
        S := NewFileName;
      end;
      B := MoveFile (PChar(ExistingFileName), PChar(S));
      if (B) then begin
        NewFileName := S;
        DebOut (DebPrefix + 'Ziel (endgültig): ' + NewFileName);
        result := true;
        break;
      end else begin
        E := GetLastError;
        DebOut (DebPrefix + 'Fehler: ' + IntToStr(E) + ', ' + GetLastErrorText (E));
        if (E = ERROR_ALREADY_EXISTS) or (E = ERROR_FILE_EXISTS) then begin
          if not RenameUnique then begin
            break;
          end;
        end else begin
          DebOut (DebPrefix + 'Unbekannter Fehler, Exit...');
          break;
        end;
      end;
    end;
  end else begin
    DebOut (DebPrefix + 'Quell- oder Zieldateiname leer...');
  end;
  DebOut (DebPrefix + 'end.');
end;


function    WrapTextUlf (const Line, BreakStr: string; BreakChars: TSysCharSet; MaxCol: Integer): string;
var
  Col, Pos: Integer;
  LinePos, LineLen: Integer;
  BreakPos: Integer;
  QuoteChar, CurChar: Char;
begin
  Col := 1;
  Pos := 1;
  LinePos := 1;
  BreakPos := 0;
  QuoteChar := ' ';
  LineLen := Length (Line);
  if (BreakChars = []) then BreakChars := [#13, #10, ' ', '.', ',', '-'];
  Result := '';
  while (Pos <= LineLen) do begin
    CurChar := Line[Pos];
    if CurChar in LeadBytes then begin
      Inc (Pos);
      Inc (Col);
    end else
      if (CurChar in BreakChars) then begin
        if QuoteChar = ' ' then BreakPos := Pos
      end;
    Inc (Pos);
    Inc (Col);
    if ((Col > MaxCol) and (BreakPos > LinePos)) then begin
      Col := Pos - BreakPos;
      Result := Result + Copy (Line, LinePos, BreakPos - LinePos + 1);
      while (Pos <= LineLen) and (Line[Pos] in BreakChars) do Inc (Pos);
      if (Pos < LineLen) then begin
        Result := Result + BreakStr;
      end;
      Inc (BreakPos);
      LinePos := BreakPos;
    end;
  end;
  Result := Result + Copy (Line, LinePos, MaxInt);
end;


function    CreateIncompleteFile (MD5: String): String;
const
  DebPrefix = 'CreateIncompleteFile: ';

var
  Path, S: String;
  H: THandle;

begin

  DebOut (DebPrefix + 'begin...');

  Path := ApplicationDataPath + IncompleteFiles;
  ForceDirectories (Path);

  result := '';

  S := Path + MD5 + '.pxf';

  DebOut (DebPrefix + S);

  H := CreateFile (PChar(S), GENERIC_READ or GENERIC_WRITE, 0, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
  if (H <> INVALID_HANDLE_VALUE) then begin
    CloseHandle (H);
    result := S;
  end;

  DebOut (DebPrefix + 'end.');

end;


function    CreateIncompleteFile: String;
const
  DebPrefix = 'CreateIncompleteFile: ';

var
  GUID: TGUID;
  Path, S: String;
  H: THandle;
  N: Integer;

begin

  DebOut (DebPrefix + 'begin...');

  Path := ApplicationDataPath + IncompleteFiles;
  ForceDirectories (Path);

  result := '';

  for N := 1 to 10 do begin

    CoCreateGuid (GUID);
    S := Path + GetMD5 (@GUID, sizeof (GUID)) + '.pxf';

    DebOut (DebPrefix + S);

    H := CreateFile (PChar(S), GENERIC_READ or GENERIC_WRITE, 0, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
    if (H <> INVALID_HANDLE_VALUE) then begin
      CloseHandle (H);
      result := S;
      break;
    end;

  end;

  DebOut (DebPrefix + 'end.');

end;


procedure   InitHighColor;
var
  DC: HDC;
  I: Integer;
begin
  DC := GetDC (0);
  try
    I := GetDeviceCaps (DC, BITSPIXEL);
  finally
    ReleaseDC (0, DC);
  end;
  HighColor := (I >= 16);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor PaxonException.Create (Obj: TObject; const Method, Text: string);
var
  S: String;
begin
  S := Obj.ClassName + '.' + Method;
  if (Text <> '') then S := S + ': ' + Text;
  DebOut ('EXCEPTION: ' + S);
  inherited Create (S);
end;


constructor PaxonException.Create (Obj: TObject; Method, Text: string; const Args: array of const);
begin
  Create (Obj, Method, Format (Text, Args));
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  SetErrorMode (SEM_FAILCRITICALERRORS or SEM_NOOPENFILEERRORBOX);
  Set8087CW ($133F);
  DecimalSeparator := '.';
  QuitEvent := TSimpleEvent.create;
  InitVersion;
  InitApplicationDataPath;
  InitHighColor;
  DesktopWindow := GetDesktopWindow;
  Screen.Cursors[crAppstarting] := LoadCursor (0, IDC_APPSTARTING);

finalization

  // QuitEvent stays until the process ends: if Paxon ends via Halt before Sounds has been freed,
  // the sound thread is still waiting for it.

end.

