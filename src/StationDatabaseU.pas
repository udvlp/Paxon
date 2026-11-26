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


unit StationDatabaseU;


interface


uses
  Windows, SysUtils, Classes, InterfacesU, GlobalU, SyncObjs, ActiveX, Forms;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

{$I+}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TStationDatabase = class
  private
    FRootStorage: IStorage;
    FCache: TStringList;
    FCriticalSection: TCriticalSection;
    CheckDB: Boolean;
    procedure   DoCheck (FileName: String);
    function    BackupFile (const FileName: String): String;
  public
    procedure   AfterConstruction; override;
    function    EnumCalls (List: TStringList): Boolean;
    function    EnumPwds (StationDatabaseEntry: IStationDatabaseEntry; List: TStringList): Boolean;
    function    Delete (Call: WideString): Boolean;
    function    Rename (Old, New: WideString): Boolean;
    constructor create (aCheckDB: Boolean);
    procedure   BeforeDestruction; override;
    function    Open (const Call: String): IStationDatabaseEntry; overload;
    function    Open (const Call: String; TryWithoutSSID: Boolean): IStationDatabaseEntry; overload;
    function    Add  (Call: String): IStationDatabaseEntry;
    function    Commit: Boolean;
    procedure   RemoveFromCache (P: TObject);
    procedure   LockCache;
    procedure   UnlockCache;
  end;


var
  StationDatabase: TStationDatabase = nil;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


uses
  DebOutU, StationDatabaseEntryU, StationDatabaseProgressU, MainU, MessageboxU, Dialogs;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  StorageMode = STGM_READWRITE or STGM_SHARE_EXCLUSIVE or STGM_DIRECT;
              // STGM_DELETEONRELEASE not supported

  StreamMode = STGM_READWRITE or STGM_SHARE_EXCLUSIVE or STGM_DIRECT;
             // Transacted mode not supported
             // STGM_SHARE_EXCLUSIVE is mandatory
             // STGM_DELETEONRELEASE not supported


resourcestring
  SErrorCannotSaveDatabase = 'Die Stationsdatenbank "%s" kann nicht geöffnet und nicht gesichert werden.';
  SDatabaseSaved = 'Die Stationsdatenbank "%s" kann nicht gelesen werden und ist vermutlich beschädigt.'#13#13 +
                   'Die Datei wurde unverändert als "%s" gesichert. Es wird eine neue, leere Stationsdatenbank angelegt.';
  SErrorCannotOpenDatabase = 'Die Stationsdatenbank "%s" kann zurzeit nicht geöffnet werden (Fehler %.8x), ' +
                             'z. B. weil ein anderes Programm sie gesperrt hat. Die Datei wurde nicht verändert.';


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// True if the result of StgIsStorageFile/StgOpenStorage indicates a damaged
// or foreign file. Other errors (lock, access denied, out of
// memory) are temporary: in that case never set the file aside.
function    FileDamaged (const R: HResult): Boolean;
begin
  Result := (R = S_FALSE) or (R = STG_E_INVALIDHEADER) or (R = STG_E_DOCFILECORRUPT) or (R = STG_E_OLDFORMAT);
end;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   ReportMessage (const S: String);
begin
  with TDlgMessage.create (MainWindow) do begin
    Run (ApplicationName, S, [mbOk]);
    Release;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TStationDatabase.create (aCheckDB: Boolean);
const
  MethodName = 'Create';
begin
  inherited create;
  CheckDB := aCheckDB;
end;


procedure   TStationDatabase.AfterConstruction;
const
  MethodName = 'AfterConstruction';

var
  R: HResult;
  FileNameStr: WideString;
  S, T: String;

