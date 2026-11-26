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


unit HostmodeTFWinDeviceU;


interface


uses
  Windows, Classes, SysUtils, Messages,
  Forms, Controls, SyncObjs, DebOutU, HostmodeTFWinDeviceSettingsU,
  GlobalU, InterfacesU, DeviceU, HostmodeDeviceU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

type

  THostmodeTFWinDeviceParameter = class (THostmodeDeviceParameter)
    //
  end;


  THostmodeTFWinDevice = class (THostmodeDevice)
  private

    FDLLHandle: THandle;
    MessageWindow: HWND;

    function    LoadDLL: Boolean;
    procedure   FreeDLL;
    procedure   CreateMessageWindow;
    procedure   DestroyMessageWindow;

  protected

    function    ParameterClass: THostmodeDeviceParameterClass; override;

    function    CommOpen: Boolean; override;
    function    CommClose: Boolean; override;
    function    CommWrite (const Buffer; nNumberOfBytesToWrite: DWORD; var lpNumberOfBytesWritten: DWORD): Boolean; override;
    function    CommRead (var Buffer; nNumberOfBytesToRead: DWORD; var lpNumberOfBytesRead: DWORD): Boolean; override;
    procedure   CommPurge; override;

    function    CommOpened: Boolean; override;

    function    SetTimeouts (aResync: Boolean): Boolean; override;
    procedure   UpdateParamText; override;

  public

    class function Name: string; override;
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   Init; override;
    procedure   Save; override;
    procedure   CancelSettings; override;
    function    SettingsDialog (AOwner: TComponent): Integer; override;
    procedure   ApplySettings; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  Registry, MainU;


var
  TfClose: function: Boolean; cdecl;
  TfOpen: function (hWnd: HWND): Boolean; cdecl;
  TfPut: function (ch: char): Integer; cdecl;
  TfGet: function: Integer; cdecl;
  TfChck: function: Boolean; cdecl;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    MessageWndProc (Window: HWND; Msg, wParam, lParam: Longint): Longint; stdcall;
begin
  Result := DefWindowProc (Window, Msg, wParam, lParam);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


class function THostmodeTFWinDevice.Name: string;
begin
  Result := 'TFWin';
end;


procedure   THostmodeTFWinDevice.AfterConstruction;
begin
  inherited;
  CreateMessageWindow;
  (*
  with (FParam as THostmodeTFWinDeviceParameter) do begin
    CommNo := 1;
    CommBaudrate := 38400;
  end;
  *)
end;


procedure   THostmodeTFWinDevice.BeforeDestruction;
begin
  DestroyMessageWindow;
  inherited;
end;


function    THostmodeTFWinDevice.LoadDLL: Boolean;
begin
  FDLLHandle := SafeLoadLibrary ('tfwin32.dll');
  if (FDLLHandle <> 0) then begin
    result := true;
    TfClose := GetProcAddress (FDLLHandle, 'TfClose');   if (addr(TfClose) = nil) then result := false;
    TfOpen  := GetProcAddress (FDLLHandle, 'TfOpen');    if (addr(TfOpen)  = nil) then result := false;
    TfPut   := GetProcAddress (FDLLHandle, 'TfPut');     if (addr(TfPut)   = nil) then result := false;
    TfGet   := GetProcAddress (FDLLHandle, 'TfGet');     if (addr(TfGet)   = nil) then result := false;
    TfChck  := GetProcAddress (FDLLHandle, 'TfChck');    if (addr(TfChck)  = nil) then result := false;
    if (not result) then FreeDLL;
  end else begin
    result := false;
  end;
end;


procedure   THostmodeTFWinDevice.FreeDLL;
begin
  if (FDLLHandle <> 0) then begin
    FreeLibrary (FDLLHandle);
    FDLLHandle := 0;
  end;
end;


function    THostmodeTFWinDevice.ParameterClass: THostmodeDeviceParameterClass;
begin
  result := THostmodeTFWinDeviceParameter;
