unit UniGui_Ops;

interface

uses
  System.SysUtils,
  uniGUIClasses, uniGUIApplication, uniGUIForm, uniPanel, uniDBGrid,
  uniStringGrid;

const
  PERSISTENT_COOKIE_EXPIRY = 73051; // Equivalend of EncodeDate(2100,1,1)

procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
procedure CentreXAonB(controlA : TUniControl;
                      controlB : TUniControl) overload;
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
procedure CentreYAonB(controlA : TUniControl;
                      controlB : TUniControl) overload;
procedure SetReadOnly(owner : TUniContainer;
                      state : Boolean;
                      handleButtons : Boolean);
procedure SetDateFormat(owner : TUniContainer;
                        newFormat : String);
procedure uniDBGridAutoWidth(aGrid: TUniDBGrid; aFieldName: String = '');
procedure ResizeGridColumns(theGrid : TUniDBGrid;
                            columnRatios : TArray<Integer>); overload;
procedure ResizeGridColumns(theGrid : TUniStringGrid;
                            columnRatios : TArray<Integer>); overload;
function GetCookieInteger(app : TUniGUIApplication;
                          cookie : String;
                          default : Integer) : Integer;
function GetCookieBoolean(app : TUniGUIApplication;
                          cookie : String;
                          default : Boolean) : Boolean;
function GetCookieISO8601DateTime(app : TUniGUIApplication;
                                  cookie : String;
                                  expectUTC : Boolean;
                                  default : TDateTime) : TDateTime;
procedure FocusAndSelectAll(focusControl : TUniControl);
procedure EnabledAsParent(container : TUniContainer);
procedure SetSpeedButtonFonts(Sender : TObject;
                              cParent : TUniContainer);
procedure DisableColumnTitleMenus(targetDBGrid : TUniDBGrid);

implementation

uses
  System.TypInfo, System.Classes, System.DateUtils, Graphics,
  uniButton, uniGUITypes, uniBasicGrid, uniDBEdit, uniMemo, uniDBMemo,
  uniSpeedButton,
  uniDateTimePicker,
  Str_Ops, HTML_Ops;
//  uniCheckBox, uniEdit, uniDateTimePicker, uniMemo,
//  uniDBCheckBox, uniDBEdit, uniDBDateTimePicker, uniDBMemo;

//***************************************************************************
//
//  FUNCTION  : CentreXAonB
//
//  I/P       : controlA : TUniControl - The target control, to be centred
//
//              controlB : TUniControl - The reference control
//
//  O/P       : controlA.Left is updated
//
//  OPERATION : Adjust controlA's left position, so it is centred on control B,
//              in the X-axis.
//
//  UPDATED   : 2023-09-20
//
//***************************************************************************
procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
begin
  controlA.Left := controlB.Left +
    (controlB.Width - controlA.Width) div 2;
end; // CentreXAonB
procedure CentreXAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
begin
  controlA.Left := controlB.Left +
    (controlB.Width - controlA.Width) div 2;
end; // CentreXAonB

procedure CentreXAonB(controlA : TUniControl;
                      controlB : TUniControl) overload;
begin
  controlA.Left := controlB.Left +
    (controlB.Width - controlA.Width) div 2;
end; // CentreXAonB

//***************************************************************************
//
//  FUNCTION  : CentreYAonB
//
//  I/P       : controlA : TUniControl - The target control, to be centred
//
//              controlB : TUniControl - The reference control
//
//  O/P       : controlA.Top is updated
//
//  OPERATION : Adjust controlA's top position, so it is centred on control B,
//              in the Y-axis.
//
//  UPDATED   : 2023-09-20
//
//***************************************************************************
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniPanel) overload;
begin
  controlA.Top := controlB.Top +
    (controlB.Height - controlA.Height) div 2;
end; // CentreYAonB
procedure CentreYAonB(controlA : TUniPanel;
                      controlB : TUniForm) overload;
begin
  controlA.Top := controlB.Top +
    (controlB.Height - controlA.Height) div 2;
end; // CentreYAonB
procedure CentreYAonB(controlA : TUniControl;
                      controlB : TUniControl) overload;
begin
  controlA.Top := controlB.Top +
    (controlB.Height - controlA.Height) div 2;
end; // CentreYAonB

