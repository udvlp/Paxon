object DlgCommand: TDlgCommand
  Left = 281
  Top = 396
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Commande'
  ClientHeight = 121
  ClientWidth = 150
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = True
  Position = poOwnerFormCenter
  PrintScale = poNone
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 6
    Top = 75
    Width = 137
    Height = 2
    Shape = bsTopLine
  end
  object ConnectBtn: TButton
    Left = 36
    Top = 12
    Width = 79
    Height = 23
    Caption = '&Connecter'
    ModalResult = 1
    TabOrder = 0
    OnClick = ConnectBtnClick
  end
  object DisconnectBtn: TButton
    Left = 36
    Top = 42
    Width = 79
    Height = 23
    Caption = '&D'#233'connecter'
    TabOrder = 1
    OnClick = DisconnectBtnClick
  end
  object CancelDialogBtn: TButton
    Left = 36
    Top = 87
    Width = 79
    Height = 23
    Cancel = True
    Caption = 'Annuler'
    ModalResult = 2
    TabOrder = 2
  end
end
