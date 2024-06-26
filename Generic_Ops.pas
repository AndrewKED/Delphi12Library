unit Generic_Ops;

interface

function IfThenV(test : boolean;
                 result1 : variant;
                 result2 : variant) : variant;

implementation

//***************************************************************************
//
//  FUNCTION  : IfThenV
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2018-10-12
//
//***************************************************************************
function IfThenV(test : boolean;
                 result1 : variant;
                 result2 : variant) : variant;
begin
  if (test) then
    result := result1
  else
    result := result2;
end; // IfThenV


end.
