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


unit ConnectionDidaditReceiveU;


interface


uses
  Classes, Windows, SysUtils, Messages,
  GlobalU, InterfacesU, FileStreamUlfU, SendFileU, MD5U, ConnectionAbstractU,
  ConnectionDidaditU, ConnectionDidaditReceiveBlockListU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

type

  TState = (state_unknown, state_info, state_data, state_end);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionDidaditReceive = class (TConnectionDidadit)
  private

    Abort: Boolean;
    MD5Error: Boolean;
    State: TState;
    FileSender: ISendFile;
    Receivebuffer: String;
    BlockSize: Integer;
    BlockList: TDidaditReceiveBlockList;
    IndexName: String;
    FileOpened: Boolean;

    procedure   InfoBlock (const DataText: String); virtual;
    function    DataBlock (const DataText: String; const BlockMD5: TMD5Digest): Boolean; virtual;
    procedure   FinBlock; virtual;
    function    FileMD5Ok: Boolean; virtual;

  protected

    procedure   Finish; override;
    procedure   AbortTransfer; override;

  public

    procedure   Init; override;
    procedure   ReceiveData; override;
    procedure   Terminated (Why: TWhyTerminated); override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, FolderU, ReceiveFilePostprocessorU, SoundsU, SoundsConstsU;

{$I+}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionDidaditReceive.Init;
const
  MethodName = 'Init';

var
  S: string;
  L: Integer;

