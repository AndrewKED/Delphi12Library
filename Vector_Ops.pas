unit Vector_Ops;

//***************************************************************************
//
// DESCRIPTION:
//  Provides routines for 2D and 3D interpolation of data, with a set of point
//  data read from a text or ini file.
//
// TO BE DONE:
//
// VERSIONS:
//
//    Update Date :
//    Changes Made :
//      *
//
//***************************************************************************

interface

uses IniFiles;

type
  TCoord2DPoint = record
    x : Double;
    y : Double;
  end;

  TArray2D = class(TObject)
    private
      sSource : String; // Temporary
      slopeTypeY : integer;
    public
      dataValues : array of TCoord2DPoint; // } I have had to move these out of private because
      iXPoints : Integer;                  // } because of errors in my temperature logger software.
      constructor Create;
      destructor Destroy; override;
      function ReadFromData(source : array of TCoord2DPoint) : boolean;
      function ReadFromFile(sFileName : String;
                            cSeparator : char) : boolean;
      function ReadFromInifile(cifSource : TCustomIniFile;
                               sSectionName : string) : boolean;
      procedure Build(iX : integer);
      procedure StuffX(iX : Integer;
                       dX : double);
      procedure StuffY(iY : Integer;
                       dY : double);
      function LookupY(dXValue : double) : Double;
      function LookupYEx(dXValue : double) : Double;
      function LookupX(dYValue : double) : Double;
      function LookupXEx(dYValue : double) : Double;
      procedure Clear;
      function Valid : boolean;
    end;

  TArray3D = class(TObject)
    private
      adXValues : array of double;
      adYValues : array of double;
      adData : array of array of double;
      iXPoints : Integer;
      iYPoints : Integer;
      sSource : String; // Temporary
    public
      constructor Create;
      destructor Destroy; override;
      function ReadFromFile(sFileName : String;
                            cSeparator : char) : boolean;
      function ReadFromInifile(cifSource : TCustomIniFile;
                               sSectionName : string) : boolean;
      procedure Build(iX,iY : integer);
      procedure StuffX(iX : Integer;
                       dX : double);
      procedure StuffY(iY : Integer;
                       dY : double);
      procedure StuffZ(iX,iY : Integer;
                       dZ : double);
      function Lookup(dXValue,dYValue : double) : Double;
      procedure Clear;
      function Valid : boolean;
    end;

implementation

uses Classes, Math, SysUtils, System.StrUtils,
     Str_Ops, Maths;

const
  SLOPE_UNKNOWN = 0;
  SLOPE_INCREASE = 1;
  SLOPE_DECREASE = 2;
  SLOPE_MIXED = 3;

var
  fInputData : Text;

//***************************************************************************
//
//  FUNCTION  : GetDataLine
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Reads a line from the Text file, ignoring lines that start with
//              a ';' character (used for comments)
//
//              Returns an empty string should it encounter EOF
//
//  UPDATED   : 2010-05-06
//
//***************************************************************************
function GetDataLine : String;
var
  sLine : String;

begin
  sLine := '';
  if (not Eof(fInputData)) then
    repeat
      Readln(fInputData,sLine);
    until (Eof(fInputData) or (Pos(';',sLine) <> 1));

  result := sLine;
end; //

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
constructor TArray2D.Create;
begin
  inherited Create;
  Self.Clear;
end; // Create

//***************************************************************************
//
//  FUNCTION  : Clear
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/05/10
//
//***************************************************************************
procedure TArray2D.Clear;
begin
  sSource := 'None';
  iXPoints := 0;
  slopeTypeY := SLOPE_UNKNOWN;
  SetLength(dataValues,0);
end; // Clear

//***************************************************************************
//
//  FUNCTION  : Valid
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/05/10
//
//***************************************************************************
function TArray2D.Valid : boolean;
begin
  result := (iXPoints >= 1);
end; // Valid

//***************************************************************************
//
//  FUNCTION  : ReadFromFile
//
//  I/P       : sFileName (string) - The full name of the text file that
//              contains the data.
//
//              cSeparator (char) - The character separating the values
//
//  O/P       : (boolean) - TRUE if the data was correctly read.
//
//  OPERATION : Reads in a text file, containing lines of separated point pairs,
//              with the first number as X, and the second as Y.   X values
//              should increase through the file.
//
//  UPDATED   : 2009-07-30
//
//***************************************************************************
function TArray2D.ReadFromFile(sFileName : String;
                               cSeparator : char) : boolean;
var
  sLine : String;
  dLastX : Double;
  dTemp : Double;
  cCurrentDecimalSeparator : char;

