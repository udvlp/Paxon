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


unit SendFileQueueU;


interface


uses
  Windows, SysUtils, Classes, InterfacesU, GlobalU, SyncObjs, PublisherU,
  SendFileU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TSendFileQueue = class (TInterfacedObject, ISendFileQueue, IPublisher)

  private

    FList: TInterfaceList;
    FEvent: TEvent;
    FCriticalSection: TCriticalSection;
    FPublisher: TPublisher;

    function    GetCount: Integer; virtual;
    function    GetItems(Index: Integer): ISendFile; virtual;
    function    GetEvent: TEvent; virtual;
    procedure   NotifySubscribers (P: Pointer); overload; virtual;
    procedure   NotifySubscribers; overload; virtual;

  public

    constructor create; virtual;
    destructor  Destroy; override;
    procedure   Release;

    property    Count: Integer read GetCount;
    property    Items [Index: Integer]: ISendFile read GetItems; default;
    procedure   Enqueue (FileSender: ISendFile); virtual;
    function    Dequeue: ISendFile; virtual;
    function    Current: ISendFile; virtual;
    property    Event: TEvent read GetEvent;
    function    Remove (FileSender: ISendFile): Integer; virtual;
    procedure   Lock; virtual;
    procedure   UnLock; virtual;
    procedure   Subscribe (Subscriber: ISubscriber); virtual;
    procedure   Unsubscribe (Subscriber: ISubscriber); virtual;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TSendFileQueue.create;
const
  MethodName = 'create';
begin
  inherited;
  FCriticalSection := TCriticalSection.create;
  FList := TInterfaceList.create;
  FEvent := TEvent.Create (nil, true, false, '');
  FPublisher := TPublisher.create;
end;


destructor  TSendFileQueue.destroy;
const
  MethodName = 'destroy';

begin
  DebOut (self, MethodName, 'begin...');
  Release;
  FPublisher.free;
  FEvent.free;
  FCriticalSection.free;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileQueue.Release;
const
  MethodName = 'Release';

var
  I: Integer;
  D: ISendFile;

begin

  DebOut (self, MethodName, 'begin...');

  FPublisher.Clear;

  FCriticalSection.Enter;
  try
    FEvent.ResetEvent;
    if (assigned (FList)) then begin
      for I := FList.Count - 1 downto 0 do begin
        D := FList.Items[I] as ISendFile;
        D.Release;
        D := nil;
        FList.delete (I);
      end;
      FList.free;
      FList := nil;
    end;
  finally
    FCriticalSection.Leave;
  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TSendFileQueue.Lock;
const
  MethodName = 'Lock';
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileQueue.UnLock;
const
  MethodName = 'UnLock';
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Leave;
  DebOut (self, MethodName, 'end.');
end;


function    TSendFileQueue.GetCount: Integer;
const
  MethodName = 'GetCount';
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    result := FList.count;
  finally
    FCriticalSection.Leave;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    TSendFileQueue.GetItems (Index: Integer): ISendFile;
const
  MethodName = 'GetItems';
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    result := FList.items[Index] as ISendFile;
  finally
    FCriticalSection.Leave;
  end;
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileQueue.EnQueue (FileSender: ISendFile);
const
  MethodName = 'EnQueue';
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    assert (FList.IndexOf (FileSender) < 0);
    FList.Add (FileSender);
    FEvent.SetEvent;
  finally
    FCriticalSection.Leave;
  end;
  NotifySubscribers;
  DebOut (self, MethodName, 'end.');
end;


function    TSendFileQueue.DeQueue: ISendFile;
const
  MethodName = 'DeQueue';
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    assert (FList.Count >= 1);
    result := FList.Items[0] as ISendFile;
    FList.delete (0);
    if FList.Count <= 0 then FEvent.ResetEvent;
  finally
    FCriticalSection.Leave;
  end;
  NotifySubscribers;
  DebOut (self, MethodName, 'end.');
end;


function    TSendFileQueue.Current: ISendFile;
const
  MethodName = 'Current';
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    assert (FList.Count >= 1);
    result := FList.Items[0] as ISendFile;
  finally
    FCriticalSection.Leave;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    TSendFileQueue.Remove (FileSender: ISendFile): Integer;
const
  MethodName = 'Remove';
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    Result := FList.remove (FileSender);
    if (FList.Count <= 0) then FEvent.ResetEvent;
  finally
    FCriticalSection.Leave;
  end;
  if (Result >= 0) then NotifySubscribers;
  DebOut (self, MethodName, 'end.');
end;


function    TSendFileQueue.GetEvent: TEvent;
begin
  result := FEvent;
end;


procedure   TSendFileQueue.Subscribe (Subscriber: ISubscriber);
const
  MethodName = 'Subscribe';
begin
  DebOut (self, MethodName, 'begin...');
  FPublisher.Subscribe (Subscriber);
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileQueue.Unsubscribe (Subscriber: ISubscriber);
const
  MethodName = 'Unsubscribe';
begin
  DebOut (self, MethodName, 'begin...');
  FPublisher.Unsubscribe (Subscriber);
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileQueue.NotifySubscribers (P: Pointer);
const
  MethodName = 'NotifySubscribers';
begin
  DebOut (self, MethodName, 'begin...');
  FPublisher.NotifySubscribers (P);
  DebOut (self, MethodName, 'end.');
end;


procedure   TSendFileQueue.NotifySubscribers;
begin
  NotifySubscribers (Pointer (self as ISendFileQueue));
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

