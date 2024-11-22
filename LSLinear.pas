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

uses
  System.Math, System.Generics.Collections, System.Generics.Defaults;

const
  LSLF_MAX_POINTS = 500;
  LSLF_NO_POINT_RECORDING = -1;

type
  TLSLFRetention = (LSLFR_UNLIMITED, LSLFR_FIFO, LSLFR_MIN_X);
  TCoordinate2 = record
    x : Extended;
    y : Extended;
  end;

  TLSqLinFit = class
  private
    fFIFOPoints : array of TCoordinate2;
    fOrderedPoints : TList<TCoordinate2>;
    fSumX : Extended;       // The sum of X values
    fSumY : Extended;       // the sum of Y values
    fSumXX : Extended;      // The sum of X*X values
    fSumYY : Extended;      // The sum of Y*Y values
    fSumXY : Extended;      // The sum of X*Y values
    fSSxx : Extended;       // The sum of X*X values - n * AveX * AveX
    fSSyy : Extended;       // The sum of Y*Y values - n * AveY * AveY
    fSSxy : Extended;       // The sum of X*Y values - n * AveX * AveY
    fLastX : Extended;      // The last X value that was added
    fLastY : Extended;      // the last Y value that was added
    fAverageX : Extended;
    fAverageY : Extended;
    fSumDYMeanSquared : Extended;
    fSumDXMeanSquared : Extended;
    fPointerHead : Integer;   // The index of fFIFOPoints where the next point will be added
    fPointerTail : Integer;   // The index of the "oldest/first" point in fFIFOPoints
    fMaxPoints : Integer;     // If retention is not infinite, this is the maximum permissable points
    fCount : Integer;         // The number of included points in an UNLIMITED fit
    fFull : Boolean;
    fEmpty : Boolean;
    fRetention : TLSLFRetention;
    fMinimumX : Extended;
    procedure SortOrderedPoints;
    function GetHeadPointer : Integer;
    function GetTailPointer : Integer;
    function GetSize : Integer;
    function GetFull : Boolean;
    function GetEmpty : Boolean;
    procedure SetSize(newSize : Integer);
    function GetCount : Integer;
    function GetAverageX : Extended;
    function GetAverageY : Extended;
    function GetMinX : Extended;
    procedure SetMinX(newMinX : Extended);
    procedure RemoveTailPoint;
    procedure RemoveMinXPoint;
  protected
  public
    //!! These are internal variables, and should be exposed as read-only!
    property HeadPointer : Integer read GetHeadPointer;
    property TailPointer : Integer read GetTailPointer;
    property Size : Integer read GetSize write SetSize;
    property Count : Integer read GetCount;
    property AverageX : Extended read GetAverageX;
    property AverageY : Extended read GetAverageY;
    property MinX : Extended read GetMinX write SetMinX;
    property Full : Boolean read GetFull;
    property Empty : Boolean read GetEmpty;
    constructor Create(lslfr : TLSLFRetention = LSLFR_FIFO; maxPoints : Integer = LSLF_MAX_POINTS);
    destructor Destroy; override;
    procedure ForceLoadYInterceptEquation(newSlope : Extended;
                                          newYIntercept : Extended;
                                          startingX : Extended;
                                          incrementX : Extended);
    procedure ForceLoadXInterceptEquation(newSlope : Extended;
                                          newXIntercept : Extended;
                                          startingX : Extended;
                                          incrementX : Extended);
    procedure ForceLoadThrough(newSlope : Extended;
                               throughX : Extended;
                               throughY : Extended;
                               incrementX : Extended);
    procedure Add(newX : extended;
                  newY : extended;
                  newMinX : extended) overload;
    procedure Add(newX : extended;
                  newY : extended) overload;
    procedure Remove(removeX, removeY : Extended);
    procedure Clear;
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
    function StdDevX : Extended;
    function StdDevY : Extended;
    function Available : Boolean;
  end; // class

implementation

uses
  System.SysUtils;

//***************************************************************************
//
//  FUNCTION  : GetAverageX
//
//  I/P       : None
//
//  O/P       : Extended - the average X value, or NaN if no samples collected
//
//  OPERATION : Get the average X value of all samples used in the fit.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
function TLSqLinFit.GetAverageX : Extended;
begin
  Result := fAverageX;
end;

