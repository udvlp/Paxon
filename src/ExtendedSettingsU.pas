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


unit ExtendedSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, SettingsU, ExtCtrls, MLCBRB;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TExtendedSettings = class (TTabForm)

    PGPGroupbox: TGroupBox;
    PGPCollectPublicKeysCheckbox: TMultiCheckBox;
    GroupBox1: TGroupBox;
    SendSIDCheckbox: TMultiCheckBox;
    HideSentSIDCheckbox: TMultiCheckBox;
    HideReceivedSIDCheckbox: TMultiCheckBox;
    GroupBox2: TGroupBox;
    HighColorCheckbox: TMultiCheckBox;
    PGPSimpleOutputCheckbox: TMultiCheckBox;

    procedure   FormCreate (Sender: TObject);
    procedure   FormDestroy (Sender: TObject);
    procedure   SendSIDCheckboxClick (Sender: TObject);

  public

    procedure   ApplyPage; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  CallsignSettingsU, MyCallsU, MyCallU, ConfigU, GlobalU, MainU;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TExtendedSettings.FormCreate (Sender: TObject);
begin
  PGPCollectPublicKeysCheckbox.Checked := Config.PGPCollectPublicKeys;
  PGPSimpleOutputCheckbox.Checked := not Config.PGPDetailedOutput;
  SendSIDCheckbox.Checked := Config.SendSID;
  HideSentSIDCheckbox.Checked := Config.HideSentSID;
  HideReceivedSIDCheckbox.Checked := Config.HideReceivedSID;
  SendSIDCheckboxClick (nil);
  HighColorCheckbox.Enabled := HighColor;
  HighColorCheckbox.Checked := HighColor and Config.HighColor;
end;


procedure   TExtendedSettings.FormDestroy (Sender: TObject);
begin
  //
end;


procedure   TExtendedSettings.ApplyPage;
begin
  Config.PGPCollectPublicKeys := PGPCollectPublicKeysCheckbox.Checked;
  Config.PGPDetailedOutput := not PGPSimpleOutputCheckbox.Checked;
  Config.SendSID := SendSIDCheckbox.Checked;
  Config.HideSentSID := HideSentSIDCheckbox.Checked;
  Config.HideReceivedSID := HideReceivedSIDCheckbox.Checked;
  if (HighColorCheckbox.Enabled) then begin
    Config.HighColor := HighColorCheckbox.Checked;
    MainWindow.ImageListInit;
  end;
end;


procedure   TExtendedSettings.SendSIDCheckboxClick (Sender: TObject);
begin
  HideSentSIDCheckbox.Enabled := SendSIDCheckbox.Checked;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

