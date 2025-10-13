unit Calendar_Ops;

interface

uses
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.WinXCalendars,
{$IFNDEF NO_DKLANG}
  DKLang,
{$ENDIF}
  Reports;

procedure SetupCalendarControls(dateControlPanel : TCustomPanel;
                                fromDateSelection : TDateTimePicker;
                                fromDayName : TLabel;
                                fromFirstDate : TCustomButton;
                                fromPreviousDay : TCustomButton;
                                fromToday : TCustomButton;
                                fromNextDay : TCustomButton;
                                fromLastDate : TCustomButton;
                                toDateSelection : TDateTimePicker;
                                toDayName : TLabel;
                                toFirstDate : TCustomButton;
                                toPreviousDay : TCustomButton;
                                toToday : TCustomButton;
                                toNextDay : TCustomButton;
                                toLastDate : TCustomButton;
                                weekPrevious : TCustomButton;
                                weekThis : TCustomButton;
                                weekNext : TCustomButton;
                                monthPrevious : TCustomButton;
                                monthThis : TCustomButton;
                                monthNext : TCustomButton) overload;
procedure SetupCalendarControls(dateControlPanel : TCustomPanel;
                                fromDateSelection : TCalendarView;
                                fromDayName : TLabel;
                                fromFirstDate : TCustomButton;
                                fromPreviousDay : TCustomButton;
                                fromToday : TCustomButton;
                                fromNextDay : TCustomButton;
                                fromLastDate : TCustomButton;
                                toDateSelection : TCalendarView;
                                toDayName : TLabel;
                                toFirstDate : TCustomButton;
                                toPreviousDay : TCustomButton;
                                toToday : TCustomButton;
                                toNextDay : TCustomButton;
                                toLastDate : TCustomButton;
                                weekPrevious : TCustomButton;
                                weekThis : TCustomButton;
                                weekNext : TCustomButton;
                                monthPrevious : TCustomButton;
                                monthThis : TCustomButton;
                                monthNext : TCustomButton) overload;
procedure PreviousWeek;
procedure ThisWeek;
procedure NextWeek;
procedure PreviousMonth;
procedure ThisMonth;
procedure NextMonth;
procedure LimitDateTimeControls(ctlFromDate : TMonthCalendar;
                                ctlToDate : TMonthCalendar;
                                dtpFromTime : TDateTimePicker;
                                dtpToTime : TDateTimePicker;
                                dtMin : TDateTime;
                                dtMax : TDateTime;
                                forceFrom : Boolean) overload;
procedure LimitDateTimeControls(ctlFromDate : TDateTimePicker;
                                ctlToDate : TDateTimePicker;
                                dtpFromTime : TDateTimePicker;
                                dtpToTime : TDateTimePicker;
                                dtMin : TDateTime;
                                dtMax : TDateTime;
                                forceFrom : Boolean) overload;

implementation

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math,
  Form_Ops, Vcl_Ops;

var
{$IFNDEF NO_DKLANG}
  lcLocal : TDKLanguageController;
{$ENDIF}
  pDateControlPanel : TCustomPanel;
  dtpfDateSelection : TDateTimePicker;
  dtpfTimeSelection : TDateTimePicker;
  cvfDateSelection : TCalendarView;
  fDayName : TLabel;
  fFirstDate : TCustomButton;
  fPreviousDay : TCustomButton;
  fToday : TCustomButton;
  fNextDay : TCustomButton;
  fLastDate : TCustomButton;
  dtptDateSelection : TDateTimePicker;
  dtptTimeSelection : TDateTimePicker;
  cvtDateSelection : TCalendarView;
  tDayName : TLabel;
  tFirstDate : TCustomButton;
  tPreviousDay : TCustomButton;
  tToday : TCustomButton;
  tNextDay : TCustomButton;
  tLastDate : TCustomButton;
  wPrevious : TCustomButton;
  wThis : TCustomButton;
  wNext : TCustomButton;
  mPrevious : TCustomButton;
  mThis : TCustomButton;
  mNext : TCustomButton;
  dateFirst : TDateTime;
  dateLast : TDateTime;

  sToday : String;
  sSetToTodaysDate : String;
  sSelectPreviousWeek : String;
  sSelectThisWeek : String;
  sSelectNextWeek : String;
  sSelectPreviousMonth : String;
  sSelectThisMonth : String;
  sSelectNextMonth : String;

