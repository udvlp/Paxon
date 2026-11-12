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


unit ConnectionDidaditU;


interface


uses
  Classes, Windows, SysUtils, Messages, GlobalU, MD5U,
  InterfacesU, SendFileU, ConnectionAbstractU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionDidadit = class (TConnectionAbstract)
  private

  protected

    MD5: TMD5Digest;
    Chat: Boolean;

    procedure   SendData; override;

  public

    procedure   Init; override;
    procedure   Terminated (Why: TWhyTerminated); override;
    function    EncodeBlock (BlockID: Word; DataText: String): String; virtual;
    function    DecodeBlock (Block: String; var BlockID: Word; var DataText: String; var MD5: TMD5Digest): Boolean; virtual;
    function    ErrorString (ErrNo: Integer; Values: array of const): String; overload; virtual;
    function    ErrorString (ErrNo: Integer): String; overload; virtual;
    procedure   SendError (ErrNo: Integer); overload; virtual;
    procedure   SendError (ErrNo: Integer; Values: array of const); overload; virtual;
    procedure   SendBlock (BlockID: Word; DataText: String); virtual;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const

  FEND  = #$C0; // FrameEND
  FESC  = #$DB; // FrameESCape
  TFEND = #$DC; // Transposed FrameEND
  TFESC = #$DD; // Transposed FrameESCape

  DIDADIT_BLOCK_INFO     =  1;
  DIDADIT_BLOCK_START    =  2;
  DIDADIT_BLOCK_ERR      =  3;
  DIDADIT_BLOCK_DATA     =  4;
  DIDADIT_BLOCK_FIN      =  5;
  DIDADIT_BLOCK_REQ      =  6;
  DIDADIT_BLOCK_FINACK   =  7;
  DIDADIT_BLOCK_ECHOREQ  =  9;
  DIDADIT_BLOCK_ECHOREP  = 10;
  DIDADIT_BLOCK_ABORT    = 11;
  DIDADIT_BLOCK_CHAT     = 12;

  DIDADIT_VERSION = '0.9.1';

  FEATURE_CHAT = 'CHAT';

  DEFAULT_BLOCKSIZE = 1750;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, CRCU, SoundsU, SoundsConstsU;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionDidadit.Init;
const
  MethodName = 'Init';
begin
  DebOut (self, MethodName, 'begin...');
  inherited;
  DebOut (self, MethodName, 'end.');
end;


procedure   TConnectionDidadit.Terminated (Why: TWhyTerminated);
const
  MethodName = 'Terminated';
begin
  DebOut (self, MethodName, 'begin...');
  case Why of
    e_finish: Sounds.PlayEvent (se_transfer_success, PacketConnection);
    e_cancel: Sounds.PlayEvent (se_transfer_cancel, PacketConnection);
    e_abort: Sounds.PlayEvent (se_transfer_error, PacketConnection);
  end;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


function    TConnectionDidadit.EncodeBlock (BlockID: Word; DataText: String): String;
const
  MethodName = 'EncodeBlock';

var
  Block: String;
  CRC: Word;
  N: Integer;

begin

  assert (Sizeof (BlockID) = 2);

  SetLength (Block, Sizeof (BlockID));
  Move (BlockID, Block[1], Sizeof (BlockID));

  if (BlockID in [DIDADIT_BLOCK_ERR,
                  DIDADIT_BLOCK_DATA,
                  DIDADIT_BLOCK_FIN,
                  DIDADIT_BLOCK_REQ,
                  DIDADIT_BLOCK_FINACK]) then begin

    N := Length (Block);
    SetLength (Block, N + sizeof (MD5));
    Move (MD5, Block[N + 1], sizeof (MD5));

  end;

  Block := Block + DataText;

  CRC := 0;
  CalcCRC16OfString (Block, CRC);

  N := Length (Block);
  SetLength (Block, N + Sizeof (CRC));
  Move (CRC, Block[N + 1], Sizeof (CRC));

  result := FEND;
  for N := 1 to Length (Block) do begin
    if (Block[N] = FEND) then begin
      result := result + FESC + TFEND;
    end else if (Block[N] = FESC) then begin
      result := result + FESC + TFESC;
    end else begin
      result := result + Block[N];
    end;
  end;
  result := result + FEND;

end;


function    TConnectionDidadit.DecodeBlock (Block: String; var BlockID: Word; var DataText: String; var MD5: TMD5Digest): Boolean;
const
  MethodName = 'DecodeBlock';

var
  N, I, L: Integer;
  S: String;
  C: Char;
  HasError: Boolean;
  CRC, MyCRC: Word;

