unit LSLinear;

//***************************************************************************
//
// DESCRIPTION:
//  Declares a class that may be used for the fitting of straight lines to
//  given data, using the method of least squares
//
// REFERENCES:
// http://mathworld.wolfram.com/LeastSquaresFitting.html
// http://mathworld.wolfram.com/CorrelationCoefficient.html
//
// TO BE DONE:
//
// To go further into curve fitting :
// https://www.experts-exchange.com/questions/27915779/Bezier-Smoothing-of-Data.html
// http://www.alglib.net
//
// VERSIONS:
//    Update Date : 2009-08-21
//    Changes Made :
//      * Added LastX and LastY
//
//    Update Date : ?
//    Changes Made :
//      * Added Force Equation
//
//    Update Date : 2006/05/30
//    Changes Made :
//      * First Issue
//
//***************************************************************************

interface

type
  TLSqLinFit = class
  private
    aeXValues : array of Extended;
    aeYValues : array of Extended;
    eSumX : Extended;
    eSumY : Extended;
    eSumXX : Extended;
    eSumYY : Extended;
    eSumXY : Extended;
    eSSxx : Extended;
    eSSyy : Extended;
    eSSxy : Extended;
    eLastX : Extended;      // The last X value that was added
    eLastY : Extended;      // the last Y value that was added
//!!    iHeadPointer : Integer;
//!!    iTailPointer : Integer;
//!!
//!!    iCount : Integer;       // The number of included points in the data
    procedure RemoveOldestPoint;
  protected
  public
  //!! These are internal variables, and should be exposed as read-only!
    iHeadPointer : Integer;
    iTailPointer : Integer;
    Size : Integer;         // set to -1 if there is to be no maximum permissable points
    Count : Integer;        // The number of included points in the data
    eAverageX : Extended;
    eAverageY : Extended;
    constructor Create;
    destructor Destroy; override;

    procedure ForceEquation(eSlope : Extended;
                            eYIntercept : Extended;
                            eStartingX : Extended;
                            eXIncrement : Extended);
    procedure Initialise(iPoints : Integer);
    procedure Resize(iPoints : Integer);
    procedure Add(eX,eY : Extended);
    procedure Remove(eX,eY : Extended);
    procedure Clear;
    procedure Reset;
    function Slope : Extended;
    function YIntercept : Extended;
    function XIntercept : Extended;
    function VarianceX : Extended;
    function VarianceY : Extended;
    function Covariance : Extended;
    function GetLowestX : Extended;
    function GetHighestX : Extended;
    function LastX : Extended;
    function LastY : Extended;
    function X(offset : Integer) : Extended;
    function Y(offset : Integer) : Extended;
    function CalculateY(x : Extended) : Extended;
    function CalculateX(y : Extended) : Extended;
    function StdDevY : Extended;
    function Available : Boolean;
    function Full : Boolean;
  end; // class

implementation

uses Math;

//***************************************************************************
//
//  FUNCTION  : ForceEquation
//
//  I/P       : eSlope (extended) - the desired slope to be obtained
//
//              eYIntercept (extended) - The desired Y Intercept
//
//              eStartingX (extended) - the first X-point to be added to the
//                set of points
//
//              eXIncrement (extended) - the increment between added points.
//
//  O/P       : None
//
//  OPERATION : This operation will only have effect if the curve is created
//              from a fixed number of points.   Pre-filling of the points
//              to create a curve holds no value otherwise.
//
//  UPDATED   : 2025-02-26
//
//***************************************************************************
procedure TLSqLinFit.ForceEquation(eSlope : extended;
                                   eYIntercept : extended;
                                   eStartingX : extended;
                                   eXIncrement : extended);
var
  n : Integer;
begin
  if (Size <> -1) then
  begin
    for n := 1 to Size do
    begin
      Add(eStartingX, eSlope * eStartingX + eYIntercept);
      eStartingX := eStartingX + eXIncrement;
    end; // for
  end; // if
