unit TimeDate;

//***************************************************************************
//
// DESCRIPTION:
//  Provides a number of helpful time and date handling functions and procedures.
//
// TO BE DONE:
//
//  *
//
// VERSIONS:
//
//    Update Date : 2008-08-25
//    Changes Made :
//      * Added ClosestWeekDay
//
//    Update Date : 2007/07/07
//    Changes Made :
//      * Removed Calendar_Months_Between and added MonthsBetweenExact
//
//    Update Date : 2007-06-06
//    Changes Made :
//      * Modified HHNNSS2DateTime and YYYYMMDD_HHNNSS2DateTime to be ISO8601 compliant
//
//    Update Date : 2007-04-11
//    Changes Made :
//      * Added multi-language facilities
//
//    Update Date : 2006-08-10
//    Changes Made :
//      * Removed the Decodexx functions - replace them with Delphi's SecondOf etc
//      * Removed IsALeapYear function - replace it with Delphi's IsLeapYear(YearOf())
//      * Removed Days_In_Month function - replace it with Delphi's DaysInAMonth(y,m)
//      * Added GPSTOW
//      * Added GPSWeekNumber
//
//    Update Date : 2006-08-10
//    Changes Made :
//      * Added GetTimeZoneDelta
//
//    Update Date : 2005-11-08
//    Changes Made :
//      * Added some SECONDS_PER_ and MINUTES_PER_ constants
//
//    Update Date : 2005-09-06
//    Changes Made :
//      * Mods to get rid of compiler hints
//
//    Update Date : 2005-08-05
//    Changes Made :
//      * Added GetTEditsTime
//
//    Update Date : 2005-01-12
//    Changes Made :
//      * Added this header
//      * Added YYYYMMDD2DateTime, HHNNSS2DateTime and YYYYMMDD_HHNNSS2DateTime
//
//***************************************************************************

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$IFNDEF NO_DKLANG}
  DKLang,
{$ENDIF}
{$ENDIF}
  Classes;

const
  MONTH_LEN : array[1..12] of byte
    = (31,28,31,30,31,30,31,31,30,31,30,31);

  MONTH_ACC : array[0..12] of word
    = (0,31,59,90,120,151,181,212,243,273,304,334,365);

  // In some cases, the month name should remain in English, and not follow the
  // text offered by the Windows installation
  MONTH_NAME_ENGLISH : array[1..12] of String
    = ('January', 'February', 'March', 'April', 'May', 'June',
       'July', 'August', 'September', 'October', 'November', 'December');

  MINUTES_PER_DAY   = 60 * 24;
  SECONDS_PER_DAY   = 60 * 60 * 24;
  MINUTES_PER_WEEK  = 60 * 24 * 7;
  SECONDS_PER_WEEK  = 60 * 60 * 24 * 7;

  DT_ROUND_START_OF_YEAR    = 0;
  DT_ROUND_START_OF_MONTH   = 1;
  DT_ROUND_START_OF_DAY     = 2;
  DT_ROUND_START_OF_HOUR    = 3;
  DT_ROUND_START_OF_MINUTE  = 4;
  DT_ROUND_START_OF_SECOND  = 5;
  DT_ROUND_START_OF_100MS   = 6;
  DT_ROUND_START_OF_10MS    = 7;

  GPS2UTC_LEAP_SECONDS = -18;   // Seconds to add when converting from GPS time to UTC
                                // GPS time is currently ahead of UTC
                                // Last correction : 2015-06-30 @ 23:59:60
                                // Note : GPS NMEA messages contain UTC time stamps

  ISO8601_DT_YMDHMS = 'yyyymmdd"T"hhnnss';      // For use in DateTimeFormat function
                                                // Although missing '-' and ':' it is 8601 compliant
                                                // And is backward compatible to my usage.
  ISO8601_DT_YMD_SEP = 'yyyy-mm-dd';                   // For use in DateTimeFormat function, with fixed separators
  ISO8601_DT_YMDHMS_SEP = 'yyyy-mm-dd"T"hh":"nn":"ss'; // For use in DateTimeFormat function, with fixed separators
  ISO8601_DT_FULL_SEP = 'yyyy-mm-dd"T"hh":"nn":"ss"."zzz'; // For use in DateTimeFormat function, with fixed separators
  // Note - use System.DateUtils.DateToISO8601 and ISO8601ToDate for best results
  ISO8601_DT_FULL = 'yyyymmdd"T"hhnnss.zzz';    // All the way to milliseconds

  VERY_LATE = 73051;    // The equivalent of EncodeDate(2100, 1, 1)
  VERY_EARLY = 1.0;

{$IFDEF MSWINDOWS}
procedure StartFastTimer(iTimerNumber : integer);
procedure PauseFastTimer(iTimerNumber : integer);
procedure ResetFastTimer(iTimerNumber : integer);
function FastTimerRunning(iTimerNumber : integer) : Boolean;
function GetFastTimer(iTimerNumber : integer) : cardinal;
function GetFastTimerIncrement(iTimerNumber : integer) : cardinal;
{$ENDIF}
function Valid_Date (year,month,day : integer) : boolean;
function Valid_Time (iHour,iMinute,iSecond,iMsecond : integer) : boolean;
function Prev_Month (datetime : TDateTime) : TDateTime;
function Next_Month (datetime : TDateTime) : TDateTime;
function Prev_Year (datetime : TDateTime) : TDateTime;
function Next_Year (datetime : TDateTime) : TDateTime;
function Move_Month(datetime : TDateTime;
                    move_by  : integer) : TDateTime;
