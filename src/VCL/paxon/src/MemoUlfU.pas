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


unit MemoUlfU;


interface


uses
  Windows, Classes, SysUtils, Messages, ComCtrls, StdCtrls;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TMemoUlf = class (TMemo)
  private
    FDigitsOnly: Boolean;
    EatNextKey: Boolean;
    procedure   SetDigitsOnly (const Value: Boolean);
  protected
    procedure   wmSetText (var Msg: TMessage); message wm_settext;
    procedure   KeyPress (var Key: Char); override;
    procedure   wmKeyDown (var Msg: TMessage);  message wm_keydown;
    procedure   wmChar (var Msg: TMessage);     message wm_char;
  published
    property    DigitsOnly: Boolean read FDigitsOnly write SetDigitsOnly;
    property    AutoSelect;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure Register;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TMemoUlf.SetDigitsOnly (const Value: Boolean);
var
  S, T: string;
  N: Integer;
begin
  FDigitsOnly := Value;
  if (not (csLoading in ComponentState)) and
     (not (csDesigning in ComponentState)) and
     (not (csReading in ComponentState)) then begin
    if FDigitsOnly then begin
      S := Text;
      T := '';
      for N := 1 to Length (S) do begin
        if (S[N] in ['0'..'9']) then T := T + S[N];
      end;
      Text := T;
    end;
  end;
end;


procedure   TMemoUlf.wmSetText (var Msg: TMessage);
begin
  inherited;
  if HandleAllocated and Assigned (Parent) then begin    SelStart := Length (Text);
    if (not (csLoading in ComponentState)) and
       (not (csDesigning in ComponentState)) and
       (not (csReading in ComponentState)) then begin
      Change;
    end;
  end;
end;


procedure   TMemoUlf.KeyPress (var Key: Char);
const
  MethodName = 'KeyPress';
begin
  if (FDigitsOnly) then begin
    if not (Key in ['0'..'9', #8]) then Key := #0;
  end;
  inherited KeyPress (Key); // OnKeyPress
end;


procedure   TMemoUlf.wmKeyDown (var Msg: TMessage);
const
  MethodName = 'wmKeyDown';

var
  AltPressed, Ctrl, Shift: Boolean;

begin

  AltPressed := ((GetAsyncKeyState (VK_MENU) and $80000000) <> 0);
  Ctrl := ((GetAsyncKeyState (VK_CONTROL) and $80000000) <> 0);
  Shift := ((GetAsyncKeyState (VK_SHIFT) and $80000000) <> 0);

  case (Msg.wParam) of

    ord ('A') .. ord ('Z'): begin
      if (not AltPressed) and (Ctrl) then begin
        if (Shift) then begin
          SelText := '^' + Chr(Msg.wParam);
          Msg.wParam := 0;
          Msg.lParam := 0;
          Msg.Result := 0;
          EatNextKey := true;
        end else begin
          // Ctrl+Z (undo), like Ctrl+C/V/X, goes through WM_CHAR and must pass through
          if (Chr(Msg.wParam) in ['A', 'X', 'C', 'V', 'Z']) then begin
            inherited;
          end else begin
            Msg.wParam := 0;
            Msg.lParam := 0;
            Msg.Result := 0;
            // TranslateMessage has already generated the control character (WM_CHAR)
            EatNextKey := true;
          end;
        end;
      end else begin
        inherited;
      end;
    end;

    else begin
      inherited;
    end;

  end;

end;


procedure   TMemoUlf.wmChar (var Msg: TMessage);
const
  MethodName = 'wmChar';
begin
  if (Msg.wParam < 32) and (EatNextKey) then begin
    Msg.wParam := 0;
    Msg.lParam := 0;
    Msg.Result := 0;
  end else begin
    inherited;
  end;
  EatNextKey := false;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure Register;
begin
  RegisterComponents('Paxon', [TMemoUlf]);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

