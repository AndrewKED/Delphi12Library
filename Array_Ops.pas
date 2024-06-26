unit Array_Ops;

// See https://stackoverflow.com/questions/15923602/why-cant-i-return-arbitrary-array-of-string/15924484#15924484

interface

uses
  System.Generics;

type
  TArray = class(Generics.Collections.TArray)
  private
    class function Comparison<T>(SortType: TSortType): TComparison<T>; static;
    class function Comparer<T>(const Comparison: TComparison<T>): IComparer<T>; static;
  public
    class procedure Swap<T>(var Left, Right: T); static;
    class procedure Reverse<T>(var Values: array of T); static;
    class function Reversed<T>(const Values: array of T): TArray<T>; static;
    class function Contains<T>(const Values: array of T; const Item: T; out ItemIndex: Integer): Boolean; overload; static;
    class function Contains<T>(const Values: array of T; const Item: T): Boolean; overload; static;
    class function IndexOf<T>(const Values: array of T; const Item: T): Integer; static;
    class function Sorted<T>(var Values: array of T; SortType: TSortType; Index, Count: Integer): Boolean; overload; static;
    class function Sorted<T>(var Values: array of T; SortType: TSortType): Boolean; overload; static;
    class function Sorted<T>(var Values: array of T; const Comparison: TComparison<T>; Index, Count: Integer): Boolean; overload; static;
    class function Sorted<T>(var Values: array of T; const Comparison: TComparison<T>): Boolean; overload; static;
    class function Sorted<T>(GetValue: TFunc<Integer,T>; const Comparison: TComparison<T>; Index, Count: Integer): Boolean; overload; static;
    class procedure Sort<T>(var Values: array of T; SortType: TSortType; Index, Count: Integer); overload; static;
    class procedure Sort<T>(var Values: array of T; SortType: TSortType); overload; static;
    class procedure Sort<T>(var Values: array of T; const Comparison: TComparison<T>; Index, Count: Integer); overload; static;
    class procedure Sort<T>(var Values: array of T; const Comparison: TComparison<T>); overload; static;
    class function Copy<T>(const Source: array of T; Index, Count: Integer): TArray<T>; overload; static;
    class function Copy<T>(const Source: array of T): TArray<T>; overload; static;
    class procedure Move<T>(const Source: array of T; var Dest: array of T; Index, Count: Integer); overload; static;
    class procedure Move<T>(const Source: array of T; var Dest: array of T); overload; static;
    class function Concatenated<T>(const Source1, Source2: array of T): TArray<T>; overload; static;
    class function Concatenated<T>(const Source: array of TArray<T>): TArray<T>; overload; static;
    class procedure Initialise<T>(var Values: array of T; const Value: T); static;
    class procedure Zeroise<T>(var Values: array of T); static;
    class function GetHashCode<T>(const Values: array of T): Integer; overload; static;
    class function GetHashCode<T>(Values: Pointer; Count: Integer): Integer; overload; static;
  end;

class function TArray.Comparison<T>(SortType: TSortType): TComparison<T>;
var
  DefaultComparer: IComparer<T>;
begin
  DefaultComparer := TComparer<T>.Default;
  Result :=
    function(const Left, Right: T): Integer
    begin
      case SortType of
      stIncreasing:
        Result := DefaultComparer.Compare(Left, Right);
      stDecreasing:
        Result := -DefaultComparer.Compare(Left, Right);
      else
        RaiseAssertionFailed(Result);
      end;
    end;
end;

class function TArray.Comparer<T>(const Comparison: TComparison<T>): IComparer<T>;
begin
  Result := TComparer<T>.Construct(Comparison);
end;

class procedure TArray.Swap<T>(var Left, Right: T);
var
  temp: T;
begin
  temp := Left;
  Left := Right;
  Right := temp;
end;

class procedure TArray.Reverse<T>(var Values: array of T);
var
  bottom, top: Integer;
begin
  bottom := 0;
  top := high(Values);
  while top>bottom do begin
    Swap<T>(Values[bottom], Values[top]);
    inc(bottom);
    dec(top);
  end;
end;

class function TArray.Reversed<T>(const Values: array of T): TArray<T>;
var
  i, j, Count: Integer;
begin
  Count := Length(Values);
  SetLength(Result, Count);
  j := Count-1;
  for i := 0 to Count-1 do begin
    Result[i] := Values[j];
    dec(j);
  end;
end;

class function TArray.Contains<T>(const Values: array of T; const Item: T; out ItemIndex: Integer): Boolean;
var
  DefaultComparer: IEqualityComparer<T>;
  Index: Integer;
begin
  DefaultComparer := TEqualityComparer<T>.Default;
  for Index := 0 to high(Values) do begin
    if DefaultComparer.Equals(Values[Index], Item) then begin
      ItemIndex := Index;
      Result := True;
      exit;
    end;
  end;
  ItemIndex := -1;
  Result := False;
end;

class function TArray.Contains<T>(const Values: array of T; const Item: T): Boolean;
var
  ItemIndex: Integer;
begin
  Result := Contains<T>(Values, Item, ItemIndex);
end;

class function TArray.IndexOf<T>(const Values: array of T; const Item: T): Integer;
begin
  Contains<T>(Values, Item, Result);
end;

class function TArray.Sorted<T>(var Values: array of T; SortType: TSortType; Index, Count: Integer): Boolean;
begin
  Result := Sorted<T>(Values, Comparison<T>(SortType), Index, Count);
