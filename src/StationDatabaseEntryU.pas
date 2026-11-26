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


unit StationDatabaseEntryU;


interface


uses
  Windows, SysUtils, Classes, InterfacesU, GlobalU, SyncObjs, ActiveX, Forms,
  SoundsConstsU, TextsConstsU;


// Stream names:
// N     Name
// T     Type
// P??*  Password
// S??   Sound
// X??   Text
// R     Remote
// C     Notes

type

  TValueState = (vs_uninitialized, vs_loaded, vs_changed);

  TStationDatabaseEntry = class (TInterfacedObject, IStationDatabaseEntry)

  private

    FCall: String;
    FStorage: IStorage;
    FCriticalSection: TCriticalSection;

    FStateT: TValueState;
    FStateR: TValueState;

    FEntryType: TStationType;
    FIncomingConnect: TIncomingConnect;

    FRemoteCommands: TStringList;

    function    GetCall: String;

    procedure   SetName (const Value: String);
    function    GetName: String;

    procedure   SetNotes (const Value: String);
    function    GetNotes: String;

    procedure   LoadT;
    function    SaveT: Boolean;

    procedure   SetStationType (const Value: TStationType);
    function    GetStationType: TStationType;

    procedure   SetIncomingConnect (const Value: TIncomingConnect);
    function    GetIncomingConnect: TIncomingConnect;

    function    GetStorage: IStorage;
    procedure   SetStorage (const Value: IStorage);

    procedure   LoadRemoteCommandList;
    function    SaveRemoteCommandList: Boolean;

    function    CommitDatabase: Boolean;

  public

    constructor create (const aCall: String); virtual;

    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;

    procedure   Save (ReleaseStorage: Boolean);

    property    Storage: IStorage read GetStorage write SetStorage;

    property    Call: String read GetCall;
    property    Name: String read GetName write SetName;
    property    EntryKind: TStationType read GetStationType write SetStationType;
    property    IncomingConnect: TIncomingConnect read GetIncomingConnect write SetIncomingConnect;
    property    Notes: String read GetNotes write SetNotes;

    procedure   SetPasswordValue (const aMycall: string; aPasswordKind: TPasswordKind; aPasswordMethod: TPasswordMethod;
                                  aPasswordStr: String);
    function    GetPasswordValue (const aMycall: string; aPasswordKind: TPasswordKind;
                                  aPasswordMethod: TPasswordMethod): String; overload;
    function    GetPasswordValue (const StreamName: string): String; overload;
    function    DeletePassword (const StreamName: string): String; overload;

    class procedure PasswordStreamNameToStrings (StreamName: string; var aMycall: string; var aPasswordKind: TPasswordKind;
                                                 var aPasswordMethod: TPasswordMethod);
    class procedure PasswordStringsToStreamName (aMycall: string; aPasswordKind: TPasswordKind; aPasswordMethod: TPasswordMethod;
                                                 var StreamName: string);

    function    _release: Integer; stdcall;

    procedure   GetSoundEvent (Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                               var Announcement: TAnnouncementType);
    function    SetSoundEvent (Event: TSoundEvent; Signal: TSignalType; const SignalWavFile: String;
                               Announcement: TAnnouncementType): Boolean;
    procedure   DeleteSoundEvent (Event: TSoundEvent);

    procedure   GetText (TextKind: TTextKind; var Text: String; var DefaultTextBefore: Boolean);
    function    SetText (TextKind: TTextKind; const Text: String; const DefaultTextBefore: Boolean): Boolean;
    procedure   DeleteText (TextKind: TTextKind);

    function    GetRemoteCommand (const aCommand: String; var State: Boolean): Boolean;
    procedure   SetRemoteCommand (const aCommand: String; const State: Boolean);
    procedure   DeleteRemoteCommand (const aCommand: String);

  end;


// Reads a freshly opened stream completely (Stat.cbSize bytes from position 0) or
// writes a string completely. Result false if not everything could be read or written
// (also if the position was not at the start when reading).

