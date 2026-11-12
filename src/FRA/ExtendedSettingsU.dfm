object ExtendedSettings: TExtendedSettings
  Left = 405
  Top = 429
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Avanc'#233
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
    Caption = 'ID de la Station'
    TabOrder = 1
    object SendSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 18
      Width = 193
      Height = 15
      Caption = 'Envoyer la propre ID de station'
      TabOrder = 0
      OnClick = SendSIDCheckboxClick
    end
    object HideSentSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 36
      Width = 193
      Height = 15
      Caption = 'Cacher l''affichage de l''ID de la station envoy'#233
      TabOrder = 1
    end
    object HideReceivedSIDCheckbox: TMultiCheckBox
      Left = 12
      Top = 54
      Width = 193
      Height = 15
      Caption = 'Cacher l''affichage de l''ID de la station re'#231'u'
      TabOrder = 2
    end
  end
  object GroupBox2: TGroupBox
    Left = 6
    Top = 192
    Width = 235
    Height = 67
    Caption = 'Barre d''outils'
    TabOrder = 2
    object HighColorCheckbox: TMultiCheckBox
      Left = 12
      Top = 18
      Width = 214
      Height = 43
      Caption =
        'Afficher les ic'#244'nes en couleurs vraies (non compatible avec tout' +
        'es les cartes graphiques)'
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
      Caption = 'Ajouter automatiquement la cl'#233' publique '#224' la liste des cl'#233's'
      TabOrder = 0
    end
    object PGPSimpleOutputCheckbox: TMultiCheckBox
      Left = 12
      Top = 48
      Width = 217
      Height = 31
      Caption =
        'Affichage simplifi'#233' des r'#233'sultats apres v'#233'rification des signatu' +
        'res'
      TabOrder = 1
    end
  end
end
