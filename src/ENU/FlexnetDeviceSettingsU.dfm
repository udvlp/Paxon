object FlexnetDeviceSettingsForm: TFlexnetDeviceSettingsForm
  Left = 579
  Top = 278
  ActiveControl = ListBox
  BorderStyle = bsDialog
  Caption = 'PC/FlexNet - Properties'
  ClientHeight = 285
  ClientWidth = 404
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = True
  Position = poOwnerFormCenter
  PrintScale = poNone
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 6
    Top = 6
    Width = 391
    Height = 247
    ActivePage = TabSheet
    TabOrder = 0
    object TabSheet: TTabSheet
      Caption = 'PC/FlexNet'
      object Label1: TLabel
        Left = 24
        Top = 56
        Width = 33
        Height = 13
        Caption = 'Channels'
      end
      object HeadingLabel: TLabel
        Left = 24
        Top = 24
        Width = 345
        Height = 31
        AutoSize = False
        Caption = 'Version'
        WordWrap = True
      end
      object ListBox: TListBox
        Left = 24
        Top = 72
        Width = 337
        Height = 116
        ItemHeight = 13
        TabOrder = 0
      end
    end
  end
  object Form_BtnOk: TButton
    Left = 234
    Top = 258
    Width = 79
    Height = 23
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object Form_BtnCancel: TButton
    Left = 318
    Top = 258
    Width = 79
    Height = 23
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
    TabStop = False
  end
end
