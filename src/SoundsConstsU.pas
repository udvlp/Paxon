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


unit SoundsConstsU;


interface


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TSignalType = (st_undefined, st_silence, st_pcspk, st_wave);


  TAnnouncementType = (at_undefined, at_silence, at_voice, at_cw);


  TSoundEvent = (se_connecting,
                 se_connected_out,
                 se_connected_in,
                 se_disconnecting,
                 se_disconnected,
                 se_linkfailure,
                 se_ring,
                 se_rx_active,
                 se_rx_inactive,
                 se_tx,
                 se_transfer_start,
                 se_transfer_success,
                 se_transfer_cancel,
                 se_transfer_error,
                 se_pgp_valid,
                 se_pgp_unknown,
                 se_pgp_wrong,
                 se_channelswitch,
                 se_programstart,
                 se_programend);


type
  TSoundEventRec = record
    Name: String;
    ID: Integer;
    AnnouncementPossible: Boolean;
    OnlyGlobal: Boolean;
    Parallel: Boolean;
    LowPriority: Boolean;
  end;


function SoundEvents(SE: TSoundEvent): TSoundEventRec;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


function SoundEvents(SE: TSoundEvent): TSoundEventRec;
resourcestring
  sen_connecting       = 'Verbindung: Aufbau';
  sen_connected_out    = 'Verbindung: Hergestellt (ausgehend)';
  sen_connected_in     = 'Verbindung: Hergestellt (ankommend)';
  sen_disconnecting    = 'Verbindung: Abbau';
  sen_disconnected     = 'Verbindung: Getrennt';
  sen_linkfailure      = 'Verbindung: Fehler';
  sen_ring             = 'Fernsteuerung: //RING';
  sen_rx_active        = 'Zeile empfangen (aktiver Kanal)';
  sen_rx_inactive      = 'Zeile empfangen (inaktiver Kanal)';
  sen_tx               = 'Zeile senden';
  sen_transfer_start   = 'Dateiübertragung: Start';
  sen_transfer_success = 'Dateiübertragung: Erfolg';
  sen_transfer_cancel  = 'Dateiübertragung: Abbruch';
  sen_transfer_error   = 'Dateiübertragung: Fehler';
  sen_pgp_valid        = 'PGP: Signatur gültig';
  sen_pgp_unknown      = 'PGP: Unterzeichner/Echtheit unbekannt';
  sen_pgp_wrong        = 'PGP: Nachricht verändert';
  sen_channelswitch    = 'Kanalwechsel';
  sen_programstart     = 'Programmstart';
  sen_programend       = 'Programmende';
begin
  with result do begin
    case SE of
      se_connecting:       begin Name := sen_connecting; ID := 00; AnnouncementPossible := True;  OnlyGlobal := False; Parallel := False; LowPriority := true; end;
      se_connected_out:    begin Name := sen_connected_out; ID := 01; AnnouncementPossible := True;  OnlyGlobal := False; Parallel := False; LowPriority := false; end;
      se_connected_in:     begin Name := sen_connected_in; ID := 02; AnnouncementPossible := True;  OnlyGlobal := False; Parallel := False; LowPriority := false; end;
      se_disconnecting:    begin Name := sen_disconnecting; ID := 03; AnnouncementPossible := True;  OnlyGlobal := False; Parallel := False; LowPriority := true; end;
      se_disconnected:     begin Name := sen_disconnected; ID := 04; AnnouncementPossible := True;  OnlyGlobal := False; Parallel := False; LowPriority := false; end;
      se_linkfailure:      begin Name := sen_linkfailure; ID := 05; AnnouncementPossible := True;  OnlyGlobal := False; Parallel := False; LowPriority := false; end;
      se_ring:             begin Name := sen_ring; ID := 06; AnnouncementPossible := True;  OnlyGlobal := False; Parallel := True; LowPriority := false; end;
      se_rx_active:        begin Name := sen_rx_active; ID := 07; AnnouncementPossible := False; OnlyGlobal := False; Parallel := True; LowPriority := true; end;
      se_rx_inactive:      begin Name := sen_rx_inactive; ID := 08; AnnouncementPossible := False; OnlyGlobal := False; Parallel := True; LowPriority := true; end;
      se_tx:               begin Name := sen_tx; ID := 09; AnnouncementPossible := False; OnlyGlobal := False; Parallel := True; LowPriority := true; end;
      se_transfer_start:   begin Name := sen_transfer_start; ID := 10; AnnouncementPossible := False; OnlyGlobal := False; Parallel := False; LowPriority := false; end;
      se_transfer_success: begin Name := sen_transfer_success; ID := 11; AnnouncementPossible := False; OnlyGlobal := False; Parallel := False; LowPriority := false; end;
      se_transfer_cancel:  begin Name := sen_transfer_cancel; ID := 12; AnnouncementPossible := False; OnlyGlobal := False; Parallel := False; LowPriority := false; end;
      se_transfer_error:   begin Name := sen_transfer_error; ID := 13; AnnouncementPossible := False; OnlyGlobal := False; Parallel := False; LowPriority := false; end;
      se_pgp_valid:        begin Name := sen_pgp_valid; ID := 14; AnnouncementPossible := False; OnlyGlobal := True;  Parallel := False; LowPriority := false; end;
      se_pgp_unknown:      begin Name := sen_pgp_unknown; ID := 15; AnnouncementPossible := False; OnlyGlobal := True;  Parallel := False; LowPriority := false; end;
      se_pgp_wrong:        begin Name := sen_pgp_wrong; ID := 16; AnnouncementPossible := False; OnlyGlobal := True;  Parallel := False; LowPriority := false; end;
      se_channelswitch:    begin Name := sen_channelswitch; ID := 17; AnnouncementPossible := False; OnlyGlobal := True;  Parallel := True; LowPriority := true; end;
      se_programstart:     begin Name := sen_programstart; ID := 18; AnnouncementPossible := False; OnlyGlobal := True;  Parallel := False; LowPriority := false; end;
      se_programend:       begin Name := sen_programend; ID := 19; AnnouncementPossible := False; OnlyGlobal := True;  Parallel := False; LowPriority := false; end;
    end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

