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

uses Classes, DKLang;

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
  sNone : String;

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
            (theText <> sNone) and
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
          COMPorts.Insert(0,sNone);
      end // if
      else
        // Add an entry for 'None', if requested
        if (bIncludeNone) then
          COMPorts.Insert(0,sNone);
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
      sNone := LangManager.ConstantValue['sNone'];
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
  sNone := 'None';
end; // initialization

end.
