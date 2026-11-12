object DevicesStatus: TDevicesStatus
  Left = 326
  Top = 197
  Width = 391
  Height = 118
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  ActiveControl = Listview
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  Caption = 'Paxon - Etat des p'#233'riph'#233'riques'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  PrintScale = poNone
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Listview: TListView
    Left = 0
    Top = 0
    Width = 375
    Height = 79
    Align = alClient
    AllocBy = 1
    Columns = <
      item
        Caption = 'P'#233'riph'#233'rique'
        Width = 80
      end
      item
        Caption = 'Param'#232'tres'
        Width = 84
      end
      item
        Caption = 'Etat'
        Width = 185
      end>
    FullDrag = True
    IconOptions.AutoArrange = True
    IconOptions.WrapText = False
    ReadOnly = True
    TabOrder = 0
    ViewStyle = vsReport
  end
end