begin
  result := TRUE;

  // Store the current decimal separator, so that we can restore it at the end.
  cCurrentDecimalSeparator := FormatSettings.DecimalSeparator;

  try
    sSource := sFileName;

    AssignFile(fInputData,sFileName);
    // clear any previous IOResult
    IOResult;
    {$I-}
    Reset(fInputData);
    {$I+}
    if (IOResult=0) then
    begin
      // There may (should) be a line containing the decimal separator character used in this file.
      // If so, read and use it in the conversions below
      sLine := GetDataLine;
      if (LeftStr(sLine,1) = '.') or (LeftStr(sLine,1) = ',') then
        FormatSettings.DecimalSeparator := sLine[1]
      else
        Reset(fInputData);

      // First, scan the file and determine the number of valid data pairs it contains
      // the X-points should increase in value.
      // For a valid reverse lookup, the Y-points should either consistently
      // increase or decrease in value.
      iXPoints := 0;
      dLastX := -MaxDouble;
      while ((result) and
             (not Eof(fInputData))) do
      begin
        sLine := GetDataLine;
        RemoveDuplicates(sLine,cSeparator);
        try
          dTemp := StrToFloat(ExtractAndTrim(sLine,cSeparator));
          if (dTemp <= dLastX) then
            result := FALSE
          else
            dLastX := dTemp;
          StrToFloat(ExtractAndTrim(sLine,cSeparator));
          Inc(iXPoints);
        except
          result := FALSE;
        end; // except
      end; // while

      // Proceed only if the file could be read, and contains 1 or more valid,
      // increasing points
      if ((result) and (iXPoints > 0)) then
      begin
        try
          SetLength(dataValues,iXPoints);
          Reset(fInputData);

          // There may (should) be a line containing the decimal separator character used in this file.
          // If so, read and use it in the conversions below
          sLine := GetDataLine;
          if (LeftStr(sLine,1) = '.') or (LeftStr(sLine,1) = ',') then
            FormatSettings.DecimalSeparator := sLine[1]
          else
            Reset(fInputData);

          iXPoints := 0;
          while ((result) and
                 (not Eof(fInputData))) do
          begin
            sLine := GetDataLine;
            RemoveDuplicates(sLine,cSeparator);
            dataValues[iXPoints].x := StrToFloat(ExtractAndTrim(sLine,cSeparator));
            dataValues[iXPoints].y := StrToFloat(ExtractAndTrim(sLine,cSeparator));
            if (iXPoints >= 1) then
            begin
              case slopeTypeY of
                SLOPE_INCREASE :
                  if (dataValues[iXPoints].y <= dataValues[iXPoints-1].y) then
                    // We cannot look up X if Y values do not change, or changes direction
                    slopeTypeY := SLOPE_MIXED;
                SLOPE_DECREASE :
                  if (dataValues[iXPoints].y >= dataValues[iXPoints-1].y) then
                    // We cannot look up X if Y values do not change, or changes direction
                    slopeTypeY := SLOPE_MIXED;
                SLOPE_UNKNOWN :
                  if (dataValues[iXPoints].y > dataValues[iXPoints-1].y) then
                    slopeTypeY := SLOPE_INCREASE
                  else
                  if (dataValues[iXPoints].y < dataValues[iXPoints-1].y) then
                    slopeTypeY := SLOPE_DECREASE;
                  else
                    slopeTypeY := SLOPE_MIXED;
              end; // case
            end;
            Inc(iXPoints);
          end; // while
        except
          result := FALSE;
        end; // except
      end // if
      else
        result := FALSE;

      System.CloseFile(fInputData);

    end // if
    else
      result := FALSE;

  finally
    // Restore the used decimal separator
    FormatSettings.DecimalSeparator := cCurrentDecimalSeparator;
  end; // finally
end; // ReadFromFile

//***************************************************************************
//
//  FUNCTION  : ReadFromIniFile
//
//  I/P       : cifSource (TCustomIniFile) - The TCustomInifile that holds the
//                2D table in a section.
//
//              sSectionName (string) - The section that holds the 2D table.
//
//  O/P       : (boolean) - TRUE if the data was correctly read.
//
//  OPERATION : Reads in a section from a TIniFile, containing values of comma-
//              separated point pairs, with the first number as X, and the
//              second as Y.   X values should increase through the file.
//              The 'name' part of the name-value pairs is irrelevant.
//
//  UPDATED   : 2007-09-07
//
//***************************************************************************
function TArray2D.ReadFromIniFile(cifSource : TCustomIniFile;
                                  sSectionName : string) : boolean;
var
  slResponsePoints : TStringList;
  sLine : String;
  dLastX : Double;
  dTemp : Double;
  cCurrentDecimalSeparator : char;

begin
  result := TRUE;

  cCurrentDecimalSeparator := FormatSettings.DecimalSeparator;

  try
    // Take care of the situation where the data file was created in a locale that uses a different decimal separator
    FormatSettings.DecimalSeparator := GetNthChar(cifSource.ReadString('General','DecimalSeparator','.'),1);

    sSource := sSectionName;

    // Create the storage space and read in the ordered field list
    slResponsePoints := TStringList.Create;
    cifSource.ReadSectionValues(sSectionName,slResponsePoints);

    // First, scan the file and determine the number of valid data pairs it contains
    // the X-points should increase in value.
    iXPoints := 0;
    dLastX := -MaxDouble;
    while ((result) and
           (iXPoints<=slResponsePoints.Count-1))  do
    begin
      sLine := slResponsePoints.ValueFromIndex[iXPoints];
      RemoveDuplicates(sLine,',');
      try
        dTemp := StrToFloat(ExtractAndTrim(sLine,','));
        if (dTemp <= dLastX) then
          result := FALSE
        else
          dLastX := dTemp;
        StrToFloat(sLine);
        Inc(iXPoints);
      except
        result := FALSE;
      end; // except
    end; // while

    // Proceed only if the section contains 1 or more valid,
    // increasing points
    if ((result) and (iXPoints > 0)) then
    begin
      try
        SetLength(dataValues,iXPoints);
        iXPoints := 0;
        while ((result) and
               (iXPoints<=slResponsePoints.Count-1)) do
        begin
          sLine := slResponsePoints.ValueFromIndex[iXPoints];
          RemoveDuplicates(sLine,',');
          dataValues[iXPoints].x := StrToFloat(ExtractAndTrim(sLine,','));
          dataValues[iXPoints].y := StrToFloat(sLine);
          if (iXPoints >= 1) then
          begin
            case slopeTypeY of
              SLOPE_INCREASE :
                if (dataValues[iXPoints].y <= dataValues[iXPoints-1].y) then
                  // We cannot look up X if Y values do not change, or changes direction
                  slopeTypeY := SLOPE_MIXED;
              SLOPE_DECREASE :
                if (dataValues[iXPoints].y >= dataValues[iXPoints-1].y) then
                  // We cannot look up X if Y values do not change, or changes direction
                  slopeTypeY := SLOPE_MIXED;
              SLOPE_UNKNOWN :
                if (dataValues[iXPoints].y > dataValues[iXPoints-1].y) then
                  slopeTypeY := SLOPE_INCREASE
                else
                if (dataValues[iXPoints].y < dataValues[iXPoints-1].y) then
                  slopeTypeY := SLOPE_DECREASE;
                else
                  slopeTypeY := SLOPE_MIXED;
            end; // case
          end;
          Inc(iXPoints);
        end; // while
      except
        result := FALSE;
      end; // except
    end // if
    else
      result := FALSE;

    if (not result) then
      Self.Clear;

    slResponsePoints.Free;

  finally
    FormatSettings.DecimalSeparator := cCurrentDecimalSeparator;
  end; // finally
