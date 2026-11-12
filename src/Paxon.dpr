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


program Paxon;

{$R 'Resources-Global.res' 'Resources-Global.rc'}
{$R 'Resources-Local.res' 'Resources-Local.rc'}

uses
  Forms,
  SysUtils,
  ActiveX,
  ConnectCommandU in 'ConnectCommandU.pas' {DlgConnectCommand},
  CommandU in 'CommandU.pas' {DlgCommand},
  BinSplitPartU in 'BinSplitPartU.pas',
  BoxListU in 'BoxListU.pas',
  CheckInstanceU in 'CheckInstanceU.pas',
  ConfigU in 'ConfigU.pas',
  ConnectionsListU in 'ConnectionsListU.pas',
  CrcU in 'CrcU.pas',
  ReceiveFilePostprocessorU in 'ReceiveFilePostprocessorU.pas',
  SendFileDlgU in 'SendFileDlgU.pas' {SendFileDlg},
  SendFilePreprocessorU in 'SendFilePreprocessorU.pas',
  SendFileQueueU in 'SendFileQueueU.pas',
  SendFilePartsSelectionDlgU in 'SendFilePartsSelectionDlgU.pas' {SendFilePartsSelectionDlg},
  SendFileU in 'SendFileU.pas',
  SendFileTemplatesDlgU in 'SendFileTemplatesDlgU.pas' {SendFileTemplatesDlg},
  SendFileTemplatesU in 'SendFileTemplatesU.pas',
  OverwriteAppendFileFormU in 'OverwriteAppendFileFormU.pas' {OverwriteAppendFileForm},
  DebOutU in 'DebOutU.pas',
  DropTargetU in 'DropTargetU.pas',
  GeneralSettingsU in 'GeneralSettingsU.pas' {GeneralSettings},
  DisplaySettingsU in 'DisplaySettingsU.pas' {DisplaySettings},
  FileSettingsU in 'FileSettingsU.pas' {FileSettings},
  ExtendedSettingsU in 'ExtendedSettingsU.pas' {ExtendedSettings},
  DeviceSettingsU in 'DeviceSettingsU.pas' {DeviceSettings},
  AddDeviceU in 'AddDeviceU.pas' {AddDeviceForm},
  SoundSettingsU in 'SoundSettingsU.pas' {SoundSettings},
  MonitorSettingsU in 'MonitorSettingsU.pas' {MonitorSettings},
  RemoteCommandSettingsU in 'RemoteCommandSettingsU.pas' {RemoteCommandSettings},
  CallsignSettingsU in 'CallsignSettingsU.pas' {CallsignSettingsForm},
  TextSettingsU in 'TextSettingsU.pas' {TextSettings},
  SettingsU in 'SettingsU.pas' {SettingsForm},
  FileStreamUlfU in 'FileStreamUlfU.pas',
  FlexnetApiU in 'FlexnetApiU.pas',
  FormU in 'FormU.pas',
  RadioChannelU in 'RadioChannelU.pas',
  DeviceStatusU in 'DeviceStatusU.pas' {DevicesStatus},
  DevicesU in 'DevicesU.pas',
  FlexnetDeviceSettingsU in 'FlexnetDeviceSettingsU.pas' {FlexnetDeviceSettingsForm},
  FlexnetDeviceU in 'FlexnetDeviceU.pas',
  HostmodeSerialDeviceSettingsU in 'HostmodeSerialDeviceSettingsU.pas' {HostmodeSerialDeviceSettingsForm},
  HostmodeSerialDeviceU in 'HostmodeSerialDeviceU.pas',
  HostmodeDeviceStatisticsU in 'HostmodeDeviceStatisticsU.pas',
  HostmodeTFWinDeviceSettingsU in 'HostmodeTFWinDeviceSettingsU.pas' {HostmodeTFWinDeviceSettingsForm},
  HostmodeTFWinDeviceU in 'HostmodeTFWinDeviceU.pas',
  HostmodeDeviceU in 'HostmodeDeviceU.pas',
  DeviceU in 'DeviceU.pas',
  GlobalU in 'GlobalU.pas',
  MainU in 'MainU.pas' {MainWindow},
  HintU in 'HintU.pas',
  InfoU in 'InfoU.pas' {DlgInfo},
  InterfacesU in 'InterfacesU.pas',
  ChannelsU in 'ChannelsU.pas',
  ChannelU in 'ChannelU.pas',
  SoundsConstsU in 'SoundsConstsU.pas',
  SoundsFormU in 'SoundsFormU.pas' {SoundsForm},
  SoundsPCSpkU in 'SoundsPCSpkU.pas',
  SoundsU in 'SoundsU.pas',
  MD5U in 'MD5U.pas',
  MessageboxU in 'MessageboxU.pas' {DlgMessage},
  MyCallsU in 'MyCallsU.pas',
  MyCallU in 'MyCallU.pas',
  FolderU in 'FolderU.pas',
  PGPApiU in 'PGPApiU.pas',
  PGPClassU in 'PGPClassU.pas',
  PublisherU in 'PublisherU.pas',
  QueueU in 'QueueU.pas',
  RegexU in 'RegexU.pas',
  RemoteCommandsFormU in 'RemoteCommandsFormU.pas' {RemoteCommandsForm},
  RemoteCommandsU in 'RemoteCommandsU.pas',
  SplashU in 'SplashU.pas' {DlgSplash},
  LanguagesFormU in 'LanguagesFormU.pas' {LanguagesForm},
  LanguagesRestartFormU in 'LanguagesRestartFormU.pas' {LanguagesRestartForm},
  LanguagesU in 'LanguagesU.pas',
  LanguagesVersionFormU in 'LanguagesVersionFormU.pas' {LanguagesVersionForm},
  SsidIteratorU in 'SsidIteratorU.pas',
  StationDatabaseDlgU in 'StationDatabaseDlgU.pas' {StationDatabaseDlg},
  StationDatabaseEditDlgU in 'StationDatabaseEditDlgU.pas' {StationDatabaseEditDlg},
  StationDatabaseEntryU in 'StationDatabaseEntryU.pas',
  StationDatabasePasswordDlgU in 'StationDatabasePasswordDlgU.pas' {StationDatabasePasswordDlg},
  StationDatabaseProgressU in 'StationDatabaseProgressU.pas' {StationDatabaseProgressForm},
  StationDatabaseU in 'StationDatabaseU.pas',
  StatusU in 'StatusU.pas',
  SynchronizeU in 'SynchronizeU.pas',
  TextsConstsU in 'TextsConstsU.pas',
  TextsFormU in 'TextsFormU.pas' {TextsForm},
  TextsU in 'TextsU.pas',
  UnhandledExceptionU in 'UnhandledExceptionU.pas' {DlgUnhandledException},
  Connection7PlusReceiveU in 'Connection7PlusReceiveU.pas',
  ConnectionAbstractU in 'ConnectionAbstractU.pas',
  ConnectionAutobinReceiveU in 'ConnectionAutobinReceiveU.pas',
  ConnectionAutobinSendU in 'ConnectionAutobinSendU.pas',
  ConnectionDidaditReceiveBlockListU in 'ConnectionDidaditReceiveBlockListU.pas',
  ConnectionDidaditReceiveU in 'ConnectionDidaditReceiveU.pas',
  ConnectionDidaditSendU in 'ConnectionDidaditSendU.pas',
  ConnectionDidaditU in 'ConnectionDidaditU.pas',
  ConnectionGoTextReceiveU in 'ConnectionGoTextReceiveU.pas',
  ConnectionStandardU in 'ConnectionStandardU.pas',
  ConnectionTextSendU in 'ConnectionTextSendU.pas',
  ConnectionU in 'ConnectionU.pas',
  PGPCheckU in 'PGPCheckU.pas',
  ColorButtonUlfU in 'VCL\paxon\src\ColorButtonUlfU.pas',
  ComboBoxUlfU in 'VCL\paxon\src\ComboBoxUlfU.pas',
  ConsoleU in 'VCL\paxon\src\ConsoleU.pas',
  DragTextU in 'VCL\paxon\src\DragTextU.pas',
  ListView4StateCheckU in 'VCL\paxon\src\ListView4StateCheckU.pas',
  MemoUlfU in 'VCL\paxon\src\MemoUlfU.pas',
  MLCBRB in 'VCL\paxon\src\MLCBRB.PAS',
  PageControlUlf in 'VCL\paxon\src\PageControlUlf.pas',
  PanelUlfU in 'VCL\paxon\src\PanelUlfU.pas',
  RicheditPaxonU in 'VCL\paxon\src\RicheditPaxonU.pas';

{$R *.RES}


begin

  // Initialize the main thread for COM/OLE (ShellExecute, structured storage of the
  // station database, drag & drop). Previously ComObj did this as a side effect via ComServ.
  OleInitialize (nil);

  try
    Forms.Application.Initialize;
    Forms.Application.UpdateFormatSettings := false;
    Forms.Application.UpdateMetricSettings := false;
    Forms.Application.ShowMainForm := false;
    Forms.Application.Title := 'Paxon';
  except
    on E: Exception do begin
      ShowUnhandledException (E, 'PROJECT', 'INIT');
      raise;
    end;
  end;

  try
    Forms.Application.CreateForm(TMainWindow, MainWindow);
  except
    on E: Exception do begin
      ShowUnhandledException (E, 'PROJECT', 'CREATEFORM');
      raise;
    end;
  end;

  try
    Forms.Application.Run;
  except
    on E: Exception do begin
      ShowUnhandledException (E, 'PROJECT', 'RUN');
      raise;
    end;
  end;

end.

