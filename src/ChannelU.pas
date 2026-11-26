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


unit ChannelU;


interface


uses
  Windows, Messages, SysUtils, Classes, Forms, ActnList,
  Controls, StdCtrls, ComCtrls, ExtCtrls, Dialogs, ImgList, Graphics,
  SyncObjs, Buttons, ActiveX,
  GlobalU, InterfacesU, PublisherU, FileStreamUlfU, ConsoleU, RicheditPaxonU,
  SendFileDlgU, BoxListU, ToolbarU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TChannelButton = TToolbarElement;

  TChannel = class (TInterfacedObject, IChannel, IChannelForConnection, IChannelForBoxlist, ISubscriber, IPublisher)
  private

    Released: Boolean;

    FNo: Integer;
    FChannelActive: Boolean;
    FPacketConnection: IConnection;
    FReceive: Boolean;

    FFileTransferPercent: Single;

    // Set in the connection thread (Notify), read in the main thread: access only via
    // the property FileSender, and work with a local copy.
    FFileSender: ISendFile;

    FSaveCriticalSection: TCriticalSection;
    FOutputCriticalSection: TCriticalSection;
    FConnectionCriticalSection: TCriticalSection;

    FSendFileDialog: TSendFileDlg;
    FPublisher: TPublisher;
    FIsReserved: Boolean;

    FChannelButton: TChannelButton;
    FConsole: TConsole;
    FInputEdit: TRicheditPaxon;

    FSaveStream: TFileStreamUlf;

    FSendDosUmlauts: Boolean;

    SyncWindow: HWND;

    BoxList: TBoxList;

    UpdateActionsSender: TObject;

    function    WriteOutput (aTextColor: Integer; const aText: String): Integer;
    procedure   SetFont (F: TFont);
    procedure   DoSendText (Sender: TObject; Text: String);
    procedure   DoButtonClick (Sender: TObject);
    procedure   FocusChange (Sender: TObject);
    procedure   DisplayStatus;
    function    GetStatus: TConnectionStatus;
    procedure   SetStatus (aStatus: TConnectionStatus);
    procedure   SetImage;
    procedure   UpdateProgress;
    function    GetFileSender: ISendFile;
    procedure   SetFileSender (const Value: ISendFile);
    property    FileSender: ISendFile read GetFileSender write SetFileSender;
    function    GetPacketConnection: IConnection;
    procedure   SetChannelConnection (const aConnectionObj: IConnection);
    procedure   Notify (P: Pointer);
    function    GetIsReserved: Boolean;
    procedure   SetIsReserved (const Value: Boolean);
    procedure   CanCancelChanged;
    procedure   CanCancelChangedSync;

    function    ConsoleHint (Sender: TConsole; HintType: THintType; XT, YT: Integer): string;
    procedure   ConsoleGutterClick (Sender: TConsole; Line: Integer);

    procedure   SaveOutput (const aText: String);

    procedure   CreateSyncWindow;
    procedure   FreeSyncWindow;

    procedure   StatusText (const aText: String; ImageIndex: Integer);

    procedure   ContextPopup (Sender: TObject; MousePos: TPoint; var Handled: Boolean);

    procedure   StatusUpdate (All: Boolean);
    procedure   UpdateActionsSync;

    procedure   SetConsoleRows (const Value: Cardinal);

  public

    constructor Create (aChannelNo: Integer; aQuantity: Integer); virtual;

    procedure   BeforeDestruction; override;

    property    ChannelActive: Boolean read FChannelActive;
    property    Font: TFont write SetFont;
    property    Status: TConnectionStatus read GetStatus write SetStatus;

    function    GetConsole: TConsole;
    procedure   SetConsole(const Value: TConsole);
    property    Console: TConsole read GetConsole write SetConsole;

    procedure   ActivateChannel (aActivate: Boolean);
    procedure   Prompt (const aText: String; aType: TDisplayType);
    procedure   Display (const aText: String; aType: TDisplayType);
    function    ReceiveTextData (const aText: String): Integer;
    procedure   SendTextData (const aText: String);
    procedure   EstablishConnection (aConnectionObj: IConnection);
    procedure   Disconnected (Reason: TDisconnectReason);
    function    IsIncomingConnectionPossible: Boolean;
    function    IsOutgoingConnectionPossible: Boolean;
    function    IsChannelConnected: Boolean;
    procedure   ConnectionEstablished;
    procedure   CallChange;
    function    ButtonControl: TChannelButton;
    function    GetNo: Integer;
    procedure   Restored;
    property    PacketConnection: IConnection read GetPacketConnection;
    procedure   KeyDown (var Key: Word; Shift: TShiftState);
    procedure   Monitor (const aHeader: String; const aText: string; Sent: Boolean);

    procedure   SendFileDialog; overload;
    procedure   SendFileDialog (const aText: String); overload;
    procedure   SendFileDialog (const aFiles: Array of String); overload;
    procedure   SendFileDialogDone;

    procedure   Release;
    procedure   subscribe (Subscriber: ISubscriber);
    procedure   unsubscribe (Subscriber: ISubscriber);
    procedure   NotifySubscribers (P: Pointer);
    property    IsReserved: Boolean read GetIsReserved write SetIsReserved;

    procedure   SaveChannelText;

    procedure   SetShowDOSUmlauts (const Value: Boolean);
    function    GetShowDOSUmlauts: Boolean;
    property    ShowDOSUmlauts: Boolean read GetShowDOSUmlauts write SetShowDOSUmlauts;

    procedure   SetSendDOSUmlauts (const Value: Boolean);
    function    GetSendDOSUmlauts: Boolean;
    property    SendDOSUmlauts: Boolean read GetSendDOSUmlauts write SetSendDOSUmlauts;

    procedure   SetBoxListLine (const Line: Integer);

    procedure   EditCut;
    procedure   EditCopy;
    procedure   EditPaste;
    procedure   EditDelete;
    procedure   EditSelectAll;

    procedure   BoxRead (Toggle: Boolean; Down: Boolean);
    procedure   BoxErase (Toggle: Boolean; Down: Boolean);
    procedure   BoxUncheck (Down: Boolean);
    procedure   BoxRun;

    procedure   StatusChanged;

    procedure   UpdateColors;
    procedure   UpdateActions (Sender: TObject);

    procedure   ClrScr;

    function    GetHint: String;
    property    Hint: String read GetHint;

    procedure   DoShowHint;

    procedure   PactorChangeOver;
    procedure   PactorBreakIn;

    property    ConsoleRows: Cardinal write SetConsoleRows;

    function    IsSendFileDialogActive: Boolean;

    procedure   Print;

  end;

  EChannel = Exception;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  Printers, DebOutU, MainU, ChannelsU, ConnectionU, StationDatabaseU, MessageBoxU,
  FolderU, OverwriteAppendFileFormU, SoundsU, SoundsConstsU,
  ConfigU, SynchronizeU, TextsU, TextsConstsU, DevicesU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  WM_SYNC_OUTPUT = WM_USER + $4031;
  WM_SYNC_STATUSTEXT = WM_USER + $4032;
  WM_SYNC_SETBOXLISTLINE = WM_USER + $4033;
  WM_SYNC_STATUSLINE = WM_USER + $4034;
  WM_SYNC_BUTTONCAPTION = WM_USER + $4035;
  WM_SYNC_BUTTONHINT = WM_USER + $4036;
  WM_SYNC_BUTTONIMAGE = WM_USER + $4037;

  BoldOnReceived = false;

resourcestring
  STimestamp = 'c';
  SMonitorCaption = 'Monitor';


function    SyncWndProc (Window: HWND; Message, wParam, lParam: Longint): Longint; stdcall;
var
  K: TChannel;
  II: Word;

