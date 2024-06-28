unit VCL_Ops;

interface

uses
  VCL.StdCtrls, VCL.Controls;

type
  TGetCanvas = Class(TCustomControl)
  published
    property Canvas;
  end;

procedure UpdateTComboBoxItems(var cbEntry : TComboBox;
                               const maxEntries : Integer = 20);

implementation

uses
  System.SysUtils;

//***************************************************************************
//
//  FUNCTION  : UpdateTComboBoxItems
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Update TComboBox.Items to include TCopmboBox.Text.
//
//              If .Text is already in .Items, move it up to the top.
//
//  UPDATED   : 2010-11-11
//
//***************************************************************************
procedure UpdateTComboBoxItems(var cbEntry : TComboBox;
                               const maxEntries : Integer = 20);
var
  bFound : Boolean;
  n : Integer;
  sLatestEntry : String;

begin
  if (cbEntry.Items.Count>0) then
  begin
    // Try to find the address in the stored list
    bFound := FALSE;
    n := 0;
    while ((n<=cbEntry.Items.Count-1) and
           (n < maxEntries-1) and
           (not bFound)) do
    begin
      if (cbEntry.Items.Strings[n].ToUpper = UpperCase(cbEntry.Text)) then
        bFound := TRUE;
      Inc(n);
    end; // while

    sLatestEntry := cbEntry.Text;

    // If found, delete it from the location where it was
    if (bFound) then
      cbEntry.Items.Delete(n-1);
    // Chop off the oldest address if there are too many in the list
    if (cbEntry.Items.Count >= maxEntries) then
      cbEntry.Items.Delete(maxEntries-1);
    // Add the address to the top of the list
    cbEntry.Items.Insert(0,sLatestEntry);
  end // if
  else
    // Add the first entry
    cbEntry.Items.Add(cbEntry.Text);
  cbEntry.ItemIndex := 0;
end; // UpdateTComboBoxItems

end.
