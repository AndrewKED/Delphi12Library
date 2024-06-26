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
//  UPDATED   : 2022-07-20
//
//***************************************************************************
function GetGUIDString : String;
var
  guidSonde : TGUID;

begin
  // The long main board serial number has not yet been obtained.
  // To get a unique record, create a unique ID
  CreateGUID(guidSonde);
  Result := GUIDToString(guidSonde);
end;

end.
