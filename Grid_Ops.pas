unit Grid_Ops;

interface

uses
  System.IniFiles, System.SysUtils, System.Types, System.Classes,
  System.Win.Registry,
  Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.Forms, Vcl.Graphics,
  SMDBGrid;

function GetColumnIndex(grid : TSMDBGrid;
                        column : TColumn) : Integer; overload;
function GetColumnIndex(grid : TDBGrid;
                        column : TColumn) : Integer; overload;
procedure HighlightGridColumn(grid : TSMDBGrid;
                              column : TColumn;
                              changeColour : Integer;
                              remap : array of Integer);
procedure SetGridCellBackground(grid : TSMDBGrid;
                                cellRect : TRect;
                                Column: TColumn;
                                State: TGridDrawState;
                                clOddRows : TColor); overload
procedure SetGridCellBackground(grid : TDBGrid;
                                cellRect : TRect;
                                Column: TColumn;
                                State: TGridDrawState;
                                clOddRows : TColor); overload;
function GetGridClientWidth(cgTarget : TCustomGrid) : Integer;
procedure ResizeDBGridColumns(theGrid : TDBGrid;
                              columnRatios : array of Integer);
procedure LoadDBGridColumnWidths(grid : TDBGrid;
                                 reg : TCustomIniFile;
                                 key : String);
procedure ResizeGridColumns(theGrid : TDrawGrid;
                            columnRatios : array of Integer); overload;
procedure ResizeGridColumns(theGrid : TDBGrid;
                            columnRatios : array of Integer); overload;
procedure LoadGridColumnWidths(grid : TDrawGrid;
                               reg : TCustomIniFile;
                               key : String); overload;
procedure HandleGridRowColour(grid : TSMDBGrid;
                              const mRect: TRect;
                              const Column: TColumn;
                              const State: TGridDrawState);
procedure DrawGridCellText(grid : TSMDBGrid;
                           const mRect : TRect;
                           const DataCol : Integer;
                           const theText : String); overload;
procedure DrawGridCellText(grid : TStringGrid;
                           const mRect : TRect;
                           const theText : String;
                           const textAlign : TAlignment); overload;
procedure StrikeoutCell(cgTarget : TCustomGrid;
                        cell : TRect;
                        const colour : TColor = clRed);
procedure TitleClickHandler(grid : TSMDBGrid;
                            Column : TColumn;
                            const indexesFwd : array of String;
                            const indexesRev : array of String;
                            const bolden : array of Integer;
                            searchEdit : TCustomEdit);
procedure SetColumnVisibility(grid : TSMDBGrid;
                              idxColumn : Integer;
                              setVisible : Boolean;
                              config : TCustomIniFile;
                              sectionColumnVisibility : String;
                              sectionColumnWidth : String);
procedure StoreGridColumnWidths(grid : TSMDBGrid;
                                config : TCustomIniFile;
                                sectionColumnWidth : String);
procedure SaveDBGridColumnWidths(grid : TSMDBGrid;
                                 reg : TRegistryIniFile;
                                 key : String); overload;
procedure SaveDBGridColumnWidths(grid : TDBGrid;
                                 reg : TRegistryIniFile;
                                 key : String); overload;
procedure SelectAll(grid : TSMDBGrid); overload;
procedure SelectAll(grid : TDBGrid); overload;

implementation

uses
  Vcl.Themes,
  Windows,
  DBISAMTb,
  Colour_Ops, Str_Ops, VCL_Ops;

//***************************************************************************
//
//  FUNCTION  : GetColumnIndex
//
//  I/P       : grid : TSMDBGrid or TDBGrid - The grid to which the column belongs
//
//              column : TColumn - the column of interest
//
//  O/P       : Integer - the index of the column, within the grid. Else -1.
//
//  OPERATION : Find the index of the given column within the given DB grid.
//
//  UPDATED   : 2024-07-22
//
//***************************************************************************
function GetColumnIndex(grid : TSMDBGrid;
                        column : TColumn) : Integer; overload;
var
  n : Integer;

begin
  // Determine the index of the column that has been clicked.
  Result := -1;
  for n := 0 to grid.Columns.Count-1 do
  begin
    if (grid.Columns[n] = column) then
    begin
      Result := n;
      Break;
    end; // if
  end; // for
end; // GetColumnIndex

