object TextsForm: TTextsForm
  Left = 310
  Top = 221
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 115
  ClientWidth = 193
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  DesignSize = (
    193
    115)
  PixelsPerInch = 96
  TextHeight = 13
  object EventGroupbox: TGroupBox
    Left = 0
    Top = 0
    Width = 193
    Height = 115
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Texts'
    TabOrder = 0
    TabStop = True
    DesignSize = (
      193
      115)
    object TextKindCombobox: TComboBox
      Left = 6
      Top = 18
      Width = 182
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      DropDownCount = 10
      ItemHeight = 13
      TabOrder = 0
      OnChange = TextKindComboboxChange
    end
    object AfterDefaultTextCheckbox: TCheckBox
      Left = 6
      Top = 95
      Width = 265
      Height = 14
      Anchors = [akLeft, akBottom]
      Caption = '&Send default text before'
      TabOrder = 1
    end
    object TextMemo: TMemo
      Left = 6
      Top = 48
      Width = 182
      Height = 42
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Paxon 08x12'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 2
      WordWrap = False
    end
  end
end
