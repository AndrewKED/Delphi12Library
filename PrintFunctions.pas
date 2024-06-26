unit PrintFunctions;

//***************************************************************************
//
// DESCRIPTION:
//  Print-orientated routines, based on the use of the TPrintPreview component
//  from the Print Preview Suite.   See http://www.delphiarea.com/products
//  Operates on V4.60 of this component.
//
// TO BE DONE:
//
//  * If cells in a row occupy differing vertical height (as is the case when
//    there are different numbers of lines in a cell, or different font sizes),
//    any background colouring only covers the vertical height of each cell, and
//    not of the whole row.
//    To fix this we need to scan through the cells before doing the border, and
//    establish the lowest position in each cell.   Then we colour in any that are
//    not as low as the lowest one.
//
// VERSIONS:
//
//    Update Date : 2008-08-26
//    Changes Made :
//      * Added PrintMemo
//      * When defining a page layout, set a default paragraph layout too, based
//        on the page layout.
//
//    Update Date : 2007/04/03
//    Changes Made :
//      * Correct an error in handling of shading of table column header cells.
//
//    Update Date : 2007/03/15
//    Changes Made :
//      * Moved SetDefaultPrinter to Print_Ops
//      * Added PrintBlank
//
//    Update Date : 2006/10/04
//    Changes Made :
//      * Fixed up the background colouring in cells where the content of cells
//        has varying height across a row.
//
//    Update Date : 2005/11/10
//    Changes Made :
//      * Added SetDefaultPrinter
//
//    Update Date : 2005/10/28
//    Changes Made :
//      * Changed the name of function SetFixedPitchFont to AutoDefineFWParagraph.
//      * Changed the name of bPFFixedLineLength to bPFAutoSetFontPitch.
//      * Altered parameters to PrintTextFile, and other modifications, to permit
//        an override of the automated font pitch creation.
//
//    Update Date : 2005/04/19
//    Changes Made :
//      * Added IOResult checking and message to PrintTextFile

//    Update Date : 2005/04/15
//    Changes Made :
//      * Adjustments to TextOut transparency and background colour filling, to
//        look nice over a watermark.
//      * Complete the Watermark.
//
//    Update Date : 2005/03/30
//    Changes Made :
//      * Initialise HeaderLine_func to nil in initialization.
//
//    Update Date : 2005/03/03
//    Changes Made :
//      * Fixed handling of multi-line cells, where a line does not fit in.
//      * Add a facility to show "Page x of y" at the bottom of the page.
//      * When wiping out a partially completed table row (because of a page
//        break, go down to iPrnAreaBottom and not iBottomBorderPos.
//
//
//    Update Date : 2005/01/12
//    Changes Made :
//      * Added this header
//
//***************************************************************************

interface

// Ensure Graphics is AFTER Windows, since both have a TBitMap type.
uses Windows, Classes, Printers, Preview, Forms, Controls, Graphics, StdCtrls,
     Vcl.ComCtrls, DKLang;

const
  MAX_TABLES = 10;
  MAX_COLUMNS = 40;
  PF_ALL_PAGES = 1000000; // A large number, to indicate printing of all pages in report

// PRINT FUNCTION VALUE IDS
//------------------------------------------------------------------------------
  PF_LEFT_MARGIN    = 0;
  PF_TOP_MARGIN     = 1;
  PF_RIGHT_MARGIN   = 2;
  PF_BOTTOM_MARGIN  = 3;
  PF_WIDTH_MARGIN   = 4;
  PF_HEIGHT_MARGIN  = 5;
  PF_LEFT_AREA      = 6;
  PF_TOP_AREA       = 7;
  PF_RIGHT_AREA     = 8;
  PF_BOTTOM_AREA    = 9;
  PF_WIDTH_AREA     = 10;
  PF_HEIGHT_AREA    = 11;
  PF_YPOS           = 12;
  PF_TABLE_COLUMNS  = 13;
  PF_TABLE_LEFT     = 14;
  PF_TABLE_RIGHT    = 15;
  PF_TABLE_WIDTH    = 16;

type
  TSimpleHdrFunction = function : String;
  TRowOfText = array[1..MAX_COLUMNS] of string;
  TRowOfAlignment = array[1..MAX_COLUMNS] of TAlignment;
  TRowOfStyle = array[1..MAX_COLUMNS] of TFontStyles;
  TRowOfFontSize = array[1..MAX_COLUMNS] of integer;
  TRowOfColour = array[1..MAX_COLUMNS] of TColor;
  TPrintOverrideOption = (PRNT_OVR_FONT_SIZE,
                          PRNT_OVR_FONT_COLOUR,
                          PRNT_OVR_FONT_BOLD,
                          PRNT_OVR_FONT_ITALIC,
                          PRNT_OVR_FONT_UNDERLINE,
                          PRNT_OVR_FONT_STRIKEOUT,
                          PRNT_OVR_BACKGROUND_COLOUR,
                          PRNT_OVR_ALIGNMENT);
  TPrintOverrides = array of TPrintOverrideOption;
  TPrintOverrideValues = array of Variant;
  TPrintFitImage = (PRNT_IMG_FIT_ALL,
                    PRNT_IMG_FIT_WIDTH,
                    PRNT_IMG_FIT_HEIGHT);

var
  bPFAutoSetFontPitch : boolean;        // TRUE if a specified number of characters are required per line
  iPFCharsPerLine  : word;              // Number of characters in a fixed font report line
  SimpleHeader_Func : TSimpleHdrFunction; // A function that generates simple string run-on header
  ComplexHeader : procedure;              // A procedure that draws a complex run-on header (may include paragraphs and tables)

procedure BeginDocument;
procedure EndDocument;
procedure DefinePageLayout(pToOutput : Pointer;
                           poDirection : TPrinterOrientation;
                           iTopMargin : Integer;
                           iBottomMargin : Integer;
                           iLeftMargin : Integer;
                           iRightMargin : Integer;
                           bBorder : boolean;
                           bAllowForPageNumbering : boolean;
                           sLogo : String;
                           sPNFontName : String;
                           iPNFontSize : Integer;
                           cPNFontColour : TColor;
                           sfsPNFontStyle : TFontStyles;
                           taPNAlignment : TAlignment;
                           iLogoWidth : Integer;
                           taLogoAlignment : TAlignment;
                           sWatermark : string);
procedure DefineParagraph(sFontName : String;
                          iFontSize : Integer;
                          cFontColour : TColor;
                          sfsFontStyle : TFontStyles;
                          taAlignment : TAlignment;
                          iSpaceBeforePt : Integer;
                          iSpaceAfterPt : Integer;
                          iLeftMM100 : Integer;
                          iRightMM100 : Integer;
                          iHangingIndentLeftMM100 : Integer;
                          cBorderColour : TColor;
                          iTopBorderTWIPS : Integer;
                          iBottomBorderTWIPS : Integer;
                          iLeftBorderTWIPS : Integer;
                          iRightBorderTWIPS : integer); overload;
procedure DefineParagraph(sFontName : String;
                          iFontSize : Integer;
                          cFontColour : TColor;
                          sfsFontStyle : TFontStyles;
                          taAlignment : TAlignment;
                          iSpaceBeforePt : Integer;
                          iSpaceAfterPt : Integer;
                          iLeftMM100 : Integer;
                          iRightMM100 : Integer;
                          iHangingIndentLeftMM100 : Integer;
                          cBorderColour : TColor;
                          iTopBorderTWIPS : Integer;
                          iBottomBorderTWIPS : Integer;
                          iLeftBorderTWIPS : Integer;
                          iRightBorderTWIPS : integer;
                          cBackgroundColour : TColor); overload;
procedure DrawPageBorder;
//procedure DrawPageNumber;
procedure InsertPageNumbers;
procedure DrawPageLogo;
procedure DrawPageWatermark;
procedure AutoDefineFWParagraph(sFontName : string);
procedure StartNewPage(bFirstPage : boolean);
procedure PrintParagraph(sParagraph : String;
                         bKeepLeadingSpaces : Boolean = TRUE;
                         overrideIDs : TPrintOverrides = [];
                         overrideValues : TPrintOverrideValues = []);
procedure PrintRichParagraph(creHolder : TCustomRichEdit);
procedure PrintBlank(iPoint : integer);
procedure InsertHorizontalPageLine(lineTWIPS : Integer);
procedure PrintTextFile(sReportFileName : String;
                        sFontName : String;
                        iFontPitch : integer);
procedure PrintRTFFile(sFileName : string);
procedure PrintMemo(memToPrint : TMemo;
                    sFontName : String;
                    iFontPitch : integer);
procedure ClearTabList;
procedure AddTab(iNewTabPosition : integer);
procedure UseTable(idxTable : Integer);
procedure DefineTable(iTableLeft : Integer;
                      iColumnWidths : array of integer);
procedure DefineTableHeaderColumn(iColumnNumber : Integer;
                                  sFontName : String;
                                  iFontSize : Integer;
                                  cFontColour : TColor;
                                  sfsFontStyle : TFontStyles;
                                  taAlignment : TAlignment;
                                  iTopGutterPt : Integer;
                                  iBottomGutterPt : Integer;
                                  iHangingIndentLeftMM100 : Integer;
                                  iLRGutterWidthMM100 : Integer;
                                  iInterParaPt : Integer;
                                  cBorderColour : TColor;
                                  iTopBorderTWIPS : Integer;
                                  iBottomBorderTWIPS : Integer;
                                  iLeftBorderTWIPS : Integer;
                                  iRightBorderTWIPS : Integer;
                                  cBackgroundColour : TColor);
procedure DefineTableBodyColumn(iColumnNumber : Integer;
                                sFontName : String;
                                iFontSize : Integer;
                                cFontColour : TColor;
                                sfsFontStyle : TFontStyles;
                                taAlignment : TAlignment;
                                iTopGutterPt : Integer;
                                iBottomGutterPt : Integer;
                                iHangingIndentLeftMM100 : Integer;
                                iLRGutterWidthMM100 : Integer;
                                iInterParaPt : Integer;
                                cBorderColour : TColor;
                                iTopBorderTWIPS : Integer;
                                iBottomBorderTWIPS : Integer;
                                iLeftBorderTWIPS : Integer;
                                iRightBorderTWIPS : Integer;
                                cBackgroundColour : TColor);
procedure SetBodyRowColour(cBackgroundColour : TColor);
procedure StartTable(allowRowPageSpanning : boolean;
                     startPagesWithHeaderRow : boolean);
procedure StoreTextIntoHeaderCell(sCellText : string;
                                  overrideIDs : TPrintOverrides = [];
                                  overrideValues : TPrintOverrideValues = []);
procedure InsertTextIntoHeaderCell(sCellText : string;
                                   overrideIDs : TPrintOverrides = [];
                                   overrideValues : TPrintOverrideValues = []);
procedure InsertTextIntoBodyCell(sCellText : string;
                                   overrideIDs : TPrintOverrides = [];
                                   overrideValues : TPrintOverrideValues = []);
function BodyRowComplete : Boolean;
procedure CompleteBodyRow(sFill : string);
procedure PrintTableHeader;
procedure EndTable;
function PrintGraphic(iX,iY : Integer;
                  iWidth : Integer;
                  gPicture : TGraphic) : Integer; overload;
function PrintGraphic(iX,iY : Integer;
                  iWidth : Integer;
                  iHeight : Integer;
                  gPicture : TGraphic;
                  stretch : TPrintFitImage = PRNT_IMG_FIT_ALL) : Integer; overload;
function MM100ToBottomOfPage : Integer;
function PageBreakIfLTmm(MinMMRemaining : integer) : boolean;
function GetPrnFnValue(iValueID : integer) : Integer;
procedure SetPrnFnValue(valueID : Integer;
                        newValue : Integer);
procedure SetLanguage(lcMain : TDKLanguageController);
procedure PrintPreview2PDF(ppToPDF : TPrintPreview;
                           FirstPage : Integer;
                           LastPage : Integer;
                           sDestinationFile : String;
                           sProducer : AnsiString;
                           sAuthor : AnsiString;
                           sCreator : AnsiString;
                           sTitle : AnsiString;
                           sSubject : AnsiString) overload;
procedure PrintPreview2PDF(ppToPDF : TPrintPreview;
                           sDestinationFile : String;
                           sProducer : AnsiString;
                           sAuthor : AnsiString;
                           sCreator : AnsiString;
                           sTitle : AnsiString;
                           sSubject : AnsiString) overload;
function PrintPreview2Printer(ppToPrint : TPrintPreview) : Integer;

implementation

uses Dialogs, SysUtils, StrUtils, Math, System.UITypes,
     Str_Ops, File_Ops;

const
  MAX_TABS = 50;

  INNER_BORDER_THICKNESS = 20;      // 0.2mm
  OUTER_BORDER_THICKNESS = 60;      // 0.6mm
  OUTER_BORDER_OFFSET = 80;         // 0.8mm

type
  TParagraph = record
    iSpaceBeforePt : Integer;       // Points spacing to be left before starting a paragraph
    iSpaceAfterPt : Integer;        // Points spacing to be left after a paragraph break
    iLeftMM100 : Integer;           // Left indent of the paragraph from left printing margin in 100s of mm
    iRightMM100 : Integer;          // Right indent of the paragraph from printable edge in 100s of mm
    iHangingIndentLeftMM100 : Integer;  // Left indent of the paragraph from iLeftMM100 in 100ths of mm for line 2 onwards
    cFontColour : TColor;
    sFontName : String;
    iFontSize : Integer;
    sfsFontStyle : set of TFontStyle;
    taAlignment : TAlignment;
    cBorderColour : TColor;
    iTopBorderTWIPS : Integer;
    iBottomBorderTWIPS : Integer;
    iLeftBorderTWIPS : Integer;
    iRightBorderTWIPS : Integer;
    cBackgroundColour : TColor;
    end; // record
  TTableColumn = record
    sFontName : String;
    iFontSize : Integer;
    cFontColour : TColor;
    sfsFontStyle : set of TFontStyle;
    taAlignment : TAlignment;           // Alignment of text within the cell
    iTopGutterPt : Integer;             // Points spacing beween border and top of first line of text
    iBottomGutterPt : Integer;          // Points spacing between bottom of last line in row and border
    iColumnLeftMM100 : Integer;         // Position of left border in 100s of mm from printable edge
    iColumnRightMM100 : Integer;        // Position of right border in 100s of mm from printable edge
    iHangingIndentLeftMM100 : Integer;  // Left indent of the paragraph from iLeftMM100 in 100ths of mm for line 2 onwards
    iLRGutterWidthMM100 : Integer;      // Distance, in 100ths of mm, between L/R border and L/R edge of text
    iInterParaPt : Integer;             // Point spacing between paragraphs within a cell
    cBorderColour : TColor;
    iTopBorderTWIPS : Integer;
    iBottomBorderTWIPS : Integer;
    iLeftBorderTWIPS : Integer;
    iRightBorderTWIPS : Integer;
    cBackgroundColour : TColor;
    end; // record
  TTableColumns = array[1..MAX_COLUMNS] of TTableColumn;
  TPrintedTable = record
    active : Boolean;                   // TRUE when we are busy generating/creating this table
    iTableColumns : shortint;           // The number of columns in the current table
    siCurrentBodyColumn : shortint;     // Column number in active table (0 = no row active, >0 = text in row)
    siCurrentHeaderColumn : shortint;   // Column number in active table (0 = no header row active, >0 = text in header row)
    headerColumns : TTableColumns;      // Default definitions of the header columns
    bodyColumns : TTableColumns;        // Default definitions of the body columns
    headerRowText : TRowOfText;         // Text in a header row
    bodyRowText : TRowOfText;           // Text in current body row
    headerAlignment : TRowOfAlignment;  // Alignment to be applied to the header row
    bodyAlignment : TRowOfAlignment;    // Alignment to be applied to the body row
    headerStyle : TRowOfStyle;          // Font Style to be applied to the header row
    bodyStyle : TRowOfStyle;            // Font Style to be applied to the body row
    headerBGColour : TRowOfColour;      // Background colour to be applied to the header row
    bodyBGColour : TRowOfColour;        // Background colour to be applied to the body row
    headerFGColour : TRowOfColour;      // Foreground (font) colour to be applied to the header row
    bodyFGColour : TRowOfColour;        // Foreground (font) colour to be applied to the body row
    headerFontSize : TRowOfFontSize;    // Font Size to be applied to the header row
    bodyFontSize : TRowOfFontSize;      // Font Size to be applied to the body row
    bPermitPageBreakInRow : boolean;    // Set if we allow rows to span a page break
    bReprintHeaderRow : boolean;        // Set if we must print column headers
    end; // record
  TPtrPrintPreview = ^TPrintPreview;

var
  lcPrintFunctions : TDKLanguageController;
  ppOutput : TPtrPrintPreview;
  iPageLeftMargin : Integer;      // The margins for any image placed on the TPreview control
  iPageRightMargin : Integer;     // Values in mmHiMetric i.e. mm * 100
  iPageTopMargin : Integer;       //
  iPageBottomMargin : Integer;    //
  iPageWidthMargin : Integer;     //
  iPageHeightMargin : Integer;    //

  iPrnAreaLeft : Integer;         // The margins for printing, allowing for any borders that may
  iPrnAreaRight : Integer;        // be imposed on each page.   If there is no border, the print
  iPrnAreaTop : Integer;          // area values are the same as the margin values.
  iPrnAreaBottom : Integer;       // Values in mmHiMetric i.e. mm * 100
  iPrnAreaWidth : Integer;        //
  iPrnAreaHeight : Integer;       //

  iCurrentYPos : Integer;         // Current y position of text in printing
  tpParagraph : TParagraph;       // Defines the output control of a block of text
  ct : Integer;                   // The current table
  tptTable : array[0..MAX_TABLES-1] of TPrintedTable; // Definitions of tabulated text layout

  bFirstParaLine : boolean;       // Indicates when we are printing the first line in a paragraph.

  bPageBorder : boolean;          // TRUE if borders are required on the pages
  bPageNumbering : boolean;       // TRUE if the intention is to insert page numbers (adjusts bottom border)
  sPageLogo : String;             // The resource name of the logo BMP, or empty string if none
  sPageNumFontName : String;
  iPageNumFontSize : Integer;
  cPageNumFontColour : TColor;
  sfsPageNumFontStyle : TFontStyles;
  taPageNumAlignment : TAlignment;
  iPageLogoWidth : Integer;       // Width of the logo space, in 100ths of mm
  taPageLogoAlignment : TAlignment;
  sPageWatermark : String;        // The resource name of the watermark BMP, or empty string if none

  sAutoSizeFWFontName : String;   // The font to be used if using auto-sized fixed line lengths
  bAutoHeaders : boolean;         // Set if we are printing out the contents of a text file

  siCurrentTabStop : shortint;    // Tabstop number of the left edge of printing
  iaTabs : array[1..MAX_TABS] of integer;

  sPageXofYText : String;         // Used in multi-language applications
  sPDFError : String;

//***************************************************************************
//
//  FUNCTION  : PrintParagraphLine
//
//  I/P       : sLineToPrint(string) - The line of text to be printed.
//                It should be known to fit in the available width
//                using the current font parameters.
//
//              tpParagraph(record) - Descriptive parameters of the
//                current paragraph.
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2004/02/16
//
//***************************************************************************
procedure PrintParagraphLine(sLineToPrint : String;
                             TextAlignment : TAlignment);
var
  iLineLength : Integer;
begin
  iLineLength := ppOutput^.Canvas.TextWidth(sLineToPrint);

  // Configure for background colour highlighting. If white, make the brush clear
  // so that a watermark could show through.
  if (ppOutput^.Canvas.Brush.Color = clWhite) then
    ppOutput^.Canvas.Brush.Style := bsClear
  else
    ppOutput^.Canvas.Brush.Style := bsSolid;

  case (TextAlignment) of
    taRightJustify :
      ppOutput^.Canvas.TextOut(iPrnAreaRight -
                               ppOutput^.ConvertX(tpParagraph.iRightMM100,mmHiMetric,ppOutput^.Units) -
                               iLineLength,iCurrentYPos,sLineToPrint);
    taCenter :
        ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                                 ppOutput^.ConvertX(tpParagraph.iLeftMM100,mmHiMetric,ppOutput^.Units) +
                                 (iPrnAreaWidth -
                                  ppOutput^.ConvertX(tpParagraph.iLeftMM100,mmHiMetric,ppOutput^.Units) -
                                  ppOutput^.ConvertX(tpParagraph.iRightMM100,mmHiMetric,ppOutput^.Units) - iLineLength) div 2,iCurrentYPos,
                                  sLineToPrint)
    else
    begin
      // Default is left justification
      if (siCurrentTabStop = 0) then
      begin
        // Handle hanging indents
        if (bFirstParaLine) then
          ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                                   ppOutput^.ConvertX(tpParagraph.iLeftMM100,mmHiMetric,ppOutput^.Units),
                                   iCurrentYPos,sLineToPrint)
        else
          ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                                   ppOutput^.ConvertX(tpParagraph.iLeftMM100,mmHiMetric,ppOutput^.Units) +
                                   ppOutput^.ConvertX(tpParagraph.iHangingIndentLeftMM100,mmHiMetric,ppOutput^.Units),
                                   iCurrentYPos,sLineToPrint)
      end // if
      else
        // Handle Tab stop positions
        ppOutput^.Canvas.TextOut(iPrnAreaLeft + iaTabs[siCurrentTabStop],
                                 iCurrentYPos,sLineToPrint)
    end; // if
  end; // case
