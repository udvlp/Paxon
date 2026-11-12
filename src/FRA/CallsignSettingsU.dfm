object CallsignSettingsForm: TCallsignSettingsForm
  Left = 294
  Top = 285
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Mon indicatif'
  ClientHeight = 214
  ClientWidth = 277
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PrintScale = poNone
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object SsidLabel: TLabel
    Left = 6
    Top = 57
    Width = 175
    Height = 13
    AutoSize = False
    Caption = 'SSIDs'
  end
  object CallsignLabel: TLabel
    Left = 6
    Top = 9
    Width = 175
    Height = 13
    AutoSize = False
    Caption = 'Indicatif'
  end
  object CallsignEdit: TEdit
    Left = 6
    Top = 24
    Width = 176
    Height = 21
    AutoSize = False
    CharCase = ecUpperCase
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Fixedsys'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnChange = CallsignEditChange
  end
  object ButtonOk: TButton
    Left = 192
    Top = 24
    Width = 79
    Height = 23
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object ButtonCancelSend: TButton
    Left = 192
    Top = 54
    Width = 79
    Height = 23
    Cancel = True
    Caption = 'Annuler'
    ModalResult = 2
    TabOrder = 3
  end
  object SsidPanel: TPanel
    Left = 6
    Top = 72
    Width = 177
    Height = 137
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 1
    object Check06: TCheckBox
      Tag = 6
      Left = 48
      Top = 56
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -6'
      TabOrder = 6
    end
    object Check10: TCheckBox
      Tag = 10
      Left = 88
      Top = 56
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '-10'
      TabOrder = 10
    end
    object Check14: TCheckBox
      Tag = 14
      Left = 128
      Top = 56
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '-14'
      TabOrder = 14
    end
    object Check03: TCheckBox
      Tag = 3
      Left = 8
      Top = 80
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -3'
      TabOrder = 3
    end
    object Check08: TCheckBox
      Tag = 8
      Left = 88
      Top = 8
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -8'
      TabOrder = 8
    end
    object Check07: TCheckBox
      Tag = 7
      Left = 48
      Top = 80
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -7'
      TabOrder = 7
    end
    object Check11: TCheckBox
      Tag = 11
      Left = 88
      Top = 80
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '-11'
      TabOrder = 11
    end
    object Check15: TCheckBox
      Tag = 15
      Left = 128
      Top = 80
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '-15'
      TabOrder = 15
    end
    object Check04: TCheckBox
      Tag = 4
      Left = 48
      Top = 8
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -4'
      TabOrder = 4
    end
    object Check00: TCheckBox
      Left = 8
      Top = 8
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -0'
      TabOrder = 0
    end
    object Check05: TCheckBox
      Tag = 5
      Left = 48
      Top = 32
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -5'
      TabOrder = 5
    end
    object Check09: TCheckBox
      Tag = 9
      Left = 88
      Top = 32
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -9'
      TabOrder = 9
    end
    object Check02: TCheckBox
      Tag = 2
      Left = 8
      Top = 56
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -2'
      TabOrder = 2
    end
    object Check13: TCheckBox
      Tag = 13
      Left = 128
      Top = 32
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '-13'
      TabOrder = 13
    end
    object Check01: TCheckBox
      Tag = 1
      Left = 8
      Top = 32
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '  -1'
      TabOrder = 1
    end
    object Check12: TCheckBox
      Tag = 12
      Left = 128
      Top = 8
      Width = 35
      Height = 16
      Alignment = taLeftJustify
      Caption = '-12'
      TabOrder = 12
    end
    object ButtonAll: TButton
      Left = 6
      Top = 105
      Width = 79
      Height = 23
      Caption = '&Tous'
      TabOrder = 16
      OnClick = ButtonAllClick
    end
    object ButtonNone: TButton
      Left = 90
      Top = 105
      Width = 79
      Height = 23
      Caption = '&Aucun'
      TabOrder = 17
      OnClick = ButtonNoneClick
    end
  end
end
