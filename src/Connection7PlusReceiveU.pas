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


unit Connection7PlusReceiveU;


interface


uses
  Classes, Windows, SysUtils, Messages, GlobalU,
  InterfacesU, SendFileU, ConnectionAbstractU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnection7PlusReceive = class (TConnectionAbstract)
  private
    TextLine: String;
    FilePathName: TextFile;
    FileName: String;
    CurrentPart, Quantity, LinesCount, CharsCount, LinesReceived: Integer;
    FileOpened: Boolean;
  public
    procedure   Init; override;
    procedure   ReceiveData; override;
    procedure   SendData; override;
    procedure   Terminated (Why: TWhyTerminated); override;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, FolderU, SoundsU, SoundsConstsU, ReceiveFilePostprocessorU;


{$I+}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TConnection7PlusReceive.Init;
const
  MethodName = 'Init';
var
  L: Integer;
  S: String;
  Header: String;

begin

  Sounds.PlayEvent (se_transfer_start, PacketConnection);

  UseEvent [e_receivedata] := true;
  UseEvent [e_senddata] := true;

  Header := PacketConnection.ReceiveQueue.dequeueLine;

  L := Length (Header);
  if (L > 0) and (Header[L] = #13) then Delete (Header, L, 1);

  DebOut (self, MethodName, 'Header: ' + Header);

  CurrentPart := StrToIntDef (Copy (Header, 9, 3), -1);
  Quantity := StrToIntDef (Copy (Header, 16, 3), -1);
  FileName := Trim (Copy (Header, 20, 12));
  CharsCount := StrToIntDef ('$' + Copy (Header, 41, 4), 0);
  LinesCount := CharsCount div 64;

  DebOut (self, MethodName, 'Teil: ' + IntToStr(CurrentPart));
  DebOut (self, MethodName, 'Anzahl: ' + IntToStr(Quantity));
  DebOut (self, MethodName, 'Original-Dateiname: ' + FileName);
  DebOut (self, MethodName, 'Zeilen erwartet: ' + IntToStr(LinesCount));

  if (Quantity = 1) then begin
    S := '.7pl';
  end else begin
    S := '.p' + IntToHex (CurrentPart, 2);
  end;
  FileName := Folders.Reception + ReceiveFilename (ChangeFileExt (FileName, S), '7plus' + S);

  DebOut (self, MethodName, 'Dateiname: ' + FileName);

  Filename := UniqueFilename (Filename);

  AssignFile (FilePathName, FileName);

  try
    ReWrite (FilePathName);
    WriteLn (FilePathName, Header);
    FileOpened := true;
  except
    Finish;
  end;

  TextLine := '';

  LinesReceived := 0;

  PacketConnection.FileSender := TSendFile.create (PacketConnection);
  with PacketConnection.FileSender do begin
    SourceFilename := FileName;
    TransferProtocol := prot_7plus;
    Absolute := LinesCount;
    TransferBegin;
  end;

end;


procedure   TConnection7PlusReceive.ReceiveData;
const
  MethodName = 'ReceiveData';

var
  L: Integer;

begin

  while not PacketConnection.ReceiveQueue.isEmpty do begin

    TextLine := TextLine + PacketConnection.ReceiveQueue.dequeueLine;
    L := Length (TextLine);

    if (L >= 1) then begin

      if TextLine[L] = #13 then begin

        PacketConnection.FileSender.Transfer (L);

        Delete (TextLine, L, 1);

        WriteLn (FilePathName, TextLine);

        if (L <= 1) then begin

          DebOut (self, MethodName, 'Ende (Leerzeile)');
          Finish;
          break;

        end else begin

          if (TextLine[1] = ' ') and (copy (TextLine, 2, 8) = 'stop_7+.') then begin
            DebOut (self, MethodName, 'Ende (" stop_7+.")');
            PacketConnection.ChannelReceiveText (TextLine + #13);
            Finish;
            break;
          end;

          if (TextLine[1] = '*') and (copy (TextLine, 2, 3) = '** ') then begin
            DebOut (self, MethodName, 'Ende ("*** ")');
            PacketConnection.ChannelReceiveText (TextLine + #13);
            Finish;
            break;
          end;

        end;

        Inc (LinesReceived);
        PacketConnection.FileSender.Progress := LinesReceived;

        TextLine := '';

      end;

    end;

  end;

end;


procedure   TConnection7PlusReceive.SendData;
begin
  PacketConnection.DeviceQueue.enqueue (PacketConnection.SendQueue.dequeueLine);
end;


procedure   TConnection7PlusReceive.Terminated (Why: TWhyTerminated);
const
  MethodName = 'Terminated';

resourcestring
  S7PlusReceiveOk = '7Plus-Empfang ok.';
  S7PlusReceiveError = '7Plus-Empfang Fehler.';
  SReceivedFileSaved = 'Empfangene Datei gespeichert:';
  SReceivedFileNotSaved = 'Empfangene Datei NICHT gespeichert.';

begin

  if (FileOpened) then CloseFile (FilePathName);

  DebOut (self, MethodName, 'Zeilen empfangen: ' + IntToStr(LinesReceived));

  case Why of
    e_finish: Sounds.PlayEvent (se_transfer_success, PacketConnection);
    e_cancel: Sounds.PlayEvent (se_transfer_cancel, PacketConnection);
    e_abort: Sounds.PlayEvent (se_transfer_error, PacketConnection);
  end;

  if (assigned (PacketConnection)) and (Why in [e_finish, e_abort]) then begin
    if (Why = e_finish) then begin
      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (#13, true);
        if (FileOpened) then begin
          PacketConnection.SendTextData (RemotePrompt + S7PlusReceiveOk + #13, true);
        end else begin
          PacketConnection.SendTextData (RemotePrompt + S7PlusReceiveError + #13, true);
        end;
      end;
      if (FileOpened) then begin
        PacketConnection.ChannelPrompt (SReceivedFileSaved + #13 + FileName, dt_pgp);
      end;
    end else begin
      PacketConnection.ChannelPrompt (SReceivedFileNotSaved + #13, dt_pgp);
    end;
  end;

  PacketConnection.FileSender.TransferEnd;
  PacketConnection.FileSender.Release;
  PacketConnection.FileSender := nil;

  if (Why <> e_finish) then begin
    try
      Recycle (FileName);
    except
    end;
  end;

  inherited;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

