unit DBUtilsCommon;

//***************************************************************************
//
// DESCRIPTION:
//  Common utilities to handle database maintenance using my standard table
//  definition files.
//
// TO BE DONE:
//
// VERSIONS:
//
//    Update Date : 2010-10-12
//    Changes Made :
//      * Based on Delphi7 DBUtilsParadox, I removed all table-specific operations
//        for movement to separate DBUtilsXXXX units
//
//
//***************************************************************************

interface

{$A-}

uses DB, StdCtrls, COMCtrls, Forms, Classes, IniFiles, DKLang;

const
  DB_UPG_FILE = 'DB-UPG';               // The in-memory file that holds database information, and pointers to table files
  TB_UPG_FILE = 'TB-UPG';               // The in-memory file that holds a table's structure
  TABLE_RESOURCE_PREFIX = 'TB_';        // Prefix added to upper-case table name to get the resource
  DB_UPG_RESOURCE = 'DB_UPG';           // The resource that holds database information, and pointers to table resources
  TEMP_TABLE_NAME = '~TMP~TBL';         // Temporary root of table file name (MUST be unused elsewhere)

  ERR_DB_NONE = 0;                      // No error
  ERR_DB_OLDER = 1;                     // Database is older.   An upgrade will be needed.
  ERR_DB_NEWER = 2;                     // Database appears to be newer.   User needs to upgrade main software
  ERR_DB_PDX2DBI_INSTALL = 3;           // Paradox-to-DBI converter must be installed
  ERR_DB_ACCESS_DENIED = 4;             // Non exclusive access (open with another user)
  ERR_DB_DEVELOPMENT = 5;               // An error typically directed at the SW developer (e.g. a definition file error)
  ERR_DB_OTHER = 6;                     // An unknown table error - maybe the user can help

function GotIndexInfo(sIndexLine : String;
                      var sIndexName : String;
                      var sIndexFields : String;
                      var setIndexOptions : TIndexOptions) : boolean;
function GetANSFieldDataType(cFieldID : char) : TFieldType;
function GetFieldTypeName (ft : TFieldType;
                           iStyle : integer) : String;
function GetTablesCount : Integer;
function GetDatabaseType : String;
function GotTableInformationFromIndex(iDBTableIndex : Integer) : Boolean;
function GotTableInformationFromName(sGivenTablename : String) : Boolean;
function WildcardTable(iDBTableIndex : Integer) : Boolean;
function TableFieldDefnsOK(sTableVer : string) : boolean;
function GetDBUpgResults : String;
procedure WriteToDBUpgLog (sLogLine : string);
function GetProgramTitle : String;
procedure StartDBUtils(bLog : boolean;
                       bClearLog : boolean);
function AccessedDBDefinitionResources : boolean;
procedure CloseOpenDataSets(dmData : TDataModule;
                            AlsoCloseMemoryDataSets : boolean);
function GotLatestVersion : boolean;
function VersionUpgradable(sTableDescriptive : String;
                           verSource : String) : boolean;
function LatestIndexDefnsOK : Boolean;
procedure SetLanguage(lcMain : TDKLanguageController);

var
  sDBUC_DBUpgResult : String;           // Empty string if last operation was OK.
                                        // Error message if not OK
  iDBUC_DBUpgErr : Integer;             // Error ID for the last operation
  sDBUC_DBFileName : String;            // Used by Absolute databases
  sDBUC_TableFilename : String;         // Full file name of the table currently being upgraded/tested
  sDBUC_TableTitle : String;            // A descriptive title of the table currently being upgraded
  sDBUC_Password : String;              // (A single) password to be used in the session.
  sDBUC_PasswordOK : Boolean;           // TRUE if the password (after an access operation) was found to be OK
  sDBUC_Session : String;               // Session name, if needed (Is this an alternative to providing a password, above?)
  mifDBUC_DBDefn : TMemIniFile;         // Database Definition file for the program
  mifDBUC_TableDefn : TMemIniFile;      // Definition file for a table
  sDBUC_AgentHelp : String;             // A internationalised string that tells the user to contact their supplier
  iDBUC_IndexesUpdated : Integer;       // Counts the number of tables which had their indexes updated
  iDBUC_FieldsUpdated : Integer;        // Counts the number of tables which had their fileds updated
  iDBUC_NewTables : Integer;            // Counts the number of new tables created
  iDBUC_Errors : Integer;               // Counts of the number of errors encountered
  iDBUC_iTablesInDB : Integer;          // The number of tables defined in the database
  sDBUC_VerLatest : String;             // Table version number ('Vxyz') of the expected latest version of the table


implementation

uses Windows, SysUtils, StrUtils, Controls, Registry, Dialogs,
     DBISAMTb,
     Str_Ops, File_Ops, TimeDate;

const

// Database types (in uppercase)
//------------------------------------------------------------------------------
  DB_DBISAM = 'DBISAM';
  DB_PARADOX = 'BDE PARADOX';
  DB_ABSOLUTE = 'ABSOLUTE';

