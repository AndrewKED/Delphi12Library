unit SunMoon;

//***************************************************************************
//
// DESCRIPTION:
//  Routines for calculations relating to sun and moon events
//
// TO BE DONE:
//
//    Changes Made :
//
// VERSIONS:
//    Update Date : 2007/02/01
//
// REFERENCES:
//   Sun rise and set algorithm :
//     http://media.skytonight.com/binary/sunup.bas
//     Sky & Telescope magazine, August 1994, page 84
//   Moon phase algorithm :
//     http://media.skytonight.com/binary/moonfx.bas
//
// DEFINITIONS: (collated from various sources)
//   Right Ascension (or hour angle):
//     RA is the astronomical equivalent of longitude.   Facing north, objects
//     appear to rise on your right (east), and hence the name Right Ascension.
//     It is measured in hours, minutes and seconds, from 0 to 24, inceasing
//     from east to west (and hence 1 hour of RA = 15 degrees of arc).
//
//     The zero point is known as the Vernal Equinox point.   This is where the
//     sun crosses the celestial equator at the March equinox (i.e. the vernal
//     (spring) equinox on 21 March).   It is a line running pole to pole and
//     cutting through eastern Pegasus, or the first point in Aries.
//
//     The right ascension of a celestial body is the angle between the
//     meridian on which that body lies and the Vernal Equinox, as measured
//     along the celestial equator.
//
//   Declination :
//     Declination is the astronomical equivalent of latitude.   The angular
//     distance north or south of the celestial equator, expressed in degrees.
//     North is +ve, up to 90°, and south is -ve, down to -90°
//
//     A celestial object that passes over the zenith of an observer has a
//     declination equal to the latitude of the observer.
//
//   Celestial Equator :
//     A great circle on the imaginary celestial sphere, which is actually the
//     plane of the terrestrial equator extended out into the universe (i.e. it
//     could be constructed by extrapolating the Earth's equator until it
//     touches the celestial sphere).  The celestial equator is inclined by
//     ~23.5°, with respect to the ecliptic plane; a result of the earth's axial
//     tilt.
//
//     If an observer stands on the earth equator, he or she sees the celestial
//     equator as a semicircle passing through the zenith. As the observer goes
//     to the north (or south) the celestial equator tilts towards south
//     (or north) horizon. However, because the celestial equator is
//     theoretically infinitely far (on the celestial sphere), irrespective of
//     the observer position, the observer always sees the endings of this
//     semicircle exactly in his/her local east/west horizon.
//
//   Ecliptic plane :
//     The ecliptic is the apparent path the Sun traces out along the sky —
//     independent of Earth's rotation — in the course of the year.  More
//     accurately, it is the intersection of the celestial sphere with the
//     ecliptic plane, which is the geometric plane containing the mean orbit
//     of the Earth around the Sun.  It should be distinguished from the
//     invariable ecliptic plane, which is the vector sum of the angular momenta
//     of all planetary orbital planes, to which Jupiter is the main contributor.
//
//   Sideral Time :
//     Time measured with respect to the stars (the vernal equinox) instead of
//     the sun.   Time required for the Earth to rotate once on its axis relative
//     to the stars.
//
//     During the course of one day, the earth has moved a short distance along
//     its orbit around the sun, and so must rotate a small extra angular distance
//     before the sun reaches its highest point. The stars, however, are so far
//     away that the earth's movement along its orbit makes a generally negligible
//     difference to their apparent direction, and so they return to their highest
//     point in slightly less than 24 hours.   A mean sidereal day is about
//     23h 56m 4.1s in length.  However, due to variations in the rotation rate
//     of the Earth the rate of an ideal sidereal clock deviates from any simple
//     multiple of a civil clock.
//
//   Solar Time :
//     Time measured by the apparent diurnal motion (apparent motion of the
//     sun around the earth) of the sun.   Local noon in solar time is defined
//     as the moment when the sun is at its highest point in the sky.   The time
//     taken for the sun to return to its highest point is 24 hours, or a solar day.
//
//
//***************************************************************************

interface

const
// IDs for astronomical body behaviour during a specified day
//------------------------------------------------------------------------------
  BODY_RISE_SET = 0;      // The body both rose and set in this day
  BODY_BELOW_HORIZ = 1;   // The body did not appear in this day
  BODY_ABOVE_HORIZ = 2;   // The body was visible for the entire day
  BODY_NOT_RISE = 3;      // The body did not rise during this day
  BODY_NOT_SET = 4;       // The body did not set during this day

  MOON_CYCLE_DAYS = 29.530588853; // Number of days for the moon to complete a full cycle

type
  TAstralBodyDay = record
    dRiseTime : Double;
    dRiseAz : Double;
    dSetTime : Double;
    dSetAz : Double;
    iBehaviour : Integer;
  end; // record

function GetRefraction(dElevation : Double;
                       dPressure : Double;
                       dTemperature : Double) : Double;
function GetVisibleSunAreaRatio(dSolarAngle : Double;
                                dHeight : Double;
                                dPressure : Double;
                                dTemperature : Double) : Double;
procedure GetSunPosition(dJulianDate : Double;
                         dCenturies : Double;
                         var dRightAscension : Double;
                         var dDeclination : Double;
                         var dDistance : double);
procedure GetMoonPosition(dJulian : Double;
                          var dRightAscension : Double;
                          var dDeclination : Double;
                          var dDistance : double);
function GetSunAngle(dtWhen : TDateTime;
                     dLatitude : Double;
                     dLongitude : double) : Double;
function LocalSiderealTime(dLongitude : Double;
                           dJulianDate : Double;
                           dZone : double) : Double;
procedure GetSunRiseSet(dObserverLatitude : Double;
                        dObserverLongitude : Double;
                        dtObserverDate : TDateTime;
                        dTZone : Double;
                        var abRiseSet : TAstralBodyDay);
