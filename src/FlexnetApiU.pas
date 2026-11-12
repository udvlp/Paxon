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
//  The declarations of this unit follow the C interface of FlexNet
//  (FLEXAPI.H/FLEXDRV.H, FlexNet by Gunter Jost, DK7WJ).
//


unit FlexnetApiU;


interface


uses
  Windows, SysUtils, Registry;


type
  i8 = byte;
  i16 = smallint;
  u16 = word;
  i32 = longint;
  u32 = longint;


const
  FlexnetDLLName = 'flxapi32.dll';


var
  Flexnet: Boolean;
  FlexnetDLL: LongInt;
  FlexnetError: String;


function FlexnetInit: Boolean;

function FlexnetDeInit: Boolean;


const

  FLXCALL = 7;

  DIGIS   = 8;

  STRCALLLEN = 16;

  STRPATHLEN = 131;


type
  PL1_STATISTICS = ^TL1_STATISTICS;
  TL1_STATISTICS = packed record
    tx_error: u32;
    rx_overrun: u32;
    rx_bufferoverflow: u32;
    tx_frames: u32;
    rx_frames: u32;
    io_error: u32;
    reserve: array[1..4] of u32;
  end;


type
  PFrame = ^TFrame;
  TFrame = packed record
    dest: array [0..FLXCALL-1] of Char;
    source: array[0..FLXCALL-1] of Char;
    digis: Byte;
    nextdigi: Byte;
    ChannelRef: Byte;
    axv2: Byte;
    pid: Byte;
    frame_type: Byte;
    cmd: Byte;
    pf: Byte;
    rx_seq: Byte;
    ns: Byte;
    dama: Byte;
    tx: Byte;
    txdel: Byte;
    reserved: Array[1..3] of Byte;
    textlen: U16;
    text: PChar;
    qsonum: U16;
    partner_num: U16;
    digi: Array[0..DIGIS-1] of Array[0..FLXCALL-1] of Char;
  end;


const
  FT_I = 1;
  FT_RR = 2;
  FT_RNR = 3;
  FT_REJ = 4;
  FT_SABM = 5;
  FT_DISC = 6;
  FT_DM = 7;
  FT_UA = 8;
  FT_FRMR = 9;
  FT_UI = 10;


const
  MAXTEXT = 300;


type
  PInfo = ^TInfo;
  TInfo = packed record
    len: i16;
    pid: byte;
    text: Array [0..MAXTEXT-1] of Char;
  end;


const
  CH_PTT   =   $20;
  CH_DCD   =   $10;
  CH_TBY   =   $04;
  MODE_y   = $0200;
  MODE_a   = $0100;
  MODE_m   = $0400;
  MODE_s   = $0800;
  MODE_d   = $0080;
  MODE_r   = $0040;
  MODE_t   = $0020;
  MODE_z   = $0010;
  MODE_c   = $0002;
  MODE_off = $0001;


const
  TRACETYPE_NO_S    =    1;
  TRACETYPE_DIAG    =   64;
  TRACETYPE_NO_TEXT =  128;


type
  TTrace = packed record
    ch_mask: U16;
    type_filter: Byte;
    trxfilter: Byte;
    Call: Array[0..FLXCALL-1] of Char;
    handle: u16;
  end;


const
  EV_QSODATA = 'FlexNet QSO Data';
  EV_TRACE = 'FlexNet Trace Data';
  EV_QSOSTATE = 'FlexNet QSO State Change';
  EV_NODEFRAME = 'FlexNet Node Frame';
  EV_SABM = 'FlexNet Connect Request';
  EV_UI = 'FlexNet Unproto Received';
  EV_CHANNELS = 'FlexNet Channel State';


var ax_init: function: Byte; cdecl;


var ax_exit: function: Byte; cdecl;


var l2_version: function: PChar; cdecl;


var l2_connect: function (Source, Destination: PChar): U16; cdecl;


var l2_check_path: function (Source, Destination: PChar): U16; cdecl;


var l2_get_sabm: function (Call: PChar): U16; cdecl;


procedure l2_sabmresp (qsonum: U16);


procedure l2_sabm_dm (qsonum: U16);


var l2_send_ui: function (Src: PChar; Dest: PChar; Pid: Byte; Poll: Byte; TextLen: U16; Text: PChar): Byte; cdecl;


var l2_get_ui: function (Call: PChar): PFrame; cdecl;


var l2_ialloc: function (QsoNum: U16; Len: I16): I8; cdecl;


