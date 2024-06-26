unit SpecialChar;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, ExtCtrls;

type
  TfSpecialCharacters = class(TForm)
    sgCharacters: TStringGrid;
    Panel1: TPanel;
    procedure sgCharactersDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fSpecialCharacters: TfSpecialCharacters;

implementation

uses Clipbrd;

{$R *.DFM}

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
procedure TfSpecialCharacters.sgCharactersDblClick(Sender: TObject);
begin
  Clipboard.AsText := Char(sgCharacters.Row * 16 + sgCharacters.Col);
  Close;
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
procedure TfSpecialCharacters.FormCreate(Sender: TObject);
var
  n : integer;
begin
  // Fill in the grid with 256 characters
  for n := 0 to 255 do
    sgCharacters.Cells[n mod 16,n div 16] := Char(n);
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
procedure TfSpecialCharacters.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case (Key) of
    VK_ESCAPE:
    begin
      Clipboard.AsText := '';
      Close;
    end; // option

    VK_RETURN:
    begin
      sgCharactersDblClick(Sender);
    end; // option
  end; // case
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
procedure TfSpecialCharacters.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
  fSpecialCharacters := nil;
end;

end.
