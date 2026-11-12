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


unit ConnectionStandardU;


interface


uses
  Classes, Windows, SysUtils, Messages, GlobalU,
  InterfacesU, SendFileU, ConnectionAbstractU, PGPCheckU, RegexU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionStandard = class (TConnectionAbstract)
  private
    TextLine: String;
    CText: Integer;
    PGPCheck: TPGPCheck;
    LastStationType: TStationType;
    SIDReceived: Boolean;
    HideReceivedSID: Boolean;
    InSID: Boolean;
    SID: String;
    BoxRegExpr: TRegex;
    DieboxLoginLines: Integer;
    PasswordLines: Integer;
    OwnResponses: TStringList; // automatic password responses (text as queued) that may still be in the SendQueue
    procedure   SendOwnResponse (const Text: string);
    function    ProcessPassword (TextLine: string; PasswordKind: TPasswordKind): Boolean;
    procedure   PasswordBaycom (Prompt, PasswordValue: string);
    procedure   PasswordMD5 (Prompt, PasswordValue: string);
    procedure   PasswordDieBox (Prompt: string);
    procedure   SetStationType;
  public
    procedure   BeforeDestruction; override;
    procedure   Release; override;
    procedure   Init; override;
    procedure   ReceiveData; override;
    procedure   SendData; override;
    procedure   SendFile; override;
    procedure   Terminated (Why: TWhyTerminated); override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, Connection7PlusReceiveU, ConnectionGoTextReceiveU, ConnectionAutobinReceiveU,
  MD5U, ConnectionTextSendU, ConnectionAutobinSendU, ConnectionDidaditSendU,
  ConnectionDidaditReceiveU, FileStreamUlfU, StationDatabaseU, ConfigU,
  BoxListU, DateUtils;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  MaxDieboxLoginLines = 4;
  MaxCTextLines = 3;
  MaxPasswordLinesLogin = 20;  // received lines after connection setup in which a password prompt counts
  MaxPasswordLinesCommand = 3;  // received lines after a line of our own (e.g. a password command)


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnectionStandard.BeforeDestruction;
begin
  Release;
  inherited;
end;


procedure   TConnectionStandard.Release;
begin
  if (not Released) then begin
    if (assigned (PGPCheck)) then begin
      PGPCheck.free;
      PGPCheck := nil;
    end;
    if (assigned (OwnResponses)) then begin
      OwnResponses.free;
      OwnResponses := nil;
    end;
    inherited;
  end;
end;


procedure   TConnectionStandard.Init;
begin

  UseEvent [e_receivedata] := true;
  UseEvent [e_senddata]    := true;
  UseEvent [e_sendfile]    := true;
  TextLine := '';
  SID := '';
  CText := MaxCTextLines;
  PGPCheck := TPGPCheck.create (PacketConnection);
  if (not assigned (OwnResponses)) then begin
    OwnResponses := TStringList.create;
    OwnResponses.CaseSensitive := true;
  end;
  OwnResponses.Clear;
  SIDReceived := false;
  HideReceivedSID := Config.HideReceivedSID;
  DieboxLoginLines := 0;
  PasswordLines := MaxPasswordLinesLogin;
  SetStationType;

end;


procedure   TConnectionStandard.ReceiveData;
const
  MethodName = 'ReceiveData';

resourcestring
  SNoRemote = 'Keine Auswertung von Fernsteuerbefehlen.';

var
  B: Boolean;
  T, U: String;
  I, N, M, K, L: Integer;
  PA: TPasswordKind;
  SpaceAdded: Integer;
  ChannelRef: IChannelForConnection;
  CursorY: Integer;
  PartnerStationType: TStationType;
  RegExpr: TRegex;


