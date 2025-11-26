unit App_Ops;

interface

const
  VER_CMP_A_SAME_AS_B = 0;
  VER_CMP_A_OLDER_THAN_B = -1;
  VER_CMP_A_NEWER_THAN_B = 1;

type
  TSWVersion = record
    filename : String;
    version : String;
  end;

  TSWVersions = array of TSWVersion;

function runningUnderIDE : Boolean;
function debugCompilation : Boolean;
function folderApplication : String;
function CompareVersions(sAppVer1 : String;
                         sAppVer2 : String;
                         iDepth : integer) : Integer;
function GetFileVersion(const fileName : string;
                        const includeBuild : boolean = FALSE) : string;
function GetApplicationVersion(const includeBuild : boolean = FALSE) : String;
function FileVersionsOK(checkInfo : array of TSWVersion) : String;
procedure CloseApplication(sAppName : string);
// function ProcessExists(exeFileName: string): boolean;
procedure HookResourceString(rs: PResStringRec; newStr: PChar);
procedure TellWindowsWeArentFrozen;
function LinkerTimeStamp(const FileName: string): TDateTime; overload;
function LinkerTimestamp: TDateTime; overload;
function GetCopyrightYear : Integer;
function DelphiVersion : String;

implementation

uses
  System.SysUtils, System.DateUtils,
  System.Win.Registry,
  Winapi.Windows,
  VCL.Forms,
  WinAPI.Messages,
  ImageHlp,
  File_Ops, Str_Ops;

const
  ES_SYSTEM_REQUIRED = $00000001;
  ES_DISPLAY_REQUIRED = $00000002;
  ES_USER_PRESENT = $00000004;
  ES_AWAYMODE_REQUIRED = $00000040;
  ES_CONTINUOUS = $80000000;
  KernelDLL = 'kernel32.dll';

type
  EXECUTION_STATE = DWORD;

  TSystemCritical = class
  private
    FIsCritical: Boolean;
    procedure SetIsCritical(const Value: Boolean) ;
  protected
    procedure UpdateCritical(Value: Boolean) ; virtual;
  public
    constructor Create;
    property IsCritical: Boolean read FIsCritical write SetIsCritical;
  end;

var
  LastPeekMessageTime: Cardinal = 0;
  Handle : HMODULE;
  SystemCritical: TSystemCritical;

//***************************************************************************
//
//  FUNCTION  : runningUnderIDE
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the application is running under the IDE
//
//  OPERATION : Indicate if the program is running under the IDE
//
//  UPDATED   : 2024-10-08
//
//***************************************************************************
function runningUnderIDE : Boolean;
begin
  Result := (DebugHook <> 0)
end; // runningUnderIDE

//***************************************************************************
//
//  FUNCTION  : debugCompilation
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the application has been compiled as DEBUG
//
//  OPERATION : Indicate if the application has been compiled as DEBUG
//
//  UPDATED   : 2024-10-08
//
//***************************************************************************
function debugCompilation : Boolean;
begin
{$IFDEF DEBUG}
  Result := TRUE;
{$ELSE}
  Result := FALSE;
{$ENDIF}
end; // debugCompilation

//***************************************************************************
//
//  FUNCTION  : folderApplication
//
//  I/P       : None
//
//  O/P       : String - The folder in which the application is found.
//
//  OPERATION : Get the full path of the folder in which the application is found.
//
//  UPDATED   : 2024-10-08
//
//***************************************************************************
function folderApplication : String;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
end; // folderApplication

