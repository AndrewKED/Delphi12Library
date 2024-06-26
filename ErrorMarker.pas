unit ErrorMarker;

interface

uses
  Controls;

type
  TExposedWinControl = class(TWinControl);

  TErrorFlag = class
  public
    class procedure RemoveErrorMarker(Sender : TObject);
  end;

procedure InsertErrorMarker(Sender : TWinControl);

implementation

uses
  ExtCtrls, Classes, SysUtils, Graphics;

var
  shError : TShape;
  eOldErrorOnClick : TNotifyEvent;

//***************************************************************************
//
//  FUNCTION  :
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
procedure InsertErrorMarker(Sender : TWinControl);
var
  wcTarget : TExposedWinControl;

begin
  // Ensure that we are not already displaying an error marker
  if (not Assigned(shError)) then
  begin
    wcTarget := TExposedWinControl(Sender);

    shError := TShape.Create(nil);
    shError.Parent := wcTarget.Parent;
    shError.Brush.Style := bsClear;
    shError.Pen.Color := clRed;
    shError.Pen.Width := 3;
    shError.Top := wcTarget.Top - 10;
    shError.Left := wcTarget.Left - 10;
    shError.Width := wcTarget.Width + 20;
    shError.Height := wcTarget.Height + 20;

    eOldErrorOnClick := wcTarget.OnClick;
    wcTarget.OnClick := TErrorFlag.RemoveErrorMarker;
  end; // if
end; // InsertErrorMarker

//***************************************************************************
//
//  FUNCTION  :
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
class procedure TErrorFlag.RemoveErrorMarker(Sender : TObject);
begin
  if (Assigned(shError)) then
  begin
    shError.Visible := FALSE;
    if (Assigned(eOldErrorOnClick)) then
      eOldErrorOnClick(Sender);
    // Restore original OnClick event
    TExposedWinControl(Sender).OnClick := eOldErrorOnClick;
    FreeAndNil(shError);
  end;
end;

end.
