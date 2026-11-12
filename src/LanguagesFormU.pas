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


unit LanguagesFormU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TLanguagesForm = class (TFormUlf)
    ListView: TListView;
    Label1: TLabel;
    OkButton: TButton;
    Label2: TLabel;
    Label3: TLabel;
    procedure   ListViewChange (Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure   ListViewDblClick (Sender: TObject);
    procedure   FormCloseQuery (Sender: TObject; var CanClose: Boolean);
    procedure   FormCreate (Sender: TObject);
  private
    FCanClose: Boolean;
  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TLanguagesForm.FormCreate (Sender: TObject);
begin
  FCanClose := false;
end;


procedure   TLanguagesForm.FormCloseQuery (Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;
end;


procedure   TLanguagesForm.ListViewChange (Sender: TObject; Item: TListItem; Change: TItemChange);
var
  B: Boolean;
begin
  B := false;
  if (assigned (Item)) then begin
    if (Change = ctState) then begin
      if (Item.Selected) then begin
        B := true;
      end;
    end;
  end else begin
    B := assigned (ListView.Selected);
  end;
  OkButton.Enabled := B;
  FCanClose := B;
end;


procedure   TLanguagesForm.ListViewDblClick (Sender: TObject);
begin
  if (assigned (ListView.Selected)) then begin
    FCanClose := true;
    ModalResult := mrOk;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.
