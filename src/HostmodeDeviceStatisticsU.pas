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


unit HostmodeDeviceStatisticsU;


interface


uses
  Classes, Windows, SysUtils, Forms, Controls, Messages;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  THostmodeDeviceStatistics = class
  private
    LastHostmodeLoop: Cardinal;
    LoopDuration: array[1..65536] of Integer;
    LoopDurationIndex: Integer;
    LoopDurationMax: Integer;
    LoopDurationMin: Integer;
  public
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   HostmodeLoop; virtual;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   THostmodeDeviceStatistics.AfterConstruction;
var
  N: Integer;
begin
  inherited;
  LastHostmodeLoop := 0;
  for N := Low (LoopDuration) to High (LoopDuration) do begin
    LoopDuration[N] := -1;
  end;
  LoopDurationIndex := Low (LoopDuration);
  LoopDurationMax := -1;
  LoopDurationMin := MaxInt;
end;


procedure   THostmodeDeviceStatistics.BeforeDestruction;
var
  R: Double;
  I, N: Integer;

begin

  I := 0;
  R := 0;
  for N := Low (LoopDuration) to High (LoopDuration) do begin
    if (LoopDuration[N] <> -1) then begin
      R := R + LoopDuration[N];
      Inc (I);
    end;
  end;
  if (I > 0) then begin
    R := R / I;
  end else begin
    R := 0;
  end;

  DebOut (self, 'Hostmodeschleife-Dauer: %d Messwerte.', [I]);
  DebOut (self, 'Hostmodeschleife-Dauer: Durchschnitt:%9.2f ms.', [R]);
  DebOut (self, 'Hostmodeschleife-Dauer: Min:         %6.2d ms.', [LoopDurationMin]);
  DebOut (self, 'Hostmodeschleife-Dauer: Max:         %6.2d ms.', [LoopDurationMax]);

  inherited;

end;


procedure   THostmodeDeviceStatistics.HostmodeLoop;
var
  T: Cardinal;
  I: Integer;
begin
  T := GetTickCount;
  if (LastHostmodeLoop = 0) then begin
    LastHostmodeLoop := T;
  end else begin
    I := T - LastHostmodeLoop;
    LoopDuration[LoopDurationIndex] := I;
    if (I > LoopDurationMax) then LoopDurationMax := I;
    if (I < LoopDurationMin) then LoopDurationMin := I;
    inc (LoopDurationIndex);
    if (LoopDurationIndex > High (LoopDuration)) then LoopDurationIndex := Low(LoopDuration);
    LastHostmodeLoop := T;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

