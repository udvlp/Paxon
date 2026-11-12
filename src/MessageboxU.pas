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


unit MessageboxU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, StdCtrls, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TDlgMessage = class (TFormUlf)
    Panel1: TPanel;
    Label1: TLabel;
    Panel2: TPanel;
    function    Run (TitleText: String; Text: String; Buttons: TMsgDlgButtons): Integer;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  Consts;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function TDlgMessage.Run (TitleText: String; Text: String; Buttons: TMsgDlgButtons): Integer;
resourcestring
  SYes = '&Ja';
  SNo = '&Nein';
  SOk = '&Ok';
  SCancel = 'Abbrechen';
  SAbort = 'Abbruch';
  SRetry = '&Wiederholen';
  SIgnore = '&Ignorieren';
  SAll = '&Alle';
  SHelp = '&Hilfe';

const
  ModalResults: array[TMsgDlgBtn] of Integer = (mrYes, mrNo, mrOk, mrCancel, mrAbort, mrRetry, mrIgnore, mrAll, mrNoToAll,
                                                mrYesToAll, 0);

var
  B: TMsgDlgBtn;
  CancelButton, DefaultButton: TMsgDlgBtn;
  I, N, Quantity: Integer;
  ButtonControl: Array[0..Ord (High (TMsgDlgBtn))] of TButton;
  ButtonNames: array[TMsgDlgBtn] of string;
  R: TRect;
  D: Integer;

  // Height of the wrapped text at the current width of Label1
  function    CalcTextHeight: Integer;
  begin
    R := Rect (0, 0, Label1.Width, 0);
    DrawText (Canvas.Handle, PChar(Text), -1, R, DT_CALCRECT or DT_WORDBREAK);
    Result := R.Bottom;
  end;

begin

  Caption := TitleText;
  Label1.Caption := Text;
  Quantity := 0;

  // Fit the window to the text, otherwise a long text is cut off at the top
  // and bottom: first wider (at most 480 pixels of text), then taller.
  Canvas.Font.Assign (Label1.Font);
  if (CalcTextHeight > Label1.Height) and (Label1.Width < 480) then begin
    D := 480 - Label1.Width;
    ClientWidth := ClientWidth + D;
    Label1.Width := Label1.Width + D;
  end;
  D := CalcTextHeight - Label1.Height;
  if (D > Screen.Height div 2) then D := Screen.Height div 2;
  if (D > 0) then begin
    ClientHeight := ClientHeight + D;
    Label1.Height := Label1.Height + D;
  end;

  ButtonNames[mbYes] := SYes;
  ButtonNames[mbNo] := SNo;
  ButtonNames[mbOk] := SOk;
  ButtonNames[mbCancel] := SCancel;
  ButtonNames[mbAbort] := SAbort;
  ButtonNames[mbRetry] := SRetry;
  ButtonNames[mbIgnore] := SIgnore;
  ButtonNames[mbAll] := SAll;
  ButtonNames[mbNoToAll] := SMsgDlgNoToAll;   // from Consts: no new resource IDs (language DLLs)
  ButtonNames[mbYesToAll] := SMsgDlgYesToAll;
  ButtonNames[mbHelp] := SHelp;

  if (mbOk in Buttons) then begin
    DefaultButton := mbOk;
  end else if (mbYes in Buttons) then begin
    DefaultButton := mbYes;
  end else begin
    DefaultButton := mbRetry;
  end;

  if (mbCancel in Buttons) then begin
    CancelButton := mbCancel
  end else if (mbNo in Buttons) then begin
    CancelButton := mbNo;
  end else begin
    CancelButton := mbOk;
  end;

  for B := Low(TMsgDlgBtn) to High (TMsgDlgBtn) do begin
    if B in Buttons then begin
      ButtonControl[Quantity] := TButton.Create (Panel2);
      with ButtonControl[Quantity] do begin
        Parent := Panel2;
        Caption := ButtonNames[B];
        ModalResult := ModalResults[B];
        if (B = DefaultButton) then Default := True;
        if (B = CancelButton) then Cancel := True;
      end;
      Inc (Quantity);
    end;
  end;
  I := Panel2.ClientWidth div 2 - ((Quantity * 79) + ((Quantity - 1) * 6)) div 2;
  for N := 0 to Quantity - 1 do begin
    ButtonControl[N].SetBounds (I + N * (79 + 6), 0, 79, 23);
  end;
  Result := ShowModal;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.