end; // ForceEquation

//***************************************************************************
//
//  FUNCTION  : RemoveOldestPoint
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : This function should only be called if there is data in the
//              array.
//
//  UPDATED   : 2011-03-30
//
//***************************************************************************
procedure TLSqLinFit.RemoveOldestPoint;
begin
  eSumX := eSumX - aeXValues[iTailPointer];
  eSumY := eSumY - aeYValues[iTailPointer];
  eSumXX := eSumXX - aeXValues[iTailPointer]*aeXValues[iTailPointer];
  eSumYY := eSumYY - aeYValues[iTailPointer]*aeYValues[iTailPointer];
  eSumXY := eSumXY - aeXValues[iTailPointer]*aeYValues[iTailPointer];

  // Advance the tail pointer, since we have caught up with it.
  iTailPointer := (iTailPointer + 1) mod Size;
end; // RemoveOldestPoint

//***************************************************************************
//
//  FUNCTION  : Add
//
//  I/P       : eX,eY (extended) - The point to be added to the fit.
//
//  O/P       : None.
//
//  OPERATION : Adds the point and updates the sums.
//              Removes the oldest point, if required, in the situation where
//              the fit is being applied to a limited number of points.
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
procedure TLSqLinFit.Add(eX,eY : extended);
begin
  // Check if we are working with a limited number of points
  if (Size >= 2) then
  begin
    // Check whether we have yet collected the number of points to which this
    // fit will be limited.
    if (Count >= Size) then
    begin
      // If we have collected the maximum permissable number of points, start
      // by removing the influence of the oldest (first-added) point.   This is
      // about to be overwritten with the new data.
      // Note : this is not necessarily the point with the lowest X value.
      RemoveOldestPoint;

      // Insert the point to be added at the old tail position
      aeXValues[iHeadPointer] := eX;
      aeYValues[iHeadPointer] := eY;

      // Store these as the last added
      eLastX := eX;
      eLastY := eY;

      // Move the head pointer on.   It will now always be the same as the
      // tail pointer.
      iHeadPointer := iTailPointer;

      // Update the summation terms
      eSumX := eSumX + eX;
      eSumY := eSumY + eY;
      eSumXX := eSumXX + eX*eX;
      eSumYY := eSumYY + eY*eY;
      eSumXY := eSumXY + eX*eY;
    end // if
    else
    begin
      aeXValues[iHeadPointer] := eX;
      aeYValues[iHeadPointer] := eY;
      Inc(Count);
      iHeadPointer := (iHeadPointer + 1) mod Size;

      // Store these as the last added
      eLastX := eX;
      eLastY := eY;

      // Update the summation terms
      eSumX := eSumX + eX;
      eSumY := eSumY + eY;
      eSumXX := eSumXX + eX*eX;
      eSumYY := eSumYY + eY*eY;
      eSumXY := eSumXY + eX*eY;
    end; // else
  end // if
  else
  begin
    // No limit to the number of points being added (so we don't use the X
    // and Y arrays).

    // Update the summation terms
    eSumX := eSumX + eX;
    eSumY := eSumY + eY;
    eSumXX := eSumXX + eX*eX;
    eSumYY := eSumYY + eY*eY;
    eSumXY := eSumXY + eX*eY;

    Inc(Count);
  end; // else

  // Update the averages
  eAverageX := eSumX / Count;
  eAverageY := eSumY / Count;

  // Update the sums of squares
  eSSxx := eSumXX - Count*eAverageX*eAverageX;
  eSSyy := eSumYY - Count*eAverageY*eAverageY;
  eSSxy := eSumXY - Count*eAverageX*eAverageY;
end; // Add

