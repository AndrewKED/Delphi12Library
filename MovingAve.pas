unit MovingAve;

//***************************************************************************
//
// DESCRIPTION:
//  Declares a class that may be used to create a moving average of a
//    variable.   It is permissable to add a NAN value to this moving
//    average.   Such a number will not be included in the moving average.
//
// TO BE DONE:
//
//      *
//
// VERSIONS:
//    Update Date : 2008-08-30
//    Changes Made :
//      * First Issue
//
//***************************************************************************

interface

type
  TMovingAve = class
  private
    aeValues : array of extended;
    eSum : extended;
    eAverage : extended;
    iPointer : Integer;                 // Indicates where the next value will be stored
    iValidValues : Integer;
    function GetAverage : extended;
    function GetVariance : extended;
    function GetStdDeviation : extended;
    function GetLowest : extended;
    function GetHighest : extended;
    function GetLast : extended;
    function GetFull : boolean;
    function GetEmpty : boolean;
    function GetSpan : Integer;
    function GetPopRatio : real;
    function GetPopPercent : real;
    procedure SizeAs(iSpan : integer);
  public
    property Variance : extended read GetVariance;
    property Average : extended read GetAverage;
    property StdDeviation : extended read GetStdDeviation;
    property Lowest : extended read GetLowest;
    property Highest : extended read GetHighest;
    property Last : extended read GetLast;
    property Full : boolean read GetFull;
    property Empty : boolean read GetEmpty;
    property Span : integer read GetSpan write SizeAs;
    property PopRatio : real read GetPopRatio;
    property PopPercent : real read GetPopPercent;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(eValue : extended);
    procedure Fill(evalue : extended);
  end; // class

implementation

uses SysUtils, Math;

//***************************************************************************
//
//  FUNCTION  : Add
//
//  I/P       : eValue (extended) - The value to be added to the moving average
//
//  O/P       : None.
//
//  OPERATION : Adds the point and updates the running total and average.
//              Removes the oldest value.
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
procedure TMovingAve.Add(eValue : extended);
begin
  // Start by removing the influence of the value which we are about to replace
  // with the given value, if it was a valid number.
  if (not IsNAN(aeValues[iPointer])) then
  begin
    eSum := eSum - aeValues[iPointer];
    Dec(iValidValues);
  end; // if

  // Store the new value
  aeValues[iPointer] := eValue;
  // Move the pointer on
  iPointer := (iPointer + 1) mod Length(aeValues);

  // Update the calculated terms
  if (not IsNAN(eValue)) then
  begin
    Inc(iValidValues);
    eSum := eSum + eValue;
  end; // if

  if (iValidValues = 0) then
    eAverage := NAN
  else
    eAverage := eSum / iValidValues;
end; // Add

//***************************************************************************
//
//  FUNCTION  : Fill
//
//  I/P       : eValue : extended - The value to be placed in all elements
//                of the array, and hence the new moving average value.
//
//  O/P       : None
//
//  OPERATION : Initialises the entire array, and hence the moving average
//              value, to a given value.
//
//  UPDATED   : 2013-11-01
//
//***************************************************************************
procedure TMovingAve.Fill(eValue : extended);
var
  n : Integer;

begin
  Clear;
  n := 0;
  while (n <= Length(aeValues)-1) do
  begin
    Add(eValue);
    Inc(n);
  end; // while
end; // Fill

//***************************************************************************
//
//  FUNCTION  : GetAverage
//
//  I/P       : None
//
//  O/P       : (extended) - the average value of the valid values in the
//                moving average.
//
//  OPERATION : Returns the average value of the valid values in the moving
//                average, or NAN if the average is undefined.
//
//  UPDATED   : 2006/05/30
//
//***************************************************************************
function TMovingAve.GetAverage : extended;
begin
  if (iValidValues <> 0) then
    result := eAverage
  else
    result := NAN;
end; // GetAverage

//***************************************************************************
//
//  FUNCTION  : Variance
//
//  I/P       : None
//
//  O/P       : (extended) - the variance of the points in the moving average
//
//  OPERATION : Variance = StdDeviation ^ 2 (i.e. sigma squared)
//
//                       = 1/N * Sum [(xi - Ave x) ^ 2]
//
//  UPDATED   : 2013-11-01
//
//***************************************************************************
function TMovingAve.GetVariance : extended;
var
  eSumDiff2 : extended;
  n : Integer;

begin
  if (iValidValues <> 0) then
  begin
    eSumDiff2 := 0;
    n := 0;
    while (n <= Length(aeValues)-1) do
    begin
      if (not IsNAN(aeValues[n])) then
        eSumDiff2 := eSumDiff2 + (aeValues[n] - eAverage) * (aeValues[n] - eAverage);
      Inc(n);
    end; // while
    result := eSumDiff2 / iValidValues;
  end // if
  else
    result := NAN;
end; // GetVariance

