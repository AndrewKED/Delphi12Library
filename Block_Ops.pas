unit Block_Ops;
//***************************************************************************
//
//  Various functions that deal with TBytes
//
//***************************************************************************

interface

uses
  System.SysUtils, System.Types;

const
  BLK_CONV_NULL = -2; // Used for conversions, up till the first null byte/character
  BLK_CONV_SIZE = -1;            // Used for conversions of the full size of the input

function AnsiString2TBytes(theAnsiString : AnsiString;
                           nullTerminate : Boolean = FALSE) : TBytes;
function TBytes2AnsiString(ipBytes : TBytes;
                           numBytes : Integer = -1;
                           offset : Integer = 0) : AnsiString;
function TBytes02AnsiString(ipBytes : TBytes;
                            maxBytes : Integer = -1;
                            offset : Integer = 0) : AnsiString;
function TBytes0ToAnsiString(ipBytes : TBytes;
                             offset : Integer = 0;
                             numBytes : Integer = -1): AnsiString;
function AByte0ToAnsiString(ipBytes : array of Byte;
                            offset : Integer = 0): AnsiString;
function ABytes0ToTBytes(ipBytes : array of Byte) : TBytes;
function ABytesToTBytes(ipBytes : array of Byte;
                        length : Integer) : TBytes;
function StringToTBytes0(str: String;
                         requiredLen : Integer = 0): TBytes;
procedure StringToAByte0(str: String;
                         var buffer : array of Byte);
function ReadTBytesToAnsiString(ipBytes : TBytes;
                                var idx : Integer;
                                terminateOn : AnsiChar;
                                skip : AnsiChar;
                                var target : AnsiString) : Boolean;
function HexString2TBytes(theHexString : String) : TBytes;
function TBytes2HexString(ipBytes : TBytes;
                          squareBrackets : Boolean = FALSE;
                          separator : String = '') : String;
function AByteToHexString(ipBytes : array of Byte;
                          numBytes : Integer = BLK_CONV_SIZE;
                          squareBrackets : Boolean = FALSE;
                          separator : String = '') : String;