//***************************************************************************
//
//  FUNCTION  : SetReadOnly
//
//  I/P       : owner : TUniContainer - The owner of the controls
//
//              state : Boolean - the ReadOnly state to be set.
//
//              handleButtons : Boolean - If TRUE, hide any buttons within the
//                container when setting the ReadOnly status to TRUE.
//
//  O/P       : None
//
//  OPERATION : Set the ReadOnly status of all components which have this
//              property, within a given container.
//
//              Optionally also set the Visible property of TUniButtons to give
//              a similar effect (i.e. can/cannot be clicked)
//
//  UPDATED   : 2024-11-12
//
//***************************************************************************
procedure SetReadOnly(owner : TUniContainer;
                      state : Boolean;
                      handleButtons : Boolean);
var
  n : Integer;
  propList : PPropList;
  propCount : Integer;
  m: Integer;

begin
  for n := 0 to owner.ControlCount-1 do
  begin
    if (owner.Controls[n] is TUniContainer) then
    begin
      SetReadOnly(TUniContainer(owner.Controls[n]), state, handleButtons);
    end;

    // If required, treat a button's Visible state like not ReadOnly.
    if (owner.Controls[n] is TUniButton) then
    begin
      if (handleButtons) then
      begin
        TUniButton(owner.Controls[n]).Visible := not state;
      end;
      Continue;
    end;

    propCount := GetPropList(owner.Controls[n], propList);
    try
      for m := 0 to propCount-1 do
      begin
        if (propList[m].Name = 'ReadOnly') then
        begin
          SetPropValue(owner.Controls[n], 'ReadOnly', state);
        end;
      end;
    finally
      FreeMem(propList);
    end;
  end; // for
end;

//***************************************************************************
//
//  FUNCTION  : SetDateFormat
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Force all components that have a DateFormat property to use
//              the given format.
//
//  UPDATED   : 2024-11-12
//
//***************************************************************************
procedure SetDateFormat(owner : TUniContainer;
                        newFormat : String);
var
  n : Integer;
  propList : PPropList;
  propCount : Integer;
  m: Integer;

begin
  for n := 0 to owner.ControlCount-1 do
  begin
    if (owner.Controls[n] is TUniContainer) then
    begin
      SetDateFormat(TUniContainer(owner.Controls[n]), newFormat);
    end;

    propCount := GetPropList(owner.Controls[n], propList);
    try
      for m := 0 to propCount-1 do
      begin
        if (propList[m].Name = 'DateFormat') then
        begin
          SetPropValue(owner.Controls[n], 'DateFormat', newFormat);
        end;
      end;
    finally
      FreeMem(propList);
    end;
  end; // for
end;

//***************************************************************************
//
//  FUNCTION  : UniDBGridAutoWidth
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//              From https://forums.unigui.com/index.php?/topic/4627-set-tunidbgrids-column-width-with-percentage/
//
//  UPDATED   : 2024-11-18
//
//***************************************************************************
procedure uniDBGridAutoWidth(aGrid: TUniDBGrid; aFieldName: String = '');
var
  s: String;
  i: Integer;

begin
  if aFieldName = '' then
  begin
    s := 'sender.headerCt.forceFit=true;'
  end
  else
  begin
    with TStringList.Create do
    try
      Delimiter := ';';
      StrictDelimiter := True;
      DelimitedText := LowerCase(aFieldName);
      for i := 0 to Pred(aGrid.Columns.Count) do
      begin
        if IndexOf(LowerCase(aGrid.Columns[i].FieldName)) <> -1 then
        begin
          s := s + Format('columns[%d].flex=1;', [i]);
        end;
      end;
    finally
      Free;
    end;
  end; // else

  if s <> '' then
  begin
    aGrid.ClientEvents.ExtEvents.Add(Format(
      'beforereconfigure=function beforereconfigure(sender, store, columns, oldStore, the, eOpts)' +
      '{%s}', [s])
    );
  end;
end;

//***************************************************************************
//
//  FUNCTION  : GetGridClientWidth
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Returns the amount of horizontal space that could be
//              apportioned between cells in a grid
//
//  UPDATED   :
//
//***************************************************************************
function GetGridClientWidth(cgTarget : TUniBasicGrid) : Integer;
begin
  Result := cgTarget.Width - 20; // GetSystemMetrics(SM_CXVSCROLL);
  // Only available in TDBGrids
