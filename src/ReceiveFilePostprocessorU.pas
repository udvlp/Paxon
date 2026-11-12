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


unit ReceiveFilePostprocessorU;


interface


uses
  Windows, SysUtils, Classes, InterfacesU, GlobalU, SyncObjs, PublisherU,
  BinSplitPartU, FileStreamUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TReceiveFilePostprocessor = class
  private

    FSendFile: ISendFile;
    FPacketConnection: IConnectionForModule;

    procedure   BinSplitCombine;

  public

    constructor Create (aConnectionObj: IConnectionForModule);
    destructor  Destroy; override;
    procedure   Execute (aSendFile: ISendFile);
    procedure   ChannelPrompt (aText: String; aType: TDisplayType);
    class function PartsAsString (const Parts: array of TBinSplitPart; Hex: Boolean): string;

  end;


function    ReceiveFilename (const Name, ReplacementName: String): String;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, FolderU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    ReceiveFilename (const Name, ReplacementName: String): String;
// Turns a filename supplied by the remote station into a plain filename without a path,
// so that the file can only be created in the receive folder. Like
// TSendFile.SetTargetFilename, it replaces invalid characters and additionally catches empty names, '.', '..'
// and device names (CON, NUL, COM1 ...). ReplacementName is used for an empty name.
var
  I, L: Integer;
  S: String;
