unit Colour_Ops;

interface

uses
  Graphics, LED;

function ChangeColourShade(colourOriginal : TColor;
                           iChange : Longint) : Integer;
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
  clTextOnWhite     = $00303030;    // Non-black, for white background, to reduce eye strain

  clLtLtRed         = $00CCCCFF;
  clHighlightPink   = $00FF80FF;
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



implementation

uses
  Math;

//***************************************************************************
//
//  FUNCTION  : ChangeColourShade
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Each colour byte is adjusted up or down by the given change.
//              Will not work for system colours (e.g. clHighlight)
//
//  UPDATED   : 2017-07-21
//
//***************************************************************************
function ChangeColourShade(colourOriginal : TColor;
                           iChange : integer) : Longint;
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
