unit Message_Ops;

interface
procedure SendMsgString(sStringToSend : string);

implementation

// Refer to
// http://delphi.about.com/od/windowsshellapi/a/wm_copydata.htm

uses
  System;

type
 TCopyDataStruct = packed record
 dwData: DWORD; //up to 32 bits of data to be passed to the receiving application
 cbData: DWORD; //the size, in bytes, of the data pointed to by the lpData member
 lpData: Pointer; //Points to data to be passed to the receiving application. This member can be nil.
 end;

//***************************************************************************
//
//  FUNCTION  : SendMessageData
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
procedure SendMessageData(const copyDataStruct: TCopyDataStruct;
                          sRxMainForm : string;
                          sRxCaption : string);
var
  hReceiver : THandle;
  res : integer;

begin
  hReceiver := FindWindow(PChar(sRxMainForm),PChar(sRxCaption)) ;
  if (hReceiver = 0) then
  begin
    ShowMessage('CopyData Receiver NOT found!') ;
    Exit;
  end;

  res := SendMessage(hReceiver, WM_COPYDATA, Integer(Handle), Integer(@copyDataStruct)) ;
 end;

//***************************************************************************
//
//  FUNCTION  : SendMsgString
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
procedure SendMsgString(sStringToSend : string);
var
  copyDataStruct : TCopyDataStruct;

begin
  copyDataStruct.dwData := 0; //use it to identify the message contents
  copyDataStruct.cbData := 1 + Length(sStringToSend);
  copyDataStruct.lpData := PChar(sStringToSend);

  SendMessageData(copyDataStruct);
end;

end.
