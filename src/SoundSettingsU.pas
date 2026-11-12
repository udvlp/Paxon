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


unit SoundSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, SettingsU, ExtCtrls, ComCtrls, SoundsFormU, Buttons,
  PanelUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TSoundSettings = class (TTabForm)

    StationDatabasePanel: TPanel;
    SoundsFormPanel: TPanel;
    GroupBoxTelegraphy: TGroupBox;
    Bevel1: TBevel;
    Label4: TLabel;
    Label5: TLabel;
    RadioButtonSoundcard: TRadioButton;
    RadioButtonPCSpeaker: TRadioButton;
    Edit2: TEdit;
    UpDown1: TUpDown;
    Edit3: TEdit;
    UpDown2: TUpDown;
    LinkLabel: TLabel;
    procedure   FormCreate (Sender: TObject);
    procedure   LinkLabelClick(Sender: TObject);

  private

    SoundsForm: TSoundsForm;

  public

    procedure   ApplyPage; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}

uses
  MainU, GlobalU, SoundsU, Registry, DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSoundSettings.FormCreate (Sender: TObject);
var
  I: Integer;
  C: TControl;

begin

  DisableAlign;

  SoundsForm := TSoundsForm.create (self);
  SoundsForm.ClientWidth := ClientWidth - 12;
  SoundsForm.ClientHeight := ClientHeight - 51;

  for I := 0 to SoundsForm.ControlCount - 1 do begin
    C := SoundsForm.Controls[0];
    C.Parent := self;
    C.Left := C.Left + 6;
    C.Top := C.Top + 6;
  end;

  EnableAlign;

  SoundsForm.Init (true);

end;


procedure   TSoundSettings.ApplyPage;
begin
  SoundsForm.Save;
end;


procedure TSoundSettings.LinkLabelClick(Sender: TObject);
begin
  MainWindow.ActionStationDatabase.Execute;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

