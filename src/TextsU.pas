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


unit TextsU;


interface


uses
  Windows, Classes, SysUtils, Messages, SyncObjs,
  InterfacesU, TextsConstsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TTexts = class
  private

    CriticalSection: TCriticalSection;

    procedure   LoadGlobal (TextKind: TTextKind; var Text: String); virtual;
    procedure   SaveGlobal (TextKind: TTextKind; const Text: String); virtual;
    procedure   DeleteGlobal (TextKind: TTextKind); virtual;

    function    LoadCall (Call: String; TextKind: TTextKind; var Text: String; var DefaultTextBefore: Boolean): Boolean; virtual;
    procedure   SaveCall (Call: String; TextKind: TTextKind; const Text: String; const DefaultTextBefore: Boolean); virtual;
    procedure   DeleteCall (Call: String; TextKind: TTextKind); virtual;

  public

    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;

    function    Load (Call: String; TextKind: TTextKind; var Text: String; var DefaultTextBefore: Boolean): Boolean; virtual;
    procedure   Save (Call: String; TextKind: TTextKind; const Text: String; const DefaultTextBefore: Boolean); virtual;
    procedure   Delete (Call: String; TextKind: TTextKind); virtual;

    function    Text (aTextType: TTextKind; aConnectionObj: IConnection = nil): String; virtual;
    procedure   SendTextItem (aTextType: TTextKind; aConnectionObj: IConnection); virtual;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  Texts: TTexts;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  GlobalU, Registry, DebOutU, StationDatabaseU;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TTexts.AfterConstruction;
begin
  assert (not assigned (Texts));
  inherited;
  Texts := self;
  CriticalSection := TCriticalSection.create;
end;


procedure   TTexts.BeforeDestruction;
begin
  CriticalSection.free;
  inherited;
  Texts := nil;
end;


function    TTexts.Load (Call: String; TextKind: TTextKind; var Text: String; var DefaultTextBefore: Boolean): Boolean;
const
  MethodName = 'Load';
var
  I: Integer;
