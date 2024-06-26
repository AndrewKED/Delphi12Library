unit Spline;

interface

uses
  SysUtils, Classes, Math;



function SplineFit(x, y: array of real; npoints: integer; AtX:real;Lambda:real):real;

implementation

const dim = 75;
Infinity         =     1.0 / 0.0;

type
vector = array[-1..dim] of real;
SplineParameters = record
 x, y, a, b, c, d: real
end; {rows}
SplineVec = array[-5..dim] of SplineParameters;



procedure Quincunx (n: integer; var u, v, w, q: vector);

var
    j: integer;

begin {Quincunx}

{factorisation}
    u[-1] := 0;
    u[0] := 0;
    v[0] := 0;
    w[-1] := 0;
    w[0] := 0;
    for j := 1 to n - 1 do
      begin
        u[j] := u[j] - u[j - 2] * Sqr(w[j - 2]) - u[j - 1] * Sqr(v[j - 1]);
        v[j] := (v[j] - u[j - 1] * v[j - 1] * w[j - 1]) / u[j];
        w[j] := w[j] / u[j];
      end;

{forward substitution}
    q[0] := 0;
    q[-1] := 0;
    for j := 1 to n - 1 do
      q[j] := q[j] - v[j - 1] * q[j - 1] - w[j - 2] * q[j - 2];
    for j := 1 to n - 1 do
      q[j] := q[j] / u[j];

{back substitution}
    q[n + 1] := 0;
    q[n] := 0;
    for j := n - 1 downto 1 do
      q[j] := q[j] - v[j] * q[j + 1] - w[j] * q[j + 2];

end; {Quincunx}


{
The SmoothingSpline procedure calculates the parameters of the segments of a cubic smoothing spline
which is fitted to the points (x_0, y_0), ldots, (x_n, y_n) by least-squares regression.
The degree of smoothness is determined by the parameter lambda in [0, 1].
Setting lambda = 1 gives the interpolating spline, whereas setting lambda = 0 gives the linear least-squares regression.
The array sigma contains the weights which are associated with the deviations in the least-squares criterion function.
}

procedure SmoothingSpline (var S: SplineVec; sigma: vector; lambda: real; n: integer);

const
almostZero = 0.00001;

var
h, r, f, p, q, u, v, w: vector;
i, j: integer;
mu: real;

begin {SmoothingSpline}

    if lambda < almostZero then
      mu := 0
    else
      mu := 2 * (1 - lambda) / (3 * lambda);

    h[0] := S[1].x - S[0].x;
    r[0] := 3 / h[0];
    for i := 1 to n - 1 do
      begin
        h[i] := S[i + 1].x - S[i].x;
        r[i] := 3 / h[i];
        f[i] := -(r[i - 1] + r[i]);
        p[i] := 2 * (S[i + 1].x - S[i - 1].x);
        q[i] := 3 * (S[i + 1].y - S[i].y) / h[i] - 3 * (S[i].y - S[i - 1].y) / h[i - 1];
      end;
    r[n] := 0;
    f[n] := 0;

    for i := 1 to n - 1 do
      begin
        u[i] := Sqr(r[i - 1]) * sigma[i - 1] + Sqr(f[i]) * sigma[i] + Sqr(r[i]) * sigma[i + 1];
        u[i] := mu * u[i] + p[i];
        v[i] := f[i] * r[i] * sigma[i] + r[i] * f[i + 1] * sigma[i + 1];
        v[i] := mu * v[i] + h[i];
        w[i] := mu * r[i] * r[i + 1] * sigma[i + 1];
      end;

    Quincunx(n, u, v, w, q);

{Spline Parameters}
    S[0].d := S[0].y - mu * r[0] * q[1] * sigma[0];
    S[1].d := S[1].y - mu * (f[1] * q[1] + r[1] * q[2]) * sigma[0];
    S[0].a := q[1] / (3 * h[0]);
    S[0].b := 0;
    S[0].c := (S[1].d - S[0].d) / h[0] - q[1] * h[0] / 3;
    r[0] := 0;

    for j := 1 to n - 1 do
      begin
        S[j].a := (q[j + 1] - q[j]) / (3 * h[j]);
        S[j].b := q[j];
        S[j].c := (q[j] + q[j - 1]) * h[j - 1] + S[j - 1].c;
        S[j].d := r[j - 1] * q[j - 1] + f[j] * q[j] + r[j] * q[j + 1];
        S[j].d := S[j].y - mu * S[j].d * sigma[j];
      end;

    S[n].d := S[n].y - mu * r[n - 1] * q[n - 1] * sigma[n];

end;{SmoothingSpline}


function SplineFit(x, y: array of real; npoints: integer; AtX:real;Lambda:real):real;
var i,j,k:integer;
    SV:SplineVec;
    Sigma:vector;
    LastX:real;

begin
j:=-1;
k:=0;
LastX:=x[npoints-1]-1;
for i:= npoints-1 downto 0 do begin
 if (LastX < x[i]) then begin
  Sv[k].y:=y[i];
  Sv[k].x:=x[i];
  Sigma[k]:=1;
  inc(k);
  LastX:=x[i];
  if (LastX >= AtX) and (j<0) then j:=k-1;
 end;
end;
if (j>0) then begin
    SmoothingSpline(SV, Sigma,Lambda,k-1);
    Result:=SV[j].a * power(AtX-SV[j].x,3) + SV[j].b * power(AtX-SV[j].x,2) + SV[j].c * (AtX-SV[j].x) + SV[j].d;
end
else Result:=INFINITY;
end;


end.


