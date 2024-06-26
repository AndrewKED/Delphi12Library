unit Canvas_Ops;

interface

uses
  System.SysUtils,
  Vcl.Graphics,
  WinAPI.Windows;

procedure AngleTextOut(cnv : TCanvas; const sTxt: string; iX, iY, iH, iAngle: integer);
function TrimStringToFit(const theString : String;
                         target : TCanvas;
                         const availWidth : Integer) : String;

implementation

//***************************************************************************
//
//  FUNCTION  : AngleTextOut
//
//  I/P       :
//
//  O/P       : None
//
//  OPERATION : Output text at a given location and angle on the given TCanvas.
//
//  See
// https://stackoverflow.com/questions/14407158/delete-font-created-by-createfont/52082418#52082418
// https://docwiki.embarcadero.com/CodeExamples/Alexandria/en/RotatedFont_(Delphi)
//      (The second reference did not work smoothly. It left fonts modified)
//
//  UPDATED   : 2022-08-13
//
//***************************************************************************
procedure AngleTextOut(cnv : TCanvas; const sTxt: string; iX, iY, iH, iAngle: integer);
var
  aryC: array[0..255] of Char;
  hFont, hFontOld: THandle;
  hDC : THandle;

begin
  hDC := cnv.Handle;

  StrPCopy(aryC, sTxt);
  hFont:= CreateFont(-iH, 0, iAngle *10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, PChar(cnv.Font.Name));
  hFontOld:= SelectObject(hDC, hFont);
  TextOut(hDC, iX, iY, aryC, StrLen(aryC));
  SelectObject(hDC, hFontOld);
  DeleteObject(hFont);
end; // AngleTextOut

//***************************************************************************
//
//  FUNCTION  : TrimStringToFit
//
//  I/P       :
//
//  O/P       : String - A string that will fit in the given canvas width.
//
//  OPERATION : If the given string, fits within the specified width, on the
//              target canvas, simply return the unaltered string.
//
//              If the string is too wide, determine the maximum number of
//              characters that would fit in the given space, with '...'
//              appended, and return the truncated string, with '...' appended.
//
//  UPDATED   : 2019-11-26
//
//***************************************************************************
function TrimStringToFit(const theString : String;
                         target : TCanvas;
                         const availWidth : Integer) : String;
var
  n : Integer;

begin
  if (target.TextWidth(theString) <= availWidth) then
  begin
    result := theString;
  end // if
  else
  begin
    // For quick and dirty, just work from one end
    n := 0;
    while ((n < Length(theString)) and
           (target.TextWidth(Copy(theString, 1, n) + '...') <= availWidth)) do
    begin
      Inc(n);
    end;

    if (target.TextWidth(Copy(theString, 1, n) + '...') > availWidth) then
    begin
      Dec(n);
    end;

    if (n < 0) then
    begin
      n := 0;
    end;

    result := Copy(theString, 1, n) + '...';
  end; // else
end; // TrimStringToFit

end.
