UNIT MakeGraf;

//*****************************************************************************
//
//  Used to aid the graphing of 2D functions.
//
//  The last modification was made on :
//
//    Update Date : 2007/07/18
//    Changes Made :
//      * Correct the date display on X-axis to more accurately show the user's
//        date format choice.
//
//*****************************************************************************

INTERFACE

uses
  Graphics, System.Types;

const
  max_graphs = 5;
  gdt_Weekly = 1;             // Graph date ticks on

type
  graph_type = RECORD
               graph_area : TRect;
               x_ratio,y_ratio : Extended;
               graph_x_min     : Real;
               graph_x_max     : Real;
               graph_y_min     : Real;
               graph_y_max     : Real;
               defined         : Boolean;
               end;

var
  grphs : ARRAY [1..max_graphs] OF graph_type;

procedure Graph_Frame(index          : Integer;
                      x1,y1,x2,y2    : Integer;
                      x_min,x_max    : Real;
                      y_min,y_max    : Real;
                      width          : Byte;
                      frame_colour   : TColor;
                      background_colour : TColor;
                      cnv            : TCanvas);

procedure Axis_Ticks(index           : Integer;
                     x_small,x_large : Real;
                     x_unit          : Real;
                     x_dec           : Byte;
                     x_ticks         : Boolean;
                     x_values        : Boolean;
                     bXBottom        : Boolean;
                     y_small,y_large : Real;
                     y_unit          : Real;
                     y_dec           : Byte;
                     y_ticks         : Boolean;
                     y_values        : Boolean;
                     bYLeft          : Boolean;
                     small_length    : Integer;
                     width           : Byte;
                     text_colour     : TColor;
                     background_colour : TColor;
                     cnv             : TCanvas);

procedure Graph_XDate_Ticks(index           : Integer;
                            small_length    : Integer;
                            width           : Byte;
                            text_colour     : TColor;
                            background_colour : TColor;
                            cnv             : TCanvas);

procedure X_Tick_Text(index           : Integer;
                      x_val           : Real;
                      x_str           : String;
                      small_length    : Integer;
                      text_colour     : TColor;
                      background_colour : TColor;
                      cnv             : TCanvas;
                      bottomAxis      : Boolean = TRUE);
procedure Y_Tick_Text(index           : Integer;
                     y_val           : Real;
                     y_str           : String;
                     small_length    : Integer;
                     text_colour     : TColor;
                     background_colour : TColor;
                     cnv             : TCanvas;
                     leftAxis        : Boolean = TRUE);

procedure Graph_Titles(index     : Integer;
                       x_title   : String;
                       x_title_y : Integer;
                       y_title   : String;
                       y_title_x : Integer;
                       text_colour     : TColor;
                       background_colour : TColor;
                       cnv             : TCanvas);

procedure Grid(index      : Integer;
               x_space    : Real;
               y_space    : Real;
               size       : Byte;
               dot_colour : TColor;
               cnv        : TCanvas);

procedure Graph_Pixel(index  : Integer;
                      x1,y1  : Real;
                      colour : Byte;
                      cnv    : TCanvas);

procedure Graph_Line(index       : Integer;
                     x1,y1,x2,y2 : Real;
                     width       : Byte;
                     line_colour : TColor;
                     cnv        : TCanvas);

procedure Graph_Rect(index       : Integer;
                     x1,y1       : Real;
                     x2,y2       : Real;
                     fill_colour : TColor;
                     brush_style : TBrushStyle;
                     cnv         : TCanvas);

procedure Graph_FillRect(index       : Integer;
                         x1,y1       : Real;
                         x2,y2       : Real;
                         cFillColour : TColor;
                         cnv         : TCanvas);

procedure Graph_Circle(index       : Integer;
                        cx,cy       : Real;
                        r           : Real;
                        fill_colour : TColor;
                        brush_style : TBrushStyle;
                        cnv         : TCanvas);

function Pixel_To_X(index : Integer;
                    x     : real) : Real;

function Pixel_To_Y(index : Integer;
                    y     : real) : Real;
function Y_To_Pixel(index : Integer;
                    y     : Double) : Integer;

procedure Crop_Line_To_Graph(index : Integer;
                             var rLX,rLY,rRX,rRY : real);

implementation

uses
  WinAPI.Windows, System.DateUtils, Classes, TimeDate, SysUtils, Maths,
  Canvas_Ops;

var
  r : Integer;

//*****************************************************************************
//
//  DESCRIPTION
//
//  This procedure will calculate and store certain parameters pertaining to
//  the positioning and scaling of a graph on the screen.   It will also draw
//  the border of the graph in a given colour.   This procedure should be
//  called before any of the following graphing procedures may be used.
//
//  Note that axis ticks, labels and titles are placed outside this rectangle.
//
//  PARAMETERS
//
//  index (Integer) : The index number given to this graph.
//  x1 (INTEGER) : The x-coordinate of the left side of the graph frame.
//  y1 (INTEGER) : The y-coordinate of the top side of the graph frame.
//  x2 (INTEGER) : The x-coordinate of the right side of the graph frame.
//  y2 (INTEGER) : The y-coordinate of the bottom of the graph frame.
//  x_min (real) : The minimum (left) graphed value of x.
//  x_max (real) : The maximum (right) graphed value of x.
//  y_min (real) : The minimum (bottom) graphed value of y.
//  y_max (real) : The maximum (top) graphed value of y.
//  width (byte) : Width of the border line
//  frame_colour (TColor) : The colour of the frame
//  background_colour (TColor) : The colour of the background
//  cnv (TCanvas) : The canvas on which this is all drawn
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  12 June 1998
//
//*****************************************************************************
procedure Graph_Frame(index          : Integer;
                      x1,y1,x2,y2    : Integer;
                      x_min,x_max    : Real;
                      y_min,y_max    : Real;
                      width          : Byte;
                      frame_colour   : TColor;
                      background_colour : TColor;
                      cnv            : TCanvas);
