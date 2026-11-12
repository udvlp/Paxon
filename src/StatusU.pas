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


unit StatusU;


interface


uses
  Classes, Windows, SysUtils, Messages, SyncObjs, Forms,
  InterfacesU, ConnectionAbstractU, GlobalU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TStatus = class (TInterfacedObject, IStatus)

  private

    CriticalSection: TCriticalSection;

    Released: Boolean;

    TimerWindow: HWnd;
    TimerRunning: Boolean;

    FChannel: IChannel;

    FUnack: Integer;
    FUnackChanged: Boolean;

    FTries: Integer;
    FTriesChanged: Boolean;

    FFrack: Integer;
    FFrackChanged: Boolean;

    FMaxframe: Integer;
    FMaxframeChanged: Boolean;

    FAx25state: Integer;
    FAx25stateChanged: Boolean;

    FEffectiveBaudrate: Integer;
    FEffectiveBaudrateChanged: Boolean;

    function    GetUnack: Integer;
    procedure   SetUnack (const Value: Integer);
    // Get...Changed returns whether the value has changed since the last query
    // and resets the flag (only TChannel.StatusUpdate queries it).
    function    GetUnackChanged: Boolean;

    function    GetTries: Integer;
    procedure   SetTries (const Value: Integer);
    function    GetTriesChanged: Boolean;

    function    GetFrack: Integer;
    procedure   SetFrack (const Value: Integer);
    function    GetFrackChanged: Boolean;

    function    GetMaxframe: Integer;
    procedure   SetMaxframe (const Value: Integer);
    function    GetMaxframeChanged: Boolean;

    function    GetAx25state: Integer;
    procedure   SetAx25state (const Value: Integer);
    function    GetAx25stateChanged: Boolean;

    function    GetEffectiveBaudrate: Integer;
    procedure   SetEffectiveBaudrate (const Value: Integer);
    function    GetEffectiveBaudrateChanged: Boolean;

    function    GetChannelRef: IChannel;
    procedure   SetChannelRef (const Value: IChannel);

    procedure   DoNotify;
    procedure   DoNotifySync;

    procedure   CreateTimerWindow;
    procedure   CreateTimerWindowSync;
    procedure   DestroyTimerWindow;
    procedure   DestroyTimerWindowSync;

    procedure   NotifyTimer;

  public

    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   Release; virtual;

    property    ChannelRef: IChannel read GetChannelRef write SetChannelRef;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  SynchronizeU, DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TimerWndProc (Window: HWND; Message, wParam, lParam: Longint): Longint; stdcall;
var
  Status: TStatus;
begin

  Status := TStatus (GetWindowLong (Window, 0));

  case Message of

    WM_TIMER: begin
      Status.NotifyTimer;
      Result := 0;
    end;

    else begin
      Result := DefWindowProc (Window, Message, wParam, lParam);
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TStatus.AfterConstruction;
const
  MethodName = 'AfterConstruction';
begin
  DebOut (self, MethodName, 'begin...');
  inherited;
  CriticalSection := TCriticalSection.create;
  FUnack := -1;
  FUnackChanged := false;
  FTries := -1;
  FTriesChanged := false;
  FFrack := -1;
  FFrackChanged := false;
  FMaxframe := -1;
  FMaxframeChanged := false;
  FAx25state := -1;
  FAx25stateChanged := false;
  TimerWindow := 0;
  TimerRunning := false;
  FChannel := nil;
  Released := false;
  DebOut (self, MethodName, 'end.');
end;


procedure   TStatus.BeforeDestruction;
const
  MethodName = 'BeforeDestruction';
begin
  DebOut (self, MethodName, 'begin...');
  if (not Released) then Release;
  CriticalSection.free;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


procedure   TStatus.Release;
const
  MethodName = 'Release';
begin
  DebOut (self, MethodName, 'begin...');
  Released := true;
  DestroyTimerWindow;
  CriticalSection.Enter;
  FChannel := nil;
  CriticalSection.Leave;
  DebOut (self, MethodName, 'end.');
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TStatus.CreateTimerWindow;
const
  MethodName = 'CreateTimerWindow';
begin
  if (not Released) then Synchronize (CreateTimerWindowSync);
end;


procedure   TStatus.CreateTimerWindowSync;
const
  MethodName = 'CreateTimerWindowSync';

var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
  TimerWindowClass: TWndClass;
  TimerWindowClassName: String;

begin


  DestroyTimerWindow;

  TimerWindowClassName := 'StatusTimerWindow';

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


procedure   TStatus.DestroyTimerWindow;
const
  MethodName = 'DestroyTimerWindow';
begin
  Synchronize (DestroyTimerWindowSync);
end;


procedure   TStatus.DestroyTimerWindowSync;
const
  MethodName = 'DestroyTimerWindowSync';
begin
  if (TimerWindow <> 0) then begin
    KillTimer (TimerWindow, 0);
    DestroyWindow (TimerWindow);
    TimerWindow := 0;
    TimerRunning := false;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TStatus.GetChannelRef: IChannel;
begin
  CriticalSection.Enter;
  result := FChannel;
  CriticalSection.Leave;
end;


procedure   TStatus.SetChannelRef (const Value: IChannel);
begin
  CriticalSection.Enter;
  FChannel := Value;
  CriticalSection.Leave;
  if (assigned (Value)) then CreateTimerWindow;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TStatus.GetUnack: Integer;
