unit DBUtilsAbsolute;

//***************************************************************************
//
// DESCRIPTION:
//  Utilities to handle databases, tables, creation and conversion from one
//  table structure to another.
//
// TO BE DONE:
//
//  * Complete the change of all routines to the multiple DB Definition
//      Files operation.
//
// VERSIONS:
//
//    Update Date : 2009-08-07
//    Changes Made :
//      * Remove the 64Kb limit on .in file size.
//
//    Update Date : 2009-05-20
//    Changes Made :
//      * GetApplicationDataDirectory returns an empty string (instead of '\')
//        if it is not available.
//
//    Update Date : 2008-06-12
//    Changes Made :
//      * Field definition lines can hold a description in the last field.
//
//    Update Date : 2008/04/07
//    Changes Made :
//      * Overload on CheckDatabaseValidity
//
//    Update Date : 2007/07/23
//    Changes Made :
//      * Various items to match with DBIUtils, and provide a common, multi-
//        language (work still needed in this unit) upgrade application.
//
//    Update Date : 2007/06/25
//    Changes Made :
//      * RecordAccessMessage now works on a DataSet and not on a Table
//
//    Update Date : 2006/02/07
//    Changes Made :
//      * Fixed the table identifiers in the warning messages in CheckDatabaseValidity
//      * Took out case sensitivity when checking field names in CheckDatabaseValidity and
//        in SourceTableFieldsMatch
//
//    Update Date : 2006/01/24
//    Changes Made :
//      * Added LocalShareIsTrue
//
//    Update Date : 2005/11/16
//    Changes Made :
//      * Make change for removal of faANSReadOnly attribute from File_Ops
//
//    Update Date : 2005/11/10
//    Changes Made :
//      * Fix number given when warning of an out-of-sequence field in TableFieldDefnsOK
//
//    Update Date : 2005/10/11
//    Changes Made :
//      * Added SealTable
//
//    Update Date : 2005/06/03
//    Changes Made :
//      * Look in 'Pick List'/'1' key before 'Files'/'DataLocn' key for
//        the database location.
//
//    Update Date : 2005/05/27
//    Changes Made :
//      * Add Flush to log file outputs, to ensure file is correctly written.
//
//    Update Date : 2005/04/12
//    Changes Made :
//      * Fix bug in SourceTableFieldsMatch
//      * GotTableInformationFromIndex was a function which was always Ok
//        (i.e. no FALSE return.)   Changed it to procedure GetTableInformationFromIndex.
//
//    Update Date : 2005/03/07
//    Changes Made :
//      * Added RecordAccessMessage, to check whether a record may be modified, or
//          whether it is being edited by another network user.
//
//    Update Date : 2005/03/03
//    Changes Made :
//      * Correct the extraction/creation of each table file name in CheckDatabaseFiles.
//      * Create tSource and tDestination during initialization instead of
//          in StartDBUtils.
//
//    Update Date : 2005/02/23
//    Changes Made :
//      * Removed EndDBUtils procedure.   Added its functionality to
//          finalization only.
//
//    Update Date : 2005/01/12
//    Changes Made :
//      * Added this header
//
//***************************************************************************

interface

{$A-}

uses StdCtrls, COMCtrls, Forms, Classes, DKLang, ABSMain;

const
  ABS_DB_EXTENSION = '.ABS';

procedure SealTable(tTableToSeal : TABSTable); overload;
(*
procedure TransferRecord(tRecSource : TTable;
                         tRecDestination : TTable;
                         slMapInfo : TStringList);
procedure StartDBUtils(bLog : boolean;
                       bClearLog : boolean);
function GetProgramTitle : string;
function GetApplicationDataDirectory : string;
*)
procedure UpgradeDatabase(sDBDirectory : string;
                          lProgressMessage : TLabel;
                          pbTableContents : TProgressBar;
                          pbTableIndexes : TProgressBar;
                          pbDatabaseProgress : TProgressBar;
                          bRestart : boolean;
                          const pw : String = '');
(*
procedure RecreateDatabaseIndexes(sDBDirectory : string;
                                  lProgressMessage : TLabel;
                                  pbTableIndexes : TProgressBar;
                                  pbDatabaseProgress : TProgressBar);
procedure RefreshOpenTables(dmData : TDataModule);
procedure CloseOpenTablesAndQueries(dmData : TDataModule);
procedure TestMapSection (sMapSection : string;
                          tTargetTable : TTable);
*)
procedure CheckDatabaseFiles(sTestDir : string);
procedure CheckDatabaseValidity(sTestDir : String;
                                const pw : String = '');
(*
function RecordAccessMessage(dsTarget : TDataSet) : string; overload;
function RecordAccessMessage(dsTarget : TDBISAMDataSet) : string; overload;
procedure SetLanguage(lcMain : TDKLanguageController);

function Got_Map_Section (tDestn : TTable;
                          tSource : TTable;
                          var sMapSection : string) : integer;
function DBError_Message(iErrorNo : integer) : string;
function Get_Upgrade_Index(tablename : string;
                           var uiUpgradeIndex : word) : integer;
function Transfer_Field_Contents(tSource : TTable;
                                 tDestination : TTable;
                                 field_map : string;
                                 dest_fno : integer) : integer;
function Get_Old_Index(tCurrent : TTable;
                       iCurrentFIndex : integer;
                       tOld : TTable) : integer;
*)

implementation

uses DB, Controls, SysUtils, Dialogs, System.StrUtils,
     DBUtilsCommon,
     Str_Ops, TimeDate, File_Ops, Dialog_Ops;


const
  TEMP_TABLE_NAME = '~TMP~TBL';         // Temporary root of table file name (MUST be unused elsewhere)
  WORK_DATABASE_NAME = 'TESTING1234';

var
(*  lcDBUtils : TDKLanguageController;
  sDBCtrlDir : string;              // Directory of the database definition file
  iTablesInDB : integer;            // The number of tables defined in the database
  tfOutput : TextFile;              // Used to log the progress
  iIndexesUpdated : integer;        // Counts the number of tables which had their indexes updated
  iFieldsUpdated : integer;         // Counts the number of tables which had their fileds updated
  iNewTables : integer;             // Counts the number of new tables created
  iErrors : integer;                // Counts of the number of errors encountered
*)
  sTableTitle : string;             // A descriptive title of the table currently being upgraded
  sSourceVer : string;              // Source table version number
  dbTest : TAbsDatabase;            // The database to be tested/upgraded
  tSource : TAbsTable;              // The original Absolute table, that is to be upgraded
  tDestination : TAbsTable;         // The target Absolute table, used to create new or updated tables
  bNewTable : boolean;              // TRUE if there is no exsiting table, and it must be created.
(*
  bUseUpgradeLog : boolean;         // TRUE if we are to use the log file for recording operations
  sTableType : string;              // Indicates the type of the table (Paradox, DBISAM)
*)
//***************************************************************************
//
//  FUNCTION  : SealTable
//
//  I/P       :  tTableToSeal (TABSTable) - The table, the contents of which
//                 must be sealed.
//
//  O/P       : None.
//
//  OPERATION : Opens and Closes the given table, returning to the record
//              that was initially active.
//
//              This function assumes that the primary key is based on the
//              first field, and can be expressed as a string.
//
//  UPDATED   : 2010-10-03
//
//***************************************************************************
procedure SealTable(tTableToSeal : TABSTable); overload;
var
  sKeyFieldValue : string;
  sIndex : string;

begin
  // Store the current record and the index, so that we can move back to it
  sKeyFieldValue := tTableToSeal.Fields[0].AsString;
  sIndex := tTableToSeal.IndexName;
  // This Close/Open operation ensures that the changes are written to disk.
  // Maybe this must be changed to another method!!
  tTableToSeal.Close;
  tTableToSeal.Open;

  // Check if there was an AfterScroll event (which I often use to organise filtered
  // data in detail tables), and execute it if required
  if (Assigned(tTableToSeal.AfterScroll)) then
    tTableToSeal.AfterScroll(nil);

  // Go back to the record that was current before the table open/close operation.
  tTableToSeal.IndexName := '_Key';
  tTableToSeal.SetKey;
  tTableToSeal.Fields[0].AsString := sKeyFieldValue;
  tTableToSeal.GotoKey;
  tTableToSeal.IndexName := sIndex;
end; // SealTable

//***************************************************************************
//
//  FUNCTION    :   SourceTableFieldsMatch
//
//  I/P         :   sCompareAgainst - The table description/version against
//                        which the comparison must be made
//
//  O/P         :   (boolean) - TRUE if the original and indicated table
//                        are the same
//
//  OPERATION   :   Check whether there is any difference between the
//                      fields of the existing table and the fields as defined
//                      in the indicated section of the definition file.
//
//  UPDATED     :   2003/08/29
//
//***************************************************************************
function SourceTableFieldsMatch(sCompareAgainst : string) : boolean;
var
  n : integer;
  field_nos : TStringList;
  field_info : TStringList;
  field_line : string;            // The ini's line of field information
  field_name : string;            // Used for Add methog, when adding fields
  ftFieldDataType : TFieldType;   // Used for Add methog, when adding fields
  field_size : word;              // Used for Add methog, when adding fields
  field_required : boolean;       // Used for Add methog, when adding fields
