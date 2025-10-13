unit JSON_Ops;

interface

uses
  System.JSON;

procedure AddUpdateJSONPair(pObj: TJSONObject;
                            pName: String;
                            pJSONValue: TJSONValue);
function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : TJSONValue) : boolean; overload;
function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : TJSONArray) : boolean; overload;
function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : Integer) : boolean; overload;
function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : Int64) : boolean; overload;
function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : Double) : boolean; overload;
function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : String) : boolean; overload;
function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : Boolean) : boolean; overload;

function GetJSONString(aJSONObject : TJSONObject;
                       name : String;
                       default : String) : String;
function GetJSONInteger(aJSONObject : TJSONObject;
                        name : String;
                        default : Integer) : Integer;
function GetJSONInt64(aJSONObject : TJSONObject;
                      name : String;
                      default : Int64) : Int64;
function GetJSONFloat(aJSONObject : TJSONObject;
                      name : String;
                      default : Double) : Double;
function GetJSONBoolean(aJSONObject : TJSONObject;
                        name : String;
                        default : Boolean) : Boolean;

function ExtractJSONObject(theJSON : TJSONValue;
                           objectName : String;
                           var objectValue : TJSONValue) : Boolean;
function ExtractJSONString(theJSON : TJSONValue;
                           objectName : String;
                           var objectValue : String) : Boolean;
function ExtractJSONInteger(theJSON : TJSONValue;
                            objectName : String;
                            var objectValue : Integer) : Boolean;
function ExtractJSONFloat(theJSON : TJSONValue;
                          objectName : String;
                          var objectValue : Extended) : Boolean;
function ExtractJSONBoolean(theJSON : TJSONValue;
                          objectName : String;
                          var objectValue : Boolean) : Boolean;
function JSONArrayString(ab : TArray<Byte>) : String;

implementation

uses
  System.Classes, System.Variants, System.SysUtils, System.Rtti,
  System.JSON.Readers, System.JSON.Types;

//***************************************************************************
//
//  FUNCTION  : AddUpdateAddUpdateJSONPairJSONValue
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2025-04-16
//
//***************************************************************************\
procedure AddUpdateJSONPair(pObj: TJSONObject;
                            pName: String;
                            pJSONValue: TJSONValue);
var
  vJsonPair: TJsonPair;

begin
  vJsonPair:= pObj.Get(pName);

  if Assigned(vJsonPair) then
  begin
    vJsonPair.JsonValue := pJSONValue;
  end // if
  else
  begin
    pObj.AddPair(pName, pJSONValue);
  end;
end; // AddUpdateJSONPair

//***************************************************************************
//
//  FUNCTION  : GotJSONValue
//
//  I/P       : aJSONObject : TJSONObject - The JSON Object that is to be examined
//
//              name : String - the name of the TJSONPair that is to be extracted
//
//              var theValue : TJSONValue - The object extracted
//                or
//              var theValue : Integer - The integer extracted
//
//  O/P       : Boolean : TRUE if the value was found and extracted
//
//  OPERATION : Attempts to extract a named value of given type from a JSON Object
//
//  UPDATED   : 2019-04-13
//
//***************************************************************************
function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : TJSONValue) : boolean; overload;
var
  jsPair : TJSONPair;
  newValue : TJSONValue;

begin
  result := FALSE;

  jsPair := aJSONObject.Get(name);
  if (jsPair <> nil) then
  begin
    newValue := jsPair.JsonValue;
    if (newValue is TJSONObject) then
    begin
      theValue := newValue;
      result := TRUE;
    end
  end;
end; // GotJSONValue

function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : TJSONArray) : boolean; overload;
var
  jsPair : TJSONPair;
  newValue : TJSONValue;

begin
  result := FALSE;

  jsPair := aJSONObject.Get(name);
  if (jsPair <> nil) then
  begin
    newValue := jsPair.JsonValue;
    if (newValue is TJSONArray) then
    begin
      theValue := TJSONArray(newValue);
      result := TRUE;
    end
  end;