procedure GetMoonRiseSet(dObserverLatitude : Double;
                        dObserverLongitude : Double;
                        dtObserverDate : TDateTime;
                        dTZone : Double;
                        var abRiseSet : TAstralBodyDay);
function GetMoonPhase(dtPhaseDateTime : TDateTime) : Double;

implementation

uses Math, DateUtils, SysUtils,
     Maths, TimeDate;

const
  // Sidereal time runs faster than solar time by 1.00273790935
  SIDEREAL_PER_SOLAR = 1.00273790935;
  SIDEREAL_HOUR = 15.0 * PI/180.0 * SIDEREAL_PER_SOLAR;

  R_EARTH = 6372;                         // Earth radius in kilometres
  BETA_SUN = 32/60/2.0;                   // Apparent angular radius of solar disk (diameter = 32')

//***************************************************************************
//
//  FUNCTION  : GetRefraction
//
//  I/P       : dElevation : Double - Elevation in degrees
//
//              dPressure : Double - Pressure in hPa
//
//              dTemperature : Double - Temperature in °C
//
//  O/P       : Double - in degrees
//
//  OPERATION : Calculate the atmospheric refraction in degrees for a given
//              elevation. Uses Saemundsson's empirical formula with the
//              correction for non-standard pressures and temperatures
//
//              http://www.jgiesen.de/refract/index.html
//
//  UPDATED   :
//
//***************************************************************************
function GetRefraction(dElevation : Double;
                       dPressure : Double;
                       dTemperature : Double) : Double;
var
  dRefraction : Double;
begin

  // For values below -5 elevation, return 0 to avoid tan function discontinuity
  if (dElevation < -5.0) then
  begin
    result := 0;
    Exit;
  end;

  // Saemundsson's formula (result in arcminutes)
  dRefraction := 1.02/tan((dElevation + (10.3/(dElevation + 5.11)))*PI/180);

  // Correct for non-reference pressure and temperature
  dRefraction := dRefraction * ((dPressure/1010) * 283/(273 + dTemperature));

  // Return as degrees (60 arc minutes = 1 degree)
  result := dRefraction / 60;
end; // GetRefraction

//***************************************************************************
//
//  FUNCTION  : GetVisibleSunAreaRatio
//
//  I/P       : dSolarAngle : Double
//
//              dHeight : Double - in km
//
//              dPressure : Double - in hPa
//
//              dTemperature : Double - in °C
//
//  O/P       :
//
//  OPERATION : Calculate the ratio of the area of the sun that is visible
//              above the horizon, as fraction of the total apparent sun area.
//              The calculation takes into account flattening of the sun due to
//              differing refraction at the upper and lower edge of the solar
//              disk.
//              Full analysis and derivation is shown in "SRC_modification.pdf"
//
//  UPDATED   :
//
//***************************************************************************
function GetVisibleSunAreaRatio(dSolarAngle : Double;
                                dHeight : Double;
                                dPressure : Double;
                                dTemperature : Double) : Double;
var
  dTheta : Double;
  dRefraction : Double;
  dDelta : Double;
  dVisibleSunRatio : Double;
  dR_1 : Double;
  dR_2 : Double;
  dBeta_Prime : Double;
begin

  // Calculate elevation of the horizon in degrees, viewed from the sonde
  dTheta := arccos(R_EARTH/(R_EARTH + dHeight)) * 180/PI;

  // Calculate refraction at horizon, in degrees
  dRefraction := GetRefraction(dSolarAngle, dPressure, dTemperature);

  // Calculate angle between sun and horizon, taking into account refraction
  dDelta := dTheta + dSolarAngle + dRefraction;

  // Calculate refractions R1 and R2 at upper and lower edge of the solar disk
  dR_1 := GetRefraction(dSolarAngle + BETA_SUN, dPressure, dTemperature);
  dR_2 := GetRefraction(dSolarAngle - BETA_SUN, dPressure, dTemperature);

  // Determine minor radius b' of the flattened sun
  dBeta_Prime := ((2 * BETA_SUN) + dR_1 - dR_2) / 2;

  // How much of the sun is visible?
  if (dDelta > dBeta_Prime) then
  begin
    // Full sun visible -> day
    dVisibleSunRatio := 1.0;
  end

  else if (dDelta < -dBeta_Prime) then
  begin
    // No sun visible -> night
    dVisibleSunRatio := 0.0;
  end // if
  else
  begin
    // A portion of the sun is visible -> twilight

    // Calculate the ratio of visible segment vs total solar ellipse area
    dVisibleSunRatio := 1.0/PI * (arccos(-dDelta / dBeta_Prime)
                                 - 0.5 * sin(2*arccos(-dDelta / dBeta_Prime)));
  end; // else

  result := dVisibleSunRatio;
end; // GetVisibleSunAreaRatio

//***************************************************************************
//
//  FUNCTION  : GetSunPosition
//
//  I/P       : dJulianDate (double) - the Julian Date for which the postion
//                is required.
//
//              dCenturies (double) - the centuries since 1900.
//
//  O/P       : dRightAscension (double) - The RA of the sun on the given date
//
//              dDeclination (double) - The Dec of the sun on the given date
//
//              dDistance (double) - The distance to the sun (not tested)
//
//  OPERATION : Compute the sun's position using fundamental arguments
//              based on Van Flandern & Pulkkinen, 1979
//
//  UPDATED   : 2007/02/02
//
//***************************************************************************
procedure GetSunPosition(dJulianDate : Double;
                         dCenturies : Double;
                         var dRightAscension : Double;
                         var dDeclination : Double;
                         var dDistance : double);
var
  dLO : Double;
  dG : Double;
  dV : Double;
  dU : Double;
  dW : Double;
  dS : Double;
