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


unit SendFileU;


interface


uses
  Windows, SysUtils, Classes, InterfacesU, GlobalU, SyncObjs, PublisherU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TSendFile = class (TInterfacedObject, ISendFile, IPublisher)
  private

    CriticalSection: TCriticalSection;

    FPacketConnection: IConnection;

    TimerWindow: HWnd;

    FPublisher: TPublisher;

    FSourceFilename: string;
    FTargetFilename: string;
    FTransferProtocol: TSendFileProtocol;
    FActive: TSendFileState;

    FPercent: Single;
    FProgress: Integer;
    FAbsolute: Integer;
    FStream: TStream;
    FTextBefore: string;
    FTextAfter: string;

    BytesPerSec: array[0..299] of Integer;
    TransferTotal: Cardinal;
    StartCalc: Boolean;
    LastTime: DWord;
    StartTime: DWord;

    TimeWindow: Integer;

    procedure   SetStream (aStream: TStream);
    function    GetStream: TStream;

    procedure   SetSourceFilename (const Name: string);
    function    GetSourceFilename: string;

    procedure   SetTargetFilename (const Name: string);
    function    GetTargetFilename: string;

    procedure   SetTransferProtocol (TransferProtocol: TSendFileProtocol);
    function    GetTransferProtocol: TSendFileProtocol;

    procedure   SetActive (aActive: TSendFileState);
    function    GetActive: TSendFileState;

    procedure   SetProgress (N: Integer);
    function    GetProgress: Integer;

    function    GetPercent: Single;

    procedure   SetAbsolute (N: Integer);
    function    GetAbsolute: Integer;

    procedure   NotifySubscribers (P: Pointer); overload;
    procedure   NotifySubscribers; overload;

    function    GetTextBefore: string;
    procedure   SetTextBefore (const Value: string);

    function    GetTextAfter: string;
    procedure   SetTextAfter (const Value: string);

    procedure   CreateTimerWindow;
    procedure   DestroyTimerWindow;

    procedure   NotifyTimer;

  public

    constructor create (aConnectionObj: IConnection); virtual;
    destructor  Destroy; override;
    procedure   release;

    property    SourceFilename: string read GetSourceFilename write SetSourceFilename;
    property    TargetFilename: string read GetTargetFilename write SetTargetFilename;
    property    TransferProtocol: TSendFileProtocol read GetTransferProtocol write SetTransferProtocol;
    property    Active: TSendFileState read GetActive write SetActive;
    property    Progress: Integer read GetProgress write SetProgress;
    property    Percent: Single read GetPercent;
    property    Absolute: Integer read GetAbsolute write SetAbsolute;
    property    Stream: TStream read GetStream write SetStream;
    property    TextBefore: string read GetTextBefore write SetTextBefore;
    property    TextAfter: string read GetTextAfter write SetTextAfter;

    procedure   TransferBegin;
    procedure   TransferEnd;
    procedure   TransferPrepare;

    procedure   Transfer (Bytes: Cardinal);

    procedure   Subscribe (Subscriber: ISubscriber);
    procedure   Unsubscribe (Subscriber: ISubscriber);

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  Messages, DebOutU, FileStreamUlfU, StrUtils;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TimerWndProc (Window: HWND; Message, wParam, lParam: Longint): Longint; stdcall;
var
  FileSender: TSendFile;
begin

  FileSender := TSendFile (GetWindowLong (Window, 0));

  case Message of

    WM_TIMER: begin
      FileSender.NotifyTimer;
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


constructor TSendFile.create (aConnectionObj: IConnection);
begin
  inherited create;
  FPacketConnection := aConnectionObj;
  FTransferProtocol := prot_unknown;
  FPublisher := TPublisher.create;
  CriticalSection := TCriticalSection.create;
end;


destructor  TSendFile.destroy;
const
  MethodName = 'destroy';

var
  FSU: TFileStreamUlf;

