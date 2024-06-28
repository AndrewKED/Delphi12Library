unit Debug_Ops;

interface

uses
  System.SysUtils;

type
  TLogEntry = (
    LOG_ENTRY_NONE,
    LOG_ENTRY_OK,
    LOG_ENTRY_ERROR);

function DebugLineHeader : String;
function SetDebugLogFile(iIndex : Integer;
                         sFileName : String;
                         bClear : Boolean;
                         addHeader : Boolean = FALSE) : Boolean;
function DebugLogExists(iIndex : Integer) : Boolean;
procedure DebugLog(iIndex : Integer;
                   sLine : string;
                   entryType : TLogEntry = LOG_ENTRY_NONE;
                   includeDT : Boolean = TRUE);
procedure DebugLogException(iIndex : Integer;
                            sLine : string;
                            ex : Exception);
procedure EraseLog(iIndex : Integer);
procedure TrimLog(iIndex : Integer;
                  numLines : Integer);

var
  DebugFileNames : array[1..5] of string; // Allow up to 5 debug files

implementation

uses
  System.Math, System.Classes,
  File_Ops, Str_Ops;

var
  n : Integer;

//***************************************************************************
//
//  FUNCTION  : LogExists
//
//  I/P       : iIndex : Integer - Index to the log file, as created in
//                the SetDebugLogFile procedure, above.
//
//  O/P       : TRUE if the log file exists
//
//  OPERATION : Check if an indexed log file exists.
//
//  UPDATED   : 2023-05-18
//
//***************************************************************************
function LogExists(iIndex : Integer) : Boolean;
begin
  result := (InRange(iIndex, Low(DebugFileNames), High(DebugFileNames))) and
            (DebugFileNames[iIndex] <> '') and
            (FileExists(DebugFileNames[iIndex]));
end; // LogExists

//***************************************************************************
//
//  FUNCTION  : DebugLineHeader
//
//  I/P       : None
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2020-05-08
//
//***************************************************************************
function DebugLineHeader : String;
begin
  Result := FormatDateTime('yyyy-mm-dd,hh:nn:ss.zzz',Now)
end;

//***************************************************************************
//
//  FUNCTION  : SetDebugLogFile
//
//  I/P       : iIndex : Integer - ID number for this log file, so that multiple
//                log files may be operated
//
//  I/P       : sFileName (string) - The full filename of the file to which
//                debug messages are to be written.
//
//              bClear : Boolean - TRUE to delete the log
//
//  O/P       : Boolean - TRUE if file was deleted, if requested, else TRUE
//
//  OPERATION : Records the file (with path) to be used for indexed logging.
//              Defaults to storage in the TEMP folder if given folder appears invalid
//              Defaults to storage in the TEMP folder with default name if the given
//              filename appears to be invalid.
//              The TEMP folder is typically
//              C:\Users\xxxxxxxxx\AppData\Local\Temp\
//
//              Optionally wipes the file.
//
//  UPDATED   : 2015-02-19
//
//***************************************************************************
function SetDebugLogFile(iIndex : Integer;
                         sFileName : String;
                         bClear : Boolean;
                         addHeader : Boolean = FALSE) : Boolean;
var
  fLogFile : TextFile;

begin
  Result := FALSE;
  if (InRange(iIndex, Low(DebugFileNames), High(DebugFileNames))) then
  begin
    if (FileNameValid(ExtractFileName(sFileName))) then
    begin
      if ((ExtractFilePath(sFileName) <> '') and
          (DirectoryExists(ExtractFilePath(sFileName)))) then
        DebugFileNames[iIndex] := sFileName
      else
        DebugFileNames[iIndex] := GetTempFolder + ExtractFileName(sFileName);
    end
    else
      DebugFileNames[iIndex] := GetTempFolder + 'Debug.log';

    if (bClear) then
      Result := DeleteFile(DebugFileNames[iIndex])
    else
      Result := TRUE;

    if (addHeader) then
    begin
      AssignFile(fLogFile,DebugFileNames[iIndex]);
      if (not FileExists(DebugFileNames[iIndex])) then
      begin
        Rewrite(fLogFile);
        Writeln(fLogFile, 'PC Date/Time,Details');
        System.CloseFile(fLogFile);
      end;
    end;
  end;
end; // SetDebugLogFile

//***************************************************************************
//
//  FUNCTION  : DebugLogExists
//
//  I/P       : iIndex : Integer - Index to the log file being queried.
//
//  O/P       :
//
//  OPERATION : Test whether the indexed Debug file exists
//
//  UPDATED   : 2022-03-16
//
//***************************************************************************
function DebugLogExists(iIndex : Integer) : Boolean;
begin
  if (InRange(iIndex, Low(DebugFileNames), High(DebugFileNames))) then
  begin
    // Ensure that a debug file has been specified
    Result := (DebugFileNames[iIndex] <> '') and
              (FileExists(DebugFileNames[iIndex]));
  end // if
  else
  begin
    Result := FALSE;
  end; // else
