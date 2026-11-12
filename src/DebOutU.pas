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


unit DebOutU;


interface


uses
  Windows, Classes, SysUtils, Messages, SyncObjs,
  Forms;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   DebOut (Text: string); overload;
procedure   DebOut (Text: string; const Args: array of const); overload;
procedure   DebOut (Obj: TObject; Text: string); overload;
procedure   DebOut (Obj: TObject; Text: string; const Args: array of const); overload;
procedure   DebOut (Obj: TObject; Method: string; Text: string); overload;
procedure   DebOut (Obj: TObject; Method: string; Text: string; const Args: array of const); overload;


var
  DeboutHandle: THandle;
  DeboutOrigin: Cardinal;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// DebOut only sends if PAXON_DEBUG is defined at compile time (e.g. -DPAXON_DEBUG).
// In the shipped program DebOut stays silent, because any window named "Paxon DebugMonitor"
// could read the output via WM_COPYDATA.


const
  wm_DebugMonitor = wm_user + $4091;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   InitDebug;
begin
{$IFDEF PAXON_DEBUG}
  DeboutHandle := FindWindow (nil, 'Paxon DebugMonitor');
  if (DeboutHandle <> 0) then begin
    SendMessage (DeboutHandle, WM_DEBUGMONITOR, 1, 0);
  end;
  DeboutOrigin := GetTickCount;
  DebOut (FormatDateTime ('dddddd tt', Now));
{$ELSE}
  DeboutHandle := 0;
  DeboutOrigin := 0;
{$ENDIF}
end;


procedure   Debout (Text: String);
{$IFDEF PAXON_DEBUG}
var
  CopyDataStruct: TCopyDataStruct;
  I, L: Integer;
  T, U: String;
  D: DWord;
{$ENDIF}
begin
{$IFDEF PAXON_DEBUG}

  if (DeboutHandle = 0) then exit;

  L := Length (Text);
  if (L > 0) then begin
    if (Text[L] = #10) then begin
      Delete (Text, L, 1);
      L := Length (Text);
    end;
    if (L = 0) then begin
      Text := #13;
    end else if (Text[L] <> #13) then begin
      Text := Text + #13;
    end;
  end else begin
    Text := #13;
  end;

  if (Text <> #13) then begin
    I := GetTickCount - DeboutOrigin;
    D := GetCurrentThreadID;
    if (D = MainThreadID) then U := '  main  ' else U := IntToHex (D, 8);
    T := Format ('%5u.%.3u [%8s] ', [I div 1000, I mod 1000, U]) + Text;
  end else begin
    T := #13;
  end;

  with CopyDataStruct do begin
    dwData := 0;
    cbData := Length (T);
    lpData := PChar(T);
  end;
  SendMessage (DeboutHandle, wm_copydata, 0, Integer(@CopyDataStruct));

{$ENDIF}
end;


procedure   DebOut (Text: string; const Args: array of const); overload;
begin
{$IFDEF PAXON_DEBUG}
  if (DeboutHandle = 0) then exit;
  DebOut (Format (Text, Args));
{$ENDIF}
end;


procedure   Debout (Obj: TObject; Text: String);
begin
{$IFDEF PAXON_DEBUG}
  if (DeboutHandle = 0) then exit;
  DebOut (Obj.ClassName + ': ' + Text);
{$ENDIF}
end;


procedure   DebOut (Obj: TObject; Text: string; const Args: array of const); overload;
begin
{$IFDEF PAXON_DEBUG}
  if (DeboutHandle = 0) then exit;
  DebOut (Obj, Format (Text, Args));
{$ENDIF}
end;


procedure   DebOut (Obj: TObject; Method: string; Text: string);
{$IFDEF PAXON_DEBUG}
var
  S: string;
{$ENDIF}
begin
{$IFDEF PAXON_DEBUG}
  if (DeboutHandle = 0) then exit;
  S := Obj.ClassName + '.' + Method;
  if Text <> '' then S := S + ': ' + Text;
  DebOut (S);
{$ENDIF}
end;


procedure   DebOut (Obj: TObject; Method: string; Text: string; const Args: array of const); overload;
begin
{$IFDEF PAXON_DEBUG}
  if (DeboutHandle = 0) then exit;
  DebOut (Obj, Method, Format (Text, Args));
{$ENDIF}
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  InitDebug;

end.
