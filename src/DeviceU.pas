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


unit DeviceU;


interface


uses
  Classes, Windows, SysUtils,
  Forms, Messages, InterfacesU, SyncObjs;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TDeviceStatus = (gs_ready, gs_init, gs_error, gs_inactive);


type

  EDevice = class (Exception);

  TDeviceThread = class;

  TDevice = class
  protected

    FThread: TDeviceThread;
    FStatus: TDeviceStatus;
    FStatusText: string;
    FPendingStatusText: string;
    FParameterText: string;
    FRegKey: string;
    FNo: Integer;
    CriticalSection: TCriticalSection;

    procedure   Error (Text: string);
    procedure   ErrorMsg (Text: string);
    procedure   Run; virtual; abstract;
    procedure   SetParameterText (S: string); virtual;
    procedure   ThreadTerminate (Sender: TObject); virtual;
    function    DeviceStatusText (GS: TDeviceStatus): String;
    function    GetNo: Integer; virtual;
    procedure   SetNo (const Value: Integer); virtual;

  public

    class function Name: string; virtual; abstract;
    constructor Create; virtual;
    destructor  Destroy; override;
    procedure   Init; virtual;
    procedure   DeInit; virtual;
    procedure   Save; virtual;
    function    SettingsDialog (AOwner: TComponent): Integer; virtual; abstract;
    procedure   CancelSettings; virtual; abstract;
    procedure   ApplySettings; virtual; abstract;
    procedure   SetStatus (aStatus: TDeviceStatus; aStatusText: string); virtual;
    function    Terminated: Boolean;
    procedure   SetStatusSync;
    property    Status: TDeviceStatus read FStatus;
    property    StatusText: string read FStatusText;
    property    ParameterText: string read FParameterText write SetParameterText;
    function    RadioChannels (var aRadioChannels: array of IRadioChannel): Integer; virtual; abstract;
    function    EstablishConnection (aRadioChannel: IRadioChannel; var aCall: String; var aMyCall: String;
                                     aChannelObj: IChannel): TConnectError; overload; virtual;
    function    EstablishConnection (aRadioChannel: IRadioChannel; var aCall: String; var aMyCall: String; aChannelObj: IChannel;
                                     var Connection: IConnection): TConnectError; overload; virtual; abstract;
    procedure   TerminateConnection (aConnectionObj: IConnection); virtual; abstract;
    property    RegKey: string read FRegKey write FRegKey;
    procedure   Restore; virtual; abstract;
    function    SendUI  (aRadioChannel: IRadioChannel; aDestination, aMyCall, aText: String): Boolean; virtual; abstract;
    procedure   PactorBreakIn (aConnectionObj: IConnection); virtual;
    procedure   PactorChangeOver (aConnectionObj: IConnection); virtual;
    property    No: Integer read GetNo write SetNo;

  end;


  TDeviceThread = class(TThread)
  private
    procedure   CreateMessageQueue;
  protected
    DeviceItem: TDevice;
    procedure   Execute; override;
  public
    destructor  Destroy; override;
  end;


  TDeviceClass = class of TDevice;


procedure   RegisterDevice (aDeviceClass: TDeviceClass);


implementation


uses
  DebOutU, MainU, ChannelsU, DevicesU, GlobalU, UnhandledExceptionU, SynchronizeU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TDevice.Create;
begin
  inherited;
  FThread := nil;
  FStatus := gs_inactive;
  FStatusText := DeviceStatusText(FStatus);
  FPendingStatusText := FStatusText;
  FParameterText := '';
  CriticalSection := TCriticalSection.create;
end;


destructor  TDevice.Destroy;
begin
  CriticalSection.free;
  inherited;
end;


function    TDevice.Terminated: Boolean;
begin
  if (FThread = nil) then begin
    Result := True;
  end else begin
    Result := FThread.Terminated;
  end;
end;


procedure   TDevice.Error (Text: string);
const
  MethodName = 'Error';
var
  S: array[0..250] of Char;
  F: Integer;
begin
  F := GetLastError;
  StrPCopy (S, 'Geraet/' + Text + ': ');
  if (FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_MAX_WIDTH_MASK,
                     nil, F, 0, PChar(StrEnd(S)), 100, nil) = 0) then begin
    StrPCopy (S, 'Nr. ' + IntToStr(F));
  end;
  DebOut (self, MethodName, S);
  raise EDevice.Create (S);
end;


procedure   TDevice.ErrorMsg (Text: string);
begin
  raise EDevice.Create ('Geraet/' + Text);
end;


procedure   TDevice.Init;
const
  MethodName = 'Init';
