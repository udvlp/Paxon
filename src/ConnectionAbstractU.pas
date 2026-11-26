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


unit ConnectionAbstractU;


interface


uses
  Classes, Windows, SysUtils, Messages, SyncObjs, QueueU,
  GlobalU, InterfacesU, SendFileU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionAbstract = class; // forward


  TWhyTerminated = e_finish..e_threadterminated;


  TConnectionAbstractClass = class of TConnectionAbstract;


  TEventSet = set of TEventEnum;


  TEventHandler = procedure of object;


  TConnectionAbstract = class (TInterfacedObject, IConnectionAbstract)

  private

    FOwner: TConnectionAbstract;
    FCanCancel: Boolean;
    FinishEvent: TEvent;
    FWhyFinished: TWhyTerminated;
    FTerminatedCalled: Boolean;
    UsedEventsSet: TEventSet;
    UsedEventHandleCount: Cardinal;
    UserEventStartIndex: Integer;
    UsedEventHandles: Array[0..Ord (High (TEventEnum))] of THandle;
    UsedEventHandlers: Array[0..Ord (High (TEventEnum))] of TEventHandler;

    function    GetUseEvent (aEvent: TUserEventEnum): Boolean;
    procedure   SetUseEvent (aEvent: TUserEventEnum; Use: Boolean);

    procedure   EventLoop; virtual;

  protected

    Released: Boolean;

    PacketConnection: IConnectionForModule;

    procedure   Init; virtual;
    procedure   ReceiveData; virtual;
    procedure   SendData; virtual;
    procedure   SendingPossible; virtual;
    procedure   SendFile; virtual;
    procedure   Terminated (Why: TWhyTerminated); virtual;
    procedure   AbortTransfer; virtual;
    property    UseEvent [aEvent: TUserEventEnum]: Boolean read GetUseEvent write SetUseEvent;

    function    GetCanCancel: Boolean; virtual;
    procedure   SetCanCancel (const Value: Boolean); virtual;
    property    CanCancel: Boolean read GetCanCancel write SetCanCancel;
    procedure   Finish; virtual;

  public

    constructor create (aOwner: TConnectionAbstract; aConnectionObj: IConnection); virtual;
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   Release; virtual;
    procedure   CancelTransfer; virtual;
    function    Name: string; virtual;

    class procedure RunStandard (aConnectionObj: IConnectionForModule);
    procedure Run (aConnectionObj: IConnectionForModule; VClass: TConnectionAbstractClass);

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, ConnectionStandardU, UnhandledExceptionU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TConnectionAbstract.create (aOwner: TConnectionAbstract; aConnectionObj: IConnection);
begin
  Released := false;
  FOwner := aOwner;
  PacketConnection := aConnectionObj as IConnectionForModule;
  inherited create;
end;


procedure   TConnectionAbstract.AfterConstruction;
begin

  FCanCancel := false;

  FinishEvent := TEvent.create (nil, true, false, '');

  UsedEventHandles [0] := FinishEvent.Handle;
  UsedEventHandles [1] := PacketConnection.AllEventHandles[e_threaddied];
  UsedEventHandles [2] := PacketConnection.AllEventHandles[e_threadterminated];
  UserEventStartIndex := 3;
  UsedEventHandleCount := 3;

  inherited;

  Init;

end;


procedure   TConnectionAbstract.BeforeDestruction;
begin
  FinishEvent.free;
  FinishEvent := nil;
  Release;
  inherited;
end;


procedure   TConnectionAbstract.Release;
begin
  if (not Released) then begin
    if (assigned (PacketConnection)) then begin
      PacketConnection.ConnectionModule := nil;
      PacketConnection := nil;
    end;
    if (assigned (FOwner)) then begin
      FOwner := nil;
    end;
  end;
  Released := true;
end;


class procedure TConnectionAbstract.RunStandard (aConnectionObj: IConnectionForModule);
const
  MethodName = 'RunStandard';
