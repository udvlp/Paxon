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


unit DropTargetU;


interface


uses
  Windows, Messages, SysUtils, Classes, SyncObjs, Controls, Forms, ToolbarU,
  ShellApi, ActiveX, GlobalU, DebOutU, ComCtrls, InterfacesU, ConsoleU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TDropType = (dt_nothing, dt_text, dt_files);


  TDropTarget = class (TInterfacedObject, IDropTarget)
  private
    TimerID1: Cardinal;
    TimerID2: Cardinal;
    ChannelButton: TToolbarElement;
    DropFileArray: array of String;
    DropText: String;
    DropType: TDropType;
    DropChannelNo: Integer;   // channel button the data was dropped on, 0 = current channel
    procedure   Timer;
  public
    procedure   AfterConstruction; override;
    function    DragEnter (const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
    function    DragOver (grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
    function    DragLeave: HResult; stdcall;
    function    Drop (const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
    procedure   Dropped;
  end;


var
  DropTarget: TDropTarget = nil;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  MainU, ChannelsU, SendFileDlgU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TimerProc1 (hwnd: THandle; uMsg: Cardinal; idEvent: Cardinal; dwTime: Cardinal); stdcall;
begin
  DropTarget.Timer;
end;


procedure   TimerProc2 (hwnd: THandle; uMsg: Cardinal; idEvent: Cardinal; dwTime: Cardinal); stdcall;
begin
  DropTarget.Dropped;
end;


procedure   TDropTarget.Timer;
begin
  if (TimerID1 <> 0) then begin
    KillTimer (0, TimerID1);
    TimerID1 := 0;
  end;
  if (assigned (ChannelButton)) then begin
    Application.ProcessMessages;
    ChannelButton.Click;
    Application.ProcessMessages;
  end;
end;


procedure   TDropTarget.AfterConstruction;
const
  MethodName = 'AfterConstruction';

var
  DH: HResult;

begin

  assert (not assigned (DropTarget));

  inherited;

  DropTarget := self;
  TimerID1 := 0;

  DH := RegisterDragDrop (MainWindow.Handle, DropTarget);
  if Succeeded (DH) then begin
    DebOut (self, MethodName, 'Drop: Registered successfully.');
  end else begin
    case DH of
      DRAGDROP_E_INVALIDHWND:        DebOut (self, MethodName, 'Drop: Invalid handle returned in the hwnd parameter.');
      DRAGDROP_E_ALREADYREGISTERED:  DebOut (self, MethodName,
                                             'Drop: The specified window has already been registered as a drop target.');
      E_OUTOFMEMORY:                 DebOut (self, MethodName, 'Drop: Out of memory.');
      else                           DebOut (self, MethodName, 'Drop: Other Error.');
    end;
  end;

end;


function    TDropTarget.DragEnter (const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint;
                                   var dwEffect: Longint): HResult; stdcall;
begin
  DebOut (self, 'DragEnter', '');
  // Determine dwEffect as in DragOver, otherwise the effects allowed by the source remain set
  result := DragOver (grfKeyState, pt, dwEffect);
end;


function    TDropTarget.DragOver (grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
const
  MethodName = 'DragOver';
var
  Control: TControl;
  PC: TPoint;
  Item: TToolbarElement;
  B: Boolean;
  Allowed: Longint;

begin

  Allowed := dwEffect;
  dwEffect := DROPEFFECT_NONE;
  B := false;

  Control := FindDragTarget (pt, false);

  if (Control = MainWindow.ChannelToolbar) then begin

    PC := MainWindow.ChannelToolbar.ScreenToClient (pt);

    Item := MainWindow.ChannelToolbar.ElementAt (PC);

    begin

      if (assigned (Item)) then begin

        if (Item.Tag > 0) then begin

          if (ChannelList[Item.Tag].IsChannelConnected) then dwEffect := DROPEFFECT_COPY;
          if (Item <> ChannelButton) then begin
            if (TimerID1 <> 0) then KillTimer (0, TimerID1);
            TimerID1 := SetTimer (0, 0, 200, @TimerProc1);
            ChannelButton := Item;
          end;

        end;

        B := true;

      end;

    end;

  end;

  if (not B) then begin

    if (TimerID1 <> 0) then begin
      KillTimer (0, TimerID1);
      TimerID1 := 0;
    end;
    // Verlässt der Zeiger die Kanalknöpfe, beim nächsten Überfahren desselben
    // Knopfs wieder umschalten.
    ChannelButton := nil;

    if (Control is TConsole) then begin
      if (ChannelList.CurrentChannel.IsChannelConnected) then begin
        dwEffect := DROPEFFECT_COPY;
      end;
    end;

  end;

  // only effects that the source allows
  dwEffect := dwEffect and Allowed;

  result := S_OK;

end;


function    TDropTarget.DragLeave: HResult; stdcall;
begin
  DebOut (self, 'DragLeave', '');
  if (TimerID1 <> 0) then begin
    KillTimer (0, TimerID1);
    TimerID1 := 0;
  end;
  ChannelButton := nil;
  result := S_OK;
end;


function    TDropTarget.Drop (const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint;
                              var dwEffect: Longint): HResult; stdcall;
var
  FormatEtc: TFormatEtc;
  StgMedium: TStgMedium;
  EnumFormat: IEnumFORMATETC;
  S: String;
  P: PChar;
  N, I: Integer;
  Item: TToolbarElement;

begin

  if (TimerID1 <> 0) then begin
    KillTimer (0, TimerID1);
    TimerID1 := 0;
  end;
  ChannelButton := nil;

  // Target channel from the drop position: the switch timer may not have fired yet
  DropChannelNo := 0;
  if (FindDragTarget (pt, false) = MainWindow.ChannelToolbar) then begin
    Item := MainWindow.ChannelToolbar.ElementAt (MainWindow.ChannelToolbar.ScreenToClient (pt));
    if (assigned (Item)) and (Item.Tag > 0) then DropChannelNo := Item.Tag;
  end;

  Forms.Application.Restore;
  SetForegroundWindow (MainWindow.Handle);

  // Enumerate formats:

  if succeeded (dataObj.EnumFormatEtc (DATADIR_GET, EnumFormat)) then begin
    EnumFormat.Reset;
    while (EnumFormat.Next (1, FormatEtc, nil) = S_OK) do begin
      // ptd belongs to the caller
      if (assigned (FormatEtc.ptd)) then begin
        CoTaskMemFree (FormatEtc.ptd);
        FormatEtc.ptd := nil;
      end;
      case FormatEtc.cfFormat of
        CF_TEXT: S := 'CF_TEXT';
        CF_BITMAP: S := 'CF_BITMAP';
        CF_METAFILEPICT: S := 'CF_METAFILEPICT';
        CF_SYLK: S := 'CF_SYLK';
        CF_DIF: S := 'CF_DIF';
        CF_TIFF: S := 'CF_TIFF';
        CF_OEMTEXT: S := 'CF_OEMTEXT';
        CF_DIB: S := 'CF_DIB';
        CF_PALETTE: S := 'CF_PALETTE';
        CF_PENDATA: S := 'CF_PENDATA';
        CF_RIFF: S := 'CF_RIFF';
        CF_WAVE: S := 'CF_WAVE';
        CF_UNICODETEXT: S := 'CF_UNICODETEXT';
        CF_ENHMETAFILE: S := 'CF_ENHMETAFILE';
        CF_HDROP: S := 'CF_HDROP';
        CF_LOCALE: S := 'CF_LOCALE';
        CF_MAX: S := 'CF_MAX';
        else begin
          SetLength (S, 255);
          SetLength (S, GetClipboardFormatName (FormatEtc.cfFormat, PChar(S), 250));
        end;
      end;
      DebOut (self, 'Drop', 'Format = ''' + S + '''' + #13);
    end;
  end;

  DropType := dt_nothing;

  // File dropped?

  with FormatEtc do begin
    cfFormat := CF_HDROP;
    ptd := nil;
    dwAspect := DVASPECT_CONTENT;
    lindex := -1;
    tymed := TYMED_HGLOBAL;
  end;

  if succeeded (dataObj.GetData (FormatEtc, StgMedium)) then begin

    DropType := dt_files;
    N := DragQueryFile (StgMedium.hGlobal, $FFFFFFFF, nil, 0);
    DebOut (self, 'Drop', 'Anzahl = ' + IntToStr (N) + #13);
    SetLength (DropFileArray, N);
    for I := 0 to N - 1 do begin
      SetLength (S, MAX_PATH);
      SetLength (S, DragQueryFile (StgMedium.hGlobal, I, PChar(S), MAX_PATH));
      DebOut (self, 'Drop', 'Datei = ''' + S + '''' + #13);
      DropFileArray[I] := S;
    end;
    ReleaseStgMedium (StgMedium);

  end;

  if (DropType = dt_nothing) then begin

    // Text dropped?

    with FormatEtc do begin
      cfFormat := CF_TEXT;
      ptd := nil;
      dwAspect := DVASPECT_CONTENT;
      lindex := -1;
      tymed := TYMED_HGLOBAL;
    end;

    if Succeeded (dataObj.GetData (FormatEtc, StgMedium)) then begin
      P := GlobalLock (StgMedium.hGlobal);
      if (assigned (P)) then begin
        DropType := dt_text;
        DebOut (self, 'Drop', 'Text = ''' + String (P) + '''' + #13);
        DropText := P;
        GlobalUnLock (StgMedium.hGlobal);
      end;
      ReleaseStgMedium (StgMedium);
    end;

  end;

  // Tell the source what happened: only copied, never moved, otherwise
  // it deletes e.g. the selected text
  if (DropType <> dt_nothing) and ((dwEffect and DROPEFFECT_COPY) <> 0) then begin

    dwEffect := DROPEFFECT_COPY;
    TimerID2 := SetTimer (0, 0, 10, @TimerProc2);

  end else begin

    dwEffect := DROPEFFECT_NONE;

  end;

  result := S_OK;

end;


procedure   TDropTarget.Dropped;
const
  MethodName = 'Dropped';
begin
  if (TimerID2 <> 0) then begin
    KillTimer (0, TimerID2);
    TimerID2 := 0;
  end;
  if (assigned (ChannelList)) then begin
    if (DropChannelNo > 0) and (DropChannelNo <= ChannelList.Quantity) then begin
      ChannelList.CurrentChannelNo := DropChannelNo;
    end;
    DropChannelNo := 0;
  end;
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    case DropType of
      dt_files: begin
        ChannelList.CurrentChannel.SendFileDialog (DropFileArray);
      end;
      dt_text: begin
        ChannelList.CurrentChannel.SendFileDialog (DropText);
      end;
    end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  OleOk: Boolean = false;


initialization

  // RegisterDragDrop needs OleInitialize (reference-counted, calling it several times is allowed)
  OleOk := Succeeded (OleInitialize (nil));

finalization

  if (OleOk) then OleUninitialize;

end.

