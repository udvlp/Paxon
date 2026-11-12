object SendFileTemplatesDlg: TSendFileTemplatesDlg
  Left = 293
  Top = 95
  AutoScroll = False
  BorderIcons = []
  Caption = 'Datei senden - Vorlagen'
  ClientHeight = 371
  ClientWidth = 468
  Color = clBtnFace
  Constraints.MinHeight = 280
  Constraints.MinWidth = 368
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PrintScale = poNone
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    468
    371)
  PixelsPerInch = 96
  TextHeight = 13
  object BtnOk: TButton
    Left = 298
    Top = 343
    Width = 79
    Height = 23
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
    TabStop = False
  end
  object BtnCancelDlg: TButton
    Left = 382
    Top = 343
    Width = 79
    Height = 23
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Abbrechen'
    ModalResult = 2
    TabOrder = 4
    TabStop = False
  end
  object Panel1: TPanel
    Left = 292
    Top = 11
    Width = 172
    Height = 134
    Anchors = [akTop, akRight]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    Color = clInfoBk
    FullRepaint = False
    TabOrder = 2
    object RichEdit1: TRichEdit
      Left = 2
      Top = 2
      Width = 168
      Height = 130
      TabStop = False
      Align = alClient
      BorderStyle = bsNone
      Color = clInfoBk
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      WantReturns = False
    end
  end
  object GroupBoxBottom: TGroupBox
    Left = 3
    Top = 150
    Width = 461
    Height = 185
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = '&Text'
    TabOrder = 1
    DesignSize = (
      461
      185)
    object TextMemo: TMemo
      Left = 6
      Top = 15
      Width = 450
      Height = 164
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Paxon 08x12'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      WordWrap = False
      OnChange = TextMemoChange
    end
  end
  object GroupBoxTop: TGroupBox
    Left = 3
    Top = 6
    Width = 284
    Height = 139
    Anchors = [akLeft, akTop, akRight]
    Caption = '&Vorlagen'
    TabOrder = 0
    DesignSize = (
      284
      139)
    object TextListview: TListView
      Left = 6
      Top = 15
      Width = 272
      Height = 91
      Anchors = [akLeft, akTop, akRight]
      Columns = <
        item
          Caption = 'Text'
        end>
      HideSelection = False
      OwnerData = True
      ReadOnly = True
      RowSelect = True
      ShowColumnHeaders = False
      TabOrder = 0
      ViewStyle = vsReport
      OnChange = TextListviewChange
      OnData = TextListviewData
      OnResize = TextListviewResize
    end
    object ButtonAdd: TButton
      Left = 6
      Top = 110
      Width = 79
      Height = 23
      Caption = '&Hinzuf'#252'gen'
      TabOrder = 1
      OnClick = ButtonAddClick
    end
    object ButtonRemove: TButton
      Left = 90
      Top = 110
      Width = 79
      Height = 23
      Caption = '&Entfernen'
      TabOrder = 2
      OnClick = ButtonRemoveClick
    end
  end
end
