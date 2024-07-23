unit Colour_Ops;

interface

uses
  Graphics, LED;

function ChangeColourShade(colourOriginal : TColor;
                           iChange : Longint) : Integer;
function CanChangeColour(colourOriginal : TColor;
                         proposedChange : Longint) : Boolean;
function ShadeBetween(StartColour : TColor;
                      EndColour : TColor;
                      Percentage : double) : TColor;
function LEDRedGreen(Good : boolean) : TLEDColor;

const
// Colours
//------------------------------------------------------------------------------

//                       BBGGRR
  clLtLtGrey        = $00F0F0F0;
  clLtSilver        = $00E0E0E0;
//clSilver          = $00C0C0C0
//clGray            = $00808080
  clTextOnWhite     = $00404040;    // Non-black, for white background, to reduce eye strain

  clLtLtRed         = $00CCCCFF;
  clHighlightPink   = $00FF80FF;

  clLtRed           = $00C0C0FF;

  clLtLtOrange      = $00B0D0FF;
  clLightOrange     = $0080C0FF;
  clOrange          = $000080FF;    // Buttons in Syntell MX Display

  clSoftYellow      = $00CCFFFF;
  clPaleYellow      = $00E0FFFF;
  clGold            = $007AC2CD;    // Dry Adiabats in D-Met SkewT-LogP (as used in RAOB)

  clLtLtBlue        = $00FFFFCC;
  clLtBlue          = $00FFFF88;
  clLtAqua          = $00FFFFC0;    // Buttons in Syntell MX Display
  clBrown           = $002A2AA5;
  clLightPurple     = $00FFCCFF;

//clLime            = $0000FF00;
  clMidGreen        = $0000C000;
//clGreen           = $00008000;
  clDarkGreen       = $00004000;
  clSeaGreen        = $00E8FFE8;
  clMedSeaGreen     = $00C8DFC8;
  clLightGreen      = $000BF4AE;    // Moist Adiabats in D-Met SkewT-LogP (as used in RAOB)

  clDocBackground   = $00FFF0D6;    // A Light blue

  // 6 Light blue-green colours
  // ChatGPS question : "Provide 6 random, distinct colours with a light blue/green theme. The colours should be in hexadecimal Pascal format BGR, with a leading zero byte"
  csBlueGreen6 : array[0..5] of TColor = (
//    $00ADD8E6, // (Light Blue)
//    $009ACD32, // (Yellow-Green)
//    $0070DB93, // (Turquoise)
//    $0056FFA4, // (Mint Green)
//    $00B0E0E6, // (Powder Blue)
//    $0080FF00 // (Lime Green)

    $00ADD8E6, // (Light Blue)
    $0000FA9A, // (Medium Spring Green)
    $0020B2AA, // (Light Sea Green)
    $000080FF, // (Light Sky Blue)
    $009ACD32, // (Yellow-Green)
    $002E8B57  // (Sea Green)

  );

  // This colour set of random, distinct blue/green shades was produced by ChatGPT
  // From further experiene with Chat GPT, there is no guarantee that these are "distinct"!
  csBlueGreen50 : array[0..49] of TColor = (
    $00FF8000,
    $0032CD32,
    $004682B4,
    $001E90FF,
    $003CB371,
    $0000BFFF,
    $0066CDAA,
    $0000CED1,
    $0000FF7F,
    $005A8268,
    $004F4F2F,
    $0040E0D0,
    $00ADD8E6,
    $00008B8B,
    $0020B2AA,
    $00008080,
    $003CB371,
    $0020B2AA,
    $0000FA9A,
    $009E9E5F,
    $0000FF00,
    $0020B2AA,
    $0066CDAA,
    $003CB371,
    $007FFFD4,
    $0032CD32,
    $00008B8B,
    $0087CEFA,
    $004682B4,
    $00008080,
    $0032CD99,
    $005A8268,
    $0020B2AA,
    $0000FF7F,
    $0000BFFF,
    $000080FF,
    $002E8B57,
    $0087CEEB,
    $0000FA9A,
    $0000FF00,
    $00008B8B,
    $0066CDAA,
    $00008080,
    $004682B4,
    $0020B2AA,
    $0000BFFF,
    $0032CD32,
    $009E9E9F,
    $007FFFD4,
    $00D4FF7F);

implementation

uses
  Math;