end; // PrintParagraphLine

//***************************************************************************
//
//  FUNCTION  : BeginDocument
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Begins a document on the defined TPtrPrintPreview object.
//              This should have been defined in DefinePageLayout() first.
//
//  UPDATED   : 2019-09-12
//
//***************************************************************************
procedure BeginDocument;
begin
  if (Assigned(ppOutput)) then
    ppOutput.BeginDoc
  else
    raise Exception.Create('TPtrPrintPreview document output not specified');
end; // BeginDocument

//***************************************************************************
//
//  FUNCTION  : EndDocument
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Ends a document and tidies up.
//
//  UPDATED   : 2020-05-22
//
//***************************************************************************
procedure EndDocument;
begin
  if (Assigned(ppOutput)) then
    ppOutput.EndDoc;
  // Ensure that these are not carried over from one document to the next
  SimpleHeader_Func := nil;
  ComplexHeader := nil;
end;

//***************************************************************************
//
//  FUNCTION  : DefinePageLayout
//
//  I/P       : pToOutput - Pointer to the PrintPreview component being set up.
//
//              poDireciton - The orientation of the printout.
//
//              liTopMargin - Printing starts this far from the top of the
//                page (in 100ths of mm).   -1 for the default.
//
//              liBottomMargin - Printing stops this far from the bottom
//                of the page (in 100ths of mm).   -1 for the default.
//
//              liLeftMargin - Printing starts this far from the left of the
//                page (in 100ths of mm).   -1 for the default.
//
//              liRightMargin - Printing stops this far from the right of the
//                page (in 100ths of mm).   -1 for the default.
//
//              bBorder - TRUE if a border is to be printed around the
//                page.
//
//              bAllowForPageNumbering - TRUE if the page must be numbered.
//                (This later causes adjustment of the lower page border)
//
//              sLogo (string) - The name of a bitmap in the resource
//                file, to be printed at the bottom of each page.
//
//              sPNFontName (string) - Font to be used for the page numbering
//                and default paragraph
//
//              iPNFontSize (integer) - Size to be used for the page numbering
//                and default paragraph
//
//              cPNFontColour (TColor) - Colour to be used for the page numbering
//                and default paragraph
//
//              sfsPNFontStyle (TFontStyles) - Font Style to be used for the page numbering
//                and default paragraph
//
//              siPNAlignment (shortint) - Alignment to be used for the page numbering
//
//              iLogoWidth (integer) -
//
//              siLogoAlignment (shortint) -
//
//              sWatermark (string) -
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED     :   2004/09/14
//
//***************************************************************************
procedure DefinePageLayout(pToOutput : Pointer;
                           poDirection : TPrinterOrientation;
                           iTopMargin : Integer;
                           iBottomMargin : Integer;
                           iLeftMargin : Integer;
                           iRightMargin : Integer;
                           bBorder : boolean;
                           bAllowForPageNumbering : boolean;
                           sLogo : String;
                           sPNFontName : String;
                           iPNFontSize : Integer;
                           cPNFontColour : TColor;
                           sfsPNFontStyle : TFontStyles;
                           taPNAlignment : TAlignment;
                           iLogoWidth : Integer;
                           taLogoAlignment : TAlignment;
                           sWatermark : string);
begin
  // Specify the control being modified
  ppOutput := TPtrPrintPreview(pToOutput);
  // Store whether a border is to be added to each page
  bPageBorder := bBorder;
  // Store whether page numbers are to be printed on each page, and the font information
  bPageNumbering := bAllowForPageNumbering;
  sPageLogo := sLogo;
  sPageNumFontName := sPNFontName;
  iPageNumFontSize := iPNFontSize;
  cPageNumFontColour := cPNFontColour;
  sfsPageNumFontStyle := sfsPNFontStyle;
  taPageNumAlignment := taPNAlignment;
  iPageLogoWidth := iLogoWidth;
  taPageLogoAlignment := taLogoAlignment;
  sPageWatermark := sWatermark;

  // Set the page orientation
  ppOutput^.Orientation := poDirection;

  // Set the left margin position, using default values, if required, that are suitable for binding
  if (iLeftMargin = -1) then
  begin
    if (poDirection = poPortrait) then
      iPageLeftMargin := ppOutput^.ConvertX(1600,mmHiMetric,ppOutput^.Units)
    else
      iPageLeftMargin := ppOutput^.ConvertX(1000,mmHiMetric,ppOutput^.Units)
  end
  else
    iPageLeftMargin := ppOutput^.ConvertX(iLeftMargin,mmHiMetric,ppOutput^.Units);

  // Set the top margin position, using default values, if required, that are suitable for binding
  if (iTopMargin = -1) then
  begin
    if (poDirection = poPortrait) then
      iPageTopMargin := ppOutput^.ConvertY(1000,mmHiMetric,ppOutput^.Units)
    else
      iPageTopMargin := ppOutput^.ConvertY(1600,mmHiMetric,ppOutput^.Units)
  end // if
  else
    iPageTopMargin := ppOutput^.ConvertY(iTopMargin,mmHiMetric,ppOutput^.Units);

  // Set the right margin position, using default values, if required.
  if (iRightMargin = -1) then
    iPageRightMargin := ppOutput^.PaperWidth - ppOutput^.ConvertX(1000,mmHiMetric,ppOutput^.Units)
  else
    iPageRightMargin := ppOutput^.PaperWidth - ppOutput^.ConvertX(iRightMargin,mmHiMetric,ppOutput^.Units);

  // Set the bottom margin position, using default values, if required.
  if (iBottomMargin = -1) then
    iPageBottomMargin := ppOutput^.PaperHeight - ppOutput^.ConvertY(1000,mmHiMetric,ppOutput^.Units)
  else
    iPageBottomMargin := ppOutput^.PaperHeight - ppOutput^.ConvertY(iBottomMargin,mmHiMetric,ppOutput^.Units);

  iPageWidthMargin := iPageRightMargin - iPageLeftMargin;
  iPageHeightMargin := iPageBottomMargin - iPageTopMargin;

  // Adjust the text printable area as required, depending on whether a border is in use or not.
  if (bPageBorder) then
  begin
    // With a border, remove 7.5mm/5.0mm from the X/Y printable area
    iPrnAreaLeft := iPageLeftMargin + ppOutput^.ConvertX(750,mmHiMetric,ppOutput^.Units);
    iPrnAreaRight := iPageRightMargin - ppOutput^.ConvertX(750,mmHiMetric,ppOutput^.Units);
    iPrnAreaTop := iPageTopMargin + ppOutput^.ConvertX(500,mmHiMetric,ppOutput^.Units);
    iPrnAreaBottom := iPageBottomMargin - ppOutput^.ConvertX(500,mmHiMetric,ppOutput^.Units);
  end
  else
  begin
    // With no border, printing may take place right up to the margin positions
    iPrnAreaLeft := iPageLeftMargin;
    iPrnAreaRight := iPageRightMargin;
    iPrnAreaTop := iPageTopMargin;
    iPrnAreaBottom := iPageBottomMargin;
  end; // else

  // Adjust the bottom printing limit, depending on whether a page number
  // will be inserted, or not
  if (bPageNumbering) then
  begin
    // Set the font, so that we can determine the height
    ppOutput^.Canvas.Font.Name := sPageNumFontName;
    ppOutput^.Canvas.Font.Size := iPageNumFontSize;
    ppOutput^.Canvas.Font.Style := sfsPageNumFontStyle;
    iPrnAreaBottom := Min(iPrnAreaBottom,
                          iPageBottomMargin - ppOutput^.Canvas.TextHeight('A') -
                          ppOutput^.ConvertX(500,mmHiMetric,ppOutput^.Units));
  end; // if

  iPrnAreaWidth := iPrnAreaRight - iPrnAreaLeft;
  iPrnAreaHeight := iPrnAreaBottom - iPrnAreaTop;

  // Default to user definition of the font parameters.
  bPFAutoSetFontPitch := FALSE;

  // Default to no automatic insertion of headers in run-on pages
  bAutoHeaders := FALSE;

  // Define a paragraph based on these default settings (so that printing of
  // text files and other such operations will use the settings defined for
  // the page)
  DefineParagraph(sPNFontName, iPNFontSize, cPNFontColour, sfsPNFontStyle,
                  taLeftJustify,
                  0,0,
                  0,0,0,
                  clBlack,
                  0,0,0,0);
end; // DefinePageLayout

//***************************************************************************
//
//  FUNCTION    :   DefineParagraph
//
//  I/P         :   sFontName(string) - Name of the font to be used
//
//                      iFontSize(integer) - Point size of the font
//
//                      cFontColour(TColor) - Colour of the font
//
//                      sfsFontStyle(set of TFontStyle) - Font style
//
//                      siAlignment(shortint) - Line alignment
//
//                      iPointsBefore(integer) - Point spacing before the paragraph
//
//                      iPointsAfter(integer) - Point spacing after the paragraph
//
//                      iMM100Left(integer) - Left indent of the paragraph
//
//                      iMM100Right(integer) - Right Indent of the paragraph
//
//                      iHangingIndentMM100Left(integer) - Amount to indent 2nd and later
//                        lines in a paragraph.
//
//                      cBorderColour(TColour) - The colour to be used for a border
//
//                      iTopBorderTWIPS(integer) - Top border width in 1/20ths of a point.
//
//                      iBottomBorderTWIPS(integer) -  Bottom border width in 1/20ths of a point.
//
//                      iLeftBorderTWIPS(integer) -  Left border width in 1/20ths of a point.
//
//                      iRightBorderTWIPS(integer) -  Right border width in 1/20ths of a point.
//
//  O/P         :   None.
//
//  OPERATION   :   Stores the paragraph information to be used for future
//                      printing.
//
//  UPDATED     :   2004/02/17
//
//***************************************************************************
procedure DefineParagraph(sFontName : String;
                          iFontSize : Integer;
                          cFontColour : TColor;
                          sfsFontStyle : TFontStyles;
                          taAlignment : TAlignment;
                          iSpaceBeforePt : Integer;
                          iSpaceAfterPt : Integer;
                          iLeftMM100 : Integer;
                          iRightMM100 : Integer;
                          iHangingIndentLeftMM100 : Integer;
                          cBorderColour : TColor;
                          iTopBorderTWIPS : Integer;
                          iBottomBorderTWIPS : Integer;
                          iLeftBorderTWIPS : Integer;
                          iRightBorderTWIPS : integer); overload;
begin
  tpParagraph.sFontName := sFontName;
  tpParagraph.iFontSize := iFontSize;
  tpParagraph.cFontColour := cFontColour;
  tpParagraph.sfsFontStyle := sfsFontStyle;
  tpParagraph.taAlignment := taAlignment;
  tpParagraph.iSpaceBeforePt := iSpaceBeforePt;
  tpParagraph.iSpaceAfterPt := iSpaceAfterPt;
  tpParagraph.iLeftMM100 := iLeftMM100;
  tpParagraph.iRightMM100 := iRightMM100;
  tpParagraph.iHangingIndentLeftMM100 := iHangingIndentLeftMM100;
  tpParagraph.cBorderColour := cBorderColour;
  tpParagraph.iTopBorderTWIPS := iTopBorderTWIPS;
  tpParagraph.iBottomBorderTWIPS := iBottomBorderTWIPS;
  tpParagraph.iLeftBorderTWIPS := iLeftBorderTWIPS;
  tpParagraph.iRightBorderTWIPS := iRightBorderTWIPS;
  tpParagraph.cBackgroundColour := clWhite;
end; // DefineParagraph

procedure DefineParagraph(sFontName : String;
                          iFontSize : Integer;
                          cFontColour : TColor;
                          sfsFontStyle : TFontStyles;
                          taAlignment : TAlignment;
                          iSpaceBeforePt : Integer;
                          iSpaceAfterPt : Integer;
                          iLeftMM100 : Integer;
                          iRightMM100 : Integer;
                          iHangingIndentLeftMM100 : Integer;
                          cBorderColour : TColor;
                          iTopBorderTWIPS : Integer;
                          iBottomBorderTWIPS : Integer;
                          iLeftBorderTWIPS : Integer;
                          iRightBorderTWIPS : integer;
                          cBackgroundColour : TColor); overload;
begin
 DefineParagraph(sFontName, iFontSize, cFontColour, sfsFontStyle, taAlignment,
                 iSpaceBeforePt, iSpaceAfterPt,
                 iLeftMM100, iRightMM100, iHangingIndentLeftMM100,
                 cBorderColour,
                 iTopBorderTWIPS, iBottomBorderTWIPS, iLeftBorderTWIPS, iRightBorderTWIPS);
 tpParagraph.cBackgroundColour := cBackgroundColour;
end; // DefineParagraph

//***************************************************************************
//
//  FUNCTION  : AutoDefineFWParagraph
//
//  I/P       : sFontName (string) - The font to be used when printing
//
//  O/P       : Modifications to Printer.Canvas.
//
//  OPERATION : Defines the paragraph to use the given font (typically a
//              fixed pitch font), in black bold, with a suitable left
//              margin and the font size set to fit in the given line width.
//
//  UPDATED   : 2005/10/28
//
//***************************************************************************
procedure AutoDefineFWParagraph(sFontName : string);
begin
  // Start off with a large font size, and work down
  ppOutput^.Canvas.Font.Name := sFontName;
  ppOutput^.Canvas.Font.Style := [fsBold];
  ppOutput^.Canvas.Font.Color := clBlack;
  ppOutput^.Canvas.Font.Size := 72;
  // Decrease the font size until the given number of characters fit in the printable area.
  repeat
    ppOutput^.Canvas.Font.Size := ppOutput^.Canvas.Font.Size-1;
    ppOutput^.Update;
  until ((iPFCharsPerLine * ppOutput^.Canvas.TextWidth('A')) <= iPrnAreaWidth);

  // Define the paragraph with the new font size and a left indent that will ensure that
  // the space front-padded lines are actually centred.
  DefineParagraph(sFontName,ppOutput^.Canvas.Font.Size,clBlack,[fsBold],
                  taLeftJustify,
                  0,0,
                  ppOutput^.ConvertX((iPrnAreaWidth - (iPFCharsPerLine * ppOutput^.Canvas.TextWidth('A'))) DIV 2,
                                     ppOutput^.Units,mmHiMetric),0,
                  0,
                  clBlack,0,0,0,0);
end; // AutoDefineFWParagraph

//***************************************************************************
//
//  FUNCTION  : DrawPageBorder
//
//  I/P       : none.
//
//  O/P       :
//
//  OPERATION : Draws a black border around the print area with a
//              0.2mm outer pen and a 0.6mm inner pen.
//
//  UPDATED   : 2004/02/13
//
//***************************************************************************
procedure DrawPageBorder;
var
  iSize : Integer;

begin
  // Set a 0.2mm wide pen
  ppOutput^.Canvas.Pen.Color := clBlack;
  ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(INNER_BORDER_THICKNESS,mmHiMetric,ppOutput^.Units);
  // Draw a box around the page margin
  ppOutput^.Canvas.MoveTo(iPageLeftMargin,iPageTopMargin);
  ppOutput^.Canvas.LineTo(iPageLeftMargin,iPageBottomMargin);
  ppOutput^.Canvas.LineTo(iPageRightMargin,iPageBottomMargin);
  ppOutput^.Canvas.LineTo(iPageRightMargin,iPageTopMargin);
  ppOutput^.Canvas.LineTo(iPageLeftMargin,iPageTopMargin);

  // Set a 0.6mm wide pen
  ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(OUTER_BORDER_THICKNESS,mmHiMetric,ppOutput^.Units);
  iSize := ppOutput^.ConvertX(OUTER_BORDER_OFFSET,mmHiMetric,ppOutput^.Units);
  // Draw a box 0.8mm further out from the page margin
  ppOutput^.Canvas.MoveTo(iPageLeftMargin - iSize,iPageTopMargin - iSize);
  ppOutput^.Canvas.LineTo(iPageLeftMargin - iSize,iPageBottomMargin + iSize);
  ppOutput^.Canvas.LineTo(iPageRightMargin + iSize,iPageBottomMargin + iSize);
  ppOutput^.Canvas.LineTo(iPageRightMargin + iSize,iPageTopMargin - iSize);
  ppOutput^.Canvas.LineTo(iPageLeftMargin - iSize,iPageTopMargin - iSize);
end; // DrawPageBorder

////***************************************************************************
////
////  FUNCTION    :   DrawPageNumber
////
////  I/P         :
////
////  O/P         :
////
////  OPERATION   :   Fills in the page number using the font and position
////                      specified.
////
////  UPDATED     :   2005/02/07
////
////***************************************************************************
//procedure DrawPageNumber;
//var
//  sPgNum : String;
//  sStartingFontName : String;
//  iStartingFontSize : Integer;
//  fsStartingFontStyle : set of TFontStyle;
//  VerticalOffset : Integer;
//
//begin
//  // Store the font that is currently in use
//  sStartingFontName := ppOutput^.Canvas.Font.Name;
//  iStartingFontSize := ppOutput^.Canvas.Font.Size;
//  fsStartingFontStyle := ppOutput^.Canvas.Font.Style;
//  // Switch to the font to be used for the page number
//  ppOutput^.Canvas.Font.Name := sPageNumFontName;
//  ppOutput^.Canvas.Font.Size := iPageNumFontSize;
//  ppOutput^.Canvas.Font.Style := sfsPageNumFontStyle;
//
//  if (iTotalNumberOfPages > 0) then
//    sPgNum := ' ' + Format(sPageXofYText,[ppOutput^.Tag,iTotalNumberOfPages]) + ' '
//  else
//    sPgNum := ' ' + Format(sPageXText,[ppOutput^.Tag]) + ' ';
//
//  if (bPageBorder) then
//    VerticalOffset := ppOutput^.ConvertX(INNER_BORDER_THICKNESS,mmHiMetric,ppOutput^.Units) div 2
//  else
//    VerticalOffset := 0;
//
//  // Wipe out anything that may be occupying the page number's position
//  ppOutput^.Canvas.Brush.Style := bsSolid;
//  case (taPageNumAlignment) of
//    taRightJustify :
//      ppOutput^.Canvas.FillRect(Rect(iPageRightMargin - ppOutput^.Canvas.TextWidth (sPgNum),
//                                     iPageBottomMargin - VerticalOffset,
//                                     iPageRightMargin,
//                                     iPageBottomMargin + ppOutput^.Canvas.TextHeight (sPgNum) + 2));
//    taCenter :
//      ppOutput^.Canvas.FillRect(Rect(iPageLeftMargin +
//                                     (iPageWidthMargin - ppOutput^.Canvas.TextWidth (sPgNum)) div 2,
//                                     iPageBottomMargin - VerticalOffset,
//                                     iPageLeftMargin +
//                                     (iPageWidthMargin - ppOutput^.Canvas.TextWidth (sPgNum)) div 2 +
//                                     ppOutput^.Canvas.TextWidth (sPgNum),
//                                     iPageBottomMargin + ppOutput^.Canvas.TextHeight (sPgNum) + 2));
//    else
//      ppOutput^.Canvas.FillRect(Rect(iPageLeftMargin,
//                                     iPageBottomMargin - VerticalOffset,
//                                     iPageLeftMargin + ppOutput^.Canvas.TextWidth (sPgNum),
//                                     iPageBottomMargin + ppOutput^.Canvas.TextHeight (sPgNum) + 2));
//  end; // case
//
//// Draw the number
//  ppOutput^.Canvas.Pen.Color := cPageNumFontColour;
//  case (taPageNumAlignment) of
//    taRightJustify :
//      ppOutput^.Canvas.TextOut(iPageRightMargin - ppOutput^.Canvas.TextWidth (sPgNum),
//                               iPageBottomMargin - VerticalOffset,
//                               sPgNum);
//    taCenter :
//      ppOutput^.Canvas.TextOut(iPageLeftMargin +
//                                 (iPageWidthMargin - ppOutput^.Canvas.TextWidth (sPgNum)) div 2,
//                               iPageBottomMargin - VerticalOffset,
//                               sPgNum);
//    else
//      ppOutput^.Canvas.TextOut(iPageLeftMargin,
//                               iPageBottomMargin - VerticalOffset,
//                               sPgNum);
//  end; // case
//
//  // Restore the font that was in use
//  ppOutput^.Canvas.Font.Name := sStartingFontName;
//  ppOutput^.Canvas.Font.Style := fsStartingFontStyle;
//  ppOutput^.Canvas.Font.Size := iStartingFontSize;
//end; // DrawPageNumber
//
//***************************************************************************
//
//  FUNCTION  : InsertPageNumbers
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Fills in the page number using the font and position
//                specified.
//
//  UPDATED   : 2019-10-25
//
//***************************************************************************
procedure InsertPageNumbers;
var
  sPgNum : String;
  VerticalOffset : Integer;
  n : Integer;

