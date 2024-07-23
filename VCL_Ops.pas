unit VCL_Ops;

interface

uses
  VCL.StdCtrls, Vcl.Controls, Vcl.ComCtrls, Vcl.Graphics;

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

implementation

uses
  System.SysUtils,
  WinAPI.Messages, WinAPI.Windows;

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

end.