//***************************************************************************
//
//  FUNCTION  : GetAverageY
//
//  I/P       : None
//
//  O/P       : Extended - the average Y value, or NaN if no samples collected
//
//  OPERATION : Get the average Y value of all samples used in the fit.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
function TLSqLinFit.GetAverageY : Extended;
begin
  Result := fAverageY;
end;

//***************************************************************************
//
//  FUNCTION  : GetMinX
//
//  I/P       : None
//
//  O/P       : Extended - The minimum X value that is being kept in the
//                accumulated points.
//
//  OPERATION : Get the object's minimum X value, as would be used if the
//              retention policy is LSLFR_MIN_X.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
function TLSqLinFit.GetMinX : Extended;
begin
  Result := fMinimumX;
end;

//***************************************************************************
//
//  FUNCTION  : SetMinX
//
//  I/P       : newMinX : Extended - The new lowest X value that should be kept.
//
//  O/P       : None;
//
//  OPERATION : Adjust the minimum X value of points that are being stored in
//              an object with a retention policy of LSLFR_MIN_X.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
procedure TLSqLinFit.SetMinX(newMinX : Extended);
begin
  if (fRetention <> LSLFR_MIN_X) then
  begin
    Exit;
  end;

  while (fOrderedPoints[0].x < newMinX) do
  begin
    RemoveMinXPoint;
  end;

  fMinimumX := newMinX;
end;


//***************************************************************************
//
//  FUNCTION  : GetHeadPointer
//
//  I/P       : None
//
//  O/P       : Integer - the index of the head pointer. (-1 if not a FIFO fit)
//
//  OPERATION : In a LSLFR_FIFO fit (with a limited number of samples), get the
//              array index which is the "oldest" (first added) data sample.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
function TLSqLinFit.GetHeadPointer : Integer;
begin
  if (fRetention = LSLFR_FIFO) then
  begin
    Result := fPointerHead;
  end // if
  else
  begin
    Result := -1;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : GetHeadPointer
//
//  I/P       : None
//
//  O/P       : Integer - the index of the tail pointer. (-1 if not a FIFO fit)
//
//  OPERATION : In a LSLFR_FIFO fit (with a limited number of samples), get the
//              array index which is the "oldest" (first added) data sample.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
function TLSqLinFit.GetTailPointer : Integer;
begin
  if (fRetention = LSLFR_FIFO) then
  begin
    Result := fPointerTail;
  end // if
  else
  begin
    Result := -1;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : GetSize
//
//  I/P       : None
//
//  O/P       : Integer - the maximum number of samples in a FIFO or MIN_X fit
//                -1 if an unlimited number of samples are used.
//
//  OPERATION : Get the maximum number of samples that may contribute to the
//              least squares fit.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
function TLSqLinFit.GetSize : Integer;
begin
  if (fRetention <> LSLFR_UNLIMITED) then
  begin
    Result := fMaxPoints;
  end // if
  else
  begin
    Result := -1;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : SetSize
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
procedure TLSqLinFit.SetSize(newSize : Integer);
var
  transfer : array of TCoordinate2;
  n : Integer;
  m : Integer;
  losePoints : Integer;

begin
  if (fRetention = LSLFR_UNLIMITED) then
  begin
    Exit;
  end;

  if (newSize < 2) then
  begin
    raise Exception.Create('TLSqLinfit : Invalid number of retention points');
    Exit;
  end;

  case fRetention of
    LSLFR_FIFO:
    begin
      // Ensure that the number of held points is no greater than the new size.
      while (GetCount > newSize) do
      begin
        RemoveTailPoint;
      end; // while

      // If changing the size, the FIFO storage will need to be rebuilt.
      if (newSize <> fMaxPoints) then
      begin
        // Create a temporary array for the retained points.
        SetLength(transfer, newSize);

        // Transfer the existing samples into a temporary array, placing the
        // oldest sample into the first element.
        n := fPointerTail;
        m := 0;
        while (n <> fPointerHead) do
        begin
          transfer[m].x := fFIFOPoints[n].x;
          transfer[m].y := fFIFOPoints[n].y;
          Inc(m);
          n := (n + 1) mod fMaxPoints;
        end;

        // Set the data array to the new required size
        SetLength(fFIFOPoints, newSize);

        // Copy the data back
        n := 0;
        while (n < m) do
        begin
          fFIFOPoints[n].x := transfer[n].x;
          fFIFOPoints[n].y := transfer[n].y;
          Inc(n);
        end; // while

        // Reset the pointers.   The tail pointer indexes the earliest point and the
        // head pointer indexes a new, unused location
        fPointerTail := 0;
        fPointerHead := n mod newSize;
        fMaxPoints := newSize;
      end; // if
    end;

    LSLFR_MIN_X:
    begin
      while (GetCount > newSize) do
      begin
        RemoveMinXPoint;
      end; // while

      fMaxPoints := newSize;
    end;

    else
      Exit;
  end;
