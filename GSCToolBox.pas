unit GSCToolbox;

{$DEFINE VERSION7}

interface

uses Windows, SysUtils, Dialogs, Registry, StdCtrls, classes, dbTables {$IFDEF VERSION7}, variants{$ENDIF};

const CDaysInMonth : Array[1..12] of byte = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

// variants;

type TGSCToolbox = class
       private


       public
         Reg : TRegistry;
         GSCRootKey   : HKEY;
         GSCRootValue : String;
         AlterTable_Fields, AlterTable_Defaults : TStrings;

         DefaultRegPath : String;

         function ReadRegistry(Value : String; Default : Variant) : Variant;
         function ReadRegistryFromKey(Key, Value : String; Default : Variant) : Variant;
         function WriteRegistry(Value : String; DataValue : Variant) : Boolean;
         procedure InitialiseRegistry(ApplicationName : String);
         function GetFileTranslation(const Filename: string; FullName: Boolean{$IFNDEF VERSION3} = FALSE{$ENDIF}): string;
         function GetFileResourceString(FileName,VerKey:string):string;
         procedure SetVersionStr(Filename : String; Lab : TLabel);
         function GetVersionStr(Filename: String; Build : Boolean): String;
         function LeadZero(s: variant; len : integer): string;

         procedure AlterTable_ClearLists;
         procedure AlterTable_AddField(FieldText, DefaultText : String);
         procedure AlterTable_Go(Alias, Table : String);
         function ConvertDMYtoValidDate(D, M, Y: Integer): TDateTime;
         function UnitsToJDate(ucYear, ucMonth, ucDay : Byte) : Word;
         function DaysInMonth(ucYear, ucMonth : Byte) : Byte;

         procedure GSCBackdoor(var ToUser, FromUser : String);

         function TrueFalse(b: Byte): String;
         function YesNo(b: Byte): String;
         function StringToHex(s: String): String;

         constructor Create;
         destructor Free;
       end;

//var
//    GSC : TGSCToolbox;

implementation

uses Math;

{ TGSCToolbox }

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
function TGSCToolbox.StringToHex(s : String) : String;
var HexString : String;
    i : integer;
begin
  for i := 1 to Length(s) do
    HexString := HexString + IntToHex(ord(s[i]),2);
  result := HexString;
end;


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
function TGSCToolbox.TrueFalse(b : Byte) : String;
begin
  if b > 0 then result := 'True' else result := 'False';
end;


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
function TGSCToolbox.YesNo(b : Byte) : String;
begin
  if b > 0 then result := 'Yes' else result := 'No';
end;


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
function TGSCToolbox.ConvertDMYtoValidDate(D,M,Y : Integer) : TDateTime;
var vss, s,  s1,s2,s3 : string;

function choose(s : string) : String;
begin
  if pos('Y',s) > 0 then result := IntToStr(Y)
  else if pos('M',s) > 0 then result := IntToStr(M)
  else if pos('D',s) > 0 then result := IntToStr(D);
end;

begin
  s := uppercase(ShortDateFormat);
  s1 := copy(s,1,pos(DateSeparator,s)-1); delete(s,1,pos(DateSeparator,s));
  vss := choose(s1)+DateSeparator;
  s2 := copy(s,1,pos(DateSeparator,s)-1); delete(s,1,pos(DateSeparator,s));
  vss := vss+choose(s2)+DateSeparator+choose(s);
  result := StrToDate(vss);
end;

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
function TGSCToolbox.DaysInMonth(ucYear, ucMonth : Byte) : Byte;
// Ported from Firmware code file
begin
  if (ucMonth = 2) and (ucYear mod 4 = 0) then result := 29 else
  result := CDAYSINMONTH[ucMonth];
end;


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
function TGSCToolbox.UnitsToJDate(ucYear, ucMonth, ucDay : Byte) : Word;
// Ported from Firmware code file
var c,uiTotDays : Word;
begin
  uiTotDays := 1461 * (ucYear shr 2);
  Inc(uiTotDays,(365*(ucYear mod 4)));
  if (ucYear mod 4) = 0 then Dec(uiTotDays);
  for c := 1 to Pred(ucMonth) do Inc(uiTotDays,DaysInMonth(ucYear,c));
  Inc(uiTotDays,ucDay);
  result := uiTotDays;
end;

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
constructor TGSCToolbox.Create;
begin
  Reg := TRegistry.Create;
  DefaultRegPath := 'SOFTWARE\GSC\';
end;

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
destructor TGSCToolbox.Free;
begin
  if Assigned(Reg) then
    begin
      Reg.CloseKey;
      Reg.Free;
      Reg := nil;
    end;
end;

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
procedure TGSCToolbox.InitialiseRegistry(ApplicationName: String);
begin
  if ApplicationName <> '' then
  begin
    GSCRootKey := HKEY_LOCAL_MACHINE;
    GSCRootValue := DefaultRegPath + ApplicationName;
    with Reg do
    begin
      RootKey := GSCRootKey;
      OpenKey(GSCRootValue,true);
    end; // with
  end // if
  else
    ShowMessage('GSCToolbox: Registry not initialised - blank ''ApplicationName'' argument');
