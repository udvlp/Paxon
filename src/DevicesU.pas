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


unit DevicesU;


interface


uses
  Classes, Windows, SysUtils, ComCtrls,
  GlobalU, InterfacesU, DeviceU, UnhandledExceptionU, SettingsU, PublisherU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TDevices = class (TInterfacedObject, IPublisher)

  private

    FPublisher: TPublisher;

  public

    Quantity: Integer;
    DeviceItem: Array[0..31] of TDevice;  // loading and adding respect the limit

    constructor Create; virtual;
    destructor  Destroy; override;

    procedure   Save;
    procedure   StatusChange (aDeviceObj: TDevice);
    function    CreateDevice (aDeviceClass: TDeviceClass): TDevice;
    procedure   Update;
    function    RadioChannels (var aRadioChannels: Array of IRadioChannel): Integer;

    procedure   subscribe (Subscriber: ISubscriber);
    procedure   unsubscribe (Subscriber: ISubscriber);
    procedure   NotifySubscribers (P: Pointer);

  end;


var
  DeviceList: TDevices;

  DeviceClasses: array of TDeviceClass;

procedure   RegisterDevice (aDeviceClass: TDeviceClass);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, Registry, MainU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TDevices.Create;
const
  MethodName = 'Create';
var
  Registry: TRegistry;
  SL: TStringList;
  I, N: Integer;
  S, T: String;
  C: TDeviceClass;
  G: TDevice;

begin

  inherited;

  DebOut (self, MethodName, 'begin...');

  FPublisher := TPublisher.create;

  SL := TStringList.Create;

  try

    Registry := TRegistry.Create (KEY_READ);

    try

      Registry.RootKey := HKEY_CURRENT_USER;
      Registry.OpenKey (RootRegKey + '\Devices', true);
      Registry.GetKeyNames (SL);
      Registry.CloseKey;

      Quantity := 0;
      for N := 0 to SL.Count - 1 do begin

        S := RootRegKey + '\Devices\' + SL.Strings[N];
        T := '';
        if Registry.OpenKey (S, true) then begin
          try
            T := Registry.ReadString ('');
          except
          end;
          Registry.CloseKey;
        end;

        // The device's class name is stored. Older versions wrote '1'/'2',
        // versions before 3.0 the German class names.
        if (T = '1') or SameText (T, 'TGeraetFlexnet') then begin
          T := 'TFlexnetDevice';
        end else if (T = '2') or SameText (T, 'TGeraetHostmode') or SameText (T, 'TGeraetHostmodeSerial') then begin
          T := 'THostmodeSerialDevice';
        end else if SameText (T, 'TGeraetHostmodeTFWin') then begin
          T := 'THostmodeTFWinDevice';
        end;
        // Devices of unknown classes (e.g. the removed AGWPE) are skipped;
        // on the next save (TDevices.Save) they disappear from the registry.

        C := nil;
        for I := 0 to (Length (DeviceClasses) - 1) do begin
          if (CompareText (DeviceClasses[I].ClassName, T) = 0) then begin
            C := DeviceClasses[I];
          end;
        end;

        if (assigned (C)) and (Quantity <= High (DeviceItem)) then begin
          G := nil;
          try
            G := CreateDevice (C);
          except
          end;
          if (assigned (G)) then begin
            // Assign the key right here: the index in SL no longer matches the
            // device index as soon as a device has been skipped.
            G.RegKey := S;
            DeviceItem[Quantity] := G;
            Inc (Quantity);
          end;
        end;

      end;

      Update;

      for N := 0 to Quantity - 1 do begin
        DeviceItem[N].Restore;
        DeviceItem[N].Init;
        DeviceItem[N].No := N;
      end;

    finally

      Registry.Free;

    end;

  finally

    SL.Free;

  end;

  DebOut (self, MethodName, 'end.');

end;


destructor  TDevices.Destroy;
const
  MethodName = 'Destroy';

var
  N: Integer;

begin

  DebOut (self, MethodName, 'begin...');

  for N := 0 to Quantity - 1 do begin

    try
      DeviceItem[N].DeInit;
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'DeInit');
        raise;
      end;
    end;

    try
      DeviceItem[N].Free;
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'Free');
        raise;
      end;
    end;

    DeviceItem[N] := nil;

  end;

  FPublisher.Free;

  inherited;

  DebOut (self, MethodName, 'Destroy: end.');

end;


procedure   TDevices.Save;
const
  MethodName = 'Save';

var
  Registry: TRegistry;
  N: Integer;
  HasError: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  HasError := false;

  Registry := TRegistry.Create (KEY_READ or KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    try
      Registry.DeleteKey (RootRegKey + '\Devices');
    except
      HasError := true;
    end;
  finally
    Registry.Free;
  end;

  if (not HasError) then begin
    for N := 0 to Quantity - 1 do begin
      DeviceItem[N].RegKey := RootRegKey + '\Devices\' + IntToStr(N);
      try
        DeviceItem[N].Save;
      except
      end;
    end;
  end;

  DebOut (self, MethodName, 'end.');

end;


function    TDevices.CreateDevice (aDeviceClass: TDeviceClass): TDevice;
begin
  Result := aDeviceClass.create;
end;


procedure   TDevices.StatusChange (aDeviceObj: TDevice);
const
  MethodName = 'StatusChange';

var
  N: Integer;
  B: Boolean;

begin


  NotifySubscribers (aDeviceObj);

  if aDeviceObj.Status = gs_ready then begin

    B := False;

    for N := 0 to Quantity - 1 do begin

      if (assigned (DeviceItem[N])) then begin
        if (DeviceItem[N].Status <> gs_ready) then begin
          B := True;
          break;
        end;
      end else begin
        DebOut (self, MethodName, 'Gerät = nil');
      end;

    end;

  end else begin
    B := True;
  end;
  MainWindow.DevicesReady (B);


end;


procedure   TDevices.Update;
var
  N: Integer;
begin
  NotifySubscribers (nil);
  for N := 0 to Quantity - 1 do begin
    DeviceItem[N].No := N;
    StatusChange (DeviceItem[N]);
  end;
end;


function    TDevices.RadioChannels (var aRadioChannels: Array of IRadioChannel): Integer;
var
  RadioChannelCount: Integer;
  N, I, K: Integer;
  A: Array[0..32] of IRadioChannel;
begin
  RadioChannelCount := 0;
  for N := 0 to Quantity - 1 do begin
    K := DeviceItem[N].RadioChannels (A);
    for I := 0 to K - 1 do begin
      if (RadioChannelCount > High (aRadioChannels)) then break;
      aRadioChannels[RadioChannelCount] := A[I];
      Inc (RadioChannelCount);
    end;
  end;
  Result := RadioChannelCount;
end;


procedure   TDevices.subscribe (Subscriber: ISubscriber);
begin
  FPublisher.subscribe (Subscriber);
end;


procedure   TDevices.unsubscribe (Subscriber: ISubscriber);
begin
  FPublisher.unsubscribe (Subscriber);
end;


procedure   TDevices.NotifySubscribers (P: Pointer);
begin
  FPublisher.NotifySubscribers (P);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   RegisterDevice (aDeviceClass: TDeviceClass);
var
  I: Integer;
begin
  I := Length (DeviceClasses);
  SetLength (DeviceClasses, I + 1);
  DeviceClasses[I] := aDeviceClass;
  DebOut ('RegisterDevice: %d: %s', [Length (DeviceClasses), DeviceClasses[I].Name]);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