end; // ReadFromIniFile

//***************************************************************************
//
//  FUNCTION  : ReadFromIniFile
//
//  I/P       : cifSource (TCustomIniFile) - The TCustomInifile that holds the
//                2D table in a section.
//
//              sSectionName (string) - The section that holds the 2D table.
//
//  O/P       : (boolean) - TRUE if the data was correctly read.
//
//  OPERATION : Reads in a section from a TIniFile, containing values of comma-
//              separated point pairs, with the first number as X, and the
//              second as Y.   X values should increase through the file.
//              The 'name' part of the name-value pairs is irrelevant.
//
//  UPDATED   : 2007-09-07
//
//***************************************************************************
function TArray2D.ReadFromData(source : array of TCoord2DPoint) : boolean;
var
  n : Integer;

begin
  result := TRUE;

  iXPoints := Length(source);

  // First, scan the array, confirming that X-points increase in value.
  n := 1;
  while ((result) and
         (n < iXPoints))  do
  begin
    result := source[n].x > source[n-1].x;
    Inc(n);
  end; // while

  // Proceed only if the source contains 1 or more valid, increasing points
  if ((result) and (iXPoints > 0)) then
  begin
    SetLength(dataValues,iXPoints);
    n := 0;
    while ((result) and
           (n < iXPoints)) do
    begin
      dataValues[n].x := source[n].x;
      dataValues[n].y := source[n].y;
      if (n >= 1) then
      begin
        case slopeTypeY of
          SLOPE_INCREASE :
            if (dataValues[n].y <= dataValues[n-1].y) then
              // We cannot look up X if Y values do not change, or changes direction
              slopeTypeY := SLOPE_MIXED;
          SLOPE_DECREASE :
            if (dataValues[n].y >= dataValues[n-1].y) then
              // We cannot look up X if Y values do not change, or changes direction
              slopeTypeY := SLOPE_MIXED;
          SLOPE_UNKNOWN :
            if (dataValues[n].y > dataValues[n-1].y) then
              slopeTypeY := SLOPE_INCREASE
            else
            if (dataValues[n].y < dataValues[n-1].y) then
              slopeTypeY := SLOPE_DECREASE;
            else
              slopeTypeY := SLOPE_MIXED;
        end; // case
      end;
      Inc(n);
    end; // while
  end // if
  else
    result := FALSE;

  if (not result) then
    Self.Clear;
end; // ReadFromArray

//***************************************************************************
//
//  FUNCTION  : Build
//
//  I/P       : iX : Integer - The X size of the 2D lookup
//
//  O/P       :
//
//  OPERATION : Creates an empty 2-D array of the given size.
//              For "manual" loading
//
//  UPDATED   : 2016-02-24
//
//***************************************************************************
procedure TArray2D.Build(iX : integer);
begin
  Self.Clear;

  sSource := 'Built';

  iXPoints := iX;

  SetLength(dataValues,iXPoints);
end; // Build

//***************************************************************************
//
//  FUNCTION  : StuffX
//
//  I/P       : iX : Integer - The column number of the element being stuffed
//
//              dX : double - The column value being inserted
//
//  O/P       :
//
//  OPERATION : Fill in the given value in the indicated column
//              For "manual" loading
//
//  UPDATED   : 2016-02-24
//
//***************************************************************************
procedure TArray2D.StuffX(iX : Integer;
                          dX : double);
begin
  dataValues[iX].x := dX;
end; // StuffX

//***************************************************************************
//
//  FUNCTION  : StuffY
//
//  I/P       : iY : Integer - The row number of the element being stuffed
//
//              dY : double - The row value being inserted
//
//  O/P       :
//
//  OPERATION : Fill in the given value in the indicated row
//              For "manual" loading
//
//  UPDATED   : 2016-02-24
//
//***************************************************************************
procedure TArray2D.StuffY(iY : Integer;
                          dY : double);
begin
  dataValues[iY].y := dY;
end; // StuffY

//***************************************************************************
//
//  FUNCTION  : LookupY
//
//  I/P       : dXValue (double) - the X-value, for which a Y-value should be
//                looked up from the given data.
//
//  O/P       : (double) - the Y value for the given X-value.
//
//  OPERATION : This function is the reverse of LookupX.   It does not extrapolate
//              past the end points.
//
//              If there is only one defined point, treat the X/Y pair as
//              defining an offset that is applied to the given X value.
//
//              For 2 or more points, between these points, apply a linear
//              interpolation.
//
//              Beyond the end points of the X data, return the value of the
//              closest end-point i.e. the Y value goes flat-line.
//
//  UPDATED   : 2017-05-29
//
//***************************************************************************
function TArray2D.LookupY(dXValue : double) : Double;
var
  n : Integer;

