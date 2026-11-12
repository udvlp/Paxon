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


unit SoundsPCSpkU;


interface


uses
  Windows;


var
  Sound: procedure (ToneFrequency, ToneDuration: Integer);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure Sound95On (Freq: Word); assembler;
asm
       MOV   CX, SP
       MOV   CX, Freq
       MOV   AX, 34DDH
       MOV   DX, 0012H
       CMP   DX, CX
       JNC   @@2
       DIV   CX
       MOV   CX, AX
       IN    AL, 61H
       TEST  AL, 3
       JNZ   @@1
       OR    AL, 3
       OUT   61H, AL
       MOV   AL, 0B6H
       OUT   43H, AL
  @@1: MOV   AL, CL
       OUT   42H, AL
       MOV   AL, CH
       OUT   42H, AL
  @@2:
end;


procedure Sound95Off; assembler;
asm
       IN    AL, 61H
       AND   AL, 0FCH
       OUT   61H, AL
end;


procedure Sound95 (ToneFrequency, ToneDuration: Integer);
begin
  Sound95On (ToneFrequency);
  Sleep (ToneDuration);
  Sound95Off;
end;


procedure SoundNT (ToneFrequency, ToneDuration: Integer);
begin
  Beep (ToneFrequency, ToneDuration);
end;


function IsWin95: Boolean;
var
  Ver: TOSVERSIONINFO;
begin
  Ver.dwOSVersionInfoSize := SizeOf (Ver);
  GetVersionEx (Ver);
  Result := (Ver.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  if IsWin95 then Sound := Sound95 else Sound := SoundNT;

end.

