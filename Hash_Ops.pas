unit Hash_Ops;

interface

uses
  System.SysUtils, System.Hash;

function HashString(theString : String;
                    AHashVersion: THashSHA2.TSHA2Version = THashSHA2.TSHA2Version.SHA256) : String;
function HashFile(filename : String;
                  AHashVersion: THashSHA2.TSHA2Version = THashSHA2.TSHA2Version.SHA256) : String;

implementation

uses
  System.Classes;

//***************************************************************************
//
//  FUNCTION  : HashString
//
//  I/P       : theString : String - The string to be hashed.
//
//              AHashVersion: THashSHA2.TSHA2Version = THashSHA2.TSHA2Version.SHA256
//                - The hash type to be used.
//
//  O/P       : String - The hash
//
//  OPERATION : Return the hash of the given string
//
//  UPDATED   : 2020-04-01
//
//***************************************************************************
function HashString(theString : String;
                    AHashVersion: THashSHA2.TSHA2Version = THashSHA2.TSHA2Version.SHA256) : String;
var
  buffer : TBytes;
  theHash : THashSHA2;

begin
  theHash := THashSHA2.Create(SHA256);
  Result := theHash.GetHashString(theString);
end;

//***************************************************************************
//
//  FUNCTION  : HashFile
//
//  I/P       : filename : String - The full name of the file to be hashed.
//
//              AHashVersion: THashSHA2.TSHA2Version = THashSHA2.TSHA2Version.SHA256
//                - The hash type to be used.
//
//  O/P       : String - The hash
//
//  OPERATION : Return the hash of the given file
//
//  UPDATED   : 2020-04-01
//
//***************************************************************************
function HashFile(filename : String;
                  AHashVersion: THashSHA2.TSHA2Version = THashSHA2.TSHA2Version.SHA256) : String;
var
  theHash : THashSHA2;

begin
  theHash := THashSHA2.Create(SHA256);
  Result := theHash.GetHashStringFromFile(filename);
end;



end.
