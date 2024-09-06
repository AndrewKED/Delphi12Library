unit Sound_Ops;

//***************************************************************************
//
// DESCRIPTION:
//  Sound-orientated utility routines.
//
//***************************************************************************

interface

uses
  Windows, Types, MMSystem, Vcl.MPlayer,
  DKLang;

type
  TMediaPlayerWarning = (WARN_MPLAYER_NEVER,
                         WARN_MPLAYER_ONCE,
                         WARN_MPLAYER_ALWAYS);

function GetWaveVolume(var LVol: DWORD; var RVol: DWORD): Boolean;
function SetWaveVolume(const AVolume: DWORD): Boolean;
procedure ThreadPlaySound(sFileName : String);
procedure PlayMediaPlayer(thePlayer : TMediaPlayer;
                          useNotify : Boolean;
                          errorWarning : TMediaPlayerWarning);

implementation

uses
  System.SysUtils, System.Classes,
  Vcl.Dialogs, Vcl.Forms,
  Dialog_Ops;

var
  warnedMediaPlayer : Boolean;

//***************************************************************************
//
//  FUNCTION  : GetWaveVolume
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : The waveOutGetDevCaps function retrieves the capabilities of
//              a given waveform-audio output device.
//
//              The waveOutGetVolume function retrieves the current volume level
//              of the specified waveform-audio output device.
//
//  http://answers.yahoo.com/question/index?qid=20080322220454AA7clOI
//
//  UPDATED   : 2011-05-12
//
//***************************************************************************
function GetWaveVolume(var LVol: DWORD; var RVol: DWORD): Boolean;
var
  WaveOutCaps: TWAVEOUTCAPS;
  Volume: DWORD;
begin
  Result := False;
  if WaveOutGetDevCaps(WAVE_MAPPER, @WaveOutCaps, SizeOf(WaveOutCaps)) = MMSYSERR_NOERROR then
    if WaveOutCaps.dwSupport and WAVECAPS_VOLUME = WAVECAPS_VOLUME then
    begin
      Result := WaveOutGetVolume(WAVE_MAPPER, @Volume) = MMSYSERR_NOERROR;
      LVol := LoWord(Volume);
      RVol := HiWord(Volume);
    end;
end; // GetWaveVolume

//***************************************************************************
//
//  FUNCTION  : SetWaveVolume
//
//  I/P       : AVolume : DWORD - The low-order word contains the left-channel
//                volume setting, and the high-order word contains the right-channel
//                setting.   A value of 65535 represents full volume, and a value of
//                0000 is silence.  If a device does not support both left and right
//                volume control, the low-order word of dwVolume specifies the volume level,
//                and the high-order word is ignored.
//
//  O/P       :
//
//  OPERATION : http://answers.yahoo.com/question/index?qid=20080322220454AA7clOI
//
//  UPDATED   : 2011-05-12
//
//***************************************************************************
function SetWaveVolume(const AVolume: DWORD): Boolean;
var
  WaveOutCaps: TWAVEOUTCAPS;
begin
  Result := False;
  if WaveOutGetDevCaps(WAVE_MAPPER, @WaveOutCaps, SizeOf(WaveOutCaps)) = MMSYSERR_NOERROR then
    if WaveOutCaps.dwSupport and WAVECAPS_VOLUME = WAVECAPS_VOLUME then
      Result := WaveOutSetVolume(WAVE_MAPPER, AVolume) = MMSYSERR_NOERROR;
end; // SetWaveVolume

//***************************************************************************
//
//  FUNCTION  : ThreadPlaySound
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Create a media player in a thread, and play the given sound file
//
//  UPDATED   : 2024-07-29
//
//***************************************************************************
procedure ThreadPlaySound(sFileName : String);
var
  Thread: TThread;

begin
  if ((sFileName <> '') and
      (FileExists(sFileName))) then
  begin
    Thread := TThread.CreateAnonymousThread(
      procedure
        var mp : TMediaPlayer;
      begin
        mp := TMediaPlayer.Create(Application.MainForm);
        try
          mp.Visible := FALSE;
          mp.Parent := Application.MainForm;
          mp.FileName := sFileName;
          mp.Open;
          mp.Wait := TRUE;
          mp.Play;
        finally
          mp.Close;
          // Use FreeAndNil here, there is no need for an owner/parent, above
          FreeAndNil(mp);
        end;
      end // if
    );
    Thread.Start;
  end; // if
end; // ThreadPlaySound

//***************************************************************************
//
//  FUNCTION  : PlayMediaPlayer
//
//  I/P       : const thePlayer : TMediaPlayer - The Media player to be used.
//
//              useNotify : Boolean - The value to be applied to the Notify
//                property of the TMediaPlayer.
//
//              errorWarning : TMediaPlayerWarning - The warning level to
//                be used.
//
//  O/P       :
//
//  OPERATION : Play the prepared file on the TMediaPlayer, with a controlled
//              error handling.
//
//  UPDATED   : 2020-04-30
//
//***************************************************************************
procedure PlayMediaPlayer(thePlayer : TMediaPlayer;
                          useNotify : Boolean;
                          errorWarning : TMediaPlayerWarning);
begin
  try
    thePlayer.Open;
    thePlayer.Notify := useNotify;
    thePlayer.Play;
  except
    on E:Exception do
    begin
      case errorWarning of
        WARN_MPLAYER_ONCE :
        begin
          if (not warnedMediaPlayer) then
          begin
            warnedMediaPlayer := TRUE;
            Dialog_Ops.MessageDlg(E.Message, mtError, [mbOK], 0);
          end; // if
        end; // option

        WARN_MPLAYER_ALWAYS :
        begin
          Dialog_Ops.MessageDlg(E.Message, mtError, [mbOK], 0);
        end; // option
      end; // case
    end; // on
  end; // except
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
  warnedMediaPlayer := FALSE;

end.