//***************************************************************************
//
//  FUNCTION  : GetStdDeviation
//
//  I/P       : None
//
//  O/P       : (extended) - the standard deviation (sigma) of the points
//                in the moving average array.
//
//  OPERATION : StdDeviation = Variance ^ 1/2
//
//                       = Sqrt (1/N * Sum [(xi - Ave x) ^ 2])
//
//  UPDATED   : 2008-07-30
//
//***************************************************************************
function TMovingAve.GetStdDeviation : extended;
begin
  if (iValidValues <> 0) then
    result := Sqrt(GetVariance)
  else
    result := NAN;
end; // GetStdDeviation

//***************************************************************************
//
//  FUNCTION  : GetLowest
//
//  I/P       : None
//
//  O/P       : (extended) - the value of the sample with the lowest
//                value.
//
//  OPERATION : Scan the stored points, and return the lowest.
//
//  UPDATED   : 2013-11-01
//
//***************************************************************************
function TMovingAve.GetLowest : extended;
var
  n : Integer;

begin
  if (iValidValues > 0) then
  begin

    result := MAXEXTENDED;
    n := 0;
    while (n <= Length(aeValues)-1) do
    begin
      if ((not IsNAN(aeValues[n])) and
          (aeValues[n] < result)) then
        result := Min(aeValues[n],result);
      Inc(n);
    end; // while

  end // if
  else
    // If the array contains no valid values, return a NAN.
    result := NAN;
end; // GetLowest

//***************************************************************************
//
//  FUNCTION  : GetHighest
//
//  I/P       : None
//
//  O/P       : (extended) - the value of the sample with the highest
//                value.
//
//  OPERATION : Scan the stored points, and return the highest.
//
//  UPDATED   : 2013-11-01
//
//***************************************************************************
function TMovingAve.GetHighest : extended;
var
  n : Integer;

begin
  if (iValidValues > 0) then
  begin

    result := -MAXEXTENDED;
    n := 0;
    while (n <= Length(aeValues)-1) do
    begin
      if ((not ISNAN(aeValues[n])) and
          (aeValues[n] > result)) then
        result := Max(aeValues[n],result);
      Inc(n);
    end; // while
  end // if
  else
    // If the array contains no valid values, return a NAN.
    result := NAN;
end; // GetHighest

//***************************************************************************
//
//  FUNCTION  : GetLast
//
//  I/P       : None
//
//  O/P       : (extended) - the value of the last sample added.
//
//  OPERATION : Return the value of the last sample added.
//
//  UPDATED   : 2022-01-31
//
//***************************************************************************
function TMovingAve.GetLast : extended;
var
  n : Integer;

begin
  if (iValidValues > 0) then
  begin
    n := iPointer - 1;
    if (n < 0) then
      n := Length(aeValues) - 1;
    // Store the new value
    Result := aeValues[n];
  end // if
  else
    // If the array contains no valid values, return a NAN.
    result := NAN;
end;

//***************************************************************************
//
//  FUNCTION  : GetPopRatio
//
//  I/P       : None
//
//  O/P       : (boolean) - The ratio of valid values in the moving average array
//
//  OPERATION :
//
//  UPDATED   : 2008-07-30
//
//***************************************************************************
function TMovingAve.GetPopRatio : real;
begin
  result := 1.0 * iValidValues / Length(aeValues);
end; // GetPopRatio

//***************************************************************************
//
//  FUNCTION  : GetPopPercent
//
//  I/P       : None
//
//  O/P       : (boolean) - The ratio of valid values in the moving average array
//
//  OPERATION :
//
//  UPDATED   : 2008-07-30
//
//***************************************************************************
function TMovingAve.GetPopPercent : real;
begin
  result := 100.0 * iValidValues / Length(aeValues);
end; // GetPopPercent

//***************************************************************************
//
//  FUNCTION  : GetFull
//
//  I/P       : None
//
//  O/P       : (boolean) - TRUE if all values in the moving average span
//                are valid (with the moving average span not being zero).
//
//  OPERATION :
//
//  UPDATED   : 2020-07-15
//
//***************************************************************************
function TMovingAve.GetFull : boolean;
begin
  result := (iValidValues = Length(aeValues)) and (iValidValues <> 0);
end; // GetFull

//***************************************************************************
//
//  FUNCTION  : GetEmpty
//
//  I/P       : None
//
//  O/P       : (boolean) - TRUE if no valid values may be found in the
//                moving average array.
//
//  OPERATION :
//
//  UPDATED   : 2008-07-30
//
//***************************************************************************
function TMovingAve.GetEmpty : boolean;
begin
  result := (iValidValues = 0);
end; // GetEmpty

//***************************************************************************
//
//  FUNCTION  : GetSpan
//
//  I/P       : None
//
//  O/P       : (integer) - Maximum number of items in the moving average array
//
//  OPERATION :
//
//  UPDATED   : 2008-08-11
//
//***************************************************************************
function TMovingAve.GetSpan : Integer;
begin
  result := Length(aeValues);