begin

  K := TChannel (GetWindowLong (Window, 0));

  case Message of

    WM_SYNC_OUTPUT: begin
      with K.FConsole do begin
        TextColor := LoWord (wParam);
        II := HiWord (wParam);
        if (II > 0) then begin
          SetGutterImageIndex (II);
        end;
        Result := CursorY;
        WriteString (String (Pointer(lParam)));
      end;
    end;

    WM_SYNC_STATUSTEXT: begin
      with K.FConsole do begin
        TextColor := LoWord (wParam);
        II := HiWord (wParam);
        if (CursorX > 0) then begin
          WriteString (#13);
        end;
        if (II > 0) then begin
          SetGutterImageIndex (II);
        end;
        WriteString (String (Pointer(lParam)));
      end;
      Result := 0;
    end;

    WM_SYNC_SETBOXLISTLINE: begin
      with K.FConsole do begin
        // The line was determined in the connection thread: the console may have
        // been made smaller meanwhile, and -1 means "unknown".
        if (Integer (wParam) >= 0) and (Integer (wParam) < Rows) then begin
          SetGutterImageIndex (4, Integer (wParam));
          if (assigned (ScreenPtrH (Integer (wParam)))) then begin
            ScreenPtrH (Integer (wParam)).LineType := 1;
          end;
        end;
        Result := 0;
      end;
    end;

    WM_SYNC_STATUSLINE: begin
      MainWindow.Statusbar.Panels[wParam].Caption := String (Pointer(lParam));
      Result := 0;
    end;

    WM_SYNC_BUTTONCAPTION: begin
      // MainWindow.ChannelToolbar.BeginUpdate;
      K.FChannelButton.Caption := String (Pointer(lParam));
      // MainWindow.ChannelToolbar.EndUpdate;
      // MainWindow.ChannelToolbar.Invalidate;
      Result := 0;
    end;

    WM_SYNC_BUTTONHINT: begin
      K.FChannelButton.Hint := String (Pointer(lParam));
      Result := 0;
    end;

    WM_SYNC_BUTTONIMAGE: begin
      if (K.FChannelButton.ImageIndex <> wParam) then begin
        K.FChannelButton.ImageIndex := wParam;
        if (BoldOnReceived) then begin
          K.FChannelButton.BoldText := (wParam = 2);
        end;
      end;
      Result := 0;
    end;

    else begin
      Result := DefWindowProc (Window, Message, wParam, lParam);
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor  TChannel.Create (aChannelNo: Integer; aQuantity: Integer);
resourcestring
  SBufferError = 'Fehler beim Öffnen der Textpuffer. Bitte starten Sie Windows neu.';
  SBufferErrorCaption = 'Fehler';

var
  R: TRect;

begin

  assert (MainThreadID = GetCurrentThreadID);

  inherited Create;

  Released := false;

  CreateSyncWindow;

  FSaveCriticalSection := TCriticalSection.create;
  FOutputCriticalSection := TCriticalSection.create;
  FConnectionCriticalSection := TCriticalSection.create;

  FPublisher := TPublisher.create;

  FSendFileDialog := nil;
  FIsReserved := false;
  FSaveStream := nil;
  FSendDosUmlauts := false;
  BoxList := nil;

  FNo := aChannelNo;

  FConsole := TConsole.Create (MainWindow);
  FConsole.Name := Format ('Console%2.2d', [FNo]);

  with FConsole do begin

    if (FNo <> 0) then begin
      Parent := MainWindow.OutputPanel;
      Hide;
    end else begin
      Parent := MainWindow.MonitorPanel;
    end;

    HandleNeeded;

    R := Parent.ClientRect;
    Left           := R.Left;
    Top            := R.Top;
    Width          := R.Right - R.Left;
    Height         := R.Bottom - R.Top;

    Align          := alClient;

    Color          := RGB ($FF, $FF, $FF);

    Cols           := 80;
    GutterImages   := MainWindow.GutterImages;
    HelpContext    := 0;
    Hint           := '';
    LineBreak      := CR;
    if (Config.ConsoleRows < MinConsoleRows) then begin
      Rows         := MinConsoleRows;
    end else if (Config.ConsoleRows > MaxConsoleRows) then begin
      Rows         := MaxConsoleRows;
    end else begin
      Rows         := Config.ConsoleRows;
    end;
    ShowHint       := true;
    TabStop        := (FNo <> 0);
    TabOrder       := 1;
    Tag            := FNo;

    OnHint         := ConsoleHint;
    OnEnter        := FocusChange;
    OnContextPopup := ContextPopup;
    OnGutterClick  := ConsoleGutterClick;

    VirtualMemory  := true;
    FileName       := Format ('%s%sBuffer%2.2x.pxn', [ApplicationDataPath, ChannelList.TextBufferPath, FNo]);

    try
      Active := true;
    except
      with TDlgMessage.create (nil) do begin
        Run (SBufferErrorCaption, SBufferError, [mbOk]);
        Release;
      end;
      Halt (5);
    end;

  end;

  FInputEdit := TRicheditPaxon.Create (MainWindow);
  FInputEdit.Name := Format ('Eingabe%2.2d', [FNo]);

  with FInputEdit do begin

    Parent         := MainWindow.InputPanel;
    Clear;
    Hide;
    Align          := alClient;
    AlignMent      := taLeftJustify;
    BorderStyle    := bsNone;

    Color          := RGB ($FF, $FF, $FF);

    Cursor         := crDefault;
    Enabled        := True;
    with Font do begin
      CharSet := ANSI_CHARSET;
      Color := clBlack;
      Name := ConsoleFontName + ' 08x12';
      Pitch := fpFixed;
      Size := 9;
      Style := [];
    end;
    HideScrollbars := false;
    HideSelection  := True;
    ImeMode        := imDontCare;
    MaxLength      := 0;
    PlainText      := False;
    ReadOnly       := False;
    Scrollbars     := ssVertical;
    WantReturns    := true;
    WantTabs       := true;
    WordWrap       := true;
    OnSendText     := DoSendText;
    OnEnter        := FocusChange;
    OnContextPopup := ContextPopup;

  end;

  FChannelButton := TChannelButton.Create (MainWindow.ChannelToolbar);

  with FChannelButton do begin

    Name := Format ('ChannelButton%2.2d', [FNo]);

    if (FNo = 0) then Caption := SMonitorCaption else Caption := '         ';

    GroupIndex := 9;
    OnClick := DoButtonClick;
    DisplayMode := anImageAndText;
    Tag := FNo;
    Visible := true;
    ImageIndex := 0;
    BoldText := false;

  end;

  with MainWindow.ChannelToolbar.Items do begin
    if (aChannelNo = 0) then begin
      Add (FChannelButton);
    end else begin
      Insert (Count - 1, FChannelButton);
    end;
  end;

  UpdateColors;

  FChannelActive := false;

end;


procedure    TChannel.Release;
const
  MethodName = 'Release';

var
  V: IConnection;

begin

  if (not Released) then begin

    DebOut (self, MethodName, 'begin...');

    Released := true;

    FIsReserved := true;

    FreeSyncWindow;

    SendFileDialogDone;

    FSaveCriticalSection.Enter;
    try
      if (assigned (FSaveStream)) then begin
        FSaveStream.Close;
        FSaveStream.Free;
        FSaveStream := nil;
      end;
    finally
      FSaveCriticalSection.Leave;
    end;

    if (assigned (BoxList)) then begin
      BoxList.free;
      BoxList := nil;
    end;

    V := PacketConnection;
    if (assigned (V)) then begin
      V.ChannelRef := nil;
      SetChannelConnection (nil);
    end;

    if (assigned (FInputEdit)) then begin
      RevokeDragDrop (FInputEdit.Handle);
      FInputEdit.Free;
      FInputEdit := nil;
    end;

    if (assigned (FChannelButton)) then begin
      FChannelButton.free;
      FChannelButton := nil;
    end;

    if (assigned (FConsole)) then begin
      FConsole.Free;
      FConsole := nil;
    end;

    FreeAndNil (FPublisher);

    DebOut (self, MethodName, 'end.');

  end else begin

    DebOut (self, MethodName, 'already released');

  end;

end;


procedure    TChannel.BeforeDestruction;
const
  MethodName = 'BeforeDestruction';

begin

  DebOut (self, MethodName, 'begin...');

  Release;

  FSaveCriticalSection.free;
  FSaveCriticalSection := nil;

  FOutputCriticalSection.free;
  FOutputCriticalSection := nil;

  FConnectionCriticalSection.free;
  FConnectionCriticalSection := nil;

  inherited;

  DebOut (self, MethodName, 'end.');

end;


function    TChannel.WriteOutput (aTextColor: Integer; const aText: String): Integer;
begin
  SaveOutput (aText);
  result := SendMessage (SyncWindow, WM_SYNC_OUTPUT, MakeLong (aTextColor, 0), Integer(Pointer(aText)));
end;


procedure   TChannel.SetBoxListLine (const Line: Integer);
begin
  SendMessage (SyncWindow, WM_SYNC_SETBOXLISTLINE, Line, 0);
end;


procedure   TChannel.SaveOutput (const aText: String);
var
  L, N, I: Integer;
  S: String;
begin
  L := Length (aText);
  if (L > 0) then begin
    FSaveCriticalSection.Enter;
    try
      if (assigned (FSaveStream)) then begin
        SetLength (S, 2 * L);
        I := 0;
        for N := 1 to L do begin
          inc (I);
          S[I] := aText[N];
          if (S[I] = #13) then begin
            inc (I);
            S[I] := #10;
          end;
        end;
        FSaveStream.Write (S[1], I);
      end;
    finally
      FSaveCriticalSection.Leave;
    end;
  end;
end;


procedure    TChannel.Prompt (const aText: String; aType: TDisplayType);
const
  MethodName = 'Prompt';

var
  T, U, V, W: String;
  B, D: Boolean;
  I, N: Integer;

begin

  DebOut (self, MethodName, 'begin...');

  T := aText;

  I := Length (T);
  if I > 0 then begin
    if T[I] <> #13 then begin
      T := T + #13;
    end;
  end;

  Display (#13, aType);

  U := RemotePrompt;
  B := true;

  while Length (T) > 0 do begin

    I := Pos (#13, T);
    if I <= 0 then I := MaxInt;
    V := Copy (T, 1, I - 1);
    Delete (T, 1, I);

    N := Length (V);

    while true do begin

      if (N > (72 - Length (U))) then begin
        D := true;
        for I := 72 - Length (U) downto 1 do begin
          if V[I] in [' ', '@', '.', ',', ':'] then begin
            W := Trim (Copy (V, 1, I));
            delete (V, 1, I);
            D := false;
            break;
          end;
        end;
        if D then begin
          W := V;
          V := '';
        end;
      end else begin
        W := V;
        V := '';
      end;

      Display (U + W + #13, aType);

      if B then begin
        B := false;
        FillChar (U[1], Length (U), 32);
      end;

      N := Length (V);
      if N <= 0 then break;

    end;

  end;

  Display (#13, aType);

  DebOut (self, MethodName, 'end.');

end;


procedure    TChannel.Display (const aText: String; aType: TDisplayType);
var
  Color: Integer;
begin
  case aType of
    dt_status:  Color := 15;
    dt_receive: Color := 10;
    dt_send:    Color :=  1;
    dt_pgp:     Color :=  8;
    else        Color :=  9;
  end;
  SendMessage (SyncWindow, WM_SYNC_OUTPUT, Color, Integer(Pointer(aText)));
end;


procedure    TChannel.Monitor (const aHeader: String; const aText: string; Sent: Boolean);
begin
  SaveOutput (#13 + aHeader + #13 + aText);
  FOutputCriticalSection.Enter;
  if (Sent) then begin
    SendMessage (SyncWindow, WM_SYNC_OUTPUT, 1, Integer(Pointer(aHeader + #13)));
  end else begin
    SendMessage (SyncWindow, WM_SYNC_OUTPUT, 10, Integer(Pointer(aHeader + #13)));
  end;
  if (Length (aText) > 0) then begin
    SendMessage (SyncWindow, WM_SYNC_OUTPUT, 5, Integer(Pointer(aText + #13)));
  end;
  FOutputCriticalSection.Leave;
end;


procedure    TChannel.SetFont (F: TFont);
var
  I: Integer;
begin
  assert (assigned (FConsole));
  FConsole.Font.assign (F);
  if assigned (FInputEdit) then begin
    with FInputEdit do begin
      with Font do begin
        CharSet := ANSI_CHARSET;
        Color := clBlack;
        Name := F.Name;
        Pitch := fpFixed;
        Size := F.Size;
        Style := [];
      end;
      Refresh;
      ShowSelection (false);
      I := SelStart;
      SelStart := 0;
      SelLength := $7FFFFFFF;
      SelAttributes.Name := F.Name;
      SelAttributes.Size := F.Size;
      DefAttributes.Name := F.Name;
      DefAttributes.Size := F.Size;
      SelStart := I;
      ShowSelection (true);
    end;
  end;
end;


procedure   TChannel.ActivateChannel (aActivate: Boolean);
const
  MethodName = 'ActivateChannel';

var
  FocusSet: Boolean;
  WasActive: Boolean;
  V: IConnection;
  D: ISendFile;

begin

  assert (MainThreadID = GetCurrentThreadID);

  WasActive := FChannelActive;
  FChannelActive := aActivate;

  if (FChannelActive) then begin

    ChannelList.ActionChannel := (self as IChannel);

    V := PacketConnection;

    if (assigned (V)) then begin
      V.Status.ChannelRef := self;
      // read once: the connection thread may end the transfer meanwhile
      D := V.FileSender;
      if (assigned (D)) then (D as IPublisher).subscribe (self);
      D := nil;
    end;

    FReceive := false;

    if (not WasActive) then begin

      if (assigned (FChannelButton)) then begin
        FChannelButton.Checked := true;
      end;
      DisplayStatus;
      if (assigned (FConsole)) then begin
        if (FNo = 0) then begin
          FConsole.Parent := MainWindow.OutputPanel;
          FConsole.TabStop := true;
        end;
        FConsole.Show;
      end;
      if (assigned (FInputEdit)) then begin
        FInputEdit.Show;
      end;

      StatusUpdate (true);
      CanCancelChanged;

    end;

    UpdateActions (nil);

    FSaveCriticalSection.Enter;
    try
      MainWindow.ActionSave.Checked := assigned (FSaveStream);
    finally
      FSaveCriticalSection.Leave;
    end;

    MainWindow.ActionShowDosUmlauts.Checked := FConsole.ShowDOS;
    MainWindow.ActionSendDosUmlauts.Checked := FSendDosUmlauts;

    FocusSet := false;
    if (assigned (FSendFileDialog)) and (FSendFileDialog.CanFocus) and (FSendFileDialog.Visible) then begin
      if (not FSendFileDialog.Active) then begin
        SetWindowPos (FSendFileDialog.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
        try
          FSendFileDialog.SetFocus;
          FocusSet := true;
        except
        end;
      end else begin
        SetWindowPos (FSendFileDialog.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
      end;
    end;

    if (not FocusSet) then begin
      if (MainWindow.Visible) and (not MainWindow.Active) then begin
        Windows.SetFocus (MainWindow.Handle);
      end;
      if (assigned (FInputEdit)) then begin
        Windows.SetFocus (FInputEdit.Handle);
        try
          FInputEdit.SetFocus;
        except
        end;
      end;
    end;

    MainWindow.ProgressBar.Repaint;

  end else begin

    V := PacketConnection;
    if (assigned (V)) then V.Status.ChannelRef := nil;

    // End of the file transfer is not detected with unsubscribe!
    //
    // if (assigned (FPacketConnection)) and (assigned (FPacketConnection.FileSender)) then begin
    //   (FPacketConnection.FileSender as IPublisher).unsubscribe (self);
    // end;

    if (FNo = 0) then begin
      FConsole.Parent := MainWindow.MonitorPanel;
      FConsole.TabStop := false;
      FConsole.ScrollBottom;
    end else begin
      FConsole.Hide;
    end;
    if (assigned (FInputEdit)) then FInputEdit.Hide;
    if (assigned (FChannelButton)) then FChannelButton.Checked := false;

    if (assigned (FSendFileDialog)) and (FSendFileDialog.CanFocus) and (FSendFileDialog.Visible) then begin
      SetWindowPos (FSendFileDialog.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    end;

  end;

  SetImage;

end;


procedure    TChannel.DoSendText (Sender: TObject; Text: String);
resourcestring
  SNoUIPort = 'Kein Kanal für UI-Pakete ausgewählt.';
  SNoUIDestination = 'Kein Ziel für UI-Pakete ausgewählt.';
  SNoUIMycall = 'Kein eigenes Rufzeichen für UI-Pakete ausgewählt.';

var
  RadioChannels: Array of IRadioChannel;
  N, I: Integer;
  S: String;
  FK: IRadioChannel;
  V: IConnection;
begin
  if (FNo > 0) then begin
    V := PacketConnection;
    if (assigned (V)) then begin
      if (Length (Text) > 0) then begin
        if (FSendDosUmlauts) then begin
          CharToOem (PChar(Text), PChar(Text));
        end;
        V.SendTextData (Text, true, true, (V.StationType in [st_unknown, st_terminal, st_box]));
        Sounds.PlayEvent (se_tx, V);
      end;
    end;
  end else begin
    S := Config.UIPort;
    SetLength (RadioChannels, 256);
    N := DeviceList.RadioChannels (RadioChannels);
    SetLength (RadioChannels, N);
    FK := nil;
    for I := 0 to N - 1 do begin
      if (RadioChannels[I].ID = S) then begin
        FK := RadioChannels[I];
        break;
      end;
    end;
    if (Length (Config.UIDestination) = 0) then begin
      with TDlgMessage.create (MainWindow) do begin
        Run (ApplicationName, SNoUIDestination, [mbOk]);
        Release;
      end;
    end else begin
      if (Length (Config.UIMyCall) = 0) then begin
        with TDlgMessage.create (MainWindow) do begin
          Run (ApplicationName, SNoUIMyCall, [mbOk]);
          Release;
        end;
      end else begin
        if (assigned (FK)) then begin
          FK.SendUI (Config.UIDestination, Config.UIMyCall, Text);
        end else begin
          with TDlgMessage.create (MainWindow) do begin
            Run (ApplicationName, SNoUIPort, [mbOk]);
            Release;
          end;
        end;
      end;
    end;
  end;
end;


procedure   TChannel.DoButtonClick (Sender: TObject);
begin
  ChannelList.CurrentChannelNo := (Sender as TChannelButton).Tag;
end;


function    TChannel.ReceiveTextData (const aText: String): Integer;
var
  V: IConnection;
begin
  result := WriteOutput (10, aText);
  if (not FChannelActive) then FReceive := true;
  SetImage;
  if (aText <> '') and (aText <> #13) and (assigned (Sounds)) then begin
    V := PacketConnection;
    if (FChannelActive) then begin
      Sounds.PlayEvent (se_rx_active, V);
    end else begin
      Sounds.PlayEvent (se_rx_inactive, V);
    end;
  end;
end;


procedure    TChannel.SendTextData (const aText: String);
begin
  WriteOutput (1, aText);
end;


procedure    TChannel.StatusText (const aText: String; ImageIndex: Integer);
begin
  SaveOutput (#13 + aText);
  SendMessage (SyncWindow, WM_SYNC_STATUSTEXT, MakeLong (15, ImageIndex), Integer(Pointer(aText)));
end;


procedure    TChannel.EstablishConnection (aConnectionObj: IConnection);
begin
  if (Released) then begin
    SetChannelConnection (nil);
  end else begin
    SetChannelConnection (aConnectionObj);
    if (assigned (aConnectionObj)) then begin
      if (FChannelActive) then aConnectionObj.Status.ChannelRef := self;
      CallChange;
    end else begin
      FIsReserved := false;
    end;
    StatusUpdate (true);
    UpdateActions (nil);
  end;
end;


procedure    TChannel.CallChange;
const
  MethodName = 'CallChange';

resourcestring
  SUnknownName = 'Unbekannt';
  SName = 'Name';
  SType = 'Typ';

var
  E: IStationDatabaseEntry;
  S, T: String;
  V: IConnection;

begin

  DebOut (self, MethodName, 'begin...');

  V := PacketConnection;

  assert (assigned (FChannelButton));
  assert (assigned (V));

  DebOut (self, MethodName, 'Call %s MyCall %s', [V.Call, V.MyCall]);

  S := V.Call;
  SendMessage (SyncWindow, WM_SYNC_BUTTONCAPTION, 0, Integer(Pointer(S)));

  E := V.StationDatabaseEntry;

  if (assigned (E)) then begin
    T := E.Name;
  end else begin
    T := SUnknownName;
  end;

  S := Format ('%s'#13'%s: %s'#13'%s: %s|', [V.Path, SName, T, SType, StationTypeText(V.StationType)]);
  SendMessage (SyncWindow, WM_SYNC_BUTTONHINT, 0, Integer(Pointer(S)));

  NotifySubscribers (nil);

  DebOut (self, MethodName, 'end.');

end;


procedure    TChannel.ConnectionEstablished;
const
  MethodName = 'ConnectionEstablished';

resourcestring
  SConnectedTo = '%s: Verbunden mit %s';
  SConnectedVia = ' (via %s)';

var
  S: String;
  V: IConnection;

begin

  V := PacketConnection;

  assert (assigned (V));
  DebOut (self, MethodName, 'begin...');

  S := Format (SConnectedTo, [V.MyCall, V.Call]);
  if Length (V.Digis) > 0 then S := S + Format (SConnectedVia, [V.Digis]);
  S := S + #13;
  if (Config.Timestamp) then S := S + FormatDateTime (STimestamp, Now) + #13;

  StatusText (S, 5);

  if (not FChannelActive) then FReceive := true;

  SetImage;

  if (assigned (MainWindow)) and (MainWindow.IsReady) and (not IsWindowVisible (MainWindow.Handle)) then begin
    FlashWindow (MainWindow.Handle, true);
    FlashWindow (Forms.Application.Handle, true);
    FlashWindow (MainWindow.Handle, true);
    FlashWindow (Forms.Application.Handle, true);
  end;

  DebOut (self, MethodName, 'end.');

end;


procedure    TChannel.Restored;
begin
  assert (assigned (FPacketConnection));
  UpdateActions (nil);
  SetImage;
end;


procedure    TChannel.Disconnected (Reason: TDisconnectReason);
resourcestring
  SDisconnectedFrom = '%s: Getrennt von %s';
  SDisconnectedFromFailure = '%s: Verbindungsfehler. Getrennt von %s';
  SDisconnectedFromBusy = '%s: Besetzt. Getrennt von %s';
  SDisconnectedVia = ' (via %s)';

var
  S: String;
  T: String;
  V: IConnection;

begin

  // Local reference: the main thread may set FPacketConnection to nil at the same time.
  V := PacketConnection;

  if (assigned (V)) then begin

    S := V.Call;
    if (Length (V.Digis) > 0) then S := S + Format (SDisconnectedVia, [V.Digis]);

    case Reason of
      dr_normal:      T := Format (SDisconnectedFrom,        [V.MyCall, S]);
      dr_linkfailure: T := Format (SDisconnectedFromFailure, [V.MyCall, S]);
      dr_busy:        T := Format (SDisconnectedFromBusy,    [V.MyCall, S]);
    end;

    T := T + #13;
    if (Config.Timestamp) then T := T + FormatDateTime (STimestamp, Now) + #13;
    T := T + #13;

    StatusText (T, 6);

  end;

  S := '         ';
  SendMessage (SyncWindow, WM_SYNC_BUTTONCAPTION, 0, Integer(Pointer(S)));
  S := '|';
  SendMessage (SyncWindow, WM_SYNC_BUTTONHINT, 0, Integer(Pointer(S)));

  if (assigned (V)) then V.Status.ChannelRef := nil;
  StatusUpdate (true);

  SetChannelConnection (nil);

  if not FChannelActive then FReceive := true;
  SetImage;
  NotifySubscribers (nil);

  UpdateActions (nil);

  FIsReserved := false;

end;


function     TChannel.GetStatus: TConnectionStatus;
var
  V: IConnection;
begin
  V := PacketConnection;
  if (assigned (V)) then begin
    result := V.ConnectionStatus;
  end else begin
    result := vs_disconnected;
  end;
end;


procedure    TChannel.SetStatus (aStatus: TConnectionStatus);
begin
  if (FChannelActive) then DisplayStatus;
end;


procedure    TChannel.DisplayStatus;

resourcestring
  SStateDisconnect = 'Trenne...';
  SStateDisconnected = 'Getrennt';
  SStateConnect = 'Verbinde...';
  SStateConnected = 'Verbunden';

  SFilenameUnknown = '(unbekannt)';

var
  A: TConnectionStatus;
  N: Integer;
  S: String;
  T: array[low(TConnectionStatus)..high (TConnectionStatus)] of string;
  V: IConnection;
  D: ISendFile;

begin

  T[vs_disconnected] := SStateDisconnected;
  T[vs_disconnect] := SStateDisconnect;
  T[vs_connect] := SStateConnect;
  T[vs_connected] := SStateConnected;

  if (FNo > 0) then begin

    A := Status;

    D := FileSender;

    if (assigned (D)) and (assigned (FPacketConnection)) then begin

      if (A = vs_connected) then begin
        case D.Active of
          fts_preparing: begin
            S := 'Warte...';
          end;
          fts_transferring: begin
            S := D.TargetFilename;
            if (S = '') then S := SFilenameUnknown;
            if (D.Absolute > 0) then begin
              S := Format ('%s (%dk)', [S, Round (D.Absolute / 1024)]);
            end;
          end;
        end;
      end else begin
        S := T[A];
      end;
      SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 1, Integer(Pointer(S)));

    end else begin

      S := T[A];
      SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 0, Integer(Pointer(S)));

      // Fetch only the file name under the lock. SendMessage waits for the
      // main thread, which in turn may wait for the lock in ActivateChannel/SaveChannelText.
      FSaveCriticalSection.Enter;
      try
        if (assigned (FSaveStream)) then begin
          S := ExtractFileName (FSaveStream.FileName);
        end else begin
          S := '';
        end;
      finally
        FSaveCriticalSection.Leave;
      end;
      SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 1, Integer(Pointer(S)));

    end;

    // Field 7 (AX.25 state busy/rbusy/reject/frmr) belongs to StatusUpdate while a connection
    // exists; it writes the field only when it changes, so do not clear it here.
    V := PacketConnection;
    if (assigned (V)) and (V.ConnectionStatus >= vs_disconnect) then begin
      S := V.MyCall;
    end else begin
      S := '';
      SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 7, Integer(Pointer(S)));
    end;
    SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 8, Integer(Pointer(S)));

  end else begin

    S := '';
    for N := 1 to 6 do begin
      SendMessage (SyncWindow, WM_SYNC_STATUSLINE, N, Integer(Pointer(S)));
    end;

  end;

  Synchronize (UpdateProgress);

end;


procedure    TChannel.UpdateProgress;
begin
  if (assigned (FileSender)) then begin
    if (not MainWindow.ProgressBar.visible) then begin
      MainWindow.ProgressBar.visible := true;
      MainWindow.ProgressLabel.visible := true;
      MainWindow.ProgressBar.Repaint;
    end;
    if (MainWindow.ProgressBar.Progress <> FFileTransferPercent) then begin
      MainWindow.ProgressLabel.Caption := Format ('%1.1f%%', [FFileTransferPercent]);
      MainWindow.ProgressBar.Progress := Round (FFileTransferPercent);
    end;
  end else begin
    if (MainWindow.ProgressBar.visible) then begin
      MainWindow.ProgressBar.visible := false;
      MainWindow.ProgressLabel.visible := false;
    end;
  end;
end;


function     TChannel.IsIncomingConnectionPossible: Boolean;
begin
  result := (not FIsReserved) and (FPacketConnection = nil) and (FNo > 0);
end;


function     TChannel.IsOutgoingConnectionPossible: Boolean;
begin
  result := (FPacketConnection = nil) and (FNo > 0);
end;


function     TChannel.IsChannelConnected: Boolean;
begin
  result := (assigned (FPacketConnection));
end;


procedure    TChannel.SetImage;
var
  G: Integer;
begin
  if (Status < vs_connected) and (not FReceive) then begin
    G := 0;
  end else begin
    if (not FReceive) or (FChannelActive) then begin
      G := 1;
    end else begin
      G := 2;
    end;
  end;
  SendMessage (SyncWindow, WM_SYNC_BUTTONIMAGE, G, 0);
end;


function     TChannel.ButtonControl: TChannelButton;
begin
  result := FChannelButton;
end;


function     TChannel.GetNo: Integer;
begin
  result := FNo;
end;


function     TChannel.GetPacketConnection: IConnection;
begin
  // FPacketConnection is also changed in the device thread. Copying the
  // interface (reading the pointer + _AddRef) is not atomic, hence under the lock.
  // Code that uses the connection more than once works with this local copy.
  FConnectionCriticalSection.Enter;
  try
    result := FPacketConnection;
  finally
    FConnectionCriticalSection.Leave;
  end;
end;


procedure    TChannel.SetChannelConnection (const aConnectionObj: IConnection);
var
  Former: IConnection;
begin
  FConnectionCriticalSection.Enter;
  try
    Former := FPacketConnection;
    FPacketConnection := aConnectionObj;
  finally
    FConnectionCriticalSection.Leave;
  end;
  // Release the previous connection only outside the lock
  // (Former is released at the end of the procedure).
end;


procedure    TChannel.Notify (P: Pointer);
const
  MethodName = 'Notify';
var
  D, F: ISendFile;
begin
  if (assigned (P)) then begin
    D := (IUnknown(P) as ISendFile);
    if (D.Active > fts_inactive) then begin
      F := FileSender;
      if (F = nil) then begin
        FileSender := D;
        F := D;
      end else begin
        if ((D as IUnknown) <> (F as IUnknown)) then begin
          beep;
          DebOut (self, MethodName, 'FileSender = ' + IntToHex (Cardinal(F), 8) + ' ' +
                  IntToHex (Cardinal(F as IUnknown), 8) + ' ' + F.TargetFilename);
          DebOut (self, MethodName, '          D = ' + IntToHex (Cardinal(D), 8) + ' ' + IntToHex (Cardinal(D as IUnknown), 8) +
                  ' ' + D.TargetFilename);
        end;
      end;
      FFileTransferPercent := F.Percent;
      F := nil;
      if (FChannelActive) then DisplayStatus;
    end else begin
      F := FileSender;
      FileSender := nil;
      if (assigned (F)) then begin
        F.Release;
        F := nil;
      end;
      if (FChannelActive) then DisplayStatus;
    end;
  end;
end;


function    TChannel.GetFileSender: ISendFile;
begin
  FConnectionCriticalSection.Enter;
  try
    result := FFileSender;
  finally
    FConnectionCriticalSection.Leave;
  end;
end;


procedure   TChannel.SetFileSender (const Value: ISendFile);
var
  Old: ISendFile;
begin
  FConnectionCriticalSection.Enter;
  try
    Old := FFileSender;
    FFileSender := Value;
  finally
    FConnectionCriticalSection.Leave;
  end;
  Old := nil; // released outside the lock
end;


procedure    TChannel.SetConsole (const Value: TConsole);
begin
  FConsole := Value;
end;


function     TChannel.GetConsole: TConsole;
begin
  result := FConsole;
end;


procedure    TChannel.KeyDown (var Key: Word; Shift: TShiftState);
const
  MethodName = 'KeyDown';

var
  C: Char;
  TT: TTextKind;
  S: String;
  V: IConnection;

begin

  if (not FConsole.Focused) then begin

    if (ssCtrl in Shift) and (not (ssAlt in Shift)) then begin
      case Key of
        vk_prior: begin
          FConsole.ScrollLineUp;
          Key := 0;
        end;
        vk_next: begin
          FConsole.ScrollLineDown;
          Key := 0;
        end;
        vk_home: begin
          FConsole.ScrollTop;
          Key := 0;
        end;
        vk_end: begin
          FConsole.ScrollBottom;
          FInputEdit.SelStart := MaxInt;
          FInputEdit.SelLength := 0;
          Key := 0;
        end;
        ord ('0') .. ord ('9'): begin
          TT := TTextKind (((Key + 9 - ord ('0')) mod 10) + ord (te_1));
          V := PacketConnection;
          S := Texts.Text (TT, V);
          if (Length (S) > 0) then begin
            if (ssShift in Shift) then begin
              FInputEdit.SelText := S;
            end else begin
              if (S[Length (S)] <> #13) then S := S + #13;
              if (assigned (V)) then begin
                V.SendTextData (S, true, true, (V.StationType in [st_unknown, st_terminal, st_box]));
                Sounds.PlayEvent (se_tx, V);
              end;
            end;
          end;
        end;
      end;
    end;

    if ((Shift = [ssShift]) and (Key = vk_tab)) then begin

      Key := 0;
      try
        FConsole.SetFocus;
      except
      end;

    end else if (Key = vk_f11) then begin

      if (not assigned (BoxList)) then begin
        BoxList := TBoxList.create (self as IChannelForBoxlist);
      end;
      BoxList.FindLastList;

      Key := 0;

      try
        FConsole.SetFocus;
      except
      end;

    end;

    if (Shift = []) then begin
      case Key of
        vk_prior: begin
          FConsole.ScrollPageUp;
          Key := 0;
        end;
        vk_next: begin
          FConsole.ScrollPageDown;
          Key := 0;
        end;
      end;
    end;

  end else begin

    if (Key = vk_f11) then begin

      FConsole.ScrollBottom;

      Key := 0;
      try
        FInputEdit.SetFocus;
      except
      end;

    end else if ((Shift = []) and (Key = vk_tab)) then begin

      Key := 0;
      try
        FInputEdit.SetFocus;
      except
      end;

    end else if ((Shift = [ssCtrl]) and (Key = vk_up)) then begin

      Key := 0;
      if (not assigned (BoxList)) then begin
        BoxList := TBoxList.create (self);
      end;
      BoxList.FindPrevList;

    end else if ((Shift = [ssCtrl]) and (Key = vk_down)) then begin

      Key := 0;
      if (not assigned (BoxList)) then begin
        BoxList := TBoxList.create (self);
      end;
      BoxList.FindNextList;

    end else if (Key < 255) then begin

      if (not assigned (BoxList)) then BoxList := TBoxList.create (self);
      C := Char (Key);
      case C of
        'R', #32: begin
          BoxRead (true, true);
        end;
        'E': begin
          BoxErase (true, true);
        end;
        #13: begin
          BoxRun;
        end else begin
          if (not (ssAlt in Shift)) and (C in ['A'..'Z', '0'..'9']) then begin
            MessageBeep ($FFFFFFFF);
          end;
        end;
      end;

    end;

  end;

end;


procedure   TChannel.ConsoleGutterClick (Sender: TConsole; Line: Integer);
var
  R: TRect;
begin
  if (not assigned (BoxList)) then BoxList := TBoxList.create (self);
  R := FConsole.Selection;
  if (R.Top < 0) then R := Rect (0, Line, 0, Line);
  BoxList.Read (R.Top, R.Bottom, true, false);
end;


procedure   TChannel.BoxErase (Toggle: Boolean; Down: Boolean);
var
  R: TRect;
begin
  if (not assigned (BoxList)) then BoxList := TBoxList.create (self);
  R := FConsole.Selection;
  if (R.Top < 0) then R := Rect (0, FConsole.CaretY, 0, FConsole.CaretY);
  BoxList.Erase (R.Top, R.Bottom, Toggle, Down);
end;


procedure   TChannel.BoxRead (Toggle: Boolean; Down: Boolean);
var
  R: TRect;
begin
  if (not assigned (BoxList)) then BoxList := TBoxList.create (self);
  R := FConsole.Selection;
  if (R.Top < 0) then R := Rect (0, FConsole.CaretY, 0, FConsole.CaretY);
  BoxList.Read (R.Top, R.Bottom, Toggle, Down);
end;


procedure   TChannel.BoxUncheck (Down: Boolean);
var
  R: TRect;
begin
  if (not assigned (BoxList)) then BoxList := TBoxList.create (self);
  R := FConsole.Selection;
  if (R.Top < 0) then begin
    R := Rect (0, FConsole.CaretY, 0, FConsole.CaretY);
  end;
  BoxList.Uncheck (R.Top, R.Bottom, Down);
end;


procedure   TChannel.BoxRun;
begin
  if (assigned (BoxList)) then begin
    BoxList.Execute;
    BoxList.free;
    BoxList := nil;
    if (assigned (FInputEdit)) then begin
      Windows.SetFocus (FInputEdit.Handle);
      try
        FInputEdit.SetFocus;
      except
      end;
    end;
    FConsole.ScrollBottom;
  end;
end;


procedure   TChannel.SendFileDialog (const aText: String);
begin
  if (not assigned (FSendFileDialog)) then begin
    FSendFileDialog := TSendFileDlg.create (Forms.Application.MainForm);
    FSendFileDialog.Execute (self, aText);
  end else begin
    // dropped on a channel whose dialog is already open: add instead of dropping it
    FSendFileDialog.AddText (aText);
    try
      FSendFileDialog.SetFocus;
    except
    end;
  end;
end;


procedure   TChannel.SendFileDialog (const aFiles: array of String);
begin
  if (not assigned (FSendFileDialog)) then begin
    FSendFileDialog := TSendFileDlg.create (Forms.Application.MainForm);
    FSendFileDialog.Execute (self, aFiles);
  end else begin
    // dropped on a channel whose dialog is already open: add instead of dropping them
    FSendFileDialog.AddFiles (aFiles);
    try
      FSendFileDialog.SetFocus;
    except
    end;
  end;
end;


procedure   TChannel.SendFileDialog;
begin
  if (not assigned (FSendFileDialog)) then begin
    FSendFileDialog := TSendFileDlg.create (Forms.Application.MainForm);
    FSendFileDialog.Execute (self);
  end else begin
    try
      FSendFileDialog.SetFocus;
    except
    end;
  end;
end;


procedure   TChannel.SendFileDialogDone;
const
  MethodName = 'SendFileDialogDone';
begin
  FSendFileDialog := nil;
end;


procedure   TChannel.NotifySubscribers (P: Pointer);
begin
  if (assigned (FPublisher)) then FPublisher.NotifySubscribers (P);
end;


procedure   TChannel.subscribe (Subscriber: ISubscriber);
begin
  if (assigned (FPublisher)) then FPublisher.subscribe (Subscriber);
end;


procedure   TChannel.unsubscribe (Subscriber: ISubscriber);
begin
  // After Release, FPublisher is nil (e.g. an open send-file dialog unsubscribes).
  if (assigned (FPublisher)) then FPublisher.unsubscribe (Subscriber);
end;


function    TChannel.GetIsReserved: Boolean;
begin
  result := FIsReserved;
end;


procedure   TChannel.SetIsReserved (const Value: Boolean);
begin
  FIsReserved := Value;
end;


procedure   TChannel.CanCancelChanged;
begin
  Synchronize (CanCancelChangedSync);
end;


procedure   TChannel.CanCancelChangedSync;
var
  I: Integer;
  V: IConnection;
begin
  if (FChannelActive) then begin
    V := PacketConnection;
    if (not assigned (V)) or (not V.CanCancel) then I := 10 else I := 9;
    if (MainWindow.ActionStop.ImageIndex <> I) then MainWindow.ActionStop.ImageIndex := I;
  end;
end;


procedure   TChannel.SaveChannelText;
const
  MethodName = 'SaveChannelText';

resourcestring
  SSaveDialogFilter = 'Text Dateien (*.txt)|*.txt|Alle Dateien (*.*)|*.*';
  SSaveDialogTitle = 'Speichern';
  SOverwriteOrAppend = 'Soll die bereits existierende Datei "%s" überschrieben werden oder möchten Sie den Text an diese anhängen?';
  SFileError = 'Datei kann nicht zum Schreiben geöffnet werden.';
  SChannel = 'Kanal%2.2d';

type
  TSaveAction = (sa_cancel, sa_overwrite, sa_append);

var
  SaveDialog: TSaveDialog;
  SaveAction: TSaveAction;
  S: String;
  L: Integer;
  HasError: Boolean;
  V: IConnection;

begin

  if (not assigned (FSaveStream)) then begin

    V := PacketConnection;
    if (assigned (V)) then begin
      S := V.Call;
    end else begin
      S := Format (SChannel, [FNo]);
    end;
    S := S + '.txt';

    SaveDialog := TSaveDialog.create (MainWindow);
    try

      SaveDialog.DefaultExt := 'txt';
      SaveDialog.FileName := S;
      SaveDialog.Filter := SSaveDialogFilter;
      SaveDialog.FilterIndex := 1;
      SaveDialog.InitialDir := Folders.Reception;
      SaveDialog.Options := [ofEnableSizing, ofHideReadOnly];
      SaveDialog.Title := SSaveDialogTitle;

      if (SaveDialog.Execute) then begin

        DebOut (self, MethodName, SaveDialog.FileName);
        if (FileExists (SaveDialog.FileName)) then begin
          with TOverwriteAppendFileForm.create (MainWindow) do begin
            Label1.Caption := Format (SOverwriteOrAppend, [ExtractFileName (SaveDialog.FileName)]);
            case ShowModal of
              mrYes: SaveAction := sa_overwrite;
              mrNo: SaveAction := sa_append;
              else SaveAction := sa_cancel;
            end;
            Release;
          end;
        end else begin
          SaveAction := sa_overwrite;
        end;

        if (SaveAction <> sa_cancel) then begin

          FSaveCriticalSection.Enter;
          try

            HasError := false;

            FSaveStream := TFileStreamUlf.create;
            FSaveStream.Filename := SaveDialog.FileName;

            if (SaveAction = sa_overwrite) then begin
              FSaveStream.Mode := fmCreate;
              try
                try
                  FSaveStream.Open;
                except
                  HasError := true;
                end;
              finally
                FSaveStream.Close;
              end;
            end;

            if (not HasError) then begin
              FSaveStream.Mode := fmOpenReadWrite or fmShareDenyWrite;
              try
                FSaveStream.Open;
                FSaveStream.Seek (0, soFromEnd);
              except
                HasError := true;
              end;
            end;

            if (HasError) then begin

              FSaveStream.Free;
              FSaveStream := nil;

            end else begin

              S := FConsole.SelectedText;
              L := Length (S);

              if (L > 0) then begin
                FSaveStream.Write (S[1], L);
              end;

              if (L > 0) and (not FConsole.IsSelectionContinued) then begin
                FSaveStream.Close;
                FSaveStream.Free;
                FSaveStream := nil;
              end;

              FConsole.Unselect;

            end;

          finally

            FSaveCriticalSection.Leave;

          end;

          // Show the message only after releasing the lock: otherwise the modal dialog would
          // block device threads in SaveOutput.
          if (HasError) then begin
            with TDlgMessage.create (MainWindow) do begin
              Run (SSaveDialogTitle, SFileError, [mbOk]);
              Release;
            end;
          end;

        end;

      end;

    finally

      SaveDialog.free;

    end;

  end else begin

    FSaveCriticalSection.Enter;
    try
      FSaveStream.Close;
      FSaveStream.Free;
      FSaveStream := nil;
    finally
      FSaveCriticalSection.Leave;
    end;

  end;

  FSaveCriticalSection.Enter;
  try
    MainWindow.ActionSave.Checked := assigned (FSaveStream);
  finally
    FSaveCriticalSection.Leave;
  end;

  DisplayStatus;

end;


function    TChannel.GetShowDOSUmlauts: Boolean;
begin
  result := FConsole.ShowDOS;
end;


procedure   TChannel.SetShowDOSUmlauts (const Value: Boolean);
begin
  FConsole.ShowDOS := Value;
end;


function    TChannel.GetSendDOSUmlauts: Boolean;
begin
  result := FSendDosUmlauts;
end;


procedure   TChannel.SetSendDOSUmlauts (const Value: Boolean);
begin
  FSendDosUmlauts := Value;
end;


procedure   TChannel.CreateSyncWindow;
var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
  SyncWindowClass: TWndClass;
  SyncWindowClassName: String;

begin

  assert (MainThreadID = GetCurrentThreadID);

  SyncWindowClassName := 'KanalSyncWindow';

  SyncWindowClass.style := 0;
  SyncWindowClass.lpfnWndProc := @SyncWndProc;
  SyncWindowClass.cbClsExtra := 0;
  SyncWindowClass.cbWndExtra := sizeof (Pointer);
  SyncWindowClass.hIcon := 0;
  SyncWindowClass.hCursor := 0;
  SyncWindowClass.hbrBackground := 0;
  SyncWindowClass.lpszMenuName := nil;
  SyncWindowClass.lpszClassName := PChar(SyncWindowClassName);
  SyncWindowClass.hInstance := HInstance;

  ClassRegistered := GetClassInfo (HInstance, SyncWindowClass.lpszClassName, TempClass);

  if (not ClassRegistered) or (TempClass.lpfnWndProc <> @SyncWndProc) then begin
    if (ClassRegistered) then Windows.UnregisterClass (SyncWindowClass.lpszClassName, HInstance);
    Windows.RegisterClass (SyncWindowClass);
  end;

  SyncWindow := CreateWindow (SyncWindowClass.lpszClassName, '', 0, 0, 0, 0, 0, 0, 0, HInstance, nil);
  SetWindowLong (SyncWindow, 0, Integer(self));

end;


procedure   TChannel.FreeSyncWindow;
begin
  if (SyncWindow <> 0) then begin
    DestroyWindow (SyncWindow);
    SyncWindow := 0;
  end;
end;


function    TChannel.ConsoleHint (Sender: TConsole; HintType: THintType; XT, YT: Integer): string;
const
  MethodName = 'ConsoleHint';

resourcestring
  SDay = 'Tag';
  SDays = 'Tagen';
  SHour = 'Stunde';
  SHours = 'Stunden';
  SMinute = 'Minute';
  SMinutes = 'Minuten';
  SSecond = 'Sekunde';
  SSeconds = 'Sekunden';
  SToday = 'Heute';
  SYesterday = 'Gestern';
  SDateTimeHintFormat = '%s%s'#13#10'(vor %s)';
  SDateTimeFormat = 'ddddd, tt';

var
  I, X1, X2: Integer;
  P: PChar;
  E: IStationDatabaseEntry;
  S, T, H: String;
  LH: PLineHeader;
  TS: TTimeStamp;
  NDT, DT, DDT: TDateTime;
  Hours, Minutes, Seconds, Milliseconds: Word;
  Days: Integer;

begin

  assert (MainThreadID = GetCurrentThreadID);

  result := '';

  if (HintType = htText) then begin

    X1 := XT;
    X2 := XT;
    P := FConsole.ScreenPtrT (0, YT);
    I := 0;

    while (X1 >= 0) and (I <= 10) do begin
      if (not (UpCase(P[X1]) in ['A'..'Z', '0'..'9', '-'])) then begin
        break;
      end;
      dec (X1);
      inc (I);
    end;
    inc (X1);

    while (X2 < FConsole.Cols) and (I <= 10) do begin
      if (not (UpCase(P[X2]) in ['A'..'Z', '0'..'9', '-'])) then begin
        break;
      end;
      inc (X2);
      inc (I);
    end;

    if (X2 > X1) then begin

      SetString (S, P + X1, X2 - X1);

      E := StationDatabase.Open (S, true);
      if (assigned (E)) then begin
        result := E.Call + #13 + E.Name;
      end;

    end;

  end else if (HintType = htGutter) then begin

    LH := FConsole.ScreenPtrH (YT);

    if (LH.Time > 0) then begin

      TS.Date := (LH.Time div (24 * 60 * 60)) + 719163;
      TS.Time := (LH.Time mod (24 * 60 * 60)) * 1000;

      DT := TimeStampToDateTime (TS);

      NDT := Now;

      DDT := NDT - DT;

      I := Trunc (NDT) - Trunc (DT);
      case I of
        0: H := SToday + ', ';
        1: H := SYesterday + ', ';
        else H := '';
      end;

      DecodeTime (DDT, Hours, Minutes, Seconds, Milliseconds);
      Days := Trunc (DDT);

      S := '';

      if (Days > 0) then begin
        if (Days = 1) then T := SDay else T := SDays;
        S := S + Format ('%d %s, ', [Days, T]);
      end;

      if (Days > 0) or (Hours > 0) then begin
        if (Hours = 1) then T := SHour else T := SHours;
        S := S + Format ('%d %s, ', [Hours, T]);
      end;

      if (Days > 0) or (Hours > 0) or (Minutes > 0) then begin
        if (Minutes = 1) then T := SMinute else T := SMinutes;
        S := S + Format ('%d %s, ', [Minutes, T]);
      end;

      if (Seconds = 1) then T := SSecond else T := SSeconds;
      S := S + Format ('%d %s', [Seconds, T]);

      result := Format (SDateTimeHintFormat, [H, FormatDateTime (SDateTimeFormat, DT), S]);

    end;

  end;

  if (result <> '') then DebOut (self, MethodName, result);

end;


procedure   TChannel.FocusChange (Sender: TObject);
begin
  UpdateActions (Sender);
end;


procedure   TChannel.UpdateActions (Sender: TObject);
begin
  UpdateActionsSender := Sender;
  Synchronize (UpdateActionsSync);
  UpdateActionsSender := nil;
end;


procedure   TChannel.UpdateActionsSync;
var
  B: Boolean;
  V: IConnection;

begin
  if (FChannelActive) then begin

    V := PacketConnection;

    MainWindow.ActionEditCut.Enabled := (UpdateActionsSender = FInputEdit);
    MainWindow.ActionEditPaste.Enabled := (UpdateActionsSender = FInputEdit);
    MainWindow.ActionEditDelete.Enabled := (UpdateActionsSender = FInputEdit);
    MainWindow.ActionEditCopy.Enabled := (UpdateActionsSender = FInputEdit) or (UpdateActionsSender = FConsole);

    B := (assigned (V)) and (V.Pactor);

    MainWindow.ActionPactorChangeover.Enabled := B;
    MainWindow.ActionPactorBreakIn.Enabled := B;
    MainWindow.MenuConnectPactor.Enabled := B;

    if (assigned (V)) then begin
      MainWindow.ActionLocalEcho.Enabled := true;
      MainWindow.ActionLocalEcho.Checked := V.LocalEcho;
    end else begin
      MainWindow.ActionLocalEcho.Enabled := false;
      MainWindow.ActionLocalEcho.Checked := Config.LocalEcho;
    end;

  end;

end;


procedure   TChannel.ContextPopup (Sender: TObject; MousePos: TPoint; var Handled: Boolean);
const
  MethodName = 'ContextPopup';

type
  TContext = (con_unknown, con_console, con_input, con_monitor);

var
  P: TPoint;
  Control: TControl;
  PopupMenu: TToolbarPopupMenu;
  Context: TContext;
  LH: PLineHeader;

  procedure AddItem (Action: TAction);
  var
    Item: TToolbarElement;
  begin
    Item := TToolbarElement.Create (PopupMenu);
    Item.Action := Action;
    PopupMenu.Items.Add (Item);
  end;

  procedure AddSeparator;
  var
    Separator: TToolbarSeparator;
  begin
    Separator := TToolbarSeparator.Create (PopupMenu);
    PopupMenu.Items.Add (Separator);
  end;

begin

  if (Sender is TControl) then begin

    Control := (Sender as TControl);

    ChannelList.ActionChannel := (self as IChannel);

    P := Control.ClientToScreen (MousePos);

    if (Control = FConsole) then begin
      if (FNo > 0) then begin
        Context := con_console;
      end else begin
        Context := con_monitor;
      end;
    end else if (Control = FInputEdit) then begin
      Context := con_input;
    end else begin
      Context := con_unknown;
    end;

    UpdateActions (Sender);

    PopupMenu := TToolbarPopupMenu.Create (MainWindow);

    try

      PopupMenu.Images := MainWindow.ImageList;

      if (Context = con_console) then begin
        // after ClrScr, CaretY = -1 (ScreenPtrH then returns nil or a
        // wrong line): in that case do not offer box commands
        if (Console.CaretY >= 0) then LH := Console.ScreenPtrH (Console.CaretY) else LH := nil;
        if (assigned (LH)) and (LH.LineType = 1) then begin
          AddItem (MainWindow.ActionBoxRead);
          AddItem (MainWindow.ActionBoxErase);
          AddItem (MainWindow.ActionBoxUncheck);
          AddItem (MainWindow.ActionBoxRun);
          AddSeparator;
        end;
      end;

      if (Context = con_input) then begin
        AddItem (MainWindow.ActionEditCut);
      end;
      AddItem (MainWindow.ActionEditCopy);
      if (Context = con_input) then begin
        AddItem (MainWindow.ActionEditPaste);
        AddItem (MainWindow.ActionEditDelete);
      end;

      PopupMenu.Popup (P.X, P.Y);

      Forms.Application.ProcessMessages;

    finally

      PopupMenu.Free;

    end;

    Handled := true;

  end;

end;


procedure   TChannel.EditCopy;
begin
  if ((FNo = 0) and (not FChannelActive)) or (FConsole.Focused) then begin
    FConsole.CopyToClipboard;
  end else if (FInputEdit.Focused) then begin
    FInputEdit.CopyToClipboard;
  end;
end;


procedure   TChannel.EditCut;
begin
  if (FInputEdit.Focused) then begin
    FInputEdit.CutToClipboard;
  end;
end;


procedure   TChannel.EditDelete;
begin
  if (FInputEdit.Focused) then begin
    SendMessage (FInputEdit.Handle, wm_keydown, VK_DELETE, 0);
    SendMessage (FInputEdit.Handle, wm_keyup, VK_DELETE, 0);
  end;
end;


procedure   TChannel.EditPaste;
begin
  if (FInputEdit.Focused) then begin
    FInputEdit.PasteFromClipboard;
  end;
end;


procedure   TChannel.EditSelectAll;
begin
  if (FInputEdit.Focused) then begin
    FInputEdit.SelectAll;
  end;
end;


procedure   TChannel.StatusChanged;
begin
  StatusUpdate (false);
end;


procedure   TChannel.StatusUpdate (All: Boolean);
var
  T, S: String;
  N, I: Integer;
  R: Real;
  V: IConnection;

begin

  if (FChannelActive) then begin

    V := PacketConnection;

    if (assigned (V)) and (V.ConnectionStatus >= vs_disconnect) then begin

      with V.Status do begin

        if (All) or (TriesChanged) then begin
          I := Tries;
          if (I >= 0) then begin
            S := Format ('T%d', [I]);
          end else begin
            S := '';
          end;
          SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 3, Integer(Pointer(S)));
        end;

        if (All) or (UnackChanged) then begin
          I := Unack;
          if (I < 100) then begin
            if (I < 0) then begin
              S := '';
            end else begin
              S := Format ('U%d', [I]);
            end;
          end else begin
            S := Format ('%d', [I]);
          end;
          SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 4, Integer(Pointer(S)));
        end;

        if (All) or (FrackChanged) then begin
          I := Frack;
          if (I < 0) then begin
            S := '';
          end else begin
            if (I = 0) then begin
              S := 'dama';
            end else begin
              S := Format ('F%d', [I]);
            end;
          end;
          SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 5, Integer(Pointer(S)));
        end;

        if (All) or (MaxframeChanged) then begin
          I := Maxframe;
          if (I < 0) then begin
            S := '';
          end else begin
            S := Format ('M%d', [I]);
          end;
          SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 6, Integer(Pointer(S)));
        end;

        if (All) or (Ax25stateChanged) then begin

          I := Ax25state;

          if (I < 0) then begin

            S := '';

          end else begin

            case (I and $07) of
              3: S := 'frmr ';
              6: S := 'reject ';
              7: S := 'polling ';
              else S := '';
            end;

            if ((I and $08) <> 0) then S := S + 'busy ';

            if ((I and $10) <> 0) then S := S + 'rbusy ';

            N := Length (S);
            if (N > 0) then SetLength (S, N - 1);

          end;

          SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 7, Integer(Pointer(S)));

        end;

        if (All) or (EffectiveBaudrateChanged) then begin

          I := EffectiveBaudrate;

          if (I <= 0) then begin

            S := '';

          end else begin

            if (I >= 1000000) then begin
              T := 'M';
              R := I / 1000000;
            end else if (I >= 1000) then begin
              T := 'k';
              R := I / 1000;
            end else begin
              T := '';
              R := I;
            end;

            if (R >= 100) then begin
              S := Format ('%3.0f%sbit/s', [R, T]);
            end else if (R >= 10) then begin
              S := Format ('%2.1f%sbit/s', [R, T]);
            end else begin
              S := Format ('%1.2f%sbit/s', [R, T]);
            end;

          end;

          SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 2, Integer(Pointer(S)));

        end;

      end;

    end else begin

      if (FNo = 0) then begin

        S := '';
        for I := 1 to 6 do begin
          SendMessage (SyncWindow, WM_SYNC_STATUSLINE, I, Integer(Pointer(S)));
        end;

        S := SMonitorCaption;
        SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 0, Integer(Pointer(S)));

        S := Config.UIDestination;
        SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 7, Integer(Pointer(S)));

        S := Config.UIMyCall;
        SendMessage (SyncWindow, WM_SYNC_STATUSLINE, 8, Integer(Pointer(S)));

      end else begin

        S := '';
        for I := 1 to 8 do begin
          SendMessage (SyncWindow, WM_SYNC_STATUSLINE, I, Integer(Pointer(S)));
        end;

      end;

    end;

  end;

end;


procedure   TChannel.UpdateColors;
var
  C: TColor;
  B: Boolean;
begin

  if (FNo = 0) then begin
    if (assigned (FConsole)) then begin
      with FConsole do begin
        Color := Config.Color[ct_monitor_background];
        VPalette[01] := Config.Color[ct_monitor_header_sent];
        VPalette[05] := Config.Color[ct_monitor_data];
        VPalette[06] := Config.Color[ct_monitor_local];
        VPalette[10] := Config.Color[ct_monitor_header_received];
        Invalidate;
      end;
    end;
  end else begin
    if (assigned (FConsole)) then begin
      with FConsole do begin
        Color := Config.Color[ct_output_background];
        VPalette[01] := Config.Color[ct_output_sent];
        VPalette[08] := Config.Color[ct_output_local];
        VPalette[10] := Config.Color[ct_output_received];
        VPalette[15] := Config.Color[ct_output_connstat];
        Invalidate;
      end;
    end;
  end;

  if (assigned (FInputEdit)) then begin

    B := false;

    C := Config.Color[ct_input_background];
    if (FInputEdit.Color <> C) then begin
      FInputEdit.Color := C;
      B := true;
    end;

    C := Config.Color[ct_input_new];
    if (FInputEdit.ColorNewText <> C) then begin
      FInputEdit.ColorNewText := C;
      B := true;
    end;

    C := Config.Color[ct_input_sent];
    if (FInputEdit.ColorSentText <> C) then begin
      FInputEdit.ColorSentText := C;
      B := true;
    end;

    if (B) then FInputEdit.Invalidate;

  end;

end;


procedure   TChannel.ClrScr;
begin
  FConsole.ClrScr;
end;


function    TChannel.GetHint: String;
begin
  result := FChannelButton.Hint;
end;


procedure   TChannel.DoShowHint;
var
  R: TRect;
  P: TPoint;
  S: String;

begin

  R := MainWindow.ChannelToolbar.ElementRect (ButtonControl);
  P.X := R.Left;
  P.Y := R.Bottom + 3;
  P := MainWindow.ChannelToolbar.ClientToScreen (P);

  S := GetShortHint (ChannelList.CurrentChannel.Hint);

  if (Length (S) > 0) then begin

    MainWindow.KeyHintWindow := HintWindowClass.create (MainWindow);
    MainWindow.KeyHintWindow.Color := Forms.Application.HintColor;

    R := MainWindow.KeyHintWindow.CalcHintRect (640, S, nil);
    OffsetRect (R, P.X, P.Y);
    MainWindow.KeyHintWindow.ActivateHint (R, S);

  end;
end;


procedure   TChannel.PactorBreakIn;
var
  V: IConnection;
begin
  V := PacketConnection;
  if (assigned (V)) then V.PactorBreakIn;
end;


procedure   TChannel.PactorChangeOver;
var
  V: IConnection;
begin
  V := PacketConnection;
  if (assigned (V)) then V.PactorChangeOver;
end;


procedure   TChannel.SetConsoleRows (const Value: Cardinal);
begin
  if (assigned (FConsole)) then FConsole.Rows := Value;
end;


function    TChannel.IsSendFileDialogActive: Boolean;
begin
  result := assigned (FSendFileDialog);
end;


procedure   TChannel.Print;
const
  MethodName = 'Print';

  BorderL = 200;
  BorderR = 100;
  BorderT = 150;
  BorderB = 150;

var
  Printer: TPrinter;
  C: TCanvas;
  I: Integer;
  {W, } H: Integer;
  DPIX, DPIY: Integer;
  S: String;
  LH: PLineHeader;
  X, X2, Y, Y1, Y2: Integer;
  TY: Integer;
  LpP: Integer;
  PT, PC: PChar;
  Col: Byte;
  FCol: TColor;
  PageCount: Integer;
  Page: Integer;

  function pxX (const hmm: Integer): Integer;
  begin
    result := Round (hmm / 254 * DPIX);
  end;

  function pxY (const hmm: Integer): Integer;
  begin
    result := Round (hmm / 254 * DPIY);
  end;

begin

  // Range: the selection, otherwise from the last connect line to the end.
  // If there is no connect line (monitor, channel never connected), from the
  // first written line of the buffer.

  Y2 := FConsole.Rows - 1;

  if (FConsole.Selection.Top >= 0) then begin

    Y1 := FConsole.Selection.Top;
    if (FConsole.Selection.Bottom < Y2) then Y2 := FConsole.Selection.Bottom;

  end else begin

    Y1 := Y2;
    while (Y1 > 0) and (FConsole.ScreenPtrH (Y1).ImageIndex <> 5) do begin
      dec (Y1);
    end;

    if (FConsole.ScreenPtrH (Y1).ImageIndex <> 5) then begin
      Y1 := 0;
      while (Y1 < Y2) and (FConsole.ScreenPtrH (Y1).Length = 0) do begin
        inc (Y1);
      end;
      if (FConsole.ScreenPtrH (Y1).Length = 0) then exit;
    end;

  end;

  if (Y1 < 0) or (Y2 < Y1) then exit;

  Printer := Printers.Printer;

  // W := GetDeviceCaps (Printer.Handle, HORZRES);
  H := GetDeviceCaps (Printer.Handle, VERTRES);

  DPIX := GetDeviceCaps (Printer.Handle, LOGPIXELSX);
  DPIY := GetDeviceCaps (Printer.Handle, LOGPIXELSY);

  Printer.BeginDoc;

  try

    C := Printer.Canvas;

    SetBkMode (C.Handle, transparent);

    C.Font.Name := 'Courier New';
    C.Font.Size := 9;

    TY := Round (C.TextHeight('Mg') * 1);

    LpP := Trunc ((H - pxY (BorderT) - pxY (BorderB)) / TY);
    if (LpP < 1) then LpP := 1;

    // Y1..Y2 are Y2 - Y1 + 1 lines
    PageCount := ((Y2 - Y1) div LpP) + 1;

    Y := Y1;

    for Page := 1 to PageCount do begin

      for I := 0 to LpP - 1 do begin

        LH := FConsole.ScreenPtrH (Y);
        PT := Console.ScreenPtrT (0, Y);
        PC := Console.ScreenPtrC (0, Y);

        C.MoveTo (pxX (BorderL), (pxY (BorderT) + TY * I));

        X := 0;

        while (X < LH.Length) do begin

          Col := Byte(PC[X]);

          X2 := X + 1;
          while (X2 < LH.Length) and (Col = Byte(PC[X2])) do begin
            inc (X2);
          end;

          SetString (S, PChar(@PT[X]), X2 - X);

          case Col of
             15: FCol := $000000; // status
             10: FCol := $7F0000; // receive
              1: FCol := $00009F; // send
              8: FCol := $7F6C00; // pgp
            else FCol := $606060;
          end;

          C.Font.Color := FCol;
          C.TextOut (C.PenPos.X, C.PenPos.Y, S);

          X := X2;

        end;

        Inc (Y);

        if (Y > Y2) then break;

      end;

      if (Page < PageCount) then Printer.NewPage;

    end;

    Printer.EndDoc;

  except
    // Do not leave the print job open, otherwise every further BeginDoc fails
    if (Printer.Printing) then Printer.Abort;
    raise;
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