end; // SetSize

//***************************************************************************
//
//  FUNCTION  : GetCount
//
//  I/P       : None
//
//  O/P       : Integer - the number of samples being used in the fit
//
//  OPERATION : Get the number of samples received/being used for the least
//              squares fit.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
function TLSqLinFit.GetCount : Integer;
begin
  case fRetention of
    LSLFR_UNLIMITED: Result := fCount;

    LSLFR_FIFO:
    begin
      if (fPointerHead > fPointerTail) then
      begin
        Result := fPointerHead - fPointerTail;
      end // if
      else
      begin
        if (fEmpty) then
        begin
          Result := 0;
        end
        else
        begin
          Result := fMaxPoints - fPointerTail + fPointerHead;
        end;
      end;
    end;

    LSLFR_MIN_X:
    begin
      Result := fOrderedPoints.Count;
    end;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : ForceLoadYInterceptEquation
//
//  I/P       : newSlope : Extended - the desired slope to be obtained
//                (traditionally "m")
//
//              eYIntercept : Extended - The desired Y-axis intercept value
//                at X=0 (traditionally "c")
//
//              eStartingX : Extended - the first X-point to be added to the
//                set of points
//
//              eXIncrement : Extended - the increment between added points.
//
//  O/P       : None
//
//  OPERATION : Load the TLSqLinFit object with points (from a given point,
//              with X increments) so that the given slope and Y-offset (at X=0)
//              are represented.
//
//              For TLSqLinFit objects with a limited points retention policy,
//              the maximum number of points are added.
//
//              For TLSqLinFit objects with an unlimited points retention policy,
//              only two points are added.
//
//  UPDATED   : 2024-10-25
//
//***************************************************************************
procedure TLSqLinFit.ForceLoadYInterceptEquation(newSlope : Extended;
                                                 newYIntercept : Extended;
                                                 startingX : Extended;
                                                 incrementX : Extended);
var
  n : Integer;
  x : Extended;
  toAdd : Integer;

begin
  Clear;

  // Fill objects with limited points storage, but only insert two points for
  // the unlimited points retention policy.
  toAdd := fMaxPoints;
  if (fRetention = LSLFR_UNLIMITED) then
  begin
    toAdd := 2;
  end; // if

  // Ensure that the minimum X policy is obeyed, if required.
  if (fRetention = LSLFR_MIN_X) then
  begin
    startingX := Max(startingX, fMinimumX);
  end;

  x := startingX;

  for n := 0 to toAdd-1 do
  begin
    Add(x, newSlope * x + newYIntercept);
    startingX := startingX + incrementX;
  end; // for
end; // ForceLoadYInterceptEquation

//***************************************************************************
//
//  FUNCTION  : ForceEquation
//
//  I/P       : newSlope : Extended - the desired slope to be obtained
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
//  OPERATION : Load the TLSqLinFit object with points (from a given point,
//              with X increments) so that the given slope and X-offset (at Y=0)
//              are represented.
//
//              For objects with a limited points retention policy, the maximum
//              number of points are added.
//
//              For objects with an unlimited points retention policy, two
//              points are added.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
procedure TLSqLinFit.ForceLoadXInterceptEquation(newSlope : Extended;
                                                 newXIntercept : Extended;
                                                 startingX : Extended;
                                                 incrementX : Extended);
var
  n : Integer;
  x : Extended;
  c : Extended;
  toAdd : Integer;

