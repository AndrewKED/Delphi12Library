unit VCL_Ops;

interface

uses
  VCL.StdCtrls, Vcl.Controls, Vcl.ComCtrls, Vcl.Graphics,
  Vcl.WinXCalendars;

type
  TGetCanvas = Class(TCustomControl)
  published
    property Canvas;
  end;

procedure UpdateTComboBoxItems(var cbEntry : TComboBox;
                               const maxEntries : Integer = 20);
procedure CentreXAonB(controlA : TControl;
                      controlB : TControl);
procedure CentreYAonB(controlA : TControl;
                      controlB : TControl);
procedure ToggleRichEditAttributeStyle(creTarget : TCustomRichEdit;
                                       fsChange : TFontStyle);
procedure RichEditAttributeSize(creTarget : TCustomRichEdit;
                                iDifference : Integer;
                                iSetTo : integer);
procedure Scroll(memTarget : TMemo;
                 bToBottom : boolean); overload;
procedure Scroll(reTarget : TRichEdit;
                 bToBottom : boolean); overload;
function GetTEditsDate(sType : String;
                       cOwner : TWinControl;
                       bErrorMessage : boolean;
                       bPermitNull : boolean;
                       var bError : boolean) : TDateTime;
function GetTEditsTime(sType : String;
                       cOwner : TWinControl;
                       bSeconds : boolean;
                       bErrorMessage : boolean;
                       bPermitNull : boolean;
                       var bError : boolean) : TDateTime;
procedure SetDateControlsToWeek(ctrlFrom, ctrlTo : TMonthCalendar;
                                dtFrom : TDateTime); overload;
procedure SetDateControlsToWeek(ctrlFrom, ctrlTo : TDateTimePicker;
                                dtFrom : TDateTime); overload;
procedure SetDateControlsToWeek(ctrlFrom, ctrlTo : TCalendarView;
                                dtFrom : TDateTime); overload;
procedure SetDateControlsToMonth(ctrlFrom, ctrlTo : TMonthCalendar;
                                 dtFrom : TDateTime;
                                 firstDay : Integer); overload;
procedure SetDateControlsToMonth(ctrlFrom, ctrlTo : TDateTimePicker;
                                 dtFrom : TDateTime;
                                 firstDay : Integer); overload;
procedure SetDateControlsToMonth(ctrlFrom, ctrlTo : TCalendarView;
                                 dtFrom : TDateTime;
                                 firstDay : Integer); overload;

implementation

uses
  System.SysUtils, System.DateUtils,
  Vcl.Dialogs,
  WinAPI.Messages, WinAPI.Windows,
  TimeDate;

//***************************************************************************
//
//  FUNCTION  : UpdateTComboBoxItems
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Update TComboBox.Items to include TComboBox.Text.
//
//              If .Text is already in .Items, move it up to the top.
//
//  UPDATED   : 2010-11-11
//
//***************************************************************************
procedure UpdateTComboBoxItems(var cbEntry : TComboBox;
                               const maxEntries : Integer = 20);
var
  bFound : Boolean;
  n : Integer;
  sLatestEntry : String;

begin
  if (cbEntry.Items.Count>0) then
  begin
    // Try to find the address in the stored list
    bFound := FALSE;
    n := 0;
    while ((n<=cbEntry.Items.Count-1) and
           (n < maxEntries-1) and
           (not bFound)) do
    begin
      if (cbEntry.Items.Strings[n].ToUpper = UpperCase(cbEntry.Text)) then
        bFound := TRUE;
      Inc(n);
    end; // while

    sLatestEntry := cbEntry.Text;

    // If found, delete it from the location where it was
    if (bFound) then
      cbEntry.Items.Delete(n-1);
    // Chop off the oldest address if there are too many in the list
    if (cbEntry.Items.Count >= maxEntries) then
      cbEntry.Items.Delete(maxEntries-1);
    // Add the address to the top of the list
    cbEntry.Items.Insert(0,sLatestEntry);
  end // if
  else
    // Add the first entry
    cbEntry.Items.Add(cbEntry.Text);
  cbEntry.ItemIndex := 0;
end; // UpdateTComboBoxItems

