unit DB_Ops;

interface

uses
  Data.DB;

function DataSetContainsRecords(ds : TDataSet) : Boolean;
procedure UpdateTableFields(ds : TDataSet);
procedure AddStringLookupField(ds : TDataSet;
                               fieldName : String;
                               size : Integer;
                               lookupDataSet : TDataSet;
                               keyFields : String;
                               lookupKeyFields : String;
                               lookupResultField : String);
procedure AddFloatLookupField(ds : TDataSet;
                              fieldName : String;
                              lookupDataSet : TDataSet;
                              keyFields : String;
                              lookupKeyFields : String;
                              lookupResultField : String);
procedure AddBooleanLookupField(ds : TDataSet;
                                fieldName : String;
                                lookupDataSet : TDataSet;
                                keyFields : String;
                                lookupKeyFields : String;
                                lookupResultField : String);

implementation

//***************************************************************************
//
//  FUNCTION  : DataSetContainsRecords
//
//  I/P       : ds : TDataSet - The data set to be examined
//
//  O/P       : Boolean - TRUE if the dataset contains records
//
//  OPERATION : Check if the given data set contains records.
//
//              Question : Is this better than using RecordCount?
//
//  UPDATED   : 2022-05-06
//
//***************************************************************************
function DataSetContainsRecords(ds : TDataSet) : Boolean;
begin
  result := (not ds.Bof) or (not ds.Eof);
end; // DataSetContainsRecords

//***************************************************************************
//
//  FUNCTION  : UpdateTableFields
//
//  I/P       : ds : TDataSet - The data set to which fields must be added
//
//  O/P       : None
//
//  OPERATION : Create the default persistent fields in a given data set.
//
//              This might be used prior to adding dynamically assigned
//              calculated/lookup fields.
//
//  UPDATED   : 2022-05-06
//
//***************************************************************************
procedure UpdateTableFields(ds : TDataSet);
var
  newField : TField;
  i : Integer;

begin
  ds.FieldDefs.Update;
  for i := 0 to ds.FieldDefs.Count - 1 do
  begin
    // Here is where we actually tell the dataset to allocate a field.
    // newField gets assigned but we don't need it - just points to new field.
    newField := ds.FieldDefs[i].CreateField(ds);
  end; // for
end; // UpdateTableFields

//***************************************************************************
//
//  FUNCTION  : AddStringLookupField
//
//  I/P       : ds : TDataSet - The dataset to which the field must be added
//
//              fieldName : String - The new field name
//
//              size : Integer - The character size of the field
//
//              lookupDataSet : TDataSet - The lookup dataset
//
//              keyFields : String - The key field/s in the dataset
//
//              lookupKeyFields : String - The key field/s in the lookup dataset
//
//              lookupResultField : String - The result field in the lookup dataase
//
//  O/P       : None
//
//  OPERATION : Configure a lookup string field in a data set.
//
//              Fixed, persistent fields should be updated first, using the
//              UpdateTableFields function, above.
//
//  UPDATED   : 2022-05-06
//
//***************************************************************************
procedure AddStringLookupField(ds : TDataSet;
                               fieldName : String;
                               size : Integer;
                               lookupDataSet : TDataSet;
                               keyFields : String;
                               lookupKeyFields : String;
                               lookupResultField : String);
var
  newField : TField;

begin
  newField := TStringField.Create(ds);
  newField.FieldName := fieldName;
  newField.Size := size;
  newField.FieldKind := fkLookup;
  newField.DataSet := ds;
  newField.Lookup := TRUE;
  newField.LookupDataSet := lookupDataSet;
  newField.KeyFields := keyFields;
  newField.LookupKeyFields := lookupKeyFields;
  newField.LookupResultField := lookupResultField;
end; // AddStringLookupField

//***************************************************************************
//
//  FUNCTION  : AddFloatLookupField
//
//  I/P       : ds : TDataSet - The dataset to which the field must be added
//
//              fieldName : String - The new field name
//
//              lookupDataSet : TDataSet - The lookup dataset
//
//              keyFields : String - The key field/s in the dataset
//
//              lookupKeyFields : String - The key field/s in the lookup dataset
//
//              lookupResultField : String - The result field in the lookup dataase
//
//  O/P       : None
//
//  OPERATION : Configure a lookup float field in a data set.
//
//              Fixed, persistent fields should be updated first, using the
//              UpdateTableFields function, above.
//
//  UPDATED   : 2022-05-06
//
//***************************************************************************
procedure AddFloatLookupField(ds : TDataSet;
                              fieldName : String;
                              lookupDataSet : TDataSet;
                              keyFields : String;
                              lookupKeyFields : String;
                              lookupResultField : String);
var
  newField : TField;

begin
  newField := TFloatField.Create(ds);
  newField.FieldName := fieldName;
  newField.FieldKind := fkLookup;
  newField.DataSet := ds;
  newField.Lookup := TRUE;
  newField.LookupDataSet := lookupDataSet;
  newField.KeyFields := keyFields;
  newField.LookupKeyFields := lookupKeyFields;
  newField.LookupResultField := lookupResultField;
end; // AddFloatLookupField

//***************************************************************************
//
//  FUNCTION  : AddBooleanLookupField
//
//  I/P       : ds : TDataSet - The dataset to which the field must be added
//
//              fieldName : String - The new field name
//
//              lookupDataSet : TDataSet - The lookup dataset
//
//              keyFields : String - The key field/s in the dataset
//
//              lookupKeyFields : String - The key field/s in the lookup dataset
//
//              lookupResultField : String - The result field in the lookup dataase
//
//  O/P       : None
//
//  OPERATION : Configure a lookup boolean field in a data set.
//
//              Fixed, persistent fields should be updated first, using the
//              UpdateTableFields function, above.
//
//  UPDATED   : 2023-09-26
//
//***************************************************************************
procedure AddBooleanLookupField(ds : TDataSet;
                                fieldName : String;
                                lookupDataSet : TDataSet;
                                keyFields : String;
                                lookupKeyFields : String;
                                lookupResultField : String);
var
  newField : TField;

begin
  newField := TBooleanField.Create(ds);
  newField.FieldName := fieldName;
  newField.FieldKind := fkLookup;
  newField.DataSet := ds;
  newField.Lookup := TRUE;
  newField.LookupDataSet := lookupDataSet;
  newField.KeyFields := keyFields;
  newField.LookupKeyFields := lookupKeyFields;
  newField.LookupResultField := lookupResultField;
end; // AddBooleanLookupField

end.