begin

  DebOut (self, MethodName, 'begin...');

  inherited;

  assert (not assigned (StationDatabase));
  StationDatabase := self;

  FCriticalSection := TCriticalSection.create;

  FCache := TStringList.create;

  FileNameStr := ApplicationDataPath + 'Database\';
  ForceDirectories (FileNameStr);
  FileNameStr := FileNameStr + 'Stations.pxd';

  // Rename the old file, if present

  try
    if (not FileExists (FileNameStr)) then begin
      S := ChangeFileExt (Application.ExeName, '-S.DAT');
      if (FileExists (S)) then begin
        T := FileNameStr;
        if (not MoveFileUlf (S, T, false)) then begin
          // Without write permission in the program folder, only copy
          CopyFile (PChar(S), PChar(T), true);
        end;
      end;
    end;
  except
  end;

  // Perform check

  if (CheckDB) then DoCheck (FileNameStr);

  // Open storage file

  R := StgIsStorageFile (PWideChar(FileNameStr));
  if (R = S_OK) then begin
    R := StgOpenStorage (PWideChar(FileNameStr), nil, StorageMode, nil, 0, FRootStorage);
  end else begin
    // Do not overwrite an existing unreadable file; rename it as a backup instead
    if (FileExists (FileNameStr)) then begin
      if (not FileDamaged (R)) then begin
        raise Exception.CreateFmt (SErrorCannotOpenDatabase, [String (FileNameStr), R]);
      end;
      S := BackupFile (FileNameStr);
      ReportMessage (Format (SDatabaseSaved, [String (FileNameStr), S]));
    end;
    R := StgCreateDocfile (PWideChar(FileNameStr), StorageMode or STGM_CREATE, 0, FRootStorage);
  end;

  if (R <> S_OK) then begin

    case R of
      STG_E_FILENOTFOUND: S := 'STG_E_FILENOTFOUND';
      STG_E_ACCESSDENIED: S := 'STG_E_ACCESSDENIED';
      STG_E_FILEALREADYEXISTS: S := 'STG_E_FILEALREADYEXISTS';
      STG_E_TOOMANYOPENFILES: S := 'STG_E_TOOMANYOPENFILES';
      STG_E_INSUFFICIENTMEMORY: S := 'STG_E_INSUFFICIENTMEMORY';
      STG_E_INVALIDNAME: S := 'STG_E_INVALIDNAME';
      STG_E_INVALIDPOINTER: S := 'STG_E_INVALIDPOINTER';
      STG_E_INVALIDFLAG: S := 'STG_E_INVALIDFLAG';
      STG_E_INVALIDFUNCTION: S := 'STG_E_INVALIDFUNCTION';
      STG_E_OLDDLL: S := 'STG_E_OLDDLL';
      STG_E_OLDFORMAT: S := 'STG_E_OLDFORMAT';
      else S := 'unknown error';
    end;

    S := 'OpenStorage/CreateDocfile: ' + S;
    DebOut (self, MethodName, S + #13);

    raise Exception.create (S);

  end;

  // Delete obsolete entry

  try
    FRootStorage.DestroyElement ('[ alle ]');
  except
  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TStationDatabase.BeforeDestruction;
// Noch lebende Entries schreiben ihre offenen Werte, bevor der Root freigegeben
// wird; danach wird der Root ein letztes Mal committet.
var
  I: Integer;
begin
  if (assigned (FCriticalSection)) and (assigned (FCache)) then begin
    FCriticalSection.Enter;
    try
      for I := 0 to FCache.Count - 1 do begin
        try
          TStationDatabaseEntry (FCache.Objects[I]).Save (false);
        except
        end;
      end;
      Commit;
    finally
      FCriticalSection.Leave;
    end;
  end;
  if (StationDatabase = self) then StationDatabase := nil;
  FRootStorage := nil;
  FCache.free;
  FCriticalSection.free;
  inherited;
end;


function    TStationDatabase.Commit: Boolean;
// Der Root ist im Direktmodus geöffnet: Jede Änderung geht sofort in die Datei,
// Teil-Storages brauchen kein Commit. Commit auf dem Root schreibt die internen
// Puffer (FAT, Verzeichnis) auf die Platte und meldet, anders als Release, Fehler.
// Keine Cache-Sperre: Wird aus Entries unter deren Sperre aufgerufen.
const
  MethodName = 'Commit';
var
  HR: HResult;
begin
  if (assigned (FRootStorage)) then begin
    HR := FRootStorage.Commit (STGC_DEFAULT);
    Result := (HR = S_OK);
    if (not Result) then begin
      DebOut (self, MethodName, 'Fehler %.8x', [HR]);
    end;
  end else begin
    Result := false;
  end;
end;


function    TStationDatabase.Delete (Call: WideString): Boolean;
var
  HR: HResult;
  I: Integer;
  W: WideString;
begin
  FCriticalSection.Enter;
  try
    W := AnsiUpperCase (Call);
    I := FCache.IndexOf (W);
    if (I >= 0) then begin
      result := false;
    end else begin
      HR := FRootStorage.DestroyElement (PWideChar(W));
      Result := (HR = S_OK) and (Commit);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabase.EnumCalls (List: TStringList): Boolean;
const
  MethodName = 'EnumCalls';
type
  TStatArray = Array[0..8191] of TSTATSTG;
var
  RootEnum: IEnumSTATSTG;
  Stats: TStatArray;
  I, N, L: LongInt;
  Malloc: IMalloc;
  HR: HResult;
begin
  CoGetMalloc (1, Malloc);
  List.Sorted := false;
  List.Clear;
  HR := FRootStorage.EnumElements (0, nil, 0, RootEnum);
  if (HR = S_OK) and (assigned (RootEnum)) then begin
    RootEnum.Reset;
    N := High (TStatArray) - Low(TStatArray) + 1;
    repeat
      RootEnum.Next (N, Stats, @L);
      for I := 0 to L - 1 do begin
        List.Add (String (Stats[I].pwcsName));
        Malloc.Free (Stats[I].pwcsName);
      end;
    until (L <> N);
  end;
  List.Sorted := true;
  result := true;
end;


function    TStationDatabase.Rename (Old, New: WideString): Boolean;
var
  HR: HRESULT;
begin
  try
    HR := FRootStorage.MoveElementTo (PWideChar(Old), FRootStorage, PWideChar(New), STGMOVE_MOVE);
    Result := (HR = S_OK) and (Commit);
  except
    Result := false;
  end;
end;


function    TStationDatabase.Open (const Call: String): IStationDatabaseEntry;
const
  MethodName = 'Open';
var
  E: TStationDatabaseEntry;
  HR: HResult;
  Storage: IStorage;
  W: WideString;
  I: Integer;
begin
  FCriticalSection.Enter;
  try
    try
      W := AnsiUpperCase (Call);
      I := FCache.IndexOf (W);
      if (I >= 0) then begin
        result := TStationDatabaseEntry (FCache.Objects[I]);
      end else begin
        HR := FRootStorage.OpenStorage (PWideChar(W), nil, StorageMode, nil, 0, Storage);
        if (HR <> S_OK) then begin
          result := nil;
        end else begin
          E := TStationDatabaseEntry.Create (W);
          E.Storage := Storage;
          FCache.AddObject (W, E);
          result := E;
        end;
      end;
    except
      result := nil;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabase.Open (const Call: String; TryWithoutSSID: Boolean): IStationDatabaseEntry;
var
  S: String;
  I: Integer;
begin
  I := Pos ('-', Call);
  if (I < 1) then S := Call + '-0' else S := Call;
  result := Open (S);
  if (not assigned (result)) and ((TryWithoutSSID) or (I < 1)) then begin
    result := Open (StripSSID (S));
  end;
end;


function    TStationDatabase.Add (Call: String): IStationDatabaseEntry;
// Creates a new station. If the station already exists, it is not
// overwritten (STGM_FAILIFTHERE); the result is then nil.
const
  MethodName = 'Add';
var
  E: TStationDatabaseEntry;
  HR: HResult;
  Storage: IStorage;
  W: WideString;
begin
  FCriticalSection.Enter;
  try
    W := AnsiUpperCase (Call);
    if (FCache.IndexOf (W) >= 0) then begin
      result := nil;
      exit;
    end;
    E := TStationDatabaseEntry.Create (W);
    HR := FRootStorage.CreateStorage (PWideChar(W), StorageMode or STGM_FAILIFTHERE, 0, 0, Storage);
    if (HR = S_OK) and (assigned (Storage)) then begin
      Commit;
      E.Storage := Storage;
      FCache.AddObject (W, E);
      result := E;
    end else begin
      E.free;
      result := nil;
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


function    TStationDatabase.BackupFile (const FileName: String): String;
// Renames an unreadable database file unchanged instead of deleting or
// overwriting it. The result is the new file name. If that fails, an exception
// is raised so that the file is never replaced.
const
  MethodName = 'BackupFile';
begin
  result := ChangeFileExt (FileName, '.pxdbak');
  if (not MoveFileUlf (FileName, result, true)) then begin
    raise Exception.CreateFmt (SErrorCannotSaveDatabase, [FileName]);
  end;
  DebOut (self, MethodName, FileName + ' -> ' + result);
end;


procedure   TStationDatabase.RemoveFromCache (P: TObject);
const
  MethodName = 'RemoveFromCache';
var
  I: Integer;
begin
  FCriticalSection.Enter;
  try
    I := FCache.IndexOfObject (P);
    if (I >= 0) then begin
      FCache.Delete (I);
    end else begin
    end;
  finally
    FCriticalSection.Leave;
  end;
end;


procedure   TStationDatabase.LockCache;
// Dieselbe Sperre wie Open, Add und RemoveFromCache (wiedereintrittsfähig).
begin
  FCriticalSection.Enter;
end;


procedure   TStationDatabase.UnlockCache;
begin
  FCriticalSection.Leave;
end;


function    TStationDatabase.EnumPwds (StationDatabaseEntry: IStationDatabaseEntry; List: TStringList): Boolean;
const
  MethodName = 'EnumPwds';

type
  TStatArray = Array[0..8191] of TSTATSTG;

var
  Enum: IEnumSTATSTG;
  Stats: TStatArray;
  I, N, L: LongInt;
  Malloc: IMalloc;
  Storage: IStorage;
  S: WideString;
  P: PWideChar;
  R: HResult;

begin


  if (assigned (StationDatabaseEntry)) then begin
    Storage := StationDatabaseEntry.Storage;
  end else begin
    Storage := nil;
  end;

  List.Sorted := false;
  List.Clear;

  if (assigned (Storage)) then begin
    CoGetMalloc (1, Malloc);
    R := Storage.EnumElements (0, nil, 0, Enum);
    if (R = S_OK) and (assigned (Enum)) then begin
      Enum.Reset;
      N := High (TStatArray) - Low(TStatArray) + 1;
      repeat
        Enum.Next (N, Stats, @L);
        for I := Low(TStatArray) to Low(TStatArray) + L - 1 do begin
          P := Stats[I].pwcsName;
          if (assigned (P)) and (P[0] <> #0) then begin
            S := string (WideString (P));
            if (Length (S) >= 1) then begin
              if (S[1] = 'P') then begin
                List.Add (S);
              end;
            end;
          end;
          Malloc.Free (Stats[I].pwcsName);
        end;
      until (L <> N);
    end;
    result := true;
  end else begin
    result := false;
  end;


end;


procedure   TStationDatabase.DoCheck (FileName: String);
const
  MethodName = 'DoCheck';

resourcestring
  SErrorDiskFull = 'Auf der Festplatte ist nicht genügend freier Speicherplatz vorhanden';
  SErrorCannotCreateNewFile = 'Kann neue Datei nicht anlegen.';
  SCheckIncomplete = 'Die Stationsdatenbank konnte nicht vollständig geprüft werden.'#13#13 +
                     'Die bisherige Datei "%s" wird unverändert weiter verwendet.';
  SCheckRepairFile = #13#13'Alle lesbaren Stationen wurden in "%s" kopiert. Um sie zu verwenden, Paxon beenden ' +
                     'und die bisherige Datei durch diese ersetzen.';

type
  TStatArray = Array[0..8191] of TSTATSTG;

var
  R: HResult;
  ChkFileName: String;
  RootStorage, ChkRootStorage, Storage, ChkStorage: IStorage;
  Enum: IEnumSTATSTG;
  Stats: TStatArray;
  K, I, N, L: LongInt;
  Malloc: IMalloc;
  HR: HResult;
  Calls, Values: TStringList;
  P: PWideChar;
  Stream: IStream;
  S: String;
  Call: WideString;
  StationDatabaseProgressForm: TStationDatabaseProgressForm;
  F: File;
  B, Total: Int64;
  Completed: Boolean;
  HintText: String;
  RepFileName: String;

begin

  DebOut (self, MethodName, 'begin...');

  if (FileExists (FileName)) then begin

    for I := 1 to 5 do begin
      Sleep (50);
      Application.ProcessMessages;
    end;

    HintText := '';

    StationDatabaseProgressForm := TStationDatabaseProgressForm.create (MainWindow);
    try

      try
        StationDatabaseProgressForm.Show;
        StationDatabaseProgressForm.Update;

        ChkFileName := ChangeFileExt (FileName, '.pxdchk');

        // Check disk space

        Assign (F, FileName);
        try
          Reset (F, 1);
          try
            N := FileSize (F);
          finally
            CloseFile (F);
          end;
        except
          raise;
        end;

        // GetDiskFreeSpaceEx with the directory also works with UNC paths;
        // if the free space cannot be determined, the check is skipped

        if (Windows.GetDiskFreeSpaceEx (PChar(ExtractFilePath (FileName)), B, Total, nil)) then begin
          DebOut (self, MethodName, 'Size of Database: ' + IntToStr (N));
          DebOut (self, MethodName, 'Free Disk Space: ' + IntToStr (B));
          if (B < N + 524288) then begin
            raise Exception.create (SErrorDiskFull);
          end;
        end else begin
          DebOut (self, MethodName, 'Free Disk Space unknown: ' + GetLastErrorText);
        end;

        // Open old file

        R := StgIsStorageFile (PWideChar(WideString(FileName)));
        if (R = S_OK) then begin
          R := StgOpenStorage (PWideChar(WideString(FileName)), nil, StorageMode, nil, 0, RootStorage);
        end;

        if (R <> S_OK) then begin

          RootStorage := nil;

          if (not FileDamaged (R)) then begin
            raise Exception.CreateFmt (SErrorCannotOpenDatabase, [FileName, R]);
          end;

          // Old file damaged: do not replace it, rename it unchanged as a backup instead

          S := BackupFile (FileName);
          HintText := Format (SDatabaseSaved, [FileName, S]);

        end else begin

          // Create new file

          DeleteFile (ChkFileName);

          R := StgCreateDocfile (PWideChar(WideString(ChkFileName)), StorageMode or STGM_CREATE, 0, ChkRootStorage);

          if (R <> S_OK) then begin
            raise Exception.create (SErrorCannotCreateNewFile);
          end;

          Completed := true;

          // Read callsigns...

          CoGetMalloc (1, Malloc);

          Calls := TStringList.create;
          Values := TStringList.create;
          try

            HR := RootStorage.EnumElements (0, nil, 0, Enum);
            if (HR = S_OK) and (assigned (Enum)) then begin
              Enum.Reset;
              N := High (TStatArray) + 1;
              repeat
                L := 0;
                HR := Enum.Next (N, Stats, @L);
                for I := 0 to L - 1 do begin
                  Calls.Add (String (Stats[I].pwcsName));
                  Malloc.Free (Stats[I].pwcsName);
                end;
                // Ein Fehler (statt S_FALSE am Ende) bricht die Aufzählung ab: Dann
                // fehlen Stationen, und die Kopie darf das Original nicht ersetzen.
                if (HR <> S_OK) and (HR <> S_FALSE) then begin
                  Completed := false;
                end;
                Application.ProcessMessages;
              until (L <> N);
            end else begin
              Completed := false;
            end;
            Enum := nil;

            Calls.Sort;

            // Write callsigns...

            for K := 0 to Calls.Count - 1 do begin

              Call := Calls[K];

              DebOut (self, MethodName, Call);

              // Enumerate values...

              R := RootStorage.OpenStorage (PWideChar(Call), nil, StorageMode, nil, 0, Storage);
              if (R = S_OK) and (assigned (Storage)) then begin

                Values.Clear;

                R := Storage.EnumElements (0, nil, 0, Enum);
                if (R = S_OK) and (assigned (Enum)) then begin
                  Enum.Reset;
                  N := High (TStatArray) + 1;
                  repeat
                    L := 0;
                    R := Enum.Next (N, Stats, @L);
                    for I := 0 to L - 1 do begin
                      P := Stats[I].pwcsName;
                      if (assigned (P)) and (P[0] <> #0) then begin
                        Values.Add (string (widestring (P)));
                      end;
                      Malloc.Free (Stats[I].pwcsName);
                    end;
                    if (R <> S_OK) and (R <> S_FALSE) then begin
                      Completed := false;
                    end;
                    Application.ProcessMessages;
                  until (L <> N);
                end else begin
                  Completed := false;
                end;
                Enum := nil;

                // Create callsign in the new file

                R := ChkRootStorage.CreateStorage (PWideChar(Call), StorageMode or STGM_CREATE, 0, 0, ChkStorage);
                if (R = S_OK) then begin

                  // Copy values completely

                  for I := 0 to Values.Count - 1 do begin

                    Stream := nil;
                    R := Storage.OpenStream (PWideChar(WideString (Values[I])), nil, StreamMode, 0, Stream);

                    if (R = S_OK) and (assigned (Stream)) then begin

                      if (not ReadStreamComplete (Stream, S)) then begin
                        Completed := false;
                      end;

                      Stream := nil;

                      R := ChkStorage.CreateStream (PWideChar(WideString (Values[I])), StreamMode or STGM_CREATE, 0, 0, Stream);
                      if (R = S_OK) and (assigned (Stream)) then begin
                        if (not WriteStreamComplete (Stream, S)) then begin
                          Completed := false;
                        end;
                      end else begin
                        Completed := false;
                      end;

                      Stream := nil;

                    end else begin
                      Completed := false;
                    end;

                  end;

                end else begin
                  Completed := false;
                end;

                Stream := nil;
                Storage := nil;
                ChkStorage := nil;

              end else begin
                Completed := false;
              end;

              Application.ProcessMessages;

              // On an error, keep copying: the readable stations are then
              // kept as a repair file (see below).
              if (not Completed) then begin
                DebOut (self, MethodName, 'Fehler beim Kopieren: ' + Call);
              end;

            end;

          finally
            Values.free;
            Calls.free;
          end;

          RootStorage := nil;
          ChkRootStorage := nil;

          for I := 1 to 5 do begin
            Sleep (50);
            Application.ProcessMessages;
          end;

          // Replace the old file only after copying has fully succeeded

          if (Completed) then begin
            if (not MoveFileEx (PChar(ChkFileName), PChar(FileName), MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH)) then begin
              DebOut (self, MethodName, 'MoveFileEx: ' + GetLastErrorText);
              Completed := false;
            end;
          end;

          if (not Completed) then begin
            HintText := Format (SCheckIncomplete, [FileName]);
            // Keep the incomplete copy as a repair file; the old file stays in use
            RepFileName := ChangeFileExt (FileName, '.pxdrep');
            if (FileExists (ChkFileName)) and
               (MoveFileEx (PChar(ChkFileName), PChar(RepFileName), MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH)) then begin
              HintText := HintText + Format (SCheckRepairFile, [RepFileName]);
            end else begin
              DeleteFile (ChkFileName);
            end;
          end;

        end;
      except
        // A failed check (disk space, check file, ...) must not prevent the start: report it,
        // the file is then opened as usual.
        on E: Exception do begin
          DebOut (self, MethodName, 'Exception: ' + E.Message);
          HintText := Format (SCheckIncomplete, [FileName]) + #13#13 + E.Message;
          // Release both files; an incomplete check file is of no use
          Enum := nil;
          Stream := nil;
          Storage := nil;
          ChkStorage := nil;
          RootStorage := nil;
          ChkRootStorage := nil;
          if (ChkFileName <> '') then DeleteFile (ChkFileName);
        end;
      end;

    finally
      StationDatabaseProgressForm.Hide;
      StationDatabaseProgressForm.Update;
      StationDatabaseProgressForm.Release;
    end;

    for I := 1 to 5 do begin
      Sleep (50);
      Application.ProcessMessages;
    end;

    if (HintText <> '') then begin
      ReportMessage (HintText);
    end;

  end else begin

    DebOut (self, MethodName, 'Keine Datenbank vorhanden.');

  end;

  DebOut (self, MethodName, 'end.');

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

