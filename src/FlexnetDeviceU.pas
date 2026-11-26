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


unit FlexnetDeviceU;


interface


uses
  Classes, Windows, SysUtils, Controls,
  GlobalU, InterfacesU, DeviceU, FlexnetDeviceSettingsU, ChannelU,
  ChannelsU, QueueU, SyncObjs;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TFlexnetDevice = class (TDevice)
  private

    FRadioChannel: Array[0..16] of IRadioChannel;
    FConnectionList: TInterfaceList;
    FDigi: Boolean;
    CriticalSection: TCriticalSection;
    AxInitOk: Boolean;

    EventQSODATA: THandle;
    EventQSOSTATE: THandle;
    EventNODEFRAME: THandle;
    EventSABM: THandle;
    EventUI: THandle;
    EventCHANNELS: THandle;

    procedure   SaveConnections;
    procedure   CheckRestored;
    procedure   DropRestored;
    procedure   InitRadioChannels;

  protected

    procedure   Run; override;

  public

    class function Name: String; override;
    constructor Create; override;
    destructor  Destroy; override;
    function    SettingsDialog (AOwner: TComponent): Integer; override;
    procedure   CancelSettings; override;
    procedure   ApplySettings; override;
    procedure   Init; override;
    procedure   Save; override;
    function    RadioChannels (var aRadioChannels: Array of IRadioChannel): Integer; override;
    function    EstablishConnection (aRadioChannel: IRadioChannel; var aCall: String; var aMyCall: String; aChannelObj: IChannel;
                                     var Connection: IConnection): TConnectError; override;
    procedure   TerminateConnection (aConnectionObj: IConnection); override;
    procedure   Restore; override;
    function    SendUI  (aRadioChannel: IRadioChannel; aDestination, aMyCall, aText: String): Boolean; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, MainU, FlexnetApiU, RadioChannelU, ConnectionU, Registry, Forms,
  ConfigU, SsidIteratorU, MyCallsU, MyCallU, UnhandledExceptionU, ConnectionsListU;


type
  TMonitorThread = class (TThread)
  private
    procedure   SetMonitor;
    procedure   ClearMonitor;
  public
    FlexNetDevice: TFlexnetDevice;
    // Copied at the start: a monitor thread that does not end in time is left
    // running (see Run) and must not touch the device object any more.
    DeviceNo: Integer;
    procedure   Execute; override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


class function TFlexnetDevice.Name: String;
begin
  Result := 'PC/FlexNet';
end;


constructor TFlexnetDevice.Create;
const
  MethodName = 'Create';
begin
  DebOut (self, MethodName, 'begin...');
  inherited;
  CriticalSection := TCriticalSection.create;
  FConnectionList := TInterfaceList.Create;
  AxInitOk := false;
  DebOut (self, MethodName, 'end.');
end;


destructor  TFlexnetDevice.Destroy;
const
  MethodName = 'Destroy';
var
  N: Integer;
begin
  DebOut (self, MethodName, 'begin...');
  if (assigned (FConnectionList)) then begin
    for N := (FConnectionList.Count - 1) downto 0 do begin
      (FConnectionList.items[N] as IConnection).Release;
      FConnectionList.items[N] := nil;
      FConnectionList.delete (N);
    end;
    FConnectionList.free;
    FConnectionList := nil;
  end;
  CriticalSection.free;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


procedure   TFlexnetDevice.SaveConnections;
const
  MethodName = 'SaveConnections';

var
  N: Integer;
  V: IConnection;
  H: Word;

begin
  DebOut (self, MethodName, 'begin...');
  assert (assigned (FConnectionList));
  for N := (FConnectionList.count - 1) downto 0 do begin
    V := IConnection (FConnectionList.items[N]);
    H := V.Handle;
    l2_long_hold (H);
    V.Save (FRegKey);
    V := nil;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    TFlexnetDevice.SettingsDialog (AOwner: TComponent): Integer;
var
  N: Integer;
  S: String;
  P: PChar;
  L: TStringList;

begin

  with TFlexnetDeviceSettingsForm.Create (AOwner) do begin

    try

      if (Status = gs_ready) then begin
        // DLL calls only under the lock and with the DLL loaded (see Run)
        L := TStringList.Create;
        try
          S := '';
          CriticalSection.Enter;
          try
            if (AxInitOk) then begin
              P := l2_version;
              if (assigned (P)) then S := StrPas (P) else S := '?';
              S := 'PC/FlexNet Kernel Version ' + S;
              if (FDigi) then S := S + ' mit Digipeater-Modul';
              for N := 0 to 15 do begin
                if (ch_active (N) <> 0) then begin
                  P := get_ident(N);
                  if (assigned (P)) then L.Add (IntToStr(N) + ' ' + StrPas (P)) else L.Add (IntToStr(N) + ' ?');
                end;
              end;
            end;
          finally
            CriticalSection.Leave;
          end;
          if (S = '') then S := StatusText;
          HeadingLabel.Caption := S;
          Listbox.Items.AddStrings (L);
        finally
          L.Free;
        end;
      end else if (Status = gs_inactive) then begin
        HeadingLabel.Caption := 'Inaktiv: Schließen Sie dieses Fenster mit OK und klicken Sie dann auf ''übernehmen'', um FlexNet zu aktivieren.';
      end else begin
        HeadingLabel.Caption := StatusText;
      end;

      Result := ShowModal;

      if (Result = mrOk) then begin

      end;

    finally

      Release;

    end;

  end;

