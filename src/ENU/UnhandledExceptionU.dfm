object DlgUnhandledException: TDlgUnhandledException
  Left = 271
  Top = 270
  AutoScroll = False
  BorderIcons = []
  Caption = 'Unexpected Error'
  ClientHeight = 226
  ClientWidth = 385
  Color = clBtnFace
  Constraints.MinHeight = 253
  Constraints.MinWidth = 393
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = False
  PrintScale = poNone
  Scaled = False
  OnShow = FormShow
  DesignSize = (
    385
    226)
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 6
    Top = 198
    Width = 151
    Height = 23
    Anchors = [akLeft, akBottom]
    Caption = '&Ignore Error'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 162
    Top = 198
    Width = 217
    Height = 23
    Anchors = [akLeft, akRight, akBottom]
    Cancel = True
    Caption = '&Close Paxon'
    Default = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Shell Dlg'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 6
    Top = 6
    Width = 373
    Height = 187
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    Color = clWindow
    TabOrder = 2
    DesignSize = (
      373
      187)
    object Label1: TLabel
      Left = 12
      Top = 12
      Width = 349
      Height = 13
      AutoSize = False
      Caption = 'The following error has occured:'
    end
    object Label2: TLabel
      Left = 12
      Top = 30
      Width = 349
      Height = 73
      Alignment = taCenter
      Anchors = [akLeft, akTop, akRight, akBottom]
      AutoSize = False
      Caption = '-'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Shell Dlg'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      WordWrap = True
    end
    object Label3: TLabel
      Left = 12
      Top = 108
      Width = 349
      Height = 49
      Anchors = [akLeft, akRight, akBottom]
      AutoSize = False
      Caption =
        'This error could have negative effects on the operation of this ' +
        'Program. It is recommended to shutdown and restart Paxon as soon' +
        ' as possible.'
      WordWrap = True
    end
    object Button3: TButton
      Left = 59
      Top = 156
      Width = 256
      Height = 21
      Anchors = [akLeft, akRight, akBottom]
      Caption = '&Copy error message to clipboard'
      TabOrder = 0
      OnClick = Button3Click
    end
  end
end
