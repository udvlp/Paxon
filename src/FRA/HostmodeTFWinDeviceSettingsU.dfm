object HostmodeTFWinDeviceSettingsForm: THostmodeTFWinDeviceSettingsForm
  Left = 298
  Top = 152
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Propri'#233't'#233's TFWin'
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
      Caption = 'TFWin'
      object PanelUlf1: TPanelUlf
        Left = 0
        Top = 0
        Width = 383
        Height = 219
        Align = alClient
        BevelOuter = bvNone
        FullRepaint = False
        TabOrder = 0
        object InitLabel: TLabel
          Left = 12
          Top = 15
          Width = 169
          Height = 13
          AutoSize = False
          Caption = '&Initialisation'
          FocusControl = InitMemo
          Transparent = True
        end
        object DeInitLabel: TLabel
          Left = 198
          Top = 15
          Width = 169
          Height = 13
          AutoSize = False
          Caption = '&D'#233'sinitialisation'
          FocusControl = DeInitMemo
          Transparent = True
        end
        object InitMemo: TMemo
          Left = 12
          Top = 30
          Width = 169
          Height = 169
          ScrollBars = ssBoth
          TabOrder = 0
        end
        object DeInitMemo: TMemo
          Left = 198
          Top = 30
          Width = 169
          Height = 169
          ScrollBars = ssBoth
          TabOrder = 1
        end
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
    Caption = 'Annuler'
    ModalResult = 2
    TabOrder = 2
    TabStop = False
  end
end
