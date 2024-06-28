unit Chart_Ops;

// http://www.teechart.net/docs/teechart/vclfmx/tutorials/UserGuide/html/manu45id.htm
// http://www.teechart.net/docs/teechart/vclfmx/lib/
// http://www.teechart.net/docs/teechart/vclfmx/lib/html/TChartShape.html

interface

uses
  VclTee.TeEngine;

procedure SetChartAxisLnLin(aChartAxis : TChartAxis;
                            invertLnAxis : Boolean = FALSE;
                            label125 : Boolean = FALSE);
procedure SetAxisMinMax(theAxis : TChartAxis;
                        minimum : Double;
                        maximum : Double);
procedure SetAxisMinMaxIncrement(theAxis : TChartAxis;
                                 minimum : Double;
                                 maximum : Double;
                                 incrementStep : Double);

implementation

uses
  System.SysUtils, System.Math, System.Types;

//***************************************************************************
//
//  FUNCTION  : SetChartAxisLnLin
//
//  I/P       : aChartAxis : TChartAxis - The TChart axis to be set.
//
//              invertLnAxis : Boolean = FALSE - TRUE to invert a logarithmic axis
//
//              label125 : Boolean = FALSE
//
//  O/P       : None
//
//  OPERATION : The axis is set up for linear or logarithmic display, based
//              on the already-set .Logarithmic property.
//
//              For logarithmic axis, add 10 labels in each decade, with
//              a suitable number of decimal places in the label value text.
//
//  UPDATED   : 2022-05-31
//
//***************************************************************************
procedure SetChartAxisLnLin(aChartAxis : TChartAxis;
                            invertLnAxis : Boolean = FALSE;
                            label125 : Boolean = FALSE);
var
  decimals : Integer;
  mark : Double;
  interval : Double;

begin
  aChartAxis.Items.Clear;

  aChartAxis.MinorTicks.Visible := not aChartAxis.Logarithmic;
  aChartAxis.Inverted := aChartAxis.Logarithmic and invertLnAxis;

  if (aChartAxis.Logarithmic) then
  begin
    // Set marks at suitable logarithmic positions
    mark := SimpleRoundTo(aChartAxis.Minimum, Trunc(Log10(aChartAxis.Minimum)));
    interval := Power(10, Trunc(Log10(mark)));
    while (mark < aChartAxis.Maximum) do
    begin
      decimals := Max(0, -Trunc(Log10(mark)));
      if ((not label125) or
          (CompareValue(mark / interval, 2.0, 0.01) = EqualsValue) or
          (CompareValue(mark / interval, 5.0, 0.01) = EqualsValue) or
          (CompareValue(mark / interval, 10.0, 0.01) = EqualsValue)) then
      begin
        // Label the 10 points within each decade, or only on the 1, 2 and 5,
        // as requested
        aChartAxis.Items.Add(mark, Format('%.*f',[decimals, mark]));
      end // if
      else
      begin
        // Add a grid line, without label
        aChartAxis.Items.Add(mark, '');
      end;
      interval := Power(10, Trunc(Log10(mark)));
      mark := mark + interval;
    end;
  end // if
  else
  begin
    aChartAxis.Items.Automatic := TRUE;
  end;
end; // SetChartAxisLnLin

//***************************************************************************
//
//  FUNCTION  : SetAxisMinMax
//
//  I/P       : theAxis : TChartAxis - The axis for which minimum and maximum
//                are to be set.
//
//              minimum : Double - The required new minimum value of the axis
//
//              maximum : Double - The required new maximum value of the axis
//
//  O/P       : None
//
//  OPERATION : Set the required minimum and maximum values on the given axis.
//
//              Used only when both theAxis.AutomaticMinimum and
//              theAxis.AutomaticMaximum are FALSE.
//
//              The steps in this function are necessary to ensure that at no
//              time is the axis minimum more than the axis maximum.
//
//  UPDATED   : 2020-04-17
//
//***************************************************************************
procedure SetAxisMinMax(theAxis : TChartAxis;
                        minimum : Double;
                        maximum : Double);
begin
  if (minimum >= theAxis.Maximum) then
  begin
    theAxis.Maximum := maximum;
    theAxis.Minimum := minimum;
  end // if
  else
  begin
    theAxis.Minimum := minimum;
    theAxis.Maximum := maximum;
  end; // else
end;

//***************************************************************************
//
//  FUNCTION  : SetAxisMinMaxIncrement
//
//  I/P       : theAxis : TChartAxis - The axis for which minimum and maximum
//                are to be set.
//
//              minimum : Double - The minimum value that should appear on
//                the axis
//
//              maximum : Double - The maximum value that should appear on
//                the axis
//
//              incrementStep : Double - The increment to buffer min and max
//                values by
//
//  O/P       : None
//
//  OPERATION : Set the minimum and maximum values on the given axis, with the
//              min and max values confined to a given step/increment size.
//
//              Used only when both theAxis.AutomaticMinimum and
//              theAxis.AutomaticMaximum are FALSE.
//
//  UPDATED   : 2021-05-03
//
//***************************************************************************
procedure SetAxisMinMaxIncrement(theAxis : TChartAxis;
                                 minimum : Double;
                                 maximum : Double;
                                 incrementStep : Double);
var
  newMin : Double;
  newMax : Double;

begin
  newMin := Floor(minimum / incrementStep) * incrementStep;
  newMax := Ceil(maximum / incrementStep) * incrementStep;

  SetAxisMinMax(theAxis, newMin, newMax);
end;

end.
