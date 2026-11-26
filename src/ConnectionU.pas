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


unit ConnectionU;


interface


uses
  Classes, Windows, SysUtils, Messages, SyncObjs, Forms,
  RemoteCommandsU, InterfacesU, QueueU, DeviceU, SendFileU,
  ConnectionAbstractU, PublisherU, GlobalU, TextsConstsU, StatusU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionThread = class;


  TEventSet = set of TUserEventEnum;


  TConnection = class;


  TApplicationRec = class
  public
    ReceiveQueue: TStringQueue;
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
  end;


  TConnection = class (TInterfacedObject, IConnection, IConnectionForModule)
  private

    Released: Boolean;
    FReleasedFlag: Integer;      // 1 once Release has started (InterlockedExchange)
    FDisconnectedFlag: Integer;  // 1 once Disconnected has started (InterlockedExchange)

    FAllEventHandles: Array[TEventEnum] of THandle;

    FCriticalSection: TCriticalSection;
    FThreadCriticalSection: TCriticalSection;
    FDiscLevel: TDisconnectLevel;
    FOwnerDevice: TDevice;
    FCall: String;
    FDigis: String;
    FRealPath: String;
    FMyCall: String;
    FChannel: IChannelForConnection;
    FHandle: Integer;
    FConnectionStatus: TConnectionStatus;
    FOutgoing: Boolean;
    FSendConnectText: Boolean;
    FThread: TConnectionThread;
    FThreadTerminateEvent: TEvent;
    FReceiveQueue: TStringQueue;
    FSendQueue: TStringQueue;
    FDeviceQueue: TStringQueue;
    FStationType: TStationType;
    FHistory: TStringList;
    FSendFileQueue: ISendFileQueue;
    FSendFile: ISendFile;
    FRemoteCommands: IRemoteCommands;
    FRemoteCommandsPossible: Boolean;
    FRestored: Boolean;
    FProtocolModule: IConnectionAbstract;
    FCanCancel: Boolean;
    FStationDatabaseEntry: IStationDatabaseEntry;
    FBinMode: TSendFileProtocol;

    FStatus: IStatus;

    FPactor: Boolean;
    FLocalEcho: Boolean;

    TimerWindow: HWnd;

    procedure   CreateTimerWindow;
    procedure   CreateTimerWindowSync;
    procedure   DestroyTimerWindow;
    procedure   DestroyTimerWindowSync;

    procedure   NotifyTimer;

    function    GetCall: String;
    procedure   SetCall (const Value: String);

    function    GetMyCall: String;
    procedure   SetMyCall (const Value: String);

    function    GetDigis: String;
    procedure   SetDigis (const Value: String);

    function    GetPath: String;
    procedure   SetPath (const Value: String);

    function    GetRealPath: String;
    procedure   SetRealPath (const Value: String);

    function    GetHandle: Integer;
    procedure   SetHandle (Value: Integer);

    function    GetAllEventHandles (E: TEventEnum): THandle;

    function    GetChannelRef: IChannelForConnection;
    procedure   SetChannelRef (aChannelObj: IChannelForConnection);

    function    GetConnectionStatus: TConnectionStatus;
    procedure   SetConnectionStatus (aConnectionStatus: TConnectionStatus);

    function    GetOutgoing: Boolean;
    procedure   SetOutgoing (aOutgoing: Boolean);

    function    GetStationType: TStationType;
    procedure   SetStationType (aStationType: TStationType);

    function    GetRemoteCommandsPossible: Boolean;
    procedure   SetRemoteCommandsPossible (const Value: Boolean);

    function    GetStatus: IStatus;

    function    GetStationDatabaseEntry: IStationDatabaseEntry;

    procedure   Run;
    procedure   CreateThread;
    procedure   StopThread;
    function    InOwnThread: Boolean;
    procedure   ClearStationDatabaseEntry;
    function    GetSendFileQueue: ISendFileQueue;
    procedure   ChannelSendText (const Text: String);

    function    InfoboxConnect (const aCall: String): Boolean;
    function    InfoboxReconnect (const aCall: String): Boolean;

    function    GetRemoteCommands: IRemoteCommands;

    procedure   SendSID;

    function    GetBinmode: TSendFileProtocol;
    procedure   SetBinmode (const Value: TSendFileProtocol);

    function    GetPactor: Boolean;
    procedure   SetPactor (const Value: Boolean);

    function    GetLocalEcho: Boolean;
    procedure   SetLocalEcho (const Value: Boolean);

    procedure   SetDiscTimer;
    procedure   SetDiscTimerSync;

  protected

    function    GetReceiveQueue: TStringQueue;
    property    ReceiveQueue: TStringQueue read GetReceiveQueue;

    function    GetSendQueue: TStringQueue;
    property    SendQueue: TStringQueue read GetSendQueue;

    function    GetDeviceQueue: TStringQueue;
    property    DeviceQueue:  TStringQueue read GetDeviceQueue;

    function    GetFileSender: ISendFile;
    procedure   SetFileSender (aSendFile: ISendFile);

    procedure   SetSendConnectText (const Value: Boolean);
    function    GetSendConnectText: Boolean;
    property    SendConnectText: Boolean read GetSendConnectText write SetSendConnectText;

    procedure   SetConnectionModule (const Value: IConnectionAbstract);
    function    GetConnectionModule: IConnectionAbstract;
    property    ConnectionModule: IConnectionAbstract read GetConnectionModule write SetConnectionModule;

    procedure   SetCanCancel (const Value: Boolean);
    function    GetCanCancel: Boolean;
    property    CanCancel: Boolean read GetCanCancel write SetCanCancel;

  public

    constructor Create (aDeviceObj: TDevice); virtual;

    procedure   BeforeDestruction; override;

    property    Call: String read GetCall write SetCall;
    property    MyCall: String read GetMyCall write SetMyCall;
    property    Digis: String read GetDigis write SetDigis;
    property    Path: String read GetPath write SetPath;
    property    Handle: Integer read GetHandle write SetHandle;

    property    AllEventHandles [E: TEventEnum]: THandle read GetAllEventHandles;
    property    ChannelRef: IChannelForConnection read GetChannelRef write SetChannelRef;
    property    ConnectionStatus: TConnectionStatus read GetConnectionStatus write SetConnectionStatus;
    property    Outgoing: Boolean read FOutgoing write FOutgoing;
    property    StationType: TStationType read GetStationType write SetStationType;
    property    FileSender: ISendFile read GetFileSender write SetFileSender;
    property    RemoteCommands: IRemoteCommands read GetRemoteCommands;
    property    RemoteCommandsPossible: Boolean read GetRemoteCommandsPossible write SetRemoteCommandsPossible;
    property    SendFileQueue: ISendFileQueue read GetSendFileQueue;
    property    Status: IStatus read GetStatus;
    property    StationDatabaseEntry: IStationDatabaseEntry read GetStationDatabaseEntry;
    property    BinMode: TSendFileProtocol read GetBinMode write SetBinMode;
    property    Pactor: Boolean read GetPactor write SetPactor;
    property    LocalEcho: Boolean read GetLocalEcho;

    function    IsIncomingConnectAllowed: TIncomingConnect;
    procedure   ConnectionEstablished; overload;
    procedure   ConnectionEstablished (aRestored: Boolean); overload;
    procedure   Disconnect;
    procedure   Disconnected (Reason: TDisconnectReason);
    procedure   ReceiveTextData (const aText: String);

    procedure   SendTextData (aText: String; aEcho: Boolean; aControlChars: Boolean = false; aWrap: Boolean = false;
                              aViaModule: Boolean = true);

    function    DiscLevel: TDisconnectLevel;
    procedure   DiscLevelDone;
    function    ChannelReceiveText (const Text: String): Integer;
    procedure   ChannelDisplay (const aText: String; aType: TDisplayType);
    procedure   ChannelPrompt (const aText: String; aType: TDisplayType);
    procedure   Release;
    procedure   CancelTransfer;
    procedure   Save (const DeviceRegKey: String);
    procedure   Restore (const DeviceRegKey: String; aHandle: Cardinal);

    procedure   PactorChangeOver;
    procedure   PactorBreakIn;

  end;


  TConnectionThread = class (TThread)
  private
    PacketConnection: TConnection;
  protected
    procedure   Execute; override;
  public
    destructor  Destroy; override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, Registry, MainU, FolderU, ChannelsU, StationDatabaseU,
  ConnectionStandardU, SendFileQueueU, ConfigU, SoundsU, SoundsConstsU,
  TextsU, UnhandledExceptionU, ConnectionsListU, SynchronizeU;