begin

  dLO := 0.779072 + 0.00273790931 * dJulianDate;
  dLO := dLO - Int(dLO);
  dLO := dLO * 2.0 * PI;

  dG := 0.993126 + 0.0027377785 * dJulianDate;
  dG := dG - INT(dG);
  dG := dG * 2.0 * PI;

  dV := 0.39785*Sin(dLO);
  dV := dV - 0.01000 * Sin(dLO - dG);
  dV := dV + 0.00333 * Sin(dLO + dG);
  dV := dV - 0.00021 * dCenturies * Sin(dLO);

  dU := 1.0 - 0.03349 * Cos(dG);
  dU := dU - 0.00014 * Cos(2*dLO);
  dU := dU + 0.00008 * Cos(dLO);

  dW := -0.00010 - 0.04129 * SIN(2*dLO);
  dW := dW + 0.03211 * Sin(dG);
  dW := dW + 0.00104 * Sin(2*dLO - dG);
  dW := dW - 0.00035 * Sin(2*dLO + dG);
  dW := dW - 0.00008 * dCenturies * Sin(dG);

  // Compute Sun's Right ascension and declination
  dS := dW / Sqrt(dU - dV*dV);
  dRightAscension := dLO + Arctan(dS/SQR(1 - dS*dS));
  dS := dV / Sqrt(dU);
  dDeclination := Arctan(dS / Sqrt(1 - dS*dS));
  dDistance := 1.00021 * Sqrt(dU);
end; // GetSunPosition

//***************************************************************************
//
//  FUNCTION  : GetMoonPosition
//
//  I/P       : dJulianDate (double) - the Julian Date for which the postion
//                is required.
//
//  O/P       : dRightAscension (double) - The RA of the moon on the given date
//
//              dDeclination (double) - The Dec of the moon on the given date
//
//              dDistance (double) - The distance of the moon on the given date
//
//  OPERATION : Compute the moons's position
//
//  UPDATED   : 2007/02/02
//
//***************************************************************************
procedure GetMoonPosition(dJulian : Double;
                          var dRightAscension : Double;
                          var dDeclination : Double;
                          var dDistance : double);
var
  l,m,f,d,n,g : Double;
  dV : Double;
  dU : Double;
  dW : Double;
  dS : Double;
begin
  l := 0.606434 + 0.03660110129 * dJulian;
  m := 0.374897 + 0.03629164709 * dJulian;
  f := 0.259091 + 0.0367481952 * dJulian;
  d := 0.827362 + 0.03386319198 * dJulian;
  n := 0.347343 - 0.00014709391 * dJulian;
  g := 0.993126 + 0.0027377785 * dJulian;
  l := l - Int(l);
  m := m - Int(m);
  f := f - Int(f);
  d := d - Int(d);
  n := n - Int(n);
  g := g - Int(g);
  l := l * 2 * Pi;
  m := m * 2 * Pi;
  f := f * 2 * Pi;
  d := d * 2 * Pi;
  n := n * 2 * Pi;
  g := g * 2 * Pi;

  dV := 0.39558 * Sin(f + n) +
        0.08200 * Sin(f) +
        0.03257 * Sin(m - f - n) +
        0.01092 * Sin(m + f + n) +
        0.00666 * Sin(m - f) -
        0.00644 * Sin(m + f - 2 * d + n) -
        0.00331 * Sin(f - 2 * d + n) -
        0.00304 * Sin(f - 2 * d) -
        0.00240 * Sin(m - f - 2 * d - n) +
        0.00226 * Sin(m + f) -
        0.00108 * Sin(m + f - 2 * d) -
        0.00079 * Sin(f - n) +
        0.00078 * Sin(f + 2 * d + n);

  dU := 1.0 -
        0.10828 * Cos(m) -
        0.01880 * Cos(m - 2 * d) -
        0.01479 * Cos(2 * d) +
        0.00181 * Cos(2 * m - 2 * d) -
        0.00147 * Cos(2 * m) -
        0.00105 * Cos(2 * d - g) -
        0.00075 * Cos(m - 2 * d + g);

  dW := 0.10478 * Sin(m) -
        0.04105 * Sin(2 * f + 2 * n) -
        0.02130 * Sin(m - 2 * d) -
        0.01779 * Sin(2 * f + n) +
        0.01774 * Sin(n) +
        0.00987 * Sin(2 * d) -
        0.00338 * Sin(m - 2 * f - 2 * n) -
        0.00309 * Sin(g) -
        0.00190 * Sin(2 * f) -
        0.00144 * Sin(m + n) -
        0.00144 * Sin(m - 2 * f - n) -
        0.00113 * Sin(m + 2 * f + 2 * n) -
        0.00094 * Sin(m - 2 * d + g) -
        0.00092 * Sin(2 * m - 2 * d);

  //  Compute Right Ascession
  dS := dW / Sqrt(dU - dV * dV);
  dRightAscension := l + Arctan(dS / Sqrt(1 - dS * dS));
  // Compute the Declination
  dS := dV / sqrt(dU);
  dDeclination := Arctan(dS / Sqrt(1 - dS * dS));
  // Compute the Distance
  dDistance := 60.40974 * Sqrt(dU);
end; // GetMoonPosition

//***************************************************************************
//
//  FUNCTION  : GetSunAngle
//
//  I/P       : dtWhen (TDateTime) - The UTC date and time at which the
//                calculation is required.
//
//              dLatitude (double) - Latitude in degrees (north is +ve)
//
//              dLongitude (double) - Longitude in degrees (east is +ve)
//  O/P       :
//
//  OPERATION : Returns the elevation angle of the sun (relative to horizon)
//              for a given location and UTC date.
//
//  UPDATED   : 2007-09-11
//
//***************************************************************************
function GetSunAngle(dtWhen : TDateTime;
                     dLatitude : Double;
                     dLongitude : double) : Double;