end;


procedure   TFlexnetDevice.CancelSettings;
begin
  //
end;


procedure   TFlexnetDevice.ApplySettings;
begin
  if (Status <> gs_ready) then begin
    FRegKey := '';
    Init;
  end;
end;


procedure   TFlexnetDevice.Init;
begin

  (*
  if (FRegKey <> '') then begin
    Registry := TRegistry.Create (KEY_READ);
    Registry.RootKey := HKEY_CURRENT_USER;
    Registry.OpenKey (FRegKey, false);
    Registry.CloseKey;
    Registry.Free;
  end;
  *)

  inherited;

end;


procedure   TFlexnetDevice.Save;
var
  Registry: TRegistry;

begin

  inherited;

  Registry := TRegistry.Create (KEY_READ or KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if (Registry.OpenKey (FRegKey, true)) then begin
      try
        Registry.WriteString ('', ClassName);
      except
      end;
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;

end;


procedure   TFlexnetDevice.Restore;
const
  MethodName = 'Restore';

var
  SL: TStringList;
  N: Integer;
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
        Registry.GetKeyNames (SL);
        Registry.CloseKey;
      end;
    finally
      Registry.free;
    end;

    for N := 0 to SL.Count - 1 do begin

      H := StrToInt (SL[N]);

      PacketConnection := TConnection.Create (self);

      try
        PacketConnection.Restore (FRegKey, H);
      except
        PacketConnection.Release;
        PacketConnection := nil;
      end;

      if (assigned (PacketConnection)) then begin
        ConnectionsList.Lock;
        try
          FConnectionList.Add (PacketConnection);
          PacketConnection := nil;
        finally
          ConnectionsList.Unlock;
        end;
      end;

    end;

  finally

    SL.Free;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TFlexnetDevice.DropRestored;
// Restore hängt die gespeicherten Verbindungen schon vor dem Laden der DLL an
// ihre Kanäle. Scheitert das Laden oder ax_init, prüft CheckRestored sie nie;
// ohne diesen Abbau blieben sie als "verbunden" stehen, ließen sich nicht
// trennen und belegten die Kanäle. Ruft keine DLL-Funktionen auf.
const
  MethodName = 'DropRestored';
var
  N: Integer;
  PacketConnection: IConnection;
begin
  while (true) do begin
    ConnectionsList.Lock;
    try
      N := FConnectionList.Count - 1;
      if (N >= 0) then begin
        PacketConnection := FConnectionList.Items[N] as IConnection;
        FConnectionList.Items[N] := nil;
        FConnectionList.Delete (N);
      end;
    finally
      ConnectionsList.UnLock;
    end;
    if (N < 0) then break;
    // Disconnected ruft in den Kanal (SendMessage an den Hauptthread), daher ohne Sperre.
    try
      PacketConnection.Disconnected (dr_linkfailure);
    except
    end;
    PacketConnection.Release;
    PacketConnection := nil;
  end;
end;


procedure   TFlexnetDevice.CheckRestored;
const
  MethodName = 'CheckRestored';

var
  N: Integer;
  PacketConnection: IConnection;
  Frame: PFrame;
  SrcCall, DestCall, Digis: String;
  B: Boolean;
  S: String;

begin

  for N := FConnectionList.Count - 1 downto 0 do begin

    PacketConnection := FConnectionList.Items[N] as IConnection;

    B := false;

    if ((l2_state (PacketConnection.Handle) and L2_STATE_MASK) >= 2) then begin

      Frame := l2_get_f (PacketConnection.Handle);

      if (assigned (Frame)) then begin

        SetLength (SrcCall, STRCALLLEN);
        StrCall (PChar(SrcCall), PChar(@Frame^.source));
        SetLength (SrcCall, StrLen(PChar(SrcCall)));

        SetLength (DestCall, STRCALLLEN);
        StrCall (PChar(DestCall), PChar(@Frame^.dest));
        SetLength (DestCall, StrLen(PChar(DestCall)));

        SetLength (Digis, STRPATHLEN);
        StrPath (PChar(Digis), Frame);
        SetLength (Digis, StrLen(PChar(Digis)));

        S := DestCall;
        if (Length (Digis) > 0) then S := S + ' ' + Digis;

        DebOut (self, MethodName, '%s > %s', [SrcCall, S]);
        DebOut (self, MethodName, '%s > %s', [PacketConnection.MyCall, PacketConnection.RealPath]);

        if (CompareStr (SrcCall, PacketConnection.MyCall) = 0) and
           (CompareStr (S, PacketConnection.RealPath) = 0) then begin

          DebOut (self, MethodName, 'FlexNet-QSO stimmt mit gespeicherten QSO-Daten überein.');
          B := true;

        end else begin

          DebOut (self, MethodName, 'FlexNet-QSO stimmt NICHT mit gespeicherten QSO-Daten überein.');

        end;

      end else begin

        DebOut (self, MethodName, 'l2_get_f lieferte NIL.');

      end;

    end;

    ConnectionsList.Lock;
    try
      if (not B) then begin
        FConnectionList.Items[N] := nil;
        FConnectionList.Delete (N);
      end;
    finally
      ConnectionsList.Unlock;
    end;

    if (not B) then begin
      PacketConnection.Disconnected (dr_linkfailure);
      PacketConnection.Release;
      PacketConnection := nil;
    end;

  end;

end;


procedure   TFlexnetDevice.Run;
const
  MethodName = 'Run';

var
  N, I, M: Integer;
  PI: PInfo;
  Info: TInfo;
  S: String;
  PacketConnection: IConnection;
  Frame: PFrame;
  SrcCall, DestCall, Digis: String;
  MyCall: TMyCall;
  OwnCalls: TStringList;
  Count: Integer;
  ChannelRef: IChannelForConnection;
  DoReleaseConnection: Boolean;
  Handle: U16;
  MonitorThread: TMonitorThread;
  MonitorTerminated: Boolean;
  Reason: TDisconnectReason;

begin

  try

    MonitorThread := nil;
    MonitorTerminated := true;

    EventQSODATA := 0;
    EventQSOSTATE := 0;
    EventNODEFRAME := 0;
    EventSABM := 0;
    EventUI := 0;
    EventCHANNELS := 0;

    SetStatus (gs_init, 'Lade DLL...');

    if (FlexnetInit) then begin

      try

        SetStatus (gs_init, 'ax_init...');
        N := ax_init;

        if (N >= 1) then begin

          try

            CriticalSection.Enter;
            AxInitOk := true;
            CriticalSection.Leave;

            FDigi := (N = 2);

            EventQSODATA := OpenEvent (Windows.SYNCHRONIZE, false, EV_QSODATA);
            EventQSOSTATE := OpenEvent (Windows.SYNCHRONIZE, false, EV_QSOSTATE);
            EventNODEFRAME := OpenEvent (Windows.SYNCHRONIZE, false, EV_NODEFRAME);
            EventSABM := OpenEvent (Windows.SYNCHRONIZE, false, EV_SABM);
            EventUI := OpenEvent (Windows.SYNCHRONIZE, false, EV_UI);
            EventCHANNELS := OpenEvent (Windows.SYNCHRONIZE, false, EV_CHANNELS);

            InitRadioChannels;

            CheckRestored;

            SetStatus (gs_ready, '');

            MonitorThread := TMonitorThread.create (true);
            MonitorThread.Priority := tpLower;
            MonitorThread.FreeOnTerminate := false;
            MonitorThread.FlexNetDevice := self;
            MonitorThread.DeviceNo := No;
            MonitorThread.Resume;

            Count := 0;

            while (not Terminated) do begin

              try

                for N := 0 to FConnectionList.Count - 1 do begin

                  PacketConnection := FConnectionList.Items[N] as IConnection;

                  Handle := PacketConnection.Handle;

                  I := l2_state (Handle);

                  if (PacketConnection.ConnectionStatus = vs_connect) then begin

                    if ((I and L2_STATE_MASK) >= 5) then begin

                      Frame := l2_get_f (Handle);

                      if (assigned (Frame)) then begin

                        SetLength (SrcCall, STRCALLLEN);
                        StrCall (PChar(SrcCall), PChar(@Frame^.source));
                        SetLength (SrcCall, StrLen(PChar(SrcCall)));

                        SetLength (DestCall, STRCALLLEN);
                        StrCall (PChar(DestCall), PChar(@Frame^.dest));
                        SetLength (DestCall, StrLen(PChar(DestCall)));

                        SetLength (Digis, STRPATHLEN);
                        StrPath (PChar(Digis), Frame);
                        SetLength (Digis, StrLen(PChar(Digis)));

                        PacketConnection.MyCall := SrcCall;
                        PacketConnection.Call := DestCall;
                        PacketConnection.Digis := Digis;

                        PacketConnection.ConnectionEstablished;

                      end;

                    end;

                  end;

                  PacketConnection.Status.Ax25state := (I and $3f);

                  if ((I and $40) <> 0) then begin // text is in the receive buffer

                    for M := 1 to 28 do begin
                      PI := l2_get_i (Handle);
                      if (assigned (PI)) then begin
                        SetString (S, PI^.Text, PI^.Len);
                        PacketConnection.ReceiveTextData (S);
                        l2_i_ack (Handle);
                      end else begin
                        break;
                      end;
                    end;

                  end;

                  case (I and L2_STATE_MASK) of

                    0: begin // partner not heard (any more)
                      PacketConnection.Disconnected (dr_linkfailure);
                      ConnectionsList.Lock;
                      try
                        FConnectionList.Items[N] := nil;
                        FConnectionList.Delete (N);
                      finally
                        ConnectionsList.UnLock;
                      end;
                      PacketConnection.Release;
                      PacketConnection := nil;
                      break;
                    end;

                    1: begin // partner busy or connection was closed
                      if (PacketConnection.ConnectionStatus = vs_connect) then begin
                        PacketConnection.Disconnected (dr_busy);
                      end else begin
                        PacketConnection.Disconnected (dr_normal);
                      end;
                      ConnectionsList.Lock;
                      try
                        FConnectionList.Items[N] := nil;
                        FConnectionList.Delete (N);
                      finally
                        ConnectionsList.UnLock;
                      end;
                      PacketConnection.Release;
                      PacketConnection := nil;
                      break;
                    end;

                    4: begin // disconnection in progress
                      PacketConnection.ConnectionStatus := vs_disconnect;
                    end;

                  end;

                  if (Terminated) then break;

                  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                  // Send text
                  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                  I := 14 - l2_unack (Handle);

                  for M := 1 to I do begin

                    if (PacketConnection.DeviceQueue.isEmpty) then break;

                    S := PacketConnection.DeviceQueue.current;

                    Info.Pid := $F0;
                    Info.Len := Length (S);
                    assert (Info.Len <= 256);

                    if (l2_ialloc (Handle, Info.Len) <> 0) then begin

                      PacketConnection.DeviceQueue.dequeue;
                      if (Info.Len > 0) then Move (S[1], Info.text, Info.Len);
                      l2_send_frame (Handle, Info);

                    end else begin

                      break;

                    end;

                  end;

                  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                  with PacketConnection.Status do begin
                    Unack := l2_unack (Handle) + PacketConnection.DeviceQueue.Count;
                    Tries := l2_tries (Handle);
                    Frack := l2_frack (Handle);
                    Maxframe := l2_maxframe (Handle);
                  end;

                  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                end;

                if (Terminated) then break;

                if (Count and $07) = 0 then begin

                  // Eigene Rufzeichen unter der Sperre nur kopieren. Das Annehmen einer
                  // Verbindung wartet per SendMessage auf den Hauptthread; hielte der
                  // Gerätethread dabei MyCalls, verklemmten sich beide, sobald der
                  // Hauptthread selbst auf MyCalls wartet.
                  OwnCalls := TStringList.Create;

                  try

                    MyCalls.BeginRead;
                    try
                      for N := 0 to MyCalls.count - 1 do begin
                        MyCall := MyCalls[N];
                        for M := 0 to MyCall.SSIDCount - 1 do begin
                          OwnCalls.Add (MyCall.CallWithSSID[M]);
                        end;
                      end;
                    finally
                      MyCalls.EndRead;
                    end;

                    for N := 0 to OwnCalls.Count - 1 do begin

                      I := l2_get_sabm (PChar(OwnCalls[N]));

                      if (I <> 0) then begin

                        Frame := l2_get_f (I);

                        if (assigned (Frame)) then begin

                          SetLength (SrcCall, STRCALLLEN);
                          StrCall (PChar(SrcCall), PChar(@Frame^.source));
                          SetLength (SrcCall, StrLen(PChar(SrcCall)));

                          SetLength (DestCall, STRCALLLEN);
                          StrCall (PChar(DestCall), PChar(@Frame^.dest));
                          SetLength (DestCall, StrLen(PChar(DestCall)));

                          SetLength (Digis, STRPATHLEN);
                          StrPath (PChar(Digis), Frame);
                          SetLength (Digis, StrLen(PChar(Digis)));

                          PacketConnection := TConnection.Create (self);

                          DoReleaseConnection := true;

                          PacketConnection.MyCall := SrcCall;
                          PacketConnection.Call := DestCall;
                          PacketConnection.Digis := Digis;
                          PacketConnection.RealPath := PacketConnection.Path;
                          PacketConnection.Handle := I;
                          PacketConnection.Outgoing := false;

                          case PacketConnection.IsIncomingConnectAllowed of

                            ic_accept: begin

                              ChannelRef := ChannelList.NextFreeChannel as IChannelForConnection;

                              if (assigned (ChannelRef)) then begin

                                PacketConnection.ChannelRef := ChannelRef;

                                PacketConnection.SendConnectText := true;
                                PacketConnection.RemoteCommandsPossible := true;

                                PacketConnection.ConnectionEstablished;

                                DebOut (self, MethodName, 'Verbindungswunsch von %s akzeptiert.', [PacketConnection.Call]);

                                l2_sabmresp (I);
                                l2_pack (PacketConnection.Handle);

                                ConnectionsList.Lock;
                                try
                                  FConnectionList.Add (PacketConnection);
                                finally
                                  ConnectionsList.UnLock;
                                end;
                                DoReleaseConnection := false;

                              end else begin

                                DebOut (self, MethodName, 'Verbindungswunsch von %s abgelehnt (kein freier Kanal).',
                                        [PacketConnection.Call]);
                                l2_sabm_dm (I);

                              end;

                            end;

                            ic_ignore: begin

                              DebOut (self, MethodName, 'Verbindungswunsch von %s ignoriert.', [PacketConnection.Call]);

                            end;

                            ic_busy: begin

                              DebOut (self, MethodName, 'Verbindungswunsch von %s abgelehnt.', [PacketConnection.Call]);
                              l2_sabm_dm (I);

                            end;

                          end;

                          if (DoReleaseConnection) then begin
                            PacketConnection.Release;
                            PacketConnection := nil;
                          end;

                        end;

                      end;

                    end;

                  finally

                    OwnCalls.Free;

                  end;

                  if (Terminated) then break;

                end;

                inc (Count);

                if (EventQSODATA <> 0) then begin
                  WaitForMultipleObjects ([EventQSODATA, EventQSOSTATE, EventSABM, EventUI, EventCHANNELS], 20);
                end else begin
                  Sleep (20);
                end;

              except

                on E: Exception do begin
                  ShowUnhandledException (E, ClassName, '1');
                  raise;
                end;

              end;

            end;

          finally

            // From here on, no more DLL calls via RadioChannels/InitRadioChannels
            CriticalSection.Enter;
            AxInitOk := false;
            CriticalSection.Leave;

            InitRadioChannels;

            if (not Terminated) then begin
              // Aborted by an exception: stop reporting "ready"
              SetStatus (gs_error, 'Abbruch nach Fehler');
            end;

            // The connections are held in the kernel (l2_long_hold), saved and restored at the
            // next start only when Paxon ends. After an exception, or when only the device is
            // stopped or removed, nothing would read or disconnect them any more.
            if (not Terminated) or (not assigned (MainWindow)) or (not MainWindow.IsShuttingDown) then begin
              if (Terminated) then Reason := dr_normal else Reason := dr_linkfailure;
              // Disconnect the connections while the DLL is still loaded; otherwise they would remain in the
              // channels. EstablishConnection adds nothing more after AxInitOk = false. Disconnected
              // calls into the channel (SendMessage to the main thread), hence without the lock.
              while (FConnectionList.Count > 0) do begin
                ConnectionsList.Lock;
                try
                  N := FConnectionList.Count - 1;
                  PacketConnection := FConnectionList.Items[N] as IConnection;
                  FConnectionList.Items[N] := nil;
                  FConnectionList.Delete (N);
                finally
                  ConnectionsList.UnLock;
                end;
                try
                  l2_stop_qso (PacketConnection.Handle);
                except
                end;
                try
                  PacketConnection.Disconnected (Reason);
                except
                end;
                PacketConnection.Release;
                PacketConnection := nil;
              end;
            end;

            if (assigned (MonitorThread)) then begin
              // The monitor thread must have ended before ax_exit and FreeLibrary. It waits
              // at most 200 ms for EV_TRACE and otherwise only calls non-blocking
              // DLL functions; ChannelList.Monitor goes via SendMessage to the main thread, which
              // processes messages during shutdown (DeInit). If it still does not end, the
              // DLL stays loaded instead of being unloaded under the running thread.
              MonitorThread.Terminate;
              if (WaitForSingleObject (MonitorThread.Handle, 3000) = WAIT_OBJECT_0) then begin
                MonitorThread.Free;
              end else begin
                DebOut (self, MethodName, 'Monitor-Thread endet nicht, DLL bleibt geladen.');
                MonitorTerminated := false;
                MonitorThread.FreeOnTerminate := true;
              end;
            end;

            PacketConnection := nil;

            try
              SaveConnections;
            except
            end;

            CloseHandle (EventQSODATA);
            CloseHandle (EventQSOSTATE);
            CloseHandle (EventNODEFRAME);
            CloseHandle (EventSABM);
            CloseHandle (EventUI);
            CloseHandle (EventCHANNELS);

            if (MonitorTerminated) then begin
              try
                ax_exit;
              except
              end;
            end;

          end;

        end else begin

          SetStatus (gs_error, 'Kernel nicht geladen');
          DropRestored;

        end;

      finally

        if (MonitorTerminated) then FlexnetDeInit;

      end;

    end else begin

      SetStatus (gs_error, FlexnetError);
      DropRestored;

    end;

  except

    on E: Exception do begin
      ShowUnhandledException (E, ClassName, '2');
      raise;
    end;

  end;

end;


function     TFlexnetDevice.RadioChannels (var aRadioChannels: Array of IRadioChannel): Integer;
var
  A, N: Integer;
begin
  // Copy under the lock: the device thread clears FRadioChannel on shutdown
  // (InitRadioChannels, also under the lock).
  CriticalSection.Enter;
  try
    if (AxInitOk) then begin
      InitRadioChannels;
      A := 0;
      for N := 0 to 16 do begin
        if (FRadioChannel[N] <> nil) then begin
          aRadioChannels[A] := FRadioChannel[N];
          Inc (A);
        end;
      end;
      result := A;
    end else begin
      result := 0;
    end;
  finally
    CriticalSection.Leave;
  end;
end;


function     TFlexnetDevice.EstablishConnection (aRadioChannel: IRadioChannel; var aCall: String; var aMyCall: String;
                                                 aChannelObj: IChannel; var Connection: IConnection): TConnectError;
const
  MethodName = 'EstablishConnection';

var
  PacketConnection: IConnection;
  Frame: FlexnetApiU.TFrame;
  QSO: U16;
  I: Integer;
  B: Boolean;
  SsidIterator: TSsidIterator;
  K: Boolean;
  S, D, M, P: String;
  DoReleaseConnection: Boolean;
  G: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  Result := vf_unknown;

  PacketConnection := TConnection.Create (self);
  DoReleaseConnection := true;

  try

    PacketConnection.Path := aCall;
    PacketConnection.MyCall := aMyCall;

    if (aRadioChannel.Handle in [1..15]) then begin
      S := IntToStr (aRadioChannel.Handle);
      if (PacketConnection.Digis <> '') then S := S + ' ' + PacketConnection.Digis;
      PacketConnection.Digis := S;
    end;

    PacketConnection.RealPath := PacketConnection.Path;

    PacketConnection.Outgoing := true;
    PacketConnection.SendConnectText := false;
    PacketConnection.RemoteCommandsPossible := true;

    SsidIterator := TSsidIterator.Create (PacketConnection.MyCall);

    try

      K := SsidIterator.Reset;

      while (true) do begin

        if (not K) then begin
          DebOut (self, MethodName, 'Keine freie SSID gefunden.');
          Result := vf_nossid;
          break;
        end;

        PacketConnection.MyCall := SsidIterator.Callsign;
        M := PacketConnection.MyCall;
        P := PacketConnection.Path;

        // DLL calls only under the lock and with the DLL loaded: Run resets AxInitOk under
        // the lock before it unloads the DLL. Assignments to Connection and DebOut
        // outside the lock.
        CriticalSection.Enter;
        try
          G := AxInitOk;
          if (G) then begin
            // BUILD frame does the routing
            build_frame (Frame, PChar(M), PChar(P));
            Frame.ChannelRef := aRadioChannel.Handle;
            SetLength (S, STRCALLLEN);
            StrCall (PChar(S), PChar(@Frame.dest));
            SetLength (S, StrLen(PChar(S)));
            SetLength (D, STRPATHLEN);
            StrPath (PChar(D), @Frame);
            SetLength (D, StrLen(PChar(D)));
          end;
        finally
          CriticalSection.Leave;
        end;

        if (not G) then begin
          Result := vf_deviceerror;
          break;
        end;

        if (PacketConnection.Call <> S) then PacketConnection.Call := S;
        if (PacketConnection.Digis <> D) then PacketConnection.Digis := D;

        PacketConnection.RealPath := PacketConnection.Path;

        DebOut (Self, MethodName, 'MyCall: ' + PacketConnection.MyCall + ' Call: ' + PacketConnection.Call);

        if (PacketConnection.MyCall = PacketConnection.Call) then begin
          B := False;
        end else begin
          QSO := 0;
          I := 0;
          CriticalSection.Enter;
          try
            G := AxInitOk;
            if (G) then begin
              QSO := l2_get_qnum (Frame);
              if (QSO <> 0) then I := l2_state (QSO) and L2_STATE_MASK;
            end;
          finally
            CriticalSection.Leave;
          end;
          if (not G) then begin
            B := false;
          end else if (QSO = 0) then begin
            DebOut (Self, MethodName, 'Kein QSO gefunden');
            B := true;
          end else begin
            if (I >= 2) then begin
              DebOut (Self, MethodName, 'Bestehendes QSO gefunden (connected)');
              B := false;
            end else begin
              DebOut (Self, MethodName, 'Bestehendes QSO gefunden (disconnected)');
              B := true;
            end;
          end;
        end;

        if (not G) then begin
          Result := vf_deviceerror;
          break;
        end;

        if (B) then begin

          CriticalSection.Enter;
          try
            G := AxInitOk;
            if (G) then PacketConnection.Handle := l2_fconnect (Frame);
          finally
            CriticalSection.Leave;
          end;

          if (G) and (PacketConnection.Handle <> 0) then begin

            PacketConnection.ChannelRef := aChannelObj as IChannelForConnection;

            // Only add while the DLL is still loaded, so that Run sees the connection on an
            // abort and disconnects it.
            CriticalSection.Enter;
            try
              G := AxInitOk;
              if (G) then begin
                ConnectionsList.Lock;
                try
                  FConnectionList.Add (PacketConnection);
                finally
                  ConnectionsList.Unlock;
                end;
              end;
            finally
              CriticalSection.Leave;
            end;

            if (G) then begin
              Result := vf_ok;
              DoReleaseConnection := false;
            end else begin
              Result := vf_deviceerror;
            end;

            break;

          end else begin
            Result := vf_deviceerror;
            break;
          end;

        end else begin

          K := SsidIterator.Next;

        end;

      end;

    finally

      SsidIterator.free;
      aChannelObj := nil;

    end;

  finally

    if (DoReleaseConnection) then begin
      PacketConnection.Release;
      PacketConnection := nil;
    end;

  end;

  Connection := PacketConnection;

  DebOut (self, MethodName, 'end.');

end;


procedure    TFlexnetDevice.TerminateConnection (aConnectionObj: IConnection);
const
  MethodName = 'TerminateConnection';
var
  L: TDisconnectLevel;
  H: Integer;
  G: Boolean;
begin
  DebOut (self, MethodName, 'begin...');
  assert (assigned (aConnectionObj));
  L := aConnectionObj.DiscLevel;
  H := aConnectionObj.Handle;
  // DLL call only under the lock and with the DLL loaded (see Run); DiscLevelDone calls
  // into the channel (SendMessage) and therefore outside the lock.
  CriticalSection.Enter;
  try
    // The device thread may have removed the connection meanwhile (link gone), and
    // FlexNet reuses QSO numbers: never stop a QSO that is no longer this connection's.
    G := (AxInitOk) and (FConnectionList.IndexOf (aConnectionObj) >= 0);
    if (G) then begin
      case L of
        dl_end: l2_stop_qso (H);
        dl_cancel: l2_cancel_qso (H);
        dl_kill: l2_kill_qso (H);
      end;
    end;
  finally
    CriticalSection.Leave;
  end;
  if (G) and (L in [dl_end, dl_cancel, dl_kill]) then aConnectionObj.DiscLevelDone;
  DebOut (self, MethodName, 'end.');
end;


procedure   TFlexnetDevice.InitRadioChannels;
var
  N: Integer;
  F: IRadioChannel;
  S: String;
  P: PChar;
begin
  CriticalSection.Enter;
  try
    if (AxInitOk) then begin
      if (FDigi) then begin
        for N := 0 to 15 do FRadioChannel[N] := nil;
        if (not assigned (FRadioChannel[16])) then begin
          FRadioChannel[16] := TRadioChannel.Create (self);
          FRadioChannel[16].Name := 'FlexNet Digi';
          FRadioChannel[16].Handle := 16;
          FRadioChannel[16].ID := 'FLEXDIGI';
        end;
      end else begin
        for N := 0 to 15 do begin
          if (ch_active (N) <> 0) then begin
            P := get_ident (N);
            if (not assigned (P)) then break;
            S := StrPas (P);
            if (assigned (FRadioChannel[N])) and (FRadioChannel[N].Name <> S) then FRadioChannel[N] := nil;
            if (not assigned (FRadioChannel[N])) then begin
              F := TRadioChannel.Create (self);
              F.Name := S;
              F.Handle := N;
              F.ID := Format ('FLEX%2.2d', [N]);
              FRadioChannel[N] := F;
            end;
          end else begin
            FRadioChannel[N] := nil;
          end;
        end;
        FRadioChannel[16] := nil;
      end;
    end else begin
      for N := 0 to 16 do FRadioChannel[N] := nil;
    end;
  finally
    CriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TMonitorThread.SetMonitor;
var
  Trace: TTrace;
begin
  // the DLL also reads the fields not set here (handle, rest of call)
  FillChar (Trace, SizeOf (Trace), 0);
  with Trace do begin
    ch_mask := $FFFF;
    type_filter := 0;
    trxfilter := 3;
    call[0] := #0;
  end;
  l2_set_monitor (Trace);
end;


procedure   TMonitorThread.ClearMonitor;
begin
  if (l2_chk_monitor <> 0) then l2_clr_monitor;
end;


procedure   TMonitorThread.Execute;
const
  MethodName = 'Execute';

var
  MonitorFrame: TMonitorFrame;
  Count: Cardinal;
  C: Cardinal;
  Monitor: Cardinal;
  Frame: PFrame;
  B: Boolean;
  EventTRACE: THandle;
  I: Integer;
  S: String;

begin

  try

    EventTRACE := OpenEvent (Windows.SYNCHRONIZE, false, EV_TRACE);

    try

      try

        Monitor := Config.Monitor;

        Count := 0;

        while (not Terminated) do begin

          if (EventTRACE <> 0) then begin
            WaitForMultipleObjects ([EventTRACE], 200);
          end else begin
            Sleep (200);
          end;
          if (Terminated) then break;

          if ((Count and $0F) = 0) then begin
            C := Config.Monitor;
            if (Monitor <> C) then begin
              Monitor := C;
              if ((Monitor and MonitorEnabled) <> 0) then begin
                SetMonitor;
              end else begin
                ClearMonitor;
              end;
            end;
          end;

          if ((Monitor and MonitorEnabled) <> 0) then begin

            if (Count and $0F) = 0 then begin
              if (l2_chk_monitor = 0) then begin
                DebOut (self, MethodName, 'Monitor verloren');
                SetMonitor;
              end;
            end;

            while (not Terminated) do begin

              Frame := l2_get_monitor;
              if (not assigned (Frame)) then break;

              with MonitorFrame do begin

                case Frame.frame_type of

                  FT_I: begin
                    if ((Monitor and MonitorInformation) <> 0) then begin
                      if ((Monitor and MonitorInformationContent) <> 0) then begin
                        if (Frame.textlen > 0) then begin
                          SetString (Text, Frame.Text, Frame.TextLen);
                        end else begin
                          Text := '';
                        end;
                      end else begin
                        Text := '';
                      end;
                      B := true;
                    end else begin
                      B := false;
                    end;
                  end;

                  FT_RR, FT_RNR, FT_REJ, FT_SABM, FT_DISC, FT_DM, FT_UA, FT_FRMR: begin
                    B := ((Monitor and MonitorStatus) <> 0);
                    Text := '';
                  end;

                  FT_UI: begin
                    if ((Monitor and MonitorUnproto) <> 0) then begin
                      if (Frame.textlen > 0) then begin
                        SetString (Text, Frame.Text, Frame.TextLen);
                      end else begin
                        Text := '';
                      end;
                      B := true;
                    end else begin
                      B := false;
                    end;
                  end;

                  else begin
                    B := false;
                  end;

                end;

                if (B) then begin

                  SetLength (Src, STRCALLLEN);
                  StrCall (PChar(Src), PChar(@Frame^.source));
                  SetLength (Src, StrLen(PChar(Src)));

                  SetLength (Dest, STRCALLLEN);
                  StrCall (PChar(Dest), PChar(@Frame^.dest));
                  SetLength (Dest, StrLen(PChar(Dest)));

                  Digis := '';
                  for I := 0 to Frame.digis - 1 do begin
                    SetLength (S, STRCALLLEN);
                    StrCall (PChar(S), PChar(@Frame^.digi[I]));
                    SetLength (S, StrLen(PChar(S)));
                    if (I > 0) then Digis := Digis + ' ';
                    Digis := Digis + S;
                    if (I + 1 = Frame.nextdigi) then Digis := Digis + '*';
                  end;

                  FrameType := Frame.frame_type;
                  RXSeq := Frame.rx_seq;
                  TXSeq := Frame.ns;
                  Command := (Frame.cmd <> 0);
                  PollFinal := (Frame.pf <> 0);
                  Dama := (Frame.dama <> 0);
                  Pid := Frame.Pid;

                  Sent := (Frame.Tx <> 0);

                  Device := DeviceNo;
                  Port := Frame.ChannelRef;

                  l2_ack_monitor;

                  if (assigned (ChannelList)) then ChannelList.Monitor (MonitorFrame);

                end else begin

                  l2_ack_monitor;

                end;

              end;

            end;

          end;

          inc (Count);

        end;

        ClearMonitor;

      except

        on E: Exception do begin
          ShowUnhandledException (E, ClassName, MethodName);
          raise;
        end;

      end;

    finally

      CloseHandle (EventTRACE);

    end;

  except

    DebOut (self, MethodName, 'EXCEPTION');

  end;

end;


function    TFlexnetDevice.SendUI (aRadioChannel: IRadioChannel; aDestination, aMyCall, aText: String): Boolean;
var
  Dest: String;
begin
  Dest := aDestination + ' ' + IntToStr (aRadioChannel.Handle);
  // DLL call only under the lock and with the DLL loaded (see Run)
  CriticalSection.Enter;
  try
    result := (AxInitOk) and (l2_send_ui (PChar(aMyCall), PChar(Dest), $F0, 1, Length (aText), PChar(aText)) <> 0);
  finally
    CriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  DebOut ('FlexnetDeviceU.initialization: begin...');
  RegisterDevice (TFlexnetDevice);
  DebOut ('FlexnetDeviceU.initialization: end.');

end.

