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


unit HostmodeSerialDeviceU;


interface


uses
  Windows, Classes, SysUtils, Messages,
  Forms, Controls, SyncObjs, DebOutU, HostmodeSerialDeviceSettingsU,
  GlobalU, InterfacesU, DeviceU, HostmodeDeviceU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

type

  THostmodeSerialDeviceParameter = class (THostmodeDeviceParameter)
    CommNo: Integer;
    CommBaudrate: Integer;
  end;


  THostmodeSerialDevice = class (THostmodeDevice)
  private

    FComm: THandle;

    procedure   CheckFifo (ComName: String);

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
  Registry;

const
  Baudrates: array[0..6] of Integer = (4800, 9600, 19200, 38400, 57600, 115200, 230400);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


class function THostmodeSerialDevice.Name: string;
begin
  Result := 'Hostmode';
end;


procedure   THostmodeSerialDevice.AfterConstruction;
begin
  inherited;
  with (FParam as THostmodeSerialDeviceParameter) do begin
    CommNo := 1;
    CommBaudrate := 38400;
  end;
end;


procedure   THostmodeSerialDevice.BeforeDestruction;
begin
  inherited;
end;


function    THostmodeSerialDevice.ParameterClass: THostmodeDeviceParameterClass;
begin
  result := THostmodeSerialDeviceParameter;
end;


function    THostmodeSerialDevice.CommOpen: Boolean;
const
  MethodName = 'CommOpen';

var
  DCB: TDCB;
  S: string;
  Error: Boolean;