var
  lcDBUtils : TDKLanguageController;
  sDBType : String;                 // Specifies ABSOLUTE, DBISAM or BDE PARADOX for the database type
  rifApplicationKey : TRegistryIniFile;  // Target application's sub-key
  tfOutput : TextFile;              // Used to log the progress
  bUseUpgradeLog : boolean;         // TRUE if we are to use the log file for recording operations

//***************************************************************************
//
//  FUNCTION    :   GotIndexInfo
//
//  I/P         :   sIndexLine - A comma-separated line defining a table
//                        index, from the control file.
//
//  O/P         :   boolean) - TRUE if th information was obtained.
//
//                      sIndexName - The name of the new index
//
//                      sINdexFields - The fields to be included in the index
//
//                      setIndexOptions - The options for the index
//
//  OPERATION   :   Extracts the index definition from an index description line
//
//  UPDATED     :   2003/09/05
//
//***************************************************************************
function GotIndexInfo(sIndexLine : String;
                      var sIndexName : String;
                      var sIndexFields : String;
                      var setIndexOptions : TIndexOptions) : boolean;
var
  iIndexNumericalOptions : Integer;
begin
  result := TRUE;

  sIndexName := ExtractAndTrim(sIndexLine,',');
  sIndexFields := ExtractAndTrim(sIndexLine,',');
  try
    iIndexNumericalOptions := StrToInt(sIndexLine);

    // Check that the options are a valid number
    if (iIndexNumericalOptions > $1F) then
    begin
      result := FALSE;
      iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
      sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (Latest)' + #$D +
                           'Options for index "' + sIndexName + '" are invalid.';
    end; // if

    setIndexOptions := [];
    if ((iIndexNumericalOptions AND $10)=$10) then
    begin
      setIndexOptions := setIndexOptions + [ixPrimary];
// Override the given primary index name - in the table it is stored as ''
      sIndexName := '';
    end; // if
    if ((iIndexNumericalOptions AND $08)=$08) then
      setIndexOptions := setIndexOptions + [ixUnique];
    if ((iIndexNumericalOptions AND $04)=$04) then
      setIndexOptions := setIndexOptions + [ixDescending];
    if ((iIndexNumericalOptions AND $02)=$02) then
      setIndexOptions := setIndexOptions + [ixNonMaintained];
    if ((iIndexNumericalOptions AND $01)=$01) then
      setIndexOptions := setIndexOptions + [ixCaseInsensitive];
  except
    // The options number could not be converted
    result := FALSE;
    iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
    sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (Latest)' + #$D +
                         'Options for index "' + sIndexName + '" are non-numeric.';
  end; // except
end; // GotIndexInfo

//***************************************************************************
//
//  FUNCTION    :   GetANSFieldDataType
//
//  I/P         :   cFieldID - A character indicating the type of field
//
//  O/P         :   (TFieldType) - The field type represented by the char.
//
//  OPERATION   :   Looks up the field type represented by a custom
//                      character.
//
//  UPDATED     :   2010-10-06
//
//***************************************************************************
function GetANSFieldDataType(cFieldID : char) : TFieldType;
begin
  case cFieldID of
    '$' : result := ftCurrency;
    '@' : result := ftDateTime;
    '=' : result := ftWideMemo;
    '1' : result := ftADT;
    '2' : result := ftArray;
    '3' : result := ftDBaseOle;
    '4' : result := ftDataSet;
    '5' : result := ftOraBlob;
    '6' : result := ftOraClob;
    '7' : result := ftVariant;
    '8' : result := ftInterface;
    'A' : result := ftString;
    'B' : result := ftBCD;
    'C' : result := ftCursor;
    'D' : result := ftDate;
    'E' : result := ftFmtMemo;
    'F' : result := ftReference;
    'G' : result := ftGraphic;
    'H' : result := ftLargeInt;
    'I' : result := ftInteger;
    'J' : result := ftGuid;
    'L' : result := ftBoolean;
    'M' : result := ftMemo;
    'N' : result := ftFloat;
    'O' : result := ftBlob;
    'P' : result := ftParadoxOle;
    'Q' : result := ftIDispatch;
    'R' : result := ftTypedBinary;
    'S' : result := ftSmallInt;
    'T' : result := ftTime;
    'U' : result := ftAutoInc;
    'V' : result := ftVarBytes;
    'W' : result := ftWord;
    'X' : result := ftFixedChar;
    'Y' : result := ftBytes;
    'Z' : result := ftWideString;
    else
      result := ftUnknown;
  end; // case
end; // GetANSFieldDataType

//***************************************************************************
//
//  FUNCTION  : GetFieldTypeName
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Returns a descriptive name for a given field type
//
//  UPDATED   : 2010-10-06
//
//***************************************************************************
function GetFieldTypeName (ft : TFieldType;
                           iStyle : integer) : String;