const
  SUN_DECLINATION : array[0..364] of double
                    = (-23.0533, -22.9717, -22.8833, -22.7867, -22.6817, -22.5717, -22.4517,
                       -22.3267, -22.1933, -22.0517, -21.9033, -21.7483, -21.5867, -21.4167,
                       -21.2417, -21.0583, -20.8700, -20.6733, -20.4700, -20.2617, -20.0467,
                       -19.8233, -19.5967, -19.3617, -19.1233, -18.8767, -18.6250, -18.3683,
                       -18.1050, -17.838, -17.5650, -17.2867, -17.0033, -16.7133, -16.4200,
                       -16.1217, -15.8200, -15.5117, -15.2000, -14.8850, -14.5650, -14.2400,
                       -13.9117, -13.5800, -13.2433, -12.9033, -12.5617, -12.2150, -11.8650,
                       -11.5117, -11.1567, -10.7983, -10.4367, -10.0717, -9.7067, -9.3367,
                       -8.9650, -8.5917, -8.2167, -7.8383, -7.4583, -7.0783, -6.6950,
                       -6.3100, -5.9250, -5.5367, -5.1483, -4.7583, -4.3683, -3.9750,
                       -3.5833, -3.1900, -2.7950, -2.4017, -2.0067, -1.6117, -1.2150,
                       -0.8200, -0.4250, 0.0300, 0.3667, 0.7600, 1.1550, 1.5483,
                       1.9417, 2.3350, 2.7267, 3.1167, 3.5067, 3.8950, 4.2833,
                       4.6683, 5.0533, 5.4367, 5.8183, 6.1983, 6.5767, 6.9517,
                       7.3267, 7.6983, 8.0683, 8.4367, 8.8017, 9.1650, 9.5267,
                       9.8833, 10.2400, 10.5917, 10.9417, 11.2883, 11.6317, 11.9717,
                       12.3083, 12.6417, 12.9717, 13.2983, 13.6217, 13.9400, 14.2550,
                       14.5667, 14.8733, 15.1767, 15.4750, 15.7700, 16.0600, 16.3467,
                       16.6283, 16.9050, 17.1767, 17.4450, 17.7067, 17.9650, 18.2167,
                       18.4650, 18.7067, 18.9433, 19.1750, 19.4017, 19.6217, 19.8383,
                       20.0467, 20.2517, 20.4483, 20.6417, 20.8283, 21.0083, 21.1817,
                       21.3500, 21.5117, 21.6683, 21.8167, 21.9600, 22.0967, 22.2267,
                       22.3517, 22.4683, 22.5800, 22.6833, 22.7817, 22.8733, 22.9567,
                       23.0350, 23.1050, 23.1700, 23.2267, 23.2767, 23.3200, 23.3567,
                       23.3867, 23.4100, 23.4267, 23.4350, 23.4383, 23.4333, 23.4217,
                       23.4033, 23.3783, 23.3450, 23.3067, 23.2600, 23.2083, 23.1483,
                       23.0833, 23.0100, 22.9300, 22.8450, 22.7517, 22.6517, 22.5467,
                       22.4333, 22.3150, 22.1900, 22.0583, 21.9200, 21.7750, 21.6250,
                       21.4683, 21.3067, 21.1367, 20.9633, 20.7817, 20.5950, 20.4033,
                       20.2050, 20.0017, 19.7933, 19.5783, 19.3583, 19.1333, 18.9033,
                       18.6667, 18.4267, 18.1817, 17.9300, 17.6750, 17.4133, 17.1483,
                       16.8783, 16.6050, 16.3267, 16.0433, 15.7550, 15.4633, 15.1683,
                       14.8683, 14.5633, 14.2567, 13.9450, 13.6300, 13.3100, 12.9883,
                       12.6633, 12.3333, 12.0017, 11.6667, 11.3283, 10.9867, 10.6417,
                       10.2950, 9.9450, 9.5933, 9.2383, 8.8800, 8.5200, 8.1583,
                       7.7950, 7.4283, 7.0600, 6.6883, 6.3167, 5.9433, 5.5667,
                       5.1900, 4.8117, 4.4317, 4.0500, 3.6667, 3.2833, 2.8983,
                       2.5133, 2.1267, 1.7400, 1.3533, 0.9650, 0.5750, 0.1867,
                       -0.2017, -0.5917, -0.9817, -1.3700, -1.7567, -2.1460, -2.5367,
                       -2.9250, -3.3133, -3.7017, -4.0867, -4.4733, -4.8583, -5.2417,
                       -5.6250, -6.0067, -6.3867, -6.7667, -7.1433, -7.5200, -7.8933,
                       -8.2667, -8.6367, -9.0050, -9.3717, -9.7350, -10.0967, -10.4550,
                       -10.8117, -11.1667, -11.5167, -11.8650, -12.2100, -12.5517, -12.8900,
                       -13.2250, -13.5583, -13.8867, -14.2100, -14.5317, -14.8483, -15.1617,
                       -15.4717, -15.7750, -16.0767, -16.3717, -16.6633, -16.9500, -17.2317,
                       -17.5083, -17.7800, -18.0467, -18.3083, -18.5650, -18.8150, -19.0617,
                       -19.3000, -19.5333, -19.7617, -19.9833, -20.1983, -20.4083, -20.6117,
                       -20.8083, -20.9983, -21.1817, -21.3583, -21.5300, -21.6933, -21.8500,
                       -22.0000, -22.1417, -22.2783, -22.4067, -22.5267, -22.6417, -22.7483,
                       -22.8467, -22.9383, -23.0217, -23.0983, -23.1667, -23.2283, -23.2817,
                       -23.3267, -23.3650, -23.3950, -23.4167, -23.4300, -23.4367, -23.4350,
                       -23.4267, -23.4100, -23.3850, -23.3517, -23.3117, -23.2633, -23.2067,
                       -23.1433);


var
  lha : Double;     // local hour angle in degrees with a range of 0-360 and +W
  co_hs : Double;   // co-solar height in degrees or solar elevation
  d : Double;
  iYearDay : Integer; // A value of 0 for 1 Jan and 364 for 31 Dec

