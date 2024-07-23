unit Font_Ops;

interface

const
  // These are the names of the fonts, as they appear in TControl properties,
  // or in the Control Panel Fonts.
  // If the fonts are changed (e.g. a version upgrade), ensure that the project
  // resources are correctly defined (under Project / Resource and Imaged, if
  // for-application dynamic font loading is being used).
  // Also check all TControl.Font.Name properties (in .dfm files) are correct.
  MONO_FONT = 'Bitstream Vera Sans Mono';
  FONT_AWESOME_SOLID = 'Font Awesome 6 Pro Solid Black';
  FONT_AWESOME_REGULAR = 'Font Awesome 6 Pro Regular';

  FA_ICON_CHECK = #$F00C;
  FA_ICON_ARROW_LEFT = #$F060;
  FA_ICON_SHOW_PASSWORD = #$F06E;
  FA_ICON_HIDE_PASSWORD = #$F070;
  FA_ICON_PLAY = #$F04B;
  FA_ICON_PAUSE = #$F04C;

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
