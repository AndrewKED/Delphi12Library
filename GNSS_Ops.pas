unit GNSS_Ops;

interface

type
  TGNSSData = record
    rmcValid : Boolean;
    rmcUTC : TDateTime;
    rmcLatitude : Double;
    rmcLongitude : Double;
    rmcSpeedOverGround : Single;
    rmcCourseOverGround : Single;
    rmcMagneticVariation : Single;
    rmcMode : AnsiChar;
    ggaValid : Boolean;
    ggaUTCTime : TDateTime;
    ggaLatitude : Double;
    ggaLongitude : Double;
    ggaQuality : Integer;
    ggaSatellitesInUse : Integer;
    ggaHDOP : Double;
    ggaAltitudeMSL : Double;
    ggaGeodSeparation : Double;
    ggaDGPSAge : Double;
    ggaDGPSStationID : Double;
  end;

function DMToD(valueDM : Double) : Double;
function NMEASentenceOK(sentence : AnsiString) : Boolean;
function GotRMCData(var sentence : AnsiString;
                    var gnssData : TGNSSData) : Boolean;
function GotGGAData(var sentence : AnsiString;
                    var gnssData : TGNSSData) : Boolean;

implementation

uses
  System.SysUtils,
  Str_Ops, KEDConstants;

//***************************************************************************
//
//  FUNCTION  : DMToD
//
//  I/P       : valueDM : Double - A degrees value, of the form
//                degrees*100 + minutes
//
//  O/P       : Double - the converted value, being decimal degrees.
//
//  OPERATION : Convert a degrees value from the standard NMEA form into decimal
//              degrees.
//
//              Latitude and longitude from the sonde are reported in this
//              fashion, as per the NMEA message standard.
//
//  UPDATED   : 2024-09-06
//
//***************************************************************************
function DMToD(valueDM : Double) : Double;
var
  temp : Double;

begin
  temp := 1.0;
  if (valueDM < 0.0) then
    temp := -1.0;
  valueDM := Abs(valueDM);
  Result := temp * (Int(valueDM / 100.0) + Frac(valueDM / 100.0) / 0.6);
end; // DMToD

//***************************************************************************
//
//  FUNCTION  : GetDegrees
//
//  I/P       : var sentence : AnsiString - the string from which to read
//
//              negativeIndicator : AnsiChar - The character in the next field
//                that will indicate a negative value. (Usually 'S' or 'W')
//
//  O/P       : Double - The degrees in decimal form
//
//  OPERATION : Extracts degrees from the form [D]DDMM.MMM which includes a
//                with a hemisphere (negative) indicator in the following
//                comma-separated field.
//
//
//  UPDATED   : 2019-07-10
//
//***************************************************************************
function GetDegrees(var sentence : AnsiString;
                    negativeIndicator : AnsiChar) : Double;
var
  sTemp : AnsiString;
  currentDS : Char;

begin
  sTemp := ExtractAndTrim(sentence,',');

  currentDS := FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator := '.';
  result := DMToD(StrToFloat(String(sTemp)));
  FormatSettings.DecimalSeparator := currentDS;

  if (ExtractAndTrim(sentence,',') = negativeIndicator) then
    result := - result;
end; // GetDegrees

//***************************************************************************
//
//  FUNCTION  : NMEASentenceOK
//
//  I/P       : sentence : AnsiString - The NMEA sentence (without terminating '\r'
//
//  O/P       : Boolean - TRUE if the NMEA sentence is valid
//
//  OPERATION : The sentence supplied was found to be #$0D-terminated, and holds
//              at maximum, a single NMEA sentence
//              Remove #$0D characters
//              Check that the sentence is a suitable length (used when sentences
//                are built character by character)
//              Check that the sentence has a checksum
//              Check that the checksum is valid
//
//  UPDATED   : 2019-05-17
//
//***************************************************************************
function NMEASentenceOK(sentence : AnsiString) : Boolean;
var
  checksumHex : String;
  checksumExpected : Byte;
  checksumRxed : Byte;
  n : Integer;