// Waits up to TimeValue ms for thread aThread to end; true if it has ended.
// No Application.ProcessMessages: in the device thread it would swallow its
// thread messages (disconnect, UI frames); in the main thread it would let
// arbitrary events re-enter. PeekMessage with PM_NOREMOVE only dispatches
// messages sent via SendMessage (this is how the connection thread outputs
// text in the channel) and leaves posted messages in the queue.

function    WaitForThread (aThread: THandle; TimeValue: DWord): Boolean;
var
  D: DWord;
  Msg: TMsg;
begin
  D := MsgWaitForMultipleObjects (1, aThread, false, TimeValue, QS_SENDMESSAGE);
  result := (D = WAIT_OBJECT_0) or (D = WAIT_FAILED);
  PeekMessage (Msg, 0, 0, 0, PM_NOREMOVE);
  if (GetCurrentThreadID = MainThreadID) then CheckSynchronize;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TimerWndProc (Window: HWND; Message, wParam, lParam: Longint): Longint; stdcall;
var
  PacketConnection: TConnection;
begin

  PacketConnection := TConnection (GetWindowLong (Window, 0));

  case Message of

    WM_TIMER: begin
      if (assigned (PacketConnection)) then PacketConnection.NotifyTimer;
      Result := 0;
    end;

    else begin
      Result := DefWindowProc (Window, Message, wParam, lParam);
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Constructor / Destructor
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TConnection.Create (aDeviceObj: TDevice);
var
  E: TEventEnum;

begin

  // inherited Create ();

  Released := false;

  // create before the status is set for the first time (SetConnectionStatus -> GetChannelRef)
  FCriticalSection := TCriticalSection.create;

  FOwnerDevice := aDeviceObj;
  ConnectionStatus := vs_connect;
  FDiscLevel := dl_none;
  FThread := nil;
  FStationType := st_unknown;
  FRemoteCommandsPossible := false;

  FThreadCriticalSection := TCriticalSection.create;
  FThreadTerminateEvent := TEvent.Create (nil, true, true, '');
  FReceiveQueue := TStringQueue.create;
  FSendQueue := TStringQueue.create;
  FDeviceQueue := TStringQueue.create;
  FHistory := TStringList.create;
  FSendFileQueue := TSendFileQueue.create;
  FRemoteCommands := TRemoteCommands.create (self);
  FSendConnectText := false;

  for E := Low (TEventEnum) to High (TEventEnum) do begin
    FAllEventHandles [E] := 0;
  end;

  FStatus := TStatus.create;

  FLocalEcho := Config.LocalEcho;

end;


procedure   TConnection.BeforeDestruction;
const
  MethodName = 'BeforeDestruction';