begin
  case iStyle of
    1 :  // Used to obtain the Delphi type description
    begin
      case ft of
        ftADT : result := 'ftADT';
        ftAutoInc : result := 'ftAutoInc';
        ftBCD : result := 'ftBCD';
        ftBlob : result := 'ftBlob';
        ftBoolean : result := 'ftBoolean';
        ftBytes : result := 'ftBytes';
        ftCurrency : result := 'ftCurrency';
        ftCursor : result := 'ftCursor';
        ftDataSet : result := 'ftDataSet';
        ftDate : result := 'ftDate';
        ftDateTime : result := 'ftDateTime';
        ftDBaseOle : result := 'ftDBaseOle';
        ftFixedChar : result := 'ftFixedChar';
        ftFloat : result := 'ftFloat';
        ftFmtMemo : result := 'ftFmtMemo';
        ftGraphic : result := 'ftGraphic';
        ftGuid : result := 'ftIGuid';
        ftIDispatch : result := 'ftIDispatch';
        ftInterface : result := 'ftInterface';
        ftInteger : result := 'ftInteger';
        ftLargeInt : result := 'ftLargeInt';
        ftMemo : result := 'ftMemo';
        ftWideMemo : result := 'ftWideMemo';
        ftParadoxOle : result := 'ftParadoxOle';
        ftOraBlob : result := 'ftOraBlob';
        ftOraClob : result := 'ftOraClob';
        ftReference : result := 'ftReference';
        ftSmallint : result := 'ftSmallint';
        ftString : result := 'ftString';
        ftTime : result := 'ftTime';
        ftTypedBinary : result := 'ftTypedBinary';
        ftVarBytes : result := 'ftVarBytes';
        ftVariant : result := 'ftVariant';
        ftWideString : result := 'ftWideString';
        ftWord : result := 'ftWord';
      else
        result := 'ftUnknown';
      end; // case
    end; // option

    2 :  // Used to obtain something that a user will recognise
    begin
      case ft of
        ftUnknown : result := 'Unknown';            // Unknown or undetermined
        ftString,
        ftWideString :
          result := 'String';	                      // Character or string field
        ftSmallint,                                 // 16-bit integer field
        ftInteger ,                                 // 32-bit integer field
        ftLargeInt :                                // Large integer field'
          result := 'Integer';
        ftWord : result := 'Positive integer';      // 16-bit unsigned integer field
        ftBoolean : result := 'Boolean';            // Boolean field
        ftFloat,                                    // Floating-point numeric field
        ftCurrency :                                // Money field
          result := 'Real';
        ftBCD : result := 'BCD';
        ftDate : result := 'Date';                  // Date field
        ftTime : result := 'Time';                  // Time field
        ftDateTime : result := 'Date+Time';         // Date and time field
        ftBytes : result := 'Fixed number of bytes (binary storage)';
        ftVarBytes : result := 'Variable number of bytes (binary storage)';
        ftAutoInc : result := 'Auto-inc';
        ftBlob : result := 'Binary Large OBject field';
        ftMemo,
        ftWideMemo : result := 'Memo';
        ftGraphic : result := 'Bitmap';
        ftFmtMemo : result := 'Formatted text memo field';
        ftParadoxOle : result := 'Paradox OLE field';
        ftDBaseOle : result := 'dBASE OLE field';
        ftTypedBinary : result := 'Typed binary field';
        ftCursor : result := 'Output cursor from an Oracle stored procedure (TParam only)';
        ftFixedChar : result := 'Fixed character field';
        ftADT : result := 'Abstract Data Type field';
        ftArray : result := 'Array';
        ftReference : result := 'REF';
        ftDataSet : result := 'DataSet';
        ftOraBlob : result := 'BLOB fields in Oracle 8 tables';
        ftOraClob : result := 'CLOB fields in Oracle 8 tables';
        ftVariant : result := 'Data of unknown or undetermined type';
        ftInterface : result := 'References to interfaces (IUnknown)';
        ftIDispatch : result := 'References to IDispatch interfaces';
        ftGuid : result := 'globally unique identifier (GUID) values';
      else
        result := 'Unknown';            // Unknown or undetermined
      end; // case
    end; // option

    else
    begin // Used to obtain a full-blown description
      case ft of
        ftString : result := 'Character or string field';
        ftSmallint : result := '16-bit integer field';
        ftInteger : result := '32-bit integer field';
        ftWord : result := '16-bit unsigned integer field';
        ftBoolean : result := 'Boolean field';
        ftFloat : result := 'Floating-point numeric field';
        ftCurrency : result := 'Money field';
        ftBCD : result := 'Binary-Coded Decimal field';
        ftDate : result := 'Date field';
        ftTime : result := 'Time field';
        ftDateTime : result := 'Date and time field';
        ftBytes : result := 'Fixed number of bytes (binary storage)';
        ftVarBytes : result := 'Variable number of bytes (binary storage)';
        ftAutoInc : result := 'Auto-incrementing 32-bit integer counter field';
        ftBlob : result := 'Binary Large OBject field';
        ftMemo : result := 'Text memo field';
        ftWideMemo : result := 'Wide text memo field';
        ftGraphic : result := 'Bitmap field';
        ftFmtMemo : result := 'Formatted text memo field';
        ftParadoxOle : result := 'Paradox OLE field';
        ftDBaseOle : result := 'dBASE OLE field';
        ftTypedBinary : result := 'Typed binary field';
        ftCursor : result := 'Output cursor from an Oracle stored procedure (TParam only)';
        ftFixedChar : result := 'Fixed character field';
        ftWideString : result := 'Wide string field';
        ftLargeInt : result := 'Large integer field';
        ftADT : result := 'Abstract Data Type field';
        ftArray : result := 'Array field';
        ftReference : result := 'REF field';
        ftDataSet : result := 'DataSet field';
        ftOraBlob : result := 'BLOB fields in Oracle 8 tables';
        ftOraClob : result := 'CLOB fields in Oracle 8 tables';
        ftVariant : result := 'Data of unknown or undetermined type';
        ftInterface : result := 'References to interfaces (IUnknown)';
        ftIDispatch : result := 'References to IDispatch interfaces';
        ftGuid : result := 'globally unique identifier (GUID) values';
      else
        result := 'Unknown or undetermined';
      end; // case
    end; // else

  end; // case
