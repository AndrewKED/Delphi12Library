unit Timezone_Ops;

interface

const
  TIMEZONES : array[1..592] of String
  = (
'Africa/Abidjan',
'Africa/Accra',
'Africa/Addis_Ababa',
'Africa/Algiers',
'Africa/Asmara',
'Africa/Asmera',
'Africa/Bamako',
'Africa/Bangui',
'Africa/Banjul',
'Africa/Bissau',
'Africa/Blantyre',
'Africa/Brazzaville',
'Africa/Bujumbura',
'Africa/Cairo',
'Africa/Casablanca',
'Africa/Ceuta',
'Africa/Conakry',
'Africa/Dakar',
'Africa/Dar_es_Salaam',
'Africa/Djibouti',
'Africa/Douala',
'Africa/El_Aaiun',
'Africa/Freetown',
'Africa/Gaborone',
'Africa/Harare',
'Africa/Johannesburg',
'Africa/Juba',
'Africa/Kampala',
'Africa/Khartoum',
'Africa/Kigali',
'Africa/Kinshasa',
'Africa/Lagos',
'Africa/Libreville',
'Africa/Lome',
'Africa/Luanda',
'Africa/Lubumbashi',
'Africa/Lusaka',
'Africa/Malabo',
'Africa/Maputo',
'Africa/Maseru',
'Africa/Mbabane',
'Africa/Mogadishu',
'Africa/Monrovia',
'Africa/Nairobi',
'Africa/Ndjamena',
'Africa/Niamey',
'Africa/Nouakchott',
'Africa/Ouagadougou',
'Africa/Porto-Novo',
'Africa/Sao_Tome',
'Africa/Timbuktu',
'Africa/Tripoli',
'Africa/Tunis',
'Africa/Windhoek',

'America/Adak',
'America/Anchorage',
'America/Anguilla',
'America/Antigua',
'America/Araguaina',
'America/Argentina/Buenos_Aires',
'America/Argentina/Catamarca',
'America/Argentina/ComodRivadavia',
'America/Argentina/Cordoba',
'America/Argentina/Jujuy',
'America/Argentina/La_Rioja',
'America/Argentina/Mendoza',
'America/Argentina/Rio_Gallegos',
'America/Argentina/Salta',
'America/Argentina/San_Juan',
'America/Argentina/San_Luis',
'America/Argentina/Tucuman',
'America/Argentina/Ushuaia',
'America/Aruba',
'America/Asuncion',
'America/Atikokan',
'America/Atka',
'America/Bahia',
'America/Bahia_Banderas',
'America/Barbados',
'America/Belem',
'America/Belize',
'America/Blanc-Sablon',
'America/Boa_Vista',
'America/Bogota',
'America/Boise',
'America/Buenos_Aires',
'America/Cambridge_Bay',
'America/Campo_Grande',
'America/Cancun',
'America/Caracas',
'America/Catamarca',
'America/Cayenne',
'America/Cayman',
'America/Chicago',
'America/Chihuahua',
'America/Coral_Harbour',
'America/Cordoba',
'America/Costa_Rica',
'America/Creston',
'America/Cuiaba',
'America/Curacao',
'America/Danmarkshavn',
'America/Dawson',
'America/Dawson_Creek',
'America/Denver',
'America/Detroit',
'America/Dominica',
'America/Edmonton',
'America/Eirunepe',
'America/El_Salvador',
'America/Ensenada',
'America/Fort_Nelson',
'America/Fort_Wayne',
'America/Fortaleza',
'America/Glace_Bay',
'America/Godthab',
'America/Goose_Bay',
'America/Grand_Turk',
'America/Grenada',
'America/Guadeloupe',
'America/Guatemala',
'America/Guayaquil',
'America/Guyana',
'America/Halifax',
'America/Havana',
'America/Hermosillo',
'America/Indiana/Indianapolis',
'America/Indiana/Knox',
'America/Indiana/Marengo',
'America/Indiana/Petersburg',
'America/Indiana/Tell_City',
'America/Indiana/Vevay',
'America/Indiana/Vincennes',
'America/Indiana/Winamac',
'America/Indianapolis',
'America/Inuvik',
'America/Iqaluit',
'America/Jamaica',
'America/Jujuy',
'America/Juneau',
'America/Kentucky/Louisville',
'America/Kentucky/Monticello',
'America/Knox_IN',
'America/Kralendijk',
'America/La_Paz',
'America/Lima',
'America/Los_Angeles',
'America/Louisville',
'America/Lower_Princes',
'America/Maceio',
'America/Managua',
'America/Manaus',
'America/Marigot',
'America/Martinique',
'America/Matamoros',
'America/Mazatlan',
'America/Mendoza',
'America/Menominee',
'America/Merida',
'America/Metlakatla',
'America/Mexico_City',
'America/Miquelon',
'America/Moncton',
'America/Monterrey',
'America/Montevideo',
'America/Montreal',
'America/Montserrat',
'America/Nassau',
'America/New_York',
'America/Nipigon',
'America/Nome',
'America/Noronha',
'America/North_Dakota/Beulah',
'America/North_Dakota/Center',
'America/North_Dakota/New_Salem',
'America/Ojinaga',
'America/Panama',
'America/Pangnirtung',
'America/Paramaribo',
'America/Phoenix',
'America/Port-au-Prince',
'America/Port_of_Spain',
'America/Porto_Acre',
'America/Porto_Velho',
'America/Puerto_Rico',
'America/Punta_Arenas',
'America/Rainy_River',
'America/Rankin_Inlet',
'America/Recife',
'America/Regina',
'America/Resolute',
'America/Rio_Branco',
'America/Rosario',
'America/Santa_Isabel',
'America/Santarem',
'America/Santiago',
'America/Santo_Domingo',
'America/Sao_Paulo',
'America/Scoresbysund',
'America/Shiprock',
'America/Sitka',
'America/St_Barthelemy',
'America/St_Johns',
'America/St_Kitts',
'America/St_Lucia',
'America/St_Thomas',
'America/St_Vincent',
'America/Swift_Current',
'America/Tegucigalpa',
'America/Thule',
'America/Thunder_Bay',
'America/Tijuana',
'America/Toronto',
'America/Tortola',
'America/Vancouver',
'America/Virgin',
'America/Whitehorse',
'America/Winnipeg',
'America/Yakutat',
'America/Yellowknife',

'Antarctica/Casey',
'Antarctica/Davis',
'Antarctica/DumontDUrville',
'Antarctica/Macquarie',
'Antarctica/Mawson',
'Antarctica/McMurdo',
'Antarctica/Palmer',
'Antarctica/Rothera',
'Antarctica/South_Pole',
'Antarctica/Syowa',
'Antarctica/Troll',
'Antarctica/Vostok',

'Arctic/Longyearbyen',

'Asia/Aden',
'Asia/Almaty',
'Asia/Amman',
'Asia/Anadyr',
'Asia/Aqtau',
'Asia/Aqtobe',
'Asia/Ashgabat',
'Asia/Ashkhabad',
'Asia/Atyrau',
'Asia/Baghdad',
'Asia/Bahrain',
'Asia/Baku',
'Asia/Bangkok',
'Asia/Barnaul',
'Asia/Beirut',
'Asia/Bishkek',
'Asia/Brunei',
'Asia/Calcutta',
'Asia/Chita',
'Asia/Choibalsan',
'Asia/Chongqing',
'Asia/Chungking',
'Asia/Colombo',
'Asia/Dacca',
'Asia/Damascus',
'Asia/Dhaka',
'Asia/Dili',
'Asia/Dubai',
'Asia/Dushanbe',
'Asia/Famagusta',
'Asia/Gaza',
'Asia/Harbin',
'Asia/Hebron',
'Asia/Ho_Chi_Minh',
'Asia/Hong_Kong',
'Asia/Hovd',
'Asia/Irkutsk',
'Asia/Istanbul',
'Asia/Jakarta',
'Asia/Jayapura',
'Asia/Jerusalem',
'Asia/Kabul',
'Asia/Kamchatka',
'Asia/Karachi',
'Asia/Kashgar',
'Asia/Kathmandu',
'Asia/Katmandu',
'Asia/Khandyga',
'Asia/Kolkata',
'Asia/Krasnoyarsk',
'Asia/Kuala_Lumpur',
'Asia/Kuching',
'Asia/Kuwait',
'Asia/Macao',
'Asia/Macau',
'Asia/Magadan',
'Asia/Makassar',
'Asia/Manila',
'Asia/Muscat',
'Asia/Nicosia',
'Asia/Novokuznetsk',
'Asia/Novosibirsk',
'Asia/Omsk',
'Asia/Oral',
'Asia/Phnom_Penh',
'Asia/Pontianak',
'Asia/Pyongyang',
'Asia/Qatar',
'Asia/Qostanay',
'Asia/Qyzylorda',
'Asia/Rangoon',
'Asia/Riyadh',
'Asia/Saigon',
'Asia/Sakhalin',
'Asia/Samarkand',
'Asia/Seoul',
'Asia/Shanghai',
'Asia/Singapore',
'Asia/Srednekolymsk',
'Asia/Taipei',
'Asia/Tashkent',
'Asia/Tbilisi',
'Asia/Tehran',
'Asia/Tel_Aviv',
'Asia/Thimbu',
'Asia/Thimphu',
'Asia/Tokyo',
'Asia/Tomsk',
'Asia/Ujung_Pandang',
'Asia/Ulaanbaatar',
'Asia/Ulan_Bator',
'Asia/Urumqi',
'Asia/Ust-Nera',
'Asia/Vientiane',
'Asia/Vladivostok',
'Asia/Yakutsk',
'Asia/Yangon',
'Asia/Yekaterinburg',
'Asia/Yerevan',

'Atlantic/Azores',
'Atlantic/Bermuda',
'Atlantic/Canary',
'Atlantic/Cape_Verde',
'Atlantic/Faeroe',
'Atlantic/Faroe',
'Atlantic/Jan_Mayen',
'Atlantic/Madeira',
'Atlantic/Reykjavik',
'Atlantic/South_Georgia',
'Atlantic/St_Helena',
'Atlantic/Stanley',

'Australia/ACT',
'Australia/Adelaide',
'Australia/Brisbane',
'Australia/Broken_Hill',
'Australia/Canberra',
'Australia/Currie',
'Australia/Darwin',
'Australia/Eucla',
'Australia/Hobart',
'Australia/LHI',
'Australia/Lindeman',
'Australia/Lord_Howe',
'Australia/Melbourne',
'Australia/NSW',
'Australia/North',
'Australia/Perth',
'Australia/Queensland',
'Australia/South',
'Australia/Sydney',
'Australia/Tasmania',
'Australia/Victoria',
'Australia/West',
'Australia/Yancowinna',

'Brazil/Acre',
'Brazil/DeNoronha',
'Brazil/East',
'Brazil/West',

'CET',
'CST6CDT',

'Canada/Atlantic',
'Canada/Central',
'Canada/Eastern',
'Canada/Mountain',
'Canada/Newfoundland',
'Canada/Pacific',
'Canada/Saskatchewan',
'Canada/Yukon',

'Chile/Continental',
'Chile/EasterIsland',
'Cuba',
'EET',
'EST',
'EST5EDT',
'Egypt',
'Eire',
'Etc/GMT',
'Etc/GMT+12',
'Etc/GMT+11',
'Etc/GMT+10',
'Etc/GMT+9',
'Etc/GMT+8',
'Etc/GMT+7',
'Etc/GMT+6',
'Etc/GMT+5',
'Etc/GMT+4',
'Etc/GMT+3',
'Etc/GMT+2',
'Etc/GMT+1',
'Etc/GMT-1',
'Etc/GMT-2',
'Etc/GMT-3',
'Etc/GMT-4',
'Etc/GMT-5',
'Etc/GMT-6',
'Etc/GMT-7',
'Etc/GMT-8',
'Etc/GMT-9',
'Etc/GMT-10',
'Etc/GMT-11',
'Etc/GMT-12',
'Etc/GMT-13',
'Etc/GMT-14',

'Etc/GMT+0',
'Etc/GMT-0',
'Etc/GMT0',
'Etc/Greenwich',
'Etc/UCT',
'Etc/UTC',
'Etc/Universal',
'Etc/Zulu',
'UCT',
'UTC',
'Zulu',
'GMT',
'GMT+0',
'GMT-0',
'GMT0',
'Greenwich',
'Universal',

'Europe/Amsterdam',
'Europe/Andorra',
'Europe/Astrakhan',
'Europe/Athens',
'Europe/Belfast',
'Europe/Belgrade',
'Europe/Berlin',
'Europe/Bratislava',
'Europe/Brussels',
'Europe/Bucharest',
'Europe/Budapest',
'Europe/Busingen',
'Europe/Chisinau',
'Europe/Copenhagen',
'Europe/Dublin',
'Europe/Gibraltar',
'Europe/Guernsey',
'Europe/Helsinki',
'Europe/Isle_of_Man',
'Europe/Istanbul',
'Europe/Jersey',
'Europe/Kaliningrad',
'Europe/Kiev',
'Europe/Kirov',
'Europe/Lisbon',
'Europe/Ljubljana',
'Europe/London',
'Europe/Luxembourg',
'Europe/Madrid',
'Europe/Malta',
'Europe/Mariehamn',
'Europe/Minsk',
'Europe/Monaco',
'Europe/Moscow',
'Europe/Nicosia',
'Europe/Oslo',
'Europe/Paris',
'Europe/Podgorica',
'Europe/Prague',
'Europe/Riga',
'Europe/Rome',
'Europe/Samara',
'Europe/San_Marino',
'Europe/Sarajevo',
'Europe/Saratov',
'Europe/Simferopol',
'Europe/Skopje',
'Europe/Sofia',
'Europe/Stockholm',
'Europe/Tallinn',
'Europe/Tirane',
'Europe/Tiraspol',
'Europe/Ulyanovsk',
'Europe/Uzhgorod',
'Europe/Vaduz',
'Europe/Vatican',
'Europe/Vienna',
'Europe/Vilnius',
'Europe/Volgograd',
'Europe/Warsaw',
'Europe/Zagreb',
'Europe/Zaporozhye',
'Europe/Zurich',
'GB',
'GB-Eire',

'HST',
'Hongkong',
'Iceland',
'Indian/Antananarivo',
'Indian/Chagos',
'Indian/Christmas',
'Indian/Cocos',
'Indian/Comoro',
'Indian/Kerguelen',
'Indian/Mahe',
'Indian/Maldives',
'Indian/Mauritius',
'Indian/Mayotte',
'Indian/Reunion',
'Iran',
'Israel',
'Jamaica',
'Japan',
'Kwajalein',
'Libya',
'MET',
'MST',
'MST7MDT',
'Mexico/BajaNorte',
'Mexico/BajaSur',
'Mexico/General',
'NZ',
'NZ-CHAT',
'Navajo',
'PRC',
'PST8PDT',
'Pacific/Apia',
'Pacific/Auckland',
'Pacific/Bougainville',
'Pacific/Chatham',
'Pacific/Chuuk',
'Pacific/Easter',
'Pacific/Efate',
'Pacific/Enderbury',
'Pacific/Fakaofo',
'Pacific/Fiji',
'Pacific/Funafuti',
'Pacific/Galapagos',
'Pacific/Gambier',
'Pacific/Guadalcanal',
'Pacific/Guam',
'Pacific/Honolulu',
'Pacific/Johnston',
'Pacific/Kiritimati',
'Pacific/Kosrae',
'Pacific/Kwajalein',
'Pacific/Majuro',
'Pacific/Marquesas',
'Pacific/Midway',
'Pacific/Nauru',
'Pacific/Niue',
'Pacific/Norfolk',
'Pacific/Noumea',
'Pacific/Pago_Pago',
'Pacific/Palau',
'Pacific/Pitcairn',
'Pacific/Pohnpei',
'Pacific/Ponape',
'Pacific/Port_Moresby',
'Pacific/Rarotonga',
'Pacific/Saipan',
'Pacific/Samoa',
'Pacific/Tahiti',
'Pacific/Tarawa',
'Pacific/Tongatapu',
'Pacific/Truk',
'Pacific/Wake',
'Pacific/Wallis',
'Pacific/Yap',
'Poland',
'Portugal',
'ROC',
'ROK',
'Singapore',
'Turkey',
'US/Alaska',
'US/Aleutian',
'US/Arizona',
'US/Central',
'US/East-Indiana',
'US/Eastern',
'US/Hawaii',
'US/Indiana-Starke',
'US/Michigan',
'US/Mountain',
'US/Pacific',
'US/Samoa',
'W-SU',
'WET'
);

