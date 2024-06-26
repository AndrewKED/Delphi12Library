unit GSCUtils;

interface
uses graphics, SysUtils,classes, Forms,
     WinTypes, WinProcs, Messages, Controls, DBTables, db, Dialogs, menus, Registry, stdctrls,
     Variants, wwdbgrid,dbgrids, inifiles,math, FileCtrl  {$IFDEF MULTILANG}, IvDictio{$ENDIF};


  type
    TTypeCase = (tcUpper, tcLower, tcPropper);

  function IntToColor(Int : Integer) : LongInt;
  function ConvertStrToStyle(S : String) : TFontStyles;
  function ConvertStyleToStr(Style : TFontStyles) : String;
  function GetShortDay(instring : string; TCase : TTypeCase) : string;

  {menu functions}
  procedure CopyMainMenu(frommenu, tomenu : tmenu);
  procedure SetWholeMenu(Items : TMenuItem; State : Boolean);
  function StripCaption(S : String) : String;

  {string fuctions}
  function GetName(Teststr : string) : string;
  function GetValue(TestStr: string) : string;
  function StripFileExt(TestStr : string) : string;
  function UTStrInc(var str : string) : string;
  function booltostr(value : boolean; TrueValue , FalseValue : string) : string;
  function booltoYesNo(value : boolean) : string;
  function ExtFormat(const FormatStr: string; const Args: array of const): string;
  function PadLeft(Str : string; StrLength : integer; Ch : char) : string;
  function PadRight(const Str : string; StrLength : integer; Ch : char) : string;
  function GetPathFromFilename(const Str : string) : string;
  function FormatAddressDateString(const str : string;Date : tdatetime; Address : integer) : string;
  function VerticalStr(ch : char;str : string; lines : integer) : string;
  function VerticalStrHeader(ch : char;str, header : string; lines : integer) : string;
  function GetFirstWord(str : string; prechar, postchar : char) : string;
  function GetNWord(str : string; N : integer; prechar, postchar : char) : string;
  function DelFirstWord(str : string; prechar, postchar : char) : string;
  function GetAppPath : string;
  function NBCDToStr(Value : char) : string;
  function StrToNBCD(Str :string) : char;
  function IntToNBCD(Value : byte) : char;
  function NBCDToInt(Value : char) : Byte;
  function IntToNBCDString(Value : byte) :string;
  function IntToBinString(Value : Cardinal; Length : integer;RightAlighn : boolean) : string;
  procedure InitString(var str : string;const NewLength : integer;const All : boolean);
  function  deletestring(const str : string; from, length : integer) : string;
  function  SetDateRange(DateField : string; Startdate, EndDate : tdatetime; IncTime : boolean) : string;
  function SetSQLDateRange(DateField, Format : string;Startdate, EndDate : tdatetime) : string;
  procedure OrFilterStr(var FilterString : string; AddString : string);
  procedure AndFilterStr(var FilterString : string; AddString : string);
  procedure Add2Filter(pos : integer; Str : string);
  function  GetFilterDateStr(DateTime : tdatetime; IncTime : boolean) : string;
  function Str2Debug(sLine : AnsiString;
                     bAllNumerical : boolean;
                     bHex : boolean;
                     bSquareBrackets : boolean;
                     cSeparator : char) : string;
  function SearchAndReplace(sMain : string; sFind : string; sReplace : string) : string;
  function ExtractAndTrimTo(var sInput : string; uiLength : word) : string; overload;
  function ExtractAndTrimTo(var sInput : AnsiString; uiLength : word) : AnsiString; overload;



  {File and path}
  function NextDateStamp(Path,FileNameFormat, ext : string) : string;
  function NextSequentialFile(FilePathAndName : string) : string;
  procedure CreatePath(Path : string);
  procedure AppendFile(var F: Text);
  function  AppendPathStr(const Path, Directory : string): string;
//  procedure CloseFile(var F: Text);
  function SetDebugLogFile(sFileName : string;
                           bClear : boolean) : boolean;
  procedure DebugLog(sLine : string);
  function FilenameValid(sFileName : string) : boolean;
  function GetTempFolder : string;


  {delhi 1 tstring functions}
  function GetIndexOfName(list : TStringList; name : string) : integer;
  procedure EnableCtrls(Sender : twincontrol; Enable : boolean);

  {Bytes / Bits / Nibbles}
  function getbit(Bits : Cardinal; pos : Byte) : boolean;
  procedure setbit(var Bits : Cardinal; pos : Byte; setBit : boolean);
  function ZeroBaseNib(value : byte) : Byte;
  function UnitBaseNib(value : byte) : Byte;

  {default database}
  {$IFNDEF DBISAM}  // ELSE USE DBSAMWIZ FOR DBISAM TABLES
  function UTDefWriteInteger(Table : ttable; Section, Ident : string; value : integer) : boolean;
  function UTDefWriteString (Defaults : TTable; Section, Ident : string; value : string ) : boolean;
  function UTDefWriteBoolean(Table : ttable; Section, Ident : string; value : boolean) : boolean;
  function UTDefReadsection (table : ttable; Section, Condition: string) : TStringList;
  function UTDefReadsectionValues(table : ttable; Section, Condition: string) : TStringList;
  function UTDefWriteSection(Table : ttable; section : string; Stringlist : TStringList) : boolean;
  function UTDefReadInteger (Table : ttable; Section, Ident : string; Default : integer) : integer;
  function UTDefReadString  (Table : ttable; Section, Ident : string; Default : string) : string;
  function UTDefReadBoolean (Table : ttable; Section, Ident : string; Default : boolean) : boolean;
  function UTDefDeleteEntry (Table : ttable; Section, Ident : string) : boolean;
  function UTDefDeleteSection(table : ttable; Section : string; Condition: string) : boolean;
  {$ENDIF}

  {Date Time}
  procedure DecMonthMin(MonthMin : Word; var Day, Hour, Min : word);
  function  EncMonthMin(Day, hour, min : word) : Word;
  function  EncMonthMin2DateTime(Year,Month,Monthmin,BaseYear : word) : tdatetime;
  procedure DecDateTime2MontMin(DateTime: tdatetime;var Year : Word;var Month : Byte;var Monthmin : word);
  function  IsNewMinute(var OldTime : ttime) : boolean;
  function  ValidTime(const timestr:string):boolean;
  function  leadzero(n : Integer) : String;
  function  ConvertToHrs(T : Integer) : String;
  function  WeekDay(dayofweek : integer) : string;

  ///////////////////////// PERSISTANT FIELD CREATION /////////////////////////
  procedure CreateStringField(const AOwner : tComponent;var field : tfield; const Name, Display : string; GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean;const Size : integer);
  procedure CreateIntegerField(const AOwner : tComponent;var field : tfield; const Name, Display : string;GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean);
  procedure CreateByteField(const AOwner : tComponent;var field : tfield; const Name, Display : string; GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean;const Size : integer);
  procedure CreateBooleanField(const AOwner : tComponent;var field : tfield; const Name, Display : string; GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean);
  procedure CreateDateTimeField(const AOwner : tComponent;var field : tfield; const Name, Display : string; GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean);

  {statistical}
  procedure UTStatAdd(var list : array of integer; value: integer);
  function  UTStatSum(var list : array of integer) : integer;
  procedure UTStatAddMax(var list : array of integer; value, maxvalue : integer);
  procedure UTStatAddMin(var list : array of integer; value, Minvalue : integer);
  procedure UTStatAddRange(var list : array of integer; value, Minvalue, Maxvalue : integer);
  function  UTStatAvg(var list : array of integer) : real;
  procedure UTStatClear(var list : array of integer);
  {Bit and Bytes}
  function IntToHexStr(int : longint; strlength : shortint) : AnsiString;
  function inttoBCDstr(int : longint; strlength : shortint) : string;
  function inttopichexstr(int : longint; strlength : shortint) : string;
  function IntToHexDisp(int : longint; length : integer) : string;
  function HexValue(Hex : char) : integer;
  function hextoint(Hex : string) : integer;
  function SwapBytes(input : integer; length : shortint) : variant;
  function AddBytesHiLow(input : string) : longint;
  function DateToHexStr(Date : tdatetime; minyear : integer; Format : String) : string;
  function EncodeByte(bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7 : boolean) : Byte;
  procedure DecodeByte(Input : Byte; var bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7 : boolean);
  {Miss}
  procedure UTCondInc(var X : longint; const Min, Max : longint);

  procedure UTTranslatewwGrid(grid : twwdbgrid);
  procedure UTTranslateGrid(grid : tdbgrid);

  {Logfiles}
  procedure MaintainLog(Filename : string; Days : integer);
  procedure LogEntry(Filename, Entry : string);

  {IniFiles}
  procedure WriteStringlistToIni(Inifile : TIniFile; const Section, Ident : string; Stringlist : tstrings);
  procedure ReadStringlistFromIni(Inifile : TIniFile; const Section, Ident : string; Stringlist : tStrings);

  {DST}
  function GetCurrentYear: Word;
  procedure GetDSTTimes(var DSTUsed : boolean;var StartTime, EndTime : tdatetime);

  Function GetX87SW: Word; // Assembler;

  function GetText(str : string) : string;