function    ReadStreamComplete (const Stream: IStream; var S: String): Boolean;
function    WriteStreamComplete (const Stream: IStream; const S: String): Boolean;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, StationDatabaseU, SoundsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  StorageMode = STGM_READWRITE or STGM_SHARE_EXCLUSIVE or STGM_DIRECT;
                // STGM_DELETEONRELEASE not supported

  StreamMode = STGM_READWRITE or STGM_SHARE_EXCLUSIVE or STGM_DIRECT;
               // Transacted mode not supported
               // STGM_SHARE_EXCLUSIVE is mandatory
               // STGM_DELETEONRELEASE not supported


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    ReadStreamComplete (const Stream: IStream; var S: String): Boolean;
var
  Stat: TStatStg;
  N, P, L: LongInt;
  R: HResult;
begin
  S := '';
  result := false;
  if (not assigned (Stream)) then exit;
  R := Stream.Stat (Stat, STATFLAG_NONAME);
  if (Failed (R)) or (Stat.cbSize < 0) or (Stat.cbSize > MaxInt) then exit;
  N := Stat.cbSize;
  SetLength (S, N);
  P := 0;
  while (P < N) do begin
    L := 0;
    R := Stream.Read (@S[P + 1], N - P, @L);
    if (Failed (R)) or (L <= 0) then break;
    inc (P, L);
  end;
  SetLength (S, P);
  result := (P = N);
end;


function    WriteStreamComplete (const Stream: IStream; const S: String): Boolean;
var
  N, P, L: LongInt;
  R: HResult;
begin
  result := false;
  if (not assigned (Stream)) then exit;
  N := Length (S);
  P := 0;
  while (P < N) do begin
    L := 0;
    R := Stream.Write (@S[P + 1], N - P, @L);
    if (Failed (R)) or (L <= 0) then break;
    inc (P, L);
  end;
  result := (P = N);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TStationDatabaseEntry.create (const aCall: String);
begin
  inherited create;
  FCall := aCall;
end;


procedure   TStationDatabaseEntry.AfterConstruction;
const
  MethodName = 'AfterConstruction';
begin
  DebOut (self, MethodName, FCall);
  inherited;
  FCriticalSection := TCriticalSection.create;
  FIncomingConnect := Low(TIncomingConnect);
  FEntryType := st_unknown;
  FRemoteCommands := nil;
end;


procedure   TStationDatabaseEntry.BeforeDestruction;
const
  MethodName = 'BeforeDestruction';

begin

  DebOut (self, MethodName, FCall);

  Save (true);

  FRemoteCommands.free;
  FCriticalSection.free;

  inherited;

end;


procedure   TStationDatabaseEntry.Save (ReleaseStorage: Boolean);
// Schreibt noch offene Werte und committet die Datenbank. Mit ReleaseStorage wird
// der Storage danach freigegeben (STGM_SHARE_EXCLUSIVE), damit ein neues Open
// derselben Station ihn wieder öffnen kann.
var
  Saved: Boolean;
begin
  FCriticalSection.Enter;
  try
    if (assigned (FStorage)) then begin
      Saved := false;
      if (FStateT = vs_changed) then begin
        SaveT;
        Saved := true;
      end;
      if (FStateR = vs_changed) then begin
        SaveRemoteCommandList;
        Saved := true;
      end;
      if (Saved) then CommitDatabase;
    end;
    if (ReleaseStorage) then FStorage := nil;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry.CommitDatabase: Boolean;
// Commit auf dem Root der Datenbank (siehe TStationDatabase.Commit); der eigene
// Storage ist im Direktmodus geöffnet und braucht kein Commit.
begin
  if (assigned (StationDatabase)) then begin
    result := StationDatabase.Commit;
  end else begin
    result := false;
  end;
end;


function    TStationDatabaseEntry.GetCall: String;
begin
  result := FCall;
end;