//***************************************************************************
//
//  FUNCTION  : Remove
//
//  I/P       : eX,eY (extended) - The point to be removed from the fit.
//
//  O/P       : None.
//
//  OPERATION : Removes a point and updates the sums.
//              This is currently only possible with the unlimited array size.
//
//              It is expected that the given point pair begin removed was,
//              sometime earlier, added as a point pair. (Otherwise this type
//              of operation would not work correctly.)
//
//              This operation to determine trends (slopes) when iterating through
//              a separately held two-dimensional array.
//
//  UPDATED   : 2018-06-19
//
//***************************************************************************
procedure TLSqLinFit.Remove(eX,eY : extended);
begin
  // The size of the least-squares array must be unlimited
  if (Size < 2) then
  begin
    if (Count > 0) then
    begin
      // Update the summation terms
      eSumX := eSumX - eX;
      eSumY := eSumY - eY;
      eSumXX := eSumXX - eX*eX;
      eSumYY := eSumYY - eY*eY;
      eSumXY := eSumXY - eX*eY;

      Dec(Count);

      if (Count > 0) then
      begin
        // Update the averages
        eAverageX := eSumX / Count;
        eAverageY := eSumY / Count;

        // Update the sums of squares
        eSSxx := eSumXX - Count*eAverageX*eAverageX;
        eSSyy := eSumYY - Count*eAverageY*eAverageY;
        eSSxy := eSumXY - Count*eAverageX*eAverageY;
      end // if
      else
      begin
        eAverageX := 0.0;
        eAverageY := 0.0;

        // Update the sums of squares
        eSSxx := 0.0;
        eSSyy := 0.0;
        eSSxy := 0.0;
      end;
    end;
  end; // else
end; // Remove

(*
//***************************************************************************
//
//  FUNCTION  : Insert
//
//  I/P       : eX,eY (extended) - The point to be added to the fit.
//
//              discardLowestX : Boolean - TRUE to discard the lowest X value
//                (potentially including this onde) if the array size is limited.
//                FALSE to discard the highest X value (potentially including
//                this one) if the array size is limited.
//
//  O/P       : None.
//
//  OPERATION : Inserts the given XY point, in order, removing the lowerst, or
//              highest X point if the array is size limited.
//
//              Updates the running sums.
//
//              Insert calls Add on unlimited array sizes.
//
//  UPDATED   : 2018-06-19
//
//***************************************************************************
procedure TLSqLinFit.Insert(eX,eY : extended;
                            discardLowestX : Boolean);
begin
  // Check if we are working with a limited number of points
  if (Size >= 2) then
  begin
    // Check whether we have yet collected the number of points to which this
    // fit will be limited.
    if (Count >= Size) then
    begin
      // If we have collected the maximum permissable number of points, start
      // by removing the influence of the oldest (first-added) point.   This is
      // about to be overwritten with the new data
      RemoveOldestPoint;

      // Insert the point to be added at the old tail position
      aeXValues[iHeadPointer] := eX;
      aeYValues[iHeadPointer] := eY;

      // Store these as the last added
      eLastX := eX;
      eLastY := eY;

      // Move the head pointer on.   It will now always be the same as the
      // tail pointer.
      iHeadPointer := iTailPointer;

      // Update the summation terms
      eSumX := eSumX + eX;
      eSumY := eSumY + eY;
      eSumXX := eSumXX + eX*eX;
      eSumYY := eSumYY + eY*eY;
      eSumXY := eSumXY + eX*eY;
    end // if
    else
    begin
      aeXValues[iHeadPointer] := eX;
      aeYValues[iHeadPointer] := eY;
      Inc(Count);
      iHeadPointer := (iHeadPointer + 1) mod Size;

      // Store these as the last added
      eLastX := eX;
      eLastY := eY;

      // Update the summation terms
      eSumX := eSumX + eX;
      eSumY := eSumY + eY;
      eSumXX := eSumXX + eX*eX;
      eSumYY := eSumYY + eY*eY;
      eSumXY := eSumXY + eX*eY;
    end; // else
  end // if
  else
  begin
    // No limit to the number of points being added (so we don't use the X
    // and Y arrays).

    // Update the summation terms
    eSumX := eSumX + eX;
    eSumY := eSumY + eY;
    eSumXX := eSumXX + eX*eX;
    eSumYY := eSumYY + eY*eY;
    eSumXY := eSumXY + eX*eY;

    Inc(Count);
  end; // else

  // Update the averages
  eAverageX := eSumX / Count;
  eAverageY := eSumY / Count;

  // Update the sums of squares
  eSSxx := eSumXX - Count*eAverageX*eAverageX;
  eSSyy := eSumYY - Count*eAverageY*eAverageY;
  eSSxy := eSumXY - Count*eAverageX*eAverageY;
end; // Add
*)
//***************************************************************************
//
//  FUNCTION  : Slope
//
//  I/P       : None
//
//  O/P       : (extended) - the y-slope of the least squares fit line
//                (0.0 if there are insufficient points to form a slope)
//
//  OPERATION : Return the y-slope of the line (y wrt x) that has been
//              fitted to the given points.
//
//              Slope = b = SSxy/SSxx
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
function TLSqLinFit.Slope : extended;
begin
  if (eSSxx <> 0.0) then
    result := eSSxy / eSSxx
  else
    result := 0.0;
