unit DBUtilsDBISAM;

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
//      * DBISAM field names can be 30 characters long
//      * Field definition lines can hold a description in the last field.
//
//    Update Date : 2007-08-21
//    Changes Made :
//      * Fix to handle transfer of an illegla date (like 000-00-00)
//
//    Update Date : 2007/07/23
//    Changes Made :
//      * Various items to match with DBUtils, and provide a common, multi-
//        language (work still needed in this unit) upgrade application.
//
//    Update Date : 2007/06/25
//    Changes Made :
//      * RecordAccessMessage now works on a DataSet and not on a Table
//
//    Update Date : 2006/07/14
//    Changes Made :
//      * Added a check for an AfterScroll event in SealTable function
//
//    Update Date : 2006/02/07
//    Changes Made :
//      * Fixed the table identifiers in the warning messages in CheckDatabaseValidity
//      * Took out case sensitivity when checking field names in CheckDatabaseValidity and
//        in SourceTableFieldsMatch
//
//    Update Date : 2005/12/20
//    Changes Made :
//      * Used Try/Except to get rid of some compiler warnings when using Val()
//
//    Update Date : 2005/11/10
//    Changes Made :
//      * Fix number given when warning of an out-of-sequence field in TableFieldDefnsOK
//
//    Update Date : 2005/09/30
//    Changes Made :
//      * Added SealTable
//
//    Update Date : 2005/09/06
//    Changes Made :
//      * First issue for DBISAM
//
//***************************************************************************

interface

{$A-}

uses
  StdCtrls, COMCtrls, Forms, Classes,
  DBISAMTB, DB,
  DKLang;

const
  DBISAM_TABLE_EXT = '.dat';

procedure SetupTable(tGiven : TDBISAMTable;
                     nameDatabase : String;
                     nameTable : String);
procedure SealTable(tTableToSeal : TDBISAMTable);
function ConvertedParadox2DBISAM(DBFolder : String;
                                 ShowDebugMessages : Boolean) : String;
procedure TransferField(tTFSource : TDBISAMTable;
                        tTFDestination : TDBISAMTable;
                        sFieldMap : String;
                        iDestFieldNo : Integer);
procedure TransferRecord(tRecSource : TDBISAMTable;
                         tRecDestination : TDBISAMTable;
                         slMapInfo : TStringList);
function UpgradedTable(iUpgTableIndex : Integer;
                       tableTitle : String;
                       tableDefnResource : String;
                       tableFilename : String;
                       sTableDirectory : String;
                       oProgressMessage : TObject;
                       pbTableRecordProgress : TProgressBar;
                       pbTableIndexProgress : TProgressBar) : Boolean;
procedure UpgradeDatabase(sDBDirectory : String;
                          oProgressMessage : TObject;
                          pbTableContents : TProgressBar;
                          pbTableIndexes : TProgressBar;
                          pbDatabaseProgress : TProgressBar;
                          bRestart : Boolean);
procedure RecreateDatabaseIndexes(sDBDirectory : String;
                                  lProgressMessage : TLabel;
                                  pbTableIndexes : TProgressBar;
                                  pbDatabaseProgress : TProgressBar);
procedure RefreshOpenTables(dmData : TDataModule);
procedure TestMapSection (sMapSection : String;
                          tTargetTable : TDBISAMTable);
procedure CheckDatabaseFiles(sTestDir : String;
                             fAllFiles : Boolean);
procedure CheckTableValidity(filenameTable : String;
                             descriptionTable : String);
procedure CheckDatabaseValidity(sTestDir : String);
function RecordAccessMessage(dsTarget : TDBISAMDataSet) : String;
procedure LoadTableFromDiscToMemory(tDiscTable : TDBISAMTable;
                                    tMemoryTable : TDBISAMTable);
function MovedTable(srcDatabaseName : String;
                    srcTableName : String;
                    destDatabaseName : String;
                    destTableName : String) : boolean;
function MovedToRecord(tTarget : TDBISAMTable;
                      nameField : String;
                      valueField : Variant) : Boolean; overload;
function MovedToRecord(tTarget : TDBISAMTable;
                      idxField : Integer;
                      valueField : Variant) : Boolean; overload;
procedure ClearAndOpenTable(theTable : TDBISAMTable);
procedure CopyFieldToStrings(target : TStrings;
                             source : TDBISAMTable;
                             indexField : Integer);
function GetIndexDefsID(source : TDBISAMTable;
                        indexName : String) : Integer;

(*
function Got_Map_Section (tDestn : TDBISAMTable;
                          tSource : TDBISAMTable;
                          var sMapSection : String) : Integer;
function DBError_Message(iErrorNo : Integer) : String;
function Get_Upgrade_Index(tablename : String;
                           var uiUpgradeIndex : word) : Integer;
function Get_Old_Index(tCurrent : TDBISAMTable;
                       iCurrentFIndex : Integer;
                       tOld : TDBISAMTable) : Integer;
*)

implementation

uses Windows, SysUtils, IniFiles, Controls, Registry, Dialogs, ShellAPI,
     System.UITypes, System.Variants,
     DBISAMCn,
     DBUtilsCommon, Str_Ops, File_Ops, TimeDate, App_Ops, Dialog_Ops;

var
  iIndexesUpdated : Integer;        // Counts the number of tables which had their indexes updated
  iFieldsUpdated : Integer;         // Counts the number of tables which had their fileds updated
  iNewTables : Integer;             // Counts the number of new tables created
  iErrors : Integer;                // Counts of the number of errors encountered
  tDSSource : TDBISAMTable;         // The original DBISAM table, that is to be upgraded
  tDSDestination : TDBISAMTable;    // The target DBISAM table, used to create new or updated tables
  sControl : TDBISAMSession;        // Session used to control session passwords
  verSource : String;               // Table verion number ('Vabc') of the source table (being examined/upgraded)
  bNewTable : Boolean;              // TRUE if there is no exsiting table, and it must be created.

// ***************************************************************************
//
//  FUNCTION  : SetupTable
//
//  I/P       : tGiven : TDBISAMTable - The table to use
//
//              nameDatabase : String - The database name of the table
//
//              nameTable : String - The table name of the table
//
//  O/P       : None
//
//  OPERATION : Closes the table and sets the database and table names
//
/// Date      : 2023-05-25
//
// ***************************************************************************
procedure SetupTable(tGiven : TDBISAMTable;
                     nameDatabase : String;
                     nameTable : String);
begin
  tGiven.Close;
  tGiven.DatabaseName := nameDatabase;
  tGiven.TableName := nameTable;
end; // SetupTable

//***************************************************************************
//
//  FUNCTION  : ConvertedParadox2DBISAM
//
//  I/P       : DBFolder : String -The folder to be examined for Paradox tables
//
//  O/P       : String -Empty if all OK, else an English error message.
//              Note that the only expected error is one that can be described
//              to the user, and they can potentially correct.
//
//  OPERATION : Scan the files in the given database folder.   If any appear to
//              be Paradox tables, use an external converter program to change
//              them to DBISAM.
//
//  UPDATED   : 2016-09-29
//
//***************************************************************************
function ConvertedParadox2DBISAM(DBFolder : String;
                                 ShowDebugMessages : Boolean) : String;
const
  TABLE_CONVERTER = 'BDE2DBISAM.exe';

var
  srParadox : TSearchRec;

begin
  var Attrs : Integer;
  Attrs := 0;
  {$IFDEF MSWINDOWS}
  {$WARN SYMBOL_PLATFORM OFF}
  Attrs := faArchive;
  {$WARN SYMBOL_PLATFORM ON}
  {$ENDIF}
  if (FindFirst(DBFolder + '*.db', Attrs, srParadox) = 0) then
  begin
    if (ShowDebugMessages) then
      Dialog_Ops.MessageDlg('Found Paradox tables in "' + DBFolder + '"',mtInformation,[mbOK],0);
    if (FileExists(ExtractFilePath(Application.ExeName) + TABLE_CONVERTER)) then
    begin
      // Convert each Paradox table into a DBISAM table, using an external program,
      // which uses the BDE.   (That way, this program does not need to have the
      // BDE bundled in its installation.)
      repeat
        if (ShowDebugMessages) then
          Dialog_Ops.MessageDlg('Executing "' +
                                 ExtractFilePath(Application.ExeName) + TABLE_CONVERTER + '" ' +
                                 '"' + DBFolder + srParadox.Name + '"',
                                 mtInformation,[mbOK],0);
        ShellExecute(Application.Handle,'open',
                     PChar('"' + ExtractFilePath(Application.ExeName) + TABLE_CONVERTER + '"'),
                     PChar('"' + DBFolder + srParadox.Name + '"'),'',SW_SHOWNORMAL);
        // Wait here until the Paradox file is deleted.   Allow 10 seconds for this to happen.
        repeat
          Application.ProcessMessages;
        until (not FileExists(DBFolder + srParadox.Name));

      until (FindNext(srParadox) <> 0);
      FindClose(srParadox);
      result := '';
    end // if
    else
    begin
      // Paradox tables exist, but there is no available conversion program
      result := 'The Paradox-to-DBISAM conversion program was not found.' + #13 +
                'Please install this before proceeding.';
      iDBUC_DBUpgErr := ERR_DB_PDX2DBI_INSTALL;
    end; // else
  end // if
  else
  begin
    // No files to be converted
    result := '';
  end;

  FindClose(srParadox);
end;

//***************************************************************************
//
//  FUNCTION  : SealTable
//
//  I/P       : tTableToSeal (TDBISAMTable) - The table, the contents of which
//                must be sealed.
//
//  O/P       : None.
//
//  OPERATION : Opens and Closes the given table, returning to the record
//              that was initially active.
//
//              This function makes the important assumption that the primary
//              key is based on the first field, and can be expressed as a string.
//              Do not use it if this is not the case.
//
//              I had commented this function out, prior to April 2016.   Why?
//
//  UPDATED   : 2005/09/30
//
//***************************************************************************
procedure SealTable(tTableToSeal : TDBISAMTable); overload;
var
  sKeyFieldValue : String;
  sIndex : String;

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
  tTableToSeal.IndexName := '';
  tTableToSeal.SetKey;
  tTableToSeal.Fields[0].AsString := sKeyFieldValue;
  tTableToSeal.GotoKey;
  tTableToSeal.IndexName := sIndex;
end; // SealTable

