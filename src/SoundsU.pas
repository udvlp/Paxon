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


unit SoundsU;


interface


uses
  Windows, Classes, SysUtils, Messages, SyncObjs,
  InterfacesU, QueueU, SoundsConstsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TPlaySeqThread = class;


  TSoundEventRec = record
    Loaded: Boolean;
    Signal: TSignalType;
    SignalWavFile: String;
    Announcement: TAnnouncementType;
  end;


  TPlaying = (pl_none, pl_lowpriority, pl_highpriority);

  TSounds = class
  private

    CriticalSection: TCriticalSection;
    Queue: TQueue;
    PlaySeqThread: TPlaySeqThread;
    Playing: TPlaying;
    GlobalSounds: array [low(TSoundEvent)..high (TSoundEvent)] of TSoundEventRec;

    procedure   LoadGlobal (Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                            var Announcement: TAnnouncementType);
    procedure   SaveGlobal (Event: TSoundEvent; Signal: TSignalType; SignalWavFile: String; Announcement: TAnnouncementType);
    function    LoadCall (Call: String; Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                          var Announcement: TAnnouncementType): Boolean;
    procedure   SaveCall (Call: String; Event: TSoundEvent; Signal: TSignalType; SignalWavFile: String;
                          Announcement: TAnnouncementType);

  public

    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    function    PlayEvent (aEvent: TSoundEvent; aConnectionObj: IConnection = nil): Boolean;
    procedure   Load (Call: String; Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                      var Announcement: TAnnouncementType);
    procedure   Save (Call: String; Event: TSoundEvent; Signal: TSignalType; SignalWavFile: String;
                      Announcement: TAnnouncementType);
    procedure   DeleteCall (Call: String; Event: TSoundEvent);

  end;


  TPlaySeqThread = class (TThread)
    procedure   Execute; override;
  private
    FCaughtException: Exception;
    procedure   ShowSoundError;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  Sounds: TSounds;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  Forms, GlobalU, Registry, StationDatabaseU, MMsystem, DebOutU,
  UnhandledExceptionU, SoundsPCSpkU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  PSoundEventEntry = ^TSoundEventEntry;
  TSoundEventEntry = record
    Event: TSoundEvent;
    Signal: TSignalType;
    SignalWavFile: String;
    Announcement: TAnnouncementType;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSounds.AfterConstruction;
var
  E: TSoundEvent;

begin

  assert (not assigned (Sounds));

  inherited;

  Sounds := self;

  CriticalSection := TCriticalSection.create;

  for E := Low (GlobalSounds) to High (GlobalSounds) do GlobalSounds[E].Loaded := false;

  Queue := TQueue.create;

  PlaySeqThread := TPlaySeqThread.create (true);
  PlaySeqThread.Priority := tpHighest;
  PlaySeqThread.Resume;

end;


procedure   TSounds.BeforeDestruction;
const
  MethodName = 'BeforeDestruction';

var
  L: Integer;
  B: Boolean;
  H: Integer;

begin

  CriticalSection.Enter;
  CriticalSection.Leave;

  if (assigned (PlaySeqThread)) then begin

    H := PlaySeqThread.Handle;
    DebOut (self, MethodName, 'PlaySeqThread.Terminate');
    PlaySeqThread.Terminate;

    L := GetTickCount;
    B := False;

    DebOut (self, MethodName, 'Warte auf Beendigung');
    repeat
      if (PlaySeqThread = nil) or (WaitForSingleObject (H, 50) = wait_object_0) then begin
        B := true;
        break;
      end;
      Application.ProcessMessages;
      if (GetCurrentThreadID = MainThreadID) then CheckSynchronize;
    until (GetTickCount > DWord (L + 8000));

    if (B) then begin
      DebOut (self, MethodName, 'PlaySeqThread normal beendet.');
    end else begin
      DebOut (self, MethodName, 'PlaySeqThread wird abgebrochen...');
      PlaySeqThread := nil;
      try
        TerminateThread (H, 1);
      except
      end;
      DebOut (self, MethodName, 'PlaySeqThread wurde abgebrochen.');
    end;

  end;

  Queue.free;

  CriticalSection.free;

  inherited;

  Sounds := nil;

end;


