unit Internet_Ops;

interface

uses
  Windows, SysUtils, Classes, Vcl.ComCtrls;

type
  TSunB = packed record
    s_b1, s_b2, s_b3, s_b4: byte;
  end;

  TSunW = packed record
    s_w1, s_w2: word;
  end;

  PIPAddr = ^TIPAddr;
  TIPAddr = record
    case integer of
      0: (S_un_b: TSunB);
      1: (S_un_w: TSunW);
      2: (S_addr: longword);
  end;

 IPAddr = TIPAddr;

function IcmpCreateFile : THandle; stdcall; external 'icmp.dll';
function IcmpCloseHandle (icmpHandle : THandle) : boolean;
            stdcall; external 'icmp.dll';
function IcmpSendEcho
   (IcmpHandle : THandle; DestinationAddress : IPAddr;
    RequestData : Pointer; RequestSize : Smallint;
    RequestOptions : pointer;
    ReplyBuffer : Pointer;
    ReplySize : DWORD;
    Timeout : DWORD) : DWORD; stdcall; external 'icmp.dll';

function Ping(InetAddress : AnsiString) : Boolean;
function IsWebSiteUP(sURL: string): boolean;
function InternetConnectionAvailable : Boolean;
//Function CheckIPConnection(Name: String; var IP: String): Boolean;

procedure GetMACAddresses(const macAddresses : TStringList;
                          includeNulls : Boolean;
                          noDuplicates : Boolean);
function GetInternetFile(const fileURL, FileName: String;
                         indicator : TComponent;
                         sizeFile : Uint32;
                         resetAtEnd : Boolean = FALSE): boolean;

implementation

uses
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Forms, Vcl.TaskBar, System.Win.TaskbarCore,
  IdHTTP,
  IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient,
  WinAPI.IpTypes, WinAPI.IpHlpApi,
  WinAPI.WinINet, WinSock, Types;

//***************************************************************************
//
//  FUNCTION  : GetMACAddresses
//
//  I/P       : includeNulls : Boolean - TRUE to include 00:00:00:00:00:00 (i.e
//                empty slots) in the list.
//
//              noDuplicates : Boolean - If TRUE, the list will be sorted,
//                with no duplicates
//
//  O/P       : const macAddresses : TStringList - Result (why "const"?
//
//  OPERATION : See Winapi.IpTypes and Winapi.IpHlpApi
//
//  UPDATED   : 2019-01-14
//
//***************************************************************************
procedure GetMACAddresses(const macAddresses : TStringList;
                          includeNulls : Boolean;
                          noDuplicates : Boolean);
var
  NumInterfaces: Cardinal;
  AdapterInfo: array of TIpAdapterInfo;
  OutBufLen: ULONG;
  i: integer;

begin
  GetNumberOfInterfaces(NumInterfaces);
  SetLength(AdapterInfo, NumInterfaces);
  OutBufLen := NumInterfaces * SizeOf(TIpAdapterInfo);
  GetAdaptersInfo(@AdapterInfo[0], OutBufLen);

  macAddresses.Clear;
  if (noDuplicates) then
  begin
    macAddresses.Sorted := TRUE;
    macAddresses.Duplicates := dupIgnore;
  end;
  for i := 0 to NumInterfaces - 1 do
  begin
    if ((includeNulls) or
        (AdapterInfo[i].Address[0] <> 0) or
        (AdapterInfo[i].Address[1] <> 0) or
        (AdapterInfo[i].Address[2] <> 0) or
        (AdapterInfo[i].Address[3] <> 0) or
        (AdapterInfo[i].Address[4] <> 0) or
        (AdapterInfo[i].Address[5] <> 0)) then
    macAddresses.Add(Format('%.2x:%.2x:%.2x:%.2x:%.2x:%.2x',
      [AdapterInfo[i].Address[0], AdapterInfo[i].Address[1],
       AdapterInfo[i].Address[2], AdapterInfo[i].Address[3],
       AdapterInfo[i].Address[4], AdapterInfo[i].Address[5]]));
  end; // for
end; // GetMACAddresses

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Attempts to get a response from a given URL
//              See http://www.delphipages.com/forum/showthread.php?t=120822
//
//  UPDATED   :
//
//***************************************************************************
function IsWebSiteUP(sURL: string): boolean;
var
  HTTP: TidHTTP;

begin
  result := TRUE;
  HTTP := TidHTTP.Create(nil);
  try
    HTTP.Get(sURL);
    // See the table below for standard HTTP response codes.
    // Modify this case statement to handle the others that you want to catch.
    case HTTP.ResponseCode of
    400..505:
      begin
        result := FALSE;
      end;
    end; {case}
  finally
    HTTP.Free;
  end;
end;





















function Fetch(var AInput: string;
                      const ADelim: string = ' ';
                      const ADelete: Boolean = true)
 : string;
var
  iPos: Integer;