function    TStationDatabaseEntry.GetStorage: IStorage;
begin
  FCriticalSection.Enter;
  try
    result := FStorage;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.SetStorage (const Value: IStorage);
begin
  FCriticalSection.Enter;
  try
    FStorage := Value;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry.GetName: String;
const
  StreamName: WideString = 'N';

var
  Stream: IStream;
  R: HResult;
  S: String;

begin
  FCriticalSection.Enter;
  try
    R := FStorage.OpenStream (PWideChar(StreamName), nil, StreamMode, 0, Stream);
    if (R = S_OK) then begin
      if (not ReadStreamComplete (Stream, S)) then begin
        S := '';
      end;
      result := S;
    end else begin
      result := '';
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.SetName (const Value: String);
const
  MethodName = 'SetName';
  StreamName: WideString = 'N';

var
  Stream: IStream;
  R: HResult;

begin
  FCriticalSection.Enter;
  try
    assert (assigned (FStorage));
    R := FStorage.CreateStream (PWideChar(StreamName), StreamMode or STGM_CREATE, 0, 0, Stream);
    if (R = S_OK) then begin
      assert (assigned (Stream));
      if (not WriteStreamComplete (Stream, Value)) then begin
        DebOut (Self, MethodName, 'Schreibfehler.');
      end;
      Stream := nil;
      CommitDatabase;
    end else begin
      DebOut (Self, MethodName, 'CreateStream Fehler.');
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry.GetNotes: String;
const
  StreamName: WideString = 'C';

var
  Stream: IStream;
  R: HResult;
  S: String;

begin
  FCriticalSection.Enter;
  try
    R := FStorage.OpenStream (PWideChar(StreamName), nil, StreamMode, 0, Stream);
    if (R = S_OK) then begin
      if (not ReadStreamComplete (Stream, S)) then begin
        S := '';
      end;
      result := S;
    end else begin
      result := '';
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.SetNotes (const Value: String);
const
  MethodName = 'SetNotes';
  StreamName: WideString = 'C';

var
  Stream: IStream;
  R: HResult;

begin
  FCriticalSection.Enter;
  try
    assert (assigned (FStorage));
    R := FStorage.CreateStream (PWideChar(StreamName), StreamMode or STGM_CREATE, 0, 0, Stream);
    if (R = S_OK) then begin
      assert (assigned (Stream));
      if (not WriteStreamComplete (Stream, Value)) then begin
        DebOut (Self, MethodName, 'Schreibfehler.');
      end;
      Stream := nil;
      CommitDatabase;
    end else begin
      DebOut (Self, MethodName, 'CreateStream Fehler.');
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.LoadT;
const
  StreamName: WideString = 'T';
var
  Stream: IStream;
  R: HResult;
  L: Integer;
  B: Byte;
begin

  FCriticalSection.Enter;
  try

    FEntryType := st_unknown;
    R := FStorage.OpenStream (PWideChar(StreamName), nil, StreamMode, 0, Stream);

    if (R = S_OK) then begin

      R := Stream.Read (@B, 1, @L);
      if (R <> S_OK) or (L <> 1) then B := 0;
      // Ältere Versionen speicherten die Grenzwerte st_first/st_last als Typ;
      // alles außerhalb der echten Typen gilt als "automatisch".
      if (Integer (B) > Ord (st_unknown)) and (Integer (B) < Ord (st_last)) then begin
        FEntryType := TStationType(B);
      end;

      R := Stream.Read (@B, 1, @L);
      if (R <> S_OK) or (L <> 1) then B := 0;
      FIncomingConnect := TIncomingConnect(B);

    end;

    FStateT := vs_loaded;

  finally
    FCriticalSection.Leave;
  end;

end;


function    TStationDatabaseEntry.SaveT: Boolean;
// Bei einem Fehler bleibt FStateT = vs_changed; Save versucht es dann erneut.
const
  MethodName = 'SaveT';
  StreamName: WideString = 'T';
var
  Stream: IStream;
  R: HResult;
  S: String;