begin
  grphs[index].graph_area.left := x1;
  grphs[index].graph_area.right := x2;
  grphs[index].graph_area.top := y1;
  grphs[index].graph_area.bottom := y2;
  grphs[index].x_ratio := (x_max - x_min) / (1.0 * (x2 - x1));
  grphs[index].y_ratio := (y_max - y_min) / (1.0 * (y2 - y1));
  grphs[index].graph_x_min := x_min;
  grphs[index].graph_y_min := y_min;
  grphs[index].graph_x_max := x_max;
  grphs[index].graph_y_max := y_max;
  grphs[index].defined := true;

  cnv.Brush.Color := background_colour;
  cnv.FillRect(grphs[index].graph_area);
  cnv.Pen.Color := frame_colour;
  cnv.Pen.Width := width;
  cnv.Pen.Style := psSolid;
    // Rectangle seems to be one pixels short at the bottom and right
  cnv.Rectangle(grphs[index].graph_area.left, grphs[index].graph_area.top,
                grphs[index].graph_area.right+1, grphs[index].graph_area.bottom+1);
end; // Graph_Frame

//*****************************************************************************
//
//  DESCRIPTION
//
//  This procedure will print large and small ticks on the x-axis (bottom) and
//  y-axis (left) of the selected graph.   Large ticks will have the values
//  printed with them.   The x-axis values are printed vertically below the
//  ticks, and the y-axis values are printed horizontally to the left of the
//  ticks.   The values printed may be scaled separately for each axis ie if
//  the scale factor for the x-axis is 1000.0, then all values will be in
//  thousands.   The number of decimal points in the printed values may also
//  be set for each axis.   The colour of the ticks and values may be
//  supplied, and is the same for both axis.
//
//  PARAMETERS
//
//  index (Integer) : The index number of the selected graph.
//  x_small (real) : The graph value spacing between x-axis small ticks.
//  x_large (real) : The graph value spacing between x-axis large ticks.
//  x_unit (real) : The units value (scale) which should be applied to the
//                  x-axis values.
//  x_dec (byte) : Number of decimal places to be displayed in the x values.
//  x_ticks (boolean) : TRUE if x-ticks are to be drawn.
//  x_values (boolean) : TRUE if x-values are to be filled in.
//  bXBottom (boolean) : TRUE if X-ticks must be on bottom of graph
//  y_small (real) : The graph value spacing between y-axis small ticks.
//  y_large (real) : The graph value spacing between y-axis large ticks.
//  y_unit (real) : The units value (scale) which should be applied to the
//                  y-axis values.
//  y_dec (byte) : Number of decimal places to be displayed in the y values.
//  y_ticks (boolean) : TRUE if y-ticks are to be drawn.
//  y_values (boolean) : TRUE if y-values are to be filled in.
//  bYLeft (boolean) : TRUE if y-ticks must be on the left of the graph
//  small_length (INTEGER) : The length of the small ticks
//  width (byte) : Width of the tick line
//  text_colour (TColor) : The colour of the ticks and printed values.
//  background_colour (TColor) : The colour behind the text
//  cnv (TCanvas) : The canvas on which this is all drawn
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  12 June 1998
//
//*****************************************************************************
procedure Axis_Ticks (index           : Integer;
                      x_small,x_large : Real;
                      x_unit          : Real;
                      x_dec           : Byte;
                      x_ticks         : Boolean;
                      x_values        : Boolean;
                      bXBottom        : Boolean;
                      y_small,y_large : Real;
                      y_unit          : Real;
                      y_dec           : Byte;
                      y_ticks         : Boolean;
                      y_values        : Boolean;
                      bYLeft          : Boolean;
                      small_length    : Integer;
                      width           : Byte;
                      text_colour     : TColor;
                      background_colour : TColor;
                      cnv             : TCanvas);
var
  n,m,p : Integer;
  xp,yp : Integer;
  st    : String;

begin

  with grphs[index] DO
  begin

    if defined then
    begin

      cnv.Brush.Color := background_colour;
      cnv.Pen.Color := text_colour;
      cnv.Pen.Width := width;

      // X-axis ticks and values
      n := Trunc ((graph_x_max - graph_x_min) / x_small) + 1;

      if (graph_x_max - graph_x_min) < x_large then
        m := 1
      else
        m := Round (x_large / x_small);

      for p := 0 to n - 1 do
      begin

        if (x_ratio<>0) then
          xp := graph_area.left + Round ((x_small * p) / x_ratio)
        else
          xp := graph_area.left;
        if (bXBottom) then
          yp := graph_area.bottom
        else
          yp := graph_area.top;

        // Check if this is a major tick
        if (p MOD m = 0) then
        begin
          st := Format('%.*f',[x_dec, (x_small * p + graph_x_min) / x_unit]);
          cnv.MoveTo (xp,yp);
          if (x_ticks) then
          begin
            if (bXBottom) then
              cnv.LineTo (xp,yp + small_length*2)
            else
              cnv.LineTo (xp,yp - small_length*2)
          end; // if
          if (x_values) then
          begin
            if (bXBottom) then
              cnv.TextOut (xp - cnv.TextWidth(st)DIV 2,
                           yp + small_length*2 + Round(0.2*cnv.TextHeight(st)),
                           st)
            else
              cnv.TextOut (xp - cnv.TextWidth(st)DIV 2,
                           yp - small_length*2 - Round(1.2*cnv.TextHeight(st)),
                           st)
          end; // if
        end // if
        else
        begin
          if (x_ticks) then
          begin
            cnv.MoveTo (xp,yp);
            if (bXBottom) then
              cnv.LineTo (xp,yp + small_length)
            else
              cnv.LineTo (xp,yp - small_length);
          end; // if
        end; //else

      end; // for

// Y-axis ticks and values
      n := Trunc ((graph_y_max - graph_y_min) / y_small) + 1;

      if (graph_y_max - graph_y_min) < y_large then
         m := 1
      else
         m := Round (y_large / y_small);

      for p := 0 to n - 1 do
      begin

        if (y_ratio<>0) then
          yp := graph_area.bottom - Round ((y_small * p) / y_ratio)
        else
          yp := graph_area.bottom;
        if (bYLeft) then
          xp := graph_area.left
        else
          xp := graph_area.right;

