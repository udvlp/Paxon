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


unit ListView4StateCheckU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Commctrl, ImgList;


type
  TListView4State = class (TCustomListView)
  private

    FAllowGrayed: Boolean;

    procedure   StateIconClick (LI: TListItem);
    function    GetAllowGrayed: Boolean;
    procedure   SetAllowGrayed(const Value: Boolean);

  protected

    procedure   WMLButtonDown (var Msg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure   WMLButtonDblClk (var Msg: TWMMButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure   WMKeyDown (var Msg: TWMKeyDown); message WM_KEYDOWN;

  public

    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    // procedure   DefaultHandler (var Message); override;

  published

    property    AllowGrayed: Boolean read GetAllowGrayed write SetAllowGrayed;

    property    Align;
    property    AllocBy;
    property    Anchors;
    property    BiDiMode;
    property    BorderStyle;
    property    BorderWidth;
    property    Color;
    property    Columns;
    property    ColumnClick;
    property    Constraints;
    property    Ctl3D;
    property    DragCursor;
    property    DragKind;
    property    DragMode;
    property    Enabled;
    property    Font;
    property    FlatScrollBars;
    property    FullDrag;
    property    GridLines;
    property    HideSelection;
    property    HotTrack;
    property    HotTrackStyles;
    property    HoverTime;
    property    IconOptions;
    property    Items;
    property    LargeImages;
    property    MultiSelect;
    property    OwnerData;
    property    OwnerDraw;
    property    ReadOnly default False;
    property    RowSelect;
    property    ParentBiDiMode;
    property    ParentColor default False;
    property    ParentFont;
    property    ParentShowHint;
    property    PopupMenu;
    property    ShowColumnHeaders;
    property    ShowWorkAreas;
    property    ShowHint;
    property    SmallImages;
    property    SortType;
    property    TabOrder;
    property    TabStop default True;
    property    ViewStyle;
    property    Visible;

    property    OnAdvancedCustomDraw;
    property    OnAdvancedCustomDrawItem;
    property    OnAdvancedCustomDrawSubItem;
    property    OnChange;
    property    OnChanging;
    property    OnClick;
    property    OnColumnClick;
    property    OnColumnDragged;
    property    OnColumnRightClick;
    property    OnCompare;
    property    OnContextPopup;
    property    OnCustomDraw;
    property    OnCustomDrawItem;
    property    OnCustomDrawSubItem;
    property    OnData;
    property    OnDataFind;
    property    OnDataHint;
    property    OnDataStateChange;
    property    OnDblClick;
    property    OnDeletion;
    property    OnDrawItem;
    property    OnEdited;
    property    OnEditing;
    property    OnEndDock;
    property    OnEndDrag;
    property    OnEnter;
    property    OnExit;
    property    OnGetImageIndex;
    property    OnGetSubItemImage;
    property    OnDragDrop;
    property    OnDragOver;
    property    OnInfoTip;
    property    OnInsert;
    property    OnKeyDown;
    property    OnKeyPress;
    property    OnKeyUp;
    property    OnMouseDown;
    property    OnMouseMove;
    property    OnMouseUp;
    property    OnResize;
    property    OnSelectItem;
    property    OnStartDock;
    property    OnStartDrag;

  end;


procedure Register;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R ListView4StateCheckU.res}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure Register;
begin
  RegisterComponents ('Paxon', [TListView4State]);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TListView4State.Create (AOwner: TComponent);
begin
  inherited;
  StateImages := TImageList.create (self);
  StateImages.GetResource (rtBitmap, 'states', 16, [], RGB ($FF, $00, $FF));
end;


destructor  TListView4State.Destroy;
begin
  inherited;
end;


procedure   TListView4State.WMLButtonDown (var Msg: TWMLButtonDown);
var
  HitTest: TLVHitTestInfo;
  LI: TListItem;
  I: Integer;
begin
  inherited;
  HitTest.pt.X := Msg.XPos;
  HitTest.pt.Y := Msg.YPos;
  ListView_HitTest (Handle, HitTest);
  if ((HitTest.Flags and LVHT_ONITEMSTATEICON) <> 0) then begin
    I := HitTest.iItem;
    LI := Items[I];
    StateIconClick (LI);
  end;
end;


procedure   TListView4State.WMLButtonDblClk (var Msg: TWMMButtonDblClk);
var
  HitTest: TLVHitTestInfo;
  LI: TListItem;
  I: Integer;
begin
  inherited;
  HitTest.pt.X := Msg.XPos;
  HitTest.pt.Y := Msg.YPos;
  ListView_HitTest (Handle, HitTest);
  if ((HitTest.Flags and LVHT_ONITEMSTATEICON) <> 0) then begin
    I := HitTest.iItem;
    LI := Items[I];
    StateIconClick (LI);
  end;
end;


procedure   TListView4State.StateIconClick (LI: TListItem);
var
  N: Integer;
begin
  LI.Focused := true;
  LI.Selected := true;
  case LI.StateIndex of
    0: N := 1;
    1: begin
      if (FAllowGrayed) then begin
        if (Cardinal(LI.Data) = 0) then N := 2 else N := 3;
      end else begin
        N := 0;
      end;
    end;
    else N := 0;
  end;
  LI.StateIndex := N;
end;


procedure   TListView4State.WMKeyDown (var Msg: TWMKeyDown);
var
  LI: TListItem;
begin
  if (Msg.CharCode = vk_space) then begin
    LI := Selected;
    if (assigned (LI)) then begin
      StateIconClick (LI);
    end;
  end else begin
    inherited;
  end;
end;


function   TListView4State.GetAllowGrayed: Boolean;
begin
  result := FAllowGrayed;
end;


procedure  TListView4State.SetAllowGrayed (const Value: Boolean);
begin
  FAllowGrayed := Value;
end;


(*
procedure  TListView4State.DefaultHandler (var Message);
begin
  // Windows XP Fix
  if (TMessage(Message).Msg <> WM_NOTIFY) then begin
    inherited;
  end;
end;
*)


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