begin
  Clear;

  // Fill objects with limited points storage, but only insert two points for
  // the unlimited points retention policy.
  toAdd := fMaxPoints;
  if (fRetention = LSLFR_UNLIMITED) then
  begin
    toAdd := 2;
  end; // if

  // Ensure that the minimum X policy is obeyed, if required.
  if (fRetention = LSLFR_MIN_X) then
  begin
    startingX := Max(startingX, fMinimumX);
  end;

  x := startingX;
  c := -newSlope * newXIntercept;

  for n := 0 to toAdd-1 do
  begin
    Add(x, newSlope * x + c);
    startingX := startingX + incrementX;
  end; // for
end; // ForceXInterceptEquation


//***************************************************************************
//
//  FUNCTION  : ForceLoadThrough
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Add data to the fit, to create the given slope, and ensure
//              passing through the given point.
//
//  UPDATED   : 2024-10-25
//
//***************************************************************************
procedure TLSqLinFit.ForceLoadThrough(newSlope : Extended;
                                      throughX : Extended;
                                      throughY : Extended;
                                      incrementX : Extended);
var
  n : Integer;
  x : Extended;
  y : Extended;
  toAdd : Integer;

begin
  Clear;

  // Fill objects with limited points storage, but only insert two points for
  // the unlimited points retention policy.
  toAdd := fMaxPoints;
  if (fRetention = LSLFR_UNLIMITED) then
  begin
    toAdd := 2;
  end; // if

  x := throughX;
  y := throughY;

  for n := 0 to toAdd - 1 do
  begin
    Add(x, y);
    x := x + incrementX;
    y := y + incrementX * newSlope;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : RemoveTailPoint
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Remove the earliest-added point in a LSFR_FIFO fit.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
procedure TLSqLinFit.RemoveTailPoint;
begin
  // This function is only applicable to FIFO retention objects
  if (fRetention <> LSLFR_FIFO) then
  begin
    Exit;
  end;

  if (not fEmpty) then
  begin
    fSumX := fSumX - fFIFOPoints[fPointerTail].x;
    fSumY := fSumY - fFIFOPoints[fPointerTail].y;
    fSumXX := fSumXX - fFIFOPoints[fPointerTail].x * fFIFOPoints[fPointerTail].x;
    fSumYY := fSumYY - fFIFOPoints[fPointerTail].y * fFIFOPoints[fPointerTail].y;
    fSumXY := fSumXY - fFIFOPoints[fPointerTail].x * fFIFOPoints[fPointerTail].y;

    // Advance the tail pointer
    fPointerTail := (fPointerTail + 1) mod fMaxPoints;

    fFull := FALSE;
    fEmpty := (fPointerTail = fPointerHead);
  end;
end; // RemoveOldestPoint

//***************************************************************************
//
//  FUNCTION  : RemoveMinXPoint
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Remove the point with the lowest X value.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
procedure TLSqLinFit.RemoveMinXPoint;
begin
  // This function is only applicable to Minimum X retention objects
  if (fRetention <> LSLFR_MIN_X) then
  begin
    Exit;
  end;

  if (fOrderedPoints.Count > 0) then
  begin
    fSumX := fSumX - fOrderedPoints[0].x;
    fSumY := fSumY - fOrderedPoints[0].y;
    fSumXX := fSumXX - fOrderedPoints[0].x * fOrderedPoints[0].x;
    fSumYY := fSumYY - fOrderedPoints[0].y * fOrderedPoints[0].y;
    fSumXY := fSumXY - fOrderedPoints[0].x * fOrderedPoints[0].y;

    fOrderedPoints.Delete(0);

    fFull := FALSE;
    fEmpty := (fOrderedPoints.Count = 0);
  end;
end; // RemoveMinXPoint

