{*
 * TBX Package
 * Copyright 2001-2013 Alex A. Denisov and contributors. All rights reserved.
 *
 * The MIT License (MIT)
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom
 * the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *}

unit TBXCore;

{ Extract from TBX.pas (TBX 2.5) for Paxon, 2026: only the parts that are
  self-contained - theme management (CurrentTheme, TBXSetTheme,
  notifications), font settings, text truncation, drawing helpers.
  Paxon draws only with the OfficeXP theme; it is active from the start.
  The bars themselves are in VCL\paxon\src\ToolbarU.pas. }

interface

{$I TBXVer.inc}
{$I TBX.inc}

uses
  Windows, Messages, Classes, SysUtils, Controls, Graphics, ImgList, Forms,
  TBXUtils, TBXThemes;

{ TBX Messages }
const
  TBM_THEMECHANGE = WM_USER + 314;
  TBM_GETVIEWTYPE = WM_USER + 237;
  TBM_GETEFFECTIVECOLOR = WM_USER + 238;

type
  TTextWrapping = (twNone, twEndEllipsis, twPathEllipsis, twWrap);
  TTextTruncation = twNone..twPathEllipsis;
  TTriState = (tsDefault, tsTrue, tsFalse);
  TFontSize = 25..1000;

  TFontSettings = class(TPersistent)
  private
    FBold: TTriState;
    FItalic: TTriState;
    FUnderline: TTriState;
    FStrikeOut: TTriState;
    FSize: TFontSize;
    FColor: TColor;
    FName: TFontName;
    FOnChange: TNotifyEvent;
    procedure SetBold(Value: TTriState);
    procedure SetColor(Value: TColor);
    procedure SetItalic(Value: TTriState);
    procedure SetName(const Value: TFontName);
    procedure SetSize(Value: TFontSize);
    procedure SetStrikeOut(Value: TTriState);
    procedure SetUnderline(Value: TTriState);
  protected
    procedure Modified;
  public
    constructor Create;
    procedure Apply(Font: TFont); overload;
    procedure Apply(var LF: TLogFont; var FontColor: TColor); overload;
    procedure Assign(Src: TPersistent); override;
    function  CreateTransformedFont(Src: HFont; var FontColor: TColor): HFont;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Bold: TTriState read FBold write SetBold default tsDefault;
    property Italic: TTriState read FItalic write SetItalic default tsDefault;
    property Underline: TTriState read FUnderline write SetUnderline default tsDefault;
    property StrikeOut: TTriState read FStrikeOut write SetStrikeOut default tsDefault;
    property Size: TFontSize read FSize write SetSize default 100;  // percent
    property Color: TColor read FColor write SetColor default clNone;
    property Name: TFontName read FName write SetName;   // default ''
  end;

function GetStateFlags(const ItemInfo: TTBXItemInfo): Integer;
function GetTBXTextColor(StateFlags: Integer): TColor;
procedure DrawTBXCaption(Canvas: TCanvas; const Rect: TRect; const Text: string;
  Format: Cardinal; StateFlags: Integer);
procedure DrawTBXImage(Canvas: TCanvas; const Rect: TRect;
  ImageList: TCustomImageList; ImageIndex: Integer; StateFlags: Integer);

var
  CurrentTheme: TTBXTheme;

procedure TBXSetTheme(const AThemeName: string);
function TBXCurrentTheme: string;

procedure AddThemeNotification(AObject: TObject);
procedure RemoveThemeNotification(AObject: TObject);

function GetEffectiveColor(C: TControl): TColor;
procedure DrawParentBackground(Control: TControl; DC: HDC; const R: TRect);

implementation

uses
  TBXUxThemes, TBXOfficeXPTheme, ComCtrls, UxTheme, Themes;

type
  TControlAccess = class(TControl);

  TTBXNexus = class
  private
    FNotifies: TList;
    procedure TBXSysCommand(var Message: TMessage); message TBX_SYSCOMMAND;
  protected
    procedure Broadcast(Msg: Cardinal; Param1, Param2: Integer);
  public
    constructor Create(const DefaultTheme: string);
    destructor Destroy; override;
    procedure SetTheme(const AThemeName: string);
    function  GetTheme: string;
    procedure AddNotifyTarget(AObject: TObject);
    procedure RemoveNotifyTarget(AObject: TObject);
  end;

var
  TBXNexus: TTBXNexus;

