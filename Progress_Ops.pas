unit Progress_Ops;

interface

uses
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Controls,
  Vcl.Samples.Gauges,
  System.Win.ComObj, ShlObj;

const
  PP_NEW_INCREMENT = -1;
  PP_NEW_MAXIMUM = -2;
  PP_NO_CHANGE = -3;

type
  TProgressLayout = (PL_NOT_APPLICABLE,
                     PL_LABEL_ABOVE,
                     PL_LABEL_LEFT);

procedure UpdateProgressItem(ProgressIndicator : TControl;
                             theValue : Variant);
procedure SetProgressMinMax(pb : TProgressBar;
                            minPosition : Integer;
                            maxPosition : Integer) overload;
procedure SetProgressMinMax(pb : TGauge;
                            minPosition : Integer;
                            maxPosition : Integer) overload;
procedure SetProgressMinMax(minPosition : Integer;
                            maxPosition : Integer) overload;
procedure SetProgressPosition(pb : TProgressBar;
                              newPosition : Integer) overload;
procedure SetProgressPosition(pb : TGauge;
                              newPosition : Integer) overload;
procedure SetProgressPosition(newPosition : Integer) overload;
procedure SetProgressPosition(percentPosition : Double) overload;
procedure IncrementProgress(pb : TProgressBar;
                            increment : Integer) overload;
procedure IncrementProgress(pb : TGauge;
                            increment : Integer) overload;
procedure IncrementProgress(increment : Integer) overload;
procedure SetProgressControls(fActivity : TForm;
                              plSetting : TProgressLayout;
                              pActivity : TPanel;
                              lActivity : TLabel;
                              pbActivity : TProgressBar) overload;
procedure SetProgressControls(fActivity : TForm;
                              plSetting : TProgressLayout;
                              pActivity : TPanel;
                              lActivity : TLabel;
                              pbActivity : TGauge) overload;
procedure UpdateActivity(sNewActivityMessage : String;
                         iNewPosition : Integer;
                         iProgressIncrement : Integer = 1);
procedure ShowProgress(bVisible : Boolean);
procedure ShowActivity(bVisible : Boolean;
                       sNewActivityMessage : String = '';
                       iProgressMax : Integer = 100;
                       iProgressPosition : Integer = 0);
procedure InitialiseTaskBar;
procedure StartTaskBarProgress(maxValue : UInt64);
procedure UpdateTaskBarProgress(progressValue : UInt64);
procedure IncrementTaskBarProgress(progressIncrement : UInt64 = 1);
procedure StopTaskBarProgress;
function GetProgressBar : TProgressBar;

implementation

uses
  System.Classes, System.Math, System.SysUtils,
  VCL_Ops;

var
  progressForm : TForm = nil;
  progressLayout : TProgressLayout = PL_LABEL_ABOVE;
  progressPanel : TPanel = nil;
  progressLabel : TLabel = nil;
  progressBar : TProgressBar = nil;
  progressGauge : TGauge = nil;

  TaskbarList : ITaskbarList;
  TaskbarList2 : ITaskbarList2;
  TaskbarList3 : ITaskbarList3;
  TaskbarList4 : ITaskbarList4;
  tbProgress : UInt64;
  tbProgressMax : UInt64;


//***************************************************************************
//
//  FUNCTION  : UpdateProgressItem
//
//  I/P       : ProgressIndicator : TControl - A TPanel, TLable or TProgressBar
//
//              theValue : Variant -The new caption/value for the control
//
//  O/P       : None
//
//  OPERATION : Updates the caption of a TPanel or TLabel, or the position of
//              a TProgressBar, as supplied, making sure that it is redrawn and visible.
//
/// UPDATED   : 2018-12-04
//
//***************************************************************************
procedure UpdateProgressItem(ProgressIndicator : TControl;
                             theValue : Variant);