begin
  // Determine the approximate local hour angle of the location west to the sun
  lha := DegToRad(dLongitude + 180.0 + (Frac(dtWhen) * 360.0));

(*
    // approximate local hour angle (from the radiosonde west to the sun)
    lha := lon + (180.0 + (time/3600.0)*15.0);
    lha *= D2R;
*)
  // Get the day offset into the year.   Cheat a bit for leap years.
  iYearDay := DayOfTheYear(dtWhen)-1;
  if (iYearDay = 365) then
    Dec(iYearDay);

  d := DegToRad(SUN_DECLINATION[iYearDay]);

  // co-solar height calculation
  co_hs := arcsin(sin(d)*sin(DegToRad(dLatitude))-cos(d)*cos(DegToRad(dLatitude))*cos(lha-PI));

  result := RadToDeg(co_hs);
end; // GetSunAngle

//***************************************************************************
//
//  FUNCTION  : LocalSiderealTime
//
//  I/P       : dLongitude (double) - The longitude, in decimal degrees, for
//                which the LST is to be calculated.
//
//              dJulianDate (double) - The Julian Date - 2451545 i.e. relative
//                to Jan 1.5 2000 for which the LST is to be calculated.
//
//              dZone (double) - The time zone offset to Greenwich expressed
//                in hours (east is -ve) (e.g. SAST = -2.0/24.0)
//
//  O/P       : (double) - the local sidereal time.
//
//  OPERATION : Operates from the known sidereal time at 1.5 January 2000.
//
//  UPDATED   : 2007/02/02
//
//***************************************************************************
function LocalSiderealTime(dLongitude : Double;
                           dJulianDate : Double;
                           dZone : double) : Double;
var
  dS : Double;
begin
  dS := 24110.5 +
        (8640184.812999999 * dJulianDate / 36525.0) +
        (dZone * 60.0 * 60.0 * SIDEREAL_PER_SOLAR) +
        (24.0 * 60.0 * 60.0 * dLongitude / 360.0);
  dS := dS / (24 * 60 * 60);
  dS := dS - Int(dS);
  result := dS * DegToRad(360);
end; // LocalSiderealTime

//***************************************************************************
//
//  FUNCTION  : GetSunRiseSet
//
//  I/P       : dObserverLatitude (double) - The latitude of the observer
//
//              dObserverLongitude (double) - The longitude of the observer
//
//              dtObserverDate (TDateTime) - The date for which the info
//                is required.
//
//              dTZone (double) - The number of hours behind UTC (west of
//                Greenwich).   SAST would be -2.
//
//  O/P       : var abRiseSet : TAstralBodyDay - Details
//
//  OPERATION : Based on a program by Roger W. Sinnott calculates the times of
//              sunrise and sunset on any date, accurate to the minute within
//              several centuries of the present.  It correctly describes what
//              happens in the arctic and antarctic regions, where the Sun may
//              not rise or set on a given date.  The calculation is discussed
//              in Sky & Telescope for August 1994, page 84.
//
//  UPDATED   : 2007/02/01
//
//***************************************************************************
procedure GetSunRiseSet(dObserverLatitude : Double;
                        dObserverLongitude : Double;
                        dtObserverDate : TDateTime;
                        dTZone : Double;
                        var abRiseSet : TAstralBodyDay);
var
  dJulianDate : Double;
  dLST : Double;  // Local sidereal time
  dCent : Double;
  dRefractionCorrection : Double;
  iStepHours : Integer;
  dFrac : Double;
  adVHz : array[0..2] of double;
  bRise : boolean;
  bSet : boolean;
  dRAStart : Double;
  dRAEnd : Double;
  dRADaySpan : Double;
  dDecStart : Double;
  dDecEnd : Double;
  dDecDaySpan : Double;
  dDistStart : Double;
  dDistEnd : Double;
  dLastRA : Double;
  dNextRA : Double;
  dLastDec : Double;
  dNextDec : Double;

  //***************************************************************************
  //
  //  FUNCTION  : TestHourForEvent
  //
  //  I/P       :
  //
  //  O/P       :
  //
  //  OPERATION : Check to see if any events happen in this hour
  //
  //  UPDATED   : 2007/02/01
  //
  //***************************************************************************
  procedure TestHourForEvent (iHr : Integer;
                              dLocSidTime : Double;
                              dObsLat : Double;
                              dRefCorrection : double);
  var
    adHA : array[0..2] of double;
    dHalfHourDec : Double;
    S,C,Z : Double;
    A,B,D,E : Double;
    dHZ,dNZ,dDZ : Double;
    dEventTime : Double;
    dEventAz : Double;

  begin
    adHA[0] := dLocSidTime - dLastRA + iHr*SIDEREAL_HOUR;
    adHA[2] := dLocSidTime - dNextRA + iHr*SIDEREAL_HOUR + SIDEREAL_HOUR;

    // Hour angle
    adHA[1] := (adHA[2] + adHA[0])/2.0;
    // Declination at half hour
    dHalfHourDec := (dNextDec + dLastDec)/2;

    S := Sin(DegToRad(dObsLat));
    C := Cos(DegToRad(dObsLat));
    // Approximate correction for refraction + body semidiameter at horizon
    Z := Cos(DegToRad(dRefCorrection));

    // First pass
    if (iHr <= 0) then
      adVHz[0] := S*Sin(dLastDec) + C*Cos(dLastDec)*Cos(adHA[0]) - Z;

    adVHz[2] := S*Sin(dNextDec) + C*Cos(dNextDec)*Cos(adHA[2]) - Z;

    // Check for an event
    if (Sign(adVHz[0]) <> Sign(adVHz[2])) then
    begin
      adVHz[1] := S*Sin(dHalfHourDec) + C*Cos(dHalfHourDec)*Cos(adHA[1]) - Z;
      A := 2*adVHz[0] - 4*adVHz[1] + 2*adVHz[2];
      B := -3*adVHz[0] + 4*adVHz[1] - adVHz[2];
      D := B*B - 4*A*adVHz[0];

      if (D >= 0) then
      begin
        D := Sqrt(D);

        E := (-B + D)/(2*A);
        if ((E > 1) or (E < 0)) then
          E := (-B - D)/(2*A);

        // The time of the event
        dEventTime := (iHr + E + 1/120) / 24.0;

        // Azimuth of the body at the event time
        dHZ := adHA[0] + E*(adHA[2] - adHA[0]);
        dNZ := -Cos(dHalfHourDec) * Sin(dHZ);
        dDZ := C*Sin(dHalfHourDec) - S*Cos(dHalfHourDec)*Cos(dHZ);
        dEventAz := RadToDeg(Arctan(dNZ/dDZ));
        if (dDZ < 0) then
          dEventAz := dEventAz + 180.0;
        if (dEventAz < 0.0) then
          dEventAz := dEventAz + 360.0
        else
          if (dEventAz > 360.0) then
            dEventAz := dEventAz - 360.0;

        if ((adVHz[0] < 0.0) AND (adVHz[2] > 0.0)) then
        begin
          abRiseSet.dRiseTime := dEventTime;
          abRiseSet.dRiseAz := dEventAz;
          bRise := TRUE;
        end; // if
        if ((adVHz[0] > 0.0) and (adVHz[2] < 0.0)) then
        begin
          abRiseSet.dSetTime := dEventTime;
          abRiseSet.dSetAz := dEventAz;
          bSet := TRUE;
        end;// if
      end;// if
    end;// if
  end; // TestHourForEvent

