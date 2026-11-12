object MainWindow: TMainWindow
  Left = 509
  Top = 404
  ActiveControl = InputPanel
  AutoScroll = False
  BorderWidth = 3
  Caption = '...'
  ClientHeight = 300
  ClientWidth = 581
  Color = clBtnFace
  DefaultMonitor = dmDesktop
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Shell Dlg'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  PrintScale = poNone
  OnActivate = FormActivate
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnDeactivate = FormDeactivate
  OnKeyDown = FormKeyDown
  OnShortCut = FormShortCut
  PixelsPerInch = 96
  TextHeight = 13
  object ClientPanel: TPanelUlf
    Left = 9
    Top = 50
    Width = 563
    Height = 221
    Align = alClient
    BevelOuter = bvNone
    FullRepaint = False
    Locked = True
    TabOrder = 0
    OnResize = ClientPanelResize
    ThemeMode = tmNoPaint
    object OutputPanel: TPanelUlf
      Left = 0
      Top = 0
      Width = 563
      Height = 128
      Align = alClient
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = clWindow
      FullRepaint = False
      Locked = True
      TabOrder = 1
      ThemeMode = tmNoPaint
    end
    object InputPanel: TPanelUlf
      Left = 0
      Top = 132
      Width = 563
      Height = 32
      Align = alBottom
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = clWindow
      FullRepaint = False
      Locked = True
      TabOrder = 0
      ThemeMode = tmNoPaint
      object EditorGutterPanel: TPanel
        Left = 0
        Top = 0
        Width = 15
        Height = 28
        Cursor = crArrow
        Align = alLeft
        BevelOuter = bvNone
        Color = cl3DDkShadow
        FullRepaint = False
        Locked = True
        ParentBackground = False
        TabOrder = 0
        object EditorGutterLine: TShape
          Left = 14
          Top = 0
          Width = 1
          Height = 28
          Align = alRight
          Pen.Color = clGray
        end
      end
    end
    object MonitorPanel: TPanelUlf
      Left = 0
      Top = 189
      Width = 563
      Height = 32
      Align = alBottom
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = clBtnHighlight
      FullRepaint = False
      TabOrder = 2
    end
    object ResizePanel2: TPanelUlf
      Left = 0
      Top = 164
      Width = 563
      Height = 25
      Cursor = crSizeNS
      Align = alBottom
      BevelOuter = bvNone
      FullRepaint = False
      ParentBackground = False
      TabOrder = 4
      OnResize = ResizePanel2Resize
      ThemeMode = tmNoPaint
      object PanelUlf1: TPanel
        Left = 548
        Top = 0
        Width = 15
        Height = 25
        Cursor = crSizeNS
        Align = alRight
        BevelOuter = bvNone
        FullRepaint = False
        ParentBackground = False
        ParentColor = True
        TabOrder = 0
        OnMouseDown = ResizePanel2MouseDown
        OnMouseMove = ResizePanel2MouseMove
        OnMouseUp = ResizePanel2MouseUp
      end
      object PanelUlf2: TPanelUlf
        Left = 0
        Top = 0
        Width = 548
        Height = 25
        Cursor = crSizeNS
        Align = alClient
        BevelOuter = bvNone
        FullRepaint = False
        ParentBackground = False
        ParentColor = True
        TabOrder = 1
        OnMouseDown = ResizePanel2MouseDown
        OnMouseMove = ResizePanel2MouseMove
        OnMouseUp = ResizePanel2MouseUp
        object ResizeDock2: TToolbarDock
          Left = 0
          Top = 0
          Width = 548
          Height = 26
          Cursor = crSizeNS
          OnMouseDown = ResizePanel2MouseDown
          OnMouseMove = ResizePanel2MouseMove
          OnMouseUp = ResizePanel2MouseUp
          OnResize = ResizeDock2Resize
          object ChannelToolbar: TPaxonToolbar
            Left = 0
            Top = 0
            Caption = 'Canaux'
            Images = ChannelStateImages
            ParentShowHint = False
            ShowHint = True
            Shrink = lkWrap
            UpdateActions = False
          end
        end
      end
    end
    object ResizePanel1: TPanelUlf
      Left = 0
      Top = 128
      Width = 563
      Height = 4
      Cursor = crSizeNS
      Align = alBottom
      BevelOuter = bvNone
      FullRepaint = False
      ParentBackground = False
      TabOrder = 3
      OnResize = ResizePanel1Resize
      ThemeMode = tmNoPaint
      object PanelUlf3: TPanel
        Left = 0
        Top = 0
        Width = 548
        Height = 4
        Cursor = crSizeNS
        Align = alClient
        BevelOuter = bvNone
        FullRepaint = False
        ParentBackground = False
        ParentColor = True
        TabOrder = 0
        OnMouseDown = ResizePanel1MouseDown
        OnMouseMove = ResizePanel1MouseMove
        OnMouseUp = ResizePanel1MouseUp
      end
      object PanelUlf4: TPanel
        Left = 548
        Top = 0
        Width = 15
        Height = 4
        Cursor = crSizeNS
        Align = alRight
        BevelOuter = bvNone
        FullRepaint = False
        ParentBackground = False
        ParentColor = True
        TabOrder = 1
        OnMouseDown = ResizePanel1MouseDown
        OnMouseMove = ResizePanel1MouseMove
        OnMouseUp = ResizePanel1MouseUp
      end
    end
  end
  object TBDock1: TToolbarDock
    Left = 0
    Top = 0
    Width = 581
    Height = 50
    object MainMenuBar: TPaxonToolbar
      Left = 0
      Top = 0
      Caption = 'Menu'
      Images = ImageList
      MenuBar = True
      Shrink = lkWrap
      Stretch = True
      object MenuFile: TToolbarSubmenu
        Caption = '&Fichier'
        object TBItem31: TToolbarElement
          Action = ActionSend
        end
        object TBItem41: TToolbarElement
          Action = ActionSave
        end
        object TBItem51: TToolbarElement
          Action = ActionStop
        end
        object TBXSeparatorItem3: TToolbarSeparator
        end
        object TBXItem3: TToolbarElement
          Action = ActionPrint
        end
        object TBSeparatorItem4: TToolbarSeparator
        end
        object TBItem62: TToolbarElement
          Action = ActionEnd
        end
      end
      object MenuConnect: TToolbarSubmenu
        Caption = 'C&onnection'
        object TBItem4a: TToolbarElement
          Action = ActionConnect
          Caption = '&Connecter...'
        end
        object TBItem83: TToolbarElement
          Action = ActionDisconnect
        end
        object TBSeparatorItem2: TToolbarSeparator
        end
        object TBItem7x: TToolbarElement
          Action = ActionLocalEcho
        end
        object TBSeparatorItem3a: TToolbarSeparator
        end
        object MenuConnectPactor: TToolbarSubmenu
          Caption = '&Pactor'
          object TBItem8x: TToolbarElement
            Action = ActionPactorChangeover
          end
          object TBItem9x: TToolbarElement
            Action = ActionPactorBreakin
          end
        end
      end
      object MenuEdit: TToolbarSubmenu
        Caption = '&Edition'
        object TBItem7: TToolbarElement
          Action = ActionEditCut
        end
        object TBItem8: TToolbarElement
          Action = ActionEditCopy
        end
        object TBItem9: TToolbarElement
          Action = ActionEditPaste
        end
        object TBItem10: TToolbarElement
          Action = ActionEditDelete
        end
        object TBSeparatorItem1: TToolbarSeparator
        end
        object TBItem13: TToolbarElement
          Action = ActionClearConsole
        end
      end
      object MenuView: TToolbarSubmenu
        Caption = 'Affic&hage'
        object TBItem15: TToolbarElement
          Action = ActionDeviceStatus
        end
        object TBSubmenuItem1: TToolbarSubmenu
          Caption = '&Barre d''outils'
          object TBItem3a: TToolbarElement
            Action = ActionToolbarNoText
            GroupIndex = 1
          end
          object TBItem2: TToolbarElement
            Action = ActionToolbarTextRight
            GroupIndex = 1
          end
          object TBItem1q: TToolbarElement
            Action = ActionToolbarTextBottom
            GroupIndex = 1
          end
        end
      end
      object MenuTools: TToolbarSubmenu
        Caption = '&Outils'
        object TBItem16: TToolbarElement
          Action = ActionSettings
          Caption = 'Param'#232'&tres...'
        end
        object TBItem17: TToolbarElement
          Action = ActionLanguage
        end
      end
      object MenuStations: TToolbarSubmenu
        Caption = 'Stati&ons'
        object TBItem19: TToolbarElement
          Action = ActionStationDatabase
        end
        object TBXItem1: TToolbarElement
          Action = ActionRepairStationDatabase
        end
      end
      object MenuHelp: TToolbarSubmenu
        Caption = '&Aide'
        object TBXItem2: TToolbarElement
          Action = ActionHelpContents
        end
        object TBSeparatorItem5: TToolbarSeparator
        end
        object TBItem26: TToolbarElement
          Action = ActionHelpInfo
        end
      end
    end
    object ToolBar: TPaxonToolbar
      Left = 0
      Top = 25
      Caption = '&Barre d''outils'
      DockRow = 1
      Images = ImageList
      ShowElementHints = True
      ParentShowHint = False
      ProcessShortCuts = True
      ShowHint = False
      object TBItem1: TToolbarElement
        Action = ActionConnect
        DisplayMode = anImageAndText
      end
      object TBItem6: TToolbarElement
        Action = ActionDisconnect
        DisplayMode = anImageAndText
      end
      object TBSeparatorItem2a: TToolbarSeparator
      end
      object TBItem56: TToolbarElement
        Action = ActionSend
        DisplayMode = anImageAndText
      end
      object TBItemSave: TToolbarElement
        Action = ActionSave
        DisplayMode = anImageAndText
        GroupIndex = 1
      end
      object TBItem3b: TToolbarElement
        Action = ActionStop
        DisplayMode = anImageAndText
      end
      object TBSeparatorItem3b: TToolbarSeparator
      end
      object TBItem72: TToolbarElement
        Action = ActionSettings
        DisplayMode = anImageAndText
      end
      object TBItem21: TToolbarElement
        Action = ActionStationDatabase
        DisplayMode = anImageAndText
      end
    end
  end
  object Statusbar: TTBXStatusBar
    Left = 0
    Top = 280
    Width = 581
    Height = 20
    Panels = <
      item
        Size = 102
        Tag = 0
      end
      item
        MaxSize = 270
        Size = 135
        StretchPriority = 1
        Tag = 0
        TextTruncation = twPathEllipsis
      end
      item
        Alignment = taCenter
        Hint = 'Baud effectif'
        Size = 70
        Tag = 0
      end
      item
        Alignment = taCenter
        Caption = 'T'
        Hint = 'Essais'
        Size = 27
        Tag = 0
      end
      item
        Alignment = taCenter
        Caption = 'U'
        Hint = 'Trames non acquitt'#233'es'
        Size = 27
        Tag = 0
      end
      item
        Alignment = taCenter
        Caption = 'F'
        Hint = 'Frack [100ms]'
        Size = 33
        Tag = 0
      end
      item
        Alignment = taCenter
        Caption = 'M'
        Hint = 'MaxFrame'
        Size = 22
        Tag = 0
      end
      item
        Alignment = taCenter
        Caption = 'S'
        Hint = #201'tat AX.25'
        Size = 67
        Tag = 0
        TextTruncation = twEndEllipsis
      end
      item
        Alignment = taCenter
        Caption = 'MYCALL'
        Hint = 'Mon indicatif'
        Size = 67
        Tag = 0
      end
      item
        Control = StatusbarDeviceImage
        Framed = False
        Size = 19
        Tag = 0
      end
      item
        Framed = False
        Size = 67
        Tag = 0
      end>
    ParentShowHint = False
    ShowHint = True
    UseSystemFont = False
    object Progressbar: TGauge
      Left = 2
      Top = 4
      Width = 96
      Height = 13
      BackColor = clBtnFace
      BorderStyle = bsNone
      Color = clBtnFace
      ForeColor = 55551
      ParentColor = False
      Progress = 100
      ShowText = False
    end
    object ProgressLabel: TLabel
      Left = 2
      Top = 4
      Width = 96
      Height = 12
      Alignment = taCenter
      AutoSize = False
      Caption = '0%'
      ShowAccelChar = False
      Transparent = True
      Layout = tlCenter
      Visible = False
    end
    object StatusbarDeviceImage: TImage
      Left = 550
      Top = 2
      Width = 19
      Height = 18
      Center = True
      Transparent = True
      OnClick = ActionDeviceStatusExecute
    end
  end
  object ChannelStateImages: TImageList
    AllocBy = 0
    Height = 0
    Masked = False
    Width = 0
    Left = 76
    Top = 90
  end
  object GutterImages: TImageList
    AllocBy = 0
    Height = 0
    Masked = False
    Width = 0
    Left = 46
    Top = 90
  end
  object ApplicationEvents: TApplicationEvents
    OnActivate = ApplicationEventsActivate
    OnShowHint = ApplicationEventsShowHint
    Left = 46
    Top = 54
  end
  object ActionList: TActionList
    Images = ImageList
    Left = 16
    Top = 54
    object ActionBoxRead: TAction
      Caption = 'Marquer le message pour lire'
      ImageIndex = 18
      OnExecute = ActionBoxReadExecute
    end
    object ActionBoxErase: TAction
      Caption = 'Marquer le message pour effacer'
      ImageIndex = 19
      OnExecute = ActionBoxEraseExecute
    end
    object ActionBoxUncheck: TAction
      Caption = 'Enlever le marquage'
      ImageIndex = 17
      OnExecute = ActionBoxUncheckExecute
    end
    object ActionBoxRun: TAction
      Caption = 'Executer'
      ImageIndex = 20
      OnExecute = ActionBoxRunExecute
    end
    object ActionConnect: TAction
      Caption = '&Connecter'
      Hint = 'Connecter'
      ImageIndex = 0
      OnExecute = ActionConnectExecute
    end
    object ActionDisconnect: TAction
      Caption = '&D'#233'connecter'
      Hint = 'D'#233'connecter'
      ImageIndex = 1
      OnExecute = ActionDisconnectExecute
    end
    object ActionDeviceStatus: TAction
      Caption = '&Etat des p'#233'riph'#233'riques'
      OnExecute = ActionDeviceStatusExecute
    end
    object ActionClearConsole: TAction
      Caption = 'Effacer la fen'#234'tre de r'#233'ception'
      OnExecute = ActionClearConsoleExecute
    end
    object ActionShowDosUmlauts: TAction
      Caption = 'Afficher les "Umlauts" DOS'
      OnExecute = ActionShowDosUmlautsExecute
    end
    object ActionSendDosUmlauts: TAction
      Caption = 'Envoyer les "Umlauts" DOS'
      OnExecute = ActionSendDosUmlautsExecute
    end
    object ActionEditCopy: TAction
      Caption = '&Copier'
      ImageIndex = 14
      ShortCut = 16451
      OnExecute = ActionEditCopyExecute
    end
    object ActionEditCut: TAction
      Caption = 'C&ouper'
      ImageIndex = 13
      ShortCut = 16472
      OnExecute = ActionEditCutExecute
    end
    object ActionEditDelete: TAction
      Caption = '&Effacer'
      ImageIndex = 16
      ShortCut = 46
      OnExecute = ActionEditDeleteExecute
    end
    object ActionEditPaste: TAction
      Caption = 'Co&ller'
      ImageIndex = 15
      ShortCut = 16470
      OnExecute = ActionEditPasteExecute
    end
    object ActionEditSelectAll: TAction
      Caption = '&Tout s'#233'lectionner'
      Enabled = False
      ShortCut = 16449
      OnExecute = ActionEditSelectAllExecute
    end
    object ActionEnd: TAction
      Caption = '&Quitter'
      OnExecute = ActionEndExecute
    end
    object ActionHelpContents: TAction
      Caption = '&Contenu'
      OnExecute = ActionHelpContentsExecute
    end
    object ActionHelpInfo: TAction
      Caption = '&A propos...'
      OnExecute = ActionHelpInfoExecute
    end
    object ActionHint: TAction
      ShortCut = 16456
      OnExecute = ActionHintExecute
    end
    object ActionLanguage: TAction
      Caption = '&Langue...'
      ImageIndex = 6
      OnExecute = ActionLanguageExecute
    end
    object ActionLocalEcho: TAction
      Caption = 'Echo &Local'
      Enabled = False
      ShortCut = 16453
      OnExecute = ActionLocalEchoExecute
    end
    object ActionMacro: TAction
      Caption = '&Macros'
    end
    object ActionPactorChangeover: TAction
      Caption = '&ChangeOver'
      Enabled = False
      ShortCut = 16473
      OnExecute = ActionPactorChangeoverExecute
    end
    object ActionPactorBreakin: TAction
      Caption = '&BreakIn'
      Enabled = False
      ShortCut = 16450
      OnExecute = ActionPactorBreakinExecute
    end
    object ActionSend: TAction
      Caption = 'E&nvoyer'
      ImageIndex = 2
      OnExecute = ActionSendExecute
    end
    object ActionSave: TAction
      Caption = '&Sauvegarder'
      ImageIndex = 3
      OnExecute = ActionSaveExecute
    end
    object ActionSettings: TAction
      Caption = 'Param'#232'&tres'
      ImageIndex = 5
      OnExecute = ActionSettingsExecute
    end
    object ActionStationDatabase: TAction
      Caption = 'Stat&ions'
      ImageIndex = 11
      OnExecute = ActionStationDatabaseExecute
    end
    object ActionRepairStationDatabase: TAction
      Caption = '&R'#233'parer la base de donn'#233'es'
      OnExecute = ActionRepairStationDatabaseExecute
    end
    object ActionAddStations: TAction
      Caption = '&Ajouter...'
    end
    object ActionStop: TAction
      Caption = 'A&rr'#234'ter'
      ImageIndex = 10
      OnExecute = ActionStopExecute
    end
    object ActionToolbarNoText: TAction
      AutoCheck = True
      Caption = '&Seulement symboles'
      GroupIndex = 22
      OnExecute = ActionToolbarNoTextExecute
    end
    object ActionToolbarTextRight: TAction
      AutoCheck = True
      Caption = 'Texte '#224' &droite'
      GroupIndex = 22
      OnExecute = ActionToolbarTextRightExecute
    end
    object ActionToolbarTextBottom: TAction
      AutoCheck = True
      Caption = 'Texte d&essous'
      GroupIndex = 22
      OnExecute = ActionToolbarTextBottomExecute
    end
    object ActionPrint: TAction
      Caption = '&Imprimer...'
      ShortCut = 16464
      OnExecute = ActionPrintExecute
    end
  end
  object ImageList: TImageList
    AllocBy = 0
    Height = 0
    Masked = False
    Width = 0
    Left = 16
    Top = 90
  end
end