// Check if this is a major tick
        if (p MOD m = 0) then
        begin
          st := Format('%.*f',[y_dec, (y_small * p + graph_y_min) / y_unit]);
          cnv.MoveTo (xp,yp);
          if (y_ticks) then
          begin
            if (bYLeft) then
              cnv.LineTo (xp - small_length*2,yp)
            else
              cnv.LineTo (xp + small_length*2,yp)
          end; // if
          if (y_values) then
          begin
            if (bYLeft) then
              cnv.TextOut (xp - small_length*2 - cnv.TextWidth(st+' '),
                           yp - cnv.TextHeight(st) DIV 2,
                           st)
            else
              cnv.TextOut (xp + small_length*2 + cnv.TextWidth('A'),
                           yp - cnv.TextHeight(st) DIV 2,
                           st);
          end; // if
        end // if
        else
        begin
          if (y_ticks) then
          begin
            cnv.MoveTo (xp,yp);
            if (bYLeft) then
              cnv.LineTo (xp - small_length,yp)
            else
              cnv.LineTo (xp + small_length,yp)
          end; // if
        end; //else

      end; // for

    end; // if

  end; // with
end; // Axis_Ticks

//***************************************************************************
//
//  FUNCTION    :   Graph_XDate_Ticks
//
//  I/P         :   index (Integer) : The index number of the selected graph.
//                      small_length  (INTEGER) : The length of the small ticks
//                      width (byte) : Width of the tick line
//                      text_colour (TColor) : The colour of the ticks and printed values.
//                      background_colour (TColor) : The colour behind the text
//                      cnv (TCanvas) : The canvas on which this is all drawn
//
//  O/P         :
//
//  OPERATION   :   Determines how best to label the X-Axis, assuming
//                      that the X-axis values are date values.
//
//  UPDATED     :   01/07/1999
//
//***************************************************************************
procedure Graph_XDate_Ticks (index           : Integer;
                             small_length    : Integer;
                             width           : Byte;
                             text_colour     : TColor;
                             background_colour : TColor;
                             cnv             : TCanvas);
const
  XL_DAY = 1;
  XL_WEEK = 2;
  XL_MONTH = 3;
  XL_YEAR = 4;
var
  ave_tw : Integer;           // The expected average width of a large tick label
  max_labels : Integer;       // The maximum number of labels we could fit on the graph
  days : Real;                // Number of days covered by the graph
  dpl : Real;                 // Number of days between each label
  xp : Integer;               // X-coordinate of the tick line
  label_every : Byte;         // Identifier for the spacing of labels/major ticks
  x : Real;                   // Steps through each day in the x-axis
  dstring : String;           // The date text to be displayed as a label
  sDateFormat : String;       // The shortest date format (max 2 digits per day,month,year)

begin
  sDateFormat := FormatSettings.ShortDateFormat;
  // Reduce the year to 2 digits
  sDateFormat := StringReplace(sDateFormat,'yyyy','yy',[]);

  with grphs[index] do
  begin
    if defined then
    begin

      cnv.Pen.Color := text_colour;
      cnv.Brush.Color := background_colour;

      ave_tw := cnv.TextWidth('00/00/00');
      max_labels := (graph_area.right - graph_area.left) div (Trunc(ave_tw * 1.1 + 0.5));
      days := graph_x_max - graph_x_min;
      dpl := days / max_labels;

      if (dpl < 1) then           // Based on how many days we can fit between each large
        label_every := XL_DAY     // tick label, decide whether the large ticks should be
        else                      // each day, Sunday, 1st of month, or 1 January.
          if (dpl < 7.0) then
            label_every := XL_WEEK
          else
            if (dpl < 30.0) then
              label_every := XL_MONTH
            else
              label_every := XL_YEAR;

      x := Int(graph_x_min+0.5);
      while (x<graph_x_max) do
      begin
        xp := graph_area.left + Round ((x-graph_x_min) / x_ratio);
        case label_every of         // Label as determined

          XL_DAY:
          begin
            // Each day is labeled and major ticked.
            dstring := FormatDateTime(sDateFormat,x);
            cnv.MoveTo (xp,graph_area.bottom);
            cnv.LineTo (xp,graph_area.bottom + small_length*2);
            cnv.TextOut (xp - cnv.TextWidth(dstring)DIV 2,
                         graph_area.bottom + small_length*2 +
                         Round(0.2*cnv.TextHeight(dstring)),dstring);
          end; // option

          XL_WEEK:                // Each Sunday is labeled and major ticked.
          begin
            if (DayOfWeek(x)=1) then
            begin
              // Display major tick on a Sunday, with label
              dstring := FormatDateTime(sDateFormat,x);
              cnv.MoveTo (xp,graph_area.bottom);
              cnv.LineTo (xp,graph_area.bottom + small_length*2);
              cnv.TextOut (xp - cnv.TextWidth(dstring)DIV 2,
                           graph_area.bottom + small_length*2 +
                           Round(0.2*cnv.TextHeight(dstring)),dstring);
            end // if
            else
            begin                     // Display minor tick on each other week day
              cnv.MoveTo (xp,graph_area.bottom);
              cnv.LineTo (xp,graph_area.bottom + small_length);
            end; // else
          end; // option

          XL_MONTH:               // Each 1st of the month is labeled and major ticked.
          begin
            if (DayOf(x)=1) then
            begin
              // Display major tick on the 1st, with label
              dstring := FormatDateTime(sDateFormat,x);
              cnv.MoveTo (xp,graph_area.bottom);
              cnv.LineTo (xp,graph_area.bottom + small_length*2);
              cnv.TextOut (xp - cnv.TextWidth(dstring)DIV 2,
                           graph_area.bottom + small_length*2 +
                           Round(0.2*cnv.TextHeight(dstring)),dstring);
            end // if
            else
            begin
              // Display minor tick on every 5th day of the month
              if (DayOf(x) mod 5 = 0) then
              begin
                cnv.MoveTo (xp,graph_area.bottom);
                cnv.LineTo (xp,graph_area.bottom + small_length);
              end; // if
            end; // else
          end; // option

          XL_YEAR:                // Each 1st of the year is labeled and major ticked.
          begin
            if (DayOf(x)=1) and (MonthOf(x)=1) then
            begin
              // Display major tick on the 1st, with label
              dstring := FormatDateTime(sDateFormat,x);
              cnv.MoveTo (xp,graph_area.bottom);
              cnv.LineTo (xp,graph_area.bottom + small_length*2);
              cnv.TextOut (xp - cnv.TextWidth(dstring)DIV 2,
                           graph_area.bottom + small_length*2 +
                           Round(0.2*cnv.TextHeight(dstring)),dstring);
            end // if
            else
            begin                     // Display minor tick on 1st of each month
              if (DayOf(x) = 1) then
              begin
                cnv.MoveTo (xp,graph_area.bottom);
                cnv.LineTo (xp,graph_area.bottom + small_length);
              end; // if
            end; // else
          end; // option

        end; // case

        x := x + 1.0;
      end; // while

    end; // if
  end; // with
