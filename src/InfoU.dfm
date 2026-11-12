object DlgInfo: TDlgInfo
  Left = 349
  Top = 271
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 270
  ClientWidth = 389
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PrintScale = poNone
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnMouseDown = FormMouseDown
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 389
    Height = 270
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 2
    Color = clBlack
    UseDockManager = False
    FullRepaint = False
    TabOrder = 0
    OnMouseDown = FormMouseDown
    OnMouseMove = FormMouseMove
    OnMouseUp = FormMouseUp
    object Panel2: TPanel
      Left = 2
      Top = 2
      Width = 385
      Height = 266
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 0
      OnMouseDown = FormMouseDown
      OnMouseMove = FormMouseMove
      OnMouseUp = FormMouseUp
      object ImageTitle: TImage
        Left = 32
        Top = 35
        Width = 320
        Height = 148
        Center = True
        OnMouseDown = FormMouseDown
        OnMouseMove = FormMouseMove
        OnMouseUp = FormMouseUp
      end
      object TextLine2: TLabel
        Left = 6
        Top = 186
        Width = 373
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption = 'XXX'
        ShowAccelChar = False
        Transparent = True
        Layout = tlCenter
        OnMouseDown = FormMouseDown
        OnMouseMove = FormMouseMove
        OnMouseUp = FormMouseUp
        IsControl = True
      end
      object Label2: TLabel
        Left = 6
        Top = 222
        Width = 373
        Height = 15
        Alignment = taCenter
        AutoSize = False
        Caption =
          'Copyright '#169' 1996-2026 by Ulf Haueisen (dg1faz), Frankfurt, Germa' +
          'ny'
        ShowAccelChar = False
        Transparent = True
        Layout = tlCenter
        OnMouseDown = FormMouseDown
        OnMouseMove = FormMouseMove
        OnMouseUp = FormMouseUp
        IsControl = True
      end
    end
  end
end
