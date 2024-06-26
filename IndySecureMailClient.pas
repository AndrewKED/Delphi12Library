unit IndySecureMailClient;

// Originally from https://mikejustin.wordpress.com/2014/07/

interface

uses
  IdMessage, Classes, IdSMTP, IdComponent, IdExplicitTLSClientServerBase;

const
  SMTP_PORT_EXPLICIT_TLS = 587;

type
  TSSLEmail = class(TObject)
  private
    IdMessage: TIdMessage;
    SMTP: TIdSMTP;

    FedBody: TStrings;
    FedHTMLBody : Boolean;
    FedSMTPPort: Integer;
    FedToEmail: String;
    FedSubject: String;
    FedAttachFile: String;
    FedAttachList: TStrings;
    FedSMTPServer: String;
    FedCCEmail: String;
    FedPassword: String;
    FedBCCEmail: String;
    FedSenderName: String;
    FedUserName: String;
    FedPriority: TIdMessagePriority;
    FedSenderEmail: String;
    FedReplyToEmail: String;
//    FedSSLConnection: Boolean;
    FedUseTLS: TIdUseTLS;
    FedAuthType: TIdSMTPAuthenticationType;

    // Getter / Setter
    procedure SetBody(const Value: TStrings);
    procedure SetAttachments(const Value: TStrings);
//    procedure SMTPStatus(ASender: TObject; const AStatus: TIdStatus;
//                         const AStatusText: String);

    procedure Init;
    procedure InitMailMessage;
    procedure InitSASL;
    procedure AddSSLHandler;

  public
    constructor Create; overload;
    constructor Create(const ASMTPServer: String;
                       const ASMTPPort: Integer;
                       const AUserName, APassword: string); overload;

    destructor Destroy; override;

    function SendEmail : String;
    function TestConnection : String;

    // Properties
    property edBCCEmail: string read FedBCCEmail write FedBCCEmail;
    property edBody: TStrings read FedBody write SetBody;
    property edCCEmail: string read FedCCEmail write FedCCEmail;
    property edPassword: string read FedPassword write FedPassword;
    property edPriority: TIdMessagePriority read FedPriority write FedPriority;
    property edSenderEmail: string read FedSenderEmail write FedSenderEmail;
    property edSenderName: string read FedSenderName write FedSenderName;
    property edReplyToEmail: string read FedReplyToEmail write FedReplyToEmail;
    property edSMTPServer: string read FedSMTPServer write FedSMTPServer;
    property edSMTPPort: Integer read FedSMTPPort write FedSMTPPort;
//    property edSSLConnection: Boolean read FedSSLConnection write FedSSLConnection;
    property edUseTLS: TIdUseTLS read FedUseTLS write FedUseTLS;
    property edAuthType: TIdSMTPAuthenticationType read FedAuthType write FedAuthType;
    property edToEmail: string read FedToEmail write FedToEmail;
    property edUserName: string read FedUserName write FedUserName;
    property edSubject: string read FedSubject write FedSubject;
    property edAttachFile: string read FedAttachFile write FedAttachFile;
    property edAttachList: TStrings read FedAttachList write SetAttachments;
    property edHTMLBody: Boolean read FedHTMLBody write FedHTMLBody;

  end;

implementation

uses
  SysUtils,
  IdTCPConnection, IdTCPClient,
  IdMessageClient, IdSMTPBase, IdBaseComponent, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdSASLLogin,
  IdSASL_CRAM_SHA1, IdSASL, IdSASLUserPass, IdSASL_CRAMBase, IdSASL_CRAM_MD5,
  IdSASLSKey, IdSASLPlain, IdSASLOTP, IdSASLExternal, IdSASLDigest,
  IdSASLAnonymous, IdUserPassProvider, IdAttachmentFile;

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
constructor TSSLEmail.Create;
begin
  inherited;

  Init;

  FedBody := TStringList.Create;
  FedAttachList := TStringList.Create;
  FedHTMLBody := FALSE;
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
procedure TSSLEmail.Init;
begin
  edUseTLS := utNoTLSSupport;
  edAuthType := satNone;
  edPriority := TIdMessagePriority.mpNormal;
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
procedure TSSLEmail.SetAttachments(const Value : TStrings);
begin
  FedAttachList.Assign(Value);
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
constructor TSSLEmail.Create(const ASMTPServer: String;
                             const ASMTPPort: Integer;
                             const AUserName, APassword: string);
