unit Report_Ops;

interface

uses
  Vcl.StdCtrls;

type
  TReportState = (
    ST_REP_UNKNOWN,
    ST_REP_COMPLETE_CONFIG,
    ST_REP_MAY_CREATE,
    ST_REP_MAY_PRINT
  );

procedure RegisterReportControls(createButton : TCustomButton;
                                 previewButton : TCustomButton;
                                 printButton : TCustomButton;
                                 var state : TReportState);
procedure SetReportButtons(state : TReportState);


implementation

var
  FCreate : TCustomButton;
  FPreview : TCustomButton;
  FPrint : TCustomButton;


//***************************************************************************
//
//  FUNCTION  : RegisterReportControls
//
//  I/P       : createButton : TCustomButton
//
//              previewButton : TCustomButton
//
//              printButton : TCustomButton
//
//  O/P       : var state : TReportState - Set to ST_REP_UNKNOWN;
//
//  OPERATION : Store references to the buttons to be controlled.
//
//              The initial (unknown i.e. disabled) button state is set.
//
//  UPDATED   : 2023-10-13
//
//***************************************************************************
procedure RegisterReportControls(createButton : TCustomButton;
                                 previewButton : TCustomButton;
                                 printButton : TCustomButton;
                                 var state : TReportState);
begin
  FCreate := createButton;
  FPreview := previewButton;
  FPrint := printButton;
  state := ST_REP_UNKNOWN;
  SetReportButtons(state);
end; // RegisterReportControls

//***************************************************************************
//
//  FUNCTION  : SetReportButtons
//
//  I/P       : state : TReportState
//
//  O/P       :
//
//  OPERATION : Set the availability of the registered buttons, according to
//              the given state of the report.
//
//  UPDATED   : 2023-10-13
//
//***************************************************************************
procedure SetReportButtons(state : TReportState);
var
  c : Boolean;
  pp : Boolean;
  pr : Boolean;

begin
  c := FALSE;
  pp := FALSE;
  pr := FALSE;

  case state of
    ST_REP_MAY_CREATE :
    begin
      c := TRUE;
    end; // option

    ST_REP_MAY_PRINT :
    begin
      pp := TRUE;
      pr := TRUE;
    end;
  end;

  if (FCreate <> nil) then
  begin
    FCreate.Enabled := c;
  end; // if
  if (FPreview <> nil) then
  begin
    FPreview.Enabled := pp;
  end; // if
  if (FPrint <> nil) then
  begin
    FPrint.Enabled := pr;
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
  FCreate := nil;
  FPreview := nil;
  FPrint := nil;

end.