begin
  result := false;
  FCriticalSection.Enter;
  try
    DebOut (self, MethodName, FCall);
    assert (assigned (FStorage));
    R := FStorage.CreateStream (PWideChar(StreamName), StreamMode or STGM_CREATE, 0, 0, Stream);
    if (R = S_OK) then begin
      assert (assigned (Stream));
      SetLength (S, 2);
      S[1] := Chr (Ord (FEntryType));
      S[2] := Chr (Ord (FIncomingConnect));
      result := WriteStreamComplete (Stream, S);
      Stream := nil;
    end;
    if (result) then begin
      FStateT := vs_loaded;
    end else begin
      DebOut (self, MethodName, 'Schreibfehler.');
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry.GetStationType: TStationType;
begin
  FCriticalSection.Enter;
  try
    if (FStateT = vs_uninitialized) then LoadT;
    result := FEntryType;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.SetStationType (const Value: TStationType);
// Vorher laden: Der Stream T enthält auch IncomingConnect, das sonst mit dem
// Vorgabewert überschrieben würde. Geschrieben wird sofort.
begin
  FCriticalSection.Enter;
  try
    if (FStateT = vs_uninitialized) then LoadT;
    if (Value <> FEntryType) then begin
      FEntryType := Value;
      FStateT := vs_changed;
    end;
    if (FStateT = vs_changed) then begin
      if (SaveT) then CommitDatabase;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry.GetIncomingConnect: TIncomingConnect;
begin
  FCriticalSection.Enter;
  try
    if (FStateT = vs_uninitialized) then LoadT;
    result := FIncomingConnect;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.SetIncomingConnect (const Value: TIncomingConnect);
// Wie SetStationType: vorher laden, sofort schreiben.
begin
  FCriticalSection.Enter;
  try
    if (FStateT = vs_uninitialized) then LoadT;
    if (Value <> FIncomingConnect) then begin
      FIncomingConnect := Value;
      FStateT := vs_changed;
    end;
    if (FStateT = vs_changed) then begin
      if (SaveT) then CommitDatabase;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry.GetPasswordValue (const aMycall: string; aPasswordKind: TPasswordKind;
                                                    aPasswordMethod: TPasswordMethod): String;
const
  MethodName = 'GetPasswordValue';

var
  StreamName: string;

begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    PasswordStringsToStreamName (aMycall, aPasswordKind, aPasswordMethod, StreamName);
    Result := GetPasswordValue (StreamName);
  finally
    FCriticalSection.Leave;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    TStationDatabaseEntry.GetPasswordValue (const StreamName: string): String;
const
  MethodName = 'GetPasswordValue';
var
  R: HResult;
  Stream: IStream;
  W: WideString;
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    DebOut (self, MethodName, 'StreamName: ' + StreamName);
    W := StreamName;
    R := FStorage.OpenStream (PWideChar(W), nil, StreamMode, 0, Stream);
    if (R = S_OK) then begin
      if (not ReadStreamComplete (Stream, Result)) then Result := '';
    end else begin
      Result := '';
    end;
    DebOut (self, MethodName, 'end.');
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.SetPasswordValue (const aMycall: string; aPasswordKind: TPasswordKind;
                                                    aPasswordMethod: TPasswordMethod; aPasswordStr: String);
const
  MethodName = 'SetPasswordValue';

var
  StreamName: WideString;
  Stream: IStream;
  R: HResult;
  S: string;

begin

  DebOut (self, MethodName, 'begin...');

  FCriticalSection.Enter;
  try

    PasswordStringsToStreamName (aMyCall, aPasswordKind, aPasswordMethod, S);
    StreamName := WideString (S);
    DebOut (self, MethodName, 'StreamName: ' + StreamName);

    assert (assigned (FStorage));
    R := FStorage.CreateStream (PWideChar(StreamName), StreamMode or STGM_CREATE, 0, 0, Stream);
    if (R = S_OK) then begin
      DebOut (Self, MethodName, 'CreateStream ok.');
      assert (assigned (Stream));
      if (not WriteStreamComplete (Stream, aPasswordStr)) then begin
        DebOut (Self, MethodName, 'Schreibfehler.');
      end;
      Stream := nil;
      CommitDatabase;
    end else begin
      DebOut (Self, MethodName, 'CreateStream Fehler.');
    end;

  finally
    FCriticalSection.Leave;
  end;

  DebOut (self, MethodName, 'end.');