//  if (cgTarget is TDBGrid) then
//  begin
//    if (dgIndicator in (cgTarget as TDBGrid).Options) then
//    begin
//      result := result - INDICATORWIDTH;
//      if dgColLines in (cgTarget as TDBGrid).Options then
//        Dec(result);
//    end; // if
//    if (dgColLines in (cgTarget as TDBGrid).Options) then
//      result := result - (cgTarget as TDBGrid).Columns.Count;
//  end; // if
//
//  if (((cgTarget is TDBGrid) and
//       ((cgTarget as TDBGrid).Ctl3D)) or
//      ((cgTarget is TStringGrid) and
//       ((cgTarget as TStringGrid).Ctl3D))) then
//  begin
//    if (((cgTarget is TDBGrid) and
//         ((cgTarget as TDBGrid).BorderStyle = bsSingle)) or
//        ((cgTarget is TStringGrid) and
//         ((cgTarget as TStringGrid).BorderStyle = bsSingle))) then
//      // 2 * 2 Pixel
//      result := result - 4
//    else
//      // 2 * 1 Pixel
//      result := result - 2;
//  end; // if
//
//  if ((cgTarget is TStringGrid) and
//      (goVertLine in (cgTarget as TStringGrid).Options)) then
//    result := result -
//              (cgTarget as TStringGrid).ColCount * (cgTarget as TStringGrid).GridLineWidth;
//
//
end; // GetGridClientWidth

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
procedure ResizeGridColumns(theGrid : TUniDBGrid;
                            columnRatios : TArray<Integer>); overload;
var
  iClientWidth : Integer;
  t : Integer;
  iTotal : Integer;

begin
  if (Length(columnRatios) = theGrid.Columns.Count) then
  begin
    iTotal := 0;
    for t := 0 to theGrid.Columns.Count-1 do
    begin
      if (theGrid.Columns[t].Visible) then
      begin
        iTotal := iTotal + columnRatios[t];
      end;
    end; // for

    iClientWidth := GetGridClientWidth(theGrid);

    if (iTotal <> 0) then
    begin
      for t := 0 to theGrid.Columns.Count-1 do
      begin
        if (theGrid.Columns[t].Visible) then
        begin
          theGrid.Columns[t].Width := iClientWidth * columnRatios[t] div iTotal;
        end;
      end; // for
    end; // if
  end;
end; // ResizeGridColumns

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
procedure ResizeGridColumns(theGrid : TUniStringGrid;
                            columnRatios : TArray<Integer>); overload;
var
  iClientWidth : Integer;
  t : Integer;
  iTotal : Integer;

begin
  if (Length(columnRatios) = theGrid.ColCount) then
  begin
    iTotal := 0;
    for t := 0 to theGrid.ColCount-1 do
    begin
      iTotal := iTotal + columnRatios[t];
    end; // for

    iClientWidth := GetGridClientWidth(theGrid);

    if (iTotal <> 0) then
    begin
      for t := 0 to theGrid.ColCount-1 do
      begin
        theGrid.ColWidths[t] := iClientWidth * columnRatios[t] div iTotal;
      end; // for
    end; // if
  end;
end; // ResizeGridColumns

//***************************************************************************
//
//  FUNCTION  : GetCookieInteger
//
//  I/P       : app : TUniGUIApplication
//
//              cookie : String - The cookie name
//
//              default : Integer - The value to be returned if the cookie is
//                not available, or is not an integer.
//
//  O/P       : Integer - The cookie value
//
//  OPERATION : Read an integer from the indicated cookie. Return a default
//              value if unavailable.
//
//  UPDATED   : 2024-12-18
//
//***************************************************************************
function GetCookieInteger(app : TUniGUIApplication;
                          cookie : String;
                          default : Integer) : Integer;
begin
  if (IsAnInteger(app.Cookies.Values[cookie])) then
  begin
    Result := StrToInt(app.Cookies.Values[cookie]);
  end
  else
  begin
    Result := default;
  end;
end; // GetCookieInteger

//***************************************************************************
//
//  FUNCTION  : GetCookieBoolean
//
//  I/P       : app : TUniGUIApplication
//
//              cookie : String - The cookie name
//
//              default : Boolean - The value to be returned if the cookie is
//                not available.
//
//  O/P       : Boolean - The cookie value
//
//  OPERATION : Read a boolean from the indicated cookie. Return a default
//              value if unavailable.
//
//  UPDATED   : 2025-02-12
//
//***************************************************************************
function GetCookieBoolean(app : TUniGUIApplication;
                          cookie : String;
                          default : Boolean) : Boolean;
