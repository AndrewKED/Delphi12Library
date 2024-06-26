unit psl_1_STOP;

{
Copyright (C) 2004 Oleg Subachev
oleg@posolsoft.com


Prevents launching of the second instance of the application
but activates the first instance at the same time.
If second instance is launched with 'STOP' command line argument,
then the first instance is terminated but not activated.

Usage:

Changing in project file:

a) add psl_1_STOP in 'uses' clause

b) change project body as follows:

  if psl1_IS_1ST_INSTANCE( True ) then begin
// prevents launching of the second instance of the application from any directory
//  if psl1_IS_1ST_INSTANCE( False ) then begin
// prevents launching of the second instance of the application from the same directory
    Application.Initialize;
    Application.CreateForm(TForm1, Form1);
    Application.Run;
  end
  else
    psl1_ACTIVATE_OR_STOP_1ST_INSTANCE;
}

interface

function psl1_IS_1ST_INSTANCE( const bFROM_ANY_DIR : Boolean = True ) : Boolean;
{
bFROM_ANY_DIR = True (default) - prevents launching of the second instance
of the application from any directory
bFROM_ANY_DIR = False - prevents launching of the second instance
of the application from the same directory
}

procedure psl1_ACTIVATE_OR_STOP_1ST_INSTANCE;

implementation

uses
  Windows, SysUtils, Forms;

var
  psl1_1ST_MESSAGE,
  psl1_STOP_MESSAGE : UINT;
  psl1_MUTEX,
  psl1_SHARED_FILE : THandle;
  psl1_SHARED_DATA : ^HWND;
  psl1_PREV_WND_PROC : TFNWndProc;

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function psl1_CreateMutex(lpMutexAttributes: PSecurityAttributes;
  bInitialOwner: Longint; lpName: PChar): THandle;
  stdcall; external 'kernel32.dll' name 'CreateMutexA';

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function psl1_WND_PROC( Handle : HWND; MSSG : UINT;
  wParam, lParam : Longint ) : Longint; stdcall;
begin
  if MSSG = psl1_1ST_MESSAGE then begin
    Application.Restore;
    Application.BringToFront;
    Result := 0;
  end
  else
  if MSSG = psl1_STOP_MESSAGE then begin
    Application.Terminate;
    Result := 0;
  end
  else
    Result := CallWindowProc( psl1_PREV_WND_PROC, Handle, MSSG, wParam, lParam );
end; // psl1_WND_PROC

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function psl1_LAST_MAX_PATH( const sNAME : String ) : String;
begin
  if Length( sNAME ) > MAX_PATH then
    Result := Copy( sNAME, Length( sNAME ) - MAX_PATH + 1, MAX_PATH )
  else
    Result := sNAME;
end; // psl1_LAST_MAX_PATH

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
function psl1_IS_1ST_INSTANCE( const bFROM_ANY_DIR : Boolean = True ) : Boolean;
var
  PS0 : String;                                                 // ParamStr( 0 )
begin
  PS0 := ParamStr( 0 );
  if bFROM_ANY_DIR then            // use only filename to init names of objects
    PS0 := ExtractFileName( PS0 )
  else                                 // use full path to init names of objects
    // name of the object must not contain BackSlash
    PS0 := StringReplace( PS0, '\', '', [ rfReplaceAll ] );
  psl1_1ST_MESSAGE := RegisterWindowMessage(
    PChar( psl1_LAST_MAX_PATH( '8E43A11714D84D7D99A095BF3CF758BE' + PS0 )));
  Win32Check( psl1_1ST_MESSAGE <> 0 );
  psl1_STOP_MESSAGE := RegisterWindowMessage(
    PChar( psl1_LAST_MAX_PATH( 'F326903B6ED643DEA79D9F5BFEC2D8EB' + PS0 )));
  Win32Check( psl1_STOP_MESSAGE <> 0 );
  psl1_MUTEX := psl1_CreateMutex(
    Nil, 1, PChar( psl1_LAST_MAX_PATH( '0B18B76E492943FE97072DF38ED73BDA' + PS0 )));
  Win32Check( psl1_MUTEX <> 0 );
  Result := ( GetLastError <> Error_Already_Exists );
  try
    psl1_SHARED_FILE := CreateFileMapping( INVALID_HANDLE_VALUE, Nil, Page_ReadWrite,
      0, SizeOf( HWND ), PChar( psl1_LAST_MAX_PATH( '8789854C059D4E0B86A76907CA2E3086' + PS0 )));
    Win32Check( psl1_SHARED_FILE <> 0 );
    psl1_SHARED_DATA := MapViewOfFile( psl1_SHARED_FILE, File_Map_All_Access, 0, 0, 0 );
    Win32Check( psl1_SHARED_DATA <> Nil );
    if Result then
    begin
      psl1_SHARED_DATA^ := Application.Handle;
      psl1_PREV_WND_PROC := TFNWndProc( SetWindowLong( Application.Handle, GWL_WNDPROC,
                                                      Longint( @psl1_WND_PROC )));
      Win32Check( psl1_PREV_WND_PROC <> Nil );
    end;
  finally
    if Result then
      Win32Check( ReleaseMutex( psl1_MUTEX ));
  end;
end; // psl1_IS_1ST_INSTANCE

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
procedure psl1_ACTIVATE_OR_STOP_1ST_INSTANCE;
begin
  WaitForSingleObject( psl1_MUTEX, INFINITE );
  try
    if FindCmdLineSwitch( 'STOP', [ '-', '/' ], True ) then
      PostMessage(psl1_SHARED_DATA^, psl1_STOP_MESSAGE, 0, 0)
    else
      PostMessage(psl1_SHARED_DATA^, psl1_1ST_MESSAGE, 0, 0);
  finally
    Win32Check(ReleaseMutex(psl1_MUTEX));
  end;
end; // psl1_ACTIVATE_OR_STOP_1ST_INSTANCE

//***************************************************************************
//
//  FUNCTION    :
//
//  I/P         :
//
//  O/P         :
//
//  OPERATION   :
//
//  UPDATED     :
//
//***************************************************************************
initialization
finalization
  if Assigned( psl1_PREV_WND_PROC ) then
    SetWindowLong( Application.Handle, GWL_WNDPROC, Longint( psl1_PREV_WND_PROC ));
  if psl1_MUTEX <> 0 then
    CloseHandle( psl1_MUTEX );
  if psl1_SHARED_DATA <> Nil then
    UnmapViewOfFile( psl1_SHARED_DATA );
  if psl1_SHARED_FILE <> 0 then
    CloseHandle( psl1_SHARED_FILE );
end.

