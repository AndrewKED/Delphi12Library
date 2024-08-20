unit Ini_Ops;

interface

uses
  System.IniFiles, System.Win.Registry;

function GetIniFileFloat(targetFile : TCustomIniFile;
                         sSection : String;
                         sKey : String;
                         dInvalid : Double) : Double;
procedure SetIniFileFloat(targetFile : TCustomIniFile;
                          sSection : String;
                          sKey : String;
                          valueGiven : Double);
function CountValues(targetFile : TCustomIniFile;
                     sSection : String;
                     filter : String = '.+') : Integer; overload;
function CountValues(targetFile : TRegIniFile;
                     sSection : String;
                     filter : String = '.+') : Integer; overload;
procedure ReloadInMemoryIni(var target : TMemIniFile;
                            updateFirst : Boolean = TRUE);
procedure ExportRegKey(bLocalKey : boolean;
                       sSection : String;
                       sFileName : String;
                       bIniFileFormat : boolean);

implementation

uses
  System.SysUtils, System.Classes, System.RegularExpressions,
  WinAPI.Windows,
  Str_Ops;

var
  rifKey : TRegistryIniFile;  // Used in recursive calls for registry exporting
  mifRIFAll : TIniFile;       // Used in recursive calls for registry exporting

  t1234 : String;

//***************************************************************************
//
//  FUNCTION  : GetIniFileFloat
//
//  I/P       : targetFile : TCustomIniFile - The pre-opened ini-format
//                information file
//
//              sSection : String - Section in the ini file
//
//              sKey : String - Key in the ini file
//
//              dInvalid : double - Value to return if invalid
//
//  O/P       : double - The result
//
//  OPERATION : This function is only necessary for TMemIniFile and TIniFile.
//              It need not be used for TRegistryIniFile, which stores floats
//              in binary form. (These are all descendents of TCustomIniFile)
//
//              Reads a floating point number from an ini-formation information
//              file.
//
//              The function first tries to convert using the current decimal
//              separator. If that is not successful, it tries the "other" one.
//              In general, decimal separators are either '.' or ','.
//
//  UPDATED   : 2019-03-07
//
//***************************************************************************
function GetIniFileFloat(targetFile : TCustomIniFile;
                         sSection : String;
                         sKey : String;
                         dInvalid : Double) : Double;
begin
  result := ForcedStrToFloat(targetFile.ReadString(sSection, sKey, ''), dInvalid);
end; // GetIniFileFloat

//***************************************************************************
//
//  FUNCTION  : SetIniFileFloat
//
//  I/P       : targetFile : TCustomIniFile - The pre-opened ini-format
//                information file
//
//              sSection : String - Section in the ini file
//
//              sKey : String - Key in the ini file
//
//              valueGiven : double - The value to be written
//
//  O/P       : None
//
//  OPERATION : This function is only necessary for TMemIniFile and TIniFile.
//              It need not be used for TRegistryIniFile, which stores floats
//              in binary form. (These are all descendents of TCustomIniFile)
//
//              Writes a floating point number to an ini-formation information
//              file.   The function uses the decimal separator that was in use
//              when the file was created (which is expected to be indicated
//              in the 'General'/'DecimalSeparator' section/key.
//
//              Because the thousands separator may also be an issue, the value
//              is written in scientific notation.
//
//  UPDATED   : 2020-04-14
//
//***************************************************************************
procedure SetIniFileFloat(targetFile : TCustomIniFile;
                          sSection : String;
                          sKey : String;
                          valueGiven : Double);
var
  cCurrentDecimalSeaprator : char;

begin
  // Load the information using the decimal separator that was used when the
  // ini file was created.
  cCurrentDecimalSeaprator := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := GetNthChar(targetFile.ReadString('General','DecimalSeparator','.'),1);
    targetFile.WriteString(sSection, sKey, Format('%e', [valueGiven]));
  finally
    FormatSettings.DecimalSeparator := cCurrentDecimalSeaprator;
  end;