end; // Slope

//***************************************************************************
//
//  FUNCTION  : YIntercept
//
//  I/P       : None
//
//  O/P       : (extended) - the Y-intercept of the least squares fit line
//                (0.0 if there are insufficient points to form a line)
//
//  OPERATION : Return the y-intercept (x=0) of the line that has been fitted
//              to the given points.
//
//              Yint = a = Ave(y) - b * Ave(x)
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
function TLSqLinFit.YIntercept : extended;
begin
  if (eSSxx <> 0.0) then
    result := eAverageY - Slope * eAverageX
  else
    result := 0.0;
end; // YIntercept

//***************************************************************************
//
//  FUNCTION  : XIntercept
//
//  I/P       : None
//
//  O/P       : (extended) - the X-intercept of the least squares fit line
//                (0.0 if there are insufficient points to form a line)
//
//  OPERATION : Return the x-intercept (y=0) of the line that has been fitted
//              to the given points.
//
//              Xint = -a/b
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
function TLSqLinFit.XIntercept : extended;
var
  eSlope : extended;
begin
  // Check that we have sufficient points to create a slope
  if (eSSxx <> 0.0) then
  begin
    // Check that the slope is not flag horizontal
    eSlope := Slope;
    if (eSlope <> 0.0) then
      result := - (eAverageY - eSlope * eAverageX) / Slope
    else
      result := 0.0;
  end // if
  else
    result := 0.0;
end; // XIntercept

//***************************************************************************
//
//  FUNCTION  : VarianceX
//
//  I/P       : None
//
//  O/P       : (extended) - sigma^2 x
//
//  OPERATION : Return the Variance of X (sigma^2 x)
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
function TLSqLinFit.VarianceX : extended;
begin
  if (Count > 0) then
    result := eSSxx / Count
  else
    result := 0.0;
end; // VarianceX

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
function TLSqLinFit.StdDevY : extended;
var
  sumDMeanSquared : extended;
  n : Integer;

begin
  if (Count > 0) then
  begin
    sumDMeanSquared := 0;
    n := 0;
    while (n < Count) do
    begin
      sumDMeanSquared := sumDMeanSquared + Power(aeYValues[n] - eAverageY, 2);
      Inc(n);
    end;
    Result := Sqrt(sumDMeanSquared / Count);
  end // if
  else
    Result := 0.0;
end; // StdDevX

//***************************************************************************
//
//  FUNCTION  : VarianceY
//
//  I/P       : None
//
//  O/P       : (extended) - sigma^2 y
//
//  OPERATION : Return the Variance of Y (sigma^2 y)
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
function TLSqLinFit.VarianceY : extended;
begin
  if (Count > 0) then
    result := eSSyy / Count
  else
    result := 0.0;
end; // VarianceY