//***************************************************************************
//
//  FUNCTION  : UpdateDayNames
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Fill in the day names above the FROM and TO calendars, if
//              configured.
//
//              (This is typically only used if the caledars are TDateTimePickers)
//
//  UPDATED   : 2023-09-12
//
//***************************************************************************
procedure UpdateDayNames;
begin
  if (fDayName <> nil) then
  begin
    if (dtpfDateSelection <> nil) then
    begin
      fDayName.Caption := FormatDateTime('dddd',dtpfDateSelection.Date);
    end // if
    else
    begin
      fDayName.Caption := FormatDateTime('dddd',cvfDateSelection.Date);
    end;
  end; // if
  if (tDayName <> nil) then
  begin
    if (dtptDateSelection <> nil) then
    begin
      tDayName.Caption := FormatDateTime('dddd',dtptDateSelection.Date);
    end // if
    else
    begin
      tDayName.Caption := FormatDateTime('dddd',cvtDateSelection.Date);
    end;
  end; // if
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
procedure SetWeekMonthHints;
begin
  wPrevious.Hint := '|' + sSelectPreviousWeek;
  wThis.Hint := '|' + sSelectThisWeek;
  wNext.Hint := '|' + sSelectNextWeek;
  mPrevious.Hint := '|' + sSelectPreviousMonth;
  mThis.Hint := '|' + sSelectThisMonth;
  mNext.Hint := '|' + sSelectNextMonth;
end;

//***************************************************************************
//
//  FUNCTION  : SetDayMovementHints
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Set the hints on the day movement buttons
//
//  UPDATED   : 2023-09-12
//
//***************************************************************************
procedure SetDayMovementHints;
begin
  if (dateFirst <> 0.0) then
  begin
    if (fFirstDate <> nil) then
    begin
      fFirstDate.Hint := FormatDateTime('ddddd', dateFirst);
    end;
    if (tFirstDate <> nil) then
    begin
      tFirstDate.Hint := FormatDateTime('ddddd', dateFirst);
    end;
  end; // if

  if (dateLast <> 0.0) then
  begin
    if (fLastDate <> nil) then
    begin
      fLastDate.Hint := FormatDateTime('ddddd', dateFirst);
    end;
    if (tLastDate <> nil) then
    begin
      tLastDate.Hint := FormatDateTime('ddddd', dateFirst);
    end;
  end; // if

  if (fToday <> nil) then
  begin
    fToday.Hint := sToday + '|' + sSetToTodaysDate;
  end;
  if (tToday <> nil) then
  begin
    tToday.Hint := sToday + '|' + sSetToTodaysDate;
  end; // if
end; // SetDayMovementHints;

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
procedure PreviousWeek;
begin
  if ((cvfDateSelection <> nil) and
      (cvtDateSelection <> nil)) then
  begin
    SetDateControlsToWeek(cvfDateSelection, cvtDateSelection, cvfDateSelection.Date - 7);
  end // if
  else if ((dtpfDateSelection <> nil) and
           (dtptDateSelection <> nil)) then
  begin
    SetDateControlsToWeek(dtpfDateSelection, dtptDateSelection, dtpfDateSelection.Date - 7);
  end;
  UpdateDayNames;
end; // PreviousWeek

//***************************************************************************
//
//  FUNCTION  : ThisWeek
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
procedure ThisWeek;
begin
  if ((cvfDateSelection <> nil) and
      (cvtDateSelection <> nil)) then
  begin
    SetDateControlsToWeek(cvfDateSelection, cvtDateSelection, cvfDateSelection.Date);
  end // if
  else if ((dtpfDateSelection <> nil) and
           (dtptDateSelection <> nil)) then
  begin
    SetDateControlsToWeek(dtpfDateSelection, dtptDateSelection, dtpfDateSelection.Date);
  end;
  UpdateDayNames;
end; // ThisWeek

//***************************************************************************
//
//  FUNCTION  : NextWeek
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
procedure NextWeek;
begin
  if ((cvfDateSelection <> nil) and
      (cvtDateSelection <> nil)) then
  begin
    SetDateControlsToWeek(cvfDateSelection, cvtDateSelection, cvfDateSelection.Date + 7);
  end // if
  else if ((dtpfDateSelection <> nil) and
           (dtptDateSelection <> nil)) then
  begin
    SetDateControlsToWeek(dtpfDateSelection, dtptDateSelection, dtpfDateSelection.Date + 7);
  end;
  UpdateDayNames;
end; // NextWeek