begin
  // Assume that the table matches the indicated description
  result := TRUE;

  // Create the storage space and read in the list of fields in this table.
  field_nos := TStringList.Create;
  field_info := TStringList.Create;
  mifDBUC_TableDefn.ReadSection(sCompareAgainst + 'Fields',field_nos);
  mifDBUC_TableDefn.ReadSectionValues(sCompareAgainst + 'Fields',field_info);

  // Check the table
  // Ensure that there are the correct number of fields
  if (tSource.FieldDefs.Count<>field_nos.Count) then
  begin
    result := FALSE;
    sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
                         'Field Count: Source has ' + IntToStr(tSource.FieldDefs.Count) +
                         ', Expected = ' + IntToStr(field_nos.Count) +
                         #13 +
                         sDBUC_AgentHelp;
  end // if
  else
  begin
    // Scan through all the fields
    n := 0;
    while (n < tSource.FieldDefs.Count-1) and (result) do
    begin
      field_line := field_info.Values[field_nos.Strings[n]];
      // Format of info given appears correct
      field_name := LeftStr(field_line,Pos(',',field_line)-1);

      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      ftFieldDataType := GetANSFieldDataType(field_line[1]);

      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      if ((ftFieldDataType = ftString) or
          (ftFieldDataType = ftWideString) or
          (ftFieldDataType = ftMemo) or
          (ftFieldDataType = ftBytes)) then
        field_size := StrToInt(LeftStr(field_line,Pos(',',field_line)-1))
      else
        field_size := 0;

      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      field_required := (field_line[1]='1');

      // Check if there was an error in the field definition
      if (UpperCase(tSource.FieldDefs.Items[n].Name) <> UpperCase(field_name)) or
         (tSource.FieldDefs.Items[n].DataType <> ftFieldDataType) or
         (tSource.FieldDefs.Items[n].Size <> field_size) or
         (tSource.FieldDefs.Items[n].Required <> field_required) then
      begin
        result := FALSE;    // Inform user of where and what the error is.
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
                             sCompareAgainst + ' field ' + IntToStr(n) + ' - ';
        if (UpperCase(tSource.FieldDefs.Items[n].Name) <> UpperCase(field_name)) then
          sDBUC_DBUpgResult := sDBUC_DBUpgResult + 'Name: Original = ' + tSource.FieldDefs.Items[n].Name +
                               ', Expected = ' + field_name + #13 + sDBUC_AgentHelp
        else
          if (tSource.FieldDefs.Items[n].DataType <> ftFieldDataType) then
            sDBUC_DBUpgResult := sDBUC_DBUpgResult + 'Type: Original = ' + GetFieldTypeName(tSource.FieldDefs.Items[n].DataType,1) +
                                 ', Expected = ' + GetFieldTypeName(ftFieldDataType,1) + #13 + sDBUC_AgentHelp
          else
            if (tSource.FieldDefs.Items[n].Size <> field_size) then
              sDBUC_DBUpgResult := sDBUC_DBUpgResult + 'Size: Original = ' + IntToStr(tSource.FieldDefs.Items[n].Size) +
                                   ', Expected = ' + IntToStr(field_size) + #13 + sDBUC_AgentHelp
            else
              sDBUC_DBUpgResult := sDBUC_DBUpgResult + 'Required: Original = ' + IntToStr(integer(tSource.FieldDefs.Items[n].Required)) +
                                   ', Expected = ' + IntToStr(integer(field_required)) + #13 + sDBUC_AgentHelp;
      end; // if
      Inc(n);
    end; // while
  end; // else

// Log progress
  if (result) then
    WriteToDBUpgLog('Source Table Field Definitions match ' + sCompareAgainst)
  else
    WriteToDBUpgLog('Source Table Field Definitions do not match ' + sCompareAgainst);

// Free up the space used by these variables
  field_nos.Free;
  field_info.Free;
end; // SourceTableFieldsMatch

//***************************************************************************
//
//  FUNCTION  : AccessedSourceTable
//
//  I/P       : sTableFielname - The full file name of the table that
//                we are wanting to upgrade.
//
//  O/P       : boolean - TRUE if we accessed and opened the table
//
//              bNewTable - TRUE if a new table must be created.
//
//  OPERATION : Checks the given file name of the table, and whether
//              it exists and is accessable for upgrading.
//              descriptions.
//
//  UPDATED   : 2010-10-12
//
//***************************************************************************
function AccessedSourceTable : boolean;
begin
  // Assume that we will be able to access the table
  result := TRUE;
  // Check that the current table file name is valid
  if (sDBUC_TableFilename = '') then
  begin
    sDBUC_DBUpgResult := 'Table : ' + sTableTitle + #$D +
                         'An invalid table, "' + sDBUC_TableFilename + '" has been specified.' + #$D +
                         'This table has not been upgraded.' +
                         #13 +
                         sDBUC_AgentHelp;
    result := FALSE;
  end // if
  else
  begin
    // Check whether the table exists in the database
    if (dbTest.TableExists(sDBUC_TableFilename)) then
    begin
      // The table file exists, so try to access it exclusively
      try
        tSource.Close;
        tSource.TableName := sDBUC_TableFilename;
        // Get exclusive access, to prevent anyone else altering contents
//!!        tSource.Exclusive := TRUE;
        tSource.Open;
        // Flag that it is not necessary to create a new table
        bNewTable := FALSE;
      except
        on E:Exception do
        begin
          result := FALSE;              // We could not obtain exclusive access to this table
          sDBUC_DBUpgResult := 'Table : ' + sTableTitle + #$D +
                               'Unable to gain exclusive access for upgrading of this table.' + #$D +
                               '(Error message "' + E.Message + '")' + #13 +
                               'Ensure that the database/table is not currently being accessed by another program or network user.';
        end; // do
      end; // except
    end // if
    else
    begin
// Flag that a new table must be created
      bNewTable := TRUE;
      WriteToDBUpgLog('Table does not exist');
    end; // else
  end; // else
end; // AccessedSourceTable

//***************************************************************************
//
//  FUNCTION  : GotSourceVersion
//
//  I/P       : tSource (TTable) - The source table.
//
//  O/P       : (boolean) - TRUE if the original and desired table
//                differ in any way
//
//                      sSourceVer - The version of the tSource table.
//
//  OPERATION : Attempt to extract the Source Table's version from
//                      Field 1.
//
//  UPDATED   : 2003/08/29
//
//***************************************************************************
function GotSourceVersion : boolean;
var
  first_ver : word;               // Used to identify the first version that we can upgrade
begin
// Read in the source table's version number (from Field 1)
  if (tSource.FieldDefs.Count>1) then
    sSourceVer := UpperCase(tSource.FieldDefs.Items[1].Name)
  else
    sSourceVer := 'No version';

// Check whether the source table version number is available and is valid
  if ((Length(sSourceVer)<>4) or
      (sSourceVer[1]<>'V')) then
  begin
// The old table's version number was not in the expected place expected place.
    first_ver := 100;
    result := FALSE;
// Start from the first table version on record, and try to find the first version number
// that we have used in the ini file. Search only up to Version 4.00
// The first SHOULD be V1.00.
    while ((first_ver<=400) and (not result)) do
    begin
      sSourceVer := 'V' + IntToStr(first_ver);
      if (mifDBUC_TableDefn.ReadString(sSourceVer + 'Fields','0','')<>'') then
        result := TRUE
      else
        first_ver := first_ver + 1;
    end; // while
  end // if
  else
// The old table's version was in the correct place in the table, so we can go ahead.
    result := TRUE;

// Warn the user if we were not able to find the version number
  if (not result) then
// The version number was not in the original table and no version info has been found in the ini file.
    sDBUC_DBUpgResult := 'Table : ' + sTableTitle + #$D +
                         'Unable to establish the version number, or find version information for this table.' +
                         #13 +
                         sDBUC_AgentHelp
  else
    WriteToDBUpgLog('Table Exists (' + sSourceVer + ')');
end; // GotSourceVersion

//***************************************************************************
//
//  FUNCTION    :   TableFieldDefnsOK
//
//  I/P         :   sTableVer - The version number (or 'Latest') to be
//                          tested.
//
//  O/P         :   (boolean) - TRUE if the field definition information
//                        for the table is correct.
//
//  OPERATION   :   Checks that the field definitions for a given table
//                      are OK i.e. Sequential and containing suitable
//                      descriptions.
//
//  UPDATED     :   2003/09/04
//
//***************************************************************************
function TableFieldDefnsOK(sTableVer : string) : boolean;
var
  n : integer;
  slFieldNos : TStringList;
  slFieldInfo : TStringList;
  sFieldDefnLine : string;        // The line of comma-separated data defining a field
  sFieldName : string;
  ftFieldDataType : TFieldType;
  uiFieldSize : word;
  iSourceFNo : integer;
  dummy : integer;
begin
  result := TRUE;                 // Initially assume all is OK

// Create the storage space and read in the list of fields in this table.
  slFieldNos := TStringList.Create;
  slFieldInfo := TStringList.Create;   //
  mifDBUC_TableDefn.ReadSection(sTableVer + 'Fields',slFieldNos);
  mifDBUC_TableDefn.ReadSectionValues(sTableVer + 'Fields',slFieldInfo);

  if (slFieldNos.Count > 0) then
// Check that field numbers are valid and sequentially numbered
    for n := 0 to slFieldNos.Count-1 do
    begin
      Val(slFieldNos.Strings[n],iSourceFNo,dummy);
      if (dummy<>0) or (iSourceFNo<>n) then
      begin
        result := FALSE;
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                             'Field identifier ' + IntToStr(n) + ' is non-sequential or invalid.' +
                             #13 +
                             sDBUC_AgentHelp;
        Break;
      end; // if
    end // for
  else
  begin
    result := FALSE;
    sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                         'No fields defined.' +
                         #13 +
                         sDBUC_AgentHelp;
  end; // else

// Do not proceed if the fields are not nmumbered correctly
  if (result) then
  begin
// Check each of the fields
    for n := 0 to slFieldNos.Count-1 do
    begin
      sFieldDefnLine := slFieldInfo.Values[slFieldNos.Strings[n]];
      // There must be 3 commas in the field definition line
      if (Count_Chars(sFieldDefnLine,',') < 3) then // Check the format of the line
      begin
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                             'Field definition ' + IntToStr(n) + ' is invalid' +
                             #13 +
                             sDBUC_AgentHelp;
        result := FALSE;
        break;
      end // if
      else
      begin
        // The format of the info given appears correct.
        // Check the field name is valid (Paradox has a max name length of 25 characters)
        sFieldName := ExtractAndTrim(sFieldDefnLine,',');
        if ((Length(sFieldName) > 25) or (Length(sFieldName) = 0)) then
        begin
          sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                               'Name for field ' + IntToStr(n) + ' is invalid' +
                               #13 +
                               sDBUC_AgentHelp;
          result := FALSE;
          break;
        end; // if

        // Get the field definition
        ftFieldDataType := GetANSFieldDataType(sFieldDefnLine[1]);
        ExtractAndTrim(sFieldDefnLine,',');
        if (ftFieldDataType = ftUnknown) then
        begin
          result := FALSE;
          sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                               'Field type in definition ' + IntToStr(n) + ' is invalid' +
                               #13 +
                               sDBUC_AgentHelp;
          break;
        end; // default

        // Check field size
        try
          uiFieldSize := StrToInt(ExtractAndTrim(sFieldDefnLine,','));
          if (((ftFieldDataType = ftString) or
               (ftFieldDataType = ftMemo) or
               (ftFieldDataType = ftBytes)) and
              (uiFieldSize = 0)) then
          begin
            result := FALSE;
            sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                                 'Field size in definition ' + IntToStr(n) + ' is zero' +
                                 #13 +
                                 sDBUC_AgentHelp;
            break;
          end;// if
        except
          result := FALSE;
          sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                               'Field size in definition ' + IntToStr(n) + ' is not number' +
                               #13 +
                               sDBUC_AgentHelp;
          break;
        end; // except
        // Ignore Field Required field
      end; // else
    end; // for
  end; // if

  // Log progress
  if (result) then
    WriteToDBUpgLog('Field Definitions for ' + sTableVer + ' OK')
  else
    WriteToDBUpgLog('Field Definitions for ' + sTableVer + 'not OK!');

