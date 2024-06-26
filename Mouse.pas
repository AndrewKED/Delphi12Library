unit Mouse;

// See http://delphi.about.com/od/vclusing/a/mouseadvanced.htm?nl=1

interface

function MousePresent : boolean;

implementation


//***************************************************************************
//
//  FUNCTION  : MousePresent
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
function MousePresent : boolean;
begin
  result := (GetSystemMetrics(SM_MOUSEPRESENT) <> 0);
end; // MousePresent


//***************************************************************************
//
//  FUNCTION  : SetMousePos
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : The SetCursorPos API function moves the cursor to the
//              specified screen coordinates.   Since this function does
//              not get a windows handle as a parameter, x/y have to be
//              screen coordinates. Your component does use relative coordinates,
//              e.g. relative to a TForm. You have to use the ClientToScreen
//              function to calculate the proper screen coordinates.
//
//  UPDATED   :
//
//***************************************************************************
procedure SetMousePos(x, y: longint) ;
var pt: TPoint;
begin
   pt := ClientToScreen(point(x, y)) ;
   SetCursorPos(pt.x, pt.y) ;
end;

end.
