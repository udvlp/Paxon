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


unit MLCBRB;

interface

uses
  Windows,
  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

const BS_TOP = $400;
      BS_MULTILINE = $2000;

type
  TMultiCheckBox = class(TCheckBox)
  private
    fMultiLine: Boolean;
    procedure SetMultiLine(Value: Boolean);
  protected
    procedure CreateParams (var Params: TCreateParams); override;
  public
    constructor Create (AOwner: TComponent); override;
  published
    property MultiLine: Boolean read fMultiLine write SetMultiLine default True;
  end;

  TMultiRadioButton = class(TRadioButton)
  private
    fMultiLine: Boolean;
    procedure SetMultiLine(Value: Boolean);
  protected
    procedure CreateParams (var Params: TCreateParams); override;
  public
    constructor Create (AOwner: TComponent); override;
  published
    property MultiLine: Boolean read fMultiLine write SetMultiLine default True;
  end;


procedure Register;

implementation

{$R MLCBRB.RES}


{  TMultiCheckBox component }
constructor TMultiCheckBox.Create (AOwner: TComponent);
begin
  inherited Create (AOwner);
  fMultiLine := true;
end;

procedure TMultiCheckBox.SetMultiLine(Value: Boolean);
begin
  if fMultiLine<>Value then begin
    fMultiLine := Value;
    RecreateWnd;
  end;
end;

procedure TMultiCheckBox.CreateParams (var Params: TCreateParams);
begin
  inherited CreateParams (Params);
  if MultiLine then Params.Style := Params.Style or BS_MULTILINE or BS_TOP
               else Params.Style := Params.Style and not BS_MULTILINE and not BS_TOP;
end;


{  TMultiRadioButton component }
constructor TMultiRadioButton.Create (AOwner: TComponent);
begin
  inherited Create (AOwner);
  fMultiLine := true;
end;

procedure TMultiRadioButton.SetMultiLine(Value: Boolean);
begin
  if fMultiLine<>Value then begin
    fMultiLine := Value;
    RecreateWnd;
  end;
end;

procedure TMultiRadioButton.CreateParams (var Params: TCreateParams);
begin
  inherited CreateParams (Params);
  if MultiLine then Params.Style := Params.Style or BS_MULTILINE or BS_TOP
               else Params.Style := Params.Style and not BS_MULTILINE and not BS_TOP;
end;


procedure Register;
begin
  RegisterComponents('Paxon', [TMultiCheckBox]);
  RegisterComponents('Paxon', [TMultiRadioButton]);
end;

end.