begin
  n := 1;
  while (n <= ppOutput^.TotalPages) do
  begin
    ppOutput^.BeginEdit(n);

    // Switch to the font to be used for the page number
    ppOutput^.Canvas.Font.Name := sPageNumFontName;
    ppOutput^.Canvas.Font.Size := iPageNumFontSize;
    ppOutput^.Canvas.Font.Style := sfsPageNumFontStyle;

    sPgNum := ' ' + Format(sPageXofYText,[n, ppOutput^.TotalPages]) + ' ';

    if (bPageBorder) then
      VerticalOffset := ppOutput^.ConvertX(INNER_BORDER_THICKNESS,mmHiMetric,ppOutput^.Units) div 2
    else
      VerticalOffset := 0;

    // Wipe out anything that may be occupying the page number's position
    ppOutput^.Canvas.Brush.Style := bsSolid;
    case (taPageNumAlignment) of
      taRightJustify :
        ppOutput^.Canvas.FillRect(Rect(iPageRightMargin - ppOutput^.Canvas.TextWidth (sPgNum),
                                       iPageBottomMargin - VerticalOffset,
                                       iPageRightMargin,
                                       iPageBottomMargin + ppOutput^.Canvas.TextHeight (sPgNum) + 2));
      taCenter :
        ppOutput^.Canvas.FillRect(Rect(iPageLeftMargin +
                                       (iPageWidthMargin - ppOutput^.Canvas.TextWidth (sPgNum)) div 2,
                                       iPageBottomMargin - VerticalOffset,
                                       iPageLeftMargin +
                                       (iPageWidthMargin - ppOutput^.Canvas.TextWidth (sPgNum)) div 2 +
                                       ppOutput^.Canvas.TextWidth (sPgNum),
                                       iPageBottomMargin + ppOutput^.Canvas.TextHeight (sPgNum) + 2));
      else
        ppOutput^.Canvas.FillRect(Rect(iPageLeftMargin,
                                       iPageBottomMargin - VerticalOffset,
                                       iPageLeftMargin + ppOutput^.Canvas.TextWidth (sPgNum),
                                       iPageBottomMargin + ppOutput^.Canvas.TextHeight (sPgNum) + 2));
    end; // case

    // Draw the number
    ppOutput^.Canvas.Pen.Color := cPageNumFontColour;
    case (taPageNumAlignment) of
      taRightJustify :
        ppOutput^.Canvas.TextOut(iPageRightMargin - ppOutput^.Canvas.TextWidth (sPgNum),
                                 iPageBottomMargin - VerticalOffset,
                                 sPgNum);
      taCenter :
        ppOutput^.Canvas.TextOut(iPageLeftMargin +
                                   (iPageWidthMargin - ppOutput^.Canvas.TextWidth (sPgNum)) div 2,
                                 iPageBottomMargin - VerticalOffset,
                                 sPgNum);
      else
        ppOutput^.Canvas.TextOut(iPageLeftMargin,
                                 iPageBottomMargin - VerticalOffset,
                                 sPgNum);
    end; // case

    ppOutput^.EndEdit(FALSE);

    Inc(n);
  end; // for
end; // InsertPageNumbers

//***************************************************************************
//
//  FUNCTION    :   DrawPageLogo
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :   Fills in the page logo using position specified.
//
//  UPDATED     :   2004/03/19
//
//***************************************************************************
procedure DrawPageLogo;
var
  iLogoHeight : Integer;
  iLogoWidth : Integer;
  iPageLogoHeight : Integer;
  bmLogo : TBitMap;
  XPosOffset : Integer;
  YPosOffset : Integer;

begin
  bmLogo := tBitMap.Create;
  bmLogo.LoadFromResourceName(HInstance,sPageLogo);

  // The height and width are set to leave a 5% border all around the given graphic
  iLogoWidth := (ppOutput^.ConvertX(iPageLogoWidth,mmHiMetric,ppOutput^.Units) * 9) div 10;
  iPageLogoHeight := (bmLogo.Height * iPageLogoWidth) div  bmLogo.Width;
  iLogoHeight := (ppOutput^.ConvertY(iPageLogoHeight,mmHiMetric,ppOutput^.Units) * 9) div 10;

  if (bPageBorder) then
  begin
    XPosOffset := ppOutput^.ConvertX(INNER_BORDER_THICKNESS,mmHiMetric,ppOutput^.Units) div 2;
    YPosOffset := ppOutput^.ConvertX(OUTER_BORDER_OFFSET,mmHiMetric,ppOutput^.Units) div 2;
  end // if
  else
  begin
    XPosOffset := 0;
    YPosOffset := 0;
  end; // else

  // Wipe out anything that may be occupying the page logo's position
  ppOutput^.Canvas.Brush.Style := bsSolid;
  case (taPageLogoAlignment) of
    taRightJustify :
    begin
      ppOutput^.Canvas.FillRect(Rect(iPageRightMargin - XPosOffset -
                                       ppOutput^.ConvertX(iPageLogoWidth,mmHiMetric,ppOutput^.Units),
                                     iPageBottomMargin - YPosOffset,
                                     iPageRightMargin - XPosOffset,
                                     iPageBottomMargin - YPosOffset +
                                       ppOutput^.ConvertX(iPageLogoHeight,mmHiMetric,ppOutput^.Units)));
    end; // option
    taCenter :
//!! This is not working properly
      ppOutput^.Canvas.FillRect(Rect(iPageLeftMargin +
                                       (iPageWidthMargin - iLogoWidth) div 2,
                                     iPageBottomMargin - YPosOffset,
                                     iPageLeftMargin +
                                       (iPageWidthMargin - iLogoWidth) div 2 + iLogoWidth,
                                     iPageBottomMargin - YPosOffset + iLogoHeight));
    else
      ppOutput^.Canvas.FillRect(Rect(iPageLeftMargin + XPosOffset,
                                     iPageBottomMargin - YPosOffset,
                                     iPageLeftMargin + XPosOffset +
                                       ppOutput^.ConvertX(iPageLogoWidth,mmHiMetric,ppOutput^.Units),
                                     iPageBottomMargin - YPosOffset +
                                       ppOutput^.ConvertX(iPageLogoHeight,mmHiMetric,ppOutput^.Units)));
  end; // case

// Draw the Logo
  case (taPageLogoAlignment) of
    taRightJustify :
    begin
      ppOutput^.PaintGraphicEx(Rect(iPageRightMargin - XPosOffset -
                                      iPageLogoWidth +
                                      (iPageLogoWidth - iLogoWidth) div 2,
                                    iPageBottomMargin - YPosOffset +
                                      (iPageLogoHeight - iLogoHeight) div 2,
                                    iPageRightMargin - XPosOffset -
                                      (iPageLogoWidth - iLogoWidth) div 2,
                                    iPageBottomMargin - YPosOffset +
                                      iPageLogoHeight -
                                      (iPageLogoHeight - iLogoHeight) div 2),
                               bmLogo,FALSE,FALSE,FALSE);
    end; // option
    taCenter :
//!! This is not working properly
      ppOutput^.PaintGraphicEx(Rect(iPageLeftMargin +
                                      (iPageWidthMargin - iLogoWidth) div 2 +
                                      (iPageLogoWidth - iLogoWidth) div 2,
                                    iPageBottomMargin - YPosOffset +
                                      (iPageLogoHeight - iLogoHeight) div 2,
                                    iPageLeftMargin +
                                      (iPageWidthMargin - iLogoWidth) div 2 +
                                      iPageLogoWidth -
                                      (iPageLogoWidth - iLogoWidth) div 2,
                                    iPageBottomMargin - YPosOffset +
                                      iPageLogoHeight -
                                      (iPageLogoHeight - iLogoHeight) div 2),
                               bmLogo,FALSE,FALSE,FALSE);
    else
      ppOutput^.PaintGraphicEx(Rect(iPageLeftMargin + XPosOffset +
                                      (iPageLogoWidth - iLogoWidth) div 2,
                                    iPageBottomMargin - YPosOffset +
                                      (iPageLogoHeight - iLogoHeight) div 2,
                                    iPageLeftMargin + XPosOffset +
                                      iPageLogoWidth -
                                      (iPageLogoWidth - iLogoWidth) div 2,
                                    iPageBottomMargin - YPosOffset +
                                      iPageLogoHeight -
                                      (iPageLogoHeight - iLogoHeight) div 2),
                                 bmLogo,FALSE,FALSE,FALSE);
  end; // case

  bmLogo.Free;
end; // DrawPageLogo

//***************************************************************************
//
//  FUNCTION    :   DrawPageLogo
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :   Fills in the page watermark.
//
//  UPDATED     :   2005/04/01
//
//***************************************************************************
procedure DrawPageWatermark;
var
  iWMarkHeight : Integer;
  iWMarkWidth : Integer;

  bmWatermark : TBitMap;
begin
  bmWatermark := tBitMap.Create;
  bmWatermark.LoadFromResourceName(HInstance,sPageWatermark);

  // The height and width are set to leave a 10% border at the largest dimension
  iWMarkWidth := (iPrnAreaWidth * 9) div 10;
  iWMarkHeight := (bmWatermark.Height * iWMarkWidth) div  bmWatermark.Width;
  if (iWMarkHeight > iPrnAreaHeight) then
  begin
  iWMarkHeight := (iPrnAreaHeight * 9) div 10;
  iWMarkWidth := (bmWatermark.Width * iWMarkHeight) div  bmWatermark.Height;
  end; // if
  // Draw the Watermark
(*
  ppOutput^.Canvas.StretchDraw(Rect(iPageLeftMargin +
                                      (iPrnAreaWidth - iWMarkWidth) div 2,
                                    iPageTopMargin +
                                      (iPrnAreaHeight - iWMarkHeight) div 2,
                                    iPageLeftMargin +
                                      (iPrnAreaWidth - iWMarkWidth) div 2 +
                                      iWMarkWidth,
                                    iPageTopMargin +
                                      (iPrnAreaHeight - iWMarkHeight) div 2 +
                                      iWMarkHeight),
                               bmWatermark);
*)
  ppOutput^.PaintGraphicEx(Rect(iPageLeftMargin +
                                      (iPrnAreaWidth - iWMarkWidth) div 2,
                                iPageTopMargin +
                                      (iPrnAreaHeight - iWMarkHeight) div 2,
                                iPageLeftMargin +
                                      (iPrnAreaWidth - iWMarkWidth) div 2 +
                                      iWMarkWidth,
                                iPageTopMargin +
                                      (iPrnAreaHeight - iWMarkHeight) div 2 +
                                      iWMarkHeight),
                           bmWatermark,FALSE,FALSE,FALSE);
end; // DrawPageLogo

//***************************************************************************
//
//  FUNCTION    :   DrawParagraphBorder
//
//  I/P         :   iTopOfParagraph(integer) - The Y position at which we
//                        would draw the top border, if required.
//
//                      bPageBreak(boolean) - Indicates whether this paragraph
//                        has already broken over a page.   If so, we would
//                        not print a top border.
//
//                      bParagraphEnded(boolean) - Indicates whether the
//                        paragraph has now ended.   If so, we would print a
//                        bottom border, if specified.
//
//  O/P         :
//
//  OPERATION   :   Prints borders if they are defined for this paragraph.
//                  Handles run-on (page break) or un-finished paragraphs
//                  by ommitting the top or bottom borders respectively.
//
//  UPDATED     :   2004/02/18
//
//***************************************************************************
procedure DrawParagraphBorder(iTopOfParagraph : Integer;
                              bPageBreak : boolean;
                              bParagraphEnded : boolean);
begin
// Check if we may be printing a top border
  if (not bPageBreak) then
  begin
// Check whether a top border has been defined
    if (tpParagraph.iTopBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tpParagraph.cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tpParagraph.iTopBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft,iTopOfParagraph);
      ppOutput^.Canvas.LineTo(iPrnAreaRight,iTopOfParagraph);
    end; // if
  end; // if

// Check whether a left border has been defined
  if (tpParagraph.iLeftBorderTWIPS > 0) then
  begin
    ppOutput^.Canvas.Pen.Color := tpParagraph.cBorderColour;
    ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tpParagraph.iLeftBorderTWIPS,mmTWIPS,ppOutput^.Units);

    ppOutput^.Canvas.MoveTo(iPrnAreaLeft,iTopOfParagraph);
    if (bParagraphEnded) then
      ppOutput^.Canvas.LineTo(iPrnAreaLeft,iCurrentYPos)
    else
      ppOutput^.Canvas.LineTo(iPrnAreaLeft,iPrnAreaBottom);
  end; // if

// Check whether a right border has been defined
  if (tpParagraph.iRightBorderTWIPS > 0) then
  begin
    ppOutput^.Canvas.Pen.Color := tpParagraph.cBorderColour;
    ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tpParagraph.iRightBorderTWIPS,mmTWIPS,ppOutput^.Units);

    ppOutput^.Canvas.MoveTo(iPrnAreaRight,iTopOfParagraph);
    if (bParagraphEnded) then
      ppOutput^.Canvas.LineTo(iPrnAreaRight,iCurrentYPos)
    else
      ppOutput^.Canvas.LineTo(iPrnAreaRight,iPrnAreaBottom);
  end; // if

// Check if we may be printing a bottom border
  if (bParagraphEnded) then
  begin
    // Check whether a bottom border has been defined
    if (tpParagraph.iBottomBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tpParagraph.cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tpParagraph.iBottomBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft,iCurrentYPos);
      ppOutput^.Canvas.LineTo(iPrnAreaRight,iCurrentYPos);

      // Compensate for the thickness of the bottom border line
      Inc(iCurrentYPos, ppOutput^.Canvas.Pen.Width div 2);
    end; // if
  end; // if
end; // DrawParagraphBorder

//***************************************************************************
//
//  FUNCTION  : PrintParagraph
//
//  I/P       : sParagraph : String - Contains the text to be printed.
//
//              bKeepLeadingSpaces : Boolean = TRUE - If FALSE, trim off leading spaces.
//
//              overrideIDs : TPrintOverrides = [] - Optional array of override
//                identifiers.
//
//              overrideValues : TPrintOverrideValues = [] - Optional array of
//                override values (matching each of the above override identifiers)
//
//  O/P       : None.
//
//  OPERATION : Outputs a given string to the print preview control.
//              Moves down by one line.
//
//  UPDATED   : 2019-09-03
//
//***************************************************************************
procedure PrintParagraph(sParagraph : String;
                         bKeepLeadingSpaces : boolean = TRUE;
                         overrideIDs : TPrintOverrides = [];
                         overrideValues : TPrintOverrideValues = []); overload;
var
  iLineHeight : Integer;
  iLineWidth : Integer;
  n : Integer;
  m : Integer;
  sOneLine : String;
  iParagraphStart : Integer;
  bPageSpanned : boolean;
  textAlignment : TAlignment;

