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


unit BoxListU;


interface


uses
  Windows, Classes, SysUtils, Contnrs,
  GlobalU, InterfacesU,
  ConsoleU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  IChannelForBoxlist = interface ['{8A6427F4-93D6-4AFC-B828-19F8762C7069}']

    function    GetConsole: TConsole;
    property    Console: TConsole read GetConsole;

    function    GetPacketConnection: IConnection;
    property    PacketConnection: IConnection read GetPacketConnection;

  end;

  TBoxCommand = class;


  TLineType = (lt_other, lt_unchecked, lt_read, lt_erase);


  TBoxList = class
  private
    FChannel: IChannelForBoxlist;
    FConsole: TConsole;
    FCommandList: TObjectList;
    procedure   DeleteCommand (aLineNo: Cardinal);
    procedure   ClearDots;
    function    CommandLine (Cmd: TObject): Integer;
    procedure   DropStaleCommands;
    procedure   ConsoleLineDown;
    procedure   ClipLines (var Y1, Y2: Integer);
    function    LineTypeAt (const Y: Integer): Integer;
  public
    constructor create (aChannelObj: IChannelForBoxlist);
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    procedure   AddCommand (aBoxCommand: TBoxCommand);
    procedure   Read (Y1: Integer; Y2: Integer; Toggle: Boolean; Down: Boolean);
    procedure   Erase (Y1: Integer; Y2: Integer; Toggle: Boolean; Down: Boolean);
    procedure   Uncheck (Y1: Integer; Y2: Integer; Down: Boolean);
    procedure   Execute;
    procedure   FindLastList;
    procedure   FindNextList;
    procedure   FindPrevList;
    function    GetChecked (Y: Integer): TLineType;
  end;


  TBoxCommandType = (bc_read, bc_erase);


  TBoxCommand = class
  private
    FLineNo: Cardinal;
    FCommand: TBoxCommandType;
  public
    constructor create (aLineNo: Cardinal; aCommand: TBoxCommandType);
  end;


const
  BoxListExpression = '^ *([0-9]+)[^ ]? +([0-9A-Z]+[0-9][A-Z]+) +((\> )([0-9A-Za-z_\-][0-9A-Za-z_\-]?[0-9A-Za-z_\-]?[0-9A-Za-z_\-]?[0-9A-Za-z_\-]?'
                    + '[0-9A-Za-z_\-]?[0-9A-Za-z_\-]?[0-9A-Za-z_\-]?)((\.*)([0-9]+))? +)?'
                    + '([0-9][0-9]\.[0-9][0-9](\.[0-9][0-9])? +)?([0-9][0-9]\:[0-9][0-9] +)?([A-Z0-9]* +)?([0-9]* +)?([0-9]* +)?(.*)$';


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, RegexU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TBoxList.create (aChannelObj: IChannelForBoxlist);
begin
  inherited create;
  FChannel := aChannelObj;
  FConsole := FChannel.Console;
end;


procedure   TBoxList.AfterConstruction;
begin
  inherited;
  FCommandList := TObjectList.Create;
end;


procedure   TBoxList.BeforeDestruction;
begin
  ClearDots;
  FCommandList.free;
  inherited;
end;


procedure   TBoxList.AddCommand (aBoxCommand: TBoxCommand);
var
  I: Integer;
  B: Boolean;
begin
  DeleteCommand (aBoxCommand.FLineNo);
  B := false;
  for I := 0 to FCommandList.Count - 1 do begin
    if (aBoxCommand.FLineNo < TBoxCommand(FCommandList[I]).FLineNo) then begin
      FCommandList.Insert (I, aBoxCommand);
      B := true;
      break;
    end;
  end;
  if (not B) then FCommandList.Add (aBoxCommand);
end;


procedure   TBoxList.DeleteCommand (aLineNo: Cardinal);
var
  I: Integer;
begin
  for I := FCommandList.Count - 1 downto 0 do begin
    if (TBoxCommand(FCommandList[I]).FLineNo = aLineNo) then begin
      FCommandList.Delete (I);
    end;
  end;
end;