end; // Graph_XDate_Ticks

//***************************************************************************
//
//  FUNCTION  : X_Tick_Text
//
//  I/P       : index : Integer - The index number of the selected graph.
//
//              x_val : Real - The X-value on which the text is to be centred.
//
//              x_str : String - The text to be printed.
//
//              small_length : Integer - The length of the small ticks
//                (used to set the y- position of the text.
//
//              text_colour : TColor - The colour of the text.
//
//              background_colour : TColor - The colour behind the text
//
//              cnv : TCanvas - The canvas on which this is all drawn
//
//              bottomAxis : Boolean = TRUE - TRUE to put the text below the
//                the bottom axis. FALSE to put it above the top axis
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2020-06-24
//
//***************************************************************************
procedure X_Tick_Text(index           : Integer;
                      x_val           : Real;
                      x_str           : String;
                      small_length    : Integer;
                      text_colour     : TColor;
                      background_colour : TColor;
                      cnv             : TCanvas;
                      bottomAxis      : Boolean = TRUE);
var
  xp : Integer;

begin
  if grphs[index].defined then
  begin

    cnv.Brush.Color := background_colour;
    cnv.Font.Color := text_colour;

    if (bottomAxis) then
    begin
      xp := grphs[index].graph_area.left + Round ((x_val-grphs[index].graph_x_min) / grphs[index].x_ratio);
      cnv.TextOut(xp - cnv.TextWidth(x_str) DIV 2,
                  grphs[index].graph_area.bottom + small_length*2 + Round(0.2*cnv.TextHeight(x_str)),
                  x_str);
    end // if
    else
    begin
      xp := grphs[index].graph_area.left + Round ((x_val-grphs[index].graph_x_min) / grphs[index].x_ratio);
      cnv.TextOut(xp - cnv.TextWidth(x_str) DIV 2,
                  grphs[index].graph_area.top - small_length*2 - Round(0.2*cnv.TextHeight(x_str)),
                  x_str);
    end; // else
  end; // if
end; // X_Tick_Text

//***************************************************************************
//
//  FUNCTION  : Y_Tick_Text
//
//  I/P       : index : Integer - The index number of the selected graph.
//
//              y_val : Real - The Y-value on which the text is to be centred.
//
//              y_str : String - The text to be printed.
//
//              small_length : Integer - The length of the small ticks
//                (used to set the x- position of the text.
//
//              text_colour : TColor - The colour of the text.
//
//              background_colour : TColor - The colour behind the text
//
//              cnv : TCanvas - The canvas on which this is all drawn
//
//              leftAxis : Boolean = TRUE - TRUE to put the text to the left of
//                the left axis. FALSE to put it to the right of the right axis
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2020-06-24
//
//***************************************************************************
procedure Y_Tick_Text(index           : Integer;
                     y_val           : Real;
                     y_str           : String;
                     small_length    : Integer;
                     text_colour     : TColor;
                     background_colour : TColor;
                     cnv             : TCanvas;
                     leftAxis        : Boolean = TRUE);
begin
  if grphs[index].defined then
  begin

    cnv.Brush.Color := background_colour;
    cnv.Font.Color := text_colour;

    if (leftAxis) then
    begin
      cnv.TextOut (grphs[index].graph_area.left - small_length*2 - cnv.TextWidth(y_str+' '),
                   grphs[index].graph_area.bottom - Round ((y_val - grphs[index].graph_y_min) / grphs[index].y_ratio) - cnv.TextHeight(y_str) DIV 2,
                   y_str);
    end // if
    else
    begin
      cnv.TextOut (grphs[index].graph_area.right + small_length*2 + cnv.TextWidth(' '),
                   grphs[index].graph_area.bottom - Round (y_val / grphs[index].y_ratio) - cnv.TextHeight(y_str) DIV 2,
                   y_str);
    end; // else
  end; // if
end; // Y_Tick_Text

//*****************************************************************************
//
//  DESCRIPTION
//
//  This procedure will print the given titles for the axis of a selected
//  graph.   The x-title is centred on the x-axis, and is printed at the
//  y-coordinate given.   The y-title is printed vertically, centered on the
//  y-axis, at the x-coordinate given.   The titles are both in a user
//  supplied colour.
//
//  PARAMETERS
//
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  2000/05/26
//
//*****************************************************************************


//***************************************************************************
//
//  FUNCTION  : Graph_Titles
//
//  I/P       : index : Integer - The index number of the selected graph.
//
//              x_title : String - The title to be printed for the x-axis.
//
//              x_title_y : Integer - The screen y-coord where the x title is displayed.
//
//              y_title : String - The title to be printed for the y-axis.
//
//              y_title_x : Integer - The screen x-coord where the y title is displayed.
//
//              text_colour : TColor - The colour of the ticks and printed values.
//
//              background_colour : TColor - The colour behind the text
//
//              cnv : TCanvas - The canvas on which this is all drawn
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure Graph_Titles(index     : Integer;
                       x_title   : String;
                       x_title_y : Integer;
                       y_title   : String;
                       y_title_x : Integer;
                       text_colour     : TColor;
                       background_colour : TColor;
                       cnv             : TCanvas);
var
  p : Integer;
  oldPenColour : TColor;
  oldBrushColour : TColor;

begin
  with grphs[index] do
  begin
    if defined then
    begin
      oldPenColour := cnv.Pen.Color;
      oldBrushColour := cnv.Brush.Color;

      cnv.Pen.Color := text_colour;
      cnv.Brush.Color := background_colour;

