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


unit PGPClassU;


interface


uses
  Windows, PGPApiU, Classes, InterfacesU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TPGP = class
  private

    FLoaded: boolean;
    FVersion: string;
    Context: pPGPContext;
    DefaultKeyset: pPGPKeyset;
    FCheckResult: string;
    MyThreadID: Cardinal;
    FCallbackException: TObject;

    function    EventHandler (context: pPGPContext; event: pPGPEvent): PGPError;
    function    CallbackResult (aResult: PGPError): PGPError;
    procedure   DoCheckSignature (Data: PChar; Len: Integer);
    procedure   SignatureEvent (SignatureData: TPGPEventSignatureData);

  public

    constructor create;
    destructor  Destroy; override;
    property    Version: string read FVersion write FVersion;
    function    GetPrivateKeys (SL: TStrings): Integer;
    function    Sign (aKey: pPGPKey; aPassPhrase: string; aComment: string; Source: PChar; SourceSize: Cardinal; Dest: PChar;
                      DestSize: Cardinal): Integer;
    function    CheckPassword (aKey: pPGPKey; aPassPhrase: string): Boolean;
    function    CheckSignature (Data: PChar; Len: Integer): string;

  end;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, SysUtils, Dialogs, GlobalU, ConfigU, SoundsU, SoundsConstsU,
  UnhandledExceptionU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  EPGP = class (Exception);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TPGP.create;
const
  MethodName = 'create';

var
  V: PGPString;
  LoadError: PGPError;

begin

  inherited create;

  MyThreadID := GetCurrentThreadID;

  if (not PGPDLLLoaded) then begin
    if (Length (PGPDLLError) > 0) then begin
      raise EPGP.create ('PGP DLL not loaded: ' + PGPDLLError);
    end else begin
      raise EPGP.create ('PGP DLL not loaded');
    end;
  end else begin
    LoadError := PGPsdkInit;
    if (LoadError <> kPGPError_NoError) then begin
      raise EPGP.create (PGPErrorMsg (LoadError));
    end;
  end;

  FLoaded := true;

  PGPCheckResult (PGPGetSDKString (V), 'Loading Version');
  FVersion := V;
  DebOut (self, MethodName, FVersion);

  PGPCheckResult (PGPNewContext (kPGPsdkAPIVersion, Context), 'Getting Context');

  PGPCheckResult (PGPOpenDefaultKeyRings (Context, 0, DefaultKeyset), 'Opening Default-Keyring');

end;


destructor  TPGP.destroy;
const
  MethodName = 'destroy';

begin

  assert (MyThreadID = GetCurrentThreadID);

  DebOut (self, MethodName, 'begin...');

  if (FLoaded) then begin
    try
      PGPFreeKeyset (DefaultKeyset);
      PGPFreeContext (Context);
      PGPsdkCleanup;
    except
    end;
  end;

  FCallbackException.free;
  FCallbackException := nil;

  inherited;

  DebOut (self, MethodName, 'end.');

end;


function    TPGP.GetPrivateKeys (SL: TStrings): Integer;
const
  MethodName = 'GetPrivateKeys';

var
  keyList: pPGPKeyList;
  iter: pPGPKeyIter;
  n: PGPUInt32;
  E: PGPError;
  Key, DefaultKey: pPGPKey;
  T, S: string;
  I, Q: Cardinal;
  M: Integer;
  B: Byte;

