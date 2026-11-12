object TextSettings: TTextSettings
  Left = 576
  Top = 246
  AutoScroll = False
  Caption = 'Texts'
  ClientHeight = 281
  ClientWidth = 443
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell DLG'
  Font.Style = []
  OldCreateOrder = True
  OnCreate = FormCreate
  DesignSize = (
    443
    281)
  PixelsPerInch = 96
  TextHeight = 13
  object StationDatabasePanel: TPanel
    Left = 6
    Top = 244
    Width = 431
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    Color = 14811135
    TabOrder = 0
    object LinkLabel: TLabel
      Left = 12
      Top = 6
      Width = 365
      Height = 13
      Caption = 'Individual texts can be specified in the station database.'
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