//***************************************************************************
//
//  FUNCTION  : PreviousMonth
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
procedure PreviousMonth;
begin
  if ((cvfDateSelection <> nil) and
      (cvtDateSelection <> nil)) then
  begin
    SetDateControlsToMonth(cvfDateSelection, cvtDateSelection, IncMonth(cvfDateSelection.Date, -1), 1);
  end // if
  else if ((dtpfDateSelection <> nil) and
           (dtptDateSelection <> nil)) then
  begin
    SetDateControlsToMonth(dtpfDateSelection, dtptDateSelection, IncMonth(dtpfDateSelection.Date, -1), 1);
  end;
  UpdateDayNames;
end; // PreviousMonth

//***************************************************************************
//
//  FUNCTION  : ThisMonth
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
procedure ThisMonth;
begin
  if ((cvfDateSelection <> nil) and
      (cvtDateSelection <> nil)) then
  begin
    SetDateControlsToMonth(cvfDateSelection, cvtDateSelection, cvfDateSelection.Date, 1);
  end // if
  else if ((dtpfDateSelection <> nil) and
           (dtptDateSelection <> nil)) then
  begin
    SetDateControlsToMonth(dtpfDateSelection, dtptDateSelection, dtpfDateSelection.Date, 1);
  end;
  UpdateDayNames;
end; // ThisMonth

//***************************************************************************
//
//  FUNCTION  : NextMonth
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
procedure NextMonth;
begin
  if ((cvfDateSelection <> nil) and
      (cvtDateSelection <> nil)) then
  begin
    SetDateControlsToMonth(cvfDateSelection, cvtDateSelection, IncMonth(cvfDateSelection.Date, 1), 1);
  end // if
  else if ((dtpfDateSelection <> nil) and
           (dtptDateSelection <> nil)) then
  begin
    SetDateControlsToMonth(dtpfDateSelection, dtptDateSelection, IncMonth(dtpfDateSelection.Date, 1), 1);
  end;
  UpdateDayNames;
end; // NextMonth

//***************************************************************************
//
//  FUNCTION  : SetupCalendarControls
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2023-09-12
//
//***************************************************************************
procedure SetupCalendarControls(dateControlPanel : TCustomPanel;
                                fromDateSelection : TDateTimePicker;
                                fromDayName : TLabel;
                                fromFirstDate : TCustomButton;
                                fromPreviousDay : TCustomButton;
                                fromToday : TCustomButton;
                                fromNextDay : TCustomButton;
                                fromLastDate : TCustomButton;
                                toDateSelection : TDateTimePicker;
                                toDayName : TLabel;
                                toFirstDate : TCustomButton;
                                toPreviousDay : TCustomButton;
                                toToday : TCustomButton;
                                toNextDay : TCustomButton;
                                toLastDate : TCustomButton;
                                weekPrevious : TCustomButton;
                                weekThis : TCustomButton;
                                weekNext : TCustomButton;
                                monthPrevious : TCustomButton;
                                monthThis : TCustomButton;
                                monthNext : TCustomButton);
begin
  pDateControlPanel := dateControlPanel;
  dtpfDateSelection := fromDateSelection;
  cvfDateSelection := nil;
  fDayName := fromDayName;
  fFirstDate := fromFirstDate;
  fPreviousDay := fromPreviousDay;
  fToday := fromToday;
  fNextDay := fromNextDay;
  fLastDate := fromLastDate;
  dtptDateSelection := toDateSelection;
  cvtDateSelection := nil;
  tDayName := toDayName;
  tFirstDate := toFirstDate;
  tPreviousDay := toPreviousDay;
  tToday := toToday;
  tNextDay := toNextDay;
  tLastDate := toLastDate;
  wPrevious := weekPrevious;
  wThis := weekThis;
  wNext := weekNext;
  mPrevious := monthPrevious;
  mThis := monthThis;
  mNext := monthNext;

  SetWeekMonthHints;
  SetDayMovementHints;
end;

procedure SetupCalendarControls(dateControlPanel : TCustomPanel;
                                fromDateSelection : TCalendarView;
                                fromDayName : TLabel;
                                fromFirstDate : TCustomButton;
                                fromPreviousDay : TCustomButton;
                                fromToday : TCustomButton;
                                fromNextDay : TCustomButton;
                                fromLastDate : TCustomButton;
                                toDateSelection : TCalendarView;
                                toDayName : TLabel;
                                toFirstDate : TCustomButton;
                                toPreviousDay : TCustomButton;
                                toToday : TCustomButton;
                                toNextDay : TCustomButton;
                                toLastDate : TCustomButton;
                                weekPrevious : TCustomButton;
                                weekThis : TCustomButton;
                                weekNext : TCustomButton;
                                monthPrevious : TCustomButton;
                                monthThis : TCustomButton;
                                monthNext : TCustomButton);