procedure AddThemeNotification(AObject: TObject);
begin
  TBXNexus.AddNotifyTarget(AObject);
end;

procedure RemoveThemeNotification(AObject: TObject);
begin
  if TBXNexus <> nil then TBXNexus.RemoveNotifyTarget(AObject);
end;

procedure TBXSetTheme(const AThemeName: string);
begin
  TBXNexus.SetTheme(AThemeName);
end;

function TBXCurrentTheme: string;
begin
  Result := TBXNexus.GetTheme;
end;

function GetEffectiveColor(C: TControl): TColor;
var
  Message: TMessage;
begin
  if C = nil then Result := clBtnFace
  else
  begin
    Message.Msg := TBM_GETEFFECTIVECOLOR;
    Message.WParam := 0;
    Message.LParam := 0;
    Message.Result := 0;
    C.Dispatch(Message);
    if Message.Result <> 0 then Result := Message.WParam
    else if (C is TForm) and (TForm(C).FormStyle = fsMDIForm) then
      Result := clBtnFace
    else
      Result := TControlAccess(C).Color;
  end;
end;

procedure DrawParentBackground(Control: TControl; DC: HDC; const R: TRect);
label
  DrawTabSheet;
var
  Parent: TWinControl;
  R2: TRect;
  BufDC: HDC;
  BufDCRec: TBufDCRec;
  ResultOK: Boolean;
begin
  if Control = nil then Exit;
  Parent := Control.Parent;
  if (Parent <> nil) and Parent.HandleAllocated then
  begin
    if (ThemeServices.ThemesEnabled or USE_THEMES) and
      (Parent is TTabSheet){special case} then goto DrawTabSheet;

    SetPoint(R2.TopLeft, 0, 0);
    R2.TopLeft := Parent.ScreenToClient(Control.ClientToScreen(R2.TopLeft));
    OffsetWindowOrgEx(DC, R2.Left, R2.Top, R2.TopLeft);
    ResultOK := Parent.Perform(WM_ERASEBKGND, WPARAM(DC), LPARAM(DC)) <> 0;
    SetWindowOrgEx(DC, R2.Left, R2.Top, nil);
    if ResultOK then Exit;

    if (ThemeServices.ThemesEnabled or USE_THEMES) and
      (Control is TWinControl) then
    begin
      DrawTabSheet:
      R2 := R;
      OffsetRect(R2, -R2.Left, -R2.Top);
      BufDC := CreateBufDC(DC, R2.Right, R2.Bottom, BufDCRec);
      { Fortunately, DrawThemeParentBackground has no problems if DC is memory DC }
      if ThemeServices.ThemesEnabled then
        ResultOK := UxTheme.DrawThemeParentBackground(TWinControl(Control).Handle, BufDC, @R2) = S_OK
      else
        ResultOK := TBXUxThemes.DrawThemeParentBackground(TWinControl(Control).Handle, BufDC, @R2) = S_OK;
      if ResultOK then
        BitBlt(DC, R.Left, R.Top, R2.Right, R2.Bottom, BufDC, 0, 0, SRCCOPY);
      DeleteBufDC(BufDCRec);
      if ResultOK then Exit;
    end;

    FillRectEx(DC, R, GetEffectiveColor(Parent));
  end
  else FillRectEx(DC, R, clBtnFace);
end;

function GetStateFlags(const ItemInfo: TTBXItemInfo): Integer;
const
  CEnabledStates: array [Boolean] of Integer = (ISF_DISABLED, 0);
  CHotStates: array [Boolean] of Integer = (0, ISF_HOT);
  CPushedStates: array [Boolean] of Integer = (0, ISF_PUSHED);
  CSelectedStates: array [Boolean] of Integer = (0, ISF_SELECTED);
begin
  with ItemInfo do
    Result := CEnabledStates[ItemInfo.Enabled] or CPushedStates[ItemInfo.Pushed] or
      CHotStates[ItemInfo.HoverKind = hkMouseHover] or CSelectedStates[ItemInfo.Selected];
end;

procedure StateFlagsToItemInfo(StateFlags: Integer; var ItemInfo: TTBXItemInfo);
const
  HoverKinds: array [Boolean] of TTBXHoverKind = (hkNone, hkMouseHover);