end; // GotJSONValue

function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : Integer) : boolean; overload;
var
  jsPair : TJSONPair;
  jsValue : TJSONValue;

begin
  result := FALSE;

  jsPair := aJSONObject.Get(name);
  if (jsPair <> nil) then
  begin
    jsValue := jsPair.JsonValue;
    if (jsValue is TJSONString) then
    begin
      theValue := jsValue.Value.ToInteger;
      result := TRUE;
    end
  end;
end; // GotJSONValue

function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : Int64) : boolean; overload;
var
  jsPair : TJSONPair;
  jsValue : TJSONValue;

begin
  result := FALSE;

  jsPair := aJSONObject.Get(name);
  if (jsPair <> nil) then
  begin
    jsValue := jsPair.JsonValue;
    if (jsValue is TJSONNumber) then
    begin
      theValue := (jsValue as TJSONNumber).AsInt64;
      result := TRUE;
    end
  end;
end; // GotJSONValue

function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : Double) : boolean; overload;
var
  jsPair : TJSONPair;
  jsValue : TJSONValue;

begin
  result := FALSE;

  jsPair := aJSONObject.Get(name);
  if (jsPair <> nil) then
  begin
    jsValue := jsPair.JsonValue;
    if (jsValue is TJSONNumber) then
    begin
      theValue := (jsValue as TJSONNumber).AsDouble;
      result := TRUE;
    end
  end;
end; // GotJSONValue

function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : String) : boolean; overload;
var
  jsPair : TJSONPair;
  jsValue : TJSONValue;

begin
  result := FALSE;

  jsPair := aJSONObject.Get(name);
  if (jsPair <> nil) then
  begin
    jsValue := jsPair.JsonValue;
    if (jsValue is TJSONString) then
    begin
      theValue := jsValue.Value;
      result := TRUE;
    end
  end;
end; // GotJSONValue

function GotJSONValue(aJSONObject : TJSONObject;
                      name : String;
                      var theValue : Boolean) : boolean; overload;
var
  jsPair : TJSONPair;
  jsValue : TJSONValue;

begin
  result := FALSE;

  jsPair := aJSONObject.Get(name);
  if (jsPair <> nil) then
  begin
    jsValue := jsPair.JsonValue;
    if (jsValue is TJSONBool) then
    begin
      theValue := jsValue.Value.ToBoolean;
      result := TRUE;
    end
  end;
end; // GotJSONValue

//***************************************************************************
//
//  FUNCTION  : GotJSONString
//
//  I/P       : aJSONObject : TJSONObject - The JSON Object that is to be examined
//
//              name : String - the name of the TJSONPair that is to be extracted
//
//              default : String - The default return value, if the pair is not
//                found or if the pair does not represent a string.
//
//  O/P       : String : The resultant output
//
//  OPERATION : Attempts to extract a named string value from a JSON Object.
//
//  UPDATED   : 2019-04-13
//
//***************************************************************************
function GetJSONString(aJSONObject : TJSONObject;
                       name : String;
                       default : String) : String;
begin
  if (not (GotJSONValue(aJSONObject, name, result))) then
  begin
    result := default;
  end;
end; // GetJSONString

//***************************************************************************
//
//  FUNCTION  : GetJSONInteger
//
//  I/P       : aJSONObject : TJSONObject - The JSON Object that is to be examined
//
//              name : String - the name of the TJSONPair that is to be extracted
//
//              default : Integer - The default return value, if the pair is not
//                found or if the pair does not represent an integer.
//
//  O/P       : Integer : The resultant output
//
//  OPERATION : Attempts to extract a named integer value from a JSON Object.
//
//  UPDATED   : 2019-04-13
//
//***************************************************************************
function GetJSONInteger(aJSONObject : TJSONObject;
                        name : String;
                        default : Integer) : Integer;
