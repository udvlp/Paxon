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


unit InterfacesU;


interface


uses
  Windows, Classes, Syncobjs, Graphics, comctrls, Buttons, ActiveX,
  QueueU, GlobalU, PublisherU, SoundsConstsU,
  TextsConstsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  IRadioChannel = interface;
  IConnection = interface;
  IConnectionForModule = interface;
  IConnectionAbstract = interface;
  ISendFile = interface;
  ISendFileQueue = interface;
  IRemoteCommands = interface;


  TConnectionStatus = (vs_disconnected,
                        vs_disconnect,
                        vs_connect,
                        vs_connected);


  TPasswordKind = (pa_user,
                  pa_sysop);


  TPasswordMethod = (pv_baycom,
                        pv_md5,
                        pv_diebox);


  TConnectError = (vf_ok,
                     vf_unknown,
                     vf_devicetimeout,
                     vf_nodevice,
                     vf_channelalreadyconnected,
                     vf_nossid,
                     vf_deviceerror,
                     vf_nofreechannel,
                     vf_notsimultaneous);


  TIncomingConnect = (ic_default,
                      ic_accept,
                      ic_ignore,
                      ic_busy);


  TSendFileProtocol = (prot_unknown, prot_text, prot_autobin, prot_7plus,
                           prot_binary, prot_didadit);


  TMonitorFrame = record
    Device: Integer;
    Port: Integer;
    Src: String;
    Dest: String;
    Digis: String;
    PID: Byte;
    FrameType: Byte;
    RXSeq: Byte;
    TXSeq: Byte;
    Command: Boolean;
    PollFinal: Boolean;
    Dama: Boolean;
    TxDel: Byte;
    Sent: Boolean;
    Text: String;
  end;


  TDisconnectLevel = (dl_none, dl_end, dl_ended, dl_cancel, dl_canceled, dl_kill, dl_killed);


  TDisplayType = (dt_status, dt_receive, dt_send, dt_pgp);


  TDisconnectReason = (dr_normal, dr_linkfailure, dr_busy);


  IChannel = interface ['{4E73C222-11F3-11D2-8BDC-00A0243DC10A}']

    function    IsIncomingConnectionPossible: Boolean;
    function    IsOutgoingConnectionPossible: Boolean;
    function    IsChannelConnected: Boolean;

    procedure   ActivateChannel (B: Boolean);

    function    GetPacketConnection: IConnection;
    property    PacketConnection: IConnection read GetPacketConnection;

    procedure   SetFont (F: TFont);
    property    Font: TFont write SetFont;

    procedure   KeyDown (var Key: Word; Shift: TShiftState);
    procedure   Monitor (const aHeader: string; const aText: string; Sent: Boolean);
    function    WriteOutput (aTextColor: Integer; const aText: String): Integer;

    procedure   SendFileDialog; overload;
    procedure   SendFileDialog (const aFiles: array of String); overload;
    procedure   SendFileDialog (const aText: String); overload; overload;

    procedure   SendFileDialogDone;

    function    GetIsReserved: Boolean;
    procedure   SetIsReserved (const Value: Boolean);
    property    IsReserved: Boolean read GetIsReserved write SetIsReserved;

    procedure   Release;
    procedure   SaveChannelText;

    procedure   SetShowDOSUmlauts (const Value: Boolean);
    function    GetShowDOSUmlauts: Boolean;
    property    ShowDOSUmlauts: Boolean read GetShowDOSUmlauts write SetShowDOSUmlauts;

    procedure   SetSendDOSUmlauts (const Value: Boolean);
    function    GetSendDOSUmlauts: Boolean;
    property    SendDOSUmlauts: Boolean read GetSendDOSUmlauts write SetSendDOSUmlauts;

    function    GetNo: Integer;
    property    No: Integer read GetNo;

    procedure   EditCut;
    procedure   EditCopy;
    procedure   EditPaste;
    procedure   EditDelete;
    procedure   EditSelectAll;

    procedure   BoxRead (Toggle: Boolean; Down: Boolean);
    procedure   BoxErase (Toggle: Boolean; Down: Boolean);
    procedure   BoxUncheck (Down: Boolean);
    procedure   BoxRun;

    procedure   StatusChanged;
    procedure   UpdateColors;

    procedure   ClrScr;

    function    GetHint: String;
    property    Hint: String read GetHint;

    procedure   DoShowHint;

    procedure   PactorChangeOver;
    procedure   PactorBreakIn;

    procedure   SetConsoleRows (const Value: Cardinal);
    property    ConsoleRows: Cardinal write SetConsoleRows;

    function    IsSendFileDialogActive: Boolean;

    procedure   Print;

  end;


  IChannelForConnection = interface (ISubscriber) ['{4E73C223-11F3-11D2-8BDC-00A0243DC10A}']

    procedure   Release;
    function    GetStatus: TConnectionStatus;
    procedure   SetStatus (aStatus: TConnectionStatus);
    property    Status: TConnectionStatus read GetStatus write SetStatus;
    procedure   Display (const aText: String; aType: TDisplayType);
    procedure   Prompt (const aText: String; aType: TDisplayType);
    function    ReceiveTextData (const aText: String): Integer;
    procedure   SendTextData (const aText: String);
    procedure   ConnectionEstablished;
    procedure   EstablishConnection (aConnectionObj: IConnection);
    procedure   Disconnected (Reason: TDisconnectReason);
    procedure   Restored;
    procedure   CallChange;
    procedure   CanCancelChanged;
    procedure   Notify (P: Pointer);
    function    GetNo: Integer;
    property    No: Integer read GetNo;
    procedure   SetBoxListLine (const Line: Integer);

  end;


  IRadioChannel = interface ['{4E73C224-11F3-11D2-8BDC-00A0243DC10A}']
    function    GetName: String;
    procedure   SetName (S: String);
    property    Name: String read GetName write SetName;
    procedure   SetHandle (aHandle: Integer);
    function    GetHandle: Integer;
    property    Handle: Integer read GetHandle write SetHandle;
    function    EstablishConnection (var aCall: String; var aMyCall: String; var aChannelObj: IChannel): TConnectError; overload;
    function    IsFlexNet: Boolean;
    function    GetID: String;
    procedure   SetID (const Value: String);
    property    ID: String read GetID write SetID;
    function    SendUI (aDestination, aMyCall, aText: String): Boolean;
  end;


  IStationDatabaseEntry = interface ['{C3793260-1CF9-11D2-8BDC-00A0243DC10A}']

    function    GetCall: String;
    property    Call: String read GetCall;

    procedure   SetName (const Value: String);
    function    GetName: String;
    property    Name: String read GetName write SetName;

    procedure   SetNotes (const Value: String);
    function    GetNotes: String;
    property    Notes: String read GetNotes write SetNotes;

    procedure   SetStationType (const Value: TStationType);
    function    GetStationType: TStationType;
    property    StationType: TStationType read GetStationType write SetStationType;

    procedure   SetIncomingConnect (const Value: TIncomingConnect);
    function    GetIncomingConnect: TIncomingConnect;
    property    IncomingConnect: TIncomingConnect read GetIncomingConnect write SetIncomingConnect;

    procedure   SetPasswordValue (const aMycall: string; aPasswordKind: TPasswordKind; aPasswordMethod: TPasswordMethod;
                                  aPasswordStr: String);
    function    GetPasswordValue (const aMycall: string; aPasswordKind: TPasswordKind;
                                  aPasswordMethod: TPasswordMethod): String; overload;
    function    GetPasswordValue (const StreamName: string): String; overload;
    function    DeletePassword (const StreamName: string): String; overload;

    function    GetStorage: IStorage;
    procedure   SetStorage (const Value: IStorage);
    property    Storage: IStorage read GetStorage write SetStorage;

    procedure   GetSoundEvent (Event: TSoundEvent; var Signal: TSignalType; var SignalWavFile: String;
                               var Announcement: TAnnouncementType);
    function    SetSoundEvent (Event: TSoundEvent; Signal: TSignalType; const SignalWavFile: String;
                               Announcement: TAnnouncementType): Boolean;
    procedure   DeleteSoundEvent (Event: TSoundEvent);

    procedure   GetText (TextKind: TTextKind; var Text: String; var DefaultTextBefore: Boolean);
    function    SetText (TextKind: TTextKind; const Text: String; const DefaultTextBefore: Boolean): Boolean;
    procedure   DeleteText (TextKind: TTextKind);

    function    GetRemoteCommand (const aCommand: String; var State: Boolean): Boolean;
    procedure   SetRemoteCommand (const aCommand: String; const State: Boolean);
    procedure   DeleteRemoteCommand (const aCommand: String);

  end;


  TEventEnum = (e_finish,
                e_cancel,
                e_abort,
                e_threaddied,
                e_threadterminated,
                e_receivedata,
                e_senddata,
                e_sendingpossible,
                e_sendfile);


  TUserEventEnum = e_receivedata..High (TEventEnum);


  IStatus = interface ['{FCC7013F-5885-473A-A155-1A59034C8B80}']

    procedure   Release;

    function    GetChannelRef: IChannel;
    procedure   SetChannelRef (const Value: IChannel);
    property    ChannelRef: IChannel read GetChannelRef write SetChannelRef;

    function    GetUnack: Integer;
    procedure   SetUnack (const Value: Integer);
    property    Unack: Integer read GetUnack write SetUnack;
    function    GetUnackChanged: Boolean;
    property    UnackChanged: Boolean read GetUnackChanged;

    function    GetTries: Integer;
    procedure   SetTries (const Value: Integer);
    property    Tries: Integer read GetTries write SetTries;
    function    GetTriesChanged: Boolean;
    property    TriesChanged: Boolean read GetTriesChanged;

    function    GetFrack: Integer;
    procedure   SetFrack (const Value: Integer);
    property    Frack: Integer read GetFrack write SetFrack;
    function    GetFrackChanged: Boolean;
    property    FrackChanged: Boolean read GetFrackChanged;

    function    GetMaxframe: Integer;
    procedure   SetMaxframe (const Value: Integer);
    property    Maxframe: Integer read GetMaxframe write SetMaxframe;
    function    GetMaxframeChanged: Boolean;
    property    MaxframeChanged: Boolean read GetMaxframeChanged;

    function    GetAx25state: Integer;
    procedure   SetAx25state (const Value: Integer);
    property    Ax25state: Integer read GetAx25state write SetAx25state;
    function    GetAx25stateChanged: Boolean;
    property    Ax25stateChanged: Boolean read GetAx25stateChanged;

    function    GetEffectiveBaudrate: Integer;
    procedure   SetEffectiveBaudrate (const Value: Integer);
    property    EffectiveBaudrate: Integer read GetEffectiveBaudrate write SetEffectiveBaudrate;
    function    GetEffectiveBaudrateChanged: Boolean;
    property    EffectiveBaudrateChanged: Boolean read GetEffectiveBaudrateChanged;

  end;


  IConnection = interface ['{4E73C225-11F3-11D2-8BDC-00A0243DC10A}']

    function    GetCall: String;
    procedure   SetCall (const Value: String);
    property    Call: String read GetCall write SetCall;

    function    GetMyCall: String;
    procedure   SetMyCall (const Value: String);
    property    MyCall: String read GetMyCall write SetMyCall;

    function    GetDigis: String;
    procedure   SetDigis (const Value: String);
    property    Digis: String read GetDigis write SetDigis;

    function    GetPath: String;
    procedure   SetPath (const Value: String);
    property    Path: String read GetPath write SetPath;

    function    GetRealPath: String;
    procedure   SetRealPath (const Value: String);
    property    RealPath: String read GetRealPath write SetRealPath;

    function    GetHandle: Integer;
    procedure   SetHandle (Value: Integer);
    property    Handle: Integer read GetHandle write SetHandle;

    procedure   Disconnect;

    function    GetStatus: IStatus;
    property    Status: IStatus read GetStatus;

    function    GetChannelRef: IChannelForConnection;
    procedure   SetChannelRef (aChannelObj: IChannelForConnection);
    property    ChannelRef: IChannelForConnection read GetChannelRef write SetChannelRef;

    procedure   SetStationType (aNewType: TStationType);
    function    GetStationType: TStationType;
    property    StationType: TStationType read GetStationType write SetStationType;

    function    GetConnectionStatus: TConnectionStatus;
    procedure   SetConnectionStatus (aConnectionStatus: TConnectionStatus);
    property    ConnectionStatus: TConnectionStatus read GetConnectionStatus write SetConnectionStatus;

    function    GetOutgoing: Boolean;
    procedure   SetOutgoing (aOutgoing: Boolean);
    property    Outgoing: Boolean read GetOutgoing write SetOutgoing;

    function    GetSendConnectText: Boolean;
    procedure   SetSendConnectText (const Value: Boolean);
    property    SendConnectText: Boolean read GetSendConnectText write SetSendConnectText;

    function    GetSendFileQueue: ISendFileQueue;
    property    SendFileQueue: ISendFileQueue read GetSendFileQueue;

    procedure   SetFileSender (aSendFile: ISendFile);
    function    GetFileSender: ISendFile;
    property    FileSender: ISendFile read GetFileSender write SetFileSender;

    procedure   SendTextData (aText: String; aEcho: Boolean; aControlChars: Boolean = false; aWrap: Boolean = false;
                              aViaModule: Boolean = true);

    function    GetDeviceQueue: TStringQueue;
    property    DeviceQueue: TStringQueue read GetDeviceQueue;

    function    GetRemoteCommandsPossible: Boolean;
    procedure   SetRemoteCommandsPossible (const Value: Boolean);
    property    RemoteCommandsPossible: Boolean read GetRemoteCommandsPossible write SetRemoteCommandsPossible;

    function    GetCanCancel: Boolean;
    procedure   SetCanCancel (const Value: Boolean);
    property    CanCancel: Boolean read GetCanCancel write SetCanCancel;

    function    GetStationDatabaseEntry: IStationDatabaseEntry;
    property    StationDatabaseEntry: IStationDatabaseEntry read GetStationDatabaseEntry;

    function    GetBinMode: TSendFileProtocol;
    procedure   SetBinMode (const Value: TSendFileProtocol);
    property    BinMode: TSendFileProtocol read GetBinMode write SetBinMode;

    function    IsIncomingConnectAllowed: TIncomingConnect;
    procedure   ConnectionEstablished;
    procedure   Disconnected (Reason: TDisconnectReason);
    procedure   ReceiveTextData (const aText: String);
    function    DiscLevel: TDisconnectLevel;
    procedure   DiscLevelDone;
    procedure   Save (const DeviceRegKey: String);
    procedure   Restore (const DeviceRegKey: String; aHandle: Cardinal);
    procedure   ChannelPrompt (const aText: String; aType: TDisplayType);
    procedure   Release;
    procedure   CancelTransfer;
    procedure   SendSID;

    function    GetPactor: Boolean;
    procedure   SetPactor (const Value: Boolean);
    property    Pactor: Boolean read GetPactor write SetPactor;

    procedure   PactorChangeOver;
    procedure   PactorBreakIn;

    function    GetLocalEcho: Boolean;
    procedure   SetLocalEcho (const Value: Boolean);
    property    LocalEcho: Boolean read GetLocalEcho write SetLocalEcho;

  end;


  IConnectionForModule = interface (IConnection) ['{4E73C226-11F3-11D2-8BDC-00A0243DC10A}']

    function    GetAllEventHandles (E: TEventEnum): THandle;
    property    AllEventHandles [E: TEventEnum]: THandle read GetAllEventHandles;

    function    ChannelReceiveText (const Text: String): Integer;
    procedure   ChannelSendText (const Text: String);
    procedure   ChannelDisplay (const aText: String; aType: TDisplayType);

    function    InfoboxConnect (const aCall: String): Boolean;
    function    InfoboxReconnect (const aCall: String): Boolean;

    function    GetReceiveQueue: TStringQueue;
    property    ReceiveQueue: TStringQueue read GetReceiveQueue;

    function    GetSendQueue: TStringQueue;
    property    SendQueue:    TStringQueue read GetSendQueue;

    function    GetRemoteCommands: IRemoteCommands;
    property    RemoteCommands: IRemoteCommands read GetRemoteCommands;

    procedure   SetConnectionModule (const Value: IConnectionAbstract);
    function    GetConnectionModule: IConnectionAbstract;
    property    ConnectionModule: IConnectionAbstract read GetConnectionModule write SetConnectionModule;

  end;


  IConnectionAbstract = interface ['{23BE0AB9-5DE4-495C-857E-E66C38C8726A}']

    procedure   Release;
    procedure   EventLoop;
    procedure   CancelTransfer;
    function    Name: String;
    function    GetCanCancel: Boolean;
    property    CanCancel: Boolean read GetCanCancel;

  end;


  TSendFileState = (fts_inactive, fts_preparing, fts_transferring);

  ISendFile = interface (IPublisher) ['{4E73C227-11F3-11D2-8BDC-00A0243DC10A}']

    procedure   Release;

    procedure   SetStream (aStream: TStream);
    function    GetStream: TStream;
    property    Stream: TStream read GetStream write SetStream;

    procedure   SetSourceFilename (const Name: String);
    function    GetSourceFilename: String;
    property    SourceFilename: String read GetSourceFilename write SetSourceFilename;

    procedure   SetTargetFilename (const Name: String);
    function    GetTargetFilename: String;
    property    TargetFilename: String read GetTargetFilename write SetTargetFilename;

    function    GetTextBefore: string;
    procedure   SetTextBefore (const Value: string);
    property    TextBefore: string read GetTextBefore write SetTextBefore;

    function    GetTextAfter: string;
    procedure   SetTextAfter (const Value: string);
    property    TextAfter: string read GetTextAfter write SetTextAfter;

    procedure   SetActive (aActive: TSendFileState);
    function    GetActive: TSendFileState;
    property    Active: TSendFileState read GetActive write SetActive;

    procedure   SetTransferProtocol (TransferProtocol: TSendFileProtocol);
    function    GetTransferProtocol: TSendFileProtocol;
    property    TransferProtocol: TSendFileProtocol read GetTransferProtocol write SetTransferProtocol;

    procedure   SetProgress (N: Integer);
    function    GetProgress: Integer;
    property    Progress: Integer read GetProgress write SetProgress;

    function    GetPercent: Single;
    property    Percent: Single read GetPercent;

    procedure   SetAbsolute (N: Integer);
    function    GetAbsolute: Integer;
    property    Absolute: Integer read GetAbsolute write SetAbsolute;

    procedure   TransferPrepare;
    procedure   TransferBegin;
    procedure   TransferEnd;
    procedure   Transfer (Bytes: Cardinal);

  end;


  ISendFileQueue = interface (IPublisher) ['{4E73C228-11F3-11D2-8BDC-00A0243DC10A}']

    procedure   Release;
    function    GetCount: Integer;
    function    GetItems (Index: Integer): ISendFile;
    property    Count: Integer read GetCount;
    property    Items [Index: Integer]: ISendFile read GetItems; default;
    procedure   Enqueue (FileSender: ISendFile);
    function    Dequeue: ISendFile;
    function    Current: ISendFile;
    function    GetEvent: TEvent;
    property    Event: TEvent read GetEvent;
    procedure   Lock;
    procedure   Unlock;
    function    Remove (FileSender: ISendFile): Integer;

  end;


  IRemoteCommands = interface ['{4E73C229-11F3-11D2-8BDC-00A0243DC10A}']
    procedure   Release;
    procedure   call (TextLine: String);
  end;