begin

  DebOut (self, MethodName, 'begin...');
  Error := false;

  S := Format ('COM%d', [(FParam as THostmodeSerialDeviceParameter).CommNo]);

  CheckFifo (S);

  // '\\.\COMn' is valid for all numbers, 'COMn' only up to COM9
  FComm := CreateFile (PChar('\\.\' + S), generic_read or generic_write, 0, nil, open_existing, 0, 0);

  if (FComm = invalid_handle_value) then begin
    Debout (self, MethodName, 'CreateFile fehlgeschlagen');
    Error := true;
  end;

  if (not Error) then begin
    if (GetFileType(FComm) <> FILE_TYPE_CHAR) then begin
      Debout (self, MethodName, 'GetFileType fehlgeschlagen: Keine Schnittstelle');
      Error := true;
    end;
  end;

  if (not Error) then begin
    if (not SetupComm (FComm, 512, 512)) then begin
      Debout (self, MethodName, 'SetupComm fehlgeschlagen');
      Error := true;
    end;
  end;

  if (not Error) then begin
    if (not SetTimeouts (false)) then begin
      Error := true;
    end;
  end;

  if (not Error) then begin
    FillChar (DCB, sizeof (DCB), 0);
    DCB.DCBlength := sizeof (DCB);
    DCB.BaudRate := (FParam as THostmodeSerialDeviceParameter).CommBaudrate;
    DCB.Flags := (1 shl  0)  // fBinary:1, binary mode, no EOF check (default: 1)
              or (0 shl  1)  // fParity:1, enable parity checking (default: 0)
              or (0 shl  2)  // fOutxCtsFlow:1, CTS output flow control (default: 0)
              or (0 shl  3)  // fOutxDsrFlow:1, DSR output flow control (default: 0)
              or (DTR_CONTROL_ENABLE shl  4)  // fDtrControl:2, DTR flow control type (default: DTR_CONTROL_ENABLE)
              or (0 shl  6)  // fDsrSensitivity:1, DSR sensitivity (default: 0)
              or (0 shl  7)  // fTXContinueOnXoff:1, XOFF continues Tx (default: 0)
              or (0 shl  8)  // fOutX:1, XON/XOFF out flow control (default: 0)
              or (0 shl  9)  // fInX:1, XON/XOFF in flow control (default: 0)
              or (0 shl 10)  // fErrorChar:1, enable error replacement (default: 0)
              or (0 shl 11)  // fNull:1, enable null stripping (default: 0)
              or (RTS_CONTROL_TOGGLE shl 12)  // fRtsControl:2, RTS flow control (default: RTS_CONTROL_TOGGLE)
              or (0 shl 14); // fAbortOnError:1, abort reads/writes on error (default: 0)
    DCB.wReserved := 0;
    DCB.XonLim := 3072;
    DCB.XoffLim := 1024;
    DCB.ByteSize := 8;
    DCB.Parity := NoParity;
    DCB.StopBits := OneStopBit;
    DCB.XOnChar := #17;
    DCB.XOffChar := #19;
    DCB.ErrorChar := #3;
    DCB.EofChar := #26;
    DCB.EvtChar := #1;
    DCB.wReserved1 := 0;

    if (not SetCommState (FComm, DCB)) then begin
      Debout (self, MethodName, 'SetCommState fehlgeschlagen');
      Error := true;
    end;

  end;

  if (Error) then begin
    if (FComm <> invalid_handle_value) then begin
      CloseHandle (FComm);
      FComm := invalid_handle_value;
    end;
    SetStatus (gs_error, SOpeningPort);
  end;

  Result := not Error;

  DebOut (self, MethodName, 'end.');

end;


function    THostmodeSerialDevice.CommClose: Boolean;
begin
  Result := false;
  if (not (FComm = invalid_handle_value)) then begin
    FlushFileBuffers (FComm);
    CloseHandle (FComm);
    FComm := invalid_handle_value;
    Result := true;
  end;
end;


function    THostmodeSerialDevice.CommRead (var Buffer; nNumberOfBytesToRead: DWORD; var lpNumberOfBytesRead: DWORD): Boolean;
begin
  result := ReadFile (FComm, Buffer, nNumberOfBytesToRead, lpNumberOfBytesRead, nil);
end;


function    THostmodeSerialDevice.CommWrite (const Buffer; nNumberOfBytesToWrite: DWORD;
                                             var lpNumberOfBytesWritten: DWORD): Boolean;
begin
  result := WriteFile (FComm, Buffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, nil);
end;


procedure   THostmodeSerialDevice.CheckFifo (ComName: String);
// Reads the FIFO settings of the serial driver and reports deviations only via DebOut.
// Previously they were written to HKEY_LOCAL_MACHINE here on every open; but an application
// does not reconfigure system drivers (and must not do so without administrator rights).
const
  MethodName = 'CheckFifo';
  FifoValues: array [0..2] of String = ('ForceFifoEnable', 'RxFIFO', 'TxFIFO');
var
  Reg: TRegistry;
  SL: TStringList;
  I, N: Integer;
  S, T: String;

  procedure CheckKeyValues (const Key: String);
  // Reg is open on Key
  var
    J, W: Integer;
  begin
    for J := 0 to High (FifoValues) do begin
      if (Reg.GetDataType (FifoValues[J]) = rdInteger) then begin
        W := Reg.ReadInteger (FifoValues[J]);
        if (W <> 1) then begin
          DebOut (self, MethodName, '%s\%s = %d (abweichend von 1)', [Key, FifoValues[J], W]);
        end;
      end else begin
        DebOut (self, MethodName, '%s\%s nicht gesetzt', [Key, FifoValues[J]]);
      end;
    end;
  end;

begin

  DebOut (self, MethodName, 'begin...');

  try

    SL := TStringList.Create;

    Reg := TRegistry.create (KEY_READ);

    try

      Reg.RootKey := HKEY_LOCAL_MACHINE;

      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      S := '\SYSTEM\CurrentControlSet\Services\Serial';

      if (Reg.OpenKey (S, false)) then begin
        CheckKeyValues (S);
        Reg.CloseKey;
      end;

      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

      if (Reg.OpenKey ('\SYSTEM\CurrentControlSet\Services\Serial\Enum', false)) then begin
        try
          N := Reg.ReadInteger ('Count')
        except
          N := 0;
        end;
        for I := 0 to N - 1 do begin
          try
            S := Reg.ReadString (IntToStr (I))
          except
            S := '';
          end;
          if (S <> '') then begin
            SL.Add (S);
          end;
        end;
        Reg.CloseKey;
      end;

      for I := 0 to SL.Count - 1 do begin

        S := Format ('\SYSTEM\CurrentControlSet\Enum\%s\Device Parameters', [SL[I]]);

        if (Reg.OpenKey (S, false)) then begin

          try
            T := Reg.ReadString ('PortName');
          except
            T := '';
          end;

          if (SameText (ComName, T)) then begin
            DebOut (self, MethodName, S);
            CheckKeyValues (S);
          end;

          Reg.CloseKey;

        end;

      end;

      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    finally

      Reg.free;
      SL.Free;

    end;

  except
    DebOut (self, MethodName, 'EXCEPTION');
  end;

  DebOut (self, MethodName, 'end.');

end;


function    THostmodeSerialDevice.SettingsDialog (AOwner: TComponent): Integer;
var
  P: THostmodeSerialDeviceParameter;
  N: Integer;

begin

  with THostmodeSerialDeviceSettingsForm.Create (AOwner) do begin

    try

      if (FNewParam = nil) then
        P := (FParam as THostmodeSerialDeviceParameter)
      else
        P := (FNewParam as THostmodeSerialDeviceParameter);

      with P do begin

        with PortComboBox do begin
          Items.Clear;
          for N := 1 to 40 do begin
            Items.Add (Format ('COM%d', [N]));
          end;
          ItemIndex := CommNo - 1;
        end;

        with BaudrateCombobox do begin
          Items.Clear;
          for N := 0 to High (Baudrates) do begin
            Items.Add (IntToStr(Baudrates[N]));
            if (CommBaudrate = Baudrates[N]) then ItemIndex := N;
          end;
        end;

        InitMemo.Lines.Clear;
        InitMemo.Lines.Assign (TncInit);

        DeinitMemo.Lines.Clear;
        DeinitMemo.Lines.Assign (TncDeinit);

      end;

      Result := ShowModal;

      if (Result = mrOk) then begin

        if (FNewParam = nil) then FNewParam := ParameterClass.Create;

        with FNewParam as THostmodeSerialDeviceParameter do begin
          CommNo := StrToIntDef (Copy (PortComboBox.Items[PortComboBox.ItemIndex], 4, MaxInt), 1);
          DeviceID := CommNo;
          CommBaudrate := StrToIntDef (BaudrateCombobox.Items[BaudrateCombobox.ItemIndex], 38400);
          TncInit.Assign (InitMemo.Lines);
          TncDeinit.Assign (DeinitMemo.Lines);
        end;

      end;

    finally

      Free;

    end;

    UpdateParamText;

  end;

end;


procedure   THostmodeSerialDevice.CancelSettings;
begin
  if (assigned (FNewParam)) then begin
    FNewParam.free;
    FNewParam := nil;
  end;
end;


procedure   THostmodeSerialDevice.ApplySettings;
const
  MethodName = 'ApplySettings';
var
  Reset: Boolean;
  TNCInitChanged: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  if (assigned (FNewParam)) then begin
    Reset := ((FParam as THostmodeSerialDeviceParameter).CommNo <> (FNewParam as THostmodeSerialDeviceParameter).CommNo) or
      ((FParam as THostmodeSerialDeviceParameter).CommBaudrate <> (FNewParam as THostmodeSerialDeviceParameter).CommBaudrate) or
      (Status <> gs_ready);

    TNCInitChanged := not (FParam.TncInit.Equals (FNewParam.TncInit));

    FParam.free;
    FParam := FNewParam;
    FNewParam := nil;

    if (TNCInitChanged) and (assigned (FThread)) then begin
      ThreadMessage (msg_initparameter, 0, 0);
    end;

  end else begin

    Reset := (Status <> gs_ready);

  end;

  if (Reset) then begin

    if (FComm <> invalid_handle_value) then begin
      DeInit;
    end;
    RegKey := '';
    Init;

  end;

  UpdateParamText;

  DebOut (self, MethodName, 'end.');

end;


procedure THostmodeSerialDevice.Init;
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
        try
          with (FParam as THostmodeSerialDeviceParameter) do begin
            CommNo := Registry.ReadInteger ('ComPort');
            DeviceID := CommNo;
          end;
        except
        end;
        try
          with (FParam as THostmodeSerialDeviceParameter) do begin
            CommBaudrate := Registry.ReadInteger ('Baudrate');
          end;
        except
        end;
        Registry.CloseKey;
      end;
    finally
      Registry.free;
    end;
  end;
  Debout (self, MethodName, 'end.');
end;


procedure   THostmodeSerialDevice.Save;
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
      Registry.WriteInteger ('ComPort', (FParam as THostmodeSerialDeviceParameter).CommNo);
      Registry.WriteInteger ('Baudrate', (FParam as THostmodeSerialDeviceParameter).CommBaudrate);
      Registry.CloseKey;
    end;
  finally
    Registry.free;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    THostmodeSerialDevice.SetTimeouts (aResync: Boolean): Boolean;
const
  MethodName = 'SetTimeouts';

var
  CommTimeouts: TCommTimeouts;

begin

  Result := false;

  if (not GetCommTimeouts(FComm, CommTimeouts)) then begin
    Debout (self, MethodName, 'GetCommTimeouts fehlgeschlagen');
    exit;
  end;

  if (aResync) then begin

    with CommTimeouts do begin
      ReadIntervalTimeout         :=   0;
      ReadTotalTimeoutMultiplier  :=   5;
      ReadTotalTimeoutConstant    :=  50;
      WriteTotalTimeoutMultiplier :=   5;
      WriteTotalTimeoutConstant   := 500;
    end;

  end else begin

    with CommTimeouts do begin
      ReadIntervalTimeout         := 500;
      ReadTotalTimeoutMultiplier  :=  50;
      ReadTotalTimeoutConstant    := 500;
      WriteTotalTimeoutMultiplier :=  50;
      WriteTotalTimeoutConstant   := 500;
    end;

  end;

  if (not SetCommTimeouts (FComm, CommTimeouts)) then begin
    Debout (self, MethodName, 'SetCommTimeouts fehlgeschlagen');
    exit;
  end;

  Result := true;

end;


procedure   THostmodeSerialDevice.UpdateParamText;
begin
  if (FNewParam = nil) then begin
    if (Status <> gs_inactive) then begin
      ParameterText := Format ('COM%d, %d',
                               [(FParam as THostmodeSerialDeviceParameter).CommNo,
                                (FParam as THostmodeSerialDeviceParameter).CommBaudrate]);
    end else begin
      ParameterText := '-';
    end;
  end else begin
    ParameterText := Format ('COM%d, %d',
                             [(FNewParam as THostmodeSerialDeviceParameter).CommNo,
                              (FNewParam as THostmodeSerialDeviceParameter).CommBaudrate]);
  end;
end;


procedure   THostmodeSerialDevice.CommPurge;
begin
  PurgeComm (FComm, PURGE_TXCLEAR or PURGE_RXCLEAR);
end;


function    THostmodeSerialDevice.CommOpened: Boolean;
begin
  result := (FComm <> invalid_handle_value);
end;


initialization

  DebOut ('THostmodeSerialDevice.initialization: begin...');
  RegisterDevice (THostmodeSerialDevice);
  DebOut ('THostmodeSerialDevice.initialization: end.');

end.