begin

  L := Length (Block);

  if (L < 4) then begin

    HasError := true;

  end else begin

    SetLength (S, L);

    I := 0;
    N := 1;
    HasError := false;

    while (N <= L) do begin
      C := Block[N];
      if (C = FESC) then begin
        inc (N);
        if (N > L) then begin
          HasError := true;
          break;
        end;
        case Block[N] of
          TFEND: begin
            inc (I);
            S[I] := FEND;
          end;
          TFESC: begin
            inc (I);
            S[I] := FESC;
          end;
          else begin
            HasError := true;
            break;
          end;
        end;
      end else begin
        inc (I);
        S[I] := C;
      end;
      inc (N);
    end;

    // At least block ID and CRC (data comes from the remote station).
    if (I < Sizeof (BlockID) + Sizeof (CRC)) then begin
      HasError := true;
    end;

    if (not HasError) then begin

      Move (S[I-1], CRC, Sizeof (CRC));

      SetLength (S, I - 2);

      MyCRC := 0;
      CalcCRC16OfString (S, MyCRC);

      if (CRC <> MyCRC) then begin
        HasError := true;
      end;

    end;

    if (not HasError) then begin

      Move (S[1], BlockID, sizeof (BlockID));

      if (BlockID in [DIDADIT_BLOCK_ERR,
                      DIDADIT_BLOCK_DATA,
                      DIDADIT_BLOCK_FIN,
                      DIDADIT_BLOCK_REQ,
                      DIDADIT_BLOCK_FINACK]) then begin

        if (Length (S) < Sizeof (BlockID) + sizeof (MD5)) then begin
          HasError := true;
        end else begin
          Move (S[3], MD5, sizeof (MD5));
          DataText := copy (S, 3 + sizeof (MD5), MaxInt);
        end;

      end else begin

        FillChar (MD5, sizeof (MD5), 0);
        DataText := copy (S, 3, MaxInt);

      end;

    end;

  end;

  result := not HasError;

end;


procedure   TConnectionDidadit.SendBlock (BlockID: Word; DataText: String);
const
  MethodName = 'SendBlock';

var
  T: String;
  I, L: Integer;

begin

  T := EncodeBlock (BlockID, DataText);
  L := Length (T);
  I := 1;

  while (I <= L) do begin
    PacketConnection.DeviceQueue.enqueue (copy (T, I, PackLen));
    inc (I, PackLen);
  end;

end;


procedure   TConnectionDidadit.SendError (ErrNo: Integer);
const
  MethodName = 'SendError';
begin
  DebOut (self, MethodName, 'begin...');
  SendError (ErrNo, []);
  DebOut (self, MethodName, 'end.');
end;


procedure   TConnectionDidadit.SendError (ErrNo: Integer; Values: array of const);
const
  MethodName = 'SendError';
var
  S: String;
begin
  DebOut (self, MethodName, 'begin...');
  S := ErrorString (ErrNo, Values);
  SendBlock (DIDADIT_BLOCK_ERR, S);
  if ((ErrNo mod 100) < 50) then begin
    DebOut (self, MethodName, 'FATALER FEHLER: %s', [S]);
    AbortTransfer;
  end else begin
    DebOut (self, MethodName, 'FEHLER: %s', [S]);
  end;
  DebOut (self, MethodName, 'end.');
end;


function    TConnectionDidadit.ErrorString (ErrNo: Integer): String;
const
  MethodName = 'ErrorString';
begin
  DebOut (self, MethodName, 'begin...');
  result := ErrorString (ErrNo, []);
  DebOut (self, MethodName, 'end.');
end;


function    TConnectionDidadit.ErrorString (ErrNo: Integer; Values: array of const): String;
const
  MethodName = 'ErrorString';
var
  S: String;

begin

  DebOut (self, MethodName, 'begin...');

  case ErrNo of

    100: S := 'Unexpected block type (%s)';
    101: S := 'REQ block with data out of range (offset %d, length %d)';
    102: S := 'MD5 validation error';
    103: S := 'PARTMD5 format error';
    104: S := 'Invalid offset/blocksize';

    150: S := 'Block type not implemented (%d)';

    200: S := 'Illegal line in INFO block';
    201: S := 'Illegal line in START block';
    202: S := 'INFO block without MD5 info';
    203: S := 'Empty file or missing size info in INFO block';
    204: S := 'INFO block without BLOCKSIZE info';
    205: S := 'INFO block without FILENAME info';
    206: S := 'Block corrupt';
    208: S := 'Compression type not supported';

    300: S := 'Could not create file';

    else S := 'Unknown Error';

  end;

  try
    result := Format ('%3.3d %s', [ErrNo, Format (S, Values)]);
  except
    result := Format ('%3.3d', [ErrNo]);
  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TConnectionDidadit.SendData;
const
  MethodName = 'SendData';
var
  S: string;
begin
  DebOut (self, MethodName, 'begin...');
  if (Chat) then begin
    DebOut (self, MethodName, 'Sende CHAT.');
    S := PacketConnection.SendQueue.dequeue;
    SendBlock (DIDADIT_BLOCK_CHAT, S);
  end else begin
    UseEvent[e_senddata] := false;
  end;
  DebOut (self, MethodName, 'end.');
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

