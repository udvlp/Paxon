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


unit SettingsU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, FormU, PanelUlfU, GlobalU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TTabForm = class (TFormUlf)
  public
    procedure   ApplyPage; virtual;
    procedure   CancelPage; virtual;
  end;


  TTabFormClass = class of TTabForm;


  TSettingsForm = class (TFormUlf)

    PageControl: TPageControl;

    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;

    FormOkBtn: TButton;
    FormCancelBtn: TButton;
    FormApplyBtn: TButton;
    TabSheet8: TTabSheet;
    TabSheet9: TTabSheet;

    procedure   FormCreate (Sender: TObject);
    procedure   FormDestroy (Sender: TObject);
    procedure   FormOkBtnClick (Sender: TObject);
    procedure   FormApplyBtnClick (Sender: TObject);
    procedure   PageControlChange (Sender: TObject);
    procedure   PageControlChanging (Sender: TObject; var AllowChange: Boolean);
    procedure   FormCancelBtnClick (Sender: TObject);
    procedure   FormClose (Sender: TObject; var Action: TCloseAction);
    procedure   FormShortCut (var Msg: TWMKey; var Handled: Boolean);

  private

    TabForm: array [0..8] of TTabForm;
    InChange: Boolean;
    ClosingWithOk: Boolean;
    function     InitTab (Index: Integer): TControl;

  end;


var
  Settings: TSettingsForm;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


{$R *.DFM}


uses
  DebOutU, DevicesU, MainU, ChannelsU, FolderU, ConfigU,
  GeneralSettingsU, DisplaySettingsU, DeviceSettingsU,
  FileSettingsU, MonitorSettingsU, ExtendedSettingsU,
  SoundSettingsU, TextSettingsU, RemoteCommandSettingsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  TabFormClass: array [0..8] of TTabFormClass = (TGeneralSettings,
                                                 TDeviceSettings,
                                                 TFileSettings,
                                                 TDisplaySettings,
                                                 TMonitorSettings,
                                                 TTextSettings,
                                                 TRemoteCommandSettings,
                                                 TSoundSettings,
                                                 TExtendedSettings);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TTabForm.ApplyPage;
begin
  // do nothing
end;


procedure   TTabForm.CancelPage;
begin
  // do nothing
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TSettingsForm.FormCreate (Sender: TObject);
var
  I: Integer;

begin

  inherited;

  InChange := false;
  ClosingWithOk := false;

  for I := Low(TabForm) to High (TabForm) do TabForm[I] := nil;

  InitTab (0);
  PageControl.ActivePage := PageControl.Pages[0];

end;


function    TSettingsForm.InitTab (Index: Integer): TControl;
var
  N, I: Integer;
  A: Array of TControl;
  Tab: TTabSheet;

begin

  result := nil;

  if (not assigned (TabForm[Index])) then begin

    Tab := PageControl.Pages[Index];

    Tab.DisableAlign;

    TabForm[Index] := TabFormClass[Index].create (self);

    TabForm[Index].ClientWidth  := Tab.ClientWidth;
    TabForm[Index].ClientHeight := Tab.ClientHeight;

    Forms.Application.HandleMessage;

    result := TabForm[Index].FindNextControl (nil, true, true, false);

    {$IFDEF VER140} MainWindow.ThemeManager.CollectControls (TabForm[Index]); {$ENDIF}

    N := TabForm[Index].ControlCount;
    SetLength (A, N);

    for I := 0 to N - 1 do begin
      A[I] := TabForm[Index].Controls[I] as TControl;
    end;

    for I := 0 to N - 1 do begin
      A[I].Parent := Tab;
    end;

    Tab.EnableAlign;

  end;

end;


procedure   TSettingsForm.FormClose (Sender: TObject; var Action: TCloseAction);
var
  I: Integer;
begin
  // Closed without OK (Cancel, close box, program end): discard pending changes
  // that the pages have already handed to live objects (e.g. device parameters)
  if (not ClosingWithOk) then begin
    for I := Low (TabForm) to High (TabForm) do begin
      if (assigned (TabForm[I])) then begin
        TabForm[I].CancelPage;
      end;
    end;
  end;
  Action := caFree;
  Settings := nil;
end;


procedure   TSettingsForm.FormDestroy (Sender: TObject);
const
  MethodName = 'FormDestroy';
var
  I: Integer;
begin
  DebOut (self, MethodName, 'begin...');
  for I := Low (TabForm) to High (TabForm) do begin
    if (assigned (TabForm[I])) then begin
      TabForm[I].Free;
      TabForm[I] := nil;
    end;
  end;
  inherited;
  DebOut (self, MethodName, 'end.');
end;


procedure   TSettingsForm.FormOkBtnClick (Sender: TObject);
begin
  FormApplyBtnClick (Sender);
  ClosingWithOk := true;
  Close;
end;


procedure   TSettingsForm.FormCancelBtnClick (Sender: TObject);
begin
  Close;
end;


procedure   TSettingsForm.FormApplyBtnClick (Sender: TObject);
var
  I: Integer;
begin
  for I := Low (TabForm) to High (TabForm) do begin
    if assigned (TabForm[I]) then begin
      TabForm[I].ApplyPage;
    end;
  end;
end;


procedure   TSettingsForm.PageControlChanging (Sender: TObject; var AllowChange: Boolean);
begin
  AllowChange := true;
end;


procedure   TSettingsForm.PageControlChange (Sender: TObject);
var
  T: TTabSheet;
  I: Integer;
  C: TControl;

begin

  if InChange then begin
    abort;
  end;

  InChange := true;
  try

    T := PageControl.ActivePage;

    if (assigned (T)) then begin

      I := T.PageIndex;

      if (I >= 0) then begin

        C := InitTab (I);
        if (assigned (C)) and (C is TWinControl) then begin
          with TWinControl(C) do begin
            try
              if CanFocus and Visible then SetFocus;
            except
            end;
          end;
        end;

      end;
    end;

  finally
    InChange := false;
  end;

end;


procedure   TSettingsForm.FormShortCut (var Msg: TWMKey; var Handled: Boolean);
begin
  Handled := (Msg.CharCode = VK_MENU);
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


initialization

  Settings := nil;

end.