begin

  Release;

  // The last reference was dropped in the connection thread itself (Release could
  // only signal it): the thread object frees itself when the thread ends.
  if (assigned (FThread)) then begin
    FThread.FreeOnTerminate := true;
    FThread := nil;
  end;

  // Destroy the timer window, otherwise a later WM_TIMER calls the freed
  // object. The window belongs to the main thread; DestroyTimerWindow destroys it there.
  if (TimerWindow <> 0) then DestroyTimerWindow;

  if (assigned (FStatus)) then begin
    FStatus.Release;
    FStatus := nil;
  end;

  FHistory.free;
  FHistory := nil;

  FDeviceQueue.free;
  FDeviceQueue := nil;

  FSendQueue.free;
  FSendQueue := nil;

  FReceiveQueue.free;
  FReceiveQueue := nil;

  FThreadTerminateEvent.free;
  FThreadTerminateEvent := nil;

  FCriticalSection.free;
  FCriticalSection := nil;

  FThreadCriticalSection.free;
  FThreadCriticalSection := nil;

  inherited;

end;


procedure   TConnection.Release;
const
  MethodName = 'Release';

var
  K: IChannelForConnection;
  M: IConnectionAbstract;

begin

  // The device thread and the main thread may both release the connection.
  if (InterlockedExchange (FReleasedFlag, 1) = 0) then begin

    Released := true;

    // End the connection thread first: it uses the modules, remote commands and
    // send queue that are released below.
    StopThread;

    ConnectionsList.Remove (self as IConnection);

    ClearStationDatabaseEntry;

    FCriticalSection.Enter;
    try
      M := FProtocolModule;
      FProtocolModule := nil;
    finally
      FCriticalSection.Leave;
    end;
    if (assigned (M)) then begin
      M.Release;
      M := nil;
    end;

    K := ChannelRef;
    if (assigned (K)) then begin
      K.EstablishConnection (nil);
      ChannelRef := nil;
    end;

    if (assigned (FRemoteCommands)) then begin
      FRemoteCommands.Release;
      FRemoteCommands := nil;
    end;

    if (assigned (FSendFile)) then begin
      FSendFile.Release;
      FSendFile := nil;
    end;

    if (assigned (FSendFileQueue)) then begin
      FSendFileQueue.Release;
      FSendFileQueue := nil;
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ***
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnection.ConnectionEstablished;
begin
  ConnectionEstablished (false);
end;


procedure   TConnection.ConnectionEstablished (aRestored: Boolean);
const
  MethodName = 'ConnectionEstablished';
begin
  assert (assigned (FOwnerDevice));
  ConnectionStatus := vs_connected;
  FRestored := aRestored;
  CreateThread;
end;


function    TConnection.IsIncomingConnectAllowed: TIncomingConnect;
var
  E: IStationDatabaseEntry;
begin
  E := StationDatabaseEntry;
  if (assigned (E)) then begin
    result := E.IncomingConnect;
  end else begin
    result := ic_default;
  end;
  if (result = ic_default) then begin
    result := Config.IncomingConnect;
  end;
end;


procedure   TConnection.SetDiscTimer;
begin
  Synchronize (SetDiscTimerSync);
end;


procedure   TConnection.SetDiscTimerSync;
begin
  SetTimer (TimerWindow, 0, 500, nil);
end;


procedure   TConnection.Disconnect;
const
  MethodName = 'Disconnect';

begin

  if (not assigned (FOwnerDevice)) then FDiscLevel := dl_kill;

  // A remote command (//q, //d) calls this in the connection thread. From there only
  // the first step (normal disconnect) is allowed: the further levels end the
  // connection thread, which cannot wait for itself.
  if (FDiscLevel <> dl_none) and (InOwnThread) then exit;

  DestroyTimerWindow;

  case FDiscLevel of

    dl_none: begin
      FDiscLevel := dl_end;
      CreateTimerWindow;
      SetDiscTimer;
    end;

    dl_end: begin
      FDiscLevel := dl_cancel;
    end;

    dl_ended: begin
      FDiscLevel := dl_cancel;
    end;

    dl_cancel: begin
      FDiscLevel := dl_kill;
    end;

    dl_canceled: begin
      FDiscLevel := dl_kill;
    end;

    dl_kill: begin
      //
    end;

    dl_killed: begin
      //
    end;

    else begin
      raise PaxonException.create (self, MethodName, 'DiscLevel ungültig.');
    end;

  end;

  if (FDiscLevel < dl_kill) then begin
    Sounds.PlayEvent (se_disconnecting, self as IConnection);
  end;

  if (FDiscLevel > dl_end) and (assigned (FOwnerDevice)) then FOwnerDevice.TerminateConnection (self);

end;


procedure   TConnection.Disconnected (Reason: TDisconnectReason);
const
  MethodName = 'Disconnected';

var
  L: DWord;
  H: THandle;
  K: IChannelForConnection;

  function    ThreadHandle: THandle;
  begin
    FThreadCriticalSection.Enter;
    try
      if (assigned (FThread)) then result := FThread.Handle else result := 0;
    finally
      FThreadCriticalSection.Leave;
    end;
  end;