//***************************************************************************
//
//  FUNCTION  : Remove
//
//  I/P       : removeX, removeY (extended) - The point to be removed from the fit.
//
//  O/P       : None.
//
//  OPERATION : Removes a point from an unlimited points fit object.
//
//              It is expected/logical that the given point being removed was,
//              sometime earlier, added as a point pair. (Otherwise the use of
//              this function would not make sense.)
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
procedure TLSqLinFit.Remove(removeX, removeY : extended);
begin
  // This function is only applicable to unlimited retention objects
  if (fRetention <> LSLFR_UNLIMITED) then
  begin
    Exit;
  end;

  if (GetCount <= 0) then
  begin
    // Nothing needs to be done if no points have been collected
    Exit;
  end;

  // Update the summation terms
  fSumX := fSumX - removeX;
  fSumY := fSumY - removeY;
  fSumXX := fSumXX - removeX * removeX;
  fSumYY := fSumYY - removeY * removeY;
  fSumXY := fSumXY - removeX * removeY;

  Dec(fCount);

  if (fCount > 0) then
  begin
    // Update the averages
    fAverageX := fSumX / fCount;
    fAverageY := fSumY / fCount;

    fSSxx := fSumXX - GetCount * fAverageX * fAverageX;
    fSSyy := fSumYY - GetCount * fAverageY * fAverageY;
    fSSxy := fSumXY - GetCount * fAverageX * fAverageY;
  end // if
  else
  begin
    fAverageX := NaN;
    fAverageY := NaN;

    // Update the sums of squares
    fSSxx := 0.0;
    fSSyy := 0.0;
    fSSxy := 0.0;
  end;
end; // Remove

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
procedure TLSqLinFit.SortOrderedPoints;
begin
  fOrderedPoints.Sort(TComparer<TCoordinate2>.Construct(
    function(const Left, Right: TCoordinate2): Integer
    begin
      if Left.x < Right.x then
        Result := -1
      else if Left.x > Right.x then
        Result := 1
      else
        Result := 0;
    end));
end;

//***************************************************************************
//
//  FUNCTION  : Add
//
//  I/P       : newX, newY : Extended - The point to be added to the fit.
//
//              newMinX : Extended - The new lowest X value to be retained.
//
//  O/P       : None.
//
//  OPERATION : Adds the point and updates the background calculations and sets
//              the new minimum X value to be retained.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
procedure TLSqLinFit.Add(newX : extended;
                         newY : extended;
                         newMinX : extended) overload;
var
  newPoint : TCoordinate2;

begin
  if (fRetention <> LSLFR_MIN_X) then
  begin
    // This addtion is only applicable to a least-sqares fit that has a minimum
    // X retention policy.
    Exit;
  end; // if

  SetMinX(newMinX);

  if (newX >= newMinX) then
  begin
    fLastX := newX;
    fLastY := newY;

    newPoint.x := newX;
    newPoint.y := newY;
    fOrderedPoints.Add(newPoint);

    SortOrderedPoints;

    // Update the averages
    fAverageX := fSumX / GetCount;
    fAverageY := fSumY / GetCount;

    // Update the sums of squares
    fSSxx := fSumXX - GetCount * fAverageX * fAverageX;
    fSSyy := fSumYY - GetCount * fAverageY * fAverageY;
    fSSxy := fSumXY - GetCount * fAverageX * fAverageY;

    while (GetCount > fMaxPoints) do
    begin
      RemoveMinXPoint;
    end;

    fEmpty := FALSE;
    fFull := (fOrderedPoints.Count = fMaxPoints);
  end; // if
end; // Add

//***************************************************************************
//
//  FUNCTION  : Add
//
//  I/P       : eX,eY (extended) - The point to be added to the fit.
//
//  O/P       : None.
//
//  OPERATION : Adds the point and updates the sums.
//
//              If the samples have been limited in number (and optionally in
//              X-value), remove samples as required.
//
//              Note that the X value of samples are not necessarily in order.
//              They are in the order in which they were added.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
procedure TLSqLinFit.Add(newX : extended;
                         newY : extended) overload;
var
  newPoint : TCoordinate2;

