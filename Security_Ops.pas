unit Security_Ops;

interface

function CreateDatePassword(dtDate : TDateTime = 0.0) : String;

implementation

uses
  SysUtils,
  Str_Ops, TimeDate;

//***************************************************************************
//
//  FUNCTION  : CreateDatePassword
//
//  I/P       : dtDate : TDateTime = 0.0 - The date for which the password is
//                required. If none is given, today's date is used.
//
//  O/P       : String - A 5-digit password that is related to the given/PC date
//
//  OPERATION : Creates a 5-digit number based on the given/current date.
//
//  UPDATED   : 2021-05-10
//
//***************************************************************************
function CreateDatePassword(dtDate : TDateTime = 0.0) : String;
var
  uiDateCode : Word;
  ucShift : Byte;
  n : Integer;

begin
  if (dtDate = 0.0) then
  begin
    dtDate := Date;
  end;

  uiDateCode := IntegerDate(dtDate);
  ucShift := IntegerDate(dtDate) mod 13;
  for n := 0 to ucShift do
    if ((uiDateCode and $0001) = $0001) then
      uiDateCode := uiDateCode div 2 + $8000
    else
      uiDateCode := uiDateCode div 2;
  // Convert this number into Hex.
  result := Front_Padded(IntToStr(uiDateCode),'0',5);
end; // CreateDatePassword

end.
