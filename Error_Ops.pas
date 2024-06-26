unit Error_Ops;

interface

uses
  Vcl.Controls, Vcl.Graphics;

procedure ShowErrorBorder(id : Integer;
                          targets : array of TWinControl;
                          errorColour : TColor;
                          transparentBackground : Boolean = FALSE);
procedure HideErrorBorder(id : Integer);

implementation

uses
  System.Types, System.Math, System.SysUtils,
  Vcl.ExtCtrls;

const
  MAX_ERROR_BORDERS = 2;
  BORDER_WIDTH = 2;

var
  n : Integer;
  errorBorder : array[0..MAX_ERROR_BORDERS-1] of TShape;

//***************************************************************************
//
//  FUNCTION  : ShowErrorBorder
//
//  I/P       : id : Integer;
//
//              targets : array of TWinControl - A set of controls that can be
//                used to indicate the boundaries of the rectangle that will
//                be coloured in.
//
//              errorColour : TColor - The colour of the error rectangle background.
//
//              transparentBackground : Boolean = FALSE. Use this behind
//                TRadioGroup etc.
//
//  O/P       : None
//
//  OPERATION : Creates a rectangle that boxes in the given array of controls.
//
//  UPDATED   : 2020-11-16
//
//***************************************************************************
procedure ShowErrorBorder(id : Integer;
                          targets : array of TWinControl;
                          errorColour : TColor;
                          transparentBackground : Boolean = FALSE);
var
  c : Integer;
  tl : TPoint;
  br : TPoint;
  theParent : TWinControl;

begin
  errorBorder[id].Pen.Color := errorColour;
  if (transparentBackground) then
  begin
    errorBorder[id].Brush.Style := bsClear;
  end // if
  else
  begin
    errorBorder[id].Brush.Style := bsSolid;
    errorBorder[id].Brush.Color := errorColour;
  end;

  tl.X := MaxInt;
  tl.Y := MaxInt;
  br.X := 0;
  br.Y := 0;

  if (Length(targets) > 0) then
  begin
    theParent := nil;

    for c := 0 to Length(targets)-1 do
    begin
      if (theParent = nil) then
      begin
        theParent := targets[c].Parent;
      end // if
      else
      begin
        if (theParent <> targets[c].Parent) then
          Exit;
      end;
      tl.X := Min(tl.X, targets[c].Left);
      tl.Y := Min(tl.Y, targets[c].Top);
      br.X := Max(br.X, targets[c].Left + targets[c].Width);
      br.Y := Max(br.Y, targets[c].Top + targets[c].Height);
    end; // for

    Dec(tl.X, BORDER_WIDTH);
    Dec(tl.Y, BORDER_WIDTH);
    Inc(br.X, BORDER_WIDTH);
    Inc(br.Y, BORDER_WIDTH);

    errorBorder[id].Parent := theParent;

    errorBorder[id].Left := tl.X;
    errorBorder[id].Top := tl.Y;
    errorBorder[id].Width := br.X - tl.X;
    errorBorder[id].Height := br.Y - tl.Y;

    errorBorder[id].Visible := TRUE;
    errorBorder[id].SendToBack;
    errorBorder[id].Repaint;

    for c := 0 to Length(targets)-1 do
    begin
      targets[c].Repaint;
    end; // for
  end; // if
end; // ShowErrorBorder

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
procedure HideErrorBorder(id : Integer);
begin
  if (errorBorder[id].Parent <> nil) then
  begin
    errorBorder[id].Visible := FALSE;
    // A repaint is required to ensure that, for example, checkboxes have the
    // error marker border complete removed.
    (errorBorder[id].Parent as TWinControl).Repaint;
    errorBorder[id].Parent := nil;
  end; // if
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
begin
  for n := 0 to MAX_ERROR_BORDERS-1 do
  begin
    FreeAndNil(errorBorder[n]);
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

  for n := 0 to MAX_ERROR_BORDERS-1 do
  begin
    errorBorder[n] := TShape.Create(nil);
    errorBorder[n].Pen.Color := clRed;
    errorBorder[n].Pen.Width := BORDER_WIDTH;
    errorBorder[n].Brush.Color := clRed;
    errorBorder[n].Shape := stRectangle;
    errorBorder[n].Visible := FALSE;
    errorBorder[n].Parent := nil;
  end;

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