begin
  case fRetention of
    LSLFR_UNLIMITED:
    begin
      // No limit to the number of points being added.
      fLastX := newX;
      fLastY := newY;

      // Update the summation terms
      fSumX := fSumX + newX;
      fSumY := fSumY + newY;
      fSumXX := fSumXX + newX * newX;
      fSumYY := fSumYY + newY * newY;
      fSumXY := fSumXY + newX * newY;

      fEmpty := FALSE;

      Inc(fCount);
    end;

    LSLFR_FIFO:
    begin
      // Ensure that there is "space" to add the new point
      while (GetCount >= fMaxPoints) do
      begin
        RemoveTailPoint;
      end; // while

      fFIFOPoints[fPointerHead].x := newX;
      fFIFOPoints[fPointerHead].y := newY;

      // Store these as the last added
      fLastX := newX;
      fLastY := newY;

      // Move the head pointer on.
      fPointerHead := (fPointerHead + 1) mod fMaxPoints;
      if (fPointerHead = fPointerTail) then
      begin
        fFull := TRUE;
      end; // if
      fEmpty := FALSE;

      // Update the summation terms
      fSumX := fSumX + newX;
      fSumY := fSumY + newY;
      fSumXX := fSumXX + newX * newX;
      fSumYY := fSumYY + newY * newY;
      fSumXY := fSumXY + newX * newY;
    end;

    LSLFR_MIN_X:
    begin
      if (newX >= fMinimumX) then
      begin
        fLastX := newX;
        fLastY := newY;

        newPoint.x := newX;
        newPoint.y := newY;
        fOrderedPoints.Add(newPoint);

        SortOrderedPoints;

        // Update the summation terms
        fSumX := fSumX + newX;
        fSumY := fSumY + newY;
        fSumXX := fSumXX + newX * newX;
        fSumYY := fSumYY + newY * newY;
        fSumXY := fSumXY + newX * newY;

        while (fOrderedPoints.Count > fMaxPoints) do
        begin
          RemoveMinXPoint;
        end;

        fEmpty := FALSE;
        fFull := (fOrderedPoints.Count = fMaxPoints);
      end; // if
    end;
  end;

  // Update the averages
  fAverageX := fSumX / GetCount;
  fAverageY := fSumY / GetCount;

  // Update the sums of squares
  fSSxx := fSumXX - GetCount * fAverageX * fAverageX;
  fSSyy := fSumYY - GetCount * fAverageY * fAverageY;
  fSSxy := fSumXY - GetCount * fAverageX * fAverageY;
end; // Add

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
  if (fSSxx <> 0.0) then
  begin
    result := fSSxy / fSSxx;
  end // if
  else
  begin
    result := 0.0;
  end; // else
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
  if (fSSxx <> 0.0) then
  begin
    result := fAverageY - Slope * fAverageX;
  end // if
  else
  begin
    result := 0.0;
  end; // else
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
//              to the accumulated points.
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
  // Check that accumulated data will permit calculation
  if (fSSxx <> 0.0) then
  begin
    // Check that the slope is not flag horizontal
    eSlope := Slope;
    if (eSlope <> 0.0) then
    begin
      result := - (fAverageY - eSlope * fAverageX) / Slope
    end
    else
    begin
      result := 0.0;
      //!! Should be Nan?
    end;
  end // if
  else
  begin
    result := 0.0;
    //!! Should be Nan?
  end;
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
  if (GetCount > 0) then
  begin
    result := fSSxx / GetCount;
  end // if
  else
  begin
    result := 0.0;
  end; // else
end; // VarianceX

//***************************************************************************
//
//  FUNCTION  : StdDevX
//
//  I/P       : None
//
//  O/P       : Extended
//
//  OPERATION : Return the standard deviation of the collected Y values.
//
//              Not applicable to objects with unlimited points retention policy.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
function TLSqLinFit.StdDevX : extended;
var
  sumDXMeanSquared : extended;
  n : Integer;
  m : Integer;
  numPoints : Integer;

begin
  numPoints := GetCount;

  if (numPoints > 0) then
  begin
    sumDXMeanSquared := 0;

    case fRetention of
      LSLFR_FIFO :
      begin
        n := fPointerTail;
        m := 0;
        while (m < numPoints) do
        begin
          sumDXMeanSquared := sumDXMeanSquared + Power(fFIFOPoints[n].x - fAverageX, 2);
          n := (n + 1) mod fMaxPoints;
          Inc(m);
        end;
        Result := Sqrt(sumDXMeanSquared / numPoints);
      end;

      LSLFR_MIN_X :
      begin
        n := 0;
        while (n < fOrderedPoints.Count) do
        begin
          sumDXMeanSquared := sumDXMeanSquared + Power(fOrderedPoints[n].y - fAverageY, 2);
          Inc(n);
        end;
        Result := Sqrt(sumDXMeanSquared / numPoints);
      end;

      else
      begin
        // LSLFR_UNLIMITED
        // Maybe sometime keep a running sumDMeanYSquared,
        // so that StdDevY can be available for the unlimited points retention policy objects
        Result := 0.0;
      end; // else
    end; // case
  end // if
  else
  begin
    Result := 0.0;
  end;
end; // StdDevX

