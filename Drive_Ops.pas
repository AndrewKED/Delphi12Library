unit Drive_Ops;

interface

uses
  System.Types;


{$MINENUMSIZE 4}
const
  IOCTL_STORAGE_QUERY_PROPERTY =  $002D1400;

type
  STORAGE_QUERY_TYPE = (PropertyStandardQuery = 0, PropertyExistsQuery, PropertyMaskQuery, PropertyQueryMaxDefined);
  TStorageQueryType = STORAGE_QUERY_TYPE;

  STORAGE_PROPERTY_ID = (StorageDeviceProperty = 0, StorageAdapterProperty);
  TStoragePropertyID = STORAGE_PROPERTY_ID;

  STORAGE_PROPERTY_QUERY = packed record
    PropertyId: STORAGE_PROPERTY_ID;
    QueryType: STORAGE_QUERY_TYPE;
    AdditionalParameters: array [0..9] of AnsiChar;
  end;
  TStoragePropertyQuery = STORAGE_PROPERTY_QUERY;

  STORAGE_BUS_TYPE = (BusTypeUnknown = 0, BusTypeScsi, BusTypeAtapi, BusTypeAta, BusType1394, BusTypeSsa, BusTypeFibre,
    BusTypeUsb, BusTypeRAID, BusTypeiScsi, BusTypeSas, BusTypeSata, BusTypeMaxReserved = $7F);
  TStorageBusType = STORAGE_BUS_TYPE;

  STORAGE_DEVICE_DESCRIPTOR = packed record
    Version: DWORD;
    Size: DWORD;
    DeviceType: Byte;
    DeviceTypeModifier: Byte;
    RemovableMedia: Boolean;
    CommandQueueing: Boolean;
    VendorIdOffset: DWORD;
    ProductIdOffset: DWORD;
    ProductRevisionOffset: DWORD;
    SerialNumberOffset: DWORD;
    BusType: STORAGE_BUS_TYPE;
    RawPropertiesLength: DWORD;
    RawDeviceProperties: array [0..0] of AnsiChar;
  end;
  TStorageDeviceDescriptor = STORAGE_DEVICE_DESCRIPTOR;

function GetDriveSerial(const Drive:AnsiChar;
                        const ddType : String) : String;
function GetAvailableDrives : String;
function GetBusType(Drive: AnsiChar): TStorageBusType;

implementation

uses
  Windows,
  System.IOUtils,
  ActiveX,
  Vcl.OleAuto,
  System.Variants,
  System.SysUtils,
  System.StrUtils;

type
// this type takes care of the wrong prototyping of Borland
// of the GetDiskFreeSpaceEx function
  TInt64 = record
    case i : integer of
      0 : (iV1, iV2 : integer);
      1 : (iV64     : comp);
  end;

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
function VarArrayToStr(const vArray: variant): string;

  function _VarToStr(const V: variant): string;
  var
  Vt: integer;
  begin
  Vt := VarType(V);
    case Vt of
      varSmallint,
      varInteger  : Result := IntToStr(integer(V));
      varSingle,
      varDouble,
      varCurrency : Result := FloatToStr(Double(V));
      varDate     : Result := VarToStr(V);
      varOleStr   : Result := WideString(V);
      varBoolean  : Result := VarToStr(V);
      varVariant  : Result := VarToStr(Variant(V));
      varByte     : Result := char(byte(V));
      varString   : Result := String(V);
      varArray    : Result := VarArrayToStr(Variant(V));
    end;
  end;

var
i : integer;
begin
  Result := '[';
  if (VarType(vArray) and VarArray)=0 then
     Result := _VarToStr(vArray)
  else
  for i := VarArrayLowBound(vArray, 1) to VarArrayHighBound(vArray, 1) do
    if i=VarArrayLowBound(vArray, 1) then
      Result := Result+_VarToStr(vArray[i])
    else
      Result := Result+'|'+_VarToStr(vArray[i]);

  Result:=Result+']';
