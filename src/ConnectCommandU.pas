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


unit ConnectCommandU;


interface


uses
  Windows, Messages, SysUtils, Classes, Forms,
  Controls, StdCtrls, ComCtrls, ExtCtrls, Dialogs, ImgList,
  GlobalU, InterfacesU, DevicesU, ComboBoxUlfU, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type


  TDlgConnectCommand = class (TFormUlf)

    Panel: TPanel;
    LabelStation: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    PortListView: TListView;
    CallCombo: TComboBoxUlf;
    MyCallCombo: TComboBoxUlf;
    PanelBottom: TPanel;
    ButtonOk: TButton;
    ButtonCancel: TButton;
    ImagePanel: TPanel;
    Image: TImage;
    procedure FormShow (Sender: TObject);

    procedure   FormCreate (Sender: TObject);
    procedure   BtnOkClick (Sender: TObject);
    procedure   FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure   FormDestroy (Sender: TObject);
    procedure   CallComboComplete (Sender: TObject; var Text: String; var CompleteWith: String; var Finish: Boolean);
    procedure   CallComboChange (Sender: TObject);
    procedure   MyCallComboChange (Sender: TObject);

  private

    RadioChannels: Array of IRadioChannel;
    ChannelRef: IChannel;
    Ports: TStringList;
    Monitor: Boolean;
    procedure   CheckOkEnabled;

  public

    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


uses
  DebOutU, MainU, ChannelsU, MyCallsU, MessageBoxU, Registry, JPEG,
  FlexnetApiU, ConfigU;


{$R *.DFM}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

const
  HistoryLength = 50;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


constructor TDlgConnectCommand.create;
begin
  inherited;
end;


destructor  TDlgConnectCommand.destroy;
begin
  inherited;
end;


procedure   TDlgConnectCommand.FormCreate (Sender: TObject);
resourcestring
  SUIDestination = 'UI-Ziel';
  SUIDestinationTitle = 'UI-Ziel einstellen';

var
  N, I, J, M: Integer;
  Registry: TRegistry;
  S, T, U, V: string;
  JPEG: TJPEGImage;
  ResStream: TResourceStream;
  SL: TStringList;
  B: Boolean;