//***************************************************************************
//
//  FUNCTION  : SourceTableFieldsMatch
//
//  I/P       : sCompareAgainst - The table description/version against
//                which the comparison must be made
//
//  O/P       : Boolean - TRUE if the original and indicated table
//                are the same
//
//  OPERATION : Check whether there is any difference between the
//              fields of the existing table and the fields as defined
//              in the indicated section of the definition file.
//
//  UPDATED   : 2003/08/29
//
//***************************************************************************
function SourceTableFieldsMatch(sCompareAgainst : String) : Boolean;
var
  n : Integer;
  field_nos : TStringList;
  field_info : TStringList;
  field_line : String;            // The ini's line of field information
  field_name : String;            // Used for Add methog, when adding fields
  ftFieldDataType : TFieldType;   // Used for Add methog, when adding fields
  field_size : Word;              // Used for Add methog, when adding fields
  field_required : Boolean;       // Used for Add methog, when adding fields
begin
  // Assume that the table matches the indicated description
  result := TRUE;

  // Create the storage space and read in the list of fields in this table.
  field_nos := TStringList.Create;
  field_info := TStringList.Create;
  mifDBUC_TableDefn.ReadSection('1.'+sCompareAgainst+'Fields',field_nos);
  mifDBUC_TableDefn.ReadSectionValues('1.'+sCompareAgainst+'Fields',field_info);

  // Check the table
  with tDSSource do
  begin
    // Ensure that there are the correct number of fields
    if (FieldDefs.Count <> field_nos.Count) then
    begin
      result := FALSE;
      iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
      sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + verSource + ')' + #13 +
                           'Field Count : ' + IntToStr(FieldDefs.Count) + #13 +
                           sDBUC_VerLatest + ' expects ' + IntToStr(field_nos.Count);
    end // if
    else
    begin
      // Scan through all the fields
      n := 0;
      while (n < FieldDefs.Count-1) and (result) do
      begin
        field_line := field_info.Values[field_nos.Strings[n]];
        // Format of info given appears correct
        field_name := Copy(field_line,1,Pos(',',field_line)-1);

        field_line := Copy(field_line,Pos(',',field_line)+1,255);
        ftFieldDataType := GetANSFieldDataType(field_line[1]);

        field_line := Copy(field_line,Pos(',',field_line)+1,255);
        if (ftFieldDataType = ftString) or
           (ftFieldDataType = ftMemo) or
           (ftFieldDataType = ftGraphic) or
           (ftFieldDataType = ftBytes) then
          field_size := StrToInt(Copy(field_line,1,Pos(',',field_line)-1))
        else
          field_size := 0;

        field_line := Copy(field_line,Pos(',',field_line)+1,255);
        field_required := (field_line[1]='1');

        // Check if there was an error in the field definition
        if (UpperCase(FieldDefs.Items[n].Name)<>UpperCase(field_name)) or
           (FieldDefs.Items[n].DataType<>ftFieldDataType) or
           (FieldDefs.Items[n].Size<>field_size) or
           (FieldDefs.Items[n].Required<>field_required) then
        begin
          result := FALSE;    // Inform user of where and what the error is.
          iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
          sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + verSource + ')' + #$D +
                               sCompareAgainst + ' field ' + IntToStr(n) + ' - ';
          if (UpperCase(FieldDefs.Items[n].Name)<>UpperCase(field_name)) then
            sDBUC_DBUpgResult := sDBUC_DBUpgResult +
                                 'Name: Original = ' + FieldDefs.Items[n].Name +
                                 ', Expected = ' + field_name
          else
            if (FieldDefs.Items[n].DataType<>ftFieldDataType) then
              sDBUC_DBUpgResult := sDBUC_DBUpgResult +
                                   'Type: Original = ' + GetFieldTypeName(FieldDefs.Items[n].DataType,1) +
                                   ', Expected = ' + GetFieldTypeName(ftFieldDataType,1)
            else
              if (FieldDefs.Items[n].Size<>field_size) then
                sDBUC_DBUpgResult := sDBUC_DBUpgResult +
                                     'Size: Original = ' + IntToStr(FieldDefs.Items[n].Size) +
                                     ', Expected = ' + IntToStr(field_size)
              else
                sDBUC_DBUpgResult := sDBUC_DBUpgResult +
                                     'Required: Original = ' + IntToStr(integer(FieldDefs.Items[n].Required)) +
                                     ', Expected = ' + IntToStr(integer(field_required));
        end; // if
        Inc(n);
      end; // while
    end; // else
  end; // with

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
//  I/P       : filenameTable : String -The full file name of the table that
//                we are wanting to upgrade (including the '.dat' extension).
//
//              openExclusive : Boolean - As required
//
//  O/P       : (boolean) - TRUE if the table was accessed and opened
//
//              bNewTable - TRUE if a new table must be created.
//
//  OPERATION : Checks the given file name of the table, and whether
//                it exists and is accessable for upgrading.
//                descriptions.
//
//  UPDATED   : 2023-05-25
//
//***************************************************************************
function AccessedSourceTable(tableFileName : String;
                             tableSession : String;
                             tableTitle : String;
                             tableExclusive : Boolean) : Boolean;
begin
  result := TRUE;

  // Check that the current table file name is valid
  if ((tableFileName = '') or
      (UpperCase(ExtractFileExt(tableFileName)) <> UpperCase(DBISAM_TABLE_EXT))) then
  begin
    iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
    sDBUC_DBUpgResult := 'Table : ' + tableTitle + ' (' + verSource + ')' + #$D +
                         'An invalid filename, ' + tableFileName + ' has been specified.' + #$D +
                         'This table has not been upgraded.';
    result := FALSE;
    Exit;
  end; // if

  // Check whether the table file exists
  if (FileExists(tableFileName)) then
  begin
    // The .dat file of the table file exists.
    // Try to open it as a table.
    try
      with tDSSource do
      begin
        SetupTable(tDSSource, ExtractFilePath(tableFileName), ExtractFileName(tableFileName));
        if (tableSession <> '') then
          SessionName := tableSession;
        if (sDBUC_Password <> '') then
        begin
          sControl.Open;
          sControl.RemoveAllPasswords;
          sControl.AddPassword(sDBUC_Password);
        end;
        // Get exclusive access, as required.
        Exclusive := tableExclusive;
        Open;
      end; // with
      // Flag that it is not necessary to create a new table
      bNewTable := FALSE;
    except
      on E: Exception do
      begin
        // It is most likely that we could not obtain exclusive access to this table
        result := FALSE;
        iDBUC_DBUpgErr := ERR_DB_OTHER;
        if (E is EDatabaseError) and (E is EDBISAMEngineError) then
        begin
          if (EDBISAMEngineError(E).ErrorCode = DBISAM_OSEACCES) then
          begin
            // Access denied error
            iDBUC_DBUpgErr := ERR_DB_ACCESS_DENIED;
            sDBUC_DBUpgResult := 'Table : ' + tableTitle + ' (' + verSource + ')' + #$D +
                                 ifthens(tableExclusive,
                                         'Unable to gain exclusive access to this table.',
                                         'Unable to gain read/write access to this table.') + #$D +
                                 '(Error message "' + E.Message + '")' + #13 +
                                 'Ensure that the table is not currently being accessed by another program or network user.';
          end // if
          else if (EDBISAMEngineError(E).ErrorCode = DBISAM_OSENOENT) then
          begin
            // "Table open fails due to the directory or table files not being present" - V4 Manual
            iDBUC_DBUpgErr := ERR_DB_ACCESS_DENIED;
            sDBUC_DBUpgResult := 'Table : ' + tableTitle + ' (' + verSource + ')' + #$D +
                                 'Table does not exist.' + #$D +
                                 '(Error message "' + E.Message + '")';
          end // if
          else
          begin
            raise Exception.Create('Database engine error ' + IntToStr(EDBISAMEngineError(E).ErrorCode) + #13 +
                                   '"' + E.Message + '"');
          end; // else
        end
        else
        begin
          raise Exception.Create('Unknown or unexpected error has occurred');
        end;
      end; // on
    end; // except
  end // if
  else
  begin
    // Flag that a new table must be created
    bNewTable := TRUE;
    result := FALSE;
    WriteToDBUpgLog('Table does not exist');
  end; // else
end; // AccessedSourceTable

//***************************************************************************
//
//  FUNCTION  : GotSourceVersion
//
//  I/P       : tSource (TDBISAMTable) - The source table.
//
//  O/P       : Boolean - TRUE if the original and desired table
//                differ in any way
//
//              sSourceVer - The version of the tSource table.
//
//  OPERATION : Attempt to extract the Source Table's version from
//                Field 1.
//
//  UPDATED   : 2003/08/29
//
//***************************************************************************
function GotSourceVersion : Boolean;
var
  first_ver : Word;               // Used to identify the first version that we can upgrade

begin
  // Read in the source table's version number (from Field 1)
  if (tDSSource.FieldDefs.Count>1) then
    verSource := UpperCase(tDSSource.FieldDefs.Items[1].Name)
  else
    verSource := 'No version';

  // Check whether the source table version number is available and is valid
  if ((Length(verSource)<>4) or
      (verSource[1]<>'V')) then
  begin
    // The old table's version number was not in the expected place expected place.
    first_ver := 100;
    result := FALSE;
    // Start from the first table version on record, and try to find the first version number
    // that we have used in the ini file. Search only up to Version 4.00
    // The first SHOULD be V1.00.
    while ((first_ver<=400) and (not result)) do
    begin
      verSource := 'V' + IntToStr(first_ver);
      if (mifDBUC_TableDefn.ReadString('1.'+verSource+'Fields','0','')<>'') then
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
  begin
    // The version number was not in the original table and no version info has been
    // found in the ini file.
    iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
    sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + #$D +
                         'Unable to establish the version number, or find version information for this table.';
  end // if
  else
    WriteToDBUpgLog('Table Exists (' + verSource + ')');
end; // GotSourceVersion

//***************************************************************************
//
//  FUNCTION  : CreatedTempTable
//
//  I/P       : current_table (integer) - The table index in the
//                upgrade INI file of the table currently being
//                upgraded.
//
//              table_title (string) - A descriptive title of the
//                table currently being upgraded.
//
//              table_filename (string) - The full path and filename
//                of the table currently being upgraded.
//
//  O/P       : Boolean - TRUE if the temporary table was created.
//
//  OPERATION : Creates a temporary in-memory table, as defined.
//
//              Field and index definitionsa are as per the sections
//              current_table.Fields and current_table.Indexes in the global
//              table definition file.
//
//  UPDATED   : 2023-05-25
//
//***************************************************************************
function CreatedTempTable : Boolean;
var
  n : Integer;
  field_nos : TStringList;
  field_info : TStringList;
  field_line : String;            // The ini's line of field information
  field_name : String;            // Used for Add methog, when adding fields
  field_datatype : TFieldType;    // Used for Add methog, when adding fields
  field_size : Word;              // Used for Add methog, when adding fields
  field_required : Boolean;       // Used for Add methog, when adding fields
  index_nos : TStringList;
  index_info : TStringList;
  index_line : String;            // The ini's line of index information
  index_name : String;            // Used for Add methog, when adding indexes
  index_fields : String;          // Used for Add methog, when adding indexes
  index_noptions : Integer;       // Used to specify the combined index options
  index_options : TIndexOptions;  // Used for Add methog, when adding indexes

