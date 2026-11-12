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


unit RadioChannelU;


interface


uses
  Classes, Windows, SysUtils, Messages,
  Forms,
  InterfacesU, DeviceU, DevicesU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TRadioChannel = class (TInterfacedObject, IRadioChannel)
  private
    FOwnerDevice: TDevice;
    FName: String;
    FHandle: Integer;
    FID: String;
    function    GetName: String;
    procedure   SetName (S: String);
    procedure   SetHandle (aHandle: Integer);
    function    GetHandle: Integer;
    function    GetID: String;
    procedure   SetID (const Value: String);
  public
    constructor Create (aDeviceObj: TDevice); reintroduce; virtual;
    destructor  Destroy; override;
    function    EstablishConnection (var aCall: String; var aMyCall: String; var aChannelObj: IChannel): TConnectError; overload;
    function    EstablishConnection (var aCall: String; var aMyCall: String; var aChannelObj: IChannel;
                                     var Connection: IConnection): TConnectError; overload;
    property    Handle: Integer read GetHandle write SetHandle;
    property    Name: String read GetName write SetName;
    function    IsFlexNet: Boolean;
    property    ID: String read GetID write SetID;
    function    SendUI (aDestination, aMyCall, aText: String): Boolean;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  ConnectionU, FlexnetDeviceU, ChannelsU, DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TRadioChannel.Create (aDeviceObj: TDevice);
begin
  inherited Create;
  FOwnerDevice := aDeviceObj;
end;


destructor  TRadioChannel.Destroy;
begin
  inherited;
end;


function    TRadioChannel.EstablishConnection (var aCall: String; var aMyCall: String; var aChannelObj: IChannel): TConnectError;
var
  Connection: IConnection;
begin
  Connection := nil;
  result := EstablishConnection (aCall, aMyCall, aChannelObj, Connection);
  Connection := nil;
end;


function    TRadioChannel.EstablishConnection (var aCall: String; var aMyCall: String; var aChannelObj: IChannel;
                                               var Connection: IConnection): TConnectError;
const
  MethodName = 'EstablishConnection';
var
  B: Boolean;
begin
  DebOut (self, MethodName, 'begin...');
  if (assigned (FOwnerDevice)) then begin
    B := false;
    if (not assigned (aChannelObj)) or (not aChannelObj.IsOutgoingConnectionPossible) then begin
      aChannelObj := ChannelList.NextFreeChannel;
      B := true;
    end;
    if (assigned (aChannelObj)) then begin
      result := FOwnerDevice.EstablishConnection (self, aCall, aMyCall, aChannelObj, Connection);
      if (result <> vf_ok) and (B) then aChannelObj.IsReserved := false;
    end else begin
      result := vf_nofreechannel;
    end;
  end else begin
    Result := vf_nodevice;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    TRadioChannel.SendUI (aDestination, aMyCall, aText: String): Boolean;
const
  MethodName = 'SendUI';
var
  S: String;
begin
  DebOut (self, MethodName, 'begin...');
  if (assigned (FOwnerDevice)) then begin
    S := aText;
    while (Length (S) > 0) do begin
      FOwnerDevice.SendUI (self, aDestination, aMyCall, Copy (S, 1, 256));
      Delete (S, 1, 256);
    end;
    result := true;
  end else begin
    result := false;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    TRadioChannel.GetName: String;
begin
  Result := FName;
end;


procedure   TRadioChannel.SetName (S: String);
begin
  FName := S;
end;


procedure   TRadioChannel.SetHandle (aHandle: Integer);
begin
  FHandle := aHandle;
end;


function    TRadioChannel.GetHandle: Integer;
begin
  Result := FHandle;
end;


function    TRadioChannel.IsFlexNet: Boolean;
begin
  result := FOwnerDevice is TFlexnetDevice;
end;


function    TRadioChannel.GetID: String;
begin
  result := FID;
end;


procedure   TRadioChannel.SetID (const Value: String);
begin
  FID := Value;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