function    TSounds.PlayEvent (aEvent: TSoundEvent; aConnectionObj: IConnection = nil): Boolean;
var
  Call: String;
  St: TSignalType;
  Sw: String;
  At: TAnnouncementType;
  Pl: TPlaying;
  SoundEventEntry: PSoundEventEntry;
  DisposeSoundEventEntry: Boolean;
  B: Boolean;

begin

  result := false;

  New (SoundEventEntry);
  DisposeSoundEventEntry := true;
  SoundEventEntry.Event := aEvent;

  if (not SoundEvents(aEvent).OnlyGlobal) and (assigned (aConnectionObj)) then begin
    Call := aConnectionObj.Call;
    B := LoadCall (Call, aEvent, SoundEventEntry.Signal, SoundEventEntry.SignalWavFile, SoundEventEntry.Announcement);
    if (not B) then begin
      Call := StripSSID (Call);
      B := LoadCall (Call, aEvent, SoundEventEntry.Signal, SoundEventEntry.SignalWavFile, SoundEventEntry.Announcement);
    end;
  end else begin
    B := false;
  end;

  if (not B) then begin
    SoundEventEntry.Signal := st_undefined;
    SoundEventEntry.SignalWavFile := '';
    SoundEventEntry.Announcement := at_undefined;
  end;

  if (SoundEventEntry.Signal = st_undefined) or (SoundEventEntry.Announcement = at_undefined) then begin

    LoadGlobal (aEvent, St, Sw, At);

    if (SoundEventEntry.Signal = st_undefined) then begin
      SoundEventEntry.Signal := St;
      SoundEventEntry.SignalWavFile := Sw;
    end;

    if (SoundEventEntry.Announcement = at_undefined) then begin
      SoundEventEntry.Announcement := At;
    end;

  end;

  if (SoundEventEntry.Signal > st_silence) or (SoundEventEntry.Announcement > at_silence) then begin
    if (SoundEvents(SoundEventEntry.Event).Parallel) then begin
      CriticalSection.Enter;
      try
        Pl := Playing;
      finally
        CriticalSection.Leave;
      end;
      if (Pl = pl_none) or ((Pl = pl_lowpriority) and (not SoundEvents(SoundEventEntry.Event).LowPriority)) then begin
        Queue.Enqueue (SoundEventEntry);
        DisposeSoundEventEntry := false;
        result := true;
      end;
    end else begin
      Queue.Enqueue (SoundEventEntry);
      DisposeSoundEventEntry := false;
      result := true;
    end;
  end;

  if (DisposeSoundEventEntry) then begin
    Dispose (SoundEventEntry);
  end;

end;


procedure   TSounds.Load (Call: String; Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                          var Announcement: TAnnouncementType);
const
  MethodName = 'Load';
begin
  CriticalSection.Enter;
  try
    if (Call = '') then begin
      DebOut (self, MethodName, '*');
      LoadGlobal (Event, Signal, SignalWavFile, Announcement);
    end else begin
      DebOut (self, MethodName, Call);
      LoadCall (Call, Event, Signal, SignalWavFile, Announcement);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TSounds.Save (Call: String; Event: TSoundEvent; Signal: TSignalType; SignalWavFile: String;
                          Announcement: TAnnouncementType);
begin
  CriticalSection.Enter;
  try
    if (Call = '') then begin
      SaveGlobal (Event, Signal, SignalWavFile, Announcement);
    end else begin
      SaveCall (Call, Event, Signal, SignalWavFile, Announcement);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TSounds.LoadGlobal (Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                                var Announcement: TAnnouncementType);
var
  S: String;
  I: Integer;
  Reg: TRegistry;