var
  aModuleObj: IConnectionAbstract;
begin
  DebOut ('TConnectionAbstract.RunStandard: Erzeuge TConnectionStandard');
  aModuleObj := TConnectionStandard.Create (nil, aConnectionObj);
  aConnectionObj.ConnectionModule := aModuleObj;
  try
    aModuleObj.EventLoop;
  finally
    aConnectionObj.ConnectionModule := nil;
    aModuleObj.Release;
    aModuleObj := nil;
  end;
  DebOut ('TConnectionAbstract.RunStandard: end.');
end;


procedure   TConnectionAbstract.Run (aConnectionObj: IConnectionForModule; VClass: TConnectionAbstractClass);
const
  MethodName = 'Run';
var
  ConnectionModule: IConnectionAbstract;
begin
  DebOut (self, MethodName, 'begin...');
  DebOut (self, MethodName, 'Erzeuge ' + VClass.ClassName);
  try
    ConnectionModule := VClass.Create (self, aConnectionObj);
  except
    // A module that fails to start (Init) only ends this transfer, like an exception
    // in its EventLoop: the half-built module has already unregistered itself
    // (BeforeDestruction -> Release), so register this module again.
    on E: Exception do begin
      ShowUnhandledException (E, ClassName, MethodName + ' (' + VClass.ClassName + ')');
      aConnectionObj.ConnectionModule := self;
      aConnectionObj.CanCancel := FCanCancel;
      exit;
    end;
  end;
  aConnectionObj.ConnectionModule := ConnectionModule;
  try
    try
      ConnectionModule.EventLoop;
    except
      // Eine Ausnahme im Übertragungsmodul (z. B. Datenträger voll) ist schon
      // gemeldet, und das Modul hat aufgeräumt (EventLoop). Sie beendet nur die
      // Übertragung, nicht den Verbindungs-Thread: Die Verbindung läuft mit
      // diesem Modul weiter.
      on E: Exception do begin
        DebOut (self, MethodName, 'Übertragung nach Ausnahme beendet: ' + E.Message);
      end;
    end;
  finally
    ConnectionModule.Release;
    ConnectionModule := nil;
    aConnectionObj.ConnectionModule := self;
    aConnectionObj.CanCancel := FCanCancel;
  end;
  DebOut (self, MethodName, 'end.');
end;


procedure   TConnectionAbstract.Init;
begin
  // abstract
end;


function    TConnectionAbstract.GetUseEvent (aEvent: TUserEventEnum): Boolean;
begin
  result := aEvent in UsedEventsSet;
end;


procedure   TConnectionAbstract.SetUseEvent (aEvent: TUserEventEnum; Use: Boolean);
const
  MethodName = 'SetUseEvent';
var
  E: TUserEventEnum;
begin
  if Use then begin
    Include (UsedEventsSet, aEvent);
  end else begin
    Exclude (UsedEventsSet, aEvent);
  end;
  UsedEventHandleCount := UserEventStartIndex;
  for E := Low(TUserEventEnum) to High (TUserEventEnum) do begin
    if (E in UsedEventsSet) then begin
      UsedEventHandles[UsedEventHandleCount] := PacketConnection.AllEventHandles[E];
      case E of
        e_receivedata:     UsedEventHandlers[UsedEventHandleCount] := ReceiveData;
        e_senddata:        UsedEventHandlers[UsedEventHandleCount] := SendData;
        e_sendingpossible: UsedEventHandlers[UsedEventHandleCount] := SendingPossible;
        e_sendfile:        UsedEventHandlers[UsedEventHandleCount] := SendFile;
        else raise PaxonException.Create (self, MethodName, 'Unbekanntes User-Event');
      end;
      Inc (UsedEventHandleCount);
    end;
  end;
end;


procedure   TConnectionAbstract.EventLoop;
const
  MethodName = 'EventLoop';

