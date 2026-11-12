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


unit SendFilePreprocessorU;


interface


uses
  Windows, SysUtils, Classes, InterfacesU, GlobalU, SyncObjs, PublisherU,
  FileStreamUlfU, PGPClassU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TSendFilePreprocessor = class
  private

    FStream: TStream;
    FFileToSend: string;
    FPacketConnection: IConnection;
    FTransferProtocol: TSendFileProtocol;
    FPGPEnabled: Boolean;
    FPGPPassword: string;
    FPGPKey: Pointer;
    FPGPCommentText: string;
    FPGP: TPGP;
    FSizePerPart: Integer;
    FTextAfter: string;
    FTextBefore: string;
    FPartsCount: Integer;
    FSelectedParts: Array of Boolean;
    FAllParts: Boolean;

    procedure   BinSplit;
    procedure   DontSplit;
    function    InsertValues (Text, PartFile: string; PartNo, PartCnt: Integer): string;
    procedure   ProcessText;
    procedure   PGPSign (InStream: TStream; OutStream: TStream; aKey: Pointer; aPwd: String; aComment: String = '');
    procedure   SetTextAfter (const Value: string);
    procedure   SetTextBefore (const Value: string);
    procedure   SetPartsCount (const Value: Integer);
    function    GetPartItems (I: Integer): Boolean;
    procedure   SetPartItems (I: Integer; const Value: Boolean);
    procedure   SetAllParts (const Value: Boolean);

  public

    property    Stream: TStream read FStream write FStream;
    property    FileNameStr: string read FFileToSend write FFileToSend;
    property    PacketConnection: IConnection read FPacketConnection write FPacketConnection;
    property    TransferProtocol: TSendFileProtocol read FTransferProtocol write FTransferProtocol;
    property    TextBefore: string read FTextBefore write SetTextBefore;
    property    TextAfter: string read FTextAfter write SetTextAfter;
    property    SizePerPart: Integer read FSizePerPart write FSizePerPart;
    property    PartsCount: Integer read FPartsCount write SetPartsCount;
    property    PartItems[I: Integer]: Boolean read GetPartItems write SetPartItems;
    property    AllParts: Boolean read FAllParts write SetAllParts;
    property    PGPEnabled: Boolean read FPGPEnabled write FPGPEnabled;
    property    PGPPassword: string read FPGPPassword write FPGPPassword;
    property    PGPKey: Pointer read FPGPKey write FPGPKey;
    property    PGPCommentText: string read FPGPCommentText write FPGPCommentText;
    property    PGP: TPGP read FPGP write FPGP;
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   Execute;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, SendFileU, CrcU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSendFilePreprocessor.AfterConstruction;
begin
  inherited;
  FPGPEnabled := False;
  FPGPPassword := '';
  FPGPKey := nil;
end;


procedure   TSendFilePreprocessor.BeforeDestruction;
begin
  FPacketConnection := nil;
  inherited;
end;


procedure   TSendFilePreprocessor.SetTextAfter (const Value: string);
begin
  FTextAfter := Value;
end;


procedure   TSendFilePreprocessor.SetTextBefore (const Value: string);
begin
  FTextBefore := Value;
end;


procedure   TSendFilePreprocessor.Execute;
begin
  if (FTransferProtocol = prot_text) then begin
    ProcessText;
  end else begin
    if (FSizePerPart > 0) and (FTransferProtocol in [prot_autobin, prot_didadit]) then begin
      BinSplit;
    end else begin
      DontSplit;
    end;
  end;
end;


procedure   TSendFilePreprocessor.BinSplit;
const
  MethodName = 'BinSplit';

resourcestring
  SPartFileError = 'Die Teildatei "%s" kann nicht angelegt werden, das Senden wird abgebrochen:'#13'%s';

var
  FS: TFileStreamUlf;
  S: string;
  N, I: Integer;
  PartFilename: string;
  TempFileName: string;
  TempPath: string;
  SR: TSearchRec;
  FileByteSize: Integer;
  FileDateStr: string;
  DT: TDateTime;
  PartSizeBytes: Integer;
  AdditionalData: string;
  CRC16: Word;
  Buffer: array of Byte;
  AccumulatedCRC32: Cardinal;
  CRC32: Cardinal;
  FileSender: ISendFile;
  PartsCount: Integer;
  PartNo: Integer;
  CreatePart: Boolean;
  HasError: Boolean;
  PartItems: TInterfaceList;

