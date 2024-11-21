unit UniGui_Ops;

interface

uses
  System.SysUtils,
  uniGUIClasses, uniGUIForm, uniPanel, uniDBGrid;

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
                            columnRatios : array of Integer); overload;

implementation

uses
  System.TypInfo, System.Classes,
  uniButton, uniBasicGrid;
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
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Force all components that have a DateFormat property to use
//              the given format.
//
//              Optionally also set the Enable property of TUniButtons to give
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

    // If required, treat a button's Enabled state like not ReadOnly.
    if (owner.Controls[n] is TUniButton) then
    begin
      if (handleButtons) then
      begin
        TUniButton(owner.Controls[n]).Enabled := not state;
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
                            columnRatios : array of Integer); overload;
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


end.