// Free up the space used by these variables
  slFieldNos.Free;
  slFieldInfo.Free;
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
function LatestIndexDefnsOK : boolean;
var
  n : integer;
  slIndexNos : TStringList;
  slIndexInfo : TStringList;
  sIndexName : string;
  sIndexFields : string;
  setIndexOptions : TIndexOptions;
  iSourceINo : integer;
  dummy : integer;
begin
// Assume that the indexes in the table match the indicated latest index descriptions
  result := TRUE;

  slIndexNos := TStringList.Create;    // Create the storage space and read in the
  slIndexInfo := TStringList.Create;   // list of fields in this table.
  mifDBUC_TableDefn.ReadSection('LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('LatestIndexes',slIndexInfo);

// Check that index numbers are valid and sequentially numbered
  for n := 0 to slIndexNos.Count-1 do
  begin
    Val(slIndexNos.Strings[n],iSourceINo,dummy);
    if (dummy<>0) or (iSourceINo<>n+1) then
    begin
      result := FALSE;
      sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (Latest)' + #$D +
                      'Index identifier ' + IntToStr(n) + ' is non-sequential or invalid.' +
                      #13 +
                      sDBUC_AgentHelp;
    end; // if
  end; // for

  // Cycle through each defined index
  n := 0;
  while ((n<slIndexNos.Count) and (result)) do
  begin
    result := GotIndexInfo(slIndexInfo.Values[slIndexNos.Strings[n]],
                           sIndexName,sIndexFields,setIndexOptions);
    // Check that the first index is the primary index
    if ((n = 0) and (not(ixPrimary in setIndexOptions))) then
      begin
        result := FALSE;
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (Latest)' + #$D +
                        'Index identifier 0 is not the primary index.' +
                        #13 +
                        sDBUC_AgentHelp;
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
//  FUNCTION    :   CreatedTempTable
//
//  I/P         :   current_table (integer) - The table index in the
//                          upgrade INI file of the table currently being
//                          upgraded.
//
//                      table_title (string) - A descriptive title of the
//                          table currently being upgraded.
//
//                      table_filename (string) - The full path and filename
//                          of the table currently being upgraded.
//
//  O/P         :   (boolean) - TRUE if the temporary table was created.
//
//  OPERATION   :   Creates a temporary table with the fields and indexes
//                      as given in the INI file sections current_table.Fields
//                      and current_table.Indexes.
//
//  UPDATED     :   2005/05/11
//
//***************************************************************************
function CreatedTempTable : boolean;
var
  n : integer;
  field_nos : TStringList;
  field_info : TStringList;
  field_line : string;            // The ini's line of field information
  field_name : string;            // Used for Add methog, when adding fields
  field_datatype : TFieldType;    // Used for Add methog, when adding fields
  field_size : word;              // Used for Add methog, when adding fields
  field_required : boolean;       // Used for Add methog, when adding fields
  index_nos : TStringList;
  index_info : TStringList;
  index_line : string;            // The ini's line of index information
  index_name : string;            // Used for Add methog, when adding indexes
  index_fields : string;          // Used for Add methog, when adding indexes
  index_noptions : integer;       // Used to specify the combined index options
  index_options : TIndexOptions;  // Used for Add methog, when adding indexes
begin

  result := TRUE;                 // Initially assume all is OK

  // Set up the temporary destination file
  index_nos := nil;
  index_info := nil;
  field_nos := nil;
  field_info := nil;

  try
    tDestination.Close;
    tDestination.TableName := TEMP_TABLE_NAME;

    tDestination.FieldDefs.Clear;            // Clear any fields and indexes in this new table
    tDestination.IndexDefs.Clear;

    field_nos := TStringList.Create;    // Create the storage space and read in the
    field_info := TStringList.Create;   // list of fields in this table.
    mifDBUC_TableDefn.ReadSection('LatestFields',field_nos);
    mifDBUC_TableDefn.ReadSectionValues('LatestFields',field_info);

    // Add each of the fields
    for n := 0 to field_nos.Count-1 do
    begin
      field_line := field_info.Values[field_nos.Strings[n]];
      // Format of info given appears correct
      field_name := LeftStr(field_line,Pos(',',field_line)-1);

      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      field_datatype := GetANSFieldDataType(field_line[1]);

      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      if ((field_datatype = ftString) or
          (field_datatype = ftWideString) or
          (field_datatype = ftMemo) or
          (field_datatype = ftWideMemo) or
          (field_datatype = ftBytes)) then
          field_size := StrToInt(LeftStr(field_line,Pos(',',field_line)-1))
      else
          field_size := 0;

      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      field_required := (field_line[1]='1');

      tDestination.FieldDefs.Add(field_name,field_datatype,field_size,field_required);
    end; // for

    index_nos := TStringList.Create;    // Create the storage space and read in the
    index_info := TStringList.Create;   // list of fields in this table.
    mifDBUC_TableDefn.ReadSection('LatestIndexes',index_nos);
    mifDBUC_TableDefn.ReadSectionValues('LatestIndexes',index_info);

    // Add each of the indexes
    for n := 0 to index_nos.Count-1 do
    begin
      index_line := index_info.Values[index_nos.Strings[n]];
      index_name := LeftStr(index_line,Pos(',',index_line)-1);

      index_line := Copy(index_line,Pos(',',index_line)+1,255);
      index_fields := LeftStr(index_line,Pos(',',index_line)-1);

      index_line := Copy(index_line,Pos(',',index_line)+1,255);
      index_noptions := StrToInt(index_line);
      index_options := [];
      if ((index_noptions AND $10)=$10) then
        index_options := index_options + [ixPrimary];
      if ((index_noptions AND $08)=$08) then
        index_options := index_options + [ixUnique];
      if ((index_noptions AND $04)=$04) then
        index_options := index_options + [ixDescending];
      if ((index_noptions AND $02)=$02) then
        index_options := index_options + [ixNonMaintained];
      if ((index_noptions AND $01)=$01) then
        index_options := index_options + [ixCaseInsensitive];

      tDestination.IndexDefs.Add(index_name,index_fields,index_options);
    end; // for
    // Make the table
    tDestination.CreateTable;
    tDestination.Close;

    WriteToDBUpgLog('Temporary upgrade table created');
  except
    on E:EDatabaseError do
    begin
      result := FALSE;
      WriteToDBUpgLog('Error creating temporary table : "' + E.Message + '"');
      sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
                      'Unable to create a temporary upgrade table.' + #$D +
                      'This table has not been upgraded.' + #$D + #$D +
                      '(Error Description : ' + E.Message + ')' + #$D +
                      #13 +
                      sDBUC_AgentHelp;
    end; // on
  end; // except

  // Free up the space used by these variables
  index_nos.Free;
  index_info.Free;
  field_nos.Free;
  field_info.Free;

end; // CreatedTempTable

//***************************************************************************
//
//  FUNCTION    :   TransferredFieldContents
//
//  I/P         :   sFieldMap (string) - The details of what to put
//                        into the field in the destination table.
//
//                  iDestnFieldNo (integer) - The destination field that is
//                        being filled in.
//
//  O/P         :   sDBUpgResult (string) - Empty string if the operation
//                        was performed correctly.   Error message if not.
//
//  OPERATION   :   Given the source and destination tables, the
//                      mapping and destination field number, transfer the
//                      source field value or the default given value into
//                      the destination field.
//
//  UPDATED     :   2004/09/20
//
//***************************************************************************
procedure TransferField(sFieldMap : string;
                        iDestFieldNo : integer);
var
  iSourceFieldNo : integer;             // Field number to be used from source file
  dummy : integer;                      // Used in string to int conversions
  def_int : integer;                    // Default integer value for a field
  def_real : real;                      // Default real value for a field
  def_string : string;                  // Default string value for a field
begin

  // Test for whether the source data has a value (either a default or from the source field)
  if (sFieldMap<>'') then
  begin
    // Check whether the source data froms from a field in the source table
    if (LeftStr(sFieldMap,2)='fn') then
    begin
      // Extract the source field number
      Val(Copy(sFieldMap,3,255),iSourceFieldNo,dummy);
      // Leave destn alone if source field is Null
      if (not tSource.Fields[iSourceFieldNo].IsNull) then
        case tDestination.FieldDefs[iDestFieldNo].DataType of

          ftString,
          ftWideString :
            tDestination.Fields[iDestFieldNo].AsString := tSource.Fields[iSourceFieldNo].AsString;

          ftSmallint ,
          ftInteger ,
          ftWord,
          ftAutoInc :
            tDestination.Fields[iDestFieldNo].AsInteger := tSource.Fields[iSourceFieldNo].AsInteger;

          ftBoolean :
            tDestination.Fields[iDestFieldNo].AsBoolean := tSource.Fields[iSourceFieldNo].AsBoolean;

          ftFloat ,
          ftCurrency ,
          ftBCD :
            tDestination.Fields[iDestFieldNo].AsFloat := tSource.Fields[iSourceFieldNo].AsFloat;

          ftDate,
          ftTime,
          ftDateTime :
            tDestination.Fields[iDestFieldNo].AsDateTime := tSource.Fields[iSourceFieldNo].AsDateTime;

          else
            tDestination.Fields[iDestFieldNo].Assign(tSource.Fields[iSourceFieldNo]);
        end; // case
    end // if
    else
    begin
      // Test if the default value for this field is a string
      if (sFieldMap[1]='"') then
      begin
        // Extract the string, clipping off the single quotes
        def_string := Copy(sFieldMap,2,255);
        def_string := LeftStr(def_string,Length(def_string)-1);
        case tDestination.FieldDefs[iDestFieldNo].DataType of
          ftString :
            tDestination.Fields[iDestFieldNo].AsString := def_string;
          ftBoolean :
            tDestination.Fields[iDestFieldNo].AsBoolean := (def_string = 'Y');
          else
          begin
            sDBUC_DBUpgResult := 'Attempt to assign a default string value to a ' +
                            GetFieldTypeName (tDestination.FieldDefs[iDestFieldNo].DataType,1) +
                            ' field.' +
                            #13 +
                            sDBUC_AgentHelp;
            Inc(iDBUC_Errors);
          end; // else
        end; // case
      end // if
      else
      begin
        // Test if the default value for this field is an integer
        Val(sFieldMap,def_int,dummy);
        if (dummy=0) then // If so...
        begin
          case tDestination.FieldDefs[iDestFieldNo].DataType of
            ftString,
            ftWideString,
            ftSmallint,
            ftInteger,
            ftWord,
            ftAutoInc :
              tDestination.Fields[iDestFieldNo].AsInteger := def_int;

            ftBoolean :
              tDestination.Fields[iDestFieldNo].AsBoolean := (def_int<>0);

            ftFloat ,
            ftCurrency ,
            ftBCD :
              tDestination.Fields[iDestFieldNo].AsFloat := def_int;

            ftDate,
            ftTime,
            ftDateTime :
              tDestination.Fields[iDestFieldNo].AsDateTime := def_int;

            else
            begin
              sDBUC_DBUpgResult := 'Attempt to assign a default integer value to a ' +
                              GetFieldTypeName (tDestination.FieldDefs[iDestFieldNo].DataType,1) +
                              ' field.' +
                              #13 +
                              sDBUC_AgentHelp;
              Inc(iDBUC_Errors);
            end; // option
          end; // case
        end // if
        else
        begin
// Test if the default value for this field is a real
          Val(sFieldMap,def_real,dummy);
          if (dummy=0) then   // If so...
          begin
            case tDestination.FieldDefs[iDestFieldNo].DataType of
              ftString ,
              ftFloat ,
              ftCurrency ,
              ftBCD :
                tDestination.Fields[iDestFieldNo].AsFloat := def_real;

              ftDate,
              ftTime,
              ftDateTime :
                tDestination.Fields[iDestFieldNo].AsDateTime := def_real;

              else
              begin
                sDBUC_DBUpgResult := 'Attempt to assign a default real value to a ' +
                                GetFieldTypeName (tDestination.FieldDefs[iDestFieldNo].DataType,1) +
                                ' field.' +
                                #13 +
                                sDBUC_AgentHelp;
                Inc(iDBUC_Errors);
              end; // option
            end; // case
          end // if
        end; // else
      end; // else
    end; // else
  end; // else
end; // TransferField

//***************************************************************************
//
//  FUNCTION  : TransferRecord
//
//  I/P       : slMapInfo (TStringLinst) : The mapping information from
//                the table definition file for transferring fields
//                from the version of the table represented by the source,
//                to the destination table.
//
//  O/P       : sDBUC_DBUpgResult : string - Contains an error description, if any.
//
//  OPERATION : Transfer all fields in the current record to a new record
//              in the destination table, using the given mapping information.
//
//  UPDATED   : 2010-10-12
//
//***************************************************************************
procedure TransferRecord(slMapInfo : TStringList);
var
  n : integer;
begin
  tDestination.Append;
  // Cycle through all fields
  n := 0;
  while ((n <= tDestination.FieldCount-1) and
         (sDBUC_DBUpgResult = ''))  do
  begin
    // Transfer each individual field within the record
    TransferField(slMapInfo.Values[IntToStr(n)],n);
    Inc(n);
  end; // for

  // Store the record if it was correctly transferred.
  if (sDBUC_DBUpgResult = '') then
    tDestination.Post
  else
    tDestination.Cancel;
end; // TransferRecord

//***************************************************************************
//
//  FUNCTION  : TestMapSection
//
//  I/P       : sMapSection (string) - The name of the mapping section
//                in the database information file.
//
//              tTargetTable (TABSTable) - The table to which we will be
//                copying data.
//
//  O/P       : sDBUpgResult - Holds a description of any errors found,
//                else empty string.
//
//  OPERATION : Checks that the specified map section in the database
//                information file is suitable for use with the specified
//                destination table.
//
//  UPDATED   : 2010-10-11
//
//***************************************************************************
procedure TestMapSection (sMapSection : string;
                          tTargetTable : TABSTable);
var
  table_open : boolean;                 // Shows whether the table was open on entering routine
  map_nos : TStringList;
  map_info : TStringList;
  n : integer;                          // Cycles through each map field number
  iDestnIndex : integer;                // Destination field index
  dummy : integer;                      // Used in string to int conversions
  sFieldMap : string;                   // The mapping to be applied to a field

begin
// Create the storage space and read in the mapping list for this table upgrade.
  map_nos := TStringList.Create;
  map_info := TStringList.Create;
  mifDBUC_TableDefn.ReadSection(sMapSection,map_nos);
  mifDBUC_TableDefn.ReadSectionValues(sMapSection,map_info);

  // Record whether the table has been passed open, and then open it.
  table_open := (tTargetTable.State<>dsInactive);
  tTargetTable.Open;
  // Check that there is complete mapping info for this table
  if (map_nos.Count<>tTargetTable.FieldCount) then
    sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                         'Field mapping information count (' + IntToStr(map_nos.Count) +
                         ') does not match destination table field count (' + IntToStr(tTargetTable.FieldCount) + ').' +
                         #13 +
                         sDBUC_AgentHelp;
  // Close the table, if it was closed on entry
  if (not table_open) then
    tTargetTable.Close;

  // Check that each mapping is sequential and valid.
  n := 0;
  while ((n<=map_nos.Count-1) and (sDBUC_DBUpgResult='')) do
  begin
    // Check that the destination field identifier is a valid number
    Val(map_nos.Strings[n],iDestnIndex,dummy);
    if (dummy<>0) then
      sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                           'Map destination field index is not a number.' +
                           #13 +
                           sDBUC_AgentHelp
    else
    begin
      // Check that the destination fields are sequential
      if (iDestnIndex<>n) then
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                             'Map destination field index ' + IntToStr(iDestnIndex) + ' is not sequential.' +
                             #13 +
                             sDBUC_AgentHelp
      else
      begin
        // Test the given source field/default values
        sFieldMap := map_info.Values[map_nos.Strings[n]];
        // Ignore null mappings
        if (sFieldMap<>'') then
        begin
          // Test if there is a direct field-to-field mapping
          if (LeftStr(sFieldMap,2)='fn') then
          begin
            try
              // Extract the source field number
              StrToInt(Copy(sFieldMap,3,255));
            except
              // Flag a bad source field number if it was bad
              sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                                   'Map source field index for destination field ' + IntToStr(n) + ' is not a number.' +
                                   #13 +
                                   sDBUC_AgentHelp;
            end; // except
          end // if
          else                      // Test if there is a default string for this field
            if (sFieldMap[1]='"') then
            begin                   // Check that its format is correct
              if ((Length(sFieldMap)=1) or
                  (sFieldMap[Length(sFieldMap)]<>'"')) then
                sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                                     'Map source default string format is invalid.' +
                                     #13 +
                                     sDBUC_AgentHelp;
            end // if
            else
            begin
              try
                // Test if there is a valid default integer for this field
                StrToInt(map_info.Values[map_nos.Strings[n]]);
              except
                // If not...
                try
                  // Test if there is a valid default real for this field
                  StrToFloat(map_info.Values[map_nos.Strings[n]]);
                except
                  // If not...
                  sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                                       'Map source default string format is invalid.' +
                                       #13 +
                                       sDBUC_AgentHelp;
                end; // except
              end; // except
            end; // else
        end; // if

      end; // else

    end; // else

    Inc(n);

  end; // while

  // Destroy objects and release memory
  map_nos.Free;
  map_info.Free;
end; // TestMapSection

//***************************************************************************
//
//  FUNCTION  : TransferTableContents
//
//  I/P       : lTransferMessage (TLabel) : The label to be used to
//                display the progress message.   Nil if not required.
//
//              pbRecordProgress (TProgressBar) : The progress bar
//                to show the progress in transferring all table
//                records.   Nil if not required.
//
//              pbIndexProgress (TProgressBar) : The progress bar
//                to show the progress in creating the table indexes.
//                Nil if not required.
//
//  O/P       : (boolean) - TRUE if the data was transferred
//
//  OPERATION : Transfer all records in the source destination into
//              the destination table, using the given mapping information.
//
//  UPDATED   : 2006/08/25
//
//***************************************************************************
procedure TransferTableContents(lTransferMessage : TLabel;
                                pbRecordProgress : TProgressBar;
                                pbIndexProgress : TProgressBar);
var
  map_info : TStringList;
  iRemaining : cardinal;

begin
  // Check that the field mapping information is valid
  TestMapSection(sSourceVer + 'Map',tDestination);

  // Continue if the mapping info is OK
  if (sDBUC_DBUpgResult = '') then
  begin
    // Open the destination table
    tDestination.Open;

    // Set up the transfer progress bars
    if (pbRecordProgress <> nil) then
    begin
      pbRecordProgress.Max := tSource.RecordCount;
      pbRecordProgress.Position := 0;
    end; // if
    if (pbIndexProgress <> nil) then
    begin
      pbIndexProgress.Max := tSource.RecordCount;
      pbIndexProgress.Position := 0;
    end; // if

    // Create the storage space and read in the mapping list for this table upgrade.
    map_info := TStringList.Create;
    mifDBUC_TableDefn.ReadSectionValues(sSourceVer + 'Map',map_info);

    StartFastTimer(1);

    // Scan through all the records in the source table, stopping if we get an error
    tSource.First;
    while ((not tSource.EOF) and (sDBUC_DBUpgResult = '')) do
    begin
      // Transfer this record from the source table to the destination table.
      TransferRecord(map_info);

      // Keep the user informed as to the number of records that have been transferred
      if (pbRecordProgress <> nil) then
        pbRecordProgress.Position := pbRecordProgress.Position + 1;
      if (pbIndexProgress <> nil) then
        pbIndexProgress.Position := pbIndexProgress.Position + 1;
      if ((lTransferMessage <> nil) and (pbRecordProgress <> nil)) then
      begin
        iRemaining := GetFastTimer(1);
        iRemaining := cardinal(pbRecordProgress.Max - pbRecordProgress.Position) *
                      (cardinal(iRemaining) div cardinal(pbRecordProgress.Position));
        lTransferMessage.Caption := 'Upgrading the ' + sTableTitle +
                                    ' table (' +
                                    IntToStr(iRemaining div 60000) + 'm ' +
                                    IntToStr((iRemaining mod 60000)div 1000) + 's till completion)';
      end; // if
      if ((pbRecordProgress <> nil) and ((pbRecordProgress.Position mod 100) = 0)) then
        Application.ProcessMessages;

      if ((pbRecordProgress <> nil) and (sDBUC_DBUpgResult <> '')) then
        WriteToDBUpgLog(IntToStr(pbRecordProgress.Position) + ':' + tDestination.Fields[0].AsString);

      tSource.Next;
    end; // while

    // Close down the destination table
    tDestination.Close;

    map_info.Free;
  end; // if

  // Count any errors encountered.
  if (sDBUC_DBUpgResult <> '') then
    Inc(iDBUC_Errors);

  tSource.Close;              // Close down the source table
end; // TransferTableContents

//***************************************************************************
//
//  FUNCTION    :   RenameTempTable
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
procedure RenameTempTable;
var
  file_root : string;
  sr : TSearchRec;
begin
  file_root := LeftStr(ExtractFileName(sDBUC_TableFilename),Pos('.',ExtractFileName(sDBUC_TableFilename)));

  file_root := LeftStr(file_root,Length(file_root)-1); // Knock off the '.'

  WriteToDBUpgLog('Temporary table renamed');
end; // RenameTempTable

//***************************************************************************
//
//  FUNCTION    :   SourceTableIndexesMatch
//
//  I/P         :   bTestAll - TRUE if all indexes are to be tested.
//                        FALSE if only the primary index is to be tested.
//
//  O/P         :   (boolean) - TRUE if the original and latest table
//                        have the same indexes.
//
//  OPERATION   :   Check whether there is any difference between the
//                      indexes of the existing table and the indexes as defined
//                      for the latest table.
//
//  UPDATED     :   2003/08/29
//
//***************************************************************************
function SourceTableIndexesMatch(bTestAll : boolean) : boolean;
var
  n,m : integer;
  slIndexNos : TStringList;
  slIndexInfo : TStringList;
  sIndexLine : string;            // The ini's line of index information
  bFound : boolean;
  sIndexName : string;
  sIndexFields : string;
  iIndexNumericalOptions : integer;
  setIndexOptions : TIndexOptions;
  iIndexesToTest : integer;
begin
// Assume that the indexes in the table match the indicated latest index descriptions
  result := TRUE;

  slIndexNos := TStringList.Create;    // Create the storage space and read in the
  slIndexInfo := TStringList.Create;   // list of fields in this table.
  mifDBUC_TableDefn.ReadSection('LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('LatestIndexes',slIndexInfo);

// Check the table
  with tSource do
  begin
// Ensure that we have the correct index defs for the table.
    IndexDefs.Update;

// Set up the number of indexes to test.   The Primary index has already been checekd as
// being in position 1 (if it is defined).
    if (bTestAll) then
      iIndexesToTest := slIndexNos.Count
    else
    begin
      iIndexesToTest := 1;
      if (slIndexNos.Count = 0) then
        iIndexesToTest := 0;
    end; // else

    // Ensure that there are the correct number of fields
    if (((bTestAll) and (tSource.IndexDefs.Count=iIndexesToTest)) or
        ((not bTestAll) and (tSource.IndexDefs.Count>=iIndexesToTest))) then
    begin
      // Cycle through each defined index, and check that it exists in the table
      n := 0;
      while ((n<iIndexesToTest) and (result)) do
      begin
        sIndexLine := slIndexInfo.Values[slIndexNos.Strings[n]];
        sIndexName := ExtractAndTrim(sIndexLine,',');
        sIndexFields := ExtractAndTrim(sIndexLine,',');
        iIndexNumericalOptions := StrToInt(sIndexLine);
        setIndexOptions := [];
        if ((iIndexNumericalOptions AND $10)=$10) then
        begin
          setIndexOptions := setIndexOptions + [ixPrimary];
        end; // if
        if ((iIndexNumericalOptions AND $08)=$08) then
          setIndexOptions := setIndexOptions + [ixUnique];
        if ((iIndexNumericalOptions AND $04)=$04) then
          setIndexOptions := setIndexOptions + [ixDescending];
        if ((iIndexNumericalOptions AND $02)=$02) then
          setIndexOptions := setIndexOptions + [ixNonMaintained];
        if ((iIndexNumericalOptions AND $01)=$01) then
          setIndexOptions := setIndexOptions + [ixCaseInsensitive];
        // Look for an index in the table that has the same definition
        bFound := FALSE;
        m := 0;
        while ((m < IndexDefs.Count) and (not bFound)) do
        begin
          if ((UpperCase(sIndexName) = UpperCase(IndexDefs.Items[m].Name)) and
              (UpperCase(sIndexFields) = UpperCase(IndexDefs.Items[m].Fields)) and
              (setIndexOptions = IndexDefs.Items[m].Options)) then
            bFound := TRUE;
          Inc(m);
        end; // while
        // Flag if we did not find the defined index
        if (not bFound) then
          result := FALSE;
        Inc(n);
      end; // while
    end // if
    else
      result := FALSE;
  end; // with

// Log progress
  if (result) then
  begin
    if (bTestAll) then
      WriteToDBUpgLog('Source Table Index Definitions match Latest (All)')
    else
      WriteToDBUpgLog('Source Table Index Definitions match Latest (Primary)');
  end
  else
  begin
    if (bTestAll) then
      WriteToDBUpgLog('Source Table Index Definitions do not match Latest (All)')
    else
      WriteToDBUpgLog('Source Table Index Definitions do not match Latest (Primary)');
  end;

// Free up the space used by these variables
  slIndexNos.Free;
  slIndexInfo.Free;
end; // SourceTableIndexesMatch

//***************************************************************************
//
//  FUNCTION    :   UpgradeIndexes
//
//  I/P         :   bCreateAll (boolean) - TRUE if all indexes are to be
//                        recreated
//
//  O/P         :   None
//
//  OPERATION   :   Creates indexes for the current table.
//
//                      Either
//                      - Deletes and recreates all specified indexes or
//                      - Deletes extra indexes and creates any that are
//                        not according to the latest definition.
//
//  UPDATED     :   2004/04/10
//
//***************************************************************************
procedure UpgradeIndexes(bCreateAll : boolean;
                         pbIndexProgress : TProgressBar);
var
  slIndexNos : TStringList;
  slIndexInfo : TStringList;
  n,m : integer;
  sIndexName : string;
  sIndexFields : string;
  setIndexOptions : TIndexOptions;
  bProceed : boolean;
  bFound : boolean;
begin
// Create the storage space and read in the list of fields in this table.
  slIndexNos := TStringList.Create;
  slIndexInfo := TStringList.Create;
  mifDBUC_TableDefn.ReadSection('LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('LatestIndexes',slIndexInfo);

// Check the table and ensure that we have the correct index defs for the table.
  tSource.IndexDefs.Update;

// Set up the progress bar
  if (pbIndexProgress <> nil) then
  begin
    pbIndexProgress.Max := slIndexNos.Count;
    pbIndexProgress.Position := 0;
  end; // if

// Check whether this is a total index recreation, or just an update.
  if (bCreateAll) then
  begin
// Delete all indexes
    while (tSource.IndexDefs.Count > 0) do
    begin
      WriteToDBUpgLog('Deleting index ' + tSource.IndexDefs.Items[0].Name);
      tSource.DeleteIndex(tSource.IndexDefs.Items[0].Name);
      tSource.IndexDefs.Update;
    end; // for
  end // if
  else
  begin
// Delete any indexes that may exist in the table but are not defined in the control file.
    n := 0;
    while (n < tSource.IndexDefs.Count) do
    begin
// Try to find the index in the definitions file
      m := 0;
      bFound := FALSE;
      while ((m<slIndexNos.Count) and (not bFound)) do
      begin
// Get the index information - this has already been checked, so we can assume no errors
        GotIndexInfo(slIndexInfo.Values[slIndexNos.Strings[m]],
                     sIndexName,sIndexFields,setIndexOptions);
        if ((UpperCase(sIndexName) = UpperCase(tSource.IndexDefs.Items[n].Name)) and
              (UpperCase(sIndexFields) = UpperCase(tSource.IndexDefs.Items[n].Fields)) and
              (setIndexOptions = tSource.IndexDefs.Items[n].Options)) then
          bFound := TRUE
        else
          Inc(m);
      end; // while
// Check whether the index was found in the Latest index definitions file
      if (not bFound) then
      begin
// If not, delete the index from the table, and restart the scanning
        WriteToDBUpgLog('Deleting index ' + tSource.IndexDefs.Items[n].Name);
        tSource.DeleteIndex(tSource.IndexDefs.Items[n].Name);
        tSource.IndexDefs.Update;
        n := 0;
      end // if
      else
        Inc(n);
    end; // while
  end; // else

// Cycle through each control-file defined index, and create it in the table if it does not exist.
  n := 0;
  bProceed := TRUE;
  while ((n<slIndexNos.Count) and (bProceed)) do
  begin
// Get the index information - this has already been checked, so we can assume no errors
    GotIndexInfo(slIndexInfo.Values[slIndexNos.Strings[n]],
                 sIndexName,sINdexFields,setIndexOptions);
// Look for an index in the table that has the same definition
    bFound := FALSE;
    m := 0;
    while ((m < tSource.IndexDefs.Count) and (not bFound)) do
    begin
      if ((UpperCase(sIndexName) = UpperCase(tSource.IndexDefs.Items[m].Name)) and
          (UpperCase(sIndexFields) = UpperCase(tSource.IndexDefs.Items[m].Fields)) and
          (setIndexOptions = tSource.IndexDefs.Items[m].Options)) then
        bFound := TRUE;
      Inc(m);
    end; // while
// Check whether we found the required index
    if (not bFound) then
    begin
// If not, try to create it
      try
        tSource.AddIndex(sIndexName,sIndexFields,setIndexOptions);
        WriteToDBUpgLog('Added index ' + sIndexName);
// Update the progress bar
        if (pbIndexProgress <> nil) then
        begin
          pbIndexProgress.Position := pbIndexProgress.Position + 1;
          Application.ProcessMessages;
        end; // if
      except
        bProceed := FALSE;
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
                        'Unable to create index "' + sIndexName + '"' + #$D +
                        'This table has not been upgraded.' +
                        #13 +
                        sDBUC_AgentHelp;
      end; // except
    end; // if
    Inc(n);
  end; // while

// Free up the space used by these variables
  slIndexNos.Free;
  slIndexInfo.Free;
end; // UpgradeIndexes

//***************************************************************************
//
//  FUNCTION  : UpgradeTable
//
//  I/P       : iUpgTableIndex - The index number of the table to be
//                upgraded.
//
//  O/P       : None.
//
//  OPERATION : Performs a complete upgrade on the indicated table
//
//  UPDATED   : 2010-10-12
//
//***************************************************************************
procedure UpgradeTable(iUpgTableIndex : integer;
                       sTableDirectory : string;
                       lProgressMessage : TLabel;
                       pbTableRecordProgress : TProgressBar;
                       pbTableIndexProgress : TProgressBar);
begin
  GotTableInformationFromIndex(iUpgTableIndex);

  // Get the descriptive name of the table being upgraded
  sTableTitle := mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iUpgTableIndex),'');
  // Show the user what we are doing
  if (lProgressMessage <> nil) then
    lProgressMessage.Caption := 'Upgrading the ' + sTableTitle + ' table...';

  WriteToDBUpgLog(#$D + IntToStr(iUpgTableIndex) + '. Upgrading ' + sTableTitle + ' Absolute table');

  // Update the Table progress bars
  if (pbTableRecordProgress <> nil) then
    pbTableRecordProgress.Position := 0;
  if (pbTableIndexProgress <> nil) then
    pbTableIndexProgress.Position := 0;
  // Keep the display up to date
  if ((pbTableRecordProgress <> nil) or (pbTableIndexProgress <> nil)) then
    Application.ProcessMessages;

  // Start off with no errors for this table
  sDBUC_DBUpgResult := '';
  // Check whether the source table name is OK, and whether it exists
  if (AccessedSourceTable) then
    // Get the version of the table that we are about to upgrade
    if ((bNewTable) or (GotSourceVersion)) then
      // Check that the version description for the source table is OK
      if ((bNewTable) or (TableFieldDefnsOK(sSourceVer))) then
        // Check that the version description for the latest version of the table is OK
        if ((TableFieldDefnsOK('Latest')) and
            (LatestIndexDefnsOK)) then
          // Check that the original table is correct according to the version information that we have
          if ((bNewTable) or (SourceTableFieldsMatch(sSourceVer))) then
            // Check whether we actually need to upgrade the entire table.
            // We must upgrade the table if one does not exist, if the source fields don't match
            // the latest fields or if the primary index has changed.
            if ((bNewTable) or
                (not (SourceTableFieldsMatch('Latest'))) or
                (not (SourceTableIndexesMatch(FALSE)))) then
            begin
              // Clear any "error message" that may have been generated by the field match or index
              // match checks above.
              sDBUC_DBUpgResult := '';

              // Check that we have been able create a temporary table, for the data transfer
              if (CreatedTempTable) then
              begin
                // If this is not a new table, transfer the data from the existing table
                if (not bNewTable) then
                  TransferTableContents(lProgressMessage,pbTableRecordProgress,pbTableIndexProgress);

                // If this is a new table, or if we transferred the contents, rename the temporary table
                if ((bNewTable) or (sDBUC_DBUpgResult = '')) then
                begin
                  tDestination.RenameTable(sDBUC_TableFilename);
                  // Count the changes that were made
                  if (bNewTable) then
                    Inc(iDBUC_NewTables)
                  else
                    Inc(iDBUC_FieldsUpdated);
                end; // if
              end; // if
            end // if
            else
            begin
              // Check whether we need to upgrade the indexes of the source table
              if (not (SourceTableIndexesMatch(TRUE))) then
              begin
                // Upgrade the indexes only
                UpgradeIndexes(FALSE,pbTableIndexProgress);
                Inc(iDBUC_IndexesUpdated);
              end; // if
            end; // else
  // Display the error message, if one was set up
  if (sDBUC_DBUpgResult<>'') then
  begin
    Dialog_Ops.MessageDlg(sDBUC_DBUpgResult,mtError,[mbOK],0);
    WriteToDBUpgLog(sDBUC_DBUpgResult);
    Inc(iDBUC_Errors);
  end; // if
  WriteToDBUpgLog('Finished with ' + sTableTitle + ' table (' + DateTimeToStr(Now) + ')');
  // Close the table that we have just worked on, just in case it was not yet closed
  if (tSource.State <> dsInactive) then
    tSource.Close;
end; // UpgradeTable

//***************************************************************************
//
//  FUNCTION  : UpgradeDatabase
//
//  I/P       : sDBDirectory - The directory containing the database
//                to be upgraded.
//
//              lProgressMessage - A TLabel that will show what is
//                happening during the upgrade.
//
//              pbTableContents - A TProgressBar that will show how
//                progress is being made in copying table contents
//                when upgrading a table.
//
//              pbTableIndexes - A TProgressBar that will show how
//                progress is being made in recreating indexes when
//                table indexes are being created.
//
//              pfDatabaseProgress - A TProgressBar that will show
//                how progress is being made on the entire database.
//
//              bRestart (boolean) - TRUE to cause the database progress
//                bar to be reset back to zero.
//
//  O/P       :
//
//  OPERATION : Performs a complete upgrade on the indicated database
//
//  UPDATED   : 2018-11-05
//
//***************************************************************************
procedure UpgradeDatabase(sDBDirectory : string;
                          lProgressMessage : TLabel;
                          pbTableContents : TProgressBar;
                          pbTableIndexes : TProgressBar;
                          pbDatabaseProgress : TProgressBar;
                          bRestart : boolean;
                          const pw : String = '');
var
  n : integer;

begin
  WriteToDBUpgLog('');
  WriteToDBUpgLog('Create/Upgrade Database');
  WriteToDBUpgLog('Target Database : ' + sDBDirectory + sDBUC_DBFileName);
  WriteToDBUpgLog('Starting : ' + DateTimeToStr(Now));

  // Set up the progress bars, if specified
  if (pbDatabaseProgress <> nil) then
  begin
    pbDatabaseProgress.Max := GetTablesCount;
    if (bRestart) then
      pbDatabaseProgress.Position := 0;
  end; // if
  if (pbTableContents <> nil) then
    pbTableContents.Position := 0;
  if (pbTableIndexes <> nil) then
    pbTableIndexes.Position := 0;

  // Ensure that the database is in existence.   At this point we
  // should have a valid filename in sDBFileName
  dbTest.DatabaseFileName := sDBDirectory + sDBUC_DBFileName;
  dbTest.Password := pw;
  if (not FileExists(dbTest.DatabaseFileName)) then
    dbTest.CreateDatabase;

  // Cycle through all the tables to be upgraded
  for n := 1 to GetTablesCount do
  begin
    // Start each table with no errors
    sDBUC_DBUpgResult := '';

    // Upgrade/transfer/create the table
    // I had created tDestination in initialization and freed it in finalization,
    // but there was a wierd reaction when using this single table to then create
    // multple tables in the routine below. The CreateTable method would use
    // FieldDefs from the previous table! I got around this problem by creating
    // and freeing the destination table for each table upgrade/creation.
    tDestination := TABSTable.Create(nil);
    try
      tDestination.DatabaseName := WORK_DATABASE_NAME;
      UpgradeTable(n,sDBDirectory,lProgressMessage,pbTableContents,pbTableIndexes);
    finally
      tDestination.Free;
    end;

    // Ensure that the Table progress bars are at the end
    if (pbTableContents <> nil) then
      pbTableContents.Position := pbTableContents.Max;
    if (pbTableIndexes <> nil) then
      pbTableIndexes.Position := pbTableIndexes.Max;
    // Update the Database progress bar
    if (pbDatabaseProgress <> nil) then
      pbDatabaseProgress.Position := pbDatabaseProgress.Position + 1;
    // Keep the display up to date
    if ((pbTableContents <> nil) or
        (pbTableIndexes <> nil) or
        (pbDatabaseProgress <> nil)) then
      Application.ProcessMessages;
  end; // for

  // Wipe the activity message
  if (lProgressMessage <> nil) then
    lProgressMessage.Caption := '';

  WriteToDBUpgLog(GetDBUpgResults);

  dbTest.Connected := FALSE;
end; // UpgradeDatabase
(*
//***************************************************************************
//
//  FUNCTION    :   ReindexTable
//
//  I/P         :   iRITableIndex - The index number of the table to be
//                        re-indexed.
//
//  O/P         :
//
//  OPERATION   :   Performs a complete recreation of the indexes for the
//                      indicated table.
//
//  UPDATED     :
//
//***************************************************************************
procedure ReindexTable(iRITableIndex : integer;
                       sTableDirectory : string;
                       lProgressMessage : TLabel;
                       pbTableIndexProgress : TProgressBar);
begin
// Renew the hourglass cursor on each table
  Screen.Cursor := crHourGlass;

// Get the descriptive name of the table being upgraded
  sTableTitle := ifDBDefn.ReadString('Descriptions',IntToStr(iRITableIndex),'');
// Show the user what we are doing
  if (lProgressMessage <> nil) then
    lProgressMessage.Caption := 'Upgrading the ' + sTableTitle + ' table...';

  GetTableInformationFromIndex(iRITableIndex);
// Add the directory
  sTableFilename := sTableDirectory + sTableFilename;
  WriteToDBUpgLog(#$D + IntToStr(iRITableIndex) + '. Upgrading ' + sTableTitle + ' table');

// Update the Table progress bar
  if (pbTableIndexProgress <> nil) then
  begin
    pbTableIndexProgress.Position := 0;
    // Keep the display up to date
    Application.ProcessMessages;
  end; // if

// Delete any existing indexes.   We must do this before trying to open the table as any corrupt
// indexes will prevent access to the table.
  DeletedFiles(ChangeFileExt(sTableFilename,'.PX'),0,0.0);
  DeletedFiles(ChangeFileExt(sTableFilename,'.XG*'),0,0.0);
  DeletedFiles(ChangeFileExt(sTableFilename,'.YG*'),0,0.0);

// Start off with no errors for this table
  sDBUpgResult := '';
// Check whether the source table name is OK, and whether it exists
  if (AccessedSourceTable) then
// If this is an existing table, get the version of the table that we are about to upgrade
    if ((not bNewTable) and (GotSourceVersion)) then
// Check that the version description for the source table is OK
      if (TableFieldDefnsOK(sSourceVer)) then
// Check that the version description for the latest version of the table is OK
        if ((TableFieldDefnsOK('Latest')) and
            (LatestIndexDefnsOK)) then
// Check that the table is correct according to the latest version information
          if (SourceTableFieldsMatch('Latest')) then
          begin
// Recreate the indexes
            UpgradeIndexes(TRUE,pbTableIndexProgress);
//!! Do we need this TRUE and FALSE thing now that we actually delete all the indexes for the file.?
            Inc(iIndexesUpdated);
          end; // if
  // Display the error message, if one was set up
  if (sDBUpgResult<>'') then
  begin
    // Restore the cursor for the prompt
    Screen.Cursor := crDefault;
     MessageDlg(sDBUpgResult,mtError,[mbOK],0);
    WriteToDBUpgLog(sDBUpgResult);
    Inc(iErrors);
  end; // if
  WriteToDBUpgLog('Finished with ' + sTableTitle + ' table');
  // Close the table that we have just worked on, just in case it was not yet closed
  if (tSource.State <> dsInactive) then
    tSource.Close;
end; // UpgradeTable

//***************************************************************************
//
//  FUNCTION    :   RecreateDatabaseIndexes
//
//  I/P         :   sDBDirectory - The directory containing the database
//                        to be upgraded.
//
//                      lProgressMessage - A TLabel that will show what is
//                        happening during the upgrade.
//
//                      pbTableContents - A TProgressBar that will show how
//                        progress is being made in copying table contents
//                        when upgrading a table.
//
//                      pbTableIndexes - A TProgressBar that will show how
//                        progress is being made in recreating indexes when
//                        table indexes are being created.
//
//                      pfDatabaseProgress - A TProgressBar that will show
//                        how progress i being made on the entire database.
//
//  O/P         :
//
//  OPERATION   :   Performs a re-creation of all indexes in the indicated
//                      database.
//
//  UPDATED     :   2004/03/10
//
//***************************************************************************
procedure RecreateDatabaseIndexes(sDBDirectory : string;
                                  lProgressMessage : TLabel;
                                  pbTableIndexes : TProgressBar;
                                  pbDatabaseProgress : TProgressBar);
var
  n : integer;
begin
  WriteToDBUpgLog('Recereate Indexes in : ' + sDBDirectory);

// Set up the progress bars, if specified
  if (pbDatabaseProgress <> nil) then
  begin
    pbDatabaseProgress.Max := iTablesInDB;
    pbDatabaseProgress.Position := 0;
  end; // if
  if (pbTableIndexes <> nil) then
    pbTableIndexes.Position := 0;

// Cycle through all the tables to be upgraded
  for n := 1 to iTablesInDB do
  begin
    ReindexTable(n,sDBDirectory,lProgressMessage,pbTableIndexes);
// Ensure that the Table progress bar is at the end
    if (pbTableIndexes <> nil) then
      pbTableIndexes.Position := pbTableIndexes.Max;
// Update the Database progress bar
    if (pbDatabaseProgress <> nil) then
    begin
      pbDatabaseProgress.Position := n;
      // Keep the display up to date
      Application.ProcessMessages;
    end; // if
  end; // for

// Wipe the activity message
  if (lProgressMessage <> nil) then
    lProgressMessage.Caption := '';

// Show we are have finished
  Screen.Cursor := crDefault;
end; // UpgradeDatabase

//***************************************************************************
//
//  FUNCTION  : RefreshOpenTables
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Refreshes all open TABSTable components in a given DataModule.
//
//  UPDATED   : 2010-10-11
//
//***************************************************************************
procedure RefreshOpenTables(dmData : TDataModule);
var
  n : word;
begin
  for n := 0 to dmData.ComponentCount-1 do
  begin
    if ((dmData.Components[n] is TABSTable) and
        ((dmData.Components[n] as TABSTable).State = dsBrowse)) then
      (dmData.Components[n] as TABSTable).Refresh;
  end; // for
end; // RefreshOpenTables

//***************************************************************************
//
//  FUNCTION    :   CloseOpenTablesAndQueries
//
//  I/P         :   None
//
//  O/P         :   None
//
//  OPERATION   :   Close all TABSTables and TABSQueries in a given DataModule
//
//  UPDATED     :   2010-10-11
//
//***************************************************************************
procedure CloseOpenTablesAndQueries(dmData : TDataModule);
var
  n : byte;
begin
  for n:=0 to dmData.ComponentCount-1 do
  begin
    if (dmData.Components[n] is TABSTable) then
      (dmData.Components[n] as TABSTable).Close;
    if (dmData.Components[n] is TABSQuery) then
      (dmData.Components[n] as TABSQuery).Close;
  end; // for
end; // CloseOpenTablesAndQueries
*)
//****************************************************************************
//
//  FUNCTION  : CheckDatabaseFiles
//
//  I/P       : sTestDir (string) - The directory to be checked
//
//  O/P       : sDBUpgResult - An empty string means that the database file was
//                found.   Anything else means that there were problems in
//                accessing the DB definition file or the database file.
//
//  OPERATION : Check access to DB definition file, and existance of a file
//              with the given database file name,
//
//  UPDATED   : 2010-10-14
//
//****************************************************************************
procedure CheckDatabaseFiles(sTestDir : string);
begin
  // Initially, no error
  sDBUC_DBUpgResult := '';

  // Check that we have the definition files for the database
  if (AccessedDBDefinitionResources) then
  begin
    // Fix up the data directory location if it does not already end in a '\'
    sTestDir := IncludeTrailingPathDelimiter(sTestDir);
    // Check for the presence of the single database file
    if (not FileExists(sTestDir + sDBUC_DBFileName)) then
      sDBUC_DBUpgResult := 'Database file missing : ' + sTestDir + sDBUC_DBFileName;
  end; // if
end; // CheckDatabaseFiles

//****************************************************************************
//
//  FUNCTION  : CheckDatabaseValidity
//
//  I/P       : sTestDir (string) - The directory which contains the
//                database is to be tested.
//
//              tTestTable (TTable) - A BDE table for use with testing of
//                Paradox tables.
//
//  O/P       : sDBUpgResult - Contains a non-empty string if there
//                is a negative result to the test, and an empty string
//                if everything is OK.
//
//  OPERATION : Checks that all tables exist, and that they all conform
//                to the format of the latest version.
//
//  UPDATED   : 2008/04/07
//
//****************************************************************************
procedure CheckDatabaseValidity(sTestDir : String;
                                const pw : String = '');
var
  iCurrentTable : integer;
  n : integer;
  field_nos : TStringList;
  field_info : TStringList;
  field_line : string;            // The ini's line of field information
  field_name : string;            // Used for Add methog, when adding fields
  field_datatype : TFieldType;    // Used for Add methog, when adding fields
  field_size : word;              // Used for Add methog, when adding fields
  field_required : boolean;       // Used for Add methog, when adding fields
  sDBFileName : string;

begin
  // Initially assume all is OK
  sDBUC_DBUpgResult := '';

  // Check that we have an information file for the database upgrade program
  if (AccessedDBDefinitionResources) then
  begin
    // Fix up the data directory location if it does not already end in a '\'
    sTestDir := IncludeTrailingPathDelimiter(sTestDir);

    // Check that the database exists
    sDBFileName := mifDBUC_DBDefn.ReadString('Target','DBName','');
    if ((sDBFileName <> '') and
        (FileExists(sTestDir + sDBFileName))) then
    begin
      dbTest.DatabaseFileName := sTestDir + sDBFileName;
      dbTest.Password := pw;

      // Cycle through all the tables to be checked within the database
      iCurrentTable := 1;
      while ((iCurrentTable <= GetTablesCount) and
             (sDBUC_DBUpgResult = '')) do
      begin
        if (GotTableInformationFromIndex(iCurrentTable)) then
        begin
          tSource.TableName := sDBUC_TableFilename;
          if (tSource.Exists) then
          begin
            // Create the storage space for the list of fields in this table.
            field_nos := TStringList.Create;
            field_info := TStringList.Create;

            // Read in the list of the fields that are expected to be in this table.
            mifDBUC_TableDefn.ReadSection('LatestFields',field_nos);
            mifDBUC_TableDefn.ReadSectionValues('LatestFields',field_info);

            // Now check the table
            tSource.Open;
            // Check that there are the correct number of fields
            if (tSource.FieldDefs.Count=field_nos.Count) then
            begin
              // Scan through all the fields
              for n := 0 to tSource.FieldDefs.Count-1 do
              begin
                field_line := field_info.Values[field_nos.Strings[n]];
                // Check the format of the line
                if (Count_Chars(field_line,',')>=3) then
                begin
                  // Format of info given appears correct
                  field_name := LeftStr(field_line,Pos(',',field_line)-1);
                  field_line := Copy(field_line,Pos(',',field_line)+1,255);
                  field_datatype := GetANSFieldDataType(field_line[1]);
                  if (field_datatype = ftUnknown) then
                     sDBUC_DBUpgResult := 'An unknown field type was found in the ' +
                                          mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table.' + #13 +
                                          #13 +
                                          sDBUC_AgentHelp;

                  field_line := Copy(field_line,Pos(',',field_line)+1,255);
                  if ((field_datatype = ftString) or
                      (field_datatype = ftWideString) or
                      (field_datatype = ftMemo) or
                      (field_datatype = ftWideMemo) or
                      (field_datatype = ftBytes)) then
                    field_size := StrToInt(LeftStr(field_line,Pos(',',field_line)-1))
                  else
                    field_size := 0;

                  field_line := Copy(field_line,Pos(',',field_line)+1,255);
                  field_required := (field_line[1]='1');

                  // Check if there was an error in the field definition
                  if (UpperCase(tSource.FieldDefs.Items[n].Name)<>UpperCase(field_name)) or
                     (tSource.FieldDefs.Items[n].DataType<>field_datatype) or
                     (tSource.FieldDefs.Items[n].Size<>field_size) or
                     (tSource.FieldDefs.Items[n].Required<>field_required) then
                    // Error in name, type, size or required, therefore table is not the latest version
                    sDBUC_DBUpgResult := 'The version of the ' +
                                         mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table is not correct.' + #13 +
                                         'Please upgrade the database.';
                end // if
                else
                  // Error in field information given.
                  sDBUC_DBUpgResult := 'There is a field information error in the ' +
                                       mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table.' + #13 +
                                       #13 +
                                       sDBUC_AgentHelp;
              end; // for
            end // if
            else
              // This table does not have the same number of fields as the most recent, so obviously
              // it cannot be the latest table version
              sDBUC_DBUpgResult := 'The version of the ' +
                                   mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table is not correct.' + #13 +
                                   'Please upgrade the database.';
            // Close the table
            tSource.Close;

            // Free up the space used by these variables
            field_nos.Free;
            field_info.Free;
          end // if
          else
            // A table file is missing from the database
            sDBUC_DBUpgResult := 'The ' +
                                 mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table is missing from the database.' + #13 +
                                 'Please upgrade the database.';
        end // if
        else
          // Could not get the data for the indexed table (unlikely)
          sDBUC_DBUpgResult := 'Table definition #' + IntToStr(iCurrentTable) + ' is corrupt' + #$D +
                               sDBUC_AgentHelp;


        // Move on to the next table
        Inc(iCurrentTable);
      end; // for

      dbTest.Close;
    end // if
    else
      // Could not get the data for the indexed table (unlikely)
      sDBUC_DBUpgResult := 'The database file ' + sDBFileName + ' is missing' + #$D +
                           'Please upgrade the database.';
  end; // if
end; // CheckDatabaseValidity
(*
//****************************************************************************
//
//  FUNCTION  : RecordAccessMessage
//
//  I/P       : dsTarget (TDataSet) - The dataset containing the record
//                that is to be modified (the current record).
//
//  O/P       : (string) : Empty if the record may be modified.
//                Otherwise, it contains a descriptive reason.
//
//  OPERATION : Checks whether the current record in the given dataset
//                may be edited.   (A record may be locked over a network
//                if someone else is editing it.)
//
//  UPDATED   : 2007/06/25
//
//****************************************************************************
function RecordAccessMessage(dsTarget : TDataSet) : string; overload;
begin
  try
    dsTarget.Edit;
    dsTarget.Cancel;
    // Able to modify the record
    result := '';
  except
    on E:EDBEngineError do
      result := 'Unable to gain exclusive access.' + #$D +
                'Received the following error message : ' + #13 +
                '      ' + SearchAndReplace(E.Message,#10,#10 + '      ') + #13 +
                'Ensure that the record is not currently being accessed by another program or network user.';
  end; // except
end; // RecordAccessMessage

//****************************************************************************
//
//  FUNCTION  : RecordAccessMessage
//
//  I/P       : dsTarget (TDBISAMDataSet) - The dataset containing the
//                record that is to be modified (the current record).
//
//  O/P       : (string) : Empty if the record may be modified.
//                Otherwise, it contains a descriptive reason.
//
//  OPERATION : Checks whether the current record in the given dataset
//                may be edited.   (A record may be locked over a network
//                if someone else is editing it.)
//
//  UPDATED   : 2007/06/25
//
//****************************************************************************
function RecordAccessMessage(dsTarget : TDBISAMDataSet) : string; overload;
begin

  while TRUE do
  begin
    try
      dsTarget.Edit;
      dsTarget.Cancel;
      // Able to modify the record
      result := '';
      // Break out of the retry loop
      Break;
    except
      on E: Exception do
      begin
        if (E is EDBISAMEngineError) then
        begin
          if ((EDBISAMEngineError(E).ErrorCode=DBISAM_RECLOCKFAILED) or
              (EDBISAMEngineError(E).ErrorCode=DBISAM_LOCKED)) then
          begin
            result := 'Unable to gain exclusive access.' + #$D +
                      'Received the following error message : ' + #13 +
                      '      ' + StringReplace(E.Message,#10,#10 + '      ',[rfReplaceAll]) + #13 +
                      'Ensure that the record is not currently being accessed by another program or network user.';
            Break;
          end // if
          else
            if (EDBISAMEngineError(E).ErrorCode=DBISAM_KEYORRECDELETED) then
            begin
              dsTarget.Refresh;
              Continue;
            end // if
            else
            begin
               MessageDlg(E.Message,mtError,[mbOK],0);
              Break;
            end; // else
        end
        else
        begin
           MessageDlg(E.Message,mtError,[mbOK],0);
          Break;
        end; // else
      end; // on
    end; // except
  end; // while
end; // RecordAccessMessage

//***************************************************************************
//
//  FUNCTION  : LocalShareIsTrue
//
//  I/P       :
//
//  O/P       : (boolean) - TRUE if LOCAL SHARE is set to TRUE.
//
//  OPERATION : Checks whether the LOCAL SHARE under BDE's Configuration\
//              System\Init is set to TRUE or not.
//
//  UPDATED   : 2006/01/24
//
//***************************************************************************
function LocalShareIsTrue : Boolean;
var
  SL : TStringList;
begin
  { Ensure BDE is initialised }
  DBTables.Session.Open;
  SL := TStringList.Create;
  DBTables.Session.GetConfigParams('\System\Init','',SL);
  result := ('TRUE' = SL.Values['LOCAL SHARE']);
  SL.Free;
end;




















// --- Stuff above here appears to work.   Stuff below is old, and needs to be reworked
// to operate correctly on multiple DB definition files.























(*
//***************************************************************************
//
//  FUNCTION    :   Transfer_To_Destn_Supp_Table
//
//  I/P         :   map_section (string) - The name of the mapping
//                        section in the database information file that will
//                        control the transfer of data between the two tables
//
//                      tSuppDesnt (TTable) - The destination supplementary table
//
//  O/P         :   None.
//
//  OPERATION   :   Transfers a record in the currently opened transfer
//                      supplementary table to the destination supplementary table
//
//  UPDATED     :   2001/02/19
//
//***************************************************************************
procedure CopyRecord(tFrom : TTable;
                     tTo : TTable;
                     sMapSection : string);
var
  map_info : TStringList;
  n : integer;

begin


// Cycle through each of the fields and transfer the data from source to destination, or fill in default
// data, as specified in the map file.
      for n := 0 to tTo.FieldCount-1 do
      begin
        result := TransferredFieldContents(tSource, tDestination, map_info.Values[map_nos.Strings[n]], n);
// Check for an error
        if (not result) then
        begin
          Inc(iErrors);
          Break;
        end; // if
      end; // for







// Get the mapping for the transfer operation
  map_info := TStringList.Create;
  ifDbCtrlFile.ReadSectionValues(sMapSection,map_info);

// Cycle through all destination fields and copy from source to destination,
// except for the Index, which must remain unchanged.
//!! Errors in the transfer operation are ignored.   Should this be so?
  for n := 0 to tDestn.FieldCount-1 do
    TransferredFieldContents(dmYAMS.tTransfer,tDestn,map_info.Values[IntToStr(n)],n);

  map_info.Free;
end; // Transfer_To_Destn_Supp_Table

//***************************************************************************
//
//  FUNCTION    :  Got_Map_Section
//
//  I/P         :  tDestn - The table to which data is to be copied.
//
//                     tSource - The table from which data is to be copied
//
//  O/P         :  result - TRUE if a valid section mapping is found.
//
//                     sMapSection - The registry section name, in the format
//                       x.VyyyMap, where x indicates the index of the sections
//                       dealing with the tDestn table, and yyy indicates the
//                       version of the tSource table.
//
//  OPERATION   :  Determines the name of a valid mapping section, to be
//                     used to transfer data between two versions of the same
//                     type of table.
//
//                     Assumes that the source table has its version as the
//                     name of field 1.
//
//  UPDATED     :  2001/02/28
//
//***************************************************************************
function Got_Map_Section (tDestn : TTable;
                          tSource : TTable;
                          var sMapSection : string) : integer;
begin
// Default to an unknown map section name
  sMapSection := '';

// Get the table definition file and the table index for this table.
  if (GotTableInformationFromName(tDestn.TableName)) then
  begin
// Enusre that the source and destination table field definitions are valid.
    tSource.FieldDefs.Update;
    tDestn.FieldDefs.Update;

// Get the version of the source table.
    if (GotSourceVersion) then
    begin
// Check that the source table version number is the same or earlier than the
// destination table version number (otherwise, we would not know how to convert it).
      if (sSourceVer <= tDestn.FieldDefs[1].Name) then
      begin
// Get the name of the map section that will control the copying of data from
// the source table to the destination table
        sMapSection := IntToStr(iTableIndex) + '.' + sSourceVer + 'Map';

// Check that the given map section is usable
        TestMapSection(sMapSection,tDestn);
        !! This function now sets up sDBUpgResult.   Check that it is empty
        result :=
      end // if
      else
// Source table is newer than destination table, so we have no mapping information
        sDBUpgResult := 'An attempt was made to process a table that is newer than the version than is used by this software.' + Chr(13) +
                        'Install the latest version of ' + GetProgramTitle;
    end // if
    else
      sDBUpgResult := 'An attempt was made to process a table that contains no version information.' +
                      #13 +
                      sDBUC_AgentHelp;
  end; // if
end; // Got_Map_Section

//***************************************************************************
//
//  FUNCTION    :  GetOldFieldIndex
//
//  I/P         :  sTableFileName - The filename of the current database
//                       file for the table (as recorded in the database
//                       control file)
//
//                     tOldTable - The table provided, for which we wish to know
//                       an original field index.
//
//                     tLatestFIndex - The index to the field in the current
//                       version of the table identified in sTableFileName.
//
//  O/P         :  result - The index to the same field in the given
//                       (possibly older) version of the table.   The result
//                       is less than 0 if there is an error or no direct field
//                       mapping could be extablished.
//
//  OPERATION   :  Determines the field index that was used in a previous
//                     table that matches the index used in the current version
//                     of that table.
//
//  UPDATED     :  2001/02/28
//
//***************************************************************************
function GetOldFieldIndex(tCurrent : TTable;
                          iCurrentFIndex : integer;
                          tOld : TTable) : integer;
var
  iDBResult : integer;                  // Result of some database upgrade operations
  sMapSection : string;
  sFieldMap :string;
  iDummy : integer;

begin
// Check that we have complete access to the database information file
  if (AccessedUpgradeControlFiles) then
  begin
!!
// Determine the name of the section that controls the mapping.
    iDBResult := Got_Map_Section(tCurrent,tOld,sMapSection);
// Proceed if a mapping section was found
    if (iDBResult = 0) then
    begin
// Read the details of the mapping to the current field index
      sFieldMap := ifDbCtrlFile.ReadString(sMapSection,IntToStr(iCurrentFIndex),'');
// Check if the mapping is for a previous field index to this field index
      if ((sFieldMap<>'') and
          (LeftStr(sFieldMap,2)='fn')) then
      begin
// Extract the original field number
        Val(Copy(sFieldMap,3,255),result,iDummy);
// If it did not convert, flag an error
        if (iDummy<>0) then
            result := -DB_ERR_UPGRADE_MFSRCNUM;
      end // if
      else
        result := -DB_ERR_UPGRADE_NOFI;
    end // if
    else
      result := -iDBResult;

// Free up the database information INI file.
    ifDbCtrlFile.Free;

  end // if
  else
// Could not access the database information file
    result := -DB_ERR_UPGRADE_IFGONE;

end; // GetOldFieldIndex
*)
(*
//***************************************************************************
//
//  FUNCTION    :  DBError_Message
//
//  I/P         :  iErrorNo (integer) - The error number
//
//  O/P         :  result - A string detailing the error information.
//
//  OPERATION   :  Returns a verbal description of a given error number.
//
//  UPDATED     :  2001/02/28
//
//***************************************************************************
function DBError_Message(iErrorNo : integer) : string;
begin
  case iErrorNo of
    DB_ERR_NONE :
      result := 'No error.';
    DB_ERR_UPGRADE_FSEQ :
      result := 'Given field identifiers not sequential.';
    DB_ERR_UPGRADE_FINFO :
      result := 'Invalid field information given.';
    DB_ERR_UPGRADE_IFUNKN :
      result := 'Unknown field type given.';
    DB_ERR_UPGRADE_TFUNKN :
      result := 'Unknown field type found.';
    DB_ERR_UPGRADE_TINFO :
      result := 'Invalid field information found.';
    DB_ERR_UPGRADE_FCOUNT :
      result := 'Field count mismatch.';
    DB_ERR_UPGRADE_VERUNK :
      result := 'Table version unknown.';
    DB_ERR_UPGRADE_VEROLD :
      result := 'Table version is older than that currently being used';
    DB_ERR_UPGRADE_VERHI :
      result := 'A table version newer than that currently being used has been encountered' + Chr(13) +
                'Obtain and install the latest version of this software';
    DB_ERR_UPGRADE_TMISSED :
      result := 'Database table file missing.';
    DB_ERR_UPGRADE_FNBAD :
      result := 'Table file name invalid.';
    DB_ERR_UPGRADE_IFGONE :
      result := 'Upgrade info file unavailable.';
    DB_ERR_UPGRADE_TUNKN :
      result := 'Unknown table.';
    DB_ERR_UPGRADE_MFID :
      result := 'Invalid map field identifier.';
    DB_ERR_UPGRADE_MFSEQ :
      result := 'Given map field identifiers not sequential.';
    DB_ERR_UPGRADE_MFFILL :
      result := 'Invalid map field source.';
    DB_ERR_UPGRADE_MFSRCNUM :
      result := 'Invalid map source field number.';
    DB_ERR_UPGRADE_MFDSTR :
      result := 'Invalid map default string.';
    DB_ERR_UPGRADE_NOFI :
      result := 'No previous field is referenced for a current field.'

    else
      result := 'Unknown database error.';
  end; // case
end; // DBError_Message

*)

//***************************************************************************
initialization
begin
  dbTest := TAbsDatabase.Create(nil);
  dbTest.DatabaseName := WORK_DATABASE_NAME;
  tSource := TABSTable.Create(nil);
  tSource.DatabaseName := WORK_DATABASE_NAME;
end;

//***************************************************************************
finalization
begin
  tSource.Free;
  dbTest.Free;
end;

end.

