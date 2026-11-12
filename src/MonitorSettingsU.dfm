object MonitorSettings: TMonitorSettings
  Left = 422
  Top = 209
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Monitor'
  ClientHeight = 273
  ClientWidth = 435
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
    435
    273)
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox: TGroupBox
    Left = 6
    Top = 6
    Width = 423
    Height = 260
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Monitor'
    TabOrder = 0
    DesignSize = (
      423
      260)
    object ExampleLabel: TLabel
      Left = 6
      Top = 120
      Width = 133
      Height = 13
      AutoSize = False
      Caption = 'Beispiel'
      Transparent = True
    end
    object Bevel1: TBevel
      Left = 211
      Top = 12
      Width = 2
      Height = 95
      Shape = bsLeftLine
    end
    object CheckBoxUnproto: TCheckBox
      Left = 6
      Top = 72
      Width = 200
      Height = 16
      Caption = 'Unnumbered Information (UI)'
      State = cbGrayed
      TabOrder = 3
      OnClick = ChangeExample
    end
    object CheckBoxInformation: TCheckBox
      Left = 6
      Top = 18
      Width = 200
      Height = 16
      Caption = 'Information (I)'
      State = cbGrayed
      TabOrder = 0
      OnClick = CheckBoxInformationClick
    end
    object CheckBoxInformationContent: TCheckBox
      Left = 18
      Top = 36
      Width = 169
      Height = 16
      Caption = 'Inhalt'
      State = cbGrayed
      TabOrder = 1
      OnClick = CheckBoxInformationContentClick
    end
    object CheckBoxInformationBinary: TCheckBox
      Left = 30
      Top = 54
      Width = 157
      Height = 16
      Caption = 'Bin'#228'rdaten'
      State = cbGrayed
      TabOrder = 2
      OnClick = ChangeExample
    end
    object CheckBoxLocal: TCheckBox
      Left = 216
      Top = 18
      Width = 200
      Height = 16
      Caption = 'Lokale Meldungen'
      State = cbGrayed
      TabOrder = 5
      OnClick = ChangeExample
    end
    object CheckBoxStatus: TCheckBox
      Left = 6
      Top = 90
      Width = 200
      Height = 16
      Caption = 'Status (SABM, UA, DM, RR, REJ...)'
      State = cbGrayed
      TabOrder = 4
      OnClick = ChangeExample
    end
    object ExamplePanel: TPanel
      Left = 6
      Top = 135
      Width = 411
      Height = 118
      Anchors = [akLeft, akTop, akRight, akBottom]
      BevelOuter = bvNone
      BorderStyle = bsSingle
      TabOrder = 6
      object ExampleConsole: TConsole
        Left = 0
        Top = 0
        Width = 407
        Height = 114
        Align = alClient
        ParentColor = False
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Paxon 07x09'
        Font.Style = []
        LineBreak = CR
        Active = True
        VirtualMemory = False
        ShowDOS = False
        TabOrder = 0
      end
    end
    object CheckBoxPortnumber: TCheckBox
      Left = 216
      Top = 36
      Width = 200
      Height = 16
      Caption = 'Kanalnummer anzeigen'
      State = cbGrayed
      TabOrder = 7
      OnClick = ChangeExample
    end
  end
end
