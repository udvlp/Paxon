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


unit RicheditPaxonU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, RichEdit, ActiveX;


type

  TSendTextEvent = procedure (Sender: TObject; Text: String) of object;


  TRichEditPaxon = class;


  IRichEditOleCallback = interface
    ['{00020D03-0000-0000-C000-000000000046}']
    function    GetNewStorage (out stg: IStorage): HRESULT; stdcall;
    function    GetInPlaceContext (out Frame: IOleInPlaceFrame; out Doc: IOleInPlaceUIWindow;
                                   var FrameInfo: TOleInPlaceFrameInfo): HRESULT; stdcall;
    function    ShowContainerUI (fShow: BOOL): HRESULT; stdcall;
    function    QueryInsertObject (const clsid: TCLSID; stg: IStorage; cp: longint): HRESULT; stdcall;
    function    DeleteObject (oleobj: IOLEObject): HRESULT; stdcall;
    function    QueryAcceptData (dataobj: IDataObject; var cfFormat: TClipFormat; reco: DWORD; fReally: BOOL;
                                 hMetaPict: HGLOBAL): HRESULT; stdcall;
    function    ContextSensitiveHelp (fEnterMode: BOOL): HRESULT; stdcall;
    function    GetClipboardData (const chrg: TCharRange; reco: DWORD; out dataobj: IDataObject): HRESULT; stdcall;
    function    GetDragDropEffect (fDrag: BOOL; grfKeyState: DWORD; var dwEffect: DWORD): HRESULT; stdcall;
    function    GetContextMenu (seltype: Word; oleobj: IOleObject; const chrg: TCharRange; var menu: HMENU): HRESULT; stdcall;
  end;


  TRichEditOleCallback = class (TInterfacedObject, IRichEditOleCallback)
  private
    RichEditPaxon: TRichEditPaxon;
  public
    procedure   AfterConstruction; override;
    function    GetNewStorage (out stg: IStorage): HRESULT; overload; stdcall;
    function    GetInPlaceContext (out Frame: IOleInPlaceFrame; out Doc: IOleInPlaceUIWindow;
                                   var FrameInfo: TOleInPlaceFrameInfo): HRESULT; overload; stdcall;
    function    ShowContainerUI (fShow: BOOL): HRESULT; overload; stdcall;
    function    QueryInsertObject (const clsid: TCLSID; stg: IStorage; cp: longint): HRESULT; overload; stdcall;
    function    DeleteObject (oleobj: IOLEObject): HRESULT; overload; stdcall;
    function    QueryAcceptData (dataobj: IDataObject; var cfFormat: TClipFormat; reco: DWORD; fReally: BOOL;
                                 hMetaPict: HGLOBAL): HRESULT; overload; stdcall;
    function    ContextSensitiveHelp (fEnterMode: BOOL): HRESULT; overload; stdcall;
    function    GetClipboardData (const chrg: TCharRange; reco: DWORD; out dataobj: IDataObject): HRESULT; overload; stdcall;
    function    GetDragDropEffect (fDrag: BOOL; grfKeyState: DWORD; var dwEffect: DWORD): HRESULT; overload; stdcall;
    function    GetContextMenu (seltype: Word; oleobj: IOleObject; const chrg: TCharRange;
                                var menu: HMENU): HRESULT; overload; stdcall;
  end;


  TRichEditPaxon = class (TRichedit)
  private
    FOnSendText: TSendTextEvent;
    RichEditOleCallback: IRichEditOleCallback;
    FColorNewText: TColor;
    FColorSentText: TColor;
    procedure   wmKeyDown (var Msg: TMessage);  message wm_keydown;
    procedure   wmChar (var Msg: TMessage);     message wm_char;
    procedure   wmContextMenu (var Msg: TMessage); message wm_contextmenu;
    function    ParagraphStart: Integer;
    function    ParagraphEnd: Integer;
    procedure   SetColorNewText (const Value: TColor);
    procedure   SetColorSentText (const Value: TColor);
  protected
    FInContextMenu: Boolean;
    procedure   CreateParams (var Params: TCreateParams); override;
  public
    function    TextRange (FromPos, ToPos: Integer): String;
    procedure   ShowSelection (TheValue: Boolean);
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   CreateWnd; override;
  published
    property    OnSendText: TSendTextEvent read FOnSendText write FOnSendText;
    property    ColorNewText: TColor read FColorNewText write SetColorNewText;
    property    ColorSentText: TColor read FColorSentText write SetColorSentText;
  end;


