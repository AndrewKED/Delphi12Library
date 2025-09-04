unit Calendar_Ops;

interface

uses
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.WinXCalendars,
  DKLang,
  Reports;

procedure SetupCalendarControls(dateControlPanel : TPanel;
                                fromDateSelection : TDateTimePicker;
                                fromDayName : TLabel;
                                fromVehicleFirst : TCustomButton;
                                fromPreviousDay : TCustomButton;
                                fromToday : TCustomButton;
                                fromNextDay : TCustomButton;
                                fromVehicleLast : TCustomButton;
                                toDateSelection : TDateTimePicker;
                                toDayName : TLabel;
                                toVehicleFirst : TCustomButton;
                                toPreviousDay : TCustomButton;
                                toToday : TCustomButton;
                                toNextDay : TCustomButton;
                                toVehicleLast : TCustomButton;
                                weekPrevious : TCustomButton;
                                weekThis : TCustomButton;
                                weekNext : TCustomButton;
                                monthPrevious : TCustomButton;
                                monthThis : TCustomButton;
                                monthNext : TCustomButton;
                                rt : TReportVehicleType) overload;
procedure SetupCalendarControls(dateControlPanel : TPanel;
                                fromDateSelection : TCalendarView;
                                fromDayName : TLabel;
                                fromVehicleFirst : TCustomButton;
                                fromPreviousDay : TCustomButton;
                                fromToday : TCustomButton;
                                fromNextDay : TCustomButton;
                                fromVehicleLast : TCustomButton;
                                toDateSelection : TCalendarView;
                                toDayName : TLabel;
                                toVehicleFirst : TCustomButton;
                                toPreviousDay : TCustomButton;
                                toToday : TCustomButton;
                                toNextDay : TCustomButton;
                                toVehicleLast : TCustomButton;
                                weekPrevious : TCustomButton;
                                weekThis : TCustomButton;
                                weekNext : TCustomButton;
                                monthPrevious : TCustomButton;
                                monthThis : TCustomButton;
                                monthNext : TCustomButton;
                                rt : TReportVehicleType) overload;
procedure UpdateDateControls;
procedure UpdateDayNames;

implementation

uses
  System.SysUtils,
  DataModule,
  Recorders,
  Form_Ops;

var
  pDateControlPanel : TPanel;
  dtpfDateSelection : TDateTimePicker;
  cvfDateSelection : TCalendarView;
  fDayName : TLabel;
  fVehicleFirst : TCustomButton;
  fPreviousDay : TCustomButton;
  fToday : TCustomButton;
  fNextDay : TCustomButton;
  fVehicleLast : TCustomButton;
  dtptDateSelection : TDateTimePicker;
  cvtDateSelection : TCalendarView;
  tDayName : TLabel;
  tVehicleFirst : TCustomButton;
  tPreviousDay : TCustomButton;
  tToday : TCustomButton;
  tNextDay : TCustomButton;
  tVehicleLast : TCustomButton;
  wPrevious : TCustomButton;
  wThis : TCustomButton;
  wNext : TCustomButton;
  mPrevious : TCustomButton;
  mThis : TCustomButton;
  mNext : TCustomButton;
  reportType : TReportVehicleType;

//***************************************************************************
//
//  FUNCTION  : SetTodayHints
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Set the hints on the "Today" buttons
//
//  UPDATED   : 2023-09-12
//
//***************************************************************************
procedure SetTodayHints;
begin
  if (fToday <> nil) then
  begin
    fToday.Hint := LangManager.ConstantValue['sToday'] +
      '|' + LangManager.ConstantValue['sSetToTodaysDate'];
  end;
  if (tToday <> nil) then
  begin
    tToday.Hint := LangManager.ConstantValue['sToday'] +
      '|' + LangManager.ConstantValue['sSetToTodaysDate'];
  end; // if
end; // SetTodayHints;

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
procedure SetupCalendarControls(dateControlPanel : TPanel;
                                fromDateSelection : TDateTimePicker;
                                fromDayName : TLabel;
                                fromVehicleFirst : TCustomButton;
                                fromPreviousDay : TCustomButton;
                                fromToday : TCustomButton;
                                fromNextDay : TCustomButton;
                                fromVehicleLast : TCustomButton;
                                toDateSelection : TDateTimePicker;
                                toDayName : TLabel;
                                toVehicleFirst : TCustomButton;
                                toPreviousDay : TCustomButton;
                                toToday : TCustomButton;
                                toNextDay : TCustomButton;
                                toVehicleLast : TCustomButton;
                                weekPrevious : TCustomButton;
                                weekThis : TCustomButton;
                                weekNext : TCustomButton;
                                monthPrevious : TCustomButton;
                                monthThis : TCustomButton;
                                monthNext : TCustomButton;
                                rt : TReportVehicleType);