begin
  // Julian day relative to Jan 1.5 2000
  dJulianDate := DateTimeToJulianDate(Int(dtObserverDate)) - 2451545;

  // Get the centuries from 1900
  dCent := dJulianDate/36525.0 + 1.0;

  // Local Sidereal Time for zone
  dLST := LocalSiderealTime(dObserverLongitude, dJulianDate, dTZone);

  // Get the sun's position at the start of the day
  dJulianDate := dJulianDate + dTZone/24.0;
  GetSunPosition(dJulianDate,dCent,dRAStart,dDecStart,dDistStart);
  // Get the sun's position at the end of the day
  dJulianDate := dJulianDate + 1.0;
  GetSunPosition(dJulianDate,dCent,dRAEnd,dDecEnd,dDistEnd);
  // Make continuous
  if (dRAEnd < dRAStart) then
    dRAEnd := dRAEnd + 2*PI;

  // Initialise
  dRefractionCorrection := 90.833;
  bRise := FALSE;
  bSet := FALSE;
  dLastRA := dRAStart;
  dLastDec := dDecStart;
  dRADaySpan := dRAEnd - dRAStart;
  dDecDaySpan := dDecEnd - dDecStart;

  for iStepHours := 0 to 23 do
  begin
    dFrac := (iStepHours + 1) / 24.0;
    dNextRA := dRAStart + dFrac * dRADaySpan;
    dNextDec := dDecStart + dFrac * dDecDaySpan;
    TestHourForEvent(iStepHours,dLST,dObserverLatitude,dRefractionCorrection);
    // Advance to the next hour
    dLastRA := dNextRA;
    dLastDec := dNextDec;
    adVHz[0] := adVHz[2];
  end; // for

  // Flag whether ascent or descent happend on this day
  abRiseSet.iBehaviour := BODY_RISE_SET;
  if ((not bRise) and (not bSet)) then
  begin
    if (adVHz[2] < 0) then
      abRiseSet.iBehaviour := BODY_BELOW_HORIZ
    else
      if (adVHz[2] > 0) then
        abRiseSet.iBehaviour := BODY_ABOVE_HORIZ;
  end // if
  else
  begin
    if (not bRise) then
      abRiseSet.iBehaviour := BODY_NOT_RISE
    else
      if (not bSet) then
        abRiseSet.iBehaviour := BODY_NOT_SET
  end; // else
end; // GetSunRiseSet

//***************************************************************************
//
//  FUNCTION  : GetMoonRiseSet
//
//  I/P       : dObserverLatitude (double) - The latitude of the observer
//
//              dObserverLongitude (double) - The longitude of the observer
//
//              dtObserverDate (TDateTime) - The date for which the info
//                is required.
//
//              dTZone (double) - The number of hours behind UTC (west of
//                Greenwich).   SAST would be -2.
//
//  O/P       :
//
//  OPERATION : Based on a program at http://www.stargazing.net/mas/moonup.htm
//              The calculation is discussed in Sky & Telescope, July 1989, page 78.
//
//  UPDATED   : 2007/02/02
//
//***************************************************************************
procedure GetMoonRiseSet(dObserverLatitude : Double;
                         dObserverLongitude : Double;
                         dtObserverDate : TDateTime;
                         dTZone : Double;
                         var abRiseSet : TAstralBodyDay);