begin

  assert (MyThreadID = GetCurrentThreadID);

  result := -1;

  try

    SL.Clear;

    PGPCheckResult (PGPCountKeys (DefaultKeyset, N), 'PGPCountKeys');
    DebOut (self, MethodName, 'PGPCountKeys = ' + IntToStr (N));

    if (N >= 1) then begin

      result := 0;

      if (PGPGetDefaultPrivateKey (DefaultKeyset, DefaultKey) <> kPGPError_NoError) then DefaultKey := nil;

      PGPCheckResult (PGPOrderKeyset (DefaultKeyset, kPGPAnyOrdering, KeyList), 'PGPOrderKeyset');

      // Fehler zwischen dem Anlegen und dem Freigeben von KeyList und Iter
      // dürfen keine Ausnahme werfen, sonst blieben beide belegt.
      E := PGPNewKeyIter (Keylist, Iter);
      if (E <> kPGPError_NoError) then begin
        PGPFreeKeyList (KeyList);
        PGPCheckResult (E, 'PGPNewKeyIter');
      end;

      while true do begin

        E := PGPKeyIterNext (Iter, Key);


        if (E <> kPGPError_NoError) or (not assigned (Key)) then break;

        // Einen Schlüssel, dessen Eigenschaften nicht lesbar sind, überspringen
        if (PGPGetKeyBoolean (Key, kPGPKeyPropIsSecret, B) <> kPGPError_NoError) then continue;

        M := 0;
        if (PGPGetKeyNumber (Key, kPGPKeyPropAlgID, M) <> kPGPError_NoError) then M := 0;

        if B <> 0 then begin

          SetLength (S, 512);
          FillChar (S[1], 512, 0);
          PGPGetPrimaryUserIDNameBuffer (Key, 512, PChar(S), Q);
          SetLength (S, StrLen(PChar(S)));

          case M of
            kPGPPublicKeyAlgorithm_RSA: T := 'RSA';
            kPGPPublicKeyAlgorithm_ElGamal: T := 'ElGamal';
            kPGPPublicKeyAlgorithm_DSA: T := 'DH/DSS';
            else T := IntToStr(M) + '?';
          end;

          S := S + ' [' + T + ']';

          I := SL.Add (S);
          SL.Objects[I] := Key;
          if (Key = DefaultKey) then begin
            result := I;
          end;

        end;

      end;

      PGPCheckResult (PGPFreeKeyIter (iter), 'PGPFreeKeyIter');

      PGPCheckResult (PGPFreeKeyList (keylist), 'PGPFreeKeyList');

    end;

  except
    on E: Exception do begin
      ShowUnhandledException (E, ClassName, MethodName);
      SL.Clear;
    end;
  end;

end;


function    TPGP.EventHandler (context: pPGPContext; event: pPGPEvent): PGPError;
const
  MethodName = 'EventHandler';

