unit Maths;

//***************************************************************************
//
// DESCRIPTION:
//  Provides a number of helpful numerical and mathematical functions and
//  procedures.
//
// TO BE DONE:
//
//  * Removed RadToDeg and DegToRad which are in Math unit.
//
// VERSIONS:
//
//    Update Date : 2009-06-06
//    Changes Made :
//      * Added PaddedSignedReal
//
//    Update Date : 2008-08-08
//    Changes Made :
//      * Added BinStrToInt and IntToBinStr
//
//    Update Date : 2006/12/13
//    Changes Made :
//      * Removed MinI, MaxI, MinF, MaxF
//      * Added the constant BASE_E
//
//    Update Date : 2006/11/27
//    Changes Made :
//      * Added LinearEqu and ZOn3PointPlane
//
//    Update Date : 2006/10/09
//    Changes Made :
//      * Simplified Polar2DCompassToRectangular
//
//    Update Date : 2006/09/19
//    Changes Made :
//      * Removed HexToInt - it is fully covered in StrToInt / StrToInt64
//        StrToInt64Def etc
//
//    Update Date : 2006/07/24
//    Changes Made :
//      * Chaged RoundTo to RoundDecimals, to avoid a naming clash with a
//        function in the Math unit.
//
//    Update Date : 2005/06/03
//    Changes Made :
//      * Fixed PaddedSignedInt
//
//    Update Date : 2005/04/26
//    Changes Made :
//      * Added WrapAround
//
//    Update Date : 2005/04/22
//    Changes Made :
//      * Added PaddedSignedInt
//      * Added this header
//
//***************************************************************************

interface

const
  BASE_E = 2.718281828;

procedure DegToDMS(dDegrees : Double;
                   var iDegrees : Integer;
                   var iMinutes : Integer;
                   var dSeconds : double);
function DMSToDeg(dDeg : Double;
                  dMin : Double;
                  dSec : double) : Double;
function BCDToBin(bcd : byte) : byte;
function BinToBCD(bin : byte) : byte;
procedure Get_Line_Equ(var eSlope,eOffset : extended;
                       rLX,rLY,rRX,rRY : extended);
function Remainder(eValue : extended;
                   eDivisor : extended) : extended;
function BlockCount(iValue : UInt64;
                    sizeBlock : UInt64) : UInt64;
function RoundDecimals(eValue : extended;
                       iDecimals : integer) : extended;
function PaddedSignedInt(liValue : longint;
                         iWidth : integer) : String;
function PaddedSignedReal(eValue : extended;
                          iWidth : Integer;
                          iDecimals : integer) : String;
function WrapAround(liValue : longint;
                    liMin,liMax : longint) : longint;
function RealWrap(dValue : Double;
                  dMin,dMax : double) : Double;
procedure Polar2DCompassToRectangular(dMagnitude : Double;
                                      dAngle : Double;
                                      var dEast : Double;
                                      var dNorth : double);
procedure RectangularToPolar2DCompass(dEast : Double;
                                      dNorth : Double;
                                      var dMagnitude : Double;
                                      var dAngle : double) overload;
procedure FromTo2Polar2DCompass(eastFrom, northFrom : Double;
                                eastTo, northTo : Double;
                                var dMagnitude : Double;
                                var dAngle : double) overload;
procedure LinearEqu(x1,y1 : Double;
                    x2,y2 : Double;
                    var m : Double;
                    var c : double);
function ZOn3PointPlane(dXValue,dYValue : Double;
                        dX1,dY1,dZ1 : Double;
                        dX2,dY2,dZ2 : Double;
                        dX3,dY3,dZ3 : double) : Double;
function Normalise(eValue : extended) : extended;
function PointInTriangle(dX,dY : Double;
                         dX1,dY1 : Double;
                         dX2,dY2 : Double;
                         dX3,dY3 : double) : boolean;
function StdDevN(adValues : array of double;
                 iNumPoints : integer) : Double;
