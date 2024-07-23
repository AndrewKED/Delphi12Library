unit WinAPI_Ops;

interface

function WUserName: String;
function GetLocalComputerName: string;
function GetSecurityID(lpSystemName : String;
                       lpAccountName : String) : String;
function GetEdgeVersion : String;
function Is64BitHardware: Boolean;
function Is64BitWindows: Boolean;
function GetWebView2RuntimeVersion : String;
function ClosedRunningApplication(exeName : String) : Boolean;

implementation

uses
  System.SysUtils, System.Win.Registry,
  WinApi.Windows, WinApi.TLHelp32;

function ConvertSidToStringSid(Sid: PSID; out StringSid: PChar): BOOL; stdcall;  external 'ADVAPI32.DLL' name {$IFDEF UNICODE} 'ConvertSidToStringSidW'{$ELSE} 'ConvertSidToStringSidA'{$ENDIF};

var
  GetAvailableCoreWebView2BrowserVersionString: function(browserExecutableFolder: PWideChar; versioninfo: PPWideChar): HRESULT; stdcall;
  versionEdge: PWideChar;

//***************************************************************************
//
//  FUNCTION  : SIDToString
//
//  I/P       : ASID: PSID - Pointer to the SID
//
//  O/P       : String - The SID in string form
//
//  OPERATION : Converts the given SID into a string form "suitable for display,
//              storage, or transmission". An empty string is returned if the
//              conversion did not proceed correctly.
//
//              See
//              https://docs.microsoft.com/en-us/windows/win32/api/sddl/nf-sddl-convertsidtostringsida
//
//  UPDATED   : 2019-11-06
//
//***************************************************************************
function SIDToString(ASID: PSID): string;
var
  StringSid : PChar;

begin
  if (ConvertSidToStringSid(ASID, StringSid)) then
  begin
    Result := string(StringSid);
  end // if
  else
  begin
    // RaiseLastWin32Error;
    Result := '';
  end; // else
end; // SIDToString

//***************************************************************************
//
//  FUNCTION  : WUserName
//
//  I/P       : None
//
//  O/P       : String - The current username
//
//  OPERATION : Returns the UserName of the currently signed-on user
//
//              From http://stackoverflow.com/questions/17599086/how-to-get-currently-logged-in-username
//
//              Note that the nSize value returned INCLUDES the null terminator.
//
//  UPDATED   : 2019-11-06
//
//***************************************************************************
function WUserName: String;
var
  nSize: DWord;

begin
 nSize := 1024;
 SetLength(Result, nSize);
 if not GetUserName(PChar(Result), nSize) then
 begin
   Result := '';
   Exit;
 end;

 SetLength(Result, nSize-1)
end;

//***************************************************************************
//
//  FUNCTION  : GetLocalComputerName
//
//  I/P       : None
//
//  O/P       : String - The current username
//
//  OPERATION : Returns the name of the local computer
//
//              Modified from WUserName, above
//
//              Note that the nSize value returned DOES NOT INCLUDE the null terminator.
//
//  UPDATED   : 2019-11-06
//
//***************************************************************************
function GetLocalComputerName: string;
var
  nSize: DWORD;

begin
  nSize := MAX_COMPUTERNAME_LENGTH + 1;
  SetLength(Result, nSize);
  if not GetComputerName(PChar(Result), nSize) then
  begin
    Result := '';
    Exit;
  end;

  SetLength(Result, nSize);
end;

//***************************************************************************
//
//  FUNCTION  : GetSecurityID
//
//  I/P       : lpSystemName : String - Empty string?
//
//              lpAccountName : String - The account name for which the SID
//                is to be obtained.
//
//  O/P       : String - The SID in string format, or an empty string if there
//                was an error
//
//  OPERATION : Some references:
//              https://www.windows-commandline.com/get-sid-of-user/
//              https://www.lifewire.com/how-to-find-a-users-security-identifier-sid-in-windows-2625149
//              https://stackoverflow.com/questions/787419/unique-identifier-for-user-profiles-in-windows
//
//  UPDATED   : 2019-11-06
//
//***************************************************************************
function GetSecurityID(lpSystemName : String;
                       lpAccountName : String) : String;
var
  Sid: PSID;
  cbSid: DWORD;
  cbReferencedDomainName : DWORD;
  ReferencedDomainName: string;
  peUse: SID_NAME_USE;
  Success: BOOL;

