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


unit QueueU;


interface


uses
  SyncObjs, Classes;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  PQueueElem = ^TQueueElem;
  TQueueElem = record
    Data: Pointer;
    Next: PQueueElem;
  end;


  TQueue = class
  private
    FEvent: TEvent;
    FCriticalSection: TCriticalSection;
    FEnd: PQueueElem;
    FBegin: PQueueElem;
    FCount: Integer;
    FEmptyEvent: TEvent;
    function GetCount: Integer;
  protected
    procedure   DisposeData (aData: Pointer); virtual;
  public
    constructor create; virtual;
    destructor  Destroy; override;
    procedure   enqueue (aData: Pointer); virtual;
    function    dequeue: Pointer; virtual;
    procedure   undequeue (aData: Pointer); virtual;
    function    current: Pointer; virtual;
    function    isEmpty: Boolean; virtual;
    property    Event: TEvent read FEvent;
    property    EmptyEvent: TEvent read FEmptyEvent;
    procedure   Clear;
    property    Count: Integer read GetCount;
  end;


  TStringQueue = class (TQueue)
  protected
    procedure   DisposeData (aData: Pointer); override;
  public
    procedure   enqueue (const S: String); reintroduce; virtual;
    function    dequeue: String; reintroduce; virtual;
    function    dequeuePacket (var Packet: String; Len: Integer): Integer; virtual;
    function    dequeueLine: String; virtual;
    function    current: String; reintroduce; virtual;
    procedure   undequeue (const S: String); reintroduce; virtual;
  end;


  TStringAndCommandQueue = class (TQueue)
  protected
    procedure   DisposeData (aData: Pointer); override;
  public
    procedure   enqueue (const S: String; C: LongInt); reintroduce; virtual;
    procedure   dequeue (var S: String; var C: LongInt); reintroduce; virtual;
    procedure   current (var S: String; var C: LongInt); reintroduce; virtual;
  end;


  TInterfaceQueue = class (TQueue)
  protected
    procedure   DisposeData (aData: Pointer); override;
  public
    procedure   enqueue (Intf: IUnknown); reintroduce; virtual;
    function    dequeue: IUnknown; reintroduce; virtual;
    procedure   undequeue (Intf: IUnknown); reintroduce; virtual;
    function    current: IUnknown; reintroduce; virtual;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  SysUtils;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TQueue.create;
begin
  inherited;
  FEvent := TEvent.create (nil, true, false, '');
  FEmptyEvent := TEvent.create (nil, true, true, '');
  FCriticalSection := TCriticalSection.create;
  FEnd := nil;
  FBegin := nil;
  FCount := 0;
end;


destructor  TQueue.destroy;
begin
  Clear;
  FCriticalSection.free;
  FEmptyEvent.free;
  FEvent.free;
  inherited;
end;


function    TQueue.isEmpty: Boolean;
begin
  FCriticalSection.Enter;
  result := (FCount = 0);
  FCriticalSection.Leave;
end;


function TQueue.GetCount: Integer;
begin
  FCriticalSection.Enter;
  result := FCount;
  FCriticalSection.Leave;
end;


procedure   TQueue.enqueue (aData: Pointer);
var
  E: PQueueElem;
begin
  FCriticalSection.Enter;
  try
    New (E);
    E^.Data := aData;
    E^.Next := nil;
    if assigned (FEnd) then FEnd.Next := E;
    FEnd := E;
    if (FBegin = nil) then FBegin := FEnd;
    if (FCount = 0) then begin
      FEvent.SetEvent;
      FEmptyEvent.ResetEvent;
    end;
    inc (FCount);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TQueue.undequeue (aData: Pointer);
var
  E: PQueueElem;
begin
  FCriticalSection.Enter;
  try
    New (E);
    E^.Data := aData;
    E^.Next := FBegin;
    FBegin := E;
    if (FEnd = nil) then FEnd := FBegin;
    if (FCount = 0) then begin
      FEvent.SetEvent;
      FEmptyEvent.ResetEvent;
    end;
    inc (FCount);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TQueue.dequeue: Pointer;
var
  E: PQueueElem;
