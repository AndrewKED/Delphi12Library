unit Form_Ops;

//***************************************************************************
//
// DESCRIPTION:
//  Form-orientated utility routines.
//
//***************************************************************************

interface

uses
  Forms, Menus, WinProcs, StdCtrls, Grids, DBGrids, ComCtrls,
  System.Win.Registry,
  Vcl.Controls, Vcl.Buttons,
  SHDocVw, SysUtils, Graphics, Classes, Vcl.Dialogs, System.IniFiles, SMDBGrid,
  JvSpeedButton;

type
  TRGBColor = record
    Red,
    Green,
    Blue : Byte;
  end;

  THSBColor = record
    Hue,
    Saturnation,
    Brightness : Double;
  end;

  TFormControl = record
    defined : Boolean;      // I wanted to use this to show if value have been set, but without a .Create, the default value is undefined.
    minHeight : Integer;    // } Minimum permissable form ClientHeight and ClientWidth,
    minWidth : Integer;     // } used to avoid a messy display with component overlaps
  end;

procedure SetMinimumFormSizes(var control : TFormControl;
                              minWidth : Integer;
                              minHeight : Integer);
function FormResizable(theForm : TForm;
                       control : TFormControl;
                       newWidth, newHeight : Integer;
                       clip : Boolean = TRUE) : Boolean;
procedure CloseAllChildren(fMain : TForm;
                           bFree : boolean);
procedure SetChildrenWindowState(fMain : TForm;
                                 wsState : TWindowState );
procedure AdjustResolution(fForm:TForm);
procedure WindowShake(wHandle: THandle;
                      shakes : Integer = 500);
procedure EditControlAvailability(cComponent : TObject;
                                  bAvailable : boolean);
function ValidTEditFloat(eEdit : TEdit;
                         bTestMin : boolean;
                         dMinValue : Double;
                         bIncludeMinValue : boolean;
                         bTestMax : boolean;
                         dMaxValue : Double;
                         bIncludeMaxValue : boolean;
                         bFocus : boolean;
                         sMessage : String;
                         mtMessage : TMsgDlgType;
                         iHelp : integer) : boolean;
function ValidTEditInteger(eEdit : TEdit;
                           bTestMin : boolean;
                           iMinValue : Integer;
                           bTestMax : boolean;
                           iMaxValue : Integer;
                           bFocus : boolean;
                           sMessage : String;
                           mtMessage : TMsgDlgType;
                           iHelp : integer) : boolean;
procedure SetFormLocnAndSize(fForm : TForm;
                             iFormLeft,iFormTop : Integer;
                             iFormWidth, iFormHeight : Integer;
                             iDesignPPI : integer);
function FormSizePositionStored(cifConfig : TCustomIniFile;
                                Section : string) : Boolean; overload;
function FormSizePositionStored(rifConfig : TRegIniFile;
                                Section : string) : Boolean; overload;

procedure ClearFormSizePosition(cifConfig : TCustomIniFile;
                                Section : string); overload;
procedure ClearFormSizePosition(cifConfig : TRegIniFile;
                                Section : string); overload;
procedure SaveFormSizePosition(ThisForm : TForm;
                               cifConfig : TCustomIniFile;
                               Section : string); overload
procedure SaveFormSizePosition(ThisForm : TForm;
                               cifConfig : TRegIniFile;
                               Section : string); overload
procedure LoadFormSizePosition(ThisForm : TForm;
                               cifConfig : TCustomIniFile;
                               Section : string); overload
procedure LoadFormSizePosition(ThisForm : TForm;
                               cifConfig : TRegIniFile;
                               Section : string); overload;
procedure DimMainForm;
procedure UndimMainForm;
function TreeViewPath(tvTree : TTreeView;
                      bIncludeRoot : boolean;
                      bIncludeCurrent : boolean;
                      sSeparator : string) : String;
procedure RepaintInParent(Container : TWinControl);
procedure UpdateInParent(Container : TWinControl);
procedure EnabledAsParent(Container: TWinControl);
procedure EnableInParent(Container: TWinControl;
                         state : Boolean);
procedure FlipAsRequired(fForm : TForm);
procedure WebBrowserScreenShot(const wb: TWebBrowser; const fileName: TFileName);
procedure WebBrowserScreen2BMP(const wb: TWebBrowser;
                               bmTarget : TBitmap);
procedure SetTabsVisible(pcGiven : TPageControl;
                         bVisible : boolean);
procedure VerticallyCentre(Target : TControl;
                           Reference : TControl = nil);
procedure HorizontallyCentre(Target : TControl;
                           Reference : TControl = nil);
procedure CentreControl(Target : TControl;
                        Reference : TControl = nil);
procedure SetTEditText(Container: TWinControl;
                       TextToSet : string);
procedure SetSpeedButtonFonts(Sender : TObject;
                              cParent : TWinControl);
procedure SetFormAccessRights(ThisForm : TForm;
                              readOnly : Boolean;
                              bAbort : TButton;
                              bOK : TButton;
                              okReadOnlyCaption : String;
                              okReadOnlyHint : String); overload;
procedure SetFormAccessRights(ThisForm : TForm;
                              readOnly : Boolean;
                              bAbort : TBitBtn;
                              bOK : TBitBtn;
                              okReadOnlyCaption : String;
                              okReadOnlyHint : String); overload;
procedure CloseFromFormActivate(ThisForm : TForm);
function ManageChildModal(parentForm : TCustomForm;
                          childForm : TCustomForm;
                          keepVisible : Boolean = FALSE) : TModalResult;

implementation

uses
  System.UITypes, ActiveX, ExtCtrls, Math, DBCtrls, Mask, Spin,
  WinAPI.Messages, WinAPI.Windows,
  Vcl.Imaging.jpeg,
  hhCheckBox, JvDBDateTimePicker, JvDBSpinEdit, JvCheckBox, JvArrowButton,
{$IFNDEF NO_DKLANG}
  DKLang
{$ENDIF}
  ;

const
  INVALID_FORM_DIMENSION = $7FFFFFF;

var
  fDimmerForm : TForm;
  wcActive : TWinControl;
  fActive : TForm;

//***************************************************************************
//
//  FUNCTION  : SetMinimumFormSizes
//
//  I/P       : var control : TFormControl - The form dimension record being kept.
//
//              minWidth : Integer - Minimum permissable width
//
//              minHeight : Integer - Minimum permissable height
//
//  O/P       : Changes to control
//
//  OPERATION : Set the minimum form dimensions that may be permitted during
//              a resizing, if the FormResizable function, below, is used.
//
//              Note that the minimum sizes should include all static controls.
//
//              (I think calling with ClientWidth, ClientHeight i.e. the design-
//              time sizing, may often be a safe techinique that does away with
//              calculating minimum dimensions based on static control positions
//              and sizes. BUT I have not checked this usage when it comes to
//              the various screen HighDPI values.)
//
//  UPDATED   : 2020-05-22
//
//***************************************************************************
procedure SetMinimumFormSizes(var control : TFormControl;
                              minWidth : Integer;
                              minHeight : Integer);
begin
  control.minWidth := minWidth;
  control.minHeight := minHeight;
  control.defined := TRUE;
end;