begin
  Sid := nil;
  try
    cbSid := 0;
    cbReferencedDomainName := 0;
    // First call to LookupAccountName to get the buffer sizes.
    Success := LookupAccountName(PChar(lpSystemName), PChar(lpAccountName),
                                 nil, cbSid,
                                 nil, cbReferencedDomainName,
                                 peUse);
    if ((not Success) and
        (GetLastError = ERROR_INSUFFICIENT_BUFFER)) then
    begin
      SetLength(ReferencedDomainName, cbReferencedDomainName);
      Sid := AllocMem(cbSid);
      // Second call to LookupAccountName to get the SID.
      Success := LookupAccountName(PChar(lpSystemName), PChar(lpAccountName),
                                   Sid, cbSid,
                                   PChar(ReferencedDomainName), cbReferencedDomainName,
                                   peUse);
      if (not Success) then
      begin
        FreeMem(Sid);
        Sid := nil;
        Result := '';
        // RaiseLastOSError;
      end
      else
        Result := SIDToString(Sid);
    end
    else
    begin
      Result := '';
      // RaiseLastOSError;
    end; // else
  finally
    if (Assigned(Sid)) then
      FreeMem(Sid);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : GetEdgeVersion
//
//  I/P       : None
//
//  O/P       : String - The version number
//
//  OPERATION : Get the version number of Microsoft Edge
//
//  UPDATED   : 2023-02-10
//
//***************************************************************************
function GetEdgeVersion : String;
var
  registry : TRegistry;
  openResult : Boolean;

