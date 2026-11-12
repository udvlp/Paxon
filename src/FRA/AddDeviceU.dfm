object AddDeviceForm: TAddDeviceForm
  Left = 401
  Top = 237
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Ajouter un p'#233'riph'#233'rique'
  ClientHeight = 127
  ClientWidth = 175
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PrintScale = poNone
  PixelsPerInch = 96
  TextHeight = 13
  object BtnOk: TButton
    Left = 6
    Top = 102
    Width = 79
    Height = 23
    Caption = '&Ajouter'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object BtnCancelDialog: TButton
    Left = 90
    Top = 102
    Width = 79
    Height = 23
    Cancel = True
    Caption = '&Annuler'
    ModalResult = 2
    TabOrder = 2
    TabStop = False
  end
  object ListBox: TListBox
    Left = 6
    Top = 6
    Width = 165
    Height = 91
    Style = lbOwnerDrawFixed
    ItemHeight = 15
    TabOrder = 0
    OnDblClick = ListBoxDblClick
  end
end
