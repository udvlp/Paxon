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


unit PanelUlfU;


interface


uses
  Windows, Messages, SysUtils, Classes, Controls, ExtCtrls;


type
  TThemeMode = (tmDefault, tmNoPaint);

  TPanelUlf = class (TPanel)
  private

    FThemeMode: TThemeMode;

    procedure   SetThemeMode (const Value: TThemeMode);

  protected

    property    FullRepaint;
    procedure   Paint; override;

  public

    constructor Create (AOwner: TComponent); override;
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   Loaded; override;
    procedure   wmEraseBkgnd (var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure   wmThemeChanged (var Message: TWmEraseBkgnd); message WM_THEMECHANGED;

  published

    property    ThemeMode: TThemeMode read FThemeMode write SetThemeMode default tmDefault;

  end;


procedure   Register;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  Graphics;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   Register;
begin
  RegisterComponents ('Paxon', [TPanelUlf]);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TPanelUlf.Create (AOwner: TComponent);
begin
  inherited;
end;


procedure   TPanelUlf.AfterConstruction;
begin
  inherited;
  Caption := '';
  FullRepaint := false;
  ThemeMode := tmDefault;
end;


procedure   TPanelUlf.BeforeDestruction;
begin
  inherited;
end;


procedure   TPanelUlf.Loaded;
begin
  inherited;
  FullRepaint := false;
  if (FThemeMode <> tmDefault) then ParentColor := false;
end;


procedure   TPanelUlf.Paint;
const
  Alignments: array[TAlignment] of Longint = (DT_LEFT, DT_RIGHT, DT_CENTER);

var
  Rect: TRect;
  TopColor, BottomColor: TColor;

begin

  Rect := GetClientRect;

  case ThemeMode of

    tmNoPaint: begin

      if (csDesigning in ComponentState) then begin

        inherited;

      end else begin

        if (BevelOuter <> bvNone) then begin
          if (BevelOuter = bvLowered) then begin
            TopColor := clBtnShadow;
            BottomColor := clBtnHighlight;
          end else begin
            TopColor := clBtnHighlight;
            BottomColor := clBtnShadow;
          end;
          Frame3D (Canvas, Rect, TopColor, BottomColor, BevelWidth);
        end;

        if (BorderWidth > 0) then begin
          Frame3D (Canvas, Rect, Color, Color, BorderWidth);
        end;

        if (BevelInner <> bvNone) then begin
          if (BevelInner = bvLowered) then begin
            TopColor := clBtnShadow;
            BottomColor := clBtnHighlight;
          end else begin
            TopColor := clBtnHighlight;
            BottomColor := clBtnShadow;
          end;
          Frame3D (Canvas, Rect, TopColor, BottomColor, BevelWidth);
        end;

      end;

    end;

    else begin

      inherited;

    end;

  end;

end;


procedure   TPanelUlf.WMEraseBkgnd (var Message: TWmEraseBkgnd);
begin
  case ThemeMode of
    tmNoPaint: Message.Result := 1;
    tmDefault: Message.Result := 1;
    else inherited;
  end;
end;


procedure   TPanelUlf.wmThemeChanged (var Message: TWmEraseBkgnd);
begin
  Message.Result := 0;
end;


procedure   TPanelUlf.SetThemeMode (const Value: TThemeMode);
begin
  if (FThemeMode <> Value) then begin
    FThemeMode := Value;
    if (FThemeMode <> tmDefault) then ParentColor := false;
    invalidate;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