//***************************************************************************
//
//  FUNCTION  : CompareVersions
//
//  I/P       : sAppVer1 (string) - The first version number
//
//              sAppVer2 (string) - The second version number
//
//              iDepth (integer) - The depth to which the version numbers
//                are to be compared (1 = Major, 2 = Minor, 3 = Release
//                else all i.e. to Build)
//
//  O/P       : Integer -
//                VER_CMP_A_OLDER_THAN_B if sAppVer1 is less than sAppVer2 to the given depth.
//                VER_CMP_A_NEWER_THAN_B if sAppVer1 is greater than sAppVer2 to the given depth.
//                VER_CMP_A_SAME_AS_B if they are equivalent to the given depth.
//
//  OPERATION : Compares a pair of version numbers which are provided in
//              the format that can be up to 4 levels i.e. M.m.r.b
//              (Major version.Minor version.Release.Build)
//              Compare to a specified depth.
//
//              Note that if the versions can not be converted to numbers,
//              they will be assumed to have the value VER_CMP_A_SAME_AS_B.
//
//  UPDATED   : 2007/02/19
//
//***************************************************************************
function CompareVersions(sAppVer1 : String;
                         sAppVer2 : String;
                         iDepth : integer) : Integer;
var
  n : Integer;
  aiAppVer1 : array[1..4] of integer;
  aiAppVer2 : array[1..4] of integer;
  iCode : Integer;

begin
  // Extract the 4 parts of each of the version numbers
  for n := 1 to 4 do
  begin
    Val(ExtractAndTrim(sAppVer1,'.'),aiAppVer1[n],iCode);
    Val(ExtractAndTrim(sAppVer2,'.'),aiAppVer2[n],iCode);
  end; // for

  case iDepth of
    1 :
    begin
      // Compare the Major Version only
      if (aiAppVer1[1] > aiAppVer2[1]) then
        result := VER_CMP_A_NEWER_THAN_B
      else
        if (aiAppVer1[1] < aiAppVer2[1]) then
          result := VER_CMP_A_OLDER_THAN_B
        else
          result := VER_CMP_A_SAME_AS_B;
    end; // option

    2 :
    begin
      // Compare the Major and Minor Versions
      if (aiAppVer1[1] > aiAppVer2[1]) then
        result := VER_CMP_A_NEWER_THAN_B
      else
        if (aiAppVer1[1] < aiAppVer2[1]) then
          result := VER_CMP_A_OLDER_THAN_B
        else
          if (aiAppVer1[2] > aiAppVer2[2]) then
            result := VER_CMP_A_NEWER_THAN_B
          else
            if (aiAppVer1[2] < aiAppVer2[2]) then
              result := VER_CMP_A_OLDER_THAN_B
            else
              result := VER_CMP_A_SAME_AS_B;
    end; // option

    3 :
    begin
      // Compare the Major, Minor and Release Versions
      if (aiAppVer1[1] > aiAppVer2[1]) then
        result := VER_CMP_A_NEWER_THAN_B
      else
        if (aiAppVer1[1] < aiAppVer2[1]) then
          result := VER_CMP_A_OLDER_THAN_B
        else
          if (aiAppVer1[2] > aiAppVer2[2]) then
            result := VER_CMP_A_NEWER_THAN_B
          else
            if (aiAppVer1[2] < aiAppVer2[2]) then
              result := VER_CMP_A_OLDER_THAN_B
            else
              if (aiAppVer1[3] > aiAppVer2[3]) then
                result := VER_CMP_A_NEWER_THAN_B
              else
                if (aiAppVer1[3] < aiAppVer2[3]) then
                  result := VER_CMP_A_OLDER_THAN_B
                else
                  result := VER_CMP_A_SAME_AS_B;
    end; // option

    else
    begin
      // Compare the Major, Minor, Release and Build Versions
      if (aiAppVer1[1] > aiAppVer2[1]) then
        result := VER_CMP_A_NEWER_THAN_B
      else
        if (aiAppVer1[1] < aiAppVer2[1]) then
          result := VER_CMP_A_OLDER_THAN_B
        else
          if (aiAppVer1[2] > aiAppVer2[2]) then
            result := VER_CMP_A_NEWER_THAN_B
          else
            if (aiAppVer1[2] < aiAppVer2[2]) then
              result := VER_CMP_A_OLDER_THAN_B
            else
              if (aiAppVer1[3] > aiAppVer2[3]) then
                result := VER_CMP_A_NEWER_THAN_B
              else
                if (aiAppVer1[3] < aiAppVer2[3]) then
                  result := VER_CMP_A_OLDER_THAN_B
                else
                  if (aiAppVer1[4] > aiAppVer2[4]) then
                    result := VER_CMP_A_NEWER_THAN_B
                  else
                    if (aiAppVer1[4] < aiAppVer2[4]) then
                      result := VER_CMP_A_OLDER_THAN_B
                    else
                      result := VER_CMP_A_SAME_AS_B;
    end; // else
  end; // case
