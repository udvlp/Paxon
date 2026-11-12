object SendFileDlg: TSendFileDlg
  Left = 536
  Top = 320
  AutoScroll = False
  BorderIcons = []
  Caption = 'Paxon - Envoyer'
  ClientHeight = 396
  ClientWidth = 480
  Color = clBtnFace
  Constraints.MinHeight = 388
  Constraints.MinWidth = 375
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
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  OnShortCut = FormShortCut
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControlUlf
    Left = 0
    Top = 49
    Width = 480
    Height = 313
    ActivePage = TabSheet4
    Align = alClient
    TabHeight = 6
    TabOrder = 0
    TabStop = False
    TabWidth = 6
    object TabSheet1: TTabSheet
      TabVisible = False
      DesignSize = (
        472
        303)
      object ProtocolGroupbox: TGroupBox
        Left = 120
        Top = 0
        Width = 352
        Height = 145
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Protocole'
        TabOrder = 1
        DesignSize = (
          352
          145)
        object ProtocolLabelInfo: TLabel
          Left = 102
          Top = 36
          Width = 238
          Height = 97
          Anchors = [akLeft, akTop, akRight]
          AutoSize = False
          Caption = 'x'
          ShowAccelChar = False
          Transparent = True
          WordWrap = True
        end
        object ProtocolBevel: TBevel
          Left = 90
          Top = 17
          Width = 7
          Height = 117
          Shape = bsLeftLine
        end
        object ProtocolLabelInfoHeading: TLabel
          Left = 102
          Top = 18
          Width = 232
          Height = 13
          Alignment = taCenter
          Anchors = [akLeft, akTop, akRight]
          AutoSize = False
          Caption = 'x'
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Shell Dlg'
          Font.Style = [fsBold]
          ParentFont = False
          ShowAccelChar = False
          Transparent = True
        end
        object ProtocolRadiobuttonAutobin: TRadioButton
          Left = 9
          Top = 36
          Width = 70
          Height = 16
          Caption = '&AutoBin'
          TabOrder = 1
          OnClick = ProtocolRadiobuttonClick
        end
        object ProtocolRadiobuttonBinary: TRadioButton
          Left = 9
          Top = 72
          Width = 70
          Height = 16
          Caption = '&Binaire'
          Enabled = False
          TabOrder = 3
          OnClick = ProtocolRadiobuttonClick
        end
        object ProtocolRadiobuttonText: TRadioButton
          Left = 9
          Top = 18
          Width = 70
          Height = 16
          Caption = '&Texte'
          Checked = True
          TabOrder = 0
          TabStop = True
          OnClick = ProtocolRadiobuttonClick
        end
        object ProtocolRadiobuttonDidadit: TRadioButton
          Left = 9
          Top = 54
          Width = 70
          Height = 16
          Caption = 'D&idadit'
          TabOrder = 2
          OnClick = ProtocolRadiobuttonClick
        end
      end
      object SendGroupbox: TGroupBox
        Left = 0
        Top = 0
        Width = 109
        Height = 145
        Caption = 'Envoyer'
        TabOrder = 0
        object SendRadiobutton1: TRadioButton
          Left = 9
          Top = 18
          Width = 94
          Height = 17
          Caption = '&Fichier(s)'
          Checked = True
          TabOrder = 0
          TabStop = True
          OnClick = SendRadiobutton1Click
        end
        object SendRadiobutton2: TRadioButton
          Left = 9
          Top = 36
          Width = 94
          Height = 17
          Caption = '&Saisie de texte'
          TabOrder = 1
          OnClick = SendRadiobutton2Click
        end
      end
      object QueueGroupbox: TGroupBox
        Left = 0
        Top = 150
        Width = 472
        Height = 146
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'File d''attente'
        Constraints.MinHeight = 85
        TabOrder = 2
        DesignSize = (
          472
          146)
        object QueueNotebook: TNotebook
          Left = 6
          Top = 18
          Width = 460
          Height = 122
          Anchors = [akLeft, akTop, akRight, akBottom]
          PageIndex = 2
          TabOrder = 0
          object TPage
            Left = 0
            Top = 0
            Caption = '2'
            DesignSize = (
              460
              122)
            object QueueDeleteButton: TButton
              Left = 6
              Top = 97
              Width = 79
              Height = 23
              Anchors = [akLeft, akBottom]
              Caption = 'Tout &effacer'
              Enabled = False
              TabOrder = 1
            end
            object QueueListbox: TListBox
              Left = 6
              Top = 0
              Width = 448
              Height = 92
              Anchors = [akLeft, akTop, akRight, akBottom]
              ItemHeight = 13
              TabOrder = 0
            end
          end
          object TPage
            Left = 0
            Top = 0
            Caption = '2'
            DesignSize = (
              460
              122)
            object QueueLabel: TLabel
              Left = 15
              Top = 18
              Width = 425
              Height = 83
              Alignment = taCenter
              Anchors = [akLeft, akTop, akRight, akBottom]
              AutoSize = False
              Caption = 'Il n''y a pas de fichiers dans la file d''attente pour l''instant.'
              Font.Charset = ANSI_CHARSET
              Font.Color = clGray
              Font.Height = -11
              Font.Name = 'MS Shell Dlg'
              Font.Style = []
              ParentFont = False
              Layout = tlCenter
            end
          end
          object TPage
            Left = 0
            Top = 0
            Caption = '2'
            DesignSize = (
              460
              122)
            object Label1: TLabel
              Left = 18
              Top = 18
              Width = 419
              Height = 83
              Alignment = taCenter
              Anchors = [akLeft, akTop, akRight, akBottom]
              AutoSize = False
              Caption = 'Le canal n''est pas connect'#233'.'
              Layout = tlCenter
            end
          end
        end
      end
    end
    object TabSheetFiles: TTabSheet
      ImageIndex = 1
      TabVisible = False
      DesignSize = (
        472
        303)
      object GroupBox5: TGroupBox
        Left = 0
        Top = 0
        Width = 472
        Height = 296
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'Fichiers '#224' envoyer:'
        TabOrder = 0
        DesignSize = (
          472
          296)
        object FilesListbox: TListBox
          Left = 12
          Top = 18
          Width = 448
          Height = 242
          Anchors = [akLeft, akTop, akRight, akBottom]
          ItemHeight = 13
          MultiSelect = True
          Sorted = True
          TabOrder = 0
        end
        object ButtonAdd: TButton
          Left = 12
          Top = 265
          Width = 79
          Height = 23
          Anchors = [akLeft, akBottom]
          Caption = '&Ajouter'
          TabOrder = 1
          OnClick = ButtonAddClick
        end
        object ButtonRemove: TButton
          Left = 96
          Top = 265
          Width = 79
          Height = 23
          Anchors = [akLeft, akBottom]
          Caption = '&Supprimer'
          TabOrder = 2
          OnClick = ButtonRemoveClick
        end
      end
    end
    object TabSheetText: TTabSheet
      ImageIndex = 2
      TabVisible = False
      DesignSize = (
        472
        303)
      object GroupBox6: TGroupBox
        Left = 0
        Top = 0
        Width = 472
        Height = 296
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'Veuillez entrer votre texte:'
        TabOrder = 0
        DesignSize = (
          472
          296)
        object TextMemo: TMemo
          Left = 6
          Top = 18
          Width = 460
          Height = 254
          Anchors = [akLeft, akTop, akRight, akBottom]
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Paxon 08x12'
          Font.Style = []
          HideSelection = False
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
          OnChange = TextMemoChange
          OnKeyDown = TextMemoKeyDown
        end
        object WordwrapCheckBox: TCheckBox
          Left = 6
          Top = 275
          Width = 211
          Height = 16
          Anchors = [akLeft, akBottom]
          Caption = '&Retour '#224' la ligne automatique'
          Checked = True
          State = cbChecked
          TabOrder = 1
          OnClick = WordwrapCheckBoxClick
        end
      end
    end
    object TabSheet4: TTabSheet
      ImageIndex = 3
      TabVisible = False
      DesignSize = (
        472
        303)
      object PageControlUlf1: TPageControlUlf
        Left = -4
        Top = 140
        Width = 482
        Height = 163
        ActivePage = TabSheet4Bin
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabHeight = 6
        TabOrder = 1
        TabPosition = tpBottom
        TabStop = False
        object TabSheet4Bin: TTabSheet
          TabVisible = False
          DesignSize = (
            474
            155)
          object PartsGroupBox: TGroupBox
            Left = 0
            Top = 0
            Width = 472
            Height = 152
            Anchors = [akLeft, akTop, akRight, akBottom]
            Caption = 'Parties'
            Constraints.MinHeight = 115
            TabOrder = 0
            DesignSize = (
              472
              152)
            object PartSizeLabel2: TLabel
              Left = 206
              Top = 19
              Width = 16
              Height = 13
              Alignment = taRightJustify
              AutoSize = False
              Caption = 'kB'
            end
            object PartSizeLabel1: TLabel
              Left = 79
              Top = 19
              Width = 70
              Height = 13
              Alignment = taRightJustify
              Caption = '&Taille de chaque partie:'
              FocusControl = PartSizeMemo
            end
            object PartsCheckbox: TCheckBox
              Left = 12
              Top = 18
              Width = 66
              Height = 17
              Caption = '&D'#233'couper'
              TabOrder = 0
              OnClick = PartsCheckboxClick
            end
            object PartSizeUpDown: TUpDown
              Left = 193
              Top = 16
              Width = 12
              Height = 20
              Associate = PartSizeMemo
              Min = 5
              Max = 10240
              Increment = 4
              Position = 32
              TabOrder = 2
              Thousands = False
            end
            object PartSizeMemo: TMemoUlf
              Left = 156
              Top = 16
              Width = 37
              Height = 20
              Alignment = taRightJustify
              Lines.Strings = (
                '32')
              MaxLength = 5
              TabOrder = 1
              WantReturns = False
              WordWrap = False
              OnChange = PartSizeMemoChange
              OnExit = PartSizeMemoExit
              DigitsOnly = True
            end
            object PartsCountListview: TListView
              Left = 12
              Top = 42
              Width = 448
              Height = 74
              AllocBy = 4
              Anchors = [akLeft, akTop, akRight, akBottom]
              Columns = <
                item
                  Caption = 'Fichier'
                  MinWidth = 40
                  Width = 160
                end
                item
                  Alignment = taRightJustify
                  Caption = 'Taille'
                  MinWidth = 40
                  Width = 54
                end
                item
                  Alignment = taRightJustify
                  Caption = 'Parties'
                  MinWidth = 40
                  Width = 54
                end
                item
                  Caption = 'Commentaires'
                  MinWidth = 40
                  Width = 156
                end>
              HideSelection = False
              IconOptions.AutoArrange = True
              IconOptions.WrapText = False
              ReadOnly = True
              RowSelect = True
              TabOrder = 3
              ViewStyle = vsReport
              OnChange = PartsCountListviewChange
              OnDblClick = PartsCountListviewDblClick
            end
            object ButtonPartsProperties: TButton
              Left = 12
              Top = 121
              Width = 79
              Height = 23
              Anchors = [akLeft, akBottom]
              Caption = '&Propri'#233't'#233's'
              Enabled = False
              TabOrder = 4
              OnClick = ButtonPartsPropertiesClick
            end
          end
        end
        object TabSheet4Text: TTabSheet
          ImageIndex = 1
          TabVisible = False
          object WordWrapGroupbox: TGroupBox
            Left = 240
            Top = 0
            Width = 229
            Height = 67
            Caption = 'Refrappe'
            Enabled = False
            TabOrder = 0
            object Label2: TLabel
              Left = 149
              Top = 29
              Width = 39
              Height = 13
              Caption = 'Caract'#232'res'
              Enabled = False
              Transparent = True
            end
            object WordWrapEnabledCheckbox: TCheckBox
              Left = 12
              Top = 25
              Width = 85
              Height = 22
              TabStop = False
              Caption = '&Refrapper '#224':'
              Enabled = False
              TabOrder = 0
            end
            object WordWrapUpDown: TUpDown
              Left = 131
              Top = 26
              Width = 12
              Height = 20
              Associate = WordWrapMemo
              Enabled = False
              TabOrder = 1
            end
            object WordWrapMemo: TMemoUlf
              Left = 102
              Top = 26
              Width = 29
              Height = 20
              Alignment = taRightJustify
              Enabled = False
              Lines.Strings = (
                '0')
              ParentColor = True
              TabOrder = 2
              DigitsOnly = False
            end
          end
        end
      end
      object MailboxGroupbox: TGroupBox
        Left = 0
        Top = 0
        Width = 472
        Height = 139
        Anchors = [akLeft, akTop, akRight]
        Caption = 'BBS'
        TabOrder = 0
        DesignSize = (
          472
          139)
        object MailboxTextBeforeCheckbox: TCheckBox
          Left = 12
          Top = 18
          Width = 97
          Height = 17
          Caption = 'Texte a&vant'
          TabOrder = 0
          OnClick = MailboxTextBeforeCheckboxClick
        end
        object MailboxTextAfterCheckbox: TCheckBox
          Left = 12
          Top = 78
          Width = 97
          Height = 17
          Caption = 'Texte &apr'#232's'
          TabOrder = 2
          OnClick = MailboxTextAfterCheckboxClick
        end
        object MailboxTextBeforeMemo: TMemoUlf
          Left = 114
          Top = 18
          Width = 341
          Height = 54
          Anchors = [akLeft, akTop, akRight]
          Enabled = False
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Paxon 07x09'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssVertical
          TabOrder = 1
          WordWrap = False
          OnKeyDown = TextMemoKeyDown
          DigitsOnly = False
        end
        object MailboxTextAfterMemo: TMemoUlf
          Left = 114
          Top = 78
          Width = 341
          Height = 54
          Anchors = [akLeft, akTop, akRight]
          Enabled = False
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Paxon 07x09'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssVertical
          TabOrder = 3
          WordWrap = False
          OnKeyDown = TextMemoKeyDown
          DigitsOnly = False
        end
        object TemplatesBeforeButton: TBitBtn
          Left = 30
          Top = 36
          Width = 75
          Height = 23
          Caption = '&Mod'#232'les'
          Enabled = False
          TabOrder = 4
          OnClick = TemplatesButtonClick
          OnMouseDown = TemplatesButtonMouseDown
          Glyph.Data = {
            4E000000424D4E000000000000003E0000002800000007000000040000000100
            010000000000100000000000000000000000020000000000000000000000FFFF
            FF00EE000000C60000008200000000000000}
          Layout = blGlyphRight
        end
        object TemplatesAfterButton: TBitBtn
          Left = 30
          Top = 96
          Width = 75
          Height = 23
          Caption = 'M&od'#232'les'
          Enabled = False
          TabOrder = 5
          OnClick = TemplatesButtonClick
          OnMouseDown = TemplatesButtonMouseDown
          Glyph.Data = {
            4E000000424D4E000000000000003E0000002800000007000000040000000100
            010000000000100000000000000000000000020000000000000000000000FFFF
            FF00EE000000C60000008200000000000000}
          Layout = blGlyphRight
        end
      end
    end
    object TabSheetPGP: TTabSheet
      ImageIndex = 4
      TabVisible = False
      DesignSize = (
        472
        303)
      object GroupBox4: TGroupBox
        Left = 0
        Top = 0
        Width = 472
        Height = 133
        Anchors = [akLeft, akTop, akRight]
        Caption = 'PGP'
        TabOrder = 0
        DesignSize = (
          472
          133)
        object PGPKeyLabel: TLabel
          Left = 12
          Top = 39
          Width = 87
          Height = 13
          Caption = 'Cl'#233' &priv'#233'e:'
          Enabled = False
        end
        object PGPPasswordLabel: TLabel
          Left = 12
          Top = 87
          Width = 46
          Height = 13
          Caption = '&Mot de passe:'
          Enabled = False
        end
        object PGPCheckBox: TCheckBox
          Left = 12
          Top = 18
          Width = 97
          Height = 17
          Caption = '&Signature'
          TabOrder = 0
          OnClick = PGPCheckBoxClick
        end
        object PGPKeyCombobox: TComboBox
          Left = 12
          Top = 54
          Width = 448
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          Enabled = False
          ItemHeight = 0
          TabOrder = 1
          OnKeyDown = TextMemoKeyDown
        end
        object PGPPasswordEdit: TEdit
          Left = 12
          Top = 102
          Width = 448
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          Enabled = False
          PasswordChar = ' '
          TabOrder = 2
          OnKeyDown = TextMemoKeyDown
        end
      end
      object GroupBox7: TGroupBox
        Left = 0
        Top = 204
        Width = 472
        Height = 92
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'Information'
        Constraints.MaxHeight = 94
        Constraints.MinHeight = 24
        TabOrder = 1
        DesignSize = (
          472
          92)
        object PGPLabel1: TLabel
          Left = 12
          Top = 13
          Width = 443
          Height = 70
          Anchors = [akLeft, akTop, akRight, akBottom]
          AutoSize = False
          Caption = '-'
          Transparent = True
          Layout = tlCenter
          WordWrap = True
        end
      end
      object GroupBox1: TGroupBox
        Left = 0
        Top = 138
        Width = 472
        Height = 61
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Options'
        TabOrder = 2
        DesignSize = (
          472
          61)
        object PGPCommentLabel: TLabel
          Left = 12
          Top = 15
          Width = 56
          Height = 13
          Caption = '&Commentaires:'
        end
        object PGPCommentEdit: TEdit
          Left = 12
          Top = 30
          Width = 443
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          OnKeyDown = TextMemoKeyDown
        end
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 362
    Width = 480
    Height = 34
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      480
      34)
    object Bevel: TBevel
      Left = 0
      Top = 0
      Width = 480
      Height = 3
      Align = alTop
      Shape = bsTopLine
    end
    object ButtonDone: TButton
      Left = 396
      Top = 7
      Width = 79
      Height = 23
      Anchors = [akTop, akRight]
      Caption = '&Terminer'
      Enabled = False
      TabOrder = 3
      OnClick = ButtonDoneClick
    end
    object ButtonNext: TButton
      Left = 306
      Top = 7
      Width = 79
      Height = 23
      Anchors = [akTop, akRight]
      Caption = '&Suivant >'
      Default = True
      TabOrder = 0
      OnClick = ButtonNextClick
    end
    object ButtonBack: TButton
      Left = 222
      Top = 7
      Width = 79
      Height = 23
      Anchors = [akTop, akRight]
      Caption = '< &Pr'#233'c'#233'dent'
      TabOrder = 1
      OnClick = ButtonBackClick
    end
    object ButtonCancelSend: TButton
      Left = 132
      Top = 7
      Width = 79
      Height = 23
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Annuler'
      ModalResult = 2
      TabOrder = 2
      OnClick = ButtonCancelSendClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    Color = clAppWorkSpace
    FullRepaint = False
    TabOrder = 2
    object Image: TImage
      Left = 0
      Top = 0
      Width = 480
      Height = 49
      Align = alClient
      Stretch = True
    end
  end
end
