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


unit DragTextU;


// Dragging text from Paxon into other programs (OLE drag and drop).
//
// The data object offers the text as CF_TEXT and CF_UNICODETEXT. Only copying
// is allowed: the console cannot give up text. Both objects are
// reference-counted; a target may keep the data object beyond DoDragDrop.


interface


uses
  Windows, ActiveX;


// Starts dragging and returns only after the drop or cancellation.
// Result: the effect chosen by the target, DROPEFFECT_NONE on cancellation.
function    DragText (const Text: String): Longint;

// The data object with the text (for DragText, also for tests and the clipboard)
function    TextDataObject (const Text: String): IDataObject;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


type

  TTextDataObject = class (TInterfacedObject, IDataObject)
  private
    FText: String;
    FWideText: WideString;
    FDataFormats: array[0..1] of TFormatEtc;
    function    FormatIndex (const Format: TFormatEtc): Integer;
  public
    constructor create (const aText: String);
    // IDataObject
    function    GetData (const formatetcIn: TFormatEtc; out medium: TStgMedium): HResult; stdcall;
    function    GetDataHere (const formatetc: TFormatEtc; out medium: TStgMedium): HResult; stdcall;
    function    QueryGetData (const formatetc: TFormatEtc): HResult; stdcall;
    function    GetCanonicalFormatEtc (const formatetc: TFormatEtc; out formatetcOut: TFormatEtc): HResult; stdcall;
    function    SetData (const formatetc: TFormatEtc; var medium: TStgMedium; fRelease: BOOL): HResult; stdcall;
    function    EnumFormatEtc (dwDirection: Longint; out enumFormatEtc: IEnumFormatEtc): HResult; stdcall;
    function    DAdvise (const formatetc: TFormatEtc; advf: Longint; const advSink: IAdviseSink;
                         out dwConnection: Longint): HResult; stdcall;
    function    DUnadvise (dwConnection: Longint): HResult; stdcall;
    function    EnumDAdvise (out enumAdvise: IEnumStatData): HResult; stdcall;
  end;

  TTextDragSource = class (TInterfacedObject, IDropSource)
  public
    function    QueryContinueDrag (fEscapePressed: BOOL; grfKeyState: Longint): HResult; stdcall;
    function    GiveFeedback (dwEffect: Longint): HResult; stdcall;
  end;


// Enumeration of the formats by the shell (Windows 2000 and later)
function    SHCreateStdEnumFmtEtc (cfmt: UINT; afmt: PFormatEtc;
                                   out ppenumFormatEtc: IEnumFormatEtc): HResult; stdcall; external 'shell32.dll';


var
  OleOk: Boolean = false;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TextDataObject (const Text: String): IDataObject;
begin
  Result := TTextDataObject.create (Text);
end;


function    DragText (const Text: String): Longint;
var
  DragDataObject: IDataObject;
  SourceReg: IDropSource;
  DragEffect: Longint;
begin
  DragDataObject := TextDataObject (Text);
  SourceReg := TTextDragSource.create;
  DragEffect := DROPEFFECT_NONE;
  if (DoDragDrop (DragDataObject, SourceReg, DROPEFFECT_COPY, DragEffect) = DRAGDROP_S_DROP) then begin
    Result := DragEffect;
  end else begin
    Result := DROPEFFECT_NONE;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TTextDataObject.create (const aText: String);
var
  I: Integer;
begin
  inherited create;
  FText := aText;
  FWideText := aText;
  for I := Low (FDataFormats) to High (FDataFormats) do begin
    FDataFormats[I].ptd := nil;
    FDataFormats[I].dwAspect := DVASPECT_CONTENT;
    FDataFormats[I].lindex := -1;
    FDataFormats[I].tymed := TYMED_HGLOBAL;
  end;
  FDataFormats[0].cfFormat := CF_UNICODETEXT;
  FDataFormats[1].cfFormat := CF_TEXT;
end;


function    TTextDataObject.FormatIndex (const Format: TFormatEtc): Integer;
var
  I: Integer;
begin
  Result := -1;
  if (Format.dwAspect <> DVASPECT_CONTENT) or ((Format.tymed and TYMED_HGLOBAL) = 0) then exit;
  for I := Low (FDataFormats) to High (FDataFormats) do begin
    if (Format.cfFormat = FDataFormats[I].cfFormat) then begin
      Result := I;
      exit;
    end;
  end;
