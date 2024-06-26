unit Print_Ops;

interface

uses Classes, ShellAPI;

function PrinterSupportsDuplex: boolean;
procedure SetPrinterDuplex(sDuplex : shortint);
procedure SetDefaultPrinter(iPrnIndex : integer);
function SetCurrentPrinter(sPrinterName : string) : boolean;
procedure ChangePrinterBin(ToBin: Integer);
procedure GetDriverInfo(Sender : TObject; BinInfo : TStringList);
procedure PrintFile(fileName : String);


implementation

uses
  Windows, Messages, SysUtils, Variants, Printers, WinSpool;

type   // these are needed for reading the Windows and WinSpool units data structures - leave the ^ in!!!!
  LPBYTE = ^byte;
  PPr_info_2 = ^printer_info_2;
  TBinNames = array[ 0..99,0..23] of char;
  PTBinNames = ^TBinNames;

var
  FPrinter : TPrinter;
  FDevice : PChar;
  FDriver : PChar;
  FPort : PChar;
  BinNames : PTBinNames;
  BinCodes : array of word;
  DeviceMode : THandle;
//  DeviceMode2 : LPBYTE; //!! Needed?
  DevMode : PDeviceMode;
  Driver_info_2 : pDriverinfo2;
//  pr_info_2 : PPr_info_2; //!! Needed?
  Retrieved : dword;
  hPrinter : THandle;
  ret2 : pdword;
  CapBuffer : PChar;
  NumCaps : integer;



//***************************************************************************
//
//  FUNCTION  : PrinterSupportsDuplex
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//              From http://www.delphipages.com/forum/showthread.php?t=138183

//ANSINVESTIGATE Look up DEVMODE in Windows SDK help

//
//  UPDATED   : 2012-03-20
//
//***************************************************************************
function PrinterSupportsDuplex: boolean;
var
  Device, Driver, Port: array[0..255] of Char;
  hDevMode: THandle;

begin
  // Get printer device mode handle.
  Printer.GetPrinter(Device, Driver, Port, hDevmode);
  Result := (WinSpool.DeviceCapabilities(Device, Port, DC_DUPLEX, nil, nil) <> 0);
end;

//***************************************************************************
//
//  FUNCTION  : SetPrinterDuplex
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//              From http://www.delphipages.com/forum/showthread.php?t=138183
//
//  UPDATED   :
//
//***************************************************************************
procedure SetPrinterDuplex(sDuplex : shortint);
var
  ADevice, ADriver, APort: array [0..255] of Char;
  DeviceHandle: THandle;
  DevMode: PDeviceMode; // A Pointer to a TDeviceMode structure

begin
  if (PrinterSupportsDuplex) then
  begin
    // First obtain a handle to the TPrinter's DeviceMode structure
    Printer.GetPrinter(ADevice, ADriver, APort, DeviceHandle);

    // If DeviceHandle is still 0, then the driver was not loaded. Set
    // the printer index to force the printer driver to load making the
    // handle available
    if (DeviceHandle = 0) then
    begin
      Printer.PrinterIndex := Printer.PrinterIndex;
      Printer.GetPrinter(ADevice, ADriver, APort, DeviceHandle);
    end; // if

    // If DeviceHandle is still 0, then an error has occurred. Otherwise,
    //  use GlobalLock() to get a pointer to the TDeviceMode structure
    if (DeviceHandle = 0) then
      Raise Exception.Create('Could Not Initialize TDeviceMode structure')
    else
      DevMode := GlobalLock(DeviceHandle);

    with Devmode^ do
    begin
      dmDuplex := sDuplex;
      dmFields := dmFields or DM_DUPLEX;
    end;

    if (DeviceHandle <> 0) then
      GlobalUnlock(DeviceHandle);
  end; // if
end; // SetPrinterDuplex


//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From a posting at borland.public.delphi.objectpascal.
//
//  UPDATED   :
//
//***************************************************************************
procedure SetDefaultPrinter(iPrnIndex : integer);
var
  Device : array[0..255] of char;
  Driver : array[0..255] of char;
  Port : array[0..255] of char;
  hDeviceMode : THandle;
begin
  Printer.PrinterIndex := iPrnIndex;
  Printer.GetPrinter(Device, Driver, Port, hDeviceMode);
  StrCat(Device, ',');
  StrCat(Device, Driver);
  StrCat(Device, ',');
  StrCat(Device, Port);
  WriteProfileString('windows', 'device', Device);
  StrCopy(Device, 'windows');
