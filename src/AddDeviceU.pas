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


unit AddDeviceU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ComCtrls, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TAddDeviceForm = class (TFormUlf)
    BtnOk: TButton;
    BtnCancelDialog: TButton;
    ListBox: TListBox;
    procedure ListBoxDblClick (Sender: TObject);
  private
  public
  end;


implementation


{$R *.DFM}


procedure TAddDeviceForm.ListBoxDblClick (Sender: TObject);
begin
  inherited;
  ModalResult := mrok;
end;


end.
