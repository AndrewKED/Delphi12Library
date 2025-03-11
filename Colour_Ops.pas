unit Colour_Ops;

interface

uses
  Graphics
{$IFDEF WIN32}
  , LED
{$ENDIF}
  ;

procedure GetRGBComponents(value : TColor;
                           var valRed : Byte;
                           var valGreen : Byte;
                           var valBlue : Byte);
function MakeColour(valRed : Byte;
                    valGreen : Byte;
                    valBlue : Byte) : TColor;
function ChangeColourShade(colourOriginal : TColor;
                           change : Integer) : Integer;
function CanChangeColour(colourOriginal : TColor;
                         proposedChange : Integer) : Boolean;
function ShadeBetween(StartColour : TColor;
                      EndColour : TColor;
                      Percentage : double) : TColor;
{$IFDEF WIN32}
function LEDRedGreen(Good : boolean) : TLEDColor;
{$ENDIF}
function Colour2HTMLHex(value : TColor) : String;
function Colour2Text(value : TColor) : String;

const
// Colours
//------------------------------------------------------------------------------

// ICAPE Colours
ICAPE_GREY = $00353535;     //  53,  53,  53  "Deep Anthracite Grey"
ICAPE_BLUE = $00BF7C12;     // 191, 124,  18  Also $00EFAE35 / $00C87D00 / $00C97E00
ICAPE_GREEN = $006ECB94;    // 110, 203, 148
ICAPE_LT_GREEN = $009FE1BA; // 159, 225, 185



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

AutumnColours: array[0..19] of TColor = (
    $4DB7FF,  // Light Orange
    $3A7CD6,  // Burnt Orange
    $13458B,  // Saddle Brown
    $2A2AA5,  // Brown
    $1E69D2,  // Chocolate
    $3F85CD,  // Peru
    $4763FF,  // Tomato
    $60A4F4,  // Sandy Brown
    $355DC6,  // Autumn Red
    $2A2AA5,  // Rust
    $27599C,  // Chestnut
    $69B4D8,  // Dark Khaki
    $8CE6F0,  // Khaki
    $B3DEF5,  // Wheat
    $0B86B8,  // Dark Goldenrod
    $008B8B,  // Olive
    $5DA6C9,  // Taupe
    $00D7FF,  // Gold
    $0045FF,  // Orange Red
    $8F8FBC   // Rosy Brown
  );

implementation

uses
  System.SysUtils,
  Vcl.GraphUtil,
  Math;

//***************************************************************************
//
//  FUNCTION  : GetRGBComponents
//
//  I/P       : value : TColor - The colour to be split
//
//  O/P       : varRed : Byte - The red portion
//              verGreen : Byte - The green portion
//              var  valBlue : Byte - The blue portion
//
//  OPERATION : Separate the given colour (including system colours) into the
//              red, green and blue components.
//
//  UPDATED   : 2024-12-19
//
//***************************************************************************
procedure GetRGBComponents(value : TColor;
                           var valRed : Byte;
                           var valGreen : Byte;
                           var valBlue : Byte);
begin
  value := Graphics.ColorToRGB(value);

  valBlue := Byte(value shr 16);
  valGreen := Byte(value shr 8);
  valRed := Byte(value);
end; // GetRGBComponents

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
function MakeColour(valRed : Byte;
                    valGreen : Byte;
                    valBlue : Byte) : TColor;
begin
  Result := TColor((Integer(valBlue) shl 16) +
                   (Integer(valGreen) shl 8) +
                   Integer(valRed));
end;

//***************************************************************************
//
//  FUNCTION  : ChangeColourShade
//
//  I/P       : colourOriginal : TColor - The colour to be changed
//
//              change : Integer - the amount by which each of the RGB
//                element values is to be changed.
//
//  O/P       : Longint - the new colour
{TODO -oAndrew Spencer -cCheck : Why did I use Longint and not TColor?}
//
//  OPERATION : Each colour byte is adjusted up or down by the given change.
//
//              Note that this does not work for system colours (e.g. clHighlight)
//              One would have to use TStyleManager.ActiveStyle.GetSystemColor()
//              to determine the actual RGB.
//
//              Final R, G and B valies are limited to $00 to $FF.
//
//  UPDATED   : 2024-08-20
//
//***************************************************************************
function ChangeColourShade(colourOriginal : TColor;
                           change : Integer) : Longint;
var
  valRed : Byte;
  valGreen : Byte;
  valBlue : Byte;

begin
  change := EnsureRange(change, -$FF, $FF);

  GetRGBComponents(colourOriginal, valBlue, valGreen, valRed);

  valBlue := EnsureRange(Integer(valBlue) + change, $00, $FF);
  valGreen := EnsureRange(Integer(valGreen) + change, $00, $FF);
  valRed := EnsureRange(Integer(valRed) + change, $00, $FF);

  result := (Integer(valBlue) shl 16) +
            (Integer(valGreen) shl 8) +
            Integer(valRed);