end; // GetSpan

//***************************************************************************
//
//  FUNCTION  : SizeAs
//
//  I/P       : iPoints (integer) - The new number of values to be used in
//                the moving average
//
//  O/P       :
//
//  OPERATION : Used to set or change change the number of values used in the
//              moving average without losing any previously accumulated data
//              (unless the number of values is being decreased)
//
//  UPDATED   : 2022-07-04
//
//***************************************************************************
procedure TMovingAve.SizeAs(iSpan : integer);
var
  aeTransfer : array of extended;
  n : Integer;
  m : Integer;

begin
  if (iValidValues <= 0) then
  begin
    // No valid data to be transferred.   Just resize the array.
    SetLength(aeValues,iSpan);
    // Initialise the moving average
    Clear;

    Exit;
  end; // if

  if (iSpan > Length(aeValues)) then
  begin
    // Increasing the number of points being used to determine the moving average

    // Create a temporary array for the data
    SetLength(aeTransfer,Length(aeValues));

    // Transfer the existing samples into a temporary array, placing the
    // oldest sample into the first element.
    iPointer := (Length(aeValues) + iPointer - 1) mod Length(aeValues);
    m := Length(aeValues)-1;
    repeat
      aeTransfer[m] := aeValues[iPointer];
      Dec(m);
      iPointer := (Length(aeValues) + iPointer - 1) mod Length(aeValues);
    until (m < 0);

    // Now enlarge the data array to the new required size
    SetLength(aeValues,iSpan);
    // Initialise the moving average
    Clear;

    // Copy the original data back to the sample arrays
    // While doing this, keep the invalid count, last valid data pointer and
    // the running totals up-to-date
    for n := 0 to Length(aeTransfer)-1 do
    begin
      aeValues[n] := aeTransfer[n];
      if (not IsNAN(aeValues[n])) then
      begin
        Inc(iValidValues);
        iPointer := n;
        eSum := eSum + aeValues[n];
      end; // if
    end; // for
    // Final corrections
    eAverage := eSum / iValidValues;

    Inc(iPointer);
  end // if

  else if (iSpan < Length(aeValues)) then
  begin
    // Decreasing the number of points being used to determine the moving average

    // Create a temporary array for the data
    SetLength(aeTransfer,Length(aeValues));

    // Transfer the existing samples into a temporary array, placing the
    // oldest sample into the first element.
    iPointer := (Length(aeValues) + iPointer - 1) mod Length(aeValues);
    m := Length(aeValues)-1;
    repeat
      aeTransfer[m] := aeValues[iPointer];
      Dec(m);
      iPointer := (Length(aeValues) + iPointer - 1) mod Length(aeValues);
    until (m < 0);

    // Now decrease the data array to the new required size
    SetLength(aeValues,iSpan);
    // Initialise the moving average
    Clear;

    // Determine where, in the ordered transfer array, we should begin the
    // transfer process.
    m := Length(aeTransfer) - Length(aeValues);

    // Copy the original data back to the sample arrays, starting from the
    // offset position
    // While doing this, keep the invalid count, last valid data pointer and
    // the running totals up-to-date
    iPointer := 0;
    for n := m to Length(aeTransfer)-1 do
    begin
      aeValues[iPointer] := aeTransfer[n];
      if (not IsNAN(aeValues[iPointer])) then
      begin
        Inc(iValidValues);
        eSum := eSum + aeValues[iPointer];
      end; // if
      iPointer := (iPointer+1) mod Length(aeValues);
    end; // for
    // Final corrections
    eAverage := eSum / iValidValues;

    Inc(iPointer);
  end; // if
end; // Resize

//***************************************************************************
//
//  FUNCTION  : Clear
//
//  I/P       : None
//
//  O/P       :
//
//  OPERATION : Empties the moving average array and resets control variables
//
//  UPDATED   : 2013-11-01
//
//***************************************************************************
procedure TMovingAve.Clear;
var
  n : Integer;
begin
  n := 0;
  while (n <= Length(aeValues)-1) do
  begin
    aeValues[n] := NAN;
    Inc(n);
  end; // while

  eAverage := 0.0;
  eSum := 0.0;
  iValidValues := 0;

  iPointer := 0;
end; // Clear

//***************************************************************************
//
//  FUNCTION  : Create
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Initialises the values in a moving average
//
//  UPDATED   : 2008-07-30
//
//***************************************************************************
constructor TMovingAve.Create;
begin
  SetLength(aeValues,0);
  Clear;
end; // Create

//***************************************************************************
//
//  FUNCTION  : Destroy
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Sets the value array to a minimum value.
//
//  UPDATED   : 2008-07-30
//
//***************************************************************************
destructor TMovingAve.Destroy;
begin
  inherited Destroy;
end; // Destroy

end. // Maths