begin
  // Initially assume all is OK
  result := TRUE;

  SetupTable(tDSDestination, 'MEMORY', TEMP_TABLE_NAME + DBISAM_TABLE_EXT);

  if (tDSDestination.Exists) then
    tDSDestination.DeleteTable;

  // Clear any fields and indexes in this new table
  tDSDestination.FieldDefs.Clear;
  tDSDestination.IndexDefs.Clear;

  // Define the fields
  field_nos := TStringList.Create;
  try
    field_info := TStringList.Create;   //
    try
      // Read in the list of fields in this table.
      mifDBUC_TableDefn.ReadSection('1.LatestFields',field_nos);
      mifDBUC_TableDefn.ReadSectionValues('1.LatestFields',field_info);

      // Add each of the fields
      for n := 0 to field_nos.Count-1 do
      begin
        field_line := field_info.Values[field_nos.Strings[n]];
        // Format of info given appears correct
        field_name := Copy(field_line,1,Pos(',',field_line)-1);

        field_line := Copy(field_line,Pos(',',field_line)+1,255);
        field_datatype := GetANSFieldDataType(field_line[1]);

        field_line := Copy(field_line,Pos(',',field_line)+1,255);
        if (field_datatype = ftString) or
           (field_datatype = ftMemo) or
           (field_datatype = ftBytes) then
            field_size := StrToInt(Copy(field_line,1,Pos(',',field_line)-1))
        else
            field_size := 0;

        field_line := Copy(field_line,Pos(',',field_line)+1,255);
        field_required := (field_line[1]='1');

        tDSDestination.FieldDefs.Add(field_name,field_datatype,field_size,field_required);
      end; // for
    finally
      field_info.Free;
    end;
  finally
    field_nos.Free;
  end; // finally

  // Define the indexes
  index_nos := TStringList.Create;
  try
    index_info := TStringList.Create;
    try
      // Read in the list of indexes in this table.
      mifDBUC_TableDefn.ReadSection('1.LatestIndexes',index_nos);
      mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',index_info);

      // Add each of the indexes
      for n := 0 to index_nos.Count-1 do
      begin
        index_line := index_info.Values[index_nos.Strings[n]];
        index_name := Copy(index_line,1,Pos(',',index_line)-1);

        index_line := Copy(index_line,Pos(',',index_line)+1,255);
        index_fields := Copy(index_line,1,Pos(',',index_line)-1);

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

        tDSDestination.IndexDefs.Add(index_name,index_fields,index_options);
      end; // for
    finally
      index_info.Free;
    end; // finally
  finally
    index_nos.Free;
  end; // finally

  try
    tDSDestination.CreateTable;

    WriteToDBUpgLog('Temporary upgrade table created');
  except
    on E:EDatabaseError do
    begin
      result := FALSE;
      WriteToDBUpgLog('Error creating temporary table : "' + E.Message + '"');
      iDBUC_DBUpgErr := ERR_DB_OTHER;
      sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + verSource + ')' + #$D +
                           'Unable to create a temporary upgrade table.' + #$D +
                           'This table has not been upgraded.' + #$D + #$D +
                           '(Error Description : ' + E.Message + ')';
    end; // on
  end; // except
end; // CreatedTempTable

//***************************************************************************
//
//  FUNCTION    :   TransferField
//
//  I/P         :   tTFSource (TDBISAMTable) - The table containing the
//                        source data.
//
//                      tTFDestination (TDBISAMTable) - The table containing the
//                        destination data.
//
//                      sFieldMap (string) - The details of what to put
//                        into the field in the destination table.
//
//                      iDestnFieldNo (integer) - The destination field that is
//                        being filled in.
//
//  O/P         :   sDBUC_DBUpgResult (string) - Empty string if the operation
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
procedure TransferField(tTFSource : TDBISAMTable;
                        tTFDestination : TDBISAMTable;
                        sFieldMap : String;
                        iDestFieldNo : Integer);
var
  iSourceFieldNo : Integer;             // Field number to be used from source file
  dummy : Integer;                      // Used in string to int conversions
  def_int : Integer;                    // Default integer value for a field
  def_real : Real;                      // Default real value for a field
  def_string : String;                  // Default string value for a field

begin

  // Test for whether the source data has a value (either a default or from the source field)
  if (sFieldMap<>'') then
  begin
    // Check whether the source data comes from a field in the source table
    if (Copy(sFieldMap,1,2)='fn') then
    begin
      // Extract the source field number
      Val(Copy(sFieldMap,3,255),iSourceFieldNo,dummy);
      // Leave destn alone if source field is Null
      if (not tTFSource.Fields[iSourceFieldNo].IsNull) then
        case tTFDestination.FieldDefs[iDestFieldNo].DataType of

          ftString :
            tTFDestination.Fields[iDestFieldNo].AsString := tTFSource.Fields[iSourceFieldNo].AsString;

          ftSmallint ,
          ftInteger ,
          ftWord,
          ftLargeInt,
          ftAutoInc :
            tTFDestination.Fields[iDestFieldNo].AsInteger := tTFSource.Fields[iSourceFieldNo].AsInteger;

          ftBoolean :
            // This permits integers to be copied to booleans, but DBISAM can not treat tfBoolean as an integer
            // so needs a special case.
            if (tTFSource.Fields[iSourceFieldNo].DataType = ftBoolean) then
              tTFDestination.Fields[iDestFieldNo].AsBoolean := tTFSource.Fields[iSourceFieldNo].AsBoolean
            else
              tTFDestination.Fields[iDestFieldNo].AsBoolean := (tTFSource.Fields[iSourceFieldNo].AsInteger <> 0);

          ftFloat ,
          ftCurrency ,
          ftBCD :
            tTFDestination.Fields[iDestFieldNo].AsFloat := tTFSource.Fields[iSourceFieldNo].AsFloat;

          ftDate,
          ftTime,
          ftDateTime :
            try
              // I have seen dates of 0000-00-00 which cause an error, so I've added this try-except
              tTFDestination.Fields[iDestFieldNo].AsDateTime := tTFSource.Fields[iSourceFieldNo].AsDateTime;
            except
              tTFDestination.Fields[iDestFieldNo].Clear;
            end; // except

          else
            tTFDestination.Fields[iDestFieldNo].Assign(tTFSource.Fields[iSourceFieldNo]);
        end; // case
    end // if
    else
      // Test if the default value for this field is a string
      if (sFieldMap[1]='"') then
      begin
        // Extract the string, clipping off the single quotes
        def_string := Copy(sFieldMap,2,255);
        def_string := Copy(def_string,1,Length(def_string)-1);
        case tTFDestination.FieldDefs[iDestFieldNo].DataType of
          ftString :
            tTFDestination.Fields[iDestFieldNo].AsString := def_string;
          ftBoolean :
            tTFDestination.Fields[iDestFieldNo].AsBoolean := (def_string = 'Y');
          else
          begin
            iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
            sDBUC_DBUpgResult := 'Attempt to assign a default string value to a ' +
                                 GetFieldTypeName (tTFDestination.FieldDefs[iDestFieldNo].DataType,1) +
                                 ' field.';
            Inc(iErrors);
          end; // else
        end; // case
      end // if
      else
      begin
        // Test if the default value for this field is an integer
        Val(sFieldMap,def_int,dummy);
        if (dummy=0) then // If so...
        begin
          case tTFDestination.FieldDefs[iDestFieldNo].DataType of
            ftString,
            ftSmallint,
            ftInteger,
            ftWord,
            ftAutoInc :
              tTFDestination.Fields[iDestFieldNo].AsInteger := def_int;

            ftBoolean :
              tTFDestination.Fields[iDestFieldNo].AsBoolean := (def_int<>0);

            ftFloat ,
            ftCurrency ,
            ftBCD :
              tTFDestination.Fields[iDestFieldNo].AsFloat := def_int;

            ftDate,
            ftTime,
            ftDateTime :
              tTFDestination.Fields[iDestFieldNo].AsDateTime := def_int;

            else
            begin
              iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
              sDBUC_DBUpgResult := 'Attempt to assign a default integer value to a ' +
                                   GetFieldTypeName (tTFDestination.FieldDefs[iDestFieldNo].DataType,1) +
                                   ' field.';
              Inc(iErrors);
            end; // option
          end; // case
        end // if
        else
        begin
          // Test if the default value for this field is a real
          Val(sFieldMap,def_real,dummy);
          if (dummy=0) then   // If so...
          begin
            case tTFDestination.FieldDefs[iDestFieldNo].DataType of
              ftString ,
              ftFloat ,
              ftCurrency ,
              ftBCD :
                tTFDestination.Fields[iDestFieldNo].AsFloat := def_real;

              ftDate,
              ftTime,
              ftDateTime :
                tTFDestination.Fields[iDestFieldNo].AsDateTime := def_real;

              else
              begin
                iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
                sDBUC_DBUpgResult := 'Attempt to assign a default real value to a ' +
                                     GetFieldTypeName (tTFDestination.FieldDefs[iDestFieldNo].DataType,1) +
                                     ' field.';
                Inc(iErrors);
              end; // option
            end; // case
          end // if
        end; // else
      end; // else
  end; // else
end; // TransferField

//***************************************************************************
//
//  FUNCTION    :   TransferRecord
//
//  I/P         :   tRecSource (TDBISAMTable) : The table from which the current
//                        record is being transferred.
//
//                      tRecDestination (TDBISAMTable) : The table to which the
//                        record is being transferred.
//
//                      slMapInfo (TStringLinst) : The mapping information from
//                        the table definition file for transferring fields
//                        from the version of the table represented by the source,
//                        to the destination table.
//
//  O/P         :   sDBUC_DBUpgResult - Contains an error description, if any.
//
//  OPERATION   :   Transfer all fields in the current record to a new record
//                      in the destination table, using the given mapping information.
//
//  UPDATED     :   2004/11/02
//
//***************************************************************************
procedure TransferRecord(tRecSource : TDBISAMTable;
                         tRecDestination : TDBISAMTable;
                         slMapInfo : TStringList);
var
  n : Integer;
