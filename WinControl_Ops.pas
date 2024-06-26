unit WinControl_Ops;

interface

uses
  Vcl.ComCtrls, Vcl.Controls;

type
  TREPutAction = (paAppend, paInsert, paReplace);

function REPutText(RE: TRichEdit; const Text: string; PutAction: TREPutAction): integer;

implementation

uses
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Classes, Winapi.Windows,
  Winapi.Messages, System.SysUtils,
  RichEdit;



//***************************************************************************
//
//  FUNCTION  : EditStreamCallback
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Part of inserting RichText into a TRichEdit (see below)
//              From http://www.delphipages.com/forum/showthread.php?t=133683
//              Not working yet
//              See also http://delphidabbler.com/tips/57
//
//  UPDATED   : 2017-05-10
//
//***************************************************************************
function EditStreamCallback(dwCookie: Longint; pbBuff: PByte;
                           cb: Longint; var pcb: Longint): Longint;
stdcall;
var
  MS : TMemoryStream;

begin
  // dwCookie is Application-defined,
  // so we're passing the stream containing
  // the formatted text to be added.
  //
  MS := TMemoryStream(dwCookie);
  result := 0;

  with MS do
  begin
    if (Size = position) then
    begin
      pcb := 0;
      Exit;
    end
    else
    if (Size - Position) <= cb then
    begin
      pcb := Size;
      Read(pbBuff^, Size);
    end
    else
    begin
      pcb := cb;
      Read(pbBuff^, cb);
    end;
  end;
end; // EditStreamCallback

//***************************************************************************
//
//  FUNCTION  : REFetchText
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Part of inserting RichText into a TRichEdit (see below)
//              From http://www.delphipages.com/forum/showthread.php?t=133683
//
//  UPDATED   : 2017-05-10
//
//***************************************************************************
function REFetchText(RE: TRichEdit; const Text: string): integer;
var
  ES : TEditStream;
  MS :  TMemoryStream;

begin
  MS := TMemoryStream.Create;
  try
    MS.Write(Text[1], Length(Text));
    MS.Seek(0, soFromBeginning);

    ES.dwCookie    := longint(MS);
    ES.dwError     := 0;
    ES.pfnCallback := @EditStreamCallback;

    result := SendMessage(RE.Handle, EM_STREAMIN, SF_RTF or SFF_SELECTION,
                          longint(@ES));
  finally
    MS.Free;
  end;
end; // REFetchText

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Use with the 2 functions above to insert RichText into a
//              TRichEdit control
//              From http://www.delphipages.com/forum/showthread.php?t=133683
//
//  UPDATED   : 2017-05-10
//
//***************************************************************************
function REPutText(RE: TRichEdit; const Text: string; PutAction: TREPutAction): integer;
begin
  result := -1;

  if Text = '' then
    exit;

  case PutAction of
    paAppend  :
    begin
      RE.Lines.Append(' ');

      RE.SelStart :=  SendMessage(RE.Handle, EM_LINEINDEX, RE.Lines.Count - 1, 0);
      RE.SelLength := 1;
    end; // option

    paInsert  :
    begin
      if RE.SelLength > 0 then
        RE.SelText := RE.SelText +#32
      else
        RE.SelText := #32;

      RE.SelStart := RE.SelStart +RE.SelLength -1;
      RE.SelLength := 1;
    end; // option

    paReplace :
    begin
      if RE.SelLength > 0 then
        RE.SelText := #32;
    end; // option
  end;

  Result := REFetchText(RE, Text);
end; // REPutText

//***************************************************************************
//
//  FUNCTION  : REAppendFile
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Use with the 2 functions above to append RichText from a file
//              to the end of a TRichEdit control
//              From http://www.delphipages.com/forum/showthread.php?t=133683
//
//  UPDATED   : 2017-05-10
//
//***************************************************************************
function REAppendFile(RE: TRichEdit; const Filename: string): integer;
var
  FS : TFileStream;
  len : int64;
  s : string;

begin
 result := -1;
 s := '';

 FS := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
 try
   len := FS.Size;
   if len > 0 then
   begin
     FS.Position := 0;
     SetLength(s, len);
     FS.Read(s[1], len);
   end;
 finally
   FS.Free;
 end;

 if s <> '' then
   result := REPutText(RE, s, paAppend);
end; // REAppendFile

end.