begin
  // Set the output to the current font.
  ppOutput^.Canvas.Font.Name := tpParagraph.sFontName;
  ppOutput^.Canvas.Font.Style := tpParagraph.sfsFontStyle;
  ppOutput^.Canvas.Font.Color := tpParagraph.cFontColour;
  ppOutput^.Canvas.Font.Size := tpParagraph.iFontSize;
  ppOutput^.Canvas.Brush.Color := tpParagraph.cBackgroundColour; // clWhite
  textAlignment := tpParagraph.taAlignment;

  // Make any specified printing changes
  n := 0;
  while ((n < Length(overrideIDs)) and
         (n < Length(overrideValues))) do
  begin
    case overrideIDs[n] of
      PRNT_OVR_FONT_SIZE :
        ppOutput^.Canvas.Font.Size := Integer(overrideValues[n]);
      PRNT_OVR_FONT_COLOUR :
        ppOutput^.Canvas.Font.Color := TColor(overrideValues[n]);
      PRNT_OVR_BACKGROUND_COLOUR :
        ppOutput^.Canvas.Brush.Color := TColor(overrideValues[n]);
      PRNT_OVR_ALIGNMENT :
        textAlignment := TAlignment(overrideValues[n]);
      PRNT_OVR_FONT_BOLD :
        if (Boolean(overrideValues[n])) then
          ppOutput^.Canvas.Font.Style := ppOutput^.Canvas.Font.Style + [fsBold]
        else
          ppOutput^.Canvas.Font.Style := ppOutput^.Canvas.Font.Style - [fsBold];
      PRNT_OVR_FONT_ITALIC :
        if (Boolean(overrideValues[n])) then
          ppOutput^.Canvas.Font.Style := ppOutput^.Canvas.Font.Style + [fsItalic]
        else
          ppOutput^.Canvas.Font.Style := ppOutput^.Canvas.Font.Style - [fsItalic];
      PRNT_OVR_FONT_UNDERLINE :
        if (Boolean(overrideValues[n])) then
          ppOutput^.Canvas.Font.Style := ppOutput^.Canvas.Font.Style + [fsUnderline]
        else
          ppOutput^.Canvas.Font.Style := ppOutput^.Canvas.Font.Style - [fsUnderline];
      PRNT_OVR_FONT_STRIKEOUT :
        if (Boolean(overrideValues[n])) then
          ppOutput^.Canvas.Font.Style := ppOutput^.Canvas.Font.Style + [fsStrikeOut]
        else
          ppOutput^.Canvas.Font.Style := ppOutput^.Canvas.Font.Style - [fsStrikeOut];
    end; // case
    Inc(n);
  end; // while

  // Determine the height of each line at the current font
  iLineHeight := ppOutput^.Canvas.TextHeight('A');
  // Record the top of the paragraph, in case we need to draw a border
  iParagraphStart := iCurrentYPos;
  // Initially, the paragraph has not spanned a page break.
  bPageSpanned := FALSE;
  // Move the starting position down by the "space before" amount
  iCurrentYPos := iCurrentYPos + ppOutput^.ConvertY(tpParagraph.iSpaceBeforePt,mmPoints,ppOutput^.Units);
  // Every paragraph starts off against the left edge, at tabstop 0.
  siCurrentTabStop := 0;

  // Start a new page if the first line that we are about to print will not fit on the current page.
  // Note that the current Y position indicates the bottom of the text.
  if (iCurrentYPos >= (iPrnAreaBottom - iLineHeight)) then
  begin
    StartNewPage(FALSE);
  end; // if

  // Remove all line feed characters - we treat a #13 as a linefeed/carriage return
  sParagraph := SearchAndReplace(sParagraph,#10,'');

  // Build up each printable line of the paragraph.
  sOneLine := '';
  n := 1;
  bFirstParaLine := TRUE;
  while (n <= Length(sParagraph)) do
  begin
    // Build up the line to be printed, removing leading spaces, if required.
    if ((bKeepLeadingSpaces) or (sOneLine<>'') or (sParagraph[n]<>' ')) then
      sOneLine := sOneLine + sParagraph[n];
    // Check for any Tab Stops within the paragraph string.
    if (sParagraph[n] = #9) then
    begin
      // Dump the line and move on to the next tab stop
      PrintParagraphLine(Copy(sOneLine,1,Length(sOneLine)-1), textAlignment);
      Inc(siCurrentTabStop);
      sOneLine := '';
      // Only add a line feed and carriage return if this paragraph has ended with a tab character
      if (n = Length(sParagraph)) then
      begin
        // Move the Y-position down by a line feed plus the "space after" amount
        iCurrentYPos := iCurrentYPos + iLineHeight +
                         ppOutput^.ConvertY(tpParagraph.iSpaceAfterPt,mmPoints,ppOutput^.Units);
        DrawParagraphBorder(iParagraphStart,bPageSpanned,TRUE);
      end; // if
    end // if
    else

    // Check for any Carriage Returns within the paragraph string.
    if (sParagraph[n] = #13) then
    begin
      PrintParagraphLine(Copy(sOneLine,1,Length(sOneLine)-1), textAlignment);
      // Any carriage return in a paragraph resets the following-line indents
      bFirstParaLine := TRUE;
      // Restart the tab stops
      siCurrentTabStop := 0;
      // Move the Y-position down by a line feed plus the "space after" amount
      iCurrentYPos := iCurrentYPos + iLineHeight +
                       ppOutput^.ConvertY(tpParagraph.iSpaceAfterPt,mmPoints,ppOutput^.Units);
      // If there is more to come in this "paragraph", move down by the "space before" amount too
      // i.e. create another paragraph.
      if (n <> Length(sParagraph)) then
        iCurrentYPos := iCurrentYPos + ppOutput^.ConvertY(tpParagraph.iSpaceBeforePt,mmPoints,ppOutput^.Units);
      sOneLine := '';
      // Start a new page if the next line that we will be printing from this paragraph will not fit
      // on the current page.
      // Note that the current Y position indicates the bottom of the text.
      if (iCurrentYPos >= (iPrnAreaBottom - iLineHeight)) then
      begin
        DrawParagraphBorder(iParagraphStart,bPageSpanned,FALSE);
        StartNewPage(FALSE);
        bPageSpanned := FALSE;
      end; // if
    end // if
    else

    // Check for a Vertical Tab within the paragraph string
    // I treat as a line break i.e. no Before or After spacing included (as with a Carriage Return)
    if (sParagraph[n] = #11) then
    begin
      PrintParagraphLine(Copy(sOneLine,1,Length(sOneLine)-1), textAlignment);
      // Restart the tab stops
      siCurrentTabStop := 0;
      // Move the Y-position down by a line feed
      iCurrentYPos := iCurrentYPos + iLineHeight;
      sOneLine := '';
      // Start a new page if the next line that we will be printing from this paragraph will not fit
      // on the current page.
      // Note that the current Y position indicates the bottom of the text.
      if (iCurrentYPos >= (iPrnAreaBottom - iLineHeight)) then
      begin
        DrawParagraphBorder(iParagraphStart,bPageSpanned,FALSE);
        StartNewPage(FALSE);
        bPageSpanned := FALSE;
      end; // if
    end // if
    else

    // Check for the end of the paragraph
    if (n = Length(sParagraph)) then
    begin
      PrintParagraphLine(sOneLine, textAlignment);
      // Move the Y=position down by a line feed plus the "space after" amount
      iCurrentYPos := iCurrentYPos + iLineHeight +
                       ppOutput^.ConvertY(tpParagraph.iSpaceAfterPt,mmPoints,ppOutput^.Units);
      sOneLine := '';
      DrawParagraphBorder(iParagraphStart,bPageSpanned,TRUE);
    end // if
    else
    begin
      // Get the length of the line from the left printable edge
      iLineWidth := ppOutput^.ConvertX(tpParagraph.iLeftMM100,mmHiMetric,ppOutput^.Units) +
                    ppOutput^.ConvertX(tpParagraph.iRightMM100,mmHiMetric,ppOutput^.Units) +
                    ppOutput^.Canvas.TextWidth(sOneLine);
      if ((tpParagraph.taAlignment = taLeftJustify) and (not bFirstParaLine)) then
        iLineWidth := iLineWidth +
                      ppOutput^.ConvertX(tpParagraph.iHangingIndentLeftMM100,mmHiMetric,ppOutput^.Units);

      // Check for overflow of a line
      if (iLineWidth  > iPrnAreaWidth) then
      begin
        // Back-track to the last space in the line, where we will create a soft line break
        m := Length(sOneLine);
        while ((m>1) and (sOneLine[m] <> ' ')) do
        begin
          Dec(m);
          Dec(n);
        end; // while
        // Ensure that the line length is valid
        if (m>1) then
        begin
          // Trim the line up to just before the space
          sOneLine := Copy(sOneLine,1,m-1);
          PrintParagraphLine(sOneLine, textAlignment);
          // Move the Y-position down by a line feed (we are still within the paragraph)
          iCurrentYPos := iCurrentYPos + iLineHeight;
          sOneLine := '';
          // Start a new page if the next line that we will be printing from this paragraph will not fit
          // on the current page.
          // Note that the current Y position indicates the bottom of the text.
          if (iCurrentYPos >= (iPrnAreaBottom - iLineHeight)) then
          begin
            DrawParagraphBorder(iParagraphStart,bPageSpanned,FALSE);
            StartNewPage(FALSE);
            bPageSpanned := FALSE;
          end; // if
          // Flag that we are still in the same paragraph, but are now in run-on lines.
          bFirstParaLine := FALSE;
          // If you over-run the first line in a paragraph, the tab stop position returns to zero
          siCurrentTabStop := 0;
        end // if
        else
          // Get out if there appears to be an error (i.e. line of 1 character)
          break;
      end; // if
    end; // else

    // Move on to the next character
    Inc(n);
  end; // while
end; // PrintParagraph

//***************************************************************************
//
//  FUNCTION  : PrintRichParagraph
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
procedure PrintRichParagraph(creHolder : TCustomRichEdit);
var
  iRenderOffset : Integer;
  iRenderOffsetTemp : Integer;
  iNewCurrentYPos : Integer;
  iParagraphStart : Integer;
  bStartOnThisPage : boolean;
  bEndOnThisPage : boolean;
  rParagraph : TRect;

begin
  // Set the output to default the current font.
  ppOutput^.Canvas.Font.Name := tpParagraph.sFontName;
  ppOutput^.Canvas.Font.Style := tpParagraph.sfsFontStyle;
  ppOutput^.Canvas.Font.Color := tpParagraph.cFontColour;
  ppOutput^.Canvas.Font.Size := tpParagraph.iFontSize;
  ppOutput^.Canvas.Brush.Color := clWhite;

  // Record the top of the paragraph, in case we need to draw a border
  iParagraphStart := iCurrentYPos;
  // Move the Y starting position down by the "space before" amount
  iCurrentYPos := iCurrentYPos + ppOutput^.ConvertY(tpParagraph.iSpaceBeforePt,mmPoints,ppOutput^.Units);

  // Start rendering from the first character in the TRichEdit
  iRenderOffset := 0;
  bStartOnThisPage := TRUE;

  repeat
    // Determine whether drawing this paragraph is going to take up more than
    // the remainder of this page.
    iRenderOffsetTemp := iRenderOffset;
    rParagraph.Left := iPrnAreaLeft + ppOutput^.ConvertX(tpParagraph.iLeftMM100,mmHiMetric,ppOutput^.Units);
    rParagraph.Top := iCurrentYPos;
    rParagraph.Right := iPrnAreaRight - ppOutput^.ConvertX(tpParagraph.iRightMM100,mmHiMetric,ppOutput^.Units);
    rParagraph.Bottom := iPrnAreaBottom;
    iNewCurrentYPos := ppOutput^.GetRichTextRect(rParagraph,creHolder,@iRenderOffset);
    bEndOnThisPage := (iRenderOffset = -1);
//!!ANS*CHECK - This does not appear to work if the RichEdit is empty.
// I found this with notes at TraX.   The TRectangle.Bottom is not determined
// One would expect it to return .Top = .Bottom

(*
Empty, non-working RTF

{\rtf1\ansi\ansicpg1252\deff0{\fonttbl{\f0\fnil MS Sans Serif;}}
{\colortbl ;\red0\green0\blue0;}
\viewkind4\uc1\pard\cf1\lang1033\f0\fs16
\par }
*)

(*
It does work for this RTF, which only has the word "test" in it

{\rtf1\ansi\ansicpg1252\deff0{\fonttbl{\f0\fnil\fcharset0 MS Sans Serif;}{\f1\fnil MS Sans Serif;}}
{\colortbl ;\red0\green0\blue0;}
\viewkind4\uc1\pard\cf1\lang1033\f0\fs16 test\f1
\par }
*)

    // Do the actual drawing of the paragraph on the current page
    iRenderOffset := iRenderOffsetTemp;
    ppOutput^.PaintRichText(rParagraph,creHolder,1,@iRenderOffset);
    iCurrentYPos := iNewCurrentYPos;
    // Place any required border around this paragraph
    DrawParagraphBorder(iParagraphStart, not bStartOnThisPage, bEndOnThisPage);
    bStartOnThisPage := FALSE;

    // Check if we need to start a new page.
    if (not bEndOnThisPage) then
      StartNewPage(FALSE);

    // Record the top of the paragraph, in case we need to draw a border on a follow-on page
    iParagraphStart := iCurrentYPos;

    // Continue until all text in the TRichEdit has been transferred to the page.
  until (iRenderOffset = -1);

//  reHolder.Free;
end; // PrintRichParagraph

//***************************************************************************
//
//  FUNCTION  : PrintBlank
//
//  I/P       : iPoint (integer) - The number of points to leave blank,
//                vertically.
//
//  O/P       : None
//
//  OPERATION : Used to move the insertion point down a certain number of points
//              No printing is done - the area is left blank.
//
//  UPDATED   : 2007/02/09
//
//***************************************************************************
procedure PrintBlank(iPoint : integer);
begin
  // Move the insertion position down by the requested amount
  iCurrentYPos := iCurrentYPos + ppOutput^.ConvertY(iPoint,mmPoints,ppOutput^.Units);

  // Start a new page if the insertion point has moved us beyond the bottom printing area.
  //!! This may need correction, when examining the above code for paragraph
  // printing (where it takes into account the height of the next line to be
  // printed.
  // Note that the current Y position indicates the bottom of the text.
  if (iCurrentYPos >= iPrnAreaBottom) then
    StartNewPage(FALSE);
end; // PrintBlank

//***************************************************************************
//
//  FUNCTION  : InsertHorizontalPageLine
//
//  I/P       : lineTWIPS : Integer - Thickness of the line
//
//  O/P       :
//
//  OPERATION : Draw a horizontal black line across the page width.
//
//              Later I can overload this with colour, left and right starting
//              positions
//
//  UPDATED   : 2017-08-22
//
//***************************************************************************
procedure InsertHorizontalPageLine(lineTWIPS : Integer);
begin
  if (lineTWIPS > 0) then
  begin
    ppOutput^.Canvas.Pen.Color := clBlack;
    ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(lineTWIPS,mmTWIPS,ppOutput^.Units);
    ppOutput^.Canvas.MoveTo(iPrnAreaLeft,iCurrentYPos);
    ppOutput^.Canvas.LineTo(iPrnAreaRight,iCurrentYPos);
  end; // if
end; // InsertHorizontalPageLine

//***************************************************************************
//
//  FUNCTION  : PrintTextFile
//
//  I/P       : sReportFileName : The full file name of the text
//                report to be printed.
//
//              sFontName (string) - The font to be used for the printout
//
//              iFontPitch (integer) - The font pitch to be used for the
//                printout.   Set this to <=0 if the font pitch must be
//                dynamically determined.   If > 0, then the DefineParagraph
//                routine should have already been called.
//
//  O/P       :
//
//  OPERATION : Takes the contents of a text file and loads it into the
//              previewer using a fixed pitch font.
//
//  UPDATED   : 2001/04/09
//
//***************************************************************************
procedure PrintTextFile(sReportFileName : String;
                        sFontName : String;
                        iFontPitch : integer);
var
  input_file      : TextFile;
  sOneLine        : String;
begin
  // Ensure that initialisation has taken place
  if (ppOutput <> nil) then
  begin
    Screen.Cursor := crHourGlass;

    // Flag that this job may have headers on run-on pages
    bAutoHeaders := TRUE;

    // Start printing
    ppOutput^.BeginDoc;

    // Indicate whether the font pitch must be dynamically determined
    bPFAutoSetFontPitch := (iFontPitch <= 0);

    // Set up the font parameters
    sAutoSizeFWFontName := sFontName;
    if (bPFAutoSetFontPitch) then
      AutoDefineFWParagraph(sAutoSizeFWFontName);

    // Draw the border and page numbering for the first page
    StartNewPage(TRUE);

    // Access the report file
    AssignFile (input_file,sReportFileName);

    // Start scanning report file from the start again
    {$I-}
    Reset(input_file);
    {$I+}
    if (IOResultTest(TRUE)) then
    begin
      // Write out the lines one by one
      while not(Eof(input_file)) do
      begin
        // Get the next line to print
        Readln(input_file,sOneLine);
        // Strip out all TABS (which are used to demarkate columns for CSV exporting)
        sOneLine := SearchAndReplace(sOneLine,#09,'');
        // Strip out carriage returns and line feeds - we don't expect them
        SearchAndReplace(sOneLine,#10,'');
        SearchAndReplace(sOneLine,#13,'');
        // Check if we should be starting a new page
        if (sOneLine<>#12) then
        begin
          // Print the line that was read, adding a line feed at the end, if there is more to come
          if (not Eof(input_file)) then
            sOneLine := sOneLine + #13;
          PrintParagraph(sOneLine,TRUE);
        end // if
        else
          StartNewPage(FALSE);
      end; // while

      System.CloseFile(input_file);
    end // if
    else
      MessageDlg('Unable to access the file ' + sReportFileName + ' for printing/previewing.' + #13 +
                 'A file error occurred : "' + LastIOResultMessage(FALSE) + '"' + #13 +
                 'I/O Error number ' + IntToStr(LastIOResultNumber(FALSE)),mtError,[mbOK],0);

    // Finish printing
    ppOutput^.EndDoc;

    // Disable the automatic insertion of headers on run-on pages
    bAutoHeaders := FALSE;

    Screen.Cursor := crDefault;
  end; // if
end; // PrintTextFile

//***************************************************************************
//
//  FUNCTION  : PrintRTFFile
//
//  I/P       : sFileName (string) - The RTF file to be printed
//
//  O/P       : None
//
//  OPERATION : Prints a given RTF file onto a pre-defined page
//
//  UPDATED   : 2007-10-31
//
//***************************************************************************
procedure PrintRTFFile(sFileName : string);
var
  reDocument : TRichEdit;
begin
  // Ensure that initialisation has taken place
  if (ppOutput <> nil) then
  begin
    Screen.Cursor := crHourGlass;
    reDocument := TRichEdit.Create(nil);
    reDocument.Visible := FALSE;
    reDocument.Parent := Application.MainForm;
    reDocument.Lines.LoadFromFile(sFileName);

    ppOutput^.BeginDoc;
    ppOutput^.PaintRichText(Rect(iPrnAreaLeft,iPrnAreaTop,iPrnAreaRight,iPrnAreaBottom),
                            reDocument,0,nil);
    ppOutput^.EndDoc;

    reDocument.Free;
    Screen.Cursor := crDefault;
  end; // if
end; // PrintRTFFile
(*
//***************************************************************************
//
//  FUNCTION  : PrintMemo
//
//  I/P       : memToPrint (TMemo) - The Memo to be printed
//
//  O/P       : None
//
//  OPERATION : Prints the contents of a given TMemo
//
//  UPDATED   : 2008-08-26
//
//***************************************************************************
procedure PrintMemo(memToPrint : TMemo);
var
  reDocument : TRichEdit;
begin
  // Ensure that initialisation has taken place
  if (ppOutput <> nil) then
  begin
    Screen.Cursor := crHourGlass;
    reDocument := TRichEdit.Create(nil);
    reDocument.Visible := FALSE;
    reDocument.Parent := Application.MainForm;
    reDocument.Lines := memToPrint.Lines;

    ppOutput^.BeginDoc;
    ppOutput^.PaintRichText(Rect(iPrnAreaLeft,iPrnAreaTop,iPrnAreaRight,iPrnAreaBottom),
                            reDocument,0,nil);
    ppOutput^.EndDoc;

    reDocument.Free;

    Screen.Cursor := crDefault;
  end; // if
end; // PrintMemo
*)

//***************************************************************************
//
//  FUNCTION  : PrintMemo
//
//  I/P       : memToPrint : The memo to be printed
//
//              sFontName (string) - The font to be used for the printout
//
//              iFontPitch (integer) - The font pitch to be used for the
//                printout.   Set this to <=0 if the font pitch must be
//                dynamically determined.   If > 0, then the DefineParagraph
//                routine should have already been called.
//
//  O/P       :
//
//  OPERATION : Takes the contents of a memo and loads it into the
//                previewer using a fixed pitch font.
//
//  UPDATED   : 2008-08-26
//
//***************************************************************************
procedure PrintMemo(memToPrint : TMemo;
                    sFontName : String;
                    iFontPitch : integer);
var
  sOneLine : String;
  iLineNumber : Integer;

begin
  // Ensure that initialisation has taken place
  if (ppOutput <> nil) then
  begin
    Screen.Cursor := crHourGlass;

    // Flag that this job may have headers on run-on pages
    bAutoHeaders := TRUE;

    // Start printing
    ppOutput^.BeginDoc;

    // Indicate whether the font pitch must be dynamically determined
    bPFAutoSetFontPitch := (iFontPitch <= 0);

    // Set up the font parameters
    sAutoSizeFWFontName := sFontName;
    if (bPFAutoSetFontPitch) then
      AutoDefineFWParagraph(sAutoSizeFWFontName);

    // Draw the border and page numbering for the first page
    StartNewPage(TRUE);

    iLineNumber := 0;
    while (iLineNumber < memToPrint.Lines.Count) do
    begin
      sOneLine := memToPrint.Lines[iLineNumber];
      // Strip out all TABS (which are used to demarkate columns for CSV exporting)
      sOneLine := StringReplace(sOneLine,#09,'',[rfReplaceAll]);
      // Strip out carriage returns and line feeds - we don't expect them
      SearchAndReplace(sOneLine,#10,'');
      SearchAndReplace(sOneLine,#13,'');
      // Check if we should be starting a new page
      if (sOneLine<>#12) then
      begin
        // Print the line that was read, adding a line feed at the end, if there is more to come
        if (iLineNumber <> memToPrint.Lines.Count-1) then
          sOneLine := sOneLine + #13;
        PrintParagraph(sOneLine,TRUE);
      end // if
      else
        StartNewPage(FALSE);
      Inc(iLineNumber);
    end; // while

    // Finish printing
    ppOutput^.EndDoc;

    // Disable the automatic insertion of headers on run-on pages
    bAutoHeaders := FALSE;

    Screen.Cursor := crDefault;
  end; // if
end; // PrintMemo

//***************************************************************************
//
//  FUNCTION    :   ClearTabList
//
//  I/P         :   None.
//
//
//  O/P         :   iaTabs - All entries set to zero.
//
//  OPERATION   :   Removes all tabs
//
//  UPDATED     :   2004/02/17
//
//***************************************************************************
procedure ClearTabList;
var
  n : Integer;
begin
  for n := 1 to MAX_TABS do
    iaTabs[n] := 0;
end; // ClearTabList

//***************************************************************************
//
//  FUNCTION    :   AddTab
//
//  I/P         :   uiTabPosition (longint) - The position, relative to
//                    the left printing edge, where the tab is to be
//                    positioned.
//
//  O/P         :   uiaTabs - Updated and sorted
//
//  OPERATION   :   Adds a tab position, keeping the items in order.
//
//  UPDATED     :   2004/02/17
//
//***************************************************************************
procedure AddTab(iNewTabPosition : integer);
var
  n : Integer;
  iCarryTab : Integer;
  iTempTab : Integer;
begin
  iCarryTab := 0;
  for n := 1 to MAX_TABS do
  begin
// Check whether this is the slot where the new tab should be inserted
    if ((iCarryTab = 0) and ((iNewTabPosition < iaTabs[n]) or (iaTabs[n] = 0))) then
    begin
      iCarryTab := iaTabs[n];
      iaTabs[n] := iNewTabPosition;
      if (iCarryTab = 0) then
        break;
    end // if
    else
// Check if there is a tab that we are carrying
      if (iCarryTab <> 0) then
      begin
        iTempTab := iaTabs[n];
        iaTabs[n] := iCarryTab;
        iCarryTab := iTempTab;
      end; // if
  end; // for
end; // AddTab

//***************************************************************************
//
//  FUNCTION    :   PrintHeaderCellLine
//
//  I/P         :   sLineToPrint(string) - The line of text to be printed.
//                    It should be known to fit in the available width
//                    using the current font parameters.
//
//                  siColumn(shortint) - Index of the column being printed.
//
//  O/P         :
//
//  OPERATION   :   Prints the given text at a position determined by the
//                  header cell definition (X) and the current Y position.
//
//  UPDATED     :   2004/03/29
//
//***************************************************************************
procedure PrintHeaderCellLine(sLineToPrint : String;
                              siColumn : shortint);
var
  iLineLength : Integer;
  iTemp : Integer;

begin
  iLineLength := ppOutput^.Canvas.TextWidth(sLineToPrint);

  // Colour in the area that will be covered by the text, from the left to
  // the right edge of the cell
  if (tptTable[ct].headerColumns[siColumn].cBackgroundColour <> clWhite) then
  begin
    ppOutput^.Canvas.Brush.Style := bsSolid;
    ppOutput^.Canvas.FillRect(Rect(iPrnAreaLeft +
                                     ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                                   iCurrentYPos,
                                   iPrnAreaLeft +
                                     ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                                   iCurrentYPos +
                                     ppOutput^.Canvas.TextHeight('A')));
  end; // if

  ppOutput^.Canvas.Brush.Style := bsClear;

  case tptTable[ct].HeaderAlignment[siColumn] of
    taRightJustify :
      ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                               ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units) -
                               ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units) -
                               iLineLength,iCurrentYPos,sLineToPrint);
    taCenter :
    begin
      iTemp := ((ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units) -
                 ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units)) -
                (iLineLength + 2*ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units))) div 2;
      ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                               ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units) +
                               ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units) +
                               iTemp,
                               iCurrentYPos,
                               sLineToPrint);
    end;
    else
    begin
// Handle hanging indents
      if (bFirstParaLine) then
        ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                                 ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units) +
                                 ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units),
                                 iCurrentYPos,sLineToPrint)
      else
        ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                                 ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units) +
                                 ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units) +
                                 ppOutput^.ConvertX(tptTable[ct].headerColumns[siColumn].iHangingIndentLeftMM100,mmHiMetric,ppOutput^.Units),
                                 iCurrentYPos,sLineToPrint)
    end; // if
  end; // case
