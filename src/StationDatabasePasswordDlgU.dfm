object StationDatabasePasswordDlg: TStationDatabasePasswordDlg
  Left = 345
  Top = 364
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Passwort'
  ClientHeight = 223
  ClientWidth = 397
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
  object MyCallLabel: TLabel
    Left = 6
    Top = 9
    Width = 100
    Height = 13
    AutoSize = False
    Caption = '&Eigenes Rufzeichen'
    FocusControl = MyCallCombo
    Transparent = True
  end
  object PasswordKindLabel: TLabel
    Left = 138
    Top = 9
    Width = 100
    Height = 13
    AutoSize = False
    Caption = '&Art'
    FocusControl = PasswordKindCombo
    Transparent = True
  end
  object MethodLabel: TLabel
    Left = 270
    Top = 9
    Width = 100
    Height = 13
    AutoSize = False
    Caption = '&Verfahren'
    FocusControl = MethodCombo
    Transparent = True
  end
  object PasswordLabel: TLabel
    Left = 6
    Top = 57
    Width = 43
    Height = 13
    Caption = '&Passwort'
    FocusControl = PasswordMemo
    Transparent = True
  end
  object MyCallCombo: TComboBoxUlf
    Left = 6
    Top = 24
    Width = 121
    Height = 21
    CharCase = ecUpperCase
    ItemHeight = 13
    TabOrder = 0
    OnChange = MyCallComboChange
    Complete = True
  end
  object PasswordKindCombo: TComboBoxUlf
    Left = 138
    Top = 24
    Width = 121
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 1
    Complete = True
  end
  object MethodCombo: TComboBoxUlf
    Left = 270
    Top = 24
    Width = 121
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 2
    Complete = True
  end
  object PasswordMemo: TMemo
    Left = 6
    Top = 72
    Width = 385
    Height = 109
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 3
    WantReturns = False
    OnChange = PasswordMemoChange
  end
  object OkButton: TButton
    Left = 120
    Top = 192
    Width = 79
    Height = 23
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object PasswordCancelButton: TButton
    Left = 204
    Top = 192
    Width = 79
    Height = 23
    Cancel = True
    Caption = 'Abbrechen'
    ModalResult = 2
    TabOrder = 5
  end
end
