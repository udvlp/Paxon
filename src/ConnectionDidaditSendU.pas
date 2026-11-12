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


unit ConnectionDidaditSendU;


interface


uses
  Classes, Windows, SysUtils, Messages,
  GlobalU, MD5U, InterfacesU, SendFileU, ConnectionAbstractU,
  QueueU, ConnectionDidaditU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

type

  TState = (state_unknown, state_ok, state_start, state_data, state_req);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  PRequest = ^TRequest;
  TRequest = packed record
    Offset: Integer;
    Length: Integer;
  end;


  TConnectionDidaditSend = class (TConnectionDidadit)
  private

    State: TState;
    Stream: TStream;
    FileSender: ISendFile;
    Receivebuffer: String;
    BlockSize: Integer;
    Offset: Integer;
    ReqQueue: TQueue;

    procedure   ReqBlock (const DataText: String; const BlockMD5: TMD5Digest); virtual;

  protected

    procedure   Finish; override;
    procedure   AbortTransfer; override;

  public

    procedure   Init; override;
    procedure   ReceiveData; override;
    procedure   SendingPossible; override;
    procedure   Terminated (Why: TWhyTerminated); override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, SoundsU, SoundsConstsU, FileStreamUlfU;

{$I+}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionDidaditSend.Init;
const
  MethodName = 'Init';

var
  MD5Str, S: string;
  N, I, L: Integer;
  D: TDateTime;
  H: THandle;
  MD5Context: TMD5Context;

begin

  inherited;

  ReqQueue := TQueue.create;

  State := state_unknown;

  UseEvent[e_receivedata] := true;
  UseEvent[e_senddata] := false;

  FileSender := PacketConnection.FileSender;

  assert (FileSender.TransferProtocol = prot_didadit);

  Stream := FileSender.Stream;

  CanCancel := true;

  PacketConnection.SendTextData (FileSender.TextBefore, true, true, false, false);

  FileSender.TransferPrepare;

  DebOut (self, MethodName, 'Berechne MD5...');

  MD5Init (MD5Context);
  Stream.Position := 0;
  SetLength (S, 65536);
  while (true) do begin
    N := Stream.Read (S[1], 65536);
    if (N <= 0) then break;
    MD5UpdateBuffer (MD5Context, PChar(S), N);
  end;
  SetLength (S, 0);
  MD5Final (MD5, MD5Context);

  MD5Str := '';
  for I := 0 to 15 do MD5Str := MD5Str + IntToHex (Byte(MD5[I]), 2);

  DebOut (self, MethodName, 'MD5 = ' + MD5Str);
  Stream.Position := 0;

  H := 0;
  if (Stream is THandleStream) then begin
    H := (Stream as THandleStream).Handle;
  end else if (Stream is TFileStreamUlf) then begin
    H := (Stream as TFileStreamUlf).Handle;
  end;

  if (H <> 0) then begin
    D := FileDateToDateTime (FileGetDate (H));
  end else begin
    D := 0;
  end;

  BlockSize := DEFAULT_BLOCKSIZE;

  S := '#DIDADIT#'#13;
  PacketConnection.DeviceQueue.enqueue (S);
  PacketConnection.ChannelSendText (S);

  L := Stream.Size;

  FileSender.Absolute := L;
  FileSender.TransferBegin;

  S := 'FILENAME=' + ExtractFileName (FileSender.TargetFilename) + #13
     + 'SIZE=' + IntToStr (L) + #13
     + 'MD5=' + MD5Str + #13;

  if (D <> 0) then begin
    S := S + 'TIME=' + IntToStr (DateTimeToUnixTime (D)) + #13;
  end;

  S := S + 'BLOCKSIZE=' + IntToStr (BlockSize) + #13
         + 'VERSION=' + DIDADIT_VERSION + #13
         + 'FEATURES=' + FEATURE_CHAT + #13;

  DebOut (self, MethodName, 'Sende INFO.');

  SendBlock (DIDADIT_BLOCK_INFO, S);

  State := state_ok;

  Receivebuffer := '';

  Sounds.PlayEvent (se_transfer_start, PacketConnection);

end;


procedure   TConnectionDidaditSend.ReceiveData;
const
  MethodName = 'ReceiveData';

var
  S: String;
  I, N: Integer;
  BlockID: Word;
  DataText: String;
  BlockMD5: TMD5Digest;
  SL, SL2: TStringList;