//***************************************************************************
//
//  FUNCTION  : Covariance
//
//  I/P       : None
//
//  O/P       : (extended) - cov(x,y)
//
//  OPERATION : Return the covariance
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
function TLSqLinFit.Covariance : extended;
begin
  if (Count > 0) then
    result := eSSxy / Count
  else
    result := 0.0;
end; // Covariance

//***************************************************************************
//
//  FUNCTION  : Initialise
//
//  I/P       : Size (integer) -
//                >= 2 to specify the maximum number of points that will be
//                  kept in the least-squares linear fit calculations.
//                < 2 to specify that there is no limit to the number of
//                  points that could be included.
//
//  O/P       : None.
//
//  OPERATION : Establishes a set of values that may be used to calculate
//              a least-squares straight line fit to data
//
//  UPDATED   :  2006/05/30
//
//***************************************************************************
procedure TLSqLinFit.Initialise(iPoints : Integer);
begin
  Reset;
  if (iPoints >= 2) then
  begin
    Size := iPoints;
    SetLength(aeXValues,iPoints);
    SetLength(aeYValues,iPoints);
  end; // if
end; // InitLSqSmLinFit

//***************************************************************************
//
//  FUNCTION  : Clear
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Clears accumulated data, but does not change the sizing
//
//  UPDATED   : 2019-05-29
//
//***************************************************************************
procedure TLSqLinFit.Clear;
begin
  eAverageX := 0.0;
  eAverageY := 0.0;
  Count := 0;

  eSumX := 0.0;
  eSumY := 0.0;
  eSumXX := 0.0;
  eSumYY := 0.0;
  eSumXY := 0.0;
  eSSxx := 0.0;
  eSSyy := 0.0;
  eSSxy := 0.0;

  iHeadPointer := 0;
  iTailPointer := 0;

  eLastX := NAN;
  eLastY := NAN;
end; // Clear

//***************************************************************************
//
//  FUNCTION  : Reset
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Clears accumulated data and sets to the default operation
//              i.e. no maximum permissable points
//
//  UPDATED   : 2019-05-29
//
//***************************************************************************
procedure TLSqLinFit.Reset;
begin
  Clear;

  Size := -1;
  SetLength(aeXValues,0);
  SetLength(aeYValues,0);
end; // Reset

//***************************************************************************
//
//  FUNCTION  : GetLowestX
//
//  I/P       : None
//
//  O/P       : (extended) - the value of X in the sample with the lowest
//                value of X.
//
//  OPERATION : The return value of this function is only valid if we are
//              dealing with a limited number of points.   Unlimited points
//              do not store X and Y values, so we can't determine the range.
//
//  UPDATED   : 2019-05-16
//
//***************************************************************************
function TLSqLinFit.GetLowestX : extended;
var
  n : Integer;
begin
  result := 0.0;
  if (Size <> -1) then
  begin
    //!! Should we not be able to return a value if we have one point? i.e. the single point
    if (Count > 1) then
    begin
      n := iTailPointer;
      result := 1.1E4931;
      repeat
        result := Min(aeXValues[n], result);
        n := (n+1) mod Size;
      until (n = iHeadPointer);
    end; // if
  end; // if
end; // GetLowestX

//***************************************************************************
//
//  FUNCTION  : GetHighestX
//
//  I/P       : None
//
//  O/P       : (extended) - the value of X in the sample with the highest
//                value of X.
//
//  OPERATION : The return value of this function is only valid if we are
//              dealing with a limited number of points.   Unlimited points
//              do not store X and Y values, so we can't determine the range.
//
//              Search backwards to speed up, since normally the poinst would
//              be added in order of X, and so iHeadPointer would be indicating
//              the highest X value.
//
//  UPDATED   : 2006/06/21
//
//***************************************************************************
function TLSqLinFit.GetHighestX : extended;
var
  n : Integer;
