unit Pointer_Ops;

interface

type
  // Note that there are various defined Standard Pointer Types in Delphi.
  // See "Pointers and Pointer Types (Delphi)" in the help
  // these include PInteger, PString etc
  PUInt32 = ^UInt32;
  PInt32 = ^Int32;
  PUInt16 = ^UInt16;
  PInt16 = ^Int16;
  PSingle = ^Single;

implementation

end.
