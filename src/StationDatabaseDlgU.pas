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


unit StationDatabaseDlgU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Dialogs,
  Forms, Menus, StdCtrls, CheckLst, ExtCtrls, ComCtrls,
  FormU, StationDatabaseU,
  GlobalU, ImgList, InterfacesU, SoundSettingsU,
  ActnList, TextsFormU, SoundsFormU, RemoteCommandsFormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TStationDatabaseDlg = class (TFormUlf)

    PageControl: TPageControl;
    TabGeneral: TTabSheet;
    TabPasswords: TTabSheet;
    TabRemoteControl: TTabSheet;
    TabTexts: TTabSheet;
    TabSounds: TTabSheet;
    CloseDlgBtn: TButton;
    CallsignListView: TListView;
    Button1: TButton;
    Button2: TButton;
    CallsignImageList: TImageList;
    Panel1: TPanel;
    HeaderLabel: TLabel;
    GeneralGroupBox: TGroupBox;
    NameLabel: TLabel;
    StationTypeLabel: TLabel;
    StationTypeCombobox: TComboBox;
    NameEdit: TEdit;
    NotesGroupBox: TGroupBox;
    NotesMemo: TMemo;
    FirewallGroupBox: TGroupBox;
    FirewallLabel: TLabel;
    FirewallCombobox: TComboBox;
    FirewallCheckbox: TCheckBox;
    GroupBox1: TGroupBox;
    PasswordListview: TListView;
    PasswordAddButton: TButton;
    PasswordRemoveButton: TButton;
    PasswordEditButton: TButton;

    procedure    FormClose (Sender: TObject; var Action: TCloseAction);
    procedure    FormCreate (Sender: TObject);
    procedure    FormDestroy (Sender: TObject);
    procedure    FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure    FormShortCut (var Msg: TWMKey; var Handled: Boolean);

    procedure    RemoveClick (Sender: TObject);
    procedure    FirewallCheckboxClick (Sender: TObject);
    procedure    AddNewEntryClick (Sender: TObject);
    procedure    PasswordRemoveButtonClick (Sender: TObject);
    procedure    PasswordAddButtonClick (Sender: TObject);
    procedure    PasswordListviewDblClick (Sender: TObject);
    procedure    CallsignListViewChange (Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure    CallsignListViewChanging (Sender: TObject; Item: TListItem; Change: TItemChange; var AllowChange: Boolean);
    procedure    CallsignListViewData (Sender: TObject; Item: TListItem);
    procedure    CallsignListViewDataFind (Sender: TObject; Find: TItemFind; const FindString: String; const FindPosition: TPoint;
                                           FindData: Pointer; StartIndex: Integer; Direction: TSearchDirection; Wrap: Boolean;
                                           var Index: Integer);
    procedure    CallsignListViewKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure    CallsignListViewSelectItem (Sender: TObject;  Item: TListItem; Selected: Boolean);
    procedure    CloseDlgBtnClick (Sender: TObject);

  private

    CallsList: TStringList;
    StationEntry: IStationDatabaseEntry;

    // Values shown when the station was selected: only fields changed in the dialog are written back
    FLoadedName: String;
    FLoadedNotes: String;
    FLoadedStationType: Integer;

    TextsForm: TTextsForm;
    SoundsForm: TSoundsForm;
    RemotecommandsForm: TRemotecommandsForm;

    procedure    RefreshPasswordListview; virtual;
    // procedure    EnableControls (Enable: Boolean);

  public

  end;


var
  StationDatabaseDlg: TStationDatabaseDlg;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}

uses
  CommCtrl, DebOutU, StationDatabaseEntryU, StationDatabaseEditDlgU,
  StationDatabasePasswordDlgU, SoundsU, TextsU, MessageBoxU,
  MyCallsU, MyCallU, ConfigU, MainU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TStationDatabaseDlg.CloseDlgBtnClick (Sender: TObject);
begin
  Close;
end;


procedure   TStationDatabaseDlg.FormCreate (Sender: TObject);
const
  MethodName = 'FormCreate';

