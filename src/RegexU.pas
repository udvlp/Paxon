//
//  PAXON Packet Radio Terminal
//
//  Copyright 2026 Ulf Haueisen <ulf@paxon.app>, Frankfurt, Germany
//
//  This file is part of PAXON.
//
//  SPDX-License-Identifier: MIT
//  PAXON is licensed under the MIT License; see LICENSE.md in the project root.
//


//  Small engine for regular expressions (backtracking, Perl semantics:
//  the leftmost match wins, alternatives are tried from left to
//  right, quantifiers are greedy by default).
//
//  Supports:
//    Literals, .  ^  $  |  ( )  (?: )
//    Character classes [abc] [a-z] [^...] with escapes inside
//    Quantifiers * + ? {n} {n,} {n,m}, each lazy with a trailing ?
//    Escapes \d \D \w \W \s \S \t \n \r \f \a \e \xHH, otherwise the character itself
//
//  Behavior as used before: matching is case-sensitive
//  (unless ModifierI = true), . matches any character including
//  line breaks, ^ and $ refer to the start and end of the input.
//
//  Running time: each pair (instruction, input position) is entered at most
//  once per search (like BitState in RE2). A state that was once left without
//  a match cannot lead to a match on any path of lower priority
//  after all. This keeps the effort proportional to
//  pattern length times input length, and empty loop iterations end
//  by themselves.
//
//  Deviation from Perl (as in RE2): if the body of a repetition can be empty,
//  e.g. (a*)* or (.?)+, Perl allows a final empty
//  iteration; here it is discarded. This only affects the contents of the
//  groups in such constructs.
//
//  As with the previously used TRegExpr, the input ends at the first #0.
//  If pattern length times input length exceeds 2^28, Exec
//  raises ERegexError.


unit RegexU;

interface

uses
  SysUtils, Classes;

type

  ERegexError = class (Exception);

  TRegexCharSet = set of Char;

  TRegexOp = (roChar, roAny, roSet, roBol, roEol, roSplit, roJmp, roSave, roMatch);

  TRegexInstr = record
    Op:     TRegexOp;
    C:      Char;
    SetIdx: Integer;
    X, Y:   Integer;
    N:      Integer;
  end;

  TRegexNodeKind = (rnChar, rnAny, rnSet, rnBol, rnEol, rnConcat, rnAlternation, rnGroup, rnRepeat);

  TRegexNode = class
  public
    Kind:     TRegexNodeKind;
    C:        Char;
    CharSet:  TRegexCharSet;
    Children: array of TRegexNode;
    Group:    Integer;            // Group number, -1 = non-capturing
    Min, Max: Integer;            // Max = -1: unlimited
    Greedy:   Boolean;
    procedure Add (aNode: TRegexNode);
  end;

  TRegexBacktrack = record
    Kind: Byte;                   // 0 = branch, 1 = group boundary
    A, B: Integer;
  end;

  TRegex = class
  private
    FExpression: String;
    FModifierI:  Boolean;
    FCompiled:   Boolean;
    FProg:       array of TRegexInstr;
    FSets:       array of TRegexCharSet;
    FGroupCount: Integer;
    FVisited:    array of Cardinal;
    FStack:      array of TRegexBacktrack;
    FInput:      String;
    FSlots:      array of Integer;
    FMatched:    Boolean;
    FPos:        Integer;
    FNodes:      TList;
    procedure SetExpression (const Value: String);
    procedure SetModifierI (const Value: Boolean);
    procedure Compile;
    function  NewError (const Msg: String): ERegexError;
    procedure Error (const Msg: String);
    function  NewNode (aKind: TRegexNodeKind): TRegexNode;
    function  AtEnd: Boolean;
    function  Peek: Char;
    function  ParseAlternation: TRegexNode;
    function  ParseConcat: TRegexNode;
    function  ParseQuantifier (var Min, Max: Integer): Boolean;
    function  ParseRepeat: TRegexNode;
    function  ParseAtom: TRegexNode;
    function  ParseClass: TRegexNode;
    function  ParseEscape (var CharSet: TRegexCharSet; var IsSet: Boolean): Char;
    function  ParseInt (var Value: Integer): Boolean;
    function  CaseFold (const S: TRegexCharSet): TRegexCharSet;
    function  Emit (Op: TRegexOp): Integer;
    procedure SetSplit (Idx, Preferred, Other: Integer; Greedy: Boolean);
    procedure EmitNode (Node: TRegexNode);
    function  AddSet (const S: TRegexCharSet): Integer;
    function  Run (Start: Integer): Boolean;
    function  GetMatch (Idx: Integer): String;
    function  GetMatchPos (Idx: Integer): Integer;
    function  GetMatchLen (Idx: Integer): Integer;
  public
    function  Exec (const aInput: String): Boolean;
    property  Expression: String read FExpression write SetExpression;
    property  ModifierI: Boolean read FModifierI write SetModifierI;
    property  GroupCount: Integer read FGroupCount;
    property  Match [Idx: Integer]: String read GetMatch;
    property  MatchPos [Idx: Integer]: Integer read GetMatchPos;
    property  MatchLen [Idx: Integer]: Integer read GetMatchLen;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

