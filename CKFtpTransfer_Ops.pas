unit CKFtpTransfer_Ops;

interface

uses
  System.SysUtils;

const
  // Protocol identifiers (persist these in Comms/FTP configuration).
  FTP_PROTO_FTP            = 0;
  FTP_PROTO_FTPS_EXPLICIT  = 1;
  FTP_PROTO_FTPS_IMPLICIT  = 2;
  FTP_PROTO_SFTP           = 3;

  // Default service ports when ARequest.Port = 0.
  FTP_DEFAULT_PORT_FTP            = 21;
  FTP_DEFAULT_PORT_FTPS_IMPLICIT  = 990;
  FTP_DEFAULT_PORT_SFTP           = 22;

type
  TFtpTransferProgressProc = procedure(ABytesTransferred: Int64;
                                       var AAbort: Boolean);

  TFtpTransferRequest = record
    Protocol           : Integer;
    Host               : string;
    Port               : Integer;
    UserName           : string;
    Password           : string;
    RemoteDir          : string;
    LocalFile          : string;
    RemoteFile         : string;
    Passive            : Boolean;
    VerifyServerCert   : Boolean;
    ConnectTimeoutSec  : Integer;
    procedure InitDefaults;
  end;

  TFtpTransferResult = record
    Success            : Boolean;
    ErrorCode          : Integer;
    ErrorMessage       : string;
    SessionLog         : string;
    class function Ok: TFtpTransferResult; static;
    class function Fail(AErrorCode: Integer; const AErrorMessage: string): TFtpTransferResult; static;
  end;

function DefaultFtpPort(AProtocol: Integer): Integer;
function FtpProtocolToText(AProtocol: Integer): string;

function ExecuteFtpUpload(const ARequest: TFtpTransferRequest;
                          AProgress: TFtpTransferProgressProc = nil;
                          ACancelFlag: PBoolean = nil): TFtpTransferResult;

implementation

uses
  System.IOUtils,
  ck_Global,
  ck_Ftp2,
  ck_SFtp,
  CKGeneral_Ops;

type
  TFtpTransferRuntime = record
    LocalFileSize      : Int64;
    Progress           : TFtpTransferProgressProc;
    CancelFlag         : PBoolean;
  end;

var
  gActiveTransferRuntime   : TFtpTransferRuntime;

function GetLocalFileSizeBytes(const AFileName: string): Int64;
begin
  if FileExists(AFileName) then
  begin
    Result := TFile.GetSize(AFileName);
  end // if
  else
  begin
    Result := 0;
  end; // else
end; // GetLocalFileSizeBytes

function Ftp2PercentDoneCallback(APctDone: Integer): Integer; cdecl;
var
  lBytes               : Int64;
  lAbort               : Boolean;
begin
  Result := 0;
  if not Assigned(gActiveTransferRuntime.Progress) then
  begin
    Exit;
  end; // if

  if (gActiveTransferRuntime.LocalFileSize > 0) then
  begin
    lBytes := (gActiveTransferRuntime.LocalFileSize * APctDone) div 100;
  end // if
  else
  begin
    lBytes := APctDone;
  end; // else

  lAbort := False;
  gActiveTransferRuntime.Progress(lBytes, lAbort);
  if lAbort then
  begin
    Result := 1;
  end; // if
end; // Ftp2PercentDoneCallback

function Ftp2AbortCheckCallback: Integer; cdecl;
begin
  Result := 0;
  if Assigned(gActiveTransferRuntime.CancelFlag) and
     gActiveTransferRuntime.CancelFlag^ then
  begin
    Result := 1;
  end; // if
end; // Ftp2AbortCheckCallback

function SftpPercentDoneCallback(APctDone: Integer): Integer; cdecl;
var
  lBytes               : Int64;
  lAbort               : Boolean;
begin
  Result := 0;
  if not Assigned(gActiveTransferRuntime.Progress) then
  begin
    Exit;
  end; // if

  if (gActiveTransferRuntime.LocalFileSize > 0) then
  begin
    lBytes := (gActiveTransferRuntime.LocalFileSize * APctDone) div 100;
  end // if
  else
  begin
    lBytes := APctDone;
  end; // else

  lAbort := False;
  gActiveTransferRuntime.Progress(lBytes, lAbort);
  if lAbort then
  begin
    Result := 1;
  end; // if
end; // SftpPercentDoneCallback

function SftpAbortCheckCallback: Integer; cdecl;
begin
  Result := 0;
  if Assigned(gActiveTransferRuntime.CancelFlag) and
     gActiveTransferRuntime.CancelFlag^ then
  begin
    Result := 1;
  end; // if
end; // SftpAbortCheckCallback

