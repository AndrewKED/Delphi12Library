unit Email_Ops;

interface

const
  ID_SMTP_CONNSEC_NONE = 0;
  ID_SMTP_CONNSEC_STARTTLS = 1;
  ID_SMTP_CONNSEC_SSL_TLS = 2;

  ID_SMTP_AUTH_NONE = 0;
  ID_SMTP_AUTH_NORMAL = 1;
  ID_SMTP_AUTH_ENCRYPTED = 2;

procedure ConfigureEmail(host : String;
                         port : Integer;
                         userName : String;
                         password : String;
                         senderName : String;
                         senderEmail : String;
                         sslMode : Integer;
                         authentication : Integer);
function SentSimpleEmail(toList : String;
                         ccList : String;
                         subject : String;
                         body : String) : Boolean;

implementation

uses
  System.SysUtils,
  IndySecureMailClient, IdExplicitTLSClientServerBase, idSMTP;

var
  EMail : TSSLEmail;

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
procedure ConfigureEmail(host : String;
                         port : Integer;
                         userName : String;
                         password : String;
                         senderName : String;
                         senderEmail : String;
                         sslMode : Integer;
                         authentication : Integer);
begin
  FreeAndNil(Email);

  EMail := TSSLEmail.Create(host, port, userName, password);

  EMail.edSenderName := senderName;
  EMail.edSenderEmail := senderEmail;

  // Connection security
  case sslMode of
    ID_SMTP_CONNSEC_STARTTLS :
      EMail.edUseTLS := utUseExplicitTLS;
    ID_SMTP_CONNSEC_SSL_TLS :
      EMail.edUseTLS := utUseImplicitTLS;
    else
      EMail.edUseTLS := utNoTLSSupport;
  end; // case

  // Authentication
  case authentication of
    ID_SMTP_AUTH_ENCRYPTED :
      EMail.edAuthType := satSASL;
    ID_SMTP_AUTH_NORMAL :
      EMail.edAuthType := satDefault
    else
      EMail.edAuthType := satNone;
  end; // case
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
function SentSimpleEmail(toList : String;
                         ccList : String;
                         subject : String;
                         body : String) : Boolean;
begin
  Result := FALSE;

  if (Assigned(Email)) then
  begin
    try
      EMail.edBody.Clear;
      EMail.edAttachList.Clear;
      EMail.edToEmail := toList;
      EMail.edCCEmail := ccList;
      EMail.edBCCEmail := '';
      EMail.edSubject := subject;
      EMail.edBody.Add(body);
      EMail.SendEmail;
    finally
    end;
  end // if
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
initialization

finalization
  FreeAndNil(Email);

end.