procedure Register;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  RICHEDIT_CLASS10A = 'RICHEDIT';
  RICHEDIT_CLASSA = 'RichEdit20A';
  RICHEDIT_CLASS = RICHEDIT_CLASSA;
  EM_AUTOURLDETECT = WM_USER + 91;
  ENM_LINK = $04000000;
  EN_LINK = $070b;


type
  TTextRange = record
    chrg: TCharRange;
    lpstrText: PAnsiChar;
  end;

  PEnLink = ^TEnLink;
  TENLink = record
    nmhdr: TNMHdr;
    msg: UINT;
    wParam: WPARAM;
    lParam: LPARAM;
    chrg: TCharRange;
  end;


(*
var
  RichEditModule: HMODULE = 0;
  RichEditUseCount: Integer = 0;
  RichEditVersion: Integer = 0;


procedure LoadRichEdit;
begin
  if (RichEditUseCount <= 0) then begin
    RichEditVersion := 0;
    RichEditModule := LoadLibrary ('RICHED20.DLL');
    if (RichEditModule <> 0) then begin
      RichEditVersion := 2;
    end else begin
      if (RichEditModule = 0) then begin
        RichEditModule := LoadLibrary ('RICHED32.DLL');
        if (RichEditModule <> 0) then begin
          RichEditVersion := 1;
        end;
      end;
    end;
  end;
  if (RichEditVersion > 0) then begin
    Inc (RichEditUseCount);
  end;
end;


procedure UnloadRichEdit;
begin
  if (RichEditUseCount > 0) then begin
    Dec (RichEditUseCount);
    if (RichEditUseCount = 0) then begin
      FreeLibrary (RichEditModule);
      RichEditModule := 0;
    end;
  end;
end;


*)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRichEditPaxon.AfterConstruction;
var
  REOC: TRichEditOleCallback;
begin
  inherited;
  // LoadRichEdit;
  REOC := TRichEditOleCallback.create;
  REOC.RichEditPaxon := self;
  RichEditOleCallback := REOC;
  PlainText := true;
end;


procedure   TRichEditPaxon.BeforeDestruction;
begin
  RichEditOleCallback := nil;
  // UnloadRichEdit;
  inherited;
end;


procedure   TRichEditPaxon.CreateParams (var Params: TCreateParams);
const
  AHideScrollBars: array[Boolean] of DWORD = (ES_DISABLENOSCROLL, 0);
  AHideSelections: array[Boolean] of DWORD = (ES_NOHIDESEL, 0);
begin
  inherited;
  with Params do begin
    Style := Style or AHideScrollBars[HideScrollBars] or AHideSelections[HideSelection];
    WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
  end;
  // if (RichEditVersion = 2) then CreateSubClass (Params, RICHEDIT_CLASS) else CreateSubClass (Params, RICHEDIT_CLASS10A);
end;


procedure   TRichEditPaxon.CreateWnd;
begin
  inherited;
  SendMessage (Handle, EM_SETOLECALLBACK, 0, Integer(RichEditOleCallback));
end;


function    TRichEditPaxon.ParagraphStart: Integer;
var
  N: Integer;
  C: Array[0..2] of Char;
  TR: TTextRange;
