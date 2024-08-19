UNIT File_Ops;

//***************************************************************************
//
// DESCRIPTION:
// Provides a number of helpful file handling functions and procedures.
//
//***************************************************************************

//*****************************************************************************
// REFERENCES"
//  Delphi Tutorial: Using FindFirstFile and FindNextFile
//    http://www.jpgriffiths.com/tutorial/api/findfirstfile.html#_Toc34008277
//
//*****************************************************************************

INTERFACE

uses Classes, SysUtils, ComCtrls, Forms, Types;

const
//  faANSReadOnly = $00000001;    // Delphi 5 has 2 faReadOnly constants
                                // One for Field Attributes and one for File Attributes
                                // Put unit DB before SysUtils in the uses clause
                                // Similar for faHidden.

  // File_Ops error codes
  FOE_NONE = 0;
  FOE_NO_SOURCE_FILE_SPECIFIED = -1;
  FOE_NO_DEST_FILE_SPECIFIED = -2;
  FOE_COULD_NOT_MAKE_DEST = -3;
  FOE_INVALID_PATH = -4;
  FOE_INVALID_TARGET = -5;
  FOE_FOLDER_NOT_DELETED = -6;
  FOE_FILE_NOT_DELETED = -7;
  FOE_NO_FILE_SPECIFIED = -8;
type
  TCharArray = array of char;
  TFolderNameType = (fnNormal, fnInFolder, fnForEditing, fnForAddressBar, fnForParsing);

function Filename_83Valid (filename : string) : boolean;
function FilenameValid(sFileName : string) : boolean;
function FileCopied (source, dest :string;
                     pbProgress : TProgressBar) : Integer;
function FileAppended (source, dest : string) : boolean;
function FileExtracted (source, dest : String; offset,size : longint) : boolean;
function DeletedFiles (filename : String;
                       delete_also : Integer;
                       dtOlder : TDateTime) : Integer;
procedure TestFilesMatch (sFile1, sFile2 :string;
                          var iErrorOffset : Integer;
                          var iFileResult : integer);
procedure GetCRC8(aBuffer : TCharArray;
                  iSize : Integer;
                  var bCRC8 : byte);
function File8BitCRC (filename : string) : byte;
procedure CalcCRC16 (p : pByte;
                     wNumBytes : word;
                     var CRCvalue: word);
procedure CalcCRC32 (p : pointer;
                     dwNumBytes : dword;
                     var CRCValue: dword);
function FileInUse (sFileName : string) : boolean;
procedure Equate_File_DateTime(source, dest : string);
function XCopyFiles(source : String;
                    dest_dir : String;
                    recurse : boolean;
                    create_empty : boolean;
                    bAlwaysOverwrite : boolean;
                    newer_only : boolean;
                    set_attr : Integer;
                    clear_attr : integer) : Integer;
function XDeleteFiles(target : String;
                      delete_also : Integer;
                      dtOlder : TDateTime) : Integer;
procedure FindAllFiles(sMask : String;
                       iAttr : Integer;
                       bDrillDown : boolean;
                       bProperties : boolean;
                       slResult : TStringList);
//function FileTimeToDateTime(ftFileTime : TFileTime) : TDateTime;
function GetAssociatedEXEFile(FName: String) : String;
function WroteToTextFile(strInput : TStrings;
                         sFileName : string) : boolean;
function ReadStrFromTextFile(var sInput : String;
                             sLineBreak : String;
                             sFileName : string) : boolean;
function IOResultTest(bNewTest : boolean) : boolean;
function IOResultString(iIOError : integer = -1) : String;
function LastIOResultMessage(bNewTest : boolean) : String;
function LastIOResultNumber(bNewTest : boolean) : Integer;
function CountFiles(sMask : String;
                    iAttr : integer) : Integer;
function XCountFiles(sMask : String;
                     iAttr : integer) : Integer;
function SizeOfFile (sFileName : string) : Int64;
function SizeOfFiles(sMask : String;
                     iAttr : integer) : Integer;
function XSizeOfFiles(sMask : String;
                      iAttr : integer) : Integer;
procedure SplitFile(FileName : TFileName; FilesByteSize : Integer);
procedure MergeFiles(FirstSplitFileName, OutFileName : TFileName);
function AlternateToLFN(AltName:String):String;
function LFNToAlternate(LongName:String):String;
function GetNetworkDriveMappings(SList: TStrings;
                                 allRemembered : Boolean): integer;
procedure ListDrivesOfType(DriveType : Cardinal;
                           var Drives : TStringList);
function IsOnLocalDrive(aFileName: string): Boolean;
function LongestTextLine(sFileName : string) : Integer;
function GetTempFolder : String;
function GetFileResourceString(sFileName : String;
                               sVersionKey : string) : String;
function FolderEmpty(sDirectory : string) : boolean;
//function ShellCopy(sFileNames : String;
//                   sDestination : string) : boolean;
//returns true if a given directory is empty, false otherwise
function FolderIsEmpty(const sFolder : string) : boolean;
function GetParentFolder(sPath : string) : String;
procedure GetSubFolders(const sFolder : String;
                        sList : TStrings);
procedure DateTimeInfo(const sPath : String;
                       const iFileAttributes : Integer;
                       var dtCreated : TDateTime;
                       var dtLastAccessed : TDateTime;
                       var dtLastWriten : TDateTime;
                       var dtLastModified : TDateTime);
procedure InitGetFolderSize;
function GetFolderSize(sFolder:string) : Integer;
function DelTree(DirName : string): boolean;
function GetSpecialFolderPath(iFolder : integer) : String;
function GetDriveSerialNo(sDrive : string) : String;
function MovedFolder(folderSrc : String;
                     folderDest : String) : Boolean;
function GetTextFileEncoding(sFileName : string) : TEncoding;
function GetTemporaryFolder(Folder : string) : String;
function RefreshMappedDrive(cDrvLetter: Char): Boolean;
procedure RefreshAllMappedDrives;
function FilesBackedUp(pathSource : String;
                       pathDestination : String) : Boolean;
procedure FilesSortedAlphabetically(const path : String;
                                    attr : Integer;
                                    aProgressBar : TProgressBar;
                                    const filesFound : TStringList);
function FileExistsA(const path : String;
                     attr : Integer) : Boolean;
function FileErrorText(idError : Integer) : String;
function IsFileInUse(FileName: TFileName): Boolean;

{=============================================================================}

implementation

uses
  WinProcs, Math, DateUtils, ShlObj, ActiveX,
  System.Win.ComObj, System.Variants, System.IOUtils,
  ShellAPI, Registry, IniFiles,
  WinAPI.Windows,
  Str_Ops, Ini_Ops;

const
  CrcTable08 : array[0..255] of byte =
    (0,   94,  188, 226, 97,  63,  221, 131, 194, 156, 126, 32,  163, 253, 31,  65,
     157, 195, 33,  127, 252, 162, 64,  30,  95,  1,   227, 189, 62,  96,  130, 220,
     35,  125, 159, 193, 66,  28,  254, 160, 225, 191, 93,  3,   128, 222, 60,  98,
     190, 224, 2,   92,  223, 129, 99,  61,  124, 34,  192, 158, 29,  67,  161, 255,
     70,  24,  250, 164, 39,  121, 155, 197, 132, 218, 56,  102, 229, 187, 89,  7,
     219, 133, 103, 57,  186, 228, 6,   88,  25,  71,  165, 251, 120, 38,  196, 154,
     101, 59,  217, 135, 4,   90,  184, 230, 167, 249, 27,  69,  198, 152, 122, 36,
     248, 166, 68,  26,  153, 199, 37,  123, 58,  100, 134, 216, 91,  5,   231, 185,
     140, 210, 48,  110, 237, 179, 81,  15,  78,  16,  242, 172, 47,  113, 147, 205,
     17,  79,  173, 243, 112, 46,  204, 146, 211, 141, 111, 49,  178, 236, 14,  80,
     175, 241, 19,  77,  206, 144, 114, 44,  109, 51,  209, 143, 12,  82,  176, 238,
     50,  108, 142, 208, 83,  13,  239, 177, 240, 174, 76,  18,  145, 207, 45,  115,
     202, 148, 118, 40,  171, 245, 23,  73,  8,   86,  180, 234, 105, 55,  213, 139,
     87,  9,   235, 181, 54,  104, 138, 212, 149, 203, 41,  119, 244, 170, 72,  22,
     233, 183, 85,  11,  136, 214, 52,  106, 43,  117, 151, 201, 74,  20,  246, 168,
     116, 42,  200, 150, 21,  75,  169, 247, 182, 232, 10,  84,  215, 137, 107, 53);

  // Source : http://www.efg2.com/Lab/Mathematics/CRC.htm
  CrcTable16 : array[0..255] of word =
    ($0000,$C0C1,$C181,$0140,$C301,$03C0,$0280,$C241,$C601,$06C0,$0780,
     $C741,$0500,$C5C1,$C481,$0440,$CC01,$0CC0,$0D80,$CD41,$0F00,$CFC1,
     $CE81,$0E40,$0A00,$CAC1,$CB81,$0B40,$C901,$09C0,$0880,$C841,$D801,
     $18C0,$1980,$D941,$1B00,$DBC1,$DA81,$1A40,$1E00,$DEC1,$DF81,$1F40,
     $DD01,$1DC0,$1C80,$DC41,$1400,$D4C1,$D581,$1540,$D701,$17C0,$1680,
     $D641,$D201,$12C0,$1380,$D341,$1100,$D1C1,$D081,$1040,$F001,$30C0,
     $3180,$F141,$3300,$F3C1,$F281,$3240,$3600,$F6C1,$F781,$3740,$F501,
     $35C0,$3480,$F441,$3C00,$FCC1,$FD81,$3D40,$FF01,$3FC0,$3E80,$FE41,
     $FA01,$3AC0,$3B80,$FB41,$3900,$F9C1,$F881,$3840,$2800,$E8C1,$E981,
     $2940,$EB01,$2BC0,$2A80,$EA41,$EE01,$2EC0,$2F80,$EF41,$2D00,$EDC1,
     $EC81,$2C40,$E401,$24C0,$2580,$E541,$2700,$E7C1,$E681,$2640,$2200,
     $E2C1,$E381,$2340,$E101,$21C0,$2080,$E041,$A001,$60C0,$6180,$A141,
     $6300,$A3C1,$A281,$6240,$6600,$A6C1,$A781,$6740,$A501,$65C0,$6480,
     $A441,$6C00,$ACC1,$AD81,$6D40,$AF01,$6FC0,$6E80,$AE41,$AA01,$6AC0,
     $6B80,$AB41,$6900,$A9C1,$A881,$6840,$7800,$B8C1,$B981,$7940,$BB01,
     $7BC0,$7A80,$BA41,$BE01,$7EC0,$7F80,$BF41,$7D00,$BDC1,$BC81,$7C40,
     $B401,$74C0,$7580,$B541,$7700,$B7C1,$B681,$7640,$7200,$B2C1,$B381,
     $7340,$B101,$71C0,$7080,$B041,$5000,$90C1,$9181,$5140,$9301,$53C0,
     $5280,$9241,$9601,$56C0,$5780,$9741,$5500,$95C1,$9481,$5440,$9C01,
     $5CC0,$5D80,$9D41,$5F00,$9FC1,$9E81,$5E40,$5A00,$9AC1,$9B81,$5B40,
     $9901,$59C0,$5880,$9841,$8801,$48C0,$4980,$8941,$4B00,$8BC1,$8A81,
     $4A40,$4E00,$8EC1,$8F81,$4F40,$8D01,$4DC0,$4C80,$8C41,$4400,$84C1,
     $8581,$4540,$8701,$47C0,$4680,$8641,$8201,$42C0,$4380,$8341,$4100,
     $81C1,$8081,$4040);

  // Source : http://www.efg2.com/Lab/Mathematics/CRC.htm
  // which states
  // "The constants here are for the CRC-32 generator polynomial,
  // as defined in the Microsoft Systems Journal, March 1995, pp. 107-108"
  CrcTable32 : array[0..255] of dword =
    ($00000000, $77073096, $EE0E612C, $990951BA,
     $076DC419, $706AF48F, $E963A535, $9E6495A3,
     $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988,
     $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
     $1DB71064, $6AB020F2, $F3B97148, $84BE41DE,
     $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
     $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC,
     $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
     $3B6E20C8, $4C69105E, $D56041E4, $A2677172,
     $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
     $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940,
     $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
     $26D930AC, $51DE003A, $C8D75180, $BFD06116,
     $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
     $2802B89E, $5F058808, $C60CD9B2, $B10BE924,
     $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,

     $76DC4190, $01DB7106, $98D220BC, $EFD5102A,
     $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
     $7807C9A2, $0F00F934, $9609A88E, $E10E9818,
     $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
     $6B6B51F4, $1C6C6162, $856530D8, $F262004E,
     $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
     $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C,
     $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
     $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2,
     $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
     $4369E96A, $346ED9FC, $AD678846, $DA60B8D0,
     $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
     $5005713C, $270241AA, $BE0B1010, $C90C2086,
     $5768B525, $206F85B3, $B966D409, $CE61E49F,
     $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4,
     $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,

     $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A,
     $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
     $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8,
     $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
     $F00F9344, $8708A3D2, $1E01F268, $6906C2FE,
     $F762575D, $806567CB, $196C3671, $6E6B06E7,
     $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC,
     $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
     $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252,
     $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
     $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60,
     $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
     $CB61B38C, $BC66831A, $256FD2A0, $5268E236,
     $CC0C7795, $BB0B4703, $220216B9, $5505262F,
     $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04,
     $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,

     $9B64C2B0, $EC63F226, $756AA39C, $026D930A,
     $9C0906A9, $EB0E363F, $72076785, $05005713,
     $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38,
     $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
     $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E,
     $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
     $88085AE6, $FF0F6A70, $66063BCA, $11010B5C,
     $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
     $A00AE278, $D70DD2EE, $4E048354, $3903B3C2,
     $A7672661, $D06016F7, $4969474D, $3E6E77DB,
     $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0,
     $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
     $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6,
     $BAD03605, $CDD70693, $54DE5729, $23D967BF,
     $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94,
     $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);

var
  iLastIOResult : Integer;
  iDirBytes : Integer;

//***************************************************************************}
//
//  FUNCTION    :   Filename_83Valid
//
//  I/P         :   filename (string) - The (8.3-format) file name to be
//                          tested.
//
//  O/P         :   (boolean) - TRUE if the given file name is a valid
//                          8.3 name.
//
//  OPERATION   :   Tests the length, position of the extension delimitter
//                      and presence of invalid characters.
//
//  UPDATED     :   2003/05/23
//
//***************************************************************************}
function Filename_83Valid (filename : string) : boolean;
var
    n : byte;