end; // ChangeColourShade

//***************************************************************************
//
//  FUNCTION  : CanChangeColour
//
//  I/P       : colourOriginal : TColor - The original colour, to be changed
//
//              proposedChange : Integer - Shade change per colour
//
//  O/P       :
//
//  OPERATION : Test whether the given change to RGB will make an appreciable
//              change to the colour.
//
//              "appreciable change" is where any one of the colours is able
//              to be changed by the proposed colour change.
//
//  UPDATED   : 2024-08-20
//
//***************************************************************************
function CanChangeColour(colourOriginal : TColor;
                         proposedChange : Integer) : Boolean;
var
  blue : Integer;
  red : Integer;
  green : Integer;
  blueNew : Integer;
  redNew : Integer;
  greenNew : Integer;

begin
  proposedChange := EnsureRange(proposedChange, -$FF, $FF);

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

{$IFDEF WIN32}
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
{$ENDIF}

//***************************************************************************
//
//  FUNCTION  : Colour2HTMLHex
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
function Colour2HTMLHex(value : TColor) : String;
var
  red : Byte;
  blue : Byte;
  green : Byte;

begin
  GetRGBComponents(value, red, green, blue);
  Result := '#' + IntToHex(red, 2) + IntToHex(green, 2) + IntToHex(blue, 2);
end; // Colour2HTMLHex

//***************************************************************************
//
//  FUNCTION  : Colour2Text
//
//  I/P       : value : TColor - The colour to be named
//
//  O/P       : String - the name
//
//  OPERATION : Attempt to get a reasonable English name for the given colour.
//
//  UPDATED   : 2024-09-27
//
//***************************************************************************
function Colour2Text(value : TColor) : String;
var
  h : Word;
  l : Word;
  s : word;

begin
  value := Graphics.ColorToRGB(value);

  Result := ColorToWebColorName(value);
//  if (Pos('clWeb', Result) <> 1) then
  begin
    // This did not "hit" one of the standard Web Colours,
    // so make an attempt
    ColorRGBToHLS(value, h, l, s);

    // Get the basic description of the colour hue
    // https://www.beachpainting.com/blog/color-hue-tint-tone-and-shade/

    if (h <= 11) then
      Result := 'red'
    else if (h <= 31) then
      Result := 'red-yellow'
    else if (h <= 53) then
      Result := 'yellow'
    else if (h <= 74) then
      Result := 'green-yellow'
    else if (h <= 96) then
      Result := 'green'
    else if (h <= 117) then
      Result := 'green-cyan'
    else if (h <=138) then
      Result := 'cyan'
    else if (h <= 159) then
      Result := 'blue-cyan'
    else if (h <= 181) then
      Result := 'blue'
    else if (h <= 202) then
      Result := 'blue-magenta'
    else if (h <= 223) then
      Result := 'magenta'
    else if (h <= 245) then
      Result := 'red-magenta'
    else
      Result := 'red';

    // Imagine a square of a particular hue with
    //    min(s) on left, max(s) on right
    //    min(l) at bottom, max(l) at top
    // Top side will go l-to-r white to pale colour to bright colour
    // Bottom side will go l-to-r black to black
    // Right side will go t-to-b bright colour to dark colour to black.
    // Left side will go t-to-b white to grey to black.

    // AArgh! GIMP also uses a triangle, which is why the bottom of the above
    // square is all black.

    // changing S if V (L?) is 0 does nothing (stays black).

    // Try this out on GIMP colour dialog.


    // White / Soft / Bright
    // Grey / Pale / Mid
    // Black / Dark / Deep

    // Ths L and S terms from ColorRGBToHLS do not match to the V and S terms in Gimp,
    // so the descriptions below/here are wrong.

    // Luminosity
    if (l < 83) then
    begin
      if (s < 83) then
        Result := 'Black ' + Result
      else if (s < 166) then
        Result := 'Grey ' + Result
      else
        Result := 'White ' + Result
    end
    else if (l < 166) then
    begin
      if (s < 83) then
        Result := 'Dark ' + Result
      else if (s < 166) then
        Result := 'Pale ' + Result
      else
        Result := 'Soft ' + Result
    end
    else
    begin
      if (s < 83) then
        Result := 'Deep ' + Result
      else if (s < 166) then
        Result := 'Mid ' + Result
      else
        Result := 'Bright ' + Result
    end;

//

//    // Luminosity
//    if (l < 83) then
//      Result := Result + ' (dark, '
//    else if (l < 166) then
//      Result := Result + ' (mid, '
//    else
//      Result := Result + ' (light, ';
//
//    // Saturation
//    if (s < 128) then
//      Result := Result + ' unsaturated)'
//    else
//      Result := Result + ' saturated)';


    // Add descriptions of saturation and lightness
  end; // else
end;

end.