end; // SetIniFileFloat

//***************************************************************************
//
//  FUNCTION  : CountValues
//
//  I/P       : targetFile : TCustomIniFile - The target INI file.
//
//              sSection : String - The name of the section to be examined.
//
//              filter : String = '.+' - The optional regex filter to be applied.
//
//  O/P       : Integer - The number of keys within the section that match
//                the filter.
//
//  OPERATION : Count the number of keys in an ini file section, with optional
//              key name matching.
//
//  UPDATED   : 2023-03-28
//
//***************************************************************************
function CountValues(targetFile : TCustomIniFile;
                     sSection : String;
                     filter : String = '.+') : Integer; overload;
var
  content : TStringList;
  n: Integer;

begin
  Result := 0;
  content := TStringList.Create;
  try
    targetFile.ReadSection(sSection, content);
    for n := 0 to content.Count-1 do
    begin
      if (TRegEx.Match(content[n], filter).Index = 1) then
      begin
        Inc(Result);
      end; // if
    end; // for
  finally
    content.Free;
  end;
end;

function CountValues(targetFile : TRegIniFile;
                     sSection : String;
                     filter : String = '.+') : Integer; overload;
var
  content : TStringList;
  n: Integer;

begin
  Result := 0;
  content := TStringList.Create;
  try
    targetFile.ReadSection(sSection, content);
    for n := 0 to content.Count-1 do
    begin
      if (TRegEx.Match(content[n], filter).Index = 1) then
      begin
        Inc(Result);
      end; // if
    end; // for
  finally
    content.Free;
  end;

end;

//***************************************************************************
//
//  FUNCTION  : ReloadInMemoryIni
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Refresh a TMemoryIni (typically a configuration file).
//
//              This can be useful in handling things in the IDE, when halting
//              the program operation.
//
//  UPDATED   : 2023-09-21
//
//***************************************************************************
procedure ReloadInMemoryIni(var target : TMemIniFile;
                            updateFirst : Boolean = TRUE);
var
  originalFileName : String;
  originalAutoSave : Boolean;


begin
  if (updateFirst) then
  begin
    // Note that this would be automatically done, on destruction below, if the
    // .AutoSave property is TRUE.
    target.UpdateFile;
  end;

  originalFileName := target.FileName;
  originalAutoSave := target.AutoSave;

  target.Free;
  target := TMemIniFile.Create(originalFileName);

  target.AutoSave := originalAutoSave;
end; // ReloadInMemoryIni

//***************************************************************************
//
//  FUNCTION  : ExportSection
//
//  I/P       : sSectionName : String - The section (key) of the given
//                TRegIniFile to be exported to a text file
//
//              bIniFileFormat : Boolean - TRUE if the export text file should
//                be in the format of a TIniFile
//
//  O/P       :
//
//  OPERATION : Exports a named key of a given TRegIniFile.
//
//  UPDATED   : 2012-09-25
//
//***************************************************************************
procedure ExportSection(sSectionName : String;
                        bIniFileFormat : boolean);
var
  slValues : TStringList;
  m,i : Integer;
  sTemp : String;
  abBinData: array [0..7] of byte;
  sKey : String;
  sValue : String;