//      p := graph_area.top +
//           ((graph_area.bottom - graph_area.top) - Length(y_title)*cnv.TextHeight('A')) DIV 2;
//      for n := 1 to Length(y_title) do  // Output one letter per line
//      begin
//        cnv.TextOut(y_title_x + (cnv.TextWidth('W') - cnv.TextWidth(y_title[n])) div 2,p,y_title[n]);
//        p := p + cnv.TextHeight('A');
//      end; // for

      if (y_title <> '') then
      begin
        // Y-axis title
        p := graph_area.top +
             ((graph_area.bottom - graph_area.top) - cnv.TextWidth(y_title)) DIV 2 +
             cnv.TextWidth(y_title);
        AngleTextOut(cnv, y_title, y_title_x, p, -cnv.Font.Height, 90);
      end; // if

      if (x_title <> '') then
      begin
        // X-axis title
        p := graph_area.left +
             ((graph_area.right - graph_area.left) - cnv.TextWidth(x_title)) DIV 2;
        cnv.TextOut (p,x_title_y,x_title);
      end; // if

      cnv.Pen.Color := oldPenColour;
      cnv.Brush.Color := oldBrushColour;
    end; // if
  end; // with
end; // Graph_Titles

//*****************************************************************************
//
//  DESCRIPTION
//
//  This procedure will place a grid of dots of a given colour on the selected
//  graph.   The x and y spacing of the dots can be specified.
//
//  PARAMETERS
//
//  index (Integer) : The index number of the selected graph.
//  x_space (real) : The graph value between dots in the x-axis.
//  y_space (real) : The graph value between dots in the y-axis.
//  size (byte) : The size of the dots.
//  dot_colour (TColor) : The colour of the dots.
//  cnv (TCanvas) : The canvas on which this is all drawn
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  2000/08/03
//
//*****************************************************************************
procedure Grid(index      : Integer;
               x_space    : Real;
               y_space    : Real;
               size       : Byte;
               dot_colour : TColor;
               cnv        : TCanvas);
VAR
  n,m,p,q : Integer;
  xp,yp   : Integer;

begin
  with grphs[index] DO
  begin
    if defined then
    begin
      cnv.Pen.Color := dot_colour;
      cnv.Pen.Width := size;
      cnv.Brush.Color := dot_colour;

      n := Round ((graph_x_max - graph_x_min) / x_space);
      m := Round ((graph_y_max - graph_y_min) / y_space);
      FOR p := 1 TO n - 1 DO
      begin
        xp := graph_area.left + Round ((x_space * p) / x_ratio);
        FOR q := 1 to m - 1 DO
        begin
          yp := graph_area.bottom - Round ((y_space * q) / y_ratio);
          if (size = 1) then
            cnv.Pixels[xp,yp] := dot_colour
          else
          begin
            cnv.MoveTo(xp,yp);
            cnv.LineTo(xp+1,yp+1);
          end; // else
//            cnv.Rectangle(xp-size div 2,yp-size div 2,
//                          xp+size div 2,yp+size div 2);
        end; // for
      end; // for
    end; // if
  end; // with
end; //Grid

//*****************************************************************************
//
//  DESCRIPTION
//
//  This procedure will set a pixel at graph coordinates on a selected graph.
//  The colour of the pixel may be specified.
//
//  PARAMETERS
//
//  index (Integer) : The index number of the selected graph.
//  x1 (real) : The graph value of the x coordinate.
//  y1 (real) : The graph value of the y coordinate.
//  colour (byte) : The colour of the pixel.
//  cnv (TCanvas) : The canvas on which this is all drawn
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  1 July 1999
//
//*****************************************************************************
procedure Graph_Pixel(index  : Integer;
                      x1,y1  : Real;
                      colour : Byte;
                      cnv    : TCanvas);
begin
  with grphs[index] do
  begin
    if defined and
       ((x1>=graph_x_min) and (x1<=graph_x_max)) and
       ((y1>=graph_y_min) and (y1<=graph_y_max)) then
      cnv.Pixels[Round ((x1 - graph_x_min) / x_ratio),
                 graph_area.bottom - graph_area.top -
                 Round ((y1 - graph_y_min) / y_ratio)] := colour;
  end; // with
end; // Graph_Pixel

//*****************************************************************************
//
//  DESCRIPTION
//
//  This procedure will draw a line between two given points on a selected
//  graph.   The colour of the line may be specified.
//
//  PARAMETERS
//
//  index (Integer) : The index number of the selected graph.
//  x1 (real) : The graph value of the starting x coordinate.
//  y1 (real) : The graph value of the starting y coordinate.
//  x2 (real) : The graph value of the finishing x coordinate.
//  y2 (real) : The graph value of the finishing y coordinate.
//  line_colour (byte) : The colour of the line.
//  cnv (TCanvas) : The canvas on which this is all drawn
//
//  AUTHOR
//
//  Andrew Neil Spencer
//
//  LATEST MODIFICATION DATE
//
//  12 June 1998
//
//*****************************************************************************
PROCEDURE Graph_Line(index       : Integer;
                     x1,y1,x2,y2 : Real;
                     width       : Byte;
                     line_colour : TColor;
                     cnv        : TCanvas);
VAR
  xs,ys : Longint;
  xf,yf : Longint;