procedure   TBoxList.Execute;
const
  MethodName = 'Execute';

var
  I, N, L, R: Integer;
  Cmd: TBoxCommand;
  Y: Integer;
  RegExpr: TRegex;
  P, U: PChar;
  S, T: String;
  Board: String;
  NumberValue: Integer;
  Text: String;
  PacketConnection: IConnection;
  B: Boolean;
  LineHeader: PLineHeader;

begin

  DropStaleCommands;
  ClearDots;
  RegExpr := TRegex.create;
  Text := '';

  try

    RegExpr.Expression := BoxListExpression;

    for I := 0 to FCommandList.Count - 1 do begin

      Cmd := TBoxCommand(FCommandList[I]);
      Y := FConsole.CursorY - Integer(FConsole.LastAbsNo - Cmd.FLineNo);
      if (Y < 0) or (Y >= FConsole.Rows) then continue; // line has meanwhile scrolled out of the buffer
      P := FConsole.ScreenPtrT (0, Y);
      SetLength (S, FConsole.Cols);
      Move (P^, S[1], FConsole.Cols);
      S := TrimRight (S);
      DebOut (self, MethodName, S);

      if (RegExpr.Exec (S)) then begin

        // for J := 1 to 10 do begin
        // end;

        Board := RegExpr.Match[5];

        if (Length (Board) > 0) then begin

          // CHECK or DIR NEWS

          T := RegExpr.Match[8];
          if (Length (T) = 0) then begin //DIR NEWS
            T := RegExpr.Match[1];
          end;

          NumberValue := StrToIntDef (T, -1);

        end else begin

          // LIST

          NumberValue := StrToIntDef (RegExpr.Match[1], -1);
          N := Y;
          B := false;
          while (N >= 0) do begin
            P := FConsole.ScreenPtrT (0, N);
            if (not (P[0] in ['0'..'9', ' '])) then begin
              B := true;
              break;
            end;
            dec (N);
          end;

          // B: header line N found (P points to it); without it there is no board,
          // P would still point to a list line
          if (B) and (N >= 1) then begin
            LineHeader := FConsole.ScreenPtrH (N - 1);
            if (LineHeader.Length > 0) then begin
              U := FConsole.ScreenPtrT (0, N - 1);
              if (U[LineHeader.Length - 1] <> '>') then begin
                P := U;
              end;
            end;
          end;

          Board := '';
          if (B) then begin
            SetLength (S, FConsole.Cols);
            Move (P^, S[1], FConsole.Cols);
            S := TrimRight (S);
            N := Pos ('@', S);
            if (N > 0) then Delete (S, N, MaxInt);
            // The loop variable of a for loop is undefined afterwards, hence while.
            // R: last character of the last word (0 if none), L: its first character
            R := Length (S);
            while (R >= 1) and (not (S[R] in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_'])) do dec (R);
            L := R;
            while (L >= 2) and (S[L-1] in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) do dec (L);
            if (R >= 1) then Board := Copy (S, L, R - L + 1);
          end;

        end;

        if (Length (Board) > 0) and (NumberValue > 0) then begin
          if (Text <> '') then Text := Text + ';';
          case Cmd.FCommand of
            bc_read: S := 'R';
            bc_erase: S := 'E';
          end;
          Text := Text + Format ('%s %s %d', [S, Board, NumberValue]);
        end;

      end;

    end;

    DebOut (self, MethodName, Text);
    PacketConnection := FChannel.PacketConnection;
    if (assigned (PacketConnection)) and (Text <> '') then begin
      PacketConnection.SendTextData (Text + #13, true, false, false, true);
    end;

  finally

    RegExpr.free;

  end;

end;


function    TBoxList.CommandLine (Cmd: TObject): Integer;
// Bildschirmzeile des Befehls oder -1. -1 auch, wenn die Zeile dort nicht mehr
// die markierte ist: Nach "Ausgabefenster löschen" beginnt die Zeilennummer
// (AbsNo) wieder bei 0, und eine neue Zeile könnte dieselbe Nummer tragen.
// Die Markierung (R/E) hat nur die ursprüngliche Zeile.
var
  C: TBoxCommand;
  T: TLineType;
  LH: PLineHeader;
begin
  C := TBoxCommand (Cmd);
  result := FConsole.CursorY - Integer(FConsole.LastAbsNo - C.FLineNo);
  if (result < 0) or (result >= FConsole.Rows) then begin
    result := -1;
    exit;
  end;
  LH := FConsole.ScreenPtrH (result);
  if (not assigned (LH)) or (LH.AbsNo <> C.FLineNo) then begin
    result := -1;
    exit;
  end;
  T := GetChecked (result);
  if ((C.FCommand = bc_read) and (T <> lt_read)) or ((C.FCommand = bc_erase) and (T <> lt_erase)) then begin
    result := -1;
  end;
end;


procedure   TBoxList.DropStaleCommands;
var
  I: Integer;
begin
  for I := FCommandList.Count - 1 downto 0 do begin
    if (CommandLine (FCommandList[I]) < 0) then FCommandList.Delete (I);
  end;
end;


procedure   TBoxList.ClearDots;
var
  I, Y: Integer;
begin
  for I := FCommandList.Count - 1 downto 0 do begin
    // Zeilen, die aus dem Puffer gelaufen oder nicht mehr die markierten sind,
    // bekommen keinen Punkt.
    Y := CommandLine (FCommandList[I]);
    if (Y >= 0) then FConsole.SetGutterImageIndex (4, Y);
  end;
end;


function    TBoxList.GetChecked (Y: Integer): TLineType;
var
  LineHeader: PLineHeader;
begin
  if (Y < 0) or (Y >= FConsole.Rows) then begin
    result := lt_other;
    exit;
  end;
  LineHeader := FConsole.ScreenPtrH (Y);
  if (LineHeader.LineType = 1) then begin
    if (LineHeader.ImageIndex = 1) then begin
      result := lt_erase;
    end else if (LineHeader.ImageIndex = 3) then begin
      result := lt_read;
    end else begin
      result := lt_unchecked;
    end;
  end else begin
    result := lt_other;
  end;
end;


procedure   TBoxList.Uncheck (Y1, Y2: Integer; Down: Boolean);
var
  LineHeader: PLineHeader;
  Y: Integer;
begin
  ClipLines (Y1, Y2);
  for Y := Y1 to Y2 do begin
    LineHeader := FConsole.ScreenPtrH (Y);
    if (LineHeader.LineType = 1) then begin
      DeleteCommand (LineHeader.AbsNo);
      FConsole.SetGutterImageIndex (4, Y);
    end;
  end;
  if (Down) then ConsoleLineDown;
end;


procedure   TBoxList.Read (Y1, Y2: Integer; Toggle: Boolean; Down: Boolean);
var
  LineHeader: PLineHeader;
  Y: Integer;
  B: Boolean;

begin

  ClipLines (Y1, Y2);

  if (Toggle) then begin
    B := false;
    for Y := Y1 to Y2 do begin
      if (not (GetChecked (Y) in [lt_read, lt_other])) then begin
        B := true;
        break;
      end;
    end;
  end else begin
    B := true;
  end;

  if (B) then begin
    for Y := Y1 to Y2 do begin
      LineHeader := FConsole.ScreenPtrH (Y);
      if (LineHeader.LineType = 1) then begin
        AddCommand (TBoxCommand.create (LineHeader.AbsNo, bc_read));
        FConsole.SetGutterImageIndex (3, Y);
      end;
    end;
  end else begin
    Uncheck (Y1, Y2, false);
  end;

  if (Down) then ConsoleLineDown;

end;


procedure   TBoxList.Erase (Y1, Y2: Integer; Toggle: Boolean; Down: Boolean);
var
  LineHeader: PLineHeader;
  Y: Integer;
  B: Boolean;

begin

  ClipLines (Y1, Y2);

  if (Toggle) then begin
    B := false;
    for Y := Y1 to Y2 do begin
      if (not (GetChecked (Y) in [lt_erase, lt_other])) then begin
        B := true;
        break;
      end;
    end;
  end else begin
    B := true;
  end;

  if (B) then begin
    for Y := Y1 to Y2 do begin
      LineHeader := FConsole.ScreenPtrH (Y);
      if (LineHeader.LineType = 1) then begin
        AddCommand (TBoxCommand.create (LineHeader.AbsNo, bc_erase));
        FConsole.SetGutterImageIndex (1, Y);
      end;
    end;
  end else begin
    Uncheck (Y1, Y2, false);
  end;

  if (Down) then ConsoleLineDown;

end;


// Limit the line range to the existing lines of the console. A selection up
// to the end has Bottom = Rows, the caret is -1 after deletion.
procedure   TBoxList.ClipLines (var Y1, Y2: Integer);
begin
  if (Y1 < 0) then Y1 := 0;
  if (Y2 > FConsole.Rows - 1) then Y2 := FConsole.Rows - 1;
end;


procedure   TBoxList.ConsoleLineDown;
var
  Key: Word;
begin
  if (FConsole.Selection.Top < 0) or (FConsole.Selection.Top = FConsole.Selection.Bottom) then begin
    FConsole.CaretX := 0;
    Key := vk_down;
    FConsole.KeyDown (Key, []);
  end;
end;


procedure   TBoxList.FindLastList;
var
  Y: Integer;
  LineHeader: PLineHeader;
begin
  Y := FConsole.CaretY;
  LineHeader := FConsole.ScreenPtrH (Y);
  if (assigned (LineHeader)) then begin
    if (LineHeader.LineType = 1) then begin
      FConsole.ScrollTo (0, Y - (FConsole.ClientSize.Y div 2 + 1));
    end else begin
      // Search the last list line from the bottom; Y is -1 if there is none.
      Y := FConsole.Rows - 1;
      while (Y >= 0) do begin
        LineHeader := FConsole.ScreenPtrH (Y);
        if (assigned (LineHeader)) and (LineHeader.LineType = 1) then break;
        dec (Y);
      end;
      if (Y >= 0) then begin
        FConsole.ScrollTo (0, Y - (FConsole.ClientSize.Y div 2 + 1));
        FConsole.CaretX := 0;
        FConsole.CaretY := Y;
      end;
    end;
  end;
end;


function    TBoxList.LineTypeAt (const Y: Integer): Integer;
var
  LineHeader: PLineHeader;
begin
  // lines outside the buffer have no type
  if (Y < 0) or (Y >= FConsole.Rows) then begin
    Result := -1;
  end else begin
    LineHeader := FConsole.ScreenPtrH (Y);
    if (assigned (LineHeader)) then Result := LineHeader.LineType else Result := -1;
  end;
end;


procedure   TBoxList.FindPrevList;
var
  Y: Integer;
begin
  // The loop variable of a for loop is undefined afterwards, hence while.
  Y := FConsole.CaretY;
  // Skip lines of the current list
  while (Y >= 0) and (LineTypeAt (Y) = 1) do dec (Y);
  // Search for the previous list
  while (Y >= 0) and (LineTypeAt (Y) <> 1) do dec (Y);
  if (Y >= 0) then begin
    FConsole.ScrollTo (0, Y - (FConsole.ClientSize.Y div 2 + 1));
    FConsole.CaretX := 0;
    FConsole.CaretY := Y;
  end;
end;


procedure   TBoxList.FindNextList;
var
  Y: Integer;
begin
  Y := FConsole.CaretY;
  if (Y < 0) then Y := 0;
  // Skip lines of the current list
  while (Y < FConsole.Rows) and (LineTypeAt (Y) = 1) do inc (Y);
  // Search for the next list
  while (Y < FConsole.Rows) and (LineTypeAt (Y) <> 1) do inc (Y);
  if (Y < FConsole.Rows) then begin
    FConsole.ScrollTo (0, Y - (FConsole.ClientSize.Y div 2 + 1));
    FConsole.CaretX := 0;
    FConsole.CaretY := Y;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TBoxCommand.create  (aLineNo: Cardinal; aCommand: TBoxCommandType);
begin
  inherited create;
  FLineNo := aLineNo;
  FCommand := aCommand;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