begin
  pDateControlPanel := dateControlPanel;
  dtpfDateSelection := nil;
  cvfDateSelection := fromDateSelection;
  fDayName := fromDayName;
  fFirstDate := fromFirstDate;
  fPreviousDay := fromPreviousDay;
  fToday := fromToday;
  fNextDay := fromNextDay;
  fLastDate := fromLastDate;
  dtptDateSelection := nil;
  cvtDateSelection := toDateSelection;
  tDayName := toDayName;
  tFirstDate := toFirstDate;
  tPreviousDay := toPreviousDay;
  tToday := toToday;
  tNextDay := toNextDay;
  tLastDate := toLastDate;
  wPrevious := weekPrevious;
  wThis := weekThis;
  wNext := weekNext;
  mPrevious := monthPrevious;
  mThis := monthThis;
  mNext := monthNext;

  SetWeekMonthHints;
  SetDayMovementHints;
end;

//***************************************************************************
//
//  FUNCTION  : LimitDateTimeControls
//
//  I/P       : ctlFromDate : TMonthCalendar
//
//              ctlToDate : TMonthCalendar
//
//              dtpFromTime : TDateTimePicker
//
//              dtpToTime : TDateTimePicker
//
//              dtMin : TDateTime - The minimum permissable TDateTime.
//                Set to 0.0 if no TDateTime limits are to be imposed.
//
//              dtMax : TDateTime - The maximum permissable TDateTime.
//
//              forceFrom : Boolean - TRUE if "From" is to be forced to "To"
//                in the case of "From" > "To". If FALSE, "To" is forced to "From"
//
//  O/P       : None
//
//  OPERATION : Ensure that the given Date TMonthCalendars (and optional Time
//              DateTimePickers) remain within the given datetime range.
//              and in a valid order.
//
//  DATE      : 2019-08-06
//
//***************************************************************************
procedure LimitDateTimeControls(ctlFromDate : TMonthCalendar;
                                ctlToDate : TMonthCalendar;
                                dtpFromTime : TDateTimePicker;
                                dtpToTime : TDateTimePicker;
                                dtMin : TDateTime;
                                dtMax : TDateTime;
                                forceFrom : Boolean) overload;
var
  neDFromCurrent : TNotifyEvent;
  neDToCurrent : TNotifyEvent;
  neTFromCurrent : TNotifyEvent;
  neTToCurrent : TNotifyEvent;

begin
  // Save the current OnClick events for the calendars (and optional time pickers),
  // and temporarily disable them, to prevent recursive calling of OnClick handlers.
  neDFromCurrent := ctlFromDate.OnClick;
  neDToCurrent := ctlToDate.OnClick;
  ctlFromDate.OnClick := nil;
  ctlToDate.OnClick := nil;
  if (dtpFromTime <> nil) then
  begin
    neTFromCurrent := dtpFromTime.OnChange;
    dtpFromTime.OnChange := nil;
  end // if
  else
  begin
    neTFromCurrent := nil;
  end; // else
  if (dtpToTime <> nil) then
  begin
    neTToCurrent := dtpToTime.OnChange;
    dtpToTime.OnChange := nil;
  end // if
  else
  begin
    neTToCurrent := nil;
  end; // else

  // If valid min and max TDateTimes are given, clip the date controls' values
  if ((dtMin <> 0.0) and
      (dtMax <> 0.0) and
      (dtMin <= dtMax)) then
  begin
    ctlFromDate.Date := DateOf(Max(ctlFromDate.Date, dtMin));
    ctlFromDate.Date := DateOf(Min(ctlFromDate.Date, dtMax));
    ctlToDate.Date := DateOf(Max(ctlToDate.Date, dtMin));
    ctlToDate.Date := DateOf(Min(ctlToDate.Date, dtMax));
  end; // if

  // Ensure that the From and To dates are in order,
  // altering the selected control's value, if required
  if (forceFrom) then
  begin
    ctlFromDate.Date := Min(ctlFromDate.Date, ctlToDate.Date);
  end // if
  else
  begin
    ctlToDate.Date := Max(ctlFromDate.Date, ctlToDate.Date);
  end;

  // If Time controls are included, and valid min and max TDateTimes are given,
  // clip the time controls' values
  if ((dtpFromTime <> nil) and
      (dtpToTime <> nil)) then
  begin
    if ((dtMin <> 0.0) and
        (dtMax <> 0.0) and
        (dtMin <= dtMax)) then
    begin
      if ((SameDate(ctlFromDate.Date, dtMin))) then
        dtpFromTime.Time := Min(TimeOf(dtpFromTime.Time),TimeOf(dtMin));
      if ((SameDate(ctlFromDate.Date, dtMax))) then
        dtpFromTime.Time := Max(TimeOf(dtpFromTime.Time),TimeOf(dtMax));
      if ((SameDate(ctlToDate.Date, dtMin))) then
        dtpToTime.Time := Min(TimeOf(dtpToTime.Time),TimeOf(dtMin));
      if ((SameDate(ctlToDate.Date, dtMax))) then
        dtpToTime.Time := Max(TimeOf(dtpToTime.Time),TimeOf(dtMax));
    end; // if

    // Ensure that the From and To times are in order, if on the same day,
    // altering the selected control's value, if required
    if (SameDate(ctlFromDate.Date, ctlToDate.Date)) then
    begin
      if (forceFrom) then
      begin
        dtpFromTime.Date := Min(dtpFromTime.Time, dtpToTime.Time);
      end // if
      else
      begin
        dtpToTime.Date := Max(dtpFromTime.Time, dtpToTime.Time);
      end;
    end; // if
  end; // if

  // Restore the OnClick event handlers
  ctlFromDate.OnClick := neDFromCurrent;
  ctlToDate.OnClick := neDToCurrent;
  if (dtpFromTime <> nil) then
    dtpFromTime.OnChange := neTFromCurrent;
  if (dtpToTime <> nil) then
    dtpToTime.OnChange := neTToCurrent;
