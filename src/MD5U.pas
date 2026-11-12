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
//  MD5 checksum (for DIDADIT and the MD5 password response). Independent implementation of the
//  algorithm described in RFC 1321; it contains no code from the reference
//  implementation given there.
//


unit MD5U;


interface


{$Q-,R-}


type
  TMD5Digest = array [0..15] of Char;

  TMD5Context = record
    State: array [0..3] of Cardinal;    // Intermediate result A, B, C, D
    ByteCount: Int64;                   // Number of bytes passed in so far
    Block: array [0..63] of Byte;       // partially filled 64-byte block
    BlockLen: Integer;                  // bytes used in it
  end;

const
  NullMD5Digest: TMD5Digest = (#0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0);


procedure MD5Init (var MD5Context: TMD5Context);
procedure MD5Update (var MD5Context: TMD5Context; const Data; Len: Cardinal);
procedure MD5UpdateBuffer (var MD5Context: TMD5Context; Buffer: Pointer; BufSize: Cardinal);
procedure MD5Final (var Digest: TMD5Digest; var MD5Context: TMD5Context);

function GetMD5 (Buffer: Pointer; BufSize: Cardinal): string;
function GetMD5OfString (Buffer: string): string;

function MD5ToString (MD5: TMD5Digest): String;
function StringToMD5 (MD5: String): TMD5Digest;


implementation


uses
  SysUtils;


type
  TMD5Words = array [0..15] of Cardinal;
  PByteArray = ^TByteArray;
  TByteArray = array [0..$3FFFFFFF] of Byte;


const
  // Additive constants of the 64 steps: integer part of 2^32 * |sin (i)|, i = 1..64
  StepConst: array [0..63] of Cardinal = (
    $D76AA478, $E8C7B756, $242070DB, $C1BDCEEE, $F57C0FAF, $4787C62A, $A8304613, $FD469501,
    $698098D8, $8B44F7AF, $FFFF5BB1, $895CD7BE, $6B901122, $FD987193, $A679438E, $49B40821,
    $F61E2562, $C040B340, $265E5A51, $E9B6C7AA, $D62F105D, $02441453, $D8A1E681, $E7D3FBC8,
    $21E1CDE6, $C33707D6, $F4D50D87, $455A14ED, $A9E3E905, $FCEFA3F8, $676F02D9, $8D2A4C8A,
    $FFFA3942, $8771F681, $6D9D6122, $FDE5380C, $A4BEEA44, $4BDECFA9, $F6BB4B60, $BEBFBC70,
    $289B7EC6, $EAA127FA, $D4EF3085, $04881D05, $D9D4D039, $E6DB99E5, $1FA27CF8, $C4AC5665,
    $F4292244, $432AFF97, $AB9423A7, $FC93A039, $655B59C3, $8F0CCC92, $FFEFF47D, $85845DD1,
    $6FA87E4F, $FE2CE6E0, $A3014314, $4E0811A1, $F7537E82, $BD3AF235, $2AD7D2BB, $EB86D391);

  // Left rotation per round (four values that repeat in each round)
  RotateBy: array [0..3, 0..3] of Byte = (
    (7, 12, 17, 22),
    (5,  9, 14, 20),
    (4, 11, 16, 23),
    (6, 10, 15, 21));


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function    RotateLeft (Value: Cardinal; Bits: Byte): Cardinal;
begin
  Result := (Value shl Bits) or (Value shr (32 - Bits));
end;


procedure   ProcessBlock (var State: array of Cardinal; const Block);
// Processes a 64-byte block. The words are little-endian, as in memory on x86.
var
  M: TMD5Words;
  A, B, C, D, F, Rotated: Cardinal;
  Step, Round, Index: Integer;
begin
  Move (Block, M, SizeOf (M));
  A := State[0];
  B := State[1];
  C := State[2];
  D := State[3];
  for Step := 0 to 63 do begin
    Round := Step div 16;
    case Round of
      0: begin
        F := (B and C) or ((not B) and D);
        Index := Step;
      end;
      1: begin
        F := (D and B) or ((not D) and C);
        Index := (5 * Step + 1) mod 16;
      end;
      2: begin
        F := B xor C xor D;
        Index := (3 * Step + 5) mod 16;
      end;
      else begin
        F := C xor (B or (not D));
        Index := (7 * Step) mod 16;
      end;
    end;
    Rotated := RotateLeft (A + F + StepConst[Step] + M[Index], RotateBy[Round, Step mod 4]);
    A := D;
    D := C;
    C := B;
    B := B + Rotated;
  end;
  Inc (State[0], A);
  Inc (State[1], B);
  Inc (State[2], C);
  Inc (State[3], D);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure MD5Init (var MD5Context: TMD5Context);
begin
  FillChar (MD5Context, SizeOf (MD5Context), 0);
  MD5Context.State[0] := $67452301;
  MD5Context.State[1] := $EFCDAB89;
  MD5Context.State[2] := $98BADCFE;
  MD5Context.State[3] := $10325476;
end;


procedure MD5Update (var MD5Context: TMD5Context; const Data; Len: Cardinal);
var
  Source: PByteArray;
  Pos, Take: Cardinal;
begin
  if (Len = 0) then exit;
  Source := @Data;
  Pos := 0;
  with MD5Context do begin
    Inc (ByteCount, Len);
    // first fill up the partially filled block
    if (BlockLen > 0) then begin
      Take := 64 - BlockLen;
      if (Take > Len) then Take := Len;
      Move (Source^[0], Block[BlockLen], Take);
      Inc (BlockLen, Take);
      Pos := Take;
      if (BlockLen < 64) then exit;
      ProcessBlock (State, Block);
      BlockLen := 0;
    end;
    // whole blocks directly from the data
    while (Len - Pos >= 64) do begin
      ProcessBlock (State, Source^[Pos]);
      Inc (Pos, 64);
    end;
    // keep the rest for later
    if (Pos < Len) then begin
      Move (Source^[Pos], Block[0], Len - Pos);
      BlockLen := Len - Pos;
    end;
  end;
end;


procedure MD5UpdateBuffer (var MD5Context: TMD5Context; Buffer: Pointer; BufSize: Cardinal);
begin
  if (BufSize > 0) then MD5Update (MD5Context, Buffer^, BufSize);
end;


procedure MD5Final (var Digest: TMD5Digest; var MD5Context: TMD5Context);
var
  Padding: array [0..71] of Byte;
  PadLen: Integer;
  BitCount: Int64;
begin
  // Padding: a 1 bit, zeros up to 56 bytes in the last block, then the length in bits (64 bits,
  // little-endian)
  BitCount := MD5Context.ByteCount * 8;
  FillChar (Padding, SizeOf (Padding), 0);
  Padding[0] := $80;
  PadLen := 56 - MD5Context.BlockLen;
  if (PadLen <= 0) then Inc (PadLen, 64);
  Move (BitCount, Padding[PadLen], 8);
  MD5Update (MD5Context, Padding, PadLen + 8);
  Assert (MD5Context.BlockLen = 0);
  Move (MD5Context.State, Digest, 16);
  FillChar (MD5Context, SizeOf (MD5Context), 0);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function GetMD5 (Buffer: Pointer; BufSize: Cardinal): string;
var
  MD5Digest: TMD5Digest;
  MD5Context: TMD5Context;
begin
  MD5Init (MD5Context);
  MD5UpdateBuffer (MD5Context, Buffer, BufSize);
  MD5Final (MD5Digest, MD5Context);
  Result := MD5ToString (MD5Digest);
end;


function    GetMD5OfString (Buffer: string): string;
begin
  Result := GetMD5 (PChar(Buffer), Length (Buffer));
end;


function    MD5ToString (MD5: TMD5Digest): String;
var
  I: Integer;
begin
  Result := '';
  for I := Low (TMD5Digest) to High (TMD5Digest) do Result := Result + IntToHex (Byte(MD5[I]), 2);
end;


function    StringToMD5 (MD5: String): TMD5Digest;
// Raises EConvertError if MD5 does not contain 32 hex digits
var
  I: Integer;
begin
  for I := Low (TMD5Digest) to High (TMD5Digest) do begin
    Result[I] := Char (StrToInt ('$' + Copy (MD5, 2 * I + 1, 2)));
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.
