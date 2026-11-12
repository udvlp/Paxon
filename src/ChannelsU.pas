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


unit ChannelsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ComCtrls, Buttons, ExtCtrls, Menus,
  SyncObjs, ChannelU, ConsoleU, RichEditPaxonU, InterfacesU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TChannels = class
  private

    FChannelCount: Integer;
    FCurrentChannelNo: Integer;
    FFont: TFont;
    FChannel: Array of IChannel;
    FTextBufferPath: String;
    // protects FChannel/FChannelCount: changing the count (main thread) against the search
    // for a free channel and accesses from the device threads
    NextFreeChannelCriticalSection: TCriticalSection;
    FActionChannel: IChannel;
    ReadableChars: Array[#$00..#$FF] of Byte;

    procedure   SetCurrentChannelNo (TheValue: Integer);
    procedure   SetFont (F: TFont);
    procedure   FontChange (Sender: TObject);
    function    GetCurrentChannel: IChannel;
    function    GetChannelRef (No: Integer): IChannel;
    procedure   SetChannelCount (const Value: Integer);
    function    GetActionChannel: IChannel;
    procedure   SetConsoleRows (const Value: Cardinal);

  public

    procedure   ChannelButtonClick (Sender: TObject);
    property    CurrentChannel: IChannel read GetCurrentChannel;
    property    CurrentChannelNo: Integer read FCurrentChannelNo write SetCurrentChannelNo;
    constructor Create;
    procedure   AfterConstruction; override;
    procedure   BeforeDestruction; override;
    property    Quantity: Integer read FChannelCount write SetChannelCount;
    property    Font: TFont read FFont write SetFont;
    function    NextFreeChannel: IChannel;
    procedure   Monitor (const Frame: TMonitorFrame); overload;
    procedure   Monitor (const aHeader: String; const aText: String); overload;
    property    ChannelRef [No: Integer]: IChannel read GetChannelRef; default;
    property    TextBufferPath: String read FTextBufferPath;
    procedure   UpdateColors;
    property    ActionChannel: IChannel read GetActionChannel write FActionChannel;
    property    ConsoleRows: Cardinal write SetConsoleRows;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  FT_I = 1;
  FT_RR = 2;
  FT_RNR = 3;
  FT_REJ = 4;
  FT_SABM = 5;
  FT_DISC = 6;
  FT_DM = 7;
  FT_UA = 8;
  FT_FRMR = 9;
  FT_UI = 10;

  // Limits as in the settings dialog (GeneralSettingsU)
  MinChannels = 1;
  MaxChannels = 40;
  MinConsoleRows = 500;
  MaxConsoleRows = 30000;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  ChannelList: TChannels = nil;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, MainU, GlobalU, ConfigU, SoundsU,
  SoundsConstsU, UnhandledExceptionU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TChannels.Create;
begin
  inherited Create;
  FChannelCount := Config.Channels;
  if (FChannelCount < MinChannels) then
    FChannelCount := MinChannels
  else
    if (FChannelCount > MaxChannels) then FChannelCount := MaxChannels;
end;


procedure   TChannels.AfterConstruction;
const
  MethodName = 'AfterConstruction';

var
  N: Integer;
  S: String;
  C: Char;

begin

  inherited;

  assert (not assigned (ChannelList));
  ChannelList := self;

  FTextBufferPath := 'Text Buffers\';

  FCurrentChannelNo := 1;

  FFont := TFont.Create;
  FFont.OnChange := FontChange;

  NextFreeChannelCriticalSection := TCriticalSection.create;

  ForceDirectories (ApplicationDataPath + FTextBufferPath);
  SetLength (FChannel, FChannelCount + 1);

  MainWindow.ChannelToolbar.BeginUpdate;
  for N := 0 to FChannelCount do begin
    FChannel[N] := TChannel.Create (N, FChannelCount);
  end;
  MainWindow.ChannelToolbar.EndUpdate;

  S := Config.FontSize;
  if (S = '') then S := '08x12';
  Font.Name := ConsoleFontName + ' ' + S;

  for C := #$00 to #$FF do ReadableChars[C] := 1;

  ReadableChars[#$0D] := 0;
  for C := #$20 to #$7E do ReadableChars[C] := 0;
  ReadableChars[#$80] := 0;
  ReadableChars['ä'] := 0;
  ReadableChars['ö'] := 0;
  ReadableChars['ü'] := 0;
  ReadableChars['Ä'] := 0;
  ReadableChars['Ö'] := 0;
  ReadableChars['Ü'] := 0;
  ReadableChars['ß'] := 0;
  ReadableChars[#$81] := 0;
  ReadableChars[#$84] := 0;
  ReadableChars[#$8E] := 0;
  ReadableChars[#$94] := 0;
  ReadableChars[#$99] := 0;
  ReadableChars[#$9A] := 0;
  ReadableChars[#$E1] := 0;

  ReadableChars[#$00] := 4;
  ReadableChars[#$7F] := 3;
  ReadableChars[#$FE] := 3;
  ReadableChars[#$FF] := 3;
  ReadableChars['À'] := 4;

  FChannel[1].ActivateChannel (true);

end;


procedure   TChannels.BeforeDestruction;
const
  MethodName = 'BeforeDestruction';
var
  N: Integer;

begin

  DebOut (self, MethodName, 'begin...');

  FActionChannel := nil;

  FChannelCount := 0;
  for N := Low(FChannel) to High (FChannel) do begin
    if (assigned (FChannel[N])) then begin
      DebOut (self, MethodName, Format ('Kanal[%2.2d] := nil', [N]));
      FChannel[N].Release;
      FChannel[N] := nil;
    end;
  end;
  SetLength (FChannel, 0);

  FFont.Free;

  NextFreeChannelCriticalSection.free;

  inherited;

  DebOut (self, MethodName, 'end.');

end;


procedure   TChannels.SetFont (F: TFont);
begin
  FFont.Assign (F);
end;


procedure   TChannels.FontChange (Sender: TObject);
var
  N: Integer;
begin
  for N := 0 to FChannelCount do begin
    FChannel[N].Font := FFont;
  end;
end;


procedure   TChannels.SetCurrentChannelNo (TheValue: Integer);
begin

  assert ((TheValue >= 0) and (TheValue <= FChannelCount));

  try

    if (FCurrentChannelNo <> TheValue) then begin

      FChannel[FCurrentChannelNo].ActivateChannel (false);
      FChannel[TheValue].ActivateChannel (true);

      FCurrentChannelNo := TheValue;

      MainWindow.ActionDisconnect.Enabled := not (TheValue = 0);
      MainWindow.ActionSend.Enabled := not (TheValue = 0);
      MainWindow.ActionStop.Enabled := not (TheValue = 0);

      Sounds.PlayEvent (se_channelswitch);

    end else begin

      FChannel[TheValue].ActivateChannel (true);

    end;

  except

    DebOut (self, 'SetCurrentChannelNo', 'Exception');

  end;

end;


procedure    TChannels.ChannelButtonClick (Sender: TObject);
begin
  CurrentChannelNo := (Sender as TToolButton).Tag;
end;


function     TChannels.GetCurrentChannel: IChannel;
begin
  NextFreeChannelCriticalSection.Enter;
  try
    Result := FChannel[FCurrentChannelNo];
  finally
    NextFreeChannelCriticalSection.Leave;
  end;
end;


function     TChannels.NextFreeChannel: IChannel;
var
  N: Integer;
begin
  NextFreeChannelCriticalSection.Enter;
  try
    result := nil;
    for N := 1 to FChannelCount do begin
      if (FChannel[N].IsIncomingConnectionPossible) then begin
        result := FChannel[N];
        result.IsReserved := true;
        break;
      end;
    end;
  finally
    NextFreeChannelCriticalSection.Leave;
  end;
end;


procedure   TChannels.Monitor (const Frame: TMonitorFrame);
const
  MethodName = 'Monitor';

var
  P, A, B, S, T, U, V, W, X: String;
  I, N, L, M: Integer;
  Bin: Boolean;
  Monitor: Cardinal;

begin

  if (Length (Frame.Src) > 0) then begin

    Monitor := Config.Monitor;

    if (length (Frame.Digis) > 0) then U := ' v ' + Frame.Digis else U := '';

    case Frame.FrameType of
      FT_I:    T := Format ('%s%d%d', ['I', Frame.RXSeq, Frame.TXSeq]);
      FT_RR:   T := Format ('%s%d', ['RR', Frame.RXSeq]);
      FT_RNR:  T := Format ('%s%d', ['RNR', Frame.RXSeq]);
      FT_REJ:  T := Format ('%s%d', ['REJ', Frame.RXSeq]);
      FT_SABM: T := 'SABM';
      FT_DISC: T := 'DISC';
      FT_DM:   T := 'DM';
      FT_UA:   T := 'UA';
      FT_FRMR: T := 'FRMR';
      FT_UI:   T := 'UI';
      else     T := '???';
    end;

    if (Frame.PollFinal) then begin
      if (Frame.Command) then V := '+' else V := '-';
    end else begin
      if (Frame.Command) then V := '^' else V := 'v';
    end;

    if (Frame.FrameType = FT_I) and (Frame.Pid <> $F0) then X := ' $' + IntToHex (Frame.Pid, 2);

    if (Frame.Dama) then W := ' DAMA' else W := '';

    A := Frame.Text;

    if (Frame.FrameType = FT_I) then begin
      Bin := false;
      if ((Monitor and MonitorInformationBinary) = 0) then begin
        L := Length (Frame.Text);
        if (Frame.Pid <> $F0) then begin
          Bin := true;
        end else begin
          if (L > 0) then begin
            if (L > 24) then N := 24 else N := L;
            M := 0;
            for I := N downto 1 do begin
              inc (M, ReadableChars [Frame.Text[I]]);
              if (M >= 4) then begin
                Bin := true;
                break;
              end;
            end;
          end;
        end;
        if (Bin) then begin
          B := Format (' BIN%d', [L]);
          A := '';
        end;
      end;
    end;

    if ((Monitor and MonitorPort) <> 0) then begin
      P := Format ('%1d%2.2d: ', [Frame.Device, Frame.Port]);
    end else begin
      P := '';
    end;

    S := Format ('[%s%s > %s%s %s%s%s%s%s]', [P, Frame.Src, Frame.Dest, U, T, V, W, B, X]);

    ChannelRef[0].Monitor (S, A, Frame.Sent);

  end;

end;


procedure   TChannels.Monitor (const aHeader, aText: String);
begin
  ChannelRef[0].WriteOutput (6, #13 + aHeader + #13 + aText + #13);
end;


function    TChannels.GetChannelRef (No: Integer): IChannel;
begin
  // Copy under the lock; output via the channel only afterwards (SendMessage
  // to the main thread must not happen under the lock)
  NextFreeChannelCriticalSection.Enter;
  try
    result := FChannel[No];
  finally
    NextFreeChannelCriticalSection.Leave;
  end;
end;


procedure   TChannels.SetChannelCount (const Value: Integer);
const
  MethodName = 'SetChannelCount';

var
  N: Integer;
  S: String;
  F: File;

begin

  if (Value <> FChannelCount) then begin

    MainWindow.ChannelToolbar.BeginUpdate;

    // Device threads search for free channels at the same time (NextFreeChannel)
    // and read FChannel; SetLength may move the array.
    NextFreeChannelCriticalSection.Enter;
    try

      if (Value < FChannelCount) then begin

        if (CurrentChannelNo > Value) then CurrentChannelNo := Value;

        for N := FChannelCount downto Value + 1 do begin

          if (assigned (FChannel[N])) then begin
            // also keep reserved channels: a device thread has just
            // taken them for an incoming connection
            if (FChannel[N].IsChannelConnected) or (FChannel[N].IsReserved) then break;
            FChannel[N].Release;
            FChannel[N] := nil;
          end;

          S := Format ('%s%sBuffer%2.2x.pxn', [ApplicationDataPath, TextBufferPath, N]);
          AssignFile (F, S);
          try
            Erase (F);
          except
          end;

          dec (FChannelCount);

        end;

      end else if (Value > FChannelCount) then begin

        SetLength (FChannel, Value + 1);
        for N := FChannelCount + 1 to Value do begin
          FChannel[N] := TChannel.Create (N, Value);
          FChannel[N].Font := FFont;
          inc (FChannelCount);
        end;

      end;

      SetLength (FChannel, FChannelCount + 1);

    finally
      NextFreeChannelCriticalSection.Leave;
    end;

    Config.Channels := FChannelCount;

    MainWindow.ChannelToolbar.EndUpdate;

  end;

end;


procedure   TChannels.UpdateColors;
var
  N: Integer;
begin
  for N := Low(FChannel) to High (FChannel) do begin
    if (assigned (FChannel[N])) then FChannel[N].UpdateColors;
  end;
end;


function    TChannels.GetActionChannel: IChannel;
begin
  if (assigned (FActionChannel)) then begin
    result := FActionChannel;
  end else begin
    result := CurrentChannel;
  end;
end;


procedure   TChannels.SetConsoleRows (const Value: Cardinal);
var
  N: Integer;
  R: Cardinal;
begin
  R := Value;
  if (R < MinConsoleRows) then R := MinConsoleRows else if (R > MaxConsoleRows) then R := MaxConsoleRows;
  for N := Low(FChannel) to High (FChannel) do begin
    if (assigned (FChannel[N])) then FChannel[N].ConsoleRows := R;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