begin
  if (iXPoints < 1) then
    raise ERangeError.CreateFmt('Invalid lookup table (' + sSource + ')',[])
  else
    if (iXPoints = 1) then
      // If only one data pair is available, treat it as a fixed offset
      result := dXValue + (dataValues[0].y - dataValues[0].x)
    else
      if (dXValue <= dataValues[0].x) then
        result := dataValues[0].y
      else
        if (dXValue >= dataValues[iXPoints-1].x) then
          result := dataValues[iXPoints-1].y
        else
        begin
          n := 1;
          while ((n < iXPoints-1) and (dataValues[n].x < dXValue)) do
            Inc(n);
          // The x value now lies fractionally between n-1 and n
          result := dataValues[n-1].y +
                    (dXValue - dataValues[n-1].x) / (dataValues[n].x - dataValues[n-1].x) *
                    (dataValues[n].y - dataValues[n-1].y);
        end; // else
end; // LookupY

//***************************************************************************
//
//  FUNCTION  : LookupYEx
//
//  I/P       : dXValue (double) - the X-value, for which a Y-value should be
//                looked up from the given data.
//
//  O/P       : (double) - the Y value for the given X-value.
//
//  OPERATION : If there is only one defined point, treat the X/Y pair as
//              defining an offset that is applied to the given X value.
//
//              For 2 or more points, between these points, apply a linear
//              interpolation.
//
//              Beyond the points, extrapolate using the slope that was between
//              the last two available points.
//
//  UPDATED   : 2017-05-29
//
//***************************************************************************
function TArray2D.LookupYEx(dXValue : double) : Double;
var
  n : Integer;

begin
  if (iXPoints < 1) then
    raise ERangeError.CreateFmt('Invalid lookup table (' + sSource + ')',[])
  else
    if (iXPoints = 1) then
      // If only one data pair is available, treat it as a linear offset
      result := dXValue + (dataValues[0].y - dataValues[0].x)
    else
      if (dXValue <= dataValues[0].x) then
        result := dataValues[0].y +
                  (dXValue - dataValues[0].x) / (dataValues[1].x - dataValues[0].x) *
                  (dataValues[1].y - dataValues[0].y)
      else
        if (dXValue >= dataValues[iXPoints-1].x) then
          result := dataValues[iXPoints-2].y +
                    (dXValue - dataValues[iXPoints-2].x) / (dataValues[iXPoints-1].x - dataValues[iXPoints-2].x) *
                    (dataValues[iXPoints-1].y - dataValues[iXPoints-2].y)
        else
        begin
          n := 1;
          while ((n < iXPoints-1) and (dataValues[n].x < dXValue)) do
            Inc(n);
          // The x value now lies fractionally between n-1 and n
          result := dataValues[n-1].y +
                    (dXValue - dataValues[n-1].x) / (dataValues[n].x - dataValues[n-1].x) *
                    (dataValues[n].y - dataValues[n-1].y);
        end; // else
end; // LookupYEx

//***************************************************************************
//
//  FUNCTION  : LookupX
//
//  I/P       : dYValue (double) - the Y-value, for which a X-value should be
//                looked up from the given data.
//
//  O/P       : (double) - the X value for the given Y-value.
//
//  OPERATION : This function is the reverse of LookupY.   It does not extrapolate
//              past the end points.
//
//              This function will only work if there is a 1-1 mapping for
//              the original X/Y data.
//
//              If there is only one defined point, treat the X/Y pair as
//              defining an offset that is applied to the given Y value.
//
//              For 2 or more points, between these points, apply a linear
//              interpolation.
//
//              Beyond the points, we cannot give a unique X-value.   This
//              function is the opposite of LookupY, so there is no 1-1 mapping
//              of Y to X beyond the end points (where we held Y constant for
//              all X).   Y is not defined beyond the end points.
//
//  UPDATED   : 2017-05-29
//
//***************************************************************************
function TArray2D.LookupX(dYValue : double) : Double;
var
  n : Integer;

begin
  if (iXPoints < 1) then
    raise ERangeError.CreateFmt('Invalid lookup table (' + sSource + ')',[])
  else
    if (iXPoints = 1) then
      // If only one data pair is available, treat it as a linear offset
      result := dYValue - (dataValues[0].y - dataValues[0].x)
    else
      if ((slopeTypeY = SLOPE_UNKNOWN) or
          (slopeTypeY = SLOPE_MIXED)) then
        raise ERangeError.CreateFmt('No unique X for given Y',[])
      else
        if (dYValue < dataValues[0].y) then
          raise ERangeError.CreateFmt('No unique X for given Y',[])
        else
          if (dYValue > dataValues[iXPoints-1].y) then
            raise ERangeError.CreateFmt('No unique X for given Y',[])
          else
          begin
            n := 1;
            while ((n < iXPoints-1) and (dataValues[n].y < dYValue)) do
              Inc(n);
            // The y value now lies fractionally between n-1 and n
            result := dataValues[n-1].x +
                      (dYValue - dataValues[n-1].y) / (dataValues[n].y - dataValues[n-1].y) *
                      (dataValues[n].x - dataValues[n-1].x);
          end; // else
end; // LookupX

//***************************************************************************
//
//  FUNCTION  : LookupXEx
//
//  I/P       : dYValue (double) - the Y-value, for which a X-value should be
//                looked up from the given data.
//
//  O/P       : (double) - the X value for the given Y-value.
//
//  OPERATION : This function will only work if there is a 1-1 mapping for
//              the original X/Y data.
//
//              If there is only one defined point, treat the X/Y pair as
//              defining an offset that is applied to the given Y value.
//
//              For 2 or more points, between these points, apply a linear
//              interpolation.
//
//              Beyond the end points, apply a linear extrapolation based on
//              the slope between the last two end points.
//
//  UPDATED   : 2017-05-29
//
//***************************************************************************
function TArray2D.LookupXEx(dYValue : double) : Double;
var
  n : Integer;