begin
  if (ProgressIndicator <> nil) then
  begin
    if (ProgressIndicator is TPanel) then
    begin
      (ProgressIndicator as TPanel).Caption := String(theValue);
      (ProgressIndicator as TPanel).Visible := TRUE;
      (ProgressIndicator as TPanel).BringToFront;
      (ProgressIndicator as TPanel).Update;
    end // if
    else if (ProgressIndicator is TLabel) then
    begin
      (ProgressIndicator as TLabel).Caption := String(theValue);
      (ProgressIndicator as TLabel).Visible := TRUE;
      (ProgressIndicator as TLabel).BringToFront;
      (ProgressIndicator as TLabel).Update;
    end // if
    else if (ProgressIndicator is TProgressBar) then
    begin
      SetProgressPosition(ProgressIndicator as TProgressBar, Integer(theValue));
      (ProgressIndicator as TProgressBar).Visible := TRUE;
      (ProgressIndicator as TProgressBar).BringToFront;
      (ProgressIndicator as TProgressBar).Update;
    end // if
    else if (ProgressIndicator is TGauge) then
    begin
      SetProgressPosition(ProgressIndicator as TGauge, Integer(theValue));
      (ProgressIndicator as TGauge).Visible := TRUE;
      (ProgressIndicator as TGauge).BringToFront;
      (ProgressIndicator as TGauge).Update;
    end; // if
    (ProgressIndicator as TControl).Invalidate;
  end; // if
end; // UpdateProgressItem

//***************************************************************************
//
//  FUNCTION  : SetProgressMinMax
//
//  I/P       : pb : TProgressBar - A given progress bar. nil to use the
//                progress bar that has been configured in SetProgressControls
//
//              minPosition : Integer } Requiired Min and Max properties of the
//              maxPosition : Integer } indicarted TProgressBar
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2019-12-27
//
//***************************************************************************
procedure SetProgressMinMax(pb : TProgressBar;
                            minPosition : Integer;
                            maxPosition : Integer) overload;
begin
  if (pb = nil) then
  begin
    pb := progressBar;
  end;

  if (pb <> nil) then
  begin
    // Start with a minimum that is "safe" for setting the given maximum
    pb.Min := Min(pb.Min, Min(minPosition, pb.Max));
    pb.Max := maxPosition;
    pb.Min := minPosition;
  end; // if
end; // SetProgressMinMax

procedure SetProgressMinMax(pb : TGauge;
                            minPosition : Integer;
                            maxPosition : Integer) overload;
begin
  if (pb = nil) then
  begin
    pb := progressGauge;
  end;

  if (pb <> nil) then
  begin
    // Start with a minimum that is "safe" for setting the given maximum
    pb.MinValue := Min(pb.MinValue, Min(minPosition, pb.MaxValue));
    pb.MaxValue := maxPosition;
    pb.MinValue := minPosition;
  end; // if
end; // SetProgressMinMax

procedure SetProgressMinMax(minPosition : Integer;
                            maxPosition : Integer) overload;
begin
  if (progressBar <> nil) then
  begin
    SetProgressMinMax(progressBar,
                      minPosition, maxPosition);
  end // if
  else if (progressGauge <> nil) then
  begin
    SetProgressMinMax(progressGauge,
                      minPosition, maxPosition);
  end; // if
end; // SetProgressMinMax

//***************************************************************************
//
//  FUNCTION  : SetProgressPosition
//
//  I/P       : pb : TProgressBar - A given progress bar. nil to use the
//                progress bar that has been configured in SetProgressControls
//
//              newPosition : Integer - The position required.
//
//  O/P       : None
//
//  OPERATION : see
//  http://zarko-gajic.iz.hr/delphi-tprogressbar-not-updating-fast-enough/
//
//  UPDATED   : 2019-08-16
//
//***************************************************************************
procedure SetProgressPosition(pb : TProgressBar;
                              newPosition : Integer) overload;
begin
  if (pb = nil) then
  begin
    pb := progressBar;
  end;

  if (pb <> nil) then
  begin
    pb.Position := newPosition;
    if (newPosition > pb.Min) then
    begin
      pb.Position := newPosition - 1;
      pb.Position := newPosition;
    end; // if
  end; // if
end; // SetProgressPosition

procedure SetProgressPosition(pb : TGauge;
                              newPosition : Integer) overload;
begin
  if (pb = nil) then
  begin
    pb := progressGauge;
  end;

  if (pb <> nil) then
  begin
    pb.Progress := newPosition;
    if (newPosition > pb.MinValue) then
    begin
      pb.Progress := newPosition - 1;
      pb.Progress := newPosition;
    end; // if
  end; // if
end; // SetProgressPosition

