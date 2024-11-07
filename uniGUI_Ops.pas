unit UniGui_Ops;

interface

uses
  System.SysUtils,
  uniGUIClasses, uniGUIForm, uniPanel;

const
  PERSISTENT_COOKIE_EXPIRY = 73051; // Equivalend of EncodeDate(2100,1,1)

procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
procedure CentreXAonB(controlA : TUniControl;
                      controlB : TUniControl) overload;
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
procedure CentreYAonB(controlA : TUniControl;
                      controlB : TUniControl) overload;
procedure SetReadOnly(owner : TUniContainer;
                      state : Boolean);

implementation

uses
  System.TypInfo,
  uniCheckBox, uniEdit, uniDateTimePicker, uniMemo,
  uniDBCheckBox, uniDBEdit, uniDBDateTimePicker, uniDBMemo;

//***************************************************************************
//
//  FUNCTION  : CentreXAonB
//
//  I/P       : controlA : TUniControl - The target control, to be centred
//
//              controlB : TUniControl - The reference control
//
//  O/P       : controlA.Left is updated
//
//  OPERATION : Adjust controlA's left position, so it is centred on control B,
//              in the X-axis.
//
//  UPDATED   : 2023-09-20
//
//***************************************************************************
procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
begin
  controlA.Left := controlB.Left +
    (controlB.Width - controlA.Width) div 2;
end; // CentreXAonB
procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
begin
  controlA.Left := controlB.Left +
    (controlB.Width - controlA.Width) div 2;
end; // CentreXAonB

procedure CentreXAonB(controlA : TUniControl;
                      controlB : TUniControl) overload;
begin
  controlA.Left := controlB.Left +
    (controlB.Width - controlA.Width) div 2;
end; // CentreXAonB

//***************************************************************************
//
//  FUNCTION  : CentreYAonB
//
//  I/P       : controlA : TUniControl - The target control, to be centred
//
//              controlB : TUniControl - The reference control
//
//  O/P       : controlA.Top is updated
//
//  OPERATION : Adjust controlA's top position, so it is centred on control B,
//              in the Y-axis.
//
//  UPDATED   : 2023-09-20
//
//***************************************************************************
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
begin
  controlA.Top := controlB.Top +
    (controlB.Height - controlA.Height) div 2;
end; // CentreYAonB
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
begin
  controlA.Top := controlB.Top +
    (controlB.Height - controlA.Height) div 2;
end; // CentreYAonB
procedure CentreYAonB(controlA : TUniControl;
                      controlB : TUniControl) overload;
begin
  controlA.Top := controlB.Top +
    (controlB.Height - controlA.Height) div 2;
end; // CentreYAonB

//***************************************************************************
//
//  FUNCTION  : SetReadOnly
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure SetReadOnly(owner : TUniContainer;
                      state : Boolean);
var
  n : Integer;
  propList : PPropList;
  propCount : Integer;
  m: Integer;

begin
  for n := 0 to owner.ControlCount-1 do
  begin
    if (owner.Controls[n] is TUniContainer) then
    begin
      SetReadOnly(TUniContainer(owner.Controls[n]), state);
    end;

    propCount := GetPropList(owner.Controls[n], propList);
    try
      for m := 0 to propCount-1 do
      begin
        if (propList[m].Name = 'ReadOnly') then
        begin
          SetPropValue(owner.Controls[n], 'ReadOnly', state);
        end;
      end;
    finally
      FreeMem(propList);
    end;
  end; // for

//    if (owner.Controls[n] is TUniCheckbox) then
//    begin
//      (owner.Controls[n] as TUniCheckbox).ReadOnly := state;
//    end;
//    if (owner.Controls[n] is TUniDBCheckbox) then
//    begin
//      (owner.Controls[n] as TUniDBCheckbox).ReadOnly := state;
//    end;
//
//    if (owner.Controls[n] is TUniEdit) then
//    begin
//      (owner.Controls[n] as TUniEdit).ReadOnly := state;
//    end;
//    if (owner.Controls[n] is TUniDBEdit) then
//    begin
//      (owner.Controls[n] as TUniDBEdit).ReadOnly := state;
//    end;
//
//    if (owner.Controls[n] is TuniDateTimePicker) then
//    begin
//      (owner.Controls[n] as TuniDateTimePicker).ReadOnly := state;
//    end;
//    if (owner.Controls[n] is TuniDBDateTimePicker) then
//    begin
//      (owner.Controls[n] as TuniDBDateTimePicker).ReadOnly := state;
//    end;
//
//    if (owner.Controls[n] is TuniMemo) then
//    begin
//      (owner.Controls[n] as TuniMemo).ReadOnly := state;
//    end;
//    if (owner.Controls[n] is TuniDBMemo) then
//    begin
//      (owner.Controls[n] as TuniDBMemo).ReadOnly := state;
//    end;
//  end;
end;

end.