procedure TFtpTransferRequest.InitDefaults;
begin
  Protocol := FTP_PROTO_FTP;
  Host := '';
  Port := 0;
  UserName := '';
  Password := '';
  RemoteDir := '';
  LocalFile := '';
  RemoteFile := '';
  Passive := True;
  VerifyServerCert := True;
  ConnectTimeoutSec := 30;
end; // InitDefaults

class function TFtpTransferResult.Ok: TFtpTransferResult;
begin
  Result.Success := True;
  Result.ErrorCode := 0;
  Result.ErrorMessage := '';
  Result.SessionLog := '';
end; // Ok

class function TFtpTransferResult.Fail(AErrorCode: Integer;
                                       const AErrorMessage: string): TFtpTransferResult;
begin
  Result.Success := False;
  Result.ErrorCode := AErrorCode;
  Result.ErrorMessage := AErrorMessage;
  Result.SessionLog := '';
end; // Fail

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function DefaultFtpPort(AProtocol: Integer): Integer;
begin
  case AProtocol of
    FTP_PROTO_FTPS_IMPLICIT:
      Result := FTP_DEFAULT_PORT_FTPS_IMPLICIT;
    FTP_PROTO_SFTP:
      Result := FTP_DEFAULT_PORT_SFTP;
  else
    Result := FTP_DEFAULT_PORT_FTP;
  end; // case
end; // DefaultFtpPort

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function FtpProtocolToText(AProtocol: Integer): string;
begin
  case AProtocol of
    FTP_PROTO_FTPS_EXPLICIT:
      Result := 'FTPS (explicit TLS)';
    FTP_PROTO_FTPS_IMPLICIT:
      Result := 'FTPS (implicit TLS)';
    FTP_PROTO_SFTP:
      Result := 'SFTP';
  else
    Result := 'FTP';
  end; // case
end; // FtpProtocolToText

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function ResolveRemoteFileName(const ARequest: TFtpTransferRequest): string;
begin
  if (Trim(ARequest.RemoteFile) <> '') then
  begin
    Result := ExtractFileName(ARequest.RemoteFile);
  end // if
  else
  begin
    Result := ExtractFileName(ARequest.LocalFile);
  end; // else
end; // ResolveRemoteFileName

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function CombineSftpRemotePath(const ARemoteDir, ARemoteFile: string): string;
var
  lDir                 : string;
  lFile                : string;
