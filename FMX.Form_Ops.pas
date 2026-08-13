unit FMX.Form_Ops;

interface

uses
  System.IniFiles,
{$IFDEF MSWINDOWS}
  System.Win.Registry,
{$ENDIF}
  FMX.Forms;

procedure LoadFormSizePosition(ThisForm : TForm;
                               cifConfig : TCustomIniFile;
                               Section : string); overload
{$IFDEF MSWINDOWS}
procedure LoadFormSizePosition(ThisForm : TForm;
                               cifConfig : TRegIniFile;
                               Section : string); overload;
{$ENDIF}


implementation

const
  INVALID_FORM_DIMENSION = $7FFFFFF;

//***************************************************************************
//
//  FUNCTION  : PlaceForm
//
//  I/P       : thisForm : TForm - The form that is to be sized/positioned
//
//              formLeft : Integer - The left edge of the form.
//                INVALID_FORM_DIMENSION if not specified
//
//              formTop : Integer - The top edge of the form.
//                INVALID_FORM_DIMENSION if not specified
//
//              formWidth : Integer - The width of the form.
//                INVALID_FORM_DIMENSION if not specified
//
//              formHeight : Integer - The height of the form.
//                INVALID_FORM_DIMENSION if not specified
//
//  O/P       : None
//
//  OPERATION : Place and size the form, as requested, on the currently-used monitors
//
//  UPDATED   : 2021-03-09
//
//***************************************************************************
procedure PlaceForm(thisForm : TForm;
                    formLeft : Integer;
                    formTop : Integer;
                    formWidth : Integer;
                    formHeight : Integer;
                    maximiseForm : Boolean = FALSE);
var
  useMonitor : Integer;
  n: Integer;

begin
  useMonitor := -1;

  if ((formLeft = INVALID_FORM_DIMENSION) or
      (formTop = INVALID_FORM_DIMENSION)) then
  begin
    // Use Monitor 0 if the desired form position is not known.
    useMonitor := 0;
  end // if
//  else if ((thisForm.BorderStyle <> bsNone) and
//        (maximiseForm)) then
// 2026-07 I'm not sure why I also checked the Border Style.
// Surely, if the request is to maximise, the Border Style is irrelevant.
  else if (maximiseForm) then
  begin
    // Form must be maximised
    for n := 0 to Screen.DisplayCount-1 do
    begin
      // Top and Left should be the same as the monitor's Top and Left
      // before the form may be deemed to be displayable on that monitor.
      // For some reason, Top and Left are often -8 relative to the top left of
      // the monitor, so I've introduced an Abs difference to try to get past
      // this, until I better understand it.
      if ((Abs(formLeft - Screen.Displays[n].PhysicalBounds.Left) < 20) and
          (Abs(formTop  - Screen.displays[n].PhysicalBounds.Top) < 20)) then
      begin
        useMonitor := n;
        break;
      end; // if
    end; // for
  end // if
  else
  begin
    // Form must be displayed in a normal size
    for n := 0 to Screen.DisplayCount - 1 do
    begin
      // Top and twice the title bar height, as well as
      // Left and the full title width, must be visible on a monitor
      // before the form may be deemed to be displayable on that monitor.
      if ((formLeft >= Screen.Displays[n].PhysicalBounds.Left) and
          (formLeft + thisForm.Canvas.TextWidth(ThisForm.Caption) <=
           Screen.Displays[n].PhysicalBounds.Left + Screen.Displays[n].Bounds.Width) and
          (formTop >= Screen.Displays[n].PhysicalBounds.Top) and
          (formTop + 2 * ((GetSystemMetrics(SM_CYSIZEFRAME) + GetSystemMetrics(SM_CYEDGE) * 2)) <=
           Screen.Displays[n].PhysicalBounds.Top + Screen.Displays[n].Bounds.Height)) then
      begin
        useMonitor := n;
        break;
      end; // if
    end; // for
    // Another way to get the Title Bar Height:
    // Get the screen position of the client area using ClientToScreen with point 0,0.
    // Then subtract that from the window top retrieved through GetWindowRect.
    // Result is the distance from the top of the window to the inside of the window, which is the titlebar height.
  end; // else

  if (useMonitor = -1) then
  begin
    // The form will be placed, as it was originally designed (on Monitor 0)
    Exit;
  end;

  // If a value is missing, use the design value of the form
  if (formLeft = INVALID_FORM_DIMENSION) then
  begin
    formLeft := thisForm.Left;
  end; // if
  if (formTop = INVALID_FORM_DIMENSION) then
  begin
    formTop := thisForm.Top;
  end; // if
  if ((formWidth = INVALID_FORM_DIMENSION) and (not maximiseForm)) then
  begin
    formWidth := thisForm.Width;
  end; // if
  if ((formHeight = INVALID_FORM_DIMENSION) and (not maximiseForm)) then
  begin
    formHeight := thisForm.Height;
  end; // if