function MeanN(adValues : array of double;
               iNumPoints : integer) : Double;
function PolynomialValue(coefficients : array of double;
                         x : Double) : Double;

implementation

uses Math, SysUtils, Str_Ops;

//***************************************************************************
//
//  FUNCTION    :   DegToDMS
//
//  I/P         :   dDegrees (double) : Degrees to be converted
//
//
//
//  O/P         :   iDegrees (integer) :
//
//                      iMinutes (integer) :
//
//                      dSeconds (double) :
//
//  OPERATION   :   Converts a given decimal degrees value into the
//                      component degrees, minutes and seconds parts.
//                      Degrees and minutes will be integers, and seconds
//                      will be fractional.
//
//                      Signs are not well handled or defined (do all items
//                      become negative if dDegrees is negative?), so we
//                      should assume that dDegrees >= 0.0.
//
//  UPDATED     :   2004/10/07
//
//***************************************************************************
procedure DegToDMS(dDegrees : Double;
                   var iDegrees : Integer;
                   var iMinutes : Integer;
                   var dSeconds : double);
begin
  iDegrees := Trunc(dDegrees);
  iMinutes := Trunc(Frac(dDegrees) * 60.0);
  dSeconds := (dDegrees - iDegrees - iMinutes/60.0) * 3600.0;
end; // DegToDMS

//***************************************************************************
//
//  FUNCTION  : DMSToDeg
//
//  I/P       :
//
//  O/P       : (double) - The result in decimal degrees
//
//  OPERATION : Converts given degrees, minutes and seconds into
//              the decimal degrees value.
//
//              NB : All values are treated as if positive.
//
//  UPDATED   : 2006/11/08
//
//***************************************************************************
function DMSToDeg(dDeg : Double;
                  dMin : Double;
                  dSec : double) : Double;
begin
  result := Abs(dDeg) + Abs(dMin)/60.0 + Abs(dSec)/3600.0;
end; // DMSToDeg

