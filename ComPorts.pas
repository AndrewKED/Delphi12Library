unit ComPorts;

//***************************************************************************
//
// DESCRIPTION:
//  Serial COM Port-orientated routines
//
// TO BE DONE:
//
//  *
//
// VERSIONS:
//    Update Date :
//    Changes Made :
//
//    Update Date : 2005/02/22
//    Changes Made :
//      * First Issue
//
//***************************************************************************

interface

uses
  Classes,
  Vcl.StdCtrls,
  DKLang, VaComm, AdPort;

procedure SetCOMSelection(iPort : integer;
                          var cbSelection : TComboBox);
procedure SetCOMPortUsage(vaPort : TVaComm;
                          var cbSelection : TComboBox); overload;
procedure SetCOMPortUsage(acpPort : TApdComPort;
                          var cbSelection : TComboBox); overload;
function ValidCOMText(theText : String;
                      otherInvalid : String = '') : Boolean;
procedure GetAvailableComPorts(bIncludeNone : boolean;
                               bIncludeCOM : boolean;
                               const COMPorts : TStringList);
function ValidCOMPort(iCOMNumber : integer) : boolean;
procedure SetLanguage(lcMain : TDKLanguageController);

implementation

uses Registry, Windows, SysUtils, System.StrUtils,
     Str_Ops;

var
  lcComPorts : TDKLanguageController;
  textNone : String;
  textUnavailable : String;

//***************************************************************************
//
//  FUNCTION  : SetCOMSelection
//
//  I/P       : iPort : integer - The COM port number to be selected
//
//  O/P       : var cbSelection : TComboBox - The TComboBox which holds the
//                list of available ports.
//
//  OPERATION : Given a COM port number and a TComboBox holding available COM
//              port names, select the entry that holds the indicated COM port.
//
//              Add the entry if it is not in the list.
//
//  UPDATED   : 2025-05-05
//
//***************************************************************************
procedure SetCOMSelection(iPort : integer;
                          var cbSelection : TComboBox);
var
  bFound : boolean;
  n : integer;

begin
  GetAvailableComPorts(TRUE,TRUE,TStringList(cbSelection.Items));

  if (iPort<>0) then
  begin
    bFound := FALSE;
    n := 1;
    while (n < cbSelection.Items.Count) do
    begin
      if ((IsAnInteger(Copy(cbSelection.Items[n],4,255))) and
          (iPort = StrToInt(Copy(cbSelection.Items[n],4,255)))) then
      begin
        cbSelection.ItemIndex := n;
        bFound := TRUE;
      end; // while
      Inc(n);
    end; // while

    // Handle the case where the assigned COM port was not found in the PC hardware
    if (not bFound) then
    begin
      cbSelection.Items.Add('COM' + IntToStr(iPort) +
                            ' (' + textUnavailable + ')');
      cbSelection.ItemIndex := cbSelection.Items.Count-1;
    end; // if
  end // if
  else
    cbSelection.ItemIndex := 0;
end; // SetCOMSelection

//***************************************************************************
//
//  FUNCTION  : SetCOMPortUsage
//
//  I/P       : acpPort : TVaComm - The COM port to be configured
//
//  O/P       : var cbSelection : TComboBox - The TComboBox which holds the
//                list of available ports.
//
//  OPERATION : Given a TVaComm and a TComboBox holding available COM port
//              names, select the entry that holds the indicated COM port.
//
//              Add the entry if it is not in the list.
//
//  UPDATED   : 2025-05-05
//
//***************************************************************************
procedure SetCOMPortUsage(vaPort : TVaComm;
                          var cbSelection : TComboBox); overload;
var
  found : Boolean;
  n : Integer;

begin
  if (vaPort.PortNum <> 0) then
  begin
    found := FALSE;
    n := 1;
    while (n < cbSelection.Items.Count) do
    begin
      if ((IsAnInteger(Copy(cbSelection.Items[n],4,255))) and
          (vaPort.PortNum = StrToInt(Copy(cbSelection.Items[n],4,255)))) then
      begin
        cbSelection.ItemIndex := n;
        found := TRUE;
      end; // while
      Inc(n);
    end; // while
    // Handle the case where the assigned COM port was not found in the PC hardware
    if (not found) then
    begin
      cbSelection.Items.Add('COM' + IntToStr(vaPort.PortNum) +
                            ' (' + textUnavailable + ')');
      cbSelection.ItemIndex := cbSelection.Items.Count-1;
    end; // if
  end // if
  else
  begin
    cbSelection.ItemIndex := 0;
  end;
end; // SetCOMPortUsage

//***************************************************************************
//
//  FUNCTION  : SetCOMPortUsage
//
//  I/P       : acpPort : TApdComPort - The COM port to be configured
//
//  O/P       : var cbSelection : TComboBox - The TComboBox which holds the
//                list of available ports.
//
//  OPERATION : Given a TApdComPort and a TComboBox holding available COM port
//              names, select the entry that holds the indicated COM port.
//
//              Add the entry if it is not in the list.
//
//  UPDATED   : 2025-05-05
//
//***************************************************************************
procedure SetCOMPortUsage(acpPort : TApdComPort;
                          var cbSelection : TComboBox); overload;
var
  found : Boolean;
  n : Integer;