//  SendMessage(HWND_BROADCAST, WM_WININICHANGE, 0, longint(@Device));
  SendMessage(HWND_BROADCAST, WM_SETTINGCHANGE, 0, longint(@Device));
end; // SetDefaultPrinter

//***************************************************************************
//
//  FUNCTION  : SetCurrentPrinter
//
//  I/P       : sPrinterName (string) - The name of the printer that is to
//                be selected.
//
//  O/P       : (boolean) - TRUE if the printer was found in the list of
//                printers, and the selection was made.
//
//  OPERATION : Set the current printer to be the specified printer.
//
//  UPDATED   : 2007/03/15
//
//***************************************************************************
function SetCurrentPrinter(sPrinterName : string) : boolean;
var
  n : integer;
begin
  Printer.PrinterIndex := Printer.Printers.IndexOf(sPrinterName);
(*
  // Scan through all installed printers, trying to match the name
  n := -1;
  repeat
    Inc(n);
  until ((n >= Printer.Printers.Count) or
         (sPrinterName = Printer.Printers[n]));

  if (n < Printer.Printers.Count) then
  begin
    Printer.PrinterIndex := n;
    result := TRUE;
  end // if
  else
    result := FALSE;
*)
end; // SetCurrentPrinter

//***************************************************************************
//
//  FUNCTION  : ChangePrinterBin
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : from : http://www.efg2.com/Lab/Library/UseNet/1999/1102.txt
//              and http://www.tek-tips.com/viewthread.cfm?qid=1079747
//
//  UPDATED   : 2011-03-18
//
//***************************************************************************
procedure ChangePrinterBin(ToBin: Integer);
var
  ADevice, ADriver, APort: array [0..255] of Char;
  DeviceHandle: THandle;
  DevMode: PDeviceMode; // A Pointer to a TDeviceMode structure

begin
  // First obtain a handle to the TPrinter's DeviceMode structure
  Printer.GetPrinter(ADevice, ADriver, APort, DeviceHandle);

  // If DeviceHandle is still 0, then the driver was not loaded. Set
  // the printer index to force the printer driver to load making the
  // handle available
  if (DeviceHandle = 0) then
  begin
    Printer.PrinterIndex := Printer.PrinterIndex;
    Printer.GetPrinter(ADevice, ADriver, APort, DeviceHandle);
  end; // if

  // If DeviceHandle is still 0, then an error has occurred. Otherwise,
  //  use GlobalLock() to get a pointer to the TDeviceMode structure
  if (DeviceHandle = 0) then
    Raise Exception.Create('Could Not Initialize TDeviceMode structure')
  else
    DevMode := GlobalLock(DeviceHandle);

  with DevMode^ do
  begin
    dmFields := DM_DEFAULTSOURCE;
    dmDefaultSource := ToBin;
  end; // with

  if (not DeviceHandle = 0) then
    GlobalUnlock(DeviceHandle);
end;

//***************************************************************************
//
//  FUNCTION  : MemAllocations_Open
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Sets aside memory for storing the information
//              ANS : It should not be necessary to create an instance of TPrinter
//                since that exists.
//
//  UPDATED   : 2011-03-18
//
//***************************************************************************
procedure MemAllocations_Open(Sender: TObject);
begin
  GetMem(CapBuffer, 10000);
  GetMem(FDevice, 1000);
  GetMem(FDriver, 1000);
  GetMem(FPort, 1000);
  GetMem(ret2, 1000 );
  GetMem(binnames, 2400);
//  fPrinter := TPrinter.Create;
//  fPrinter.PrinterIndex := -1;
end;

//***************************************************************************
//
//  FUNCTION  : MemAllocations_close
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Clears memory when you finish
//
//  UPDATED   : 2011-03-18
//
//***************************************************************************
procedure MemAllocations_close(Sender: TObject);
begin
//  fPrinter.free;
  FreeMem(CapBuffer, 10000);
  FreeMem(FDevice, 1000);
  FreeMem(FDriver, 1000);
  FreeMem(FPort, 1000);
  FreeMem(ret2, 1000 );
  FreeMem(binnames, 2400);
  SetLength( BinCodes, 0 );
end;