//***************************************************************************
//
//  FUNCTION  : CentreXAonB
//
//  I/P       : controlA : TControl - The target control, to be centred
//
//              controlB : TControl - The reference control
//
//  O/P       : controlA.Left is updated
//
//  OPERATION : Adjust controlA's left position, so it is centred on control B,
//              in the X-axis.
//
//  UPDATED   : 2023-09-20
//
//***************************************************************************
procedure CentreXAonB(controlA : TControl;
                      controlB : TControl);
begin
  controlA.Left := controlB.Left +
    (controlB.Width - controlA.Width) div 2;
end; // CentreXAonB

//***************************************************************************
//
//  FUNCTION  : CentreYAonB
//
//  I/P       : controlA : TControl - The target control, to be centred
//
//              controlB : TControl - The reference control
//
//  O/P       : controlA.Top is updated
//
//  OPERATION : Adjust controlA's top position, so it is centred on control B,
//              in the Y-axis.
//
//  UPDATED   : 2023-09-20
//
//***************************************************************************
procedure CentreYAonB(controlA : TControl;
                     controlB : TControl);
begin
  controlA.Top := controlB.Top +
    (controlB.Height - controlA.Height) div 2;
end; // CentreYAonB

//***************************************************************************
//
//  FUNCTION  : ToggleRichEditAttributeStyle
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
procedure ToggleRichEditAttributeStyle(creTarget : TCustomRichEdit;
                                       fsChange : TFontStyle);
var
  iSStart : Integer;
  iSLength : Integer;
  bSet : boolean;
  n : Integer;

begin
  // Determine the span of the selection and
  // the state of the first character in the seleciton
  iSStart := creTarget.SelStart;
  iSLength := creTarget.SelLength;
  bSet := not (fsChange in creTarget.SelAttributes.Style);

  // Go through each of the characters in the selection, modifying them to adjust
  // the indicated attribute to the required setting
  for n := iSStart to iSStart + iSLength-1 do
  begin
    creTarget.SelStart := n;
    creTarget.SelLength := 1;
    if (bSet) then
      creTarget.SelAttributes.Style := creTarget.SelAttributes.Style + [fsChange]
    else
      creTarget.SelAttributes.Style := creTarget.SelAttributes.Style - [fsChange];
  end; // for

  // Reselect the original selection
  creTarget.SelStart := iSStart;
  creTarget.SelLength := iSLength;
end; // ToggleRichEditAttributeStyle

//***************************************************************************
//
//  FUNCTION  : RichEditAttributeSize
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
procedure RichEditAttributeSize(creTarget : TCustomRichEdit;
                                iDifference : Integer;
                                iSetTo : integer);
var
  iSStart : Integer;
  iSLength : Integer;
  n : Integer;

begin
  // Determine the span of the selection
  iSStart := creTarget.SelStart;
  iSLength := creTarget.SelLength;

  // Go through each of the characters in the selection, modifying them to adjust
  // the sizea to the required setting
  for n := iSStart to iSStart + iSLength-1 do
  begin
    creTarget.SelStart := n;
    creTarget.SelLength := 1;
    if (iSetTo > 0) then
      creTarget.SelAttributes.Size := iSetTo
    else
      if (creTarget.SelAttributes.Size + iDifference > 0) then
      creTarget.SelAttributes.Size := creTarget.SelAttributes.Size + iDifference;
  end; // for

  // Reselect the original selection
  creTarget.SelStart := iSStart;
  creTarget.SelLength := iSLength;
end; // RichEditAttributeSize

//***************************************************************************
//
//  FUNCTION  : Scroll
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : http://fgaillard.com/2010/11/richedit-on-scrolling-strike/
//
//              Scrolls given TRichEdit to the caret or the bottom.
//
//  UPDATED   : 2012-08-06
//
//***************************************************************************
procedure Scroll(memTarget : TMemo;
                 bToBottom : boolean); overload;
var
  isSelectionHidden: Boolean;

