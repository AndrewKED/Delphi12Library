unit Number_Ops;

interface

const
  // The number of set bits in a byte value of given value
  // (This constant definition saves on having to work this out with loops)
  SET_BITS_IN_BYTE : array[0..255] of byte =
    (0,1,1,2,1,2,2,3, 1,2,2,3,2,3,3,4,   // 0b00000000 to 0b00001111
     1,2,2,3,2,3,3,4, 2,3,3,4,3,4,4,5,   // 0b00010000 to 0b00011111
     1,2,2,3,2,3,3,4, 2,3,3,4,3,4,4,5,   // 0b00100000 to 0b00101111
     2,3,3,4,3,4,4,5, 3,4,4,5,4,5,5,6,   // 0b00110000 to 0b00111111
     1,2,2,3,2,3,3,4, 2,3,3,4,3,4,4,5,   // 0b01000000 to 0b01001111
     2,3,3,4,3,4,4,5, 3,4,4,5,4,5,5,6,   // 0b01010000 to 0b01011111
     2,3,3,4,3,4,4,5, 3,4,4,5,4,5,5,6,   // 0b01100000 to 0b01101111
     3,4,4,5,4,5,5,6, 4,5,5,6,5,6,6,7,   // 0b01110000 to 0b01111111
     1,2,2,3,2,3,3,4, 2,3,3,4,3,4,4,5,   // 0b10000000 to 0b10001111
     2,3,3,4,3,4,4,5, 3,4,4,5,4,5,5,6,   // 0b10010000 to 0b10011111
     2,3,3,4,3,4,4,5, 3,4,4,5,4,5,5,6,   // 0b10100000 to 0b10101111
     3,4,4,5,4,5,5,6, 4,5,5,6,5,6,6,7,   // 0b11110000 to 0b10111111
     2,3,3,4,3,4,4,5, 3,4,4,5,4,5,5,6,   // 0b11000000 to 0b11001111
     3,4,4,5,4,5,5,6, 4,5,5,6,5,6,6,7,   // 0b11010000 to 0b11011111
     3,4,4,5,4,5,5,6, 4,5,5,6,5,6,6,7,   // 0b11100000 to 0b11101111
     4,5,5,6,5,6,6,7, 5,6,6,7,6,7,7,8);  // 0b11110000 to 0b11111111


function Bytes2Int16(iByte0, iByte1 : byte) : Int16;
procedure Int162Bytes(GivenValue : int16;
                      var iByte0, iByte1 : byte);
function Bytes2UInt16(iByte0, iByte1 : byte) : UInt16;
procedure UInt162Bytes(GivenValue : uint16;
                       var iByte0, iByte1 : byte);
function Bytes2Int32(iByte0, iByte1, iByte2, iByte3 : byte) : Int32;
procedure Int322Bytes(GivenValue : int32;
                      var iByte0, iByte1, iByte2, iByte3 : byte);
function Bytes2UInt32(iByte0, iByte1, iByte2, iByte3 : byte) : UInt32;
procedure UInt322Bytes(GivenValue : uint32;
                       var iByte0, iByte1, iByte2, iByte3 : byte);
function Bytes2UInt64(iByte0, iByte1, iByte2, iByte3, iByte4, iByte5, iByte6, iByte7 : byte) : UInt64;
procedure UInt642Bytes(GivenValue : uint64;
                       var iByte0, iByte1, iByte2, iByte3, iByte4, iByte5, iByte6, iByte7 : byte);
function Bytes2Single(iByte0, iByte1, iByte2, iByte3 : byte) : single;
procedure Single2Bytes(GivenValue : single;
                       var iByte0, iByte1, iByte2, iByte3 : byte);
function IEEE754Single(iByte0, iByte1, iByte2, iByte3 : integer) : single;
function IntToBinStr(theValue : UInt64;
                     BitsRequired : byte;
                     ByteBreakChar : char;
                     NibbleBreakChar : char) : String;
