unit StopWatch;

//***************************************************************************
//
//  Original code and discussion on
//  http://delphi.about.com/od/windowsshellapi/a/delphi-high-performance-timer-tstopwatch.htm
//
//***************************************************************************
 interface

 uses Windows, SysUtils, DateUtils;

 type TStopWatch = class
   private
     fFrequency : TLargeInteger;
     fIsRunning: boolean;
     fIsHighResolution: boolean;
     fStartCount, fStopCount : TLargeInteger;
     procedure SetTickStamp(var lInt : TLargeInteger) ;
     function GetElapsedTicks: TLargeInteger;
     function GetElapsedMiliseconds: TLargeInteger;
     function GetElapsed: string;
   public
     constructor Create(const startOnCreate : boolean = false) ;
     procedure Start;
     procedure Stop;
     property IsHighResolution : boolean read fIsHighResolution;
     property ElapsedTicks : TLargeInteger read GetElapsedTicks;
     property ElapsedMiliseconds : TLargeInteger read GetElapsedMiliseconds;
     property Elapsed : string read GetElapsed;
     property IsRunning : boolean read fIsRunning;
   end;

 implementation

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
 constructor TStopWatch.Create(const startOnCreate : boolean = false) ;
 begin
   inherited Create;

   fIsRunning := false;

   fIsHighResolution := QueryPerformanceFrequency(fFrequency);
   if not fIsHighResolution then
     fFrequency := MSecsPerSec;

   if startOnCreate then Start;
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
 function TStopWatch.GetElapsedTicks: TLargeInteger;
 begin
   result := fStopCount - fStartCount;
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
 procedure TStopWatch.SetTickStamp(var lInt : TLargeInteger) ;
 begin
   if fIsHighResolution then
     QueryPerformanceCounter(lInt)
   else
     lInt := MilliSecondOf(Now) ;
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
 function TStopWatch.GetElapsed: string;
 var
   dt : TDateTime;
 begin
   dt := ElapsedMiliseconds / MSecsPerSec / SecsPerDay;
   result := FormatDateTime('%d days, %s', dt) ;
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
 function TStopWatch.GetElapsedMiliseconds: TLargeInteger;
 begin
   result := (MSecsPerSec * (fStopCount - fStartCount)) div fFrequency;
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
 procedure TStopWatch.Start;
 begin
   SetTickStamp(fStartCount);
   fIsRunning := true;
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
 procedure TStopWatch.Stop;
 begin
   SetTickStamp(fStopCount);
   fIsRunning := false;
 end;

end.