begin
  if (iXPoints < 1) then
    raise ERangeError.CreateFmt('Invalid lookup table (' + sSource + ')',[])
  else
    if (iXPoints = 1) then
      // If only one data pair is available, treat it as a linear offset
      result := dYValue - (dataValues[0].y - dataValues[0].x)
    else
      if ((slopeTypeY = SLOPE_UNKNOWN) or
          (slopeTypeY = SLOPE_MIXED)) then
        raise ERangeError.CreateFmt('No unique X for given Y',[])
      else
        if (dYValue < dataValues[0].y) then
          // The y value now lies before the first point
          result := dataValues[0].x +
                    (dYValue - dataValues[0].y) / (dataValues[1].y - dataValues[0].y) *
                    (dataValues[1].x - dataValues[0].x)
        else
          if (dYValue > dataValues[iXPoints-1].y) then
            // The y value now lies after the last point
            result := dataValues[iXPoints-2].x +
                      (dYValue - dataValues[iXPoints-2].y) / (dataValues[iXPoints-1].y - dataValues[iXPoints-2].y) *
                      (dataValues[iXPoints-1].x - dataValues[iXPoints-2].x)
          else
          begin
            n := 1;
            while ((n < iXPoints-1) and (dataValues[n].y < dYValue)) do
              Inc(n);
            // The y value now lies fractionally between n-1 and n
            result := dataValues[n-1].x +
                      (dYValue - dataValues[n-1].y) / (dataValues[n].y - dataValues[n-1].y) *
                      (dataValues[n].x - dataValues[n-1].x);
          end; // else
end; // LookupXEx

//***************************************************************************
//
//  FUNCTION  : Destroy
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
destructor TArray2D.Destroy;
begin
  SetLength(dataValues,0);
  inherited Destroy;
end;

//***************************************************************************
//
//  FUNCTION  : Create
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
constructor TArray3D.Create;
begin
  inherited Create;
  Self.Clear;
end; // Create

//***************************************************************************
//
//  FUNCTION  : Clear
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/05/10
//
//***************************************************************************
procedure TArray3D.Clear;
begin
  sSource := 'None';
  iXPoints := 0;
  iYPoints := 0;
  SetLength(adXValues,0);
  SetLength(adYValues,0);
  SetLength(adData,0,0);
end; // Clear

//***************************************************************************
//
//  FUNCTION  : ReadFromFile
//
//  I/P       : sFileName (string) - The full name of the text file that
//              contains the data.
//
//              cSeparator (char) - The character separating the values
//
//  O/P       : (boolean) - TRUE if the data was correctly read.
//
//  OPERATION : Reads in a text file, containing lines of data that define
//              a three-dimensional data set.
//              The first line contains xn unique X values, in ascending order.
//              the second line contains yn unique Y values, in ascending order.
//              There follows xn rows of data, each containing yn values.
//
//  UPDATED   : 2006/11/22
//
//***************************************************************************
function TArray3D.ReadFromFile(sFileName : String;
                               cSeparator : char) : boolean;
var
  sLine : String;
  sZValue : String;
  dLastX : Double;
  dLastY : Double;
  iXCounter : Integer;
  iYCounter : Integer;
  dTemp : Double;
  cCurrentDecimalSeparator : char;

begin
  result := TRUE;

  // Store the current decimal separator, so that we can restore it at the end.
  cCurrentDecimalSeparator := FormatSettings.DecimalSeparator;

  try
    sSource := sFileName;

    AssignFile(fInputData,sFileName);
    // clear any previous IOResult
    IOResult;
    {$I-}
    Reset(fInputData);
    {$I+}
    if (IOResult=0) then
    begin
      // There may (should) be a line containing the decimal separator character used in this file.
      // If so, read and use it in the conversions below
      sLine := GetDataLine;
      if (sLine = '.') or (sLine = ',') then
        FormatSettings.DecimalSeparator := sLine[1]
      else
        Reset(fInputData);

      // Test the line of X-data
      if ((not Eof(fInputData)) and (result)) then
      begin
        iXPoints := 0;
        dLastX := -MaxDouble;
        sLine := GetDataLine;
        RemoveDuplicates(sLine,cSeparator);
        while ((sLine <> '') and (result)) do
        begin
          try
            dTemp := StrToFloat(ExtractAndTrim(sLine,cSeparator));
            // X values must show an increase
            if (dTemp <= dLastX) then
              result := FALSE
            else
              dLastX := dTemp;
            Inc(iXPoints);
          except
            result := FALSE;
          end; // except
        end; // while
      end; // if
      if (iXPoints = 0) then
        result := FALSE;

      // Test the line of Y-data
      if ((not Eof(fInputData)) and (result)) then
      begin
        iYPoints := 0;
        dLastY := -MaxDouble;
        sLine := GetDataLine;
        RemoveDuplicates(sLine,cSeparator);
        while ((sLine <> '') and (result)) do
        begin
          try
            dTemp := StrToFloat(ExtractAndTrim(sLine,cSeparator));
            // Y values must show an increase in value
            if (dTemp <= dLastY) then
              result := FALSE
            else
              dLastY := dTemp;
            Inc(iYPoints);
          except
            result := FALSE;
          end; // except
        end; // while
      end; // if
      if (iYPoints = 0) then
        result := FALSE;

      // Proceed only if the file contains valid data
      if (result) then
      begin
        SetLength(adXValues,iXPoints);
        SetLength(adYValues,iYPoints);
        SetLength(adData,iXPoints,iYPoints);

        Reset(fInputData);

        // There may (should) be a line containing the decimal separator character used in this file.
        // If so, read and use it in the conversions below
        sLine := GetDataLine;
        if (sLine = '.') or (sLine = ',') then
          FormatSettings.DecimalSeparator := sLine[1]
        else
          Reset(fInputData);

        // Now read and store the X values
        iXCounter := 0;
        sLine := GetDataLine;
        RemoveDuplicates(sLine,cSeparator);
        while (sLine <> '') do
        begin
          adXValues[iXCounter] := StrToFloat(ExtractAndTrim(sLine,cSeparator));
          Inc(iXCounter);
        end; // while

        // Now read and store the Y values
        iYCounter := 0;
        sLine := GetDataLine;
        RemoveDuplicates(sLine,cSeparator);
        while (sLine <> '') do
        begin
          adYValues[iYCounter] := StrToFloat(ExtractAndTrim(sLine,cSeparator));
          Inc(iYCounter);
        end; // while

        // Now read and store the Z values
        iXCounter := 0;
        while ((iXCounter < iXPoints) and
               (result)) do
        begin
          sLine := GetDataLine;
          RemoveDuplicates(sLine,cSeparator);
          result := (Count_Chars(sLine,',') = iXPoints-1);
          iYCounter := 0;
          while ((iYCounter < iYPoints) and
                 (result)) do
          begin
            try
              sZValue := ExtractAndTrim(sLine,cSeparator);
              if (sZValue <> 'NAN') then
                adData[iXCounter,iYCounter] := StrToFloat(sZValue)
              else
                adData[iXCounter,iYCounter] := NAN;
            except
              result := FALSE;
            end; // try
            Inc(iYCounter);
          end; // while
          Inc(iXCounter);
        end; // while

      end // if
      else
        result := FALSE;

      System.CloseFile(fInputData);

    end // if
    else
      result := FALSE;

    if (not result) then
      Self.Clear;

  finally
    // Restore the used decimal separator
    FormatSettings.DecimalSeparator := cCurrentDecimalSeparator;
  end; // finally