end; // GetFieldTypeName

//***************************************************************************
//
//  FUNCTION  : GetTablesCount
//
//  I/P       : None
//
//  O/P       : (integer) - The number of table entries.
//
//  OPERATION : Counts the number of tables that are contained in
//              the database.
//
//              The information is taken form the DB control file,
//              which is already open and accessable.
//
//  UPDATED   : 2010-10-12
//
//***************************************************************************
function GetTablesCount : Integer;
var
  sTFN : String;

begin
  result := 0;
  sTFN := mifDBUC_DBDefn.ReadString('Tables',IntToStr(result+1),'');
  while (sTFN <> '') do
  begin
    Inc(result);
    sTFN := mifDBUC_DBDefn.ReadString('Tables',IntToStr(result+1),'');
  end; // while
end; // GetTablesCount

//***************************************************************************
//
//  FUNCTION  : GetDatabaseType
//
//  I/P       : ifDBDefn : TIniFile - Open, with definition of database
//
//  O/P       : string : The ID of the type of tables in this database
//
//  OPERATION : Returns the type of tables in the database.
//
//              The information is taken form the DB control file,
//              which is already open and accessable.
//
//  UPDATED   : 2011-08-31
//
//***************************************************************************
function GetDatabaseType : String;
begin
  result := UpperCase(mifDBUC_DBDefn.ReadString('Type','Engine',''));
end; // GetDatabaseType

//***************************************************************************
//
//  FUNCTION  : GotTableInformationFromIndex
//
//  I/P       : iDBTableIndex : Integer - Index of the table in the [Tables]
//                section of the database definition file.
//
//  O/P       : Boolean - TRUE if the information was obtained.
//
//              mifDBUC_TableDefn : TMemIniFile - The table definition file.
//
//              sDBUC_TableFilename : String - The filename (no path) of the table
//                to be upgraded.   Includes wildcards, if present.
//                Returns an empty string if there is no defined table for the
//                given index.
//
//  OPERATION : Prepares the above variables, given the index of a
//                table in the database definition file.
//
//  UPDATED   : 2018-09-17
//
//***************************************************************************
function GotTableInformationFromIndex(iDBTableIndex : integer) : boolean;
var
  sLine : String;
  sTableDefResource : String;
  rsTableDefn : TResourceStream;
  slTableDefn : TStringList;

begin
  sLine := mifDBUC_DBDefn.ReadString('Tables',IntToStr(iDBTableIndex),'');
  // Extract the first CSV field (i.e. the resource name, including any wildcards)
  sDBUC_TableFilename := ExtractAndTrim(sLine,',');
  // Check that a valid resource name was specified
  if (sDBUC_TableFilename <> '') then
  begin
    // Remove any wildcards, and replace '-' (which I have been using for YAMS vehicles) with '_'
    sTableDefResource := TABLE_RESOURCE_PREFIX +
                         UpperCase(SearchAndReplace(SearchAndReplace(sDBUC_TableFilename,'*',''),'-','_'));
    rsTableDefn := TResourceStream.Create(HInstance, sTableDefResource, RT_RCDATA);
    try
      slTableDefn := TStringList.Create;
      try
        slTableDefn.LoadFromStream(rsTableDefn);
        mifDBUC_TableDefn.SetStrings(slTableDefn);
      finally
        slTableDefn.Free;
      end;
    finally
      rsTableDefn.Free;
    end;

    sDBType := UpperCase(GetDatabaseType);
    // Change the filename extension to indicate the table being upgraded
    if (sDBType = DB_ABSOLUTE) then
      sDBUC_TableFilename := ChangeFileExt(sDBUC_TableFilename,'')
    else
    if (sDBType = DB_DBISAM) then
      sDBUC_TableFilename := ChangeFileExt(sDBUC_TableFilename,'.dat')
    else
      sDBUC_TableFilename := ChangeFileExt(sDBUC_TableFilename,'.db');
    result := TRUE;
  end // if
  else
  begin
    mifDBUC_TableDefn.Clear;
    result := FALSE;
  end; // else
end; // GotTableInformationFromIndex

