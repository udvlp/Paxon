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


unit ComboBoxUlfU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TOnComplete = procedure (Sender: TObject; var Text: String; var CompleteWith: string; var Finish: Boolean) of object;


  TComboBoxUlf = class (TComboBox)
  private
    FComplete: Boolean;
    FKey: Byte;
    FOnComplete: TOnComplete;
    FExtendedUI: Boolean;
    procedure   SetComplete (Value: Boolean);
    function    GetExtendedUI: Boolean;
    procedure   SetExtendedUI (const Value: Boolean);
  public
    OldHintHidePause: Integer;
    constructor Create (aOwner: TComponent); override;
  protected
    procedure   KeyDown (var Key: Word; Shift: TShiftState); override;
    procedure   KeyPress (var Key: Char); override;
    procedure   Change; override;
    procedure   Loaded; override;
  published
    property    Complete: Boolean read FComplete write SetComplete;
    property    OnComplete: TOnComplete read FOnComplete write FOnComplete;
    property    CharCase;
    property    ExtendedUI: Boolean read GetExtendedUI write SetExtendedUI default false;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure Register;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.RES}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   Register;
begin
  RegisterComponents('Paxon', [TComboBoxUlf]);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TComboBoxUlf.create (aOwner: Tcomponent);
begin
  inherited create (aOwner);
  FComplete := true;
  FKey := 0;
  FExtendedUI := false;
end;


procedure   TComboBoxUlf.Loaded;
begin
  inherited;
end;


procedure   TComboBoxUlf.KeyDown (var Key: Word; Shift: TShiftState);
var
  I: Integer;
  N: Integer;

begin

  if (Key = VK_DELETE) and (DroppedDown) then begin
    N := SendMessage (Handle, CB_GETTOPINDEX, 0, 0);
    I := ItemIndex;
    Items.Delete (I);
    if (I >= Items.Count) then I := Items.Count - 1;
    ItemIndex := I;
    SendMessage (Handle, CB_SETTOPINDEX, N, 0);
    Key := 0;
    FKey := 0;
  end else if (Key <= $FF) and (IsCharAlphaNumeric (Char(Key and $FF))) then begin
    if (DroppedDown) then DroppedDown := false;
  end;

  FKey := Key;

  if (Key <> 0) then inherited;

end;


procedure   TComboBoxUlf.KeyPress (var Key: Char);
begin
  if (Key = #9) then begin
    if (DroppedDown) then begin
      FKey := 0;
      Key := #0;
      DroppedDown := false;
      PostMessage (Handle, wm_keydown, vk_tab, 0);
    end;
  end else begin
    inherited;
  end;
end;


procedure   TComboBoxUlf.Change;
const
  MethodName = 'Change';

var
  S, T, W: string;
  I, N: Integer;
  Finish: Boolean;

begin

  if (FComplete) and (Style in [csDropDown, csSimple]) and (FKey <> 0) and (FKey <> VK_DELETE) and (FKey <> VK_BACK) then begin

    Finish := false;
    T := Text;
    N := Length (T);
    S := '';

    if (SelStart >= N) then begin

      if (assigned (FOnComplete)) then begin
        FOnComplete (self, T, S, Finish);
      end;

      if (not Finish) then begin
        if (Items.Count > 0) then begin
          for I := 0 to Items.Count - 1 do begin
            W := Items.Strings[I];
            if (AnsiCompareText (T, Copy (W, 1, N)) = 0) then begin
              S := Copy (W, N + 1, MaxInt);
              Finish := true;
              break;
            end;
          end;
        end;
      end;

      if (Finish) then begin
        Text := T + S;
        SendMessage (Handle, CB_SETEDITSEL, 0, MakeLParam (N, $FFFF));
      end;

    end;

  end;

  inherited Change;

end;


procedure   TComboBoxUlf.SetComplete (Value: Boolean);
begin
  FComplete := Value;
end;


function    TComboBoxUlf.GetExtendedUI: Boolean;
begin
  result := FExtendedUI;
end;


procedure   TComboBoxUlf.SetExtendedUI (const Value: Boolean);
begin
  FExtendedUI := Value;
  SendMessage (Handle, CB_SETEXTENDEDUI, Integer(FExtendedUI), 0);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