begin
  tRecDestination.Append;
  // Cycle through all fields
  n := 0;
  while ((n <= tRecDestination.FieldCount-1) and (sDBUC_DBUpgResult = ''))  do
  begin
    // Transfer each individual field within the record
    TransferField(tRecSource,tRecDestination,slMapInfo.Values[IntToStr(n)],n);
    Inc(n);
  end; // for

  // Store the record if it was correctly transferred.
  if (sDBUC_DBUpgResult = '') then
    tRecDestination.Post
  else
    tRecDestination.Cancel;
end; // TransferRecord

//***************************************************************************
//
//  FUNCTION  : TransferTableContents
//
//  I/P       : oTransferMessage : TObject - The TLabel or TStatusPanel to
//                be used to display the progress message.   Nil if not required.
//
//              pbRecordProgress (TProgressBar) : The progress bar
//                to show the progress in transferring all table
//                records.   Nil if not required.
//
//              pbIndexProgress (TProgressBar) : The progress bar
//                to show the progress in creating the table indexes.
//                Nil if not required.
//
//              tDSDestination : The destination table.
//
//              tSource : The source table
//
//  O/P       : Boolean -TRUE if the data was transferred
//
//  OPERATION : Transfer all records in the source destination into
//              the destination table, using the given mapping information.
//
//  UPDATED   : 2013-06-20
//
//***************************************************************************
procedure TransferTableContents(oTransferMessage : TObject;
                                pbRecordProgress : TProgressBar;
                                pbIndexProgress : TProgressBar);
var
  map_info : TStringList;
  sTemp : String;
  iRecordsTotal : Integer;
  iRecordsDone : Integer;

begin
  // Check that the field mapping information is valid
  TestMapSection('1.' + verSource + 'Map',tDSDestination);

  // Continue if the mapping info is OK
  if (sDBUC_DBUpgResult = '') then
  begin
    // Re-open the source table exclusively. \
    // This is to prevent any data changes during this transfer operation
    // Note that exception handling is provided in the calling function.
    tDSSource.Close;
    tDSSource.Exclusive := TRUE;
    tDSSource.Open;

    // Open the destination table
    tDSDestination.Open;

    // Set up the transfer progress bars
    iRecordsTotal := tDSSource.RecordCount;
    iRecordsDone := 0;
    if (pbRecordProgress <> nil) then
    begin
      pbRecordProgress.Max := iRecordsTotal;
      pbRecordProgress.Position := iRecordsDone;
    end; // if
    if (pbIndexProgress <> nil) then
    begin
      pbIndexProgress.Max := iRecordsTotal;
      pbIndexProgress.Position := iRecordsDone;
    end; // if

    // Create the storage space and read in the mapping list for this table upgrade.
    map_info := TStringList.Create;
    mifDBUC_TableDefn.ReadSectionValues('1.' + verSource + 'Map',map_info);

    StartFastTimer(1);

    // Scan through all the records in the source table, stopping if we get an error
    tDSSource.First;
    while ((not tDSSource.EOF) and (sDBUC_DBUpgResult = '')) do
    begin
      // Transfer this record to the destination table.
      TransferRecord(tDSSource, tDSDestination, map_info);

      // Keep the user informed as to the number of records that have been transferred
      Inc(iRecordsDone);
      if (pbRecordProgress <> nil) then
        pbRecordProgress.Position := pbRecordProgress.Position + 1;
      if (pbIndexProgress <> nil) then
        pbIndexProgress.Position := pbIndexProgress.Position + 1;
      if (oTransferMessage <> nil) then
      begin
//        dRemaining := (iRecordsTotal - iRecordsDone) * (GetFastTimer(1) / iRecordsDone);
        sTemp := Format(LangManager.ConstantValue['sUpgradingTheSTable'],[sDBUC_TableTitle]);
        // The time prediction was problematic, especially with wild card tables.
        // As long as the user sees a moving progress bar, they should be happy.
//        sTemp := 'Upgrading the ' + sDBUC_TableTitle +
//                 ' table (' +
//                 IntToStr(Trunc(dRemaining / 60000)) + 'm ' +
//                 IntToStr(Trunc(dRemaining - 60000*Trunc(dRemaining / 60000)) div 1000) + 's till completion)';
        if (oTransferMessage <> nil) then
        begin
          if (oTransferMessage is TStatusPanel) then
             (oTransferMessage as TStatusPanel).Text := sTemp
          else
            if (oTransferMessage is TLabel) then
               (oTransferMessage as TLabel).Caption := sTemp;
        end; // if
      end; // if
      if (((pbRecordProgress <> nil) or
           (pbIndexProgress <> nil) or
           (oTransferMessage <> nil)) and ((iRecordsDone mod 100) = 0)) then
        Application.ProcessMessages;

      if ((pbRecordProgress <> nil) and (sDBUC_DBUpgResult <> '')) then
        WriteToDBUpgLog(IntToStr(pbRecordProgress.Position) + ':' + tDSDestination.Fields[0].AsString);

      tDSSource.Next;
    end; // while

    // Close down the destination table
    tDSDestination.Close;

    map_info.Free;
  end; // if

  // Count any errors encountered.
  if (sDBUC_DBUpgResult <> '') then
    Inc(iErrors);

  tDSSource.Close;
end; // TransferTableContents

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
function SourceTableIndexesMatch(bTestAll : Boolean) : Boolean;
var
  n,m : Integer;
  slIndexNos : TStringList;
  slIndexInfo : TStringList;
  sIndexLine : String;            // The ini's line of index information
  bFound : Boolean;
  sIndexName : String;
  sIndexFields : String;
  iIndexNumericalOptions : Integer;
  setIndexOptions : TIndexOptions;
  iIndexesToTest : Integer;
begin
// Assume that the indexes in the table match the indicated latest index descriptions
  result := TRUE;

  slIndexNos := TStringList.Create;    // Create the storage space and read in the
  slIndexInfo := TStringList.Create;   // list of fields in this table.
  mifDBUC_TableDefn.ReadSection('1.LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',slIndexInfo);

// Check the table
  with tDSSource do
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
    if (((bTestAll) and (tDSSource.IndexDefs.Count=iIndexesToTest)) or
        ((not bTestAll) and (tDSSource.IndexDefs.Count>=iIndexesToTest))) then
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
procedure UpgradeIndexes(bCreateAll : Boolean;
                         pbIndexProgress : TProgressBar);
var
  slIndexNos : TStringList;
  slIndexInfo : TStringList;
  n,m : Integer;
  sIndexName : String;
  sIndexFields : String;
  setIndexOptions : TIndexOptions;
  bProceed : Boolean;
  bFound : Boolean;
begin
// Create the storage space and read in the list of fields in this table.
  slIndexNos := TStringList.Create;
  slIndexInfo := TStringList.Create;
  mifDBUC_TableDefn.ReadSection('1.LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',slIndexInfo);

// Check the table and ensure that we have the correct index defs for the table.
  tDSSource.IndexDefs.Update;

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
    while (tDSSource.IndexDefs.Count > 0) do
    begin
      WriteToDBUpgLog('Deleting index ' + tDSSource.IndexDefs.Items[0].Name);
      tDSSource.DeleteIndex(tDSSource.IndexDefs.Items[0].Name);
      tDSSource.IndexDefs.Update;
    end; // for
  end // if
  else
  begin
// Delete any indexes that may exist in the table but are not defined in the control file.
    n := 0;
    while (n < tDSSource.IndexDefs.Count) do
    begin
// Try to find the index in the definitions file
      m := 0;
      bFound := FALSE;
      while ((m < slIndexNos.Count) and (not bFound)) do
      begin
// Get the index information - this has already been checked, so we can assume no errors
        GotIndexInfo(slIndexInfo.Values[slIndexNos.Strings[m]],
                     sIndexName,sIndexFields,setIndexOptions);
        if ((UpperCase(sIndexName) = UpperCase(tDSSource.IndexDefs.Items[n].Name)) and
              (UpperCase(sIndexFields) = UpperCase(tDSSource.IndexDefs.Items[n].Fields)) and
              (setIndexOptions = tDSSource.IndexDefs.Items[n].Options)) then
          bFound := TRUE
        else
          Inc(m);
      end; // while
// Check whether the index was found in the Latest index definitions file
      if ((not bFound) and (slIndexNos.Count > 0)) then
      begin
// If not, delete the index from the table, and restart the scanning
        WriteToDBUpgLog('Deleting index ' + tDSSource.IndexDefs.Items[n].Name);
        tDSSource.DeleteIndex(tDSSource.IndexDefs.Items[n].Name);
        tDSSource.IndexDefs.Update;
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
    while ((m < tDSSource.IndexDefs.Count) and (not bFound)) do
    begin
      if ((UpperCase(sIndexName) = UpperCase(tDSSource.IndexDefs.Items[m].Name)) and
          (UpperCase(sIndexFields) = UpperCase(tDSSource.IndexDefs.Items[m].Fields)) and
          (setIndexOptions = tDSSource.IndexDefs.Items[m].Options)) then
        bFound := TRUE;
      Inc(m);
    end; // while
// Check whether we found the required index
    if (not bFound) then
    begin
// If not, try to create it
      try
        tDSSource.AddIndex(sIndexName,sIndexFields,setIndexOptions);
        WriteToDBUpgLog('Added index ' + sIndexName);
// Update the progress bar
        if (pbIndexProgress <> nil) then
        begin
          pbIndexProgress.Position := pbIndexProgress.Position + 1;
          pbIndexProgress.Update;
        end; // if
      except
        bProceed := FALSE;
        iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT; // Most likely
        sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + verSource + ')' + #$D +
                             'Unable to create index "' + sIndexName + '"' + #$D +
                             'This table has not been upgraded.';
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
//  FUNCTION  : UpgradedTable
//
//  I/P       : iUpgTableIndex : Integer - If the DB Control file is being
//                used, this is the index number of the table to be upgraded.
//                Otherwise, -1
//
//              tableTitle : String - If upgrading a named table, this is the
//                descriptive title.
//
//              tableDefnResource : String - If upgrading a named table, this
//                is the name of the table definition resource.
//
//              tableFilename : String - If upgrading a named table that uses
//                the above definition file, but a different table name, this
//                is the filename of the table.   Otherwise '' to use the same
//                base name as the table definition file. The '.dat' extension
//                is not necessary.
//
//              sTableDirectory : string - Location of the database
//
//              oProgressMessage : TObject - Either a TStatusPanel or a TLabel
//                where the progress will be indicated
//
//              pbTableRecordProgress : TProgressBar -
//
//              pbTableIndexProgress : TProgressBar -
//
//  O/P       : Boolean -TRUE if the table was upgraded.
//                FALSE otherwise.
//
//  OPERATION : Performs a complete upgrade on the indicated DBISAM table
//
//  UPDATED   : 2020-10-19
//
//***************************************************************************
function UpgradedTable(iUpgTableIndex : Integer;
                       tableTitle : String;
                       tableDefnResource : String;
                       tableFilename : String;
                       sTableDirectory : String;
                       oProgressMessage : TObject;
                       pbTableRecordProgress : TProgressBar;
                       pbTableIndexProgress : TProgressBar) : Boolean;
