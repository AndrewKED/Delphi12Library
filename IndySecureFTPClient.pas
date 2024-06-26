unit IndySecureFTPClient;

// Based on my IndySecureMailClient unit
// See also http://www.indyproject.org/kb/index.html?howdoiuseftpwithssl.htm

interface

uses
  Classes, IdFTP, IdComponent, IdExplicitTLSClientServerBase, IdFTPCommon;

//const
//  SMTP_PORT_EXPLICIT_TLS = 587;

type
  TSSLFTP = class(TObject)
  private
    FTP: TIdFTP;

    FedFTPPort: Integer;
    FedFTPServer: String;
    FedPassword: String;
    FedUserName: String;
    FedUseTLS: TIdUseTLS;

    procedure Init;
    procedure InitMailMessage;
    procedure InitSASL;
    procedure AddSSLHandler;

  public
    constructor Create; overload;
    constructor Create(const AFTPServer: String;
                       const AFTPPort: Integer;
                       const AUserName, APassword: string); overload;

    destructor Destroy; override;

    function SendEmail : String;
    function TestConnection : String;

    // Properties
    property edPassword: string read FedPassword write FedPassword;
    property edFTPServer: string read FedFTPServer write FedFTPServer;
    property edFTPPort: Integer read FedFTPPort write FedFTPPort;
//    property edSSLConnection: Boolean read FedSSLConnection write FedSSLConnection;
    property edUseTLS: TIdUseTLS read FedUseTLS write FedUseTLS;
    property edUserName: string read FedUserName write FedUserName;

  end;

implementation

uses
  SysUtils,
  IdTCPConnection, IdTCPClient,
  IdBaseComponent, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdSASLLogin,
  IdSASL_CRAM_SHA1, IdSASL, IdSASLUserPass, IdSASL_CRAMBase, IdSASL_CRAM_MD5,
  IdSASLSKey, IdSASLPlain, IdSASLOTP, IdSASLExternal, IdSASLDigest,
  IdSASLAnonymous, IdUserPassProvider;

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
constructor TSSLFTP.Create;
begin
  inherited;

  Init;
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
procedure TSSLFTP.Init;
begin
  edUseTLS := utNoTLSSupport;
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
constructor TSSLFTP.Create(const AFTPServer: String;
                             const AFTPPort: Integer;
                             const AUserName, APassword: string);
begin
  Create;

  edFTPServer := AFTPServer;
  edFTPPort := AFTPPort;
  edUserName := AUserName;
  edPassword := APassword;
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
destructor TSSLFTP.Destroy;
begin
  inherited;
end;

//***************************************************************************
//
//  FUNCTION  : TestConnection
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
function TSSLFTP.TestConnection : String;
begin
  result := '';

  FTP := TIdFTP.Create;
  try
    if (edUseTLS <> utNoTLSSupport) then
    begin
      AddSSLHandler;

      if (edUseTLS = utUseExplicitTLS) then
        FTP.UseTLS := utUseExplicitTLS
      else
        FTP.UseTLS := utUseImplicitTLS;
    end;

// Note http://embarcadero.newsgroups.archived.at/public.delphi.internet.winsock/201009/1009284803.html
// comments on satDefault
    case edAuthType of
      satSASL :
      begin
        SMTP.AuthType := satSASL;
        InitSASL;
      end; // option
      satDefault :
      begin
        SMTP.AuthType := satDefault;
        SMTP.Username := edUserName;
        SMTP.Password := edPassword;
      end; // option
      else
      begin
        SMTP.AuthType := satNone;
      end; // else
    end; // case

//      SMTP.OnStatus := SMTPStatus;
    SMTP.Host := edSMTPServer;
    SMTP.Port := edSMTPPort;
    SMTP.ConnectTimeout := 30000;
    SMTP.UseEHLO := True;
    try
      SMTP.Connect;
    except
      on E: Exception do
      begin
        result := E.Message;
      end;
    end;
    SMTP.Disconnect;
  finally
    SMTP.Free;
  end;
end; // TestConnection

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : For a full email settings test, we need to actually try to
//              send an email.
//
//  UPDATED   : 2015-11-27
//
//***************************************************************************
function TSSLFTP.SendEmail : String;
begin
  result := '';

  IdMessage := TIdMessage.Create;
  try
    InitMailMessage;

    SMTP := TIdSMTP.Create;
    try
      if (edUseTLS <> utNoTLSSupport) then
      begin
        AddSSLHandler;

        if (edUseTLS = utUseExplicitTLS) then
          SMTP.UseTLS := utUseExplicitTLS
        else
          SMTP.UseTLS := utUseImplicitTLS;
      end;

