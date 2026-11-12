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


unit CheckInstanceU;


interface


uses
  Windows, Messages, LanguagesU;


const
  wm_activate_instance = WM_USER + $4021;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, Classes, SysUtils, SyncObjs,
  ComCtrls, GlobalU;


var
  InstanceWindow: THandle;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  InstanceWindowClassName = 'PaxonInstanceWindow';


function    InstanceWndProc (Window: HWND; Message, wParam, lParam: Longint): Longint; stdcall;
begin
  Result := DefWindowProc (Window, Message, wParam, lParam);
end;


procedure   CreateInstanceWindow;
var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
  InstanceWindowClass: TWndClass;

begin

  InstanceWindowClass.style := 0;
  InstanceWindowClass.lpfnWndProc := @InstanceWndProc;
  InstanceWindowClass.cbClsExtra := 0;
  InstanceWindowClass.cbWndExtra := sizeof (Pointer);
  InstanceWindowClass.hIcon := 0;
  InstanceWindowClass.hCursor := 0;
  InstanceWindowClass.hbrBackground := 0;
  InstanceWindowClass.lpszMenuName := nil;
  InstanceWindowClass.lpszClassName := PChar(InstanceWindowClassName);
  InstanceWindowClass.hInstance := HInstance;

  ClassRegistered := GetClassInfo (HInstance, InstanceWindowClass.lpszClassName, TempClass);

  if (not ClassRegistered) or (TempClass.lpfnWndProc <> @InstanceWndProc) then begin
    if (ClassRegistered) then Windows.UnregisterClass (InstanceWindowClass.lpszClassName, HInstance);
    Windows.RegisterClass (InstanceWindowClass);
  end;

  InstanceWindow := CreateWindow (InstanceWindowClass.lpszClassName, '', 0, 0, 0, 0, 0, 0, 0, HInstance, nil);

end;


procedure   DestroyInstanceWindow;
begin
  if (InstanceWindow <> 0) then begin
    DestroyWindow (InstanceWindow);
    InstanceWindow := 0;
  end;
end;


procedure   InitPrevInstance;
var
  H: THandle;
begin
  H := FindWindow (InstanceWindowClassName, nil);
  if (H <> 0) then begin
    H := FindWindow (nil, WindowCaptionName);
    if (H <> 0) then begin
      SetForegroundWindow (H);
      PostMessage (H, wm_activate_instance, 0, 0);
    end;
    Halt (2);
  end;
  CreateInstanceWindow;
end;


procedure   FinalizePrevInstance;
begin
  DestroyInstanceWindow;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  InitPrevInstance;

finalization

  FinalizePrevInstance;

end.

