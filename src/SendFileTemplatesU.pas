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


unit SendFileTemplatesU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TSendFileTemplates = class
  private
    FRegKey: String;
    FStrings: array of String;
    function    GetCount: Integer; virtual;
    procedure   SetCount (const Value: Integer); virtual;
    function    GetStrings (I: Integer): String; virtual;
    procedure   SetStrings (I: Integer; const Value: String); virtual;
  public
    constructor create (aRegKey: String; aTemplates: array of String; aTemplatesVersion: Integer = 0); overload; virtual;
    constructor create (aSource: TSendFileTemplates); overload; virtual;
    procedure   assign (aSource: TSendFileTemplates); virtual;
    destructor  Destroy; override;
    property    Count: Integer read GetCount write SetCount;
    property    Strings [I: Integer]: String read GetStrings write SetStrings; default;
    procedure   Save; virtual;
    function    GetShortString (Idx: Integer; PixelWidth: Integer; Font: TFont): String; virtual;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  Registry;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TSendFileTemplates.create (aRegKey: String; aTemplates: array of String; aTemplatesVersion: Integer);
var
  Reg: TRegistry;
  SL: TStringList;
  N, I, M: Integer;
  S, T: String;
  B: Boolean;

begin

  inherited create;

  FRegKey := aRegKey;

  Reg := TRegistry.create (KEY_READ or KEY_WRITE);

  try

    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey (FRegKey, true);

    SL := TStringList.create;

    try

      Reg.GetValueNames (SL);
      N := SL.Count;
      SetLength (FStrings, N);
      M := 0;
      for I := 0 to N - 1 do begin
        if (SL[I] <> '') then begin
          try
            S := Reg.ReadString (SL[I]);
          except
            S := '';
          end;
          if (Length (S) > 0) then begin
            FStrings[M] := S;
            inc (M);
          end;
        end;
      end;

    finally

      SL.free;

    end;

    if (N <> M) then SetLength (FStrings, M);

    try
      S := Reg.ReadString ('');
    except
      S := '';
    end;

    T := IntToStr (aTemplatesVersion);

    if (S <> T) then begin

      Reg.WriteString ('', T);

      for N := Low(aTemplates) to High (aTemplates) do begin
        B := false;
        for I := Low(FStrings) to High (FStrings) do begin
          if (CompareText (aTemplates[N], FStrings[I]) = 0) then begin
            B := true;
            break;
          end;
        end;
        if (not B) then begin
          I := Length (FStrings);
          SetLength (FStrings, I + 1);
          FStrings[I] := aTemplates[N];
        end;
      end;

      Save;

    end;

    Reg.CloseKey;

  finally

    Reg.free;

  end;

end;


constructor TSendFileTemplates.create (aSource: TSendFileTemplates);
begin
  inherited create;
  assign (aSource);
end;


procedure TSendFileTemplates.assign (aSource: TSendFileTemplates);
var
  L, N: Integer;
begin
  FRegKey := aSource.FRegKey;
  L := Length (aSource.FStrings);
  SetLength (FStrings, L);
  for N := 0 to L - 1 do begin
    FStrings[N] := aSource.FStrings[N];
  end;
end;


destructor  TSendFileTemplates.destroy;
begin
  inherited;
end;


procedure   TSendFileTemplates.Save;
var
  Reg: TRegistry;
  S: String;
  N, I: Integer;
  SL: TStringList;

begin

  Reg := TRegistry.create (KEY_READ or KEY_WRITE);

  try

    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey (FRegKey, true);

    SL := TStringList.create;
    try
      Reg.GetValueNames (SL);
      for I := 0 to SL.Count - 1 do begin
        if (SL[I] <> '') then begin
          Reg.DeleteValue (SL[I]);
        end;
      end;
    finally
      SL.free;
    end;

    N := 0;
    for I := 0 to Length (FStrings) - 1 do begin
      S := FStrings[I];
      if (S <> '') then begin
        try
          Reg.WriteString (Format ('%2.2d', [N]), S);
          Inc (N);
        except
        end;
      end;
    end;

    Reg.CloseKey;

  finally

    Reg.free;

  end;

end;


function    TSendFileTemplates.GetCount: Integer;
begin
  result := Length (FStrings);
end;


procedure   TSendFileTemplates.SetCount (const Value: Integer);
begin
  SetLength (FStrings, Value);
end;


function    TSendFileTemplates.GetStrings (I: Integer): String;
begin
  result := FStrings[I];
end;


procedure   TSendFileTemplates.SetStrings (I: Integer; const Value: String);
begin
  FStrings[I] := Value;
end;


function    TSendFileTemplates.GetShortString (Idx: Integer; PixelWidth: Integer; Font: TFont): String;
var
  L, I, K, Z, W: Integer;
  DC: HDC;
  TextSize: TSize;
  SaveFont: HFont;
  B, SpaceAdded: Boolean;
  S: String;

begin

  result := '';
  S := FStrings[Idx];

  if (S <> '') then begin

    Z := 0;
    SpaceAdded := false;
    I := 0;
    L := Length (S);
    SetLength (result, L + 4);

    for K := 1 to L do begin

      if (IsCharAlphaNumeric (S[K])) then begin

        inc (I);
        result[I] := S[K];
        Z := 0;
        SpaceAdded := false;

      end else begin

        if (S[K] = #13) then begin
          S[K] := ' ';
          Z := 0;
        end;

        if (not SpaceAdded) and (S[K] = #32) then begin
          if (I > 0) then begin
            SpaceAdded := true;
            inc (I);
            result[I] := #32;
          end;
        end else if (S[K] > #32) and (Z < 3) then begin
          inc (I);
          result[I] := S[K];
          inc (Z);
          SpaceAdded := false;
        end;

      end;

    end;

    SetLength (result, I);

    DC := GetDC (0);
    SaveFont := SelectObject (DC, Font.Handle);
    B := false;
    W := 0;
    while (true) do begin
      GetTextExtentPoint32 (DC, PChar(result), Length (result), TextSize);
      if (TextSize.cx <= PixelWidth - W) then break;
      delete (result, Length (result) div 2, 1);
      if (not B) then begin
        B := true;
        GetTextExtentPoint32 (DC, '...', 3, TextSize);
        W := TextSize.cx;
      end;
    end;
    SelectObject (DC, SaveFont);
    ReleaseDC (0, DC);
    if (B) then begin
      insert ('...', result, Length (result) div 2);
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.
