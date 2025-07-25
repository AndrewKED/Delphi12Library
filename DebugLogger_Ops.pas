unit DebugLogger_Ops;

//***************************************************************************
//
//  MODULE   : DebugLogger_Ops
//
//  PURPOSE  : Logging and diagnostic output using a class-based wrapper.
//
//  CREATED  : 2025-06-20
//
//***************************************************************************

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

type
  TLogEntry = (
    LOG_ENTRY_NONE,
    LOG_ENTRY_OK,
    LOG_ENTRY_ERROR);

  TDebugLogger = class
  private
    logFileName : String;
  public
    constructor Create(const fileName : String = '';
                      clear : Boolean = FALSE;
                      addHeader : Boolean = FALSE);
    function Exists : Boolean;
    procedure Log(sLine : String;
                  entryType : TLogEntry = LOG_ENTRY_NONE;
                  includeDT : Boolean = TRUE);
    procedure LogException(sLine : String;
                           ex : Exception);
    procedure Erase;
    procedure TrimTo(numLines : Integer);

    property FileName : String read logFileName;
  end;

function DebugLineHeader : String;

implementation

uses
  File_Ops, Str_Ops;

//***************************************************************************
//
//  FUNCTION  : DebugLineHeader
//
//  I/P       : None
//
//  O/P       : String - A timestamp string formatted for debug logs.
//
//  OPERATION : Formats the current date and time as a precise timestamp.
//
//  UPDATED   : 2025-06-20
//
//***************************************************************************
function DebugLineHeader : String;
begin
  Result := FormatDateTime('yyyy-mm-dd,hh:nn:ss.zzz', Now);
end; // DebugLineHeader

//***************************************************************************
//
//  FUNCTION  : Create
//
//  I/P       : See class interface
//
//  O/P       : None
//
//  OPERATION : Sets up the logger file and optional header.
//
//  UPDATED   : 2025-06-20
//
//***************************************************************************
constructor TDebugLogger.Create(const fileName : String;
                                clear : Boolean;
                                addHeader : Boolean);
begin
  if (FileNameValid(ExtractFileName(fileName))) then
  begin
    if ((ExtractFilePath(fileName) <> '') and
        (DirectoryExists(ExtractFilePath(fileName)))) then
    begin
      logFileName := fileName;
    end
    else
    begin
      logFileName := GetTempFolder + ExtractFileName(fileName);
    end;
  end
  else
  begin
    logFileName := GetTempFolder + 'Debug.log';
  end;

  if (clear) then
  begin
    DeleteFile(logFileName);
  end;

  if ((addHeader) and
      (not TFile.Exists(logFileName))) then
  begin
    TFile.WriteAllText(
      logFileName,
      'PC Date/Time,Details' + sLineBreak
    );
  end;
end; // Create

//***************************************************************************
//
//  FUNCTION  : Log
//
//  I/P       : sLine : String - The text to append to the log file.
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
//  UPDATED   : 2025-06-20
//
//***************************************************************************
procedure TDebugLogger.Log(sLine : string;
                           entryType : TLogEntry = LOG_ENTRY_NONE;
                           includeDT : Boolean = TRUE);
var
  logLine : String;

begin
  try
    logLine := ifthens(includeDT, DebugLineHeader + ',', '');
    case entryType of
      LOG_ENTRY_OK :
        logLine := logLine + '1,';
      LOG_ENTRY_ERROR :
        logLine := logLine + '2,';
      else
        logLine := logLine + '0,';
    end;
    TFile.AppendAllText(logFileName, logLine + sLine + sLineBreak);
  except
  end; // except
end; // Log

//***************************************************************************
//
//  FUNCTION  : LogException
//
//  I/P       : sLine : String - The text to append to the log file.
//
//              ex : Exception - The exception from which this logging
//                function has been called.
//
//  O/P       : None
//
//  OPERATION : Make an exception entry into the log file.
//
//              Makes use of the Log function, above.
//
//  UPDATED   : 2025-06-20
//
//***************************************************************************
procedure TDebugLogger.LogException(sLine : string;
                                    ex : Exception);
begin
  Log('Exception "' + ex.Message + '" : ' + sLine);
end; // LogException

//***************************************************************************
//
//  FUNCTION  : TrimTo
//
//  I/P       : numLines : Integer - The number of text lines to keep in the
//                file.
//
//  O/P       : None
//
//  OPERATION : Trim the front of a log file, to ensure a given maximum number
//              of lines
//
//  UPDATED   : 2025-06-20
//
//***************************************************************************
procedure TDebugLogger.TrimTo(numLines : Integer);
var
  wholeLog : TStringList;

begin
  if (numLines < 0) then
  begin
    Exit;
  end; // if

  wholeLog := TStringList.Create;
  try
    if (FileExists(logFileName)) then
    begin
      wholeLog.LoadFromFile(logFileName);
      while ((numLines >= 0) and
             (wholeLog.Count > numLines)) do
      begin
        wholeLog.Delete(0);
      end; // while
      wholeLog.SaveToFile(logFileName);
    end; // if
  finally
    wholeLog.Free;
  end;
end; // TrimTo

//***************************************************************************
//
//  FUNCTION  : Exists
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the debug log file exists
//
//  OPERATION : Test whether the Debug file exists
//
//  UPDATED   : 2025-06-20
//
//***************************************************************************
function TDebugLogger.Exists : Boolean;
begin
  Result := TFile.Exists(logFileName);
end; // Exists

//***************************************************************************
//
//  FUNCTION  : EraseDebugLog
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Erase an existing log file
//
//  UPDATED   : 2025-06-20
//
//***************************************************************************
procedure TDebugLogger.Erase;
begin
  if (Exists) then
  begin
    TFile.Delete(logFileName);
  end; // if
end; // Erase


end.