//***************************************************************************
//
//  FUNCTION  : FormResizable
//
//  I/P       : theForm : TForm - The form being resized
//
//              control : TFormControl - Contains the previously configured
//                minimum form height and width.
//
//              newWidth, newHeight : Integer - The proposed new form dimensions
//
//              clip : Boolean = TRUE - Results in a fast mouse move setting
//                the width/height to the minimum. (I'm not sure of the conditions
//                under which I might want to use clip as FALSE. It doesn't look
//                or feel good.)
//
//  O/P       : Boolean - TRUE if the form can be resized.
//
//  OPERATION : Check if the proposed form resizing operation can go ahead.
//
//              Normally called from the OnCanResize event of a TForm, the new
//              form size is compared to minimum form dimensions that were
//              configured in SetMinimumFormSizes, above.
//
//  UPDATED   : 2020-05-22
//
//***************************************************************************
function FormResizable(theForm : TForm;
                       control : TFormControl;
                       newWidth, newHeight : Integer;
                       clip : Boolean = TRUE) : Boolean;
var
  borderX : Integer;
  borderY : Integer;

begin
  borderX := theForm.Width - theForm.ClientWidth;
  borderY := theForm.Height - theForm.ClientHeight;

//  if (control.defined) then
//  begin
    result := (((newHeight >= theForm.Height) or
                (newHeight - borderY >= control.minHeight)) and
               ((newWidth >= theForm.Width) or
                (newWidth - borderX >= control.minWidth)));

    if ((clip) and
        (not result)) then
    begin
      if ((newWidth < control.minWidth + borderX )) then
      begin
        theForm.Width := control.minWidth + borderX;
      end;
      if ((newHeight < control.minHeight + borderY)) then
      begin
        theForm.Height := control.minHeight + borderY;
      end;
    end;
//  end // if
//  else
//  begin
//    result := TRUE;
//  end;
end; // FormResizable