end;


class procedure TStationDatabaseEntry.PasswordStreamNameToStrings (StreamName: string; var aMycall: string;
                                                                   var aPasswordKind: TPasswordKind;
                                                                   var aPasswordMethod: TPasswordMethod);
var
  PA: TPasswordKind;
  PV: TPasswordMethod;
begin
  assert (Length (StreamName) >= 4);
  assert (StreamName[1] = 'P');
  aPasswordKind := Low (TPasswordKind);
  for PA := Low (TPasswordKind) to High (TPasswordKind) do begin
    if StreamName[2] = PasswordKindID[PA] then begin
      aPasswordKind := PA;
      break;
    end;
  end;
  aPasswordMethod := Low (TPasswordMethod);
  for PV := Low (TPasswordMethod) to High (TPasswordMethod) do begin
    if StreamName[3] = PasswordMethodID[PV] then begin
      aPasswordMethod := PV;
      break;
    end;
  end;
  aMyCall := Copy (StreamName, 4, MaxInt);
end;


class procedure TStationDatabaseEntry.PasswordStringsToStreamName (aMycall: string; aPasswordKind: TPasswordKind;
                                                                   aPasswordMethod: TPasswordMethod; var StreamName: string);
begin
  StreamName := 'P' + PasswordKindID[aPasswordKind] + PasswordMethodID[aPasswordMethod] + aMyCall;
end;


function    TStationDatabaseEntry.DeletePassword (const StreamName: string): String;
var
  W: WideString;
begin
  FCriticalSection.Enter;
  try
    if (StreamName <> '') then begin
      W := StreamName;
      try
        Storage.DestroyElement (PWideChar(W));
      except
      end;
      CommitDatabase;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry._release: Integer;
// Bei Zähler 0 wird noch unter der Cache-Sperre gespeichert und der Storage
// (STGM_SHARE_EXCLUSIVE) freigegeben, erst dann ausgetragen: Ein paralleles Open
// derselben Station wartet auf die Sperre und kann den Storage danach öffnen.
// Save nimmt nur die eigene Sperre (Reihenfolge Cache vor Entry wie überall).
// Herunterzählen und Austragen aus dem Cache geschehen unter der Cache-Sperre.
// Sonst könnte Open oder Add eines anderen Threads zwischen dem Zähler 0 und
// RemoveFromCache das sterbende Objekt im Cache finden und weiterverwenden.
const
  MethodName = '_release';
begin
  if (assigned (StationDatabase)) then begin
    StationDatabase.LockCache;
    try
      result := InterlockedDecrement (FRefCount);
      if (result = 0) then begin
        try
          Save (true);
        except
          on E: Exception do begin
            DebOut (self, MethodName, E.Message);
          end;
        end;
        StationDatabase.RemoveFromCache (self);
      end;
    finally
      StationDatabase.UnlockCache;
    end;
  end else begin
    result := InterlockedDecrement (FRefCount);
  end;
  if (result = 0) then begin
    Destroy;
  end;
end;


procedure   TStationDatabaseEntry.GetSoundEvent (Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                                                 var Announcement: TAnnouncementType);
var
  Stream: IStream;
  R: HResult;
  S: String;
  StreamName: WideString;
  SL: TStringList;
