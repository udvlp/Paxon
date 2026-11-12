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


unit MainU;


interface


uses
  Windows, Messages, SysUtils, Classes, Forms,
  Dialogs, StdCtrls, Graphics, ActiveX,
  ComCtrls, ExtCtrls, Menus, AppEvnts, ActnList, ImgList, Controls,
  FormU, ToolbarU,
  CheckInstanceU, GlobalU, InterfacesU, DevicesU, ChannelsU, ChannelU,
  UnhandledExceptionU, MessageboxU, RicheditPaxonU, QueueU, SplashU, ConfigU,
  MyCallsU, FolderU, StationDatabaseU,
  SettingsU, Gauges, PanelUlfU,
  TBXStatusBars, ShellApi;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


const
  wm_DebugMonitor = WM_USER + $4091;

type

  TMainWindow = class (TFormUlf)

    ActionClearConsole: TAction;
    ActionConnect: TAction;
    ActionDeviceStatus: TAction;
    ActionDisconnect: TAction;
    ActionShowDosUmlauts: TAction;
    ActionSendDosUmlauts: TAction;
    ActionEnd: TAction;
    ActionHelpInfo: TAction;
    ActionLanguage: TAction;
    ActionList: TActionList;
    ActionMacro: TAction;
    ActionSave: TAction;
    ActionSend: TAction;
    ActionSettings: TAction;
    ActionStationDatabase: TAction;
    ActionAddStations: TAction;
    ActionStop: TAction;
    ApplicationEvents: TApplicationEvents;
    OutputPanel: TPanelUlf;
    ClientPanel: TPanelUlf;
    EditorGutterLine: TShape;
    EditorGutterPanel: TPanel;
    InputPanel: TPanelUlf;
    MonitorPanel: TPanelUlf;
    ResizePanel1: TPanelUlf;
    ResizePanel2: TPanelUlf;
    TBDock1: TToolbarDock;
    GutterImages: TImageList;
    ActionHint: TAction;
    ActionEditCut: TAction;
    ActionEditCopy: TAction;
    ActionEditPaste: TAction;
    ActionEditDelete: TAction;
    ActionEditSelectAll: TAction;
    Statusbar: TTBXStatusBar;
    ProgressLabel: TLabel;
    Progressbar: TGauge;
    MainMenuBar: TPaxonToolbar;
    MenuFile: TToolbarSubmenu;
    MenuEdit: TToolbarSubmenu;
    MenuView: TToolbarSubmenu;
    MenuTools: TToolbarSubmenu;
    MenuStations: TToolbarSubmenu;
    MenuHelp: TToolbarSubmenu;
    ToolBar: TPaxonToolbar;
    TBItem6: TToolbarElement;
    TBItem7: TToolbarElement;
    TBItem8: TToolbarElement;
    TBItem9: TToolbarElement;
    TBItem10: TToolbarElement;
    TBItem13: TToolbarElement;
    TBItem15: TToolbarElement;
    TBItem16: TToolbarElement;
    TBItem17: TToolbarElement;
    TBItem19: TToolbarElement;
    TBItem26: TToolbarElement;
    ChannelStateImages: TImageList;
    PanelUlf1: TPanel;
    PanelUlf2: TPanelUlf;
    ResizeDock2: TToolbarDock;
    PanelUlf3: TPanel;
    PanelUlf4: TPanel;
    ChannelToolbar: TPaxonToolbar;
    MenuConnect: TToolbarSubmenu;
    TBSeparatorItem4: TToolbarSeparator;
    TBSeparatorItem5: TToolbarSeparator;
    ActionToolbarNoText: TAction;
    ActionToolbarTextRight: TAction;
    ActionToolbarTextBottom: TAction;
    ActionLocalEcho: TAction;
    ActionPactorChangeover: TAction;
    ActionPactorBreakin: TAction;
    TBSeparatorItem3a: TToolbarSeparator;
    TBSeparatorItem3b: TToolbarSeparator;
    TBXItem1: TToolbarElement;
    ActionRepairStationDatabase: TAction;
    ActionBoxRead: TAction;
    ActionBoxErase: TAction;
    ActionBoxUncheck: TAction;
    ActionBoxRun: TAction;
    ImageList: TImageList;
    ActionHelpContents: TAction;
    TBXItem2: TToolbarElement;
    MenuConnectPactor: TToolbarSubmenu;
    TBXItem4: TToolbarElement;
    TBXSeparatorItem1: TToolbarSeparator;
    ActionPrint: TAction;
    TBXSeparatorItem3: TToolbarSeparator;
    TBXItem3: TToolbarElement;
    StatusbarDeviceImage: TImage;

    procedure   ActionConnectExecute (Sender: TObject);
    procedure   ActionDeviceStatusExecute (Sender: TObject);
    procedure   ActionDisconnectExecute (Sender: TObject);
    procedure   ActionShowDosUmlautsExecute (Sender: TObject);
    procedure   ActionSendDosUmlautsExecute (Sender: TObject);
    procedure   ActionEditCopyExecute (Sender: TObject);
    procedure   ActionEditCutExecute (Sender: TObject);
    procedure   ActionEditDeleteExecute (Sender: TObject);
    procedure   ActionEditPasteExecute (Sender: TObject);
    procedure   ActionEditSelectAllExecute (Sender: TObject);
    procedure   ActionEndExecute (Sender: TObject);
    procedure   ActionHelpInfoExecute (Sender: TObject);
    procedure   ActionHintExecute (Sender: TObject);
    procedure   ActionLanguageExecute (Sender: TObject);
    procedure   ActionSaveExecute (Sender: TObject);
    procedure   ActionSendExecute (Sender: TObject);
    procedure   ActionSettingsExecute (Sender: TObject);
    procedure   ActionStationDatabaseExecute (Sender: TObject);
    procedure   ActionStopExecute (Sender: TObject);
    procedure   ApplicationEventsShowHint (var HintStr: String; var CanShow: Boolean; var HintInfo: THintInfo);
    procedure   ApplicationException (Sender: TObject; E: Exception);
    procedure   ClientPanelResize (Sender: TObject);
    procedure   FormCloseQuery (Sender: TObject; var CanClose: Boolean);
    procedure   FormCreate (Sender: TObject);
    procedure   FormDestroy (Sender: TObject);
    procedure   FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure   FormShortCut (var Msg: TWMKey; var Handled: Boolean);
    procedure   ProgressBarMouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure   ResizeDock2Resize (Sender: TObject);
    procedure   ResizePanel1Resize (Sender: TObject);
    procedure   ResizePanel2Resize (Sender: TObject);
    procedure   ResizePanel1MouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure   ResizePanel1MouseMove (Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure   ResizePanel2MouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure   ResizePanel2MouseMove (Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure   ResizePanel1MouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure   ResizePanel2MouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure   ActionClearConsoleExecute (Sender: TObject);
    procedure   ActionToolbarNoTextExecute (Sender: TObject);
    procedure   ActionToolbarTextRightExecute (Sender: TObject);
    procedure   ActionToolbarTextBottomExecute (Sender: TObject);
    procedure   FormActivate (Sender: TObject);
    procedure   FormDeactivate (Sender: TObject);
    procedure   ActionLocalEchoExecute (Sender: TObject);
    procedure   ActionPactorChangeoverExecute (Sender: TObject);
    procedure   ActionPactorBreakinExecute (Sender: TObject);
    procedure   ActionRepairStationDatabaseExecute (Sender: TObject);
    procedure   ApplicationEventsActivate (Sender: TObject);
    procedure   ActionBoxReadExecute (Sender: TObject);
    procedure   ActionBoxEraseExecute (Sender: TObject);
    procedure   ActionBoxUncheckExecute (Sender: TObject);
    procedure   ActionBoxRunExecute (Sender: TObject);
    procedure   ActionHelpContentsExecute (Sender: TObject);
    procedure   ActionPrintExecute (Sender: TObject);

  private

    MinimumSize, SizeValue: TPoint;
    MousePoint: TPoint;
    DlgSplash: TDlgSplash;

    FOutputHeight: Integer;
    OutputMinHeight: Integer;
    InputMinHeight: Integer;
    MonitorMinHeight: Integer;
    ResizeMinHeight: Integer;

    FDevicesReady: Boolean;
    FResizePanel2Height: Integer;
    FResizePanel1Height: Integer;

    FIsReady: Boolean;

    MouseClipRect: TRect;

    ResizeHandlingEnabled: Boolean;

    WasDirty: Boolean;
    StartupError: Boolean;

    PaxonDestroyed: Boolean;

    procedure   PaxonDestroy;

    procedure   wmActivateInstance (var Msg: TMessage); message wm_activate_instance;
    procedure   wmDebugMonitor (var Msg: TMessage); message wm_debugmonitor;
    procedure   wmEndSession (var Msg: TMessage); message wm_endsession;
    procedure   wmGetMinMaxInfo (var Msg: TMessage); message wm_getminmaxinfo;
    procedure   wmEraseBkgnd (var Msg: TMessage); message wm_erasebkgnd;
    procedure   wmSyscommand (var Msg: TMessage); message wm_Syscommand;
    procedure   FontInit;
    procedure   FontDeinit;
    procedure   DestroyKeyHintWindow;
    procedure   ClipMouse (const R: TRect); overload;
    procedure   ClipMouse; overload;
    procedure   CheckClip (var P: TPoint);

    procedure   SetOutputHeight(const Value: Integer);
    property    OutputHeight: Integer read FOutputHeight write SetOutputHeight;

    procedure   ShowFatalError (S: String);


  public

    KeyHintWindow: THintWindow;

    procedure   AfterConstruction; override;
    procedure   CreateParams (var Params: TCreateParams); override;

    procedure   SetStatus (N: Integer; const S: String);
    property    Status[N: Integer]: String write SetStatus;

    procedure   DevicesReady (B: Boolean);

    property    IsReady: Boolean read FIsReady;
    procedure   ImageListInit;

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var
  MainWindow: TMainWindow;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}
{$R WinXP.res}

uses
  DebOutU, StationDatabaseDlgU, InfoU, CommandU, ConnectCommandU,
  DeviceStatusU, PGPClassU, Commctrl, Registry, MultiMon,
  ReceiveFilePostprocessorU, SoundsU, SoundsConstsU,
  TextsU, TextsConstsU, DropTargetU, LanguagesU,
  RemoteCommandsU, ConnectionsListU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TMainWindow.CreateParams (var Params: TCreateParams);
begin
  inherited;
  with Params do begin
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
  end;
end;


procedure   TMainWindow.AfterConstruction;
begin
  FIsReady := false;
  PaxonDestroyed := false;
  inherited;
end;


procedure   TMainWindow.FormCreate (Sender: TObject);
resourcestring
  SInitFonts = 'Initialisiere Schriften...';
  SInitStations = 'Initialisiere Datenbank...';
  SInitChannels = 'Initialisiere Kanäle...';
  SInitDevices = 'Initialisiere Geräte...';
  SReady = 'Bereit.';
  SErrorDatabase = 'Fehler beim Öffnen der Datenbank. (%s)';

var
  N, I, K: Integer;
  Registry: TRegistry;
  ScreenR: TRect;
  R, RM: TRect;
  S: string;
  HasError: Boolean;
  Mon: HMonitor;
  MonInfo: TMonitorInfo;
  C1, C2: TColor;

begin

  Forms.Application.OnException := ApplicationException;

  Randomize;

  ResizeHandlingEnabled := false;

  DlgSplash := nil;

  HasError := false;
  StartupError := false;

  Application.HintPause      :=   500;
  Application.HintShortPause :=   100;
  Application.HintHidePause  := 20000;

  Caption := WindowCaptionName;
  Forms.Application.Title := WindowCaptionName;

  Config := TConfig.create;

  WasDirty := Config.Dirty;
  Config.Dirty := true;

  ImageListInit;

  Folders := TFolder.create;

  TDropTarget.create;

  Registry := TRegistry.Create (KEY_READ or KEY_WRITE);

  MinimumSize.X := 340;
  MinimumSize.Y := 280;

  SystemParametersInfo (SPI_GETWORKAREA, 0, @ScreenR, 0);

  FResizePanel1Height := ResizePanel1.Height;
  FResizePanel2Height := ResizePanel2.Height;

  Registry.RootKey := HKEY_CURRENT_USER;

  if (Registry.OpenKey (RootRegKey + '\Windows\Main', true)) then begin

    try

      R.Left := Registry.ReadInteger ('X');
      R.Top := Registry.ReadInteger ('Y');
      R.Right := R.Left + Registry.ReadInteger ('DX');
      R.Bottom := R.Top + Registry.ReadInteger ('DY');

      Mon := MonitorFromRect (@R, MONITOR_DEFAULTTONEAREST);

      MonInfo.cbSize := sizeof (MonInfo);
      GetMonitorInfo (Mon, @MonInfo);

      RM := MonInfo.rcWork;

      if (R.Right - R.Left > RM.Right - RM.Left) then R.Right := R.Left + RM.Right - RM.Left;

      if (R.Bottom - R.Top > RM.Bottom - RM.Top) then R.Bottom := R.Top + RM.Bottom - RM.Top;

      I := R.Left - RM.Left;
      if (I < 0) then begin
        Dec (R.Left, I);
        Dec (R.Right, I);
      end;

      I := R.Top - RM.Top;
      if (I < 0) then begin
        Dec (R.Top, I);
        Dec (R.Bottom, I);
      end;

      I := R.Right - RM.Right;
      if (I > 0) then begin
        Dec (R.Left, I);
        Dec (R.Right, I);
      end;

      I := R.Bottom - RM.Bottom;
      if (I > 0) then begin
        Dec (R.Top, I);
        Dec (R.Bottom, I);
      end;

      BoundsRect := R;

    except

      Width := (ScreenR.Right - ScreenR.Left) * 2 div 3;
      Height := (ScreenR.Bottom - ScreenR.Top) * 2 div 3;
      Left := ScreenR.Left div 2 + ScreenR.Right div 2 - Width div 2;
      Top := ScreenR.Top div 2 + ScreenR.Bottom div 2 - Height div 2;

    end;

    try
      I := Registry.ReadInteger ('S');
    except
      I := 0;
    end;
    WindowState := TWindowState (I);

    Registry.CloseKey;

  end;

  Application.ProcessMessages;

  try
    if (Config.SplashScreen) then begin
      DlgSplash := TDlgSplash.Create (self);
      DlgSplash.Show;
      DlgSplash.Update;
      ProcessPaintMessages;
    end;
  except
    DlgSplash := nil;
  end;

  // App Paths under HKEY_CURRENT_USER (since Windows 7), so that no administrator rights are needed
  Registry.RootKey := HKEY_CURRENT_USER;
  if (Registry.OpenKey ('\Software\Microsoft\Windows\CurrentVersion\App Paths\' + ExtractFileName (Forms.Application.ExeName),
                        True)) then begin
    try
      S := Registry.ReadString ('');
    except
      S := '';
    end;
    if (CompareText (S, Forms.Application.ExeName) <> 0) then begin
      try
        Registry.WriteString ('', Forms.Application.ExeName);
      except
      end;
    end;
    Registry.CloseKey;
  end;

  TSounds.create;

  Sounds.PlayEvent (se_programstart);

  TTexts.create;

  TRemoteCommandManager.create;

  TConnectionsList.create;

  if (assigned (DlgSplash)) then DlgSplash.Status := SInitFonts;

  try
    FontInit;
  except
    on E: Exception do begin
      HasError := true;
      ShowFatalError (E.Message);
    end;
  end;

  if (not HasError) then begin

    MyCalls := TMyCallsInt.create;

    if (assigned (DlgSplash)) then DlgSplash.Status := SInitStations;

    try
      TStationDatabase.create (WasDirty or Config.ForceDatabaseCheck);
    except
      on E: Exception do begin
        HasError := true;
        ShowFatalError (Format (SErrorDatabase, [E.Message]));
        StationDatabase := nil;
      end;
    end;

  end;

  if (not HasError) then begin

    Config.ForceDatabaseCheck := false;

    if (assigned (DlgSplash)) then DlgSplash.Status := SInitChannels;

    TChannels.Create;

    MousePoint := Point (MaxInt, MaxInt);

    if (assigned (DlgSplash)) then DlgSplash.Status := SInitDevices;

    DeviceList := TDevices.Create;

    Registry.Free;

    if (assigned (DlgSplash)) then begin
      DlgSplash.Status := SReady;
      DlgSplash.Ready;
    end;

    FIsReady := true;

    EditorGutterPanel.Width := 13;

    if (HighColor) then begin

      C1 := ColorToRGB (clBtnShadow);
      C2 := ColorToRGB (clBtnFace);
      EditorGutterLine.Pen.Color := RGB (Trunc (GetRValue (C1) * 0.6 + GetRValue (C2) * 0.4),
                                         Trunc (GetGValue (C1) * 0.6 + GetGValue (C2) * 0.4),
                                         Trunc (GetBValue (C1) * 0.6 + GetBValue (C2) * 0.4));

      C1 := ColorToRGB (clBtnHighlight);
      C2 := ColorToRGB (clBtnFace);
      EditorGutterPanel.Color := RGB (Trunc (GetRValue (C1) * 0.8 + GetRValue (C2) * 0.2),
                                      Trunc (GetGValue (C1) * 0.8 + GetGValue (C2) * 0.2),
                                      Trunc (GetBValue (C1) * 0.8 + GetBValue (C2) * 0.2));

    end else begin

      EditorGutterPanel.Color := cl3DLight;
      EditorGutterLine.Pen.Color := cl3DDkShadow;

    end;

    ClientPanel.DisableAlign;
    OutputPanel.Align := alNone;
    ResizePanel1.Align := alNone;
    InputPanel.Align := alNone;
    ResizePanel2.Align := alNone;
    MonitorPanel.Align := alNone;
    ClientPanel.EnableAlign;

    OutputHeight := OutputPanel.Height;

    I := Config.MonitorHeight;
    if (I >= 4) and (I < Height) then begin
      N := MonitorPanel.Height - I;
      MonitorPanel.Top := MonitorPanel.Top + N;
      MonitorPanel.Height := MonitorPanel.Height - N;
      ResizePanel2.Top := ResizePanel2.Top + N;
      InputPanel.Top := InputPanel.Top + N;
      ResizePanel1.Top := ResizePanel1.Top + N;
      OutputHeight := OutputHeight + N;
    end;

    I := Config.InputHeight;
    if (I >= 4) and (I < Height - MonitorPanel.Height) then begin
      N := InputPanel.Height - I;
      InputPanel.Top := InputPanel.Top + N;
      InputPanel.Height := InputPanel.Height - N;
      ResizePanel1.Top := ResizePanel1.Top + N;
      OutputHeight := OutputHeight + N;
    end;

    ResizeHandlingEnabled := true;

    ClientPanelResize (nil);

    case Config.ToolbarText of
      0: ActionToolbarNoText.Execute;
      1: ActionToolbarTextRight.Execute;
      2: ActionToolbarTextBottom.Execute;
    end;

    for I := 0 to ToolBar.Items.Count - 1 do begin
      S := ToolBar.Items[I].Caption;
      N := Pos ('&', S);
      if (N >= 1) and (N < Length (S)) then begin
        ToolBar.Items[I].ShortCut := Ord (UpCase(S[N + 1])) + $8000;
        ToolBar.Items[I].Hint := ToolBar.Items[I].Hint + ' (' + ShortcutToText (ToolBar.Items[I].ShortCut) + ')';
      end;
    end;

    ResizeDock2Resize (ResizeDock2);

    Visible := true;

  end;

  if (HasError) then begin
    StartupError := true;
    Application.Terminate;
  end;

end;


procedure   TMainWindow.ShowFatalError (S: String);
begin
  if (assigned (DlgSplash)) then begin
    DlgSplash.Release;
    DlgSplash := nil;
  end;
  with TDlgMessage.create (self) do begin
    Run (ApplicationName, S, [mbOk]);
    Release;
  end;
end;


procedure   TMainWindow.FormDestroy (Sender: TObject);
begin
  PaxonDestroy;
  inherited;
end;


procedure   TMainWindow.PaxonDestroy;
var
  Registry: TRegistry;
  I: Integer;

begin

  // Runs on WM_ENDSESSION and once more afterwards in FormDestroy: clean up only once.
  if (PaxonDestroyed) then exit;
  PaxonDestroyed := true;

  if (assigned (Sounds)) and (not StartupError) then begin
    try
      Sounds.PlayEvent (se_programend);
    except
    end;
  end;

  try
    QuitEvent.SetEvent;
  except
  end;

  if (not StartupError) and (assigned (Config)) then begin

    try

      Config.MonitorHeight := MonitorPanel.Height;

      Config.InputHeight := InputPanel.Height;

      if (ActionToolbarTextRight.Checked) then begin
        I := 1;
      end else if (ActionToolbarTextBottom.Checked) then begin
        I := 2;
      end else begin
        I := 0;
      end;
      Config.ToolbarText := I;

      Registry := TRegistry.Create (KEY_READ or KEY_WRITE);
      try
        Registry.RootKey := HKEY_CURRENT_USER;
        if Registry.OpenKey (RootRegKey + '\Windows\Main', true) then begin
          try
            Registry.WriteInteger ('S', Ord (WindowState));
            WindowState := wsNormal;
            Application.RestoreTopMosts;
            Application.ProcessMessages;
            Registry.WriteInteger ('X', left);
            Registry.WriteInteger ('Y', top);
            Registry.WriteInteger ('DX', width);
            Registry.WriteInteger ('DY', height);
          except
          end;
          Registry.CloseKey;
        end;
      finally
        Registry.Free;
      end;

    except
    end;

  end;

  try
    RevokeDragDrop (Handle);
  except
  end;

  if (assigned (DeviceList)) then begin
    try
      DeviceList.Free;
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'DeviceList.Free');
      end;
    end;
    DeviceList := nil;
  end;

  if (assigned (ChannelList)) then begin
    try
      ChannelList.Free;
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'ChannelList.Free');
      end;
    end;
    ChannelList := nil;
  end;

  if (assigned (MyCalls)) then begin
    try
      MyCalls.Release;
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'MyCalls.Release');
      end;
    end;
    MyCalls := nil;
  end;

  if (assigned (Folders)) then begin
    try
      Folders.Free;
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'Folders.Free');
      end;
    end;
    Folders := nil;
  end;

  if (assigned (StationDatabase)) then begin
    try
      StationDatabase.free;
    except
      on E: Exception do begin
        ShowUnhandledException (E, ClassName, 'StationDatabase.Free');
      end;
    end;
    StationDatabase := nil;
  end;

  try
    Texts.Free;
  except
    on E: Exception do begin
      ShowUnhandledException (E, ClassName, 'Texts.Free');
    end;
  end;
  Texts := nil;

  try
    ConnectionsList.Free;
  except
    on E: Exception do begin
      ShowUnhandledException (E, ClassName, 'ConnectionsList.Free');
    end;
  end;
  ConnectionsList := nil;

  try
    Sounds.Free;
  except
    on E: Exception do begin
      ShowUnhandledException (E, ClassName, 'Sounds.Free');
    end;
  end;
  Sounds := nil;

  if (not StartupError) and (ErrorAddr = nil) and (assigned (Config)) then Config.Dirty := false;

  try
    Config.Free;
  except
    on E: Exception do begin
      ShowUnhandledException (E, ClassName, 'Config.Free');
    end;
  end;
  Config := nil;

  try
    FontDeinit;
  except
    on E: Exception do begin
      ShowUnhandledException (E, ClassName, 'FontDeInit');
    end;
  end;

