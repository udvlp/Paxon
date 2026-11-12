object DlgConnectCommand: TDlgConnectCommand
  Left = 263
  Top = 187
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Connecter'
  ClientHeight = 201
  ClientWidth = 348
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell DLG'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PrintScale = poNone
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel: TPanel
    Left = 54
    Top = 6
    Width = 289
    Height = 157
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 0
    object LabelStation: TLabel
      Left = 6
      Top = 12
      Width = 130
      Height = 13
      AutoSize = False
      Caption = 'Station'
    end
    object Label2: TLabel
      Left = 120
      Top = 60
      Width = 130
      Height = 13
      AutoSize = False
      Caption = 'Canaux'
    end
    object Label3: TLabel
      Left = 6
      Top = 60
      Width = 103
      Height = 13
      AutoSize = False
      Caption = 'Mon indicatif'
    end
    object PortListView: TListView
      Left = 120
      Top = 75
      Width = 162
      Height = 75
      Columns = <
        item
          AutoSize = True
        end>
      ColumnClick = False
      HideSelection = False
      ReadOnly = True
      ShowColumnHeaders = False
      TabOrder = 2
      ViewStyle = vsReport
    end
    object CallCombo: TComboBoxUlf
      Left = 6
      Top = 27
      Width = 277
      Height = 23
      CharCase = ecUpperCase
      DropDownCount = 10
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Fixedsys'
      Font.Style = []
      ItemHeight = 0
      ParentFont = False
      TabOrder = 0
      OnChange = CallComboChange
      Complete = True
      OnComplete = CallComboComplete
    end
    object MyCallCombo: TComboBoxUlf
      Left = 6
      Top = 75
      Width = 103
      Height = 23
      CharCase = ecUpperCase
      DropDownCount = 10
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Fixedsys'
      Font.Style = []
      ItemHeight = 0
      ParentFont = False
      TabOrder = 1
      OnChange = MyCallComboChange
      Complete = True
    end
  end
  object PanelBottom: TPanel
    Left = 48
    Top = 165
    Width = 298
    Height = 35
    BevelOuter = bvNone
    TabOrder = 1
    object ButtonOk: TButton
      Left = 68
      Top = 6
      Width = 79
      Height = 23
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = BtnOkClick
    end
    object ButtonCancel: TButton
      Left = 152
      Top = 6
      Width = 79
      Height = 23
      Cancel = True
      Caption = 'Annuler'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object ImagePanel: TPanel
    Left = 0
    Top = 0
    Width = 48
    Height = 201
    Align = alLeft
    BevelOuter = bvNone
    Color = clAppWorkSpace
    FullRepaint = False
    TabOrder = 2
    object Image: TImage
      Left = 0
      Top = 0
      Width = 48
      Height = 201
      Align = alLeft
      Stretch = True
    end
  end
end
