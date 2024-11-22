unit CR95HF_Ops;

interface

uses
  System.SysUtils;

const
  CR95HF_SERIAL_DLL = 'CR95HFs.dll';
  CR95HF_USB_DLL = 'CR95HF.dll';

type
  TCR95HFDLLReply = function(stringReply : array of Byte) : Integer; stdcall;
  TCR95HFDLLNoParameters = function : Integer; stdcall;
  TCR95HFDLLCmd = function(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall;

procedure SetCR95HFSerialInterface(port : Integer);

// USB DLL Functions
//------------------------------------------------------------------------------
function CR95HFDll_Echo(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;

function CR95HFDll_Idn(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDll_Select(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDll_SendReceive(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDll_STCmd(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDll_FieldOff(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;

function CR95HFDll_ResetSPI(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDLL_getHardwareVersion(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDLL_getMCUrev(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;

function CR95HFDll_GetDLLrev(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDLL_USBconnect : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDLL_USBhandlecheck : Integer; stdcall; external CR95HF_USB_DLL;

// function CR95HFDLL_getInterfacePinState(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;

function CR95HFDll_GpsOn(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDll_GpsOff(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDll_GetGps(stringReply : array of Byte) : Integer; stdcall; external CR95HF_USB_DLL;

function CR95HFDLL_USBinit() : Integer; stdcall; external CR95HF_USB_DLL;
function CR95HFDLL_USBfinal() : Integer; stdcall; external CR95HF_USB_DLL;

// Serial interface DLL Functions
//------------------------------------------------------------------------------
function CR95HFSDll_Echo(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;

function CR95HFSDll_Idn(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDll_Select(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDll_SendReceive(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDll_STCmd(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDll_FieldOff(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;

function CR95HFSDll_ResetSPI(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDLL_getHardwareVersion(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDLL_getMCUrev(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;

function CR95HFSDll_GetDLLrev(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDLL_USBhandlecheck : Integer; stdcall; external CR95HF_SERIAL_DLL;
//function CR95HFSDLL_CheckConnection : Integer; stdcall; external CR95HF_SERIAL_DLL;

//function CR95HFSDLL_getInterfacePinState(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;

function CR95HFSDll_GpsOn(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDll_GpsOff(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDll_GetGps(stringReply : array of Byte) : Integer; stdcall; external CR95HF_SERIAL_DLL;

function CR95HFSDLL_USBinit(comport : Integer) : Integer; stdcall; external CR95HF_SERIAL_DLL;
function CR95HFSDLL_USBfinal() : Integer; stdcall; external CR95HF_SERIAL_DLL;

var
  cr95HFSerialInterface : Boolean;
  cr95HFComPort : Integer;

  CR95HF_Echo : TCR95HFDLLReply;
  CR95HF_Idn : TCR95HFDLLReply;
  CR95HF_Select : TCR95HFDLLCmd;
  CR95HF_SendReceive : TCR95HFDLLCmd;
  CR95HF_STCmd : TCR95HFDLLCmd;
  CR95HF_FieldOff : TCR95HFDLLReply;
  CR95HF_ResetSPI : TCR95HFDLLReply;
  CR95HF_getHardwareVersion : TCR95HFDLLReply;
  CR95HF_getMCUrev : TCR95HFDLLReply;
  CR95HF_GetDLLrev : TCR95HFDLLReply;
  CR95HF_USBhandlecheck : TCR95HFDLLNoParameters;
  CR95HF_getInterfacePinState : TCR95HFDLLReply;
  CR95HF_GpsOn : TCR95HFDLLReply;
  CR95HF_GpsOff : TCR95HFDLLReply;
  CR95HF_GetGps : TCR95HFDLLReply;
  CR95HF_Close : TCR95HFDLLNoParameters;
//  CR95HF_Init : the serial and USB versions have differing parameters, so must be handled at a different level.
  CR95HF_Final : TCR95HFDLLNoParameters;

implementation

//***************************************************************************
//
//  FUNCTION  : SetCR95HFSerialInterface
//
//  I/P       : port : Integer - The COM port to be used for a serial interface.
//                If 0, a USB interface will be used.
//
//  O/P       : None
//
//  OPERATION : Set the DLL routines to be used, based on the chosen interface.
//
//  UPDATED   : 2024-01-16
//
//***************************************************************************
procedure SetCR95HFSerialInterface(port : Integer);
begin
  cr95HFComPort := port;
  cr95HFSerialInterface := (cr95HFComPort <> 0);

  if (cr95HFSerialInterface) then
  begin
    // Serial Interface
    CR95HF_Echo := CR95HFSDll_Echo;
    CR95HF_Idn := CR95HFSDll_Idn;
    CR95HF_Select := CR95HFSDll_Select;
    CR95HF_SendReceive := CR95HFSDll_SendReceive;
    CR95HF_STCmd := CR95HFSDll_STCmd;
    CR95HF_FieldOff := CR95HFSDll_FieldOff;
    CR95HF_ResetSPI := CR95HFSDll_ResetSPI;
    CR95HF_getHardwareVersion := CR95HFSDLL_getHardwareVersion;
    CR95HF_getMCUrev := CR95HFSDLL_getMCUrev;
    CR95HF_GetDLLrev := CR95HFSDll_GetDLLrev;
    CR95HF_USBhandlecheck := CR95HFSDLL_USBhandlecheck;
//    CR95HF_USBhandlecheck := CR95HFSDLL_CheckConnection;
//    CR95HF_getInterfacePinState := CR95HFSDLL_getInterfacePinState;
    CR95HF_GpsOn := CR95HFSDll_GpsOn;
    CR95HF_GpsOff := CR95HFSDll_GpsOff;
    CR95HF_GetGps := CR95HFSDll_GetGps;
//    CR95HF_Close := nil;    // Nothing to be shut down
  end // if
  else
  begin
    // USB Interface
    CR95HF_Echo := CR95HFDll_Echo;
    CR95HF_Idn := CR95HFDll_Idn;
    CR95HF_Select := CR95HFDll_Select;
    CR95HF_SendReceive := CR95HFDll_SendReceive;
    CR95HF_STCmd := CR95HFDll_STCmd;
    CR95HF_FieldOff := CR95HFDll_FieldOff;
    CR95HF_ResetSPI := CR95HFDll_ResetSPI;
    CR95HF_getHardwareVersion := CR95HFDLL_getHardwareVersion;
    CR95HF_getMCUrev := CR95HFDLL_getMCUrev;
    CR95HF_GetDLLrev := CR95HFDll_GetDLLrev;
    CR95HF_USBhandlecheck := CR95HFDLL_USBhandlecheck;
//    CR95HF_getInterfacePinState := CR95HFDLL_getInterfacePinState;
    CR95HF_GpsOn := CR95HFDll_GpsOn;
    CR95HF_GpsOff := CR95HFDll_GpsOff;
    CR95HF_GetGps := CR95HFDll_GetGps;
    CR95HF_Close := CR95HFDLL_USBfinal;
  end;
end;

initialization
  // Default to using the USB interface
  SetCR95HFSerialInterface(0);

end.
