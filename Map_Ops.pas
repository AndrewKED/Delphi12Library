unit Map_Ops;

//***************************************************************************
//
// DESCRIPTION:
// Provides a number of helpful mapping and co-ordinate handling functions
// and procedures.
//
// REFERENCES:
// http://mtp.jpl.nasa.gov/notes/altitude/altitude.html
//
// Other calculations provided by Nico Bestbier, ASE
//
// TO BE DONE:
//
//  *
//
// VERSIONS:
//    Update Date :
//    Changes Made :
//      *
//
//    Update Date : 2005/04/28
//    Changes Made :
//      * Added RoughLLNE2LL
//      * Added this header
//
//***************************************************************************

// Notes
// http://www.uwgb.edu/dutchs/UsefulData/UTMFormulas.HTM for long/lat to UTM conversions

interface

const
// Textual degrees representation
  ID_DEG_DECIMAL = 0;             // Decimal degrees
  ID_DEG_DM_DECIMAL = 1;          // Degrees and decimal minutes
  ID_DEG_DMS = 2;                 // Degrees, minutes and decimal seconds

// Datum IDs
//------------------------------------------------------------------------------
  DATUMS_USED = 4;
  ID_DATUM_WGS84 = 0;             // International
  ID_DATUM_CLARK1880 = 1;         // France, Africa
  ID_DATUM_CLARK1866 = 2;         // US
  ID_DATUM_BESSEL1841 = 3;        // Central Europe, Chile, Indonesia

// WGS84 Earth constants
//------------------------------------------------------------------------------
  // Eqautorial radius (a), in m                         // WGS84        Clark 1880    Clark1866     BESSEL1841
  SEMI_MAJOR_AXIS : array[0..DATUMS_USED-1] of double = (6378137.0,      6378249.145,  6378206.4,    6377397.155);
  // Polar radius (b), in m
  SEMI_MINOR_AXIS : array[0..DATUMS_USED-1] of double = (6356752.3142,   6356514.967,  6356583.8,    6356078.963);

  // As far as I know, other datums do not define the quantities below, so the WGS84 definitions will
  // be used in all cases.
  OMEGA_WGS84 = 7.2921151467E-5;            // Earth's rotation rate in rad/s
  POLAR_GRAVITY_WGS84 = 9.8321849378;       // Gravity at the poles m/s2
  EQUATORIAL_GRAVITY_WGS84 = 9.7803253359;  // Gravity at the equator m/s2
  GM_WGS84 = 3.986005E+14;                  // Earth's universal gravitational constant

  GRAVITY45_WMO = 9.80665;                  // WMO Gravity at 45° (actually at 45.542°) but this does not
                                            // change its usage in geopotential calculations

// Where does this software originate (Marks the City Hall)
//------------------------------------------------------------------------------
  LATITUDE_CAPETOWN = -33.925096;
  LONGITUDE_CAPETOWN =  18.423776;

// IDs for an 8-point compass
//------------------------------------------------------------------------------
  COMPASS_DIR_8_N = 0;
  COMPASS_DIR_8_NE = 1;
  COMPASS_DIR_8_E = 2;
  COMPASS_DIR_8_SE = 3;
  COMPASS_DIR_8_S = 4;
  COMPASS_DIR_8_SW = 5;
  COMPASS_DIR_8_W = 6;
  COMPASS_DIR_8_NW = 7;

type
  vec3 = array[1..3] of double;
  vec2 = array[1..2] of double;

procedure RoughDeltaLL2NE(dFromLatitudeA,dFromLongitudeA : Double;
                          dToLatitudeB,dToLongitudeB : Double;
                          var dNorthings,dEastings : double);
function radiusEarth(latitude : Double) : Double;
procedure RoughLLNE2LL(dFromLatitude,dFromLongitude : Double;
                       dNorthings,dEastings : Double;
                       var dToLatitude,dToLongitude : double);
//  procedure RoughLLBD2LL(dFromLatitude,dFromLongitude : Double;
//                         dBearing,dDistance : Double;
//                         var dToLatitude,dToLongitude : double);
procedure EC_XYZ2LLA(Xi: vec3; var Xo: vec3);
procedure EC_LLA2XYZ(Xi: vec3; var Xo: vec3);
function GravityAtLatitude(dLatitude : double) : Double;
function Rwgs(dLatitude : double) : Double;
function GeometricToGeopotential_1(dGeometric : Double;
                                   dLatitude : double) : Double;
function GeopotentialToGeometric_1(dGeopotential : Double;
                                   dLatitude : double) : Double;
function GeometricToGeopotential_2(dGeometric : Double;
                                   dGravity : Double;
                                   dRwgs : double) : Double;
function GeopotentialToGeometric_2(dGeopotential : Double;
                                   dGravity : Double;
                                   dRwgs : double) : Double;
function DegToDMSHString(dDegrees : Double;
                         iDegreesDigits : Integer;
                         iSecondsDecimals : Integer;
                         cDegreeChar : Char;
                         cPos : Char;
                         cNeg : Char) : String;
function DegToDMHString(dDegrees : Double;
                        iDegreesDigits : Integer;
                        iMinutesDecimals : Integer;
                        cDegreeChar : char;
                        cPos : char;
                        cNeg : char) : String;
function DegToDHString(dDegrees : Double;
                       iDegreesDigits : Integer;
                       iDegreesDecimals : Integer;
                       cDegreeChar : char;
                       cPos : char;
                       cNeg : char) : String;
procedure LatLong2UTM(dLatitude : Double;
                      dLongitude : Double;
                      var sGrid : String;
                      var dNorthings : Double;
                      var dEastings : double);
procedure UTM2LatLong(sGrid : String;
                      dNorthings : Double;
                      dEastings : Double;
                      var dLatitude : Double;
                      var dLongitude : double);
procedure NEAltOffset2AzEl(dNorthOffset : Double;
                           dEastOffset : Double;
                           dAltOffset : Double;
                           var dAz : Double;
                           var dEl : double);
procedure AzElAlt2NEOffset(dAzimuth : Double;
                           dElevation : Double;
                           dAltOffset : Double;
                           var dNorthOffset : Double;
                           var dEastOffset : double);
function GetEarthOctant(dLatitude : Double;
                        dLongitude : double) : Integer;
function LatitudeToText(degrees : Double;
                        idFormat : Integer = ID_DEG_DECIMAL;
                        decimalPlaces : Integer = 6) : String;
function LongitudeToText(degrees : Double;
                         idFormat : Integer = ID_DEG_DECIMAL;
                         decimalPlaces : Integer = 6) : String;
function CompassDirections8(id : Integer) : String;

implementation

uses
  SysUtils, Math, System.StrUtils,
{$IFNDEF NO_DKLANG}
  DKLang,
{$ENDIF}
  Maths, Str_Ops, KEDConstants;

const
  c = 299792458.0;             {WGS-84 speed of light}
  F = -4.442807633E-10;        {relativistic correction term constant}
  tau=0.075;
  K0 = 0.9996;                 // Scale along central meridian of UTM

var
  dSomiglianas : Double;
  dEccentricity : Double;
  dFlattening : Double;
  dGravityRatio : Double;
  dE : Double;                // This is the eccentricity of the earth's elliptical cross-section.
  dE1 : Double;
  dEPrimeSquared : Double;
  dAPrime : Double;
  dBPrime : Double;
  dCPrime : Double;
  dDPrime : Double;
  dEPrime : Double;
  dE1Sqr : Double;
  dE2Sqr : Double;
  dSine1Second : Double;
  iDatumToUse : Integer;

//***************************************************************************
//
//  FUNCTION    :   RoughDeltaLL2NE
//
//  I/P         :   dFromLatitudeA (double) - Latitude of the starting
//                    point in decimal degrees.
//
//                  dFromLongitudeA (double) - Longitude of the starting
//                    point in decimal degrees.
//
//                  dToLatitudeB (double) - Latitude of the finishing
//                    point in decimal degrees.
//
//                  dToLongitudeB (double) - Longitude of the finishing
//                    point in decimal degrees.
//
//  O/P         :   dNorthings (double) - The distance moved north (positive)
//                    in metres.
//
//                  dEastings (double) - The distance moved east (positive)
//                    in metres
//
//  OPERATION   :   Determine the northings and eastings in metres between
//                  the two given locations.   This algorithm is only
//                  "accurate" if the locations are relatively close together.
//                  I have not quantified it, as the accuracy will vary over
//                  the globe surface.   I would guess that it is usable if
//                  the positions vary by a few degrees.
//
//                  Note that the eastings value is the more inaccurate of
//                  the two values returned due to the changes in the
//                  circumference of a same-latitude circle.
//
// Compare http://edwilliams.org/avform147.htm#flat
//
//  UPDATED     :   2004/10/13
//
//***************************************************************************
procedure RoughDeltaLL2NE(dFromLatitudeA,dFromLongitudeA : Double;
                          dToLatitudeB,dToLongitudeB : Double;
                          var dNorthings,dEastings : double);
