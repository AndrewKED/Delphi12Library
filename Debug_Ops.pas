unit Debug_Ops;

interface

uses
  System.SysUtils;

function DebugLineHeader : String;
function SetDebugLogFile(iIndex : Integer;
                         sFileName : String;
                         bClear : boolean) : Boolean;
function DebugLogExists(iIndex : Integer) : Boolean;
procedure DebugLog(iIndex : Integer;
                   sLine : string;
                   includeDT : Boolean = TRUE);
procedure DebugLogException(iIndex : Integer;
                            sLine : string;
                            ex : Exception);
procedure EraseLog(iIndex : Integer);

var
  DebugFileNames : array[1..5] of string; // Allow up to 5 debug files

implementation

uses
  System.Math,
  File_Ops, Str_Ops;

var
  n : Integer;

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
                         bClear : boolean) : boolean;
begin
  result := FALSE;
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
      result := DeleteFile(DebugFileNames[iIndex])
    else
      result := TRUE;
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
  // I have, in the past, inadvertently passed an invalid index to DebugLog, and
  // then unsuccessully hunted for the error.
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
//              includeDT : Boolean = TRUE - Include a date field and a time field,
//                to milliseconds.
//
//  O/P       : None.
//
//  OPERATION : Creates a log file in the location that has been configured (see above)
//              Each logged line is date- and time-stampped.
//
//  UPDATED   : 2016-03-18
//
//***************************************************************************
procedure DebugLog(iIndex : Integer;
                   sLine : string;
                   includeDT : Boolean = TRUE);
var
  fLogFile : TextFile;

begin
  // I have, in the past, inadvertently passed an invalid index to DebugLog, and
  // then unsuccessully hunted for the error.
  if (InRange(iIndex, Low(DebugFileNames), High(DebugFileNames))) then
  begin
    // Ensure that a debug file has been specified
    if (DebugFileNames[iIndex] = '') then
      SetDebugLogFile(iIndex,'',FALSE);

    try
      AssignFile(fLogFile,DebugFileNames[iIndex]);
      if (FileExists(DebugFileNames[iIndex])) then
        Append(fLogFile)
      else
        Rewrite(fLogFile);
      Writeln(fLogFile, ifthens(includeDT, DebugLineHeader + ',', '') + sLine);
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
  if ((DebugFileNames[iIndex] <> '') and
      (FileExists(DebugFileNames[iIndex]))) then
  begin
    DeleteFile(DebugFileNames[iIndex])
  end; // if
end; // EraseLog

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
