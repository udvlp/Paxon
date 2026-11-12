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


unit CallsignSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs,
  StdCtrls, ExtCtrls, MyCallU, MyCallsU, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TCallsignSettingsForm = class (TFormUlf)

    SsidPanel: TPanel;
    Check00: TCheckBox;
    Check01: TCheckBox;
    Check02: TCheckBox;
    Check03: TCheckBox;
    Check04: TCheckBox;
    Check05: TCheckBox;
    Check06: TCheckBox;
    Check07: TCheckBox;
    Check08: TCheckBox;
    Check09: TCheckBox;
    Check10: TCheckBox;
    Check11: TCheckBox;
    Check12: TCheckBox;
    Check13: TCheckBox;
    Check14: TCheckBox;
    Check15: TCheckBox;
    SsidLabel: TLabel;
    CallsignEdit: TEdit;
    CallsignLabel: TLabel;
    ButtonAll: TButton;
    ButtonOk: TButton;
    ButtonCancelSend: TButton;
    ButtonNone: TButton;

    procedure    ButtonAllClick(Sender: TObject);
    procedure    ButtonNoneClick(Sender: TObject);
    procedure    CallsignEditChange(Sender: TObject);
    procedure    FormCreate (Sender: TObject);
    function     Run (MyCall: TMyCall): Boolean;

  private

    FCheck: Array[0..15] of TCheckbox;
    procedure    CheckClick (Sender: TObject);
    procedure    CheckOkButton;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TCallsignSettingsForm.Run (MyCall: TMyCall): Boolean;
var
  I: Integer;
  S: String;

begin

  assert (assigned (MyCall));

  CallsignEdit.Text := MyCall.Call;
  for I := 0 to MyCall.SSIDCount - 1 do begin
    FCheck[MyCall.SSID[I]].Checked := true;
  end;

  CallsignEditChange (self);
  result := (ShowModal = mrOk);

  if result then begin
    // As checked in CheckOkButton: trimmed and in upper case
    S := UpperCase (Trim (CallsignEdit.Text));
    I := Pos ('-', S);
    if I > 0 then begin
      MyCall.Call := Copy (S, 1, I - 1);
      MyCall.SSIDCount := 1;
      MyCall.SSID[0] := StrToInt (Copy (S, I + 1, MaxInt));
    end else begin
      MyCall.Call := S;
      MyCall.SSIDCount := 0;
      for I := 0 to 15 do begin
        if FCheck[I].Checked then begin
          MyCall.SSID[MyCall.SSIDCount] := I;
          inc (MyCall.SSIDCount);
        end;
      end;
    end;
  end;

end;


procedure   TCallsignSettingsForm.ButtonAllClick (Sender: TObject);
var
  I: Integer;
begin
  inherited;
  for I := 0 to 15 do FCheck[I].Checked := true;
end;


procedure   TCallsignSettingsForm.CheckClick (Sender: TObject);
begin
  inherited;
  CheckOkButton;
end;


procedure   TCallsignSettingsForm.ButtonNoneClick(Sender: TObject);
var
  I: Integer;
begin
  inherited;
  for I := 0 to 15 do FCheck[I].Checked := false;
end;


procedure   TCallsignSettingsForm.CallsignEditChange (Sender: TObject);
var
  B: Boolean;
  I: Integer;
begin
  inherited;
  B := (Pos ('-', CallsignEdit.Text) = 0);
  if (B <> SsidPanel.Enabled) then begin
    SsidPanel.Enabled := B;
    ButtonAll.Enabled := B;
    ButtonNone.Enabled := B;
    for I := 0 to 15 do FCheck[I].Enabled := B;
  end;
  CheckOkButton;
end;


procedure   TCallsignSettingsForm.CheckOkButton;
var
  B: Boolean;
  N, I, A: Integer;
  S, T, U: String;

begin

  B := False;
  S := UpperCase (Trim (CallsignEdit.Text));

  if (Length (S) >= 3) then begin

    for I := 0 to 15 do begin
      if (FCheck[I].Checked) then begin
        B := true;
        break;
      end;
    end;

    if B then begin
      I := Pos ('-', S);
      if I > 0 then begin
        T := Copy (S, 1, I - 1);
        U := Copy (S, I + 1, MaxInt);
        if Length (U) > 0 then begin
          Val (U, N, A);
          if (A <> 0) or ((A = 0) and ((N < 0) or (N > 15))) then B := false;
        end else begin
          B := false;
        end;
      end else begin
        T := S;
        U := '';
      end;
    end;

    if B then begin
      for I := 1 to Length (T) do begin
        if not (T[I] in ['0'..'9', 'A'..'Z']) then begin
          B := false;
          break;
        end;
      end;
    end;

  end;

  ButtonOk.Enabled := B;

end;


procedure   TCallsignSettingsForm.FormCreate (Sender: TObject);
var
  I: Integer;

begin

  inherited;

  with SsidPanel do begin
    for I := 0 to ControlCount - 1 do begin
      if (Controls[I] is TCheckBox) then FCheck[Controls[I].Tag] := (Controls[I] as TCheckBox);
    end;
  end;

  for I := 0 to 15 do begin
    assert (assigned (FCheck[I]));
    FCheck[I].OnClick := CheckClick;
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