end;

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
function VarStrNull(const V:OleVariant):string; //avoid problems with null strings
begin
  Result:='';
  if not VarIsNull(V) then
  begin
    if VarIsArray(V) then
       Result:=VarArrayToStr(V)
    else
    Result:=VarToStr(V);
  end;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : create the Wmi instance
//
//  UPDATED   :
//
//***************************************************************************
//function GetWMIObject(const objectName: String): IDispatch;
//var
//  chEaten: Integer;
//  BindCtx: IBindCtx;
//  Moniker: IMoniker;
//begin
//  OleCheck(CreateBindCtx(0, bindCtx));
//  OleCheck(MkParseDisplayName(BindCtx, StringToOleStr(objectName), chEaten, Moniker));
//  OleCheck(Moniker.BindToObject(BindCtx, nil, IDispatch, Result));
//end;

//***************************************************************************
//
//  FUNCTION  : GetDriveSerial
//
//  I/P       : const Drive:AnsiChar - Drive ID e.g. 'C'
//
//              const ddType : String - Drive type ('IDE' or 'USB')
//
//  O/P       : String - The drive serial number
//
//  OPERATION : Some drivers of the USB disks does not expose the manufacturer
//              serial number on the Win32_DiskDrive.SerialNumber property,
//              so on this cases you can extract the serial number from the
//              PnPDeviceID property.
//
//              See
//              https://stackoverflow.com/questions/4292395/how-to-get-manufacturer-serial-number-of-an-usb-flash-drive
//
//  For hard discs, from https://winaero.com/blog/find-hard-disk-serial-number-windows-10/
//    1) Open an elevated command prompt.
//    2) Type or copy-paste the following command: wmic diskdrive get Name, Manufacturer, Model, InterfaceType, MediaType, SerialNumber .
//    3) In the output, you'll see the model, name, and serial number listed for the installed hard drives
//
//  UPDATED   : 2018-09-25
//
//***************************************************************************
function GetDriveSerial(const Drive:AnsiChar;
                        const ddType : String) : String;
var
 FSWbemLocator   : OleVariant;
  objWMIService  : OLEVariant;
  colDiskDrives  : OLEVariant;
  colLogicalDisks: OLEVariant;
  colPartitions  : OLEVariant;
  objDiskDrive   : OLEVariant;
  objPartition   : OLEVariant;
  objLogicalDisk : OLEVariant;
  oEnumDiskDrive : IEnumvariant;
  oEnumPartition : IEnumvariant;
  oEnumLogical   : IEnumvariant;
  iValue         : LongWord;
  DeviceID       : string;