begin
  with memTarget do
  begin
    SelStart := Perform(EM_LINEINDEX, Lines.Count, 0);  //Set caret at end
    isSelectionHidden := HideSelection;
    try
      HideSelection := False;
      if (bToBottom) then
        Perform(WM_VSCROLL, SB_BOTTOM, 0) // Scroll to bottom
      else
        Perform(EM_SCROLLCARET, 0, 0);    // Scroll to caret
    finally
      HideSelection := isSelectionHidden;
    end;
  end;
end; // Scroll

procedure Scroll(reTarget : TRichEdit;
                 bToBottom : boolean); overload;
var
  isSelectionHidden: Boolean;

begin
  with reTarget do
  begin
    SelStart := Perform(EM_LINEINDEX, Lines.Count, 0);//Set caret at end
    isSelectionHidden := HideSelection;
    try
      HideSelection := False;
      if (bToBottom) then
        Perform(WM_VSCROLL, SB_BOTTOM, 0) // Scroll to bottom
      else
        Perform(EM_SCROLLCARET, 0, 0);    // Scroll to caret
    finally
      HideSelection := isSelectionHidden;
    end;
  end;
end; // Scroll

//***************************************************************************
//
// FUNCTION  : GetTEditsDate
//
// I/P       : sType - The name associated with the three TEdit
//               controls that hold the year, month and day.
//
//             cOwner (TWinControl) - Owner component of the three
//               TEdit controls
//
//             bErrorMessage - TRUE if an error message is to be
//               displayed if the date is invalid.
//
//             bPermitNull - TRUE if a null entry may be considered
//               to be valid.
//
//             bError - TRUE if there was an error in the
//               conversion.
//
// O/P       : TDateTime - The date, if valid, else 0.0
//
// OPERATION : Converts the date given in three separate TEdit
//             controls, neamed e'sType'Year, e'sType'Month and
//             e'sType'Day into a TDateTime.
//
//             Optionally gives an error message if the date is
//             bad.   Optionally permits the date entries to be
//             all left blank.
//
// UPDATED   : 2005/04/22
//
//***************************************************************************
function GetTEditsDate(sType : String;
                       cOwner : TWinControl;
                       bErrorMessage : boolean;
                       bPermitNull : boolean;
                       var bError : boolean) : TDateTime;
var
  eYear : TEdit;
  eMonth : TEdit;
  eDay : TEdit;
begin
  try
    // Identify the components
    eYear := cOwner.FindComponent('e' + sType + 'Year') as TEdit;
    eMonth := cOwner.FindComponent('e' + sType + 'Month') as TEdit;
    eDay := cOwner.FindComponent('e' + sType + 'Day') as TEdit;
    // Identify all null entries
    if ((eYear.Text = '') and
        (eMonth.Text = '') and
        (eDay.Text = '')) then
    begin
      result := 0.0;
      if (bPermitNull) then
        // If this is allowed, it's OK
        bError := FALSE
      else
      begin
        // Flag if it's not allowed, and display an error message, if required.
        bError := TRUE;
        if (bErrorMessage) then
          MessageDlg(Format(sInvalidSDate,[sType]),mtError,[mbOK],0);
      end; // else
    end // if
    else
    begin
      // Check whether the date is valid
      if (Valid_Date(StrToInt(eYear.Text),StrToInt(eMonth.Text),StrToInt(eDay.Text))) then
      begin
        result := EncodeDate(StrToInt(eYear.Text),StrToInt(eMonth.Text),StrToInt(eDay.Text));
        bError := FALSE;
      end // if
      else
      begin
        // The date is illegal (e.g. invalid day for a month)
        result := 0.0;
        // Flag an error, and display an error message, if required.
        bError := TRUE;
        if (bErrorMessage) then
          MessageDlg(Format(sInvalidSDate,[sType]),mtError,[mbOK],0);
      end; // else
    end; // else
  except
    // Something went wrong - probably in the StrToInt conversions.
    result := 0.0;
    // Flag an error, and display an error message, if required.
    bError := TRUE;
    if (bErrorMessage) then
      MessageDlg(Format(sInvalidSDate,[sType]),mtError,[mbOK],0);
  end; // except
end; // GetTEditsDate