begin

  inherited;

  State := state_unknown;

  Abort := false;
  MD5Error := false;
  FileOpened := false;
  IndexName := '';

  BlockList := TDidaditReceiveBlockList.create;

  BlockSize := DEFAULT_BLOCKSIZE;

  CanCancel := true;

  S := PacketConnection.ReceiveQueue.dequeueLine;
  L := Length (S);
  if (L > 0) and (S[L] = #13) then Delete (S, L, 1);
  DebOut (self, MethodName, 'Didadit-Header: ' + S);

  UseEvent[e_receivedata] := true;
  UseEvent[e_senddata] := false;

  FileSender := TSendFile.create (PacketConnection);

  S := '#OK#'#13;
  PacketConnection.DeviceQueue.enqueue (S);
  PacketConnection.ChannelSendText (S);

  FileSender.TransferPrepare;

  State := state_info;

  Sounds.PlayEvent (se_transfer_start, PacketConnection);

end;


procedure   TConnectionDidaditReceive.ReceiveData;
const
  MethodName = 'ReceiveData';

var
  S: String;
  I: Integer;
  BlockID: Word;
  DataText: String;
  BlockMD5: TMD5Digest;

begin

  if Abort then begin

    exit;

  end else begin

    // After an abort or end, do not evaluate any further blocks (a later
    // FIN must not, e.g., turn an abort into an end).
    while (State <> state_end) and (not PacketConnection.ReceiveQueue.isEmpty) do begin

      Receivebuffer := Receivebuffer + PacketConnection.ReceiveQueue.dequeue;

      while (State <> state_end) do begin

        I := Pos (FEND, ReceiveBuffer);

        if (I <= 0) then break;

        S := Copy (ReceiveBuffer, 1, I - 1);
        Delete (ReceiveBuffer, 1, I);

        if (Length (S) > 0) then begin

          if (DecodeBlock (S, BlockID, DataText, BlockMD5)) then begin

            case BlockID of

              DIDADIT_BLOCK_INFO: begin
                InfoBlock (DataText);
              end;

              DIDADIT_BLOCK_START: begin
                DebOut (self, MethodName, 'Empfange START: Nicht beim Empfangen.');
                SendError (100, ['START']);
              end;

              DIDADIT_BLOCK_ERR: begin
                DebOut (self, MethodName, 'Empfange ERR: %s', [DataText]);
                PacketConnection.ChannelPrompt ('Empfange ERR: ' + DataText, dt_pgp);
                I := Pos (' ', DataText);
                if (I <= 0) then I := MaxInt;
                I := StrToIntDef (Copy (DataText, 1, I - 1), -1);
                if (I < 0) or ((I mod 100) < 50) then begin
                  AbortTransfer;
                end;
              end;

              DIDADIT_BLOCK_DATA: begin
                if (State <> state_data) then begin
                  DebOut (self, MethodName, 'Empfange DATA: Falscher Zustand');
                  SendError (100, ['DATA']);
                end else if (not DataBlock (DataText, BlockMD5)) then begin
                  SendError (300);
                  AbortTransfer;
                end;
              end;

              DIDADIT_BLOCK_FIN: begin
                FinBlock;
              end;

              DIDADIT_BLOCK_REQ: begin
                DebOut (self, MethodName, 'Empfange REQ: Nicht beim Senden.');
                SendError (100, ['REQ']);
              end;

              DIDADIT_BLOCK_FINACK: begin
                // Only the receiver sends FINACK; coming from the sender it is not a valid end.
                DebOut (self, MethodName, 'Empfange FINACK: Nicht beim Empfangen.');
                SendError (100, ['FINACK']);
              end;

              DIDADIT_BLOCK_ECHOREQ: begin
                DebOut (self, MethodName, 'Empfange ECHOREQ: "%s".', [DataText]);
                SendBlock (DIDADIT_BLOCK_ECHOREP, DataText);
              end;

              DIDADIT_BLOCK_ECHOREP: begin
                DebOut (self, MethodName, 'Empfange ECHOREP: Verworfen');
              end;

              DIDADIT_BLOCK_ABORT: begin
                DebOut (self, MethodName, 'Empfange ABORT: Abbrechen');
                AbortTransfer;
              end;

              DIDADIT_BLOCK_CHAT: begin
                PacketConnection.ChannelReceiveText (DataText);
              end;

              else begin
                DebOut (self, MethodName, 'Empfange UNBEKANNTEN BLOCK.');
                SendError (150);
              end;

            end;

          end else begin

            DebOut (self, MethodName, 'Fehler');

          end;

        end;

      end;

    end;

  end;

end;


procedure   TConnectionDidaditReceive.InfoBlock (const DataText: String);
const
  MethodName = 'InfoBlock';

  function CallToFileName (const Call: String): String;
  var
    I: Integer;
  begin
    // Callsign as part of a file name: only letters, digits and '-'.
    result := UpperCase (Call);
    for I := 1 to Length (result) do begin
      if (not (result[I] in ['A'..'Z', '0'..'9', '-'])) then result[I] := '_';
    end;
  end;

resourcestring
  SInvalidHeader = 'Ungültiger Header.';
  SCannotOpenFile = 'Datei kann nicht geöffnet werden.';

var
  SL: TStringList;
  N: Integer;
  S, T: String;
  FileName: String;
  FileLen: Integer;
  OtherBlockSize: Boolean;
  Features: TStringList;
  Offset: Integer;
  MD5Ok: Boolean;

begin

  if (State = state_info) then begin

    SL := TStringList.create;

    try

      SL.Text := DataText;

      // FILENAME, PATH, SIZE, MD5, TIME, BLOCKSIZE, VERSION

      for N := 0 to SL.Count - 1 do begin
        DebOut (self, MethodName, SL[N]);
      end;

      FileName := SL.Values['FILENAME'];

      FileLen := StrToIntDef (SL.Values['SIZE'], -1);
      BlockList.Size := FileLen;

      // MD5 must be present and valid: it names the partial file and
      // is used at the end to verify the received file.
      S := SL.Values['MD5'];
      MD5Ok := (Length (S) = 2 * sizeof (MD5));
      for N := 1 to Length (S) do begin
        if (not (S[N] in ['0'..'9', 'A'..'F', 'a'..'f'])) then MD5Ok := false;
      end;

      if (not MD5Ok) then begin
        DebOut (self, MethodName, 'INFO ohne gültige MD5.');
        SendError (202);
        exit;
      end;

      MD5 := StringToMD5 (S);

      if (FileLen < 0) then begin
        DebOut (self, MethodName, 'INFO ohne gültige Größe.');
        SendError (203);
        exit;
      end;

      N := StrToIntDef (SL.Values['BLOCKSIZE'], 0);

      Features := TStringList.create;
      try
        Features.CommaText := SL.Values['FEATURES'];
        Chat := (Features.IndexOf (FEATURE_CHAT) >= 0);
        Features.Clear;
      finally
        Features.free;
      end;

      UseEvent[e_senddata] := Chat;

      if (N >= 256) and (N <= 16384) then begin
        OtherBlockSize := false;
        BlockSize := N;
      end else begin
        OtherBlockSize := true;
        BlockSize := DEFAULT_BLOCKSIZE;
      end;

      // The partial file is named after MD5 and callsign: a transfer of another
      // station with the same MD5 never touches this station's partial file.
      // It is resumed only if its index file names the same callsign and size.
      BlockList.Call := UpperCase (PacketConnection.Call);
      T := MD5ToString (MD5) + '_' + CallToFileName (PacketConnection.Call);
      S := ApplicationDataPath + IncompleteFiles + T + '.pxf';
      Offset := -1;
      if (FileExists (S)) then begin
        Offset := BlockList.ReadIndexFile (T);
        if (Offset < 0) then begin
          DebOut (self, MethodName, 'Teildatei gehört nicht zu dieser Übertragung: neu beginnen.');
          // If deleting fails (e.g. file in use), CreateIncompleteFile fails as well
          // and the transfer is aborted with error 300.
          if (not DeleteFile (S)) then begin
            DebOut (self, MethodName, 'Löschen fehlgeschlagen: ' + S);
          end;
        end;
      end;
      if (Offset < 0) then begin
        S := CreateIncompleteFile (T);
        Offset := 0;
      end;
      IndexName := T;

      FileSender.TransferProtocol := prot_Didadit;
      FileSender.Absolute := FileLen;

      PacketConnection.FileSender := FileSender;

      FileSender.TransferBegin;

      FileSender.Stream := TFileStreamUlf.create;
      (FileSender.Stream as TFileStreamUlf).FileName := S;
      FileSender.SourceFilename := S;

      FileSender.TargetFilename := FileName;

      DebOut (self, MethodName, 'Zieldatei: %s ', [FileSender.TargetFilename]);
      DebOut (self, MethodName, 'Quelldatei: %s', [FileSender.SourceFilename]);
      DebOut (self, MethodName, 'Dateigröße: %d', [FileLen]);

      if (FileLen < 0) then begin

        Abort := true;

      end else begin

        (FileSender.Stream as TFileStreamUlf).Mode := fmOpenReadWrite or fmShareDenyWrite;

        try
          (FileSender.Stream as TFileStreamUlf).Open;
          FileOpened := true;
          // if (FileDate <> -1) then FileSetDate ((FileSender.Stream as TFileStreamUlf).Handle, FileDate);
        except
          Abort := true;
        end;

      end;

      if (Abort) then begin

        SendError (300);
        AbortTransfer;

      end else begin

        S := Format ('OFFSET=%d'#13, [Offset]);

        if (OtherBlockSize) then begin
          S := S + 'BLOCKSIZE=' + IntToStr (BlockSize) + #13
        end;

        S := S + 'VERSION=' + DIDADIT_VERSION + #13;

        Features := TStringList.create;
        try
          if (Chat) then Features.Add (FEATURE_CHAT);
          if (Features.Count > 0) then S := S + 'FEATURES=' + Features.CommaText + #13;
        finally
          Features.free;
        end;

        DebOut (self, MethodName, 'Sende START.');

        SendBlock (DIDADIT_BLOCK_START, S);

        State := state_data;

      end;

    finally

      SL.free;

    end;

  end else begin

    DebOut (self, MethodName, 'Empfange INFO: Falscher Zustand');
    SendError (100, ['INFO']);

  end;

end;


function    TConnectionDidaditReceive.DataBlock (const DataText: String; const BlockMD5: TMD5Digest): Boolean;
const
  MethodName = 'DataBlock';

// Result false: file not writable (caller reports error 300).
// Faulty blocks are discarded, blocks outside the file are rejected with error 104.

var
  Off: Integer;
  Len: Word;
  I, L: Integer;
  Error: Boolean;

begin

  assert (sizeof (Off) = 4);
  assert (sizeof (Len) = 2);

  Error := false;
  result := true;

  // Data comes from the remote station: check length, offset and MD5.

  L := Length (DataText);
  if (L < sizeof (Off) + sizeof (Len)) then begin
    DebOut (self, MethodName, 'DATA zu kurz (%d Bytes): verworfen.', [L]);
    exit;
  end;

  if (MD5ToString (BlockMD5) <> MD5ToString (MD5)) then begin
    DebOut (self, MethodName, 'DATA mit fremder MD5: verworfen.');
    exit;
  end;

  Move (DataText[1], Off, sizeof (Off));
  Move (DataText[5], Len, sizeof (Len));


  if (Len > 0) then begin

    if (L < Len + sizeof (Len) + sizeof (Off)) then begin
      DebOut (self, MethodName, 'DATA kürzer als angegeben (%d statt %d Bytes): verworfen.',
              [L - sizeof (Len) - sizeof (Off), Len]);
      exit;
    end;

    if (Off < 0) or (Off > BlockList.Size - Len) then begin
      DebOut (self, MethodName, 'DATA außerhalb der Datei (Offset %d, Länge %d, Größe %d).', [Off, Len, BlockList.Size]);
      SendError (104);
      exit;
    end;

    try
      FileSender.Stream.Position := Off;
      if (FileSender.Stream.Write (DataText[7], Len) <> Len) then Error := true;
    except
      Error := true;
    end;

    if (not Error) then begin
      FileSender.Transfer (Len);
      I := BlockList.Add (Off, Len);
      FileSender.Progress := I;
    end;

  end;

  result := not Error;

end;


procedure TConnectionDidaditReceive.FinBlock;
const
  MethodName = 'FinBlock';

var
  Requests: Array of TRequest;
  I, N: Integer;
  Max: Integer;
  S: String;

begin

  if (State <> state_data) then begin
    DebOut (self, MethodName, 'Empfange FIN: Falscher Zustand');
    SendError (100, ['FIN']);
    exit;
  end;

  Max := BlockSize div sizeof (TRequest) - 1;
  SetLength (Requests, Max);
  N := BlockList.GetRequests (Requests);
  SetLength (Requests, N);

  if (N > 0) then begin

    DebOut (self, MethodName, 'Sende %d Request(s).', [N]);
    for I := 0 to N - 1 do begin
      DebOut (self, MethodName, 'Sende REQ Offset %d, Länge %d', [Requests[I].Offset, Requests[I].Length]);
    end;

    SetLength (S, sizeof (TRequest) * N);
    Move (Requests[0], S[1], sizeof (TRequest) * N);

    SendBlock (DIDADIT_BLOCK_REQ, S);

  end else if (FileMD5Ok) then begin

    DebOut (self, MethodName, 'Sende FINACK.');
    SendBlock (DIDADIT_BLOCK_FINACK, S);
    Finish;

  end else begin

    // File complete but MD5 wrong: error 102 (aborts), do not store the file.
    DebOut (self, MethodName, 'MD5 der empfangenen Datei stimmt nicht.');
    MD5Error := true;
    SendError (102);

  end;

end;


function    TConnectionDidaditReceive.FileMD5Ok: Boolean;
const
  MethodName = 'FileMD5Ok';
  BufLen = 16384;

var
  MD5Context: TMD5Context;
  Digest: TMD5Digest;
  Buffer: String;
  BytesRemaining, N: Integer;

begin

  // Check the completely received file against the MD5 from the INFO block.
  // The file belongs to this transfer (new, or resumed with matching callsign
  // and size), so excess bytes at the end may be truncated.

  try

    if (FileSender.Stream.Size > BlockList.Size) then begin
      FileSender.Stream.Size := BlockList.Size;
    end;

    MD5Init (MD5Context);
    FileSender.Stream.Position := 0;
    SetLength (Buffer, BufLen);
    BytesRemaining := BlockList.Size;
    while (BytesRemaining > 0) do begin
      N := FileSender.Stream.Read (Buffer[1], BufLen);
      if (N <= 0) then break;
      MD5Update (MD5Context, Buffer[1], N);
      Dec (BytesRemaining, N);
    end;
    MD5Final (Digest, MD5Context);

    result := (BytesRemaining = 0) and (MD5ToString (Digest) = MD5ToString (MD5));

  except
    on E: Exception do begin
      DebOut (self, MethodName, 'Fehler: ' + E.Message);
      result := false;
    end;
  end;

end;


procedure   TConnectionDidaditReceive.Terminated (Why: TWhyTerminated);
const
  MethodName = 'Terminated';

resourcestring
  SDidaditReceiveOk    = 'Didadit-Empfang ok.';
  SDidaditReceiveAbort = 'Didadit-Empfang abgebrochen.';

var
  ReceiveFilePostprocessor: TReceiveFilePostprocessor;

begin

  if (assigned (PacketConnection)) then begin

    if (Why = e_cancel) then begin

      SendBlock (DIDADIT_BLOCK_ABORT, '');

    end else if (Why = e_finish) then begin

      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (RemotePrompt + SDidaditReceiveOk + #13, true);
      end;

      ReceiveFilePostprocessor := TReceiveFilePostprocessor.create (PacketConnection);
      try
        ReceiveFilePostprocessor.Execute (FileSender);
      finally
        ReceiveFilePostprocessor.free;
      end;

    end;

    if (Why in [e_cancel, e_abort]) then begin
      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (#13 + RemotePrompt + SDidaditReceiveAbort + #13, true);
      end else begin
        PacketConnection.ChannelPrompt (SDidaditReceiveAbort + #13, dt_pgp);
      end;
    end;

    if (Length (ReceiveBuffer) > 0) then begin
      PacketConnection.ChannelReceiveText (ReceiveBuffer);
      ReceiveBuffer := '';
    end;

    if (assigned (PacketConnection.FileSender)) then PacketConnection.FileSender := nil;

  end;

  // Index file only if INFO was accepted and the partial file was opened.
  if (FileOpened) then begin
    BlockList.WriteIndexFile (IndexName);
  end;
  BlockList.free;

  FileSender.TransferEnd;
  if (FileSender.Stream is TFileStreamUlf) then begin
    (FileSender.Stream as TFileStreamUlf).Close;
    // Delete a complete file with wrong MD5 so that a new attempt starts from scratch.
    if (MD5Error) then begin
      try
        (FileSender.Stream as TFileStreamUlf).Delete;
      except
        on E: Exception do DebOut (self, MethodName, 'Löschen fehlgeschlagen: ' + E.Message);
      end;
    end;
  end;

  if (assigned (FileSender)) then begin
    FileSender.release;
    FileSender := nil;
  end;

  inherited;

end;


procedure   TConnectionDidaditReceive.AbortTransfer;
begin
  State := state_end;
  UseEvent[e_receivedata] := false;
  inherited;
end;


procedure   TConnectionDidaditReceive.Finish;
begin
  State := state_end;
  UseEvent[e_receivedata] := false;
  inherited;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