// Note http://embarcadero.newsgroups.archived.at/public.delphi.internet.winsock/201009/1009284803.html
// comments on satDefault
      case edAuthType of
        satSASL :
        begin
          SMTP.AuthType := satSASL;
          InitSASL;
        end; // option
        satDefault :
        begin
          SMTP.AuthType := satDefault;
          SMTP.Username := edUserName;
          SMTP.Password := edPassword;
        end; // option
        else
        begin
          SMTP.AuthType := satNone;
        end; // else
      end; // case

//      SMTP.OnStatus := SMTPStatus;
      FTP.Host := edFTPServer;
      FTP.Port := edFTPPort;
      FTP.ConnectTimeout := 30000;
      SMTP.UseEHLO := True;
      try
        FTP.Connect;

        try
          try
            SMTP.Send(IdMessage);
          except
            on E: Exception do
            begin
              result := E.Message;
            end;
          end;
        finally
          FTP.Disconnect;
        end;

      except
        on E: Exception do
        begin
          result := E.Message;
        end;
      end;

    finally
      FTP.Free;
    end;
  finally
    IdMessage.Free;
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
procedure TSSLFTP.AddSSLHandler;
var
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(FTP);
  // SSL/TLS handshake determines the highest available SSL/TLS version dynamically
  SSLHandler.SSLOptions.Method := sslvSSLv23;
  SSLHandler.SSLOptions.Mode := sslmClient;
  SSLHandler.SSLOptions.VerifyMode := [];
  SSLHandler.SSLOptions.VerifyDepth := 0;
  FTP.IOHandler := SSLHandler;
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
procedure TSSLFTP.InitSASL;
var
  IdUserPassProvider: TIdUserPassProvider;
  IdSASLCRAMMD5: TIdSASLCRAMMD5;
  IdSASLCRAMSHA1: TIdSASLCRAMSHA1;
  IdSASLPlain: TIdSASLPlain;
  IdSASLLogin: TIdSASLLogin;
  IdSASLSKey: TIdSASLSKey;
  IdSASLOTP: TIdSASLOTP;
  IdSASLAnonymous: TIdSASLAnonymous;
  IdSASLExternal: TIdSASLExternal;

begin
  IdUserPassProvider := TIdUserPassProvider.Create(FTP);
  IdUserPassProvider.Username := edUserName;
  IdUserPassProvider.Password:= edPassword;

  IdSASLCRAMSHA1 := TIdSASLCRAMSHA1.Create(FTP);
  IdSASLCRAMSHA1.UserPassProvider := IdUserPassProvider;
  IdSASLCRAMMD5 := TIdSASLCRAMMD5.Create(FTP);
  IdSASLCRAMMD5.UserPassProvider := IdUserPassProvider;
  IdSASLSKey := TIdSASLSKey.Create(FTP);
  IdSASLSKey.UserPassProvider := IdUserPassProvider;
  IdSASLOTP := TIdSASLOTP.Create(FTP);
  IdSASLOTP.UserPassProvider := IdUserPassProvider;
  IdSASLAnonymous := TIdSASLAnonymous.Create(FTP);
  IdSASLExternal := TIdSASLExternal.Create(FTP);
  IdSASLLogin := TIdSASLLogin.Create(FTP);
  IdSASLLogin.UserPassProvider := IdUserPassProvider;
  IdSASLPlain := TIdSASLPlain.Create(FTP);
  IdSASLPlain.UserPassProvider := IdUserPassProvider;

  FTP.SASLMechanisms.Add.SASL := IdSASLCRAMSHA1;
  FTP.SASLMechanisms.Add.SASL := IdSASLCRAMMD5;
  FTP.SASLMechanisms.Add.SASL := IdSASLSKey;
  FTP.SASLMechanisms.Add.SASL := IdSASLOTP;
  FTP.SASLMechanisms.Add.SASL := IdSASLAnonymous;
  FTP.SASLMechanisms.Add.SASL := IdSASLExternal;
  FTP.SASLMechanisms.Add.SASL := IdSASLLogin;
  FTP.SASLMechanisms.Add.SASL := IdSASLPlain;
end;

end.
