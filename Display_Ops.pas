unit Display_Ops;

interface

uses
  Types;

const
  DMDO_DEFAULT : DWord  = 0;
  DMDO_90      : DWord  = 1;
  DMDO_180     : DWord  = 2;
  DMDO_270     : DWord  = 3;

function GetDisplayOrientation : Integer;
procedure ChangeDisplayOrientation(NewOrientation : DWord);
procedure ChangeDisplayOrientation2(NewOrientation : DWord);
function GetBestDisplayFit(RequiredX : Integer;
                           RequiredY : Integer) : Integer;

implementation

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms;

const
  ENUM_CURRENT_SETTINGS: DWORD = $FFFFFFFF;

type
  _devicemode = record
    dmDeviceName: array [0..CCHDEVICENAME - 1] of {$IFDEF UNICODE} WideChar {$ELSE} AnsiChar {$ENDIF};
    dmSpecVersion: WORD;
    dmDriverVersion: WORD;
    dmSize: WORD;
    dmDriverExtra: WORD;
    dmFields: DWORD;
    union1: record
    case Integer of
      // printer only fields
      0: (
        dmOrientation: Smallint;
        dmPaperSize: Smallint;
        dmPaperLength: Smallint;
        dmPaperWidth: Smallint;
        dmScale: Smallint;
        dmCopies: Smallint;
        dmDefaultSource: Smallint;
        dmPrintQuality: Smallint);
      // display only fields
      1: (
        dmPosition: TPointL;
        dmDisplayOrientation: DWORD;
        dmDisplayFixedOutput: DWORD);
    end;
    dmColor: Shortint;
    dmDuplex: Shortint;
    dmYResolution: Shortint;
    dmTTOption: Shortint;
    dmCollate: Shortint;
    dmFormName: array [0..CCHFORMNAME - 1] of {$IFDEF UNICODE} WideChar {$ELSE} AnsiChar {$ENDIF};
    dmLogPixels: WORD;
    dmBitsPerPel: DWORD;
    dmPelsWidth: DWORD;
    dmPelsHeight: DWORD;
    dmDiusplayFlags: DWORD;
    dmDisplayFrequency: DWORD;
    dmICMMethod: DWORD;
    dmICMIntent: DWORD;
    dmMediaType: DWORD;
    dmDitherType: DWORD;
    dmReserved1: DWORD;
    dmReserved2: DWORD;
    dmPanningWidth: DWORD;
    dmPanningHeight: DWORD;
  end;
  devicemode  = _devicemode;
  Pdevicemode = ^devicemode;

var
  OriginalScreenOrientation : Integer;

//***************************************************************************
//
//  FUNCTION  : GetDisplayOrientation
//
//  I/P       : None
//
//  O/P       : Integer - (-1) if unavailable, else 0..3 for 0,90,180,270°
//
//  OPERATION : Returns the current display orientation
//
//  UPDATED   : 2016-06-08
//
//***************************************************************************
function GetDisplayOrientation : Integer;
var
  dm : TDeviceMode;

begin
  ZeroMemory(@dm, sizeof(dm));
  dm.dmSize := sizeof(dm);
  // Get the current settings
  if EnumDisplaySettings(nil, DWORD(ENUM_CURRENT_SETTINGS), dm) then
    result := Pdevicemode(@dm)^.union1.dmDisplayOrientation
  else
    result := -1;
end; // GetDisplayOrientation

//***************************************************************************
//
//  FUNCTION  : ChangeDisplayOrientation
//
//  I/P       : NewOrientation : DWord -
//
//  O/P       :
//
//  OPERATION : See
//              https://theroadtodelphi.com/2011/02/11/changing-screen-orientation-programmatically-using-delphi/
//
//  UPDATED   : 2016-06-08
//
//***************************************************************************
procedure ChangeDisplayOrientation(NewOrientation : DWord);
var
  dm       : TDeviceMode;
  dwTemp  : DWord;