var
  i : Integer;
  dJulianDate : Double;
  dLST : Double;  // Local sidereal time
  dRefractionCorrection : Double;
  iStepHours : Integer;
  adRA : array[1..3] of double;
  adDec : array[1..3] of double;
  adDist : array[1..3] of double;
  dFrac : Double;
  adVHz : array[0..2] of double;
  bRise : boolean;
  bSet : boolean;
  dLastRA : Double;
  dNextRA : Double;
  dLastDec : Double;
  dNextDec : Double;

  //***************************************************************************
  //
  //  FUNCTION  : TestHourForEvent
  //
  //  I/P       :
  //
  //  O/P       :
  //
  //  OPERATION : Check to see if any events happen in this hour
  //
  //  UPDATED   : 2007/02/01
  //
  //***************************************************************************
  procedure TestHourForEvent (iHr : Integer;
                              dLocSidTime : Double;
                              dObsLat : Double;
                              dRefCorrection : double);
  var
    adHA : array[0..2] of double;
    dHalfHourDec : Double;
    S,C,Z : Double;
    A,B,D,E : Double;
    dHZ,dNZ,dDZ : Double;
    dEventTime : Double;
    dEventAz : Double;

  begin
    if (dNextRA < dLastRA) then
      dNextRA := dNextRA + 2*Pi;

    adHA[0] := dLocSidTime - dLastRA + iHr*SIDEREAL_HOUR;
    adHA[2] := dLocSidTime - dNextRA + iHr*SIDEREAL_HOUR + SIDEREAL_HOUR;

    // Hour angle
    adHA[1] := (adHA[2] + adHA[0])/2.0;
    // Declination at half hour
    dHalfHourDec := (dNextDec + dLastDec)/2;

    S := Sin(DegToRad(dObsLat));
    C := Cos(DegToRad(dObsLat));
    // Approximate correction for refraction + body semidiameter at horizon
    Z := Cos(DegToRad(dRefCorrection));

    // First pass
    if (iHr <= 0) then
      adVHz[0] := S*Sin(dLastDec) + C*Cos(dLastDec)*Cos(adHA[0]) - Z;

    adVHz[2] := S*Sin(dNextDec) + C*Cos(dNextDec)*Cos(adHA[2]) - Z;

    // Check for an event
    if (Sign(adVHz[0]) <> Sign(adVHz[2])) then
    begin
      adVHz[1] := S*Sin(dHalfHourDec) + C*Cos(dHalfHourDec)*Cos(adHA[1]) - Z;
      A := 2*adVHz[0] - 4*adVHz[1] + 2*adVHz[2];
      B := -3*adVHz[0] + 4*adVHz[1] - adVHz[2];
      D := B*B - 4*A*adVHz[0];

      if (D >= 0) then
      begin
        D := Sqrt(D);

        E := (-B + D)/(2*A);
        if ((E > 1) or (E < 0)) then
          E := (-B - D)/(2*A);

        // The time of the event
        dEventTime := (iHr + E + 1/120) / 24.0;

        // Azimuth of the body at the event time
        dHZ := adHA[0] + E*(adHA[2] - adHA[0]);
        dNZ := -Cos(dHalfHourDec) * Sin(dHZ);
        dDZ := C*Sin(dHalfHourDec) - S*Cos(dHalfHourDec)*Cos(dHZ);
        dEventAz := RadToDeg(Arctan(dNZ/dDZ));
        if (dDZ < 0) then
          dEventAz := dEventAz + 180.0;
        if (dEventAz < 0.0) then
          dEventAz := dEventAz + 360.0
        else
          if (dEventAz > 360.0) then
            dEventAz := dEventAz - 360.0;

        if ((adVHz[0] < 0.0) AND (adVHz[2] > 0.0)) then
        begin
          abRiseSet.dRiseTime := dEventTime;
          abRiseSet.dRiseAz := dEventAz;
          bRise := TRUE;
        end; // if
        if ((adVHz[0] > 0.0) and (adVHz[2] < 0.0)) then
        begin
          abRiseSet.dSetTime := dEventTime;
          abRiseSet.dSetAz := dEventAz;
          bSet := TRUE;
        end;// if
      end;// if
    end;// if
  end; // TestHourForEvent

  //***************************************************************************
  //
  //  FUNCTION  : ThreePointInterpolation
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
  function ThreePointInterpolation(dPoint0, dPoint1, dPoint2 : Double;
                                   dFraction : double) : Double;
  var
    a, b : Double;
  begin
    a := dPoint1 - dPoint0;
    b := dPoint2 - dPoint1 - a;
    result := dPoint0 + dFraction * (2 * a + b * (2 * dFrac - 1));
  end; // ThreePointInterpolation

begin
  // Julian day relative to Jan 1.5 2000
  dJulianDate := DateTimeToJulianDate(Int(dtObserverDate)) - 2451545;

  // Local Sidereal Time for zone
  dLST := LocalSiderealTime(dObserverLongitude,dJulianDate,dTZone);

  dJulianDate := dJulianDate + dTZone/24.0;

  for i := 1 to 3 do
  begin
    GetMoonPosition(dJulianDate,adRA[i],adDec[i],adDist[i]);
    dJulianDate := dJulianDate + 0.5;
  end; // for
  // Make continuous
  if (adRA[2] <= adRA[1]) then
    adRA[2] := adRA[2] + 2*Pi;
  if (adRA[3] <= adRA[2]) then
    adRA[3] := adRA[3] + 2*Pi;

  // Initialise
  dRefractionCorrection := 90.567 - 41.685 / adDist[2];
  bRise := FALSE;
  bSet := FALSE;
  dLastRA := adRA[1];
  dLastDec := adDec[1];

  for iStepHours := 0 to 23 do
  begin
    dFrac := (iStepHours + 1) / 24.0;
    dNextRA := ThreePointInterpolation(adRA[1],adRA[2],adRA[3],dFrac);
    dNextDec := ThreePointInterpolation(adDec[1],adDec[2],adDec[3],dFrac);
    TestHourForEvent(iStepHours,dLST,dObserverLatitude,dRefractionCorrection);
    // Advance to the next hour
    dLastRA := dNextRA;
    dLastDec := dNextDec;
    adVHz[0] := adVHz[2];
  end; // if

  // Flag whether ascent or descent happend on this day
  abRiseSet.iBehaviour := BODY_RISE_SET;
  if ((not bRise) and (not bSet)) then
  begin
    if (adVHz[2] < 0) then
      abRiseSet.iBehaviour := BODY_BELOW_HORIZ
    else
      if (adVHz[2] > 0) then
        abRiseSet.iBehaviour := BODY_ABOVE_HORIZ;
  end // if
  else
  begin
    if (not bRise) then
      abRiseSet.iBehaviour := BODY_NOT_RISE
    else
      if (not bSet) then
        abRiseSet.iBehaviour := BODY_NOT_SET
  end; // else
end; // GetMoonRiseSet

