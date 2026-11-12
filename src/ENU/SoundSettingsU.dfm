object SoundSettings: TSoundSettings
  Left = 300
  Top = 246
  AutoScroll = False
  Caption = 'Sounds'
  ClientHeight = 281
  ClientWidth = 443
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell DLG'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    443
    281)
  PixelsPerInch = 96
  TextHeight = 13
  object SoundsFormPanel: TPanel
    Left = 6
    Top = 6
    Width = 431
    Height = 227
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    FullRepaint = False
    TabOrder = 0
    Visible = False
    DesignSize = (
      431
      227)
    object GroupBoxTelegraphy: TGroupBox
      Left = 298
      Top = 6
      Width = 127
      Height = 121
      Anchors = [akTop, akRight]
      Caption = 'CW'
      Enabled = False
      TabOrder = 0
      Visible = False
      object Bevel1: TBevel
        Left = 12
        Top = 54
        Width = 103
        Height = 7
        Shape = bsTopLine
      end
      object Label4: TLabel
        Left = 12
        Top = 66
        Width = 36
        Height = 13
        Caption = 'Speed:'
        Enabled = False
      end
      object Label5: TLabel
        Left = 12
        Top = 93
        Width = 46
        Height = 13
        Caption = 'Pitch:'
        Enabled = False
      end
      object RadioButtonSoundcard: TRadioButton
        Left = 12
        Top = 18
        Width = 109
        Height = 15
        Caption = 'Soundcard'
        Checked = True
        Enabled = False
        TabOrder = 0
        TabStop = True
      end
      object RadioButtonPCSpeaker: TRadioButton
        Left = 12
        Top = 33
        Width = 109
        Height = 15
        Caption = 'PC speaker'
        Enabled = False
        TabOrder = 1
      end
      object Edit2: TEdit
        Left = 66
        Top = 63
        Width = 37
        Height = 21
        Enabled = False
        TabOrder = 2
        Text = '0'
      end
      object UpDown1: TUpDown
        Left = 103
        Top = 63
        Width = 16
        Height = 21
        Associate = Edit2
        Enabled = False
        TabOrder = 3
      end
      object Edit3: TEdit
        Left = 66
        Top = 90
        Width = 37
        Height = 21
        Enabled = False
        TabOrder = 4
        Text = '0'
      end
      object UpDown2: TUpDown
        Left = 103
        Top = 90
        Width = 16
        Height = 21
        Associate = Edit3
        Enabled = False
        TabOrder = 5
      end
    end
  end
  object StationDatabasePanel: TPanel
    Left = 6
    Top = 244
    Width = 431
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    Color = 14811135
    TabOrder = 1
    object LinkLabel: TLabel
      Left = 12
      Top = 6
      Width = 371
      Height = 13
      Cursor = crHandPoint
      Caption = 'Individual sounds can be specified in the station database.'
      Color = clInfoBk
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Shell DLG'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = True
      OnClick = LinkLabelClick
    end
  end
end
