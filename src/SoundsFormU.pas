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


unit SoundsFormU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, MMSystem, SoundsConstsU,
  ExtCtrls, PanelUlfU, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  PEntry = ^TEntry;
  TEntry = record
    Event: TSoundEvent;
    Loaded: Boolean;
    SignalChecked: Boolean;
    Signal: TSignalType;
    SignalWavFile: String;
    AnnouncementChecked: Boolean;
    Announcement: TAnnouncementType;
  end;


  TSoundsForm = class (TFormUlf)
    EventGroupbox: TGroupBox;
    EventLabel: TLabel;
    EventComboBox: TComboBox;
    SoundGroupBox: TGroupBox;
    SoundNoneRadioButton: TRadioButton;
    SoundPCSpeakerRadioButton: TRadioButton;
    SoundWaveRadioButton: TRadioButton;
    SoundWaveEdit: TEdit;
    SoundWaveBrowseButton: TButton;
    SoundWavePlayButton: TBitBtn;
    AnnouncementGroupBox: TGroupBox;
    AnnouncementNoneRadioButton: TRadioButton;
    AnnouncementVoiceRadioButton: TRadioButton;
    AnnouncementTelegraphyRadioButton: TRadioButton;
    AnnouncementCheckBox: TCheckBox;
    SchemaGroupBox: TGroupBox;
    SchemeLoadButton: TButton;
    SchemeSaveButton: TButton;
    SoundCheckBox: TCheckBox;
    GroupBox1: TGroupBox;

    procedure   EventComboBoxChange (Sender: TObject);
    procedure   SoundRadioButtonClick (Sender: TObject);
    procedure   SoundWaveBrowseButtonClick (Sender: TObject);
    procedure   SoundWavePlayButtonClick (Sender: TObject);
    procedure   SoundCheckBoxClick (Sender: TObject);
    procedure   AnnouncementCheckBoxClick (Sender: TObject);
    procedure   SaveSound;
    procedure   SaveAnnouncement;
    procedure   SchemeLoadButtonClick (Sender: TObject);
    procedure   SchemeSaveButtonClick (Sender: TObject);

  private

    SoundEntries: Array of TEntry;
    Index: Integer;
    FCall: String;
    FGlobal: Boolean;

  public

    procedure   Init (Global: Boolean); virtual;
    procedure   Save; virtual;
    procedure   SetNewCall (aCall: String); virtual;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}

uses
  DebOutU, SoundsU, MainU, IniFiles, GlobalU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


resourcestring
  SLoadSaveDialogFilter = 'Paxon Soundschema (*.pxs)|*.pxs';


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSoundsForm.Init (Global: Boolean);
const
  MethodName = 'Init';

var
  I: TSoundEvent;
  N: Integer;

begin

  DebOut (self, MethodName, 'begin...');

  FGlobal := Global;

  if (Global) then begin
    SoundCheckBox.Visible := false;
    AnnouncementCheckBox.Visible := false;
  end else begin
    SoundCheckBox.Visible := true;
    SoundGroupBox.Caption := ' ';
    AnnouncementCheckBox.Visible := true;
    AnnouncementGroupBox.Caption := ' ';
  end;

  FCall := '';

  SoundCheckBox.Width := Application.MainForm.Canvas.TextWidth (SoundCheckBox.Caption) +
                         (20 * Application.MainForm.PixelsPerInch div 96);
  AnnouncementCheckBox.Width := Application.MainForm.Canvas.TextWidth (AnnouncementCheckBox.Caption) +
                                (20 * Application.MainForm.PixelsPerInch div 96);

  EventComboBox.Clear;

  assert (Ord (Low (TSoundEvent)) = 0);
  SetLength (SoundEntries, Ord (High (TSoundEvent)) + 1);
  N := 0;

  for I := Low (TSoundEvent) to High (TSoundEvent) do begin
    if (not (SoundEvents(I).OnlyGlobal)) or (Global) then begin
      EventComboBox.Items.Add (SoundEvents(I).Name);
      SoundEntries[N].Event := I;
      SoundEntries[N].Loaded := false;
      inc (N);
    end;
  end;
  SetLength (SoundEntries, N);

  EventComboBox.ItemIndex := 0;
  Index := -1;
  EventComboBoxChange (nil);

  DebOut (self, MethodName, 'end.');

end;


procedure   TSoundsForm.SaveSound;
var
  E: PEntry;
begin
  if (Index >= 0) then begin
    E := @SoundEntries[Index];
    if (E.SignalChecked) then begin
      if (SoundPCSpeakerRadioButton.Checked) then begin
        E.Signal := st_pcspk;
      end else if (SoundWaveRadioButton.Checked) then begin
        E.Signal := st_wave;
      end else begin
        E.Signal := st_silence;
      end;
      E.SignalWavFile := SoundWaveEdit.Text;
      E.SignalChecked := true;
    end else begin
      E.SignalChecked := false;
    end;
  end;