end; // ReadFromFile

//***************************************************************************
//
//  FUNCTION  : ReadFromIniFile
//
//  I/P       : cifSource (TCustomIniFile) - The TCustomInifile that holds the
//                3D table in a section.
//
//              sSectionName (string) - The section that holds the 2D table.
//
//  O/P       : (boolean) - TRUE if the data was correctly read.
//
//  OPERATION : Reads in a section from a TIniFile, containing values of comma-
//              separated point pairs, with the first number as X, and the
//              second as Y.   X values should increase through the file.
//              The 'name' part of the name-value pairs is irrelevant.
//
//  UPDATED   : 2007-09-07
//
//***************************************************************************
function TArray3D.ReadFromIniFile(cifSource : TCustomIniFile;
                                  sSectionName : string) : boolean;
var
  sLine : String;
  sZValue : String;
  dLastX : Double;
  dLastY : Double;
  iXCounter : Integer;
  iYCounter : Integer;
  dTemp : Double;
  cCurrentDecimalSeparator : char;

begin
  result := TRUE;

  cCurrentDecimalSeparator := FormatSettings.DecimalSeparator;

  try
    // Take care of the situation where the data file was created in a locale that uses a different decimal separator
    FormatSettings.DecimalSeparator := GetNthChar(cifSource.ReadString('General','DecimalSeparator','.'),1);

    sSource := sSectionName;

    // Test the line of X-data
    iXPoints := 0;
    dLastX := -MaxDouble;
    sLine := cifSource.ReadString(sSectionName,'X','');
    RemoveDuplicates(sLine,',');
    while ((sLine <> '') and (result)) do
    begin
      try
        dTemp := StrToFloat(ExtractAndTrim(sLine,','));
        // X values must show an increase
        if (dTemp <= dLastX) then
          result := FALSE
        else
          dLastX := dTemp;
        Inc(iXPoints);
      except
        result := FALSE;
      end; // except
    end; // while
    if (iXPoints = 0) then
      result := FALSE;

    // Test the line of Y-data
    iYPoints := 0;
    dLastY := -MaxDouble;
    sLine := cifSource.ReadString(sSectionName,'Y','');
    RemoveDuplicates(sLine,',');
    while ((sLine <> '') and (result)) do
    begin
      try
        dTemp := StrToFloat(ExtractAndTrim(sLine,','));
        // Y values must show an increase
        if (dTemp <= dLastY) then
          result := FALSE
        else
          dLastY := dTemp;
        Inc(iYPoints);
      except
        result := FALSE;
      end; // except
    end; // while
    if (iYPoints = 0) then
      result := FALSE;

    // Proceed only if the section contains valid data
    if (result) then
    begin
      SetLength(adXValues,iXPoints);
      SetLength(adYValues,iYPoints);
      SetLength(adData,iXPoints,iYPoints);

      // Now read and store the X values
      iXCounter := 0;
      sLine := cifSource.ReadString(sSectionName,'X','');
      RemoveDuplicates(sLine,',');
      while (sLine <> '') do
      begin
        adXValues[iXCounter] := StrToFloat(ExtractAndTrim(sLine,','));
        Inc(iXCounter);
      end; // while

      // Now read and store the Y values
      iYCounter := 0;
      sLine := cifSource.ReadString(sSectionName,'Y','');
      RemoveDuplicates(sLine,',');
      while (sLine <> '') do
      begin
        adYValues[iYCounter] := StrToFloat(ExtractAndTrim(sLine,','));
        Inc(iYCounter);
      end; // while

      // Now read and store the Z values
      iYCounter := 0;
      while ((iYCounter < iYPoints) and
             (result)) do
      begin
        sLine := cifSource.ReadString(sSectionName,IntToStr(iYCounter+1),'');
        RemoveDuplicates(sLine,',');
        result := (Count_Chars(sLine,',') = iXPoints-1);
        iXCounter := 0;
        while ((iXCounter < iXPoints) and
               (result)) do
        begin
          try
            sZValue := ExtractAndTrim(sLine,',');
            if (sZValue <> 'NAN') then
              adData[iXCounter,iYCounter] := StrToFloat(sZValue)
            else
              adData[iXCounter,iYCounter] := NAN;
          except
            result := FALSE;
          end; // try
          Inc(iXCounter);
        end; // while
        Inc(iYCounter);
      end; // while

    end // if
    else
      result := FALSE;

    if (not result) then
      Self.Clear;

  finally
    FormatSettings.DecimalSeparator := cCurrentDecimalSeparator;
  end; // finally