begin
  FCriticalSection.Enter;
  try
    if (FBegin = nil) then begin
      result := nil;
    end else begin
      E := FBegin;
      result := FBegin.Data;
      FBegin := FBegin.next;
      if (E = FEnd) then FEnd := nil;
      Dispose (E);
      dec (FCount);
      if (FCount = 0) then begin
        FEvent.ResetEvent;
        FEmptyEvent.SetEvent;
      end;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TQueue.current: Pointer;
begin
  FCriticalSection.Enter;
  try
    if (FBegin = nil) then begin
      result := nil;
    end else begin
      result := FBegin.Data;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TQueue.DisposeData (aData: Pointer);
begin
  // TQueue does not know the type of the elements; their owner must dispose of them itself.
end;


procedure   TQueue.Clear;
begin
  FCriticalSection.Enter;
  try
    // TQueue.dequeue (the subclasses introduce their own dequeue but do not override it)
    while (FBegin <> nil) do DisposeData (dequeue);
  finally
    FCriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TStringQueue.enqueue (const S: String);
var
  P: PString;
begin
  FCriticalSection.Enter;
  try
    if (Length (S) > 0) then begin
      New (P);
      P^ := S;
      inherited enqueue (P);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStringQueue.undequeue (const S: String);
var
  P: PString;
begin
  FCriticalSection.Enter;
  try
    New (P);
    P^ := S;
    inherited undequeue (P);
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStringQueue.dequeue: String;
var
  P: PString;
begin
  FCriticalSection.Enter;
  try
    P := inherited dequeue;
    assert (assigned (P));
    result := P^;
    dispose (P);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStringQueue.DisposeData (aData: Pointer);
begin
  Dispose (PString (aData));
end;


function    TStringQueue.current: string;
begin
  FCriticalSection.Enter;
  try
    result := PString (inherited current)^;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStringQueue.dequeuePacket (var Packet: String; Len: Integer): Integer;
var
  P: PString;
  L: Integer;
begin
  FCriticalSection.Enter;
  try
    assert (not isEmpty);
    P := inherited current;
    L := Length (P^);
    if Len < L then begin
      Packet := Copy (P^, 1, Len);
      delete (P^, 1, Len);
      Result := Len;
    end else begin
      Packet := dequeue;
      Result := L;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStringQueue.dequeueLine: String;
var
  P: PString;
  N: Integer;
begin
  FCriticalSection.Enter;
  try
    assert (not isEmpty);
    P := inherited current;
    if (P = nil) then begin
      result := '';
    end else begin
      N := Pos (#13, P^);
      if (N > 0) then begin
        result := Copy (P^, 1, N);
        Delete (P^, 1, N);
        if Length (P^) = 0 then dequeue;
      end else begin
        result := P^;
        dequeue;
      end;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  PSC = ^TSC;
  TSC = record
    S: String;
    C: LongInt;
  end;


procedure   TStringAndCommandQueue.enqueue (const S: String; C: LongInt);
var
  P: PSC;
begin
  FCriticalSection.Enter;
  try
    New (P);
    P^.S := S;
    P^.C := C;
    inherited enqueue (P);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStringAndCommandQueue.dequeue (var S: String; var C: LongInt);
var
  P: PSC;
begin
  FCriticalSection.Enter;
  try
    P := inherited dequeue;
    assert (assigned (P));
    S := P^.S;
    C := P^.C;
    dispose (P);
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStringAndCommandQueue.DisposeData (aData: Pointer);
begin
  Dispose (PSC (aData));
end;


procedure   TStringAndCommandQueue.current (var S: String; var C: LongInt);
var
  P: PSC;
begin
  FCriticalSection.Enter;
  try
    P := PSC (inherited current);
    S := P^.S;
    C := P^.C;
  finally
    FCriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TInterfaceQueue.DisposeData (aData: Pointer);
begin
  IUnknown (aData)._Release;
end;


function    TInterfaceQueue.current: IUnknown;
begin
  result := IUnknown (inherited current);
end;


function    TInterfaceQueue.dequeue: IUnknown;
begin
  result := IUnknown (inherited dequeue);
  result._release;
end;


procedure   TInterfaceQueue.enqueue (Intf: IUnknown);
begin
  Intf._addref;
  inherited enqueue (Pointer (Intf));
end;


procedure   TInterfaceQueue.undequeue (Intf: IUnknown);
begin
  Intf._addref;
  inherited undequeue (Pointer (Intf));
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