end; // PrintHeaderCellLine

//***************************************************************************
//
//  FUNCTION  : PrintBodyCellLine
//
//  I/P       : sLineToPrint : String - The line of text to be printed.
//                It should be known to fit in the available width
//                using the current font parameters.
//
//              siColumn : shortint - Index of the column being printed.
//
//  O/P       :
//
//  OPERATION : Prints the given text at a position determined by the
//                body cell definition (X) and the current Y position.
//
//  UPDATED   : 2010-10-05
//
//***************************************************************************
procedure PrintBodyCellLine(sLineToPrint : String;
                            siColumn : shortint);
var
  iLineLength : Integer;
  iTemp : Integer;

begin
  iLineLength := ppOutput^.Canvas.TextWidth(sLineToPrint);

  // Colour in the area that will be covered by the text, from the left to the right edge of the cell
  if (tptTable[ct].bodyBGColour[siColumn] <> clWhite) then
  begin
    ppOutput^.Canvas.Brush.Style := bsSolid;
    ppOutput^.Canvas.FillRect(Rect(iPrnAreaLeft +
                                     ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                                   iCurrentYPos,
                                   iPrnAreaLeft +
                                     ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                                   iCurrentYPos +
                                     ppOutput^.Canvas.TextHeight('A')));
  end; // if

  // Change the brush to clear, so that watermarks will shine through
  ppOutput^.Canvas.Brush.Style := bsClear;

  // Insert the text with the selected alignment
  case (tptTable[ct].bodyAlignment[siColumn]) of
    taRightJustify :
      ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                               ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units) -
                               ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units) -
                               iLineLength,iCurrentYPos,sLineToPrint);
    taCenter :
    begin
      iTemp := ((ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units) -
                 ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units)) -
                (iLineLength + 2*ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units))) div 2;
      ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                               ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units) +
                               ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units) +
                               iTemp,
                               iCurrentYPos,
                               sLineToPrint);
    end;
    else
    begin
// Handle hanging indents
      if (bFirstParaLine) then
        ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                                 ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units) +
                                 ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units),
                                 iCurrentYPos,sLineToPrint)
      else
        ppOutput^.Canvas.TextOut(iPrnAreaLeft +
                                 ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units) +
                                 ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units) +
                                 ppOutput^.ConvertX(tptTable[ct].bodyColumns[siColumn].iHangingIndentLeftMM100,mmHiMetric,ppOutput^.Units),
                                 iCurrentYPos,sLineToPrint)
    end; // if
  end; // case
end; // PrintBodyCellLine

//***************************************************************************
//
//  FUNCTION    :   DrawHeaderCellBorders
//
//  I/P         :   iTopBorder(integer) - The Y position of the top border
//                    of the row.
//
//                  iBottomBorder(integer) - The Y position of the bottom
//                    border of the row.
//
//  O/P         :
//
//  OPERATION   :   Prints body cell borders, as defined, between the given
//                  top and bottom positions.
//
//  UPDATED     :   2004/02/18
//
//***************************************************************************
procedure DrawHeaderCellBorders(iTopBorder : Integer;
                                iBottomBorder : integer);
var
  n : Integer;
begin
  n := 1;
  while (n <= tptTable[ct].iTableColumns) do
  begin
// Check whether a top border has been defined for this cell - if so, print it
    if (tptTable[ct].headerColumns[n].iTopBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tptTable[ct].headerColumns[n].cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iTopBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                              iTopBorder);
      ppOutput^.Canvas.LineTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                              iTopBorder);
    end; // if

// Check whether a left border has been defined
    if (tptTable[ct].headerColumns[n].iLeftBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tptTable[ct].headerColumns[n].cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iLeftBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                              iTopBorder);
      ppOutput^.Canvas.LineTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                              iBottomBorder);
    end; // if

// Check whether a right border has been defined
    if (tptTable[ct].headerColumns[n].iRightBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tptTable[ct].headerColumns[n].cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iRightBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                              iTopBorder);
      ppOutput^.Canvas.LineTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                              iBottomBorder);
    end; // if

// Check whether a bottom border has been defined
    if (tptTable[ct].headerColumns[n].iBottomBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tptTable[ct].headerColumns[n].cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iBottomBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                              iBottomBorder);
      ppOutput^.Canvas.LineTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                              iBottomBorder);
    end; // if

    Inc(n);
  end; // while

end; // DrawHeaderCellBorders

//***************************************************************************
//
//  FUNCTION    :   DrawBodyCellBorders
//
//  I/P         :   iTopBorder(integer) - The Y position of the top border
//                    of the row.
//
//                  iBottomBorder(integer) - The Y position of the bottom
//                    border of the row.
//
//  O/P         :
//
//  OPERATION   :   Prints body cell borders, as defined, between the given
//                  top and bottom positions.
//
//  UPDATED     :   2004/02/18
//
//***************************************************************************
procedure DrawBodyCellBorders(iTopBorder : Integer;
                              iBottomBorder : integer);
var
  n : Integer;
begin
  n := 1;
  while (n <= tptTable[ct].iTableColumns) do
  begin
    // Check whether a top border has been defined for this cell - if so, print it
    if (tptTable[ct].bodyColumns[n].iTopBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tptTable[ct].bodyColumns[n].cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iTopBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                              iTopBorder);
      ppOutput^.Canvas.LineTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                              iTopBorder);
    end; // if

    // Check whether a left border has been defined
    if (tptTable[ct].bodyColumns[n].iLeftBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tptTable[ct].bodyColumns[n].cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iLeftBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                              iTopBorder);
      ppOutput^.Canvas.LineTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                              iBottomBorder);
    end; // if

    // Check whether a right border has been defined
    if (tptTable[ct].bodyColumns[n].iRightBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tptTable[ct].bodyColumns[n].cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iRightBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                              iTopBorder);
      ppOutput^.Canvas.LineTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                              iBottomBorder);
    end; // if

    // Check whether a bottom border has been defined
    if (tptTable[ct].bodyColumns[n].iBottomBorderTWIPS > 0) then
    begin
      ppOutput^.Canvas.Pen.Color := tptTable[ct].bodyColumns[n].cBorderColour;
      ppOutput^.Canvas.Pen.Width := ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iBottomBorderTWIPS,mmTWIPS,ppOutput^.Units);

      ppOutput^.Canvas.MoveTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                              iBottomBorder);
      ppOutput^.Canvas.LineTo(iPrnAreaLeft +
                              ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                              iBottomBorder);
    end; // if

    Inc(n);
  end; // while
end; // DrawBodyCellBorders

//***************************************************************************
//
//  FUNCTION  :`PrintTableRow
//
//  I/P       : bHeader (boolean) - TRUE if we are printing a header
//                row.
//
//              tptTable[ct].headerRowText (array of strings) - The text for each cell.
//                or
//              tptTable[ct].bodyRowText (array of strings) - The text for each cell.
//
//  O/P       : tptTable[ct].siCurrentBodyColumn - If this was a boy row that was
//              printed, reset to 0, to show that a new row
//              has been started, but that it contains no text.
//
//  OPERATION : Prints a single row of a table (header or body).
//
//  UPDATED   : 2019-08-19
//
//***************************************************************************
procedure PrintTableRow(bHeader : boolean);
var
  tcaColumns : TTableColumns;
  bRowCompleted : boolean;
  iLineHeight : Integer;
  iLineWidth : Integer;
  n : Integer;
  sOneLine : String;
  iTopBorderPos : Integer;
  aiBottomBorderPos : array of integer;
  iLowestBottomBorderPos : Integer;
  bPageSpanned : boolean;
  saCellsText : TRowOfText;
  iSmallestTopGutter : Integer;
  siColumn : shortint;
  iNewYPos : Integer;

  procedure ColourBackground(idCol, xl, yt, xr, yb : Integer);
  begin
    if (((bHeader) and
         (tptTable[ct].headerBGColour[idCol] <> clWhite)) or
        ((not bHeader) and
         (tptTable[ct].bodyBGColour[idCol] <> clWhite)))   then
    begin
      ppOutput^.Canvas.Brush.Style := bsSolid;
      if (bHeader) then
      begin
        ppOutput^.Canvas.Brush.Color := tptTable[ct].headerBGColour[idCol];
      end // if
      else
      begin
        ppOutput^.Canvas.Brush.Color := tptTable[ct].bodyBGColour[idCol];
      end; // else

      ppOutput^.Canvas.FillRect(Rect(xl, yt, xr, yb));
    end; // if
  end; // ColourBackground

