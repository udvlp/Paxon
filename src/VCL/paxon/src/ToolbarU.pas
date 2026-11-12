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
//  The drawing routines for items, bar frames, popup frames and
//  dock background follow TBX.pas (TBX 2.5, Copyright 2001-2013 Alex A.
//  Denisov and contributors, MIT license, see VCL\tbxthemes\LICENSE),
//  so that the TBX theme fits unchanged.
//


unit ToolbarU;


// Bars and menus for the main window.
//
//   TToolbarDock        Area at the top of the window or in a splitter bar; arranges the
//                       bars in rows one below the other and adjusts its height.
//   TPaxonToolbar       Command, menu or channel bar at a fixed position (not
//                       movable); wrapping or chevron if there is not enough space.
//   TToolbarElement     Button or menu item, can also be bound to an action;
//   TToolbarSubmenu  with subitems; TToolbarSeparator separator line.
//   TToolbarPopupMenu   Context menu (Popup returns only after a selection).
//
// Drawing uses the TBX theme Office XP (TBXCore.CurrentTheme).


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ImgList, ActnList,
  Menus, TBXThemes, TBXCore;


type

  TToolbarDock = class;
  TPaxonToolbar = class;
  TToolbarElement = class;
  TToolbarPopupMenu = class;


  // What an item shows in a bar (in a menu always image and text)
  TToolbarDisplay = (anStandard,       // image, text only without image
                     anImageAndText,
                     anTextOnly,
                     anImageOnly);

  // Behaviour of a bar when its space is not sufficient
  TToolbarShrink = (lkChevron,       // surplus items behind a chevron
                      lkWrap);      // items on several lines


  TToolbarElementActionLink = class (TActionLink)
  protected
    FClient: TToolbarElement;
    procedure   AssignClient (AClient: TObject); override;
    function    IsAutoCheckLinked: Boolean; virtual;
    function    IsCaptionLinked: Boolean; override;
    function    IsCheckedLinked: Boolean; override;
    function    IsEnabledLinked: Boolean; override;
    function    IsGroupIndexLinked: Boolean; override;
    function    IsHintLinked: Boolean; override;
    function    IsImageIndexLinked: Boolean; override;
    function    IsShortCutLinked: Boolean; override;
    function    IsVisibleLinked: Boolean; override;
    function    IsOnExecuteLinked: Boolean; override;
    procedure   SetAutoCheck (Value: Boolean); override;
    procedure   SetCaption (const Value: String); override;
    procedure   SetChecked (Value: Boolean); override;
    procedure   SetEnabled (Value: Boolean); override;
    procedure   SetGroupIndex (Value: Integer); override;
    procedure   SetHint (const Value: String); override;
    procedure   SetImageIndex (Value: Integer); override;
    procedure   SetShortCut (Value: TShortCut); override;
    procedure   SetVisible (Value: Boolean); override;
    procedure   SetOnExecute (Value: TNotifyEvent); override;
  end;


  TToolbarElement = class (TComponent)
  private
    FActionLink: TToolbarElementActionLink;
    FDisplayMode: TToolbarDisplay;
    FAutoCheck: Boolean;
    FToolbarImages: TCustomImageList;
    FCaption: String;
    FChecked: Boolean;
    FParentElement: TToolbarElement;
    FEnabled: Boolean;
    FBoldText: Boolean;
    FGroupIndex: Integer;
    FHint: String;
    FImageIndex: TImageIndex;
    FChildren: TList;
    FRadioItem: Boolean;
    FShortCut: TShortCut;
    FVisible: Boolean;
    FRootOf: TComponent;      // bar or popup menu if this is its root
    FOnClick: TNotifyEvent;
    function    GetAction: TBasicAction;
    function    GetCount: Integer;
    function    GetItem (Index: Integer): TToolbarElement;
    function    IsCaptionStored: Boolean;
    function    IsCheckedStored: Boolean;
    function    IsEnabledStored: Boolean;
    function    IsHintStored: Boolean;
    function    IsImageIndexStored: Boolean;
    function    IsOnClickStored: Boolean;
    function    IsShortCutStored: Boolean;
    function    IsVisibleStored: Boolean;
    function    IsAutoCheckStored: Boolean;
    procedure   SetAction (Value: TBasicAction);
    procedure   SetDisplayMode (Value: TToolbarDisplay);
    procedure   SetToolbarImages (Value: TCustomImageList);
    procedure   SetCaption (const Value: String);
    procedure   SetChecked (Value: Boolean);
    procedure   SetEnabled (Value: Boolean);
    procedure   SetBoldText (Value: Boolean);
    procedure   SetGroupIndex (Value: Integer);
    procedure   SetImageIndex (Value: TImageIndex);
    procedure   SetRadioItem (Value: Boolean);
    procedure   SetShortCut (Value: TShortCut);
    procedure   SetVisible (Value: Boolean);
    procedure   DoActionChange (Sender: TObject);
    procedure   DeselectGroup;
  protected
    procedure   ActionChange (Sender: TObject; CheckDefaults: Boolean); virtual;
    procedure   SignalChange (ArrangeElements: Boolean);
    procedure   GetChildren (Proc: TGetChildProc; Root: TComponent); override;
    procedure   Notification (AComponent: TComponent; Operation: TOperation); override;
    procedure   SetChildOrder (Child: TComponent; Order: Integer); override;
    procedure   SetParentComponent (Value: TComponent); override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    function    GetParentComponent: TComponent; override;
    function    HasParent: Boolean; override;
    procedure   Add (Element: TToolbarElement);
    procedure   Insert (Index: Integer; Element: TToolbarElement);
    procedure   Remove (Element: TToolbarElement);
    procedure   Clear;
    function    IndexOf (Element: TToolbarElement): Integer;
    procedure   Click; virtual;
    procedure   InitiateAction; virtual;
    function    IsSubmenu: Boolean; virtual;
    function    IsSeparator: Boolean; virtual;
    function    TreeRoot: TToolbarElement;
    function    OwnerToolbar: TPaxonToolbar;
    function    EffectiveImages: TCustomImageList;
    function    ShortcutLabel: String;
    function    AcceleratorChar: Char;
    property    Count: Integer read GetCount;
    property    Items[Index: Integer]: TToolbarElement read GetItem; default;
    property    Parent: TToolbarElement read FParentElement;
  published
    property    Action: TBasicAction read GetAction write SetAction;
    property    DisplayMode: TToolbarDisplay read FDisplayMode write SetDisplayMode default anStandard;
    property    AutoCheck: Boolean read FAutoCheck write FAutoCheck stored IsAutoCheckStored default false;
    property    ToolbarImages: TCustomImageList read FToolbarImages write SetToolbarImages;
    property    Caption: String read FCaption write SetCaption stored IsCaptionStored;
    property    Checked: Boolean read FChecked write SetChecked stored IsCheckedStored default false;
    property    Enabled: Boolean read FEnabled write SetEnabled stored IsEnabledStored default true;
    property    BoldText: Boolean read FBoldText write SetBoldText default false;
    property    GroupIndex: Integer read FGroupIndex write SetGroupIndex default 0;
    property    Hint: String read FHint write FHint stored IsHintStored;
    property    ImageIndex: TImageIndex read FImageIndex write SetImageIndex stored IsImageIndexStored default -1;
    property    RadioItem: Boolean read FRadioItem write SetRadioItem default false;
    property    ShortCut: TShortCut read FShortCut write SetShortCut stored IsShortCutStored default 0;
    property    Visible: Boolean read FVisible write SetVisible stored IsVisibleStored default true;
    property    OnClick: TNotifyEvent read FOnClick write FOnClick stored IsOnClickStored;
  end;


  TToolbarSubmenu = class (TToolbarElement)
  public
    function    IsSubmenu: Boolean; override;
  end;


  TToolbarSeparator = class (TToolbarElement)
  public
    function    IsSeparator: Boolean; override;
  end;


  // How an item is drawn
  TElementView = record
    ViewType: Integer;
    IsToolbarStyle: Boolean;
    ImageOverText: Boolean;
    ToolbarImages: TCustomImageList;
    PopupBorder: Integer;
    HidePrefix: Boolean;
  end;


  // Position of an item in a bar or popup (client coordinates)
  TElementSlot = record
    Element: TToolbarElement;
    R: TRect;
  end;
  TElementSlots = array of TElementSlot;


  TToolbarDock = class (TCustomControl)
  private
    FBackgroundOnToolbars: Boolean;
    FArranging: Boolean;
    procedure   SetBackgroundOnToolbars (Value: Boolean);
    procedure   CMColorChanged (var Message: TMessage); message CM_COLORCHANGED;
    procedure   TBMGetEffectiveColor (var Message: TMessage); message TBM_GETEFFECTIVECOLOR;
    procedure   TBMThemeChange (var Message: TMessage); message TBM_THEMECHANGE;
    procedure   WMEraseBkgnd (var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure   WMMove (var Message: TWMMove); message WM_MOVE;
  protected
    procedure   AlignControls (AControl: TControl; var Rect: TRect); override;
    procedure   Loaded; override;
    procedure   Paint; override;
    procedure   Resize; override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   ArrangeElements;
    procedure   DrawBackground (DC: HDC; const DrawRect: TRect);
    function    EffectiveColor: TColor;
    function    UsingBackground: Boolean;
    function    ToolbarCount: Integer;
  published
    property    BackgroundOnToolbars: Boolean read FBackgroundOnToolbars write SetBackgroundOnToolbars default true;
    property    Color default clNone;
    property    Cursor;
    property    Visible;
    property    OnMouseDown;
    property    OnMouseMove;
    property    OnMouseUp;
    property    OnResize;
  end;


  TPaxonToolbar = class (TCustomControl)
  private
    FUpdateLevel: Integer;
    FArrangeNeeded: Boolean;
    FChevronHot: Boolean;
    FChevronOpen: Boolean;
    FImageOverText: Boolean;
    FToolbarImages: TCustomImageList;
    FAssignedImagesLink: TChangeLink;
    FChevron: TRect;
    FDockRow: Integer;
    FPressedElement: TToolbarElement;
    FHotElement: TToolbarElement;
    FShowElementHints: Boolean;
    FShrink: TToolbarShrink;
    FMenuBar: Boolean;
    FOpenElement: TToolbarElement;        // item whose popup is currently open
    FElementSlots: TElementSlots;
    FProcessShortCuts: Boolean;
    FStretch: Boolean;
    FKeyboard: TToolbarElement;     // item selected via keyboard (menu bar)
    FKeyboardChars: Boolean;      // underlines despite hidden keyboard cues
    FUpdateActions: Boolean;
    FHiddenElements: TList;              // items behind the chevron
    FRootElement: TToolbarElement;
    FContentWidth, FContentHeight: Integer;   // most recently arranged content
    procedure   ToolbarImagesChanged (Sender: TObject);
    function    GetCurrentDock: TToolbarDock;
    procedure   SetImageOverText (Value: Boolean);
    procedure   SetToolbarImages (Value: TCustomImageList);
    procedure   SetDockRow (Value: Integer);
    procedure   SetShowElementHints (Value: Boolean);
    procedure   SetShrink (Value: TToolbarShrink);
    procedure   SetMenuBar (Value: Boolean);
    procedure   SetStretch (Value: Boolean);
    procedure   CMHintShow (var Message: TCMHintShow); message CM_HINTSHOW;
    procedure   CMMouseLeave (var Message: TMessage); message CM_MOUSELEAVE;
    procedure   CMVisibleChanged (var Message: TMessage); message CM_VISIBLECHANGED;
    procedure   TBMGetEffectiveColor (var Message: TMessage); message TBM_GETEFFECTIVECOLOR;
    procedure   TBMGetViewType (var Message: TMessage); message TBM_GETVIEWTYPE;
    procedure   TBMThemeChange (var Message: TMessage); message TBM_THEMECHANGE;
    procedure   WMEraseBkgnd (var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure   WMNCCalcSize (var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure   WMNCHitTest (var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure   WMNCPaint (var Message: TMessage); message WM_NCPAINT;
    function    CalculateLayout (LengthValue: Integer; ApplyLayout: Boolean): TPoint;
    procedure   SetElements;
    procedure   ToolbarInfo (var TI: TTBXToolbarInfo);
    procedure   PaintToolbarBackground (DC: HDC);
    procedure   DrawNC (Clip: HRGN);
  protected
    procedure   CreateParams (var Params: TCreateParams); override;
    procedure   Resize; override;
    procedure   GetChildren (Proc: TGetChildProc; Root: TComponent); override;
    procedure   Loaded; override;
    procedure   MouseDown (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure   MouseMove (Shift: TShiftState; X, Y: Integer); override;
    procedure   MouseUp (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure   Notification (AComponent: TComponent; Operation: TOperation); override;
    procedure   Paint; override;
    procedure   SetParent (AParent: TWinControl); override;
    procedure   SetChildOrder (Child: TComponent; Order: Integer); override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   BeginUpdate;
    procedure   EndUpdate;
    procedure   InitiateAction; override;
    procedure   ElementChanged (Element: TToolbarElement; ArrangeElements: Boolean);
    function    ElementAt (const P: TPoint): TToolbarElement;
    function    ElementRect (Element: TToolbarElement): TRect;
    procedure   InvalidateElementArea (Element: TToolbarElement);
    function    Docked: Boolean;
    function    Embedded: Boolean;
    function    EffectiveColor: TColor;
    function    ViewType: Integer;
    function    NonClientBorders: TRect;             // non-client area (left, top, right, bottom)
    function    ContentSize (LengthValue: Integer): TPoint;
    function    MinimumLength: Integer;
    procedure   ArrangeElements;
    procedure   FitInto (WidthPx, FitHeight: Integer);
    function    IsShortCut (ShortcutKey: TShortCut): Boolean;
    function    OpenMenu (Element: TToolbarElement; ByKeyboard: Boolean): Boolean;
    procedure   KeyboardMode;
    function    SearchAccelerator (C: Char): TToolbarElement;
    function    ElementView: TElementView;
    property    CurrentDock: TToolbarDock read GetCurrentDock;
    property    Items: TToolbarElement read FRootElement;
  published
    property    ImageOverText: Boolean read FImageOverText write SetImageOverText default false;
    property    Caption;
    property    Color default clNone;
    property    DockRow: Integer read FDockRow write SetDockRow default 0;
    property    ShowElementHints: Boolean read FShowElementHints write SetShowElementHints default false;
    property    Images: TCustomImageList read FToolbarImages write SetToolbarImages;
    property    Shrink: TToolbarShrink read FShrink write SetShrink default lkChevron;
    property    MenuBar: Boolean read FMenuBar write SetMenuBar default false;
    property    ParentShowHint;
    property    ProcessShortCuts: Boolean read FProcessShortCuts write FProcessShortCuts default false;
    property    ShowHint;
    property    Stretch: Boolean read FStretch write SetStretch default false;
    property    UpdateActions: Boolean read FUpdateActions write FUpdateActions default true;
    property    Visible;
  end;


  TToolbarPopupMenu = class (TComponent)
  private
    FToolbarImages: TCustomImageList;
    FRootElement: TToolbarElement;
    procedure   SetToolbarImages (Value: TCustomImageList);
  protected
    procedure   GetChildren (Proc: TGetChildProc; Root: TComponent); override;
    procedure   Notification (AComponent: TComponent; Operation: TOperation); override;
    procedure   SetChildOrder (Child: TComponent; Order: Integer); override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Popup (X, Y: Integer);
    property    Items: TToolbarElement read FRootElement;
  published
    property    Images: TCustomImageList read FToolbarImages write SetToolbarImages;
  end;


procedure   Register;


implementation


uses
  MultiMon, MMSystem, TBXUtils, TBXStatusBars, ToolbarHelpU;


const
  CS_DROPSHADOW = $00020000;
  SPI_GETKEYBOARDCUES = $100A;
  SPI_GETMENUSHOWDELAY_ = 106;
  ChevronSize = 13;
  TimerSubmenu = 1;


type
  TPopupWindow = class;
  TMenuLoop = class;


  TPopupWindow = class (TCustomControl)
  private
    FLoop: TMenuLoop;
    FContentElement: TToolbarElement;     // its children are shown
    FChevronElements: TList;             // chevron: the hidden items of the bar
    FElementSlots: TElementSlots;
    FSelectedSlot: Integer;
    FByMouse: Boolean;
    FKind: TPopupWindow;
    FChildIndex: Integer;
    FParentRect: TRect;           // screen: the item the popup belongs to
    FParentToolbarStyle: Boolean;
    FOpposite: Boolean;         // submenu to the left of the parent (deeper ones follow)
    FViewType: Integer;
    FView: TElementView;
    FDropShadows: TShadows;
    procedure   CMHintShow (var Message: TCMHintShow); message CM_HINTSHOW;
    procedure   WMEraseBkgnd (var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure   WMMouseActivate (var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure   WMNCCalcSize (var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure   WMNCPaint (var Message: TMessage); message WM_NCPAINT;
    procedure   WMTimer (var Message: TWMTimer); message WM_TIMER;
    procedure   TBMGetViewType (var Message: TMessage); message TBM_GETVIEWTYPE;
  protected
    procedure   CreateParams (var Params: TCreateParams); override;
    procedure   Paint; override;
  public
    constructor Create (ALoop: TMenuLoop; AElementContent: TToolbarElement; AElements: TList); reintroduce;
    destructor  Destroy; override;
    procedure   ArrangeElements;
    procedure   ShowPopup (const ParentBounds: TRect; AsSubmenu, ParentToolbarStyle: Boolean; X, Y: Integer);
    function    ElementIndexAt (const P: TPoint): Integer;
    procedure   SelectEntry (Index: Integer; ByMouse: Boolean);
    procedure   InvalidateSlot (Index: Integer);
    function    IsSelectable (Index: Integer): Boolean;
    function    NextIndex (Index, StepDirection: Integer): Integer;
    procedure   CreatePopupShadow;
    procedure   DrawNC (DC: HDC);
  end;


  // Modal menu loop (as with Windows menus): mouse and keyboard go to the
  // popups and the menu bar until an item is selected or the menu is left.
  TMenuLoop = class
  private
    FOwnerToolbar: TPaxonToolbar;
    FPopupMenu: TToolbarPopupMenu;
    FWindows: TList;
    FClick: TToolbarElement;
    FEndRequested: Boolean;
    FKeyboard: Boolean;
    FCaptureWindow: HWND;
    FLoopForm: TCustomForm;
    FMouseStart: TPoint;
    FMouseMoved: Boolean;
    FLastMouse: TPoint;        // last evaluated mouse position
    function    TopmostPopup: TPopupWindow;
    function    WindowAt (const P: TPoint): TPopupWindow;
    procedure   CloseFrom (MenuLevel: Integer);
    procedure   OpenToolbarElement (E: TToolbarElement; ByKeyboard: Boolean);
    procedure   OpenSubmenu (F: TPopupWindow; Index: Integer; ByKeyboard: Boolean);
    procedure   ChooseItem (F: TPopupWindow; Index: Integer; ByKeyboard: Boolean);
    procedure   MouseMoved (const P: TPoint);
    procedure   MousePressed (const P: TPoint);
    procedure   MouseReleased (const P: TPoint);
    function    HandleKey (HandleKey: Word): Boolean;
    procedure   HandleChar (C: Char);
    procedure   SwitchToolbar (StepDirection: Integer);
    procedure   QuitLoop;
  public
    constructor Create (AOwnerToolbar: TPaxonToolbar; APopupMenu: TToolbarPopupMenu; AOwningForm: TCustomForm);
    destructor  Destroy; override;
    procedure   ExecuteLoop;
    procedure   OpenChevron;
    procedure   ElementChanged;
    procedure   ElementRemoved (E: TToolbarElement);
    procedure   TimerSubmenu (F: TPopupWindow);
  end;


  // Hooks into the window procedure of a form: Alt, F10 and Alt+letter
  // for the menu bar and bars, application activation, system settings.
  TFormHook = class (TComponent)
  private
    FForm: TCustomForm;
    FOldProcedure: TWndMethod;
    FToolbars: TList;
    procedure   NewProcedure (var Message: TMessage);
  protected
    procedure   Notification (AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create (AForm: TCustomForm); reintroduce;
    destructor  Destroy; override;
    function    MenuBarToolbar: TPaxonToolbar;
  end;


var
  ActiveLoop: TMenuLoop = nil;
  FormHooks: TList = nil;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Helper functions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    HookFor (Form: TCustomForm; CreateIfMissing: Boolean): TFormHook;
var
  I: Integer;
begin
  result := nil;
  if (not assigned (Form)) then exit;
  if (assigned (FormHooks)) then begin
    for I := 0 to FormHooks.Count - 1 do begin
      if (TFormHook(FormHooks[I]).FForm = Form) then begin
        result := TFormHook(FormHooks[I]);
        exit;
      end;
    end;
  end;
  if (CreateIfMissing) and (not (csDesigning in Form.ComponentState)) then begin
    if (not assigned (FormHooks)) then FormHooks := TList.Create;
    result := TFormHook.Create (Form);
    FormHooks.Add (result);
  end;
end;


function    OwnerFormOf (C: TComponent): TCustomForm;
begin
  result := nil;
  while (assigned (C)) do begin
    if (C is TCustomForm) then begin
      result := TCustomForm(C);
      exit;
    end;
    C := C.Owner;
  end;
end;


// Registers the bar with the hook of its form (Alt, F10, shortcuts).
// From Create (also bars created in code) and Loaded; registering twice does no harm.
procedure   RegisterToolbar (L: TPaxonToolbar);
var
  H: TFormHook;
begin
  if (csDesigning in L.ComponentState) then exit;
  H := HookFor (OwnerFormOf (L), true);
  if (assigned (H)) and (H.FToolbars.IndexOf (L) < 0) then H.FToolbars.Add (L);
end;


procedure   SelectNCUpdateRgn (Wnd: HWND; DC: HDC; Rgn: HRGN);
var
  R: TRect;
  NewRgn: HRGN;
begin
  if (Rgn <> 0) and (Rgn <> 1) then begin
    GetWindowRect (Wnd, R);
    NewRgn := CreateRectRgn (0, 0, 0, 0);
    try
      if (CombineRgn (NewRgn, Rgn, 0, RGN_COPY) <> ERROR) then begin
        OffsetRgn (NewRgn, -R.Left, -R.Top);
        SelectClipRgn (DC, NewRgn);
      end;
    finally
      DeleteObject (NewRgn);
    end;
  end;
end;


function    ScreenWorkArea (const P: TPoint): TRect;
var
  M: HMONITOR;
  MI: TMonitorInfo;
begin
  M := MonitorFromPoint (P, MONITOR_DEFAULTTONEAREST);
  MI.cbSize := SizeOf (MI);
  if (M <> 0) and (GetMonitorInfo (M, @MI)) then begin
    result := MI.rcWork;
  end else begin
    SystemParametersInfo (SPI_GETWORKAREA, 0, @result, 0);
  end;
end;


function    KeyboardCuesOn: Boolean;
begin
  result := GetSystemParametersInfoBool (SPI_GETKEYBOARDCUES, true);
end;


procedure   MenuSound (const Name: String);
begin
  PlaySound (PChar(Name), 0, SND_ALIAS or SND_ASYNC or SND_NODEFAULT or SND_NOSTOP);
end;


// Text for bar buttons: without trailing "..." and ':'
function    ToolbarCaption (const S: String): String;
begin
  result := S;
  if (Copy (result, Length (result) - 2, 3) = '...') then begin
    SetLength (result, Length (result) - 3);
  end else if (Length (result) > 0) and (result[Length (result)] = ':') then begin
    SetLength (result, Length (result) - 1);
  end;
end;


function    IsImageShown (E: TToolbarElement; const A: TElementView): Boolean;
begin
  result := (E.ImageIndex >= 0) and assigned (A.ToolbarImages) and (E.ImageIndex < A.ToolbarImages.Count) and
            (E.DisplayMode in [anStandard, anImageAndText, anImageOnly]);
end;


function    TextShown (E: TToolbarElement; const A: TElementView): Boolean;
begin
  if (E.Caption = '') then begin
    result := false;
  end else if (not A.IsToolbarStyle) then begin
    result := true;
  end else if (A.ImageOverText) then begin
    // image above text always shows the text
    result := true;
  end else begin
    case E.DisplayMode of
      anImageAndText, anTextOnly: result := true;
      anImageOnly: result := not IsImageShown (E, A);
    else
      result := not IsImageShown (E, A);
    end;
  end;
end;


function    ImageExtent (const A: TElementView): TSize;
begin
  if (assigned (A.ToolbarImages)) then begin
    result.cx := A.ToolbarImages.Width;
    result.cy := A.ToolbarImages.Height;
  end else begin
    result.cx := 0;
    result.cy := 0;
  end;
end;


procedure   SelectFont (Canvas: TCanvas; E: TToolbarElement);
begin
  Canvas.Font := ToolbarFont;
  if (E.BoldText) then Canvas.Font.Style := Canvas.Font.Style + [fsBold];
end;


function    CalcTextSize (Canvas: TCanvas; const Text: String; Flags: Cardinal): TSize;
var
  R: TRect;
begin
  if (Text = '') then begin
    result.cx := 0;
    result.cy := 0;
    exit;
  end;
  R := Rect (0, 0, 1, 0);
  DrawText (Canvas.Handle, PChar(Text), Length (Text), R, Flags or DT_CALCRECT);
  result.cx := R.Right;
  result.cy := R.Bottom;
end;


// Width of the image strip on the left in menus (like GetPopupMargin in TBX.pas)
function    CalculatePopupBorder (ToolbarImages: TCustomImageList): Integer;
var
  Sz: TSize;
  TM: TTextMetric;
  H, M2: Integer;
  Margins: TTBXMargins;
begin
  Sz.cx := 0;
  Sz.cy := 0;
  if (assigned (ToolbarImages)) then begin
    Sz.cx := ToolbarImages.Width;
    Sz.cy := ToolbarImages.Height;
  end;
  if (Sz.cx = 0) or (Sz.cy = 0) then begin
    Sz.cx := 16;
    Sz.cy := 16;
  end;
  StockBitmap1.Canvas.Font := ToolbarFont;
  GetTextMetrics (StockBitmap1.Canvas.Handle, TM);
  CurrentTheme.GetMargins (MID_MENUITEM, Margins);
  M2 := Margins.TopHeight + Margins.BottomHeight;
  result := TM.tmHeight + TM.tmExternalLeading + M2;
  H := Sz.cy + M2;
  if (H > result) then result := H;
  result := (Sz.cx + M2) * result div H;
end;


function    MeasureElement (Canvas: TCanvas; E: TToolbarElement; const A: TElementView): TPoint;
var
  Img: TSize;
  ImageOnTop, WithText: Boolean;
  S: String;
  Flags: Cardinal;
  T: TSize;
  TM: TTextMetric;
  Margins: TTBXMargins;
  SZ: Integer;
begin

  if (E.IsSeparator) then begin
    if (A.IsToolbarStyle) then SZ := CurrentTheme.TlbrSeparatorSize else SZ := CurrentTheme.MenuSeparatorSize;
    // if the theme gives no value: menus 10 (Office 2000), bars 6
    if (SZ < 0) then begin
      if (A.IsToolbarStyle) then SZ := 6 else SZ := 10;
    end;
    if (A.IsToolbarStyle) then result := Point (SZ, SZ) else result := Point (0, SZ);
    exit;
  end;

  if (IsImageShown (E, A)) then Img := ImageExtent (A) else Img := ImageExtent (A);
  if (Img.cx <= 0) or (Img.cy <= 0) then begin
    Img.cx := 0;
    Img.cy := 0;
  end;

  ImageOnTop := A.ImageOverText;
  WithText := TextShown (E, A);
  SelectFont (Canvas, E);

  if (WithText) then begin
    if (A.IsToolbarStyle) then S := ToolbarCaption (E.Caption) else S := E.Caption;
    if (not A.IsToolbarStyle) then Flags := DT_SINGLELINE else Flags := 0;
    T := CalcTextSize (Canvas, S, Flags);
  end else begin
    T.cx := 0;
    T.cy := 0;
  end;

  if (A.IsToolbarStyle) then begin

    result.X := 6;
    result.Y := 6;
    if (WithText) then begin
      inc (result.X, T.cx);
      inc (result.Y, T.cy);
      inc (result.X, 4);
    end;
    if (IsImageShown (E, A)) and (Img.cx > 0) then begin
      if (not ImageOnTop) then begin
        inc (result.X, Img.cx + 1);
        if (result.Y < Img.cy + 6) then result.Y := Img.cy + 6;
      end else begin
        inc (result.Y, Img.cy);
        if (result.X < Img.cx + 7) then result.X := Img.cx + 7;
      end;
    end;

  end else begin

    GetTextMetrics (Canvas.Handle, TM);
    inc (T.cy, TM.tmExternalLeading);
    result.X := T.cx;
    result.Y := T.cy;
    if (Img.cy = 0) then Img.cy := 16;
    if (result.Y < Img.cy) then result.Y := Img.cy;
    CurrentTheme.GetMargins (MID_MENUITEM, Margins);
    inc (result.X, Margins.LeftWidth + Margins.RightWidth);
    inc (result.Y, Margins.TopHeight + Margins.BottomHeight);
    inc (result.X, A.PopupBorder + CurrentTheme.MenuImageTextSpace +
                   CurrentTheme.MenuLeftCaptionMargin + CurrentTheme.MenuRightCaptionMargin);
    S := E.ShortcutLabel;
    if (S <> '') then inc (result.X, (result.Y - 6) + GetTextWidth (Canvas.Handle, S, true));
    inc (result.X, result.Y);

  end;

end;


procedure   DrawSeparatorLine (Canvas: TCanvas; const A: TElementView; const R: TRect);
var
  Info: TTBXItemInfo;
  IsHorizontal: Boolean;
begin
  FillChar (Info, SizeOf (Info), 0);
  Info.ViewType := A.ViewType;
  if (A.IsToolbarStyle) then Info.ItemOptions := IO_TOOLBARSTYLE;
  Info.Enabled := true;
  if (not A.IsToolbarStyle) then Info.PopupMargin := A.PopupBorder;
  IsHorizontal := not A.IsToolbarStyle;
  CurrentTheme.PaintSeparator (Canvas, R, Info, IsHorizontal, false);
end;


// Draws an item (like TTBXItemViewer.Paint in TBX.pas, without split buttons).
// The area starts at (0,0); PaintElement moves the origin beforehand.
procedure   DrawElementInner (Canvas: TCanvas; E: TToolbarElement; const A: TElementView;
                                  const AreaRect: TRect; IsHot, KeyboardHot, IsPressed, PopupOpen: Boolean);
const
  CToolbarStyle: array [Boolean] of Integer = (0, IO_TOOLBARSTYLE);
  CSubmenuItem: array [Boolean] of Integer = (0, IO_SUBMENUITEM);
  CAppActive: array [Boolean] of Integer = (0, IO_APPACTIVE);
var
  Info: TTBXItemInfo;
  R, TextR, ImageR: TRect;
  Img: TSize;
  HasImage, WithText, ImageOnTop: Boolean;
  S: String;
  Flags: Cardinal;
  T: TSize;
  TM: TTextMetric;
  Margins: TTBXMargins;
  C: TColor;
begin

  if (E.IsSeparator) then begin
    DrawSeparatorLine (Canvas, A, AreaRect);
    exit;
  end;

  HasImage := IsImageShown (E, A);
  if (HasImage) then Img := ImageExtent (A) else begin
    Img.cx := 0;
    Img.cy := 0;
  end;
  if (Img.cx <= 0) or (Img.cy <= 0) then begin
    HasImage := false;
    Img.cx := 0;
    Img.cy := 0;
  end;

  FillChar (Info, SizeOf (Info), 0);
  Info.ViewType := A.ViewType;
  Info.ItemOptions := CToolbarStyle[A.IsToolbarStyle] or CSubmenuItem[E.IsSubmenu and (E.Count > 0) or E.IsSubmenu] or
                      CAppActive[Application.Active];
  Info.Enabled := E.Enabled;
  Info.Pushed := IsPressed;
  Info.Selected := E.Checked;
  Info.ImageShown := HasImage;
  Info.ImageWidth := Img.cx;
  Info.ImageHeight := Img.cy;
  // as in TBX: disabled items only show the keyboard selection
  if (IsHot) or (KeyboardHot) then begin
    if (not Info.Enabled) and (not IsHot) then begin
      Info.HoverKind := hkKeyboardHover;
    end else if (Info.Enabled) then begin
      Info.HoverKind := hkMouseHover;
    end else begin
      Info.HoverKind := hkNone;
    end;
  end else begin
    Info.HoverKind := hkNone;
  end;
  Info.IsPopupParent := A.IsToolbarStyle and PopupOpen;
  Info.PopupMargin := A.PopupBorder;

  ImageOnTop := A.ImageOverText;

  SelectFont (Canvas, E);
  Canvas.Font.Color := CurrentTheme.GetItemTextColor (Info);
  C := Canvas.Font.Color;

  if (A.HidePrefix) then Flags := DT_HIDEPREFIX else Flags := 0;
  WithText := TextShown (E, A);
  if (WithText) then begin
    if (A.IsToolbarStyle) then S := ToolbarCaption (E.Caption) else S := E.Caption;
    if (not A.IsToolbarStyle) then Flags := Flags or DT_SINGLELINE;
    T := CalcTextSize (Canvas, S, Flags);
  end else begin
    S := '';
    T.cx := 0;
    T.cy := 0;
  end;

  R := AreaRect;
  if (A.IsToolbarStyle) then begin
    CurrentTheme.GetMargins (MID_TOOLBARITEM, Margins);
    CurrentTheme.PaintButton (Canvas, R, Info);
  end else begin
    CurrentTheme.GetMargins (MID_MENUITEM, Margins);
    CurrentTheme.PaintMenuItem (Canvas, R, Info);
  end;
  inc (R.Left, Margins.LeftWidth);
  dec (R.Right, Margins.RightWidth);
  inc (R.Top, Margins.TopHeight);
  dec (R.Bottom, Margins.BottomHeight);

  // Text
  if (WithText) then begin
    if (A.IsToolbarStyle) then begin
      TextR := R;
      Flags := Flags or DT_CENTER or DT_VCENTER;
      if (HasImage) then begin
        if (not ImageOnTop) then begin
          inc (TextR.Left, Img.cx + 3);
          TextR.Top := (TextR.Top + TextR.Bottom - T.cy) div 2;
          TextR.Bottom := TextR.Top + T.cy;
          TextR.Left := (TextR.Left + TextR.Right - T.cx) div 2;
          TextR.Right := TextR.Left + T.cx;
          Flags := Flags and not DT_CENTER;
        end else begin
          inc (TextR.Top, Img.cy + 1);
          TextR.Top := (TextR.Top + TextR.Bottom - T.cy) div 2;
          TextR.Bottom := TextR.Top + T.cy;
          TextR.Left := (TextR.Left + TextR.Right - T.cx) div 2;
          TextR.Right := TextR.Left + T.cx;
          Flags := Flags and not DT_VCENTER;
        end;
      end else begin
        TextR.Left := (TextR.Left + R.Right - T.cx) div 2;
        TextR.Top := (TextR.Top + R.Bottom - T.cy) div 2;
        TextR.Right := TextR.Left + T.cx;
        TextR.Bottom := TextR.Top + T.cy;
      end;
      Canvas.Font.Color := C;
      CurrentTheme.PaintCaption (Canvas, TextR, Info, S, Flags, false);
    end else begin
      Flags := DT_LEFT or DT_VCENTER or Flags;
      GetTextMetrics (Canvas.Handle, TM);
      TextR := R;
      inc (TextR.Left, Info.PopupMargin + CurrentTheme.MenuImageTextSpace + CurrentTheme.MenuLeftCaptionMargin);
      if ((TextR.Bottom - TextR.Top) - (TM.tmHeight + TM.tmExternalLeading) = Margins.BottomHeight) then dec (TextR.Bottom);
      inc (TextR.Top, TM.tmExternalLeading);
      TextR.Right := TextR.Left + T.cx;
      Canvas.Font.Color := C;
      CurrentTheme.PaintCaption (Canvas, TextR, Info, S, Flags, false);
    end;
  end;

  // Shortcut (menus only)
  if (not A.IsToolbarStyle) then begin
    S := E.ShortcutLabel;
    if (S <> '') then begin
      GetTextMetrics (Canvas.Handle, TM);
      TextR := R;
      TextR.Left := TextR.Right - (TextR.Bottom - TextR.Top) - GetTextWidth (Canvas.Handle, S, true);
      if ((TextR.Bottom - TextR.Top) - (TM.tmHeight + TM.tmExternalLeading) = Margins.BottomHeight) then dec (TextR.Bottom);
      inc (TextR.Top, TM.tmExternalLeading);
      Canvas.Font.Color := C;
      CurrentTheme.PaintCaption (Canvas, TextR, Info, S, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX, false);
    end;
  end;

  // Image or check mark
  if (HasImage) or ((not A.IsToolbarStyle) and E.Checked) then begin
    ImageR := R;
    if (A.IsToolbarStyle) then begin
      if (not ImageOnTop) then begin
        ImageR.Right := ImageR.Left + Img.cx + Margins.LeftWidth;
      end else begin
        ImageR.Top := (ImageR.Top + ImageR.Bottom - Img.cy - 2 - T.cy) div 2;
        ImageR.Bottom := ImageR.Top + Img.cy + Margins.TopHeight;
      end;
    end else begin
      ImageR.Right := ImageR.Left + AreaRect.Bottom - AreaRect.Top;
    end;
    if (HasImage) then begin
      ImageR.Left := ImageR.Left + ((ImageR.Right - ImageR.Left) - Img.cx) div 2;
      ImageR.Top := ImageR.Top + ((ImageR.Bottom - ImageR.Top) - Img.cy) div 2;
      ImageR.Right := ImageR.Left + Img.cx;
      ImageR.Bottom := ImageR.Top + Img.cy;
      CurrentTheme.PaintImage (Canvas, ImageR, Info, A.ToolbarImages, E.ImageIndex);
    end else begin
      if (E.RadioItem) then Info.ItemOptions := Info.ItemOptions or IO_RADIO;
      CurrentTheme.PaintCheckMark (Canvas, ImageR, Info);
    end;
  end;

end;


// Origin at the top left corner of the item,
// clipped to the item, brush origin adjusted. The themes expect
// rectangles starting at (0,0) and partly calculate without R.Left/R.Top.
procedure   PaintElement (Canvas: TCanvas; E: TToolbarElement; const A: TElementView;
                             const AreaRect: TRect; IsHot, KeyboardHot, IsPressed, PopupOpen: Boolean);
var
  DC: HDC;
  Marker: Integer;
  Org: TPoint;
begin
  if (IsRectEmpty (AreaRect)) then exit;
  Canvas.Refresh;
  DC := Canvas.Handle;
  Marker := SaveDC (DC);
  try
    IntersectClipRect (DC, AreaRect.Left, AreaRect.Top, AreaRect.Right, AreaRect.Bottom);
    GetWindowOrgEx (DC, Org);
    SetWindowOrgEx (DC, Org.X - AreaRect.Left, Org.Y - AreaRect.Top, nil);
    if (GetWindowOrgEx (DC, Org)) then SetBrushOrgEx (DC, -Org.X, -Org.Y, nil);
    DrawElementInner (Canvas, E, A, Rect (0, 0, AreaRect.Right - AreaRect.Left, AreaRect.Bottom - AreaRect.Top),
                          IsHot, KeyboardHot, IsPressed, PopupOpen);
  finally
    Canvas.Refresh;
    RestoreDC (DC, Marker);
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TToolbarElementActionLink
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TToolbarElementActionLink.AssignClient (AClient: TObject);
begin
  FClient := AClient as TToolbarElement;
end;


function    TToolbarElementActionLink.IsAutoCheckLinked: Boolean;
begin
  result := FClient.AutoCheck = (Action as TCustomAction).AutoCheck;
end;


function    TToolbarElementActionLink.IsCaptionLinked: Boolean;
begin
  result := inherited IsCaptionLinked and (FClient.Caption = (Action as TCustomAction).Caption);
end;


function    TToolbarElementActionLink.IsCheckedLinked: Boolean;
begin
  result := inherited IsCheckedLinked and (FClient.Checked = (Action as TCustomAction).Checked);
end;


function    TToolbarElementActionLink.IsEnabledLinked: Boolean;
begin
  result := inherited IsEnabledLinked and (FClient.Enabled = (Action as TCustomAction).Enabled);
end;


function    TToolbarElementActionLink.IsGroupIndexLinked: Boolean;
begin
  result := inherited IsGroupIndexLinked and (FClient.GroupIndex = (Action as TCustomAction).GroupIndex);
end;


function    TToolbarElementActionLink.IsHintLinked: Boolean;
begin
  result := inherited IsHintLinked and (FClient.Hint = (Action as TCustomAction).Hint);
end;


function    TToolbarElementActionLink.IsImageIndexLinked: Boolean;
begin
  result := inherited IsImageIndexLinked and (FClient.ImageIndex = (Action as TCustomAction).ImageIndex);
end;


function    TToolbarElementActionLink.IsShortCutLinked: Boolean;
begin
  result := inherited IsShortCutLinked and (FClient.ShortCut = (Action as TCustomAction).ShortCut);
end;


function    TToolbarElementActionLink.IsVisibleLinked: Boolean;
begin
  result := inherited IsVisibleLinked and (FClient.Visible = (Action as TCustomAction).Visible);
end;


function    TToolbarElementActionLink.IsOnExecuteLinked: Boolean;
begin
  result := inherited IsOnExecuteLinked and (@FClient.OnClick = @Action.OnExecute);
end;


procedure   TToolbarElementActionLink.SetAutoCheck (Value: Boolean);
begin
  if (IsAutoCheckLinked) then FClient.AutoCheck := Value;
end;


procedure   TToolbarElementActionLink.SetCaption (const Value: String);
begin
  if (IsCaptionLinked) then FClient.Caption := Value;
end;


procedure   TToolbarElementActionLink.SetChecked (Value: Boolean);
begin
  if (IsCheckedLinked) then FClient.Checked := Value;
end;


procedure   TToolbarElementActionLink.SetEnabled (Value: Boolean);
begin
  if (IsEnabledLinked) then FClient.Enabled := Value;
end;


procedure   TToolbarElementActionLink.SetGroupIndex (Value: Integer);
begin
  if (IsGroupIndexLinked) then FClient.GroupIndex := Value;
end;


procedure   TToolbarElementActionLink.SetHint (const Value: String);
begin
  if (IsHintLinked) then FClient.Hint := Value;
end;


procedure   TToolbarElementActionLink.SetImageIndex (Value: Integer);
begin
  if (IsImageIndexLinked) then FClient.ImageIndex := Value;
end;


procedure   TToolbarElementActionLink.SetShortCut (Value: TShortCut);
begin
  if (IsShortCutLinked) then FClient.ShortCut := Value;
end;


procedure   TToolbarElementActionLink.SetVisible (Value: Boolean);
begin
  if (IsVisibleLinked) then FClient.Visible := Value;
end;


procedure   TToolbarElementActionLink.SetOnExecute (Value: TNotifyEvent);
begin
  if (IsOnExecuteLinked) then FClient.OnClick := Value;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TToolbarElement
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TToolbarElement.Create (AOwner: TComponent);
begin
  inherited Create (AOwner);
  FEnabled := true;
  FVisible := true;
  FImageIndex := -1;
  FChildren := TList.Create;
end;


destructor  TToolbarElement.Destroy;
var
  I: Integer;
  K: TToolbarElement;
begin
  if (assigned (ActiveLoop)) then ActiveLoop.ElementRemoved (self);
  if (assigned (FParentElement)) then FParentElement.Remove (self);
  // Children belong to the item, even if the form owns them
  for I := FChildren.Count - 1 downto 0 do begin
    K := TToolbarElement(FChildren[I]);
    K.FParentElement := nil;
    FChildren.Delete (I);
    K.Free;
  end;
  FreeAndNil (FChildren);
  FreeAndNil (FActionLink);
  inherited Destroy;
end;


function    TToolbarElement.GetCount: Integer;
begin
  result := FChildren.Count;
end;


function    TToolbarElement.GetItem (Index: Integer): TToolbarElement;
begin
  result := TToolbarElement(FChildren[Index]);
end;


procedure   TToolbarElement.Add (Element: TToolbarElement);
begin
  Insert (FChildren.Count, Element);
end;


procedure   TToolbarElement.Insert (Index: Integer; Element: TToolbarElement);
begin
  if (Element.FParentElement = self) then exit;
  if (assigned (Element.FParentElement)) then Element.FParentElement.Remove (Element);
  if (Index < 0) then Index := 0;
  if (Index > FChildren.Count) then Index := FChildren.Count;
  FChildren.Insert (Index, Element);
  Element.FParentElement := self;
  SignalChange (true);
end;


procedure   TToolbarElement.Remove (Element: TToolbarElement);
var
  L: TPaxonToolbar;
begin
  if (FChildren.Remove (Element) >= 0) then begin
    Element.FParentElement := nil;
    L := OwnerToolbar;
    if (assigned (L)) then begin
      if (L.FHotElement = Element) then L.FHotElement := nil;
      if (L.FPressedElement = Element) then L.FPressedElement := nil;
      if (L.FKeyboard = Element) then L.FKeyboard := nil;
      if (L.FOpenElement = Element) then L.FOpenElement := nil;
    end;
    SignalChange (true);
  end;
end;


procedure   TToolbarElement.Clear;
var
  I: Integer;
begin
  for I := FChildren.Count - 1 downto 0 do TToolbarElement(FChildren[I]).Free;
end;


function    TToolbarElement.IndexOf (Element: TToolbarElement): Integer;
begin
  result := FChildren.IndexOf (Element);
end;


function    TToolbarElement.TreeRoot: TToolbarElement;
begin
  result := self;
  while (assigned (result.FParentElement)) do result := result.FParentElement;
end;


function    TToolbarElement.OwnerToolbar: TPaxonToolbar;
var
  W: TToolbarElement;
begin
  W := TreeRoot;
  if (W.FRootOf is TPaxonToolbar) then result := TPaxonToolbar(W.FRootOf) else result := nil;
end;


function    TToolbarElement.EffectiveImages: TCustomImageList;
var
  E: TToolbarElement;
begin
  // Images of the parent items, otherwise of the bar or popup menu
  result := nil;
  E := FParentElement;
  while (assigned (E)) do begin
    if (assigned (E.FToolbarImages)) then begin
      result := E.FToolbarImages;
      exit;
    end;
    if (E.FRootOf is TPaxonToolbar) then begin
      result := TPaxonToolbar(E.FRootOf).Images;
      exit;
    end;
    if (E.FRootOf is TToolbarPopupMenu) then begin
      result := TToolbarPopupMenu(E.FRootOf).Images;
      exit;
    end;
    E := E.FParentElement;
  end;
end;


function    TToolbarElement.ShortcutLabel: String;
begin
  if (FShortCut <> 0) then result := ShortCutToText (FShortCut) else result := '';
end;


function    TToolbarElement.AcceleratorChar: Char;
var
  U: Integer;
  S: String;
begin
  S := WithoutPrefix (FCaption, U);
  if (U > 0) then result := AnsiUpperCase (S[U])[1] else result := #0;
end;


function    TToolbarElement.IsSubmenu: Boolean;
begin
  result := false;
end;


function    TToolbarElement.IsSeparator: Boolean;
begin
  result := false;
end;


procedure   TToolbarElement.SignalChange (ArrangeElements: Boolean);
var
  L: TPaxonToolbar;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then exit;
  L := OwnerToolbar;
  if (assigned (L)) then L.ElementChanged (self, ArrangeElements);
  if (assigned (ActiveLoop)) then ActiveLoop.ElementChanged;
end;


procedure   TToolbarElement.DeselectGroup;
var
  I: Integer;
  E: TToolbarElement;
begin
  if (FGroupIndex = 0) or (not assigned (FParentElement)) then exit;
  for I := 0 to FParentElement.Count - 1 do begin
    E := FParentElement[I];
    if (E <> self) and (E.FGroupIndex = FGroupIndex) and (E.FChecked) then E.Checked := false;
  end;
end;


procedure   TToolbarElement.Click;
begin
  if (not FEnabled) then exit;
  if (FAutoCheck) and not (assigned (FActionLink) and (FActionLink.Action is TCustomAction) and
                           TCustomAction(FActionLink.Action).AutoCheck) then begin
    if (FGroupIndex <> 0) then Checked := true else Checked := not FChecked;
  end;
  if (assigned (FOnClick)) and ((Action = nil) or (@FOnClick <> @Action.OnExecute)) then begin
    FOnClick (self);
  end else if (not (csDesigning in ComponentState)) and (assigned (FActionLink)) then begin
    FActionLink.Execute (self);
  end else if (assigned (FOnClick)) then begin
    FOnClick (self);
  end;
end;


procedure   TToolbarElement.InitiateAction;
begin
  if (assigned (FActionLink)) then FActionLink.Update;
end;


function    TToolbarElement.GetAction: TBasicAction;
begin
  if (assigned (FActionLink)) then result := FActionLink.Action else result := nil;
end;


procedure   TToolbarElement.SetAction (Value: TBasicAction);
begin
  if (Value = nil) then begin
    FreeAndNil (FActionLink);
  end else begin
    if (FActionLink = nil) then FActionLink := TToolbarElementActionLink.Create (self);
    FActionLink.Action := Value;
    FActionLink.OnChange := DoActionChange;
    ActionChange (Value, csLoading in Value.ComponentState);
    Value.FreeNotification (self);
  end;
end;


procedure   TToolbarElement.DoActionChange (Sender: TObject);
begin
  if (Sender = Action) then ActionChange (Sender, false);
end;


procedure   TToolbarElement.ActionChange (Sender: TObject; CheckDefaults: Boolean);
begin
  if (Sender is TCustomAction) then with TCustomAction(Sender) do begin
    if (not CheckDefaults) or (self.AutoCheck = false) then self.AutoCheck := AutoCheck;
    if (not CheckDefaults) or (self.Caption = '') then self.Caption := Caption;
    if (not CheckDefaults) or (self.Checked = false) then self.Checked := Checked;
    if (not CheckDefaults) or (self.Enabled = true) then self.Enabled := Enabled;
    if (not CheckDefaults) or (self.GroupIndex = 0) then self.GroupIndex := GroupIndex;
    if (not CheckDefaults) or (self.Hint = '') then self.Hint := Hint;
    if (not CheckDefaults) or (self.ImageIndex = -1) then self.ImageIndex := ImageIndex;
    if (not CheckDefaults) or (self.ShortCut = scNone) then self.ShortCut := ShortCut;
    if (not CheckDefaults) or (self.Visible = true) then self.Visible := Visible;
    if (not CheckDefaults) or not assigned (self.OnClick) then self.OnClick := OnExecute;
  end;
end;


procedure   TToolbarElement.Notification (AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification (AComponent, Operation);
  if (Operation = opRemove) then begin
    if (AComponent = Action) then Action := nil;
    if (AComponent = FToolbarImages) then FToolbarImages := nil;
  end;
end;


function    TToolbarElement.IsAutoCheckStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsAutoCheckLinked;
end;


function    TToolbarElement.IsCaptionStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsCaptionLinked;
end;


function    TToolbarElement.IsCheckedStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsCheckedLinked;
end;


function    TToolbarElement.IsEnabledStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsEnabledLinked;
end;


function    TToolbarElement.IsHintStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsHintLinked;
end;


function    TToolbarElement.IsImageIndexStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsImageIndexLinked;
end;


function    TToolbarElement.IsOnClickStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsOnExecuteLinked;
end;


function    TToolbarElement.IsShortCutStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsShortCutLinked;
end;


function    TToolbarElement.IsVisibleStored: Boolean;
begin
  result := (FActionLink = nil) or not FActionLink.IsVisibleLinked;
end;


procedure   TToolbarElement.SetDisplayMode (Value: TToolbarDisplay);
begin
  if (FDisplayMode <> Value) then begin
    FDisplayMode := Value;
    SignalChange (true);
  end;
end;


procedure   TToolbarElement.SetToolbarImages (Value: TCustomImageList);
begin
  if (FToolbarImages <> Value) then begin
    FToolbarImages := Value;
    if (assigned (Value)) then Value.FreeNotification (self);
    SignalChange (true);
  end;
end;


procedure   TToolbarElement.SetCaption (const Value: String);
begin
  if (FCaption <> Value) then begin
    FCaption := Value;
    SignalChange (true);
  end;
end;


procedure   TToolbarElement.SetChecked (Value: Boolean);
begin
  if (FChecked <> Value) then begin
    FChecked := Value;
    if (Value) then DeselectGroup;
    SignalChange (false);
  end;
end;


procedure   TToolbarElement.SetEnabled (Value: Boolean);
begin
  if (FEnabled <> Value) then begin
    FEnabled := Value;
    SignalChange (false);
  end;
end;


procedure   TToolbarElement.SetBoldText (Value: Boolean);
begin
  if (FBoldText <> Value) then begin
    FBoldText := Value;
    SignalChange (true);
  end;
end;


procedure   TToolbarElement.SetGroupIndex (Value: Integer);
begin
  if (FGroupIndex <> Value) then begin
    FGroupIndex := Value;
    if (FChecked) then DeselectGroup;
  end;
end;


procedure   TToolbarElement.SetImageIndex (Value: TImageIndex);
begin
  if (FImageIndex <> Value) then begin
    FImageIndex := Value;
    SignalChange (true);
  end;
end;


procedure   TToolbarElement.SetRadioItem (Value: Boolean);
begin
  if (FRadioItem <> Value) then begin
    FRadioItem := Value;
    SignalChange (false);
  end;
end;


procedure   TToolbarElement.SetShortCut (Value: TShortCut);
begin
  if (FShortCut <> Value) then begin
    FShortCut := Value;
    SignalChange (false);
  end;
end;


procedure   TToolbarElement.SetVisible (Value: Boolean);
begin
  if (FVisible <> Value) then begin
    FVisible := Value;
    SignalChange (true);
  end;
end;


procedure   TToolbarElement.GetChildren (Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
begin
  for I := 0 to FChildren.Count - 1 do begin
    if (TToolbarElement(FChildren[I]).Owner = Root) then Proc (TToolbarElement(FChildren[I]));
  end;
end;


function    TToolbarElement.GetParentComponent: TComponent;
begin
  if (assigned (FParentElement)) then begin
    if (assigned (FParentElement.FRootOf)) then result := FParentElement.FRootOf else result := FParentElement;
  end else begin
    result := nil;
  end;
end;


function    TToolbarElement.HasParent: Boolean;
begin
  result := true;
end;


procedure   TToolbarElement.SetParentComponent (Value: TComponent);
begin
  if (assigned (FParentElement)) then FParentElement.Remove (self);
  if (Value is TPaxonToolbar) then begin
    TPaxonToolbar(Value).Items.Add (self);
  end else if (Value is TToolbarPopupMenu) then begin
    TToolbarPopupMenu(Value).Items.Add (self);
  end else if (Value is TToolbarElement) then begin
    TToolbarElement(Value).Add (self);
  end;
end;


procedure   TToolbarElement.SetChildOrder (Child: TComponent; Order: Integer);
var
  I: Integer;
begin
  I := FChildren.IndexOf (Child);
  if (I >= 0) and (Order >= 0) and (Order < FChildren.Count) then FChildren.Move (I, Order);
end;


function    TToolbarSubmenu.IsSubmenu: Boolean;
begin
  result := true;
end;


function    TToolbarSeparator.IsSeparator: Boolean;
begin
  result := true;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TToolbarDock
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TToolbarDock.Create (AOwner: TComponent);
begin
  inherited Create (AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls] - [csOpaque];
  FBackgroundOnToolbars := true;
  Color := clNone;
  Align := alTop;
  Height := 9;
  AddThemeNotification (self);
end;


destructor  TToolbarDock.Destroy;
begin
  RemoveThemeNotification (self);
  inherited Destroy;
end;


procedure   TToolbarDock.SetBackgroundOnToolbars (Value: Boolean);
begin
  if (FBackgroundOnToolbars <> Value) then begin
    FBackgroundOnToolbars := Value;
    if (HandleAllocated) then RedrawWindow (Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
  end;
end;


function    TToolbarDock.EffectiveColor: TColor;
begin
  if (Color <> clNone) then begin
    result := Color;
  end else if (assigned (Parent)) then begin
    result := GetEffectiveColor (Parent);
  end else begin
    result := clBtnFace;
  end;
end;


function    TToolbarDock.UsingBackground: Boolean;
begin
  result := (Color = clNone) and CurrentTheme.PaintDockBackground;
end;


procedure   TToolbarDock.DrawBackground (DC: HDC; const DrawRect: TRect);
var
  Canvas: TCanvas;
  R: TRect;
begin
  if (UsingBackground) then begin
    Canvas := TCanvas.Create;
    try
      Canvas.Handle := DC;
      R := BoundsRect;
      // The theme receives the position of the dock via PenPos (as in TBX)
      Canvas.MoveTo (Integer(PointToSmallPoint (R.TopLeft)), Integer(PointToSmallPoint (R.BottomRight)));
      CurrentTheme.PaintDock (Canvas, ClientRect, DrawRect, DP_TOP);
    finally
      Canvas.Handle := 0;
      Canvas.Free;
    end;
  end else begin
    FillRectEx (DC, DrawRect, EffectiveColor);
  end;
end;


procedure   TToolbarDock.WMEraseBkgnd (var Message: TWMEraseBkgnd);
begin
  DrawBackground (Message.DC, ClientRect);
  Message.Result := 1;
end;


procedure   TToolbarDock.Paint;
begin
  if (csDesigning in ComponentState) then begin
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Style := psDot;
    Canvas.Rectangle (ClientRect);
  end;
end;


procedure   TToolbarDock.WMMove (var Message: TWMMove);
begin
  inherited;
  // Background gradients depend on the position
  if (UsingBackground) and (HandleAllocated) then begin
    RedrawWindow (Handle, nil, 0, RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_FRAME);
  end;
end;


procedure   TToolbarDock.CMColorChanged (var Message: TMessage);
begin
  inherited;
  if (HandleAllocated) then RedrawWindow (Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
end;


procedure   TToolbarDock.TBMGetEffectiveColor (var Message: TMessage);
begin
  Message.WParam := EffectiveColor;
  Message.Result := 1;
end;


procedure   TToolbarDock.TBMThemeChange (var Message: TMessage);
begin
  if (Message.WParam = TSC_AFTERVIEWCHANGE) then begin
    ArrangeElements;
    if (HandleAllocated) then RedrawWindow (Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
  end;
end;


procedure   TToolbarDock.Loaded;
begin
  inherited Loaded;
  ArrangeElements;
end;


procedure   TToolbarDock.Resize;
begin
  inherited Resize;
  ArrangeElements;
  if (UsingBackground) and (HandleAllocated) then begin
    RedrawWindow (Handle, nil, 0, RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_FRAME);
  end;
end;


procedure   TToolbarDock.AlignControls (AControl: TControl; var Rect: TRect);
begin
  // The bars are arranged by ArrangeElements, not by the VCL
  ArrangeElements;
end;


function    TToolbarDock.ToolbarCount: Integer;
var
  I: Integer;
begin
  result := 0;
  for I := 0 to ControlCount - 1 do begin
    if (Controls[I] is TPaxonToolbar) and (Controls[I].Visible) then inc (result);
  end;
end;


// Rows by DockRow one below the other; within a row the bars in component order
// from the left. If there is not enough space, bars are shortened down to their minimum length; a
// stretched bar (menu bar) fills the rest of its row.
procedure   TToolbarDock.ArrangeElements;
type
  TEntry = record
    L: TPaxonToolbar;
    RowNo, Pos, LengthValue, MinLen: Integer;
  end;
var
  E: array of TEntry;
  RowNumbers: array of Integer;
  RowNo: array of Integer;     // indices into E for the current row
  N, I, J, K, Across, Thickness, P, RemainingSpace, Extra, D: Integer;
begin

  if (FArranging) or (csLoading in ComponentState) or (csDestroying in ComponentState) then exit;
  if (not assigned (Parent)) then exit;
  FArranging := true;
  try

    N := 0;
    SetLength (E, ControlCount);
    for I := 0 to ControlCount - 1 do begin
      if (Controls[I] is TPaxonToolbar) and ((Controls[I].Visible) or (csDesigning in ComponentState)) then begin
        E[N].L := TPaxonToolbar(Controls[I]);
        E[N].RowNo := E[N].L.FDockRow;
        E[N].LengthValue := E[N].L.ContentSize (0).X;
        E[N].MinLen := E[N].L.MinimumLength;
        if (E[N].MinLen > E[N].LengthValue) then E[N].MinLen := E[N].LengthValue;
        inc (N);
      end;
    end;
    SetLength (E, N);

    // make row numbers contiguous
    SetLength (RowNumbers, 0);
    for I := 0 to N - 1 do begin
      K := 0;
      while (K < Length (RowNumbers)) and (RowNumbers[K] < E[I].RowNo) do inc (K);
      if (K >= Length (RowNumbers)) or (RowNumbers[K] <> E[I].RowNo) then begin
        SetLength (RowNumbers, Length (RowNumbers) + 1);
        for J := High (RowNumbers) downto K + 1 do RowNumbers[J] := RowNumbers[J - 1];
        RowNumbers[K] := E[I].RowNo;
      end;
    end;
    for I := 0 to N - 1 do begin
      for K := 0 to High (RowNumbers) do begin
        if (RowNumbers[K] = E[I].RowNo) then begin
          E[I].RowNo := K;
          E[I].L.FDockRow := K;
          break;
        end;
      end;
    end;

    Across := 0;
    for K := 0 to High (RowNumbers) do begin

      SetLength (RowNo, 0);
      for I := 0 to N - 1 do begin
        if (E[I].RowNo = K) then begin
          SetLength (RowNo, Length (RowNo) + 1);
          RowNo[High (RowNo)] := I;
        end;
      end;

      // from the left, shorten if necessary so that the following ones fit with their minimum length
      P := 0;
      for I := 0 to High (RowNo) do begin
        E[RowNo[I]].Pos := P;
        RemainingSpace := ClientWidth - P;
        for J := I + 1 to High (RowNo) do dec (RemainingSpace, E[RowNo[J]].MinLen);
        if (E[RowNo[I]].LengthValue > RemainingSpace) then begin
          if (RemainingSpace > E[RowNo[I]].MinLen) then
            E[RowNo[I]].LengthValue := RemainingSpace
          else
            E[RowNo[I]].LengthValue := E[RowNo[I]].MinLen;
        end;
        P := P + E[RowNo[I]].LengthValue;
      end;
      // stretched bar (menu bar) fills the rest of the row
      for I := 0 to High (RowNo) do begin
        if (E[RowNo[I]].L.Stretch) then begin
          Extra := ClientWidth - P;
          if (Extra > 0) then begin
            inc (E[RowNo[I]].LengthValue, Extra);
            for J := I + 1 to High (RowNo) do inc (E[RowNo[J]].Pos, Extra);
          end;
          break;
        end;
      end;

      // height of the row: the highest bar (wrapping bars get taller depending on the width)
      Thickness := 0;
      for I := 0 to High (RowNo) do begin
        D := E[RowNo[I]].L.ContentSize (E[RowNo[I]].LengthValue).Y;
        if (D > Thickness) then Thickness := D;
      end;
      for I := 0 to High (RowNo) do begin
        E[RowNo[I]].L.SetBounds (E[RowNo[I]].Pos, Across, E[RowNo[I]].LengthValue, Thickness);
      end;
      inc (Across, Thickness);

    end;

    if (not (csDesigning in ComponentState)) or (N > 0) then begin
      if (Height <> Across) then Height := Across;
    end;

  finally
    FArranging := false;
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TPaxonToolbar
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TPaxonToolbar.Create (AOwner: TComponent);
begin
  inherited Create (AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents, csDoubleClicks] - [csOpaque, csAcceptsControls];
  FRootElement := TToolbarElement.Create (nil);
  FRootElement.FRootOf := self;
  FAssignedImagesLink := TChangeLink.Create;
  FAssignedImagesLink.OnChange := ToolbarImagesChanged;
  FHiddenElements := TList.Create;
  FUpdateActions := true;
  Color := clNone;
  Width := 23;
  Height := 22;
  AddThemeNotification (self);
  RegisterToolbar (self);
end;


destructor  TPaxonToolbar.Destroy;
var
  H: TFormHook;
begin
  RemoveThemeNotification (self);
  H := HookFor (OwnerFormOf (self), false);
  if (assigned (H)) then H.FToolbars.Remove (self);
  FreeAndNil (FRootElement);
  FreeAndNil (FHiddenElements);
  FreeAndNil (FAssignedImagesLink);
  inherited Destroy;
end;


procedure   TPaxonToolbar.CreateParams (var Params: TCreateParams);
begin
  inherited CreateParams (Params);
  Params.WindowClass.style := Params.WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
end;


procedure   TPaxonToolbar.Loaded;
begin
  inherited Loaded;
  if (FShowElementHints) then ShowHint := true;
  RegisterToolbar (self);
  ArrangeElements;
end;


procedure   TPaxonToolbar.GetChildren (Proc: TGetChildProc; Root: TComponent);
begin
  FRootElement.GetChildren (Proc, Root);
end;


procedure   TPaxonToolbar.SetChildOrder (Child: TComponent; Order: Integer);
begin
  FRootElement.SetChildOrder (Child, Order);
end;


procedure   TPaxonToolbar.Notification (AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification (AComponent, Operation);
  if (Operation = opRemove) then begin
    if (AComponent = FToolbarImages) then Images := nil;
  end;
end;


procedure   TPaxonToolbar.SetParent (AParent: TWinControl);
var
  PrevDock: TToolbarDock;
begin
  if (Parent is TToolbarDock) then PrevDock := TToolbarDock(Parent) else PrevDock := nil;
  inherited SetParent (AParent);
  if (AParent is TToolbarDock) then Align := alNone;
  if (HandleAllocated) then begin
    SetWindowPos (Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOACTIVATE or SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE);
  end;
  if (assigned (PrevDock)) and (PrevDock <> AParent) and not (csDestroying in PrevDock.ComponentState) then begin
    PrevDock.ArrangeElements;
  end;
end;


function    TPaxonToolbar.GetCurrentDock: TToolbarDock;
begin
  if (Parent is TToolbarDock) then result := TToolbarDock(Parent) else result := nil;
end;


function    TPaxonToolbar.Docked: Boolean;
begin
  result := Parent is TToolbarDock;
end;


function    TPaxonToolbar.Embedded: Boolean;
begin
  result := not Docked;
end;


function    TPaxonToolbar.ViewType: Integer;
begin
  if (FMenuBar) then result := TVT_MENUBAR else result := TVT_NORMALTOOLBAR;
  if (Embedded) then result := result or TVT_EMBEDDED;
end;


function    TPaxonToolbar.EffectiveColor: TColor;
begin
  if (Color <> clNone) then begin
    result := Color;
  end else if (Embedded) and (assigned (Parent)) then begin
    result := GetEffectiveColor (Parent);
  end else begin
    result := CurrentTheme.GetViewColor (ViewType);
  end;
end;


function    TPaxonToolbar.NonClientBorders: TRect;
var
  B: TPoint;
begin
  result := Rect (0, 0, 0, 0);
  if (Docked) then begin
    CurrentTheme.GetViewBorder (ViewType, B);
    result := Rect (B.X, B.Y, B.X, B.Y);
  end;
end;


function    TPaxonToolbar.MinimumLength: Integer;
var
  R: TRect;
  M: TTBXMargins;
  I, A: Integer;
  G: TPoint;
  ElemView: TElementView;
begin
  R := NonClientBorders;
  CurrentTheme.GetViewMargins (ViewType, M);
  result := R.Left + R.Right + M.LeftWidth + M.RightWidth;
  if (FShrink = lkWrap) then begin
    // widest item
    FillChar (ElemView, SizeOf (ElemView), 0);
    ElemView.ViewType := ViewType;
    ElemView.IsToolbarStyle := true;
    ElemView.ImageOverText := FImageOverText;
    ElemView.ToolbarImages := FToolbarImages;
    A := 0;
    for I := 0 to FRootElement.Count - 1 do begin
      if (FRootElement[I].Visible) then begin
        G := MeasureElement (StockBitmap1.Canvas, FRootElement[I], ElemView);
        if (G.X > A) then A := G.X;
      end;
    end;
    inc (result, A);
  end else begin
    inc (result, ChevronSize);
  end;
end;


// Arranges the items for a client length (0: unlimited) and returns the
// size of the content in the client. ApplyLayout: apply the item positions.
function    TPaxonToolbar.CalculateLayout (LengthValue: Integer; ApplyLayout: Boolean): TPoint;
type
  TLayoutLine = record
    SpanStart, SpanEnd: Integer;      // indices into ItemList
    Thickness: Integer;
  end;
var
  ItemList: array of TToolbarElement;
  Gr: array of TPoint;
  Along, Pos: array of Integer;
  LayoutLines: array of TLayoutLine;
  TextLine: array of Integer;
  ElemView: TElementView;
  M: TTBXMargins;
  N, I, Z, Interior, P, Q, MaxL, Displayable, A, Dk: Integer;
  WrapRow, Chevron: Boolean;
  R: TRect;
begin

  FillChar (ElemView, SizeOf (ElemView), 0);
  ElemView.ViewType := ViewType;
  ElemView.IsToolbarStyle := true;
  ElemView.ImageOverText := FImageOverText;
  ElemView.ToolbarImages := FToolbarImages;
  CurrentTheme.GetViewMargins (ViewType, M);

  N := 0;
  SetLength (ItemList, FRootElement.Count);
  for I := 0 to FRootElement.Count - 1 do begin
    if (FRootElement[I].Visible) or (csDesigning in ComponentState) then begin
      ItemList[N] := FRootElement[I];
      inc (N);
    end;
  end;
  SetLength (ItemList, N);
  SetLength (Gr, N);
  SetLength (Along, N);
  SetLength (Pos, N);
  SetLength (TextLine, N);
  for I := 0 to N - 1 do begin
    Gr[I] := MeasureElement (StockBitmap1.Canvas, ItemList[I], ElemView);
    Along[I] := Gr[I].X;
  end;

  if (LengthValue > 0) then begin
    Interior := LengthValue - M.LeftWidth - M.RightWidth;
  end else begin
    Interior := MaxInt div 2;
  end;
  WrapRow := FShrink = lkWrap;
  Chevron := false;
  Displayable := N;

  // form lines or cut off items for the chevron
  SetLength (LayoutLines, 0);
  P := 0;
  for I := 0 to N - 1 do begin
    if (WrapRow) and (P > 0) and (P + Along[I] > Interior) then begin
      LayoutLines[High (LayoutLines)].SpanEnd := I - 1;
      P := 0;
    end;
    if (P = 0) then begin
      SetLength (LayoutLines, Length (LayoutLines) + 1);
      LayoutLines[High (LayoutLines)].SpanStart := I;
      LayoutLines[High (LayoutLines)].Thickness := 0;
    end;
    // separators at the start of a line (after a wrap) are dropped
    if (WrapRow) and (P = 0) and (ItemList[I].IsSeparator) and (Length (LayoutLines) > 1) then begin
      Along[I] := 0;
    end;
    Pos[I] := P;
    TextLine[I] := High (LayoutLines);
    inc (P, Along[I]);
  end;
  if (Length (LayoutLines) > 0) then LayoutLines[High (LayoutLines)].SpanEnd := N - 1;

  if (not WrapRow) and (N > 0) and (P > Interior) then begin
    Chevron := true;
    Displayable := 0;
    while (Displayable < N) and (Pos[Displayable] + Along[Displayable] <= Interior - ChevronSize) do inc (Displayable);
    while (Displayable > 0) and (ItemList[Displayable - 1].IsSeparator) do dec (Displayable);
  end;

  // thickness of the lines
  for I := 0 to Displayable - 1 do begin
    Dk := Gr[I].Y;
    if (ItemList[I].IsSeparator) then Dk := 0;
    if (Dk > LayoutLines[TextLine[I]].Thickness) then LayoutLines[TextLine[I]].Thickness := Dk;
  end;
  for Z := 0 to High (LayoutLines) do begin
    if (LayoutLines[Z].Thickness = 0) then begin
      StockBitmap1.Canvas.Font := ToolbarFont;
      LayoutLines[Z].Thickness := StockBitmap1.Canvas.TextHeight ('Ag') + 10;
    end;
  end;

  // extent
  MaxL := 0;
  for I := 0 to Displayable - 1 do begin
    if (Pos[I] + Along[I] > MaxL) then MaxL := Pos[I] + Along[I];
  end;
  if (Chevron) then inc (MaxL, ChevronSize);
  Q := 0;
  for Z := 0 to High (LayoutLines) do begin
    if (Displayable > 0) and (LayoutLines[Z].SpanStart < Displayable) then inc (Q, LayoutLines[Z].Thickness);
  end;
  if (N = 0) then begin
    StockBitmap1.Canvas.Font := ToolbarFont;
    Q := StockBitmap1.Canvas.TextHeight ('Ag') + 10;
    MaxL := 8;
  end;

  result.X := MaxL + M.LeftWidth + M.RightWidth;
  result.Y := Q + M.TopHeight + M.BottomHeight;

  if (ApplyLayout) then begin
    SetLength (FElementSlots, Displayable);
    FHiddenElements.Clear;
    for I := Displayable to N - 1 do FHiddenElements.Add (ItemList[I]);
    // line starts across the bar
    Q := 0;
    for Z := 0 to High (LayoutLines) do begin
      A := LayoutLines[Z].Thickness;
      // Without wrapping, the single line fills the whole thickness of the bar
      if (not WrapRow) and (Length (LayoutLines) = 1) then begin
        A := ClientHeight - M.TopHeight - M.BottomHeight;
        if (A < LayoutLines[Z].Thickness) then A := LayoutLines[Z].Thickness;
      end;
      for I := LayoutLines[Z].SpanStart to LayoutLines[Z].SpanEnd do begin
        if (I >= Displayable) then break;
        R := Rect (M.LeftWidth + Pos[I], M.TopHeight + Q, M.LeftWidth + Pos[I] + Along[I], M.TopHeight + Q + A);
        FElementSlots[I].Element := ItemList[I];
        FElementSlots[I].R := R;
      end;
      inc (Q, A);
    end;
    if (Chevron) then begin
      FChevron := Rect (ClientWidth - M.RightWidth - ChevronSize, M.TopHeight,
                        ClientWidth - M.RightWidth, ClientHeight - M.BottomHeight);
    end else begin
      FChevron := Rect (0, 0, 0, 0);
    end;
    FContentWidth := result.X;
    FContentHeight := result.Y;
  end;

end;


function    TPaxonToolbar.ContentSize (LengthValue: Integer): TPoint;
var
  R: TRect;
  L: Integer;
begin
  // Total size of the window (with border) for a window width (0: unlimited)
  R := NonClientBorders;
  L := LengthValue;
  if (L > 0) then begin
    dec (L, R.Left + R.Right);
    if (L < 1) then L := 1;
  end;
  result := CalculateLayout (L, false);
  inc (result.X, R.Left + R.Right);
  inc (result.Y, R.Top + R.Bottom);
end;


procedure   TPaxonToolbar.Resize;
begin
  inherited Resize;
  SetElements;
end;


procedure   TPaxonToolbar.SetElements;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then exit;
  CalculateLayout (ClientWidth, true);
  Invalidate;
end;


procedure   TPaxonToolbar.ArrangeElements;
var
  G: TPoint;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then exit;
  if (FUpdateLevel > 0) then begin
    FArrangeNeeded := true;
    exit;
  end;
  if (Docked) then begin
    CurrentDock.ArrangeElements;
  end else if (Parent = nil) and (ParentWindow = 0) then begin
    // not yet placed: nothing can be measured without a window
    exit;
  end else begin
    G := CalculateLayout (0, false);
    if (ClientWidth <> G.X) or (ClientHeight <> G.Y) then begin
      ClientWidth := G.X;
      ClientHeight := G.Y;
    end;
  end;
  SetElements;
end;


procedure   TPaxonToolbar.FitInto (WidthPx, FitHeight: Integer);
begin
  SetBounds (Left, Top, WidthPx, FitHeight);
  SetElements;
end;


procedure   TPaxonToolbar.BeginUpdate;
begin
  inc (FUpdateLevel);
end;


procedure   TPaxonToolbar.EndUpdate;
begin
  if (FUpdateLevel > 0) then dec (FUpdateLevel);
  if (FUpdateLevel = 0) and (FArrangeNeeded) then begin
    FArrangeNeeded := false;
    ArrangeElements;
  end;
end;


procedure   TPaxonToolbar.ElementChanged (Element: TToolbarElement; ArrangeElements: Boolean);
var
  R: TRect;
begin
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then exit;
  if (Element.Parent <> FRootElement) and (Element <> FRootElement) then exit;   // the bar does not see subitems
  if (ArrangeElements) then begin
    if (FUpdateLevel > 0) then FArrangeNeeded := true else self.ArrangeElements;
  end else if (HandleAllocated) then begin
    R := ElementRect (Element);
    if (IsRectEmpty (R)) then Invalidate else InvalidateRect (Handle, @R, false);
  end;
end;


procedure   TPaxonToolbar.ToolbarImagesChanged (Sender: TObject);
begin
  ArrangeElements;
end;


procedure   TPaxonToolbar.SetToolbarImages (Value: TCustomImageList);
begin
  if (FToolbarImages <> Value) then begin
    if (assigned (FToolbarImages)) then FToolbarImages.UnRegisterChanges (FAssignedImagesLink);
    FToolbarImages := Value;
    if (assigned (FToolbarImages)) then begin
      FToolbarImages.RegisterChanges (FAssignedImagesLink);
      FToolbarImages.FreeNotification (self);
    end;
    ArrangeElements;
  end;
end;


procedure   TPaxonToolbar.SetImageOverText (Value: Boolean);
begin
  if (FImageOverText <> Value) then begin
    FImageOverText := Value;
    ArrangeElements;
  end;
end;


procedure   TPaxonToolbar.SetDockRow (Value: Integer);
begin
  if (FDockRow <> Value) then begin
    FDockRow := Value;
    if (Docked) and not (csLoading in ComponentState) then CurrentDock.ArrangeElements;
  end;
end;


procedure   TPaxonToolbar.SetShowElementHints (Value: Boolean);
begin
  FShowElementHints := Value;
  if (Value) and not (csLoading in ComponentState) then ShowHint := true;
end;


procedure   TPaxonToolbar.SetShrink (Value: TToolbarShrink);
begin
  if (FShrink <> Value) then begin
    FShrink := Value;
    ArrangeElements;
  end;
end;


procedure   TPaxonToolbar.SetMenuBar (Value: Boolean);
begin
  if (FMenuBar <> Value) then begin
    FMenuBar := Value;
    // when set at runtime, the defaults of a menu bar apply
    if not (csLoading in ComponentState) then begin
      if (Value) then FShrink := lkWrap else FShrink := lkChevron;
      FProcessShortCuts := Value;
    end;
    if (HandleAllocated) then begin
      SetWindowPos (Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOACTIVATE or SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE);
    end;
    ArrangeElements;
  end;
end;


procedure   TPaxonToolbar.SetStretch (Value: Boolean);
begin
  if (FStretch <> Value) then begin
    FStretch := Value;
    ArrangeElements;
  end;
end;


procedure   TPaxonToolbar.CMVisibleChanged (var Message: TMessage);
begin
  inherited;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then exit;
  if (Docked) then CurrentDock.ArrangeElements;
end;


procedure   TPaxonToolbar.InitiateAction;
var
  I: Integer;
begin
  inherited InitiateAction;
  if (FUpdateActions) and not (csDesigning in ComponentState) then begin
    for I := 0 to FRootElement.Count - 1 do FRootElement[I].InitiateAction;
  end;
end;


function    TPaxonToolbar.ElementAt (const P: TPoint): TToolbarElement;
var
  I: Integer;
begin
  result := nil;
  for I := 0 to High (FElementSlots) do begin
    if (PtInRect (FElementSlots[I].R, P)) then begin
      result := FElementSlots[I].Element;
      if (result.IsSeparator) then result := nil;
      exit;
    end;
  end;
end;


function    TPaxonToolbar.ElementRect (Element: TToolbarElement): TRect;
var
  I: Integer;
begin
  for I := 0 to High (FElementSlots) do begin
    if (FElementSlots[I].Element = Element) then begin
      result := FElementSlots[I].R;
      exit;
    end;
  end;
  result := Rect (0, 0, 0, 0);
end;


// only have the area of one item redrawn (otherwise, without a buffer, the whole bar would flicker)
procedure   TPaxonToolbar.InvalidateElementArea (Element: TToolbarElement);
var
  R: TRect;
begin
  if (Element = nil) or (not HandleAllocated) then exit;
  R := ElementRect (Element);
  if (not IsRectEmpty (R)) then InvalidateRect (Handle, @R, false);
end;


function    TPaxonToolbar.ElementView: TElementView;
begin
  FillChar (result, SizeOf (result), 0);
  result.ViewType := ViewType;
  result.IsToolbarStyle := true;
  result.ImageOverText := FImageOverText;
  result.ToolbarImages := FToolbarImages;
  result.HidePrefix := FMenuBar and not KeyboardCuesOn and not FKeyboardChars;
end;


procedure   TPaxonToolbar.ToolbarInfo (var TI: TTBXToolbarInfo);
begin
  FillChar (TI, SizeOf (TI), 0);
  TI.WindowHandle := Handle;
  TI.ViewType := ViewType;
  // no grip (AllowDrag false): the bars cannot be moved
  TI.ClientWidth := ClientWidth;
  TI.ClientHeight := ClientHeight;
  TI.BorderStyle := bsSingle;
  CurrentTheme.GetViewBorder (TI.ViewType, TI.BorderSize);
  TI.Caption := PChar(Caption);
  TI.EffectiveColor := EffectiveColor;
end;


procedure   TPaxonToolbar.PaintToolbarBackground (DC: HDC);
var
  Dock: TToolbarDock;
  CR, DockR, DockPosR: TRect;
  Transparent: Boolean;
  Canvas: TCanvas;
begin
  CR := ClientRect;
  Transparent := Color = clNone;
  if (Docked) then begin
    Dock := CurrentDock;
    DockR := Dock.ClientRect;
    MapWindowPoints (Dock.Handle, Handle, DockR, 2);
    DockPosR := BoundsRect;
    Transparent := Transparent and Dock.UsingBackground and Dock.BackgroundOnToolbars and
                   not CurrentTheme.SolidToolbarClientArea;
    if (Transparent) then Dock.DrawBackground (DC, DockR);
  end else begin
    SetRectEmpty (DockR);
    DockPosR := CR;
    Transparent := Transparent and Embedded;
    if (Transparent) then DrawParentBackground (self, DC, CR);
  end;
  Canvas := TCanvas.Create;
  try
    Canvas.Handle := DC;
    Canvas.MoveTo (Integer(PointToSmallPoint (DockPosR.TopLeft)), Integer(PointToSmallPoint (DockPosR.BottomRight)));
    CurrentTheme.PaintBackgnd (Canvas, DockR, CR, CR, EffectiveColor, Transparent, ViewType);
  finally
    Canvas.Handle := 0;
    Canvas.Free;
  end;
end;


procedure   TPaxonToolbar.WMEraseBkgnd (var Message: TWMEraseBkgnd);
begin
  // everything in Paint
  Message.Result := 1;
end;


// Draws directly into the window, without a memory bitmap: only then can Windows render text and
// lines sharply at high resolution with GDI scaling (manifest). The items
// are drawn one by one, clipped. To avoid flicker, state changes only invalidate
// the affected items; Paint skips items outside the invalid region.
procedure   TPaxonToolbar.Paint;
var
  ElemView: TElementView;
  I: Integer;
  E: TToolbarElement;
  Info: TTBXItemInfo;
  IsHot, IsPressed: Boolean;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then exit;
  PaintToolbarBackground (Canvas.Handle);
  ElemView := ElementView;
  for I := 0 to High (FElementSlots) do begin
    if (not RectVisible (Canvas.Handle, FElementSlots[I].R)) then continue;
    E := FElementSlots[I].Element;
    // as in TBX: the item with an open popup is selected and pressed
    IsHot := ((E = FHotElement) and ((FPressedElement = nil) or (FPressedElement = E)) and (FOpenElement = nil)) or
             (E = FOpenElement);
    IsPressed := ((E = FPressedElement) and (E = FHotElement)) or (E = FOpenElement);
    PaintElement (Canvas, E, ElemView, FElementSlots[I].R, IsHot, (E = FKeyboard), IsPressed, (E = FOpenElement));
  end;
  if (not IsRectEmpty (FChevron)) then begin
    FillChar (Info, SizeOf (Info), 0);
    Info.ViewType := ViewType;
    Info.ItemOptions := IO_TOOLBARSTYLE;
    Info.Enabled := true;
    Info.Pushed := FChevronOpen;
    Info.IsPopupParent := FChevronOpen;
    if (FChevronHot) or (FChevronOpen) then Info.HoverKind := hkMouseHover;
    CurrentTheme.PaintChevron (Canvas, FChevron, Info);
  end;
end;


procedure   TPaxonToolbar.WMNCCalcSize (var Message: TWMNCCalcSize);
var
  R: TRect;
begin
  R := NonClientBorders;
  with Message.CalcSize_Params^.rgrc[0] do begin
    inc (Left, R.Left);
    inc (Top, R.Top);
    dec (Right, R.Right);
    dec (Bottom, R.Bottom);
  end;
  Message.Result := 0;
end;


procedure   TPaxonToolbar.DrawNC (Clip: HRGN);
var
  WndDC, DC: HDC;
  BufDCRec: TBufDCRec;
  R, R2: TRect;
  Canvas: TCanvas;
  TI: TTBXToolbarInfo;
  Dock: TToolbarDock;
begin
  if (not Docked) or (not HandleAllocated) then exit;
  Dock := CurrentDock;
  ToolbarInfo (TI);
  GetWindowRect (Handle, R);
  WndDC := GetWindowDC (Handle);
  try
    DC := CreateBufDC (WndDC, R.Right - R.Left, R.Bottom - R.Top, BufDCRec);
    try
      SelectNCUpdateRgn (Handle, WndDC, Clip);
      R2 := ClientRect;
      MapWindowPoints (Handle, 0, R2, 2);
      OffsetRect (R2, -R.Left, -R.Top);
      ExcludeClipRect (WndDC, R2.Left, R2.Top, R2.Right, R2.Bottom);
      OffsetRect (R, -R.Left, -R.Top);
      Canvas := TCanvas.Create;
      try
        Canvas.Handle := DC;
        if (CurrentTheme.SolidToolbarNCArea) then begin
          Canvas.Brush.Color := TI.EffectiveColor;
          Canvas.Brush.Style := bsSolid;
        end else if (Dock.UsingBackground) then begin
          Canvas.Brush.Color := TI.EffectiveColor;
          R2 := Dock.ClientRect;
          OffsetRect (R2, -Left, -Top);
          Dock.DrawBackground (DC, R2);
          if (Color = clNone) and (Dock.BackgroundOnToolbars) then Canvas.Brush.Style := bsClear;
        end else begin
          FillRectEx (DC, R, Dock.EffectiveColor);
          Canvas.Brush.Color := TI.EffectiveColor;
          Canvas.Brush.Style := bsSolid;
        end;
        CurrentTheme.PaintToolbarNCArea (Canvas, R, TI);
      finally
        Canvas.Handle := 0;
        Canvas.Free;
      end;
      BitBlt (WndDC, 0, 0, R.Right, R.Bottom, DC, 0, 0, SRCCOPY);
    finally
      DeleteBufDC (BufDCRec);
    end;
  finally
    ReleaseDC (Handle, WndDC);
  end;
end;


procedure   TPaxonToolbar.WMNCPaint (var Message: TMessage);
begin
  DrawNC (HRGN(Message.WParam));
  Message.Result := 0;
end;


procedure   TPaxonToolbar.WMNCHitTest (var Message: TWMNCHitTest);
var
  R: TRect;
begin
  // The border also delivers client mouse messages (coordinates are then negative)
  GetWindowRect (Handle, R);
  if (PtInRect (R, Point (Message.XPos, Message.YPos))) then Message.Result := HTCLIENT
  else inherited;
end;


procedure   TPaxonToolbar.CMHintShow (var Message: TCMHintShow);
var
  E: TToolbarElement;
begin
  with Message.HintInfo^ do begin
    E := ElementAt (CursorPos);
    if (assigned (E)) and (E.Hint <> '') and (FOpenElement = nil) then begin
      HintStr := GetShortHint (E.Hint);
      CursorRect := ElementRect (E);
      Message.Result := 0;
    end else begin
      Message.Result := 1;
    end;
  end;
end;


procedure   TPaxonToolbar.CMMouseLeave (var Message: TMessage);
begin
  inherited;
  if (FHotElement <> nil) or (FChevronHot) then begin
    InvalidateElementArea (FHotElement);
    if (FChevronHot) and (HandleAllocated) then InvalidateRect (Handle, @FChevron, false);
    FHotElement := nil;
    FChevronHot := false;
  end;
end;


procedure   TPaxonToolbar.MouseMove (Shift: TShiftState; X, Y: Integer);
var
  E: TToolbarElement;
  C: Boolean;
begin
  inherited MouseMove (Shift, X, Y);
  E := ElementAt (Point (X, Y));
  C := PtInRect (FChevron, Point (X, Y));
  if (E <> FHotElement) or (C <> FChevronHot) then begin
    if (E <> FHotElement) then begin
      InvalidateElementArea (FHotElement);
      InvalidateElementArea (E);
    end;
    if (C <> FChevronHot) and (HandleAllocated) then InvalidateRect (Handle, @FChevron, false);
    FHotElement := E;
    FChevronHot := C;
  end;
end;


procedure   TPaxonToolbar.MouseDown (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  E: TToolbarElement;
  P: TPoint;
begin
  inherited MouseDown (Button, Shift, X, Y);
  if (Button <> mbLeft) or (csDesigning in ComponentState) then exit;
  P := Point (X, Y);
  if (PtInRect (FChevron, P)) then begin
    OpenMenu (nil, false);
    exit;
  end;
  E := ElementAt (P);
  if (E = nil) then exit;
  if (E.IsSubmenu) then begin
    OpenMenu (E, false);
    exit;
  end;
  if (not E.Enabled) then exit;
  InvalidateElementArea (FHotElement);
  FPressedElement := E;
  FHotElement := E;
  InvalidateElementArea (E);
end;


procedure   TPaxonToolbar.MouseUp (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  E: TToolbarElement;
begin
  inherited MouseUp (Button, Shift, X, Y);
  if (Button <> mbLeft) then exit;
  E := FPressedElement;
  FPressedElement := nil;
  if (assigned (E)) then begin
    InvalidateElementArea (E);
    if (ElementAt (Point (X, Y)) = E) then begin
      Update;
      E.Click;
    end;
  end;
end;


procedure   TPaxonToolbar.TBMGetEffectiveColor (var Message: TMessage);
begin
  Message.WParam := EffectiveColor;
  Message.Result := 1;
end;


procedure   TPaxonToolbar.TBMGetViewType (var Message: TMessage);
begin
  Message.Result := ViewType;
end;


procedure   TPaxonToolbar.TBMThemeChange (var Message: TMessage);
begin
  case Message.WParam of
    TSC_BEFOREVIEWCHANGE: BeginUpdate;
    TSC_AFTERVIEWCHANGE: begin
      UpdateToolbarFont;
      EndUpdate;
      if (HandleAllocated) then begin
        SetWindowPos (Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOACTIVATE or SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE);
      end;
      ArrangeElements;
      Invalidate;
    end;
    TSC_APPACTIVATE, TSC_APPDEACTIVATE: if (FMenuBar) then Invalidate;
  end;
end;


function    TPaxonToolbar.IsShortCut (ShortcutKey: TShortCut): Boolean;

  function  SearchElement (W: TToolbarElement): TToolbarElement;
  var
    I: Integer;
  begin
    result := nil;
    for I := 0 to W.Count - 1 do begin
      if (W[I].Visible) then begin
        W[I].InitiateAction;
        if (W[I].ShortCut = ShortcutKey) and (W[I].Enabled) and not (W[I].IsSubmenu) then begin
          result := W[I];
          exit;
        end;
        if (W[I].Count > 0) then begin
          result := SearchElement (W[I]);
          if (assigned (result)) then exit;
        end;
      end;
    end;
  end;

var
  E: TToolbarElement;
begin
  result := false;
  if (ShortcutKey = 0) or (not Visible) then exit;
  E := SearchElement (FRootElement);
  if (assigned (E)) then begin
    result := true;
    E.Click;
  end;
end;


function    TPaxonToolbar.SearchAccelerator (C: Char): TToolbarElement;
var
  I: Integer;
  B: Char;
begin
  result := nil;
  B := AnsiUpperCase (C)[1];
  for I := 0 to High (FElementSlots) do begin
    if (FElementSlots[I].Element.AcceleratorChar = B) and (FElementSlots[I].Element.Enabled) then begin
      result := FElementSlots[I].Element;
      exit;
    end;
  end;
end;


function    TPaxonToolbar.OpenMenu (Element: TToolbarElement; ByKeyboard: Boolean): Boolean;
var
  S: TMenuLoop;
  ClickedElement: TToolbarElement;
begin
  result := false;
  if (assigned (ActiveLoop)) then exit;
  S := TMenuLoop.Create (self, nil, OwnerFormOf (self));
  try
    S.FKeyboard := ByKeyboard;
    if (Element = nil) then begin
      // Chevron
      FChevronOpen := true;
      Invalidate;
      S.OpenChevron;
    end else begin
      S.OpenToolbarElement (Element, ByKeyboard);
    end;
    S.ExecuteLoop;
    ClickedElement := S.FClick;
  finally
    S.Free;
  end;
  result := true;
  if (assigned (ClickedElement)) then begin
    MenuSound ('MenuCommand');
    ClickedElement.Click;
  end;
end;


procedure   TPaxonToolbar.KeyboardMode;
var
  S: TMenuLoop;
  ClickedElement: TToolbarElement;
  I: Integer;
begin
  if (assigned (ActiveLoop)) or (Length (FElementSlots) = 0) then exit;
  S := TMenuLoop.Create (self, nil, OwnerFormOf (self));
  try
    S.FKeyboard := true;
    FKeyboardChars := true;
    for I := 0 to High (FElementSlots) do begin
      if (not FElementSlots[I].Element.IsSeparator) then begin
        FKeyboard := FElementSlots[I].Element;
        break;
      end;
    end;
    Invalidate;
    S.ExecuteLoop;
    ClickedElement := S.FClick;
  finally
    S.Free;
  end;
  if (assigned (ClickedElement)) then begin
    MenuSound ('MenuCommand');
    ClickedElement.Click;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TPopupWindow
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TPopupWindow.Create (ALoop: TMenuLoop; AElementContent: TToolbarElement; AElements: TList);
var
  B: TCustomImageList;
begin
  inherited Create (nil);
  FLoop := ALoop;
  FContentElement := AElementContent;
  FChevronElements := AElements;
  FSelectedSlot := -1;
  FChildIndex := -1;
  Visible := false;
  if (assigned (FChevronElements)) then FViewType := PVT_CHEVRONMENU else FViewType := PVT_POPUPMENU;
  if (assigned (FLoop.FLoopForm)) and (FLoop.FLoopForm.HandleAllocated) then begin
    ParentWindow := FLoop.FLoopForm.Handle;
  end;
  B := nil;
  if (assigned (FChevronElements)) then begin
    if (assigned (FLoop.FOwnerToolbar)) then B := FLoop.FOwnerToolbar.Images;
  end else if (assigned (FContentElement)) then begin
    if (assigned (FContentElement.FToolbarImages)) then B := FContentElement.FToolbarImages
    else if (FContentElement.Count > 0) then B := FContentElement[0].EffectiveImages
    else if (FContentElement.FRootOf is TToolbarPopupMenu) then B := TToolbarPopupMenu(FContentElement.FRootOf).Images;
  end;
  FillChar (FView, SizeOf (FView), 0);
  FView.ViewType := FViewType;
  FView.IsToolbarStyle := false;
  FView.ToolbarImages := B;
  FView.PopupBorder := CalculatePopupBorder (B);
  FView.HidePrefix := (not KeyboardCuesOn) and (not FLoop.FKeyboard);
end;


destructor  TPopupWindow.Destroy;
begin
  if (HandleAllocated) then KillTimer (Handle, TimerSubmenu);
  FreeAndNil (FDropShadows);
  inherited Destroy;
end;


procedure   TPopupWindow.CreateParams (var Params: TCreateParams);
begin
  inherited CreateParams (Params);
  Params.Style := WS_POPUP or WS_CLIPSIBLINGS;
  Params.ExStyle := WS_EX_TOPMOST or WS_EX_TOOLWINDOW;
  Params.WindowClass.style := (Params.WindowClass.style or CS_SAVEBITS) and not (CS_DROPSHADOW or CS_DBLCLKS);
  if (CurrentTheme.GetPopupShadowType = PST_WINDOWSXP) and (IsWindowsXP) then begin
    Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
    StrPCopy (Params.WinClassName, ClassName + 'S');
  end;
end;


procedure   TPopupWindow.WMMouseActivate (var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;


procedure   TPopupWindow.CMHintShow (var Message: TCMHintShow);
begin
  Message.Result := 1;
end;


procedure   TPopupWindow.TBMGetViewType (var Message: TMessage);
begin
  Message.Result := FViewType;
end;


procedure   TPopupWindow.WMNCCalcSize (var Message: TWMNCCalcSize);
var
  B: TPoint;
begin
  CurrentTheme.GetViewBorder (FViewType, B);
  with Message.CalcSize_Params^.rgrc[0] do begin
    inc (Left, B.X);
    inc (Top, B.Y);
    dec (Right, B.X);
    dec (Bottom, B.Y);
  end;
  Message.Result := 0;
end;


// Border (like TBXPopupNCPaintProc in TBX.pas)
procedure   TPopupWindow.DrawNC (DC: HDC);
var
  R, R2: TRect;
  Canvas: TCanvas;
  PI: TTBXPopupInfo;
begin
  Canvas := TCanvas.Create;
  try
    Canvas.Handle := DC;
    FillChar (PI, SizeOf (PI), 0);
    PI.WindowHandle := Handle;
    PI.ViewType := FViewType;
    GetWindowRect (Handle, R2);
    if (FParentToolbarStyle) and not (IsRectEmpty (FParentRect)) then begin
      R := FParentRect;
      OffsetRect (R, -R2.Left, -R2.Top);
      PI.ParentRect := R;
    end;
    R := R2;
    OffsetRect (R, -R.Left, -R.Top);
    CurrentTheme.GetViewBorder (PI.ViewType, PI.BorderSize);
    R2 := R;
    InflateRect (R2, -PI.BorderSize.X, -PI.BorderSize.Y);
    ExcludeClipRect (Canvas.Handle, R2.Left, R2.Top, R2.Right, R2.Bottom);
    CurrentTheme.PaintPopupNCArea (Canvas, R, PI);
  finally
    Canvas.Handle := 0;
    Canvas.Free;
  end;
end;


procedure   TPopupWindow.WMNCPaint (var Message: TMessage);
var
  DC: HDC;
begin
  DC := GetWindowDC (Handle);
  try
    SelectNCUpdateRgn (Handle, DC, HRGN(Message.WParam));
    DrawNC (DC);
  finally
    ReleaseDC (Handle, DC);
  end;
  Message.Result := 0;
end;


procedure   TPopupWindow.WMEraseBkgnd (var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;


// directly into the window (see TPaxonToolbar.Paint)
procedure   TPopupWindow.Paint;
var
  R: TRect;
  I: Integer;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then exit;
  R := ClientRect;
  CurrentTheme.PaintBackgnd (Canvas, R, R, R, CurrentTheme.GetViewColor (FViewType), false, FViewType);
  for I := 0 to High (FElementSlots) do begin
    if (not RectVisible (Canvas.Handle, FElementSlots[I].R)) then continue;
    PaintElement (Canvas, FElementSlots[I].Element, FView, FElementSlots[I].R,
                     (I = FSelectedSlot) and (FByMouse), (I = FSelectedSlot) and (not FByMouse),
                     (I = FChildIndex), false);
  end;
end;


procedure   TPopupWindow.ArrangeElements;
var
  ItemList: TList;
  I, Y, W: Integer;
  G: array of TPoint;
  M: TTBXMargins;
  E: TToolbarElement;
begin
  ItemList := TList.Create;
  try
    if (assigned (FChevronElements)) then begin
      for I := 0 to FChevronElements.Count - 1 do begin
        if (TToolbarElement(FChevronElements[I]).Visible) then ItemList.Add (FChevronElements[I]);
      end;
    end else if (assigned (FContentElement)) then begin
      for I := 0 to FContentElement.Count - 1 do begin
        if (FContentElement[I].Visible) then ItemList.Add (FContentElement[I]);
      end;
    end;
    // separators at the start, at the end and duplicates are dropped
    while (ItemList.Count > 0) and (TToolbarElement(ItemList[0]).IsSeparator) do ItemList.Delete (0);
    while (ItemList.Count > 0) and (TToolbarElement(ItemList[ItemList.Count - 1]).IsSeparator) do
      ItemList.Delete (ItemList.Count - 1);
    for I := ItemList.Count - 1 downto 1 do begin
      if (TToolbarElement(ItemList[I]).IsSeparator) and (TToolbarElement(ItemList[I - 1]).IsSeparator) then ItemList.Delete (I);
    end;
    CurrentTheme.GetViewMargins (FViewType, M);
    SetLength (G, ItemList.Count);
    W := 0;
    for I := 0 to ItemList.Count - 1 do begin
      E := TToolbarElement(ItemList[I]);
      G[I] := MeasureElement (StockBitmap1.Canvas, E, FView);
      if (G[I].X > W) then W := G[I].X;
    end;
    if (W < 40) then W := 40;
    SetLength (FElementSlots, ItemList.Count);
    Y := M.TopHeight;
    for I := 0 to ItemList.Count - 1 do begin
      FElementSlots[I].Element := TToolbarElement(ItemList[I]);
      FElementSlots[I].R := Rect (M.LeftWidth, Y, M.LeftWidth + W, Y + G[I].Y);
      inc (Y, G[I].Y);
    end;
    ClientWidth := W + M.LeftWidth + M.RightWidth;
    ClientHeight := Y + M.BottomHeight;
  finally
    ItemList.Free;
  end;
end;


procedure   TPopupWindow.ShowPopup (const ParentBounds: TRect; AsSubmenu, ParentToolbarStyle: Boolean; X, Y: Integer);
var
  B: TPoint;
  W, H, NCX, NCY, X2: Integer;
  A: TRect;
  XP, Against, Again: Boolean;
begin
  HandleNeeded;
  ArrangeElements;
  CurrentTheme.GetViewBorder (FViewType, B);
  W := ClientWidth + 2 * B.X;
  H := ClientHeight + 2 * B.Y;
  FParentRect := ParentBounds;
  FParentToolbarStyle := ParentToolbarStyle;
  XP := CurrentTheme.OfficeXPPopupAlignment;
  A := ScreenWorkArea (ParentBounds.TopLeft);

  if (IsRectEmpty (ParentBounds)) and not (AsSubmenu) and not (ParentToolbarStyle) then begin
    // Context menu at a point (OfficeXP alignment: one pixel up and to the left,
    // calculated with width and height reduced by one)
    if (XP) then begin
      dec (X);
      dec (Y);
      dec (W);
      dec (H);
    end;
    if (Y + H > A.Bottom) and (ParentBounds.Top - H >= A.Top) then Y := ParentBounds.Top - H;
    if (Y + H > A.Bottom) then Y := A.Bottom - H;
    if (X + W > A.Right) then X := X - W;
    if (XP) then begin
      inc (W);
      inc (H);
    end;
  end else if (AsSubmenu) then begin
    // at the right edge of the item, overlapping by the popup's border
    // (OfficeXP alignment without overlap). If it does not fit on the right, it goes to the
    // left, and deeper submenus follow this direction until space runs out.
    if (XP) then begin
      NCX := 0;
      NCY := 0;
    end else begin
      NCX := B.X;
      NCY := B.Y;
    end;
    X := ParentBounds.Right - NCX;
    Y := ParentBounds.Top - NCY;
    Against := FOpposite;
    FOpposite := false;
    repeat
      Again := false;
      X2 := X;
      if (Against) or (X2 + W > A.Right) then begin
        X2 := ParentBounds.Left + NCX - W;
        if (not Against) then FOpposite := true
        else if (X2 < A.Left) then begin
          Against := false;
          Again := true;
        end else FOpposite := true;
      end;
    until not Again;
    X := X2;
    if (Y + H > A.Bottom) then Y := A.Bottom - H;
  end else begin
    X := ParentBounds.Left;
    Y := ParentBounds.Bottom;
    if (XP) then dec (Y);
    if (Y + H > A.Bottom) then begin
      Y := ParentBounds.Top - H;
      if (XP) then inc (Y);
    end;
    if (X + W > A.Right) then X := A.Right - W;
  end;
  if (X < A.Left) then X := A.Left;
  if (Y < A.Top) then Y := A.Top;

  // first position and size, then show without changing the Z order (WS_EX_TOPMOST
  // is already in the style). Done in one step with HWND_TOPMOST, under Windows 11 the
  // parent popup loses its system shadow (CS_DROPSHADOW).
  SetWindowPos (Handle, 0, X, Y, W, H, SWP_NOACTIVATE or SWP_NOZORDER or SWP_FRAMECHANGED);
  SetWindowPos (Handle, 0, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
  if (CurrentTheme.GetPopupShadowType in [PST_OFFICEXP, PST_WINDOWS2K]) then CreatePopupShadow;
  UpdateWindow (Handle);
end;


// Shadow (like TTBXPopupWindow.CreateShadow in TBX.pas)
procedure   TPopupWindow.CreatePopupShadow;
var
  PR, BR: TRect;
begin
  if (CurrentTheme.GetPopupShadowType = PST_WINDOWS2K) and
     not ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion >= 5)) then exit;
  SetRectEmpty (PR);
  if (CurrentTheme.GetPopupShadowType = PST_OFFICEXP) and (FParentToolbarStyle) then PR := FParentRect;
  GetWindowRect (Handle, BR);
  FreeAndNil (FDropShadows);
  FDropShadows := TShadows.Create (PR, BR, 4, 61, TBXLoColor);
  FDropShadows.Show (Handle);
end;


function    TPopupWindow.ElementIndexAt (const P: TPoint): Integer;
var
  I: Integer;
begin
  result := -1;
  for I := 0 to High (FElementSlots) do begin
    if (PtInRect (FElementSlots[I].R, P)) then begin
      if (not FElementSlots[I].Element.IsSeparator) then result := I;
      exit;
    end;
  end;
end;


function    TPopupWindow.IsSelectable (Index: Integer): Boolean;
begin
  result := (Index >= 0) and (Index <= High (FElementSlots)) and not FElementSlots[Index].Element.IsSeparator;
end;


function    TPopupWindow.NextIndex (Index, StepDirection: Integer): Integer;
var
  N, I: Integer;
begin
  result := Index;
  N := Length (FElementSlots);
  if (N = 0) then exit;
  I := Index;
  repeat
    I := I + StepDirection;
    if (I < 0) then I := N - 1;
    if (I >= N) then I := 0;
    if (IsSelectable (I)) then begin
      result := I;
      exit;
    end;
  until (I = Index) or ((Index < 0) and (I = N - 1) and (StepDirection < 0)) or
        ((Index < 0) and (I = 0) and (StepDirection > 0) and false);
end;


procedure   TPopupWindow.InvalidateSlot (Index: Integer);
var
  R: TRect;
begin
  if (Index < 0) or (Index > High (FElementSlots)) or (not HandleAllocated) then exit;
  R := FElementSlots[Index].R;
  InvalidateRect (Handle, @R, false);
end;


procedure   TPopupWindow.SelectEntry (Index: Integer; ByMouse: Boolean);
var
  ShowDelay: Integer;
begin
  if (Index = FSelectedSlot) and (ByMouse = FByMouse) then exit;
  // only the old and new entry: otherwise, without a buffer, the whole menu would flicker
  InvalidateSlot (FSelectedSlot);
  FSelectedSlot := Index;
  FByMouse := ByMouse;
  InvalidateSlot (FSelectedSlot);
  if (HandleAllocated) then begin
    KillTimer (Handle, TimerSubmenu);
    if (ByMouse) then begin
      ShowDelay := 400;
      SystemParametersInfo (SPI_GETMENUSHOWDELAY_, 0, @ShowDelay, 0);
      if (ShowDelay < 1) then ShowDelay := 1;
      SetTimer (Handle, TimerSubmenu, ShowDelay, nil);
    end;
  end;
end;


procedure   TPopupWindow.WMTimer (var Message: TWMTimer);
begin
  if (Message.TimerID = TimerSubmenu) then begin
    KillTimer (Handle, TimerSubmenu);
    FLoop.TimerSubmenu (self);
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TMenuLoop
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TMenuLoop.Create (AOwnerToolbar: TPaxonToolbar; APopupMenu: TToolbarPopupMenu; AOwningForm: TCustomForm);
begin
  inherited Create;
  FOwnerToolbar := AOwnerToolbar;
  FPopupMenu := APopupMenu;
  FLoopForm := AOwningForm;
  if (not assigned (FLoopForm)) then FLoopForm := Screen.ActiveCustomForm;
  FWindows := TList.Create;
  ActiveLoop := self;
end;


destructor  TMenuLoop.Destroy;
begin
  CloseFrom (0);
  if (assigned (FOwnerToolbar)) then begin
    FOwnerToolbar.FOpenElement := nil;
    FOwnerToolbar.FKeyboard := nil;
    FOwnerToolbar.FKeyboardChars := false;
    FOwnerToolbar.FChevronOpen := false;
    FOwnerToolbar.FHotElement := nil;
    FOwnerToolbar.FPressedElement := nil;
    if (FOwnerToolbar.HandleAllocated) then FOwnerToolbar.Invalidate;
  end;
  if (ActiveLoop = self) then ActiveLoop := nil;
  FreeAndNil (FWindows);
  inherited Destroy;
end;


function    TMenuLoop.TopmostPopup: TPopupWindow;
begin
  if (FWindows.Count > 0) then result := TPopupWindow(FWindows[FWindows.Count - 1]) else result := nil;
end;


function    TMenuLoop.WindowAt (const P: TPoint): TPopupWindow;
var
  I: Integer;
  R: TRect;
begin
  result := nil;
  for I := FWindows.Count - 1 downto 0 do begin
    GetWindowRect (TPopupWindow(FWindows[I]).Handle, R);
    if (PtInRect (R, P)) then begin
      result := TPopupWindow(FWindows[I]);
      exit;
    end;
  end;
end;


procedure   TMenuLoop.CloseFrom (MenuLevel: Integer);
var
  I: Integer;
  F: TPopupWindow;
begin
  if (MenuLevel < 0) then MenuLevel := 0;
  for I := FWindows.Count - 1 downto MenuLevel do begin
    F := TPopupWindow(FWindows[I]);
    FWindows.Delete (I);
    F.Free;
  end;
  // only redraw if a submenu really closed (otherwise the entry would appear pressed when
  // opening)
  if (MenuLevel > 0) and (MenuLevel <= FWindows.Count) then begin
    F := TPopupWindow(FWindows[MenuLevel - 1]);
    if (F.FChildIndex >= 0) or (assigned (F.FKind)) then F.Invalidate;
    F.FKind := nil;
    F.FChildIndex := -1;
  end;
end;


function    HasVisibleChildren (E: TToolbarElement): Boolean;
var
  I: Integer;
begin
  result := false;
  for I := 0 to E.Count - 1 do begin
    E[I].InitiateAction;
    if (E[I].Visible) and not (E[I].IsSeparator) then result := true;
  end;
end;


procedure   TMenuLoop.OpenToolbarElement (E: TToolbarElement; ByKeyboard: Boolean);
var
  F: TPopupWindow;
  R: TRect;
  OldOpen, OldKeyboard, OldHot: TToolbarElement;

  // with the mouse only the affected items (otherwise the bar flickers when moving across the
  // menu bar); with the keyboard everything, because then the underlines of all entries appear
  procedure Redraw;
  begin
    if (ByKeyboard) then begin
      FOwnerToolbar.Invalidate;
    end else begin
      FOwnerToolbar.InvalidateElementArea (OldOpen);
      FOwnerToolbar.InvalidateElementArea (OldKeyboard);
      FOwnerToolbar.InvalidateElementArea (OldHot);
      FOwnerToolbar.InvalidateElementArea (E);
    end;
  end;

begin
  if (not assigned (FOwnerToolbar)) then exit;
  OldOpen := FOwnerToolbar.FOpenElement;
  OldKeyboard := FOwnerToolbar.FKeyboard;
  OldHot := FOwnerToolbar.FHotElement;
  CloseFrom (0);
  FOwnerToolbar.FOpenElement := nil;
  FOwnerToolbar.FKeyboard := E;
  FOwnerToolbar.FHotElement := nil;
  if (ByKeyboard) then begin
    FKeyboard := true;
    FOwnerToolbar.FKeyboardChars := true;
  end;
  if (assigned (E)) and (E.IsSubmenu) and (E.Enabled) and (HasVisibleChildren (E)) then begin
    FOwnerToolbar.FOpenElement := E;
    FOwnerToolbar.FKeyboard := nil;
    Redraw;
    FOwnerToolbar.Update;
    F := TPopupWindow.Create (self, E, nil);
    FWindows.Add (F);
    R := FOwnerToolbar.ElementRect (E);
    R.TopLeft := FOwnerToolbar.ClientToScreen (R.TopLeft);
    R.BottomRight := FOwnerToolbar.ClientToScreen (R.BottomRight);
    F.ShowPopup (R, false, true, 0, 0);
    if (ByKeyboard) then F.SelectEntry (F.NextIndex (-1, 1), false);
    MenuSound ('MenuPopup');
  end;
  Redraw;
end;


procedure   TMenuLoop.OpenChevron;
var
  F: TPopupWindow;
  R: TRect;
begin
  if (not assigned (FOwnerToolbar)) or (FOwnerToolbar.FHiddenElements.Count = 0) then exit;
  F := TPopupWindow.Create (self, nil, FOwnerToolbar.FHiddenElements);
  FWindows.Add (F);
  R := FOwnerToolbar.FChevron;
  R.TopLeft := FOwnerToolbar.ClientToScreen (R.TopLeft);
  R.BottomRight := FOwnerToolbar.ClientToScreen (R.BottomRight);
  F.ShowPopup (R, false, true, 0, 0);
  MenuSound ('MenuPopup');
end;


procedure   TMenuLoop.OpenSubmenu (F: TPopupWindow; Index: Integer; ByKeyboard: Boolean);
var
  E: TToolbarElement;
  K: TPopupWindow;
  R: TRect;
begin
  if (not F.IsSelectable (Index)) then exit;
  E := F.FElementSlots[Index].Element;
  if (not E.IsSubmenu) or (not E.Enabled) or (not HasVisibleChildren (E)) then exit;
  if (F.FChildIndex = Index) and (assigned (F.FKind)) then begin
    if (ByKeyboard) and (F.FKind.FSelectedSlot < 0) then F.FKind.SelectEntry (F.FKind.NextIndex (-1, 1), false);
    exit;
  end;
  CloseFrom (FWindows.IndexOf (F) + 1);
  K := TPopupWindow.Create (self, E, nil);
  FWindows.Add (K);
  F.FKind := K;
  F.FChildIndex := Index;
  // no redraw of the parent popup: the entry now counts as pressed, but this only becomes
  // visible when it is redrawn anyway (e.g. after selection via accelerator)
  R := F.FElementSlots[Index].R;
  R.TopLeft := F.ClientToScreen (R.TopLeft);
  R.BottomRight := F.ClientToScreen (R.BottomRight);
  K.FOpposite := F.FOpposite;
  K.ShowPopup (R, true, false, 0, 0);
  if (ByKeyboard) then K.SelectEntry (K.NextIndex (-1, 1), false);
  MenuSound ('MenuPopup');
end;


procedure   TMenuLoop.ChooseItem (F: TPopupWindow; Index: Integer; ByKeyboard: Boolean);
var
  E: TToolbarElement;
begin
  if (not F.IsSelectable (Index)) then exit;
  E := F.FElementSlots[Index].Element;
  if (not E.Enabled) then exit;
  if (E.IsSubmenu) then begin
    OpenSubmenu (F, Index, ByKeyboard);
  end else begin
    FClick := E;
    QuitLoop;
  end;
end;


procedure   TMenuLoop.QuitLoop;
begin
  FEndRequested := true;
end;


procedure   TMenuLoop.ElementChanged;
var
  I: Integer;
begin
  for I := 0 to FWindows.Count - 1 do TPopupWindow(FWindows[I]).Invalidate;
end;


procedure   TMenuLoop.ElementRemoved (E: TToolbarElement);
begin
  // A displayed item disappears: close the menu
  if (FClick = E) then FClick := nil;
  CloseFrom (0);
  QuitLoop;
end;


procedure   TMenuLoop.TimerSubmenu (F: TPopupWindow);
begin
  if (FWindows.IndexOf (F) < 0) then exit;
  if (F.IsSelectable (F.FSelectedSlot)) and (F.FElementSlots[F.FSelectedSlot].Element.IsSubmenu) then begin
    if (F.FChildIndex <> F.FSelectedSlot) then OpenSubmenu (F, F.FSelectedSlot, false);
  end else if (assigned (F.FKind)) and (F.FSelectedSlot <> F.FChildIndex) then begin
    CloseFrom (FWindows.IndexOf (F) + 1);
  end;
end;


procedure   TMenuLoop.MouseMoved (const P: TPoint);
var
  F: TPopupWindow;
  I: Integer;
  E: TToolbarElement;
  R: TRect;
begin
  // Windows also sends WM_MOUSEMOVE without movement (when windows open or close);
  // that must not overwrite the keyboard selection
  if (P.X = FLastMouse.X) and (P.Y = FLastMouse.Y) then exit;
  FLastMouse := P;
  if (not FMouseMoved) and ((P.X <> FMouseStart.X) or (P.Y <> FMouseStart.Y)) then FMouseMoved := true;
  F := WindowAt (P);
  if (assigned (F)) then begin
    I := F.ElementIndexAt (F.ScreenToClient (P));
    if (I < 0) and (assigned (F.FKind)) then I := F.FChildIndex;
    F.SelectEntry (I, true);
    exit;
  end;
  if (assigned (FOwnerToolbar)) and (FOwnerToolbar.HandleAllocated) then begin
    GetWindowRect (FOwnerToolbar.Handle, R);
    if (PtInRect (R, P)) then begin
      E := FOwnerToolbar.ElementAt (FOwnerToolbar.ScreenToClient (P));
      if (FWindows.Count > 0) and (assigned (FOwnerToolbar.FOpenElement)) then begin
        if (assigned (E)) and (E <> FOwnerToolbar.FOpenElement) and (E.IsSubmenu) then OpenToolbarElement (E, false);
      end else if (FWindows.Count = 0) and (assigned (E)) and (E <> FOwnerToolbar.FKeyboard) then begin
        FOwnerToolbar.InvalidateElementArea (FOwnerToolbar.FKeyboard);
        FOwnerToolbar.FKeyboard := E;
        FOwnerToolbar.InvalidateElementArea (E);
      end;
      exit;
    end;
  end;
  // outside: select nothing in the lowest popup without an open submenu
  F := TopmostPopup;
  if (assigned (F)) and (F.FKind = nil) and (F.FByMouse) then F.SelectEntry (-1, true);
end;


procedure   TMenuLoop.MousePressed (const P: TPoint);
var
  F: TPopupWindow;
  I: Integer;
  E: TToolbarElement;
  R: TRect;
begin
  FMouseMoved := true;
  F := WindowAt (P);
  if (assigned (F)) then begin
    I := F.ElementIndexAt (F.ScreenToClient (P));
    if (F.IsSelectable (I)) and (F.FElementSlots[I].Element.IsSubmenu) then OpenSubmenu (F, I, false);
    exit;
  end;
  if (assigned (FOwnerToolbar)) and (FOwnerToolbar.HandleAllocated) then begin
    GetWindowRect (FOwnerToolbar.Handle, R);
    if (PtInRect (R, P)) then begin
      E := FOwnerToolbar.ElementAt (FOwnerToolbar.ScreenToClient (P));
      if (assigned (E)) and (E.IsSubmenu) and (E <> FOwnerToolbar.FOpenElement) then begin
        OpenToolbarElement (E, false);
        exit;
      end;
      if (PtInRect (FOwnerToolbar.FChevron, FOwnerToolbar.ScreenToClient (P))) and not (FOwnerToolbar.FChevronOpen) then begin
        // Chevron while a menu is open: new menu
        QuitLoop;
        exit;
      end;
    end;
  end;
  // Click on the open item or outside: close the menu
  QuitLoop;
end;


procedure   TMenuLoop.MouseReleased (const P: TPoint);
var
  F: TPopupWindow;
  I: Integer;
  E: TToolbarElement;
begin
  if (not FMouseMoved) then exit;
  F := WindowAt (P);
  if (not assigned (F)) then exit;
  I := F.ElementIndexAt (F.ScreenToClient (P));
  if (not F.IsSelectable (I)) then exit;
  E := F.FElementSlots[I].Element;
  if (E.IsSubmenu) then begin
    OpenSubmenu (F, I, false);
  end else if (E.Enabled) then begin
    FClick := E;
    QuitLoop;
  end;
end;


procedure   TMenuLoop.SwitchToolbar (StepDirection: Integer);
var
  CurrentItem: TToolbarElement;
  I, N, K: Integer;
  IsOpen: Boolean;
begin
  if (not assigned (FOwnerToolbar)) then exit;
  N := Length (FOwnerToolbar.FElementSlots);
  if (N = 0) then exit;
  IsOpen := assigned (FOwnerToolbar.FOpenElement);
  if (IsOpen) then CurrentItem := FOwnerToolbar.FOpenElement else CurrentItem := FOwnerToolbar.FKeyboard;
  I := -1;
  for K := 0 to N - 1 do begin
    if (FOwnerToolbar.FElementSlots[K].Element = CurrentItem) then I := K;
  end;
  for K := 1 to N do begin
    I := I + StepDirection;
    if (I < 0) then I := N - 1;
    if (I >= N) then I := 0;
    if (not FOwnerToolbar.FElementSlots[I].Element.IsSeparator) then break;
  end;
  if (IsOpen) then begin
    OpenToolbarElement (FOwnerToolbar.FElementSlots[I].Element, true);
  end else begin
    FOwnerToolbar.FKeyboard := FOwnerToolbar.FElementSlots[I].Element;
    FOwnerToolbar.Invalidate;
  end;
end;


function    TMenuLoop.HandleKey (HandleKey: Word): Boolean;
var
  F: TPopupWindow;
  E: TToolbarElement;
begin
  result := true;
  F := TopmostPopup;
  FKeyboard := true;
  if (assigned (FOwnerToolbar)) then FOwnerToolbar.FKeyboardChars := true;
  case HandleKey of
    VK_ESCAPE: begin
      if (FWindows.Count > 1) then begin
        CloseFrom (FWindows.Count - 1);
      end else if (FWindows.Count = 1) and (assigned (FOwnerToolbar)) and (assigned (FOwnerToolbar.FOpenElement)) then begin
        E := FOwnerToolbar.FOpenElement;
        CloseFrom (0);
        FOwnerToolbar.FOpenElement := nil;
        FOwnerToolbar.FKeyboard := E;
        FOwnerToolbar.Invalidate;
      end else begin
        QuitLoop;
      end;
    end;
    VK_MENU, VK_F10: QuitLoop;
    VK_UP, VK_DOWN: begin
      if (assigned (F)) then begin
        if (HandleKey = VK_UP) then F.SelectEntry (F.NextIndex (F.FSelectedSlot, -1), false)
        else F.SelectEntry (F.NextIndex (F.FSelectedSlot, 1), false);
      end else if (assigned (FOwnerToolbar)) and (assigned (FOwnerToolbar.FKeyboard)) and (HandleKey = VK_DOWN) then begin
        OpenToolbarElement (FOwnerToolbar.FKeyboard, true);
      end;
    end;
    VK_HOME, VK_END: begin
      if (assigned (F)) then begin
        if (HandleKey = VK_HOME) then F.SelectEntry (F.NextIndex (-1, 1), false)
        else F.SelectEntry (F.NextIndex (Length (F.FElementSlots), -1), false);
      end;
    end;
    VK_RIGHT: begin
      if (assigned (F)) and (F.IsSelectable (F.FSelectedSlot)) and (F.FElementSlots[F.FSelectedSlot].Element.IsSubmenu) and
         (F.FElementSlots[F.FSelectedSlot].Element.Enabled) then begin
        OpenSubmenu (F, F.FSelectedSlot, true);
      end else if (assigned (FOwnerToolbar)) then begin
        SwitchToolbar (1);
      end;
    end;
    VK_LEFT: begin
      if (FWindows.Count > 1) then begin
        CloseFrom (FWindows.Count - 1);
      end else if (assigned (FOwnerToolbar)) then begin
        SwitchToolbar (-1);
      end;
    end;
    VK_RETURN: begin
      if (assigned (F)) then begin
        if (F.FSelectedSlot >= 0) then ChooseItem (F, F.FSelectedSlot, true);
      end else if (assigned (FOwnerToolbar)) and (assigned (FOwnerToolbar.FKeyboard)) then begin
        E := FOwnerToolbar.FKeyboard;
        if (E.IsSubmenu) then begin
          OpenToolbarElement (E, true);
        end else if (E.Enabled) then begin
          FClick := E;
          QuitLoop;
        end;
      end;
    end;
  else
    result := false;
  end;
end;


procedure   TMenuLoop.HandleChar (C: Char);
var
  F: TPopupWindow;
  I, FirstSelectable, Quantity, NextFound: Integer;
  B: Char;
  E: TToolbarElement;
begin
  if (C < ' ') then exit;
  B := AnsiUpperCase (C)[1];
  F := TopmostPopup;
  if (assigned (F)) then begin
    FirstSelectable := -1;
    NextFound := -1;
    Quantity := 0;
    for I := 0 to High (F.FElementSlots) do begin
      if (F.IsSelectable (I)) and (F.FElementSlots[I].Element.AcceleratorChar = B) then begin
        inc (Quantity);
        if (FirstSelectable < 0) then FirstSelectable := I;
        if (NextFound < 0) and (I > F.FSelectedSlot) then NextFound := I;
      end;
    end;
    if (Quantity = 1) then begin
      F.SelectEntry (FirstSelectable, false);
      ChooseItem (F, FirstSelectable, true);
    end else if (Quantity > 1) then begin
      if (NextFound < 0) then NextFound := FirstSelectable;
      F.SelectEntry (NextFound, false);
    end else begin
      MessageBeep (0);
    end;
  end else if (assigned (FOwnerToolbar)) then begin
    E := FOwnerToolbar.SearchAccelerator (C);
    if (assigned (E)) then begin
      if (E.IsSubmenu) then begin
        OpenToolbarElement (E, true);
      end else begin
        FClick := E;
        QuitLoop;
      end;
    end else begin
      MessageBeep (0);
    end;
  end;
end;


procedure   TMenuLoop.ExecuteLoop;
var
  Msg: TMsg;
  P: TPoint;
begin
  if (FWindows.Count = 0) and ((FOwnerToolbar = nil) or (FOwnerToolbar.FKeyboard = nil) and (FOwnerToolbar.FOpenElement = nil)) then
    exit;
  if (assigned (FLoopForm)) and (FLoopForm.HandleAllocated) then FCaptureWindow := FLoopForm.Handle
  else if (FWindows.Count > 0) then FCaptureWindow := TPopupWindow(FWindows[0]).Handle
  else FCaptureWindow := FOwnerToolbar.Handle;
  GetCursorPos (FMouseStart);
  FLastMouse := FMouseStart;
  Application.CancelHint;
  SetCapture (FCaptureWindow);
  Windows.SetCursor (Screen.Cursors[crDefault]);
  try
    while (not FEndRequested) do begin
      if (GetCapture <> FCaptureWindow) then break;
      if (not PeekMessage (Msg, 0, 0, 0, PM_REMOVE)) then begin
        WaitMessage;
        continue;
      end;
      case Msg.message of
        WM_MOUSEMOVE, WM_NCMOUSEMOVE: begin
          GetCursorPos (P);
          MouseMoved (P);
        end;
        WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN,
        WM_LBUTTONDBLCLK, WM_RBUTTONDBLCLK, WM_MBUTTONDBLCLK,
        WM_NCLBUTTONDOWN, WM_NCRBUTTONDOWN, WM_NCMBUTTONDOWN: begin
          GetCursorPos (P);
          MousePressed (P);
        end;
        WM_LBUTTONUP, WM_RBUTTONUP, WM_NCLBUTTONUP, WM_NCRBUTTONUP: begin
          GetCursorPos (P);
          MouseReleased (P);
        end;
        WM_MBUTTONUP, WM_MOUSEWHEEL: ;
        WM_KEYDOWN, WM_SYSKEYDOWN: begin
          if (not HandleKey (Msg.wParam)) then TranslateMessage (Msg);
        end;
        WM_CHAR, WM_SYSCHAR: HandleChar (Char(Msg.wParam));
        WM_KEYUP, WM_SYSKEYUP, WM_DEADCHAR, WM_SYSDEADCHAR: ;
        WM_QUIT: begin
          PostQuitMessage (Msg.wParam);
          QuitLoop;
        end;
      else
        TranslateMessage (Msg);
        DispatchMessage (Msg);
      end;
    end;
  finally
    if (GetCapture = FCaptureWindow) then ReleaseCapture;
    CloseFrom (0);
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TToolbarPopupMenu
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TToolbarPopupMenu.Create (AOwner: TComponent);
begin
  inherited Create (AOwner);
  FRootElement := TToolbarElement.Create (nil);
  FRootElement.FRootOf := self;
end;


destructor  TToolbarPopupMenu.Destroy;
begin
  FreeAndNil (FRootElement);
  inherited Destroy;
end;


procedure   TToolbarPopupMenu.GetChildren (Proc: TGetChildProc; Root: TComponent);
begin
  FRootElement.GetChildren (Proc, Root);
end;


procedure   TToolbarPopupMenu.SetChildOrder (Child: TComponent; Order: Integer);
begin
  FRootElement.SetChildOrder (Child, Order);
end;


procedure   TToolbarPopupMenu.Notification (AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification (AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FToolbarImages) then FToolbarImages := nil;
end;


procedure   TToolbarPopupMenu.SetToolbarImages (Value: TCustomImageList);
begin
  FToolbarImages := Value;
  if (assigned (Value)) then Value.FreeNotification (self);
end;


procedure   TToolbarPopupMenu.Popup (X, Y: Integer);
var
  S: TMenuLoop;
  F: TPopupWindow;
  ClickedElement: TToolbarElement;
begin
  if (assigned (ActiveLoop)) then exit;
  if (not HasVisibleChildren (FRootElement)) then exit;
  S := TMenuLoop.Create (nil, self, OwnerFormOf (self));
  try
    F := TPopupWindow.Create (S, FRootElement, nil);
    S.FWindows.Add (F);
    F.ShowPopup (Rect (X, Y, X, Y), false, false, X, Y);
    MenuSound ('MenuPopup');
    S.ExecuteLoop;
    ClickedElement := S.FClick;
  finally
    S.Free;
  end;
  if (assigned (ClickedElement)) then begin
    MenuSound ('MenuCommand');
    ClickedElement.Click;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  TFormHook
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TFormHook.Create (AForm: TCustomForm);
begin
  inherited Create (nil);
  FForm := AForm;
  FToolbars := TList.Create;
  FOldProcedure := FForm.WindowProc;
  FForm.WindowProc := NewProcedure;
  FForm.FreeNotification (self);
end;


destructor  TFormHook.Destroy;
begin
  if (assigned (FForm)) then begin
    FForm.WindowProc := FOldProcedure;
    FForm.RemoveFreeNotification (self);
  end;
  FreeAndNil (FToolbars);
  if (assigned (FormHooks)) then FormHooks.Remove (self);
  inherited Destroy;
end;


procedure   TFormHook.Notification (AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification (AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FForm) then begin
    FForm.WindowProc := FOldProcedure;
    FForm := nil;
  end;
end;


function    TFormHook.MenuBarToolbar: TPaxonToolbar;
var
  I: Integer;
  L: TPaxonToolbar;
begin
  result := nil;
  for I := 0 to FToolbars.Count - 1 do begin
    L := TPaxonToolbar(FToolbars[I]);
    if (L.MenuBar) and (L.Visible) and (L.HandleAllocated) and (IsWindowVisible (L.Handle)) then begin
      result := L;
      exit;
    end;
  end;
end;


procedure   TFormHook.NewProcedure (var Message: TMessage);
var
  C: Char;
  I: Integer;
  L: TPaxonToolbar;
  E: TToolbarElement;
  K: TShortCut;
  SavedWndProc: TWndMethod;
begin

  SavedWndProc := FOldProcedure;

  case Message.Msg of

    WM_SYSCOMMAND: begin
      if ((Message.WParam and $FFF0) = SC_KEYMENU) and (ActiveLoop = nil) then begin
        C := Char(Message.LParam and $FF);
        if (C = #0) then begin
          // Alt alone or F10: menu bar via keyboard
          L := MenuBarToolbar;
          if (assigned (L)) then begin
            L.KeyboardMode;
            Message.Result := 0;
            exit;
          end;
        end else if (C <> ' ') and (C <> '-') then begin
          // Alt+letter: first bars with ProcessShortCuts, then the menu bar
          K := ShortCut (Ord (AnsiUpperCase (C)[1]), [ssAlt]);
          for I := 0 to FToolbars.Count - 1 do begin
            L := TPaxonToolbar(FToolbars[I]);
            if (L.ProcessShortCuts) and (L.Visible) and (L.IsShortCut (K)) then begin
              Message.Result := 0;
              exit;
            end;
          end;
          L := MenuBarToolbar;
          if (assigned (L)) then begin
            E := L.SearchAccelerator (C);
            if (assigned (E)) then begin
              if (E.IsSubmenu) then L.OpenMenu (E, true) else E.Click;
              Message.Result := 0;
              exit;
            end;
          end;
        end;
      end;
    end;

    WM_ACTIVATEAPP: begin
      SavedWndProc (Message);
      for I := 0 to FToolbars.Count - 1 do begin
        L := TPaxonToolbar(FToolbars[I]);
        if (L.MenuBar) and (L.HandleAllocated) then L.Invalidate;
      end;
      exit;
    end;

    WM_SETTINGCHANGE, WM_SYSCOLORCHANGE: begin
      SavedWndProc (Message);
      UpdateToolbarFont;
      for I := 0 to FToolbars.Count - 1 do TPaxonToolbar(FToolbars[I]).ArrangeElements;
      exit;
    end;

  end;

  SavedWndProc (Message);

end;


procedure   Register;
begin
  // the status bar comes from TBX (VCL\tbxthemes) and belongs to the bars
  RegisterComponents ('Paxon', [TToolbarDock, TPaxonToolbar, TToolbarPopupMenu, TTBXStatusBar]);
end;


initialization
  RegisterClasses ([TToolbarElement, TToolbarSubmenu, TToolbarSeparator, TPaxonToolbar, TToolbarDock, TToolbarPopupMenu]);

finalization
  while (assigned (FormHooks)) and (FormHooks.Count > 0) do TFormHook(FormHooks[FormHooks.Count - 1]).Free;
  FreeAndNil (FormHooks);

end.
