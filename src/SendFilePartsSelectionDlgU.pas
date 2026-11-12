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


unit SendFilePartsSelectionDlgU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, CheckLst, ComCtrls, Menus, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TSendFilePartsSelectionDlg = class(TFormUlf)
    FileNameLabel: TLabel;
    ButtonCancelSend: TButton;
    ButtonOk: TButton;
    ListView1: TListView;
    procedure   ListView1KeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure   ListView1MouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    procedure   ToggleCheck;
  public
    function    Execute (FileNameStr: String; var PartItems: array of Boolean): Boolean;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TSendFilePartsSelectionDlg.Execute (FileNameStr: String; var PartItems: array of Boolean): Boolean;
resourcestring
  SListItem = 'Teil %0:3.3d (.B%0:2.2x)';
var
  N: Integer;
  LI: TListItem;
  K: Integer;
begin
  assert (Low(PartItems) = 0);
  FileNameLabel.Caption := FileNameStr;
  ListView1.Items.Clear;
  K := 1;
  for N := 0 to High (PartItems) do begin
    LI := ListView1.Items.Add;
    LI.Caption := Format (SListItem, [K]);
    LI.Checked := PartItems[N];
    inc (K);
  end;
  result := (ShowModal = mrOk);
  if (result) then begin
    for N := 0 to High (PartItems) do begin
      LI := ListView1.Items[N];
      PartItems[N] := LI.Checked;
    end;
  end;
end;


procedure TSendFilePartsSelectionDlg.ListView1KeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = vk_space) then begin
    ToggleCheck;
    Key := 0;
  end;
end;


procedure   TSendFilePartsSelectionDlg.ListView1MouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,
                                                           Y: Integer);
var
  H: THitTests;
begin
  if (Button = mbRight) then begin
    H := ListView1.GetHitTestInfoAt (X, Y);
    if (htOnLabel in H) then ToggleCheck;
  end;
end;


procedure   TSendFilePartsSelectionDlg.ToggleCheck;
var
  B: Boolean;
  N: Integer;

begin

  B := false;
  for N := 0 to ListView1.Items.Count - 1 do begin
    if (ListView1.Items[N].Selected) and (not ListView1.Items[N].Checked) then begin
      B := true;
      break;
    end;
  end;

  for N := 0 to ListView1.Items.Count - 1 do begin
    if ListView1.Items[N].Selected then begin
      ListView1.Items[N].Checked := B;
    end;
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