function GetColumnIndex(grid : TDBGrid;
                        column : TColumn) : Integer; overload;
var
  n : Integer;

begin
  // Determine the index of the column that has been clicked.
  Result := -1;
  for n := 0 to grid.Columns.Count-1 do
  begin
    if (grid.Columns[n] = column) then
    begin
      Result := n;
      Break;
    end; // if
  end; // for
end; // GetColumnIndex

//***************************************************************************
//
//  FUNCTION  : HighlightGridColumn
//
//  I/P       : grid : TSMDBGrid - The target TSMDBGrid
//
//              column : TColumn - the selected column for highlighting
//
//              changeColour : Integer - The amount by which the column
//                background RGB elements are to be darkened (or lightened)
//
//              remap : array of Integer - An array of column indexes,
//                allowing an alternative column to be highlighted. Elements
//                may be -1, if no change is required. The array should be zero
//                length if no remapping is required.
//
//  O/P       : None
//
//  OPERATION : Alter the background colour of a given column to show interest.
//
//              Un-highlighted column backgrounds are assumed to be clWindow and
//              highlighted column backgrounds will be darkened by the given
//              amount (if the theme permits) else lightened.
//
//              Typically used when a title has been clicked, and the column
//              indicates sort order.
//
//              Remapping to a different column is optionally available.
//
//  UPDATED   : 2024-07-22
//
//***************************************************************************
procedure HighlightGridColumn(grid : TSMDBGrid;
                              column : TColumn;
                              changeColour : Integer;
                              remap : array of Integer);
var
  n : Integer;
  idxColumnToHighlight : Integer;

begin
  with grid do
  begin

    if ((Length(remap) <> 0) and
        (Length(remap) <> Columns.Count)) then
    begin
      // If highlighting a column other than the column offered, the remapping
      // set should be valid.
      Exit;
    end;

    // Determine the index of the column to be highlighted, remapping as needed.
    idxColumnToHighlight := GetColumnIndex(grid, column);
    if (Length(remap) <> 0) then
    begin
      idxColumnToHighlight := remap[idxColumnToHighlight];
    end; // if

    // Check whether a column has been selected for highlighting, or is valid.
    // Make no changes otherwise.
    if ((idxColumnToHighlight < 0) or
        (idxColumnToHighlight > Columns.Count)) then
    begin
      Exit;
    end;

    // Remove the bold (active sorting) from each title and determine the
    // index of the column that has been clicked.   (This operation assumes
    // that the same field does not appear in more than one column)
    for n := 0 to grid.Columns.Count-1 do
    begin
      grid.Columns[n].Title.Font.Style := [];
      grid.Columns[n].Color := TStyleManager.ActiveStyle.GetSystemColor(clWindow);
      // Columns[n].Color := TStyleManager.ActiveStyle.GetStyleColor(scGrid);
    end; // for


    // Set the title of the required column to Bold font
    Columns[idxColumnToHighlight].Title.Font.Style := [fsBold];
    // Set the column background to a slightly different colour, to indicate
    // that it is the sorted column.
    if (CanChangeColour(TStyleManager.ActiveStyle.GetSystemColor(clWindow), -changeColour)) then
    begin
      Columns[idxColumnToHighlight].Color := ChangeColourShade(
        TStyleManager.ActiveStyle.GetSystemColor(clWindow),
        -changeColour
      )
    end // if
    else
    begin
      Columns[idxColumnToHighlight].Color := ChangeColourShade(
        TStyleManager.ActiveStyle.GetSystemColor(clWindow), changeColour
      );
    end; // else

  end; // whith
end; // HighlightGridColumn

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
procedure SetGridCellBackground(grid : TSMDBGrid;
                                cellRect : TRect;
                                Column: TColumn;
                                State: TGridDrawState;
                                clOddRows : TColor); overload
var
  oddLine : Boolean;

