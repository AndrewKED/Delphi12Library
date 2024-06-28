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
function CountValues(targetFile : TCustomIniFile;
                     sSection : String;
                     filter : String = '.+') : Integer;

implementation

uses
  System.SysUtils, System.Classes, System.RegularExpressions,
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

//***************************************************************************
//
//  FUNCTION  : CountValues
//
//  I/P       : targetFile : TCustomIniFile - The target INI file.
//
//              sSection : String - The name of the section to be examined.
//
//              filter : String = '.+' - The optional regex filter to be applied.
//
//  O/P       : Integer - The number of keys within the section that match
//                the filter.
//
//  OPERATION : Count the number of keys in an ini file section, with optional
//              key name matching.
//
//  UPDATED   : 2023-03-28
//
//***************************************************************************
function CountValues(targetFile : TCustomIniFile;
                     sSection : String;
                     filter : String = '.+') : Integer;
var
  content : TStringList;
  n: Integer;

begin
  Result := 0;
  content := TStringList.Create;
  try
    targetFile.ReadSection(sSection, content);
    for n := 0 to content.Count-1 do
    begin
      if (TRegEx.Match(content[n], filter).Index = 1) then
      begin
        Inc(Result);
      end; // if
    end; // for
  finally
    content.Free;
  end;

end;

end.
