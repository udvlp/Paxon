object SendFilePartsSelectionDlg: TSendFilePartsSelectionDlg
  Left = 482
  Top = 305
  AutoScroll = False
  BorderIcons = []
  Caption = 'Teile...'
  ClientHeight = 219
  ClientWidth = 175
  Color = clBtnFace
  Constraints.MinHeight = 140
  Constraints.MinWidth = 183
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PrintScale = poNone
  DesignSize = (
    175
    219)
  PixelsPerInch = 96
  TextHeight = 13
  object FileNameLabel: TLabel
    Left = 6
    Top = 6
    Width = 163
    Height = 13
    AutoSize = False
    Caption = 'Datei...'
  end
  object ButtonCancelSend: TButton
    Left = 90
    Top = 190
    Width = 79
    Height = 23
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Abbrechen'
    ModalResult = 2
    TabOrder = 2
  end
  object ButtonOk: TButton
    Left = 6
    Top = 190
    Width = 79
    Height = 23
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object ListView1: TListView
    Left = 6
    Top = 24
    Width = 163
    Height = 161
    Anchors = [akLeft, akTop, akRight, akBottom]
    Checkboxes = True
    Columns = <
      item
        MaxWidth = 147
        MinWidth = 147
        Width = 147
      end>
    HideSelection = False
    MultiSelect = True
    ReadOnly = True
    ShowColumnHeaders = False
    TabOrder = 0
    ViewStyle = vsReport
    OnKeyDown = ListView1KeyDown
    OnMouseDown = ListView1MouseDown
  end
end
