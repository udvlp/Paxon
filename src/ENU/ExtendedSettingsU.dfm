object ExtendedSettings: TExtendedSettings
  Left = 405
  Top = 429
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Advanced'
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
    Caption = 'Station ID'
    TabOrder = 1
    object SendSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 18
      Width = 193
      Height = 15
      Caption = 'Send own station ID'
      TabOrder = 0
      OnClick = SendSIDCheckboxClick
    end
    object HideSentSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 36
      Width = 193
      Height = 15
      Caption = 'Hide sent station ID'
      TabOrder = 1
    end
    object HideReceivedSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 54
      Width = 193
      Height = 15
      Caption = 'Hide received station ID'
      TabOrder = 2
    end
  end
  object GroupBox2: TGroupBox
    Left = 6
    Top = 192
    Width = 235
    Height = 67
    Caption = 'Toolbar'
    TabOrder = 2
    object HighColorCheckbox: TMultiCheckBox
      Left = 12
      Top = 18
      Width = 214
      Height = 43
      Caption =
        'Show icons in truecolor (not compatible with all display adapter' +
        's)'
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
      Caption = 'Automatically add received public keys to keyring'
      TabOrder = 0
    end
    object PGPSimpleOutputCheckbox: TMultiCheckBox
      Left = 12
      Top = 48
      Width = 217
      Height = 31
      Caption = 'Show simplified results after checking signatures'
      TabOrder = 1
    end
  end
end