function PC2UTC(datetimePC : TDateTime) : TDateTime;
function UTC2PC(datetimeUTC : TDateTime) : TDateTime;
function GetPCTimeZoneDelta: Double;
function GetPCTimeZoneDeltaString : String;
function GetTimeZoneDeltaString(offset : Double) : String;
function TimeZoneOffsetValid(utcOffset : String) : Boolean;
function ConvertTimeZoneString(offset : String) : Double;

implementation

uses
  System.SysUtils,
  Windows,
  Str_Ops;

//***************************************************************************
//
//  FUNCTION  : GetPCTimeZoneDelta
//
//  I/P       : None
//
//  O/P       : Double - the offset, in faction of a day, so that when added
//                to the PC's date/time will convert it to UTC date/time.
//
//  OPERATION : From borland.public.delphi.winapi
//
//              Bias provides the offset in minutes.
//
//  UPDATED   : 2019-10-23
//
//***************************************************************************
function GetPCTimeZoneDelta: Double;
var
  TzInfo: TTimeZoneInformation;

begin
  case GetTimeZoneInformation(TzInfo) of
    TIME_ZONE_ID_UNKNOWN:
      result := TzInfo.Bias / 1440;
    TIME_ZONE_ID_STANDARD:
      result := (TzInfo.Bias + TzInfo.StandardBias) / 1440;
    TIME_ZONE_ID_DAYLIGHT:
      result := (TzInfo.Bias + TzInfo.DayLightBias) / 1440;
    else
      RaiseLastOSError;
      result := 0.0;
  end; // case
