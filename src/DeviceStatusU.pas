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


unit DeviceStatusU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, PublisherU, DevicesU, DeviceU, FormU, ComCtrls,
  Dialogs, GlobalU, InterfacesU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TDevicesStatusSubscriber = class;


  TDevicesStatus = class (TFormUlf)
    Listview: TListView;
    procedure    FormShow (Sender: TObject);
    procedure    FormHide (Sender: TObject);
    procedure    FormCreate (Sender: TObject);
    procedure    FormDestroy (Sender: TObject);
  private
    FWidth: Integer;
    Subscriber: ISubscriber;
    procedure    FormClose (Sender: TObject; var Action: TCloseAction);
    procedure    wmGetMinMaxInfo   (var Msg: TMessage); message wm_getminmaxinfo;
    procedure    Notify (DeviceItem: TDevice); virtual;
  end;


  TDevicesStatusSubscriber = class (TInterfacedObject, ISubscriber)
  public
    procedure    Notify (P: Pointer); virtual;
  end;


var
  DevicesStatus: TDevicesStatus = nil;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}

uses
  Registry, MainU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDevicesStatus.FormCreate (Sender: TObject);
var
  X, Y: Integer;
  Registry: TRegistry;

begin

  Registry := TRegistry.Create (KEY_READ or KEY_WRITE);
  Registry.RootKey := HKEY_CURRENT_USER;
  Registry.OpenKey (RootRegKey + '\Windows\DeviceStatus', true);
  try
    X := Registry.ReadInteger ('X');
    Y := Registry.ReadInteger ('Y');
    if (X > Screen.Width - Width) then X := Screen.Width - Width;
    if (X < 0) then X := 0;
    if (Y > Screen.Height - Height) then Y := Screen.Height - Height;
    if (Y < 0) then Y := 0;
    left := X;
    top := Y;
  except
    Position := poScreenCenter;
  end;
  Registry.CloseKey;
  Registry.Free;

  Subscriber := TDevicesStatusSubscriber.Create;

  // Im Code statt in den DFMs (auch die der Sprach-DLLs) zugewiesen.
  OnClose := FormClose;

end;


procedure   TDevicesStatus.FormClose (Sender: TObject; var Action: TCloseAction);
begin
  // Mit [X] geschlossen wurde das Fenster vorher nur versteckt, FormHide setzte
  // aber DevicesStatus auf nil: Jedes Öffnen legte eine neue Instanz an, und
  // die Position wurde erst beim Programmende (aus der ältesten) gespeichert.
  Action := caFree;
end;


procedure   TDevicesStatus.FormShow (Sender: TObject);
begin
  FWidth := Width;
  MainWindow.ActionDeviceStatus.Checked := true;
  if (assigned (DeviceList)) then begin
    Notify (nil);
    DeviceList.Subscribe (Subscriber);
  end;
end;


procedure   TDevicesStatus.FormDestroy (Sender: TObject);
var
  Registry: TRegistry;

begin

  Subscriber := nil;

  Registry := TRegistry.Create (KEY_READ or KEY_WRITE);
  Registry.RootKey := HKEY_CURRENT_USER;
  if (Registry.OpenKey (RootRegKey + '\Windows\DeviceStatus', true)) then begin
    try
      Registry.WriteInteger ('X', left);
      Registry.WriteInteger ('Y', top);
    except
    end;
    Registry.CloseKey;
  end;
  Registry.Free;

end;


procedure   TDevicesStatus.FormHide (Sender: TObject);
begin
  if (assigned (DeviceList)) then begin
    DeviceList.Unsubscribe (Subscriber);
  end;
  MainWindow.ActionDeviceStatus.Checked := false;
  DevicesStatus := nil;
end;


procedure   TDevicesStatus.wmGetMinMaxInfo (var Msg: TMessage);
begin
  if (FWidth <> 0) then begin
    with PMinMaxInfo (Msg.lParam)^ do begin
      ptMinTrackSize.X := FWidth;
      ptMaxTrackSize.X := FWidth;
    end;
  end;
end;


procedure   TDevicesStatus.Notify (DeviceItem: TDevice);
var
  LI: TListItem;
  N: Integer;

begin

  if (assigned (DeviceItem)) then begin

    with ListView do begin
      if (Items.Count > 0) then begin
        for N := 0 to DeviceList.Quantity - 1 do begin
          if (DeviceItem = DeviceList.DeviceItem[N]) then begin
            with Items[N].SubItems do begin
              Strings[0] := DeviceItem.ParameterText;
              Strings[1] := DeviceItem.StatusText;
            end;
            break;
          end;
        end;
      end;
    end;

  end else begin

    with ListView do begin
      Items.BeginUpdate;
      Items.Clear;
      for N := 0 to DeviceList.Quantity - 1 do begin
        LI := Items.Add;
        LI.Caption := DeviceList.DeviceItem[N].Name;
        LI.SubItems.Add (DeviceList.DeviceItem[N].ParameterText);
        LI.SubItems.Add (DeviceList.DeviceItem[N].StatusText);
      end;
      Items.EndUpdate;
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDevicesStatusSubscriber.Notify (P: Pointer);
begin
  DevicesStatus.Notify (TDevice(P));
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