var
  dAverageLat : Double;
  dX, dY : Double;
  dSameLatCircum : Double;
  dEarthCentreToSurface : Double;
  dSameLongCircum : Double;

begin
  // This is where an accuracy problem creeps in.   The eastings beween A and B
  // will give different values, depending on whether you use LatitudeA or LatitudeB
  // as the reference.   This is because the circumference of the same-latitude circle
  // (centred on a N/S axis centre) varies quite considerably, especially nearer the poles.
  // I use the average to minimise the error.
  dAverageLat := (dFromLatitudeA + dToLatitudeB) / 2.0;
  // The radius from earth centre to surface varies with latitude too.   The equator is
  // further from the centre of the earth than the poles.   As long as the difference
  // between LatitudeA and LatitudeB is small, the difference is minimal.
  // I use the average to minimise the error.

  // Slice the earth through the longitude and longitude+180 to get an ellipse.
  // The N/S axis is the Y axis, and from surface to surface at the equator is the X-axis.
  // Then the equation for the ellipse is
  //          X = (radius at equator) * cos(latitude)
  //          Y = (radius at poles) * sin(latitude)
  dX := SEMI_MAJOR_AXIS[iDatumToUse] * cos(dAverageLat * PI / 180.0);
  dY := SEMI_MINOR_AXIS[iDatumToUse] * sin(dAverageLat * PI / 180.0);
  // dX is the radius of the same-latitude circle, centred on the N/S axis.
  // Determine the circumference of that same latitude circle.
  dSameLatCircum := 2 * PI * dX;
  // The eastings are then the fraction of this circumference.
  // Check for crossing the -180 / +180 divide
  if (abs(dToLongitudeB - dFromLongitudeA) < 180) then
    dEastings := dSameLatCircum * (dToLongitudeB - dFromLongitudeA) / 360.0
  else
    if (dToLongitudeB > dFromLongitudeA) then
      dEastings := dSameLatCircum * (dToLongitudeB - dFromLongitudeA - 360) / 360.0
    else
      dEastings := dSameLatCircum * (dToLongitudeB - dFromLongitudeA + 360) / 360.0;

  // To determine the northings along the surface of the earth, I determine the distance
  // from the centre of the earth to the surface at the given latitude.
  dEarthCentreToSurface := Sqrt(dX*dX + dY*dY);
  // Assume that the surface of the earth at that latitude is then a circle of this radius.
  // Northings are then calculated as a fraction of the circumference.
  dSameLongCircum := 2 * PI * dEarthCentreToSurface;
  dNorthings := dSameLongCircum * (dToLatitudeB - dFromLatitudeA) / 360.0;
end; // RoughDeltaLL2NE

//***************************************************************************
//
//  FUNCTION  : radiusEarth
//
//  I/P       : latitude : Double - the latitude at which the radius is
//              required
//
//  O/P       : Double - the radius at the given latitude, in metres
//
//  OPERATION : Get the radius of the earth at a given latitude
//
//  UPDATED   : 2023-01-24
//
//***************************************************************************
function radiusEarth(latitude : Double) : Double;
var
  dX, dY : Double;

begin
  // Slice the earth through the longitude and longitude+180 to get an elipse.
  // The N/S axis is the Y axis, and from surface to surface at the equator is the X-axis.
  // Then the equation for the elipse is
  //          X = (radius at equator) * cos(latitude)
  //          Y = (radius at poles) * sin(latitude)
  dX := SEMI_MAJOR_AXIS[iDatumToUse] * cos(latitude * PI / 180.0);
  dY := SEMI_MINOR_AXIS[iDatumToUse] * sin(latitude * PI / 180.0);

  // Northings is the distance along the surface of the earth.  Determine the distance
  // from the centre of the earth to the surface at the given latitude.
  Result := Sqrt(dX*dX + dY*dY);
end;

//***************************************************************************
//
//  FUNCTION    :   RoughLLNE2LL
//
//  I/P         :   dFromLatitude (double) - Latitude of the starting
//                    point in decimal degrees.
//
//                  dFromLongitude (double) - Longitude of the starting
//                    point in decimal degrees.
//
//                  dNorthings (double) - The distance moved north (positive)
//
//                  dEastings (double) - The distance moved east (positive)
//
//  O/P         :   dToLatitude (double) - Latitude of the finishing
//                    point in decimal degrees.
//
//                  dToLongitude (double) - Longitude of the finishing
//                    point in decimal degrees.
//
//  OPERATION   :   Determine the latitude and longitude of a destination
//                  given the starting lat/long and the northings/eastings
//                  in metres.   This algorithm reverses the algorithm in
//                  RoughDeltaLL2NE, above.
//
//                  This algorithm suffers because it takes the radius from
//                  the centre of the earth at the dFromLatitude point, whereas
//                  it should somehow work out the true radius over the displacement.
//                  (Above we used the average radius at the two latitude points)
//
//  UPDATED     :   2005/04/28
//
//***************************************************************************
procedure RoughLLNE2LL(dFromLatitude,dFromLongitude : Double;
                       dNorthings,dEastings : Double;
                       var dToLatitude,dToLongitude : double);
var
  dX, dY : Double;
  dSameLatCircum : Double;
  dEarthCentreToSurface : Double;
  dSameLongCircum : Double;

begin
  // Slice the earth through the longitude and longitude+180 to get an elipse.
  // The N/S axis is the Y axis, and from surface to surface at the equator is the X-axis.
  // Then the equation for the elipse is
  //          X = (radius at equator) * cos(latitude)
  //          Y = (radius at poles) * sin(latitude)
  dX := SEMI_MAJOR_AXIS[iDatumToUse] * cos(dFromLatitude * PI / 180.0);
  dY := SEMI_MINOR_AXIS[iDatumToUse] * sin(dFromLatitude * PI / 180.0);

  // Northings is the distance along the surface of the earth.  Determine the distance
  // from the centre of the earth to the surface at the given latitude.
  dEarthCentreToSurface := Sqrt(dX*dX + dY*dY);
  // Assume that the surface of the earth at that latitude is then a circle of this radius.
  // Northings are then the arc distance and the change in latitude is the arc angle.
  dSameLongCircum := 2 * PI * dEarthCentreToSurface;
  dToLatitude := dFromLatitude + (dNorthings / dSameLongCircum * 360.0);

  // dX is the radius of the same-latitude circle, centred on the N/S axis.
  // Determine the circumference of that same latitude cicle.
  dSameLatCircum := 2 * PI * dX;
  // Eastings are then the arc distance and the change in longitude is the arc angle.
  dToLongitude := dFromLongitude + (dEastings / dSameLatCircum * 360.0);
  // Check for crossing the -180 / +180 divide
  if (dToLongitude > 180.0) then
    dToLongitude := dToLongitude - 360.0
  else
    if (dToLongitude <= -180.0) then
      dToLongitude := dToLongitude + 360.0;
end; // RoughLLNE2LL
(*
//***************************************************************************
//
//  FUNCTION    :   RoughLLBD2LL
//
//  I/P         :   dFromLatitude (double) - Latitude of the starting
//                    point in decimal degrees.
//
//                  dFromLongitude (double) - Longitude of the starting
//                    point in decimal degrees.
//
//                  dBearing (double) - The true bearing of the new point
//
//                  dDistance (double) - The distance to the new point
//
//  O/P         :   dToLatitude (double) - Latitude of the finishing
//                    point in decimal degrees.
//
//                  dToLongitude (double) - Longitude of the finishing
//                    point in decimal degrees.
//
//  OPERATION   :   Determine the latitude and longitude of a destination
//                  given the starting lat/long and the bearing/distance
//                  in degrees and metres.
//
//                  This algorithm suffers because it takes the radius from
//                  the centre of the earth at the dFromLatitude point, whereas
//                  it should somehow work out the true radius over the displacement.
//                  (Above we used the average radius at the two latitude points)
//
//  UPDATED     :   2006/11/13
//
//***************************************************************************
procedure RoughLLBD2LL(dFromLatitude,dFromLongitude : Double;
                       dBearing,dDistance : Double;
                       var dToLatitude,dToLongitude : double);
var
  dX, dY : Double;
  dSameLatCircum : Double;
  dEarthCentreToSurface : Double;
  dSameLongCircum : Double;

begin

Convert dBearing and dDistance into northings and eastings at this location.

  // Slice the earth through the longitude and longitude+180 to get an elipse.
  // The N/S axis is the Y axis, and from surface to surface at the equator is the X-axis.
  // Then the equation for the elipse is
  //          X = (radius at equator) * cos(latitude)
  //          Y = (radius at poles) * sin(latitude)
  dX := SEMI_MAJOR_AXIS_WGS84 * cos(dFromLatitude * PI / 180.0);
  dY := SEMI_MINOR_AXIS_WGS84 * sin(dFromLatitude * PI / 180.0);

  // Northings is the distance along the surface of the earth.  Determine the distance
  // from the centre of the earth to the surface at the given latitude.
  dEarthCentreToSurface := Sqrt(dX*dX + dY*dY);
  // Assume that the surface of the earth at that latitude is then a circle of this radius.
  // Northings are then the arc distance and the change in latitude is the arc angle.
  dSameLongCircum := 2 * PI * dEarthCentreToSurface;
  dToLatitude := dFromLatitude + (dNorthings / dSameLongCircum * 360.0);

  // dX is the radius of the same-latitude circle, centred on the N/S axis.
  // Determine the circumference of that same latitude cicle.
  dSameLatCircum := 2 * PI * dX;
  // Eastings are then the arc distance and the change in longitude is the arc angle.
  dToLongitude := dFromLongitude + (dEastings / dSameLatCircum * 360.0);
  // Check for crossing the -180 / +180 divide
  if (dToLongitude > 180.0) then
    dToLongitude := dToLongitude - 360.0
  else
    if (dToLongitude <= -180.0) then
      dToLongitude := dToLongitude + 360.0;

end; // RoughLLBD2LL
*)
//*******************************************************************
//  Description: Latitude-Longitide-Altitude TO XYZ
//               Earth-Centred
//  Author:      Sam Storm van Leeuwen
//               Nico Bestbier
//  Date:        2002/10/03
//  Status:      Tested
//*******************************************************************
procedure EC_LLA2XYZ(Xi : vec3; var Xo : vec3);
var
  N: double;
