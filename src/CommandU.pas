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


unit CommandU;


interface


uses
  Windows, Messages, SysUtils, Classes, Forms,
  Controls, StdCtrls, ComCtrls, ExtCtrls, Dialogs, ImgList,
  GlobalU, InterfacesU, ConnectCommandU, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TDlgCommand = class (TFormUlf)
    Bevel1: TBevel;
    ConnectBtn: TButton;
    DisconnectBtn: TButton;
    CancelDialogBtn: TButton;
    procedure   FormKeyPress       (Sender: TObject; var Key: Char);
    procedure   ConnectBtnClick    (Sender: TObject);
    procedure   DisconnectBtnClick (Sender: TObject);
  private
  public
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


{$R *.DFM}


uses
  MainU, ChannelsU, SettingsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure TDlgCommand.FormKeyPress (Sender: TObject; var Key: Char);
var
  C: Char;
begin
  C := Upcase(Key);
  case C of
    'V', 'C': ConnectBtn.Click;
    'T', 'D': DisconnectBtn.Click;
  end;
end;


procedure TDlgCommand.ConnectBtnClick (Sender: TObject);
var
  Dialog: TDlgConnectCommand;
begin
  Hide;
  Close;
  Dialog := TDlgConnectCommand.Create (MainWindow);
  Dialog.ShowModal;
  Dialog.Release;
end;


procedure TDlgCommand.DisconnectBtnClick (Sender: TObject);
begin
  MainWindow.ActionDisconnect.Execute;
  Hide;
  Close;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

