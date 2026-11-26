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


unit ConsoleU;


interface


uses
  Windows, Messages, Classes, Controls, Forms, Graphics, SysUtils,
  ClipBrd, DragTextU, extctrls, ImgList, AppEvnts;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  ExtraBytesPerLine = 20;


type

  EConsole = Exception;


  TConsole = class;


  TConsoleLineBreak = (CRLF, CR, LF);


  THintType = (htText, htGutter, htOther);
  TScrollState = (ssTop, ssMiddle, ssBottom);


  TOnHint = function (Sender: TConsole; HintType: THintType; XT, YT: Integer): AnsiString of object;
  TOnGutterClick = procedure (Sender: TConsole; Line: Integer) of object;


  PFileHeader = ^TFileHeader;
  TFileHeader = packed record
    Signature: array[0..63] of AnsiChar;
    FormatVersion: Cardinal;
    Cols: Integer;
    Rows: Integer;
    FirstLine: Integer;   // First visible line in circular buffer
    Cursor: TPoint;       // Cursor location
    LastAbsNo: Cardinal;
  end;


  PLineHeader = ^TLineHeader;
  TLineHeader = packed record
    AbsNo: Cardinal;
    Time: Cardinal;
    Length: Byte;
    LineType: Byte;
    ImageIndex: Byte;
    EOLColor: Byte;
  end;


  TConsole = class (TCustomControl)
  private

    FScrollState: TScrollState;
    FFocused: Boolean;
    FFont: TFont;
    FCols: Integer;
    FRows: Integer;
    FLineBreak: TConsoleLineBreak;
    FTextColor: Cardinal;
    FVPalette: Array[0..15] of Cardinal;
    FHPalette: Array[0..15] of Cardinal;
    FRange: TPoint;                   // Scroll bar ranges
    FOrigin: TPoint;                  // Client/scroll origin
    FClientSize: TPoint;              // Number of visible whole cells
    FCharSize: TPoint;                // Character cell size
    FCharAscent: Integer;             // Baseline location (for caret)
    FOverhang: Integer;               // Extra space needed for chars
    FCaret: TPoint;

    FActive: Boolean;
    FTextBuffer: PAnsiChar;
    FBuffer: PAnsiChar;
    FFileHeader: PFileHeader;
    FStream: TFileStream;
    FMappingHandle: THandle;
    FFileName: AnsiString;
    FVirtualMemory: Boolean;
    FSelection: TRect;
    FSelectionAnchor: TPoint;
    FMousePos: TPoint;
    FWheelRemainder: Integer;              // not yet scrolled remainder of small mouse wheel steps (pixels)
    FShowDOS: Boolean;

    FDragsText: Boolean;
    DragStartingPoint: TPoint;

    FHintPos: TPoint;
    FHintWindow: THintWindow;

    FOnHint: TOnHint;
    FOnGutterClick: TOnGutterClick;

    FGutterWidth: Integer;
    FGutterColor: TColor;
    FGutterLineColor: TColor;
    FListbackgroundColor: TColor;

    FGutterImages: TCustomImageList;

    ApplicationEvents: TApplicationEvents;

    procedure   DoFontChanged (Sender: TObject);
    procedure   ResizeBuffer;
    procedure   RecalibrateFont;
    procedure   RecalcSizeAndRange;
    procedure   ShowText (L, R: Integer);
    procedure   WriteBuf (aText: PAnsiChar; aTextLen: Cardinal);
    procedure   SetScrollbars;
    procedure   SetCols (N: Integer);
    procedure   SetRows (N: Integer);
    procedure   SetFont (F: TFont);
    function    GetVPalette (Ind: Integer): Cardinal;
    procedure   SetVPalette (Ind: Integer; const TheValue: Cardinal);
    function    GetHPalette (Ind: Integer): Cardinal;
    procedure   SetHPalette (Ind: Integer; const TheValue: Cardinal);
    function    GetTextColorIndex: Integer;
    procedure   SetTextColorIndex (const TheValue: Integer);
    procedure   DoScroll (Which, Action, Thumb: Integer);
    procedure   SetVertScrollPos;
    function    GetActive: Boolean;
    procedure   SetActive (const Value: Boolean);
    function    GetFileName: AnsiString;
    procedure   SetFileName (const Value: AnsiString);
    function    GetVirtualMemory: Boolean;
    procedure   SetVirtualMemory (const Value: Boolean);
    procedure   ModifySelection (X, Y: Integer);
    function    IsPosInSelection (X, Y: Integer): Boolean;
    procedure   SetShowDOS (const Value: Boolean);
    procedure   HandleHint;
    procedure   DestroyHint;
    procedure   InitColors;
    function    GetCursorX: Integer;
    function    GetCursorY: Integer;
    procedure   UpdateCaretPos;
    procedure   ApplicationDeactivate (Sender: TObject);
    procedure   InvalidateLine (Y: Integer);
    function    GetCaretX: Integer;
    procedure   SetCaretX (const Value: Integer);
    function    GetCaretY: Integer;
    procedure   SetCaretY (const Value: Integer);
    procedure   SetGutterImages (Value: TCustomImageList);

    procedure   wmCreate       (var Msg: TMessage);       message WM_Create;
    procedure   wmDestroy      (var Msg: TMessage);       message WM_Destroy;
    procedure   wmSize         (var Msg: TwmSize);        message WM_Size;
    procedure   wmHScroll      (var Msg: TwmHScroll);     message WM_HScroll;
    procedure   wmVScroll      (var Msg: TwmVScroll);     message WM_VScroll;
    procedure   wmSetFocus     (var Msg: TwmSetFocus);    message WM_SetFocus;
    procedure   wmKillFocus    (var Msg: TwmKillFocus);   message WM_KillFocus;
    procedure   wmGetDlgCode   (var Msg: TwmGetDlgCode);  message WM_GetDlgCode;
    procedure   wmEraseBkgnd   (var Msg: TwmEraseBkgnd);  message WM_EraseBkgnd;
    procedure   wmTimer        (var Msg: TMessage);       message WM_timer;
    procedure   wmChar         (var Msg: TMessage);       message wm_char;

  protected

    procedure   SetParent (AParent: TWinControl); override;
    procedure   CreateParams (var Params: TCreateParams); override;
    procedure   SetName (const NewName: TComponentName); override;
    procedure   Paint; override;
    procedure   KeyPress (var Key: AnsiChar); override;
    procedure   MouseDown (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure   MouseUp   (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure   MouseMove (Shift: TShiftState; X, Y: Integer); override;
    function    DoMouseWheel (Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure   Loaded; override;
    procedure   VisibleChanging; override;
    procedure   Notification (AComponent: TComponent; Operation: TOperation); override;

  public

    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   WriteChar (Ch: AnsiChar);
    procedure   WriteFill (X, Y: Integer; Ch: AnsiChar; Count: Cardinal);
    procedure   WriteString (const S: AnsiString);
    procedure   ClrEol;
    procedure   CursorTo (X, Y: Integer);
    procedure   ScrollTo (X, Y: Integer);
    procedure   TrackCursor;
    procedure   ShowCaret;
    procedure   HideCaret;
    procedure   ClrScr;
    function    SelectedText: AnsiString;
    function    IsSelectionContinued: Boolean;
    procedure   Unselect;
    function    ScreenPtrT (X, Y: Integer): PAnsiChar;
    function    ScreenPtrC (X, Y: Integer): PAnsiChar;
    function    ScreenPtrH (Y: Integer): PLineHeader;
    property    TextColor: Integer read GetTextColorIndex write SetTextColorIndex;
    property    VPalette [I: Integer]: Cardinal read GetVPalette write SetVPalette;
    property    HPalette [I: Integer]: Cardinal read GetHPalette write SetHPalette;
    property    CursorX: Integer read GetCursorX;
    property    CursorY: Integer read GetCursorY;
    property    CaretX: Integer read GetCaretX write SetCaretX;
    property    CaretY: Integer read GetCaretY write SetCaretY;
    property    ClientSize: TPoint read FClientSize;
    property    Selection: TRect read FSelection;
    procedure   SetGutterImageIndex (aIndex: Integer; aLine: Integer = -1);
    procedure   KeyDown (var Key: Word; Shift: TShiftState); override;

    procedure   ScrollPageUp;
    procedure   ScrollPageDown;
    procedure   ScrollLineUp;
    procedure   ScrollLineDown;
    procedure   ScrollTop;
    procedure   ScrollBottom;

    function    LastAbsNo: Cardinal;

    procedure   CopyToClipboard;

  published

    property    OnHint: TOnHint read FOnHint write FOnHint default nil;
    property    OnGutterClick: TOnGutterClick read FOnGutterClick write FOnGutterClick default nil;

    property    Align;
    property    ParentColor;
    property    Color;
    property    Font: TFont read FFont write SetFont;
    property    Cols: Integer read FCols write SetCols default 80;
    property    Rows: Integer read FRows write SetRows default 25;
    property    LineBreak: TConsoleLineBreak read FLineBreak write FLineBreak;
    property    Active: Boolean read GetActive write SetActive;
    property    FileName: AnsiString read GetFileName write SetFileName;
    property    VirtualMemory: Boolean read GetVirtualMemory write SetVirtualMemory;
    property    PopupMenu;
    property    ShowDOS: Boolean read FShowDOS write SetShowDOS;
    property    ShowHint;
    property    GutterWidth: Integer read FGutterWidth;
    property    GutterColor: TColor read FGutterColor;
    property    GutterLineColor: TColor read FGutterLineColor;
    property    GutterImages: TCustomImageList read FGutterImages write SetGutterImages;
    property    TabStop;
    property    TabOrder;
    property    OnEnter;
    property    OnContextPopup;

  end;


procedure Register;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  FormatVersion = $00000005;
  FileHeaderSignature = 'PaxonConsole. Copyright 2016 by Ulf Haueisen (ulf@paxon.app)'#13#10#26;


var
  ConvertTable: Array[#0..#255] of AnsiChar;


procedure   InitConvertTable;
var
  C: AnsiChar;
  S, T: AnsiString;
  I: Integer;
begin
  for C := #0 to #255 do ConvertTable[C] := C;
  S := 'ƒ÷‹‰ˆ¸ﬂ¥';
  SetLength (T, Length (S));
  CharToOem (PAnsiChar(S), PAnsiChar(T));
  for I := 1 to Length (S) do begin
    ConvertTable[T[I]] := S[I];
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    GetLastErrorText (F: DWord): AnsiString; overload;
var
  S: Array[0..250] of AnsiChar;
begin
  if FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_MAX_WIDTH_MASK, nil, F, 0, S, 100, nil) = 0 then begin
    StrPCopy (S, 'Nr. ' + IntToStr (F));
  end;
  result := AnsiString (S);
end;


function    GetLastErrorText: AnsiString; overload;
begin
  result := GetLastErrorText (GetLastError);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// Scroll key definition record
type
  TScrollKey = packed record
    sKey: Byte;
    Ctrl: Boolean;
    SBar: Byte;
    Action: Byte;
  end;


function    Min (X, Y: Integer): Integer;
begin
  if X < Y then result := X else result := Y;
end;


function    Max (X, Y: Integer): Integer;
begin
  if X > Y then result := X else result := Y;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TConsole.Create (AOwner: TComponent);
begin

  inherited Create (AOwner);

  ApplicationEvents := TApplicationEvents.create (self);

  ApplicationEvents.OnDeactivate := ApplicationDeactivate;

  Width := 209;
  Height := 129;
  ControlStyle := ControlStyle + [csClickEvents, csDoubleClicks, csReflector, csOpaque] - [csCaptureMouse];
  FRows := 25;
  FCols := 80;

  FSelection := Rect (-1, -1, -1, -1);

  ParentColor := false;
  Color := clWindow;

  FFileName := '';
  FActive := false;

  FFont := TFont.Create;
  FFont.Name := 'Fixedsys';
  FFont.OnChange := DoFontChanged;

  FBuffer := nil;
  FTextBuffer := nil;
  FFileHeader := nil;
  FStream := nil;

  FOrigin := Point (-1, -1);

  FScrollState := ssBottom;

  FHintWindow := nil;
  Hint := '';

  FGutterWidth := 14;

  InitColors;

  Enabled := True;

end;

destructor  TConsole.Destroy;
begin

  ApplicationEvents.Free;

  FCols := 0;
  FRows := 0;
  FActive := false;

  ResizeBuffer; // free memory

  DestroyHint;

  FFont.Free;

  inherited;

end;


procedure   TConsole.InitColors;
var
  C1, C2: TColor;
  DC: HDC;
  I: Integer;
  HighColor: Boolean;

begin

  DC := GetDC (0);
  try
    I := GetDeviceCaps (DC, BITSPIXEL);
    HighColor := (I >= 16);
  finally
    ReleaseDC (0, DC);
  end;

  VPalette[00] := RGB ($7F, $00, $00);
  VPalette[01] := RGB ($9F, $00, $00);
  VPalette[02] := RGB ($BF, $00, $00);
  VPalette[03] := RGB ($DF, $00, $00);
  VPalette[04] := RGB ($FF, $00, $00);
  VPalette[05] := RGB ($00, $7F, $00);
  VPalette[06] := RGB ($00, $9F, $00);
  VPalette[07] := RGB ($00, $BF, $00);
  VPalette[08] := RGB ($00, $6F, $6F);
  VPalette[09] := RGB ($5F, $5F, $5F);
  VPalette[10] := RGB ($00, $00, $7F);
  VPalette[11] := RGB ($00, $00, $9F);
  VPalette[12] := RGB ($00, $00, $BF);
  VPalette[13] := RGB ($00, $00, $DF);
  VPalette[14] := RGB ($00, $00, $FF);
  VPalette[15] := RGB ($00, $00, $00);

  if (HighColor) then begin

    C1 := ColorToRGB (clBtnShadow);
    C2 := ColorToRGB (clBtnFace);
    FGutterLineColor := RGB (Trunc (GetRValue (C1) * 0.6 + GetRValue (C2) * 0.4),
                             Trunc (GetGValue (C1) * 0.6 + GetGValue (C2) * 0.4),
                             Trunc (GetBValue (C1) * 0.6 + GetBValue (C2) * 0.4));

    C1 := ColorToRGB (clBtnHighlight);
    C2 := ColorToRGB (clBtnFace);
    FGutterColor := RGB (Trunc (GetRValue (C1) * 0.8 + GetRValue (C2) * 0.2),
                         Trunc (GetGValue (C1) * 0.8 + GetGValue (C2) * 0.2),
                         Trunc (GetBValue (C1) * 0.8 + GetBValue (C2) * 0.2));

    C1 := ColorToRGB (clBtnHighlight);
    C2 := ColorToRGB (clBtnFace);
    FListbackgroundColor := RGB (Trunc (GetRValue (C1) * 0.4 + GetRValue (C2) * 0.6),
                                 Trunc (GetGValue (C1) * 0.4 + GetGValue (C2) * 0.6),
                                 Trunc (GetBValue (C1) * 0.4 + GetBValue (C2) * 0.6));

  end else begin

    FGutterLineColor := cl3DDkShadow;
    FGutterColor := cl3DLight;
    FListbackgroundColor := RGB ($D8, $D8, $D8);

  end;

end;


procedure   TConsole.CreateParams (var Params: TCreateParams);
begin
  inherited CreateParams (Params);
  with Params do begin
    Style := Style and (not (cs_HRedraw or cs_VRedraw or ws_Border));
    // ExStyle := ExStyle or WS_EX_CLIENTEDGE;
  end;
end;


procedure   TConsole.wmCreate (var Msg: TMessage);
begin
  inherited;
  RecalibrateFont;
end;


procedure   TConsole.wmDestroy (var Msg: TMessage);
begin
  KillTimer (Handle, 1);
  KillTimer (Handle, 2);
  KillTimer (Handle, 3);
  inherited;
end;


procedure   TConsole.ResizeBuffer;
const
  MethodName = 'ResizeBuffer';

var
  BufferSize: Cardinal;
  FileHeaderSize: Cardinal;
  ClearMemory: Boolean;
  H: THandle;
  N: Cardinal;

begin

  FileHeaderSize := Sizeof (TFileHeader);

  if (assigned (FBuffer)) then begin
    if (FMappingHandle <> 0) then begin
      UnmapViewOfFile (FBuffer);
    end else begin
      FreeMem (FBuffer);
    end;
    FBuffer := nil;
  end;

  FTextBuffer := nil;
  FFileHeader := nil;

  if (FMappingHandle <> 0) then begin
    CloseHandle (FMappingHandle);
    FMappingHandle := 0;
  end;

  if (assigned (FStream)) then begin
    FStream.free;
    FStream := nil;
  end;

  ClearMemory := true;

  BufferSize := (FCols + ExtraBytesPerLine) * FRows * 2;

  if (BufferSize > 0) then begin

    if (FVirtualMemory) then begin

      if (Length (FFileName) > 0) then begin

        if (FileExists (FFileName)) then begin
          FStream := TFileStream.create (FFileName, fmOpenReadWrite or fmShareExclusive);
          New (FFileHeader);
          N := FStream.Read (FFileHeader^, FileHeaderSize);
          if (N = FileHeaderSize) and (FFileHeader^.FormatVersion in [4..FormatVersion]) then begin
            if (FFileHeader.Rows = 0) then FFileHeader.Rows := 1250; // for compatibility only
            // A damaged or foreign file must not lead outside the buffer: the size
            // must match the layout, FirstLine must be a buffer line, Cols (0 in
            // older files) must match.
            if (FFileHeader.Rows = FRows) and (FStream.Size = FileHeaderSize + BufferSize) and
               (FFileHeader.FirstLine >= 0) and (FFileHeader.FirstLine < FRows) and
               ((FFileHeader.Cols = 0) or (FFileHeader.Cols = FCols)) then begin
              ClearMemory := false;
            end else begin
              FStream.Free;
              FStream := nil;
            end;
          end;
          Dispose (FFileHeader);
        end else begin
          FStream := nil;
        end;

        if (not assigned (FStream)) then begin
          FStream := TFileStream.create (FFileName, fmCreate or fmShareExclusive);
        end;

        H := FStream.Handle;

      end else begin

        FStream := nil;
        H := $FFFFFFFF;

      end;

      FMappingHandle := CreateFileMapping (H, nil, PAGE_READWRITE, 0, FileHeaderSize + BufferSize, nil);

      if (FMappingHandle = 0) then begin
        raise EConsole.create ('CreateFileMapping Error:' + GetLastErrorText);
      end;

      FBuffer := MapViewOfFile (FMappingHandle, FILE_MAP_ALL_ACCESS, 0, 0, FileHeaderSize + BufferSize);

      if (not assigned (FBuffer)) then begin
        raise EConsole.create ('MapViewOfFile Error:' + GetLastErrorText);
      end;

    end else begin

      FStream := nil;
      FMappingHandle := 0;
      GetMem (FBuffer, FileHeaderSize + BufferSize);

      if (not assigned (FBuffer)) then begin
        raise EConsole.create ('GetMem Error:' + GetLastErrorText);
      end;

    end;

    FFileHeader := Pointer(FBuffer);

    FFileHeader.FormatVersion := FormatVersion;
    FFileHeader.Cols := FCols;

    if (ClearMemory) then begin
      ClrScr;
    end;

    FTextBuffer := Pointer(FBuffer);
    Inc (FTextBuffer, FileHeaderSize);

    CursorTo (FFileHeader.Cursor.X, FFileHeader.Cursor.Y);

  end;

  Repaint;

end;


procedure   TConsole.SetCols (N: Integer);
begin
  assert ((csLoading in ComponentState) or (not FActive));
  if (FCols <> N) then begin
    FCols := N;
  end;
end;


procedure   TConsole.SetRows (N: Integer);
var
  B: Boolean;
begin
  if (FRows <> N) then begin
    B := Active;
    Active := false;
    FRows := N;
    Active := B;
  end;
end;


procedure   TConsole.SetFont (F: TFont);
begin
  FFont.Assign (F);
end;


procedure   TConsole.DoFontChanged (Sender: TObject);
const
  MethodName = 'DoFontChanged';

var
  DC: HDC;
  Save: THandle;
  Metrics: TTextMetric;

begin

  DC := CreateDC (PAnsiChar('DISPLAY'), nil, nil, nil);
  Save := SelectObject (DC, FFont.Handle);
  GetTextMetrics (DC, Metrics);
  SelectObject (DC, Save);
  DeleteDC (DC);

  with Metrics do begin
    FCharSize.X := tmAveCharWidth;
    FCharSize.Y := tmHeight + tmExternalLeading;
    FCharAscent := tmAscent;
    FOverhang   := Max (tmOverhang, tmMaxCharWidth - tmAveCharWidth);
  end;

  // FGutterWidth := Trunc (FCharSize.X * 1.5) + 2;

  InvalidateRect (Handle, nil, false);
  RecalcSizeAndRange;

end;


procedure   TConsole.SetParent (AParent: TWinControl);
begin
  inherited;
  RecalcSizeAndRange;
end;


procedure   TConsole.RecalcSizeAndRange;
var
  Y: Integer;
begin

  if (assigned (Parent)) then begin

    HandleNeeded;

    FClientSize.X := ClientWidth  div FCharSize.X;
    FClientSize.Y := ClientHeight div FCharSize.Y;

    FRange.X := FCols - FClientSize.X;
    if (FRange.X < 0) then FRange.X := 0;

    FRange.Y := FRows - FClientSize.Y;
    if (FRange.Y < 0) then FRange.Y := 0;

    if (FOrigin.Y < FRange.Y) then Y := FOrigin.Y else Y := FRange.Y;
    ScrollTo (0, Y);

    SetScrollBars;

  end;

  TrackCursor;

end;


procedure   TConsole.SetName (const NewName: TComponentName);
begin
  inherited;
end;


function    TConsole.ScreenPtrT (X, Y: Integer): PAnsiChar;
begin
  assert (FActive);
  Inc (Y, FFileHeader.FirstLine);
  if (Y >= FRows) then Dec (Y, FRows);
  Result := @FTextBuffer[Y * (FCols * 2 + ExtraBytesPerLine) + ExtraBytesPerLine + X];
end;


function    TConsole.ScreenPtrC (X, Y: Integer): PAnsiChar;
begin
  assert (FActive);
  Inc (Y, FFileHeader.FirstLine);
  if (Y >= FRows) then Dec (Y, FRows);
  Result := @FTextBuffer[Y * (FCols * 2 + ExtraBytesPerLine) + ExtraBytesPerLine + X + FCols];
end;


function    TConsole.ScreenPtrH (Y: Integer): PLineHeader;
begin
  assert (FActive);
  Inc (Y, FFileHeader.FirstLine);
  if (Y >= FRows) then Dec (Y, FRows);
  if (Y < 0) then begin
    Result := nil;
  end else begin
    Result := @FTextBuffer[Y * (FCols * 2 + ExtraBytesPerLine)];
  end;
end;


// Update text on cursor line
procedure   TConsole.ShowText (L, R: Integer);
const
  MethodName = 'ShowText';
var
  B: TRect;
begin
  if (HandleAllocated) and (L < R) then begin
    B.Left := (FGutterWidth) + ((L - FOrigin.X) * FCharSize.X);
    B.Top  := (FFileHeader.Cursor.Y - FOrigin.Y) * FCharSize.Y;
    B.Right := (FGutterWidth) + ((R - FOrigin.X + 1) * FCharSize.X) + FOverhang + FCharSize.X;
    B.Bottom := B.Top + FCharSize.Y;
    InvalidateRect (Handle, @B, false);
  end
end;


procedure   TConsole.InvalidateLine (Y: Integer);
var
  B: TRect;
begin
  if (Y >= 0) and (HandleAllocated) then begin
    B.Left := (FGutterWidth);
    B.Top  := (Y - FOrigin.Y) * FCharSize.Y;
    B.Right := Width;
    B.Bottom := B.Top + FCharSize.Y;
    InvalidateRect (Handle, @B, false);
  end
end;


procedure   TConsole.ShowCaret;
begin
  if (HandleAllocated) and (FFocused) then begin
    UpdateCaretPos;
    Windows.ShowCaret (Handle);
  end;
end;


procedure   TConsole.HideCaret;
begin
  Windows.HideCaret (Handle);
end;


procedure   TConsole.UpdateCaretPos;
begin
  if (FFocused) then SetCaretPos ((FCaret.X - FOrigin.X) * FCharSize.X + FGutterWidth, (FCaret.Y - FOrigin.Y) * FCharSize.Y);
end;


procedure   TConsole.CursorTo (X, Y: Integer);
const
  MethodName = 'CursorTo';
var
  R: TRect;

begin

  if (HandleAllocated) then begin

    R.Left := (FGutterWidth) + (FFileHeader.Cursor.X - FOrigin.X) * FCharSize.X;
    R.Top  := (FFileHeader.Cursor.Y - FOrigin.Y) * FCharSize.Y;
    R.Right := R.Left + FCharSize.X;
    R.Bottom := R.Top + FCharSize.Y;

    if (X < 0) then X := 0 else if (X > FCols - 1) then X := FCols - 1;
    if (Y < 0) then Y := 0 else if (Y > FRows - 1) then Y := FRows - 1;
    FFileHeader.Cursor.X := X;
    FFileHeader.Cursor.Y := Y;

    InvalidateRect (Handle, @R, false);

  end;

end;


// Scroll window to given origin
// If font has overlapping cells (ie, italic), additional work is done to
// remove the residual overlapped pixels from the leftmost column.
// Using the clip rect with ScrollWindowEx helps eliminate pixel flicker in
// the left column.
procedure   TConsole.ScrollTo (X, Y: Integer);
const
  MethodName = 'ScrollTo';
var
  R: TRect;
  OldOrigin: TPoint;

begin

  X := Max (0, Min (X, FRange.X));
  Y := Max (0, Min (Y, FRange.Y));

  if (X <> FOrigin.X) or (Y <> FOrigin.Y) then begin

    OldOrigin := FOrigin;
    FOrigin.X := X;
    FOrigin.Y := Y;
    if (HandleAllocated) then begin
      R := ClientRect;
      if X > OldOrigin.X then Inc (R.Left, FOverhang);
      if Y > OldOrigin.Y then R.Bottom := FClientSize.Y * FCharSize.Y;
      ScrollWindowEx (Handle, (OldOrigin.X - X) * FCharSize.X, (OldOrigin.Y - Y) * FCharSize.Y, nil, @R, 0, @R, 0);
      if (Y <> OldOrigin.Y) then begin
        SetVertScrollPos;
        if (Y > OldOrigin.Y) then begin
          InvalidateRect (Handle, @R, false);
          R.Top := R.Bottom;
          R.Bottom := ClientRect.Bottom;
        end;
      end;

      if (X <> OldOrigin.X) then begin
        SetScrollPos (Handle, sb_Horz, X, True);
        if (FOverhang > 0) then begin
          if (X < OldOrigin.X) then begin
            // Scroll right - left edge repaint
            // Add overhang to invalidation rect to redraw leftmost char pair
            R.Left := 0;
            R.Right := Max (R.Right, (OldOrigin.X - X) * FCharSize.X + FOverhang);
          end else begin
            // Scroll left - right edge repaint
            // Redraw leftmost chars to remove prev chars' overhang
            InvalidateRect (Handle, @R, false);
            R.Left := 0;
            R.Top  := 0;
            R.Right := FOverhang;
            R.Bottom := ClientHeight;
          end;
        end;
      end;

      InvalidateRect (Handle, @R, false);
      UpdateCaretPos;
      UpdateWindow (Handle);

    end;
  end;

end;


procedure   TConsole.SetVertScrollPos;
var
  B: TScrollState;

begin

  SetScrollPos (Handle, sb_Vert, FOrigin.Y, True);

  if (FOrigin.Y <= 0) then begin
    B := ssTop;
  end else if (FFileHeader.Cursor.Y <= (FClientSize.Y + FOrigin.Y - 1)) then begin
    B := ssBottom;
  end else begin
    B := ssMiddle;
  end;

  if (B <> FScrollState) then begin

    FScrollState := B;

  end;

end;


// Scroll to make cursor visible (synchronous - immediate update)
procedure   TConsole.TrackCursor;
begin
  if (FActive) and (FScrollState = ssBottom) then begin
    ScrollTo ({Max (FFileHeader.Cursor.X - FClientSize.X + 1, Min (FOrigin.X, FFileHeader.Cursor.X))} 0,
              Max (FFileHeader.Cursor.Y - FClientSize.Y + 1, Min (FOrigin.Y, FFileHeader.Cursor.Y)));
  end;
end;


// Update scroll bars
procedure   TConsole.SetScrollBars;
var
  ScrollInfo: TScrollInfo;

begin

  if (HandleAllocated) then begin
    {
    with ScrollInfo do begin
      cbSize    := sizeof (ScrollInfo);
      fMask     := sif_all;
      nMin      := 0;
      nMax      := FCols - 1;
      nPage     := FClientSize.X;
      nPos      := FOrigin.X;
      nTrackPos := 0;
    end;
    SetScrollInfo (Handle, SB_HORZ, ScrollInfo, True);
    }

    with ScrollInfo do begin
      cbSize    := sizeof (ScrollInfo);
      fMask     := sif_all;
      nMin      := 0;
      nMax      := FRows - 1;
      nPage     := FClientSize.Y;
      nPos      := FOrigin.Y;
      nTrackPos := 0;
    end;
    SetScrollInfo (Handle, SB_VERT, ScrollInfo, True);

  end;

end;


procedure   TConsole.ClrScr;
const
  MethodName = 'ClrScr';

var
  I: Integer;
  P: PAnsiChar;

begin

  if (FActive) then begin

    P := FBuffer;
    FillChar (P^, Sizeof (TFileHeader), $00);
    inc (P, Sizeof (TFileHeader));

    for I := 0 to FRows - 1 do begin
      FillChar (P^, ExtraBytesPerLine, $00);
      inc (P, ExtraBytesPerLine);
      FillChar (P^, FCols, $20);
      inc (P, FCols);
      FillChar (P^, FCols, $FF);
      inc (P, FCols);
    end;

    StrCopy (FFileHeader.Signature, FileHeaderSignature);
    FFileHeader.FormatVersion := FormatVersion;
    FFileHeader.Cursor.Y := FRows - 1;
    FFileHeader.Rows := FRows;

    CursorTo (FFileHeader.Cursor.X, FFileHeader.Cursor.Y);

    FCaret.X := 0;
    FCaret.Y := -1;

    InvalidateRect (Handle, nil, false);

  end;

end;


procedure   TConsole.RecalibrateFont;
begin
  FCharSize.X := 0;
  FCharSize.Y := 0;
  FCharAscent := 0;
  FOverhang := 0;
  DoFontChanged (FFont);
end;


function    TConsole.IsSelectionContinued: Boolean;
begin
  result := (FSelection.Bottom >= FRows);
end;


procedure   TConsole.ClrEol;
begin
  WriteFill (FFileHeader.Cursor.X, FFileHeader.Cursor.Y, ' ', FCols - FFileHeader.Cursor.X);
  ShowText (FFileHeader.Cursor.X, FCols);
end;


procedure   TConsole.WriteBuf (aText: PAnsiChar; aTextLen: Cardinal);
var
  L, R: Integer;
  CY: Integer;
  ScrollY: Integer;

  procedure Return;
  begin
    L := 0;
    R := 0;
    CursorTo (0, FFileHeader.Cursor.Y);
  end;

  procedure LineFeed;
  var
    LineHeader: PLineHeader;

  begin

    LineHeader := ScreenPtrH (FFileHeader.Cursor.Y);
    LineHeader.EOLColor := FTextColor;

    CursorTo (FFileHeader.Cursor.X, FFileHeader.Cursor.Y);

    Inc (FFileHeader.Cursor.Y);

    if (FFileHeader.Cursor.Y >= FRows) then begin

      Dec (FFileHeader.Cursor.Y);

      Dec (FCaret.Y);
      if (FCaret.Y < 0) then FCaret.Y := 0;

      Dec (CY);

      if (FSelection.Top <> -1) then begin
        Dec (FSelection.Top);
        if (FSelection.Top < 0) then begin
          FSelection.Top := 0;
          FSelection.Left := 0;
        end;
        if (FSelection.Bottom < FRows) then begin
          Dec (FSelection.Bottom);
          if (FSelection.Bottom < 0) then begin
            FSelection.Top := -1;
            FSelection.Bottom := -1;
            FSelection.Left := -1;
            FSelection.Right := -1;
          end;
        end;
      end;

      with FSelectionAnchor do begin
        if (Y <> -1) then begin
          Dec (Y);
          if (Y < 0) then begin
            Y := 0;
            X := 0;
          end;
        end;
      end;

      Inc (FFileHeader.FirstLine);
      if (FFileHeader.FirstLine >= FRows) then FFileHeader.FirstLine := 0;
      WriteFill (0, FFileHeader.Cursor.Y, ' ', FCols);

      LineHeader := ScreenPtrH (FFileHeader.Cursor.Y);

      FillChar (LineHeader^, ExtraBytesPerLine, 0);

      Inc (FFileHeader.LastAbsNo);
      LineHeader.AbsNo := FFileHeader.LastAbsNo;

      Inc (ScrollY);

    end;

  end;

var
  I, BlockEnd, BlockLen, BlockStart: Integer;
  P: PAnsiChar;
  TS: TTimeStamp;
  UT: Cardinal;
  LineHeader: PLineHeader;


begin

  assert (FActive);
  assert (MainThreadID = GetCurrentThreadID);

  if (not assigned (aText)) then exit;

  ScrollY := 0;

  CY := FFileHeader.Cursor.Y;

  L := FFileHeader.Cursor.X;
  R := FFileHeader.Cursor.X;

  while (aTextLen > 0) do begin

    BlockEnd := Min (FCols - FFileHeader.Cursor.X, aTextLen);
    P := aText;
    BlockStart := BlockEnd;
    while (BlockEnd > 0) and (not (aText^ in [#10, #13])) do begin
      Inc (aText);
      Dec (BlockEnd);
    end;
    BlockLen := BlockStart - BlockEnd;

    LineHeader := ScreenPtrH (FFileHeader.Cursor.Y);
    LineHeader.Length := FFileHeader.Cursor.X + BlockLen;

    if (BlockLen > 0) then begin

      Dec (aTextLen, BlockLen);

      Move (P^, ScreenPtrT (FFileHeader.Cursor.X, FFileHeader.Cursor.Y)^, BlockLen);
      FillChar (ScreenPtrC (FFileHeader.Cursor.X, FFileHeader.Cursor.Y)^, BlockLen, FTextColor);

      Inc (FFileHeader.Cursor.X, BlockLen);
      if (FFileHeader.Cursor.X > R) then R := FFileHeader.Cursor.X;

      if (BlockEnd = 0) and (FFileHeader.Cursor.X >= FCols) then begin
        ShowText (L, R);
        Return;
        LineFeed;
        Continue;
      end;

    end;

    if (aTextLen > 0) then begin

      case aText^ of
        #13: begin
          if (FLineBreak <> LF) then begin
            ShowText (L, R);
            Return;
            if (FLineBreak = CR) then LineFeed;
          end;
        end;
        #10: begin
          if (FLineBreak <> CR) then begin
            ShowText (L, R);
            if (FLineBreak = LF) then Return;
            LineFeed;
          end;
        end;
      end;
      Inc (aText);
      Dec (aTextLen);
    end;

  end;

  if (ScrollY > 0) then begin

    Dec (FOrigin.Y, ScrollY);

    if (FScrollState = ssMiddle) then begin
      if (FOrigin.Y < 0) then begin
        // the displayed text has scrolled out of the circular buffer
        FOrigin.Y := 0;
        if (HandleAllocated) then InvalidateRect (Handle, nil, false);
      end;
      SetVertScrollPos;
    end else begin
      ScrollTo (0, FOrigin.Y + ScrollY);
    end;

  end;

  TS := DateTimeToTimeStamp (Now);
  UT := ((TS.Date - 719163) * (24 * 60 * 60)) + (TS.Time div 1000);

  // If there are more new lines than fit into the circular buffer, CY is negative;
  // these lines have already scrolled out of the buffer again.
  if (CY < 0) then CY := 0;

  for I := CY to FFileHeader.Cursor.Y do begin
    ScreenPtrH (I).Time := UT;
  end;

  ShowText (L, R);

  TrackCursor;

  if (FFocused) then ShowCaret;

end;


procedure   TConsole.WriteChar (Ch: AnsiChar);
begin
  WriteBuf (@Ch, 1);
end;


procedure   TConsole.WriteString (const S: AnsiString);
begin
  WriteBuf (PAnsiChar(S), Length (S));
end;


procedure   TConsole.WriteFill (X, Y: Integer; Ch: AnsiChar; Count: Cardinal);
var
  I: Integer;

begin

  assert (FActive);

  if (Count > 0) then begin
    if (X + Integer(Count)) > Integer(FCols) then begin
      FillChar (ScreenPtrT (X, Y)^, FCols - X, Ch);
      FillChar (ScreenPtrC (X, Y)^, FCols - X, 0);
      Dec (Count, FCols - X);
      I := FCols;
      while (Count > 0) do begin
        Inc (Y);
        FillChar (ScreenPtrT (X, Y)^, I, Ch);
        FillChar (ScreenPtrC (X, Y)^, I, 0);
        Dec (Count, I);
      end;
    end else begin
      FillChar (ScreenPtrT (X, Y)^, Count, Ch);
      FillChar (ScreenPtrC (X, Y)^, Count, 0);
    end;
  end;

end;


procedure   TConsole.Paint;
const
  MethodName = 'Paint';

var
  M, I, N, X1, X2, X, Y1, Y2, Y, PY, K, Z: Integer;
  R, TR: TRect;
  T: THandle;
  DX, DY: Integer;
  InSelection: Boolean;
  InSelectionChanged: Boolean;
  InList: Boolean;

  ColorF: TColor;
  ColorB: TColor;
  ColorLineB: TColor;

  ColorListB: TColor;
  ColorDefB: TColor;
  ColorSelB: TColor;
  ColorSelF: TColor;

  AnsiBuff: PAnsiChar;
  P: PAnsiChar;
  LineHeader: PLineHeader;

  PtrC, PtrT: PAnsiChar;
  CanvasHandle: THandle;

begin

  if (FActive) then begin

    CanvasHandle := Canvas.Handle;

    ColorListB := FListbackgroundColor;
    ColorDefB := ColorToRGB (Color);
    ColorSelB := ColorToRGB (clHighlight);
    ColorSelF := ColorToRGB (clHighlightText);

    GetMem (AnsiBuff, FCols + 1);

    DX := FOrigin.X * FCharSize.X - FGutterWidth;
    DY := FOrigin.Y * FCharSize.Y;

    GetClipBox (CanvasHandle, R);

    Canvas.Font.Assign (FFont);

    OffsetRect (R, DX, DY);

    X1 := (R.left - FOverhang) div FCharSize.X;
    if (FOrigin.X > X1) then X1 := FOrigin.X;

    X2 := (R.right + FCharSize.X) div FCharSize.X;
    if (X2 > FCols) then X2 := FCols;

    Y1 := R.top div FCharSize.Y;
    if (Y1 < 0) then Y1 := 0;

    Y2 := (R.bottom + FCharSize.Y - 1) div FCharSize.Y;
    if (Y2 > FRows) then Y2 := FRows;

    PY := Y1 * FCharSize.Y;

    Canvas.Brush.Color := ColorDefB;
    SetBkColor (CanvasHandle, ColorDefB);

    if ((FRows * FCharSize.Y) < R.Bottom) then begin

      Canvas.FillRect (Rect (R.Left - DX, FRows * FCharSize.Y - DY, R.Right - DX, R.Bottom - DY));

      if (R.Left < 0) then begin
        Canvas.Brush.Color := FGutterColor;
        Canvas.FillRect (Rect (0, FRows * FCharSize.Y - DY, FGutterWidth - 2, R.Bottom - DY));
        Canvas.Brush.Color := FGutterLineColor;
        Canvas.FillRect (Rect (FGutterWidth - 2, FRows * FCharSize.Y - DY, FGutterWidth - 1, R.Bottom - DY));
        Canvas.Brush.Color := ColorDefB;
        Canvas.FillRect (Rect (FGutterWidth - 1, FRows * FCharSize.Y - DY, FGutterWidth - 0, R.Bottom - DY));
      end;

    end;

    T := SelectObject (CanvasHandle, FFont.Handle);
    Y := Y1;
    if (FSelection.Top <> -1) then begin
      InSelection := (Y > FSelection.Top) and (Y < FSelection.Bottom);
      InSelectionChanged := InSelection;
    end else begin
      InSelection := false;
      InSelectionChanged := false;
    end;

    while (Y < Y2) do begin

      Z := Y + FFileHeader.FirstLine;
      if (Z >= FRows) then Dec (Z, FRows);
      LineHeader := @FTextBuffer[Z * (FCols * 2 + ExtraBytesPerLine)];
      PtrT := PAnsiChar(Cardinal(LineHeader) + ExtraBytesPerLine);
      PtrC := PAnsiChar(Cardinal(PtrT) + Cardinal(FCols));

      if (R.Left < 0) then begin
        Canvas.Brush.Color := FGutterColor;
        Canvas.FillRect (Rect (0, PY - DY, FGutterWidth - 1, PY - DY + FCharSize.Y));
        Canvas.Brush.Color := FGutterLineColor;
        Canvas.FillRect (Rect (FGutterWidth - 2, PY - DY, FGutterWidth - 1, PY - DY + FCharSize.Y));
        Canvas.Brush.Color := ColorDefB;
        Canvas.FillRect (Rect (FGutterWidth - 1, PY - DY, FGutterWidth - 0, PY - DY + FCharSize.Y));
        if (assigned (FGutterImages)) then begin
          if (LineHeader.ImageIndex > 0) then begin
            FGutterImages.Draw (Canvas, ((FGutterWidth - FGutterImages.Width) div 2 - 1),
                                ((FCharSize.Y - FGutterImages.Height) div 2) + PY - DY, LineHeader.ImageIndex);
          end;
        end;
      end;

      InList := (LineHeader.LineType = 1) and (FFocused) and
                (((FSelection.Top = -1) and (Y = FCaret.Y)) or ((Y >= FSelection.Top) and (Y <= FSelection.Bottom)));

      if (InList) then begin
        ColorLineB := ColorListB;
      end else begin
        ColorLineB := ColorDefB;
      end;

      N := Byte(PtrC[X1]);
      if (InSelection) then begin
        ColorF := ColorSelF;
        ColorB := ColorSelB;
      end else begin
        ColorF := VPalette[N and $0F];
        ColorB := ColorLineB;
      end;

      SetBKColor (CanvasHandle, ColorB);

      M := X1;

      for X := X1 to X2 do begin

        I := Byte(PtrC[X]);

        if (FSelection.Top <> -1) then begin
          if (InSelection) then begin
            if ((Y > FSelection.Bottom) or ((Y = FSelection.Bottom) and (X > FSelection.Right))) then begin
              InSelection := false;
              InSelectionChanged := true;
            end;
          end else begin
            if ((Y > FSelection.Top) or ((Y = FSelection.Top) and (X >= FSelection.Left))) and
               (not ((Y > FSelection.Bottom) or ((Y = FSelection.Bottom) and (X > FSelection.Right)))) then begin
              InSelection := true;
              InSelectionChanged := true;
            end;
          end;
        end;

        if (N <> I) or (X = X2) or (X = LineHeader.Length) or (InSelectionChanged) then begin

          SetTextColor (CanvasHandle, ColorF);
          N := I;
          if (not InSelection) then ColorF := VPalette[N and $0F];

          P := @PtrT[M];

          if (FShowDOS) then begin
            for K := 0 to X - M - 1 do AnsiBuff[K] := ConvertTable[P[K]];
            P := AnsiBuff;
          end;

          ExtTextOut (CanvasHandle, M * FCharSize.X - DX, PY - DY, 0, nil, P, X - M, nil);

          // Canvas.Pixels [M * FCharSize.X - DX, PY - DY] := clRed;

          M := X;

          if (X >= LineHeader.Length) then begin
            InSelectionChanged := false;
            break;
          end else begin
            if (InSelectionChanged) then begin
              if (InSelection) then begin
                SetBkColor (CanvasHandle, ColorSelB);
                ColorF := ColorSelF;
              end else begin
                SetBkColor (CanvasHandle, ColorLineB);
              end;
              InSelectionChanged := false;
            end;
          end;

        end;

      end;

      SetBkColor (CanvasHandle, ColorLineB);
      TR.Left := LineHeader.Length * FCharSize.X - DX;
      TR.Top := PY - DY;
      TR.Right := Width;
      TR.Bottom := TR.Top + FCharSize.Y;
      ExtTextOut (CanvasHandle, TR.Left, TR.Top, eto_opaque, @TR, nil, 0, nil);

      Inc (Y);
      Inc (PY, FCharSize.Y);

    end;

    SelectObject (CanvasHandle, T);

    if (Y1 <= FFileHeader.Cursor.Y) and (FFileHeader.Cursor.Y <= Y2) then begin
      Canvas.Brush.Color := clGray;
      Canvas.FillRect (Rect (FFileHeader.Cursor.X * FCharSize.X + 1 - DX,
                            (FFileHeader.Cursor.Y + 1) * FCharSize.Y - 4 - DY,
                            (FFileHeader.Cursor.X + 1) * FCharSize.X - DX,
                            (FFileHeader.Cursor.Y + 1) * FCharSize.Y - 2 - DY));
    end;

    FreeMem (AnsiBuff, FCols + 1);

  end else begin

    Canvas.Brush.Color := clAppWorkSpace;
    Canvas.FillRect (Rect (0, 0, ClientWidth, ClientHeight));

  end;

end;


procedure   TConsole.wmSize (var Msg: TwmSize);
begin
  if (FFocused) then HideCaret;
  inherited;
  RecalcSizeAndRange;
  if (FFocused) then ShowCaret;
end;


procedure   TConsole.DoScroll (Which, Action, Thumb: Integer);
var
  X, Y: Integer;

  function GetNewPos (Pos, Page, Range: Integer): Integer;
  begin
    case Action of
      sb_LineUp: GetNewPos := Pos - 1;
      sb_LineDown: GetNewPos := Pos + 1;
      sb_PageUp: GetNewPos := Pos - Page;
      sb_PageDown: GetNewPos := Pos + Page;
      sb_Top: GetNewPos := 0;
      sb_Bottom: GetNewPos := Range;
      sb_ThumbPosition, sb_ThumbTrack: GetNewPos := Thumb;
    else
      GetNewPos := Pos;
    end;
  end;

begin
  DestroyHint;
  X := FOrigin.X;
  Y := FOrigin.Y;
  case Which of
    sb_Horz: X := GetNewPos (X, FClientSize.X div 2, FRange.X);
    sb_Vert: Y := GetNewPos (Y, FClientSize.Y - 1, FRange.Y);
  end;
  ScrollTo (X, Y);
end;


procedure   TConsole.wmHScroll (var Msg: TwmHScroll);
begin
  DoScroll (sb_Horz, Msg.ScrollCode, Msg.Pos);
end;


procedure   TConsole.wmVScroll (var Msg: TwmVScroll);
begin
  DoScroll (sb_Vert, Msg.ScrollCode, Msg.Pos);
end;


procedure   TConsole.KeyPress (var Key: AnsiChar);
begin
  inherited KeyPress (Key);
end;


procedure   TConsole.KeyDown (var Key: Word; Shift: TShiftState);
const
  MethodName = 'KeyDown';

var
  CursorKey: Boolean;
  LineHeader: PLineHeader;
  I: Integer;
  R: TRect;

begin

  CursorKey := false;

  case Key of

    vk_left: begin
      if (FCaret.X > 0) then dec (FCaret.X);
      UpdateCaretPos;
      CursorKey := true;
    end;

    vk_right: begin
      if (FCaret.X < FCols) then inc (FCaret.X);
      UpdateCaretPos;
      CursorKey := true;
    end;

    vk_up: begin
      InvalidateLine (FCaret.Y);
      if (FCaret.Y > 0) then dec (FCaret.Y);
      if (FCaret.Y < FOrigin.Y) then begin
        ScrollTo (FOrigin.X, FCaret.Y);
      end;
      LineHeader := ScreenPtrH (FCaret.Y);
      if (assigned (LineHeader)) and (FCaret.X > LineHeader.Length) then FCaret.X := LineHeader.Length;
      InvalidateLine (FCaret.Y);
      UpdateCaretPos;
      CursorKey := true;
    end;

    vk_down: begin
      InvalidateLine (FCaret.Y);
      if (FCaret.Y < FRows - 1) then inc (FCaret.Y);
      if (FCaret.Y >= FOrigin.Y + FClientSize.Y) then begin
        ScrollTo (FOrigin.X, FCaret.Y - FClientSize.Y + 1);
      end;
      LineHeader := ScreenPtrH (FCaret.Y);
      if (assigned (LineHeader)) and (FCaret.X > LineHeader.Length) then FCaret.X := LineHeader.Length;
      InvalidateLine (FCaret.Y);
      UpdateCaretPos;
      CursorKey := true;
    end;

    vk_prior: begin
      if (ssCtrl in Shift) then begin
        ScrollTo (FOrigin.X, FOrigin.Y - 1);
        InvalidateLine (FCaret.Y);
        if (FCaret.Y > FOrigin.Y + FClientSize.Y - 1) then FCaret.Y := FOrigin.Y + FClientSize.Y - 1;
      end else begin
        InvalidateLine (FCaret.Y);
        if (FCaret.Y > 0) then dec (FCaret.Y, FClientSize.Y);
        if (FCaret.Y < 0) then FCaret.Y := 0;
        if (FCaret.Y < FOrigin.Y) then begin
          ScrollTo (FOrigin.X, FOrigin.Y - FClientSize.Y);
        end;
      end;
      // after "clear output" FCaret.Y is -1: no line header
      LineHeader := ScreenPtrH (FCaret.Y);
      if (assigned (LineHeader)) and (FCaret.X > LineHeader.Length) then FCaret.X := LineHeader.Length;
      InvalidateLine (FCaret.Y);
      UpdateCaretPos;
      Key := 0;
      CursorKey := true;
    end;

    vk_next: begin
      if (ssCtrl in Shift) then begin
        ScrollTo (FOrigin.X, FOrigin.Y + 1);
        InvalidateLine (FCaret.Y);
        if (FCaret.Y < FOrigin.Y) then FCaret.Y := FOrigin.Y;
      end else begin
        InvalidateLine (FCaret.Y);
        if (ssCtrl in Shift) then I := 1 else I := FClientSize.Y;
        if (FCaret.Y < FRows - 1) then inc (FCaret.Y, I);
        if (FCaret.Y > FRows - 1) then FCaret.Y := FRows - 1;
        if (FCaret.Y >= FOrigin.Y + FClientSize.Y) then begin
          ScrollTo (FOrigin.X, FOrigin.Y + FClientSize.Y);
        end;
      end;
      LineHeader := ScreenPtrH (FCaret.Y);
      if (assigned (LineHeader)) and (FCaret.X > LineHeader.Length) then FCaret.X := LineHeader.Length;
      InvalidateLine (FCaret.Y);
      UpdateCaretPos;
      Key := 0;
      CursorKey := true;
    end;

    vk_home: begin
      if (ssCtrl in Shift) then begin
        InvalidateLine (FCaret.Y);
        FCaret.X := 0;
        FCaret.Y := 0;
        InvalidateLine (FCaret.Y);
        ScrollTop;
        UpdateCaretPos;
        Key := 0;
        CursorKey := true;
      end else begin
        FCaret.X := 0;
        UpdateCaretPos;
        Key := 0;
        CursorKey := true;
      end;
    end;

    vk_end: begin
      if (ssCtrl in Shift) then begin
        InvalidateLine (FCaret.Y);
        FCaret.X := FFileHeader.Cursor.X;
        FCaret.Y := FFileHeader.Cursor.Y;
        InvalidateLine (FCaret.Y);
        ScrollBottom;
        UpdateCaretPos;
        Key := 0;
        CursorKey := true;
      end else begin
        LineHeader := ScreenPtrH (FCaret.Y);
        if (assigned (LineHeader)) then FCaret.X := LineHeader.Length;
        UpdateCaretPos;
        Key := 0;
        CursorKey := true;
      end;
    end;

    vk_tab: begin
      if (Shift = []) then begin
        if (Owner is TCustomForm) then begin
          PostMessage (TCustomForm(Owner).Handle, WM_NEXTDLGCTL, 1, 0);
        end;
      end;
      Key := 0;
    end;

    vk_insert, ord ('C'): begin
      if (Shift = [ssCtrl]) then begin
        CopyToClipboard;
        Key := 0;
      end;
    end;

  end;

  if (CursorKey) then begin

    if not (ssShift in Shift) then begin

      FSelectionAnchor.X := FCaret.X;
      FSelectionAnchor.Y := FCaret.Y;

      if (FSelection.Left <> -1) then begin

        R.Left   := (FGutterWidth);
        R.Top    := (FSelection.Top - FOrigin.Y) * FCharSize.Y;
        R.Right  := Width;
        R.Bottom := (FSelection.Bottom - FOrigin.Y + 1) * FCharSize.Y;

        FSelection := Rect (-1, -1, -1, -1);

        InvalidateRect (Handle, @R, false);

      end;

    end else begin

      ModifySelection (FCaret.X, FCaret.Y);

    end;

  end;

end;


procedure   TConsole.wmChar (var Msg: TMessage);
begin
  case (Msg.wParam) of
    9: begin
      Msg.wParam := 0;
      Msg.lParam := 0;
      Msg.Result := 0;
    end;
    else begin
      inherited;
    end;
  end;
end;


procedure   TConsole.ScrollPageDown;
begin
  DoScroll (sb_vert, sb_PageDown, 0);
end;


procedure   TConsole.ScrollPageUp;
begin
  DoScroll (sb_vert, sb_PageUp, 0);
end;


procedure   TConsole.ScrollLineDown;
begin
  DoScroll (sb_vert, sb_LineDown, 0);
end;


procedure   TConsole.ScrollLineUp;
begin
  DoScroll (sb_vert, sb_LineUp, 0);
end;


procedure   TConsole.ScrollTop;
begin
  ScrollTo (0, 0);
end;


procedure   TConsole.ScrollBottom;
begin
  ScrollTo (0, FRows - 1);
end;


procedure   TConsole.wmSetFocus (var Msg: TwmSetFocus);
const
  MethodName = 'wmSetFocus';
begin
  if (Application.Terminated) then exit;
  if (TabStop) then begin
    FFocused := True;
    if (FCaret.Y < 0) or (FCaret.Y >= FOrigin.Y + FClientSize.Y) then begin
      FCaret.Y := FOrigin.Y + FClientSize.Y - 1;
    end else if (FCaret.Y < FOrigin.Y) then begin
      FCaret.Y := FOrigin.Y;
    end;
    Windows.CreateCaret (Handle, 0, GetSystemMetrics (SM_CXBORDER), FCharSize.Y);
    ShowCaret;
    if (FSelectionAnchor.X = -1) then begin
      FSelectionAnchor.X := FCaret.X;
      FSelectionAnchor.Y := FCaret.Y;
    end;
    InvalidateLine (FCaret.Y);
  end;
  InvalidateRect (Handle, nil, false);
  inherited;
end;


procedure   TConsole.wmKillFocus (var Msg: TwmKillFocus);
const
  MethodName = 'wmKillFocus';
begin
  if (Application.Terminated) then exit;
  inherited;
  InvalidateLine (FCaret.Y);
  InvalidateRect (Handle, nil, false);
  Windows.DestroyCaret;
  FFocused := false;
end;


procedure   TConsole.wmGetDlgCode (var Msg: TwmGetDlgCode);
begin
  inherited;
  Msg.Result := Msg.Result or DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTALLKEYS or DLGC_WANTCHARS;
end;


procedure   TConsole.wmEraseBkgnd (var Msg: TwmEraseBkgnd);
begin
  Msg.Result := -1;
end;


procedure   TConsole.MouseDown (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  MethodName = 'MouseDown';

var
  XT, YT: Integer;

begin

  if (TabStop) and (CanFocus) then SetFocus;

  XT := Max (FOrigin.X, (X - FGutterWidth + FOrigin.X * FCharSize.X - FOverhang + FCharSize.X div 2 - 1) div FCharSize.X);
  // below the last line there is no line FRows (that would be the oldest one in the circular buffer)
  YT := Min (FRows - 1, Max (0, (Y + FOrigin.Y * FCharSize.Y) div FCharSize.Y));

  if (Button = mbLeft) then begin

    if (X > FGutterWidth) then begin

      MouseCapture := True;
      DragStartingPoint := Point (-1, -1);

      if (IsPosInSelection (XT, YT)) then begin

        Screen.Cursor := crArrow;
        DragStartingPoint := Point (X, Y);

      end else begin

        FSelectionAnchor.X := XT;
        FSelectionAnchor.Y := YT;
        if (FSelection.Left <> -1) then begin
          FSelection := Rect (-1, -1, -1, -1);
          InvalidateRect (Handle, nil, false);
        end;

        if (XT <> FCaret.X) or (YT <> FCaret.Y) then begin
          InvalidateLine (FCaret.Y);
          FCaret.X := XT;
          FCaret.Y := YT;
          InvalidateLine (FCaret.Y);
          UpdateCaretPos;
        end;

      end;

    end else begin

      if not ((YT >= FSelection.Top) and (YT <= FSelection.Bottom)) then begin

        FSelection := Rect (-1, -1, -1, -1);

        if (YT <> FCaret.Y) then begin
          FCaret.X := 0;
          FCaret.Y := YT;
          UpdateCaretPos;
        end;

        InvalidateRect (Handle, nil, false);

      end;

    end;

  end else if (Button = mbRight) then begin

    if (X > FGutterWidth) then begin

      if (IsPosInSelection (XT, YT)) then begin

        Screen.Cursor := crArrow;

      end else begin

        FSelection := Rect (-1, -1, -1, -1);

        if (XT <> FCaret.X) or (YT <> FCaret.Y) then begin
          FCaret.X := XT;
          FCaret.Y := YT;
          UpdateCaretPos;
        end;

        InvalidateRect (Handle, nil, false);

      end;

    end else begin

      if not ((YT >= FSelection.Top) and (YT <= FSelection.Bottom)) then begin

        FSelection := Rect (-1, -1, -1, -1);

        if (YT <> FCaret.Y) then begin
          FCaret.X := 0;
          FCaret.Y := YT;
          UpdateCaretPos;
        end;

        InvalidateRect (Handle, nil, false);

      end;

    end;

  end;

end;


procedure   TConsole.MouseUp   (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  MethodName = 'MouseUp';
var
  YT: Integer;

begin

  inherited MouseUp (Button, Shift, X, Y);

  if (Button = mbLeft) then begin

    if (DragStartingPoint.X <> -1) then begin
      FSelection := Rect (-1, -1, -1, -1);
      InvalidateRect (Handle, nil, false);
    end;
    DragStartingPoint := Point (-1, -1);
    Screen.Cursor := crDefault;

    if (X <= FGutterWidth) and (not MouseCapture) then begin

      if (assigned (FOnGutterClick)) then begin
        YT := Min (FRows - 1, Max (0, (Y + FOrigin.Y * FCharSize.Y) div FCharSize.Y));
        FOnGutterClick (self, YT);
      end;

    end;

    MouseCapture := false;

  end;

end;


procedure   TConsole.MouseMove (Shift: TShiftState; X, Y: Integer);
const
  MethodName = 'MouseMove';

var
  XT, YT: Integer;

begin

  KillTimer (Handle, 1);
  KillTimer (Handle, 2);

  XT := Max (FOrigin.X, (X - FGutterWidth + FOrigin.X * FCharSize.X - FOverhang + FCharSize.X div 2 - 1) div FCharSize.X);
  // YT = FRows is allowed only for the selection (selects to the end), not for the caret
  YT := Min (FRows, Max (0, (Y + FOrigin.Y * FCharSize.Y) div FCharSize.Y));

  if (MouseCapture) then begin

    if (DragStartingPoint.X = -1) then begin

      if (XT <> FCaret.X) or (Min (YT, FRows - 1) <> FCaret.Y) then begin
        InvalidateLine (FCaret.Y);
        FCaret.X := XT;
        FCaret.Y := Min (YT, FRows - 1);
        InvalidateLine (FCaret.Y);
        UpdateCaretPos;
      end;

      ModifySelection (XT, YT);

      if (YT < FOrigin.Y) then begin
        ScrollTo (0, FOrigin.Y - 3);
      end else if (YT > FOrigin.Y + FClientSize.Y) then begin
        ScrollTo (0, FOrigin.Y + 3);
      end;

      SetTimer (Handle, 1, 20, nil);

      FMousePos := Point (X, Y);

    end else begin

      if (((abs (DragStartingPoint.X - X) >= 8) or (abs (DragStartingPoint.Y - Y) >= 8))) then begin
        if (not FDragsText) then begin
          // DragText returns only after the drop; meanwhile do not start a
          // second operation. The OLE objects are reference-counted.
          FDragsText := true;
          try
            DragText (SelectedText);
          finally
            FDragsText := false;
          end;
          DragStartingPoint := Point (-1, -1);
        end;
      end else begin
        Screen.Cursor := crArrow;
      end;

    end;

  end else begin

    if (X <= FGutterWidth) then begin
      Cursor := crArrow;
    end else begin
      if (isPosInSelection (XT, YT)) then begin
        Cursor := crArrow;
      end else begin
        Cursor := crIBeam;
      end;
    end;

  end;

  if (Abs (FHintPos.X - X) >= 4) or (Abs (FHintPos.Y - Y) >= 4) then begin
    DestroyHint;
    SetTimer (Handle, 2, Application.HintPause, nil);
  end;

end;


function    TConsole.DoMouseWheel (Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
const
  MethodName = 'DoMouseWheel';
  Steps = 3;
var
  N, I: Integer;
begin
  result := inherited DoMouseWheel (Shift, WheelDelta, MousePos);
  if (not result) then begin
    if (FCharSize.Y > 0) then begin
      // sum up small steps (touchpad) instead of rounding them to 0
      if ((FWheelRemainder < 0) and (WheelDelta > 0)) or ((FWheelRemainder > 0) and (WheelDelta < 0)) then FWheelRemainder := 0;
      Inc (FWheelRemainder, WheelDelta);
      N := FWheelRemainder div FCharSize.Y;
      Dec (FWheelRemainder, N * FCharSize.Y);
      for I := 1 to Steps do begin
        ScrollTo (0, FOrigin.Y - (N * I div Steps - N * (I - 1) div Steps));
      end;
    end;
    result := true;
  end;
end;


function    TConsole.IsPosInSelection (X, Y: Integer): Boolean;
begin
  result := ((Y > FSelection.Top)    or ((Y = FSelection.Top)    and (X >= FSelection.Left)))
        and ((Y < FSelection.Bottom) or ((Y = FSelection.Bottom) and (X <= FSelection.Right)));
end;


procedure   TConsole.wmTimer (var msg: TMessage);
begin
  case msg.wParam of
    1: begin
      KillTimer (Handle, 1);
      with FMousePos do begin
        PostMessage (Handle, WM_MOUSEMOVE, 0, makelong (Word(FMousePos.x), Word(FMousePos.y)));
      end;
    end;
    2: begin
      KillTimer (Handle, 2);
      HandleHint;
    end;
    3: begin
      KillTimer (Handle, 3);
      DestroyHint;
    end;
  end;
end;


procedure   TConsole.ModifySelection (X, Y: Integer);
const
  MethodName = 'ModifySelection';

var
  NewSel: TRect;
  Y1, Y2: Integer;
  R: TRect;

begin

  if (FSelectionAnchor.X <> -1) then begin

    if (FSelectionAnchor.Y > Y) or ((FSelectionAnchor.Y = Y) and (FSelectionAnchor.X > X)) then begin

      with NewSel do begin
        Top := Y;
        Left := X;
        Bottom := FSelectionAnchor.Y;
        Right := FSelectionAnchor.X - 1;
      end;

    end else begin

      with NewSel do begin
        Top := FSelectionAnchor.Y;
        Left := FSelectionAnchor.X;
        Bottom := Y;
        Right := X - 1;
      end;

    end;

    with NewSel do begin

      if (Left < 0) then begin
        Left := 0;
      end else if (Left >= FCols) then begin
        Left := 0;
        inc (Top);
      end;

      if (Top < 0) then begin
        Top := 0;
      end else if (Top >= FRows) then begin
        Top := FRows - 1;
      end;

      if (Right < 0) then begin
        Right := FCols - 1;
        Dec (Bottom);
      end else if (Right >= FCols) then begin
        Right := FCols - 1;
      end;

      if (Bottom > FRows) then begin
        Bottom := FRows;
        Right := 0;
      end;

      if (Top > Bottom) then NewSel := Rect (-1, -1, -1, -1);

    end;

    if (not EqualRect (NewSel, FSelection)) then begin

      if (FSelection.Top <> NewSel.Top) or (FSelection.Left <> NewSel.Left) then begin
        Y1 := Min (FSelection.Top, NewSel.Top);
        Y2 := Max (FSelection.Top, NewSel.Top);
        R.Left   := (FGutterWidth);
        R.Top    := (Y1 - FOrigin.Y) * FCharSize.Y;
        R.Right  := Width;
        R.Bottom := (Y2 - FOrigin.Y + 1) * FCharSize.Y;
        InvalidateRect (Handle, @R, false);
      end;

      if (FSelection.Bottom <> NewSel.Bottom) or (FSelection.Right <> NewSel.Right) then begin
        Y1 := Min (FSelection.Bottom, NewSel.Bottom);
        Y2 := Max (FSelection.Bottom, NewSel.Bottom);
        R.Left   := (FGutterWidth);
        R.Top    := (Y1 - FOrigin.Y) * FCharSize.Y;
        R.Right  := Width;
        R.Bottom := (Y2 - FOrigin.Y + 1) * FCharSize.Y;
        InvalidateRect (Handle, @R, false);
      end;

      FSelection := NewSel;

    end;

  end;

end;


function    TConsole.GetVPalette (Ind: Integer): Cardinal;
begin
  Result := FVPalette [Ind];
end;


procedure   TConsole.SetVPalette (Ind: Integer; const TheValue: Cardinal);
begin
  FVPalette [Ind] := TheValue;
end;


function    TConsole.GetHPalette (Ind: Integer): Cardinal;
begin
  Result := FHPalette [Ind];
end;


procedure   TConsole.SetHPalette (Ind: Integer; const TheValue: Cardinal);
begin
  FHPalette [Ind] := TheValue;
end;


function    TConsole.GetTextColorIndex: Integer;
begin
  Result := FTextColor;
end;


procedure   TConsole.SetTextColorIndex (const TheValue: Integer);
begin
  FTextColor := TheValue;
end;


function    TConsole.GetActive: Boolean;
begin
  result := FActive;
end;


procedure   TConsole.SetActive (const Value: Boolean);
const
  MethodName = 'SetActive';

begin

  if (FActive <> Value) then begin

    FActive := Value;

    if not (csLoading in ComponentState) then begin

      ResizeBuffer;

      if (FActive) then begin
        FOrigin.X := 0;
        FOrigin.Y := FRows - 1;
        FCaret.X := 0;
        FCaret.Y := FRows - 1;
        FSelectionAnchor := FCaret;
      end;

      RecalcSizeAndRange;

      InvalidateRect (Handle, nil, false);

    end;

  end;

end;


procedure   TConsole.Loaded;
begin
  inherited Loaded;
  if (FActive) then begin
    FActive := false;
    Active := true;
  end;
end;


function    TConsole.GetFileName: AnsiString;
begin
  result := FFileName;
end;


procedure   TConsole.SetFileName (const Value: AnsiString);
begin
  assert ((csLoading in ComponentState) or (not FActive));
  FFileName := Value;
end;


function    TConsole.GetVirtualMemory: Boolean;
begin
  result := FVirtualMemory;
end;


procedure   TConsole.SetVirtualMemory (const Value: Boolean);
begin
  assert ((csLoading in ComponentState) or (not FActive));
  FVirtualMemory := Value;
end;


function    TConsole.SelectedText: AnsiString;
const
  MethodName = 'SelectedText';
var
  Z: AnsiString;
  I: Integer;
  P: PAnsiChar;
  X, L: Integer;
  Y2: Integer;
begin
  result := '';
  if (FSelection.Top <> -1) then begin
    X := FSelection.Left;
    Y2 := FSelection.Bottom;
    if (Y2 >= FRows) then Y2 := FRows - 1;
    for I := FSelection.Top to Y2 do begin
      if (I < FSelection.Bottom) then begin
        L := FCols - X;
      end else begin
        L := FSelection.Right + 1 - X;
      end;
      P := ScreenPtrT (X, I);
      SetLength (Z, L);
      StrMove (PAnsiChar(Z), P, L);
      result := result + TrimRight (Z);
      if (I < Y2) then result := result + #13#10;
      X := 0;
    end;
  end;
end;


procedure   TConsole.CopyToClipboard;
const
  MethodName = 'CopySelection';
var
  S: AnsiString;
begin
  S := SelectedText;
  if (Length (S) > 0) then begin
    Clipboard.SetTextBuf (PAnsiChar(S));
  end;
end;


procedure   TConsole.Unselect;
begin
  FSelection := Rect (-1, -1, -1, -1);
  FSelectionAnchor := Point (-1, -1);
  InvalidateRect (Handle, nil, false);
end;


procedure   TConsole.SetShowDOS (const Value: Boolean);
begin
  FShowDOS := Value;
  Repaint;
end;


procedure   TConsole.VisibleChanging;
begin
  if (Visible) then begin
    DestroyHint;
    GetCursorPos (FHintPos);
    FHintPos := ScreenToClient (FHintPos);
  end;
  inherited;
end;


procedure   TConsole.HandleHint;
var
  SP, CP: TPoint;
  S: AnsiString;
  R: TRect;
  XT, YT: Integer;
  HT: THintType;

  function GetCursorHeightMargin: Integer;

    function FindScanline (Source: Pointer; MaxLen: Cardinal; Value: Cardinal): Cardinal; assembler;
    asm
      PUSH    ECX
      MOV     ECX, EDX
      MOV     EDX, EDI
      MOV     EDI, EAX
      POP     EAX
      REPE    SCASB
      MOV     EAX, ECX
      MOV     EDI, EDX
    end;

  var
    IconInfo: TIconInfo;
    BitmapInfoSize, BitmapBitsSize, ImageSize: DWORD;
    Bitmap: PBitmapInfoHeader;
    Bits: Pointer;
    BytesPerScanline: Integer;

  begin
    Result := GetSystemMetrics(SM_CYCURSOR);
    if GetIconInfo (GetCursor, IconInfo) then
    try
      GetDIBSizes (IconInfo.hbmMask, BitmapInfoSize, BitmapBitsSize);
      Bitmap := AllocMem(DWORD (BitmapInfoSize) + BitmapBitsSize);
      try
        Bits := Pointer(DWORD (Bitmap) + BitmapInfoSize);
        if GetDIB(IconInfo.hbmMask, 0, Bitmap^, Bits^) and (Bitmap^.biBitCount = 1) then begin
          with Bitmap^ do begin
            BytesPerScanline := ((biWidth * biBitCount + 31) and not 31) div 8;
            ImageSize := biWidth * BytesPerScanline;
            Bits := Pointer(DWORD (Bits) + BitmapBitsSize - ImageSize);
            Result := FindScanline(Bits, ImageSize, $FF);
            if (Result = 0) and (biHeight >= 2 * biWidth) then begin
              Result := FindScanline (Pointer(DWORD (Bits) - ImageSize), ImageSize, $00);
            end;
            Result := Result div BytesPerScanline;
          end;
          Dec (Result, IconInfo.yHotSpot);
        end;
      finally
        FreeMem (Bitmap, BitmapInfoSize + BitmapBitsSize);
      end;
    finally
      if (IconInfo.hbmColor <> 0) then DeleteObject (IconInfo.hbmColor);
      if (IconInfo.hbmMask <> 0) then DeleteObject (IconInfo.hbmMask);
    end;
  end;

begin

  assert (MainThreadID = GetCurrentThreadID);

  DestroyHint;

  if (FActive) then begin

    GetCursorPos (SP);

    CP := ScreenToClient (SP);

    if (CP.X >= 0) and (CP.Y >= 0) and (CP.X < ClientWidth) and (CP.Y < ClientHeight) then begin

      if (ShowHint) then begin

        if (FindDragTarget (SP, false) = self) then begin

          FHintPos := CP;

          if (CP.X > (FCols - FOrigin.X) * FCharSize.X + FGutterWidth) or
             (CP.Y >= (FRows - FOrigin.Y) * FCharSize.Y) then begin

              HT := htOther;
              XT := -1;
              YT := -1;

          end else begin

            if (CP.X < FGutterWidth - 1) then begin

              HT := htGutter;
              XT := -1;
              YT := Max (0, (CP.Y + FOrigin.Y * FCharSize.Y) div FCharSize.Y);

            end else begin

              HT := htText;
              XT := Max (FOrigin.X,
                         (CP.X - FGutterWidth + FOrigin.X * FCharSize.X - FOverhang + FCharSize.X div 2 - 1) div FCharSize.X);
              YT := Max (0, (CP.Y + FOrigin.Y * FCharSize.Y) div FCharSize.Y);

            end;

          end;

          if (assigned (FOnHint)) then begin
            S := FOnHint (self, HT, XT, YT);
          end else begin
            S := '';
          end;

          if (Length (S) > 0) then begin

            Inc (SP.Y, GetCursorHeightMargin);

            FHintWindow := HintWindowClass.Create (Self);

            R := FHintWindow.CalcHintRect (600, S, nil);
            OffsetRect (R, SP.X, SP.Y);

            FHintWindow.ActivateHint (R, S);

            SetTimer (Handle, 3, Application.HintHidePause, nil);

          end;

        end;

      end;

    end else begin

      FHintPos := Point (-1, -1);

    end;

  end;

end;


procedure   TConsole.DestroyHint;
const
  MethodName = 'DestroyHint';
begin
  assert (MainThreadID = GetCurrentThreadID);
  if (assigned (FHintWindow)) then begin
    FHintWindow.ReleaseHandle;
    FHintWindow.Free;
    FHintWindow := nil;
  end;
end;


procedure   TConsole.ApplicationDeactivate (Sender: TObject);
begin
  assert (MainThreadID = GetCurrentThreadID);
  DestroyHint;
end;


procedure   TConsole.SetGutterImages (Value: TCustomImageList);
begin
  if (FGutterImages <> Value) then begin
    if (assigned (FGutterImages)) then begin
      FGutterImages.RemoveFreeNotification (self);
    end;
    FGutterImages := Value;
    if (assigned (FGutterImages)) then begin
      FGutterImages.FreeNotification (self);
    end;
  end;
end;


procedure   TConsole.Notification (AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) then begin
    if (AComponent = FGutterImages) then FGutterImages := nil;
  end;
end;


function    TConsole.GetCursorX: Integer;
begin
  result := FFileHeader.Cursor.X;
end;


function    TConsole.GetCursorY: Integer;
begin
  result := FFileHeader.Cursor.Y;
end;


function    TConsole.GetCaretX: Integer;
begin
  result := FCaret.X;
end;


procedure   TConsole.SetCaretX (const Value: Integer);
begin
  if (FCaret.X <> Value) then begin
    InvalidateLine (FCaret.Y);
    FCaret.X := Value;
    InvalidateLine (FCaret.Y);
    UpdateCaretPos;
  end;
end;


function    TConsole.GetCaretY: Integer;
begin
  result := FCaret.Y;
end;


procedure   TConsole.SetCaretY (const Value: Integer);
begin
  if (FCaret.Y <> Value) then begin
    InvalidateLine (FCaret.Y);
    FCaret.Y := Value;
    InvalidateLine (FCaret.Y);
    if (FCaret.Y < FOrigin.Y) then begin
      ScrollTo (FOrigin.X, FCaret.Y);
    end;
    UpdateCaretPos;
  end;
end;


procedure   TConsole.SetGutterImageIndex (aIndex: Integer; aLine: Integer = -1);
const
  MethodName = 'SetGutterImageIndex';

var
  LineHeader: PLineHeader;
  R: TRect;

begin

  // -1 = caret line; other lines outside the buffer (e.g. those already
  // scrolled out) do not exist
  if (aLine = -1) then aLine := FFileHeader.Cursor.Y;
  if (aLine < 0) or (aLine >= FRows) then exit;

  LineHeader := ScreenPtrH (aLine);
  LineHeader.ImageIndex := aIndex;

  R.Left := 0;
  R.Top  := (aLine - FOrigin.Y) * FCharSize.Y;
  R.Right := FGutterWidth;
  R.Bottom := R.Top + FCharSize.Y;

  InvalidateRect (Handle, @R, false);

end;


function    TConsole.LastAbsNo: Cardinal;
begin
  result := FFileHeader.LastAbsNo;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   Register;
begin
  RegisterComponents ('Paxon', [TConsole]);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  assert (Length (FileHeaderSignature) < 64);
  assert (Sizeof (TLineHeader) <= ExtraBytesPerLine);
  InitConvertTable;

finalization


end.

