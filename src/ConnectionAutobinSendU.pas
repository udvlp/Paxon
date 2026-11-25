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


unit ConnectionAutobinSendU;


interface


uses
  Classes, Windows, SysUtils, Messages, GlobalU,
  InterfacesU, SendFileU, ConnectionAbstractU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionAutobinSend = class (TConnectionAbstract)
  private
    WaitforOk: Boolean;
    Stream: TStream;
    FileSender: ISendFile;
    Receivebuffer: String;
  public
    procedure   Init; override;
    procedure   ReceiveData; override;
    procedure   SendData; override;
    procedure   SendingPossible; override;
    procedure   Terminated (Why: TWhyTerminated); override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, FileStreamUlfU, CrcU, SoundsU, SoundsConstsU;

{$I+}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionAutobinSend.Init;
const
  MethodName = 'Init';
  BlockLen = 4096;

var
  S, T, U: string;
  I, N, L: Integer;
  MyCRC: Word;
  H: THandle;

begin

  UseEvent[e_receivedata] := true;
  UseEvent[e_senddata] := (PacketConnection.StationType in [st_unknown, st_terminal]);

  FileSender := PacketConnection.FileSender;

  assert (FileSender.TransferProtocol = prot_Autobin);

  Receivebuffer := '';

  Stream := FileSender.Stream;

  // AutoBIN kündigt die Länge als Integer an. Größere Dateien würden mit
  // abgeschnittener (ab 2 GiB negativer) Länge angekündigt; sie müssen geteilt
  // gesendet werden. Abbruch, bevor etwas gesendet ist.
  if (Stream.Size > MaxInt) then begin
    DebOut (self, MethodName, 'Datei zu groß für AutoBIN: %d', [Stream.Size]);
    AbortTransfer;
    exit;
  end;

  CanCancel := true;

  PacketConnection.SendTextData (FileSender.TextBefore, true, true, false, false);

  WaitForOK := true;

  L := Stream.Size;

  FileSender.Absolute := L;
  FileSender.TransferBegin;

  DebOut (self, MethodName, 'Berechne CRC...');
  MyCRC := 0;
  Stream.Position := 0;
  SetLength (S, BlockLen);
  while true do begin
    N := Stream.Read (S[1], BlockLen);
    if (N <= 0) then break;
    CalcCRC16OfStringLen (S, N, MyCRC);
  end;
  SetLength (S, 0);
  DebOut (self, MethodName, 'MyCRC = ' + IntToStr(MyCRC));
  Stream.Position := 0;

  H := 0;
  if (Stream is THandleStream) then begin
    H := (Stream as THandleStream).Handle;
  end else if (Stream is TFileStreamUlf) then begin
    H := (Stream as TFileStreamUlf).Handle;
  end;

  if (H <> 0) then begin
    I := FileGetDate (H);
  end else begin
    I := 0;
  end;

  T := ExtractFileName (FileSender.TargetFilename);

  S := '#BIN#'
     + IntToStr(L)
     + '#|' + IntToStr(MyCRC)
     + '#$' + IntToHex (I, 8)
     + '#';

  // The header goes out as one packet and may be at most PackLen bytes long:
  // shorten a long filename and keep the extension.
  N := PackLen - Length (S) - 1;
  if (Length (T) > N) then begin
    U := ExtractFileExt (T);
    if (Length (U) >= N) then begin
      T := Copy (T, 1, N);
    end else begin
      T := Copy (ChangeFileExt (T, ''), 1, N - Length (U)) + U;
    end;
  end;

  S := S + T + #13;

  PacketConnection.DeviceQueue.enqueue (S);
  PacketConnection.ChannelSendText (S);

  Sounds.PlayEvent (se_transfer_start, PacketConnection);

end;


procedure   TConnectionAutobinSend.ReceiveData;
var
  S: string;
  I: Integer;

begin

  while (not PacketConnection.ReceiveQueue.isEmpty) do begin

    S := PacketConnection.ReceiveQueue.dequeueLine;
    Receivebuffer := Receivebuffer + S;
    PacketConnection.ChannelReceiveText (S);

    while (true) do begin

      I := Pos (#13, ReceiveBuffer);
      if (I <= 0) then break;

      S := Copy (ReceiveBuffer, 1, I - 1);
      Delete (ReceiveBuffer, 1, I);

      if (WaitForOk) then begin
        if (copy (S, 1, 4) = '#NO#') or (copy (S, 1, 7) = '#ABORT#') then begin
          AbortTransfer;
          break;
        end else if (copy (S, 1, 4) = '#OK#') then begin
          WaitforOk := false;
          UseEvent[e_sendingpossible] := true;
        end;
      end else begin
        if (copy (S, 1, 7) = '#ABORT#') then begin
          AbortTransfer;
          break;
        end;
      end;

    end;

  end;

end;


procedure   TConnectionAutobinSend.SendData;
const
  AutobinId = 'SP\-';
var
  S, T: string;
  N: Integer;
begin
  // Text during the transfer: each packet starts with 'SP\-' and ends with #13,
  // otherwise the receiver takes it for file data. Together at most PackLen bytes
  // (hostmode allows 256); longer lines are split.
  S := PacketConnection.SendQueue.dequeueLine;
  N := Length (S);
  if (N > 0) and (S[N] = #13) then Delete (S, N, 1);
  repeat
    T := Copy (S, 1, PackLen - Length (AutobinId) - 1);
    Delete (S, 1, Length (T));
    PacketConnection.DeviceQueue.enqueue (AutobinId + T + #13);
  until (Length (S) = 0);
end;


procedure   TConnectionAutobinSend.SendingPossible;
var
  S: string;
  N, I: Integer;
begin
  for I := 1 to 5 do begin
    SetLength (S, PackLen);
    N := Stream.Read (S[1], PackLen);
    SetLength (S, N);
    if (N <= 0) then break;
    FileSender.Transfer (N);
    FileSender.Progress := FileSender.Progress + N;
    PacketConnection.DeviceQueue.enqueue (S);
  end;
  if N <= 0 then Finish;
end;


procedure   TConnectionAutobinSend.Terminated (Why: TWhyTerminated);
const
  MethodName = 'Terminated';

resourcestring
  SAutobinSendOk = 'Autobin-Senden ok.';
  SAutobinSendCanceled = 'Autobin-Senden abgebrochen.';

begin

  DebOut (self, MethodName, 'begin...');

  case Why of
    e_finish: Sounds.PlayEvent (se_transfer_success, PacketConnection);
    e_cancel: Sounds.PlayEvent (se_transfer_cancel, PacketConnection);
    e_abort: Sounds.PlayEvent (se_transfer_error, PacketConnection);
  end;

  if (assigned (PacketConnection)) then begin

    if (Why = e_cancel) then begin

      PacketConnection.DeviceQueue.enqueue ('#ABORT#'#13);

    end else if (Why = e_finish) then begin

      PacketConnection.SendTextData (FileSender.TextAfter, true, true, false, false);

      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (RemotePrompt + SAutobinSendOk + #13, true, false, false, false);
      end;

    end;

    if (Why in [e_cancel, e_abort]) then begin
      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (#13 + RemotePrompt + SAutobinSendCanceled + #13, true, false, false, false);
      end else begin
        PacketConnection.ChannelPrompt (SAutobinSendCanceled + #13, dt_pgp);
      end;
    end;

  end;

  if (assigned (FileSender)) then begin
    FileSender.TransferEnd;
    FileSender.Release;
    FileSender := nil;
  end;

  inherited;

  DebOut (self, MethodName, 'end.');

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