begin
  Signal := st_undefined;
  SignalWavFile := '';
  Announcement := at_undefined;
  FCriticalSection.Enter;
  try
    StreamName := Format ('S%2.2d', [SoundEvents(Event).ID]);
    R := FStorage.OpenStream (PWideChar(StreamName), nil, StreamMode, 0, Stream);
    if (R = S_OK) then begin
      if (not ReadStreamComplete (Stream, S)) then S := '';
      SL := TStringList.create;
      SL.CommaText := S;
      if (SL.Count = 3) then begin
        try
          Signal := TSignalType (StrToInt (SL[0]));
          SignalWavFile := SL[1];
          Announcement := TAnnouncementType (StrToInt (SL[2]));
        except
        end;
      end;
      SL.free;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry.SetSoundEvent (Event: TSoundEvent; Signal: TSignalType; const SignalWavFile: String;
                                                 Announcement: TAnnouncementType): Boolean;
var
  Stream: IStream;
  R: HResult;
  StreamName: WideString;
  SL: TStringList;
  S: String;
begin
  result := false;
  FCriticalSection.Enter;
  try
    assert (assigned (FStorage));
    StreamName := Format ('S%2.2d', [SoundEvents(Event).ID]);
    R := FStorage.CreateStream (PWideChar(StreamName), StreamMode or STGM_CREATE, 0, 0, Stream);
    if (R = S_OK) then begin
      assert (assigned (Stream));
      SL := TStringlist.create;
      try
        SL.Add (IntToStr (Ord (Signal)));
        SL.Add (SignalWavFile);
        SL.Add (IntToStr (Ord (Announcement)));
        S := SL.CommaText;
      finally
        SL.free;
      end;
      assert (Length (S) > 0);
      result := WriteStreamComplete (Stream, S);
      Stream := nil;
      if (result) then result := CommitDatabase;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.DeleteSoundEvent (Event: TSoundEvent);
const
  MethodName = 'DeleteSoundEvent';
var
  StreamName: WideString;
begin
  FCriticalSection.Enter;
  try
    assert (assigned (FStorage));
    StreamName := Format ('S%2.2d', [SoundEvents(Event).ID]);
    try
      FStorage.DestroyElement (PWideChar(StreamName));
    except
    end;
    CommitDatabase;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.GetText (TextKind: TTextKind; var Text: String; var DefaultTextBefore: Boolean);
var
  Stream: IStream;
  R: HResult;
  I: Integer;
  S: String;
  StreamName: WideString;
  SL: TStringList;
begin
  Text := '';
  DefaultTextBefore := true;
  FCriticalSection.Enter;
  try
    StreamName := Format ('X%2.2d', [TextKinds(TextKind).ID]);
    R := FStorage.OpenStream (PWideChar(StreamName), nil, StreamMode, 0, Stream);
    if (R = S_OK) then begin
      if (not ReadStreamComplete (Stream, S)) then S := '';
      SL := TStringList.create;
      SL.CommaText := S;
      for I := SL.Count + 1 to 2 do SL.Add ('');
      if (SL.Count = 2) then begin
        try
          DefaultTextBefore := (SL[0] <> '0');
          Text := SL[1];
        except
        end;
      end;
      SL.free;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabaseEntry.SetText (TextKind: TTextKind; const Text: String; const DefaultTextBefore: Boolean): Boolean;
var
  Stream: IStream;
  R: HResult;
  StreamName: WideString;
  SL: TStringList;
  S: String;
begin
  result := false;
  FCriticalSection.Enter;
  try
    assert (assigned (FStorage));
    StreamName := Format ('X%2.2d', [TextKinds(TextKind).ID]);
    R := FStorage.CreateStream (PWideChar(StreamName), StreamMode or STGM_CREATE, 0, 0, Stream);
    if (R = S_OK) then begin
      assert (assigned (Stream));
      SL := TStringlist.create;
      try
        if (DefaultTextBefore) then S := '1' else S := '0';
        SL.Add (S);
        SL.Add (Text);
        S := SL.CommaText;
      finally
        SL.free;
      end;
      assert (Length (S) > 0);
      result := WriteStreamComplete (Stream, S);
      Stream := nil;
      if (result) then result := CommitDatabase;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.DeleteText (TextKind: TTextKind);