//***************************************************************************
//
//  FUNCTION  : GotTableInformationFromName
//
//  I/P       : sGivenTablename : String - The filename of the table, which
//                may include an extension
//
//  O/P       : Boolean - TRUE if the information was obtained.
//
//              ifTableDefn : TIniFile - The table definition file.
//
//              sDBUC_TableFilename : String - The filename (no path) of the table
//                to be upgraded.   Returns an empty string if there
//                is no defined table for the given index.
//
//  OPERATION : Prepares the above variables, given the index of a
//                table in the database definition file.
//
//  UPDATED   : 2010-10-12
//
//***************************************************************************
function GotTableInformationFromName(sGivenTablename : string) : boolean;
var
  sTableDefResource : String;
  rsTableDefn : TResourceStream;
  slTableDefn : TStringList;

begin
  sGivenTablename := ChangeFileExt(sGivenTablename,'');
  // Check that a valid resource name was specified
  if (sGivenTablename <> '') then
  begin
    // Remove any wildcards, and replace '-' (which I have been using for YAMS vehicles) with '_'
    sTableDefResource := TABLE_RESOURCE_PREFIX +
                         UpperCase(SearchAndReplace(SearchAndReplace(sGivenTablename,'*',''),'-','_'));
    rsTableDefn := TResourceStream.Create(HInstance, sTableDefResource, RT_RCDATA);
    try
      slTableDefn := TStringList.Create;
      try
        slTableDefn.LoadFromStream(rsTableDefn);
        mifDBUC_TableDefn.SetStrings(slTableDefn);
      finally
        slTableDefn.Free;
      end;
    finally
      rsTableDefn.Free;
    end;

    sDBType := UpperCase(GetDatabaseType);
    // Change the filename extension to indicate the table being upgraded
    if (sDBType = DB_ABSOLUTE) then
      sDBUC_TableFilename := ChangeFileExt(sGivenTablename,'')
    else
    if (sDBType = DB_DBISAM) then
      sDBUC_TableFilename := ChangeFileExt(sGivenTablename,'.dat')
    else
      sDBUC_TableFilename := ChangeFileExt(sGivenTablename,'.db');
    result := TRUE;
  end // if
  else
  begin
    mifDBUC_TableDefn.Clear;
    result := FALSE;
  end; // else
end; // GotTableInformationFromName

//***************************************************************************
//
//  FUNCTION  : WildcardTable
//
//  I/P       : iDBTableIndex : Integer - Index of the table in the [Tables]
//                section of the database definition file.
//
//  O/P       : Boolean - TRUE if this is a "Wildcard" table
//
//  OPERATION : Checks whether there are meant to be multiple copies of
//              tables of this form, all with the same record/index structure.
//
//  UPDATED   : 2018-11-08
//
//***************************************************************************
function WildcardTable(iDBTableIndex : Integer) : Boolean;
var
  sLine : String;
  sTemp : String;

begin
  sLine := mifDBUC_DBDefn.ReadString('Tables',IntToStr(iDBTableIndex),'');
  // Extract the first CSV field (i.e. the file name)
  sTemp := ExtractAndTrim(sLine,',');
  // Check that a valid table name was specified
  result := (Pos('*', sTemp) <> 0);
end; // WildcardTable

//***************************************************************************
//
//  FUNCTION    :   GetDBUpgResults
//
//  I/P         :   None
//
//  O/P         :   A string showing the totals of what had been done in
//                      the most recent DB Upgrade operations.
//
//  OPERATION   :
//
//  UPDATED     :   2004/04/10
//
//***************************************************************************
function GetDBUpgResults : String;
begin
  result := 'Tables Created  : ' + IntToStr(iDBUC_NewTables) + #13 +
            'Fields Updated  : ' + IntToStr(iDBUC_FieldsUpdated) + #13 +
            'Indexes Updated : ' + IntToStr(iDBUC_IndexesUpdated) + #13 +
            'Errors          : ' + IntToStr(iDBUC_Errors);
end; // GetDBUpgResults

//***************************************************************************
//
//  FUNCTION    :   WriteToDBUpgLog
//
//  I/P         :   sLogLine - The line to be stored in the log file
//
//                      bUseUpgradeLog - TRUE if logging is to be carried out
//
//  O/P         :   OK
//
//  OPERATION   :   Writes a line to the text upgrade log file.
//
//  UPDATED     :   2004/04/10
//
//***************************************************************************
procedure WriteToDBUpgLog (sLogLine : string);
begin
  if (bUseUpgradeLog) then
  begin
    {$I-}
    Append(tfOutput);
    {$I+}
    if (IOResult = 0) then
    begin
      Writeln(tfOutput,sLogLine);
      Flush(tfOutput);
      CloseFile(tfOutput);
    end; // if
  end; // if
end; // WriteToDBUpgLog

//***************************************************************************
//
//  FUNCTION    :   GetProgramTitle
//
//  I/P         :   None.
//
//  O/P         :   Returns the title of the program
//
//  OPERATION   :
//
//  UPDATED     :   2004/09/23
//
//***************************************************************************
function GetProgramTitle : String;
begin
  result := UpperCase(mifDBUC_DBDefn.ReadString('Target','Title',''));
end; // GetProgramTitle

//***************************************************************************
//
//  FUNCTION    :   StartDBUtils
//
//  I/P         :   bLog - TRUE if logging of the operation is to take place
//
//  O/P         :
//
//  OPERATION   :   Initialises counters and log file.
//
//  UPDATED     :   2004/03/10
//
//***************************************************************************
procedure StartDBUtils(bLog : boolean;
                       bClearLog : boolean);