begin

  Debout (self, MethodName, 'begin...');

  Release;

  FPublisher.free;
  FPublisher := nil;

  if (assigned (FStream)) then begin
    if (FStream is TFileStreamUlf) then begin
      FSU := FStream as TFileStreamUlf;
      try
        if (FSU.DeleteIfTemporary) then begin
          DebOut (self, MethodName, 'Gelöscht: ' + FSU.FileName);
        end else begin
          DebOut (self, MethodName, 'Behalte: ' + FSU.FileName);
        end;
      except
        DebOut (self, MethodName, 'Fehler beim Löschen: ' + FSU.FileName);
      end;
    end;
    FStream.free;
    FStream := nil;
  end;

  CriticalSection.free;

  inherited;

  Debout (self, MethodName, 'end.');

end;


procedure   TSendFile.release;
const
  MethodName = 'release';

begin
  Debout (self, MethodName, 'begin...');
  if (assigned (FStream)) and (FStream is TFileStreamUlf) then begin
    DebOut (self, MethodName, (FStream as TFileStreamUlf).Filename);
  end;
  FPacketConnection := nil;
  FPublisher.Clear;
  DestroyTimerWindow;
  Debout (self, MethodName, 'end.');
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Property Get/Set
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSendFile.SetStream (aStream: TStream);
begin
  FStream := aStream;
end;


function    TSendFile.GetStream: TStream;
begin
  result := FStream;
end;


procedure   TSendFile.SetSourceFilename (const Name: string);
begin
  FSourceFilename := Name;
end;


function    TSendFile.GetSourceFilename: string;
begin
  result := FSourceFilename;
end;


procedure   TSendFile.SetTargetFilename (const Name: string);
var
  I: Integer;