begin
  if (gdSelected in State) then
  begin
    grid.Canvas.Brush.Color := clHighlight;
  end // if
  else
  begin
    oddLine := ((grid.DataSource.DataSet.RecNo mod 2) <> 0);
    if ((oddLine) and (not grid.DataSource.DataSet.Filtered)) then
    begin
      if (CanChangeColour(clOddRows, - (TStyleManager.ActiveStyle.GetSystemColor(clWindow) - Column.Color))) then
      begin
        grid.Canvas.Brush.Color := (
          clOddRows - (TStyleManager.ActiveStyle.GetSystemColor(clWindow) - Column.Color)
        ) AND $00FFFFFF;
      end // if
      else
      begin
        grid.Canvas.Brush.Color := (
          clOddRows + (TStyleManager.ActiveStyle.GetSystemColor(clWindow) - Column.Color)
        ) AND $00FFFFFF;
      end;
    end // if
    else
    begin
      grid.Canvas.Brush.Color := Column.Color;
    end; // else
  end; // else
  grid.Canvas.FillRect(cellRect);
end; // SetGridCellBackground

procedure SetGridCellBackground(grid : TDBGrid;
                                cellRect : TRect;
                                Column: TColumn;
                                State: TGridDrawState;
                                clOddRows : TColor); overload;
var
  oddLine : Boolean;

begin
  if (gdSelected in State) then
  begin
    grid.Canvas.Brush.Color := clHighlight;
  end // if
  else
  begin
    oddLine := ((grid.DataSource.DataSet.RecNo mod 2) <> 0);
    if ((oddLine) and (not grid.DataSource.DataSet.Filtered)) then
    begin
      if (CanChangeColour(clOddRows, - (TStyleManager.ActiveStyle.GetSystemColor(clWindow) - Column.Color))) then
      begin
        grid.Canvas.Brush.Color := (
          clOddRows - (TStyleManager.ActiveStyle.GetSystemColor(clWindow) - Column.Color)
        ) AND $00FFFFFF;
      end // if
      else
      begin
        grid.Canvas.Brush.Color := (
          clOddRows + (TStyleManager.ActiveStyle.GetSystemColor(clWindow) - Column.Color)
        ) AND $00FFFFFF;
      end;
    end // if
    else
    begin
      grid.Canvas.Brush.Color := Column.Color;
    end; // else
  end; // else
  grid.Canvas.FillRect(cellRect);
end; // SetGridCellBackground

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
function GetGridClientWidth(cgTarget : TCustomGrid) : Integer;
begin
  result := cgTarget.Width - GetSystemMetrics(SM_CXVSCROLL);
  // Only available in TDBGrids
  if (cgTarget is TDBGrid) then
  begin
    if (dgIndicator in (cgTarget as TDBGrid).Options) then
    begin
      result := result - INDICATORWIDTH;
      if dgColLines in (cgTarget as TDBGrid).Options then
        Dec(result);
    end; // if
    if (dgColLines in (cgTarget as TDBGrid).Options) then
      result := result - (cgTarget as TDBGrid).Columns.Count;
  end; // if

  if (((cgTarget is TDBGrid) and
       ((cgTarget as TDBGrid).Ctl3D)) or
      ((cgTarget is TStringGrid) and
       ((cgTarget as TStringGrid).Ctl3D))) then
  begin
    if (((cgTarget is TDBGrid) and
         ((cgTarget as TDBGrid).BorderStyle = bsSingle)) or
        ((cgTarget is TStringGrid) and
         ((cgTarget as TStringGrid).BorderStyle = bsSingle))) then
      // 2 * 2 Pixel
      result := result - 4
    else
      // 2 * 1 Pixel
      result := result - 2;
  end; // if

  if ((cgTarget is TStringGrid) and
      (goVertLine in (cgTarget as TStringGrid).Options)) then
    result := result -
              (cgTarget as TStringGrid).ColCount * (cgTarget as TStringGrid).GridLineWidth;


end; // GetGridClientWidth
(*
function GetDBGridClientWidth(dbgTarget : TDBGrid) : Integer;
begin
  result := dbgTarget.Width - GetSystemMetrics(SM_CXVSCROLL);
  if (dgIndicator in dbgTarget.Options) then
  begin
    result := result - INDICATORWIDTH;
    if dgColLines in dbgTarget.Options then
      Dec(result);
  end; // if
  if (dbgTarget.BorderStyle = bsSingle) then
  begin
    if (dbgTarget.Ctl3D) then // 2 * 2 Pixel
      result := result - 4
    else // 2 * 1 Pixel
      result := result - 2;
  end; // if
  if (dgColLines in dbgTarget.Options) then
    result := result - dbgTarget.Columns.Count;
end; // GetGridClientWidth
*)


