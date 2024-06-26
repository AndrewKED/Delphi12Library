unit Checksum_Ops;

interface

uses
  System.SysUtils;

function GetXORChecksum(sTest : AnsiString) : Byte; overload;
function GetXORChecksum(testBlock : TBytes) : Byte; overload;
function GetAddChecksum(sTest : AnsiString) : Byte; overload;
function GetAddChecksum(testBlock : TBytes) : Byte; overload;

implementation

//***************************************************************************
//
//  FUNCTION  : GetXORChecksum
//
//  I/P       : sTest (AnsiString) - The string for which the checksum is
//                to be calculated.
//
//  O/P       : byte - A byte checksum of the given string.
//
//  OPERATION : Calculates the XOR checksum (as used in comms with the
//                station and UDP comms) of a given string.
//
//  UPDATED   : 2016-06-03
//
//***************************************************************************
function GetXORChecksum(sTest : AnsiString) : Byte; overload;
var
  n : Integer;

begin
  result := 0;
  for n := 1 to Length(sTest) do
    result := result xor Ord(sTest[n]);
end; // GetXORChecksum

function GetXORChecksum(testBlock : TBytes) : Byte; overload;
var
  n : Integer;

begin
  result := 0;
  for n := 0 to Length(testBlock)-1 do
    result := result xor testBlock[n];
end; // GetXORChecksum

//***************************************************************************
//
//  FUNCTION  : GetAddChecksum
//
//  I/P       : sTest (AnsiString) - The AnsiString for which the checksum is
//                to be calculated.
//
//  O/P       : byte - A byte checksum of the given string.
//
//  OPERATION : Calculates the additive checksum (as used in comms with the
//                iMet-3000/3100) of a given string.
//
//  UPDATED   : 2016-06-03
//
//***************************************************************************
function GetAddChecksum(sTest : AnsiString) : Byte; overload;
var
  n : Integer;

begin
  result := 0;
  for n := 1 to Length(sTest) do
    result := result + Ord(sTest[n]);
end; // GetAddChecksum

function GetAddChecksum(testBlock : TBytes) : Byte; overload;
var
  n : Integer;

begin
  result := 0;
  for n := 0 to Length(testBlock)-1 do
    result := result + testBlock[n];
end; // GetAddChecksum

end.