begin
  if (acpPort.ComNumber <> 0) then
  begin
    found := FALSE;
    n := 1;
    while (n < cbSelection.Items.Count) do
    begin
      if ((IsAnInteger(Copy(cbSelection.Items[n],4,255))) and
          (acpPort.ComNumber = StrToInt(Copy(cbSelection.Items[n],4,255)))) then
      begin
        cbSelection.ItemIndex := n;
        found := TRUE;
      end; // while
      Inc(n);
    end; // while
    // Handle the case where the assigned COM port was not found in the PC hardware
    if (not found) then
    begin
      cbSelection.Items.Add('COM' + IntToStr(acpPort.ComNumber) +
                            ' (' + textUnavailable + ')');
      cbSelection.ItemIndex := cbSelection.Items.Count-1;
    end; // if
  end // if
  else
  begin
    cbSelection.ItemIndex := 0;
  end;
end; // SetCOMPortUsage


//***************************************************************************
//
//  FUNCTION  : ValidCOMText
//
//  I/P       : theText : String - The text, typically as found in a TComboBox
//                list (e.g. 'COM4')
//
//              otherInvalid : String = '' - A string that should not appear
//                e.g. '(Unavailable)' as may be found in 'COM4 (Unavailable)'
//
//  O/P       : Booleam
//
//  OPERATION : Check whether a COM port description might be invalid/unavailable
//
//  UPDATED   : 2022-01-20
//
//***************************************************************************
function ValidCOMText(theText : String;
                      otherInvalid : String = '') : Boolean;
begin
  result := (theText <> '') and
            (theText <> textNone) and
            ((otherInvalid = '') or
             (Pos(otherInvalid, theText) = 0));
end; // ValidCOMText

//***************************************************************************
//
//  FUNCTION    :   GetAvailableComPorts
//
//  I/P         :   bIncludeNone : Boolean - Adds in the entry 'None' at the
//                    top of the list.
//
//                  bIncludeCOM : Boolean - Includes the letters 'COM' in front
//                    of each numerical entry.
//
//  O/P         :   COMPorts : TStringList - The list of available COM
//                    ports on this machine.
//
//  OPERATION   :   Searches the registry key
//                      HKEY_LOCAL_MACHINE\Hardware\DeviceMap\SerialComm
//                      which lists the COM ports that are available on a PC.
//
//  UPDATED     :   2015-10-15
//
//***************************************************************************
procedure GetAvailableComPorts(bIncludeNone : boolean;
                               bIncludeCOM : boolean;
                               const COMPorts : TStringList);
var
  Reg: TRegistry;
  n : Integer;
  slValueNames : TStringList;

begin
  // Initially, there are no known COM ports
  COMPorts.Clear;
  Reg := TRegistry.Create;
  try
    slValueNames := TStringList.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      Reg.Access := KEY_READ;
      if (Reg.OpenKey('\Hardware\DeviceMap\SerialComm', FALSE)) then
      begin
        Reg.GetValueNames(slValueNames);
        // Scan through all the entries
        for n := 0 to slValueNames.Count-1 do
        begin
          if (LeftStr(Reg.ReadString(slValueNames[n]),3) = 'COM') then
          begin
            // Add the COM port to the list, removing the 'COM' string, if requested
            if (bIncludeCOM) then
              COMPorts.Add(Reg.ReadString(slValueNames[n]))
            else
              COMPorts.Add(Copy(Reg.ReadString(slValueNames[n]),4,255));
          end; // if
        end; // for
        SortTStrings(COMPorts);
        // Add an entry for 'None', if requested
        if (bIncludeNone) then
          COMPorts.Insert(0, textNone);
      end // if
      else
        // Add an entry for 'None', if requested
        if (bIncludeNone) then
          COMPorts.Insert(0, textNone);
      Reg.CloseKey;
    finally
      slValueNames.Free;
    end; // finally
  finally
    Reg.Free;
  end; // finally
end; // GetAvailableComPorts

//***************************************************************************
//
//  FUNCTION    :   ValidCOMPort
//
//  I/P         :   iComNumber (integer) - The COM number to be checked
//
//  O/P         :   (boolean) - TRUE if the given port number is available
//                        on this PC.
//
//  OPERATION   :   Checks whether the given COM port number is available
//                      on this PC.
//
//  UPDATED     :   2005/12/20
//
//***************************************************************************
function ValidCOMPort(iCOMNumber : integer) : boolean;
var
  slAvailablePorts : TStringList;
  n : Integer;

begin
  slAvailablePorts := TStringList.Create;
  try
    GetAvailableComPorts(FALSE,FALSE,slAvailablePorts);
    n := 0;
    result := FALSE;
    // Scan through all the available COM ports.
    while (n < slAvailablePorts.Count) do
    begin
      if (StrToInt(slAvailablePorts[n]) = iCOMNumber) then
        result := TRUE;
      Inc(n);
    end; // while
  finally
    slAvailablePorts.Free;
  end; // finally
end; // ValidCOMPort

//***************************************************************************
//
//  FUNCTION  : SetLanguage
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/02/23
//
//***************************************************************************
procedure SetLanguage(lcMain : TDKLanguageController);
begin
  lcComPorts := lcMain;
  if (lcMain <> nil) then
    try
      textNone := LangManager.ConstantValue['sNone'];
      textUnavailable := LangManager.ConstantValue['sUnavailable'];
    except
    end; // except
end;

//***************************************************************************
//
//  FUNCTION  : initialization
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
initialization
begin
  lcComPorts := nil;

  // Defaults, in case SetLanguage does not get called
  textNone := 'None';
  textUnavailable := 'Unavailable';
end; // initialization

end.