function BinStrToInt(sBinary : string): cardinal;
function ByteSwap(cInput : cardinal; bLength : byte) : variant;
procedure ExchangeContent(var Value1 : Integer;
                          var Value2 : integer);
function Dec2Base(theValue : UInt64;
                  base : Byte;
                  unusedChars : String) : String;
function Base2Dec(theValue : String;
                  base : Byte;
                  unusedChars : String) : UInt64;
function SwapEndianHex(hex : String) : String;
function SwapEndian(theValue : Word) : Word;
procedure SetDecimalSeparatorAsPoint;
procedure RestoreDecimalSeparator;
function IsNumberInArray(const ANumber: Integer;
                         const AArray: array of Integer): Boolean;

implementation

uses
  WinApi.Windows,
  System.Math, system.SysUtils,
  Str_Ops, Generic_Ops;

var
  currentDecimalSeaprator : char;


//***************************************************************************
//
//  FUNCTION  : Bytes2Int16
//
//  I/P       : iByte0, iByte1 : byte - The component bytes that make up the
//                Int16 structure.
//
//  O/P       : Int16 : the representative unsigned 16-bit integer
//
//  OPERATION : Given an ordered set of bytes (iByte0 = LSB), return the
//                signed 16-bit integer value that they represent.
//
//              Alternatively use (PInt16(@buffer[index]))^
//
//  UPDATED   : 2015-07-16
//
//***************************************************************************
function Bytes2Int16(iByte0, iByte1 : byte) : Int16;
var
  FinalValue : Int16;
  RawBytes : array[1..2]of byte absolute FinalValue;

begin
  RawBytes[1] := iByte0;
  RawBytes[2] := iByte1;
  result := FinalValue;
end; // Bytes2Int16

//***************************************************************************
//
//  FUNCTION  : Int162Bytes
//
//  I/P       : GivenValue : Int16 - The 16-bit integer
//
//  O/P       : iByte0, iByte1 : byte - The component bytes that make up the
//                Int16 structure.
//
//  OPERATION : Given a signed 16-bit integer, return the ordered set of bytes
//                that represent this value.
//
//  UPDATED   : 2015-07-16
//
//***************************************************************************
procedure Int162Bytes(GivenValue : int16;
                      var iByte0, iByte1 : byte);
var
  InputValue : Int16;
  RawBytes : array[1..2]of byte absolute InputValue;

begin
  InputValue := GivenValue;
  iByte0 := RawBytes[1];
  iByte1 := RawBytes[2];
end; // Int162Bytes

//***************************************************************************
//
//  FUNCTION  : Bytes2UInt16
//
//  I/P       : iByte0, iByte1 : byte - The component bytes that make up the
//                UInt16 structure.
//
//  O/P       : UInt16 : the representative unsigned 16-bit integer
//
//  OPERATION : Given an ordered set of bytes, return the unsigned 16-bit
//                integer value that they represent.
//
//              Alternatively use (PUint16(@buffer[index]))^
//
//  UPDATED   : 2015-07-16
//
//***************************************************************************
function Bytes2UInt16(iByte0, iByte1 : byte) : UInt16;
var
  FinalValue : UInt16;
  RawBytes : array[1..2]of byte absolute FinalValue;

begin
  RawBytes[1] := iByte0;
  RawBytes[2] := iByte1;
  result := FinalValue;
end; // Bytes2UInt16

//***************************************************************************
//
//  FUNCTION  : UInt162Bytes
//
//  I/P       : GivenValue : uint16 - The 16-bit unsigned integer
//
//  O/P       : iByte0, iByte1 : byte - The component bytes that make up the
//                uint16 structure.
//
//  OPERATION : Given an unsigned 16-bit integer, return the ordered set of
//                bytes that represent this value.
//
//  UPDATED   : 2015-07-16
//
//***************************************************************************
procedure UInt162Bytes(GivenValue : uint16;
                       var iByte0, iByte1 : byte);
var
  InputValue : UInt16;
  RawBytes : array[1..2]of byte absolute InputValue;