end; // LimitDateTimeControls

//***************************************************************************
//
//  FUNCTION  : LimitDateTimeControls
//
//  I/P       : ctlFromDate : TDateTimePicker
//
//              ctlToDate : TDateTimePicker
//
//              dtpFromTime : TDateTimePicker
//
//              dtpToTime : TDateTimePicker
//
//              dtMin : TDateTime - The minimum permissable TDateTime.
//                Set to 0.0 if no TDateTime limits are to be imposed.
//
//              dtMax : TDateTime - The maximum permissable TDateTime.
//
//              forceFrom : Boolean - TRUE if "From" is to be forced to "To"
//                in the case of "From" > "To". If FALSE, "To" is forced to "From"
//
//  O/P       : None
//
//  OPERATION : Ensure that the given Date TDateTimePicker (and optional Time
//              DateTimePickers) remain within the given datetime range.
//              and in a valid order.
//
//  DATE      : 2019-08-06
//
//***************************************************************************
procedure LimitDateTimeControls(ctlFromDate : TDateTimePicker;
                                ctlToDate : TDateTimePicker;
                                dtpFromTime : TDateTimePicker;
                                dtpToTime : TDateTimePicker;
                                dtMin : TDateTime;
                                dtMax : TDateTime;
                                forceFrom : Boolean) overload;
var
  neDFromCurrent : TNotifyEvent;
  neDToCurrent : TNotifyEvent;
  neTFromCurrent : TNotifyEvent;
  neTToCurrent : TNotifyEvent;