begin
  // Set up the array that records the lowest position reached in each cell
  SetLength(aiBottomBorderPos,tptTable[ct].iTableColumns);

  // Select the cell definitions to be used.
  if (bHeader) then
    tcaColumns := tptTable[ct].headerColumns
  else
    tcaColumns := tptTable[ct].bodyColumns;

  // Make a working copy of the text to be printed in this row
  siColumn := 1;
  while (siColumn <= tptTable[ct].iTableColumns) do
  begin
    if (bHeader) then
      saCellsText[siColumn] := tptTable[ct].headerRowText[siColumn]
    else
      saCellsText[siColumn] := tptTable[ct].bodyRowText[siColumn];
    Inc(siColumn);
  end; // while

  // Check whether there is enough space to print at least one row in each
  // of the cells in this row.   If not, we must start a new page.
  // Cycle through all the used columns to check the minimum height that
  // they would occupy i.e. the height with only one line of text.
  siColumn := 1;
  iLineHeight := 0;
  while (siColumn <= tptTable[ct].iTableColumns) do
  begin
    // Set the font details to those defined for this column
    ppOutput^.Canvas.Font.Name := tcaColumns[siColumn].sFontName;
    if (bHeader) then
    begin
      ppOutput^.Canvas.Font.Style := tptTable[ct].headerStyle[siColumn];
      ppOutput^.Canvas.Font.Size := tptTable[ct].headerFontSize[siColumn];
    end // if
    else
    begin
      ppOutput^.Canvas.Font.Style := tptTable[ct].bodyStyle[siColumn];
      ppOutput^.Canvas.Font.Size := tptTable[ct].bodyFontSize[siColumn];
    end; // else
    // Keep a running figure of the tallest line of text in this row (note that empty strings
    // also occupy height)
    iLineHeight := Max(iLineHeight,ppOutput^.ConvertY(tcaColumns[siColumn].iTopGutterPt,mmPoints,ppOutput^.Units) +
                                   ppOutput^.Canvas.TextHeight('A') +
                                   ppOutput^.ConvertY(tcaColumns[siColumn].iBottomGutterPt,mmPoints,ppOutput^.Units));
    Inc(siColumn);
  end; // while
  // Check if this height can be fitted in to what remains of the current page
  if (iCurrentYPos + iLineHeight > iPrnAreaBottom) then
  begin
    // If not, start a new page
    StartNewPage(FALSE);
    // Check if we must put column headers at the start of this page
    if ((not bHeader) and (tptTable[ct].bReprintHeaderRow)) then
      PrintTableRow(TRUE);
  end; // if

  // Initially, we will not have spanned a page
  bPageSpanned := FALSE;
  // Process the data until there is nothing more to be printed.
  repeat
    // Record the position of the top of the row, so that we can later draw the top border
    iTopBorderPos := iCurrentYPos;
    iLowestBottomBorderPos := iCurrentYPos; // Was 0

    // Initially assume that the row will be printed in a single pass (i.e. it will not
    // span a page break)
    bRowCompleted := TRUE;
    // Cycle through all the used columns to see what can be printed from each
    siColumn := 1;
    while (siColumn <= tptTable[ct].iTableColumns) do
    begin
      // Set the font details to those defined for this column
      ppOutput^.Canvas.Font.Name := tcaColumns[siColumn].sFontName;
      if (bHeader) then
      begin
        ppOutput^.Canvas.Font.Style := tptTable[ct].headerStyle[siColumn];
        ppOutput^.Canvas.Font.Size := tcaColumns[siColumn].iFontSize;
      end // if
      else
      begin
        ppOutput^.Canvas.Font.Style := tptTable[ct].bodyStyle[siColumn];
        ppOutput^.Canvas.Font.Size := tptTable[ct].bodyFontSize[siColumn];
      end; // else
      ppOutput^.Canvas.Font.Color := tptTable[ct].bodyFGColour[siColumn]; // tcaColumns[siColumn].cFontColour;
      ppOutput^.Canvas.Brush.Color := tptTable[ct].bodyBGColour[siColumn]; // tcaColumns[siColumn].cBackgroundColour;
      // Determine the height of each line at the current font
      iLineHeight := ppOutput^.Canvas.TextHeight('A');
      // Colour in the "space before" area with the background colour, as required
      if (ppOutput^.ConvertY(tcaColumns[siColumn].iTopGutterPt,mmPoints,ppOutput^.Units) <> 0) then
      begin
        ColourBackground(siColumn,
                         iPrnAreaLeft +
                           ppOutput^.ConvertX(tcaColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                         iTopBorderPos,
                         iPrnAreaLeft +
                           ppOutput^.ConvertX(tcaColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                         iTopBorderPos +
                           ppOutput^.ConvertY(tcaColumns[siColumn].iTopGutterPt,mmPoints,ppOutput^.Units));
      end; // if
      // Move the starting position of this cell down by the "space before" amount
      iCurrentYPos := iTopBorderPos + ppOutput^.ConvertY(tcaColumns[siColumn].iTopGutterPt,mmPoints,ppOutput^.Units);

      // Remove all line feed characters - we treat a #13 as a linefeed/carriage return
      saCellsText[siColumn] := SearchAndReplace(saCellsText[siColumn],#10,'');

      // Build up each printable line in the cell
      sOneLine := '';
      n := 1;
// !! This is not totally correct, but we may assume that if we have split the row with a page
// break, then all text within each cell will have printed their first lines, and will be on
// follow-on lines.   This can get quite complex if cell text has paragraphs, and may require an
// array element for each column, to see whether this is so.
      bFirstParaLine := not bPageSpanned;

      // There is a special case handling if the cell text was an empty string?
      if (Length(saCellsText[siColumn]) = 0) then
      begin
        if (bHeader) then
          PrintHeaderCellLine(sOneLine,siColumn)
        else
          PrintBodyCellLine(sOneLine,siColumn);
        // Move the Y=position down by a line feed plus the bottom gutter space
        iNewYPos := iCurrentYPos + iLineHeight +
                    ppOutput^.ConvertY(tcaColumns[siColumn].iBottomGutterPt,mmPoints,ppOutput^.Units);
        // Colour in the background, as required
        ColourBackground(siColumn,
                         iPrnAreaLeft +
                           ppOutput^.ConvertX(tcaColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                         iCurrentYPos + iLineHeight,
                         iPrnAreaLeft +
                           ppOutput^.ConvertX(tcaColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                         iNewYPos);
        iCurrentYPos := iNewYPos;
        // Record the lowest position that we got to in this cell.
        aiBottomBorderPos[siColumn-1] := iCurrentYPos;
      end // if
      else
      begin
        // Handle all the characters that are in the cell's text
        while (n <= Length(saCellsText[siColumn])) do
        begin
          // Build up the line to be printed
          sOneLine := sOneLine + saCellsText[siColumn][n];
          // Check for any Carriage Returns within the paragraph string.
          if (saCellsText[siColumn][n] = #13) then
          begin
            if (bHeader) then
              PrintHeaderCellLine(Copy(sOneLine,1,Length(sOneLine)-1),siColumn)
            else
              PrintBodyCellLine(Copy(sOneLine,1,Length(sOneLine)-1),siColumn);
            // We have ended a paragraph, so the next line will be treated as the start of a new paragraph
            bFirstParaLine := TRUE;
            // Determine the new Y-position.   Move down by the line height plus the inter-paragraph
            // height.
            iNewYPos := iCurrentYPos + iLineHeight +
                        ppOutput^.ConvertY(tcaColumns[siColumn].iInterParaPt,mmPoints,ppOutput^.Units);
            // Colour in the background of the inter-paragraph gap, as required
            ColourBackground(siColumn,
                             iPrnAreaLeft +
                               ppOutput^.ConvertX(tcaColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                             iCurrentYPos + iLineHeight,
                             iPrnAreaLeft +
                               ppOutput^.ConvertX(tcaColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                             iNewYPos);
            iCurrentYPos := iNewYPos;
            sOneLine := '';
            // Check whether this carriage return was the last character in this cell
            if (n = Length(saCellsText[siColumn])) then
            begin
              // Move the Y=position down by a line feed plus the bottom gutter space
              iNewYPos := iCurrentYPos + iLineHeight +
                          ppOutput^.ConvertY(tcaColumns[siColumn].iBottomGutterPt,mmPoints,ppOutput^.Units);
              // Colour in the background if this empty line plus the bottom gutter
              // space, as required
              ColourBackground(siColumn,
                               iPrnAreaLeft +
                                 ppOutput^.ConvertX(tcaColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                               iCurrentYPos,
                               iPrnAreaLeft +
                                 ppOutput^.ConvertX(tcaColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                               iNewYPos);
              iCurrentYPos := iNewYPos;
              // Remove the text that has been printed in this cell, so that it will
              // not get printed again if there is a page break caused by the content
              // of another cell
              saCellsText[siColumn] := '';
              // Record the lowest position that we got to in this cell.
              aiBottomBorderPos[siColumn-1] := iCurrentYPos;
            end // if
            else
//!! This is where I must work out how to stop page splitting in a row.
//!! Permit page spanning if the cell height is alway going to be more than the available page
// height (how can we establish this fact?)
// If this was NOT the last character in the cell, there is a chance that the next paragraph
// could be too low to be continued on this page.
// Flag that there will be a page-break in the row if the next line that we will be printing from
// this cell will not fit on the current page (with the requested gutter after it).
// Note that the current Y position indicates the bottom of the text.
              if ((iCurrentYPos + ppOutput^.ConvertY(tcaColumns[siColumn].iBottomGutterPt,mmPoints,ppOutput^.Units)) >=
                  (iPrnAreaBottom - iLineHeight)) then
              begin
                bRowCompleted := FALSE;
                // Remove the text that has already been printed in this cell
                saCellsText[siColumn] := Copy(saCellsText[siColumn],n+1,Length(saCellsText[siColumn]));
                // Force completion of this cell text
                n := Length(saCellsText[siColumn]);
                // Store the bottom of the printable area as the bottom of the last
                // printed row, with the space after
                aiBottomBorderPos[siColumn-1] := iCurrentYPos -
                                                 iLineHeight +
                                                 ppOutput^.ConvertY(tcaColumns[siColumn].iInterParaPt,mmPoints,ppOutput^.Units);
              end // if
              else
              begin
                // Remove the text that has already been printed in this cell
                saCellsText[siColumn] := Copy(saCellsText[siColumn],n+1,Length(saCellsText[siColumn]));
                n := 0;
              end; // else
          end // if
          else
            // Check for the end of the cell's text
            if (n >= Length(saCellsText[siColumn])) then
            begin
              if (bHeader) then
                PrintHeaderCellLine(sOneLine,siColumn)
              else
                PrintBodyCellLine(sOneLine,siColumn);
              // Move the Y=position down by a line feed plus the bottom gutter space
              iNewYPos := iCurrentYPos + iLineHeight +
                          ppOutput^.ConvertY(tcaColumns[siColumn].iBottomGutterPt,mmPoints,ppOutput^.Units);
              // Colour in the background, as required
              ColourBackground(siColumn,
                               iPrnAreaLeft +
                                 ppOutput^.ConvertX(tcaColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                               iCurrentYPos + iLineHeight,
                               iPrnAreaLeft +
                                 ppOutput^.ConvertX(tcaColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                               iNewYPos);
              iCurrentYPos := iNewYPos;
              sOneLine := '';
              // Remove the text that has been printed in this cell, so that it
              // will not get printed again if there is a page break caused by
              // the content of another cell
              saCellsText[siColumn] := '';
              // Record the lowest position that we got to in this cell.
              aiBottomBorderPos[siColumn-1] := iCurrentYPos;
            end // if
            else
            begin
              // Get the length of the line within the cell
              iLineWidth := 2 * ppOutput^.ConvertX(tcaColumns[siColumn].iLRGutterWidthMM100,mmHiMetric,ppOutput^.Units) +
                            ppOutput^.Canvas.TextWidth(sOneLine);
              if ((tpParagraph.taAlignment = taLeftJustify) and (not bFirstParaLine)) then
                iLineWidth := iLineWidth +
                              ppOutput^.ConvertX(tcaColumns[siColumn].iHangingIndentLeftMM100,mmHiMetric,ppOutput^.Units);
              // Check for overflow of a line i.e. the line cannot fit in the width of the cell
              if (iLineWidth  > (ppOutput^.ConvertX(tcaColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units) -
                                 ppOutput^.ConvertX(tcaColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units))) then
              begin
                // Check whether the string contains a space in a position other
                // than the first location, to which we can back-step for a line break
                if (Pos(' ',sOneLine)>1) then
                begin
                  // Find out where this string started in the original cell string
                  n := n - Length(sOneLine);
                  // Shorten the string up to before the space, where we will create a soft line break
                  sOneLine := RemoveFromLast(sOneLine,' ');
                  // Set the point to clip the original cell string
                  n := n + Length(sOneLine) + 2;
                end // if
                else
                begin
                  // Shorten the string by one character, because that length was
                  // found to fit into the cell on the previous loop.
                  sOneLine := Copy(sOneLine,1,Length(sOneLine)-1);
                  // Set the point to clip the original string
                  n := Length(sOneLine) + 1;
                end; // else
                if (bHeader) then
                  PrintHeaderCellLine(sOneLine,siColumn)
                else
                  PrintBodyCellLine(sOneLine,siColumn);
                // Move the Y=position down by a line feed (we are still within the cell text)
                iNewYPos := iCurrentYPos + iLineHeight;
                // Colour in the background, as required
                ColourBackground(siColumn,
                                 iPrnAreaLeft +
                                   ppOutput^.ConvertX(tcaColumns[siColumn].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                                 iCurrentYPos + iLineHeight,
                                 iPrnAreaLeft +
                                   ppOutput^.ConvertX(tcaColumns[siColumn].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                                 iNewYPos);
                iCurrentYPos := iNewYPos;
// Remove the text that has been printed in this cell, so that it will not get printed again if
// there is a page break caused by the content of another cell
                saCellsText[siColumn] := Copy(saCellsText[siColumn],n,Length(saCellsText[siColumn]));
                n := 0;
                sOneLine := '';
//!! This is where I must work out how to stop page splitting in a row.
//!! Permit page spanning if the cell height is alway going to be more than the available page
// height (how can we establish this fact?)
// Flag that there will be a page-break in the row if the next line that we will be printing from
// this cell will not fit on the current page (with the requested gutter space after it).
// Note that the current Y position indicates the bottom of the text.
                if ((iCurrentYPos + ppOutput^.ConvertY(tcaColumns[siColumn].iBottomGutterPt,mmPoints,ppOutput^.Units)) >=
                    (iPrnAreaBottom - iLineHeight)) then
                begin
                  bRowCompleted := FALSE;
                  // Force completion of this cell text
                  n := Length(saCellsText[siColumn]);
                  // Store the bottom of the printable area as the bottom of the last printed
                  // row, with the space after
                  aiBottomBorderPos[siColumn-1] := iCurrentYPos -
                                                   iLineHeight +
                                                   ppOutput^.ConvertY(tcaColumns[siColumn].iBottomGutterPt,mmPoints,ppOutput^.Units);
                end; // if
                // Flag that we are still in the same paragraph, but are now in run-on lines.
                bFirstParaLine := FALSE;
              end; // if
            end; // else
          // Move on to the next character in the cell text
          Inc(n);
        end; // while
      end; // else
      // Move on to the next column
      Inc(siColumn);
    end; // while

    // If the row has not been completed, it means that the page has been spanned
    bPageSpanned := not bRowCompleted;
    if (bPageSpanned) then
    begin
      // Check if we permit a row to span a page
      if (not tptTable[ct].bPermitPageBreakInRow) then
      begin
        // There is a request to prevent rows from spanning a page.
        // We must check whether this was the only row in the page.
        // !! How do we check this?
        // We cannot obey the request to not let a row span a page if this is
        // the only row in the page.
        // It must then span, or we will end up in an infinite loop!!

        // Wipe out what has been printed of the row
        // Problems that I encountered in trying to remove a border have caused
        // me to leave border drawing until I know that the row is staying on
        // this page.   The following code thus only wipes the area that would
        // be covered by the text.
        siColumn := 1;
        iSmallestTopGutter := MAXINT;
        while (siColumn <= tptTable[ct].iTableColumns) do
        begin
          iSmallestTopGutter := Min(iSmallestTopGutter,
                                    ppOutput^.ConvertY(tcaColumns[siColumn].iTopGutterPt,mmPoints,ppOutput^.Units));
          Inc(siColumn);
        end; // while
        ppOutput^.Canvas.Brush.Color := clWhite;
        ppOutput^.Canvas.Brush.Style := bsSolid;
        ppOutput^.Canvas.FillRect(Rect(iPrnAreaLeft,
                                       iTopBorderPos + iSmallestTopGutter,
                                       iPrnAreaRight,
                                       iPrnAreaBottom)); // ibottomBorderPos
        // Restore the strings that make up the row, so that we can start again on the next page.
        siColumn := 1;
        while (siColumn <= tptTable[ct].iTableColumns) do
        begin
          saCellsText[siColumn] := tptTable[ct].bodyRowText[siColumn];
          Inc(siColumn);
        end; // while
      end // if
      else
      begin
        // Determine the position of the bottom line/border of the cell row
        for n := 0 to tptTable[ct].iTableColumns-1 do
          if (aiBottomBorderPos[n] > iLowestBottomBorderPos) then
            iLowestBottomBorderPos := aiBottomBorderPos[n];
        // Fill in any colouring-in that may be missing at the bottom of the
        // shorter cells.
        for n := 1 to tptTable[ct].iTableColumns do
        begin
          ColourBackground(n,
                           iPrnAreaLeft +
                             ppOutput^.ConvertX(tcaColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                           aiBottomBorderPos[n-1],
                           iPrnAreaLeft +
                             ppOutput^.ConvertX(tcaColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                           iLowestBottomBorderPos);
        end; // for
        // This partial row will be left on the page, so produce the required borders
        // around the cells in this row.
        if (bHeader) then
          DrawHeaderCellBorders(iTopBorderPos,iLowestBottomBorderPos)
        else
          DrawBodyCellBorders(iTopBorderPos,iLowestBottomBorderPos);
      end; // else
      StartNewPage(FALSE);
      // Check if we must put column headers at the start of this page
      if ((not bHeader) and (tptTable[ct].bReprintHeaderRow)) then
        PrintTableRow(TRUE);
    end // if
    else
    begin
      // Determine the position of the bottom line/border of the cell row
      for n := 0 to tptTable[ct].iTableColumns-1 do
        if (aiBottomBorderPos[n] > iLowestBottomBorderPos) then
          iLowestBottomBorderPos := aiBottomBorderPos[n];
      // Fill in any colouring-in that may be missing at the bottom of the
      // shorter cells.
      for n := 1 to tptTable[ct].iTableColumns do
      begin
        ColourBackground(n,
                         iPrnAreaLeft +
                           ppOutput^.ConvertX(tcaColumns[n].iColumnLeftMM100,mmHiMetric,ppOutput^.Units),
                         aiBottomBorderPos[n-1],
                         iPrnAreaLeft +
                           ppOutput^.ConvertX(tcaColumns[n].iColumnRightMM100,mmHiMetric,ppOutput^.Units),
                         iLowestBottomBorderPos);
      end; // for

      // This row fits on the page, so produce the required borders around the cells in this row
      if (bHeader) then
        DrawHeaderCellBorders(iTopBorderPos,iLowestBottomBorderPos)
      else
        DrawBodyCellBorders(iTopBorderPos,iLowestBottomBorderPos);
    end; // else

  until (bRowCompleted);

  // Adjust the lowest position used to take into account the thickness of any
  // bottom borders in this row. Note the div 2, since the line is drawn on the
  // lowest bottom border pos, half the width on each side of the Y-position.
  iLowestBottomBorderPos := iCurrentYPos;
  for n := 0 to tptTable[ct].iTableColumns-1 do
  begin
    if (bHeader) then
    begin
      iLowestBottomBorderPos := Max(iLowestBottomBorderPos,
                                    aiBottomBorderPos[n] +
                                    ppOutput^.ConvertX(tptTable[ct].headerColumns[n].iBottomBorderTWIPS,
                                                       mmTWIPS,ppOutput^.Units) div 2);
    end // if
    else
    begin
      iLowestBottomBorderPos := Max(iLowestBottomBorderPos,
                                    aiBottomBorderPos[n] +
                                    ppOutput^.ConvertX(tptTable[ct].bodyColumns[n].iBottomBorderTWIPS,
                                                       mmTWIPS,ppOutput^.Units) div 2);
    end; // else
  end; // for

  // Set the new Y position, ready for the next row
  iCurrentYPos := iLowestBottomBorderPos;

  // Reset the insertion column of the row type (header or body) that has just
  // been printed, ready to collect new text into the cells.
  if (bHeader) then
  begin
    tptTable[ct].siCurrentHeaderColumn := 0;
  end // if
  else
  begin
    tptTable[ct].siCurrentBodyColumn := 0;
  end;
end; // PrintTableRow

//***************************************************************************
//
//  FUNCTION  : UseTable
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
procedure UseTable(idxTable : Integer);
begin
  if (idxTable < MAX_TABLES) then
  begin
    // Terminate a previously active table, printing anything remaining.
    EndTable;

    ct := idxTable;
  end;
end; // UseTable

//***************************************************************************
//
//  FUNCTION    :   DefineTable
//
//  I/P         :   iTableLeft(integer) - The X position of the left side
//                    of the table (in MM100) that is about to be defined.
//
//                  iColumnWidths (array of integer) - The widths of each
//                    column in the table in 100ths of mm.
//
//  O/P         :   tptTable[ct].headerColumns and tptTable[ct].bodyColumns - Have their column
//                    widths and left/right edges defined.
//
//                  tptTable[ct].iTableColumns - Set to the number of columns in the
//                    table.
//
//  OPERATION   :   Any unfinished row is printed.
//
//                  Undefines all table columns and header columns.
//
//                  Destroys any current table.
//
//  UPDATED     :   2018-11-07
//
//***************************************************************************
procedure DefineTable(iTableLeft : Integer;
                      iColumnWidths : array of integer);
var
  n : Integer;
  iLeft : Integer;

begin
  // Terminate a previously active table, printing anything remaining.
  EndTable;

  // Set the number of columns in the new table
  tptTable[ct].iTableColumns := High(iColumnWidths) + 1;
  // Define the positions and widths of each header column and body column
  iLeft := iTableLeft;
  for n := 1 to tptTable[ct].iTableColumns do
  begin
    tptTable[ct].bodyColumns[n].iColumnLeftMM100 := iLeft;
    tptTable[ct].headerColumns[n].iColumnLeftMM100 := iLeft;
    iLeft := iLeft + iColumnWidths[n-1];
    tptTable[ct].bodyColumns[n].iColumnRightMM100 := iLeft;
    tptTable[ct].headerColumns[n].iColumnRightMM100 := iLeft;
  end; // for
  // Indicate that there is no active table at present
  tptTable[ct].active := FALSE;
end; // DefineTable

//***************************************************************************
//
//  FUNCTION  : ClearTable
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Sets the current table to non-operational.
//
//  UPDATED   : 2008-06-17
//
//***************************************************************************
procedure ClearTable;
begin
  tptTable[ct].iTableColumns := 0;
  DefineTable(0,[]);
end; // ClearTable

//***************************************************************************
//
//  FUNCTION    :   DefineTableHeaderColumn
//
//  I/P         :   iColumnNumber(integer) - The column number
//
//                  sFontName(string) - Name of the font to be used in the column
//
//                  iFontSize(integer) - Point size of the font in the column
//
//                  cFontColour(TColor) - Colour of the font in the column
//
//                  sfsFontStyle(set of TFontStyle) - Font style in the column
//
//                  siAlignment(shortint) - Line alignment within the column
//
//                  iSpaceBeforePt(integer) - Point spacing between top border and the
//                    top of the text.
//
//                  iSpaceAfterPt(integer) - Point spacing bottom of the text and
//                    the bottom border.   The figure used is the highest in a row.
//
//                  iHangingIndentLeftMM100(integer) - Amount to indent 2nd and later
//                    lines in a paragraph from the left border
//
//                  iLRGutterWidthMM100(integer) - Gap left between the left and right
//                    borders and the edges of the text in the column.
//
//                  iInterParaPt(integer) - Point spacing between paragraphs within a
//                    single cell.
//
//                  cBorderColour(TColour) - The colour to be used for a border
//
//                  iTopBorderTWIPS(integer) - Top border width in 1/20ths of a point.
//
//                  iBottomBorderTWIPS(integer) -  Bottom border width in 1/20ths of a point.
//
//                  iLeftBorderTWIPS(integer) -  Left border width in 1/20ths of a point.
//
//                  iRightBorderTWIPS(integer) -  Right border width in 1/20ths of a point.
//
//                  cBackgroundColour(TColor) -  The background colour of the cell.
//
//  O/P         :   tcaColumns - Updated and sorted
//
//  OPERATION   :   Defines the format of the indicated column header.   A header
//                  is printed, if requested, at the top of a table that breaks
//                  over a page.
//
//  UPDATED     :   2004/04/19
//
//***************************************************************************
procedure DefineTableHeaderColumn(iColumnNumber : Integer;
                                  sFontName : String;
                                  iFontSize : Integer;
                                  cFontColour : TColor;
                                  sfsFontStyle : TFontStyles;
                                  taAlignment : TAlignment;
                                  iTopGutterPt : Integer;
                                  iBottomGutterPt : Integer;
                                  iHangingIndentLeftMM100 : Integer;
                                  iLRGutterWidthMM100 : Integer;
                                  iInterParaPt : Integer;
                                  cBorderColour : TColor;
                                  iTopBorderTWIPS : Integer;
                                  iBottomBorderTWIPS : Integer;
                                  iLeftBorderTWIPS : Integer;
                                  iRightBorderTWIPS : Integer;
                                  cBackgroundColour : TColor);
begin
  // Check if we found an empty slot
  if (iColumnNumber <= tptTable[ct].iTableColumns) then
  begin
    tptTable[ct].headerColumns[iColumnNumber].sFontName := sFontName;
    tptTable[ct].headerColumns[iColumnNumber].iFontSize := iFontSize;
    tptTable[ct].headerColumns[iColumnNumber].cFontColour := cFontColour;
    tptTable[ct].headerColumns[iColumnNumber].sfsFontStyle := sfsFontStyle;
    tptTable[ct].headerColumns[iColumnNumber].taAlignment := taAlignment;
    tptTable[ct].headerColumns[iColumnNumber].iTopGutterPt := itopGutterPt;
    tptTable[ct].headerColumns[iColumnNumber].iBottomGutterPt := iBottomGutterPt;
    tptTable[ct].headerColumns[iColumnNumber].iHangingIndentLeftMM100 := iHangingIndentLeftMM100;
    tptTable[ct].headerColumns[iColumnNumber].iLRGutterWidthMM100 := iLRGutterWidthMM100;
    tptTable[ct].headerColumns[iColumnNumber].iInterParaPt := iInterParaPt;
    tptTable[ct].headerColumns[iColumnNumber].cBorderColour := cBorderColour;
    tptTable[ct].headerColumns[iColumnNumber].iTopBorderTWIPS := iTopBorderTWIPS;
    tptTable[ct].headerColumns[iColumnNumber].iBottomBorderTWIPS := iBottomBorderTWIPS;
    tptTable[ct].headerColumns[iColumnNumber].iLeftBorderTWIPS := iLeftBorderTWIPS;
    tptTable[ct].headerColumns[iColumnNumber].iRightBorderTWIPS := iRightBorderTWIPS;
    tptTable[ct].headerColumns[iColumnNumber].cBackgroundColour := cBackgroundColour;
  end; // if
end; // DefineTableHeaderColumn

//***************************************************************************
//
//  FUNCTION  : AddTableBodyColumn
//
//  I/P       : iColumnNumber (integer) - The column being defined
//
//              sFontName(string) - Name of the font to be used in the column
//
//              iFontSize(integer) - Point size of the font in the column
//
//              cFontColour(TColor) - Colour of the font in the column
//
//              sfsFontStyle(set of TFontStyle) - Font style in the column
//
//              siAlignment(shortint) - Line alignment within the column
//
//              iSoaceBeforePt(integer) - Point spacing between top border and the
//                top of the text.
//
//              iSpaceAfterPt(integer) - Point spacing bottom of the text and
//                the bottom border.   The figure used is the highest in a row.
//
//              iHangingIndentLeftMM100(integer) - Amount to indent 2nd and later
//                lines in a paragraph from the left border
//
//              iLRGutterWidthMM100(integer) - Gap left between the left and right
//                borders and the edges of the text in the column.
//
//              iInterParaPt(integer) - Point spacing between paragraphs within a
//                single cell.

//              cBorderColour(TColour) - The colour to be used for a border
//
//              iTopBorderTWIPS(integer) - Top border width in 1/20ths of a point.
//
//              iBottomBorderTWIPS(integer) -  Bottom border width in 1/20ths of a point.
//
//              iLeftBorderTWIPS(integer) -  Left border width in 1/20ths of a point.
//
//              iRightBorderTWIPS(integer) -  Right border width in 1/20ths of a point.
//
//              cBackgroundColour(TColor) -  The background colour of the cell.
//
//  O/P       : tcaColumns - Updated and sorted
//
//  OPERATION : Defines the properties of the indicated column
//
//  UPDATED   : 2004/04/19
//
//***************************************************************************
procedure DefineTableBodyColumn(iColumnNumber : Integer;
                                sFontName : String;
                                iFontSize : Integer;
                                cFontColour : TColor;
                                sfsFontStyle : TFontStyles;
                                taAlignment : TAlignment;
                                iTopGutterPt : Integer;
                                iBottomGutterPt : Integer;
                                iHangingIndentLeftMM100 : Integer;
                                iLRGutterWidthMM100 : Integer;
                                iInterParaPt : Integer;
                                cBorderColour : TColor;
                                iTopBorderTWIPS : Integer;
                                iBottomBorderTWIPS : Integer;
                                iLeftBorderTWIPS : Integer;
                                iRightBorderTWIPS : Integer;
                                cBackgroundColour : TColor);
begin
  if (iColumnNumber <= tptTable[ct].iTableColumns) then
  begin
    tptTable[ct].bodyColumns[iColumnNumber].sFontName := sFontName;
    tptTable[ct].bodyColumns[iColumnNumber].iFontSize := iFontSize;
    tptTable[ct].bodyColumns[iColumnNumber].cFontColour := cFontColour;
    tptTable[ct].bodyColumns[iColumnNumber].sfsFontStyle := sfsFontStyle;
    tptTable[ct].bodyColumns[iColumnNumber].taAlignment := taAlignment;
    tptTable[ct].bodyColumns[iColumnNumber].iTopGutterPt := itopGutterPt;
    tptTable[ct].bodyColumns[iColumnNumber].iBottomGutterPt := iBottomGutterPt;
    tptTable[ct].bodyColumns[iColumnNumber].iHangingIndentLeftMM100 := iHangingIndentLeftMM100;
    tptTable[ct].bodyColumns[iColumnNumber].iLRGutterWidthMM100 := iLRGutterWidthMM100;
    tptTable[ct].bodyColumns[iColumnNumber].iInterParaPt := iInterParaPt;
    tptTable[ct].bodyColumns[iColumnNumber].cBorderColour := cBorderColour;
    tptTable[ct].bodyColumns[iColumnNumber].iTopBorderTWIPS := iTopBorderTWIPS;
    tptTable[ct].bodyColumns[iColumnNumber].iBottomBorderTWIPS := iBottomBorderTWIPS;
    tptTable[ct].bodyColumns[iColumnNumber].iLeftBorderTWIPS := iLeftBorderTWIPS;
    tptTable[ct].bodyColumns[iColumnNumber].iRightBorderTWIPS := iRightBorderTWIPS;
    tptTable[ct].bodyColumns[iColumnNumber].cBackgroundColour := cBackgroundColour;
  end; // if
end; // DefineTableBodyColumn

//***************************************************************************
//
//  FUNCTION  : SetBodyRowColour
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Overrides the background colour of body cells for the
//              rows (i.e. all columns) that will be printed from here onwards.
//
//  UPDATED   : 2008-02-13
//
//***************************************************************************
procedure SetBodyRowColour(cBackgroundColour : TColor);
var
  n : Integer;
begin
  for n := Low(tptTable[ct].bodyColumns) to High(tptTable[ct].bodyColumns) do
    tptTable[ct].bodyColumns[n].cBackgroundColour := cBackgroundColour;
end; // SetBodyRowColour

//***************************************************************************
//
//  FUNCTION  : StoreTextIntoHeaderCell
//
//  I/P       : sCellText(string) - The text to be printed in this cell.
//                Insert #9 characters to move to next cell.
//
//              overrideIDs : TPrintOverrides = [] - Optional array of override
//                identifiers.
//
//              overrideValues : TPrintOverrideValues = [] - Optional array of
//                override values (matching each of the above override identifiers)
//
//  O/P       : tptTable[ct].headerRowText - updated
//
//              tptTable[ct].siCurrentBodyColumn - indicates the current column
//
//  OPERATION : Add the given text to the next header column/s.
//
//              If specified, certain attributes of the defined table header
//              column may be overridden for this row.
//
//              The row is not printed when it ends.
//
//  UPDATED   : 2020-05-22
//
//***************************************************************************
procedure StoreTextIntoHeaderCell(sCellText : string;
                                  overrideIDs : TPrintOverrides = [];
                                  overrideValues : TPrintOverrideValues = []);
var
  n : Integer;

begin
  repeat
    // Select the column into which this text will be placed.
    Inc(tptTable[ct].siCurrentHeaderColumn);
    // Add the text
    if (Pos(#9,sCellText)<>0) then
    begin
      tptTable[ct].headerRowText[tptTable[ct].siCurrentHeaderColumn] := ExtractAndTrim(sCellText,#9)
    end // if
    else
    begin
      tptTable[ct].headerRowText[tptTable[ct].siCurrentHeaderColumn] := sCellText;
      sCellText := '';
    end; // else

    // Set the defaults
    tptTable[ct].headerAlignment[tptTable[ct].siCurrentHeaderColumn] := tptTable[ct].headerColumns[tptTable[ct].siCurrentHeaderColumn].taAlignment;
    tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] := tptTable[ct].headerColumns[tptTable[ct].siCurrentHeaderColumn].sfsFontStyle;
    tptTable[ct].headerBGColour[tptTable[ct].siCurrentHeaderColumn] := tptTable[ct].headerColumns[tptTable[ct].siCurrentHeaderColumn].cBackgroundColour;
    tptTable[ct].headerFGColour[tptTable[ct].siCurrentHeaderColumn] := tptTable[ct].headerColumns[tptTable[ct].siCurrentHeaderColumn].cFontColour;
    tptTable[ct].headerFontSize[tptTable[ct].siCurrentHeaderColumn] := tptTable[ct].headerColumns[tptTable[ct].siCurrentHeaderColumn].iFontSize;
    // Make any specified cell changes
    n := 0;
    while ((n < Length(overrideIDs)) and
           (n < Length(overrideValues))) do
    begin
      case overrideIDs[n] of
        PRNT_OVR_FONT_SIZE :
          tptTable[ct].headerFontSize[tptTable[ct].siCurrentHeaderColumn] := Integer(overrideValues[n]);
        PRNT_OVR_FONT_COLOUR :
          tptTable[ct].headerFGColour[tptTable[ct].siCurrentHeaderColumn] := TColor(overrideValues[n]);
        PRNT_OVR_BACKGROUND_COLOUR :
          tptTable[ct].headerBGColour[tptTable[ct].siCurrentHeaderColumn] := TColor(overrideValues[n]);
        PRNT_OVR_ALIGNMENT :
          tptTable[ct].headerAlignment[tptTable[ct].siCurrentHeaderColumn] := TAlignment(overrideValues[n]);
        PRNT_OVR_FONT_BOLD :
          if (Boolean(overrideValues[n])) then
            tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] :=
              tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] + [fsBold]
          else
            tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] :=
              tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] - [fsBold];
        PRNT_OVR_FONT_ITALIC :
          if (Boolean(overrideValues[n])) then
            tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] :=
              tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] + [fsItalic]
          else
            tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] :=
              tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] - [fsItalic];
        PRNT_OVR_FONT_UNDERLINE :
          if (Boolean(overrideValues[n])) then
            tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] :=
              tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] + [fsUnderline]
          else
            tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] :=
              tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] - [fsUnderline];
        PRNT_OVR_FONT_STRIKEOUT :
          if (Boolean(overrideValues[n])) then
            tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] :=
              tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] + [fsStrikeOut]
          else
            tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] :=
              tptTable[ct].headerStyle[tptTable[ct].siCurrentHeaderColumn] - [fsStrikeOut];
      end; // case
      Inc(n);
    end; // while

    // Wrap back to the beginning if we have got to the last column
    if (tptTable[ct].siCurrentHeaderColumn >= tptTable[ct].iTableColumns) then
    begin
      tptTable[ct].siCurrentHeaderColumn := 0;
    end;
  until (sCellText = '');
end; // StoreTextIntoHeaderCell

//***************************************************************************
//
//  FUNCTION  : InsertTextIntoHeaderCell
//
//  I/P       : sCellText(string) - The text to be printed in this cell.
//                Insert #9 characters to move to next cell.
//
//              overrideIDs : TPrintOverrides = [] - Optional array of override
//                identifiers.
//
//              overrideValues : TPrintOverrideValues = [] - Optional array of
//                override values (matching each of the above override identifiers)
//
//  O/P       : tptTable[ct].headerRowText - updated
//
//              tptTable[ct].siCurrentBodyColumn - indicates the current column
//
//  OPERATION : Add the given text to the next header column/s and print when
//              the row is ended.
//
//              If specified, certain attributes of the defined table header
//              column may be overridden for this row.
//
//  UPDATED   : 2020-05-22
//
//***************************************************************************
procedure InsertTextIntoHeaderCell(sCellText : string;
                                   overrideIDs : TPrintOverrides = [];
                                   overrideValues : TPrintOverrideValues = []);
begin
  StoreTextIntoHeaderCell(sCellText, overrideIDs, overrideValues);

  // Print the row if the last cell was just entered
  if (tptTable[ct].siCurrentHeaderColumn = 0) then
    PrintTableRow(TRUE);
end; // InsertTextIntoHeaderCell

//***************************************************************************
//
//  FUNCTION  : InsertTextIntoBodyCell
//
//  I/P       : sCellText(string) - The text to be printed in this cell.
//
//              overrideIDs : TPrintOverrides = [] - Optional array of override
//                identifiers.
//
//              overrideValues : TPrintOverrideValues = [] - Optional array of
//                override values (matching each of the above override identifiers)
//
//  O/P       : tptTable[ct].bodyRowText - updated
//
//              tptTable[ct].siCurrentBodyColumn - indicates the current column
//
//  OPERATION : Adds the given text to the next body column.
//              If specified, certain attributes of the defined table body
//              column may be overridden for this row.
//
//  UPDATED   : 2019-09-03
//
//***************************************************************************
procedure InsertTextIntoBodyCell(sCellText : string;
                                   overrideIDs : TPrintOverrides = [];
                                   overrideValues : TPrintOverrideValues = []);
var
  n : Integer;

begin
  repeat
    // Select the column into which this text will be placed.
    Inc(tptTable[ct].siCurrentBodyColumn);
    // If it is the first column, clear the entire row (removing any left-overs
    // from the previous row)
    if (tptTable[ct].siCurrentBodyColumn = 1) then
      for n := 1 to tptTable[ct].iTableColumns do
        tptTable[ct].bodyRowText[n] := '';
    // Add the text
    if (Pos(#9,sCellText)<>0) then
      tptTable[ct].bodyRowText[tptTable[ct].siCurrentBodyColumn] := ExtractAndTrim(sCellText,#9)
    else
    begin
      tptTable[ct].bodyRowText[tptTable[ct].siCurrentBodyColumn] := sCellText;
      sCellText := '';
    end; // else
    // Set the defaults
    tptTable[ct].bodyAlignment[tptTable[ct].siCurrentBodyColumn] := tptTable[ct].bodyColumns[tptTable[ct].siCurrentBodyColumn].taAlignment;
    tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] := tptTable[ct].bodyColumns[tptTable[ct].siCurrentBodyColumn].sfsFontStyle;
    tptTable[ct].bodyBGColour[tptTable[ct].siCurrentBodyColumn] := tptTable[ct].bodyColumns[tptTable[ct].siCurrentBodyColumn].cBackgroundColour;
    tptTable[ct].bodyFGColour[tptTable[ct].siCurrentBodyColumn] := tptTable[ct].bodyColumns[tptTable[ct].siCurrentBodyColumn].cFontColour;
    tptTable[ct].bodyFontSize[tptTable[ct].siCurrentBodyColumn] := tptTable[ct].bodyColumns[tptTable[ct].siCurrentBodyColumn].iFontSize;
    // Make any specified cell changes
    n := 0;
    while ((n < Length(overrideIDs)) and
           (n < Length(overrideValues))) do
    begin
      case overrideIDs[n] of
        PRNT_OVR_FONT_SIZE :
          tptTable[ct].bodyFontSize[tptTable[ct].siCurrentBodyColumn] := Integer(overrideValues[n]);
        PRNT_OVR_FONT_COLOUR :
          tptTable[ct].bodyFGColour[tptTable[ct].siCurrentBodyColumn] := TColor(overrideValues[n]);
        PRNT_OVR_BACKGROUND_COLOUR :
          tptTable[ct].bodyBGColour[tptTable[ct].siCurrentBodyColumn] := TColor(overrideValues[n]);
        PRNT_OVR_ALIGNMENT :
          tptTable[ct].bodyAlignment[tptTable[ct].siCurrentBodyColumn] := TAlignment(overrideValues[n]);
        PRNT_OVR_FONT_BOLD :
          if (Boolean(overrideValues[n])) then
            tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] :=
              tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] + [fsBold]
          else
            tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] :=
              tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] - [fsBold];
        PRNT_OVR_FONT_ITALIC :
          if (Boolean(overrideValues[n])) then
            tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] :=
              tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] + [fsItalic]
          else
            tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] :=
              tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] - [fsItalic];
        PRNT_OVR_FONT_UNDERLINE :
          if (Boolean(overrideValues[n])) then
            tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] :=
              tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] + [fsUnderline]
          else
            tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] :=
              tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] - [fsUnderline];
        PRNT_OVR_FONT_STRIKEOUT :
          if (Boolean(overrideValues[n])) then
            tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] :=
              tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] + [fsStrikeOut]
          else
            tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] :=
              tptTable[ct].bodyStyle[tptTable[ct].siCurrentBodyColumn] - [fsStrikeOut];
      end; // case
      Inc(n);
    end; // while

    // Print the row if we have got to the last column
    if (tptTable[ct].siCurrentBodyColumn >= tptTable[ct].iTableColumns) then
      PrintTableRow(FALSE);
  until (sCellText = '');
