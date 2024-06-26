unit MatLib;

interface

uses
  SysUtils, Classes, Forms, Dialogs, StdCtrls, Math;

const
  { Size of Extended }
  szExtended = SizeOf(Extended);
  szPointer = SizeOf(Pointer);

type
  { Array of Extended }
  PExtArray = ^TExtArray;
  TExtArray = array [0..MaxInt div szExtended - 1] of Extended;
  { Array of pointers }
  PPtrArray = ^TPtrArray;
  TPtrArray = array [0..MaxInt div szPointer - 1] of PExtArray;

type
  EMatrixException = class(Exception);

  TMatrix = class;
  TVector = class;
  TMatrixClass = class of TMatrix;
  TVectorClass = class of TVector;

  { TMatrix - base abstract class for matrices }
  TMatrix = class(TComponent)
  protected
    FColCount: Integer;
    FRowCount: Integer;
    { Must be overrided in decendent class !}
    function  GetCells(ARow, ACol: Integer): Extended; virtual; abstract;
    { Must be overrided in decendent class !}
    procedure SetCells(ARow, ACol: Integer; AValue: Extended); virtual; abstract;
    { Must be overrided in decendent class !}
    procedure SetRanges(NewRow, NewCol: Integer); virtual; abstract;
    procedure SetCols(Value: Integer);
    procedure SetRows(Value: Integer);
  public
    FClass: TMatrixClass;
    constructor Create(AOwner: TComponent); override;
    { Assign matrix from Source }
    procedure   Assign(Source: TMatrix);
    { Assign Value to all cells of matrix }
    procedure   AssignValue(Value: Extended);
    { Assign Values array to NLine row of matrix  }
    procedure   AssignToLine(NLine: Integer; Values: array of Extended);
    { Assign Values array to NCol column of matrix  }
    procedure   AssignToCol (NCol : Integer; Values: array of Extended);
    { Add matrix AMatrix to Self (this matrix) }
    procedure   Add(AMatrix: TMatrix);
    { Subtract matrix AMatrix from Self (this matrix) }
    procedure   Subtract(AMatrix: TMatrix);
    { Multiply Self by AMatrix }
    procedure   MultAsLeft(AMatrix: TMatrix);
    { Multiply Self by AMatrix }
    procedure   MultAsRight(AMatrix: TMatrix);
    { Multiply Self by Value }
    procedure   MultValue(Value: Extended);
    { Assign Value to diagonal elements (only square matrix) }
    procedure   MainBasis(Value: Extended);
    { Calculate determinant }
    function    Determinant: Extended;
    { Inverses matrix  }
    function   Inverse: boolean;
    { Transpose matrix }
    procedure   Transpose;
    { ExChanges rows (Rows) number i and j }
    procedure   ExChangeRows(i, j: Integer);
    { Add to i-row j-row muliplied by Factor }
    procedure   AddRows(i, j: integer; Factor: Extended);
    { Multiply all elements of i-row by Factor }
    procedure   MultLine(i: Integer; Factor: Extended);
    { Raise to power Pow  }
    procedure   Power(Pow: Integer);
    property Cells[ARow, ACol: Integer]: Extended read GetCells write SetCells; default;
    property ColCount: Integer read FColCount write SetCols;
    property RowCount: Integer read FRowCount write SetRows;
  end;

  { Matrix of Extended [(MaxInt div 4)x(MaxInt div 10) elements maximum) }
  TRealMatrix = class(TMatrix)
  protected
    FRows: PPtrArray;
    destructor  Destroy; override;
    function  GetCells(ARow, ACol: Integer): Extended; override;
    procedure SetCells(ARow, ACol: Integer; AValue: Extended); override;
    procedure SetRanges(NewRow, NewCol: Integer); override;
  public
    property Cells;
  published
    property ColCount;
    property RowCount;
  end;

  { Sparse matrix cell }
  PSCell = ^TSCell;
  TSCell = record
    Col, Row: Integer;  { location of this cell in the matrix }
    Value: Extended;    { value to hold in the cell }
  end;

  { Sparse matrix row }
  TSRow = class(TList)
  private
    FRowNum: Integer;
    function Get(Index: Integer): PSCell;
    procedure Put(Index: Integer; ACell: PSCell);
  public
    constructor Create(ARowNum: Integer);
    destructor  Destroy; override;
    property RowNum: Integer read FRowNum write FRowNum;
    property Items[Index: Integer]: PSCell read Get write Put;
    function Find(ACellCol: Integer; var Index: Integer): Boolean;
    function Add(const ACellCol: Integer; const AValue: Extended): Integer;
  end;

  { Sparse matrix row list }
  TRowList = class(TList)
  private
    function Get(Index: Integer): TSRow;
    procedure Put(Index: Integer; ARow: TSRow);
  public
    destructor Destroy; override;
    property Items[Index: Integer]: TSRow read Get write Put;
    function Find(ARowNum: Integer; var Index: Integer): Boolean;
    function Add(const ARowNum: Integer): Integer;
  end;

  { Sparse matrix }
  TSparseMatrix = class(TMatrix)
  protected
    FRows: TRowList;
    destructor  Destroy; override;
    function  GetCells(ARow, ACol: Integer): Extended; override;
    procedure SetCells(ARow, ACol: Integer; AValue: Extended); override;
    procedure SetRanges(NewRow, NewCol: Integer); override;
  public
    property Cells;
  published
    property ColCount;
    property RowCount;
  end;

  { TVector - base abstract class for vectors }
  TVector = class(TComponent)
  protected
    FCount: Integer;
    FClass: TVectorClass;
    { Must be overrided in decendent class !}
    function  GetCells(APos: Integer): Extended; virtual; abstract;
    { Must be overrided in decendent class !}
    procedure SetCells(APos: Integer; AValue: Extended); virtual; abstract;
    { Must be overrided in decendent class !}
    procedure SetCount(NewCount: Integer); virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
    { Assign Vector from Source }
    procedure   Assign(Source: TVector);
    { Assign Value to all cells of Vector }
    procedure   AssignValue(Value: Extended);
    { Add Vector AVector to Self (this Vector) }
    procedure   Add(AVector: TVector);
    {}
    procedure   Exchange(i, j: Integer);
    { Multiply Self by AVector }
    procedure   MultValue(Value: Extended);
    { Scalar product }
    function    ScalarProduct(AVector: TVector): Extended;
    { Transpose Vector }
    procedure   Transpose;
    property Cells[APos: Integer]: Extended read GetCells write SetCells; default;
    property Count: Integer read FCount write SetCount;
  end;

  { Vector of Extended [(MaxInt div 10) elements maximum) }
  TRealVector = class(TVector)
  protected
    FData: PExtArray;
    destructor  Destroy; override;
    function  GetCells(APos: Integer): Extended; override;
    procedure SetCells(APos: Integer; AValue: Extended); override;
    procedure SetCount(NewCount: Integer); override;
  public
    property Cells;
  published
    property Count;
  end;

  { Sparse Vector }
  TSparseVector = class(TVector)
  protected
    FData: TSRow;
    destructor  Destroy; override;
    function  GetCells(APos: Integer): Extended; override;
    procedure SetCells(APos: Integer; AValue: Extended); override;
    procedure SetCount(NewCount: Integer); override;
  public
    property Cells;
  published
    property Count;
  end;