begin
  // Renew the hourglass cursor on each table
//  Screen.Cursor := crHourGlass;

  if (iUpgTableIndex <> -1) then
  begin
    // Get information from the DB Control file
    GotTableInformationFromIndex(iUpgTableIndex);
    sDBUC_TableTitle := mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iUpgTableIndex),'');
  end
  else
  begin
    // Use the given information for this table
    GotTableInformationFromName(tableDefnResource);
    if (tableFilename <> '') then
      sDBUC_TableFilename := tableFilename;
    sDBUC_TableTitle := tableTitle;
  end;

  // Show the user what we are doing
  if (oProgressMessage <> nil) then
  begin
    if (oProgressMessage is TStatusPanel) then
       (oProgressMessage as TStatusPanel).Text := 'Upgrading the ' + sDBUC_TableTitle + ' table...'
    else
      if (oProgressMessage is TLabel) then
         (oProgressMessage as TLabel).Caption := 'Upgrading the ' + sDBUC_TableTitle + ' table...';
  end; // if

  // Add the directory
  sDBUC_TableFilename := sTableDirectory + sDBUC_TableFilename;
  WriteToDBUpgLog(#$D + IntToStr(iUpgTableIndex) + '. Upgrading ' + sDBUC_TableTitle + ' DBISAM table');

  // Update the Table progress bars
  if (pbTableRecordProgress <> nil) then
  begin
    pbTableRecordProgress.Position := 0;
    pbTableRecordProgress.Update;
  end;
  if (pbTableIndexProgress <> nil) then
  begin
    pbTableIndexProgress.Position := 0;
    pbTableIndexProgress.Update;
  end;

  // Start off with no errors for this table
  iDBUC_DBUpgErr := ERR_DB_NONE;
  sDBUC_DBUpgResult := '';

  if (AccessedSourceTable(sDBUC_TableFilename,sDBUC_Session, sDBUC_TableTitle, FALSE) or
      (bNewTable)) then
  begin
    // The source table name is accessible (non-exclusively), or it is a new table

    if ((bNewTable) or (GotSourceVersion)) then
    begin
      // This is a new table, or the source table version has been read from
      // the name of Field[0] (a method that this system uses for table version ID)

      if ((GotLatestVersion) and
          (TableFieldDefnsOK('Latest')) and
          (LatestIndexDefnsOK)) then
      begin
        // The field and index definitions for the latest version of this table
        // are available and valid.

        if ((bNewTable) or (VersionUpgradable(sDBUC_TableTitle,verSource))) then
        begin
          // This a new table, or the source table version is at or earlier than
          // the latest table definition i.e. we know how to handle it.

          if ((bNewTable) or (TableFieldDefnsOK(verSource))) then
          begin
            // This is a new table, or the source table field definitions are
            // available and valid.

            if ((bNewTable) or (SourceTableFieldsMatch(verSource))) then
            begin
              // The source table has fields that match the expected fields for
              // its version

              if ((bNewTable) or
                  (not (SourceTableFieldsMatch('Latest'))) or
                  (not (SourceTableIndexesMatch(FALSE)))) then
              begin
                // Either its a new table, or there is a mismatch between the
                // source table version and the latest table field definitions,
                // or the primary index has changed.

                // Clear any "error message" that may have been generated by the field match or index
                // match checks above.
                iDBUC_DBUpgErr := ERR_DB_NONE;
                sDBUC_DBUpgResult := '';

                if ((CreatedTempTable) and
                    (sDBUC_DBUpgResult = '')) then
                begin
                  // A temporary table, of the required schema has been created.

                  if (not bNewTable) then
                  begin
                    // Transfer the data from the existing table.
                    // Exclusivity to the source table will be required,
                    // to prevent data changes during in mid-transfer.
                    try
                      TransferTableContents(
                        oProgressMessage, pbTableRecordProgress, pbTableIndexProgress
                      );
                    except
                      on E: Exception do
                        sDBUC_DBUpgResult := 'Table : ' + tableTitle + ' (' + verSource + ')' + #$D +
                                             'Unable to gain exclusive access to this table.' + #$D +
                                             '(Error message "' + E.Message + '")' + #13 +
                                             'Ensure that the table is not currently being accessed by another program or network user.';
                    end; // except
                  end;

                  if ((bNewTable) or (sDBUC_DBUpgResult = '')) then
                  begin
                    // With a new table, or transferred contents of an existing
                    // table, move the table to the destination.
                    tDSDestination.CopyTable(
                      ExtractFilePath(sDBUC_TableFilename),
                      ExtractFileName(sDBUC_TableFilename)
                    );
                    tDSDestination.DeleteTable;
                    WriteToDBUpgLog('Temporary table renamed');

                    // Count the changes that were made
                    if (bNewTable) then
                      Inc(iNewTables)
                    else
                      Inc(iFieldsUpdated);
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
                  Inc(iIndexesUpdated);
                end; // if
              end; // else
            end; // if
          end; // if
        end; // if
      end; // if
    end; // if
  end; // if
  // At this point, only display errors for a developer's attention
  if ((sDBUC_DBUpgResult<>'') and
      ((iDBUC_DBUpgErr = ERR_DB_DEVELOPMENT))) then
  begin
    // Restore the cursor for the prompt
    Dialog_Ops.MessageDlg(sDBUC_DBUpgResult,mtError,[mbOK],0);
    WriteToDBUpgLog(sDBUC_DBUpgResult);
    Inc(iErrors);
  end; // if
  WriteToDBUpgLog('Finished with ' + sDBUC_TableTitle + ' table (' + DateTimeToStr(Now) + ')');
  // Close the table that we have just worked on, just in case it was not yet closed
  if (tDSSource.State <> dsInactive) then
    tDSSource.Close;
  result := TRUE;

//  Screen.Cursor := crDefault;
end; // UpgradedTable

//***************************************************************************
//
//  FUNCTION  : UpgradeDatabase
//
//  I/P       : sDBDirectory - The directory containing the database
//                to be upgraded.
//
//              oProgressMessage : TObject - Either a TLabel or a StatusBar
//                Panel that will show what is happening during the upgrade.
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
//                how progress i being made on the entire database.
//
//              bRestart (boolean) - TRUE to cause the database progress
//                bar to be reset back to zero.
//
//  O/P       :
//
//  OPERATION : Performs a complete upgrade on the indicated database
//
//  UPDATED   : 2004/03/10
//
//***************************************************************************
procedure UpgradeDatabase(sDBDirectory : String;
                          oProgressMessage : TObject;
                          pbTableContents : TProgressBar;
                          pbTableIndexes : TProgressBar;
                          pbDatabaseProgress : TProgressBar;
                          bRestart : Boolean);
var
  idxTable : Integer;
  searchrec : TSearchRec;       // Search Record for finding individual tables in wildcard definitions

begin
  WriteToDBUpgLog('');
  WriteToDBUpgLog('Create/Upgrade DBISAM Database');
  WriteToDBUpgLog('Target Database Directory : ' + sDBDirectory);
  WriteToDBUpgLog('Starting : ' + DateTimeToStr(Now));

  // Set up the progress bars, if specified
  if (pbDatabaseProgress <> nil) then
  begin
    pbDatabaseProgress.Max := iDBUC_iTablesInDB;
    if (bRestart) then
      pbDatabaseProgress.Position := 0;
  end; // if
  if (pbTableContents <> nil) then
    pbTableContents.Position := 0;
  if (pbTableIndexes <> nil) then
    pbTableIndexes.Position := 0;

  // Start the whole operation with no errors
  iDBUC_DBUpgErr := ERR_DB_NONE;


  sDBUC_DBUpgResult := '';

  // Cycle through all the tables to be upgraded, stopping if there are any errors.
  WriteToDBUpgLog('Tables in database : ' + IntToStr(iDBUC_iTablesInDB));
  idxTable := 1;
  while ((sDBUC_DBUpgResult = '') and
         (idxTable <= iDBUC_iTablesInDB)) do
  begin
    GotTableInformationFromIndex(idxTable);
    // Check if this is a set of tables, with a naming wildcard,
    // rather than an individual table.
    if (Pos('*', sDBUC_TableFilename) <> 0) then
    begin
       // With a wildcard table definition, we can only upgrade tables that are existing
       // (We would not know how to name any new tables!)
       // Count the wildcard tables
       if (pbDatabaseProgress <> nil) then
       begin
         pbDatabaseProgress.Max := pbDatabaseProgress.Max - 1 +
                                   CountFiles(sDBDirectory + ChangeFileExt(sDBUC_TableFilename,DBISAM_TABLE_EXT), faArchive);
       end; // if
       // Iterate through all existing wildcard tables.
      var Attrs : Integer;
      Attrs := 0;
      {$IFDEF MSWINDOWS}
      {$WARN SYMBOL_PLATFORM OFF}
      Attrs := faArchive;
      {$WARN SYMBOL_PLATFORM ON}
      {$ENDIF}
       if (FindFirst(sDBDirectory + ChangeFileExt(sDBUC_TableFilename,DBISAM_TABLE_EXT), Attrs, searchrec) = 0) then
       begin
//         // Adjust this progress bar (and below) to show progress in wildcard tables
//         if (pbDatabaseProgress <> nil) then
//           pbDatabaseProgress.Max := pbDatabaseProgress.Max - 1;

         repeat
           // Reload the original wildcard table file name as this will have been
           // set to an actual table file name in each iteration
           GotTableInformationFromIndex(idxTable);
           WriteToDBUpgLog('Got info for : ' + IntToStr(idxTable));
           // Upgrade the table
           if (UpgradedTable(-1, mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(idxTable),''),
                             SearchAndReplace(sDBUC_TableFilename,'*',''), searchrec.Name, sDBDirectory,
                             oProgressMessage, pbTableContents, pbTableIndexes)) then
           begin
             // Ensure that the Table progress bars are at the end
             if (pbTableContents <> nil) then
             begin
               pbTableContents.Position := pbTableContents.Max;
               pbTableContents.Update;
             end; // if
             if (pbTableIndexes <> nil) then
             begin
               pbTableIndexes.Position := pbTableIndexes.Max;
               pbTableIndexes.Update;
             end; // if
             // Update the Database progress bar
             if (pbDatabaseProgress <> nil) then
             begin
