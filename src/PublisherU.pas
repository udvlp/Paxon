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


unit PublisherU;


interface


uses
  Windows, SysUtils, Classes, SyncObjs;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type


  ISubscriber = interface ['{6B3211A0-587F-11D2-A5B9-AEFA21EDC335}']
    procedure   notify (P: Pointer);
  end;


  IPublisher = interface ['{6B3211A1-587F-11D2-A5B9-AEFA21EDC335}']
    procedure   Subscribe (Subscriber: ISubscriber);
    procedure   Unsubscribe (Subscriber: ISubscriber);
  end;


  TPublisher = class (TInterfacedObject, IPublisher)
  private
    Subscribers: TInterfaceList;
    CriticalSection: TCriticalSection;
  public
    constructor create; virtual;
    destructor  Destroy; override;
    procedure   subscribe (Subscriber: ISubscriber);
    procedure   unsubscribe (Subscriber: ISubscriber);
    procedure   NotifySubscribers (P: Pointer);
    procedure   Clear;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TPublisher.create;
begin
  inherited;
  CriticalSection := TCriticalSection.create;
  Subscribers := TInterfaceList.Create;
end;


destructor  TPublisher.destroy;
begin
  Subscribers.Free;
  CriticalSection.Free;
  inherited;
end;


procedure   TPublisher.subscribe (Subscriber: ISubscriber);
const
  MethodName = 'Subscribe';
begin
  CriticalSection.Enter;
  try
    if (Subscribers.IndexOf (Subscriber) < 0) then begin
      Subscribers.Add (Subscriber);
      DebOut (self, MethodName, 'Subscribe ' + IntTohex (Integer(Pointer(Subscriber)), 8));
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TPublisher.unsubscribe (Subscriber: ISubscriber);
const
  MethodName = 'Unsubscribe';
var
  I: Integer;
begin
  CriticalSection.Enter;
  try
    I := Subscribers.Remove (Subscriber);
    if (I >= 0) then begin
      DebOut (self, MethodName, 'Unsubscribed ' + IntTohex (Integer(Pointer(Subscriber)), 8));
    end else begin
      DebOut (self, MethodName, 'Not unsubscribed ' + IntTohex (Integer(Pointer(Subscriber)), 8));
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TPublisher.NotifySubscribers (P: Pointer);
var
  I, N: Integer;
  Subscr: array[0..15] of ISubscriber;

begin

  CriticalSection.Enter;
  try
    N := Subscribers.Count - 1;
    assert (N <= 15);
    for I := 0 to N do begin
      Subscr[I] := Subscribers.Items[I] as ISubscriber;
    end;
  finally
    CriticalSection.Leave;
  end;

  for I := 0 to N do begin
    Subscr[I].notify (P);
  end;

end;


procedure   TPublisher.Clear;
begin
  Subscribers.Clear;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.
