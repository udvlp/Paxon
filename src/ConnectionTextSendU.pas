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


unit ConnectionTextSendU;


interface


uses
  Classes, Windows, SysUtils, Messages,
  GlobalU, InterfacesU, SendFileU, ConnectionAbstractU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionTextSend = class (TConnectionAbstract)
  private
    Stream: TStream;
    LastCR: Boolean;
  public
    procedure   Init; override;
    procedure   ReceiveData; override;
    procedure   SendingPossible; override;
    procedure   Terminated (Why: TWhyTerminated); override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$I+}

uses
  SoundsU, SoundsConstsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionTextSend.Init;
begin
  UseEvent [e_receivedata] := true;
  UseEvent [e_sendingpossible] := true;
  Stream := PacketConnection.FileSender.Stream;
  Stream.Position := 0;
  LastCR := false;
  PacketConnection.SendTextData (PacketConnection.FileSender.TextBefore, true, true, false, false);
  Sounds.PlayEvent (se_transfer_start, PacketConnection);
  PacketConnection.FileSender.Absolute := Stream.Size;
  PacketConnection.FileSender.TransferBegin;
end;


procedure   TConnectionTextSend.ReceiveData;
resourcestring
  STextFileSendCanceled = 'Textdatei-Senden abgebrochen.';

var
  S, T: String;
  M: Integer;

begin
  while (not PacketConnection.ReceiveQueue.isEmpty) do begin
    S := PacketConnection.ReceiveQueue.dequeueLine;
    M := Length (S);
    if (M >= 1) then begin
      if (S[1] = '#') or (S[1] = '/') then begin
        if (S[M] = #13) then Delete (S, M, 1);
        T := UpperCase (S);
        if (T = '#ABORT#') or (T = '//ABORT') or (T = '//CUT') then begin
          if (PacketConnection.StationType in [st_unknown, st_terminal]) then
            PacketConnection.SendTextData (RemotePrompt + STextFileSendCanceled + #13, true, false, false, false);
          AbortTransfer;
          break;
        end;
      end;
      PacketConnection.ChannelReceiveText (S);
    end;
  end;
end;


procedure   TConnectionTextSend.SendingPossible;
var
  S: String;
  I, J, N: Integer;
  C: Char;

begin

  SetLength (S, PackLen);
  N := Stream.Read (S[1], PackLen);
  SetLength (S, N);

  if (N <= 0) then begin

    Finish;

  end else begin

    // Line endings for packet radio: CR LF -> CR, LF alone -> CR.
    // A CR LF can be split across two packets, hence LastCR across packets.
    J := 0;
    for I := 1 to N do begin
      C := S[I];
      if (C = #10) then begin
        if (not LastCR) then begin
          Inc (J);
          S[J] := #13;
        end;
      end else begin
        Inc (J);
        S[J] := C;
      end;
      LastCR := (C = #13);
    end;
    SetLength (S, J);

    PacketConnection.FileSender.Progress := PacketConnection.FileSender.Progress + N;

    if (J > 0) then begin
      PacketConnection.FileSender.Transfer (J);
      PacketConnection.DeviceQueue.enqueue (S);
      PacketConnection.ChannelSendText (S);
    end;

  end;

end;


procedure   TConnectionTextSend.Terminated (Why: TWhyTerminated);
begin
  case Why of
    e_finish: Sounds.PlayEvent (se_transfer_success, PacketConnection);
    e_cancel: Sounds.PlayEvent (se_transfer_cancel, PacketConnection);
    e_abort: Sounds.PlayEvent (se_transfer_error, PacketConnection);
  end;
  PacketConnection.SendTextData (PacketConnection.FileSender.TextAfter, true, true, false, false);
  PacketConnection.FileSender.TransferEnd;
  PacketConnection.FileSender.Release;
  PacketConnection.FileSender := nil;
  inherited;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

