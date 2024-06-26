unit Object_Ops;

interface

type
  TMethodPointer = packed record
    pMethod: Pointer;
    pObject: TObject;
  end;
(* Example usage
  var
    mpNewMethod : TMethodPointer;

  mpNewMethod.pMethod := @timTickTimer;
  mpNewMethod.pObject := nil;
  timTick.OnTimer := TNotifyEvent(mpNewMethod);
*)


implementation

end.
