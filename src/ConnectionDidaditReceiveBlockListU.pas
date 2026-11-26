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


unit ConnectionDidaditReceiveBlockListU;


interface


uses
  Classes, SysUtils, DebOutU, GlobalU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  PRequest = ^TRequest;
  TRequest = packed record
    Offset: Integer;
    Length: Integer;
  end;


  PListElem = ^TListElem;
  TListElem = record
    FromPos: Integer;
    ToPos: Integer;
    Next: PListElem;
  end;


  TDidaditReceiveBlockList = class
  private
    FBegin: PListElem;
    FSize: Integer;
    FCall: String;
    procedure   Clear; virtual;
  public
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   OutputList; virtual;
    function    Add (Offset: Integer; Length: Integer): Integer; virtual;
    property    Size: Integer read FSize write FSize;
    property    Call: String read FCall write FCall;
    function    GetRequests (var Requests: array of TRequest): Integer; virtual;
    procedure   WriteIndexFile (const BaseName: String); virtual;
    function    ReadIndexFile (const BaseName: String): Integer; virtual;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  IniFiles;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDidaditReceiveBlockList.AfterConstruction;
begin
  inherited;
  FBegin  := nil;
end;


procedure   TDidaditReceiveBlockList.BeforeDestruction;
begin
  Clear;
  inherited;
end;


function    TDidaditReceiveBlockList.Add (Offset: Integer; Length: Integer): Integer;

  procedure CleanUpNext (First: PListElem);
  var
    E: PListElem;
  begin
    if (assigned (First)) then begin
      E := First.Next;
      while (assigned (E)) do begin
        if (First.ToPos + 1 >= E.FromPos) then begin
          if (First.ToPos < E.ToPos) then begin
            First.ToPos := E.ToPos;
          end;
          First.Next := E.Next;
          Dispose (E);
          E := First.Next;
        end else begin
          E := E.Next;
        end;
      end;
    end;
  end;

const
  MethodName = 'Add';

var
  E, F, L: PListElem;
  ToPos: Integer;

begin
  ToPos := Offset + Length - 1;
  if (Offset < 0) or (Length <= 0) or (Offset > MaxInt - Length) then begin
    // Values come from the remote station: do not accept an invalid range.
    DebOut (self, MethodName, 'Ungültiger Abschnitt: Offset %d, Länge %d', [Offset, Length]);
  end else if (not assigned (FBegin)) then begin
    New (FBegin);
    FBegin.FromPos := Offset;
    FBegin.ToPos := ToPos;
    FBegin.Next := nil;
  end else begin
    L := nil;
    E := FBegin;
    while (assigned (E)) do begin
      if (Offset >= E.FromPos) and (Offset <= E.ToPos + 1) then begin
        if (ToPos > E.ToPos) then begin
          E.ToPos := ToPos;
          CleanUpNext (E);
        end;
        break;
      end else if (Offset < E.FromPos) then begin
        if (ToPos + 1 < E.FromPos) then begin
          New (F);
          F.FromPos := Offset;
          F.ToPos := ToPos;
          if (assigned (L)) then begin
            L.Next := F;
            F.Next := E;
          end else begin
            F.Next := FBegin;
            FBegin := F;
          end;
          break;
        end else if (ToPos + 1 = E.FromPos) then begin
          E.FromPos := Offset;
          break;
        end else begin
          // Overlaps the start of E: extend E at the front and merge it with the
          // following ranges. No new node; the predecessor
          // still points to E.
          E.FromPos := Offset;
          if (ToPos > E.ToPos) then begin
            E.ToPos := ToPos;
            CleanUpNext (E);
          end;
          break;
        end;
      end;
      L := E;
      E := E.Next;
    end;
    if (not assigned (E)) and (assigned (L)) and (L.ToPos < Offset) then begin
      New (F);
      F.FromPos := Offset;
      F.ToPos := ToPos;
      F.Next := nil;
      L.Next := F;
    end;
  end;
  E := FBegin;
  result := 0;
  while (assigned (E)) do begin
    inc (Result, E.ToPos - E.FromPos + 1);
    E := E.Next;
  end;
end;


procedure   TDidaditReceiveBlockList.OutputList;
const
  MethodName = 'OutputList';
var
  E: PListElem;
begin
  DebOut (self, MethodName, 'begin...');
  E := FBegin;
  while (assigned (E)) do begin
    DebOut (self, MethodName, 'von %d bis %d (%d)', [E.FromPos, E.ToPos, E.ToPos - E.FromPos + 1]);
    E := E.Next;
  end;
  DebOut (self, MethodName, 'end.');
end;


function    TDidaditReceiveBlockList.GetRequests (var Requests: array of TRequest): Integer;
const
  MethodName = 'GetRequests';
var
  E: PListElem;
  FromPos: Integer;
  ToPos: Integer;
  Len: Integer;