{ Routines which returnes matrices. A and B matrices will not ExChange }
{ !!! Note that you are responsible for destroying returned matrix.  }
{ type of returned matrix is the same as A                           }

{ }
function SolveMatrix(AMatrix: TMatrix; BVector: TVector): Extended;
{ }
function SolveMatrixEx(AMatrix: TMatrix; BMatrix: TMatrix): Extended;
{ Inverses matrix A }
function M_Inverse(A: TMatrix): TMatrix;
{ MultAsLeftiply A * B  }
function M_Mult(A, B: TMatrix): TMatrix;
{ Add A to B, A + B }
function M_Add(A, B: TMatrix): TMatrix;
{ Subtract B from A, A - B }
function M_Subtract(A, B: TMatrix): TMatrix;
{ Mulltiply A by Value }
function M_MultValue(A: TMatrix; Value: Extended): TMatrix;
{ Raise A to power Pow  }
function M_Power(A: TMatrix; Pow: Integer): TMatrix;

{ My additional code - prefered method: fast (Above does'nt work for all matrix)}
function M_Solve(A, B, X: TMatrix): boolean;

procedure Register;

implementation


procedure Register;
begin
  RegisterComponents('Math', [TRealMatrix, TSparseMatrix, TRealVector, TSparseVector]);
end;

//*******************************************************************
//  Description: M_Calculate - Calculate one variable
//  Author:      Nico Bestbier
//  Date:        2/18/2002
//*******************************************************************

function M_Solve(A, B, X: TMatrix): boolean;
var
  col, row, i: integer;
  val: extended;
  AA, BB: TRealMatrix;
begin
  Result:=true;
  AA:=TRealMatrix.Create(nil);
  BB:=TRealMatrix.Create(nil);
  AA.Assign(A);
  BB.Assign(B);

  //Forward Pass
  for row:=0 to AA.RowCount-1 do begin
      for i:=row+1 to AA.RowCount-1 do begin
          if AA[i, row]<>0 then begin
             val:=AA[row, row]/AA[i, row];

             //Update A Row
             for col:=row to AA.ColCount-1 do begin
                 AA[i, col]:=AA[row, col] - AA[i, col]*val;
             end;

             //Update B Value
             BB[i, 0]:=BB[row, 0] - BB[i, 0]*val;
          end else begin
             //temp
             //beep;
          end;
      end;
  end;

  //Backward Pass
  for row:=AA.RowCount-1 downto 0 do begin
      for i:=row-1 downto 0 do begin
          if AA[i, row]<>0 then begin
             val:=AA[row, row]/AA[i, row];

             //Update A Row
             for col:=AA.ColCount-1 downto 0 do begin
                 AA[i, col]:=AA[row, col] - AA[i, col]*val;
             end;

             //Update B Value
             BB[i, 0]:=BB[row, 0] - BB[i, 0]*val;
           end else begin
             //temp
             //beep;
          end;
      end;
  end;

  //Calculate Identity Matrix
  for i:=0 to AA.ColCount-1 do begin
      if (AA[i, i] <> 0) then begin
         BB[i, 0]:=BB[i, 0]/AA[i, i];
      end else begin
         //Pivot is zero - no solution
         Result:=false;
      end;
  end;


  //Result
  X.Assign(BB);

  AA.Free;
  BB.Free;
end;


{ SolveMatrix uses Gaussian algorithm to transform AMatrix to identity matrix }
{ At the same time it perform same operation on BMatrix, as a result it }
{ returns determinant of AMatrix }
function SolveMatrixEx(AMatrix: TMatrix; BMatrix: TMatrix): Extended;
var
  i, j: Integer;
  Temp: Extended;
begin
  Result := 1;
  { Forward pass, choose main element <> 0 }
  for i := 0 to AMatrix.RowCount - 1 do
  begin
    j := 0;
    while j < AMatrix.RowCount do
      if AMatrix.Cells[i, j] <> 0 then break
                                  else inc(j);
    if j = AMatrix.RowCount then
    begin
      Result := 0;
      Exit;
    end;
    AMatrix.ExChangeRows(i, j);
    BMatrix.ExChangeRows(i, j);
    if not Odd(AMatrix.ColCount) then Result := -1 * Result;
    for j := i + 1 to AMatrix.RowCount - 1 do
    begin
      if (AMatrix.Cells[i, i] <>0 ) then begin
         Temp := AMatrix.Cells[j, i]/AMatrix.Cells[i, i];
         AMatrix.AddRows(j, i, -Temp);
         BMatrix.AddRows(j, i, -Temp);
      end else begin
         //temp
         //beep;
      end;
    end;
  end;

  { Backward pass }
  for i := AMatrix.RowCount - 1 downto 0 do
    for j := i - 1 downto 0 do
    begin
      if (AMatrix.Cells[i, i] <> 0) then begin
         Temp := AMatrix.Cells[j, i]/AMatrix.Cells[i, i];

         AMatrix.AddRows(j, i, -Temp);
         BMatrix.AddRows(j, i, -Temp);
      end else begin
         //temp
         //beep;
      end;
    end;


  { Divide diagonal elements by themself, making identity matrix }
  for i := 0 to AMatrix.RowCount - 1 do
  begin
    Result := Result * AMatrix.Cells[i, i];
    if (AMatrix.Cells[i, i] <>0 ) then begin
       Temp := 1/AMatrix.Cells[i, i];
       BMatrix.MultLine(i, Temp);
       AMatrix.MultLine(i, Temp);
    end else begin
       //temp
       //beep;
    end;
  end;
end;

function SolveMatrix(AMatrix: TMatrix; BVector: TVector): Extended;
var
  i, j: Integer;
  Temp: Extended;
  Factor: Integer;
begin
  Result := 1;
  { Forward pass, choose main element <> 0 }
  for i := 0 to AMatrix.RowCount - 1 do
  begin
    j := 0;
    while j < AMatrix.RowCount do
      if AMatrix.Cells[i, j] <> 0 then break
                                  else inc(j);
    if j = AMatrix.RowCount then
    begin
      Result := 0;
      Exit;
    end;
    AMatrix.ExChangeRows(i, j);
    BVector.ExChange(i, j);
    if not Odd(AMatrix.ColCount) then Result := -1 * Result;
    for j := i + 1 to AMatrix.RowCount - 1 do
    begin
      Temp := AMatrix.Cells[j, i]/AMatrix.Cells[i, i];
      AMatrix.AddRows(j, i, -Temp);
      BVector[j] := BVector[j] - Temp*BVector[i];
    end;
  end;

  { Backward pass }
  for i := AMatrix.RowCount - 1 downto 0 do
    for j := i - 1 downto 0 do
    begin
      Temp := AMatrix.Cells[j, i]/AMatrix.Cells[i, i];
      AMatrix.AddRows(j, i, -Temp);
      BVector[j] := BVector[j] - Temp*BVector[i];
    end;

  { Divide diagonal elements by themself, making identity matrix }
  for i := 0 to AMatrix.RowCount - 1 do
  begin
    Result := Result * AMatrix.Cells[i, i];
    Temp := 1/AMatrix.Cells[i, i];
    BVector[i] := BVector[i] * Temp;
    AMatrix.MultLine(i, Temp);
  end;
end;

function Min(Num1, Num2: Integer): Integer;
begin
  if Num1 < Num2 then Result := Num1
                 else Result := Num2;
end;

{ -- TMatrix -- }
constructor TMatrix.Create;
begin
  inherited Create(AOwner);
  FClass := TMatrixClass(ClassType);
  SetRanges(5, 5);
end;

procedure TMatrix.Assign(Source: TMatrix);
var
  i, j: Integer;
begin
  RowCount := Source.RowCount;
  ColCount := Source.ColCount;
  for i := 0 to RowCount - 1 do
    for j := 0 to ColCount - 1 do
      Cells[i,j] := Source[i, j];
end;

procedure TMatrix.AssignValue(Value: Extended);
var
  i, j: Integer;
begin
  for i := 0 to RowCount - 1 do
    for j := 0 to ColCount - 1 do
      Cells[i,j] := Value;
end;

procedure TMatrix.AssignToLine(NLine: Integer; Values: array of Extended);
var
  j, Min: Integer;
begin
  if (NLine >= RowCount) or (NLine < 0)
    then raise EMatrixException.Create('Invalid row number');
  if ColCount > High(Values)
    then Min := High(Values)
    else Min := ColCount - 1;
  for j := 0 to Min do
    Cells[NLine,j] := Values[j];
end;

procedure TMatrix.AssignToCol(NCol: Integer; Values: array of Extended);
var
  j, Min: Integer;
begin
  if (NCol >= ColCount) or (NCol < 0)
    then raise EMatrixException.Create('Invalid column number');
  if RowCount > High(Values)
    then Min := High(Values)
    else Min := RowCount - 1;
  for j := 0 to Min do
    Cells[j,NCol] := Values[j];
end;

procedure TMatrix.Add(AMatrix: TMatrix);
var
  i, j: Integer;
begin
  if (ColCount <> AMatrix.ColCount) or (RowCount <> AMatrix.RowCount)
    then raise EMatrixException.Create('Can not add these matrixes');
  for i := 0 to RowCount - 1 do
    for j := 0 to ColCount - 1 do
      Cells[i,j] := Cells[i,j] + AMatrix[i,j];
end;

procedure TMatrix.Subtract(AMatrix: TMatrix);
var
  i, j: Integer;
begin
  if (ColCount <> AMatrix.ColCount) or (RowCount <> AMatrix.RowCount)
    then raise EMatrixException.Create('Can not add these matrixes');
  for i := 0 to RowCount - 1 do
    for j := 0 to ColCount - 1 do
      Cells[i,j] := Cells[i,j] - AMatrix[i,j];
end;

procedure TMatrix.MultAsLeft(AMatrix: TMatrix);
var
  A: TMatrix;
  i, j, k: Integer;
begin
  if ColCount <> AMatrix.RowCount
    then raise EMatrixException.Create('Can not Multiply these matrixes');
  A := FClass.Create(nil);
  A.RowCount := RowCount;
  A.ColCount := AMatrix.ColCount;
  for k := 0 to RowCount - 1 do
    for i := 0 to AMatrix.ColCount - 1 do
      for j := 0 to ColCount - 1 do
        A[k, i] := A[k, i] + Cells[k, j] * AMatrix.Cells[j, i];
  Assign(A);
  A.Free;
end;

procedure TMatrix.MultAsRight(AMatrix: TMatrix);
var
  A: TMatrix;
  i, j, k: Integer;
begin
  if ColCount <> AMatrix.RowCount
    then raise EMatrixException.Create('Can not Multiply these matrixes');
  A := FClass.Create(nil);
  A.RowCount := AMatrix.RowCount;
  A.ColCount := ColCount;
  for k := 0 to AMatrix.RowCount - 1 do
    for i := 0 to ColCount - 1 do
      for j := 0 to AMatrix.ColCount - 1 do
        A[k, i] := A[k, i] + AMatrix[k, j] * Cells[j, i];
  Assign(A);
  A.Free;
end;

procedure TMatrix.MultValue(Value: Extended);
var
  i, j: Integer;
begin
  for i := 0 to RowCount - 1 do
    for j := 0 to ColCount - 1 do
      Cells[i,j] := Cells[i,j] * Value;
end;

procedure TMatrix.MainBasis(Value: Extended);
var
  i: Integer;
begin
  if RowCount <> ColCount
    then raise EMatrixException.Create('This operation can be applied only to square matrix');
  AssignValue(0);
  for i := 0 to RowCount - 1 do
    Cells[i,i] := Value;
end;

function TMatrix.Determinant: Extended;
var
  A, B: TMatrix;
begin
  if RowCount <> ColCount
    then raise EMatrixException.Create('This operation can be applied only to square matrix');
  A := FClass.Create(nil);
  A.Assign(Self);

  B := FClass.Create(nil);
  B.RowCount := RowCount;
  B.ColCount := ColCount;
  B.MainBasis(1);

  Result := SolveMatrixEx(A, B);
end;

function TMatrix.Inverse: boolean;
var
  I, X: TMatrix;
begin
  if RowCount <> ColCount then begin
     Result:=false;
     exit;
  end;

  I := FClass.Create(nil);
  I.RowCount := RowCount;
  I.ColCount := ColCount;
  I.MainBasis(1);


  //Nico: "I've changed this to my solve algorithm"
  X := FClass.Create(nil);
  X.RowCount := RowCount;
  X.ColCount := ColCount;

  if (M_Solve(self, I, X)) then begin
     Assign(X);
     Result:=true;
  end else begin
     Result:=false;
  end;

  X.Free;
end;

procedure TMatrix.Transpose;
var
  A: TMatrix;
  T: Extended;
  i, j: Integer;
begin
  for i := 0 to RowCount - 1 do
    for j := i + 1 to ColCount - 1 do
    begin
    end;
end;

procedure TMatrix.Power(Pow: Integer);
var
  Temp: TMatrix;
  i: Integer;
begin
  Temp := FClass.Create(nil);
  Temp.Assign(Self);
  for i := 1 to Pow - 1 do
    MultAsLeft(Temp);
  Temp.Free;
end;

procedure TMatrix.SetCols(Value: Integer);
begin
  try
    SetRanges(RowCount, Value);
  except
  end;
end;

procedure TMatrix.SetRows(Value: Integer);
begin
  try
    SetRanges(Value, ColCount);
  except
  end;
end;

procedure TMatrix.ExChangeRows(i, j: Integer);
var
  k: Integer;
  Temp: Extended;
begin
  for k := 0 to ColCount - 1 do
  begin
    Temp := Cells[i,k];
    Cells[j,k] := Cells[i,k];
    Cells[j,k] := Temp;
  end;
end;

procedure TMatrix.AddRows(i, j: integer; Factor: Extended);
var
  k: Integer;
begin
  for k := 0 to ColCount - 1 do
    Cells[i,k] := Cells[i,k] + Cells[j,k] * Factor;
end;

procedure TMatrix.MultLine(i: Integer; Factor: Extended);
var
  k: Integer;
begin
  for k := 0 to ColCount - 1 do
    Cells[i,k] := Cells[i,k] * Factor;
end;

function M_Inverse(A: TMatrix): TMatrix;
var
  I: TMatrix;
begin
  if A.RowCount <> A.ColCount then begin
     Result:=nil;
     exit;
  end;

  //Create result matrix
  Result := A.FClass.Create(nil);
  Result.RowCount := A.RowCount;
  Result.ColCount := A.ColCount;

  //Create Identity matrix
  I := A.FClass.Create(nil);
  I.RowCount := A.RowCount;
  I.ColCount := A.ColCount;
  I.MainBasis(1);

  //Nico: "I've change this to my solve algorithm"
  if (NOT M_Solve(A, I, Result)) then begin
     Result:=nil;
  end;
end;

function M_Mult(A, B: TMatrix): TMatrix;
begin
  Result := A.FClass.Create(nil);
  Result.Assign(A);
  Result.MultAsLeft(B);
end;

function M_Add(A, B: TMatrix): TMatrix;
begin
  Result := A.FClass.Create(nil);
  Result.Assign(A);
  Result.Add(B);
end;

function M_Subtract(A, B: TMatrix): TMatrix;
begin
  Result := A.FClass.Create(nil);
  Result.Assign(A);
  Result.Subtract(B);
end;


function M_MultValue(A: TMatrix; Value: Extended): TMatrix;
begin
  Result := A.FClass.Create(nil);
  Result.Assign(A);
  Result.MultValue(Value);
end;

function M_Power(A: TMatrix; Pow: Integer): TMatrix;
begin
  Result := A.FClass.Create(nil);
  Result.Assign(A);
  Result.Power(Pow);
end;

{ TRealMatrix }
procedure TRealMatrix.SetRanges(NewRow, NewCol: Integer);
var
  OldCol, OldRow: Integer;
  i, j: Integer;
begin
  if (NewRow < 1) or (NewCol < 1)
    then raise Exception.Create('Invalid dimensions...');
  if (RowCount <> NewRow) or (ColCount <> NewCol)
  then begin
    OldRow := RowCount;
    OldCol := ColCount;
    { reallocate memory }
    { if OldCol < NewCol then new elements will be equal to 0 }
    { if OldCol > NewCol then elements will be lost }
    for i := 0 to OldRow - 1 do
    begin
      ReAllocMem(FRows^[i], szExtended * NewCol);

      if OldCol < NewCol
        then FillChar(FRows^[i]^[OldCol], (NewCol - OldCol)*szExtended, 0);
    end;
    { if NewRow < OldRow, unnessesary Rows will be destroed }
    for i := OldRow - 1 downto NewRow do
      FreeMem(FRows^[i], szExtended * OldCol);
    { Resize FRows }
    ReAllocMem(FRows, szPointer * NewRow);

    { if NewRow > OldRows, new Rows will be added }
    for i := OldRow to NewRow - 1 do
    begin
      FRows^[i] := AllocMem(szExtended * NewCol);
      FillChar(FRows^[i]^, NewCol*szExtended, 0);
    end;
    { update FRowCount }
    FRowCount := NewRow;
    { update FColCount }
    FColCount := NewCol;
  end;
end;

function  TRealMatrix.GetCells(ARow, ACol: Integer): Extended;
begin
  { if index is invalid then raise exception }
  if (ACol < 0) or (ACol > ColCount - 1) or
     (ARow < 0) or (ARow > RowCount - 1)
  then  raise EMatrixException.Create('Index out of bounds' + IntTostr(ACol) + ' ' + IntToStr(ARow));
  Result := FRows^[ARow]^[ACol];
end;

procedure TRealMatrix.SetCells(ARow, ACol: Integer; AValue: Extended);
begin
  { if index is invalid then raise exception }
  if (ACol < 0) or (ACol > ColCount - 1) or
     (ARow < 0) or (ARow > RowCount - 1)
  then  raise EMatrixException.Create('Index out of bounds');
  FRows^[ARow]^[ACol] := AValue;
end;

destructor TRealMatrix.Destroy;
var
  i: Integer;
begin
  { deallocate memory }
  for i := 0 to RowCount - 1 do
    FreeMem(FRows^[i], szExtended * ColCount);
  inherited Destroy;
end;

{ -- TSRow methods -- }
constructor TSRow.Create(ARowNum: Integer);
begin
  inherited Create;
  FRowNum := ARowNum;
end;

destructor TSRow.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Dispose(PSCell(Items[i]));
  inherited Destroy;
end;

function TSRow.Get(Index: Integer): PSCell;
begin
  Result := inherited Get(Index);
end;

procedure TSRow.Put(Index: Integer; ACell: PSCell);
begin
  inherited Put(Index, ACell);
end;

function TSRow.Find(ACellCol: Integer; var Index: Integer): Boolean;
var
  L, H, C, I: Integer;
begin
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    if Items[I]^.Col < ACellCol
      then L := I + 1
      else begin
        H := I - 1;
        if Items[i]^.Col = ACellCol then
        begin
          Result := True;
          L := I;
        end
      end;
  end;
  Index := L;
end;

function TSRow.Add(const ACellCol: Integer; const AValue: Extended): Integer;

function NewCell(ARow, ACol: Integer; AValue: Extended): PSCell;
begin
  New(Result);
  with Result^ do
  begin
    Row := ARow;
    Col := ACol;
    Value := AValue;
  end;
end;

begin
  Find(ACellCol, Result);
  Insert(Result, NewCell(FRowNum, ACellCol, AValue));
end;

{ -- TRowList methods -- }
destructor TRowList.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited Destroy;
end;

function TRowList.Get(Index: Integer): TSRow;
begin
  Result := inherited Get(Index);
end;

procedure TRowList.Put(Index: Integer; ARow: TSRow);
begin
  inherited Put(Index, ARow);
end;

function TRowList.Find(ARowNum: Integer; var Index: Integer): Boolean;
var
  L, H, C, I: Integer;
begin
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    if Items[i].RowNum < ARowNum
      then L := I + 1
      else begin
        H := I - 1;
        if Items[i].RowNum = ARowNum then
        begin
          Result := True;
          L := I;
        end
      end;
  end;
  Index := L;
end;

function TRowList.Add(const ARowNum: Integer): Integer;
begin
  Find(ARowNum, Result);
  Insert(Result, TSRow.Create(ARowNum));
end;

{-- TSparseMatrix --}
destructor TSparseMatrix.Destroy;
begin
  FRows.Free;
  inherited Destroy;
end;

function  TSparseMatrix.GetCells(ARow, ACol: Integer): Extended;
var
  Index: Integer;
  tRow: TSRow;
begin
  { if index is invalid then raise exception }
  if (ACol < 0) or (ACol >= ColCount) or
     (ARow < 0) or (ARow >= RowCount)
  then  raise EMatrixException.Create('Index out of bounds');
  with FRows do
    if not Find(ARow, Index)
      then Result := 0
      else begin
        tRow := Items[Index];
        if not tRow.Find(ACol, Index)
          then Result := 0
          else Result := tRow.Items[Index]^.Value;
      end;
end;

procedure TSparseMatrix.SetCells(ARow, ACol: Integer; AValue: Extended);
var
  Index: Integer;
  tRow: TSRow;
begin
  { if index is invalid then raise exception }
  if (ACol < 0) or (ACol >= ColCount) or
     (ARow < 0) or (ARow >= RowCount)
  then  raise EMatrixException.Create('Index out of bounds');
  with FRows do
    if not Find(ARow, Index)
      then begin
        Index := Add(ARow);
        Items[Index].Add(ACol, AValue);
      end
      else begin
        tRow := Items[Index];
        if not tRow.Find(ACol, Index)
          then begin
            if AValue <> 0 then tRow.Add(ACol, AValue);
          end
          else begin
            if AValue <> 0
              then tRow.Items[Index]^.Value := AValue
              else begin
                Dispose(PSCell(tRow.Items[Index]));
                tRow.Delete(Index);
              end;
          end;
      end;
end;

procedure TSparseMatrix.SetRanges(NewRow, NewCol: Integer);
var
  i, j, Index: Integer;
  tRow: TSRow;
begin
  if (NewRow < 1) or (NewCol < 1)
    then raise Exception.Create('Invalid dimensions...');
  if FRows = nil then FRows := TRowList.Create;
  if RowCount > NewRow then
    with FRows do
      for i := Count - 1 downto 0 do
        if Items[i].RowNum >= NewRow then
        begin
          Items[i].Free;
          Delete(i);
        end
        else break;
  if ColCount > NewCol then
    with FRows do
      for i := 0 to Count - 1 do
      begin
        tRow := Items[i];
        for j := tRow.Count - 1 downto 0 do
          if tRow.Items[j]^.Col > NewCol then
          begin
            Dispose(tRow.Items[j]);
            tRow.Delete(j);
          end
          else break;
      end;
   FRowCount := NewRow;
   FColCount := NewCol;
end;

{-- TVector --}
constructor TVector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetCount(5);
end;

procedure TVector.Assign(Source: TVector);
var
  i: Integer;
begin
  Count := Source.Count;
  for i := 0 to Count - 1 do
    Cells[i] := Source[i];
end;

procedure TVector.AssignValue(Value: Extended);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Cells[i] := Value;
end;

procedure TVector.Add(AVector: TVector);
var
  i: Integer;
begin
  if Count <> AVector.Count
    then raise EMatrixException.Create('Can not add these Vectors');
  for i := 0 to Count - 1 do
    Cells[i] := Cells[i] + AVector[i];
end;

procedure TVector.MultValue(Value: Extended);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Cells[i] := Cells[i] * Value;
end;

procedure TVector.Transpose;
var
  T: Extended;
  i: Integer;
begin
  for i := 0 to (Count - 1) div 2 do
    begin
      T := Cells[i];
      Cells[i] := Cells[Count - i];
      Cells[Count - i] := T;
    end;
end;

function TVector.ScalarProduct(AVector: TVector): Extended;
var
  i: Integer;
begin
  if Count <> AVector.Count
    then raise EMatrixException.Create('Can not process these Vectors');
  Result := 0;
  for i := 0 to Count - 1 do
    Result := Cells[i] * AVector[i];
end;

procedure TVector.Exchange(i, j: Integer);
var
  T: Extended;
begin
  T := Cells[i];
  Cells[i] := Cells[j];
  Cells[j] := T;
end;

{-- TRealVector --}
destructor  TRealVector.Destroy;
begin
  FreeMem(FData, szExtended * Count);
  inherited Destroy;
end;

function  TRealVector.GetCells(APos: Integer): Extended;
begin
  { if index is invalid then raise exception }
  if (APos < 0) or (APos > Count - 1)
    then  raise EMatrixException.Create('Index out of bounds');
  Result := FData^[APos];
end;

procedure TRealVector.SetCells(APos: Integer; AValue: Extended);
begin
  { if index is invalid then raise exception }
  if (APos < 0) or (APos > Count - 1)
    then  raise EMatrixException.Create('Index out of bounds');
  FData^[APos] := AValue;
end;

procedure TRealVector.SetCount(NewCount: Integer);
var
  OldCount: Integer;
begin
  if (NewCount < 1)
    then raise Exception.Create('Invalid dimension...');
  if Count <> NewCount
  then begin
    OldCount := Count;
    { reallocate memory }
    ReAllocMem(FData, szExtended * NewCount);

      if OldCount < NewCount
        then FillChar(FData^[OldCount], (NewCount - OldCount)*szExtended, 0);
    FCount := NewCount;
  end;
end;

{-- TSparseVector --}
destructor  TSparseVector.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

function  TSparseVector.GetCells(APos: Integer): Extended;
var
  Index: Integer;
begin
  { if index is invalid then raise exception }
  if (APos < 0) or (APos >= Count)
    then  raise EMatrixException.Create('Index out of bounds');
  if not FData.Find(APos, Index)
    then Result := 0
    else Result := FData.Items[Index]^.Value;
end;

procedure TSparseVector.SetCells(APos: Integer; AValue: Extended);
var
  Index: Integer;
begin
  { if index is invalid then raise exception }
  if (APos < 0) or (APos >= Count)
    then  raise EMatrixException.Create('Index out of bounds');
  if not FData.Find(APos, Index)
    then begin
      if AValue <> 0 then FData.Add(APos, AValue);
    end
    else begin
      if AValue <> 0
        then FData.Items[Index]^.Value := AValue
        else begin
          Dispose(PSCell(FData.Items[Index]));
          FData.Delete(Index);
        end;
    end;
end;

procedure TSparseVector.SetCount(NewCount: Integer);
var
  i: Integer;
begin
  if NewCount < 1
    then raise Exception.Create('Invalid dimension...');
  if FData = nil then FData := TSRow.Create(1);
  if Count > NewCount then
    for i := FData.Count - 1 downto 0 do
      if FData.Items[i]^.Col > NewCount then
      begin
        Dispose(FData.Items[i]);
        FData.Delete(i);
      end
      else break;
  FCount := NewCount;
end;


end.
