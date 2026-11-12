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


unit TextsConstsU;


interface


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type
  TTextKind = (te_greeting,
              te_end,
              te_info,
              te_news,
              te_1,
              te_2,
              te_3,
              te_4,
              te_5,
              te_6,
              te_7,
              te_8,
              te_9,
              te_0);


resourcestring
  ten_greeting      = 'Begrüßung';
  ten_end             = 'Abschied (//Q)';
  ten_info             = 'Info über die Station (//I)';
  ten_news            = 'Neuigkeiten (//NE)';
  ten_n                = 'Textbaustein %d (Strg+%d)';


type
  TTextKindRec = record
    Name: String;
    ID: Integer;
    GlobalOnly: Boolean;
  end;


function TextKinds(TT: TTextKind): TTextKindRec;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

uses
  SysUtils;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function TextKinds(TT: TTextKind): TTextKindRec;
begin
  with result do begin
    case TT of
      te_greeting: begin Name := ten_greeting; ID := 00; GlobalOnly := False; end;
      te_end:        begin Name := ten_end;        ID := 01; GlobalOnly := False; end;
      te_info:        begin Name := ten_info;        ID := 02; GlobalOnly := True;  end;
      te_news:       begin Name := ten_news;       ID := 03; GlobalOnly := False; end;
      te_1..te_0:     begin Name := Format (ten_n, [ord (tt) - ord (te_1) + 1, (ord (tt) - ord (te_1) + 1) mod 10]); ID := 4 +
                                    ord (tt) - ord (te_1); GlobalOnly := False; end;
    end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.