//***************************************************************************
//
// FUNCTION  : GetTEditsTime
//
// I/P       : sType - The name associated with the three TEdit
//               controls that hold the hour, minute and second (optional).
//
//             cOwner (TWinControl) - Owner component of the three
//               TEdit controls
//
//             bSeconds (boolean) - Indicates whether there is a
//               seconds entry to be used.
//
//             bErrorMessage - TRUE if an error message is to be
//               displayed if the time is invalid.
//
//             bPermitNull - TRUE if a null entry may be considered
//               to be valid.
//
//             bError - TRUE if there was an error in the
//               conversion.
//
// O/P       : TDateTime - The time, if valid, else 0.0
//
// OPERATION : Converts the time given in two or three separate TEdit
//             controls, neamed e'sType'Hour, e'sType'Minute and
//             (optionally) e'sType'Second into a TDateTime.
//
//             Optionally gives an error message if the time is
//             bad.   Optionally permits the time entries to be
//             all left blank.
//
// UPDATED   : 2005/08/05
//
//***************************************************************************
function GetTEditsTime(sType : String;
                       cOwner : TWinControl;
                       bSeconds : boolean;
                       bErrorMessage : boolean;
                       bPermitNull : boolean;
                       var bError : boolean) : TDateTime;
var
  eHour : TEdit;
  eMinute : TEdit;
  eSecond : TEdit;
begin
  try
    // Identify the components
    eHour := cOwner.FindComponent('e' + sType + 'Hour') as TEdit;
    eMinute := cOwner.FindComponent('e' + sType + 'Minute') as TEdit;
    if (bSeconds) then
      eSecond := cOwner.FindComponent('e' + sType + 'Second') as TEdit
    else
      eSecond := nil;
    // Identify all null entries
    if ((eHour.Text = '') and
        (eMinute.Text = '') and
        ((not bSeconds) or ((bSeconds) and (eSecond.Text = '')))) then
    begin
      result := 0.0;
      if (bPermitNull) then
        // If this is allowed, it's OK
        bError := FALSE
      else
      begin
        // Flag if it's not allowed, and display an error message, if required.
        bError := TRUE;
        if (bErrorMessage) then
          MessageDlg(Format(sInvalidSTime,[sType]),mtError,[mbOK],0);
      end; // else
    end // if
    else
    begin
      // Check whether the time is valid
      if (((bSeconds) and (Valid_Time(StrToInt(eHour.Text),StrToInt(eMinute.Text),StrToInt(eSecond.Text),0))) or
          ((not bSeconds) and (Valid_Time(StrToInt(eHour.Text),StrToInt(eMinute.Text),0,0)))) then
      begin
        if (bSeconds) then
          result := EncodeTime(StrToInt(eHour.Text),StrToInt(eMinute.Text),StrToInt(eSecond.Text),0)
        else
          result := EncodeTime(StrToInt(eHour.Text),StrToInt(eMinute.Text),0,0);
        bError := FALSE;
      end // if
      else
      begin
        // The date is invalid (e.g. minutes >= 60)
        result := 0.0;
        // Flag an error, and display an error message, if required.
        bError := TRUE;
        if (bErrorMessage) then
          MessageDlg(Format(sInvalidSTime,[sType]),mtError,[mbOK],0);
      end; // else
    end; // else
  except
    // Something went wrong - probably in the StrToInt conversions.
    result := 0.0;
    // Flag an error, and display an error message, if required.
    bError := TRUE;
    if (bErrorMessage) then
      MessageDlg(Format(sInvalidSTime,[sType]),mtError,[mbOK],0);
  end; // except
end; // GetTEditstime

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
procedure SetDateControlsToWeek(ctrlFrom, ctrlTo : TMonthCalendar;
                                dtFrom : TDateTime); overload;
var
  fromDOW : Integer;
  firstDOW : Integer;

begin
  fromDOW := DayOfTheWeek(DateOf(dtFrom));
  firstDOW := GetStartOfTheWeek;
  if (fromDOW >= firstDOW) then
    ctrlFrom.Date := DateOf(dtFrom) - (fromDOW - firstDOW)
  else
    ctrlFrom.Date := DateOf(dtFrom) - 7 + (firstDOW - fromDOW);
  ctrlTo.Date := ctrlFrom.Date + 6;
end; // SetDateControlsToWeek

