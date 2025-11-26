unit REST_Ops;

interface

uses
  REST.Client;

type
  TAfterExecuteProc = procedure(Sender: TCustomRESTRequest) of object;

procedure AddQuery(var queries : String;
                   keyName : String;
                   keyValue : String);
function FixRESTQueries(queries : String) : String;


implementation

//***************************************************************************
//
//  FUNCTION  : AddQuery
//
//  I/P       : var queries : String - Any existing queries
//
//              keyName : String - Must include the '=' if there is a value
//
//              keyValue : String
//
//  O/P       : var queries : String - Updated
//
//  OPERATION : Add the given keyName (and keyValues) to an existing query
//              string. Manage the initial '?' and subsequency '&' separators.
//
//  UPDATED   : 2020-05-11
//
//***************************************************************************
procedure AddQuery(var queries : String;
                   keyName : String;
                   keyValue : String);
begin
  if (keyName <> '') then
  begin
    if (queries = '') then
    begin
      queries := '?' + keyName;
    end // if
    else
    begin
      queries := queries + '&' + keyName;
    end; // else

    if (keyValue <> '') then
    begin
      queries := queries + '=' + keyValue;
    end;
  end; // if
end; // AddQuery

//***************************************************************************
//
//  FUNCTION  : FixRESTQueries
//
//  I/P       : queries : String - A string containing zero or more queries.
//
//  O/P       : String - If queries exist, the first character should be '?'
//
//  OPERATION : Ensure that the given string, which may contain zero or more
//              queries, is correctly formatted, to start with '?'.
//
//  UPDATED   : 2020-02-20
//
//***************************************************************************
function FixRESTQueries(queries : String) : String;
begin
  if (Length(queries) > 1) then
  begin
    if (queries[1] = '&') then
    begin
      queries[1] := '?';
    end
    else if (queries[1] <> '?') then
    begin
      queries := '?' + queries;
    end;
  end; // if
  Result := queries;
end; // FixRESTQueries

end.
