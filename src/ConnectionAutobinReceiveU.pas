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


unit ConnectionAutobinReceiveU;


interface


uses
  Classes, Windows, SysUtils, Messages,
  GlobalU, FileStreamUlfU, InterfacesU, SendFileU, ConnectionAbstractU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

type

  TState = (state_unknown, state_ok, state_start, state_data, state_req);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionAutobinReceive = class (TConnectionAbstract)
  private
    Abort: Boolean;
    CRC: Boolean;
    MyCRC, OtherCRC: Word;
    FileLen, BytesRemaining: Integer;
    FileDate: Integer;
    FileSender: ISendFile;
  public
    procedure   Init; override;
    procedure   ReceiveData; override;
    procedure   SendData; override;
    procedure   Terminated (Why: TWhyTerminated); override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, FolderU, ReceiveFilePostprocessorU, CrcU,
  SoundsU, SoundsConstsU;


{$I+}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionAutobinReceive.Init;
resourcestring
  SInvalidHeader = 'Ungültiger Header.';
  SCannotOpenFile = 'Datei kann nicht geöffnet werden.';

const
  MethodName = 'Init';

var
  L, N, I: Integer;
  S: string;
  Header: string;
  FileName: string;

begin

  UseEvent[e_receivedata] := true;
  UseEvent[e_senddata] := true;

  CanCancel := true;

  Header := PacketConnection.ReceiveQueue.dequeueLine;

  L := Length (Header);
  if (L > 0) and (Header[L] = #13) then Delete (Header, L, 1);

  DebOut (self, MethodName, 'Header: ' + Header);

  delete (Header, 1, 5); // remove #BIN# at the start

  S := Header;
  I := Pos ('#', Header);
  if (I > 0) then begin
    delete (S, I, MaxInt);
    delete (Header, 1, I - 1);
  end else begin
    Header := '';
  end;
  FileLen := StrToIntDef (S, -1);

  DebOut (self, MethodName, 'Länge: ' + IntToStr(FileLen));

  CRC := false;
  OtherCRC := 0;
  if (copy (Header, 1, 2) = '#|') then begin
    Delete (Header, 1, 2);
    I := Pos ('#', Header);
    if (I > 0) then begin
      S := Copy (Header, 1, I - 1);
      Delete (Header, 1, I - 1);
    end else begin
      S := Header;
      Header := '';
    end;
    try
      OtherCRC := StrToInt (S);
      CRC := true;
    except
      OtherCRC := 0;
    end;
  end;

  if (CRC) then begin
    DebOut (self, MethodName, 'CRC: ' + IntToStr(OtherCRC));
  end else begin
    DebOut (self, MethodName, 'CRC: (keiner)');
  end;

  MyCRC := 0;

  FileDate := -1;

  if (copy (Header, 1, 2) = '#$') then begin
    Delete (Header, 1, 2);
    I := Pos ('#', Header);
    if (I > 0) then begin
      S := Copy (Header, 1, I - 1);
      Delete (Header, 1, I);
    end else begin
      S := Header;
      Header := '';
    end;
    FileDate := StrToIntDef ('$' + S, -1);
  end else if (Copy (Header, 1, 1) = '#') then begin
    Delete (Header, 1, 1);
  end;

  BytesRemaining := FileLen;

  if (Length (Header) > 0) then begin
    FileName := Header;
    N := LastDelimiter ('/\:', FileName);
    if (N > 0) then Delete (FileName, 1, N);
  end else begin
    FileName := '';
  end;

  if (Length (FileName) = 0) then begin
    FileName := PacketConnection.Call + '.dat';
  end;

  assert (Length (FileName) > 0);

  FileSender := TSendFile.create (PacketConnection);

  S := CreateIncompleteFile;

  FileSender.Stream := TFileStreamUlf.create;
  (FileSender.Stream as TFileStreamUlf).FileName := S;
  FileSender.SourceFilename := S;

  FileSender.TargetFilename := FileName;

  DebOut (self, MethodName, 'Zieldatei: ' + FileSender.TargetFilename);
  DebOut (self, MethodName, 'Quelldatei: ' + FileSender.SourceFilename);

  Abort := false;

  if (FileLen < 0) then begin

    Abort := true;

  end else begin

    (FileSender.Stream as TFileStreamUlf).Mode := fmCreate or fmShareExclusive;

    try
      (FileSender.Stream as TFileStreamUlf).Open;
      if (FileDate <> -1) then FileSetDate((FileSender.Stream as TFileStreamUlf).Handle, FileDate);
    except
      Abort := true;
    end;

  end;

  if (Abort) then begin

    Sounds.PlayEvent (se_transfer_error, PacketConnection);

    PacketConnection.SendTextData ('#NO#'#13, true);
    AbortTransfer;

  end else begin

    Sounds.PlayEvent (se_transfer_start, PacketConnection);

    PacketConnection.SendTextData ('#OK#'#13, true);

    FileSender.SourceFilename := (FileSender.Stream as TFileStreamUlf).FileName;
    FileSender.TransferProtocol := prot_Autobin;
    FileSender.Absolute := FileLen;

    PacketConnection.FileSender := FileSender;

    FileSender.TransferBegin;

  end;

end;


procedure   TConnectionAutobinReceive.ReceiveData;
var
  L: Integer;
  B: Boolean;
  S: string;

begin

  L := PacketConnection.ReceiveQueue.dequeuePacket (S, BytesRemaining);

  if (L >= 1) then begin

    B := true;
    if (S[L] = #13) then begin
      if (S = '#ABORT#'#13) then begin
        Abort := true;
        B := false;
      end else if (copy (S, 1, 4) = 'SP\-') then begin
        if (assigned (PacketConnection.ChannelRef)) then PacketConnection.ChannelReceiveText (copy (S, 5, MaxInt));
        B := false;
      end;
    end;

    if (B) then begin
      CalcCRC16OfStringLen (S, L, MyCRC);
      FileSender.Stream.write (S[1], L);
      FileSender.Transfer (L);
      Dec (BytesRemaining, L);
      FileSender.Progress := FileLen - BytesRemaining;
    end;

  end;

  if (Abort) then begin
    AbortTransfer;
  end else if (BytesRemaining <= 0) then begin
    Finish;
  end;

end;


procedure   TConnectionAutobinReceive.SendData;
begin
  PacketConnection.DeviceQueue.enqueue (PacketConnection.SendQueue.dequeueLine);
end;


procedure   TConnectionAutobinReceive.Terminated (Why: TWhyTerminated);
resourcestring
  SAutobinOk = 'Autobin-Empfang ok.';
  SAutobinOkWithoutCRC = 'Autobin-Empfang ok. (ohne CRC-Prüfung.)';
  SAutobinCanceled = 'Autobin-Empfang abgebrochen.';
  SAutobinCRCErr = 'Autobin-Empfang CRC-Fehler.';

const
  MethodName = 'Terminated';

var
  S: string;
  ReceiveFilePostprocessor: TReceiveFilePostprocessor;

begin

  case Why of
    e_finish: Sounds.PlayEvent (se_transfer_success, PacketConnection);
    e_cancel: Sounds.PlayEvent (se_transfer_cancel, PacketConnection);
    e_abort: Sounds.PlayEvent (se_transfer_error, PacketConnection);
  end;

  if (assigned (PacketConnection)) then begin

    if (Why = e_cancel) then begin

      PacketConnection.DeviceQueue.enqueue ('#ABORT#'#13);

    end else if (Why = e_finish) then begin

      if (CRC) then begin
        if (MyCRC = OtherCRC) then begin
          S := SAutobinOk;
        end else begin
          S := SAutobinCRCErr;
          Abort := true;
        end;
      end else begin
        S := SAutobinOkWithoutCRC;
      end;

      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (RemotePrompt + S + #13, true);
      end else begin
        if (Abort) then PacketConnection.ChannelPrompt (S + #13, dt_pgp);
      end;

      if (not Abort) then begin
        ReceiveFilePostprocessor := TReceiveFilePostprocessor.create (PacketConnection);
        try
          ReceiveFilePostprocessor.Execute (FileSender);
        finally
          ReceiveFilePostprocessor.free;
        end;
      end;

    end;

    if (Why in [e_cancel, e_abort]) then begin
      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (#13 + RemotePrompt + SAutobinCanceled + #13, true);
      end else begin
        PacketConnection.ChannelPrompt (SAutobinCanceled + #13, dt_pgp);
      end;
    end;

    if (assigned (PacketConnection.FileSender)) then PacketConnection.FileSender := nil;

  end;

  FileSender.TransferEnd;

  if (FileSender.Stream is TFileStreamUlf) then begin
    (FileSender.Stream as TFileStreamUlf).Close;
    if (Why <> e_finish) or (Abort) then begin
      (FileSender.Stream as TFileStreamUlf).Recycle;
    end;
  end;

  if (assigned (FileSender)) then begin
    FileSender.release;
    FileSender := nil;
  end;

  inherited;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