//               pbDatabaseProgress.Max := pbDatabaseProgress.Max + 1;
               pbDatabaseProgress.Position := pbDatabaseProgress.Position + 1;
               pbDatabaseProgress.Update;
             end; // if
           end; // if
         until (FindNext(searchrec) <> 0);
       end;
       SysUtils.FindClose(searchrec);
    end // if
    else
    begin
      // Upgrade/transfer/create the table
      if (UpgradedTable(idxTable,'','','',sDBDirectory,oProgressMessage,pbTableContents,pbTableIndexes)) then
      begin
        // Ensure that the Table progress bars are at the end
        if (pbTableContents <> nil) then
        begin
          pbTableContents.Position := pbTableContents.Max;
          pbTableContents.Update;
        end; // if
        if (pbTableIndexes <> nil) then
        begin
          pbTableIndexes.Position := pbTableIndexes.Max;
          pbTableIndexes.Update;
        end; // if
        // Update the Database progress bar
        if (pbDatabaseProgress <> nil) then
        begin
          pbDatabaseProgress.Position := pbDatabaseProgress.Position + 1;
          pbDatabaseProgress.Update;
        end; // if
      end; // if
    end; // else

    Inc(idxTable);
  end; // while

  // Wipe the activity message
  if (oProgressMessage <> nil) then
  begin
    if (oProgressMessage is TStatusPanel) then
       (oProgressMessage as TStatusPanel).Text := ''
    else
      if (oProgressMessage is TLabel) then
         (oProgressMessage as TLabel).Caption := '';
  end; // if

  WriteToDBUpgLog(GetDBUpgResults);
end; // UpgradeDatabase

//***************************************************************************
//
//  FUNCTION  : ReindexTable
//
//  I/P       : iRITableIndex - The index number of the table to be
//                re-indexed.
//
//  O/P       :
//
//  OPERATION : Performs a complete recreation of the indexes for the
//                indicated table.
//
//  UPDATED   : 2020-10-19
//
//***************************************************************************
procedure ReindexTable(iRITableIndex : Integer;
                       sTableDirectory : String;
                       lProgressMessage : TLabel;
                       pbTableIndexProgress : TProgressBar);
begin
  // Renew the hourglass cursor on each table
