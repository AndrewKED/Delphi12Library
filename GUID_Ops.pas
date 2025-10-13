unit GUID_Ops;

interface

function GetGUIDString : String;

implementation

uses
  System.SysUtils;

//***************************************************************************
//
//  FUNCTION  : GetGUIDString
//
//  I/P       : None
//
//  O/P       : String - The GUID string
//
//  OPERATION : Provide a globally unique identifier, in string form.
//
//  UPDATED   : 2025-08-27
//
//***************************************************************************
function GetGUIDString : String;
var
  aGUID : TGUID;

begin
  CreateGUID(aGUID);
  Result := GUIDToString(aGUID);
end;

end.