begin
  if (IsAnInteger(app.Cookies.Values[cookie])) then
  begin
    Result := (app.Cookies.Values[cookie] = '1');
  end
  else
  begin
    Result := default;
  end;
end; // GetCookieBoolean

//***************************************************************************
//
//  FUNCTION  : GetCookieISO8601DateTime
//
//  I/P       : app : TUniGUIApplication
//
//              cookie : String - The cookie name
//
//              expectUTC : Boolean - TRUE if the cookie string should terminate
//                with a 'Z'
//
//              default : TDateTime - The value to be returned if the cookie
//                is not available, or is not a valid date/time in the given
//                format.
//
//  O/P       : TDateTime - The cookie value
//
//  OPERATION : Read a date/time from the indicated cookie. Return a default
//              value if unavailable.
//
//              Note that the cookie is expected to be in ISO8601 format
//
//  UPDATED   : 2025-02-12
//
//***************************************************************************
function GetCookieISO8601DateTime(app : TUniGUIApplication;
                                  cookie : String;
                                  expectUTC : Boolean;
                                  default : TDateTime) : TDateTime;
begin
  if (IsAISO8601DateTime(app.Cookies.Values[cookie], expectUTC)) then
  begin
    Result := ISO8601ToDate(app.Cookies.Values[cookie], expectUTC);
  end
  else
  begin
    Result := default;
  end;
end; // GetCookieISO8601DateTime

//***************************************************************************
//
//  FUNCTION  : FocusAndSelectAll
//
//  I/P       : focusControl : TUniControl
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2024-12-19
//
//***************************************************************************
procedure FocusAndSelectAll(focusControl : TUniControl);
begin
  if (focusControl is TUniDBEdit) then
  begin
    TUniDBEdit(focusControl).SetFocus;
    TUniDBEdit(focusControl).SelectAll;
  end // if

  else if (focusControl is TUniDBNumberEdit) then
  begin
    TUniDBNumberEdit(focusControl).SetFocus;
    TUniDBNumberEdit(focusControl).SelectAll;
  end // if

  else if (focusControl is TUniDateTimePicker) then
  begin
    TUniDateTimePicker(focusControl).SetFocus;
//!!    TUniDateTimePicker(focusControl).SelectAll;
  end // if

  else if (focusControl is TUniButton) then
  begin
    TUniButton(focusControl).SetFocus;
  end // if

  else if (focusControl is TUniMemo) then
  begin
    TUniMemo(focusControl).SetFocus;
//!!    TUniMemo(failedEntry).JSInterface.JSCall('execCmd', ['selectAll']);
  end // if

  else if (focusControl is TUniDBMemo) then
  begin
    TUniDBMemo(focusControl).SetFocus;
//!!    TUniDBMemo(failedEntry).JSInterface.JSCall('execCmd', ['selectAll']);
  end // if
end;

//***************************************************************************
//
//  FUNCTION  : EnabledAsParent
//
//  I/P       : parent : TUniContainer - The control within which
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2025-03-06
//
//***************************************************************************
procedure EnabledAsParent(container : TUniContainer);
//var
//  index: Integer;

begin
////TUniPanel, TUniCustomPanel, TUniCustomScrollablePanel, TUniCustomContainerPanel, TUniContainer
////TUniGroupBox, TUniContainer
////TUniContainerPanel, TUniCustomScrollablePanel, TUniCustomContainerPanel, TUniContainer
//
//  for index := 0 to container.ControlCount-1 do
//  begin
//    aControl := container.Controls[index];
//
//    if (IsPublishedProp(aControl, 'Enabled') then
//    begin
//
//    end;
//    aControl.Enabled := container.Enabled;
//
//    isContainer := (csAcceptsControls in Container.Controls[index].ControlStyle);
//
//    if ((isContainer) AND (aControl is TWinControl)) then
//    begin
//      // Recursive for child controls
//      EnabledAsParent(TWinControl(Container.Controls[index]));
//    end;
//  end;
//
//
//
//  if (not (parent is TUniContainer)) then
//  begin
//    Exit;
//  end;
//
//  for n := 0 to parent.ControlCount-1 do
//  begin
//    if (parent.Controls[n] is TUniButton) then
//    begin
//      TUniButton(parent.Controls[n]).Enabled := parent.Enabled;
//    end;
//    if (parent.Controls[n] is TUniMemo) then
//    begin
//      TUniMemo(parent.Controls[n]).Enabled := parent.Enabled;
//    end;
//  end; // for
end; // EnabledAsParent