begin
  FillChar(ItemInfo, SizeOf(ItemInfo), 0);
  case StateFlags and ISF_LOCATIONMASK of
    ISF_TOOLBARCOLOR:
      begin
        ItemInfo.ViewType := VT_TOOLBAR;
        ItemInfo.ItemOptions := IO_TOOLBARSTYLE;
      end;
    ISF_MENUCOLOR:
      begin
        ItemInfo.ViewType := VT_DOCKPANEL;
      end;
    ISF_STATUSCOLOR:
      begin
        ItemInfo.ViewType := VT_STATUSBAR;
      end;
  else
    ItemInfo.ViewType := VT_UNKNOWN;
  end;
  ItemInfo.Enabled := StateFlags and ISF_DISABLED = 0;
  ItemInfo.Pushed := StateFlags and ISF_PUSHED <> 0;
  ItemInfo.HoverKind := HoverKinds[StateFlags and ISF_HOT <> 0];
  ItemInfo.Selected := StateFlags and ISF_SELECTED <> 0;
end;

function GetTBXTextColor(StateFlags: Integer): TColor;
var
  ItemInfo: TTBXItemInfo;
begin
  StateFlagsToItemInfo(StateFlags, ItemInfo);
  Result := CurrentTheme.GetItemTextColor(ItemInfo);
end;

procedure DrawTBXCaption(Canvas: TCanvas; const Rect: TRect; const Text: string;
  Format: Cardinal; StateFlags: Integer);
var
  ItemInfo: TTBXItemInfo;
begin
  StateFlagsToItemInfo(StateFlags, ItemInfo);
  CurrentTheme.PaintCaption(Canvas, Rect, ItemInfo, Text, Format, False);
end;

procedure DrawTBXImage(Canvas: TCanvas; const Rect: TRect;
  ImageList: TCustomImageList; ImageIndex: Integer; StateFlags: Integer);
var
  ItemInfo: TTBXItemInfo;
begin
  StateFlagsToItemInfo(StateFlags, ItemInfo);
  CurrentTheme.PaintImage(Canvas, Rect, ItemInfo, ImageList, ImageIndex);
end;

{ TFontSettings }

procedure TFontSettings.Apply(Font: TFont);
var
  FS: TFontStyles;
begin
  if Size <> 100 then Font.Size := (Font.Size * FSize + 50) div 100;
  if Color <> clNone then Font.Color := Color;
  if Name <> '' then Font.Name := Name;
  FS := Font.Style;
  if Bold = tsTrue then Include(FS, fsBold)
  else if Bold = tsFalse then Exclude(FS, fsBold);
  if Italic = tsTrue then Include(FS, fsItalic)
  else if Italic = tsFalse then Exclude(FS, fsItalic);
  if Underline = tsTrue then Include(FS, fsUnderline)
  else if Underline = tsFalse then Exclude(FS, fsUnderline);
  if StrikeOut = tsTrue then Include(FS, fsStrikeOut)
  else if StrikeOut = tsFalse then Exclude(FS, fsStrikeOut);
  Font.Style := FS;
end;

procedure TFontSettings.Apply(var LF: TLogFont; var FontColor: TColor);
begin
  if Size <> 100 then LF.lfHeight := (LF.lfHeight * Size + 50) div 100;
  if Color <> clNone then FontColor := Color;
  if Name <> '' then StrPLCopy(LF.lfFaceName, Name, 31);
  if Bold = tsTrue then LF.lfWeight := FW_BOLD
  else if Bold = tsFalse then LF.lfWeight := FW_NORMAL;
  if Italic = tsTrue then LF.lfItalic := 1
  else if Italic = tsFalse then LF.lfItalic := 0;
  if Underline = tsTrue then LF.lfUnderline := 1
  else if Underline = tsFalse then LF.lfUnderline := 0;
  if StrikeOut = tsTrue then LF.lfStrikeOut := 1
  else if StrikeOut = tsFalse then LF.lfStrikeOut := 0;
end;

procedure TFontSettings.Assign(Src: TPersistent);
var
  F: TFontSettings;
begin
  if Src is TFontSettings then
  begin
    F := TFontSettings(Src);
    if (FBold <> F.Bold) or (FItalic <> F.Italic) or (FUnderline <> F.Underline) or
      (FStrikeOut <> F.StrikeOut) or (FSize <> F.Size) or (FColor <> F.Color) or
      (FName <> F.Name) then
    begin
      FBold := F.Bold;
      FItalic := F.Italic;
      FUnderline := F.Underline;
      FStrikeOut := F.StrikeOut;
      FSize := F.Size;
      FColor := F.Color;
      FName := F.Name;
      Modified;
    end;
  end
  else inherited;
