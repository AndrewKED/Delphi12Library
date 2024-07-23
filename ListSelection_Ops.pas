unit ListSelection_Ops;

interface

uses
  System.Classes,
  Vcl.StdCtrls;

procedure SetupSelection(available : TListBox;
                         selected : TListBox;
                         addButton : TCustomButton;
                         addAllButton : TCustomButton;
                         clearButton : TCustomButton;
                         clearAllButton : TCustomButton;
                         moveUpButton : TCustomButton;
                         moveDownButton : TCustomButton;
                         availableLabel : TLabel;
                         selectedLabel : TLabel;
                         availableFormat : String;
                         selectedFormat : String);
procedure RestoreAvailableSelection;
procedure AddAvailable(item : String);
procedure FilterAvailable(filter : String;
                          filtered : Boolean);
procedure UpdateSelectionControls;
procedure AddToSelected;
procedure AddAllToSelected;
procedure ClearFromSelected;
procedure ClearAllFromSelected;
procedure MoveSelectedUp;
procedure MoveSelectedDown;
procedure EnsureSelectionValidity(eraseOnError : Boolean);

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
  FMoveUpButton : TCustomButton;
  FMoveDownButton : TCustomButton;
  FAvailableLabel : TLabel;
  FSelectedLabel : TLabel;
  FAvailableFormat : String;
  FSelectedFormat : String;

  listAvailable : TStringList;


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
                         addButton : TCustomButton;
                         addAllButton : TCustomButton;
                         clearButton : TCustomButton;
                         clearAllButton : TCustomButton;
                         moveUpButton : TCustomButton;
                         moveDownButton : TCustomButton;
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
  FMoveUpButton := moveUpButton;
  FMoveDownButton := moveDownButton;
  FAvailableLabel := availableLabel;
  FSelectedLabel := selectedLabel;
  FAvailableFormat := availableFormat;
  FSelectedFormat := selectedFormat;

  if (FAvailable <> nil) then
  begin
    fAvailable.Items.Clear;
  end;
  if (FSelected <> nil) then
  begin
    FSelected.Items.Clear;
  end;
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
//  FUNCTION  : RestoreAvailableSelection
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Restores the available TListBox to show the full list of items
//
//              i.e. removes any filtering.
//
//  UPDATED   : 2024-06-26
//
//***************************************************************************
procedure RestoreAvailableSelection;
var
  n : Integer;

begin
  if (FAvailable <> nil) then
  begin
    FAvailable.Items.Clear;
    for n := 0 to listAvailable.Count-1 do
    begin
      FAvailable.Items.Add(listAvailable[n]);
    end; // for
  end;
end;

//***************************************************************************
//
//  FUNCTION  : AddAvailable
//
//  I/P       : item : String
//
//  O/P       : None
//
//  OPERATION : Add items to the selectable list
//
//              Keep a separate copy of the items, so that filtering can be
//              applied and removed from the TListBox.
//
//  UPDATED   : 2024-06-26
//
//***************************************************************************
procedure AddAvailable(item : String);
begin
  listAvailable.Add(item);
  RestoreAvailableSelection;
end; // AddAvailable

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
procedure FilterAvailable(filter : String;
                          filtered : Boolean);
var
  m : Integer;

begin
  if (filtered) then
  begin
    if (FAvailable <> nil) then
    begin
      FAvailable.Items.Clear;
      for m := 0 to listAvailable.Count - 1 do
      begin
        if ((filter = '') or
            (Pos(UpperCase(filter), listAvailable[m].ToUpper) > 0)) then
        begin
          FAvailable.Items.Add(listAvailable[m]);
        end;
      end; // for
    end; // if
  end; // if
end;

