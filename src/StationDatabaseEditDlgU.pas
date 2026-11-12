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


unit StationDatabaseEditDlgU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TStationDatabaseEditDlg = class (TFormUlf)
    Button1: TButton;
    Button2: TButton;
    GroupBoxXP1: TGroupbox;
    CallsignEdit: TEdit;
  private
  public
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