//***************************************************************************
//
//  FUNCTION  : StdDevY
//
//  I/P       : None
//
//  O/P       : Extended
//
//  OPERATION : Return the standard deviation of the collected Y values.
//
//              Not applicable to objects with unlimited points retention policy.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
function TLSqLinFit.StdDevY : extended;
var
  sumDYMeanSquared : extended;
  n : Integer;
  m : Integer;
  numPoints : Integer;

begin
  numPoints := GetCount;

  if (numPoints > 0) then
  begin
    sumDYMeanSquared := 0;

    case fRetention of
      LSLFR_FIFO :
      begin
        n := fPointerTail;
        m := 0;
        while (m < numPoints) do
        begin
          sumDYMeanSquared := sumDYMeanSquared + Power(fFIFOPoints[n].y - fAverageY, 2);
          n := (n + 1) mod fMaxPoints;
          Inc(m);
        end;
        Result := Sqrt(sumDYMeanSquared / numPoints);
      end;

      LSLFR_MIN_X :
      begin
        n := 0;
        while (n < numPoints) do
        begin
          sumDYMeanSquared := sumDYMeanSquared + Power(fOrderedPoints[n].y - fAverageY, 2);
          Inc(n);
        end;
        Result := Sqrt(sumDYMeanSquared / numPoints);
      end;

      else
      begin
        // LSLFR_UNLIMITED
        // Maybe sometime keep a running sumDMeanYSquared,
        // so that StdDevY can be available for the unlimited points retention policy objects
        Result := 0.0;
      end; // else
    end; // case
  end // if
  else
  begin
    Result := 0.0;
  end;
end; // StdDevY

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
  if (GetCount > 0) then
  begin
    result := fSSyy / GetCount;
  end // if
  else
  begin
    result := 0.0;
  end; // else
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
  if (GetCount > 0) then
  begin
    result := fSSxy / GetCount;
  end // if
  else
  begin
    result := 0.0;
  end; // else
end; // Covariance

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
//  UPDATED   : 2024-10-22
//
//***************************************************************************
procedure TLSqLinFit.Clear;
begin
  fAverageX := 0.0;
  fAverageY := 0.0;
  fCount := 0;

  fSumX := 0.0;
  fSumY := 0.0;
  fSumXX := 0.0;
  fSumYY := 0.0;
  fSumXY := 0.0;
  fSSxx := 0.0;
  fSSyy := 0.0;
  fSSxy := 0.0;

  fPointerHead := 0;
  fPointerTail := 0;
  fFull := FALSE;
  fEmpty := TRUE;

  fLastX := NaN;
  fLastY := NaN;
end; // Clear

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
function TLSqLinFit.GetLowestX : Extended;
var
  n : Integer;
  numPoints : Integer;

begin
  numPoints := GetCount;

  case fRetention of
    LSLFR_UNLIMITED :
    begin
      Result := 0.0;
    end;

    LSLFR_FIFO :
    begin
      if (numPoints > 0) then
      begin
        n := fPointerTail;
        Result := 1.1E4931;
        repeat
          Result := Min(fFIFOPoints[n].x, Result);
          n := (n+1) mod fMaxPoints;
        until (n = fPointerHead);
      end;

    end;

    LSLFR_MIN_X :
    begin
      if (numPoints > 0) then
      begin
        Result := fOrderedPoints[0].x;
      end; // if
    end;
  end;
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
  numPoints : Integer;

begin
  numPoints := GetCount;

  case fRetention of
    LSLFR_UNLIMITED :
    begin
      Result := 0.0;
    end;

    LSLFR_FIFO :
    begin
      if (numPoints > 0) then
      begin
        n := fPointerTail;
        Result := -1.1E4931;
        repeat
          Result := Max(fFIFOPoints[n].x, Result);
          n := (n+1) mod fMaxPoints;
        until (n = fPointerHead);
      end;

    end;

    LSLFR_MIN_X :
    begin
      if (numPoints > 0) then
      begin
        Result := fOrderedPoints[numPoints-1].x;
      end; // if
    end;
  end;
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
  result := fLastX;
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
  result := fLastY;
end; // LastY