begin
  if (bLog) then
  begin
    // Create an new Database Upgrade operations log file
    AssignFile(tfOutput,GetTempFolder + 'Upgrade.Log');
{$I-}
    if ((bClearLog) or
        (not FileExists(GetTempFolder + 'Upgrade.Log'))) then
      Rewrite(tfOutput)
    else
      Append(tfOutput);
{$I+}
    if (IOResult = 0) then
      CloseFile(tfOutput);
    // Indicate whether we should be logging operations
    bUseUpgradeLog := TRUE;
  end // if
  else
    bUseUpgradeLog := FALSE;

  // Initially no changes have been made
  iDBUC_IndexesUpdated := 0;
  iDBUC_FieldsUpdated := 0;
  iDBUC_NewTables := 0;
  iDBUC_Errors := 0;
  // Initially no errors have been detected
  iDBUC_DBUpgErr := ERR_DB_NONE;
  sDBUC_DBUpgResult := '';
  // Initially, no session or password specified
  sDBUC_Session := '';
  sDBUC_Password := '';
end; // StartDBUtils

//***************************************************************************
//
//  FUNCTION  : AccessedDBDefinitionResources
//
//  I/P       : None
//
//  O/P       : iTablesInDB (integer) - Number of tables in the database
//
//  OPERATION : Check that all of the resources that are required for
//              the database management are available.
//
//              Load the main database definition resource.
//
//  UPDATED   : 2018-09-17
//
//***************************************************************************
function AccessedDBDefinitionResources : boolean;
var
  n : Integer;
  sLine : String;
  sTableDefResource : String;
  rsDBDefn : TResourceStream;
  slDBDefn : TStringList;

begin
  // Assume that all information is available for defining/upgrading the database
  result := TRUE;

  rsDBDefn := TResourceStream.Create(HInstance, DB_UPG_RESOURCE, RT_RCDATA);
  try
    slDBDefn := TStringList.Create;
    try
      slDBDefn.LoadFromStream(rsDBDefn);
      mifDBUC_DBDefn.SetStrings(slDBDefn);
    finally
      slDBDefn.Free;
    end;
  finally
    rsDBDefn.Free;
  end;

  // Get the file name of the database (only applicable to Absolute databases)
  sDBUC_DBFileName := mifDBUC_DBDefn.ReadString('Target','DBName','');

  // Get the number of tables that are defined in this operation
  iDBUC_iTablesInDB := GetTablesCount;

  WriteToDBUpgLog('Database contains ' + IntToStr(iDBUC_iTablesInDB) + ' table definitions');
  // We expect one definition resource for each table.
  // Check that all these definition files exist.
  for n := 1 to iDBUC_iTablesInDB do
  begin
    sLine := mifDBUC_DBDefn.ReadString('Tables',IntToStr(n),'');
    // Table resource info line may have csv fields after the resource name
    sTableDefResource := UpperCase(ExtractAndTrim(sLine,','));
    sTableDefResource := SearchAndReplace(sTableDefResource, '*', '');
    if (FindResource(hInstance, PChar(sTableDefResource), RT_RCDATA) <> 0) then
    begin
      WriteToDBUpgLog('Resource ' + sTableDefResource + ' not found');
      result := FALSE;
      break;
    end; // if
  end; // for
end; // AccessedDBDefinitionResources

//***************************************************************************
//
//  FUNCTION  : CloseOpenDataSets
//
//  I/P       : dmData : TDataModule - The TDataModule holding the datasets.
//
//              AlsoCloseMemoryDataSets : Boolean - TRUE if these should also
//                be closed (valid for TDBISAMDataSets only)
//
//  O/P       : None
//
//  OPERATION : Close all DataSets (i.e. Tables and Queries), optionally
//              leaving MEMORY tables open.
//
//  UPDATED   : 2015-11-10
//
//***************************************************************************
procedure CloseOpenDataSets(dmData : TDataModule;
                            AlsoCloseMemoryDataSets : boolean);
var
  n : Integer;

begin
  for n:=0 to dmData.ComponentCount-1 do
  begin
    if (dmData.Components[n] is TDBISAMDataSet) then
    begin
      if (((dmData.Components[n] is TDBISAMTable) and
           (((dmData.Components[n] as TDBISAMTable).DatabaseName <> 'MEMORY') or
            (AlsoCloseMemoryDataSets))) or
          (dmData.Components[n] is TDBISAMQuery)) then
        (dmData.Components[n] as TDBISAMDataSet).Close;
    end
    else
      if (dmData.Components[n] is TDataSet) then
        (dmData.Components[n] as TDataSet).Close
  end; // for
end; // CloseOpenDataSets

//***************************************************************************
//
//  FUNCTION  : GotLatestVersion
//
//  I/P       :
//
//  O/P       : Boolean -
//
//  OPERATION : Gets the version number of the Latest table definition.
//
//  UPDATED   : 2016-09-29
//
//***************************************************************************
function GotLatestVersion : boolean;
var
  slFieldNos : TStringList;
  slFieldInfo : TStringList;
  i : Integer;