end; // GetPCTimeZoneDelta

//***************************************************************************
//
//  FUNCTION  : GetPCTimeZoneDeltaString
//
//  I/P       : None
//
//  O/P       : String - The PC's time zone
//
//  OPERATION : Return the PC's time zone as a signed ('+' or '-') 'hh:nn'
//              value.
//
//              This is the standard expression, showing how many hours the
//              PC is ahead (+) or behind (-) UTC.
//
//  UPDATED   : 2019-10-23
//
//***************************************************************************
function GetPCTimeZoneDeltaString : String;
var
  offset : Double;

begin
  offset := 1.0 - GetPCTimeZoneDelta;
  if (offset >= 1.0) then
  begin
    result := '+' + FormatDateTime('hh:nn', offset);
  end // if
  else
  begin
    result := '-' + FormatDateTime('hh:nn', 1.0 - offset);
  end; // else
end; // GetPCTimeZoneDeltaString

//***************************************************************************
//
//  FUNCTION  : PC2UTC
//
//  I/P       : datetimeUTC : TDateTime - the date and time in local (PC) time
//
//  O/P       : TDateTime - The given date and time, converted to UTC,
//                using the PC's current time zone information.
//
//  OPERATION : Converts a given local (PC) datetime to UTC datetime.
//
//              Note that the PC's current time zone delta information is used.
//              This means that (particularly where DST is in operation) there
//              is a chance of error when converting historical datetimes.
//
//  UPDATED   : 2020-01-02
//
//***************************************************************************
function PC2UTC(datetimePC : TDateTime) : TDateTime;
begin
  Result := datetimePC + GetPCTimeZoneDelta;