var l2_printf_: function (QsoNum: U16; Fmt: PChar; Text: PChar): I8; cdecl;


var l2_puts: procedure (QsoNum: U16; Str: PChar); cdecl;


var l2_send_char: procedure (QsoNum: U16; Character: Char); cdecl;


procedure l2_pack (qsonum: U16);


var l2_get_i: function (QsoNum: U16): PInfo; cdecl;


procedure l2_i_ack (qsonum: U16);


procedure l2_stop_qso (qsonum: U16);


procedure l2_cancel_qso (qsonum: U16);


procedure l2_kill_qso (qsonum: U16);


procedure l2_clr_i (qsonum: U16);


procedure l2_long_hold (qsonum: U16);


procedure l2_set_linemode (qsonum: U16);


function l2_state (qsonum: U16): Byte;

const
  L2_STATE_MASK = $07;


function l2_unack (qsonum: U16): Byte;


var l2_get_f: function (QsoNum: U16): PFrame; cdecl;


var get_tic: function: U16; cdecl;


var appl_watchdog: procedure (Time: U16); cdecl;


var l2_set_monitor: function (var Trace: TTrace): Byte; cdecl;


var l2_clr_monitor: procedure; cdecl;


var l2_chk_monitor: function: Byte; cdecl;


var l2_get_monitor: function: PFrame; cdecl;


var l2_ack_monitor: procedure; cdecl;


var StrCall: function (Call: PChar; FlexCall: PChar): PChar; cdecl;

function FlxCallToString (FlexCall: PChar): String;


var StrPath: function (Path: PChar; F: PFrame): PChar; cdecl;


var build_call: procedure (FlexCall: Pointer; Call: PChar); cdecl;


var build_frame: procedure (var Frame: TFrame; Source: PChar; Destination: PChar); cdecl;


var l2_send_f: function (var Frame: TFrame): Byte; cdecl;


var l2_fconnect: function (var Frame: TFrame): U16; cdecl;


var l2_send_frame: procedure (QsoNum: U16; var Info: TInfo); cdecl;


function l2_maxframe (qsonum: U16): Byte;


function l2_tries (qsonum: U16): Byte;


function l2_frack (qsonum: U16): U16;


function l2_idletime (qsonum: U16): U16;


var l2_get_qnum: function (var Frame: TFrame): U16; cdecl;


function l2_rx_cnt (qsonum: U16): U16;


function l2_i_len (qsonum: U16): U16;


procedure l2_init_poll (qsonum: U16);


procedure l2_reset_tries (qsonum: U16);


procedure l2_start_qso (qsonum: U16);


var l2_cmd: procedure (Func: Byte; qsonum: U16); cdecl;


var l2_stat: function (Func: Byte; qsonum: U16): U16; cdecl;


var l2_set_pid: procedure (QsoNum: U16; PID: Byte); cdecl;


var ch_state: function (ChannelRef: Byte): Byte; cdecl;


var ch_active: function (ChannelRef: Byte): Byte; cdecl;


var set_chmode: function (ChannelRef: Byte; Mode: U16; Baud: U16): Byte; cdecl;


var set_txdelay: procedure (ChannelRef: Byte; TXD: Byte); cdecl;


var calibrate: procedure (ChannelRef: Byte; Minutes: Byte); cdecl;


var get_chbaud: function (ChannelRef: Byte): U16; cdecl;


var get_chmode: function (ChannelRef: Byte): U16; cdecl;


var get_txdelay: function (ChannelRef: Byte): U16; cdecl;


var get_ident: function (ChannelRef: Byte): PChar; cdecl;


var get_stat: function (ChannelRef: Byte; Del: Byte): PL1_Statistics; cdecl;


var set_debug_mode: procedure (mode: integer); cdecl;


var flxdbg_: procedure (level: Integer; Fmt: PChar; Text: PChar); cdecl;


implementation


function FlexnetInit: Boolean;
var
  S: String;
  L: Integer;
  Reg: TRegistry;

