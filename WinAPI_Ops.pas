unit WinAPI_Ops;

interface

function WUserName: String;
function GetLocalComputerName: string;
function GetSecurityID(lpSystemName : String;
                       lpAccountName : String) : String;

implementation

uses
  Windows, SysUtils;

function ConvertSidToStringSid(Sid: PSID; out StringSid: PChar): BOOL; stdcall;  external 'ADVAPI32.DLL' name {$IFDEF UNICODE} 'ConvertSidToStringSidW'{$ELSE} 'ConvertSidToStringSidA'{$ENDIF};

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

end.