begin
  if ADelim = #0 then begin
    // AnsiPos does not work with #0
    iPos := Pos(ADelim, AInput);
  end else begin
    iPos := Pos(ADelim, AInput);
  end;
  if iPos = 0 then begin
    Result := AInput;
    if ADelete then begin
      AInput := '';
    end;
  end else begin
    result := Copy(AInput, 1, iPos - 1);
    if ADelete then begin
      Delete(AInput, 1, iPos + Length(ADelim) - 1);
    end;
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
procedure TranslateStringToTInAddr(AIP: AnsiString; var AInAddr);
var
  phe: PHostEnt;
  pac: PAnsiChar;
  GInitData: TWSAData;

begin
  WSAStartup($101, GInitData);
  try
    phe := GetHostByName(PAnsiChar(AIP));
    if Assigned(phe) then
    begin
      pac := phe^.h_addr_list^;
      if Assigned(pac) then
      begin
        with TIPAddr(AInAddr).S_un_b do
        begin
          s_b1 := Byte(pac[0]);
          s_b2 := Byte(pac[1]);
          s_b3 := Byte(pac[2]);
          s_b4 := Byte(pac[3]);
        end;
      end
      else
      begin
        raise Exception.Create('Error getting IP from HostName');
      end;
    end
    else
    begin
      raise Exception.Create('Error getting HostName');
    end;
  except
    FillChar(AInAddr, SizeOf(AInAddr), #0);
  end;
  WSACleanup;
end;

//***************************************************************************
//
//  FUNCTION  : Ping
//
//  I/P       : InetAddress : AnsiString
//
//  O/P       : Boolean - TRUE if the given address is reachable.
//
//  OPERATION :
//
//  UPDATED   : 2019-05-04
//
//***************************************************************************
function Ping(InetAddress : AnsiString) : Boolean;
var
 Handle : THandle;
 InAddr : IPAddr;
 DW : DWORD;
 rep : array[1..128] of byte;

begin
  result := false;
  Handle := IcmpCreateFile;
  if Handle = INVALID_HANDLE_VALUE then
   Exit;
  TranslateStringToTInAddr(InetAddress, InAddr);
  DW := IcmpSendEcho(Handle, InAddr, nil, 0, nil, @rep, 128, 0);
  Result := (DW <> 0);
  IcmpCloseHandle(Handle);
end;

//***************************************************************************
//
//  FUNCTION  : InternetConnectionAvailable
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
function InternetConnectionAvailable : Boolean;
const
  // local system uses a modem to connect to the Internet.
  INTERNET_CONNECTION_MODEM = 1;
  // local system uses a local area network to connect to the Internet.
  INTERNET_CONNECTION_LAN = 2;
  // local system uses a proxy server to connect to the Internet.
  INTERNET_CONNECTION_PROXY = 4;
  // local system's modem is busy with a non-Internet connection.
  INTERNET_CONNECTION_MODEM_BUSY = 8;

var
  dwConnectionTypes : cardinal;

begin
  Result := InternetGetConnectedState(@dwConnectionTypes,0);

//dwConnectionTypes := INTERNET_CONNECTION_MODEM;
//dwConnectionTypes := INTERNET_CONNECTION_MODEM + INTERNET_CONNECTION_LAN + INTERNET_CONNECTION_PROXY;
//dwConnectionTypes := INTERNET_CONNECTION_MODEM + INTERNET_CONNECTION_LAN + INTERNET_CONNECTION_PROXY;
//dwConnectionTypes := INTERNET_CONNECTION_MODEM + INTERNET_CONNECTION_LAN + INTERNET_CONNECTION_PROXY;
//dwConnectionTypes := INTERNET_CONNECTION_MODEM + INTERNET_CONNECTION_LAN + INTERNET_CONNECTION_PROXY;

end; // InternetConnectionAvailable


(*
// CheckIPConnection('www.whatever.com' IP);
Function CheckIPConnection(Name: String; var IP: String): Boolean;
var
  wsdata : TWSAData;
  hostName : array [0..255] of char;
  hostEnt : PHostEnt;
  addr : PChar;

begin
  WSAStartup ($0101, wsdata);
  try
    gethostname (hostName, sizeof (hostName));
    StrPCopy(hostName, Name);
    hostEnt := gethostbyname (hostName); // Hier is de vertraging...
    if Assigned (hostEnt) then
    begin
      if Assigned (hostEnt^.h_addr_list) then
      begin
        addr := hostEnt^.h_addr_list^;
        if Assigned (addr) then
        begin
          IP := Format ('%d.%d.%d.%d', [byte (addr [0]),byte (addr [1]), byte (addr [2]), byte (addr [3])]);
          Result := True;
        end
        else
          Result := False;
      end
      else
        Result := False
    end // if
    else
    begin
      Result := False;
    end;
  finally
    WSACleanup;
  end;
end;
*)

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
// from http://stackoverflow.com/questions/9165926/using-wininet-to-identify-total-file-size-before-downloading-it
//
//  UPDATED   :
//
//***************************************************************************
function GetInternetFilesize(const Url :string) : Integer;
var
  Http: TIdHTTP;

begin
  Http := TIdHTTP.Create(nil);
  try
    Http.Head(Url);
    result:= Http.Response.ContentLength;
  finally
    Http.Free;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : GetInternetFile
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : from http://delphi.about.com/od/internetintranet/a/get_file_net.htm
// Warning : http://stackoverflow.com/questions/9165926/using-wininet-to-identify-total-file-size-before-downloading-it
//
//  UPDATED   : 2019-05-04
//
//***************************************************************************
function GetInternetFile(const fileURL, FileName: String;
                         indicator : TComponent;
                         sizeFile : Uint32;
                         resetAtEnd : Boolean = FALSE): boolean;
const
  BufferSize = 1024;
var
  hSession, hURL: HInternet;
  Buffer: array[1..BufferSize] of Byte;
  BufferLen: Cardinal;
  f: File;
  sAppName: string;
  overallSize : Integer;
  progressValue : Uint32;

begin
  result := false;
  progressValue := 0;

  sAppName := ExtractFileName(Application.ExeName);
  hSession := InternetOpen(PChar(sAppName), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  try
    hURL := InternetOpenURL(hSession, PChar(fileURL), nil, 0, INTERNET_FLAG_RELOAD, 0);//INTERNET_FLAG_RELOAD or INTERNET_FLAG_PRAGMA_NOCACHE or INTERNET_FLAG_RESYNCHRONIZE, 0);
    try

      // Initialise the progress indicator
      if (indicator is TProgressBar) then
      begin
        // Get passed the size from the ini file at present
        if (sizeFile > 0) then
          TProgressBar(indicator).Max := sizeFile
        else
          TProgressBar(indicator).Max := GetInternetFilesize(fileURL);
        TProgressBar(indicator).Position := 0;
      end // if
      else if (indicator is TTaskBar) then
      begin
        TTaskBar(indicator).ProgressState := TTaskbarProgressState.Normal;
        // Get passed the size from the ini file at present
        if (sizeFile > 0) then
          TTaskBar(indicator).ProgressMaxValue := sizeFile
        else
          TTaskBar(indicator).ProgressMaxValue := GetInternetFilesize(fileURL);
        TTaskBar(indicator).ProgressValue := 0;
      end // if
      else if (indicator is TPanel) then
      begin
        progressValue := 0;
        TPanel(indicator).Caption := '0%';
        TPanel(indicator).Update
      end // if
      else if (indicator is TLabel) then
      begin
        progressValue := 0;
        TLabel(indicator).Caption := '0%';
        TLabel(indicator).Update;
      end; // if

      AssignFile(f, FileName);
      Rewrite(f,1);
      repeat
        result := InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen);
        if (result) then
        begin
          BlockWrite(f, Buffer, BufferLen);
          // Update progress
          if (indicator is TProgressBar) then
          begin
            TProgressBar(indicator).Position := TProgressBar(indicator).Position +
                                                Integer(BufferLen);
          end // if
          else if (indicator is TTaskBar) then
          begin
            TTaskBar(indicator).ProgressValue := TTaskBar(indicator).ProgressValue +
                                                 Integer(BufferLen);
          end // if
          else if (indicator is TPanel) then
          begin
            progressValue := progressValue + Cardinal(BufferLen);
            TPanel(indicator).Caption := Format('%.0f%%', [100.0 * progressValue / sizeFile]);
            TPanel(indicator).Update;
          end // if
          else if (indicator is TLabel) then
          begin
            progressValue := progressValue + Cardinal(BufferLen);
            TLabel(indicator).Caption := Format('%.0f%%', [100.0 * progressValue / sizeFile]);
            TLabel(indicator).Update;
          end; // if
        end; // if
      until ((not result) or
             (BufferLen = 0));
      CloseFile(f);

      if (resetAtEnd) then
      begin
        if (indicator is TProgressBar) then
        begin
          TProgressBar(indicator).Position := 0;
        end // if
        else if (indicator is TTaskBar) then
        begin
          TTaskBar(indicator).ProgressState := TTaskbarProgressState.None;
        end // if
        else if (indicator is TPanel) then
        begin
          TPanel(indicator).Caption := '';
          TPanel(indicator).Update;
        end // if
        else if (indicator is TLabel) then
        begin
          TLabel(indicator).Caption := '';
          TLabel(indicator).Update;
        end;
      end; // if
//      result := True;
{TODO -oAndrew Spencer -cGeneric : Check that this works with and without internet connection}
    finally
      InternetCloseHandle(hURL);
    end
  finally
    InternetCloseHandle(hSession);
  end
end; // GetInternetFile

end.