end;


procedure   TSoundsForm.SaveAnnouncement;
var
  E: PEntry;
begin
  if (Index >= 0) then begin
    E := @SoundEntries[Index];
    if (E.AnnouncementChecked) then begin
      if (AnnouncementVoiceRadioButton.Checked) then begin
        E.Announcement := at_voice;
      end else if (AnnouncementTelegraphyRadioButton.Checked) then begin
        E.Announcement := at_cw;
      end else begin
        E.Announcement := at_silence;
      end;
      E.AnnouncementChecked := true;
    end else begin
      E.AnnouncementChecked := false;
    end;
  end;
end;


procedure   TSoundsForm.EventComboBoxChange (Sender: TObject);
var
  E: PEntry;

begin

  SaveSound;
  SaveAnnouncement;

  Index := EventComboBox.ItemIndex;

  if (Index >= 0) then begin

    E := @SoundEntries[Index];

    if (not E.Loaded) then begin
      Sounds.Load (FCall, E.Event, E.Signal, E.SignalWavFile, E.Announcement);
      E.SignalChecked := (E.Signal <> st_undefined);
      E.AnnouncementChecked := (E.Announcement <> at_undefined);
      E.Loaded := true;
    end;

    SoundCheckBox.Checked := (FGlobal) or (E.SignalChecked);
    SoundCheckBoxClick (nil);

    if (SoundEvents(E.Event).AnnouncementPossible) then begin
      AnnouncementCheckBox.Enabled := true;
      AnnouncementCheckBox.Checked := (FGlobal) or (E.AnnouncementChecked);
    end else begin
      AnnouncementCheckBox.Enabled := false;
      AnnouncementCheckBox.Checked := false;
    end;
    AnnouncementCheckBoxClick (nil);

  end;

end;


procedure   TSoundsForm.SoundRadioButtonClick (Sender: TObject);
var
  B: Boolean;
  C: TColor;
begin
  B := (SoundWaveRadioButton.Enabled) and (SoundWaveRadioButton.Checked);
  SoundWaveEdit.Enabled := B;
  SoundWavePlayButton.Enabled := B;
  SoundWaveBrowseButton.Enabled := B;
  if B then C := clWindow else C := clBtnFace;
  SoundWaveEdit.Color := C;
end;


procedure   TSoundsForm.SetNewCall (aCall: String);
var
  I: Integer;
begin
  FCall := aCall;
  for I := 0 to High (SoundEntries) do begin
    SoundEntries[I].Loaded := false;
  end;
  EventComboBoxChange (nil);
end;


procedure   TSoundsForm.Save;
var
  I: Integer;
  E: PEntry;
  Signal: TSignalType;
  SignalWavFile: String;
  Announcement: TAnnouncementType;

begin

  EventComboBoxChange (nil);

  for I := 0 to High (SoundEntries) do begin

    E := @SoundEntries[I];

    if (E.Loaded) then begin

      if (E.SignalChecked) or (FGlobal) then begin
        Signal := E.Signal;
        if (FGlobal) and (Signal = st_undefined) then Signal := st_silence;
        SignalWavFile := E.SignalWavFile;
      end else begin
        Signal := st_undefined;
        SignalWavFile := '';
      end;

      if (E.AnnouncementChecked) or (FGlobal) then begin
        Announcement := E.Announcement;
        if (FGlobal) and (Announcement = at_undefined) then Announcement := at_silence;
      end else begin
        Announcement := at_undefined;
      end;

      if (Signal = st_undefined) and (Announcement = at_undefined) then begin
        Sounds.DeleteCall (FCall, E.Event);
      end else begin
        Sounds.Save (FCall, E.Event, Signal, SignalWavFile, Announcement);
      end;

    end;

  end;

end;


procedure   TSoundsForm.SoundCheckBoxClick (Sender: TObject);
var
  B: Boolean;
  E: PEntry;
  Signal: TSignalType;
  SignalWavFile: String;
  Announcement: TAnnouncementType;