begin
  result := -1.1E4931;
  if (Size <> -1) then
  begin
    //!! Should we not be able to return a value if we have one point? i.e. the single point
    if (Count > 1) then
    begin
      n := iHeadPointer;
      repeat
        Dec(n);
        if (n < 0) then
          n := Size - 1;
        result := Max(aeXValues[n],result);
      until (n = iTailPointer);
    end // if
    else
      result := 0.0;
  end // if
  else
    result := 0.0;
end; // GetHighestX

//***************************************************************************
//
//  FUNCTION  : LastX
//
//  I/P       : None
//
//  O/P       : The last X value that was added
//
//  OPERATION : Returns the last X value that was added
//
//  UPDATED   : 2009-08-21
//
//***************************************************************************
function TLSqLinFit.LastX : extended;
begin
  result := eLastX;
end; // LastX

//***************************************************************************
//
//  FUNCTION  : LastY
//
//  I/P       : None
//
//  O/P       : The last Y value that was added
//
//  OPERATION : Returns the last Y value that was added
//
//  UPDATED   : 2009-08-21
//
//***************************************************************************
function TLSqLinFit.LastY : extended;
begin
  result := eLastY;
end; // LastY

//***************************************************************************
//
//  FUNCTION  : X
//
//  I/P       : offset : Integer - Offset into the added data, with index 0
//                being the first added.
//
//  O/P       : Extended - The reqested X value, or NAN if not available.
//
//  OPERATION : Return the indexed X value
//
//              Note that X values are not necessarily in order. They are in
//              the order in which they were added.
//
//  UPDATED   : 2022-06-02
//
//***************************************************************************
function TLSqLinFit.X(offset : Integer) : extended;
begin
  if (offset < Count) then
  begin
    Result := aeXValues[(iHeadPointer + offset) mod Size];
  end
  else
  begin
    Result := NAN;
  end;
end; // X

//***************************************************************************
//
//  FUNCTION  : Y
//
//  I/P       : offset : Integer - Offset into the added data, with index 0
//                being the first added.
//
//  O/P       : Extended - The reqested Y value, or NAN if not available.
//
//  OPERATION : Return the indexed Y value
//
//  UPDATED   : 2022-06-02
//
//***************************************************************************
function TLSqLinFit.Y(offset : Integer) : extended;
begin
  if (offset < Count) then
  begin
    Result := aeYValues[(iHeadPointer + offset) mod Size];
  end
  else
  begin
    Result := NAN;
  end;
end; // Y

//***************************************************************************
//
//  FUNCTION  : CalculateY
//
//  I/P       : x : Extended - The X value, for which Y must be computed
//
//  O/P       : Extended - The reqested Y value, or NAN if not available.
//
//  OPERATION : Return the calculated Y value
//
//  UPDATED   : 2022-06-02
//
//***************************************************************************
function TLSqLinFit.CalculateY(x : Extended) : Extended;
begin
  if (Count >= 2) then
  begin
    Result := Slope * x + YIntercept;
  end // if
  else
  begin
    Result := NAN;
  end;
end; // CalculateY

//***************************************************************************
//
//  FUNCTION  : CalculateX
//
//  I/P       : y : Extended - The Y value, for which X must be computed
//
//  O/P       : Extended - The reqested X value, or NAN if not available.
//
//  OPERATION : Return the calculated X value
//
//  UPDATED   : 2022-06-02
//
//***************************************************************************
function TLSqLinFit.CalculateX(y : Extended) : Extended;
begin
  if ((Count >= 2) and (Slope <> 0.0)) then
  begin
    Result := (y - YIntercept) / Slope;
  end // if
  else
  begin
    Result := NAN;
  end;
end; // CalculateX

//***************************************************************************
//
//  FUNCTION  : Available
//
//  I/P       : None
//
//  O/P       : TRUE if there are more than two points in the graph, and
//              the slope is not infinite.
//
//  OPERATION :
//
//  UPDATED   : 2006/09/05
//
//***************************************************************************
function TLSqLinFit.Available : Boolean;
begin
  result := ((Count >= 2) and (eSSxx <> 0.0));
