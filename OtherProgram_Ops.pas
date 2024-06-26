unit OtherProgram_Ops;
interface
function processExists(exeFileName: string): Boolean;
function ExecuteProcess(const FileName, Params: string;
                        Folder: string;
                        WaitUntilTerminated, WaitUntilIdle: boolean;
                        windowDisplay : Integer;
                        var ErrorCode: integer): boolean;
function KillTask(ExeFileName: string): Integer;
implementation
uses
  System.SysUtils,
  WinAPI.Windows,
  Vcl.Forms,
  TlHelp32,
  Dialogs;

//***************************************************************************
//
//  FUNCTION  : ProcessExists
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  Usage : if processExists('notepad.exe') then .....
//
//  Reference : https://stackoverflow.com/questions/876224/how-to-check-if-a-process-is-running-using-delphi#876237
//
//  UPDATED   : 2020-10-21
//
//***************************************************************************
function ProcessExists(exeFileName: string): Boolean;
var
  ContinueLoop: Boolean;
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

//***************************************************************************
//
//  FUNCTION  : ExecuteProcess
//
//  I/P       : windowDisplay : Integer - SW_SHOWMAXIMIZED, SW_SHOWNORMAL or
//                SW_SHOWMINIMIZED
//
//  O/P       :
//
//  OPERATION : Lifted from https://riptutorial.com/delphi/example/18340/createprocess
(* Usage example
var
  FileName, Parameters, WorkingFolder: string;
  Error: integer;
  OK: boolean;
begin
  FileName := 'C:\FullPath\myapp.exe';
  WorkingFolder := ''; // if empty function will extract path from FileName
  Parameters := '-p'; // can be empty
  OK := ExecuteProcess(FileName, Parameters, WorkingFolder, false, false, false, Error);
  if not OK then ShowMessage('Error: ' + IntToStr(Error));
end;
*)
//
//  UPDATED   : 2019-07-19
//
//***************************************************************************
function ExecuteProcess(const FileName, Params: string;
                        Folder: string;
                        WaitUntilTerminated, WaitUntilIdle: boolean;
                        windowDisplay : Integer;
                        var ErrorCode: integer): boolean;
var
  CmdLine: string;
  WorkingDirP: PChar;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;

begin
  Result := true;
  CmdLine := '"' + FileName + '" ' + Params;
  if (Folder = '') then
  begin
    Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(FileName));
  end;
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := windowDisplay;
  if (Folder <> '') then
  begin
    WorkingDirP := PChar(Folder)
  end
  else
  begin
    WorkingDirP := nil;
  end;
  if (not CreateProcess(nil, PChar(CmdLine), nil, nil, false, 0, nil, WorkingDirP, StartupInfo, ProcessInfo)) then
  begin
    Result := false;
    ErrorCode := GetLastError;
    exit;
  end;
  with ProcessInfo do
  begin
    CloseHandle(hThread);
    if WaitUntilIdle then WaitForInputIdle(hProcess, INFINITE);
    if WaitUntilTerminated then
    begin
      repeat
        Application.ProcessMessages;
      until MsgWaitForMultipleObjects(1, hProcess, false, INFINITE, QS_ALLINPUT) <> WAIT_OBJECT_0 + 1;
    end;
    CloseHandle(hProcess);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : KillTask
//
//  I/P       : ExeFileName : String - the name of the executable
//
//  O/P       :
//
//  OPERATION : Kills a program by name (e.g. 'notepad.exe')
//
//  Reference : https://stackoverflow.com/questions/43774320/how-to-kill-a-process-by-name
//
//  UPDATED   : 2021-10-12
//
//***************************************************************************
function KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      begin
        Result := Integer(TerminateProcess(OpenProcess(PROCESS_TERMINATE,
                                           BOOL(0),
                                           FProcessEntry32.th32ProcessID),
                                           0));
      end; // if
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end; // while
  CloseHandle(FSnapshotHandle);
end; // end
end.
