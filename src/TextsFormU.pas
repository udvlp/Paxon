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


unit TextsFormU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, TextsConstsU, ExtCtrls, PanelUlfU, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  PEntry = ^TEntry;
  TEntry = record
    TextKind: TTextKind;
    Loaded: Boolean;
    Text: String;
    PrependDefaultText: Boolean;
  end;


  TTextsForm = class (TFormUlf)

    EventGroupbox: TGroupBox;
    TextKindCombobox: TComboBox;
    AfterDefaultTextCheckbox: TCheckBox;
    TextMemo: TMemo;

    procedure   TextKindComboboxChange (Sender: TObject);

  private

    SoundEntries: Array of TEntry;
    Index: Integer;
    FCall: String;
    FGlobal: Boolean;

    procedure   SaveCurrentText;

  public

    procedure   Init (Global: Boolean); virtual;
    procedure   Save;
    procedure   SetNewCall (aCall: String);

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}

uses
  TextsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TTextsForm.Init (Global: Boolean);
var
  T: TTextKind;
  N: Integer;

begin

  FGlobal := Global;

  FCall := '';

  if (FGlobal) then begin
    TextMemo.ClientHeight := TextMemo.ClientHeight + 18;
    AfterDefaultTextCheckbox.Visible := false;
  end;

  TextKindCombobox.Clear;

  assert (Ord (Low (TTextKind)) = 0);
  SetLength (SoundEntries, Ord (High (TTextKind)) + 1);
  N := 0;
  for T := Low (TTextKind) to High (TTextKind) do begin
    if (not (TextKinds(T).GlobalOnly)) or (FGlobal) then begin
      TextKindCombobox.Items.Add (TextKinds(T).Name);
      SoundEntries[N].TextKind := T;
      SoundEntries[N].Loaded := false;
      inc (N);
    end;
  end;
  SetLength (SoundEntries, N);

  TextKindCombobox.ItemIndex := 0;
  Index := -1;
  TextKindComboboxChange (nil);

end;


procedure   TTextsForm.TextKindComboboxChange (Sender: TObject);
var
  E: PEntry;

begin

  SaveCurrentText;

  Index := TextKindCombobox.ItemIndex;

  if (Index >= 0) then begin

    E := @SoundEntries[Index];

    if (not E.Loaded) then begin
      Texts.Load (FCall, E.TextKind, E.Text, E.PrependDefaultText);
      E.Loaded := true;
    end;

    TextMemo.Text := AdjustLineBreaks (E.Text);

    AfterDefaultTextCheckbox.Checked := (not FGlobal) and E.PrependDefaultText;

  end;

end;


procedure   TTextsForm.SaveCurrentText;
var
  E: PEntry;
begin
  if (Index >= 0) then begin
    E := @SoundEntries[Index];
    E.Text := TextMemo.Text;
    E.PrependDefaultText := AfterDefaultTextCheckbox.Checked;
  end;
end;


procedure   TTextsForm.SetNewCall (aCall: String);
var
  I: Integer;
begin
  FCall := aCall;
  for I := 0 to High (SoundEntries) do begin
    SoundEntries[I].Loaded := false;
  end;
  TextKindComboboxChange (nil);
end;


procedure   TTextsForm.Save;
var
  I, M: Integer;
  E: PEntry;
  S: String;
  B: Boolean;

begin

  TextKindComboboxChange (nil);

  for I := 0 to High (SoundEntries) do begin

    E := @SoundEntries[I];

    if (E.Loaded) then begin

      S := E.Text;
      B := true;
      for M := 1 to Length (S) do begin
        if (not (S[M] in [#32, #13, #10])) then begin
          B := false;
          break;
        end;
      end;

      if (E.PrependDefaultText) and (B) then begin
        Texts.Delete (FCall, E.TextKind);
      end else begin
        Texts.Save (FCall, E.TextKind, E.Text, E.PrependDefaultText);
      end;

    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