var
  D: DWord;
  Msg: TMsg;

begin

  DebOut (self, MethodName, 'begin...');

  assert (UsedEventHandles [0] = FinishEvent.Handle);
  assert (UsedEventHandles [1] = PacketConnection.AllEventHandles[e_threaddied]);
  assert (UsedEventHandles [2] = PacketConnection.AllEventHandles[e_threadterminated]);

  while true do begin

    try

      D := Windows.MsgWaitForMultipleObjects (UsedEventHandleCount, UsedEventHandles, false, INFINITE, QS_ALLEVENTS);

      if (D = WAIT_OBJECT_0 + UsedEventHandleCount) then begin

        while PeekMessage (Msg, 0, 0, 0, PM_REMOVE) do begin
          DispatchMessage (Msg);
        end;

      end else begin

        case D of

          WAIT_OBJECT_0 + 0: begin // e_finish
            FTerminatedCalled := true;
            Terminated (FWhyFinished);
            break;
          end;

          WAIT_OBJECT_0 + 1: begin // e_threaddied
            FTerminatedCalled := true;
            Terminated (e_threaddied);
            break;
          end;

          WAIT_OBJECT_0 + 2: begin // e_threadterminated
            FTerminatedCalled := true;
            Terminated (e_threadterminated);
            break;
          end;

          WAIT_OBJECT_0 + 3 .. WAIT_OBJECT_0 + 6: begin
            UsedEventHandlers [D - WAIT_OBJECT_0];
          end;

          WAIT_ABANDONED_0..WAIT_ABANDONED_0+6: begin
            DebOut (self, MethodName, 'Error: WAIT_ABANDONED');
            break;
          end;

          WAIT_TIMEOUT: begin
            DebOut (self, MethodName, 'Error: WAIT_TIMEOUT');
            break;
          end;

          WAIT_FAILED: begin
            DebOut (self, MethodName, 'Error: WAIT_FAILED, ' + GetLastErrorText);
            break;
          end;

          else begin
            DebOut (self, MethodName, 'Error: Unbekannter Rückgabewert.');
            break;
          end;

        end;

      end;

    except

      on E: Exception do begin
        ShowUnhandledException (E, ClassName, MethodName);
        // Aufräumen wie bei einem Abbruch: Dateien schließen, FileSender
        // freigeben. Nicht erneut, wenn die Ausnahme aus Terminated selbst kam.
        if (not FTerminatedCalled) then begin
          FTerminatedCalled := true;
          try
            Terminated (e_abort);
          except
          end;
        end;
        raise;
      end;

    end;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TConnectionAbstract.Finish;
begin
  FWhyFinished := e_finish;
  FinishEvent.SetEvent;
end;


procedure   TConnectionAbstract.AbortTransfer;
begin
  FWhyFinished := e_abort;
  FinishEvent.SetEvent;
end;


procedure   TConnectionAbstract.CancelTransfer;
begin
  if (FCanCancel) then begin
    FWhyFinished := e_cancel;
    FinishEvent.SetEvent;
  end;
end;


procedure   TConnectionAbstract.Terminated (Why: TWhyTerminated);
begin
  PacketConnection := nil;
end;


procedure   TConnectionAbstract.ReceiveData;
begin
  // abstract
end;


procedure   TConnectionAbstract.SendData;
begin
  // abstract
end;


procedure   TConnectionAbstract.SendingPossible;
begin
  // abstract
end;


procedure   TConnectionAbstract.SendFile;
begin
  // abstract
end;


function    TConnectionAbstract.Name: string;
begin
  result := ClassName;
end;


function    TConnectionAbstract.GetCanCancel: Boolean;
begin
  result := FCanCancel;
end;


procedure   TConnectionAbstract.SetCanCancel (const Value: Boolean);
begin
  if (Value <> FCanCancel) then begin
    FCanCancel := Value;
    PacketConnection.CanCancel := Value;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