procedure SetProgressPosition(newPosition : Integer) overload;
begin
  if (progressBar <> nil) then
  begin
    SetProgressPosition(progressBar, newPosition);
  end // if
  else if (progressGauge <> nil) then
  begin
    SetProgressPosition(progressGauge, newPosition);
  end; // if
end; // SetProgressPosition

procedure SetProgressPosition(percentPosition : Double) overload;
begin
  if (progressBar <> nil) then
  begin
    SetProgressPosition(
      progressBar,
      Trunc(percentPosition * progressBar.Max / 100.0)
    );
  end // if
  else if (progressGauge <> nil) then
  begin
    SetProgressPosition(
      progressGauge,
      Trunc(percentPosition * progressGauge.MaxValue / 100.0)
    );
  end; // if
end; // SetProgressPosition

//***************************************************************************
//
//  FUNCTION  : IncrementProgress
//
//  I/P       : pb : TProgressBar - A given progress bar. nil to use the
//                progress bar that has been configured in SetProgressControls
//
//              newPosition : Integer - The position required.
//
//  O/P       : None
//
//  OPERATION : see
//  http://zarko-gajic.iz.hr/delphi-tprogressbar-not-updating-fast-enough/
//
//  UPDATED   : 2019-08-16
//
//***************************************************************************
procedure IncrementProgress(pb : TProgressBar;
                            increment : Integer) overload;
begin
  if (pb = nil) then
  begin
    pb := progressBar;
  end;

  if (pb <> nil) then
  begin
    pb.Position := pb.Position + increment;
    SetProgressPosition(pb, pb.Position);
  end; // if
end; // IncrementProgressBar

procedure IncrementProgress(pb : TGauge;
                            increment : Integer) overload;
begin
  if (pb = nil) then
  begin
    pb := progressGauge;
  end;

  if (pb <> nil) then
  begin
    pb.Progress := pb.Progress + increment;
    SetProgressPosition(pb, pb.Progress);
  end; // if
end; // IncrementProgress

procedure IncrementProgress(increment : Integer) overload;
begin
  if (progressBar <> nil) then
  begin
    progressBar.Position := progressBar.Position + increment;
    SetProgressPosition(progressBar, progressBar.Position);
  end; // if
end; // IncrementProgressBar

//***************************************************************************
//
//  FUNCTION  : SetProgressControls
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2019-08-16
//
//***************************************************************************
procedure SetProgressControls(fActivity : TForm;
                              plSetting : TProgressLayout;
                              pActivity : TPanel;
                              lActivity : TLabel;
                              pbActivity : TProgressBar) overload;
begin
  progressForm := fActivity;
  progressLayout := plSetting;
  progressPanel := pActivity;
  progressLabel := lActivity;
  progressBar := pbActivity;
  progressGauge := nil;
end;

procedure SetProgressControls(fActivity : TForm;
                              plSetting : TProgressLayout;
                              pActivity : TPanel;
                              lActivity : TLabel;
                              pbActivity : TGauge) overload;
begin
  progressForm := fActivity;
  progressLayout := plSetting;
  progressPanel := pActivity;
  progressLabel := lActivity;
  progressBar := nil;
  progressGauge := pbActivity;
end;

//***************************************************************************
//
//  FUNCTION  : AdjustLabelAndBar
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Adjust sizing of progress bar for a changed left-positioned label.
//
//              Called when the label is positioned to the left of the progress
//              bar and changes to the label text have been made that would
//              require adjustment of the progress bar position and width.
//
//              progressForm, progressLabel and progressBar are tested and
//              assumed to be correctly defined.
//
//  UPDATED   : 2018-09-12
//
//***************************************************************************
procedure AdjustLabelAndBar;
var
  overallWidth : Integer;

begin
  if ((progressForm <> nil) and
      (progressBar <> nil) and
      (progressLabel <> nil)) then
  begin
    if (progressForm.BiDiMode = bdLeftToRight) then
    begin
      overallWidth := (progressBar.Left + progressBar.Width) - progressLabel.Left;
      progressBar.Left := progressLabel.Left + progressLabel.Width + 10;
      progressBar.Width := overallWidth - progressLabel.Width - 10;
    end // if
    else
    begin
      progressLabel.Left := progressPanel.ClientWidth -
                            TGetCanvas(progressPanel).Canvas.TextWidth(progressLabel.Caption) - 10;
      progressBar.Left := 10;
      progressBar.Width := progressLabel.Left - progressBar.Left - 5;
    end;
  end; // if