procedure SetDateControlsToWeek(ctrlFrom, ctrlTo : TDateTimePicker;
                                dtFrom : TDateTime); overload;
var
  fromDOW : Integer;
  firstDOW : Integer;

begin
  fromDOW := DayOfTheWeek(DateOf(dtFrom));
  firstDOW := GetStartOfTheWeek;
  if (fromDOW >= firstDOW) then
    ctrlFrom.Date := DateOf(dtFrom) - (fromDOW - firstDOW)
  else
    ctrlFrom.Date := DateOf(dtFrom) - 7 + (firstDOW - fromDOW);
  ctrlTo.Date := ctrlFrom.Date + 6;
end; // SetDateControlsToWeek

procedure SetDateControlsToWeek(ctrlFrom, ctrlTo : TCalendarView;
                                dtFrom : TDateTime); overload;
var
  fromDOW : Integer;
  firstDOW : Integer;

begin
  fromDOW := DayOfTheWeek(DateOf(dtFrom));
  firstDOW := GetStartOfTheWeek;
  if (fromDOW >= firstDOW) then
    ctrlFrom.Date := DateOf(dtFrom) - (fromDOW - firstDOW)
  else
    ctrlFrom.Date := DateOf(dtFrom) - 7 + (firstDOW - fromDOW);
  ctrlTo.Date := ctrlFrom.Date + 6;
end; // SetDateControlsToWeek

//***************************************************************************
//
//  FUNCTION  : SetDateControlsToMonth
//
//  I/P       : mcFrom,mcTo : TMonthCalendar or TDateTimePicker
//                The two date controls
//
//              dtFrom : TDateTime - A date that falls within the month that
//                must be shown in the FROM month calendar
//
//              firstDay : Integer - The day number to be selected in the
//                FROM calendar (and consequently the day number-1 to be
//                specified in the TO calendar)
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2019-08-27
//
//***************************************************************************
procedure SetDateControlsToMonth(ctrlFrom, ctrlTo : TMonthCalendar;
                                 dtFrom : TDateTime;
                                 firstDay : Integer); overload;
begin
  if (DayOf(dtFrom) >= firstDay) then
    ctrlFrom.Date := EncodeDate(YearOf(dtFrom), MonthOf(dtFrom), firstDay)
  else
    ctrlFrom.Date := EncodeDate(YearOf(IncMonth(dtFrom,-1)), MonthOf(IncMonth(dtFrom,-1)), firstDay);
  ctrlTo.Date := EncodeDate(YearOf(ctrlFrom.Date), MonthOf(ctrlFrom.Date), DaysInMonth(ctrlFrom.Date));
end; // SetDateControlsToMonth

procedure SetDateControlsToMonth(ctrlFrom, ctrlTo : TDateTimePicker;
                                 dtFrom : TDateTime;
                                 firstDay : Integer); overload;
begin
  if (DayOf(dtFrom) >= firstDay) then
    ctrlFrom.Date := EncodeDate(YearOf(dtFrom), MonthOf(dtFrom), firstDay)
  else
    ctrlFrom.Date := EncodeDate(YearOf(IncMonth(dtFrom,-1)), MonthOf(IncMonth(dtFrom,-1)), firstDay);
  ctrlTo.Date := EncodeDate(YearOf(ctrlFrom.Date), MonthOf(ctrlFrom.Date), DaysInMonth(ctrlFrom.Date));
end; // SetDateControlsToMonth

procedure SetDateControlsToMonth(ctrlFrom, ctrlTo : TCalendarView;
                                 dtFrom : TDateTime;
                                 firstDay : Integer); overload;
begin
  if (DayOf(dtFrom) >= firstDay) then
    ctrlFrom.Date := EncodeDate(YearOf(dtFrom), MonthOf(dtFrom), firstDay)
  else
    ctrlFrom.Date := EncodeDate(YearOf(IncMonth(dtFrom,-1)), MonthOf(IncMonth(dtFrom,-1)),firstDay);
  ctrlTo.Date := EncodeDate(YearOf(ctrlFrom.Date), MonthOf(ctrlFrom.Date), DaysInMonth(ctrlFrom.Date));
end; // SetDateControlsToMonth



end.
