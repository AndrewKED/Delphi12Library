unit WinControl_Ops;

interface

uses
  Vcl.ComCtrls, Vcl.Controls;

type
  TREPutAction = (paAppend, paInsert, paReplace);

function REPutText(RE: TRichEdit; const Text: string; PutAction: TREPutAction): integer;
procedure FixTCalendarViewDate(Sender : TObject);

implementation

uses
  System.Classes, System.SysUtils,
  Winapi.Windows, Winapi.Messages,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.WinXCalendars,
  RichEdit;

const
  NullDate: TDate = -700000;    // Lifted from the implementation section of Vcl.WinXCalendars

var
  lastDate : TDateTime;

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

//***************************************************************************
//
//  FUNCTION  : FixTCalendarViewDate
//
//  I/P       : Sender : TObject - Typically the target TCalendarView.
//
//  O/P       : None.
//
//  OPERATION : "Fix" a null date when double-clicking a TCalendarVliew.
//
//              If TCalendarView.SelectionMode = smSingle, the .Date
//              property will toggle (between the selected date and NullDate)
//              with each click. This function overrides the toggle function.
//
//              Note : If TCalendarView.SelectionMode = smNone, the selected
//              date block does not get highlighted.
//
//  UPDATED   : 2023-07-04
//
//***************************************************************************
procedure FixTCalendarViewDate(Sender : TObject);
begin
  if ((Sender is TCalendarView) and
      (TCalendarView(Sender).SelectionMode = Vcl.WinXCalendars.TSelectionMode.smSingle)) then
  begin
    if (TCalendarView(Sender).Date = NullDate) then
    begin
      // Replace value that has toggled back to NullDate with the last chosen Date.
      if (lastDate <> NullDate) then
      begin
        TCalendarView(Sender).Date := lastDate;
      end // if
      else
      begin
        // Fallbacl - select today's date
        TCalendarView(Sender).Date := Date;
      end;
    end;
    lastDate := TCalendarView(Sender).Date;
  end;
end; // FixTCalendarViewDate

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
  lastDate := NullDate;

end.