begin

  assert (MyThreadID = GetCurrentThreadID);

  DebOut (self, MethodName, PGPDescribeEvent (event^.etype) + #13);

  result := kPGPError_NoError;

  case (event^.etype) of

    kPGPEvent_SignatureEvent: begin
      SignatureEvent (event^.data.signatureData);
    end;

    kPGPEvent_ErrorEvent: begin
      DebOut (self, MethodName, 'ERROR: ' + PGPErrorMsg (event^.data.errorData.error));
    end;

    kPGPEvent_WarningEvent: begin
      DebOut (self, MethodName, 'WARNING: ' + PGPErrorMsg (event^.data.warningData.warning));
    end;

  end;

end;


function    MyEventHandler (context: pPGPContext; event: pPGPEvent; UserValue: PGPUserValue): PGPError; cdecl;
var
  PGP: TPGP;
  E: TObject;
begin
  PGP := TPGP(UserValue);
  try
    assert (PGP.MyThreadID = GetCurrentThreadID);
    result := PGP.EventHandler(Context, event);
  except
    // Do not let a Delphi exception run through the stack frames of the PGP DLL:
    // remember it, report an error to the SDK and re-raise it in CallbackResult
    // after returning from the SDK function.
    E := TObject (AcquireExceptionObject);
    if (assigned (PGP.FCallbackException)) then begin
      E.free;
    end else begin
      PGP.FCallbackException := E;
    end;
    result := kPGPError_UserAbort;
  end;
end;


function    TPGP.CallbackResult (aResult: PGPError): PGPError;
var
  E: TObject;
begin
  // Call after PGPEncode/PGPDecode: re-raise an exception caught in the callback
  // now (in Delphi code), otherwise pass the result through.
  E := FCallbackException;
  if (assigned (E)) then begin
    FCallbackException := nil;
    raise E;
  end;
  result := aResult;
end;


procedure   TPGP.SignatureEvent (SignatureData: TPGPEventSignatureData);
const
  MethodName = 'SignatureEvent';

resourcestring
  SSignatureNotChecked = 'Die Unterschrift wurde nicht überprüft.';
  SUnknownKey = 'Unbekannt (ID=%s)';
  SValidityUnknown = 'Die Echtheit des Unterzeichnerschlüssels ist unbekannt.';
  SSignatureVerified = 'Die Unterschrift ist gültig.';
  SSignatureNotVerified = 'Die Unterschrift ist ungültig, die Nachricht wurde verändert.';
  SCreationTime = '"Unterzeichnet am" dd.mm.yyyy "um" hh:nn:ss "utc."';
  SKeyRevoked = 'Der Schlüssel wurde zurückgezogen.';
  SKeyDisabled = 'Der Schlüssel wurde deaktiviert.';
  SKeyExpired = 'Der Schlüssel ist abgelaufen.';
  SSigner = 'Unterzeichner:';

type
  PPGPChar = ^PGPChar;

var
  S, T: string;
  N: Cardinal;
  P: PPGPChar;
  DT: TDateTime;
  Y, M, D: Word;
  Details: Boolean;

begin

  Details := Config.PGPDetailedOutput;

  if (Details) then begin
    T := 'Signer: ';
  end else begin
    T := SSigner + ' ';
  end;

  FCheckResult := T;
  if (not assigned (SignatureData.SigningKey)) then begin
    SetLength (S, kPGPMaxKeyIDStringSize);
    P := Pointer (PChar(S));
    PGPGetKeyIDString (SignatureData.signingKeyID, kPGPKeyIDString_Abbreviated, P^);
    SetLength (S, StrLen(PChar(S)));
    if (Details) then begin
      S := Format ('Unknown, ID=%s', [S]);
    end else begin
      S := Format (SUnknownKey, [S]);
    end;
  end else begin
    SetLength (S, 512);
    FillChar (S[1], 512, 0);
    PGPCheckResult (PGPGetPrimaryUserIDNameBuffer (SignatureData.signingKey, 512, PChar(S), N), 'examining key');
    SetLength (S, StrLen(PChar(S)));
    S := '"' + S + '"';
  end;
  assert (Length (T) > 0);
  FillChar (T[1], Length (T), ' ');
  T := T + ' ';
  FCheckResult := FCheckResult + WrapTextUlf (S, #13 + T, ['.', ' ', #9, '-', '@', ','], 72 - Length (RemotePrompt) - Length (T)) +
                  #13;

  if (Details) or (SignatureData.Checked = PGPTrue) then begin

    if (Details) then begin
      FCheckResult := FCheckResult + 'Checked: ';
      if (SignatureData.Checked = PGPTrue) then FCheckResult := FCheckResult + 'true' else FCheckResult := FCheckResult + 'false';
      FCheckResult := FCheckResult + '.'#13;
    end;

    if (Details) then begin
      FCheckResult := FCheckResult + 'Verified: ';
      if (SignatureData.Verified = PGPTrue) then FCheckResult := FCheckResult + 'true' else FCheckResult := FCheckResult + 'false';
      FCheckResult := FCheckResult + '.'#13;
    end;

    if (Details) then begin
      FCheckResult := FCheckResult + 'KeyValidity: ';
      case SignatureData.KeyValidity of
        kPGPValidity_Unknown: FCheckResult := FCheckResult + 'unknown';
        kPGPValidity_Invalid: FCheckResult := FCheckResult + 'invalid';
        kPGPValidity_Marginal: FCheckResult := FCheckResult + 'marginal';
        kPGPValidity_Complete: FCheckResult := FCheckResult + 'complete';
        else FCheckResult := FCheckResult + '???';
      end;
      FCheckResult := FCheckResult + '.'#13;
    end else begin
      if (SignatureData.KeyValidity < kPGPValidity_Marginal) then begin
        FCheckResult := FCheckResult + SValidityUnknown + #13;
      end;
    end;

    if (not Details) then begin
      if (SignatureData.Verified = PGPTrue) then begin
        FCheckResult := FCheckResult + SSignatureVerified;
      end else begin
        FCheckResult := FCheckResult + SSignatureNotVerified;
      end;
      FCheckResult := FCheckResult + #13;
    end;

    PGPGetYMDFromPGPTime (SignatureData.creationTime, Y, M, D);
    try
      DT := UnixTimeToDateTime (PGPGetStdTimeFromPGPTime (SignatureData.creationTime));
      if (DT >= 0) then begin
        if (Details) then begin
          S := FormatDateTime ('"Date/Time: "yyyy-mm-dd hh:nn:ss" utc."', DT);
        end else begin
          S := FormatDateTime (SCreationTime, DT);
        end;
        FCheckResult := FCheckResult + S + #13;
      end;
    except
    end;

    if (Details) then begin
      FCheckResult := FCheckResult + 'KeyRevoked: ';
      if (SignatureData.KeyRevoked = PGPTrue) then
        FCheckResult := FCheckResult + 'true'
      else
        FCheckResult := FCheckResult + 'false';
      FCheckResult := FCheckResult + '.'#13;
    end else begin
      if (SignatureData.KeyRevoked = PGPTrue) then begin
        FCheckResult := FCheckResult + SKeyRevoked + #13;
      end;
    end;

    if (Details) then begin
      FCheckResult := FCheckResult + 'KeyDisabled: ';
      if (SignatureData.KeyDisabled = PGPTrue) then
        FCheckResult := FCheckResult + 'true'
      else
        FCheckResult := FCheckResult + 'false';
      FCheckResult := FCheckResult + '.'#13;
    end else begin
      if (SignatureData.KeyDisabled = PGPTrue) then begin
        FCheckResult := FCheckResult + SKeyDisabled + #13;
      end;
    end;

    if (Details) then begin
      FCheckResult := FCheckResult + 'KeyExpired: ';
      if (SignatureData.KeyExpired = PGPTrue) then
        FCheckResult := FCheckResult + 'true'
      else
        FCheckResult := FCheckResult + 'false';
      FCheckResult := FCheckResult + '.'#13;
    end else begin
      if (SignatureData.KeyExpired = PGPTrue) then begin
        FCheckResult := FCheckResult + SKeyExpired + #13;
      end;
    end;

  end else begin

    FCheckResult := FCheckResult + SSignatureNotChecked + #13;

  end;

  // Nicht geprüft (Schlüssel unbekannt) ist nicht "falsch": Der Text meldet
  // dann "nicht überprüft", der Klang darf nicht "ungültig" melden.
  if (SignatureData.Checked <> PGPTrue) then begin
    Sounds.PlayEvent (se_pgp_unknown, nil);
  end else if (SignatureData.Verified = PGPTrue) then begin
    // A revoked, disabled or expired key does not make the signature valid (the text says so)
    if (assigned (SignatureData.SigningKey)) and (SignatureData.KeyValidity >= kPGPValidity_Marginal) and
       (SignatureData.KeyRevoked <> PGPTrue) and (SignatureData.KeyDisabled <> PGPTrue) and
       (SignatureData.KeyExpired <> PGPTrue) then begin
      Sounds.PlayEvent (se_pgp_valid, nil);
    end else begin
      Sounds.PlayEvent (se_pgp_unknown, nil);
    end;
  end else begin
    Sounds.PlayEvent (se_pgp_wrong, nil);
  end;

end;


function    TPGP.Sign (aKey: pPGPKey; aPassPhrase: string; aComment: string; Source: PChar; SourceSize: Cardinal; Dest: PChar;
                       DestSize: Cardinal): Integer;
var
  sop, gop: pPGPOptionsList;
  PComment: PChar;

begin

  assert (MyThreadID = GetCurrentThreadID);

  Result := 0;

  if (Length (aComment) > 0) then PComment := PChar(aComment) else PComment := PChar('');

  PGPCheckResult (PGPBuildOptionList(Context, sop,
    [
    PGPOClearSign(Context, PGPTrue),
    PGPOSignWithKey(Context, aKey, [PGPOPassphrase(Context, PChar(aPassPhrase))])
    ]
    ), 'building Signing Options');
  try

    PGPCheckResult (PGPBuildOptionList(Context, gop,
      [
      PGPOInputBuffer (Context, Source, SourceSize),
      PGPOOutputBuffer (Context, Dest, DestSize, Cardinal(Result)),
      PGPOOutputLineEndType (Context, kPGPLineEnd_CR),
      PGPODataIsASCII (Context, PGPTrue),
      PGPOVersionString (Context, PChar(ApplicationName + ' ' + GlobalU.Version)),
      PGPOCommentString (Context, PComment),
      PGPOEventHandler (Context, MyEventHandler, self)
      ]
      ), 'bulding General Options');
    try
      PGPCheckResult (CallbackResult (PGPEncode (Context, [gop, sop])), 'Encoding');
    finally
      PGPCheckResult (PGPFreeOptionList (gop), 'Freeing Encoding Options 1');
    end;

  finally
    PGPCheckResult (PGPFreeOptionList (sop), 'Freeing Encoding Options 3');
  end;

end;


function    TPGP.CheckPassword (aKey: pPGPKey; aPassPhrase: string): Boolean;
var
  sop, gop: pPGPOptionsList;
  S: array[0..7] of char;

begin

  assert (MyThreadID = GetCurrentThreadID);

  Result := false;
  S := 'a'#0;
  try
    PGPCheckResult (PGPBuildOptionList(Context, sop,
      [
      PGPOClearSign (Context, PGPTrue),
      PGPOSignWithKey (Context, aKey, [PGPOPassphrase(Context, PChar(aPassPhrase))])
      ]
      ), 'building Signing Options');
    try
      PGPCheckResult (PGPBuildOptionList(Context, gop,
        [
        PGPOInputBuffer (Context, @S, 1),
        PGPODiscardOutput (Context, PGPTrue),
        PGPODataIsASCII (Context, PGPTrue),
        PGPOEventHandler (Context, MyEventHandler, self)
        ]
        ), 'bulding General Options');
      try
        PGPCheckResult (CallbackResult (PGPEncode (Context, [gop, sop])), 'Encoding');
        Result := true;
      finally
        PGPCheckResult (PGPFreeOptionList(gop), 'Freeing Encoding Options 1');
      end;
    finally
      PGPCheckResult (PGPFreeOptionList(sop), 'Freeing Encoding Options 3');
    end;
  except
  end;
end;


function    TPGP.CheckSignature (Data: PChar; Len: Integer): string;
begin
  // Actual work in a procedure: otherwise Delphi 7 wrongly reports W1035
  // (return value undefined) for this function.
  DoCheckSignature (Data, Len);
  Result := FCheckResult;
end;


procedure   TPGP.DoCheckSignature (Data: PChar; Len: Integer);
resourcestring
  SShareError = 'Die Schlüssel können nicht zum Schlüsselbund hinzugefügt werden,'#13
              + 'da eine andere Anwendung (z.B. PGPKeys) auf diesen zugreift.';
  SKeysAdded = 'Folgende Schlüssel wurden dem Schlüsselring hinzugefügt:';
  SKeysNotAdded = 'Die Nachricht enthält öffentliche Schlüssel. Sie wurden nicht'#13
                + 'zum Schlüsselbund hinzugefügt, da das automatische Hinzufügen'#13
                + 'ausgeschaltet ist.';

const
  MethodName = 'CheckSignature';

var
  Options: pPGPOptionsList;
  Dest: string;
  N: Cardinal;
  NewKeyset: pPGPKeyset;
  DefaultKeysetWriteable: pPGPKeyset;
  keyList: pPGPKeyList;
  iter: pPGPKeyIter;
  E: PGPError;
  Key: pPGPKey;
  S: string;
  Q: Cardinal;
  HasError: Boolean;

begin

  assert (MyThreadID = GetCurrentThreadID);

  FCheckResult := '';

  if (Len > 0) then begin

    SetLength (Dest, Len + $FFFF);
    FillChar (Dest[1], Len + $FFFF, 0);

    PGPCheckResult (PGPNewKeyset (Context, NewKeyset), 'PGPNewKeyset');

    try

      PGPCheckResult (PGPBuildOptionList (Context, Options,
        [
        PGPOInputBuffer (Context, Data, Len),
        PGPOOutputBuffer (Context, PChar(Dest), Len + $FFFF, N),
        PGPOOutputLineEndType (Context, kPGPLineEnd_CR),
        PGPOEventHandler (Context, MyEventHandler, self),
        PGPOImportKeysTo (Context, NewKeyset),
        PGPOKeysetRef (Context, DefaultKeyset)
        ]
        ), 'building decoding Options');

      try

        PGPCheckResult (CallbackResult (PGPDecode (Context, [Options])), 'Decoding');

        SetLength (Dest, N);

        PGPCheckResult (PGPCountKeys (NewKeyset, N), 'PGPCountKeys');

        if (N > 0) and (not Config.PGPCollectPublicKeys) then begin

          // "Schlüssel sammeln" (collect keys) is switched off: do not add embedded keys (also from
          // signed messages) to the keyring.
          FCheckResult := FCheckResult + SKeysNotAdded;

        end else if (N > 0) then begin

          HasError := true;

          E := PGPOpenDefaultKeyRings (Context, kPGPKeyRingOpenFlags_Mutable, DefaultKeysetWriteable);

          if (E <> kPGPError_NoError) then begin

            DebOut (self, MethodName, 'FEHLER: PGPOpenDefaultKeyRings (Mutable): ' + PGPErrorMsg (E));

          end else begin

            try

              E := PGPAddKeys (NewKeyset, DefaultKeysetWriteable);

              if (E <> kPGPError_NoError) then begin

                DebOut (self, MethodName, 'FEHLER: PGPAddKeys: ' + PGPErrorMsg (E));

              end else begin

                E := PGPCommitKeyRingChanges (DefaultKeysetWriteable);

                if (E <> kPGPError_NoError) then begin

                  DebOut (self, MethodName, 'FEHLER: PGPCommitKeyRingChanges: ' + PGPErrorMsg (E));

                end else begin

                  PGPCheckResult (PGPOrderKeyset (NewKeyset, kPGPAnyOrdering, KeyList), 'PGPOrderKeyset');

                  E := PGPNewKeyIter (Keylist, Iter);
                  if (E <> kPGPError_NoError) then begin
                    PGPFreeKeyList (KeyList);
                    PGPCheckResult (E, 'PGPNewKeyIter');
                  end;

                  FCheckResult := FCheckResult + SKeysAdded + #13;

                  while true do begin

                    E := PGPKeyIterNext (Iter, Key);

                    if (E <> kPGPError_NoError) or (not assigned (Key)) then break;

                    SetLength (S, 512);
                    FillChar (S[1], 512, 0);
                    PGPGetPrimaryUserIDNameBuffer (Key, 512, PChar(S), Q);
                    SetLength (S, StrLen(PChar(S)));

                    FCheckResult := FCheckResult + '"' + S + '"'#13;

                  end;

                  PGPCheckResult (PGPFreeKeyIter (iter), 'PGPFreeKeyIter');

                  PGPCheckResult (PGPFreeKeyList (keylist), 'PGPFreeKeyList');

                  HasError := false;

                end;

              end;

            finally

              PGPCheckResult (PGPFreeKeyset (DefaultKeysetWriteable), 'Closing Default-Keyring');

            end;

          end;

          if (HasError) then begin
            FCheckResult := FCheckResult + SShareError;
          end;

        end;

      finally

        PGPCheckResult (PGPFreeOptionList (Options), 'Freeing Decoding Options');

      end;

    finally

      PGPCheckResult (PGPFreeKeyset (NewKeyset), 'PGPFreeKeyset');

    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