begin
  if (grphs[index].defined) then
  begin
    if (((x1 >= grphs[index].graph_x_min) and (x1 <= grphs[index].graph_x_max)) and
        ((x2 >= grphs[index].graph_x_min) and (x2 <= grphs[index].graph_x_max)) and
        ((y1 >= grphs[index].graph_y_min) and (y1 <= grphs[index].graph_y_max)) and
        ((y2 >= grphs[index].graph_y_min) and (y2 <= grphs[index].graph_y_max))) then
    begin
      cnv.Pen.Color := line_colour;
      cnv.Pen.Width := width;

  // Permit drawing on a graph where the left and right X values are equal
      if (grphs[index].x_ratio <> 0) then
      begin
        xs := grphs[index].graph_area.left + Round ((x1 - grphs[index].graph_x_min) / grphs[index].x_ratio);
        xf := grphs[index].graph_area.left + Round ((x2 - grphs[index].graph_x_min) / grphs[index].x_ratio);
      end // if
      else
      begin
        xs := grphs[index].graph_area.left;
        xf := grphs[index].graph_area.left;
      end; // else

      // Permit drawing on a graph where the top and bottom Y values are equal
      if (grphs[index].y_ratio <> 0) then
      begin
        ys := grphs[index].graph_area.bottom - Round ((y1 - grphs[index].graph_y_min) / grphs[index].y_ratio);
        yf := grphs[index].graph_area.bottom - Round ((y2 - grphs[index].graph_y_min) / grphs[index].y_ratio);
      end // if
      else
      begin
        ys := grphs[index].graph_area.bottom;
        yf := grphs[index].graph_area.bottom;
      end; // else
  (*
  These conditions are always false!
      if ABS (xs) > MaxInt then
         xs := (xs DIV ABS(xs)) * MaxInt;

      if ABS (ys) > MaxInt then
         ys := (ys DIV ABS(ys)) * MaxInt;

      if ABS (xf) > MaxInt then
         xf := (xf DIV ABS(xf)) * MaxInt;

      if ABS (yf) > MaxInt then
         yf := (yf DIV ABS(yf)) * MaxInt;
  *)
      cnv.MoveTo (xs,ys);
      cnv.LineTo (xf,yf);

    end; // if
  end; // if
end; // Graph_Line

//***************************************************************************
//
//  FUNCTION    :   Graph_Rect
//
//  I/P         :   index (Integer) : The index number of the selected graph.
//                      x1 (real) : The graph value of the Left side.
//                      y1 (real) : The graph value of the Top side.
//                      x2 (real) : The graph value of the Right side.
//                      y2 (real) : The graph value of the Bottom side.
//                      line_colour (byte) : The colour of the rectangle.
//                      brush_style (TBrushStyle) : The style of rectangle fill
//                      cnv (TCanvas) : The canvas on which this is all drawn
//
//  O/P         :
//
//  OPERATION   :   This procedure will draw a rectangle on the graph.   The
//                      shape may be outlined (Pen only) or filled (Pen and Brush)
//
//                      The original brush and pen colours are restored after drawing
//                      the rectangle.
//
//  UPDATED     :   12/08/1999
//
//***************************************************************************
procedure Graph_Rect(index       : Integer;
                     x1,y1       : Real;
                     x2,y2       : Real;
                     fill_colour : TColor;
                     brush_style : TBrushStyle;
                     cnv         : TCanvas);
var
  xs,ys : Longint;
  xf,yf : Longint;
  temp_pen : TPen;                    // Temporary storage of existing Pen
  temp_brush : TBrush;                // Temporary storage of existing Brush

begin
  with grphs[index] do
  begin

    if defined then
    begin
      temp_pen := cnv.Pen;            // Store the original Brush and Pen, so that we do not
      temp_brush := cnv.Brush;        // mess up items (eg text) later.

      cnv.Brush.Color := fill_colour;
      cnv.Pen.Color := fill_colour;
      cnv.Pen.Style := psSolid;
      cnv.Brush.Style := brush_style;

      if (x1<graph_x_min) then
        x1 := graph_x_min;

      if (x1>graph_x_max) then
        x1 := graph_x_max;

      if (x2<graph_x_min) then
        x2 := graph_x_min;

      if (x2>graph_x_max) then
        x2 := graph_x_max;

      if (y1<graph_y_min) then
        y1 := graph_y_min;

      if (y1>graph_y_max) then
        y1 := graph_y_max;

      if (y2<graph_y_min) then
        y2 := graph_y_min;

      if (y2>graph_y_max) then
        y2 := graph_y_max;

      xs := graph_area.left + Round ((x1 - graph_x_min) / x_ratio);
      ys := graph_area.bottom - Round ((y1 - graph_y_min) / y_ratio);
      xf := graph_area.left + Round ((x2 - graph_x_min) / x_ratio);
      yf := graph_area.bottom - Round ((y2 - graph_y_min) / y_ratio);
(*
These conditions are always false!
      if ABS (xs) > MaxInt then
         xs := (xs DIV ABS(xs)) * MaxInt;

      if ABS (ys) > MaxInt then
         ys := (ys DIV ABS(ys)) * MaxInt;

      if ABS (xf) > MaxInt then
         xf := (xf DIV ABS(xf)) * MaxInt;

      if ABS (yf) > MaxInt then
         yf := (yf DIV ABS(yf)) * MaxInt;
*)
      // Don't draw the rectanlge if it is flat - more than likely
      // this will be on an axis line, which we might not actually want eg if
      // the fill colour is white (An example is 0-height bars in a bar graphs)
      if ((xs<>xf) and (ys<>yf)) then
        cnv.Rectangle(xs,ys,xf,yf);

      cnv.Brush := temp_brush;      // Restore the original Pen and Brush.
      cnv.Pen := temp_pen;
    end; // if
  end; // with

end; // Graph_Rect

//***************************************************************************
//
//  FUNCTION  : Graph_FillRect
//
//  I/P       : index (Integer) : The index number of the selected graph.
//              x1 (real) : The graph value of the Left side.
//              y1 (real) : The graph value of the Top side.
//              x2 (real) : The graph value of the Right side.
//              y2 (real) : The graph value of the Bottom side.
//              cFillColour (TColor) : The colour of the rectangle.
//              cnv (TCanvas) : The canvas on which this is all drawn
//
//  O/P       : None.
//
//  OPERATION : This procedure will draw a rectangle on the graph.   The
//              shape may be outlined (Pen only) or filled (Pen and Brush)
//
//              The original brush and pen colours are restored after drawing
//              the rectangle.
//
//              This routine was found to work in a situation where the above
//              Graph_Rectangle did not (i.e. filling thin rectangles on a
//              printout in YAMS linear activity charts)
//
//  UPDATED   : 2007/02/24
//
//***************************************************************************
procedure Graph_FillRect(index       : Integer;
                         x1,y1       : Real;
                         x2,y2       : Real;
                         cFillColour : TColor;
                         cnv         : TCanvas);
var
  xs,ys : Longint;
  xf,yf : Longint;
  temp_brush : TBrush;                // Temporary storage of existing Brush