begin

  CriticalSection.Enter;
  try

    if (Call = '') then begin
      DebOut (self, MethodName, '*');
      LoadGlobal (TextKind, Text);
      DefaultTextBefore := false;
      result := true;
    end else begin
      DebOut (self, MethodName, Call);
      result := LoadCall (Call, TextKind, Text, DefaultTextBefore);
    end;

    for I := Length (Text) downto 1 do begin
      if (Text[I] = #10) then System.Delete (Text, I, 1);
    end;

  finally
    CriticalSection.Leave;
  end;

end;


procedure   TTexts.Save (Call: String; TextKind: TTextKind; const Text: String; const DefaultTextBefore: Boolean);
const
  MethodName = 'Save';
begin
  CriticalSection.Enter;
  try
    if (Call = '') then begin
      DebOut (self, MethodName, '*');
      SaveGlobal (TextKind, Text);
    end else begin
      DebOut (self, MethodName, Call);
      SaveCall (Call, TextKind, Text, DefaultTextBefore);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TTexts.Delete (Call: String; TextKind: TTextKind);
begin
  CriticalSection.Enter;
  try
    if (Call = '') then begin
      DeleteGlobal (TextKind);
    end else begin
      DeleteCall (Call, TextKind);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TTexts.LoadGlobal (TextKind: TTextKind; var Text: String);
resourcestring
  SDefaultConnectText = #13'Hallo %n...'#13;
  SDefaultQuitText = '<Paxon>: Tschüss...'#13;

var
  S: String;
  Reg: TRegistry;

begin

  CriticalSection.Enter;
  try

    Text := '';

    Reg := TRegistry.Create (KEY_READ or KEY_WRITE);
    try

      Reg.RootKey := HKEY_CURRENT_USER;

      S := Format ('%2.2d', [TextKinds(TextKind).ID]);

      if (Reg.OpenKey (RootRegKey + '\Texts\' + S, false)) then begin
        try
          try
            Text := Reg.ReadString ('Text');
          except
            Text := '';
          end;
        finally
          Reg.CloseKey;
        end;
      end else begin
        case TextKind of
          te_greeting: Text := SDefaultConnectText;
          te_end: Text := SDefaultQuitText;
        end;
      end;

    finally
      Reg.free;
    end;

  finally
    CriticalSection.Leave;
  end;

end;


procedure   TTexts.SaveGlobal (TextKind: TTextKind; const Text: String);
var
  S: String;
  Reg: TRegistry;

begin

  CriticalSection.Enter;
  try

    Reg := TRegistry.Create (KEY_READ or KEY_WRITE);
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      S := Format ('%2.2d', [TextKinds(TextKind).ID]);
      if (Reg.OpenKey (RootRegKey + '\Texts\' + S, true)) then begin
        try
          Reg.WriteString  ('Text', Text);
        finally
          Reg.CloseKey;
        end;
      end;
    finally
      Reg.free;
    end;

  finally
    CriticalSection.Leave;
  end;

end;


procedure   TTexts.DeleteGlobal (TextKind: TTextKind);
var
  S: String;
  Reg: TRegistry;

begin

  CriticalSection.Enter;
  try

    Reg := TRegistry.Create (KEY_READ or KEY_WRITE);
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      S := Format ('%2.2d', [TextKinds(TextKind).ID]);
      if (Reg.OpenKey (RootRegKey + '\Texts\' + S, true)) then begin
        try
          Reg.DeleteValue ('Text');
          Reg.DeleteValue ('StandardText');
        finally
          Reg.CloseKey;
        end;
      end;
    finally
      Reg.free;
    end;

  finally
    CriticalSection.Leave;
  end;

end;


function    TTexts.LoadCall (Call: String; TextKind: TTextKind; var Text: String; var DefaultTextBefore: Boolean): Boolean;
var
  E: IStationDatabaseEntry;

begin

  CriticalSection.Enter;
  try

    result := false;
    E := StationDatabase.Open (Call);
    if (assigned (E)) then begin
      E.GetText (TextKind, Text, DefaultTextBefore);
      result := true;
    end;

  finally
    CriticalSection.Leave;
  end;

end;


procedure   TTexts.SaveCall (Call: String; TextKind: TTextKind; const Text: String; const DefaultTextBefore: Boolean);
var
  E: IStationDatabaseEntry;

begin

  CriticalSection.Enter;
  try

    E := StationDatabase.Open (Call);
    if (assigned (E)) then begin
      E.SetText (TextKind, Text, DefaultTextBefore);
    end;

  finally
    CriticalSection.Leave;
  end;

end;


procedure   TTexts.DeleteCall (Call: String; TextKind: TTextKind);
var
  E: IStationDatabaseEntry;

begin

  CriticalSection.Enter;
  try

    if (Length (Call) > 0) then begin
      E := StationDatabase.Open (Call);
      if (assigned (E)) then begin
        E.DeleteText (TextKind);
      end;
    end;

  finally
    CriticalSection.Leave;
  end;

end;


function    TTexts.Text (aTextType: TTextKind; aConnectionObj: IConnection): String;
var
  Text, StdText, S, U: String;
  B, DefaultTextBefore: Boolean;
  N, L: Integer;
  E: IStationDatabaseEntry;

begin

  if (assigned (aConnectionObj)) then begin
    B := Load (aConnectionObj.Call, aTextType, Text, DefaultTextBefore);
    if (not B) then begin
      B := Load (StripSSID (aConnectionObj.Call), aTextType, Text, DefaultTextBefore);
    end;
  end else begin
    B := false;
  end;

  if (not B) or (DefaultTextBefore) then begin
    if (not B) then Text := '';
    Load ('', aTextType, StdText, DefaultTextBefore);
  end else begin
    StdText := '';
  end;

  S := StdText + Text;

  result := '';
  L := Length (S);
  N := 1;
  while (N <= L) do begin
    if (S[N] = '%') then begin
      Inc (N);
      if (N > L) then begin
        // Keep '%' at the end unchanged
        U := '%';
      end else case UpCase(S[N]) of
        'N': begin
          if (assigned (aConnectionObj)) then begin
            E := aConnectionObj.StationDatabaseEntry;
            if (assigned (E)) then begin
              U := E.Name;
            end else begin
              U := '';
            end;
            if (U = '') then begin
              U := aConnectionObj.Call;
            end;
          end else begin
            U := '?';
          end;
        end;
        '%': begin
          U := '%'
        end;
        else begin
          // Keep unknown sequence unchanged
          U := '%';
          if (S[N] <> #10) then U := U + S[N];
        end;
      end;
      result := result + U;
    end else if (S[N] <> #10) then begin
      result := result + S[N];
    end;
    Inc (N);
  end;

end;


procedure   TTexts.SendTextItem (aTextType: TTextKind; aConnectionObj: IConnection);
begin
  assert (assigned (aConnectionObj));
  aConnectionObj.SendTextData (Text (aTextType, aConnectionObj), true, true);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