begin
  FTargetFilename := ExtractFileName (Name);
  for I := 1 to Length (FTargetFilename) do begin
    if (FTargetFilename[I] in [#$00..#$1F, #$7F, #$81..#$A0, #$FF, '<', '>', ':', '"', '/', '\', '|', '?', '*']) then begin
      FTargetFilename[I] := '_';
    end;
  end;
end;


function    TSendFile.GetTargetFilename: string;
begin
  if (Length (FTargetFilename) = 0) then SetTargetFilename (FSourceFilename);
  result := FTargetFilename;
end;


procedure   TSendFile.SetTransferProtocol (TransferProtocol: TSendFileProtocol);
const
  MethodName = 'SetTransferProtocol';
begin
  if (FTransferProtocol <> prot_unknown) then begin
    DebOut (self, MethodName, 'WARNUNG: FileSender.TransferProtocol sollte nur einmal gesetzt werden.');
  end;
  FTransferProtocol := TransferProtocol;
end;


function    TSendFile.GetTransferProtocol: TSendFileProtocol;
begin
  result := FTransferProtocol;
end;


procedure   TSendFile.SetActive (aActive: TSendFileState);
begin
  if (FActive <> aActive) then FActive := aActive;
  NotifySubscribers;
end;


function    TSendFile.GetActive: TSendFileState;
begin
  result := FActive;
end;


procedure   TSendFile.SetProgress (N: Integer);
var
  P: Single;

begin

  if (FProgress <> N) then begin

    FProgress := N;

    if (FActive >= fts_transferring) then begin

      if (FAbsolute <= 0) then begin
        P := 0;
      end else if (FProgress >= FAbsolute) then begin
        P := 100;
      end else begin
        P := (FProgress / FAbsolute * 1000) / 10;
      end;

      if (P <> FPercent) then begin
        FPercent := P;
        NotifySubscribers;
      end;

    end;

  end;

end;


function    TSendFile.GetProgress: Integer;
begin
  result := FProgress;
end;


function    TSendFile.GetPercent: Single;
begin
  result := FPercent;
end;


procedure   TSendFile.SetAbsolute (N: Integer);
begin
  if (FAbsolute <> N) then begin
    FAbsolute := N;
    if (FActive >= fts_transferring) then NotifySubscribers;
  end;
end;


function    TSendFile.GetAbsolute: Integer;
begin
  result := FAbsolute;
end;


function    TSendFile.GetTextBefore: string;
begin
  Result := FTextBefore;
end;


procedure   TSendFile.SetTextBefore (const Value: string);
var
  L: Integer;
begin
  FTextBefore := TrimLeft (Value);
  L := Length (FTextBefore);
  if (L > 0) and (FTextBefore[L] >= #32) then FTextBefore := FTextBefore + #13;
end;


function    TSendFile.GetTextAfter: string;
begin
  Result := FTextAfter;
end;


procedure   TSendFile.SetTextAfter (const Value: string);
var
  L: Integer;
begin
  FTextAfter := TrimRight (Value);
  L := Length (FTextAfter);
  if (L > 0) and (FTextAfter[L] >= #32) then FTextAfter := FTextAfter + #13;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Transfer...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSendFile.TransferPrepare;
begin
  Progress := 0;
  Active := fts_preparing;
  NotifySubscribers;
end;


procedure   TSendFile.TransferBegin;
var
  I: Integer;

begin

  Progress := 0;
  Active := fts_transferring;
  NotifySubscribers;

  for I := Low (BytesPerSec) to High (BytesPerSec) do BytesPerSec[I] := 0;

  TransferTotal := 0;
  StartCalc := false;

  TimeWindow := -1;

  CreateTimerWindow;
  SetTimer (TimerWindow, 0, 1000, nil);

end;


procedure   TSendFile.TransferEnd;
begin

  FPacketConnection.Status.EffectiveBaudrate := 0;

  KillTimer (TimerWindow, 0);
  DestroyTimerWindow;

  Active := fts_inactive;

end;


procedure   TSendFile.Transfer (Bytes: Cardinal);
var
  T: DWord;
  K: Integer;

begin

  inc (TransferTotal, Bytes);

  if (not StartCalc) then begin

    if (TransferTotal > 14 * 256) then begin
      StartCalc := true;
      StartTime := GetTickCount div 1000;
      LastTime := StartTime;
    end;

  end else begin

    T := GetTickCount div 1000 - StartTime;
    CriticalSection.Enter;
    try
      for K := LastTime + 1 to T do begin
        BytesPerSec [K mod (High (BytesPerSec) + 1)] := 0;
      end;
      Inc (BytesPerSec[T mod (High (BytesPerSec) + 1)], Bytes);
      LastTime := T;
    finally
      CriticalSection.Leave;
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSendFile.Subscribe (Subscriber: ISubscriber);
begin
  FPublisher.Subscribe (Subscriber);
end;


procedure   TSendFile.Unsubscribe (Subscriber: ISubscriber);
begin
  FPublisher.Unsubscribe (Subscriber);
end;


procedure   TSendFile.NotifySubscribers (P: Pointer);
begin
  FPublisher.NotifySubscribers (P);
end;


procedure   TSendFile.NotifySubscribers;
begin
  NotifySubscribers (Pointer (self as ISendFile));
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSendFile.CreateTimerWindow;
var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
  TimerWindowClass: TWndClass;
  TimerWindowClassName: String;

begin

  TimerWindowClassName := 'DateiTransferTimerWindow';

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


procedure   TSendFile.DestroyTimerWindow;
begin
  if (TimerWindow <> 0) then begin
    KillTimer (TimerWindow, 0);
    DestroyWindow (TimerWindow);
    TimerWindow := 0;
  end;
end;


procedure   TSendFile.NotifyTimer;
const
  MethodName = 'NotifyTimer';

var
  F, T, N, K, CN: Integer;

begin

  // once per second

  T := (GetTickCount div 1000 - StartTime);

  if (T > 0) then begin

    if (assigned (FPacketConnection)) and (assigned (FPacketConnection.Status)) then begin

      F := FPacketConnection.Status.Frack;
      if (F > 0) then begin
        CN := F * 21 div 10;
      end else begin
        CN := 40;
      end;

      if (CN < 20) then CN := 20;
      if (CN > T) then CN := T;
      if (CN > 299) then CN := 299;

      if (TimeWindow < 0) or (CN <= TimeWindow) then begin
        TimeWindow := CN;
      end else begin
        Inc (TimeWindow, 1);
      end;

      T := T mod (High (BytesPerSec) + 1);

      CriticalSection.Enter;
      try

        N := 0;
        for K := 1 to TimeWindow do begin
          Inc (N, BytesPerSec [T mod (High (BytesPerSec) + 1)]);
          if (T > Low(BytesPerSec)) then Dec (T) else T := High (BytesPerSec);
        end;
        N := N div TimeWindow;

        FPacketConnection.Status.EffectiveBaudrate := N * 8;

      finally
        CriticalSection.Leave;
      end;

    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