//***************************************************************************
//
//  FUNCTION  : GetMoonPhase
//
//  I/P       : dtUTCDateTime (TDateTime) - The UTC date and time at which
//                the phase of the moon is required.
//
//  O/P       :
//
//  OPERATION : I am not happy with this, and rather use a look up table based
//              on Astronomical Applications Dept., U.S. Naval Observatory,
//              which is also reported by
//
//  UPDATED   : 2007/02/02
//
//***************************************************************************
function GetMoonPhase(dtPhaseDateTime : TDateTime) : Double;
var
//  YY,MM,D,K1,K2,K3 : Double;
  JD, V : Double;

begin
  // Calculate illumination (synodic) phase
  JD := DateTimeToJulianDate(dtPhaseDateTime);
  V := (JD - 2451550.1) / MOON_CYCLE_DAYS;
// My offset using 2007/02/17 16h14 from Naval observatory  V := (JD - 2454148.1764) / MOON_CYCLE_DAYS;

// from http://www.moonphasecalendar.com/moon_phase_emergency.htm
//  V := ((dtPhaseDatetime - EncodeDate(2001,1,1)) * 850 + 5130.5769)/25101;

  result := Normalise(V);
(*
  // Calculate the Julian date at 12h UT on the given date
  D := DayOf(dtDate);
  YY := YearOf(dtDate) - Int((12 - MonthOf(dtDate))/10);
  MM := MonthOf(dtDate) + 9;
  if (MM >= 12) then
    MM := MM - 12;
  K1 := Int(365.25 * (YY + 4712));
  K2 := Int(30.6 * MM + 0.5);
  K3 := Int(Int((YY / 100) + 49) * 0.75) -38;
  JD := K1 + K2 + D + 59; // JD for dates in Julian calendar
  if JD > 2299160.0 then
    JD := JD - K3; // For Gregorian calendar

  // Calculate illumination (synodic) phase
  V := (JD - 2451550.1) / MOON_CYCLE_DAYS;
  result := Normalise(V);
*)
end; // GetMoonPhase

//***************************************************************************
//
//  FUNCTION  : GetMoonPhaseDateTime
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
(*
function GetMoonPhaseDateTime(dPhase : double) : TDateTime;
var
  YY,MM,D,K1,K2,K3,JD,V : Double;
begin
  dSinceLastNew := dPhase * MOON_CYCLE_DAYS;


  // Calculate the Julian date at 12h UT on the given date
  D := DayOf(dtDate);
  YY := YearOf(dtDate) - Int((12 - MonthOf(dtDate))/10);
  MM := MonthOf(dtDate) + 9;
  if (MM >= 12) then
    MM := MM - 12;
  K1 := Int(365.25 * (YY + 4712));
  K2 := Int(30.6 * MM + 0.5);
  K3 := Int(Int((YY / 100) + 49) * 0.75) -38;
  JD := K1 + K2 + D + 59; // JD for dates in Julian calendar
  if JD > 2299160.0 then
    JD := JD - K3; // For Gregorian calendar

//  JD1 := DateTimeToJulianDate(Int(dtDate));
//  JD := DateTimeToJulianDate(Int(dtDate)) - 0.5;

  // Calculate illumination (synodic) phase
  V := (JD - 2451550.1) / MOON_CYCLE_DAYS;
  result := Normalise(V);
*)

//***************************************************************************
//
//  FUNCTION  : GetMoonYear
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Identifies the date and UTC time of full and new moons.
//              It ties in very closely with figures published at
//              http://aa.usno.navy.mil/data/docs/MoonPhase.html
//
//  UPDATED   :
//
//***************************************************************************
procedure GetMoonYear (iYear : integer);
var
  bFullMoon : boolean;
  K0, T, T2, T3, J0, F0, J, F, M0, M1, B1, K, M5, M6, B6 : Double;
  K9 : Integer;
  JDE : Double;

begin
  bFullMoon := FALSE;

  K0 := Int((iYear-1900)*12.3685);
  T := (iYear-1899.5) / 100;
  T2 := T*T;
  T3 := T*T*T;
  J0 := 2415020 + 29*K0;
  F0 := 0.0001178*T2 - 0.000000155*T3 +
        (0.75933 + 0.53058868*K0) -
        (0.000837*T + 0.000335*T2);
  M0 := K0*0.08084821133;
  M0 := 360*(M0 - INT(M0)) + 359.2242 -
        0.0000333*T2 -
        0.00000347*T3;
  M1 := K0*0.07171366128;
  M1 := 360*(M1 - INT(M1)) + 306.0253 +
        0.0107306*T2 +
        0.00001236*T3;
  B1 := K0*0.08519585128;
  B1 := 360*(B1 - INT(B1)) + 21.2964 -
        0.0016528*T2 -
        0.00000239*T3;
  for K9 := 0 to 28 do
  begin
    J := J0 + 14*K9;
    F := F0 + 0.765294*K9;
    K := K9/2;
    M5 := DegToRad((M0 + K*029.10535608));
    M6 := DegToRad((M1 + K*385.81691806));
    B6 := DegToRad((B1 + K*390.67050646));
    F := F - 0.4068*Sin(M6) +
         (0.1734 - 0.000393*T)*Sin(M5) +
         0.0161*Sin(2*M6) +
         0.0104*Sin(2*B6) -
         0.0074*Sin(M5 - M6) -
         0.0051*Sin(M5 + M6) +
         0.0021*Sin(2*M5) +
         0.0010*Sin(2*B6-M6) +
         0.5 / 1440; //Adds 1/2 minute for proper rounding to minutes per Sky & Tel article
    // Julian Empheris Day with fractions for time of day
    JDE := J + F;
    JulianDateToDateTime(JDE);

		if (not bFullMoon) then
//!!  WriteNew( str )
    else
//!!  WriteFull(str ); 	//Output Result to correct panel

    bFullMoon := not bFullMoon;
  end; // for
end; // GetMoonYear


end.