end;

constructor TFontSettings.Create;
begin
  FSize := 100;
  FColor := clNone;
end;

function TFontSettings.CreateTransformedFont(Src: HFont; var FontColor: TColor): HFont;
var
  LF: TLogFont;
begin
  GetObject(Src, SizeOf(LF), @LF);
  Apply(LF, FontColor);
  Result := CreateFontIndirect(LF);
end;

procedure TFontSettings.Modified;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TFontSettings.SetBold(Value: TTriState);
begin
  if FBold <> Value then
  begin
    FBold := Value;
    Modified;
  end;
end;

procedure TFontSettings.SetColor(Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Modified;
  end;
end;

procedure TFontSettings.SetItalic(Value: TTriState);
begin
  if FItalic <> Value then
  begin
    FItalic := Value;
    Modified;
  end;
end;

procedure TFontSettings.SetName(const Value: TFontName);
begin
  if FName <> Value then
  begin
    FName := Value;
    Modified;
  end;
end;

procedure TFontSettings.SetSize(Value: TFontSize);
begin
  if FSize <> Value then
  begin
    FSize := Value;
    Modified;
  end;
end;

procedure TFontSettings.SetStrikeOut(Value: TTriState);
begin
  if FStrikeOut <> Value then
  begin
    FStrikeOut := Value;
    Modified;
  end;
end;

procedure TFontSettings.SetUnderline(Value: TTriState);
begin
  if FUnderline <> Value then
  begin
    FUnderline := Value;
    Modified;
  end;
end;

{ TTBXNexus }

procedure TTBXNexus.AddNotifyTarget(AObject: TObject);
begin
  if FNotifies.IndexOf(AObject) < 0 then FNotifies.Add(AObject);
end;

procedure TTBXNexus.Broadcast(Msg: Cardinal; Param1, Param2: Integer);
var
  M: TMessage;
  I: Integer;
begin
  if FNotifies.Count > 0 then
  begin
    M.Msg := Msg;
    M.WParam := WPARAM(Param1);
    M.LParam := LPARAM(Param2);
    M.Result := 0;
    { Paxon: backwards, so that a receiver may unregister while being notified }
    for I := FNotifies.Count - 1 downto 0 do
      if I < FNotifies.Count then TObject(FNotifies[I]).Dispatch(M);
  end;
end;

constructor TTBXNexus.Create(const DefaultTheme: string);
begin
  FNotifies := TList.Create;
  CurrentTheme := GetTBXTheme(DefaultTheme);
  AddTBXSysChangeNotification(Self);
end;

destructor TTBXNexus.Destroy;
begin
  RemoveTBXSysChangeNotification(Self);
  ReleaseTBXTheme(CurrentTheme);
  FNotifies.Free;
  inherited;
end;

function TTBXNexus.GetTheme: string;
begin
  Result := CurrentTheme.Name;
end;

procedure TTBXNexus.RemoveNotifyTarget(AObject: TObject);
begin
  FNotifies.Remove(AObject);
end;

procedure TTBXNexus.SetTheme(const AThemeName: string);
begin
  if IsTBXThemeAvailable(AThemeName) then
  begin
    ReleaseTBXTheme(CurrentTheme);
    CurrentTheme := GetTBXTheme(AThemeName);
    Broadcast(TBM_THEMECHANGE, TSC_BEFOREVIEWCHANGE, 1);
    Broadcast(TBM_THEMECHANGE, TSC_VIEWCHANGE, 1);
    Broadcast(TBM_THEMECHANGE, TSC_AFTERVIEWCHANGE, 1);
  end;
end;

procedure TTBXNexus.TBXSysCommand(var Message: TMessage);
begin
  { Retranslate TBX_SYSCOMMAND to TBM_THEMECHANGE }
  if Message.Msg = TBX_SYSCOMMAND then
    Broadcast(TBM_THEMECHANGE, Message.WParam, 0);
end;

initialization
  // TBXOfficeXPTheme registers its theme in its own initialization section
  TBXNexus := TTBXNexus.Create('OfficeXP');

finalization
  FreeAndNil(TBXNexus);

end.
