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


unit HostmodeSerialDeviceSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, FormU,
  StdCtrls, ComCtrls, ExtCtrls, Buttons;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  THostmodeSerialDeviceSettingsForm = class (TFormUlf)
    PageControl: TPageControl;
    TabSheet: TTabSheet;
    BaudrateLabel: TLabel;
    BaudrateComboBox: TComboBox;
    PortLabel: TLabel;
    PortComboBox: TComboBox;
    InitLabel: TLabel;
    InitMemo: TMemo;
    DeInitLabel: TLabel;
    DeInitMemo: TMemo;
    BtnOk: TButton;
    BtnCancelDialog: TButton;
  private
  public
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

implementation

{$R *.DFM}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

