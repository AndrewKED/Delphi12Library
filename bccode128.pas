unit bccode128;
// This is a unit to print Bar codes, Code128
// Written by Andrew Spencer, ans@pixie.co.za
// Based on code written for 2-of-5 Interleaved by
// Claudio Domiziani, E.T.I. Elettronica - San Gemini (TERNI) - ITALY
interface

uses Graphics, Classes;

Type TBarCode128 = Object
  unitx : integer;
  ht : integer;
  cnv : TCanvas;
  procedure SetParameters(u, h : integer; pcanvas : TObject);
  procedure PrintBC(startx, starty : integer;
                    msg : string;
                    add_text : boolean);
  private
    procedure StartChar(code_id : byte;
                        x,y : integer);
    procedure StopChar(x,y : integer);
    procedure SingleChar(ascii_char : char;
                         as_is : boolean;
                         x,y : integer;
                         display_orig : boolean;
                         msg_position : integer);

  public
end;

implementation

const
STARTCODEA = 103;
STARTCODEB = 104;
STARTCODEC = 105;
StartSet : array[0..2,0..5] of byte =
           ((2,1,1,4,1,2),(2,1,1,2,1,4),(2,1,1,2,3,2));
StopCode : array[0..7] of byte = (2,3,3,1,1,1,2,99);

CharSet : array[0..102,0..5] of byte =                             // CODE A        CODE B      CODE C
        ((2,1,2,2,2,2),(2,2,2,1,2,2),(2,2,2,2,2,1),(1,2,1,2,2,3),  // ' ' to '#'
         (1,2,1,3,2,2),(1,3,1,2,2,2),(1,2,2,2,1,3),(1,2,2,3,1,2),  // '$' to '''
         (1,3,2,2,1,2),(2,2,1,2,1,3),(2,1,1,3,1,2),(2,3,1,2,1,2),  // '(' to '+'
         (1,1,2,2,3,2),(1,2,2,1,3,2),(1,2,2,2,3,1),(1,1,3,2,2,2),  // ',' to '/'
         (1,2,3,1,2,2),(1,2,3,2,2,1),(2,2,3,2,1,1),(2,2,1,1,3,2),  // '0' to '3'
         (2,2,1,2,3,1),(2,1,3,2,1,2),(2,2,3,1,1,2),(3,1,2,1,3,1),  // '4' to '7'
         (3,1,1,2,2,2),(3,2,1,1,2,2),(3,2,1,2,2,1),(3,1,2,2,1,2),  // '8' to ';'
         (3,2,2,1,1,2),(3,2,2,2,1,1),(2,1,2,1,2,3),(2,1,2,3,2,1),  // '<' to '?'
         (2,3,2,1,2,1),(1,1,1,3,2,3),(1,3,1,1,2,3),(1,3,1,3,2,1),  // '@' to 'C'
         (1,1,2,3,1,3),(1,3,2,1,1,3),(1,3,2,3,1,1),(2,1,1,3,1,3),  // 'D' to 'G'
         (2,3,1,1,1,3),(2,3,1,3,1,1),(1,1,2,1,3,3),(1,1,2,3,3,1),  // 'H' to 'K'
         (1,3,2,1,3,1),(1,1,3,1,2,3),(1,1,3,3,2,1),(1,3,3,1,2,1),  // 'L' to 'O'
         (3,1,3,1,2,1),(2,1,1,3,3,1),(2,3,1,1,3,1),(2,1,3,1,1,3),  // 'P' to 'S'
         (2,1,3,3,1,1),(2,1,3,1,3,1),(3,1,1,1,2,3),(3,1,1,3,2,1),  // 'T' to 'W'
         (3,3,1,1,2,1),(3,1,2,1,1,3),(3,1,2,3,1,1),(3,3,2,1,1,1),  // 'X' to '['
         (3,1,4,1,1,1),(2,2,1,4,1,1),(4,3,1,1,1,1),(1,1,1,2,2,4),  // '\' to '_'
         (1,1,1,4,2,2),(1,2,1,1,2,4),(1,2,1,4,2,1),(1,4,1,1,2,2),  // NUL to ETX
         (1,4,1,2,2,1),(1,1,2,2,1,4),(1,1,2,4,1,2),(1,2,2,1,1,4),  // EOT to BEL
         (1,2,2,4,1,1),(1,4,2,1,1,2),(1,4,2,2,1,1),(2,4,1,2,1,1),  // BS  to VT
         (2,2,1,1,1,4),(4,1,3,1,1,1),(2,4,1,1,1,2),(1,3,4,1,1,1),  // FF  to SI
         (1,1,1,2,4,2),(1,2,1,1,4,2),(1,2,1,2,4,1),(1,1,4,2,1,2),  // DLE to DC3
         (1,2,4,1,1,2),(1,2,4,2,1,1),(4,1,1,2,1,2),(4,2,1,1,1,2),  // DC4 to ETB
         (4,2,1,2,1,1),(2,1,2,1,4,1),(2,1,4,1,2,1),(4,1,2,1,2,1),  // CAN to ESC
         (1,1,1,1,4,3),(1,1,1,3,4,1),(1,3,1,1,4,1),(1,1,4,1,1,3),  // FS  to US
         (1,1,4,3,1,1),(4,1,1,1,1,3),(4,1,1,3,1,1),(1,1,3,1,4,1),  // FNC3 to CODEC
         (1,1,4,1,3,1),(3,1,1,1,4,1),(4,1,1,1,3,1));               // CODEB to FNC1