//  if ((thisForm.BorderStyle <> bsNone) and
//      (maximiseForm)) then
//!! As above, I don't recal wny BorderStyle is important in this case
  if (maximiseForm) then
  begin
    // Form must be maximised
    // Set left first, to correctly create maximized forms on the applicable monitor
    thisForm.Left := Screen.Displays[useMonitor].Bounds.Left;
    thisForm.Top := Screen.Displays[useMonitor].Bounds.Top;
    thisForm.Height := Screen.Displays[useMonitor].Bounds.Height;
    thisForm.Width := Screen.Displays[useMonitor].Bounds.Width;
    thisForm.WindowState := wsMaximized;
    thisForm.Repaint;
  end // if
  else
  begin
    if (thisForm.BorderStyle <> Single) then
    begin
      thisForm.WindowState := wsNormal;
      thisForm.Width := formWidth;
      thisForm.Height := formHeight;
    end;
    thisForm.Left := formLeft;
    thisForm.Top := formTop;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : LoadFormSizePosition
//
//  I/P       : ThisForm : TForm - The form that is to be sized/positioned
//
//              ifConfig : TCustomIniFile/TRegIniFile - The ini file / registry
//                entry that contains the last-recorded form information.
//
//              Section : String - The name of the registry key for this form.
//
//  O/P       : None
//
//  OPERATION : Sets the WindowState, Left, Top, Height and Width of a form.
//
//              Normally called during OnCreate of the form, so as to maintain
//              any previous user choices. (I had a previous note here that read:
//              "Note : ThisForm is nil if called from within the form's OnCreate event."
//              but THIS DOES NOT SEEM TO BE THE CASE, so it can be called from OnCreate)
//
//              If no previous choices, the form is centred with its designed size.
//
//              This function will ensure that forms are visible, especially
//              if they had previously been positioned on a second monitor, which
//              may have since been disconnected.
//
//              I have not yet tried handling minimised forms.   (Closing a Modal
//              minimized form causes some problems in screen/form handling.)
//
//              Forms should have Position := poDesigned and
//                WindowState := wsNormal
//              if Position := poMainFormCenter, then size is set, but position
//                will be MainFormCenter (which is sometimes useful for neatness).
//
//              Note that the TRegIniFile overload version is probably not used
//              as it is Windows95/NT-specific
//
//  UPDATED   : 2021-03-09
//
//***************************************************************************
procedure LoadFormSizePosition(ThisForm : TForm;
                               cifConfig : TCustomIniFile;
                               Section : string); overload;
begin
  PlaceForm(ThisForm,
            cifConfig.ReadInteger(Section, 'FormLeft', INVALID_FORM_DIMENSION),
            cifConfig.ReadInteger(Section, 'FormTop', INVALID_FORM_DIMENSION),
            cifConfig.ReadInteger(Section, 'FormWidth', INVALID_FORM_DIMENSION),
            cifConfig.ReadInteger(Section, 'FormHeight', INVALID_FORM_DIMENSION),
            cifConfig.ReadString(Section, 'FormSize', '') = 'Max');
end; // LoadFormSizePosition

{$IFDEF MSWINDOWS}
procedure LoadFormSizePosition(ThisForm : TForm;
                               cifConfig : TRegIniFile;
                               Section : string); overload;
begin
  PlaceForm(ThisForm,
            cifConfig.ReadInteger(Section, 'FormLeft', INVALID_FORM_DIMENSION),
            cifConfig.ReadInteger(Section, 'FormTop', INVALID_FORM_DIMENSION),
            cifConfig.ReadInteger(Section, 'FormWidth', INVALID_FORM_DIMENSION),
            cifConfig.ReadInteger(Section, 'FormHeight', INVALID_FORM_DIMENSION),
            cifConfig.ReadString(Section, 'FormSize', '') = 'Max');
end; // LoadFormSizePosition
{$ENDIF}


end.