begin
  if SelStart > 0 then begin
    for N := SelStart - 1 downto 0 do begin
      with TR do begin
        chrg.cpMin := N;
        chrg.cpMax := N+1;
        lpStrText := PChar(@C);
      end;
      SendMessage (Handle, em_gettextrange, 0, LongInt(@TR));
      if (C[0] = #13) or (C[0] = #10) then break;
    end;
    Result := N + 1;
  end else begin
    Result := 0;
  end;
end;


function    TRichEditPaxon.ParagraphEnd: Integer;
var
  I, N: Integer;
  C: Array[0..2] of Char;
  TR: TTextRange;
begin
  for N := SelStart to MaxInt do begin
    with TR do begin
      chrg.cpMin := N;
      chrg.cpMax := N + 1;
      lpStrText := PChar(@C);
    end;
    I := SendMessage (Handle, em_gettextrange, 0, LongInt(@TR));
    if (I = 0) or (C[0] = #13) or (C[0] = #0) then break;
  end;
  Result := N;
end;


function    TRichEditPaxon.TextRange (FromPos, ToPos: Integer): String;
var
  TR: TTextRange;
  I: Integer;
begin
  SetLength (Result, ToPos - FromPos + 1);
  TR.chrg.cpMin := FromPos;
  TR.chrg.cpMax := ToPos;
  TR.lpStrText := PChar(Result);
  I := SendMessage (Handle, em_gettextrange, 0, LongInt(@TR));
  SetLength (Result, I);
end;


procedure   TRichEditPaxon.wmKeyDown (var Msg: TMessage);
const
  MethodName = 'wmKeyDown';

var
  B, E, Y, L: Integer;
  S: string;
  AltPressed, Ctrl, Shift: Boolean;

begin

  AltPressed := ((GetAsyncKeyState (VK_MENU) and $80000000) <> 0);
  Ctrl := ((GetAsyncKeyState (VK_CONTROL) and $80000000) <> 0);
  Shift := ((GetAsyncKeyState (VK_SHIFT) and $80000000) <> 0);

  case (Msg.wParam) of

    vk_return: begin
      if (not Ctrl) or (Ctrl and Shift) then begin
        ShowSelection (false);
        B := ParagraphStart;
        E := ParagraphEnd;
        SelStart := B;
        SelLength := E - B;
        SelAttributes.Color := FColorSentText;
        if TextRange (E, E + 1) <> #13 then begin
          SelStart := E + 1;
          SelLength := 0;
          SelAttributes.Color := FColorNewText;
          SelText := #13#10;
        end else begin
          SelStart := E + 2;
          SelLength := 0;
          SelAttributes.Color := FColorNewText;
        end;
        ShowSelection (true);
        if assigned (OnSendText) then begin
          S := TextRange (B, E);
          if (Shift and Ctrl) then begin
            OnSendText (self, S);
          end else begin
            OnSendText (self, S + #13);
          end;
        end;
        E := SelStart; SelStart := E + 2; SelStart := E;
      end;
    end;

    vk_down: begin
      // X := CaretPos.X;
      Y := CaretPos.Y;
      L := Lines.Count - 1;
      if (Y >= L) then begin
        Lines.Add ('');
        Msg.wParam := 0;
        Msg.lParam := 0;
        Msg.Result := 0;
      end else begin
        inherited;
      end;
    end;

    vk_tab: begin
      if (Shift) then begin
        if (Owner is TCustomForm) then begin
          PostMessage (TCustomForm(Owner).Handle, WM_NEXTDLGCTL, 1, 0);
        end;
      end else begin
        Msg.Result := 0;
      end;
    end;

    ord ('A') .. ord ('Z'): begin
      if (not AltPressed) and (Ctrl) then begin
        if (Shift) then begin
          SelText := '^' + Chr(Msg.wParam);
          Msg.wParam := 0;
          Msg.lParam := 0;
          Msg.Result := 0;
        end else begin
          if (Chr(Msg.wParam) in ['A', 'X', 'C', 'V']) then begin
            inherited;
          end else begin
            Msg.wParam := 0;
            Msg.lParam := 0;
            Msg.Result := 0;
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


procedure   TRichEditPaxon.wmChar (var Msg: TMessage);
begin
  case (Msg.wParam) of
    13, 26, 9: begin
      Msg.wParam := 0;
      Msg.lParam := 0;
      Msg.Result := 0;
    end;
    else begin
      inherited;
    end;
  end;
end;


procedure   TRichEditPaxon.ShowSelection (TheValue: Boolean);
begin
  SendMessage (Handle, em_hideselection, LongInt(not TheValue), 0);
end;


procedure   TRichEditPaxon.wmContextMenu (var Msg: TMessage);
begin
  if (not FInContextMenu) then begin
    FInContextMenu := true;
    try
      inherited;
    finally
      FInContextMenu := false;
    end;
  end else begin
    Abort;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRichEditOleCallback.AfterConstruction;
begin
  inherited;
end;


function    TRichEditOleCallback.ContextSensitiveHelp (fEnterMode: BOOL): HRESULT;
begin
  Result := E_NOTIMPL;
end;


function    TRichEditOleCallback.DeleteObject (oleobj: IOLEObject): HRESULT;
begin
  Result := E_NOTIMPL;
end;


function    TRichEditOleCallback.GetClipboardData (const chrg: TCharRange; reco: DWORD; out dataobj: IDataObject): HRESULT;
begin
  Result := E_NOTIMPL;
end;


function    TRichEditOleCallback.GetContextMenu (seltype: Word; oleobj: IOleObject; const chrg: TCharRange;
                                                 var menu: HMENU): HRESULT;
var
  P: TPoint;
  Handled: Boolean;
begin
  if (not RichEditPaxon.FInContextMenu) then begin
    RichEditPaxon.FInContextMenu := true;
    try
      GetCursorPos (P);
      SendMessage (RichEditPaxon.Handle, wm_cancelmode, 0, 0);
      SendMessage (RichEditPaxon.Handle, wm_lbuttonup, 0, 0);
      SendMessage (RichEditPaxon.Handle, wm_mbuttonup, 0, 0);
      SendMessage (RichEditPaxon.Handle, wm_rbuttonup, 0, 0);
      Handled := false;
      if (assigned (RichEditPaxon.OnContextPopup)) then
        RichEditPaxon.OnContextPopup (RichEditPaxon, RichEditPaxon.ScreenToClient (P), Handled);
      Menu := CreatePopupMenu;
      //PostMessage (RichEditPaxon.Handle, wm_contextmenu, RichEditPaxon.Handle, MakeLong (P.X, P.Y));
    finally
      RichEditPaxon.FInContextMenu := false;
    end;
  end;
  Result := S_OK;
end;


function    TRichEditOleCallback.GetDragDropEffect (fDrag: BOOL; grfKeyState: DWORD; var dwEffect: DWORD): HRESULT;
begin
  Result := E_NOTIMPL;
end;


function    TRichEditOleCallback.GetInPlaceContext (out Frame: IOleInPlaceFrame; out Doc: IOleInPlaceUIWindow;
                                                    var FrameInfo: TOleInPlaceFrameInfo): HRESULT;
begin
  Result :=  E_NOTIMPL;
end;


function    TRichEditOleCallback.GetNewStorage (out Stg: IStorage): HRESULT;
begin
  Result := E_NOTIMPL;
end;


function    TRichEditOleCallback.QueryAcceptData (dataobj: IDataObject; var cfFormat: TClipFormat; reco: DWORD; fReally: BOOL;
                                                  hMetaPict: HGLOBAL): HRESULT;
begin
  cfFormat := CF_Text;
  Result := S_OK;
end;


function    TRichEditOleCallback.QueryInsertObject (const clsid: TCLSID; stg: IStorage; cp: longint): HRESULT;
begin
  Result :=  E_INVALIDARG;
end;


function    TRichEditOleCallback.ShowContainerUI (fShow: BOOL): HRESULT;
begin
  Result :=  E_NOTIMPL;
end;


procedure   TRichEditPaxon.SetColorNewText (const Value: TColor);
begin
  FColorNewText := Value;
  SelStart := 0;
  SelLength := MaxInt;
  SelAttributes.Color := FColorNewText;
  SelStart := MaxInt;
  SelLength := 0;
end;


procedure   TRichEditPaxon.SetColorSentText (const Value: TColor);
begin
  FColorSentText := Value;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure Register;
begin
  RegisterComponents ('Paxon', [TRichEditPaxon]);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization


finalization

  // UnloadRichEdit;

end.

