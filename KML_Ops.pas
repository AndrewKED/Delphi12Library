unit KML_Ops;

//***************************************************************************
//
//  Parse KML files that define placemarks with polygon boundaries (e.g. field
//  boundaries), for ingestion into the geofences implementation.
//
//  Supports: <Placemark><name>...</name>...<coordinates>lon,lat,alt ...</coordinates>
//  KML coordinate order is longitude,latitude[,altitude]; we convert to lat,long
//  for use with TGeofence. MultiGeometry (multiple Polygon per Placemark) yields
//  one polygon item per ring, with disambiguated names where needed.
//
//***************************************************************************

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections;

type
  // One polygon from KML: display name and vertices (latitude, longitude).
  TKMLPolygonItem = class
  private
    FName: string;
    FLatitudes: TArray<Double>;
    FLongitudes: TArray<Double>;
    function GetCount: Integer;
    function GetLatitude(i: Integer): Double;
    function GetLongitude(i: Integer): Double;
  public
    constructor Create(const AName: string);
    procedure AddVertex(const ALatitude, ALongitude: Double);

    property Name: string read FName write FName;
    property Count: Integer read GetCount;
    property Latitude[i: Integer]: Double read GetLatitude;
    property Longitude[i: Integer]: Double read GetLongitude;
  end;

function ParseKMLFile(const AFileName: string;
                      out AList: TObjectList<TKMLPolygonItem>): Boolean;
function DefaultKMLFolder: string;

implementation

uses
  System.Math,
  Str_Ops;

const
  TAG_PLACEMARK_O = '<Placemark';
  TAG_PLACEMARK_C = '</Placemark>';
  TAG_NAME_O = '<name>';
  TAG_NAME_C = '</name>';
  TAG_COORDS_O = '<coordinates>';
  TAG_COORDS_C = '</coordinates>';

//***************************************************************************
//
// OPERATION : Return the default folder for KML files (e.g. application
//             directory + 'KML'). Used as initial directory for file dialogs.
//
// I/P : None
//
// O/P : String - Trailing path delimiter included
//
//***************************************************************************
function DefaultKMLFolder: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'KML');
end;

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function PosEx(const ASub, AStr: string; AOffset: Integer): Integer;
var
  i: Integer;

begin
  Result := 0;
  if ((ASub = '') or
      (AOffset < 1) or
      (AOffset > Length(AStr))) then
  begin
    Exit;
  end;

  for i := AOffset to Length(AStr) - Length(ASub) + 1 do
  begin
    if Copy(AStr, i, Length(ASub)) = ASub then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
function ExtractTagContent(const ASource, ATagOpen, ATagClose: string;
  var AStart: Integer; out AContent: string): Boolean;
var
  p, q, r: Integer;
begin
  Result := False;
  AContent := '';
  p := PosEx(ATagOpen, ASource, AStart);
  if p <= 0 then Exit;
  q := p + Length(ATagOpen);
  r := PosEx(ATagClose, ASource, q);
  if r <= 0 then Exit;
  AContent := Copy(ASource, q, r - q).Trim;
  AStart := r + Length(ATagClose);
  Result := True;
end;

//***************************************************************************
//
//  OPERATION :
//
//  I/P       :
//
//  O/P       :
//
//***************************************************************************
procedure ParseCoordinateString(const ACoordText: string; AItem: TKMLPolygonItem);
var
  s, t: string;
  parts: TArray<string>;
  lonStr, latStr: string;
  lonVal, latVal: Double;
  p: Integer;