//  Screen.Cursor := crHourGlass;

  // Get the descriptive name of the table being upgraded
  sDBUC_TableTitle := mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iRITableIndex),'');
  // Show the user what we are doing
  if (lProgressMessage <> nil) then
    lProgressMessage.Caption := 'Upgrading the ' + sDBUC_TableTitle + ' table...';

  GotTableInformationFromIndex(iRITableIndex);
  // Add the directory
  sDBUC_TableFilename := sTableDirectory + sDBUC_TableFilename;
  WriteToDBUpgLog(#$D + IntToStr(iRITableIndex) + '. Upgrading ' + sDBUC_TableTitle + ' table');

  // Update the Table progress bar
  if (pbTableIndexProgress <> nil) then
  begin
    pbTableIndexProgress.Position := 0;
    pbTableIndexProgress.Update;
  end; // if

  // Delete any existing indexes.   We must do this before trying to open the table as any corrupt
  // indexes will prevent access to the table. (!! This statement is correct for Paradox, but does it hold for DBISAM?)
  DeletedFiles(ChangeFileExt(sDBUC_TableFilename,'.IDX'),0,0.0);

  // Start off with no errors for this table
  iDBUC_DBUpgErr := ERR_DB_NONE;
  sDBUC_DBUpgResult := '';
  // Check whether the source table name is OK, and whether it exists
  if (AccessedSourceTable(sDBUC_TableFilename, sDBUC_Session,sDBUC_TableTitle, TRUE)) then
    // If this is an existing table, get the version of the table that we are about to upgrade
    if ((not bNewTable) and (GotSourceVersion)) then
      // Check that the table definition for the latest version of the table is OK
      if ((GotLatestVersion) and
          (TableFieldDefnsOK('Latest')) and
          (LatestIndexDefnsOK)) then
        // The source should be same or earlier than the latest, otherwise we do
        // not know how to handle it (i.e. its from newer software)
        if (VersionUpgradable(sDBUC_TableTitle,verSource)) then
          // Check that the version description for the source table is OK
          if (TableFieldDefnsOK(verSource)) then
            // Check that the table is correct according to the latest version information
            if (SourceTableFieldsMatch('Latest')) then
            begin
              // Recreate the indexes
              UpgradeIndexes(TRUE,pbTableIndexProgress);
              //!! Do we need this TRUE and FALSE thing now that we actually
              // delete all the indexes for the file.?
              Inc(iIndexesUpdated);
            end; // if
  // Display the error message, if one was set up
  if (sDBUC_DBUpgResult <> '') then
  begin
    // Restore the cursor for the prompt
    Dialog_Ops.MessageDlg(sDBUC_DBUpgResult,mtError,[mbOK],0);
    WriteToDBUpgLog(sDBUC_DBUpgResult);
    Inc(iErrors);
  end; // if
  WriteToDBUpgLog('Finished with ' + sDBUC_TableTitle + ' table');
  // Close the table that we have just worked on, just in case it was not yet closed
  if (tDSSource.State <> dsInactive) then
    tDSSource.Close;

//  Screen.Cursor := crDefault;
end; // ReindexTable

//***************************************************************************
//
//  FUNCTION  : RecreateDatabaseIndexes
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
//                how progress i being made on the entire database.
//
//  O/P       :
//
//  OPERATION : Performs a re-creation of all indexes in the indicated
//                database.
//
//  UPDATED   : 2020-10-19
//
//***************************************************************************
procedure RecreateDatabaseIndexes(sDBDirectory : String;
                                  lProgressMessage : TLabel;
                                  pbTableIndexes : TProgressBar;
                                  pbDatabaseProgress : TProgressBar);
var
  n : Integer;

begin
//  Screen.Cursor := crHourGlass;

  WriteToDBUpgLog('Recereate Indexes in : ' + sDBDirectory);

  // Set up the progress bars, if specified
  if (pbDatabaseProgress <> nil) then
  begin
    pbDatabaseProgress.Max := iDBUC_iTablesInDB;
    pbDatabaseProgress.Position := 0;
  end; // if
  if (pbTableIndexes <> nil) then
    pbTableIndexes.Position := 0;

  // Cycle through all the tables to be upgraded
  for n := 1 to iDBUC_iTablesInDB do
  begin

// !!  Check for wildcards
// Used in TraXBase V8.25.2

    ReindexTable(n,sDBDirectory,lProgressMessage,pbTableIndexes);
    // Ensure that the Table progress bar is at the end
    if (pbTableIndexes <> nil) then
      pbTableIndexes.Position := pbTableIndexes.Max;
    // Update the Database progress bar
    if (pbDatabaseProgress <> nil) then
    begin
      pbDatabaseProgress.Position := n;
      pbDatabaseProgress.Update;
    end; // if
  end; // for

  // Wipe the activity message
  if (lProgressMessage <> nil) then
    lProgressMessage.Caption := '';

  // Show we are have finished
//  Screen.Cursor := crDefault;
end; // RecreateDatabaseIndexes

//***************************************************************************
//
//  FUNCTION  : RefreshOpenTables
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Refreshes all open TDBISAMTable components in a given DataModule.
//
//  UPDATED   : 2010-10-11
//
//***************************************************************************
procedure RefreshOpenTables(dmData : TDataModule);
var
  n : Word;
begin
  for n := 0 to dmData.ComponentCount-1 do
  begin
    if ((dmData.Components[n] is TDBISAMTable) and
        ((dmData.Components[n] as TDBISAMTable).State = dsBrowse)) then
      (dmData.Components[n] as TDBISAMTable).Refresh;
  end; // for
end; // RefreshOpenTables

//***************************************************************************
//
//  FUNCTION  : TestMapSection
//
//  I/P       : sMapSection (string) - The name of the mapping section
//                in the database information file.
//
//              tTargetTable (TDBISAMTable) - The table to which we will be
//                copying data.
//
//  O/P       : sDBUC_DBUpgResult - Holds a description of any errors found,
//                else empty string.
//
//  OPERATION : Checks that the specified map section in the database
//                information file is suitable for use with the specified
//                destination table.
//
//  UPDATED   : 2010-10-11
//
//***************************************************************************
procedure TestMapSection (sMapSection : String;
                          tTargetTable : TDBISAMTable);
var
  table_open : Boolean;                 // Shows whether the table was open on entering routine
  map_nos : TStringList;
  map_info : TStringList;
  n : Integer;                          // Cycles through each map field number
  iDestnIndex : Integer;                // Destination field index
  dummy : Integer;                      // Used in string to int conversions
  sFieldMap : String;                   // The mapping to be applied to a field

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
  begin
    iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
    sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                         'Field mapping information count (' + IntToStr(map_nos.Count) +
                         ') does not match destination table field count (' + IntToStr(tTargetTable.FieldCount) + ').';
  end; // if
  // Close the table, if it was closed on entry
  if (not table_open) then
    tTargetTable.Close;

  // Check that each mapping is sequential and valid.
  n := 0;
  while ((n<=map_nos.Count-1) and (sDBUC_DBUpgResult = '')) do
  begin
    // Check that the destination field identifier is a valid number
    Val(map_nos.Strings[n],iDestnIndex,dummy);
    if (dummy<>0) then
    begin
      iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
      sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                           'Map destination field index is not a number.'
    end // if
    else
    begin
      // Check that the destination fields are sequential
      if (iDestnIndex<>n) then
      begin
        iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
        sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                             'Map destination field index ' + IntToStr(iDestnIndex) + ' is not sequential.';
      end // if
      else
      begin
        // Test the given source field/default values
        sFieldMap := map_info.Values[map_nos.Strings[n]];
        // Ignore null mappings
        if (sFieldMap<>'') then
        begin
          // Test if there is a direct field-to-field mapping
          if (Copy(sFieldMap,1,2)='fn') then
          begin
            try
              // Extract the source field number
              StrToInt(Copy(sFieldMap,3,255));
            except
              // Flag a bad source field number if it was bad
              iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
              sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                                   'Map source field index for destination field ' + IntToStr(n) + ' is not a number.';
            end; // except
          end // if
          else
            // Test if there is a default string for this field
            if (sFieldMap[1]='"') then
            begin                   // Check that its format is correct
              if ((Length(sFieldMap)=1) or
                  (sFieldMap[Length(sFieldMap)]<>'"')) then
              begin
                iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
                sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                                     'Map source default string format is invalid.';
              end;
            end // if
            else
              // Test if there is a unique ID
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
                  iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
                  sDBUC_DBUpgResult := 'Table : ' + sDBUC_TableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                                       'Map source default string format is invalid.';
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

// ***************************************************************************
//
//  FUNCTION  : CheckDatabaseFiles
//
//  I/P       : sTestDir (string) - The directory to be checked
//
//              fAllFiles (boolean) - TRUE if all of the files that
//                are required for this database are to be
//                checked for existance.
//
//  O/P       : sDBUC_DBUpgResult - An empty string means that the file (or
//                files were found).   Anything else means that there
//                were one or more files missing.
//
//  OPERATION :
//
//  UPDATED   : 2005/01/28
//
// ***************************************************************************
procedure CheckDatabaseFiles(sTestDir : String;
                             fAllFiles : Boolean);
var
  iCurrentTable : Integer;
  sLine : String;
  filenameTable : String;
  optTableControl : String; // Options for table control (includes 'O' if table is optional)
  bFilesFound : Boolean;

begin
  // Set an error message (which will be removed if all is OK)
  iDBUC_DBUpgErr := ERR_DB_OLDER;
  sDBUC_DBUpgResult := 'One or more tables are missing from the database';

  if (fAllFiles) then
    // If requiring all files to be present, initially assume this will be so.
    bFilesFound := TRUE
  else
    // If requiring only some files to be present, initially assume none are present.
    bFilesFound := FALSE;

  // Check that we have the definition resource for the database
  if (AccessedDBDefinitionResources) then
  begin
    // Fix up the data directory location if it does not already end in a '\'
    sTestDir := IncludeTrailingPathDelimiter(sTestDir);

    // Check all the tables in the database
    for iCurrentTable := 1 to iDBUC_iTablesInDB do
    begin
      sLine := mifDBUC_DBDefn.ReadString('Tables',IntToStr(iCurrentTable),'');
      // The table definition line has a table file name (with no extension),
      // followed by an optional comma-separated field/s
      // Remove the extension (which should not exist),
      // and replace with the DBISAM table extension
      filenameTable := ExtractAndTrim(sLine,',');
      optTableControl := ExtractAndTrim(sLine,',');
      filenameTable := ChangeFileExt(filenameTable,DBISAM_TABLE_EXT);

      // Look for the table, if it is not optional
      if (Pos('O',optTableControl) = 0) then
      begin
        // Try to find the table, if required
        if (FileExists(sTestDir + filenameTable)) then
        begin
          // If the file exists and we do not require all files to be present,
          // then we have at least a partial
          if (not fAllFiles) then
            bFilesFound := TRUE;
        end // if
        else
          // If the file does not exist and we require all files to be present,
          // then it is likely that this is an older, incomplete database.
          // (Very small chance that its a more modern version of the database)
          if (fAllFiles) then
          begin
            bFilesFound := FALSE;
            iDBUC_DBUpgErr := ERR_DB_OLDER;
            sDBUC_DBUpgResult := sDBUC_DBUpgResult + ' - ' + filenameTable;
          end; // if
      end; // if
    end; // for

    // If no errors, kill the error message
    if (bFilesFound) then
    begin
      iDBUC_DBUpgErr := ERR_DB_NONE;
      sDBUC_DBUpgResult := '';
    end;
  end; // if
end; // CheckDatabaseFiles

//***************************************************************************
//
//  FUNCTION  : CheckTableValidity
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2020-09-03
//
//***************************************************************************
procedure CheckTableValidity(filenameTable : String;
                             descriptionTable : String);
var
  n : Integer;
  field_nos : TStringList;
  field_info : TStringList;
  field_line : String;            // The ini's line of field information
  field_name : String;            // Used for Add methog, when adding fields
  field_datatype : TFieldType;    // Used for Add methog, when adding fields
  field_size : Word;              // Used for Add methog, when adding fields
  field_required : Boolean;       // Used for Add methog, when adding fields
  index_nos : TStringList;
  index_info : TStringList;
  index_line : String;            // The ini's line of index information
  index_name : String;
  index_fields : String;
  index_flags : String;

begin
  // Confirm that the the file does exist
  if (not FileExists(filenameTable)) then
  begin
    // A table's .dat file is missing from the database
    iDBUC_DBUpgErr := ERR_DB_OLDER;
    sDBUC_DBUpgResult := 'The ' + descriptionTable + ' table is missing from the database.' + #13 +
                         'Please upgrade the database.';
    Exit;
  end; // if

  if (not AccessedSourceTable(filenameTable,sDBUC_Session,sDBUC_TableTitle,FALSE)) then
  begin
    Exit;
  end; // if

  // Create the storage space for the list of fields in this table.
  field_nos := TStringList.Create;
  field_info := TStringList.Create;
  try
    // Read in the list of the fields that are expected to be in this table.
    mifDBUC_TableDefn.ReadSection('1.LatestFields',field_nos);
    mifDBUC_TableDefn.ReadSectionValues('1.LatestFields',field_info);

    // Now check the table
    // Check that there are the correct number of fields
    if (tDSSource.FieldDefs.Count <> field_nos.Count) then
    begin
      // This table does not have the expected number of fields
      // At this point in the checking, an upgrade can be assumed as necessary
      iDBUC_DBUpgErr := ERR_DB_OLDER;
      sDBUC_DBUpgResult := 'The version of the ' + descriptionTable + ' table is not correct.' + #13 +
                           'Please upgrade the database.';
      if (runningUnderIDE) then
      begin
        sDBUC_DBUpgResult := sDBUC_DBUpgResult + #13 +
          'Field count differences' + #13 +
          '   ' + IntToStr(tDSSource.FieldDefs.Count) + ' / ' +
          IntToStr(field_nos.Count);
      end; // if
      Exit;
    end; // if

    // Scan through all the fields
    for n := 0 to tDSSource.FieldDefs.Count-1 do
    begin
      field_line := field_info.Values[field_nos.Strings[n]];

      // Check the format of the line
      if (Count_Chars(field_line,',') < 3) then
      begin
        // Error in field information given.
        iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
        sDBUC_DBUpgResult := 'There is a field information error in the ' + descriptionTable + ' table.' + #13 +
                            '(' + field_line + ')';
        Exit;
      end;

      // Format of info given appears correct
      field_name := Copy(field_line,1,Pos(',',field_line)-1);
      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      field_datatype := GetANSFieldDataType(field_line[1]);

      if (field_datatype = ftUnknown) then
      begin
        iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
        sDBUC_DBUpgResult := 'An unknown field type was found in the ' + descriptionTable + ' table.';
        Exit;
      end; // if

      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      if (field_datatype = ftString) or
         (field_datatype = ftMemo) or
         (field_datatype = ftGraphic) or
         (field_datatype = ftBytes) then
        field_size := StrToInt(Copy(field_line,1,Pos(',',field_line)-1))
      else
        field_size := 0;

      field_line := Copy(field_line,Pos(',',field_line)+1,255);
      field_required := (field_line[1]='1');

      // Check that the expected and found field definitions match.
      if (UpperCase(tDSSource.FieldDefs.Items[n].Name)<>UpperCase(field_name)) or
         (tDSSource.FieldDefs.Items[n].DataType<>field_datatype) or
         (tDSSource.FieldDefs.Items[n].Size<>field_size) or
         (tDSSource.FieldDefs.Items[n].Required<>field_required) then
      begin
        // At this point in the checking, an upgrade can be assumed as necessary
        iDBUC_DBUpgErr := ERR_DB_OLDER;
        sDBUC_DBUpgResult := 'The version of the ' + descriptionTable + ' table is not correct.' + #13 +
                             'Please upgrade the database.';
        if (runningUnderIDE) then
        begin
          sDBUC_DBUpgResult := sDBUC_DBUpgResult + #13 +
            'Differences in definition of field "' +
            tDSSource.FieldDefs.Items[n].Name + '" / "' +
            field_name + '"';
        end; // if
        Exit;
      end; // else
    end; // for

  finally
    field_nos.Free;
    field_info.Free;
  end; // if

  // Create the storage space for the list of indexes in this table.
  index_nos := TStringList.Create;
  index_info := TStringList.Create;
  try
    // Read in the list of the fields that are expected to be in this table.
    mifDBUC_TableDefn.ReadSection('1.LatestIndexes',index_nos);
    mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',index_info);

    // Now check the indexes.
    // Check that there are the correct number of indexes
    if (tDSSource.IndexDefs.Count <> index_nos.Count) then
    begin
      iDBUC_DBUpgErr := ERR_DB_OLDER;
      sDBUC_DBUpgResult := 'The indexes of the ' + descriptionTable + ' table are not correct.' + #13 +
                           'Please upgrade the database.';
      Exit;
    end; // else

    // Scan through all the indexes
    for n := 0 to tDSSource.IndexDefs.Count-1 do
    begin
      index_line := index_info.Values[index_nos.Strings[n]];
      // Check the format of the line
      if (Count_Chars(index_line,',') < 2) then
      begin
        // Error in index information given.
        iDBUC_DBUpgErr := ERR_DB_DEVELOPMENT;
        sDBUC_DBUpgResult := 'There is an index information error in the ' + descriptionTable + ' table.' + #13 +
                            '(' + index_line + ')';
        Exit;
      end;

      // Format of info given appears correct
      index_name := ExtractAndTrim(index_line,',');
      index_fields := ExtractAndTrim(index_line,',');
      index_flags := ExtractAndTrim(index_line,',');
      // IndexDefs has the indexes in the order in which they
      // were originally created, so matching can be problematic!
      //!!ANS*BUSY HERE
      // This is the case with Paradox tables.   Is it also the case with DBISAM?
    end; // for

  finally
    index_nos.Free;
    index_info.Free;
  end;

  tDSSource.Close;
end;

// ***************************************************************************
//
//  FUNCTION  : CheckDatabaseValidity
//
//  I/P       : sTestDir (string) - The directory which contains the
//                database is to be tested.
//
//  O/P       : sDBUC_DBUpgResult - Contains a non-empty string if there
//                is a negative result to the test, and an empty string
//                if everything is OK.
//
//  OPERATION : Checks that all tables exist, and that they all conform
//                to the format of the latest version.
//
//  UPDATED   : 2020-10-19
//
// ***************************************************************************
procedure CheckDatabaseValidity(sTestDir : String);
var
  iCurrentTable : Integer;
  searchrec  : TSearchRec;      // Search Record for finding individual DAD table files
  fresult : Integer;            // Result of each search.

begin
  // Show we are busy
//  Screen.Cursor := crHourGlass;

  // Initially assume all is OK
  iDBUC_DBUpgErr := ERR_DB_NONE;
  sDBUC_DBUpgResult := '';

  // Check that we have an information resource for the database upgrade program
  if (AccessedDBDefinitionResources) then
  begin
    // Fix up the data directory location if it does not already end in a '\'
    sTestDir := IncludeTrailingPathDelimiter(sTestDir);

    // Cycle through all the tables to be checked
    iCurrentTable := 1;
    while ((iCurrentTable <= iDBUC_iTablesInDB) and
           (sDBUC_DBUpgResult = '')) do
    begin
      GotTableInformationFromIndex(iCurrentTable);
      // Get the descriptive name of the table being upgraded
      sDBUC_TableTitle := mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable));

      if (Pos('*', sDBUC_TableFilename) <> 0) then
      begin
        // Wildcard (multiple tables with a similar naming structure)
        // Go through all the existing wildcard tables, checking each for validity
        // Note that I am deeming it permissable (no error) that no wildcard tabled exist.
        var Attrs : Integer;
        Attrs := 0;
        {$IFDEF MSWINDOWS}
        {$WARN SYMBOL_PLATFORM OFF}
        Attrs := faArchive;
        {$WARN SYMBOL_PLATFORM ON}
        {$ENDIF}
        fresult := FindFirst(sTestDir + sDBUC_TableFilename, Attrs, searchrec);
        if (fresult = 0) then
        begin
          while ((fresult=0) and
                 (sDBUC_DBUpgResult = '')) do
          begin
            CheckTableValidity(sTestDir + searchrec.name, sDBUC_TableTitle);
            // See if there are any more wildcard table files
            fresult := FindNext(searchrec);
          end; // while
          SysUtils.FindClose(searchrec);
        end
      end // if
      else
      begin
        // Normal, single table
        sDBUC_TableFilename := sTestDir + sDBUC_TableFilename;
        CheckTableValidity(sDBUC_TableFilename, sDBUC_TableTitle);
      end;
      // Move on to the next table
      Inc(iCurrentTable);
    end; // for
  end; // if