//***************************************************************************
//
//  FUNCTION  : ResizeDBGridColumns
//
//  I/P       : theGrid : TDBGrid
//
//              columnRatios : array of Integer
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2019-06-09
//
//***************************************************************************
procedure ResizeDBGridColumns(theGrid : TDBGrid;
                              columnRatios : array of Integer);
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
      end; // if
    end; // for

    iClientWidth := GetGridClientWidth(theGrid);

    if (iTotal <> 0) then
    begin
      for t := 0 to theGrid.Columns.Count-1 do
      begin
        theGrid.Columns[t].Width := iClientWidth * columnRatios[t] div iTotal;
      end; // for
    end; // if
  end;
end; // ResizeDBGridColumns

//***************************************************************************
//
//  FUNCTION  : LoadDBGridColumnWidths
//
//  I/P       : grid : TSMDBGrid - The grid for which column widths are to be loaded
//
//              reg : TCustomIniFile - The RegistryIniFile to be used
//
//              key : String - the key within the above RegistryIniFile to use
//
//  O/P       : None
//
//  OPERATION : Loads the widths of the specified DGgrid from the given
//              registry/registry key
//
//  UPDATED   : 2019-06-09
//
//***************************************************************************
procedure LoadDBGridColumnWidths(grid : TDBGrid;
                                 reg : TCustomIniFile;
                                 key : String);
var
  iClientSpace : Integer;
  iTotal : Integer;
  n : Integer;

begin
  iClientSpace := GetGridClientWidth(grid);
  iTotal := 0;
  for n := 0 to grid.Columns.Count-1 do
    Inc(iTotal,reg.ReadInteger(key, 'Col' + IntToStr(n), grid.Columns[n].Width));
  for n := 0 to grid.Columns.Count-1 do
    grid.Columns[n].Width := iClientSpace *
                             reg.ReadInteger(key, 'Col' + IntToStr(n), grid.Columns[n].Width) div iTotal;
end; // LoadDBGridColumnWidths

//***************************************************************************
//
//  FUNCTION  : ResizeGridColumns
//
//  I/P       : grid : TDrawGrid - The grid for which column widths are to be loaded
//
//              reg : TCustomIniFile - The RegistryIniFile to be used
//
//              key : String - the key within the above RegistryIniFile to use
//
//  O/P       : None
//
//  O/P       :
//
//  OPERATION : Ratiometrically set the size of columns in a TStringGrid.
//              Differences with the TDBGrid, above, related to property
//              names, and the inability to set the visibility of a particular
//              column.
//
//              Note that the overloaded TDBGrid version can deal with columns
//              that are not visible.
//
//  UPDATED   : 2024-08-12
//
//***************************************************************************
procedure ResizeGridColumns(theGrid : TDrawGrid;
                            columnRatios : array of Integer); overload
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
      begin
        iTotal := iTotal + columnRatios[t];
      end;
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

