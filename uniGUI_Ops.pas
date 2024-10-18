unit UniGui_Ops;

interface

uses
  uniGUIForm, uniPanel;

procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;

implementation

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

end.
