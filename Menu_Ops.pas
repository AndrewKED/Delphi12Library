unit Menu_Ops;

interface

uses
  System.Classes;

procedure EnableMenuItems(mMenu : TComponent;
                          bState : Boolean;
                          recurse : Boolean = FALSE);

implementation

uses
  Vcl.Menus;

//***************************************************************************
//
//  FUNCTION  : EnableMenuItems
//
//  I/P       : mMenu : TComponent - A TMainMenu, TPopupMenu or TMenuItem component
//
//              bState (boolean) - The state to which the enabled property
//                of the given menu/item and all its TMenuItems will be set.
//
//              recurse (Boolean) = FALSE - Set to TRUE to cause all sub-menus
//                of mMenu to be enabled as requested. Otherwise, just the first-
//                sub-menus will be enabled as requested.
//
//  O/P       : None.
//
//  OPERATION : Enable/disable all, or first-level, menu items as requested.
//
//              Iterates through all menu items, or just the first-level menu items,
//              under the given menu, setting the enabled property, as required.
//
//  UPDATED   : 2020-05-12
//
//***************************************************************************
procedure EnableMenuItems(mMenu : TComponent;
                          bState : Boolean;
                          recurse : Boolean = FALSE);
var
  n : Integer;

  procedure EnableSubMenuItems(miMenu : TMenuItem);
  var
    m : Integer;
  begin
    if ((miMenu.Count>0) and
        (recurse)) then
      for m := 0 to miMenu.Count-1 do
        EnableSubMenuItems(miMenu.Items[m]);
    miMenu.Enabled := bState;
  end; // EnableSubMenuItems

begin
  if ((mMenu is TMainMenu) or
      (mMenu is TPopupMenu)) then
    // Enable all top-level menu items
    for n := 0 to (mMenu as TMenu).Items.Count-1 do
       EnableSubMenuItems((mMenu as TMenu).Items[n])
  else
    if (mMenu is TMenuItem) then
      EnableSubMenuItems(mMenu as TMenuItem);
end; // EnableAllMenuItems



end.
