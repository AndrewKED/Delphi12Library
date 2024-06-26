unit Encrypt_Ops;

interface

uses
  System.Classes, System.SysUtils;

const
  C1 = 57890;
  C2 = 23509;

function Encrypt(const S: AnsiString; Key: Word): AnsiString;
function Decrypt(const S: AnsiString; Key: Word): AnsiString;
function EncryptB(const B: TBytes; Key: Word): TBytes;
function DecryptB(const B: TBytes; Key: Word): TBytes;
function EncryptedFile(INFName, OutFName : String; Key : Word) : boolean;
function DecryptedFile(INFName, OutFName : String; Key : Word) : boolean;

implementation

//***************************************************************************
//
//  FUNCTION    : Encrypt
//
//  I/P         : const S: AnsiString - The clear text
//
//                Key: Word - The encryption key
//
//  O/P         : AnsiString - The encrypted string
//
//  OPERATION   : Encrypt a given string.
//
//                Be careful of AnsiStrings in foreign locales!
//
//  UPDATED     : 2022-09-15
//
//***************************************************************************
function Encrypt(const S: AnsiString; Key: Word): AnsiString;
var
   I: Integer;

begin
  Result := S;
  for I := 1 to Length(S) do
  begin
    Result[I] := AnsiChar(byte(S[I]) xor (Key shr 8));
    Key := (byte(Result[I]) + Key) * C1 + C2;
  end;
end; // Encrypt

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function Decrypt(const S: AnsiString; Key: Word): AnsiString;
var
  I: Integer;
begin
  Result := S;
  for I := 1 to Length(S) do
  begin
    Result[I] := AnsiChar(byte(S[I]) xor (Key shr 8));
    Key := (byte(S[I]) + Key) * C1 + C2;
  end;
end; // Decrypt

//***************************************************************************
//
//  FUNCTION  : EncryptB
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
function EncryptB(const B: TBytes; Key: Word): TBytes;
var
   I: Integer;

begin
  SetLength(Result, Length(B));
  for I := 0 to Length(B)-1 do
  begin
    Result[I] := B[I] xor (Key shr 8);
    Key := (Result[I] + Key) * C1 + C2;
  end;
end; // EncryptB

//***************************************************************************
//
//  FUNCTION  : DecryptB
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
function DecryptB(const B: TBytes; Key: Word): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(B));
  for I := 0 to Length(B)-1 do
  begin
    Result[I] := B[I] xor (Key shr 8);
    Key := (B[I] + Key) * C1 + C2;
  end;
end; // DecryptB

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function EncryptedFile(INFName, OutFName : String; Key : Word) : boolean;
var
  MS, SS : TMemoryStream;
  X : Integer;
  C : Byte;
begin
// Assume that we were able not able to complete the operation
  result := FALSE;

  MS := TMemoryStream.Create;
  SS := TMemoryStream.Create;
  try
    MS.LoadFromFile(INFName);
    MS.Position := 0;
    for X := 0 to MS.Size - 1 do
    begin
      MS.Read(C, 1);
      C := (C xor (Key shr 8));
      Key := (C + Key) * C1 + C2;
      SS.Write(C,1);
    end;
    SS.SaveToFile(OutFName);
// Flag that the operation was successfully completed
    result := TRUE;
  finally
    SS.Free;
    MS.Free;
  end;
end; // EncryptedFile

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function DecryptedFile(INFName, OutFName : String; Key : Word) : boolean;
var
  MS, SS : TMemoryStream;
  X : Integer;
  C, O : Byte;
begin
// Assume that we were able not able to complete the operation
  result := FALSE;

  MS := TMemoryStream.Create;
  SS := TMemoryStream.Create;
  try
    MS.LoadFromFile(INFName);
    MS.Position := 0;
    for X := 0 to MS.Size - 1 do
    begin
      MS.Read(C, 1);
      O := C;
      C := (C xor (Key shr 8));
      Key := (O + Key) * C1 + C2;
      SS.Write(C,1);
    end;
    SS.SaveToFile(OutFName);
// Flag that the operation was successfully completed
    result := TRUE;
  finally
    SS.Free;
    MS.Free;
  end;
end; // DecryptedFile

end.