var
  L: TListItem;
  N: Integer;
  T: TStationType;


  procedure InsertForm (aForm: TForm; aParent: TWinControl);
  var
    N, I: Integer;
    A: Array of TWinControl;

  begin

    aParent.DisableAlign;

    aForm.ClientWidth  := aParent.ClientWidth - 12;
    aForm.ClientHeight := aParent.ClientHeight - 10;

    Forms.Application.ProcessMessages;

    {$IFDEF VER140} MainWindow.ThemeManager.CollectControls (aForm); {$ENDIF}

    N := aForm.ControlCount;
    SetLength (A, N);

    for I := 0 to N - 1 do begin
      A[I] := aForm.Controls[I] as TWinControl;
    end;

    for I := 0 to N - 1 do begin
      A[I].Parent := aParent;
      A[I].Left := A[I].Left + 6;
      A[I].Top := A[I].Top + 3;
    end;

    aParent.EnableAlign;

  end;


var
  bmp: HBitmap;

begin

  DebOut (self, MethodName, 'begin...');

  inherited;

  CallsignImageList.Handle := ImageList_Create (12, 13, ILC_COLOR8 or ILC_MASK, 4, 4);
  bmp := LoadImage (HInstance, 'StationDatabase', IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
  ImageList_AddMasked (CallsignImageList.Handle, bmp, RGB (255, 0, 255));
  DeleteObject (bmp);

  CallsignListView.Columns[0].Width := CallsignListView.ClientWidth - GetSystemMetrics (SM_CYHSCROLL) - 2;

  TextsForm := TTextsForm.create (self);
  InsertForm (TextsForm, TabTexts);
  TextsForm.Init (false);

  RemotecommandsForm := TRemotecommandsForm.create (self);
  InsertForm (RemotecommandsForm, TabRemoteControl);
  RemotecommandsForm.Init (false);

  SoundsForm := TSoundsForm.create (self);
  InsertForm (SoundsForm, TabSounds);
  SoundsForm.Init (false);

  StationEntry := nil;

  PageControl.ActivePage := PageControl.Pages[0];

  // st_first und st_last sind nur Grenzwerte und keine wählbaren Typen.
  for T := st_unknown to Pred (st_last) do begin
    StationTypeCombobox.Items.Add (StationTypeText(T));
  end;

  StationTypeCombobox.ItemIndex := 0;

  FirewallCheckbox.Width := Forms.Application.MainForm.Canvas.TextWidth (FirewallCheckbox.Caption) +
                            (20 * Forms.Application.MainForm.PixelsPerInch div 96);

  FirewallCombobox.Items.Add (SIncomingConnectAccept);
  FirewallCombobox.Items.Add (SIncomingConnectIgnore);
  FirewallCombobox.Items.Add (SIncomingConnectBusy);

  L := nil;

  CallsignListView.Items.BeginUpdate;
  try

    CallsignListView.Items.Clear;

    CallsList := TStringList.create;

    StationDatabase.EnumCalls (CallsList);
    CallsignListView.Items.Count := CallsList.Count;

    N := CallsignListView.Items.Count;
    if (N >= 1) then begin
      L := CallsignListView.Items[0];
      if (assigned (L)) then begin
        L.Selected := true;
        L.Focused := true;
        L.MakeVisible (false);
      end;
    end;

  finally
    CallsignListView.Items.EndUpdate;
  end;

  CallsignListViewSelectItem (CallsignListView, L, true);

  DebOut (self, MethodName, 'end.');

end;


procedure   TStationDatabaseDlg.FormDestroy (Sender: TObject);
begin
  CallsList.Free;
  CallsList := nil;
end;


procedure   TStationDatabaseDlg.RemoveClick (Sender: TObject);
resourcestring
  SRemoveCaption = 'Entfernen';
  SRemove = 'Station wirklich entfernen?';
var
  Call: String;
  L: TListItem;
  M, N, I, K: Integer;
begin
  inherited;
  if (CallsignListView.Items.Count > 0) then begin
    L := CallsignListView.Selected;
    if (assigned (L)) then begin
      with TDlgMessage.create (parent) do begin
        M := Run (SRemoveCaption, SRemove, [mbYes, mbNo]);
        Release;
      end;
      if (M = idyes) then begin
        I := L.Index;
        Call := L.Caption;
        StationEntry := nil;
        if (StationDatabase.Delete (Call)) then begin
          N := CallsignListView.Items.Count - 1;
          CallsignListView.Items.Count := N;
          CallsList.Delete (I);
          CallsignListView.UpdateItems (0, MaxInt);
          if (I < N) then K := I else K := N - 1;
          if (K >= 0) then begin
            L := CallsignListView.Items[K];
            L.Selected := true;
            L.Focused := true;
            L.MakeVisible (false);
            CallsignListViewSelectItem (CallsignListView, L, true);
          end;
        end else begin
          beep;
          StationEntry := StationDatabase.Open (Call);
        end;
      end;
    end;
  end;
  CallsignListView.Invalidate;
end;


procedure   TStationDatabaseDlg.CallsignListViewKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
var
  L: TListItem;
begin
  inherited;
  if (Key = vk_f2) and (Shift = []) then begin
    L := CallsignListView.Selected;
    if assigned (L) then begin
      // L.EditCaption;
      beep;
    end;
  end else if (Key = vk_delete) and (Shift = []) then begin
    RemoveClick (Sender);
  end else if (Key = vk_insert) and (Shift = []) then begin
    AddNewEntryClick (sender);
  end;
end;


procedure   TStationDatabaseDlg.AddNewEntryClick (Sender: TObject);
const
  MethodName = 'AddNewEntryClick';
resourcestring
  NewButtonCaption = 'Neu...';
  SInvalidCallsign = 'Ungültiges Rufzeichen';
  SStationExists = 'Die Station ist bereits in der Datenbank vorhanden.';
  SCannotAddStation = 'Die Station kann nicht angelegt werden.';

var
  N, I: Integer;
  Dialog: TStationDatabaseEditDlg;
  E: IStationDatabaseEntry;
  Callsign: String;
  Item: TListItem;
  HasError: Boolean;

begin
  inherited;
  Dialog := TStationDatabaseEditDlg.create (self);
  try

    repeat
      HasError := true;
      N := Dialog.ShowModal;
      if (N = mrOk) then begin
        Callsign := AnsiUpperCase (Dialog.CallsignEdit.Text);
        if (Length (Callsign) > 0) then begin
          HasError := false;
          for I := 1 to Length (Callsign) do begin
            if (not (Callsign[I] in ['0'..'9', 'A'..'Z', '-'])) then begin
              HasError := true;
              break;
            end;
          end;
        end;
        if (HasError) then begin
          with TDlgMessage.create (self) do begin
            Run (ApplicationName, SInvalidCallsign, [mbOk]);
            Release;
          end;
        end;
      end;
    until (N <> mrOk) or (not HasError);

    if (N = mrOk) and (not HasError) then begin
      I := CallsList.IndexOf (Callsign);
      if (I < 0) then begin
        // Add does not overwrite an existing station. If the station has meanwhile
        // been created elsewhere (e.g. via a remote command), it is only displayed.
        E := StationDatabase.Add (Callsign);
        if (not assigned (E)) then begin
          E := StationDatabase.Open (Callsign);
          with TDlgMessage.create (self) do begin
            if (assigned (E)) then begin
              Run (ApplicationName, SStationExists, [mbOk]);
            end else begin
              Run (ApplicationName, SCannotAddStation, [mbOk]);
            end;
            Release;
          end;
        end;
        if (assigned (E)) then begin
          I := CallsList.Add (Callsign);
          CallsignListView.Items.Count := CallsignListView.Items.Count + 1;
          CallsignListView.UpdateItems (0, MaxInt);
          E := nil;
        end;
      end;
      if (I >= 0) then begin
        Item := CallsignListView.Items[I];
        with Item do begin
          Selected := true;
          Focused := true;
          MakeVisible (false);
        end;
        DebOut (self, MethodName, 'Item.Caption = ' + Item.Caption +#13);
        CallsignListViewSelectItem (CallsignListView, Item, true);
      end;
    end;

  finally
    Dialog.Release;
  end;
  if CallsignListView.CanFocus then CallsignListView.SetFocus;
end;


procedure   TStationDatabaseDlg.FirewallCheckboxClick (Sender: TObject);
var
  IC: TIncomingConnect;
  I: Integer;
begin
  if (FirewallCheckbox.Checked) then begin
    FirewallCombobox.Enabled := true;
    FirewallCombobox.Color := clWindow;
    FirewallLabel.Enabled := true;
    if (assigned (StationEntry)) then begin
      IC := StationEntry.IncomingConnect;
    end else begin
      IC := ic_default;
    end;
    if (IC = ic_default) then IC := Config.IncomingConnect;
    FirewallCombobox.ItemIndex := Ord (IC) - Ord (ic_accept);
  end else begin
    if (assigned (StationEntry)) then begin
      I := FirewallCombobox.ItemIndex + 1;
      if (I < Ord (Low (TIncomingConnect))) or (I > Ord (High (TIncomingConnect))) then I := Ord (Low (TIncomingConnect));
      StationEntry.IncomingConnect := TIncomingConnect (I);
    end;
    FirewallCombobox.Enabled := false;
    FirewallCombobox.Color := clBtnFace;
    FirewallLabel.Enabled := false;
    FirewallCombobox.ItemIndex := Ord (Config.IncomingConnect) - Ord (ic_accept);
  end;
end;


procedure   TStationDatabaseDlg.CallsignListViewChanging (Sender: TObject; Item: TListItem; Change: TItemChange;
                                                          var AllowChange: Boolean);
const
  MethodName = 'CallsignListViewChanging';
var
  S: String;
begin
  if (assigned (Item)) then S := Item.Caption else S := '/nil/';
  DebOut (self, MethodName, '%d %s', [integer(Change), S]);
  inherited;
end;


procedure   TStationDatabaseDlg.CallsignListViewChange (Sender: TObject; Item: TListItem; Change: TItemChange);
const
  MethodName = 'CallsignListViewChange';
var
  S: String;
begin
  if (assigned (Item)) then S := Item.Caption else S := '/nil/';
  DebOut (self, MethodName, '%d %s', [integer(Change), S]);
  inherited;
end;


procedure   TStationDatabaseDlg.CallsignListViewSelectItem (Sender: TObject; Item: TListItem; Selected: Boolean);
resourcestring
  SPropertiesOf = 'Einstellungen für %s:';

const
  MethodName = 'CallsignListViewSelectItem';

var
  E: IStationDatabaseEntry;
  I: Integer;
  S, T: String;
  IC: TIncomingConnect;

begin

  if (assigned (Item)) then S := Item.Caption else S := '/nil/';
  DebOut (self, MethodName, '%d %s', [integer(selected), S]);

  inherited;

  if (assigned (StationEntry)) then begin

    // Only write what was changed in the dialog: values changed meanwhile by others (e.g. the
    // name via //name, the station type via the SID) must not be overwritten with old ones.
    if (NameEdit.Text <> FLoadedName) then StationEntry.Name := NameEdit.Text;

    T := copy (NotesMemo.Text, 1, 16384);
    if (T <> FLoadedNotes) then StationEntry.Notes := T;

    if (StationTypeCombobox.ItemIndex <> FLoadedStationType) then begin
      I := StationTypeCombobox.ItemIndex + Ord (st_unknown);
      if (I <= Ord (st_unknown)) or (I >= Ord (st_last)) then I := Ord (st_unknown);
      StationEntry.StationType := TStationType(I);
    end;

    if (FirewallCheckbox.Checked) then begin
      I := FirewallCombobox.ItemIndex + 1;
      if (I < Ord (Low(TIncomingConnect))) or (I > Ord (High (TIncomingConnect))) then I := Ord (Low(TIncomingConnect));
      IC := TIncomingConnect (I);
    end else begin
      IC := ic_default;
    end;
    // Compared with the stored value, as FirewallCheckboxClick may already have written it
    if (IC <> StationEntry.IncomingConnect) then StationEntry.IncomingConnect := IC;

    SoundsForm.Save;
    TextsForm.Save;
    RemoteCommandsForm.Save;

    StationEntry := nil;

  end;

  if (Selected) then begin

    if (assigned (Item)) then begin

      PageControl.Enabled := true;

      HeaderLabel.Caption := Format (SPropertiesOf, [Item.Caption]);

      E := StationDatabase.Open (Item.Caption);

      if (assigned (E)) then begin

        DebOut (self, MethodName, 'ok.'#13);

        NameEdit.Text := E.Name;

        NotesMemo.Text := E.Notes;

        if (E.StationType > st_unknown) and (E.StationType < st_last) then begin
          StationTypeCombobox.ItemIndex := Ord (E.StationType) - Ord (st_unknown);
        end else begin
          StationTypeCombobox.ItemIndex := 0;
        end;

        if (E.IncomingConnect = ic_default) then begin
          FirewallCheckbox.Checked := false;
          FirewallCombobox.Enabled := false;
          FirewallCombobox.Color := clBtnFace;
          FirewallLabel.Enabled := false;
          FirewallCombobox.ItemIndex := Ord (Config.IncomingConnect) - Ord (ic_accept);
        end else begin
          FirewallCheckbox.Checked := true;
          FirewallCombobox.Enabled := true;
          FirewallCombobox.Color := clWindow;
          FirewallLabel.Enabled := true;
          FirewallCombobox.ItemIndex := Ord (E.IncomingConnect) - Ord (ic_accept);
        end;

        FLoadedName := NameEdit.Text;
        FLoadedNotes := copy (NotesMemo.Text, 1, 16384);
        FLoadedStationType := StationTypeCombobox.ItemIndex;

        SoundsForm.SetNewCall (Item.Caption);
        TextsForm.SetNewCall (Item.Caption);
        RemoteCommandsForm.SetNewCall (Item.Caption);

      end else begin

        DebOut (self, MethodName, 'Fehler.'#13);
        beep;

      end;

      StationEntry := E;

      RefreshPasswordListview;

    end else begin

    end;

  end;

end;


procedure   TStationDatabaseDlg.RefreshPasswordListview;
var
  N: Integer;
  L: TStringList;
  S: string;
  PA: TPasswordKind;
  PV: TPasswordMethod;
begin
  if (assigned (StationEntry)) then begin
    L := TStringList.create;
    try
      StationDatabase.EnumPwds (StationEntry, L);
      PasswordListview.Items.BeginUpdate;
      try
        PasswordListview.Items.Clear;
        for N := 0 to L.Count - 1 do begin
          TStationDatabaseEntry.PasswordStreamNameToStrings (L[N], S, PA, PV);
          with PasswordListview.Items.Add do begin
            Caption := S;
            SubItems.Add (PasswordKindString[PA]);
            SubItems.Add (PasswordMethodString[PV]);
            SubItems.Add (L[N]);
          end;
        end;
      finally
        PasswordListview.Items.EndUpdate;
      end;
    finally
      L.free;
    end;
  end else begin
    PasswordListview.Items.Clear;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TStationDatabaseDlg.CallsignListViewData (Sender: TObject; Item: TListItem);
begin
  assert (assigned (Item));
  with Item do begin
    if (Index >= 0) and (Index < CallsList.Count) then begin
      Caption := CallsList[Index];
    end else begin
      Caption := '???';
    end;
    ImageIndex := 0;
  end;
end;


procedure   TStationDatabaseDlg.CallsignListViewDataFind (Sender: TObject; Find: TItemFind; const FindString: String;
                                                          const FindPosition: TPoint; FindData: Pointer; StartIndex: Integer;
                                                          Direction: TSearchDirection; Wrap: Boolean; var Index: Integer);
const
  MethodName = 'CallsignListViewDataFind';
var
  I: Integer;
  ListView: TListView;
  FindStringU: String;
  S: String;

begin

  inherited;

  DebOut (self, MethodName, FindString + #13);
  ListView := Sender as TListView;
  FindStringU := UpperCase (FindString);

  case Find of

    ifData: begin
    end;

    ifPartialString, ifExactString: begin
      I := StartIndex;
      repeat
        if (I >= Listview.Items.Count) then begin
          if Wrap then I := 0 else Exit;
        end;
        // if Find = ifPartialString then begin
          S := UpperCase (Copy (CallsList[I], 1, Length (FindStringU)));
        // end else begin
        //   S := UpperCase (CallsList[I]);
        // end;
        if (FindStringU = S) then begin
          Index := I;
          break;
        end;
        Inc (I);
      until (I = StartIndex);
    end;

    ifNearest: begin
    end;

  end;
end;


procedure   TStationDatabaseDlg.PasswordAddButtonClick (Sender: TObject);
var
  SDP: TStationDatabasePasswordDlg;
  AddNewEntry: Boolean;
  LI: TListItem;
  StreamName, NewStreamName: string;

begin

  if (assigned (StationEntry)) then begin

    AddNewEntry := (Sender = PasswordAddButton);

    StreamName := '';
    if not AddNewEntry then begin
      if (PasswordListview.Items.Count > 0) then begin
        LI := PasswordListview.Selected;
        if Assigned (LI) then begin
          if (LI.SubItems.Count >= 3) then begin
            StreamName := LI.SubItems[2];
          end;
        end;
      end;
    end;

    if (AddNewEntry) or (StreamName <> '') then begin
      SDP := TStationDatabasePasswordDlg.create (self);
      try
        SDP.AddNewEntry := AddNewEntry;
        if not AddNewEntry then begin
          SDP.StreamName := StreamName;
          SDP.PasswordValue := StationEntry.GetPasswordValue (StreamName);
        end;
        if SDP.ShowModal = mrOk then begin
          assert (assigned (StationEntry));
          // Write the new password first; delete the old one only if it is stored under another
          // name and the new one has been written, so that a write error does not lose both.
          TStationDatabaseEntry.PasswordStringsToStreamName (SDP.OwnCallsign, SDP.PasswordKind, SDP.PasswordMethod,
                                                             NewStreamName);
          StationEntry.SetPasswordValue (SDP.OwnCallsign, SDP.PasswordKind, SDP.PasswordMethod, SDP.PasswordValue);
          if (Length (StreamName) > 0) and (AnsiCompareText (StreamName, NewStreamName) <> 0) and
             (StationEntry.GetPasswordValue (NewStreamName) = SDP.PasswordValue) then begin
            StationEntry.DeletePassword (StreamName);
          end;
        end;
      finally
        SDP.Release;
      end;
    end;

  end;

  RefreshPasswordListview;

end;


procedure   TStationDatabaseDlg.PasswordListviewDblClick(Sender: TObject);
begin
  if Assigned (PasswordListview.Selected) then begin
    PasswordAddButtonClick (PasswordEditButton);
  end else begin
    PasswordAddButtonClick (PasswordAddButton);
  end;
end;


procedure   TStationDatabaseDlg.FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
var
  I: Integer;
begin
  if (Key = vk_tab) and (ssCtrl in Shift) then begin
    I := PageControl.ActivePage.PageIndex;
    if (ssShift in Shift) then Dec (I) else Inc (I);
    if (I < 0) then begin
      I := PageControl.PageCount - 1;
    end else if (I >= PageControl.PageCount) then begin
      I := 0;
    end;
    PageControl.ActivePage := PageControl.Pages[I];
  end;
end;


procedure   TStationDatabaseDlg.PasswordRemoveButtonClick (Sender: TObject);
var
  StreamName: string;
  LI: TListItem;

begin

  StreamName := '';
  if (PasswordListview.Items.Count > 0) then begin
    LI := PasswordListview.Selected;
    if (assigned (LI)) then begin
      if (LI.SubItems.Count >= 3) then begin
        StreamName := LI.SubItems[2];
      end;
    end;
  end;

  if (StreamName <> '') then begin
    StationEntry.DeletePassword (StreamName);
    RefreshPasswordListview;
  end;

end;


procedure   TStationDatabaseDlg.FormClose (Sender: TObject; var Action: TCloseAction);
begin
  // Änderungen an der gewählten Station speichern, auch beim Schließen mit
  // [X] oder Alt+F4 und nicht nur über "Schließen".
  CallsignListViewSelectItem (CallsignListView, nil, false);
  Action := caFree;
  StationDatabaseDlg := nil;
end;


procedure   TStationDatabaseDlg.FormShortCut (var Msg: TWMKey; var Handled: Boolean);
begin
  Handled := (Msg.CharCode = VK_MENU);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  StationDatabaseDlg := nil;

end.