resourcestring
  SPasswordTypeUser = 'Benutzer';
  SPasswordTypeSysop = 'Sysop';

const
  PasswordKindString: array[TPasswordKind] of string
                   = (SPasswordTypeUser, SPasswordTypeSysop);


  PasswordKindID: array[TPasswordKind] of Char
               = ('U', 'S');

  PasswordMethodString: array[TPasswordMethod] of string
                         = ('BayCom', 'MD5', 'DieBox');

  PasswordMethodID: array[TPasswordMethod] of Char
                     = ('B', 'M', 'D');


function StationTypeText(ST: TStationType): string;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation


function StationTypeText(ST: TStationType): string;
resourcestring
  SStationTypeAutomatic = 'Automatisch';
  SStationTypeNode = 'Digi';
  SStationTypeMailbox = 'Mailbox';
  SStationTypeConvers = 'Convers';
  SStationTypeTerminal = 'Terminal';
  SStationTypeCluster = 'Cluster';
begin
  case ST of
    st_unknown: result := SStationTypeAutomatic;
    st_digi: result := SStationTypeNode;
    st_box: result := SStationTypeMailbox;
    st_convers: result := SStationTypeConvers;
    st_terminal: result := SStationTypeTerminal;
    st_cluster: result := SStationTypeCluster;
    else result := '[undef]';
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

initialization

  assert (high (TEventEnum) = high (TUserEventEnum));

end.

