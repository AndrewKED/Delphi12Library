unit Image_Ops;

// Something nice for the future - Screen Capture
// http://mc-computing.com/Languages/Delphi/CaptureWindowImage.html
// https://stackoverflow.com/questions/661250/how-to-take-a-screenshot-of-the-active-window-in-delphi#661321

interface

function BMPtoJPG (BMPpic, JPGpic: string):boolean;

implementation

uses
  Graphics, Jpeg_Ops;

//***************************************************************************
//
//  FUNCTION  : BMPtoJPG
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From http://delphi.about.com/cs/adptips2001/a/bltip0301_3.htm
//
//  UPDATED   :
//
//***************************************************************************
function BMPtoJPG (BMPpic, JPGpic: string) : boolean;
var
  Bitmap: TBitmap;
  JpegImg: TJpegImage;

begin
  Result := False;
  Bitmap := TBitmap.Create;
  try
    Bitmap.LoadFromFile(BMPpic);
    JpegImg := TJpegImage.Create;
    try
      JpegImg.Assign(Bitmap);
      JpegImg.SaveToFile(JPGpic);
      Result := True;
    finally
      JpegImg.Free
    end; // finally
  finally
    Bitmap.Free
  end; // finally
end;


end.