{$IFDEF VER220}      {Delphi XE}
  function GetFileTranslation(const Filename: string; FullName: Boolean = FALSE): string;
{$ELSE}
  function GetFileTranslation(const Filename: string; FullName: Boolean): string;
{$ENDIF}
  function GetFileResourceString(FileName,VerKey:string):string;

  procedure RemoveDLLPATHSemiColon;


  var Dictionary : tOBJECT;

implementation

{$IFDEF MULTILANG} uses IvBinDic; {$ENDIF}

const STRING_NOT_FOUND = 'Not Found';

var
  sDebugFileName : string;

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
procedure RemoveDLLPATHSemiColon;
var Reg : TRegistry;
    s : string;
begin
  Reg := TRegistry.Create;
  with Reg do
    begin
      RootKey := HKEY_LOCAL_MACHINE;
      if OpenKey('SOFTWARE\Borland\Database Engine',FALSE) then
        begin
          if ValueExists('DLLPATH') then
            begin
              s := ReadString('DLLPATH');
              if s[Length(s)] = ';' then
                WriteString('DLLPATH',copy(s,1,Length(s)-1));
            end;
          CloseKey;
        end;
    end;
  FreeAndNil(Reg);
end;


function IntToColor(Int : Integer) : LongInt;
var Color : LongInt;
begin
  case Int of
    1 : Color := clBlack;
    2 : Color := clMaroon;
    3 : Color := clGreen;
    4 : Color := clOlive;
    5 : Color := clNavy ;
    6 : Color := clPurple;
    7 : Color := clTeal ;
    8 : Color := clSilver;
    9 : Color := clGray ;
    10 : Color := clRed;
    11 : Color := clLime;
    12 : Color := clYellow;
    13 : Color := clBlue;
    14 : Color := clFuchsia;
    15 : Color := clAqua;
    16 : Color := clWhite;
  else color := clBlack;
  end;
  IntToColor := Color;
end;

function ConvertStrToStyle(S : String) : TFontStyles;
var t : TFontStyles;
begin
  t := [];
  if Pos('fsBold',S) > 0 then t := t+ [fsBold];
  if Pos('fsItalic',S) > 0 then t := t+ [fsItalic];
  if Pos('fsUnderline',S) > 0 then t := t+ [fsUnderline];
  if Pos('fsStrikeout',S) > 0 then t := t+ [fsStrikeout];
  ConvertStrToStyle := t;
end;

function ConvertStyleToStr(Style : TFontStyles) : String;
var t : string;
begin
  t := '[';
  if (fsBold in Style) then t := t+'fsBold';
  if fsItalic in Style then t := t+',fsItalic';
  if fsUnderline in Style then t := t+',fsUnderline';
  if fsStrikeout in Style then t := t+',fsStrikeout';
  t := t+']';
  ConvertStyleToStr := t;
end;

function GetShortDay(instring : string; TCase : TTypeCase) : string;
{ Identify a string and convert to short version in required case}
type daytype = (Monday, Thuesday, Wednesday, Thursday, Friday, Saturday, Sunday, None);
var tempstr : string;
    day     : daytype;
begin
  tempstr := LowerCase(instring);
  if tempstr = 'monday'    then day := Monday else
  if tempstr = 'thuesday'  then day := Thuesday else
  if tempstr = 'wednesday' then day := Wednesday else
  if tempstr = 'thursday'  then day := Thursday else
  if tempstr = 'friday'    then day := Friday else
  if tempstr = 'saturday'  then day := Saturday else
  if tempstr = 'sunday'    then day := Sunday
  else day := None;
  if day = None
  then result := instring
  else begin
    case TCase of
      tcUpper : begin
                  case day of
                        Monday   : result := 'MON';
                        Thuesday : result := 'TUE';
                        Wednesday: result := 'WED';
                        Thursday : result := 'THU';
                        Friday   : result := 'FRI';
                        Saturday : result := 'SAT';
                        Sunday   : result := 'SUN';
                  end;
                end;
      tcLower : begin
                  case day of
                        Monday   : result := 'mon';
                        Thuesday : result := 'tue';
                        Wednesday: result := 'wed';
                        Thursday : result := 'the';
                        Friday   : result := 'fri';
                        Saturday : result := 'sat';
                        Sunday   : result := 'sun';
                  end;
                end;
      tcPropper:begin
                  case day of
                        Monday   : result := 'Mon';
                        Thuesday : result := 'Tue';
                        Wednesday: result := 'Wed';
                        Thursday : result := 'Thu';
                        Friday   : result := 'Fri';
                        Saturday : result := 'Sat';
                        Sunday   : result := 'Sun';
                  end;
                end;
    end;
  end;
end;


{*****************************************************************************}
{**********               MENU FUNCIONS                                *******}
{*****************************************************************************}
procedure CopyMainMenu(frommenu, tomenu : tmenu);
var i : integer;
    tempitem : TMenuItem;
{ Change 09/04/2000 because to use the menu item form the
  from menu and add it to the to menu directly and not recreate the
  item, because the handle property would change by doing this and the
  menu item can not be search for.}
begin
  // Clear the target menu
  for i := 0 to tomenu.items.Count - 1 do begin
    tomenu.items.Delete(0);
  end;
  // Copy the source menu
  for i := 0 to frommenu.items.Count - 1 do begin
    tempitem := frommenu.Items[0];
    frommenu.items.Delete(0);
    tomenu.Items.Add(tempitem);
  end;
end;

procedure SetWholeMenu(Items : TMenuItem; State : Boolean);
var a : shortint;
begin
  if items.Count > 0 then begin{if subitems...}
    for a := 0 to Items.Count-1 do begin
      Items[a].Visible := State;
      SetWholeMenu(Items[a],State);
    end;
  end ;
end;

function StripCaption(S : String) : String;
begin
  while Pos('&',S) > 0 do Delete(S,Pos('&',S),1);
  StripCaption := S;
end;