end;

//***************************************************************************
//
//  FUNCTION  : DebugLog
//
//  I/P       : iIndex : Integer - Index to the log file, as created in
//                the SetDebugLogFile procedure, above.
//
//              sLine : String - The text to append to the log file.
//
//              entryType : TLogEntry = LOG_ENTRY_NONE - Indicates the ID to
//                be inserted as a field in the log line
//
//              includeDT : Boolean = TRUE - Include a date field and a time field,
//                to milliseconds.
//
//  O/P       : None.
//
//  OPERATION : Creates a log file in the location that has been configured (see above)
//
//              Logged lines have, by default, date and time fields.
//
//              Logged lines have a type field, which is '0' by default
//
//  UPDATED   : 2023-05-18
//
//***************************************************************************
procedure DebugLog(iIndex : Integer;
                   sLine : string;
                   entryType : TLogEntry = LOG_ENTRY_NONE;
                   includeDT : Boolean = TRUE);
var
  fLogFile : TextFile;
  logLine : String;

begin
  // I have, in the past, inadvertently passed an invalid index to DebugLog, and
  // then unsuccessully hunted for the error.
  if (InRange(iIndex, Low(DebugFileNames), High(DebugFileNames))) then
  begin
    // Ensure that a debug file has been specified
    if (DebugFileNames[iIndex] = '') then
      SetDebugLogFile(iIndex, '', FALSE);

    try
      AssignFile(fLogFile,DebugFileNames[iIndex]);
      if (FileExists(DebugFileNames[iIndex])) then
        Append(fLogFile)
      else
        Rewrite(fLogFile);

      logLine := ifthens(includeDT, DebugLineHeader + ',', '');
      case entryType of
        LOG_ENTRY_OK :
          logLine := logLine + '1,';
        LOG_ENTRY_ERROR :
          logLine := logLine + '2,';
        else
          logLine := logLine + '0,';
      end;
      Writeln(fLogFile, logLine + sLine);
      System.CloseFile(fLogFile);
    except
    end; // except
  end; // if
end; // DebugLog

//***************************************************************************
//
//  FUNCTION  : DebugLogException
//
//  I/P       : iIndex : Integer - Index to the log file, as created in
//                the SetDebugLogFile procedure, above.
//
//              sLine : String - The text to append to the log file.
//
//              ex : Exception - The exception from which this logging
//                function has been called.
//
//  O/P       : None
//
//  OPERATION : Make an exception entry into the indicated log file.
//
//              Makes use of the DebugLog function, above.
//
//  UPDATED   : 2020-09-07
//
//***************************************************************************
procedure DebugLogException(iIndex : Integer;
                            sLine : string;
                            ex : Exception);
begin
  DebugLog(iIndex, 'Exception "' + ex.Message + '" : ' + sLine);
end;

//***************************************************************************
//
//  FUNCTION  : EraseLog
//
//  I/P       : iIndex : Integer - The index of the log file to be erased.
//
//  O/P       : None
//
//  OPERATION : Erase an existing log file
//
//  UPDATED   : 2020-11-19
//
//***************************************************************************
procedure EraseLog(iIndex : Integer);
begin
  if (LogExists(iIndex)) then
  begin
    DeleteFile(DebugFileNames[iIndex])
  end; // if
end; // EraseLog

//***************************************************************************
//
//  FUNCTION  : TrimLog
//
//  I/P       : iIndex : Integer - Index to the log file, as created in
//                the SetDebugLogFile procedure, above.
//
//              numLines : Integer - The number of text lines to keep in the
//                file.
//
//  O/P       : None
//
//  OPERATION : Trim the front of an indexed log file, to ensure a given
//              maximum number of lines
//
//  UPDATED   : 2023-05-18
//
//***************************************************************************
procedure TrimLog(iIndex : Integer;
                  numLines : Integer);
var
  wholeLog : TStringList;

begin
  wholeLog := TStringList.Create;
  try
    if (LogExists(iIndex)) then
    begin
      wholeLog.LoadFromFile(DebugFileNames[iIndex]);
      while ((numLines >= 0) and
             (wholeLog.Count > numLines)) do
      begin
        wholeLog.Delete(0);
      end; // while
      wholeLog.SaveToFile(DebugFileNames[iIndex]);
    end; // if
  finally
    wholeLog.Free;
  end;
end; // TrimLog

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
initialization
  for n := Low(DebugFileNames) to High(DebugFileNames) do
    DebugFileNames[n] := '';
  DebugFileNames[1] := GetTempFolder + 'Debug.log';

end.