begin
  Result := '';

  registry := TRegistry.Create;
  try
    registry.RootKey := HKEY_CURRENT_USER;
    if (registry.KeyExists('Software\Microsoft\Edge\BLBeacon\')) then
    begin
      registry.Access := KEY_READ;
      openResult := registry.OpenKeyReadOnly('Software\Microsoft\Edge\BLBeacon\');
      if (openResult) then
      begin
        Result := registry.ReadString('version');
      end;
    end;
  finally
    registry.CloseKey();
    registry.Free;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : Is64BitHardware
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the processor is 64-bit architecture.
//
//  OPERATION : Check if this is a 64-bit CPU.
//
//              Note that, as some have pointed out, that you can have a
//              32-bit Windows installation on 64-bit hardware.
//
//  UPDATED   : 2023-02-09
//
//***************************************************************************
function Is64BitHardware : Boolean;
var
  MySystem: TSystemInfo;
begin
  GetSystemInfo(MySystem);
  Result := (TOSVersion.Architecture = arIntelX64) or
            (TOSVersion.Architecture = arARM64);
end; // Is64BitHardware

//***************************************************************************
//
//  FUNCTION  : Is64BitWindows
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Check if this is a 64-bit installation of Windows.
//
//              There are many ways of doing this. (Spent an afternoon on forums)
//
//              Strangely, I get an Access Violation error if I use the
//              'IsWow64Process' (commented out, below), and then try to examine
//              the registry and use TRegistry.Create;
//              So I am not using that method.
//
//  https://stackoverflow.com/questions/601089/detect-whether-current-windows-version-is-32-bit-or-64-bit
//
//              WOW64 is the x86 emulator that allows 32-bit Windows-based
//              applications to run seamlessly on 64-bit Windows.
//
//  https://stackoverflow.com/questions/1436185/how-can-i-tell-if-im-running-on-x64
//
//  UPDATED   : 2023-02-09
//
//***************************************************************************
function Is64BitWindows : Boolean;
begin
  Result := (System.SysUtils.GetEnvironmentVariable('ProgramW6432') <> '');
end; // Is64BitWindows
//
//type
//  TIsWow64Process = function(Handle:THandle; var IsWow64 : boolean) : Boolean; stdcall;
//var
//  Iret : Boolean;
//  hDLL : cardinal;
//  IsWow64Process : TIsWow64Process;
//
//begin
//  Result := false;
//  hDLL := LoadLibrary('kernel32.dll');
//  if (hDLL = 0) then Exit;
//  try
//    @IsWow64Process := GetProcAddress(hDLL, 'IsWow64Process');
//    if Assigned(IsWow64Process) then
//    begin
//      if (not IsWow64Process(GetCurrentProcess, Iret)) then
//      begin
//        Raise Exception.Create('Invalid handle');
//      end; // if
//      Result := Iret;
//    end;
//  finally
//    FreeLibrary(hDLL);
//  end;
//end;

//***************************************************************************
//
//  FUNCTION  : GetWebView2RuntimeVersion
//
//  I/P       : None
//
//  O/P       : String - The version number of the WebView2 Runtime.
//                Empty string, if not installed.
//
//  OPERATION : Get the version of the installed WebView2 Runtime.
//
//              https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution
//
//              Two approaches are presented in the above documentation:
//                * Examine the registry
//                * Use GetAvailableCoreWebView2BrowserVersionString()
//              Delphi 10.4.2 does not seem to support the second in its WinAPI.
//
//              For the registry approach, examine the 'pv (REG_SZ)' regkey in
//              the approriate registry locations. (See in code, below)
//              At least one of these regkeys must be present and defined with
//              a version greater than 0.0.0.0. If neither regkey exists, or if
//              only one of these regkeys exists but its value is null, an empty
//              string, or 0.0.0.0, this means that the WebView2 Runtime isn't
//              installed on the client.
//
//              Inspect these regkeys to detect whether the WebView2 Runtime is
//              installed, and to get the version of the WebView2 Runtime.
//
//
//  UPDATED   : 2023-02-09
//
//***************************************************************************
function GetWebView2RuntimeVersion : String;
var
  lEdgeHandle : HMODULE;
  registry : TRegistry;
  openResult : Boolean;

begin
  Result := '';


(*
  // This to get the WebView2 versions
  versionEdge := '';

  lEdgeHandle := LoadLibrary('WebView2Loader_x86.dll');
  if (lEdgeHandle <> 0) then
  begin
    GetAvailableCoreWebView2BrowserVersionString := GetProcAddress(lEdgeHandle, 'GetAvailableCoreWebView2BrowserVersionString');
    if Assigned(GetAvailableCoreWebView2BrowserVersionString) then
    begin
      GetAvailableCoreWebView2BrowserVersionString(nil, @versionEdge);
    end;
  end;

  Result := versionEdge;
*)


  if (Is64BitWindows) then
  begin
    // 64-bit PC
    registry := TRegistry.Create;
    try
      registry.RootKey := HKEY_LOCAL_MACHINE;
      if (registry.KeyExists('SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\')) then
      begin
        registry.Access := KEY_READ;
        openResult := registry.OpenKeyReadOnly('SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\');
        if (openResult) then
        begin
          Result := registry.ReadString('pv');
        end;
      end;
    finally
      registry.CloseKey();
      registry.Free;
    end;

    if ((Result = '') or
        (Result = '0.0.0.0')) then
    begin
      registry := TRegistry.Create;
      try
        registry.RootKey := HKEY_CURRENT_USER;
        if (registry.KeyExists('SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\')) then
        begin
          registry.Access := KEY_READ;
          openResult := registry.OpenKeyReadOnly('SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\');
          if (openResult) then
          begin
            Result := registry.ReadString('pv');
          end;
        end;
      finally
        registry.CloseKey();
        registry.Free;
      end;
    end;
  end // if
  else
  begin
    // 32-bit PC
    registry := TRegistry.Create;
    try
      registry.RootKey := HKEY_LOCAL_MACHINE;
      if (registry.KeyExists('SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\')) then
      begin
        registry.Access := KEY_READ;
        openResult := registry.OpenKeyReadOnly('SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\');
        if (openResult) then
        begin
          Result := registry.ReadString('pv');
        end;
      end;
    finally
      registry.CloseKey();
      registry.Free;
    end;

    if ((Result = '') or
        (Result = '0.0.0.0')) then
    begin
      registry := TRegistry.Create;
      try
        registry.RootKey := HKEY_CURRENT_USER;
        if (registry.KeyExists('SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\')) then
        begin
          registry.Access := KEY_READ;
          openResult := registry.OpenKeyReadOnly('SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\');
          if (openResult) then
          begin
            Result := registry.ReadString('pv');
          end;
        end;
      finally
        registry.CloseKey();
        registry.Free;
      end;
    end;
  end; // else

  if (Result = '0.0.0.0') then
  begin
    Result := '';
  end;
end; // GetWebView2RuntimeVersion

//***************************************************************************
//
//  FUNCTION  : CloseRunningApplication
//
//  I/P       : exeName : String - The name of the application to be close.
//                e.g. "yamsc.exe" (Note that there might be many instances of
//                some named applications, and an alternative method may then
//                need to be found.)
//
//  O/P       : Boolean : TRUE if the named application was closed (or not found)
//
//  OPERATION : Close the named application.
//
//  UPDATED   : 2024-01-05
//
//***************************************************************************
function ClosedRunningApplication(exeName : String) : Boolean;
var
  snapshot: THandle;
  ProcEntry: TProcessEntry32;
  s: String;
  targetProcess : THandle;
  found : Boolean;

begin
  Result := FALSE;

  snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot <> INVALID_HANDLE_VALUE) then
  begin
    ProcEntry.dwSize := SizeOf(ProcessEntry32);
    if (Process32First(snapshot, ProcEntry)) then
    begin
      s := ProcEntry.szExeFile;
      // s contains image name of the first process

      found := FALSE;
      while Process32Next(snapshot, ProcEntry) do
      begin
        s := ProcEntry.szExeFile;
        // s contains image name of the current process
        if (s.ToUpper = exeName.ToUpper) then
        begin
          found := TRUE;
          targetProcess := OpenProcess(PROCESS_TERMINATE, False, ProcEntry.th32ProcessID);
          if targetProcess > 0 then
          try
            Result := Win32Check(WinApi.Windows.TerminateProcess(targetProcess,0));
          finally
            CloseHandle(targetProcess);
          end;
        end;
      end;

      if (not found) then
      begin
        Result := TRUE;
      end;
    end;
  end;
  CloseHandle(snapshot);
end;

end.