const
  Digits    = ['0'..'9'];
  WordChars = ['0'..'9', 'A'..'Z', 'a'..'z', '_'];
  Spaces    = [' ', #9, #10, #11, #12, #13];
  AllChars  = [#0..#255];

  // Upper limit for pattern length times input length (32 MB of visited marks);
  // also keeps the bit indices safely within Integer range
  MaxVisitedBits = 1 shl 28;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure TRegexNode.Add (aNode: TRegexNode);
begin
  SetLength (Children, Length (Children) + 1);
  Children[High (Children)] := aNode;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure TRegex.SetExpression (const Value: String);
begin
  FExpression := Value;
  FCompiled := false;
  FMatched := false;
end;


procedure TRegex.SetModifierI (const Value: Boolean);
begin
  FModifierI := Value;
  FCompiled := false;
  FMatched := false;
end;


function TRegex.NewError (const Msg: String): ERegexError;
begin
  Result := ERegexError.CreateFmt ('Regulaerer Ausdruck "%s", Position %d: %s', [FExpression, FPos, Msg]);
end;


procedure TRegex.Error (const Msg: String);
begin
  raise NewError (Msg);
end;


function TRegex.NewNode (aKind: TRegexNodeKind): TRegexNode;
begin
  Result := TRegexNode.Create;
  FNodes.Add (Result);
  Result.Kind := aKind;
  Result.Group := -1;
end;


function TRegex.AtEnd: Boolean;
begin
  Result := (FPos > Length (FExpression));
end;


function TRegex.Peek: Char;
begin
  if (AtEnd) then Result := #0 else Result := FExpression[FPos];
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Parser


function TRegex.ParseAlternation: TRegexNode;
var
  Left: TRegexNode;
begin
  Left := ParseConcat;
  if (not AtEnd) and (Peek = '|') then begin
    Result := NewNode (rnAlternation);
    Result.Add (Left);
    while (not AtEnd) and (Peek = '|') do begin
      Inc (FPos);
      Result.Add (ParseConcat);
    end;
  end else begin
    Result := Left;
  end;
end;


function TRegex.ParseConcat: TRegexNode;
begin
  Result := NewNode (rnConcat);
  while (not AtEnd) and (Peek <> '|') and (Peek <> ')') do begin
    Result.Add (ParseRepeat);
  end;
end;


function TRegex.ParseInt (var Value: Integer): Boolean;
begin
  Result := false;
  Value := 0;
  while (not AtEnd) and (Peek in Digits) do begin
    Value := Value * 10 + Ord (Peek) - Ord ('0');
    if (Value > 10000) then Error ('Wiederholungszahl zu gross');
    Inc (FPos);
    Result := true;
  end;
end;


function TRegex.ParseQuantifier (var Min, Max: Integer): Boolean;
var
  Save: Integer;
begin
  // Reads * + ? or {n} {n,} {n,m}. A '{' that does not start a valid quantifier
  // is left in place and later read as a literal.
  Result := true;
  case Peek of
    '*': begin Min := 0; Max := -1; Inc (FPos); end;
    '+': begin Min := 1; Max := -1; Inc (FPos); end;
    '?': begin Min := 0; Max := 1;  Inc (FPos); end;
    '{': begin
      Save := FPos;
      Inc (FPos);
      Result := false;
      Max := -1;
      if (ParseInt (Min)) then begin
        Max := Min;
        if (Peek = ',') then begin
          Inc (FPos);
          if (not ParseInt (Max)) then Max := -1;
        end;
        if (Peek = '}') then begin
          Inc (FPos);
          Result := true;
        end;
      end;
      if (not Result) then FPos := Save;
    end;
  else
    Result := false;
  end;
end;


function TRegex.ParseRepeat: TRegexNode;
var
  Atom:     TRegexNode;
  Min, Max: Integer;
  Save:     Integer;
  M2, X2:   Integer;
begin
  Atom := ParseAtom;
  Result := Atom;
  if (not ParseQuantifier (Min, Max)) then exit;
  if (Max <> -1) and (Max < Min) then Error ('{n,m} mit m < n');
  if (Atom.Kind in [rnBol, rnEol]) then Error ('Quantor nach ^ oder $');

  Result := NewNode (rnRepeat);
  Result.Add (Atom);
  Result.Min := Min;
  Result.Max := Max;
  Result.Greedy := true;
  if (Peek = '?') then begin
    Result.Greedy := false;
    Inc (FPos);
  end;

  Save := FPos;
  if (ParseQuantifier (M2, X2)) then begin
    FPos := Save;
    Error ('Doppelter Quantor');
  end;
end;


function TRegex.ParseEscape (var CharSet: TRegexCharSet; var IsSet: Boolean): Char;
var
  E: Char;
  H: String;
begin
  // FPos is behind the backslash
  if (AtEnd) then Error ('Backslash am Ende');
  E := Peek;
  Inc (FPos);
  IsSet := true;
  Result := #0;
  case E of
    'd': CharSet := Digits;
    'D': CharSet := AllChars - Digits;
    'w': CharSet := WordChars;
    'W': CharSet := AllChars - WordChars;
    's': CharSet := Spaces;
    'S': CharSet := AllChars - Spaces;
  else
    IsSet := false;
    case E of
      't': Result := #9;
      'n': Result := #10;
      'r': Result := #13;
      'f': Result := #12;
      'a': Result := #7;
      'e': Result := #27;
      'x': begin
        H := Copy (FExpression, FPos, 2);
        if (Length (H) <> 2) or (not (H[1] in ['0'..'9', 'A'..'F', 'a'..'f']))
                             or (not (H[2] in ['0'..'9', 'A'..'F', 'a'..'f'])) then begin
          Error ('\x erwartet zwei Hex-Ziffern');
        end;
        Result := Chr (StrToInt ('$' + H));
        Inc (FPos, 2);
      end;
      'b', 'B': Error ('Wortgrenzen (\b, \B) werden nicht unterstuetzt');
    else
      Result := E;
    end;
  end;
end;


function TRegex.ParseClass: TRegexNode;
var
  Negate:  Boolean;
  First:   Boolean;
  Lo, Hi:  Char;
  S:       TRegexCharSet;
  IsSet:   Boolean;
  Res:     TRegexCharSet;
begin
  // FPos is behind '['
  Res := [];
  Negate := false;
  if (not AtEnd) and (Peek = '^') then begin
    Negate := true;
    Inc (FPos);
  end;
  First := true;
  while true do begin
    if (AtEnd) then Error ('Fehlendes ]');
    if (Peek = ']') and (not First) then begin
      Inc (FPos);
      break;
    end;
    First := false;

    if (Peek = '\') then begin
      Inc (FPos);
      Lo := ParseEscape (S, IsSet);
      if (IsSet) then begin
        Res := Res + S;
        continue;
      end;
    end else begin
      Lo := Peek;
      Inc (FPos);
    end;

    // Range a-z; a '-' before ']' is a literal
    if (FPos < Length (FExpression)) and (Peek = '-') and (FExpression[FPos + 1] <> ']') then begin
      Inc (FPos);
      if (Peek = '\') then begin
        Inc (FPos);
        Hi := ParseEscape (S, IsSet);
        if (IsSet) then Error ('Klasse als Bereichsende');
      end else begin
        Hi := Peek;
        Inc (FPos);
      end;
      if (Hi < Lo) then Error ('Bereich in falscher Reihenfolge');
      Res := Res + [Lo..Hi];
    end else begin
      Res := Res + [Lo];
    end;
  end;

  if (FModifierI) then Res := CaseFold (Res);
  if (Negate) then Res := AllChars - Res;
  Result := NewNode (rnSet);
  Result.CharSet := Res;
end;


function TRegex.ParseAtom: TRegexNode;
var
  C:     Char;
  S:     TRegexCharSet;
  IsSet: Boolean;
begin
  C := Peek;
  Inc (FPos);
  case C of
    '(': begin
      Result := NewNode (rnGroup);
      if (Copy (FExpression, FPos, 2) = '?:') then begin
        Inc (FPos, 2);
      end else begin
        Inc (FGroupCount);
        Result.Group := FGroupCount;
      end;
      Result.Add (ParseAlternation);
      if (AtEnd) or (Peek <> ')') then Error ('Fehlende )');
      Inc (FPos);
    end;
    '.': Result := NewNode (rnAny);
    '^': Result := NewNode (rnBol);
    '$': Result := NewNode (rnEol);
    '[': Result := ParseClass;
    '*', '+', '?': begin
      Dec (FPos);
      raise NewError ('Quantor ohne Ausdruck');
    end;
    '\': begin
      C := ParseEscape (S, IsSet);
      if (IsSet) then begin
        Result := NewNode (rnSet);
        Result.CharSet := S;
      end else begin
        Result := NewNode (rnChar);
        Result.C := C;
      end;
    end;
  else
    Result := NewNode (rnChar);
    Result.C := C;
  end;

  if (FModifierI) and (Result.Kind = rnChar) then begin
    S := CaseFold ([Result.C]);
    if (S <> [Result.C]) then begin
      Result.Kind := rnSet;
      Result.CharSet := S;
    end;
  end;
end;


function TRegex.CaseFold (const S: TRegexCharSet): TRegexCharSet;
var
  C: Char;
  U: String;
begin
  Result := S;
  for C := #1 to #255 do begin
    if (C in S) then begin
      U := AnsiUpperCase (C);
      if (Length (U) = 1) then Include (Result, U[1]);
      U := AnsiLowerCase (C);
      if (Length (U) = 1) then Include (Result, U[1]);
    end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Translation into instructions for the automaton


function TRegex.Emit (Op: TRegexOp): Integer;
begin
  Result := Length (FProg);
  SetLength (FProg, Result + 1);
  FillChar (FProg[Result], SizeOf (TRegexInstr), 0);
  FProg[Result].Op := Op;
end;


function TRegex.AddSet (const S: TRegexCharSet): Integer;
begin
  Result := Length (FSets);
  SetLength (FSets, Result + 1);
  FSets[Result] := S;
end;


procedure TRegex.SetSplit (Idx, Preferred, Other: Integer; Greedy: Boolean);
begin
  if (Greedy) then begin
    FProg[Idx].X := Preferred;
    FProg[Idx].Y := Other;
  end else begin
    FProg[Idx].X := Other;
    FProg[Idx].Y := Preferred;
  end;
end;


procedure TRegex.EmitNode (Node: TRegexNode);
var
  I, J, S, L:    Integer;
  Jumps:         array of Integer;
begin
  case Node.Kind of
    rnChar: begin
      I := Emit (roChar);
      FProg[I].C := Node.C;
    end;
    rnAny:   Emit (roAny);
    rnSet: begin
      I := Emit (roSet);
      FProg[I].SetIdx := AddSet (Node.CharSet);
    end;
    rnBol:   Emit (roBol);
    rnEol:   Emit (roEol);
    rnConcat:
      for I := 0 to High (Node.Children) do EmitNode (Node.Children[I]);
    rnAlternation: begin
      SetLength (Jumps, Length (Node.Children) - 1);
      for I := 0 to High (Node.Children) - 1 do begin
        S := Emit (roSplit);
        FProg[S].X := S + 1;
        EmitNode (Node.Children[I]);
        Jumps[I] := Emit (roJmp);
        FProg[S].Y := Length (FProg);
      end;
      EmitNode (Node.Children[High (Node.Children)]);
      for I := 0 to High (Jumps) do FProg[Jumps[I]].X := Length (FProg);
    end;
    rnGroup: begin
      if (Node.Group >= 0) then begin
        I := Emit (roSave);
        FProg[I].N := 2 * Node.Group;
      end;
      EmitNode (Node.Children[0]);
      if (Node.Group >= 0) then begin
        I := Emit (roSave);
        FProg[I].N := 2 * Node.Group + 1;
      end;
    end;
    rnRepeat:
      begin
        for I := 1 to Node.Min do EmitNode (Node.Children[0]);
        if (Node.Max = -1) then begin
          L := Emit (roSplit);
          EmitNode (Node.Children[0]);
          I := Emit (roJmp);
          FProg[I].X := L;
          SetSplit (L, L + 1, Length (FProg), Node.Greedy);
        end else begin
          SetLength (Jumps, Node.Max - Node.Min);
          for J := 0 to High (Jumps) do begin
            Jumps[J] := Emit (roSplit);
            EmitNode (Node.Children[0]);
          end;
          for J := 0 to High (Jumps) do SetSplit (Jumps[J], Jumps[J] + 1, Length (FProg), Node.Greedy);
        end;
      end;
  end;
end;


procedure TRegex.Compile;
var
  Root: TRegexNode;
  I:    Integer;
begin
  FCompiled := false;
  FMatched := false;
  FProg := nil;
  FSets := nil;
  FGroupCount := 0;
  FPos := 1;
  FNodes := TList.Create;
  try
    Root := ParseAlternation;
    if (not AtEnd) then Error ('Unerwartete )');
    I := Emit (roSave);
    FProg[I].N := 0;
    EmitNode (Root);
    I := Emit (roSave);
    FProg[I].N := 1;
    Emit (roMatch);
  finally
    for I := 0 to FNodes.Count - 1 do TObject (FNodes[I]).Free;
    FreeAndNil (FNodes);
  end;
  SetLength (FSlots, 2 * (FGroupCount + 1));
  FCompiled := true;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Execution


function TRegex.Run (Start: Integer): Boolean;
var
  Top:   Integer;
  PC:    Integer;
  SP:    Integer;
  Len:   Integer;
  Fail:  Boolean;
  I:     Integer;
  Bit:   Integer;
  Mask:  Cardinal;

  procedure Push (aKind: Byte; aA, aB: Integer);
  begin
    if (Top >= Length (FStack)) then SetLength (FStack, 2 * Length (FStack) + 64);
    FStack[Top].Kind := aKind;
    FStack[Top].A := aA;
    FStack[Top].B := aB;
    Inc (Top);
  end;

begin
  Result := false;
  for I := 0 to High (FSlots) do FSlots[I] := 0;
  Top := 0;
  PC := 0;
  SP := Start;
  Len := Length (FInput);

  while true do begin
    Fail := false;
    Bit := PC * (Len + 1) + (SP - 1);
    Mask := Cardinal (1) shl (Bit and 31);
    if ((FVisited[Bit shr 5] and Mask) <> 0) then begin
      Fail := true;
    end else begin
      FVisited[Bit shr 5] := FVisited[Bit shr 5] or Mask;
      with FProg[PC] do begin
        case Op of
          roChar:  if (SP <= Len) and (FInput[SP] = C) then begin
            Inc (SP);
            Inc (PC);
          end else Fail := true;
          roAny:   if (SP <= Len) then begin
            Inc (SP);
            Inc (PC);
          end else Fail := true;
          roSet:   if (SP <= Len) and (FInput[SP] in FSets[SetIdx]) then begin
            Inc (SP);
            Inc (PC);
          end else Fail := true;
          roBol:   if (SP = 1) then Inc (PC) else Fail := true;
          roEol:   if (SP = Len + 1) then Inc (PC) else Fail := true;
          roSplit: begin
            Push (0, Y, SP);
            PC := X;
          end;
          roJmp:   PC := X;
          roSave: begin
            Push (1, N, FSlots[N]);
            FSlots[N] := SP;
            Inc (PC);
          end;
          roMatch: begin
            Result := true;
            exit;
          end;
        end;
      end;
    end;

    while (Fail) do begin
      if (Top = 0) then exit;
      Dec (Top);
      case FStack[Top].Kind of
        0: begin
          PC := FStack[Top].A;
          SP := FStack[Top].B;
          Fail := false;
        end;
        1: FSlots[FStack[Top].A] := FStack[Top].B;
      end;
    end;
  end;
end;


function TRegex.Exec (const aInput: String): Boolean;
var
  Start: Integer;
  Z:     Integer;
  Bits:  Int64;
  Words: Integer;
begin
  FMatched := false;
  Result := false;
  if (not FCompiled) then Compile;

  // The input ends at the first #0, as with the previously used TRegExpr,
  // which worked on null-terminated strings
  Z := Pos (#0, aInput);
  if (Z > 0) then FInput := Copy (aInput, 1, Z - 1) else FInput := aInput;

  // The visited marks apply to all start positions: whether a state
  // leads to a match depends only on instruction and input position
  Bits := Int64 (Length (FProg)) * (Length (FInput) + 1);
  if (Bits > MaxVisitedBits) then begin
    raise ERegexError.CreateFmt ('Regulaerer Ausdruck "%s": Eingabe mit %d Zeichen ist zu lang', [FExpression, Length (FInput)]);
  end;
  Words := (Bits + 31) div 32;
  if (Length (FVisited) < Words) then SetLength (FVisited, Words);
  FillChar (FVisited[0], Words * SizeOf (Cardinal), 0);

  for Start := 1 to Length (FInput) + 1 do begin
    if (Run (Start)) then begin
      Result := true;
      break;
    end;
  end;
  FMatched := Result;
end;


function TRegex.GetMatchPos (Idx: Integer): Integer;
begin
  Result := -1;
  if (FMatched) and (Idx >= 0) and (Idx <= FGroupCount) and (FSlots[2 * Idx] > 0) and (FSlots[2 * Idx + 1] > 0) then begin
    Result := FSlots[2 * Idx];
  end;
end;


function TRegex.GetMatchLen (Idx: Integer): Integer;
begin
  Result := -1;
  if (GetMatchPos (Idx) > 0) then Result := FSlots[2 * Idx + 1] - FSlots[2 * Idx];
end;


function TRegex.GetMatch (Idx: Integer): String;
begin
  Result := '';
  if (GetMatchPos (Idx) > 0) then Result := Copy (FInput, FSlots[2 * Idx], FSlots[2 * Idx + 1] - FSlots[2 * Idx]);
end;


end.
