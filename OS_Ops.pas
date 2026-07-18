unit OS_Ops;

interface

function GetEnvironmentInteger(name : String;
                               default : Integer = 0) : Integer;

implementation

uses
  System.SysUtils,
  Str_Ops;

//***************************************************************************
//
//  FUNCTION  : GetEnvironmentInteger
//
//  I/P       : name : String - The name of the environment variable
//
//              default : Integer = 0 - the value to return if the environment
//                variable does not exists or is not a valid integer.
//
//  O/P       : Integer - The environment variable as an integer, or the default.
//
//  OPERATION : Attempt to read the given environment variable as an integer.
//
//  UPDATED   : 2025-09-08
//
//***************************************************************************
function GetEnvironmentInteger(name : String;
                               default : Integer = 0) : Integer;
var
  s : String;

begin
  Result := default;

  s := GetEnvironmentVariable(name);
  if (IsAnInteger(s)) then
  begin
    Result := s.ToInteger;
  end; // if
end; // GetEnvironmentInteger

end.
