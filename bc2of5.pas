unit Bc2of5;
{This is a unit to print Bar codes, interlaved 2 of 5                  }
{I think it can be coded better but i have no time to refine it        }
{You can use this unit freely. if you find this unit useful, please    }
{send me your comments or bug reports to : domiziac@tin.it             }
{Claudio Domiziani, E.T.I. Elettronica - San Gemini (TERNI) - ITALY    }
interface

uses Graphics, Classes;

Type TBarCode2of5 = Object
  unitx : integer;
  ht : integer;
  chk : boolean;
  cnv : TCanvas;
  procedure setpar(u, h : integer; c : boolean; pcanvas : TObject);
  procedure print(startx, starty : integer; msg : string);
end;

implementation
const
CharSet : array['0'..'9',0..4] of byte =
        ((1,1,3,3,1), (3,1,1,1,3), (1,3,1,1,3),(3,3,1,1,1),
        (1,1,3,1,3), (3,1,3,1,1), (1,3,3,1,1), (1,1,1,3,3),
        (3,1,1,3,1), (1,3,1,3,1));


procedure TBarCode2of5.setpar(u, h : integer; c : boolean; pcanvas : TObject);
begin
     unitx := u;
     ht := h;
     chk := c;
     cnv := TCanvas(pcanvas);
end;



procedure TBarCode2of5.print(startx, starty : integer; msg : string);
var i, mul, positionx, lng:integer;
    oddsum, evensum : integer;

begin
     {calculate lenght of message to encode and add a check character if
      required }
     lng := length(msg);
     if (chk) then begin
        oddsum := 0;
        evensum := 0;
        for i := 1 to lng do begin
            {string position 1 = message position 0}
            if not odd(i) then inc(oddsum, byte(msg[i]) - byte('0'))
            else inc(evensum, byte(msg[i]) - byte('0'));
        end;
        msg := msg + chr((byte('0') + 10 - ((evensum * 3 + oddsum) mod 10)));
     end;
     lng := length(msg);
     {lenght must be even}
     if lng mod 2 <> 0 then begin
        msg := '0'+ msg;
        inc(lng);
     end;

     positionx := startx;
     {start character}
     cnv.fillrect(rect(positionx, starty,positionx + unitx, starty + ht));
     inc (positionx, 2 * unitx);
     cnv.fillrect(rect(positionx , starty,positionx + unitx, starty + ht));
     inc (positionx, 2 * unitx);

     {process string}
     i := 1;
     with cnv do repeat
       for mul := 0 to 4 do begin
           fillrect(rect(positionx, starty, positionx + unitx * CharSet [msg[i], mul], starty + ht));
           inc (positionx, unitx * (CharSet [msg[i], mul] + CharSet [msg[i + 1], mul]));
       end;
       inc (i, 2);
     until i > lng;
     {end caracter}
     cnv.fillrect(rect(positionx, starty, positionx + 3 * unitx, starty + ht));
     cnv.fillrect(rect(positionx + 4 * unitx, starty, positionx + 5 * unitx, starty + ht));

end;

end.