begin
  DebOut (self, MethodName, '...' + Copy (FRegKey, Length (FRegKey) - 14, MaxInt) + '''');
  // Ein noch laufender Gerätethread (Status gs_init, oder gs_error während des
  // Abbaus nach einer Ausnahme) muss erst enden: Zwei Threads teilten sich sonst
  // DLL, Schnittstelle und Verbindungsliste.
  if (assigned (FThread)) then begin
    DeInit;
  end;
  FThread := TDeviceThread.Create (true);
  FThread.FreeOnTerminate := true;
  FThread.OnTerminate := ThreadTerminate;
  FThread.DeviceItem := self;
  FThread.Resume;
end;


procedure   TDevice.DeInit;
const
  MethodName = 'DeInit';

var
  L: Integer;
  B: Boolean;
  H: Integer;

begin

  DebOut (self, MethodName, 'begin...');

  if (assigned (FThread)) then begin

    H := FThread.Handle;
    L := GetTickCount;
    B := False;

    DebOut (self, MethodName, 'Thread.Terminate');
    FThread.Terminate;

    DebOut (self, MethodName, 'Warte auf Beendigung');

    repeat
      if (FThread = nil) or (WaitForSingleObject(H, 50) = wait_object_0) then begin
        B := true;
        break;
      end;
      Forms.Application.ProcessMessages;
      if (GetCurrentThreadID = MainThreadID) then CheckSynchronize;
    // Verstrichene Zeit statt Zeitpunkt vergleichen: GetTickCount läuft alle
    // 49,7 Tage über.
    until (GetTickCount - DWord (L) > 8000);

    if (B) then begin
      DebOut (self, MethodName, 'Geräte-Thread normal beendet.');
    end else begin
      DebOut (self, MethodName, 'Geräte-Thread wird abgebrochen...');
      FThread := nil;
      try
        TerminateThread (H, 1);
      except
      end;
      DebOut (self, MethodName, 'Geräte-Thread wurde abgebrochen.');
    end;

  end else begin

    DebOut (self, MethodName, 'Kein Geräte-Thread vorhanden.');

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TDevice.Save;
begin
  assert (FRegKey <> '');
end;


procedure   TDevice.ThreadTerminate (Sender: TObject);
const
  MethodName = 'ThreadTerminate';
begin
  DebOut (self, MethodName, 'begin...');
  FThread := nil;
  DebOut (self, MethodName, 'end.');
end;


procedure   TDevice.SetStatus (aStatus: TDeviceStatus; aStatusText: string);
const
  MethodName = 'SetStatus';
begin
  // FStatusText liest der Hauptthread (Einstellungen, Gerätestatus); er wird
  // deshalb erst in SetStatusSync, also im Hauptthread, gesetzt.
  FPendingStatusText := DeviceStatusText(aStatus);
  if (aStatusText <> '') then FPendingStatusText := FPendingStatusText + ' - ' + aStatusText;
  FStatus := aStatus;
  Synchronize (SetStatusSync);
end;


procedure   TDevice.SetParameterText (S: string);
begin
  FParameterText := S;
  Synchronize (SetStatusSync);
end;


procedure   TDevice.SetStatusSync;
begin
  FStatusText := FPendingStatusText;
  if (assigned (DeviceList)) then begin
    DeviceList.StatusChange (self);
  end;
end;


function    TDevice.EstablishConnection (aRadioChannel: IRadioChannel; var aCall: String; var aMyCall: String;
                                         aChannelObj: IChannel): TConnectError;
var
  Connection: IConnection;
begin
  Connection := nil;
  result := EstablishConnection (aRadioChannel, aCall, aMyCall, aChannelObj, Connection);
  Connection := nil;
end;


function    TDevice.DeviceStatusText (GS: TDeviceStatus): String;
resourcestring
  SStatusReady = 'Bereit';
  SStatusInit = 'Init';
  SStatusError = 'Fehler';
  SStatusInactive = 'Inaktiv';
begin
  case GS of
    gs_ready: result := SStatusReady;
    gs_init: result := SStatusInit;
    gs_error: result := SStatusError;
    gs_inactive: result := SStatusInactive;
  end;
end;


procedure   TDevice.PactorBreakIn (aConnectionObj: IConnection);
begin
  // do nothing
end;


procedure   TDevice.PactorChangeOver (aConnectionObj: IConnection);
begin
  // do nothing
end;


function    TDevice.GetNo: Integer;
begin
  result := FNo;
end;


procedure   TDevice.SetNo (const Value: Integer);
begin
  FNo := Value;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDeviceThread.Execute;
const
  MethodName = 'Execute';

begin

  try
    try
      DebOut (self, MethodName, 'begin...');
      CreateMessageQueue;
      DeviceItem.Run;
      DebOut (self, MethodName, 'end.');
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, MethodName);
        raise;
      end;
    end;
  finally
    DeviceItem.FThread := nil;
  end;

end;


destructor  TDeviceThread.Destroy;
const
  MethodName = 'Destroy';
begin
  DebOut (self, MethodName, 'begin...');
  inherited;
  DebOut (self, MethodName, 'end.');
end;


procedure   TDeviceThread.CreateMessageQueue;
var
  Msg: TMsg;
begin
  // Create the thread message queue:
  PeekMessage (Msg, 0, 0, 0, PM_NOREMOVE);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   RegisterDevice (aDeviceClass: TDeviceClass);
begin
  DevicesU.RegisterDevice (aDeviceClass);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

