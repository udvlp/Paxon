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


unit ToolbarHelpU;


// Small drawing and system helpers for the bars (ToolbarU) and the
// TBX themes in VCL\tbxthemes. Their names and parameters are the
// ones the themes call, so the themes need no
// changes.


interface


uses
  Windows, Messages, SysUtils, Graphics;


const
  // DrawText: evaluate prefix characters, but do not underline (Windows 2000 and later)
  DT_HIDEPREFIX = $00100000;


// Windows XP or newer (visual styles, CS_DROPSHADOW, flat menus)
function    IsWindowsXP: Boolean;

// Boolean value from SystemParametersInfo, Default if the query fails
function    GetSystemParametersInfoBool (const Param: UINT; const Default: BOOL): BOOL;

// Processes pending WM_PAINT messages (before capturing screen content)
procedure   ProcessPaintMessages;

// Draws a hatched frame (NewRect, thickness NewSize) by inverting and
// erases the previous one (OldRect, OldSize) at the same time. Called twice with the same values,
// the screen is as before. OldRect empty: nothing to erase.
procedure   DrawHalftoneInvertRect (const DC: HDC; const NewRect, OldRect: TRect;
                                    const NewSize, OldSize: TSize);

// Outputs text rotated 90 degrees clockwise (readable from top to bottom),
// for vertical bars. Across the text it is always centered; DT_CENTER
// centers along the text (i.e. vertically), otherwise it starts at the top. Also
// evaluated: DT_NOPREFIX, DT_HIDEPREFIX, DT_END_ELLIPSIS and DT_NOCLIP (without it, output is
// clipped to ARect). As with DrawText, '&' underlines the following character.
// This is what the TBX themes expect.
procedure   DrawRotatedText (const DC: HDC; AText: String; const ARect: TRect;
                             const AFormat: Cardinal);

// The DC's font rotated by 270 degrees (the caller frees it with DeleteObject).
// Raster fonts (MS Sans Serif) cannot be rotated; Tahoma is used instead.
// Rotated text must be measured with this font: because of hinting
// the widths differ from those of the unrotated font.
function    RotatedFont (const DC: HDC): HFONT;

var
  // Font of the bars and menus: the system menu font (NONCLIENTMETRICS).
  // ToolbarU calls UpdateToolbarFont when the system settings change.
  ToolbarFont: TFont;

procedure   UpdateToolbarFont;

// Smaller or larger value (as in Math; the themes expect them here)
function    Min (const A, B: Integer): Integer;
function    Max (const A, B: Integer): Integer;

// Halftone brush (1:1 checkerboard), freed when the program ends
function    HalftoneBrush: HBRUSH;

// Text without prefix characters; index (1-based) of the underlined character in UnderlinePos
// (0: none). '&&' becomes '&'.
function    WithoutPrefix (const Text: String; var UnderlinePos: Integer): String;

// Width of a text in the DC's font; Prefix: evaluate '&' as prefix character
function    GetTextWidth (const DC: HDC; S: String; const Prefix: Boolean): Integer;


implementation


function    GetTextWidth (const DC: HDC; S: String; const Prefix: Boolean): Integer;
var
  U: Integer;
  SizeValue: TSize;
begin
  if (Prefix) then S := WithoutPrefix (S, U);
  SizeValue.cx := 0;
  GetTextExtentPoint32 (DC, PChar(S), Length (S), SizeValue);
  result := SizeValue.cx;
end;


var
  FHalftoneBrush: HBRUSH = 0;


procedure   UpdateToolbarFont;
var
  NCM: TNonClientMetrics;
begin
  if (not assigned (ToolbarFont)) then ToolbarFont := TFont.Create;
  FillChar (NCM, SizeOf (NCM), 0);
  NCM.cbSize := SizeOf (NCM);
  if (SystemParametersInfo (SPI_GETNONCLIENTMETRICS, SizeOf (NCM), @NCM, 0)) then begin
    ToolbarFont.Handle := CreateFontIndirect (NCM.lfMenuFont);
  end else begin
    ToolbarFont.Handle := GetStockObject (DEFAULT_GUI_FONT);
  end;
  ToolbarFont.Color := clBtnText;
end;


function    Min (const A, B: Integer): Integer;
begin
  if (A < B) then result := A else result := B;
end;


function    Max (const A, B: Integer): Integer;
begin
  if (A > B) then result := A else result := B;
end;


function    IsWindowsXP: Boolean;
begin
  result := (Win32Platform = VER_PLATFORM_WIN32_NT) and
            ((Win32MajorVersion > 5) or ((Win32MajorVersion = 5) and (Win32MinorVersion >= 1)));
end;


