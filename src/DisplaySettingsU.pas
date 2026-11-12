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


unit DisplaySettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ConsoleU, ExtCtrls, ComCtrls,
  GlobalU, SettingsU, ColorButtonUlfU, PanelUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TDisplaySettings = class(TTabForm)
    GroupBox: TGroupBox;
    FontLabel: TLabel;
    ExampleLabel: TLabel;
    FontCombobox: TComboBox;
    ExamplePanel: TPanel;
    ExampleConsole: TConsole;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    Label5: TLabel;
    Label4: TLabel;
    Label3: TLabel;
    Label2: TLabel;
    Label1: TLabel;
    Bevel1: TBevel;
    OutputStandardButton: TButton;
    ColorButtonAB: TColorButtonUlf;
    ColorButtonA4: TColorButtonUlf;
    ColorButtonA3: TColorButtonUlf;
    ColorButtonA2: TColorButtonUlf;
    ColorButtonA1: TColorButtonUlf;
    TabSheet3: TTabSheet;
    Bevel2: TBevel;
    Label7: TLabel;
    Label6: TLabel;
    Label10: TLabel;
    InputStandardButton: TButton;
    ColorButtonE1: TColorButtonUlf;
    ColorButtonE2: TColorButtonUlf;
    ColorButtonEB: TColorButtonUlf;
    TabSheet2: TTabSheet;
    Bevel3: TBevel;
    Label8: TLabel;
    Label15: TLabel;
    Label12: TLabel;
    Label11: TLabel;
    MonitorStandardButton: TButton;
    ColorButtonMB: TColorButtonUlf;
    ColorButtonM3: TColorButtonUlf;
    ColorButtonM2: TColorButtonUlf;
    ColorButtonM1: TColorButtonUlf;
    ColorButtonM4: TColorButtonUlf;
    Label9: TLabel;

    procedure   FormCreate (Sender: TObject);
    procedure   FontComboBoxChange (Sender: TObject);
    procedure   MonitorStandardButtonClick (Sender: TObject);
    procedure   InputStandardButtonClick (Sender: TObject);
    procedure   OutputStandardButtonClick (Sender: TObject);
    procedure   PageControlChange (Sender: TObject);
    procedure   MonitorColorChange (Sender: TObject);
    procedure   InputColorChange (Sender: TObject);
    procedure   OutputColorChange (Sender: TObject);
    procedure ColorClick(Sender: TObject);

  public

    procedure   ApplyPage; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  ConfigU, ChannelsU, MainU, Registry;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


resourcestring
  SOutput = 'Ausgabe';
  SOutputReceivedText = 'Empfangener Text';
  SOutputSentText = 'Gesendeter Text';
  SOutputStatusText = 'Status-Text';

  SInput = 'Eingabe';
  SInputText = 'Text';

  SMonitor = 'Monitor';
  SMonitorHeader = 'Kopf';
  SMonitorData = 'Daten';

  SExample = 'Beispiel:';


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDisplaySettings.FormCreate (Sender: TObject);

  function EnumFontsProc (var LogFont: TLogFont; var TextMetric: TTextMetric; FontType: Integer; Data: Pointer): Integer; stdcall;
  var
    S: String;
  begin
    if (StrLIComp (PChar(ConsoleFontName), LogFont.lfFaceName, Length (ConsoleFontName)) = 0) then begin
      S := StrPas (@(LogFont.lfFaceName[Length (ConsoleFontName)+1]));
      TStrings(Data^).Add (S);
    end;
    Result := 1;
  end;

var
  SL: TStringList;
  N, I, M: Integer;
  DC: HDC;
  S, T: String;

begin

  inherited;

  PageControl.ActivePageIndex := 0;

  with FontCombobox do begin
    SL := TStringList.Create;
    DC := GetDC (Handle);
    EnumFonts (DC, nil, @EnumFontsProc, PChar(@SL));
    ReleaseDC (Handle, DC);
    T := Config.FontSize;
    M := -1;
    for N := 0 to SL.Count-1 do begin
      S := SL.Strings[N];
      I := Items.Add (S);
      if (M < 0) and (S = T) then M := I;
    end;
    if (M < 0) then M := 2;
    ItemIndex := M;
    if Assigned (OnChange) then OnChange (FontCombobox);
    SL.Free;
  end;

  ColorButtonA1.Color := Config.Color [ct_output_received];
  ColorButtonA2.Color := Config.Color [ct_output_sent];
  ColorButtonA3.Color := Config.Color [ct_output_connstat];
  ColorButtonA4.Color := Config.Color [ct_output_local];
  ColorButtonAB.Color := Config.Color [ct_output_background];

  ColorButtonE1.Color := Config.Color [ct_input_new];
  ColorButtonE2.Color := Config.Color [ct_input_sent];
  ColorButtonEB.Color := Config.Color [ct_input_background];

  ColorButtonM1.Color := Config.Color [ct_monitor_header_received];
  ColorButtonM2.Color := Config.Color [ct_monitor_header_sent];
  ColorButtonM3.Color := Config.Color [ct_monitor_data];
  ColorButtonM4.Color := Config.Color [ct_monitor_local];
  ColorButtonMB.Color := Config.Color [ct_monitor_background];

  ExampleConsole.GutterImages := MainWindow.GutterImages;

  PageControlChange (nil);