begin
  InputValue := GivenValue;
  iByte0 := RawBytes[1];
  iByte1 := RawBytes[2];
end; // UInt162Bytes

//***************************************************************************
//
//  FUNCTION  : Bytes2Int32
//
//  I/P       : iByte0, iByte1, iByte2, iByte3 : byte - The component bytes
//                that make up the Int32 structure.
//
//  O/P       : Int32 : the representative unsigned 32-bit integer
//
//  OPERATION : Given an ordered set of bytes, return the signed 32-bit
//                integer value that they represent.
//
//              Alternatively use (PInt32(@buffer[index]))^
//
//  UPDATED   : 2015-06-10
//
//***************************************************************************
function Bytes2Int32(iByte0, iByte1, iByte2, iByte3 : byte) : Int32;
var
  FinalValue : Int32;
  RawBytes : array[1..4]of byte absolute FinalValue;

begin
  RawBytes[1] := iByte0;
  RawBytes[2] := iByte1;
  RawBytes[3] := iByte2;
  RawBytes[4] := iByte3;
  result := FinalValue;
end; // Bytes2Int32

//***************************************************************************
//
//  FUNCTION  : Int322Bytes
//
//  I/P       : GivenValue : int32 - The 32-bit integer
//
//  O/P       : iByte0, iByte1, iByte2, iByte3 : byte - The component bytes
//                that make up the Int32 structure.
//
//  OPERATION : Given a signed 32-bit integer, return the ordered set of bytes
//                that represent this value.
//
//  UPDATED   : 2015-06-15
//
//***************************************************************************
procedure Int322Bytes(GivenValue : int32;
                      var iByte0, iByte1, iByte2, iByte3 : byte);
var
  InputValue : Int32;
  RawBytes : array[1..4]of byte absolute InputValue;

begin
  InputValue := GivenValue;
  iByte0 := RawBytes[1];
  iByte1 := RawBytes[2];
  iByte2 := RawBytes[3];
  iByte3 := RawBytes[4];
end; // Int322Bytes

//***************************************************************************
//
//  FUNCTION  : Bytes2UInt32
//
//  I/P       : iByte0, iByte1, iByte2, iByte3 : byte - The component bytes
//                that make up the UInt32 structure.
//
//  O/P       : UInt32 : the representative unsigned 32-bit integer
//
//  OPERATION : Given an ordered set of bytes, return the unsigned 32-bit
//                integer value that they represent.
//
//              Alternatively use (PUint32(@buffer[index]))^
//
//  UPDATED   : 2015-06-10
//
//***************************************************************************
function Bytes2UInt32(iByte0, iByte1, iByte2, iByte3 : byte) : UInt32;
var
  FinalValue : UInt32;
  RawBytes : array[1..4]of byte absolute FinalValue;

begin
  RawBytes[1] := iByte0;
  RawBytes[2] := iByte1;
  RawBytes[3] := iByte2;
  RawBytes[4] := iByte3;
  result := FinalValue;
end; // Bytes2UInt32

//***************************************************************************
//
//  FUNCTION  : UInt322Bytes
//
//  I/P       : GivenValue : uint32 - The 32-bit unsigned integer
//
//  O/P       : iByte0, iByte1, iByte2, iByte3 : byte - The component bytes
//                that make up the Int32 structure.
//
//  OPERATION : Given an unsigned 32-bit integer, return the ordered set of
//                bytes that represent this value.
//
//  UPDATED   : 2015-06-15
//
//***************************************************************************
procedure UInt322Bytes(GivenValue : uint32;
                       var iByte0, iByte1, iByte2, iByte3 : byte);
var
  InputValue : UInt32;
  RawBytes : array[1..4]of byte absolute InputValue;

begin
  InputValue := GivenValue;
  iByte0 := RawBytes[1];
  iByte1 := RawBytes[2];
  iByte2 := RawBytes[3];
  iByte3 := RawBytes[4];
end; // UInt322Bytes