begin

  assert (assigned (FOwnerDevice));

  // The main thread (last disconnect level) and the device thread (the TNC reports
  // the disconnect) may both get here; only the first one handles it.
  if (InterlockedExchange (FDisconnectedFlag, 1) <> 0) then exit;

  if (TimerWindow <> 0) then DestroyTimerWindow;

  // Let the connection thread finish processing the receive queue; abort
  // if it is not running (any more) or after 4 seconds. The connection
  // thread itself cannot wait for itself.
  if (not InOwnThread) then begin
    L := GetTickCount;
    while (not FReceiveQueue.isEmpty) do begin
      H := ThreadHandle;
      if (H = 0) then break;
      if (WaitForThread (H, 50)) then break;
      if (GetTickCount - L >= 4000) then break;
    end;
  end;

  StopThread;

  ConnectionStatus := vs_disconnected;

  if (Reason <> dr_normal) then begin
    Sounds.PlayEvent (se_linkfailure, self as IConnection);
  end else begin
    Sounds.PlayEvent (se_disconnected, self as IConnection);
  end;

  K := ChannelRef;
  if (assigned (K)) then begin
    K.Disconnected (Reason);
    ChannelRef := nil;
  end;

  ClearStationDatabaseEntry;

end;


procedure   TConnection.ReceiveTextData (const aText: String);
begin
  FReceiveQueue.enqueue (aText);
end;


// FChannel is set to nil in the device thread while e.g. the main thread
// is sending (local echo). Therefore always work with a local copy.

procedure   TConnection.ChannelSendText (const Text: String);
var
  K: IChannelForConnection;
begin
  K := ChannelRef;
  if (assigned (K)) then K.SendTextData (Text);
end;


function    TConnection.ChannelReceiveText (const Text: String): Integer;
var
  K: IChannelForConnection;
begin
  K := ChannelRef;
  if (assigned (K)) then result := K.ReceiveTextData (Text) else result := -1;
end;


procedure   TConnection.ChannelDisplay (const aText: String; aType: TDisplayType);
var
  K: IChannelForConnection;
begin
  K := ChannelRef;
  if (assigned (K)) then K.Display (aText, aType);
end;


procedure   TConnection.ChannelPrompt (const aText: String; aType: TDisplayType);
const
  MethodName = 'ChannelPrompt';
var
  K: IChannelForConnection;
begin
  K := ChannelRef;
  if (assigned (K)) then K.Prompt (aText, aType);
end;


procedure   TConnection.SendTextData (aText: String; aEcho: Boolean; aControlChars: Boolean = false; aWrap: Boolean = false;
                                      aViaModule: Boolean = true);
var
  L, I, N, Q: Integer;
  S: String;
  C: Char;

begin

  L := Length (aText);

  if (aControlChars) then begin
    I := 1;
    N := 1;
    while (N <= L) do begin
      if (aText[N] = '^') then begin
        C := aText[N + 1];
        if (C = '^') then begin
          aText[I] := '^';
          inc (N);
        end else begin
          if (C = '$') then begin
            if (N + 2 <= L) then begin
              Q := StrToIntDef (copy (aText, N + 1, 3), -1);
              if (Q >= 0) then begin
                aText[I] := Chr(Q);
                inc (N, 3);
              end else begin
                aText[I] := aText[N];
              end;
            end else begin
              aText[I] := aText[N];
            end;
          end else begin
            if (C in ['a'..'z']) then dec (C, 32);
            if (C in ['@'..'Z']) then begin
              dec (C, 64);
              aText[I] := C;
              inc (N);
            end else begin
              aText[I] := aText[N];
            end;
          end;
        end;
      end else begin
        aText[I] := aText[N];
      end;
      inc (I);
      inc (N);
    end;
    L := I - 1;
    SetLength (aText, L);
  end;

  if (aWrap) then begin
    aText := WrapTextUlf (aText, #13, [#13, #10, ' '], 78);
    L := Length (aText);
  end;

  repeat
    if (L > 256) then begin
      S := copy (aText, 1, 256);
      if (aViaModule) then begin
        FSendQueue.enqueue (S);
      end else begin
        FDeviceQueue.enqueue (S);
      end;
      if (aEcho and FLocalEcho) then ChannelSendText (S);
      delete (aText, 1, 256);
      Dec (L, 256);
    end else begin
      if (aViaModule) then begin
        FSendQueue.enqueue (aText);
      end else begin
        FDeviceQueue.enqueue (aText);
      end;
      if (aEcho and FLocalEcho) then ChannelSendText (aText);
      L := 0;
    end;
  until (L = 0);

end;


function    TConnection.DiscLevel: TDisconnectLevel;
begin
  result := FDiscLevel;
end;


procedure   TConnection.DiscLevelDone;
const
  MethodName = 'DiscLevelDone';
begin
  case FDiscLevel of
    dl_end: begin
      FDiscLevel := dl_ended;
    end;
    dl_cancel: begin
      FDiscLevel := dl_canceled;
    end;
    dl_kill: begin
      FDiscLevel := dl_killed;
    end;
    else begin
    end;
  end;
  ConnectionStatus := vs_disconnect;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Run
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnection.Run;
const
  MethodName = 'Run';

var
  K: IChannelForConnection;

begin

  // Release may already have run (device stopped right after the connect): then the
  // connection must not be added any more, it would stay in the list forever.
  ConnectionsList.Lock;
  try
    if (not Released) then ConnectionsList.Add (self as IConnection);
  finally
    ConnectionsList.UnLock;
  end;

  try

    try

      FAllEventHandles[e_threaddied]       := FThread.Handle;
      FAllEventHandles[e_threadterminated] := FThreadTerminateEvent.Handle;
      FAllEventHandles[e_receivedata]      := FReceiveQueue.Event.Handle;
      FAllEventHandles[e_senddata]         := FSendQueue.Event.Handle;
      FAllEventHandles[e_sendingpossible]  := FDeviceQueue.EmptyEvent.Handle;
      FAllEventHandles[e_sendfile]         := FSendFileQueue.Event.Handle;

      K := ChannelRef;
      if (assigned (K)) then begin
        if (FRestored) then K.Restored else K.ConnectionEstablished;
      end;

      if (not FRestored) then begin
        if (FOutgoing) then begin
          Sounds.PlayEvent (se_connected_out, self as IConnection);
        end else begin
          Sounds.PlayEvent (se_connected_in, self as IConnection);
        end;
      end;

      if (FSendConnectText) then begin

        if (Config.SendSID) then begin
          SendSID;
        end;

        Texts.SendTextItem (te_greeting, self);

      end;

    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'Before RunStandard');
      end;
    end;

    try
      TConnectionAbstract.RunStandard (self);
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'While RunStandard');
      end;
    end;

  finally
    // After Release the connection is no longer in the list. Release may be
    // waiting for this thread while holding ConnectionsList.Lock.
    if (not Released) then ConnectionsList.Remove (self as IConnection);
  end;