end;

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
function TGSCToolbox.ReadRegistry(Value: String;
  Default: Variant): Variant;
begin
  if Reg.ValueExists(Value) then
    begin
    case VarType(Default) of
      varEmpty, varNull, varUnknown, varError, varOleStr, varDispatch,
      varTypeMask, varArray, varByRef,
      varVariant                        : ShowMessage('GSCToolbox: Unable to load ['+Value+'] as default type is unsupported');
      varSmallint, varByte, varInteger  : result := Reg.ReadInteger(Value);
      varSingle, varDouble              : result := Reg.ReadFloat(Value);
      varCurrency                       : result := Reg.ReadCurrency(Value);
      varDate                           : result := Reg.ReadDateTime(Value);
      varBoolean                        : result := Reg.ReadBool(Value);
      varString                         : result := Reg.ReadString(Value);
    end;
    if (Value = '') and (result = '') then result := Default;
    end
  else result := Default;
end;


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
function TGSCToolbox.WriteRegistry(Value: String; DataValue: Variant): Boolean;
begin
  result := true;
  try
    case VarType(DataValue) of
      varEmpty, varNull, varUnknown, varError, varOleStr, varDispatch,
      varTypeMask, varArray, varByRef,
      varVariant                        : ShowMessage('GSCToolbox: Unable to write ['+Value+'] as DataValue type is unsupported');
      varSmallint, varByte, varInteger  : Reg.WriteInteger(Value, DataValue);
      varSingle, varDouble              : Reg.WriteFloat(Value, DataValue);
      varCurrency                       : Reg.WriteCurrency(Value, DataValue);
      varDate                           : Reg.WriteDateTime(Value, DataValue);
      varBoolean                        : Reg.WriteBool(Value, DataValue);
      varString                         : Reg.WriteString(Value, DataValue);
    end
  except on E:Exception do
    begin
      ShowMessage('GSCToolbox: Exception occured writing Registry value ['+Value+']'#13#10+
                   E.Message);
      result := false;
    end;
  end;
end;

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
function TGSCToolBox.GetFileTranslation(const Filename: string; FullName: Boolean{$IFNDEF VERSION3} = FALSE{$ENDIF}): string;
var
  VerInfSize, Sz: Cardinal;
  LangID: Pointer;
  VerInfo: Pointer;
  Buf: array[0..255] of char;
begin
  Result := '';
  if FileExists(Filename) then begin
    VerInfSize := GetFileVersionInfoSize(PCHAR(Filename), Sz);
    if VerInfSize > 0 then begin
      VerInfo := Allocmem(VerInfSize);
      try
        GetFileVersionInfo(PCHAR(Filename), 0, VerInfSize, VerInfo);
        VerQueryValue(VerInfo, '\VarFileInfo\Translation', LangID, Sz);
        if LangID <> NIL then
        case Ord(FullName) of
          0: Result := IntToHex(MakeLong(HiWord(Longint(LangID^)),LoWord(Longint(LangID^))), 8);
          1: if VerLanguageName(DWORD(LangID^), Buf, SizeOf(Buf)) > 0
             then Result := Buf;
        end;
      finally
        FreeMem(VerInfo);
      end;
    end;
  end;
end;

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
function TGSCToolbox.GetFileResourceString(FileName,VerKey:string):string;
var Dummy,InfoSize,BufferSize:dword;
    Info:pointer;
    Buffer:PChar;
    LocaleString : string;
begin
  LocaleString := GetFileTranslation(Filename,False);
  Result:='';
  InfoSize:=GetFileVersionInfoSize(PChar(FileName),Dummy);
  if (InfoSize>0) then
  begin
    GetMem(Info,InfoSize);
    try
      if GetFileVersionInfo(PChar(FileName),0,InfoSize,Info) then
        if VerQueryValue(Info,PChar('\\StringFileInfo\\'+LocaleString+'\\'+VerKey),
                         Pointer(Buffer),BufferSize) then
          Result:=Buffer
        else
          Result:=''
      else
        Result:='';
    finally
      FreeMem(Info,InfoSize)
    end; // try-finally for GetMem
  end // if (InfoSize>0)
  else
    Result:='';
end; // function GetFileResourceString

//initialization
//  GSC := TGSCToolbox.Create;

//finalization
//  FreeAndNil(GSC);

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
procedure TGSCToolbox.SetVersionStr(Filename: String; Lab: TLabel);
var str, Global_Version : string;
begin
  str := GetFileResourceString(Filename,'FileVersion');
  Global_Version := copy(str,1,pos('.',str));
  Delete(str,1,pos('.',str));
  Delete(str,1,pos('.',str));
  Global_Version := Global_Version + LeadZero(copy(str,1,pos('.',str)-1),2);
  Delete(str,1,pos('.',str));

  Lab.Hint := 'Build: '+str;
  Lab.ShowHint := true;
  Lab.caption := 'Version '+Global_Version
