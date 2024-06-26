unit DBUtilsParadox;
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
//    Update Date : 2010-10-11
//    Changes Made :
//      * Based on DBUtilsParadox, but only includes Paradox-related routines
//
//***************************************************************************

interface

{$A-}

uses DBTables, DB, StdCtrls, COMCtrls, Forms, Classes, DKLang;

procedure SealTable(tTableToSeal : TTable);
procedure TransferField(tTFSource : TTable;
                        tTFDestination : TTable;
                        sFieldMap : string;
                        iDestFieldNo : integer);
procedure TransferRecord(tRecSource : TTable;
                         tRecDestination : TTable;
                         slMapInfo : TStringList);
procedure UpgradeDatabase(sDBDirectory : string;
                          lProgressMessage : TLabel;
                          pbTableContents : TProgressBar;
                          pbTableIndexes : TProgressBar;
                          pbDatabaseProgress : TProgressBar;
                          bRestart : boolean);
procedure RecreateDatabaseIndexes(sDBDirectory : string;
                                  lProgressMessage : TLabel;
                                  pbTableIndexes : TProgressBar;
                                  pbDatabaseProgress : TProgressBar);
procedure RefreshOpenTables(dmData : TDataModule);
procedure TestMapSection (sMapSection : string;
                          tTargetTable : TTable);
procedure CheckDatabaseFiles(sTestDir : string;
                             fAllFiles : boolean);
procedure CheckDatabaseValidity(sTestDir :string);
function RecordAccessMessage(dsTarget : TDataSet) : string;
(*
function Got_Map_Section (tDestn : TTable;
                          tSource : TTable;
                          var sMapSection : string) : integer;
function DBError_Message(iErrorNo : integer) : string;
function Get_Upgrade_Index(tablename : string;
                           var uiUpgradeIndex : word) : integer;
function Get_Old_Index(tCurrent : TTable;
                       iCurrentFIndex : integer;
                       tOld : TTable) : integer;
*)

implementation

uses Windows, SysUtils, IniFiles, Controls, Registry, Dialogs,
     DBUtilsCommon, Str_Ops, File_Ops, TimeDate;

var
  lcDBUtils : TDKLanguageController;
  sDBCtrlDir : string;              // Directory of the database definition file
  tfOutput : TextFile;              // Used to log the progress
  iIndexesUpdated : integer;        // Counts the number of tables which had their indexes updated
  iFieldsUpdated : integer;         // Counts the number of tables which had their fileds updated
  iNewTables : integer;             // Counts the number of new tables created
  iErrors : integer;                // Counts of the number of errors encountered
  sTableTitle : string;             // A descriptive title of the table currently being upgraded
  tParSource : TTable;              // The original Paradox table, that is to be upgraded
  tParDestination : TTable;         // The target Paradox table, used to create new or updated tables
  sSourceVer : string;              // Source table version number
  bNewTable : boolean;              // TRUE if there is no exsiting table, and it must be created.
  bUseUpgradeLog : boolean;         // TRUE if we are to use the log file for recording operations
  sAgentHelp : string;