begin
  result := FALSE;
  sDBUC_VerLatest := '';

  // Create the storage space and read in the list of fields in this table.
  slFieldNos := TStringList.Create;
  slFieldInfo := TStringList.Create;   //
  mifDBUC_TableDefn.ReadSection('1.LatestFields',slFieldNos);
  mifDBUC_TableDefn.ReadSectionValues('1.LatestFields',slFieldInfo);

  if (slFieldNos.Count >= 2) then
  begin
    i := Pos(',',slFieldInfo.Values[slFieldNos.Strings[1]])-1;
    if (i=4) then
    begin
      sDBUC_VerLatest := LeftStr(slFieldInfo.Values[slFieldNos.Strings[1]],i);
      result := TRUE;
    end;
  end;
  // Free up the space used by these variables
  slFieldNos.Free;
  slFieldInfo.Free;
end;

//***************************************************************************
//
//  FUNCTION  : VersionUpgradable
//
//  I/P       : sTableDescriptive : String - The descriptive name of the table.
//
//              verSource : String - The version of the table being investigated.
//
//  O/P       : Boolean - TRUE if we can deal with this table
//
//  OPERATION : Checks that the table being upgraded is the same or earlier
//              in version than the latest expected version.
//
//  UPDATED   : 2016-09-29
//
//***************************************************************************
function VersionUpgradable(sTableDescriptive : String;
                           verSource : String) : boolean;
begin
  result := TRUE;
  if (verSource > sDBUC_VerLatest) then
  begin
    result := FALSE;
    iDBUC_DBUpgErr := ERR_DB_NEWER;
    sDBUC_DBUpgResult := 'Table : ' + sTableDescriptive + #$D +
                         'The table version is newer than expected.';
  end; // if
end; // VersionUpgradable

//***************************************************************************
//
//  FUNCTION  : TableFieldDefnsOK
//
//  I/P       : sTableVer - The version number (or 'Latest') to be
//                tested.
//
//  O/P       : (boolean) - TRUE if the field definition information
//                for the table is correct.
//
//  OPERATION : Checks that the field definitions for a given table
//              (as detailed in mifDBUC_TableDefn file) are OK
//              i.e. Sequential and containing suitable descriptions.
//
//  UPDATED   : 2016-09-29
//
//***************************************************************************
function TableFieldDefnsOK(sTableVer : String) : Boolean;
var
  n : Integer;
  slFieldNos : TStringList;
  slFieldInfo : TStringList;
  sFieldDefnLine : String;        // The line of comma-separated data defining a field
  sFieldName : String;
  ftFieldDataType : TFieldType;
  uiFieldSize : Word;
  iSourceFNo : Integer;
  dummy : Integer;

begin
  // Initially assume all is OK
  result := TRUE;

  // Create the storage space and read in the list of fields in this table.
  slFieldNos := TStringList.Create;
  try
    slFieldInfo := TStringList.Create;
    try
      mifDBUC_TableDefn.ReadSection('1.' + sTableVer + 'Fields',slFieldNos);
      mifDBUC_TableDefn.ReadSectionValues('1.' + sTableVer + 'Fields',slFieldInfo);

      if (slFieldNos.Count > 0) then
        // Check that field numbers are valid and sequentially numbered
        for n := 0 to slFieldNos.Count-1 do
        begin
          Val(slFieldNos.Strings[n],iSourceFNo,dummy);
          if (dummy<>0) or (iSourceFNo<>n) then
          begin
            result := FALSE;
            iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
            sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + sTableVer + ')' + #13 +
                                 'Field identifier ' + IntToStr(n) + ' is non-sequential or invalid.';
            Break;
          end; // if
        end // for
      else
      begin
        result := FALSE;
        iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
        sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + sTableVer + ')' + #13 +
                             'No fields defined.';
      end; // else

      // Do not proceed if the fields are not nmumbered correctly
      if (result) then
      begin
        // Check each of the fields
        for n := 0 to slFieldNos.Count-1 do
        begin
          sFieldDefnLine := slFieldInfo.Values[slFieldNos.Strings[n]];
          // There must be 3 or more commas in the field definition line
          // format = FieldName,Type,Size,Required[,Description]
          if (Count_Chars(sFieldDefnLine,',') < 3) then
          begin
            iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
            sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + sTableVer + ')' + #13 +
                                 'Field definition ' + IntToStr(n) + ' is invalid.';
            result := FALSE;
            break;
          end // if
          else
          begin
            // The format of the info given appears correct.
            // Check the field name is valid
            // (DBISAM has a max name length of 30 characters)
            sFieldName := ExtractAndTrim(sFieldDefnLine,',');
            if ((Length(sFieldName) > 30) or (Length(sFieldName) = 0)) then
            begin
              iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
              sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + sTableVer + ')' + #13 +
                                   'Field name ' + IntToStr(n) + ' is invalid.';
              result := FALSE;
              break;
            end; // if

            // Get the field definition
            ftFieldDataType := GetANSFieldDataType(sFieldDefnLine[1]);
            ExtractAndTrim(sFieldDefnLine,',');
            if (ftFieldDataType = ftUnknown) then
            begin
              result := FALSE;
              iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
              sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + sTableVer + ')' + #13 +
                                   'Field type in definition ' + IntToStr(n) + ' is invalid.';
              break;
            end; // default

            // Check field size
            try
              uiFieldSize := StrToInt(ExtractAndTrim(sFieldDefnLine,','));
              if (((ftFieldDataType = ftString) or
    //??               (ftFieldDataType = ftMemo) or  //!! Does a ftMemo have a non-zero fied size in DBISAM?
                   (ftFieldDataType = ftBytes)) and
                  (uiFieldSize = 0)) then
              begin
                result := FALSE;
                iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
                sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + sTableVer + ')' + #13 +
                                     'Field size in definition ' + IntToStr(n) + ' is zero.';
                break;
              end;// if
            except
              result := FALSE;
              iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
              sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + sTableVer + ')' + #13 +
                                   'Field size in definition ' + IntToStr(n) + ' is not number.';
              break;
            end; // except
            // Ignore Field Required and Description field
          end; // else
        end; // for
      end; // if

      // Log progress
      if (result) then
        WriteToDBUpgLog('Field Definitions for ' + sTableVer + ' OK')
      else
        WriteToDBUpgLog('Field Definitions for ' + sTableVer + 'not OK!');

    finally
      slFieldInfo.Free;
    end; // finally
  finally
    slFieldNos.Free;
  end; // finally