begin
  N := SEMI_MAJOR_AXIS[iDatumToUse] / sqrt(1.0 - dE1Sqr * sin(Xi[1]) * sin(Xi[1]));

  Xo[1] := (N                 + Xi[3]) * cos(Xi[1]) * cos(Xi[2]);
  Xo[2] := (N                 + Xi[3]) * cos(Xi[1]) * sin(Xi[2]);
  Xo[3] := (N * (1.0 - dE1Sqr) + Xi[3]) * sin(Xi[1]);
end;

//*******************************************************************
//  Description: XYZ TO Latitude-Longitude-Altitude
//               Earth-Centred
//  Author:      Sam Storm van Leeuwen
//               Nico Bestbier
//  Date:        2002/10/03
//  Status:      Tested
//*******************************************************************
procedure EC_XYZ2LLA(Xi: vec3; var Xo: vec3);
var
  p, T, sT, cT, N, sig: double;
begin
  p := sqrt(Xi[1] * Xi[1] + Xi[2] * Xi[2]);
  T := arctan((Xi[3] * SEMI_MAJOR_AXIS[iDatumToUse]) / (p * SEMI_MINOR_AXIS[iDatumToUse]));
  sT := sin(T); cT := cos(T);
  Xo[1] := arctan((Xi[3] + dE2Sqr * SEMI_MINOR_AXIS[iDatumToUse] * sT * sT * sT) /
                  (p - dE1Sqr * SEMI_MAJOR_AXIS[iDatumToUse] * cT * cT * cT));

  if Xi[2] <> 0.0 then
    sig := Xi[2] / abs(Xi[2])
  else
    sig := 1.0;

  if Xi[1] = 0.0 then
     Xo[2] := sig * pi / 2.0
  else
  begin
     Xo[2] := arctan(Xi[2]/Xi[1]);
     if ((Xi[1] < 0.0) and (Xi[2] >= 0.0)) then
       Xo[2] := Xo[2] + pi;
     if ((Xi[1] < 0.0) and (Xi[2] < 0.0)) then
       Xo[2] := Xo[2] - pi;
  end; // else

  N := SEMI_MAJOR_AXIS[iDatumToUse] / sqrt(1.0 - dE1Sqr * sin(Xo[1]) * sin(Xo[1]));
  Xo[3] := p / cos(Xo[1]) - N;
end;

//***************************************************************************
//
//  FUNCTION  : GravityAtLatitude
//
//  I/P       : dLatitude (double) - The latitude at which the gravity is
//                required.
//
//  O/P       : (double) - Gravity in m/s2
//
//  OPERATION : Somigliana's equation for normal gravity on the surface of
//              an ellipsoid of revolution.
//
//              reference : A discussion of various measures of altitude
//                www.mtp.jpl.nasa.gov/notes/altitude/altitude.html
//                equation 17
//
//  UPDATED   : 2006/06/02
//
//***************************************************************************
function GravityAtLatitude(dLatitude : double) : Double;
begin
  result := EQUATORIAL_GRAVITY_WGS84 *
            ((1.0 + dSomiglianas * Power(Sin(DegToRad(dLatitude)),2)) /
             (Sqrt(1.0 - dEccentricity*dEccentricity*Power(Sin(DegToRad(dLatitude)),2))));
end; // GravityAtLatitude


//***************************************************************************
//
//  FUNCTION  : Rwgs
//
//  I/P       : dLatitude (double) - The latitude at which Rwgs is
//                required.
//
//  O/P       : (double) - Rwgs
//
//  OPERATION : Return the "effective radius" or "closed-form version of the
//              ficticious radius" of the earth for a given latitude.   This is
//              not the same as the actual radius of the earth.
//
//              reference : A discussion of various measures of altitude
//                www.mtp.jpl.nasa.gov/notes/altitude/altitude.html
//                equation 20
//
//  UPDATED   : 2006/06/05
//
//***************************************************************************
function Rwgs(dLatitude : double) : Double;
begin
  result := SEMI_MAJOR_AXIS[iDatumToUse] /
            (1 + dFlattening + dGravityRatio -
             2.0 * dFlattening * Power(Sin(DegToRad(dLatitude)),2.0));
end; // Rwgs

//***************************************************************************
//
//  FUNCTION  : GeometricToGeopotential_1
//
//  I/P       : dGeometric (double) - Geometric altitude in m
//
//              dLatitude (double) - Latitude in degrees
//
//  O/P       : (double) - Geopotential height in gpm
//
//  OPERATION : Converts geometric altitude into geopotential altitude.
//              This function determines gravity and the equivalent radius
//              at the given latitude (and hence involves extra computation)
//
//              Uses Equation (22) in the above document.
//
//  UPDATED   : 2006/06/05
//
//***************************************************************************
function GeometricToGeopotential_1(dGeometric : Double;
                                   dLatitude : double) : Double;
var
  dGravity : Double;
  dRwgs : Double;

begin
  dGravity := GravityAtLatitude(dLatitude);
  dRwgs := Rwgs(dLatitude);
  result := dGravity / GRAVITY45_WMO * dRwgs * dGeometric / (dRwgs + dGeometric);
end; // GeometricToGeopotential_1

//***************************************************************************
//
//  FUNCTION  : GeopotentialToGeometric_1
//
//  I/P       : dGeopotential (double) - Geopotential altitude in gpm
//
//              dLatitude (double) - Latitude in degrees
//
//  O/P       : (double) - Geometric height in m
//
//  OPERATION : Converts geopotential altitude into geometric altitude
//              This function determines gravity and the equivalent radius
//              at the given latitude (and hence involves extra computation)
//
//              Uses Equation (22) in the above document.
//
//  UPDATED   : 2017-01-16
//
//***************************************************************************
function GeopotentialToGeometric_1(dGeopotential : Double;
                                   dLatitude : double) : Double;
var
  dGravity : Double;
  dRwgs : Double;

begin
  dGravity := GravityAtLatitude(dLatitude);
  dRwgs := Rwgs(dLatitude);
  result := dRwgs * dGeopotential / (dGravity / GRAVITY45_WMO * dRwgs - dGeopotential);
end; // GeopotentialToGeometric_1

//***************************************************************************
//
//  FUNCTION  : GeometricToGeopotential_2
//
//  I/P       : dGeometric (double) - Geometric altitude in m
//
//              dGravity (double) - Gravity at the latitude of calculation, in
//                m/s2
//
//              dRwgs (double) - Effective radius (not the actual radius) of
//                the earth at the latitude of calculation, in m.
//
//  O/P       : (double) - Geopotential height in gpm
//
//  OPERATION : Converts geometric altitude into geopotential altitude.
//
//              Uses Equation (22) in the above document.
//
//  UPDATED   : 2006/06/05
//
//***************************************************************************
function GeometricToGeopotential_2(dGeometric : Double;
                                   dGravity : Double;
                                   dRwgs : double) : Double;
begin
  result := dGravity / GRAVITY45_WMO * dRwgs * dGeometric / (dRwgs + dGeometric);
end; // GeometricToGeopotential_2

