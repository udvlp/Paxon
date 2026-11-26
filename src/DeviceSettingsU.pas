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


unit DeviceSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, ComCtrls, StdCtrls, PublisherU,
  SettingsU, DeviceU, DevicesU, GlobalU, ExtCtrls,
  PanelUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TDeviceSettingsSubscriber = class;


  TDeviceSettings = class (TTabForm)
    Groupbox: TGroupBox;
    PropertiesBtn: TButton;
    AddBtn: TButton;
    RemoveBtn: TButton;
    Listview: TListView;
    DownBtn: TBitBtn;
    UpBtn: TBitBtn;

    procedure   FormCreate (Sender: TObject);
    procedure   FormDestroy (Sender: TObject);
    procedure   PropertiesBtnClick (Sender: TObject);
    procedure   RemoveBtnClick (Sender: TObject);
    procedure   AddBtnClick (Sender: TObject);
    procedure   UpBtnClick (Sender: TObject);
    procedure   ListviewDblClick (Sender: TObject);
    procedure   ListviewKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure   DownBtnClick (Sender: TObject);
    procedure   FormShow (Sender: TObject);

  private

    DeletedDevices: TList;
    AddedDevices: TList;
    Subscriber: TDeviceSettingsSubscriber;

    procedure   AddNewEntry (aDeviceObj: TDevice);
    procedure   Notify (aDeviceObj: TDevice);

  public

    procedure   ApplyPage; override;
    procedure   CancelPage; override;

  end;


  TDeviceSettingsSubscriber = class (TInterfacedObject, ISubscriber)
  private
    FDeviceSettings: TDeviceSettings;
  public
    constructor create (aDeviceSettings: TDeviceSettings); reintroduce; virtual;
    procedure   Notify (P: Pointer); virtual;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


uses
  DebOutU, AddDeviceU, MessageBoxU, MainU, FlexnetDeviceU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDeviceSettings.FormCreate (Sender: TObject);
var
  N: Integer;

begin

  with Listview do begin

    Items.Clear;
    for N := 0 to DeviceList.Quantity - 1 do begin
      AddNewEntry (DeviceList.DeviceItem[N]);
    end;

    Selected := Items[0];
    if (assigned (Selected)) then begin
      Selected.Focused := true;
    end;

  end;

  DeletedDevices := TList.Create;
  AddedDevices := TList.Create;

  Subscriber := TDeviceSettingsSubscriber.create (self);

  DeviceList.Subscribe (Subscriber);

end;


procedure   TDeviceSettings.FormDestroy (Sender: TObject);
var
  N: Integer;
begin
  if (assigned (DeviceList)) then DeviceList.Unsubscribe (Subscriber);
  DeletedDevices.Free;
  // Nach "Übernehmen" ist die Liste leer (die Geräte gehören dann der
  // Geräteliste). Nach "Abbrechen" stehen hier neu angelegte, nie übernommene
  // Geräte, die sonst niemand freigibt.
  for N := 0 to AddedDevices.Count - 1 do begin
    TDevice (AddedDevices[N]).Free;
  end;
  AddedDevices.Free;
end;


procedure   TDeviceSettings.FormShow (Sender: TObject);
begin
  if (ListView.CanFocus) then ListView.SetFocus;
  if (assigned (Listview.Items[0])) then begin
    Listview.Selected := Listview.Items[0];
    Listview.Items[0].Focused := True;
    Listview.Items[0].Selected := True;
  end;
end;


procedure   TDeviceSettings.AddNewEntry (aDeviceObj: TDevice);
var
  LI: TListItem;
begin
  with Listview do begin
    LI := Items.Add;
    LI.Caption := aDeviceObj.Name;
    LI.Data    := aDeviceObj;
    LI.SubItems.Add (aDeviceObj.ParameterText);
    LI.SubItems.Add (aDeviceObj.StatusText);
    Selected := LI;
    Selected.Focused := True;
  end;
end;


procedure   TDeviceSettings.ListviewDblClick (Sender: TObject);
begin
  inherited;
  PropertiesBtnClick (Sender);
end;


