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


unit SplashU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, StdCtrls, JPEG,
  GlobalU, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TDlgSplash = class (TFormUlf)
    ClientPanel: TPanel;
    VersionLabel: TLabel;
    Image: TImage;
    StatusLabel: TLabel;
    Shape: TShape;
    LabelNotForDistribution: TLabel;
    procedure  FormCreate (Sender: TObject);
    procedure  FormDestroy (Sender: TObject);
  private
    fTimer: TTimer;
    procedure  SetStatus (S: String);
    function   GetStatus: String;
    procedure  TimerTick (Sender: TObject);
  public
    property   Status: string read GetStatus write SetStatus;
    procedure  Ready;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TDlgSplash.FormCreate (Sender: TObject);
var
  ResStream: TResourceStream;
  JPEG: TJPEGImage;

begin

  VersionLabel.Caption := Version;

  // Load the logo; an error here does not matter, but the stream and the JPEG are always freed

  try

    ResStream := TResourceStream.Create (HInstance, 'Logo', RT_RCDATA);
    try
      JPEG := TJPEGImage.Create;
      try
        JPEG.PixelFormat := jf8Bit;
        JPEG.Performance := jpBestSpeed;
        JPEG.Smoothing := false;
        JPEG.LoadFromStream (ResStream);
        Image.Picture.Graphic := JPEG;
      finally
        JPEG.Free;
      end;
    finally
      ResStream.Free;
    end;

  except
  end;

  if (VersionIsPrivate) then begin
    with LabelNotForDistribution do begin
      Font.Color := clRed;
      Font.Style := [fsBold];
      Visible := true;
    end;
  end else begin
    LabelNotForDistribution.Visible := false;
  end;

end;


procedure   TDlgSplash.Ready;
begin
  fTimer := TTimer.create (self);
  fTimer.OnTimer := TimerTick;
  fTimer.Interval := 1500;
  fTimer.Enabled := True;
end;


procedure   TDlgSplash.TimerTick (Sender: TObject);
begin
  Release;
end;


procedure   TDlgSplash.SetStatus (S: String);
begin
  StatusLabel.Caption := S;
  Update;
end;


function    TDlgSplash.GetStatus: String;
begin
  Result := StatusLabel.Caption;
end;


procedure   TDlgSplash.FormDestroy (Sender: TObject);
begin
  fTimer.free;
  inherited;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

