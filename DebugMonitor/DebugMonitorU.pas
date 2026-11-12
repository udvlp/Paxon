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


unit DebugMonitorU;


// Shows the debug output of Paxon (DebOut, only when compiled with PAXON_DEBUG).


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ConsoleU;


const
  ApplicationName = 'Paxon Terminal';
  WM_DebugMonitor = wm_user + $4091;


type
  TMainForm = class (TForm)
    Console: TConsole;
    procedure   FormCreate (Sender: TObject);
    procedure   FormDestroy (Sender: TObject);
  private
    procedure   wmCopyData (var Msg: TWMCopyData); message WM_COPYDATA;
    procedure   wmDebugMonitor (var Msg: TMessage); message WM_DEBUGMONITOR;
  public
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  MainForm: TMainForm;


implementation


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TMainForm.FormCreate (Sender: TObject);
var
  H: THandle;

begin
  Application.Title := 'DebugMonitor';
  Left := Screen.Width - Width;
  Top := 28;
  Caption := 'Paxon DebugMonitor';
  H := FindWindow (nil, ApplicationName);
  if (H <> 0) then begin
    SendMessage (H, WM_DEBUGMONITOR, Handle, 0);
    Console.ClrScr;
  end;
  Console.TextColor := 15;
end;


procedure   TMainForm.FormDestroy (Sender: TObject);
var
  H: THandle;
begin
  H := FindWindow (nil, ApplicationName);
  if (H <> 0) then PostMessage (H, WM_DEBUGMONITOR, 0, 0);
end;


procedure   TMainForm.wmCopyData (var Msg: TWMCopyData);
var
  S: String;
begin
  with Msg.CopyDataStruct^ do begin
    if (cbData > 0) and (assigned (lpData)) then begin
      SetLength (S, cbData);
      CharToOemBuff (lpData, PChar(S), cbData);
      Console.WriteString (S);
    end;
  end;
end;


procedure   TMainForm.wmDebugMonitor (var Msg: TMessage);
begin
  if (Msg.wParam = 1) then begin
    Console.ClrScr;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

