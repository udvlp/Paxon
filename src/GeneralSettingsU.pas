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


unit GeneralSettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  GlobalU, InterfacesU, StdCtrls, ComCtrls, ExtCtrls,
  SettingsU, Mask;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TGeneralSettings = class (TTabForm)

    AllGroupbox1: TGroupBox;
    CallsignListView: TListView;
    EditCallsign: TButton;
    AddCallsign: TButton;
    RemoveCallsign: TButton;
    AllGroupbox2: TGroupBox;
    AllChannelsLabel: TLabel;
    AllLinesLabel: TLabel;
    ChannelCountUpDown: TUpDown;
    ChannelCountEdit: TEdit;
    AllLinesEdit: TEdit;
    AllLinesUpDown: TUpDown;
    LocalEchoCheckBox: TCheckBox;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    IncomingConnectionsCombobox: TComboBox;

    procedure   FormCreate (Sender: TObject);
    procedure   FormDestroy (Sender: TObject);
    procedure   EditCallsignClick (Sender: TObject);
    procedure   RemoveCallsignClick (Sender: TObject);
    procedure   AddCallsignClick (Sender: TObject);
    procedure   CallsignListviewDblClick (Sender: TObject);

  public

    procedure   ApplyPage; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  CallsignSettingsU, MyCallsU, MyCallU, ConfigU, ChannelsU, DebOutU, MainU, MessageboxU;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TGeneralSettings.FormCreate (Sender: TObject);
var
  N: Integer;
  R: TMyCall;
  IC: TIncomingConnect;

begin

  MyCalls.BeginRead;
  try
    for N := 0 to MyCalls.count - 1 do begin
      with CallsignListView do begin
        R := TMyCall.Create;
        R.Assign (MyCalls[N]);
        with Items.Add do begin
          Data := R;
          Caption := R.Call;
          SubItems.Add (R.SsidsAsString);
        end;
      end;
    end;
  finally
    MyCalls.EndRead;
  end;

  IncomingConnectionsCombobox.Items.Clear;
  IncomingConnectionsCombobox.Items.Add (SIncomingConnectAccept);
  IncomingConnectionsCombobox.Items.Add (SIncomingConnectIgnore);
  IncomingConnectionsCombobox.Items.Add (SIncomingConnectBusy);

  IC := Config.IncomingConnect;
  case IC of
    ic_ignore: N := 1;
    ic_busy:   N := 2;
    else       N := 0;
  end;
  IncomingConnectionsCombobox.ItemIndex := N;

  ChannelCountUpDown.Position := ChannelList.Quantity;

  LocalEchoCheckBox.Checked := Config.LocalEcho;

  AllLinesUpDown.Position := Config.ConsoleRows;

  // Allow only digits to be entered
  SetWindowLong (ChannelCountEdit.Handle, GWL_STYLE, GetWindowLong (ChannelCountEdit.Handle, GWL_STYLE) or ES_NUMBER);
  SetWindowLong (AllLinesEdit.Handle, GWL_STYLE, GetWindowLong (AllLinesEdit.Handle, GWL_STYLE) or ES_NUMBER);

end;


procedure   TGeneralSettings.FormDestroy (Sender: TObject);
var
  N: Integer;

begin

  with CallsignListView.Items do begin
    for N := 0 to count - 1 do begin
      TMyCall(Item[N].Data).Free;
    end;
  end;

  inherited;

end;


procedure   TGeneralSettings.ApplyPage;
resourcestring
  SRowsChanged = 'Bei Änderung der Zeilenzahl werden die Inhalte der Empfangsfenster gelöscht. Fortsetzen?';

var
  N: Integer;
  R: TMyCall;
  IC: TIncomingConnect;
  B: Boolean;

begin

  MyCalls.BeginWrite;
  try
    MyCalls.Clear;
    with CallsignListView.Items do begin
      for N := 0 to count - 1 do begin
        R := TMyCall.Create;
        R.assign (TMyCall(Item[N].Data));
        MyCalls.add (R);
      end;
    end;
  finally
    MyCalls.EndWrite;
  end;

  case IncomingConnectionsCombobox.ItemIndex of
    1: IC := ic_ignore;
    2: IC := ic_busy;
    else IC := ic_accept;
  end;
  Config.IncomingConnect := IC;

  N := StrToIntDef (Trim (ChannelCountEdit.Text), ChannelCountUpDown.Min);
  if (N < ChannelCountUpDown.Min) then begin
    N := ChannelCountUpDown.Min;
  end else if (N > ChannelCountUpDown.Max) then begin
    N := ChannelCountUpDown.Max;
  end;
  ChannelList.Quantity := N;

  Config.LocalEcho := LocalEchoCheckBox.Checked;

  // Limit the line count to the valid range of the field (applying via Enter
  // happens without CM_EXIT, pasted text is not checked)

  N := StrToIntDef (Trim (AllLinesEdit.Text), AllLinesUpDown.Min);
  if (N < AllLinesUpDown.Min) then begin
    N := AllLinesUpDown.Min;
  end else if (N > AllLinesUpDown.Max) then begin
    N := AllLinesUpDown.Max;
  end;
  AllLinesEdit.Text := IntToStr (N);

  if (Config.ConsoleRows <> N) then begin

    with TDlgMessage.create (Settings) do begin
      B := IsPositiveResult (Run (ApplicationName, SRowsChanged, [mbYes, mbNo]));
      Release;
    end;

    if (B) then begin
      try
        ChannelList.ConsoleRows := N;
        Config.ConsoleRows := N;
      except
      end;
    end else begin
      AllLinesEdit.Text := IntToStr (Config.ConsoleRows);
    end;

  end;

  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    ChannelList.CurrentChannel.ActivateChannel (true);
  end;

end;


procedure   TGeneralSettings.CallsignListviewDblClick (Sender: TObject);
begin
  inherited;
  EditCallsignClick (Sender);
end;


procedure   TGeneralSettings.EditCallsignClick (Sender: TObject);
var
  LI: TListItem;
  MC: TMyCall;
begin
  with TCallsignSettingsForm.Create (Parent) do begin
    LI := CallsignListView.Selected;
    if (LI <> nil) then begin
      MC := TMyCall (LI.Data);
      if (Run (MC)) then begin
        LI.Caption := MC.Call;
        LI.SubItems.Strings[0] := MC.SsidsAsString;
      end;
    end;
  end;
  if (CallsignListView.CanFocus) then CallsignListView.SetFocus;
end;


procedure   TGeneralSettings.AddCallsignClick (Sender: TObject);
const
  MethodName = 'AddCallsignClick';
var
  R: TMyCall;
  LI: TListItem;
begin
  DebOut (self, MethodName, 'begin...');
  R := TMyCall.create;
  with R do begin
    Call := '';
    SSIDCount := 1;
    SSID[0] := 0;
  end;
  DebOut (self, MethodName, 'TCallsignSettingsForm.Create...');
  with TCallsignSettingsForm.Create (Parent) do begin
    if (Run (R)) then begin
      LI := CallsignListView.Items.Add;
      with LI do begin
        Data := R;
        Caption := R.Call;
        SubItems.Add (R.SsidsAsString);
      end;
      CallsignListView.Selected := LI;
    end else begin
      R.Free;
    end;
  end;
  DebOut (self, MethodName, 'end.');
end;


procedure   TGeneralSettings.RemoveCallsignClick (Sender: TObject);
var
  LI: TListItem;
  R: TMyCall;
begin
  LI := CallsignListView.Selected;
  if (LI <> nil) then begin
    R := TMyCall (LI.Data);
    LI.Data := nil;
    LI.Delete;
    R.Free;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

