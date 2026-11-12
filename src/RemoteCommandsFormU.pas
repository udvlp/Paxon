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


unit RemoteCommandsFormU;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ListView4StateCheckU, ExtCtrls, PanelUlfU, FormU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


type

  TRemoteCommandsForm = class (TFormUlf)
    RemoteCommandsGroupbox: TGroupBox;
    CheckListView: TListView4State;

  private

    FGlobal: Boolean;
    FCall: String;
    procedure   UpdateList;

  public

    procedure   Init (Global: Boolean);
    procedure   Save; virtual;
    procedure   SetNewCall (aCall: String);

  end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


implementation

{$R *.DFM}

uses
  RemoteCommandsU;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


procedure   TRemoteCommandsForm.Init (Global: Boolean);
begin
  FGlobal := Global;
  FCall := '';
  CheckListView.AllowGrayed := not FGlobal;
  CheckListView.Items.Clear;
  UpdateList;
end;


procedure   TRemoteCommandsForm.Save;
var
  I, N: Integer;
  LI: TListItem;
begin
  for I := 0 to CheckListView.Items.Count - 1 do begin
    LI := CheckListView.Items[I];
    N := LI.StateIndex;
    if (N >= 2) then begin
      RemoteCommandManager.DeleteCall (FCall, LI.Caption);
    end else begin
      RemoteCommandManager.Save (FCall, LI.Caption, (N = 1));
    end;
  end;
end;


procedure   TRemoteCommandsForm.SetNewCall (aCall: String);
begin
  FCall := aCall;
  UpdateList;
end;


procedure   TRemoteCommandsForm.UpdateList;
var
  N, I: Integer;
  LI: TListItem;
  State: Boolean;
  SL: TStringList;
  RemoteCommandClass: TRemoteCommandClass;
  S: String;

begin

  SL := TStringList.create;
  try

    RemoteCommandManager.GetList (SL);

    CheckListView.Items.BeginUpdate;
    try

      CheckListView.Items.Clear;

      for I := 0 to SL.Count - 1 do begin

        LI := CheckListView.Items.Add;
        LI.Caption := SL[I];

        S := SL[I];
        RemoteCommandClass := RemoteCommandManager.Find (S);
        if (assigned (RemoteCommandClass)) then begin
          S := RemoteCommandClass.Help (false);
        end else begin
          S := '';
        end;

        LI.SubItems.Add (S);

        RemoteCommandManager.Load ('', SL[I], State);

        if (State) then N := 1 else N := 0;
        if (FCall = '') then begin
          LI.StateIndex := N;
        end else begin
          LI.Data := Pointer(N);
          if (RemoteCommandManager.Load (FCall, SL[I], State)) then begin
            if (State) then N := 1 else N := 0;
          end else begin
            if (State) then N := 3 else N := 2;
          end;
          LI.StateIndex := N;
        end;

      end;

    finally
      CheckListView.Items.EndUpdate;
    end;

  finally
    SL.free;
  end;

end;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


end.