begin
  // Save the current OnChange events for the calendars (and optional time pickers),
  // and temporarily disable them, to prevent recursive calling of OnChange handlers.
  neDFromCurrent := ctlFromDate.OnChange;
  neDToCurrent := ctlToDate.OnChange;
  ctlFromDate.OnChange := nil;
  ctlToDate.OnChange := nil;
  if (dtpFromTime <> nil) then
  begin
    neTFromCurrent := dtpFromTime.OnChange;
    dtpFromTime.OnChange := nil;
  end // if
  else
  begin
    neTFromCurrent := nil;
  end; // else
  if (dtpToTime <> nil) then
  begin
    neTToCurrent := dtpToTime.OnChange;
    dtpToTime.OnChange := nil;
  end // if
  else
  begin
    neTToCurrent := nil;
  end;

  // If valid min and max TDateTimes are given, clip the date controls' values
  if ((dtMin <> 0.0) and
      (dtMax <> 0.0) and
      (dtMin <= dtMax)) then
  begin
    ctlFromDate.Date := DateOf(Max(ctlFromDate.Date, dtMin));
    ctlFromDate.Date := DateOf(Min(ctlFromDate.Date, dtMax));
    ctlToDate.Date := DateOf(Max(ctlToDate.Date, dtMin));
    ctlToDate.Date := DateOf(Min(ctlToDate.Date, dtMax));
  end; // if

  // Ensure that the From and To dates are in order,
  // altering the selected control's value, if required
  if (forceFrom) then
  begin
    ctlFromDate.Date := Min(ctlFromDate.Date, ctlToDate.Date);
  end // if
  else
  begin
    ctlToDate.Date := Max(ctlFromDate.Date, ctlToDate.Date);
  end;

  // If Time controls are included, and valid min and max TDateTimes are given,
  // clip the time controls' values
  if ((dtpFromTime <> nil) and
      (dtpToTime <> nil)) then
  begin
    if ((dtMin <> 0.0) and
        (dtMax <> 0.0) and
        (dtMin <= dtMax)) then
    begin
      if ((SameDate(ctlFromDate.Date, dtMin))) then
        dtpFromTime.Time := Min(TimeOf(dtpFromTime.Time),TimeOf(dtMin));
      if ((SameDate(ctlFromDate.Date, dtMax))) then
        dtpFromTime.Time := Max(TimeOf(dtpFromTime.Time),TimeOf(dtMax));
      if ((SameDate(ctlToDate.Date, dtMin))) then
        dtpToTime.Time := Min(TimeOf(dtpToTime.Time),TimeOf(dtMin));
      if ((SameDate(ctlToDate.Date, dtMax))) then
        dtpToTime.Time := Max(TimeOf(dtpToTime.Time),TimeOf(dtMax));
    end; // if

    // Ensure that the From and To times are in order, if on the same day,
    // altering the selected control's value, if required
    if (SameDate(ctlFromDate.Date, ctlToDate.Date)) then
    begin
      if (forceFrom) then
      begin
        dtpFromTime.Date := Min(dtpFromTime.Time, dtpToTime.Time);
      end // if
      else
      begin
        dtpToTime.Date := Max(dtpFromTime.Time, dtpToTime.Time);
      end;
    end; // if
  end; // if

  // Restore the OnClick event handlers
  ctlFromDate.OnChange := neDFromCurrent;
  ctlToDate.OnChange := neDToCurrent;
  if (dtpFromTime <> nil) then
    dtpFromTime.OnChange := neTFromCurrent;
  if (dtpToTime <> nil) then
    dtpToTime.OnChange := neTToCurrent;
end; // LimitDateTimeControls

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
  lcLocal := lcMain;
  if (lcMain <> nil) then
    try
      sToday := LangManager.ConstantValue['sToday'];
      sSetToTodaysDate := LangManager.ConstantValue['sSetToTodaysDate'];
      sSelectPreviousWeek := LangManager.ConstantValue['sSelectPreviousWeek'];
      sSelectThisWeek := LangManager.ConstantValue['sSelectThisWeek'];
      sSelectNextWeek := LangManager.ConstantValue['sSelectNextWeek'];
      sSelectPreviousMonth := LangManager.ConstantValue['sSelectPreviousMonth'];
      sSelectThisMonth := '|' + LangManager.ConstantValue['sSelectThisMonth'];
      sSelectNextMonth := '|' + LangManager.ConstantValue['sSelectNextMonth'];
    except
    end; // except
end;
{$ENDIF}

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
  pDateControlPanel := nil;
  dtpfDateSelection := nil;
  dtpfTimeSelection := nil;
  cvfDateSelection := nil;
  fDayName := nil;
  fFirstDate := nil;
  fPreviousDay := nil;
  fToday := nil;
  fNextDay := nil;
  fLastDate := nil;
  dtptDateSelection := nil;
  dtptTimeSelection := nil;
  cvtDateSelection := nil;
  tDayName := nil;
  tFirstDate := nil;
  tPreviousDay := nil;
  tToday := nil;
  tNextDay := nil;
  tLastDate := nil;
  wPrevious := nil;
  wThis := nil;
  wNext := nil;
  mPrevious := nil;
  mThis := nil;
  mNext := nil;

  dateFirst := 0.0;
  dateLast := 0.0;

  sToday := 'Today';
  sSetToTodaysDate := 'Set to today''s date';
  sSelectPreviousWeek := 'Select the previous week';
  sSelectThisWeek := 'Select this week';
  sSelectNextWeek := 'Select the next week';
  sSelectPreviousMonth := 'Select the previous month';
  sSelectThisMonth := 'Select this month';
  sSelectNextMonth := 'Select the next month';
end.
