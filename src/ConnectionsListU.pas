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


unit ConnectionsListU;


interface


uses
  Classes, Windows, SysUtils, Messages, SyncObjs, Registry,
  GlobalU, InterfacesU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionsList = class
  private
    CriticalSection: TCriticalSection;
    List: TInterfaceList;
    function    GetItem (Index: Integer): IConnection;
  public
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   Add (PacketConnection: IConnection);
    procedure   Remove (PacketConnection: IConnection);
    function    Count: Integer;
    property    Items [Index: Integer]: IConnection read GetItem; default;
    procedure   Lock;
    procedure   Unlock;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  ConnectionsList: TConnectionsList = nil;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionsList.AfterConstruction;
const
  MethodName = 'AfterConstruction';
begin

  DebOut (self, MethodName, 'begin...');

  inherited;

  assert (not assigned (ConnectionsList));
  ConnectionsList := self;

  CriticalSection := TCriticalSection.create;

  List := TInterfaceList.create;

  DebOut (self, MethodName, 'end.');

end;


procedure   TConnectionsList.BeforeDestruction;
const
  MethodName = 'BeforeDestruction';
begin
  DebOut (self, MethodName, 'begin...');
  List.free;
  CriticalSection.free;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


procedure   TConnectionsList.Add (PacketConnection: IConnection);
var
  I: Integer;
begin
  CriticalSection.Enter;
  try
    I := List.IndexOf (PacketConnection);
    if (I < 0) then begin
      List.Add (PacketConnection);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TConnectionsList.Remove (PacketConnection: IConnection);
var
  I: Integer;
begin
  CriticalSection.Enter;
  try
    I := List.IndexOf (PacketConnection);
    if (I >= 0) then begin
      List.Delete (I);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


function    TConnectionsList.Count: Integer;
begin
  CriticalSection.Enter;
  try
    result := List.Count;
  finally
    CriticalSection.Leave;
  end;
end;


function    TConnectionsList.GetItem (Index: Integer): IConnection;
begin
  CriticalSection.Enter;
  try
    result := List.Items[Index] as IConnection;
  finally
    CriticalSection.Leave;
  end;
end;


procedure TConnectionsList.Lock;
begin
  CriticalSection.Enter;
end;


procedure TConnectionsList.Unlock;
begin
  CriticalSection.Leave;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