begin
  lDir := Trim(ARemoteDir);
  lFile := Trim(ARemoteFile);
  lDir := StringReplace(lDir, '\', '/', [rfReplaceAll]);
  while (lDir <> '') and ((lDir[1] = '/') or (lDir[1] = '\')) do
  begin
    Delete(lDir, 1, 1);
  end; // while
  while (lDir <> '') and ((lDir[Length(lDir)] = '/') or (lDir[Length(lDir)] = '\')) do
  begin
    Delete(lDir, Length(lDir), 1);
  end; // while

  if (lDir = '') then
  begin
    Result := lFile;
  end // if
  else if (lFile = '') then
  begin
    Result := lDir;
  end // else if
  else
  begin
    Result := lDir + '/' + lFile;
  end; // else
end; // CombineSftpRemotePath

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function ValidateRequest(const ARequest: TFtpTransferRequest): TFtpTransferResult;
begin
  Result := TFtpTransferResult.Ok;

  if (Trim(ARequest.Host) = '') then
  begin
    Result := TFtpTransferResult.Fail(-1, 'FTP host is not specified.');
    Exit;
  end; // if

  if (Trim(ARequest.LocalFile) = '') then
  begin
    Result := TFtpTransferResult.Fail(-2, 'Local file path is not specified.');
    Exit;
  end; // if

  if (not FileExists(ARequest.LocalFile)) then
  begin
    Result := TFtpTransferResult.Fail(-3, 'Local file does not exist: ' + ARequest.LocalFile);
    Exit;
  end; // if
end; // ValidateRequest

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
procedure NotifyProgress(ABytesTransferred: Int64;
                         ACancelFlag: PBoolean;
                         AProgress: TFtpTransferProgressProc);
var
  lAbort               : Boolean;
begin
  if not Assigned(AProgress) then
  begin
    Exit;
  end; // if

  lAbort := False;
  AProgress(ABytesTransferred, lAbort);
  if lAbort and Assigned(ACancelFlag) then
  begin
    ACancelFlag^ := True;
  end; // if
end; // NotifyProgress

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
procedure ApplyFtp2SecuritySettings(AFtp: HCkFtp2; AProtocol: Integer;
                                    AVerifyServerCert: Boolean);
begin
  CkFtp2_putSsl(AFtp, AProtocol = FTP_PROTO_FTPS_IMPLICIT);
  CkFtp2_putAuthTls(AFtp, AProtocol = FTP_PROTO_FTPS_EXPLICIT);
  CkFtp2_putAuthSsl(AFtp, False);
  CkFtp2_putRequireSslCertVerify(AFtp, AVerifyServerCert);
end; // ApplyFtp2SecuritySettings

function UploadViaFtp2(const ARequest: TFtpTransferRequest;
                       APort: Integer;
                       AProgress: TFtpTransferProgressProc;
                       ACancelFlag: PBoolean): TFtpTransferResult;
var
  lFtp                 : HCkFtp2;
  lRemoteFile          : string;
  lAbort               : Boolean;
begin
  Result := TFtpTransferResult.Ok;
  lFtp := CkFtp2_Create();
  try
    FillChar(gActiveTransferRuntime, SizeOf(gActiveTransferRuntime), 0);
    gActiveTransferRuntime.Progress := AProgress;
    gActiveTransferRuntime.CancelFlag := ACancelFlag;
    gActiveTransferRuntime.LocalFileSize := GetLocalFileSizeBytes(ARequest.LocalFile);

    CkFtp2_putHostname(lFtp, PWideChar(ARequest.Host));
    CkFtp2_putPort(lFtp, APort);
    CkFtp2_putUsername(lFtp, PWideChar(ARequest.UserName));
    CkFtp2_putPassword(lFtp, PWideChar(ARequest.Password));
    CkFtp2_putPassive(lFtp, ARequest.Passive);
    if (ARequest.ConnectTimeoutSec > 0) then
    begin
      CkFtp2_putConnectTimeout(lFtp, ARequest.ConnectTimeoutSec);
    end; // if

    ApplyFtp2SecuritySettings(lFtp, ARequest.Protocol, ARequest.VerifyServerCert);

    CkFtp2_putHeartbeatMs(lFtp, 200);
    CkFtp2_SetAbortCheck(lFtp, @Ftp2AbortCheckCallback);
    CkFtp2_SetPercentDone(lFtp, @Ftp2PercentDoneCallback);

    NotifyProgress(0, ACancelFlag, AProgress);
    if Assigned(ACancelFlag) and ACancelFlag^ then
    begin
      Result := TFtpTransferResult.Fail(-10, 'FTP upload cancelled.');
      Exit;
    end; // if

    if not CkFtp2_Connect(lFtp) then
    begin
      Result := TFtpTransferResult.Fail(CkFtp2_getConnectFailReason(lFtp),
                                         string(CkFtp2__lastErrorText(lFtp)));
      Result.SessionLog := string(CkFtp2__sessionLog(lFtp));
      Exit;
    end; // if

    NotifyProgress(-1, ACancelFlag, AProgress);

    if (Trim(ARequest.RemoteDir) <> '') then
    begin
      if not CkFtp2_ChangeRemoteDir(lFtp, PWideChar(ARequest.RemoteDir)) then
      begin
        Result := TFtpTransferResult.Fail(-11, 'Unable to change remote directory to "' +
                                          ARequest.RemoteDir + '". ' +
                                          string(CkFtp2__lastErrorText(lFtp)));
        Result.SessionLog := string(CkFtp2__sessionLog(lFtp));
        Exit;
      end; // if
    end; // if

    lRemoteFile := ResolveRemoteFileName(ARequest);
    if not CkFtp2_PutFile(lFtp, PWideChar(ARequest.LocalFile), PWideChar(lRemoteFile)) then
    begin
      Result := TFtpTransferResult.Fail(-12, 'FTP upload failed. ' +
                                         string(CkFtp2__lastErrorText(lFtp)));
      Result.SessionLog := string(CkFtp2__sessionLog(lFtp));
      Exit;
    end; // if

    if (gActiveTransferRuntime.LocalFileSize > 0) then
    begin
      NotifyProgress(gActiveTransferRuntime.LocalFileSize, ACancelFlag, AProgress);
    end // if
    else
    begin
      lAbort := False;
      if Assigned(AProgress) then
      begin
        AProgress(100, lAbort);
      end; // if
    end; // else

    CkFtp2_Disconnect(lFtp);
  finally
    FillChar(gActiveTransferRuntime, SizeOf(gActiveTransferRuntime), 0);
    CkFtp2_Dispose(lFtp);
  end; // try
end; // UploadViaFtp2

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function UploadViaSftp(const ARequest: TFtpTransferRequest;
                       APort: Integer;
                       AProgress: TFtpTransferProgressProc;
                       ACancelFlag: PBoolean): TFtpTransferResult;
var
  lSftp                : HCkSFtp;
  lRemotePath          : string;
  lAbort               : Boolean;
begin
  Result := TFtpTransferResult.Ok;
  lSftp := CkSFtp_Create();
  try
    FillChar(gActiveTransferRuntime, SizeOf(gActiveTransferRuntime), 0);
    gActiveTransferRuntime.Progress := AProgress;
    gActiveTransferRuntime.CancelFlag := ACancelFlag;
    gActiveTransferRuntime.LocalFileSize := GetLocalFileSizeBytes(ARequest.LocalFile);

    if (ARequest.ConnectTimeoutSec > 0) then
    begin
      CkSFtp_putConnectTimeoutMs(lSftp, ARequest.ConnectTimeoutSec * 1000);
    end; // if
    // Note: SFTP host-key pinning/fingerprint validation can be added when
    // destination configuration supports a known host key fingerprint.

    CkSFtp_putHeartbeatMs(lSftp, 200);
    CkSFtp_SetAbortCheck(lSftp, @SftpAbortCheckCallback);
    CkSFtp_SetPercentDone(lSftp, @SftpPercentDoneCallback);

    NotifyProgress(0, ACancelFlag, AProgress);
    if Assigned(ACancelFlag) and ACancelFlag^ then
    begin
      Result := TFtpTransferResult.Fail(-20, 'SFTP upload cancelled.');
      Exit;
    end; // if

    if not CkSFtp_Connect(lSftp, PWideChar(ARequest.Host), APort) then
    begin
      Result := TFtpTransferResult.Fail(-21, 'SFTP connect failed. ' +
                                         string(CkSFtp__lastErrorText(lSftp)));
      Result.SessionLog := string(CkSFtp__sessionLog(lSftp));
      Exit;
    end; // if

    if not CkSFtp_AuthenticatePw(lSftp, PWideChar(ARequest.UserName), PWideChar(ARequest.Password)) then
    begin
      Result := TFtpTransferResult.Fail(CkSFtp_getAuthFailReason(lSftp),
                                         'SFTP authentication failed. ' +
                                         string(CkSFtp__lastErrorText(lSftp)));
      Result.SessionLog := string(CkSFtp__sessionLog(lSftp));
      CkSFtp_Disconnect(lSftp);
      Exit;
    end; // if

    if not CkSFtp_InitializeSftp(lSftp) then
    begin
      Result := TFtpTransferResult.Fail(-22, 'SFTP subsystem initialization failed. ' +
                                         string(CkSFtp__lastErrorText(lSftp)));
      Result.SessionLog := string(CkSFtp__sessionLog(lSftp));
      CkSFtp_Disconnect(lSftp);
      Exit;
    end; // if

    NotifyProgress(-1, ACancelFlag, AProgress);

    lRemotePath := CombineSftpRemotePath(ARequest.RemoteDir, ResolveRemoteFileName(ARequest));
    if not CkSFtp_UploadFileByName(lSftp, PWideChar(lRemotePath), PWideChar(ARequest.LocalFile)) then
    begin
      Result := TFtpTransferResult.Fail(-23, 'SFTP upload failed. ' +
                                         string(CkSFtp__lastErrorText(lSftp)));
      Result.SessionLog := string(CkSFtp__sessionLog(lSftp));
      CkSFtp_Disconnect(lSftp);
      Exit;
    end; // if

    if (gActiveTransferRuntime.LocalFileSize > 0) then
    begin
      NotifyProgress(gActiveTransferRuntime.LocalFileSize, ACancelFlag, AProgress);
    end // if
    else
    begin
      lAbort := False;
      if Assigned(AProgress) then
      begin
        AProgress(100, lAbort);
      end; // if
    end; // else

    CkSFtp_Disconnect(lSftp);
  finally
    FillChar(gActiveTransferRuntime, SizeOf(gActiveTransferRuntime), 0);
    CkSFtp_Dispose(lSftp);
  end; // try
end; // UploadViaSftp

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function ExecuteFtpUpload(const ARequest: TFtpTransferRequest;
                          AProgress: TFtpTransferProgressProc;
                          ACancelFlag: PBoolean): TFtpTransferResult;
var
  lPort                : Integer;
begin
  Result := ValidateRequest(ARequest);
  if not Result.Success then
  begin
    Exit;
  end; // if

  try
    EnsureChilkatLicenseApplied;
  except
    on E: Exception do
    begin
      Result := TFtpTransferResult.Fail(-100, E.Message);
      Exit;
    end; // on
  end; // try

  lPort := ARequest.Port;
  if (lPort <= 0) then
  begin
    lPort := DefaultFtpPort(ARequest.Protocol);
  end; // if

  case ARequest.Protocol of
    FTP_PROTO_FTP,
    FTP_PROTO_FTPS_EXPLICIT,
    FTP_PROTO_FTPS_IMPLICIT:
      Result := UploadViaFtp2(ARequest, lPort, AProgress, ACancelFlag);
    FTP_PROTO_SFTP:
      Result := UploadViaSftp(ARequest, lPort, AProgress, ACancelFlag);
  else
    Result := TFtpTransferResult.Fail(-4, 'Unsupported FTP protocol.');
  end; // case
end; // ExecuteFtpUpload

end.