//***************************************************************************
//
//  FUNCTION  : SealTable
//
//  I/P       : tTableToSeal (TTable) - The table, the contents of which
//                must be sealed.
//
//  O/P       : None.
//
//  OPERATION : Opens and Closes the given table, returning to the record
//              that was initially active.
//
//              This function assumes that the primary key is based on the
//              first field, and can be expressed as a string.
//
//  UPDATED   : 2005/10/11
//
//***************************************************************************
procedure SealTable(tTableToSeal : TTable); overload;
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
  tTableToSeal.IndexName := '';
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
  mifDBUC_TableDefn.ReadSection('1.'+sCompareAgainst+'Fields',field_nos);
  mifDBUC_TableDefn.ReadSectionValues('1.'+sCompareAgainst+'Fields',field_info);

  // Check the table
  with tParSource do
  begin
    // Ensure that there are the correct number of fields
    if (FieldDefs.Count<>field_nos.Count) then
    begin
      result := FALSE;
      sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
                           'Field Count: Source has ' + IntToStr(FieldDefs.Count) +
                           ', Expected = ' + IntToStr(field_nos.Count) +
                           #13 +
                           sAgentHelp;
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
          sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
                               sCompareAgainst + ' field ' + IntToStr(n) + ' - ';
          if (UpperCase(FieldDefs.Items[n].Name)<>UpperCase(field_name)) then
            sDBUC_DBUpgResult := sDBUC_DBUpgResult +
                                 'Name: Original = ' + FieldDefs.Items[n].Name +
                                 ', Expected = ' + field_name + #13 + sAgentHelp
          else
            if (FieldDefs.Items[n].DataType<>ftFieldDataType) then
              sDBUC_DBUpgResult := sDBUC_DBUpgResult +
                                   'Type: Original = ' + GetFieldTypeName(FieldDefs.Items[n].DataType,1) +
                                   ', Expected = ' + GetFieldTypeName(ftFieldDataType,1) + #13 + sAgentHelp
            else
              if (FieldDefs.Items[n].Size<>field_size) then
                sDBUC_DBUpgResult := sDBUC_DBUpgResult +
                                     'Size: Original = ' + IntToStr(FieldDefs.Items[n].Size) +
                                     ', Expected = ' + IntToStr(field_size) + #13 + sAgentHelp
              else
                sDBUC_DBUpgResult := sDBUC_DBUpgResult +
                                     'Required: Original = ' + IntToStr(integer(FieldDefs.Items[n].Required)) +
                                     ', Expected = ' + IntToStr(integer(field_required)) + #13 + sAgentHelp;
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
//  FUNCTION    :   AccessedSourceTable
//
//  I/P         :   sTableFielname - The full file name of the table that
//                        we are wanting to upgrade.
//
//  O/P         :   (boolean) - TRUE if we accessed and opened the table
//
//                      bNewTable - TRUE if a new table must be created.
//
//  OPERATION   :   Checks the given file name of the table, and whether
//                      it exists and is accessable for upgrading.
//                      descriptions.
//
//  UPDATED     :   2003/09/04
//
//***************************************************************************
function AccessedSourceTable : boolean;
begin
  // Assume that we will be able to access the table
  result := TRUE;
  // Check that the current table file name is valid
  if ((sDBUC_TableFilename='') or
      (UpperCase(ExtractFileExt(sDBUC_TableFilename)) <> '.DB')) then
  begin
    sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
                         'An invalid filename, ' + sDBUC_TableFilename + ' has been specified.' + #$D +
                         'This table has not been upgraded.' +
                         #13 +
                         sAgentHelp;
    result := FALSE;
  end // if
  else
  begin
    // Check whether the table file exists
    if (FileExists(sDBUC_TableFilename)) then
    begin
// The table file exists, so try to access it exclusively
      try
        with tParSource do
        begin
          Close;
          DatabaseName := ExtractFilePath(sDBUC_TableFilename);
          TableName := ExtractFileName(sDBUC_TableFilename);
          // Get exclusive access, to prevent anyone else altering contents
          Exclusive := TRUE;
          Open;
        end; // with
// Flag that it is not necessary to create a new table
        bNewTable := FALSE;
      except
        on E:EDBEngineError do
        begin
          result := FALSE;              // We could not obtain exclusive access to this table
          sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
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
//  FUNCTION    :   GotSourceVersion
//
//  I/P         :   tSource (TTable) - The source table.
//
//  O/P         :   (boolean) - TRUE if the original and desired table
//                        differ in any way
//
//                      sSourceVer - The version of the tSource table.
//
//  OPERATION   :   Attempt to extract the Source Table's version from
//                      Field 1.
//
//  UPDATED     :   2003/08/29
//
//***************************************************************************
function GotSourceVersion : boolean;
var
  first_ver : word;               // Used to identify the first version that we can upgrade
begin
  // Read in the source table's version number (from Field 1)
  if (tParSource.FieldDefs.Count>1) then
    sSourceVer := UpperCase(tParSource.FieldDefs.Items[1].Name)
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
      if (mifDBUC_TableDefn.ReadString('1.'+sSourceVer+'Fields','0','')<>'') then
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
                    sAgentHelp
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
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                        'Field identifier ' + IntToStr(n) + ' is non-sequential or invalid.' +
                        #13 +
                        sAgentHelp;
        Break;
      end; // if
    end // for
  else
  begin
    result := FALSE;
    sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                    'No fields defined.' +
                    #13 +
                    sAgentHelp;
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
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                        'Field definition ' + IntToStr(n) + ' is invalid' +
                        #13 +
                        sAgentHelp;
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
                          sAgentHelp;
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
                          sAgentHelp;
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
                            sAgentHelp;
            break;
          end;// if
        except
          result := FALSE;
          sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sTableVer + ')' + #$D +
                          'Field size in definition ' + IntToStr(n) + ' is not number' +
                          #13 +
                          sAgentHelp;
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
//  O/P       : boolean - TRUE if the index definition information
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
//  UPDATED   : 2003/09/04
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
  mifDBUC_TableDefn.ReadSection('1.LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',slIndexInfo);

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
                      sAgentHelp;
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
                        sAgentHelp;
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

  Screen.Cursor := crHourGlass;   // Show we are busy

  result := TRUE;                 // Initially assume all is OK

  with tParDestination do            // Set up the temporary destination file
  begin
    index_nos := nil;
    index_info := nil;
    field_nos := nil;
    field_info := nil;

    try
      Close;
      DatabaseName := ExtractFilePath(sDBUC_TableFilename);
      TableName := TEMP_TABLE_NAME + '.DB';
      TableType := ttParadox;

      FieldDefs.Clear;            // Clear any fields and indexes in this new table
      IndexDefs.Clear;

      field_nos := TStringList.Create;    // Create the storage space and read in the
      field_info := TStringList.Create;   // list of fields in this table.
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

        FieldDefs.Add(field_name,field_datatype,field_size,field_required);
      end; // for

      index_nos := TStringList.Create;    // Create the storage space and read in the
      index_info := TStringList.Create;   // list of fields in this table.
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

        IndexDefs.Add(index_name,index_fields,index_options);
      end; // for
      // Make the table
      CreateTable;

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
                        sAgentHelp;
      end; // on
    end; // except

    // Free up the space used by these variables
    index_nos.Free;
    index_info.Free;
    field_nos.Free;
    field_info.Free;
  end; // with