end;


function    TTextDataObject.GetData (const formatetcIn: TFormatEtc; out medium: TStgMedium): HResult;
var
  I, L: Integer;
  H: HGLOBAL;
  P: Pointer;
begin
  FillChar (medium, SizeOf (medium), 0);
  I := FormatIndex (formatetcIn);
  if (I < 0) then begin
    Result := DV_E_FORMATETC;
    exit;
  end;
  // Length in bytes including the terminating null
  if (FDataFormats[I].cfFormat = CF_UNICODETEXT) then begin
    L := (Length (FWideText) + 1) * SizeOf (WideChar);
  end else begin
    L := Length (FText) + 1;
  end;
  H := GlobalAlloc (GMEM_MOVEABLE, L);
  if (H = 0) then begin
    Result := E_OUTOFMEMORY;
    exit;
  end;
  P := GlobalLock (H);
  if (not assigned (P)) then begin
    GlobalFree (H);
    Result := E_OUTOFMEMORY;
    exit;
  end;
  FillChar (P^, L, 0);
  if (FDataFormats[I].cfFormat = CF_UNICODETEXT) then begin
    if (Length (FWideText) > 0) then Move (FWideText[1], P^, Length (FWideText) * SizeOf (WideChar));
  end else begin
    if (Length (FText) > 0) then Move (FText[1], P^, Length (FText));
  end;
  GlobalUnlock (H);
  medium.tymed := TYMED_HGLOBAL;
  medium.hGlobal := H;
  Result := S_OK;
end;


function    TTextDataObject.GetDataHere (const formatetc: TFormatEtc; out medium: TStgMedium): HResult;
begin
  Result := E_NOTIMPL;
end;


function    TTextDataObject.QueryGetData (const formatetc: TFormatEtc): HResult;
begin
  if (FormatIndex (formatetc) >= 0) then Result := S_OK else Result := DV_E_FORMATETC;
end;


function    TTextDataObject.GetCanonicalFormatEtc (const formatetc: TFormatEtc; out formatetcOut: TFormatEtc): HResult;
begin
  formatetcOut := formatetc;
  formatetcOut.ptd := nil;
  Result := DATA_S_SAMEFORMATETC;
end;


function    TTextDataObject.SetData (const formatetc: TFormatEtc; var medium: TStgMedium; fRelease: BOOL): HResult;
begin
  Result := E_NOTIMPL;
end;


function    TTextDataObject.EnumFormatEtc (dwDirection: Longint; out enumFormatEtc: IEnumFormatEtc): HResult;
begin
  if (dwDirection = DATADIR_GET) then begin
    Result := SHCreateStdEnumFmtEtc (Length (FDataFormats), @FDataFormats[0], enumFormatEtc);
  end else begin
    enumFormatEtc := nil;
    Result := E_NOTIMPL;
  end;
end;


function    TTextDataObject.DAdvise (const formatetc: TFormatEtc; advf: Longint; const advSink: IAdviseSink;
                                     out dwConnection: Longint): HResult;
begin
  dwConnection := 0;
  Result := OLE_E_ADVISENOTSUPPORTED;
end;


function    TTextDataObject.DUnadvise (dwConnection: Longint): HResult;
begin
  Result := OLE_E_ADVISENOTSUPPORTED;
end;


function    TTextDataObject.EnumDAdvise (out enumAdvise: IEnumStatData): HResult;
begin
  enumAdvise := nil;
  Result := OLE_E_ADVISENOTSUPPORTED;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    TTextDragSource.QueryContinueDrag (fEscapePressed: BOOL; grfKeyState: Longint): HResult;
begin
  if (fEscapePressed) then begin
    Result := DRAGDROP_S_CANCEL;
  end else if ((grfKeyState and MK_LBUTTON) = 0) then begin
    Result := DRAGDROP_S_DROP;
  end else begin
    Result := S_OK;
  end;
end;


function    TTextDragSource.GiveFeedback (dwEffect: Longint): HResult;
begin
  Result := DRAGDROP_S_USEDEFAULTCURSORS;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  // DoDragDrop and RegisterDragDrop (DropTargetU) need OleInitialize, not just CoInitialize
  OleOk := Succeeded (OleInitialize (nil));

finalization

  if (OleOk) then OleUninitialize;

end.