begin

  with grphs[index] DO
  begin

    if defined then
    begin
      // Store the original Brush, so that we do not mess up items later.
      temp_brush := cnv.Brush;

      cnv.Brush.Color := cFillColour;

      if (x1<graph_x_min) then
        x1 := graph_x_min;

      if (x1>graph_x_max) then
        x1 := graph_x_max;

      if (x2<graph_x_min) then
        x2 := graph_x_min;

      if (x2>graph_x_max) then
        x2 := graph_x_max;

      if (y1<graph_y_min) then
        y1 := graph_y_min;

      if (y1>graph_y_max) then
        y1 := graph_y_max;

      if (y2<graph_y_min) then
        y2 := graph_y_min;

      if (y2>graph_y_max) then
        y2 := graph_y_max;

      xs := graph_area.left + Round ((x1 - graph_x_min) / x_ratio);
      ys := graph_area.bottom - Round ((y1 - graph_y_min) / y_ratio);
      xf := graph_area.left + Round ((x2 - graph_x_min) / x_ratio);
      yf := graph_area.bottom - Round ((y2 - graph_y_min) / y_ratio);

(*
These conditions are always false!
      if ABS (xs) > MaxInt then
         xs := (xs DIV ABS(xs)) * MaxInt;

      if ABS (ys) > MaxInt then
         ys := (ys DIV ABS(ys)) * MaxInt;

      if ABS (xf) > MaxInt then
         xf := (xf DIV ABS(xf)) * MaxInt;

      if ABS (yf) > MaxInt then
         yf := (yf DIV ABS(yf)) * MaxInt;
*)
      // Don't draw the rectanlge if it is flat - more than likely
      // this will be on an axis line, which we might not actually want eg if
      // the fill colour is white (An example is 0-height bars in a bar graphs)
      if ((xs<>xf) and (ys<>yf)) then
        cnv.FillRect(Rect(xs,ys,xf,yf));

      cnv.Brush := temp_brush;      // Restore the original Pen and Brush.
    end; // if
  end; // with

end; // Graph_FillRect

//***************************************************************************
//
//  FUNCTION    :   Graph_Circle
//
//  I/P         :   index (Integer) : The index number of the selected graph.
//                      cx1 (real) : The graph value of the centre.
//                      cy1 (real) : The graph value of the centre.
//                      r (real) : Radius of the circle.
//                      fill_colour (byte) : The colour of the circle
//                      brush_style (TBrushStyle) : The style of circle fill
//                      cnv (TCanvas) : The canvas on which this is all drawn
//
//  O/P         :
//
//  OPERATION   :   This procedure will draw a circle on the graph.   The
//                      shape may be outlined (Pen only) or filled (Pen and Brush)
//
//                      The original brush and pen colours are restored after drawing
//                      the rectangle.
//
//  UPDATED     :   2001/04/22
//
//***************************************************************************
procedure Graph_Circle(index       : Integer;
                        cx,cy       : Real;
                        r           : Real;
                        fill_colour : TColor;
                        brush_style : TBrushStyle;
                        cnv         : TCanvas);
var
  xs,ys : Longint;
  xf,yf : Longint;
  temp_pen : TPen;                    // Temporary storage of existing Pen
  temp_brush : TBrush;                // Temporary storage of existing Brush

begin

  with grphs[index] DO
  begin

    if ((defined) and
        (cx >= graph_x_min) and
        (cx <= graph_x_max) and
        (cy >= graph_y_min) and
        (cy <= graph_y_max)) then
    begin

// Store the original Brush and Pen, so that we do not mess up items (eg text) later.
      temp_pen := cnv.Pen;
      temp_brush := cnv.Brush;

      cnv.Brush.Color := fill_colour;
      cnv.Pen.Color := fill_colour;
      cnv.Brush.Style := brush_style;

      xs := graph_area.left + Round ((cx - r - graph_x_min) / x_ratio);
      ys := graph_area.bottom - Round ((cy - r - graph_y_min) / y_ratio);
      xf := graph_area.left + Round ((cx + r - graph_x_min) / x_ratio);
      yf := graph_area.bottom - Round ((cy + r - graph_y_min) / y_ratio);

(*
These conditions are always false!
      if ABS (xs) > MaxInt then
         xs := (xs DIV ABS(xs)) * MaxInt;

      if ABS (ys) > MaxInt then
         ys := (ys DIV ABS(ys)) * MaxInt;

      if ABS (xf) > MaxInt then
         xf := (xf DIV ABS(xf)) * MaxInt;

      if ABS (yf) > MaxInt then
         yf := (yf DIV ABS(yf)) * MaxInt;
*)
      if (xs<>xf) and (ys<>yf) then // Don't draw the circle if it is flat - more than
        cnv.Ellipse(xs,ys,xf,yf);   // likely this will be on an axis line, which we might
                                    // not actually want eg if the fill colour is white
                                    // (An example is 0-height bars in a bar graphs)

      cnv.Brush := temp_brush;      // Restore the original Pen and Brush.
      cnv.Pen := temp_pen;
    end; // if
  end; // with

end; // Graph_Circle

//***************************************************************************
//
//  FUNCTION    :   Pixel_To_X
//
//  I/P         :   index (byte) : The index number of the selected graph.
//                      x (integer) : The screen x co-ordinate.
//
//  O/P         :   (real) : The corresponding real x graph value at the
//                      given screen x pixel position.  (0.0 if graph is not defined
//
//  OPERATION   :   This procedure converts a screen x-value into a graph
//                      x-value.
//
//  UPDATED     :   17/07/1999
//
//***************************************************************************
function Pixel_To_X (index : Integer;
                     x     : real) : Real;
begin
  if grphs[index].defined then
    result := (x - grphs[index].graph_area.left) * grphs[index].x_ratio +
              grphs[index].graph_x_min
  else
    result := 0.0
end; // Pixel_To_X

//***************************************************************************
//
//  FUNCTION    :   Pixel_To_Y
//
//  I/P         :   index (Integer) : The index number of the selected graph.
//                      y (integer) : The screen y co-ordinate.
//
//  O/P         :   (real) : The corresponding real y graph value at the
//                      given screen y pixel position.  (0.0 if graph is not defined
//
//  OPERATION   :   This procedure converts a screen y-value into a graph
//                      y-value.
//
//  UPDATED     :   17/07/1999
//
//***************************************************************************
function Pixel_To_Y (index : Integer;
                     y     : real) : Real;