end; // CreatedTempTable

//***************************************************************************
//
//  FUNCTION    :   TransferField
//
//  I/P         :   tTFSource (TTable) - The table containing the
//                        source data.
//
//                      tTFDestination (TTable) - The table containing the
//                        destination data.
//
//                      sFieldMap (string) - The details of what to put
//                        into the field in the destination table.
//
//                      iDestnFieldNo (integer) - The destination field that is
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
procedure TransferField(tTFSource : TTable;
                        tTFDestination : TTable;
                        sFieldMap : string;
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
          ftAutoInc :
            tTFDestination.Fields[iDestFieldNo].AsInteger := tTFSource.Fields[iSourceFieldNo].AsInteger;

          ftBoolean :
            tTFDestination.Fields[iDestFieldNo].AsBoolean := tTFSource.Fields[iSourceFieldNo].AsBoolean;

          ftFloat ,
          ftCurrency ,
          ftBCD :
            tTFDestination.Fields[iDestFieldNo].AsFloat := tTFSource.Fields[iSourceFieldNo].AsFloat;

          ftDate,
          ftTime,
          ftDateTime :
            tTFDestination.Fields[iDestFieldNo].AsDateTime := tTFSource.Fields[iSourceFieldNo].AsDateTime;

          else
            tTFDestination.Fields[iDestFieldNo].Assign(tTFSource.Fields[iSourceFieldNo]);
        end; // case
    end // if
    else
    begin
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
            sDBUC_DBUpgResult := 'Attempt to assign a default string value to a ' +
                            GetFieldTypeName (tParDestination.FieldDefs[iDestFieldNo].DataType,1) +
                            ' field.' +
                            #13 +
                            sAgentHelp;
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
              sDBUC_DBUpgResult := 'Attempt to assign a default integer value to a ' +
                              GetFieldTypeName (tParDestination.FieldDefs[iDestFieldNo].DataType,1) +
                              ' field.' +
                              #13 +
                              sAgentHelp;
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
                sDBUC_DBUpgResult := 'Attempt to assign a default real value to a ' +
                                GetFieldTypeName (tParDestination.FieldDefs[iDestFieldNo].DataType,1) +
                                ' field.' +
                                #13 +
                                sAgentHelp;
                Inc(iErrors);
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
//  FUNCTION    :   TransferRecord
//
//  I/P         :   tRecSource (TTable) : The table from which the current
//                        record is being transferred.
//
//                      tRecDestination (TTable) : The table to which the
//                        record is being transferred.
//
//                      slMapInfo (TStringLinst) : The mapping information from
//                        the table definition file for transferring fields
//                        from the version of the table represented by the source,
//                        to the destination table.
//
//  O/P         :   sDBUpgResult - Contains an error description, if any.
//
//  OPERATION   :   Transfer all fields in the current record to a new record
//                      in the destination table, using the given mapping information.
//
//  UPDATED     :   2004/11/02
//
//***************************************************************************
procedure TransferRecord(tRecSource : TTable;
                         tRecDestination : TTable;
                         slMapInfo : TStringList);
var
  n : integer;
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
//              tParDestination : The destination table.
//
//              tSource : The source table
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
  dRemaining : double;

begin
  // Check that the field mapping information is valid
  TestMapSection('1.' + sSourceVer + 'Map',tParDestination);

  // Continue if the mapping info is OK
  if (sDBUC_DBUpgResult = '') then
  begin
    // Open the destination table
    tParDestination.Open;

    // Set up the transfer progress bars
    if (pbRecordProgress <> nil) then
    begin
      pbRecordProgress.Max := tParSource.RecordCount;
      pbRecordProgress.Position := 0;
    end; // if
    if (pbIndexProgress <> nil) then
    begin
      pbIndexProgress.Max := tParSource.RecordCount;
      pbIndexProgress.Position := 0;
    end; // if

    // Create the storage space and read in the mapping list for this table upgrade.
    map_info := TStringList.Create;
    mifDBUC_TableDefn.ReadSectionValues('1.' + sSourceVer + 'Map',map_info);

    StartFastTimer(1);

    // Scan through all the records in the source table, stopping if we get an error
    tParSource.First;
    while ((not tParSource.EOF) and (sDBUC_DBUpgResult = '')) do
    begin
      // Transfer this record to the destination table.
      TransferRecord(tParSource, tParDestination, map_info);

      // Keep the user informed as to the number of records that have been transferred
      if (pbRecordProgress <> nil) then
      begin
        pbRecordProgress.Position := pbRecordProgress.Position + 1;
        if ((pbRecordProgress.Position mod 100) = 0) then
          pbRecordProgress.Update;
      end;
      if (pbIndexProgress <> nil) then
      begin
        pbIndexProgress.Position := pbIndexProgress.Position + 1;
        pbIndexProgress.Update;
      end;
      if ((lTransferMessage <> nil) and (pbRecordProgress <> nil)) then
      begin
        dRemaining := GetFastTimer(1);
        dRemaining := (pbRecordProgress.Max - pbRecordProgress.Position) *
                      (dRemaining / pbRecordProgress.Position);
        lTransferMessage.Caption := 'Upgrading the ' + sTableTitle +
                                    ' table (' +
                                    IntToStr(Trunc(dRemaining / 60000)) + 'm ' +
                                    IntToStr(Trunc(dRemaining - 60000*Trunc(dRemaining / 60000)) div 1000) + 's till completion)';
      end; // if

      if ((pbRecordProgress <> nil) and (sDBUC_DBUpgResult <> '')) then
        WriteToDBUpgLog(IntToStr(pbRecordProgress.Position) + ':' + tParDestination.Fields[0].AsString);

      tParSource.Next;
    end; // while

    // Close down the destination table
    tParDestination.Close;

    map_info.Free;
  end; // if

  // Count any errors encountered.
  if (sDBUC_DBUpgResult <> '') then
    Inc(iErrors);

  tParSource.Close;              // Close down the source table
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
  file_root := Copy(ExtractFileName(sDBUC_TableFilename),1,Pos('.',ExtractFileName(sDBUC_TableFilename)));
  DeletedFiles(ExtractFilePath(sDBUC_TableFilename) + file_root + 'db',0,0.0);
  DeletedFiles(ExtractFilePath(sDBUC_TableFilename) + file_root + 'px',0,0.0);
  DeletedFiles(ExtractFilePath(sDBUC_TableFilename) + file_root + 'x*',0,0.0);
  DeletedFiles(ExtractFilePath(sDBUC_TableFilename) + file_root + 'y*',0,0.0);
  DeletedFiles(ExtractFilePath(sDBUC_TableFilename) + file_root + 'mb',0,0.0);
  DeletedFiles(ExtractFilePath(sDBUC_TableFilename) + file_root + 'tv',0,0.0);
  DeletedFiles(ExtractFilePath(sDBUC_TableFilename) + file_root + 'val',0,0.0);

  file_root := Copy(file_root,1,Length(file_root)-1); // Knock off the '.'

  ChDir(ExtractFilePath(sDBUC_TableFilename));

  while (FindFirst(ExtractFilePath(sDBUC_TableFilename) + TEMP_TABLE_NAME + '.*',faReadOnly + faArchive,sr)=0) do
    RenameFile (sr.name,file_root + ExtractFileExt(sr.name));

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
  mifDBUC_TableDefn.ReadSection('1.LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',slIndexInfo);

// Check the table
  with tParSource do
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
    if (((bTestAll) and (tParSource.IndexDefs.Count=iIndexesToTest)) or
        ((not bTestAll) and (tParSource.IndexDefs.Count>=iIndexesToTest))) then
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
  mifDBUC_TableDefn.ReadSection('1.LatestIndexes',slIndexNos);
  mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',slIndexInfo);

// Check the table and ensure that we have the correct index defs for the table.
  tParSource.IndexDefs.Update;

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
    while (tParSource.IndexDefs.Count > 0) do
    begin
      WriteToDBUpgLog('Deleting index ' + tParSource.IndexDefs.Items[0].Name);
      tParSource.DeleteIndex(tParSource.IndexDefs.Items[0].Name);
      tParSource.IndexDefs.Update;
    end; // for
  end // if
  else
  begin
// Delete any indexes that may exist in the table but are not defined in the control file.
    n := 0;
    while (n < tParSource.IndexDefs.Count) do
    begin
// Try to find the index in the definitions file
      m := 0;
      bFound := FALSE;
      while ((m<slIndexNos.Count) and (not bFound)) do
      begin
// Get the index information - this has already been checked, so we can assume no errors
        GotIndexInfo(slIndexInfo.Values[slIndexNos.Strings[m]],
                     sIndexName,sIndexFields,setIndexOptions);
        if ((UpperCase(sIndexName) = UpperCase(tParSource.IndexDefs.Items[n].Name)) and
              (UpperCase(sIndexFields) = UpperCase(tParSource.IndexDefs.Items[n].Fields)) and
              (setIndexOptions = tParSource.IndexDefs.Items[n].Options)) then
          bFound := TRUE
        else
          Inc(m);
      end; // while
// Check whether the index was found in the Latest index definitions file
      if (not bFound) then
      begin
// If not, delete the index from the table, and restart the scanning
        WriteToDBUpgLog('Deleting index ' + tParSource.IndexDefs.Items[n].Name);
        tParSource.DeleteIndex(tParSource.IndexDefs.Items[n].Name);
        tParSource.IndexDefs.Update;
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
    while ((m < tParSource.IndexDefs.Count) and (not bFound)) do
    begin
      if ((UpperCase(sIndexName) = UpperCase(tParSource.IndexDefs.Items[m].Name)) and
          (UpperCase(sIndexFields) = UpperCase(tParSource.IndexDefs.Items[m].Fields)) and
          (setIndexOptions = tParSource.IndexDefs.Items[m].Options)) then
        bFound := TRUE;
      Inc(m);
    end; // while
// Check whether we found the required index
    if (not bFound) then
    begin
// If not, try to create it
      try
        tParSource.AddIndex(sIndexName,sIndexFields,setIndexOptions);
        WriteToDBUpgLog('Added index ' + sIndexName);
// Update the progress bar
        if (pbIndexProgress <> nil) then
        begin
          pbIndexProgress.Position := pbIndexProgress.Position + 1;
          pbIndexProgress.Update;
        end; // if
      except
        bProceed := FALSE;
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + sSourceVer + ')' + #$D +
                        'Unable to create index "' + sIndexName + '"' + #$D +
                        'This table has not been upgraded.' +
                        #13 +
                        sAgentHelp;
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
//  I/P       : iUpgTableIndex - The index number of the table to be
//                upgraded.
//
//  O/P       : (boolean) - TRUE if the table was upgraded.
//                FALSE otherwise.
//
//  OPERATION : Performs a complete upgrade on the indicated table
//
//  UPDATED   : 2007/07/23
//
//***************************************************************************
function UpgradedTable(iUpgTableIndex : integer;
                       sTableDirectory : string;
                       lProgressMessage : TLabel;
                       pbTableRecordProgress : TProgressBar;
                       pbTableIndexProgress : TProgressBar) : boolean;
begin
  result := FALSE;
  // Renew the hourglass cursor on each table
  Screen.Cursor := crHourGlass;

  GotTableInformationFromIndex(iUpgTableIndex);

  // Get the descriptive name of the table being upgraded
  sTableTitle := mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iUpgTableIndex),'');
  // Show the user what we are doing
  if (lProgressMessage <> nil) then
  begin
    lProgressMessage.Caption := 'Upgrading the ' + sTableTitle + ' table...';
    lProgressMessage.Update;
  end;

  // Add the directory
  sDBUC_TableFilename := sTableDirectory + sDBUC_TableFilename;
  WriteToDBUpgLog(#$D + IntToStr(iUpgTableIndex) + '. Upgrading ' + sTableTitle + ' Paradox table');

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
                  RenameTempTable;
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
  // Display the error message, if one was set up
  if (sDBUC_DBUpgResult<>'') then
  begin
    // Restore the cursor for the prompt
    Screen.Cursor := crDefault;
    MessageDlg(sDBUC_DBUpgResult,mtError,[mbOK],0);
    WriteToDBUpgLog(sDBUC_DBUpgResult);
    Inc(iErrors);
  end; // if
  WriteToDBUpgLog('Finished with ' + sTableTitle + ' table (' + DateTimeToStr(Now) + ')');
  // Close the table that we have just worked on, just in case it was not yet closed
  if (tParSource.State <> dsInactive) then
    tParSource.Close;
  result := TRUE;
end; // UpgradedTable

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
//  UPDATED   : 2004/03/10
//
//***************************************************************************
procedure UpgradeDatabase(sDBDirectory : string;
                          lProgressMessage : TLabel;
                          pbTableContents : TProgressBar;
                          pbTableIndexes : TProgressBar;
                          pbDatabaseProgress : TProgressBar;
                          bRestart : boolean);
var
  n : integer;
begin
  WriteToDBUpgLog('');
  WriteToDBUpgLog('Create/Upgrade Database');
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
  sDBUC_DBUpgResult := '';

  // Cycle through all the tables to be upgraded, stopping if there are any errors.
  n := 1;
  while ((sDBUC_DBUpgResult = '') and
         (n <= iDBUC_iTablesInDB)) do
  begin
    // Upgrade/transfer/create the table
    if (UpgradedTable(n,sDBDirectory,lProgressMessage,pbTableContents,pbTableIndexes)) then
    begin
      // Ensure that the Table progress bars are at the end
      if (pbTableContents <> nil) then
      begin
        pbTableContents.Position := pbTableContents.Max;
        pbTableContents.Update;
      end;
      if (pbTableIndexes <> nil) then
      begin
        pbTableIndexes.Position := pbTableIndexes.Max;
        pbTableIndexes.Update;
      end;
      // Update the Database progress bar
      if (pbDatabaseProgress <> nil) then
      begin
        pbDatabaseProgress.Position := pbDatabaseProgress.Position + 1;
        pbDatabaseProgress.Update;
      end;
    end; // if
    Inc(n);
  end; // while

  // Wipe the activity message
  if (lProgressMessage <> nil) then
    lProgressMessage.Caption := '';

  WriteToDBUpgLog(GetDBUpgResults);
end; // UpgradeDatabase

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
  sTableTitle := mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iRITableIndex),'');
  // Show the user what we are doing
  if (lProgressMessage <> nil) then
    lProgressMessage.Caption := 'Upgrading the ' + sTableTitle + ' table...';

  GotTableInformationFromIndex(iRITableIndex);
  // Add the directory
  sDBUC_TableFilename := sTableDirectory + sDBUC_TableFilename;
  WriteToDBUpgLog(#$D + IntToStr(iRITableIndex) + '. Upgrading ' + sTableTitle + ' table');

  // Update the Table progress bar
  if (pbTableIndexProgress <> nil) then
  begin
    pbTableIndexProgress.Position := 0;
    pbTableIndexProgress.Update;
  end; // if

  // Delete any existing indexes.   We must do this before trying to open the table as any corrupt
  // indexes will prevent access to the table.
  DeletedFiles(ChangeFileExt(sDBUC_TableFilename,'.PX'),0,0.0);
  DeletedFiles(ChangeFileExt(sDBUC_TableFilename,'.XG*'),0,0.0);
  DeletedFiles(ChangeFileExt(sDBUC_TableFilename,'.YG*'),0,0.0);

  // Start off with no errors for this table
  sDBUC_DBUpgResult := '';
  // Check whether the source table name is OK, and whether it exists
  if (AccessedSourceTable) then
    // If this is an existing table, get the version of the table that we are
    // about to upgrade
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
            //!! Do we need this TRUE and FALSE thing now that we actually
            // delete all the indexes for the file.?
            Inc(iIndexesUpdated);
          end; // if
  // Display the error message, if one was set up
  if (sDBUC_DBUpgResult <> '') then
  begin
    // Restore the cursor for the prompt
    Screen.Cursor := crDefault;
    MessageDlg(sDBUC_DBUpgResult,mtError,[mbOK],0);
    WriteToDBUpgLog(sDBUC_DBUpgResult);
    Inc(iErrors);
  end; // if
  WriteToDBUpgLog('Finished with ' + sTableTitle + ' table');
  // Close the table that we have just worked on, just in case it was not yet closed
  if (tParSource.State <> dsInactive) then
    tParSource.Close;
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
    pbDatabaseProgress.Max := iDBUC_iTablesInDB;
    pbDatabaseProgress.Position := 0;
  end; // if
  if (pbTableIndexes <> nil) then
    pbTableIndexes.Position := 0;

  // Cycle through all the tables to be upgraded
  for n := 1 to iDBUC_iTablesInDB do
  begin
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
//  OPERATION : Refreshes all open TTable components in a given DataModule.
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
    if ((dmData.Components[n] is TTable) and
        ((dmData.Components[n] as TTable).State = dsBrowse)) then
      (dmData.Components[n] as TTable).Refresh;
  end; // for
end; // RefreshOpenTables

//***************************************************************************
//
//  FUNCTION  : TestMapSection
//
//  I/P       : sMapSection (string) - The name of the mapping section
//                in the database information file.
//
//              tTargetTable (TTable) - The table to which we will be
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
                          tTargetTable : TTable);
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
                    sAgentHelp;
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
      sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                      'Map destination field index is not a number.' +
                      #13 +
                      sAgentHelp
    else
    begin
      // Check that the destination fields are sequential
      if (iDestnIndex<>n) then
        sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                        'Map destination field index ' + IntToStr(iDestnIndex) + ' is not sequential.' +
                        #13 +
                        sAgentHelp
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
              sDBUC_DBUpgResult := 'Table : ' + sTableTitle + ' (' + Copy(sMapSection,Pos('.',sMapSection)+1,Length(sMapSection)) + ')' + #$D +
                              'Map source field index for destination field ' + IntToStr(n) + ' is not a number.' +
                              #13 +
                              sAgentHelp;
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
                                sAgentHelp;
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
                                  sAgentHelp;
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
//       FUNCTION    :   CheckDatabaseFiles
//
//       I/P         :   sTestDir (string) - The directory to be checked
//
//                       fAllFiles (boolean) - TRUE if all of the files that
//                           are required for this database are to be
//                           checked for existance.
//
//       O/P         :   sDBUC_DBUpgResult - An empty string means that the file (or
//                         files were found).   Anything else means that there
//                         were one or more files missing.
//
//       OPERATION   :
//
//       UPDATED     :   2005/01/28
//
// ***************************************************************************
procedure CheckDatabaseFiles(sTestDir : string;
                             fAllFiles : boolean);
