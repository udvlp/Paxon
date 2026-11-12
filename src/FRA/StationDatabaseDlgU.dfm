object StationDatabaseDlg: TStationDatabaseDlg
  Left = 449
  Top = 199
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = 'Stations'
  ClientHeight = 353
  ClientWidth = 493
  Color = clBtnFace
  Constraints.MinHeight = 380
  Constraints.MinWidth = 501
  DefaultMonitor = dmMainForm
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PrintScale = poNone
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShortCut = FormShortCut
  DesignSize = (
    493
    353)
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 114
    Top = 30
    Width = 373
    Height = 292
    ActivePage = TabGeneral
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
    TabStop = False
    object TabGeneral: TTabSheet
      Caption = 'Global'
      DesignSize = (
        365
        264)
      object GeneralGroupBox: TGroupBox
        Left = 6
        Top = 3
        Width = 353
        Height = 61
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Global'
        TabOrder = 0
        DesignSize = (
          353
          61)
        object NameLabel: TLabel
          Left = 6
          Top = 18
          Width = 49
          Height = 13
          AutoSize = False
          Caption = '&Nom'
          FocusControl = NameEdit
          Transparent = True
        end
        object StationTypeLabel: TLabel
          Left = 244
          Top = 18
          Width = 37
          Height = 13
          Anchors = [akTop, akRight]
          AutoSize = False
          Caption = '&Type'
          FocusControl = StationTypeCombobox
          Transparent = True
        end
        object StationTypeCombobox: TComboBox
          Left = 244
          Top = 33
          Width = 103
          Height = 21
          Style = csDropDownList
          Anchors = [akTop, akRight]
          ItemHeight = 13
          TabOrder = 1
        end
        object NameEdit: TEdit
          Left = 6
          Top = 33
          Width = 227
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
        end
      end
      object NotesGroupBox: TGroupBox
        Left = 6
        Top = 72
        Width = 353
        Height = 116
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'Notes'
        TabOrder = 1
        DesignSize = (
          353
          116)
        object NotesMemo: TMemo
          Left = 6
          Top = 18
          Width = 341
          Height = 91
          Anchors = [akLeft, akTop, akRight, akBottom]
          MaxLength = 16384
          TabOrder = 0
        end
      end
      object FirewallGroupBox: TGroupBox
        Left = 6
        Top = 196
        Width = 172
        Height = 61
        Anchors = [akLeft, akBottom]
        Caption = ' '
        TabOrder = 2
        object FirewallLabel: TLabel
          Left = 6
          Top = 18
          Width = 142
          Height = 13
          AutoSize = False
          Caption = 'Connexions entrantes'
          Transparent = True
        end
        object FirewallCombobox: TComboBox
          Left = 6
          Top = 33
          Width = 160
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 1
        end
        object FirewallCheckbox: TCheckBox
          Left = 8
          Top = 0
          Width = 85
          Height = 14
          Caption = 'Pare &feu'
          TabOrder = 0
          OnClick = FirewallCheckboxClick
        end
      end
    end
    object TabPasswords: TTabSheet
      Caption = 'Mots de passe'
      DesignSize = (
        365
        264)
      object GroupBox1: TGroupBox
        Left = 6
        Top = 3
        Width = 353
        Height = 254
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'Mots de passe'
        TabOrder = 0
        DesignSize = (
          353
          254)
        object PasswordListview: TListView
          Left = 6
          Top = 18
          Width = 343
          Height = 203
          Anchors = [akLeft, akTop, akRight, akBottom]
          Columns = <
            item
              Caption = 'Mon Indicatif'
              Width = 113
            end
            item
              Caption = 'Utilisateur/Sysop'
              Width = 98
            end
            item
              Caption = 'M'#233'thode'
              Width = 98
            end>
          HideSelection = False
          ReadOnly = True
          RowSelect = True
          TabOrder = 0
          ViewStyle = vsReport
          OnDblClick = PasswordListviewDblClick
        end
        object PasswordAddButton: TButton
          Left = 6
          Top = 226
          Width = 78
          Height = 23
          Anchors = [akLeft, akBottom]
          Caption = 'Ajouter'
          TabOrder = 1
          OnClick = PasswordAddButtonClick
        end
        object PasswordRemoveButton: TButton
          Left = 90
          Top = 226
          Width = 78
          Height = 23
          Anchors = [akLeft, akBottom]
          Caption = 'Supprimer'
          TabOrder = 2
          OnClick = PasswordRemoveButtonClick
        end
        object PasswordEditButton: TButton
          Left = 174
          Top = 226
          Width = 78
          Height = 23
          Anchors = [akLeft, akBottom]
          Caption = '&Modifier'
          ModalResult = 1
          TabOrder = 3
          OnClick = PasswordAddButtonClick
        end
      end
    end
    object TabTexts: TTabSheet
      Caption = 'Textes'
    end
    object TabRemoteControl: TTabSheet
      Caption = 'T'#233'l'#233'commande'
    end
    object TabSounds: TTabSheet
      Caption = 'Sons'
      ImageIndex = 4
    end
  end
  object CloseDlgBtn: TButton
    Left = 408
    Top = 327
    Width = 79
    Height = 23
    Anchors = [akRight, akBottom]
    BiDiMode = bdLeftToRight
    Cancel = True
    Caption = '&Fermer'
    ParentBiDiMode = False
    TabOrder = 4
    OnClick = CloseDlgBtnClick
  end
  object Button1: TButton
    Left = 6
    Top = 327
    Width = 49
    Height = 23
    Anchors = [akLeft, akBottom]
    Caption = 'Ajouter'
    TabOrder = 2
    TabStop = False
    OnClick = AddNewEntryClick
  end
  object Button2: TButton
    Left = 60
    Top = 327
    Width = 49
    Height = 23
    Anchors = [akLeft, akBottom]
    Caption = 'Effacer'
    TabOrder = 3
    TabStop = False
    OnClick = RemoveClick
  end
  object CallsignListView: TListView
    Left = 6
    Top = 6
    Width = 103
    Height = 316
    AllocBy = 512
    Anchors = [akLeft, akTop, akBottom]
    Columns = <
      item
        Caption = 'Stations'
        Width = 75
      end>
    ColumnClick = False
    FullDrag = True
    HideSelection = False
    IconOptions.Arrangement = iaLeft
    IconOptions.AutoArrange = True
    OwnerData = True
    ReadOnly = True
    ShowColumnHeaders = False
    SmallImages = CallsignImageList
    TabOrder = 0
    ViewStyle = vsReport
    OnChange = CallsignListViewChange
    OnChanging = CallsignListViewChanging
    OnData = CallsignListViewData
    OnDataFind = CallsignListViewDataFind
    OnKeyDown = CallsignListViewKeyDown
    OnSelectItem = CallsignListViewSelectItem
  end
  object Panel1: TPanel
    Left = 114
    Top = 6
    Width = 373
    Height = 20
    Anchors = [akLeft, akTop, akRight]
    BevelInner = bvRaised
    BevelOuter = bvLowered
    FullRepaint = False
    TabOrder = 5
    DesignSize = (
      373
      20)
    object HeaderLabel: TLabel
      Left = 6
      Top = 3
      Width = 358
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = #183
    end
  end
  object CallsignImageList: TImageList
    Height = 13
    Width = 12
    Left = 12
    Top = 12
  end
end
