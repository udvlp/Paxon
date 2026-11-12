object StationDatabaseEditDlg: TStationDatabaseEditDlg
  Left = 308
  Top = 270
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Nouvel indicatif...'
  ClientHeight = 90
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
  object Button1: TButton
    Left = 6
    Top = 63
    Width = 79
    Height = 23
    Caption = 'Ok'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object Button2: TButton
    Left = 90
    Top = 63
    Width = 79
    Height = 23
    Cancel = True
    Caption = 'Annuler'
    ModalResult = 2
    TabOrder = 2
  end
  object GroupBoxXP1: TGroupBox
    Left = 6
    Top = 6
    Width = 163
    Height = 52
    Caption = 'Indicatif'
    TabOrder = 0
    object CallsignEdit: TEdit
      Left = 6
      Top = 18
      Width = 151
      Height = 23
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
end