function    GetSystemParametersInfoBool (const Param: UINT; const Default: BOOL): BOOL;
var
  B: BOOL;
begin
  B := Default;
  if (SystemParametersInfo (Param, 0, @B, 0)) then result := B else result := Default;
end;


procedure   ProcessPaintMessages;
var
  Msg: TMsg;
  N: Integer;
begin
  // Otherwise a window that does not validate WM_PAINT would stay in the queue forever
  N := 0;
  while (N < 256) and (PeekMessage (Msg, 0, WM_PAINT, WM_PAINT, PM_REMOVE)) do begin
    DispatchMessage (Msg);
    inc (N);
  end;
end;


function    HalftoneBrush: HBRUSH;
const
  PatternData: array[0..7] of Word = ($55, $AA, $55, $AA, $55, $AA, $55, $AA);
var
  Bmp: HBITMAP;
begin
  if (FHalftoneBrush = 0) then begin
    Bmp := CreateBitmap (8, 8, 1, 1, @PatternData);
    FHalftoneBrush := CreatePatternBrush (Bmp);
    DeleteObject (Bmp);
  end;
  result := FHalftoneBrush;
end;


procedure   DrawHalftoneInvertRect (const DC: HDC; const NewRect, OldRect: TRect;
                                    const NewSize, OldSize: TSize);

  // Frame area of a rectangle as a region (0 for an empty rectangle)
  function  FrameRegion (const R: TRect; const S: TSize): HRGN;
  var
    Interior: HRGN;
    RI: TRect;
  begin
    if (IsRectEmpty (R)) then begin
      result := 0;
      exit;
    end;
    result := CreateRectRgnIndirect (R);
    RI := R;
    InflateRect (RI, -S.cx, -S.cy);
    if (not IsRectEmpty (RI)) then begin
      Interior := CreateRectRgnIndirect (RI);
      CombineRgn (result, result, Interior, RGN_DIFF);
      DeleteObject (Interior);
    end;
  end;

var
  NewRegion, OldRegion: HRGN;
  R: TRect;
  OldBrushHandle: HBRUSH;

begin
  NewRegion := FrameRegion (NewRect, NewSize);
  OldRegion := FrameRegion (OldRect, OldSize);
  try
    // Where the old and new frame overlap, the image remains unchanged
    if (NewRegion = 0) then begin
      NewRegion := OldRegion;
      OldRegion := 0;
    end else if (OldRegion <> 0) then begin
      CombineRgn (NewRegion, NewRegion, OldRegion, RGN_XOR);
    end;
    if (NewRegion = 0) then exit;
    SaveDC (DC);
    try
      SelectClipRgn (DC, NewRegion);
      GetClipBox (DC, R);
      OldBrushHandle := SelectObject (DC, HalftoneBrush);
      PatBlt (DC, R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, PATINVERT);
      SelectObject (DC, OldBrushHandle);
    finally
      RestoreDC (DC, -1);
    end;
  finally
    if (NewRegion <> 0) then DeleteObject (NewRegion);
    if (OldRegion <> 0) then DeleteObject (OldRegion);
  end;
end;


function    WithoutPrefix (const Text: String; var UnderlinePos: Integer): String;
var
  I: Integer;
begin
  result := '';
  UnderlinePos := 0;
  I := 1;
  while (I <= Length (Text)) do begin
    if (Text[I] = '&') and (I < Length (Text)) then begin
      inc (I);
      if (Text[I] <> '&') and (UnderlinePos = 0) then UnderlinePos := Length (result) + 1;
    end;
    result := result + Text[I];
    inc (I);
  end;
end;


function    FontFound (const LF: TEnumLogFont; const TM: TNewTextMetric; FontType: Integer; Data: LPARAM): Integer; stdcall;
begin
  PBoolean(Data)^ := true;
  result := 0;
end;


function    FontPresent (const DC: HDC; const Name: String): Boolean;
begin
  result := false;
  EnumFontFamilies (DC, PChar(Name), @FontFound, LPARAM(@result));
end;


function    RotatedFont (const DC: HDC): HFONT;
var
  LF: TLogFont;
  TM: TTextMetric;