//***************************************************************************
//
//  FUNCTION  : GetDriverInfo
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Call this to get the driver information
//              An instance of Pinter should exist, and the PrinterIndex
//                property should be set to the required printer. (-1 = Default)
//
//  UPDATED   : 2011-03-18
//
//***************************************************************************
procedure GetDriverInfo(Sender : TObject; BinInfo : tStringList);
var
  i : integer;

begin
  MemAllocations_Open(Sender);
//  if not assigned(fPrinter) then
//    Exit;

  // This call returns the FDevice string of the selected printer
  Printer.GetPrinter(FDevice, FDriver, FPort, DeviceMode);
  DevMode := GlobalLock(DeviceMode);

  //----------------------------------------------------
  GetMem(Driver_info_2, 1000);
  try
    OpenPrinter(FDevice, hPrinter, nil);
    try
      GetPrinterDriver(hPrinter, nil, 2, Driver_info_2, 1000, Retrieved);
    except
    end;
  except
  end;

  //-------------------------------------------------------
  DeviceCapabilities(FDevice, FPort, DC_BINS, CapBuffer, nil);
  // Bin names
  NumCaps := DeviceCapabilities(FDevice, FPort, DC_BINNAMES, CapBuffer, nil);
  CopyMemory(pointer(BinNames), capbuffer, 2400);
  SetLength(BinCodes, NumCaps);
  FillChar(Pointer(BinCodes)^, NumCaps * Sizeof(word), #0);

  // Bin codes
  NumCaps := DeviceCapabilities(FDevice, FPort, DC_BINS, PChar(BinCodes), nil);
  // Write valid bin codes to the string list
  for i := 0 to NumCaps - 1 do
    if (trim(BinNames[i]) <> '') then
      BinInfo.Add(BinNames[i] + format( ' : Code= %d', [BinCodes[i]]));

  // Clean it all up
  FreeMem(Driver_info_2, 255);
  GlobalUnlock(Devicemode);
  MemAllocations_Close(Sender);
end; // GetDriverInfo

//***************************************************************************
//
//  FUNCTION  : ChangePrinter
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From http://forum.delphiarea.com/viewtopic.php?p=5211
//
//  UPDATED   : 2011-03-18
//
//***************************************************************************
procedure ChangePrinter(ToBin: Integer; ToOrientation: TPrinterOrientation);
var
  ADevice, ADriver, APort: array [0..255] of Char;
  DeviceHandle: THandle;
  DevMode: PDeviceMode; // A Pointer to a TDeviceMode structure

begin
  // First obtain a handle to the TPrinter's DeviceMode structure
  Printer.GetPrinter(ADevice, ADriver, APort, DeviceHandle);

  { If DeviceHandle is still 0, then the driver was not loaded. Set
    the printer index to force the printer driver to load making the
    handle available }
  if DeviceHandle = 0 then
  begin
    Printer.PrinterIndex := Printer.PrinterIndex;
    Printer.GetPrinter(ADevice, ADriver, APort, DeviceHandle);
  end;
  { If DeviceHandle is still 0, then an error has occurred. Otherwise,
    use GlobalLock() to get a pointer to the TDeviceMode structure }
  if DeviceHandle = 0 then
    Raise Exception.Create('Could Not Initialize TDeviceMode structure');

  DevMode := GlobalLock(DeviceHandle);
  try
    with DevMode^ do
    begin
      dmFields := DM_DEFAULTSOURCE or DM_ORIENTATION;
      dmDefaultSource := ToBin;
      case ToOrientation of
        poPortrait: dmOrientation := DMORIENT_PORTRAIT;
        poLandscape: dmOrientation := DMORIENT_LANDSCAPE;
      end;
    end;
  finally
    GlobalUnlock(DeviceHandle);
  end;
end; //

//***************************************************************************
//
//  FUNCTION  : PrintFile
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : This function will print any file type that Windows knows how
//              to handle (e.g. .doc, .pdf etc), on the default printer.
// see http://delphi.about.com/od/delphitips2009/qt/delphi-print-documents-shellexecute-print-printto.htm
//
//  UPDATED   : 2016-10-13
//
//***************************************************************************
procedure PrintFile(fileName : String);
begin
  ShellExecute(Handle, 'print', PChar(fileName), nil, nil, SW_HIDE);
end;

// Duplex Printing
// see http://www.delphipages.com/forum/showthread.php?t=162930

end.
