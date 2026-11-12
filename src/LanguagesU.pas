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


unit LanguagesU;


interface


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


uses
  Windows, Messages, SysUtils, Classes, Controls, Forms,
  StdCtrls, ComCtrls;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TLanguageList = class
  private
    class function  CheckVersion (Language: String): Boolean;
  public
    class function  SelectLanguage (RestartWarning: Boolean): String;
    class procedure LoadResourceModule;
    class function  GetFriendlyName (Language: String): String;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  Registry, LanguagesFormU, LanguagesRestartFormU, LanguagesVersionFormU, GlobalU, DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  ValueName = 'Language';
  RootRegKey = '\Software\Ulf Haueisen\Paxon';

type
  TLanguagesEntry = record
    LanguageCode: String;
    Name: String;
  end;

const
  LanguageNames: array[1..4] of TLanguagesEntry =
    ((LanguageCode: 'DE'; Name: 'Deutsch'),
     (LanguageCode: 'EN'; Name: 'English'),
     (LanguageCode: 'FR'; Name: 'Français'),
     (LanguageCode: 'ES'; Name: 'Español'));


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


class function  TLanguageList.SelectLanguage (RestartWarning: Boolean): String;
var
  LanguagesForm: TLanguagesForm;
  OldLanguage: String;


  function AddItem (Language: String): TListItem;
  var
    S: String;
  begin
    assert (Language <> '');
    result := LanguagesForm.ListView.Items.Add;
    S := GetFriendlyName (Language);
    assert (S <> '');
    result.Caption := S;
    result.Data := StrNew (PChar(Language));
    if (CompareText (OldLanguage, Language) = 0) then begin
      result.Selected := true;
      result.Focused := true;
    end;
  end;


  procedure ClearItems;
  var
    LI: TListItem;
    I: Integer;
  begin
    for I := 0 to LanguagesForm.ListView.Items.Count - 1 do begin
      LI := LanguagesForm.ListView.Items[I];
      StrDispose (LI.Data);
    end;
    LanguagesForm.ListView.Items.Clear;
  end;


var
  S, T, U: String;
  SR: TSearchRec;
  I, L: Integer;
  Registry: TRegistry;

begin

  result := '';

  Registry := TRegistry.create (KEY_READ or KEY_WRITE);
  try

    Registry.RootKey := HKEY_CURRENT_USER;
    Registry.OpenKey (RootRegKey, true);

    LanguagesForm := TLanguagesForm.create (nil);
    try

      OldLanguage := Registry.ReadString (ValueName);

      AddItem ('DE');
      S := ChangeFileExt (Application.ExeName, '-*.pxl');
      U := ExtractFileName (S);
      L := Pos ('*', U);
      I := FindFirst (S, faReadOnly or faHidden or faSysFile or faArchive, SR);
      while (I = 0) do begin
        T := ChangeFileExt (Copy (SR.Name, L, MaxInt), '');
        AddItem (T);
        I := FindNext (SR);
      end;
      FindClose (SR);

      LanguagesForm.ListViewChange (nil, nil, ctState);

      if (LanguagesForm.ShowModal = mrOk) then begin

        T := StrPas (LanguagesForm.ListView.Selected.Data);
        Registry.WriteString (ValueName, T);
        result := T;

        if (RestartWarning) and (T <> OldLanguage) then begin
          with TLanguagesRestartForm.create (LanguagesForm) do begin
            ShowModal;
            Release;
          end;
        end;

      end;

      ClearItems;

    finally
      LanguagesForm.free;
    end;

    Registry.CloseKey;

  finally
    Registry.free;
  end;

end;


class function  TLanguageList.GetFriendlyName (Language: String): String;
var
  I: Integer;
begin
  Language := UpperCase (Language);
  result := '';
  for I := Low (LanguageNames) to High (LanguageNames) do begin
    if (Language = LanguageNames[I].LanguageCode) then begin
      result := LanguageNames[I].Name;
      break;
    end;
  end;
  if (result = '') then begin
    result := Format ('unknown (%s)', [Language]);
  end;
end;


class function  TLanguageList.CheckVersion (Language: String): Boolean;
var
  B, P: PChar;
  L: integer;
  FN1, FN2: String;
  V1L, V1H, V2L, V2H: DWord;

begin

  FN1 := Application.ExeName;
  FN2 := ChangeFileExt (FN1, Format ('-%s.pxl', [Language]));

  GetMem (B, 4096);
  try

    V1L := 0;
    V1H := 1;
    V2L := 0;
    V2H := 2;

    if (GetFileVersionInfo (PChar(FN1), 0, 4096, B)) then begin
      VerQueryValue (B, '\', Pointer(P), Cardinal(L));
      V1L := PVSFixedFileInfo(P)^.dwFileVersionLS;
      V1H := PVSFixedFileInfo(P)^.dwFileVersionMS;
    end;

    if (GetFileVersionInfo (PChar(FN2), 0, 4096, B)) then begin
      VerQueryValue (B, '\', Pointer(P), Cardinal(L));
      V2L := PVSFixedFileInfo(P)^.dwFileVersionLS;
      V2H := PVSFixedFileInfo(P)^.dwFileVersionMS;
    end;

    result := (V1H = V2H) and (V1L = V2L);

  finally
    FreeMem (B);
  end;

end;


class procedure TLanguageList.LoadResourceModule;
var
  FileName: String;
  NewInst: Longint;
  CurModule: PLibModule;
  Locale: LCID;
  Language: String;
  Registry: TRegistry;

begin

  Registry := TRegistry.create (KEY_READ or KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    Registry.OpenKey (RootRegKey, true);
    Language := Registry.ReadString (ValueName);
  finally
    Registry.free;
  end;

  if (Language = '') then begin
    Locale := GetUserDefaultLCID and $000003FF;
    if (Locale = LANG_GERMAN) then begin
      Language := 'DE';
    end else if (Locale = LANG_ENGLISH) then begin
      Language := 'EN';
    end else begin
      Language := SelectLanguage (false);
    end;
  end;

  if (Language = 'DE') then Language := '';

  if (Language <> '') then begin

    if (CheckVersion (Language)) then begin

      FileName := ChangeFileExt (Application.ExeName, Format ('-%s.pxl', [UpperCase (Language)]));

      NewInst := LoadLibraryEx (PChar(FileName), 0, 0);

      if (NewInst <> 0) then begin

        CurModule := LibModuleList;
        while (CurModule <> nil) do begin
          if (CurModule.Instance = HInstance) then begin
            if (CurModule.ResInstance <> CurModule.Instance) then FreeLibrary (CurModule.ResInstance);
            CurModule.ResInstance := NewInst;
            break;
          end;
          CurModule := CurModule.Next;
        end;

      end;

    end else begin

      with TLanguagesVersionForm.create (nil) do begin
        try
          try
            ShowModal;
          except
          end;
        finally
          Release;
        end;
      end;

    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  DebOut ('LanguagesU.initialization: begin...');
  try
    TLanguageList.LoadResourceModule;
  except
  end;
  DebOut ('LanguagesU.initialization: end.');

finalization


end.