end; // ReadFromIniFile

//***************************************************************************
//
//  FUNCTION  : Build
//
//  I/P       : iX, iY : Integer - The X and Y sizes of the 3D lookup
//
//  O/P       :
//
//  OPERATION : Creates an empty 3-D array of the given size
//              For "manual" loading
//
//  UPDATED   : 2010-05-03
//
//***************************************************************************
procedure TArray3D.Build(iX,iY : integer);
begin
  Self.Clear;

  sSource := 'Built';

  iXPoints := iX;
  iYPoints := iY;

  SetLength(adXValues,iXPoints);
  SetLength(adYValues,iYPoints);
  SetLength(adData,iXPoints,iYPoints);
end; // Build

//***************************************************************************
//
//  FUNCTION  : StuffX
//
//  I/P       : iX : Integer - The column number of the element being stuffed
//
//              dX : double - The column value being inserted
//
//  O/P       :
//
//  OPERATION : Fill in the given value in the indicated column
//              For "manual" loading
//
//  UPDATED   : 2010-05-03
//
//***************************************************************************
procedure TArray3D.StuffX(iX : Integer;
                          dX : double);
begin
  adXValues[iX] := dX;
end; // StuffX

//***************************************************************************
//
//  FUNCTION  : StuffY
//
//  I/P       : iY : Integer - The row number of the element being stuffed
//
//              dY : double - The row value being inserted
//
//  O/P       :
//
//  OPERATION : Fill in the given value in the indicated row
//              For "manual" loading
//
//  UPDATED   : 2016-02-24
//
//***************************************************************************
procedure TArray3D.StuffY(iY : Integer;
                          dY : double);
begin
  adYValues[iY] := dY;
end; // StuffY

//***************************************************************************
//
//  FUNCTION  : StuffZ
//
//  I/P       : iX, iY : Integer - The column and row number of the Z-value being stuffed
//
//              dZ : double - The Z value being inserted
//
//  O/P       :
//
//  OPERATION : Fill in the given value in the indicated column/row
//              For "manual" loading
//
//  UPDATED   : 2010-05-03
//
//***************************************************************************
procedure TArray3D.StuffZ(iX,iY : Integer;
                          dZ : double);
begin
  adData[iX,iY] := dZ;
end; // StuffZ

//***************************************************************************
//
//  FUNCTION  : Lookup
//
//  I/P       : dXValue,dYValue (double) - the X- and Y-values, for which a
//                Z-value should be looked up from the given data.
//
//  O/P       : (double) - the Z value for the given X- and Y-values.
//
//  OPERATION :
//
//  UPDATED   : 2006/11/22
//
//***************************************************************************
function TArray3D.Lookup(dXValue,dYValue : double) : Double;
var
  xn : Integer;
  yn : Integer;
  dZVal : Double;
  dZValm1 : Double;
  dZa : Double;
  dZb : Double;

