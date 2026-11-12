object DlgSplash: TDlgSplash
  Left = 301
  Top = 259
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 221
  ClientWidth = 389
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = True
  Position = poOwnerFormCenter
  PrintScale = poNone
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object ClientPanel: TPanel
    Left = 0
    Top = 0
    Width = 389
    Height = 221
    Align = alClient
    BevelOuter = bvNone
    FullRepaint = False
    ParentColor = True
    TabOrder = 0
    object Shape: TShape
      Left = 0
      Top = 0
      Width = 389
      Height = 221
      Align = alClient
      Brush.Style = bsClear
      Pen.Width = 2
    end
    object Image: TImage
      Left = 2
      Top = 2
      Width = 385
      Height = 217
      Center = True
    end
    object StatusLabel: TLabel
      Left = 10
      Top = 201
      Width = 271
      Height = 13
      AutoSize = False
      Caption = '-'
      ShowAccelChar = False
      Transparent = True
    end
    object VersionLabel: TLabel
      Left = 58
      Top = 201
      Width = 318
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = '-'
      ShowAccelChar = False
      Transparent = True
      IsControl = True
    end
    object LabelNotForDistribution: TLabel
      Left = 59
      Top = 174
      Width = 271
      Height = 13
      Alignment = taCenter
      AutoSize = False
      ShowAccelChar = False
      Transparent = True
    end
  end
end