begin

  B := SoundCheckBox.Checked;

  SoundNoneRadioButton.Enabled := B;
  SoundPCSpeakerRadioButton.Enabled := B;
  SoundWaveRadioButton.Enabled := B;

  if (Index >= 0) then begin

    E := @SoundEntries[Index];
    assert (assigned (E));

    if (B) then begin

      if (E.Signal = st_undefined) then begin
        Sounds.Load ('', E.Event, E.Signal, E.SignalWavFile, Announcement);
      end;

      if (E.Signal = st_pcspk) then begin
        SoundPCSpeakerRadioButton.Checked := true;
      end else if (E.Signal = st_wave) then begin
        SoundWaveRadioButton.Checked := true;
      end else begin
        SoundNoneRadioButton.Checked := true;
      end;
      SoundWaveEdit.Text := E.SignalWavFile;

    end else begin

      SaveSound;

      Sounds.Load ('', E.Event, Signal, SignalWavFile, Announcement);

      if (Signal = st_pcspk) then begin
        SoundPCSpeakerRadioButton.Checked := true;
      end else if (Signal = st_wave) then begin
        SoundWaveRadioButton.Checked := true;
      end else begin
        SoundNoneRadioButton.Checked := true;
      end;
      SoundWaveEdit.Text := SignalWavFile;

    end;

    E.SignalChecked := B;

  end;

  SoundRadioButtonClick (nil);

end;


procedure   TSoundsForm.AnnouncementCheckBoxClick (Sender: TObject);
var
  B: Boolean;
  E: PEntry;
  Signal: TSignalType;
  SignalWavFile: String;
  Announcement: TAnnouncementType;

begin

  B := AnnouncementCheckBox.Checked and AnnouncementCheckBox.Enabled;

  AnnouncementNoneRadioButton.Enabled := B;
  AnnouncementVoiceRadioButton.Enabled := false;
  AnnouncementTelegraphyRadioButton.Enabled := false;

  if (Index >= 0) then begin

    E := @SoundEntries[Index];
    assert (assigned (E));

    if (B) then begin

      if (E.Announcement = at_undefined) then begin
        Sounds.Load ('', E.Event, Signal, SignalWavFile, E.Announcement);
      end;

      if (E.Announcement = at_voice) then begin
        AnnouncementVoiceRadioButton.Checked := true;
      end else if (E.Announcement = at_cw) then begin
        AnnouncementTelegraphyRadioButton.Checked := true;
      end else begin
        AnnouncementNoneRadioButton.Checked := true;
      end;


    end else begin

      SaveAnnouncement;

      Sounds.Load ('', E.Event, Signal, SignalWavFile, Announcement);

      if (E.Announcement = at_voice) then begin
        AnnouncementVoiceRadioButton.Checked := true;
      end else if (E.Announcement = at_cw) then begin
        AnnouncementTelegraphyRadioButton.Checked := true;
      end else begin
        AnnouncementNoneRadioButton.Checked := true;
      end;

    end;

    E.AnnouncementChecked := B;

  end;

end;


procedure   TSoundsForm.SoundWaveBrowseButtonClick (Sender: TObject);
resourcestring
  SOpenDialogFilter = 'Klang-Dateien (*.wav)|*.wav|Alle Dateien (*)|*.*';
  SOpenDialogTitle = 'Klang auswählen...';
var
  OpenDialog: TOpenDialog;
begin
  try
    OpenDialog := TOpenDialog.create (self);
    try
      OpenDialog.DefaultExt := '';
      OpenDialog.FileName := '';
      OpenDialog.Filter := SOpenDialogFilter;
      OpenDialog.FilterIndex := 1;
      OpenDialog.Options := [ofEnableSizing, ofHideReadOnly];
      OpenDialog.Title := SOpenDialogTitle;
      OpenDialog.InitialDir := ExtractFilePath (Forms.Application.ExeName) + 'Sound';
      if (OpenDialog.Execute) then begin
        SoundWaveEdit.Text := OpenDialog.FileName;
      end;
    finally
      OpenDialog.free;
    end;
  finally
    Enabled := true;
  end;
end;


procedure   TSoundsForm.SoundWavePlayButtonClick (Sender: TObject);
var
  S: String;
begin
  S := SoundWaveEdit.Text;
  if (Length (S) > 0) then begin
    PlaySound (PChar(S), 0, SND_ASYNC or SND_FILENAME or SND_NODEFAULT);
  end;
end;


procedure   TSoundsForm.SchemeLoadButtonClick (Sender: TObject);
resourcestring
  SLoadDialogTitle = 'Schema laden';

const
  MethodName = 'MethodName';
  Section = 'Paxon Sound Scheme';

var
  I, J: Integer;
  E: PEntry;
  Ini: TIniFile;
  OpenDialog: TOpenDialog;
  B: Boolean;
  FileName: String;
  FilePath: String;
  S: String;
  SL: TStringList;

