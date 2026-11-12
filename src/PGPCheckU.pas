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


unit PGPCheckU;


interface


uses
  Classes, Windows, SysUtils, Messages, Forms, SyncObjs,
  InterfacesU, PublisherU, GlobalU, PGPClassU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TPGPCheckAction = (pca_nothing, pca_checksignature, pca_receivepublickey);

  TPGPCheck = class
  private

    PacketConnection: IConnectionForModule;
    Stream: TMemoryStream;
    PGP: TPGP;
    SavePGPStreamEnabled: Boolean;
    Action: TPGPCheckAction;

    procedure   SavePGPStream (SourceStream: TStream);

  public

    constructor Create (aConnectionObj: IConnectionForModule); virtual;
    procedure   BeforeDestruction; override;
    procedure   Receive (S: string); virtual;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  DebOutU, Registry, FolderU, ConfigU, SoundsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TPGPCheck.Create (aConnectionObj: IConnectionForModule);
begin
  inherited Create;
  SavePGPStreamEnabled := false;
  PacketConnection := aConnectionObj;
  Stream := nil;
  PGP := nil;
  Action := pca_nothing;
end;


procedure   TPGPCheck.BeforeDestruction;
begin
  if Assigned (Stream) then begin
    Stream.free;
    Stream := nil;
  end;
  if Assigned (PGP) then begin
    PGP.free;
    PGP := nil;
  end;
  PacketConnection := nil;
  inherited;
end;


procedure   TPGPCheck.Receive (S: string);
const
  MethodName = 'Receive';

resourcestring
  SNoAutoAddPublicKey = 'Das automatische Hinzufügen von öffentlichen Schlüsseln zum Schlüsselbund ist ausgeschaltet.';
  SPGPMessageTooBig = 'PGP-signierte Nachricht zu groß.';

var
  L: Integer;
  T: string;

begin

  L := Length (S);

  if (not assigned (Stream)) then begin

    if (L >= 30) and (S[1] = '-') and (S[2] = '-') and (S[L] = #13) then begin

      if (copy (S, 1, 34) = '-----BEGIN PGP SIGNED MESSAGE-----') then begin
        Action := pca_checksignature;
      end else if (copy (S, 1, 36) = '-----BEGIN PGP PUBLIC KEY BLOCK-----') then begin
        Action := pca_receivepublickey;
      end else begin
        Action := pca_nothing;
      end;

      if (Action <> pca_nothing) then begin

        try
          PGP := TPGP.create;
        except
          PGP := nil;
        end;

        if Assigned (PGP) then begin
          Stream := TMemoryStream.create;
          Stream.write (S[1], L);
        end;

      end;

    end;

  end else begin

    if (L >= 1) then begin

      Stream.write (S[1], L);

      if (S[L] = #13) and
         ((copy (S, 1, 27) = '-----END PGP SIGNATURE-----') or (copy (S, 1, 34) = '-----END PGP PUBLIC KEY BLOCK-----')) then begin

        S := #0;
        Stream.write (S[1], 1);

        if (SavePGPStreamEnabled) then SavePGPStream (Stream);

        try

          case Action of

            pca_checksignature: begin
              T := PGP.CheckSignature (Stream.Memory, Stream.Size);
            end;

            pca_receivepublickey: begin
              if (Config.PGPCollectPublicKeys) then begin
                T := PGP.CheckSignature (Stream.Memory, Stream.Size);
              end else begin
                T := SNoAutoAddPublicKey;
                T := WrapTextUlf (T, #13, [], 72 - Length (RemotePrompt));
              end;
            end;

          end;

        except
          on E: Exception do begin
            T := 'PGP Fehler: "' + E.Message + '"';
            DebOut (self, MethodName, E.Message);
          end;
        end;

        PacketConnection.ChannelPrompt (T, dt_pgp);

        Stream.free;
        Stream := nil;

        PGP.free;
        PGP := nil;

      end else if (Stream.Size > $100000) then begin

        PacketConnection.ChannelPrompt (SPGPMessageTooBig, dt_pgp);

        Stream.free;
        Stream := nil;

        PGP.free;
        PGP := nil;

      end;

    end;

  end;

end;


procedure   TPGPCheck.SavePGPStream (SourceStream: TStream);
const
  MethodName = 'SavePGPStream';
var
  S: String;
  FS: TFileStream;
begin
  DebOut (self, MethodName, 'begin...');
  S := Format ('%sPGPCheck-%8.8x-%8.8x.txt.asc', [Folders.Reception, GetCurrentThreadID, GetTickCount]);
  DebOut (self, MethodName, 'FileNameStr = %s', [S]);
  FS := TFileStream.create (S, fmCreate);
  try
    FS.CopyFrom (SourceStream, 0);
  finally
    FS.free;
  end;
  DebOut (self, MethodName, 'end.');
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

