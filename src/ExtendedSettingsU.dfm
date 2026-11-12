object ExtendedSettings: TExtendedSettings
  Left = 405
  Top = 429
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Erweitert'
  ClientHeight = 277
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
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 6
    Top = 102
    Width = 235
    Height = 79
    Caption = 'Stations-ID'
    TabOrder = 1
    object SendSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 18
      Width = 193
      Height = 15
      Caption = 'Eigene Stations-ID senden'
      TabOrder = 0
      OnClick = SendSIDCheckboxClick
    end
    object HideSentSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 36
      Width = 193
      Height = 15
      Caption = 'Gesendete Stations-ID verbergen'
      TabOrder = 1
    end
    object HideReceivedSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 54
      Width = 193
      Height = 15
      Caption = 'Empfangene Stations-ID verbergen'
      TabOrder = 2
    end
  end
  object GroupBox2: TGroupBox
    Left = 6
    Top = 192
    Width = 235
    Height = 67
    Caption = 'Befehlsleiste'
    TabOrder = 2
    object HighColorCheckbox: TMultiCheckBox
      Left = 12
      Top = 18
      Width = 214
      Height = 43
      Caption = 
        'Symbole in Echtfarben anzeigen (nicht mit allen Grafikkartentrei' +
        'bern kompatibel)'
      TabOrder = 0
      OnClick = SendSIDCheckboxClick
    end
  end
  object PGPGroupbox: TGroupBox
    Left = 6
    Top = 6
    Width = 235
    Height = 85
    Caption = 'PGP'
    TabOrder = 0
    object PGPCollectPublicKeysCheckbox: TMultiCheckBox
      Left = 12
      Top = 18
      Width = 217
      Height = 30
      Caption = #214'ffentliche Schl'#252'ssel automatisch zum Schl'#252'sselring hinzuf'#252'gen'
      TabOrder = 0
    end
    object PGPSimpleOutputCheckbox: TMultiCheckBox
      Left = 12
      Top = 48
      Width = 217
      Height = 31
      Caption = 'Vereinfachte Ergebnisse von Signatur- pr'#252'fungen anzeigen'
      TabOrder = 1
    end
  end
end
