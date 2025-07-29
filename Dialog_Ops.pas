unit Dialog_Ops;

interface

uses
  Vcl.Forms, Vcl.Dialogs, Graphics;

function MessageDlg(const Msg: string;
                    DlgType: TMsgDlgType;
                    Buttons: TMsgDlgButtons;
                    HelpCtx: Longint;
                    WordWrap: Boolean = TRUE): Integer; overload;
function MessageDlg(const Msg: string;
                    DlgType: TMsgDlgType;
                    Buttons: TMsgDlgButtons;
                    HelpCtx: Longint;
                    DefaultButton: TMsgDlgBtn;
                    WordWrap: Boolean = TRUE): Integer; overload;
function MyMessageDlg(const Msg: String;
                      DlgTypt: TmsgDlgType;
                      button: TMsgDlgButtons;
                      Caption: array of String;
                      dlgCaption: String): Integer;
procedure SODialogTypeChange(sod : TOpenDialog);
function GetSOFileTypeExt(sod : TOpenDialog) : String;

implementation

uses
  Windows,
  System.Classes, System.UITypes, System.Math, System.SysUtils, System.StrUtils,
  System.Types,
  Vcl.StdCtrls,
  Str_Ops;

//***************************************************************************
//
//  FUNCTION  : MessageDlg
//
//  I/P       : const Msg: string;
//              DlgType: TMsgDlgType;
//              Buttons: TMsgDlgButtons;
//              HelpCtx: Longint;
//              DefaultButton: TMsgDlgBtn;
//              WordWrap: Boolean - Defaults to TRUE. Set to FALSE to use the
//                older dialog style, which does not wrap long lines. Note that
//                this changes the style/layout of the dialog box.
//
//  O/P       :
//
//  OPERATION : Temporarily ensures that the default cursor is displayed
//              when using the MessageDlg.
//
//              To use this function, ensure that it is fully qualified when
//              it is called i.e. "Dialog_Ops.MessageDlg"
//
//  UPDATED   : 2020-03-15
//
//***************************************************************************
function MessageDlg(const Msg: string;
                    DlgType: TMsgDlgType;
                    Buttons: TMsgDlgButtons;
                    HelpCtx: Longint;
                    WordWrap: Boolean = TRUE): Integer; overload;
var
  cursorCurrent : TCursor;

begin
  // Setting this to TRUE will prevent wrapping of longer lines
  UseLatestCommonDialogs := WordWrap;

  cursorCurrent := Screen.Cursor;
  Screen.Cursor := crDefault;
  result := Vcl.Dialogs.MessageDlg(Msg, DlgType, Buttons, HelpCtx);
  Screen.cursor := cursorCurrent;

  // Restore!
  UseLatestCommonDialogs := TRUE;
end;

function MessageDlg(const Msg: string;
                    DlgType: TMsgDlgType;
                    Buttons: TMsgDlgButtons;
                    HelpCtx: Longint;
                    DefaultButton: TMsgDlgBtn;
                    WordWrap: Boolean = TRUE): Integer; overload;
var
  cursorCurrent : TCursor;

begin
  // Setting this to TRUE will prevent wrapping of longer lines
  UseLatestCommonDialogs := WordWrap;

  cursorCurrent := Screen.Cursor;
  Screen.Cursor := crDefault;
  result := Vcl.Dialogs.MessageDlg(Msg, DlgType, Buttons, HelpCtx, DefaultButton);
  Screen.cursor := cursorCurrent;

  // Restore!
  UseLatestCommonDialogs := TRUE;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From https://stackoverflow.com/questions/5417843/generic-dialog-with-custom-captions-for-buttons
//
//              Permits very long captions in buttons
//
//  UPDATED   :
//
//***************************************************************************
function MyMessageDlg(const Msg: String;
                      DlgTypt: TmsgDlgType;
                      button: TMsgDlgButtons;
                      Caption: array of String;
                      dlgCaption: String): Integer;
var
  aMsgdlg: TForm;
  i: Integer;
  Dlgbutton: TButton;
  Captionindex: Integer;
  widthButtons : Integer;
  countButtons : Integer;
  leftBPos : Integer;