//***************************************************************************
//
//  FUNCTION  : SetSpeedButtonFonts
//
//  I/P       : Sender : TSpeedButton - The TObject that we would like to
//                highlight.
//
//              cParent : TWinControl - The container of the TSpeedButton
//                and other associated TSpeedButtons
//
//  O/P       : None.
//
//  OPERATION : In a set of TUniSpeedButtons that share the same GroupIndex property,
//              highlight the given one by setting its font to Bold and Underlined.
//
//  UPDATED   : 2025-05-21
//
//***************************************************************************
procedure SetSpeedButtonFonts(Sender : TObject;
                              cParent : TUniContainer);
var
  n : Integer;

begin
  if ((Sender is TUniSpeedButton) and
      (cParent <> nil)) then
  begin
    for n := 0 to cParent.ControlCount-1 do
      if (cParent.Controls[n] is TUniSpeedButton) then
        if (((cParent.Controls[n] as TUniSpeedButton).GroupIndex <> 0) and
            ((cParent.Controls[n] as TUniSpeedButton).GroupIndex = (Sender as TUniSpeedButton).GroupIndex)) then
//          (cParent.Controls[n] as TUniSpeedButton).Font.Style :=
//            (cParent.Controls[n] as TUniSpeedButton).Font.Style - [fsBold] - [fsUnderline];
          (cParent.Controls[n] as TUniSpeedButton).Caption :=
            RemoveHTML((cParent.Controls[n] as TUniSpeedButton).Caption);
    // Now set the button's own font to bold and underlined
    (Sender as TUniSpeedButton).Caption := '<u><b>' + (Sender as TUniSpeedButton).Caption + '</b></u>';
//    (Sender as TUniSpeedButton).Font.Style := (Sender as TUniSpeedButton).Font.Style + [fsBold] + [fsUnderline];
  end; // if

//  if ((Sender is TJvSpeedButton) and
//      (cParent <> nil)) then
//  begin
//    for n := 0 to cParent.ComponentCount-1 do
//      if (cParent.Components[n] is TJvSpeedButton) then
//        if (((cParent.Components[n] as TJvSpeedButton).GroupIndex <> 0) and
//            ((cParent.Components[n] as TJvSpeedButton).GroupIndex = (Sender as TJvSpeedButton).GroupIndex)) then
//          (cParent.Components[n] as TJvSpeedButton).Font.Style :=
//            (cParent.Components[n] as TJvSpeedButton).Font.Style - [fsBold] - [fsUnderline];
//    // Now set the button's own font to bold and underlined
//    (Sender as TJvSpeedButton).Font.Style := (Sender as TJvSpeedButton).Font.Style + [fsBold] + [fsUnderline];
//  end; // if
//
//  if ((Sender is TJvArrowButton) and
//      (cParent <> nil)) then
//  begin
//    for n := 0 to cParent.ComponentCount-1 do
//      if (cParent.Components[n] is TJvArrowButton) then
//        if (((cParent.Components[n] as TJvArrowButton).GroupIndex <> 0) and
//            ((cParent.Components[n] as TJvArrowButton).GroupIndex = (Sender as TJvArrowButton).GroupIndex)) then
//          (cParent.Components[n] as TJvArrowButton).Font.Style :=
//            (cParent.Components[n] as TJvArrowButton).Font.Style - [fsBold] - [fsUnderline];
//    // Now set the button's own font to bold and underlined
//    (Sender as TJvArrowButton).Font.Style := (Sender as TJvArrowButton).Font.Style + [fsBold] + [fsUnderline];
//  end; // if
end; // SetSpeedButtonFonts

//***************************************************************************
//
//  FUNCTION  : DisableColumnTitleMenus
//
//  I/P       : targetDBGrid : TUniDBGrid - The TUniDBGrid for which column
//                title menus are to be disabled.
//
//  O/P       : None
//
//  OPERATION : Turn off all column title select/sort menus in a TUniDBGrid
//
//  UPDATED   : 2025-07-16
//
//***************************************************************************
procedure DisableColumnTitleMenus(targetDBGrid : TUniDBGrid);
var
  n: Integer;

begin
  for n := 0 to targetDBGrid.Columns.Count-1 do
  begin
    targetDBGrid.Columns.ColumnFromId(n).Menu.MenuEnabled := FALSE;
  end;
end; // DisableColumnTitleMenus


end.