//***************************************************************************
//
//  FUNCTION  : ChangeColourShade
//
//  I/P       : colourOriginal : TColor - The colour to be changed
//
//              iChange : Integer - the amount by which each of the RGB
//                element values is to be changed.
//
//  O/P       : Longint - the new colour
{TODO -oAndrew Spencer -cCheck : Why did I use Longint and not TColor?}
//
//  OPERATION : Each colour byte is adjusted up or down by the given change.
//
//              Note that this does not work for system colours (e.g. clHighlight)
//              One would have to use TStyleManager.ActiveStyle.GetSystemColor()
//              to determine the actual RGB
//
//  UPDATED   : 2017-07-21
//
//***************************************************************************
function ChangeColourShade(colourOriginal : TColor;
                           iChange : Integer) : Longint;
var
  iBlue : Integer;
  iRed : Integer;
  iGreen : Integer;

begin
  colourOriginal := Graphics.ColorToRGB(colourOriginal);

  iBlue := (colourOriginal and $00FF0000) shr 16;
  iGreen := (colourOriginal and $0000FF00) shr 8;
  iRed := (colourOriginal and $000000FF);

  iBlue := EnsureRange(iBlue + iChange,$00,$FF);
  iGreen := EnsureRange(iGreen + iChange,$00,$FF);
  iRed := EnsureRange(iRed + iChange,$00,$FF);

  result := (iBlue shl 16) + (iGreen shl 8) + iRed;
end;

//***************************************************************************
//
//  FUNCTION  : CanChangeColour
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Test whether the given change to RGB will make an appreciable
//              change to the colour.
//
//              "appreciable change" is where any one of the colours is able
//              to be changed by the proposed colour change.
//
//  UPDATED   : 2024-07-22
//
//***************************************************************************
function CanChangeColour(colourOriginal : TColor;
                         proposedChange : Longint) : Boolean;
var
  blue : Integer;
  red : Integer;
  green : Integer;
  blueNew : Integer;
  redNew : Integer;
  greenNew : Integer;

begin
  colourOriginal := Graphics.ColorToRGB(colourOriginal);

  blue := (colourOriginal and $00FF0000) shr 16;
  green := (colourOriginal and $0000FF00) shr 8;
  red := (colourOriginal and $000000FF);

  blueNew := EnsureRange(blue + proposedChange, $00, $FF);
  greenNew := EnsureRange(green + proposedChange, $00, $FF);
  redNew := EnsureRange(red + proposedChange, $00, $FF);

  result := (blueNew - blue = proposedChange) or
            (greenNew - green = proposedChange) or
            (redNew - red = proposedChange);
end; // CanChangeColour

//***************************************************************************
//
//  FUNCTION  : ShadeBetween
//
//  I/P       : StartColour : TColor - the colour for 0%
//
//              EndColour : TColor - the colour for 100%
//
//              Percentage : double - Decimal fraction, representing the shade
//                between StartColour (0.0) and EndColour (1.0)
//
//  O/P       : TColour
//
//  OPERATION : Creates a colour that is a given position between two other
//              colours
//
//  UPDATED   : 2015-02-09
//
//***************************************************************************
function ShadeBetween(StartColour : TColor;
                      EndColour : TColor;
                      Percentage : double) : TColor;
var
  iBlueRange : Integer;
  iRedRange : Integer;
  iGreenRange : Integer;
  iBlue : Integer;
  iRed : Integer;
  iGreen : Integer;

begin
  iBlueRange := ((EndColour and $00FF0000) shr 16) -
                ((StartColour and $00FF0000) shr 16);
  iGreenRange := ((EndColour and $0000FF00) shr 8) -
                ((StartColour and $0000FF00) shr 8);
  iRedRange := (EndColour and $000000FF) -
               (StartColour and $000000FF);

  iBlue := ((StartColour and $00FF0000) shr 16) +
           Trunc(iBlueRange * Percentage);
  iGreen := ((StartColour and $0000FF00) shr 8) +
            Trunc(iGreenRange * Percentage);
  iRed := (StartColour and $000000FF) +
          Trunc(iRedRange * Percentage);

  result := (iBlue shl 16) + (iGreen shl 8) + iRed;
end; // ShadeBetween

//***************************************************************************
//
//  FUNCTION  : LEDRedGreen
//
//  I/P       : Good : Boolean - Indicates the state of the choice
//
//  O/P       : TLEDColor - lcGreen if Good is TRUE, else lcRed
//
//  OPERATION : Returns a LED colour to indicate the state of the choice.
//              Used for setting the colour of a TLEDLabel
//
//  UPDATED   : 2015-10-02
//
//***************************************************************************
function LEDRedGreen(Good : boolean) : TLEDColor;
begin
  if (Good) then
    result := lcGreen
  else
    result := lcRed;
end;

end.