procedure   TDeviceSettings.PropertiesBtnClick (Sender: TObject);
var
  LI: TListItem;
begin
  inherited;
  LI := Listview.Selected;
  if (LI <> nil) then begin
    TDevice(LI.Data).SettingsDialog (MainWindow);
  end;
  if (Listview.CanFocus) then Listview.SetFocus;
end;


procedure   TDeviceSettings.AddBtnClick (Sender: TObject);
const
  MethodName = 'AddBtnClick';

resourcestring
  STooManyDevices = 'Es können höchstens %d Geräte eingerichtet werden.';

var
  Dialog: TAddDeviceForm;
  DeviceItem: TDevice;
  N, I: Integer;
  HasFlexnet: Boolean;

begin

  if (Listview.Items.Count > High (DeviceList.DeviceItem)) then begin
    with TDlgMessage.create (parent) do begin
      Run (ApplicationName, Format (STooManyDevices, [Length (DeviceList.DeviceItem)]), [mbOk]);
      Release;
    end;
    exit;
  end;

  Dialog := TAddDeviceForm.Create (parent);

  try

    with Dialog do begin

      // The FlexNet DLL keeps global state: only one FlexNet device is possible.
      // Devices removed but not yet applied are still running, so count them too.
      HasFlexnet := false;
      for I := 0 to Listview.Items.Count - 1 do begin
        if (TDevice (Listview.Items[I].Data) is TFlexnetDevice) then HasFlexnet := true;
      end;
      for I := 0 to DeletedDevices.Count - 1 do begin
        if (TDevice (DeletedDevices[I]) is TFlexnetDevice) then HasFlexnet := true;
      end;

      // Objects: index into DeviceClasses
      for N := 0 to (Length (DeviceClasses) - 1) do begin
        if (HasFlexnet) and (DeviceClasses[N].InheritsFrom (TFlexnetDevice)) then continue;
        Listbox.Items.AddObject (DeviceClasses[N].Name, TObject (N));
      end;

      Listbox.ItemIndex := 0;

      if (ShowModal = mrOk) then begin

        N := Listbox.ItemIndex;
        if (N >= 0) and (N < Listbox.Items.Count) then N := Integer (Listbox.Items.Objects[N]) else N := -1;
        if (N >= 0) and (N < Length (DeviceClasses)) then begin

          DeviceItem := DeviceList.CreateDevice (DeviceClasses[N]);
          if (DeviceItem <> nil) then begin
            AddNewEntry (DeviceItem);
            AddedDevices.Add (DeviceItem);
          end;

        end;

      end;

    end;

  finally

    Dialog.Release;

  end;

  if (Listview.CanFocus) then Listview.SetFocus;

end;


procedure   TDeviceSettings.RemoveBtnClick (Sender: TObject);
resourcestring
  SRemoveDeviceCaption = 'Entfernen';
  SRemoveDevice = 'Gerät wirklich entfernen?';
var
  LI: TListItem;
  N: Integer;
  I: Integer;
begin
  with Listview do begin
    LI := Selected;
    if (LI <> nil) then begin
      with TDlgMessage.create (parent) do begin
        I := Run (SRemoveDeviceCaption, SRemoveDevice, [mbYes, mbNo]);
        Release;
      end;
      if (I = idyes) then begin
        N := AddedDevices.IndexOf (LI.Data);
        if (N >= 0) then begin
          TDevice(AddedDevices[N]).Free;
          AddedDevices.Delete (N);
        end else begin
          DeletedDevices.Add (LI.Data);
        end;
        N := LI.Index;
        Items.Delete (N);
        if (N < Items.Count) then begin
          Selected := Items[N];
        end else if (N > 0) then begin
          Selected := Items[N-1];
        end else begin
          Selected := nil;
        end;
        if (Selected <> nil) then Selected.Focused := true;
      end;
    end;
    if (CanFocus) then SetFocus;
  end;
end;


procedure   TDeviceSettings.UpBtnClick (Sender: TObject);
var
  LI: TListItem;
  N: Integer;
