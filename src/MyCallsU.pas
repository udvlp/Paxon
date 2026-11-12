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


unit MyCallsU;


interface


uses
  Classes, Windows, SysUtils, Messages, Controls, Dialogs,
  Forms, StdCtrls, ExtCtrls, ComCtrls, SyncObjs,
  InterfacesU, PublisherU, MyCallU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TMyCallsInt = class (TInterfacedObject, IPublisher)
  private

    FSelfRef: IUnknown;

    FList: TList;
    FCriticalSection: TCriticalSection;
    FPublisher: TPublisher;

    function    GetCall (Index: Integer): TMyCall;
    procedure   NotifySubscribers (P: Pointer); overload; virtual;
    procedure   NotifySubscribers; overload; virtual;
    function    GetCount: Integer; virtual;

  public

    constructor Create; virtual;
    destructor  Destroy; override;
    property    Count: Integer read GetCount;
    property    Call [Index: Integer]: TMyCall read GetCall; default;
    procedure   Assign (Source: TMyCallsInt); virtual;
    procedure   Clear; virtual;
    function    Add (aMyCall: TMyCall): Boolean; virtual;

    procedure   Subscribe (Subscriber: ISubscriber); virtual;
    procedure   Unsubscribe (Subscriber: ISubscriber); virtual;

    procedure   BeginRead; virtual;
    procedure   EndRead; virtual;
    procedure   BeginWrite; virtual;
    procedure   EndWrite; virtual;

    procedure   Release; virtual;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  MyCalls: TMyCallsInt;


resourcestring

  SIncomingConnectDefault = 'Standard-Einstellung';
  SIncomingConnectAccept  = 'annehmen';
  SIncomingConnectIgnore  = 'ignorieren';
  SIncomingConnectBusy    = 'abweisen';


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  Registry,
  DebOutU, GlobalU;


const
  RegKeyMycalls = RootRegKey + '\MyCalls';


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TMyCallsInt.Create;
var
  Registry: TRegistry;
  SL: TStringList;
  N, I, M: Integer;
  MyCall: TMyCall;
  S: String;

begin

  inherited;

  FSelfRef := self as IUnknown;

  FCriticalSection := TCriticalSection.create;

  FPublisher := TPublisher.create;

  FList := TList.Create;
  Registry := TRegistry.create (KEY_READ or KEY_WRITE);
  Registry.RootKey := HKEY_CURRENT_USER;
  Registry.OpenKey (RegKeyMycalls, true);
  SL := TStringList.Create;
  Registry.GetKeyNames (SL);
  Registry.CloseKey;

  for N := 0 to SL.Count - 1 do begin

    S := UpperCase (SL.Strings[N]);

    MyCall := TMyCall.create;
    MyCall.Call := S;
    MyCall.SSIDCount := 0;
    Registry.OpenKey (RegKeyMycalls + '\' + S, true);
    try
      M := Registry.ReadInteger ('SSIDs');
      for I := 0 to 15 do begin
        if ((M and 1) <> 0) then begin
          MyCall.SSID[MyCall.SSIDCount] := I;
          inc (MyCall.SSIDCount);
        end;
        M := M shr 1;
      end;
    except
    end;
    if MyCall.SSIDCount <= 0 then begin
      MyCall.SSIDCount := 1;
      MyCall.SSID[0] := 0;
    end;
    Registry.CloseKey;

    Add (MyCall);

  end;
  SL.Free;
  Registry.free;
end;


procedure   TMyCallsInt.Release;
begin
  FSelfRef := nil;
end;


destructor  TMyCallsInt.Destroy;
var
  N, I, M: Integer;
  MyCall: TMyCall;
  Registry: TRegistry;

begin

  Registry := TRegistry.create (KEY_READ or KEY_WRITE);

  Registry.RootKey := HKEY_CURRENT_USER;
  Registry.DeleteKey (RegKeyMycalls);

  for N := 0 to FList.Count - 1 do begin

    MyCall := FList.Items[N];

    Registry.OpenKey (RegKeyMycalls + '\' + MyCall.Call, true);
    M := 0;
    for I := 0 to MyCall.SSIDCount - 1 do begin
      M := M or (1 shl MyCall.SSID[I]);
    end;
    Registry.WriteInteger ('SSIDs', M);
    Registry.CloseKey;

    MyCall.Free;

  end;

  FList.Free;

  Registry.Free;

  FPublisher.free;

  FCriticalSection.free;

  inherited;

end;


function    TMyCallsInt.GetCount: Integer;
begin
  result := FList.Count;
end;


procedure   TMyCallsInt.Clear;
var
  N: Integer;
  R: TMyCall;
begin
  for N := 0 to FList.count - 1 do begin
    R := FList.Items[N];
    R.Free;
  end;
  FList.clear;
end;


function    TMyCallsInt.Add (aMyCall: TMyCall): Boolean;
begin
  assert (assigned (aMyCall));
  FList.Add (aMyCall);
  Result := true;
end;


function    TMyCallsInt.GetCall (Index: Integer): TMyCall;
begin
  result := FList.Items[Index];
end;


procedure   TMyCallsInt.Assign (Source: TMyCallsInt);
var
  N: Integer;
  R: TMyCall;
begin
  Clear;
  for N := 0 to Source.Count - 1 do begin
    R := TMyCall.create;
    R.Assign (Source.Call[N]);
    FList.Add (R);
  end;
end;


procedure   TMyCallsInt.BeginRead;
begin
  FCriticalSection.Enter;
end;


procedure   TMyCallsInt.EndRead;
begin
  FCriticalSection.Leave;
end;


procedure   TMyCallsInt.BeginWrite;
begin
  FCriticalSection.Enter;
end;


procedure   TMyCallsInt.EndWrite;
begin
  FCriticalSection.Leave;
  NotifySubscribers;
end;


procedure   TMyCallsInt.NotifySubscribers;
begin
  FPublisher.NotifySubscribers (nil);
end;


procedure   TMyCallsInt.NotifySubscribers (P: Pointer);
begin
  FPublisher.NotifySubscribers (P);
end;


procedure   TMyCallsInt.Subscribe (Subscriber: ISubscriber);
begin
  FPublisher.Subscribe (Subscriber);
end;


procedure   TMyCallsInt.Unsubscribe (Subscriber: ISubscriber);
begin
  FPublisher.Unsubscribe (Subscriber);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