end;

class function TArray.Sorted<T>(var Values: array of T; SortType: TSortType): Boolean;
begin
  Result := Sorted<T>(Values, Comparison<T>(SortType));
end;

class function TArray.Sorted<T>(var Values: array of T; const Comparison: TComparison<T>; Index, Count: Integer): Boolean;
var
  i: Integer;
begin
  for i := Index+1 to Index+Count-1 do begin
    if Comparison(Values[i-1], Values[i])>0 then begin
      Result := False;
      exit;
    end;
  end;
  Result := True;
end;

class function TArray.Sorted<T>(var Values: array of T; const Comparison: TComparison<T>): Boolean;
begin
  Result := Sorted<T>(Values, Comparison, 0, Length(Values));
end;

class function TArray.Sorted<T>(GetValue: TFunc<Integer, T>; const Comparison: TComparison<T>; Index, Count: Integer): Boolean;
var
  i: Integer;
begin
  for i := Index+1 to Index+Count-1 do begin
    if Comparison(GetValue(i-1), GetValue(i))>0 then begin
      Result := False;
      exit;
    end;
  end;
  Result := True;
end;

class procedure TArray.Sort<T>(var Values: array of T; SortType: TSortType; Index, Count: Integer);
begin
  Sort<T>(Values, Comparison<T>(SortType), Index, Count);
end;

class procedure TArray.Sort<T>(var Values: array of T; SortType: TSortType);
begin
  Sort<T>(Values, SortType, 0, Length(Values));
end;

class procedure TArray.Sort<T>(var Values: array of T; const Comparison: TComparison<T>; Index, Count: Integer);
begin
  if not Sorted<T>(Values, Comparison, Index, Count) then begin
    Sort<T>(Values, Comparer<T>(Comparison), Index, Count);
  end;
end;

class procedure TArray.Sort<T>(var Values: array of T; const Comparison: TComparison<T>);
begin
  Sort<T>(Values, Comparison, 0, Length(Values));
end;

class function TArray.Copy<T>(const Source: array of T; Index, Count: Integer): TArray<T>;
var
  i: Integer;
begin
  SetLength(Result, Count);
  for i := 0 to high(Result) do begin
    Result[i] := Source[i+Index];
  end;
end;

class function TArray.Copy<T>(const Source: array of T): TArray<T>;
var
  i: Integer;
begin
  SetLength(Result, Length(Source));
  for i := 0 to high(Result) do begin
    Result[i] := Source[i];
  end;
end;

class procedure TArray.Move<T>(const Source: array of T; var Dest: array of T; Index, Count: Integer);
var
  i: Integer;
begin
  for i := 0 to Count-1 do begin
    Dest[i] := Source[i+Index];
  end;
end;

class procedure TArray.Move<T>(const Source: array of T; var Dest: array of T);
var
  i: Integer;
begin
  for i := 0 to high(Source) do begin
    Dest[i] := Source[i];
  end;
end;

class function TArray.Concatenated<T>(const Source1, Source2: array of T): TArray<T>;
var
  i, Index: Integer;
begin
  SetLength(Result, Length(Source1)+Length(Source2));
  Index := 0;
  for i := low(Source1) to high(Source1) do begin
    Result[Index] := Source1[i];
    inc(Index);
  end;
  for i := low(Source2) to high(Source2) do begin
    Result[Index] := Source2[i];
    inc(Index);
  end;
end;

class function TArray.Concatenated<T>(const Source: array of TArray<T>): TArray<T>;
var
  i, j, Index, Count: Integer;
begin
  Count := 0;
  for i := 0 to high(Source) do begin
    inc(Count, Length(Source[i]));
  end;
  SetLength(Result, Count);
  Index := 0;
  for i := 0 to high(Source) do begin
    for j := 0 to high(Source[i]) do begin
      Result[Index] := Source[i][j];
      inc(Index);
    end;
  end;
end;

class procedure TArray.Initialise<T>(var Values: array of T; const Value: T);
var
  i: Integer;
begin
  for i := 0 to high(Values) do begin
    Values[i] := Value;
  end;
end;

class procedure TArray.Zeroise<T>(var Values: array of T);
begin
  Initialise<T>(Values, Default(T));
end;

{$IFOPT Q+}
  {$DEFINE OverflowChecksEnabled}
  {$Q-}
{$ENDIF}
class function TArray.GetHashCode<T>(const Values: array of T): Integer;
// see http://stackoverflow.com/questions/1646807 and http://stackoverflow.com/questions/11294686
var
  Value: T;
  EqualityComparer: IEqualityComparer<T>;
begin
  EqualityComparer := TEqualityComparer<T>.Default;
  Result := 17;
  for Value in Values do begin
    Result := Result*37 + EqualityComparer.GetHashCode(Value);
  end;
end;

class function TArray.GetHashCode<T>(Values: Pointer; Count: Integer): Integer;
// see http://stackoverflow.com/questions/1646807 and http://stackoverflow.com/questions/11294686
var
  Value: ^T;
  EqualityComparer: IEqualityComparer<T>;
begin
  EqualityComparer := TEqualityComparer<T>.Default;
  Result := 17;
  Value := Values;
  while Count>0 do begin
    Result := Result*37 + EqualityComparer.GetHashCode(Value^);
    inc(Value);
    dec(Count);
  end;
end;
{$IFDEF OverflowChecksEnabled}
  {$Q+}
{$ENDIF}


implementation

end.
