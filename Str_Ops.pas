unit Str_Ops;

//***************************************************************************
//
// DESCRIPTION:
//  Provides a number of helpful string handling functions and procedures.
//
// TO BE DONE:
//
//  *
//
//***************************************************************************

interface

uses Classes, Sysutils;

const
  CRLF = #$D#$A;

function Centre_Line (main : String; ch : Char; field : integer) : String;
procedure RemoveLagging(var main : String; sRemove : string);
function RemoveLaggingCRLF(main : string) : String;
function End_Trimmed(main : String; sRemove : string) : String;
procedure RemoveLeading(var main : String; sRemove : string); overload;
procedure RemoveLeading(var main : AnsiString; sRemove : AnsiString); overload;
function Front_Trimmed(main : String; sRemove : string) : String;
procedure Pad_End(var main; ch : Char; field : integer);
function End_Padded(main : String; ch : Char; field : integer) : String;
procedure Pad_Front(var main; ch : Char; field : integer);
function Front_Padded (main : String;
                       ch : Char;
                       field : integer) : String;
function Leading_Zeroes(num : Word; field : integer) : String;
//NB BytesToAnsiStr replaces the earlier, faulty Bytes_To_AnsiStr
function BytesToAnsiStr (ip_array : array of Byte;
                         offset : Integer;
                         count : integer) : AnsiString;
function Count_Chars(main : String; ch : Char) : Integer;
function TrimToFirst (sMain : String; sFind : string) : String;
function TrimFromFirst (sMain : String; sFind : string) : String;
function RemoveBeforeLast(sMain : String; cGiven : Char) : String;
function RemoveFromLast (orig : String; trimFrom : String) : String;
function ANSStrToBool(sLine : string) : boolean;
function Str2ASCIIHex(sInput : String;
                      ucBlockSize : byte = 0) : String; overload;
function Str2ASCIIHex(sInput : AnsiString;
                      ucBlockSize : byte = 0) : String; overload;
function Hex2Str(Hex : string) : AnsiString;
function GroupSplitString(original : String;
                          separator : String;
                          sizeGroup : Integer = 2) : String;
function String2Longint(sInput : String;
                        var liOutput : longint) : boolean;
function ExtractAndTrim (var sInput : String; sSeparator : string) : String; overload;
function ExtractAndTrim (var sInput : AnsiString; sSeparator : AnsiString) : AnsiString; overload;
function ExtractAndTrimQ (var sInput : String; sSeparator : string) : String; overload;
function ExtractAndTrimQ (var sInput : AnsiString; sSeparator : AnsiString) : AnsiString; overload;
function Strip_Front(sMain : String; cRemove : Char) : String;
function ExtractAndTrimTo(var sInput : String; uiLength : word) : String; overload;
function ExtractAndTrimTo(var sInput : AnsiString; uiLength : word) : AnsiString; overload;
function Boolean2Str(bTest : boolean) : String;
function SearchAndReplace(sMain : String; sFind : String; sReplace : string) : String; overload;
function SearchAndReplace(sMain : AnsiString; sFind : AnsiString; sReplace : AnsiString) : AnsiString; overload;
function ExtractFrontMatching (sInput : String; stMatch : TSysCharSet) : String;
function Str2Debug(sLine : AnsiString;
                   bAllNumerical : boolean;
                   bHex : boolean;
                   bSquareBrackets : boolean;
                   cSeparator : Char) : String;
function DP(dtDate : TDateTime) : String;
procedure StuffString(sNew : String;
                      var sOriginal : String;
                      iOffset : integer);
procedure RemoveDuplicates(var sMain : String; cChar : Char);
procedure RemoveMarkedSections(var original : String;
                               markStart : String;
                               markEnd : String);
function SuppressMiddle(sMain :string;
                        iAvailableSpace :integer): string;
function SuppressEnd(sMain : String;
                     iAvailableSpace : Integer) : String;
function YesNo(sInput : String;
               bUpperCase : boolean) : String; overload;
function YesNo(bState : boolean;
               bUpperCase : boolean = FALSE) : String; overload;
function IfThenS(state : boolean;
                 sTrue : String; sFalse : String = '') : String;
function RemapString(given : AnsiString;
                     origSet : AnsiString;
                     remapSet : AnsiString) : AnsiChar;
procedure InitialiseString (var sMain : string);
function GetNthChar(sIP : String;
                    iOffset : integer) : Char;
function Readable(sIP : string) : boolean;
function MatchingChars(s1 : AnsiString;
                       s2 : AnsiString) : Integer;
function IsAnInteger(sNumber : string) : boolean;
function IsAFloat(sNumber : string) : boolean;
function IsAlphaNumeric(sInput : string) : boolean;
function IsIP4Address(sInput : string) : boolean;
function IsAHexadecimal(sInput : String) : Boolean;
function IsADateTime(sInput : String) : Boolean;
function ForcedStrToFloat(sValue : String;
                          dInvalid : Extended) : Extended;
function InitialUpperCase(sInput : string) : String;
function AdditiveChecksum(sInput : AnsiString;
                          iSize : integer) : Integer; overload;
function AdditiveChecksum(sInput : array of AnsiChar;
                          iSize : integer) : Integer; overload;
function XORChecksum(sInput : AnsiString;
                     iSize : integer) : Integer; overload;
function XORChecksum(sInput : array of AnsiChar;
                     iSize : integer) : Integer; overload;
function GetLuhnModNCheckChar(sInput : AnsiString) : AnsiChar;
function ValidLuhnModNCheckChar(sInput : AnsiString) : boolean;
function ExtractCorSCSeparatedElement(var sInput : string) : String;
function ValidEmailAddress(sAddress : string) : boolean;
function ValidEmailAddresses(sAddress : string) : boolean;
function ValidPhoneNumber(phoneNumber : string) : boolean;
function GUIDDegrouping(guid : String) : String;
function GUID2Grouping(guid : String) : String;
function BreakText(theText : String;
                   breakString : String;
                   linesRequired : Integer) : String;
function JoinStrings(theStrings : array of String;
                     inBetween : String) : String;
function StringHasCharacters(const theString : AnsiString;
                             const theCharacters : TSysCharSet;
                             const only : Boolean) : Boolean; overload;
function StringHasCharacters(const theString : String;
                             const theCharacters : TArray<Char>;
                             const only : Boolean) : Boolean; overload;
function StringIncludes(const theString : AnsiString;
                        const needs_lower : Boolean;
                        const needs_upper : Boolean;
                        const needs_number : Boolean;
                        const needs_special : Boolean;
                        const special_set : TSysCharSet) : Boolean; overload;
function StringIncludes(const theString : String;
                        const needs_lower : Boolean;
                        const needs_upper : Boolean;
                        const needs_number : Boolean;
                        const needs_special : Boolean;
                        const special_set : TArray<Char>) : Boolean; overload;
function NoneSingleMultiple(items : Integer;
                            noneText : String;
                            oneText : String;
                            multipleText : String) : String;
function IsASCIIOnly(test : AnsiString;
                     printable : Boolean = FALSE) : Boolean;

// TStrings-associated functions
//------------------------------------------------------------------------------
procedure SortStrings(var sStrings : TStrings);         //!! Not strings!
function FindIndex(sFind : String;
                   bCaseSensitive : boolean;
                   sAvailable : TStrings) : Integer;    //!! Not strings!
procedure ParseDelimited(const sl : TStringList;
                         const sMain : String;
                         const sDelimiter : string);
procedure SortTStrings(theStrings : TStrings);
function TStrings2String(theStrings : TStrings;
                         separator : String) : String;
procedure RemoveEmptyFromTString(theStrings : TStrings);
function ConcatenateStrings(theStrings : TStrings;
                            separator : String = '';
                            quotes : String = '') : String;

//****************************************************************************

implementation

uses
  System.StrUtils, System.AnsiStrings, System.Character, System.Types,
  System.RegularExpressions,
  Math, DateUtils, TimeDate;

//****************************************************************************
//
//  DESCRIPTION
//  This function will add sufficient characters to the front of the given
//  string, until the given string is centred within the field.   It will then
//  continue to add further characters to the end of the field until the
//  overall length equals the given field.   If the string already exceeds the
//  given length, the string is returned as is.
//
//  PARAMETERS
//
//  main (string) : This is the string which should be padded out.
//  ch (Char)     : This is the character which should be added to the front
//                  of the given string, until it reaches the given length.
//  field : integer : This is the total length of the resultant string.
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  19 June 1997
//
//****************************************************************************
function Centre_Line (main : String; ch : Char; field : integer) : String;
begin
  Pad_Front (main,ch,(field-Length(main)) DIV 2 + Length(main));
  Pad_End (main,ch,field);
  Centre_Line := main;
end; //Centre_Line

//***************************************************************************
//
//  FUNCTION  : RemoveLagging
//
//  I/P       : main (string) -  This is the string which should be
//                trimmed of excess lagging characters.
//
//              sRemove (string) - These are the character/s which should be
//                removed from the end of the given string.
//
//  O/P       :
//
//  OPERATION : Remove from the end of the given string all excess occurances
//              of the given string.
//
//  UPDATED   : 2003/06/05
//
//***************************************************************************
procedure RemoveLagging (var main : String; sRemove : string);
begin
  if (sRemove <> '') then
    while (Copy(main,Length(main)-Length(sRemove)+1,Length(sRemove))= sRemove) do
      main := LeftStr(main,Length(main) - Length(sRemove));
end; // RemoveLagging

