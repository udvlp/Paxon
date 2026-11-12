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


unit SynchronizeU;


interface


uses
  Windows, Messages, Classes, SysUtils;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   Synchronize (aMethod: TThreadMethod);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, SyncObjs, UnhandledExceptionU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  SyncWindow: THandle;

const
  WindowClassName = 'PaxonSyncWindow';
  wm_execproc = WM_USER + $4011;

type
  PThreadMethod = ^TThreadMethod;


function    SyncWndProc (Window: HWND; Msg, wParam, lParam: Longint): Longint; stdcall;
begin
  case Msg of
    wm_execproc: begin
      if (Cardinal(wParam) = Cardinal($d3adb3af)) then begin
        assert (LongInt(lParam) <> 0);
        try
          PThreadMethod(lParam)^;
        except
          on E: Exception do ShowUnhandledException (E, 'SYNCHRONIZE', 'SyncWndProc');
        end;
      end;
      Result := 0;
    end;
    else begin
      Result := DefWindowProc (Window, Msg, wParam, lParam);
    end;
  end;
end;


procedure   Synchronize (aMethod: TThreadMethod);
begin
  if (GetCurrentThreadID = MainThreadID) then begin
    aMethod;
  end else begin
    assert (isWindow (SyncWindow));
    SendMessage (SyncWindow, wm_execproc, LongInt($d3adb3af), LongInt(@@aMethod));
  end;
end;


procedure   CreateSyncWindow;
var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
  SyncWindowClass: TWndClass;

begin

  SyncWindowClass.style := 0;
  SyncWindowClass.lpfnWndProc := @SyncWndProc;
  SyncWindowClass.cbClsExtra := 0;
  SyncWindowClass.cbWndExtra := sizeof (Pointer);
  SyncWindowClass.hIcon := 0;
  SyncWindowClass.hCursor := 0;
  SyncWindowClass.hbrBackground := 0;
  SyncWindowClass.lpszMenuName := nil;
  SyncWindowClass.lpszClassName := PChar(WindowClassName);
  SyncWindowClass.hInstance := HInstance;

  ClassRegistered := GetClassInfo (HInstance, SyncWindowClass.lpszClassName, TempClass);

  if (not ClassRegistered) or (TempClass.lpfnWndProc <> @SyncWndProc) then begin
    if (ClassRegistered) then Windows.UnregisterClass (SyncWindowClass.lpszClassName, HInstance);
    Windows.RegisterClass (SyncWindowClass);
  end;

  SyncWindow := CreateWindow (SyncWindowClass.lpszClassName, '', 0, 0, 0, 0, 0, 0, 0, HInstance, nil);

end;


procedure   DestroySyncWindow;
begin
  if (SyncWindow <> 0) then begin
    DestroyWindow (SyncWindow);
    SyncWindow := 0;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  DebOut ('SynchronizeU.initialization: begin...');
  CreateSyncWindow;
  DebOut ('SynchronizeU.initialization: end.');

finalization

  DestroySyncWindow;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

