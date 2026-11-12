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


unit FileStreamUlfU;


interface


uses
  Windows, Classes, SysUtils;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TFileStreamUlf = class (TStream)
  private
    FFilename: string;
    FMode: Word;
    FFileStream: TFileStream;
    FIsTemporary: Boolean;
    procedure   SetFilename (const aFilename: string);
    function    GetFilename: string;
    function    GetMode: Word;
    procedure   SetMode (const Value: Word);
    function    GetHandle: THandle;
  public
    constructor create; reintroduce; virtual;
    destructor  Destroy; override;
    property    Filename: string read GetFilename write SetFilename;
    property    Mode: Word read GetMode write SetMode;
    procedure   Open;
    procedure   Close;
    function    Read (var Buffer; Count: Longint): Longint; override;
    function    Write (const Buffer; Count: Longint): Longint; override;
    function    Seek (Offset: Longint; Origin: Word): Longint; override;
    procedure   Delete;
    function    DeleteIfTemporary: Boolean;
    procedure   Recycle;
    procedure   SetSize (NewSize: Longint); override;
    property    IsTemporary: Boolean read FIsTemporary write FIsTemporary;
    property    Handle: THandle read GetHandle;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  GlobalU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TFileStreamUlf.create;
begin
  FFileStream := nil;
  FIsTemporary := false;
  inherited;
end;


destructor  TFileStreamUlf.destroy;
begin
  Close;
  inherited;
end;


function    TFileStreamUlf.GetFilename: string;
begin
  Result := FFilename;
end;


procedure   TFileStreamUlf.SetFilename (const aFileName: string);
begin
  if (not assigned (FFileStream)) then begin
    FFilename := aFileName;
  end else begin
    raise EStreamError.Create ('Not while open');
  end;
end;


function    TFileStreamUlf.GetMode: Word;
begin
  result := FMode;
end;


procedure   TFileStreamUlf.SetMode (const Value: Word);
begin
  if not Assigned (FFileStream) then begin
    FMode := Value;
  end else begin
    raise EStreamError.Create ('Not while open');
  end;
end;


procedure   TFileStreamUlf.Open;
begin
  // Errors on opening (EFOpenError/EFCreateError) go to the caller.
  if (not assigned (FFileStream)) then begin
    FFileStream := TFileStream.create (FFileName, FMode);
  end else begin
    raise EStreamError.Create ('Already open');
  end;
end;


procedure   TFileStreamUlf.Close;
begin
  if (assigned (FFileStream)) then begin
    FFileStream.free;
    FFileStream := nil;
  end;
end;


function    TFileStreamUlf.read (var Buffer; Count: Integer): Longint;
begin
  if assigned (FFileStream) then begin
    result := FFileStream.read (Buffer, Count);
  end else begin
    raise EStreamError.Create ('File not open');
  end;
end;


function    TFileStreamUlf.Seek (Offset: Integer; Origin: Word): Longint;
begin
  if (assigned (FFileStream)) then begin
    result := FFileStream.Seek (Offset, Origin);
  end else begin
    raise EStreamError.Create ('File not open');
  end;
end;


procedure   TFileStreamUlf.SetSize (NewSize: Integer);
begin
  if assigned (FFileStream) then begin
    FFileStream.Size := NewSize;
  end else begin
    raise EStreamError.Create ('File not open');
  end;
end;


function    TFileStreamUlf.write (const Buffer; Count: Integer): Longint;
begin
  if assigned (FFileStream) then begin
    result := FFileStream.write (Buffer, Count);
  end else begin
    raise EStreamError.Create ('File not open');
  end;
end;


procedure   TFileStreamUlf.Delete;
begin
  Close;
  if (not DeleteFile (FFilename)) then begin
    raise EStreamError.Create (GetLastErrorText);
  end;
end;


function    TFileStreamUlf.DeleteIfTemporary: Boolean;
begin
  if (FIsTemporary) then begin
    try
      Delete;
      result := true;
    except
      result := false;
    end;
  end else begin
    result := false;
  end;
end;


function    TFileStreamUlf.GetHandle: THandle;
begin
  if assigned (FFileStream) then begin
    result := FFileStream.Handle;
  end else begin
    result := 0;
  end;
end;


procedure    TFileStreamUlf.Recycle;
begin
  Close;
  if not GlobalU.Recycle (FFilename) then begin
    raise EStreamError.Create ('Cannot recycle');
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

