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


unit FormU;


interface


uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TFormUlf = class (TForm)
    procedure Loaded; override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, Registry;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure TFormUlf.Loaded;
const
  MethodName = 'Loaded';
var
  R: TRegistry;
  UseMSShellDlg2: Boolean;

begin
  DebOut (self, MethodName, 'begin...');
  inherited;
  UseMSShellDlg2 := false;
  R := TRegistry.create (KEY_READ);
  try
    R.RootKey := HKEY_LOCAL_MACHINE;
    if (R.OpenKey ('\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes', false)) then begin
      if (R.ValueExists ('MS Shell Dlg 2')) then begin
        UseMSShellDlg2 := true;
      end;
      R.CloseKey;
    end;
  finally
    R.free;
  end;
  if (UseMSShellDlg2) then begin
    if (Font.Name = 'MS Shell Dlg') or (Font.Name = 'MS Sans Serif') then begin
      Font.Name := 'MS Shell Dlg 2';
    end;
  end;
  DebOut (self, MethodName, 'end.');
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