var
  current_set : byte;                   // Indicates the set in use
  chk_char : integer;                   // Builds the check character

//***************************************************************************
//
//  FUNCTION    :  Code182Char
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :  Converts ASCII character to the code number in the
//                     set currently being used
//
//  UPDATED     :
//
//***************************************************************************
function Code128Char(ascii_char : char) : byte;
begin
  if (current_set = STARTCODEA) then
  begin
    case ascii_char of
      ' '..'_' : result := Ord(ascii_char) - Ord(' ');
      #0..#31  : result := Ord(ascii_char) + 64;
      #96..#102 : result := Ord(ascii_char);
      else
        result := 255;            // Ignore #103 and above
    end; // case
  end // if
  else
    result := 255;
end; // Code128Char

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
procedure TBarCode128.StartChar(code_id : byte;
                                x,y : integer);
var
  element : byte;

begin
                                        // Don't do anything unprintable
  if (code_id>=STARTCODEA) and (code_id<=STARTCODEC) then
  begin

    current_set := code_id;             // Store the currently used code set

    chk_char := code_id;                // Initialise the check char

    with cnv do
    begin
      element := 0;                     // Print the code, which has 6 elements
      while (element<6) do
      begin                             // Print the bar
        fillrect(rect(x,y,x + unitx * StartSet[code_id-STARTCODEA,element],y+ht));
                                        // Move x on by bar width + following space width
        inc(x,unitx * StartSet[code_id-STARTCODEA,element] +
              unitx * StartSet[code_id-STARTCODEA,element+1]);
        inc(element,2);                 // Skip to the next bar element
      end; // for
    end; // with
  end; // if
end; // StartChar

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
procedure TBarCode128.StopChar(x,y : integer);
var
  element : byte;

begin
  with cnv do
  begin
    element := 0;                       // Print the stop code, which has 7 elements
    while (element<7) do
    begin                               // Print the bar
      fillrect(rect(x,y,x + unitx * StopCode[element],y+ht));
                                        // Move x on by bar width + following space width
      inc(x,unitx * StopCode[element] + unitx * StopCode[element+1]);
      inc(element,2);                   // Skip to the next bar element
    end; // for
  end; // with
end;

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
procedure TBarCode128.SingleChar(ascii_char : char;
                                 as_is : boolean;
                                 x,y : integer;
                                 display_orig : boolean;
                                 msg_position : integer);
var
  element,code_num  : integer;
  old_font : TFont;

begin
  if (not as_is) then                     // check if we must translate this character
    code_num := Code128Char(ascii_char)
  else
    code_num := Ord(ascii_char);

  if (code_num<255) then                  // Don't do anything unprintable
  begin

    Inc(chk_char,code_num*msg_position);  // Keep track of the check character

    with cnv do
    begin
      if ((display_orig) and      // If we can and are requested to
          (not as_is) and         // display the original (decoded)
          (ascii_char in [' '..'_'])) then
      begin                       // character, set a
        old_font := font;         // suitable font size, and do so.
        font.size := 10;
        Brush.Color := (not Brush.Color) and $00FFFFFF;
        TextOut(x,y+ht+cnv.TextHeight('A') div 2,Char(ascii_char));
        Brush.Color := (not Brush.Color) and $00FFFFFF;
        font := old_font;
      end; // if

      element := 0;                     // Print the code, which has 6 elements
      while (element<6) do
      begin                             // Print the bar
        fillrect(rect(x,y,x + unitx * CharSet[code_num,element],y+ht));
                                        // Move x on by bar width + following space width
        inc(x,unitx * CharSet[code_num,element] + unitx * CharSet[code_num,element+1]);
        inc(element,2);                 // Skip to the next bar element
      end; // for
    end; // with
  end; // if
end;

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
procedure TBarCode128.SetParameters(u, h : integer; pcanvas : TObject);
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
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
procedure TBarCode128.PrintBC(startx, starty : integer;
                              msg : string;
                              add_text : boolean);
var
  n : integer;

begin

  // start character (CodeA)
  StartChar(STARTCODEA,startx,starty);

  for n := 1 to length(msg) do
  begin
    SingleChar(msg[n],FALSE,startx+(n*11*unitx),starty,add_text,n);
  end; // for

  chk_char := chk_char mod 103;       // Determine the check character
                                      // Print the check character
  SingleChar(Char(chk_char),TRUE,startx+((length(msg)+1)*11*unitx),starty,FALSE,0);

  // stop character
  StopChar(startx+(length(msg)+2)*11*unitx,starty);
end; // PrintBC

end.