const
  MethodName = 'DeleteSoundEvent';
var
  StreamName: WideString;
  H: HResult;
begin
  DebOut (self, MethodName, 'begin...');
  FCriticalSection.Enter;
  try
    assert (assigned (FStorage));
    StreamName := Format ('X%2.2d', [TextKinds(TextKind).ID]);
    try
      H := FStorage.DestroyElement (PWideChar(StreamName));
      DebOut (self, MethodName, '%d', [H]);
    except
    end;
    CommitDatabase;
  finally
    FCriticalSection.Leave;
  end;
  DebOut (self, MethodName, 'end.');
end;


procedure   TStationDatabaseEntry.LoadRemoteCommandList;
var
  Stream: IStream;
  R: HResult;
  S: String;
  StreamName: WideString;

begin

  FCriticalSection.Enter;
  try

    if (assigned (FRemoteCommands)) then FRemoteCommands.free;
    FRemoteCommands := TStringList.create;

    StreamName := 'R';
    R := FStorage.OpenStream (PWideChar(StreamName), nil, StreamMode, 0, Stream);

    if (R = S_OK) then begin

      if (not ReadStreamComplete (Stream, S)) then S := '';

      FRemoteCommands.CommaText := S;

    end;

    FStateR := vs_loaded;

  finally
    FCriticalSection.Leave;
  end;

end;


function    TStationDatabaseEntry.SaveRemoteCommandList: Boolean;
// Bei einem Fehler bleibt FStateR = vs_changed; Save versucht es dann erneut.
const
  MethodName = 'SaveRemoteCommandList';
var
  Stream: IStream;
  R: HResult;
  S: String;
  StreamName: WideString;

begin

  result := true;

  if (assigned (FRemoteCommands)) then begin

    FCriticalSection.Enter;
    try

      StreamName := 'R';

      R := FStorage.CreateStream (PWideChar(StreamName), StreamMode or STGM_CREATE, 0, 0, Stream);

      result := (R = S_OK);
      if (result) then begin
        S := FRemoteCommands.CommaText;
        result := WriteStreamComplete (Stream, S);
        Stream := nil;
      end;

      if (result) then begin
        FStateR := vs_loaded;
      end else begin
        DebOut (self, MethodName, 'Schreibfehler.');
      end;

    finally
      FCriticalSection.Leave;
    end;

  end;

end;


function    TStationDatabaseEntry.GetRemoteCommand (const aCommand: String; var State: Boolean): Boolean;
var
  S: String;
begin
  FCriticalSection.Enter;
  try
    if (not assigned (FRemoteCommands)) then LoadRemoteCommandList;
    assert (assigned (FRemoteCommands));
    S := FRemoteCommands.Values[aCommand];
    if (S = '') then begin
      result := false;
    end else begin
      result := true;
      if (S = '1') then State := true else State := false;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.SetRemoteCommand (const aCommand: String; const State: Boolean);
var
  S: String;
begin
  FCriticalSection.Enter;
  try
    if (not assigned (FRemoteCommands)) then LoadRemoteCommandList;
    assert (assigned (FRemoteCommands));
    if (State) then S := '1' else S := '0';
    FRemoteCommands.Values[aCommand] := S;
    FStateR := vs_changed;
    if (SaveRemoteCommandList) then CommitDatabase;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabaseEntry.DeleteRemoteCommand (const aCommand: String);
var
  I: Integer;
begin
  FCriticalSection.Enter;
  try
    if (not assigned (FRemoteCommands)) then LoadRemoteCommandList;
    assert (assigned (FRemoteCommands));
    I := FRemoteCommands.IndexOfName (aCommand);
    if (I >= 0) then begin
      FRemoteCommands.Delete (I);
      FStateR := vs_changed;
      if (SaveRemoteCommandList) then CommitDatabase;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  assert (sizeof (TIncomingConnect) = 1);

end.