//***************************************************************************
//
//  FUNCTION  : RGBToHSB
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : The HSV (Hue, Saturation, Value) model, also called HSB (Hue,
//              Saturation, Brightness), defines a color space commonly used
//              in graphics applications. Hue value ranges from 0 to 360,
//              Saturation and Brightness values range from 0 to 100%.
//
//              Taken from
//              http://delphi.about.com/od/adptips2006/qt/RgbToHsb.htm?nl=1
//
//  UPDATED   : 2006/03/09
//
//***************************************************************************
function RGBToHSB(rgb : TRGBColor) : THSBColor;
var
   minRGB, maxRGB, delta : Double;
   h , s , b : Double ;
begin
   H := 0.0 ;
   minRGB := Min(Min(rgb.Red, rgb.Green), rgb.Blue) ;
   maxRGB := Max(Max(rgb.Red, rgb.Green), rgb.Blue) ;
   delta := ( maxRGB - minRGB ) ;
   b := maxRGB ;
   if (maxRGB <> 0.0) then
     s := 255.0 * Delta / maxRGB
   else
     s := 0.0;
   if (s <> 0.0) then
   begin
     if rgb.Red = maxRGB then
       h := (rgb.Green - rgb.Blue) / Delta
     else
       if rgb.Green = minRGB then
         h := 2.0 + (rgb.Blue - rgb.Red) / Delta
       else
         if rgb.Blue = maxRGB then
           h := 4.0 + (rgb.Red - rgb.Green) / Delta
   end
   else
     h := -1.0;
   h := h * 60 ;
   if h < 0.0 then
     h := h + 360.0;
   with result do
   begin
     Hue := h;
     Saturnation := s * 100 / 255;
     Brightness := b * 100 / 255;
   end;
end; // RGBToHSB

//***************************************************************************
//
//  FUNCTION    :   CloseAllChildren
//
//  I/P         :   fMain (TForm) - The parent MDI form
//
//  O/P         :   None
//
//  OPERATION   :   Closes any child forms that are open in an MDI form
//                  Iterates, so as to handle the eventuality where the
//                  closing of one child form causes another child form
//                  to open (as occurs in TRaXBase when closing a
//                  Modification screen)
//
//  UPDATED     :   2005/04/20
//
//***************************************************************************
procedure CloseAllChildren(fMain : TForm;
                           bFree : boolean);
begin
// Check that the given form is an MDI form
  if (fMain.FormStyle = fsMDIForm) then
  begin
// Close all open forms
    with fMain do
      while (MDIChildCount <> 0) do
      begin
        MDIChildren[MDIChildCount-1].Close;
        if (bFree) then
        begin
          MDIChildren[MDIChildCount-1].Free;
//          MDIChildren[MDIChildCount-1] := nil;
        end; // if
        Application.ProcessMessages;
      end; // while
  end; // if
end; // CloseAllChildren

//***************************************************************************
//
//  FUNCTION    :   SetChildrenWindowState
//
//  I/P         :   fMain (TForm) - The parent MDI form
//
//                      wsState (TWindowState) - The state to which all
//                        child forms must be set
//
//  O/P         :   None
//
//  OPERATION   :   Sets all child forms to a given window state.
//
//  UPDATED     :   2004/05/04
//
//***************************************************************************
procedure SetChildrenWindowState(fMain : TForm;
                                 wsState : TWindowState);
var
  I: Integer;
begin
  with fMain do
    // Must be done backwards through the MDIChildren array
    for I := MDIChildCount - 1 downto 0 do
      MDIChildren[I].WindowState := wsMinimized;
end; // SetChildrenWindowState

//***************************************************************************
//
//  FUNCTION    :   AdjustResolution
//
//  I/P         :   fForm (TForm) - The form to be scaled
//
//  O/P         :   None
//
//  OPERATION   :   This procedure scales all the children on a given
//                      form to conform to the current screen resolution
//
//                      I have not tested it.
//
//  UPDATED     :   2005/04/11
//
//***************************************************************************
procedure AdjustResolution(fForm:TForm);
var
  iPercentage : Integer;
begin
  if (Screen.Width > 640) then
  begin
    iPercentage := Round(((Screen.Width-640)/640)*100)+100;
    fForm.ScaleBy(iPercentage,100);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : WindowShake
//
//  I/P       : wHandle: THandle
//
//              shakes : Integer = 500 - The number of shaking actions.
//
//  O/P       :
//
//  OPERATION : From
//                http://delphi.about.com/od/adptips2005/qt/windowshake.htm
//
//              Usage: WindowShake(Application.MainForm.Handle) ; will shake
//              the main form of your application.
//
//  UPDATED   : 2024-06-13
//
//***************************************************************************
procedure WindowShake(wHandle: THandle;
                      shakes : Integer = 500);
const
   MAXDELTA = 4;

var
   oRect, wRect :TRect;
   deltax : Integer;
   deltay : Integer;
   cnt : Integer;
   dx, dy : Integer;
begin
   // remember original position
   GetWindowRect(wHandle,wRect) ;
   oRect := wRect;

   for cnt := 0 to shakes do
   begin
     deltax := Round(Random(MAXDELTA)) ;
     deltay := Round(Random(MAXDELTA)) ;
     dx := Round(1 + Random(2)) ;
     if dx = 2 then dx := -1;
     dy := Round(1 + Random(2)) ;
     if dy = 2 then dy := -1;
     OffsetRect(wRect,dx * deltax, dy * deltay) ;
     MoveWindow(wHandle, wRect.Left,wRect.Top,wRect.Right - wRect.Left,wRect.Bottom - wRect.Top,true) ;
   end;
   // return to start position
   MoveWindow(wHandle, oRect.Left,oRect.Top,oRect.Right - oRect.Left,oRect.Bottom - oRect.Top,true) ;
end; // WindowShake

//***************************************************************************
//
//  FUNCTION  : EditControlAvailability
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Sets the availability of a control.   I like to make edit
//              controls grey if not available, and not include them in the
//              tab stops.
//
//  UPDATED   : 2009-12-17
//
//***************************************************************************
procedure EditControlAvailability(cComponent : TObject;
                                  bAvailable : boolean);
begin
  if (cComponent is TEdit) then
  begin
    if (bAvailable) then
      TEdit(cComponent).Color := clWindow
    else
      TEdit(cComponent).Color := clBtnFace;
    TEdit(cComponent).TabStop := bAvailable;
    TEdit(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TSpinEdit) then
  begin
    if (bAvailable) then
      TSpinEdit(cComponent).Color := clWindow
    else
      TSpinEdit(cComponent).Color := clBtnFace;
    TSpinEdit(cComponent).TabStop := bAvailable;
    TSpinEdit(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TMaskEdit) then
  begin
    if (bAvailable) then
      TMaskEdit(cComponent).Color := clWindow
    else
      TMaskEdit(cComponent).Color := clBtnFace;
    TMaskEdit(cComponent).TabStop := bAvailable;
    TMaskEdit(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TComboBox) then
  begin
    if (bAvailable) then
      TComboBox(cComponent).Color := clWindow
    else
      TComboBox(cComponent).Color := clBtnFace;
    TComboBox(cComponent).TabStop := bAvailable;
    TComboBox(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TMemo) then
  begin
    if (bAvailable) then
      TMemo(cComponent).Color := clWindow
    else
      TMemo(cComponent).Color := clBtnFace;
    TMemo(cComponent).TabStop := bAvailable;
    TMemo(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TCustomCheckBox) then
  begin
    TCustomCheckBox(cComponent).TabStop := bAvailable;
    TCustomCheckBox(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is ThhCheckbox) then
  begin
    ThhCheckbox(cComponent).TabStop := bAvailable;
    ThhCheckbox(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TJVCheckbox) then
  begin
    TJVCheckbox(cComponent).TabStop := bAvailable;
    TJVCheckbox(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TRadiobutton) then
  begin
    TRadiobutton(cComponent).TabStop := bAvailable;
    TRadiobutton(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TGroupBox) then
  begin
    TGroupBox(cComponent).TabStop := bAvailable;
    TGroupBox(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TPanel) then
  begin
    TPanel(cComponent).TabStop := bAvailable;
    TPanel(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TButton) then
  begin
    TButton(cComponent).TabStop := bAvailable;
    TButton(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TBitBtn) then
  begin
    TBitBtn(cComponent).TabStop := bAvailable;
    TBitBtn(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TTreeView) then
  begin
    TTreeView(cComponent).TabStop := bAvailable;
    TTreeView(cComponent).ReadOnly := not bAvailable;
    TTreeView(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TListBox) then
  begin
    TListBox(cComponent).TabStop := bAvailable;
    TListBox(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TDBEdit) then
  begin
    if (bAvailable) then
      TDBEdit(cComponent).Color := clWindow
    else
      TDBEdit(cComponent).Color := clBtnFace;
    TDBEdit(cComponent).TabStop := bAvailable;
    TDBEdit(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TDBMemo) then
  begin
    if (bAvailable) then
      TDBMemo(cComponent).Color := clWindow
    else
      TDBMemo(cComponent).Color := clBtnFace;
    TDBMemo(cComponent).TabStop := bAvailable;
    TDBMemo(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TDBCheckbox) then
  begin
    TDBCheckbox(cComponent).TabStop := bAvailable;
    TDBCheckbox(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TRadioGroup) then
  begin
    TRadioGroup(cComponent).TabStop := bAvailable;
    TRadioGroup(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TDBRadioGroup) then
  begin
    TDBRadioGroup(cComponent).TabStop := bAvailable;
    TDBRadioGroup(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TDBComboBox) then
  begin
    if (bAvailable) then
      TDBComboBox(cComponent).Color := clWindow
    else
      TDBComboBox(cComponent).Color := clBtnFace;
    TDBComboBox(cComponent).TabStop := bAvailable;
    TDBComboBox(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TDBLookupComboBox) then
  begin
    if (bAvailable) then
      TDBLookupComboBox(cComponent).Color := clWindow
    else
      TDBLookupComboBox(cComponent).Color := clBtnFace;
    TDBLookupComboBox(cComponent).TabStop := bAvailable;
    TDBLookupComboBox(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TDateTimePicker) then
  begin
    if (bAvailable) then
      TDateTimePicker(cComponent).Color := clWindow
    else
      TDateTimePicker(cComponent).Color := clBtnFace;
    TDateTimePicker(cComponent).TabStop := bAvailable;
    TDateTimePicker(cComponent).Enabled := bAvailable;
  end // if

  else
  if (cComponent is TJvDBDateTimePicker) then
  begin
    if (bAvailable) then
      TJvDBDateTimePicker(cComponent).Color := clWindow
    else
      TJvDBDateTimePicker(cComponent).Color := clBtnFace;
    TJvDBDateTimePicker(cComponent).TabStop := bAvailable;
    TJvDBDateTimePicker(cComponent).ReadOnly := not bAvailable;
  end // if

  else
  if (cComponent is TJvDBSpinEdit) then
  begin
    if (bAvailable) then
      TJvDBSpinEdit(cComponent).Color := clWindow
    else
      TJvDBSpinEdit(cComponent).Color := clBtnFace;
    TJvDBSpinEdit(cComponent).TabStop := bAvailable;
    TJvDBSpinEdit(cComponent).ReadOnly := not bAvailable;
  end // if

// I've removed this because sometimes I iterate through all components on
// a form, and set their edit control availability.   Labels, bevels etc get
// passed through here, so it's ,aybe a bit much to expect every component
// type to be handled.
//  else
//    raise Exception.Create('Control not handled for enable/disable');
end; // EditControlAvailability

//***************************************************************************
//
//  FUNCTION  : ValidTEditFloat
//
//  I/P       : eEdit (TEdit) - The edit control whose Text property contains
//                the number.
//
//              bTestMin (boolean) - If the Text property yields a floating
//                point number, it may be tested against a lower limit of
//                dMinValue (below) if this flag is set.
//
//              dMinValue (double) - The lower limit of an acceptable value,
//                if this is being tested.
//
//              bIncludeMinValue (boolean) - If testing the lower limit, this
//                flag is set if the floating point value may include the minimum
//                value.
//
//              bTestMax (boolean) - If the Text property yields a floating
//                point number, it may be tested against an upper limit of
//                dMaxValue (below) if this flag is set.
//
//              dMaxValue (double) - The upper limit of an acceptable value,
//                if this is being tested.
//
//              bIncludeMaxValue (boolean) - If testing the upper limit, this
//                flag is set if the floating point value may include the maximum
//                value.
//
//              bFocus (boolean) - TRUE if the indicated TEdit component is
//                to receive focus if there is an error in the value
//
//              sMessage (string) - The error/warning message to be displayed
//                if the value does not pass the tests.   Setting this to an
//                empty string means that no message dialog will be shown.
//
//              mtMessage (TMsgDlgType) - The type of dialog box to show.
//
//              iHelp (integer) - The help index for the dialog box.   If
//                this is >= 0, a help button will be shown.
//
//  O/P       : (boolean) - TRUE if the value was valid and passed any
//                required range checks.
//
//  OPERATION : This function is used to check whether a TEdit control contains
//              a valid floating point number.
//
//  UPDATED   : 2006/08/22
//
//***************************************************************************
function ValidTEditFloat(eEdit : TEdit;
                         bTestMin : boolean;
                         dMinValue : Double;
                         bIncludeMinValue : boolean;
                         bTestMax : boolean;
                         dMaxValue : Double;
                         bIncludeMaxValue : boolean;
                         bFocus : boolean;
                         sMessage : String;
                         mtMessage : TMsgDlgType;
                         iHelp : integer) : boolean;
var
  dTemp : Double;
begin
  result := TRUE;
  try
    dTemp := StrToFloat(eEdit.Text);
    if (bTestMin) then
      if (((bIncludeMinValue) and (dTemp < dMinValue)) or
          ((not bIncludeMinValue) and (dTemp <= dMinValue))) then
        raise ERangeError.Create('');
    if (bTestMax) then
      if (((bIncludeMaxValue) and (dTemp > dMaxValue)) or
          ((not bIncludeMaxValue) and (dTemp >= dMaxValue))) then
        raise ERangeError.Create('');
  except
    if (bFocus) then
    begin
      // Ensure that we can focus on the edit control.   (Could use CanFocus...)
      if (eEdit.Parent is TTabSheet) then
        TPageControl(TTabSheet(eEdit.Parent).Parent).ActivePage := TTabSheet(eEdit.Parent);
      eEdit.SetFocus;
    end; // if
    if (sMessage <> '') then
    begin
      if (iHelp >= 0) then
        MessageDlg(sMessage,mtMessage,[mbOK,mbHelp],iHelp)
      else
        MessageDlg(sMessage,mtMessage,[mbOK],0);
    end; // if
    result := FALSE;
  end; // except
end; // ValidTEditFloat

//***************************************************************************
//
//  FUNCTION  : ValidTEditInteger
//
//  I/P       : eEdit (TEdit) - The edit control whose Text property contains
//                the number.
//
//              bTestMin (boolean) - If the Text property yields an integer,
//                it may be tested against a lower limit of iMinValue (below)
//                if this flag is set.
//
//              iMinValue (integer) - The minimum permissable value of the
//                given integer, if lower limits are being tested.
//
//              bTestMax (boolean) - If the Text property yields an integer,
//                it may be tested against a upper limit of iMaxValue (below)
//                if this flag is set.
//
//              iMaxValue (integer) - The maximum permissable value of the
//                given integer, if upper limits are being tested.
//
//              bFocus (boolean) - TRUE if the indicated TEdit component is
//                to receive focus if there is an error in the value
//
//              sMessage (string) - The error/warning message to be displayed
//                if the value does not pass the tests.   Setting this to an
//                empty string means that no message dialog will be shown.
//
//              mtMessage (TMsgDlgType) - The type of dialog box to show.
//
//              iHelp (integer) - The help index for the dialog box.   If
//                this is >= 0, a help button will be shown.
//
//  O/P       : (boolean) - TRUE if the value was valid and passed any
//                required range checks.
//
//  OPERATION : This function is used to check whether a TEdit control contains
//              a valid integer.
//
//  UPDATED   : 2006/08/22
//
//***************************************************************************
function ValidTEditInteger(eEdit : TEdit;
                           bTestMin : boolean;
                           iMinValue : Integer;
                           bTestMax : boolean;
                           iMaxValue : Integer;
                           bFocus : boolean;
                           sMessage : String;
                           mtMessage : TMsgDlgType;
                           iHelp : integer) : boolean;
var
  iTemp : Integer;
begin
  result := TRUE;
  try
    iTemp := StrToInt(eEdit.Text);
    if ((bTestMin) and
        (iTemp < iMinValue)) then
        raise ERangeError.Create('');
    if ((bTestMax) and
        (iTemp > iMaxValue)) then
        raise ERangeError.Create('');
  except
    // Ensure that we can focus on the edit control.   (Could use CanFocus...)
    if (bFocus) then
    begin
      if (eEdit.Parent is TTabSheet) then
        TPageControl(TTabSheet(eEdit.Parent).Parent).ActivePage := TTabSheet(eEdit.Parent);
      eEdit.SetFocus;
    end; // if
    if (sMessage <> '') then
    begin
      if (iHelp >= 0) then
        MessageDlg(sMessage,mtMessage,[mbOK,mbHelp],iHelp)
      else
        MessageDlg(sMessage,mtMessage,[mbOK],0);
    end; // if
    result := FALSE;
  end; // except
end; // ValidTEditInteger

//***************************************************************************
//
//  FUNCTION  : SetFormLocnAndSize
//
//  I/P       : iDesignPPI (integer) - The screen resolution under which the
//                form was designed.   The help on TCustomForm.PixelsPerInch
//                implies that the figure is saved with the form at designtime,
//
//  O/P       :
//
//  OPERATION : Used to set a form to a particular size, especially when
//              the BorderStyle is fsSizeable and the Position is poDefault.
//
//              If found that poDefault will set the size to something that
//              is sometimes too small (in the Drill128 example that I tested)
//
//              If you want the form to be sizeable, then when it is run, it
//              should at least show all the components, and not be partly
//              off the screen.   This function helps to achieve that.
//
//  UPDATED   : 2007/02/15
//
//***************************************************************************
procedure SetFormLocnAndSize(fForm : TForm;
                             iFormLeft,iFormTop : Integer;
                             iFormWidth, iFormHeight : Integer;
                             iDesignPPI : integer);
begin
  with fForm do
  begin
    Left := iFormLeft;
    Top := iFormTop;
    ClientWidth := (iFormWidth * PixelsPerInch) div iDesignPPI;
    ClientHeight := (iFormHeight * PixelsPerInch) div iDesignPPI;
    ClientWidth := (iFormWidth * PixelsPerInch) div iDesignPPI;
  end; // with
end; // SetFormLocnAndSize

//***************************************************************************
//
//  FUNCTION  : FormSizePositionStored
//
//  I/P       : ifConfig : TCustomIniFile/TRegIniFile - The IniFile that would
//                be expeced to contain the last-recorded form information.
//
//              Section : String - The name of the registry key for this form.
//
//  O/P       : Boolean - TRUE if this form size and position has been stored
//
//  OPERATION : Check whether this form size and position has ever been stored.
//
//              Note that the TRegIniFile overload version is probably not used
//              as it is Windows95/NT-specific
//
//  UPDATED   : 2019-07-30
//
//***************************************************************************
function FormSizePositionStored(cifConfig : TCustomIniFile;
                                Section : string) : Boolean; overload;
begin
  result := cifConfig.SectionExists(Section);
end; // FormSizePositionStored
function FormSizePositionStored(rifConfig : TRegIniFile;
                                Section : string) : Boolean; overload;
begin
  result := rifConfig.KeyExists(Section);
end; // FormSizePositionStored

//***************************************************************************
//
//  FUNCTION  : ClearFormSizePosition
//
//  I/P       : cifConfig : TCustomIniFile/TRegIniFile - The ini file/registry
//                entry that will contains the form information.
//
//              Section : String - The name of the registry key for this form.
//
//  O/P       : None
//
//  OPERATION : Clears any record of form size/postion under this section name.
//
//              Note that the TRegIniFile overload version is probably not used
//              as it is Windows95/NT-specific
//
//  UPDATED   : 2019-11-20
//
//***************************************************************************
procedure ClearFormSizePosition(cifConfig : TCustomIniFile;
                                Section : string);
begin
  cifConfig.EraseSection(Section);
end; // ClearFormSizePosition

procedure ClearFormSizePosition(cifConfig : TRegIniFile;
                                Section : string); overload;
begin
  cifConfig.EraseSection(Section);
end; // ClearFormSizePosition

//***************************************************************************
//
//  FUNCTION  : SaveFormSizePosition
//
//  I/P       : ThisForm : TForm - The form whose size/position is to be saved
//
//              cifConfig : TCustomIniFile/TRegIniFile - The ini file / registry
//                entry that will contains the form information.
//
//              Section : String - The name of the registry key for this form.
//
//  O/P       : None
//
//  OPERATION : Stores the current WindowState, Left, Top, Height and Width of
//              a form.
//
//              Normally called during OnClose of the form, to maintain a
//              user's choices.
//
//              Note that the TRegIniFile overload version is probably not used
//              as it is Windows95/NT-specific
//
//  UPDATED   : 2021-03-09
//
//***************************************************************************
procedure SaveFormSizePosition(ThisForm : TForm;
                               cifConfig : TCustomIniFile;
                               Section : string); overload;
begin
  if (ThisForm.WindowState = wsMaximized) then
  begin
    // The form is Maximized
    cifConfig.WriteString(Section, 'FormSize', 'Max');
    cifConfig.WriteInteger(Section, 'FormTop', ThisForm.Top);
    cifConfig.WriteInteger(Section, 'FormLeft', ThisForm.Left);
    cifConfig.DeleteKey(Section, 'FormWidth');
    cifConfig.DeleteKey(Section, 'FormHeight');
  end // if
  else
  begin
    // The form in Normal or Minimized
    cifConfig.WriteString(Section, 'FormSize', 'Normal');
    cifConfig.WriteInteger(Section, 'FormTop', ThisForm.Top);
    cifConfig.WriteInteger(Section, 'FormLeft', ThisForm.Left);
    cifConfig.WriteInteger(Section, 'FormWidth', ThisForm.Width);
    cifConfig.WriteInteger(Section, 'FormHeight', ThisForm.Height);
  end; // else
end; // SaveFormSizePosition

procedure SaveFormSizePosition(ThisForm : TForm;
                               cifConfig : TRegIniFile;
                               Section : string); overload;
begin
  if (ThisForm.WindowState = wsMaximized) then
  begin
    // The form is Maximized
    cifConfig.WriteString(Section, 'FormSize', 'Max');
    cifConfig.WriteInteger(Section, 'FormTop', ThisForm.Top);
    cifConfig.WriteInteger(Section, 'FormLeft', ThisForm.Left);
    cifConfig.DeleteKey(Section, 'FormWidth');
    cifConfig.DeleteKey(Section, 'FormHeight');
  end // if
  else
  begin
    // The form in Normal or Minimized
    cifConfig.WriteString(Section, 'FormSize', 'Normal');
    cifConfig.WriteInteger(Section, 'FormTop', ThisForm.Top);
    cifConfig.WriteInteger(Section, 'FormLeft', ThisForm.Left);
    cifConfig.WriteInteger(Section, 'FormWidth', ThisForm.Width);
    cifConfig.WriteInteger(Section, 'FormHeight', ThisForm.Height);
  end; // else
end; // SaveFormSizePosition

//***************************************************************************
//
//  FUNCTION  : FormSizePositionAvailable
//
//  I/P       : ifConfig : TCustomIniFile - The registry entry that would be
//                expeced to contain the last-recorded form information.
//
//              Section : String - The name of the registry key for this form.
//
//  O/P       : Boolean - TRUE if this form size and position has been stored
//
//  OPERATION : Check whether this form size and position has ever been stored.
//
//  UPDATED   : 2019-07-30
//
//***************************************************************************
function FormSizePositionAvailable(cifConfig : TCustomIniFile;
                                   Section : string) : Boolean;
begin
  result := cifConfig.SectionExists(Section);
end; // FormSizePositionAvailable

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
  else if ((thisForm.BorderStyle <> bsNone) and
        (maximiseForm)) then
  begin
    // Form must be maximised
    for n := 0 to Screen.MonitorCount-1 do
    begin
      // Top and Left should be the same as the monitor's Top and Left
      // before the form may be deemed to be displayable on that monitor.
      // For some reason, Top and Left are often -8 relative to the top left of
      // the monitor, so I've introduced an Abs difference to try to get past
      // this, until I better understand it.
      if ((Abs(formLeft - Screen.Monitors[n].Left) < 20) and
          (Abs(formTop  - Screen.Monitors[n].Top) < 20)) then
      begin
        useMonitor := n;
        break;
      end; // if
    end; // for
  end // if
  else
  begin
    // Form must be displayed in a normal size
    for n := 0 to Screen.MonitorCount-1 do
    begin
      // Top and twice the title bar height, as well as
      // Left and the full title width, must be visible on a monitor
      // before the form may be deemed to be displayable on that monitor.
      if ((formLeft >= Screen.Monitors[n].Left) and
          (formLeft + thisForm.Canvas.TextWidth(ThisForm.Caption) <=
           Screen.Monitors[n].Left + Screen.Monitors[n].Width) and
          (formTop >= Screen.Monitors[n].Top) and
          (formTop + 2 * ((GetSystemMetrics(SM_CYSIZEFRAME) + GetSystemMetrics(SM_CYEDGE) * 2)) <=
           Screen.Monitors[n].Top + Screen.Monitors[n].Height)) then
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
  if (formWidth = INVALID_FORM_DIMENSION) then
  begin
    formWidth := thisForm.Width;
  end; // if
  if (formHeight = INVALID_FORM_DIMENSION) then
  begin
    formHeight := thisForm.Height;
  end; // if

  if ((thisForm.BorderStyle <> bsNone) and
      (maximiseForm)) then
  begin
    // Form must be maximised
    // Set left first, to correctly create maximized forms on the applicable monitor
    thisForm.Left := Screen.Monitors[useMonitor].Left;
    thisForm.Top := Screen.Monitors[useMonitor].Top;
    thisForm.Height := Screen.Monitors[useMonitor].Height;
    thisForm.Width := Screen.Monitors[useMonitor].Width;
    thisForm.WindowState := wsMaximized;
    thisForm.Repaint;
  end // if
  else
  begin
    if (thisForm.BorderStyle <> bsDialog) then
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

//***************************************************************************
//
//  FUNCTION  : DimMainForm
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : This function can be called immediately before opening a
//              Modal dialog box, to dim the main (background) form.   In
//              Delphi 2008, this can be hooked to an TApplicationEvents
//              component's OnModalBegin event.
//
//              See http://delphi.about.com/od/delphitips2008/qt/form_dimmer.htm
//
//  UPDATED   : 2008-05-26
//
//***************************************************************************
procedure DimMainForm;
begin
  wcActive := Screen.ActiveControl;
  fActive := Screen.ActiveForm;
//  I am not happy with this at present (2010-05-13) because on the Undimming,
//  the previously active control  is not restored.
//  I need to work out a way to do this.
(*
  with fDimmerForm do
  begin
    Left := Application.MainForm.Left;
    Top := Application.MainForm.Top;
    Width := Application.MainForm.Width;
    Height := Application.MainForm.Height;
    Show;
  end; // with
*)
end; // DimMainForm

//***************************************************************************
//
//  FUNCTION  : UndimMainForm
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : This function can be called immediately after closing a
//              Modal dialog box, to undim the main (background) form (which
//              has been dimmed using the above code).   In Delphi 2008, this
//              can be hooked to an TApplicationEvents component's OnModalEnd event.
//
//              See http://delphi.about.com/od/delphitips2008/qt/form_dimmer.htm
//
//  UPDATED   : 2008-05-26
//
//***************************************************************************
procedure UndimMainForm;
begin

//  See above for the reason I am disabling this.
(*
  fDimmerForm.Hide;

  fActive.Show;
  fActive.ActiveControl := wcActive;
*)
end; // UndimMainForm

//***************************************************************************
//
//  FUNCTION  : TreeViewPath
//
//  I/P       : tvTree (TTreeView) - The tree view for which the path is required
//
//              bIncludeRoot (boolean) - TRUE to include the name of the root node
//
//              bIncludeCurrent (boolean) - TRUE to include the name of the root node
//
//              sSeaprator (string) - The string to place between node names in the path
//
//  O/P       : (string) - A string of the path from the selected node to the root.
//
//  OPERATION : Creates the full "path" of the currently selected node, with an
//              optional inclusion of the root node name at the front.
//
//  UPDATED   : 2009-12-17
//
//***************************************************************************
function TreeViewPath(tvTree : TTreeView;
                      bIncludeRoot : boolean;
                      bIncludeCurrent : boolean;
                      sSeparator : string) : String;
var
  tnParent : TTreeNode;

begin
  result := '';

  if (tvTree.Selected.Parent <> nil) then
  begin
    if (bIncludeCurrent) then
      result := tvTree.Selected.Text;
    tnParent := tvTree.Selected.Parent;
    while (tnParent.Parent <> nil) do
    begin
      result := tnParent.Text + sSeparator + result;
      tnParent := tnParent.Parent;
    end;

    result := sSeparator + result;
    if (bIncludeRoot) then
      result := tnParent.Text + result;

  end // if
  else
    if ((bIncludeRoot) and
        (bIncludeCurrent)) then
      result := tvTree.Selected.Text;
end; // TreeViewPath

//***************************************************************************
//
//  FUNCTION  : RepaintInParent
//
//  I/P       : Container: TWinControl - The parent
//
//  O/P       :
//
//  OPERATION : Updates all controls within a parent control
//
//              See EnabledAsParent.
//
//  UPDATED   : 2020-10-24
//
//***************************************************************************
procedure RepaintInParent(Container : TWinControl);
var
  index : Integer;
  aControl : TControl;
  isContainer : boolean;

begin
  for index := 0 to Container.ControlCount-1 do
  begin
    aControl := Container.Controls[index];

    aControl.Repaint;

    isContainer := (csAcceptsControls in Container.Controls[index].ControlStyle);

    if ((isContainer) AND (aControl is TWinControl)) then
    begin
      // Recursive for child controls
      RepaintInParent(TWinControl(Container.Controls[index]));
    end;
  end;
end; // RepaintInParent

//***************************************************************************
//
//  FUNCTION  : UpdateInParent
//
//  I/P       : Container: TWinControl - The parent
//
//  O/P       :
//
//  OPERATION : Updates all controls within a parent control
//
//              See EnabledAsParent.
//
//  UPDATED   : 2020-10-24
//
//***************************************************************************
procedure UpdateInParent(Container : TWinControl);
var
  index : Integer;
  aControl : TControl;
  isContainer : boolean;

begin
  for index := 0 to Container.ControlCount-1 do
  begin
    aControl := Container.Controls[index];

    aControl.Update;

    isContainer := (csAcceptsControls in Container.Controls[index].ControlStyle);

    if ((isContainer) AND (aControl is TWinControl)) then
    begin
      // Recursive for child controls
      UpdateInParent(TWinControl(Container.Controls[index]));
    end;
  end;
end; // UpdateInParent

//***************************************************************************
//
//  FUNCTION  : EnabledAsParent
//
//  I/P       : Container: TWinControl - The parent
//
//  O/P       :
//
//  OPERATION : Taken from Delphi About
//              http://delphi.about.com/od/vclusing/a/parent_enabled.htm
//
//  UPDATED   : 2010-02-25
//
//***************************************************************************
procedure EnabledAsParent(Container: TWinControl) ;
var
  index : Integer;
  aControl : TControl;
  isContainer : boolean;

begin
  for index := 0 to Container.ControlCount-1 do
  begin
    aControl := Container.Controls[index];

    aControl.Enabled := Container.Enabled;

    isContainer := (csAcceptsControls in Container.Controls[index].ControlStyle);

    if ((isContainer) AND (aControl is TWinControl)) then
    begin
      // Recursive for child controls
      EnabledAsParent(TWinControl(Container.Controls[index]));
    end;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : EnabledInParent
//
//  I/P       : Container: TWinControl - The parent
//
//              state : Boolean - The state to which the controls must be set
//
//  O/P       :
//
//  OPERATION : Modified from above
//
//  UPDATED   : 2017-07-21
//
//***************************************************************************
procedure EnableInParent(Container: TWinControl;
                         state : Boolean);
var
  index : Integer;
  aControl : TControl;
  isContainer : boolean;

begin
  for index := 0 to Container.ControlCount-1 do
  begin
    aControl := Container.Controls[index];

    aControl.Enabled := state;

    isContainer := (csAcceptsControls in Container.Controls[index].ControlStyle);

    if ((isContainer) AND (aControl is TWinControl)) then
    begin
      // Recursive for child controls
      EnableInParent(TWinControl(Container.Controls[index]),state);
    end;
  end;
end; // EnableInParent

//***************************************************************************
//
//  FUNCTION   : FlipAsRequired
//
//  I/P        :
//
//  O/P        :
//
//  OPERATION  : Flips the given form's components, as may be required for
//               locale language direction.
//
//  UPDATED    : 2011-02-22
//
//***************************************************************************
procedure FlipAsRequired(fForm : TForm);
const
  // A list of right-to-left languages that will grow as I encounter more of them
  LM_ARABIC_KSA = 1025;

begin
{$IFNDEF NO_DKLANG}
  if ((fForm <> nil) and
      (((LangManager.LanguageID = LM_ARABIC_KSA) and
        (not (fForm.BiDiMode = bdRightToLeft))) or
       ((LangManager.LanguageID <> LM_ARABIC_KSA) and
        (fForm.BiDiMode = bdRightToLeft)))) then
  begin
    fForm.FlipChildren(TRUE);
    if (LangManager.LanguageID = LM_ARABIC_KSA) then
      fForm.BiDiMode := bdRightToLeft
    else
      fForm.BiDiMode := bdLeftToRight;

    // If this form is has an owner, flip that form too
    if ((fForm.Owner <> nil) and
        (fForm.Owner is TForm)) then
      FlipAsRequired(fForm.Owner as TForm);

    // In some cases, flipping may need to call the resize event, because I adjust the position
    // of various components
    if (Assigned(fForm.OnResize)) then
      fForm.OnResize(nil);
  end; // if
{$ENDIF}
end;

//***************************************************************************
//
//  FUNCTION  : WebBrowserScreenShot
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From http://delphi.about.com/od/vclusing/a/wb_scren_shot.htm
//
//  UPDATED   : 2012-09-11
//
//***************************************************************************
procedure WebBrowserScreenShot(const wb: TWebBrowser; const fileName: TFileName) ;
var
  viewObject : IViewObject;
  r : TRect;
  bitmap : TBitmap;

begin
  if (wb.Document <> nil) then
  begin
    wb.Document.QueryInterface(IViewObject, viewObject) ;
    if Assigned(viewObject) then
    try
      bitmap := TBitmap.Create;
      try
        r := Rect(0, 0, wb.Width, wb.Height) ;

        bitmap.Height := wb.Height;
        bitmap.Width := wb.Width;

        viewObject.Draw(DVASPECT_CONTENT, 1, nil, nil, Application.Handle, bitmap.Canvas.Handle, @r, nil, nil, 0) ;

        with TJPEGImage.Create do
        try
          Assign(bitmap);
          SaveToFile(fileName);
        finally
          Free;
        end; // finally
      finally
        bitmap.Free;
      end; // finally
    finally
      viewObject._Release;
    end; // finally
  end; // if
 end; // WebBrowserScreenShot

//***************************************************************************
//
//  FUNCTION  : WebBrowserScreen2BMP
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From http://delphi.about.com/od/vclusing/a/wb_scren_shot.htm
//
//  UPDATED   : 2012-09-11
//
//***************************************************************************
procedure WebBrowserScreen2BMP(const wb: TWebBrowser;
                               bmTarget : TBitmap);
var
  viewObject : IViewObject;
  r : TRect;

begin
  if wb.Document <> nil then
  begin
    wb.Document.QueryInterface(IViewObject, viewObject);
    if Assigned(viewObject) then
    try
      r := Rect(0, 0, wb.Width, wb.Height);

      bmTarget.Height := wb.Height;
      bmTarget.Width := wb.Width;

      viewObject.Draw(DVASPECT_CONTENT, 1, nil, nil, Application.Handle, bmTarget.Canvas.Handle, @r, nil, nil, 0) ;
    finally
      viewObject._Release;
    end;
  end;
end; // WebBrowserScreen2BMP

//***************************************************************************
//
//  FUNCTION  : SetTabsVisible
//
//  I/P       : pcGiven : TPageControl - The TPageControl for which the visibility
//                of its tabs must be set.
//
//              bVisible : Boolean - The state to which all tabsheets visibility
//                should be set.
//
//  O/P       : None
//
//  OPERATION : Sets or resets the visibility of all TTabsheets in a given
//              TPageControl
//
//  UPDATED   : 2014-02-10
//
//***************************************************************************
procedure SetTabsVisible(pcGiven : TPageControl;
                         bVisible : boolean);
var
  n : Integer;

begin
  for n := 0 to pcGiven.PageCount-1 do
    pcGiven.Pages[n].TabVisible := bVisible;
end;

//***************************************************************************
//
//  FUNCTION  : VerticallyCentre
//
//  I/P       : Target : TControl - the control to be positioned
//
//              Reference : TControl = nil - The reference control. If nil,
//                this is treated as the parent of Target
//
//  O/P       : None
//
//  OPERATION : Used to position one control (Target) to vertically
//              centre on another (Reference)
//
//  UPDATED   : 2024-09-05
//
//***************************************************************************
procedure VerticallyCentre(Target : TControl;
                           Reference : TControl = nil);
begin
  if (Reference = nil) then
  begin
    Reference := Target.Parent;
  end;

  if (Reference <> nil) then
  begin
    if (Target.Parent = Reference) then
    begin
      // The target is an immediate child of the reference.
      // Its top position is therefore relative.
      Target.Top := (Reference.ClientHeight - Target.Height) div 2;
    end // if
    else
    begin
      // The target is not a child of the reference
      // Its left position is therefor offset in the same way as the reference.
      Target.Top := Reference.Top + (Reference.ClientHeight - Target.Height) div 2;
    end; // else
  end;
end; // VerticallyCentre

//***************************************************************************
//
//  FUNCTION  : HorizontallyCentre
//
//  I/P       : Target : TControl - the control to be positioned
//
//              Reference : TControl = nil - The reference control. If nil,
//                this is treated as the parent of Target
//
//  O/P       : None
//
//  OPERATION : Used to position one control (Target) to horizontally
//              centre on another (Reference);
//
//  UPDATED   : 2024-09-05
//
//***************************************************************************
procedure HorizontallyCentre(Target : TControl;
                             Reference : TControl = nil);
begin
  if (Reference = nil) then
  begin
    Reference := Target.Parent;
  end;

  if (Reference <> nil) then
  begin
    if (Target.Parent = Reference) then
    begin
      // The target is an immediate child of the reference.
      // Its left position is therefore relative.
      Target.Left := (Reference.ClientWidth - Target.Width) div 2;
    end // if
    else
    begin
      // The target is not a child of the reference
      // Its left position is therefor offset in the same way as the reference.
      Target.Left := Reference.Left + (Reference.ClientWidth - Target.Width) div 2;
    end;
  end;
end; // HorizontallyCentre

//***************************************************************************
//
//  FUNCTION  : CentreControl
//
//  I/P       : Target : TControl - the control to be positioned
//
//              Reference : TControl = nil - The reference control. If nil,
//                this is treated as the parent of Target
//
//  O/P       : None
//
//  OPERATION : Used to position one control (Target) to horizontally and
//              vertically centre on another (Reference);
//
//  UPDATED   : 2024-09-05
//
//***************************************************************************
procedure CentreControl(Target : TControl;
                        Reference : TControl = nil);
begin
  HorizontallyCentre(Target, Reference);
  VerticallyCentre(Target, Reference);
end;

//***************************************************************************
//
//  FUNCTION  : SetTEditText
//
//  I/P       : Container: TWinControl - Container control holding the TEdit controls
//
//              TextToSet : String - The text to place in all TEdit controls
//
//  O/P       : None
//
//  OPERATION : Sets the .Text property of all TEdit controls within the given
//              TWinControl to the given value.
//
//  UPDATED   : 2015-08-19
//
//***************************************************************************
procedure SetTEditText(Container: TWinControl;
                       TextToSet : string);
var
  index : Integer;
  aControl : TControl;
  isContainer : boolean;

begin
  for index := 0 to Container.ControlCount-1 do
  begin
    aControl := Container.Controls[index];

    if (aControl is TEdit) then
     (aControl as TEdit).Text := TextToSet;

    isContainer := (csAcceptsControls in Container.Controls[index].ControlStyle);

    if ((isContainer) and (aControl is TWinControl)) then
    begin
      // Recursive for child controls
      EnabledAsParent(TWinControl(Container.Controls[index])) ;
    end;
  end; // for
end; // SetTEditText

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
//  OPERATION : In a set of TSpeedButtons that share the same GroupIndex property,
//              highlight the given one by setting its font to Bold and Underlined.
//
//  UPDATED   : 2024-06-28
//
//***************************************************************************
procedure SetSpeedButtonFonts(Sender : TObject;
                              cParent : TWinControl);
var
  n : Integer;

begin
  if ((Sender is TSpeedButton) and
      (cParent <> nil)) then
  begin
    for n := 0 to cParent.ComponentCount-1 do
      if (cParent.Components[n] is TSpeedButton) then
        if (((cParent.Components[n] as TSpeedButton).GroupIndex <> 0) and
            ((cParent.Components[n] as TSpeedButton).GroupIndex = (Sender as TSpeedButton).GroupIndex)) then
          (cParent.Components[n] as TSpeedButton).Font.Style :=
            (cParent.Components[n] as TSpeedButton).Font.Style - [fsBold] - [fsUnderline];
    // Now set the button's own font to bold and underlined
    (Sender as TSpeedButton).Font.Style := (Sender as TSpeedButton).Font.Style + [fsBold] + [fsUnderline];
  end; // if

  if ((Sender is TJvSpeedButton) and
      (cParent <> nil)) then
  begin
    for n := 0 to cParent.ComponentCount-1 do
      if (cParent.Components[n] is TJvSpeedButton) then
        if (((cParent.Components[n] as TJvSpeedButton).GroupIndex <> 0) and
            ((cParent.Components[n] as TJvSpeedButton).GroupIndex = (Sender as TJvSpeedButton).GroupIndex)) then
          (cParent.Components[n] as TJvSpeedButton).Font.Style :=
            (cParent.Components[n] as TJvSpeedButton).Font.Style - [fsBold] - [fsUnderline];
    // Now set the button's own font to bold and underlined
    (Sender as TJvSpeedButton).Font.Style := (Sender as TJvSpeedButton).Font.Style + [fsBold] + [fsUnderline];
  end; // if

  if ((Sender is TJvArrowButton) and
      (cParent <> nil)) then
  begin
    for n := 0 to cParent.ComponentCount-1 do
      if (cParent.Components[n] is TJvArrowButton) then
        if (((cParent.Components[n] as TJvArrowButton).GroupIndex <> 0) and
            ((cParent.Components[n] as TJvArrowButton).GroupIndex = (Sender as TJvArrowButton).GroupIndex)) then
          (cParent.Components[n] as TJvArrowButton).Font.Style :=
            (cParent.Components[n] as TJvArrowButton).Font.Style - [fsBold] - [fsUnderline];
    // Now set the button's own font to bold and underlined
    (Sender as TJvArrowButton).Font.Style := (Sender as TJvArrowButton).Font.Style + [fsBold] + [fsUnderline];
  end; // if
end; // SetSpeedButtonFonts

//***************************************************************************
//
//  FUNCTION  : SetFormAccessRights
//
//  I/P       : ThisForm : TForm - The form being limited
//
//              readOnly : Boolean - TRUE to make the form read-only
//
//              bAbort : TButton / TBitBtn - Target abort button
//              bAccept : TButton / TBitBtn - Target OK/Accpet button
//              okReadOnlyCaption : String
//              okReadOnlyHint : String
//
//  O/P       : None
//
//  OPERATION : Typically used on edit dialogs to cause the form to have an
//              edit-able and ReadOnly format, by changing the Caption and
//              altering the use/display of the typical Abort and Accept/OK
//              button-pair.
//
//  UPDATED   : 2020-01-29
//
//***************************************************************************
procedure SetFormAccessRights(ThisForm : TForm;
                              readOnly : Boolean;
                              bAbort : TButton;
                              bOK : TButton;
                              okReadOnlyCaption : String;
                              okReadOnlyHint : String); overload;
begin
  if (readOnly) then
  begin
{$IFNDEF NO_DKLANG}
    ThisForm.Caption := ThisForm.Caption + ' [' +
                        LangManager.ConstantValue['sReadOnly'] +
                        ']';
{$ELSE}
    ThisForm.Caption := ThisForm.Caption + ' [Read only]';
{$ENDIF}
    if (bAbort <> nil) then
    begin
      bAbort.Visible := FALSE;
    end; // if
    if (bOK <> nil) then
    begin
      bOK.Cancel := TRUE;
      bOK.Hint := okReadOnlyHint;
      bOK.Caption := okReadOnlyCaption;
    end; // if
  end; // if
end; // SetFormAccessRights

procedure SetFormAccessRights(ThisForm : TForm;
                              readOnly : Boolean;
                              bAbort : TBitBtn;
                              bOK : TBitBtn;
                              okReadOnlyCaption : String;
                              okReadOnlyHint : String); overload;
begin
  if (readOnly) then
  begin
{$IFNDEF NO_DKLANG}
    ThisForm.Caption := ThisForm.Caption + ' [' +
                        LangManager.ConstantValue['sReadOnly'] +
                        ']';
{$ELSE}
    ThisForm.Caption := ThisForm.Caption + ' [Read only]';
{$ENDIF}
    if (bAbort <> nil) then
    begin
      bAbort.Visible := FALSE;
    end; // if
    if (bOK <> nil) then
    begin
      bOK.Cancel := TRUE;
      bOK.Hint := okReadOnlyHint;
      bOK.Caption := okReadOnlyCaption;
    end; // if
  end; // if
end; // SetFormAccessRights

//***************************************************************************
//
//  FUNCTION  : CloseFromFormActivate
//
//  I/P       : ThisForm : TForm - The form to be closed
//
//  O/P       : None
//
//  OPERATION : Close the form.
//              This is the way to do it, when closing from FormActivate.
//
//  UPDATED   : 2020-02-20
//
//***************************************************************************
procedure CloseFromFormActivate(ThisForm : TForm);
begin
  PostMessage(ThisForm.Handle, WM_CLOSE, 0, 0);
end; // CloseFromFormActivate

//***************************************************************************
//
//  FUNCTION  : ManageChildModal
//
//  I/P       : parentForm : TCustomForm - The form which is launching the
//                child modal form. (May be nil)
//
//              childForm : TFTCustomFormorm - The child modal form to be
//                launched.
//
//              keepVisible : Boolean = FALSE - Indicates whether the parent
//                form should be restored (made visible) or closed on closing
//                the child form.
//
//  O/P       : TModalResult - The Modal Result of the child form.
//
//  OPERATION : Manage launching and closing of a child Modal form from a
//              parent (modal) form.
//
//              Hide the parent modal form while the child form has control.
//
//              If the child form aborts, restore the parent form. For all other
//              child closure types, close the parent too. This may be overridden.
//
//  UPDATED   : 2021-07-25
//
//***************************************************************************
function ManageChildModal(parentForm : TCustomForm;
                          childForm : TCustomForm;
                          keepVisible : Boolean = FALSE) : TModalResult;
begin
  if (parentForm <> nil) then
  begin
    parentForm.Visible := FALSE;
  end;

  result := childForm.ShowModal;

  if (parentForm <> nil) then
  begin
    if ((keepVisible) or
        (childForm.ModalResult = mrAbort)) then
    begin
      parentForm.Visible := TRUE;
    end // if
    else
    begin
      parentForm.Close;
    end;
  end; // if
end; // ManageChildModal

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
  // Set a "dimmer form" used to dim the application when a Modal Dialog box
  // is opened.
  fDimmerForm := TForm.Create(nil);
  fDimmerForm.AlphaBlend := TRUE;
  fDimmerForm.AlphaBlendValue := 128;
  fDimmerForm.BorderStyle := bsNone;

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
finalization
  fDimmerForm.Free;

end.