//  Screen.Cursor := crDefault;
end; //

// ***************************************************************************
//
//       FUNCTION    :   RecordAccessMessage
//
//       I/P         :   dsTarget (TDBISAMDataSet) - The dataset containing the
//                         record that is to be modified (the current record).
//
//       O/P         :   (string) : Empty if the record may be modified.
//                          Otherwise, it contains a descriptive reason.
//
//       OPERATION   :   Checks whether the current record in the given dataset
//                       may be edited.   (A record may be locked over a network
//                       if someone else is editing it.)
//
//       UPDATED     :   2007/06/25
//
// ***************************************************************************
function RecordAccessMessage(dsTarget : TDBISAMDataSet) : String;
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
              Dialog_Ops.MessageDlg(E.Message,mtError,[mbOK],0);
              Break;
            end; // else
        end
        else
        begin
          Dialog_Ops.MessageDlg(E.Message,mtError,[mbOK],0);
          Break;
        end; // else
      end; // on
    end; // except
  end; // while
end; // RecordAccessMessage

//***************************************************************************
//
//  FUNCTION  : LoadTableFromDiscToMemory
//
//  I/P       : tDiscTable (TDBISAMTable) - The source table
//
//              tMemoryTable (TDBISAMTable) - The destination table (already
//                created and configured for memory operation)
//
//  O/P       : tDiscTable (TDBISAMTable) - Left closed
//
//              tMemoryTable (TDBISAMTable) - Left open
//
//  OPERATION : Copies a table that is stored on disc to a table (with matching
//              structure) in memory.
//
//  UPDATED   : 2006/01/27
//
//***************************************************************************
procedure LoadTableFromDiscToMemory(tDiscTable : TDBISAMTable;
                                    tMemoryTable : TDBISAMTable);
var
  n : Integer;
begin
  tMemoryTable.Close;
  tMemoryTable.Exclusive := TRUE;
  tMemoryTable.Open;
  tMemoryTable.EmptyTable;
  tMemoryTable.Close;
  tMemoryTable.Exclusive := FALSE;
  tMemoryTable.Open;

  tDiscTable.Open;
  tDiscTable.First;
  while (not tDiscTable.Eof) do
  begin
    tMemoryTable.Append;
    for n := 0 to tDiscTable.FieldCount-1 do
      tMemoryTable.Fields[n].Assign(tDiscTable.Fields[n]);
    tMemoryTable.Post;
    tDiscTable.Next;
  end; // while
  tDiscTable.Close;
end; // LoadTableFromDiscToMemory

//***************************************************************************
//
//  FUNCTION  : MovedTable
//
//  I/P       : srcDatabaseName : String - Path to the source database
//
//              srcTableName : String - Name of the source table
//
//              destDatabaseName : String - Path to the destination database
//
//              destTableName : String - Name of the destination table
//
//  O/P       : TRUE if the move was successful
//
//  OPERATION : Moves a table from one location to another
//
//  UPDATED   : 2017-11-21
//
//***************************************************************************
function MovedTable(srcDatabaseName : String;
                    srcTableName : String;
                    destDatabaseName : String;
                    destTableName : String) : boolean;
var
  tDAD : TDBISAMTable;

begin
  result := FALSE;

  // Ensure the correct naming
  srcDatabaseName := IncludeTrailingPathDelimiter(srcDatabaseName);
  srcTableName := ChangeFileExt(srcTableName,DBISAM_TABLE_EXT);
  destDatabaseName := IncludeTrailingPathDelimiter(destDatabaseName);
  destTableName := ChangeFileExt(destTableName,DBISAM_TABLE_EXT);

  tDAD := TDBISAMTable.Create(nil);
  try
    SetupTable(tDAD, destDatabaseName, destTableName);
    if (tDAD.Exists) then
      tDAD.DeleteTable;

    SetupTable(tDAD, srcDatabaseName, srcTableName);
    if (tDAD.Exists) then
    begin
      tDAD.CopyTable(destDatabaseName, destTableName);
      tDAD.DeleteTable;
      result := TRUE;
    end;
  finally
    tDAD.Close;
    tDAD.Free;
  end;
end; // MovedTable

//***************************************************************************
//
//  FUNCTION  : MovedToRecord
//
//  I/P       : tTarget : TDBISAMTable - The table in which to work
//
//              nameField : String - The field name to be matched
//
//              valueField : Variant - The value to be matched
//
//  O/P       : Boolean - TRUE if the record was found
//
//  OPERATION : Attempts to point to a record in the target table where the
//              field contents matches the given value
//
//              In the case of a string value, the match is case insensitive
//
//              This operation uses Locate, rather than any pre-defined index,
//              so has that speed knock.
//
//  UPDATED   : 2019-06-14
//
//***************************************************************************
function MovedToRecord(tTarget : TDBISAMTable;
                      nameField : String;
                      valueField : Variant) : Boolean;
begin
  result := FALSE;

  if (VarIsType(valueField, [varUString, varString])) then
  begin
    result := tTarget.Locate(nameField, String(valueField), [loCaseInsensitive]);
    if (not result) then
      tTarget.First;
  end // if

  else if (VarIsType(valueField, [varInteger, varDate])) then
  begin
    result := tTarget.Locate(nameField, valueField, []);
    if (not result) then
      tTarget.First;
  end; // if
end; // MovedToRecord

function MovedToRecord(tTarget : TDBISAMTable;
                      idxField : Integer;
                      valueField : Variant) : Boolean; overload;
begin
  result := MovedToRecord(tTarget, tTarget.FieldDefs[idxField].Name, valueField);
end; // MovedToRecord

//***************************************************************************
//
//  FUNCTION  : ClearAndOpenTable
//
//  I/P       : theTable : TDBISAMTable - The table to be emptied and opened.
//
//  O/P       : None
//
//  OPERATION : Close, EmptyTable and Open the given tabl.
//
//              Used so that we do not need to open tables with Exclusive=True
//              which causes a problem with sharing (e.g. in multi-vehicle
//              selection)
//
//              It can also help with debugging when accessing tables while the
//              software is still running
//
//  UPDATED   : 2019-08-29
//
//***************************************************************************
procedure ClearAndOpenTable(theTable : TDBISAMTable);
begin
  theTable.Close;
  theTable.EmptyTable;
  theTable.Open;
end; // ClearAndOpenTable

//***************************************************************************
//
//  FUNCTION  : CopyFieldToStrings
//
//  I/P       : target : TStrings - The Items property of this TStrings
//                object is to be filled with contents of the indicated field
//
//              source : TDBISAMTable - The source data table (already open)
//
//              indexField : Integer - The index of the field to be copied.
//
//  O/P       : target : TStrings
//
//  OPERATION : Fills a TStrings with the string contents of the indicated field.
//
//  UPDATED   : 2019-11-04
//
//***************************************************************************
procedure CopyFieldToStrings(target : TStrings;
                             source : TDBISAMTable;
                             indexField : Integer);
begin
  target.Clear;
  source.First;
  while (not source.Eof) do
  begin
    target.Add(source.Fields[indexField].AsString);
    source.Next;
  end; // while
end; // CopyFieldToStrings

//***************************************************************************
//
//  FUNCTION  : GetIndexDefsID
//
//  I/P       : source : TDBISAMTable - The table of interest
//
//              indexName : String - The index name
//
//  O/P       : Integer - The required index to the IndexDefs property
//
//  OPERATION : Find the index of the given table IndexName in the table's IndexDefs
//
//              Raise and exception if the index is not found
//
//              I'm suprised that such a function had to be written!
//
//  UPDATED   : 2020-06-24
//
//***************************************************************************
function GetIndexDefsID(source : TDBISAMTable;
                        indexName : String) : Integer;
var
  n : Integer;

begin
  n := 0;
  while (n < source.IndexDefs.Count) do
  begin
    if (source.IndexDefs[n].Name = indexName) then
    begin
      Result := n;
      Exit;
    end; // if
    Inc(n);
  end;

  raise Exception.Create('Unknown table index name');
end; // GetIndexDefsID

//***************************************************************************
initialization
begin
  sControl := TDBISAMSession.Create(nil);
  sControl.SessionName := 'ABC123';
  tDSDestination := TDBISAMTable.Create(nil);
  tDSDestination.SessionName := sControl.SessionName;
  tDSSource := TDBISAMTable.Create(nil);
  tDSSource.SessionName := sControl.SessionName;
end;

//***************************************************************************
finalization
begin
  tDSDestination.Close;
  tDSSource.Close;
  sControl.Close;

  tDSDestination.Free;
  tDSSource.Free;
  sControl.Free;
end;

end.