procedure ResizeGridColumns(theGrid : TDBGrid;
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

//***************************************************************************
//
//  FUNCTION  : LoadGridColumnWidths
//
//  I/P       : grid : TDrawGrid - The grid for which column widths are to be loaded
//
//              reg : TCustomIniFile - The RegistryIniFile to be used
//
//              key : String - the key within the above RegistryIniFile to use
//
//  O/P       : None
//
//  OPERATION : Loads the widths of the specified TDrawGrid from the given
//              registry/registry key
{TODO -oAndrew Spencer -cGeneric : An SMDBGrid is a descendent of a TDBGrid, is it not? These two procedures could be combined}
//
//  UPDATED   : 2020-05-22
//
//***************************************************************************
procedure LoadGridColumnWidths(grid : TDrawGrid;
                               reg : TCustomIniFile;
                               key : String); overload;
var
  iClientSpace : Integer;
  iTotal : Integer;
  n : Integer;

begin
  iClientSpace := GetGridClientWidth(grid);
  iTotal := 0;
  for n := 0 to grid.ColCount-1 do
    Inc(iTotal,reg.ReadInteger(key, 'Col' + IntToStr(n), grid.ColWidths[n]));
  for n := 0 to grid.ColCount-1 do
    grid.ColWidths[n] := iClientSpace *
                         reg.ReadInteger(key, 'Col' + IntToStr(n), grid.ColWidths[n]) div iTotal;
end; // LoadGridColumnWidths

//***************************************************************************
//
//  FUNCTION  : HandleRowColour
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2020-01-28
//
//***************************************************************************
procedure HandleGridRowColour(grid : TSMDBGrid;
                              const mRect: TRect;
                              const Column: TColumn;
                              const State: TGridDrawState);
var
  OddRec : Boolean;

begin
  with grid do
  begin
    OddRec := ((DataSource.DataSet.RecNo mod 2) <> 0);
    with Canvas do
    begin
//      OldBrushColor := Brush.Color;
      if ((gdSelected in State) or
          ((SelectedRows.Count > 1) and (SelectedRows.CurrentRowSelected))) then
      begin
        Brush.Color := clHighlight;
        Font.Color := clWhite;
      end // if
      else
      begin
        if OddRec then
        begin
          if (Column.Color = clWindow) then
          begin
            Brush.Color := clLtLtGrey;
          end // if
          else
          begin
            if (Columns.Count = 1) then
            begin
              Brush.Color := clWindow;
            end // if
            else
            begin
              Brush.Color := ChangeColourShade(clLtLtGrey, -$10);
            end; // else
          end;
        end
        else
        begin
          Brush.Color := Column.Color;
        end;
      end; // else
      FillRect(mRect);
    end; // with
  end; // with
end;

//***************************************************************************
//
//  FUNCTION  : DrawGridCellText
//
//  I/P       : grid : TSMDBGrid - The grid being drawn
//
//              const mRect : TRect - The rectangle of the cell
//
//              const DataCol : Integer - The column index
//
//              const theText : String - the text being drawn
//
//  O/P       : None
//
//  OPERATION : I have observed something odd if the first column is taRightJustify
//              and the second column is taLeftJustify. The Columns[DataCol].Alignment
//              for BOTH columns is reported as taRightJustify.
//
//  UPDATED   : 2020-06-25
//
//***************************************************************************
procedure DrawGridCellText(grid : TSMDBGrid;
                           const mRect : TRect;
                           const DataCol : Integer;
                           const theText : String); overload
var
  iStringWidth : Integer;
  iStringHeight : Integer;

begin
  with grid do
  begin
    iStringWidth := Canvas.TextWidth(theText);
    iStringHeight := Canvas.TextHeight(theText);

    // Left and right justify are surely not hard up against the edge of the
    // rectangle. I'm not sure, at present, how to set their offset, so I
    // have just made it the width of an '0' character
    case Columns[DataCol].Alignment of
      taLeftJustify :
        Canvas.TextOut(mRect.Left + Canvas.TextWidth('0'),
                       mRect.Top + (mRect.Bottom - mRect.Top - iStringHeight) div 2,
                       theText);
      taRightJustify :
        Canvas.TextOut(mRect.Left + (mRect.Right - iStringWidth - Canvas.TextWidth('0')),
                       mRect.Top + (mRect.Bottom - mRect.Top - iStringHeight) div 2,
                       theText);
      else
        Canvas.TextOut(mRect.Left + (mRect.Right - mRect.Left - iStringWidth) div 2,
                       mRect.Top + (mRect.Bottom - mRect.Top - iStringHeight) div 2,
                       theText);
    end; // case
  end; // with
end;

//***************************************************************************
//
//  FUNCTION  : DrawGridCellText
//
//  I/P       : grid : TStringGrid - The grid being drawn
//
//              const mRect : TRect - The rectangle of the cell
//
//              const theText : String - the text being drawn
//
//              const textAlign : TAlignment - The required text alignment
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2021-03-19
//
//***************************************************************************
procedure DrawGridCellText(grid : TStringGrid;
                           const mRect : TRect;
                           const theText : String;
                           const textAlign : TAlignment); overload;
var
  iStringWidth : Integer;
  iStringHeight : Integer;

begin
  with grid do
  begin
    iStringWidth := Canvas.TextWidth(theText);
    iStringHeight := Canvas.TextHeight(theText);

    // Left and right justify are surely not hard up against the edge of the
    // rectangle. I'm not sure, at present, how to set their offset, so I
    // have just made it the width of an '0' character
    case textAlign of
      taLeftJustify :
        Canvas.TextOut(mRect.Left + Canvas.TextWidth('0'),
                       mRect.Top + (mRect.Bottom - mRect.Top - iStringHeight) div 2,
                       theText);
      taRightJustify :
        Canvas.TextOut(mRect.Left + (mRect.Right - iStringWidth - Canvas.TextWidth('0')),
                       mRect.Top + (mRect.Bottom - mRect.Top - iStringHeight) div 2,
                       theText);
      else
        Canvas.TextOut(mRect.Left + (mRect.Right - mRect.Left - iStringWidth) div 2,
                       mRect.Top + (mRect.Bottom - mRect.Top - iStringHeight) div 2,
                       theText);

    // Investigate : Use TextRect instead of TextOut to prevent overflowing of text out of mRect
    end; // case
  end; // with
end;

//***************************************************************************
//
//  FUNCTION  : StrikeoutCell
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2024-03-22
//
//***************************************************************************
procedure StrikeoutCell(cgTarget : TCustomGrid;
                        cell : TRect;
                        const colour : TColor = clRed);
var
  OldPenColour : TColor;

begin
  OldPenColour := TGetCanvas(cgTarget).Canvas.Pen.Color;
  TGetCanvas(cgTarget).Canvas.Pen.Color := clRed;
  TGetCanvas(cgTarget).Canvas.Pen.Width := 1;
  TGetCanvas(cgTarget).Canvas.MoveTo(cell.Left, cell.Top + (cell.Bottom - cell.Top) div 2+1);
  TGetCanvas(cgTarget).Canvas.LineTo(cell.Right, cell.Top + (cell.Bottom - cell.Top) div 2+1);
  TGetCanvas(cgTarget).Canvas.Pen.Color := OldPenColour;
end; // StrikeoutGridLine

//***************************************************************************
//
//  FUNCTION  : TitleClickHandler
//
//  I/P       : grid : TSMDBGrid - the grid to be controlled.
//
//              Column : TColumn - the column whose title has been clicked.
//
//              indexesFWD : array of String - Array of the forward-sorted
//                index names, one for each column.
//                e.g. ['col0', 'col1']
//
//              indexesREV : array of String - Array of the reverse-sorted
//                index names, one for each column. May be empty.
//                e.g. ['col0r', 'col1r'], or []
//
//              bolden : array of Integer - Array of (0-based) indexes, one
//                for each column, indicating the column title index to bolden,
//                and the index name, from the above arrays, to select when the
//                title is clicked.
//                e.g. [0, 1]
//
//
//  O/P       :
//
//  OPERATION : Typically called from within an OnTitleClick event of a grid.
//
//
//  UPDATED   : 2019-11-01
//
//***************************************************************************
procedure TitleClickHandler(grid : TSMDBGrid;
                            Column : TColumn;
                            const indexesFwd : array of String;
                            const indexesRev : array of String;
                            const bolden : array of Integer;
                            searchEdit : TCustomEdit);
var
  n : Integer;
  iColumnIndex : Integer;

begin
  if (Length(bolden) <> grid.Columns.Count) then
  begin
    raise Exception.Create('Invalid grid index indicator set');
  end;

  if ((Length(indexesRev) <> 0) and
      (Length(indexesRev) <> Length(indexesFwd))) then
  begin
    raise Exception.Create('Invalid grid reverse indexes');
  end;

  (grid.DataSource.DataSet as TDBISAMTable).IndexDefs.Update;

  // Determine the index of the column that has been clicked.
  // (This operation assumes that the same field does not appear in more than one column)
  iColumnIndex := 0;
  for n := 0 to grid.Columns.Count-1 do
  begin
    if (grid.Columns[n].FieldName = Column.FieldName) then
    begin
      iColumnIndex := n;
      Break;
    end; // if
  end; // for

  // Check whether this column has an index associated with it.
  // Make no changes if the column does not have an index.
  if (bolden[iColumnIndex] <> -1) then
  begin
    // Remove the bold and sort type indicator (active sorting) from all titles
    for n := 0 to grid.Columns.Count-1 do
    begin
      grid.Columns[n].Title.Font.Style := [];
      grid.Columns[n].Color := clWindow;
      grid.Columns[n].SortType := stNone;
    end; // for
    // Set the title of the required column to Bold font
    grid.Columns[BOLDEN[iColumnIndex]].Title.Font.Style := [fsBold];
    // Set the column background to light grey, to indicate that it is the
    // sorted column
    grid.Columns[BOLDEN[iColumnIndex]].Color := clLtLtGrey;
    // Set the required sort radiobutton
    // rgSort.ItemIndex := RADIOBUTTON[iColumnIndex];

    // Ensure that we do have sufficient indexes defined for this table
    if (iColumnIndex <= High(indexesFwd)) then
    begin
      // This is a click on a column that is currently the index column
      if ((Length(indexesRev) > 0) and
          ((grid.DataSource.DataSet as TDBISAMTable).IndexName = indexesFwd[iColumnIndex])) then
      begin
        (grid.DataSource.DataSet as TDBISAMTable).IndexName := indexesRev[iColumnIndex];
        grid.Columns[BOLDEN[iColumnIndex]].SortType := stAscending;
      end // if
      else
        if ((Length(indexesRev) > 0) and
            ((grid.DataSource.DataSet as TDBISAMTable).IndexName = indexesRev[iColumnIndex])) then
        begin
          (grid.DataSource.DataSet as TDBISAMTable).IndexName := indexesFwd[iColumnIndex];
          grid.Columns[BOLDEN[iColumnIndex]].SortType := stDescending;
        end // if
        else
        begin
          // The sorting column has changed.   Default to forward sorting
          (grid.DataSource.DataSet as TDBISAMTable).IndexName := indexesFwd[iColumnIndex];
          grid.Columns[BOLDEN[iColumnIndex]].SortType := stDescending;
        end; // else

      // Find the IndexDefs index of the given index (! wow)
      n := 0;
      while ((searchEdit <> nil) and
             (n <(grid.DataSource.DataSet as TDBISAMTable).IndexDefs.Count)) do
      begin
        if ((grid.DataSource.DataSet as TDBISAMTable).IndexDefs.Items[n].Name =
            (grid.DataSource.DataSet as TDBISAMTable).IndexName) then
          searchEdit.Text :=
            (grid.DataSource.DataSet as TDBISAMTable).FieldByName(
              TrimFromFirst((grid.DataSource.DataSet as TDBISAMTable).IndexDefs.Items[n].Fields,';')).AsString;
        Inc(n);
      end; // while
    end; // if
  end; // if

  if (searchEdit <> nil) then
  begin
    searchEdit.SetFocus;
  end; // if
end; // TitleClickHandler

//***************************************************************************
//
//  FUNCTION  : SetColumnVisibility
//
//  I/P       : grid : TSMDBGrid - Grid on which to operate
//
//              idxColumn : Integer - Index of the column to be altered
//
//              setVisible : Boolean - TRUE to show the column
//
//              config : TCustomIniFile - Configuration file storing the
//                column visibility and width information. (May be nil)
//
//              sectionColumnVisibility : String - The section storing the
//                column visibility. This may be '', if no storage.
//
//              sectionColumnWidth : String - The section storing the columns
//                widths (ratiometrically). This may be '', if no storage.
//
//  O/P       : None
//
//  OPERATION : This function will typically be followed by a call to the form
//              OnResize event, which should adjust the columns widths, by the
//              ratios stored in sectionColumnWidth.
//
//  UPDATED   : 2020-02-09
//
//***************************************************************************
procedure SetColumnVisibility(grid : TSMDBGrid;
                              idxColumn : Integer;
                              setVisible : Boolean;
                              config : TCustomIniFile;
                              sectionColumnVisibility : String;
                              sectionColumnWidth : String);
var
  c : Integer;
  totalWidth : Integer;
  visibleColumns : Integer;

begin
  if (setVisible) then
  begin
    // Show the column
    // Get info to determine the average (ratiometric) width of the other visible columns.
    totalWidth := 0;
    visibleColumns := 0;
    c := 0;
    while (c < grid.Columns.Count) do
    begin
      if (grid.Columns[c].Visible) then
      begin
        Inc(visibleColumns);
        Inc(totalWidth, grid.Columns[c].Width);
      end; // if
      Inc(c);
    end; // if

    // Show the column, and set its width to the averge of the other visible columns
    grid.Columns[idxColumn].Visible := TRUE;
    if (visibleColumns > 0) then
    begin
      grid.Columns[idxColumn].Width := (totalWidth + visibleColumns div 2) div visibleColumns;
    end // if
    else
    begin
      grid.Columns[idxColumn].Width := 100;
    end;

  end // if
  else
  begin
    // Remove the column
    grid.Columns[idxColumn].Visible := FALSE;
    grid.Columns[idxColumn].Width := 0;
  end;

  // Store the information, as required
  if (config <> nil) then
  begin
    if (sectionColumnVisibility <> '') then
    begin
      config.WriteBool(sectionColumnVisibility, idxColumn.ToString, setVisible);
    end; // if
    if (sectionColumnWidth <> '') then
    begin
      config.WriteInteger(sectionColumnWidth, idxColumn.ToString, grid.Columns[idxColumn].Width);
    end; // if
  end; // if
end; // SetColumnVisibility

//***************************************************************************
//
//  FUNCTION  : StoreGridColumnWidths
//
//  I/P       : grid : TSMDBGrid - Grid on which to operate
//
//              config : TCustomIniFile - Configuration file storing the
//                column visibility and width information. (May be nil)
//
//              sectionColumnWidth : String - The section storing the columns
//                widths (ratiometrically).
//
//  O/P       : None
//
//  OPERATION : Stores a grids column widths, for later use in ratiometrically
//              scaling them to git an available width.
//
//  UPDATED   : 2020-02-09
//
//***************************************************************************
procedure StoreGridColumnWidths(grid : TSMDBGrid;
                                config : TCustomIniFile;
                                sectionColumnWidth : String);
var
  idxColumn : Integer;

begin
  idxColumn := 0;
  while (idxColumn < grid.Columns.Count) do
  begin
    config.WriteInteger(sectionColumnWidth,
                        idxColumn.ToString,
                        grid.Columns[idxColumn].Width);
    Inc(idxColumn);
  end;
  config.UpdateFile;
end; // StoreGridColumnWidths

//***************************************************************************
//
//  FUNCTION  : SaveDBGridColumnWidths
//
//  I/P       : grid : TSMDBGrid - The grid for which column widths are to be saved
//
//              reg : TRegistryIniFile - The RegistryIniFile to be used
//
//              key : String - the key within the above RegistryIniFile to use
//
//  O/P       : None
//
//  OPERATION : Saves the widths of the specified DGgrid in the given
//              registry/registry key
//
//  UPDATED   : 2017-10-16
//
//***************************************************************************
procedure SaveDBGridColumnWidths(grid : TSMDBGrid;
                                 reg : TRegistryIniFile;
                                 key : String); overload;
var
  n : Integer;

begin
  for n := 0 to grid.Columns.Count-1 do
    reg.WriteInteger(key,'Col' + IntToStr(n),grid.Columns[n].Width);
end;
procedure SaveDBGridColumnWidths(grid : TDBGrid;
                                 reg : TRegistryIniFile;
                                 key : String); overload;
var
  n : Integer;

begin
  for n := 0 to grid.Columns.Count-1 do
    reg.WriteInteger(key,'Col' + IntToStr(n),grid.Columns[n].Width);
end;

//***************************************************************************
//
//  FUNCTION  : SelectAll
//
//  I/P       : grid : TSMDBGrid or
//              grid : TDBGrid - The grid for which all records are to be selected.
//
//  O/P       : None
//
//  OPERATION : Selects all records in a grid.
//
//              Sets the grid options to permit MultiSelect.
//              Selects all items in the grid, and leaves the active record
//              as the last in the current index order.
//
//  UPDATED   : 2020-04-28
//
//***************************************************************************
procedure SelectAll(grid : TSMDBGrid); overload;
begin
  grid.Options := grid.Options + [dgMultiSelect];

  grid.DataSource.DataSet.DisableControls;

  grid.SelectedRows.Clear;
  grid.DataSource.DataSet.First;
  while (not grid.DataSource.DataSet.Eof) do
  begin
    grid.SelectedRows.CurrentRowSelected := true;
    grid.DataSource.DataSet.Next;
  end; // while

  grid.DataSource.DataSet.EnableControls;
end;

procedure SelectAll(grid : TDBGrid); overload;
begin
  grid.Options := grid.Options + [dgMultiSelect];

  grid.DataSource.DataSet.DisableControls;

  grid.SelectedRows.Clear;
  grid.DataSource.DataSet.First;
  while (not grid.DataSource.DataSet.Eof) do
  begin
    grid.SelectedRows.CurrentRowSelected := true;
    grid.DataSource.DataSet.Next;
  end; // while

  grid.DataSource.DataSet.EnableControls;
end;

end.
