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


unit FileSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, FileCtrl,
  SettingsU, ExtCtrls, PanelUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TFileSettings = class(TTabForm)
    GroupBox1: TGroupBox;
    ReceptionLabel: TLabel;
    ReceptionEdit: TEdit;
    ReceptionBtn: TButton;
    RemoteLabel: TLabel;
    RemoteEdit: TEdit;
    RemoteBtn: TButton;
    GroupBox2: TGroupBox;
    TransferProgressCheckbox: TCheckBox;

    procedure BrowseFolderBtnClick(Sender: TObject);
    procedure FormCreate (Sender: TObject);

  public

    procedure ApplyPage; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  FolderU;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TFileSettings.FormCreate (Sender: TObject);
begin
  inherited;
  assert (assigned (Folders));
  ReceptionEdit.Text := ExcludeTrailingPathDelimiter (Folders.Reception);
  RemoteEdit.Text := ExcludeTrailingPathDelimiter (Folders.Remote);
end;


procedure TFileSettings.BrowseFolderBtnClick(Sender: TObject);
resourcestring
  SFolderForDownloadedFiles = 'Ordner für empfangene Dateien:';
  SFolderForRemoteFiles = 'Ordner für per Fernsteuerung lesbare Dateien:';

var
  E: TEdit;
  S: string;
  NewDir: string;

begin

  inherited;

  if (Sender = ReceptionBtn) then begin

    E := ReceptionEdit;
    S := SFolderForDownloadedFiles;

  end else if (Sender = RemoteBtn) then begin

    E := RemoteEdit;
    S := SFolderForRemoteFiles;

  end else begin

    exit;

  end;

  NewDir := E.Text;
  if SelectDirectory(S, '', NewDir) then begin
    E.Text := NewDir;
  end;

end;


procedure TFileSettings.ApplyPage;
begin
  assert (assigned (Folders));
  Folders.Reception := ReceptionEdit.Text;
  Folders.Remote := RemoteEdit.Text;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