//***************************************************************************
//
//  FUNCTION  : GeopotentialToGeometric_2
//
//  I/P       : dGeopotential (double) - Geopotential altitude in gpm
//
//              dGravity (double) - Gravity at the latitude of calculation, in
//                m/s2
//
//              dRwgs (double) - Effective radius (not the actual radius) of
//                the earth at the latitude of calculation, in m.
//
//  O/P       : (double) - Geometric height in m
//
//  OPERATION : Converts geopotential altitude into geometric altitude
//
//              Uses Equation (23) in the above document.
//
//  UPDATED   : 2017-01-16
//
//***************************************************************************
function GeopotentialToGeometric_2(dGeopotential : Double;
                                   dGravity : Double;
                                   dRwgs : double) : Double;
begin
  result := dRwgs * dGeopotential / (dGravity / GRAVITY45_WMO * dRwgs - dGeopotential);
end; // GeopotentialToGeometric_2

//***************************************************************************
//
//  FUNCTION  : DegToDMSHString
//
//  I/P       : dDegrees (double) : Degrees to be converted
//
//              iDegreeDigits (integer) : The number of digits that
//                are required in the degrees potion (front-padded with
//                zeroes)
//
//              iSecondsDecimals (integer) : The number of digits that
//                are required in the decimal portion of the seconds.
//
//              cDegreeChar (char) - The character to be used in the
//                degrees position.   This is typically a '°'
//
//              cPos (char) - The character to add to the end of the
//                string if the value is positive.
//
//              cNeg (char) - The character to add to the end of the
//                string if the value is negative.
//
//
//  O/P       : (string)
//
//  OPERATION : Converts a given decimal degrees value into the
//              representative degrees, minutes, decimal seconds and
//              hemisphere string.
//
//  UPDATED   : 2004/10/15
//
//***************************************************************************
function DegToDMSHString(dDegrees : Double;
                         iDegreesDigits : Integer;
                         iSecondsDecimals : Integer;
                         cDegreeChar : char;
                         cPos : char;
                         cNeg : char) : String;
var
  iDegrees : Integer;
  iMinutes : Integer;
  dSeconds : Double;
  iSecondsDecSpace : Integer;
begin
// Get the hemisphere indicators
  if (dDegrees >= 0.0) then
    result := cPos
  else
    result := cNeg;

// Determine the field width of the seconds
  if (iSecondsDecimals>0) then
    iSecondsDecSpace := iSecondsDecimals + 1
  else
    iSecondsDecSpace := 0;

  dDegrees := abs(dDegrees);
  DegToDMS(dDegrees,iDegrees,iMinutes,dSeconds);

  result := Front_Padded(IntToStr(iDegrees),'0',iDegreesDigits) + cDegreeChar +
            Front_Padded(IntToStr(iMinutes),'0',2) + '''' +
            Front_Padded(FloatToStrF(dSeconds,ffFixed,15,iSecondsDecimals),'0',2 + iSecondsDecSpace) + '"' +
            result;
end; // DegToDMSHString

//***************************************************************************
//
//  FUNCTION  : DegToDMHString
//
//  I/P       : dDegrees (double) : Degrees to be converted
//
//              iDegreeDigits (integer) : The number of digits that
//                are required in the degrees potion (front-padded with
//                zeroes)
//
//              iMinutesDecimals (integer) : The number of digits that
//                are required in the decimal portion of the minutes.
//
//              cDegreeChar (char) - The character to be used in the
//                degrees position.   This is typically a '°'
//
//              cPos (char) - The character to add to the end of the
//                string if the value is positive.
//
//              cNeg (char) - The character to add to the end of the
//                string if the value is negative.
//
//  O/P       : (string)
//
//  OPERATION : Converts a given decimal degrees value into the
//              representative string of degrees, decimal minutes and
//              hemisphere.
//
//  UPDATED   : 2006/11/07
//
//***************************************************************************
function DegToDMHString(dDegrees : Double;
                        iDegreesDigits : Integer;
                        iMinutesDecimals : Integer;
                        cDegreeChar : char;
                        cPos : char;
                        cNeg : char) : String;
var
  iDegrees : Integer;
  dMinutes : Double;
  iMinutesDecSpace : Integer;
begin
  // Get the hemisphere indicators
  if (dDegrees >= 0.0) then
    result := cPos
  else
    result := cNeg;

  // Determine the field width of the minutes
  if (iMinutesDecimals>0) then
    iMinutesDecSpace := iMinutesDecimals + 1
  else
    iMinutesDecSpace := 0;

  iDegrees := Trunc(Abs(dDegrees));
  dMinutes := (Abs(dDegrees) - iDegrees) * 60.0;

  result := Front_Padded(IntToStr(iDegrees),'0',iDegreesDigits) + cDegreeChar +
            Front_Padded(FloatToStrF(dMinutes,ffFixed,15,iMinutesDecimals),'0',2 + iMinutesDecSpace) + '''' +
            result;
end; // DegToDMHString

//***************************************************************************
//
//  FUNCTION  : DegToDHString
//
//  I/P       : dDegrees (double) : Degrees to be converted
//
//              iDegreeDigits (integer) : The number of digits that
//                are required in the degrees potion (front-padded with
//                zeroes)
//
//              iDegreesDecimals (integer) : The number of digits that
//                are required in the decimal portion of the degrees.
//
//              cDegreeChar (char) - The character to be used in the
//                degrees position.   This is typically a '°'.
//
//              cPos (char) - The character to add to the end of the
//                string if the value is positive.
//
//              cNeg (char) - The character to add to the end of the
//                string if the value is negative.
//
//  O/P       : (string)
//
//  OPERATION : This function returns the string of a decimal Degrees
//              value, formatted to required field widths, and including
//              a hemisphere indicator, for a given degrees value.
//
//  UPDATED   : 2006/11/07
//
//***************************************************************************
function DegToDHString(dDegrees : Double;
                       iDegreesDigits : Integer;
                       iDegreesDecimals : Integer;
                       cDegreeChar : char;
                       cPos : char;
                       cNeg : char) : String;
var
  iDegreesDecSpace : Integer;
begin
  // Get the hemisphere indicators
  if (dDegrees >= 0.0) then
    result := cPos
  else
    result := cNeg;

  // Determine the field width of the degrees
  if (iDegreesDecimals>0) then
    iDegreesDecSpace := iDegreesDecimals + 1
  else
    iDegreesDecSpace := 0;

  dDegrees := Abs(dDegrees);

  result := Front_Padded(FloatToStrF(dDegrees,ffFixed,15,iDegreesDecimals),'0',iDegreesDigits + iDegreesDecSpace) +
            cDegreeChar +
            result;
end; // DegToDHString


//***************************************************************************
//
//  FUNCTION  : LL2UTMNorthEast
//
//  I/P       : dLatitude (double) - The latitude of the point to be
//                converted.
//
//              dLongitude (double) - The longitude of the point to be
//                converted.
//
//              dLong0 (double) - The central longitude meridian of the zone
//
//  O/P       :
//
//  OPERATION : See http://www.uwgb.edu/dutchs/UsefulData/UTMFormulas.HTM
//
//  UPDATED   :
//
//***************************************************************************
procedure LL2UTMNorthEast(dLatitude, dLongitude : Double;
                          dLong0 : Double;
                          var dNorthing : Double;
                          var dEasting : double);
var
  dLat : Double;              // Latitude of point
//  dRho : Double;
  dS : Double;
  dNu : Double;
  dP : Double;
  dK1 : Double;
  dK2 : Double;
  dK3 : Double;
  dK4 : Double;
  dK5 : Double;

begin
  dLat := DegToRad(dLatitude);

  dP := (dLongitude - dLong0) * 3600.0;

  // Central meridian of zone
//  dLong0 := DegToRad(dLong0);

  // This is the radius of curvature of the earth in the meridian plane.
//  dRho := (a * (1-dE*dE)) / Power((1-dE*dE*sin(dLat)*sin(dLat)),1.5);

  // This is the radius of curvature of the earth perpendicular to the meridian plane.
  // It is also the distance from the point in question to the polar axis, measured
  // perpendicular to the earth's surface.
  dNu := SEMI_MAJOR_AXIS[iDatumToUse] / Power((1-dE*dE*sin(dLat)*sin(dLat)),0.5);

  // Calculate the Meridional Arc
  // dS is the meridional arc through the point in question (the distance along the
  // earth's surface from the equator). All angles are in radians.
  dS := (dAPrime * dLat) -
        (dBPrime * sin(2 * dLat)) +
        (dCPrime * sin(4 * dLat)) -
        (dDPrime * sin(6 * dLat)) +
        (dEPrime * sin(8 * dLat));

  // Northings
  dK1 := dS * K0;
  dK2 := K0 * Power(dSine1Second,2) * dNu * sin(dLat) * cos(dLat)/2;
  dK3 := (K0 * Power(dSine1Second,4) * dNu * sin(dLat) * Power(cos(dLat),3) / 24) *
         (5
          - Power(tan(dLat),2)
          + 9 * dEPrimeSquared * Power(cos(dLat),2)
          + 4 * Power(dEPrimeSquared,2) * Power(cos(dLat),4));

  dNorthing := dK1 +
              dK2 * Power(dP,2) +
              dK3 * Power(dP,4);

  // Eastings
  dK4 := K0 * dSine1Second * dNu * cos(dLat);
  dK5 := (K0 * Power(dSine1Second,3) * dNu * Power(cos(dLat),3) / 6) *
         (1
          - Power(tan(dLat),2)
          + dEPrimeSquared * Power(cos(dLat),2));
  dEasting := dK4 * dP +
              dK5 * Power(dP,3);
