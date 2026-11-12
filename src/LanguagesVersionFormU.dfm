object LanguagesVersionForm: TLanguagesVersionForm
  Left = 338
  Top = 224
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Paxon'
  ClientHeight = 123
  ClientWidth = 331
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 6
    Top = 12
    Width = 319
    Height = 26
    AutoSize = False
    Caption = 
      'Die gew'#252'nschte Sprache kann nicht geladen werden. Die Version de' +
      'r Ressourcen-Datei passt nicht zum Hauptprogramm.'
    WordWrap = True
  end
  object Label2: TLabel
    Left = 6
    Top = 54
    Width = 319
    Height = 26
    AutoSize = False
    Caption = 
      'Cannot load the selected language. The version of the language r' +
      'esource does not match the main program.'
    WordWrap = True
  end
  object OkButton: TButton
    Left = 126
    Top = 96
    Width = 79
    Height = 23
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
end