begin
  Create;

  edSMTPServer := ASMTPServer;
  edSMTPPort := ASMTPPort;
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
destructor TSSLEmail.Destroy;
begin
  FedAttachList.Free;
  edBody.Free;

  inherited;
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
procedure TSSLEmail.SetBody(const Value: TStrings);
begin
  FedBody.Assign(Value);
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
function TSSLEmail.TestConnection : String;
begin
  result := '';

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
function TSSLEmail.SendEmail : String;
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
      SMTP.Host := edSMTPServer;
      SMTP.Port := edSMTPPort;
      SMTP.ConnectTimeout := 30000;
      SMTP.UseEHLO := True;
      try
        SMTP.Connect;

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
          SMTP.Disconnect;
        end;

      except
        on E: Exception do
        begin
          result := E.Message;
        end;
      end;

    finally
      SMTP.Free;
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
procedure TSSLEmail.InitMailMessage;
var
  i : Integer;

begin
  IdMessage.Charset := 'iso-8859-1';
  IdMessage.AttachmentEncoding := 'MIME';
  IdMessage.Encoding := meMIME;
  IdMessage.Body := edBody;
  IdMessage.Sender.Text := edSenderEmail;
  IdMessage.From.Name := edSenderName;
  IdMessage.From.Address := edSenderEmail;
  if (edReplyToEmail = '') then
    IdMessage.ReplyTo.EMailAddresses := edSenderEmail
  else
    IdMessage.ReplyTo.EMailAddresses := edReplyToEmail;
  IdMessage.Recipients.EMailAddresses := edToEmail;
  IdMessage.Subject := edSubject;
  IdMessage.Priority := edPriority;
  IdMessage.CCList.EMailAddresses := edCCEMail;
  IdMessage.ReceiptRecipient.Text := '';
  IdMessage.BccList.EMailAddresses := edBCCEMail;

  // Attachments are specified either in FedAttachList (TStrings) OR
  // in FedAttachFile (String).
  if (FedAttachList.Count > 0) then
  begin
    IdMessage.ContentType := 'multipart/mixed';
    for i := 0 to FedAttachList.Count-1 do
      if FileExists(FedAttachList[i]) then
        TIdAttachmentFile.Create(IdMessage.MessageParts, FedAttachList[i]);
  end // if
  else
    if ((FedAttachFile <> '') and
        (FileExists(FedAttachFile))) then
    begin
      IdMessage.ContentType := 'multipart/mixed';
      TIdAttachmentFile.Create(IdMessage.MessageParts, FedAttachFile)
    end // if
    else
      if (FedHTMLBody) then
        IdMessage.ContentType := 'text/html'
      else
        IdMessage.ContentType := 'text/plain';
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
procedure TSSLEmail.AddSSLHandler;
var
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(SMTP);
  // SSL/TLS handshake determines the highest available SSL/TLS version dynamically
  SSLHandler.SSLOptions.Method := sslvSSLv23;
  SSLHandler.SSLOptions.Mode := sslmClient;
  SSLHandler.SSLOptions.VerifyMode := [];
  SSLHandler.SSLOptions.VerifyDepth := 0;
  SMTP.IOHandler := SSLHandler;
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
procedure TSSLEmail.InitSASL;
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
  IdUserPassProvider := TIdUserPassProvider.Create(SMTP);
  IdUserPassProvider.Username := edUserName;
  IdUserPassProvider.Password:= edPassword;

  IdSASLCRAMSHA1 := TIdSASLCRAMSHA1.Create(SMTP);
  IdSASLCRAMSHA1.UserPassProvider := IdUserPassProvider;
  IdSASLCRAMMD5 := TIdSASLCRAMMD5.Create(SMTP);
  IdSASLCRAMMD5.UserPassProvider := IdUserPassProvider;
  IdSASLSKey := TIdSASLSKey.Create(SMTP);
  IdSASLSKey.UserPassProvider := IdUserPassProvider;
  IdSASLOTP := TIdSASLOTP.Create(SMTP);
  IdSASLOTP.UserPassProvider := IdUserPassProvider;
  IdSASLAnonymous := TIdSASLAnonymous.Create(SMTP);
  IdSASLExternal := TIdSASLExternal.Create(SMTP);
  IdSASLLogin := TIdSASLLogin.Create(SMTP);
  IdSASLLogin.UserPassProvider := IdUserPassProvider;
  IdSASLPlain := TIdSASLPlain.Create(SMTP);
  IdSASLPlain.UserPassProvider := IdUserPassProvider;

  SMTP.SASLMechanisms.Add.SASL := IdSASLCRAMSHA1;
  SMTP.SASLMechanisms.Add.SASL := IdSASLCRAMMD5;
  SMTP.SASLMechanisms.Add.SASL := IdSASLSKey;
  SMTP.SASLMechanisms.Add.SASL := IdSASLOTP;
  SMTP.SASLMechanisms.Add.SASL := IdSASLAnonymous;
  SMTP.SASLMechanisms.Add.SASL := IdSASLExternal;
  SMTP.SASLMechanisms.Add.SASL := IdSASLLogin;
  SMTP.SASLMechanisms.Add.SASL := IdSASLPlain;
end;

end.
