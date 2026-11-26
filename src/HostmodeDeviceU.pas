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


unit HostmodeDeviceU;


interface


uses
  Windows, Classes, SysUtils, Messages,
  Forms, Controls, SyncObjs,
  GlobalU, InterfacesU, DeviceU, ChannelU,
  PublisherU, ConnectionU, QueueU, MyCallsU, MyCallU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TOwnCallsignsSubscriber = class;


  THostmodeDeviceParameter = class
    DeviceID: Integer;
    TncInit: TStringList;
    TncDeinit: TStringList;
    constructor Create; virtual;
    destructor  Destroy; override;
  end;


  THostmodeDeviceParameterClass = class of THostmodeDeviceParameter;


  THostmodeDevice = class (TDevice)
  private

    FRadioChannel: array[0..7] of IRadioChannel;
    FConnectionList: array[0..255] of IConnection;
    // Channels whose connection was killed (dl_kill) and freed while the TNC still has
    // the link: not taken over as a new connection until the TNC reports it gone.
    // Protected by ConnectionsCriticalSection.
    FKillPending: array[0..255] of Boolean;
    FMonitorFrame: TMonitorFrame;
    FTncChannelCount: Integer;
    FExtendedHostmode: Boolean;
    FMonitor: Cardinal;
    FMonitorOk: Boolean;
    FDeviceName: string;
    FOwnCallsigns: TStringList;
    FResyncCount: Integer;
    FResyncCountCriticalSection: TCriticalSection;
    FullCheckCount: Integer;
    OwnCallsignsSubscriber: ISubscriber;
    OwnCallsignsCriticalSection: TCriticalSection;
    ConnectionsCriticalSection: TCriticalSection;
    PactorChannel: Integer;
    MessagesCriticalSection: TCriticalSection; // protects FMessagesClosed and the lists of open jobs
    FMessagesClosed: Boolean;             // device thread no longer accepts messages
    FOpenConnects: TList;                      // PRecConnect whose msg_connect is in transit or being processed
    FOpenUIFrames: TList;                       // PRecUIFrame whose msg_uiframe is in transit or being processed

    function    CommandStr (ChannelRef: Byte; CommandStr: Boolean; DataText: string; var ResponseStr: string;
                            var ResponseValue: Integer): Boolean;
    function    Resync: Boolean;
    function    IsInHostmode: Boolean;
    function    MonitorHeader (H: string): Boolean;
    procedure   MonitorBody (S: string);
    function    SwitchToHostmode: Boolean;
    function    GetTNCStatus (const TNCChannel: Integer; var TNCStatus: array of Integer): Boolean;
    function    GetCommandC (const TNCChannel: Integer; var Call: string): Boolean;
    procedure   ConnectionEstablished (const TNCChannel: Integer; const aCall: string; const aSendConnectText: Boolean);
    procedure   SetMonitor;
    procedure   OwnCallsignsChanged;
    function    SetOwnCallsigns (AllChannels: Boolean): Integer;
    function    KillPending (TNCChannel: Integer): Boolean;
    procedure   SetKillPending (TNCChannel: Integer; Value: Boolean);
    function    GetResyncCount: Integer;
    procedure   IncResyncCount;
    procedure   SetStatusReady;
    function    GetConnectPath (S: String): String;
    property    ResyncCount: Integer read GetResyncCount;
    function    PTCPortName: String;
    procedure   DiscardMessages;
    procedure   JobDone (aMsg: Cardinal; P: Pointer);

  protected

    // FParam is replaced in the main thread (ApplySettings) while the device thread
    // reads it: replace it only with ReplaceParam, read it in the device thread only
    // under LockParam (or via GetTncInit, GetTncDeinit, ParamDeviceID).
    FParam: THostmodeDeviceParameter;
    FNewParam: THostmodeDeviceParameter;
    FParamCriticalSection: TCriticalSection;
    FThreadTncList: TStringList; // device thread only

    procedure   LockParam;
    procedure   UnlockParam;
    procedure   ReplaceParam (aNewParam: THostmodeDeviceParameter);
    procedure   GetTncInit (L: TStrings);
    procedure   GetTncDeinit (L: TStrings);
    function    ParamDeviceID: Integer;

    function    CommOpen: Boolean; virtual; abstract;
    function    CommClose: Boolean; virtual; abstract;
    function    CommWrite (const Buffer; nNumberOfBytesToWrite: DWORD;
                           var lpNumberOfBytesWritten: DWORD): Boolean; virtual; abstract;
    function    CommRead (var Buffer; nNumberOfBytesToRead: DWORD; var lpNumberOfBytesRead: DWORD): Boolean; virtual; abstract;
    procedure   CommPurge; virtual; abstract;
    function    CommOpened: Boolean; virtual; abstract;

    function    ParameterClass: THostmodeDeviceParameterClass; virtual; abstract;
    function    SetTimeouts (aResync: Boolean): Boolean; virtual; abstract;
    procedure   UpdateParamText; virtual; abstract;

    function    ThreadMessage (aMsg: Cardinal; aWParam, aLParam: Integer): Boolean;

  public

    constructor Create; override;
    destructor  Destroy; override;
    procedure   Init; override;
    procedure   DeInit; override;
    procedure   Save; override;
    function    RadioChannels (var aRadioChannels: array of IRadioChannel): Integer; override;
    function    EstablishConnection (aRadioChannel: IRadioChannel; var aCall: String; var aMyCall: String; aChannelObj: IChannel;
                                     var Connection: IConnection): TConnectError; override;
    procedure   TerminateConnection (aConnectionObj: IConnection); override;
    procedure   Restore; override;
    procedure   Run; override;
    procedure   OwnCallsignsNotify;
    function    SendUI  (aRadioChannel: IRadioChannel; aDestination, aMyCall, aText: String): Boolean; override;
    procedure   PactorBreakIn (aConnectionObj: IConnection); override;
    procedure   PactorChangeOver (aConnectionObj: IConnection); override;

  end;


  TOwnCallsignsSubscriber = class (TInterfacedObject, ISubscriber)
  private
    FHostmodeDevice: THostmodeDevice;
  public
    constructor Create (aHostmodeDevice: THostmodeDevice); virtual;
    destructor  Destroy; override;
    procedure   Notify (P: Pointer); virtual;
  end;


const
  msg_connect = WM_USER + $4041;
  msg_disconnect = WM_USER + $4042;
  msg_owncallsigns = WM_USER + $4043;
  msg_initparameter = WM_USER + $4044;
  msg_uiframe = WM_USER + $4045;
  msg_pactorbreakin = WM_USER + $4046;
  msg_pactorchangeover = WM_USER + $4047;


resourcestring
  SAllPortsBusy = 'Alle Kanäle sind belegt.';
  SIsInHostmodeSendInit = 'Ist im Hostmode... Sende Init.';
  SOpeningPort = 'Öffnen der Schnittstelle';
  SFrameReject = 'Frame Reject (%s)';


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


uses
  DebOutU, Registry, MainU, ChannelsU, RadioChannelU, ConfigU,
  SsidIteratorU, UnhandledExceptionU, StrUtils, ConnectionsListU,
  HostmodeTFWinDeviceU;


// Compares a connection path as entered (RealPath) with the TNC's answer to 'C':
// case, "VIA", SSID -0 and repeated blanks do not count.

function    NormalizePath (const Path: String): String;
var
  SL: TStringList;
  N: Integer;
  S: String;
begin
  result := '';
  SL := TStringList.create;
  try
    SL.Delimiter := ' ';
    SL.DelimitedText := UpperCase (Path);
    for N := 0 to SL.Count - 1 do begin
      S := SL[N];
      if (S = '') or (S = 'VIA') or (S = 'V') then continue;
      if (Length (S) > 2) and (Copy (S, Length (S) - 1, 2) = '-0') then SetLength (S, Length (S) - 2);
      if (result <> '') then result := result + ' ';
      result := result + S;
    end;
  finally
    SL.free;
  end;
end;


function    SamePath (const A, B: String): Boolean;
begin
  result := (NormalizePath (A) = NormalizePath (B));
end;


type
  PRecConnect = ^TRecConnect;
  TRecConnect = record
    PacketConnection: IConnection;
    Event: TSimpleEvent;
    RadioChannel: IRadioChannel;
    Result: TConnectError;
    RefCount: Integer;        // held by EstablishConnection and by the message to the device thread
    AccessLock: TCriticalSection; // protects IsExpired and Adopted
    IsExpired: Boolean;      // EstablishConnection no longer waits
    Adopted: Boolean;     // device thread delivers the result
  end;

  PRecUIFrame = ^TRecUIFrame;
  TRecUIFrame = record
    Mycall: String;
    Dest: String;
    Text: String;
    Port: Integer;
  end;

  // Access to the Windows lock for TryEnterCriticalSection (see DeInit)
  TCriticalSectionAccess = class (TCriticalSection);


// A connection job (TRecConnect) lives on the heap. EstablishConnection and the message to the
// device thread each hold a reference; whoever finishes last frees it. Whether the result
// still counts is decided under the job's lock: either the device thread adopts
// the job (then EstablishConnection waits for the event), or EstablishConnection gives up first (then
// the thread discards its result).
// While the message is in transit or being processed, the job is registered with the device
// (FOpenConnects, likewise UI frames in FOpenUIFrames). Whoever unregisters it under
// MessagesCriticalSection releases the message's reference: the device thread
// after processing (JobDone), DiscardMessages at the end of Run - even after an
// exception in the middle of processing - or DeInit if the thread was aborted.


procedure   RecConnectRelease (P: PRecConnect);
begin
  if (InterlockedDecrement (P^.RefCount) = 0) then begin
    P^.Event.Free;
    P^.AccessLock.Free;
    Dispose (P);
  end;
end;


function    RecConnectAdopt (P: PRecConnect): Boolean;
begin
  P^.AccessLock.Enter;
  try
    Result := not P^.IsExpired;
    if (Result) then P^.Adopted := true;
  finally
    P^.AccessLock.Leave;
  end;
end;


function    RecConnectGiveUp (P: PRecConnect): Boolean;
begin
  P^.AccessLock.Enter;
  try
    Result := not P^.Adopted;
    if (Result) then P^.IsExpired := true;
  finally
    P^.AccessLock.Leave;
  end;
end;


// Completes unregistered jobs whose message will no longer be processed: EstablishConnection
// gets vf_deviceerror unless a result has already been reported, and the message's reference
// is released; UI frames are discarded. Frees the lists.
procedure   FinishJobs (ConnectRequests, UIFrames: TList);
var
  N: Integer;
  P: PRecConnect;
begin
  try
    for N := 0 to ConnectRequests.Count - 1 do begin
      P := PRecConnect (ConnectRequests[N]);
      if (P^.Event.WaitFor (0) <> wrSignaled) then begin
        P^.Result := vf_deviceerror;
        P^.Event.SetEvent;
      end;
      RecConnectRelease (P);
    end;
    for N := 0 to UIFrames.Count - 1 do begin
      Dispose (PRecUIFrame (UIFrames[N]));
    end;
  finally
    ConnectRequests.Free;
    UIFrames.Free;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor THostmodeDeviceParameter.Create;
begin
  inherited;
  TncInit := TStringList.Create;
  TncDeinit := TStringList.Create;
end;


destructor  THostmodeDeviceParameter.Destroy;
begin
  TncInit.free;
  TncDeinit.free;
  inherited;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor THostmodeDevice.Create;
var
  I: Integer;

begin

  inherited;

  FParamCriticalSection := TCriticalSection.create;
  FThreadTncList := TStringList.create;
  FParam := ParameterClass.Create;

  for I := Low (FConnectionList) to High (FConnectionList) do begin
    FConnectionList[I] := nil;
  end;

  FMonitorOk := false;

  ConnectionsCriticalSection  := TCriticalSection.create;

  MessagesCriticalSection := TCriticalSection.create;
  FMessagesClosed := false;
  FOpenConnects := TList.create;
  FOpenUIFrames := TList.create;

  OwnCallsignsCriticalSection := TCriticalSection.create;

  OwnCallsignsSubscriber := TOwnCallsignsSubscriber.create (self);
  Mycalls.Subscribe (OwnCallsignsSubscriber);

  FMonitor := Config.Monitor;
  FOwnCallsigns := TStringList.create;
  FResyncCountCriticalSection := TCriticalSection.create;
  FResyncCount := 0;

  with FMonitorFrame do begin
    Device := 0;
    Port := 0;
    Src := '';
    Dest := '';
    Digis := '';
    PID := $00;
    FrameType := FT_UI;
    RXSeq := 0;
    TXSeq := 0;
    Command := false;
    PollFinal := false;
    Dama := false;
    TxDel := 0;
    Sent := false;
    Text := '';
  end;

  PactorChannel := -1;

end;


destructor  THostmodeDevice.Destroy;
const
  MethodName = 'Destroy';

var
  I: Integer;