end; // LL2UTMNorthEast

//***************************************************************************
//
//  FUNCTION  : GetUTMGrid
//
//  I/P       : dLatitude (double) - Decimal latitude of the location
//
//              dLongitude (double) - Decimal longitude of the location
//
//  O/P       : sGrid (string) -
//
//              dCentralMeridian (double) - the longitudinal meridian from which
//                the eastings are to be calculated.
//
//  OPERATION : UTM longitude zone
//              The UTM system divides the surface of the Earth between 80° S
//              latitude and 84° N latitude into 60 zones, each 6° of longitude
//              in width and centered over a meridian of longitude. Zones are
//              numbered from 1 to 60. Zone 1 is bounded by longitude 180° to
//              174° W and is centered on the 177th West meridian. Zone numbering
//              increases in an easterly direction.
//
//              Each of the 60 longitude zones in the UTM system is based on a
//              Transverse Mercator projection, which is capable of mapping a
//              region of large north-south extent with a low amount of distortion.
//              By using narrow zones of 6° in width, and reducing the scale factor
//              along the central meridian to 0.9996, (a reduction of 1:2500) the
//              amount of distortion is held below 1 part in 1,000 inside each zone.
//              Distortion of scale increases to 1.0010 at the outer zone boundaries
//              along the equator.
//
//              The reduction in the scale factor along the central meridian
//              creates two lines of true scale located approximately 180 km on
//              either side of, and approximately parallel to, the central
//              meridian. The scale factor is too small inside these lines and
//              too large outside of these lines, but the overall distortion
//              scale inside the entire zone is minimized.
//
//              UTM latitude zone
//              The UTM system segments each longitude zone into 20 latitude
//              zones. Each latitude zone is 8 degrees high, and is lettered
//              starting from "C" at 80° S, increasing up the English alphabet
//              until "X", omitting the letters "I" and "O" (because of their
//              similarity to the digits one and zero). The last latitude zone,
//              "X", is extended an extra 4 degrees, so it ends at 84° N latitude,
//              thus covering the northern most land on Earth. Latitude zones "A"
//              and "B" do exist, as do zones "Y" and Z". They cover the western
//              and eastern sides of the Antarctic and Arctic regions respectively.
//              A convenient trick to remember is that the letter "N" is the first
//              letter in the northern hemisphere, so any letter coming before "N"
//              in the alphabet is in the southern hemisphere, and any letter "N"
//              or after is in the northern hemisphere.
//
//              Notation
//              Each grid square is referred to by the longitude zone number and
//              the latitude zone character. The longitude zone is always written
//              first, followed by the latitude zone. For example, a position in
//              Toronto, Canada, would find itself in longitude zone 17 and latitude
//              zone "T", thus the full reference is "17T".
//
//              Exceptions
//              These longitude and latitude zones are uniform over the globe,
//              except in two areas. On the southwest coast of Norway, the UTM
//              zone 32V is extended further west, and the zone 31V is
//              correspondingly shrunk to cover only open water. Also, in the
//              region around Svalbard, the longitude zones are given double
//              their normal width.
//
//  UPDATED   : 2007/02/06
//
//***************************************************************************
procedure GetUTMGrid(dLatitude : Double;
                     dLongitude : Double;
                     var sGrid : String;
                     var dCentralMeridian : double);
const
  acLatZones : array[0..19] of char = ('C','D','E','F','G',
                                       'H','J','K','L','M',
                                       'N','P','Q','R','S',
                                       'T','U','V','W','X');
var
  x,y : Integer;
begin
  if (dLatitude < -80.0) then
  begin
    // Antarctic
    if (dLongitude < 0.0) then
    begin
      sGrid := 'A';
      dCentralMeridian := -90.0;
    end // if
    else
    begin
      sGrid := 'B';
      dCentralMeridian := 90.0;
    end // if
  end // if
  else
    if (dLatitude > 84.0) then
    begin
      // Arctic
      if (dLongitude < 0.0) then
      begin
        sGrid := 'Y';
        dCentralMeridian := -90.0;
      end // if
      else
      begin
        sGrid := 'Z';
        dCentralMeridian := 90.0;
      end // if
    end // if
    else
    begin
      // Normal Latitudes
      // Longitude block
      x := Min(Trunc((dLongitude + 180.0) / 6.0),59) + 1;
      // Latitude block
      y := Min(Trunc((dLatitude + 80.0) / 8.0),19);
      sGrid := Front_Padded(IntToStr(x),'0',2) + acLatZones[y];
      dCentralMeridian := ((x-1.0) * 6.0) + 3.0 - 180.0;
      //Exceptions
      if ((y = 18) and (x = 31) and (dLongitude > 3.0)) then
      begin
        // Off the west coast of Norway, grid block 32V is extended halfway into 31V
        sGrid := '32V';
        dCentralMeridian := 9.0;
      end // if
      else
        if (y = 20) then
        begin
          if (x = 32) then
          begin
            if (dLongitude < 9.0) then
            begin
              // 32X does not exist.   It's western half is taken by 31X
              sGrid := '31X';
              dCentralMeridian := 3.0;
            end // if
            else
            begin
              // 32X does not exist.   It's eastern half is taken by 33X
              sGrid := '33X';
              dCentralMeridian := 9.0;
            end; // else
          end // if
          else
            if (x = 34) then
            begin
              if (dLongitude < 15.0) then
              begin
                // 34X does not exist.   It's western half is taken by 33X
                sGrid := '33X';
                dCentralMeridian := 9.0;
              end // if
              else
              begin
                // 34X does not exist.   It's eastern half is taken by 35X
                sGrid := '35X';
                dCentralMeridian := 27.0;
              end; // else
            end // if
            else
              if (x = 36) then
              begin
                if (dLongitude < 33.0) then
                begin
                  // 36X does not exist.   It's western half is taken by 35X
                  sGrid := '35X';
                  dCentralMeridian := 27.0;
                end // if
                else
                begin
                  // 36X does not exist.   It's eastern half is taken by 37X
                  sGrid := '37X';
                  dCentralMeridian := 39.0;
                end; // else
              end; // if
        end; // if
    end; // else
end; // GetUTMGrid

//***************************************************************************
//
//  FUNCTION  : GetBTMGrid
//
//  I/P       : dLatitude (double) - Decimal latitude of the location
//
//              dLongitude (double) - Decimal longitude of the location
//
//  O/P       : sGrid (string) -
//
//              dCentralMeridian (double) - the longitudinal meridian from which
//                the eastings are to be calculated.
//
//  OPERATION : BTM longitude zone
//              Bangladesh TM version of UTM.
//              See the description of UTM Gride, above and also
//                http://ahasanulhoque.com/752-2/
//                http://socolzahid-en.blogspot.co.za/2012/07/bangladesh-transverse-mercator-btm.html
//
//              Exceptions
//              These longitude and latitude zones are uniform over the globe,
//              except in two areas. On the southwest coast of Norway, the UTM
//              zone 32V is extended further west, and the zone 31V is
//              correspondingly shrunk to cover only open water. Also, in the
//              region around Svalbard, the longitude zones are given double
//              their normal width.
//
//  UPDATED   : 2007/02/06
//
//***************************************************************************
procedure GetBTMGrid(dLatitude : Double;
                     dLongitude : Double;
                     var sGrid : String;
                     var dCentralMeridian : double);
const
  acLatZones : array[0..19] of char = ('C','D','E','F','G',
                                       'H','J','K','L','M',
                                       'N','P','Q','R','S',
                                       'T','U','V','W','X');
var
  x,y : Integer;