end; // AdjustLabelAndBar

//***************************************************************************
//
//  FUNCTION  : UpdateActivity
//
//  I/P       : sNewActivityMessage (string) - The message to be shown.
//                If an empty string, no change is made to the current message.
//
//              iNewPosition (integer) - The progress bar position.
//                If PP_NEW_INCREMENT then the progress bar is moved by the increment
//                indicated in iProgressIncrement.
//                If PP_NEW_MAXIMUM then the progress bar is moved to maximum.
//                If PP_NO_CHANGE, then do not change the position.
//
//              iProgressIncrement (integer) - The amount by which the
//                progress bar position should b moved, if iNewPosition is
//                given as PP_NEW_INCREMENT.
//
//  O/P       :
//
//  OPERATION : Set all controls to visible.
//
//  UPDATED   : 2019-05-06
//
//***************************************************************************
procedure UpdateActivity(sNewActivityMessage : String;
                         iNewPosition : Integer;
                         iProgressIncrement : Integer = 1);
begin
  if (progressPanel <> nil) then
  begin
    progressPanel.Visible := TRUE;
  end; // if

  if (progressLabel <> nil) then
  begin
    progressLabel.Visible := TRUE;
    if (sNewActivityMessage <> '') then
    begin

      // This progressBar visible/invisible setting below is not specified.
      // Is it used anywhere?
      if ((iNewPosition <> MAXINT) and
          (iProgressIncrement <> MAXINT)) then
      begin
        progressBar.Visible := TRUE;
      end // if
      else
        progressBar.Visible := FALSE;

      progressLabel.Caption := sNewActivityMessage;
      if (progressLayout = PL_LABEL_LEFT) then
        AdjustLabelAndBar;
      UpdateProgressItem(progressLabel, sNewActivityMessage);

    end; // if
  end; // if

  if (progressBar <> nil) then
  begin
    progressBar.Visible := TRUE;

    if (iNewPosition = PP_NO_CHANGE) then
    begin
      UpdateProgressItem(progressBar, progressBar.Position);
    end // if
    else
    begin
      if (iNewPosition = PP_NEW_MAXIMUM) then
      begin
        UpdateProgressItem(progressBar, progressBar.Max);
      end // if
      else if (iNewPosition <> PP_NEW_INCREMENT) then
      begin
        UpdateProgressItem(progressBar, iNewPosition);
      end // if
      else
      begin
        UpdateProgressItem(progressBar, progressBar.Position + iProgressIncrement);
      end; // else
    end; // if
  end; // if
end; // UpdateActivity

//***************************************************************************
//
//  FUNCTION  : ShowProgress
//
//  I/P       : bVisible : Boolean - TRUE to show, FALSE to hide
//
//  O/P       : None
//
//  OPERATION : Show/hid a predefined TProgressbar.
//
//  UPDATED   : 2023-08-15
//
//***************************************************************************
procedure ShowProgress(bVisible : Boolean);
begin
  if (progressBar <> nil) then
  begin
    progressBar.Visible := bVisible;
    progressBar.Update;
    progressBar.Invalidate;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : ShowActivity
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2020-05-26
//
//***************************************************************************
procedure ShowActivity(bVisible : Boolean;
                       sNewActivityMessage : String = '';
                       iProgressMax : Integer = 100;
                       iProgressPosition : Integer = 0);
begin
  if (bVisible) then
  begin
    if (progressLabel <> nil) then
    begin
      progressLabel.Caption := sNewActivityMessage;
    end; // if
    if (progressLayout = PL_LABEL_LEFT) then
    begin
      AdjustLabelAndBar;
    end;
    if (progressBar <> nil) then
    begin
      progressBar.Max := iProgressMax;
      progressBar.Position := iProgressPosition;
      progressBar.Update;
      progressBar.Invalidate;
    end;
  end; // if

  ShowProgress(bVisible);

  if (progressLabel <> nil) then
  begin
    progressLabel.Visible := bVisible;
  end;

  if (progressPanel <> nil) then
  begin
    progressPanel.Visible := bVisible;
    progressPanel.Update;
    progressPanel.Invalidate;
  end;