begin
  result := ExtractFileName (Name);
  for I := 1 to Length (result) do begin
    if (result[I] in [#$00..#$1F, #$7F, #$81..#$A0, #$FF, '<', '>', ':', '"', '/', '\', '|', '?', '*']) then begin
      result[I] := '_';
    end;
  end;
  // Windows strips trailing dots and spaces anyway ('..' would otherwise be the folder itself).
  L := Length (result);
  while (L > 0) and (result[L] in ['.', ' ']) do Dec (L);
  SetLength (result, L);
  if (result = '') then result := ReplacementName;
  // Device names apply with an extension too ('COM1.txt' writes to the port).
  I := Pos ('.', result);
  if (I > 0) then S := Copy (result, 1, I - 1) else S := result;
  S := AnsiUpperCase (TrimRight (S));
  if (S = 'CON') or (S = 'PRN') or (S = 'AUX') or (S = 'NUL') or (S = 'CONIN$') or (S = 'CONOUT$')
    or ((Length (S) = 4) and ((Copy (S, 1, 3) = 'COM') or (Copy (S, 1, 3) = 'LPT')) and
        (S[4] in ['0'..'9', #$B2, #$B3, #$B9])) then begin
    result := '_' + result;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TReceiveFilePostprocessor.create (aConnectionObj: IConnectionForModule);
begin
  inherited create;
  FPacketConnection := aConnectionObj;
end;


destructor  TReceiveFilePostprocessor.destroy;
begin
  FPacketConnection := nil;
  inherited;
end;


procedure   TReceiveFilePostprocessor.Execute (aSendFile: ISendFile);
const
  MethodName = 'Execute';

resourcestring
  SFileSaved = 'Empfangene Datei gespeichert:'#13'%s';
  SErrorSavingFile = 'Fehler beim Speichern der Datei:'#13'%s';
  SFileNotSaved = 'Empfangene Datei NICHT gespeichert.';
  SErrorCreatingFolder = 'Empfangene Datei NICHT gespeichert.'#13'Empfangs-Ordner konnte nicht angelegt werden:'#13'%s';

var
  Q, S: string;
  B: Boolean;
  DontCombine: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  DontCombine := false;

  FSendFile := aSendFile;

  FSendFile.Stream.Seek (0, soFromBeginning);

  if (not DontCombine) then begin
    SetLength (S, 5);
    SetLength (S, FSendFile.Stream.read (S[1], 5));
  end;

  if (not DontCombine) and (S = '>BS<'#10) then begin

    DebOut (self, MethodName, 'ist BINSPLIT-Datei');

    BinSplitCombine;

  end else begin

    DebOut (self, MethodName, 'ist keine BINSPLIT-Datei');

    try
      B := ForceDirectories (Folders.Reception);
    except
      B := false;
    end;

    if (B) then begin
      S := Folders.Reception + ReceiveFilename (FSendFile.TargetFilename, 'empfang.bin');
      if (FSendFile.Stream is TFileStreamUlf) then begin
        (FSendFile.Stream as TFileStreamUlf).Close;
        Q := (FSendFile.Stream as TFileStreamUlf).FileName;
        if (MoveFileUlf (Q, S, true)) then begin
          ChannelPrompt (Format (SFileSaved, [S]), dt_pgp);
        end else begin
          ChannelPrompt (Format (SErrorSavingFile, [S]), dt_pgp);
        end;
      end else begin
        ChannelPrompt (SFileNotSaved, dt_pgp);
      end;
    end else begin
      ChannelPrompt (Format (SErrorCreatingFolder, [Folders.Reception]), dt_pgp);
    end;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TReceiveFilePostprocessor.BinSplitCombine;
const
  MethodName = 'BinSplitCombine';

resourcestring
  SPartReceived = 'Teil %d von %s empfangen.';
  SAllPartsAvailable = 'Alle Teile verfügbar. Kombiniere...';
  SPartsMissing = 'Folgende Teile fehlen noch:';
  SDec = 'dez:';
  SHex = 'hex:';
  SCRCError = 'CRC-Fehler:'#13'%s, Teil %d von %d';
  SWrongDataInHeader = 'FEHLER: Falsche Daten im Header.';
  SHeaderInvalidOrTooShort = 'FEHLER: Header ungültig oder zu kurz.';
  SErrorInAccumulatedCRC = 'Fehler im akkumulierten CRC von Teil %d.';
  SReceivedFileNotSavedFolderCouldNotCreateFolder = 'Empfangene Datei NICHT gespeichert.'#13'Empfangs-Ordner konnte nicht angelegt werden:'#13'%s'#13;
  SCannotOpenDestinationFile = 'Kann Zieldatei nicht öffnen:'#13'%s'#13;
  SErrorWritingDestinationFile = 'Fehler beim Schreiben der Zieldatei:'#13'%s'#13;
  SCannotDeleteFile = 'Kann Datei nicht löschen: '#13'%s'#13'%s'#13#13;
  SCannotDeletePart = 'Kann Teil nicht löschen: '#13'%s'#13#13;
  SReceivedFileSaved = 'Empfangene Datei gespeichert:'#13'%s'#13;

var
  ActualPart, AnotherPart: TBinSplitPart;
  Parts: array of TBinSplitPart;
  SR: TSearchRec;
  U, S, T: string;
  I: Integer;
  B, A, C: Boolean;
  FS: TFileStreamUlf;
  HasError: Boolean;
  AccumulatedCRC32: Cardinal;
  Prompt: string;
  DontDelete: Boolean;
  FileWasOpened: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  DontDelete := false;

  ActualPart := TBinSplitPart.CreateFromStream (FSendFile.Stream as TFileStreamUlf);
  AnotherPart := nil;

  try

    if (ActualPart.ReadHeader) then begin

      if (ActualPart.Parse) then begin

        if (ActualPart.CheckPartCRC) then begin

          SetLength (Parts, ActualPart.PartCount);
          for I := Low(Parts) to High (Parts) do Parts[I] := nil;

          U := (FSendFile.Stream as TFileStreamUlf).FileName;
          S := ExtractFilePath (U);
          T := ExtractFileName (U);

          // Parse has checked part number and part count for valid ranges.
          Parts [ActualPart.PartNumber - 1] := ActualPart;

          Prompt := Format (SPartReceived + #13, [ActualPart.PartNumber, ActualPart.FileName]);

          I := FindFirst (S + '*', faReadOnly or faHidden or faSysFile or faArchive, SR);
          while (I = 0) do begin
            if (CompareText (SR.Name, T) <> 0) then begin
              DebOut (self, MethodName, 'Öffnen: ' + SR.Name + '...');
              try
                AnotherPart := TBinSplitPart.CreateFromFile (S + SR.Name);
              except
                AnotherPart := nil;
              end;
              if (assigned (AnotherPart)) then begin
                try
                  if (AnotherPart.ReadHeader) then begin
                    if (AnotherPart.Parse) then begin
                      if (AnotherPart.PartCount = ActualPart.PartCount)
                        and (AnotherPart.Splitsize = ActualPart.SplitSize)
                        and (AnotherPart.Originalsize = ActualPart.Originalsize)
                        and (AnotherPart.FileName = ActualPart.FileName)
                        and (AnotherPart.Date = ActualPart.Date) then begin
                        DebOut (self, MethodName,
                                Format ('Ist Teil %3.3d von %3.3d', [AnotherPart.PartNumber, AnotherPart.PartCount]));
                        if (Parts [AnotherPart.PartNumber - 1] = nil) then begin
                          Parts [AnotherPart.PartNumber - 1] := AnotherPart;
                          AnotherPart := nil;
                        end;
                      end else begin
                        DebOut (self, MethodName, 'Passt nicht zu diesem Set.');
                      end;
                    end else begin
                      DebOut (self, MethodName, 'Fehler: Parse');
                    end;
                  end else begin
                    DebOut (self, MethodName, 'Fehler: ReadHeader');
                  end;
                finally
                  if (assigned (AnotherPart)) then begin
                    AnotherPart.free;
                    AnotherPart := nil;
                  end;
                end;
              end;
            end;
            I := FindNext (SR);
          end;
          FindClose (SR);

          B := true;
          for I := Low(Parts) to High (Parts) do begin
            if (not assigned (Parts[I])) then begin
              B := false;
            end else begin
              DebOut (self, MethodName, 'Teil %3.3d: %s', [Parts[I].PartNumber, Parts[I].Stream.Filename]);
            end;
          end;

          if (B) then begin

            // all parts present

            Prompt := Prompt + SAllPartsAvailable + #13#13;

            HasError := false;

            DebOut (self, MethodName, 'Überprüfe akkumulierten CRC...');
            AccumulatedCRC32 := $FFFFFFFF;
            for I := Low(Parts) to High (Parts) do begin
              A := Parts[I].CheckAccumulatedCRC (AccumulatedCRC32);
              DebOut (self, MethodName, Format ('Teil %3.3d: Akkumulierter CRC = %8.8x', [Parts[I].PartNumber, AccumulatedCRC32]));
              if (not A) then begin
                Prompt := Prompt + Format (SErrorInAccumulatedCRC, [Parts[I].PartNumber]);
                HasError := true;
                break;
              end;
            end;

            if (not HasError) then begin

              try
                C := ForceDirectories (Folders.Reception);
              except
                C := false;
              end;

              if (not C) then begin
                Prompt := Prompt + Format (SReceivedFileNotSavedFolderCouldNotCreateFolder, [Folders.Reception]);
                HasError := true;
              end;

            end;

            if not HasError then begin

              FS := TFileStreamUlf.create;

              try

                FS.FileName := UniqueFilename (Folders.Reception + ReceiveFilename (Parts[0].FileName, 'binsplit.bin'));
                FS.Mode := fmCreate or fmShareDenyWrite;
                FileWasOpened := false;
                try
                  FS.Open;
                  FileWasOpened := true;
                except
                  Prompt := Prompt + Format (SCannotOpenDestinationFile, [FS.FileName]);
                  HasError := true;
                end;

                // Only write to an opened target file, otherwise only further error messages follow.
                if (FileWasOpened) then begin
                  for I := Low(Parts) to High (Parts) do begin
                    try
                      Parts[I].WriteToStream (FS);
                    except
                      Prompt := Prompt + Format (SErrorWritingDestinationFile, [FS.FileName]);
                      HasError := true;
                      break;
                    end;
                  end;
                end;

                if (HasError) then begin
                  try
                    // Only delete a target file we created ourselves.
                    if (FileWasOpened) and (not DontDelete) then FS.Delete;
                  except
                    on E: Exception do begin
                      Prompt := Prompt + Format (SCannotDeleteFile, [FS.FileName, E.Message]);
                    end;
                  end;
                end else begin
                  for I := Low(Parts) to High (Parts) do begin
                    try
                      if (not DontDelete) then Parts[I].Stream.Delete;
                    except
                      Prompt := Prompt + Format (SCannotDeletePart, [Parts[I].Stream.FileName]);
                    end;
                  end;
                end;

                if not HasError then begin

                  Prompt := Prompt + Format (SReceivedFileSaved, [FS.FileName]);

                end;

              finally

                FS.Close;
                FS.free;

              end;

            end;

            ChannelPrompt (Prompt, dt_pgp);

          end else begin

            // not all parts present

            Prompt := Prompt + SPartsMissing + #13;
            Prompt := Prompt + SDec + ' ' + PartsAsString (Parts, false) + #13;
            Prompt := Prompt + SHex + ' ' + PartsAsString (Parts, true) + #13;
            ChannelPrompt (Prompt, dt_pgp);

          end;

          for I := Low(Parts) to High (Parts) do begin
            if (Parts[I] = ActualPart) then ActualPart := nil;
            Parts[I].free;
            Parts[I] := nil;
          end;

          if (assigned (ActualPart)) then begin
            ActualPart.free;
            ActualPart := nil;
          end;

        end else begin

          ChannelPrompt (Format (SCRCError + #13, [ActualPart.FileName, ActualPart.PartNumber, ActualPart.PartCount]), dt_pgp);

        end;

      end else begin

        ChannelPrompt (SWrongDataInHeader + #13, dt_pgp);

      end;

    end else begin

      ChannelPrompt (SHeaderInvalidOrTooShort + #13, dt_pgp);

    end;

    assert (not assigned (AnotherPart));

  finally

    if (assigned (ActualPart)) then ActualPart.Free;

  end;

  DebOut (self, MethodName, 'end.');

end;


class function TReceiveFilePostprocessor.PartsAsString (const Parts: array of TBinSplitPart; Hex: Boolean): string;

  function Test (I: Integer): Boolean;
  begin
    result := not assigned (Parts[I])
  end;

  function AsString (I: Integer): string;
  begin
    if (Hex) then begin
      result := IntToHex (I + 1, 2);
    end else begin
      result := IntToStr (I + 1);
    end;
  end;

var
  B: Boolean;
  S: string;
  N: Integer;
  H: Integer;
begin
  result := '';
  B := false;
  S := '';
  H := -1;
  for N := High (Parts) downto Low(Parts) do begin
    if (Test(N)) then begin
      H := N;
      break;
    end;
  end;
  if H < 0 then Exit;
  for N := Low(Parts) to H do begin
    if (Test (N)) then begin
      if (N < H) and (test(N+1)) then begin
        if not B then begin
          B := true;
          S := S + AsString (N) + '..';
        end;
      end else begin
        B := false;
        S := S + AsString (N);
        if N < H then S := S + ', ';
      end;
    end;
  end;
  result := S;
end;


procedure   TReceiveFilePostprocessor.ChannelPrompt (aText: String; aType: TDisplayType);
const
  MethodName = 'ChannelPrompt';
begin
  DebOut (self, MethodName, aText);
  if assigned (FPacketConnection) then FPacketConnection.ChannelPrompt (aText, aType);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