begin
  CriticalSection.Enter;
  result := FUnack;
  CriticalSection.Leave;
end;


procedure   TStatus.SetUnack (const Value: Integer);
var
  B: Boolean;
begin
  assert (not Released);
  CriticalSection.Enter;
  if (FUnack <> Value) then begin
    FUnack := Value;
    FUnackChanged := true;
    B := true;
  end else begin
    B := false;
  end;
  CriticalSection.Leave;
  if (B) then DoNotify;
end;


function    TStatus.GetUnackChanged: Boolean;
begin
  CriticalSection.Enter;
  result := FUnackChanged;
  FUnackChanged := false;
  CriticalSection.Leave;
end;


function    TStatus.GetTries: Integer;
begin
  CriticalSection.Enter;
  result := FTries;
  CriticalSection.Leave;
end;


procedure   TStatus.SetTries (const Value: Integer);
var
  B: Boolean;
begin
  assert (not Released);
  CriticalSection.Enter;
  if (FTries <> Value) then begin
    FTries := Value;
    FTriesChanged := true;
    B := true;
  end else begin
    B := false;
  end;
  CriticalSection.Leave;
  if (B) then DoNotify;
end;


function    TStatus.GetTriesChanged: Boolean;
begin
  CriticalSection.Enter;
  result := FTriesChanged;
  FTriesChanged := false;
  CriticalSection.Leave;
end;


function    TStatus.GetFrack: Integer;
begin
  CriticalSection.Enter;
  result := FFrack;
  CriticalSection.Leave;
end;


procedure   TStatus.SetFrack (const Value: Integer);
var
  B: Boolean;
begin
  assert (not Released);
  CriticalSection.Enter;
  if (FFrack <> Value) then begin
    FFrack := Value;
    FFrackChanged := true;
    B := true;
  end else begin
    B := false;
  end;
  CriticalSection.Leave;
  if (B) then DoNotify;
end;


function    TStatus.GetFrackChanged: Boolean;
begin
  CriticalSection.Enter;
  result := FFrackChanged;
  FFrackChanged := false;
  CriticalSection.Leave;
end;


function    TStatus.GetMaxframe: Integer;
begin
  CriticalSection.Enter;
  result := FMaxFrame;
  CriticalSection.Leave;
end;


procedure   TStatus.SetMaxframe (const Value: Integer);
var
  B: Boolean;
begin
  assert (not Released);
  CriticalSection.Enter;
  if (FMaxframe <> Value) then begin
    FMaxframe := Value;
    FMaxframeChanged := true;
    B := true;
  end else begin
    B := false;
  end;
  CriticalSection.Leave;
  if (B) then DoNotify;
end;


function    TStatus.GetMaxframeChanged: Boolean;
begin
  CriticalSection.Enter;
  result := FMaxframeChanged;
  FMaxframeChanged := false;
  CriticalSection.Leave;
end;


function    TStatus.GetAx25state: Integer;
begin
  CriticalSection.Enter;
  result := FAx25state;
  CriticalSection.Leave;
end;


procedure   TStatus.SetAx25state (const Value: Integer);
var
  B: Boolean;
begin
  assert (not Released);
  CriticalSection.Enter;
  if (FAx25state <> Value) then begin
    FAx25state := Value;
    FAx25stateChanged := true;
    B := true;
  end else begin
    B := false;
  end;
  CriticalSection.Leave;
  if (B) then DoNotify;
end;


function    TStatus.GetAx25stateChanged: Boolean;
begin
  CriticalSection.Enter;
  result := FAx25stateChanged;
  FAx25stateChanged := false;
  CriticalSection.Leave;
end;


function    TStatus.GetEffectiveBaudrate: Integer;
begin
  CriticalSection.Enter;
  result := FEffectiveBaudrate;
  CriticalSection.Leave;
end;


procedure   TStatus.SetEffectiveBaudrate (const Value: Integer);
var
  B: Boolean;
begin
  assert (not Released);
  CriticalSection.Enter;
  if (FEffectiveBaudrate <> Value) then begin
    FEffectiveBaudrate := Value;
    FEffectiveBaudrateChanged := true;
    B := true;
  end else begin
    B := false;
  end;
  CriticalSection.Leave;
  if (B) then DoNotify;
end;


function    TStatus.GetEffectiveBaudrateChanged: Boolean;
begin
  CriticalSection.Enter;
  result := FEffectiveBaudrateChanged;
  FEffectiveBaudrateChanged := false;
  CriticalSection.Leave;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TStatus.DoNotify;
const
  MethodName = 'DoNotify';
begin
  if (not Released) then Synchronize (DoNotifySync);
end;


procedure   TStatus.DoNotifySync;
const
  MethodName = 'DoNotifySync';
begin
  CriticalSection.Enter;
  if (assigned (FChannel)) and (not TimerRunning) and (iswindow (TimerWindow)) then begin
    TimerRunning := true;
    SetTimer (TimerWindow, 0, 100, nil);
  end;
  CriticalSection.Leave;
end;


procedure   TStatus.NotifyTimer;
const
  MethodName = 'NotifyTimer';
begin
  if (not Released) then begin
    CriticalSection.Enter;
    KillTimer (TimerWindow, 0);
    if (assigned (FChannel)) then FChannel.StatusChanged;
    TimerRunning := false;
    CriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

