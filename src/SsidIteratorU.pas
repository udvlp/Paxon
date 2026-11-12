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


unit SsidIteratorU;


interface


uses
  Classes, Windows, SysUtils, Controls,
  Forms, GlobalU, InterfacesU, MyCallsU, MyCallU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TSSID = -1..15;


  TCallsign = class
  private
    FPSID: string;
    FSSID: TSSID;
    function    GetCallsign: string;
    procedure   SetCallsign (const Value: string);
    function    GetCallsignWithoutDashZero: string;
  public
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   Assign (Source: TCallsign);
    property    Callsign: string read GetCallsign write SetCallsign;
    property    CallsignWithoutDashZero: string read GetCallsignWithoutDashZero;
    function    CallsignWithOtherSSID (aSSID: TSSID; aWithoutDashZero: Boolean): string;
    property    SSID: TSSID read FSSID write FSSID;
    property    PSID: string read FPSID write FPSID;
  end;


  TSsidIterator = class
  private
    FMyCall: TMyCall;
    FCallsign: string;
    FCounter: Integer;
  public
    constructor Create (aMyCall: string); virtual;
    destructor  Destroy; override;
    function    Reset: Boolean; virtual;
    function    Next: Boolean; virtual;
    function    EOF: Boolean; virtual;
    property    Callsign: string read FCallsign;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TCallsign
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TCallsign.AfterConstruction;
begin
  inherited;
end;


procedure   TCallsign.BeforeDestruction;
begin
  inherited;
end;


procedure   TCallsign.Assign (Source: TCallsign);
begin
  inherited;
  FPSID := Source.FPSID;
  FSSID := Source.FSSID;
end;


procedure   TCallsign.SetCallsign (const Value: string);
var
  I: Integer;
begin
  I := Pos ('-', Value);
  if I <= 0 then begin
    FPSID := Value;
    FSSID := -1;
  end else begin
    FPSID := Copy (Value, 1, I - 1);
    FSSID := StrToIntDef (Copy (Value, I + 1, MaxInt), -1);
  end;
end;


function    TCallsign.GetCallsign: string;
begin
  if FSSID >= 0 then begin
    Result := Format ('%s-%d', [FPSID, FSSID]);
  end else begin
    Result := FPSID;
  end;
end;


function    TCallsign.GetCallsignWithoutDashZero: string;
begin
  if FSSID > 0 then begin
    Result := Format ('%s-%d', [FPSID, FSSID]);
  end else begin
    Result := FPSID;
  end;
end;


function    TCallsign.CallsignWithOtherSSID (aSSID: TSSID; aWithoutDashZero: Boolean): string;
begin
  if ((aSSID < 0) and (not aWithoutDashZero)) or ((aSSID <= 0) and (aWithoutDashZero)) then begin
    Result := FPSID;
  end else begin
    Result := Format ('%s-%d', [FPSID, aSSID]);
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TSsidIterator.Create (aMyCall: string);
var
  Callsign: TCallsign;
  B: Boolean;
  N: Integer;

begin

  inherited Create;

  FMyCall := TMyCall.Create;

  Callsign := TCallsign.Create;

  try

    Callsign.Callsign := aMyCall;

    if (Callsign.SSID >= 0) then begin

      // SSID given

      FMyCall.Call := Callsign.PSID;
      FMyCall.SSIDCount := 1;
      FMyCall.SSID[0] := Callsign.SSID;

    end else begin

      // No SSID given

      B := False;
      MyCalls.BeginRead;
      try
        for N := 0 to MyCalls.Count - 1 do begin
          if MyCalls[N].Call = Callsign.PSID then begin

            // Callsign found in the list of own callsigns,
            // so use the selected SSIDs

            FMyCall.assign (MyCalls[N]);
            B := True;
            break;

          end;
        end;
      finally
        MyCalls.EndRead;
      end;

      if not B then begin

        // Not found in the list of own callsigns,
        // so use all SSIDs

        FMyCall.Call := Callsign.PSID;
        FMyCall.SSIDCount := 16;
        for N := 0 to 15 do FMyCall.SSID[N] := N;

      end;

    end;

  finally

    Callsign.Free;

  end;

  Reset;

end;


destructor  TSsidIterator.Destroy;
begin
  FMyCall.Free;
  inherited;
end;


function    TSsidIterator.EOF: Boolean;
begin
  Result := (FCounter < 0) or (FCounter >= FMyCall.SSIDCount);
end;


function    TSsidIterator.Next: Boolean;
begin
  Inc (FCounter);
  Result := FCounter < FMyCall.SSIDCount;
  if Result then begin
    FCallsign := FMyCall.CallWithSSID [FCounter];
  end else begin
    FCallsign := 'NOCALL';
  end;
end;


function    TSsidIterator.Reset: Boolean;
begin
  FCounter := -1;
  Result := Next;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