procedure Fix_ShortDate;
function ShorterTimeFormat(dtTime : TDateTime) : String;
function Hr_Min_Str(mins : longint; pad_char : char = #0) : String;
function Short_Hr_Min_Str(mins : longint; pad_char : char = #0) : String;
function VerboseTimeVariable(period : Double;
                             reportSeconds : Boolean = TRUE) : String;
function YYYYMMDD2DateTime(sYYYYMMDD : string) : TDateTime;
function HHNNSS2DateTime(sHHNNSS : string) : TDateTime;
function YYYYMMDD_HHNNSS2DateTime(sDateTime : string) : TDateTime;
{$IFDEF MSWINDOWS}
procedure ForceSystemDateTime(dtNew : TDateTime);
{$ENDIF}
function MonthsBetweenExact(dtFrom : TDateTime;
                            dtTo : TDateTime) : Integer;
function GPSTOW(dtWhen : TDateTime) : longword;
function GPSWeekNumber(dtWhen : TDateTime) : word;
function ClosestWeekDay(dtTargetDate : TDateTime) : TDateTime;
function FixedDTPShortDateFormat : String;
function FixedDTPShortTimeFormat : String;
function RemoveMilliSeconds(dtGiven : TDateTime) : TDateTime;
function RemoveSeconds(dtGiven : TDateTime) : TDateTime;
function RemoveMinutes(dtGiven : TDateTime) : TDateTime;
function RemoveHours(dtGiven : TDateTime) : TDateTime;
function RoundToSecond(dtGiven : TDateTime) : TDateTime;
function RoundToMinute(dtGiven : TDateTime) : TDateTime;
function RoundToHour(dtGiven : TDateTime) : TDateTime;
function RoundToNearest(TheDateTime : TDateTime;
                        TheRoundStep : TDateTime) : TDateTime;
function IntegerDate(dtGiven : TDateTime) : Integer;
function LongDayNamesISO8601(DayNumber : integer) : String;
function AddDateToTime(TimeOnly : TDateTime;
                       DateAndTime : TDateTime) : TDateTime;
function RoundDateTimeDown(Given : TDateTime;
                           RoundDownID : integer) : TDateTime;
{$IFDEF MSWINDOWS}
function GetStartOfTheWeek : Integer;
{$IFNDEF NO_DKLANG}
procedure SetLanguage(lcMain : TDKLanguageController);
{$ENDIF}
{$ENDIF}

var
  sAbbrHour : String;
  sAbbrMinute : String;
  sInvalidSDate : String;
  sInvalidSTime : String;
  sSecond : String;
  sSeconds : String;
  sMinute : String;
  sMinutes : String;
  sHour : String;
  sHours : String;
  sDay : String;
  sDays : String;

IMPLEMENTATION

uses
  System.StrUtils, System.DateUtils, System.SysUtils, System.Math, System.UITypes,
  System.Types,
{$IFDEF MSWINDOWS}
  Vcl.Dialogs, Vcl.StdCtrls,
{$ENDIF}
  Str_Ops, Maths;

var
{$IFDEF MSWINDOWS}
{$IFNDEF NO_DKLANG}
  lcTimeDate : TDKLanguageController;
{$ENDIF}
{$ENDIF}

  timerFast : array[0..9] of Cardinal;
  timerFastRunning : array[0..9] of Boolean;
  timerPauseValue : array[0..9] of Cardinal;
  timerLast : array[0..9] of Cardinal;
  n : Integer;

{$IFDEF MSWINDOWS}
//***************************************************************************
//
//  FUNCTION  : StartFastTimer
//
//  I/P       : iTimerNumber : Integer - The timer number to be started (0-9)
//
//  O/P       : None
//
//  OPERATION : Start timing on the given timer.
//
//              If the timer was paused, and already had a value, arrange to
//              continue timing from that value
//
//  UPDATED   : 2024-01-11
//
//***************************************************************************
procedure StartFastTimer(iTimerNumber : integer);
begin
  if (iTimerNumber < Low(timerFast)) or (iTimerNumber > High(timerFast)) then
  begin
    Exit;
  end; // if

  if (not timerFastRunning[iTimerNumber]) then
  begin
    timerFast[iTimerNumber] := GetTickCount - timerPauseValue[iTimerNumber];
  end // if
  else
  begin
    timerFast[iTimerNumber] := GetTickCount;
  end;

  timerLast[iTimerNumber] := 0;
  timerFastRunning[iTimerNumber] := TRUE;
end; // StartFastTimer

//***************************************************************************
//
//  FUNCTION  : PauseFastTimer
//
//  I/P       : iTimerNumber : Integer - The timer number to be paused
//
//  O/P       :
//
//  OPERATION : Pause timing on the given timer.
//
//  UPDATED   : 2020-05-29
//
//***************************************************************************
procedure PauseFastTimer(iTimerNumber : integer);
begin
  if (iTimerNumber < Low(timerFast)) or (iTimerNumber > High(timerFast)) then
  begin
    Exit;
  end; // if

  timerPauseValue[iTimerNumber] := GetFastTimer(iTimerNumber);
  timerFastRunning[iTimerNumber] := FALSE;
end; // PauseFastTimer

//***************************************************************************
//
//  FUNCTION  : ResetFastTimer
//
//  I/P       : iTimerNumber : Integer - The timer number to be reset
//
//  O/P       :
//
//  OPERATION : Reset (and stop) the given timer.
//
//  UPDATED   : 2020-05-29
//
//***************************************************************************
procedure ResetFastTimer(iTimerNumber : integer);
begin
  if (iTimerNumber < Low(timerFast)) or (iTimerNumber > High(timerFast)) then
  begin
    Exit;
  end; // if

  timerPauseValue[iTimerNumber] := 0;
  timerFastRunning[iTimerNumber] := FALSE;
end; // ResetFastTimer

//***************************************************************************
//
//  FUNCTION  : FastTimerRunning
//
//  I/P       : iTimerNumber : Integer - The timer number to be examined
//
//  O/P       : Boolean - TRUE if the timer is running. FALSE if paused.
//
//  OPERATION : Query whether the timer is running (or paused).
//
//  UPDATED   : 2020-05-29
//
//***************************************************************************
function FastTimerRunning(iTimerNumber : integer) : Boolean;
begin
  Result := FALSE;

  if (iTimerNumber < Low(timerFast)) or (iTimerNumber > High(timerFast)) then
  begin
    Exit;
  end; // if

  Result := TRUE;
end; // FastTimerRunning

//***************************************************************************
//
//  FUNCTION  : GetFastTimer
//
//  I/P       : iTimerNumber : Integer - The timer number to be stopped
//
//  O/P       : Cardinal - milliseconds since start. 0 if not running.
//
//  OPERATION : Returns the number of milliseconds since a running timer was
//              started, or the pause value on a paused timer.
//
//  UPDATED   : 2020-05-29
//
//***************************************************************************
function GetFastTimer(iTimerNumber : integer) : cardinal;
var
  c : Cardinal;

begin
  Result := 0;

  if (iTimerNumber < Low(timerFast)) or (iTimerNumber > High(timerFast)) then
  begin
    Exit;
  end; // if

  if (not timerFastRunning[iTimerNumber]) then
  begin
    Result := timerPauseValue[iTimerNumber];
    Exit;
  end; // if

  c := GetTickCount;
  if (c >= timerFast[iTimerNumber]) then
  begin
    Result := c - timerFast[iTimerNumber]
  end // if
  else
  begin
    Result := ($FFFFFFFF - timerFast[iTimerNumber]) + c;
  end; // else
end; // GetFastTimer

//***************************************************************************
//
//  FUNCTION  : GetFastTimerIncrement
//
//  I/P       : iTimerNumber : Integer - The timer number to be stopped
//
//  O/P       : Cardinal - milliseconds since start/last call. 0 if not running.
//
//  OPERATION : Returns the number of milliseconds since a running timer was
//              started, or this function was last called.
//
//  UPDATED   : 2023-10-27
//
//***************************************************************************
function GetFastTimerIncrement(iTimerNumber : integer) : cardinal;
var
  c : Cardinal;

begin
  c := GetFastTimer(iTimerNumber);
  if (c >= timerLast[iTimerNumber]) then
  begin
    Result := c - timerLast[iTimerNumber];
  end // fi
  else
  begin
    Result := ($FFFFFFFF - timerLast[iTimerNumber]) + c;
  end;
  timerLast[iTimerNumber] := c;
end;
{$ENDIF}
//***************************************************************************
//
//  FUNCTION  : Valid_Date
//
//  I/P       : year, month, day (integer) - The date to test
//
//  O/P       : (boolean) - TRUE if the date is valid, else FALSE
//
//  OPERATION :	Checks if such a date exists.
//
//	UPDATED		: 2005-08-22
//
//***************************************************************************
function Valid_Date (year,month,day : integer) : boolean;
begin
  if ((year>=1900) and (year<=2099)) and
     ((month>=1) and (month<=12)) and
     (((day>=1) and (day<=month_len[month])) or
      (((year-1980) mod 4 = 0) and (month=2) and (day=29))) then
    result := TRUE
  else
    result := FALSE;
end; // Valid_Date

//***************************************************************************
//
// FUNCTION  : Valid_Time
//
// I/P       : iHour, iMinute, iSecond, iMSecond (WORD) - The time to test
//
// O/P       : (boolean) - TRUE if the time is valid, else FALSE
//
// OPERATION : Checks if such a time is permissable.
//
// UPDATED   : 2005-08-22
//
//***************************************************************************
function Valid_Time (iHour, iMinute, iSecond, iMSecond : integer) : boolean;
begin
  if ((iHour >= 0) and
      (iHour <=23) and
      (iMinute >= 0) and
      (iMinute <= 59) and
      (iSecond >= 0) and
      (iSecond <=59) and
      (iMSecond >= 0) and
      (iMSecond <= 999)) then
    result := TRUE
  else
    result := FALSE;
end; // Valid_Time

//***************************************************************************
//
//  FUNCTION    :   Prev_Month
//
//  I/P         :   datetime (TDateTime) - The date/time to be set back
//                          to the previous month.
//
//  O/P         :   (TDateTime) - The date/time, set back to the previous
//                          month.   The time component is nulled.
//
//  OPERATION   :   Moves the given date/time back to the same day on the
//                      previous month.   If the day does not exist, it sets
//                      the day to the last available day.   The time
//                      component is nulled.
//
//  UPDATED     :   1999-11-01
//
//***************************************************************************
function Prev_Month(datetime : TDateTime) : TDateTime;
var
   d,m,y : word;
begin
  DecodeDate(datetime,y,m,d);

  Dec(m);
  if (m=0) then
  begin
    Dec(y);
    m := 12;
  end; // if

  d := Min(d,DaysInAMonth(y,m));

  result := EncodeDate(y,m,d);
end; // Prev_Month

//***************************************************************************
//
//  FUNCTION    :   Next_Month
//
//  I/P         :   datetime (TDateTime) - The date/time to be set forward
//                          to the next month.
//
//  O/P         :   (TDateTime) - The date/time, set back forward to
//                          the next month.   The time component is nulled.
//
//  OPERATION   :   Moves the given date/time back to the same day on the
//                      next month.   The time component is
//                      nulled.
//
//  UPDATED     :   1999-01-29
//
//***************************************************************************
function Next_Month(datetime : TDateTime) : TDateTime;
var
   d,m,y : word;
begin
  DecodeDate(datetime,y,m,d);

  Inc(m);
  if (m>12) then
  begin
    Inc(y);
    m := 1;
  end; // if

  d := Min(d,DaysInAMonth(y,m));

  result := EncodeDate(y,m,d);
end; // Next_Month

//***************************************************************************
//
//  FUNCTION    :   Move_Month
//
//  I/P         :   datetime (TDateTime) - The date/time to be altered
//
//                      move_by (integer) - The number of moths to change
//
//  O/P         :   (TDateTime) - The date/time, set back forward or
//                          backward by teh specified number of months.
//
//  OPERATION   :   Moves the given date/time forwards or backwards
//                      by a specified number of months.
//
//  UPDATED     :   1999-05-05
//
//***************************************************************************
function Move_Month(datetime : TDateTime;
                    move_by  : integer) : TDateTime;
var
   d,m,y : word;
   new_month : Integer;
   tfrac : real;
begin
  DecodeDate(datetime,y,m,d);
  tfrac := TimeOf(datetime);

  new_month := m + move_by - 1;         // Setup new month, where 0=January

  if (new_month < 0) then               // Check if we have gone back past January
  begin
    y := y + (new_month div 12-1);      // If so, move AT LEAST one year back
    m := new_month - ((new_month div 12)-1) * 12 + 1;
  end
  else
  begin
    y := y + new_month div 12;
    m := new_month - (new_month div 12) * 12 + 1;
  end; // else
  d := Min(d,DaysInAMonth(y,m));

  result := EncodeDate(y,m,d) + tfrac;
end; // Move_Month

//***************************************************************************
//
//  FUNCTION    :   Prev_Year
//
//  I/P         :   datetime (TDateTime) - The date/time to be set back
//                          to the previous year.
//
//  O/P         :   (TDateTime) - The date/time, set back to
//                          the previous year.   The time component is
//                          nulled.
//
//  OPERATION   :   Moves the given date/time back to the same day and
//                      month in the previous year.   If the day does not
//                      exist, it sets the day to the last available day
//                      in the month.   The time component is nulled.
//
//  UPDATED     :   1999-01-11
//
//***************************************************************************
function Prev_Year(datetime : TDateTime) : TDateTime;
var
   d,m,y : word;
begin
  DecodeDate(datetime,y,m,d);
  Dec(y);
  d := Min(d,DaysInAMonth(y,m));
  result := EncodeDate(y,m,d);
end; // Prev_Year

//***************************************************************************
//
//  FUNCTION    :   Next_Year
//
//  I/P         :   datetime (TDateTime) - The date/time to be set forward
//                          to the next year.
//
//  O/P         :   (TDateTime) - The date/time, set forward to
//                          the next year.   The time component is
//                          nulled.
//
//  OPERATION   :   Moves the given date/time forward to the same day and
//                      month in the next year.   The time component is nulled.
//
//  UPDATED     :   1999-01-11
//
//***************************************************************************
function Next_Year(datetime : TDateTime) : TDateTime;
var
   d,m,y : word;
begin
  DecodeDate(datetime,y,m,d);
  Inc(y);
  result := EncodeDate(y,m,d);
end; // Next_Year

//***************************************************************************
//
//  FUNCTION    :   Fix_ShortDate
//
//  I/P         :   FormatSettings.ShortDateFormat
//
//  O/P         :   minute (word)
//
//  OPERATION   :   Forces the Short Date format to always show a
//                  full 4-digit year, with ISO8601 standard if possible.
//
//  UPDATED     :   2007-06-06
//
//***************************************************************************
procedure Fix_ShortDate;
var
  n : word;
begin
  if Pos('yyyy',FormatSettings.ShortDateFormat)=0 then  // Check if the full year is displayed
  begin
    n := Pos('yy',FormatSettings.ShortDateFormat);      // Get the position of the 2-digit year
    if (n<>0) then
      // Extend to full year if this is implemented
      FormatSettings.ShortDateFormat :=
        StringReplace(LeftStr(FormatSettings.ShortDateFormat,n-1) + 'yy' +
                      Copy(FormatSettings.ShortDateFormat,n,255),'/','-',[rfReplaceAll])
    else                                 // Add a full year to the end, which is the best
                                         // position in this instance.
      FormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  end; // if
end; // Fix_ShortDate

//***************************************************************************
//
//  FUNCTION    :   ShorterTimeFormat
//
//  I/P         :   dtTime : TDateTime
//
//  O/P         :   String -
//
//  OPERATION   :   Convert the given time into a string, and strip
//                      off "long" 'AM' or 'PM' strings, and replace them with
//                      'a' or 'p', and remove any spaces.
//
//  UPDATED     :   2000/10/03
//
//***************************************************************************
function ShorterTimeFormat(dtTime : TDateTime) : String;
begin
  result := FormatDateTime('t',dtTime);
  if (Pos(FormatSettings.TimeAMString,result)<>0) then
    result := Copy(result,1,Pos(FormatSettings.TimeAMString,result)-1) +
              'a' +
              Copy(result,Pos(FormatSettings.TimeAMString,result) +
                              Length(FormatSettings.TimeAMString),255);
  if (Pos(FormatSettings.TimePMString,result)<>0) then
    result := LeftStr(result,Pos(FormatSettings.TimePMString,result)-1) +
              'p' +
              Copy(result,Pos(FormatSettings.TimePMString,result) +
                              Length(FormatSettings.TimeAMString),255);
  result := StringReplace(result,' ','',[rfReplaceAll]);
end; // ShorterTimeFormat

//***************************************************************************
//
//  FUNCTION    :   Calendar_Months_Between
//
//  I/P         :   datetime1, datetime2 (TDateTime) - the two dates
//
//  O/P         :   The number of calendar months separating the two
//                      dates.
//
//  OPERATION   :   Returns the number of calendar months separating the
//                      two dates
//                      eg 14/01/2000 and 11/11/1999 returns -2
//                         31/01/2000 and 01/02/2000 returns 1
//                         14/06/2000 and 16/06/2000 returns 0
//
//  UPDATED     :   07/05/1998
//
//***************************************************************************
function Calendar_Months_Between(datetime1 : TDateTime;
                                 datetime2 : TDateTime) : Integer;
begin
  result := (MonthOf(datetime2) + 12 * YearOf(datetime2)) -
            (MonthOf(datetime1) + 12 * YearOf(datetime1));
end; // Calendar_Months_Between

//****************************************************************************
//
//  FUNCTION  : Hr_Min_Str
//
//  I/P       : mins (word) - The number of minutes to be converted
//
//              pad_char : char = #0 - The character to use to pad the
//                hours and minutes to 2 characters.   #0 for no padding.
//
//  O/P       : String
//
//  OPERATION : Converts given number of minutes into a string of
//                format "x hr yy min".
//
//  UPDATED   : 2019-08-28
//
//****************************************************************************
function Hr_Min_Str(mins : longint; pad_char : char = #0) : String;
begin
  if (pad_char=#0) then
    result := IntToStr(mins div 60) + ' ' + sAbbrHour + ' '+
              Front_Padded(IntToStr(mins mod 60),'0',2) + ' ' + sAbbrMinute
  else
    result := Front_Padded(IntToStr(mins div 60),pad_char,2) + ' ' + sAbbrHour + ' '+
              Front_Padded(IntToStr(mins mod 60),'0',2) + ' ' + sAbbrMinute;
end; // Hr_Min_Str

//****************************************************************************
//
//  FUNCTION  : Short_Hr_Min_Str
//
//  I/P       : mins (word) - The number of minutes to be converted
//
//              pad_char (char) - The padding character for hours.   This
//                would normally be #0 or '0'.
//
//  O/P       : (string) - The given minutes converted to the format h:mm
//
//  OPERATION : Converts given number of minutes into a string of format
//              "x:mm", where x is the hours, front padded with the given
//              character for hours less than 10.
//
//  UPDATED   : 19/11/98
//
//****************************************************************************
function Short_Hr_Min_Str(mins : longint; pad_char : char = #0) : String;
begin
  if (pad_char=#0) then
    result := IntToStr(mins div 60) + ':'+
              Front_Padded(IntToStr(mins mod 60),'0',2)
  else
    result := Front_Padded(IntToStr(mins div 60),pad_char,2) + ':'+
              Front_Padded(IntToStr(mins mod 60),'0',2);
end; // Hr_Min_Str

//***************************************************************************
//
//  FUNCTION  : VerboseTimeVariable
//
//  I/P       : period : Double;
//
//              reportSeconds : Boolean = TRUE
//
//  O/P       :
//
//  OPERATION : Convert the given number of seconds into a reasonable, full
//              expression of time. The components are adjusted, as required.
//
//  UPDATED   : 2022-07-14
//
//***************************************************************************
function VerboseTimeVariable(period : Double;
                             reportSeconds : Boolean = TRUE) : String;
var
  seconds : Longint;

begin
  Result := '';

  seconds := Trunc(period);

  if (seconds > 24*60*60) then
  begin
    Result := Format('%d', [seconds div (24*60*60)]) + ' ' +
    NoneSingleMultiple(seconds div (24*60*60), sDays, sDay, sDays) + ' ';
    Dec(seconds, (seconds div (24*60*60)) * (24*60*60));
  end; // if

  if (seconds > 60*60) then
  begin
    Result := Result +
      Format('%d', [seconds div (60*60)]) + ' ' +
      NoneSingleMultiple(seconds div (60*60), sHours, sHour, sHours) + ' ';
    Dec(seconds, (seconds div (60*60)) * (60*60));
  end; // if

  if ((seconds > 60) or
      (not reportSeconds)) then
  begin
    if (reportSeconds) then
    begin
      Result := Result +
        Format('%d', [seconds div 60]) + ' ' +
        NoneSingleMultiple(seconds div 60, sMinutes, sMinute, sMinutes) + ' ';
    end // if
    else
    begin
      Result := Result +
        Format('%d', [Trunc(seconds / 60.0)]) + ' ' +
        NoneSingleMultiple(Trunc(seconds / 60.0), sMinutes, sMinute, sMinutes) + ' ';
    end;
    Dec(seconds, (seconds div 60) * 60);
  end; // if

  if ((reportSeconds) and
      (seconds > 0)) then
  begin
    Result := Result +
      Format('%d', [seconds]) + ' ' +
      NoneSingleMultiple(seconds, sSeconds, sSecond, sSeconds) + ' ';
  end; // if

  Result := End_Trimmed(Result, ' ');
end; // VerboseTimeVariable

//***************************************************************************
//
//  FUNCTION    :   YYYYMMDD2DateTime
//
//  I/P         :   sYYYYMMDD (string) - The date in the string form of
//                    'yyyymmdd', 'yyyy/mm/dd' or 'yyyy-mm-dd'
//
//  O/P         :   (TDateTime) - The decoded date.   (<0.0 if a failure)
//
//  OPERATION   :   Takes a string in the format 'yyyymmdd' and converts it
//                  to a TDateTime value.   If the figures are invalid, the
//                  value returned is less than zero.
//
//  UPDATED     :   2019-05-14
//
//***************************************************************************
function YYYYMMDD2DateTime(sYYYYMMDD : string) : TDateTime;
var
  iYear : Integer;
  iMonth : Integer;
  iDay : Integer;
begin
  // Assume a failure
  result := -1.0;

  // Remove any separating '-' or ;/;
  sYYYYMMDD := StringReplace(sYYYYMMDD, '-', '', [rfReplaceAll]);
  sYYYYMMDD := StringReplace(sYYYYMMDD, '/', '', [rfReplaceAll]);
  if (Length(sYYYYMMDD) = 8) then
  begin
    // Check that the whole string is a number (i.e. no non-numerical characters)
    try
      StrToInt(sYYYYMMDD);
      iYear := StrToInt(LeftStr(sYYYYMMDD,4));
      if ((iYear>=1900) and (iYear <= 2099)) then
      begin
        iMonth := StrToInt(Copy(sYYYYMMDD,5,2));
        if ((iMonth>=1) and (iMonth <= 12)) then
        begin
          iDay := StrToInt(Copy(sYYYYMMDD,7,2));
          if ((iDay >=1) and (iDay <= DaysInAMonth(iYear,iMonth))) then
            result := EncodeDate(iYear,iMonth,iDay);
        end; // else
      end; // else
    except
    end; // except
  end; // else
end; // YYYYMMDD2DateTime

//***************************************************************************
//
//  FUNCTION  : HHNNSS2DateTime
//
//  I/P       : sHHNNSS (string) - The time in the string form of
//                    'hhnnss' (e.g. 122345) or 'hh:nn:ss'.
//                    Fractional seconds are permitted, either with a decimal point
//                    (which is ISO8061) or no decimal point (must be 3 ms digits,
//                    which was my method)
//
//  O/P       : (TDateTime) - The decoded time.   (<0.0 if a failure)
//
//  OPERATION : Convert a time representing string to a TDateTime value.
//
//              The string is expected to be in the form 'hhnnss', with optional
//              decimal seconds (with or without decimal separator) and a possible
//              trailing 'Z' (Zulu indicator).
//
//              If the figures are invalid, the value returned is less than zero.
//
//              Handles '.' or ',' for decimal separators
//
//  UPDATED   : 2020-11-11
//
//***************************************************************************
function HHNNSS2DateTime(sHHNNSS : string) : TDateTime;
var
  iHour : Integer;
  iMinute : Integer;
  fTemp : Double;

begin
  // Assume a failure
  result := -1.0;
  if (Length(sHHNNSS) >= 6) then
  begin
    // Check that the whole string is a positive floating point number (i.e. no non-numerical characters)
    try
      // We expect either '.' or ',' as a decimal separator in this string, so the operation below will ensure that
      // the decimal separator is correct for the current locale.
      sHHNNSS := StringReplace(sHHNNSS, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
      sHHNNSS := StringReplace(sHHNNSS, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
      // Remove any separating ':'
      sHHNNSS := StringReplace(sHHNNSS, ':', '', [rfReplaceAll]);
      // Cater for a potential Zulu indicator, and remove it
      if (sHHNNSS[Length(sHHNNSS)] = 'Z') then
         sHHNNSS := Copy(sHHNNSS, 1, Length(sHHNNSS) - 1);
      // Do the conversion
      fTemp := StrToFloat(sHHNNSS);
      if (fTemp>=0.0) then
      begin
        iHour := StrToInt(LeftStr(sHHNNSS,2));
        if ((iHour>=0) and (iHour <= 23)) then
        begin
          iMinute := StrToInt(Copy(sHHNNSS,3,2));
          if ((iMinute>=0) and (iMinute <= 59)) then
          begin
            // Ensure that seconds is specified in ms
            if (Copy(sHHNNSS,7,1) = FormatSettings.DecimalSeparator) then
              fTemp := StrToFloat(End_Padded(Copy(sHHNNSS,5,255),'0',5))
            else
              fTemp := StrToFloat(End_Padded(Copy(sHHNNSS,5,5),'0',5)) / 1000.0;
            if ((fTemp >= 0.0) and (fTemp < 60.0)) then
              result := EncodeTime(iHour,iMinute,Trunc(fTemp),Trunc(Frac(fTemp) * 1000.0));
          end; // else
        end; // else
      end; // else
    except
      result := -1.0;
    end;
  end; // else
end; // HHNNSS2DateTime

//***************************************************************************
//
//  FUNCTION  : YYYYMMDD_HHNNSS2DateTime
//
//  I/P       : sDateTime (string) - The datetime stamp in the string form of
//                ISO8601 standard, or 'yyyymmdd hhnnss' which was my standard
//                before I noticed that it was close to ISO8601, and that was
//                better to use.
//                My standard permitted permitted seconds in milliseconds.
//
//  O/P       : (TDateTime) - The decoded date/time.   (<0.0 if a failure)
//
//  OPERATION : Takes a string in my "old" format, or in ISO8601 (or "reasonable"
//              variants and converts it to a TDateTime value.
//
//              If the figures or format is invalid, the value returned
//              is less than zero.
//
//  UPDATED   : 2019-04-17
//
//***************************************************************************
function YYYYMMDD_HHNNSS2DateTime(sDateTime : string) : TDateTime;
var
  dtDate : TDateTime;
  dtTime : TDateTime;
  separatorDate : Integer;

begin
  result := -1.0;

  // Remove separators in date and time portion
  sDateTime := StringReplace(sDateTime, '-', '', [rfReplaceAll]);
  sDateTime := StringReplace(sDateTime, '/', '', [rfReplaceAll]);
  sDateTime := StringReplace(sDateTime, ':', '', [rfReplaceAll]);

  // Check if the given string is in my old format.
  if (Copy(sDateTime,9,1) = ' ') then
  begin
    // The input is in my old format
    begin
      dtDate := YYYYMMDD2DateTime(LeftStr(sDateTime,8));
      if (dtDate >= 0.0) then
      begin
        dtTime := HHNNSS2DateTime(Copy(sDateTime,10,255));
        if (dtTime >= 0.0) then
          result := dtDate + dtTime;
      end; // if
    end; // if
  end // if
  else
  begin
    separatorDate := Pos('T', sDateTime);
    if (separatorDate = 0) then
    begin
      // Only a date in this string, now expected to be YYYYMMDD
      result := YYYYMMDD2DateTime(sDateTime);
    end // if
    else
    begin
      dtDate := YYYYMMDD2DateTime(LeftStr(sDateTime, separatorDate-1));
      if (dtDate >= 0.0) then
      begin
        dtTime := HHNNSS2DateTime(Copy(sDateTime, separatorDate+1,255));
        if (dtTime >= 0.0) then
          result := dtDate + dtTime;
      end; // if
    end;

// Using this build-in conversion did not seem to work.
// It threw an error, saying '112233.456' was not a valid time
//    with TXSDateTime.Create() do
//    try
//      UseZeroMilliseconds := TRUE;
//      XSToNative(sDateTime);
//      result := AsDateTime;
//    finally
//      Free;
//    end;
  end; // else
end; // YYYYMMDD_HHNNSS2DateTime

{$IFDEF MSWINDOWS}
//***************************************************************************
//
//  FUNCTION  : ForceSystemDateTime
//
//  I/P       : dtNew (TDateTime) - The date and time, in UTC, to
//                which the PC system clock must be set.
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure ForceSystemDateTime(dtNew : TDateTime);
var
  sTd : TSystemTime;
begin
  DateTimeToSystemTime(dtNew, sTd);
  SetSystemTime(sTd);
end; // ForceSystemDateTime
{$ENDIF}

//***************************************************************************
//
//  FUNCTION  : MonthsBetweenExact
//
//  I/P       : dtFrom (TDateTime) - The starting date
//
//              dtTo (TDateTime) - The ending date
//
//  O/P       : The number of months changed between the two dates.
//
//  OPERATION : An extension to the available functions of MonthsBetween and
//              MonthSpan, as found in DateUtils.
//
//              This function returns the number of named months that change
//              between two dates.
//                 e.g. 13 Feb 2007 to 1 April 2007 = 2
//                      31 December 2007 to 1 January 2007 = -12
//
//  UPDATED   : 2007/05/29
//
//***************************************************************************
function MonthsBetweenExact(dtFrom : TDateTime;
                            dtTo : TDateTime) : Integer;
begin
  result := (YearOf(dtTo)*12 + MonthOf(dtTo)) -
            (YearOf(dtFrom)*12 + MonthOf(dtFrom));
end; // MonthsBetweenExact

//***************************************************************************
//
//  FUNCTION  : GPSTOW
//
//  I/P       : dtWhen (TDateTime) - The date and time for which the Time Of
//                Week (TOW), is required.
//
//  O/P       : (longword) - TOW
//
//  OPERATION : GPS Time Of Week is the number of seconds from midnight on
//              Saturday (i.e. Sunday 00h00:00.0) till the given time within
//              the week.
//
//  UPDATED   : 2007/03/09
//
//***************************************************************************
function GPSTOW(dtWhen : TDateTime) : longword;
begin
  if (DayOfTheWeek(dtWhen) = 7) then
    result := SecondOfTheWeek(dtWhen) - (6 * 24 * 60 * 60)
  else
    result := SecondOfTheWeek(dtWhen) + (24 * 60 * 60)
end; // TimeFoWeek

//***************************************************************************
//
//  FUNCTION  : GPSWeekNumber
//
//  I/P       : dtWhen (TDateTime) - The date for which the week number is
//                required.
//
//  O/P       : (word) - The number of weeks since 6 Jan 1980 00h00:00
//
//  OPERATION : GPS measures the week number from midnight 5 Jan 1980, up to
//              modulo 1024.
//
//  UPDATED   : 2007/03/09
//
//***************************************************************************
function GPSWeekNumber(dtWhen : TDateTime) : word;
begin
  result := WeeksBetween(dtWhen,EncodeDate(1980,1,6)) mod 1024;
end; // GPSWeekNumber

//***************************************************************************
//
//  FUNCTION  : ClosestWeekDay
//
//  I/P       : dtTargetDate (TDateTime) - The date that is required to be
//                on the closest week day.
//
//  O/P       : (TDateTime) - The date required (integer portion only)
//
//  OPERATION : Returns a date that falls on a Monday to Friday.   If the
//              given date is on the weekend, the date of the next Monday
//              will be returned.
//
//  UPDATED   : 2008-09-25
//
//***************************************************************************
function ClosestWeekDay(dtTargetDate : TDateTime) : TDateTime;
begin
  result := DateOf(dtTargetDate);
  while (not (DayOfWeek(result) in [2..6])) do
    result := result + 1;
end; // ClosestWeekDay

//***************************************************************************
//
//  OPERATION : Return a time format string for a TDateTimePicker,
//              based on the current Short Time Format.
//
//              Make conversions between Windows ShortTimeFormat specifiers
//              and the format specifiers required for use in a TDateTimePicker.
//
//              Firstly, I have come across the situation, (checked in
//              Windows 7 only), where Regional Settings has the Short time
//              set as "HH:mm", but Delphi's FormatSettings.ShortTimeFormat
//              variable returns "hh:mm".
//
//              Secondly, a TDateTimePicker wants the use of an AM/PM indicator
//              to be specified by 'tt' and not the 'AMPM' that
//              FromatSettings.ShortTimeFormat may report.
//
//              Note that Short time format specifieds hour and minutes (and no
//              seconds or milliseconds)
//
//  I/P       : None
//
//  O/P       : String - A version of the PC's short time format which is
//                applicable for use in a TDateTimePicker component.
//
//***************************************************************************
function FixedDTPShortTimeFormat : String;
begin
  result := FormatSettings.ShortTimeFormat;

  // The abbreviation n (for minutes) must be replaced with m
  result := SearchAndReplace(result, 'n', 'm');

  if (Pos('AMPM',result) = 0) then
  begin
    // I have encountered a PC where a format without "AMPM" (i.e. 24 hour clock)
    // had been specified as 'hh' instead of 'HH', which is confusing.
    result := SearchAndReplace(result, 'hh', 'HH')
  end // if
  else
  begin
    // Delphi TDateTimePicker uses 'tt' for the two-letter AM/PM abbreviation
    result := SearchAndReplace(result, 'AMPM', 'tt');
  end; // else
end; // FixedDTPShortTimeFormat

//***************************************************************************
//
//  FUNCTION  : FixedDTPShortTimeFormat
//
//  I/P       : None
//
//  O/P       : String - A version of the PC's short date format which is
//                applicable for use in a TDateTimePicker component.
//
//  OPERATION : Return a date format string for a TDateTimePicker,
//              based on the current Short Date Format.
//
//              Make conversions between Windows ShortTimeFormat specifiers
//              and the format specifiers required for use in a TDateTimePicker.
//
//              TDateTimePicker (original and Jedi) do not replace the '/'
//              character in ShortDateFormat with the current DateSeparator,
//              which they should do. So dates shown as "yyyy/mm/dd" will always
//              display a '/' separator.
//
//  UPDATED   : 2025-02-13
//
//***************************************************************************
function FixedDTPShortDateFormat : String;
begin
  result := FormatSettings.ShortDateFormat;

  // The abbreviation m (for months) must be replaced with M
  result := SearchAndReplace(result, 'm', 'M');

  result := SearchAndReplace(result, '/', FormatSettings.DateSeparator);
end; // FixedDTPShortDateFormat

//***************************************************************************
//
//  FUNCTION  : RemoveMilliSeconds
//
//  I/P       : dtGiven : TDateTime - The TDateTime to be modified.
//
//  O/P       : TDateTime - result
//
//  OPERATION : Sets the milliseconds of the given TDateTime to zero.
//              No rounding is implemented.
//
//  UPDATED   : 2013-09-23
//
//***************************************************************************
function RemoveMilliSeconds(dtGiven : TDateTime) : TDateTime;
begin
  result := RecodeMilliSecond(dtGiven,0);
end; // RemoveMilliSeconds

//***************************************************************************
//
//  FUNCTION  : RemoveSeconds
//
//  I/P       : dtGiven : TDateTime - The TDateTime to be modified.
//
//  O/P       : TDateTime - result
//
//  OPERATION : Sets the seconds and milliseconds of the given TDateTime to zero.
//              No rounding is implemented.
//
//  UPDATED   : 2013-09-23
//
//***************************************************************************
function RemoveSeconds(dtGiven : TDateTime) : TDateTime;
begin
  result := RecodeSecond(RemoveMilliSeconds(dtGiven),0);
end; // RemoveSeconds

//***************************************************************************
//
//  FUNCTION  : RemoveMinutes
//
//  I/P       : dtGiven : TDateTime - The TDateTime to be modified.
//
//  O/P       : TDateTime - result
//
//  OPERATION : Sets the minutes, seconds and milliseconds of the given
//              TDateTime to zero.  No rounding is implemented.
//
//  UPDATED   : 2013-09-23
//
//***************************************************************************
function RemoveMinutes(dtGiven : TDateTime) : TDateTime;
begin
  result := RecodeMinute(RemoveSeconds(dtGiven),0);
end; // RemoveMinutes

//***************************************************************************
//
//  FUNCTION  : RemoveHours
//
//  I/P       : dtGiven : TDateTime - The TDateTime to be modified.
//
//  O/P       : TDateTime - result
//
//  OPERATION : Sets the hours, minutes, seconds and milliseconds of the given
//              TDateTime to zero.  No rounding is implemented.
//              This is effectively the same as DateOf(dtGiven)
//
//  UPDATED   : 2013-09-23
//
//***************************************************************************
function RemoveHours(dtGiven : TDateTime) : TDateTime;
begin
  result := RecodeHour(RemoveMinutes(dtGiven),0);
end; // RemoveHours

//***************************************************************************
//
//  FUNCTION  : RoundToSecond
//
//  I/P       : dtGiven : TDateTime - The TDateTime to be rounded.
//
//  O/P       : TDateTime - the given TDateTime, rounded to the nearest second.
//
//  OPERATION : Rounds the given time to the closest second
//
//  UPDATED   : 2013-09-23
//
//***************************************************************************
function RoundToSecond(dtGiven : TDateTime) : TDateTime;
begin
  if (MilliSecondOf(dtGiven) >= 500) then
    result := RemoveMilliSeconds(dtGiven) + OneSecond
  else
    result := RemoveMilliSeconds(dtGiven);
end; // RoundToSecond

//***************************************************************************
//
//  FUNCTION  : RoundToMinute
//
//  I/P       : dtGiven : TDateTime - The TDateTime to be rounded.
//
//  O/P       : TDateTime - the given TDateTime, rounded to the nearest second.
//
//  OPERATION : Rounds the given time to the closest minute
//
//  UPDATED   : 2013-09-23
//
//***************************************************************************
function RoundToMinute(dtGiven : TDateTime) : TDateTime;
begin
  if (SecondOf(dtGiven) >= 30) then
    result := RemoveSeconds(dtGiven) + ONEMINUTE
  else
    result := RemoveSeconds(dtGiven);
end; // RoundToMinute

//***************************************************************************
//
//  FUNCTION  : RoundToHour
//
//  I/P       : dtGiven : TDateTime - The TDateTime to be rounded.
//
//  O/P       : TDateTime - the given TDateTime, rounded to the nearest second.
//
//  OPERATION : Rounds the given time to the closest hour
//
//  UPDATED   : 2013-09-23
//
//***************************************************************************
function RoundToHour(dtGiven : TDateTime) : TDateTime;
begin
  if (MinuteOf(dtGiven) >= 30) then
    result := RemoveMinutes(dtGiven) + ONEHOUR
  else
    result := RemoveMinutes(dtGiven);
end; // RoundToHour

//***************************************************************************
//
//  FUNCTION  : RoundToNearest
//
//  I/P       : TheDateTime : TDateTime - Input date/time
//
//              TheRoundStep : TDateTime - the amount to which to round
//                e.g. EncodeTime(0,5,0,0) for nearest 5 minutes
//
//  O/P       : TDateTime - The given date/time rounted to the to closest value.
//
//  OPERATION : Rounds to a specified boundary.
//
//  UPDATED   : 2018-12-08
//
//***************************************************************************
function RoundToNearest(TheDateTime : TDateTime;
                        TheRoundStep : TDateTime) : TDateTime;
begin
  if (TheRoundStep = 0.0) then
  begin
    // If round step is zero there is no round at all
    result := TheDateTime;
  end // if
  else
  begin
    // Round to the nearest multiple of TheRoundStep
    result := RoundDecimals(TheDateTime / TheRoundStep, 0) * TheRoundStep;
  end; // else
end; // RoundToNearest

//***************************************************************************
//
//  FUNCTION  : IntegerDate
//
//  I/P       : dtGiven : TDateTime - A date (and time) for which the date
//                portion is needed, in integer form.
//
//  O/P       : Integer - The integer value of the date
//
//  OPERATION : Return the correct integer date value for a given date/time
//
//  UPDATED   : 2015-06-15
//
//***************************************************************************
function IntegerDate(dtGiven : TDateTime) : Integer;
begin
  result := Trunc(DateOf(dtGiven) + 0.5);
end; // IntegerDate

//***************************************************************************
//
//  FUNCTION  : LongDayNamesISO8601
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Returns the full name of the given week day index.
//              This is ISO8601 compliant, where Monday = 1
//
//  UPDATED   : 2015-11-28
//
//***************************************************************************
function LongDayNamesISO8601(DayNumber : integer) : String;
begin
  Inc(DayNumber);
  if (DayNumber < 8) then
    result := FormatSettings.LongDayNames[DayNumber]
  else
    result := FormatSettings.LongDayNames[1];
end; // LongDayNamesISO8601

//***************************************************************************
//
//  FUNCTION  : AddDateToTime
//
//  I/P       : TimeOnly : TDateTime - A time-only (i.e. fractional) value
//
//              DateAndTime : TDateTime - A date and time value, close to the
//                TimeOnly value.
//
//  O/P       : TDateTime - The original time value with a date component added.
//
//  OPERATION : Given a time value and a date+time value, assuming minimal
//              offset (less than half a day) between the two, add the correct
//              date value.
//
//  UPDATED   : 2016-03-22
//
//***************************************************************************
function AddDateToTime(TimeOnly : TDateTime;
                       DateAndTime : TDateTime) : TDateTime;
begin
  result := TimeOnly + DateOf(DateAndTime);
  if (result - DateAndTime > 0.5) then
    result := result - 1.0
  else
    if (result - DateAndTime < -0.5) then
      result := result + 1.0;
end; // AddDateToTime

//***************************************************************************
//
//  FUNCTION  : RoundDateTimeDown
//
//  I/P       : Given : TDateTime - The date/time to be rounded down
//
//              RoundDownID : Integer - ID of the element to which the given
//                TDateTime should be rounded.   (e.g. DT_ROUND_START_OF_YEAR)
//
//  O/P       : The given TDateTime, rounded down to the specified level
//
//  OPERATION : Round a given TDateTime down to the start of the year, month,
//              day, hour, minute or second
//
//  UPDATED   : 2016-03-29
//
//***************************************************************************
function RoundDateTimeDown(Given : TDateTime;
                           RoundDownID : integer) : TDateTime;
begin
  case RoundDownID of
    DT_ROUND_START_OF_YEAR :
      result := EncodeDate(YearOf(Given),1,1) +
                EncodeTime(0,0,0,0);
    DT_ROUND_START_OF_MONTH :
      result := EncodeDate(YearOf(Given),MonthOf(Given),1) +
                EncodeTime(0,0,0,0);
    DT_ROUND_START_OF_DAY :
      result := EncodeDate(YearOf(Given),MonthOf(Given),DayOf(Given)) +
                EncodeTime(0,0,0,0);
    DT_ROUND_START_OF_HOUR :
      result := EncodeDate(YearOf(Given),MonthOf(Given),DayOf(Given)) +
                EncodeTime(HourOf(Given),0,0,0);
    DT_ROUND_START_OF_MINUTE :
      result := EncodeDate(YearOf(Given),MonthOf(Given),DayOf(Given)) +
                EncodeTime(HourOf(Given),MinuteOf(Given),0,0);
    DT_ROUND_START_OF_SECOND :
      result := EncodeDate(YearOf(Given),MonthOf(Given),DayOf(Given)) +
                EncodeTime(HourOf(Given),MinuteOf(Given),SecondOf(Given),0);
    DT_ROUND_START_OF_100MS :
      result := EncodeDate(YearOf(Given),MonthOf(Given),DayOf(Given)) +
                EncodeTime(HourOf(Given),MinuteOf(Given),SecondOf(Given),(MillisecondOf(Given) div 100) * 100);
    DT_ROUND_START_OF_10MS :
      result := EncodeDate(YearOf(Given),MonthOf(Given),DayOf(Given)) +
                EncodeTime(HourOf(Given),MinuteOf(Given),SecondOf(Given),(MillisecondOf(Given) div 10) * 10);
    else
      result := Given;
  end;
end;

{$IFDEF MSWINDOWS}
//***************************************************************************
//
//  FUNCTION  : GetStartOfTheWeek
//
//  I/P       : None
//
//  O/P       : Monday = 1, .. Sunday = 7
//
//  OPERATION : Returns the ID of the first day of the week.
//
//              Functionality extracted from Vcl.ComCtrls.pas
//              See TCommonCalendar.SetFirstDayOfWeek
//
//  UPDATED   : 2016-12-18
//
//***************************************************************************
function GetStartOfTheWeek : Integer;
var
  A: array[0..1] of char;

begin
  GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_IFIRSTDAYOFWEEK, A, SizeOf(A));
  result := Ord(A[0]) - Ord('0') + 1;
end; // GetStartOfTheWeek

{$IFNDEF NO_DKLANG}
//***************************************************************************
//
//  FUNCTION  : SetLanguage
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/02/23
//
//***************************************************************************
procedure SetLanguage(lcMain : TDKLanguageController);
begin
  lcTimeDate := lcMain;
  if (lcMain <> nil) then
    try
      sAbbrHour := LangManager.ConstantValue['sAbbreviationHour'];
      sAbbrMinute := LangManager.ConstantValue['sAbbreviationMinute'];
      sInvalidSDate := LangManager.ConstantValue['sInvalidSDate'];
      sInvalidSTime := LangManager.ConstantValue['sInvalidSTime'];

      sSecond := LangManager.ConstantValue['sSecondLC'];
      sSeconds := LangManager.ConstantValue['sSecondsLC'];
      sMinute := LangManager.ConstantValue['sMinuteLC'];
      sMinutes := LangManager.ConstantValue['sMinutesLC'];
      sHour := LangManager.ConstantValue['sHourLC'];
      sHours := LangManager.ConstantValue['sHoursLC'];
      sDay := LangManager.ConstantValue['sDayLC'];
      sDays := LangManager.ConstantValue['sDaysLC'];
    except
    end; // except
end;
{$ENDIF}
{$ENDIF}

//***************************************************************************
//
//  FUNCTION  : initialization
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Initialise the array of timer tick timers.
//
//  UPDATED   : 2006/10/18
//
//***************************************************************************
initialization
{$IFDEF MSWINDOWS}
  // By default, all fast timers are running from the start of the application.
  for n := Low(timerFast) to High(timerFast) do
  begin
    timerFast[n] := GetTickCount;
    timerFastRunning[n] := TRUE;
    timerPauseValue[n] := 0;
    timerLast[n] := 0;
  end; // else
{$ENDIF}

  sAbbrHour := 'hr';
  sAbbrMinute := 'min';
  sInvalidSDate := 'Invalid %s date';
  sInvalidSTime := 'Invalid %s time';
  sSecond := 'second';
  sSeconds := 'seconds';
  sMinute := 'minute';
  sMinutes := 'minutes';
  sHour := 'hour';
  sHours := 'hours';
  sDay := 'day';
  sDays := 'days';

end. // TimeDate

