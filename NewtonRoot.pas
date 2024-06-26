unit NewtonRoot;

//***************************************************************************
//
// DESCRIPTION:
//  Used to find the root of an equation i.e. x, where F(x) = 0
//
// TO BE DONE:
//
//  *
//
// VERSIONS:
//
//    Update Date : 2009-11-20
//    Changes Made :
//      * Changed the terminating dCorrection, to dMaxError i.e. F(x) <= Abs(dMaxError)
//
//
//***************************************************************************

interface

type
  fnNewtonFunction = function (X : extended) : extended;

function FindNewtonRoot(fnEquation : fnNewtonFunction;
                        fnDerivative : fnNewtonFunction;
                        dStart : Double;
                        dMaxError : Double;
                        iMaxIterations : integer) : Double;

implementation

uses Math;

//***************************************************************************
//
//  FUNCTION  : FindNewtonRoot
//
//  I/P       : fnEquation (fnNewtonFunction) - The equation to be solved.
//
//              fnDerivative (fnNewtonFunction) - The derivative of the equation wrt X
//
//              dStart (double) - A suitable first guess
//
//              dMaxError (double) - the maximum permissable error
//
//              iMaxIterations (integer) - The maximum number of attempts  
//
//  O/P       :
//
//  OPERATION : At least 1 iteration.
//
//              Find the x where F(x) = 0, to a given accuracy
//
//              Repeat until F(x) <= Abs(dMaxError)
//              Only carry out a given maximum number of iterations.
//
//              Return an error (NAN) if F(x) > Abs(dMaxError), after the
//              maximum number of iterations, or if a flat point is found (i.e. slope = 0)
//
//  UPDATED   :
//
//***************************************************************************
function FindNewtonRoot(fnEquation : fnNewtonFunction;
                        fnDerivative : fnNewtonFunction;
                        dStart : Double;
                        dMaxError : Double;
                        iMaxIterations : integer) : Double;
var
  dCorrection : Double;
  iIteration : Integer;
  dEquation : Double;
  dSlope : Double;

begin
  result := dStart;
  iIteration := 0;
  repeat
    dEquation := fnEquation(result);
    dSlope := fnDerivative(result);
    if (dSlope <> 0.0) then
      dCorrection := dEquation / dSlope
    else
      dCorrection := 0.0;
    result := result - dCorrection;
    Inc(iIteration);
  until ((Abs(fnEquation(result)) <= dMaxError) or
         (iIteration > iMaxIterations) or
         (dSlope = 0.0));

  if ((Abs(fnEquation(result)) > dMaxError) or
      (dSlope = 0.0)) then
    result := NAN;
end; // NewtonRoot

end.
