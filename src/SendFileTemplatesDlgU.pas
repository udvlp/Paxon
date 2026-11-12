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


unit SendFileTemplatesDlgU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, DebOutU, FormU, SendFileTemplatesU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TSendFileTemplatesDlg = class (TFormUlf)

    BtnOk: TButton;
    BtnCancelDlg: TButton;
    Panel1: TPanel;
    RichEdit1: TRichEdit;
    GroupBoxBottom: TGroupBox;
    GroupBoxTop: TGroupBox;
    TextListview: TListView;
    ButtonAdd: TButton;
    ButtonRemove: TButton;
    TextMemo: TMemo;

    procedure   FormCreate (Sender: TObject);
    procedure   FormDestroy (Sender: TObject);
    procedure   TextListviewData (Sender: TObject; Item: TListItem);
    procedure   TextListviewChange (Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure   TextMemoChange (Sender: TObject);
    procedure   ButtonAddClick (Sender: TObject);
    procedure   ButtonRemoveClick (Sender: TObject);
    constructor create (aOwner: TComponent; aSendFileTemplates: TSendFileTemplates); reintroduce; virtual;
    procedure   Resize; override;
    procedure   TextListviewResize(Sender: TObject);

  private

    ItemIndex: Integer;
    OriginalSendFileTemplates: TSendFileTemplates;
    SendFileTemplates: TSendFileTemplates;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}

uses
  GlobalU, Registry;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TSendFileTemplatesDlg.create (aOwner: TComponent; aSendFileTemplates: TSendFileTemplates);
begin
  OriginalSendFileTemplates := aSendFileTemplates;
  SendFileTemplates := TSendFileTemplates.create (OriginalSendFileTemplates);
  inherited create (aOwner);
end;


procedure   TSendFileTemplatesDlg.FormCreate (Sender: TObject);
var
  ResStream: TResourceStream;
  LI: TListItem;

begin

  ResStream := TResourceStream.Create (FindResourceHInstance (HInstance), 'SendFileVariables', RT_RCDATA);
  try
    Richedit1.Lines.LoadFromStream (ResStream);
  finally
    ResStream.Free;
  end;

  assert (assigned (SendFileTemplates));

  ItemIndex := -1;

  TextListview.Items.Count := SendFileTemplates.Count;

  if (TextListview.Items.Count >= 1) then begin
    LI := TextListview.Items[0];
    LI.Selected := true;
    LI.Focused := true;
  end else begin
    LI := nil;
  end;

  TextListviewChange (TextListview, LI, ctState);

end;


procedure   TSendFileTemplatesDlg.FormDestroy (Sender: TObject);
begin
  if (ModalResult = mrOk) then begin
    SendFileTemplates.Save;
    OriginalSendFileTemplates.assign (SendFileTemplates);
  end;
  SendFileTemplates.free;
end;


procedure   TSendFileTemplatesDlg.TextListviewData (Sender: TObject; Item: TListItem);
begin
  Item.Caption := SendFileTemplates.GetShortString (Item.Index, TextListView.Columns[0].Width - 8, TextListView.Font);
end;


procedure   TSendFileTemplatesDlg.TextListviewChange (Sender: TObject; Item: TListItem; Change: TItemChange);
const
  MethodName = 'TextListviewChange';
begin
  ItemIndex := -1;
  TextMemo.Text := '';
  if (assigned (Item)) then begin
    if (Change = ctState) then begin
      if (Item.Selected) then begin
        ItemIndex := Item.Index;
        TextMemo.Text := SendFileTemplates[ItemIndex];
      end;
    end;
  end;
  if (ItemIndex >= 0) then begin
    TextMemo.Enabled := true;
    TextMemo.Color := clWindow;
  end else begin
    TextMemo.Enabled := false;
    TextMemo.Color := clBtnFace;
  end;
end;


procedure   TSendFileTemplatesDlg.TextMemoChange (Sender: TObject);
begin
  if (ItemIndex >= 0) then begin
    SendFileTemplates[ItemIndex] := TextMemo.Text;
    TextListview.Items[ItemIndex].Update;
  end;
end;


procedure   TSendFileTemplatesDlg.ButtonAddClick (Sender: TObject);
var
  L: Integer;
  LI: TListItem;
begin
  L := SendFileTemplates.Count - 1;
  if (L < 99) then begin
    Inc (L);
    SendFileTemplates.Count := L + 1;
    SendFileTemplates[L] := '';
    TextListview.Items.Count := L + 1;
    LI := TextListview.Items[L];
    LI.MakeVisible (false);
    LI.Focused := true;
    TextListview.Selected := LI;
  end;
  TextMemo.SetFocus;
end;


procedure   TSendFileTemplatesDlg.ButtonRemoveClick (Sender: TObject);
var
  L, N: Integer;
  LI: TListItem;
begin
  if (ItemIndex >= 0) then begin
    L := SendFileTemplates.Count - 1;
    for N := ItemIndex to L - 1 do begin
      SendFileTemplates[N] := SendFileTemplates[N + 1];
    end;
    TextListview.Items.Count := L;
    SendFileTemplates.Count := L;
    if (ItemIndex > L - 1) then ItemIndex := L - 1;
    if (ItemIndex >= 0) then begin
      LI := TextListview.Items[ItemIndex];
      LI.Focused := true;
      LI.MakeVisible (false);
    end else begin
      LI := nil;
    end;
    TextListview.Selected := LI;
    TextListviewChange (TextListview, LI, ctState);
    TextListview.Refresh;
  end;
  TextListview.SetFocus;
end;


procedure   TSendFileTemplatesDlg.TextListviewResize(Sender: TObject);
begin
  TextListView.Columns[0].Width := TextListView.ClientWidth - 2;
end;


procedure   TSendFileTemplatesDlg.Resize;
begin
  inherited;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