//***************************************************************************
//
//  FUNCTION  : Bytes2UInt64
//
//  I/P       : iByte0, iByte1, iByte2, iByte3, iByte4, iByte5, iByte6, iByte7 : byte -
//                The component bytes that make up the UInt64 structure.
//
//  O/P       : UInt64 : the representative unsigned 64-bit integer
//
//  OPERATION : Given an ordered set of bytes, return the unsigned 64-bit
//                integer value that they represent.
//
//  UPDATED   : 2017-09-14
//
//***************************************************************************
function Bytes2UInt64(iByte0, iByte1, iByte2, iByte3, iByte4, iByte5, iByte6, iByte7 : byte) : UInt64;
var
  FinalValue : UInt64;
  RawBytes : array[1..8]of byte absolute FinalValue;

begin
  RawBytes[1] := iByte0;
  RawBytes[2] := iByte1;
  RawBytes[3] := iByte2;
  RawBytes[4] := iByte3;
  RawBytes[5] := iByte4;
  RawBytes[6] := iByte5;
  RawBytes[7] := iByte6;
  RawBytes[8] := iByte7;
  result := FinalValue;
end; // Bytes2UInt64

//***************************************************************************
//
//  FUNCTION  : UInt642Bytes
//
//  I/P       : GivenValue : uint64 - The 64-bit unsigned integer
//
//  O/P       : iByte0, iByte1, iByte2, iByte3, iByte4, iByte5, iByte6, iByte7 : byte -
//                The component bytes that make up the Int64 structure.
//
//  OPERATION : Given an unsigned 64-bit integer, return the ordered set of
//                bytes that represent this value.
//
//  UPDATED   : 2017-09-14
//
//***************************************************************************
procedure UInt642Bytes(GivenValue : uint64;
                       var iByte0, iByte1, iByte2, iByte3, iByte4, iByte5, iByte6, iByte7 : byte);
var
  InputValue : UInt64;
  RawBytes : array[1..8]of byte absolute InputValue;

begin
  InputValue := GivenValue;
  iByte0 := RawBytes[1];
  iByte1 := RawBytes[2];
  iByte2 := RawBytes[3];
  iByte3 := RawBytes[4];
  iByte4 := RawBytes[5];
  iByte5 := RawBytes[6];
  iByte6 := RawBytes[7];
  iByte7 := RawBytes[8];
end; // UInt642Bytes

//***************************************************************************
//
//  FUNCTION  : Bytes2Single
//
//  I/P       : iByte0, iByte1, iByte2, iByte3 : byte - The component bytes
//                that make up the single structure.
//
//  O/P       : single : the representative single value
//
//  OPERATION : Given an ordered set of bytes, return the single (floating
//                point) value that they represent.
//
//              Useful : https://gregstoll.com/~gregstoll/floattohex/
//
//  UPDATED   : 2014-06-04
//
//***************************************************************************
function Bytes2Single(iByte0, iByte1, iByte2, iByte3 : byte) : single;
var
  FinalValue : single;
  RawBytes : array[1..4]of byte absolute FinalValue;

begin
  RawBytes[1] := iByte0;
  RawBytes[2] := iByte1;
  RawBytes[3] := iByte2;
  RawBytes[4] := iByte3;
  result := FinalValue;
end; // Bytes2Single

//***************************************************************************
//
//  FUNCTION  : Single2Bytes
//
//  I/P       : GivenValue : single - The floating point value to be converted
//
//  O/P       : iByte0, iByte1, iByte2, iByte3 : byte - The ordered set of bytes
//                that represent the storage of the given single
//
//  OPERATION : Given a single (floating point) value, return the ordered set
//                of bytes that is used to store/represent it.
//
//              Useful : https://gregstoll.com/~gregstoll/floattohex/
//
//  UPDATED   : 2014-06-04
//
//***************************************************************************
procedure Single2Bytes(GivenValue : single;
                       var iByte0, iByte1, iByte2, iByte3 : byte);
var
  Value : single;
  RawBytes : array[1..4]of byte absolute Value;

