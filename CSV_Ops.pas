unit CSV_Ops;

interface

uses
  System.SysUtils;

var
  CSVFormatSettings: TFormatSettings;
  lastUsedCSVFileName : TFileName;

implementation

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
initialization
  CSVFormatSettings := FormatSettings;
  CSVFormatSettings.DecimalSeparator := '.';
  CSVFormatSettings.ListSeparator := ',';

  lastUsedCSVFileName := '';

end.
