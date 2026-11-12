object DeviceSettings: TDeviceSettings
  Left = 577
  Top = 459
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Devices'
  ClientHeight = 277
  ClientWidth = 439
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
  OnShow = FormShow
  DesignSize = (
    439
    277)
  PixelsPerInch = 96
  TextHeight = 13
  object Groupbox: TGroupBox
    Left = 6
    Top = 6
    Width = 427
    Height = 265
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Device drivers'
    Ctl3D = True
    ParentCtl3D = False
    TabOrder = 0
    TabStop = True
    DesignSize = (
      427
      265)
    object PropertiesBtn: TButton
      Left = 6
      Top = 234
      Width = 79
      Height = 23
      Anchors = [akLeft, akBottom]
      Caption = '&Properties'
      TabOrder = 1
      OnClick = PropertiesBtnClick
    end
    object AddBtn: TButton
      Left = 90
      Top = 234
      Width = 79
      Height = 23
      Anchors = [akLeft, akBottom]
      Caption = '&Add'
      TabOrder = 2
      OnClick = AddBtnClick
    end
    object RemoveBtn: TButton
      Left = 174
      Top = 234
      Width = 79
      Height = 23
      Anchors = [akLeft, akBottom]
      Caption = '&Remove'
      TabOrder = 3
      OnClick = RemoveBtnClick
    end
    object Listview: TListView
      Left = 6
      Top = 18
      Width = 415
      Height = 211
      Anchors = [akLeft, akTop, akRight, akBottom]
      Columns = <
        item
          Caption = 'Device'
          Width = 80
        end
        item
          Caption = 'Parameters'
          Width = 126
        end
        item
          Caption = 'Status'
          Width = 190
        end>
      IconOptions.AutoArrange = True
      ReadOnly = True
      TabOrder = 0
      ViewStyle = vsReport
      OnDblClick = ListviewDblClick
      OnKeyDown = ListviewKeyDown
    end
    object DownBtn: TBitBtn
      Left = 290
      Top = 234
      Width = 23
      Height = 23
      Anchors = [akLeft, akBottom]
      TabOrder = 5
      OnClick = DownBtnClick
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000010000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00BBBBBBBBBBBB
        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB8BBBBBBBBBBBBBB888BBB
        BBBBBBBBB88888BBBBBBBBBB8888888BBBBBBBB888888888BBBBBB8888888888
        8BBBBBBBB88888BBBBBBBBBBB88888BBBBBBBBBBB88888BBBBBBBBBBB88888BB
        BBBBBBBBB88888BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB}
    end
    object UpBtn: TBitBtn
      Left = 264
      Top = 234
      Width = 23
      Height = 23
      Anchors = [akLeft, akBottom]
      TabOrder = 4
      OnClick = UpBtnClick
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000010000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00BBBBBBBBBBBB
        BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB88888BB
        BBBBBBBBB88888BBBBBBBBBBB88888BBBBBBBBBBB88888BBBBBBBBBBB88888BB
        BBBBBB88888888888BBBBBB888888888BBBBBBBB8888888BBBBBBBBBB88888BB
        BBBBBBBBBB888BBBBBBBBBBBBBB8BBBBBBBBBBBBBBBBBBBBBBBB}
    end
  end
end
