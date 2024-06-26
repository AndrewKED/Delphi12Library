unit Screen_Ops;

interface

function ScreenSizeOK(widthMinimum : Integer;
                      heightMinimum : Integer;
                      messageError : String) : Boolean;

implementation

uses
  Vcl.Forms, Vcl.Dialogs,
  Dialog_Ops;

//***************************************************************************
//
//  FUNCTION  : ScreenSizeOK
//
//  I/P       : widthMinimum : Integer - Minimum expected width
//
//              heightMinimum : Integer - Minimum expected height
//
//              messageError : String - Message to display in an Error Dialog
//                on non-compliance. No error is shown if this is empty.
//
//  O/P       : Boolean - TRUE if the requirements are met.
//
//  OPERATION : Checks that the screen size meets minimum requirements in
//              width and/or height. Optionally displays an error message if
//              this is not so, and returns a compliance flag
//
//  UPDATED   : 2019-08-21
//
//***************************************************************************
function ScreenSizeOK(widthMinimum : Integer;
                      heightMinimum : Integer;
                      messageError : String) : Boolean;
begin
  if ((Screen.Height < heightMinimum) or
      (Screen.Width < widthMinimum)) then
  begin
    if (messageError <> '') then
    begin
      Dialog_Ops.MessageDlg(messageError, mtError, [mbOK], 0);
    end;
    result := FALSE;
  end // if
  else
  begin
    result := TRUE;
  end; // else
end; // ScreenSizeOK

end.