end; // Available

//***************************************************************************
//
//  FUNCTION  : Full
//
//  I/P       : None
//
//  O/P       : (boolean) - TRUE if, on a fixed number of points, the maximum
//                number of points are being used to determine the line.
//                FALSE if this line is made up of an unlimited number of
//                samples, or if fewer than the maximum number of points are
//                being used to determine the line.
//
//  OPERATION :
//
//  UPDATED   : 2007/05/25
//
//***************************************************************************
function TLSqLinFit.Full : Boolean;
begin
  result := ((Size <> -1) and (Count >= Size));
end; // Full

//***************************************************************************
//
//  FUNCTION  : Resize
//
//  I/P       : iPoints (integer) - The new number of points to be used in
//
//
//  O/P       :
//
//  OPERATION : Used to change the number of points used in the calculation
//              without losing previously accumulated data.   If decreasing the
//              number of points, the first-added data is lost.
//
//  UPDATED   : 2011-03-30
//
//***************************************************************************
procedure TLSqLinFit.Resize(iPoints : Integer);
var
  aeXTransfer : array of extended;
  aeYTransfer : array of extended;
  n : Integer;
  m : Integer;
  iLose : Integer;

begin
  // Don't do anything if this is an unlimited point determination
  // or if we are requesting an invalid number of points in the new system.
  if ((Size <> -1) and (iPoints >= 2)) then
  begin
    // Check if there is any existing data to be handled.
    if (Count > 0) then
    begin
      // Check if decreasing the number of points being used to determine the line
      if (iPoints < Size) then
      begin
        // We need to lose a number of points of the oldest data (the smaller of
        // the difference in data size, or the number of points already collected)
        iLose := Min(Size - iPoints,Count);
        while (iLose > 0) do
        begin
          RemoveOldestPoint;
          Dec(iLose);
        end; // while
      end; // if

      // Now check if we are making any change to the number of points being used to determine the line
      // (Increasing or decreasing)
      if (iPoints <> Size) then
      begin
        // Create a temporary array for the X and Y-data
        SetLength(aeXTransfer,iPoints);
        SetLength(aeYTransfer,iPoints);

        // Transfer the existing samples into a temporary array, placing the
        // oldest sample into the first element.
        n := iTailPointer;
        m := 0;
        repeat
          aeXTransfer[m] := aeXValues[n];
          aeYTransfer[m] := aeYValues[n];
          Inc(m);
          n := (n + 1) mod Size;
        until (n = iHeadPointer);

        // Now set the data array to the new required size
        SetLength(aeXValues,iPoints);
        SetLength(aeYValues,iPoints);

        // Copy the data back to the sample arrays
        n := 0;
        while (n < m) do
        begin
          aeXValues[n] := aeXTransfer[n];
          aeYValues[n] := aeYTransfer[n];
          Inc(n);
        end; // while

        // Reset the pointers.   The tail pointer indexes the earliest point and the
        // head pointer indexes a new, unused location
        iTailPointer := 0;
        iHeadPointer := n mod iPoints;
      end; // if

      // Set the new maximum number of points
      Size := iPoints;
      Count := Min(Count,Size);
    end // if
    else
    begin
      // No data to be transferred.   Simply resize the arrays
      SetLength(aeXValues,iPoints);
      SetLength(aeYValues,iPoints);
    end; // else
  end; // if
end; // Resize

//***************************************************************************
//
//  FUNCTION  : Create
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Initialises the values in a least squares fit for an unlimited
//              number of points.
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
constructor TLSqLinFit.Create;
begin
  Reset;
end; // Create

//***************************************************************************
//
//  FUNCTION  : Destroy
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Sets the array of X and Y data to a minimum value.
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
destructor TLSqLinFit.Destroy;
begin
  Reset;
  inherited Destroy;
end; // Destroy

end. // Maths
