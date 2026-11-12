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


unit ColorButtonUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


interface

uses
  Windows, Messages, Classes, Controls, Forms, Graphics, StdCtrls, ExtCtrls,
  CommCtrl;


type


  TButtonState = (bsUp, bsDisabled, bsDown, bsExclusive);

  TColorButtonUlf = class (TButton)
  private
    FColor: TColor;
    FCanvas: TCanvas;
    IsFocused: Boolean;
    FMouseInControl: Boolean;
    procedure DrawItem (const DrawItemStruct: TDrawItemStruct);
    procedure CNMeasureItem (var Message: TWMMeasureItem); message CN_MEASUREITEM;
    procedure CNDrawItem (var Message: TWMDrawItem); message CN_DRAWITEM;
    procedure CMEnabledChanged (var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMMouseEnter (var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave (var Message: TMessage); message CM_MOUSELEAVE;
    procedure SetColor (Value: TColor);
  protected
    procedure CreateHandle; override;
    procedure CreateParams (var Params: TCreateParams); override;
    procedure SetButtonStyle (ADefault: Boolean); override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    property Color: TColor read FColor write SetColor;
  end;


procedure Register;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  Consts, Themes, SysUtils;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure Register;
begin
  RegisterComponents ('Paxon', [TColorButtonUlf]);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TColorButtonUlf.Create (AOwner: TComponent);
begin
  inherited Create (AOwner);
  FCanvas := TCanvas.Create;
  ControlStyle := ControlStyle + [csReflector] - [csDoubleClicks];
  DoubleBuffered := True;
  FColor := clWhite;
  Width := 31;
  Height := 23;
end;


destructor  TColorButtonUlf.Destroy;
begin
  inherited Destroy;
  FCanvas.Free;
end;


procedure   TColorButtonUlf.CreateHandle;
begin
  inherited CreateHandle;
end;


procedure   TColorButtonUlf.CreateParams (var Params: TCreateParams);
begin
  inherited CreateParams (Params);
  with Params do Style := Style or BS_OWNERDRAW;
end;


procedure   TColorButtonUlf.SetButtonStyle (ADefault: Boolean);
begin
  if ADefault <> IsFocused then begin
    IsFocused := ADefault;
    Refresh;
  end;
end;


procedure   TColorButtonUlf.Click;
begin
  inherited Click;
end;


procedure   TColorButtonUlf.CNMeasureItem (var Message: TWMMeasureItem);
begin
  with Message.MeasureItemStruct^ do begin
    itemWidth := Width;
    itemHeight := Height;
  end;
end;


procedure   TColorButtonUlf.CNDrawItem (var Message: TWMDrawItem);
begin
  DrawItem (Message.DrawItemStruct^);
end;


procedure   TColorButtonUlf.DrawItem (const DrawItemStruct: TDrawItemStruct);
var
  IsDown, IsDefault: Boolean;
  R: TRect;
  Flags: Longint;
  Details: TThemedElementDetails;
  Button: TThemedButton;
  Offset: TPoint;
  ColorRect: TRect;

begin

  FCanvas.Handle := DrawItemStruct.hDC;

  R := ClientRect;

  with DrawItemStruct do begin
    FCanvas.Handle := hDC;
    FCanvas.Font := Self.Font;
    IsDown := itemState and ODS_SELECTED <> 0;
    IsDefault := itemState and ODS_FOCUS <> 0;
  end;

  if ThemeServices.ThemesEnabled then begin

    if not Enabled then begin
      Button := tbPushButtonDisabled
    end else begin
      if IsDown then begin
        Button := tbPushButtonPressed
      end else begin
        if FMouseInControl then begin
          Button := tbPushButtonHot
        end else begin
          if IsFocused or IsDefault then begin
            Button := tbPushButtonDefaulted
          end else begin
            Button := tbPushButtonNormal;
          end;
        end;
      end;
    end;

    Details := ThemeServices.GetElementDetails (Button);

    ThemeServices.DrawParentBackground (Handle, DrawItemStruct.hDC, @Details, True); // Parent background.
    ThemeServices.DrawElement (DrawItemStruct.hDC, Details, DrawItemStruct.rcItem); // Button shape.
    R := ThemeServices.ContentRect (FCanvas.Handle, Details, DrawItemStruct.rcItem);

    if Button = tbPushButtonPressed then begin
      Offset := Point (1, 0)
    end else begin
      Offset := Point (0, 0);
    end;

    if IsFocused and IsDefault then begin
      FCanvas.Pen.Color := clWindowFrame;
      FCanvas.Brush.Color := clBtnFace;
      DrawFocusRect (FCanvas.Handle, R);
    end;

    R := ClientRect;
    ColorRect := Rect (R.Left + 6, R.Top + 6, R.Right - 6, R.Bottom - 6);

  end else begin

    R := ClientRect;

    Flags := DFCS_BUTTONPUSH or DFCS_ADJUSTRECT;
    if IsDown then Flags := Flags or DFCS_PUSHED;
    if DrawItemStruct.itemState and ODS_DISABLED <> 0 then Flags := Flags or DFCS_INACTIVE;

    (*
    { DrawFrameControl doesn't allow for drawing a button as the default button, so it must be done here. }
    if IsFocused or IsDefault then begin
      FCanvas.Pen.Color := clWindowFrame;
      FCanvas.Pen.Width := 1;
      FCanvas.Brush.Style := bsClear;
      FCanvas.Rectangle (R.Left, R.Top, R.Right, R.Bottom);
      InflateRect (R, -1, -1);
    end;
    *)

    { DrawFrameControl does not draw a pressed button correctly }
    if IsDown then begin
      FCanvas.Pen.Color := clBtnShadow;
      FCanvas.Pen.Width := 1;
      FCanvas.Brush.Color := clBtnFace;
      FCanvas.Rectangle (R.Left, R.Top, R.Right, R.Bottom);
      InflateRect (R, -1, -1);
    end else begin
      DrawFrameControl (DrawItemStruct.hDC, R, DFC_BUTTON, Flags);
    end;

    if IsFocused then begin
      R := ClientRect;
      InflateRect (R, -1, -1);
    end;

    FCanvas.Font := Self.Font;

    if IsFocused and IsDefault then begin
      R := ClientRect;
      if IsDown then OffsetRect (R, 1, 1);
      R := Rect (R.Left + 2, R.Top + 2, R.Right - 3, R.Bottom - 3);
      FCanvas.Pen.Color := clWindowFrame;
      FCanvas.Brush.Color := clBtnFace;
      DrawFocusRect (FCanvas.Handle, R);
    end;

    R := ClientRect;
    ColorRect := Rect (R.Left + 5, R.Top + 5, R.Right - 6, R.Bottom - 6);

    if IsDown then OffsetRect (ColorRect, 1, 1);

  end;

  FCanvas.Pen.Color := cl3DDkShadow;
  FCanvas.Rectangle (ColorRect.Left - 1, ColorRect.Top - 1, ColorRect.Right + 1, ColorRect.Bottom + 1);

  FCanvas.Brush.Style := bsSolid;
  FCanvas.Brush.Color := FColor;
  FCanvas.FillRect (ColorRect);

  FCanvas.Handle := 0;

end;


procedure   TColorButtonUlf.CMEnabledChanged (var Message: TMessage);
begin
  inherited;
  Invalidate;
end;


procedure   TColorButtonUlf.CMMouseEnter (var Message: TMessage);
begin
  inherited;
  if ThemeServices.ThemesEnabled and not FMouseInControl and not (csDesigning in ComponentState) then begin
    FMouseInControl := True;
    Repaint;
  end;
end;


procedure   TColorButtonUlf.CMMouseLeave (var Message: TMessage);
begin
  inherited;
  if ThemeServices.ThemesEnabled and FMouseInControl then begin
    FMouseInControl := False;
    Repaint;
  end;
end;


procedure   TColorButtonUlf.SetColor (Value: TColor);
begin
  FColor := Value;
  Repaint;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