begin;
  CoInitialize(nil);
  try
    Result:='';
    FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    objWMIService := FSWbemLocator.ConnectServer('.', 'root\CIMV2', '', '');
    colDiskDrives := objWMIService.ExecQuery('SELECT * FROM Win32_DiskDrive WHERE InterfaceType="' + ddType + '"','WQL',0);
    oEnumDiskDrive := IUnknown(colDiskDrives._NewEnum) as IEnumVariant;
    while (oEnumDiskDrive.Next(1, objDiskDrive, iValue) = 0) do
    begin
      DeviceID := StringReplace(VarStrNull(objDiskDrive.DeviceID),'\','\\',[rfReplaceAll]); //Escape the `\` chars in the DeviceID value because the '\' is a reserved character in WMI.
      colPartitions := objWMIService.ExecQuery(Format('ASSOCIATORS OF {Win32_DiskDrive.DeviceID="%s"} WHERE AssocClass = Win32_DiskDriveToDiskPartition',[DeviceID]));//link the Win32_DiskDrive class with the Win32_DiskDriveToDiskPartition class
      oEnumPartition := IUnknown(colPartitions._NewEnum) as IEnumVariant;
      while (oEnumPartition.Next(1, objPartition, iValue) = 0) do
      begin
        colLogicalDisks := objWMIService.ExecQuery('ASSOCIATORS OF {Win32_DiskPartition.DeviceID="'+VarStrNull(objPartition.DeviceID)+'"} WHERE AssocClass = Win32_LogicalDiskToPartition'); //link the Win32_DiskPartition class with theWin32_LogicalDiskToPartition class.
        oEnumLogical := IUnknown(colLogicalDisks._NewEnum) as IEnumVariant;
        while (oEnumLogical.Next(1, objLogicalDisk, iValue) = 0) do
        begin
          // Compare the device id
          if (SameText(VarStrNull(objLogicalDisk.DeviceID),Drive+':')) then
          begin
            if (ddType = 'IDE') then
            begin
              // IDE drive
              // .SerialNumber does work on some USB drives, but I found it added an extra character
              Result := VarStrNull(objDiskDrive.SerialNumber);
              Exit;
            end // if
            else
            begin
              // USB drive
              Result := VarStrNull(objDiskDrive.PnPDeviceID);
              if (AnsiStartsText('USBSTOR', Result)) then
              begin
                iValue:=LastDelimiter('\', Result);
                Result:=Copy(Result, iValue+1, Length(Result));
              end; // if
              objLogicalDisk := Unassigned;
              Exit;
            end; // else
          end; // if
          objLogicalDisk := Unassigned;
        end; // while
        objPartition := Unassigned;
      end; // while
      objDiskDrive := Unassigned;
    end; // while
  finally
    CoUninitialize;
  end; // finally
end;

//***************************************************************************
//
//  FUNCTION  : DiskSize
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
function DiskSize(drive : char;
                  var totFreeBytesAvailable : Int64;
                  var totNumberOfBytes : Int64;
                  var totNumberOfFreeBytes : Int64) : boolean;
var
  iTotBytes      : comp;
  iTotFree       : comp;
  s              : string;
  pc             : array[0..255] of char;
  fSuccess       : boolean;
  i6FBA : TInt64;
  i6NoB : TInt64;
  i6NoFB : TInt64;

begin
  result := FALSE;
  s := drive + ':\';
  iTotBytes := 0;
//  result := SysUtils.GetDiskFreeSpaceEx(PChar(s),totFreeBytesAvailable, totNumberOfBytes, totNumberOfFreeBytes);
end; // DiskSize

//***************************************************************************
//
//  FUNCTION  : GetAvailableDrives
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2018-09-25
//
//***************************************************************************
function GetAvailableDrives : String;
var
  Drives: TStringDynArray;
  Drive: string;
  n : Integer;

begin
  Drives := TDirectory.GetLogicalDrives;
  result := '';
  n := 0;
  while (n < Length(Drives)) do
  begin
    result := result + Copy(Drives[n],1,1);
    Inc(n);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : GetBusType
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : See
//              https://stackoverflow.com/questions/3718192/delphi-how-to-get-list-of-usb-removable-hard-drives-and-memory-sticks
//
//  UPDATED   :
//
//***************************************************************************
function GetBusType(Drive: AnsiChar): TStorageBusType;
var
  H: THandle;
  Query: TStoragePropertyQuery;
  dwBytesReturned: DWORD;
  Buffer: array [0..1023] of Byte;
  sdd: TStorageDeviceDescriptor absolute Buffer;
  OldMode: UINT;

begin
  Result := BusTypeUnknown;

  OldMode := SetErrorMode(SEM_FAILCRITICALERRORS);
  try
    H := CreateFile(PChar(Format('\\.\%s:', [AnsiLowerCase(String(Drive))])), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
      OPEN_EXISTING, 0, 0);
    if H <> INVALID_HANDLE_VALUE then
    begin
      try
        dwBytesReturned := 0;
        FillChar(Query, SizeOf(Query), 0);
        FillChar(Buffer, SizeOf(Buffer), 0);
        sdd.Size := SizeOf(Buffer);
        Query.PropertyId := StorageDeviceProperty;
        Query.QueryType := PropertyStandardQuery;
        if DeviceIoControl(H, IOCTL_STORAGE_QUERY_PROPERTY, @Query, SizeOf(Query), @Buffer, SizeOf(Buffer), dwBytesReturned, nil) then
          Result := sdd.BusType;
      finally
        CloseHandle(H);
      end;
    end;
  finally
    SetErrorMode(OldMode);
  end;
end;


end.