begin
  if (dLatitude < -80.0) then
  begin
    // Antarctic
    if (dLongitude < 0.0) then
    begin
      sGrid := 'A';
      dCentralMeridian := -90.0;
    end // if
    else
    begin
      sGrid := 'B';
      dCentralMeridian := 90.0;
    end // if
  end // if
  else
    if (dLatitude > 84.0) then
    begin
      // Arctic
      if (dLongitude < 0.0) then
      begin
        sGrid := 'Y';
        dCentralMeridian := -90.0;
      end // if
      else
      begin
        sGrid := 'Z';
        dCentralMeridian := 90.0;
      end // if
    end // if
    else
    begin
      // Normal Latitudes
      // Longitude block
      x := Min(Trunc((dLongitude + 180.0) / 6.0),59) + 1;
      // Latitude block
      y := Min(Trunc((dLatitude + 80.0) / 8.0),19);
      sGrid := Front_Padded(IntToStr(x),'0',2) + acLatZones[y];
      dCentralMeridian := ((x-1.0) * 6.0) + 3.0 - 180.0;
      //Exceptions
      if ((y = 18) and (x = 31) and (dLongitude > 3.0)) then
      begin
        // Off the west coast of Norway, grid block 32V is extended halfway into 31V
        sGrid := '32V';
        dCentralMeridian := 9.0;
      end // if
      else
        if (y = 20) then
        begin
          if (x = 32) then
          begin
            if (dLongitude < 9.0) then
            begin
              // 32X does not exist.   It's western half is taken by 31X
              sGrid := '31X';
              dCentralMeridian := 3.0;
            end // if
            else
            begin
              // 32X does not exist.   It's eastern half is taken by 33X
              sGrid := '33X';
              dCentralMeridian := 9.0;
            end; // else
          end // if
          else
            if (x = 34) then
            begin
              if (dLongitude < 15.0) then
              begin
                // 34X does not exist.   It's western half is taken by 33X
                sGrid := '33X';
                dCentralMeridian := 9.0;
              end // if
              else
              begin
                // 34X does not exist.   It's eastern half is taken by 35X
                sGrid := '35X';
                dCentralMeridian := 27.0;
              end; // else
            end // if
            else
              if (x = 36) then
              begin
                if (dLongitude < 33.0) then
                begin
                  // 36X does not exist.   It's western half is taken by 35X
                  sGrid := '35X';
                  dCentralMeridian := 27.0;
                end // if
                else
                begin
                  // 36X does not exist.   It's eastern half is taken by 37X
                  sGrid := '37X';
                  dCentralMeridian := 39.0;
                end; // else
              end; // if
        end; // if
    end; // else
end; // GetBTMGrid

//***************************************************************************
//
//  FUNCTION  : LatLong2UTM
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Determines first the grid and datum longitude, then the
//              northings and eastings from the datum longitude.   Eastings
//              is offset by 500000 to keep it positive.
//
//  UPDATED   : 2007/02/06
//
//***************************************************************************
procedure LatLong2UTM(dLatitude : Double;
                      dLongitude : Double;
                      var sGrid : String;
                      var dNorthings : Double;
                      var dEastings : double);
var
  dDatumLong : Double;
begin
  GetUTMGrid(dLatitude,dLongitude,sGrid,dDatumLong);
  LL2UTMNorthEast(dLatitude, dLongitude,
                  dDatumLong,
                  dNorthings, dEastings);
  if (dLatitude < 0.0) then
    dNorthings := dNorthings + 10000000.0;
  dEastings := dEastings + 500000.0;
end; // LatLong2UTM

//***************************************************************************
//
//  FUNCTION  : UTMNorthEast2LL
//
//  I/P       : dNorthing (double) - Signed north offset from equator (+ve
//                means north of the equator)
//
//              dEasting (double) - Signed east offset from central meridian
//                (+ve means east of the meridian)
//
//              dLong0 (double) - the central longitudinal meridian.
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2007/02/07
//
//***************************************************************************
procedure UTMNorthEast2LL(dNorthing : Double;
                          dEasting : Double;
                          dLong0 : Double;
                          var dLatitude : Double;
                          var dLongitude : double);
var
  dMu : Double;
  dS : Double;
  dJ1,dJ2,dJ3,dJ4 : Double;
  dFP : Double;
  dD : Double;
  dC1,dN1,dT1,dR1 : Double;
  dQ1,dQ2,dQ3,dQ4,dQ5,dQ6,dQ7 : Double;
begin
  // Calculate the Meridional Arc length
  // dS is the meridional arc through the point in question (the distance along the
  // earth's surface from the equator). All angles are in radians.
  dS := dNorthing / K0;

  // Calculate the Foorprint Latitude
  dMu := dS / (SEMI_MAJOR_AXIS[iDatumToUse] *
               (1 - Power(dEccentricity,2)/4 - 3 * Power(dEccentricity,4)/64 - 5 * Power(dEccentricity,6)/256));

  dJ1 := 3.0 * dE1/2.0 - 27.0 * Power(dE1,3.0)/32.0;
  dJ2 := 21.0 * Power(dE1,2.0)/16.0 - 55 * Power(dE1,4.0)/32.0;
  dJ3 := 151.0 * Power(dE1,3.0)/96.0;
  dJ4 := 1097 * Power(dE1,4.0)/512.0;
  dFP := dMu + dJ1*Sin(2*dMu) + dJ2*Sin(4*dMu) + dJ3*Sin(6*dMu) + dJ4*Sin(8*dMu);

  // Calculate the latitude and longitude
  dC1 := dEPrimeSquared * Power(Cos(dFP),2.0);
  dT1 := Power(Tan(dFP),2.0);
  dN1 := SEMI_MAJOR_AXIS[iDatumToUse] / Sqrt(1.0 - Power((dEccentricity *Sin(dFP)),2.0));
  dR1 := SEMI_MAJOR_AXIS[iDatumToUse] *
         (1.0 - dEccentricity*dEccentricity) /
         Power(1.0 - Power(dEccentricity*SIN(dFP),2.0),3.0/2.0);
  dD := dEasting / (dN1 * K0);

  dQ1 := dN1 * Tan(dFP) / dR1;
  dQ2 := dD * dD / 2.0;
  dQ3 := (5.0 + 3.0*dT1 + 10.0*dC1 - 4*dC1*dC1 - 9 * dEPrimeSquared) *
         Power(dD,4.0) / 24.0;
  dQ4 := (61.0 + 90.0*dT1 + 298.0*dC1 + 45.0*dT1*dT1 - 3.0*dC1*dC1 - 252.0 * dEPrimeSquared) *
         Power(dD,6.0) / 720.0;
  dLatitude := RadToDeg(dFP - dQ1 * (dQ2 - dQ3 + dQ4));

  dQ5 := dD;
  dQ6 := (1.0 + 2.0*dT1 + dC1) * Power(dD,3.0) / 6.0;
  dQ7 := (5.0 - 2.0*dC1 + 28.0*dT1 - 3.0*dC1*dC1 + 8.0*dEPrimeSquared + 24.0 * dT1*dT1) *
         Power(dD,5.0) / 120.0;
  dLongitude := dLong0 + RadToDeg((dQ5 - dQ6 + dQ7) / Cos(dFP));
end; // UTMNorthEast2LL

//***************************************************************************
//
//  FUNCTION  : GetUTMDatum
//
//  I/P       : sGridID : The UTM grid normally xxy where xx is a number 01 to
//                60 and y is a letter.
//
//  O/P       : (double) - The central longitude meridian for this UTM grid
//
//  OPERATION : Determines the central longitude meridain given the grid ID.
//
//              An exception will be raised if values are invalid
//
//  UPDATED   : 2020-11-06
//
//***************************************************************************
function GetUTMDatum(sGridID : string) : Double;
var
  iLongZone : Integer;

begin
  if ((sGridID = 'A') or (sGridID = 'Y')) then
  begin
    result := -90
  end // if
  else if ((sGridID = 'B') or (sGridID = 'Z')) then
  begin
    result := 90
  end // if
  else
  begin
    if ((Length(sGridID) <> 3) or
        (sGridID[3] < 'C') or
        (sGridID[3] > 'X')) then
    begin
      raise Exception.Create('Invalid UTM Grid');
    end; // if

    iLongZone := StrToInt(LeftStr(sGridID,2));
    if ((iLongZone >= 1) and (iLongZone <= 60)) then
    begin
      result := (iLongZone * 6.0) - 183;
    end // if
    else
    begin
      raise Exception.Create('Invalid UTM Grid');
    end;
  end; // else
end; // GetUTMDatum

//***************************************************************************
//
//  FUNCTION  : UTM2LatLong
//
//  I/P       : sGrid (string) - The UTM grid zone ID
//
//              dNorthings (double) - The UTM northings (including the
//                10 000 000 metre offset for the southern hemisphere.)
//
//              dEastings (double) - The UTM eastings (including the
//                500 000 metre offset.)
//
//  O/P       : dLatitude (double) - The determined latitude
//
//              dLongitude (double) - The determined longitude
//
//  OPERATION : See http://www.uwgb.edu/dutchs/UsefulData/UTMFormulas.HTM
//
//  UPDATED   : 2007/02/07
//
//***************************************************************************
procedure UTM2LatLong(sGrid : String;
                      dNorthings : Double;
                      dEastings : Double;
                      var dLatitude : Double;
                      var dLongitude : double);
var
  dDatumLong : Double;