end;


procedure   TMainWindow.wmActivateInstance (var Msg: TMessage);
begin
  Forms.Application.Restore;
  SetForegroundWindow (MainWindow.Handle);
  SetWindowPos (Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
  SetWindowPos (Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
end;


procedure   TMainWindow.ApplicationException (Sender: TObject; E: Exception);
begin
  ShowUnhandledException (E, ClassName);
end;


procedure   TMainWindow.ResizeDock2Resize (Sender: TObject);
var
  Y: Integer;
begin
  if (ResizeHandlingEnabled) then begin
    Y := ResizeDock2.Height;
    if (Y < 4) then Y := 4;
    if (ResizePanel2.Height <> Y) then ResizePanel2.Height := Y;
  end;
end;


procedure   TMainWindow.ResizePanel1Resize (Sender: TObject);
var
  dH: Integer;
begin
  if (ResizeHandlingEnabled) then begin
    ResizePanel1.Realign;
    dH := ResizePanel1.Height - FResizePanel1Height;
    if (dH <> 0) then begin
      ResizePanel1.Top := ResizePanel1.Top - dH;
      OutputHeight := OutputHeight - dH;
      FResizePanel1Height := ResizePanel1.Height;
    end;
  end;
end;


procedure   TMainWindow.ResizePanel2Resize (Sender: TObject);
var
  dH: Integer;
begin
  if (ResizeHandlingEnabled) then begin
    ResizePanel2.Realign;
    dH := ResizePanel2.Height - FResizePanel2Height;
    if (dH <> 0) then begin
      ResizePanel2.Top := ResizePanel2.Top - dH;
      InputPanel.Top := InputPanel.Top - dH;
      ResizePanel1.Top := ResizePanel1.Top - dH;
      OutputHeight := OutputHeight - dH;
      FResizePanel2Height := ResizePanel2.Height;
    end;
  end;
end;


procedure   TMainWindow.SetOutputHeight (const Value: Integer);
begin
  FOutputHeight := Value;
  if (FOutputHeight >= OutputMinHeight) then begin
    OutputPanel.Top := 0;
    OutputPanel.Height := OutputHeight;
  end else begin
    OutputPanel.Top := OutputHeight + OutputMinHeight;
    OutputPanel.Height := OutputMinHeight;
  end;
  OutputPanel.Realign;
end;


procedure   TMainWindow.ClientPanelResize (Sender: TObject);
const
  Method = 'ClientPanelResize';

var
  dB, dH: Integer;

begin

  if (ResizeHandlingEnabled) then begin

    with ClientPanel do begin

      if (SizeValue.X = 0) then begin

        SizeValue.X := ClientWidth;
        SizeValue.Y := ClientHeight;

        OutputMinHeight := 4;
        InputMinHeight := 16;
        MonitorMinHeight := 4;
        ResizeMinHeight  := 4;

      end else begin

        dB := ClientWidth - SizeValue.X;
        dH := ClientHeight - SizeValue.Y;

        OutputPanel.Width  := OutputPanel.Width  + dB;

        if (dH <> 0) then begin

          OutputHeight := OutputHeight + dH;

          ResizePanel1.Top    := ResizePanel1.Top    + dH;
          InputPanel.Top    := InputPanel.Top    + dH;
          ResizePanel2.Top    := ResizePanel2.Top    + dH;
          MonitorPanel.Top    := MonitorPanel.Top    + dH;

        end;

        ResizePanel1.Width  := ResizePanel1.Width  + dB;
        InputPanel.Width  := InputPanel.Width  + dB;
        ResizePanel2.Width  := ResizePanel2.Width  + dB;
        MonitorPanel.Width  := MonitorPanel.Width  + dB;

        SizeValue.X := ClientWidth;
        SizeValue.Y := ClientHeight;

      end;

    end;

  end;

end;


procedure   TMainWindow.wmGetMinMaxInfo (var Msg: TMessage);
begin
  PMinMaxInfo (Msg.lParam)^.ptMinTrackSize := MinimumSize;
end;


procedure   TMainWindow.ActionHintExecute (Sender: TObject);
begin
  DestroyKeyHintWindow;
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    ChannelList.CurrentChannel.DoShowHint;
  end;
end;


procedure   TMainWindow.FormKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
var
  I: Integer;

begin

  DestroyKeyHintWindow;

  ChannelList.CurrentChannel.KeyDown (Key, Shift);

  if (Key in [vk_f1..vk_f10]) and
     ((Shift = []) or (Shift = [ssShift]) or (Shift = [ssCtrl]) or (Shift = [ssShift, ssCtrl])) then begin

    if (assigned (ChannelList)) then begin
      I := (Key - vk_f1 + 1);
      if (ssShift in Shift) then inc (I, 10);
      if (ssCtrl in Shift) then inc (I, 20);
      if (I <= ChannelList.Quantity) then ChannelList.CurrentChannelNo := I;
      Key := 0;
    end;

  end else if (Key = vk_f12) then begin

    if (assigned (ChannelList)) then begin
      ChannelList.CurrentChannelNo := 0;
      Key := 0;
    end;

  end else if (Key = vk_escape) and (Shift = []) then begin

    with TDlgCommand.Create (self) do begin
      ShowModal;
      Release;
    end;
    Key := 0;

  end;

  inherited;

end;


procedure   TMainWindow.FormShortCut (var Msg: TWMKey; var Handled: Boolean);
begin
  Handled := false;
end;


procedure   TMainWindow.DestroyKeyHintWindow;
begin
  if (assigned (KeyHintWindow)) then begin
    KeyHintWindow.free;
    KeyHintWindow := nil;
  end;
end;


procedure   TMainWindow.ActionSettingsExecute (Sender: TObject);
begin
  try
    if (not assigned (Settings)) then begin
      Settings := TSettingsForm.Create (self);
    end;
  except
    Settings := nil;
  end;
  if (assigned (Settings)) then begin
    Settings.Show;
  end;
end;


procedure   TMainWindow.ActionEndExecute (Sender: TObject);
begin
  Close;
end;


procedure   TMainWindow.ActionConnectExecute (Sender: TObject);
var
  Dialog: TDlgConnectCommand;
begin
  Application.ProcessMessages;
  Dialog := TDlgConnectCommand.Create (self);
  try
    Dialog.ShowModal;
  finally
    Dialog.Release;
  end;
end;


procedure   TMainWindow.ActionDisconnectExecute (Sender: TObject);
var
  ChannelRef: IChannel;
  PacketConnection: IConnection;
begin
  if (assigned (ChannelList)) then begin
    ChannelRef := ChannelList.CurrentChannel;
    if (assigned (ChannelRef)) then begin
      ConnectionsList.Lock;
      try
        PacketConnection := ChannelRef.PacketConnection;
      finally
        ConnectionsList.Unlock;
      end;
      if (assigned (PacketConnection)) then begin
        PacketConnection.Disconnect;
      end;
    end;
  end;
end;


procedure   TMainWindow.ActionHelpContentsExecute (Sender: TObject);
begin
  ShellExecute(0, 'OPEN', PChar('https://www.paxon.app/help.html?ver=' + Version), '', '', SW_SHOWNORMAL);
end;


procedure   TMainWindow.ActionHelpInfoExecute (Sender: TObject);
var
  Dialog: TDlgInfo;
begin
  Dialog := TDlgInfo.Create (self);
  if (assigned (Dialog)) then begin
    Dialog.ShowModal;
    Dialog.Release;
  end;
end;


procedure   TMainWindow.ResizePanel1MouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
  O, U: Integer;
begin
  if (Button = mbLeft) then begin
    SetCaptureControl (Sender as TControl);
    ResizePanel1.Color := clHighlight;
    MousePoint := (Sender as TCustomControl).ClientToScreen (Point (X, Y));
    O := Y + OutputPanel.ClientToScreen (Point (0, 0)).Y + OutputMinHeight - 2;
    U := Y + MonitorPanel.ClientToScreen (Point (0, MonitorPanel.Height)).Y - ResizePanel2.Height - InputMinHeight -
         ResizePanel1.Height - MonitorMinHeight - 1;
    R := Rect (Left, O, Left + Width, U);
    ClipMouse (R);
  end;
end;


procedure   TMainWindow.ResizePanel2MouseDown (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
  O, U: Integer;
begin
  if (Button = mbLeft) then begin
    SetCaptureControl (Sender as TControl);
    ResizePanel2.Color := clHighlight;
    ResizeDock2.Color := clHighlight;
    MousePoint := (Sender as TCustomControl).ClientToScreen (Point (X, Y));
    O := Y + OutputPanel.ClientToScreen (Point (0, 0)).Y + ResizePanel1.Height + InputMinHeight + OutputMinHeight - 2;
    U := Y + MonitorPanel.ClientToScreen (Point (0, MonitorPanel.Height)).Y - 5 - ResizePanel2.Height;
    R := Rect (Left, O, Left + Width, U);
    ClipMouse (R);
  end;
end;


procedure   TMainWindow.ResizePanel1MouseMove (Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  DY: Integer;
  P: TPoint;
  N: Integer;

begin

  if (MousePoint.X <> MaxInt) then begin

    P := ResizePanel1.ClientToScreen (Point (X, Y));

    CheckClip (P);

    DY := P.Y - MousePoint.Y;

    if (DY <> 0) then begin

      if InputPanel.Height - DY >= InputMinHeight then begin
        InputPanel.Height  := InputPanel.Height - DY;
      end else begin
        N := InputMinHeight - InputPanel.Height;
        if N <> 0 then begin
          InputPanel.Height  := InputPanel.Height + N;
          ResizePanel2.Top     := ResizePanel2.Top    + N;
          MonitorPanel.Top     := MonitorPanel.Top    + N;
          MonitorPanel.Height  := MonitorPanel.Height - N;
        end;
        ResizePanel2.Top     := ResizePanel2.Top    + DY;
        MonitorPanel.Top     := MonitorPanel.Top    + DY;
        MonitorPanel.Height  := MonitorPanel.Height - DY;
      end;
      InputPanel.Top     := InputPanel.Top     + DY;
      ResizePanel1.Top     := ResizePanel1.Top     + DY;
      OutputHeight        := OutputHeight  + DY;

    end;

    MousePoint := P;

  end;

end;


procedure   TMainWindow.ResizePanel2MouseMove (Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  DY: Integer;
  P: TPoint;
  N: Integer;

begin

  if (MousePoint.X <> MaxInt) then begin

    P := ResizePanel2.ClientToScreen (Point (X, Y));

    CheckClip (P);

    DY := P.Y - MousePoint.Y;

    if (DY <> 0) then begin

      if (OutputHeight + DY >= OutputMinHeight) then begin
        OutputHeight        := OutputHeight + DY;
        ResizePanel1.Top     := ResizePanel1.Top    + DY;
        InputPanel.Top     := InputPanel.Top    + DY;
      end else begin
        N := OutputMinHeight - OutputHeight;
        if (N <> 0) then begin
          OutputHeight        := OutputHeight + N;
          ResizePanel1.Top     := ResizePanel1.Top    + N;
          InputPanel.Top     := InputPanel.Top    + N;
          InputPanel.Height  := InputPanel.Height - N;
        end;
        InputPanel.Height := InputPanel.Height + DY;
      end;
      ResizePanel2.Top     := ResizePanel2.Top    + DY;
      MonitorPanel.Top     := MonitorPanel.Top    + DY;
      MonitorPanel.Height  := MonitorPanel.Height - DY;

    end;

    MousePoint := P;

  end;

end;


procedure   TMainWindow.ResizePanel1MouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then begin
    SetCaptureControl (nil);
    ClipMouse;
    ResizePanel1.ParentColor := true;
    MousePoint.X := MaxInt;
  end;
end;


procedure TMainWindow.ResizePanel2MouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then begin
    SetCaptureControl (nil);
    ClipMouse;
    ResizePanel2.ParentColor := true;
    ResizeDock2.Color := clNone;
    ResizeDock2.BackgroundOnToolbars := true;
    MousePoint.X := MaxInt;
  end;
end;


procedure   TMainWindow.ActionSendExecute(Sender: TObject);
begin
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    ChannelList.CurrentChannel.SendFileDialog;
  end;
end;


procedure   TMainWindow.ActionSaveExecute (Sender: TObject);
begin
  Application.ProcessMessages;
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    ChannelList.CurrentChannel.SaveChannelText;
  end;
end;


procedure   TMainWindow.ActionBoxReadExecute (Sender: TObject);
var
  ChannelRef: IChannel;
begin
  ChannelRef := ChannelList.CurrentChannel;
  if (assigned (ChannelRef)) then ChannelRef.BoxRead (false, false);
end;


procedure   TMainWindow.ActionBoxEraseExecute (Sender: TObject);
var
  ChannelRef: IChannel;
begin
  ChannelRef := ChannelList.CurrentChannel;
  if (assigned (ChannelRef)) then ChannelRef.BoxErase (false, false);
end;


procedure   TMainWindow.ActionBoxUncheckExecute (Sender: TObject);
var
  ChannelRef: IChannel;
begin
  ChannelRef := ChannelList.CurrentChannel;
  if (assigned (ChannelRef)) then ChannelRef.BoxUncheck (false);
end;


procedure   TMainWindow.ActionBoxRunExecute (Sender: TObject);
var
  ChannelRef: IChannel;
begin
  ChannelRef := ChannelList.CurrentChannel;
  if (assigned (ChannelRef)) then ChannelRef.BoxRun;
end;


procedure   TMainWindow.ActionDeviceStatusExecute (Sender: TObject);
begin
  if (assigned (DevicesStatus)) then begin
    DevicesStatus.Release;
  end else begin
    DevicesStatus := TDevicesStatus.create (self);
    DevicesStatus.Show;
  end;
end;


procedure   TMainWindow.DevicesReady (B: Boolean);
resourcestring
  SHintReady = 'Alle Geräte sind bereit|';
  SHintNotReady = 'Ein Gerät ist nicht bereit|';
begin
  if (B <> FDevicesReady) then begin
    if B then begin
      StatusbarDeviceImage.Picture.Bitmap.LoadFromResourceName (HInstance, 'DeviceStatus2');
      StatusbarDeviceImage.Hint := SHintNotReady;
    end else begin
      StatusbarDeviceImage.Picture.Bitmap.LoadFromResourceName (HInstance, 'DeviceStatus1');
      StatusbarDeviceImage.Hint := SHintReady;
    end;
    FDevicesReady := B;
  end;
end;


procedure   TMainWindow.SetStatus (N: Integer; const S: String);
begin
  assert ((N >= 0) and (N <= 9));
  Statusbar.Panels.Items[N].Caption := S;
end;


procedure   TMainWindow.wmDebugMonitor (var Msg: TMessage);
begin
  if (Msg.wParam = 0) then begin
    DebOutHandle := 0;
  end else begin
    DebOutHandle := Msg.wParam;
  end;
end;


procedure   TMainWindow.FormCloseQuery (Sender: TObject; var CanClose: Boolean);
begin
  CanClose := true;
end;


procedure   TMainWindow.wmEndSession (var Msg: TMessage);
begin
  if (Msg.WParam <> 0) then PaxonDestroy;
  Msg.Result := 0;
end;


procedure   TMainWindow.wmEraseBkgnd (var Msg: TMessage);
begin
  Msg.Result := 1;
end;


procedure   TMainWindow.ProgressBarMouseUp (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Beep;
end;


procedure   TMainWindow.ActionStationDatabaseExecute (Sender: TObject);
begin
  Application.ProcessMessages;
  try
    if (not assigned (StationDatabaseDlg)) then begin
      StationDatabaseDlg := TStationDatabaseDlg.Create (self);
    end;
  except
    on E: Exception do begin
      StationDatabaseDlg := nil;
      ShowUnhandledException (E, ClassName, 'ActionStationDatabaseExecute');
    end;
  end;
  if (assigned (StationDatabaseDlg)) then begin
    StationDatabaseDlg.Show;
  end;
end;


procedure   TMainWindow.ActionRepairStationDatabaseExecute (Sender: TObject);
resourcestring
  SDatabaseRepair = 'Die Datenbank wird beim nächsten Start von Paxon repariert und optimiert.';
begin
  with TDlgMessage.create (self) do begin
    if (Run (ApplicationName, SDatabaseRepair, [mbOk, mbCancel]) = mrOk) then begin
      Config.ForceDatabaseCheck := true;
    end;
    Release;
  end;
end;


procedure   TMainWindow.ActionStopExecute (Sender: TObject);
var
  PacketConnection: IConnection;
begin
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    PacketConnection := ChannelList.CurrentChannel.PacketConnection;
    if (assigned (PacketConnection)) then begin
      PacketConnection.CancelTransfer;
    end;
  end;
end;


procedure   TMainWindow.ImageListInit;
var
  bmp: HBitmap;

begin

  if (HighColor and Config.HighColor) then begin

    ImageList.Handle := ImageList_Create (16, 16, ILC_COLOR8 or ILC_MASK, 4, 4);
    bmp := LoadImage (HInstance, 'ToolbarSmallHigh', IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
    ImageList_AddMasked (ImageList.Handle, bmp, RGB (255, 0, 255));
    DeleteObject (bmp);

    GutterImages.Handle := ImageList_Create (8, 9, ILC_COLOR8 or ILC_MASK, 4, 4);
    bmp := LoadImage (HInstance, 'ConsoleHigh', IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
    ImageList_AddMasked (GutterImages.Handle, bmp, RGB (255, 0, 255));
    DeleteObject (bmp);

    ChannelStateImages.Handle := ImageList_Create (10, 13, ILC_COLOR8 or ILC_MASK, 4, 4);
    bmp := LoadImage (HInstance, 'ChannelStateHigh', IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
    ImageList_AddMasked (ChannelStateImages.Handle, bmp, RGB (255, 0, 255));
    DeleteObject (bmp);

  end else begin

    ImageList.Handle := ImageList_LoadImage (HInstance, 'ToolbarSmall', 16, 4, RGB (255, 0, 255), IMAGE_BITMAP, 0);
    GutterImages.Handle := ImageList_LoadImage (HInstance, 'Console', 8, 4, RGB (255, 0, 255), IMAGE_BITMAP, 0);
    ChannelStateImages.Handle := ImageList_LoadImage (HInstance, 'ChannelState', 10, 4, RGB (255, 0, 255), IMAGE_BITMAP, 0);

  end;

end;


procedure   TMainWindow.ActionShowDosUmlautsExecute (Sender: TObject);
var
  B: Boolean;
begin
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    B := not ChannelList.CurrentChannel.ShowDOSUmlauts;
    ChannelList.CurrentChannel.ShowDOSUmlauts := B;
    ActionShowDosUmlauts.Checked := B;
  end;
end;


procedure   TMainWindow.ActionSendDosUmlautsExecute (Sender: TObject);
var
  B: Boolean;
begin
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    B := not ChannelList.CurrentChannel.SendDOSUmlauts;
    ChannelList.CurrentChannel.SendDOSUmlauts := B;
    ActionSendDosUmlauts.Checked := B;
  end;
end;


procedure   TMainWindow.ActionClearConsoleExecute(Sender: TObject);
resourcestring
  SClearConsole = 'Ausgabefenster löschen?';
  SClearConsoleTitle = 'Paxon';

begin
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    with TDlgMessage.create (self) do begin
      try
        if (Run (SClearConsoleTitle, SClearConsole, [mbYes, mbNo]) = mrYes) then begin
          ChannelList.CurrentChannel.ClrScr;
        end;
      finally
        Release;
      end;
    end;
  end;
end;


procedure   TMainWindow.FontInit;
resourcestring
  SCanNotLoadRequiredFile = 'Die erforderliche Datei "%s" kann nicht geladen werden.';

var
  FontPath: String;
  I, N: Integer;

begin

  FontPath := ChangeFileExt (Application.ExeName, '.fon');

  for I := 1 to 10 do begin
    N := AddFontResource (PChar(FontPath));
    if (N > 0) then break;
    RemoveFontResource (PChar(FontPath));
  end;
  if (N <= 0) then begin
    raise Exception.Create (Format (SCanNotLoadRequiredFile, [ExtractFilename (FontPath)]));
  end;

end;


procedure   TMainWindow.FontDeinit;
var
  FontPath: String;
  I: Integer;
  N: LongBool;
begin
  FontPath := ChangeFileExt (Application.ExeName, '.fon');
  for I := 1 to 10 do begin
    N := RemoveFontResource (PChar(FontPath));
    if (N) then break;
  end;
end;


procedure   TMainWindow.ApplicationEventsShowHint (var HintStr: String; var CanShow: Boolean; var HintInfo: THintInfo);
begin
  DestroyKeyHintWindow;
end;


procedure   TMainWindow.wmSyscommand (var Msg: TMessage);
begin
  DestroyKeyHintWindow;
  inherited;
end;


procedure   TMainWindow.ActionLanguageExecute (Sender: TObject);
begin
  TLanguageList.SelectLanguage (true);
end;


procedure   TMainWindow.ActionEditCutExecute (Sender: TObject);
var
  K: IChannel;
begin
  if (Active) then begin
    if (assigned (ChannelList)) then K := ChannelList.CurrentChannel else K := nil;
    if (assigned (K)) then begin
      K.EditCut;
    end;
  end else begin
    Abort;
  end;
end;


procedure   TMainWindow.ActionEditCopyExecute (Sender: TObject);
var
  K: IChannel;
begin
  if (Active) then begin
    if (assigned (ChannelList)) then K := ChannelList.ActionChannel else K := nil;
    if (assigned (K)) then begin
      K.EditCopy;
    end;
  end else begin
    Abort;
  end;
end;


procedure   TMainWindow.ActionEditPasteExecute (Sender: TObject);
var
  K: IChannel;
begin
  if (Active) then begin
    if (assigned (ChannelList)) then K := ChannelList.CurrentChannel else K := nil;
    if (assigned (K)) then begin
      K.EditPaste;
    end;
  end else begin
    Abort;
  end;
end;


procedure   TMainWindow.ActionEditDeleteExecute (Sender: TObject);
var
  K: IChannel;
begin
  if (Active) then begin
    if (assigned (ChannelList)) then K := ChannelList.CurrentChannel else K := nil;
    if (assigned (K)) then begin
      K.EditDelete;
    end;
  end else begin
    Abort;
  end;
end;


procedure   TMainWindow.ActionEditSelectAllExecute (Sender: TObject);
var
  K: IChannel;
begin
  if (Active) then begin
    if (assigned (ChannelList)) then K := ChannelList.CurrentChannel else K := nil;
    if (assigned (K)) then begin
      K.EditSelectAll;
    end;
  end else begin
    Abort;
  end;
end;


procedure   TMainWindow.ClipMouse (const R: TRect);
begin
  MouseClipRect := R;
  ClipCursor (@R);
end;


procedure   TMainWindow.ClipMouse;
begin
  MouseClipRect := Rect (0, 0, MaxInt, MaxInt);
  ClipCursor (nil);
end;


procedure   TMainWindow.CheckClip (var P: TPoint);
begin

  if (P.Y < MouseClipRect.Top) then begin
    P.Y := MouseClipRect.Top
  end else if (P.Y > MouseClipRect.Bottom) then begin
    P.Y := MouseClipRect.Bottom;
  end;

  if (P.X < MouseClipRect.Left) then begin
    P.X := MouseClipRect.Left;
  end else if (P.X > MouseClipRect.Right) then begin
    P.X := MouseClipRect.Right;
  end;

end;


procedure   TMainWindow.ActionToolbarNoTextExecute (Sender: TObject);
var
  I: Integer;
begin
  Toolbar.BeginUpdate;
  try
    Toolbar.ImageOverText := false;
    for I := 0 to ToolBar.Items.Count - 1 do begin
      ToolBar.Items[I].DisplayMode := anStandard;
    end;
  finally
    Toolbar.EndUpdate;
  end;
end;


procedure   TMainWindow.ActionToolbarTextRightExecute (Sender: TObject);
var
  I: Integer;
begin
  Toolbar.BeginUpdate;
  try
    Toolbar.ImageOverText := false;
    for I := 0 to ToolBar.Items.Count - 1 do begin
      ToolBar.Items[I].DisplayMode := anImageAndText;
    end;
  finally
    Toolbar.EndUpdate;
  end;
end;


procedure   TMainWindow.ActionToolbarTextBottomExecute (Sender: TObject);
var
  I: Integer;
begin
  Toolbar.BeginUpdate;
  try
    Toolbar.ImageOverText := true;
    for I := 0 to ToolBar.Items.Count - 1 do begin
      ToolBar.Items[I].DisplayMode := anImageAndText;
    end;
  finally
    Toolbar.EndUpdate;
  end;
end;


procedure   TMainWindow.ActionLocalEchoExecute (Sender: TObject);
var
  V: IConnection;
begin
  ActionLocalEcho.Checked := not ActionLocalEcho.Checked;
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    V := ChannelList.CurrentChannel.PacketConnection;
    if (assigned (V)) then begin
      V.LocalEcho := ActionLocalEcho.Checked;
    end;
  end;
end;


procedure   TMainWindow.ActionPactorChangeoverExecute (Sender: TObject);
var
  K: IChannel;
begin
  if (assigned (ChannelList)) then K := ChannelList.CurrentChannel else K := nil;
  if (assigned (K)) then begin
    K.PactorChangeOver;
  end;
end;


procedure   TMainWindow.ActionPactorBreakinExecute (Sender: TObject);
var
  K: IChannel;
begin
  if (assigned (ChannelList)) then K := ChannelList.CurrentChannel else K := nil;
  if (assigned (K)) then begin
    K.PactorBreakIn;
  end;
end;


procedure   TMainWindow.FormActivate (Sender: TObject);
begin
  Toolbar.ProcessShortCuts := true;
end;


procedure   TMainWindow.FormDeactivate (Sender: TObject);
begin
  Toolbar.ProcessShortCuts := false;
end;


procedure   TMainWindow.ApplicationEventsActivate (Sender: TObject);
begin
  if (assigned (ChannelList)) and (assigned (ChannelList.CurrentChannel)) then begin
    if (not ChannelList.CurrentChannel.IsSendFileDialogActive) then ChannelList.CurrentChannel.ActivateChannel (true);
  end;
end;


procedure   TMainWindow.ActionPrintExecute (Sender: TObject);
var
  ChannelRef: IChannel;
begin
  ChannelRef := ChannelList.CurrentChannel;
  ChannelRef.Print;
end;


end.