begin
  // KML: "lon,lat,alt lon,lat,alt ..." with spaces/newlines/tabs between tuples
  s := ACoordText.Trim;
  if s = '' then Exit;
  p := 1;
  while p <= Length(s) do
  begin
    // Skip whitespace
    while (p <= Length(s)) and (s[p] in [#9, #10, #13, ' ']) do Inc(p);
    if p > Length(s) then Break;
    t := '';
    while (p <= Length(s)) and (not (s[p] in [#9, #10, #13, ' '])) do
    begin
      t := t + s[p];
      Inc(p);
    end;
    if t = '' then Continue;
    parts := t.Split([',']);
    if Length(parts) >= 2 then
    begin
      lonStr := Trim(parts[0]);
      latStr := Trim(parts[1]);
      if TryStrToFloat(lonStr, lonVal, TFormatSettings.Invariant) and
         TryStrToFloat(latStr, latVal, TFormatSettings.Invariant) then
        AItem.AddVertex(latVal, lonVal);
    end;
  end;
end;

//***************************************************************************
//
// OPERATION  : Parse a KML file and return a list of polygon items (one per
//             outer boundary ring). Caller must free the list and its items.
//
// I/P        : AFileName: string - Full path to the .kml file
//
// O/P        : AList: TObjectList<TKMLPolygonItem> - Parsed polygons (owned by caller)
//
//      Returns True if at least one polygon was parsed; False on file error
//      or no valid Placemark/coordinates found.
//
//***************************************************************************
function ParseKMLFile(const AFileName: string;
                      out AList: TObjectList<TKMLPolygonItem>): Boolean;
var
  sl: TStringList;
  content, placeBlock, nameText, coordText, baseName: string;
  polygonIndex: Integer;
  idxPlacemarkStart : Integer;
  idxPlacemarkEnd : Integer;
  idxNameStart : Integer;
  idxCoordinatesStart : Integer;
  item: TKMLPolygonItem;
  addNameIndexes : Boolean;

begin
  AList := TObjectList<TKMLPolygonItem>.Create(True);
  Result := False;

  if (not FileExists(AFileName)) then
  begin
    Exit;
  end;

  sl := TStringList.Create;
  try
    sl.LoadFromFile(AFileName, TEncoding.UTF8);
    content := sl.Text;
  finally
    sl.Free;
  end;

  idxPlacemarkStart := 1;
  while (TRUE) do
  begin
    // Find the index of the next '<Placemark>'
    idxPlacemarkStart := Pos(TAG_PLACEMARK_O, content, idxPlacemarkStart);
    if (idxPlacemarkStart <= 0) then
    begin
      Break;
    end;
    // Find the index of terminating '</Placemark>'
    idxPlacemarkEnd := PosEx(TAG_PLACEMARK_C, content, idxPlacemarkStart);
    if (idxPlacemarkEnd <= 0) then
    begin
      Break;
    end;

    // Extract the <Placemark> element
    placeBlock := Copy(content, idxPlacemarkStart, idxPlacemarkEnd - idxPlacemarkStart + Length(TAG_PLACEMARK_C));

    // Extract (or create) the (base)name field from the '<name>' element
    baseName := '';
    idxNameStart := 1;
    if (ExtractTagContent(placeBlock, TAG_NAME_O, TAG_NAME_C, idxNameStart, nameText)) then
    begin
      baseName := nameText.Trim;
    end;
    if (baseName = '') then
    begin
      baseName := 'Imported';
    end;

    polygonIndex := 1;
    addNameIndexes := (CountStrings(placeBlock, TAG_COORDS_O) > 1);
    idxCoordinatesStart := 1;
    // Search for all the <coordinates> elements in the <Placemark> element
    while ExtractTagContent(placeBlock, TAG_COORDS_O, TAG_COORDS_C, idxCoordinatesStart, coordText) do
    begin
      // A <coordinates> element has been found
      item := TKMLPolygonItem.Create(baseName);
      try
        if (addNameIndexes) then
        begin
          item.Name := baseName + ' (' + polygonIndex.ToString + ')';
        end;
        ParseCoordinateString(coordText, item);
        if (item.Count >= 3) then
        begin
          AList.Add(item);
          item := nil;
          Result := True;
        end;
      finally
        FreeAndNil(item);
      end;
      Inc(polygonIndex);
      Inc(idxCoordinatesStart, Length(TAG_PLACEMARK_C));
    end; // while

    Inc(idxPlacemarkStart, idxCoordinatesStart);
  end; // while
end;

{ TKMLPolygonItem }

constructor TKMLPolygonItem.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  SetLength(FLatitudes, 0);
  SetLength(FLongitudes, 0);
end;

procedure TKMLPolygonItem.AddVertex(const ALatitude, ALongitude: Double);
var
  n: Integer;
begin
  n := Length(FLatitudes);
  SetLength(FLatitudes, n + 1);
  SetLength(FLongitudes, n + 1);
  FLatitudes[n] := ALatitude;
  FLongitudes[n] := ALongitude;
end;

function TKMLPolygonItem.GetCount: Integer;
begin
  Result := Length(FLatitudes);
end;

function TKMLPolygonItem.GetLatitude(i: Integer): Double;
begin
  if (i < 0) or (i >= Length(FLatitudes)) then
    Result := 0.0
  else
    Result := FLatitudes[i];
end;

function TKMLPolygonItem.GetLongitude(i: Integer): Double;
begin
  if (i < 0) or (i >= Length(FLongitudes)) then
    Result := 0.0
  else
    Result := FLongitudes[i];
end;

end.