begin
  dDatumLong := GetUTMDatum(sGrid);
  // Check whether the position is in the southern hemisphere
  if (sGrid[Length(sGrid)] < 'N') then
    dNorthings := dNorthings - 10000000.0;
  dEastings := dEastings - 500000;
  UTMNorthEast2LL(dNorthings,dEastings,dDatumLong,
                  dLatitude,dLongitude);
end; // UTM2LatLong

//***************************************************************************
//
//  FUNCTION  : GetConvergenceAngle
//
//  I/P       : latitude, longitude : Double - The given location, in degrees
//
//              centralMeridian : Double - (Optional) The central meridian to
//                be used. If missing, the applicable UTM central meridian is
//                used.
//
//  O/P       : Double - The convergence angle
//
//  OPERATION : Calculate the convergence angle, based on a given or UTM standard
//              central meridian.
//
//              TN = GN + CONV
//              GN = TN - CONV
//
//              Reference :
//              https://goneoutdoors.com/convert-grid-true-north-8264607.html
//              https://www.softdrill.nl/wp-content/download/TNGN_Correction_rev_5.pdf
//
//              The Grid Correction or Convergence (CONV) is the angular difference
//              between True North and Grid North. Grid Correction is expressed
//              as the angular rotation from True North to Grid North, whereby
//              a negative value lies to the West and a positive value to the
//              East of True North.
//
//  UPDATED   : 2020-11-06
//
//***************************************************************************
function GetConvergenceAngle(latitude, longitude : Double;
                             centralMeridian : Double = 999.0) : Double;
var
  grid : String;
  cm : Double;

begin
  if (centralMeridian > 900.0) then
  begin
    GetUTMGrid(latitude, longitude, grid, cm);
  end;
  Result := (cm - latitude) * sin(DegToRad(longitude));
end; // GetConvergenceAngle

//***************************************************************************
//
//  FUNCTION  : NEAltOffset2AzEl
//
//  I/P       : dNorthOffset (double) - The north offset, in metres, from the
//                starting point, to the target.
//
//              dEastOffset (double) - The east offset, in metres, from the
//                starting point, to the target.
//
//              dAltOffset (double) - The altitude offset, in metres, from the
//                starting point, to the target.
//
//  O/P       : dAz (double) - The azimuth bearing, clockwise from north,
//                in degrees, from the starting point to the target.
//
//              dEl (double) - The elevation bearing, above the horizon
//                in degrees, from the starting point to the target.
//
//  OPERATION : Returns the azimuth and elevation bearings (in degrees) to
//              a location that has a given north, east and altitude offset.
//
//  UPDATED   : 2008-10-17
//
//***************************************************************************
procedure NEAltOffset2AzEl(dNorthOffset : Double;
                           dEastOffset : Double;
                           dAltOffset : Double;
                           var dAz : Double;
                           var dEl : double);
var
  dGroundRange : Double;

begin
  // Get the azimuth bearing
  if (dNorthOffset <> 0.0) then
  begin
    dAz := arctan(dEastOffset / dNorthOffset) / PI * 180.0;
    if (dNorthOffset < 0.0) then
      dAz := 180.0 + dAz;
    if (dAz < 0.0) then
      dAz := dAz + 360.0;
  end // if
  else
    if (dEastOffset < 0.0) then
      dAz := 270.0
    else
      if (dEastOffset > 0.0) then
        dAz := 90.0
      else
        dAz := 0.0;

  // Get the ground range and elevation angle
  dGroundRange := Sqrt(Power(dNorthOffset,2) + Power(dEastOffset,2));
  if (dGroundRange <> 0.0) then
    dEl := arctan(dAltOffset/ dGroundRange) / PI * 180.0
  else
    if (dAltOffset > 0.0) then
      dEl := 90.0
    else
      if (dAltOffset < 0.0) then
        dEl := -90.0
      else
        dEl := 0.0;
end; // NEAltOffset2AzEl

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       : dAz (double) - The azimuth bearing, clockwise from north,
//                in degrees, from the starting point to the target.
//
//              dEl (double) - The elevation bearing, above the horizon
//                in degrees, from the starting point to the target.
//
//              dAltOffset (double) - The altitude offset, in metres, from the
//                starting point, to the target.   (Must be positive if the
//                elevation is above the horizon.)
//
//  O/P        : dNorthOffset (double) - The north offset, in metres, from the
//                starting point, to the target.
//
//              dEastOffset (double) - The east offset, in metres, from the
//                starting point, to the target.
//
//  OPERATION : Returns the north and east offset (in metres) from a starting
//              position, given the azimuth, elevation and altitude offset.
//
//              An elevation of 0° will be interpreted to mean no positional offset.
//
//              Invalid values will be interpreted to mean no positional offset
//
//  UPDATED   : 2011-04-18
//
//***************************************************************************
procedure AzElAlt2NEOffset(dAzimuth : Double;
                           dElevation : Double;
                           dAltOffset : Double;
                           var dNorthOffset : Double;
                           var dEastOffset : double);
var
  dGroundRange : Double;

begin
  if ((dElevation <> 0.0) or
      ((dElevation > 0.0) and (dAltOffset < 0.0)) or
      ((dElevation < 0.0) and (dAltOffset > 0.0))) then
  begin
    dGroundRange := dAltOffset / arctan(DegToRad(dElevation));
    dNorthOffset := cos(DegToRad(dAzimuth)) * dGroundRange;
    dEastOffset := sin(DegToRad(dAzimuth)) * dGroundRange;
  end // if
  else
  begin
    dNorthOffset := 0.0;
    dEastOffset := 0.0;
  end;

end; // AzElAlt2NEOffset


//***************************************************************************
//
//  FUNCTION  : SetDatumConstants
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Most of these are taken from
//              "A Discussion of Various Measures of Altitude" - a paper by
//              MJ Mahoney, Created: Oct 22, 2001 Last Revision: Oct 20, 2005
//              mtp.mjmahoney.net/www/notes/altitude/altitude.html
//
//  UPDATED   :
//
//***************************************************************************
procedure SetDatumConstants(iNewDatum : integer);
var
  dN : Double;
  dLinearEccentricity : Double;
begin
  iDatumToUse := iNewDatum;

  dFlattening := (SEMI_MAJOR_AXIS[iDatumToUse] - SEMI_MINOR_AXIS[iDatumToUse]) / SEMI_MAJOR_AXIS[iDatumToUse];

  dLinearEccentricity := Sqrt(SEMI_MAJOR_AXIS[iDatumToUse] * SEMI_MAJOR_AXIS[iDatumToUse] -
                              SEMI_MINOR_AXIS[iDatumToUse] * SEMI_MINOR_AXIS[iDatumToUse]);

  dEccentricity := dLinearEccentricity / SEMI_MAJOR_AXIS[iDatumToUse];
  dE1 := (1- Sqrt(1-dEccentricity*dEccentricity))/(1+Sqrt(1-dEccentricity*dEccentricity));

  // This is the eccentricity of the earth's elliptical cross-section.
  dE := SQRT(1-((SEMI_MINOR_AXIS[iDatumToUse]*SEMI_MINOR_AXIS[iDatumToUse])/
                (SEMI_MAJOR_AXIS[iDatumToUse]*SEMI_MAJOR_AXIS[iDatumToUse])));

  dSomiglianas := SEMI_MINOR_AXIS[iDatumToUse] / SEMI_MAJOR_AXIS[iDatumToUse] *
                  POLAR_GRAVITY_WGS84 / EQUATORIAL_GRAVITY_WGS84 - 1;

  dGravityRatio := OMEGA_WGS84*OMEGA_WGS84 *
                   SEMI_MAJOR_AXIS[iDatumtoUse]*SEMI_MAJOR_AXIS[iDatumtoUse] *
                   SEMI_MINOR_AXIS[iDatumToUse] /
                   GM_WGS84;

  // The quantity e' only occurs in even powers so it need only be calculated as e'2.
  dEPrimeSquared := dE*dE / (1 - dE*dE);
  dN := (SEMI_MAJOR_AXIS[iDatumToUse] - SEMI_MINOR_AXIS[iDatumToUse]) /
        (SEMI_MAJOR_AXIS[iDatumToUse] + SEMI_MINOR_AXIS[iDatumToUse]);
  // For the Meridional Arc
  dAPrime := SEMI_MAJOR_AXIS[iDatumToUse] * (1
                                      - dN
                                      + (5/4)*(Power(dN,2) - Power(dN,3))
                                      + (81/64) * (Power(dN,4) - Power(dN,5)));
  dBPrime := (3 * SEMI_MAJOR_AXIS[iDatumToUse] * dN /2) * (1
                                                    - dN
                                                    + (7/8) * (Power(dN,2) - Power(dN,3))
                                                    + (55/64) * (Power(dN,4) - Power(dN,5)));
  dCPrime := (15 * SEMI_MAJOR_AXIS[iDatumToUse] * Power(dN,2)/16) * (1
                                                              - dN
                                                              + (3/4) * (Power(dN,2) - Power(dN,3)));
  dDPrime := (35 * SEMI_MAJOR_AXIS[iDatumtoUse] * Power(dN,3)/48) * (1
                                                              - dN
                                                              + (11/16) * (Power(dN,2) - Power(dN,3)));
  dEPrime := (315 * SEMI_MAJOR_AXIS[iDatumToUse] * Power(dN,4)/51) * (1
                                                               - dN);
  dE1Sqr := (SEMI_MAJOR_AXIS[iDatumToUse]*SEMI_MAJOR_AXIS[iDatumToUse] - SEMI_MINOR_AXIS[iDatumToUse]*SEMI_MINOR_AXIS[iDatumToUse]) /
            (SEMI_MAJOR_AXIS[iDatumToUse]*SEMI_MAJOR_AXIS[iDatumToUse]); // first  numerical eccentricity
  dE2Sqr := (SEMI_MAJOR_AXIS[iDatumToUse]*SEMI_MAJOR_AXIS[iDatumToUse] - SEMI_MINOR_AXIS[iDatumToUse]*SEMI_MINOR_AXIS[iDatumToUse]) /
            (SEMI_MINOR_AXIS[iDatumToUse]*SEMI_MINOR_AXIS[iDatumToUse]); // second  numerical eccentricity