begin

  while (assigned (PacketConnection.ReceiveQueue)) and (not PacketConnection.ReceiveQueue.isEmpty) do begin

    T := PacketConnection.ReceiveQueue.dequeueLine;

    if (Length (T) > 0) then begin

      if (not SIDReceived) then begin

        if (TextLine = '') then begin
          if (T[1] = '{') then begin
            InSID := true;
          end;
        end;

        if (InSID) then begin
          I := Pos ('}', T);
          M := Pos (#13, T);
          if (I <= 0) or ((M > 0) and (M < I)) then I := M;
          if (I > 0) then begin
            SID := SID + copy (T, 1, I);
            if (HideReceivedSID) then Delete (T, 1, I);
            InSID := false;
          end else begin
            SID := SID + T;
            if (HideReceivedSID) then T := '';
          end;
          if (not InSID) then begin
            I := Length (SID);
            if (I > 0) then begin
              if (I >= 6) and (I <= 78) and (SID[1] = '{') and (SID[2] <> '-') and (SID[I-1] <> '-') and (SID[I] = '}') then begin
                K := 0;
                L := 0;
                for M := 3 to I - 2 do begin
                  if (SID[M] = '-') then begin
                    inc (L);
                    if (M >= K + 2) then begin
                      K := M;
                    end else begin
                      L := 0;
                      break;
                    end;
                  end;
                end;
                if (L = 2) then begin

                  DebOut (self, MethodName, 'SID = %s', [SID]);
                  if (not HideReceivedSID) then begin
                    PacketConnection.ChannelReceiveText (T);
                  end;

                  RegExpr := TRegex.create;

                  RegExpr.Expression := '\{.+-.+-(.*)\}';
                  if (RegExpr.Exec (SID)) then begin
                    if (Pos ('D', RegExpr.Match[1]) >= 1) then begin
                      PacketConnection.BinMode := prot_didadit;
                    end;
                  end;

                  RegExpr.Free;

                  T := '';
                  if (Config.SendSID) and (PacketConnection.Outgoing) then begin
                    PacketConnection.SendSID;
                  end;

                  SIDReceived := true;
                  SID := '';

                end;
              end;
              if (SID <> '') then begin
                if (HideReceivedSID) then T := SID + T;
                SID := '';
              end;
            end;
          end;
        end;

      end;

      TextLine := TextLine + T;
      SpaceAdded := Length (TextLine);

      CursorY := PacketConnection.ChannelReceiveText (T) - 1;

      if (SpaceAdded > 0) and (TextLine[SpaceAdded] = #13) then begin // line complete

        if (assigned (PGPCheck)) then PGPCheck.Receive (TextLine);

        // Answer passwords only on connections we set up ourselves: on an
        // incoming connection the remote station (with a freely chosen
        // callsign) controls every line and could pose arbitrary challenges.
        if (PacketConnection.Outgoing) and (DieboxLoginLines < MaxDieboxLoginLines) then begin
          PasswordDieBox (TextLine);
        end;

        if (CText <= 0) then PA := pa_sysop else PA := pa_user;

        // Accept password prompts only shortly after connection setup or after a line of our own,
        // never in Convers: there any participant can send a line that looks like a prompt.
        B := (PacketConnection.Outgoing) and (PasswordLines > 0) and (PacketConnection.StationType <> st_convers);
        if (PasswordLines > 0) then dec (PasswordLines);

        if (B) and (ProcessPassword (TextLine, PA)) then begin

          // One challenge per window: after that, only again after a line of our own
          PasswordLines := 0;

          if (CText > 0) then begin
            if (PacketConnection.StationType = st_unknown) then begin
              LastStationType := st_unknown;
              PacketConnection.StationType := st_box;
            end;
            DebOut (self, MethodName, 'CText: Passwortabfrage erkannt => ' + StationTypeText(PacketConnection.StationType));
            CText := 0;
          end;

        end else if (CText > 0) then begin

          U := TextLine;
          L := Length (U);
          if (L > 0) and (U[L] = #13) then Delete (U, L, 1);
          U := AnsiLowerCase (Trim (U));
          if (Length (U) > 0) then begin
            if (PacketConnection.StationType = st_unknown) then begin
              I := MaxInt;
              K := -1;
              for N := Low(CTextKey) to High (CTextKey) do begin
                M := Pos (AnsiLowerCase (CTextKey[N].Key), U);
                if (M > 0) and (M < I) then begin
                  I := M;
                  K := N;
                end;
              end;
              if (K >= 0) then begin
                LastStationType := PacketConnection.StationType;
                PacketConnection.StationType := CTextKey[K].StationType;
                DebOut (self, MethodName, 'CText: "' + CTextKey[K].Key + '" erkannt => ' +
                        StationTypeText(PacketConnection.StationType));
                CText := 0;
              end;
            end else begin
              CText := 0;
            end;
          end;

        end else if (PacketConnection.StationType = st_unknown) then begin

          LastStationType := PacketConnection.StationType;
          PacketConnection.StationType := st_terminal;
          DebOut (self, MethodName, 'CText: Nichts erkannt => ' + StationTypeText(PacketConnection.StationType));

        end;

        PartnerStationType := PacketConnection.StationType;

        if (SpaceAdded >= 3) and (PartnerStationType in [st_unknown, st_terminal]) and (TextLine[1] = '/') and
           (TextLine[2] = '/') and (TextLine[3] <> '/') and (TextLine[3] <> ' ') then begin

          if (PacketConnection.RemoteCommandsPossible) then begin
            PacketConnection.RemoteCommands.Call (TextLine);
          end else begin
            PacketConnection.ChannelPrompt (SNoRemote, dt_pgp);
          end;

        end else if (PartnerStationType in [st_unknown, st_digi, st_box, st_terminal]) and
                    (StrLComp (PChar(TextLine), PChar('#BIN#'), 5) = 0) then begin

          PacketConnection.ReceiveQueue.undequeue (TextLine);
          Run (PacketConnection, TConnectionAutobinReceive);

        end else if (PartnerStationType in [st_unknown, st_digi, st_box, st_terminal]) and
                    (StrLComp (PChar(TextLine), PChar('#DIDADIT#'), 9) = 0) then begin

          PacketConnection.ReceiveQueue.undequeue (TextLine);
          Run (PacketConnection, TConnectionDidaditReceive);

        end else if (PartnerStationType in [st_unknown, st_digi, st_box, st_terminal]) and
                    (StrLComp (PChar(TextLine), PChar(' go_7+. '), 8) = 0) then begin

          PacketConnection.ReceiveQueue.undequeue (TextLine);
          Run (PacketConnection, TConnection7PlusReceive);

        end else if (PartnerStationType in [st_unknown, st_digi, st_box, st_terminal]) and
                    ((StrLComp (PChar(TextLine), PChar(' go_text. '), 10) = 0) or
                     (StrLComp (PChar(TextLine), PChar(' go_info. '), 10) = 0)) then begin

          PacketConnection.ReceiveQueue.undequeue (TextLine);
          Run (PacketConnection, TConnectionGoTextReceive);

        end else if (PartnerStationType in [st_unknown, st_digi, st_terminal]) and
                    ((StrLComp (PChar(TextLine), PChar('conversd @ '), 11) = 0) or
                     (StrLComp (PChar(TextLine), PChar('kaconversd @ '), 13) = 0)) then begin

          LastStationType := PacketConnection.StationType;
          PacketConnection.StationType := st_convers;

        end else if (PartnerStationType in [st_convers]) and
                    (StrLIComp (PChar(TextLine), PChar('Convers session terminated.'), 27) = 0) then begin

          PacketConnection.StationType := LastStationType;
          LastStationType := st_convers;

        end else begin

          if (PartnerStationType = st_box) then begin

            if (not assigned (BoxRegExpr)) then begin
              BoxRegExpr := TRegex.create;
              BoxRegExpr.Expression := BoxListExpression;
            end;

            if (BoxRegExpr.Exec (TextLine)) then begin

              ChannelRef := PacketConnection.ChannelRef;
              if (assigned (ChannelRef)) then ChannelRef.SetBoxListLine (CursorY);

            end;

          end;

          L := SpaceAdded;
          T := UpperCase (TextLine);

          if (L > 0) and (T[L] = #13) then begin
            Delete (T, L, 1);
            dec (L);
          end;

          if (L > 1) and (T[1] <> ' ') then begin

            B := false;
            I := pos (' CONNECTED TO ', T);
            if (I > 0) then begin
              Delete (T, 1, I + 13);
            end else begin
              B := true;
              I := pos (' RECONNECTED TO ', T);
              if (I > 0) then begin
                Delete (T, 1, I + 15);
              end;
            end;

            if (I > 0) then begin

              K := Pos (':', T);
              if (K > 0) and (K <= 9) and (T[K+1] in ['A'..'Z', '0'..'9']) then begin
                delete (T, 1, K);
              end;

              T := Trim (T);
              K := Pos (' ', T);
              if (K > 0) then delete (T, K, Length (T));

              if (B) then begin
                PartnerStationType := PacketConnection.StationType;
                if (PacketConnection.InfoboxReconnect (T)) then begin
                  LastStationType := PartnerStationType;
                end;
              end else begin
                if (PacketConnection.InfoboxConnect (T)) then begin
                  CText := MaxCTextLines;
                  DieboxLoginLines := 0;
                  PasswordLines := MaxPasswordLinesLogin;
                  SetStationType;
                end;
              end;

            end;

          end;

        end;

        TextLine := '';

        dec (CText);

      end;

    end;

  end;

end;


procedure   TConnectionStandard.SendData;
var
  S: String;
  I: Integer;
begin
  S := PacketConnection.SendQueue.dequeue;
  // After a line of our own (e.g. SYS), briefly check the remote station's response for a password prompt.
  // The automatic password response itself does not reopen the window, otherwise
  // the remote station could pose any number of challenges in a row.
  // It is recognized by its text, not by its position: user lines may already be
  // ahead of it in the queue.
  if (Pos (#13, S) > 0) then begin
    if (assigned (OwnResponses)) then I := OwnResponses.IndexOf (S) else I := -1;
    if (I >= 0) then begin
      OwnResponses.Delete (I);
    end else if (PasswordLines < MaxPasswordLinesCommand) then begin
      PasswordLines := MaxPasswordLinesCommand;
    end;
  end;
  // The responses are remembered in this thread (ReceiveData) before they are queued. If the
  // queue is now empty, none is left in it; any others were sent by another module (e.g. line by line).
  if (assigned (OwnResponses)) and (OwnResponses.Count > 0) and (PacketConnection.SendQueue.isEmpty) then begin
    OwnResponses.Clear;
  end;
  PacketConnection.DeviceQueue.enqueue (S);
end;


procedure   TConnectionStandard.SendOwnResponse (const Text: string);
// Send the automatic password response and remember it so that SendData recognizes it
begin
  if (assigned (OwnResponses)) then OwnResponses.Add (Text);
  PacketConnection.SendTextData (Text, True);
end;


procedure   TConnectionStandard.SendFile;
const
  MethodName = 'SendFile';

var
  FileSender: ISendFile;

begin

  DebOut (self, MethodName, 'begin...');

  assert (not assigned (PacketConnection.FileSender));

  FileSender := PacketConnection.SendFileQueue.current;

  if (assigned (FileSender)) then begin

    PacketConnection.FileSender := FileSender;

    try

      assert (assigned (PacketConnection.FileSender));
      case FileSender.TransferProtocol of
        prot_text:      Run (PacketConnection, TConnectionTextSend);
        prot_autobin:   Run (PacketConnection, TConnectionAutobinSend);
        prot_binary:    beep;
        prot_didadit:   Run (PacketConnection, TConnectionDidaditSend);
        else            beep;
      end;

      PacketConnection.SendFileQueue.remove (FileSender);

      if (assigned (FileSender)) then begin
        FileSender.Release;
        FileSender := nil;
      end;

    finally

      if (assigned (PacketConnection.FileSender)) then begin
        PacketConnection.FileSender.Release;
        PacketConnection.FileSender := nil;
      end;

    end;

  end;

  DebOut (self, MethodName, 'end.');

end;


procedure   TConnectionStandard.Terminated (Why: TWhyTerminated);
begin
  inherited;
end;


function    TConnectionStandard.ProcessPassword (TextLine: string; PasswordKind: TPasswordKind): Boolean;
const
  MethodName = 'ProcessPassword';
var
  E: IStationDatabaseEntry;
  S, T, Pwd: string;
  N, I, L, K: Integer;
  PV: TPasswordMethod;

begin

  Result := False;

  L := Length (TextLine);
  if (L < 14) then exit;
  if (TextLine[L] = #13) then dec (L);
  if (not (TextLine[L] in [']', '0'..'9'])) then exit;

  S := StripSSID (PacketConnection.Call) + '> ';

  T := AnsiUpperCase (TextLine);
  I := Pos (S, T);
  if (I <= 0) then begin
    S := PacketConnection.Call + '> ';
    I := Pos (S, T);
    if (I <= 0) then exit;
  end;

  // The prompt must be at the start of the line, preceded at most by an alias as in "FFM:DB0FFM> 3 7 1 12 5".
  // Otherwise a Convers or text line "<DL1ABC>: DB0XYZ> 3 7 1 12 5" would also count as a prompt.
  K := 1;
  while (K < I) and (T[K] = #10) do inc (K);
  if (K < I) then begin
    if (T[I - 1] <> ':') then exit;
    while (K < I - 1) do begin
      if (not (T[K] in ['A'..'Z', '0'..'9', '-'])) then exit;
      inc (K);
    end;
  end;

  Delete (TextLine, 1, I + Length (S) - 1);

  L := Length (TextLine);
  if (L <= 4) then exit;

  if (TextLine[L] = #13) then Delete (TextLine, L, 1);
  if (TextLine[1] = ' ') then Delete (TextLine, 1, 1);

  case TextLine[1] of

    '0'..'9': begin
      PV := pv_baycom;
      // Only the positions may follow the prompt.
      for I := 1 to Length (TextLine) do begin
        if (not (TextLine[I] in ['0'..'9', ' '])) then exit;
      end;
    end;

    '[': begin
      PV := pv_md5;
      Delete (TextLine, 1, 1);
      I := Length (TextLine);
      if I <= 0 then begin
        Exit;
      end else begin
        if (TextLine[I] = ']') then Delete (TextLine, I, 1);
        I := Length (TextLine);
        if (I <> 10) then exit;
      end;
    end;

    else begin
      exit;
    end;

  end;

  Result := True;

  E := StationDatabase.Open (PacketConnection.Call, true);

  if (assigned (E)) then begin

    S := StripSSID (PacketConnection.MyCall);

    for N := Ord (Low(TPasswordKind)) to Ord (High (TPasswordKind)) do begin

      Pwd := E.GetPasswordValue (S, PasswordKind, PV);

      while (true) do begin
        I := Pos (#13, Pwd);
        if (I <= 0) then I := Pos (#10, Pwd);
        if (I <= 0) then break;
        Delete (Pwd, I, 1);
      end;

      if (Length (Pwd) > 0) then break;

      if (PasswordKind < High (PasswordKind)) then Inc (PasswordKind) else PasswordKind := Low(PasswordKind);

    end;

    if (Length (Pwd) = 0) then Debout (Self, MethodName, 'Kein Passwort gespeichert.');

    if (Length (Pwd) > 0) then begin

      case PV of
        pv_baycom: PasswordBaycom (TextLine, Pwd);
        pv_md5: PasswordMD5 (TextLine, Pwd);
      end;

    end;

  end;

  E := nil;

end;


procedure   TConnectionStandard.PasswordBaycom (Prompt: string; PasswordValue: string);
const
  MethodName = 'PasswordBaycom';
  RandomStringLength = 67;

resourcestring
  STooManyValues = 'Passwort-Prompt enthält zu viele Positionen.';
  SInvalidChars = 'Passwort-Prompt enthält ungültige Zeichen.';
  STooShort = 'Gespeichertes Passwort zu kurz.';

var
  ZI: array[0..4] of Integer;
  I, N, L: Integer;
  C: char;
  HasError: Boolean;
  S, T: string;
  CharsetStr: string;
  AllCharacters: string;

begin

  for N := Low(ZI) to High (ZI) do ZI[N] := 0;

  HasError := False;
  N := Low(ZI);
  for I := 1 to Length (Prompt) do begin
    C := Prompt[I];
    if (C = ' ') then begin
      Inc (N);
    end else if (C in ['0'..'9']) then begin
      if N > High (ZI) then begin
        PacketConnection.ChannelPrompt (STooManyValues, dt_pgp);
        HasError := True;
        break;
      end;
      ZI[N] := (10 * ZI[N]) + (Ord (C) - Ord ('0'));
    end else begin
      PacketConnection.ChannelPrompt (SInvalidChars, dt_pgp);
      HasError := True;
      break;
    end;
  end;

  if not HasError then begin

    S := '';
    L := Length (PasswordValue);
    for N := Low(ZI) to High (ZI) do begin
      if (ZI[N] >= 1) then begin
        if (ZI[N] <= L) then begin
          S := S + PasswordValue[ZI[N]];
        end else begin
          PacketConnection.ChannelPrompt (STooShort, dt_pgp);
          HasError := True;
          break;
        end;
      end else begin
        break;
      end;
    end;

  end;

  if (not HasError) then begin

    AllCharacters := '';
    for C := #33 to #126 do AllCharacters := AllCharacters + C;

    CharsetStr := '';
    for N := 1 to Length (PasswordValue) do begin
      if (Pos (PasswordValue[N], CharsetStr) <= 0) then begin
        CharsetStr := CharsetStr + PasswordValue[N];
        I := Pos (PasswordValue[N], AllCharacters);
        if (I > 0) then Delete (AllCharacters, I, 1);
      end;
    end;

    I := Length (CharsetStr) div 3 + 2;
    while (true) do begin
      N := Length (AllCharacters);
      if (N <= I) then break;
      Delete (AllCharacters, Random(N) + 1, 1);
    end;

    CharsetStr := CharsetStr + AllCharacters;

    L := Length (CharsetStr);
    SetLength (T, RandomStringLength);
    for I := 1 to RandomStringLength do T[I] := CharsetStr[Random(L) + 1];

    N := Random (RandomStringLength) + 1;

    S := Copy (T, 1, N) + S + Copy (T, N + 1, MaxInt);

    SendOwnResponse (S + #13);

  end;

end;


procedure   TConnectionStandard.PasswordMD5 (Prompt: string; PasswordValue: string);
const
  MethodName = 'PasswordMD5';
var
  Msg: string;
  Digest: string;
begin
  Debout (Self, MethodName, 'begin...');
  // Do not output challenge, password and response in DebOut.
  Msg := Prompt + PasswordValue;
  Digest := LowerCase (GetMD5OfString (Msg));
  SendOwnResponse (Digest + #13);
  Debout (Self, MethodName, 'end.');
end;


procedure   TConnectionStandard.SetStationType;
var
  E: IStationDatabaseEntry;

begin

  E := StationDatabase.Open (PacketConnection.Call, true);

  if (assigned (E)) then begin
    if (E.StationType <> st_unknown) then begin
      LastStationType := PacketConnection.StationType;
      PacketConnection.StationType := E.StationType;
    end;
  end;

  E := nil;

end;


procedure   TConnectionStandard.PasswordDieBox (Prompt: String);
const
  MethodName = 'PasswordDieBox';
  RandomStringLength = 67;
resourcestring
  SNotLength1620 = 'Das in der Datenbank gespeicherte Passwort hat nicht die erforderliche Länge von 1620 Zeichen.';
var
  RegExpr: TRegex;
  I, J, K: Integer;
  Error: Boolean;
  E: IStationDatabaseEntry;
  S, T, Pwd, LastPwd: string;
  PasswordKind: TPasswordKind;
  YearNum, MonthNum, Tag, HourVal, Minute: Integer;
  Mul: Array[0..4] of Integer;
  Pos: Array[0..4] of Integer;
  C: Char;
  MyCall: String;
  RandomText: String;
  RandomPos: Integer;

begin

  Debout (Self, MethodName, 'begin...');

  inc (DieboxLoginLines);

  Tag    := 0;
  MonthNum  := 0;
  YearNum   := 0;
  HourVal := 0;
  Minute := 0;
  RandomPos := 1;
  RandomText := '';

  RegExpr := TRegex.create;
  RegExpr.Expression := '.*Login: (\d\d)\.(\d\d)\.(\d\d) (\d\d):(\d\d).*';
  if (RegExpr.Exec (TextLine)) then begin
    try
      Tag    := StrToInt (RegExpr.Match[1]);
      MonthNum  := StrToInt (RegExpr.Match[2]);
      YearNum   := StrToInt (RegExpr.Match[3]) mod 100;
      HourVal := StrToInt (RegExpr.Match[4]);
      Minute := StrToInt (RegExpr.Match[5]);
      Error := false;
    except
      Error := true;
    end;
  end else begin
    Error := true;
  end;
  RegExpr.Free;

  if (not Error) then begin

    DebOut (self, MethodName, 'Tag: %d  Monat: %d  Jahr: %d  Stunde: %d  Minute: %d', [Tag, MonthNum, YearNum, HourVal, Minute]);

    LastPwd := '';

    E := StationDatabase.Open (PacketConnection.Call, true);

    if (assigned (E)) then begin

      MyCall := StripSSID (PacketConnection.MyCall);

      for PasswordKind := Low(TPasswordKind) to High (TPasswordKind) do begin

        DebOut (self, MethodName, '------ Art = %d', [ord (PasswordKind)]);

        T := E.GetPasswordValue (MyCall, PasswordKind, pv_diebox);

        if (Length (T) > 0) then begin

          SetLength (Pwd, 1620);
          I := 1;
          for J := 1 to Length (T) do begin
            if (T[J] in ['0'..'9', 'A'..'Z', 'a'..'z']) then begin
              Pwd [I] := T[J];
              inc (I);
              if (I > 1621) then break;
            end;
          end;
          SetLength (Pwd, I - 1);

          if (Length (Pwd) = 1620) then begin

            DebOut (self, MethodName, 'Pwd-Länge: %d', [Length (Pwd)]);

            Mul[0] :=  3;
            Mul[1] :=  5;
            Mul[2] :=  7;
            Mul[3] :=  9;
            Mul[4] := 11;

            K := (Minute + 1) * 1620 div 60;

            DebOut (self, MethodName, 'Startposition: %d', [K]);

            I := 0;
            for J := K - 1 to 1620 * 5 - 2 + K do begin
              C := Pwd[J mod 1620 + 1];
              if (C in ['1'..'9']) then begin
                Mul[I] := Ord (C) - Ord ('0');
                inc (I);
                if (I > 4) then break;
              end;
            end;

            Pos[0] := (HourVal * Mul[0] + Minute * Mul[1] + Tag * Mul[2] + MonthNum * Mul[3] + YearNum * YearNum * Mul[4] +
                       Mul[2] * Mul[3]);
            Pos[1] := (HourVal * Mul[1] + Minute * Mul[3] + Tag * Mul[0] + MonthNum * Mul[4] + YearNum * YearNum * Mul[2] +
                       Mul[0] * Mul[4]);
            Pos[2] := (HourVal * Mul[2] + Minute * Mul[0] + Tag * Mul[4] + MonthNum * Mul[1] + YearNum * YearNum * Mul[3] +
                       Mul[1] * Mul[2]);
            Pos[3] := (HourVal * Mul[3] + Minute * Mul[4] + Tag * Mul[1] + MonthNum * Mul[2] + YearNum * YearNum * Mul[0] +
                       Mul[3] * Mul[4]);
            Pos[4] := (HourVal * Mul[4] + Minute * Mul[2] + Tag * Mul[3] + MonthNum * Mul[0] + YearNum * YearNum * Mul[1] +
                       Mul[0] * Mul[2]);

            for J := 0 to 4 do begin
              if (Pos[J] > 1620) then Pos[J] := (Pos[J] mod 1620) + 1;
            end;

            if (Pwd <> LastPwd) then begin
              SetLength (RandomText, RandomStringLength);
              for J := 1 to RandomStringLength do begin
                RandomText[J] := Pwd[Random(1620) + 1];
              end;
              RandomPos := Random (RandomStringLength) + 1;
            end;

            SetLength (S, 5);
            for J := 0 to 4 do begin
              S[J+1] := Pwd[Pos[J]];
            end;

            T := RandomText;
            insert (S, T, RandomPos);

            SendOwnResponse ('PRIV ' + T + #13);

            LastPwd := Pwd;

          end else begin

            PacketConnection.ChannelPrompt (SNotLength1620, dt_pgp);

          end;

        end;

      end;

      E := nil;

    end;

    DieboxLoginLines := MaxDieboxLoginLines;

  end else begin

    E := StationDatabase.Open (PacketConnection.Call, true);
    if (assigned (E)) then begin
      MyCall := StripSSID (PacketConnection.MyCall);
      if (E.GetPasswordValue (MyCall, pa_user, pv_diebox) = '') then DieboxLoginLines := MaxDieboxLoginLines;
      E := nil;
    end else begin
      DieboxLoginLines := MaxDieboxLoginLines;
    end;

  end;

  Debout (Self, MethodName, 'end.');

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