end;

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
function TGSCToolbox.LeadZero(s: variant; len : integer): string;
begin
  if vartype(s) = varString
  then
    begin
      result := s;
      while length(result) < len do result := '0'+result;
    end
  else if vartype(s) = varInteger then
    begin
      result := inttostr(s);
      while length(result) < len do result := '0'+result;
    end;
end;

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
function TGSCToolbox.GetVersionStr(Filename: String; Build : Boolean): String;
var str, Global_Version : string;
begin
  str := GetFileResourceString(Filename,'FileVersion');
  Global_Version := copy(str,1,pos('.',str));
  Delete(str,1,pos('.',str));
  Delete(str,1,pos('.',str));
  Global_Version := Global_Version + LeadZero(copy(str,1,pos('.',str)-1),2);
  Delete(str,1,pos('.',str));
  result := Global_Version;
  if Build then result := result + '.'+Str;
end;


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
procedure TGSCToolbox.AlterTable_AddField(FieldText, DefaultText: String);
begin
  if not Assigned(AlterTable_Fields)   then AlterTable_Fields := TStringList.Create;
  if not Assigned(AlterTable_Defaults) then AlterTable_Defaults := TStringList.Create;

  if AlterTable_Fields.IndexOf(FieldText) = -1 then
    begin
      AlterTable_Fields.Add(FieldText);
      AlterTable_Defaults.Add(DefaultText);
    end;

end;

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
procedure TGSCToolbox.AlterTable_Go(Alias, Table: String);
var c : integer;
    s : string;

function GetFieldName(s : String; WithQuotes : Boolean{$IFNDEF VERSION3} = TRUE{$ENDIF}) : String;
begin
  result := copy(AlterTable_Fields[c],1,pos(' ',AlterTable_Fields[c])-1);
  if not WithQuotes then
    result := copy(result,2,length(result)-2);
end;

begin
  with TQuery.Create(nil) do
    begin
      DatabaseName := Alias;
      SQL.Text := 'SELECT * FROM "'+Table+'"';
      Open;

      c := 0;

      while (c < AlterTable_Fields.Count) do
        begin
          if not assigned(FindField(GetFieldName(AlterTable_Fields[c], FALSE))) then inc(c)
          else
            begin
              AlterTable_Fields.Delete(c);
              AlterTable_Defaults.Delete(c);
            end;
        end;

      Close;

      if (AlterTable_Fields.Count > 0) then
        begin
          for c := 0 to (AlterTable_Fields.Count-1) do
            begin
              SQL.Text := 'ALTER TABLE "'+Table+'" ADD "'+Table+'".'+AlterTable_Fields[c];
              ExecSQL;
            end;

          SQL.Text := 'UPDATE "'+Table+'" T SET ';

          for c := 0 to (AlterTable_Defaults.Count-1) do
            SQL.Text := SQL.Text + 'T.'+GetFieldName(AlterTable_Fields[c],true) +' = '+AlterTable_Defaults[c]+', ';

          SQL.Text := copy(SQL.Text,1,length(SQL.Text)-4);
          ExecSQL;
        end;
      Free;
    end;
end;

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
procedure TGSCToolbox.AlterTable_ClearLists;
begin
  if not Assigned(AlterTable_Fields)   then AlterTable_Fields := TStringList.Create;
  if not Assigned(AlterTable_Defaults) then AlterTable_Defaults := TStringList.Create;

  AlterTable_Fields.Clear;
  AlterTable_Defaults.Clear;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : ToUser (string) - A random 5-digit number
//
//              FromUser (string) - A manipulation of TUser
//
//  UPDATED   :
//
//***************************************************************************
procedure TGSCToolbox.GSCBackdoor(var ToUser, FromUser: String);
var i : integer;
begin
  randomize;
  repeat
    str(random(65535),ToUser);
  until length(ToUser) = 5;
  FromUser := '     ';
  for i:=1 to length(ToUser) do
    begin
      if byte(ToUser[6-i])-48>4 then
        FromUser[i]:=char((byte(ToUser[6-i])-48)-i+48)
      else
        FromUser[i]:=char((byte(ToUser[6-i])-48)+i+48);
    end;

end;

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
function TGSCToolbox.ReadRegistryFromKey(Key, Value: String;
  Default: Variant): Variant;
var OldKey : String;
    OldRoot : HKEY;
begin
  with Reg do
    begin
      OldKey := CurrentPath;
      OldRoot := CurrentKey;
      CloseKey;
      RootKey := HKEY_LOCAL_MACHINE;
      Key := OldKey+'\'+Key;
      if KeyExists(Key) then
        if OpenKey(Key,false) then
          result := ReadRegistry(Value,Default)
        else result := default
      else result := default;
      CloseKey;
      RootKey := HKEY_LOCAL_MACHINE;
      OpenKey(OldKey,false);

    end;
end;

end.