end;


procedure   TConnection.SendSID;
var
  Capabilities: String;
  I, J: Integer;
  S: String;

begin

  Capabilities := 'D'; // DIDADIT
  if (not assigned (StationDatabaseEntry)) then Capabilities := Capabilities + '?';

  I := Pos (' ', Version);
  J := Pos ('-', Version);
  if (I <= 0) or (J < I) then I := J;
  if (I <= 0) then I := MaxInt;
  S := Copy (Version, 1, I - 1);

  SendTextData (Format ('{%s-%s-%s}'#13, [ApplicationName, S, Capabilities]), not Config.HideSentSID);

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Infobox-Connect / Infobox-Reconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TConnection.InfoboxConnect (const aCall: String): Boolean;
const
  MethodName = 'InfoboxConnect';

var
  K: IChannelForConnection;

begin

  if (StationType = st_digi) then begin

    FHistory.Add (Call);

    if (Digis <> '') then Digis := Digis + ' ';
    Digis := Digis + Call;
    Call := aCall;

    StationType := st_unknown;
    K := ChannelRef;
    if (assigned (K)) then K.CallChange;

    Sounds.PlayEvent (se_connected_out, self as IConnection);

    result := true;

  end else begin

    result := false;

  end;

end;


function    TConnection.InfoboxReconnect (const aCall: String): Boolean;
const
  MethodName = 'InfoboxReconnect';

var
  N, I, Q, M, L: Integer;
  S, U: String;
  B: Boolean;
  K: IChannelForConnection;

begin

  result := false;

  I := FHistory.Count - 1;
  if (I >= 0) then begin

    S := 'ERROR';
    B := false;
    for N := I downto 0 do begin
      S := FHistory.Strings[N];
      if (S = aCall) then begin
        B := true;
        break;
      end;
    end;

    if (B) then begin

      Call := S;
      StationType := st_digi;
      U := Digis;
      for Q := I downto N do begin
        L := Length (U);
        S := FHistory.Strings[Q];
        M := Length (S);
        if (CompareText (S, copy (U, L - M + 1, MaxInt)) = 0) then begin
          Delete (U, L - M + 1, MaxInt);
          L := Length (U);
          if (L > 0) and (U[L] = ' ') then delete (U, L, MaxInt);
        end;
        FHistory.Delete (Q);
      end;
      Digis := U;
      K := ChannelRef;
      if assigned (K) then K.CallChange;

      StationType := st_digi;

      Sounds.PlayEvent (se_disconnected, self as IConnection);

      result := true;

    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Save / Restore
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnection.Save (const DeviceRegKey: String);
var
  I: Integer;
  Reg: TRegistry;
  K: IChannelForConnection;
begin
  Reg := TRegistry.create (KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if (Reg.OpenKey (DeviceRegKey + '\' + IntToStr(FHandle), true)) then begin
      try
        Reg.WriteString  ('C', Path);
        Reg.WriteString  ('R', FRealPath);
        Reg.WriteString  ('M', MyCall);
        Reg.WriteBool    ('A', FOutgoing);
        Reg.WriteString  ('H', FHistory.CommaText);
        K := ChannelRef;
        if (assigned (K)) then I := K.No else I := -1;
        Reg.WriteInteger ('K', I);
        Reg.WriteInteger ('T', Ord (FStationType));
        Reg.WriteInteger ('S', Ord (FConnectionStatus));
        Reg.WriteInteger ('BinMode', Ord (FBinMode));
        Reg.WriteInteger ('LocalEcho', Ord (FLocalEcho));
      except
      end;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;


procedure   TConnection.Restore (const DeviceRegKey: String; aHandle: Cardinal);
const
  MethodName = 'Restore';

var
  I: Integer;
  Reg: TRegistry;

begin

  FHandle := aHandle;

  Reg := TRegistry.create (KEY_READ);

  try

    Reg.RootKey := HKEY_CURRENT_USER;

    if (Reg.OpenKey (DeviceRegKey + '\' + IntToStr(FHandle), false)) then begin

      try

        Path        := Reg.ReadString ('C');
        FRealPath   := Reg.ReadString ('R');

        MyCall      := Reg.ReadString ('M');

        FOutgoing  := Reg.ReadBool ('A');

        try
          FHistory.CommaText := Reg.ReadString ('H');
        except
          FHistory.Clear;
        end;

        StationType := st_unknown;
        if (Reg.ValueExists ('T')) then begin
          I := Reg.ReadInteger ('T');
          if (I > Integer(st_first)) and (I < Integer(st_last)) then begin
            StationType := TStationType (I);
          end;
        end;

        ConnectionStatus := vs_connected;
        if (Reg.ValueExists ('S')) then begin
          I := Reg.ReadInteger ('S');
          if (I in [ord (low(TConnectionStatus))..ord (high (TConnectionStatus))]) then begin
            ConnectionStatus := TConnectionStatus (I);
          end;
        end;

        FBinMode := prot_unknown;
        try
          if (Reg.ValueExists ('BinMode')) then begin
            I := Reg.ReadInteger ('BinMode');
            if (I in [ord (low(TSendFileProtocol))..ord (high (TSendFileProtocol))]) then begin
              FBinMode := TSendFileProtocol (I);
            end;
          end;
        except
        end;

        FLocalEcho := true;
        try
          if (Reg.ValueExists ('LocalEcho')) then begin
            if (Reg.ReadInteger ('LocalEcho') = 0) then FLocalEcho := false;
          end;
        except
        end;

        FSendConnectText := false;

        I := Reg.ReadInteger ('K');
        if (I >= 1) and (I <= ChannelList.Quantity) then begin
          ChannelRef := ChannelList[I] as IChannelForConnection;
        end else begin
          ChannelRef := nil;
        end;

      except
        on E: Exception do begin
          DebOut (self, MethodName, E.ClassName + ':' + E.Message);
          raise;
        end;
      end;

      Reg.CloseKey;

      Reg.DeleteKey (DeviceRegKey + '\' + IntToStr(FHandle));

    end;

  finally

    Reg.free;

  end;

  RemoteCommandsPossible := true;

  if (ConnectionStatus >= vs_connected) then begin
    ConnectionEstablished (true);
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Property Get/Set
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TConnection.GetStatus: IStatus;
begin
  result := FStatus;
end;


// FCall, FDigis and FStationDatabaseEntry are set in the device thread (connect)
// and the connection thread ("CONNECTED TO" from a digipeater) and read in the main
// thread: strings and interfaces are reference counted, so only under FCriticalSection.

function    TConnection.GetCall: String;
begin
  FCriticalSection.Enter;
  try
    Result := FCall;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConnection.SetCall (const Value: String);
var
  S: String;
  E, Old: IStationDatabaseEntry;
  Same: Boolean;
begin
  S := Uppercase (Trim (Value));
  FCriticalSection.Enter;
  try
    Same := (FCall = S) and (assigned (FStationDatabaseEntry));
  finally
    FCriticalSection.Leave;
  end;
  if (Same) then exit;
  // open outside the lock: the station database has locks of its own
  E := StationDatabase.Open (S, true);
  FCriticalSection.Enter;
  try
    FCall := S;
    Old := FStationDatabaseEntry;
    FStationDatabaseEntry := E;
  finally
    FCriticalSection.Leave;
  end;
  Old := nil; // released outside the lock
end;


procedure   TConnection.ClearStationDatabaseEntry;
var
  Old: IStationDatabaseEntry;
begin
  FCriticalSection.Enter;
  try
    Old := FStationDatabaseEntry;
    FStationDatabaseEntry := nil;
  finally
    FCriticalSection.Leave;
  end;
  Old := nil; // released outside the lock (saves the entry)
end;


function    TConnection.GetPath: String;
begin
  FCriticalSection.Enter;
  try
    Result := FCall;
    if (FDigis <> '') then Result := Result + ' ' + FDigis;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConnection.SetPath (const Value: String);
var
  N: Integer;
  S: String;

begin

  S := Uppercase (Trim (Value));

  while (true) do begin
    N := pos (' VIA ', S);
    if N <= 0 then break;
    delete (S, N, 4);
  end;

  while (true) do begin
    N := pos (' V ', S);
    if N <= 0 then break;
    delete (S, N, 2);
  end;

  N := Pos (' ', S);
  if (N = 0) then begin
    Call := S;
    Digis := '';
  end else begin
    Call := Copy (S, 1, N - 1);
    Digis := Copy (S, N + 1, MaxInt);
  end;

end;


function    TConnection.GetRealPath: String;
begin
  Result := FRealPath;
end;


procedure   TConnection.SetRealPath (const Value: String);
var
  N: Integer;
  S: String;

begin

  //assert (FConnectionStatus <= vs_connect);

  S := Uppercase (Trim (Value));

  while (true) do begin
    N := pos (' VIA ', S);
    if (N <= 0) then break;
    delete (S, N, 4);
  end;

  while (true) do begin
    N := pos (' V ', S);
    if (N <= 0) then break;
    delete (S, N, 2);
  end;

  FRealPath := S;

end;


function    TConnection.GetMyCall: String;
begin
  Result := FMyCall;
end;


procedure   TConnection.SetMyCall (const Value: String);
begin
  assert (FConnectionStatus <= vs_connect);
  FMyCall := Uppercase (Trim (Value));
end;


function    TConnection.GetDigis: String;
begin
  FCriticalSection.Enter;
  try
    Result := FDigis;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConnection.SetDigis (const Value: String);
begin
  FCriticalSection.Enter;
  try
    FDigis := Value;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConnection.SetHandle (Value: Integer);
begin
  FHandle := Value;
end;


function    TConnection.GetHandle: Integer;
begin
  Result := FHandle;
end;


function    TConnection.GetSendFileQueue;
begin
  result := FSendFileQueue;
end;


function    TConnection.GetAllEventHandles (E: TEventEnum): THandle;
begin
  result := FAllEventHandles[E];
end;


function    TConnection.GetChannelRef: IChannelForConnection;
begin
  // Copy the interface under the lock (not atomic)
  FCriticalSection.Enter;
  try
    Result := FChannel;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConnection.SetChannelRef (aChannelObj: IChannelForConnection);
var
  Former: IChannelForConnection;
begin
  FCriticalSection.Enter;
  try
    Former := FChannel;
    if (Released) then begin
      FChannel := nil;
    end else begin
      FChannel := aChannelObj;
    end;
  finally
    FCriticalSection.Leave;
  end;
  // Calls into the channel (SendMessage to the main thread) outside the lock;
  // the previous channel is released only at the end.
  if (not Released) and (assigned (aChannelObj)) then begin
    aChannelObj.EstablishConnection (self);
    aChannelObj.Status := FConnectionStatus;
  end;
end;


function    TConnection.GetConnectionStatus: TConnectionStatus;
begin
  Result := FConnectionStatus;
end;


procedure   TConnection.SetConnectionStatus (aConnectionStatus: TConnectionStatus);
var
  K: IChannelForConnection;
begin
  if (FConnectionStatus <> aConnectionStatus) then begin
    FConnectionStatus := aConnectionStatus;
    K := ChannelRef;
    if (assigned (K)) then K.Status := FConnectionStatus;
  end;
end;


function    TConnection.GetOutgoing: Boolean;
begin
  result := FOutgoing;
end;


procedure   TConnection.SetOutgoing (aOutgoing: Boolean);
const
  MethodName = 'SetOutgoing';
begin
  if (FOutgoing = false) and (aOutgoing = true) then begin
    Sounds.PlayEvent (se_connecting, self as IConnection);
  end;
  FOutgoing := aOutgoing;
end;


function    TConnection.GetSendConnectText: Boolean;
begin
  result := FSendConnectText;
end;


procedure   TConnection.SetSendConnectText (const Value: Boolean);
begin
  FSendConnectText := Value;
end;


procedure   TConnection.SetStationType (aStationType: TStationType);
var
  K: IChannelForConnection;
begin
  FStationType := aStationType;
  K := ChannelRef;
  if assigned (K) then K.CallChange;
end;


function    TConnection.GetStationType: TStationType;
begin
  result := FStationType;
end;


function    TConnection.GetReceiveQueue: TStringQueue;
begin
  result := FReceiveQueue;
end;


function    TConnection.GetSendQueue: TStringQueue;
begin
  result := FSendQueue;
end;


function    TConnection.GetDeviceQueue: TStringQueue;
begin
  result := FDeviceQueue;
end;


function    TConnection.GetFileSender: ISendFile;
begin
  FCriticalSection.Enter;
  try
    result := FSendFile as ISendFile;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConnection.SetFileSender (aSendFile: ISendFile);
begin
  FCriticalSection.Enter;
  try
    FSendFile := aSendFile as ISendFile;
    if (assigned (FSendFile)) then begin
      if (assigned (FChannel)) then (FSendFile as IPublisher).subscribe (FChannel as ISubscriber);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConnection.GetRemoteCommands: IRemoteCommands;
begin
  result := FRemoteCommands;
end;


function    TConnection.GetRemoteCommandsPossible: Boolean;
begin
  result := FRemoteCommandsPossible;
end;


procedure   TConnection.SetRemoteCommandsPossible (const Value: Boolean);
begin
  FRemoteCommandsPossible := Value;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Thread Create / Terminate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnection.CreateThread;
const
  MethodName = 'CreateThread';
begin
  DebOut (self, MethodName, 'begin...');
  FThreadCriticalSection.Enter;
  try
    if (not assigned (FThread)) then begin
      FThreadTerminateEvent.ResetEvent;
      FThread := TConnectionThread.create (true);
      FThread.FreeOnTerminate := false;
      FThread.PacketConnection := self;
      FThread.Resume;
    end;
  finally
    FThreadCriticalSection.Leave;
  end;
  DebOut (self, MethodName, 'end.');
end;


// Ends the connection thread: signals it and waits up to 4 seconds. Called in the
// connection thread itself, it only signals (a thread cannot wait for itself); a later
// call from another thread then waits. A thread that does not end in time is not
// killed with TerminateThread, which would leave the locks it holds (queues, channel
// output, heap) locked forever: the thread object frees itself when the thread ends.
// The thread keeps a reference to the connection (RunStandard), so the connection
// stays alive until then.

procedure   TConnection.StopThread;
const
  MethodName = 'StopThread';
var
  H: THandle;
  L: DWord;
  B: Boolean;
begin
  FThreadCriticalSection.Enter;
  try
    if (assigned (FThread)) then begin
      FThreadTerminateEvent.SetEvent;
      if (FThread.ThreadID <> GetCurrentThreadID) then begin
        H := FThread.Handle;
        L := GetTickCount;
        B := false;
        repeat
          if (WaitForThread (H, 50)) then begin
            B := true;
            break;
          end;
        until (GetTickCount - L >= 4000);
        if (B) then begin
          FThread.free;
        end else begin
          DebOut (self, MethodName, 'Thread endet nicht, gibt sich am Ende selbst frei.');
          FThread.FreeOnTerminate := true;
        end;
        FThread := nil;
      end;
    end;
  finally
    FThreadCriticalSection.Leave;
  end;
end;


function    TConnection.InOwnThread: Boolean;
begin
  FThreadCriticalSection.Enter;
  try
    result := (assigned (FThread)) and (FThread.ThreadID = GetCurrentThreadID);
  finally
    FThreadCriticalSection.Leave;
  end;
end;


// FProtocolModule is changed in the connection thread (modules start and end) and
// read in the main thread (CancelTransfer) and the device thread (Release).

function    TConnection.GetConnectionModule: IConnectionAbstract;
begin
  FCriticalSection.Enter;
  try
    result := FProtocolModule;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TConnection.SetConnectionModule (const Value: IConnectionAbstract);
const
  MethodName = 'SetConnectionModule';
var
  S: String;
  Old: IConnectionAbstract;
begin
  FCriticalSection.Enter;
  try
    Old := FProtocolModule;
    FProtocolModule := Value;
  finally
    FCriticalSection.Leave;
  end;
  // Drop the old module outside the lock: its destruction may synchronize with the
  // main thread, which may be waiting for FCriticalSection (GetFileSender).
  Old := nil;
  if (assigned (Value)) then begin
    S := Value.Name;
  end else begin
    S := 'nil';
  end;
  DebOut (self, MethodName, S);
end;


procedure   TConnection.CancelTransfer;
var
  M: IConnectionAbstract;
begin
  M := ConnectionModule;
  if (assigned (M)) then begin
    M.CancelTransfer;
  end;
end;


function    TConnection.GetCanCancel: Boolean;
begin
  result := FCanCancel;
end;


procedure   TConnection.SetCanCancel (const Value: Boolean);
var
  K: IChannelForConnection;
begin
  if (Value <> FCanCancel) then begin
    FCanCancel := Value;
    K := ChannelRef;
    if (assigned (K)) then begin
      K.CanCancelChanged;
    end;
  end;
end;


function    TConnection.GetStationDatabaseEntry: IStationDatabaseEntry;
begin
  FCriticalSection.Enter;
  try
    result := FStationDatabaseEntry;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TConnection.GetBinmode: TSendFileProtocol;
begin
  result := FBinMode;
end;


procedure   TConnection.SetBinmode (const Value: TSendFileProtocol);
begin
  FBinMode := Value;
end;


function    TConnection.GetPactor: Boolean;
begin
  result := FPactor;
end;


procedure   TConnection.SetPactor (const Value: Boolean);
begin
  FPactor := Value;
end;


function    TConnection.GetLocalEcho: Boolean;
begin
  result := FLocalEcho;
end;


procedure   TConnection.SetLocalEcho (const Value: Boolean);
begin
  FLocalEcho := Value;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnection.CreateTimerWindow;
begin
  Synchronize (CreateTimerWindowSync);
end;


procedure   TConnection.CreateTimerWindowSync;
var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
  TimerWindowClass: TWndClass;
  TimerWindowClassName: String;

begin

  DestroyTimerWindow;

  TimerWindowClassName := 'VerbindungTimerWindow';

  TimerWindowClass.style := 0;
  TimerWindowClass.lpfnWndProc := @TimerWndProc;
  TimerWindowClass.cbClsExtra := 0;
  TimerWindowClass.cbWndExtra := sizeof (Pointer);
  TimerWindowClass.hIcon := 0;
  TimerWindowClass.hCursor := 0;
  TimerWindowClass.hbrBackground := 0;
  TimerWindowClass.lpszMenuName := nil;
  TimerWindowClass.lpszClassName := PChar(TimerWindowClassName);
  TimerWindowClass.hInstance := HInstance;

  ClassRegistered := GetClassInfo (HInstance, TimerWindowClass.lpszClassName, TempClass);

  if (not ClassRegistered) or (TempClass.lpfnWndProc <> @TimerWndProc) then begin
    if (ClassRegistered) then Windows.UnregisterClass (TimerWindowClass.lpszClassName, HInstance);
    Windows.RegisterClass (TimerWindowClass);
  end;

  TimerWindow := CreateWindow (TimerWindowClass.lpszClassName, '', 0, 0, 0, 0, 0, 0, 0, HInstance, nil);
  SetWindowLong (TimerWindow, 0, Integer(self));

end;


procedure   TConnection.DestroyTimerWindow;
begin
  Synchronize (DestroyTimerWindowSync);
end;


procedure   TConnection.DestroyTimerWindowSync;
begin
  if (TimerWindow <> 0) then begin
    SetWindowLong (TimerWindow, 0, 0);
    KillTimer (TimerWindow, 0);
    DestroyWindow (TimerWindow);
    TimerWindow := 0;
  end;
end;


procedure   TConnection.NotifyTimer;
const
  MethodName = 'NotifyTimer';

begin

  DebOut (self, MethodName, 'begin...');

  if
    (Released)
    or
    (
      ((not assigned (DeviceQueue)) or (DeviceQueue.isempty))
      and
      ((not assigned (ReceiveQueue)) or (ReceiveQueue.isEmpty))
      and
      ((not assigned (SendQueue)) or (SendQueue.isEmpty))
      and
      ((not assigned (FStatus)) or (FStatus.Unack = 0))
    )
    then begin

    DestroyTimerWindow;

    if (not Released) and (assigned (FOwnerDevice)) then FOwnerDevice.TerminateConnection (self);

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TConnection.PactorBreakIn;
const
  MethodName = 'PactorBreakIn';
begin
  DebOut (self, MethodName, 'begin...');
  FOwnerDevice.PactorBreakIn (self);
  DebOut (self, MethodName, 'end.');
end;


procedure   TConnection.PactorChangeOver;
const
  MethodName = 'PactorChangeOver';
begin
  DebOut (self, MethodName, 'begin...');
  FOwnerDevice.PactorChangeOver (self);
  DebOut (self, MethodName, 'end.');
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Thread
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionThread.Execute;
const
  MethodName = 'Execute';
begin
  try
    PacketConnection.Run;
  except
    on E: Exception do begin
      ShowUnhandledException (E, ClassName, MethodName);
      raise;
    end;
  end;
end;


destructor  TConnectionThread.Destroy;
const
  MethodName = 'Destroy';
begin
  DebOut (self, MethodName, 'begin...');
  PacketConnection := nil;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure  TApplicationRec.AfterConstruction;
begin
  ReceiveQueue := TStringQueue.create;
end;


procedure  TApplicationRec.BeforeDestruction;
begin
  ReceiveQueue.free;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

