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


unit StationDatabasePasswordDlgU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComboBoxUlfU, InterfacesU, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TStationDatabasePasswordDlg = class (TFormUlf)

    MyCallLabel: TLabel;
    MyCallCombo: TComboBoxUlf;
    PasswordKindLabel: TLabel;
    PasswordKindCombo: TComboBoxUlf;
    MethodLabel: TLabel;
    MethodCombo: TComboBoxUlf;
    PasswordLabel: TLabel;
    PasswordMemo: TMemo;

    OkButton: TButton;
    PasswordCancelButton: TButton;

    procedure   FormCreate (Sender: TObject);
    procedure   MyCallComboChange (Sender: TObject);
    procedure   PasswordMemoChange (Sender: TObject);

  private

    function    GetPasswordKind: TPasswordKind; virtual;
    procedure   SetPasswordKind (const Value: TPasswordKind); virtual;
    function    GetOwnCallsign: string; virtual;
    procedure   SetOwnCallsign (const Value: string); virtual;
    function    GetPasswordValue: string; virtual;
    procedure   SetPasswordValue (const Value: string); virtual;
    function    GetPasswordMethod: TPasswordMethod; virtual;
    procedure   SetPasswordMethod (const Value: TPasswordMethod); virtual;
    procedure   SetAddNewEntry (const Value: Boolean); virtual;
    function    GetStreamName: string;
    procedure   SetStreamName (const Value: string);
    procedure   CheckOk;

  public

    property    OwnCallsign: string read GetOwnCallsign write SetOwnCallsign;
    property    PasswordKind: TPasswordKind read GetPasswordKind write SetPasswordKind;
    property    PasswordMethod: TPasswordMethod read GetPasswordMethod write SetPasswordMethod;
    property    StreamName: string read GetStreamName write SetStreamName;

    property    PasswordValue: string read GetPasswordValue write SetPasswordValue;
    property    AddNewEntry: Boolean write SetAddNewEntry;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


uses
  StationDatabaseU, StationDatabaseEntryU, MyCallsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TStationDatabasePasswordDlg.FormCreate (Sender: TObject);
var
  I: Integer;
  S: string;
  PA: TPasswordKind;
  PV: TPasswordMethod;

begin

  assert (assigned (MyCalls));

  for I := 0 to MyCalls.Count - 1 do begin
    S := MyCalls[I].Call;
    MycallCombo.Items.Add (S);
  end;
  MycallCombo.ItemIndex := 0;

  for PA := Low(TPasswordKind) to High (TPasswordKind) do begin
    PasswordKindCombo.Items.Add (PasswordKindString[PA]);
  end;
  PasswordKindCombo.ItemIndex := 0;

  for PV := Low(TPasswordMethod) to High (TPasswordMethod) do begin
    MethodCombo.Items.Add (PasswordMethodString[PV]);
  end;
  MethodCombo.ItemIndex := 0;

  CheckOk;

end;


procedure   TStationDatabasePasswordDlg.SetAddNewEntry (const Value: Boolean);
resourcestring
  SAddPassword = 'Passwort hinzufügen...';
  SEditPassword = 'Passwort bearbeiten...';
begin
  if Value then begin
    Caption := SAddPassword;
  end else begin
    Caption := SEditPassword;
  end;
  MyCallCombo.Enabled := Value;
end;


function    TStationDatabasePasswordDlg.GetPasswordKind: TPasswordKind;
begin
  result := TPasswordKind(PasswordKindCombo.ItemIndex);
end;


procedure   TStationDatabasePasswordDlg.SetPasswordKind (const Value: TPasswordKind);
begin
  PasswordKindCombo.ItemIndex := Ord (Value);
end;


function    TStationDatabasePasswordDlg.GetOwnCallsign: string;
begin
  result := MycallCombo.Text;
end;


procedure   TStationDatabasePasswordDlg.SetOwnCallsign (const Value: string);
begin
  MycallCombo.Text := Value;
  CheckOk;
end;


function    TStationDatabasePasswordDlg.GetPasswordValue: string;
begin
  result := PasswordMemo.Text;
end;


procedure   TStationDatabasePasswordDlg.SetPasswordValue (const Value: string);
begin
  PasswordMemo.Text := Value;
  CheckOk;
end;


function    TStationDatabasePasswordDlg.GetPasswordMethod: TPasswordMethod;
begin
  result := TPasswordMethod(MethodCombo.ItemIndex);
end;


procedure   TStationDatabasePasswordDlg.SetPasswordMethod (const Value: TPasswordMethod);
begin
  MethodCombo.ItemIndex := Ord (Value);
end;


function    TStationDatabasePasswordDlg.GetStreamName: string;
begin
  TStationDatabaseEntry.PasswordStringsToStreamName (OwnCallsign, PasswordKind, PasswordMethod, result);
end;


procedure   TStationDatabasePasswordDlg.SetStreamName (const Value: string);
var
  PA: TPasswordKind;
  PV: TPasswordMethod;
  ER: string;
begin
  TStationDatabaseEntry.PasswordStreamNameToStrings (Value, ER, PA, PV);
  PasswordMethod := PV;
  PasswordKind := PA;
  OwnCallsign := ER;
end;


procedure   TStationDatabasePasswordDlg.MyCallComboChange (Sender: TObject);
begin
  CheckOk;
end;


procedure   TStationDatabasePasswordDlg.CheckOk;
begin
  OkButton.Enabled := (Length (MyCallCombo.Text) > 0) and (Length (PasswordMemo.Text) > 0);
end;


procedure   TStationDatabasePasswordDlg.PasswordMemoChange (Sender: TObject);
begin
  CheckOk;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