{function GetNextIndex(table : ttable; fieldname : string) : integer;
begin
  with TQuery.Create(nil) do begin
    try
      DatabaseName := table.DatabaseName;
      SQL.Add('SELECT MAX(' + fieldname + ') AS NEXTNBR FROM ' + table.TableName);
      Prepare;
      Open;
      result := FieldByName('NEXTNBR').AsInteger + 1;
      Close;
    finally
      Free;
    end;
  end;
end;


function CanDelete(databasename,tablename,fieldname,value : string;fieldtype :  TFieldType) : boolean;
begin
  with tquery.Create(nil) do begin
    try
      databasename := DatabaseName;
      sql.Add('SELECT DISTINCT ' + fieldname + ' FROM ' +tablename + ' WHERE ');
      case fieldtype of
        ftString : sql.Add(fieldname + ' = ''' + value + '''');
      else sql.Add(fieldname + ' = ' + value);
      end;
      prepare;
      open;
      result := recordcount > 0;
      Close;
    finally
      free;
    end;
  end;
end;

function CanInsert(table : ttable; fieldname,value : string;fieldtype :  TFieldType; Count : shortint) : boolean;
begin
  with tquery.Create(nil) do begin
    try
      databasename := table.DatabaseName;
      sql.Add('SELECT ' + fieldname + ' FROM ' +table.TableName + ' WHERE ');
      case fieldtype of
        ftString : sql.Add(fieldname + ' LIKE ''' + value + '''');
      else sql.Add(fieldname + ' LIKE ' + value);
      end;
      prepare;
      open;
      result := recordcount <= count;
      Close;
    finally
      free;
    end;
  end;
end;}


{=String functions}
function GetName(Teststr : string) : string;
var sep : integer;
begin
  sep := Pos('=',teststr);
  if sep = 0
  then result := ''
  else result := copy(teststr,1,sep-1);
end;

function GetValue(TestStr: string) : string;
var sep : integer;
begin
  sep := Pos('=',teststr);
  if sep = 0
  then result := ''
  else result := copy(teststr,sep + 1, Length(teststr));
end;

function StripFileExt(TestStr : string) : string;
var IPos : shortint;
begin
  IPos := Pos('.',Teststr);
  if IPos > 0
  then result := copy(Teststr,1,Ipos-1)
  else result := teststr;
end;

function booltostr(value : boolean; TrueValue , FalseValue : string) : string;
begin
  if value
  then result := TRUEValue
  else result := FALSEValue;
end;

function  BooltoYesNo(value : boolean): string;
begin
  if value
  then result := 'Yes'
  else result := 'No'
end;

function ExtFormat(const FormatStr: string; const Args: array of const): string;
var i,j,k : integer;
    Lstr : string;
    LArg : array[0..10] of pvarrec;
begin
  if High(Args) > 10 then begin
    MessageDlg('Message to Self -- Can not hangle more than 10 arguments', mtError,[mbOK],0);
    Exit;
  end;
  Lstr := '';
  i := 0; {index to FormatStr string}
  j := -1;{counter of % in formatStr string - index to Args}
  k := 0; {number of %L foundr in formatStr string}
  while i < Length(FormatStr) do begin
    inc(i);
    if formatStr[i] = '%' then begin
      inc(j);
      if UpperCase(formatStr[i+1]) = 'L' then begin
        inc(k);
        if Args[j].VBoolean
        then LStr := LStr + 'FALSE'
        else LStr := LStr + 'TRUE';
        inc(i);
      end
      else begin
        move(Args[i],LArg[j-k],sizeof(Args[i]));
      end;
    end
    else LStr := LStr + formatStr[i];
  end;
  result := Format(Lstr,[LArg[0],LArg[1],LArg[2],LArg[3],LArg[4],LArg[5],LArg[6],LArg[7],LArg[8],LArg[9],LArg[10]]);
end;

function PadLeft(Str : string; StrLength : integer; Ch : char) : string;
begin
  result := str;
  while Length(result) < StrLength
  do result := ch + result;
end;

function PadRight(const Str : string; StrLength : integer; Ch : char) : string;
begin
  result := str;
  while Length(Result) < StrLength
  do result := result + ch;
end;

function GetPathFromFilename(const Str : string) : string;
var Temp : string;
begin
  Temp := str;
  result := '';
  while Pos('\',Temp) > 0 do begin
    result := result + copy(temp,1,Pos('\',Temp));
    Delete(temp,1,Pos('\',Temp));
  end;
end;

function FormatAddressDateString(const str : string;Date : tdatetime; Address : integer) : string;
var Lstr,Ltemp : string;
    LLiteral : boolean;
    LY, LM, LD, LH, LN, LS, LMS : Word;

  function GetConsChars(const str : string) : string;
  var LStr : string;
      LCh  : char;
  begin
    LStr := str;
    LCh  := str[1];
    Delete(LStr,1,1);
    result := LCh;
    while (LStr <>  '') and (LStr[1] = LCh) do begin
      result := result + LCh;
      Delete(LStr,1,1);
    end;
  end;

begin
  result := '';
  DecodeDate(Date,LY,LM,LD);
  DecodeTime(Date,LH,LN,LS,LMS);
  LLiteral := FALSE;
  Lstr := str;
  while lstr <> '' do begin
    if LLiteral then begin
      if LStr[1] <> '"'
      then result := result + LStr[1]   {Add Literals to result}
      else LLiteral := FALSE           {End literals}
    end
    else begin
      if Lstr[1] = '/' then begin
        Delete(Lstr,1,1);
        if lstr[1] = '"'
        then LLiteral := TRUE          {Begin literals}
        else result := result + lstr[1];{Add only one char after '/'}
      end
      else if UpperCase(Lstr[1]) = 'Y' then begin
        LTemp := IntToStr(LY);
        result := result + copy(LTemp,Length(LTemp)-Length(GetConsChars(Lstr))+1,Length(GetConsChars(Lstr)));
        Delete(LStr,1,Length(GetConsChars(Lstr))-1);
      end
      else
        if (CharInSet(UpperCase(Lstr[1])[1],['A','M','D','H','N','S'])) then
        begin
          case UpperCase(Lstr[1])[1] of
            'A' : LTemp := IntToStr(Address);
            'M' : LTemp := IntToStr(LM);
            'D' : LTemp := IntToStr(LD);
            'H' : LTemp := IntToStr(LH);
            'N' : LTemp := IntToStr(LN);
            'S' : LTemp := IntToStr(LS);
          end; // case
        result := result + padleft(Ltemp,Length(GetConsChars(Lstr)),'0');
        Delete(LStr,1,Length(GetConsChars(Lstr))-1);
      end
    end;
    Delete(LStr,1,1);
  end;
end;

function GetIndexOfName(list : TStringList; name : string) : integer;
var i : integer;
    teststr : string;
begin
  result := -1;
  i := 0;
  while (result = -1) and (i < list.Count) do begin
    teststr := getname(list.Strings[i]);
    if LowerCase(teststr) = LowerCase(name)
    then result := i;
    inc(i);
  end;
end;

procedure EnableCtrls(Sender : twincontrol; Enable : boolean);
var i : integer;
begin
  sender.Enabled := Enable;
  for i := 0 to sender.controlcount - 1
  do begin
    if sender.controls[i] is tgroupbox
    then EnableCtrls(twincontrol(Sender.controls[i]), Enable);
    try
    twincontrol(Sender.controls[i]).Enabled := Enable;
    except
    end;
  end;
end;


function getbit(Bits : Cardinal; pos : Byte) : boolean;
{This fuction return true if the bit at pos in Bits is set}
begin
  result := Bits and (1 shl pos) = (1 shl pos)
end;

procedure setbit(var Bits : Cardinal; pos : Byte; setBit : boolean);
{This procedure set the bit at pos in Bits to 1 if setbit true}
begin
  if setbit
  then bits := (Bits or (1 shl pos));
end;

function UnitBaseNib(value : byte) : Byte;
begin
  result := 0;
  if value and $0F < 7
  then result := (value and $0F) + 1;
  if (value shr 4) < 7
  then result := result + (((value shr 4) + 1) shl 4);
end;

function ZeroBaseNib(value : byte) : Byte;
begin
  result := 0;
  if (value and $0F) > 0
  then result := (value and $0F) - 1;
  if (value shr 4) > 0
  then result := result + ((value shr 4) - 1) shl 4;
end;


{default database}
function UTDefWriteInteger(Table : ttable; Section, Ident : string; value : integer) : boolean;
begin
  result := FALSE;
  try
    table.Open;
    try
      if not table.locate('section;ident',VarArrayOf([section,Ident]),[loCaseInsensitive])
      then begin
        table.insert;
        table.FieldByName('Section').AsString := section;
        table.FieldByName('Ident').AsString   := Ident;
      end
      else table.Edit;
      table.FieldByName('defvalue').AsString := IntToStr(value);
      table.Post;
      result := TRUE;
    finally
      table.close
    end;
  except
  end;
end;

//***************************************************************************
//
//  FUNCTION  : UTDefWriteString
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Write defaults into a table of Section/Identifiers (very similar
//              to a TInifile structure
//
//  UPDATED   : 2014-02-28
//
//***************************************************************************
function UTDefWriteString (Defaults : TTable; Section, Ident : string; value : string ) : boolean;
begin
  result := FALSE;
  try
    Defaults.Open;
    try
      if (not Defaults.locate('section;ident',VarArrayOf([section,Ident]),[loCaseInsensitive])) then
      begin
        Defaults.insert;
        Defaults.FieldByName('Section').AsString := section;
        Defaults.FieldByName('Ident').AsString   := Ident;
      end // if
      else
        Defaults.Edit;
      Defaults.FieldByName('defvalue').AsString := value;
      Defaults.Post;
      result := TRUE;
    finally
      Defaults.Close;
    end;
  except
  end;
end;

function UTDefWriteBoolean(Table : ttable; Section, Ident : string; value : boolean) : boolean;
begin
  result := FALSE;
  try
    table.Open;
    try
      if not table.locate('section;ident',VarArrayOf([section,Ident]),[loCaseInsensitive])
      then begin
        table.insert;
        table.FieldByName('Section').AsString := section;
        table.FieldByName('Ident').AsString   := Ident;
      end
      else table.Edit;
      if value
      then table.FieldByName('defvalue').AsString := 'T'
      else table.FieldByName('defvalue').AsString := 'F';
      table.Post;
      result := TRUE;
    finally
      table.close
    end;
  except
  end;
end;

function UTDefDeleteSection(table : ttable; Section : string; Condition: string) : boolean;
begin
{  result := FALSE;}
  with tquery.Create(nil) do begin
    try
      databasename := table.DatabaseName;
      sql.Add('delete from ' + stripFileext(table.TableName));
      sql.Add('where section = ''' + section+'''');
      if Condition <> ''
      then sql.Add('and DEFvalue = ''' + condition + '''');
      execsql;
      result := TRUE;
    finally free;end;
  end;
end;

function  UTDefReadsection (table : ttable; Section, Condition: string) : TStringList;
begin
  result := TStringList.Create;
  with tquery.Create(nil) do begin
    try
      databasename := table.DatabaseName;
      sql.Add('select * from ' + stripfileext(table.TableName) );
      sql.Add('where section = ''' + section + '''');
      if Condition <> ''
      then sql.Add('and DEFvalue = ''' + condition + '''');
      open;
      while not eof do begin
        result.Add(FieldByName('Ident').AsString){ + '=' + FieldByName('defvalue').AsString)};
        next;
      end;
    finally free;end;
  end;
end;

function UTDefReadsectionValues(table : ttable; Section, Condition: string) : TStringList;
begin
  result := TStringList.Create;
  with tquery.Create(nil) do begin
    try
      databasename := table.DatabaseName;
      sql.Add('select * from ' + stripfileext(table.TableName) );
      sql.Add('where section = ''' + section + '''');
      if Condition <> ''
      then sql.Add('and DEFvalue = ''' + condition + '''');
      open;
      while not eof do begin
        result.Add(FieldByName('Ident').AsString + '=' + FieldByName('defvalue').AsString);
        next;
      end;
    finally free;end;
  end;
end;

function UTDefWriteSection(Table : ttable; section : string; Stringlist : TStringList) : boolean;
var i : integer;
begin
  result := FALSE;
  UTDefDeleteSection(table,section,'');
  for i := 0 to Stringlist.Count - 1 do begin
    result := UTDefWriteString(table,section,stringlist.names[i],stringlist.values[stringlist.names[i]]);
  end;
end;


function  UTDefReadInteger (Table : ttable; Section, Ident : string; Default : integer) : integer;
begin
  try
    table.Open;
    if table.locate('section;ident',VarArrayOf([section,Ident]),[loCaseInsensitive])
    then result := table.FieldByName('defvalue').AsInteger
    else result := default;
    table.Close;
  except
    result := default;
  end;
end;

function  UTDefReadString  (Table : ttable; Section, Ident : string; Default : string) : string;
begin
  try
    table.Open;
    if table.locate('section;ident',VarArrayOf([section,Ident]),[loCaseInsensitive])
    then result := table.FieldByName('defvalue').AsString
    else result := default;
    table.Close;
  except
    result := default;
  end;
end;

function  UTDefReadBoolean (Table : ttable; Section, Ident : string; Default : boolean) : boolean;
begin
  try
    table.Open;
    if table.locate('section;ident',VarArrayOf([section,Ident]),[loCaseInsensitive])
    then result := UpperCase(table.FieldByName('defvalue').AsString) = 'T'
    else result := default;
    table.Close;
  except
    result := default;
  end;
end;

function UTDefDeleteEntry (Table : ttable; Section, Ident : string) : boolean;
begin
  table.Open;
  result := table.locate('section;ident',VarArrayOf([section,Ident]),[loCaseInsensitive]);
  if result
  then Table.delete;
  table.Close;
end;

function UTStrInc(var str : string) : string;
var int : integer;
begin
  int := strtoint(str);
  inc(int);
  str :=  IntToStr(int);
end;
{=========================}
{Date Time}
{=========================}
procedure DecMonthMin(MonthMin : Word; var Day, Hour, Min : word);
begin
  Day      := Trunc(MonthMin/(60*24)) + 1;
  MonthMin := MonthMin - (day-1)*60*24;
  Hour     := Trunc(monthmin/60);
  Min := MonthMin - Hour *60;
end;

function EncMonthMin(Day, hour, min : word) : Word;
begin
  result := (Day-1)*24*60 + Hour*60 + min;
end;

function  EncMonthMin2DateTime(Year,Month,Monthmin,BaseYear : word) : tdatetime;
var Day, Hour, Min : Word;
begin
  DecMonthMin(Monthmin, Day, Hour, Min);
  Year := Year + BaseYear;
  try
    if (month in [1..12]) and (dAY in [1..31])
    then result := EncodeDate(Year,Month,Day) + EncodeTime(Hour,Min,0,0)
    else result := 0;
  except
    result := 0;
  end;
end;

procedure DecDateTime2MontMin(DateTime: tdatetime;var Year : Word;var Month : Byte;var Monthmin : word);
var WMonth,Day,Hour, Min, Sec, MSec : Word;
begin
  if DateTime = 0 then begin
    Year := 2000;
    Month:= 1;
    Day  := 1;
    MonthMin := 0;
  end
  else begin
    DecodeDate(DateTime,Year,WMonth,Day);
    Month := WMonth;
    DecodeTime(DateTIme,Hour,Min,Sec,MSec);
    MonthMin := Day * 24 * 60 + Hour * 60 + Min;
  end;
end;

function IsNewMinute(var OldTime : ttime) : boolean;
var LTime : ttime;
begin
  LTime := time;
  result := (Trunc(Ltime * 24 * 60) <> Trunc(OldTime * 24* 60));
  OldTime := LTime
end;

function ValidTime(const timestr:string):boolean;
var
  valid:boolean;
  colonpos:integer;
  mins:integer;
begin
  valid:=false;
  colonpos := Pos(':',timestr);
  if colonpos>0 then begin
    try
//      hours:=StrToInt(copy(timestr,1,colonpos-1));
      try
        mins:=StrToInt(copy(timestr,colonpos+1,Length(timestr)));
        if mins<=59 then valid:=true;
      except
      end;
    except
    end;
  end;
  ValidTime:=valid;
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
function leadzero(n : Integer) : String;
var
  s : string;

begin
  Str(n,s);
  if (Length(s) = 1) then
    s := '0' + s;
  leadzero := s;
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
function ConvertToHrs(T : Integer) : String;
{converts a string time (hh:mm or hh) to minutes}
begin
  ConvertToHrs := LeadZero(T div 60)+':'+LeadZero(T mod 60);
end;

function  WeekDay(dayofweek : integer) : string;
var
  days: array[1..8] of string;
begin
  days[1] := GetText('Sunday');
  days[2] := GetText('Monday');
  days[3] := GetText('Tuesday');
  days[4] := GetText('Wednesday');
  days[5] := GetText('Thursday');
  days[6] := GetText('Friday');
  days[7] := GetText('Saturday');
  days[8] := GetText('Holiday');
  result := days[dayofweek];
end;

{statistical}
function UTStatAvg(var list : array of integer) : real;
var i : integer;
begin
  result := 0;
  for i := 1 to High(list)
  do result := result + list[i];
  result := result / High(list);
end;

function UTStatSum(var list : array of integer) : integer;
var i : integer;
begin
  result := 0;
  for i := 1 to High(list)
  do result := result + list[i]
end;

procedure UTStatAdd(var list : array of integer; value : integer);
begin
  if list[0] = High(list)
  then list[0] := 1
  else list[0] := list[0] + 1;
  list[list[0]] := value;
end;

procedure UTStatAddRange(var list : array of integer; value, Minvalue, Maxvalue : integer);
begin
  if (abs(value) < Maxvalue) and (abs(value) > MinValue) then begin
    if list[0] = High(list)
    then list[0] := 1
    else list[0] := list[0] + 1;
    list[list[0]] := value;
  end;
end;

procedure UTStatAddMax(var list : array of integer; value, Maxvalue : integer);
begin
  if abs(value) < Maxvalue then begin
    if list[0] = High(list)
    then list[0] := 1
    else list[0] := list[0] + 1;
    list[list[0]] := value;
  end;
end;

procedure UTStatAddMin(var list : array of integer; value, Minvalue : integer);
begin
  if abs(value) > Minvalue then begin
    if list[0] = High(list)
    then list[0] := 1
    else list[0] := list[0] + 1;
    list[list[0]] := value;
  end;
end;

procedure UTStatClear(var list : array of integer);
var i : shortint;
begin
  for i := 0 to High(list)
  do list[i] := 0;
end;

{Bit and Bytes}

function IntToHexStr(int : longint; strlength : shortint) : AnsiString;
{ Convert a integer to a string whithout any adjustemtn eg 100 as 'd' }
begin
  result := '';
  while (abs(int) > 0) do
  begin
    result := AnsiChar(int and $FF) + result;
    int := Trunc(int shr 8);
  end;
  // Ensure the correct number of digits (front-padding)
  while (Length(result) < strlength) do
    result := AnsiChar(0) + result;
end;

function inttoBCDstr(int : longint; strlength : shortint) : string;
var c : char;
begin
  result := '';
  while abs(int) > 0 do
  begin
    case int and $0F of
      0 : c := '0';
      1 : c := '1';
      2 : c := '2';
      3 : c := '3';
      4 : c := '4';
      5 : c := '5';
      6 : c := '6';
      7 : c := '7';
      8 : c := '8';
      9 : c := '9';
      10: c := 'A';
      11: c := 'B';
      12: c := 'C';
      13: c := 'E';
      14: c := 'D';
      15: c := 'F';
      else c := ' ';
    end;
    result :=  c + result;
    int := Trunc(int shr 4);
  end;
  while Length(result) < strlength
  do result := '0' + result;
end;

function inttopichexstr(int : longint; strlength : shortint) : string;
begin
  result := '';
  while abs(int) > 0 do begin
    result :=  result + char(int and $FF);
    int := Trunc(int shr 8);
  end;
  while Length(result) < strlength
  do result := result + char(0);
end;

function HexChar(int : integer) : char;
begin
  case int of
    0 : result := '0';
    1 : result := '1';
    2 : result := '2';
    3 : result := '3';
    4 : result := '4';
    5 : result := '5';
    6 : result := '6';
    7 : result := '7';
    8 : result := '8';
    9 : result := '9';
    10: result := 'A';
    11: result := 'B';
    12: result := 'C';
    13: result := 'D';
    14: result := 'E';
    15: result := 'F';
    else
      result := ' ';
  end;
end;

function IntToHexDisp(int : longint; length : integer) : string;
{ Displays the int value as Hex value eg. 100 as '$64'}
var str : string;
begin
  str := IntToHexStr(int,length);
  result := '';
  while str <> '' do begin
    result := result + HexChar(ord(str[1]) shr 4) + HexChar(ord(str[1]) and $F);
    Delete(str,1,1);
  end;
  result := '$' + padleft(result,length * 2,'0');
end;

function HexValue(Hex : char) : integer;
begin
  case Hex of
    '0' : result := 0;
    '1' : result := 1;
    '2' : result := 2;
    '3' : result := 3;
    '4' : result := 4;
    '5' : result := 5;
    '6' : result := 6;
    '7' : result := 7;
    '8' : result := 8;
    '9' : result := 9;
    'A' : result := 10;
    'B' : result := 11;
    'C' : result := 12;
    'D' : result := 13;
    'E' : result := 14;
    'F' : result := 15;
  else begin
    result := 16;
    MessageDlg('Not a valid Hex value',mtError,[mbOK],0);
  end; end;
end;

function hextoint(Hex : string) : integer;
var i : integer;
begin
  result := 0;
  for i := Length(Hex) downto 1
  do result := result + Round(HexValue(Hex[i]) * power(16,Length(HEX)-i));
end;

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
function SwapBytes(input : integer; length : shortint) : variant;
var i : Byte;
begin
  result := 0;
  for i := 0 to length - 1 do
  begin
    result := result shl 8; {shift all 8 left}
    result := result + ((input and ($FF shl (8 * i)){Byte to move} shr(8 * i)){make smalles byte});
  end;
end;

function AddBytesHiLow(input : string) : longint;
var i : Byte;
begin
  result := 0;
  for i := 1 to Length(input)
  do begin
    result := (result shl 8)+ ord(input[i]);
  end;
end;

function DateToHexStr(Date : tdatetime; minyear : integer; Format : string) : string;
{Returns a hex string with year and monthmin}
var SYear, Year,Month,Day,Hour,Min,Sec,MSec, MonthMin : Word;
begin
  DecodeDate(Date,Year,Month,Day);
  DecodeTime(Date,Hour,Min,Sec,MSec);
  Monthmin := EncMonthMin(Day,Hour,Min);
  SYear :=  Year - minyear;
  if format = 'YYYY,MMIN'  {Ignore Minyear}
  then result := IntToHexStr(Year,2)+IntToHexStr(Monthmin,2)
  else if format = 'YY,MMIN'
  then result := IntToHexStr(SYear,1)+IntToHexStr(Monthmin,2)
  else if format = 'DAYS'
  then result := IntToHexStr(Trunc(Date - Encodedate(Minyear,1,1)),2)
  else if format = 'YYYY,MM,DD'  {Ignore Minyear}
  then result := IntToHexStr(Year,2) + char(Month) + char(Day)
  else if format = 'YY,MM,DD'
  then result := IntToHexStr(SYear,2) + char(Month) + char(Day)
  else if format = 'YYYY,MM,DD,HH,MM'
  then result := IntToHexStr(Year,2) + char(Month) + char(Day) + char(hour)+char(min)
  else if format = 'YY,MM,DD,HH,MM'
  then result := IntToHexStr(SYear,2) + char(Month) + char(Day) + char(hour)+char(min)
  else MessageDlg('DateToHexstr format not known',mtInformation,[mbOK],0);
end;

function EncodeByte(bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7 : boolean) : Byte;
begin
  result := 0;
  if bit0 then result := result or $01;
  if bit1 then result := result or $02;
  if bit2 then result := result or $04;
  if bit3 then result := result or $08;
  if bit4 then result := result or $10;
  if bit5 then result := result or $20;
  if bit6 then result := result or $40;
  if bit7 then result := result or $80;
end;

procedure DecodeByte(Input : Byte; var bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7 : boolean);
begin
  bit0 := input and $01 = $01;
  bit1 := input and $02 = $02;
  bit2 := input and $04 = $04;
  bit3 := input and $08 = $08;
  bit4 := input and $10 = $10;
  bit5 := input and $20 = $20;
  bit6 := input and $40 = $40;
  bit7 := input and $80 = $80;
end;

procedure UTCondInc(var X : longint; const Min, Max : longint);
begin
  if X = Max
  then X := Min
  else inc(X);
end;

procedure UTTranslatewwGrid(grid : twwdbgrid);
var i : integer;
begin
  for i := 0 to Grid.FieldCount - 1 do begin
    grid.Fields[i].displaylabel := GetText(grid.Fields[i].displaylabel);
  end;
end;

procedure UTTranslateGrid(grid : tdbgrid);
var i : integer;
begin
  for i := 0 to Grid.FieldCount - 1 do begin
    grid.Fields[i].displaylabel := GetText(grid.Fields[i].displaylabel);
  end;
end;

{Logfiles}
procedure MaintainLog(Filename : string; Days : integer);
var
  Logfile, ToFile : textfile;
  Lstr,DStr : string;
  DateTime : tdatetime;
  WriteEmpLn  : boolean;

begin
  WriteEmpLn := FALSE;
  AssignFile(LogFile,Filename);
  AssignFile(ToFile,'~'+filename);
  try
    Rewrite(ToFile);
    reset(LogFile);
    while (not Eof(LogFile)) do
    begin
      ReadLn(LogFile,LStr);
      if LStr <> '' then
      begin
        DStr := '';
        if ((LStr = '') and WriteEmpLn) then
          Writeln(ToFile,'')
        else
        begin
          while (Pos(':',LStr) > 1) do
          begin
            DStr := DStr + Copy(LStr,1,Pos(':',LStr));
            Delete(LStr,1,Pos(':',LStr));
          end;
          Delete(DStr,Length(Dstr),1);
          try
            Datetime := Strtodatetime(DStr);
            if (Datetime > Now - Days) then
            begin
              Writeln(ToFile,DStr+':'+LStr);
              WriteEmpLn := TRUE;
            end;
          except
          end;
        end
      end
      else
        Writeln(ToFile,'');
    end;
    CloseFile(LogFile);
    CloseFile(ToFile);
    Erase(LogFile);
    Rename(ToFile,Filename);
  except
  end;
end;

//***************************************************************************
//
//  FUNCTION  : LogEntry
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Handles the situation of finding a log file inaccessible by
//              creating a temporary file
//
//  UPDATED   : 2013-08-23
//
//***************************************************************************
procedure LogEntry(Filename, Entry : string);
var
  F,G : textfile;
  STR : string;

begin
  try
    AssignFile(F,Filename);
    try
      Append(F);
    except
      if (FileExists(Filename)) then
      begin
        Filename := ChangeFileExt(Filename,'tmp');
        CloseFile(F);
        AssignFile(F,Filename); //Create tmp file
        if (FileExists(Filename)) then
          Append(F)
        else
          Rewrite(F);
      end
      else
        // Create for the first time
        Rewrite(F);
    end; // except

    try
      if (pos('tmp',Filename) = 0) then
      begin
        // No temporary file was created
        Filename := ChangeFileExt(Filename,'tmp');
        if FileExists(Filename) then
        begin
          // A temporary file does exist
          // Transfer data from .tmp file back to expected file
          CloseFile(G);
          AssignFile(G,Filename);
          Reset(G);
          try
            while not eof(G) do
            begin
              ReadLn(G,str);
              Writeln(F,str);
            end;
          finally
            // Get rid of the temporary file
            CloseFile(G);
            Deletefile(pchar(filename));
          end;
        end;
      end;
      Writeln(F,Entry);
    finally
      CloseFile(F);
    end;
  except
  end;
end;

{IniFiles}
procedure WriteStringlistToIni(Inifile : TIniFile; const Section, Ident : string; Stringlist : tstrings);
var i : integer;
begin
  if (Stringlist = nil) or (Inifile = nil) then Exit;
  {Remove eccess entries}
  if inifile.readinteger(section,Ident,0) > stringlist.Count  then begin
    for i := Stringlist.Count - 1 to inifile.readinteger(section,Ident,0) - 1
    do inifile.deletekey(section,ident+IntToStr(i));
  end;
  {Add number of entries}
  inifile.writeinteger(section,Ident,Stringlist.Count);
  {Add entries}
  for i := 0 to Stringlist.Count - 1
  do inifile.writestring(section, Ident+IntToStr(i), stringlist.Strings[i]);
end;

procedure  ReadStringlistFromIni(Inifile : TIniFile; const Section, Ident : string; Stringlist : tStrings);
var i : integer;
begin
  if (Stringlist = nil) or (Inifile = nil) then Exit;
  stringlist.Clear;
  if inifile.readinteger(section,ident,0) = 0
  then Exit;
  for i := 0 to inifile.readinteger(section,ident,0) - 1
  do Stringlist.Add(inifile.ReadString(Section,ident+IntToStr(i),''));
end;

function VerticalStrHeader(ch : char;str, header : string; lines : integer) : string;
var i,k : integer;
begin
{  result := '';
  k := Round(Length(str)/lines + 0.5);
  j := 0;
  for i := 1 to Length(str) do begin
    if j = k then begin
      result := result + ch;
      j := 0;
    end;
    inc(j);
    result := result + str[i];
  end;}
  result := header+'~ ~';
  for i := 1 to lines - 2 do begin
    k := 1;
    while i+((k-1)*(lines-2)) <= Length(str) do begin
      if str[(k-1)*(lines-2)+1] <> ' '
      then result := result + str[i+((k-1)*(lines-2))]
      else if i+((k-1)*(lines-2))+1 <= Length(str)
      then result := result + str[i+((k-1)*(lines-2)) + 1]; // do not add a space on top of a column
      inc(k);
    end;
    if i < lines - 2
    then result := result + ch;
  end;
end;

function VerticalStr(ch : char;str : string; lines : integer) : string;
var i,k : integer;
begin
{  result := '';
  k := Round(Length(str)/lines + 0.5);
  j := 0;
  for i := 1 to Length(str) do begin
    if j = k then begin
      result := result + ch;
      j := 0;
    end;
    inc(j);
    result := result + str[i];
  end;}

  result := '';
  for i := 1 to lines do begin
    k := i;
    while k <= Length(str) do begin
      result := result + str[k];
      k := k + lines;
    end;
    if i < lines
    then result := result + ch;
  end;
end;

function GetAppPath : string;
begin
  result := GetPathFromFilename(Application.ExeName);
//  result := ExtractFilePath(Paramstr(0)) + '\';
end;

function GetFirstWord(str : string; prechar, postchar : char) : string;
var i : integer;
begin
  i := 1;
  while str[1] = prechar
  do Delete(str,1,1);
  while (i <= Length(str)) and (str[i] <> postchar)
  do inc(i);
  result := copy(str,1,i-1);
end;

function GetNWord(str : string; N : integer; prechar, postchar : char) : string;
var i : integer;
begin
  if (n = 0) or (str = '')
  then Exit;
  repeat
    i := 1;
    while (Length(str) > 0) and (str[1] = prechar)
    do Delete(str,1,1);
    while (i <= Length(str)) and (str[i] <> postchar) do begin
      if str[i] = prechar then begin
        Delete(str,1,i);
        i := 1;
      end
      else inc(i);
    end;
    result := copy(str,1,i-1);
    if n > 1
    then Delete(str,1,i-1);
    Dec(n);
  until n = 0;
end;

function DelFirstWord(str : string; prechar, postchar : char) : string;
var i : integer;
begin
  i := 1;
  while str[1] = prechar
  do Delete(str,1,1);
  while (i <= Length(str)) and (str[i] <> postchar)
  do Delete(str,1,1);
  result := str;
end;

function NBCDToStr(Value : char) : string;
begin
  result := char((ord(value) shr 4) + $30) +
            char((ord(value) and $0F)+ $30);
end;

function StrToNBCD(Str :string) : char;
begin
  result := char(((ord(Str[1]) - $30) * $10) +
                 (ord(Str[2]) - $30));
end;

function IntToNBCD(Value : byte) : char;
begin
  result := char((Value mod 10) + Trunc(Value/10) * 16);
end;

function NBCDToInt(Value : char) : Byte;
begin
  result := (ord(Value) shr 4) * 10 + ord(Value) and $F;
end;

function IntToNBCDString(Value : byte) :string;
begin
  result := char(Trunc(Value / 10) + $30) + char(Value mod 10 + $30);
end;

function IntToBinString(Value : Cardinal; Length : integer;RightAlighn : boolean) : string;
begin
  while Value > 1 do begin
    if RightAlighn then begin
      if (value mod 2) = 1
      then result := '1' + result
      else result := '0' + result;
    end
    else begin
      if (value mod 2) = 1
      then result := result + '1'
      else result := result + '0';
    end;
    Value := Value div 2;
  end;
  if Value = 1
  then result := '1' + result;
  result := Padleft(result,Length,'0')
end;

procedure InitString(var str : string;const NewLength : integer;const All : boolean);
var i : integer;
begin
  if all
  then i := 0
  else i := Length(str) + 1;
  setLength(str,NewLength);
  while i <= Length(str) do begin
    str[i] := #00;
    inc(i);
  end;
end;

function deletestring(const str : string; from, length : integer) : string;
begin
  result := str;
  Delete(result,from,length);
end;

function SetDateRange(DateField : string; Startdate, EndDate : tdatetime;  IncTime : boolean) : string;
begin
  if IncTime
  then result := '(['+DateField+ '] >= '''+ datetimetostr(StartDate) +''''+
                 ' and ['+DateField+'] <= ''' + datetimetostr(endDate) +''')'
  else result := '(['+DateField+ '] >= '''+ datetimetostr(Trunc(StartDate)) + ''''+
                 ' and ['+DateField+'] <= ''' + datetimetostr(Trunc(endDate))+ ''')';
end;

function SetSQLDateRange(DateField, Format : string;Startdate, EndDate : tdatetime) : string;
//'mm"/"dd"/"yyyy hh:mm'
begin
  result := '(['+DateField+ '] >= "'+ FormatDateTime(Format,StartDate) +'"'+
                 ' and ['+DateField+'] <= "' + FormatDateTime(Format,endDate) +'")'
end;

function GetFilterDateStr(DateTime : tdatetime;   IncTime : boolean) : string;
begin
  if inctime
  then result := '''' + datetimetostr(DateTime) +''''
  else result := '''' + datetimetostr(Trunc(DateTime)) +'''';
end;

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
                   cSeparator : char) : string;
var
  n : integer;
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
function SearchAndReplace(sMain : string; sFind : string; sReplace : string) : string;
var
  iTo : integer;
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
          result := result + Copy(sMain,1,Length(sMain))
        else
        begin
          // Get the part of the string up to the found sub-string, and shorten
          // the original string to that point
          result := result +
          ExtractAndTrimTo(sMain,iTo-1);
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
function ExtractAndTrimTo (var sInput : string; uiLength : word) : string; overload;
begin
  result := Copy(sInput,1,uiLength);
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
  result := Copy(sInput,1,uiLength);
  sInput := Copy(sInput,uiLength+1,Length(sInput));
end; // ExtractAndTrimTo

procedure  OrFilterStr(var FilterString : string; AddString : string);
begin
  if AddString <> '' then begin
    if Length(FilterString) > 0
    then FilterString := FilterString + ' or ' + AddString
    else FilterString := AddString;
  end;
end;

procedure  AndFilterStr(var FilterString : string; AddString : string);
begin
  if AddString <> '' then begin
    if Length(FilterString) > 0
    then FilterString := FilterString + ' and (' + AddString + ')'
    else FilterString := AddString;
  end;
end;

procedure Add2Filter(pos : integer; Str : string);
begin
  MessageDlg(GetText('This procedure is not in use.'),mtError,[mbOK],0)
end;

function NextDateStamp(Path,FileNameFormat, ext : string) : string;
var str1 : string;
begin
  str1 := FormatDateTime(FileNameFormat,Date);
  if (pos(':',Path) = 0)
  then path := getAppPath + path;
  if (path[Length(path)] <> '\')
  then path := path + '\';
  result := NextSequentialFile(Path + str1 + '.' + ext);
end;

function NextSequentialFile(FilePathAndName : string) : string;
var path, filename, str, ext : string;
  i : integer;
begin
  i := 0;
  str := '';
  path := GetPathFromFilename(FilePathAndName);
  ext  := copy(FilePathAndName,Pos('.',FilePathAndName),10);
  filename := copy(FilePathAndName,Length(Path)+1,Pos('.',FilePathAndName) -Length(Path)-1);
  while FileExists(Path + filename + str + ext) do begin
    inc(i);
    str := padleft(IntToStr(i),3,'0')
  end;
  result := path + filename + str + ext;
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
procedure CreatePath(Path : string);
var
  str : string;
begin
  str := copy(path,1,Pos('\',path)-1);
  repeat
    Delete(path,1,Pos('\',path));
    if Pos('\',path) > 0
    then str := str + '\' + copy(path,1,Pos('\',path)-1)
    else str := str + '\' + path;
    if (not SysUtils.DirectoryExists(str)) then
      CreateDir(str);
  until Pos('\',path) = 0;
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
procedure AppendFile(var F: Text);
begin
  Append(F);
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
procedure CloseFile(var F: Text);
begin
  Close(F);
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
function  AppendPathStr(const Path, Directory : string): string;
begin
  if path[Length(path)] = '\'
  then result := path + Directory
  else result := path + '\' + Directory;
end;

//***************************************************************************
//
//  FUNCTION  : SetDebugLog
//
//  I/P       : sFileName (string) - The full filename of the file to which
//                debug messages are to be written.
//
//              bClear : boolean - TRUE to delete the log
//
//  O/P       : boolean - TRUE if file was deleted, if requested, else TRUE
//
//  OPERATION : Specifies the file (with path) to be used for any debug logging.
//              Defaults if the given filename appears to be invalid.
//
//              Optionally wipes the file.
//
//  UPDATED   : 2010-03-11
//
//***************************************************************************
function SetDebugLogFile(sFileName : string;
                         bClear : boolean) : boolean;
begin
  if ((ExtractFilePath(sFileName) <> '') and
      (SysUtils.DirectoryExists(ExtractFilePath(sFileName))) and
      (FileNameValid(ExtractFileName(sFileName)))) then
    sDebugFileName := sFileName
  else
    sDebugFileName := GetTempFolder + 'Debug.log';

  if (bClear) then
    result := SysUtils.DeleteFile(sDebugFileName)
  else
    result := TRUE;
end; // SetDebugLogFile

//***************************************************************************
//
//  FUNCTION  : DebugLog
//
//  I/P       : sLine (string) - The text to append to the log file.
//
//  O/P       : None.
//
//  OPERATION : Used for development debugging.   Creates a temporary log file
//              in the location that has been configured (see above)
//              Each logged line is date- and time-stampped.
//
//  UPDATED   : 2010-03-30
//
//***************************************************************************
procedure DebugLog(sLine : string);
var
  fLogFile : TextFile;

begin
  // Ensure that a debug file has been specified
  if (sDebugFileName = '') then
    SetDebugLogFile('',FALSE);

  try
    AssignFile(fLogFile,sDebugFileName);
    if (FileExists(sDebugFileName)) then
      Append(fLogFile)
    else
      Rewrite(fLogFile);
    Writeln(fLogFile,FormatDateTime('ddddd,hh:nn:ss.zzz',Now) + ',' + sLine);
    CloseFile(fLogFile);
  except
  end; // except
end; // DebugLogTemp

//***************************************************************************
//
//  FUNCTION  : FilenameValid
//
//  I/P       : sFileName (string) - The filename (excluding path) to be tested.
//
//  O/P       : (boolean) - FALSE if the filename is an empty string or
//                contains one of a number of invalid characters
//
//  OPERATION : Checks the filename for validity
//              From http://delphi.about.com/od/delphitips2009/qt/is-valid-file-name-delphi.htm
//
//              Disallow for space-only filenames.
//
//              I had previously also disallowed '[', ']', ';', '=' and ','
//              I don't see a reason not to include these again, apart from the
//              potential occurrance of a filename with a ',' in it in a field in a CSV file.
//
//  UPDATED   : 2012-05-11
//
//***************************************************************************
function FilenameValid(sFileName : string) : boolean;
var
   c : char;
begin
  // Reducing all spaces in the given filename should not result in an
  // empty string or extension separator
  sFileName := SearchAndReplace(sFileName,' ','');
  result := (sFileName <> '') and (sFileName <> '.');

  // Search for invalid characters
  if (result) then
  begin
    for c in sFileName do
    begin
     result := not CharInSet(c,['"','/','\',':',',','*','?','<','>','|']);
     if (not result) then
       break;
   end;
  end;
end; // FilenameValid

//***************************************************************************
//
//  FUNCTION  : GetTempFolder
//
//  I/P       : None
//
//  O/P       : (string) - The path to the temporary folder
//
//  OPERATION : Gets the temporary folder path - usually C:\TEMP
//
//              http://delphi.about.com/cs/adptips2000/a/bltip0900_5.htm?nl=1
//
//  UPDATED   : 2007/01/26
//
//***************************************************************************
function GetTempFolder : string;
var
  lng: DWORD;
  sThePath: string;
begin
  SetLength(sThePath, MAX_PATH);
  lng := GetTempPath(MAX_PATH, PChar(sThePath));
  SetLength(sThePath,lng);
  result := sThePath;
end; // GetTempFolder

Function GetX87SW: Word; // Assembler;
ASM
  FStSW [Result]
End;

function GetDayFromDayDesc(DoW, Week, Month: Byte; Year: Word): TDateTime;
var
  Day: TDateTime;
  DayInMonth: Integer;
  DOWDifference: Integer;
  MaxDaysInMont: Integer;
  I: Integer;
begin
  Result:= 0;

  // Bei ungültigen Werten abbrechen
  if not DoW in [1..7] then
    Exit;
  if not Month in [1..12] then
    Exit;
  if not (Week > 0) then
    Exit;

  // Erster des betrachteten Monats
  Day:= EncodeDate(Year, Month, 1);

  // Erster gesuchter Wochentag im Monat
  DOWDifference:= DoW - DayOfWeek(Day);
  if DOWDifference < 0 then
    DOWDifference:= 7 + DOWDifference;
  DayInMonth:= 1 + DOWDifference;

  // Maximale Anzahl Tage in dem Monat
  MaxDaysInMont:= MonthDays[IsLeapYear(Year), Month];
  // Beginn der letzten 7 Tage des Monats
  MaxDaysInMont:= MaxDaysInMont - 7;

  // n. Woche in diesem Monat
  for I:= 2 to Week do
  begin
    if DayInMonth > MaxDaysInMont then
      Break
    else
      Inc(DayInMonth, 7);
  end;

  Result:= EncodeDate(Year, Month, DayInMonth);
end;

function GetCurrentYear: Word;
var
  Temp: Word;
begin
  DecodeDate(Now, Result, Temp, Temp);
end;

procedure GetDSTTimes(var DSTUsed : boolean;var StartTime, EndTime : tdatetime);
var  tz: ttimezoneinformation;
     tzType : integer;
begin
  tzType  := GetTimeZoneInformation(tz);  //Get TZ structure and type
  DSTUsed := TRUE;

  case tzType of
    {TIME_ZONE_ID_STANDARD:}
    1 :  DSTUsed := TRUE;
    {TIME_ZONE_ID_DAYLIGHT:}
    2 :   DSTUsed := TRUE;
    else begin
      DSTUsed  := FALSE;
      StartTime := 0;
      EndTime   := 0;
      Exit;
    end;
  end;

  if tz.DaylightDate.wMonth = 0 then begin
    DSTUsed  := FALSE;
    StartTime := 0;
    EndTime   := 0;
    Exit;
  end;

  if tz.DaylightDate.wYear = 0 then
  begin // beschreibende Angabe
    StartTime := GetDayFromDayDesc(tz.DaylightDate.wDayOfWeek + 1,
                                   tz.DaylightDate.wDay, tz.DaylightDate.wMonth, GetCurrentYear);
    StartTime := StartTime + (tz.DaylightDate.wHour * 1/24);
    StartTime := StartTime + (tz.DaylightDate.wMinute * 1/24/60);
  end
  else
  begin // Absolute Angabe
    StartTime:= SystemTimeToDateTime(tz.DaylightDate);
  end;

  tzType  := GetTimeZoneInformation(tz);  //Get TZ structure and type

  case tzType of  // simply added to get rid of the hint when building
    {TIME_ZONE_ID_STANDARD:}
    1 :  DSTUsed := TRUE;
    {TIME_ZONE_ID_DAYLIGHT:}
    2 :   DSTUsed := TRUE;
    else begin
      DSTUsed  := FALSE;
      StartTime := 0;
      EndTime   := 0;
      Exit;
    end;
  end;

  if tz.StandardDate.wYear = 0 then
  begin // beschreibende Angabe
    EndTime := GetDayFromDayDesc(tz.StandardDate.wDayOfWeek + 1,
      tz.StandardDate.wDay, tz.StandardDate.wMonth, GetCurrentYear);
    EndTime:= EndTime + (tz.StandardDate.wHour * 1/24);
    EndTime:= EndTime + (tz.StandardDate.wMinute * 1/24/60);
  end
  else
  begin // Absolute Angabe
    EndTime:= SystemTimeToDateTime(tz.StandardDate);
  end;

end;

function GetText(str : string) : string;
begin
  {$IFDEF MULTILANG}
  if Assigned(Dictionary) then
    result := TIvDictionary(Dictionary).translate(str)
  else
  {$ENDIF }
    result := str;
end;


{$IFDEF VER220}      {Delphi XE}
  function GetFileTranslation(const Filename: string; FullName: Boolean = FALSE): string;
{$ELSE}
  function GetFileTranslation(const Filename: string; FullName: Boolean): string;
{$ENDIF}
var
  {$IFDEF VER220}      {Delphi XE}
  VerInfSize, Sz: Cardinal;
  {$ELSE}
  VerInfSize, Sz: integer;
  {$ENDIF}
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
        VerQueryValue(VerInfo, '\VarFileInfo\Translation', LangID,Sz);
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

function GetFileResourceString(FileName,VerKey:string):string;
var Dummy,InfoSize,BufferSize:dword;
    Info:pointer;
    Buffer:PChar;
    LocaleString : string;
begin
  LocaleString := GetFileTranslation(Filename,FALSE);
  Result:='';
  InfoSize:=GetFileVersionInfoSize(PChar(FileName),Dummy);
  if (InfoSize>0) then
    begin
      GetMem(Info,InfoSize);
      try
        if GetFileVersionInfo(PChar(FileName),0,InfoSize,Info) then
          if VerQueryValue(Info,PChar('\\StringFileInfo\\'+LocaleString+'\\'+VerKey),
            Pointer(Buffer),BufferSize) then Result:=Buffer
          else Result:=STRING_NOT_FOUND
        else Result:=STRING_NOT_FOUND;
      finally
        FreeMem(Info,InfoSize)
      end; // try-finally for GetMem
    end // if (InfoSize>0)
  else Result:=STRING_NOT_FOUND;
end; // function GetFileResourceString


///////////////////////// PERSISTANT FIELD CREATION /////////////////////////
procedure CreateStringField(const AOwner : tComponent;var field : tfield; const Name, Display : string; GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean;const Size : integer);
begin
  Field := tstringfield.Create(AOwner);
  Field.Name         := AOwner.name + name;
  Field.FieldName    := Name;
  Field.DisplayLabel := Name;
  Field.Calculated   := Calculated;
  Field.DataSet      := tdataset(AOwner);
  Field.Visible      := visible;
  Field.Required     := required;
  Field.size         := size;
  if Display <> ''
  then Field.DisplayLabel := Display;
  Field.OnGetText    := GetTextProcedure;
end;

procedure CreateIntegerField(const AOwner : tComponent;var field : tfield; const Name, Display : string;GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean);
begin
  Field := tintegerfield.Create(AOwner);
  Field.Name         := AOwner.name + name;
  Field.FieldName    := Name;
  Field.DisplayLabel := Name;
  Field.Calculated   := Calculated;
  Field.DataSet      := tdataset(AOwner);
  Field.Visible      := visible;
  Field.Required     := required;
  if Display <> ''
  then Field.DisplayLabel  := Display;
  Field.OnGetText    := GetTextProcedure;
end;

procedure CreateByteField(const AOwner : tComponent;var field : tfield; const Name, Display : string; GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean;const Size : integer);
begin
  Field := tbytesfield.Create(AOwner);
  Field.Name         := AOwner.name + name;
  Field.FieldName    := Name;
  Field.DisplayLabel := Name;
  Field.Calculated   := Calculated;
  Field.DataSet      := tdataset(AOwner);
  Field.Visible      := visible;
  Field.Required     := required;
  Field.size         := size;
  if Display <> ''
  then Field.DisplayLabel  := Display;
  Field.OnGetText    := GetTextProcedure;
end;

procedure CreateBooleanField(const AOwner : tComponent;var field : tfield; const Name, Display : string; GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean);
begin
  Field := tbooleanfield.Create(AOwner);
  Field.Name         := AOwner.name + name;
  Field.FieldName    := Name;
  Field.DisplayLabel := Name;
  Field.Calculated   := Calculated;
  Field.DataSet      := tdataset(AOwner);
  Field.Visible      := visible;
  Field.Required     := required;
  if Display <> ''
  then Field.DisplayLabel  := Display;
  Field.OnGetText    := GetTextProcedure;
end;

procedure CreateDateTimeField(const AOwner : tComponent;var field : tfield; const Name, Display : string; GetTextProcedure : TFieldGetTextEvent;const Calculated, Visible, Required : boolean);
begin
  Field := tdatetimefield.Create(AOwner);
  Field.Name         := AOwner.name + name;
  Field.FieldName    := Name;
  Field.DisplayLabel := Name;
  Field.Calculated   := Calculated;
  Field.DataSet      := tdataset(AOwner);
  Field.Visible      := visible;
  Field.Required     := required;
  if Display <> ''
  then Field.DisplayLabel  := Display;
  Field.OnGetText    := GetTextProcedure;
end;

end.