begin
  result := 0.0;

  if ((iXPoints = 0) or (iYPoints = 0)) then
    raise ERangeError.CreateFmt('Invalid lookup table (' + sSource + ')',[])
  else
    // Check for X-values lower than the lowest X
    if (dXValue <= adXValues[0]) then
    begin
      // Check for Y-values lower than the lowest Y
      if (dYValue <= adYValues[0]) then
        result := adData[0,0]
      else
        // Check for Y-values higher than the highest Y
        if (dYValue >= adYValues[iYPoints-1]) then
          result := adData[0,iYPoints-1]
        else
        begin
          // 2D-Linear interpolation
          yn := 1;
          while ((yn < iYPoints-1) and (adYValues[yn] < dYValue)) do
            Inc(yn);
          // The y value now lies fractionally between yn-1 and yn
          result := adData[0,yn-1] +
                    (dYValue - adYValues[yn-1]) / (adYValues[yn] - adYValues[yn-1]) *
                    (adData[0,yn] - adData[0,yn-1]);
        end // if
    end // if
    else
      // Check for X-values higher than the highest X
      if (dXValue >= adXValues[iXPoints-1]) then
      begin
        // Check for Y-values lower than the lowest Y
        if (dYValue <= adYValues[0]) then
          result := adData[iXPoints-1,0]
        else
          // Check for Y-values higher than the highest Y
          if (dYValue >= adYValues[iYPoints-1]) then
            result := adData[iXPoints-1,iYPoints-1]
          else
          begin
            // 2D-Linear interpolation
            yn := 1;
            while ((yn < iYPoints-1) and (adYValues[yn] < dYValue)) do
              Inc(yn);
            // The y value now lies fractionally between xn-1 and xn
            result := adData[iXPoints-1,yn-1] +
                      (dYValue - adYValues[yn-1]) / (adYValues[yn] - adYValues[yn-1]) *
                      (adData[iXPoints-1,yn] - adData[iXPoints-1,yn-1]);
          end // if
      end // if
      else
        // The X-point lies between the limits
        // Check for Y-values lower than the lowest Y
        if (dYValue <= adYValues[0]) then
        begin
          // 2D-Linear interpolation
          xn := 1;
          while ((xn < iXPoints-1) and (adXValues[xn] < dXValue)) do
            Inc(xn);
          // The x value now lies fractionally between xn-1 and xn
          result := adData[xn-1,0] +
                    (dXValue - adXValues[xn-1]) / (adXValues[xn] - adXValues[xn-1]) *
                    (adData[xn,0] - adData[xn-1,0]);
        end // if
        else
          // Check for Y-values higher than the highest Y
          if (dYValue >= adYValues[iYPoints-1]) then
          begin
            // 2D-Linear interpolation
            xn := 1;
            while ((xn < iXPoints-1) and (adXValues[xn] < dXValue)) do
              Inc(xn);
            // The x value now lies fractionally between n-1 and n
            result := adData[xn-1,iYPoints-1] +
                      (dXValue - adXValues[xn-1]) / (adXValues[xn] - adXValues[xn-1]) *
                      (adData[xn,iYPoints-1] - adData[xn-1,iYPoints-1]);
          end // if
          else
          begin
            // 3-D Linear interpolation

            // Find the X-points that are on either side of the given X point
            xn := 1;
            while ((xn < iXPoints-1) and (adXValues[xn] < dXValue)) do
              Inc(xn);
            // Find the Y-points that are on either side of the given Y point
            yn := 1;
            while ((yn < iYPoints-1) and (adYValues[yn] < dYValue)) do
              Inc(yn);

            // We now know the 4 vertices of the XY rectangle that contains the
            // z-value

            // Check that all vertices are valid numbers
            if ((not isNAN(adData[xn-1,yn-1])) and
                (not isNAN(adData[xn,yn-1])) and
                (not isNAN(adData[xn,yn])) and
                (not isNAN(adData[xn-1,yn]))) then
            begin
              // Find the Zn and Zn-1 at the given X value on the two Y-sides of the rectangle
              dZValm1 := adData[xn-1,yn-1] +
                         (dXValue - adXValues[xn-1]) / (adXValues[xn] - adXValues[xn-1]) *
                         (adData[xn,yn-1] - adData[xn-1,yn-1]);
              dZVal := adData[xn-1,yn] +
                       (dXValue - adXValues[xn-1]) / (adXValues[xn] - adXValues[xn-1]) *
                       (adData[xn,yn] - adData[xn-1,yn]);

              // Now find the Z value on this X value for the given Y value.
              dZa := dZValm1 +
                     (dYValue - adYValues[yn-1]) / (adYValues[yn] - adYValues[yn-1]) *
                     (dZVal - dZValm1);

              // Find the Zn and Zn-1 at the given Y value on the two X-sides of the rectangle
              dZValm1 := adData[xn-1,yn-1] +
                         (dYValue - adYValues[yn-1]) / (adYValues[yn] - adYValues[yn-1]) *
                         (adData[xn-1,yn] - adData[xn-1,yn-1]);
              dZVal := adData[xn,yn-1] +
                       (dYValue - adYValues[yn-1]) / (adYValues[yn] - adYValues[yn-1]) *
                       (adData[xn,yn] - adData[xn,yn-1]);
              // Now find the Z value on this Y value for the given X value.
              dZb := dZValm1 +
                     (dXValue - adXValues[xn-1]) / (adXValues[xn] - adXValues[xn-1]) *
                     (dZVal - dZValm1);

              result := (dZa + dZb) / 2.0;
            end // if
            else
            begin
              // One or more of the vertices are NAN
              // Ensure that only one vertix is NAN, and then use the other three to
              // do a point-on-plane calculation
              if (isNAN(adData[xn-1,yn-1])) then
              begin
                if ((not isNAN(adData[xn,yn-1])) and
                    (not isNAN(adData[xn,yn])) and
                    (not isNAN(adData[xn-1,yn]))) then
                  result := ZOn3PointPlane(dXValue,dYValue,
                                           adXValues[xn],adYValues[yn-1],adData[xn,yn-1],
                                           adXValues[xn],adYValues[yn],adData[xn,yn],
                                           adXValues[xn-1],adYValues[yn],adData[xn-1,yn])
                else
                  result := NAN;
              end // if
              else
              if (isNAN(adData[xn,yn-1])) then
              begin
                if ((not isNAN(adData[xn-1,yn-1])) and
                    (not isNAN(adData[xn,yn])) and
                    (not isNAN(adData[xn-1,yn]))) then
                  result := ZOn3PointPlane(dXValue,dYValue,
                                           adXValues[xn-1],adYValues[yn-1],adData[xn-1,yn-1],
                                           adXValues[xn],adYValues[yn],adData[xn,yn],
                                           adXValues[xn-1],adYValues[yn],adData[xn-1,yn])
                else
                  result := NAN;
              end // if
              else
              if (isNAN(adData[xn,yn])) then
              begin
                if ((not isNAN(adData[xn-1,yn-1])) and
                    (not isNAN(adData[xn,yn-1])) and
                    (not isNAN(adData[xn-1,yn]))) then
                  result := ZOn3PointPlane(dXValue,dYValue,
                                           adXValues[xn-1],adYValues[yn-1],adData[xn-1,yn-1],
                                           adXValues[xn],adYValues[yn-1],adData[xn,yn-1],
                                           adXValues[xn-1],adYValues[yn],adData[xn-1,yn])
                else
                  result := NAN;
              end // if
              else
              if (isNAN(adData[xn-1,yn])) then
              begin
                if ((not isNAN(adData[xn-1,yn-1])) and
                    (not isNAN(adData[xn,yn-1])) and
                    (not isNAN(adData[xn,yn]))) then
                  result := ZOn3PointPlane(dXValue,dYValue,
                                           adXValues[xn-1],adYValues[yn-1],adData[xn-1,yn-1],
                                           adXValues[xn],adYValues[yn-1],adData[xn,yn-1],
                                           adXValues[xn],adYValues[yn],adData[xn,yn])
                else
                  result := NAN;
              end; // else
            end; // else
          end; // else
end; // Lookup

//***************************************************************************
//
//  FUNCTION  : Valid
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/09/27
//
//***************************************************************************
function TArray3D.Valid : boolean;
begin
  result := ((iXPoints <> 0) and (iYPoints <> 0));
end; // Valid

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
destructor TArray3D.Destroy;
begin
  SetLength(adData,0,0);
  SetLength(adXValues,0);
  SetLength(adYValues,0);
  inherited Destroy;
end;

end.