begin
  if grphs[index].defined then
    result := grphs[index].graph_y_max -
              (y - grphs[index].graph_area.top) * grphs[index].y_ratio
  else
    result := 0.0
end; // Pixel_To_X

//***************************************************************************
//
//  FUNCTION  : Y_To_Pixel
//
//  I/P       : index : Integer - The index number of the selected graph.
//
//              y : Double - The Y-value on the graph.
//
//  O/P       : Integer -  The correspondingscreen y pixel value
//                    (-1 if graph is not defined or outside of the Y-axis)
//
//  OPERATION : This procedure converts a graph Y-value into a screen pixel
//                Y-value.
//
//  UPDATED   : 2018-11-15
//
//***************************************************************************
function Y_To_Pixel (index : Integer;
                     y     : Double) : Integer;
begin
  if (grphs[index].defined) then
  begin
    if ((y <= grphs[index].graph_y_max) and
        (y >= grphs[index].graph_y_min)) then
    begin
      result := Trunc(grphs[index].graph_area.bottom - y / grphs[index].y_ratio);
//      result := Trunc((grphs[index].graph_y_max - y) / grphs[index].y_ratio +
//                      grphs[index].graph_area.top);
    end // if
    else
    begin
      result := -1;
    end;
  end // if
  else
  begin
    result := -1;
  end; // else
end; // Y_To_Pixel

//***************************************************************************
//
//  FUNCTION    :   Crop_Line_To_Graph
//
//  I/P         :   index (Integer) : The index number of the selected graph.
//                      eLX,eLY (real) : The left had points of the line
//                      eRX,eRY (real) : The right hand points of the line
//
//  O/P         :   eLX,eLY,eRX,eRY (real) : Modified, so that the points
//                      fall within the graph area, but the line has the same
//                      slope and offset as when the routine was called.
//
//  OPERATION   :   This procedure may modify the position of one or both
//                      of the given line end-points, so that the line falls
//                      within the graph area, but has the same slope and offset
//                      as the original line.
//
//                      If the line lies completely outside of the graph area,
//                      it is returned with both points defined to the lower left
//                      corner of the graph.
//
//                      Note that this function does not extend lines, it only
//                      crops them.
//
//  UPDATED     :   2000/11/22
//
//***************************************************************************
procedure Crop_Line_To_Graph(index : Integer;
                             var rLX,rLY,rRX,rRY : real);
var
  eSlope : Extended;
  eOffset : Extended;
begin
// Ensure that this is a defined graph area
  if grphs[index].defined then
  begin

// Determine the current slope and offset of the line
    Get_Line_Equ(eSlope,eOffset,rLX,rLY,rRX,rRY);

// Check that the entire line does not lie to the left or right of the graph area
    if (((rLX < grphs[index].graph_x_min) and
         (rRX < grphs[index].graph_x_min)) or
        ((rLX > grphs[index].graph_x_max) and
         (rRX > grphs[index].graph_x_max))) then
    begin
// The line lies to left or right, so set both points to the lower left of the graph
      rLX := grphs[index].graph_x_min;
      rLY := grphs[index].graph_y_min;
      rRX := grphs[index].graph_x_min;
      rRY := grphs[index].graph_y_min;
    end // if
    else
    begin
// The line does have an X-range that includes, at least, part of the graph's X-range

// Check if the left point's X co-ordinate is below the minimum
      if (rLX < grphs[index].graph_x_min) then
      begin
// If so, fix it at the minimum, and calculate the new Y co-ordinate
        rLX := grphs[index].graph_x_min;
        rLY := rLX * eSlope + eOffset;
      end;

// Check if the right point's X co-ordinate is above the maximum
      if (rRX > grphs[index].graph_x_max) then
      begin
// If so, fix it at the minimum, and calculate the new Y co-ordinate
        rRX := grphs[index].graph_x_max;
        rRY := rRX * eSlope + eOffset;
      end;

// Check that the entire line does not lie to above or below the graph area
      if (((rLY < grphs[index].graph_y_min) and
           (rRY < grphs[index].graph_y_min)) or
          ((rLY > grphs[index].graph_y_max) and
           (rRY > grphs[index].graph_y_max))) then
      begin
// The line lies above or below, so set both points to the lower left of the graph
        rLX := grphs[index].graph_x_min;
        rLY := grphs[index].graph_y_min;
        rRX := grphs[index].graph_x_min;
        rRY := grphs[index].graph_y_min;
      end // if
      else
      begin
// The line does have a Y-range that includes, at least, part of the graph's Y-range

// Check if the left point's Y co-ordinate is below the minimum
        if (rLY < grphs[index].graph_y_min) then
        begin
// If so, fix it at the minimum, and calculate the new X co-ordinate
          rLY := grphs[index].graph_y_min;
          rLX := (rLY - eOffset) / eSlope;
        end
        else
// Check if the left point's Y co-ordinate is above the maximum
          if (rLY > grphs[index].graph_y_max) then
          begin
// If so, fix it at the maximum, and calculate the new X co-ordinate
            rLY := grphs[index].graph_y_max;
            rLX := (rLY - eOffset) / eSlope;
          end;

// Check if the right point's Y co-ordinate is below the minimum
        if (rRY < grphs[index].graph_y_min) then
        begin
// If so, fix it at the minimum, and calculate the new X co-ordinate
          rRY := grphs[index].graph_y_min;
          rRX := (rRY - eOffset) / eSlope;
        end
        else
// Check if the right point's Y co-ordinate is above the maximum
          if (rRY > grphs[index].graph_y_max) then
          begin
// If so, fix it at the maximum, and calculate the new X co-ordinate
            rRY := grphs[index].graph_y_max;
            rRX := (rRY - eOffset) / eSlope;
          end;
      end; // else
    end; // else
  end; // if
end; // Crop_Line_To_Graph


begin

//*****************************************************************************

  FOR r := 1 TO max_graphs DO
    grphs[r].defined := false;

end. //UNIT

