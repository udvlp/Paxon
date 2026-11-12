object HostmodeSerialDeviceSettingsForm: THostmodeSerialDeviceSettingsForm
  Left = 298
  Top = 152
  ActiveControl = PortComboBox
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Hostmode - Eigenschaften'
  ClientHeight = 286
  ClientWidth = 403
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  KeyPreview = True
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
      Caption = 'Hostmode'
      object DeInitLabel: TLabel
        Left = 198
        Top = 69
        Width = 169
        Height = 13
        AutoSize = False
        Caption = '&Deinitialisierung'
        FocusControl = DeInitMemo
      end
      object InitLabel: TLabel
        Left = 12
        Top = 69
        Width = 169
        Height = 13
        AutoSize = False
        Caption = '&Initialisierung'
        FocusControl = InitMemo
      end
      object BaudrateLabel: TLabel
        Left = 102
        Top = 15
        Width = 73
        Height = 13
        AutoSize = False
        Caption = '&Baudrate'
        FocusControl = BaudrateComboBox
      end
      object PortLabel: TLabel
        Left = 12
        Top = 15
        Width = 69
        Height = 13
        AutoSize = False
        Caption = '&Anschluss'
        FocusControl = PortComboBox
      end
      object DeInitMemo: TMemo
        Left = 198
        Top = 84
        Width = 169
        Height = 121
        ScrollBars = ssBoth
        TabOrder = 3
      end
      object InitMemo: TMemo
        Left = 12
        Top = 84
        Width = 169
        Height = 121
        ScrollBars = ssBoth
        TabOrder = 2
      end
      object BaudrateComboBox: TComboBox
        Left = 102
        Top = 30
        Width = 73
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 1
      end
      object PortComboBox: TComboBox
        Left = 12
        Top = 30
        Width = 73
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 0
      end
    end
  end
  object BtnOk: TButton
    Left = 234
    Top = 258
    Width = 79
    Height = 23
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object BtnCancelDialog: TButton
    Left = 318
    Top = 258
    Width = 79
    Height = 23
    Cancel = True
    Caption = 'Abbrechen'
    ModalResult = 2
    TabOrder = 2
    TabStop = False
  end
end