begin

  FlexnetDLL := 0;

  Reg := TRegistry.Create (KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey ('\Software\FlexNet', false) then begin
      S := Reg.ReadString ('Home');
      Reg.CloseKey;
      L := Length (S);
      if (L > 0) then begin
        if (S[L] <> '\') then S := S + '\';
        FlexnetDLL := SafeLoadLibrary (PChar(S + FlexnetDLLName));
      end;
    end;
  finally
    Reg.free;
  end;

  if (FlexnetDLL = 0) then begin
    SetLength (S, 260);
    SetLength (S, GetEnvironmentVariable ('flexnet', PChar(S), 259));
    L := Length (S);
    if (L > 0) then begin
      if (S[L] <> '\') then S := S + '\';
      FlexnetDLL := SafeLoadLibrary (PChar(S + FlexnetDLLName));
    end;
  end;

  if (FlexnetDLL = 0) then begin
    FlexnetDLL := SafeLoadLibrary (FlexnetDLLName);
  end;

  FlexnetError := '';

  if (FlexnetDLL <> 0) then begin

    ax_init        := GetProcAddress (FlexnetDLL, 'ax_init');         if addr(ax_init)        = nil then
      FlexnetError := FlexnetError + 'ax_init' + ' / ';
    ax_exit        := GetProcAddress (FlexnetDLL, 'ax_exit');         if addr(ax_exit)        = nil then
      FlexnetError := FlexnetError + 'ax_exit' + ' / ';
    l2_version     := GetProcAddress (FlexnetDLL, 'l2_version');      if addr(l2_version)     = nil then
      FlexnetError := FlexnetError + 'l2_version' + ' / ';
    l2_connect     := GetProcAddress (FlexnetDLL, 'l2_connect');      if addr(l2_connect)     = nil then
      FlexnetError := FlexnetError + 'l2_connect' + ' / ';
    l2_check_path  := GetProcAddress (FlexnetDLL, 'l2_check_path');   if addr(l2_check_path)  = nil then
      FlexnetError := FlexnetError + 'l2_check_path' + ' / ';
    l2_get_sabm    := GetProcAddress (FlexnetDLL, 'l2_get_sabm');     if addr(l2_get_sabm)    = nil then
      FlexnetError := FlexnetError + 'l2_get_sabm' + ' / ';
    l2_send_ui     := GetProcAddress (FlexnetDLL, 'l2_send_ui');      if addr(l2_send_ui)     = nil then
      FlexnetError := FlexnetError + 'l2_send_ui' + ' / ';
    l2_get_ui      := GetProcAddress (FlexnetDLL, 'l2_get_ui');       if addr(l2_get_ui)      = nil then
      FlexnetError := FlexnetError + 'l2_get_ui' + ' / ';
    l2_ialloc      := GetProcAddress (FlexnetDLL, 'l2_ialloc');       if addr(l2_ialloc)      = nil then
      FlexnetError := FlexnetError + 'l2_ialloc' + ' / ';
    l2_printf_     := GetProcAddress (FlexnetDLL, 'l2_printf');       if addr(l2_printf_)     = nil then
      FlexnetError := FlexnetError + 'l2_printf' + ' / ';
    l2_puts        := GetProcAddress (FlexnetDLL, 'l2_puts');         if addr(l2_puts)        = nil then
      FlexnetError := FlexnetError + 'l2_puts' + ' / ';
    l2_send_char   := GetProcAddress (FlexnetDLL, 'l2_send_char');    if addr(l2_send_char)   = nil then
      FlexnetError := FlexnetError + 'l2_send_char' + ' / ';
    l2_get_i       := GetProcAddress (FlexnetDLL, 'l2_get_i');        if addr(l2_get_i)       = nil then
      FlexnetError := FlexnetError + 'l2_get_i' + ' / ';
    l2_get_f       := GetProcAddress (FlexnetDLL, 'l2_get_f');        if addr(l2_get_f)       = nil then
      FlexnetError := FlexnetError + 'l2_get_f' + ' / ';
    get_tic        := GetProcAddress (FlexnetDLL, 'get_tic');         if addr(get_tic)        = nil then
      FlexnetError := FlexnetError + 'get_tic' + ' / ';
    appl_watchdog  := GetProcAddress (FlexnetDLL, 'appl_watchdog');   if addr(appl_watchdog)  = nil then
      FlexnetError := FlexnetError + 'appl_watchdog' + ' / ';
    l2_set_monitor := GetProcAddress (FlexnetDLL, 'l2_set_monitor');  if addr(l2_set_monitor) = nil then
      FlexnetError := FlexnetError + 'l2_set_monitor' + ' / ';
    l2_clr_monitor := GetProcAddress (FlexnetDLL, 'l2_clr_monitor');  if addr(l2_clr_monitor) = nil then
      FlexnetError := FlexnetError + 'l2_clr_monitor' + ' / ';
    l2_chk_monitor := GetProcAddress (FlexnetDLL, 'l2_chk_monitor');  if addr(l2_chk_monitor) = nil then
      FlexnetError := FlexnetError + 'l2_chk_monitor' + ' / ';
    l2_get_monitor := GetProcAddress (FlexnetDLL, 'l2_get_monitor');  if addr(l2_get_monitor) = nil then
      FlexnetError := FlexnetError + 'l2_get_monitor' + ' / ';
    l2_ack_monitor := GetProcAddress (FlexnetDLL, 'l2_ack_monitor');  if addr(l2_ack_monitor) = nil then
      FlexnetError := FlexnetError + 'l2_ack_monitor' + ' / ';
    strcall        := GetProcAddress (FlexnetDLL, 'strcall');         if addr(strcall)        = nil then
      FlexnetError := FlexnetError + 'strcall' + ' / ';
    strpath        := GetProcAddress (FlexnetDLL, 'strpath');         if addr(strpath)        = nil then
      FlexnetError := FlexnetError + 'strpath' + ' / ';
    build_call     := GetProcAddress (FlexnetDLL, 'build_call');      if addr(build_call)     = nil then
      FlexnetError := FlexnetError + 'build_call' + ' / ';
    build_frame    := GetProcAddress (FlexnetDLL, 'build_frame');     if addr(build_frame)    = nil then
      FlexnetError := FlexnetError + 'build_frame' + ' / ';
    l2_send_f      := GetProcAddress (FlexnetDLL, 'l2_send_f');       if addr(l2_send_f)      = nil then
      FlexnetError := FlexnetError + 'l2_send_f' + ' / ';
    l2_fconnect    := GetProcAddress (FlexnetDLL, 'l2_fconnect');     if addr(l2_fconnect)    = nil then
      FlexnetError := FlexnetError + 'l2_fconnect' + ' / ';
    l2_send_frame  := GetProcAddress (FlexnetDLL, 'l2_send_frame');   if addr(l2_send_frame)  = nil then
      FlexnetError := FlexnetError + 'l2_send_frame' + ' / ';
    l2_get_qnum    := GetProcAddress (FlexnetDLL, 'l2_get_qnum');     if addr(l2_get_qnum)    = nil then
      FlexnetError := FlexnetError + 'l2_get_qnum' + ' / ';
    l2_cmd         := GetProcAddress (FlexnetDLL, 'l2_bef');          if addr(l2_cmd)         = nil then
      FlexnetError := FlexnetError + 'l2_bef' + ' / ';
    l2_stat        := GetProcAddress (FlexnetDLL, 'l2_stat');         if addr(l2_stat)        = nil then
      FlexnetError := FlexnetError + 'l2_stat' + ' / ';
    l2_set_pid     := GetProcAddress (FlexnetDLL, 'l2_set_pid');      if addr(l2_set_pid)     = nil then
      FlexnetError := FlexnetError + 'l2_set_pid' + ' / ';
    ch_state       := GetProcAddress (FlexnetDLL, 'ch_state');        if addr(ch_state)       = nil then
      FlexnetError := FlexnetError + 'ch_state' + ' / ';
    ch_active      := GetProcAddress (FlexnetDLL, 'ch_active');       if addr(ch_active)      = nil then
      FlexnetError := FlexnetError + 'ch_active' + ' / ';
    set_chmode     := GetProcAddress (FlexnetDLL, 'set_chmode');      if addr(set_chmode)     = nil then
      FlexnetError := FlexnetError + 'set_chmode' + ' / ';
    set_txdelay    := GetProcAddress (FlexnetDLL, 'set_txdelay');     if addr(set_txdelay)    = nil then
      FlexnetError := FlexnetError + 'set_txdelay' + ' / ';
    calibrate      := GetProcAddress (FlexnetDLL, 'calibrate');       if addr(calibrate)      = nil then
      FlexnetError := FlexnetError + 'calibrate' + ' / ';
    get_chbaud     := GetProcAddress (FlexnetDLL, 'get_chbaud');      if addr(get_chbaud)     = nil then
      FlexnetError := FlexnetError + 'get_chbaud' + ' / ';
    get_chmode     := GetProcAddress (FlexnetDLL, 'get_chmode');      if addr(get_chmode)     = nil then
      FlexnetError := FlexnetError + 'get_chmode' + ' / ';
    get_txdelay    := GetProcAddress (FlexnetDLL, 'get_txdelay');     if addr(get_txdelay)    = nil then
      FlexnetError := FlexnetError + 'get_txdelay' + ' / ';
    get_ident      := GetProcAddress (FlexnetDLL, 'get_ident');       if addr(get_ident)      = nil then
      FlexnetError := FlexnetError + 'get_ident' + ' / ';
    get_stat       := GetProcAddress (FlexnetDLL, 'get_stat');        if addr(get_stat)       = nil then
      FlexnetError := FlexnetError + 'get_stat' + ' / ';
    set_debug_mode := GetProcAddress (FlexnetDLL, 'set_debug_mode');  if addr(set_debug_mode) = nil then
      FlexnetError := FlexnetError + 'set_debug_mode' + ' / ';
    flxdbg_        := GetProcAddress (FlexnetDLL, 'flxdbg');          if addr(flxdbg_)        = nil then
      FlexnetError := FlexnetError + 'flxdbg' + ' / ';

    if (FlexnetError <> '') then FlexnetError := 'Nicht in DLL: ' + Copy (FlexnetError, 1, Length (FlexnetError) - 3);

  end else begin

    FlexnetError := FlexnetError + 'DLL nicht gefunden';

  end;

  Flexnet := (FlexnetError = '');
  FlexnetInit := Flexnet;

end;


function FlexnetDeInit: Boolean;
begin
  if (FlexnetDLL <> 0) then FreeLibrary (FlexnetDLL);
  FlexnetDLL := 0;
  result := true;
end;


procedure flxdbg (Level: Integer; Text: String);
begin
  flxdbg_ (Level, '%s', PChar(Text));
end;


procedure l2_sabmresp (qsonum: U16);
begin
  l2_cmd (2, qsonum);
end;


procedure l2_sabm_dm (qsonum: U16);
begin
  l2_cmd (3, qsonum);
end;


procedure l2_pack (qsonum: U16);
begin
  l2_cmd (7, qsonum);
end;


procedure l2_i_ack (qsonum: U16);
begin
  l2_cmd (15, qsonum);
end;


procedure l2_stop_qso (qsonum: U16);
begin
  l2_cmd (4, qsonum);
end;


procedure l2_cancel_qso (qsonum: U16);
begin
  l2_cmd (5, qsonum);
end;


procedure l2_clr_i (qsonum: U16);
begin
  l2_cmd (10, qsonum);
end;


procedure l2_kill_qso (qsonum: U16);
begin
  l2_cmd (6, qsonum);
end;


procedure l2_init_poll (qsonum: U16);
begin
  l2_cmd (11, qsonum);
end;


procedure l2_start_qso (qsonum: U16);
begin
  l2_cmd (1, qsonum);
end;


procedure l2_reset_tries (qsonum: U16);
begin
  l2_cmd (12, qsonum);
end;


procedure l2_set_linemode (qsonum: U16);
begin
  l2_cmd (14, qsonum);
end;


procedure l2_long_hold (qsonum: U16);
begin
  l2_cmd (18, qsonum);
end;


function l2_i_len (qsonum: U16): U16;
begin
  Result := l2_stat (6, qsonum);
end;


function l2_rx_cnt (qsonum: U16): U16;
begin
  Result := l2_stat (9, qsonum);
end;


function l2_idletime (qsonum: U16): U16;
begin
  Result := l2_stat (5, qsonum);
end;


function l2_frack (qsonum: U16): U16;
begin
  Result := l2_stat (4, qsonum);
end;


function l2_tries (qsonum: U16): Byte;
begin
  Result := Byte(l2_stat (3, qsonum));
end;


function l2_maxframe (qsonum: U16): Byte;
begin
  Result := Byte(l2_stat (2, qsonum));
end;


function l2_state (qsonum: U16): Byte;
begin
  Result := Byte(l2_stat (0, qsonum));
end;


function l2_unack (qsonum: U16): Byte;
begin
  Result := Byte(l2_stat (1, qsonum));
end;


function    FlxCallToString (FlexCall: PChar): String;
begin
  SetLength (result, STRCALLLEN);
  StrCall (PChar(result), FlexCall);
  SetLength (result, StrLen(PChar(result)));
end;


initialization

  Flexnet := false;
  FlexnetError := '';

  assert (sizeof (i8) = 1);
  assert (sizeof (i16) = 2);
  assert (sizeof (u16) = 2);
  assert (sizeof (i32) = 4);
  assert (sizeof (u32) = 4);

end.