begin
  ZeroMemory(@dm, sizeof(dm));
  dm.dmSize := sizeof(dm);
  // Get the current settings
  if EnumDisplaySettings(nil, DWORD(ENUM_CURRENT_SETTINGS), dm) then
  begin
    //Now this part is very important :
    //when we change the orientation also we are changing resolution of the screen
    //example : if the current orientation is 1024x768x0 (0 is the default orientation)
    // and we need set the orientation to 90 degrees we must swap the values of the width
    // and height, so the new resolution will be (768x1024x90)
    //The next lines makes this trick using the values of the current and new orientation
    if (Odd(Pdevicemode(@dm)^.union1.dmDisplayOrientation) <> Odd(NewOrientation)) then
    begin
      dwTemp := dm.dmPelsHeight;
      dm.dmPelsHeight:= dm.dmPelsWidth;
      dm.dmPelsWidth := dwTemp;
    end;

    //Now casting the Windows.TDeviceMode record with our devicemode record
    if (Pdevicemode(@dm)^.union1.dmDisplayOrientation <> NewOrientation) then
    begin
      //casting again to set the new orientation
      Pdevicemode(@dm)^.union1.dmDisplayOrientation := NewOrientation;
      //setting the new orientation
      if (ChangeDisplaySettings(dm, 0) <> DISP_CHANGE_SUCCESSFUL) then
        RaiseLastOSError;
    end;
  end;
end; // ChangeDisplayOrientation

//***************************************************************************
//
//  FUNCTION  : ChangeDisplayOrientation2
//
//  I/P       : NewOrientation : DWord -
//
//  O/P       :
//
//  OPERATION : Esentially the same as the function above.
//              See
//              https://theroadtodelphi.com/2011/02/11/changing-screen-orientation-programmatically-using-delphi/
//
//  UPDATED   : 2016-06-08
//
//***************************************************************************
procedure ChangeDisplayOrientation2(NewOrientation : DWord);
var
  dm      : TDeviceMode;
  dwTemp  : DWord;
  dmDisplayOrientation : DWord;

begin
  ZeroMemory(@dm, sizeof(dm));
  dm.dmSize   := sizeof(dm);
  if (EnumDisplaySettings(nil, DWORD(ENUM_CURRENT_SETTINGS), dm)) then
  begin
    //In the TDevMode record the offset of the dmScale field is equal to the position of the dmDisplayOrientation field
    //so using the move procedure we can get the value of the dmDisplayOrientation field
    Move(dm.dmScale,dmDisplayOrientation,SizeOf(dmDisplayOrientation));
    //See the coments in the previous method
    // swap width and height
    if (Odd(dmDisplayOrientation) <> Odd(NewOrientation)) then
    begin
      dwTemp := dm.dmPelsHeight;
      dm.dmPelsHeight:= dm.dmPelsWidth;
      dm.dmPelsWidth := dwTemp;
    end;

    if (dmDisplayOrientation <> NewOrientation) then
    begin
    //set the value of the   dmDisplayOrientation
      Move(NewOrientation,dm.dmScale,SizeOf(NewOrientation));
      if (ChangeDisplaySettings(dm, 0)<>DISP_CHANGE_SUCCESSFUL) then
        RaiseLastOSError;
    end;
  end;
end; // ChangeDisplayOrientation2

//***************************************************************************
//
//  FUNCTION  : GetBestDisplayFit
//
//  I/P       : RequiredX : DWord - } The minimum-X and -Y screen resolution that
//              RequiredY : DWord - } is required.
//
//  O/P       : Integer - -1 if the display will not fit in any orientation,
//              else 0..3 for the best fit 0,90,180,270°
//
//  OPERATION :
//
    // From http://liliputing.com/2009/04/a-thorough-examination-of-netbook-screen-sizes.html
    // 7 inch - 800 x 480 pixels
    // 8.9 inch – 1024 x 600 pixels
    // 10.1 inch – 1024 x 576 pixels or 1366 x 768 pixels
    // 10.2 inch – 1024 x 600 pixels
    // 11.6 inch – 1366 x 768 pixels
    // 12.1 inch – 1280 x 800 pixels
