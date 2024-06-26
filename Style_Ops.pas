unit Style_Ops;

interface

uses
  System.Classes, Vcl.Themes;

procedure LoadAvailableStyles(theList : TStrings);

implementation

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
procedure LoadAvailableStyles(theList : TStrings);
var
  n : Integer;

begin
  if (Assigned(TStyleManager.ActiveStyle)) then
  begin
    theList.Clear;
    for n := 0 to Length(TStyleManager.StyleNames)-1 do
    begin
      theList.Add(TStyleManager.StyleNames[n]);
    end;
  end;
end;

end.