var
  iCurrentTable : integer;
  sLine : string;
  sTableFilename : string;
  bFilesFound : boolean;

begin
  // Initially, no error
  sDBUC_DBUpgResult := 'One or more tables are missing from the database';

  if (fAllFiles) then
    // If requiring all files to be present, initially assume this will be so.
    bFilesFound := TRUE
  else
    // If requiring only some files to be present, initially assume none are present.
    bFilesFound := FALSE;

  // Check that we have the definition files for the database
  if (AccessedDBDefinitionFiles) then
  begin
    // Fix up the data directory location if it does not already end in a '\'
    sTestDir := IncludeTrailingPathDelimiter(sTestDir);

    // Check all the tables in the database
    for iCurrentTable := 1 to iDBUC_iTablesInDB do
    begin
      sLine := mifDBUC_DBDefn.ReadString('Tables',IntToStr(iCurrentTable),'');
      // The table definition line has a table file name with a .IN extension,
      // followed by an optional comma-separated field/s
      // Remove the extension, and replace with .DB
      sTableFilename := ExtractAndTrim(sLine,'.');
      if (UpperCase(Copy(sLine,1,2)) = 'IN') then
        sTableFilename := ChangeFileExt(sTableFilename,'.DB')
      else
        // The '.IN' extension is expected
        sTableFilename := 'GFDYYJ4UZ3NRDXSDF5GFD.DB';
      // Try to find the table
      if (FileExists(sTestDir + sTableFilename)) then
      begin
        // If the file exists and we do not require all files to be present,
        // then we have at least a partial
        if (not fAllFiles) then
          bFilesFound := TRUE;
      end // if
      else
        // If the file does not exist and we require all files to be present,
        // then this could not be a full database.
        if (fAllFiles) then
        begin
          bFilesFound := FALSE;
          sDBUC_DBUpgResult := sDBUC_DBUpgResult + ' - ' + sTableFilename;
        end; // if
    end; // for

    // If no errors, kill the error message
    if (bFilesFound) then
      sDBUC_DBUpgResult := '';
  end; // if
