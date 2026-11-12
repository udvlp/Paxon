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


unit FlexnetDeviceSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Controls, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TFlexnetDeviceSettingsForm = class (TFormUlf)
    PageControl: TPageControl;
    TabSheet: TTabSheet;
    Label1: TLabel;
    HeadingLabel: TLabel;
    ListBox: TListBox;
    Form_BtnOk: TButton;
    Form_BtnCancel: TButton;
  private
  public
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

