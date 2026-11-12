object FileSettings: TFileSettings
  Left = 515
  Top = 367
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Fichiers'
  ClientHeight = 281
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
  DesignSize = (
    443
    281)
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 6
    Top = 6
    Width = 431
    Height = 97
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Dossier'
    TabOrder = 0
    DesignSize = (
      431
      97)
    object ReceptionLabel: TLabel
      Left = 12
      Top = 27
      Width = 74
      Height = 13
      AutoSize = False
      Caption = '&Sauvegarde'
      FocusControl = ReceptionEdit
      Transparent = True
    end
    object RemoteLabel: TLabel
      Left = 12
      Top = 63
      Width = 74
      Height = 13
      AutoSize = False
      Caption = '&T'#233'l'#233'commande'
      FocusControl = RemoteEdit
      Transparent = True
    end
    object ReceptionEdit: TEdit
      Left = 88
      Top = 24
      Width = 307
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object RemoteEdit: TEdit
      Left = 88
      Top = 60
      Width = 307
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
    object ReceptionBtn: TButton
      Left = 400
      Top = 24
      Width = 21
      Height = 21
      Anchors = [akTop, akRight]
      Caption = '...'
      TabOrder = 2
      OnClick = BrowseFolderBtnClick
    end
    object RemoteBtn: TButton
      Left = 400
      Top = 60
      Width = 21
      Height = 21
      Anchors = [akTop, akRight]
      Caption = '...'
      TabOrder = 3
      OnClick = BrowseFolderBtnClick
    end
  end
  object GroupBox2: TGroupBox
    Left = 6
    Top = 210
    Width = 431
    Height = 61
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Transfert de fichiers'
    TabOrder = 1
    Visible = False
    object TransferProgressCheckbox: TCheckBox
      Left = 12
      Top = 26
      Width = 241
      Height = 16
      Caption = 'Nouvelle fen'#234'tre pour le transfert de fichiers'
      Enabled = False
      TabOrder = 0
    end
  end
end
