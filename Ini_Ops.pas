unit Ini_Ops;

interface

uses
  System.IniFiles;

function GetIniFileFloat(targetFile : TCustomIniFile;
                         sSection : String;
                         sKey : String;
                         dInvalid : Double) : Double;
procedure SetIniFileFloat(targetFile : TCustomIniFile;
                          sSection : String;
                          sKey : String;
                          valueGiven : Double);

implementation

uses
  System.SysUtils,
  Str_Ops;

//***************************************************************************
//
//  FUNCTION  : GetIniFileFloat
//
//  I/P       : targetFile : TCustomIniFile - The pre-opened ini-format
//                information file
//
//              sSection : String - Section in the ini file
//
//              sKey : String - Key in the ini file
//
//              dInvalid : double - Value to return if invalid
//
//  O/P       : double - The result
//
//  OPERATION : This function is only necessary for TMemIniFile and TIniFile.
//              It need not be used for TRegistryIniFile, which stores floats
//              in binary form. (These are all descendents of TCustomIniFile)
//
//              Reads a floating point number from an ini-formation information
//              file.
//
//              The function first tries to convert using the current decimal
//              separator. If that is not successful, it tries the "other" one.
//              In general, decimal separators are either '.' or ','.
//
//  UPDATED   : 2019-03-07
//
//***************************************************************************
function GetIniFileFloat(targetFile : TCustomIniFile;
                         sSection : String;
                         sKey : String;
                         dInvalid : Double) : Double;
begin
  result := ForcedStrToFloat(targetFile.ReadString(sSection, sKey, ''), dInvalid);
end; // GetIniFileFloat

//***************************************************************************
//
//  FUNCTION  : SetIniFileFloat
//
//  I/P       : targetFile : TCustomIniFile - The pre-opened ini-format
//                information file
//
//              sSection : String - Section in the ini file
//
//              sKey : String - Key in the ini file
//
//              valueGiven : double - The value to be written
//
//  O/P       : None
//
//  OPERATION : This function is only necessary for TMemIniFile and TIniFile.
//              It need not be used for TRegistryIniFile, which stores floats
//              in binary form. (These are all descendents of TCustomIniFile)
//
//              Writes a floating point number to an ini-formation information
//              file.   The function uses the decimal separator that was in use
//              when the file was created (which is expected to be indicated
//              in the 'General'/'DecimalSeparator' section/key.
//
//              Because the thousands separator may also be an issue, the value
//              is written in scientific notation.
//
//  UPDATED   : 2020-04-14
//
//***************************************************************************
procedure SetIniFileFloat(targetFile : TCustomIniFile;
                          sSection : String;
                          sKey : String;
                          valueGiven : Double);
var
  cCurrentDecimalSeaprator : char;

begin
  // Load the information using the decimal separator that was used when the
  // ini file was created.
  cCurrentDecimalSeaprator := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := GetNthChar(targetFile.ReadString('General','DecimalSeparator','.'),1);
    targetFile.WriteString(sSection, sKey, Format('%e', [valueGiven]));
  finally
    FormatSettings.DecimalSeparator := cCurrentDecimalSeaprator;
  end;
end; // SetIniFileFloat

end.