begin
  Value := GivenValue;
  iByte0 := RawBytes[1];
  iByte1 := RawBytes[2];
  iByte2 := RawBytes[3];
  iByte3 := RawBytes[4];
end; //

//***************************************************************************
//
//  FUNCTION  : IEEE754Single
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Converts the given 4 Little Endian 8-bit bytes into a single
//              according to IEEE 754.
//
//              See http://en.wikipedia.org/wiki/IEEE_754
//
//  UPDATED   :
//
//***************************************************************************
function IEEE754Single(iByte0, iByte1, iByte2, iByte3 : integer) : single;
const
  BIAS = 127;
var
  iFull : Integer;
  iExponent : Integer;
  iFraction : Integer;
begin
  iFull := (iByte3 shl 24) + (iByte2 shl 16) + (iByte1 shl 8) + iByte0;
  iExponent := (iFull shr 23) and $FF;
  iFraction := iFull and $7FFFFF;

  if (iExponent = $FF) then
  begin
    // Positive infinity, negative infinity or not-a-number
    if (iFraction = 0) then
    begin
      if ((iFull and $80000000) <> 0) then
        result := -Infinity
      else
        result := Infinity;
    end // if
    else
    begin
      if ((iFull and $80000000) <> 0) then
        result := -NaN
      else
        result := NaN;
    end; // else
  end // if
  else
  begin

    result := (1 + (1.0 * iFraction) / $7FFFFF) * Power(2.0,iExponent - BIAS);
    if ((iFull and $80000000) <> 0) then
      result := -result;
  end; // else
end; // IEEE754Single

//***************************************************************************
//
//  FUNCTION  : IntToBinStr
//
//  I/P       : theValue : UInt64 - The value to be converted
//
//              BitsRequired : byte - The number of bits in the result
//
//              ByteBreakChar : char - Character to place between bytes
//                Set to #0 for none.
//
//              NibbleBreakChar : char - Character to place between nibbles
//                If ByteBreakChar is #0, this character is placed between bytes too.
//                Set to #0 for none.
//
//  O/P       : string : The value converted into binary
//
//  OPERATION : Convert the given value to binary.   Trim or pad to the
//                specified number of bits
//
//  UPDATED   : 2020-10-23
//
//***************************************************************************
function IntToBinStr(theValue : UInt64;
                     BitsRequired : byte;
                     ByteBreakChar : char;
                     NibbleBreakChar : char) : String;
var
  Mask : UInt64;
  BitNow : Integer;