begin

  inherited;

  assert (assigned (MyCalls));

  Ports := TStringList.create;

  ChannelRef := ChannelList.CurrentChannel;

  Monitor := (ChannelRef.No = 0);

  if (Monitor) then begin
    Caption := SUIDestinationTitle;
    LabelStation.Caption := SUIDestination;
  end;

  ChannelRef.IsReserved := true;

  if (HighColor) then begin
    ResStream := TResourceStream.Create (HInstance, 'ConnectPicture', RT_RCDATA);
    JPEG := TJPEGImage.Create;
    JPEG.LoadFromStream (ResStream);
    Image.Picture.Graphic := JPEG;
    JPEG.Free;
    ResStream.Free;
  end;

  Registry := TRegistry.create (KEY_READ or KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    Registry.OpenKey (RootRegKey + '\History', true);
    try
      S := Registry.ReadString ('OwnCallsign');
    except
      S := '';
    end;
    Registry.CloseKey;
  finally
    Registry.free;
  end;

  SL := TStringList.create;

  try

    SL.CommaText := S;

    MyCallCombo.Items.Clear;

    MyCalls.BeginRead;

    try

      for J := 0 to SL.Count - 1 do begin
        T := SL[J];
        for I := 0 to MyCalls.Count - 1 do begin
          S := MyCalls[I].Call;
          if (T = S) then begin
            MyCallCombo.Items.Add (S);
            SL[J] := '';
            break;
          end;
        end;
      end;

      for I := 0 to MyCalls.Count - 1 do begin
        S := MyCalls[I].Call;
        B := true;
        for J := 0 to MyCallCombo.Items.Count - 1 do begin
          T := MyCallCombo.Items[J];
          if (S = T) then begin
            B := false;
            break;
          end;
        end;
        if (B) then begin
          MyCallCombo.Items.Add (S);
        end;
      end;

      for J := 0 to SL.Count - 1 do begin
        T := SL[J];
        if (Length (T) > 0) then begin
          MyCallCombo.Items.Add (T);
        end;
      end;

      MycallCombo.ItemIndex := 0;

    finally

      MyCalls.EndRead;

    end;

  finally

    SL.free;

  end;

  Registry := TRegistry.create (KEY_READ or KEY_WRITE);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    Registry.OpenKey (RootRegKey + '\History', true);
    SL := TStringList.create;
    try
      try
        if (Monitor) then V := 'UI-Destination' else V := 'Station';
        S := Registry.ReadString (V);
      except
        S := '';
      end;
      try
        SL.CommaText := S;
      except
        SL.Clear;
      end;
      I := 0;
      CallCombo.Items.Clear;
      while (I < SL.Count) do begin
        S := SL[I];
        if (Length (S) >= 1) and (S[1] <> '#') then begin
          T := '';
          if (I + 1 < SL.Count) then begin
            U := SL[I + 1];
            assert (Length (U) > 0);
            if (U[1] = '#') then begin
              T := Copy (U, 2, MaxInt);
              inc (I);
            end;
          end;
          M := Ports.Add (T);
          CallCombo.Items.AddObject (S, TObject(M));
        end;
        inc (I);
      end;
    finally
      SL.free;
    end;
    Registry.CloseKey;
  finally
    Registry.free;
  end;

  CallCombo.ItemIndex := 0;

  PortListView.Items.Clear;
  SetLength (RadioChannels, 256);
  I := DeviceList.RadioChannels (RadioChannels);
  SetLength (RadioChannels, I);
  for N := 0 to I - 1 do begin
    with PortListView.Items.Add do begin
      Caption := RadioChannels[N].Name;
    end;
  end;

end;


procedure   TDlgConnectCommand.FormShow (Sender: TObject);
var
  K: Integer;

begin
  if (assigned (PortListView.Items[0])) then begin

    with PortListView.Items[0] do begin
      Selected := true;
      Focused := true;
      MakeVisible (false);
    end;

    if (Ports.Count > 0) then begin
      for K := Low(RadioChannels) to High (RadioChannels) do begin
        if (RadioChannels[K].ID = Ports[0]) then begin
          with PortListView.Items[K] do begin
            Focused := true;
            Selected := true;
          end;
          break;
        end;
      end;
    end;

  end;

  CheckOkEnabled;

end;


procedure   TDlgConnectCommand.FormDestroy (Sender: TObject);
var
  Registry: TRegistry;
  I, N: Integer;
  SL: TStringList;
  V: String;

begin

  Registry := TRegistry.create (KEY_READ or KEY_WRITE);

  try

    Registry.RootKey := HKEY_CURRENT_USER;
    Registry.OpenKey (RootRegKey + '\History', true);

    ////////////////////////////////////////////////////////////////////////

    Registry.WriteString ('OwnCallsign', MyCallCombo.Items.CommaText);

    ////////////////////////////////////////////////////////////////////////

    SL := TStringList.create;
    try
      for N := 0 to CallCombo.Items.Count - 1 do begin
        SL.Add (CallCombo.Items[N]);
        I := Integer(CallCombo.Items.Objects[N]);
        SL.Add ('#' + Ports[I]);
      end;
      if (Monitor) then V := 'UI-Destination' else V := 'Station';
      Registry.WriteString (V, SL.CommaText);
    finally
      SL.free;
    end;

    ////////////////////////////////////////////////////////////////////////

    Registry.CloseKey;

  finally

    Registry.free;

  end;

  if (assigned (ChannelRef)) then begin
    ChannelRef.IsReserved := false;
  end;

  Ports.free;

  ChannelRef := nil;

end;


procedure   TDlgConnectCommand.BtnOkClick (Sender: TObject);
resourcestring
  SMessageboxCaption = 'Verbinden';
  SNoChannelSelected = 'Kein Kanal ausgewählt.';
  SDeviceTimeout = 'Das Gerät antwortet nicht.';
  SNoDevice = 'Kein Gerät vorhanden.';
  SChannelAlreadyConnected = 'Der Kanal ist bereits verbunden.';
  SNoSSID = 'Keine freie SSID verfügbar.';
  SDeviceError = 'Gerätefehler.';
  SUnknownError = 'Unbekannter Fehler.';
  SUnhandledError = 'Unbehandelter Fehler.';
  SNoFreeChannel = 'Alle Kanäle sind belegt.';
  SNotSimultaneous = 'Gewählte Betriebsarten sind nicht gleichzeitig möglich.';

const
  MethodName = 'BtnOkClick';

var
  LI: TListItem;
  RadioChannel: IRadioChannel;
  Call, MyCall, Digis: String;
  I, N: Integer;
  S: string;
  W: String;

begin

  ButtonOk.Enabled := false;
  ButtonCancel.Enabled := false;
  CallCombo.Enabled := false;
  MyCallCombo.Enabled := false;
  PortListView.Enabled := false;

  try

    inherited;

    // Eine ungültige SSID (nicht 0..15) wird nicht still entfernt: Das ergäbe
    // ein anderes Rufzeichen. Ohne Rufzeichen wird nicht verbunden, der Dialog
    // bleibt offen.
    MyCall := UpperCase (Trim (MycallCombo.Text));
    I := Pos ('-', MyCall);
    if (I > 0) then begin
      N := StrToIntDef (Copy (MyCall, I+1, MaxInt), -1);
      Delete (MyCall, I, MaxInt);
      if (N >= 0) and (N <= 15) then begin
        MyCall := MyCall + '-' + IntToStr (N);
      end else begin
        MyCall := '';
        MessageBeep (MB_ICONEXCLAMATION);
      end;
    end;

    Call := UpperCase (Trim (CallCombo.Text));
    I := Pos (' ', Call);
    if (I > 0) then begin
      Digis := Copy (Call, I+1, MaxInt);
      Delete (Call, I, MaxInt);
    end else begin
      Digis := '';
    end;

    I := Pos ('-', Call);
    if (I > 0) then begin
      N := StrToIntDef (Copy (Call, I + 1, MaxInt), -1);
      Delete (Call, I, MaxInt);
      if (N >= 0) and (N <= 15) then begin
        if (N > 0) then Call := Call + '-' + IntToStr (N);
      end else begin
        Call := '';
        MessageBeep (MB_ICONEXCLAMATION);
      end;
    end;

    DebOut (self, MethodName, 'MyCall=''' + MyCall + ''' Call=''' + Call + ''' Digis=''' + Digis + '''');

    if (Length (MyCall) > 0) and (Length (Call) > 0) then begin

      LI := PortListView.Selected;

      if (LI = nil) then begin
        with TDlgMessage.create (self) do begin
          Run (SMessageboxCaption, SNoChannelSelected, [mbOk]);
          Release;
        end;
        exit;
      end;

      RadioChannel := RadioChannels[LI.Index];

      W := Call;
      if (Length (Digis) > 0) then W := W + ' ' + Digis;

      if (Monitor) then begin

        Config.UIDestination := W;
        Config.UIMyCall := MyCall;
        Config.UIPort := RadioChannel.ID;
        if (assigned (ChannelRef)) then ChannelRef.StatusChanged;
        ModalResult := mrOk;

      end else begin

        case RadioChannel.EstablishConnection (W, MyCall, ChannelRef) of
          vf_ok: begin
            S := '';
          end;
          vf_devicetimeout: begin
            S := SDeviceTimeout;
          end;
          vf_nodevice: begin
            S := SNoDevice;
          end;
          vf_channelalreadyconnected: begin
            S := SChannelAlreadyConnected;
          end;
          vf_nossid: begin
            S := SNoSSID;
          end;
          vf_deviceerror: begin
            S := SDeviceError;
          end;
          vf_unknown: begin
            S := SUnknownError;
          end;
          vf_nofreechannel: begin
            S := SNoFreeChannel;
          end;
          vf_notsimultaneous: begin
            S := SNotSimultaneous;
          end;
          else begin
            S := SUnhandledError;
          end;
        end;

        if (Length (S) > 0) then begin

          with TDlgMessage.create (self) do begin
            Run (SMessageboxCaption, S, [mbOk]);
            Release;
          end;

        end else begin

          ChannelList.CurrentChannelNo := ChannelRef.No;

          ModalResult := mrOk;

        end;

      end;

      if (ModalResult = mrOk) then begin

        repeat
          N := MyCallCombo.Items.IndexOf (MyCall);
          if (N < 0) then break;
          MyCallCombo.Items.Delete (N);
        until False;

        MyCallCombo.Items.Insert (0, MyCall);

        for N := MyCallCombo.Items.Count - 1 downto HistoryLength do begin
          MyCallCombo.Items.Delete (N);
        end;

        S := Call;
        if (Length (Digis) > 0) then S := S + ' ' + Digis;

        repeat
          N := CallCombo.Items.IndexOf (S);
          if (N < 0) then break;
          CallCombo.Items.Delete (N);
        until false;

        N := Ports.Add (RadioChannel.ID);
        CallCombo.Items.InsertObject (0, S, TObject(N));

        for N := CallCombo.Items.Count - 1 downto HistoryLength do begin
          CallCombo.Items.Delete (N);
        end;

      end;

    end;

  finally

    if (ModalResult = mrNone) then begin
      Enabled := true;
      CheckOkEnabled;
      ButtonCancel.Enabled := true;
      CallCombo.Enabled := true;
      MyCallCombo.Enabled := true;
      PortListView.Enabled := true;
    end;

  end;

end;


procedure   TDlgConnectCommand.FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
var
  I: Integer;

begin

  if ((Key in [vk_f1..vk_f12]) and (Shift = [])) then begin

    I := Key - vk_f1;

    if (I >= 0) and (I < PortListView.Items.Count) then begin

      with PortListView.Items[I] do begin
        Selected := true;
        Focused := true;
      end;

    end else begin

      beep;

    end;

    Key := 0;
    Shift := [];

  end;

end;


procedure   TDlgConnectCommand.CallComboComplete (Sender: TObject; var Text: String; var CompleteWith: String; var Finish: Boolean);
const
  MethodName = 'CallComboComplete';

var
  W: String;
  N, I: Integer;

begin

  if (CallCombo.Items.Count > 0) then begin
    N := Length (Text);
    for I := 0 to CallCombo.Items.Count - 1 do begin
      W := CallCombo.Items.Strings[I];
      if (StrLIComp (PChar(Text), PChar(W), N) = 0) then begin
        CompleteWith := Copy (W, N + 1, MaxInt);
        break;
      end;
    end;
  end;

  Finish := true;

end;


procedure   TDlgConnectCommand.CheckOkEnabled;
begin
  ButtonOk.Enabled := (PortListView.Items.Count > 0) and (Length (CallCombo.Text) > 0) and (Length (MyCallCombo.Text) > 0);
end;


procedure   TDlgConnectCommand.CallComboChange (Sender: TObject);
const
  MethodName = 'CallComboChange';
var
  K, I: Integer;
  S, T: String;

begin

  S := CallCombo.Text;

  for I := 0 to CallCombo.Items.Count - 1 do begin

    T := CallCombo.Items.Strings[I];

    if (AnsiCompareText (S, T) = 0) then begin

      for K := Low(RadioChannels) to High (RadioChannels) do begin
        if (RadioChannels[K].ID = Ports[Integer(CallCombo.Items.Objects[I])]) then begin
          with PortListView.Items[K] do begin
            Selected := true;
            Focused := true;
          end;
          break;
        end;
      end;

      break;

    end;
  end;

  CheckOkEnabled;

end;


procedure   TDlgConnectCommand.MyCallComboChange (Sender: TObject);
begin
  CheckOkEnabled;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