//***************************************************************************
//
//  FUNCTION  : RemoveLaggingCRLF
//
//  I/P       : main : String - The string to be modified.
//
//  O/P       : String - The given string, with all trailing CR and LF
//                characters removed.
//
//  OPERATION : Remove all trailing CR and LF characters from the given string.
//
//  UPDATED   : 2015-11-27
//
//***************************************************************************
function RemoveLaggingCRLF(main : string) : String;
begin
  while ((Length(main) > 0) and
         ((main[Length(main)] = #13) or
          (main[Length(main)] = #10))) do
  begin
    if (main[Length(main)] = #13) then
      RemoveLagging(main,#13);
    if ((Length(main) > 0) and
        (main[Length(main)] = #10)) then
      RemoveLagging(main,#10);
  end; // while
  result := main;
end;

//***************************************************************************
//
//  FUNCTION  : End_Trimmed
//
//  I/P       : main (string) - This is the string which should be trimmed of
//                excess characters.
//
//              sRemove (string) - These are the character/s which should be
//                removed from the end of the given string.
//
//  O/P       : (string)
//
//  OPERATION : Remove, from the end of a string all excess occurrances of
//              another string.
//
//  UPDATED   : 2007/03/14
//
//***************************************************************************
function End_Trimmed(main : String; sRemove : string) : String;
begin
  RemoveLagging(main,sRemove);
  result := main;
end; //End_Trimmed

//***************************************************************************
//
//  FUNCTION  : RemoveLeading
//
//  I/P       : main (string) -  This is the string which should be
//                        trimmed of excess leading characters.
//
//              sRemove (string) - These are the character/s which should be
//                removed from the front of the given string.
//
//  O/P       :
//
//  OPERATION : Remove from the front of the given string all excess occurances
//              of the given string.
//
//  UPDATED   : 2007/03/14
//
//***************************************************************************
procedure RemoveLeading (var main : String; sRemove : string); overload;
begin
  if (sRemove <> '') then
    while (LeftStr(main,Length(sRemove)) = sRemove) do
      main := Copy(main,Length(sRemove)+1,Length(main));
end; // RemoveLeading

//***************************************************************************
//
//  FUNCTION  : RemoveLeading
//
//  I/P       : main : AnsiString -  This is the string which should be
//                        trimmed of excess leading characters.
//
//              sRemove : AnsiString - These are the character/s which should be
//                removed from the front of the given string.
//
//  O/P       :
//
//  OPERATION : Remove from the front of the given string all excess occurances
//              of the given string.
//
//  UPDATED   : 2010-10-28
//
//***************************************************************************
procedure RemoveLeading (var main : AnsiString; sRemove : AnsiString); overload;
begin
  if (sRemove <> '') then
    while (System.AnsiStrings.LeftStr(main,Length(sRemove)) = sRemove) do
      main := Copy(main,Length(sRemove)+1,Length(main));
end; // RemoveLeading

//***************************************************************************
//
//  FUNCTION  : Front_Trimmed
//
//  I/P       : main (string) - This is the string which should be trimmed of
//                excess characters.
//
//              sRemove (string) - These are the character/s which should be
//                removed from the front of the given string.
//  O/P       :
//
//  OPERATION : This function will remove from the front of the given string
//              all excess occurrances of the given string.
//
//  UPDATED   : 2007/03/14
//
//***************************************************************************
function Front_Trimmed (main : String; sRemove : string) : String;
begin
  RemoveLeading(main,sRemove);
  result := main;
end; //Front_Trimmed

//****************************************************************************
//
//  DESCRIPTION
//  This procedure will add the given characters to the end of the given
//  string, until the length of that string equals a given length.   If the
//  string already exceeds the given length, the string is returned as is.
//
//  PARAMETERS
//
//  main (UNTYPED) : This is the string which should be padded out.
//  ch (CHAR)     : This is the character which should be added to the end of
//                  the given string, until it reaches the given length.
//  field (integer)  : This is the desired length of the string.
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  2009-11-13
//
//****************************************************************************
procedure Pad_End (var main; ch : Char; field : integer);
begin

   while Length (string(main))<field do
      string(main) := string(main) + ch;

end; //Pad_End

//****************************************************************************
//
//  DESCRIPTION
//  This function will add the given characters to the end of the given
//  string, until the length of that string equals a given length.   If the
//  string already exceeds the given length, the string is returned as is.
//
//  PARAMETERS
//
//  main (string) : This is the string which should be padded out.
//  ch (CHAR)     : This is the character which should be added to the end of
//                  the given string, until it reaches the given length.
//  field (integer)  : This is the desired length of the string.
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  2009-11-13
//
//****************************************************************************
function End_Padded (main : String; ch : Char; field : integer) : String;
begin

   Pad_End (main,ch,field);
   End_Padded := main;

end; //Pad_End

//****************************************************************************
//
//  DESCRIPTION
//  This procedure will add the given characters to the front of the given
//  string, until the length of that string equals a given length.   If the
//  string already exceeds the given length, the string is returned as is.
//
//  PARAMETERS
//
//  main (untyped) : This is the string which should be padded out.
//  ch (CHAR)      : This is the character which should be added to the front
//                   of the given string, until it reaches the given length.
//  field (integer)   : This is the desired length of the string.
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  2009-11-13
//
//****************************************************************************
procedure Pad_Front (var main; ch : Char; field : integer);
begin

   while Length (string(main))<field do
      string(main) := ch + string(main);

end; //Pad_Front

//***************************************************************************
//
//  FUNCTION  : Front_Padded
//
//  I/P       : main : String - The original string
//
//              ch : Char - The characters to be added to the front, to achieve
//                the desired length.
//
//              maxLength : integer - If padding, this is the maximum length
//                of the resultant string.
//
//  O/P       : String - the resultant string.
//
//  OPERATION : Add the given characters to the front of the given  string,
//              until the length of that string equals a given length.   If the
//              string already exceeds the given length, the string is returned as is.
//
//  UPDATED   : 2018-11-10
//
//***************************************************************************
function Front_Padded (main : String;
                       ch : Char;
                       field : integer) : String;
begin
  Pad_Front (main,ch,field);
  Front_Padded := main;
end; //Front_Padded

//****************************************************************************
//
//  DESCRIPTION
//  This function will add leading zeroes to a given (positive) whole number,
//  returning the number in a string form of a given length.   If the length
//  of the number is greater than the given length, the string will contain
//  the complete number, but with no leading zeroes.
//
//  PARAMETERS
//
//  main (string) : This is the string which should be padded out.
//  ch (CHAR)     : This is the character which should be added to the front
//                  of the given string, until it reaches the given length.
//  field (integer)  : This is the desired length of the string.
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  2010-08-16
//
//****************************************************************************
function Leading_Zeroes (num : Word; field : integer) : String;
begin
   result := IntToStr(num);
   if (Length(result) < num)  then
     result := Front_Padded (result,'0',field);
end; //Leading_Zeroes

//***************************************************************************
//
//  FUNCTION  : BytesToAnsiStr
//
//  I/P       : ip_array : array of Byte - The source bytes.
//
//              offset : Integer - The array offset of the first byte in
//                the resultant string.
//
//              count : Integer - The number of bytes/characters in the string
//
//  O/P       : AnsiString
//
//  OPERATION : This function replaces the previous Bytes_To_AnsiStr function,
//              which was faulty in that it added one more byte than was
//              indicated in the count parameter.
//
//              Create a string out of a series of bytes.
//
//  UPDATED   : 2019-10-22
//
//***************************************************************************
function BytesToAnsiStr (ip_array : array of Byte;
                         offset : Integer;
                         count : integer) : AnsiString;
var
   n : Integer;

begin
  result := '';

  n := offset;
  while (n < offset + count) do
  begin
    result := result + AnsiChar(ip_array[n]);
    Inc(n);
  end; // while
end; // BytesToAnsiStr

//***************************************************************************
//
//  FUNCTION    :   Count_Chars
//
//  I/P         :
//
//  O/P         :   (integer) - The number of occurrances of the given
//                          character in the given string.
//
//  OPERATION   :   Counts the number of occurrances of a given character
//                      in a given string.
//
//  UPDATED     :   15/07/1999
//
//***************************************************************************
function Count_Chars (main : String; ch : CHAR) : Integer;
var
  n : Integer;
  ls : Integer;
begin
  ls := Length(main);
  result := 0;
  for n := 1 to ls do
    if (main[n] = ch) then
      Inc(result);
end; // Count_Chars

//***************************************************************************
//
//  FUNCTION  : TrimToFirst
//
//  I/P       : sMain (string) - The string to be trimmed
//
//              sFind (char) - The string from which the main string
//                is to be shortened.
//
//  O/P       : (string) - The given string, less the first occurrance
//                of sFind, and any characters prior to it.
//
//  OPERATION : Trims a string, removing all characters that occur
//              up to, and including, the first occurrance of the
//              given find-string.
//
//              If the given find string is not in the string, an
//              empty string is returned.
//
//  UPDATED   : 2009-08-25
//
//***************************************************************************
function TrimToFirst (sMain : String; sFind : string) : String;
begin
  if (Pos(sFind,sMain) <> 0) then
    result := Copy(sMain,Pos(sFind,sMain)+Length(sFind),Length(sMain))
  else
    result := '';
end; // TrimToFirst

//***************************************************************************
//
//  FUNCTION  : TrimFromFirst
//
//  I/P       : sMain (string) - The string to be trimmed
//
//              sFind (string) - The string after which the main string
//                is to be shortened.
//
//  O/P       : (string) - The given string, less any characters
//                from the first occurrance of the find-string onwards.
//
//  OPERATION : Trims a string, removing all characters that occur
//              from the first occurrance of the given find-string to
//              the end of the string.
//
//              If the given find string is not in the string, the
//              entire original string is returned.
//
//  UPDATED   : 2009-08-25
//
//***************************************************************************
function TrimFromFirst (sMain : String; sFind : string) : String;
begin
  if (Pos(sFind,sMain) <> 0) then
    result := LeftStr(sMain,Pos(sFind,sMain)-1)
  else
    result := sMain;
end; // TrimFromFirst

//***************************************************************************
//
//  FUNCTION  : RemoveBeforeLast
//
//  I/P       : sMain (string) - The string to be trimmed
//
//              cGiven (char) - The character from which the string
//                is to be shortened.
//
//  O/P       : (string) - The given string, less the last occurrance
//                of cFrom, and any characters prior to it.
//
//  OPERATION : Trims a string, removing all characters that occur
//              up to, and including, the last occurrance of the
//              given character.    Returns the end portion
//
//  UPDATED   : 2004/02/23
//
//***************************************************************************
function RemoveBeforeLast (sMain : String; cGiven : char) : String;
var
  n : Integer;
begin
// Check whether the string actually contains the required character
  if (Pos(cGiven,sMain)<>0) then
  begin
// Move through the string backwards, looking for the first occurrance from the end.
    n := Length(sMain);
    while (n>0) do
    begin
      if (sMain[n] = cGiven) then
      begin
        result := Copy(sMain,n + 1,Length(sMain));
        break;
      end; // if
      Dec(n);
    end; // while
  end // if
  else
// If the string does not contain the required character, the result is an
// empty string
    result := '';
end; // RemoveBeforeLast

//***************************************************************************
//
//  FUNCTION  : RemoveFromLast
//
//  I/P       : orig : String - The string to be trimmed
//
//              trimFrom : String - The string from which the string
//                is to be shortened.
//
//  O/P       : String - The given string, less any characters
//                from the last occurrance of trimFrom onwards.
//
//  OPERATION : Trims a string, removing all characters that occur
//              from the last occurrance of the given string to
//              the end of the string.   Returns the front portion.
//
//  UPDATED   : 2019-04-24
//
//***************************************************************************
function RemoveFromLast (orig : String; trimFrom : String) : String;
var
  n : Integer;
begin
  // Check whether the string actually contains the required character
  if (Pos(trimFrom, orig) <> 0) then
  begin
    // Move through the string backwards, looking for the first occurrance
    // from the end.
    n := Length(orig) - Length(trimFrom) + 1;
    while (n > 0) do
    begin
      if (Copy(orig, n, Length(trimFrom)) = trimFrom) then
      begin
        result := LeftStr(orig, n-1);
        break;
      end; // if
      Dec(n);
    end; // while
  end // if
  else
    // If the string does not contain the required string,
    // the result is the original string
    result := orig;
end; // RemoveFromLast

//***************************************************************************
//
//       FUNCTION    :  ANSStrToBool
//
//       I/P         :  sLine (string) - The string, the first character of
//                        which is a boolean character
//
//       O/P         :  TRUE if the first character of the given string was
//                        a '1', else FALSE.
//
//       OPERATION   :  Tests the first character of a given string to see if
//                       it is a '1'.   FALSE if not, or if string is empty
//
//       UPDATED     :   2001/01/15
//
//***************************************************************************
function ANSStrToBool(sLine : string) : boolean;
begin
  if (sLine='') then
    result := FALSE
  else
    if (sLine[1] = '1') then
      result := TRUE
    else
      result := FALSE;
end; // ANSStrToBool

//***************************************************************************
//
//       FUNCTION    :  Str2ASCIIHex
//
//       I/P         :  sInput (string) - The string to be converted to Hex
//
//                      ucBlockSize : - The number of bytes in divisions (with
//                        a space between each block).   0 = no divisions.
//
//       O/P         :  String of hex data
//
//       OPERATION   :  Converts a given string into its Hex equivalent.   Adds
//                      separator spaces at the requested interval.
//                      eg StrToHex('Andrew Spencer' + #0 + #13 + #10,4) will give
//                      '406E6472 65772053 70656E63 6572000D 0A'
//
//       UPDATED     :   2003/06/05
//
//***************************************************************************
function Str2ASCIIHex(sInput : String;
                      ucBlockSize : byte = 0) : String;
var
  n : Integer;
begin
  result := '';
  for n := 1 to Length(sInput) do
  begin
    result := result + IntToHex(Ord(sInput[n]),2);

    if ((ucBlockSize<>0) and
        (n mod ucBlockSize = 0)) then
      result := result + ' ';
  end; // for
end; // Str2ASCIIHex

function Str2ASCIIHex(sInput : AnsiString;
                      ucBlockSize : byte = 0) : String;
var
  n : Integer;
begin
  result := '';
  for n := 1 to Length(sInput) do
  begin
    result := result + IntToHex(Ord(sInput[n]),2);

    if ((ucBlockSize<>0) and
        (n mod ucBlockSize = 0)) then
      result := result + ' ';
  end; // for
end; // Str2ASCIIHex

//***************************************************************************
//
//  FUNCTION  : Hex2Str
//
//  I/P       : Hex (string) - The string of hex characters
//
//  O/P       : String of characters as given.
//
//  OPERATION : Converts a given string of hex pairs into the equivalent
//                AnsiString.   Returns an empty string if there is an error.
//
//  UPDATED   : 2015-12-04
//
//***************************************************************************
function Hex2Str(Hex : string) : AnsiString;
var
  n : Integer;

begin
  result := '';
  if ((Hex <> '') and
      (Length(Hex) mod 2 = 0)) then
  begin
    for n := 1 to Length(Hex) div 2 do
      result := result + AnsiChar(StrToInt('$' + Copy(Hex,n*2-1,2)));
  end;
end; // Str2ASCIIHex

//***************************************************************************
//
//  FUNCTION  : GroupSplitString
//
//  I/P       : original : String - The string to be split
//
//              separator : String - The string to insert between each group
//
//              sizeGroup : Integer = 2 - The number of characters in each group.
//
//  O/P       : String
//
//  OPERATION : Split a string into groupings.
//
//              Typically used to split a string of hex characters
//
//  UPDATED   : 2021-01-27
//
//***************************************************************************
function GroupSplitString(original : String;
                          separator : String;
                          sizeGroup : Integer = 2) : String;
var
  n : Integer;

begin
  Result := '';

  // Create groups, up till the the last group
  n := 1;
  while (n + sizeGroup - 1 < Length(original)) do
  begin
    Result := Result + Copy(original, n, sizeGroup) + separator;
    Inc(n, sizeGroup);
  end;

  // Add the last group
  Result := Result + Copy(original, n, Length(original));
end; // GroupSplitString

//***************************************************************************
//
//  FUNCTION    :   String2Longint
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :   Converts a given string to a longint.   This may be
//                      used in place of Val, since it returns a TRUE/FALSE
//                      result of the conversion.   It may also be used in
//                      place of StrToInt, which only returns an integer, and
//                      causes an exception if it fails.
//
//  UPDATED     :
//
//***************************************************************************
function String2Longint (sInput : String;
                         var liOutput : longint) : boolean;
var
  iResult : Integer;
begin
  Val (sInput,liOutput,iResult);
  result := (iResult=0);
end; // String2Longint

//***************************************************************************
//
//  FUNCTION  : ExtractAndTrim
//
//  I/P       : sInput (string) - The initial source string.
//
//              sSeparator (string) - The string of characters (usually just
//                one character e.g. ',') up to which the string must be
//                extracted.
//
//  O/P       : (string) - The extracted string.
//
//              sInput (string) - The initial source string, less the extracted
//                portion and the separator string.
//
//  OPERATION : Extracts a string from the front of a given string, using a given
//              separator. The original string is returned with the extracted
//              string and separator strings removed.
//
//              If no occurrance of the separator is found, the entire
//              input string is returned as the result, and the original
//              string is set to an empty string.
//
//              This function may be used for CSV file parsing.
//
//  UPDATED   : 2007/02/07
//
//***************************************************************************
function ExtractAndTrim (var sInput : String; sSeparator : string) : String; overload;
begin
  if (Pos(sSeparator,sInput) <> 0) then
  begin
    result := LeftStr(sInput,Pos(sSeparator,sInput)-1);
    sInput := Copy(sInput,Pos(sSeparator,sInput)+Length(sSeparator),Length(sInput));
  end // if
  else
  begin
    result := sInput;
    sInput := '';
  end; // else
end; // ExtractAndTrim

//***************************************************************************
//
//  FUNCTION  : ExtractAndTrim
//
//  I/P       : sInput (AnsiString) - The initial source string.
//
//              sSeparator (AnsiString) - The string of characters (usually just
//                one character e.g. ',') up to which the string must be
//                extracted.
//
//  O/P       : (AnsiString) - The extracted string.
//
//              sInput (AnsiString) - The initial source string, less the extracted
//                portion and the separator string.
//
//  OPERATION : Extracts a string from the front of a given string, using a given
//              separator. The original string is returned with the extracted
//              string and separator strings removed.
//
//              If no occurrance of the separator is found, the entire
//              input string is returned as the result, and the original
//              string is set to an empty string.
//
//              This function may be used for CSV file parsing.
//
//  UPDATED   : 2010-10-21
//
//***************************************************************************
function ExtractAndTrim (var sInput : AnsiString; sSeparator : AnsiString) : AnsiString; overload;
begin
  if (Pos(sSeparator,sInput) <> 0) then
  begin
    result := System.AnsiStrings.LeftStr(sInput,Pos(sSeparator,sInput)-1);
    sInput := Copy(sInput,Pos(sSeparator,sInput)+Length(sSeparator),Length(sInput));
  end // if
  else
  begin
    result := sInput;
    sInput := '';
  end; // else
end; // ExtractAndTrim

//***************************************************************************
//
//  FUNCTION  : ExtractAndTrimQ
//
//  I/P       : sInput (string) - The initial source string.
//
//              sSeparator (string) - The string of characters (usually just
//                one character e.g. ',') up to which the string must be
//                extracted.
//
//  O/P       : (string) - The extracted string.
//
//              sInput (string) - The initial source string, less the extracted
//                portion and the separator string.
//
//  OPERATION : Extracts a string from the front of a given string, using a given
//              separator. The original string is returned with the extracted
//              string and separator strings removed.
//
//              The extracted string may be optionally enclosed in single or
//              double quotes, which are removed in the result.
//
//              If no occurrance of the separator is found, the entire
//              input string (less any surrounding quotes) is returned as the
//              result, and the original string is set to an empty string.
//
//              This function may be used for CSV file parsing.
//
//  UPDATED   : 2024-09-26
//
//***************************************************************************
function ExtractAndTrimQ (var sInput : String; sSeparator : string) : String; overload;
begin
  if (Length(sInput) > 0) then
  begin
    if (sInput[1] = '"') then
    begin
      ExtractAndTrim(sInput, '"');
      Result := ExtractAndTrim(sInput,'"');
      ExtractAndTrim(sInput, sSeparator);
    end // if
    else if (sInput[1] = '''') then
    begin
      ExtractAndTrim(sInput, '''');
      Result := ExtractAndTrim(sInput,'''');
      ExtractAndTrim(sInput, sSeparator);
    end // if
    else
      Result := ExtractAndTrim(sInput, sSeparator);
  end // else
  else
  begin
    result := sInput;
    sInput := '';
  end;
end; // ExtractAndTrimQ

//***************************************************************************
//
//  FUNCTION  : ExtractAndTrimQ
//
//  I/P       : sInput (AnsiString) - The initial source string.
//
//              sSeparator (AnsiString) - The string of characters (usually just
//                one character e.g. ',') up to which the string must be
//                extracted.
//
//  O/P       : (AnsiString) - The extracted string.
//
//              sInput (AnsiString) - The initial source string, less the extracted
//                portion and the separator string.
//
//  OPERATION : Extracts a string from the front of a given string, using a given
//              separator. The original string is returned with the extracted
//              string and separator strings removed.
//
//              The extracted string may be optionally enclosed in single or
//              double quotes, which are removed in the result.
//
//              If no occurrance of the separator is found, the entire
//              input string (less any surrounding quotes) is returned as the
//              result, and the original string is set to an empty string.
//
//              This function may be used for CSV file parsing.
//
//  UPDATED   : 2024-09-26
//
//***************************************************************************
function ExtractAndTrimQ (var sInput : AnsiString; sSeparator : AnsiString) : AnsiString; overload;
begin
  if (Length(sInput) > 0) then
  begin
    if (sInput[1] = '"') then
    begin
      sInput := Copy(sInput, 2, Length(sInput));
      Result := ExtractAndTrim(sInput, '"');
      sInput := Copy(sInput, 2, Length(sInput));
      ExtractAndTrim(sInput, sSeparator);
    end // if
    else if (sInput[1] = '''') then
    begin
      sInput := Copy(sInput, 2, Length(sInput));
      Result := ExtractAndTrim(sInput, '''');
      sInput := Copy(sInput, 2, Length(sInput));
      ExtractAndTrim(sInput, sSeparator);
    end // if
    else
      Result := ExtractAndTrim(sInput, sSeparator);
  end // else
  else
  begin
    result := sInput;
    sInput := '';
  end;
end; // ExtractAndTrimQ

//***************************************************************************
//
//  FUNCTION    :   Strip_Front
//
//  I/P         :   sMain (string) - The string to be pruned
//
//                      cRemove (char) - The characters to be removed
//
//  O/P         :   (string) - The given string, without any initial
//                        occurrances of the indicated character.
//
//  OPERATION   :   Removes all initial occurrances of the indicated character
//                      from the given string.
//
//  UPDATED     :   2001/10/16
//
//***************************************************************************
function Strip_Front (sMain : String; cRemove : CHAR) : String;
var
  n : Integer;
begin
  n := 1;
  while ((n<=Length(sMain)) and (sMain[n]=cRemove)) do
    Inc(n);

  result := Copy(sMain,n,Length(sMain));
end; // Strip_Front

//***************************************************************************
//
//  FUNCTION    :   ExtractAndTrimTo
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :   Extracts a string from a given string, for a given number
//                      of characters.   The original string then has the extracted
//                      string removed from it.
//
//                      This function may be used for concatenated string parsing.
//
//  UPDATED     :   2001/10/\17
//
//***************************************************************************
function ExtractAndTrimTo (var sInput : String; uiLength : word) : String; overload;
begin
  result := LeftStr(sInput,uiLength);
  sInput := Copy(sInput,uiLength+1,Length(sInput));
end; // ExtractAndTrimTo

//***************************************************************************
//
//  FUNCTION    :   ExtractAndTrim
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :   Extracts a string from a given string, for a given number
//                      of characters.   The original string then has the extracted
//                      string removed from it.
//
//                      This function may be used for concatenated string parsing.
//
//  UPDATED     :   2010-10-28
//
//***************************************************************************
function ExtractAndTrimTo(var sInput : AnsiString; uiLength : word) : AnsiString; overload;
begin
  result := System.AnsiStrings.LeftStr(sInput,uiLength);
  sInput := Copy(sInput,uiLength+1,Length(sInput));
end; // ExtractAndTrimTo

//***************************************************************************
//
//  FUNCTION    :   Boolean2Str
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :   Return a '1' or '0' depending on the input boolean value.
//
//  UPDATED     :   2001/10/23
//
//***************************************************************************
function Boolean2Str (bTest : boolean) : String;
begin
  if (bTest) then
    result := '1'
  else
    result := '0';
end; // Boolean2Str

//***************************************************************************
//
//  FUNCTION  : SearchAndReplace
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Replaces all occurrences of the string sFind with the
//              string sReplace.
//
//              This must be a single-pass, and not an iterative,
//              operation.
//
//              An iterative operation would reduce '----' to '-'
//              if we repaced all '---' with '-'.
//
//              A single-pass operation would reduce '----' to '--'
//              if we repaced all '---' with '-'.
//
//  UPDATED   : 2007-06-06
//
//***************************************************************************
function SearchAndReplace(sMain : String; sFind : String; sReplace : string) : String; overload;
var
  iTo : Integer;
begin
// I am not using StringReplace (a built-in Delphi function).
// I can't recall the exact reason, but it did not work as I would have liked it to.
// I think it was when there were odd characters (like #0) in the string (changed when doing the SPS uploader)
//  result := StringReplace(sMain,sFind,sReplace,[rfReplaceAll]);
  if (sMain = '') then
    result := ''
  else
    if ((sFind = '') or (sFind = sReplace)) then
      result := sMain
    else
    begin
      result := '';
      repeat
        iTo := Pos(sFind,sMain);
        if (iTo = 0) then
          result := result + LeftStr(sMain,Length(sMain))
        else
        begin
          // Get the part of the string up to the found sub-string, and shorten
          // the original string to that point
          result := result + ExtractAndTrimTo(sMain,iTo-1);
          // Add the replacement
          result := result + sReplace;
          // Skip over the found sub-string in the original string.
          sMain := Copy(sMain,Length(sFind)+1,Length(sMain));
        end; // else
      until (iTo = 0);
    end; // if
end; // SearchAndReplace
function SearchAndReplace(sMain : AnsiString; sFind : AnsiString; sReplace : AnsiString) : AnsiString; overload;
var
  iTo : Integer;
begin
// I am not using StringReplace (a built-in Delphi function).
// I can't recall the exact reason, but it did not work as I would have liked it to.
// I think it was when there were odd characters (like #0) in the string (changed when doing the SPS uploader)
//  result := StringReplace(sMain,sFind,sReplace,[rfReplaceAll]);
  if (sMain = '') then
    result := ''
  else
    if ((sFind = '') or (sFind = sReplace)) then
      result := sMain
    else
    begin
      result := '';
      repeat
        iTo := Pos(sFind,sMain);
        if (iTo = 0) then
          result := result + System.AnsiStrings.LeftStr(sMain,Length(sMain))
        else
        begin
          // Get the part of the string up to the found sub-string, and shorten
          // the original string to that point
          result := result + ExtractAndTrimTo(sMain,iTo-1);
          // Add the replacement
          result := result + sReplace;
          // Skip over the found sub-string in the original string.
          sMain := Copy(sMain,Length(sFind)+1,Length(sMain));
        end; // else
      until (iTo = 0);
    end; // if
end; // SearchAndReplace

//***************************************************************************
//
//  FUNCTION  : ExtractFrontMatching
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Extracts a string, starting at the beginning of the
//              given string, and containing only characters in the
//              given set.
//
//              This function may be used, for example, to extract
//              '12345' from '12345ABCDE'
//
//  UPDATED   : 2002/09/05
//
//***************************************************************************
function ExtractFrontMatching (sInput : String; stMatch : TSysCharSet) : String;
var
  n : Integer;
begin
  Result := '';
  n := 1;
  while ((n<=Length(sInput)) and (CharInSet(sInput[n],stMatch))) do
  begin
    Result := Result + sInput[n];
    Inc(n);
  end; // while
end; // ExtractFrontMatch

//***************************************************************************
//
//  FUNCTION  : Str2Debug
//
//  I/P       : sLine (AnsiString) - The string to be represented in a debug form
//
//              bAllNumerical (boolean) - TRUE to represent each character in
//                the string as a single byte value.   FALSE to show textual
//                representations of the control characters for the first 32 characters.
//
//              bHex (boolean) - TRUE to express the numerical characters in hex
//
//              bSquareBrackets (boolean) - TRUE to enclose hex values in [] brackets
//
//              cSeparator (char) - The character (e.g. ',') used to separate
//                the debug entries.   Use #0 for no separator.
//
//  O/P       : string
//
//  OPERATION :
//
//  UPDATED   : 2009-02-20
//
//***************************************************************************
function Str2Debug(sLine : AnsiString;
                   bAllNumerical : boolean;
                   bHex : boolean;
                   bSquareBrackets : boolean;
                   cSeparator : char) : String;
var
  n : Integer;
begin
  result := '';
  for n := 1 to Length(sLine) do
  begin
    if (bAllNumerical) then
    begin
      if (bHex) then
      begin
        if (bSquareBrackets) then
          result := result + '[' + IntToHex(Ord(sLine[n]),2) + ']'
        else
          result := result + IntToHex(Ord(sLine[n]),2);
      end // if
      else
        result := result + IntToStr(Ord(sLine[n]));
    end // IF
    else
      case sLine[n] of
        #0 : result := result + '<NUL>';
        #1 : result := result + '<SOH>';
        #2 : result := result + '<STX>';
        #3 : result := result + '<ETX>';
        #4 : result := result + '<EOT>';
        #5 : result := result + '<ENQ>';
        #6 : result := result + '<ACK>';
        #7 : result := result + '<BEL>';
        #8 : result := result + '<BS>';
        #9 : result := result + '<HT>';
        #10 : result := result + '<LF>';
        #11 : result := result + '<VT>';
        #12 : result := result + '<FF>';
        #13 : result := result + '<CR>';
        #14 : result := result + '<SO>';
        #15 : result := result + '<SI>';
        #16 : result := result + '<SLE>';
        #17 : result := result + '<CS1>';
        #18 : result := result + '<DC2>';
        #19 : result := result + '<DC3>';
        #20 : result := result + '<DC4>';
        #21 : result := result + '<NAK>';
        #22 : result := result + '<SYN>';
        #23 : result := result + '<ETB>';
        #24 : result := result + '<CAN>';
        #25 : result := result + '<EM>';
        #26 : result := result + '<SIB>';
        #27 : result := result + '<ESC>';
        #28 : result := result + '<FS>';
        #29 : result := result + '<GS>';
        #30 : result := result + '<RS>';
        #31 : result := result + '<US>';
        ' '..'~' : result := result + char(sLine[n]);
        else
        begin
          if (bSquareBrackets) then
            result := result + '[' + IntToHex(Ord(sLine[n]),2) + ']'
          else
            result := result + IntToHex(Ord(sLine[n]),2);
        end; // if
      end; // case
    // Add the separator character after all except the last character
    if (n < Length(sLine)) then
      if (cSeparator <> #0) then
        result := result + cSeparator;
  end; // for
end; // Str2Debug

//***************************************************************************
//
//  FUNCTION  : DP
//
//  I/P       : dtDate (TDateTime) - the date for which the password will be
//                generated.
//
//  O/P       : (string) - A 5-digit number
//
//  OPERATION : Constructs a "Date Password" - a number that is derived from
//              the given date.   This is used for "backdoor" access to
//              programs where users have forgotten their password.   This
//              password would, in general, be valid only for a particular day.
//
//              Note - the function name is left vague to minimise location of
//              the function in EXE examination.
//
//  UPDATED   : 2005/11/09
//
//***************************************************************************
function DP(dtDate : TDateTime) : String;
var
  uiDateCode : Word;
  ucShift : Byte;
  n : Integer;

begin
  uiDateCode := IntegerDate(dtDate);
  ucShift := IntegerDate(Date) mod 13;
  for n := 0 to ucShift do
    if ((uiDateCode and $0001) = $0001) then
      uiDateCode := uiDateCode div 2 + $8000
    else
      uiDateCode := uiDateCode div 2;
  result := Front_Padded(IntToStr(uiDateCode),'0',5);
end; // DP

//***************************************************************************
//
//  FUNCTION  : StuffString
//
//  I/P       : sNew (string) - The string to be inserted
//
//              iOffset (integer) - The offset where the string is to be
//                inserted
//
//  O/P       : sOriginal (string) - The origianl string with the new
//                characters inserted.
//
//  OPERATION : Inserts a given string into another string, without moving
//              moving anything in the original string.
//
//  UPDATED   : 2006/03/08
//
//***************************************************************************
procedure StuffString(sNew : String;
                      var sOriginal : String;
                      iOffset : integer);
var
  n : Integer;
begin
  if (Length(sOriginal) < iOffset + Length(sNew) - 1) then
    End_Padded(sOriginal,' ',iOffset + Length(sNew) - 1);
  n := 0;
  while (n < Length(sNew)) do
  begin
    sOriginal[n + iOffset] := sNew[n+1];
    Inc(n);
  end; // while
end; // StuffString

//***************************************************************************
//
//  FUNCTION  : RemoveDuplicates
//
//  I/P       : sMain (string) - The string to be reduced.
//
//              cChar (char) - The character of which all adjacent duplicates
//                are to be removed.
//
//  O/P       : sMain (string) - The string, with all duplications of the
//                given character removed.
//
//  OPERATION : Removes all duplications of the given character, reducing
//              them to one instance of each.   This may be useful when parsing
//              space-separated data.
//
//  UPDATED   : 2006/11/22
//
//***************************************************************************
procedure RemoveDuplicates(var sMain : String; cChar : char);
begin
  while (Pos(cChar+cChar,sMain) <> 0) do
    sMain := StringReplace(sMain,cChar+cChar,cChar,[rfReplaceAll]);
end; // RemoveDuplicates

//***************************************************************************
//
//  FUNCTION  : RemoveMarkedSections
//
//  I/P       : var original : String - The string to be modified
//
//              markStart : String - The indicator of the start of the text
//                to be removed.
//
//              markEnd : String - The indicator of the end of the text to be
//                removed.
//
//  O/P       : None
//
//  OPERATION : Remove all text found between the indicated markers. Remove
//              the markers as well. Do this for all occurrances of the markers
//
//  UPDATED   : 2024-11-21
//
//***************************************************************************
procedure RemoveMarkedSections(var original : String;
                               markStart : String;
                               markEnd : String);
begin
  while ((Pos(markStart, original) > 0) and
         (Pos(markEnd, original) > 0) and
         (Pos(markEnd, original) > Pos(markStart, original))) do
  begin
    original := Copy(original, 1, Pos(markStart, original)-1) +
                Copy(original, Pos(markEnd, original) + Length(markEnd), Length(original));
  end;
end; // RemoveMarkedSections

//***************************************************************************
//
//  FUNCTION  : SuppressMiddle
//
//  I/P       : sMain (string) - The long string, that is to be fitted in a
//                small space.
//
//              iAvailableSpace (integer) - The maximum number of characters
//                that may be displayed in the result.
//
//  O/P       : (string) - the resultant string, with '...' replacing the
//                central portion that has been removed.
//
//  OPERATION : Sometimes when a huge path [any long string] is to be
//              displayed in a small space, it is desirable to see the start
//              and the end of the path with ellipses in-between, rather than
//              truncating one of the ends.
//
//              For example
//                "C:\Program Files\Delphi\DDrop\TargetDemo\main.pas"
//              is desired to be seen as
//                "C:\Program F....Demo\main.pas"
//              then the following "Mince" function could be used.
//
//              From : http://delphi.about.com/cs/adptips2000/a/bltip0400_2.htm?nl=1
//
//  UPDATED   : 2007/03/06
//
//***************************************************************************
function SuppressMiddle(sMain :string;
                        iAvailableSpace :integer): string;
var
  iLengthMain : Integer;
  iLengthEnds : Integer;
begin
  iLengthMain := Length(sMain);
  if (iLengthMain > iAvailableSpace) then
  begin
    iLengthEnds := (iAvailableSpace Div 2) - 2;
    result := LeftStr(sMain,iLengthEnds) +
              '...' +
              Copy(sMain,iLengthMain-iLengthEnds,iLengthMain);
  end // if
  else
    result := sMain;
end; // SuppressMiddle

//***************************************************************************
//
//  FUNCTION  : SuppressEnd
//
//  I/P       : sMain : String - The string to be shortened
//
//  O/P       : String - The resultant, possibly truncated, string
//
//  OPERATION : If the given string is too long, it cuts the end, and adds '...'
//
//  UPDATED   : 2019-06-05
//
//***************************************************************************
function SuppressEnd(sMain : String;
                     iAvailableSpace : Integer) : String;
var
  iLengthMain : Integer;

begin
  iLengthMain := Length(sMain);
  if (iLengthMain > iAvailableSpace) then
  begin
    result := Copy(sMain, 1, iAvailableSpace-3) +
              '...';
  end // if
  else
    result := sMain;
end; // SuppressEnd

//***************************************************************************
//
//  FUNCTION  : YesNo
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : WARNING : This routine is language dependent!
//
//  UPDATED   :
//
//***************************************************************************
function YesNo(sInput : String;
               bUpperCase : boolean) : String; overload;
begin
  result := 'No';
  if ((UpperCase(LeftStr(sInput,1)) = 'Y') or
      (UpperCase(LeftStr(sInput,1)) = '1')) then
    result := 'Yes';

  if (bUpperCase) then
    result := UpperCase(result);
end; // YesNo
function YesNo(bState : boolean;
               bUpperCase : boolean = FALSE) : String; overload;
begin
  result := 'No';
  if (bState) then
      result := 'Yes';

  if (bUpperCase) then
    result := UpperCase(result);
end; // YesNo

//***************************************************************************
//
//  FUNCTION  : IfThenS
//
//  I/P       : state : boolean - The choice
//
//              sTrue : String - The result if the choice is TRUE
//
//              sFalse : String = '' - The result if the choice is FALSE
//
//  O/P       : String
//
//  OPERATION : String equivalent of the Maths ifthen i.e. in-line string selection
//
//  UPDATED   : 2018-08-04
//
//***************************************************************************
function IfThenS(state : boolean;
                 sTrue : String; sFalse : String = '') : String;
begin
  result := System.StrUtils.ifthen(state, sTrue, sFalse);
end; // IfThenS

//***************************************************************************
//
//  FUNCTION  : RemapString
//
//  I/P       : given : AnsiString - The string to find in origSet
//
//              origSet : AnsiString - the set of expected characters
//
//              remapSet : AnsiString - the ordered set of remappings
//
//  O/P       :
//
//  OPERATION : Given a character, find it in a string of expected characters.
//              Then return the associated character from the remap string.
//
//  UPDATED   : 2017-10-12
//
//***************************************************************************
function RemapString(given : AnsiString;
                     origSet : AnsiString;
                     remapSet : AnsiString) : AnsiChar;
begin
  if ((Length(origSet) = Length(remapSet)) and
      (Length(origSet) >= Length(given))) then
    result := remapSet[Pos(given,origSet)]
  else
    result := #0;
end; // RemapCharacters

//***************************************************************************
//
//  FUNCTION  : InitialiseName
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Attempts to capitalise all first letters in words (i.e. first
//              word and following a ' ') and all initials (i.e. following a '.',
//              '-' or '&')
//
//  UPDATED   : 2007-12-30
//
//***************************************************************************
procedure InitialiseString (var sMain : string);
var
  n : Integer;
begin
  sMain := LowerCase(sMain);
  // Handle the first letter
  if (Length(sMain) >= 1) then
    sMain[1] := UpperCase(sMain[1])[1];
  // Capitalise everything after a space or full-stop
  n := 1;
  while (n < Length(sMain)) do
  begin
    if ((sMain[n] = ' ') or
        (sMain[n] = '.') or
        (sMain[n] = '-') or
        (sMain[n] = '&')) then
      sMain[n+1] := UpperCase(sMain[n+1])[1];
    Inc(n);
  end; // while
end; // InitialiseString

//***************************************************************************
//
//  FUNCTION  : GetNthChar
//
//  I/P       : sIP (string) - The string from which the character is to be
//                extracted.
//
//              iOffset (string) - The offset of the required character
//
//  O/P       : (char) - The character, or #0 if there is no indexed character.
//
//  OPERATION : Returns the n-th character in the given string
//              Returns #0 if there is no n-th character
//
//  UPDATED   : 2009-07-30
//
//***************************************************************************
function GetNthChar(sIP : String;
                    iOffset : integer) : Char;
begin
  if (Length(sIP) >= iOffset) then
    result := sIP[iOffset]
  else
    result := #0;
end; // GetNthChar

//***************************************************************************
//
//  FUNCTION  : Readable
//
//  I/P       :
//
//  O/P       : (boolean) - TRUE if the string contains only characters that
//                fall in the "readable" range of ASCII
//
//  OPERATION : Returns an indication as to whether the content of the given
//              string is all readable or not.
//
//  UPDATED   :
//
//***************************************************************************
function Readable(sIP : string) : boolean;
var
  n : Integer;

begin
  result := TRUE;
  n := 1;
  while ((result) and (n <= Length(sIP))) do
  begin
    if ((Ord(sIP[n]) < 32) or (Ord(sIP[n]) > 126)) then
      result := FALSE;
    Inc(n);
  end; // while
end; // Readable

//***************************************************************************
//
//  FUNCTION  : MatchingChars
//
//  I/P       : s1,s2 : String - The strings to be compared
//
//  O/P       : Integer - The number of characters, from the front of the
//                two strings, that match
//
//  OPERATION : Indicates the number of matching characters in the two given
//              strings
//
//  UPDATED   : 2010-08-23
//
//***************************************************************************
function MatchingChars(s1 : AnsiString;
                       s2 : AnsiString) : Integer;
var
  iShortest : Integer;
  n : Integer;

begin
  iShortest := Min(Length(s1),Length(s2));
  n := 1;
  while ((n <= iShortest) and (s1[n] = s2[n])) do
    Inc(n);

  Dec(n);
  result := n;
end; // MatchingChars

//***************************************************************************
//
//  FUNCTION  : IsAnInteger
//
//  I/P       :
//
//  O/P       : Boolean - TRUE if the string can be converted to an integer
//
//  OPERATION : Returns TRUE if the string represents an integer number
//              (in any format that can be converted to a integer, including
//              '$'-prefixed hexadecimal)
//
//              I would really like to get rid of the Compiler Hint:
//                'H2077 Value assigned to 'iTarget' never used'
//
//  UPDATED   : 2024-11-07
//
//***************************************************************************
function IsAnInteger(sNumber : string) : boolean;
var
  iCode : Integer;
  iTarget : Int64; // To handle really big numbers!

begin
  Val(sNumber, iTarget, iCode);
  result := (iCode = 0);
end; // IsAnInteger

//***************************************************************************
//
//  FUNCTION  : IsAFloat
//
//  I/P       : sNumber : string
//
//  O/P       : Boolean - TRUE if the string can be converted to a floating point
//
//  OPERATION : Returns true if the string represents a floating point number.
//
//              Allow any format that can be converted to a float, including
//              whole numbers, scientific and normal floating point.
//
//              Note : You cannot use the Val command here, as I have done in
//                IsAnInteger, above (to avoid exceptions during debugging).
//                Val command expects a '.' as a decimal separator(!)
//
//              Empty string, a single minus (typical if testing an input as
//              someone is typing in a negative number) and 'NAN' are
//              specifically tested to stop the StrToFloat operation causing
//              an annoying exception during debugging operations.
//
//  UPDATED   : 2023-03-22
//
//***************************************************************************
function IsAFloat(sNumber : string) : boolean;
begin
  if ((sNumber <> '') and
      (sNumber <> '-') and
      (sNumber <> 'NAN')) then
  begin
    try
  {$O-}
      StrToFloat(sNumber);
  {$O+}
      result := TRUE;
    except
      result := FALSE;
    end;
  end // if
  else
    result := FALSE;
end; // IsAFloat

//***************************************************************************
//
//  FUNCTION  : IsAlphaNumeric
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Check that the given string contains alphanumeric characters
//              only.   (An emptry string returns FALSE.)
//
//  UPDATED   : 2012-04-19
//
//***************************************************************************
function IsAlphaNumeric(sInput : string) : boolean;
var
   c : char;
begin
  result := (sInput <> '');

  if (result) then
  begin
    for c in sInput do
    begin
     result := CharInSet(c,['0'..'9','A'..'Z','a'..'z']);
     if (not result) then
       break;
   end;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : IsIP4Address
//
//  I/P       : sInput : String - the IP address to be tested
//
//  O/P       : Boolean - TRUE if this looks like a valid IP
//
//  OPERATION : Check that the given input string is of the form a.b.c.d where
//              a, b, c and d are integers in the range 0 and 255.
//
//  UPDATED   : 2014-03-03
//
//***************************************************************************
function IsIP4Address(sInput : string) : boolean;
var
  sPart : String;
  n: integer;
  iValue : Integer;

begin
  result := TRUE;
  if (Count_Chars(sInput,'.') = 3) then
  begin
    for n := 1 to 4 do
    begin
      sPart := ExtractAndTrim(sInput,'.');
      if (IsAnInteger(sPart)) then
      begin
        iValue := StrToInt(sPart);
        if ((iValue < 0) or (iValue > 255)) then
          result := FALSE;
      end; // if
    end; // for
  end // if
  else
    result := FALSE;
end;

//***************************************************************************
//
//  FUNCTION  : IsAHexadecimal
//
//  I/P       : sInput : String - The string to be tested
//
//  O/P       : Boolean - TRUE if the string is non-empty, with all characters
//                being valid hexadecimal characters.
//
//  OPERATION : Check that the given string contains valid hexadecimal characters.
//
//              The string may be very long, and need not contain an even number
//              of characters.
//
//  UPDATED   : 2019-06-13
//
//***************************************************************************
function IsAHexadecimal(sInput : String) : Boolean;
var
  n : Integer;

begin
  result := TRUE;
  n := Length(sInput);
  if (n > 0) then
  begin
    while ((result) and (n > 0)) do
    begin
      if (not ((sInput[n].IsNumber) or
               (CharInSet(sInput[n].ToUpper, ['A'..'F'])))) then
      begin
        result := FALSE;
      end;
      Dec(n);
    end;
  end // if
  else
  begin
    result := FALSE;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : IsADateTime
//
//  I/P       : sInput : String - The string to be tested
//
//  O/P       : Boolean - TRUE if the string appears to be a valid date time
//
//  OPERATION : Check that the given string contains a convertable date time.
//
//  UPDATED   : 2024-11-18
//
//***************************************************************************
function IsADateTime(sInput : String) : Boolean;
var
  n : Integer;

begin
  result := TRUE;
  n := Length(sInput);
  if (n > 3) then
  begin
    // The shortest valid datetime string is probably something like "0:0"
    try
      StrToDateTime(sInput);
    except
      Result := False;
    end;
  end
  else
  begin
    result := FALSE;
  end;
end; // IsADateTime

//***************************************************************************
//
//  FUNCTION  : ForcedStrToFloat
//
//  I/P       : sValue : String - The string that is to be converted into a
//                floating point number
//
//              dInvalid : Extended - Value to return if invalid
//
//  O/P       : Extended - The result
//
//  OPERATION : Convert a given string into a floating point number.
//
//              The function first tries to convert a string to a floating
//              point number using the current decimal separator. If that is
//              not successful, it tries the "other" one.
//              In general, decimal separators are either '.' or ','.
//              If neither attempt is successful, the given invalid value is
//              returned.
//
//              This function should handle both normal and scientific notation.
//
//              Not thread-safe. See the help on StrToFloat.
//
//  UPDATED   : 2020-10-19
//
//***************************************************************************
function ForcedStrToFloat(sValue : String;
                          dInvalid : Extended) : Extended;
var
  cCurrentDecimalSeaprator : char;

begin
  cCurrentDecimalSeaprator := FormatSettings.DecimalSeparator;
  try
    try
      // It's annoying to get interruptions when debugging, so do some pre-tests
      // at the expense of a small amount of speed, before attempting a string-
      // to-float conversion.
      if ((sValue <> '') and
          (sValue <> 'NAN')) then
      begin
        // The string may sometimes contain spaces (thousands separators)
        // Remove these.
        sValue := StringReplace(sValue, ' ', '', [rfReplaceAll]);
        if (Pos(',', sValue) = 0) then
        begin
          FormatSettings.DecimalSeparator := '.';
        end // if
        else
        begin
          FormatSettings.DecimalSeparator := ','
        end; // else
        result := StrToFloat(sValue);
      end // if
      else
      begin
        result := dInvalid;
      end; // else
    except
      // The above attempt failed. Try the "other" commonly used decimal separator.
      // Failure may occur because some countries use '.' or ',' as the
      // thousands separator.
      if (cCurrentDecimalSeaprator = '.') then
        FormatSettings.DecimalSeparator := ','
      else
        FormatSettings.DecimalSeparator := '.';
      try
        result := StrToFloat(sValue);
      except
        result := dInvalid;
      end; // except
    end; // except
  finally
    FormatSettings.DecimalSeparator := cCurrentDecimalSeaprator;
  end;
end; // ForcedStrToFloat

//***************************************************************************
//
//  FUNCTION  : InitialUpperCase
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
function InitialUpperCase(sInput : String) : String;
begin
  sInput := LowerCase(sInput);
  if (Length(sInput) > 0) then
    sInput[1] := sInput[1].ToUpper;
  result := sInput;
end; // InitialUpperCase

//***************************************************************************
//
//  FUNCTION  : CodePointFromChar
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Used in Luhn Mod N single-character check code creation.
//
//              Returns the position of the given character in the set ['0'..'9','A'..'Z']
//
//  UPDATED   : 2011-04-24
//
//***************************************************************************
function CodePointFromChar(cChar : AnsiChar) : Integer;
begin
  if (cChar in ['0'..'9','A'..'Z']) then
  begin
    if (cChar in ['0'..'9']) then
      result := Ord(cChar) - Ord('0')
    else
      result := Ord(cChar) - Ord('A') + 10;
  end // if
  else
    result := 0;
end; // CodePointFromChar

//***************************************************************************
//
//  FUNCTION  : CharFromCodePoint
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Used in Luhn Mod N single-character check code creation.
//
//              Returns the nth character in the set ['0'..'9','A'..'Z']
//
//              Ref : http://en.wikipedia.org/wiki/Luhn_mod_N_algorithm
//
//  UPDATED   : 2011-04-24
//
//***************************************************************************
function CharFromCodePoint(iCodePoint : integer) : AnsiChar;
begin
  if (iCodePoint <= 9) then
    result := AnsiChar(Ord('0') + iCodePoint)
  else
    if (iCodePoint <= 35) then
      result := AnsiChar(Ord('A') + iCodePoint - 10)
    else
      result := '0';
end; // CharFromCodePoint

//***************************************************************************
//
//  FUNCTION  : GetLuhnModNCheckChar
//
//  I/P       : sInput : AnsiString - The string to for which the LuhnModN
//                check character is to be generated.
//
//  O/P       : AnsiChar - The resultant check character
//
//  OPERATION : Generates the Luhn-Mod-N check character for the given string.
//
//              Operates for strings that contain only characters in ['0'..'9']
//              and ['A'..'Z'].
//
//              Uses the CodePointFromChar and CharFromCodePoint functions above.
//
//              The Luhn mod N algorithm is an extension to the Luhn algorithm
//              (also known as mod 10 algorithm) that allows it to work with
//              sequences of non-numeric characters. This can be useful when a
//              check digit is required to validate an identification string composed
//              of letters, a combination of letters and digits or even any arbitrary
//              set of characters.
//
//              Ref : http://en.wikipedia.org/wiki/Luhn_mod_N_algorithm
//
//  UPDATED   : 2011-04-24
//
//***************************************************************************
function GetLuhnModNCheckChar(sInput : AnsiString) : AnsiChar;
const
  VALID_IP_CHARS = 36;

var
  i : Integer;
  iFactor : Integer;
  iSum : Integer;
  iAddEnd : Integer;

begin
  iFactor := 2;
  iSum := 0;
  // Starting from the right and working leftwards is easier since
  // the initial "factor" will always be "2"
  for i := Length(sInput) downto 1 do
  begin
    iAddEnd := iFactor * CodePointFromChar(sInput[i]);

    // Alternate the "factor" that each "codePoint" is multiplied by
    iFactor := 3 - iFactor;

    // Sum the digits of the "addend" as expressed in base "n"
    iAddEnd := (iAddEnd div VALID_IP_CHARS) + (iAddEnd mod VALID_IP_CHARS);
    iSum := iSum + iAddEnd;
  end; // for

  // Calculate the number that must be added to the "sum" to make it divisible by "n"
  result := CharFromCodePoint((VALID_IP_CHARS - (iSum mod VALID_IP_CHARS)) mod VALID_IP_CHARS);
end; // GetLuhnModNCheckChar

//***************************************************************************
//
//  FUNCTION  : ValidLuhnModNCheckChar
//
//  I/P       : sInput : AnsiString - The string to be tested
//
//  O/P       : Boolean - TRUE if the check character/string is correct
//
//  OPERATION : Confirms whether the given string, which contains a Luhn-mod-N
//              check character at the end, has been entered correctly.
//
//              Operates for strings that contain only characters in ['0'..'9']
//              and ['A'..'Z'].
//
//              Uses the CodePointFromChar and CharFromCodePoint functions above.
//
//  UPDATED   : 2011-04-24
//
//***************************************************************************
function ValidLuhnModNCheckChar(sInput : AnsiString) : boolean;
const
  VALID_IP_CHARS = 36;

var
  i : Integer;
  iFactor : Integer;
  iSum : Integer;
  iAddEnd : Integer;

begin
  iFactor := 1;
  iSum := 0;

  // Starting from the right, work leftwards
  // Now, the initial "factor" will always be "1" since the last character is the check character
  for i := Length(sInput) downto 1 do
  begin
    iAddEnd := iFactor * CodePointFromChar(sInput[i]);

    // Alternate the "factor" that each "codePoint" is multiplied by
    iFactor := 3 - iFactor;

    // Sum the digits of the "addend" as expressed in base "n"
    iAddEnd := (iAddEnd div VALID_IP_CHARS) + (iAddEnd mod VALID_IP_CHARS);
    iSum := iSum + iAddEnd;
  end; // for

  result := ((iSum mod VALID_IP_CHARS) = 0);
end; // ValidLuhnModNCheckChar

//***************************************************************************
//
//  FUNCTION  : AdditiveChecksum
//
//  I/P       : sInput : AnsiString - The string to be used
//
//              iSize : Integer - the size (length) of the string
//
//  O/P       : The required checksum
//
//  OPERATION : Creates an additive checksum of the given AnsiString
//
//  UPDATED   : 2016-06-30
//
//***************************************************************************
function AdditiveChecksum(sInput : AnsiString;
                          iSize : integer) : Integer; overload;
var
  n : Integer;

begin
  result := 0;
  for n := 1 to iSize do
    result := result + Ord(sInput[n]);
end;

//***************************************************************************
//
//  FUNCTION  : AdditiveChecksum
//
//  I/P       : sInput : array of AnsiChar - The string to be used
//
//              iSize : Integer - the size (length) of the string
//
//  O/P       : The required checksum
//
//  OPERATION : Creates a 8-bit xor checksum of the given array of Ansichar
//
//  UPDATED   : 2016-06-30
//
//***************************************************************************
function AdditiveChecksum(sInput : array of AnsiChar;
                     iSize : integer) : Integer; overload;
var
  n : Integer;

begin
  result := 0;
  for n := 0 to iSize-1 do
    result := result + Ord(sInput[n]);
end; // XORChecksum

//***************************************************************************
//
//  FUNCTION  : XORChecksum
//
//  I/P       : sInput : AnsiString - The string to be used
//
//              iSize : Integer - the size (length) of the string
//
//  O/P       : The required checksum
//
//  OPERATION : Creates an 8-bit xor checksum of the given AnsiString
//
//  UPDATED   : 2013-09-13
//
//***************************************************************************
function XORChecksum(sInput : AnsiString;
                     iSize : integer) : Integer; overload;
var
  n : Integer;

begin
  result := 0;
  for n := 1 to iSize do
    result := result xor Ord(sInput[n]);
end; // XORChecksum

//***************************************************************************
//
//  FUNCTION  : XORChecksum
//
//  I/P       : sInput : array of AnsiChar - The string to be used
//
//              iSize : Integer - the size (length) of the string
//
//  O/P       : The required checksum
//
//  OPERATION : Creates a 8-bit xor checksum of the given array of Ansichar
//
//  UPDATED   : 2013-09-13
//
//***************************************************************************
function XORChecksum(sInput : array of AnsiChar;
                     iSize : integer) : Integer; overload;
var
  n : Integer;

begin
  result := 0;
  for n := 0 to iSize-1 do
    result := result xor Ord(sInput[n]);
end; // XORChecksum

//***************************************************************************
//
//  FUNCTION  : ExtractCorSCSeparatedElement
//
//  I/P       : var sAddress : string
//
//  O/P       : string
//
//  OPERATION : Extracts the next field from a comma or semi-colon delimited
//              string.
//
//  UPDATED   : 2015-11-26
//
//***************************************************************************
function ExtractCorSCSeparatedElement(var sInput : string) : String;
begin
  if ((Pos(';',sInput) = 0) and
      (Pos(',',sInput) = 0)) then
  begin
    result := sInput;
    sInput := '';
  end
  else
  if ((Pos(';',sInput) = 0) and
      (Pos(',',sInput) > 0)) then
    result := ExtractAndTrim(sInput,',')
  else
    if ((Pos(',',sInput) = 0) and
        (Pos(';',sInput) > 0)) then
      result := ExtractAndTrim(sInput,';')
    else
      if (Pos(';',sInput) < Pos(',',sInput)) then
        result := ExtractAndTrim(sInput,';')
      else
        result := ExtractAndTrim(sInput,',');
end; // ExtractCorSCSeparatedElement

//***************************************************************************
//
//  FUNCTION  : ValidEmailAddress
//
//  I/P       : sAddress : String - The email address to test
//
//  O/P       : boolean : TRUE if the email address appears to be of a valid
//                format.
//
//  OPERATION : As far as can be reasonably checked, test the validity of a
//              given email address.
//
//              See https://www.rfc-editor.org/rfc/rfc5322
//
//              Pre-2022-02-22, the Rexex was
//              '^[a-zA-Z0-9.%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$'
//              I modified this as per rfc5322, but the second part of the
//              domain may require further modification. For absolute correctness,
//              there is also the matter of quotes in addresses.
//
//  UPDATED   : 2023-02-22
//
//***************************************************************************
function ValidEmailAddress(sAddress : string) : boolean;
begin
  result := (
    TRegEx.Match(
      sAddress, '^[!-Z^-~]+@[!-Z^-~]+\.[A-Za-z]{2,}$'
    ).Index = 1
  ) and (
    Pos(
      '..',sAddress
    ) = 0
  );
end; // ValidEmailAddress

//***************************************************************************
//
//  FUNCTION  : ValidPhoneNumber
//
//  I/P       : phonNumber : String - The phone number to test
//
//  O/P       : Boolean - TRUE if acceptable
//
//  OPERATION : Phone number must be of form
//                  '+' <country prefix> + <number>
//              with no spaces, and at least 5 number long.
//
//  UPDATED   : 2020-06-29
//
//***************************************************************************
function ValidPhoneNumber(phoneNumber : string) : boolean;
begin
  result := (TRegEx.Match(phoneNumber, '^[\+][0-9]{5,}$').Index = 1);
end; // ValidEmailAddress

//***************************************************************************
//
//  FUNCTION  : ValidEmailAddresses
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Checks the validity of one or more email addresses, separated
//              by commas or semi-colons.
//
//  UPDATED   : 2015-11-26
//
//***************************************************************************
function ValidEmailAddresses(sAddress : string) : boolean;
begin
  // Initialise
  if (sAddress <> '') then
    result := TRUE
  else
    result := FALSE;

  while ((sAddress > '') and
         (result)) do
    result := ValidEmailAddress(ExtractCorSCSeparatedElement(sAddress));
end;

//***************************************************************************
//
//  FUNCTION  : GUIDDegrouping
//
//  I/P       : guid : String - The GUID, which may include curly braces ('{', '}')
//                and hyphens ('-')
//
//  O/P       : String - The GUID as an unbroken hexadecimal string.
//
//  OPERATION : Converts a GUID into the upper-case hexadecimal digits only.
//
//  UPDATED   : 2019-02-10
//
//***************************************************************************
function GUIDDegrouping(guid : String) : String;
begin
  result := guid.ToUpper;
  result := SearchAndReplace(result, '{', '');
  result := SearchAndReplace(result, '}', '');
  result := SearchAndReplace(result, '-', '');
end; // GUIDDegrouping

//***************************************************************************
//
//  FUNCTION  : GUID2Grouping
//
//  I/P       : guid : String - The GUID, which may include curly braces ('{', '}')
//                and hyphens ('-')
//
//  O/P       : String - The GUID in 8 groups of 4 characters, separated by
//                hyphens.
//
//  OPERATION : Converts a GUID into the form
//                XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
//              which may be more easily visually parsed and verbally conveyed.
//
//  UPDATED   : 2019-02-10
//
//***************************************************************************
function GUID2Grouping(guid : String) : String;
begin
  result := '';
  guid := GUIDDegrouping(guid);
  if (Length(guid) = 32) then
  begin
    result := Copy(guid, 1, 4) + '-' +
              Copy(guid, 5, 4) + '-' +
              Copy(guid, 9, 4) + '-' +
              Copy(guid, 13, 4) + '-' +
              Copy(guid, 17, 4) + '-' +
              Copy(guid, 21, 4) + '-' +
              Copy(guid, 25, 4) + '-' +
              Copy(guid, 29, 4);
  end; // if
end; // GUID2Grouping

//***************************************************************************
//
//  FUNCTION  : BreakText
//
//  I/P       : theText : String - The text to be split
//
//              breakString : String - The string to insert at breaks.
//
//              linesRequired : Integer - The number of sections into which
//                the string must be split.
//
//  O/P       : String - The original string, with splits inserted as required.
//
//  OPERATION : Breaks a given string, at spaces, into a maximum of the
//              required number of lines, inserting the given break in place
//              of the substituted spaces.
//
//              At the moment (2019-09-03) I only need to be able to divide a
//              string into 2 (for column titles). Maybe later, when I have time
//              I can write an algorithm that intelligently divides a string
//              into n lines.
//
//  UPDATED   : 2019-09-03
//
//***************************************************************************
function BreakText(theText : String;
                   breakString : String;
                   linesRequired : Integer) : String;
var
  n : Integer;
  idealSegmentLength : Integer;
  words : TStringDynArray;
  breakOffset : array of Integer;
  breakAfterWord : Integer;
  bestBreakOffset : Integer;
  posBreaks : Integer;

begin
  result := theText;

  if ((linesRequired > 1) and
      (linesRequired <= 2)) then
  begin
    // Ensure that there are no double spaces
    while (Pos('  ', theText) > 0) do
    begin
      theText := ReplaceStr(theText, '  ', ' ');
    end; // while

    SetLength(words, Count_Chars(theText, ' ') + 1);
    if (Length(words) > 1) then
    begin
      SetLength(breakOffset, Length(words)-1);

      words := SplitString(theText, ' ');

      idealSegmentLength := Length(theText) div linesRequired;

      // Locate the position of spaces in the original text
      posBreaks := 0;
      for n := 0 to Length(breakOffset)-1 do
      begin
        breakOffset[n] := posBreaks + Length(words[n]);
        posBreaks := posBreaks + Length(words[n]) + 1;
      end;

      // Since, at the moment, the algorithm is only wanting to split the
      // string into 2 lines, we are only looking for the single best break point
      bestBreakOffset := Length(result);
      breakAfterWord := -1;
      for n := 0 to Length(breakOffset)-1 do
      begin
        if (Abs(breakOffset[n] - idealSegmentLength) < bestBreakOffset) then
        begin
          breakAfterWord := n;
          bestBreakOffset := Abs(breakOffset[n] - idealSegmentLength);
        end; // if
      end; // for

      if (breakAfterWord >= 0) then
      begin
        result := '';
        for n := 0 to Length(words)-2 do
        begin
          result := result + words[n];
          if (n = breakAfterWord) then
          begin
            result := result + breakString;
          end // if
          else
          begin
            result := result + ' ';
          end;
        end; // for
        result := result + words[Length(words)-1];
      end;
    end; // if
  end; // if
end; // BreakText

//***************************************************************************
//
//  FUNCTION  : IsASCIIOnly
//
//  I/P       : test : AnsiString - The string to be tested
//
//              printable : Boolean = FALSE - TRUE if the characters must be
//                in the range of $20 to $7F inclusive
//
//  O/P       :
//
//  OPERATION : Check if a given AnsiString contains only ASCII characters
//              (i.e. in the range of $00 to $7F inclusive)
//
//              Optionally, only printable ASCII characters (i.e. in the range
//              of $20 to $7F inclusive.).
//
//  UPDATED   : 2024-02-29
//
//***************************************************************************
function IsASCIIOnly(test : AnsiString;
                     printable : Boolean = FALSE) : Boolean;
var
  n : Integer;

begin
  Result := TRUE;
  for n := Length(test) downto 1 do
  begin
    if ((test[n] > #127) or
        ((printable) and (test[n] < #32)))  then
    begin
      Result := FALSE;
      Exit;
    end;
  end;
end; // IsASCIIOnly

//***************************************************************************
//
//  FUNCTION  : JoinStrings
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2019-09-22
//
//***************************************************************************
function JoinStrings(theStrings : array of String;
                     inBetween : String) : String;
var
  n : Integer;

begin
  result := '';
  n := 0;
  while (n < Length(theStrings)) do
  begin
    if (theStrings[n] <> '') then
    begin
      result := result + theStrings[n] + inBetween;
    end; // if
    Inc(n);
  end;
  // Remove the trailing inBetween string, if it exists
  if (Copy(result, Length(result) - Length(inBetween) + 1, Length(inBetween)) = inBetween) then
  begin
    result := Copy(result, 1, Length(result) - Length(inBetween));
  end; // if
end; // JoinStrings

//***************************************************************************
//
//  FUNCTION  : StringHasCharacters
//
//  I/P       : theString : String - The string to be tested
//
//              theCharacters : TSysCharSet - the set of characters to check for.
//
//              only : Boolean - TRUE if the string may contain no other characters
//
//  O/P       : Boolean
//
//  OPERATION : Test if the given string has ONLY characters in the given set,
//              or if the given string has at least one character in the given set.
//
//  UPDATED   : 2019-11-23
//
//***************************************************************************
function StringHasCharacters(const theString : AnsiString;
                             const theCharacters : TSysCharSet;
                             const only : Boolean) : Boolean; overload;
var
  i: integer;

begin
  result := only;

  i := 1;
  while (i <= Length(theString)) do
  begin
    if (only) then
    begin
      if (not CharInSet(theString[i], theCharacters)) then
      begin
        result := false;
        exit;
      end; // if
    end // if
    else
    begin
      if (CharInSet(theString[i], theCharacters)) then
      begin
        result := TRUE;
        exit;
      end; // if
    end;
    Inc(i);
  end; // while
end; // StringHasCharacters

function StringHasCharacters(const theString : String;
                             const theCharacters : TArray<Char>;
                             const only : Boolean) : Boolean; overload;
var
  i: integer;

begin
  result := only;

  i := 1;
  while (i <= Length(theString)) do
  begin
    if (only) then
    begin
      if (not theString[i].IsInArray(theCharacters)) then
      begin
        result := false;
        exit;
      end; // if
    end // if
    else
    begin
      if (theString[i].IsInArray(theCharacters)) then
      begin
        result := TRUE;
        exit;
      end; // if
    end;
    Inc(i);
  end; // while
end; // StringHasCharacters

//***************************************************************************
//
//  FUNCTION  : StringIncludes
//
//  I/P       : theString : AnsiString / String - the string to test
//
//              lower_case : Boolean - TRUE if string must contain at least one
//                lower case letter
//
//              upper_case : Boolean- TRUE if string must contain at least one
//                upper case letter
//
//              numbers : Boolean- TRUE if string must contain at least one
//                number
//
//              special : Boolean- TRUE if string must contain at least one
//                special character from the following set
//
//              special_set : TSysCharSet / TArray<Char> - Set of required specail
//                characters.
//
//  O/P       : Boolean;
//
//  OPERATION : Check that the string contains at least one character from
//              each of the indicated sets of characters.
//
//  UPDATED   : 2024-11-11
//
//***************************************************************************
function StringIncludes(const theString : AnsiString;
                        const needs_lower : Boolean;
                        const needs_upper : Boolean;
                        const needs_number : Boolean;
                        const needs_special : Boolean;
                        const special_set : TSysCharSet) : Boolean; overload;
const
  setLower : TSysCharSet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
                                 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
  setUpper : TSysCharSet = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
                                 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
  setNumbers : TSysCharSet = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

var
  n: Integer;
  found_lower : Boolean;
  found_upper : Boolean;
  found_number : Boolean;
  found_special : Boolean;

begin
  found_lower := not needs_lower;
  found_upper := not needs_upper;
  found_number := not needs_number;
  found_special := not needs_special;

  if (needs_lower) then
  begin
    for n := 1 to Length(theString) do
    begin
      if (CharInSet(theString[n], setLower)) then
      begin
        // A lower case character has been found
        found_lower := TRUE;
        Break;
      end;
    end; // for
  end;

  if (needs_upper) then
  begin
    for n := 1 to Length(theString) do
    begin
      if (CharInSet(theString[n], setUpper)) then
      begin
        // An upper case character has been found
        found_upper := TRUE;
        Break;
      end;
    end; // for
  end;

  if (needs_number) then
  begin
    for n := 1 to Length(theString) do
    begin
      if (CharInSet(theString[n], setNumbers)) then
      begin
        // A number character has been found
        found_number := TRUE;
        Break;
      end;
    end; // for
  end;

  if (needs_special) then
  begin
    for n := 1 to Length(theString) do
    begin
      if (CharInSet(theString[n], special_set)) then
      begin
        // A special character has been found
        found_special := TRUE;
        Break;
      end;
    end; // for
  end; // if

  Result := (found_lower) and
            (found_upper) and
            (found_number) and
            (found_special);
end;

function StringIncludes(const theString : String;
                        const needs_lower : Boolean;
                        const needs_upper : Boolean;
                        const needs_number : Boolean;
                        const needs_special : Boolean;
                        const special_set : TArray<Char>) : Boolean; overload;
const
  setLower : TArray<Char> = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
                             'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
  setUpper : TArray<Char> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
                             'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
  setNumbers : TArray<Char> = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

var
  n: Integer;
  found_lower : Boolean;
  found_upper : Boolean;
  found_number : Boolean;
  found_special : Boolean;

begin
  found_lower := not needs_lower;
  found_upper := not needs_upper;
  found_number := not needs_number;
  found_special := not needs_special;

  if (needs_lower) then
  begin
    for n := 1 to Length(theString) do
    begin
      if (theString[n].IsInArray(setLower)) then
      begin
        // A lower case character has been found
        found_lower := TRUE;
        Break;
      end;
    end; // for
  end;

  if (needs_upper) then
  begin
    for n := 1 to Length(theString) do
    begin
      if (theString[n].IsInArray(setUpper)) then
      begin
        // An upper case character has been found
        found_upper := TRUE;
        Break;
      end;
    end; // for
  end;

  if (needs_number) then
  begin
    for n := 1 to Length(theString) do
    begin
      if (theString[n].IsInArray(setNumbers)) then
      begin
        // A number character has been found
        found_number := TRUE;
        Break;
      end;
    end; // for
  end;

  if (needs_special) then
  begin
    for n := 1 to Length(theString) do
    begin
      if (theString[n].IsInArray(special_set)) then
      begin
        // A special character has been found
        found_special := TRUE;
        Break;
      end;
    end; // for
  end; // if

  Result := (found_lower) and
            (found_upper) and
            (found_number) and
            (found_special);
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       : items : Integer - The count of the item being displayed
//
//              noneText : String - The text to display of there are no items.
//
//              oneText : String - The text to display if there is one item.
//
//              multipleText : String - The text to display if there is more than
//                one item. This must contain a %d placeholder.
//
//  O/P       : String - The required text.
//
//  OPERATION : Provide text that may be used in describing a count of items
//
//  UPDATED   : 2021-03-30
//
//***************************************************************************
function NoneSingleMultiple(items : Integer;
                            noneText : String;
                            oneText : String;
                            multipleText : String) : String;
begin
  if (items = 0) then
  begin
    Result := noneText;
  end // if
  else if (items = 1) then
  begin
    Result := oneText;
  end // if
  else
  begin
    Result := Format(multipleText, [items]);
  end;
end; // NoneSingleMultiple

//***************************************************************************
//
//  FUNCTION    :   SortStrings
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :   2002/10/20
//
//***************************************************************************
procedure SortStrings(var sStrings : TStrings);
var
  bDone : boolean;
  iJump : Integer;
  i : Integer;
  j : Integer;
  iCount : Integer;
  sTemp : String;
begin
  iCount := sStrings.Count;
  iJump := iCount;

  while (iJump > 1) do
  begin
    iJump := iJump div 2;
    repeat
      bDone := TRUE;
      for j:= 1 to iCount - iJump do
      begin
        i := j + iJump;
        if (sStrings[j] > sStrings[j]) then
        begin
          sTemp := sStrings[i];
          sStrings[i] := sStrings[j];
          sStrings[j] := sTemp;
          bDone := FALSE;
        end; // if
      end; // for
    until (bDone);
  end; // while
(*Quick Sort - Recursive, but faster
procedure qsort(lower, upper : byte)
     var
       left, right, pivot : Byte;
     begin
         pivot:=Data[(lower+upper) div 2];
         left:=lower;
         right:=upper;

         while left<=right do
         begin
             while Data[left]  < pivot do left:=left+1;  // Parting for left
             while Data[right] > pivot do right:=right-1;// Parting for right
             if left<=right then   // Validate the change
             begin
                 swap Data[left] with Data[right];
                 left:=left+1;
                 right:=right-1;
             end;
         end;
         if right>lower then qsort(lower,right); // Sort the LEFT  part
         if upper>left  then qsort(left ,upper); // Sort the RIGHT part
     end;
*)
end; // SortStrings

//***************************************************************************
//
//  FUNCTION  :   FindIndex
//
//  I/P       : sFind (string) - The string value to be found
//
//              bCaseSensitive (boolean) - TRUE if the strings must match
//                in case.
//
//              sAvailable (TStrings) - The strings that may contain the
//                the given string.
//
//  O/P       : (integer) - -1 if no match is found, else the index to the
//                matching string.
//
//  OPERATION : Finds the index of the string in a string list that matches
//              a given string.
//
//  UPDATED   :   2005/09/12
//
//***************************************************************************
function FindIndex(sFind : String;
                   bCaseSensitive : boolean;
                   sAvailable : TStrings) : Integer;
var
  n : Integer;
begin
  result := -1;
  n := 0;
  while ((result = -1) and
         (n < sAvailable.Count)) do
    if ((sAvailable.Strings[n] = sFind) or
        ((not bCaseSensitive) and (UpperCase(sAvailable.Strings[n]) = UpperCase(sFind)))) then
      result := n
    else
      Inc(n);
end; // FindIndex

//***************************************************************************
//
//  FUNCTION  : ParseDelimited
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Splits a delimited string into individual strings in a
//              TStrings object.
//
//              Copied from
//      http://delphi.about.com/od/adptips2005/qt/parsedelimited.htm?nl=1
//
//  UPDATED   : 2005/11/25
//
//***************************************************************************
procedure ParseDelimited(const sl : TStringList;
                         const sMain : String;
                         const sDelimiter : string);
var
  dx : Integer;
  ns : String;
  txt : String;
  delta : Integer;

begin
  delta := Length(sDelimiter);
  txt := sMain + sDelimiter;
  sl.BeginUpdate;
  sl.Clear;
  try
    while Length(txt) > 0 do
    begin
      dx := Pos(sDelimiter, txt) ;
      ns := Copy(txt,0,dx-1) ;
      sl.Add(ns) ;
      txt := Copy(txt,dx+delta,MaxInt) ;
    end;
  finally
    sl.EndUpdate;
  end;
end; // ParseDelimited

//***************************************************************************
//
//  FUNCTION  : SortTStrings
//
//  I/P       : theStrings : TStrings - TStrings or TStringList of items to be
//                sorted.
//
//  O/P       : TheStrings : TStrings - Sorted!
//
//  OPERATION : from http://delphi.cjcsoft.net/viewthread.php?tid=46126
//
//  UPDATED   : 2015-10-13
//
//***************************************************************************
procedure SortTStrings(theStrings : TStrings);
var
   tmp: TStringList;

begin
  if (theStrings is TStringList) then
  begin
    TStringList(TheStrings).Sort;
  end
  else
  begin
    tmp := TStringList.Create;
    try
      // Make a copy, sort and assign
      tmp.Assign(theStrings);
      tmp.Sort;
      theStrings.Assign(tmp);
    finally
      tmp.Free;
    end;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : TStrings2String
//
//  I/P       : theStrings : TStrings
//
//              separator : String - The character/characters that separate
//                each TString item
//
//  O/P       : String - The single string containing all items
//
//  OPERATION : Create a single string comprising all the items in a given
//              TStrings, with a given separator between each item.
//
//  UPDATED   : 2016-07-25
//
//***************************************************************************
function TStrings2String(theStrings : TStrings;
                         separator : String) : String;
var
  i : Integer;

begin
  result := '';
  i := 0;
  while (i < theStrings.Count) do
  begin
    result := result + theStrings[i] + separator;
    Inc(i);
  end; // while
  // Remove the last separator
  result := Copy(result,1,Length(result) - Length(separator));
end;

//***************************************************************************
//
//  FUNCTION  : RemoveEmptyFromTString
//
//  I/P       : theStrings : TStrings - The strings to be checked
//
//  O/P       : theStrings : TStrings - All empty strings removed
//
//  OPERATION : Remove empty strings from a given TStrings.
//
//  UPDATED   : 2023-02-08
//
//***************************************************************************
procedure RemoveEmptyFromTString(theStrings : TStrings);
var
  n : integer;

begin
  n := theStrings.Count-1;
  while (n >= 0) do
  begin
    if (theStrings[n] = '') then
    begin
      theStrings.Delete(n);
    end;
    Dec(n);
  end;
end; // RemoveEmptyFromTString

//***************************************************************************
//
//  FUNCTION  : ConcatenateStrings
//
//  I/P       : theStrings : TStrings - The strings to be joined
//
//              separator : String = '' - The separator string between strings.
//
//              quotes : String = '' - Any quotations to be used around strings.
//
//  O/P       : String - The combination.
//
//  OPERATION : Produce a formatted concatenation of the strings in TStrings.
//
//              After a fashioin, this can be done with .DelimitedText, but
//              not exactly in the way that I wanted it.
//
//              e.g. it uses only a single character separator, and does some
//              intersting stuff with replacements and quoting.
//
//  UPDATED   : 2023-08-31
//
//***************************************************************************
function ConcatenateStrings(theStrings : TStrings;
                            separator : String = '';
                            quotes : String = '') : String;
var
  n : Integer;

begin
  Result := '';
  for n := 0 to theStrings.Count-1 do
  begin
    Result := Result + quotes + theStrings[n] + quotes + separator;
  end;

  // Trim off the last separator
  if (Result <> '') then
  begin
    Result := Copy(Result, 1, Length(Result) - Length(separator));
  end;
end; // ConcatenateStrings

end.
