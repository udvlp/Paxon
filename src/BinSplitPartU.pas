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


unit BinSplitPartU;


interface


uses
  Windows, SysUtils, Classes,
  SyncObjs, Buttons, ActiveX,
  GlobalU, InterfacesU, PublisherU, FileStreamUlfU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TBinSplitPart = class
  private

    Data: string;
    FStream: TFileStreamUlf;
    MyOwnStream: Boolean;

    FPartNumber: Integer;
    FPartCount: Integer;
    FSplitsize: Integer;
    FOriginalsize: Integer;
    FFileName: string;
    FDate: string;
    FBytesInThisPart: Integer;

    DataStartPos: Integer;

    constructor Create; virtual;

  public

    constructor CreateFromStream (aStream: TFileStreamUlf);
    constructor CreateFromFile (aFileName: String);
    destructor  Destroy; override;

    function    ReadHeader: Boolean;
    function    Parse: Boolean;

    property    Stream: TFileStreamUlf read FStream;

    property    PartNumber: Integer read FPartNumber;
    property    PartCount: Integer read FPartCount;
    property    Splitsize: Integer read FSplitsize;
    property    Originalsize: Integer read FOriginalsize;
    property    FileName: string read FFileName;
    property    Date: string read FDate;
    property    BytesInThisPart: Integer read FBytesInThisPart;

    procedure   WriteToStream (DstStream: TStream);

    function    CheckPartCRC: Boolean;
    function    CheckAccumulatedCRC (var CRC: Cardinal): Boolean;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, CrcU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TBinSplitPart.create;
begin
  inherited create;
end;


constructor TBinSplitPart.CreateFromFile (aFileName: String);
begin
  MyOwnStream := true;
  FStream := TFileStreamUlf.create;
  FStream.FileName := aFileName;
  FStream.Mode := fmOpenRead or fmShareDenyWrite;
  FStream.Open;
  Create;
end;


constructor TBinSplitPart.CreateFromStream (aStream: TFileStreamUlf);
begin
  MyOwnStream := false;
  FStream := aStream;
  Create;
end;


destructor  TBinSplitPart.Destroy;
begin
  if MyOwnStream then begin
    FStream.free;
  end;
  FStream := nil;
  inherited;
end;


function    TBinSplitPart.ReadHeader: Boolean;
const
  MethodName = 'ReadHeader';
  MaxHeaderSize = 1024; // the header is far shorter; do not search a whole foreign file for #0
var
  L, N, I: Integer;
  HasError: Boolean;
  CRC16: Word;
  S: string;