begin
  DebOut (self, MethodName, 'begin...');
  try
    E := FBegin;
    FromPos := 0;
    result := 0;
    while (assigned (E)) do begin
      ToPos := E.FromPos - 1;
      Len := ToPos - FromPos + 1;
      if (Len > 0) then begin
        DebOut (self, MethodName, 'Lücke bei %d, Länge %d', [FromPos, Len]);
        Requests[result].Offset := FromPos;
        Requests[result].Length := Len;
        Inc (result);
        if (result >= Length (Requests)) then break;
      end;
      FromPos := E.ToPos + 1;
      E := E.Next;
    end;
    if (not (result >= Length (Requests))) then begin
      ToPos := Size - 1;
      Len := ToPos - FromPos + 1;
      if (Len > 0) then begin
        DebOut (self, MethodName, 'Lücke bei %d, Länge %d', [FromPos, Len]);
        Requests[result].Offset := FromPos;
        Requests[result].Length := Len;
        Inc (result);
      end;
    end;
  finally
    DebOut (self, MethodName, 'end.');
  end;
end;


procedure   TDidaditReceiveBlockList.Clear;
var
  E, F: PListElem;
begin
  E := FBegin;
  while (assigned (E)) do begin
    F := E.Next;
    Dispose (E);
    E := F;
  end;
  FBegin := nil;
end;


procedure   TDidaditReceiveBlockList.WriteIndexFile (const BaseName: String);
const
  MethodName = 'WriteIndexFile';
  Section = 'Blocks';
  FileSection = 'File';

var
  IniFile: TIniFile;
  E: PListElem;
  N: Integer;
  FileName: String;

begin

  DebOut (self, MethodName, 'begin...');
  FileName := ApplicationDataPath + IncompleteFiles + BaseName + '.pxi';

  if (assigned (FBegin)) and ((FBegin.FromPos <> 0) or (FBegin.ToPos <> Size - 1)) then begin

    IniFile := TIniFile.create (FileName);
    try
      // Remove keys of an older transfer before writing the current state.
      IniFile.EraseSection (FileSection);
      IniFile.EraseSection (Section);
      // Callsign and size identify the transfer the partial file belongs to.
      IniFile.WriteString (FileSection, 'CALL', FCall);
      IniFile.WriteString (FileSection, 'SIZE', IntToStr (Size));
      N := 0;
      E := FBegin;
      while (assigned (E)) do begin
        IniFile.WriteString (Section, Format ('%4.4d', [N]), Format ('%d,%d', [E.FromPos, E.ToPos]));
        E := E.Next;
        Inc (N);
      end;
    finally
      IniFile.free;
    end;

  end else begin

    // DeleteFile instead of Erase: an error must not raise in Terminated.
    if (FileExists (FileName)) and (not DeleteFile (FileName)) then begin
      DebOut (self, MethodName, 'Löschen fehlgeschlagen: ' + FileName);
    end;

  end;

  DebOut (self, MethodName, 'end.');

end;


function    TDidaditReceiveBlockList.ReadIndexFile (const BaseName: String): Integer;
const
  MethodName = 'ReadIndexFile';
  Section = 'Blocks';
  FileSection = 'File';

// Result: resume offset, or -1 if there is no index file or it does not belong
// to this transfer (other callsign, other size, older index file without these keys).

var
  IniFile: TIniFile;
  I, N: Integer;
  FileName: String;
  S: String;
  FromPos, ToPos: Integer;

begin

  DebOut (self, MethodName, 'begin...');

  Clear;

  FileName := ApplicationDataPath + IncompleteFiles + BaseName + '.pxi';

  result := -1;

  if (FileExists (FileName)) then begin

    IniFile := TIniFile.create (FileName);
    try

      S := IniFile.ReadString (FileSection, 'CALL', '');
      if (S = '') or (S <> FCall) then begin
        DebOut (self, MethodName, 'Indexdatei ohne passendes Rufzeichen (%s).', [S]);
        exit;
      end;

      if (StrToIntDef (IniFile.ReadString (FileSection, 'SIZE', ''), -1) <> Size) then begin
        DebOut (self, MethodName, 'Indexdatei ohne passende Größe.');
        exit;
      end;

      result := 0;

      N := 0;
      while (true) do begin

        S := IniFile.ReadString (Section, Format ('%4.4d', [N]), '');
        if (S = '') then break;

        I := Pos (',', S);
        if (I <= 1) then break;

        FromPos := StrToIntDef (copy (S, 1, I - 1), -1);
        ToPos := StrToIntDef (copy (S, I + 1, MaxInt), -1);

        if (FromPos >= 0) and (ToPos >= FromPos) and (ToPos < Size) then begin
          Add (FromPos, ToPos - FromPos + 1);
          if (ToPos + 1 > Result) then Result := ToPos + 1;
        end;

        inc (N);

      end;

    finally
      IniFile.free;
    end;

  end;

  DebOut (self, MethodName, 'end.');

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