//
//  UPDATED   : 2016-06-08
//
//***************************************************************************
function GetBestDisplayFit(RequiredX : Integer;
                           RequiredY : Integer) : Integer;
begin
  if (RequiredX > RequiredY) then
  begin
    // We would like to have a landscape display
    if (Screen.Width > Screen.Height) then
    begin
      // The display is currently in landscape mode
      if ((Screen.Width < RequiredX) or (Screen.Height < RequiredY)) then
        // No fit
        result := -1
      else
      begin
        // OK as we are (DMDO_DEFAULT or, less likely, DMDO_180)
        result := GetDisplayOrientation;
        if (result = -1) then
          result := DMDO_DEFAULT;
      end; // else
    end // if
    else
    begin
      // The display is currently in portrait mode
      if ((Screen.Width < RequiredX) or (Screen.Height < RequiredY)) then
      begin
        // The landscape requirements do not fit into the current portrait mode.
        // Check what might happen if we rotated the display to landscape mode.
        if ((Screen.Height < RequiredX) or (Screen.Width < RequiredY)) then
          // The landscape requirements are not going to fit into a landscape display either
          result := -1
        else
          // Suggest rotating the display to landscape mode
          result := DMDO_DEFAULT;
      end
      else
      begin
        // The resolution is acceptable this way, but may look better in landscape
        if ((Screen.Height < RequiredX) or (Screen.Width < RequiredY)) then
        begin
          // It will not fit into a rotated (landscape) display, so leave the
          // display as it is (DMDO_90 or DMDO_270).
          result := GetDisplayOrientation;
          if (result = -1) then
            result := DMDO_90;
        end
        else
          // Suggest rotating the display to landscape mode
          result := DMDO_DEFAULT;
      end; // else
    end; // else
  end
  else
  begin
    // We would like to have a portrait display
    if (Screen.Width < Screen.Height) then
    begin
      // The display is currently in portrait mode
      if ((Screen.Width < RequiredX) or (Screen.Height < RequiredY)) then
        // No fit
        result := -1
      else
      begin
        // OK as we are (DMDO_90 or DMDO_270)
        result := GetDisplayOrientation;
        if (result = -1) then
          result := DMDO_90;
      end; // else
    end // if
    else
    begin
      // The display is currently in landscape mode
      if ((Screen.Width < RequiredX) or (Screen.Height < RequiredY)) then
      begin
        // The portrait requirements do not fit into the current landscape mode.
        // Check what might happen if we rotated the display to portrait mode.
        if ((Screen.Height < RequiredX) or (Screen.Width < RequiredY)) then
          // The portrait requirements are not going to fit into a portrait display either
          result := -1
        else
          // Suggest rotating the display to portrait mode
          result := DMDO_90;
      end
      else
      begin
        // The resolution is acceptable this way, but may look better in portrait mode
        if ((Screen.Height < RequiredX) or (Screen.Width < RequiredY)) then
        begin
          // It will not fit into a rotated (portrait) display, so leave the
          // display as it is (DMDO_DEFAULT or, less likely, DMDO_270).
          result := GetDisplayOrientation;
          if (result = -1) then
            result := DMDO_DEFAULT;
        end // if
        else
          // Suggest rotating the display to portrait mode
          result := DMDO_90;
      end; // else
    end; // else
  end;
end; // GetBestDisplayFit

//***************************************************************************
//
//  FUNCTION  : initialization
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Record the current screen orientation, just in case it gets
//              changed during this program.
//
//  UPDATED   : 2016-06-08
//
//***************************************************************************
initialization
begin
  OriginalScreenOrientation := GetDisplayOrientation;
end;

//***************************************************************************
//
//  FUNCTION  : finalization
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Restore the screen orientation to whatever it was when the
//              program was started.
//
//  UPDATED   : 2016-06-08
//
//***************************************************************************
finalization
begin
  if ((OriginalScreenOrientation <> -1) and
      (OriginalScreenOrientation <> GetDisplayOrientation)) then
    ChangeDisplayOrientation(OriginalScreenOrientation);
end;

end.
