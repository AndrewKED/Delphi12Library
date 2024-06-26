unit Net_Ops;

interface

uses WinSock, Classes;

function GetLocalIP: string;
function My_IP_Address : longint;
function LocalIP : String;
procedure GetWin32_NetworkAdapterConfigurationInfo(slResult : TStringList);
function IsValidIP4Address(ip : String) : Boolean;

implementation

uses
  System.Types,
  OverbyteICSWSocket, SysUtils, StrUtils,
  ActiveX,
  ComObj,
  Variants,
  Str_Ops;

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function LWToIP(LW: LongWord): string;
begin
  Result := IntToStr(LW and $FF);
  LW := LW shr 8;
  Result := Result + '.' + IntToStr(LW and $FF);
  LW := LW shr 8;
  Result := Result + '.' + IntToStr(LW and $FF);
  LW := LW shr 8;
  Result := Result + '.' + IntToStr(LW and $FF);
end;

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function GetLocalIP: string;
var
  sLocalHostName : string;
  sIPs : TStrings;

begin
  sLocalHostName := String(LocalhostName);

  sIPs := TStrings.Create;
  sIPs := LocalIPList; // GetIPAddresses(slIPs, LocalhostName);

  result := sIPs[0];
end;

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function My_IP_Address : longint;
var
  buf : array [0..255] of AnsiChar;
  RemoteHost : PHostEnt;

begin
  Winsock.GetHostName(@buf, 255);
  RemoteHost:=Winsock.GetHostByName(buf);
  if RemoteHost=NIL then
    My_IP_Address := winsock.htonl($07000001) { 127.0.0.1 }
  else
    My_IP_Address := longint(pointer(RemoteHost^.h_addr_list^)^);
  Result := Winsock.ntohl(Result);
end;

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//      CALLS       :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function LocalIP : String;
type
  TArrayPInAddr = array [0..10] of PInAddr;
  PArrayPInAddr = ^ TArrayPInAddr;
  var
  phe      : PHostEnt;
  pptr     : PArrayPInAddr;
  Buffer   : array [0..63] of AnsiChar;
  i        : integer;
//  GInitData: TWSADATA;

begin
// Should this be called by the calling program before any of the above
// routines work?
//  WSAStartup($101, GInitData);
  result := '';
  GetHostName(Buffer, sizeof(Buffer));
  phe := GetHostByName(Buffer);
  if phe=nil then
  begin
    exit
  end;
  pptr := PArrayPInAddr(phe^.h_addr_list);
  i := 0;
  while pptr^[i]<>nil do
  begin
    result := StrPas(inet_ntoa(pptr^[i]^));
    Inc(i);
  end;
// Should this be called by the calling program after complete with all
// of the above routines?
//  WSACleanup;
end;

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
  if (VarType(vArray) and VarArray)=0 then
    Result := Result + _VarToStr(vArray)
  else
    for i := VarArrayLowBound(vArray, 1) to VarArrayHighBound(vArray, 1) do
      if (i=VarArrayLowBound(vArray, 1)) then
        Result := Result + _VarToStr(vArray[i])
      else
        Result := Result + '|'+_VarToStr(vArray[i]);
end;

procedure GetWin32_NetworkAdapterConfigurationInfo(slResult : TStringList);
const
  WbemUser            ='';
  WbemPassword        ='';
  WbemComputer        ='localhost';
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator : OLEVariant;
  FWMIService   : OLEVariant;
  FWbemObjectSet: OLEVariant;
  FWbemObject   : OLEVariant;
  oEnum         : IEnumvariant;
  iValue        : LongWord;

begin;
  slResult.Clear;
  try
    CoInitialize(nil);
    try
      FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
      FWMIService   := FSWbemLocator.ConnectServer(WbemComputer, 'root\CIMV2', WbemUser, WbemPassword);
      FWbemObjectSet:= FWMIService.ExecQuery('SELECT * FROM Win32_NetworkAdapterConfiguration Where IpEnabled=True','WQL',wbemFlagForwardOnly);
      oEnum         := IUnknown(FWbemObjectSet._NewEnum) as IEnumVariant;
      while (oEnum.Next(1, FWbemObject, iValue) = 0) do
      begin
        slResult.Add(String(FWbemObject.Caption));// String

        if (not VarIsNull(FWbemObject.DHCPServer)) then
          slResult.Add(String(FWbemObject.DHCPServer))
        else
          slResult.Add('');

        if not VarIsNull(FWbemObject.IPAddress) then
          slResult.Add(VarArrayToStr(FWbemObject.IPAddress))// array String
        else
          slResult.Add('');

        if not VarIsNull(FWbemObject.IPSubnet) then
          slResult.Add(VarArrayToStr(FWbemObject.IPSubnet)) // array String
        else
          slResult.Add('');

        if not VarIsNull(FWbemObject.MACAddress) then
          slResult.Add(VarArrayToStr(FWbemObject.MACAddress)) // array String
        else
          slResult.Add('');

        FWbemObject:=Unassigned;
      end;
    finally
      CoUninitialize;
    end;
  except
  end; // try
end;

//***************************************************************************
//
//  FUNCTION  : IsValidIP4Address
//
//  I/P       : ip : String - The IP addres to be tested
//
//  O/P       : Boolean - TRUE if the IP address is valid.
//
//  OPERATION : Check whether the given string is a valid IP4 address
//
//  UPDATED   : 2021-10-11
//
//***************************************************************************
function IsValidIP4Address(ip : String) : Boolean;
var
  elements : TStringDynArray;
  n: Integer;

begin
  result := FALSE;
  elements := SplitString(ip, '.');
  if (Length(elements) = 4) then
  begin
    for n := 0 to 3 do
    begin
      if ((not IsAnInteger(elements[n])) or
          (StrToInt(elements[n]) < 0) or
          (StrToInt(elements[n]) > 255)) then
      begin
        exit;
      end;
    end;
  end;
  result := TRUE;
end;




end.
