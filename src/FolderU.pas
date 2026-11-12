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


unit FolderU;


interface


uses
  Classes, Windows, SysUtils, Messages,
  Forms, Registry, StrUtils,
  InterfacesU, GlobalU, DebOutU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TFileEntry = record
    Name: String;
    Time: TDateTime;
    Size: Integer;
    Attr: Integer;
  end;

  TFileEntryArray = array of TFileEntry;


  TFolder = class
  private

    Registry: TRegistry;

    function    GetReception: String;
    procedure   SetReception (aPath: String);
    function    DataText: String;
    function    GetRemote: String;
    procedure   SetRemote (aPath: String);

  public

    constructor Create;
    destructor  Destroy; override;
    property    Reception: string read GetReception write SetReception;
    property    Remote: string read GetRemote write SetRemote;
    function    FindRemoteFiles (const Params: String; const UseAutoWildcards: Boolean; var Files: TFileEntryArray;
                                 var aFolder: String; var Wildcard: String):Boolean;

  end;


var
  Folders: TFolder;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TFolder.Create;
begin
  inherited;
  Registry := TRegistry.create (KEY_READ or KEY_WRITE);
  Registry.RootKey := HKEY_CURRENT_USER;
  Registry.OpenKey (RootRegKey + '\Folders', true);
end;


destructor  TFolder.Destroy;
begin
  Registry.CloseKey;
  Registry.free;
  inherited;
end;


function    TFolder.GetReception: String;
begin
  assert (assigned (Registry));
  try
    result := Registry.ReadString ('Receive');
  except
    result := '';
  end;
  if (result = '') then result := DataText;
  result := IncludeTrailingPathDelimiter (result);
end;


procedure   TFolder.SetRemote (aPath: String);
begin
  Registry.WriteString ('Remote', aPath);
end;


function    TFolder.GetRemote: String;
begin
  assert (assigned (Registry));
  try
    result := Registry.ReadString ('Remote');
  except
    result := '';
  end;
  if (result = '') then result := DataText + 'Paxon';
  result := IncludeTrailingPathDelimiter (result);
end;


procedure   TFolder.SetReception (aPath: String);
begin
  Registry.WriteString ('Receive', aPath);
end;


function    TFolder.DataText: String;
var
  R: TRegistry;
begin
  R := TRegistry.create (KEY_READ or KEY_WRITE);
  R.RootKey := HKEY_CURRENT_USER;
  result := '';
  if R.OpenKey ('Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', false) then begin
    try
      result := R.ReadString ('Personal');
    except
      result := '';
    end;
  end;
  result := IncludeTrailingPathDelimiter (result);
  R.Free;
end;


function    TFolder.FindRemoteFiles (const Params: String; const UseAutoWildcards: Boolean; var Files: TFileEntryArray;
                                     var aFolder: String; var Wildcard: String): Boolean;
const
  MethodName = 'DirRemote';
  MaxFileCount = 1000;

var
  ParamFolder, Folder: String;
  SR: TSearchRec;
  I, N: Integer;
  S: String;
  RemoteFolder: String;

begin

  SetLength (Files, MaxFileCount);

  RemoteFolder := IncludeTrailingPathDelimiter (ExpandFileName (Folders.Remote));

  if (UseAutoWildcards) then begin
    if (DirectoryExists (RemoteFolder + Params)) then begin
      ParamFolder := IncludeTrailingPathDelimiter (Params);
      Wildcard := '*';
    end else begin
      ParamFolder := IncludeTrailingPathDelimiter (ExtractFilePath (Params));
      Wildcard := ExtractFileName (Params);
      if (Wildcard = '') then Wildcard := '*';
    end;
  end else begin
    ParamFolder := ExcludeTrailingPathDelimiter (Params);
    Wildcard := '';
  end;

  DebOut (self, MethodName, 'Wildcard: %s', [Wildcard]);
  DebOut (self, MethodName, 'Folder (Parameter): %s', [ParamFolder]);

  S := ExpandFileName (RemoteFolder + ParamFolder);

  if (UseAutoWildcards) then begin
    if (DirectoryExists (S)) then begin
      Folder := IncludeTrailingPathDelimiter (S);
    end else begin
      Folder := IncludeTrailingPathDelimiter (ExtractFilePath (S));
    end;
  end else begin
    Folder := ExcludeTrailingPathDelimiter (S);
  end;

  DebOut (self, MethodName, 'Folder (wirklich): %s', [Folder]);

  aFolder := ExcludeTrailingPathDelimiter (ExtractRelativePath (RemoteFolder, IncludeTrailingPathDelimiter (Folder)));

  if (AnsiStartsText (RemoteFolder, IncludeTrailingPathDelimiter (Folder))) then begin

    N := 0;
    I := FindFirst (Folder + Wildcard, faAnyFile, SR);
    try

      while (I = 0) do begin

        // FindFirst returns device names such as NUL or CON with date 0: not a valid
        // timestamp, not a file - do not include (otherwise EConvertError).
        if ((not UseAutoWildcards) or ((SR.Name <> '.') and (SR.Name <> '..'))) and (SR.Time <> 0) then begin

          with Files[N] do begin
            Name := SR.Name;
            try
              Time := FileDateToDateTime (SR.Time);
            except
              on EConvertError do Time := 0;
            end;
            Size := SR.Size;
            Attr := SR.Attr;
          end;

          inc (N);

          if (N >= MaxFileCount) then break;

        end;

        I := FindNext (SR);

      end;

    finally
      FindClose (SR);
    end;

    SetLength (Files, N);

    result := true;

  end else begin

    SetLength (Files, 0);

    result := false;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

