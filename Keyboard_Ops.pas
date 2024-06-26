unit Keyboard_Ops;

interface

procedure ClearKeyBoardBuffer(Handle:THandle);

implementation

uses WinTypes, Messages;

//***************************************************************************
//
//  FUNCTION  : ClearKeyBoardBuffer
//
//  I/P       : Handle:THandle
//
//  O/P       :
//
//  OPERATION : from
//              https://www.experts-exchange.com/questions/12027199/Empty-or-Clear-KeyBoard-Buffer.html
//
//  UPDATED   : 2016-10-03
//
//***************************************************************************
procedure ClearKeyBoardBuffer(Handle:THandle);
var
  MyMgs : TMsg;

begin
  while PeekMessage(MyMgs,Handle,WM_KEYFIRST,WM_KEYLAST,PM_REMOVE) do ;
end; // ClearKeyBoardBuffer

end.