begin

  OpenDialog := TOpenDialog.create (MainWindow);
  try
    OpenDialog.DefaultExt := 'pxs';
    OpenDialog.FileName := '';
    OpenDialog.Filter := SLoadSaveDialogFilter;
    OpenDialog.FilterIndex := 1;
    OpenDialog.Options := [ofEnableSizing, ofHideReadOnly];
    OpenDialog.Title := SLoadDialogTitle;
    // User-defined sound schemes are in the application data folder, the supplied ones in the program folder
    S := ApplicationDataPath + 'Sound';
    if (not DirectoryExists (S)) then S := ExtractFilePath (Forms.Application.ExeName) + 'Sound';
    OpenDialog.InitialDir := S;
    B := (OpenDialog.Execute);
    FileName := OpenDialog.FileName;
  finally
    OpenDialog.Free;
  end;

  if (B) then begin

    Index := -1;
    EventComboBoxChange (nil);

    SL := TStringList.create;
    SL.Delimiter := ',';
    SL.QuoteChar := '"';

    FilePath := ExtractFilePath (FileName);

    Ini := TIniFile.create (FileName);
    try

      for I := 0 to High (SoundEntries) do begin

        E := @SoundEntries[I];
        assert (assigned (E));

        S := Trim (Ini.ReadString (Section, Format ('%2.2d', [SoundEvents(E.Event).ID]), ''));

        if (S = '') then begin

          E.SignalChecked := false;
          E.Signal := st_silence;

        end else begin

          if (S[1] in ['0'..'9']) and (S[2] = ',') then begin

            SL.DelimitedText := S;
            for J := SL.Count + 1 to 2 do SL.Add ('');

            if SL[0] = '1' then begin
              E.Signal := st_wave;
            end else if SL[0] = '2' then begin
              E.Signal := st_pcspk;
            end else begin
              E.Signal := st_silence;
            end;

            if (Length (SL[1]) > 0) then begin
              S := IncludeTrailingPathDelimiter (FilePath) + SL[1];
              S := ExpandFileName (S);
            end else begin
              S := '';
            end;

            E.SignalWavFile := S;

          end else begin

            S := IncludeTrailingPathDelimiter (FilePath) + S;
            S := ExpandFileName (S);

            E.SignalChecked := false;
            E.Signal := st_wave;
            E.SignalWavFile := S;

          end;

        end;

        E.Loaded := true;

      end;

    finally
      Ini.free;
    end;

    SL.free;

    Index := -1;
    EventComboBoxChange (nil);

  end;

end;


procedure   TSoundsForm.SchemeSaveButtonClick (Sender: TObject);
resourcestring
  SSaveDialogTitle = 'Schema speichern';

const
  Section = 'Paxon Sound Scheme';

var
  I: Integer;
  E: PEntry;
  Ini: TIniFile;
  SaveDialog: TSaveDialog;
  B: Boolean;
  FileName: String;
  FilePath: String;
  S: String;
  SL: TStringList;

begin

  SaveDialog := TSaveDialog.create (MainWindow);
  try
    SaveDialog.DefaultExt := 'pxs';
    SaveDialog.FileName := '';
    SaveDialog.Filter := SLoadSaveDialogFilter;
    SaveDialog.FilterIndex := 1;
    SaveDialog.Options := [ofEnableSizing, ofHideReadOnly];
    SaveDialog.Title := SSaveDialogTitle;
    // The program folder is not writable without administrator rights
    SaveDialog.InitialDir := ApplicationDataPath + 'Sound';
    ForceDirectories (SaveDialog.InitialDir);
    B := (SaveDialog.Execute);
    FileName := SaveDialog.FileName;
  finally
    SaveDialog.Free;
  end;

  if (B) then begin

    FilePath := ExtractFilePath (FileName);

    Ini := TIniFile.create (FileName);
    try

      EventComboBoxChange (nil);

      SL := TStringList.create;
      SL.Delimiter := ',';
      SL.QuoteChar := '"';

      for I := 0 to High (SoundEntries) do begin

        SL.Clear;

        E := @SoundEntries[I];
        assert (assigned (E));

        if (not E.Loaded) then begin
          Sounds.Load (FCall, E.Event, E.Signal, E.SignalWavFile, E.Announcement);
          E.SignalChecked := (E.Signal <> st_undefined);
          E.AnnouncementChecked := (E.Announcement <> at_undefined);
          E.Loaded := true;
        end;

        if (E.SignalChecked) or (FGlobal) then begin

          case E.Signal of
            st_wave: S := '1';
            st_pcspk: S := '2';
            else S := '0';
          end;

          SL.Add (S);

          S := E.SignalWavFile;
          if (S <> '') then S := ExtractRelativePath (FilePath, S);

          SL.Add (S);

          Ini.WriteString (Section, Format ('%2.2d', [SoundEvents(E.Event).ID]), SL.CommaText);

        end;

      end;

      SL.free;

    finally
      Ini.free;
    end;

  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

