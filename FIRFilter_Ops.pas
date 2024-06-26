unit FIRFilter_Ops;

interface

type
  TFIRFilter = class
  private
    aeValues : array of extended;
    aeCoefficients : array of extended;
    iPointer : Integer;                 // Indicates where the next value will be stored
    iInputValues : Integer;
    function GetOutput : extended;
    function GetFull : boolean;
    function GetEmpty : boolean;
    function GetDelay : Integer;
    function GetSize : Integer;
    function GetPopRatio : real;
    function GetPopPercent : real;
  published
  protected
  public
    property Output : extended read GetOutput;
    property Full : boolean read GetFull;
    property Empty : boolean read GetEmpty;
    property Delay : integer read GetDelay;
    property Size : integer read GetSize;
    property PopRatio : real read GetPopRatio;
    property PopPercent : real read GetPopPercent;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SetCoefficients(coefs : array of extended);
    procedure Add(eValue : extended);
    procedure Fill(eValue : extended);
  end; // class

implementation

uses SysUtils, Math;

//***************************************************************************
//
//  FUNCTION  : SetCoefficients
//
//  I/P       : coefs : array of extended - Coefficients of the filter.
//
//  O/P       :
//
//  OPERATION : Sets the coefficients for the filter. These may be
//              derived from the "Designed Filters" page on
//              http://www.micromodeler.com/dsp/
//
//  UPDATED   : 2018-11-26
//
//***************************************************************************
procedure TFIRFilter.SetCoefficients(coefs : array of extended);
var
  n : Integer;

begin
  if (Length(coefs) mod 2 = 1) then
  begin
    Clear;

    SetLength(aeCoefficients, Length(coefs));

    n := 0;
    while (n <= Length(coefs)-1) do
    begin
      aeCoefficients[n] := coefs[n];
      Inc(n);
    end; // while
  end // if
  else
  begin
    raise Exception.Create('Invalid FIR filter coefficient count');
  end;
end; // SetCoefficients

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
procedure TFIRFilter.Add(eValue : extended);
begin
  // Start by removing the influence of the value which we are about to replace
  // with the given value, if it was a valid number.
  if (not IsNAN(aeValues[iPointer])) then
  begin
    Dec(iInputValues);
  end; // if

  // Store the new value
  aeValues[iPointer] := eValue;
  // Move the pointer on
  iPointer := (iPointer + 1) mod Length(aeValues);

  // Update the calculated terms
  if (not IsNAN(eValue)) then
  begin
    Inc(iInputValues);
  end; // if
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
procedure TFIRFilter.Fill(eValue : extended);
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
//  FUNCTION  : GetOutput
//
//  I/P       : None
//
//  O/P       : (extended) - the filtered output
//
//  OPERATION : Returns the filtered output, based on multiplication of the
//                preceding values by the filter coefficients.
//
//  UPDATED   : 2018-11-26
//
//***************************************************************************
function TFIRFilter.GetOutput : extended;
var
  n : Integer;
  m : Integer;

begin
  if (iInputValues <> 0) then
  begin
    result := 0.0;
    n := iPointer;
    for m := 0 to Length(aeCoefficients)-1 do
    begin
      result := result + aeValues[n] * aeCoefficients[m];
      n := (n + 1) mod Length(aeValues);
    end; // for
  end
  else
    result := NAN;
end; // GetOutput

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
function TFIRFilter.GetPopRatio : real;
begin
  result := 1.0 * iInputValues / Length(aeValues);
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
function TFIRFilter.GetPopPercent : real;
begin
  result := 100.0 * iInputValues / Length(aeValues);
end; // GetPopPercent

//***************************************************************************
//
//  FUNCTION  : GetFull
//
//  I/P       : None
//
//  O/P       : (boolean) - TRUE if all values in the moving average span
//                are valid.
//
//  OPERATION :
//
//  UPDATED   : 2008-07-30
//
//***************************************************************************
function TFIRFilter.GetFull : boolean;
begin
  result := (iInputValues = Length(aeValues));
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
function TFIRFilter.GetEmpty : boolean;
begin
  result := (iInputValues = 0);
end; // GetEmpty

//***************************************************************************
//
//  FUNCTION  : GetSize
//
//  I/P       : None
//
//  O/P       : integer : Half the size of the filter
//
//  OPERATION : The number of terms in the filter
//
//  UPDATED   : 2018-12-19
//
//***************************************************************************
function TFIRFilter.GetSize : Integer;
begin
  result := Length(aeValues);
end; // GetSize

//***************************************************************************
//
//  FUNCTION  : GetDelay
//
//  I/P       : None
//
//  O/P       : integer : Half the size of the filter
//
//  OPERATION : The filter always contains an odd number of terms. The delay
//              is the number of samples needed before the centred sample may
//              be determined.
//
//  UPDATED   : 2018-11-26
//
//***************************************************************************
function TFIRFilter.GetDelay : Integer;
begin
  result := (GetSize - 1) div 2;
end; // GetDelay

//***************************************************************************
//
//  FUNCTION  : Clear
//
//  I/P       : None
//
//  O/P       :
//
//  OPERATION : Empties the input samples array and resets control variables
//
//  UPDATED   : 2013-11-01
//
//***************************************************************************
procedure TFIRFilter.Clear;
var
  n : Integer;

begin
  n := 0;
  while (n <= Length(aeValues)-1) do
  begin
    aeValues[n] := NAN;
    Inc(n);
  end; // while

  iInputValues := 0;

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
//  OPERATION : Initialises the a zero-length filter
//
//  UPDATED   : 2018-11-26
//
//***************************************************************************
constructor TFIRFilter.Create;
begin
  SetLength(aeValues,0);
  SetLength(aeCoefficients,0);
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
//  OPERATION :
//
//  UPDATED   : 2018-11-26
//
//***************************************************************************
destructor TFIRFilter.Destroy;
begin
  inherited Destroy;
end; // Destroy

end.