begin
  if (not (GotJSONValue(aJSONObject, name, result))) then
  begin
    result := default;
  end;
end; // GetJSONInteger

//***************************************************************************
//
//  FUNCTION  : GetJSONInt64
//
//  I/P       : aJSONObject : TJSONObject - The JSON Object that is to be examined
//
//              name : String - the name of the TJSONPair that is to be extracted
//
//              default : Int64 - The default return value, if the pair is not
//                found or if the pair does not represent a cardinal.
//
//  O/P       : Int64 : The resultant output
//
//  OPERATION : Attempts to extract a named Int64 value from a JSON Object.
//
//  UPDATED   : 2019-12-31
//
//***************************************************************************
function GetJSONInt64(aJSONObject : TJSONObject;
                      name : String;
                      default : Int64) : Int64;
begin
  if (not (GotJSONValue(aJSONObject, name, result))) then
  begin
    result := default;
  end;
end; // GetJSONInt64

//***************************************************************************
//
//  FUNCTION  : GetJSONFloat
//
//  I/P       : aJSONObject : TJSONObject - The JSON Object that is to be examined
//
//              name : String - the name of the TJSONPair that is to be extracted
//
//              default : Double - The default return value, if the pair is not
//                found or if the pair does not represent an double.
//
//  O/P       : Double : The resultant output
//
//  OPERATION : Attempts to extract a named double value from a JSON Object.
//
//  UPDATED   : 2019-06-21
//
//***************************************************************************
function GetJSONFloat(aJSONObject : TJSONObject;
                      name : String;
                      default : Double) : Double;
begin
  if (not (GotJSONValue(aJSONObject, name, result))) then
  begin
    result := default;
  end;
end; // GetJSONFloat

//***************************************************************************
//
//  FUNCTION  : GetJSONBoolean
//
//  I/P       : aJSONObject : TJSONObject - The JSON Object that is to be examined
//
//              name : String - the name of the TJSONPair that is to be extracted
//
//              default : Boolean - The default return value, if the pair is not
//                found or if the pair does not represent an integer.
//
//  O/P       : Boolean : The resultant output
//
//  OPERATION : Attempts to extract a named boolean value from a JSON Object.
//
//  UPDATED   : 2019-04-13
//
//***************************************************************************
function GetJSONBoolean(aJSONObject : TJSONObject;
                        name : String;
                        default : Boolean) : Boolean;
begin
  if (not (GotJSONValue(aJSONObject, name, result))) then
  begin
    result := default;
  end;
end; // GetJSONBoolean

//***************************************************************************
//
//  FUNCTION  : ExtractSimpleJSONValue
//
//  I/P       : theJSON : TJSONValue - The JSON to be examined
//
//              objectName : String - The name of the object to be returned
//
//              var object TValue - The object, if found, else nil
//
//  O/P       : Boolean - TRUE if the named object is found.
//
//  OPERATION : Extracts the value of the first simple (i.e. string,
//              integer, float, boolean or null) matching named JSON
//              object from a given JSON value.
//
//  UPDATED   : 2019-04-02
//
//***************************************************************************
function ExtractedFirstJSONValue(theJSON : TJSONValue;
                                 objectName : String;
                                 var objectValue : TValue) : Boolean;
var
  sReader : TStringReader;
  jReader : TJsonTextReader;

begin
  result := FALSE;
  objectValue := nil;

  sReader := TStringReader.Create(theJSON.ToString);
  try
    jReader := TJsonTextReader.Create(sReader);
    try
      while ((jReader.Read) and
             (not result)) do
      begin
        if ((jReader.TokenType = TJsonToken.PropertyName) and
            (jReader.Value.ToString = objectName)) then
        begin
          result := TRUE;
          if ((jReader.Read) and
              ((jReader.TokenType = TJsonToken.String) or
               (jReader.TokenType = TJsonToken.Integer) or
               (jReader.TokenType = TJsonToken.Float) or
               (jReader.TokenType = TJsonToken.Boolean) or
               (jReader.TokenType = TJsonToken.Null))) then
          begin
            objectValue := jReader.Value;
          end; // if
        end; // if
      end; // while
    finally
      jReader.Free;
    end;
  finally
    sReader.Free;
  end;
