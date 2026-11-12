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


unit RemoteCommandSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, SettingsU, RemoteCommandsFormU, Buttons, ExtCtrls,
  PanelUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TRemoteCommandSettings = class (TTabForm)

    StationDatabasePanel: TPanel;
    LinkLabel: TLabel;

    procedure   FormCreate (Sender: TObject);
    procedure   LinkLabelClick(Sender: TObject);

  private

    RemotecommandsForm: TRemotecommandsForm;

  public

    procedure   ApplyPage; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  MainU;

{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandSettings.FormCreate (Sender: TObject);
var
  I: Integer;
  C: TControl;

begin

  DisableAlign;

  RemoteCommandsForm := TRemoteCommandsForm.create (self);
  RemoteCommandsForm.ClientWidth := ClientWidth - 12;
  RemoteCommandsForm.ClientHeight := ClientHeight - 51;

  for I := 0 to RemoteCommandsForm.ControlCount - 1 do begin
    C := RemoteCommandsForm.Controls[0];
    C.Parent := self;
    C.Left := C.Left + 6;
    C.Top := C.Top + 6;
  end;

  EnableAlign;

  RemoteCommandsForm.Init (true);

end;


procedure   TRemoteCommandSettings.ApplyPage;
begin
  RemoteCommandsForm.Save;
end;


procedure TRemoteCommandSettings.LinkLabelClick(Sender: TObject);
begin
  MainWindow.ActionStationDatabase.Execute;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.