end; // PC2UTC

//***************************************************************************
//
//  FUNCTION  : UTC2PC2
//
//  I/P       : datetimeUTC : TDateTime - the date and time in UTC
//
//  O/P       : TDateTime - The given date and time, converted to local (PC) time,
//                using the PC's current time zone information.
//
//  OPERATION : Converts a given UTC datetime to local datetime.
//
//              Note that the PC's current time zone delta information is used.
//              This means that (particularly where DST is in operation) there
//              is a chance of error when converting historical datetimes.
//
//  UPDATED   : 2020-01-02
//
//***************************************************************************
function UTC2PC(datetimeUTC : TDateTime) : TDateTime;
begin
  Result := datetimeUTC - GetPCTimeZoneDelta;
end; // UTC2PC2

//***************************************************************************
//
//  FUNCTION  : GetTimeZoneDeltaString
//
//  I/P       : offset : Double - The time offset of the zone. Expected to be
//                -12/24 <= x <= 14/24
//
//  O/P       : String - The represented time zone in form '±hh:mm'
//
//  OPERATION : Returns the given time zone offset as a signed ('+' or '-')
//              'hh:nn' value
//
//  UPDATED   : 2019-10-23
//
//***************************************************************************
function GetTimeZoneDeltaString(offset : Double) : String;
begin
  offset := Frac(offset);
  if (offset >= 0.0) then
  begin
    result := '+' + FormatDateTime('hh:nn', offset);
  end // if
  else
  begin
    result := '-' + FormatDateTime('hh:nn', 1.0 - offset);
  end; // else
