object GeneralSettings: TGeneralSettings
  Left = 351
  Top = 264
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Global'
  ClientHeight = 268
  ClientWidth = 445
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
  PixelsPerInch = 96
  TextHeight = 13
  object AllGroupbox1: TGroupBox
    Left = 6
    Top = 6
    Width = 259
    Height = 130
    Caption = 'Mes Indicatifs'
    TabOrder = 0
    object CallsignListView: TListView
      Left = 6
      Top = 18
      Width = 247
      Height = 76
      Columns = <
        item
          Caption = 'Indicatif'
          Width = 70
        end
        item
          Caption = 'SSIDs'
          Width = 151
        end>
      IconOptions.WrapText = False
      ReadOnly = True
      SortType = stText
      TabOrder = 0
      ViewStyle = vsReport
      OnDblClick = CallsignListviewDblClick
    end
    object EditCallsign: TButton
      Left = 6
      Top = 99
      Width = 78
      Height = 23
      Caption = '&Editer'
      TabOrder = 1
      OnClick = EditCallsignClick
    end
    object AddCallsign: TButton
      Left = 90
      Top = 99
      Width = 78
      Height = 23
      Caption = '&Ajouter'
      TabOrder = 2
      OnClick = AddCallsignClick
    end
    object RemoveCallsign: TButton
      Left = 174
      Top = 99
      Width = 78
      Height = 23
      Caption = '&Effacer'
      TabOrder = 3
      OnClick = RemoveCallsignClick
    end
  end
  object AllGroupbox2: TGroupBox
    Left = 276
    Top = 6
    Width = 163
    Height = 88
    Caption = 'Entr'#233'e/Sortie'
    TabOrder = 1
    object AllChannelsLabel: TLabel
      Left = 6
      Top = 18
      Width = 60
      Height = 13
      AutoSize = False
      Caption = 'Canaux'
      Transparent = True
    end
    object AllLinesLabel: TLabel
      Left = 84
      Top = 18
      Width = 60
      Height = 13
      AutoSize = False
      Caption = 'Lignes'
      Transparent = True
    end
    object ChannelCountUpDown: TUpDown
      Left = 47
      Top = 33
      Width = 13
      Height = 21
      Associate = ChannelCountEdit
      Min = 1
      Max = 40
      Position = 1
      TabOrder = 0
      Thousands = False
    end
    object ChannelCountEdit: TEdit
      Left = 6
      Top = 33
      Width = 41
      Height = 21
      AutoSize = False
      MaxLength = 2
      TabOrder = 1
      Text = '1'
    end
    object AllLinesEdit: TEdit
      Left = 84
      Top = 33
      Width = 59
      Height = 21
      AutoSize = False
      MaxLength = 5
      TabOrder = 2
      Text = '500'
    end
    object AllLinesUpDown: TUpDown
      Left = 143
      Top = 33
      Width = 12
      Height = 21
      Associate = AllLinesEdit
      Min = 500
      Max = 30000
      Increment = 50
      Position = 500
      TabOrder = 3
      Thousands = False
    end
    object LocalEchoCheckBox: TCheckBox
      Left = 6
      Top = 63
      Width = 97
      Height = 18
      Caption = 'Echo &Local'
      TabOrder = 4
    end
  end
  object GroupBox1: TGroupBox
    Left = 276
    Top = 102
    Width = 163
    Height = 61
    Caption = 'Pare feu'
    TabOrder = 2
    object Label2: TLabel
      Left = 6
      Top = 18
      Width = 142
      Height = 13
      AutoSize = False
      Caption = 'Connexions entrantes'
      Transparent = True
    end
    object IncomingConnectionsCombobox: TComboBox
      Left = 6
      Top = 33
      Width = 151
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
    end
  end
end