end;


function    THostmodeTFWinDevice.CommOpen: Boolean;

const
  MethodName = 'CommOpen';

resourcestring
  SDLLNotFound = 'TFWIN32.DLL nicht gefunden';
  STFOpenFailed = 'TFOpen fehlgeschlagen';

var
  Error: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  DebOut (self, MethodName, 'LoadDLL...');

  Error := not LoadDLL;

  if (Error) then begin
    SetStatus (gs_error, SDLLNotFound);
  end else begin
    DebOut (self, MethodName, 'TFOpen...');
    Error := not TfOpen (MessageWindow);
    if (Error) then begin
      SetStatus (gs_error, STFOpenFailed);
      // otherwise the DLL stays loaded and CommOpened reports an open interface
      FreeDLL;
    end;
  end;

  Result := not Error;

  DebOut (self, MethodName, 'end.');

end;


function    THostmodeTFWinDevice.CommClose: Boolean;
begin
  if (FDLLHandle <> 0) then begin
    TFClose;
  end;
  FreeDLL;
  Result := true;
end;


function    THostmodeTFWinDevice.CommRead (var Buffer; nNumberOfBytesToRead: DWORD; var lpNumberOfBytesRead: DWORD): Boolean;
type
  TChars = array[0..MaxInt-1] of Char;
var
  I, N, M: Integer;
  C: Char;
begin
  assert (FDLLHandle <> 0);
  result := true;
  for I := 0 to nNumberOfBytesToRead - 1 do begin
    for M := 1 to 10 do begin
      if TFChck then break;
      sleep (25);
    end;
    N := TFGet;
    if (N < 0) then begin
      result := false;
      break;
    end;
    C := Char (N);
    TChars(Buffer)[I] := C;
  end;
  if (result) then begin
    lpNumberOfBytesRead := nNumberOfBytesToRead;
  end else begin
    lpNumberOfBytesRead := I;
  end;
end;


function    THostmodeTFWinDevice.CommWrite (const Buffer; nNumberOfBytesToWrite: DWORD; var lpNumberOfBytesWritten: DWORD): Boolean;
type
  TChars = array[0..MaxInt-1] of Char;
var
  I: Integer;
  C: Char;
begin
  assert (FDLLHandle <> 0);
  result := true;
  for I := 0 to nNumberOfBytesToWrite - 1 do begin
    C := TChars(Buffer)[I];
    if (TFPut (C) = 0) then begin
      result := false;
      break;
    end;
  end;
  if (result) then begin
    lpNumberOfBytesWritten := nNumberOfBytesToWrite;
  end else begin
    lpNumberOfBytesWritten := I;
  end;
end;


function    THostmodeTFWinDevice.SettingsDialog (AOwner: TComponent): Integer;
var
  P: THostmodeTFWinDeviceParameter;

begin

  with THostmodeTFWinDeviceSettingsForm.Create (AOwner) do begin

    try

      if (FNewParam = nil) then
        P := (FParam as THostmodeTFWinDeviceParameter)
      else
        P := (FNewParam as THostmodeTFWinDeviceParameter);

      with P do begin

        InitMemo.Lines.Clear;
        InitMemo.Lines.Assign (TncInit);

        DeinitMemo.Lines.Clear;
        DeinitMemo.Lines.Assign (TncDeinit);

      end;

      Result := ShowModal;

      if (Result = mrOk) then begin

        if (FNewParam = nil) then FNewParam := ParameterClass.Create;

        with FNewParam as THostmodeTFWinDeviceParameter do begin

          TncInit.Assign (InitMemo.Lines);

          TncDeinit.Assign (DeinitMemo.Lines);

        end;

      end;

    finally

      Free;

    end;

  end;

end;


