unit ListSelection_Ops;

interface

uses
  System.Classes,
  Vcl.StdCtrls;

procedure SetupSelection(available : TListBox;
                         selected : TListBox;
                         addButton : TButton;
                         addAllButton : TButton;
                         clearButton : TButton;
                         clearAllButton : TButton;
                         availableLabel : TLabel;
                         selectedLabel : TLabel;
                         availableFormat : String;
                         selectedFormat : String);
procedure UpdateSelectionInfo;
procedure AddToSelected;
procedure AddAllToSelected;
procedure ClearFromSelected;
procedure ClearAllFromSelected;

implementation

uses
  System.SysUtils;

var
  FAvailable : TListBox;
  FSelected : TListBox;
  FAddButton : TCustomButton;
  FAddAllButton : TCustomButton;
  FClearButton : TCustomButton;
  FClearAllButton : TCustomButton;
  FAvailableLabel : TLabel;
  FSelectedLabel : TLabel;
  FAvailableFormat : String;
  FSelectedFormat : String;

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
procedure SetupSelection(available : TListBox;
                         selected : TListBox;
                         addButton : TButton;
                         addAllButton : TButton;
                         clearButton : TButton;
                         clearAllButton : TButton;
                         availableLabel : TLabel;
                         selectedLabel : TLabel;
                         availableFormat : String;
                         selectedFormat : String);
begin
  FAvailable := available;
  FSelected := selected;
  FAddButton := addButton;
  FAddAllButton := addAllButton;
  FClearButton := clearButton;
  FClearAllButton := clearAllButton;
  FAvailableLabel := availableLabel;
  FSelectedLabel := selectedLabel;
  FAvailableFormat := availableFormat;
  FSelectedFormat := selectedFormat;
end;

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
procedure DisableSelection;
begin
  FAvailable := nil;
  FSelected := nil;
  FAddButton := nil;
  FAddAllButton := nil;
  FClearButton := nil;
  FClearAllButton := nil;
  FAvailableLabel := nil;
  FSelectedLabel := nil;
  FAvailableFormat := '';
  FSelectedFormat := '';
end;

//***************************************************************************
//
//  FUNCTION  : UpdateSelectionInfo
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2023-08-08
//
//***************************************************************************
procedure UpdateSelectionInfo;
begin
  if ((Assigned(FAvailable)) and
      (Assigned(FAvailableLabel)) and
      (FAvailableFormat <> '')) then
  begin
    fAvailableLabel.Caption := Format(fAvailableFormat, [fAvailable.Count]);
  end; // if
  if ((Assigned(FSelected)) and
      (Assigned(FSelectedLabel)) and
      (FSelectedFormat <> '')) then
  begin
    fSelectedLabel.Caption := Format(fSelectedFormat, [fSelected.Count]);
  end; // if
end;

//***************************************************************************
//
//  FUNCTION  : AddToSelected
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2023-08-08
//
//***************************************************************************
procedure AddToSelected;
var
  index : Integer;
  n : Word;

begin
  if ((Assigned(FAvailable)) and
      (Assigned(FSelected))) then
  begin
    // Add the selected entry/entries if they are not already in the selected list
    for n := 0 to FAvailable.Items.Count-1 do
    begin
      if ((FAvailable.Selected[n]) and
          (FSelected.Items.IndexOf(FAvailable.Items[n]) = -1)) then
      begin
        FSelected.Items.Add(FAvailable.Items[n]);
      end; // if
    end; // for

    UpdateSelectionInfo;
  end; // if
end; // AddToSelected

//***************************************************************************
//
//  FUNCTION  : AddAllToSelected
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2023-08-08
//
//***************************************************************************
procedure AddAllToSelected;
var
  Index : Integer;
  n : Word;

begin
  if ((Assigned(FAvailable)) and
      (Assigned(FSelected))) then
  begin
    FSelected.Clear;
    for n := 0 to FAvailable.Items.Count-1 do
      FSelected.Items.Add(FAvailable.Items[n]);

    UpdateSelectionInfo;
  end;
end; // AddAllToSelected

//***************************************************************************
//
//  FUNCTION  : ClearFromSelected
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2023-08-08
//
//***************************************************************************
procedure ClearFromSelected;
var
  Index : Integer;
  n : Word;

begin
  if (Assigned(FSelected)) then
  begin
    n := 0;
    while (n < FSelected.Items.Count) and
          (FSelected.Items.Count <> 0) do
    begin
      if (FSelected.Selected[n]) then
      begin
        FSelected.Items.Delete(n);
      end // if
      else
      begin
        n := n + 1;
      end; // else
    end; // while

    UpdateSelectionInfo;
  end;
end; // ClearFromSelected

//***************************************************************************
//
//  FUNCTION  : ClearAllFromSelected
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2023-08-08
//
//***************************************************************************
procedure ClearAllFromSelected;
begin
  if (Assigned(fSelected)) then
  begin
    fSelected.Clear;
  end;

  UpdateSelectionInfo;
end; // ClearAllFromSelected

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
initialization
  DisableSelection;

end.