end; // ExtractedFirstJSONValue

//***************************************************************************
//
//  FUNCTION  : ExtractJSONObject
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
function ExtractJSONObject(theJSON : TJSONValue;
                          objectName : String;
                          var objectValue : TJSONValue) : Boolean;
var
  sReader : TStringReader;
  jReader : TJsonTextReader;

begin
  result := FALSE;
  objectValue := nil;

  sReader := TStringReader.Create(theJSON.ToString);
  try
    jReader := TJsonTextReader.Create(sReader);
    try
//      while ((jReader.Read) and
//             (not result)) do
//      begin
//        if ((jReader.TokenType = TJsonToken.PropertyName) and
//            (jReader.Value.ToString = objectName)) then
//        begin
//          result := TRUE;
//          if ((jReader.Read) and
//              (jReader.TokenType = TJsonToken.StartObject)) then
//          begin
//            objectValue := jReader.Value.AsObject;
//          end; // if
//        end; // if
//      end; // while
    finally
      jReader.Free;
    end;
  finally
    sReader.Free;
  end;
end; // ExtractJSONObject

//***************************************************************************
//
//  FUNCTION  : ExtractJSONString
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
function ExtractJSONString(theJSON : TJSONValue;
                           objectName : String;
                           var objectValue : String) : Boolean;
var
  theValue : TValue;

begin
  if (ExtractedFirstJSONValue(theJSON, objectName, theValue)) then
  begin
    objectValue := theValue.ToString;
    result := TRUE;
  end // if
  else
  begin
    objectValue := '';
    result := FALSE;
  end;
end; // ExtractJSONString

//***************************************************************************
//
//  FUNCTION  : ExtractJSONInteger
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
function ExtractJSONInteger(theJSON : TJSONValue;
                            objectName : String;
                            var objectValue : Integer) : Boolean;
var
  theValue : TValue;

begin
  if (ExtractedFirstJSONValue(theJSON, objectName, theValue)) then
  begin
    objectValue := theValue.AsInteger;
    result := TRUE;
  end // if
  else
  begin
    objectValue := 0;
    result := FALSE;
  end;
end; // ExtractJSONInteger

//***************************************************************************
//
//  FUNCTION  : ExtractJSONFloat
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
function ExtractJSONFloat(theJSON : TJSONValue;
                          objectName : String;
                          var objectValue : Extended) : Boolean;
var
  theValue : TValue;

begin
  if (ExtractedFirstJSONValue(theJSON, objectName, theValue)) then
  begin
    objectValue := theValue.AsExtended;
    result := TRUE;
  end // if
  else
  begin
    objectValue := 0.0;
    result := FALSE;
  end;
end; // ExtractJSONFloat

//***************************************************************************
//
//  FUNCTION  : ExtractJSONBoolean
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
function ExtractJSONBoolean(theJSON : TJSONValue;
                          objectName : String;
                          var objectValue : Boolean) : Boolean;
var
  theValue : TValue;

begin
  if (ExtractedFirstJSONValue(theJSON, objectName, theValue)) then
  begin
    objectValue := theValue.AsBoolean;
    result := TRUE;
  end // if
  else
  begin
    objectValue := FALSE;
    result := FALSE;
  end;
end; // ExtractJSONBoolean

function JSONArrayString(ab : TArray<Byte>) : String;
var
  n : Integer;

begin
  Result := '[';
  for n := 0 to Length(ab) do
  begin
    Result := Result + ab[n].ToString + ',';
  end;

  Result := Copy(Result, 1, Length(Result)-1) + ']';
end;


end.
