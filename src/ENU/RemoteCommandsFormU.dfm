object RemoteCommandsForm: TRemoteCommandsForm
  Left = 453
  Top = 406
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 252
  ClientWidth = 351
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  DesignSize = (
    351
    252)
  PixelsPerInch = 96
  TextHeight = 13
  object RemoteCommandsGroupbox: TGroupBox
    Left = 0
    Top = 0
    Width = 351
    Height = 252
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Remote commands'
    TabOrder = 0
    DesignSize = (
      351
      252)
    object CheckListView: TListView4State
      Left = 6
      Top = 15
      Width = 339
      Height = 231
      AllowGrayed = False
      Anchors = [akLeft, akTop, akRight, akBottom]
      Columns = <
        item
          Caption = 'Command'
          Width = 100
        end
        item
          Caption = 'Description'
          Width = 200
        end>
      ReadOnly = True
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
end