end; // InsertTextIntoBodyCell

//***************************************************************************
//
//  FUNCTION  : BodyRowComplete
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the last body row was completed and/or the
//                current body row has not yet received any cell insertions
//
//  OPERATION : Used to check if the current row has been partially created.
//              This function may be called before a call to CompleteBodyRow
//
//  UPDATED   : 2019-08-27
//
//***************************************************************************
function BodyRowComplete : Boolean;
begin
  result := (tptTable[ct].siCurrentBodyColumn = 0)
end; // BodyRowComplete

//***************************************************************************
//
//  FUNCTION  : CompleteBodyRow
//
//  I/P       : sFill (string) - The string to put in each of the remaining
//                cells in the row
//
//  O/P       : None
//
//  OPERATION : Fills the remainder of the current row with empty cells.
//              A new row must have been started i.e. this is not meant to be
//              used to create an empty row.
//
//  UPDATED   : 2018-11-12
//
//***************************************************************************
procedure CompleteBodyRow(sFill : string);
begin
  if (tptTable[ct].siCurrentBodyColumn <> 0) then
    InsertTextIntoBodyCell(DupeString(sFill+#09,tptTable[ct].iTableColumns - tptTable[ct].siCurrentBodyColumn));
end; // CompleteBodyRow

//***************************************************************************
//
//  FUNCTION  : PrintTableHeader
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Prints the current table header row, if one is active.
//
//  UPDATED   : 2019-08-16
//
//***************************************************************************
procedure PrintTableHeader;
begin
  if (tptTable[ct].active) then
  begin
    PrintTableRow(TRUE);
  end;
end; // PrintTableHeader

//***************************************************************************
//
//  FUNCTION  : StartTable
//
//  I/P       : allowRowPageSpanning (boolean) -
//
//              startPagesWithHeaderRow (boolean) - TRUE if the header row
//                should be reprinted at the start of a new page in a table
//                that has split over a page.
//
//  O/P       : tptTable[ct].siCurrentBodyColumn - Reset to show the table has started.
//
//                  saColumns - Contents cleared.
//
//  OPERATION : Initialises the implementation of a table
//
//  UPDATED   : 2020-05-22
//
//***************************************************************************
procedure StartTable(allowRowPageSpanning : boolean;
                     startPagesWithHeaderRow : boolean);
var
  n : Integer;
begin
  // Indicate that a table has been started, but that there is not yet any text in the row
  tptTable[ct].active := TRUE;
  tptTable[ct].siCurrentBodyColumn := 0;
  tptTable[ct].siCurrentHeaderColumn := 0;
  // Store the permission to break a row across a page
  tptTable[ct].bPermitPageBreakInRow := allowRowPageSpanning;
  // Store whether the header row should be reprinted at the start of a new
  // page in a table that has split over a page
  tptTable[ct].bReprintHeaderRow := startPagesWithHeaderRow;
  // Clear all text from the column headers row
  for n := 1 to MAX_COLUMNS do
    tptTable[ct].headerRowText[n] := '';
  // Clear all text from this body row
  for n := 1 to MAX_COLUMNS do
    tptTable[ct].bodyRowText[n] := '';
end; // StartTable

//***************************************************************************
//
//  FUNCTION    :   EndTable
//
//  I/P         :   None.
//
//  O/P         :   tptTable[ct].Active set to FALSE.
//
//  OPERATION   :   Terminates the implementation/generation of a table.
//
//                  An imcomplete row will be completed.
//
//  UPDATED     :   2018-11-07
//
//***************************************************************************
procedure EndTable;
begin
  // If the table was active, complete the printing of the current row,
  // if it contains any unprinted cells
  if ((tptTable[ct].Active) and
      (tptTable[ct].siCurrentBodyColumn > 0)) then
    PrintTableRow(FALSE);

  // Indicate that the table is complete
  tptTable[ct].active := FALSE;
end; // EndTable

//***************************************************************************
//
//  FUNCTION  : PrintGraphic
//
//  I/P       : iX,iY (integer) - The top left corner of the BMP, in
//                HiMetric
//
//              iWidth (integer) - The printed width of the image, in HiMetric
//
//              bmPicture (TBitMap) - The image to be printed
//
//  O/P       : Integer - The Y-position, in mmHiMetric, of the base of the BMP
//
//  OPERATION : Prints the given BMP
//
//  UPDATED   : 2020-05-04
//
//***************************************************************************
function PrintGraphic(iX,iY : Integer;
                  iWidth : Integer;
                  gPicture : TGraphic) : Integer; overload;
var
  iBMPWidth : Integer;
  iBMPHeight : Integer;

begin
  if (Assigned(ppOutput)) then
  begin
    iBMPWidth := ppOutput^.ConvertX(iWidth, mmHiMetric, ppOutput^.Units);
    iBMPHeight := ppOutput^.ConvertX((gPicture.Height * iWidth) div  gPicture.Width, mmHiMetric, ppOutput^.Units);

  (*
    ppOutput^.Canvas.StretchDraw(Rect(ppOutput^.ConvertX(iX,mmHiMetric,ppOutput^.Units),
                                      ppOutput^.ConvertY(iY,mmHiMetric,ppOutput^.Units),
                                      ppOutput^.ConvertX(iX,mmHiMetric,ppOutput^.Units) + iBMPWidth,
                                      ppOutput^.ConvertY(iY,mmHiMetric,ppOutput^.Units) + iBMPHeight),
                                 bmPicture);
  *)
  //!!ANS*BUSY HERE
  (*
  // Had problems with PaintGraphicEx at TraX in Sept 2015.
  // It occasionally produced black (or sometimes even other colour) images
  // Although it did not happen every time I used the PC, I did a test one day in which graphics (the TraX logo)
  // placed on TPrintPreview using PaintGraphicEx would cause solid colour blocks (typically black) about
  // 12% of the time.   On another day, I could not get the error to happen.
  // Using ppOutput^.Canvas.StretchDraw resulted in 0% errors on the day when I was getting 12%
  // error with PaintGraphicEx.
  // I need to investigate further on a day when black blocks are being produced.
  // 1) Check typecasting of the TBitmap before passing it to PaintGraphicEx
  // 2) Check pre-clearing the rectangle, as is done in DrawPageLogo, above.
  // 3) Try to write a small application that produces the problem, for demonstration and
  //    return to Kambiz.
  *)

    ppOutput^.PaintGraphicEx(Rect(ppOutput^.ConvertX(iX, mmHiMetric, ppOutput^.Units),
                                  ppOutput^.ConvertY(iY, mmHiMetric, ppOutput^.Units),
                                  ppOutput^.ConvertX(iX, mmHiMetric, ppOutput^.Units) + iBMPWidth,
                                  ppOutput^.ConvertY(iY, mmHiMetric, ppOutput^.Units) + iBMPHeight),
                             gPicture,FALSE,FALSE,FALSE);
  end; // if

  Result := iY + (gPicture.Height * iWidth) div  gPicture.Width;
end; // PrintGraphic

//***************************************************************************
//
//  FUNCTION  : PrintGraphic
//
//  I/P       : iX,iY (integer) - The top left corner of the BMP, in
//                HiMetric
//
//              iWidth (integer) - The printed width of the image, in mmHiMetric
//
//              iHeight (integer) - The printed height of the image, in mmHiMetric
//
//              gPicture (TGraphic) - The image to be printed (TBitMap, TPngImage,
//                tMetaFile, TJPEGImage.....
//
//              stretch : TPrintFitImage = PRNT_IMG_FIT_ALL - Determines how the
//                image may be stretched or scaled to fit the given space.
//
//  O/P       : Integer - The Y-position, in mmHiMetric, of the base of the BMP
//
//  OPERATION : Prints the given BMP
//
//  UPDATED   : 2020-05-04
//
//***************************************************************************
function PrintGraphic(iX,iY : Integer;
                  iWidth : Integer;
                  iHeight : Integer;
                  gPicture : TGraphic;
                  stretch : TPrintFitImage = PRNT_IMG_FIT_ALL) : Integer; overload;
var
  iBMPWidth : Integer;
  iBMPHeight : Integer;
  iLeft : Integer;
  iTop : Integer;

begin
  Result := iY;

  if (Assigned(ppOutput)) then
  begin
    if (stretch = PRNT_IMG_FIT_ALL) then
    begin
      // Stretch the image to fill the indicated space
      iBMPWidth := ppOutput^.ConvertX(iWidth,mmHiMetric,ppOutput^.Units);
      iBMPHeight := ppOutput^.ConvertY(iHeight,mmHiMetric,ppOutput^.Units);
      ppOutput^.Canvas.StretchDraw(Rect(ppOutput^.ConvertX(iX,mmHiMetric,ppOutput^.Units),
                                        ppOutput^.ConvertY(iY,mmHiMetric,ppOutput^.Units),
                                        ppOutput^.ConvertX(iX,mmHiMetric,ppOutput^.Units) + iBMPWidth,
                                        ppOutput^.ConvertY(iY,mmHiMetric,ppOutput^.Units) + iBMPHeight),
                                   gPicture);
      Result := iY + iHeight;
    end // if
    else if (stretch = PRNT_IMG_FIT_WIDTH) then
    begin
      // Stretch the image to fill the indicated width
      // The height should be adjusted to preserve the aspect ratio of the image
      // Centre the Y-position of the image within the indicated space
      if (gPicture.Width <> 0) then
      begin
        iBMPWidth := ppOutput^.ConvertX(iWidth,mmHiMetric,ppOutput^.Units);
        iBMPHeight := ppOutput^.ConvertY((gPicture.Height * iWidth) div  gPicture.Width,
                                         mmHiMetric, ppOutput^.Units);
        iTop := iY + (iHeight - iBMPHeight) div 2;
        ppOutput^.PaintGraphicEx(Rect(ppOutput^.ConvertX(iX,mmHiMetric,ppOutput^.Units),
                                      ppOutput^.ConvertY(iTop,mmHiMetric,ppOutput^.Units),
                                      ppOutput^.ConvertX(iX,mmHiMetric,ppOutput^.Units) + iBMPWidth,
                                      ppOutput^.ConvertY(iTop,mmHiMetric,ppOutput^.Units) + iBMPHeight),
                                 gPicture,FALSE,FALSE,FALSE);
        Result := iY + (gPicture.Height * iWidth) div  gPicture.Width;
      end; // if
    end
    else
    begin
      // Stretch the image to fill the indicated height
      // The width should be adjusted to preserve the aspect ratio of the image
      // Centre the X-position of the image within the indicated space
      if (gPicture.Height <> 0) then
      begin
        iBMPHeight := ppOutput^.ConvertY(iHeight, mmHiMetric,ppOutput^.Units);
        iBMPWidth := ppOutput^.ConvertX((gPicture.Width * iHeight) div  gPicture.Height,
                                        mmHiMetric, ppOutput^.Units);
        iLeft := iX + (iWidth - iBMPWidth) div 2;
        ppOutput^.PaintGraphicEx(Rect(ppOutput^.ConvertX(iLeft,mmHiMetric,ppOutput^.Units),
                                      ppOutput^.ConvertY(iY,mmHiMetric,ppOutput^.Units),
                                      ppOutput^.ConvertX(iLeft,mmHiMetric,ppOutput^.Units) + iBMPWidth,
                                      ppOutput^.ConvertY(iY,mmHiMetric,ppOutput^.Units) + iBMPHeight),
                                 gPicture,FALSE,FALSE,FALSE);
        Result := iY + iHeight;
      end; // if
    end; // else
  end; // if
end; // PrintGraphic

//***************************************************************************
//
//  FUNCTION    :   MM100TobBottomOfPage
//
//  I/P         :   None.
//
//  O/P         :   integer : The distance, in 100ths of mm, that remains
//                    for printing from the current print position to
//                    the end of the printable area on this page.
//
//  OPERATION   :   Determines how much space there is left for printing
//                  on the current page.
//
//  UPDATED     :   2005/02/07
//
//***************************************************************************
function MM100ToBottomOfPage : Integer;
begin
 result := iPrnAreaBottom - iCurrentYPos;
end; // MM100ToBottomOfPage

//***************************************************************************
//
//  FUNCTION  : PageBreakIfLTmm
//
//  I/P       : MinMMRemaining : Integer - Minimum permissable remaining printing
//                area at the bottom of the page
//
//  O/P       : Boolean - TRUE if a new page was started.
//
//  OPERATION : If there is less than the specified number of millimetres of
//              print space remaining on the page, start a new page.
//
//  UPDATED   : 2016-03-29
//
//***************************************************************************
function PageBreakIfLTmm(MinMMRemaining : integer) : boolean;
begin
  if (MM100ToBottomOfPage >= ppOutput^.ConvertY(MinMMRemaining*10,mmLoMetric,ppOutput^.Units)) then
    result := FALSE
  else
  begin
    StartNewPage(FALSE);
    result := TRUE;
  end; // else
end; // PageBreakIfLTmm

//***************************************************************************
//
//  FUNCTION  : GetPrnFnValue
//
//  I/P       : iValueID (integer) - Indicates the Print Function value
//                that is required
//
//  O/P       : (integer) - The required value
//
//  OPERATION : Returns various internal Print function values.   This is
//              used rather than exposing these internal variables.
//
//              Access to these values would normally only required when
//              drawing graphics on a page.
//
//  UPDATED   : 2010-05-04
//
//***************************************************************************
function GetPrnFnValue(iValueID : integer) : Integer;
begin
  case iValueID of
    PF_LEFT_MARGIN :
      Result := iPageLeftMargin;
    PF_TOP_MARGIN :
      Result := iPageTopMargin;
    PF_RIGHT_MARGIN :
      Result := iPageRightMargin;
    PF_BOTTOM_MARGIN :
      Result := iPageBottomMargin;
    PF_WIDTH_MARGIN :
      Result := iPageWidthMargin;
    PF_HEIGHT_MARGIN :
      Result := iPageHeightMargin;
    PF_LEFT_AREA :
      Result := iPrnAreaLeft;
    PF_TOP_AREA :
      Result := iPrnAreaTop;
    PF_RIGHT_AREA :
      Result := iPrnAreaRight;
    PF_BOTTOM_AREA :
      Result := iPrnAreaBottom;
    PF_WIDTH_AREA :
      Result := iPrnAreaWidth;
    PF_HEIGHT_AREA :
      Result := iPrnAreaHeight;
    PF_YPOS :
      Result := iCurrentYPos;
    PF_TABLE_COLUMNS :
      Result := tptTable[ct].iTableColumns;
    PF_TABLE_LEFT :
      if (tptTable[ct].iTableColumns > 0) then
        Result := tptTable[ct].bodyColumns[1].iColumnLeftMM100
      else
        Result := -1;
    PF_TABLE_RIGHT :
      if (tptTable[ct].iTableColumns > 0) then
        Result := tptTable[ct].bodyColumns[tptTable[ct].iTableColumns].iColumnRightMM100
      else
        Result := -1;
    PF_TABLE_WIDTH :
      if (tptTable[ct].iTableColumns > 0) then
        Result := tptTable[ct].bodyColumns[tptTable[ct].iTableColumns].iColumnRightMM100 -
                  tptTable[ct].bodyColumns[1].iColumnRightMM100
      else
        Result := -1;
    else
      Result := -1;
  end; // case
end; // GetPrnFnValue

//***************************************************************************
//
//  FUNCTION  : SetPrnFnValue
//
//  I/P       : valueID : Integer - Identifier of the value to be set
//
//              newValue : Integer - The value to be assigned
//
//  O/P       : None
//
//  OPERATION : Changes an internal value which is allowed to be changed by
//              this sort of method (and not by page definition, table definition
//              etc)
//
//              Originally created to move the iCurrentYPOos entry point around
//              on the current page
//
//  UPDATED   : 2016-06-23
//
//***************************************************************************
procedure SetPrnFnValue(valueID : Integer;
                        newValue : Integer);
begin
  case valueID of
    PF_YPOS :
      iCurrentYPos := newValue;
  end; // case
end; // SetPrnFnValue

//***************************************************************************
//
//  FUNCTION  : SetLanguage
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/02/23
//
//***************************************************************************
procedure SetLanguage(lcMain : TDKLanguageController);
begin
  lcPrintFunctions := lcMain;
  if (lcMain <> nil) then
  begin
    try
      sPageXOfYText := LangManager.ConstantValue['sPageDofD'];
      sPDFError := LangManager.ConstantValue['sErrorWhileCreatingPDF'];
    except
    end; // except
  end; // if
end;

//***************************************************************************
//
//  FUNCTION    :   StartNewPage
//
//  I/P         :   bFirstPage (boolean) - TRUE if this is the first page
//                    in the document.
//
//  O/P         :
//
//  OPERATION   :   Create a new page, reset the font, draw the border,
//                  if required and add a header, if required,
//
//  UPDATED     :   2001/04/09
//
//***************************************************************************
procedure StartNewPage(bFirstPage : boolean);
var
  sHeaderLine : String;
  sOneLine : String;
  n : Integer;
  sStartingFontName : String;
  iStartingFontSize : Integer;
  fsStartingFontStyle : set of TFontStyle;
  tpTempParagraph : TParagraph;
  tptTempTable : TPrintedTable;

begin
// Force a new page if this is not the first page
  if (not bFirstPage) then
  begin
    // Store the font that is currently in use because forcing a new page
    // appears to cause the font to reset to the defined component default
    sStartingFontName := ppOutput^.Canvas.Font.Name;
    iStartingFontSize := ppOutput^.Canvas.Font.Size;
    fsStartingFontStyle := ppOutput^.Canvas.Font.Style;
    // Create a new page
    ppOutput^.NewPage;
    // Restore the font that was in use.
    ppOutput^.Canvas.Font.Name := sStartingFontName;
    ppOutput^.Canvas.Font.Style := fsStartingFontStyle;
    ppOutput^.Canvas.Font.Size := iStartingFontSize;
  end; // if

  // Setup the size required to obtain the requested line length
  if (bPFAutoSetFontPitch) then
    AutoDefineFWParagraph(sAutoSizeFWFontName);

  // Draw the border, if required
  if (bPageBorder) then
    DrawPageBorder;
  // Print the page logo, if required
  if (sPageLogo<>'') then
    DrawPageLogo;
  // Print the page watermark, if required
  if (sPageWatermark<>'') then
    DrawPageWatermark;

  // Initialise the text cursor positions
  iCurrentYPos := iPrnAreaTop;

  // Produce any run-on page headers
  if (not bFirstPage) then
  begin

    // Produce any text-file run-on page headers
    if (bAutoHeaders) then
    begin
      // Check if a simple header (line of text) is required
      if (Assigned(SimpleHeader_Func)) then
      begin
        sHeaderLine := SimpleHeader_Func;
        // Strip out all TABS (which are used to demarkate columns for CSV exporting)
        sHeaderLine := SearchAndReplace(sHeaderLine,#09,'');
        sOneLine := '';
        // Scan through to handle multi-line headers
        for n := 1 to Length(sHeaderLine) do
        begin
          // Build up the line
          sOneLine := sOneLine + sHeaderLine[n];
          // Print complete lines
          if (sHeaderLine[n] = #13) then
          begin
            PrintParagraph(sOneLine,TRUE);
            sOneLine := '';
          end // if
          else
        end; // for

        // Print last line of header line
        if (sOneLine<>'') then
          PrintParagraph(sOneLine,TRUE);
      end; // if
    end; // if

    // Check if a complex header is required
    if (Assigned(ComplexHeader)) then
    begin
      // Save all the current styles, and clear them.
      tpTempParagraph := tpParagraph;
      //!! I do not like this - you cannot assign a record like this.
      //!! This is merely copying the pointer to the record. Use with extreme caution!
      tptTempTable := tptTable[ct];
      ClearTable;
      ComplexHeader;
      // Restore the current styles
      tpParagraph := tpTempParagraph;
      tptTable[ct] := tptTempTable;
    end; // if

  end; // if
end; // StartNewPage

//***************************************************************************
//
//  FUNCTION  : PrintPreview2PDF
//
//  I/P       : ppToPDF : TPrintPreview - the document to be printed
//
//              FirstPage : Integer - first page to be printed
//
//              LastPage : Integer - last page to be printed
//
//              sDestinationFile : String - the file to which the PDF output must be saved
//                (overwrite existing without any confirmation)
//
//              sProducer : AnsiString - Kinetic Electronic Designs cc
//
//              sAuthor : AnsiString - The owner company of the application
//
//              sCreator : AnsiString - The name of the application
//
//              sTitle : AnsiString - The document title
//
//              sSubject : AnsiString - The document subject
//
//  O/P       : None
//
//  OPERATION : Note that most of the functionality of this function is provided
//              by methods of TPrintPreview.
//
//              This function adds the ability to limit the page range.
//
//              Check at http://delphistep.cis.si/ (my postcard on pg 29)
//
//  UPDATED   : 2016-11-10
//
//***************************************************************************
procedure PrintPreview2PDF(ppToPDF : TPrintPreview;
                           FirstPage : Integer;
                           LastPage : Integer;
                           sDestinationFile : String;
                           sProducer : AnsiString;
                           sAuthor : AnsiString;
                           sCreator : AnsiString;
                           sTitle : AnsiString;
                           sSubject : AnsiString) overload;
var
  mems: TMemoryStream;
  n : Integer;

  Handle: HMODULE;
  pBeginDoc: function(FileName: PAnsiChar): Integer; stdcall;
  pEndDoc: function: Integer; stdcall;
  pNewPage: function: Integer; stdcall;
  pPrintPageMemory: function(Buffer: Pointer; BufferSize: Integer): Integer; stdcall;
  pPrintPageFile: function(FileName: PAnsiChar): Integer; stdcall;
  pSetParameters: function(OffsetX, OffsetY: Integer; ConverterX, ConverterY: Double): Integer; stdcall;
  pSetPage: function(PageSize, Orientation, Width, Height: Integer): Integer; stdcall;
  pSetDocumentInfo: function(What: Integer; Value: PAnsiChar): Integer; stdcall;

begin
  LastPage := Min(LastPage,ppToPDF.TotalPages);

  if ((FirstPage >= 1) and
      (FirstPage <= LastPage)) then
  begin
  mems := TMemoryStream.Create;

  Handle := LoadLibrary('dspdf.dll');
  if (Handle > 0) then
  begin
      // If the file already exists, attempt to delete it
      if ((not FileExists(sDestinationFile)) or
          (SysUtils.DeleteFile(sDestinationFile))) then
      begin
        @pBeginDoc := GetProcAddress(Handle, 'BeginDoc');
        @pEndDoc := GetProcAddress(Handle, 'EndDoc');
        @pNewPage := GetProcAddress(Handle, 'NewPage');
        @pPrintPageMemory := GetProcAddress(Handle, 'PrintPageM');
        @pPrintPageFile := GetProcAddress(Handle, 'PrintPageF');
        @pSetParameters := GetProcAddress(Handle, 'SetParameters');
        @pSetPage := GetProcAddress(Handle, 'SetPage');
        @pSetDocumentInfo := GetProcAddress(Handle, 'SetDocumentInfo');

        pBeginDoc(PAnsiChar(AnsiString(sDestinationFile)));

        pSetDocumentInfo(0,PAnsiChar(sProducer));    // Producer
        pSetDocumentInfo(1,PAnsiChar(sAuthor));      // Author
        pSetDocumentInfo(2,PAnsiChar(sCreator));     // Creator
        pSetDocumentInfo(4,PAnsiChar(sTitle));       // Title
        pSetDocumentInfo(3,PAnsiChar(sSubject));     // Subject

        for n := FirstPage to LastPage do
        begin
          mems.Clear;

          ppToPDF.Pages[n].SaveToStream(mems);
          mems.Position := 0;

          if (n > FirstPage) then
            pNewPage;

          if (ppToPDF.Orientation = poPortrait) then
            pSetPage(2, 0, 0, 0)
          else
            pSetPage(2, 1, 0, 0);

          pPrintPageMemory(mems.Memory, mems.Size);
        end; // for
        pEndDoc;
      end // if
      else
        MessageDlg(sPDFError,mtError,[mbOK],0);
    end
    else
      MessageDlg(sPDFError,mtError,[mbOK],0);

    mems.Free;
  end; // if
end;

//***************************************************************************
//
//  FUNCTION  : PrintPreview2PDF
//
//  I/P       : ppToPDF : TPrintPreview - the document to be printed
//
//              sDestinationFile : String - the file to which the PDF output must be saved
//                (overwrite existing without any confirmation)
//
//              sProducer : AnsiString - Kinetic Electronic Designs cc
//
//              sAuthor : AnsiString - The owner company of the application
//
//              sCreator : AnsiString - The name of the application
//
//              sTitle : AnsiString - The document title
//
//              sSubject : AnsiString - The document subject
//
//  O/P       :
//
//  OPERATION : Prints the given TPrintPreview to a given PDF file, using the
//              TPrintPreview methods
//
//  UPDATED   : 2016-11-10
//
//***************************************************************************
procedure PrintPreview2PDF(ppToPDF : TPrintPreview;
                           sDestinationFile : String;
                           sProducer : AnsiString;
                           sAuthor : AnsiString;
                           sCreator : AnsiString;
                           sTitle : AnsiString;
                           sSubject : AnsiString) overload;
begin
  // Check that the DLL is registered
  if (ppToPDF.CanSaveAsPDF) then
  begin
    // If the file already exists, attempt to delete it
    if ((not FileExists(sDestinationFile)) or
        (SysUtils.DeleteFile(sDestinationFile))) then
    begin
      ppToPDF.PDFDocumentInfo.Producer := sProducer;
      ppToPDF.PDFDocumentInfo.Author := sAuthor;
      ppToPDF.PDFDocumentInfo.Creator := sCreator;
      ppToPDF.PDFDocumentInfo.Title := sTitle;
      ppToPDF.PDFDocumentInfo.Subject := sSubject;

      ppToPDF.SaveAsPDF(sDestinationFile);
    end // if
    else
      MessageDlg(sPDFError,mtError,[mbOK],0);
  end // if
  else
    MessageDlg(sPDFError,mtError,[mbOK],0);
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
function PrintPreview2Printer(ppToPrint : TPrintPreview) : Integer;
var
  iCopyNumber : Integer;
  iPage : Integer;
  PrintDialog : TPrintDialog;

begin
  if (ppToPrint.State = psReady) then
  begin
    PrintDialog := TPrintDialog.Create(nil);
    try
      // Permit selected page number printing, if more than one page is available
      if (ppToPrint.TotalPages > 1) then
      begin
        PrintDialog.Options := [poPageNums];
        PrintDialog.MinPage := 1;
        PrintDialog.MaxPage := ppToPrint.TotalPages;
        PrintDialog.FromPage := 1;
        PrintDialog.ToPage := PrintDialog.MaxPage;
      end // if
      else
        PrintDialog.Options := [];
      // Show the printer dialog
      if (PrintDialog.Execute) then
      begin
        // Check if non-collation will need to be handled
        if ((PrintDialog.Copies = 1) or (PrintDialog.Collate)) then
        begin
          // Print the requested number of copies, in order, of the requested pages
          iCopyNumber := 1;
          while (iCopyNumber <= PrintDialog.Copies) do
          begin
            if (PrintDialog.PrintRange = prAllPages) then
              ppToPrint.Print
            else
              ppToPrint.PrintPages(PrintDialog.FromPage,PrintDialog.ToPage);
            Inc(iCopyNumber);
          end; // while
        end // if
        else
        begin
          // Collation is disabled (print the requested number of each page)
          if (PrintDialog.PrintRange = prAllPages) then
          begin
            PrintDialog.FromPage := 1;
            PrintDialog.ToPage := PrintDialog.MaxPage;
          end; // if
          for iPage := PrintDialog.FromPage to PrintDialog.ToPage do
            for iCopyNumber := 1 to PrintDialog.Copies do
              ppToPrint.PrintPages(iPage,iPage);
        end; // else
        result := mrOK;
      end // if
      else
        result := mrCancel;
    finally
      PrintDialog.Free;
    end;
  end // if
  else
    result := mrAbort;
end; // PrintPreview2Printer

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
initialization
begin
  ppOutput := nil;
  ClearTabList;
  // Indicate that there is no active table
  ClearTable;

  UseTable(0);

  lcPrintFunctions := nil;

  // These functions are initially unassigned.
  SimpleHeader_Func := nil;
  ComplexHeader := nil;

  // Defaults, in case SetLanguage does not get called
  sPageXofYText := 'Page %d of %d';
  sPDFError := 'Error while creating PDF';
end;

finalization
begin

end;

end.