begin
  FillChar (LF, SizeOf (LF), 0);
  if (GetObject (GetCurrentObject (DC, OBJ_FONT), SizeOf (LF), @LF) = 0) then begin
    result := 0;
    exit;
  end;
  LF.lfEscapement := 2700;
  LF.lfOrientation := 2700;
  LF.lfOutPrecision := OUT_TT_ONLY_PRECIS;
  if (StrIComp (LF.lfFaceName, 'MS Sans Serif') = 0) or (StrIComp (LF.lfFaceName, 'Microsoft Sans Serif') = 0) then begin
    StrPCopy (LF.lfFaceName, 'Tahoma');
    // use the actual height, not the requested one
    if (GetTextMetrics (DC, TM)) then begin
      if (LF.lfHeight <= 0) then LF.lfHeight := -(TM.tmHeight - TM.tmInternalLeading)
      else LF.lfHeight := TM.tmHeight;
    end;
  end;
  // If there is a vertical variant ('@' + name), East Asian characters stand upright
  if (FontPresent (DC, '@' + String (LF.lfFaceName))) then begin
    StrPLCopy (LF.lfFaceName, '@' + String (LF.lfFaceName), SizeOf (LF.lfFaceName) - 1);
  end;
  result := CreateFontIndirect (LF);
end;


procedure   DrawRotatedText (const DC: HDC; AText: String; const ARect: TRect;
                             const AFormat: Cardinal);
var
  RotatedHFont, OldFontHandle: HFONT;
  TM: TTextMetric;
  S: String;
  U, X, Y, LengthValue, OffsetBefore, WidthPx, UX: Integer;
  SizeValue: TSize;
  PenHandle, OldPenHandle: HPEN;
  OldAlignment: UINT;

begin

  if (AText = '') then exit;
  if (AFormat and DT_NOPREFIX <> 0) then begin
    S := AText;
    U := 0;
  end else begin
    S := WithoutPrefix (AText, U);
  end;

  RotatedHFont := RotatedFont (DC);
  if (RotatedHFont = 0) then exit;
  OldFontHandle := SelectObject (DC, RotatedHFont);
  try

    // Measure everything with the rotated font
    GetTextMetrics (DC, TM);
    GetTextExtentPoint32 (DC, PChar(S), Length (S), SizeValue);
    LengthValue := SizeValue.cx;

    // Too long: truncate at the end and append '...'
    if (AFormat and DT_END_ELLIPSIS <> 0) and (Length (S) > 1) and (LengthValue > ARect.Bottom - ARect.Top) then begin
      if (ARect.Bottom - ARect.Top > 2) then begin
        repeat
          SetLength (S, Length (S) - 1);
          GetTextExtentPoint32 (DC, PChar(S + '...'), Length (S) + 3, SizeValue);
        until (Length (S) <= 1) or (SizeValue.cx <= ARect.Bottom - ARect.Top);
      end else begin
        SetLength (S, 1);
      end;
      if (U > Length (S)) then U := 0;
      S := S + '...';
      GetTextExtentPoint32 (DC, PChar(S), Length (S), SizeValue);
      LengthValue := SizeValue.cx;
    end;

    if (AFormat and DT_NOCLIP = 0) then begin
      SaveDC (DC);
      IntersectClipRect (DC, ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    end;
    try

      // At 270 degrees the reference point (top left corner of the text) is at the top right;
      // the characters grow to the left, the text downwards.
      X := (ARect.Left + ARect.Right + TM.tmHeight) div 2;
      if (AFormat and DT_CENTER <> 0) then begin
        Y := ARect.Top + ((ARect.Bottom - ARect.Top) - LengthValue) div 2;
      end else begin
        Y := ARect.Top;
      end;

      OldAlignment := SetTextAlign (DC, TA_LEFT or TA_TOP or TA_NOUPDATECP);
      TextOut (DC, X, Y, PChar(S), Length (S));
      SetTextAlign (DC, OldAlignment);

      if (U > 0) and (AFormat and DT_HIDEPREFIX = 0) then begin
        OffsetBefore := 0;
        if (U > 1) then begin
          GetTextExtentPoint32 (DC, PChar(S), U - 1, SizeValue);
          OffsetBefore := SizeValue.cx;
        end;
        GetTextExtentPoint32 (DC, @S[U], 1, SizeValue);
        WidthPx := SizeValue.cx;
        // Underline two lines below the baseline, i.e. to the left of it
        UX := X - TM.tmAscent - 2;
        PenHandle := CreatePen (PS_SOLID, 1, GetTextColor (DC));
        OldPenHandle := SelectObject (DC, PenHandle);
        MoveToEx (DC, UX, Y + OffsetBefore, nil);
        LineTo (DC, UX, Y + OffsetBefore + WidthPx);
        SelectObject (DC, OldPenHandle);
        DeleteObject (PenHandle);
      end;

    finally
      if (AFormat and DT_NOCLIP = 0) then RestoreDC (DC, -1);
    end;

  finally
    SelectObject (DC, OldFontHandle);
    DeleteObject (RotatedHFont);
  end;

end;


initialization
  UpdateToolbarFont;

finalization
  FreeAndNil (ToolbarFont);
  if (FHalftoneBrush <> 0) then DeleteObject (FHalftoneBrush);

end.
