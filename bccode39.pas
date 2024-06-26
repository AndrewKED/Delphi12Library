unit BcCode39;
//***************************************************************************
//
// DESCRIPTION:
//  This is a unit to print Bar codes, Code-39 (or Code 3 of 9)   Each character
//  is made up of 9 bars, 3 of which are wider than the others.   The ratio of
//  wide:narrow is 3:1.
//
// AUTHOR : Andrew Spencer - andrew@ked.co.za
//
// TO BE DONE:
//
//  *
//
// VERSIONS:
//    Update Date : 200 /  /  
//    Changes Made :
//      *
//
//    Update Date : ?
//    Changes Made :
//      * First issue based on code written for 2-of-5 Interleaved by
//        Claudio Domiziani, E.T.I. Elettronica - San Gemini (TERNI) - ITALY
//
//***************************************************************************

interface

uses Graphics, Classes;

Type TBarCode39 = Object
  unitx : integer;
  ht : integer;
  cnv : TCanvas;
  procedure SetParameters(u, h : integer; pcanvas : TObject);
  procedure SingleChar(bc_char : char;
                       x,y : integer;
                       display_orig : boolean);
  procedure PrintBC(startx, starty : integer;
                    msg : string;
                    decoded : boolean);
end;

implementation
const

CharSet : array[0..43,0..8] of byte =
        ((1,1,1,3,3,1,3,1,1), (3,1,1,3,1,1,1,1,3), (1,1,3,3,1,1,1,1,3), (3,1,3,3,1,1,1,1,1),  // 0-3
         (1,1,1,3,3,1,1,1,3), (3,1,1,3,3,1,1,1,1), (1,1,3,3,3,1,1,1,1), (1,1,1,3,1,1,3,1,3),  // 4-7
         (3,1,1,3,1,1,3,1,1), (1,1,3,3,1,1,3,1,1),                                            // 8-9
         (3,1,1,1,1,3,1,1,3), (1,1,3,1,1,3,1,1,3), (3,1,3,1,1,3,1,1,1), (1,1,1,1,3,3,1,1,3),  // A-D
         (3,1,1,1,3,3,1,1,1), (1,1,3,1,3,3,1,1,1), (1,1,1,1,1,3,3,1,3), (3,1,1,1,1,3,3,1,1),  // E-H
         (1,1,3,1,1,3,3,1,1), (1,1,1,1,3,3,3,1,1), (3,1,1,1,1,1,1,3,3), (1,1,3,1,1,1,1,3,3),  // I-L
         (3,1,3,1,1,1,1,3,1), (1,1,1,1,3,1,1,3,3), (3,1,1,1,3,1,1,3,1), (1,1,3,1,3,1,1,3,1),  // M-P
         (1,1,1,1,1,1,3,3,3), (3,1,1,1,1,1,3,3,1), (1,1,3,1,1,1,3,3,1), (1,1,1,1,3,1,3,3,1),  // Q-T
         (3,3,1,1,1,1,1,1,3), (1,3,3,1,1,1,1,1,3), (3,3,3,1,1,1,1,1,1), (1,3,1,1,3,1,1,1,3),  // U-X
         (3,3,1,1,3,1,1,1,1), (1,3,3,1,3,1,1,1,1),                                            // Y-Z
         (1,3,1,1,1,1,3,1,3), (3,3,1,1,1,1,3,1,1), (1,3,3,1,1,1,3,1,1), (1,3,1,1,3,1,3,1,1),  // -,., ,*
         (1,3,1,3,1,3,1,1,1), (1,3,1,3,1,1,1,3,1), (1,3,1,1,1,3,1,3,1), (1,1,1,3,1,3,1,3,1)); // $,/,+,%

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
procedure TBarCode39.SingleChar(bc_char : char;
                                x,y : integer;
                                display_orig : boolean);
var
  element, offset : integer;
  old_font : TFont;

begin
  case bc_char of
    '0'..'9' : offset := Ord(bc_char) - Ord('0');
    'A'..'Z' : offset := Ord(bc_char) - Ord('A') + 10;
    '-'      : offset := 36;
    '.'      : offset := 37;
    ' '      : offset := 38;
    '*'      : offset := 39;
    '$'      : offset := 40;
    '/'      : offset := 41;
    '+'      : offset := 42;
    '%'      : offset := 43;
    else
      offset := 99;
  end; // case

  if (offset<99) then             // Don't do anything unprintable
    with cnv do
    begin
      if display_orig then        // If we are required to display the
      begin                       // original (decoded) character, set a
        old_font := font;         // suitable font size, and do so.
        font.size := 10;
        Brush.Color := (not Brush.Color) and $00FFFFFF;
        TextOut(x,y+ht+cnv.TextHeight('A') div 2,bc_char);
        Brush.Color := (not Brush.Color) and $00FFFFFF;
        font := old_font;
      end; // if

      element := 0;               // Print the bar.
      while (element<10) do
      begin
        fillrect(rect(x,y,x + unitx * CharSet[offset,element],y+ht));
        inc(x,unitx * CharSet[offset,element] + unitx * CharSet[offset,element+1]);
        inc(element,2);
      end; // for
    end; // with
end;

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         : u (integer) - Specifies the width of a narrow bar or gap,
//                  in pixels.
//
//                h (integer) - Specifies the height of the bar code, in
//                  pixels
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
procedure TBarCode39.SetParameters(u, h : integer; pcanvas : TObject);
begin
  unitx := u;
  ht := h;
  cnv := TCanvas(pcanvas);
end;

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
procedure TBarCode39.PrintBC(startx, starty : integer;
                             msg : string;
                             decoded : boolean);
var
  n : integer;
begin
  // start character
  TBarCode39.SingleChar('*',startx,starty,FALSE);

  for n := 1 to length(msg) do
    TBarCode39.SingleChar(msg[n],startx+(n*16*unitx),starty,decoded);

  // stop character
  TBarCode39.SingleChar('*',startx+(length(msg)+1)*16*unitx,starty,FALSE);
end; // PrintBC

end.
