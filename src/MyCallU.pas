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


unit MyCallU;


interface


uses
  Classes, Windows, SysUtils, Messages, Controls, Dialogs,
  Forms, StdCtrls, ExtCtrls, ComCtrls, SyncObjs,
  InterfacesU, PublisherU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TMyCall = class (TObject)
  private
    FCall: String;
    function    GetCallWithSSID (N: Integer): String;
    procedure   SetCall (const aCall: String);
    function    GetCall: String;
  public
    SSID: array[0..15] of Integer;
    SSIDCount: Integer;
    constructor Create; virtual;
    destructor  Destroy; override;
    function    SSIDsAsString: String;
    property    CallWithSSID [N: Integer]: String read GetCallWithSSID;
    procedure   Assign (Source: TMyCall);
    property    Call: String read GetCall write SetCall;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TMyCall.Create;
begin
  inherited create ();
end;


destructor  TMyCall.Destroy;
begin
  inherited;
end;


function    TMyCall.SSIDsAsString: String;
var
  N: Integer;
  S: String;
  B: Boolean;
begin
  B := false;
  S := '';
  for N := 0 to SSIDCount - 1 do begin
    if (N < SSIDCount - 1) and (SSID[N] = SSID[N+1] - 1) then begin
      if not B then begin
        B := true;
        S := S + IntToStr (SSID[N]) + '..';
      end;
    end else begin
      B := false;
      S := S + IntToStr (SSID[N]);
      if N < SSIDCount - 1 then S := S + ', ';
    end;
  end;
  result := S;
end;


function    TMyCall.GetCallWithSSID (N: Integer): String;
var
  S: String;
begin
  assert ((N >= 0) and (N < SSIDCount));
  if (SSID[N] > 0) then S := '-' + IntToStr(SSID[N]) else S := '';
  result := Call + S;
end;


procedure   TMyCall.Assign (Source: TMyCall);
begin
  Call := Source.Call;
  SSIDCount := Source.SSIDCount;
  SSID := Source.SSID;
end;


function    TMyCall.GetCall: String;
begin
  result := FCall;
end;


procedure   TMyCall.SetCall (const aCall: String);
begin
  FCall := AnsiUpperCase (aCall);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

