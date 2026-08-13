unit Error_Ops;

interface

uses
  Vcl.Controls, Vcl.Graphics;

procedure ShowErrorBorder(id : Integer;
                          targets : array of TControl;
                          errorColour : TColor = clRed;
                          transparentBackground : Boolean = FALSE);
procedure HideErrorBorder(id : Integer;
                          doRepaint : Boolean = TRUE);

implementation

uses
  System.Types, System.Math, System.SysUtils,
  Vcl.ExtCtrls;

const
  MAX_ERROR_BORDERS = 2;
  BORDER_WIDTH = 2;

type
  TErrorControls = record
    controls : array of TShape;
  end;

var
  n : Integer;
  errorBorder : array[0..MAX_ERROR_BORDERS-1] of TErrorControls;

//***************************************************************************
//
//  FUNCTION  : ShowErrorBorder
//
//  I/P       : id : Integer - The error group ID (Currently 0..1);
//
//              targets : array of TControl - A set of controls that can be
//                used to indicate the boundaries of the rectangle that will
//                be coloured in.
//
//              errorColour : TColor = clRed - The colour of the error rectangle
//                background.
//
//              transparentBackground : Boolean = FALSE. Use this behind
//                TRadioGroup etc.
//
//  O/P       : None
//
//  OPERATION : Creates an error border "set" of rectangular boxes around each
//              of the controls.
//
//              A TForm which uses Error Borders should always call HideErrorBorder(?) in
//              its OnDestroy event (to make sure that it has tidied up correctly)
//
//  UPDATED   : 2020-11-16
//
//***************************************************************************
procedure ShowErrorBorder(id : Integer;
                          targets : array of TControl;
                          errorColour : TColor = clRed;
                          transparentBackground : Boolean = FALSE);
var
  c : Integer;

begin
  SetLength(errorBorder[id].controls, 0);

  for c := 0 to Length(targets)-1 do
  begin
    SetLength(errorBorder[id].controls, Length(errorBorder[id].controls) + 1);

    errorBorder[id].controls[c] := TShape.Create(nil);
    errorBorder[id].controls[c].Pen.Color := errorColour;
    errorBorder[id].controls[c].Pen.Width := BORDER_WIDTH;
    errorBorder[id].controls[c].Brush.Color := errorColour;
    errorBorder[id].controls[c].Shape := stRectangle;
    errorBorder[id].controls[c].Parent := targets[c].Parent;

    if (transparentBackground) then
    begin
      errorBorder[id].controls[c].Brush.Style := bsClear;
    end // if
    else
    begin
      errorBorder[id].controls[c].Brush.Style := bsSolid;
    end;

    errorBorder[id].controls[c].Left := targets[c].Left - BORDER_WIDTH;
    errorBorder[id].controls[c].Top := targets[c].Top - BORDER_WIDTH;
    errorBorder[id].controls[c].Width := targets[c].Width + 2 * BORDER_WIDTH;
    errorBorder[id].controls[c].Height := targets[c].Height + 2 * BORDER_WIDTH;

    errorBorder[id].controls[c].Visible := TRUE;
    errorBorder[id].controls[c].SendToBack;
    errorBorder[id].controls[c].Repaint;
  end;
end; // ShowErrorBorder

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       : id : Integer - The id of the error border set
//
//              doRepaint : Boolean = TRUE - TRUE to repaint the parent/s of
//                the control/s in the error border set.
//
//  O/P       :
//
//  OPERATION : Remove an error border set.
//
//  UPDATED   : 2023-01-23
//
//***************************************************************************
procedure HideErrorBorder(id : Integer;
                          doRepaint : Boolean = TRUE);
var
  c : Integer;

begin
  while (Length(errorBorder[id].controls) > 0) do
  begin
    c := Length(errorBorder[id].controls) - 1;
    errorBorder[id].controls[c].Visible := FALSE;
    if ((errorBorder[id].controls[c].Parent <> nil) and
        (doRepaint)) then
    begin
      // A repaint is required to ensure that, for example, checkboxes have the
      // error marker border complete removed.
      (errorBorder[id].controls[c].Parent as TWinControl).Repaint;
    end;
    FreeAndNil(errorBorder[id].controls[c]);
    SetLength(errorBorder[id].controls, Length(errorBorder[id].controls) - 1);
  end;
end; // HideErrorBorder

//***************************************************************************
//
//  FUNCTION  : FreeErrorBorders
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : This operation is placed in its own proceudre, instead of
//              being in the finalizaation section, to lose the warning
//              "For loop control variable must be simple variable"
//
//              If used errors have not been hidden using HideErrorBorder,
//              above, this cleanup produces an "Invalid pointer operation" error.
//
//  UPDATED   : 2019-09-08
//
//***************************************************************************
procedure FreeErrorBorders;
var
  n : Integer;
  c : Integer;

begin
  for n := 0 to MAX_ERROR_BORDERS-1 do
  begin
    HideErrorBorder(n, FALSE);
  end;
end; // FreeErrorBorders

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
initialization

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
finalization
  // A TForm which uses Error Borders should always call HideErrorBorder(?) in
  // its OnDestroy event (to make sure that it has tidied up correctly)

  // If this is not done, this Free operation may give an AV.
  FreeErrorBorders;

end.