begin
  slValues := TStringList.Create;

  // First export all the keys within this section
  rifKey.ReadSectionValues(sSectionName,slValues);
  m := 0;
  while (m < slValues.Count) do
  begin
    sKey := Copy(slValues[m],1,Pos('=',slValues[m])-1);
    sValue := Copy(slValues[m],Pos('=',slValues[m])+1,Length(slValues[m]));
    if (sKey <> '') then
    begin
      // Simply adding each value to the output string list using
      //      sRIFAll.Add(slSK.Strings[m]);
      // will incluce key values of the form:
      //      dword:xxxxxxxx and
      //      hex:xx,xx,xx,xx,xx,xx,xx,xx
      // I want the exported file to be readable as a TIniFile, so these must
      // be converted to integers and floats, respectively
      if (bIniFileFormat) then
      begin
        if ((sValue <> '') and
            (Pos('dword',sValue) = 1)) then
        begin
          // Integer
          sValue := Copy(sValue,7,Length(sValue));
          mifRIFAll.WriteInteger(sSectionName,sKey,StrToInt('$' + sValue));

          mifRIFAll.Free;
          mifRIFAll := TIniFile.Create(t1234);
        end // if
        else
          if ((sValue <> '') and
              (Pos('hex',sValue) = 1)) then
          begin
            // Floating point value
            sValue := Copy(sValue,5,Length(sValue));
            for i := 0 to 7 do
              abBinData[i] := StrToInt('$' + ExtractAndTrim(sValue,','));
            SetInifileFloat(mifRIFAll, sSectionName,sKey,double(abBinData));
          end // if
          else
          begin
            // String
            // Registry strings can contain carriage returns and line feeds (as might be found
            // when writing a TMemo.Text to a registry)
            // Handle these separately so that the they do not destroy the TIniFile format
            // (This will mean a discontinuity in the way that this string is read and written.
            // In TRegIniFile it could have been read/written into a single key.
            // In TIniFile is must be read and written into separate, indexed keys.)
            if (Pos(#$0D,sValue)<>0) or (Pos(#$0A,sValue) <> 0) then
            begin
              sValue := StringReplace(sValue,#$0D#$0A,#$0D,[rfReplaceAll]);
              sValue := StringReplace(sValue,#$0A#$0D,#$0D,[rfReplaceAll]);
              sValue := StringReplace(sValue,#$0A,#$0D,[rfReplaceAll]);
              i := 0;
              while (Pos(#$0D,sValue)<>0) do
              begin
                mifRIFAll.WriteString(sSectionName + '\' + sKey,IntToStr(i),ExtractAndTrim(sValue,#$0D));
                Inc(i);
              end;
              mifRIFAll.WriteString(sSectionName + '\' + sKey,IntToStr(i),sValue);
            end // if
            else
              mifRIFAll.WriteString(sSectionName,sKey,sValue);
          end;
      end // if
      else
        // We do not want the output in TIniFile format, so write as it was read from the registry
        mifRIFAll.WriteString(sSectionName,sKey,sValue);
    end; // else
    Inc(m);
  end;

  // Then check if there are further sub sections
  rifKey.ReadSections(sSectionName,slValues);
  m := 0;
  while (m < slValues.Count) do
  begin
    if (sSectionName <> '') then
      sTemp := sSectionName + '\'
    else
      sTemp := '';
    ExportSection(sTemp + slValues.Strings[m],bIniFileFormat);
    Inc(m);
  end;

  slValues.Free;
end; // ExportSection

//***************************************************************************
//
//  FUNCTION  : ExportRegKey
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Note that this can cause problems with Windows 7 UAC.
//
//  UPDATED   : 2012-09-25
//
//***************************************************************************
procedure ExportRegKey(bLocalKey : boolean;
                       sSection : String;
                       sFileName : String;
                       bIniFileFormat : boolean);
begin
  rifKey := TRegistryIniFile.Create('');

  if (bLocalKey) then
    rifKey.RegIniFile.RootKey := HKEY_LOCAL_MACHINE
  else
    rifKey.RegIniFile.RootKey := HKEY_CURRENT_USER;
  rifKey.RegIniFile.OpenKey(sSection,True);

  // Use Unicode in the output export file, so that it can handle any input characters
//  mifRIFAll := TMemIniFile.Create(sFileName,TEncoding.Unicode);
  mifRIFAll := TIniFile.Create(sFileName);
  t1234 := sFileName;
  ExportSection('',bIniFileFormat);

//  mifRIFAll.UpdateFile;

  mifRIFAll.Free;
  rifKey.Free;
end; // ExportRegKey

end.
