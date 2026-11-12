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


procedure   ShowUnhandledException (anException: Exception; aClassName: String = ''; aContext: String = '');
var
  UE: TDlgUnhandledException;
  S, T: String;

begin

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

  try
    UE := TDlgUnhandledException.Create (nil);
    if (assigned (UE)) then begin
      UE.Label2.Caption := S + #13 + T;;
      UE.ShowModal;
      UE.Free;
    end;
  except;
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


end.