end; // TableFieldDefnsOK

//***************************************************************************
//
//  FUNCTION  : LatestIndexDefnsOK
//
//  I/P       : None
//
//  O/P       : Boolean - TRUE if the index definition information
//                is valid.
//
//  OPERATION : Checks that the index definitions for a given table
//              are OK i.e. Sequential and anything else that can
//              be checked.
//
//              I do not test whether the fields that are listed in
//              each index actually match those in the latest table
//              field definitions.   That is a bit difficult for now.
//
//  UPDATED   : 2016-06-17
//
//***************************************************************************
function LatestIndexDefnsOK : Boolean;
var
  n : Integer;
  slIndexNos : TStringList;
  slIndexInfo : TStringList;
  sIndexName : String;
  sIndexFields : String;
  setIndexOptions : TIndexOptions;
  iSourceINo : Integer;
  dummy : Integer;

begin
  // Assume that the indexes in the table match the indicated latest index descriptions
  result := TRUE;

  slIndexNos := TStringList.Create;    // Create the storage space and read in the
  slIndexInfo := TStringList.Create;   // list of fields in this table.
  mifDBUC_TableDefn.ReadSection('1.LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',slIndexInfo);

  // Check that index numbers are valid and sequentially numbered
  for n := 0 to slIndexNos.Count-1 do
  begin
    Val(slIndexNos.Strings[n],iSourceINo,dummy);
    if (dummy<>0) or (iSourceINo<>n+1) then
    begin
      result := FALSE;
      iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
      sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (Latest)' + #$D +
                           'Index identifier ' + IntToStr(n) + ' is non-sequential or invalid.';
    end; // if
  end; // for

  // Cycle through each defined index
  n := 0;
  while ((n<slIndexNos.Count) and (result)) do
  begin
    result := GotIndexInfo(slIndexInfo.Values[slIndexNos.Strings[n]],
                           sIndexName,sIndexFields,setIndexOptions);
    // Check that the first index is the primary index
    // Even though DBISAM creates a primary index based on RecordID, I have decided to
    // make this a required LatestIndexes entry.   That way, when counting indexes as
    // part of the table validity checks, we come up with the correct number of indexes
    // (and not 1 more than we expect.)
    if ((n = 0) and (not(ixPrimary in setIndexOptions))) then
      begin
        result := FALSE;
        iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
        sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (Latest)' + #$D +
                        'Index identifier 0 is not the primary index.';
      end; // if
    Inc(n);
  end; // for

  // Log progress
  if (result) then
    WriteToDBUpgLog('Index Definitions for Latest OK')
  else
    WriteToDBUpgLog('Index Definitions for Latest not OK!');

  // Free up the space used by these variables
  slIndexNos.Free;
  slIndexInfo.Free;
end; // LatestIndexDefnsOK

//***************************************************************************
//
//  FUNCTION  : SetLanguage
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/02/23
//
//***************************************************************************
procedure SetLanguage(lcMain : TDKLanguageController);
begin
  lcDBUtils := lcMain;
  if (lcMain <> nil) then
    try
      sDBUC_AgentHelp := LangManager.ConstantValue['sAgentHelp'];
    except
    end; // except
end;


//***************************************************************************
initialization
begin
  lcDBUtils := nil;
  mifDBUC_DBDefn := TMemIniFile.Create(DB_UPG_FILE);
  mifDBUC_TableDefn := TMemIniFile.Create(TB_UPG_FILE);
  sDBUC_AgentHelp := 'Please contact the software supplier for further information or assistance.';
end;


//***************************************************************************
finalization
begin
  mifDBUC_TableDefn.Free;
  mifDBUC_DBDefn.Free;
  rifApplicationKey.Free;
end;

end.