procedure   THostmodeTFWinDevice.CancelSettings;
begin
  if (assigned (FNewParam)) then begin
    FNewParam.free;
    FNewParam := nil;
    UpdateParamText;
  end;
end;


procedure   THostmodeTFWinDevice.ApplySettings;
const
  MethodName = 'ApplySettings';
var
  Reset: Boolean;
  TNCInitChanged: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  if (assigned (FNewParam)) then begin

    Reset := (Status <> gs_ready);

    TNCInitChanged := not (FParam.TncInit.Equals (FNewParam.TncInit));

    ReplaceParam (FNewParam);
    FNewParam := nil;

    if (TNCInitChanged) and (assigned (FThread)) then begin
      ThreadMessage (msg_initparameter, 0, 0);
    end;

  end else begin

    Reset := (Status <> gs_ready);

  end;

  if (Reset) then begin

    if (FDLLHandle <> 0) then begin
      DeInit;
    end;

    RegKey := '';

    Init;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure THostmodeTFWinDevice.Init;
const
  MethodName = 'Init';
var
  Registry: TRegistry;
begin
  inherited;
  Debout (self, MethodName, 'begin...');
  if (FRegKey <> '') then begin
    Registry := TRegistry.Create (KEY_READ);
    try
      Registry.RootKey := HKEY_CURRENT_USER;
      if (Registry.OpenKey (FRegKey, false)) then begin
        Registry.CloseKey;
      end;
    finally
      Registry.free;
    end;
  end;
  Debout (self, MethodName, 'end.');
end;


procedure   THostmodeTFWinDevice.Save;
const
  MethodName = 'Save';
var
  Registry: TRegistry;
begin
  inherited;
  DebOut (self, MethodName, 'begin...');
  Registry := TRegistry.Create (KEY_READ or KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if (Registry.OpenKey (FRegKey, true)) then begin
      Registry.CloseKey;
    end;
  finally
    Registry.free;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    THostmodeTFWinDevice.SetTimeouts (aResync: Boolean): Boolean;
const
  MethodName = 'SetTimeouts';
begin
  Result := true;
end;


procedure   THostmodeTFWinDevice.CommPurge;
begin
  // nothing to do
end;


function    THostmodeTFWinDevice.CommOpened: Boolean;
begin
  result := (FDLLHandle <> 0);
end;


procedure   THostmodeTFWinDevice.UpdateParamText;
begin
  ParameterText := '';
end;


procedure   THostmodeTFWinDevice.CreateMessageWindow;
var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
  MessageWindowClass: TWndClass;
begin
  MessageWindowClass.style := 0;
  MessageWindowClass.lpfnWndProc := @MessageWndProc;
  MessageWindowClass.cbClsExtra := 0;
  MessageWindowClass.cbWndExtra := 0;
  MessageWindowClass.hIcon := 0;
  MessageWindowClass.hCursor := 0;
  MessageWindowClass.hbrBackground := 0;
  MessageWindowClass.lpszMenuName := nil;
  MessageWindowClass.lpszClassName := PChar('PaxonTFWin');
  MessageWindowClass.hInstance := HInstance;
  ClassRegistered := GetClassInfo (HInstance, MessageWindowClass.lpszClassName, TempClass);
  if (not ClassRegistered) or (TempClass.lpfnWndProc <> @MessageWndProc) then begin
    if (ClassRegistered) then Windows.UnregisterClass (MessageWindowClass.lpszClassName, HInstance);
    Windows.RegisterClass (MessageWindowClass);
  end;
  MessageWindow := CreateWindow (MessageWindowClass.lpszClassName, '', 0, 0, 0, 0, 0, 0, 0, HInstance, nil);
end;


procedure   THostmodeTFWinDevice.DestroyMessageWindow;
begin
  if (MessageWindow <> 0) then begin
    DestroyWindow (MessageWindow);
    MessageWindow := 0;
  end;
end;


initialization

  RegisterDevice (THostmodeTFWinDevice);

end.

