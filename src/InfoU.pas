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


unit InfoU;


interface


uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls, StdCtrls, ExtCtrls,
  GlobalU, InterfacesU, ComCtrls, ToolWin,
  Forms, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TDlgInfo = class (TFormUlf)

    Panel1: TPanel;
    Panel2: TPanel;
    ImageTitle: TImage;
    TextLine2: TLabel;
    Label2: TLabel;

    procedure   FormCreate (Sender: TObject);
    procedure   FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure   FormMouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure   FormMouseMove (Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure   FormMouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

  private

    CanMove: Boolean;
    OldX, OldY: Integer;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  JPEG;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDlgInfo.FormCreate (Sender: TObject);
var
  ResStream: TResourceStream;
  JPEG: TJPEGImage;

begin

  TextLine2.Font.Style := [fsBold];
  TextLine2.Caption := 'Version ' + Version;

  ResStream := TResourceStream.Create (HInstance, 'Logo', RT_RCDATA);
  try
    JPEG := TJPEGImage.Create;
    try
      JPEG.LoadFromStream (ResStream);
      ImageTitle.Picture.Graphic := JPEG;
    finally
      JPEG.Free;
    end;
  finally
    ResStream.Free;
  end;

end;


procedure   TDlgInfo.FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Shift = []) and ((Key = vk_escape) or (Key = vk_return) or (Key = 32)) then begin
    Key := 0;
    Shift := [];
    Close;
  end;
end;


procedure   TDlgInfo.FormMouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if (Button = mbLeft) then begin
    P := (Sender as TControl).ClientToScreen (Point (X, Y));
    P := ScreenToClient (P);
    if (P.Y < GetSystemMetrics (SM_CYCAPTION) - 2) then begin
      CanMove := true;
      OldX := X;
      OldY := Y;
    end;
  end;
end;


procedure   TDlgInfo.FormMouseMove (Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (CanMove) then begin
    Top := Top + (Y - OldY);
    Left := Left + (X - OldX);
  end;
end;


procedure   TDlgInfo.FormMouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then begin
    if (not CanMove) and (X >= 0) and (Y >= 0) and (X < Width) and (Y < Height) then Close;
    CanMove := false;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

