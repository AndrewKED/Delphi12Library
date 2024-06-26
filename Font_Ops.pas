unit Font_Ops;

interface

const
  MONO_FONT = 'Bitstream Vera Sans Mono';
  FONT_AWESOME_SOLID = 'Font Awesome 5 Pro Solid';
  FONT_AWESOME_REGULAR = 'Font Awesome 5 Pro Regular';

function LoadResourceFont(const ResourceName : String) : Boolean;

implementation

uses
  System.Classes, System.Types,
  WinAPI.Windows;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From
//              https://stackoverflow.com/questions/2984474/embedding-a-font-in-delphi
//
//  UPDATED   : 2019-09-26
//
//***************************************************************************
function LoadResourceFont(const ResourceName : String) : Boolean;
var
 ResStream : tResourceStream;
 FontsCount : Integer;
 hFont : tHandle;

begin
  ResStream := tResourceStream.Create(hInstance, ResourceName, RT_RCDATA);
  hFont := AddFontMemResourceEx(ResStream.Memory, ResStream.Size, nil, @FontsCount);
  result := (hFont <> 0);
  ResStream.Free();
end;

end.