//***************************************************************************
//
//  FUNCTION  : X
//
//  I/P       : offset : Integer - Offset into the added data, with index 0
//                being the first added.
//
//  O/P       : Extended - The reqested X value, or NaN if not available.
//
//  OPERATION : Return the indexed X value of a FIFO type object
//
//              Note that the X value of samples are not necessarily in order.
//              They are in the order in which they were added.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
function TLSqLinFit.X(offset : Integer) : extended;
begin
  Result := NaN;

  if (fRetention <> LSLFR_FIFO) then
  begin
    if (offset < GetCount) then
    begin
      Result := fFIFOPoints[(fPointerTail + offset) mod Size].x;
    end
  end;
end; // X

//***************************************************************************
//
//  FUNCTION  : Y
//
//  I/P       : offset : Integer - Offset into the added data, with index 0
//                being the first added.
//
//  O/P       : Extended - The reqested Y value, or NaN if not available.
//
//  OPERATION : Return the indexed Y value of a FIFO type object
//
//  UPDATED   : 2022-06-02
//
//***************************************************************************
function TLSqLinFit.Y(offset : Integer) : extended;
begin
  Result := NaN;

  if (fRetention <> LSLFR_FIFO) then
  begin
    if (offset < GetCount) then
    begin
      Result := fFIFOPoints[(fPointerTail + offset) mod Size].y;
    end
  end;
end; // Y

//***************************************************************************
//
//  FUNCTION  : CalculateY
//
//  I/P       : x : Extended - The X value, for which Y must be computed
//
//  O/P       : Extended - The reqested Y value, or NaN if not available.
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
    Result := NaN;
  end;
end; // CalculateY

//***************************************************************************
//
//  FUNCTION  : CalculateX
//
//  I/P       : y : Extended - The Y value, for which X must be computed
//
//  O/P       : Extended - The reqested X value, or NaN if not available.
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
    Result := NaN;
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
//  OPERATION : Check whether a least squares fit is available.
//
//  UPDATED   : 2006/09/05
//
//***************************************************************************
function TLSqLinFit.Available : Boolean;
begin
  result := ((GetCount >= 2) and (fSSxx <> 0.0));
end; // Available

//***************************************************************************
//
//  FUNCTION  : GetFull
//
//  I/P       : None
//
//  O/P       : Boolean
//
//  OPERATION : Indicate whether the storage of points for the fit is full.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
function TLSqLinFit.GetFull : Boolean;
begin
  Result := fFull;
end; // GetFull

//***************************************************************************
//
//  FUNCTION  : GetEmpty
//
//  I/P       : None
//
//  O/P       : Boolean
//
//  OPERATION : Indicate whether the storage of points for the fit is empty.
//
//  UPDATED   : 2024-10-23
//
//***************************************************************************
function TLSqLinFit.GetEmpty : Boolean;
begin
  Result := fEmpty;
end; // GetEmpty

//***************************************************************************
//
//  FUNCTION  : Create
//
//  I/P       : lslfr : TLSLFRetention = LSLFR_FIFO - The type of sample
//                retention.
//
//              maxPoints : Integer = LSLF_MAX_POINTS - Used if FIFO or MIN_X
//                implementations.
//
//  O/P       : None
//
//  OPERATION : Set up an instance and retention tyupe of a least squares linear
//              fit.
//
//              Note that it does not really make sense to be able to change the
//              retention policy of a LSLF instance, once created. So the
//              retention policy is set up on creation.
//
//              Default to the maximum number of points for FIFO and MIN_X
//              implementations.
//
//  UPDATED   : 2024-10-22
//
//***************************************************************************
constructor TLSqLinFit.Create(lslfr : TLSLFRetention = LSLFR_FIFO; maxPoints : Integer = LSLF_MAX_POINTS);
begin
  Clear;

  fRetention := lslfr;

  case lslfr of
    LSLFR_FIFO :
    begin
      if (maxPoints < 2) then
      begin
        Exception.Create('TLSqLinFit : Invalid maximum number of points');
      end;

      SetLength(fFIFOPoints, maxPoints);
      fMaxPoints := maxPoints;
    end;

    LSLFR_MIN_X :
    begin
      if (maxPoints < 2) then
      begin
        Exception.Create('TLSqLinFit : Invalid maximum number of points');
      end;

      fOrderedPoints := TList<TCoordinate2>.Create;
      fMaxPoints := maxPoints;
    end;
  end;
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
  inherited Destroy;
end; // Destroy

end. // Maths
