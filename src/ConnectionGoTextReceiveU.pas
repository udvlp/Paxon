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


unit ConnectionGoTextReceiveU;


interface


uses
  Classes, Windows, SysUtils, Messages, GlobalU,
  InterfacesU, SendFileU, ConnectionAbstractU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TConnectionGoTextReceive = class (TConnectionAbstract)
  private
    TextLine: String;
    FilePathName: TextFile;
    FileName: String;
    FileOpened: Boolean;
    Echo: Boolean;
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


procedure   TConnectionGoTextReceive.Init;
const
  MethodName = 'Init';
var
  L: Integer;
  Header: String;
  S: String;

begin

  UseEvent [e_receivedata] := true;
  UseEvent [e_senddata] := true;

  // Abbrechbar machen: Kommt das Ende nie, bliebe der Empfang sonst bis zum
  // Disconnect aktiv.
  CanCancel := true;

  FileOpened := false;

  Header := PacketConnection.ReceiveQueue.dequeueLine;

  L := Length (Header);
  if (L > 0) then begin
    if (Header[L] = #13) then Delete (Header, L, 1);
    DebOut (self, MethodName, 'GoText-Header: ' + Header);
    if (Header[1] = ' ') then Delete (Header, 1, 1);
    L := Pos (' ', Header);
    if L > 0 then begin
      Delete (Header, 1, L);
      FileName := Folders.Reception + ReceiveFilename (Header, 'gotext.txt');
      DebOut (self, MethodName, 'GoText-Dateiname: ' + FileName);

      Echo := true;
      S := UpperCase (ExtractFileExt (FileName));
      if Length (S) >= 1 then begin
        if S[1] = '.' then Delete (S, 1, 1);
        if (S = 'COR') or (S = 'ERR') then Echo := false;
      end;

      Filename := UniqueFilename (Filename);
      DebOut (self, MethodName, 'GoText-SpeichernUnter: ' + FileName);
      AssignFile (FilePathName, FileName);
      try
        ReWrite (FilePathName);
        FileOpened := true;
      except
        Finish;
      end;
    end else begin
      Finish;
    end;
  end else begin
    Finish;
  end;

  TextLine := '';

  Sounds.PlayEvent (se_transfer_start, PacketConnection);

end;


procedure   TConnectionGoTextReceive.ReceiveData;
var
  L: Integer;
  S: String;

begin

  while not PacketConnection.ReceiveQueue.isEmpty do begin

    S := PacketConnection.ReceiveQueue.dequeueLine;

    if Echo then PacketConnection.ChannelReceiveText (S);

    TextLine := TextLine + S;

    L := Length (TextLine);

    if L >= 1 then begin

      if TextLine[L] = #13 then begin

        Delete (TextLine, L, 1);

        if (L >= 2) then begin

          if (TextLine[1] = ' ') and ((copy (TextLine, 2, 10) = 'stop_text.') or (copy (TextLine, 2, 10) = 'stop_info.')) then begin
            if not Echo then PacketConnection.ChannelReceiveText (S);
            Finish;
            break;
          end;

          if (TextLine[1] = '*') and (copy (TextLine, 2, 3) = '** ') then begin
            if not Echo then PacketConnection.ChannelReceiveText (S);
            Finish;
            break;
          end;

        end;

        WriteLn (FilePathName, TextLine);

        TextLine := '';

      end;

    end;

  end;

end;


procedure   TConnectionGoTextReceive.SendData;
begin
  PacketConnection.DeviceQueue.enqueue (PacketConnection.SendQueue.dequeueLine);
end;


procedure   TConnectionGoTextReceive.Terminated (Why: TWhyTerminated);
const
  MethodName = 'Terminated';

resourcestring
  SGoTextReceiveOk = 'GoText-Empfang ok.';
  SGoTextReceiveError = 'GoText-Empfang Fehler.';
  SReceivedFileSaved = 'Empfangene Datei gespeichert:';
  SReceivedFileNotSaved = 'Empfangene Datei NICHT gespeichert.';

begin

  case Why of
    e_finish: Sounds.PlayEvent (se_transfer_success, PacketConnection);
    e_cancel: Sounds.PlayEvent (se_transfer_cancel, PacketConnection);
    e_abort: Sounds.PlayEvent (se_transfer_error, PacketConnection);
  end;

  // A failing close (e.g. disk full on the final flush) must not skip the rest of the
  // cleanup; the file is then treated as not saved.
  if (FileOpened) then begin
    try
      CloseFile (FilePathName);
    except
      on E: Exception do begin
        DebOut (self, MethodName, 'CloseFile: ' + E.Message);
        FileOpened := false;
      end;
    end;
  end;

  if (assigned (PacketConnection)) and (Why in [e_finish, e_abort, e_cancel]) then begin

    if (Why = e_finish) then begin
      if (PacketConnection.StationType in [st_unknown, st_terminal]) then begin
        PacketConnection.SendTextData (#13, true);
        if (FileOpened) then begin
          PacketConnection.SendTextData (RemotePrompt + SGoTextReceiveOk + #13, true);
        end else begin
          PacketConnection.SendTextData (RemotePrompt + SGoTextReceiveError + #13, true);
        end;
      end;
      if (FileOpened) then begin
        PacketConnection.ChannelPrompt (SReceivedFileSaved + #13 + FileName, dt_pgp);
      end;
    end else begin
      PacketConnection.ChannelPrompt (SReceivedFileNotSaved + #13, dt_pgp);
    end;

  end;

  if ((Why <> e_finish) or (not FileOpened)) and (FileName <> '') then begin
    try
      Recycle (FileName);
    except
    end;
  end;

  inherited;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

