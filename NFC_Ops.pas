unit NFC_Ops;

interface

uses
  System.SysUtils, Vcl.StdCtrls;

const
  NFC_BUFF_SIZE = 256;

  GCRCU_INTERFACE_DLL = 'CR95HF.dll';

type
  TNFCBuffer = packed array[0..NFC_BUFF_SIZE-1] of Byte;

// DLL Functions
function CR95HFDll_Echo(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;

function CR95HFDll_Idn(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDll_Select(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDll_SendReceive(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDll_STCmd(stringCmd : TBytes; stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDll_FieldOff(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;

function CR95HFDll_ResetSPI(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDLL_getHardwareVersion(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDLL_getMCUrev(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;

function CR95HFDll_GetDLLrev(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDLL_USBconnect : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDLL_USBhandlecheck : Integer; stdcall; external GCRCU_INTERFACE_DLL;

//function CR95HFDll_SendIRQPulse(stringReply : array of Byte) : Integer; stdcall; external 'CR95HF.dll';
function CR95HFDLL_getInterfacePinState(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
//function CR95HFDll_Polling_Reading(stringReply : array of Byte) : Integer; stdcall; external 'CR95HF.dll';
//function CR95HFDll_SendNSSPulse(stringReply : array of Byte) : Integer; stdcall; external 'CR95HF.dll';

function CR95HFDll_GpsOn(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDll_GpsOff(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;
function CR95HFDll_GetGps(stringReply : array of Byte) : Integer; stdcall; external GCRCU_INTERFACE_DLL;

function CR95HFDLL_USBfinal() : Integer; stdcall; external GCRCU_INTERFACE_DLL;

procedure SetNFCDebug(debugToUse : TCustomMemo);
procedure AddNFCDebug(line : String);
function ISO14443A_Initiate : Boolean;
function ISO14443A_AntiCollision : Boolean;
function ISO14443A_RATS : Boolean;
function NFCFieldOff : Boolean;
procedure InitNFC;
function NFC_SelectNDEFTagApplication : Boolean;
function NFC_SelectCapabilityContainerFile : Boolean;
function NFC_SelectSystemFile : Boolean;
function NFC_SelectNDEFFile : Boolean;
function NFC_ReadFile : Boolean;
function NFC_WriteFile(hexData : AnsiString) : Boolean;
function NFC_StateControl(state : Boolean) : Boolean;
function NFC_GetError : String;
procedure StartLogging(idDebug : Integer);
procedure StopLogging;

var
  ndefFileContents : TBytes;

implementation

uses
  Vcl.ComCtrls,
  Block_Ops, Debug_Ops;

const
// PCB (Process Control Block)
  PCB_BLOCK_MASK              = $C0;  // Used to extract the block type bits
  PCB_ID_I                    = $00;
  PCB_RFU_I                   = $02;  // Reserved for future use in Block I
  PCB_ID_R                    = $80;
  PCB_RFU_R                   = $22;  // Table 18 implies 0x22 while Table 19 implies 0x20!! Reserved for future use in Block R
  PCB_ID_S                    = $C0;
  PCB_RFU_S                   = $02;  // Reserved for future use in Block S
  PCB_DID                     = $08;  // Used in I-, R- and S-blocks
  IR_PCB_BLOCK_NUMBER_MASK    = $01;  // Used to extract the Block number bit in I- and R-block replies

  R_PCB_ACK_MASK              = $10;  // Used to extract the ACK bit
  R_PCB_ACK                   = $00;  // Used in R-block : the acknowledgement block sent by the RF or I�C host or by the M24SR02-Y
  R_PCB_NACK                  = $10;  // Used in R-block : the non-acknowledgement block sent by the RF or I�C host or by the M24SR02-Y

  S_PCB_DESELECT              = $00;  // Used in S-block : Deselect command
  S_PCB_WTX                   = $30;  // Used in S-block : Waiting Frame Extension command or response

  FI_CC                       = 0;
  FI_SYSTEM                   = 1;
  FI_NDEF                     = 2;

// C-APDU (Command Application Protocol Data Unit) CLA (Class) byte
  CLA_STANDARD                = $00;
  CLA_ST_CMD                  = $A2;

// C-APDU INS (Instruction) byte
// NFC Forum Type 4 Tag (Class = 0x00)
  INS_SELECT                  = $A4;  // Select the NDEF Tag application, CC-, NDEF- or system-file
  INS_READ_BINARY             = $B0;  // Read data from file
  INS_WRITE_BINARY            = $D6;  // Write or erase data to a NDEF file
// ISO/IEC 7816-4 (Class = 0x00)
  INS_VERIFY                  = $20;  // Checks the right access of a NDEF file or sends a password
  INS_CHANGE_REF_DATA         = $24;  // Change a Read or write password
  INS_ENABLE_VERIFICATION_RQ  = $28;  // Activate the password security
  INS_DISABLE_VERIFICATION_RQ = $26;  // Disable the password security
// ST Proprietary (Class = 0xA2)
  INS_ENABLE_PERMANENT_STATE  = $28;  // Enables the Read Only or Write Only security state
  INS_EXTENDED_READ_BINARY    = $B0;  // Read data from file
// I2C Commands
  INS_I2C_GET_I2C_SESSION     = $26;  // Open an I�C session when the RF session is not ongoing
  INS_I2C_KILL_RF_SESSION     = $52;  // Kill the RF session and open an I�C session

  ID_PWD_READ_NDEF            = $0001;  // Read access to NDEF file
  ID_PWD_WRITE_NDEF           = $0002;  // Write access to NDEF file
  ID_PWD_I2C_SUPERUSER        = $0003;  // I2C super-user rights

  RX_STAT_OK                  = $9000;  // Command completed successfully
  RX_STAT_FILE_OVERFLOW_LE    = $6280;  // File overflow (Le error)
  RX_STAT_EOF_ERR             = $6282;  // End of file or record reached before reading Le bytes
  RX_STAT_PWD_RQD             = $6300;  // Password is required
  RX_STAT_PWD_ERR_0           = $63C0;  // Password is incorrect (no more retries allowed)
  RX_STAT_PWD_ERR_1           = $63C1;  // Password is incorrect (1 retry allowed)
  RX_STAT_PWD_ERR_2           = $63C2;  // Password is incorrect (2 retries allowed)
  RX_STAT_UPDATE_ERR          = $6581;  // Unsuccessful updating
  RX_STAT_LENGTH_ERR          = $6700;  // Wrong length
  RX_STAT_CMD_INCOMPATIBLE    = $6981;  // Cmd is incompatible with the file structure
  RX_STAT_SECURITY_ERR        = $6982;  // Security status not satisfied
  RX_STAT_REF_DATA_ERR        = $6984;  // Reference data not usable
  RX_STAT_PARAM_ERR           = $6A80;  // Incorrect parameters Le or Lc
  RX_STAT_FILE_APP_NOT_FOUND  = $6A82;  // File or application not found
  RX_STAT_FILE_OVERFLOW_LC    = $6A84;  // File overflow (Lc error)
  RX_STAT_P1P2_ERR            = $6A86;  // Incorrect P1 or P2 values
  RX_STAT_INS_FIELD_UNSUPP    = $6D00;  // INS field not supported
  RX_STAT_CLASS_UNSUPP        = $6E00;  // Class not supported


  SIZE_MAX_NFC_COMMS_PACKET   = 254;     // Whye does M24SR02-Y say "Read up to 246 bytes in a single command" ? !!
  NDEF_PACKET_OVERHEAD        = 4;       // 4 additional bytes at the start of the NDEF record

var
  uid : array[0..7] of AnsiString;    // UID of the tag
  lastCommandPCB : Byte;
  blockNumber : Byte;
  errorMsgNFC : String;
  idxLogFile : Integer;

  debugMonitor : TCustomMemo;

	cmdResponse : TNFCBuffer;

//{$DEFINE DEBUG_LOTS}

//***************************************************************************
//
//  FUNCTION  : SetGCRCUDebug
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2021-08-25
//
//***************************************************************************
procedure SetNFCDebug(debugToUse : TCustomMemo);
begin
  debugMonitor := nil;
  if ((debugToUse is TMemo) or
      (debugToUse is TRichEdit)) then
  begin
    debugMonitor := TCustomMemo(debugToUse);
  end;
end; // SetGCRCUDebug

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
procedure ClearNFCDebug;
begin
  if (debugMonitor <> nil) then
  begin
    TCustomMemo(debugMonitor).Lines.Clear;
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
//  OPERATION :
//
//  UPDATED   :
//
//***************************************************************************
procedure AddNFCDebug(line : String);
begin
  if (debugMonitor <> nil) then
  begin
    TCustomMemo(debugMonitor).Lines.Add(FormatDateTime('hh:nn:ss.zzz',Now) + ',' + line);
  end;

  if (idxLogFile <> -1) then
  begin
    DebugLog(idxLogFile, line, FALSE);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : SendToTag
//
//  I/P       : tagCommand : array of Byte - A null-terminated array of ASCII
//                hexadecimal pairs, representing the command to send to the tag.
//
//  O/P       : Boolean - TRUE if the command executed correctly
//
//  OPERATION : Send the given command, and provide the answer in the global
//              array.
//
//  UPDATED   : 2021-09-28
//
//***************************************************************************
function SendToTag(command : TBytes) : Boolean;
var
  response : TNFCBuffer;
  iresult : Integer;
  lenAnswer : Integer;
  i : Integer;

begin
  result := FALSE;
  try
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('Send to tag,Tx,' + TBytes2HexString(tagCommand));
{$ENDIF}
    iresult := CR95HFDll_SendReceive(command, response);
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('Send to tag,Response,' + IntToStr(iresult));
{$ENDIF}
//    AddNFCDebug('Send to tag,Rx,' + TBytes2HexString(reply));

    // Somewhere I picked up that the answer could start with '80' or '90'.
    // Note that this is a wrapper of the actual response from the M24SR02-Y,
    // which generally shows all "good" answers starting with '9000'
    // This is burried within the DLL's reply.

    if ((iresult <> 4) and
        (iresult <> 5) and
        ((Copy(AByte0ToAnsiString(response), 1, 2) = '80') or
         (Copy(AByte0ToAnsiString(response), 1, 2) = '90'))) then
    begin
      if (Copy(AByte0ToAnsiString(response), 3, 2) <> '') then
      begin
        lenAnswer := StrToInt('$' + Copy(String(AByte0ToAnsiString(response)), 3, 2));
        i := 0;
        while ((i < lenAnswer) and
               (Copy(AByte0ToAnsiString(response), 5 + i*2, 2) <> '')) do
        begin
          cmdResponse[i] := StrToInt('$' + Copy(String(AByte0ToAnsiString(response)), 5 + i*2, 2));
          Inc(i);
        end;
{$IFDEF DEBUG_LOTS}
        AddNFCDebug('Send to tag,Length of reply = ' + IntToStr(lenAnswer));
{$ENDIF}
        // A reply of some length is expected, and it should all be processed.
        result := ((lenAnswer > 0) and (i = lenAnswer));
      end // if
    end; // if

  //80, 08, 02, 90, 00, F1, 09, 08, 00, 00,


  // #0, 'A', '6', '9', '0', '8', '0', '0', '0', '0'
  except
    on E:Exception do
    begin
      errorMsgNFC := 'CR95HFDll_SendReceive (' + E.Message + ')';
      result := FALSE;
    end; // on
  end;
end; // SendToTag

//***************************************************************************
//
//  FUNCTION  : InitiateIS14443A
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the ISO14443A interface was correctly initialised.
//
//  OPERATION :
//
//              ST support says "0280 parameters are best configuration
//              for CR95HF demo board and ISO14443-A.
//
//  UPDATED   : 2021-09-08
//
//***************************************************************************
function ISO14443A_Initiate : Boolean;
var
  reply : TNFCBuffer;
  iresult : Integer;

begin
  result := FALSE;
  try
    // Set ISO14443A Protocol
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('ISO14443A Init,Tx,02000280');
{$ENDIF}
    iresult := CR95HFDll_Select(StringToTBytes0('02000280'), reply);
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('ISO14443A Init,Response,' + IntToStr(iresult));
    AddNFCDebug('ISO14443A Init,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}

    if (iresult = 0) then
    begin
      // Optomise ISO14443A
{$IFDEF DEBUG_LOTS}
      AddNFCDebug('ISO14443A Init,Tx,0109043A005804');
{$ENDIF}
      iresult := CR95HFDll_STCmd(StringToTBytes0('0109043A005804'), reply);
{$IFDEF DEBUG_LOTS}
      AddNFCDebug('ISO14443A Init,Response,' + IntToStr(iresult));
      AddNFCDebug('ISO14443A Init,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}
    end;

    if (iresult = 0) then
    begin
      // Modify Index And Rx Gain
{$IFDEF DEBUG_LOTS}
      AddNFCDebug('ISO14443A Init,Tx,010904680101D3');
{$ENDIF}
      iresult := CR95HFDll_STCmd(StringToTBytes0('010904680101D3'), reply);
{$IFDEF DEBUG_LOTS}
      AddNFCDebug('ISO14443A Init,Response,' + IntToStr(iresult));
      AddNFCDebug('ISO14443A Init,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}
    end;

    result := (iresult = 0);
  except
    on E:Exception do
      errorMsgNFC := 'ISO14443A_Initiate (' + E.Message + ')';
  end;
end; // InitiateIS14443A

//***************************************************************************
//
//  FUNCTION  : ISO14443A_AntiCollision
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the tag was correctly selected
//
//  OPERATION : Performs anti-collision and tag selection.
//
//  UPDATED   : 2018-10-15
//
//***************************************************************************
function ISO14443A_AntiCollision : Boolean;
var
  reply : TNFCBuffer;
  iresult : Integer;
  bcc : AnsiString;

begin
  // REQ-A
  try
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('ISO14443A AntiCollision,Tx,2607');
{$ENDIF}
    iresult := CR95HFDll_SendReceive(StringToTBytes0('2607'), reply);
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('ISO14443A AntiCollision,Response,' + IntToStr(iresult));
    AddNFCDebug('ISO14443A AntiCollision,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}
    if ((iresult <> 4) and
        (iresult <> 5) and
        ((Copy(AByte0ToAnsiString(reply), 1, 2) = '80') or
         (Copy(AByte0ToAnsiString(reply), 1, 2) = '90'))) then
    begin

      // Anticollision 1
      try
{$IFDEF DEBUG_LOTS}
        AddNFCDebug('ISO14443A AntiCollision,Tx,932008');
{$ENDIF}
        iresult := CR95HFDll_SendReceive(StringToTBytes0('932008'), reply);
{$IFDEF DEBUG_LOTS}
        AddNFCDebug('ISO14443A AntiCollision,Response,' + IntToStr(iresult));
        AddNFCDebug('ISO14443A AntiCollision,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}
        if ((iresult <> 4) and
            (iresult <> 5) and
            ((Copy(AByte0ToAnsiString(reply), 1, 2) = '80') or
             (Copy(AByte0ToAnsiString(reply), 1, 2) = '90')) and
            (Copy(AByte0ToAnsiString(reply), 3, 2) = '08') and      // Length
            (Copy(AByte0ToAnsiString(reply), 5, 2) = '88')) then
        begin
          uid[0] := Copy(AByte0ToAnsiString(reply), 7, 2);
          uid[1] := Copy(AByte0ToAnsiString(reply), 9, 2);
          uid[2] := Copy(AByte0ToAnsiString(reply), 11, 2);
          bcc := Copy(AByte0ToAnsiString(reply), 13, 2);
          if (StrToInt('$' + bcc) =
              (StrToInt('$88') xor StrToInt('$' + uid[0]) xor StrToInt('$' + uid[1]) xor StrToInt('$' + uid[2]))) then
          begin

            // Select 1
            try
{$IFDEF DEBUG_LOTS}
              AddNFCDebug('ISO14443A AntiCollision,Tx,937088' + uid[0] + uid[1] + uid[2] + bcc + '28');
{$ENDIF}
              iresult := CR95HFDll_SendReceive(StringToTBytes0('937088' + uid[0] + uid[1] + uid[2] + bcc + '28'), reply);
{$IFDEF DEBUG_LOTS}
              AddNFCDebug('ISO14443A AntiCollision,Response,' + IntToStr(iresult));
              AddNFCDebug('ISO14443A AntiCollision,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}
              if ((iresult <> 4) and
                  (iresult <> 5) and
                  ((Copy(AByte0ToAnsiString(reply), 1, 2) = '80') or
                   (Copy(AByte0ToAnsiString(reply), 1, 2) = '90')) and
                  (Copy(AByte0ToAnsiString(reply), 5, 2) = '04')) then
              begin

                // Anticollision 2
                try
{$IFDEF DEBUG_LOTS}
                  AddNFCDebug('ISO14443A AntiCollision,Tx,952008');
{$ENDIF}
                  iresult := CR95HFDll_SendReceive(StringToTBytes0('952008'), reply);
{$IFDEF DEBUG_LOTS}
                  AddNFCDebug('ISO14443A AntiCollision,Response,' + IntToStr(iresult));
                  AddNFCDebug('ISO14443A AntiCollision,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}
                  if ((iresult <> 4) and
                      (iresult <> 5) and
                      ((Copy(AByte0ToAnsiString(reply), 1, 2) = '80') or
                       (Copy(AByte0ToAnsiString(reply), 1, 2) = '90')) and
                      (Copy(AByte0ToAnsiString(reply), 3, 2) = '08')) then     // Length
                  begin
                    uid[3] := Copy(AByte0ToAnsiString(reply), 5, 2);
                    uid[4] := Copy(AByte0ToAnsiString(reply), 7, 2);
                    uid[5] := Copy(AByte0ToAnsiString(reply), 9, 2);
                    uid[6] := Copy(AByte0ToAnsiString(reply), 11, 2);
                    bcc := Copy(AByte0ToAnsiString(reply), 13, 2);
                    if (StrToInt('$' + bcc) =
                        (StrToInt('$' + uid[3]) xor StrToInt('$' + uid[4]) xor StrToInt('$' + uid[5]) xor StrToInt('$' + uid[6]))) then
                    begin

                      // Select 2
                      try
{$IFDEF DEBUG_LOTS}
                        AddNFCDebug('ISO14443A AntiCollision,Tx,9570' + uid[3] + uid[4] + uid[5] + uid[6] + bcc + '28');
{$ENDIF}
                        iresult := CR95HFDll_SendReceive(StringToTBytes0('9570' + uid[3] + uid[4] + uid[5] + uid[6] + bcc + '28'), reply);
{$IFDEF DEBUG_LOTS}
                        AddNFCDebug('ISO14443A AntiCollision,Response,' + IntToStr(iresult));
                        AddNFCDebug('ISO14443A AntiCollision,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}
                        if ((iresult <> 4) and
                            (iresult <> 5) and
                            ((Copy(AByte0ToAnsiString(reply), 1, 2) = '80') or
                             (Copy(AByte0ToAnsiString(reply), 1, 2) = '90')) and
                            (Copy(AByte0ToAnsiString(reply), 5, 2) = '20')) then
                        begin
                          result := TRUE;
                        end // if
                        else
                        begin
                          result := FALSE;
                        end; // else
                      except
                        on E:Exception do
                        begin
                          errorMsgNFC := 'Select 2 (' + E.Message + ')';
                          result := FALSE;
                        end; // on
                      end;
                    end // if
                    else
                    begin
                      result := FALSE;
                    end;
                  end // if
                  else
                  begin
                    result := FALSE;
                  end;
                except
                  on E:Exception do
                  begin
                    errorMsgNFC := 'Anticollision 2 (' + E.Message + ')';
                    result := FALSE;
                  end; // on
                end;
              end // if
              else
              begin
                result := FALSE;
              end;
            except
              on E:Exception do
              begin
                errorMsgNFC := 'Select 1 (' + E.Message + ')';
                result := FALSE;
              end; // on
            end;
          end // if
          else
          begin
            result := FALSE;
          end;
        end // if
        else
        begin
          result := FALSE;
        end;
      except
        on E:Exception do
        begin
          errorMsgNFC := 'Anticollision 1 (' + E.Message + ')';
          result := FALSE;
        end; // on
      end;
    end // if
    else
    begin
      result := FALSE;
    end;
  except
    on E:Exception do
    begin
      errorMsgNFC := 'REQ-A (' + E.Message + ')';
      result := FALSE;
    end;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : ISO14443A_RATS
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the command executes correctly
//
//  OPERATION :
//
//  UPDATED   : 2018-10-15
//
//***************************************************************************
function ISO14443A_RATS : Boolean;
var
  reply : TNFCBuffer;
  iresult : Integer;

begin
  try
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('ISO14443A RATS,Tx,E08028');
{$ENDIF}
    iresult := CR95HFDll_SendReceive(StringToTBytes0('E08028'), reply);
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('ISO14443A RATS,Response,' + IntToStr(iresult));
    AddNFCDebug('ISO14443A RATS,Rx,' + ABytes0ToAnsiString(reply));
{$ENDIF}

    result := ((iresult <> 4) and
               (iresult <> 5) and
               ((Copy(AByte0ToAnsiString(reply), 1, 2) = '80') or
                (Copy(AByte0ToAnsiString(reply), 1, 2) = '90')));
  except
    on E:Exception do
    begin
      errorMsgNFC := 'RATS (' + E.Message + ')';
      result := FALSE;
    end; // on
  end;
end; // ISO14443A_RATS

//***************************************************************************
//
//  FUNCTION  : NFCFieldOff
//
//  I/P       : reply : PAnsiChar -
//
//  O/P       : Integer - 0 if the command was executed correctly
//
//  OPERATION :
//
//  UPDATED   : 2021-03-19
//
//***************************************************************************
function NFCFieldOff : Boolean;
var
  reply : TNFCBuffer;
  iresult : Integer;

begin
  try
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('Turning off NFC field');
{$ENDIF}
    iresult := CR95HFDll_FieldOff(reply);
{$IFDEF DEBUG_LOTS}
    AddNFCDebug('NFC field off,Response,' + IntToStr(iresult));
    AddNFCDebug('NFC field off,Rx,' + AByte0ToAnsiString(reply));
{$ENDIF}

//iresult := CR95HFDll_FieldOff(reply);
//is giving a compile error, since the defintion of CR95HFDll_FieldOff expects a TBytes parameter.

    result := ((iresult = 0) and
               (AByte0ToAnsiString(reply) = '0000'));

    if (result) then
      AddNFCDebug('NFC field off successful')
    else
      AddNFCDebug('NFC field off failure')

  except
    on E:Exception do
    begin
      errorMsgNFC := 'FieldOff (' + E.Message + ')';
      result := FALSE;
    end; // on
  end;
end; // NFCFieldOff

//***************************************************************************
//
//  FUNCTION  : InitNFC
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION :
//  These notes obtained from datasheet for ST25TA512 :
//  Block numbering rules follow ISO 14443_4
//  Reader rules:
//    Rule A: The Reader block number shall be initialized to 0.
//    Rule B: When an I-block or an R(ACK) block with a block number equal to
//      the current block number is received, the Reader shall toggle the
//      current block number before optionally sending a block to the NFC device.
//  NFC device rules:
//    Rule C: The NFC device block number shall be initialized to 1 at activation.
//    Rule D: When an I-block is received, the NFC device shall toggle its block
//      number before sending a block.
//      Note: The NFC device may check if the received block number is not in
//        compliance with Reader rules to decide neither to toggle its internal block
//        number nor to send a response block.
//    Rule E: When an R(ACK) block with a block number not equal to the current
//      NFC device block number is received, the NFC device shall toggle
//      its block number before sending a block.
//      Note: There is no block number toggling when an R(NAK) block is received.
//
//  UPDATED   : 2018-10-15
//
//***************************************************************************
procedure InitNFC;
begin
  // See ISO 14443_4 rules above
  blockNumber := 0;
  errorMsgNFC := '';
end;

//*****************************************************************************
//
// FUNCTION   : SendCommand
//
// I/P        : PCB : Byte - Process Control Block
//
//              command : array of Byte - The command to send
//
// O/P        : Boolean - TRUE if the command executed correctly
//
//  OPERATION : Send a given command to the M24SR02 device (I-, R- or S-block format)
//
//  UPDATED   : 2021-01-27
//
//*****************************************************************************
function SendCommand(PCB : Byte;
                     command : TBytes) : Boolean;
var
	hexCommand : AnsiString;
  toSend : TBytes;
  i : Integer;
  newCRC : Word;

begin
  try
    lastCommandPCB := PCB;

    hexCommand := IntToHex(PCB, 2);
    i := 1;
    while (i <= Length(command)) do
    begin
      hexCommand := hexCommand + IntToHex(command[i - 1], 2);
      Inc(i);
    end; // while
    hexCommand := hexCommand + '28';

    // Calculate and append CRC
  //	newCRC = M24SR_ComputeCrc(msg, commandLen+1);
  //	msg[commandLen + 1] = newCRC  & 0x00FF;
  //	msg[commandLen + 2] = (newCRC & 0xFF00) >> 8;

    toSend := StringToTBytes0(hexCommand);
    result := SendToTag(toSend);

{$IFDEF DEBUG_LOTS}
    AddNFCDebug('Send to tag,Exited');
    AddNFCDebug('Send to tag,Length of reply = ' + IntToStr(Length(cmdResponse)));
{$ENDIF}

    // Check PCB to see whether the Block number should be changed
    // See ISO 14443_4 rules, above
    //    Rule B: When an I-block or an R(ACK) block with a block number equal to
    //      the current block number is received, the Reader shall toggle the
    //      current block number before optionally sending a block to the NFC device.
    if ((result) and
        ((((Ord(cmdResponse[0]) and PCB_BLOCK_MASK) = PCB_ID_I) or
         ((Ord(cmdResponse[0]) and (PCB_BLOCK_MASK or R_PCB_ACK_MASK)) = (PCB_ID_R or R_PCB_ACK))) and
        ((Ord(cmdResponse[0]) and IR_PCB_BLOCK_NUMBER_MASK) = blockNumber))) then
      blockNumber := 1 - blockNumber;
  except
    on E:Exception do
    begin
      errorMsgNFC := 'SendCommand (' + E.Message + ')';
      result := FALSE;
    end; // on
  end;

{$IFDEF DEBUG_LOTS}
  if (result) then
    AddNFCDebug('SendCommand,Sucessful')
  else
    AddNFCDebug('SendCommand,Failed');
{$ENDIF}
end; // SendCommand

//*****************************************************************************
//
//  FUNCTION  : ResponseStatus
//
//  I/P       : response : array of Byte - The received response
//
//              offset : Integer - The expected location in the response of SW1
//
//  O/P       : Word - SW1 (MSB) + SW2 (LSB)
//
//  OPERATION : Concatenates the response status bytes SW1/SW2 as Hi/Lo
//
//  UPDATED   : 2021-09-28
//
//*****************************************************************************
function ResponseStatus(response : array of Byte;
                        offset : Integer) : Word;
begin
  if (Length(response) >= offset + 1) then
  begin
    result := (response[offset] shl 8) or response[offset+1]
  end
  else
  begin
    result := 0;
  end;
end; // ResponseStatus

//***************************************************************************
//
//  FUNCTION  : NFC_StateControl
//
//  I/P       :
//
//  O/P       : Boolean - TRUE if the command executed correctly
//
//  OPERATION :
//
//  UPDATED   : 2021-02-01
//
//***************************************************************************
function NFC_StateControl(state : Boolean) : Boolean;
var
  command : TBytes;

begin
  SetLength(command, 6);
  command[0] := CLA_ST_CMD;               // $A2
  command[1] := INS_WRITE_BINARY;         // $D6
  command[2] := $00;                      // P1
  command[3] := $1F;                      // P2
  command[4] := $01;                      // Lc
  if (state) then
    command[5] := $01
  else
    command[5] := $00;
  // not used                             // Le

  result := (SendCommand(PCB_ID_I or PCB_RFU_I or blockNumber,
                         command)) and
//            (Length(cmdResponse) = 5) and
            (ResponseStatus(cmdResponse, 1) = RX_STAT_OK);
end; // NFC_StateControl

//***************************************************************************
//
//  FUNCTION  : NFC_SelectNDEFTagApplication
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2021-01-29
//
//***************************************************************************
function NFC_SelectNDEFTagApplication : Boolean;
const
	data : array[0..6] of Byte = ($D2, $76, $00, $00, $85, $01, $01);

var
  command : TBytes;

begin
  SetLength(command, 6 + SizeOf(data));
  command[0] := CLA_STANDARD;             // $00
  command[1] := INS_SELECT;               // $A4
  command[2] := $04;                      // P1
  command[3] := $00;                      // P2
  command[4] := sizeof(data);             // Lc
  Move(data, command[5], sizeof(data));
  command[6 + sizeof(data) - 1] := $00;   // Le

  result := (SendCommand(PCB_ID_I or PCB_RFU_I or blockNumber,
                         command)) and
//            (Length(cmdResponse) = 5) and
            (ResponseStatus(cmdResponse, 1) = RX_STAT_OK);

{$IFDEF DEBUG_LOTS}
  AddNFCDebug('NFC_SelectNDEFTagApplication response length,' + IntToStr(Length(cmdResponse)));
  AddNFCDebug('NFC_SelectNDEFTagApplication response,' + TBytes2HexString(cmdResponse));
  AddNFCDebug('NFC_SelectNDEFTagApplication completed,' + IntToStr(Integer(result)));
{$ENDIF}
end;


//*****************************************************************************
//
//  FUNCTION  : SelectFile
//
//  I/P       : uint8_t fileID - Identity for the type of file to be selected
//
//  O/P       : status_t
//
//  OPERATION : Then select the requested file (Capability Container, System file
//              or NDEF file) and receive a response.   This should be
//              PCB (no DID), [SW1, SW2], 2 x CRC
//
//  UPDATED   : 2018-10-05
//
//*****************************************************************************
function NFC_SelectFile(fileID : Integer) : Boolean;
var
  command : TBytes;

begin
  SetLength(command, 7);
  command[0] := CLA_STANDARD;                       // $00
  command[1] := INS_SELECT;                         // $A4
  command[2] := $00;                               // P1
  command[3] := $0C;                               // P2
  command[4] := $02;                               // Lc - Length command
  case fileID of
    FI_CC :
    begin
      command[5] := $E1;
      command[6] := $03;
    end;

    FI_SYSTEM :
    begin
      command[5] := $E1;
      command[6] := $01;
    end

    else
    // FI_NDEF :
      command[5] := $00;
      command[6] := $01;
  end; // case

  result := (SendCommand(PCB_ID_I or PCB_RFU_I or blockNumber,
                         command)) and
//            (Length(cmdResponse) = 5) and
            (ResponseStatus(cmdResponse, 1) = RX_STAT_OK);
end;

//***************************************************************************
//
//  FUNCTION  : NFC_SelectCapabilityContainerFile
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Select the NDEF file
//
//  UPDATED   : 2018-10-05
//
//***************************************************************************
function NFC_SelectCapabilityContainerFile : Boolean;
begin
  result := NFC_Selectfile(FI_CC);
end; // NFC_SelectCapabilityContainerFile

//***************************************************************************
//
//  FUNCTION  : NFC_SelectSystemFile
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Select the NDEF file
//
//  UPDATED   : 2018-10-05
//
//***************************************************************************
function NFC_SelectSystemFile : Boolean;
begin
  result := NFC_Selectfile(FI_SYSTEM);
end; // NFC_SelectSystemFile

//***************************************************************************
//
//  FUNCTION  : NFC_SelectNDEFFile
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Select the NDEF file
//
//  UPDATED   : 2018-10-05
//
//***************************************************************************
function NFC_SelectNDEFFile : Boolean;
begin
  result := NFC_Selectfile(FI_NDEF);
end; // NFC_SelectNDEFFile

//***************************************************************************
//
//  FUNCTION  : NFC_ReadFile
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2021-01-29
//
//***************************************************************************
function NFC_ReadFile : Boolean;
var
  command : TBytes;
  response : TBytes;
  offset : Word;
  Le : Byte;
  lengthFile : Integer;

begin
  SetLength(command, 5);
  // Get the size of the file
  offset := $0000;
  Le := 2;
  command[0] := CLA_STANDARD;               // $00
  command[1] := INS_READ_BINARY;            // $B0
  command[2] := (offset shr 8) and $FF;     // P1 } Address
  command[3] := offset and $FF;             // P2 }
  command[4] := Le;                         // Length expected

  if ((SendCommand(PCB_ID_I or PCB_RFU_I or blockNumber,
                   command)) and
      (ResponseStatus(cmdResponse, Le + 1) = RX_STAT_OK)) then
  begin
    // Get the file
    offset := $0002;
    Le := (cmdResponse[1] shl 8) or Ord(cmdResponse[2]);
    command[0] := CLA_STANDARD;             // $00
    command[1] := INS_READ_BINARY;          // $B0
    command[2] := (offset shr 8) and $FF;   // P1 } Address
    command[3] := offset and $FF;           // P2 }
    command[4] := Le;                       // Length expected

    result := (SendCommand(PCB_ID_I or PCB_RFU_I or blockNumber,
                           command)) and
//        (kStatus_Success == ReceiveResponse(response, Le + 5)) &&
              (ResponseStatus(cmdResponse, Le + 1) = RX_STAT_OK);

    SetLength(ndefFileContents, NFC_BUFF_SIZE);
    Move(Pointer(@cmdResponse[1])^, Pointer(@ndefFileContents[0])^, Le);
    SetLength(ndefFileContents, Le);
//'�'#1#$E'T$$$$Z�'#5#0'IDT='#1'`'
// D1, 01, 0E(length=14), 'T', '$', '$', '$', '$', 5A, FF, 05, 00, 'I', 'D', 'T', '=', 01, CS
  end;
end; // NFC_ReadFile

//***************************************************************************
//
//  FUNCTION  : NFC_WriteFile
//
//  I/P       : hexData : AnsiString - The full command, in hexadecimal form.
// '$', '$', '$', '$', 5A, FF, 05, 00, 'I', 'D', 'T', '=', 01, CS
//
//  O/P       :
//
//  OPERATION : Writes the data from the beginning of the file, updating the
//              file length in the process.
//
//  UPDATED   : 2021-01-29
//
//***************************************************************************
function NFC_WriteFile(hexData : AnsiString) : Boolean;
var
  command : TBytes;
  i: Integer;

begin
  // Add the overall length to the front of the data (2 bytes)
  // Add the extra NDEF overhead bytes (4 of them)
  //    $D1 = TNF+Flags : ME, ME, CF, SR, IL, TNF[0..2]
  //    $01 = Type length
  //    Length command
  //    'T' = Payload type (text)
  hexData := '00' +
          IntToHex(Length(hexData) div 2 + NDEF_PACKET_OVERHEAD, 2) +
          'D1' +
          '01' +
          IntToHex(Length(hexData) div 2, 2) +
          IntToHex(Ord('T'), 2) +
          hexData;

  SetLength(command, 7 + Length(hexData) div 2);
  // Send an I-block format C-APDU command
  // (see M24SR02-Y datasheet 5.2.1 and 5.6.8)
  command[0] := CLA_STANDARD;                       // $00
  command[1] := INS_WRITE_BINARY;                   // $D6
  command[2] := $00;                                // P1 } Address
  command[3] := $00;                                // P2 }
  command[4] := Length(hexData) div 2 + 2;          // Length to be written (1 length bytes + data)
  for i := 0 to Length(hexData) div 2 - 1 do
    command[5 + i] := StrToInt('$' + Copy(hexData, 2*i+1, 2));
  result := (SendCommand(PCB_ID_I or PCB_RFU_I or blockNumber,
                         command));

  // Check if there is a S(WTX) Waiting Frame eXtension time request
  // (see M24SR02-Y datasheet 5.4)
  if ((result) and
      ((cmdResponse[0] and (PCB_BLOCK_MASK or S_PCB_WTX)) = (PCB_ID_S or S_PCB_WTX))) then
  begin
    SetLength(command, 1);
    command[0] := cmdResponse[1];
    result := SendCommand(PCB_ID_S or PCB_RFU_S or S_PCB_WTX, command);
    Sleep(Ord(command[0]) * 10);
  end;

  // Expect, at this point (whether an extension was requested or not), to have
  // an I-Block format response (see M24SR02-Y datasheet 5.2.2) with an SW1/SW2
  // "OK" result (i.e. $90/$00) (see M24SR02-Y datasheet 5.6.2)
  result := result and
            ((cmdResponse[0] and (PCB_ID_I or PCB_RFU_I)) = (PCB_ID_I or PCB_RFU_I)) and
            (cmdResponse[1] = $90) and
            (cmdResponse[2] = $00);
end; // NFC_WriteFile

//***************************************************************************
//
//  FUNCTION  : NFC_GetError
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2018-11-15
//
//***************************************************************************
function NFC_GetError : String;
begin
  result := errorMsgNFC;
end; // NFC_GetError

//***************************************************************************
//
//  FUNCTION  : StartLogging
//
//  I/P       : idDebug : Integer - The ID to be used for NFC debug logging
//
//  O/P       :
//
//  OPERATION : Start logging of NFC activities
//
//  UPDATED   : 2021-09-08
//
//***************************************************************************
procedure StartLogging(idDebug : Integer);
begin
  idxLogFile := idDebug;
end; // StartLogging

//***************************************************************************
//
//  FUNCTION  : StopLogging
//
//  I/P       : None
//
//  O/P       :
//
//  OPERATION : Start logging of NFC activities
//
//  UPDATED   : 2021-09-08
//
//***************************************************************************
procedure StopLogging;
begin
  idxLogFile := -1;
end; // StopLogging

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
//***************************************************************************\
initialization
  idxLogFile := -1;

end.