//***************************************************************************
//
//  FUNCTION  : UpdateSelectionControls
//
//  I/P       : None
//
//  O/P       : None
//
//  OPERATION : Update controls based on the current situation.
//
//              Buttons are enabled or disabled, based on what can be done.
//
//              Fill in the headings above the available and selected list,
//              showing the current status, where numbers are indicated.
//
//  UPDATED   : 2024-06-25
//
//***************************************************************************
procedure UpdateSelectionControls;
begin
  if (FAvailable <> nil) then
  begin
    if (FAddButton <> nil) then
    begin
      FAddButton.Enabled := (FAvailable.Items.Count > 0);
    end; // if
    if (FAddAllButton <> nil) then
    begin
      FAddAllButton.Enabled := (FAvailable.Items.Count > 0);
    end; // if

    // Update the label above the available itens
    if (FAvailableLabel <> nil) then
    begin
      if (Pos('%d', FAvailableFormat) > 0) then
      begin
        fAvailableLabel.Caption := Format(fAvailableFormat, [fAvailable.Count]);
      end // if
      else
      begin
        fAvailableLabel.Caption := fAvailableFormat;
      end; // else
    end; // if
  end; // if

  if (FSelected <> nil) then
  begin
    if (FClearButton <> nil) then
    begin
      FClearButton.Enabled := (FSelected.Items.Count > 0);
    end; // if
    if (FClearAllButton <> nil) then
    begin
      FClearAllButton.Enabled := (FSelected.Items.Count > 0);
    end; // if

    if (FMoveUpButton <> nil) then
    begin
      FMoveUpButton.Enabled := (FSelected.Items.Count > 1);
    end; // if
    if (FMoveDownButton <> nil) then
    begin
      FMoveDownButton.Enabled := (FSelected.Items.Count > 1);
    end; // if

    // Update the label above the selected items
    if (FSelectedLabel <> nil) then
    begin
      if (Pos('%d', FSelectedFormat) > 0) then
      begin
        fSelectedLabel.Caption := Format(FSelectedFormat, [fAvailable.Count]);
      end // if
      else
      begin
        fSelectedLabel.Caption := FSelectedFormat;
      end; // else
    end; // if
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
//  UPDATED   : 2024-06-25
//
//***************************************************************************
procedure AddToSelected;
var
  n : Word;

begin
  if ((FAvailable <> nil) and
      (FSelected <> nil)) then
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

    FAvailable.ClearSelection;

    UpdateSelectionControls;
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
  n : Word;

begin
  if ((FAvailable <> nil) and
      (FSelected <> nil)) then
  begin
    FSelected.Clear;
    for n := 0 to FAvailable.Items.Count-1 do
      FSelected.Items.Add(FAvailable.Items[n]);

    UpdateSelectionControls;
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
  if (FSelected <> nil) then
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

    UpdateSelectionControls;
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
  if (fSelected <> nil) then
  begin
    fSelected.Clear;
  end;

  UpdateSelectionControls;
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
procedure MoveSelectedUp;
var
  n: Integer;
  temp : String;

begin
  if (fSelected <> nil) then
  begin
    for n := 1 to fSelected.Items.Count-1 do
    begin
      if ((fSelected.Selected[n]) and
          (not fSelected.Selected[n - 1])) then
      begin
        temp := fSelected.Items[n - 1];
        fSelected.Items[n - 1] := fSelected.Items[n];
        fSelected.Items[n] := temp;

        fSelected.Selected[n] := FALSE;
        fSelected.Selected[n - 1] := TRUE;
      end;
    end;
  end; // if
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
procedure MoveSelectedDown;
var
  n: Integer;
  temp : String;

begin
  if (fSelected <> nil) then
  begin
    for n := fSelected.Items.Count-2 downto 0 do
    begin
      if ((fSelected.Selected[n]) and
          (not fSelected.Selected[n + 1])) then
      begin
        temp := fSelected.Items[n + 1];
        fSelected.Items[n + 1] := fSelected.Items[n];
        fSelected.Items[n] := temp;

        fSelected.Selected[n] := FALSE;
        fSelected.Selected[n + 1] := TRUE;
      end;
    end;
  end; // if
end;

//***************************************************************************
//
//  FUNCTION  : EnsureSelectionValidity
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Ensure that the currently selected items are valid.
//
//              Delete the items that are not in the available list, and
//              optionally delete the entire selected
//
//  UPDATED   : 2023-09-13
//
//***************************************************************************
procedure EnsureSelectionValidity(eraseOnError : Boolean);
var
  allOk : Boolean;
  n : Integer;

begin
  allOK := TRUE;
  n := 0;
  while (n < FSelected.Items.Count) do
  begin
    if (fAvailable.Items.IndexOf(fSelected.Items[n]) = -1) then
    begin
      allOK := FALSE;
      FSelected.Items.Delete(n);
    end
    else
    begin
      Inc(n);
    end;
  end; // while

  if ((not allOK) and (eraseOnError)) then
  begin
    fSelected.Items.Clear;
  end; // if

  UpdateSelectionControls;
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
initialization
  DisableSelection;

  listAvailable := TStringList.Create;

finalization
  listAvailable.Free;

end.
