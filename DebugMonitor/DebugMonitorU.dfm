object MainForm: TMainForm
  Left = 708
  Top = 180
  ActiveControl = Console
  Anchors = [akTop, akRight]
  AutoScroll = False
  BorderIcons = [biSystemMenu, biMinimize]
  ClientHeight = 482
  ClientWidth = 320
  Color = clBtnFace
  Constraints.MinHeight = 64
  Constraints.MinWidth = 128
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  PrintScale = poNone
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Console: TConsole
    Left = 0
    Top = 0
    Width = 320
    Height = 482
    Align = alClient
    ParentColor = False
    Font.Charset = OEM_CHARSET
    Font.Color = clWindowText
    Font.Height = -8
    Font.Name = 'Terminal'
    Font.Pitch = fpFixed
    Font.Style = []
    Cols = 200
    Rows = 5000
    LineBreak = CR
    Active = True
    VirtualMemory = True
    ShowDOS = False
    TabStop = True
    TabOrder = 0
  end
end
