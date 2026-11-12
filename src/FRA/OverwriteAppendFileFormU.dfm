object OverwriteAppendFileForm: TOverwriteAppendFileForm
  Left = 371
  Top = 201
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Enregistrer'
  ClientHeight = 129
  ClientWidth = 289
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = True
  Position = poOwnerFormCenter
  PrintScale = poNone
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 289
    Height = 99
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 24
      Top = 13
      Width = 241
      Height = 73
      Alignment = taCenter
      AutoSize = False
      Caption = '...'
      Layout = tlCenter
      WordWrap = True
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 99
    Width = 289
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object Button1: TButton
      Left = 12
      Top = 0
      Width = 85
      Height = 23
      Caption = '&Ecraser'
      ModalResult = 6
      TabOrder = 2
    end
    object Button2: TButton
      Left = 102
      Top = 0
      Width = 85
      Height = 23
      Caption = '&Attacher'
      Default = True
      ModalResult = 7
      TabOrder = 0
    end
    object Button3: TButton
      Left = 192
      Top = 0
      Width = 85
      Height = 23
      Cancel = True
      Caption = 'Annuler'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