begin

  PartSizeBytes := FSizePerPart * 1024;

  if FindFirst (FFileToSend, faAnyFile, SR) = 0 then begin
    FileByteSize := SR.Size;
    DT := FileDateToDateTime(SR.Time);
  end else begin
    FileByteSize := 0;
    DT := 0;
  end;
  FindClose (SR);

  PartsCount := (FileByteSize - 1) div PartSizeBytes + 1;

  if (PartsCount > 1) then begin

    FileDateStr := FormatDateTime ('yyyymmddhhmmss', DT);

    SetLength (TempPath, MAX_PATH);
    I := GetTempPath (MAX_PATH, PChar(TempPath));
    SetLength (TempPath, I);
    if (I <= 0) then begin
      DebOut (self, MethodName, 'Temp-Pfad: Fehler');
    end else begin
      if (TempPath[I] <> '\') then TempPath := TempPath + '\';
      DebOut (self, MethodName, 'Temp-Pfad: ' + S);
    end;

    // Always free FStream, even on write or read errors (full disk etc.)
    try

      FStream.Position := 0;

      AccumulatedCRC32 := $FFFFFFFF;

      // Queue the parts only once all have been created: if a part fails,
      // no incomplete set is sent (the parts are freed together with PartItems).
      PartItems := TInterfaceList.create;
      try

        for PartNo := 1 to PartsCount do begin

          CreatePart := (FAllParts) or (FSelectedParts[PartNo - 1]);

          if (CreatePart) then begin

            PartFilename := ChangeFileExt (ExtractFileName (FFileToSend), AnsiLowerCase (Format ('.b%2.2x', [PartNo])));
            DebOut (self, MethodName, 'Teil-Dateiname: ' + PartFileName);

            AdditionalData := 'P' + #13 + ApplicationName + ' ' + Version + #13#10;

            SetLength (TempFileName, MAX_PATH);
            GetTempFileName (PChar(TempPath), 'pbs', 0, PChar(TempFileName));
            SetLength (TempFileName, StrLen(PChar(TempFileName)));
            TempFileName := AnsiLowerCaseFileName (TempFileName);

            DebOut (self, MethodName, 'Öffne Datei... ' + TempFileName);

            FS := TFileStreamUlf.create;

          end else begin

            FS := nil;

          end;

          try

            if (CreatePart) then begin

              FS.IsTemporary := true;
              FS.FileName := TempFileName;

              try
                FS.Mode := fmCreate;
                FS.Open;
                FS.Close;
                FS.Mode := fmOpenReadWrite or fmShareDenyWrite;
                FS.Open;
                HasError := false;
              except
                on E: Exception do begin
                  // Do not just skip this part: its bytes would not be read from FStream,
                  // the following parts would get shifted data and a wrong
                  // overall CRC. Therefore abort and report the error to the caller.
                  DebOut (self, MethodName, 'Fehler: ' + E.Message);
                  raise Exception.CreateFmt (SPartFileError, [PartFileName, E.Message]);
                end;
              end;

              if (not HasError) then begin

                DebOut (self, MethodName, 'ok.');

                S := Format ('>BS<'#10'%2.2x'#10'%2.2x'#10'%d'#10'%d'#10'%s'#10'%s'#10'%s'#0,
                            [PartNo,
                             PartsCount,
                             PartSizeBytes,
                             FileByteSize,
                             ExtractFileName (FFileToSend),
                             FileDateStr,
                             AdditionalData]);

                FS.write (S[1], Length (S));

                CRC16 := 0;
                CalcCRC16OfString (S, CRC16);

                S := IntToHex (CRC16, 4) + #10;
                FS.write (S[1], Length (S));

              end;

            end else begin

              HasError := false;

            end;

            if (not HasError) then begin

              SetLength (Buffer, PartSizeBytes);

              N := FStream.read (Buffer[0], PartSizeBytes);

              CRC32 := $FFFFFFFF;

              for I := 0 to N - 1 do begin
                AccumulatedCRC32 := CalcCRC32 (Buffer[I], AccumulatedCRC32);
                CRC32 := CalcCRC32 (Buffer[I], CRC32);
              end;

              if (CreatePart) then begin

                FS.write (Buffer[0], N);

                S := IntToHex ((not AccumulatedCRC32), 8) + #10;

                for I := 1 to Length (S) do begin
                  CRC32 := CalcCRC32 (Byte(S[I]), CRC32);
                end;

                S := S + IntToHex ((not CRC32), 8) + #10;
                FS.write (S[1], Length (S));

                FS.Position := 0;

                if (assigned (FPacketConnection)) and (assigned (FPacketConnection.SendFileQueue)) then begin
                  FileSender := TSendFile.create (FPacketConnection);
                  FileSender.SourceFilename := TempFileName;
                  FileSender.TargetFilename := PartFileName;
                  FileSender.TransferProtocol := FTransferProtocol;
                  FileSender.Stream := FS;
                  FileSender.TextBefore := InsertValues (FTextBefore, PartFileName, PartNo, PartsCount);
                  FileSender.TextAfter := InsertValues (FTextAfter, PartFileName, PartNo, PartsCount);
                  PartItems.Add (FileSender); // queue only after all parts
                  FileSender := nil;
                  FS := nil; // is freed in FileSender.
                end else begin
                  break;
                end;

              end;

            end;

          finally

            if (assigned (FS)) then FS.free;

          end;

        end;

        for I := 0 to PartItems.Count - 1 do begin
          FPacketConnection.SendFileQueue.Enqueue (PartItems[I] as ISendFile);
        end;

      finally
        PartItems.free;
      end;

    finally
      FStream.free;
      FStream := nil;
    end;

  end else begin

    DontSplit;

  end;

end;


procedure   TSendFilePreprocessor.DontSplit;
var
  FileSender: ISendFile;
  PartFileName: string;

begin

  if (assigned (FPacketConnection)) and (assigned (FPacketConnection.SendFileQueue)) then begin

    PartFileName := ExtractFileName (FFileToSend);

    FileSender := TSendFile.create (FPacketConnection);
    FileSender.SourceFilename := FFileToSend;
    FileSender.TransferProtocol := FTransferProtocol;
    FileSender.Stream := FStream;
    FileSender.TextBefore := InsertValues (FTextBefore, PartFileName, 1, 1);
    FileSender.TextAfter := InsertValues (FTextAfter, PartFileName, 1, 1);

    FPacketConnection.SendFileQueue.Enqueue (FileSender);
    FileSender := nil;
    FStream := nil; // is freed in FileSender.

  end;

end;


function    TSendFilePreprocessor.InsertValues (Text: string; PartFile: string; PartNo: Integer; PartCnt: Integer): string;
var
  N: Integer;
  L: Integer;
begin
  Result := '';
  L := Length (Text);
  N := 1;
  while (N <= L) do begin
    if Text[N] = '%' then begin
      Inc (N);
      case UpCase(Text[N]) of
        'N': begin
          Result := Result + ExtractFileName (PartFile);
        end;
        'O': begin
          Result := Result + ExtractFileName (FFileToSend);
        end;
        'P': begin
          Result := Result + Format ('%2.2d', [PartNo]);
        end;
        'Q': begin
          Result := Result + Format ('%2.2d', [PartCnt]);
        end;
        '%': begin
          Result := Result + '%';
        end;
      end;
    end else if (Text[N] <> #10) then begin
      Result := Result + Text[N];
    end;
    Inc (N);
  end;
  L := Length (Result);
  if (L > 0) and (Result[L] <> #13) then Result := Result + #13;
end;


procedure   TSendFilePreprocessor.ProcessText;
var
  OutStream: TMemoryStream;
  FileSender: ISendFile;

begin

  FileSender := TSendFile.create (FPacketConnection);

  if (FPGPEnabled) then begin
    OutStream := TMemoryStream.create;
    try
      PGPSign (FStream, OutStream, FPGPKey, FPGPPassword, PGPCommentText);
    except
      // Signing failed: send neither empty nor unsigned. The exception
      // goes to the caller (message); the transfer is aborted.
      OutStream.free;
      FStream.free;
      FStream := nil;
      raise;
    end;
    FileSender.Stream := OutStream; // is freed in FileSender.
    FStream.free;
    FStream := nil;
  end else begin
    FileSender.Stream := FStream; // is freed in FileSender.
    FStream := nil;
  end;

  FileSender.SourceFilename := FFileToSend;
  FileSender.TransferProtocol := FTransferProtocol;
  FileSender.TextBefore := InsertValues (FTextBefore, FFileToSend, 1, 1);
  FileSender.TextAfter := InsertValues (FTextAfter, FFileToSend, 1, 1);

  FPacketConnection.SendFileQueue.Enqueue (FileSender);

end;


procedure   TSendFilePreprocessor.PGPSign (InStream: TStream; OutStream: TStream; aKey: Pointer; aPwd: String;
                                           aComment: String = '');
const
  MethodName = 'PGPSign';

resourcestring
  SPGPNotAvailable = 'PGP ist nicht verfügbar.';
  SNoPGPKey = 'Es ist kein PGP-Schlüssel ausgewählt.';
  SNoResult = 'PGP hat keine signierte Nachricht geliefert.';
  SPGPSignError = 'Die Nachricht konnte nicht mit PGP signiert werden und wurde nicht gesendet:'#13'%s';

var
  I: Integer;
  SrcStream, DstStream: TMemoryStream;

begin

  // The key (aKey) comes from the PGP context of FPGP, so sign with FPGP as well.

  if (not assigned (FPGP)) then raise Exception.CreateFmt (SPGPSignError, [SPGPNotAvailable]);
  if (not assigned (aKey)) then raise Exception.CreateFmt (SPGPSignError, [SNoPGPKey]);

  SrcStream := nil;
  DstStream := nil;

  try

    if (InStream is TMemoryStream) then begin
      SrcStream := InStream as TMemoryStream;
    end else begin
      SrcStream := TMemoryStream.create;
      SrcStream.LoadFromStream (InStream);
    end;

    SrcStream.Seek (0, soFromEnd);
    I := 0;
    SrcStream.Write (I, 1);

    DstStream := TMemoryStream.create;
    DstStream.Size := SrcStream.Size + 65536;

    try
      I := FPGP.Sign (aKey, aPwd, aComment, SrcStream.Memory, SrcStream.Size - 1, DstStream.Memory, DstStream.Size);
    except
      on E: Exception do begin
        DebOut (self, MethodName, E.Message);
        raise Exception.CreateFmt (SPGPSignError, [E.Message]);
      end;
    end;

    if (I <= 0) or (I > DstStream.Size) then begin
      raise Exception.CreateFmt (SPGPSignError, [SNoResult]);
    end;

    DstStream.Size := I;

    OutStream.Position := 0;
    OutStream.CopyFrom (DstStream, 0);

  finally

    if (assigned (SrcStream)) and (SrcStream <> InStream) then SrcStream.free;
    DstStream.free;

  end;

end;


procedure   TSendFilePreprocessor.SetPartsCount (const Value: Integer);
begin
  FPartsCount := Value;
  if (FAllParts) then begin
    SetLength (FSelectedParts, 0);
  end else begin
    SetLength (FSelectedParts, FPartsCount);
  end;
end;


procedure   TSendFilePreprocessor.SetAllParts (const Value: Boolean);
begin
  FAllParts := Value;
  if (FAllParts) then begin
    SetLength (FSelectedParts, 0);
  end else begin
    SetLength (FSelectedParts, FPartsCount);
  end;
end;


function    TSendFilePreprocessor.GetPartItems (I: Integer): Boolean;
begin
  result := FSelectedParts[I];
end;


procedure   TSendFilePreprocessor.SetPartItems (I: Integer; const Value: Boolean);
begin
  FSelectedParts[I] := Value;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