begin

  DebOut (self, MethodName, 'begin...');

  try

    Stream.Seek (0, soFromBeginning);

    HasError := true;
    L := 0;
    while true do begin
      SetLength (Data, L + 256);
      N := Stream.Read (Data[L+1], 256);
      for I := 1 to N do begin
        if Data[L+I] = #0 then begin
          SetLength (Data, L + I);
          Stream.Seek (L + I, soFromBeginning);
          DataStartPos := L + I + 5;
          HasError := false;
          break;
        end;
      end;
      if (not HasError) or (N < 256) or (L + 256 >= MaxHeaderSize) then break;
      Inc (L, 256);
    end;

    if HasError then begin

      DebOut (self, MethodName, 'Keine Null gefunden');

    end else begin

      CRC16 := 0;
      CalcCRC16OfString (Data, CRC16);
      DebOut (self, MethodName, 'Header-CRC: ' + IntToHex (CRC16, 4));
      SetLength (S, 5);
      try
        Stream.ReadBuffer (S[1], 5);
        if not ((IntToHex (CRC16, 4) = Copy (S, 1, 4)) and (S[5] = #10)) then begin
          DebOut (self, MethodName, 'Header-CRC falsch');
          HasError := true;
        end;
      except
        DebOut (self, MethodName, 'Kann Header-CRC nicht lesen');
        HasError := true;
      end;

    end;

    if HasError then DataStartPos := -1;

    result := not HasError;

  except

    result := false;

  end;

  DebOut (self, MethodName, 'end.');

end;


function    TBinSplitPart.Parse: Boolean;
const
  MethodName = 'Parse';
  MaxPartCount = $FFFF; // Upper limit against absurdly large part arrays
var
  I, N: Integer;
  S: string;
  HasError: Boolean;

begin

  DebOut (self, MethodName, 'begin...');

  S := '';
  N := 0;
  HasError := false;

  for I := 1 to Length (Data) do begin

    if Data[I] = #10 then begin

      case N of

        0: begin // >BS<
          if (S <> '>BS<') then begin
            HasError := true;
            break;
          end;
        end;

        1: begin // Partnumber
          try
            FPartNumber := StrToInt ('$' + S);
          except
            HasError := true;
            break;
          end;
        end;

        2: begin // Partcount
          try
            FPartCount := StrToInt ('$' + S);
          except
            HasError := true;
            break;
          end;
        end;

        3: begin // Splitsize
          try
            FSplitsize := StrToInt (S);
          except
            HasError := true;
            break;
          end;
        end;

        4: begin // Originalsize
          try
            FOriginalsize := StrToInt (S);
          except
            HasError := true;
            break;
          end;
        end;

        5: begin // Filename
          FFileName := S;
        end;

        6: begin // Date
          FDate := S;
        end;

        7: begin // additional Fields
          break;
        end;

      end;

      S := '';
      Inc (N);

    end else begin

      S := S + Data[I];

    end;

  end;

  if (HasError) then begin

    DebOut (self, MethodName, 'FEHLER beim Parsen des Headers.');

  end else if (FPartCount < 1) or (FPartCount > MaxPartCount)
    or (FPartNumber < 1) or (FPartNumber > FPartCount)
    or (FSplitsize < 1) or (FOriginalsize < 1)
    or (FPartCount <> (FOriginalsize - 1) div FSplitsize + 1) then begin

    // The values come from the remote station: part number, part count and sizes must match,
    // otherwise data is written outside the part array or divided by 0.
    DebOut (self, MethodName, 'FEHLER: Ungültige Werte im Header.');
    HasError := true;

  end else begin

    if (FPartNumber < FPartCount) then begin
      FBytesInThisPart := FSplitSize;
    end else begin
      FBytesInThisPart := (FOriginalSize - 1) mod FSplitSize + 1;
    end;


    if (Stream.Size < (Int64 (Length (Data)) + 5 + FBytesInThisPart + 18)) then begin
      DebOut (self, MethodName, 'FEHLER: Datei zu kurz');
      HasError := true;
    end;

  end;

  result := not HasError;

  DebOut (self, MethodName, 'end.');

end;


procedure   TBinSplitPart.WriteToStream (DstStream: TStream);
begin
  FStream.Seek (DataStartPos, soFromBeginning);
  DstStream.CopyFrom (FStream, FBytesInThisPart);
end;


function    TBinSplitPart.CheckPartCRC: Boolean;
const
  MethodName = 'CheckPartCRC';
  BufferSize = 1024;
var
  CRC: Cardinal;
  Buffer: array of Byte;
  I, N, Q: Integer;
  C, D: Cardinal;
  S: string;
begin
  result := false;
  FStream.Seek (DataStartPos, soFromBeginning);
  SetLength (Buffer, BufferSize);
  CRC := $FFFFFFFF;
  I := BytesInThisPart + 9;
  while (I > 0) do begin
    if I > BufferSize then N := BufferSize else N := I;
    Dec (I, N);
    try
      FStream.ReadBuffer (Buffer[0], N);
    except
      DebOut (self, MethodName, 'Kann Daten nicht aus Stream lesen.');
      Exit;
    end;
    for Q := 0 to N - 1 do begin
      CRC := CalcCRC32 (Buffer[Q], CRC);
    end;
  end;
  C := not CRC;
  SetLength (S, 9);
  try
    FStream.ReadBuffer (S[1], 9);
  except
    DebOut (self, MethodName, 'Kann CRC nicht aus Stream lesen');
    Exit;
  end;
  if (S[9] <> #10) then begin
    DebOut (self, MethodName, 'CRC ist nicht mit LF abgeschlossen.');
    Exit;
  end;
  Delete (S, 9, 1);
  try
    D := Cardinal (StrToInt ('$' + S));
  except
    DebOut (self, MethodName, Format ('CRC in der Datei ungültig (%s)', [S]));
    Exit;
  end;
  if (C = D) then begin
    DebOut (self, MethodName, Format ('CRC ok (%8.8x)', [C]));
    result := true;
  end else begin
    DebOut (self, MethodName, Format ('CRC falsch (%8.8x, %8.8x)', [C, D]));
  end;
end;


function    TBinSplitPart.CheckAccumulatedCRC (var CRC: Cardinal): Boolean;
const
  MethodName = 'CheckAccumulatedCRC';
  BufferSize = 1024;
var
  Buffer: array of Byte;
  I, N, Q: Integer;
  C, D: Cardinal;
  S: string;
begin
  result := false;
  FStream.Seek (DataStartPos, soFromBeginning);
  SetLength (Buffer, BufferSize);
  I := BytesInThisPart;
  while (I > 0) do begin
    if I > BufferSize then N := BufferSize else N := I;
    Dec (I, N);
    try
      FStream.ReadBuffer (Buffer[0], N);
    except
      DebOut (self, MethodName, 'Kann Daten nicht aus Stream lesen.');
      Exit;
    end;
    for Q := 0 to N - 1 do begin
      CRC := CalcCRC32 (Buffer[Q], CRC);
    end;
  end;
  C := not CRC;
  SetLength (S, 9);
  try
    FStream.ReadBuffer (S[1], 9);
  except
    DebOut (self, MethodName, 'Kann CRC nicht aus Stream lesen');
    Exit;
  end;
  if (S[9] <> #10) then begin
    DebOut (self, MethodName, 'CRC ist nicht mit LF abgeschlossen.');
    Exit;
  end;
  Delete (S, 9, 1);
  try
    D := Cardinal (StrToInt ('$' + S));
  except
    DebOut (self, MethodName, Format ('CRC in der Datei ungültig (%s)', [S]));
    Exit;
  end;
  if C = D then begin
    DebOut (self, MethodName, Format ('CRC ok (%8.8x)', [C]));
    result := true;
  end else begin
    DebOut (self, MethodName, Format ('CRC falsch (%8.8x, %8.8x)', [C, D]));
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