end; // CompareVersions

//***************************************************************************
//
//  FUNCTION  : GetFileVersion
//
//  I/P       : fileName : string - The path and filename of the file
//
//              includeBuild : Boolean = FALSE - Whether the build number is
//                to be added as the 4th portion of the version, or not.
//
//  O/P       : String - The version number in format v.x.y.build or v.x.y
//
//  OPERATION : Get the version number of the given file.
//
//  UPDATED   : 2023-02-07
//
//***************************************************************************
function GetFileVersion(const fileName : string;
                        const includeBuild : boolean = FALSE) : string;
var
  verInfoSize : DWORD;
  verInfo : pointer;
  verValueSize : UINT;
  verValue : PVSFixedFileInfo;
  wnd : DWORD;

begin
  Result := '?';

  verInfoSize := GetFileVersioninfoSize(PChar(fileName), wnd);

  if (verInfoSize <> 0) then
  begin
    GetMem(verInfo, verInfoSize);
    try
      if (GetFileVersionInfo(PChar(fileName), 0, verInfoSize, verInfo)) then
      begin
        if (VerQueryValue(verInfo, '\', Pointer(verValue), VerValueSize)) then;
        begin
          Result := IntToStr(verValue.dwFileVersionMS shr 16) + '.' +
                    IntToStr(verValue.dwFileVersionMS and $FFFF) + '.' +
                    IntToStr(verValue.dwFileVersionLS shr 16);
          if (includeBuild) then
          begin
            Result := Result + '.' +
                      IntToStr(VerValue.dwFileVersionLS and $FFFF);
          end; // if
        end; // if
//      else
//      begin
//        RaiseLastOSError;
//      end;
      end; // if
//    else
//    begin
//      RaiseLastOSError;
//    end;
    finally
      FreeMem(verInfo);
    end;
  end; // if
//  else
//  begin
//    RaiseLastOSError;
//  end;
end; // GetFileVersion

//***************************************************************************
//
//  FUNCTION  : GetApplicationVersion
//
//  I/P       : includeBuild : Boolean = FALSE - Whether the build number is to be
//                added as the 4th portion of the version, or not.
//
//  O/P       : String - The version number in format v.x.y.build or v.x.y
//
//  OPERATION : Get the version number of the application.
//
//              Note that for this to work "properly" (or at least in the way
//              that I like my application version numbers), the Delphi project
//              options should specify "Do not change build number" or,
//              preferably, "Auto increment build number".
//
//              "Auto generate build number", as far as I have been able to
//              ascertain, stores dwFileVersionLS as the days since 2000-01-01
//              (high word) and number of seconds since midnight div 2 (low word).
//
//  UPDATED   : 2023-02-07
//
//***************************************************************************
function GetApplicationVersion(const includeBuild : boolean = FALSE) : String;
begin
  Result := GetFileVersion(ParamStr(0), includeBuild);
end; // GetApplicationVersion

(*
const
  InfoNum = 10;
  InfoStr: array[1..InfoNum] of string = ('CompanyName', 'FileDescription', 'FileVersion', 'InternalName', 'LegalCopyright', 'LegalTradeMarks', 'OriginalFileName', 'ProductName', 'ProductVersion', 'Comments');

var
  S: string;
  n, Len, i: DWORD;
  Buf: PChar;
  Value: PChar;

begin
  S := Application.ExeName;
  n := GetFileVersionInfoSize(PChar(S), n);
  if n > 0 then
  begin
    Buf := AllocMem(n);
    Memo1.Lines.Add('VersionInfoSize = ' + IntToStr(n));
    GetFileVersionInfo(PChar(S), 0, n, Buf);
    for i := 1 to InfoNum do
      if VerQueryValue(Buf, PChar('StringFileInfo\040904E4\' + InfoStr[i]), Pointer(Value), Len) then
        Memo1.Lines.Add(InfoStr[i] + ' = ' + Value);
    FreeMem(Buf, n);
  end
  else
    Memo1.Lines.Add('No version information found');
end;
*)

//***************************************************************************
//
//  FUNCTION  : FileVersionsOK
//
//  I/P       : checkInfo : array of TSWVersion - An array of filename and
//                expected version pairings.
//
//  O/P       : String - Empty if all filenames have the expected version
//                The problem filename, if there is a mismatch.
//
//  OPERATION : Check that the list of filenames (of exe and/or dll files) each
//              have the expected version numbers.
//
//              The version numbers may be specified as a.b.c.d or a.b.c
//
//              This is typically used to ensure that installations have been
//              correctly made.
//
//  UPDATED   : 2023-02-09
//
//***************************************************************************
function FileVersionsOK(checkInfo : array of TSWVersion) : String;
var
  n: Integer;
  verFound : String;

begin
  Result := '';

  for n := 0 to Length(checkInfo)-1 do
  begin
    verFound := GetFileVersion(checkInfo[n].filename, Count_Chars(checkInfo[n].version,'.')=3);
    if (verFound <> checkInfo[n].version) then
    begin
      // Keep the response simple, for possible inclusion in a dialog/log line
      Result := checkInfo[n].filename;
      break;
    end; // if
  end; // for
end; // FileVersionsOK

//***************************************************************************
//
//  FUNCTION  : SetThreadExecutionState
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Enables an application to inform the system that it is in use,
//              thereby preventing the system from entering sleep or turning
//              off the display while the application is running.
//
//              Part of TSystemCritical see
//              http://msdn.microsoft.com/en-us/library/aa373208.aspx
//              http://delphi.about.com/od/delphitips2008/qt/nosleep.htm
//              http://delphidabbler.com/tips/127
//
//  UPDATED   : 2010-11-17
//
//***************************************************************************
procedure SetThreadExecutionState(ESFlags: EXECUTION_STATE) ; stdcall; external kernel32 name 'SetThreadExecutionState';

constructor TSystemCritical.Create;
begin
  inherited;
  FIsCritical := False;
end;

//***************************************************************************
//
//  FUNCTION   : SetIsCritical
//
//  I/P        :
//
//  O/P        :
//
//  OPERATION : Part of TSystemCritical see
//              http://msdn.microsoft.com/en-us/library/aa373208.aspx
//              http://delphi.about.com/od/delphitips2008/qt/nosleep.htm
//              http://delphidabbler.com/tips/127
//
//  UPDATED   : 2010-11-17
//
//***************************************************************************
procedure TSystemCritical.SetIsCritical(const Value: Boolean) ;
begin
  if FIsCritical = Value then Exit;

  FIsCritical := Value;
  UpdateCritical(FIsCritical);
end;

//***************************************************************************
//
//  FUNCTION   : UpdateCritical
//
//  I/P        :
//
//  O/P        :
//
//  OPERATION : Part of TSystemCritical see
//              http://msdn.microsoft.com/en-us/library/aa373208.aspx
//              http://delphi.about.com/od/delphitips2008/qt/nosleep.htm
//              http://delphidabbler.com/tips/127
//
//  UPDATED   : 2010-11-17
//
//***************************************************************************
procedure TSystemCritical.UpdateCritical(Value: Boolean) ;
begin
  if Value then //Prevent the sleep idle time-out and Power off.
    SetThreadExecutionState(ES_SYSTEM_REQUIRED or ES_CONTINUOUS)
  else //Clear EXECUTION_STATE flags to disable away mode and allow the system to idle to sleep normally.
    SetThreadExecutionState(ES_CONTINUOUS) ;
end;

//***************************************************************************
//
//  FUNCTION  : CloseApplication
//
//  I/P       : sAppName : String - The Window name (Title)
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure CloseApplication(sAppName : string);
var
  H: HWND;
begin
  H := FindWindow(nil, pWideChar(sAppName));
  if (H <> 0) then
    PostMessage(H, WM_CLOSE, 0, 0);
end; // CloseApplication

//***************************************************************************
//
//  FUNCTION  : HookResourceString
//
//  I/P       : rs: PResStringRec - Pointer to a resource string.   Typically
//                one that appears in
//                c:\Program Files\Embarcadero\Studio\17.0\source\vcl\Vcl.Consts.pas
//
//              newStr: PChar - The replacement string
//
//  O/P       : None
//
//  OPERATION : From http://www.delphibasics.info/home/delphibasicssnippets/changeresourcestringsatruntime
//              Change a resource string at runtime.
//
//  UPDATED   : 2015-11-05
//
//***************************************************************************
procedure HookResourceString(rs: PResStringRec; newStr: PChar);
var
  oldprotect: DWORD;

begin
  VirtualProtect(rs, SizeOf(rs^), PAGE_EXECUTE_READWRITE, @oldProtect);
  rs^.Identifier := Integer(newStr);
  VirtualProtect(rs, SizeOf(rs^), oldProtect, @oldProtect);
end;

//***************************************************************************
//
//  FUNCTION  : TellWindowsWeArentFrozen
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : From http://blog.excastle.com/2005/08/15/telling-windows-were-not-really-not-responding/comment-page-1/
//
//              Application.ProcessMessages is dangerous (see various forum
//              articles) to use as a weapon against Windows' "Not Responding"
//              message.
//
//              PeekMessage, called more often than once every 5 seconds, will
//              do a non-destructive read on the message queue, and result in
//              suppression of "Not Responding" messages.   So, call this
//              function (which introduces a slight time overhead) from within
//              long calculations/operations.
//
//              See also : https://msdn.microsoft.com/en-us/library/windows/desktop/ms633526(v=vs.85).aspx
//              for the comment that "The Windows timeout criteria of 5 seconds is subject to change."
//              NOTE : THIS WILL STILL MAKE THE APP LOOK
//
//  UPDATED   : 2017-10-27
//
//***************************************************************************
procedure TellWindowsWeArentFrozen;
var
  Msg: TMsg;

begin
  if (GetTickCount <> LastPeekMessageTime) then
  begin
    PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE);
    LastPeekMessageTime := GetTickCount;
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
//  UPDATED   : 2019-11-19
//
//***************************************************************************
function LinkerTimeStamp(const FileName: string): TDateTime; overload;
var
  LI: TLoadedImage;

begin
  Win32Check(MapAndLoad(PAnsiChar(AnsiString(FileName)), nil, @LI, False, True));
  Result := LI.FileHeader.FileHeader.TimeDateStamp / SecsPerDay + UnixDateDelta;
  UnMapAndLoad(@LI);
end;

function LinkerTimestamp: TDateTime; overload;
begin
  Result := PImageNtHeaders(HInstance + Cardinal(PImageDosHeader(HInstance)^._lfanew))^.FileHeader.TimeDateStamp / SecsPerDay + UnixDateDelta;
end;

//***************************************************************************
//
//  FUNCTION  : GetCopyrightYear
//
//  I/P       : None
//
//  O/P       : Integer - The year of application .exe file modification
//
//  OPERATION : Get the year of last modification of the application
//
//  UPDATED   : 2021-09-13
//
//***************************************************************************
function GetCopyrightYear : Integer;
var
  sr : TSearchRec;

begin
  Result := 2021;
  if System.SysUtils.FindFirst(Application.ExeName, faReadOnly or faAnyFile, sr) = 0 then
  begin
    try
      Result := YearOf(sr.TimeStamp);
    finally
      System.SysUtils.FindClose(sr);
    end
  end;
end; // GetCopyrightYear

//***************************************************************************
//
//  FUNCTION  : DelphiVersion
//
//  I/P       : None
//
//  O/P       : String - The (main) Delphi version
//
//  OPERATION : Get the Delphi Version.
//
//              Based on information from
//              https://github.com/omonien/Delphi-Version-Information
//
//  UPDATED   : 2024-12-12
//
//***************************************************************************
function DelphiVersion : String;
begin
  if (System.CompilerVersion >= 36.0) then
    Result := '12'
  else if (System.CompilerVersion >= 35.0) then
    Result := '11'
  else if (System.CompilerVersion >= 34.0) then
    Result := '10.4'
  else if (System.CompilerVersion >= 33.0) then
    Result := '10.3'
  else if (System.CompilerVersion >= 32.0) then
    Result := '10.2'
  else if (System.CompilerVersion >= 31.0) then
    Result := '10.1'
  else if (System.CompilerVersion >= 30.0) then
    Result := '10'
  else if (System.CompilerVersion >= 29.0) then
    Result := 'XE8'
  else if (System.CompilerVersion >= 28.0) then
    Result := 'XE7'
  else if (System.CompilerVersion >= 27.0) then
    Result := 'XE6'
  else if (System.CompilerVersion >= 26.0) then
    Result := 'XE5'
  else if (System.CompilerVersion >= 25.0) then
    Result := 'XE4'
  else if (System.CompilerVersion >= 24.0) then
    Result := 'XE3'
  else if (System.CompilerVersion >= 23.0) then
    Result := 'XE2'
  else if (System.CompilerVersion >= 22.0) then
    Result := 'XE'
  else if (System.CompilerVersion >= 21.0) then
    Result := '2010'
  else if (System.CompilerVersion >= 20.0) then
    Result := '2009'
  else if (System.CompilerVersion >= 18.5) then
    Result := '2007'
  else if (System.CompilerVersion >= 18.0) then
    Result := '2006'
  else if (System.CompilerVersion >= 17.0) then
    Result := '2005'
  else if (System.CompilerVersion >= 16.0) then
    Result := '8'
  else if (System.CompilerVersion >= 15.0) then
    Result := '7/7.1'
  else if (System.CompilerVersion >= 14.0) then
    Result := '6'
  else
    Result := '?';
end;

//***************************************************************************
//
//  FUNCTION   :
//
//  I/P        :
//
//  O/P        :
//
//  OPERATION : Part of TSystemCritical see
//              http://msdn.microsoft.com/en-us/library/aa373208.aspx
//              http://delphi.about.com/od/delphitips2008/qt/nosleep.htm
//              http://delphidabbler.com/tips/127
//
//  UPDATED   : 2018-03-14
//
//***************************************************************************
initialization
begin
  Handle := LoadLibrary(KernelDLL);
  if (Handle <> 0) then
  begin
    if (GetProcAddress(Handle, 'InitializeCriticalSectionEx') <> nil) then
    begin
      SystemCritical := TSystemCritical.Create;
    end;
  end;
end;

//***************************************************************************
//
//  FUNCTION   :
//
//  I/P        :
//
//  O/P        :
//
//  OPERATION : Part of TSystemCritical see
//              http://msdn.microsoft.com/en-us/library/aa373208.aspx
//              http://delphi.about.com/od/delphitips2008/qt/nosleep.htm
//
//  UPDATED   : 2010-11-17
//
//***************************************************************************
finalization
  if (SystemCritical <> nil) then
  begin
    SystemCritical.IsCritical := False;
    SystemCritical.Free;
  end;
end.
