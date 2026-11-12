object SettingsForm: TSettingsForm
  Left = 272
  Top = 158
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = 'Settings'
  ClientHeight = 349
  ClientWidth = 465
  Color = clBtnFace
  Constraints.MinHeight = 376
  Constraints.MinWidth = 473
  DefaultMonitor = dmMainForm
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PrintScale = poNone
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShortCut = FormShortCut
  DesignSize = (
    465
    349)
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 6
    Top = 6
    Width = 453
    Height = 311
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    RaggedRight = True
    TabHeight = 18
    TabOrder = 0
    OnChange = PageControlChange
    OnChanging = PageControlChanging
    object TabSheet1: TTabSheet
      Caption = 'General'
    end
    object TabSheet2: TTabSheet
      Caption = 'Devices'
      ImageIndex = 1
    end
    object TabSheet3: TTabSheet
      Caption = 'Files'
      ImageIndex = 2
    end
    object TabSheet4: TTabSheet
      Caption = 'Display'
      ImageIndex = 3
    end
    object TabSheet5: TTabSheet
      Caption = 'Monitor'
      ImageIndex = 4
    end
    object TabSheet8: TTabSheet
      Caption = 'Texts'
      ImageIndex = 7
    end
    object TabSheet9: TTabSheet
      Caption = 'Remote'
      ImageIndex = 8
    end
    object TabSheet7: TTabSheet
      Caption = 'Sounds'
      ImageIndex = 6
    end
    object TabSheet6: TTabSheet
      Caption = 'Advanced'
      ImageIndex = 5
    end
  end
  object FormOkBtn: TButton
    Left = 212
    Top = 322
    Width = 79
    Height = 23
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    TabOrder = 1
    OnClick = FormOkBtnClick
  end
  object FormCancelBtn: TButton
    Left = 296
    Top = 322
    Width = 79
    Height = 23
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 2
    TabStop = False
    OnClick = FormCancelBtnClick
  end
  object FormApplyBtn: TButton
    Left = 380
    Top = 322
    Width = 79
    Height = 23
    Anchors = [akRight, akBottom]
    Caption = '&Apply'
    TabOrder = 3
    TabStop = False
    OnClick = FormApplyBtnClick
  end
end