{****************************************************************************}
{*
{*      FUNCTION    :   BCDToBin
{*
{*      I/P         :
{*
{*      O/P         :
{*
{*      OPERATION   :
{*
{*      UPDATED     :
{*
{****************************************************************************}
function BCDToBin(bcd : byte) : byte;
begin
  result := ((bcd div $10) * 10) + (bcd mod $10);
end; {BCDToBin}

{****************************************************************************}
{*
{*      FUNCTION    :   BinToBCD
{*
{*      I/P         :
{*
{*      O/P         :
{*
{*      OPERATION   :
{*
{*      UPDATED     :
{*
{****************************************************************************}
function BinToBCD(bin : byte) : byte;
begin
  result := (bin div 10) * $10 + (bin mod 10);
end; {BinToBCD}

//***************************************************************************
//
//  FUNCTION    :   Get_Line_Equ
//
//  I/P         :   rLX,rLY (extended) : The left hand points of the line
//                      rRX,rRY (extended) : The right hand points of the line
//
//  O/P         :   eSlope (extended) : Slope of the line
//                      eOffset (extended) : Y-intercept of the line
//
//  OPERATION   :   Determines the slope (m) and offset (c) of the line
//                      defined by the two end-points, as given in the equation
//                                 y = mx + c
//
//  UPDATED     :   2003/12/22
//
//***************************************************************************
procedure Get_Line_Equ(var eSlope,eOffset : extended;
                       rLX,rLY,rRX,rRY : extended);
const
  MAX_EXTENDED = 1.1E4932;
begin
// Check for a non-vertical slope
  if (rLX<>rRX) then
  begin
// A nicely behaved line, so determine slope and offset
    eSlope := (rRY - rLY)/(rRx - rLX);
    eOffset := rLY - (eSlope * rLX);
  end // if
  else
// A vertical slope or undefined slope
    if (rRY=rLY) then
    begin
// Points are equal, so not possible to determine the slope
      eSlope := 0.0;
      eOffset := 0.0;
    end // if
    else
// Slope is vertical
      if (rRy>rLY) then
      begin
// Slop is vertical, "sloping" upwards
        eSlope := MAX_EXTENDED;
        eOffset := -MAX_EXTENDED;
      end // if
      else
      begin
// Slop is vertical, "sloping" downwards
        eSlope := -MAX_EXTENDED;
        eOffset := MAX_EXTENDED;
      end; // else
end; // Get_Line_Equ

//***************************************************************************
//
//  FUNCTION  : LinearEqu
//
//  I/P       : x1,y1 (double) - The first point on the line
//
//              x2,y2 (double) - The second point on the line
//
//  O/P       : m (double) - The slope of the line.   NAN if the slope is
//                infinite.
//
//              c (double) - The y intercept of the line for x = 0.
//                NAN if the slope is infinite.
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure LinearEqu(x1,y1 : Double;
                    x2,y2 : Double;
                    var m : Double;
                    var c : double);
begin
  if (x1 = x2) then
  begin
    m := NAN;
    c := NAN;
  end // if
  else
  begin
    m := (y2-y1) / (x2-x1);
    c := y1 - (m * x1);
  end; // else
end; // LinearEqu

//***************************************************************************
//
//  FUNCTION    :   Remainder
//
//  I/P         :   eValue (extended) : The value to be divided
//                      eDivisor (extended) : The divisor
//
//  O/P         :   (extended) : The result
//
//  OPERATION   :   Returning the remainder after dividing the value
//                      by the divisor.
//
//  UPDATED     :   2002/02/01
//
//***************************************************************************
function Remainder(eValue : extended;
                   eDivisor : extended) : extended;
begin
  result := eValue - (Int(eValue / eDivisor) * eDivisor);
end; // Remainder

//***************************************************************************
//
//  FUNCTION  : BlockCount
//
//  I/P       : iValue : UInt64 - The value to be contained
//
//              sizeBlock : UInt64 - The size of the containing blocks
//
//  O/P       : UInt64 - iValue div sizeBlock, but rounded up 1 if there is a
//                remainder.
//
//  OPERATION : Returns a value indicating the number of blocks of given size
//                that are needed to hold the given value.
//
//  UPDATED   : 2019-12-11
//
//***************************************************************************
function BlockCount(iValue : UInt64;
                    sizeBlock : UInt64) : UInt64;
begin
  result := iValue div sizeBlock;
  if (iValue mod sizeBlock <> 0) then
  begin
    Inc(result);
  end;
end; // BlockCount

//***************************************************************************
//
//  FUNCTION  :   RoundDecimals
//
//  I/P       :   eValue (extended) : The value to be rounded
//
//                iDecimals (integer) : The number of decimal places required
//
//  O/P       :   (extended) : The result
//
//  OPERATION :   Rounds a number to the given number of decimal places.
//                There is a problem in that some numbers that should round
//                up do not.   For example, the number 302.085 is actually
//                stored in an extended variable as 302.08499999999998.   If
//                rounding to 2 decimal places, it would round to 302.08
//                instead of 302.09.
//
//                This rounding algorithm attempts to overcome the problem
//                where a value that is just below the rounding point is not
//                accurately stored.   It works to 5 places beyond the
//                requested number of decimal places, and rounds from
//                there.
//
//                Thus a number like 0.00499996 will be rounded at 2
//                decimal places to 0.01, and not 0.00.
//
//                Since the algorithm makes use of an extended real type,
//                which can have 19-20 significant digits the algorithm can
//                only process 14-15(?) significant digits.
//
//  UPDATED   :   2009-10-22
//
//***************************************************************************
function RoundDecimals(eValue : extended;
                       iDecimals : integer) : extended;
var
  eMultiplier : extended;
  eTemp : extended;

begin
  // Get the multiplier - this itterative method may be quicker than using logarithms.
  eMultiplier := 100000.0;
  while (iDecimals > 0) do
  begin
    eMultiplier := eMultiplier * 10.0;
    Dec(iDecimals);
  end; // while
(*
  // This method was in use up to 2010-10-14
  // and version 1.255 of BCD, where the change may have the most effect
  // It incorrectly rounded negative numbers

  // Handle rounding of negative numbers correctly
  if (eValue * eMultiplier <= -0.5) then
  begin
    eTemp := Int((eValue * eMultiplier) - 0.5);
  end // if
  else
  begin
    eTemp := Int((eValue * eMultiplier) + 0.5);
  end; // else
    result := Int((eTemp + 50000) / 100000 ) / (eMultiplier / 100000.0);
*)

  if (eValue * eMultiplier <= -0.5) then
  begin
    eTemp := Int((eValue * eMultiplier) - 0.5);
    result := Int((eTemp - 50000) / 100000 ) / (eMultiplier / 100000.0);
  end // if
  else
  begin
    eTemp := Int((eValue * eMultiplier) + 0.5);
    result := Int((eTemp + 50000) / 100000 ) / (eMultiplier / 100000.0);
  end; // else

end; // RoundDecimals

//***************************************************************************
//
//  FUNCTION    :   PaddedSignedInt
//
//  I/P         :   liValue (longint) - The value
//
//                  iWidth (integer) - The number of digits after the sign
//
//  O/P         :   (string)
//
//  OPERATION   :   Given an integer value and field witdh, it returns a
//                  string that starts with a '+' or '-', followed by the
//                  given number of digits, front-padded with zeroes.
//
//  UPDATED     :   2005/04/22
//
//***************************************************************************
function PaddedSignedInt(liValue : longint;
                         iWidth : integer) : String;
var
  sTemp : String;
begin
  sTemp := Front_Padded(IntToStr(Abs(liValue)),'0',iWidth);
  if (liValue >= 0) then
    result := '+' + sTemp
  else
    result := '-' + sTemp
end; // PaddedSignedInt

//***************************************************************************
//
//  FUNCTION    :   PaddedSignedReal
//
//  I/P         :   eValue (extended) - The value
//
//                  iWidth (integer) - The number of characters after the sign,
//
//                  iDecimals (integer) - The number of decimal places,
//
//  O/P         :   (string)
//
//  OPERATION   :   Given a real value, field width and decimal places, it
//                  returns a string that starts with a '+' or '-', followed by
//                  the given number of characters, front-padded with zeroes.
//
//  UPDATED     :   2009-06-06
//
//***************************************************************************
function PaddedSignedReal(eValue : extended;
                          iWidth : Integer;
                          iDecimals : integer) : String;
begin
  if (eValue >= 0.0) then
    result := '+'
  else                
    result := '-';
  result := result + Front_Padded(Format('%.*f',[iDecimals,Abs(eValue)]),'0',iWidth);
end; // PaddedSignedReal


//***************************************************************************
//
//  FUNCTION  : WrapAround
//
//  I/P       : liValue (longint) - The value to be limited.
//
//              liMin,liMax (longint) - The highest and lowest values that
//                are permitted.
//
//  O/P       : longint - The value
//
//  OPERATION : Handles wrapping around of numbers that should remain
//              within a range e.g. indexes to a circular array.
//
//  UPDATED   : 2005/04/25
//
//***************************************************************************
function WrapAround(liValue : longint;
                    liMin,liMax : longint) : longint;
begin
  if ((liValue > liMax) or (liValue < liMin)) then
  begin
    while (liValue > liMax) do
      liValue := liValue - (liMax - liMin + 1);
    while (liValue < liMin) do
      liValue := liValue + (liMax - liMin + 1);
  end; // else
  result := liValue;
end; // WrapAround

//***************************************************************************
//
//  FUNCTION  : RealWrap
//
//  I/P       : dValue : double - The value to be limited.
//
//              dMin : double - The lowest permissable value.   dValue must be
//                equal to, or greater than this value.
//
//              dMax : double - The warp-around point.   dValue must be less than
//                this value.
//
//  O/P       : double - The value
//
//  OPERATION : Handles wrapping around of numbers that should remain
//              within a range e.g. direction, which remains 0 <= x < 360
//
//  UPDATED   : 2012-06-18
//
//***************************************************************************
function RealWrap(dValue : Double;
                  dMin,dMax : double) : Double;
begin
  if ((dValue >= dMax) or (dValue < dMin)) then
  begin
    while (dValue >= dMax) do
      dValue := dValue - (dMax - dMin);
    while (dValue < dMin) do
      dValue := dValue + (dMax - dMin);
  end; // else
  result := dValue;
end; // RealWrap

//***************************************************************************
//
//  FUNCTION  : Polar2DCompassToRectangular
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Convert from a compass vector (magnitude and direction) into
//              cartesean co-ordinate steps in the easterly and northerly
//              direction.
//
//  UPDATED   : 2006/10/09
//
//***************************************************************************
procedure Polar2DCompassToRectangular(dMagnitude : Double;
                                      dAngle : Double;
                                      var dEast : Double;
                                      var dNorth : double);
begin
  dEast := Sin(DegToRad(dAngle)) * dMagnitude;
  dNorth := Cos(DegToRad(dAngle)) * dMagnitude;
end; // Polar2DCompassToRectangular

//***************************************************************************
//
//  FUNCTION  : RectangularToPolar2DCompass
//
//  I/P       : dEast : Double - The change in easterly component
//
//              dNorth : Double - The change in northerly component
//
//  O/P       : var dMagnitude : Double - The magnitude of the vector
//
//              var dAngle : double - The direction of the vector

//
//  OPERATION : Convert a change in east/north components into a compass vector
//
//  UPDATED   : 2006/03/03
//
//***************************************************************************
procedure RectangularToPolar2DCompass(dEast : Double;
                                      dNorth : Double;
                                      var dMagnitude : Double;
                                      var dAngle : double);
begin
  if (dEast <> 0.0) then
  begin
    dAngle := RadToDeg(ArcTan(dNorth/dEast));
    if (dEast >= 0.0) then
      dAngle := 90.0 - dAngle
    else
      dAngle := 270.0 - dAngle;
  end // if
  else
    if (dNorth >= 0) then
      dAngle := 180.0
    else
      dAngle := 0.0;

  // Catch any "funnies" that may case angles outside of the normal range.
  if (dAngle < 0.0) then
    dAngle := dAngle + 360.0
  else
    if (dAngle >= 360.0) then
      dAngle := dAngle - 360.0;

  dMagnitude := Sqrt(dEast*dEast + dNorth*dNorth);
end; // RectangularToPolar2DCompass

//***************************************************************************
//
//  FUNCTION  : FromTo2Polar2DCompass
//
//  I/P       : eastFrom, northFrom : Double - Starting point co-ordinates
//
//              eastTo, northTo : Double; - Ending co-ordinates
//
//  O/P       : var dMagnitude : Double - The magnitude of the vector
//
//              var dAngle : double - The direction of the vector

//
//  OPERATION : Derive a compass vector from starting and ending co-ordinates
//
//  UPDATED   : 2022-07-15
//
//***************************************************************************
procedure FromTo2Polar2DCompass(eastFrom, northFrom : Double;
                                eastTo, northTo : Double;
                                var dMagnitude : Double;
                                var dAngle : double);
begin
  RectangularToPolar2DCompass(eastTo - eastFrom, northTo - northFrom,
                              dMagnitude, dAngle);
end; // FromTo2Polar2DCompass


//***************************************************************************
//
//  FUNCTION  : ZOn3PointPlane
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Given three 3-D points that define a flat plane, determine
//              Z-value for given X- and Y-values.
//
//              From http://en.wikipedia.org/wiki/Plane_%28mathematics%29
//              A plane passing through (x1,y1,z1),(x2,y2,z2),(x3,y3,z3)
//              can be expressed by the following determinante equation
//
//              |  x-x1  y-y1  z-z1 |     | x-x1  y-y1  z-z1 |
//              | x2-x1 y2-y1 z2-z1 |  =  | x-x2  y-y2  z-z2 | = 0
//              | x3-x1 y3-y1 z3-z1 |     | x-x3  y-y3  z-z3 |
//
//              From http://en.wikipedia.org/wiki/Determinant,
//              The determinant of a 3x3 matrix A is given as
//              det(A) = A11.A22.A33 + A13.A21.A32 + A12.A23.A31 -
//                       A13.A22.A31 - A11.A23.A32 - A12.A21.A33
//
//              Remember Aij is row i, column j
//              From http://en.wikipedia.org/wiki/Matrix_%28mathematics%29
//
//              We therefore get
//              det(A) = (x-x1)(y-y2)(z-z3) + (z-z1)(x-x2)(y-y3) + (y-y1)(z-z2)(x-x3) -
//                       (z-z1)(y-y2)(x-x3) - (x-x1)(z-z2)(y-y3) - (y-y1)(x-x2)(z-z3)
//                     = 0
//              Given that we know x,y and the points, we can reduce this to
//                   0 = A(z-z3) + B(z-z1) + C(z-z2) -
//                       D(z-z1) - E(z-z2) - F(z-z3)
//                   0 = Az - Az3 + Bz - Bz1 + Cz - Cz2 - Dz + Dz1 - Ez + Ez2 - Fz + Fz3
//                   z = (Az3 + Bz1 + Cz2 - Dz1 - Ez2 - Fz3) / (A + B + C - D - E - F)
//
//  UPDATED   : 2006/11/27
//
//***************************************************************************
function ZOn3PointPlane(dXValue,dYValue : Double;
                        dX1,dY1,dZ1 : Double;
                        dX2,dY2,dZ2 : Double;
                        dX3,dY3,dZ3 : double) : Double;
var
  A,B,C,D,E,F : Double;
  dTemp : Double;
begin
  A := (dXValue - dX1) * (dYValue - dY2);
  B := (dXValue - dX2) * (dYValue - dY3);
  C := (dYValue - dY1) * (dXValue - dX3);
  D := (dYValue - dY2) * (dXValue - dX3);
  E := (dXValue - dX1) * (dYValue - dY3);
  F := (dYValue - dY1) * (dXValue - dX2);

  // Test for an unsolvable situation
  dTemp := A + B + C - D - E - F;
  if (dTemp <> 0.0) then
    result := ((A * dZ3) + (B * dZ1) + (C * dZ2) - (D * dZ1) - (E * dZ2) - (F * dZ3)) / dTemp
  else
    result := NAN;
end; // ZOn3PointPlane

//***************************************************************************
//
//  FUNCTION  : Normalise
//
//  I/P       : eValue (extended) - The value to be normalised
//
//  O/P       : (extended) - the normalised value
//
//  OPERATION : Normalise a value (remove integer portion).   An application
//              is in rotation.   +10.6 rotations puts you in the same position
//              as +0.6 rotations.   -1.2 rotations puts you in the same position
//              as +0.8 rotations.
//
//  UPDATED   : 2007/02/02
//
//***************************************************************************
function Normalise(eValue : extended) : extended;
begin
  result := eValue - Int(eValue);
  if (result < 0.0) then
    result := result + 1.0;
end; // Normalise

//***************************************************************************
//
//  FUNCTION  : PointInTriangle
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Based on an algorithm discussed at
//              http://mcraefamily.com/athHelp/GeometryPointAndTriangle2.htm
//
//              Imagine standing on one corner of the triangle, looking at the
//              next corner.  Keep point P in view, noting whether it's somewhere
//              on your left or on your right or neither.  Now walk along the side
//              of the triangle. When you get to the second corner, turn to face
//              the third corner, keeping point P in view. Walk along the second
//              side of the triangle. When you get to the third  corner, turn to
//              face the first corner, still keeping point P in view.  Now walk
//              along the third side of the triangle back to the point from which
//              you started. Did P stay on the same side of you during your entire
//              trip?  That is, did P stay always on the left or always on the
//              right?  If so, P is inside the triangle. If not, P is not inside
//              the triangle.
//
//              So the crux of this program is to develop a function that tells
//              us whether a point is to the "left" or "right" of a particular
//              line as we look in a particular direction along the line.
//
//              Given two different points, A=(x1,y1), and B=(x2,y2), the line,
//              AB, that passes through points A and B is given by the equation,
//
//              (y-y1)(x2-x1) = (x-x1)(y2-y1)
//
//              The set of (x,y) that satisfies this equation is the line that
//              passes through those two points. To show this is true, first notice
//              that it is linear.  That is, it has the form ay+b = cx+d, where a,
//              b, c, and d are constants.  Now notice that when x=x1 and y=y1, the
//              equation is satisfied -- 0=0.  Finally notice that when x=x2 and y=y2,
//              the equation is also satisfied.
//
//              Now consider a function suggested by the equation of this line AB,
//
//              fAB(x,y) = (y-y1)(x2-x1) - (x-x1)(y2-y1)
//
//              fAB(x,y) is zero for all points on the line, and non-zero for
//              all other points.  In fact, if you're standing on B looking at
//              A, then fAB(x,y) is negative for all points (x,y) to your left,
//              and fAB(x,y) is positive for all points (x,y) to your right!
//              This is a very interesting function.  It represents twice the
//              "signed area" of the triangle (x,y),(x1,y1),(x2,y2) and also
//              the determinant of a certain matrix.
//
//  UPDATED   : 2007-09-13
//
//***************************************************************************
function PointInTriangle(dX,dY : Double;
                         dX1,dY1 : Double;
                         dX2,dY2 : Double;
                         dX3,dY3 : double) : boolean;
  function fAB : Double;
  begin
    result := (dY - dY1) * (dX2 - dX1) - (dX - dX1) * (dY2 - dY1);
  end; // fAB
  function fBC : Double;
  begin
    result := (dY - dY2) * (dX3 - dX2) - (dX - dX2) * (dY3 - dY2);
  end; // fBC
  function fCA : Double;
  begin
    result := (dY - dY3) * (dX1 - dX3) - (dX - dX3) * (dY1 - dY3);
  end; // fCA
begin
//!! Not yet tested 2007-09-13
  result := ((fAB * fBC) > 0.0) and ((fBC * fCA) > 0.0);
end; // PointInTriangle

//***************************************************************************
//
//  FUNCTION  : PointInPolygon
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Lifted from
//              http://alienryderflex.com/polygon/
//
//        Andrew Warning - the algorithm required the number of sides to be
//          passed to it.   Either write it like that, or there may be problems
//          of there are concurrent vertices.
//
//  UPDATED   :
//
//***************************************************************************
(*function PointInPolygon(dX,dY : Double;
                        aPolygon : array of TPoint) : boolean
//  Globals which should be set before calling this function:
//
//  int    polySides  =  how many corners the polygon has
//  float  polyX[]    =  horizontal coordinates of corners
//  float  polyY[]    =  vertical coordinates of corners
//  float  x, y       =  point to be tested
//
//  (Globals are used in this example for purposes of speed.  Change as
//  desired.)
//
//  The function will return YES if the point x,y is inside the polygon, or
//  NO if it is not.  If the point is exactly on the edge of the polygon,
//  then the function may return YES or NO.
//
//  Note that division by zero is avoided because the division is protected
//  by the "if" clause which surrounds it.

bool pointInPolygon() {

  int      i, j=polySides-1 ;
  boolean  oddNodes=NO      ;

  for (i=0; i<polySides; i++) {
    if (polyY[i]<y && polyY[j]>=y
    ||  polyY[j]<y && polyY[i]>=y) {
      if (polyX[i]+(y-polyY[i])/(polyY[j]-polyY[i])*(polyX[j]-polyX[i])<x) {
        oddNodes=!oddNodes; }}
    j=i; }

  return oddNodes; }
*)

//***************************************************************************
//
//  FUNCTION  : StdDevN
//
//  I/P       : adValues (array of double) - Zero- based array, not necessarily
//                full, that holds the values.
//
//              iNumPoints (integer) - The number of points in adValues to be
//                used to create the Standard Deviation.
//
//  O/P       : (double) - Standard Deviation of the given point values.
//
//  OPERATION :
//
//  UPDATED   : 2009-09-07
//
//***************************************************************************
function StdDevN(adValues : array of double;
                 iNumPoints : integer) : Double;
var
  adTransfer : array of double;
  n : Integer;

begin
  try
    if (iNumPoints > 0) then
    begin
      SetLength(adTransfer,iNumPoints);
      for n := 0 to iNumPoints-1 do
        adTransfer[n] := adValues[n];
      result := StdDev(adTransfer);
    end // if
    else
      result := NAN;
  except
    // I have come across a problem where all elements in the array are equal, a
    // illegal floating point operation exception is raised.
    result := 0.0;
  end; // except
end; // StdDevN

//***************************************************************************
//
//  FUNCTION  : MeanN
//
//  I/P       : adValues (array of double) - Zero- based array, not necessarily
//                full, that holds the values.
//
//              iNumPoints (integer) - The number of points in adValues, from
//                the 0-th point, to be used to create the mean.
//
//  O/P       : (double) - Mean of the given point values.
//
//  OPERATION :
//
//  UPDATED   : 2009-09-07
//
//***************************************************************************
function MeanN(adValues : array of double;
               iNumPoints : integer) : Double;
var
  adTransfer : array of double;
  n : Integer;

begin
  try
    if (iNumPoints > 0) then
    begin
      SetLength(adTransfer,iNumPoints);
      for n := 0 to iNumPoints-1 do
        adTransfer[n] := adValues[n];
      result := Mean(adTransfer);
    end // if
    else
      result := NAN;
  except
    result := NAN;
  end; // except
end; // MeanN

//***************************************************************************
//
//  FUNCTION  : PolynomialValue
//
//  I/P       : coefficients : array of double - (Zero-based) array holding
//                the polynomial coefficients for powers of X.
//
//              x : Double - The X value at which the equation is applied.
//
//  O/P       : Double - The result of the equation
//
//  OPERATION : Calculate the result of a polynomial equation at given X value
//
//              Only positive, integer powers of X (including X = 0) are supported.
//
//  UPDATED   : 2022-06-09
//
//***************************************************************************
function PolynomialValue(coefficients : array of double;
                         x : Double) : Double;
var
  n : Integer;

begin
  Result := 0.0;

  n := Length(coefficients) - 1;
  while (n >= 0) do
  begin
    Result := Result + coefficients[n];
    if (n > 0) then
    begin
      Result := Result * x;
    end; // if
    Dec(n);
  end;
end; // PolynomialValue

////***************************************************************************
////
////  FUNCTION  : FMod
////
////  I/P       :
////
////  O/P       :
////
////  OPERATION : Floating point modulo function
////              In Delphi integer modulo, answer takes the sign of the dividend
////
////              Removed 2020-08-07, because Delphi has FMod in System.Math
////
////  UPDATED   :
////
////***************************************************************************
//function FMod(dDividend : Double;
//              dDivisor : double) : Double;
//var
//  iTimes : Double;
//
//begin
//
//  if (dDivisor = 0) then
//    raise Exception.Create('FMod division by zero')
//  else
//  begin
//
//    iTimes := Int(Abs(dDividend) / Abs(dDivisor));
//    if (dDividend < 0) then
//      result := - (Abs(dDividend) - iTimes * Abs(dDivisor))
//    else
//      result := Abs(dDividend) - iTimes * Abs(dDivisor);
//  end; // else
//end; // FMod
//
//
end. // Maths


