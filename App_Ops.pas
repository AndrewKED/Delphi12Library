unit App_Ops;

interface

const
  VER_CMP_A_SAME_AS_B = 0;
  VER_CMP_A_OLDER_THAN_B = -1;
  VER_CMP_A_NEWER_THAN_B = 1;

type
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

function GetApplicationVersion(bBuild : boolean = FALSE) : String;
function CompareVersions(sAppVer1 : String;
                         sAppVer2 : String;
                         iDepth : integer) : Integer;
procedure CloseApplication(sAppName : string);
// function ProcessExists(exeFileName: string): boolean;
procedure HookResourceString(rs: PResStringRec; newStr: PChar);
procedure TellWindowsWeArentFrozen;
function LinkerTimeStamp(const FileName: string): TDateTime; overload;
function LinkerTimestamp: TDateTime; overload;
function GetCopyrightYear : Integer;

var
  SystemCritical: TSystemCritical;
  runningUnderIDE : Boolean;
  debugCompilation : Boolean;
  folderApplication : String;

implementation

uses
  System.SysUtils, System.DateUtils,
  Windows,
  VCL.Forms,
  WinAPI.Messages,
  ImageHlp,
  File_Ops, Str_Ops;

{ TSystemCritical }
type
  EXECUTION_STATE = DWORD;
const
  ES_SYSTEM_REQUIRED = $00000001;
  ES_DISPLAY_REQUIRED = $00000002;
  ES_USER_PRESENT = $00000004;
  ES_AWAYMODE_REQUIRED = $00000040;
  ES_CONTINUOUS = $80000000;
  KernelDLL = 'kernel32.dll';

var
  LastPeekMessageTime: Cardinal = 0;

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
//  FUNCTION  : GetApplicationVersion
//
//  I/P       : bBuild : Boolean = FALSE - Whether the build number is to be
//                added as the 4th portion of the version, or not.
//
//  O/P       : String - The version number in format v.x.y.build or v.x.y
//
//  OPERATION : Note that for this to work "properly" (or at least in the way
//              that I like my application version numbers), the Delphi project
//              options should specify "Do not change build number" or, preferably,
//              "Auto increment build number".
//
//              "Auto generate build number", as far as I have been able to
//              ascertain, stores dwFileVersionLS as the days since 2000-01-01
//              (high word) and number of seconds since midnight div 2 (low word).
//
//  UPDATED   : 2015-11-19
//
//***************************************************************************
function GetApplicationVersion(bBuild : boolean = FALSE) : String;
var
  VerInfoSize: DWORD;
  VerInfo: pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;

begin
  VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
  GetMem(VerInfo, VerInfoSize);
  GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
  if (VerInfo <> nil) then
  begin
    VerQueryValue(VerInfo, '\', pointer(VerValue), VerValueSize);

    result := IntToStr(VerValue^.dwFileVersionMS shr 16) + '.' +
              IntToStr(VerValue^.dwFileVersionMS and $FFFF) + '.' +
              IntTostr(VerValue^.dwFileVersionLS shr 16);
    if (bBuild) then
      result := result + '.' +
                IntToStr(VerValue^.dwFileVersionLS and $FFFF);
  end // if
  else
    result := '?';

  FreeMem(VerInfo, VerInfoSize);

(*
var
  Exe: string;
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedPtr: PVSFixedFileInfo;
begin
  Exe := ParamStr(0);
  Size := GetFileVersionInfoSize(PChar(Exe), Handle);
  if Size = 0 then
    RaiseLastOSError;
  SetLength(Buffer, Size);
  if not GetFileVersionInfo(PChar(Exe), Handle, Size, Buffer) then
    RaiseLastOSError;
  if not VerQueryValue(Buffer, '\', Pointer(FixedPtr), Size) then
    RaiseLastOSError;
  Result := Format('%d.%d.%d.%d',
    [LongRec(FixedPtr.dwFileVersionMS).Hi,  //major
     LongRec(FixedPtr.dwFileVersionMS).Lo,  //minor
     LongRec(FixedPtr.dwFileVersionLS).Hi,  //release
     LongRec(FixedPtr.dwFileVersionLS).Lo]) //build
*)
end; // GetApplicationVersion

(*
procedure TForm1.Button1Click(Sender: TObject);

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
//  FUNCTION   : Running32ON64
//
//  I/P        :
//
//  O/P        :
//
//  OPERATION : See http://delphi.about.com/od/delphi-tips-2011/qt/is-your-32bit-delphi-applications-running-on-x86-win-32-or-x64-win-64.htm
//
//  UPDATED   : 2012-07-18
//
//***************************************************************************
function Running32ON64: boolean;
type
  TIsWow64Process = function(Handle:THandle; var IsWow64 : boolean) : boolean; stdcall;
var
  hDLL : cardinal;
  IsWow64Process : TIsWow64Process;
begin
  result := false;
  hDLL := LoadLibrary('kernel32.dll');
  if (hDLL = 0) then Exit;
  try
    @IsWow64Process := GetProcAddress(hDLL, 'IsWow64Process');
    if Assigned(IsWow64Process) then IsWow64Process(GetCurrentProcess, result);
  finally
    FreeLibrary(hDLL);
  end;
end;
(*
//***************************************************************************
//
//  FUNCTION  : ProcessExists
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Check if a process from the task list is active.
//              from
//              http://www.delphitricks.com/source-code/windows/check_if_a_process_is_running.html
//
//  UPDATED   : 2015-11-11
//
//***************************************************************************
function ProcessExists(exeFileName: string): boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;

begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  Result := False;
  while (Integer(ContinueLoop) <> 0) do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
    begin
      Result := True;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end; // ProcessExists
*)
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
  SystemCritical := TSystemCritical.Create;

  // Indicate if the program is running under the IDE
  runningUnderIDE := (DebugHook <> 0);

{$IFDEF DEBUG}
  debugCompilation := TRUE;
{$ELSE}
  debugCompilation := FALSE;
{$ENDIF}

  folderApplication := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
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
  SystemCritical.IsCritical := False;
  SystemCritical.Free;
end.