end; // CheckDatabaseFiles

// ***************************************************************************
//
//  FUNCTION  : CheckDatabaseValidity
//
//  I/P       : sTestDir (string) - The directory which contains the
//                database is to be tested.
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
// ***************************************************************************
procedure CheckDatabaseValidity(sTestDir :string);
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
  index_nos : TStringList;
  index_info : TStringList;
  index_line : string;            // The ini's line of index information
  index_name : string;
  index_fields : string;
  index_flags : string;
  index_flagsi : integer;


begin
  // Show we are busy
  Screen.Cursor := crHourGlass;

  // Initially assume all is OK
  sDBUC_DBUpgResult := '';

  // Check that we have an information file for the database upgrade program
  if (AccessedDBDefinitionFiles) then
  begin
    // Fix up the data directory location if it does not already end in a '\'
    sTestDir := IncludeTrailingPathDelimiter(sTestDir);

    // Cycle through all the tables to be checked
    iCurrentTable := 1;
    while ((iCurrentTable <= iDBUC_iTablesInDB) and
           (sDBUC_DBUpgResult = '')) do
    begin
      GotTableInformationFromIndex(iCurrentTable);
      // If the file does exist, check its validity
      if (FileExists(sTestDir + sDBUC_TableFilename)) then
      begin

        with tParSource do
        begin
          Close;
          DatabaseName := sTestDir;
          TableName := sDBUC_TableFilename;
          Open;
        end; // with

        // Create the storage space for the list of fields in this table.
        field_nos := TStringList.Create;
        field_info := TStringList.Create;

        // Read in the list of the fields that are expected to be in this table.
        mifDBUC_TableDefn.ReadSection('1.LatestFields',field_nos);
        mifDBUC_TableDefn.ReadSectionValues('1.LatestFields',field_info);

        // Now check the indexes.
        // Check that there are the correct number of fields
        if (tParSource.FieldDefs.Count=field_nos.Count) then
        begin
          // Scan through all the fields
          for n := 0 to tParSource.FieldDefs.Count-1 do
          begin
            field_line := field_info.Values[field_nos.Strings[n]];
            // Check the format of the line
            if (Count_Chars(field_line,',')>=3) then
            begin
              // Format of info given appears correct
              field_name := Copy(field_line,1,Pos(',',field_line)-1);
              field_line := Copy(field_line,Pos(',',field_line)+1,255);
              field_datatype := GetANSFieldDataType(field_line[1]);
              if (field_datatype = ftUnknown) then
                 sDBUC_DBUpgResult := 'An unknown field type was found in the ' +
                                      mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table.' + #13 +
                                      #13 +
                                      sAgentHelp;

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

              // Check if there was an error in the field definition
              if (UpperCase(tParSource.FieldDefs.Items[n].Name)<>UpperCase(field_name)) or
                 (tParSource.FieldDefs.Items[n].DataType<>field_datatype) or
                 (tParSource.FieldDefs.Items[n].Size<>field_size) or
                 (tParSource.FieldDefs.Items[n].Required<>field_required) then
                // Error in name, type, size or required, therefore table is not the latest version
                sDBUC_DBUpgResult := 'The version of the ' +
                                     mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table is not correct.' + #13 +
                                     'Please upgrade the database.';
            end // if
            else
              // Error in field information given.
              sDBUC_DBUpgResult := 'There is a field information error in the ' +
                  mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table.' + #13 +
                  '(' + field_line + ')' + #13 +
                  #13 +
                  sAgentHelp;
          end; // for

        end // if
        else
          // This table does not have the same number of fields as the most recent, so obviously
          // it cannot be the latest table version
          sDBUC_DBUpgResult := 'The version of the ' +
                               mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table is not correct.' + #13 +
                               'Please upgrade the database.';

        if (sDBUC_DBUpgResult = '') then
        begin
          // If there is no fields error, scan through all the indexes
          index_nos := TStringList.Create;
          index_info := TStringList.Create;

          // Read in the list of the fields that are expected to be in this table.
          mifDBUC_TableDefn.ReadSection('1.LatestIndexes',index_nos);
          mifDBUC_TableDefn.ReadSectionValues('1.LatestIndexes',index_info);

          // Now check the indexes.
          // Check that there are the correct number of indexes
          if (tParSource.IndexDefs.Count=index_nos.Count) then
          begin
            // Scan through all the indexes
            for n := 0 to tParSource.IndexDefs.Count-1 do
            begin
              index_line := index_info.Values[index_nos.Strings[n]];
              // Check the format of the line
              if (Count_Chars(index_line,',')>=2) then
              begin
                // Format of info given appears correct
                index_name := ExtractAndTrim(index_line,',');
                index_fields := ExtractAndTrim(index_line,',');
                index_flags := ExtractAndTrim(index_line,',');
                // IndexDefs has the indexes in the order in which they
                // were originally created, so matching can be problematic!
                //!!ANS*BUSY HERE
              end; // if
            end; // for
          end // if
          else
            sDBUC_DBUpgResult := 'The indexes of the ' +
                                 mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table are not correct.' + #13 +
                                 'Please upgrade the database.';
          // Free up the space used by these variables
          index_nos.Free;
          index_info.Free;
        end; // if

        // Close the table
        tParSource.Close;

        // Free up the space used by these variables
        field_nos.Free;
        field_info.Free;
      end // if
      else
        // A table file is missing from the database
        sDBUC_DBUpgResult := 'The ' +
                             mifDBUC_DBDefn.ReadString('Descriptions',IntToStr(iCurrentTable),'#'+IntToStr(iCurrentTable)) + ' table is missing from the database.' + #13 +
                             'Please upgrade the database.';

      // Move on to the next table
      Inc(iCurrentTable);
    end; // for
  end; // if

  Screen.Cursor := crDefault;   // Show we are finished
end; // CheckDatabaseValidity

// ***************************************************************************
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
// ***************************************************************************
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
        result := TransferredFieldContents(tSource, tParDestination, map_info.Values[map_nos.Strings[n]], n);
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
    tParSource.FieldDefs.Update;
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
        sMapSection := IntToStr('1.' + sSourceVer + 'Map';

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
                      sAgentHelp;
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
          (Copy(sFieldMap,1,2)='fn')) then
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
  tParDestination := TTable.Create(nil);
  tParSource := TTable.Create(nil);
end;


//***************************************************************************
finalization
begin
  tParDestination.Free;
  tParSource.Free;
end;

end.