end;

//***************************************************************************
//
//  FUNCTION   :  GetEarthOctant
//
//  I/P        :
//
//  O/P        :
//
//  OPERATION  :  Determine the Octant of the globe, given the
//                  longitude and latitude.
//
//  UPDATED    :  2004/10/27
//
//***************************************************************************
function GetEarthOctant(dLatitude : Double;
                        dLongitude : double) : Integer;
var
  dAbsLong : Double;
begin
  if (dLatitude > 0.0) then
  begin
    // In the Northern Hemisphere
    if (dLongitude > 0.0) then
    begin
      // North East
      dAbsLong := abs(dLongitude);
      if ((dAbsLong>=0) and (dAbsLong<=90.0)) then
        result := 3
      else
        result := 2;
    end // if
    else
    begin
      // North West
      dAbsLong := abs(dLongitude);
      if ((dAbsLong>=0) and (dAbsLong<=90.0)) then
        result := 0
      else
        result := 1;
    end; // else
  end // if
  else
  begin
    // In the Southern Hemisphere
    if (dLongitude > 0.0) then
    begin
      // South East
      dAbsLong := abs(dLongitude);
      if ((dAbsLong>=0) and (dAbsLong<=90.0)) then
        result := 8
      else
        result := 7;
    end // if
    else
    begin
      // South West
      dAbsLong := abs(dLongitude);
      if ((dAbsLong>=0) and (dAbsLong<=90.0)) then
        result := 5
      else
        result := 6;
    end;
  end;
end; // GetEarthOctant

//***************************************************************************
//
//  FUNCTION  : LatitudeToText
//
//  I/P       : degrees : Double - The latitude to be converted.
//
//              idFormat : Integer = ID_DEG_DECIMAL - the output format
//
//              decimalPlaces : Integer = 6 - The number of decimal places in
//                the least significan element.
//
//  O/P       : String - The formatted output
//
//  OPERATION : Provide a string representation of a given latitude value
//
//  UPDATED   : 2021-03-16
//
//***************************************************************************
function LatitudeToText(degrees : Double;
                        idFormat : Integer = ID_DEG_DECIMAL;
                        decimalPlaces : Integer = 6) : String;
var
  ad : Double;

begin
  if (degrees < INVALID_TEST) then
  begin
    ad := Abs(degrees);

    case idFormat of
      ID_DEG_DM_DECIMAL :
      begin
        // Degrees and decimal minutes
        Result := Format('%.0f', [Int(ad)]) + '°' +
                  Format('%*.*f', [1, decimalPlaces, Frac(ad)*60.0]) + ''' ';
      end; // option

      ID_DEG_DMS :
      begin
        // Degrees, minutes and decimal seconds
        Result := Format('%.0f',[Int(ad)]) + '°';
        ad := Frac(ad) * 60;
        Result := Result +
          Format('%.0f', [Int(ad)]) + '''' +
          Format('%*.*f',[1, decimalPlaces, Frac(ad)*60.0]) + '" ';
      end; // option

      else
      begin
        // Decimal degrees
        Result := Format('%*.*f',[1, decimalPlaces, ad]) + '° ';
      end;
    end;

    if (degrees >= 0.0) then
    begin
{$IFNDEF NO_DKLANG}
      Result := Result + LangManager.ConstantValue['sAbbrNorth'];
{$ELSE}
      Result := Result + 'N';
{$ENDIF}
    end // if
    else
    begin
{$IFNDEF NO_DKLANG}
      Result := Result + LangManager.ConstantValue['sAbbrSouth'];
{$ELSE}
      Result := Result + 'S';
{$ENDIF}
    end; // else
  end // if
  else
  begin
    Result := '';
  end; // else
end; // LatitudeToText

//***************************************************************************
//
//  FUNCTION  : LongitudeToText
//
//  I/P       : degrees : Double - The longitude to be converted.
//
//              idFormat : Integer = ID_DEG_DECIMAL - the output format
//
//              decimalPlaces : Integer = 6 - The number of decimal places in
//                the least significan element.
//
//  O/P       : String - The formatted output
//
//  OPERATION : Provide a string representation of a given latitude value
//
//  UPDATED   : 2021-03-16
//
//***************************************************************************
function LongitudeToText(degrees : Double;
                         idFormat : Integer = ID_DEG_DECIMAL;
                         decimalPlaces : Integer = 6) : String;
var
  ad : Double;

begin
  if (degrees < INVALID_TEST) then
  begin
    ad := Abs(degrees);

    case idFormat of
      ID_DEG_DM_DECIMAL :
      begin
        // Degrees and decimal minutes
        Result := Format('%.0f', [Int(ad)]) + '°' +
                  Format('%*.*f', [1, decimalPlaces, Frac(ad)*60.0]) + ''' ';
      end; // option

      ID_DEG_DMS :
      begin
        // Degrees, minutes and decimal seconds
        Result := Format('%.0f',[Int(ad)]) + '°';
        ad := Frac(ad) * 60;
        Result := Result +
          Format('%.0f', [Int(ad)]) + '''' +
          Format('%*.*f',[1, decimalPlaces, Frac(ad)*60.0]) + '" ';
      end; // option

      else
      begin
        // Decimal degrees
        Result := Format('%*.*f',[1, decimalPlaces, ad]) + '° ';
      end;
    end;

    if (degrees >= 0.0) then
    begin
{$IFNDEF NO_DKLANG}
      Result := Result + LangManager.ConstantValue['sAbbrEast'];
{$ELSE}
      Result := Result + 'E';
{$ENDIF}
    end // if
    else
    begin
{$IFNDEF NO_DKLANG}
      Result := Result + LangManager.ConstantValue['sAbbrWest'];
{$ELSE}
      Result := Result + 'W';
{$ENDIF}
    end; // else
  end // if
  else
  begin
    Result := '';
  end; // else
end; // LongitudeToText

//***************************************************************************
//
//  FUNCTION  : CompassDirections8
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION :
//
//  UPDATED   : 2021-10-06
//
//***************************************************************************
function CompassDirections8(id : Integer) : String;
begin
  case id of
{$IFNDEF NO_DKLANG}
    COMPASS_DIR_8_N : Result := LangManager.ConstantValue['sNorth'];
    COMPASS_DIR_8_NE : Result := LangManager.ConstantValue['sNorthEast'];
    COMPASS_DIR_8_E : Result := LangManager.ConstantValue['sEast'];
    COMPASS_DIR_8_SE : Result := LangManager.ConstantValue['sSouthEast'];
    COMPASS_DIR_8_S : Result := LangManager.ConstantValue['sSouth'];
    COMPASS_DIR_8_SW : Result := LangManager.ConstantValue['sSouthWest'];
    COMPASS_DIR_8_W : Result := LangManager.ConstantValue['sWest'];
    COMPASS_DIR_8_NW : Result := LangManager.ConstantValue['sNorthWest'];
{$ELSE}
    COMPASS_DIR_8_N : Result := 'North';
    COMPASS_DIR_8_NE : Result := 'North East';
    COMPASS_DIR_8_E : Result := 'East';
    COMPASS_DIR_8_SE : Result := 'South East';
    COMPASS_DIR_8_S : Result := 'South';
    COMPASS_DIR_8_SW : Result := 'South West';
    COMPASS_DIR_8_W : Result := 'West';
    COMPASS_DIR_8_NW : Result := 'North West';
{$ENDIF}
    else
    Result := '';
  end;
end; // CompassDirections8

//***************************************************************************

initialization
begin
  SetDatumConstants(ID_DATUM_WGS84);
  dSine1Second := sin(PI / (180 * 60 * 60));
end; // initialization


end.
