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


unit MonitorSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls,
  SettingsU, PanelUlfU, ConsoleU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TMonitorSettings = class (TTabForm)

    GroupBox: TGroupBox;
    CheckBoxUnproto: TCheckBox;
    CheckBoxInformation: TCheckBox;
    CheckBoxInformationContent: TCheckBox;
    CheckBoxInformationBinary: TCheckBox;
    CheckBoxLocal: TCheckBox;
    CheckBoxStatus: TCheckBox;
    ExamplePanel: TPanel;
    ExampleConsole: TConsole;
    ExampleLabel: TLabel;
    Bevel1: TBevel;
    CheckBoxPortnumber: TCheckBox;

    procedure   FormCreate (Sender: TObject);
    procedure   CheckBoxInformationClick (Sender: TObject);
    procedure   CheckBoxInformationContentClick (Sender: TObject);
    procedure   ChangeExample (Sender: TObject);

  public

    procedure   ApplyPage; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


uses
  ConfigU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TMonitorSettings.FormCreate (Sender: TObject);
var
  M: Cardinal;

begin

  with ExampleConsole do begin
    Color := Config.Color[ct_monitor_background];
    VPalette[01] := Config.Color[ct_monitor_header_sent];
    VPalette[05] := Config.Color[ct_monitor_data];
    VPalette[06] := Config.Color[ct_monitor_local];
    VPalette[10] := Config.Color[ct_monitor_header_received];
  end;

  M := Config.Monitor;

  CheckBoxStatus.Checked := ((M and MonitorStatus) <> 0);
  CheckBoxInformation.Checked := ((M and MonitorInformation) <> 0);
  CheckBoxInformationContent.Checked := ((M and MonitorInformationContent) <> 0);
  CheckBoxInformationBinary.Checked := ((M and MonitorInformationBinary) <> 0);
  CheckBoxUnproto.Checked := ((M and MonitorUnproto) <> 0);
  CheckBoxLocal.Checked := ((M and MonitorLocal) <> 0);
  CheckBoxPortnumber.Checked := ((M and MonitorPort) <> 0);

  CheckBoxInformationClick (nil);

end;


procedure   TMonitorSettings.ApplyPage;
var
  M: Cardinal;
begin
  M := 0;
  if (CheckBoxStatus.Checked) then M := M or MonitorStatus;
  if (CheckBoxInformation.Checked) then M := M or MonitorInformation;
  if (CheckBoxInformationContent.Checked) then M := M or MonitorInformationContent;
  if (CheckBoxInformationBinary.Checked) then M := M or MonitorInformationBinary;
  if (CheckBoxUnproto.Checked) then M := M or MonitorUnproto;
  if (CheckBoxLocal.Checked) then M := M or MonitorLocal;
  if (CheckBoxPortnumber.Checked) then M := M or MonitorPort;
  Config.Monitor := M;
end;


procedure   TMonitorSettings.CheckBoxInformationClick (Sender: TObject);
begin
  CheckBoxInformationContent.Enabled := CheckBoxInformation.Checked;
  CheckBoxInformationBinary.Enabled := CheckBoxInformation.Checked and CheckBoxInformationContent.Checked;
  ChangeExample (Sender);
end;


procedure   TMonitorSettings.CheckBoxInformationContentClick (Sender: TObject);
begin
  CheckBoxInformationBinary.Enabled := CheckBoxInformationContent.Checked;
  ChangeExample (Sender);
end;


procedure   TMonitorSettings.ChangeExample (Sender: TObject);
var
  Port: String;
begin

  if (CheckBoxPortnumber.Checked) then Port := '001: ' else Port := '';

  with ExampleConsole do begin

    ClrScr;

    if (CheckBoxLocal.Checked) then begin
      TextColor :=  6; WriteString ('[TNC COM2 38400: Init]'#13);
      TextColor :=  6; WriteString ('  T15: ok'#13);
    end;

    if (CheckBoxStatus.Checked) then begin
      TextColor :=  1; WriteString ('['+Port+'DG1FAZ-1 > DB0DAR v DB0FT SABM+]'#13);
      TextColor := 10; WriteString ('['+Port+'DB0DAR > DG1FAZ-1 v DB0FT* UA-]'#13);
    end;

    if (CheckBoxInformation.Checked) then begin
      TextColor := 10; WriteString ('['+Port+'DB0DAR > DG1FAZ-1 v DB0FT* I00^]'#13);
      if (CheckBoxInformationContent.Checked) then begin
        TextColor :=  5; WriteString ('RMNC/FlexNet V3.3h * Digipeater Technische Hochschule Darmstadt'#13);
      end;
    end;

    if (CheckBoxUnproto.Checked) then begin
      TextColor :=  1; WriteString ('['+Port+'DB0ZDF-8 > MAILS UI^]'#13);
      TextColor :=  5; WriteString ('DG1FAZ'#13);
    end;

    if (CheckBoxStatus.Checked) then begin
      TextColor :=  1; WriteString ('['+Port+'DG1FAZ-1 > DB0DAR v DB0FT RR1-]'#13);
    end;

    if (CheckBoxInformation.Checked) then begin
      if (CheckBoxInformationContent.Checked) then begin
        if (CheckBoxInformationBinary.Checked) then begin
          TextColor :=  1; WriteString ('['+Port+'DB0ZDF-8 > DG1FAZ v DB0FT* I51^]'#13);
          TextColor :=  5; WriteString ('ÇÃf'#3'¨ŽXP'#1'‰£f½‘52zžc)­©ïlÜ¸qÓÆŸî)»x\úöâER#¥¥ýÃf'#3'¨ŽXP'#13);
        end else begin
          TextColor :=  1; WriteString ('['+Port+'DB0ZDF-8 > DG1FAZ v DB0FT* I51^ BIN230]'#13);
        end;
      end else begin
        TextColor :=  1; WriteString ('['+Port+'DB0ZDF-8 > DG1FAZ v DB0FT* I51^]'#13);
      end;
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