begin
  result := '';
  Mask := 1;
  BitNow := 0;
  while (BitNow < BitsRequired) do
  begin
    if ((theValue and Mask)<>0) then
      result := '1' + result
    else
      result := '0' + result;
    Inc(BitNow);
    Mask := Mask shl 1;
    // Add separator characters, as required
    if (BitNow < BitsRequired) then
    begin
      if ((ByteBreakChar <> #0) and
          (BitNow mod 8 = 0)) then
      begin
        result := ByteBreakChar + result
      end // if
      else
      begin
        if ((NibbleBreakChar <> #0) and
            (BitNow mod 4 = 0)) then
        begin
          result := NibbleBreakChar + result;
        end; // if
      end; // if
    end; // if
  end; // while
end; // IntToBinStr

//***************************************************************************
//
//  FUNCTION  : BinStrToInt
//
//  I/P       : sBinary (string) - The value, in binary
//
//  O/P       : (cardinal) - The value given.
//
//  OPERATION : Convert a binary string into its binary value
//
//  UPDATED   : 2008-08-08
//
//***************************************************************************
function BinStrToInt(sBinary : string): cardinal;
var
  iPlace : cardinal;
  n : Integer;
begin
  iPlace := 1;
  result := 0;
  n := Length(sBinary);
  while (n > 0) do
  begin
    if (sBinary[n] = '1') then
      result := result + iPlace;
    iPlace := iPlace * 2;
    Dec(n);
  end; // while
end; // BinStrToInt

//***************************************************************************
//
//  FUNCTION  : SwapBytes
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
function ByteSwap(cInput : cardinal; bLength : byte) : variant;
var
  i : byte;

begin
  result := 0;
  for i := 0 to blength - 1 do
  begin
    result := result shl 8; {shift all 8 left}
    result := result + ((cInput and ($FF shl (8 * i)){Byte to move} shr(8 * i)){make smalles byte});
  end; // for
end;

//***************************************************************************
//
//  FUNCTION  : ExchangeContent
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
procedure ExchangeContent(var Value1 : Integer;
                          var Value2 : integer); overload;
var
  Temp : Integer;

begin
  Temp := Value1;
  Value1 := Value2;
  Value2 := Temp;
end; // ExchangeContent

//***************************************************************************
//
//  FUNCTION  : Dec2Base
//
//  I/P       : theValue : UInt64 - The number to be expressed in a different base
//
//              base : Byte - The base (<= 36)
//
//              unusedChar : String - The characters that are not permitted
//                in the final result. The user must ensure there are no
//                duplicates and that there remain sufficient characters from
//                the set ['0'..'9','A'..'Z'] to represent the given number
//                to the require base.
//
//  O/P       : String - The given number, to the require base, not using the
//                identified "illegal" characters
//
//  OPERATION : Produce a representation of the given number in the given base.
//              Up to base 36 ('0'..'9','A'..'Z') may be implemented. The option
//              to not use certain characters (thereby reducing the maximum base)
//              is also offered.

//  Dec2Base(987654321,10,'');    // expect '987654321'
//  Dec2Base(127,16,'7F');        // expect '8H'
//  Dec2Base($FFFFFFFF,36,'');
//  Dec2Base($FFFFFFFFFFFFFFFF,31,'AEIOU');
//
//  UPDATED   : 2018-09-10
//
//***************************************************************************
function Dec2Base(theValue : UInt64;
                  base : Byte;
                  unusedChars : String) : String;
var
  usableCharacters : String;
  n : Integer;
  nextDigit : Integer;

begin
  result := '';

  usableCharacters := '';
  for n := 0 to 35 do
    usableCharacters := usableCharacters + IfThenV(n<=9, Char(n + Ord('0')), Char(n - 10 + Ord('A')));
  n := 1;
  while (n <= Length(unusedChars)) do
  begin
    usableCharacters := SearchAndReplace(usableCharacters, unusedChars[n], '');
    Inc(n);
  end;

  if ((base <= Length(usableCharacters)) and
      (base >= 2)) then
  begin
    while (theValue > 0) do
    begin
      nextDigit := theValue mod base;
      result := usableCharacters[nextDigit + 1] + result;
      theValue := theValue div base;
    end;
  end; // if
end;

//***************************************************************************
//
//  FUNCTION  : Base2Dec
//
//  I/P       : theValue : String - the number in the given base
//
//              base : Byte;
//
//              unusedChar : String - The characters (from ['0'..'9','A'..'Z']
//                that are not used in the given number representation.
//
//  O/P       : UInt64 - The given number in decimal
//
//  OPERATION : Restore a given string representing a number to a given base,
//              (optionally with given unused characters), in decimal
//
//  Base2Dec('3W5E11264SGSF',36,''); // Expect 18446744073709551615
//  Base2Dec('1Z141Z3',36,''); // Expect 4294967295
//  Base2Dec('9876543210',10,'');
//  Base2Dec('RF075LC45N86H',31,'AEIOU'); // Expect 18446744073709551615
//  Base2Dec('8H',16,'7F'); // Expect 255
//
//              Raises an exception if theValue contains invalid digits.
//
//  UPDATED   : 2019-05-04
//
//***************************************************************************
function Base2Dec(theValue : String;
                  base : Byte;
                  unusedChars : String) : UInt64;
var
  multiplier : UInt64;
  usableCharacters : String;
  n : Integer;
  digitValue : Integer;

begin
  result := 0;
  // Create a digits string of the possible usable characters (i.e. '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')
  usableCharacters := '';
  for n := 0 to 35 do
    usableCharacters := usableCharacters + IfThenV(n<=9, Char(n + Ord('0')), Char(n - 10 + Ord('A')));
  // Remove all unused characters from the above digits string
  n := 1;
  while (n <= Length(unusedChars)) do
  begin
    usableCharacters := SearchAndReplace(usableCharacters, unusedChars[n], '');
    Inc(n);
  end;
  // Do the calculation
  multiplier := 1;
  for n := Length(theValue) downto 1 do
  begin
    digitValue := (Pos(theValue[n], usableCharacters) - 1);
    if (digitValue > 0) then
    begin
      result := result + multiplier * UInt8(digitValue)
    end // if
    else
    begin
      raise EMathError.Create('Invalid digit');
    end;
    multiplier := multiplier * base;
  end;
end; // Base2Dec

//***************************************************************************
//
//  FUNCTION  : SwapEndianHex
//
//  I/P       : hex : String - a string containing one or more pairs of hex
//                characters.
//
//  O/P       : String - The hex pairs, arranged in the opposite order.
//
//  OPERATION : Swaps the "endian-ness" of a given hex string by reversing
//              the byte order.
//
//              If the string does not contain an even number of characters,
//              no action is taken
//
//  UPDATED   : 2020-01-23
//
//***************************************************************************
function SwapEndianHex(hex : String) : String;
var
  n : Integer;

begin
  if (Length(hex) mod 2 <> 0) then
  begin
    Result := hex;
    Exit;
  end; // if

  Result := '';
  n := 2;
  while (n <= Length(hex)) do
  begin
    Result := Result + Copy(hex, Length(hex) - n + 1, 2);
    Inc(n, 2);
  end;
end; // SwapEndianHex

//***************************************************************************
//
//  FUNCTION  : SwapEndian
//
//  I/P       : theValue : Word - The value to be swapped
//
//  O/P       : Word - The high and low byte values are swapped
//
//  OPERATION : Swap the "Endianness" of a given 2-byte value
//
//  UPDATED   : 2023-03-24
//
//***************************************************************************
function SwapEndian(theValue : Word) : Word;
begin
  result := (theValue shr 8) +
            (theValue and $FF) shl 8;
end; // SwapEndian

//***************************************************************************
//
//  FUNCTION  : SetDecimalSeparatorAsPoint
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Store current decimal separator, and set it to '.'
//
//  UPDATED   : 2020-06-13
//
//***************************************************************************
procedure SetDecimalSeparatorAsPoint;
begin
  currentDecimalSeaprator := FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator := '.';
end; // SetDecimalSeparatorAsPoint

//***************************************************************************
//
//  FUNCTION  : RestoreDecimalSeparator
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Restore the previously-saved decimal separator.
//
//  UPDATED   : 2020-06-13
//
//***************************************************************************
procedure RestoreDecimalSeparator;
begin
  FormatSettings.DecimalSeparator := currentDecimalSeaprator;
end; // RestoreDecimalSeparator

//***************************************************************************
//
//  FUNCTION  : IsNumberInArray
//
//  I/P       : const ANumber: Integer - The number being searched for.
//
//              const AArray: array of Integer - The array of possible numbers.
//
//  O/P       : Boolean - True if the given number is the given array
//
//  OPERATION : Check if a given integer is in a given array of integer.
//
//  UPDATED   :
//
//***************************************************************************
function IsNumberInArray(const ANumber: Integer;
                         const AArray: array of Integer): Boolean;
var
  i: Integer;

begin
  for i := Low(AArray) to High(AArray) do
  begin
    if (ANumber = AArray[i]) then
    begin
      Exit(True);
    end;
  end;
  Result := False;
end; // IsNumberInArray

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
  // Get the regional formats correct
  // see https://forums.embarcadero.com/thread.jspa?threadID=47770
  SetThreadLocale(LOCALE_USER_DEFAULT);
  GetFormatSettings;

  currentDecimalSeaprator := FormatSettings.DecimalSeparator;


end.
