unit Delphi_Ops;

interface

function InstalledComponentsList : String;

implementation

uses
  VaComm,               // TMS Async (TvaComm)
  VCL.TMSFNCOpenLayers; // TMS FNC Maps (TTMSFNCOpenLayers)

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
function InstalledComponentsList : String;
begin
  Result := '';
  // TMS Async
  with TVaComm.Create(nil) do
  begin
    Result := Result + 'TMS Async V' + Version + sLineBreak;
    Free;
  end; // with
  // TMS OpenLayers
  with TTMSFNCOpenLayers.Create(nil) do
  begin
    Result := Result + 'TMS Open Layers V' + Version + sLineBreak;
    Free;
  end;
end;

end.