begin
  pDateControlPanel := dateControlPanel;
  dtpfDateSelection := fromDateSelection;
  cvfDateSelection := nil;
  fDayName := fromDayName;
  fVehicleFirst := fromVehicleFirst;
  fPreviousDay := fromPreviousDay;
  fToday := fromToday;
  fNextDay := fromNextDay;
  fVehicleLast := fromVehicleLast;
  dtptDateSelection := toDateSelection;
  cvtDateSelection := nil;
  tDayName := toDayName;
  tVehicleFirst := toVehicleFirst;
  tPreviousDay := toPreviousDay;
  tToday := toToday;
  tNextDay := toNextDay;
  tVehicleLast := toVehicleLast;
  wPrevious := weekPrevious;
  wThis := monthThis;
  wNext := monthThis;
  mPrevious := monthThis;
  mThis := monthThis;
  mNext := monthNext;
  reportType := rt;

  // Set start and finish to the most recently used date range
  dtpfDateSelection.Date := LatestPeriodStart;
  dtptDateSelection.Date := LatestPeriodEnd;

  wPrevious.Hint := '|' + LangManager.ConstantValue['sSelectPreviousWeek'];
  wThis.Hint := '|' + LangManager.ConstantValue['sSelectThisWeek'];
  wNext.Hint := '|' + LangManager.ConstantValue['sSelectNextWeek'];
  mPrevious.Hint := '|' + LangManager.ConstantValue['sSelectPreviousMonth'];
  mThis.Hint := '|' + LangManager.ConstantValue['sSelectThisMonth'];
  mNext.Hint := '|' + LangManager.ConstantValue['sSelectNextMonth'];

  SetTodayHints;
end;

procedure SetupCalendarControls(dateControlPanel : TPanel;
                                fromDateSelection : TCalendarView;
                                fromDayName : TLabel;
                                fromVehicleFirst : TCustomButton;
                                fromPreviousDay : TCustomButton;
                                fromToday : TCustomButton;
                                fromNextDay : TCustomButton;
                                fromVehicleLast : TCustomButton;
                                toDateSelection : TCalendarView;
                                toDayName : TLabel;
                                toVehicleFirst : TCustomButton;
                                toPreviousDay : TCustomButton;
                                toToday : TCustomButton;
                                toNextDay : TCustomButton;
                                toVehicleLast : TCustomButton;
                                weekPrevious : TCustomButton;
                                weekThis : TCustomButton;
                                weekNext : TCustomButton;
                                monthPrevious : TCustomButton;
                                monthThis : TCustomButton;
                                monthNext : TCustomButton;
                                rt : TReportVehicleType);
begin
  pDateControlPanel := dateControlPanel;
  dtpfDateSelection := nil;
  cvfDateSelection := fromDateSelection;
  fDayName := fromDayName;
  fVehicleFirst := fromVehicleFirst;
  fPreviousDay := fromPreviousDay;
  fToday := fromToday;
  fNextDay := fromNextDay;
  fVehicleLast := fromVehicleLast;
  dtptDateSelection := nil;
  cvtDateSelection := toDateSelection;
  tDayName := toDayName;
  tVehicleFirst := toVehicleFirst;
  tPreviousDay := toPreviousDay;
  tToday := toToday;
  tNextDay := toNextDay;
  tVehicleLast := toVehicleLast;
  wPrevious := weekPrevious;
  wThis := monthThis;
  wNext := monthThis;
  mPrevious := monthThis;
  mThis := monthThis;
  mNext := monthNext;
  reportType := rt;

  // Set start and finish to the most recently used date range
  cvfDateSelection.Date := LatestPeriodStart;
  cvtDateSelection.Date := LatestPeriodEnd;

  SetTodayHints;
end;

//***************************************************************************
//
//  FUNCTION  : UpdateDateControls
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Set the date control availability and earliest/latest dates
//              for the report.
//
//  UPDATED   : 2023-09-12
//
//***************************************************************************
procedure UpdateDateControls;
begin
  if (reportType = SV) then
  begin
    // Check for no data available
    pDateControlPanel.Enabled := (dmData.tVDD.Fields[FLX_VDD_FIRST_DATA].AsDateTime <> 0.0);
    EnabledAsParent(pDateControlPanel);
  end
  else
  begin
    UpdateMVSelectionDateRange;

    // Check for no data available
    pDateControlPanel.Enabled := (dmData.tSelected.RecordCount > 0);
    EnabledAsParent(pDateControlPanel);
  end;

  fVehicleFirst.Hint :=
    FormatDateTime('ddddd', GetBestFirstReportDate(reportType)) +
    '|' + LangManager.ConstantValue['sFromFirstDayHint'];
  tVehicleFirst.Hint := fVehicleFirst.Hint;
  fVehicleLast.Hint :=
    FormatDateTime('(ddddd)', GetBestLastReportDate(reportType)) +
    '|' + LangManager.ConstantValue['sToLastDayHint'];
  tVehicleLast.Hint := fVehicleLast.Hint;
end; // UpdateDateControls

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
initialization
  pDateControlPanel := nil;
  dtpfDateSelection := nil;
  cvfDateSelection := nil;
  fDayName := nil;
  fVehicleFirst := nil;
  fPreviousDay := nil;
  fToday := nil;
  fNextDay := nil;
  fVehicleLast := nil;
  dtptDateSelection := nil;
  cvtDateSelection := nil;
  tDayName := nil;
  tVehicleFirst := nil;
  tPreviousDay := nil;
  tToday := nil;
  tNextDay := nil;
  tVehicleLast := nil;
  wPrevious := nil;
  wThis := nil;
  wNext := nil;
  mPrevious := nil;
  mThis := nil;
  mNext := nil;
  reportType := SV;

end.