end; // ShowActivity

//***************************************************************************
//
//  FUNCTION  : InitialiseTaskBar
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Get the TaskBar operational
//
//              Reference : http://www.drbob42.com/examines/examinC5.htm
//                          https://forums.embarcadero.com/thread.jspa?messageID=905781
//                          https://docs.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-itaskbarlist3-setprogressstate
//                          https://www.delphipower.xyz/handbook_2010/working_with_taskbar_buttons_in_windows.html
//
//  UPDATED   : 2019-11-12
//
//***************************************************************************
procedure InitialiseTaskBar;
begin
  if (CheckWin32Version(6, 1)) then
  begin
    TaskbarList := CreateComObject(CLSID_TaskbarList) as ITaskbarList;
    TaskbarList.HrInit;
    Supports(TaskbarList, IID_ITaskbarList2, TaskbarList2);
    Supports(TaskbarList, IID_ITaskbarList3, TaskbarList3);
    Supports(TaskbarList, IID_ITaskbarList4, TaskbarList4);
  end; // if
end;

//***************************************************************************
//
//  FUNCTION  : StartTaskBarProgress
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//              Reference : http://www.drbob42.com/examines/examinC5.htm
//
//  UPDATED   : 2019-11-12
//
//***************************************************************************
procedure StartTaskBarProgress(maxValue : UInt64);
var
  FormHandle: THandle;

begin
  if not Application.MainFormOnTaskBar then
    FormHandle := Application.Handle
  else
    FormHandle := Application.MainForm.Handle;
  // Set up to show a green progress bar
  if Assigned(TaskbarList3) then
    TaskbarList3.SetProgressState(FormHandle, TBPF_NORMAL);

  tbProgress := 0;
  tbProgressMax := maxValue;

  if Assigned(TaskbarList3) then
    TaskbarList3.SetProgressValue(FormHandle, tbProgress, tbProgressMax);
end; // StartTaskBarProgress

//***************************************************************************
//
//  FUNCTION  : UpdateTaskBarProgress
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//              Reference : http://www.drbob42.com/examines/examinC5.htm
//
//  UPDATED   : 2019-11-12
//
//***************************************************************************
procedure UpdateTaskBarProgress(progressValue : UInt64);
var
  FormHandle: THandle;

begin
  if not Application.MainFormOnTaskBar then
    FormHandle := Application.Handle
  else
    FormHandle := Application.MainForm.Handle;
  // Set up to show a green progress bar
  if Assigned(TaskbarList3) then
    TaskbarList3.SetProgressState(FormHandle, TBPF_NORMAL);

  tbProgress := progressValue;

  if Assigned(TaskbarList3) then
    TaskbarList3.SetProgressValue(FormHandle, tbProgress, tbProgressMax);
end; // UpdateTaskBarProgress

//***************************************************************************
//
//  FUNCTION  : IncrementTaskBarProgress
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//              Reference : http://www.drbob42.com/examines/examinC5.htm
//
//  UPDATED   : 2019-11-12
//
//***************************************************************************
procedure IncrementTaskBarProgress(progressIncrement : UInt64 = 1);
begin
  Inc(tbProgress, progressIncrement);
  UpdateTaskBarProgress(tbProgress);
end; // IncrementTaskBarProgress

//***************************************************************************
//
//  FUNCTION  : StopTaskBarProgress
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//              Reference : http://www.drbob42.com/examines/examinC5.htm
//
//  UPDATED   : 2019-11-12
//
//***************************************************************************
procedure StopTaskBarProgress;
var
  FormHandle: THandle;

begin
  if not Application.MainFormOnTaskBar then
    FormHandle := Application.Handle
  else
    FormHandle := Application.MainForm.Handle;
  if Assigned(TaskbarList3) then
    TaskbarList3.SetProgressState(FormHandle, TBPF_NOPROGRESS);
  tbProgress := 0;
end; // StopTaskBarProgress

//***************************************************************************
//
//  FUNCTION  : GetProgressBar
//
//  I/P       : None
//
//  O/P       : TProgressBar
//
//  OPERATION : Return the "registered" TProgressBar
//
//  UPDATED   : 2023-08-15
//
//***************************************************************************
function GetProgressBar : TProgressBar;
begin
  result := progressBar;
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
  tbProgress := 0;

end.