end; // GetTimeZoneDeltaString

//***************************************************************************
//
//  FUNCTION  : TimeZoneOffsetValid
//
//  I/P       :
//
//  O/P       : Boolean;
//
//  OPERATION : Tests a UTC offset string, which should in the format '±hh:mm'
//              Limits : +14:00 (Line Islands Time), -12:00 (e.g. Baker Island Time)
//              and minutes of 00, 15, 30 or 45
//
//              Reference : https://en.m.wikipedia.org/wiki/List_of_time_zone_abbreviations
//
//  UPDATED   : 2019-10-23
//
//***************************************************************************
function TimeZoneOffsetValid(utcOffset : String) : Boolean;
var
  hours : Integer;
  minutes : Integer;

begin
  result := (Length(utcOffset) = 6) and
            (CharInSet(utcOffset[1], ['+', '-'])) and
            (utcOffset[4] = ':') and
            IsAnInteger(Copy(utcOffset, 2, 2)) and
            IsAnInteger(Copy(utcOffset, 5, 2));
  if (result) then
  begin
    hours := StrToInt(Copy(utcOffset, 2, 2));
    minutes := StrToInt(Copy(utcOffset, 5, 2));
    result := (hours <= 14) and
              ((minutes mod 15) = 0)
  end; // if
end; // TimeZoneOffsetValid

//***************************************************************************
//
//  FUNCTION  : ConvertTimeZoneString
//
//  I/P       : offset : String - The UTC offset, specified in form '±hh:mm'
//
//  O/P       : Double - A value to add to local datetime to get UTC.
//
//  OPERATION : Converts a Timezone offset format string (i.e. '±hh:mm') into
//              a value that can be subtracted from the local datetime to get UTC.
//
//  UPDATED   : 2019-10-23
//
//***************************************************************************
function ConvertTimeZoneString(offset : String) : Double;
var
  AFormatSettings : TFormatSettings;

begin
  result := 0.0;
  if (TimeZoneOffsetValid(offset)) then
  begin
    AFormatSettings := TFormatSettings.Create;
    AFormatSettings.TimeSeparator := ':';
    result := StrToTime(Copy(offset, 2, Length(offset)), AFormatSettings);
    if (offset[1] = '-') then
    begin
      result := -result;
    end;
  end; //if
end;

end.
