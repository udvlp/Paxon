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


unit UnhandledExceptionU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Dialogs, Forms,
  StdCtrls, ExtCtrls, Buttons, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TDlgUnhandledException = class (TFormUlf)
    Button1: TButton;
    Button2: TButton;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button3: TButton;
    procedure   Button1Click (Sender: TObject);
    procedure   Button2Click (Sender: TObject);
    procedure   Button3Click (Sender: TObject);
    procedure   FormShow (Sender: TObject);
  private
  public
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   ShowUnhandledException (anException: Exception; aClassName: String = ''; aContext: String = '');


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  ClipBrd, DebOutU;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  // Zeigt Meldungen aus Nebenthreads im Hauptthread an (die VCL ist nicht
  // threadsicher). PostMessage statt SendMessage: Der meldende Thread wartet
  // nicht auf den Dialog und kann weiter aufräumen.
  TExceptionNotifier = class
  private
    FWindow: HWND;
    procedure   WndProc (var Msg: TMessage);
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   Post (const aText: String);
  end;

const
  wm_showexception = WM_USER + $4012;

var
  Notifier: TExceptionNotifier = nil;

threadvar
  // Die zuletzt gemeldete Ausnahme dieses Threads. Eine weitergeworfene
  // Ausnahme durchläuft oft mehrere Handler; gemeldet wird sie nur einmal.
  LastReported: Pointer;
  // The address alone is not enough: a later exception object can get the same
  // address. A re-raise passes the handlers within moments, so class and time count too.
  LastReportedClass: TClass;
  LastReportedTick: Cardinal;


procedure   ShowDialog (const aText: String);
var
  UE: TDlgUnhandledException;
begin
  try
    UE := TDlgUnhandledException.Create (nil);
    try
      UE.Label2.Caption := aText;
      UE.ShowModal;
    finally
      UE.Free;
    end;
  except;
  end;
end;


constructor TExceptionNotifier.Create;
begin
  inherited;
  FWindow := Classes.AllocateHWnd (WndProc);
end;


destructor  TExceptionNotifier.Destroy;
begin
  Classes.DeallocateHWnd (FWindow);
  inherited;
end;


procedure   TExceptionNotifier.Post (const aText: String);
var
  P: PString;
begin
  New (P);
  P^ := aText;
  if (not PostMessage (FWindow, wm_showexception, 0, LongInt (P))) then begin
    Dispose (P);
  end;
end;


procedure   TExceptionNotifier.WndProc (var Msg: TMessage);
var
  P: PString;
  S: String;
begin
  if (Msg.Msg = wm_showexception) then begin
    P := PString (Msg.LParam);
    S := P^;
    Dispose (P);
    ShowDialog (S);
    Msg.Result := 0;
  end else begin
    Msg.Result := DefWindowProc (FWindow, Msg.Msg, Msg.WParam, Msg.LParam);
  end;
end;


procedure   ShowUnhandledException (anException: Exception; aClassName: String = ''; aContext: String = '');
var
  S, T: String;

begin

  if (assigned (anException)) and (Pointer (anException) = LastReported) and
     (anException.ClassType = LastReportedClass) and (GetTickCount - LastReportedTick < 2000) then begin
    DebOut ('EXCEPTION bereits gemeldet: ' + aClassName + ' (' + aContext + ')');
    exit;
  end;
  LastReported := Pointer (anException);
  if (assigned (anException)) then LastReportedClass := anException.ClassType else LastReportedClass := nil;
  LastReportedTick := GetTickCount;

  T := '';
  S := '';
  if (assigned (anException)) then begin
    S := S + anException.ClassName;
    T := anException.Message;
  end else begin
    S := S + '[unassigned]';
  end;
  S := S + ' in ';
  if (length (aClassName) > 0) then begin
    S := S + aClassName;
  end;
  if (Length (aContext) > 0) then begin
    S := S + ' (' + aContext + ')';
  end;
  if (Length (T) = 0) then T := '(no message)';

  try
    DebOut ('');
    DebOut ('---------------------------- EXCEPTION ----------------------------');
    DebOut (S);
    DebOut (T);
    DebOut ('-------------------------------------------------------------------');
    DebOut ('');
  except;
  end;

  if (GetCurrentThreadID = MainThreadID) then begin
    ShowDialog (S + #13 + T);
    // the modal dialog may stay open for long; the re-raise comes only afterwards
    LastReportedTick := GetTickCount;
  end else if (assigned (Notifier)) then begin
    Notifier.Post (S + #13 + T);
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDlgUnhandledException.FormShow (Sender: TObject);
begin
  Update;
end;


procedure   TDlgUnhandledException.Button1Click (Sender: TObject);
begin
  Close;
end;


procedure   TDlgUnhandledException.Button2Click (Sender: TObject);
begin
  ExitProcess (1);
end;


procedure   TDlgUnhandledException.Button3Click (Sender: TObject);
var
  S: String;
  N, L: Integer;
begin
  S := Label2.Caption;
  L := Length (S);
  for N := L downto 1 do begin
    if (S[N] = #13) then Insert (#10, S, N + 1);
  end;
  S := S + #13#10;
  ClipBoard.AsText := S;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  Notifier := TExceptionNotifier.Create;

finalization

  FreeAndNil (Notifier);

end.