begin
  // Check size and position of '.'
  result := TRUE;
  if ((Length(filename) > 12) or
      (Length(filename) = 0) or
      ((Pos('.',filename) <> 0) and
       ((Pos('.',filename) = 1) or
        (Pos('.',filename) = Length(filename)) or
        (Pos('.',filename) < Length(filename)-4)))) then
    result := FALSE;

  for n := 1 to Length(filename) do
  begin
    // Search for illegal characters - source MS DOS user's guide}
                                {'_' added by me}
    if not (CharInSet(filename[n],['A'..'Z','a'..'z','0'..'9','$','%','''','-','@','{','}','~','`','!','#','(',')','&','_','.'])) then
      result := FALSE;
    // Search for more than one '.'
    if (filename[n]='.') and
       (n<>Pos('.',filename)) then
      result := FALSE;
    end; // for
end; {Filename_Valid}

//***************************************************************************
//
//  FUNCTION  : FilenameValid
//
//  I/P       : sFileName (string) - The filename (excluding path) to be tested.
//
//  O/P       : (boolean) - FALSE if the filename is an empty string or
//                contains one of a number of invalid characters
//
//  OPERATION : Checks the filename for validity.
//
//              Disallow for space-only filenames.
//
//  UPDATED   : 2024-08-19
//
//***************************************************************************
function FilenameValid(sFileName : string) : boolean;
begin
  // Reducing all spaces in the given filename should not result in an
  // empty string or extension separator
  sFileName := SearchAndReplace(sFileName,' ','');
  result := (sFileName <> '') and
            (sFileName <> '.') and
            (TPath.HasValidFileNameChars(sFileName, FALSE));
end; // FilenameValid

//***************************************************************************}
//
// FUNCTION   : FileCopied
//
// I/P        : source, dest (string) - The full name of the source
//                and destination files.
//
//              pbProgress (TProgressBar) - Set to indicate a progress bar
//                that will show progress through the operation, or else nil.
//
// O/P        : (integer) - 0 if OK, negative for ANS errors and positive
//                for system IO errors.
//
// OPERATION  : Attempts to copy the source file to destination.
//              Overwrites ANY file of the same name (including Read-Only,
//              Hidden or System files)
//
// UPDATED    : 2008-02-11
//
//***************************************************************************}
function FileCopied (source, dest :string;
                     pbProgress : TProgressBar) : Integer;
var
  FromF, ToF: file;
  NumRead, NumWritten: Integer;
  Buf: array[1..2048] of Char;
  iBytesWritten : Integer;

begin
  // Ensure that the source file is specified
  if (source <> '') then
  begin
    AssignFile(FromF, source);
    {$I-}
    Reset(FromF, 1);		          {Record size = 1}
    {$I+}
    // Check that we could get hold of the file
    result := IOResult;
    if (result = 0) then
    begin

      // Set up the progress bar, if one is being used.
      if (pbProgress <> nil) then
      begin
        pbProgress.Max := FileSize(FromF);
        pbProgress.Position := 0;
      end; // if

      // Ensure that the destination file is specified
      if (dest <> '') then
      begin
        // This deletion operation gets rid of any existing files with a
        // read-only attribute (otherwise Rewrite fails with error 5)
        if (SysUtils.FileExists(dest)) then
          DeletedFiles(dest, faReadOnly+faHidden+faSysFile+faArchive,0.0);

        AssignFile(ToF, dest);	  {Open output file}
        {$I-}
        Rewrite(ToF, 1);  	      {Record size = 1}
        {$I+}
        // Check that we could create the file
        result := IOResult;
        if (result=0) then
        begin
          iBytesWritten := 0;
          repeat
            BlockRead(FromF, Buf, SizeOf(Buf), NumRead);
            BlockWrite(ToF, Buf, NumRead, NumWritten);
            Inc(iBytesWritten,NumWritten);

            // Update the progress bar, if one is being used
            if (pbProgress <> nil) then
            begin
              pbProgress.Position := iBytesWritten;
              pbProgress.Update;
            end;

          until (NumRead = 0) or (NumWritten <> NumRead);
          System.CloseFile(ToF);
        end; // if
      end // if
      else
        // Destination file name was empty
        result := FOE_NO_DEST_FILE_SPECIFIED;
      System.CloseFile(FromF);
    end; // if
  end // if
  else
    // Source file name was empty
    result := FOE_NO_SOURCE_FILE_SPECIFIED;
end; {FileCopied}

{****************************************************************************}
{*
{*      FUNCTION    :   FileAppended
{*
{*      I/P         :   source, dest (string) - The full name of the source
{*                          and destination files.
{*
{*      O/P         :   (boolean) - TRUE if the function completed correctly
{*
{*      CALLS       :   None.
{*
{*      OPERATION   :   Attempts to append the source file to destination.
{*
{*      UPDATED     :   29/06/1998
{*
{****************************************************************************}
function FileAppended (source, dest :string) : boolean;
var
  FromF, ToF: file;
  NumRead, NumWritten: Integer;
  Buf: array[1..2048] of Char;
begin
  result := TRUE;                 {Assume we complete the operation OK}

  if (source<>'') then            {Ensure that the source file is a disc file}
  begin                           {(See Help on AssignFile)}
    AssignFile(FromF, source);
    {$I-}
    Reset(FromF, 1);		          {Record size = 1}
    {$I+}
    if (IOResult=0) then          {Check that we could get hold of the file}
    begin
      if (dest<>'') then          {Ensure that the destination file is a disc file}
      begin
        AssignFile(ToF, dest);	  {Open output file}
        if (SysUtils.FileExists(dest)) then
        begin
          {$I-}                   {If the file exists, reset it}
          Reset(ToF, 1);          {Record size = 1}
          {$I+}
        end // if
        else
        begin
          {$I-}                   {If the file does not exist, then create it}
          Rewrite(ToF, 1);        {Record size = 1}
          {$I+}
        end; // else

        if (IOResult=0) then      {Check that we could create the file}
        begin
          Seek(ToF,FileSize(ToF));  {Move to the end of the destination file}
          repeat
            BlockRead(FromF, Buf, SizeOf(Buf), NumRead);
            BlockWrite(ToF, Buf, NumRead, NumWritten);
          until (NumRead = 0) or (NumWritten <> NumRead);
          System.CloseFile(ToF);
        end // if
        else
          result := FALSE;        {I/O error in accessing the destination file}
      end // if
      else
        result := FALSE;          {Destination file name did not specify a file}
      System.CloseFile(FromF);
    end // if
    else
      result := FALSE;            {I/O error in accessing the source file}
  end // if
  else
    result := FALSE;              {Source file name did not specify a file}
end; {FileAppended}

{****************************************************************************}
{*
{*      FUNCTION    :   FileExtracted
{*
{*      I/P         :   source, dest (string) - The full name of the source
{*                          and destination files.
{*
{*                      offset (longint) - The offset within the source file
{*                          of the start of the block to be extracted.
{*
{*                      size (longint) - The size of the block to be
{*                          extracted.  (=MAXLONGINT to read to end of file}
{*
{*      O/P         :   (boolean) - TRUE if the function completed correctly
{*
{*      CALLS       :   None.
{*
{*      OPERATION   :   Attempts to extract a block of data from a given file
{*                      to a destination file.
{*
{*      UPDATED     :   30/06/1998
{*
{****************************************************************************}
function FileExtracted (source, dest : String; offset,size : longint) : boolean;
var
  FromF, ToF: file;
  NumRead, NumWritten: Integer;
  Buf: array[1..2048] of Char;
  this_read : word;               {Required size of the current read operation}
begin
  result := TRUE;                 {Assume we complete the operation OK}

  if (source<>'') then            {Ensure that the source file is a disc file}
  begin                           {(See Help on AssignFile)}
    AssignFile(FromF, source);
    {$I-}
    Reset(FromF, 1);		          {Record size = 1}
    {$I+}
    if (IOResult=0) then          {Check that we could get hold of the file}
    begin
      if (dest<>'') then          {Ensure that the destination file is a disc file}
      begin
        AssignFile(ToF, dest);	  {Create the output file}
        {$I-}
        Rewrite(ToF, 1);          {Record size = 1}
        {$I+}

        if (IOResult=0) then      {Check that we could create the file}
        begin
          Seek(FromF,offset);     {Move to the offset of the block to extract}
          repeat

            if (size>SizeOf(Buf)) then  {Work out how many bytes to be read}
              this_read := SizeOf(Buf)
            else
              this_read := size;
                                        {Do the transfer}
            BlockRead(FromF, Buf, this_read, NumRead);
            BlockWrite(ToF, Buf, NumRead, NumWritten);

            size := size - NumRead;     {Decrease the size of block still to do}

          until (size<=0) or (NumRead = 0) or (NumWritten <> NumRead);

          if (NumWritten<>NumRead) then {Check whether the disc became full}
            result := FALSE;            {during the transfer}

          System.CloseFile(ToF);
        end // if
        else
          result := FALSE;        {I/O error in accessing the destination file}
      end // if
      else
        result := FALSE;          {Destination file name did not specify a file}
      System.CloseFile(FromF);
    end // if
    else
      result := FALSE;            {I/O error in accessing the source file}
  end // if
  else
    result := FALSE;              {Source file name did not specify a file}
end; {FileExtracted}

//***************************************************************************}
//
//  FUNCTION    :   DeletedFiles
//
//  I/P         :   filename (string) - Full path and filename of the
//                    file to be deleted.   Wildcards may be used int
//                    the filename for multiple file deletiong.
//
//                  delete_also (integer) - Or-ed file attributes for the
//                    deletion of ReadOnly, System, Hidden files etc.
//
//                  dtOlder (TDateTime) - Only delete the files if they
//                    are older than this date/time.   Delete all files
//                    if this value is 0.0;
//
//  O/P         :   (integer) - FOE_NONE if OK, else an error code
//
//  CALLS       :   None.
//
//  OPERATION   :   Deletes all files that match the given filename.
//
//  UPDATED     :   2005/12/12
//
//***************************************************************************}
function DeletedFiles (filename : String;
                       delete_also : Integer;
                       dtOlder : TDateTime) : Integer;
var
  sr : Integer;
  SearchRec : TSearchRec;
  sDeleteFile : String;
begin
  // Assume it all works
  result := FOE_NONE;

  sr := FindFirst(filename,faReadOnly+faHidden+faSysFile+faArchive,SearchRec);
  while ((sr=0) and
         (result = FOE_NONE)) do
  begin
    sDeleteFile := ExtractFilePath(filename);
    sDeleteFile := sDeleteFile + SearchRec.Name;
    FileSetAttr(ExtractFilePath(filename) + SearchRec.Name,
                SearchRec.Attr and (not (delete_also)));
    if (not SysUtils.DeleteFile(sDeleteFile)) then
      result := FOE_FILE_NOT_DELETED;
    sr := FindNext(SearchRec);
  end; // while
  SysUtils.FindClose(SearchRec);
end; // DeletedFiles

//***************************************************************************}
//
// FUNCTION   : TestFilesMatch
//
// I/P        : sFile1, sFile2 (string) - The full name of the two files that
//                are to be compared.
//
// O/P        : iErrorOffset (integer) - negative if the files match.
//                Otherwise this indicates the offset to the first mismatch.
//                If one file is longer than the other, this value returns the
//                offset to the first byte after the shorter file.
//
//              iFileResult (integer) - Indicates any errors in accessing the
//                two files.   FOE_NONE if both files were correctly accessed.
//
// OPERATION  : Attempts to copy the source file to destination.
//              Overwrites any file of the same name.
//
// UPDATED    : 2006/01/16
//
//***************************************************************************}
procedure TestFilesMatch (sFile1, sFile2 :string;
                          var iErrorOffset : Integer;
                          var iFileResult : integer);
var
  fFile1, fFile2: file;
  iNumRead1, iNumRead2 : Integer;
  acBuf1, acBuf2: array[0..2047] of Char;
  iFileOffset : Integer;
  bCompareError : boolean;
  iCompareSize : Integer;
  n : Integer;
begin
  iFileOffset := 0;
  iErrorOffset := -1;
  iFileResult := FOE_NONE;

  // Ensure that both files are specified
  if ((sFile1='') or (sFile2='')) then
        // Source file name was empty
    iFileResult := FOE_NO_FILE_SPECIFIED
  else
  begin
    AssignFile(fFile1, sFile1);
    {$I-}
    Reset(fFile1, 1);
    {$I+}
    // Check that we could get hold of the first file
    iFileResult := IOResult;
    if (iFileResult = 0) then
    begin

      AssignFile(fFile2, sFile2);
      {$I-}
      Reset(fFile2, 1);
      {$I+}
      // Check that we could get hold of the second file
      iFileResult := IOResult;
      if (iFileResult = 0) then
      begin
        bCompareError := FALSE;
        repeat
          // Read in the next block of data to be compared
          BlockRead(fFile1, acBuf1, SizeOf(acBuf1), iNumRead1);
          BlockRead(fFile2, acBuf2, SizeOf(acBuf2), iNumRead2);

          // Compare the blocks of data, up to the end of the shortest
          iCompareSize := Min(iNumRead1,iNumRead2);

          // Do a fast block comparison
          if (not CompareMem(@acBuf1[0],@acBuf2[0],iCompareSize)) then
          begin
            // If the block comparison shows a mismatch, find the
            // position of the mismatch, using a slower scanning.
            n := 0;
            while ((not bCompareError) and
                   (n < iCompareSize)) do
            begin
              if (acBuf1[n] <> acBuf2[n]) then
              begin
                bCompareError := TRUE;
                iErrorOffset := iFileOffset + n;
              end; // if
              Inc(n);
            end; // while
          end; // if
          iFileOffset := iFileOffset + iCompareSize;

          // Check for the case where the files are of different sizes
          if ((not bCompareError) and (iNumRead1 <> iNumRead2)) then
          begin
            bCompareError := TRUE;
            iErrorOffset := iFileOffset;
          end; // if

        until ((bCompareError) or (iNumRead1 = 0) or (iNumRead2 = 0));
        System.CloseFile(fFile2);
      end; // if
      System.CloseFile(fFile1);
    end; // if
  end; // if
end; // FilesMatch

//***************************************************************************
//
//  FUNCTION    :   GetCRC8
//
//  I/P         :   aBuffer (TCharArray) - Block of data to be CRCed.
//
//                  iSize (integer) - The number of bytes to be CRCed.
//                    Note : This must fit on the stack.
//
//                  bCRC8 (byte) - The running 8-bit CRC
//
//  O/P         :
//
//  OPERATION   :   Includes the indicated block of data in the CRC8
//
//  UPDATED     :   2005/06/02
//
//***************************************************************************
procedure GetCRC8(aBuffer : TCharArray;
                  iSize : Integer;
                  var bCRC8 : byte);
var
  index : byte;
  n : Integer;
begin
  for n := 0 to iSize-1 do
  begin
    index := bCRC8 xor Ord(aBuffer[n]);
    bCRC8 := CrcTable08[index];
  end; // if
end; // GetCRC8

//***************************************************************************
//
//  FUNCTION  : CalcCRC16
//
//  I/P       : p : pByte - Pointer to the block of data to be CRC-ed
//
//              wNumBytes : word - The number of bytes to be CRCed.
//
//              CRCvalue : word - Initialised CRC-16 (to zero for first use)
//                This permits multiple calls to this routine
//
//  O/P       : CRCvalue : word - The resultant CRC-16
//
//                From the source webpage : The initial value could be
//                  Method 1 : $0000
//                  Method 2 : $FFFF (with an inversion of the result at the end)
//
//  OPERATION : The following is a little cryptic (but executes very quickly).
//              The algorithm is as follows:
//                1. exclusive-or the input byte with the low-order byte of
//                   the CRC register to get an INDEX
//                2. shift the CRC register eight bits to the right
//                3. exclusive-or the CRC register with the contents of CrcTable16[INDEX]
//                4. repeat steps 1 through 3 for all bytes
//
//              Source : http://www.efg2.com/Lab/Mathematics/CRC.htm
//
//  UPDATED   : 2014-02-11
//
//***************************************************************************
procedure CalcCRC16 (p : pByte;
                     wNumBytes : word;
                     var CRCvalue: word);
var
  i : word;
  q : pByte;

begin
  q := p;
  for i := 1 to wNumBytes do
  begin
    CRCvalue := Hi(CRCvalue) xor CrcTable16[q^ xor Lo(CRCvalue)];
    Inc(q);
  end; // for
end; // CalcCRC16

//***************************************************************************
//
//  FUNCTION  : CalcCRC32
//
//  I/P       : p : pByte - Pointer to the block of data to be CRC-ed
//
//              dwNumBytes : dword - The number of bytes to be CRCed.
//
//              CRCvalue : word - Initialised CRC-32
//                This permits multiple calls to this routine
//
//                From the source webpage : The initial value could be
//                  Method 1 : $00000000
//                  Method 2 : $FFFFFFFF (with an inversion of the result at the end - PKZIP method)
//
//  O/P       : CRCvalue : word - The resultant CRC-32
//
//  OPERATION : The following is a little cryptic (but executes very quickly).
//              The algorithm is as follows:
//                1. exclusive-or the input byte with the low-order byte of
//                   the CRC register to get an INDEX
//                2. shift the CRC register eight bits to the right
//                3. exclusive-or the CRC register with the contents of CrcTable32[INDEX]
//                4. repeat steps 1 through 3 for all bytes
//
//              Source : http://www.efg2.com/Lab/Mathematics/CRC.htm
//
//  UPDATED   : 2014-02-11
//
//***************************************************************************
procedure CalcCRC32 (p : pointer;
                     dwNumBytes : dword;
                     var CRCValue: dword);
var
  i : dword;
  q : pByte;

begin
  q := p;
  for i := 0 to dwNumBytes-1 do
  begin
    CRCvalue := (CRCvalue shr 8) xor CrcTable32[q^ xor (CRCvalue and $000000FF)];
    Inc(q);
  end; // for
end; // CalcCRC32

{****************************************************************************}
{*
{*      FUNCTION    :   File8BitCRC
{*
{*      I/P         :   filename (string) - Full path and filename of the
{*                          file whose CRC is required.
{*
{*      O/P         :   (byte) - The 8-bit CRC of the specified file, or
{*                          zero if the file could not be found or accessed.
{*
{*      CALLS       :   None.
{*
{*      OPERATION   :   Returns the 8-bit CRC of the file.
{*
{*                      NOTE: No warning if given if the file could not be
{*                      accessed.
{*
{*      UPDATED     :   25/03/1998
{*
{****************************************************************************}
function File8BitCRC (filename : string) : byte;
var
  f : file;
  num_read : Integer;
  buf: TCharArray;
  CRC08 : byte;

begin
  if (filename<>'') then
  begin
    AssignFile (f,filename);
    {$I-}
    Reset(f,1);
    {$I+}
    if (IOResult=0) then
    begin
      CRC08 := 0;
      SetLength(buf,2048);
      repeat
        BlockRead(f, buf, SizeOf(buf), num_read);
        GetCRC8(buf,num_read,CRC08);
      until (num_read = 0);
      buf := nil;
      System.CloseFile(f);
      result := CRC08;
    end // if
    else
      result := 0;
  end // if
  else
    result := 0;
end; // File8BitCRC

//****************************************************************************
//
//      FUNCTION    :   FileInUse
//
//      I/P         :   filename (string) - Full path and filename of the
//                          file to be tested.
//
//      O/P         :   (boolean) - TRUE if the file is currently being used
//                          ie it cannot be deleted or renamed.
//
//      CALLS       :   None.
//
//      OPERATION   :   Checks whether the given file may be deleted or
//                      renamed.
//
//                      Copied from
//            http://delphi.about.com/cs/adptips1999/a/bltip0999_3.htm?nl=1
//
//      UPDATED     :   2005/11/28
//
//***************************************************************************
function FileInUse (sFileName : string) : boolean;
var
  HFileRes : HFILE;
begin
  Result := false;
  if (not SysUtils.FileExists(sFileName)) then
    exit;
  HFileRes := CreateFile(pchar(sFileName),
                         GENERIC_READ or GENERIC_WRITE,
                         0, nil, OPEN_EXISTING,
                         FILE_ATTRIBUTE_NORMAL,
                         0) ;
  Result := (HFileRes = INVALID_HANDLE_VALUE) ;
  if not Result then
    CloseHandle(HFileRes);
end; // FileInUse

{****************************************************************************}
{*
{*      FUNCTION    :   Equate_File_DateTime
{*
{*      I/P         :   source (string) - Full path and filename of the
{*                          file whose date and time is to be copied.
{*
{*                      dest (string) - Full path and filename of the
{*                          file whose date and time is to be altered.
{*
{*      O/P         :   None.
{*
{*      CALLS       :   None.
{*
{*      OPERATION   :   Alters the date and time of the destination file to
{*                      match that of the source file.
{*
{*      UPDATED     :   30/04/1998
{*
{****************************************************************************}
procedure Equate_File_DateTime(source, dest : string);
var
  FromF, ToF: integer;

begin
                                    {Access the source file}
    FromF := FileOpen(source, fmOpenRead OR fmShareDenyNone);
    if (FromF>0) then               {Test for an error}
    begin
                                    {Access the destination file}
        ToF := FileOpen(dest, fmOpenWrite OR fmShareDenyNone);
        if (ToF>0) then             {Test for an error}
        begin
            FileSetDate(ToF,FileGetDate(FromF));
            FileClose(ToF);
        end; // if

        FileClose(FromF);
    end; // if
end; {Equate_file_Date_Time}

//***************************************************************************
//
//  FUNCTION  : XCopyFiles
//
//  I/P       : source (string) - Full path and filename (or wild card)
//                of the file/s to be copied.
//
//              dest_dir (string) - Destination path to which the
//                file/s are to be copied.
//
//              recurse (boolean) - TRUE if we should copy all sub-
//                directories and their matching contents from source
//                to the destination.   FALSE for only the contents of
//                the current directory that match the file spec.
//
//              create_empty (boolean) - TRUE to create a destination
//                directory, even if it will not hold any files.
//
//              bAlwaysOverwrite (boolean) - TRUE to overwrite any existing
//                files of matching name in the destination, irrespective
//                of dates of the files.
//
//              newer_only (boolean) - TRUE to overwrite only files that are
//                newer in the source than the destination.
//
//              set_attr (integer) - Set the specified attributes when the
//                files are copied to the destination
//
//              clear_attr (integer) - Clear the specified attributes when the
//                files are copied to the destination
//
//  O/P       : (integer) - Non-zero if an error occurred
//
//  OPERATION : A partial mimic of the DOS XCOPY command.
//
//              Copies files from a source to a destination.   Multiple
//              files may be copied if wild-cards are used.
//
//              Sub-directories may also be copied, and file attributes may
//              be set and cleared in the operation.
//
//              Uses recursion to drill down through directories, if required.
//
//  UPDATED   : 2005/10/11
//
//***************************************************************************
function XCopyFiles(source : String;
                    dest_dir : String;
                    recurse : boolean;
                    create_empty : boolean;
                    bAlwaysOverwrite : boolean;
                    newer_only : boolean;
                    set_attr : Integer;
                    clear_attr : integer) : Integer;
var
  iErrorCode : Integer;   // Shows whether we encountered an error or not.
  current_dir : String;   // The current directory - used if no dir given

  procedure Copy_Tree(ctsource, ctdest_dir : string);
  var
    sr : TSearchRec;
    sr1 : TSearchRec;
    sr_dest : TSearchRec;
    iSearchResult : Integer;

  begin
    // Check if there are any sub-directories if we are handling sub-directories.
    if ((FindFirst(ExtractFilePath(ctsource) + '*.*',faDirectory,sr)=0) and
        (recurse)) then
    begin
      repeat
        if (sr.name<>'.') and             // We have found a valid sub-directory
           (sr.name<>'..') and
           ((sr.attr and faDirectory) > 0) then
        begin                             // Go down one level

          //!! Empty directory detection does not work since we will always see that the
          // directory contains '.' and '..', and hence it will always be created.
          // We need to check whether it contains anything other than these two entries.

          // If all is still OK...  create the destination directory, provided that
          // - the destination directory does not exist and we are creating even if empty, or
          // - there are files or directories in the source
          if ((FindFirst(ctdest_dir,faDirectory,sr1)<>0) and
              (iErrorCode = 0) and
              ((create_empty) or
               ((not create_empty) and
                (FindFirst(ctsource,faAnyFile,sr1)=0)))) then
          begin
            if ((not SysUtils.DirectoryExists(ctdest_dir + sr.name)) and
                (not CreateDir(ctdest_dir + sr.name))) then
              iErrorCode := FOE_COULD_NOT_MAKE_DEST;
          end; // if
          SysUtils.FindClose(sr1);

          Copy_Tree(
            IncludeTrailingPathDelimiter(ExtractFilePath(ctsource)) +
            sr.Name + TPath.DirectorySeparatorChar +
            ExtractFileName(ctsource),
            ctdest_dir + sr.Name + TPath.DirectorySeparatorChar
          );
        end; // if
      until (FindNext(sr)<>0);
    end; // if
    SysUtils.FindClose(sr);

    // We are now at the lowest level of the source to which we must/can go in this arm.
    // Continue only if everything has worked OK up to now.
    if (iErrorCode = FOE_NONE) then
    begin

      // Are there any files to be copied?
      if (FindFirst(ctsource,faReadOnly or
                             faHidden or
                             faSysFile or
                             faArchive,sr)=0) then
      begin
        repeat
          // Check whether the destination file exists
          iSearchResult := FindFirst(ctdest_dir + sr.name,
                                     faReadOnly or faHidden or faSysFile or faArchive,
                                     sr_dest);
          // If the destination file does not exist, go ahead with the copying
          // If the destination file already exists, check whether we may
          // just overwrite it, or only overwrite it if the source is newer.
          if ((iSearchResult <> 0) or
              ((iSearchResult = 0) and
               ((bAlwaysOverwrite) or
                ((newer_only) and
                 (sr.TimeStamp > sr_dest.TimeStamp))))) then
          begin
            // Copy the file
            iErrorCode := FileCopied(ExtractFilePath(ctsource) + sr.name,
                                    ctdest_dir + sr.name,nil);
            // Set the Date/Time
            if (iErrorCode = FOE_NONE) then
              Equate_File_DateTime(ExtractFilePath(ctsource) + sr.name,
                                   ctdest_dir + sr.name);
            // If we copied OK, modify the file attributes as specified.
            if (iErrorCode = FOE_NONE) then
              iErrorCode := FileSetAttr(ctdest_dir + sr.name,
                                        (sr.Attr and (not clear_attr)) or set_attr);
          end; // if
        until (iErrorCode <> FOE_NONE) or (FindNext(sr)<>0);
        SysUtils.FindClose(sr_dest);
      end; // if
      SysUtils.FindClose(sr);
    end; // if

  end; // Copy_Tree

begin
  // If no source is specified, assume all files.
  if (source = '') then
    source := '*.*';

  // If no source directory is specified, use the current directory.
  if (ExtractFilePath(source) = '') then
  begin
    GetDir(0,current_dir);
    source := current_dir + source;
  end; // if

  // If a source directory was given as a drive letter and ':' only, append
  // the backslash.
  if (source[Length(source)] = ':') then
    source := source + TPath.DirectorySeparatorChar;

  // If no source file name is given, assume that all files are to be copied.
  if (source[Length(source)] = TPath.DirectorySeparatorChar) then
    source := source + '*.*';

  // If no destination directory is specified, use the current directory.
  if (dest_dir = '') then
  begin
    GetDir(0,current_dir);
    dest_dir := current_dir;
  end; // if

  // Ensure that the destination directory is treated as a directory.
  dest_dir := IncludeTrailingPathDelimiter(dest_dir);

  // Everything is OK so far.
  iErrorCode := FOE_NONE;

  // Start the whole thing going
  Copy_Tree(source,dest_dir);

  // Return the result
  result := iErrorCode;
end; // XCopyFiles

//***************************************************************************
//
//  FUNCTION  : XDeleteFiles
//
//  I/P       : target (string) - Full path and filename (or wild card)
//                of the file/s to be deleted.
//
//              delete_also (integer) - Or-ed file attributes for the
//                deletion of ReadOnly, System, Hidden files etc.
//                faReadOnly
//
//              dtOlder (TDateTime) - Delete all files that are older than
//                this date.   If 0.0, then delete all files.
//
//  O/P       : (integer) - a result code
//
//      CALLS : DeleteFiles
//
//  OPERATION : Removes all files that match the given filename in the
//              specified directory, and all sub-directories.   If the
//              filename is '*.*', then all sub-directories are removed
//              as well, if they become empty.
//
//              Uses recursion to drill down through directories, as
//              required.
//
//  UPDATED   : 1999/10/19
//
//***************************************************************************
function XDeleteFiles(target : String;
                      delete_also : Integer;
                      dtOlder : TDateTime) : Integer;

  procedure Delete_Tree(dttarget : string);
  var
    sr : TSearchRec;
  begin
    // If everything is OK so far, check if there are any sub-directories
    if (((result = FOE_NONE) and
        (FindFirst(ExtractFilePath(dttarget) + '*.*',faDirectory,sr)=0))) then
    begin
      repeat
        if (sr.name<>'.') and             // We have found a valid sub-directory
           (sr.name<>'..') and
           ((sr.attr and faDirectory) > 0) then
        begin
          // Go down one level
          Delete_Tree(
            IncludeTrailingPathDelimiter(ExtractFilePath(dttarget)) +
            sr.Name + TPath.DirectorySeparatorChar +
            ExtractFileName(dttarget)
          );
          if ((result = FOE_NONE) and
              (ExtractFileName(dttarget) = '*.*')) then
            if (RemoveDir(IncludeTrailingPathDelimiter(ExtractFilePath(dttarget)) + sr.Name)) then
              result := FOE_NONE
            else
              result := FOE_FOLDER_NOT_DELETED;
        end; // if
      until (FindNext(sr)<>0);
      SysUtils.FindClose(sr);
    end; // if

// Go ahead and delete the files if we have been successful in the operation so far.
    if (result = FOE_NONE) then
      result := DeletedFiles(dttarget, delete_also, dtOlder);

  end; // Delete_Tree

begin

  // If no target, quit
  if (target = '') then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  // If an invalid target directory is specified, quit
  if (ExtractFilePath(target) = '') then
  begin
    result := FOE_INVALID_PATH;
    Exit;
  end; // if

  // If no target file name is given, quit
  if (target[Length(target)] = TPath.DirectorySeparatorChar) then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  result := FOE_NONE;               // Everything is OK so far.

  Delete_Tree(target);              // Start the whole thing going
end; // XDeleteFiles

//***************************************************************************}
//
//  FUNCTION  : FindAllFiles
//
//  I/P       : sMask (string) : Mask of the files to find (e.g. 'C:\*.bat')
//
//              iAttr (integer) : Attributes to be matched
//
//              bDrilDown (boolean) : TRUE if the search should cover
//                all sub directories
//
//              bProperties (boolean) : TRUE if the results should
//                include information on the properties of each file.
//
//              slResult (TStringList) : The results of the search
//
//  O/P       : Updates to slResult
//
//  OPERATION : Creates a list of the full path to all files that
//              match the given mask.
//
//  UPDATED   : 2005/01/19
//
//***************************************************************************}
procedure FindAllFiles(sMask : String;
                       iAttr : Integer;
                       bDrillDown : boolean;
                       bProperties : boolean;
                       slResult : TStringList);
var
  srFile : TSearchRec;
  sTemp : String;
begin
  if (FindFirst(sMask,iAttr,srFile) = 0) then
  begin
    repeat
      sTemp := ExtractFilePath(sMask) + srFile.Name;
      // Add properties of the file, separated by tabs, if so requested
      if (bProperties) then
      begin
        sTemp := sTemp + #09 +
                 IntToStr(srFile.Size) + #09 +
                 FormatDateTime('ddddd t', srFile.TimeStamp) + #09 +
                 string(srFile.FindData.cAlternateFileName);
      end; // if
      slResult.Add(sTemp);
    until (FindNext(srFile) <> 0);
  end; // if
  SysUtils.FindClose(srFile);

  // If we are drilling down, we should now search for sub directories
  if (bDrillDown) then
  begin
    // Look for the first sub-directory
    if (FindFirst(ExtractFilePath(sMask) + '*.*',faDirectory,srFile) = 0) then
    begin
      repeat
        // For each available sub-directory, perform a recursive call on this routine.
        if ((srFile.Name <> '.') and
            (srFile.Name <> '..') and
            ((srFile.Attr and faDirectory) <> 0)) then
        FindAllFiles(ExtractFilePath(sMask) + srFile.Name + TPath.DirectorySeparatorChar + ExtractFileName(sMask),
                     iAttr,bDrillDown,bProperties,slResult);
      until (FindNext(srFile) <> 0);
    end; // if
    SysUtils.FindClose(srFile);
  end; // if
end; // FindAllFiles
(*
//*****************************************************************************
//
//  FUNCTION    :   FileTimeToDateTime
//
//  I/P         :   ftFileTime (TFileTime) : A record structure that
//                    contains a date and time in Coordinated Universal
//                    Time (UTC) format. The TFileTime structure corresponds
//                    to the Win32 FILETIME structure, which is defined as:
//
//                    typedef struct _FILETIME
//                    { // ft
//                      DWORD dwLowDateTime;
//                      DWORD dwHighDateTime;
//                    } FILETIME;
//
//  O/P         :   TDateTime - The file date and time
//
//  OPERATION   :   Used to convert one of the date/time records in the
//                  TWin32FindData structure, that is returned in the FindFirst
//                  and FindNext functions.
//
//  UPDATED     :   2005/01/24
//
//*****************************************************************************
function FileTimeToDateTime(ftFileTime : TFileTime) : TDateTime;
var
  ftLocalTime : TFileTime;
  stSystemTime : TSystemTime;

begin
  // set default return in case of failure;
  result := EncodeDate(1900,1,1);
  if FileTimeToLocalFileTime(ftFileTime, ftLocalTime) then
    if FileTimeToSystemTime(ftLocalTime, stSystemTime) then
      Result := SystemTimeToDateTime(stSystemTime);
end;  // function FileTimeToDateTime
*)
//*****************************************************************************
//
//  FUNCTION    :   GetAssociatedEXEFile
//
//  I/P         :   sFName (string) : The file name
//
//  O/P         :   Returns the associated EXE file name on success.
//                      If the function fails, it returns an empty string.
//
//  OPERATION   :   This function will determine the full path and file
//                      name for the executable file associated with a file or
//                      file extension.
//
//                      Copied from
//          http://www.jpgriffiths.com/tutorial/Snippets/getassociatedexe.html
//
//  UPDATED     :   2005/01/24
//
//*****************************************************************************
function GetAssociatedEXEFile(FName: String) : String;
var
  FileExt, Buffer : String;
  Reg: TRegistry;

begin
  // Get the extension of the file
  FileExt := UpperCase(ExtractFileExt(FName));
  Result := '';

  // If an EXE, ICO or DLL file, that will be the location
  if ((FileExt = '.EXE') or
      (FileExt = '.ICO') or
      (FileExt = '.DLL')) then
  begin
    Result := FName;
    Exit;
  end; // if

  // Read the registry for an associated EXE
  Reg := nil;
  try
    Reg := TRegistry.Create(KEY_QUERY_VALUE);
    Reg.RootKey := HKEY_CLASSES_ROOT;
    if Reg.OpenKeyReadOnly(FileExt) then
      try
        Buffer := Reg.ReadString('');
      finally
        Reg.CloseKey;
      end;

    if ((Buffer <> '') and
        (Reg.OpenKeyReadOnly(Buffer + '\Shell\Open\Command'))) then
      try
        Result := Reg.ReadString('');
      finally
        Reg.CloseKey;
      end;
  finally
    Reg.Free;
  end;
end;

//***************************************************************************
//
//  FUNCTION    :   IOResultTest
//
//  I/P         :   bNewTest (boolean) - TRUE if the test must check and
//                  store the result of the most recent IO operation.
//                  FALSE if it must report on a previously tested result.
//
//  O/P         :   TRUE if the most recent (or last tested) I/O operation
//                  proceeded correctly
//
//  OPERATION   :   Used to check IOResult, and store the result for later
//                  access using the associated functions (below)
//
//  UPDATED     :   2005/05/19
//
//***************************************************************************
function IOResultTest(bNewTest : boolean) : boolean;
begin
  // If this is a new test, access and store the latest IOResult value
  if (bNewTest) then
    iLastIOResult := IOResult;
  // Perform the test
  result := (iLastIOResult = 0);
end; // IOResultTest

//***************************************************************************
//
//  FUNCTION    :   IOResultString
//
//  I/P         :   iIOError (integer) - The error code of the IO error, or
//                    -1 for the internally stored, last I/O Result.
//
//  O/P         :   (string) - A description of the type of error that has
//                  occurred.   '' if there is no error.
//
//  OPERATION   :   Returns a descriptive message of the error.
//
//                  According to Borland's "Unknown runtime errors. What's
//                  error 163?" (TI 506D), if you ever get an IORESULT code
//                  in the range 150-199, just subtract 131 from it and then
//                  look in your DOS reference manual.
//
//                  http://homepages.borland.com/efg2lab/Library/Delphi/IO/IOResult.htm
//
//  UPDATED     :   2006/01/16
//
//***************************************************************************
function IOResultString(iIOError : integer = -1) : String;
begin
  case iIOError of
    0 : result := '';
    1 : result := 'Invalid/Incorrect function';
    2 : result := 'File not found';
    3 : result := 'Path not found';
    4 : result := 'Too many open files';
    5 : result := 'File access denied';
    6 : result := 'Invalid file handle';
    19 : result := 'Write protect error.';                  // 150 - 131
    20 : result := 'Could not find the specified device.';
    21 : result := 'Device not ready.';
    26 : result := 'Unknown media type.';
    29 : result := 'Write fault error.';
    30 : result := 'Read fault error.';
    31 : result := 'Hardware fault.   Device not functioning.';
    32 : result := 'Sharing violation.   Another process is using this file.';
    33 : result := 'Lock violation.   Another process has locked this file.'
    else
      result := 'I/O Error ' + IntToStr(iLastIOResult);
  end; // case
end; // IOResultString

//***************************************************************************
//
//  FUNCTION    :   LastIOResultMessage
//
//  I/P         :   bNewTest (boolean) - TRUE if the test must check and
//                  store the result of the most recent IO operation.
//                  FALSE if it must report on a previously tested result.
//
//  O/P         :   '' if the most recent (or last tested) I/O operation
//                  proceeded correctly.   Otherwise, some suitable
//                  descriptive string will be returned.
//
//  OPERATION   :   Stores the latest IOResult value, if so selected, and
//                  returns a descriptive message of the error.
//
//  UPDATED     :   2005/10/28
//
//***************************************************************************
function LastIOResultMessage(bNewTest : boolean) : String;
begin
  // If this is a new test, access and store the latest IOResult value
  if (bNewTest) then
    iLastIOResult := IOResult;
  // Find a suitable message
  result := IOResultString(iLastIOResult);
end; // LastIOResultMessage

//***************************************************************************
//
//  FUNCTION    :   LastIOResultNumber
//
//  I/P         :   bNewTest (boolean) - TRUE if the test must check and
//                  store the result of the most recent IO operation.
//                  FALSE if it must report on a previously tested result.
//
//  O/P         :   0 if the most recent (or last tested) I/O operation
//                  proceeded correctly.   Otherwise, an IOResult value for
//                  the error code.
//
//  OPERATION   :   Stores the latest IOResult value, if so selected, and
//                  returns the value of this (or the last) IOResult.
//
//  UPDATED     :   2005/05/19
//
//***************************************************************************
function LastIOResultNumber(bNewTest : boolean) : Integer;
begin
  // If this is a new test, access and store the latest IOResult value
  if (bNewTest) then
    iLastIOResult := IOResult;
  // Return the number
  result := iLastIOResult;
end; // LastIOResultNumber

//***************************************************************************
//
//  FUNCTION    :   WroteToTextFile
//
//  I/P         :   strInput (TStrings) - The strings to be written to file
//
//                  sFileName (string) - The full file name of the output file.
//
//  O/P         :   TRUE if the string list was written away to file.
//
//  OPERATION   :   This performs an expanded version of TStrings.SaveToFile
//
//                  It makes use of the persistent IO checking (see functions
//                  above), so that any file errors can be neatly reported.
//
//  UPDATED     :   2005/05/19
//
//***************************************************************************
function WroteToTextFile(strInput : TStrings;
                         sFileName : string) : boolean;
var
  tfReport : TextFile;
  n : Integer;
begin
  result := TRUE;

  AssignFile (tfReport,sFileName);
  {$I-}
  Rewrite(tfReport);
  {$I+}
  if (IOResultTest(TRUE)) then
  begin
    for n := 0 to strInput.Count-1 do
      Writeln(tfReport,strInput.Strings[n]);
    System.CloseFile(tfReport);
  end // if
  else
    result := FALSE;
end; // WroteToTextFile

//***************************************************************************
//
//  FUNCTION    :   ReadFromTextFile
//
//  I/P         :   sFileName (string) - The full file name of the output file.
//
//  O/P         :   TRUE if the string list was written away to file.
//
//                  strOutput (TStrings) - The strings read from the file
//
//  OPERATION   :   This performs an expanded version of TStrings.ReadFromFile
//
//                  It makes use of the persistent IO checking (see functions
//                  above), so that any file errors can be neatly reported.
//
//  UPDATED     :   2005/05/19
//
//***************************************************************************
function ReadStrFromTextFile(var sInput : String;
                             sLineBreak : String;
                             sFileName : string) : boolean;
var
  tfInput : TextFile;
  sLine : String;
begin
  result := TRUE;

  AssignFile (tfInput,sFileName);
  {$I-}
  Reset(tfInput);
  {$I+}
  if (IOResultTest(TRUE)) then
  begin
    sInput := '';
    while (not Eof(tfInput)) do
    begin
      Readln(tfInput,sLine);
      sInput := sInput + sLine + sLineBreak;
    end; // while
    System.CloseFile(tfInput);
  end // if
  else
    result := FALSE;
end; // ReadFromTextFile

//***************************************************************************
//
//  FUNCTION  : CountFiles
//
//  I/P       : sMask : String - The FindFirst path to be used
//
//              iAttr : integer - File attributes to be applied
//
//  O/P       : Integer - The number of files. Negative numbers (error flags)
//                if parameters were invalid
//
//  OPERATION : Counts the number of files that match the given mask.
//
//  UPDATED   : 2018-12-01
//
//***************************************************************************
function CountFiles(sMask : String;
                    iAttr : integer) : Integer;
var
  srResult : TSearchRec;

begin
  // If no mask is given, then quit
  if (sMask = '') then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  // If an invalid target directory is specified, quit
  if (ExtractFilePath(sMask) = '') then
  begin
    result := FOE_INVALID_PATH;
    Exit;
  end; // if

  // If no target file name is given, quit
  if (sMask[Length(sMask)] = TPath.DirectorySeparatorChar) then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  result := 0;

  // Check if there are one or more of the required files in the directory
  if (FindFirst(sMask,iAttr,srResult) = 0) then
    // Scan through all the files in the directory
    repeat
      Inc(result);
    until (FindNext(srResult) <> 0);

  SysUtils.FindClose(srResult);
end; // CountFiles

//***************************************************************************
//
//  FUNCTION  : XCountFiles
//
//  I/P       : sMask : String - The FindFirst path to be used
//
//              iAttr : integer - File attributes to be applied
//
//  O/P       : Integer - The number of files. Negative numbers (error flags)
//                if parameters were invalid
//
//  OPERATION : Counts the matching files in the folder, and all sub-folders
//
//  UPDATED   :
//
//***************************************************************************
function XCountFiles(sMask : String;
                     iAttr : integer) : Integer;
var
  iFiles : Integer;

  procedure Count_Tree(sTMask : string);
  var
    sr : TSearchRec;
  begin
    // If everything is OK so far, check if there are any sub-directories
    if (FindFirst(ExtractFilePath(sTMask) + '*.*',faDirectory,sr)=0) then
    begin
      repeat
        // We have found a valid sub-directory
        if (sr.name<>'.') and
           (sr.name<>'..') and
           ((sr.attr and faDirectory) > 0) then
        begin
          // Go down one level
          Count_Tree(
            IncludeTrailingPathDelimiter(ExtractFilePath(sTMask)) +
            sr.Name + TPath.DirectorySeparatorChar +
            ExtractFileName(sTMask)
          );
        end; // if
      until (FindNext(sr)<>0);
      SysUtils.FindClose(sr);
    end; // if

    // Go ahead and count the files in this folder
    iFiles := iFiles + CountFiles(sTMask, iAttr);
  end; // Count_Tree

begin
  iFiles := 0;

  // If no mask is given, then quit
  if (sMask = '') then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  // If an invalid target directory is specified, quit
  if (ExtractFilePath(sMask) = '') then
  begin
    result := FOE_INVALID_PATH;
    Exit;
  end; // if

  // If no target file name is given, quit
  if (sMask[Length(sMask)] = TPath.DirectorySeparatorChar) then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  // Start the whole thing going
  Count_Tree(sMask);

  result := iFiles;
end; // XCountFiles

//***************************************************************************}
//
//  FUNCTION    :   SizeOfFile
//
//  I/P         :   filename (string) - Full path and filename of the
//                          file whose size is required.   The file should
//                          exist.
//
//  O/P         :   (Int64) - The size of the specified file, or
//                          zero if it could not be found or accessed.
//
//      CALLS       :   None.
//
//  OPERATION   :   Return the exact file size for a file. If the file
//                      is not found, returns a zero.
//
//                      Uses the FindData record, to cater for files with
//                      sizes larger than 2Gb.
//
//                      NOTE: No warning if given if the file could not be
//                      accessed.
//
//  UPDATED     :   2005/01/24
//
//***************************************************************************}
function SizeOfFile(sFileName : string) : Int64;
var
  SearchRec : TSearchRec;

begin
  if (sFileName <> '') then
  begin
    if (FindFirst(sFileName, faAnyFile, SearchRec ) = 0) then
      result := Int64(SearchRec.FindData.nFileSizeHigh) shl Int64(32) +
                Int64(SearchREc.FindData.nFileSizeLow)
    else
      result := 0;
    SysUtils.FindClose(SearchRec);
  end // if
  else
    result := 0;
end; // SizeOfFile

//***************************************************************************
//
//  FUNCTION  : SizeOfFiles
//
//  I/P       : sMask : String - The FindFirst path to be used
//
//              iAttr : integer - File attributes to be applied (what happens
//                if one includes faDirectory?)
//
//  O/P       : Integer - The total size of all the matching files.
//                Negative numbers (error flags) if parameters were invalid.
//
//  OPERATION : Returns the total size of the files in the folder
//
//  UPDATED   : 2018-12-01
//
//***************************************************************************
function SizeOfFiles(sMask : String;
                     iAttr : integer) : Integer;
var
  srResult : TSearchRec;

begin
  // If no mask is given, then quit
  if (sMask = '') then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  // If an invalid target directory is specified, quit
  if (ExtractFilePath(sMask) = '') then
  begin
    result := FOE_INVALID_PATH;
    Exit;
  end; // if

  // If no target file name is given, quit
  if (sMask[Length(sMask)] = TPath.DirectorySeparatorChar) then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  result := 0;

  // Check if there are one or more of the required files in the directory
  if (FindFirst(sMask, iAttr, srResult) = 0) then
  begin
    // Scan through all the files in the directory
    repeat
      Inc(result, SizeOfFile(ExtractFilePath(sMask) + srResult.Name));
    until (FindNext(srResult) <> 0);
  end;

  SysUtils.FindClose(srResult);
end; // SizeOfFiles

//***************************************************************************
//
//  FUNCTION  : XSizeOfFiles
//
//  I/P       : sMask : String - The FindFirst path to be used
//
//              iAttr : integer - File attributes to be applied (what happens
//                if one includes faDirectory?)
//
//  O/P       : Integer - The total size of all the matching files.
//                Negative numbers (error flags) if parameters were invalid.
//
//  OPERATION : Returns the total size of the matching files in the folder,
//              and all sub-folders
//
//  UPDATED   : 2018-12-01
//
//***************************************************************************
function XSizeOfFiles(sMask : String;
                      iAttr : integer) : Integer;
var
  totalSize : Integer;

  procedure Size_Tree(sTMask : string);
  var
    sr : TSearchRec;
  begin
    // If everything is OK so far, check if there are any sub-directories
    if (FindFirst(ExtractFilePath(sTMask) + '*.*',faDirectory,sr)=0) then
    begin
      repeat
        // We have found a valid sub-directory
        if (sr.name<>'.') and
           (sr.name<>'..') and
           ((sr.attr and faDirectory) > 0) then
        begin
          // Go down one level
          Size_Tree(
            IncludeTrailingPathDelimiter(ExtractFilePath(sTMask)) +
            sr.Name + TPath.DirectorySeparatorChar +
            ExtractFileName(sTMask)
          );
        end; // if
      until (FindNext(sr)<>0);
      SysUtils.FindClose(sr);
    end; // if

    // Tally the size of files in this folder
    totalSize := totalSize + SizeOfFiles(sTMask, iAttr);
  end; // Count_Tree

begin
  totalSize := 0;

  // If no mask is given, then quit
  if (sMask = '') then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  // If an invalid target directory is specified, quit
  if (ExtractFilePath(sMask) = '') then
  begin
    result := FOE_INVALID_PATH;
    Exit;
  end; // if

  // If no target file name is given, quit
  if (sMask[Length(sMask)] = TPath.DirectorySeparatorChar) then
  begin
    result := FOE_INVALID_TARGET;
    Exit;
  end; // if

  // Start the whole thing going
  Size_Tree(sMask);

  result := totalSize;
end; // XSizeOfFiles

//***************************************************************************
//
//  FUNCTION  : SplitFile
//
//  I/P       : FileName (TFileName) - file to split into several smaller files
//
//              FilesByteSize (integer) - the size of files in bytes
//
//  O/P       : None
//
//  OPERATION : Split a file into files of the given size.
//
//              Note: a 3 KB file 'myfile.ext' will be split into
//                'myfile._1', 'myfile._2','myfile._3' if FilesByteSize
//                parameter equals 1024 (1 KB).
//
//              Usage:
//                SplitFile('c:\mypicture.bmp', 1024) ; //into 1 KB files
//                MergeFiles('c:\mypicture._1','c:\mymergedpicture.bmp') ;
//
//              From
//              http://delphi.about.com/od/adptips2005/qt/splitfilemerge.htm?nl=1
//
//  UPDATED   : 2005/12/01
//
//***************************************************************************
procedure SplitFile(FileName : TFileName; FilesByteSize : Integer);
var
   fs, ss: TFileStream;
   cnt : Integer;
   SplitName: String;
begin
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite) ;
  try
    for cnt := 1 to Trunc(fs.Size / FilesByteSize) + 1 do
    begin
      SplitName := ChangeFileExt(FileName, Format('%s%d', ['._',cnt])) ;
      ss := TFileStream.Create(SplitName, fmCreate or fmShareExclusive) ;
      try
        if fs.Size - fs.Position < FilesByteSize then
          FilesByteSize := fs.Size - fs.Position;
        ss.CopyFrom(fs, FilesByteSize) ;
      finally
        ss.Free;
      end;
    end;
  finally
    fs.Free;
  end;
end; // SplitFile

//***************************************************************************
//
//  FUNCTION  : MergeFiles
//
//  I/P       : FirstSplitFileName (TFileName) - the name of the first piece
//                of the split file.
//
//              OutFileName (TFileName) - the name of the resulting merged
//                file.
//
//  O/P       : None
//
//  OPERATION : Merge files that have been split with SplitFile, above.
//
//              Usage:
//                SplitFile('c:\mypicture.bmp', 1024) ; //into 1 KB files
//                MergeFiles('c:\mypicture._1','c:\mymergedpicture.bmp') ;
//
//              From
//              http://delphi.about.com/od/adptips2005/qt/splitfilemerge.htm?nl=1
//
//  UPDATED   : 2005/12/01
//
//***************************************************************************
procedure MergeFiles(FirstSplitFileName, OutFileName : TFileName);
var
  fs, ss: TFileStream;
  cnt: integer;
begin
  cnt := 1;
  fs := TFileStream.Create(OutFileName, fmCreate or fmShareExclusive) ;
  try
    while (SysUtils.FileExists(FirstSplitFileName)) do
    begin
      ss := TFileStream.Create(FirstSplitFileName, fmOpenRead or fmShareDenyWrite) ;
      try
        fs.CopyFrom(ss, 0) ;
      finally
        ss.Free;
      end;
      Inc(cnt) ;
      FirstSplitFileName := ChangeFileExt(FirstSplitFileName, Format('%s%d', ['._',cnt])) ;
    end;
  finally
    fs.Free;
  end;
end; // MergeFiles

//***************************************************************************
//
//  FUNCTION  : AlternateToLFN
//
//  I/P       : AltName (string) - The 8.3 file name
//
//  O/P       : (string) - The long file name
//
//  OPERATION : Taken from
//              http://delphi.about.com/cs/adptips1999/a/bltip1199_3.htm?nl=1
//
//              Converts 8.3 format filename to the long format filename
//
//  UPDATED   : 2006/01/10
//
//***************************************************************************
function AlternateToLFN(AltName:String):String;
var
  temp: TWIN32FindData;
  searchHandle: THandle;
begin
  searchHandle := WinAPI.Windows.FindFirstFile(PChar(AltName),temp);
  if searchHandle <> ERROR_INVALID_HANDLE then
    result := String(temp.cFileName)
  else
    result := '';
  WinAPI.Windows.FindClose(searchHandle);
end; // AlternateToLFN

//***************************************************************************
//
//  FUNCTION  : LFNToAlternate
//
//  I/P       : LongName (string) - The long file name
//
//  O/P       : (string) - The 8.3 alternate file name
//
//  OPERATION : Taken from
//              http://delphi.about.com/cs/adptips1999/a/bltip1199_3.htm?nl=1
//
//              Converts long format filename to the 8.3 format filename
//
//  UPDATED   : 2006/01/10
//
//***************************************************************************
function LFNToAlternate(LongName:String):String;
var
  temp: TWIN32FindData;
  searchHandle: THandle;
begin
  searchHandle := WinAPI.Windows.FindFirstFile(PChar(LongName),temp);
  if searchHandle <> ERROR_INVALID_HANDLE then
    result := String(temp.cALternateFileName)
  else
    result := '';
  WinAPI.Windows.FindClose(searchHandle);
end; // LFNToAlternate

//***************************************************************************
//
//  FUNCTION  : FileLastModified
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
function FileLastModified (const TheFile: string): string;
(*
var
  FileH : THandle;
  LocalFT : TFileTime;
  DosFT : DWORD;
  LastAccessedTime : TDateTime;
  FindData : TWin32FindData;
*)
begin
(*
  Result := '';
  FileH := FindFirstFile(PChar(TheFile), FindData);
  if (FileH <> INVALID_HANDLE_VALUE) then
  begin
    Windows.FindClose(Handle);
    if (FindData.dwFileAttributes AND
        FILE_ATTRIBUTE_DIRECTORY) = 0 then
    begin
      FileTimeToLocalFileTime(FindData.ftLastWriteTime,LocalFT) ;
      FileTimeToDosDateTime(LocalFT,LongRec(DosFT).Hi,LongRec(DosFT).Lo);
      LastAccessedTime := FileDateToDateTime(DosFT);
      Result := DateTimeToStr(LastAccessedTime);
    end;
  end;
*)
end; // FileLastModified

//***************************************************************************
//
//  FUNCTION  : ListDrivesOfType
//
//  I/P       : DriveType : Cardinal - One of the constants defined in WinAPI.Windows
//                DRIVE_UNKNOWN,
//                DRIVE_NO_ROOT_DIR,
//                DRIVE_REMOVABLE,
//                DRIVE_FIXED,
//                DRIVE_REMOTE,
//                DRIVE_CDROM,
//                DRIVE_RAMDISK,
//
//  O/P       : Drives : TStringList - The list of available drives of the
//                selected type.
//
//  OPERATION : From
// https://stackoverflow.com/questions/5635573/delphi-enumerate-the-disks-and-other-drives-on-windows-pc
//
//  UPDATED   : 2018-05-08
//
//***************************************************************************
procedure ListDrivesOfType(DriveType : Cardinal;
                           var Drives : TStringList);
var
  DriveMap,
  dMask : DWORD;
  dRoot : String;
  i     : Integer;

begin
  dRoot := 'A:\'; //' // work around highlighting
  DriveMap := GetLogicalDrives;
  dMask := 1;

  for i := 0 to 32 do
  begin
    if ((dMask and DriveMap) <> 0) then
      if (GetDriveType(PChar(dRoot)) = DriveType) then
      begin
        Drives.Add(IncludeTrailingPathDelimiter(dRoot[1] + ':'));
      end;

    dMask := dMask shl 1;
    Inc(dRoot[1]);
  end; // for
end;

//***************************************************************************
//
//  FUNCTION  : IsOnLocalDrive
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From http://www.swissdelphicenter.ch/torry/showcode.php?id=1183
//
//  UPDATED   : 2006/11/30
//
//***************************************************************************
function IsOnLocalDrive(aFileName: string): Boolean;
var
  aDrive: string;
begin
  aDrive := ExtractFileDrive(aFileName);
  if (GetDriveType(PChar(aDrive)) = DRIVE_REMOVABLE) or
     (GetDriveType(PChar(aDrive)) = DRIVE_FIXED) then
    Result := True
  else
    Result := False;
end;

//***************************************************************************
//
//  FUNCTION  : LongestTextLine
//
//  I/P       : sFileName (string) - the full filename of the file to be
//                tested.
//
//  O/P       : (integer) - The length of the longest line in the file.
//                -1 if access to the file was not possible.
//
//  OPERATION : Scans a text file and returns the number of characters in
//              the longest line.
//
//  UPDATED   : 2006/12/14
//
//***************************************************************************
function LongestTextLine(sFileName : string) : Integer;
var
  tfInput : TextFile;
  sLine : String;
begin
  if (SysUtils.FileExists(sFileName)) then
  begin
    AssignFile (tfInput,sFileName);
    {$I-}
    Reset(tfInput);
    {$I+}
    if (IOResult=0) then
    begin
      result := 0;
      while (not Eof(tfInput)) do
      begin
        Readln(tfInput,sLine);
        result := Max(Length(sLine),result);
      end; // while
      System.CloseFile(tfInput);
    end // if
    else
      result := -1;
  end // if
  else
    result := -1;
end; // LongestTextLine

//***************************************************************************
//
//  FUNCTION  : GetTempFolder
//
//  I/P       : None
//
//  O/P       : (string) - The path to the temporary folder
//
//  OPERATION : Gets the temporary folder path - usually C:\TEMP
//
//              http://delphi.about.com/cs/adptips2000/a/bltip0900_5.htm?nl=1
//
//  UPDATED   : 2007/01/26
//
//***************************************************************************
function GetTempFolder : String;
var
  lng: DWORD;
  sThePath: string;
begin
  SetLength(sThePath, MAX_PATH);
  lng := GetTempPath(MAX_PATH, PChar(sThePath));
  SetLength(sThePath,lng);
  result := sThePath;
end; // GetTempFolder

//***************************************************************************
//
//  FUNCTION  : GetFileTranslation
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Lifted from GSCToolbox
//
//  UPDATED   : 2007/02/19
//
//***************************************************************************
function GetFileTranslation(const sFilename: string;
                            bFullName: Boolean{$IFNDEF VERSION3} = FALSE{$ENDIF}): string;
var
  VerInfSize, Sz: Cardinal;
  LangID: Pointer;
  VerInfo: Pointer;
  Buf: array[0..255] of char;
begin
  Result := '';
  if (SysUtils.FileExists(sFilename)) then
  begin
    VerInfSize := GetFileVersionInfoSize(PCHAR(sFilename), Sz);
    if (VerInfSize > 0) then
    begin
      VerInfo := Allocmem(VerInfSize);
      try
        GetFileVersionInfo(PCHAR(sFilename), 0, VerInfSize, VerInfo);
        VerQueryValue(VerInfo, '\VarFileInfo\Translation', LangID, Sz);
        if (LangID <> NIL) then
        case Ord(bFullName) of
          0 :
            Result := IntToHex(MakeLong(HiWord(Longint(LangID^)),LoWord(Longint(LangID^))), 8);
          1 :
            if (VerLanguageName(DWORD(LangID^), Buf, SizeOf(Buf)) > 0) then
              Result := Buf;
        end; // case
      finally
        FreeMem(VerInfo);
      end; // finally
    end; // if
  end; // if
end; // GetFileTranslation

//***************************************************************************
//
//  FUNCTION  : GetFileResourceString
//
//  I/P       : sFileName (string) - The full file name of the file that is
//                being queried.
//
//              sVersionKey (string) - The VerQueryValue id string required.
//                (See the remarks under VerQueryValue in Windows SDK Help)
//
//  O/P       : (string) - The application file version, if available
//
//  OPERATION : Modified from the Delphi Help example on "Reading Version
//              Information" and from GSCToolbox
//
//  UPDATED   : 2007/02/19
//
//***************************************************************************
function GetFileResourceString(sFileName : String;
                               sVersionKey : string) : String;
var
  dwDummy, dwInfoSize, Len: DWORD;
  Buf: PChar;
  Value: PChar;
  sLocaleString : String;
begin
  sLocaleString := GetFileTranslation(sFileName,False);
  dwInfoSize := GetFileVersionInfoSize(PChar(sFileName), dwDummy);
  if (dwInfoSize > 0) then
  begin
    Buf := AllocMem(dwInfoSize);
    try
      GetFileVersionInfo(PChar(sFileName), 0, dwInfoSize, Buf);
      if VerQueryValue(Buf, PChar('\\StringFileInfo\\' + sLocaleString + '\\'+sVersionKey),
                       Pointer(Value), Len) then
        result := Value
      else
        result := '';
    finally
      FreeMem(Buf, dwInfoSize);
    end; // finally
  end
  else
    result := '';
end; // GetFileResourceString

//***************************************************************************
//
//  FUNCTION  : FolderEmpty
//
//  I/P       : sDirectory (string) - The directory to be checked
//
//  O/P       : (boolean) - TRUE if the folder contains no files
//
//  OPERATION : Checks if a folder is empty.
//
//              Lifted from
//              http://delphi.about.com/od/delphitips2007/qt/isfolderempty.htm
//
//  UPDATED   : 2007/04/26
//
//***************************************************************************
function FolderEmpty(sDirectory : string) : boolean;
var
  searchRec :TSearchRec;
begin
  try
   result := (FindFirst(IncludeTrailingPathDelimiter(sDirectory) + '*.*', faAnyFile, searchRec) = 0) and
             (FindNext(searchRec) = 0) and
             (FindNext(searchRec) <> 0) ;
  finally
    SysUtils.FindClose(searchRec);
  end;
end;

//***************************************************************************
//
//  FUNCTION  : FolderIsEmpty
//
//  I/P       : sFolder : String - Folder to be examined (with or without
//                the trailing path delimiter).
//
//  O/P       : TRUE if the folder contains no files.
//
//  OPERATION : from
//              http://delphi.about.com/od/delphitips2007/qt/isfolderempty.htm
//
//  UPDATED   :
//
//***************************************************************************
function FolderIsEmpty(const sFolder : string) : boolean;
var
  searchRec :TSearchRec;

begin
  try
    result := (FindFirst(IncludeTrailingPathDelimiter(sFolder) + '*.*', faAnyFile, searchRec) = 0) and
              (FindNext(searchRec) = 0) and
              (FindNext(searchRec) <> 0);
  finally
    SysUtils.FindClose(searchRec);
  end;
end; // FolderIsEmpty

//returns the parent directory for the
 //provided "path" (file or directory)

//***************************************************************************
//
//  FUNCTION  : GetParentFolder
//
//  I/P       : sPath : String - file or folder name
//
//  O/P       :
//
//  OPERATION : Gets the parent folder for a specified file or folder name,
//              For example, for a given file named: "c:\My Documents\Pictures\ADP2008.gif",
//              the parent folder is "c:\My Documents\Pictures".
//
//              If a folder is specified as "c:\My Documents\Pictures", the parent folder
//              is then "c:\My Documents". Therefore, parent directory is the directory
//              that is one level up from the specified directory.
//
//              from
//              http://delphi.about.com/od/delphitips2007/qt/parent_folder.htm
//
//              ANS : Test this with sPath ending in a backslash, and with a file name.
//
//  UPDATED   : 2010-04-30
//
//***************************************************************************
function GetParentFolder(sPath : string) : String;
begin
  result := ExpandFileName(sPath + '\..')
end;


//fills the "list" TStrings with the subdirectories of the "directory" directory

//***************************************************************************
//
//  FUNCTION  : GetSubFolders
//
//  I/P       : sFolder : String - the folder to be examined (e.g. 'C:\')
//
//  O/P       : sList : TStrings - A list filled with all the subdirectories
//                of the given folder
//
//  OPERATION : List all sub-directories for a given directory
//
//              from
//              http://delphi.about.com/od/delphitips2008/qt/subdirectories.htm
//
//  UPDATED   : 2010-04-30
//
//***************************************************************************
procedure GetSubFolders(const sFolder : String;
                        sList : TStrings);
var
  sr : TSearchRec;

begin
  try
    if FindFirst(IncludeTrailingPathDelimiter(sFolder) + '*.*', faDirectory, sr) < 0 then
      Exit
    else
    repeat
      if ((sr.Attr and faDirectory <> 0) and
          (sr.Name <> '.') and
          (sr.Name <> '..')) then
        sList.Add(IncludeTrailingPathDelimiter(sFolder) + sr.Name) ;
    until FindNext(sr) <> 0;
  finally
    SysUtils.FindClose(sr) ;
  end;
end; // GetSubFolders

//***************************************************************************
//
//  FUNCTION  : DateTimeInfo
//
//  I/P       : sPath : String - The folder or file to be examined
//
//              faExamine : - The file attributes of sPath
//
//  O/P       : dtCreated : TDateTime - Date/time when file was created
//
//              dtLastAccessed : TDateTime - Date/time file was last opened?
//
//              dtLastWriten : TDateTime - Not sure of the difference between this and dtLastModified
//
//              dtLastModified : TDateTime - Not sure of the difference between this and dtLastWritten
//
//  OPERATION : from
//              http://delphi.about.com/od/delphitips2007/qt/directory_dates.htm
//
//  UPDATED   : 2010-04-30
//
//***************************************************************************
procedure DateTimeInfo(const sPath : String;
                       const iFileAttributes : Integer;
                       var dtCreated : TDateTime;
                       var dtLastAccessed : TDateTime;
                       var dtLastWriten : TDateTime;
                       var dtLastModified : TDateTime);
var
  sr : TSearchRec;
  creationTimeSystem: TSystemTime;
  lastAccessTimeSystem: TSystemTime;
  lastWriteTimeSystem: TSystemTime;

begin
  if sysUtils.FindFirst(sPath, iFileAttributes, sr) = 0 then
    try
      dtLastModified := sr.TimeStamp;

      FileTimeToSystemTime(sr.FindData.ftCreationTime, creationTimeSystem) ;
      with creationTimeSystem do
        dtCreated := EncodeDateTime(wYear, wMonth, wDay, wHour, wMinute, wSecond, wMilliseconds);

      FileTimeToSystemTime(sr.FindData.ftLastAccessTime, lastAccessTimeSystem);
      with lastAccessTimeSystem do
        dtLastAccessed := EncodeDateTime(wYear, wMonth, wDay, wHour, wMinute, wSecond, wMilliseconds);

      FileTimeToSystemTime(sr.FindData.ftLastWriteTime, lastWriteTimeSystem);
      with lastWriteTimeSystem do
        dtLastWriten := EncodeDateTime(wYear, wMonth, wDay, wHour, wMinute, wSecond, wMilliseconds);
    finally
      SysUtils.FindClose(sr);
    end
  else
  begin
    dtCreated := 0.0;
    dtLastAccessed := 0.0;
    dtLastWriten := 0.0;
    dtLastModified := 0.0;
  end; // else
end;

//***************************************************************************
//
//  FUNCTION  : InitGetFolderSize and
//              GetFolderSize
//
//  I/P       : sFolder : String - The starting folder
//
//  O/P       : integer : the size of files in the folder.
//
//  OPERATION : This function it looks at hidden, system, archive, and normal
//              files; it uses a recursive algorithm to look in all sub-directories
//              also.
//
//              WARNING : Note the use of a global variable iDirBytes.   This
//                must be zeroed before calling this function, using InitGetFolderSize.
//
//              from
//              http://delphi.about.com/cs/adptips2002/a/bltip0702_2.htm
//
//  UPDATED   : 2010-04-30
//
//***************************************************************************
procedure InitGetFolderSize;
begin
  iDirBytes := 0;
end; // InitGetFolderSize

function GetFolderSize(sFolder:string) : Integer;
var
  SearchRec : TSearchRec;
  Separator : String;

begin
  if (Copy(sFolder,Length(sFolder),1) = TPath.DirectorySeparatorChar) then
    Separator := ''
  else
    Separator := TPath.DirectorySeparatorChar;

  if (FindFirst(sFolder + Separator + '*.*',faAnyFile,SearchRec) = 0) then
  begin
    if (SysUtils.FileExists(sFolder + Separator + SearchRec.Name)) then
    begin
      iDirBytes := iDirBytes + SearchRec.Size;
    end
    else
      if (SysUtils.DirectoryExists(sFolder + Separator + SearchRec.Name)) then
      begin
        if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
        begin
          GetFolderSize(sFolder + Separator + SearchRec.Name);
        end;
      end; // if

    while FindNext(SearchRec) = 0 do
    begin
      if (SysUtils.FileExists(sFolder + Separator + SearchRec.Name)) then
      begin
        iDirBytes := iDirBytes + SearchRec.Size;
      end
      else
        if (SysUtils.DirectoryExists(sFolder + Separator + SearchRec.Name)) then
        begin
          if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
          begin
            GetFolderSize(sFolder + Separator + SearchRec.Name) ;
          end; // if
        end; // if
    end; // while
  end; // if

  SysUtils.FindClose(SearchRec) ;
  result := iDirBytes;
end; // GetFolderSize

//***************************************************************************
//
//  FUNCTION  : DelTree
//
//  I/P       : DirName : String - The directory to be deleted
//
//  O/P       : Boolean - TRUE if operation was successful
//
//  OPERATION : The following function completely deletes a directory
//              regardless of whether the directory is filled or has subdirectories.
//              No confirmation is requested so be careful.
//
//              http://delphi.about.com/cs/adptips1999/a/bltip1199_2.htm
//
//  UPDATED   : 2010-09-02
//
//***************************************************************************
function DelTree(DirName : string): boolean;
var
  SHFileOpStruct : TSHFileOpStruct;
  DirBuf : array [0..255] of char;
begin
  try
    Fillchar(SHFileOpStruct,Sizeof(SHFileOpStruct),0) ;
    FillChar(DirBuf, Sizeof(DirBuf), 0 ) ;
    StrPCopy(DirBuf, DirName) ;
    with SHFileOpStruct do
    begin
      Wnd := 0;
      pFrom := @DirBuf;
      wFunc := FO_DELETE;
      fFlags := FOF_ALLOWUNDO;
      fFlags := fFlags or FOF_NOCONFIRMATION;
      fFlags := fFlags or FOF_SILENT;
    end;
    Result := (SHFileOperation(SHFileOpStruct) = 0) ;
   except
     Result := False;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : GetSpecialFolderPath
//
//  I/P       : Integer - CSIDL value (From constants held in the WinAPI.SHFolder
//                or ShlObj units)
//
//  O/P       : String - Full path to a special folder (no trailing backslash)
//
//  OPERATION : Get paths for special Windows folders.
//
//              Example values :
//                CSIDL_COMMON_DESKTOPDIRECTORY
//                CSIDL_COMMON_APPDATA
//                CSIDL_COMMON_DOCUMENTS - (Note : Embedded XP would not write here - it went to the TEMP folder)
//                CSIDL_PERSONAL
//
//              see http://delphi.about.com/od/kbwinshell/a/SHGetFolderPath.htm
// https://msdn.microsoft.com/en-us/library/windows/desktop/bb762494(v=vs.85).aspx
//
//  UPDATED   : 2015-10-12
//
//***************************************************************************
function GetSpecialFolderPath(iFolder : integer) : String;
const
  SHGFP_TYPE_CURRENT = 0;
var
  acPath: array [0..MAX_PATH] of char;

begin
  if SUCCEEDED(SHGetFolderPath(0,iFolder,0,SHGFP_TYPE_CURRENT,@acPath[0])) then
    Result := acPath
  else
    Result := '';
end; // GetSpecialFolderPath
(*
//***************************************************************************
//
//  FUNCTION  : GetKnownFolder
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  see https://msdn.microsoft.com/en-us/library/bb762584(VS.85).aspx
//
//  UPDATED   :
//
//***************************************************************************
function GetKnownFolder(knownFolderID : ??) : String;
begin
KnownFolders.pas





function GetCommonAppDataPath: string;
const
  FOLDERID_ProgramData: TGUID = '{62AB5D82-FDC1-4DC3-A9DD-070D1D495D97}';
  KF_FLAG_CREATE = $8000;
var
  Path: PWideChar;
begin
  Path := nil;
  try
    OleCheck(SHGetKnownFolderPath(FOLDERID_ProgramData, KF_FLAG_CREATE, 0, Path));
    Result := Path;
  finally
    CoTaskMemFree(Path);
  end;
end;




end; // GetKnownFolder
*)
//***************************************************************************
//
//  FUNCTION  : GetDriveSerialNo
//
//  I/P       : sDrive : String - 'c:' or such-like, with or without a
//                trailing delimiter.
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2024-08-19
//
//***************************************************************************
function GetDriveSerialNo(sDrive : string) : String;
var VolSerNum: DWORD;
    Dummy1, Dummy2: DWORD;

begin
  if GetVolumeInformation(PWideChar(IncludeTrailingPathDelimiter(sDrive)), NIL, 0, @VolSerNum, Dummy1, Dummy2, NIL, 0) then
  begin
    Result := Format('%.4x:%.4x', [HiWord(VolSerNum), LoWord(VolSerNum)]);
  end;
end; // GetDriveSerialNo

//***************************************************************************
//
//  FUNCTION  : MovedFolder
//
//  I/P       : folderSrc : String - Source folder, with or without the
//                trailing path delimiter (e.g. 'E:\Temp')
//
//              folderDest : String - Destination folder, with or without the
//                trailing path delimiter (e.g. 'C:\Dest')
//
//  O/P       : Boolean : TRUE if the operation was a success
//
//  OPERATION : Moves all the contents (files, folders and subfolders) from
//              one folder to another one.   Leaves an empty source folder.
//
//              This pops up a Windows progress window
//
//  UPDATED   : 2018-01-17
//
//***************************************************************************
function MovedFolder(folderSrc : String;
                     folderDest : String) : Boolean;
var
  FOS: TSHFileOpStruct;

begin
  ZeroMemory(@FOS, SizeOf(FOS));
  with FOS do
  begin
    wFunc  := FO_MOVE; // FO_COPY;
    fFlags := FOF_ALLOWUNDO or FOF_SIMPLEPROGRESS;
    pFrom  := PChar(IncludeTrailingPathDelimiter(folderSrc) + '*.*'#0);
    pTo    := PChar(folderDest + #0);
  end;
  Result := (SHFileOperation(FOS) = 0);
end; // MovedFolder


//***************************************************************************
//
//  FUNCTION   : GetTextFileEncoding
//
//  I/P        :
//
//  O/P        :
//
//  OPERATION  : I had to add fmShareDenyNone to the Create parameters to prevent
//               some sharing errors that appeared when the file is in Public Documents (!)
//
//  UPDATED    : 2013-11-28
//
//***************************************************************************
function GetTextFileEncoding(sFileName : string) : TEncoding;
var
  LBuffer : TBytes;
  LFileStream : TFileStream;
  LEncoding : TEncoding;

begin
  if (SysUtils.FileExists(sFileName)) then
  begin
    LEncoding := nil;
    LFileStream := TFileStream.Create(sFileName,fmOpenRead or fmShareDenyNone);
    try
      SetLength(LBuffer, Min(10,LFileStream.Size));
      LFileStream.ReadBuffer(Pointer(LBuffer)^, Length(LBuffer));
      TEncoding.GetBufferEncoding(LBuffer, LEncoding);
      result := LEncoding;
    finally
      LFileStream.Free;
    end;
  end // if
  else
    result := TEncoding.ASCII;
end;

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : This function needs some more work, and then to be tested.
//              It was presented as an OnClick function for a button on a form,
//              and copied three files.
//
//              It was lifted from
//              http://delphi.about.com/cs/adptips2001/a/bltip0201_3.htm
//
//  UPDATED   :
//
//***************************************************************************
(*
function ShellCopy(sFileNames : String;
                   sDestination : string) : boolean;
var
  Fos : TSHFileOpStruct;
  Buf : array[0..4096] of char;
  p : pchar;

begin

  // Modify this to make use of sFileNames
  FillChar(Buf, sizeof(Buf), #0) ;
  p := @buf;
  p := StrECopy(p, 'C:\FirstFile.ext1') + 1;
  p := StrECopy(p, 'C:\SecondFile.ext2') + 1;
  StrECopy(p, 'C:\ThirdFile.ext3') ;

  sDestination := IncludeTrailingPathDelimiter(sDestination);

  FillChar(Fos, sizeof(Fos), #0) ;
  with Fos do
  begin
    Wnd := Handle;
    wFunc := FO_COPY;
    pFrom := @Buf;
    pTo := sDest;
    fFlags := 0;
  end; // with

  if ((SHFileOperation(Fos) <> 0) or
      (Fos.fAnyOperationsAborted <> false)) then
    result := FALSE
  else
    result := TRUE;

end; // ShellCopy
*)

//***************************************************************************
//
//  FUNCTION  : GetTemporaryFolder
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
// When run by a user, this gives a folder like
// C:\Users\Kinetic\AppData\Local\
// When run from a service, this gives a folder like
// C:\WINDOWS\system32\config\systemprofile\AppData\Local\
// The second one is difficult to access and appears to be under some sort of control
// after the program has terminated, so contents can not be analysed.
//
//  UPDATED   : 2019-05-01
//
//***************************************************************************
function GetTemporaryFolder(Folder : string) : String;
begin
  result := IncludeTrailingPathDelimiter(
              IncludeTrailingPathDelimiter(GetSpecialFolderPath(CSIDL_LOCAL_APPDATA)) +
              Folder);
//  result := 'C:\LockedTemp\';

  SysUtils.ForceDirectories(result);
  if (not SysUtils.DirectoryExists(result)) then
  begin
    // Just in case we could not create the working dir (which is unlikely)
    result := 'C:\Temp\';
    SysUtils.ForceDirectories(result);
  end; // if

//  Test that we can read/write to this folder
//  Gerhard had no access on his Documents and Settings folders!
end;

//***************************************************************************
//
//  FUNCTION  : RefreshMappedDrive
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : From https://www.experts-exchange.com/questions/28697025/Activate-Mapped-Drive.html
//
//              Usage
(*
  if FileExists('z:\test.txt') then
    Memo2.Lines.Add('exists')
  else
  begin
    Memo2.Lines.Add('connecting');

    CoInitialize(nil);
    try
      RefreshMappedDrive('Z');
    finally
      CoUninitialize;
    end;
  end;
*)
//
//  UPDATED   : 2017-10-27
//
//***************************************************************************
function RefreshMappedDrive(cDrvLetter: Char): Boolean;
const
  WbemUser            ='';
  WbemPassword        ='';
  WbemComputer        ='localhost';
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator : OLEVariant;
  FWMIService   : OLEVariant;
  FWbemObjectSet: OLEVariant;
  FWbemObject   : OLEVariant;
  oEnum         : IEnumvariant;
  iValue        : LongWord;
  WshNetwork    : OLEVariant;

begin;
  Result := False;

  FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
  FWMIService   := FSWbemLocator.ConnectServer(WbemComputer, 'root\CIMV2', WbemUser, WbemPassword);
  FWbemObjectSet:= FWMIService.ExecQuery('SELECT LocalName,ConnectionState,RemotePath FROM Win32_NetworkConnection','WQL',wbemFlagForwardOnly);
  oEnum         := IUnknown(FWbemObjectSet._NewEnum) as IEnumVariant;
  while oEnum.Next(1, FWbemObject, iValue) = 0 do
  begin
    if String(FWbemObject.LocalName) = (cDrvLetter+':') then //if this drive
    begin
      if String(FWbemObject.ConnectionState) <> 'Connected' then //if disconnected
      begin
        //try to reconnect ....
        try
          WshNetwork := CreateOleObject('WScript.Network');
          WshNetwork.MapNetworkDrive(cDrvLetter+':', String(FWbemObject.RemotePath));
        except
        end;
        Result := True;
      end
      else
      begin
        Result := True;
      end;
      Break;
    end;
    FWbemObject := Unassigned;
  end;
end;

//***************************************************************************
//
//  FUNCTION  : GetNetworkDriveMappings
//
//  I/P       : SList: TStrings - Where the results will be stored
//
//              allRemembered : Boolean - TRUE to include remembered (but
//                currently unconnected) mapped drives
//
//  O/P       :
//
//  OPERATION : From http://delphi.about.com/cs/adptips2001/a/bltip0401_2.htm
//
//  UPDATED   : 2018-01-12
//
//***************************************************************************
function GetNetworkDriveMappings(SList: TStrings;
                                 allRemembered : Boolean): integer;
var
  i: Char;
  ThePath: string;
  MaxNetPathLen: DWord;
  connResult : DWord;

begin
  SList.Clear;
  MaxNetPathLen := MAX_PATH;
  SetLength(ThePath, MAX_PATH);
  for i := 'A' to 'Z' do
  begin
    connResult := WNetGetConnection(PChar('' + i + ':'),PChar(ThePath),MaxNetPathLen);
    if ((connResult = NO_ERROR) or
        (((connResult = ERROR_CONNECTION_UNAVAIL) and
          (allRemembered)))) then
      SList.Add(i + ': ' + ThePath);
  end;
  result := SList.Count;
end; // GetNetworkDriveMappings

//***************************************************************************
//
//  FUNCTION  : RefreshAllMappedDrives
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : See GetNetworkDriveMappings above
//
//  UPDATED   : 2018-01-12
//
//***************************************************************************
procedure RefreshAllMappedDrives;
var
  i: Char;
  ThePath: string;
  MaxNetPathLen: DWord;
  connResult : DWord;

begin
  MaxNetPathLen := MAX_PATH;
  SetLength(ThePath, MAX_PATH);
  for i := 'A' to 'Z' do
  begin
    connResult := WNetGetConnection(PChar('' + i + ':'),PChar(ThePath),MaxNetPathLen);
    if (connResult = ERROR_CONNECTION_UNAVAIL) then
      RefreshMappedDrive(i);
  end;
end; // RefreshAllMappedDrives

//***************************************************************************
//
//  FUNCTION  : FilesBackedUp
//
//  I/P       : pathSource : String - Full path to the files to be copied.
//
//              pathDestination : String - Full path to the destination.
//
//  O/P       : Boolean - TRUE if the operation was successful.
//
//  OPERATION : Copies all files in the root of pathSource to a given folder.
//
//  UPDATED   : 2018-03-06
//
//***************************************************************************
function FilesBackedUp(pathSource : String;
                       pathDestination : String) : Boolean;
begin
  result := (SysUtils.ForceDirectories(pathDestination)) and
            (XCopyFiles(pathSource, pathDestination, FALSE, FALSE,
                        TRUE, FALSE, 0, 0) = 0);
end; // FilesBackedUp

//***************************************************************************
//
//  FUNCTION  : FilesSortedAlphabetically
//
//  I/P       : const path : String - The folder and file name mask, including
//                wildcard characters, as used by FindFirst.
//
//              attr : Integer - the special files to include in addition to
//                all normal files, as used by FindFirst.
//
//              pbProgess : TProgressBar - A progress bar, if one is required,
//                which is advanced in position with each file found.
//
//  O/P       : filesFound : TStringList - A sorted list of the required files.
//
//  OPERATION : Returns a string list of all files found in a FindFirst/FindNext
//              operation, sorted in alphabetical order.
//
//  UPDATED   : 2018-12-03
//
//***************************************************************************
procedure FilesSortedAlphabetically(const path : String;
                                    attr : Integer;
                                    aProgressBar : TProgressBar;
                                    const filesFound : TStringList);
var
  fresult : Integer;
  srFile : TSearchRec;

begin
  filesFound.Clear;
  fresult := FindFirst(path, attr, srFile);
  while (fresult = 0) do
  begin
    if ((srFile.Name <> '.') and
        (srFile.Name <> '..')) then
    begin
      filesFound.Add(srFile.Name);
      if (aProgressBar <> nil) then
      begin
        aProgressBar.Position := aProgressBar.Position + 1;
        aProgressBar.Update;
      end;
    end; // if
    fresult := FindNext(srFile);
  end; // while
  SysUtils.FindClose(srFile);
  filesFound.Sort;
end; // FilesSortedAlphabetically

//***************************************************************************
//
//  FUNCTION  : FileExistsA
//
//  I/P       : path : String - The directory and file name mask, including
//                wildcard characters.
//
//              attr : Integer - specifies the special files to include, in
//                addition to all normal files.
//
//  O/P       : Boolean - TRUE if one or more files are found that match the
//                requirements.
//
//  OPERATION : Check if one or more files, with specified path (may include
//              wildcards, or exact, full name) exist, with the specified attributes.
//
//  UPDATED   : 2018-12-04
//
//***************************************************************************
function FileExistsA(const path : String;
                     attr : Integer) : Boolean;
var
  sr : TSearchRec;

begin
  result := (FindFirst(path, attr, sr) = 0);
  SysUtils.FindClose(sr);
end; // FileExistsA

//***************************************************************************
//
//  FUNCTION  : FileErrorText
//
//  I/P       : idError : Integer - FileIO error number, or error number from
//                the operations in this unit.
//
//  O/P       : String - A description of the error that has occurred.
//
//  OPERATION : This is meant for debugging and internal use only. It is not
//              intended that these messages should reach end users, and
//              in particular, they are not intended to be translated.
//
//  UPDATED   : 2019-06-03
//
//***************************************************************************
function FileErrorText(idError : Integer) : String;
begin
  case idError of
    FOE_NO_SOURCE_FILE_SPECIFIED : result := 'No source file specified';
    FOE_NO_DEST_FILE_SPECIFIED : result := 'No destination file specified';
    FOE_COULD_NOT_MAKE_DEST : result := 'Unable to create destination ';
    FOE_INVALID_PATH : result := 'Invalid path';
    FOE_INVALID_TARGET : result := 'Invalid target';
    FOE_FOLDER_NOT_DELETED : result := 'Folder not deleted';
    FOE_FILE_NOT_DELETED : result := 'File not deleted';
    FOE_NO_FILE_SPECIFIED : result := 'No file specified';

    // The following (positive) codes are from Winapi.Windows.pas

    { . }
    ERROR_SUCCESS : result := 'The operation completed successfully';
    ERROR_INVALID_FUNCTION : result := 'Incorrect function';
    ERROR_FILE_NOT_FOUND : result := 'The system cannot find the file specified';
    ERROR_PATH_NOT_FOUND : result := 'The system cannot find the path specified';
    ERROR_TOO_MANY_OPEN_FILES : result := 'The system cannot open the file';
    ERROR_ACCESS_DENIED : result := 'Access is denied';
    ERROR_INVALID_HANDLE : result := 'The handle is invalid';
    ERROR_ARENA_TRASHED : result := 'The storage control blocks were destroyed';
    ERROR_NOT_ENOUGH_MEMORY : result := 'Not enough storage is available to process this command';
    ERROR_INVALID_BLOCK : result := 'The storage control block address is invalid';
    ERROR_BAD_ENVIRONMENT : result := 'The environment is incorrect';
    ERROR_BAD_FORMAT : result := 'An attempt was made to load a program with an incorrect format';
    ERROR_INVALID_ACCESS : result := 'The access code is invalid';
    ERROR_INVALID_DATA : result := 'The data is invalid';
    ERROR_OUTOFMEMORY : result := 'Not enough storage is available to complete this operation';
    ERROR_INVALID_DRIVE : result := 'The system cannot find the drive specified';
    ERROR_CURRENT_DIRECTORY : result := 'The directory cannot be removed';
    ERROR_NOT_SAME_DEVICE : result := 'The system cannot move the file to a different disk drive';
    ERROR_NO_MORE_FILES : result := 'There are no more files';
    ERROR_WRITE_PROTECT : result := 'The media is write protected';
    ERROR_BAD_UNIT : result := 'The system cannot find the device specified';
    ERROR_NOT_READY : result := 'The device is not ready';
    ERROR_BAD_COMMAND : result := 'The device does not recognize the command';
    ERROR_CRC : result := 'Data error (cyclic redundancy check)';
    ERROR_BAD_LENGTH : result := 'The program issued a command but the command length is incorrect';
    ERROR_SEEK : result := 'The drive cannot locate a specific area or track on the disk';
    ERROR_NOT_DOS_DISK : result := 'The specified disk or diskette cannot be accessed';
    ERROR_SECTOR_NOT_FOUND : result := 'The drive cannot find the sector requested';
    ERROR_OUT_OF_PAPER : result := 'The printer is out of paper';
    ERROR_WRITE_FAULT : result := 'The system cannot write to the specified device';
    ERROR_READ_FAULT : result := 'The system cannot read from the specified device';
    ERROR_GEN_FAILURE : result := 'A device attached to the system is not functioning';
    ERROR_SHARING_VIOLATION : result := 'The process cannot access the file because it is being used by another process';
    ERROR_LOCK_VIOLATION : result := 'The process cannot access the file because another process has locked a portion of the file';
(*
 : result := 'The wrong diskette is in the drive. Insert %2 (Volume Serial Number: %3) }
 : result := 'into drive %1';
    ERROR_WRONG_DISK = 34;
    {$EXTERNALSYM ERROR_WRONG_DISK}

 : result := 'Too many files opened for sharing';
    ERROR_SHARING_BUFFER_EXCEEDED = 36;
    {$EXTERNALSYM ERROR_SHARING_BUFFER_EXCEEDED}

 : result := 'Reached end of file';
    ERROR_HANDLE_EOF = 38;
    {$EXTERNALSYM ERROR_HANDLE_EOF}

 : result := 'The disk is full';
    ERROR_HANDLE_DISK_FULL = 39;
    {$EXTERNALSYM ERROR_HANDLE_DISK_FULL}

 : result := 'The network request is not supported';
    ERROR_NOT_SUPPORTED = 50;
    {$EXTERNALSYM ERROR_NOT_SUPPORTED}

 : result := 'The remote computer is not available';
    ERROR_REM_NOT_LIST = 51;
    {$EXTERNALSYM ERROR_REM_NOT_LIST}

 : result := 'A duplicate name exists on the network';
    ERROR_DUP_NAME = 52;
    {$EXTERNALSYM ERROR_DUP_NAME}

 : result := 'The network path was not found';
    ERROR_BAD_NETPATH = 53;
    {$EXTERNALSYM ERROR_BAD_NETPATH}

 : result := 'The network is busy';
    ERROR_NETWORK_BUSY = 54;
    {$EXTERNALSYM ERROR_NETWORK_BUSY}

 : result := 'The specified network resource or device is no longer }
 : result := 'available';
    ERROR_DEV_NOT_EXIST = 55;   { dderror }
    {$EXTERNALSYM ERROR_DEV_NOT_EXIST}

 : result := 'The network BIOS command limit has been reached';
    ERROR_TOO_MANY_CMDS = 56;
    {$EXTERNALSYM ERROR_TOO_MANY_CMDS}

 : result := 'A network adapter hardware error occurred';
    ERROR_ADAP_HDW_ERR = 57;
    {$EXTERNALSYM ERROR_ADAP_HDW_ERR}

 : result := 'The specified server cannot perform the requested }
 : result := 'operation';
    ERROR_BAD_NET_RESP = 58;
    {$EXTERNALSYM ERROR_BAD_NET_RESP}

 : result := 'An unexpected network error occurred';
    ERROR_UNEXP_NET_ERR = 59;
    {$EXTERNALSYM ERROR_UNEXP_NET_ERR}

 : result := 'The remote adapter is not compatible';
    ERROR_BAD_REM_ADAP = 60;
    {$EXTERNALSYM ERROR_BAD_REM_ADAP}

 : result := 'The printer queue is full';
    ERROR_PRINTQ_FULL = 61;
    {$EXTERNALSYM ERROR_PRINTQ_FULL}

 : result := 'Space to store the file waiting to be printed is }
 : result := 'not available on the server';
    ERROR_NO_SPOOL_SPACE = 62;
    {$EXTERNALSYM ERROR_NO_SPOOL_SPACE}

 : result := 'Your file waiting to be printed was deleted';
    ERROR_PRINT_CANCELLED = 63;
    {$EXTERNALSYM ERROR_PRINT_CANCELLED}

 : result := 'The specified network name is no longer available';
    ERROR_NETNAME_DELETED = $40;
    {$EXTERNALSYM ERROR_NETNAME_DELETED}

 : result := 'Network access is denied';
    ERROR_NETWORK_ACCESS_DENIED = 65;
    {$EXTERNALSYM ERROR_NETWORK_ACCESS_DENIED}

 : result := 'The network resource type is not correct';
    ERROR_BAD_DEV_TYPE = 66;
    {$EXTERNALSYM ERROR_BAD_DEV_TYPE}

 : result := 'The network name cannot be found';
    ERROR_BAD_NET_NAME = 67;
    {$EXTERNALSYM ERROR_BAD_NET_NAME}

 : result := 'The name limit for the local computer network }
 : result := 'adapter card was exceeded';
    ERROR_TOO_MANY_NAMES = 68;
    {$EXTERNALSYM ERROR_TOO_MANY_NAMES}

 : result := 'The network BIOS session limit was exceeded';
    ERROR_TOO_MANY_SESS = 69;
    {$EXTERNALSYM ERROR_TOO_MANY_SESS}

 : result := 'The remote server has been paused or is in the }
 : result := 'process of being started';
    ERROR_SHARING_PAUSED = 70;
    {$EXTERNALSYM ERROR_SHARING_PAUSED}

 : result := 'No more connections can be made to this remote computer at this time }
 : result := 'because there are already as many connections as the computer can accept';
    ERROR_REQ_NOT_ACCEP = 71;
    {$EXTERNALSYM ERROR_REQ_NOT_ACCEP}

 : result := 'The specified printer or disk device has been paused';
    ERROR_REDIR_PAUSED = 72;
    {$EXTERNALSYM ERROR_REDIR_PAUSED}

 : result := 'The file exists';
    ERROR_FILE_EXISTS = 80;
    {$EXTERNALSYM ERROR_FILE_EXISTS}

 : result := 'The directory or file cannot be created';
    ERROR_CANNOT_MAKE = 82;
    {$EXTERNALSYM ERROR_CANNOT_MAKE}

 : result := 'Fail on INT 24 }
    ERROR_FAIL_I24 = 83;
    {$EXTERNALSYM ERROR_FAIL_I24}

 : result := 'Storage to process this request is not available';
    ERROR_OUT_OF_STRUCTURES = 84;
    {$EXTERNALSYM ERROR_OUT_OF_STRUCTURES}

 : result := 'The local device name is already in use';
    ERROR_ALREADY_ASSIGNED = 85;
    {$EXTERNALSYM ERROR_ALREADY_ASSIGNED}

 : result := 'The specified network password is not correct';
    ERROR_INVALID_PASSWORD = 86;
    {$EXTERNALSYM ERROR_INVALID_PASSWORD}

 : result := 'The parameter is incorrect';
    ERROR_INVALID_PARAMETER = 87;   { dderror }
    {$EXTERNALSYM ERROR_INVALID_PARAMETER}

 : result := 'A write fault occurred on the network';
    ERROR_NET_WRITE_FAULT = 88;
    {$EXTERNALSYM ERROR_NET_WRITE_FAULT}

 : result := 'The system cannot start another process at }
 : result := 'this time';
    ERROR_NO_PROC_SLOTS = 89;
    {$EXTERNALSYM ERROR_NO_PROC_SLOTS}

 : result := 'Cannot create another system semaphore';
    ERROR_TOO_MANY_SEMAPHORES = 100;
    {$EXTERNALSYM ERROR_TOO_MANY_SEMAPHORES}

 : result := 'The exclusive semaphore is owned by another process';
    ERROR_EXCL_SEM_ALREADY_OWNED = 101;
    {$EXTERNALSYM ERROR_EXCL_SEM_ALREADY_OWNED}

 : result := 'The semaphore is set and cannot be closed';
    ERROR_SEM_IS_SET = 102;
    {$EXTERNALSYM ERROR_SEM_IS_SET}

 : result := 'The semaphore cannot be set again';
    ERROR_TOO_MANY_SEM_REQUESTS = 103;
    {$EXTERNALSYM ERROR_TOO_MANY_SEM_REQUESTS}

 : result := 'Cannot request exclusive semaphores at interrupt time';
    ERROR_INVALID_AT_INTERRUPT_TIME = 104;
    {$EXTERNALSYM ERROR_INVALID_AT_INTERRUPT_TIME}

 : result := 'The previous ownership of this semaphore has ended';
    ERROR_SEM_OWNER_DIED = 105;
    {$EXTERNALSYM ERROR_SEM_OWNER_DIED}

 : result := 'Insert the diskette for drive %1';
    ERROR_SEM_USER_LIMIT = 106;
    {$EXTERNALSYM ERROR_SEM_USER_LIMIT}

 : result := 'Program stopped because alternate diskette was not inserted';
    ERROR_DISK_CHANGE = 107;
    {$EXTERNALSYM ERROR_DISK_CHANGE}

 : result := 'The disk is in use or locked by }
 : result := 'another process';
    ERROR_DRIVE_LOCKED = 108;
    {$EXTERNALSYM ERROR_DRIVE_LOCKED}

 : result := 'The pipe has been ended';
    ERROR_BROKEN_PIPE = 109;
    {$EXTERNALSYM ERROR_BROKEN_PIPE}

 : result := 'The system cannot open the device or file specified';
    ERROR_OPEN_FAILED = 110;
    {$EXTERNALSYM ERROR_OPEN_FAILED}

 : result := 'The file name is too long';
    ERROR_BUFFER_OVERFLOW = 111;
    {$EXTERNALSYM ERROR_BUFFER_OVERFLOW}

 : result := 'There is not enough space on the disk';
    ERROR_DISK_FULL = 112;
    {$EXTERNALSYM ERROR_DISK_FULL}

 : result := 'No more internal file identifiers available';
    ERROR_NO_MORE_SEARCH_HANDLES = 113;
    {$EXTERNALSYM ERROR_NO_MORE_SEARCH_HANDLES}

 : result := 'The target internal file identifier is incorrect';
    ERROR_INVALID_TARGET_HANDLE = 114;
    {$EXTERNALSYM ERROR_INVALID_TARGET_HANDLE}

 : result := 'The IOCTL call made by the application program is not correct';
    ERROR_INVALID_CATEGORY = 117;
    {$EXTERNALSYM ERROR_INVALID_CATEGORY}

 : result := 'The verify-on-write switch parameter value is not correct';
    ERROR_INVALID_VERIFY_SWITCH = 118;
    {$EXTERNALSYM ERROR_INVALID_VERIFY_SWITCH}

 : result := 'The system does not support the command requested';
    ERROR_BAD_DRIVER_LEVEL = 119;
    {$EXTERNALSYM ERROR_BAD_DRIVER_LEVEL}

 : result := 'This function is only valid in Windows NT mode';
    ERROR_CALL_NOT_IMPLEMENTED = 120;
    {$EXTERNALSYM ERROR_CALL_NOT_IMPLEMENTED}

 : result := 'The semaphore timeout period has expired';
    ERROR_SEM_TIMEOUT = 121;
    {$EXTERNALSYM ERROR_SEM_TIMEOUT}

 : result := 'The data area passed to a system call is too small';
    ERROR_INSUFFICIENT_BUFFER = 122;   { dderror }
    {$EXTERNALSYM ERROR_INSUFFICIENT_BUFFER}

 : result := 'The filename, directory name, or volume label syntax is incorrect';
    ERROR_INVALID_NAME = 123;
    {$EXTERNALSYM ERROR_INVALID_NAME}

 : result := 'The system call level is not correct';
    ERROR_INVALID_LEVEL = 124;
    {$EXTERNALSYM ERROR_INVALID_LEVEL}

 : result := 'The disk has no volume label';
    ERROR_NO_VOLUME_LABEL = 125;
    {$EXTERNALSYM ERROR_NO_VOLUME_LABEL}

 : result := 'The specified module could not be found';
    ERROR_MOD_NOT_FOUND = 126;
    {$EXTERNALSYM ERROR_MOD_NOT_FOUND}

 : result := 'The specified procedure could not be found';
    ERROR_PROC_NOT_FOUND = 127;
    {$EXTERNALSYM ERROR_PROC_NOT_FOUND}

 : result := 'There are no child processes to wait for';
    ERROR_WAIT_NO_CHILDREN = $80;
    {$EXTERNALSYM ERROR_WAIT_NO_CHILDREN}

 : result := 'The %1 application cannot be run in Windows NT mode';
    ERROR_CHILD_NOT_COMPLETE = 129;
    {$EXTERNALSYM ERROR_CHILD_NOT_COMPLETE}

 : result := 'Attempt to use a file handle to an open disk partition for an }
 : result := 'operation other than raw disk I/O';
    ERROR_DIRECT_ACCESS_HANDLE = 130;
    {$EXTERNALSYM ERROR_DIRECT_ACCESS_HANDLE}

 : result := 'An attempt was made to move the file pointer before the beginning of the file';
    ERROR_NEGATIVE_SEEK = 131;
    {$EXTERNALSYM ERROR_NEGATIVE_SEEK}

 : result := 'The file pointer cannot be set on the specified device or file';
    ERROR_SEEK_ON_DEVICE = 132;
    {$EXTERNALSYM ERROR_SEEK_ON_DEVICE}

 : result := 'A JOIN or SUBST command }
 : result := 'cannot be used for a drive that }
 : result := 'contains previously joined drives';
    ERROR_IS_JOIN_TARGET = 133;
    {$EXTERNALSYM ERROR_IS_JOIN_TARGET}

 : result := 'An attempt was made to use a }
 : result := 'JOIN or SUBST command on a drive that has }
 : result := 'already been joined';
    ERROR_IS_JOINED = 134;
    {$EXTERNALSYM ERROR_IS_JOINED}

 : result := 'An attempt was made to use a }
 : result := 'JOIN or SUBST command on a drive that has }
 : result := 'already been substituted';
    ERROR_IS_SUBSTED = 135;
    {$EXTERNALSYM ERROR_IS_SUBSTED}

 : result := 'The system tried to delete }
 : result := 'the JOIN of a drive that is not joined';
    ERROR_NOT_JOINED = 136;
    {$EXTERNALSYM ERROR_NOT_JOINED}

 : result := 'The system tried to delete the }
 : result := 'substitution of a drive that is not substituted';
    ERROR_NOT_SUBSTED = 137;
    {$EXTERNALSYM ERROR_NOT_SUBSTED}

 : result := 'The system tried to join a drive to a directory on a joined drive';
    ERROR_JOIN_TO_JOIN = 138;
    {$EXTERNALSYM ERROR_JOIN_TO_JOIN}

 : result := 'The system tried to substitute a drive to a directory on a substituted drive';
    ERROR_SUBST_TO_SUBST = 139;
    {$EXTERNALSYM ERROR_SUBST_TO_SUBST}

 : result := 'The system tried to join a drive to a directory on a substituted drive';
    ERROR_JOIN_TO_SUBST = 140;
    {$EXTERNALSYM ERROR_JOIN_TO_SUBST}

 : result := 'The system tried to SUBST a drive to a directory on a joined drive';
    ERROR_SUBST_TO_JOIN = 141;
    {$EXTERNALSYM ERROR_SUBST_TO_JOIN}

 : result := 'The system cannot perform a JOIN or SUBST at this time';
    ERROR_BUSY_DRIVE = 142;
    {$EXTERNALSYM ERROR_BUSY_DRIVE}

 : result := 'The system cannot join or substitute a }
 : result := 'drive to or for a directory on the same drive';
    ERROR_SAME_DRIVE = 143;
    {$EXTERNALSYM ERROR_SAME_DRIVE}

 : result := 'The directory is not a subdirectory of the root directory';
    ERROR_DIR_NOT_ROOT = 144;
    {$EXTERNALSYM ERROR_DIR_NOT_ROOT}

 : result := 'The directory is not empty';
    ERROR_DIR_NOT_EMPTY = 145;
    {$EXTERNALSYM ERROR_DIR_NOT_EMPTY}

 : result := 'The path specified is being used in a substitute';
    ERROR_IS_SUBST_PATH = 146;
    {$EXTERNALSYM ERROR_IS_SUBST_PATH}

 : result := 'Not enough resources are available to process this command';
    ERROR_IS_JOIN_PATH = 147;
    {$EXTERNALSYM ERROR_IS_JOIN_PATH}

 : result := 'The path specified cannot be used at this time';
    ERROR_PATH_BUSY = 148;
    {$EXTERNALSYM ERROR_PATH_BUSY}

 : result := 'An attempt was made to join or substitute a drive for which a directory }
 : result := 'on the drive is the target of a previous substitute';
    ERROR_IS_SUBST_TARGET = 149;
    {$EXTERNALSYM ERROR_IS_SUBST_TARGET}

 : result := 'System trace information was not specified in your }
 : result := 'CONFIG.SYS file, or tracing is disallowed';
    ERROR_SYSTEM_TRACE = 150;
    {$EXTERNALSYM ERROR_SYSTEM_TRACE}

 : result := 'The number of specified semaphore events for }
 : result := 'DosMuxSemWait is not correct';
    ERROR_INVALID_EVENT_COUNT = 151;
    {$EXTERNALSYM ERROR_INVALID_EVENT_COUNT}

 : result := 'DosMuxSemWait did not execute; too many semaphores }
 : result := 'are already set';
    ERROR_TOO_MANY_MUXWAITERS = 152;
    {$EXTERNALSYM ERROR_TOO_MANY_MUXWAITERS}

 : result := 'The DosMuxSemWait list is not correct';
    ERROR_INVALID_LIST_FORMAT = 153;
    {$EXTERNALSYM ERROR_INVALID_LIST_FORMAT}

 : result := ' The volume label you entered exceeds the label character }
 : result := ' limit of the target file system';
    ERROR_LABEL_TOO_LONG = 154;
    {$EXTERNALSYM ERROR_LABEL_TOO_LONG}

 : result := 'Cannot create another thread';
    ERROR_TOO_MANY_TCBS = 155;
    {$EXTERNALSYM ERROR_TOO_MANY_TCBS}

 : result := 'The recipient process has refused the signal';
    ERROR_SIGNAL_REFUSED = 156;
    {$EXTERNALSYM ERROR_SIGNAL_REFUSED}

 : result := 'The segment is already discarded and cannot be locked';
    ERROR_DISCARDED = 157;
    {$EXTERNALSYM ERROR_DISCARDED}

 : result := 'The segment is already unlocked';
    ERROR_NOT_LOCKED = 158;
    {$EXTERNALSYM ERROR_NOT_LOCKED}

 : result := 'The address for the thread ID is not correct';
    ERROR_BAD_THREADID_ADDR = 159;
    {$EXTERNALSYM ERROR_BAD_THREADID_ADDR}

 : result := 'The argument string passed to DosExecPgm is not correct';
    ERROR_BAD_ARGUMENTS = 160;
    {$EXTERNALSYM ERROR_BAD_ARGUMENTS}

 : result := 'The specified path is invalid';
    ERROR_BAD_PATHNAME = 161;
    {$EXTERNALSYM ERROR_BAD_PATHNAME}

 : result := 'A signal is already pending';
    ERROR_SIGNAL_PENDING = 162;
    {$EXTERNALSYM ERROR_SIGNAL_PENDING}

 : result := 'No more threads can be created in the system';
    ERROR_MAX_THRDS_REACHED = 164;
    {$EXTERNALSYM ERROR_MAX_THRDS_REACHED}

 : result := 'Unable to lock a region of a file';
    ERROR_LOCK_FAILED = 167;
    {$EXTERNALSYM ERROR_LOCK_FAILED}

 : result := 'The requested resource is in use';
    ERROR_BUSY = 170;
    {$EXTERNALSYM ERROR_BUSY}

 : result := 'A lock request was not outstanding for the supplied cancel region';
    ERROR_CANCEL_VIOLATION = 173;
    {$EXTERNALSYM ERROR_CANCEL_VIOLATION}

 : result := 'The file system does not support atomic changes to the lock type';
    ERROR_ATOMIC_LOCKS_NOT_SUPPORTED = 174;
    {$EXTERNALSYM ERROR_ATOMIC_LOCKS_NOT_SUPPORTED}

 : result := 'The system detected a segment number that was not correct';
    ERROR_INVALID_SEGMENT_NUMBER = 180;
    {$EXTERNALSYM ERROR_INVALID_SEGMENT_NUMBER}

 : result := 'The operating system cannot run %1';
    ERROR_INVALID_ORDINAL = 182;
    {$EXTERNALSYM ERROR_INVALID_ORDINAL}

 : result := 'Cannot create a file when that file already exists';
    ERROR_ALREADY_EXISTS = 183;
    {$EXTERNALSYM ERROR_ALREADY_EXISTS}

 : result := 'The flag passed is not correct';
    ERROR_INVALID_FLAG_NUMBER = 186;
    {$EXTERNALSYM ERROR_INVALID_FLAG_NUMBER}

 : result := 'The specified system semaphore name was not found';
    ERROR_SEM_NOT_FOUND = 187;
    {$EXTERNALSYM ERROR_SEM_NOT_FOUND}

 : result := 'The operating system cannot run %1';
    ERROR_INVALID_STARTING_CODESEG = 188;
    {$EXTERNALSYM ERROR_INVALID_STARTING_CODESEG}

 : result := 'The operating system cannot run %1';
    ERROR_INVALID_STACKSEG = 189;
    {$EXTERNALSYM ERROR_INVALID_STACKSEG}

 : result := 'The operating system cannot run %1';
    ERROR_INVALID_MODULETYPE = 190;
    {$EXTERNALSYM ERROR_INVALID_MODULETYPE}

 : result := 'Cannot run %1 in Windows NT mode';
    ERROR_INVALID_EXE_SIGNATURE = 191;
    {$EXTERNALSYM ERROR_INVALID_EXE_SIGNATURE}

 : result := 'The operating system cannot run %1';
    ERROR_EXE_MARKED_INVALID = 192;
    {$EXTERNALSYM ERROR_EXE_MARKED_INVALID}

 : result := '%1 is not a valid Windows NT application';
    ERROR_BAD_EXE_FORMAT = 193;
    {$EXTERNALSYM ERROR_BAD_EXE_FORMAT}

 : result := 'The operating system cannot run %1';
    ERROR_ITERATED_DATA_EXCEEDS_64k = 194;
    {$EXTERNALSYM ERROR_ITERATED_DATA_EXCEEDS_64k}

 : result := 'The operating system cannot run %1';
    ERROR_INVALID_MINALLOCSIZE = 195;
    {$EXTERNALSYM ERROR_INVALID_MINALLOCSIZE}

 : result := 'The operating system cannot run this application program';
    ERROR_DYNLINK_FROM_INVALID_RING = 196;
    {$EXTERNALSYM ERROR_DYNLINK_FROM_INVALID_RING}

 : result := 'The operating system is not presently configured to run this application';
    ERROR_IOPL_NOT_ENABLED = 197;
    {$EXTERNALSYM ERROR_IOPL_NOT_ENABLED}

 : result := 'The operating system cannot run %1';
    ERROR_INVALID_SEGDPL = 198;
    {$EXTERNALSYM ERROR_INVALID_SEGDPL}

 : result := 'The operating system cannot run this }
 : result := 'application program';
    ERROR_AUTODATASEG_EXCEEDS_64k = 199;
    {$EXTERNALSYM ERROR_AUTODATASEG_EXCEEDS_64k}

 : result := 'The code segment cannot be greater than or equal to 64KB';
    ERROR_RING2SEG_MUST_BE_MOVABLE = 200;
    {$EXTERNALSYM ERROR_RING2SEG_MUST_BE_MOVABLE}

 : result := 'The operating system cannot run %1';
    ERROR_RELOC_CHAIN_XEEDS_SEGLIM = 201;
    {$EXTERNALSYM ERROR_RELOC_CHAIN_XEEDS_SEGLIM}

 : result := 'The operating system cannot run %1';
    ERROR_INFLOOP_IN_RELOC_CHAIN = 202;
    {$EXTERNALSYM ERROR_INFLOOP_IN_RELOC_CHAIN}

 : result := 'The system could not find the environment option that was entered';
    ERROR_ENVVAR_NOT_FOUND = 203;
    {$EXTERNALSYM ERROR_ENVVAR_NOT_FOUND}

 : result := 'No process in the command subtree has a signal handler';
    ERROR_NO_SIGNAL_SENT = 205;
    {$EXTERNALSYM ERROR_NO_SIGNAL_SENT}

 : result := 'The filename or extension is too long';
    ERROR_FILENAME_EXCED_RANGE = 206;
    {$EXTERNALSYM ERROR_FILENAME_EXCED_RANGE}

 : result := 'The ring 2 stack is in use';
    ERROR_RING2_STACK_IN_USE = 207;
    {$EXTERNALSYM ERROR_RING2_STACK_IN_USE}

 : result := 'The global filename characters, * or ?, are entered }
 : result := 'incorrectly or too many global filename characters are specified';
    ERROR_META_EXPANSION_TOO_LONG = 208;
    {$EXTERNALSYM ERROR_META_EXPANSION_TOO_LONG}

 : result := 'The signal being posted is not correct';
    ERROR_INVALID_SIGNAL_NUMBER = 209;
    {$EXTERNALSYM ERROR_INVALID_SIGNAL_NUMBER}

 : result := 'The signal handler cannot be set';
    ERROR_THREAD_1_INACTIVE = 210;
    {$EXTERNALSYM ERROR_THREAD_1_INACTIVE}

 : result := 'The segment is locked and cannot be reallocated';
    ERROR_LOCKED = 212;
    {$EXTERNALSYM ERROR_LOCKED}

 : result := 'Too many dynamic link modules are attached to this }
 : result := 'program or dynamic link module';
    ERROR_TOO_MANY_MODULES = 214;
    {$EXTERNALSYM ERROR_TOO_MANY_MODULES}

 : result := 'Can't nest calls to LoadModule';
    ERROR_NESTING_NOT_ALLOWED = 215;
    {$EXTERNALSYM ERROR_NESTING_NOT_ALLOWED}

 : result := ' The image file %1 is valid, but is for a machine type other }
 : result := ' than the current machine';
    ERROR_EXE_MACHINE_TYPE_MISMATCH = 216;
    {$EXTERNALSYM ERROR_EXE_MACHINE_TYPE_MISMATCH}

 : result := 'The pipe state is invalid';
    ERROR_BAD_PIPE = 230;
    {$EXTERNALSYM ERROR_BAD_PIPE}

 : result := 'All pipe instances are busy';
    ERROR_PIPE_BUSY = 231;
    {$EXTERNALSYM ERROR_PIPE_BUSY}

 : result := 'The pipe is being closed';
    ERROR_NO_DATA = 232;
    {$EXTERNALSYM ERROR_NO_DATA}

 : result := 'No process is on the other end of the pipe';
    ERROR_PIPE_NOT_CONNECTED = 233;
    {$EXTERNALSYM ERROR_PIPE_NOT_CONNECTED}

 : result := 'More data is available';
    ERROR_MORE_DATA = 234;   { dderror }
    {$EXTERNALSYM ERROR_MORE_DATA}

 : result := 'The session was cancelled';
    ERROR_VC_DISCONNECTED = 240;
    {$EXTERNALSYM ERROR_VC_DISCONNECTED}

 : result := 'The specified extended attribute name was invalid';
    ERROR_INVALID_EA_NAME = 254;
    {$EXTERNALSYM ERROR_INVALID_EA_NAME}

 : result := 'The extended attributes are inconsistent';
    ERROR_EA_LIST_INCONSISTENT = 255;
    {$EXTERNALSYM ERROR_EA_LIST_INCONSISTENT}

 : result := 'No more data is available';
    ERROR_NO_MORE_ITEMS = 259;
    {$EXTERNALSYM ERROR_NO_MORE_ITEMS}

 : result := 'The Copy API cannot be used';
    ERROR_CANNOT_COPY = 266;
    {$EXTERNALSYM ERROR_CANNOT_COPY}

 : result := 'The directory name is invalid';
    ERROR_DIRECTORY = 267;
    {$EXTERNALSYM ERROR_DIRECTORY}

 : result := 'The extended attributes did not fit in the buffer';
    ERROR_EAS_DIDNT_FIT = 275;
    {$EXTERNALSYM ERROR_EAS_DIDNT_FIT}

 : result := 'The extended attribute file on the mounted file system is corrupt';
    ERROR_EA_FILE_CORRUPT = 276;
    {$EXTERNALSYM ERROR_EA_FILE_CORRUPT}

 : result := 'The extended attribute table file is full';
    ERROR_EA_TABLE_FULL = 277;
    {$EXTERNALSYM ERROR_EA_TABLE_FULL}

 : result := 'The specified extended attribute handle is invalid';
    ERROR_INVALID_EA_HANDLE = 278;
    {$EXTERNALSYM ERROR_INVALID_EA_HANDLE}

 : result := 'The mounted file system does not support extended attributes';
    ERROR_EAS_NOT_SUPPORTED = 282;
    {$EXTERNALSYM ERROR_EAS_NOT_SUPPORTED}

 : result := 'Attempt to release mutex not owned by caller';
    ERROR_NOT_OWNER = 288;
    {$EXTERNALSYM ERROR_NOT_OWNER}

 : result := 'Too many posts were made to a semaphore';
    ERROR_TOO_MANY_POSTS = 298;
    {$EXTERNALSYM ERROR_TOO_MANY_POSTS}

 : result := 'Only part of a Read/WriteProcessMemory request was completed';
    ERROR_PARTIAL_COPY = 299;
    {$EXTERNALSYM ERROR_PARTIAL_COPY}

 : result := 'The system cannot find message for message number $%1 }
 : result := 'in message file for %2';
    ERROR_MR_MID_NOT_FOUND = 317;
    {$EXTERNALSYM ERROR_MR_MID_NOT_FOUND}

 : result := 'Attempt to access invalid address';
    ERROR_INVALID_ADDRESS = 487;
    {$EXTERNALSYM ERROR_INVALID_ADDRESS}

 : result := 'Arithmetic result exceeded 32 bits';
    ERROR_ARITHMETIC_OVERFLOW = 534;
    {$EXTERNALSYM ERROR_ARITHMETIC_OVERFLOW}

 : result := 'There is a process on other end of the pipe';
    ERROR_PIPE_CONNECTED = 535;
    {$EXTERNALSYM ERROR_PIPE_CONNECTED}

 : result := 'Waiting for a process to open the other end of the pipe';
    ERROR_PIPE_LISTENING = 536;
    {$EXTERNALSYM ERROR_PIPE_LISTENING}

 : result := 'Access to the extended attribute was denied';
    ERROR_EA_ACCESS_DENIED = 994;
    {$EXTERNALSYM ERROR_EA_ACCESS_DENIED}

 : result := 'The I/O operation has been aborted because of either a thread exit }
 : result := 'or an application request';
    ERROR_OPERATION_ABORTED = 995;
    {$EXTERNALSYM ERROR_OPERATION_ABORTED}

 : result := 'Overlapped I/O event is not in a signalled state';
    ERROR_IO_INCOMPLETE = 996;
    {$EXTERNALSYM ERROR_IO_INCOMPLETE}

 : result := 'Overlapped I/O operation is in progress';
    ERROR_IO_PENDING = 997;   { dderror }
    {$EXTERNALSYM ERROR_IO_PENDING}

 : result := 'Invalid access to memory location';
    ERROR_NOACCESS = 998;
    {$EXTERNALSYM ERROR_NOACCESS}

 : result := 'Error performing inpage operation';
    ERROR_SWAPERROR = 999;
    {$EXTERNALSYM ERROR_SWAPERROR}

 : result := 'Recursion too deep, stack overflowed';
    ERROR_STACK_OVERFLOW = 1001;
    {$EXTERNALSYM ERROR_STACK_OVERFLOW}

 : result := 'The window cannot act on the sent message';
    ERROR_INVALID_MESSAGE = 1002;
    {$EXTERNALSYM ERROR_INVALID_MESSAGE}

 : result := 'Cannot complete this function';
    ERROR_CAN_NOT_COMPLETE = 1003;
    {$EXTERNALSYM ERROR_CAN_NOT_COMPLETE}

 : result := 'Invalid flags';
    ERROR_INVALID_FLAGS = 1004;
    {$EXTERNALSYM ERROR_INVALID_FLAGS}

 : result := 'The volume does not contain a recognized file system';
 : result := 'Please make sure that all required file system drivers are loaded and that the }
 : result := 'volume is not corrupt';
    ERROR_UNRECOGNIZED_VOLUME = 1005;
    {$EXTERNALSYM ERROR_UNRECOGNIZED_VOLUME}

 : result := 'The volume for a file has been externally altered such that the }
 : result := 'opened file is no longer valid';
    ERROR_FILE_INVALID = 1006;
    {$EXTERNALSYM ERROR_FILE_INVALID}

 : result := 'The requested operation cannot be performed in full-screen mode';
    ERROR_FULLSCREEN_MODE = 1007;
    {$EXTERNALSYM ERROR_FULLSCREEN_MODE}

 : result := 'An attempt was made to reference a token that does not exist';
    ERROR_NO_TOKEN = 1008;
    {$EXTERNALSYM ERROR_NO_TOKEN}

 : result := 'The configuration registry database is corrupt';
    ERROR_BADDB = 1009;
    {$EXTERNALSYM ERROR_BADDB}

 : result := 'The configuration registry key is invalid';
    ERROR_BADKEY = 1010;
    {$EXTERNALSYM ERROR_BADKEY}

 : result := 'The configuration registry key could not be opened';
    ERROR_CANTOPEN = 1011;
    {$EXTERNALSYM ERROR_CANTOPEN}

 : result := 'The configuration registry key could not be read';
    ERROR_CANTREAD = 1012;
    {$EXTERNALSYM ERROR_CANTREAD}

 : result := 'The configuration registry key could not be written';
    ERROR_CANTWRITE = 1013;
    {$EXTERNALSYM ERROR_CANTWRITE}

 : result := 'One of the files in the Registry database had to be recovered }
 : result := 'by use of a log or alternate copy.  The recovery was successful';
    ERROR_REGISTRY_RECOVERED = 1014;
    {$EXTERNALSYM ERROR_REGISTRY_RECOVERED}

 : result := 'The Registry is corrupt. The structure of one of the files that contains }
 : result := 'Registry data is corrupt, or the system's image of the file in memory }
 : result := 'is corrupt, or the file could not be recovered because the alternate }
 : result := 'copy or log was absent or corrupt';
    ERROR_REGISTRY_CORRUPT = 1015;
    {$EXTERNALSYM ERROR_REGISTRY_CORRUPT}

 : result := 'An I/O operation initiated by the Registry failed unrecoverably';
 : result := 'The Registry could not read in, or write out, or flush, one of the files }
 : result := 'that contain the system's image of the Registry';
    ERROR_REGISTRY_IO_FAILED = 1016;
    {$EXTERNALSYM ERROR_REGISTRY_IO_FAILED}

 : result := 'The system has attempted to load or restore a file into the Registry, but the }
 : result := 'specified file is not in a Registry file format';
    ERROR_NOT_REGISTRY_FILE = 1017;
    {$EXTERNALSYM ERROR_NOT_REGISTRY_FILE}

 : result := 'Illegal operation attempted on a Registry key which has been marked for deletion';
    ERROR_KEY_DELETED = 1018;
    {$EXTERNALSYM ERROR_KEY_DELETED}

 : result := 'System could not allocate the required space in a Registry log';
    ERROR_NO_LOG_SPACE = 1019;
    {$EXTERNALSYM ERROR_NO_LOG_SPACE}

 : result := 'Cannot create a symbolic link in a Registry key that already }
 : result := 'has subkeys or values';
    ERROR_KEY_HAS_CHILDREN = 1020;
    {$EXTERNALSYM ERROR_KEY_HAS_CHILDREN}

 : result := 'Cannot create a stable subkey under a volatile parent key';
    ERROR_CHILD_MUST_BE_VOLATILE = 1021;
    {$EXTERNALSYM ERROR_CHILD_MUST_BE_VOLATILE}

 : result := 'A notify change request is being completed and the information }
 : result := 'is not being returned in the caller's buffer. The caller now }
 : result := 'needs to enumerate the files to find the changes';
    ERROR_NOTIFY_ENUM_DIR = 1022;
    {$EXTERNALSYM ERROR_NOTIFY_ENUM_DIR}

 : result := 'A stop control has been sent to a service which other running services }
 : result := 'are dependent on';
    ERROR_DEPENDENT_SERVICES_RUNNING = 1051;
    {$EXTERNALSYM ERROR_DEPENDENT_SERVICES_RUNNING}

 : result := 'The requested control is not valid for this service }
    ERROR_INVALID_SERVICE_CONTROL = 1052;
    {$EXTERNALSYM ERROR_INVALID_SERVICE_CONTROL}

 : result := 'The service did not respond to the start or control request in a timely }
 : result := 'fashion';
    ERROR_SERVICE_REQUEST_TIMEOUT = 1053;
    {$EXTERNALSYM ERROR_SERVICE_REQUEST_TIMEOUT}

 : result := 'A thread could not be created for the service';
    ERROR_SERVICE_NO_THREAD = 1054;
    {$EXTERNALSYM ERROR_SERVICE_NO_THREAD}

 : result := 'The service database is locked';
    ERROR_SERVICE_DATABASE_LOCKED = 1055;
    {$EXTERNALSYM ERROR_SERVICE_DATABASE_LOCKED}

 : result := 'An instance of the service is already running';
    ERROR_SERVICE_ALREADY_RUNNING = 1056;
    {$EXTERNALSYM ERROR_SERVICE_ALREADY_RUNNING}

 : result := 'The account name is invalid or does not exist';
    ERROR_INVALID_SERVICE_ACCOUNT = 1057;
    {$EXTERNALSYM ERROR_INVALID_SERVICE_ACCOUNT}

 : result := 'The specified service is disabled and cannot be started';
    ERROR_SERVICE_DISABLED = 1058;
    {$EXTERNALSYM ERROR_SERVICE_DISABLED}

 : result := 'Circular service dependency was specified';
    ERROR_CIRCULAR_DEPENDENCY = 1059;
    {$EXTERNALSYM ERROR_CIRCULAR_DEPENDENCY}

 : result := 'The specified service does not exist as an installed service';
    ERROR_SERVICE_DOES_NOT_EXIST = 1060;
    {$EXTERNALSYM ERROR_SERVICE_DOES_NOT_EXIST}

 : result := 'The service cannot accept control messages at this time';
    ERROR_SERVICE_CANNOT_ACCEPT_CTRL = 1061;
    {$EXTERNALSYM ERROR_SERVICE_CANNOT_ACCEPT_CTRL}

 : result := 'The service has not been started';
    ERROR_SERVICE_NOT_ACTIVE = 1062;
    {$EXTERNALSYM ERROR_SERVICE_NOT_ACTIVE}

 : result := 'The service process could not connect to the service controller';
    ERROR_FAILED_SERVICE_CONTROLLER_ = 1063;
    {$EXTERNALSYM ERROR_FAILED_SERVICE_CONTROLLER_}

 : result := 'An exception occurred in the service when handling the control request';
    ERROR_EXCEPTION_IN_SERVICE = 1064;
    {$EXTERNALSYM ERROR_EXCEPTION_IN_SERVICE}

 : result := 'The database specified does not exist';
    ERROR_DATABASE_DOES_NOT_EXIST = 1065;
    {$EXTERNALSYM ERROR_DATABASE_DOES_NOT_EXIST}

 : result := 'The service has returned a service-specific error code';
    ERROR_SERVICE_SPECIFIC_ERROR = 1066;
    {$EXTERNALSYM ERROR_SERVICE_SPECIFIC_ERROR}

 : result := 'The process terminated unexpectedly';
    ERROR_PROCESS_ABORTED = 1067;
    {$EXTERNALSYM ERROR_PROCESS_ABORTED}

 : result := 'The dependency service or group failed to start';
    ERROR_SERVICE_DEPENDENCY_FAIL = 1068;
    {$EXTERNALSYM ERROR_SERVICE_DEPENDENCY_FAIL}

 : result := 'The service did not start due to a logon failure';
    ERROR_SERVICE_LOGON_FAILED = 1069;
    {$EXTERNALSYM ERROR_SERVICE_LOGON_FAILED}

 : result := 'After starting, the service hung in a start-pending state';
    ERROR_SERVICE_START_HANG = 1070;
    {$EXTERNALSYM ERROR_SERVICE_START_HANG}

 : result := 'The specified service database lock is invalid';
    ERROR_INVALID_SERVICE_LOCK = 1071;
    {$EXTERNALSYM ERROR_INVALID_SERVICE_LOCK}

 : result := 'The specified service has been marked for deletion';
    ERROR_SERVICE_MARKED_FOR_DELETE = 1072;
    {$EXTERNALSYM ERROR_SERVICE_MARKED_FOR_DELETE}

 : result := 'The specified service already exists';
    ERROR_SERVICE_EXISTS = 1073;
    {$EXTERNALSYM ERROR_SERVICE_EXISTS}

 : result := 'The system is currently running with the last-known-good configuration';
    ERROR_ALREADY_RUNNING_LKG = 1074;
    {$EXTERNALSYM ERROR_ALREADY_RUNNING_LKG}

 : result := 'The dependency service does not exist or has been marked for }
 : result := 'deletion';
    ERROR_SERVICE_DEPENDENCY_DELETED = 1075;
    {$EXTERNALSYM ERROR_SERVICE_DEPENDENCY_DELETED}

 : result := 'The current boot has already been accepted for use as the }
 : result := 'last-known-good control set';
    ERROR_BOOT_ALREADY_ACCEPTED = 1076;
    {$EXTERNALSYM ERROR_BOOT_ALREADY_ACCEPTED}

 : result := 'No attempts to start the service have been made since the last boot';
    ERROR_SERVICE_NEVER_STARTED = 1077;
    {$EXTERNALSYM ERROR_SERVICE_NEVER_STARTED}

 : result := 'The name is already in use as either a service name or a service display }
 : result := 'name';
    ERROR_DUPLICATE_SERVICE_NAME = 1078;
    {$EXTERNALSYM ERROR_DUPLICATE_SERVICE_NAME}

 : result := ' The account specified for this service is different from the account }
 : result := ' specified for other services running in the same process';
    ERROR_DIFFERENT_SERVICE_ACCOUNT = 1079;
    {$EXTERNALSYM ERROR_DIFFERENT_SERVICE_ACCOUNT}

 : result := 'The physical end of the tape has been reached';
    ERROR_END_OF_MEDIA = 1100;
    {$EXTERNALSYM ERROR_END_OF_MEDIA}

 : result := 'A tape access reached a filemark';
    ERROR_FILEMARK_DETECTED = 1101;
    {$EXTERNALSYM ERROR_FILEMARK_DETECTED}

 : result := 'Beginning of tape or partition was encountered';
    ERROR_BEGINNING_OF_MEDIA = 1102;
    {$EXTERNALSYM ERROR_BEGINNING_OF_MEDIA}

 : result := 'A tape access reached the end of a set of files';
    ERROR_SETMARK_DETECTED = 1103;
    {$EXTERNALSYM ERROR_SETMARK_DETECTED}

 : result := 'No more data is on the tape';
    ERROR_NO_DATA_DETECTED = 1104;
    {$EXTERNALSYM ERROR_NO_DATA_DETECTED}

 : result := 'Tape could not be partitioned';
    ERROR_PARTITION_FAILURE = 1105;
    {$EXTERNALSYM ERROR_PARTITION_FAILURE}

 : result := 'When accessing a new tape of a multivolume partition, the current }
 : result := 'blocksize is incorrect';
    ERROR_INVALID_BLOCK_LENGTH = 1106;
    {$EXTERNALSYM ERROR_INVALID_BLOCK_LENGTH}

 : result := 'Tape partition information could not be found when loading a tape';
    ERROR_DEVICE_NOT_PARTITIONED = 1107;
    {$EXTERNALSYM ERROR_DEVICE_NOT_PARTITIONED}

 : result := 'Unable to lock the media eject mechanism';
    ERROR_UNABLE_TO_LOCK_MEDIA = 1108;
    {$EXTERNALSYM ERROR_UNABLE_TO_LOCK_MEDIA}

 : result := 'Unable to unload the media';
    ERROR_UNABLE_TO_UNLOAD_MEDIA = 1109;
    {$EXTERNALSYM ERROR_UNABLE_TO_UNLOAD_MEDIA}

 : result := 'Media in drive may have changed';
    ERROR_MEDIA_CHANGED = 1110;
    {$EXTERNALSYM ERROR_MEDIA_CHANGED}

 : result := 'The I/O bus was reset';
    ERROR_BUS_RESET = 1111;
    {$EXTERNALSYM ERROR_BUS_RESET}

 : result := 'No media in drive';
    ERROR_NO_MEDIA_IN_DRIVE = 1112;
    {$EXTERNALSYM ERROR_NO_MEDIA_IN_DRIVE}

 : result := 'No mapping for the Unicode character exists in the target multi-byte code page';
    ERROR_NO_UNICODE_TRANSLATION = 1113;
    {$EXTERNALSYM ERROR_NO_UNICODE_TRANSLATION}

 : result := 'A dynamic link library (DLL) initialization routine failed';
    ERROR_DLL_INIT_FAILED = 1114;
    {$EXTERNALSYM ERROR_DLL_INIT_FAILED}

 : result := 'A system shutdown is in progress';
    ERROR_SHUTDOWN_IN_PROGRESS = 1115;
    {$EXTERNALSYM ERROR_SHUTDOWN_IN_PROGRESS}

 : result := 'Unable to abort the system shutdown because no shutdown was in progress';
    ERROR_NO_SHUTDOWN_IN_PROGRESS = 1116;
    {$EXTERNALSYM ERROR_NO_SHUTDOWN_IN_PROGRESS}

 : result := 'The request could not be performed because of an I/O device error';
    ERROR_IO_DEVICE = 1117;
    {$EXTERNALSYM ERROR_IO_DEVICE}

 : result := 'No serial device was successfully initialized.  The serial driver will unload';
    ERROR_SERIAL_NO_DEVICE = 1118;
    {$EXTERNALSYM ERROR_SERIAL_NO_DEVICE}

 : result := 'Unable to open a device that was sharing an interrupt request (IRQ) }
 : result := 'with other devices. At least one other device that uses that IRQ }
 : result := 'was already opened';
    ERROR_IRQ_BUSY = 1119;
    {$EXTERNALSYM ERROR_IRQ_BUSY}

 : result := 'A serial I/O operation was completed by another write to the serial port';
 : result := '(The IOCTL_SERIAL_XOFF_COUNTER reached zero.) }
    ERROR_MORE_WRITES = 1120;
    {$EXTERNALSYM ERROR_MORE_WRITES}

 : result := 'A serial I/O operation completed because the time-out period expired';
 : result := '(The IOCTL_SERIAL_XOFF_COUNTER did not reach zero.) }
    ERROR_COUNTER_TIMEOUT = 1121;
    {$EXTERNALSYM ERROR_COUNTER_TIMEOUT}

 : result := 'No ID address mark was found on the floppy disk';
    ERROR_FLOPPY_ID_MARK_NOT_FOUND = 1122;
    {$EXTERNALSYM ERROR_FLOPPY_ID_MARK_NOT_FOUND}

 : result := 'Mismatch between the floppy disk sector ID field and the floppy disk }
 : result := 'controller track address';
    ERROR_FLOPPY_WRONG_CYLINDER = 1123;
    {$EXTERNALSYM ERROR_FLOPPY_WRONG_CYLINDER}

 : result := 'The floppy disk controller reported an error that is not recognized }
 : result := 'by the floppy disk driver';
    ERROR_FLOPPY_UNKNOWN_ERROR = 1124;
    {$EXTERNALSYM ERROR_FLOPPY_UNKNOWN_ERROR}

 : result := 'The floppy disk controller returned inconsistent results in its registers';
    ERROR_FLOPPY_BAD_REGISTERS = 1125;
    {$EXTERNALSYM ERROR_FLOPPY_BAD_REGISTERS}

 : result := 'While accessing the hard disk, a recalibrate operation failed, even after retries';
    ERROR_DISK_RECALIBRATE_FAILED = 1126;
    {$EXTERNALSYM ERROR_DISK_RECALIBRATE_FAILED}

 : result := 'While accessing the hard disk, a disk operation failed even after retries';
    ERROR_DISK_OPERATION_FAILED = 1127;
    {$EXTERNALSYM ERROR_DISK_OPERATION_FAILED}

 : result := 'While accessing the hard disk, a disk controller reset was needed, but }
 : result := 'even that failed';
    ERROR_DISK_RESET_FAILED = 1128;
    {$EXTERNALSYM ERROR_DISK_RESET_FAILED}

 : result := 'Physical end of tape encountered';
    ERROR_EOM_OVERFLOW = 1129;
    {$EXTERNALSYM ERROR_EOM_OVERFLOW}

 : result := 'Not enough server storage is available to process this command';
    ERROR_NOT_ENOUGH_SERVER_MEMORY = 1130;
    {$EXTERNALSYM ERROR_NOT_ENOUGH_SERVER_MEMORY}

 : result := 'A potential deadlock condition has been detected';
    ERROR_POSSIBLE_DEADLOCK = 1131;
    {$EXTERNALSYM ERROR_POSSIBLE_DEADLOCK}

 : result := 'The base address or the file offset specified does not have the proper }
 : result := 'alignment';
    ERROR_MAPPED_ALIGNMENT = 1132;
    {$EXTERNALSYM ERROR_MAPPED_ALIGNMENT}

 : result := 'An attempt to change the system power state was vetoed by another }
 : result := 'application or driver';
    ERROR_SET_POWER_STATE_VETOED = 1140;
    {$EXTERNALSYM ERROR_SET_POWER_STATE_VETOED}

 : result := 'The system BIOS failed an attempt to change the system power state';
    ERROR_SET_POWER_STATE_FAILED = 1141;
    {$EXTERNALSYM ERROR_SET_POWER_STATE_FAILED}

 : result := ' An attempt was made to create more links on a file than }
 : result := ' the file system supports';
    ERROR_TOO_MANY_LINKS = 1142;
    {$EXTERNALSYM ERROR_TOO_MANY_LINKS}

 : result := 'The specified program requires a newer version of Windows';
    ERROR_OLD_WIN_VERSION = 1150;
    {$EXTERNALSYM ERROR_OLD_WIN_VERSION}

 : result := 'The specified program is not a Windows or MS-DOS program';
    ERROR_APP_WRONG_OS = 1151;
    {$EXTERNALSYM ERROR_APP_WRONG_OS}

 : result := 'Cannot start more than one instance of the specified program';
    ERROR_SINGLE_INSTANCE_APP = 1152;
    {$EXTERNALSYM ERROR_SINGLE_INSTANCE_APP}

 : result := ' The specified program was written for an older version of Windows';
    ERROR_RMODE_APP = 1153;
    {$EXTERNALSYM ERROR_RMODE_APP}

 : result := 'One of the library files needed to run this application is damaged';
    ERROR_INVALID_DLL = 1154;
    {$EXTERNALSYM ERROR_INVALID_DLL}

 : result := 'No application is associated with the specified file for this operation';
    ERROR_NO_ASSOCIATION = 1155;
    {$EXTERNALSYM ERROR_NO_ASSOCIATION}

 : result := 'An error occurred in sending the command to the application';
    ERROR_DDE_FAIL = 1156;
    {$EXTERNALSYM ERROR_DDE_FAIL}

 : result := 'One of the library files needed to run this application cannot be found';
    ERROR_DLL_NOT_FOUND = 1157;
    {$EXTERNALSYM ERROR_DLL_NOT_FOUND}


  { Winnet32 Status Codes }

 : result := 'The specified username is invalid';
    ERROR_BAD_USERNAME = 2202;
    {$EXTERNALSYM ERROR_BAD_USERNAME}

 : result := 'This network connection does not exist';
    ERROR_NOT_CONNECTED = 2250;
    {$EXTERNALSYM ERROR_NOT_CONNECTED}

 : result := 'This network connection has files open or requests pending';
    ERROR_OPEN_FILES = 2401;
    {$EXTERNALSYM ERROR_OPEN_FILES}

 : result := 'Active connections still exist';
    ERROR_ACTIVE_CONNECTIONS = 2402;
    {$EXTERNALSYM ERROR_ACTIVE_CONNECTIONS}

 : result := 'The device is in use by an active process and cannot be disconnected';
    ERROR_DEVICE_IN_USE = 2404;
    {$EXTERNALSYM ERROR_DEVICE_IN_USE}

 : result := 'The specified device name is invalid';
    ERROR_BAD_DEVICE = 1200;
    {$EXTERNALSYM ERROR_BAD_DEVICE}

 : result := 'The device is not currently connected but it is a remembered connection';
    ERROR_CONNECTION_UNAVAIL = 1201;
    {$EXTERNALSYM ERROR_CONNECTION_UNAVAIL}

 : result := 'An attempt was made to remember a device that had previously been remembered';
    ERROR_DEVICE_ALREADY_REMEMBERED = 1202;
    {$EXTERNALSYM ERROR_DEVICE_ALREADY_REMEMBERED}

 : result := 'No network provider accepted the given network path';
    ERROR_NO_NET_OR_BAD_PATH = 1203;
    {$EXTERNALSYM ERROR_NO_NET_OR_BAD_PATH}

 : result := 'The specified network provider name is invalid';
    ERROR_BAD_PROVIDER = 1204;
    {$EXTERNALSYM ERROR_BAD_PROVIDER}

 : result := 'Unable to open the network connection profile';
    ERROR_CANNOT_OPEN_PROFILE = 1205;
    {$EXTERNALSYM ERROR_CANNOT_OPEN_PROFILE}

 : result := 'The network connection profile is corrupt';
    ERROR_BAD_PROFILE = 1206;
    {$EXTERNALSYM ERROR_BAD_PROFILE}

 : result := 'Cannot enumerate a non-container';
    ERROR_NOT_CONTAINER = 1207;
    {$EXTERNALSYM ERROR_NOT_CONTAINER}

 : result := 'An extended error has occurred';
    ERROR_EXTENDED_ERROR = 1208;
    {$EXTERNALSYM ERROR_EXTENDED_ERROR}

 : result := 'The format of the specified group name is invalid';
    ERROR_INVALID_GROUPNAME = 1209;
    {$EXTERNALSYM ERROR_INVALID_GROUPNAME}

 : result := 'The format of the specified computer name is invalid';
    ERROR_INVALID_COMPUTERNAME = 1210;
    {$EXTERNALSYM ERROR_INVALID_COMPUTERNAME}

 : result := 'The format of the specified event name is invalid';
    ERROR_INVALID_EVENTNAME = 1211;
    {$EXTERNALSYM ERROR_INVALID_EVENTNAME}

 : result := 'The format of the specified domain name is invalid';
    ERROR_INVALID_DOMAINNAME = 1212;
    {$EXTERNALSYM ERROR_INVALID_DOMAINNAME}

 : result := 'The format of the specified service name is invalid';
    ERROR_INVALID_SERVICENAME = 1213;
    {$EXTERNALSYM ERROR_INVALID_SERVICENAME}

 : result := 'The format of the specified network name is invalid';
    ERROR_INVALID_NETNAME = 1214;
    {$EXTERNALSYM ERROR_INVALID_NETNAME}

 : result := 'The format of the specified share name is invalid';
    ERROR_INVALID_SHARENAME = 1215;
    {$EXTERNALSYM ERROR_INVALID_SHARENAME}

 : result := 'The format of the specified password is invalid';
    ERROR_INVALID_PASSWORDNAME = 1216;
    {$EXTERNALSYM ERROR_INVALID_PASSWORDNAME}

 : result := 'The format of the specified message name is invalid';
    ERROR_INVALID_MESSAGENAME = 1217;
    {$EXTERNALSYM ERROR_INVALID_MESSAGENAME}

 : result := 'The format of the specified message destination is invalid';
    ERROR_INVALID_MESSAGEDEST = 1218;
    {$EXTERNALSYM ERROR_INVALID_MESSAGEDEST}

 : result := 'The credentials supplied conflict with an existing set of credentials';
    ERROR_SESSION_CREDENTIAL_CONFLICT = 1219;
    {$EXTERNALSYM ERROR_SESSION_CREDENTIAL_CONFLICT}

 : result := 'An attempt was made to establish a session to a network server, but there }
 : result := 'are already too many sessions established to that server';
    ERROR_REMOTE_SESSION_LIMIT_EXCEEDED = 1220;
    {$EXTERNALSYM ERROR_REMOTE_SESSION_LIMIT_EXCEEDED}

 : result := 'The workgroup or domain name is already in use by another computer on the }
 : result := 'network';
    ERROR_DUP_DOMAINNAME = 1221;
    {$EXTERNALSYM ERROR_DUP_DOMAINNAME}

 : result := 'The network is not present or not started';
    ERROR_NO_NETWORK = 1222;
    {$EXTERNALSYM ERROR_NO_NETWORK}

 : result := 'The operation was cancelled by the user';
    ERROR_CANCELLED = 1223;
    {$EXTERNALSYM ERROR_CANCELLED}

 : result := 'The requested operation cannot be performed on a file with a user mapped section open';
    ERROR_USER_MAPPED_FILE = 1224;
    {$EXTERNALSYM ERROR_USER_MAPPED_FILE}

 : result := 'The remote system refused the network connection';
    ERROR_CONNECTION_REFUSED = 1225;
    {$EXTERNALSYM ERROR_CONNECTION_REFUSED}

 : result := 'The network connection was gracefully closed';
    ERROR_GRACEFUL_DISCONNECT = 1226;
    {$EXTERNALSYM ERROR_GRACEFUL_DISCONNECT}

 : result := 'The network transport endpoint already has an address associated with it';
    ERROR_ADDRESS_ALREADY_ASSOCIATED = 1227;
    {$EXTERNALSYM ERROR_ADDRESS_ALREADY_ASSOCIATED}

 : result := 'An address has not yet been associated with the network endpoint';
    ERROR_ADDRESS_NOT_ASSOCIATED = 1228;
    {$EXTERNALSYM ERROR_ADDRESS_NOT_ASSOCIATED}

 : result := 'An operation was attempted on a non-existent network connection';
    ERROR_CONNECTION_INVALID = 1229;
    {$EXTERNALSYM ERROR_CONNECTION_INVALID}

 : result := 'An invalid operation was attempted on an active network connection';
    ERROR_CONNECTION_ACTIVE = 1230;
    {$EXTERNALSYM ERROR_CONNECTION_ACTIVE}

 : result := 'The remote network is not reachable by the transport';
    ERROR_NETWORK_UNREACHABLE = 1231;
    {$EXTERNALSYM ERROR_NETWORK_UNREACHABLE}

 : result := 'The remote system is not reachable by the transport';
    ERROR_HOST_UNREACHABLE = 1232;
    {$EXTERNALSYM ERROR_HOST_UNREACHABLE}

 : result := 'The remote system does not support the transport protocol';
    ERROR_PROTOCOL_UNREACHABLE = 1233;
    {$EXTERNALSYM ERROR_PROTOCOL_UNREACHABLE}

 : result := 'No service is operating at the destination network endpoint }
 : result := 'on the remote system';
    ERROR_PORT_UNREACHABLE = 1234;
    {$EXTERNALSYM ERROR_PORT_UNREACHABLE}

 : result := 'The request was aborted';
    ERROR_REQUEST_ABORTED = 1235;
    {$EXTERNALSYM ERROR_REQUEST_ABORTED}

 : result := 'The network connection was aborted by the local system';
    ERROR_CONNECTION_ABORTED = 1236;
    {$EXTERNALSYM ERROR_CONNECTION_ABORTED}

 : result := 'The operation could not be completed.  A retry should be performed';
    ERROR_RETRY = 1237;
    {$EXTERNALSYM ERROR_RETRY}

 : result := 'A connection to the server could not be made because the limit on the number of }
 : result := 'concurrent connections for this account has been reached';
    ERROR_CONNECTION_COUNT_LIMIT = 1238;
    {$EXTERNALSYM ERROR_CONNECTION_COUNT_LIMIT}

 : result := 'Attempting to login during an unauthorized time of day for this account';
    ERROR_LOGIN_TIME_RESTRICTION = 1239;
    {$EXTERNALSYM ERROR_LOGIN_TIME_RESTRICTION}

 : result := 'The account is not authorized to login from this station';
    ERROR_LOGIN_WKSTA_RESTRICTION = 1240;
    {$EXTERNALSYM ERROR_LOGIN_WKSTA_RESTRICTION}

 : result := 'The network address could not be used for the operation requested';
    ERROR_INCORRECT_ADDRESS = 1241;
    {$EXTERNALSYM ERROR_INCORRECT_ADDRESS}

 : result := 'The service is already registered';
    ERROR_ALREADY_REGISTERED = 1242;
    {$EXTERNALSYM ERROR_ALREADY_REGISTERED}

 : result := 'The specified service does not exist';
    ERROR_SERVICE_NOT_FOUND = 1243;
    {$EXTERNALSYM ERROR_SERVICE_NOT_FOUND}

 : result := 'The operation being requested was not performed because the user }
 : result := 'has not been authenticated';
    ERROR_NOT_AUTHENTICATED = 1244;
    {$EXTERNALSYM ERROR_NOT_AUTHENTICATED}

 : result := 'The operation being requested was not performed because the user }
 : result := 'has not logged on to the network';
 : result := 'The specified service does not exist';
    ERROR_NOT_LOGGED_ON = 1245;
    {$EXTERNALSYM ERROR_NOT_LOGGED_ON}

 : result := 'Return that wants caller to continue with work in progress';
    ERROR_CONTINUE = 1246;
    {$EXTERNALSYM ERROR_CONTINUE}

 : result := 'An attempt was made to perform an initialization operation when }
 : result := 'initialization has already been completed';
    ERROR_ALREADY_INITIALIZED = 1247;
    {$EXTERNALSYM ERROR_ALREADY_INITIALIZED}

 : result := 'No more local devices';
    ERROR_NO_MORE_DEVICES = 1248;
    {$EXTERNALSYM ERROR_NO_MORE_DEVICES}


  { Security Status Codes }

 : result := 'Not all privileges referenced are assigned to the caller';
    ERROR_NOT_ALL_ASSIGNED = 1300;
    {$EXTERNALSYM ERROR_NOT_ALL_ASSIGNED}

 : result := 'Some mapping between account names and security IDs was not done';
    ERROR_SOME_NOT_MAPPED = 1301;
    {$EXTERNALSYM ERROR_SOME_NOT_MAPPED}

 : result := 'No system quota limits are specifically set for this account';
    ERROR_NO_QUOTAS_FOR_ACCOUNT = 1302;
    {$EXTERNALSYM ERROR_NO_QUOTAS_FOR_ACCOUNT}

 : result := 'No encryption key is available.  A well-known encryption key was returned';
    ERROR_LOCAL_USER_SESSION_KEY = 1303;
    {$EXTERNALSYM ERROR_LOCAL_USER_SESSION_KEY}

 : result := 'The NT password is too complex to be converted to a LAN Manager }
 : result := 'password.  The LAN Manager password returned is a NULL string';
    ERROR_NULL_LM_PASSWORD = 1304;
    {$EXTERNALSYM ERROR_NULL_LM_PASSWORD}

 : result := 'The revision level is unknown';
    ERROR_UNKNOWN_REVISION = 1305;
    {$EXTERNALSYM ERROR_UNKNOWN_REVISION}

 : result := 'Indicates two revision levels are incompatible';
    ERROR_REVISION_MISMATCH = 1306;
    {$EXTERNALSYM ERROR_REVISION_MISMATCH}

 : result := 'This security ID may not be assigned as the owner of this object';
    ERROR_INVALID_OWNER = 1307;
    {$EXTERNALSYM ERROR_INVALID_OWNER}

 : result := 'This security ID may not be assigned as the primary group of an object';
    ERROR_INVALID_PRIMARY_GROUP = 1308;
    {$EXTERNALSYM ERROR_INVALID_PRIMARY_GROUP}

 : result := 'An attempt has been made to operate on an impersonation token }

 : result := 'by a thread that is not currently impersonating a client';
    ERROR_NO_IMPERSONATION_TOKEN = 1309;
    {$EXTERNALSYM ERROR_NO_IMPERSONATION_TOKEN}

 : result := 'The group may not be disabled';
    ERROR_CANT_DISABLE_MANDATORY = 1310;
    {$EXTERNALSYM ERROR_CANT_DISABLE_MANDATORY}

 : result := 'There are currently no logon servers available to service the logon }
 : result := 'request';
    ERROR_NO_LOGON_SERVERS = 1311;
    {$EXTERNALSYM ERROR_NO_LOGON_SERVERS}

 : result := ' A specified logon session does not exist.  It may already have }
 : result := ' been terminated';
    ERROR_NO_SUCH_LOGON_SESSION = 1312;
    {$EXTERNALSYM ERROR_NO_SUCH_LOGON_SESSION}

 : result := ' A specified privilege does not exist';
    ERROR_NO_SUCH_PRIVILEGE = 1313;
    {$EXTERNALSYM ERROR_NO_SUCH_PRIVILEGE}

 : result := ' A required privilege is not held by the client';
    ERROR_PRIVILEGE_NOT_HELD = 1314;
    {$EXTERNALSYM ERROR_PRIVILEGE_NOT_HELD}

 : result := 'The name provided is not a properly formed account name';
    ERROR_INVALID_ACCOUNT_NAME = 1315;
    {$EXTERNALSYM ERROR_INVALID_ACCOUNT_NAME}

 : result := 'The specified user already exists';
    ERROR_USER_EXISTS = 1316;
    {$EXTERNALSYM ERROR_USER_EXISTS}

 : result := 'The specified user does not exist';
    ERROR_NO_SUCH_USER = 1317;
    {$EXTERNALSYM ERROR_NO_SUCH_USER}

 : result := 'The specified group already exists';
    ERROR_GROUP_EXISTS = 1318;
    {$EXTERNALSYM ERROR_GROUP_EXISTS}

 : result := 'The specified group does not exist';
    ERROR_NO_SUCH_GROUP = 1319;
    {$EXTERNALSYM ERROR_NO_SUCH_GROUP}

 : result := 'Either the specified user account is already a member of the specified }
 : result := 'group, or the specified group cannot be deleted because it contains }
 : result := 'a member';
    ERROR_MEMBER_IN_GROUP = 1320;
    {$EXTERNALSYM ERROR_MEMBER_IN_GROUP}

 : result := 'The specified user account is not a member of the specified group account';
    ERROR_MEMBER_NOT_IN_GROUP = 1321;
    {$EXTERNALSYM ERROR_MEMBER_NOT_IN_GROUP}

 : result := 'The last remaining administration account cannot be disabled }
 : result := 'or deleted';
    ERROR_LAST_ADMIN = 1322;
    {$EXTERNALSYM ERROR_LAST_ADMIN}

 : result := 'Unable to update the password.  The value provided as the current }
 : result := 'password is incorrect';
    ERROR_WRONG_PASSWORD = 1323;
    {$EXTERNALSYM ERROR_WRONG_PASSWORD}

 : result := 'Unable to update the password.  The value provided for the new password }
 : result := 'contains values that are not allowed in passwords';
    ERROR_ILL_FORMED_PASSWORD = 1324;
    {$EXTERNALSYM ERROR_ILL_FORMED_PASSWORD}

 : result := 'Unable to update the password because a password update rule has been }
 : result := 'violated';
    ERROR_PASSWORD_RESTRICTION = 1325;
    {$EXTERNALSYM ERROR_PASSWORD_RESTRICTION}

 : result := 'Logon failure: unknown user name or bad password';
    ERROR_LOGON_FAILURE = 1326;
    {$EXTERNALSYM ERROR_LOGON_FAILURE}

 : result := 'Logon failure: user account restriction';
    ERROR_ACCOUNT_RESTRICTION = 1327;
    {$EXTERNALSYM ERROR_ACCOUNT_RESTRICTION}

 : result := 'Logon failure: account logon time restriction violation';
    ERROR_INVALID_LOGON_HOURS = 1328;
    {$EXTERNALSYM ERROR_INVALID_LOGON_HOURS}

 : result := 'Logon failure: user not allowed to log on to this computer';
    ERROR_INVALID_WORKSTATION = 1329;
    {$EXTERNALSYM ERROR_INVALID_WORKSTATION}

 : result := 'Logon failure: the specified account password has expired';
    ERROR_PASSWORD_EXPIRED = 1330;
    {$EXTERNALSYM ERROR_PASSWORD_EXPIRED}

 : result := 'Logon failure: account currently disabled';
    ERROR_ACCOUNT_DISABLED = 1331;
    {$EXTERNALSYM ERROR_ACCOUNT_DISABLED}

 : result := 'No mapping between account names and security IDs was done';
    ERROR_NONE_MAPPED = 1332;
    {$EXTERNALSYM ERROR_NONE_MAPPED}

 : result := 'Too many local user identifiers (LUIDs) were requested at one time';
    ERROR_TOO_MANY_LUIDS_REQUESTED = 1333;
    {$EXTERNALSYM ERROR_TOO_MANY_LUIDS_REQUESTED}

 : result := 'No more local user identifiers (LUIDs) are available';
    ERROR_LUIDS_EXHAUSTED = 1334;
    {$EXTERNALSYM ERROR_LUIDS_EXHAUSTED}

 : result := 'The subauthority part of a security ID is invalid for this particular use';
    ERROR_INVALID_SUB_AUTHORITY = 1335;
    {$EXTERNALSYM ERROR_INVALID_SUB_AUTHORITY}

 : result := 'The access control list (ACL) structure is invalid';
    ERROR_INVALID_ACL = 1336;
    {$EXTERNALSYM ERROR_INVALID_ACL}

 : result := 'The security ID structure is invalid';
    ERROR_INVALID_SID = 1337;
    {$EXTERNALSYM ERROR_INVALID_SID}

 : result := 'The security descriptor structure is invalid';
    ERROR_INVALID_SECURITY_DESCR = 1338;
    {$EXTERNALSYM ERROR_INVALID_SECURITY_DESCR}

 : result := 'The inherited access control list (ACL) or access control entry (ACE) }
 : result := 'could not be built';
    ERROR_BAD_INHERITANCE_ACL = 1340;
    {$EXTERNALSYM ERROR_BAD_INHERITANCE_ACL}

 : result := 'The server is currently disabled';
    ERROR_SERVER_DISABLED = 1341;
    {$EXTERNALSYM ERROR_SERVER_DISABLED}

 : result := 'The server is currently enabled';
    ERROR_SERVER_NOT_DISABLED = 1342;
    {$EXTERNALSYM ERROR_SERVER_NOT_DISABLED}

 : result := 'The value provided was an invalid value for an identifier authority';
    ERROR_INVALID_ID_AUTHORITY = 1343;
    {$EXTERNALSYM ERROR_INVALID_ID_AUTHORITY}

 : result := 'No more memory is available for security information updates';
    ERROR_ALLOTTED_SPACE_EXCEEDED = 1344;
    {$EXTERNALSYM ERROR_ALLOTTED_SPACE_EXCEEDED}

 : result := 'The specified attributes are invalid, or incompatible with the }

 : result := 'attributes for the group as a whole';
    ERROR_INVALID_GROUP_ATTRIBUTES = 1345;
    {$EXTERNALSYM ERROR_INVALID_GROUP_ATTRIBUTES}

 : result := 'Either a required impersonation level was not provided, or the }
 : result := 'provided impersonation level is invalid';
    ERROR_BAD_IMPERSONATION_LEVEL = 1346;
    {$EXTERNALSYM ERROR_BAD_IMPERSONATION_LEVEL}

 : result := 'Cannot open an anonymous level security token';
    ERROR_CANT_OPEN_ANONYMOUS = 1347;
    {$EXTERNALSYM ERROR_CANT_OPEN_ANONYMOUS}

 : result := 'The validation information class requested was invalid';
    ERROR_BAD_VALIDATION_CLASS = 1348;
    {$EXTERNALSYM ERROR_BAD_VALIDATION_CLASS}

 : result := 'The type of the token is inappropriate for its attempted use';
    ERROR_BAD_TOKEN_TYPE = 1349;
    {$EXTERNALSYM ERROR_BAD_TOKEN_TYPE}

 : result := 'Unable to perform a security operation on an object }
 : result := 'which has no associated security';
    ERROR_NO_SECURITY_ON_OBJECT = 1350;
    {$EXTERNALSYM ERROR_NO_SECURITY_ON_OBJECT}

 : result := 'Indicates a Windows NT Server could not be contacted or that }
 : result := 'objects within the domain are protected such that necessary }
 : result := 'information could not be retrieved';
    ERROR_CANT_ACCESS_DOMAIN_INFO = 1351;
    {$EXTERNALSYM ERROR_CANT_ACCESS_DOMAIN_INFO}

 : result := 'The security account manager (SAM) or local security }
 : result := 'authority (LSA) server was in the wrong state to perform }
 : result := 'the security operation';
    ERROR_INVALID_SERVER_STATE = 1352;
    {$EXTERNALSYM ERROR_INVALID_SERVER_STATE}

 : result := 'The domain was in the wrong state to perform the security operation';
    ERROR_INVALID_DOMAIN_STATE = 1353;
    {$EXTERNALSYM ERROR_INVALID_DOMAIN_STATE}

 : result := 'This operation is only allowed for the Primary Domain Controller of the domain';
    ERROR_INVALID_DOMAIN_ROLE = 1354;
    {$EXTERNALSYM ERROR_INVALID_DOMAIN_ROLE}

 : result := 'The specified domain did not exist';
    ERROR_NO_SUCH_DOMAIN = 1355;
    {$EXTERNALSYM ERROR_NO_SUCH_DOMAIN}

 : result := 'The specified domain already exists';
    ERROR_DOMAIN_EXISTS = 1356;
    {$EXTERNALSYM ERROR_DOMAIN_EXISTS}

 : result := 'An attempt was made to exceed the limit on the number of domains per server';
    ERROR_DOMAIN_LIMIT_EXCEEDED = 1357;
    {$EXTERNALSYM ERROR_DOMAIN_LIMIT_EXCEEDED}

 : result := 'Unable to complete the requested operation because of either a }
 : result := 'catastrophic media failure or a data structure corruption on the disk';
    ERROR_INTERNAL_DB_CORRUPTION = 1358;
    {$EXTERNALSYM ERROR_INTERNAL_DB_CORRUPTION}

 : result := 'The security account database contains an internal inconsistency';
    ERROR_INTERNAL_ERROR = 1359;
    {$EXTERNALSYM ERROR_INTERNAL_ERROR}

 : result := 'Generic access types were contained in an access mask which should }
 : result := 'already be mapped to non-generic types';
    ERROR_GENERIC_NOT_MAPPED = 1360;
    {$EXTERNALSYM ERROR_GENERIC_NOT_MAPPED}

 : result := 'A security descriptor is not in the right format (absolute or self-relative)';
    ERROR_BAD_DESCRIPTOR_FORMAT = 1361;
    {$EXTERNALSYM ERROR_BAD_DESCRIPTOR_FORMAT}

 : result := 'The requested action is restricted for use by logon processes }
 : result := 'only.  The calling process has not registered as a logon process';
    ERROR_NOT_LOGON_PROCESS = 1362;
    {$EXTERNALSYM ERROR_NOT_LOGON_PROCESS}

 : result := 'Cannot start a new logon session with an ID that is already in use';
    ERROR_LOGON_SESSION_EXISTS = 1363;
    {$EXTERNALSYM ERROR_LOGON_SESSION_EXISTS}

 : result := 'A specified authentication package is unknown';
    ERROR_NO_SUCH_PACKAGE = 1364;
    {$EXTERNALSYM ERROR_NO_SUCH_PACKAGE}

 : result := 'The logon session is not in a state that is consistent with the }
 : result := 'requested operation';
    ERROR_BAD_LOGON_SESSION_STATE = 1365;
    {$EXTERNALSYM ERROR_BAD_LOGON_SESSION_STATE}

 : result := 'The logon session ID is already in use';
    ERROR_LOGON_SESSION_COLLISION = 1366;
    {$EXTERNALSYM ERROR_LOGON_SESSION_COLLISION}

 : result := 'A logon request contained an invalid logon type value';
    ERROR_INVALID_LOGON_TYPE = 1367;
    {$EXTERNALSYM ERROR_INVALID_LOGON_TYPE}

 : result := 'Unable to impersonate via a named pipe until data has been read }
 : result := 'from that pipe';
    ERROR_CANNOT_IMPERSONATE = 1368;
    {$EXTERNALSYM ERROR_CANNOT_IMPERSONATE}

 : result := 'The transaction state of a Registry subtree is incompatible with the }
 : result := 'requested operation';
    ERROR_RXACT_INVALID_STATE = 1369;
    {$EXTERNALSYM ERROR_RXACT_INVALID_STATE}

 : result := 'An internal security database corruption has been encountered';
    ERROR_RXACT_COMMIT_FAILURE = 1370;
    {$EXTERNALSYM ERROR_RXACT_COMMIT_FAILURE}

 : result := 'Cannot perform this operation on built-in accounts';
    ERROR_SPECIAL_ACCOUNT = 1371;
    {$EXTERNALSYM ERROR_SPECIAL_ACCOUNT}

 : result := 'Cannot perform this operation on this built-in special group';
    ERROR_SPECIAL_GROUP = 1372;
    {$EXTERNALSYM ERROR_SPECIAL_GROUP}

 : result := 'Cannot perform this operation on this built-in special user';
    ERROR_SPECIAL_USER = 1373;
    {$EXTERNALSYM ERROR_SPECIAL_USER}

 : result := 'The user cannot be removed from a group because the group }
 : result := 'is currently the user's primary group';
    ERROR_MEMBERS_PRIMARY_GROUP = 1374;
    {$EXTERNALSYM ERROR_MEMBERS_PRIMARY_GROUP}

 : result := 'The token is already in use as a primary token';
    ERROR_TOKEN_ALREADY_IN_USE = 1375;
    {$EXTERNALSYM ERROR_TOKEN_ALREADY_IN_USE}

 : result := 'The specified local group does not exist';
    ERROR_NO_SUCH_ALIAS = 1376;
    {$EXTERNALSYM ERROR_NO_SUCH_ALIAS}

 : result := 'The specified account name is not a member of the local group';
    ERROR_MEMBER_NOT_IN_ALIAS = 1377;
    {$EXTERNALSYM ERROR_MEMBER_NOT_IN_ALIAS}

 : result := 'The specified account name is already a member of the local group';
    ERROR_MEMBER_IN_ALIAS = 1378;
    {$EXTERNALSYM ERROR_MEMBER_IN_ALIAS}

 : result := 'The specified local group already exists';
    ERROR_ALIAS_EXISTS = 1379;
    {$EXTERNALSYM ERROR_ALIAS_EXISTS}

 : result := 'Logon failure: the user has not been granted the requested }
 : result := 'logon type at this computer';
    ERROR_LOGON_NOT_GRANTED = 1380;
    {$EXTERNALSYM ERROR_LOGON_NOT_GRANTED}

 : result := 'The maximum number of secrets that may be stored in a single system has been }
 : result := 'exceeded';
    ERROR_TOO_MANY_SECRETS = 1381;
    {$EXTERNALSYM ERROR_TOO_MANY_SECRETS}

 : result := 'The length of a secret exceeds the maximum length allowed';
    ERROR_SECRET_TOO_LONG = 1382;
    {$EXTERNALSYM ERROR_SECRET_TOO_LONG}

 : result := 'The local security authority database contains an internal inconsistency';
    ERROR_INTERNAL_DB_ERROR = 1383;
    {$EXTERNALSYM ERROR_INTERNAL_DB_ERROR}

 : result := 'During a logon attempt, the user's security context accumulated too many }
 : result := 'security IDs';
    ERROR_TOO_MANY_CONTEXT_IDS = 1384;
    {$EXTERNALSYM ERROR_TOO_MANY_CONTEXT_IDS}

 : result := 'Logon failure: the user has not been granted the requested logon type }
 : result := 'at this computer';
    ERROR_LOGON_TYPE_NOT_GRANTED = 1385;
    {$EXTERNALSYM ERROR_LOGON_TYPE_NOT_GRANTED}

 : result := 'A cross-encrypted password is necessary to change a user password';
    ERROR_NT_CROSS_ENCRYPTION_REQUIRED = 1386;
    {$EXTERNALSYM ERROR_NT_CROSS_ENCRYPTION_REQUIRED}

 : result := 'A new member could not be added to a local group because the member does }
 : result := 'not exist';
    ERROR_NO_SUCH_MEMBER = 1387;
    {$EXTERNALSYM ERROR_NO_SUCH_MEMBER}

 : result := 'A new member could not be added to a local group because the member has the }
 : result := 'wrong account type';
    ERROR_INVALID_MEMBER = 1388;
    {$EXTERNALSYM ERROR_INVALID_MEMBER}

 : result := 'Too many security IDs have been specified';
    ERROR_TOO_MANY_SIDS = 1389;
    {$EXTERNALSYM ERROR_TOO_MANY_SIDS}

 : result := 'A cross-encrypted password is necessary to change this user password';
    ERROR_LM_CROSS_ENCRYPTION_REQUIRED = 1390;
    {$EXTERNALSYM ERROR_LM_CROSS_ENCRYPTION_REQUIRED}

 : result := 'Indicates an TACL contains no inheritable components }
    ERROR_NO_INHERITANCE = 1391;
    {$EXTERNALSYM ERROR_NO_INHERITANCE}

 : result := 'The file or directory is corrupt and non-readable';
    ERROR_FILE_CORRUPT = 1392;
    {$EXTERNALSYM ERROR_FILE_CORRUPT}

 : result := 'The disk structure is corrupt and non-readable';
    ERROR_DISK_CORRUPT = 1393;
    {$EXTERNALSYM ERROR_DISK_CORRUPT}

 : result := 'There is no user session key for the specified logon session';
    ERROR_NO_USER_SESSION_KEY = 1394;
    {$EXTERNALSYM ERROR_NO_USER_SESSION_KEY}

 : result := 'The service being accessed is licensed for a particular number of connections';
 : result := 'No more connections can be made to the service at this time }
 : result := 'because there are already as many connections as the service can accept';
    ERROR_LICENSE_QUOTA_EXCEEDED = 1395;
    {$EXTERNALSYM ERROR_LICENSE_QUOTA_EXCEEDED}


  { WinUser Error Codes }

 : result := 'Invalid window handle';
    ERROR_INVALID_WINDOW_HANDLE = 1400;
    {$EXTERNALSYM ERROR_INVALID_WINDOW_HANDLE}

 : result := 'Invalid menu handle';
    ERROR_INVALID_MENU_HANDLE = 1401;
    {$EXTERNALSYM ERROR_INVALID_MENU_HANDLE}

 : result := 'Invalid cursor handle';
    ERROR_INVALID_CURSOR_HANDLE = 1402;
    {$EXTERNALSYM ERROR_INVALID_CURSOR_HANDLE}

 : result := 'Invalid accelerator table handle';
    ERROR_INVALID_ACCEL_HANDLE = 1403;
    {$EXTERNALSYM ERROR_INVALID_ACCEL_HANDLE}

 : result := 'Invalid hook handle';
    ERROR_INVALID_HOOK_HANDLE = 1404;
    {$EXTERNALSYM ERROR_INVALID_HOOK_HANDLE}

 : result := 'Invalid handle to a multiple-window position structure';
    ERROR_INVALID_DWP_HANDLE = 1405;
    {$EXTERNALSYM ERROR_INVALID_DWP_HANDLE}

 : result := 'Cannot create a top-level child window';
    ERROR_TLW_WITH_WSCHILD = 1406;
    {$EXTERNALSYM ERROR_TLW_WITH_WSCHILD}

 : result := 'Cannot find window class';
    ERROR_CANNOT_FIND_WND_CLASS = 1407;
    {$EXTERNALSYM ERROR_CANNOT_FIND_WND_CLASS}

 : result := 'Invalid window, belongs to other thread';
    ERROR_WINDOW_OF_OTHER_THREAD = 1408;
    {$EXTERNALSYM ERROR_WINDOW_OF_OTHER_THREAD}

 : result := 'Hot key is already registered';
    ERROR_HOTKEY_ALREADY_REGISTERED = 1409;
    {$EXTERNALSYM ERROR_HOTKEY_ALREADY_REGISTERED}

 : result := 'Class already exists';
    ERROR_CLASS_ALREADY_EXISTS = 1410;
    {$EXTERNALSYM ERROR_CLASS_ALREADY_EXISTS}

 : result := 'Class does not exist';
    ERROR_CLASS_DOES_NOT_EXIST = 1411;
    {$EXTERNALSYM ERROR_CLASS_DOES_NOT_EXIST}

 : result := 'Class still has open windows';
    ERROR_CLASS_HAS_WINDOWS = 1412;
    {$EXTERNALSYM ERROR_CLASS_HAS_WINDOWS}

 : result := 'Invalid index';
    ERROR_INVALID_INDEX = 1413;
    {$EXTERNALSYM ERROR_INVALID_INDEX}

 : result := 'Invalid icon handle';
    ERROR_INVALID_ICON_HANDLE = 1414;
    {$EXTERNALSYM ERROR_INVALID_ICON_HANDLE}

 : result := 'Using private DIALOG window words';
    ERROR_PRIVATE_DIALOG_INDEX = 1415;
    {$EXTERNALSYM ERROR_PRIVATE_DIALOG_INDEX}

 : result := 'The listbox identifier was not found';
    ERROR_LISTBOX_ID_NOT_FOUND = 1416;
    {$EXTERNALSYM ERROR_LISTBOX_ID_NOT_FOUND}

 : result := 'No wildcards were found';
    ERROR_NO_WILDCARD_CHARACTERS = 1417;
    {$EXTERNALSYM ERROR_NO_WILDCARD_CHARACTERS}

 : result := 'Thread does not have a clipboard open';
    ERROR_CLIPBOARD_NOT_OPEN = 1418;
    {$EXTERNALSYM ERROR_CLIPBOARD_NOT_OPEN}

 : result := 'Hot key is not registered';
    ERROR_HOTKEY_NOT_REGISTERED = 1419;
    {$EXTERNALSYM ERROR_HOTKEY_NOT_REGISTERED}

 : result := 'The window is not a valid dialog window';
    ERROR_WINDOW_NOT_DIALOG = 1420;
    {$EXTERNALSYM ERROR_WINDOW_NOT_DIALOG}

 : result := 'Control ID not found';
    ERROR_CONTROL_ID_NOT_FOUND = 1421;
    {$EXTERNALSYM ERROR_CONTROL_ID_NOT_FOUND}

 : result := 'Invalid message for a combo box because it does not have an edit control';
    ERROR_INVALID_COMBOBOX_MESSAGE = 1422;
    {$EXTERNALSYM ERROR_INVALID_COMBOBOX_MESSAGE}

 : result := 'The window is not a combo box';
    ERROR_WINDOW_NOT_COMBOBOX = 1423;
    {$EXTERNALSYM ERROR_WINDOW_NOT_COMBOBOX}

 : result := 'Height must be less than 256';
    ERROR_INVALID_EDIT_HEIGHT = 1424;
    {$EXTERNALSYM ERROR_INVALID_EDIT_HEIGHT}

 : result := 'Invalid device context (DC) handle';
    ERROR_DC_NOT_FOUND = 1425;
    {$EXTERNALSYM ERROR_DC_NOT_FOUND}

 : result := 'Invalid hook procedure type';
    ERROR_INVALID_HOOK_FILTER = 1426;
    {$EXTERNALSYM ERROR_INVALID_HOOK_FILTER}

 : result := 'Invalid hook procedure';
    ERROR_INVALID_FILTER_PROC = 1427;
    {$EXTERNALSYM ERROR_INVALID_FILTER_PROC}

 : result := 'Cannot set non-local hook without a module handle';
    ERROR_HOOK_NEEDS_HMOD = 1428;
    {$EXTERNALSYM ERROR_HOOK_NEEDS_HMOD}

 : result := 'This hook procedure can only be set globally';
    ERROR_GLOBAL_ONLY_HOOK = 1429;
    {$EXTERNALSYM ERROR_GLOBAL_ONLY_HOOK}

 : result := 'The journal hook procedure is already installed';
    ERROR_JOURNAL_HOOK_SET = 1430;
    {$EXTERNALSYM ERROR_JOURNAL_HOOK_SET}

 : result := 'The hook procedure is not installed';
    ERROR_HOOK_NOT_INSTALLED = 1431;
    {$EXTERNALSYM ERROR_HOOK_NOT_INSTALLED}

 : result := 'Invalid message for single-selection listbox';
    ERROR_INVALID_LB_MESSAGE = 1432;
    {$EXTERNALSYM ERROR_INVALID_LB_MESSAGE}

 : result := 'LB_SETCOUNT sent to non-lazy listbox';
    ERROR_SETCOUNT_ON_BAD_LB = 1433;
    {$EXTERNALSYM ERROR_SETCOUNT_ON_BAD_LB}

 : result := 'This list box does not support tab stops';
    ERROR_LB_WITHOUT_TABSTOPS = 1434;
    {$EXTERNALSYM ERROR_LB_WITHOUT_TABSTOPS}

 : result := 'Cannot destroy object created by another thread';
    ERROR_DESTROY_OBJECT_OF_OTHER_THREAD = 1435;
    {$EXTERNALSYM ERROR_DESTROY_OBJECT_OF_OTHER_THREAD}

 : result := 'Child windows cannot have menus';
    ERROR_CHILD_WINDOW_MENU = 1436;
    {$EXTERNALSYM ERROR_CHILD_WINDOW_MENU}

 : result := 'The window does not have a system menu';
    ERROR_NO_SYSTEM_MENU = 1437;
    {$EXTERNALSYM ERROR_NO_SYSTEM_MENU}

 : result := 'Invalid message box style';
    ERROR_INVALID_MSGBOX_STYLE = 1438;
    {$EXTERNALSYM ERROR_INVALID_MSGBOX_STYLE}

 : result := 'Invalid system-wide ( SPI_* ) parameter';
    ERROR_INVALID_SPI_VALUE = 1439;
    {$EXTERNALSYM ERROR_INVALID_SPI_VALUE}

 : result := 'Screen already locked';
    ERROR_SCREEN_ALREADY_LOCKED = 1440;
    {$EXTERNALSYM ERROR_SCREEN_ALREADY_LOCKED}

 : result := 'All handles to windows in a multiple-window position structure must }
 : result := 'have the same parent';
    ERROR_HWNDS_HAVE_DIFF_PARENT = 1441;
    {$EXTERNALSYM ERROR_HWNDS_HAVE_DIFF_PARENT}

 : result := 'The window is not a child window';
    ERROR_NOT_CHILD_WINDOW = 1442;
    {$EXTERNALSYM ERROR_NOT_CHILD_WINDOW}

 : result := 'Invalid GW_* command';
    ERROR_INVALID_GW_COMMAND = 1443;
    {$EXTERNALSYM ERROR_INVALID_GW_COMMAND}

 : result := 'Invalid thread identifier';
    ERROR_INVALID_THREAD_ID = 1444;
    {$EXTERNALSYM ERROR_INVALID_THREAD_ID}

 : result := 'Cannot process a message from a window that is not a multiple document }
 : result := 'interface (MDI) window';
    ERROR_NON_MDICHILD_WINDOW = 1445;
    {$EXTERNALSYM ERROR_NON_MDICHILD_WINDOW}

 : result := 'Popup menu already active';
    ERROR_POPUP_ALREADY_ACTIVE = 1446;
    {$EXTERNALSYM ERROR_POPUP_ALREADY_ACTIVE}

 : result := 'The window does not have scroll bars';
    ERROR_NO_SCROLLBARS = 1447;
    {$EXTERNALSYM ERROR_NO_SCROLLBARS}

 : result := 'Scroll bar range cannot be greater than $7FFF';
    ERROR_INVALID_SCROLLBAR_RANGE = 1448;
    {$EXTERNALSYM ERROR_INVALID_SCROLLBAR_RANGE}

 : result := 'Cannot show or remove the window in the way specified';
    ERROR_INVALID_SHOWWIN_COMMAND = 1449;
    {$EXTERNALSYM ERROR_INVALID_SHOWWIN_COMMAND}

 : result := 'Insufficient system resources exist to complete the requested service';
    ERROR_NO_SYSTEM_RESOURCES = 1450;
    {$EXTERNALSYM ERROR_NO_SYSTEM_RESOURCES}

 : result := 'Insufficient system resources exist to complete the requested service';
    ERROR_NONPAGED_SYSTEM_RESOURCES = 1451;
    {$EXTERNALSYM ERROR_NONPAGED_SYSTEM_RESOURCES}

 : result := 'Insufficient system resources exist to complete the requested service';
    ERROR_PAGED_SYSTEM_RESOURCES = 1452;
    {$EXTERNALSYM ERROR_PAGED_SYSTEM_RESOURCES}

 : result := 'Insufficient quota to complete the requested service';
    ERROR_WORKING_SET_QUOTA = 1453;
    {$EXTERNALSYM ERROR_WORKING_SET_QUOTA}

 : result := 'Insufficient quota to complete the requested service';
    ERROR_PAGEFILE_QUOTA = 1454;
    {$EXTERNALSYM ERROR_PAGEFILE_QUOTA}

 : result := 'The paging file is too small for this operation to complete';
    ERROR_COMMITMENT_LIMIT = 1455;
    {$EXTERNALSYM ERROR_COMMITMENT_LIMIT}

 : result := 'A menu item was not found';
    ERROR_MENU_ITEM_NOT_FOUND = 1456;
    {$EXTERNALSYM ERROR_MENU_ITEM_NOT_FOUND}

 : result := 'Invalid keyboard layout handle';
    ERROR_INVALID_KEYBOARD_HANDLE = 1457;
    {$EXTERNALSYM ERROR_INVALID_KEYBOARD_HANDLE}

 : result := 'Hook type not allowed';
    ERROR_HOOK_TYPE_NOT_ALLOWED = 1458;
    {$EXTERNALSYM ERROR_HOOK_TYPE_NOT_ALLOWED}

 : result := 'This operation requires an interactive windowstation';
    ERROR_REQUIRES_INTERACTIVE_WINDOWSTATION = 1459;
    {$EXTERNALSYM ERROR_REQUIRES_INTERACTIVE_WINDOWSTATION}

 : result := 'This operation returned because the timeout period expired';
    ERROR_TIMEOUT = 1460;
    {$EXTERNALSYM ERROR_TIMEOUT}
*)



    else
      result := 'Unknown';
  end;
end;

//***************************************************************************
//
//  FUNCTION  : IsFileInUse
//
//  I/P       : FileName: TFileName - The full filename of the file to be checked
//
//  O/P       : Boolean - TRUE if the file is in use
//
//  OPERATION : Find out if a file is in use
//
//              https://www.swissdelphicenter.ch/en/showcode.php?id=104
//
//  UPDATED   : 2021-04-08
//
//***************************************************************************
function IsFileInUse(FileName: TFileName): Boolean;
var
  HFileRes: HFILE;
begin
  Result := False;
  if (not FileExists(FileName)) then
  begin
    Exit;
  end;

  HFileRes := CreateFile(PChar(FileName),
                         GENERIC_READ or GENERIC_WRITE,
                         0,
                         nil,
                         OPEN_EXISTING,
                         FILE_ATTRIBUTE_NORMAL,
                         0);
  Result := (HFileRes = INVALID_HANDLE_VALUE);
  if (not Result) then
  begin
    CloseHandle(HFileRes);
  end;
end;

//***************************************************************************
//
//  FUNCTION    :   initialization
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
initialization;
begin
  iLastIOResult := 0;
  InitGetFolderSize;

  var t1234 : String;
  t1234 := TPath.GetHomePath;

end; // initialization

end.