procedure InsertValue(value : Byte;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
procedure InsertValue(value : WORD;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
procedure InsertValue(value : DWORD;
                      var blockDestn : TBytes;
                      offset : Integer;
                      size : Integer = SizeOf(DWORD)); overload;
procedure InsertValue(value : Int16;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
procedure InsertValue(value : Int32;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
procedure InsertValue(value : Single;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
procedure SetBytes(value : Byte;
                   offset : Integer;
                   count : Integer;
                   var blockDestn : TBytes);
procedure DeleteBytes(offset : Integer;
                      count : Integer;
                      var blockDestn : TBytes);
function MakeATBytesCopy(const blockSource : TBytes;
                         const offsetStart : Integer = 0;
                         copyLength : Integer = -1) : TBytes;
procedure CopyBytes(const blockSource : TBytes;
                    var blockDestn : TBytes;
                    const offsetDestn : Integer = 0;
                    const offsetSource : Integer = 0;
                    copyLength : Integer = -1);
procedure AppendValue(value : Byte;
                      var blockDestn : TBytes); overload;
procedure AppendValue(value : WORD;
                      var blockDestn : TBytes); overload;
procedure AppendValue(value : DWORD;
                      var blockDestn : TBytes); overload;
procedure AppendValue(value : Int32;
                      var blockDestn : TBytes); overload;
procedure AppendValue(value : Single;
                      var blockDestn : TBytes); overload;
procedure AppendBytes(const blockAdd : TBytes;
                      var blockDestn : TBytes);
function JoinedBytes(const block1 : TBytes;
                     const block2 : TBytes) : TBytes;
procedure PadBytes(value : Byte;
                   count : Integer;
                   var blockDestn : TBytes);
procedure RandomBytes(var block : TBytes;
                      lengthSet : Integer;
                      offsetSet : Integer = 0;
                      range : Integer = 256);
procedure SaveBytesToFile(const Data: TBytes;
                          const FileName: string);
function OffsetInBytes(const findBytes : TBytes;
                       const inBytes : TBytes;
                       const idxStart : Integer = 0) : Integer;
function BlockSum(const blockSource : TBytes;
                  const mask : Byte = $FF) : Cardinal;

implementation

uses
  System.Classes, System.Math, System.AnsiStrings, System.StrUtils,
  Str_Ops;

//***************************************************************************
//
//  FUNCTION  : AnsiString2TBytes
//
//  I/P       : theAnsiString : AnsiString - The AnsiString to convert
//
//              nullTerminate : Boolean = FALSE - TRUE to null-terminate
//
//  O/P       : TBytes
//
//  OPERATION : Given an AnsiString, return the TBytes byte array.
//
//              Optionally add a terminating null character
//
//  UPDATED   : 2021-08-04
//
// *** WARNING *** Depending on the character set, characters can be one or more
// bytes. See System.AnsiString
//
//***************************************************************************
function AnsiString2TBytes(theAnsiString : AnsiString;
                           nullTerminate : Boolean = FALSE) : TBytes;
begin
// Copilot suggested replacing this with the followng:
//  Result := TEncoding.ANSI.GetBytes(theAnsiString);
//  if nullTerminate then
//    Result := Result + [0];

  if (nullTerminate) then
  begin
    SetLength(Result, Length(theAnsiString) + 1);
  end // if
  else
  begin
    SetLength(Result, Length(theAnsiString));
  end;

  Move(Pointer(theAnsiString)^, Pointer(Result)^, Length(theAnsiString));

  if (nullTerminate) then
  begin
    Result[Length(Result)-1] := 0;
  end // if
end; // AnsiString2TBytes

//***************************************************************************
//
//  FUNCTION  : TBytes2AnsiString
//
//  I/P       : ipBytes : TBytes - The TBytes to be converted.
//
//              numBytes : Integer = -1 - The number of bytes to be converted.
//                Default to all bytes.
//
//              offset : Integer = 0 - The index from which the bytes are to
//                be converted.
//
//  O/P       :
//
//  OPERATION : Given a TBytes, return the AnsiString of its contents
//
//  UPDATED   : 2021-03-01
//
//***************************************************************************
function TBytes2AnsiString(ipBytes : TBytes;
                           numBytes : Integer = -1;
                           offset : Integer = 0) : AnsiString;
begin
  if (numBytes = -1) then
  begin
    numBytes := Length(ipBytes) - offset;
  end;
  Result := System.AnsiStrings.DupeString(AnsiChar(#0), numBytes);
  Move(Pointer(@ipBytes[offset])^, Pointer(Result)^, numBytes);
end; // TBytes2AnsiString

//***************************************************************************
//
//  FUNCTION  : TBytes02AnsiString
//
//  I/P       : ipBytes : TBytes - The TBytes to be converted.
//
//              maxBytes : Integer = -1 - The maximum number of bytes to be
//                converted. Default to all bytes.
//
//              offset : Integer = 0 - The index from which the bytes are to
//                be converted.
//
//  O/P       :
//
//  OPERATION : Given a TBytes containing a null-terminated string, return
//              the AnsiString of its contents.
//
//  UPDATED   : 2021-08-04
//
//***************************************************************************
function TBytes02AnsiString(ipBytes : TBytes;
                            maxBytes : Integer = -1;
                            offset : Integer = 0) : AnsiString;
var
  n : Integer;

begin
  if (maxBytes = -1) then
  begin
    maxBytes := Length(ipBytes) - offset;
  end;

  Result := System.AnsiStrings.DupeString(AnsiChar(#0), maxBytes);
  n := 1;
  while ((ipBytes[offset] <> 0) and
         (n <= maxBytes)) do
  begin
    Result[n] := AnsiChar(ipBytes[offset]);
    Inc(offset);
    Inc(n);
  end;

  if (n <= maxBytes) then
  begin
    SetLength(Result, n-1);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : TBytes0ToAnsiString
//
//  I/P       : ipBytes : TBytes - The TBytes to be converted.
//
//              offset : Integer = 0 - The index from which the bytes are to
//                be converted.
//
//              numBytes : Integer = -1 - The number of bytes to be converted.
//                Default to all bytes.
//
//  O/P       : AnsiString
//
//  OPERATION : Given a TBytes containing a null-terminated string, return
//              the AnsiString of its contents.
//
//  UPDATED   : 2021-09-17
//
//***************************************************************************
function TBytes0ToAnsiString(ipBytes : TBytes;
                             offset : Integer = 0;
                             numBytes : Integer = -1): AnsiString;
var
  byteCopy: TBytes;
  i: integer;

begin
  i := 0;

  if (numBytes = -1) then
  begin
    numBytes := Length(ipBytes);
  end; // if

  SetLength(byteCopy, numBytes+1);

  while (numBytes > 0) do
  begin
    byteCopy[i] := ipBytes[offset + i];

    i := i + 1;
    Dec(numBytes);
  end;

  byteCopy[i] := 0;
  Result := PAnsiChar(@byteCopy[0]);
end; // TBytes0ToAnsiString

function AByte0ToAnsiString(ipBytes : array of Byte;
                            offset : Integer = 0): AnsiString;
begin
  Result := PAnsiChar(@ipBytes[offset]);
end;

//***************************************************************************
//
//  FUNCTION  : ABytes0ToTBytes
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
function ABytes0ToTBytes(ipBytes : array of Byte) : TBytes;
var
  count : Integer;

begin
  count := Length(ipBytes);
  SetLength(Result, Count);
  if (Count > 0) then
  begin
    Move(ipBytes[0], Result[0], Count);
  end;
end; // ABytes0ToTBytes

//***************************************************************************
//
//  FUNCTION  : ABytesToTBytes
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
function ABytesToTBytes(ipBytes : array of Byte;
                        length : Integer) : TBytes;
begin
  SetLength(Result, length);
  if (length > 0) then
  begin
    Move(ipBytes[0], Result[0], length);
  end;
end; // ABytesToTBytes

//***************************************************************************
//
//  FUNCTION  : StringToTBytes0
//
//  I/P       : str : String - The string to be converted
//
//              requiredLen : Integer = 0. The required length of the output.
//
//  O/P       : TBytes
//
//  OPERATION : Return a TBytes representation of a string.
//
//              A null byte will be appended to the end of the string bytes.
//
//  UPDATED   : 2021-09-17
//
//***************************************************************************
function StringToTBytes0(str: String;
                         requiredLen : Integer = 0): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(str+#0);
  if (requiredLen <> 0) then
  begin
    SetLength(Result, requiredLen);
  end;
end; // StringToTBytes0

procedure StringToAByte0(str: String;
                         var buffer : array of Byte);
var
  temp : TBytes;
begin
  temp := TEncoding.UTF8.GetBytes(str+#0);
  Move(Pointer(@temp[0])^, Pointer(@buffer[0])^, Length(temp));
end;

//***************************************************************************
//
//  FUNCTION  : ReadTBytesToAnsiString
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Reads a
//
//  UPDATED   :
//
//***************************************************************************
function ReadTBytesToAnsiString(ipBytes : TBytes;
                                var idx : Integer;
                                terminateOn : AnsiChar;
                                skip : AnsiChar;
                                var target : AnsiString) : Boolean;
begin
  result := FALSE;
  while (idx < Length(ipBytes)) do
  begin
    if (ipBytes[idx] = Ord(terminateOn)) then
    begin
      Inc(idx);
      result := TRUE;
      Break;
    end;

    if (ipBytes[idx] <> Ord(skip)) then
    begin
      target := target + AnsiChar(ipBytes[idx]);
    end;
    Inc(idx);
  end; // while
end; // ReadTBytesToAnsiString

//***************************************************************************
//
//  FUNCTION  : HexString2TBytes
//
//  I/P       : theHexString : String - The input string of hexasedicmal
//                character pairs, representing bytes.
//
//  O/P       : TBytes - The converted bytes, the length of which is half of
//                the input string length. Length = 0 if an error.
//
//  OPERATION : Converts a given string of hexadecimal characters, representing
//              bytes, into the equivalent TBytes object. If there are any
//              errors in the conversion, the resultant TBytes object will have
//              zero length
//
//  UPDATED   : 2020-04-06
//
//***************************************************************************
function HexString2TBytes(theHexString : String) : TBytes;
var
  n, m : Integer;
  hexByte : String;

begin
  if (Length(theHexString) mod 2 <> 0) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Result, Length(theHexString) div 2);
  n := 1;
  m := 0;
  while (n < Length(theHexString)) do
  begin
    hexByte := Copy(theHexString, n, 2);
    if (not IsAHexadecimal(hexByte)) then
    begin
      SetLength(Result, 0);
      Exit;
    end; // if

    Result[m] := StrToInt('$' + hexByte);
    Inc(n, 2);
    Inc(m);
  end; // while
end; // HexString2TBytes

//***************************************************************************
//
//  OPERATION : Convert a given TBytes object into the equivalent string of
//              upper-case hexadecimal character pairs.
//
//  I/P       : ipBytes: TBytes - The bytes to be converted into a hex string
//
//              squareBrackets : Boolean = FALSE - Encase each byte in square
//                breackets.
//
//              separator : String = '' - Separator between hexadecimal pairs
//
//  O/P       : String - The resultant string of upper-case hexasedicmal pairs.
//
//***************************************************************************
function TBytes2HexString(ipBytes : TBytes;
                          squareBrackets : Boolean = FALSE;
                          separator : String = '') : String;
var
  n : Integer;

begin
  Result := '';
  n := 0;
  while (n < Length(ipBytes)) do
  begin
    Result := Result +
              ifthen(squareBrackets, '[', '') +
              IntToHex(ipBytes[n]) +
              ifthen(squareBrackets, ']', '') +
              separator;
    Inc(n);
  end; // while

  // Trim off the trailing separator
  if (Result <> '') then
  begin
    Result := Copy(Result, 1, Length(Result) - Length(separator));
  end;
end; // TBytes2HexString

//***************************************************************************
//
//  FUNCTION  : AByteToHexString
//
//  I/P       : ipBytes: array of Bytes - The bytes to be converted into a
//                hex string.
//
//              numBytes : Integer = BLK_CONV_SIZE - Specifies the
//                number of bytes to be converted.
//                BLK_CONV_SIZE will convert the full input array,
//                BLK_CONV_NULL will convert until the first null byte
//                Any other value will convert the specified length.
//
//              squareBrackets : Boolean = FALSE - Encase each byte in square
//                breackets.
//
//              separator : String = '' - Separator between hexadecimal pairs
//
//  O/P       : String - The resultant string of upper-case hexasedicmal pairs.
//
//  OPERATION : Converts a given array of bytes into the equivalent string of
//                upper-case hexadecimal character pairs.
//
//              Length specification may select all, up till null, or a segment.
//
//  UPDATED   : 2021-09-28
//
//***************************************************************************
function AByteToHexString(ipBytes : array of Byte;
                          numBytes : Integer = BLK_CONV_SIZE;
                          squareBrackets : Boolean = FALSE;
                          separator : String = '') : String;
var
  n : Integer;

begin
  Result := '';
  n := 0;
  while (((numBytes = BLK_CONV_SIZE) and (n < Length(ipBytes))) or
         ((numBytes = BLK_CONV_NULL) and (n < Length(ipBytes)) and (ipBytes[n] <> 0)) or
         ((numBytes <> BLK_CONV_SIZE) and (numBytes <> BLK_CONV_NULL) and (n < numBytes))) do
  begin
    Result := Result +
              ifthen(squareBrackets, '[', '') +
              IntToHex(ipBytes[n]) +
              ifthen(squareBrackets, ']', '') +
              separator;
    Inc(n);
  end; // while

  // Trim off the trailing separator
  if (Result <> '') then
  begin
    Result := Copy(Result, 1, Length(Result) - Length(separator));
  end;
end; // AByteToHexString

//***************************************************************************
//
//  FUNCTION  : InsertValue
//
//  I/P       : value : Whatever structure/variable is to be inserted
//
//              var blockDestn : TBytes - Target TBytes
//
//              offset : Integer - Where in TBytes it must be inserted.
//
//              size : Integer - The number of bytes to write (because only
//                3 bytes out of a DWORD has been encountered(!))
//
//  O/P       : var paraneter/s
//
//  OPERATION : Insert the given value, in the form of bytes, at the given
//              offset into the TBytes
//
//              Note to future self : Make this routine more universal, with value
//              being some sort of Variant.
//
//  UPDATED   : 2019-10-01
//
//***************************************************************************
procedure InsertValue(value : Byte;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
begin
  if (offset + SizeOf(value) < Length(blockDestn)) then
  begin
    Move(value, blockDestn[offset], SizeOf(value));
  end;
end;
procedure InsertValue(value : WORD;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
begin
  if (offset + SizeOf(value) < Length(blockDestn)) then
  begin
    Move(value, blockDestn[offset], SizeOf(value));
  end;
end;
procedure InsertValue(value : DWORD;
                      var blockDestn : TBytes;
                      offset : Integer;
                      size : Integer = SizeOf(DWORD)); overload;
begin
  if (offset + size < Length(blockDestn)) then
  begin
    Move(value, blockDestn[offset], size);
  end;
end;
procedure InsertValue(value : DWORD;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
begin
  if (offset + SizeOf(value) < Length(blockDestn)) then
  begin
    Move(value, blockDestn[offset], SizeOf(value));
  end;
end;
procedure InsertValue(value : Int32;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
begin
  if (offset + SizeOf(value) < Length(blockDestn)) then
  begin
    Move(value, blockDestn[offset], sizeof(value));
  end;
end;
procedure InsertValue(value : Int16;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
begin
  if (offset + SizeOf(value) < Length(blockDestn)) then
  begin
    Move(value, blockDestn[offset], sizeof(value));
  end;
end;
procedure InsertValue(value : Single;
                      var blockDestn : TBytes;
                      offset : Integer); overload;
begin
  if (offset + SizeOf(value) < Length(blockDestn)) then
  begin
    Move(value, blockDestn[offset], sizeof(value));
  end;
end;

//***************************************************************************
//
//  FUNCTION  : SetBytes
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Sets a block of bytes to the given value
//
//  UPDATED   : 2019-08-22
//
//***************************************************************************
procedure SetBytes(value : Byte;
                   offset : Integer;
                   count : Integer;
                   var blockDestn : TBytes);
var
  n : Integer;

begin
  n := offset;
  while (n <= offset + count - 1) do
  begin
    blockDestn[n] := value;
    Inc(n);
  end; // for
end; // SetBytes

//***************************************************************************
//
//  FUNCTION  : DeleteBytes
//
//  I/P       : offset : Integer - The offset from which bytes are to be removed
//
//              count : Integer - The number of bytes to be removed
//
//              var blockDestn : TBytes - The TBytes to be modified
//
//  O/P       : None
//
//  OPERATION : Removes the indicated bytes from the TBytes
//
//  UPDATED   : 2021-01-27
//
//***************************************************************************
procedure DeleteBytes(offset : Integer;
                      count : Integer;
                      var blockDestn : TBytes);
begin
  if ((offset >= Length(blockDestn)) or
      (count <= 0)) then
  begin
    Exit;
  end; // if

  if (offset + count > Length(blockDestn)) then
  begin
    count := Length(blockDestn) - offset;
  end; // if

  Move(blockDestn[offset + Count], blockDestn[offset], Length(blockDestn) - offset - Count);
  SetLength(blockDestn, Length(blockDestn) - Count);
end; // DeleteBytes

//***************************************************************************
//
//  FUNCTION  : MakeATBytesCopy
//
//  I/P       : const blockSource : TBytes - The data to be copied.
//
//              const offsetStart : Integer = 0 - The index from which copying
//                of the source data is to start.
//
//              const copyLength : Integer = -1) : TBytes - The number of bytes
//                to be copied. If default, copy from offsetStart to the end
//                of the source data.
//
//  O/P       : TBytes - The copy of the given data.
//
//  OPERATION : Copies all, or a portion, of a given TBytes into a new TBytes.
//
//              The source offset and number of bytes to copy may be set.
//
//              This routine used to be called CopyBytes.
//
//  UPDATED   : 2020-12-30
//
//***************************************************************************
function MakeATBytesCopy(const blockSource : TBytes;
                         const offsetStart : Integer = 0;
                         copyLength : Integer = -1) : TBytes;
begin
  if (copyLength = -1) then
  begin
    copyLength := Max(Length(blockSource) - offsetStart, 0);
  end;

  SetLength(Result, copyLength);
  Move(blockSource[offsetStart], Result[0], copyLength);
end; // MakeATBytesCopy

//***************************************************************************
//
//  FUNCTION  : CopyBytes
//
//  I/P       : const blockSource : TBytes - The data to be copied.
//
//              const offsetDestn : Integer = 0 - The index at which the source
//                data will be inserted into the desgination data
//
//              const offsetSource : Integer = 0 - The index from which copying
//                of the source data is to start.
//
//              const copyLength : Integer = -1) : TBytes - The number of bytes
//                to be copied. If default, copy from offsetStart to the end
//                of the source data.
//
//  O/P       : var blockDestn : TBytes - The copy of the given data.
//
//  OPERATION : Copies all, or a portion, of a given TBytes to an offset in an
//              existing TBytes.
//
//              The destination offset, source offset and number of bytes to
//              be copied may be optionally set.
//
//              The destination TBytes is expanded in length, if necessary.
//
//  UPDATED   : 2020-12-30
//
//***************************************************************************
procedure CopyBytes(const blockSource : TBytes;
                    var blockDestn : TBytes;
                    const offsetDestn : Integer = 0;
                    const offsetSource : Integer = 0;
                    copyLength : Integer = -1);
begin
  if (copyLength = -1) then
  begin
    copyLength := Max(Length(blockSource) - offsetSource, 0);
  end;

  if (Length(blockDestn) < offsetDestn + copyLength) then
  begin
    SetLength(blockDestn, offsetDestn + copyLength);
  end;
  Move(blockSource[offsetSource], blockDestn[offsetDestn], copyLength);
end; // CopyBytes

//***************************************************************************
//
//  FUNCTION  : Append
//
//  I/P       : value : Whatever structure/variable is to be appended
//
//              var blockDestn : TBytes - Target TBytes
//
//  O/P       : var parameter/s
//
//  OPERATION : Add the given value, in the form of bytes, to the end of the
//              TBytes.
//
//              Note to future self : Make this routine more universal, with value
//              being some sort of Variant
//
//  UPDATED   : 2021-01-27
//
//***************************************************************************
procedure AppendValue(value : Byte;
                      var blockDestn : TBytes); overload;
begin
  SetLength(blockDestn, Length(blockDestn) + SizeOf(value));
  Move(value, blockDestn[Length(blockDestn) - SizeOf(value)], sizeof(value));
end;
procedure AppendValue(value : Word;
                      var blockDestn : TBytes); overload;
begin
  SetLength(blockDestn, Length(blockDestn) + SizeOf(value));
  Move(value, blockDestn[Length(blockDestn) - SizeOf(value)], sizeof(value));
end;
procedure AppendValue(value : DWord;
                      var blockDestn : TBytes); overload;
begin
  SetLength(blockDestn, Length(blockDestn) + SizeOf(value));
  Move(value, blockDestn[Length(blockDestn) - SizeOf(value)], sizeof(value));
end;
procedure AppendValue(value : Int32;
                      var blockDestn : TBytes); overload;
begin
  SetLength(blockDestn, Length(blockDestn) + SizeOf(value));
  Move(value, blockDestn[Length(blockDestn) - SizeOf(value)], sizeof(value));
end;
procedure AppendValue(value : Single;
                      var blockDestn : TBytes); overload;
begin
  SetLength(blockDestn, Length(blockDestn) + SizeOf(value));
  Move(value, blockDestn[Length(blockDestn) - SizeOf(value)], sizeof(value));
end;

//***************************************************************************
//
//  FUNCTION  : AppendBytes
//
//  I/P       : blockAdd : TBytes - The data to be added to the end.
//
//  O/P       : var blockDestn : TBytes - The original TBytes, with the given
//                TBytes now added to the end.
//
//  OPERATION : Appends a given TBytes to the end of another TBytes
//
//  UPDATED   : 2019-08-22
//
//***************************************************************************
procedure AppendBytes(const blockAdd : TBytes;
                      var blockDestn : TBytes);
var
  origLength : Integer;

begin
  if (Length(blockAdd) > 0) then
  begin
    origLength := Length(blockDestn);
    SetLength(blockDestn, origLength + Length(blockAdd));
    Move(blockAdd[0], blockDestn[origLength], Length(blockAdd));
  end; // if
end; // AppendBytes

//***************************************************************************
//
//  FUNCTION  : JoinedBytes
//
//  I/P       : const block1 : TBytes - The first TBytes
//
//              const block2 : TBytes - The second TBytes
//
//  O/P       : TBytes - Merged
//
//  OPERATION : Merge two given TBytes into one
//
//  UPDATED   : 2024-03-26
//
//***************************************************************************
function JoinedBytes(const block1 : TBytes;
                     const block2 : TBytes) : TBytes;
begin
  SetLength(Result, Length(block1) + Length(block2));
  Move(block1[0], Result[0], Length(block1));
  Move(block2[0], Result[Length(block1)], Length(block2));
end;

//***************************************************************************
//
//  FUNCTION  : PadBytes
//
//  I/P       : value : Byte - The value to be used in the padding
//
//              count : Integer - The size of the padding
//
//  O/P       : var blockDestn : TBytes - The original TBytes, with the given
//                padding now added to the end.
//
//  OPERATION : Appends a block of byte values to the end of a given TBytes
//
//  UPDATED   : 2019-08-22
//
//***************************************************************************
procedure PadBytes(value : Byte;
                   count : Integer;
                   var blockDestn : TBytes);
var
  origLength : Integer;

begin
  origLength := Length(blockDestn);
  SetLength(blockDestn, origLength + count);
  SetBytes(value, origLength, count, blockDestn);
end; // PadBytes

//***************************************************************************
//
//  FUNCTION  : RandomBytes
//
//  I/P       : block : TBytes - The TBytes to be filled
//
//              lengthSet : Integer - The size to set TBytes
//
//              offsetSet : Integer - Optional offset into bytes
//                (default 0)
//
//              range : Integer - Optional range [0..range-1] of the fill values
//                (default 256)
//
//  O/P       : block : TBytes - Length set and filled with random values.
//
//  OPERATION : Create a block of random bytes in a given TBytes.
//              If necessary (i.e. the destination TBytes is not already long
//              enough), the length is set.
//
//  UPDATED   : 2019-08-16
//
//***************************************************************************
procedure RandomBytes(var block : TBytes;
                      lengthSet : Integer;
                      offsetSet : Integer = 0;
                      range : Integer = 256);
var
  n : Integer;

begin
  if (Length(block) < lengthSet + offsetSet) then
    SetLength(block, lengthSet + offsetSet);
  for n := 0 to lengthSet-1 do
    block[n + offsetSet] := Random(range);
end; // RandomBytes

//***************************************************************************
//
//  FUNCTION  : SaveBytesToFile
//
//  I/P       : Data: TBytes - The block to be writted
//
//              FileName: string - Full output filename
//
//  O/P       : None
//
//  OPERATION : Writes the given data to a named file
//
//  UPDATED   : 2018-12-01
//
//***************************************************************************
procedure SaveBytesToFile(const Data: TBytes;
                          const FileName: string);
var
  Stream: TFileStream;

begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if (Data <> nil) then
      Stream.WriteBuffer(Data[0], Length(Data));
  finally
    Stream.Free;
  end; // finally
end; // SaveBytesToFile

//***************************************************************************
//
//  FUNCTION  : OffsetInBytes
//
//  I/P       : findBytes : TBytes - The block of data to be found.
//
//              inBytes : TBytes - The data to be searched.
//
//              idxStart : Integer = 0 - The offset from which the search is to
//                be carried out.
//
//  O/P       : Integer - The offset of the given data block. -1 if not found.
//
//  OPERATION : Find the offset of a given data block within another
//
//  UPDATED   : 2021-01-27
//
//***************************************************************************
function OffsetInBytes(const findBytes : TBytes;
                       const inBytes : TBytes;
                       const idxStart : Integer = 0) : Integer;
var
  n, m : Integer;

begin
  Result := -1;

  // Don't do anything if the search and search-in TBytes are empty
  if ((Length(findBytes) = 0) or
      (Length(inBytes) - Length(findBytes) < idxStart)) then
  begin
    Exit;
  end; // if

  n := idxStart;
  m := 0;
  // Look through search data, until it could no longer hold the data that is
  // being sought.
  while (n <= Length(inBytes) - Length(findBytes)) do
  begin
    while ((inBytes[n+m] = findBytes[m]) and
           (m < Length(findBytes))) do
    begin
      Inc(m);
      if (m >= Length(findBytes)) then
      begin
        Result := n;
        Exit;
      end;
    end;
    m := 0;
    Inc(n);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : BlockSum
//
//  I/P       : const blockSource : TBytes - The array to be summed.
//
//              const mask : Byte = $FF - The optional mask to apply to each byte
//
//  O/P       : Cardinal - The resulting sum.
//
//  OPERATION : Sum the byte values in a TBytes, with optional value masking.
//
//  UPDATED   : 2021-03-18
//
//***************************************************************************
function BlockSum(const blockSource : TBytes;
                  const mask : Byte = $FF) : Cardinal;
var
  n : Integer;

begin
  Result := 0;
  n := 0;
  while (n < Length(blockSource)) do
  begin
    Inc(Result, blockSource[n] and mask);
    Inc(n);
  end;
end; // BlockSum


end.
