unit Prog_Ops;

interface

function GetVersionString(sFilename: String; bAddBuild : Boolean): String;

implementation

uses Windows, SysUtils,
     Str_Ops;

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
function GetFileTranslation(const Filename: string; FullName: Boolean): string;
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
function GetFileResourceString(sFileName,sVerKey:string) : string;
var
    Dummy,InfoSize,BufferSize : dword;
    Info : pointer;
    Buffer : PChar;
    sLocaleString : string;
begin
  sLocaleString := GetFileTranslation(sFilename,False);
  Result := '';
  InfoSize := GetFileVersionInfoSize(PChar(sFileName),Dummy);
  if (InfoSize > 0) then
  begin
    GetMem(Info,InfoSize);
    try
      if GetFileVersionInfo(PChar(sFileName),0,InfoSize,Info) then
        if VerQueryValue(Info,PChar('\\StringFileInfo\\'+sLocaleString+'\\'+sVerKey),
          Pointer(Buffer),BufferSize) then
          result := Buffer
        else
          result := ''
      else
        result := '';
    finally
      FreeMem(Info,InfoSize)
    end; // try-finally for GetMem
  end // if (InfoSize>0)
  else
    result:='';
end; // GetFileResourceString

//***************************************************************************
//
//  FUNCTION  : GetVersionString
//
//  I/P       : sFilename (string) - The filename of the Delphi-created exe
//                file from which the version information is to be extracted.
//
//              bAddBuild (boolean) - TRUE if the "build" portion of the
//                version is to be included.
//
//  O/P       : (string) - The resulting version string.
//
//  OPERATION : Originally from GSCToolbox unit.
//
//  UPDATED   : 2006/08/07
//
//***************************************************************************
function GetVersionString(sFilename: string; bAddBuild : Boolean): string;
var
    sTemp : string;
    sGlobalVersion : string;
begin
  sTemp := GetFileResourceString(sFilename,'FileVersion');
  sGlobalVersion := Copy(sTemp,1,pos('.',sTemp));
  Delete(sTemp,1,Pos('.',sTemp));
  Delete(sTemp,1,Pos('.',sTemp));
  sGlobalVersion := sGlobalVersion + Front_Padded(Copy(sTemp,1,Pos('.',sTemp)-1),'0',2);
  Delete(sTemp,1,Pos('.',sTemp));
  result := sGlobalVersion;
  if bAddBuild then
    result := result + '.' + sTemp;
end;

end.