begin
  with Listview do begin
    if (Selected <> nil) then begin
      N := Selected.Index;
      if (N > 0) then begin
        LI := TListItem.Create (Items);
        LI.Assign (Selected);
        Items[N]     := Items[N - 1];
        Items[N - 1] := LI;
        Selected := Items[N - 1];
        Selected.Focused := true;
        LI.Free;
      end;
    end;
    if (CanFocus) then SetFocus;
    Checkboxes := false;
  end;
end;


procedure   TDeviceSettings.DownBtnClick (Sender: TObject);
var
  LI: TListItem;
  N: Integer;
begin
  inherited;
  with Listview do begin
    if (Selected <> nil) then begin
      N := Selected.Index;
      if (N < Items.Count - 1) then begin
        LI := TListItem.Create (Items);
        LI.Assign (Selected);
        Items[N]     := Items[N + 1];
        Items[N + 1] := LI;
        Selected := Items[N + 1];
        Selected.Focused := true;
        LI.Free;
      end;
    end;
    if (CanFocus) then SetFocus;
    Checkboxes := false;
  end;
end;


procedure   TDeviceSettings.ListviewKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = vk_Down) and (ssCtrl in Shift) then begin
    Key := 0;
    Shift := [];
    DownBtnClick (Sender);
  end else if (Key = vk_Up) and (ssCtrl in Shift) then begin
    Key := 0;
    Shift := [];
    UpBtnClick (Sender);
  end else begin
    inherited;
  end;
end;


procedure   TDeviceSettings.ApplyPage;
const
  MethodName = 'ApplyPage';

var
  N: Integer;

begin

  // First take the removed devices out of DeviceList: DeInit and ApplySettings
  // process messages for seconds, and a status change of another device then walks
  // through DeviceList (TDevices.StatusChange), which must not hold freed devices.
  with Listview do begin
    for N := 0 to Items.Count - 1 do begin
      DeviceList.DeviceItem[N] := TDevice(Items[N].Data);
    end;
    DeviceList.Quantity := Items.Count;
  end;

  AddedDevices.Clear;

  if (DeletedDevices.Count > 0) then begin
    DeletedDevices.Pack;
    DebOut (self, MethodName, 'Gelöschte Geraete deinitialisieren...');
    for N := 0 to DeletedDevices.Count - 1 do begin
      with TDevice(DeletedDevices.Items[N]) do begin
        DeInit;
        Free;
      end;
    end;
    DeletedDevices.Clear;
  end;

  DebOut (self, MethodName, 'Einstellungen uebernehmen...');

  with Listview do begin
    for N := 0 to Items.Count - 1 do begin
      TDevice(Items[N].Data).ApplySettings;
    end;
    DeviceList.Update;
  end;

  DebOut (self, MethodName, 'Einstellungen speichern...');
  DeviceList.Save;

  DebOut (self, MethodName, 'ok.');

end;


procedure   TDeviceSettings.CancelPage;
var
  N: Integer;
begin
  // Discard parameters changed in the device dialogs but not applied (FNewParam);
  // removed devices are still live until applied
  for N := 0 to Listview.Items.Count - 1 do begin
    TDevice (Listview.Items[N].Data).CancelSettings;
  end;
  for N := 0 to DeletedDevices.Count - 1 do begin
    if (assigned (DeletedDevices[N])) then TDevice (DeletedDevices[N]).CancelSettings;
  end;
end;


procedure   TDeviceSettings.Notify (aDeviceObj: TDevice);
var
  N: Integer;
  R: TRect;
begin
  with Listview do begin
    for N := 0 to Items.Count - 1 do begin
      if (aDeviceObj = Items[N].Data) then begin
        with Items[N] do begin
          SubItems.Strings[0] := aDeviceObj.ParameterText;
          SubItems.Strings[1] := aDeviceObj.StatusText;
          R := DisplayRect (drBounds);
          InvalidateRect (Handle, @R, false);
        end;
        break;
      end;
    end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TDeviceSettingsSubscriber.create (aDeviceSettings: TDeviceSettings);
begin
  inherited create;
  FDeviceSettings := aDeviceSettings;
end;


procedure   TDeviceSettingsSubscriber.Notify (P: Pointer);
begin
  FDeviceSettings.Notify (TDevice(P));
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