begin
  // Remove any line feed characters
  sentence := AnsiString(StringReplace(String(sentence), #$0A, '', [rfReplaceAll]));

  if ((Length(sentence) >= 3) and
      (sentence[1] = '$') and
      (sentence[Length(sentence)-2] = '*')) then
  begin
    // The two characters after the '*' are meant to be the hex checksum
    // It seems as if the iMet GNSS may replace a leading '0' in the checksum with
    // a space. It's safe to replace.
    checksumHex := Copy(String(sentence),Length(sentence)-1,2);
    checksumHex := SearchAndReplace(checksumHex,' ','0');
    if (IsAHexadecimal(checksumHex)) then
    begin
      checksumExpected := StrToInt('$' + checksumHex);
      // Test whether checksum is OK
      checksumRxed := 0;
      // The checksum is an EXOR of all characters between the '$' (1st char)
      // and the '*' (which precedes the 2-character checksum)
      for n := 2 to Pos('*', String(sentence))-1 do
         checksumRxed := checksumRxed xor Ord(sentence[n]);

      result := (checksumRxed = checksumExpected);
    end // if
    else
    begin
      result := FALSE;
    end;
  end // if
  else
  begin
    result := FALSE;
  end;
end; // NMEASentenceOK

//***************************************************************************
//
//  FUNCTION  : GotRMCData
//
//  I/P       : var sentence : AnsiString -
//
//              gnssData : TGNSSData -
//
//  O/P       :
//
//  OPERATION : Attempt to parse a valid NMEA sentence (i.e. basic format and
//              checksum OK) as a '$G_RMC' (GNSS Recommended Minimum Data)
//
//  UPDATED   : 2019-05-17
//
//***************************************************************************
function GotRMCData(var sentence : AnsiString;
                    var gnssData : TGNSSData) : Boolean;
var
  tempDS : Char;
  iUTCYear : Integer;
  iUTCMonth : Integer;
  iUTCDay : Integer;
  iUTCHour : Integer;
  iUTCMinute : Integer;
  iUTCSecond : Integer;
  iUTCMillisecond : Integer;
  sTemp : AnsiString;

begin
  if ((Pos('$G', String(sentence)) = 1) and
      (Pos('RMC,', String(sentence)) = 4)) then
  begin
    result := TRUE;

    gnssData.rmcValid := FALSE;

    tempDS := FormatSettings.DecimalSeparator;
    FormatSettings.DecimalSeparator := '.';

    // Get rid of sentence ID/header
    ExtractAndTrim(sentence,',');
    // This check helps to prevent exceptions during debuggin
    if ((Length(sentence)>0) and
        (sentence[1] <> ',')) then
    begin
      try
        // Read the hhmmss.ss UTC time field
        iUTCHour := StrToInt(String(ExtractAndTrimTo(sentence, 2)));
        iUTCMinute := StrToInt(String(ExtractAndTrimTo(sentence, 2)));
        iUTCSecond := StrToInt(String(ExtractAndTrimTo(sentence, 2)));
        // Some RMC sentences appear not to have milliseconds
        if (sentence[1] = '.') then
        begin
          ExtractAndTrim(sentence,'.');
          iUTCMillisecond := 10 * StrToInt(String(ExtractAndTrim(sentence, ',')));
        end // if
        else
        begin
          ExtractAndTrim(sentence, ',');
          iUTCMillisecond := 0;
        end; // else

        if (ExtractAndTrim(sentence, ',') = 'A') then
        begin
          gnssData.rmcLatitude := GetDegrees(sentence, 'S');
          gnssData.rmcLatitude := GetDegrees(sentence, 'W');
          gnssData.rmcSpeedOverGround := StrToFloat(String(ExtractAndTrim(sentence, ',')));
          gnssData.rmcCourseOverGround := StrToFloat(String(ExtractAndTrim(sentence, ',')));

          // Read the ddmmyy UTC date field
          iUTCDay := StrToInt(String(ExtractAndTrimTo(sentence, 2)));
          iUTCMonth := StrToInt(String(ExtractAndTrimTo(sentence, 2)));
          iUTCYear := 2000 + StrToInt(String(ExtractAndTrimTo(sentence, 2)));
          ExtractAndTrim(sentence, ',');

          gnssData.rmcUTC := EncodeDate(iUTCYear, iUTCMonth, iUTCDay) +
                             EncodeTime(iUTCHour, iUTCMinute, iUTCSecond, iUTCMillisecond);

          sTemp := ExtractAndTrim(sentence, ',');
          if IsAFloat(String(sTemp)) then
          begin
            gnssData.rmcMagneticVariation := StrToFloat(String(sTemp));
            if (ExtractAndTrim(sentence, ',') = 'W') then
            begin
              gnssData.rmcMagneticVariation := -gnssData.rmcMagneticVariation;
            end; // if
          end // if
          else
          begin
            gnssData.rmcMagneticVariation := INVALID_VALUE;
          end;

          sTemp := ExtractAndTrim(sentence, ',');
          if (Length(sTemp) > 0)  then
          begin
            gnssData.rmcMode := sTemp[1];
            gnssData.rmcValid := (gnssData.rmcMode <> 'N');
          end;// if
        end; // if
      except
      end;
    end;

    FormatSettings.DecimalSeparator := tempDS;
  end // if
  else
  begin
    result := FALSE;
  end; // else
end; // GotRMCData

//***************************************************************************
//
//  FUNCTION  : GotGGAData
//
//  I/P       : var sentence : AnsiString -
//
//              gnssData : TGNSSData -
//
//  O/P       :
//
//  OPERATION : Attempt to parse a valid NMEA sentence (i.e. basic format and
//              checksum OK) as a '$G_GGA' (GNSS Recommended Minimum Data)
//
//  UPDATED   : 2019-05-17
//
//***************************************************************************
function GotGGAData(var sentence : AnsiString;
                    var gnssData : TGNSSData) : Boolean;
var
  tempDS : Char;

begin
  if ((Pos('$G', String(sentence)) = 1) and
      (Pos('GGA,', String(sentence)) = 4)) then
  begin
    result := TRUE;

    gnssData.ggaValid := FALSE;

    tempDS := FormatSettings.DecimalSeparator;
    FormatSettings.DecimalSeparator := '.';

    // Get rid of sentence ID/header
    ExtractAndTrim(sentence,',');
    // This check helps to prevent exceptions during debuggin
    if ((Length(sentence)>0) and
        (sentence[1] <> ',')) then
    begin
      try
        // Skip the hhmmss.ss UTC time field
        ExtractAndTrim(sentence, ',');

        gnssData.ggaLatitude := GetDegrees(sentence, 'S');
        gnssData.ggaLongitude := GetDegrees(sentence, 'W');

        gnssData.ggaQuality := StrToInt(String(ExtractAndTrim(sentence, ',')));
        if ((gnssData.ggaQuality = 1) or
            (gnssData.ggaQuality = 2) or
            (gnssData.ggaQuality = 3)) then
        begin
          gnssData.ggaValid := TRUE;

          gnssData.ggaSatellitesInUse := StrToInt(String(ExtractAndTrim(sentence, ',')));
          gnssData.ggaHDOP := StrToFloat(String(ExtractAndTrim(sentence, ',')));
          gnssData.ggaAltitudeMSL := StrToFloat(String(ExtractAndTrim(sentence, ',')));
        end; // if

      except
      end;
    end; // if

    FormatSettings.DecimalSeparator := tempDS;
  end // if
  else
  begin
    result := FALSE;
  end; // else
end; // GotRMCData

end.
