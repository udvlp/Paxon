object DisplaySettings: TDisplaySettings
  Left = 410
  Top = 280
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Anzeige'
  ClientHeight = 281
  ClientWidth = 443
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = False
  PrintScale = poNone
  OnCreate = FormCreate
  DesignSize = (
    443
    281)
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox: TGroupBox
    Left = 6
    Top = 6
    Width = 431
    Height = 269
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Anzeige'
    TabOrder = 0
    DesignSize = (
      431
      269)
    object FontLabel: TLabel
      Left = 6
      Top = 225
      Width = 85
      Height = 13
      Anchors = [akLeft, akBottom]
      AutoSize = False
      Caption = 'Schriftgr'#246#223'e'
      Transparent = True
    end
    object ExampleLabel: TLabel
      Left = 222
      Top = 22
      Width = 133
      Height = 13
      AutoSize = False
      Caption = 'Beispiel'
      Transparent = True
    end
    object FontCombobox: TComboBox
      Left = 6
      Top = 240
      Width = 205
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akBottom]
      ItemHeight = 13
      TabOrder = 1
      OnChange = FontComboBoxChange
    end
    object ExamplePanel: TPanel
      Left = 222
      Top = 37
      Width = 203
      Height = 224
      Anchors = [akLeft, akTop, akRight, akBottom]
      BevelOuter = bvNone
      BorderStyle = bsSingle
      TabOrder = 2
      object ExampleConsole: TConsole
        Left = 0
        Top = 0
        Width = 199
        Height = 220
        Align = alClient
        ParentColor = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Fixedsys'
        Font.Style = []
        LineBreak = CR
        Active = True
        VirtualMemory = False
        ShowDOS = False
        TabOrder = 0
      end
    end
    object PageControl: TPageControl
      Left = 6
      Top = 18
      Width = 205
      Height = 205
      ActivePage = TabSheet1
      TabOrder = 0
      OnChange = PageControlChange
      object TabSheet1: TTabSheet
        Caption = 'Ausgabe'
        object Label5: TLabel
          Left = 42
          Top = 122
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Hintergrund'
          Transparent = True
        end
        object Label4: TLabel
          Left = 42
          Top = 83
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Lokale Meldungen'
          Transparent = True
        end
        object Label3: TLabel
          Left = 42
          Top = 59
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Verbindungsstatus'
          Transparent = True
        end
        object Label2: TLabel
          Left = 42
          Top = 35
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Gesendeter Text'
          Transparent = True
        end
        object Label1: TLabel
          Left = 42
          Top = 11
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Empfangener Text'
          Transparent = True
        end
        object Bevel1: TBevel
          Left = 2
          Top = 108
          Width = 193
          Height = 3
          Shape = bsTopLine
        end
        object ColorButtonA1: TColorButtonUlf
          Tag = 1
          Left = 6
          Top = 6
          Width = 31
          Height = 23
          TabOrder = 0
          OnClick = ColorClick
          Color = clWhite
        end
        object OutputStandardButton: TButton
          Left = 90
          Top = 150
          Width = 103
          Height = 23
          Caption = 'Standardfarben'
          TabOrder = 5
          OnClick = OutputStandardButtonClick
        end
        object ColorButtonAB: TColorButtonUlf
          Tag = 1
          Left = 6
          Top = 117
          Width = 31
          Height = 23
          TabOrder = 4
          OnClick = ColorClick
          Color = clWhite
        end
        object ColorButtonA4: TColorButtonUlf
          Tag = 1
          Left = 6
          Top = 78
          Width = 31
          Height = 23
          Caption = 'Nachricht zum L'#246'schen markieren'
          TabOrder = 3
          OnClick = ColorClick
          Color = clWhite
        end
        object ColorButtonA3: TColorButtonUlf
          Tag = 1
          Left = 6
          Top = 54
          Width = 31
          Height = 23
          TabOrder = 2
          OnClick = ColorClick
          Color = clWhite
        end
        object ColorButtonA2: TColorButtonUlf
          Tag = 1
          Left = 6
          Top = 30
          Width = 31
          Height = 23
          TabOrder = 1
          OnClick = ColorClick
          Color = clWhite
        end
      end
      object TabSheet3: TTabSheet
        Caption = 'Eingabe'
        ImageIndex = 2
        object Label10: TLabel
          Left = 42
          Top = 73
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Hintergrund'
          Transparent = True
        end
        object Label6: TLabel
          Left = 42
          Top = 11
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Neuer Text'
          Transparent = True
        end
        object Label7: TLabel
          Left = 42
          Top = 35
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Gesendeter Text'
          Transparent = True
        end
        object Bevel2: TBevel
          Left = 2
          Top = 60
          Width = 193
          Height = 3
          Shape = bsTopLine
        end
        object ColorButtonE2: TColorButtonUlf
          Tag = 2
          Left = 6
          Top = 30
          Width = 31
          Height = 23
          TabOrder = 1
          OnClick = ColorClick
          Color = clWhite
        end
        object ColorButtonE1: TColorButtonUlf
          Tag = 2
          Left = 6
          Top = 6
          Width = 31
          Height = 23
          TabOrder = 0
          OnClick = ColorClick
          Color = clWhite
        end
        object ColorButtonEB: TColorButtonUlf
          Tag = 2
          Left = 6
          Top = 69
          Width = 31
          Height = 23
          TabOrder = 2
          OnClick = ColorClick
          Color = clWhite
        end
        object InputStandardButton: TButton
          Left = 90
          Top = 150
          Width = 103
          Height = 23
          Caption = 'Standardfarben'
          TabOrder = 3
          OnClick = InputStandardButtonClick
        end
      end
      object TabSheet2: TTabSheet
        Caption = 'Monitor'
        ImageIndex = 1
        object Label11: TLabel
          Left = 42
          Top = 11
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Kopfzeile (empfangen)'
          Transparent = True
        end
        object Label12: TLabel
          Left = 42
          Top = 59
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Daten'
          Transparent = True
        end
        object Label15: TLabel
          Left = 42
          Top = 122
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Hintergrund'
          Transparent = True
        end
        object Label8: TLabel
          Left = 42
          Top = 35
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Kopfzeile (gesendet)'
          Transparent = True
        end
        object Bevel3: TBevel
          Left = 2
          Top = 108
          Width = 193
          Height = 3
          Shape = bsTopLine
        end
        object Label9: TLabel
          Left = 42
          Top = 83
          Width = 151
          Height = 13
          AutoSize = False
          Caption = 'Lokale Meldungen'
          Transparent = True
        end
        object ColorButtonM3: TColorButtonUlf
          Tag = 3
          Left = 6
          Top = 54
          Width = 31
          Height = 23
          TabOrder = 2
          OnClick = ColorClick
          Color = clWhite
        end
        object ColorButtonM1: TColorButtonUlf
          Tag = 3
          Left = 6
          Top = 6
          Width = 31
          Height = 23
          TabOrder = 0
          OnClick = ColorClick
          Color = clWhite
        end
        object ColorButtonM2: TColorButtonUlf
          Tag = 3
          Left = 6
          Top = 30
          Width = 31
          Height = 23
          TabOrder = 1
          OnClick = ColorClick
          Color = clWhite
        end
        object ColorButtonMB: TColorButtonUlf
          Tag = 3
          Left = 6
          Top = 117
          Width = 31
          Height = 23
          TabOrder = 3
          OnClick = ColorClick
          Color = clWhite
        end
        object MonitorStandardButton: TButton
          Left = 90
          Top = 150
          Width = 103
          Height = 23
          Caption = 'Standardfarben'
          TabOrder = 4
          OnClick = MonitorStandardButtonClick
        end
        object ColorButtonM4: TColorButtonUlf
          Tag = 3
          Left = 6
          Top = 78
          Width = 31
          Height = 23
          TabOrder = 5
          OnClick = ColorClick
          Color = clWhite
        end
      end
    end
  end
end