begin

  CriticalSection.Enter;

  try

    if (not GlobalSounds[Event].Loaded) then begin

      Reg := TRegistry.Create (KEY_READ or KEY_WRITE);

      try

        Reg.RootKey := HKEY_CURRENT_USER;

        S := Format ('%2.2d', [SoundEvents(Event).ID]);
        if (Reg.OpenKey (RootRegKey + '\Sounds\' + S, true)) then begin
          try

            if (Reg.ValueExists ('Signal')) then begin
              try
                I := Reg.ReadInteger ('Signal');
              except
                I := -1;
              end;
            end else begin
              I := -1;
            end;

            if (I >= Ord (Low (TSignalType))) and (I <= Ord (High (TSignalType))) then
              GlobalSounds[Event].Signal := TSignalType (I)
            else
              GlobalSounds[Event].Signal := Low (TSignalType);

            if (Reg.ValueExists ('SignalWavFile')) then begin
              try
                GlobalSounds[Event].SignalWavFile := Reg.ReadString ('SignalWavFile');
              except
                GlobalSounds[Event].SignalWavFile := '';
              end;
            end else begin
              GlobalSounds[Event].SignalWavFile := '';
            end;

            if (Reg.ValueExists ('Announcement')) then begin
              try
                I := Reg.ReadInteger ('Announcement');
              except
                I := -1;
              end;
            end else begin
              I := -1;
            end;
            if (I >= Ord (Low (TAnnouncementType))) and (I <= Ord (High (TAnnouncementType))) then
              GlobalSounds[Event].Announcement := TAnnouncementType (I)
            else
              GlobalSounds[Event].Announcement := Low (TAnnouncementType);

          finally
            Reg.CloseKey;
          end;

        end;

      finally
        Reg.free;
      end;

      GlobalSounds[Event].Loaded := true;

    end;

    Signal := GlobalSounds[Event].Signal;
    SignalWavFile := GlobalSounds[Event].SignalWavFile;
    Announcement := GlobalSounds[Event].Announcement;

  finally
    CriticalSection.Leave;
  end;

end;


procedure   TSounds.SaveGlobal (Event: TSoundEvent; Signal: TSignalType; SignalWavFile: String; Announcement: TAnnouncementType);
var
  S: String;
  Reg: TRegistry;

begin

  CriticalSection.Enter;

  try

    GlobalSounds[Event].Signal := Signal;
    GlobalSounds[Event].SignalWavFile := SignalWavFile;
    GlobalSounds[Event].Announcement := Announcement;
    GlobalSounds[Event].Loaded := true;

    Reg := TRegistry.Create (KEY_READ or KEY_WRITE);
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      S := Format ('%2.2d', [SoundEvents(Event).ID]);
      if (Reg.OpenKey (RootRegKey + '\Sounds\' + S, true)) then begin
        try
          Reg.WriteInteger ('Signal', Integer(Signal));
          Reg.WriteString  ('SignalWavFile', SignalWavFile);
          Reg.WriteInteger ('Announcement', Integer(Announcement));
        finally
          Reg.CloseKey;
        end;
      end;
    finally
      Reg.free;
    end;

  finally
    CriticalSection.Leave;
  end;

end;


function    TSounds.LoadCall (Call: String; Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                              var Announcement: TAnnouncementType): Boolean;
var
  E: IStationDatabaseEntry;
begin
  CriticalSection.Enter;
  try
    result := false;
    E := StationDatabase.Open (Call);
    if (assigned (E)) then begin
      E.GetSoundEvent (Event, Signal, SignalWavFile, Announcement);
      result := true;
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TSounds.SaveCall (Call: String; Event: TSoundEvent; Signal: TSignalType; SignalWavFile: String;
                              Announcement: TAnnouncementType);
var
  E: IStationDatabaseEntry;
begin
  CriticalSection.Enter;
  try
    E := StationDatabase.Open (Call);
    if (assigned (E)) then begin
      E.SetSoundEvent (Event, Signal, SignalWavFile, Announcement);
    end;
  finally
    CriticalSection.Leave;
  end;
end;


procedure   TSounds.DeleteCall (Call: String; Event: TSoundEvent);
var
  E: IStationDatabaseEntry;
begin
  CriticalSection.Enter;
  try
    if (Length (Call) > 0) then begin
      E := StationDatabase.Open (Call);
      if (assigned (E)) then begin
        E.DeleteSoundEvent (Event);
      end;
    end;
  finally
    CriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TPlaySeqThread.ShowSoundError;
// Runs in the main thread via Synchronize
begin
  ShowUnhandledException (FCaughtException, ClassName, 'Execute');
end;


procedure   TPlaySeqThread.Execute;
const
  MethodName = 'Execute';
var
  I, N: Cardinal;
  SoundEventEntry: PSoundEventEntry;
  Pl: TPlaying;

begin

  try

    while (true) do begin

      N := WaitForMultipleObjects ([Sounds.Queue.Event.Handle, QuitEvent.Handle], INFINITE);

      case N of

        WAIT_OBJECT_0: begin

          SoundEventEntry := Sounds.Queue.Dequeue;

          if (assigned (SoundEventEntry)) then begin

            try

              if (SoundEvents(SoundEventEntry.Event).LowPriority) then Pl := pl_lowpriority else Pl := pl_highpriority;

              Sounds.CriticalSection.Enter;
              Sounds.Playing := Pl;
              Sounds.CriticalSection.Leave;

              if (SoundEventEntry.Signal = st_wave) and (SoundEventEntry.SignalWavFile <> '') then begin
                if (FileExists (SoundEventEntry.SignalWavFile)) then begin
                  PlaySound (PChar(SoundEventEntry.SignalWavFile), 0, SND_SYNC or SND_FILENAME or SND_NODEFAULT);
                end;
              end else if (SoundEventEntry.Signal = st_pcspk) then begin
                case SoundEventEntry.Event of
                  se_connecting: begin
                    Sound (698, 20);
                    sleep (20);
                  end;
                  se_connected_in: begin
                    Sound (523, 80);
                    Sound (698, 80);
                    sleep (160);
                  end;
                  se_connected_out: begin
                    Sound (698, 80);
                    Sound (523, 80);
                    sleep (160);
                  end;
                  se_disconnecting: begin
                    Sound (196, 20);
                    sleep (20);
                  end;
                  se_disconnected: begin
                    Sound (196, 160);
                    sleep (80);
                  end;
                  se_linkfailure: begin
                    Sound (131, 160);
                    sleep (80);
                  end;
                  se_ring: begin
                    for I := 1 to 8 do begin
                      Sound (523, 20);
                      Sound (659, 20);
                      Sound (784, 20);
                    end;
                  end;
                  se_rx_active: begin
                    Sound (1175, 20);
                    sleep (140);
                  end;
                  se_rx_inactive: begin
                    Sound (1047, 20);
                    sleep (140);
                  end;
                  se_tx: begin
                    Sound (748, 20);
                    sleep (140);
                  end;
                  se_transfer_start: begin
                    Sound (523, 80);
                    Sound (494, 80);
                    Sound (523, 80);
                    sleep (80);
                  end;
                  se_transfer_success: begin
                    Sound (494, 80);
                    Sound (523, 80);
                    Sound (494, 80);
                    sleep (80);
                  end;
                  se_transfer_cancel: begin
                    Sound (262, 80);
                    sleep (80);
                  end;
                  se_transfer_error: begin
                    Sound (196, 80);
                    sleep (80);
                  end;
                  se_pgp_valid: begin
                    Sound (196, 80);
                    Sound (196, 784);
                  end;
                  se_pgp_unknown: begin
                    Sound (262, 40);
                    sleep (40);
                    Sound (262, 40);
                    sleep (40);
                  end;
                  se_pgp_wrong: begin
                    Sound (262, 40);
                    sleep (40);
                    Sound (262, 40);
                    sleep (40);
                    Sound (262, 40);
                    sleep (40);
                    Sound (262, 40);
                    sleep (40);
                  end;
                  se_channelswitch: begin
                    Sound (200, 20);
                    sleep (20);
                  end;
                  se_programstart: begin
                    Sleep (640);
                    Sound (262, 160);
                    Sound (330, 160);
                    Sound (392, 160);
                    Sound (523, 320);
                    sleep (160);
                  end;
                  se_programend: begin
                    Sound (523, 80);
                    Sound (262, 160);
                  end;
                end;
              end;

            finally

              Sounds.CriticalSection.Enter;
              Sounds.Playing := pl_none;
              Sounds.CriticalSection.Leave;

            end;

            Dispose (SoundEventEntry);

          end;
        end;

        else begin
          break;
        end;

      end;

    end;

  except
    on E: Exception do begin
      // Do not show a VCL form in the playback thread; instead output the
      // error message in the main thread
      FCaughtException := E;
      Synchronize (ShowSoundError);
      FCaughtException := nil;
      raise
    end;
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  Sounds := nil;

end.