end;


procedure   TDisplaySettings.ApplyPage;
var
  S: String;

begin

  S := '';
  if (FontCombobox.ItemIndex >= 0) then begin
    S := FontCombobox.Items.Strings[FontCombobox.ItemIndex];
  end;

  if (S <> '') then Config.FontSize := S;
  ChannelList.Font := ExampleConsole.Font;

  Config.Color [ct_output_received]         := ColorButtonA1.Color;
  Config.Color [ct_output_sent]             := ColorButtonA2.Color;
  Config.Color [ct_output_connstat]         := ColorButtonA3.Color;
  Config.Color [ct_output_local]            := ColorButtonA4.Color;
  Config.Color [ct_output_background]       := ColorButtonAB.Color;

  Config.Color [ct_input_new]               := ColorButtonE1.Color;
  Config.Color [ct_input_sent]              := ColorButtonE2.Color;
  Config.Color [ct_input_background]        := ColorButtonEB.Color;

  Config.Color [ct_monitor_header_received] := ColorButtonM1.Color;
  Config.Color [ct_monitor_header_sent]     := ColorButtonM2.Color;
  Config.Color [ct_monitor_data]            := ColorButtonM3.Color;
  Config.Color [ct_monitor_local]           := ColorButtonM4.Color;
  Config.Color [ct_monitor_background]      := ColorButtonMB.Color;

  ChannelList.UpdateColors;

end;


procedure   TDisplaySettings.FontComboBoxChange (Sender: TObject);

  function EnumFontsProc (var LogFont: TLogFont; var TextMetric: TTextMetric; FontType: Integer; Data: Pointer): Integer; stdcall;
  begin
    Integer(Data^) := LogFont.lfHeight;
    Result := 0;
  end;

var
  S: String;
  N: Integer;
  DC: HDC;

begin
  inherited;
  with FontCombobox do begin
    if (ItemIndex >= 0) then begin
      S := ConsoleFontName + ' ' + Items.Strings[ItemIndex];
      DC := GetDC (Handle);
      EnumFonts (DC, PChar(S), @EnumFontsProc, PChar(@N));
      ReleaseDC (Handle, DC);
      ExampleConsole.Font.Name := S;
    end;
  end;
end;


procedure   TDisplaySettings.MonitorStandardButtonClick (Sender: TObject);
begin
  ColorButtonM1.Color := DefaultColors [ct_monitor_header_received];
  ColorButtonM2.Color := DefaultColors [ct_monitor_header_sent];
  ColorButtonM3.Color := DefaultColors [ct_monitor_data];
  ColorButtonM4.Color := DefaultColors [ct_monitor_local];
  ColorButtonMB.Color := DefaultColors [ct_monitor_background];
  MonitorColorChange (nil);
end;


procedure   TDisplaySettings.InputStandardButtonClick (Sender: TObject);
begin
  ColorButtonE1.Color := DefaultColors [ct_input_new];
  ColorButtonE2.Color := DefaultColors [ct_input_sent];
  ColorButtonEB.Color := DefaultColors [ct_input_background];
  InputColorChange (nil);
end;


procedure   TDisplaySettings.OutputStandardButtonClick (Sender: TObject);
begin
  ColorButtonA1.Color := DefaultColors [ct_output_received];
  ColorButtonA2.Color := DefaultColors [ct_output_sent];
  ColorButtonA3.Color := DefaultColors [ct_output_connstat];
  ColorButtonA4.Color := DefaultColors [ct_output_local];
  ColorButtonAB.Color := DefaultColors [ct_output_background];
  OutputColorChange (nil);
end;


procedure   TDisplaySettings.PageControlChange (Sender: TObject);
resourcestring
  SExampleConnectedTo = 'DG1FAZ: Verbunden mit DB0FT';
  SExampleDisconnectedFrom = 'DG1FAZ: Getrennt von DB0FT';

