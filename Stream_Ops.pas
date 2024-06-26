unit Stream_Ops;

interface

uses
  System.Classes;

type
   TStreamEx = class helper for TStream
     procedure WriteString(const data: String);
     function ReadString : String;
   end;

procedure DeleteFromStream(Stream: TStream;
                           offsetStart : Int64;
                           lengthDelete : Int64);

implementation

uses
  System.Math;

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
procedure TStreamEx.WriteString(const data: String);
var
  len: cardinal;
  oString: UTF8String;

begin
   oString := UTF8String(data);
   len := length(oString);
   self.WriteBuffer(len, 4);
   if len > 0 then
     self.WriteBuffer(oString[1], len);
end; // WriteString

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
function TStreamEx.ReadString: String;
var
  len: integer;
  iString: UTF8String;

begin
  self.readBuffer(len, 4);
  if len > 0 then
  begin
    setLength(iString, len);
    self.ReadBuffer(iString[1], len);
    result := string(iString);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : DeleteFromStream
//
//  I/P       : Stream: TStream - The stream to be modified (read/write)
//
//              offsetStart : Int64 - The offset start of the data to delete
//
//              lengthDelete: Int64 - The number of bytes to be deleted.
//
//  O/P       : None
//
//  OPERATION : Lifted from https://stackoverflow.com/questions/9598032/is-it-possible-to-delete-bytes-from-the-beginning-of-a-file
//
//              This operation deletes a specified number of bytes from the
//              given offset in a stream.
//
//  UPDATED   : 2019-05-05
//
//***************************************************************************
procedure DeleteFromStream(Stream: TStream;
                           offsetStart : Int64;
                           lengthDelete : Int64);
var
  Buffer: Pointer;
  BufferSize: Integer;
  BytesToRead: Int64;
  BytesRemaining: Int64;
  posSource, posDest: Int64;

begin
  posSource := offsetStart + lengthDelete;
  posDest := offsetStart;
  BytesRemaining := Stream.Size - posSource;
  BufferSize := Min(BytesRemaining, 1024*1024*16); // No bigger than 16MB
  GetMem(Buffer, BufferSize);
  try
    while (BytesRemaining > 0) do
    begin
      BytesToRead := Min(BufferSize, BytesRemaining);
      Stream.Position := posSource;
      Stream.ReadBuffer(Buffer^, BytesToRead);
      Stream.Position := posDest;
      Stream.WriteBuffer(Buffer^, BytesToRead);
      Inc(posSource, BytesToRead);
      Inc(posDest, BytesToRead);
      Dec(BytesRemaining, BytesToRead);
    end;
    Stream.Size := posDest;
  finally
    FreeMem(Buffer);
  end;
end; // DeleteFromStream

end.
