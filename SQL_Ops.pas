unit SQL_Ops;

interface

uses
  FireDAC.Comp.Client;

const
  // Just useful reminders of how to test(!)
  // (Keep the leading space in place)
  // https://www.w3schools.com/sql/sql_null_values.asp
  IS_NULL = ' IS NULL';
  IS_NOT_NULL = ' IS NOT NULL';

  MYSQL_DATETIME_FORMAT = 'yyyy-mm-dd hh:nn:ss.zzz';
  MYSQL_YMDHN_FORMAT = 'yyyy-mm-dd hh:nn';
  MYSQL_DATE_FORMAT = 'yyyy-mm-dd';

procedure ExportMySQLSchema(connection : TFDConnection;
                            destination : String);

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  WinAPI.ShellAPI, WinAPI.Windows;

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
function GetMySQLInstallFolder(connection : TFDConnection) : String;
var
  installFolder : TFDQuery;

begin
  installFolder := TFDQuery.Create(nil);
  try
    installFolder.Connection := connection;

    installFolder.SQL.Text := 'SHOW VARIABLES LIKE ''basedir''';
    installFolder.Open;
    Result := installFolder.Fields[1].AsString;

  finally
    installFolder.Close;
    installFolder.Free;
  end; //
end;

//***************************************************************************
//
//  FUNCTION  : ExportMySQLSchema
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
procedure ExportMySQLSchema(connection : TFDConnection;
                            destination : String);
var
  tableList : TFDQuery;

  procedure ExportTable(const TableName: string);
  var
    command: String;
    parameters : String;

  begin
    command := '"' +IncludeTrailingPathDelimiter(GetMySQLInstallFolder(connection)) +
      'bin\mysqldump"';
    parameters := Format(
      '-u%s -p%s %s %s --result-file="%s%s_%s.sql"',
//      '-u%s -p%s %s %s > "%s%s_%s.sql"',
      [
        connection.Params.UserName,
        connection.Params.Password,
        connection.Params.Database,
        TableName,
        destination,
        connection.Params.Database,
        TableName
      ]
    );
    ShellExecute(Application.Handle, 'open', PChar(command), PChar(parameters), '', SW_HIDE);
  end; // ExportTable

begin
  tableList := TFDQuery.Create(nil);
  try
    tableList.Connection := connection;

    tableList.SQL.Text :=
      'SELECT TABLE_NAME' + sLineBreak +
      'FROM INFORMATION_SCHEMA.TABLES' + sLineBreak +
      'WHERE TABLE_SCHEMA = ''' + connection.Params.Database + '''';
    tableList.Open;

    while not tableList.Eof do
    begin
      ExportTable(tableList.Fields[0].AsString);
      tableList.Next;
    end;

  finally
    tableList.Close;
    tableList.Free;
  end; //
end; // ExportMySQLSchema

////***************************************************************************
////
////  FUNCTION  : ExportMySQLSchema
////
////  I/P       :
////
////  O/P       :
////
////  OPERATION :
////
////  UPDATED   :
////
////***************************************************************************
//procedure ExportMySQLSchema(connection : TFDConnection;
//                            destination : String);
//var
//  command: String;
//  parameters : String;
//
//begin
//  command := '"' +IncludeTrailingPathDelimiter(GetMySQLInstallFolder(connection)) +
//    'bin\mysqldump"';
//  parameters := Format(
//    '-u%s -p%s --single-transaction %s > "%s%s.sql"',
//    [
//      connection.Params.UserName,
//      connection.Params.Password,
//      connection.Params.Database,
//      IncludeTrailingPathDelimiter(destination),
//      connection.Params.Database
//    ]
//  );
//
//  ShellExecute(Application.Handle, 'open', PChar(command), PChar(parameters), '', SW_HIDE);
//end; // ExportMySQLSchema

end.
