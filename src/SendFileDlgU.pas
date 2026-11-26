//
//  PAXON Packet Radio Terminal
//
//  Copyright 1996-2026 Ulf Haueisen <ulf@paxon.app>, Frankfurt, Germany
//
//  This file is part of PAXON.
//
//  SPDX-License-Identifier: MIT
//  PAXON is licensed under the MIT License; see LICENSE.md in the project root.
//


unit SendFileDlgU;


interface


uses
  Windows, Messages, SysUtils, Classes, Forms,
  Graphics, Controls, StdCtrls, ExtCtrls, ComCtrls, CommCtrl, Dialogs, Buttons,
  Menus, FormU,
  GlobalU, InterfacesU, PGPClassU, PageControlUlf, MemoUlfU,
  PublisherU, SendFileTemplatesU, RicheditPaxonU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TSendType = (st_file, st_input);


  PFileEntry = ^TSendFileEntry;
  TSendFileEntry = record
    Name: string;
    SizeValue: Integer;
    Quantity: Integer;
    AllParts: Boolean;
    PartItems: array of Boolean;
  end;


  TSendFileQueueSubscriber = class; // forward


  TStartMode = (sm_normal, sm_dndtext, sm_dndfiles);


  TSendFileDlg = class (TFormUlf)

    ProtocolBevel: TBevel;
    Bevel: TBevel;
    ButtonCancelSend: TButton;
    ButtonRemove: TButton;
    ButtonAdd: TButton;
    ButtonDone: TButton;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    QueueLabel: TLabel;
    FilesListbox: TListBox;
    MailboxGroupbox: TGroupBox;
    MailboxTextAfterCheckbox: TCheckBox;
    MailboxTextAfterMemo: TMemoUlf;
    MailboxTextBeforeCheckbox: TCheckBox;
    MailboxTextBeforeMemo: TMemoUlf;
    QueueNotebook: TNotebook;
    PageControl: TPageControlUlf;
    Panel1: TPanel;
    PGPCheckBox: TCheckBox;
    PGPKeyCombobox: TComboBox;
    PGPKeyLabel: TLabel;
    PGPLabel1: TLabel;
    PGPPasswordEdit: TEdit;
    PGPPasswordLabel: TLabel;
    ProtocolGroupbox: TGroupBox;
    ProtocolLabelInfo: TLabel;
    ProtocolLabelInfoHeading: TLabel;
    ProtocolRadiobuttonAutobin: TRadioButton;
    ProtocolRadiobuttonBinary: TRadioButton;
    ProtocolRadiobuttonText: TRadioButton;
    SendGroupbox: TGroupBox;
    SendRadiobutton1: TRadioButton;
    SendRadiobutton2: TRadioButton;
    TabSheet1: TTabSheet;
    TabSheetFiles: TTabSheet;
    TabSheetText: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheetPGP: TTabSheet;
    TextMemo: TMemo;
    QueueGroupbox: TGroupBox;
    QueueListbox: TListBox;
    QueueDeleteButton: TButton;
    ButtonNext: TButton;
    ButtonBack: TButton;
    GroupBox1: TGroupBox;
    PGPCommentLabel: TLabel;
    PGPCommentEdit: TEdit;
    PageControlUlf1: TPageControlUlf;
    TabSheet4Bin: TTabSheet;
    PartsGroupBox: TGroupBox;
    PartSizeLabel2: TLabel;
    PartSizeLabel1: TLabel;
    PartsCheckbox: TCheckBox;
    PartSizeUpDown: TUpDown;
    PartSizeMemo: TMemoUlf;
    PartsCountListview: TListView;
    TabSheet4Text: TTabSheet;
    WordWrapGroupbox: TGroupBox;
    WordWrapEnabledCheckbox: TCheckBox;
    WordWrapUpDown: TUpDown;
    WordWrapMemo: TMemoUlf;
    ButtonPartsProperties: TButton;
    Label2: TLabel;
    ProtocolRadiobuttonDidadit: TRadioButton;
    Label1: TLabel;
    TemplatesBeforeButton: TBitBtn;
    TemplatesAfterButton: TBitBtn;
    WordwrapCheckBox: TCheckBox;
    Panel2: TPanel;
    Image: TImage;

    procedure   ButtonRemoveClick (Sender: TObject);
    procedure   ButtonAddClick (Sender: TObject);
    procedure   MailboxTextBeforeCheckboxClick (Sender: TObject);
    procedure   MailboxTextAfterCheckboxClick (Sender: TObject);
    procedure   ButtonDoneClick (Sender: TObject);
    procedure   FormCreate (Sender: TObject);
    procedure   FormDestroy (Sender: TObject);
    procedure   PGPCheckBoxClick (Sender: TObject);
    procedure   ProtocolRadiobuttonClick (Sender: TObject);
    procedure   SendRadiobutton1Click (Sender: TObject);
    procedure   SendRadiobutton2Click (Sender: TObject);
    procedure   TextMemoChange (Sender: TObject);
    procedure   ButtonNextClick (Sender: TObject);
    procedure   ButtonBackClick (Sender: TObject);
    procedure   PartSizeMemoChange (Sender: TObject);
    procedure   PartsCheckboxClick (Sender: TObject);
    procedure   PartSizeMemoExit (Sender: TObject);
    procedure   FormClose (Sender: TObject; var Action: TCloseAction);
    procedure   FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure   ButtonPartsPropertiesClick (Sender: TObject);
    procedure   EditTemplatesClick (Sender: TObject);
    procedure   TextMemoKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure   FormKeyUp (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure   TemplatesPopup (Sender: TObject);
    procedure   TemplatesButtonClick (Sender: TObject);
    procedure   TemplatesButtonMouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure   PartsCountListviewChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure   PartsCountListviewDblClick (Sender: TObject);
    procedure   FormShortCut (var Msg: TWMKey; var Handled: Boolean);
    procedure   WordwrapCheckBoxClick (Sender: TObject);
    procedure   FormCloseQuery (Sender: TObject; var CanClose: Boolean);
    procedure ButtonCancelSendClick(Sender: TObject);

  private

    FDialogDone: Boolean;
    FTransferProtocol: TSendFileProtocol;
    PGP: TPGP;
    FileEntries: array of TSendFileEntry;
    FSendFileQueueSubscriber: ISubscriber;
    FChannelSubscriber: ISubscriber;
    FChannel: IChannel;
    FSubscribedQueue: ISendFileQueue;
    FStartMode: TStartMode;
    TemplatesBeforePopup: TPopupMenu;
    TemplatesAfterPopup: TPopupMenu;
    TemplatesBefore: TSendFileTemplates;
    TemplatesAfter: TSendFileTemplates;
    Popup: TPopupMenu;
    AskClose: Boolean;
    InitialProtocol: TSendFileProtocol;

    procedure   SetDialogDone (Value: Boolean);
    property    DialogDone: Boolean read FDialogDone write SetDialogDone;
    procedure   Send (aStream: TStream; FileEntry: PFileEntry; aSendProtocol: TSendFileProtocol);

    procedure   PGPChecked;
    procedure   PGPEnabled (Value: Boolean);
    procedure   UpdateFileList;
    procedure   EnableParts (B: Boolean);
    procedure   SendFileQueueChanged;
    procedure   ChannelChanged;
    procedure   UpdateDone;
    procedure   TemplateClick (Sender: TObject);
    procedure   wmUser (var Msg: TMessage); message WM_USER;
    procedure   UpdatePartsRemarks (LI: TListItem);
    function    PartsAsString (const Parts: array of Boolean; Hex: Boolean): string;

  public

    procedure   Execute (aChannelObj: IChannel); overload;
    procedure   Execute (aChannelObj: IChannel; aText: String); overload;
    procedure   Execute (aChannelObj: IChannel; const aFiles: Array of String); overload;
    procedure   AddFiles (const aFiles: array of String);
    procedure   AddText (const aText: String);

    procedure   BeforeDestruction; override;

  end;


  TSendFileQueueSubscriber = class (TInterfacedObject, ISubscriber)
  private
    FSendFileDlg: TSendFileDlg;
  public
    constructor Create (aSendFileDlg: TSendFileDlg); virtual;
    procedure   Notify (P: Pointer); virtual;
  end;


  TChannelSubscriber = class (TInterfacedObject, ISubscriber)
  private
    FSendFileDlg: TSendFileDlg;
  public
    constructor Create (aSendFileDlg: TSendFileDlg); virtual;
    procedure   Notify (P: Pointer); virtual;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, JPEG, SendFileU, MessageBoxU, SendFilePreprocessorU, ConfigU,
  MainU, SendFilePartsSelectionDlgU, SendFileTemplatesDlgU, FolderU, SynchronizeU,
  Registry;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

ResourceString
  SSendTitle = 'Senden - %s';
  SNeedPGP = 'Um Nachrichten signieren zu können, benötigen Sie PGP 6.5.8 (Freeware).';


procedure   TSendFileDlg.FormCreate (Sender: TObject);
var
  JPEG: TJPEGImage;
  ResStream: TResourceStream;
  Reg: TRegistry;
  S: String;

begin

  inherited;

  FStartMode := sm_normal;

  InitialProtocol := prot_unknown;

  AskClose := true;

  TemplatesBeforePopup := nil;
  TemplatesAfterPopup := nil;
  TemplatesBefore := nil;
  TemplatesAfter := nil;

  Reg := TRegistry.create (KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if (Reg.OpenKey (RootRegKey + '\History', true)) then begin
      try
        S := Reg.ReadString ('SendTextBefore');
      except
        S := '';
      end;
      MailboxTextBeforeMemo.Text := S;
      try
        S := Reg.ReadString ('SendTextAfter');
      except
        S := '';
      end;
      MailboxTextAfterMemo.Text := S;
      Reg.CloseKey;
    end;
  finally
    Reg.free;
  end;

  FSendFileQueueSubscriber := TSendFileQueueSubscriber.create (self);
  FChannelSubscriber := TChannelSubscriber.create (self);

  if (HighColor) then begin
    ResStream := TResourceStream.Create (HInstance, 'SendFileWizard', RT_RCDATA);
    JPEG := TJPEGImage.Create;
    JPEG.LoadFromStream (ResStream);
    Image.Picture.Graphic := JPEG;
    JPEG.Free;
    ResStream.Free;
  end;

  with PageControl do begin
    ActivePage := TabSheet1;
    ButtonBack.Enabled := false;
  end;

  try
    PGP := TPGP.create;
  except
    PGP := nil;
  end;

  if (assigned (PGP)) then begin
    try
      PGPLabel1.Caption := PGP.Version;
      PGPKeyCombobox.Clear;
      PGPKeyCombobox.ItemIndex := PGP.GetPrivateKeys (PGPKeyCombobox.Items);
    except
      on E: Exception do begin
        PGPLabel1.Caption := PGPLabel1.Caption + #13 + E.Message;
        PGP.Free;
        PGP := nil;
      end;
    end;
    PGPCommentEdit.Text := Config.PGPComment;
  end else begin
    PGPLabel1.Caption := SNeedPGP;
  end;

  SendRadiobutton1.Checked := true;
  SendRadiobutton1Click (SendRadiobutton1);

  WordwrapCheckBoxClick (nil);

  DialogDone := false;

end;


procedure   TSendFileDlg.FormCloseQuery (Sender: TObject; var CanClose: Boolean);
resourcestring
  SReallyCancelTextInput = 'Texteingabe wirklich abbrechen?';
begin
  if (AskClose) then begin
    if (SendRadiobutton2.Checked) and (TextMemo.Lines.Count > 0) then begin
      with TDlgMessage.create (self) do begin
        CanClose := (Run (ApplicationName, SReallyCancelTextInput, [mbYes, mbNo]) = mrYes);
        Release;
      end;
    end;
  end;
end;


procedure   TSendFileDlg.FormClose (Sender: TObject; var Action: TCloseAction);
const
  MethodName = 'FormClose';

begin

  DebOut (self, MethodName, 'begin...');

  assert (assigned (FChannel));

  FChannel.SendFileDialogDone;

  // Unsubscribe from the queue actually subscribed to: after a reconnect the
  // connection has another one.
  if (assigned (FSubscribedQueue)) then begin
    (FSubscribedQueue as IPublisher).UnSubscribe (FSendFileQueueSubscriber);
    FSubscribedQueue := nil;
  end;

  (FChannel as IPublisher).UnSubscribe (FChannelSubscriber);

  FChannel := nil;

  Action := caFree;

  DebOut (self, MethodName, 'end.');

end;


procedure   TSendFileDlg.FormDestroy (Sender: TObject);
const
  MethodName = 'FormDestroy';

begin

  DebOut (self, MethodName, 'begin...');

  if (assigned (TemplatesBefore)) then begin
    TemplatesBefore.free;
    TemplatesBefore := nil;
  end;

  if (assigned (TemplatesAfter)) then begin
    TemplatesAfter.free;
    TemplatesAfter := nil;
  end;

  if (assigned (PGP)) then begin
    PGP.free;
    PGP := nil;
  end;

  inherited;

  DebOut (self, MethodName, 'end.');

end;


procedure   TSendFileDlg.Execute (aChannelObj: IChannel; aText: String);
var
  L: Integer;
begin

  FChannel := aChannelObj;
  assert (assigned (FChannel));

  FStartMode := sm_dndtext;

  InitialProtocol := prot_text;

  SendRadiobutton2.Checked := true;
  SendRadiobutton2Click (nil);
  SendRadiobutton1.Enabled := false;
  SendRadiobutton2.Enabled := false;

  TextMemo.Text := aText;
  L := Length (aText);
  DialogDone := (L >= 1);

  PageControl.ActivePage := TabSheetText;
  ButtonBack.Enabled := true;

  Execute (aChannelObj);

end;


procedure   TSendFileDlg.AddFiles (const aFiles: array of String);
// Adds files (folders with their contents) to the file list, without duplicates.
const
  MethodName = 'AddFiles';


  procedure AddFile (const FileName: String);
  begin
    if (FilesListbox.Items.IndexOf (FileName) < 0) then FilesListbox.Items.Add (FileName);
  end;


  procedure ScanDirectories (Path: String);
  var
    SR: TSearchRec;
    I: Integer;
  begin
    DebOut (self, MethodName, Path);
    I := FindFirst (Path + '*', faAnyFile, SR);
    while (I = 0) do begin
      if ((SR.Attr and faVolumeID) = 0) then begin
        if ((SR.Attr and faDirectory) <> 0) then begin
          assert (Length (SR.Name) > 0);
          if (SR.Name[1] <> '.') then begin
            ScanDirectories (IncludeTrailingPathDelimiter (Path + SR.Name));
          end;
        end else begin
          AddFile (Path + SR.Name);
        end;
      end;
      I := FindNext (SR);
    end;
    FindClose (SR);
  end;


var
  I, N: Integer;
  SR: TSearchRec;

begin

  // Files are sent as files: leave the text input mode.
  if (not SendRadiobutton1.Checked) then begin
    SendRadiobutton1.Checked := true;
    SendRadiobutton1Click (nil);
  end;

  for N := 0 to (Length (aFiles) - 1) do begin

    I := FindFirst (aFiles[N], faAnyFile, SR);
    FindClose (SR);
    if (I = 0) then begin

      if ((SR.Attr and faVolumeID) = 0) then begin
        if ((SR.Attr and faDirectory) <> 0) then begin
          ScanDirectories (IncludeTrailingPathDelimiter (aFiles[N]));
        end else begin
          AddFile (aFiles[N]);
        end;
      end;

    end;

  end;

  UpdateFileList;

  DialogDone := (FilesListbox.Items.Count > 0);

end;


procedure   TSendFileDlg.AddText (const aText: String);
// Appends text to the text input (or sets it, if empty) and switches to text input.
var
  S: String;
begin

  if (not SendRadiobutton2.Checked) then begin
    SendRadiobutton2.Checked := true;
    SendRadiobutton2Click (nil);
  end;

  S := TextMemo.Text;
  if (Length (S) > 0) and (not (S[Length (S)] in [#13, #10])) then S := S + #13#10;
  TextMemo.Text := S + aText;

  DialogDone := (TextMemo.Lines.Count >= 1);

  PageControl.ActivePage := TabSheetText;
  ButtonBack.Enabled := true;

end;


procedure   TSendFileDlg.Execute (aChannelObj: IChannel; const aFiles: array of String);
begin

  FChannel := aChannelObj;
  assert (assigned (FChannel));

  FStartMode := sm_dndfiles;

  SendRadiobutton1.Checked := true;
  SendRadiobutton1Click (nil);
  SendRadiobutton1.Enabled := false;
  SendRadiobutton2.Enabled := false;

  TabSheetFiles.Enabled := false;
  TabSheetText.Enabled := false;

  FilesListbox.Items.Clear;
  AddFiles (aFiles);

  ProtocolRadiobuttonAutobin.Checked := true;
  ProtocolRadiobuttonClick (ProtocolRadiobuttonAutobin);

  DialogDone := (FilesListbox.Items.Count > 0);

  Execute (aChannelObj);

end;


procedure   TSendFileDlg.Execute (aChannelObj: IChannel);
const
  MethodName = 'Execute';

var
  V: IConnection;
  R: TRadioButton;

begin

  DebOut (self, MethodName, 'begin...');

  FChannel := aChannelObj;
  assert (assigned (FChannel));

  if (InitialProtocol = prot_unknown) then begin
    V := FChannel.PacketConnection;
    if (assigned (V)) then begin
      if (V.BinMode <> prot_unknown) then InitialProtocol := V.BinMode;
    end;
  end;

  case InitialProtocol of
    prot_text: R := ProtocolRadiobuttonText;
    prot_didadit: R := ProtocolRadiobuttonDidadit;
    else R := ProtocolRadiobuttonAutobin;
  end;

  R.Checked := true;
  ProtocolRadiobuttonClick (R);

  (FChannel as IPublisher).Subscribe (FChannelSubscriber);

  // Also subscribes to the send file queue of the connection.
  ChannelChanged;

  Show;

  DebOut (self, MethodName, 'end.');

end;


procedure   TSendFileDlg.Send (aStream: TStream; FileEntry: PFileEntry; aSendProtocol: TSendFileProtocol);
var
  SendFilePreprocessor: TSendFilePreprocessor;
  S: string;
  I: Integer;

begin

  SendFilePreprocessor := TSendFilePreprocessor.create;
  try

    SendFilePreprocessor.Stream := aStream;
    SendFilePreprocessor.PacketConnection := FChannel.PacketConnection;

    if (assigned (FileEntry)) then begin
      SendFilePreprocessor.FileNameStr := FileEntry.Name;
    end else begin
      SendFilePreprocessor.FileNameStr := '???';
    end;

    SendFilePreprocessor.TransferProtocol := aSendProtocol;

    if (MailboxTextBeforeCheckbox.Checked) then begin
      S := MailboxTextBeforeMemo.Lines.Text;
      I := Length (S);
      if (I > 0) and (S[I] <> #13) then S := S + #13;
    end else begin
      S := '';
    end;
    SendFilePreprocessor.TextBefore := S;

    if (MailboxTextAfterCheckbox.Checked) then begin
      S := MailboxTextAfterMemo.Lines.Text;
      I := Length (S);
      if (I > 0) and (S[I] <> #13) then S := S + #13;
    end else begin
      S := '';
    end;
    SendFilePreprocessor.TextAfter := S;

    if (assigned (FileEntry)) and (PartsCheckbox.Enabled) and (PartsCheckbox.Checked) then begin
      SendFilePreprocessor.SizePerPart := StrToIntDef (PartSizeMemo.Text, 0);
      SendFilePreprocessor.PartsCount := FileEntry.Quantity;
      SendFilePreprocessor.AllParts := FileEntry.AllParts;
      if (not SendFilePreprocessor.AllParts) then begin
        for I := 0 to FileEntry.Quantity - 1 do SendFilePreprocessor.PartItems[I] := FileEntry.PartItems[I];
      end;
    end else begin
      SendFilePreprocessor.SizePerPart := 0;
      SendFilePreprocessor.PartsCount := 0;
    end;

    SendFilePreprocessor.PGP := PGP;
    SendFilePreprocessor.PGPEnabled := (assigned (PGP)) and (PGPCheckBox.Enabled) and (PGPCheckBox.Checked);
    SendFilePreprocessor.PGPKey := nil;
    SendFilePreprocessor.PGPPassword := '';
    SendFilePreprocessor.PGPCommentText := '';
    if SendFilePreprocessor.PGPEnabled then begin
      I := PGPKeyCombobox.ItemIndex;
      if (I >= 0) and (I < PGPKeyCombobox.Items.Count) then begin
        SendFilePreprocessor.PGPKey := PGPKeyCombobox.Items.Objects[I];
        SendFilePreprocessor.PGPPassword := PGPPasswordEdit.Text;
        SendFilePreprocessor.PGPCommentText := PGPCommentEdit.Text;
      end;
    end;

    SendFilePreprocessor.Execute;

  finally

    SendFilePreprocessor.free;

  end;

end;


procedure   TSendFileDlg.ButtonNextClick (Sender: TObject);
var
  T: TTabSheet;
  B: Boolean;
  W: TWinControl;
  I: Integer;
  LI: TListItem;

begin

  with PageControl do begin

    B := false;
    T := Activepage;

    if (T = TabSheetFiles) then begin
      UpdateFileList;
    end;

    while true do begin
      assert (assigned (T));
      if T.PageIndex >= PageCount - 1 then begin
        break;
      end;
      T := Pages[T.PageIndex + 1];
      if T.Enabled then begin
        B := true;
        break;
      end;
    end;

    if not B then exit;

    assert (assigned (T));

    ButtonBack.Enabled := true;
    ActivePage := T;

    B := false;
    while true do begin
      assert (assigned (T));
      if T.PageIndex >= PageCount - 1 then begin
        break;
      end;
      T := Pages[T.PageIndex + 1];
      if T.Enabled then begin
        B := true;
        break;
      end;
    end;
    ButtonNext.Enabled := B;

    W := FindNextControl(ActivePage, true, true, false);
    if (assigned (W)) and (W.CanFocus) then W.SetFocus;

  end;

  T := PageControl.ActivePage;

  if (T = TabSheet4) then begin

    PartsCountListview.Items.Clear;
    if (FTransferProtocol in [prot_autobin, prot_didadit]) then begin
      for I := Low(FileEntries) to High (FileEntries) do begin
        LI := PartsCountListview.Items.Add;
        LI.Caption := ExtractFileName (FileEntries[I].Name);
        LI.SubItems.Add (Format ('%d kB', [(FileEntries[I].SizeValue - 1) div 1024 + 1]));
        LI.SubItems.Add ('');
        LI.SubItems.Add ('');
        UpdatePartsRemarks (LI);
      end;
      B := True;
    end else begin
      B := False;
    end;

    PartsCheckbox.Enabled := B;
    if B then begin
      if not PartsCheckbox.Checked then B := False;
    end else begin
      PartsCheckbox.Checked := False;
    end;
    EnableParts(B);

    PartSizeMemoChange (nil);
    MailboxTextBeforeCheckboxClick (nil);
    MailboxTextAfterCheckboxClick (nil);

  end;

end;


procedure   TSendFileDlg.BeforeDestruction;
begin
  inherited;
end;


procedure   TSendFileDlg.ButtonBackClick (Sender: TObject);
var
  T: TTabSheet;
  W: TWinControl;

begin

  with PageControl do begin

    T := ActivePage;

    if (T = TabSheetFiles) then begin
      UpdateFileList;
    end;

    repeat
      if (T.PageIndex <= 0) then break;
      T := Pages[T.PageIndex - 1];
    until (T = nil) or (T.Enabled = true);

    ButtonBack.Enabled := (T <> nil) and (T.PageIndex >= 1);

    ActivePage := T;

    W := FindNextControl(ActivePage, true, true, false);
    if (assigned (W)) and (W.CanFocus) then W.SetFocus;

    ButtonNext.Enabled := true;

  end;

end;


procedure   TSendFileDlg.PartSizeMemoChange (Sender: TObject);
var
  I, N, M, J, K, Q: Integer;
  LI: TListItem;
begin
  N := StrToIntDef (PartSizeMemo.Text, -1);
  if (N >= 5) and (N <= 10240) then begin
    if (PartsCountListview.Items.Count > 0) and (PartsCountListview.Items.Count = Length (FileEntries)) then begin
      for I := Low(FileEntries) to High (FileEntries) do begin
        LI := PartsCountListview.Items[I];
        J := N * 1024;
        M := (FileEntries[I].SizeValue - 1) div J + 1;
        FileEntries[I].Quantity := M;
        if (not FileEntries[I].AllParts) then begin
          K := Length (FileEntries[I].PartItems);
          SetLength (FileEntries[I].PartItems, M);
          if (M > K) then begin
            for Q := K to M - 1 do FileEntries[I].PartItems[Q] := false;
          end;
        end;
        assert (LI.SubItems.Count >= 1);
        LI.SubItems[1] := Format ('%d', [FileEntries[I].Quantity]);
        UpdatePartsRemarks (LI);
      end;
    end;
  end else begin
    for I := 0 to PartsCountListview.Items.Count - 1 do begin
      LI := PartsCountListview.Items[I];
      assert (LI.SubItems.Count >= 1);
      LI.SubItems[1] := '-';
    end;
  end;
end;


procedure   TSendFileDlg.PartSizeMemoExit (Sender: TObject);
var
  N: Integer;
begin
  N := StrToIntDef (PartSizeMemo.Text, -1);
  if (N < 5) then begin
    PartSizeMemo.Text := '5';
  end else if (N > 10240) then begin
    PartSizeMemo.Text := '10240';
  end;
end;


procedure   TSendFileDlg.EnableParts (B: Boolean);
var
  C: TColor;
begin
  if B then C := clWindow else C := clBtnFace;
  PartSizeLabel1.Enabled := B;
  PartSizeLabel2.Enabled := B;
  PartSizeMemo.Enabled := B;
  PartSizeUpDown.Enabled := B;
  if (not B) then PartsCountListview.Selected := nil;
  PartsCountListview.Enabled := B;
  PartsCountListview.Color := C;
  PartSizeMemo.Color := C;
  ButtonPartsProperties.Enabled := (assigned (PartsCountListview.Selected)) and (B);
end;


procedure   TSendFileDlg.PartsCheckboxClick(Sender: TObject);
begin
  EnableParts ((FTransferProtocol in [prot_autobin, prot_didadit]) and (PartsCheckbox.Checked));
end;


procedure   TSendFileDlg.UpdateFileList;
var
  L, I, N, Q, K: Integer;
  S: string;
  Size64: Int64;
  OldFileEntries: array of TSendFileEntry;
  B: Boolean;

begin

  L := Length (FileEntries);
  SetLength (OldFileEntries, L);
  for N := 0 to L - 1 do OldFileEntries[N] := FileEntries[N];

  N := FilesListbox.Items.Count;

  SetLength (FileEntries, N + L);
  K := 0;
  for I := 0 to N - 1 do begin
    B := false;
    for Q := 0 to L - 1 do begin
      if (AnsiCompareText (OldFileEntries[Q].Name, FilesListbox.Items[I]) = 0) then begin
        B := true;
        break;
      end;
    end;
    if (B) then begin
      FileEntries[K] := OldFileEntries[Q];
      Inc (K);
    end else begin
      S := FilesListbox.Items[I];
      FileEntries[K].Name := S;
      // TSearchRec.Size is an Integer; larger files are rejected when sending.
      Size64 := GetFileSize64 (S);
      if (Size64 < 0) then Size64 := 0;
      if (Size64 > MaxInt) then Size64 := MaxInt;
      FileEntries[K].SizeValue := Size64;
      FileEntries[K].Quantity := 0;
      FileEntries[K].AllParts := true;
      SetLength (FileEntries[K].PartItems, 0);
      Inc (K);
    end;
  end;
  SetLength (FileEntries, K);

end;


procedure   TSendFileDlg.SendRadiobutton1Click (Sender: TObject);
begin
  ProtocolRadiobuttonAutobin.Enabled := true;
  ProtocolRadiobuttonDidadit.Enabled := true;
  TabSheetFiles.Enabled := true;
  TabSheetText.Enabled := false;
end;


procedure   TSendFileDlg.SendRadiobutton2Click (Sender: TObject);
begin
  ProtocolRadiobuttonText.Checked := true;
  ProtocolRadiobuttonClick(ProtocolRadiobuttonText);
  ProtocolRadiobuttonAutobin.Enabled := false;
  ProtocolRadiobuttonDidadit.Enabled := false;
  TabSheetFiles.Enabled := false;
  TabSheetText.Enabled := true;
end;


procedure   TSendFileDlg.MailboxTextBeforeCheckboxClick(Sender: TObject);
var
  C: TColor;
  B: Boolean;
begin
  B := MailboxTextBeforeCheckbox.Checked;
  if B then C := clWindow else C := clBtnFace;
  MailboxTextBeforeMemo.Enabled := B;
  MailboxTextBeforeMemo.Color := C;
  TemplatesBeforeButton.Enabled := B;
  if MailboxTextBeforeMemo.CanFocus then MailboxTextBeforeMemo.SetFocus;
end;


procedure   TSendFileDlg.MailboxTextAfterCheckboxClick(Sender: TObject);
var
  C: TColor;
  B: Boolean;
begin
  B := MailboxTextAfterCheckbox.Checked;
  if B then C := clWindow else C := clBtnFace;
  MailboxTextAfterMemo.Enabled := B;
  MailboxTextAfterMemo.Color := C;
  TemplatesAfterButton.Enabled := B;
  if MailboxTextAfterMemo.CanFocus then MailboxTextAfterMemo.SetFocus;
end;


procedure   TSendFileDlg.PGPCheckBoxClick(Sender: TObject);
begin
  PGPChecked;
end;


procedure   TSendFileDlg.ProtocolRadiobuttonClick(Sender: TObject);
resourcestring
  SDescText = 'Senden Sie Text (*.txt) und 7Plus-Dateien (*.7pl, *.p01, ...) mit diesem Protokoll.';
  SDescAutoBin = 'Benutzen Sie das AutoBin-Protokoll, um Bild-, Programm- und andere binäre Dateien zu übertragen. Wenn Ihre Gegenstation jedoch das neuere Didadit-Protokoll unterstützt, verwenden Sie dieses.';
  SDescDidadit = 'Benutzen Sie Didadit, um Bild-, Programm- und andere binäre Dateien zu übertragen.';

begin

  if ProtocolRadiobuttonText.Checked then begin
    FTransferProtocol := prot_text;
  end else if ProtocolRadiobuttonAutobin.Checked then begin
    FTransferProtocol := prot_autobin;
  end else if ProtocolRadiobuttonBinary.Checked then begin
    FTransferProtocol := prot_binary;
  end else if ProtocolRadiobuttonDidadit.Checked then begin
    FTransferProtocol := prot_didadit;
  end else begin
    FTransferProtocol := prot_unknown;
  end;

  case FTransferProtocol of

    prot_text: begin
      ProtocolLabelInfoHeading.Caption := 'Text';
      ProtocolLabelInfo.Caption := SDescText;
    end;

    prot_autobin: begin
      ProtocolLabelInfoHeading.Caption := 'AutoBin';
      ProtocolLabelInfo.Caption := SDescAutoBin;
    end;

    prot_didadit: begin
      ProtocolLabelInfoHeading.Caption := 'Didadit';
      ProtocolLabelInfo.Caption := SDescDidadit;
    end;

    prot_binary: begin
      ProtocolLabelInfoHeading.Caption := 'Binär';
      ProtocolLabelInfo.Caption := '';
    end;

    else begin
      ProtocolLabelInfoHeading.Caption := '?';
      ProtocolLabelInfo.Caption := '?';
    end;

  end;

  PGPEnabled(FTransferProtocol in [prot_text]);

end;


procedure   TSendFileDlg.ButtonAddClick (Sender: TObject);
resourcestring
  SOpenDialogFilter = 'Alle Dateien (*)|*.*';
  SOpenDialogTitle = 'Datei(en) hinzufügen...';
var
  N: Integer;
  S: string;
  OpenDialog: TOpenDialog;
begin
  Enabled := false;
  SetWindowPos (Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  try
    OpenDialog := TOpenDialog.create (self);
    try
      OpenDialog.DefaultExt := '';
      OpenDialog.FileName := '';
      OpenDialog.Filter := SOpenDialogFilter;
      OpenDialog.FilterIndex := 1;
      OpenDialog.InitialDir := Folders.Reception;
      OpenDialog.Options := [ofAllowMultiSelect, ofEnableSizing, ofHideReadOnly];
      OpenDialog.Title := SOpenDialogTitle;
      if (OpenDialog.Execute) then begin
        for N := 0 to OpenDialog.Files.Count - 1 do begin
          S := OpenDialog.Files[N];
          if (FilesListbox.Items.IndexOf (S) < 0) then begin
            FilesListbox.Items.Add (S);
          end;
        end;
      end;
      if (FilesListbox.Items.Count >= 1) then begin
        DialogDone := true;
      end;
    finally
      OpenDialog.free;
    end;
  finally
    Enabled := true;
    SetWindowPos (Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  end;
end;


procedure   TSendFileDlg.ButtonRemoveClick (Sender: TObject);
var
  N: Integer;
begin
  for N := FilesListbox.Items.Count - 1 downto 0 do begin
    if (FilesListbox.Selected[N]) then begin
      FilesListbox.Items.Delete (N);
    end;
  end;
  if (FilesListbox.Items.Count <= 0) then begin
    DialogDone := false;
  end;
end;


procedure   TSendFileDlg.TextMemoChange (Sender: TObject);
begin
  if (TextMemo.Lines.Count >= 1) then begin
    DialogDone := true;
  end else begin
    DialogDone := false;
  end;
end;


procedure   TSendFileDlg.SetDialogDone (Value: Boolean);
begin
  FDialogDone := Value;
  UpdateDone;
end;


procedure   TSendFileDlg.UpdateDone;
var
  B: Boolean;
begin
  B := FDialogDone and FChannel.IsChannelConnected;
  ButtonDone.Enabled := B;
  ButtonNext.Default := not B;
  ButtonDone.Default := B;
end;


procedure   TSendFileDlg.PGPChecked;
var
  B: Boolean;
begin
  B := (PGPCheckBox.Enabled) and (PGPCheckBox.Checked);
  PGPKeyLabel.enabled := B;
  PGPKeyCombobox.enabled := B;
  PGPPasswordLabel.enabled := B;
  PGPPasswordEdit.enabled := B;
  PGPCommentLabel.enabled := B;
  PGPCommentEdit.enabled := B;
  if (B) and (PGPPasswordEdit.CanFocus) then PGPPasswordEdit.SetFocus;
end;


procedure   TSendFileDlg.PGPEnabled(Value: Boolean);
begin
  if (not assigned (PGP)) then Value := false;
  PGPCheckBox.Enabled := Value;
  PGPChecked;
end;


procedure   TSendFileDlg.ButtonDoneClick (Sender: TObject);
resourcestring
  SInvalidPassword = 'Falsches Passwort.';
  SInvalidPasswordTitle = 'PGP';
  SFileOpenError = 'Datei konnte nicht geöffnet werden. Noch einmal versuchen?';
  SFileOpenErrorTitle = 'Fehler';

const
  MethodName = 'ButtonDoneClick';

var
  Pwd: string;
  Key: Pointer;
  I: Integer;
  Ok: Boolean;
  N: Integer;
  S, T: string;
  Stream: TStream;
  Reg: TRegistry;
  Wrap: Boolean;
  K, L, M: Integer;
  Retry: Boolean;
  SentFiles: TStringList;
  Failed: Boolean;

begin

  Ok := false;

  // Same condition as in Send: a checked but disabled box does not sign.
  if (assigned (PGP)) and (PGPCheckBox.Enabled) and (PGPCheckBox.Checked) then begin

    I := PGPKeyCombobox.ItemIndex;
    if (I >= 0) and (I < PGPKeyCombobox.Items.Count) then begin
      Key := PGPKeyCombobox.Items.Objects[I];
      Pwd := PGPPasswordEdit.Text;
    end else begin
      Key := nil;
      Pwd := '';
    end;

    if (PGP.CheckPassword (Key, Pwd)) then begin
      Ok := true;
    end else begin
      with TDlgMessage.create (self) do begin
        Run (SInvalidPasswordTitle, SInvalidPassword, [mbOk]);
        Release;
      end;
      PGPPasswordEdit.SelectAll;
      if PGPPasswordEdit.CanFocus then PGPPasswordEdit.SetFocus;
    end;

  end else begin

    Ok := true;

  end;

  if (Ok) then begin

    Reg := TRegistry.create (KEY_READ or KEY_WRITE);
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if (Reg.OpenKey (RootRegKey + '\History', true)) then begin
        try
          Reg.WriteString ('SendTextBefore', MailboxTextBeforeMemo.Text);
        except
        end;
        try
          Reg.WriteString ('SendTextAfter', MailboxTextAfterMemo.Text);
        except
        end;
        Reg.CloseKey;
      end;
    finally
      Reg.free;
    end;

    Config.PGPComment := PGPCommentEdit.Text;

    if (SendRadiobutton1.Checked) then begin

      //////////////////////////////////////////////////////////////////////////
      // Send file(s)...
      //////////////////////////////////////////////////////////////////////////

      UpdateFileList;

      Failed := false;
      SentFiles := TStringList.create;
      try

        for N := Low (FileEntries) to High (FileEntries) do begin

          S := FileEntries[N].Name;

          // Sizes beyond MaxInt cannot be announced (AutoBIN, DIDADIT, BinSplit header).
          if (GetFileSize64 (S) > MaxInt) then begin
            DebOut (self, MethodName, 'Datei zu groß, nicht gesendet: ' + S);
            continue;
          end;

          Retry := true;
          Stream := nil;
          while (Retry) do begin
            try
              Stream := TFileStream.create (S, fmOpenRead or
                                            fmShareDenyWrite); // Stream is freed again in SendFilePreprocessor or SendXXX.
              Retry := false;
            except
              Stream := nil;
              with TDlgMessage.create (self) do begin
                Retry := IsPositiveResult (Run (SFileOpenErrorTitle, SFileOpenError, [mbYes, mbNo]));
                Release;
              end;
            end;
          end;

          if (assigned (Stream)) then begin
            // An error in one file must not stop the others, and the files already
            // queued must not be sent a second time on the next click.
            try
              Send (Stream, @FileEntries[N], FTransferProtocol);
              SentFiles.Add (S);
            except
              on E: Exception do begin
                DebOut (self, MethodName, 'Fehler: ' + E.Message);
                Failed := true;
                with TDlgMessage.create (self) do begin
                  Run (SFileOpenErrorTitle, E.Message, [mbOk]);
                  Release;
                end;
              end;
            end;
          end;

        end;

        for N := 0 to SentFiles.Count - 1 do begin
          I := FilesListbox.Items.IndexOf (SentFiles[N]);
          if (I >= 0) then FilesListbox.Items.Delete (I);
        end;

      finally
        SentFiles.free;
      end;

      // On an error the dialog stays open with the files not sent.
      if (Failed) then begin
        UpdateFileList;
        DialogDone := (FilesListbox.Items.Count > 0);
        exit;
      end;

    end else if SendRadiobutton2.Checked then begin

      //////////////////////////////////////////////////////////////////////////
      // Send text input...
      //////////////////////////////////////////////////////////////////////////

      Wrap := WordwrapCheckBox.Checked;
      Stream := TMemoryStream.create; // Stream is freed again in SendFilePreprocessor or SendXXX.
      S := TextMemo.Lines.Text;
      with Stream as TMemoryStream do begin
        K := 1;
        L := Length (S);
        for I := 1 to L do begin
          if (I = L) or (S[I] = #13) then begin
            T := copy (S, K, I - K + 1);
            K := I + 1;
            if (K <= L) and (S[K] = #10) then Inc (K);
            if (Wrap) then T := WrapTextUlf (T, #13, [#13, #10, ' '], 78);
            M := Length (T);
            if (M > 0) then Write (T[1], M);
          end;
        end;
      end;
      Send (Stream, nil, FTransferProtocol);

    end;

    AskClose := false;

    Close;

  end;

end;


procedure   TSendFileDlg.SendFileQueueChanged;
const
  MethodName = 'SendFileQueueChanged';
var
  N: Integer;
  B: Boolean;
  FileSender: ISendFile;
  V: IConnection;
  Queue: ISendFileQueue;
begin
  DebOut (self, MethodName, 'begin...');
  V := FChannel.PacketConnection;
  // Fetch the queue once: the connection may close in between.
  Queue := nil;
  if (assigned (V)) then Queue := V.SendFileQueue;
  if (assigned (Queue)) then begin
    with Queue do begin
      Lock;
      try
        if (Count >= 1) then begin
          QueueListbox.Items.Clear;
          for N := 0 to count - 1 do begin
            FileSender := Items[N];
            if (assigned (FileSender)) then QueueListbox.Items.Add (FileSender.TargetFilename);
          end;
          B := true;
        end else begin
          B := false;
        end;
        if B then begin
          QueueNotebook.PageIndex := 0;
        end else begin
          QueueNotebook.PageIndex := 1;
        end;
      finally
        UnLock;
      end;
    end;
  end else begin
    QueueNotebook.PageIndex := 2;
  end;
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileDlg.ChannelChanged;
resourcestring
  SNotConnected = 'nicht verbunden';
var
  V: IConnection;
  S: String;
  Queue: ISendFileQueue;
begin
  // Fetch the connection only once: the device thread can set it to nil at any time.
  V := FChannel.PacketConnection;
  if (assigned (V)) then begin
    S := V.Call;
    Queue := V.SendFileQueue;
  end else begin
    S := SNotConnected;
    Queue := nil;
  end;
  // After a reconnect the connection has a new queue: move the subscription.
  if (Queue <> FSubscribedQueue) then begin
    if (assigned (FSubscribedQueue)) then begin
      (FSubscribedQueue as IPublisher).UnSubscribe (FSendFileQueueSubscriber);
    end;
    FSubscribedQueue := Queue;
    if (assigned (FSubscribedQueue)) then begin
      (FSubscribedQueue as IPublisher).Subscribe (FSendFileQueueSubscriber);
    end;
  end;
  Caption := Format (SSendTitle, [S]);
  UpdateDone;
  SendFileQueueChanged;
end;


procedure   TSendFileDlg.FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssAlt in Shift) then begin
    if (Key <> vk_f4) then begin
      Key := 0;
      Shift := [];
    end;
  end else begin
    if ((Key in [vk_f1..vk_f12]) and (Shift = [])) then begin
      MainWindow.OnKeyDown (Sender, Key, Shift);
      Key := 0;
      Shift := [];
    end else begin
      inherited;
    end;
  end;
end;


procedure   TSendFileDlg.FormKeyUp (Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssAlt in Shift) then begin
    Key := 0;
    Shift := [];
  end;
end;


procedure   TSendFileDlg.PartsCountListviewDblClick (Sender: TObject);
begin
  ButtonPartsPropertiesClick (Sender);
end;


procedure   TSendFileDlg.ButtonPartsPropertiesClick (Sender: TObject);
var
  SendFilePartsSelectionDlg: TSendFilePartsSelectionDlg;
  LI: TListItem;
  N, I: Integer;
  B: Boolean;
  DE: PFileEntry;

begin

  LI := PartsCountListview.Selected;

  if (assigned (LI)) then begin

    I := LI.Index;
    if (I >= Low (FileEntries)) and (I <= High (FileEntries)) then begin

      DE := @(FileEntries[I]);

      if (DE.AllParts) then begin
        SetLength (DE.PartItems, DE.Quantity);
        for N := 0 to DE.Quantity - 1 do DE.PartItems[N] := true;
      end;

      SendFilePartsSelectionDlg := TSendFilePartsSelectionDlg.create (self);
      try
        SendFilePartsSelectionDlg.Execute (ExtractFileName (DE.Name), DE.PartItems);
      finally
        SendFilePartsSelectionDlg.Release;
      end;

      B := true;
      for N := Low (DE.PartItems) to High (DE.PartItems) do begin
        if (DE.PartItems[N] = false) then begin
          B := false;
          break;
        end;
      end;

      if (B) then begin
        DE.AllParts := true;
        SetLength (DE.PartItems, 0);
      end else begin
        DE.AllParts := false;
      end;

      UpdatePartsRemarks (LI);

    end;

  end;

end;


procedure   TSendFileDlg.UpdatePartsRemarks (LI: TListItem);

var
  DE: PFileEntry;
  I: Integer;

begin
  if (assigned (LI)) then begin
    I := LI.Index;
    if (I >= Low (FileEntries)) and (I <= High (FileEntries)) then begin
      DE := @(FileEntries[I]);
      if (DE.AllParts) then begin
        LI.SubItems[2] := '';
      end else begin
        LI.SubItems[2] := PartsAsString (DE.PartItems, false);
      end;
    end;
  end;
end;


function    TSendFileDlg.PartsAsString (const Parts: array of Boolean; Hex: Boolean): string;

  function AsString (I: Integer): string;
  begin
    if (Hex) then begin
      result := IntToHex (I + 1, 2);
    end else begin
      result := IntToStr (I + 1);
    end;
  end;

resourcestring
  SOnlyPart = 'nur Teil %s.';
  SOnlyParts = 'nur Teile %s.';
  SNoParts = 'keine Teile ausgewählt';

var
  B: Boolean;
  S, T: string;
  N: Integer;
  H: Integer;
  L: Integer;
begin
  result := '';
  B := false;
  S := '';
  H := -1;
  for N := High (Parts) downto Low(Parts) do begin
    if (Parts[N]) then begin
      H := N;
      break;
    end;
  end;
  if H < 0 then begin
    result := SNoParts;
  end else begin
    L := 0;
    for N := Low(Parts) to H do begin
      if (Parts[N]) then inc (L);
    end;
    for N := Low(Parts) to H do begin
      if (Parts[N]) then begin
        if (N < H) and (Parts[N+1]) then begin
          if not B then begin
            B := true;
            S := S + AsString (N) + '..';
          end;
        end else begin
          B := false;
          S := S + AsString (N);
          if N < H then S := S + ', ';
        end;
      end;
    end;
    if (L > 1) then T := SOnlyParts else T := SOnlyPart;
    result := Format (T, [S]);
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TSendFileQueueSubscriber.Create (aSendFileDlg: TSendFileDlg);
begin
  inherited create;
  FSendFileDlg := aSendFileDlg;
end;


procedure   TSendFileQueueSubscriber.Notify (P: Pointer);
const
  MethodName = 'Notify';
begin
  DebOut (self, MethodName, 'begin...');
  Synchronize (FSendFileDlg.SendFileQueueChanged);
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileDlg.TextMemoKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = vk_escape) then begin
    Key := 0;
    Close;
  end else begin
    inherited;
  end;
end;


procedure   TSendFileDlg.TemplatesPopup (Sender: TObject);
resourcestring
  SEditTemplates = 'Vorlagen bearbeiten...';
  SStandardTextBeforeTemplate0 = 's rubrik@dl #10 Titel'#13#10;
  SStandardTextBeforeTemplate1 = 's rubrik@dl #10 %n (%p/%q)'#13#10;
  SStandardTextAfterTemplate0 = '***end'#13#10;
  SStandardTextAfterTemplate1 = 'NNNN'#13#10;
  SStandardTextAfterTemplate2 = '/EX'#13#10;
  SStandardTextAfterTemplate3 = '^Z'#13#10;

var
  P: TPoint;
  M: TMenuItem;
  I: Integer;
  RegKey: String;
  PopupNew: Boolean;
  Templates: TSendFileTemplates;
  DefaultTemplates: array of String;

begin

  PopupNew := false;
  if (Sender = TemplatesBeforeButton) then begin
    RegKey := RootRegKey + '\Templates\SendTextBefore';
    if (not assigned (TemplatesBefore)) then begin
      SetLength (DefaultTemplates, 2);
      DefaultTemplates[0] := SStandardTextBeforeTemplate0;
      DefaultTemplates[1] := SStandardTextBeforeTemplate1;
      TemplatesBefore := TSendFileTemplates.create (RegKey, DefaultTemplates, 1);
    end;
    Templates := TemplatesBefore;
    if (not assigned (TemplatesBeforePopup)) then begin
      TemplatesBeforePopup := TPopupMenu.create (self);
      PopupNew := true;
    end;
    Popup := TemplatesBeforePopup;
  end else if (Sender = TemplatesAfterButton) then begin
    RegKey := RootRegKey + '\Templates\SendTextAfter';
    if (not assigned (TemplatesAfter)) then begin
      SetLength (DefaultTemplates, 4);
      DefaultTemplates[0] := SStandardTextAfterTemplate0;
      DefaultTemplates[1] := SStandardTextAfterTemplate1;
      DefaultTemplates[2] := SStandardTextAfterTemplate2;
      DefaultTemplates[3] := SStandardTextAfterTemplate3;
      TemplatesAfter := TSendFileTemplates.create (RegKey, DefaultTemplates, 1);
    end;
    Templates := TemplatesAfter;
    if (not assigned (TemplatesAfterPopup)) then begin
      TemplatesAfterPopup := TPopupMenu.create (self);
      PopupNew := true;
    end;
    Popup := TemplatesAfterPopup;
  end else begin
    Templates := nil;
    Popup := nil;
  end;

  if (assigned (Templates)) then begin

    if (PopupNew) then begin

      Popup.Images := MainWindow.ImageList;
      Popup.Alignment := paLeft;
      Popup.AutoPopup := false;
      Popup.PopupComponent := Sender as TComponent;
      Popup.TrackButton := tbLeftButton;

      for I := 0 to Templates.Count - 1 do begin

        M := TMenuItem.create (self);
        M.Caption := Templates.GetShortString (I, 320, Screen.MenuFont);
        M.Tag := I;
        M.OnClick := TemplateClick;
        Popup.Items.Add (M);

      end;

      M := TMenuItem.create (self);
      M.Caption := '-';
      Popup.Items.Add (M);

      M := TMenuItem.create (self);
      M.Caption := SEditTemplates;
      M.OnClick := EditTemplatesClick;
      M.ImageIndex := 12;
      Popup.Items.Add (M);

      (*
      M := TMenuItem.create (self);
      M.Caption := 'Aktuellen Text hinzufügen...';
      M.OnClick := EditTemplatesClick;
      TemplatesBeforePopup.Items.Add (M);
      *)

    end;

  end;

  P := (Sender as TWinControl).ClientToScreen (Point (0, (Sender as TWinControl).Height));

  Popup.Popup (P.X, P.Y);

end;


procedure   TSendFileDlg.wmUser (var Msg: TMessage);
begin
end;


procedure   TSendFileDlg.EditTemplatesClick (Sender: TObject);
var
  SendFileTemplatesDlg: TSendFileTemplatesDlg;
  MI: TMenuItem;
  Templates: TSendFileTemplates;

begin

  MI := Sender as TMenuItem;
  assert (assigned (MI));

  Templates := nil;
  if (assigned (TemplatesBeforePopup)) and (MI.Parent = TemplatesBeforePopup.Items) then begin
    Templates := TemplatesBefore;
  end else if (assigned (TemplatesAfterPopup)) and (MI.Parent = TemplatesAfterPopup.Items) then begin
    Templates := TemplatesAfter;
  end;

  if (assigned (Templates)) then begin

    SendFileTemplatesDlg := TSendFileTemplatesDlg.create (self, Templates);
    try
      SendFileTemplatesDlg.ShowModal;
    finally
      SendFileTemplatesDlg.Free;
    end;

    if (Templates = TemplatesBefore) then begin
      TemplatesBeforePopup.free;
      TemplatesBeforePopup := nil;
    end else if (Templates = TemplatesAfter) then begin
      TemplatesAfterPopup.free;
      TemplatesAfterPopup := nil;
    end;

  end;

end;


procedure   TSendFileDlg.TemplateClick (Sender: TObject);
const
  MethodName = 'TemplateClick';

var
  MI: TMenuItem;
  Memo: TCustomMemo;
  Templates: TSendFileTemplates;

begin

  MI := Sender as TMenuItem;

  if (assigned (TemplatesBeforePopup)) and (MI.Parent = TemplatesBeforePopup.Items) then begin
    Memo := MailboxTextBeforeMemo;
    Templates := TemplatesBefore;
  end else if (assigned (TemplatesAfterPopup)) and (MI.Parent = TemplatesAfterPopup.Items) then begin
    Memo := MailboxTextAfterMemo;
    Templates := TemplatesAfter;
  end else begin
    Memo := nil;
    Templates := nil;
  end;

  if (assigned (Templates)) then begin
    Memo.Text := Templates[MI.Tag];
  end;

end;


procedure   TSendFileDlg.TemplatesButtonClick (Sender: TObject);
begin
  inherited;
  TemplatesPopup (Sender);
end;


procedure   TSendFileDlg.TemplatesButtonMouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  TemplatesPopup (Sender);
end;


procedure   TSendFileDlg.PartsCountListviewChange (Sender: TObject; Item: TListItem; Change: TItemChange);
var
  B: Boolean;
begin
  B := false;
  if (assigned (Item)) then begin
    if (Change = ctState) then begin
      if (Item.Selected) then begin
        B := true;
      end;
    end;
  end;
  ButtonPartsProperties.Enabled := B;
end;


procedure   TSendFileDlg.FormShortCut (var Msg: TWMKey; var Handled: Boolean);
begin
  Handled := (Msg.CharCode = VK_MENU);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TChannelSubscriber.Create (aSendFileDlg: TSendFileDlg);
begin
  inherited create;
  FSendFileDlg := aSendFileDlg;
end;


procedure   TChannelSubscriber.Notify (P: Pointer);
const
  MethodName = 'Notify';
begin
  DebOut (self, MethodName, 'begin...');
  Synchronize (FSendFileDlg.ChannelChanged);
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileDlg.WordwrapCheckBoxClick (Sender: TObject);
begin
  TextMemo.WordWrap := WordwrapCheckbox.Checked;
  if (TextMemo.WordWrap) then TextMemo.Scrollbars := ssVertical else TextMemo.Scrollbars := ssBoth;
end;


procedure   TSendFileDlg.ButtonCancelSendClick(Sender: TObject);
begin
  Close;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