begin

  DebOut (self, MethodName, 'begin...');

  Mycalls.Unsubscribe (OwnCallsignsSubscriber);
  OwnCallsignsSubscriber := nil;

  ConnectionsCriticalSection.Enter;
  try
    for I := Low (FConnectionList) to High (FConnectionList) do begin
      if (assigned (FConnectionList[I])) then begin
        FConnectionList[I].Release;
        FConnectionList[I] := nil;
      end;
    end;
  finally
    ConnectionsCriticalSection.Leave;
  end;

  FOwnCallsigns.free;

  OwnCallsignsCriticalSection.free;

  ConnectionsCriticalSection.free;

  MessagesCriticalSection.free;

  FOpenConnects.free;

  FOpenUIFrames.free;

  FResyncCountCriticalSection.free;

  FNewParam.free;

  FParam.free;

  FThreadTncList.free;
  FParamCriticalSection.free;

  inherited;

  DebOut (self, MethodName, 'end.');

end;


procedure   THostmodeDevice.Init;
const
  MethodName = 'Init';

var
  Registry: TRegistry;
  S: string;
  I, N: Integer;

begin

  Debout (self, MethodName, 'begin...');

  if (FRegKey <> '') then begin

    Registry := TRegistry.Create (KEY_READ);

    try

      Registry.RootKey := HKEY_CURRENT_USER;

      if (Registry.OpenKey (FRegKey, false)) then begin

        FParam.TncInit.Clear;
        try
          I := Registry.GetDataSize ('Init');
          if (I > 0) then begin
            SetLength (S, I);
            Registry.ReadBinaryData ('Init', S[1], I);
            while Length (S) > 0 do begin
              N := Pos (#0, S);
              if (N = 0) then break;
              // Hostmode-Befehle haben höchstens 256 Zeichen (CommandStr prüft das per Assert)
              FParam.TncInit.Add (Copy (Copy (S, 1, N - 1), 1, 256));
              S := Copy (S, N + 1, MaxInt);
            end;
          end;
        except
        end;

        FParam.TncDeinit.Clear;
        try
          I := Registry.GetDataSize ('Deinit');
          if (I > 0) then begin
            SetLength (S, I);
            Registry.ReadBinaryData ('Deinit', S[1], I);
            while Length (S) > 0 do begin
              N := Pos (#0, S);
              if (N = 0) then break;
              FParam.TncDeinit.Add (Copy (Copy (S, 1, N - 1), 1, 256));
              S := Copy (S, N + 1, MaxInt);
            end;
          end;
        except
        end;

        Registry.CloseKey;

      end;

    finally
      Registry.free;
    end;

  end;

  // inherited Init calls DeInit if a device thread still exists, which closes the
  // messages: only afterwards does the new device thread accept messages again
  // (see DiscardMessages).
  inherited;

  MessagesCriticalSection.Enter;
  try
    FMessagesClosed := false;
  finally
    MessagesCriticalSection.Leave;
  end;

  Debout (self, MethodName, 'end.');

end;


procedure   THostmodeDevice.Save;
const
  MethodName = 'Save';

var
  Registry: TRegistry;
  S, T: string;
  L, N: Integer;

begin

  inherited;

  DebOut (self, MethodName, 'begin...');
  Registry := TRegistry.Create (KEY_READ or KEY_WRITE);

  try

    Registry.RootKey := HKEY_CURRENT_USER;

    if (Registry.OpenKey (FRegKey, true)) then begin

      Registry.WriteString ('', ClassName);

      S := '';
      for N := 0 to FParam.TncInit.Count - 1 do begin
        T := Trim (FParam.TncInit[N]);
        S := S + T + #0;
      end;
      try
        L := Length (S);
        if (L > 0) then begin
          Registry.WriteBinaryData ('Init', S[1], L);
        end else begin
          Registry.DeleteValue ('Init');
        end;
      except
        DebOut (self, MethodName, 'FEHLER: Kann INIT nicht in die Registry schreiben.');
      end;

      S := '';
      for N := 0 to FParam.TncDeinit.Count - 1 do begin
        T := Trim (FParam.TncDeinit[N]);
        S := S + T + #0;
      end;
      try
        L := Length (S);
        if (L > 0) then begin
          Registry.WriteBinaryData ('Deinit', S[1], Length (S));
        end else begin
          Registry.DeleteValue ('Deinit');
        end;
      except
        DebOut (self, MethodName, 'FEHLER: Kann DEINIT nicht in die Registry schreiben.');
      end;

      Registry.CloseKey;

    end;

  finally

    Registry.free;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   THostmodeDevice.Restore;
const
  MethodName = 'Restore';

var
  SL: TStringList;
  N, I: Integer;
  PacketConnection: IConnection;
  Registry: TRegistry;
  H: Cardinal;

begin

  DebOut (self, MethodName, 'begin...');

  SL := TStringList.create;

  try

    Registry := TRegistry.create (KEY_READ);
    try
      Registry.RootKey := HKEY_CURRENT_USER;
      if (Registry.OpenKey (FRegKey, true)) then begin
        try
          Registry.GetKeyNames (SL);
        except
        end;
        Registry.CloseKey;
      end;
    finally
      Registry.free;
    end;

    ConnectionsCriticalSection.Enter;
    try

      for N := 0 to SL.Count - 1 do begin

        H := StrToInt (SL[N]);

        ConnectionsList.Lock;
        try
          PacketConnection := TConnection.Create (self);
          try
            PacketConnection.Restore (FRegKey, H);
            PacketConnection.Pactor := (PacketConnection.Handle = PactorChannel);
          except
            PacketConnection.Release;
            PacketConnection := nil;
          end;

          if (assigned (PacketConnection)) then begin
            I := PacketConnection.Handle;
            if (I >= Low (FConnectionList)) and (I <= High (FConnectionList)) and (not assigned (FConnectionList[I])) then begin
              FConnectionList[I] := PacketConnection;
            end else begin
              PacketConnection.Release;
              PacketConnection := nil;
            end;
          end;

        finally
          ConnectionsList.Unlock;
        end;

      end;

    finally
      ConnectionsCriticalSection.Leave;
    end;

  finally

    SL.free;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   THostmodeDevice.ConnectionEstablished (const TNCChannel: Integer; const aCall: string; const aSendConnectText: Boolean);
const
  MethodName = 'ConnectionEstablished';

var
  S: string;
  PacketConnection: IConnection;
  N, I: Integer;
  ChannelRef: IChannelForConnection;
  DoReleaseConnection: Boolean;

begin

  Debout (self, MethodName, 'begin...');

  if (TNCChannel >= Low (FConnectionList)) and (TNCChannel <= High (FConnectionList)) then begin

    ConnectionsCriticalSection.Enter;
    try
      PacketConnection := FConnectionList[TNCChannel];
    finally
      ConnectionsCriticalSection.Leave;
    end;

    if (not assigned (PacketConnection)) then begin

      ConnectionsList.Lock;
      try

        PacketConnection := TConnection.Create (self);
        DoReleaseConnection := true;

        PacketConnection.Path := aCall;
        PacketConnection.RealPath := aCall;

        PacketConnection.Handle := TNCChannel;
        PacketConnection.Outgoing := false;
        PacketConnection.SendConnectText := aSendConnectText;

        PacketConnection.Pactor := (TNCChannel = PactorChannel);

      finally
        ConnectionsList.Unlock;
      end;

      case PacketConnection.IsIncomingConnectAllowed of

        ic_accept: begin

          ChannelRef := ChannelList.NextFreeChannel as IChannelForConnection;

          if (assigned (ChannelRef)) then begin

            PacketConnection.ChannelRef := ChannelRef;

            while (not CommandStr (TNCChannel, true, 'I', S, I)) and (not Terminated) do Resync;
            if (not Terminated) then begin

              PacketConnection.MyCall := S;

              ConnectionsCriticalSection.Enter;
              try
                FConnectionList[TNCChannel] := PacketConnection;
              finally
                ConnectionsCriticalSection.Leave;
              end;

              DoReleaseConnection := false;

              PacketConnection.ConnectionEstablished;

              SetOwnCallsigns (false);

            end;

          end else begin

            DebOut (self, MethodName, 'Verbindungswunsch von %s abgelehnt (kein freier Kanal).', [PacketConnection.Call]);
            while (not CommandStr (TNCChannel, false, RemotePrompt + SAllPortsBusy + #13, S, I)) and (not Terminated) do Resync;
            while (not CommandStr (TNCChannel, true, 'D', S, I)) and (not Terminated) do Resync;

          end;

        end;

        ic_ignore: begin

          DebOut (self, MethodName, 'Verbindungswunsch von %s ignoriert.', [PacketConnection.Call]);
          for N := 1 to 4 do begin
            while (not CommandStr (TNCChannel, true, 'D', S, I)) and (not Terminated) do Resync;
            if (Terminated) then break;
          end;

        end;

        ic_busy: begin

          DebOut (self, MethodName, 'Verbindungswunsch von %s abgelehnt.', [PacketConnection.Call]);

          while (not CommandStr (TNCChannel, false, RemotePrompt + SAllPortsBusy + #13, S, I)) and (not Terminated) do Resync;
          while (not CommandStr (TNCChannel, true, 'D', S, I)) and (not Terminated) do Resync;

        end;

      end;

      ConnectionsList.Lock;
      try

        if (DoReleaseConnection) then begin
          PacketConnection.Release;
          PacketConnection := nil;
        end;

      finally
        ConnectionsList.Unlock;
      end;

    end else begin

      PacketConnection.SendConnectText := false;
      PacketConnection.ConnectionEstablished;

      SetOwnCallsigns (false);

    end;

  end else begin

    Debout (self, MethodName, 'TNCChannel nicht gültig.');

  end;

  Debout (self, MethodName, 'end.');

end;


function    THostmodeDevice.PTCPortName: String;
var
  U: String;
  I: Integer;
  J: Integer;

begin

  result := '';

  while (not CommandStr (0, true, '%B', U, I)) and (not Terminated) do Resync;
  if (Terminated) then exit;

  for I := Length (U) downto 1 do begin
    if (U[I] = #13) then delete (U, I, 1);
  end;

  J := Pos ('settings: ', U);
  if (J >= 1) then U := copy (U, J + 10, Maxint);

  if (AnsiStartsText ('SCS - ', U)) then U := copy (U, 7, MaxInt);

  if not (AnsiStartsText ('NO MODEM', U)) then begin
    result := U;
  end;

end;


procedure   THostmodeDevice.Run;

const
  MethodName = 'Run';

const
  Linkstatus: array[1..8] of string =
   ('BUSY fm',
    'CONNECTED to',
    'LINK RESET fm',
    'LINK RESET to',
    'DISCONNECTED fm',
    'LINK FAILURE with',
    'CONNECT REQUEST fm',
    'FRAME REJECT');

const
  FullCheckCountTrigger = 50;

var
  K, I, N, Q, TNCChannel, J, M, R: Integer;
  NewRadioChannel: array[0..7] of IRadioChannel;
  T: array[0..40] of Char;
  S, V, U, TNCChannelList, TNCChannelConnectedTo: string;
  Msg: TMsg;
  TNCStatus: array[0..5] of Integer;
  SsidIterator: TSsidIterator;
  B: Boolean;
  PacketConnection: IConnection;
  FullCheck: Boolean;
  FullCheckChannel: Boolean;
  CommandOk: Boolean;
  C: Cardinal;
  LastStateTime: Cardinal;
  StateCheck: Boolean;
  MilliSec: Boolean;
  IsPTC: Boolean;
  UiFrame: PRecUiFrame;
  Forwarded: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  assert (assigned (FThread));

  try

    SetStatus (gs_init, SOpeningPort);
    UpdateParamText;
    MilliSec := false;
    IsPTC := false;

    if (CommOpen) then begin

      if (IsInHostmode) then begin
        DebOut (self, MethodName, 'TNC war bereits im Hostmode.');
      end else begin
        DebOut (self, MethodName, 'TNC war im Terminalmode.');
        while (not Terminated) do begin
          if (SwitchtoHostmode) then begin
            break;
          end else begin
            Resync;
          end;
        end;
      end;

      if (not Terminated) then begin

        SetStatus (gs_init, SIsInHostmodeSendInit);
        while (not CommandStr (0, true, 'V', S, I)) and (not Terminated) do Resync;

      end;

      if (not Terminated) then begin

        if (self is THostmodeTFWinDevice) then begin

          FDeviceName := 'TFWin';

        end else begin

          FDeviceName := 'Hostmode';

          S := UpperCase (S);
          if (Pos ('TNC2', S) > 0) then begin
            FDeviceName := 'TNC2';
          end else if (Pos ('TURBO-FIRMWARE', S) > 0) then begin
            FDeviceName := 'TNC3';
            MilliSec := true;
          end else if (Pos ('PTC-II', S) > 0) then begin
            FDeviceName := 'PTC-II';
            MilliSec := true;
            IsPTC := true;
          end;

        end;

      end;

      if (not Terminated) then begin

        B := false;

        for N := Low (NewRadioChannel) to High (NewRadioChannel) do NewRadioChannel[N] := nil;

        PactorChannel := -1;

        if (IsPTC) then begin

          // PTC:
          // %P - [1..2]  INVALID VALUE: 3
          // %B - "Current port settings: SCS - HIGH SPEED / DIRECT FSK MODEM at 9600 baud...
          //    - "Current port settings: SCS - 1200/2400 Bd AFSK MODEM at 1200 baud.
          // %T - Code=1, data='0' on the Pactor channel, otherwise Code=0, data=''.

          while (not CommandStr (0, true, '%P9', U, I)) and (not Terminated) do Resync;

          if (I = 2) and (AnsiStartsText ('INVALID', U)) then begin

            // PTC-II, PTC-IIpro

            DebOut (self, MethodName, 'Gerätetyp: PTC-II oder PTC-IIpro');

            for N := 0 to 4 do begin

              while (not CommandStr (0, true, '%P' + IntToStr (N + 1), U, I)) and (not Terminated) do Resync;
              if (Terminated) then break;

              if (I = 0) then begin

                S := PTCPortName;

                if (S <> '') then begin

                  NewRadioChannel[N] := TRadioChannel.Create (self);
                  NewRadioChannel[N].Name := FDeviceName + ' ' + S;
                  NewRadioChannel[N].Handle := N + 1;
                  NewRadioChannel[N].ID := Format ('HM%d%d', [ParamDeviceID, N + 1]);

                  B := true;

                end;

              end else begin

                break;

              end;

            end;

          end else begin

            // PTC-IIe

            DebOut (self, MethodName, 'Gerätetyp: PTC-IIe');

            FDeviceName := 'PTC-IIe';
            NewRadioChannel[0] := TRadioChannel.Create (self);
            NewRadioChannel[0].Name := FDeviceName + ' ' + PTCPortName;
            NewRadioChannel[0].Handle := -1;
            NewRadioChannel[0].ID := Format ('HM%d%d', [ParamDeviceID, 0]);
            B := true;

          end;

          for J := 1 to 250 do begin

            while (not CommandStr (J, true, '%T', U, I)) and (not Terminated) do Resync;
            if (Terminated) then break;

            if (I = 1) then begin
              PactorChannel := J;
              break;
            end else if (I <> 0) then begin
              break;
            end;

          end;

          if (not Terminated) then begin

            if (PactorChannel >= 1) then begin

              N := High (NewRadioChannel);
              NewRadioChannel[N] := TRadioChannel.Create (self);
              NewRadioChannel[N].Name := FDeviceName + ' PACTOR';
              NewRadioChannel[N].Handle := 255;
              NewRadioChannel[N].ID := Format ('HM%d%d', [ParamDeviceID, 255]);

            end;

          end;

        end else begin

          for J := 0 to 4 do begin

            N := (J + 1) mod 5;

            while (not CommandStr (0, true, '#PORT' + IntToStr (N), U, I)) and (not Terminated) do Resync;
            if (Terminated) then break;

            if (I >= 0) and (I <= 1) then begin
              NewRadioChannel[N] := TRadioChannel.Create (self);
              if (N = 0) then S := 'intern' else S := 'Port ' + IntToStr (N);
              NewRadioChannel[N].Name := FDeviceName + ' ' + S;
              NewRadioChannel[N].Handle := N;
              NewRadioChannel[N].ID := Format ('HM%d%d', [ParamDeviceID, N]);
              B := true;
            end;

          end;

        end;

        if (not B) then begin
          NewRadioChannel[0] := TRadioChannel.Create (self);
          NewRadioChannel[0].Name := FDeviceName;
          NewRadioChannel[0].Handle := -1;
          NewRadioChannel[0].ID := Format ('HM%d', [ParamDeviceID]);
        end;

      end;

      // Die Funkkanäle lokal aufbauen und erst fertig unter der Sperre
      // übernehmen: RadioChannels kopiert sie im Hauptthread.
      CriticalSection.Enter;
      try
        for N := Low (FRadioChannel) to High (FRadioChannel) do FRadioChannel[N] := NewRadioChannel[N];
      finally
        CriticalSection.Leave;
      end;
      for N := Low (NewRadioChannel) to High (NewRadioChannel) do NewRadioChannel[N] := nil;

      DebOut (self, MethodName, 'Pactor-Channel: %d', [PactorChannel]);

      if (PactorChannel >= 0) and (assigned (FConnectionList[PactorChannel])) then FConnectionList[PactorChannel].Pactor := true;

      I := 0;
      if (not Terminated) then begin
        while (not CommandStr (255, true, 'G', S, I)) and (not Terminated) do Resync;
      end;

      if (not Terminated) then begin
        if (I = 1) then begin
          FExtendedHostmode := true;
          DebOut (self, MethodName, 'Extended Hostmode.');
        end else begin
          FExtendedHostmode := false;
          DebOut (self, MethodName, 'Standard Hostmode.');
        end;
      end;

      if (not Terminated) then begin

        DebOut (self, MethodName, 'Initialisiere TNC...');

        PostThreadMessage (GetCurrentThreadId, msg_initparameter, 0, 0);

        SetMonitor;

        SetStatusReady;

        DebOut (self, MethodName, 'Bereit.');

        DebOut (self, MethodName, 'Frage Kanäle ab und setze Rufzeichen...');
        OwnCallsignsChanged;
        FTncChannelCount := SetOwnCallsigns (true);
        DebOut (self, MethodName, 'TNC hat %d Kanäle.', [FTncChannelCount]);

        TNCChannelList := '';
        if (not FExtendedHostmode) then begin
          for N := 0 to FTncChannelCount do begin
            TNCChannelList := TNCChannelList + Chr (N + 1);
          end;
        end;

      end;

      FullCheckCount := 0;

      LastStateTime := GetTickCount;

      //////////////////////////////////////////////////////////////////////////

      DebOut (self, MethodName, 'Start der Hostmode-Hauptschleife...');

      while (not Terminated) do begin

        try

          //////////////////////////////////////////////////////////////////////
          // Start of the loop...
          //////////////////////////////////////////////////////////////////////


          if (FullCheckCount <= 0) or (FullCheckCount > FullCheckCountTrigger) then begin
            FullCheck := true;
            FullCheckCount := 1;
          end else begin
            FullCheck := false;
            inc (FullCheckCount);
          end;

          (*
          if (FullCheck) then begin
            DebOut (self, MethodName, 'FullCheck');
          end;
          *)

          if (FullCheck) then begin
            C := Config.Monitor;
            if (C <> FMonitor) then begin
              FMonitor := C;
              SetMonitor;
            end;
          end;

          if (FExtendedHostmode) then begin
            if (FullCheck) then begin
              SetLength (TNCChannelList, FTncChannelCount);
              for I := 1 to FTncChannelCount do begin
                TNCChannelList[I] := chr (I + 1);
              end;
            end else begin
              while (not CommandStr (255, true, 'G', TNCChannelList, I)) and (not Terminated) do Resync;
              if (Terminated) then begin
                DebOut (self, MethodName, 'Terminated, break. (1)');
                break;
              end;
              // Only code 1 carries the list of channels with pending data.
              if (I <> 1) then TNCChannelList := '';
            end;
          end;

          //////////////////////////////////////////////////////////////////////
          // Poll channels with 'G'...
          //////////////////////////////////////////////////////////////////////


          for N := 1 to Length (TNCChannelList) do begin

            TNCChannel := Ord (TNCChannelList[N]) - 1;
            if (TNCChannel < 0) then continue;

            if (TNCChannel > FTncChannelCount) then begin

              for K := 1 to 7 do begin
                if (not CommandStr (TNCChannel, true, 'G', S, R)) then begin
                  Resync;
                  break;
                end;
              end;

            end else begin

              FullCheckChannel := (FullCheck) and (TNCChannel <> 0);

              if (FullCheckChannel) then begin
                if (not GetCommandC (TNCChannel, TNCChannelConnectedTo)) then begin
                  TNCChannelConnectedTo := '';
                end;
              end else begin
                TNCChannelConnectedTo := '';
              end;

              if (TNCChannel = 0) then begin
                J := 20;
              end else begin
                J :=  7;
              end;

              for K := 1 to J do begin

                CommandOk := CommandStr (TNCChannel, true, 'G', S, R);

                if (not CommandOk) then begin
                  Debout (self, MethodName, 'Fehler beim Abfragen von Kanal %d (1)', [TNCChannel]);
                  if (not Resync) then break;
                end;

                case R of

                  0: begin // success, no data

                    if (CommandOk) then begin

                      if (FullCheckChannel) then begin


                        ConnectionsCriticalSection.Enter;
                        try
                          PacketConnection := FConnectionList[TNCChannel];
                        finally
                          ConnectionsCriticalSection.Leave;
                        end;

                        if (assigned (PacketConnection)) then begin

                          if (not SamePath (PacketConnection.RealPath, TNCChannelConnectedTo)) then begin
                            DebOut (self, MethodName, 'FULLCHECK: TNCChannelConnectedTo = ' + TNCChannelConnectedTo);
                            DebOut (self, MethodName, 'FULLCHECK: RealPath = ' + PacketConnection.RealPath);
                            DebOut (self, MethodName, 'Verbindung.Getrennt... (1)');
                            PacketConnection.Disconnected (dr_linkfailure);
                            ConnectionsList.Lock;
                            try
                              PacketConnection.Release;
                              ConnectionsCriticalSection.Enter;
                              try
                                if (FConnectionList[TNCChannel] = PacketConnection) then FConnectionList[TNCChannel] := nil;
                              finally
                                ConnectionsCriticalSection.Leave;
                              end;
                            finally
                              ConnectionsList.Unlock;
                            end;
                            // Letzte Referenz erst ohne Sperren freigeben: Der Abbau schickt
                            // per Synchronize an den Hauptthread (sonst Verklemmung).
                            PacketConnection := nil;
                            SetOwnCallsigns (false);
                          end;

                        end else begin

                          // A link we killed is not taken over again before it is gone.
                          if (TNCChannelConnectedTo = '') then SetKillPending (TNCChannel, false);
                          if (TNCChannelConnectedTo <> '') and (not KillPending (TNCChannel)) then begin
                            DebOut (self, MethodName, 'FULLCHECK: Verbindung aufgetaucht.');
                            DebOut (self, MethodName, 'FULLCHECK: TNCChannelConnectedTo = ' + TNCChannelConnectedTo);
                            ConnectionEstablished (TNCChannel, TNCChannelConnectedTo, false);
                          end;

                        end;

                      end;

                      ConnectionsCriticalSection.Enter;
                      try
                        PacketConnection := FConnectionList[TNCChannel];
                      finally
                        ConnectionsCriticalSection.Leave;
                      end;

                      if (assigned (PacketConnection)) then begin
                        PacketConnection.RemoteCommandsPossible := true;
                      end;

                      break;

                    end;

                  end;

                  3: begin // connection status

                    if (CommandOk) then begin

                      FullCheckChannel := false;

                      DebOut (self, MethodName, 'Verbindungsstatus: ' + S);

                      if (Length (S) <= 0) then begin
                        Resync;
                        break;
                      end;

                      // Remove port specification
                      I := Pos (':', Copy (S, 1, 6));
                      if (I > 0) then Delete (S, 1, I);

                      // Remove channel specification "(n) "
                      if (Length (S) >= 1) and (S[1] = ' ') then Delete (S, 1, 1);
                      if (Length (S) >= 1) and (S[1] = '(') then begin
                        I := Pos (')', S);
                        if (I > 0) then S := TrimLeft (Copy (S, I + 1, MaxInt));
                      end;

                      for I := Low (Linkstatus) to High (Linkstatus) do begin

                        if (StrLIComp (PChar(Linkstatus[I]), PChar(S), Length (Linkstatus[I])) = 0) then begin

                          DebOut (self, MethodName, 'Verbindungsstatus: ' + S);

                          S := Copy (S, Length (Linkstatus[I]) + 2, MaxInt);

                          // Any link status ends (or replaces) a link we killed.
                          SetKillPending (TNCChannel, false);

                          case I of

                            1: begin // BUSY fm
                              PacketConnection := FConnectionList[TNCChannel];
                              if (assigned (PacketConnection)) then begin
                                DebOut (self, MethodName, 'Verbindung.Getrennt... (2)');
                                PacketConnection.Disconnected (dr_busy);
                                ConnectionsList.Lock;
                                try
                                  PacketConnection.Release;
                                  ConnectionsCriticalSection.Enter;
                                  try
                                    if (FConnectionList[TNCChannel] = PacketConnection) then FConnectionList[TNCChannel] := nil;
                                  finally
                                    ConnectionsCriticalSection.Leave;
                                  end;
                                finally
                                  ConnectionsList.Unlock;
                                end;
                                // Letzte Referenz erst ohne Sperren freigeben: Der Abbau schickt
                                // per Synchronize an den Hauptthread (sonst Verklemmung).
                                PacketConnection := nil;
                                SetOwnCallsigns (false);
                              end;
                            end;

                            2: begin // CONNECTED to
                              DebOut (self, MethodName, 'Verbindungsstatus: ' + S);
                              U := GetConnectPath (S);
                              if (U = '') then begin
                                if (TNCChannel = PactorChannel) then begin
                                  U := 'PactorMonitor';
                                end else begin
                                  U := '???';
                                end;
                              end;
                              ConnectionEstablished (TNCChannel, U, true);
                            end;

                            3, 4: begin // LINK RESET fm, LINK RESET to
                              PacketConnection := FConnectionList[TNCChannel];
                              if (assigned (PacketConnection)) then begin
                                DebOut (self, MethodName, 'Verbindung.Getrennt... (3)');
                                PacketConnection.Disconnected (dr_normal);
                                ConnectionsList.Lock;
                                try
                                  PacketConnection.Release;
                                  ConnectionsCriticalSection.Enter;
                                  try
                                    if (FConnectionList[TNCChannel] = PacketConnection) then FConnectionList[TNCChannel] := nil;
                                  finally
                                    ConnectionsCriticalSection.Leave;
                                  end;
                                finally
                                  ConnectionsList.Unlock;
                                end;
                                // Letzte Referenz erst ohne Sperren freigeben: Der Abbau schickt
                                // per Synchronize an den Hauptthread (sonst Verklemmung).
                                PacketConnection := nil;
                                ConnectionEstablished (TNCChannel, GetConnectPath (S), true);
                              end;
                            end;

                            5: begin // DISCONNECTED fm
                              DebOut (self, MethodName, 'DISCONNECTED fm: begin...');
                              PacketConnection := FConnectionList[TNCChannel];
                              if (assigned (PacketConnection)) then begin
                                PacketConnection.RealPath := GetConnectPath (S);
                                PacketConnection.Path := PacketConnection.RealPath;
                                DebOut (self, MethodName, 'Verbindung.Getrennt... (4)');
                                PacketConnection.Disconnected (dr_normal);
                                ConnectionsList.Lock;
                                try
                                  PacketConnection.Release;
                                  ConnectionsCriticalSection.Enter;
                                  try
                                    if (FConnectionList[TNCChannel] = PacketConnection) then FConnectionList[TNCChannel] := nil;
                                  finally
                                    ConnectionsCriticalSection.Leave;
                                  end;
                                finally
                                  ConnectionsList.Unlock;
                                end;
                                // Letzte Referenz erst ohne Sperren freigeben: Der Abbau schickt
                                // per Synchronize an den Hauptthread (sonst Verklemmung).
                                PacketConnection := nil;
                                SetOwnCallsigns (false);
                              end;
                              DebOut (self, MethodName, 'DISCONNECTED fm: end.');
                            end;

                            6: begin // LINK FAILURE with
                              PacketConnection := FConnectionList[TNCChannel];
                              if (assigned (PacketConnection)) then begin
                                DebOut (self, MethodName, 'Verbindung.Getrennt... (5)');
                                PacketConnection.Disconnected (dr_linkfailure);
                                ConnectionsList.Lock;
                                try
                                  PacketConnection.Release;
                                  ConnectionsCriticalSection.Enter;
                                  try
                                    if (FConnectionList[TNCChannel] = PacketConnection) then FConnectionList[TNCChannel] := nil;
                                  finally
                                    ConnectionsCriticalSection.Leave;
                                  end;
                                finally
                                  ConnectionsList.Unlock;
                                end;
                                // Letzte Referenz erst ohne Sperren freigeben: Der Abbau schickt
                                // per Synchronize an den Hauptthread (sonst Verklemmung).
                                PacketConnection := nil;
                                SetOwnCallsigns (false);
                              end;
                            end;

                            7: begin // CONNECT REQUEST fm
                              //
                            end;

                            8: begin // FRAME REJECT
                              PacketConnection := FConnectionList[TNCChannel];
                              if (assigned (PacketConnection)) then begin
                                PacketConnection.ChannelPrompt (Format (SFrameReject, [S]), dt_pgp);
                              end;
                            end;

                          end;

                          break;

                        end;

                      end;

                    end;

                  end;

                  4: begin // monitor header, no data
                    if (CommandOk) then begin
                      if ((FMonitor and MonitorStatus) <> 0) then begin
                        if (MonitorHeader (S)) then begin
                          MonitorBody ('');
                        end;
                      end;
                    end;
                  end;

                  5: begin // monitor header, data follows
                    if (CommandOk) then begin
                      if ((FMonitor and MonitorEnabled) <> 0) then begin
                        FMonitorOk := MonitorHeader (S);
                        case FMonitorFrame.FrameType of
                          FT_I: begin
                            if ((FMonitor and MonitorInformation) <> 0) then begin
                              if ((FMonitor and MonitorInformationContent) = 0) then begin
                                MonitorBody ('');
                                FMonitorOk := false;
                              end;
                            end else begin
                              FMonitorOk := false;
                            end;
                          end;
                          FT_UI: begin
                            if ((FMonitor and MonitorUnproto) = 0) then begin
                              FMonitorOk := false;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;

                  6: begin // monitor data
                    if (CommandOk) then begin
                      if ((FMonitor and MonitorEnabled) <> 0) and (FMonitorOk) then begin
                        MonitorBody (S);
                        FMonitorOk := false;
                      end;
                    end;
                  end;

                  7: begin // AX25 data

                    // Nur vollständig gelesene Daten weitergeben; nach einem Lesefehler
                    // enthält S einen Rumpf oder nicht initialisierten Speicher.
                    if (CommandOk) then begin

                      PacketConnection := FConnectionList[TNCChannel];
                      FullCheckChannel := false;
                      if (not assigned (PacketConnection)) or (PacketConnection.ConnectionStatus < vs_connected) then begin
                        DebOut (self, MethodName, 'WARNUNG: AX25-Daten ohne vs_connected');
                        // Eine Verbindung nur übernehmen, wenn der TNC eine Gegenstation
                        // meldet. Sonst (z. B. nach dl_kill) entstünde eine Verbindung mit
                        // leerem Rufzeichen, die nie wieder abgebaut wird.
                        if (GetCommandC (TNCChannel, TNCChannelConnectedTo)) and (TNCChannelConnectedTo <> '') and
                           (not KillPending (TNCChannel)) then begin
                          ConnectionEstablished (TNCChannel, TNCChannelConnectedTo, false);
                          PacketConnection := FConnectionList[TNCChannel];
                        end;
                      end;

                      if (assigned (PacketConnection)) then begin
                        PacketConnection.ReceiveTextData (S);
                      end else begin
                        DebOut (self, MethodName, 'AX25-Daten ohne Verbindung verworfen');
                      end;

                    end;

                  end;

                  else begin // error

                    Debout (self, MethodName, 'Fehler beim Abfragen von Kanal %d (2)', [TNCChannel]);
                    if (not Resync) then break;

                  end;

                end;

              end;

              if (Terminated) then break;

              sleep (0);

            end;

          end;

          //////////////////////////////////////////////////////////////////////
          // Send data...
          //////////////////////////////////////////////////////////////////////


          if ((GetTickCount - LastStateTime) > 333) then begin
            StateCheck := true;
            LastStateTime := GetTickCount;
          end else begin
            StateCheck := false;
          end;

          for N := 0 to FTncChannelCount do begin

            TNCChannel := N;
            PacketConnection := FConnectionList[TNCChannel];

            if (assigned (PacketConnection)) then begin

              // [0]: Number of link status messages not yet displayed
              // [1]: Number of receive frames not yet displayed
              // [2]: Number of send frames not yet transmitted
              // [3]: Number of transmitted frames not yet acknowledged
              // [4]: Number of tries on current operation
              // [5]: Link state
              //      00 = disconnected
              //      01 = Link Setup
              //      02 = Frame Reject
              //      03 = Disconnect Request
              //      04 = Information Transfer
              //      05 = Reject Frame Sent
              //      06 = Waiting Acknowledgement
              //      07 = Device Busy
              //      08 = Remote Device Busy
              //      09 = Both Devices Busy
              //      10 = Waiting Acknowledgement and Device Busy
              //      11 = Waiting Acknowledgement and Remote Busy
              //      12 = Waiting Acknowledgement and Both Devices Busy
              //      13 = Reject Frame Sent and Device Busy
              //      14 = Reject Frame Sent and Remote Busy
              //      15 = Reject Frame Sent and Both Devices Busy

              GetTNCStatus (TNCChannel, TNCStatus);

              case TncStatus[5] of
                2: Q := 3;
                5, 13, 14, 15: Q := 6;
                6, 10, 11, 12: Q := 7;
                else Q := 0;
              end;

              case TncStatus[5] of
                7, 9, 10, 12, 13, 15: Q := Q or $08;
              end;

              case TncStatus[5] of
                8, 9, 11, 12, 14, 15: Q := Q or $10;
              end;

              if (assigned (PacketConnection.Status)) then begin

                with PacketConnection.Status do begin

                  Ax25State := Q;
                  Unack := TncStatus[2] + TncStatus[3] + PacketConnection.DeviceQueue.Count;
                  Tries := TncStatus[4];

                end;

                if (StateCheck) then begin

                  if (not CommandStr (TNCChannel, true, 'O', U, I)) then begin
                    Resync;
                    I := -1;
                  end;
                  if (I = 1) then begin
                    Q := StrToIntDef (U, -1);
                    if (Q >= 0) then begin
                      PacketConnection.Status.MaxFrame := Q;
                    end;
                  end;

                  if (not CommandStr (TNCChannel, true, 'F', U, I)) then begin
                    Resync;
                    I := -1;
                  end;
                  if (I = 1) then begin
                    Q := StrToIntDef (U, -1);
                    if (Q >= 0) then begin
                      if (MilliSec) then Q := Q div 10;
                      if (Q <= 10) then begin
                        PacketConnection.Status.Frack := 1;
                      end else begin
                        PacketConnection.Status.Frack := (Q + 5) div 10;
                      end;
                    end;
                  end;

                end;

              end;

              if (TNCStatus[0] = 0) and (TNCStatus[1] < 7) then begin

                while (not CommandStr (TNCChannel, true, '@B', U, I)) and (not Terminated) do Resync;
                if (Terminated) then break;

                if (I = 1) and (StrToIntDef (U, -1) > 300) then begin

                  J := 14 - (TNCStatus[2] + TNCStatus[3]);

                  while (not PacketConnection.DeviceQueue.isempty) and (J > 0) do begin

                    S := PacketConnection.DeviceQueue.current;

                    while (not CommandStr (TNCChannel, false, S, U, I)) and (not Terminated) do Resync;
                    if (Terminated) then break;

                    if (I = 0) then begin
                      PacketConnection.DeviceQueue.dequeue;
                    end else begin
                      DebOut (self, MethodName, 'Senden: Fehler = ' + U);
                      if (I < 0) then Resync;
                      break;
                    end;

                    dec (J);

                  end;

                end;

              end;

            end;

            sleep (0);

          end;

          //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
          // Process messages...
          //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


          M := 0;

          while (M < 3) and (PeekMessage (Msg, 0, 0, 0, pm_remove)) do begin

            case Msg.Message of

              msg_initparameter: begin

                while not (CommandStr (0, true, 'U0', U, I)) and (not Terminated) do Resync;
                if (Terminated) then break;

                V := '';
                GetTncInit (FThreadTncList);
                for N := 0 to FThreadTncList.Count - 1 do begin
                  S := Trim (FThreadTncList[N]);
                  V := V + '  ' + S + ': ';
                  if (Length (S) >= 1) then begin
                    if (Upcase(S[1]) in ['C', 'D', 'M', 'Y', 'I', 'Q']) then begin
                      V := V + 'ignoriert';
                    end else begin
                      while not (CommandStr (0, true, S, U, I)) and (not Terminated) do Resync;
                      if (Terminated) then break;
                      if (U <> '') then begin
                        V := V + '"' + U + '"';
                      end else begin
                        V := V + 'ok';
                      end;
                    end;
                  end;
                  V := V + #13;
                end;

                if ((FMonitor and MonitorLocal) <> 0) then begin
                  ChannelList.Monitor ('[TNC ' + ParameterText + ': Init]', V);
                end;

              end;

              msg_owncallsigns: begin

                Debout (self, MethodName, 'msg_eigenerufzeichen empfangen');
                SetOwnCallsigns (true);

              end;

              msg_connect: begin

                // The message holds a reference to the job (see EstablishConnection). It is
                // released as soon as the job is done, unless the job is queued again.
                Forwarded := false;

                // Vorzeichenbehafteter Abstand statt ">": übersteht den Überlauf von GetTickCount
                if (Integer (GetTickCount - Cardinal (Msg.wParam)) > 0) or (PRecConnect (Msg.lParam)^.IsExpired) then begin

                  Debout (self, MethodName, 'msg_connect empfangen (abgelaufen)');
                  JobDone (msg_connect, Pointer (Msg.lParam));

                end else begin

                  Debout (self, MethodName, 'msg_connect empfangen (gut und frisch)');

                  if (PactorChannel >= 1) and (PRecConnect (Msg.lParam)^.RadioChannel.Handle = 255) then begin

                    PRecConnect (Msg.lParam)^.Result := vf_deviceerror;

                    TNCChannel := PactorChannel;

                    while (not CommandStr (TNCChannel, true, 'C', U, I)) and (not Terminated) do Resync;
                    if (Terminated) then begin
                      JobDone (msg_connect, Pointer (Msg.lParam));
                      break;
                    end;

                    if (AnsiStartsText ('*** SIMULT', U)) then begin

                      PRecConnect (Msg.lParam)^.Result := vf_notsimultaneous;

                    end else if (AnsiStartsText ('CHANNEL NO', U)) then begin

                      if (assigned (FConnectionList[TNCChannel])) then begin
                        // Queue the job again together with its reference
                        if (not PostThreadMessage (GetCurrentThreadId, msg_connect, Msg.wParam, Msg.lParam)) then begin
                          JobDone (msg_connect, Pointer (Msg.lParam));
                        end;
                        sleep (50);
                        break;
                      end;

                      PacketConnection := PRecConnect (Msg.lParam)^.PacketConnection;

                      DebOut (self, MethodName, 'Verwende MyCall ' + PacketConnection.MyCall);

                      while (not CommandStr (TNCChannel, true, 'I ' + PacketConnection.MyCall, U, Q)) and (not Terminated) do
                        Resync;
                      if (Terminated) then begin
                        JobDone (msg_connect, Pointer (Msg.lParam));
                        break;
                      end;

                      if (Q > 0) or (U <> '') then DebOut (self, MethodName, 'MyCall-setzen fehlgeschlagen (' + U + ')');

                      S := PacketConnection.Path;
                      DebOut (self, MethodName, 'Connecte...: ' + S);

                      while (not CommandStr (TNCChannel, true, 'C' + S , U, Q)) and (not Terminated) do Resync;
                      if (Terminated) then begin
                        JobDone (msg_connect, Pointer (Msg.lParam));
                        break;
                      end;

                      if (Q = 0) then begin
                        if (RecConnectAdopt (PRecConnect (Msg.lParam))) then begin
                          DebOut (self, MethodName, 'Connect erfolgreich.');
                          PacketConnection.Handle := TNCChannel;
                          PacketConnection.Pactor := (TNCChannel = PactorChannel);
                          ConnectionsCriticalSection.Enter;
                          try
                            FConnectionList[TNCChannel] := PacketConnection;
                          finally
                            ConnectionsCriticalSection.Leave;
                          end;
                          PRecConnect (Msg.lParam)^.Result := vf_ok;
                        end else begin
                          DebOut (self, MethodName, 'Connect erfolgreich, aber Verbinde hat schon aufgegeben - trenne.');
                          while (not CommandStr (TNCChannel, true, 'D', U, Q)) and (not Terminated) do Resync;
                        end;
                      end else begin

                        if (AnsiStartsText ('STATION AL', U)) then begin
                          DebOut (self, MethodName, 'Station bereits verbunden...');
                        end else if (AnsiStartsText ('*** SIMULT', U)) then begin
                          PRecConnect (Msg.lParam)^.Result := vf_notsimultaneous;
                        end else begin
                          DebOut (self, MethodName, 'Connect fehlgeschlagen (' + U + ')');
                          if (RecConnectAdopt (PRecConnect (Msg.lParam))) then begin
                            DebOut (self, MethodName, 'Verbindung.Getrennt... (6)');
                            PacketConnection.Disconnected (dr_linkfailure);
                          end;
                          PacketConnection := nil;
                          PRecConnect (Msg.lParam)^.Result := vf_deviceerror;
                        end;
                      end;

                    end else begin

                      PRecConnect (Msg.lParam)^.Result := vf_channelalreadyconnected;

                    end;

                    PRecConnect (Msg.lParam)^.Event.SetEvent;
                    JobDone (msg_connect, Pointer (Msg.lParam));

                  end else begin

                    PRecConnect (Msg.lParam)^.Result := vf_deviceerror;

                    for TNCChannel := FTncChannelCount downto 1 do begin

                      if (TNCChannel = PactorChannel) then continue;

                      while (not CommandStr (TNCChannel, true, 'C', U, I)) and (not Terminated) do Resync;
                      if (Terminated) then break;

                      if (AnsiStartsText ('*** SIMULT', U)) then begin

                        PRecConnect (Msg.lParam)^.Result := vf_notsimultaneous;
                        break;

                      end else if (AnsiStartsText ('CHANNEL NO', U)) then begin

                        if (assigned (FConnectionList[TNCChannel])) then begin
                          // Queue the job again together with its reference, then do not report here
                          Forwarded := PostThreadMessage (GetCurrentThreadId, msg_connect, Msg.wParam, Msg.lParam);
                          sleep (50);
                          break;
                        end;

                        PacketConnection := PRecConnect (Msg.lParam)^.PacketConnection;

                        SsidIterator := TSsidIterator.Create (PacketConnection.MyCall);

                        try

                          B := SsidIterator.Reset;

                          repeat

                            if (not B) then begin
                              DebOut (self, MethodName, 'Keine freie SSID gefunden.');
                              PRecConnect (Msg.lParam)^.Result := vf_nossid;
                              break;
                            end;

                            PacketConnection.MyCall := SsidIterator.Callsign;
                            DebOut (self, MethodName, 'Verwende MyCall ' + PacketConnection.MyCall);

                            while (not CommandStr (TNCChannel, true, 'I ' + PacketConnection.MyCall, U, Q)) and (not Terminated) do
                              Resync;
                            if (Terminated) then break;

                            if (Q > 0) or (U <> '') then DebOut (self, MethodName, 'MyCall-setzen fehlgeschlagen (' + U + ')');

                            I := PRecConnect (Msg.lParam)^.RadioChannel.Handle;
                            if (I >= 0) then S := Format ('%d:', [I]) else S := '';
                            S := S + PacketConnection.Path;
                            DebOut (self, MethodName, 'Connecte...: ' + S);

                            while (not CommandStr (TNCChannel, true, 'C' + S , U, Q)) and (not Terminated) do Resync;
                            if (Terminated) then break;

                            if (Q = 0) then begin
                              if (RecConnectAdopt (PRecConnect (Msg.lParam))) then begin
                                DebOut (self, MethodName, 'Connect erfolgreich.');
                                PacketConnection.Handle := TNCChannel;
                                ConnectionsCriticalSection.Enter;
                                try
                                  FConnectionList[TNCChannel] := PacketConnection;
                                finally
                                  ConnectionsCriticalSection.Leave;
                                end;
                                PRecConnect (Msg.lParam)^.Result := vf_ok;
                              end else begin
                                DebOut (self, MethodName, 'Connect erfolgreich, aber Verbinde hat schon aufgegeben - trenne.');
                                while (not CommandStr (TNCChannel, true, 'D', U, Q)) and (not Terminated) do Resync;
                              end;
                              break;
                            end else begin
                              if (AnsiStartsText ('STATION AL', U)) then begin
                                DebOut (self, MethodName, 'Station bereits verbunden...');
                                B := SsidIterator.Next;
                              end else if (AnsiStartsText ('*** SIMULT', U)) then begin
                                PRecConnect (Msg.lParam)^.Result := vf_notsimultaneous;
                                break;
                              end else begin
                                DebOut (self, MethodName, 'Connect fehlgeschlagen (' + U + ')');
                                if (RecConnectAdopt (PRecConnect (Msg.lParam))) then begin
                                  DebOut (self, MethodName, 'Verbindung.Getrennt... (7)');
                                  PacketConnection.Disconnected (dr_linkfailure);
                                end;
                                ConnectionsList.Lock;
                                try
                                  PacketConnection := nil;
                                finally
                                  ConnectionsList.UnLock;
                                end;
                                PRecConnect (Msg.lParam)^.Result := vf_deviceerror;
                                break;
                              end;
                            end;

                          until (Terminated);

                        finally

                          SsidIterator.free;

                        end;

                        break;

                      end;

                    end;

                    if (not Forwarded) then begin
                      PRecConnect (Msg.lParam)^.Event.SetEvent;
                      JobDone (msg_connect, Pointer (Msg.lParam));
                    end;

                  end;

                end;

              end;

              msg_disconnect: begin

                Debout (self, MethodName, 'msg_trennen empfangen.');

                assert ((Msg.wParam >= Low (FConnectionList)) and (Msg.wParam <= High (FConnectionList)));

                while (not CommandStr (Msg.wParam, true, 'D', U, Q)) and (not Terminated) do Resync;
                if (Terminated) then break;

                if (U <> '') then DebOut (self, MethodName, 'Disconnect fehlgeschlagen (' + U + ')');

              end;

              msg_uiframe: begin

                Debout (self, MethodName, 'msg_uiframe empfangen.');

                UiFrame := PRecUIFrame (Msg.lParam);

                // Release even on Terminated (break) or an exception
                try

                  assert (assigned (UIFrame));
                  assert (Length (UIFrame.Text) > 0);

                  if (UIFrame.Port >= 0) then V := Format ('%d:', [UIFrame.Port]) else V := '';
                  V := V + UIFrame.Dest;

                  DebOut (self, MethodName, V);

                  while (not CommandStr (0, true, 'I' + UIFrame.MyCall, U, I)) and (not Terminated) do Resync;
                  if (Terminated) then break;

                  while (not CommandStr (0, true, 'C' + V, U, I)) and (not Terminated) do Resync;
                  if (Terminated) then break;

                  while (not CommandStr (0, false, UIFrame.Text, U, I)) and (not Terminated) do Resync;
                  if (Terminated) then break;

                finally
                  JobDone (msg_uiframe, UIFrame);
                end;

              end;

              msg_pactorbreakin: begin

                Debout (self, MethodName, 'msg_pactorbreakin empfangen.');

                while (not CommandStr (Msg.wParam, true, '%I', U, I)) and (not Terminated) do Resync;
                if (Terminated) then break;

                if ((FMonitor and MonitorLocal) <> 0) then begin
                  ChannelList.Monitor ('[TNC ' + ParameterText + ': Pactor BreakIn]', U);
                end;

              end;

              msg_pactorchangeover: begin

                Debout (self, MethodName, 'msg_pactorchangeover empfangen.');

                while (not CommandStr (Msg.wParam, true, '%O', U, I)) and (not Terminated) do Resync;
                if (Terminated) then break;

                if ((FMonitor and MonitorLocal) <> 0) then begin
                  ChannelList.Monitor ('[TNC ' + ParameterText + ': Pactor ChangeOver]', U);
                end;

              end;

              else begin

                Debout (self, MethodName, 'unbekannte Message $%x empfangen.', [Msg.Message]);

              end;

            end;

            sleep (0);

            Inc (M);

          end;

        except

          on E: Exception do begin
            // Complete open jobs before the dialog blocks the thread: EstablishConnection
            // gets an error immediately, even for a job currently being processed.
            DiscardMessages;
            ShowUnhandledException (E, ClassName, '1');
            raise;
          end;

        end;

        Sleep (50);

      end;

      //////////////////////////////////////////////////////////////////////////

      PacketConnection := nil;

      DebOut (self, MethodName, 'RegKey = ' + FRegKey);

      // When Paxon ends, the connections stay up in the TNC and are saved; the next
      // start restores them. When only the device is stopped or reconfigured, nothing
      // restores them: disconnect them, otherwise they would stay in their channels and
      // the new device thread would take the links over as incoming connections.
      // Disconnected calls into the channel (SendMessage to the main thread), hence
      // outside ConnectionsCriticalSection.
      for N := 1 to FTncChannelCount do begin
        ConnectionsCriticalSection.Enter;
        try
          PacketConnection := FConnectionList[N];
          FConnectionList[N] := nil;
        finally
          ConnectionsCriticalSection.Leave;
        end;
        if (assigned (PacketConnection)) then begin
          try
            if (assigned (MainWindow)) and (MainWindow.IsShuttingDown) then begin
              PacketConnection.Save (FRegKey);
            end else begin
              if (CommOpened) then CommandStr (N, true, 'D', U, Q);
              PacketConnection.Disconnected (dr_normal);
            end;
            PacketConnection.Release;
          except
            on E: Exception do begin
              DebOut (self, MethodName, 'FEHLER beim Abbau der Verbindung: ' + E.Message);
            end;
          end;
          PacketConnection := nil;
        end;
      end;

      if (CommOpened) then begin

        DebOut (self, MethodName, 'TNC deinitialisieren...');

        GetTncDeinit (FThreadTncList);
        for N := 0 to FThreadTncList.Count - 1 do begin
          S := Trim (FThreadTncList[N]);
          if (S <> '') then begin
            DebOut (self, MethodName, 'DeInit ' + S);
            CommandStr (0, true, S, U, Q);
          end;
        end;

        CommandStr (0, true, 'MN', U, Q);
        CommandStr (0, true, 'Z3', U, Q);
        CommandStr (0, true, 'S0', U, Q);

        DebOut (self, MethodName, 'TNC in den Terminalmodus schalten...');

        T := #0#1#5'JHOST0';
        if (not CommWrite (T, 9, Cardinal (N))) then begin
          DebOut (self, MethodName, 'FEHLER beim Schalten in den Terminalmodus.');
        end;

      end;

      DebOut (self, MethodName, 'Schnittstelle schließen...');

      CommClose;

    end;

  except

    on E: Exception do begin
      DiscardMessages;
      // Abbruch nach einer Ausnahme: nicht mehr "bereit" melden, die Verbindungen
      // trennen und die Schnittstelle schließen. Sonst bleiben die Verbindungen in
      // ihren Kanälen stehen und die Schnittstelle bis zum Programmende belegt;
      // ein Neustart des Geräts scheiterte dann am eigenen, offenen Handle.
      SetStatus (gs_error, 'Abbruch nach Fehler');
      for N := Low (FConnectionList) to High (FConnectionList) do begin
        ConnectionsCriticalSection.Enter;
        try
          PacketConnection := FConnectionList[N];
          FConnectionList[N] := nil;
        finally
          ConnectionsCriticalSection.Leave;
        end;
        if (assigned (PacketConnection)) then begin
          try
            PacketConnection.Disconnected (dr_linkfailure);
            PacketConnection.Release;
          except
          end;
          PacketConnection := nil;
        end;
      end;
      try
        CommClose;
      except
      end;
      ShowUnhandledException (E, ClassName, '2');
      raise;
    end;

  end;

  DiscardMessages;

  DebOut (self, MethodName, 'end.');

end;


function   THostmodeDevice.GetTNCStatus (const TNCChannel: Integer; var TNCStatus: array of Integer): Boolean;
const
  MethodName = 'GetTNCStatus';

var
  L, K, Q, I: Integer;
  U: string;

begin

  result := false;

  while (not CommandStr (TNCChannel, true, 'L', U, I)) and (not Terminated) do Resync;

  if (Terminated) then Exit;

  for Q := Low (TNCStatus) to High (TNCStatus) do TNCStatus[Q] := 0;

  K := Low (TNCStatus);
  for Q := 1 to Length (U) do begin
    if (U[Q] = #32) then begin
      Inc (K);
      if (K > High (TNCStatus)) then exit;
    end else begin
      L := Ord (U[Q]) - Ord ('0');
      TNCStatus[K] := L + 10 * TNCStatus[K];
    end;
  end;

  result := true;

end;


function    THostmodeDevice.MonitorHeader (H: string): Boolean;
const
  MethodName = 'MonitorHeader';

var
  I: Integer;
  S: string;

begin

  // 1:fm DG1FAZ to DB0DAR-8 via DB0AIS ctl RR4-

  result := false;

  if (Length (H) >= 9) then begin

    FMonitorFrame.Sent := false;

    if (H[2] = ':') and (H[1] in ['0'..'9']) then begin
      FMonitorFrame.Port := ord (H[1]) - ord ('0');
    end else begin
      FMonitorFrame.Port := 0;
    end;

    FMonitorFrame.Device := No;

    I := pos ('fm ', H);
    delete (H, 1, I + 2);

    I := pos (' ', H);
    FMonitorFrame.Src := copy (H, 1, I - 1);
    delete (H, 1, I);

    I := pos ('to ', H);
    delete (H, 1, I + 2);

    I := pos (' ', H);
    FMonitorFrame.Dest := copy (H, 1, I - 1);
    delete (H, 1, I);

    I := pos ('via ', H);
    if (I > 0) then begin
      delete (H, 1, I + 3);
      I := pos (' ctl ', H);
      FMonitorFrame.Digis := copy (H, 1, I - 1);
      delete (H, 1, I);
    end else begin
      FMonitorFrame.Digis := '';
    end;

    I := pos ('ctl ', H);
    delete (H, 1, I + 3);

    if (Length (H) < 2) then begin
      exit;
    end;

    S := Copy (H, 1, 2);

    assert (Length (S) >= 1);

    FMonitorFrame.RXSeq := 0;
    FMonitorFrame.TXSeq := 0;

    if (S[1] = 'I') then begin
      FMonitorFrame.FrameType := FT_I;
      if (Length (H) >= 3) then begin
        FMonitorFrame.RXSeq := Ord (H[2]) - Ord ('0');
        FMonitorFrame.TXSeq := Ord (H[3]) - Ord ('0');
      end;
      delete (H, 1, 3);
    end else if (S = 'RR') then begin
      FMonitorFrame.FrameType := FT_RR;
      if (Length (H) >= 3) then begin
        FMonitorFrame.RXSeq := Ord (H[3]) - Ord ('0');
      end;
      delete (H, 1, 3);
    end else if (S = 'RN') then begin
      FMonitorFrame.FrameType := FT_RNR;
      delete (H, 1, 3);
    end else if (S = 'RE') then begin
      FMonitorFrame.FrameType := FT_REJ;
      if (Length (H) >= 4) then begin
        FMonitorFrame.RXSeq := Ord (H[4]) - Ord ('0');
      end;
      delete (H, 1, 4);
    end else if (S = 'SA') then begin
      FMonitorFrame.FrameType := FT_SABM;
      delete (H, 1, 4);
    end else if (S = 'DI') then begin
      FMonitorFrame.FrameType := FT_DISC;
      delete (H, 1, 4);
    end else if (S = 'DM') then begin
      FMonitorFrame.FrameType := FT_DM;
      delete (H, 1, 2);
    end else if (S = 'UA') then begin
      FMonitorFrame.FrameType := FT_UA;
      delete (H, 1, 2);
    end else if (S = 'FR') then begin
      FMonitorFrame.FrameType := FT_FRMR;
      delete (H, 1, 4);
    end else if (S = 'UI') then begin
      FMonitorFrame.FrameType := FT_UI;
      delete (H, 1, 2);
    end else begin
      exit;
    end;

    if (Length (H) >= 1) then begin
      case H[1] of
        '+': begin
          FMonitorFrame.Command := True; FMonitorFrame.PollFinal := True;
        end;
        '-': begin
          FMonitorFrame.Command := False; FMonitorFrame.PollFinal := True;
        end;
        '^': begin
          FMonitorFrame.Command := True; FMonitorFrame.PollFinal := False;
        end;
        'v': begin
          FMonitorFrame.Command := False; FMonitorFrame.PollFinal := False;
        end;
      end;
      Delete (H, 1, 1);
    end else begin
      exit;
    end;

    I := Pos ('pid ', H);
    if (I > 0) then begin
      Delete (H, 1, I + 3);
      FMonitorFrame.PID := StrToIntDef ('$' + Copy (H, 1, 2), 0);
    end else begin
      FMonitorFrame.PID := 0;
    end;

    I := Pos ('[DAMA]', H);
    FMonitorFrame.Dama := (I > 0);

    FMonitorFrame.TxDel := 0;

    result := true;

  end;

end;


procedure   THostmodeDevice.MonitorBody (S: string);
begin
  with FMonitorFrame do begin
    Text := S;
  end;
  ChannelList.Monitor (FMonitorFrame);
end;


// Command
// 0  Success, no data
// 1  Success, message follows      (null-terminated)
// 2  Error, message follows        (null-terminated)
// 3  Connection status             (null-terminated)
// 4  Monitor header, no data       (null-terminated)
// 5  Monitor header, data follows  (null-terminated)
// 6  Monitor mode data             (byte-count)
// 7  Data from AX.25 connection    (byte-count)


function    THostmodeDevice.CommandStr (ChannelRef: Byte; CommandStr: Boolean; DataText: string; var ResponseStr: string;
                                        var ResponseValue: Integer): Boolean;
const
  MethodName = 'CommandStr';

  procedure DebOutCommand (P1: String; S: String);
  begin
    DebOut (self, MethodName, 'FEHLER: %s: %s [%s]', [P1, S, Trim (GetLastErrorText)]);
  end;

var
  T: array[0..2] of Char;
  L, N, I, J, K: Integer;
  C: Char;
  A, B: Byte;
  HasError: Boolean;

begin

  L := Length (DataText);

  assert (L <= 256);

  if (L <= 0) then begin

    ResponseStr := '';
    ResponseValue := 0;
    Result := true;

  end else begin

    HasError := false;

    ResponseValue := -1;
    ResponseStr := '';

    T[0] := Char (ChannelRef);
    if (CommandStr) then T[1] := #1 else T[1] := #0;
    T[2] := Char (L - 1);

    N := 0;
    if (not CommWrite (T, 3, Cardinal (N))) then begin                       // #1
      DebOutCommand ('1a', '');
      HasError := true;
    end else if (N <> 3) then begin
      DebOutCommand ('1b', '');
      HasError := true;
    end;

    N := 0;
    if (not CommWrite (DataText[1], L, Cardinal (N))) then begin                // #2
      DebOutCommand ('2a', '');
      HasError := true;
    end else if (L <> N) then begin
      DebOutCommand ('2b', '');
      HasError := true;
    end;

    I := 0;
    if (not CommRead (C, 1, Cardinal (I))) then begin                        // #3
      DebOutCommand ('3a', '');
      HasError := true;
    end else if (I <> 1) then begin
      DebOutCommand ('3b', '');
      HasError := true;
    end else if (Byte (C) <> ChannelRef) then begin
      // The response belongs to another channel: an earlier response came after the
      // timeout, and every further command would read the response of the previous
      // one (data of one channel would go to another connection). The caller resyncs.
      DebOutCommand ('3c', Format ('Antwort von Kanal %d statt %d', [Byte (C), ChannelRef]));
      HasError := true;
    end else begin

      B := Byte(-1);

      if (not CommRead (B, 1, Cardinal (I))) then begin                      // #4
        DebOutCommand ('4a', '');
        HasError := true;
      end else if (I <> 1) then begin
        DebOutCommand ('4b', '');
        HasError := true;
      end else begin

        ResponseValue := B;

        if (ResponseValue >= 1) and (ResponseValue <= 5) then begin // null-terminated data

          SetLength (ResponseStr, 256);
          K := 1;
          repeat
            J := 0;
            if (not CommRead (ResponseStr[K], 1, Cardinal (J))) then begin       // #5
              DebOutCommand ('5a', '');
              HasError := true;
            end else if (J <> 1) then begin
              DebOutCommand ('5b', '');
              HasError := true;
            end else begin
              if (ResponseStr[K] = #0) then break;
              Inc (K);
              if (K > 256) then begin
                K := 257;
                DebOutCommand ('5c', 'Mehr als 256 Bytes gelesen');
                HasError := true;
              end;
            end;
          until (HasError);
          SetLength (ResponseStr, K - 1);

        end else if (ResponseValue >= 6) and (ResponseValue <= 7) then begin // length + data

          J := 0;
          if (not CommRead (A, 1, Cardinal (J))) then begin                  // #6
            DebOutCommand ('6a', '');
            HasError := true;
          end else if (J <> 1) then begin
            DebOutCommand ('6b', '');
            HasError := true;
          end else begin
            SetLength (ResponseStr, A + 1);
            K := 0;
            if (not CommRead (ResponseStr[1], A + 1, Cardinal (K))) then begin   // #7
              DebOutCommand ('7a', '');
              HasError := true;
            end else if (K <> A + 1) then begin
              SetLength (ResponseStr, K);
              DebOutCommand ('7b', Format ('%d <> %d', [K, A + 1]));
              HasError := true;
            end;
          end;

        end else if (ResponseValue <> 0) then begin

          DebOutCommand ('8', 'Falsches Byte empfangen');
          HasError := true;

        end;

      end;
    end;

    Result := not HasError;

  end;

end;


function    THostmodeDevice.IsInHostmode: Boolean;
var
  L, I, N: Integer;
  C: Char;
  S: array[0..100] of Char;

begin

  Result := false;

  S := #1#1#1#1#1;
  L := StrLen(S);

  if (CommWrite (S, L, DWord (N))) and (L = N) then begin

    I := 0;
    while true do begin
      if (Terminated) then exit;
      if (not CommRead (C, 1, DWord (N))) then N := 0;
      if (N <> 1) then break;
      if (C = #1) then begin
        I := 1;
      end else if (C = #2) and (I = 1) then begin
        I := 2;
        break;
      end;
    end;
    if (I = 2) then begin
      repeat;
        if (Terminated) then exit;
        if (not CommRead (C, 1, DWord (N))) then N := 0;
        if (N <> 1) then break;
      until C = #0;
      Result := true;
    end;

  end;

end;


function THostmodeDevice.SwitchToHostmode: Boolean;
var
  L, N, I: Integer;
  T: string;
  B: Boolean;
begin
  result := IsInHostmode;
  if (not result) then begin
    for I := 2 downto 0 do begin
      if (Terminated) then break;
      T := #$11#$18#$1B'JHOST1'#$0D;
      L := Length (T);
      N := -1;
      B := CommWrite (T[1], L, DWord (N));
      if (B = false) or (L <> N) then begin
        if (N = 0) then begin
          result := false;
        end;
      end else begin
        result := IsInHostmode;
        if (result) then begin
          break;
        end else begin
          T := #13;
          L := Length (T);
          N := -1;
          CommWrite (T[1], L, DWord (N));
          Sleep (100);
        end;
      end;
    end;
  end;
  if (result) then FullCheckCount := -1;
end;


function    THostmodeDevice.Resync: Boolean;
const
  MethodName = 'Resync';

resourcestring
  SStatusPrefix = 'Resynchronisierung: ';
  SStart = 'Start';
  SReceiving = 'Empfange';
  SSwitchingToHostmode = 'Schalte in Hostmode';

var
  N, I: Integer;
  C: Char;

begin

  DebOut (self, MethodName, 'Start...');

  IncResyncCount;

  SetTimeouts (true);

  while (not Terminated) do begin

    SetStatus (gs_init, SStatusPrefix + SStart);

    Sleep (200);
    CommPurge;

    for N := 0 to 263 do begin
      if (Terminated) then break;
      SetStatus (gs_init, SStatusPrefix + IntToStr (N));
      C := #1;
      if (CommWrite (C, 1, DWord (I))) and (I = 1) then begin
        if (CommRead (C, 1, DWord (I))) and (I = 1) then begin
          SetStatus (gs_init, SStatusPrefix + SReceiving);
          Sleep (100);
          break;
        end;
      end else begin
        DebOut (self, MethodName, 'ERROR: CommWrite');
      end;
    end;

    if (not Terminated) then begin
      SetStatus (gs_init, SStatusPrefix + SSwitchingToHostmode);
      if (SwitchToHostmode) then break;
    end;

  end;

  if (Terminated) then begin
    Result := false;
  end else begin
    SetTimeouts (false);
    SetStatusReady;
    Result := true;
  end;

  DebOut (self, MethodName, 'Ende.');

end;


function    THostmodeDevice.EstablishConnection (aRadioChannel: IRadioChannel; var aCall: String; var aMyCall: String;
                                                 aChannelObj: IChannel; var Connection: IConnection): TConnectError;
const
  MethodName = 'EstablishConnection';

var
  PacketConnection: IConnection;
  RecConnect: PRecConnect;
  ExpiryDate: Cardinal;

begin

  Result := vf_unknown;

  ConnectionsList.Lock;
  try

    PacketConnection := TConnection.Create (self);

    assert (assigned (PacketConnection));

    with PacketConnection do begin
      Path := aCall;
      RealPath := aCall;
      MyCall := aMyCall;
      Outgoing := true;
    end;

  finally
    ConnectionsList.UnLock;
  end;

  assert (assigned (aRadioChannel));

  try

    // Job on the heap so that the device thread can still access it safely even after the
    // waiting time has expired (see RecConnectRelease).
    New (RecConnect);
    RecConnect.RefCount := 2;
    RecConnect.AccessLock := TCriticalSection.Create;
    RecConnect.IsExpired := false;
    RecConnect.Adopted := false;
    RecConnect.Event := TSimpleEvent.create;
    RecConnect.RadioChannel := aRadioChannel;
    RecConnect.PacketConnection := PacketConnection;
    RecConnect.Result := vf_unknown;

    try

      Screen.Cursor := crHourglass;

      ExpiryDate := GetTickCount + 8000;

      Debout (self, MethodName, 'Sende msg_connect...');
      if (not ThreadMessage (msg_connect, Integer(ExpiryDate), Integer(RecConnect))) then begin
        Debout (self, MethodName, 'msg_connect nicht zugestellt.');
        RecConnectRelease (RecConnect); // the message's reference
        ExpiryDate := GetTickCount;
      end;
      Debout (self, MethodName, 'Warte auf Event...');

      while (true) do begin

        case RecConnect.Event.WaitFor (50) of

          wrSignaled: begin
            DebOut (self, MethodName, 'Event: signaled');
            Result := RecConnect.Result;
            if (Result = vf_ok) then begin
              aCall := PacketConnection.Call;
              aMyCall := PacketConnection.MyCall;
              PacketConnection.ChannelRef := aChannelObj as IChannelForConnection;
            end else begin
              ConnectionsList.Lock;
              try
                PacketConnection.Release;
                PacketConnection := nil;
              finally
                ConnectionsList.UnLock;
              end;
            end;
            break;
          end;

          wrTimeout: begin
            // If the device thread has already adopted the job, the event will arrive shortly.
            // Vorzeichenbehafteter Abstand statt ">": übersteht den Überlauf von GetTickCount
            if (Integer (GetTickCount - ExpiryDate) > 0) and (RecConnectGiveUp (RecConnect)) then begin
              DebOut (self, MethodName, 'Event: Timeout');
              Result := vf_deviceTimeout;
              ConnectionsList.Lock;
              try
                PacketConnection.Release;
                PacketConnection := nil;
              finally
                ConnectionsList.UnLock;
              end;
              break;
            end else if (Integer (GetTickCount - ExpiryDate) > 0) and
                        ((not assigned (FThread)) or (Integer (GetTickCount - ExpiryDate) > 30000)) then begin
              // Adopted, but no event: the device thread was terminated between adoption and
              // SetEvent (exception, DeInit) - do not wait forever. After
              // adoption it only needs a short time anyway, so the hard deadline suffices in other cases too.
              // The message's reference is released by DiscardMessages or DeInit,
              // our own reference by the finally.
              DebOut (self, MethodName, 'Event: Geräte-Thread antwortet nicht');
              Result := vf_deviceerror;
              ConnectionsList.Lock;
              try
                PacketConnection.Release;
                PacketConnection := nil;
              finally
                ConnectionsList.UnLock;
              end;
              break;
            end else begin
              Forms.Application.ProcessMessages;
            end;
          end;

          wrAbandoned: begin
            DebOut (self, MethodName, 'Event: abandoned');
            PacketConnection.Release;
            PacketConnection := nil;
            break;
          end;

          wrError: begin
            DebOut (self, MethodName, 'Event: error');
            PacketConnection.Release;
            PacketConnection := nil;
            break;
          end;

        end;

      end;

    finally

      RecConnectRelease (RecConnect);

    end;

  finally

    Screen.Cursor := crDefault;

  end;

  Connection := PacketConnection;

end;


function    THostmodeDevice.RadioChannels (var aRadioChannels: array of IRadioChannel): Integer;
var
  N: Integer;
begin
  assert (Low (FRadioChannel) = 0);
  result := 0;
  // Unter der Sperre kopieren: Der Gerätethread setzt FRadioChannel bei der Initialisierung neu.
  CriticalSection.Enter;
  try
    for N := Low (FRadioChannel) to High (FRadioChannel) do begin
      if (assigned (FRadioChannel[N])) then begin
        aRadioChannels[result] := FRadioChannel[N];
        Inc (Result);
      end;
    end;
  finally
    CriticalSection.Leave;
  end;
end;


function    THostmodeDevice.KillPending (TNCChannel: Integer): Boolean;
begin
  result := false;
  if (TNCChannel < Low (FKillPending)) or (TNCChannel > High (FKillPending)) then exit;
  ConnectionsCriticalSection.Enter;
  try
    result := FKillPending[TNCChannel];
  finally
    ConnectionsCriticalSection.Leave;
  end;
end;


procedure   THostmodeDevice.SetKillPending (TNCChannel: Integer; Value: Boolean);
begin
  if (TNCChannel < Low (FKillPending)) or (TNCChannel > High (FKillPending)) then exit;
  ConnectionsCriticalSection.Enter;
  try
    FKillPending[TNCChannel] := Value;
  finally
    ConnectionsCriticalSection.Leave;
  end;
end;


procedure   THostmodeDevice.LockParam;
begin
  FParamCriticalSection.Enter;
end;


procedure   THostmodeDevice.UnlockParam;
begin
  FParamCriticalSection.Leave;
end;


procedure   THostmodeDevice.ReplaceParam (aNewParam: THostmodeDeviceParameter);
var
  Old: THostmodeDeviceParameter;
begin
  LockParam;
  try
    Old := FParam;
    FParam := aNewParam;
  finally
    UnlockParam;
  end;
  Old.free;
end;


procedure   THostmodeDevice.GetTncInit (L: TStrings);
begin
  LockParam;
  try
    L.Assign (FParam.TncInit);
  finally
    UnlockParam;
  end;
end;


procedure   THostmodeDevice.GetTncDeinit (L: TStrings);
begin
  LockParam;
  try
    L.Assign (FParam.TncDeinit);
  finally
    UnlockParam;
  end;
end;


function    THostmodeDevice.ParamDeviceID: Integer;
begin
  LockParam;
  try
    result := FParam.DeviceID;
  finally
    UnlockParam;
  end;
end;


procedure   THostmodeDevice.TerminateConnection (aConnectionObj: IConnection);
const
  MethodName = 'TerminateConnection';

var
  H: Integer;

begin

  DebOut (self, MethodName, 'begin...');

  if (assigned (FThread)) then begin

    DebOut (self, MethodName, 'assigned (FThread)');

    case aConnectionObj.DiscLevel of

      dl_end: begin
        ThreadMessage (msg_disconnect, aConnectionObj.Handle, 0);
        aConnectionObj.DiscLevelDone;
      end;

      dl_cancel: begin
        ThreadMessage (msg_disconnect, aConnectionObj.Handle, 0);
        aConnectionObj.DiscLevelDone;
      end;

      dl_kill: begin

        ThreadMessage (msg_disconnect, aConnectionObj.Handle, 0);

        aConnectionObj.DiscLevelDone;
        DebOut (self, MethodName, 'Verbindung.Getrennt... (8)');
        aConnectionObj.Disconnected (dr_normal);

        // The device thread may have torn the connection down meanwhile (the TNC
        // reported the disconnect) and the slot may hold a new connection already.
        ConnectionsCriticalSection.Enter;
        try
          H := aConnectionObj.Handle;
          assert ((H >= Low (FConnectionList)) and (H <= High (FConnectionList)));
          if (FConnectionList[H] = aConnectionObj) then begin
            FConnectionList[H] := nil;
            // The 'D' goes out only with msg_disconnect; until the TNC reports the link
            // gone, polling must not take it over as a new incoming connection.
            FKillPending[H] := true;
          end;
        finally
          ConnectionsCriticalSection.Leave;
        end;

        ConnectionsList.Lock;
        try
          aConnectionObj.Release;
          aConnectionObj := nil;
        finally
          ConnectionsList.Unlock;
        end;

      end;

    end;

  end else begin

    DebOut (self, MethodName, 'not assigned (FThread)');

    aConnectionObj.DiscLevelDone;
    DebOut (self, MethodName, 'Verbindung.Getrennt... (9)');
    aConnectionObj.Disconnected (dr_normal);

    ConnectionsList.Lock;
    try

      ConnectionsCriticalSection.Enter;
      try
        H := aConnectionObj.Handle;
        if (FConnectionList[H] = aConnectionObj) then FConnectionList[H] := nil;
      finally
        ConnectionsCriticalSection.Leave;
      end;

      aConnectionObj.Release;
      aConnectionObj := nil;

    finally
      ConnectionsList.Unlock;
    end;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   THostmodeDevice.PactorBreakIn (aConnectionObj: IConnection);
begin
  ThreadMessage (msg_pactorbreakin, aConnectionObj.Handle, 0);
end;


procedure   THostmodeDevice.PactorChangeOver (aConnectionObj: IConnection);
begin
  ThreadMessage (msg_pactorchangeover, aConnectionObj.Handle, 0);
end;


function    THostmodeDevice.ThreadMessage (aMsg: Cardinal; aWParam, aLParam: Integer): Boolean;
var
  T: TDeviceThread;
begin
  // FThread becomes nil when the device thread ends (e.g. the port cannot be opened).
  // When called from the main thread, T stays valid until the end of this method: the thread
  // frees itself only after the Synchronize of its OnTerminate.
  // Under the lock and only while the thread accepts messages: anything posted later
  // would never be released after the queue has been emptied at the end of Run.
  MessagesCriticalSection.Enter;
  try
    T := FThread;
    if (assigned (T)) and (not FMessagesClosed) then begin
      // Register heap data until the device thread is done with it (see TRecConnect)
      if (aMsg = msg_connect) then FOpenConnects.Add (Pointer (aLParam));
      if (aMsg = msg_uiframe) then FOpenUIFrames.Add (Pointer (aLParam));
      Result := PostThreadMessage (T.ThreadId, aMsg, aWParam, aLParam);
      if (not Result) then begin
        if (aMsg = msg_connect) then FOpenConnects.Remove (Pointer (aLParam));
        if (aMsg = msg_uiframe) then FOpenUIFrames.Remove (Pointer (aLParam));
      end;
    end else begin
      Result := false;
    end;
  finally
    MessagesCriticalSection.Leave;
  end;
end;


// In the device thread at the end of Run, even after an exception: accept no more messages
// and complete all jobs still registered - those in the thread queue and one whose
// processing was aborted by an exception. A second call finds nothing left.
procedure   THostmodeDevice.DiscardMessages;
var
  Msg: TMsg;
  ConnectRequests, UIFrames: TList;
begin
  MessagesCriticalSection.Enter;
  try
    FMessagesClosed := true;
    ConnectRequests := FOpenConnects;
    UIFrames := FOpenUIFrames;
    FOpenConnects := TList.Create;
    FOpenUIFrames := TList.Create;
  finally
    MessagesCriticalSection.Leave;
  end;
  FinishJobs (ConnectRequests, UIFrames);
  // Whatever is still in the queue only refers to completed jobs.
  while (PeekMessage (Msg, 0, msg_connect, msg_pactorchangeover, PM_REMOVE)) do ;
end;


// In the device thread after processing msg_connect or msg_uiframe: unregister and release the
// message's reference. No longer registered means: already completed.
procedure   THostmodeDevice.JobDone (aMsg: Cardinal; P: Pointer);
var
  WasEntered: Boolean;
begin
  MessagesCriticalSection.Enter;
  try
    if (aMsg = msg_connect) then begin
      WasEntered := (FOpenConnects.Remove (P) >= 0);
    end else begin
      WasEntered := (FOpenUIFrames.Remove (P) >= 0);
    end;
  finally
    MessagesCriticalSection.Leave;
  end;
  if (WasEntered) then begin
    if (aMsg = msg_connect) then begin
      RecConnectRelease (PRecConnect (P));
    end else begin
      Dispose (PRecUIFrame (P));
    end;
  end;
end;


// If TDevice.DeInit aborts the device thread with TerminateThread, DiscardMessages no
// longer runs, and the thread's queue vanishes together with the messages in it. The jobs
// are still registered, though, and are completed here once the thread is certainly no longer running.
// After a normal end, DiscardMessages has already emptied the lists.
procedure   THostmodeDevice.DeInit;
const
  MethodName = 'DeInit';

var
  T: TDeviceThread;
  H: THandle;
  L: Cardinal;
  IsTerminated: Boolean;
  ConnectRequests, UIFrames: TList;

begin

  // Own handle, because the thread object's handle is closed by its destructor (FreeOnTerminate).
  // In the main thread, T stays valid up to here (see ThreadMessage).
  H := 0;
  T := FThread;
  if (assigned (T)) then begin
    if (not DuplicateHandle (GetCurrentProcess, T.Handle, GetCurrentProcess, @H, SYNCHRONIZE, false, 0)) then H := 0;
  end;

  inherited;

  if (H = 0) then exit;

  // Even a thread that ends normally still waits for the Synchronize of its OnTerminate.
  L := GetTickCount;
  repeat
    IsTerminated := (WaitForSingleObject (H, 50) = WAIT_OBJECT_0);
    if (IsTerminated) then break;
    if (GetCurrentThreadID = MainThreadID) then CheckSynchronize;
  until (GetTickCount - L > 2000);
  CloseHandle (H);

  if (not IsTerminated) then begin
    DebOut (self, MethodName, 'Geräte-Thread läuft noch - offene Aufträge bleiben liegen.');
    exit;
  end;

  // An aborted thread may have died inside MessagesCriticalSection: it
  // would stay locked forever and the lists might be half modified. In that case do not wait and
  // free nothing, but replace the lock and the lists and leave the old ones behind (a leak instead of
  // a hang or double free). Apart from the main thread, nobody accesses them any more.
  if (TryEnterCriticalSection (TCriticalSectionAccess (MessagesCriticalSection).FSection)) then begin
    try
      FMessagesClosed := true;
      ConnectRequests := FOpenConnects;
      UIFrames := FOpenUIFrames;
      FOpenConnects := TList.Create;
      FOpenUIFrames := TList.Create;
    finally
      MessagesCriticalSection.Leave;
    end;
    FinishJobs (ConnectRequests, UIFrames);
  end else begin
    DebOut (self, MethodName, 'Sperre vom abgebrochenen Geräte-Thread belegt - offene Aufträge bleiben liegen.');
    MessagesCriticalSection := TCriticalSection.Create;
    FMessagesClosed := true;
    FOpenConnects := TList.Create;
    FOpenUIFrames := TList.Create;
  end;

end;


function    THostmodeDevice.GetCommandC (const TNCChannel: Integer; var Call: string): Boolean;
var
  I: Integer;
  S: string;

begin

  // Response of command 'C' without parameters
  // <Port>:<Call> via <Digis>

  result := false;
  Call := '';

  while (not CommandStr (TNCChannel, true, 'C', S, I)) and (not Terminated) do Resync;
  if (Terminated) then exit;

  // Only code 1 is the connection path; anything else is an error message.
  if (I <> 1) then exit;

  I := Pos (':', S);
  if (I >= 1) and (I <= 8) then Delete (S, 1, I);
  if (Length (S) >= 1) and (S[1] = ' ') then Delete (S, 1, 1);

  if (not AnsiStartsText ('CHANNEL NO', S)) and (not AnsiStartsText ('***', S)) then begin

    I := Pos (' via ', S);
    if (I > 0) then Delete (S, I, 4);

    result := true;
    Call := S;

  end;

end;


procedure   THostmodeDevice.OwnCallsignsNotify;
const
  MethodName = 'OwnCallsignsNotify';
begin
  DebOut (self, MethodName, 'begin...');
  OwnCallsignsChanged;
  if (assigned (FThread)) then begin
    ThreadMessage (msg_owncallsigns, 0, 0);
  end;
  DebOut (self, MethodName, 'end.');
end;


procedure   THostmodeDevice.OwnCallsignsChanged;
const
  MethodName = 'OwnCallsignsChanged';

var
  B: Boolean;
  K, Q: Integer;
  S: string;

begin

  DebOut (self, MethodName, 'begin...');

  MyCalls.BeginRead;

  try

    OwnCallsignsCriticalSection.Enter;

    try

      FOwnCallsigns.Clear;

      if (MyCalls.Count > 0) then begin

        Q := 0;
        K := 0;
        B := true;

        while true do begin
          if (Q < MyCalls[K].SSIDCount) then begin
            B := true;
            S := MyCalls[K].CallWithSSID[Q];
            DebOut (self, MethodName, S);
            FOwnCallsigns.Add (S);
          end;
          Inc (K);
          if (K >= MyCalls.Count) then begin
            K := 0;
            if (not B) then break;
            B := false;
            Inc (Q);
          end;
        end;

      end;

    finally

      OwnCallsignsCriticalSection.Leave;

    end;

  finally

    MyCalls.EndRead;

  end;

  DebOut (self, MethodName, 'end.');

end;


function   THostmodeDevice.SetOwnCallsigns (AllChannels: Boolean): Integer;
const
  MethodName = 'SetOwnCallsigns';

var
  I, K, N, C, R: Integer;
  S, M: string;
  E: Boolean;
  L: TStringList;

begin

  DebOut (self, MethodName, 'begin...');

  // Work on a copy: the lock must not be held across CommandStr/Resync. There,
  // SetStatus reports to the main thread via Synchronize, which in turn may wait for the lock in
  // OwnCallsignsChanged (deadlock).
  L := TStringList.Create;

  try

    OwnCallsignsCriticalSection.Enter;
    try
      L.Assign (FOwnCallsigns);
    finally
      OwnCallsignsCriticalSection.Leave;
    end;

    C := L.Count;
    if (C > 0) then begin

      if (AllChannels) then K := 0 else K := 1;
      E := true;

      repeat

        N := 0;
        while (N <= (C - 1)) do begin

          S := L[N];

          while E do begin

            // channel number is a byte, and 255 is the poll channel ('G'): the
            // channel list of 'G255' holds channel + 1, which must fit into a byte
            if (K > 254) then begin
              K := 254;
              E := false;
              break;
            end;

            while (not CommandStr (K, true, 'I' + S, M, I)) and (not Terminated) do Resync;
            if (Terminated) then break;

            if (I = 0) then begin
              DebOut (self, MethodName, Format ('Kanal %2.2d: %s', [K, S]));
              Inc (K);
              break;
            end else begin
              DebOut (self, MethodName, Format ('Kanal %2.2d: %s', [K, M]));
              if (M = 'INVALID CHANNEL NUMBER') then begin
                Dec (K);
                E := false;
                break;
              end else begin
                Inc (K);
              end;
            end;
          end;

          if (Terminated) then break;

          // no more channels: done (without this, endless loop if K stays <= 1)
          if (not E) then break;

          if (K > 1) then inc (N);

        end;

        if (Terminated) then break;

      until (not AllChannels) or (not E);

      if (PactorChannel >= 1) then begin
        S := L[0];
        while (not CommandStr (PactorChannel, true, 'I' + S, M, I)) and (not Terminated) do Resync;
      end;

    end else begin

      if (AllChannels) then begin

        K := 1;

        while (K < 256) do begin

          while (not CommandStr (K, true, 'I', M, I)) and (not Terminated) do Resync;
          if (Terminated) then break;

          if (I = 2) then begin
            DebOut (self, MethodName, Format ('Kanal %2.2d: %s', [K, M]));
            if (M = 'INVALID CHANNEL NUMBER') then begin
              Dec (K);
              break;
            end;
          end;

          Inc (K);

        end;

        if (K > 254) then K := 254;

      end else begin

        K := 0;

      end;

    end;

    if (AllChannels) then begin
      if (L.Count <= 0) then begin
        I := 0;
      end else begin
        I := K;
      end;
      DebOut (self, MethodName, 'Setze Y %d', [I]);
      while (not CommandStr (0, true, 'Y' + IntToStr (I), S, R)) and (not Terminated) do Resync;
      if (Terminated) then begin
        result := 0;
      end else begin
        result := K;
      end;
    end else begin
      result := 0;
    end;

  finally

    L.Free;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   THostmodeDevice.SetMonitor;
const
  MethodName = 'SetMonitor';
var
  S, U: string;
  I: Integer;
begin
  if ((FMonitor and MonitorEnabled) <> 0)  then begin
    if (not CommandStr (0, true, 'M-', U, I)) then Resync;
    S := 'M';
    if ((FMonitor and MonitorInformation) <> 0) then S := S + 'I';
    if ((FMonitor and MonitorUnproto) <> 0) then S := S + 'U';
    if ((FMonitor and MonitorStatus) <> 0) then S := S + 'S';
  end else begin
    S := 'MN';
  end;
  DebOut (self, MethodName, S);
  if (not CommandStr (0, true, S, U, I)) then Resync;
end;


function    THostmodeDevice.GetResyncCount: Integer;
begin
  FResyncCountCriticalSection.Enter;
  try
    result := FResyncCount;
  finally
    FResyncCountCriticalSection.Leave;
  end;
end;


procedure   THostmodeDevice.IncResyncCount;
begin
  FResyncCountCriticalSection.Enter;
  try
    Inc (FResyncCount);
  finally
    FResyncCountCriticalSection.Leave;
  end;
end;


procedure   THostmodeDevice.SetStatusReady;
resourcestring
  SErrorCount = '%d Fehler';
var
  I: Integer;
  S: String;
begin
  I := ResyncCount;
  if (I <= 0) then S := '' else S := Format (SErrorCount, [I]);
  SetStatus (gs_ready, S);
end;


function    THostmodeDevice.GetConnectPath (S: String): String;
const
  MethodName = 'GetConnectPath';
var
  I: Integer;
begin
  Debout (self, MethodName, 'Eingabe: ' + S);
  if (Length (S) >= 3) and (S[2] = ':') then Delete (S, 1, 2);
  I := Pos (' -', S);
  if (I >= 1) then Delete (S, I, MaxInt);
  I := Pos (' via ', S);
  if (I >= 1) then Delete (S, I, 4);
  result := Trim (S);
  Debout (self, MethodName, 'Ausgabe: ' + Result);
end;


function    THostmodeDevice.SendUI (aRadioChannel: IRadioChannel; aDestination, aMyCall, aText: String): Boolean;
var
  P: PRecUIFrame;
begin
  New (P);
  P.Mycall := aMyCall;
  P.Dest := aDestination;
  P.Text := aText;
  P.Port := aRadioChannel.Handle;
  result := ThreadMessage (msg_uiframe, 0, Integer(P));
  if (not result) then Dispose (P);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TOwnCallsignsSubscriber.Create (aHostmodeDevice: THostmodeDevice);
begin
  inherited Create;
  FHostmodeDevice := aHostmodeDevice;
end;


destructor  TOwnCallsignsSubscriber.Destroy;
begin
  FHostmodeDevice := nil;
  inherited;
end;


procedure   TOwnCallsignsSubscriber.Notify (P: Pointer);
begin
  if assigned (FHostmodeDevice) then FHostmodeDevice.OwnCallsignsNotify;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

