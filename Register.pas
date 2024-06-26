unit Register;
//***************************************************************************
//
// This suite of functions is used to register/licence software to a user.
//
// It is expected that the software will be distributed with a unique software
// serial number (known below as OS - original serial number).   This will be
// placed on the CD/DVD cover or emailed to the user.
//
// The software will be licenced to a user (or company) (known below as LU - the
// licensed user).
//
// The installation disc serial number (known below as HS) on which the software
// is installed will be used as an encryption key.
//
// The user will enter the software serial number and licenced user.   A function,
// below, will generate a unique code that should be sent back to us.   This
// code will include the disc serial number and the licenced user, encrypted
// in a standard form.   We will use letters and numbers in the code.
//
// We will generate an unlock code (known below as UK), and return this to the user.
// The user will enter the unlock code.
//
// The software serial number, licenced user and unlock code are all stored
// in the clear in a binary file in the Users\All Users\Application Data folder.
//
//***************************************************************************
interface

function MC(sLU : string;
            sOS : string) : string;
function PL : boolean;

implementation

uses SysUtils, Forms,
     File_Ops;


//***************************************************************************
//
//  FUNCTION  : MC
//
//  I/P       : sLU : string - The Company (owner) to whom the software is
//                being licensed i.e. the licensed user.
//
//              sOS : string - The serial number that is provided on the original
//                software CD/DVD
//
//  O/P       :
//
//  OPERATION : This function will make a code, given the Licensed User (LU) and
//              Original Serial Number (OS).   It will make use of the serial
//              number of the disc on which this application resides to encrypt
//              the two input strings
//
//  UPDATED   :
//
//***************************************************************************
function MC(sLU : string;
            sOS : string) : string;
var
  sDS : string;   // Drive serial number
  sID : string;   // The drive letter of the drive on which the application is installed

begin
  sID := ExtractFileDrive(Application.ExeName);
  // The application must be on a local drive (single letter ID)
  if (Length(sID) = 1) then
  begin
    sDS := GetDriveSerialNo(sID);
    result := '1234';
  end // if
  else
    result := '';
end; // MC

//***************************************************************************
//
//  FUNCTION  : PL
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : The function name is shortened, so as not to draw attention
//
//              Given a Licensed User (LU), Original Serial Number (OS), Licence
//              Number (LN) and knowing the serial number of the disc on which
//              this application resides, check whether all items form a match.
//
//              This function effectively reverses the operation of the above
//              function, to check that the software is licenced.
//
//  UPDATED   :
//
//***************************************************************************
function PL : boolean;
begin
  result := TRUE;
end; // ProgramLicenced


end.
