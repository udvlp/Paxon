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


unit HintU;


interface


uses
  Classes, Windows, Graphics, Messages, Controls, Forms, SysUtils;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  THintWindowUlf = class (THintWindow)
  private

    BackgroundBitmap: TBitmap;

  protected

    procedure   Paint; override;
    procedure   CreateParams (var Params: TCreateParams); override;
    procedure   wmEraseBkgnd (var Msg: TMessage); message wm_erasebkgnd;

  public

    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   ActivateHint (HintRect: TRect; const AHint: string); override;
    function    CalcHintRect (MaxWidth: Integer; const AHint: string; AData: Pointer): TRect; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  GlobalU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   THintWindowUlf.AfterConstruction;

begin

  inherited;

  if (HighColor) then begin
    BackgroundBitmap := TBitmap.create;
    BackgroundBitmap.LoadFromResourceName (Hinstance, 'HintBackground');
  end else begin
    BackgroundBitmap := nil;
  end;

end;


procedure   THintWindowUlf.BeforeDestruction;
begin
  if (assigned (BackgroundBitmap)) then BackgroundBitmap.free;
  inherited;
end;


procedure   THintWindowUlf.CreateParams (var Params: TCreateParams);
const
  CS_DROPSHADOW = $00020000;
begin
  inherited CreateParams (Params);
  if (Win32Platform = VER_PLATFORM_WIN32_NT) and
     ((Win32MajorVersion > 5) or ((Win32MajorVersion = 5) and (Win32MinorVersion >= 1))) then begin
    Params.WindowClass.Style := Params.WindowClass.Style or CS_DROPSHADOW;
  end;
end;


procedure   THintWindowUlf.wmEraseBkgnd (var Msg: TMessage);
begin
  Msg.result := 1;
end;


procedure   THintWindowUlf.Paint;
var
  TextRect: TRect;
begin
  if (assigned (BackgroundBitmap)) then begin
    canvas.StretchDraw (Rect (ClientRect.Left, ClientRect.Top, ClientRect.Right, ClientRect.Bottom), BackgroundBitmap);
  end else begin
    canvas.brush.Color := clInfoBk;
    canvas.brush.Style := bsSolid;
    canvas.FillRect (Rect (ClientRect.Left, ClientRect.Top, ClientRect.Right, ClientRect.Bottom));
  end;
  canvas.brush.Style := bsClear;
  TextRect := Rect (ClientRect.Left + 4, ClientRect.Top + 1, ClientRect.Right, ClientRect.Bottom);
  DrawText (canvas.handle, PChar(Caption), Length (Caption), TextRect, DT_WORDBREAK or DT_NOPREFIX);
end;


function    THintWindowUlf.CalcHintRect (MaxWidth: Integer; const AHint: string; AData: Pointer): TRect;
begin
  result.left := 0;
  result.right := MaxWidth;
  result.top := 0;
  result.bottom := 0;
  DrawText (Canvas.Handle, PChar(AHint), Length (AHint), result, DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
  inc (result.bottom, 5);
  inc (result.right, 10);
end;


procedure   THintWindowUlf.ActivateHint (HintRect: TRect; const AHint: string);
var
  Pnt: TPoint;

begin
  if (Length (Trim (AHint)) > 0) then begin
    Caption := AHint;
    BoundsRect := HintRect;
    Pnt := ClientToScreen (Point (0, 0));
    SetWindowPos (Handle, HWND_TOPMOST, Pnt.X, Pnt.Y, 0, 0, SWP_SHOWWINDOW or SWP_NOACTIVATE or SWP_NOSIZE);
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  HintWindowClass := THintWindowUlf;

end.