begin

  with ExampleConsole do begin

    ClrScr;

    case PageControl.ActivePageIndex of

      0: begin

        TextColor := 15;
        SetGutterImageIndex (5);
        WriteString (SExampleConnectedTo + #13);

        TextColor := 10;
        WriteString ('RMNC/FlexNet V3.3h Digi Grosser Feldberg/Taunus JO40FF'#13);
        WriteString ('(A)ktuell (I)nfo (M)ailbox (H)elp'#13);
        WriteString ('=>');

        TextColor :=  1;
        WriteString ('links'#13);

        TextColor := 10;
        WriteString ('DB0AIS  0-15    3/4   P6'#13);
        WriteString ('=>');

        TextColor :=  1;
        WriteString ('quit'#13);

        TextColor := 10;
        WriteString ('73!'#13);

        TextColor := 15;
        SetGutterImageIndex (6);
        WriteString (SExampleDisconnectedFrom + #13);

        OutputColorChange (nil);

      end;

      1: begin

        TextColor :=  2; WriteString ('links'#13);
                         WriteString ('help'#13);
                         WriteString ('c db0ais-8'#13);
        TextColor := 15; WriteString ('list dg1faz 1-');

        InputColorChange (nil);

      end;

      2: begin

        TextColor :=  6; WriteString ('[Initialisierung TNC: COM2, 38400]'#13);
        TextColor :=  6; WriteString ('  T15: ok'#13);
        TextColor :=  1; WriteString ('[DG1FAZ-1 > DB0DAR SABM+]'#13);
        TextColor := 10; WriteString ('[DB0DAR > DG1FAZ-1 UA-]'#13);
                         WriteString ('[DB0DAR > DG1FAZ-1 I00^]'#13);
        TextColor :=  5; WriteString ('RMNC/FlexNet V3.3h * Digipeater Technische Hochschule Darmstadt'#13);
                         WriteString ('(A)ktuell (H)ilfe (I)nfo (D)estinations (MH)-Liste (L)inks'#13);
        TextColor :=  1; WriteString ('[DG1FAZ-1 > DB0DAR RR1-]'#13);

        MonitorColorChange (nil);

      end;

    end;

  end;

end;


procedure   TDisplaySettings.OutputColorChange (Sender: TObject);
begin
  with ExampleConsole do begin
    VPalette[10] := ColorButtonA1.Color;
    VPalette[01] := ColorButtonA2.Color;
    VPalette[15] := ColorButtonA3.Color;
    VPalette[08] := ColorButtonA4.Color;
    Color := ColorButtonAB.Color;
    Invalidate;
  end;
end;


procedure   TDisplaySettings.InputColorChange (Sender: TObject);
begin
  with ExampleConsole do begin
    VPalette[15] := ColorButtonE1.Color;
    VPalette[02] := ColorButtonE2.Color;
    Color := ColorButtonEB.Color;
    Invalidate;
  end;
end;


procedure   TDisplaySettings.MonitorColorChange (Sender: TObject);
begin
  with ExampleConsole do begin
    VPalette[10] := ColorButtonM1.Color;
    VPalette[01] := ColorButtonM2.Color;
    VPalette[05] := ColorButtonM3.Color;
    VPalette[06] := ColorButtonM4.Color;
    Color := ColorButtonMB.Color;
    Invalidate;
  end;
end;


procedure   TDisplaySettings.ColorClick (Sender: TObject);
var
  ColorDlg: TColorDialog;
  Registry: TRegistry;
  C: Char;
  SL: TStringList;
  I: Integer;

begin

  assert (Sender is TColorButtonUlf);

  ColorDlg := TColorDialog.Create (Self);
  try

    SL := TStringList.create;

    Registry := TRegistry.create (KEY_READ or KEY_WRITE);
    Registry.RootKey := HKEY_CURRENT_USER;
    Registry.OpenKey (RootRegKey + '\Colors', true);
    try
      SL.CommaText := Registry.ReadString ('Custom');
    except
      SL.Clear;
    end;

    if (SL.Count = 0) then begin
      for I := Ord (Low(DefaultColors)) to Ord (High (DefaultColors)) do begin
        SL.Add (IntToHex (DefaultColors[TColorType(I)], 6));
      end;
    end;

    ColorDlg.CustomColors.Clear;
    C := 'A';
    for I := 0 to SL.Count - 1 do begin
      ColorDlg.CustomColors.Add ('Color' + C + '=' + SL[I]);
      inc (C);
    end;

    ColorDlg.Color := (Sender as TColorButtonUlf).Color;
    ColorDlg.Options := [cdFullOpen, cdSolidColor];

    if (ColorDlg.Execute) then begin

      (Sender as TColorButtonUlf).Color := ColorDlg.Color;
      case (Sender as TColorButtonUlf).Tag of
        1: OutputColorChange (Sender);
        2: InputColorChange (Sender);
        3: MonitorColorChange (Sender);
      end;

      SL.Clear;
      for I := 0 to ColorDlg.CustomColors.Count - 1 do begin
        SL.Add (ColorDlg.CustomColors.Values[ColorDlg.CustomColors.Names[I]]);
      end;
      Registry.WriteString ('Custom', SL.CommaText);

    end;

    Registry.CloseKey;
    Registry.free;

    SL.Free;

  finally
    ColorDlg.Free;
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

