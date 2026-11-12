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


unit TextSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, SettingsU, TextsFormU, Buttons, ExtCtrls,
  PanelUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TTextSettings = class (TTabForm)

    StationDatabasePanel: TPanel;
    LinkLabel: TLabel;

    procedure   FormCreate (Sender: TObject);
    procedure   LinkLabelClick(Sender: TObject);

  private

    TextsForm: TTextsForm;

  public

    procedure   ApplyPage; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}

uses
  MainU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TTextSettings.FormCreate (Sender: TObject);
var
  I: Integer;
  C: TControl;

begin

  DisableAlign;

  TextsForm := TTextsForm.create (self);
  TextsForm.ClientWidth := ClientWidth - 12;
  TextsForm.ClientHeight := ClientHeight - 48;

  for I := 0 to TextsForm.ControlCount - 1 do begin
    C := TextsForm.Controls[0];
    C.Parent := self;
    C.Left := C.Left + 6;
    C.Top := C.Top + 6;
  end;

  EnableAlign;

  TextsForm.Init (true);

end;


procedure   TTextSettings.ApplyPage;
begin
  TextsForm.Save;
end;


procedure TTextSettings.LinkLabelClick(Sender: TObject);
begin
  MainWindow.ActionStationDatabase.Execute;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