begin

  DebOut (self, MethodName, 'begin...');

  while (not PacketConnection.ReceiveQueue.isEmpty) do begin

    Receivebuffer := Receivebuffer + PacketConnection.ReceiveQueue.dequeue;

    while (true) do begin

      case State of

        state_ok: begin

          I := Pos ('#ABORT#'#13, ReceiveBuffer);
          if (I > 0) then begin
            PacketConnection.ChannelReceiveText (copy (ReceiveBuffer, 1, I + 8 - 1));
            Delete (ReceiveBuffer, 1, I + 8 - 1);
            AbortTransfer;
            break;
          end else begin
            I := Pos ('#OK#'#13, ReceiveBuffer);
            if (I > 0) then begin
              PacketConnection.ChannelReceiveText (copy (ReceiveBuffer, 1, I + 5 - 1));
              Delete (ReceiveBuffer, 1, I + 5 - 1);
              State := state_start;
            end else begin
              break;
            end;
          end;
        end;

        state_start, state_data, state_req: begin

          I := Pos (FEND, ReceiveBuffer);

          if (I <= 0) then break;

          S := Copy (ReceiveBuffer, 1, I - 1);
          Delete (ReceiveBuffer, 1, I);

          if (Length (S) > 0) then begin

            if (DecodeBlock (S, BlockID, DataText, BlockMD5)) then begin

              case BlockID of

                DIDADIT_BLOCK_INFO: begin
                  DebOut (self, MethodName, 'Empfange INFO: Nicht beim Senden.');
                  SendError (100, ['INFO']);
                end;

                DIDADIT_BLOCK_START: begin
                  if (State = state_start) then begin
                    SL := TStringList.create;
                    try
                      SL.Text := DataText;
                      N := StrToIntDef (SL.Values['BLOCKSIZE'], 0);
                      if (N > 0) and (N < BlockSize) then BlockSize := N;
                      Offset := StrToIntDef (SL.Values['OFFSET'], 0);
                      DebOut (self, MethodName, 'Empfange START: Offset %d, BlockSize %d.', [Offset, BlockSize]);
                      S := SL.Values['FEATURES'];
                      if (Length (S) > 0) then begin
                        CharUpper (PChar(S));
                        SL2 := TStringList.create;
                        try
                          SL2.CommaText := S;
                          for N := 0 to SL2.Count - 1 do begin
                            DebOut (self, MethodName, 'Empfange START: Feature %s.', [SL2[N]]);
                          end;
                          Chat := (SL2.IndexOf (FEATURE_CHAT) >= 0);
                          UseEvent[e_senddata] := Chat;
                        finally
                          SL2.free;
                        end;
                      end;
                    finally
                      SL.free;
                    end;
                    State := state_data;
                    UseEvent[e_sendingpossible] := true;
                  end else begin
                    DebOut (self, MethodName, 'Empfange START: Falscher Zustand.');
                    SendError (100, ['START']);
                  end;
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
                  DebOut (self, MethodName, 'Empfange DATA: Nicht beim Senden.');
                  SendError (100, ['DATA']);
                end;

                DIDADIT_BLOCK_FIN: begin
                  DebOut (self, MethodName, 'Empfange FIN: Nicht beim Senden.');
                  SendError (100, ['FIN']);
                end;

                DIDADIT_BLOCK_REQ: begin
                  UseEvent[e_senddata] := Chat;
                  ReqBlock (DataText, BlockMD5);
                end;

                DIDADIT_BLOCK_FINACK: begin
                  DebOut (self, MethodName, 'Empfange FINACK: Beende Protokoll.');
                  Finish;
                end;

                DIDADIT_BLOCK_ECHOREQ: begin
                  DebOut (self, MethodName, 'Empfange ECHOREQ: "%s".', [DataText]);
                  SendBlock (DIDADIT_BLOCK_ECHOREP, DataText);
                end;

                DIDADIT_BLOCK_ECHOREP: begin
                  DebOut (self, MethodName, 'Empfange ECHOREP: Verworfen.');
                  // discard
                end;

                DIDADIT_BLOCK_ABORT: begin
                  DebOut (self, MethodName, 'Empfange ABORT: Abbrechen.');
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

              DebOut (self, MethodName, 'Fehler.');

            end;

          end;

        end;

        else begin

          assert (false);

        end;

      end;

    end;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TConnectionDidaditSend.ReqBlock (const DataText: String; const BlockMD5: TMD5Digest);
const
  MethodName = 'ReqBlock';

var
  I, N, L: Integer;
  B: Boolean;
  Req: PRequest;

begin

  L := Length (DataText);

  if ((L mod sizeof (TRequest)) <> 0) then begin

    SendError (101, [0, 0]);

  end else begin

    while (true) do begin
      Req := ReqQueue.dequeue;
      if (Req = nil) then break;
      Dispose (Req);
    end;

    N := L div 8;
    B := false;

    DebOut (self, MethodName, 'Empfange REQ: %d Request(s).', [N]);

    for I := 0 to N - 1 do begin

      New (Req);

      Move (DataText[I * sizeof (Req^) + 1], Req^, sizeof (Req^));

      DebOut (self, MethodName, 'Empfange REQ: Offset %d, Länge %d.', [Req^.Offset, Req^.Length]);
      if (Req.Offset < 0) or (Req.Length < 1) or (Req.Offset + Req.Length > Stream.Size) then begin
        SendError (101, [Req.Offset, Req.Length]);
        B := true;
        Dispose (Req);
        while (true) do begin
          Req := ReqQueue.dequeue;
          if (Req = nil) then break;
          Dispose (Req);
        end;
        break;
      end else begin
        ReqQueue.enqueue (Req);
      end;

    end;

    if (not B) then begin
      UseEvent[e_sendingpossible] := true;
    end;

  end;

end;


procedure   TConnectionDidaditSend.SendingPossible;
const
  MethodName = 'SendingPossible';

var
  Data, S: string;
  N, O, L: Integer;
  IsReq: Boolean;
  Req: PRequest;

begin

  if (not ReqQueue.IsEmpty) then begin
    IsReq := true;
    Req := ReqQueue.current;
    if (Req^.Length <= BlockSize) then begin
      O := Req^.Offset;
      L := Req^.Length;
      ReqQueue.dequeue;
      Dispose (Req);
    end else begin
      O := Req^.Offset;
      L := BlockSize;
      Inc (Req^.Offset, L);
      Dec (Req^.Length, L);
    end;
  end else begin
    IsReq := false;
    if (State = state_data) then begin
      O := Offset;
      L := BlockSize;
    end else begin
      O := -1;
      L := -1;
    end;
  end;

  N := 0;

  if (O >= 0) and (O <= Stream.Size) and (L >= 1) then begin
    SetLength (S, L);
    Stream.Position := O;
    N := Stream.Read (S[1], L);
    if (not IsReq) then Offset := Stream.Position;
    if (N <> L) then SetLength (S, N);
  end;

  if (N > 0) then begin

    if (not IsReq) then begin
      FileSender.Progress := O + N;
    end;

    FileSender.Transfer (N);

    SetLength (Data, 6 + N);

    assert (sizeof (O) = 4);
    Move (O, Data[1], 4);

    assert (sizeof (Word(N)) = 2);

    Move (N, Data[5], 2);

    Move (S[1], Data[7], N);

    SendBlock (DIDADIT_BLOCK_DATA, Data);

  end else begin


    SendBlock (DIDADIT_BLOCK_FIN, '');
    UseEvent[e_sendingpossible] := false;
    UseEvent[e_senddata] := false;

    // If FINACK does not arrive, the transfer waits until it is aborted manually

  end;

end;


procedure   TConnectionDidaditSend.Terminated (Why: TWhyTerminated);
const
  MethodName = 'Terminated';

resourcestring
  SDidaditSendOK = 'Didadit-Senden ok.';
  SDidaditSendAbort = 'Didadit-Senden abgebrochen.';

var
  Req: PRequest;

begin

  if (assigned (PacketConnection)) then begin

    if (Why = e_cancel) then begin

      SendBlock (DIDADIT_BLOCK_ABORT, '');

    end else if (Why = e_finish) then begin

      PacketConnection.SendTextData (FileSender.TextAfter, true, true, false, false);

      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (RemotePrompt + SDidaditSendOK + #13, true, false, false, false);
      end else begin
        PacketConnection.ChannelPrompt (SDidaditSendOk + #13, dt_pgp);
      end;

    end;

    if (Why in [e_cancel, e_abort]) then begin
      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (#13 + RemotePrompt + SDidaditSendAbort + #13, true, false, false, false);
      end else begin
        PacketConnection.ChannelPrompt (SDidaditSendAbort + #13, dt_pgp);
      end;
    end;

    if (Length (ReceiveBuffer) > 0) then begin
      PacketConnection.ChannelReceiveText (ReceiveBuffer);
      ReceiveBuffer := '';
    end;

  end;

  if (assigned (FileSender)) then begin
    FileSender.TransferEnd;
    FileSender.Release;
    FileSender := nil;
  end;

  while (true) do begin
    Req := ReqQueue.dequeue;
    if (Req = nil) then break;
    Dispose (Req);
  end;
  ReqQueue.free;

  inherited;

end;


procedure   TConnectionDidaditSend.AbortTransfer;
const
  MethodName = 'AbortTransfer';
begin
  DebOut (self, MethodName, 'begin...');
  UseEvent[e_receivedata] := false;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


procedure   TConnectionDidaditSend.Finish;
const
  MethodName = 'Finish';
begin
  DebOut (self, MethodName, 'begin...');
  UseEvent[e_receivedata] := false;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

