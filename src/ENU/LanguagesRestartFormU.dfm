object LanguagesRestartForm: TLanguagesRestartForm
  Left = 338
  Top = 224
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Paxon'
  ClientHeight = 147
  ClientWidth = 259
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
    Width = 247
    Height = 26
    AutoSize = False
    Caption = 'Sie m'#252'ssen Paxon neu starten, um die neue Sprache zu aktivieren.'
    WordWrap = True
  end
  object Label2: TLabel
    Left = 6
    Top = 48
    Width = 247
    Height = 26
    AutoSize = False
    Caption = 'You have to restart Paxon to activate the new language.'
    WordWrap = True
  end
  object Label3: TLabel
    Left = 6
    Top = 84
    Width = 247
    Height = 26
    AutoSize = False
    Caption = 
      'Veuillez red'#233'marrer Paxon afin que la nouvelle langue soit dispo' +
      'nible.'
    WordWrap = True
  end
  object OkButton: TButton
    Left = 90
    Top = 120
    Width = 79
    Height = 23
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
end