begin
  aMsgdlg := CreateMessageDialog(Msg, DlgTypt, button);
  aMsgdlg.Caption := dlgCaption;
  aMsgdlg.BiDiMode := bdLeftToRight;

  // If AParent is provided (in the parameters) as the parent form, the following
  // code was advised in
  // https://forum.lazarus.freepascal.org/index.php?topic=36586.0
  // to permit wide message dialogs
  aMsgdlg.Position := poScreenCenter;
  aMsgdlg.FormStyle := fsStayOnTop;

  widthButtons := 0;
  countbuttons := 0;
  Captionindex := 0;
  for i := 0 to aMsgdlg.Componentcount - 1 do
  begin
    if (aMsgdlg.Components[i] is TButton) then
    begin
      Dlgbutton := TButton(aMsgdlg.Components[i]);
      if Captionindex <= High(Caption) then
      begin
        Dlgbutton.Caption := Caption[Captionindex];
        Dlgbutton.Width := Max(Dlgbutton.Width,
                               aMsgdlg.Canvas.TextWidth(Dlgbutton.Caption) +
                               Dlgbutton.Margins.Left + Dlgbutton.Margins.Right);
        Inc(widthButtons, DlgButton.Width);
        Inc(countButtons);
      end;
      Inc(Captionindex);
    end;
  end;
  // Ensure that the form is wide enough to fit the buttons. Use the form's Margins.Left
  // value as the minimum spacing on the left and for the spacing between the buttons.
  aMsgdlg.ClientWidth := Max(aMsgdlg.ClientWidth,
                             widthButtons +
                             aMsgdlg.Margins.Left * countButtons +
                             aMsgdlg.Margins.Right);
  // Ensure that the buttons are centred between the form's Margins.Left and Margins.Right
  leftBPos := aMsgdlg.Margins.Left +
              (aMsgdlg.ClientWidth - widthButtons - (countButtons-1)*aMsgdlg.Margins.Left - aMsgdlg.Margins.Right) div 2;
  for i := 0 to aMsgdlg.Componentcount - 1 do
  begin
    if (aMsgdlg.Components[i] is TButton) then
    begin
      TButton(aMsgdlg.Components[i]).Left := leftBPos;
      Inc(leftBPos, TButton(aMsgdlg.Components[i]).Width + aMsgdlg.Margins.Left);
    end; // for
  end; // for

  result := aMsgdlg.ShowModal;
end;

//***************************************************************************
//
//  FUNCTION  : GetSOFileTypeExt
//
//  I/P       : sod : TSaveDialog or TOpenDialog
//
//  O/P       : String - The currently selected filter extension (or the first
//                if the filter has multiple extensions.
//
//  OPERATION : Get the extension that is currently selected in a TSaveDialog/
//              TOpenDialog fil
//
//  UPDATED   : 2025-07-29
//
//***************************************************************************
function GetSOFileTypeExt(sod : TOpenDialog) : String;
var
  filterElements : TStringDynArray;
  filters : TStringDynArray;

begin
  Result := sod.DefaultExt;

  if (sod.Filter = '') then
  begin
    Exit;
  end; // if

  filterElements := SplitString(sod.Filter, '|');
  if ((sod.FilterIndex * 2 - 1 <= High(filterElements)) and
      (filterElements[sod.FilterIndex * 2 - 1] <> '.*')) then
  begin
    // Extract the currently specified filter, and handle multiple extensions
    filters := SplitString(filterElements[sod.FilterIndex * 2 - 1], ';');
    if (Length(filters) > 0) then
    begin
      // Filters exist
      // Remove the '.'
      Result := Front_Trimmed(filters[0], '*.');
    end; // if
  end; // if
end; // GetSOFileTypeExt

//***************************************************************************
//
//  FUNCTION  : SODialogTypeChange
//
//  I/P       : sod : TSaveDialog or TOpenDialog
//
//  O/P       : None
//
//  OPERATION : Change the .DefaultExt of a TOpenDialog/TSaveDialog to match the
//              extension that is currently indicated by .FilterIndex
//
//              Note that any extension on an existing entered file name
//              may/will(?)will then be altered.
//
//              https://docwiki.embarcadero.com/Libraries/Sydney/en/Vcl.Dialogs.TOpenDialog.Filter
//
//  UPDATED   : 2025-07-29
//
//***************************************************************************
procedure SODialogTypeChange(sod : TOpenDialog);
begin
  sod.DefaultExt := GetSOFileTypeExt(sod);
end; // SODialogTypeChange

end.
