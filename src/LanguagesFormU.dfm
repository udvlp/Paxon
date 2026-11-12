object LanguagesForm: TLanguagesForm
  Left = 339
  Top = 225
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Paxon'
  ClientHeight = 157
  ClientWidth = 221
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 6
    Top = 6
    Width = 211
    Height = 13
    AutoSize = False
    Caption = 'Bitte w'#228'hlen Sie eine Sprache aus.'
  end
  object Label2: TLabel
    Left = 6
    Top = 21
    Width = 211
    Height = 13
    AutoSize = False
    Caption = 'Please select a language.'
  end
  object Label3: TLabel
    Left = 6
    Top = 36
    Width = 211
    Height = 13
    AutoSize = False
    Caption = 'S'#233'lectionnez la langue, s'#39'il vous plait.'
  end
  object ListView: TListView
    Left = 6
    Top = 54
    Width = 211
    Height = 73
    Columns = <
      item
        Caption = 'Sprache'
        Width = 190
      end>
    ReadOnly = True
    ShowColumnHeaders = False
    TabOrder = 0
    ViewStyle = vsReport
    OnChange = ListViewChange
    OnDblClick = ListViewDblClick
  end
  object OkButton: TButton
    Left = 72
    Top = 132
    Width = 79
    Height = 23
    Caption = 'OK'
    Default = True
    Enabled = False
    ModalResult = 1
    TabOrder = 1
  end
end
