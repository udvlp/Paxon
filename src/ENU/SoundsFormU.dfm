object SoundsForm: TSoundsForm
  Left = 391
  Top = 297
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 226
  ClientWidth = 291
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  DesignSize = (
    291
    226)
  PixelsPerInch = 96
  TextHeight = 13
  object EventGroupbox: TGroupBox
    Left = 0
    Top = 0
    Width = 291
    Height = 226
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Events'
    TabOrder = 0
    TabStop = True
    DesignSize = (
      291
      226)
    object EventLabel: TLabel
      Left = 14
      Top = 24
      Width = 47
      Height = 13
      AutoSize = False
      Caption = '&Event'
      FocusControl = EventComboBox
      Transparent = True
    end
    object EventComboBox: TComboBox
      Left = 60
      Top = 20
      Width = 225
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      DropDownCount = 40
      ItemHeight = 13
      TabOrder = 0
      OnChange = EventComboBoxChange
    end
    object SoundGroupBox: TGroupBox
      Left = 6
      Top = 48
      Width = 279
      Height = 94
      Anchors = [akLeft, akTop, akRight]
      Caption = '&Sound'
      TabOrder = 1
      DesignSize = (
        279
        94)
      object SoundNoneRadioButton: TRadioButton
        Left = 12
        Top = 18
        Width = 113
        Height = 15
        Caption = 'None'
        Checked = True
        TabOrder = 0
        TabStop = True
        OnClick = SoundRadioButtonClick
      end
      object SoundPCSpeakerRadioButton: TRadioButton
        Left = 12
        Top = 33
        Width = 113
        Height = 15
        Caption = 'PC speaker'
        TabOrder = 1
        TabStop = True
        OnClick = SoundRadioButtonClick
      end
      object SoundWaveRadioButton: TRadioButton
        Left = 12
        Top = 48
        Width = 113
        Height = 15
        Caption = 'Wave File'
        TabOrder = 2
        OnClick = SoundRadioButtonClick
      end
      object SoundWaveEdit: TEdit
        Left = 30
        Top = 66
        Width = 195
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 3
      end
      object SoundWaveBrowseButton: TButton
        Left = 250
        Top = 67
        Width = 19
        Height = 19
        Anchors = [akTop, akRight]
        Caption = '...'
        TabOrder = 5
        OnClick = SoundWaveBrowseButtonClick
      end
      object SoundWavePlayButton: TBitBtn
        Left = 228
        Top = 67
        Width = 19
        Height = 19
        Anchors = [akTop, akRight]
        TabOrder = 4
        OnClick = SoundWavePlayButtonClick
        Glyph.Data = {
          BE000000424DBE00000000000000760000002800000010000000090000000100
          0400000000004800000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
          8888880888888878888888008888887788888800088888777888880000888877
          7788880008888877788888008888887788888808888888788888888888888888
          8888}
        NumGlyphs = 2
      end
      object SoundCheckBox: TCheckBox
        Left = 8
        Top = 0
        Width = 127
        Height = 14
        Caption = 'Specific &Sound'
        TabOrder = 6
        OnClick = SoundCheckBoxClick
      end
    end
    object AnnouncementGroupBox: TGroupBox
      Left = 6
      Top = 147
      Width = 183
      Height = 73
      Anchors = [akLeft, akTop, akRight]
      Caption = '&Announcement'
      TabOrder = 2
      Visible = False
      object AnnouncementNoneRadioButton: TRadioButton
        Left = 12
        Top = 18
        Width = 113
        Height = 15
        Caption = 'None'
        Checked = True
        TabOrder = 1
        TabStop = True
      end
      object AnnouncementVoiceRadioButton: TRadioButton
        Left = 12
        Top = 33
        Width = 113
        Height = 15
        Caption = 'Voice'
        Enabled = False
        TabOrder = 2
      end
      object AnnouncementTelegraphyRadioButton: TRadioButton
        Left = 12
        Top = 48
        Width = 113
        Height = 15
        Caption = 'CW'
        Enabled = False
        TabOrder = 3
      end
      object AnnouncementCheckBox: TCheckBox
        Left = 8
        Top = 0
        Width = 135
        Height = 14
        Caption = 'Specific &Announcement'
        TabOrder = 0
        OnClick = AnnouncementCheckBoxClick
      end
    end
    object SchemaGroupBox: TGroupBox
      Left = 194
      Top = 147
      Width = 91
      Height = 73
      Anchors = [akTop, akRight]
      Caption = 'Scheme'
      TabOrder = 3
      object SchemeLoadButton: TButton
        Left = 6
        Top = 18
        Width = 79
        Height = 23
        Caption = 'Load...'
        TabOrder = 0
        OnClick = SchemeLoadButtonClick
      end
      object SchemeSaveButton: TButton
        Left = 6
        Top = 45
        Width = 79
        Height = 23
        Caption = 'Save...'
        TabOrder = 1
        OnClick = SchemeSaveButtonClick
      end
    end
    object GroupBox1: TGroupBox
      Left = 6
      Top = 147
      Width = 183
      Height = 73
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 4
    end
  end
end
