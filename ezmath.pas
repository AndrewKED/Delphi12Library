unit EZMath;
(***********************************************)
(* Elememtary functions not in Standard Delphi *)
(* R. Bullock email: bullocrm@muohio.edu       *)
(***********************************************)
interface

(**** Missing Trig functions ****)
function Tan(x : extended) : extended;
function Cot(x : extended) : extended;
function Sec(x : extended) : extended;
function Csc(x : extended) : extended;

(**** Principal Polar Coordinates ****)
{Euclidean plane distance from (0,0) to (x,y)}
function EuclideanNorm(x,y : extended): extended;
{angle the ray [(0,0),(x,y)] makes with positive x-axis; note x is first!}
function arctan2(x,y : extended) : extended;

(**** Missing inverse Trig functions ****)
{Note: ArcSec and ArcCsc range is [0,pi/2)U[pi,3*pi/2)}
function ArcSin(x : extended) : extended;
function ArcCos(x : extended) : extended;
function ArcCot(x : extended) : extended;
function ArcSec(x : extended) : extended;
function ArcCsc(x : extended) : extended;

(**** Base 10 and base a > 0 Logarithm functions ****)
function Log10(x : extended) : extended;
function Log(a,x : extended) : extended;

(**** Power functions ****)
function Pow(x : extended; n : integer) : extended; {faster(?) for integer}
(*
function Power(x,y : extended) : extended; {x^y for x > 0}
*)
(**** Hyperbolic functions ****)
function Sinh(x : extended) : extended;
function Cosh(x : extended) : extended;
function Tanh(x : extended) : extended;
function Coth(x : extended) : extended;
function Sech(x : extended) : extended;
function Csch(x : extended) : extended;

(**** Inverse hyperbolic functions ****)
function ASinh(x : extended) : extended;
function ACosh(x : extended) : extended;
function ATanh(x : extended) : extended;
function ACoth(x : extended) : extended;
function ASech(x : extended) : extended;
function ACsch(x : extended) : extended;

(******************************************************************************)
(******************************************************************************)
implementation

function Tan(x : extended) : extended; assembler;
asm
   FLD x
   FPTAN
   FSTP ST(0)
   FWAIT
end;

function Cot(x : extended) : extended;
begin
  Result := Tan(pi/2 - x);
end;

function Sec(x : extended) : extended;
begin
  Result := 1/Cos(x);
end;

function Csc(x : extended) : extended;
begin
  Result := Sec(pi/2 - x);
end;

function EuclideanNorm(x,y : extended) : extended;
var
  u : extended;
begin {algorithm reduces chance of overflow in mid calculation}
  if x = 0.0 then
    Result := Abs(y)
  else if  y = 0.0 then
    Result := Abs(x)
  else if Abs(x) > Abs(y) then
    begin
      u := y/x;
      Result := Abs(x)*Sqrt(1.0 + u*u);
    end
  else
    begin
       u := x/y;
       Result := Abs(y)*Sqrt(1.0 + u*u);
    end;
end;

function  ArcTan2(x,y : extended) : extended; assembler;
asm
   FLD y
   FLD x
   FPATAN
   FWAIT
end;

function ArcSin(x : extended) : extended;
begin
  Result := ArcTan2(Sqrt(1-Sqr(x)),x);
end;

function ArcCos(x : extended) : extended;
begin
  Result := pi/2 - arcsin(x);
end;

function ArcCot(x : extended) : extended;
begin
  Result := pi/2 - ArcTan(x);
end;

function ArcSec(x : extended) : extended;
begin
  Result := ArcCos(1/Abs(x));
  if x < 0 then Result := Result + pi;
end;

function ArcCsc(x : extended) : extended;
begin
  Result := ArcSin(1/Abs(x));
  if x < 0 then Result := Result + pi;
end;

function Log10(x : extended) : extended; assembler;
asm
   FLDLG2
   FLD X
   FYL2X
   FWAIT
end;

function Log(a,x : extended) : extended;
begin
  Result := Ln(x)/Ln(a);
end;

function Pow(x : extended; n : integer) : extended;
var
  m : cardinal;
begin
  Result := 1;
  if (x = 0) and (n = 0) then exit
  else if n = 0 then Result := 1
  else if x = 0 then Result := 0
  else begin
    m := Abs(n);
    while m > 0 do begin
      while not Odd(m) do
        begin
          m := m shr 1;
          x := x*x
        end;
      Dec(m);
      Result := Result*x
    end;
  end;
  if n < 0 then Result := 1/Result
end;
(*
function Power(x,y : extended) : extended;
begin
  Result := Exp(y*ln(x));
end;
*)
function Sinh(x : extended) : extended;
begin
  Result := (Exp(x) - Exp(-x))/2;
end;

function Cosh(x : extended) : extended;
begin
  Result := (Exp(x) + Exp(-x))/2;
end;

function Tanh(x : extended) : extended;
begin
  Result := Sinh(x)/Cosh(x);
end;

function Coth(x : extended) : extended;
begin
  Result := 1/Tanh(x);
end;

function Sech(x : extended) : extended;
begin
  Result := 1/cosh(x);
end;

function Csch(x : extended) : extended;
begin
  Result := 1/Sinh(x);
end;

function ASinh(x : extended) : extended;
begin
  Result := Ln(x + Sqrt(Sqr(x) + 1));
end;

function ACosh(x : extended) : extended;
begin
  Result := Ln(x + Sqrt(Sqr(x) - 1));
end;

function ATanh(x : extended) : extended;
 begin
  Result := Ln((1 + x)/(1 - x))/2;
end;

function ACoth(x : extended) : extended;
begin
  Result := Ln((1 + x)/(x - 1))/2;
end;

function ASech(x : extended) : extended;
begin
  Result := Ln(1/x + Sqrt(Sqr(1/x) - 1));
end;

function ACsch(x : extended) : extended;
 begin
  Result := Ln(1/x + Sqrt(Sqr(1/x) + 1));
end;

end.
