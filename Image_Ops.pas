unit Image_Ops;

// Something nice for the future - Screen Capture
// http://mc-computing.com/Languages/Delphi/CaptureWindowImage.html
// https://stackoverflow.com/questions/661250/how-to-take-a-screenshot-of-the-active-window-in-delphi#661321

interface

uses
  System.SysUtils,
  Vcl.Dialogs, Vcl.Graphics;

function BMPFiletoJPGFile (BMPpic, JPGpic: string):boolean;
procedure SaveImage(bm : TBitMap;
                    fn : TFileName);

implementation

uses
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg;

//***************************************************************************
//
//  FUNCTION  : BMPFiletoJPGFile
//
//  I/P       : BMPpic : String - Filename of the input bitmap image
//
//              JPGpic: String - Filename to which the jpg image should be saved
//
//  O/P       : Boolean - TRUE if the operation completed correctly
//
//  OPERATION : From http://delphi.about.com/cs/adptips2001/a/bltip0301_3.htm
//
//  UPDATED   :
//
//***************************************************************************
function BMPFiletoJPGFile (BMPpic, JPGpic: String) : Boolean;
var
  Bitmap: TBitmap;
  JpegImg: TJPEGImage;

begin
  Result := False;

  Bitmap := TBitmap.Create;
  try
    Bitmap.LoadFromFile(BMPpic);
    JpegImg := TJPEGImage.Create;
    try
      JpegImg.Assign(Bitmap);
      // Set options here
      // JpegImg.PixelFormat :=jf24bit;
      // JpegImg.CompressionQuality := 100;
      // JpegImg.ProgressiveDisplay := False;
      // JpegImg.ProgressiveEncoding := False;
      JpegImg.SaveToFile(JPGpic);
      Result := True;
    finally
      JpegImg.Free
    end; // finally
  finally
    Bitmap.Free
  end; // finally
end; // BMPFiletoJPGFile

//***************************************************************************
//
//  FUNCTION  : SaveImage
//
//  I/P       : bm : TBitMap - the image to be saved
//
//              fn : TFileName - the target filename
//
//  O/P       : None
//
//  OPERATION : Give a BMP, save it to the given filename, using an output
//              format as indicated by the extension (JPG, PNG or BMP)
//
//  UPDATED   :
//
//***************************************************************************
procedure SaveImage(bm : TBitMap;
                    fn : TFileName);
var
  pngGraph : TPngImage;
  jpgGraph : TJPEGImage;

begin
  if ((ExtractFileExt(fn).ToLower = '.jpg') or
      (ExtractFileExt(fn).ToLower = '.jpeg') or
      (ExtractFileExt(fn).ToLower = '.jpe') or     // Apparently also applicable
      (ExtractFileExt(fn).ToLower = '.jfif') or    // Apparently also applicable
      (ExtractFileExt(fn).ToLower = '.jif')) then  // Apparently also applicable
  begin
    jpgGraph := TJPEGImage.Create;
    try
      jpgGraph.Assign(bm);
      jpgGraph.PixelFormat :=jf24bit;  // or jf8bit
      jpgGraph.CompressionQuality := 100;
      jpgGraph.ProgressiveDisplay := False;
      jpgGraph.ProgressiveEncoding := False;
      jpgGraph.SaveToFile(fn);
    finally
      jpgGraph.Free;
    end;
  end // if

  else if (ExtractFileExt(fn).ToLower = '.png') then
  begin
    pngGraph := TPNGImage.Create;
    try
      pngGraph.Assign(bm);
      pngGraph.SaveToFile(fn);
    finally
      pngGraph.Free;
    end;
  end // if

  else
  begin
    bm.SaveToFile(fn);
  end // else
end; // SaveImage

end.
