unit MetCalcs;

interface

const
  RDGAS = 287.04;                           // Rd : Gas constant for dry air in J/(kgK) (or 8.314 J/(molK))
  RVGAS = 461.5;                            // Rv : Gas constant for water vapour in J/(kgK)
  SPECH_DA_CP = 1005.7;                     // Cpd : specific heat of dry air at constant pressure in J/(kgK)
  STANDARD_NORMAL_GRAVITY = 9.80665;        // m/s2 Gravitational Constant in m/s2 (WMO) - gn
  ABS_ZEROT = -273.15;                      // Temperature of absolute zero, in degC - To
  STANDARD_SL_PRESSURE = 1013.25;           // International Civil Aviation Organisation ICAO hPa
  STANDARD_SL_TEMPERATURE = 15;             // ICAO (in deg C)
  STANDARD_SL_DENSITY = 1.225;              // ICAO (in kg/m3)
  SMD_STANDARD_SL_PRESSURE = 1000.0;        // 750mmHg is SMD standard
  INITIAL_TLAPSE = 6.5;                     // Initial temperature lapse rate in degC/1000m
  POISSON_CONSTANT_DRY = RDGAS/SPECH_DA_CP; // Poisson constant (typically given the capital Kappa symbol) for dry air

  MAX_TEMPERATURE = 65.0;             // 57.8degC at Al' Aziziyah, Libya, Sept 1922)
  MIN_GROUND_TEMPERATURE = -95.0;     // -89.4degC at Vostok, Antartica, 21 July 1983
  MIN_FLIGHT_TEMPERATURE = -95.0;     // Based on observed InterMet data

function VirtualTemperatureK(dVTPressure : Double;
                             dVTTemperature : Double;
                             dVTHumidity : Double) : Double;
function AirDensity(dADPressure : Double;
                    dADVirtualTemperature : Double) : Double;
function SaturationVapourPressure(dSVPTemperature : Double) : Double;
//function SaturationVapourPressure(dSVPTemperature : Double;
//                                  dSVPPressure : Double) : Double;
function Td_From_VP(dGivenVP : Double) : Double;
function Tf_From_VP(dGivenVP : Double) : Double;
function VapourPressure(dTemperature : Double;
                        dHumidity : Double) : Double;
function MixingRatio(pressure : Double;
                     temperature : Double;
                     humidity : Double) : Double;
function Td_From_P_MR(pressure : Double;
                      mixingRatio : Double) : Double;
function PrecipitableWater(p1 : Double;
                           t1 : Double;
                           u1 : Double;
                           p2 : Double;
                           t2 : Double;
                           u2 : Double;
                           g : Double) : Double;
function Td_From_MR_P(dMixingRatio : Double;
                      dPressure : Double) : Double;
function PotTemp_From_T_P(dTemperature : Double;
                        dPressure : Double) : Double;
function T_From_PotTemp_P(potentialTemperature : Double;
                        pressure : Double) : Double;
function U_From_Tdp_T(dDewPoint : Double;
                      dTemperature : Double) : Double;
function AbsoluteHumidity(vapourPressure : Double;
                          temperature : Double) : Double;
function DewPoint(dTemperature : Double;
                  dHumidity : Double) : Double;
function DerivedRH(dDPTemperature : Double;
                   dTemperature : Double) : Double;
function FrostPoint(dTemperature : Double;
                    dHumidity : Double) : Double;
function DewPointDepression(dDPTemperature : Double;
                            dDPHumidity : Double) : Double;
procedure GetWindFromEndPoints(var dSpeed : Double;
                               var dDirection : Double;
                               dFromNorthing, dFromEasting : Double;
                               dToNorthing,dToEasting : Double;
                               dTimePeriod : Double);
procedure GetWindFromComponents(var dSpeed : Double;
                                var dDirection : Double;
                                dNorthing : Double;
                                dEasting : Double;
                                dTimePeriod : Double);
procedure GetComponentsFromWind(var dNorthing : Double;
                                var dEasting : Double;
                                dSpeed : Double;
                                dDirection : Double;
                                dTimePeriod : Double);
function HeatIndex(temperature : Double;
                   humidity : Double) : Double;
function WindChill(windSpeed : Double;
                   temperature : Double) : Double;
function WindChillWattsPerM2(windSpeed : Double;
                             temperature : Double) : Double;
function WetDryTemp2Humidity(dTDryBulb : Double;
                             dTWetBulb : Double;
                             dPressure : Double) : Double;
function T_From_SAT_P(dSaturationAdiabat : Double;
                      dPressure : Double) : Double;
function SAT_From_T_P(temperature : Double;
                      pressure : Double) : Double;
function GetWetBulbTemp(dTDryBulb : Double;
                        dHumidity : Double;
                        dPressure : Double) : Double;
function IndexOfRefraction(pressure : Double;
                           vapourPressure : Double;
                           temperature : Double) : Double;
function RoughAltitude(dStartAlt : Double;
                       dStartPressure : Double;
                       dStartTemperature : Double;
                       dStartHumidity : Double;
                       dEndPressure : Double;
                       dEndTemperature : Double;
                       dEndHumidity : Double) : Double;
function PressureFromdGPM(pressureStart : Double;
                          gpmStart : Double;
                          gpmEnd : Double;
                          TvirtualAverage : Double) : Double;
function RegionalPressureAtGeopotential(gpmGround : Double;
                                        gpmAGL : Double;
                                        iRegion : Integer) : Double;
function SATemperature(dGeopotentialMSL : Double) : Double;
function SAPressure(dGeopotentialMSL : Double) : Double;
function SADensity(dGeopotentialMSL : Double) : Double;
//function SpeedOfSound(sosVirtualTemperature : Double) : Double;
function SpeedOfSound(pressure : Double;
                      density : Double) : Double;
function ValidGroundTemperature(temperature : Double) : Boolean;
function ValidFlightTemperature(temperature : Double) : Boolean;
function GetLCLPressure(pressure : Double;
                        temperature : Double;
                        dewPoint : Double) : Double;

implementation

uses
  Math,
  KEDConstants,
  Maths, NewtonRoot, UnitConversions;

type
  TAltPress = record
    dAlt : Double;
    dPress : Double;
  end; // record

const
  SA_BOUNDARIES : array[0..3] of double = (0.0,
                                           11000.0,
                                           20000.0,
                                           32000.0);
  SA_TEMPERATURES : array[0..3] of double = (STANDARD_SL_TEMPERATURE - ABS_ZEROT,
                                             216.65,
                                             216.65,
                                             228.65);
  SA_TLAPSES : array[0..3] of double = (-6.5,
                                        0.0,
                                        1.0,
                                        2.8);
  SA_PRATIOS : array[0..3] of double = (1.0,
                                        2.233611E-1,
                                        5.403295E-2,
                                        8.5666784E-3);

  // Region 1 : Geopotential altitude and associated "standard" pressures
  //            (See WMO306 Vol II Region I 1/32.1 and 2/32.3)
  //            !! Note Algeria has differences
  R1_GPM2ALT : array[0..14] of TAltPress =
                               ((dAlt : 0;      dPress : STANDARD_SL_PRESSURE),
                                (dAlt : 1500;   dPress : 850),
                                (dAlt : 3000;   dPress : 700),
                                (dAlt : 5700;   dPress : 500),
                                (dAlt : 7500;   dPress : 400),
                                (dAlt : 9600;   dPress : 300),
                                (dAlt : 10800;  dPress : 250),
                                (dAlt : 12300;  dPress : 200),
                                (dAlt : 14100;  dPress : 150),
                                (dAlt : 16500;  dPress : 100),
                                (dAlt : 18600;  dPress : 70),
                                (dAlt : 20700;  dPress : 50),
                                (dAlt : 23400;  dPress : 30),
                                (dAlt : 25800;  dPress : 20),
                                (dAlt : 29700;  dPress : 10));
  // Region 2 : Geopotential altitude and associated "standard" pressures
  //            (See WMO306 Vol II Region II 2/32.1 and 2/32.4)
  R2_GPM2ALT : array[0..14] of TAltPress =
                               ((dAlt : 0;      dPress : STANDARD_SL_PRESSURE),
                                (dAlt : 1500;   dPress : 850),
                                (dAlt : 3100;   dPress : 700),
                                (dAlt : 5800;   dPress : 500),
                                (dAlt : 7600;   dPress : 400),
                                (dAlt : 9500;   dPress : 300),
                                (dAlt : 10600;  dPress : 250),
                                (dAlt : 12300;  dPress : 200),
                                (dAlt : 14100;  dPress : 150),
                                (dAlt : 16600;  dPress : 100),
                                (dAlt : 18500;  dPress : 70),
                                (dAlt : 20500;  dPress : 50),
                                (dAlt : 24000;  dPress : 30),
                                (dAlt : 26500;  dPress : 20),
                                (dAlt : 31000;  dPress : 10));
  // Region 6 : Geopotential altitude and associated "standard" pressures
  //            (See WMO306 Vol II Region VI 6/32.1 and 6/32.4)
  R6_GPM2ALT : array[0..14] of TAltPress =
                               ((dAlt : 0;      dPress : STANDARD_SL_PRESSURE),
                                (dAlt : 1500;   dPress : 850),
                                (dAlt : 3000;   dPress : 700),
                                (dAlt : 5500;   dPress : 500),
                                (dAlt : 7000;   dPress : 400),
                                (dAlt : 9000;   dPress : 300),
                                (dAlt : 10500;  dPress : 250),
                                (dAlt : 12000;  dPress : 200),
                                (dAlt : 13500;  dPress : 150),
                                (dAlt : 16000;  dPress : 100),
                                (dAlt : 18500;  dPress : 70),
                                (dAlt : 20500;  dPress : 50),
                                (dAlt : 23500;  dPress : 30),
                                (dAlt : 26500;  dPress : 20),
                                (dAlt : 31000;  dPress : 10));

//***************************************************************************
//
//  FUNCTION  : SaturationVapourPressure
//
//  I/P       : dSVPTemperature (double) - the temperature in degC.
//
//  O/P       : (double) - The saturation vapour pressure, in hPa
//
//  OPERATION : Determines the saturation vapour pressure of moist air
//              with regard to water at the given temperature.
//
//              Definition :
//                The water vapour pressure when the air is saturated i.e. 100% RH.
//                  or
//                The maximum water vapour pressure that air can support
//                at a given temperature.
//
//                At SVP there is a state of equilibrium with respect to
//                a plane surface of pure water.
//
//              Up until V3.16, I used equations from WMO-No.8 "Guide
//              to Meteorological Instruments and Methods of
//              Observation" Annex 4B (Page I.4-25).   I commented out
//              the SVP relative to ice.   Technical
//              Regulations WMO No.49 Appendix A equ 13 and Appendix B
//              (17) says that we can use this equation down to -50�C
//              with insignificant error.
//              See also comments about relative humidity in (17) of
//              Annex 4A (Page I.4-23) of WMO-No.8.//
//
//              Holger Voemel's article (http://cires.colorado.edu/~voemel/vp.html),
//              the China Intercomparison report and comments from
//              Helmut Mitter (E+E) have caused me to change from this
//              CIMO/Bolton type equation to Wexler (modified to ITS-90 by Hardy)
//              see
//                The Proceedings of the Third International Symposium on
//                Humidity & Moisture, Teddington, London, England, April 1998
//                "ITS-90 FORMULATIONS FOR VAPOR PRESSURE, FROSTPOINT
//                TEMPERATURE, DEWPOINT TEMPERATURE, AND
//                ENHANCEMENT FACTORS IN THE RANGE -100 TO +100 C"
//
//              Copy this line for use in spreadsheets\
//              NOTE : Temperature is in Kelvin
//  =Exp(- 2836.5744 * Power(B2,-2) - 6028.076559 * Power(B2,-1) + 19.54263612 - (0.02737830188 * B2) + 0.000016261698 * Power(B2,2) + 0.00000000070229056 * Power(B2,3) - 1.8680009E-13 * Power(B2,4) + 2.7150305 * Ln(B2))/100
//
//  UPDATED   : 2013-08-16
//
//***************************************************************************
function SaturationVapourPressure(dSVPTemperature : Double) : Double;
begin
  if (dSVPTemperature < INVALID_TEST) then
  begin
    // This equation gives pressure in hPa, given that T is in Kelvin
    dSVPTemperature := dSVPTemperature - ABS_ZEROT;
    result := Exp(- 2836.5744 * Power(dSVPTemperature,-2)
                  - 6028.076559 * Power(dSVPTemperature,-1)
                  + 19.54263612
                  - 0.02737830188 * dSVPTemperature
                  + 0.000016261698 * Power(dSVPTemperature,2)
                  + 0.00000000070229056 * Power(dSVPTemperature,3)
                  - 1.8680009E-13 * Power(dSVPTemperature,4)
                  + 2.7150305 * Ln(dSVPTemperature))/100;
  end // if
  else
    result := INVALID_VALUE;
end; // SaturationVapourPressure

//***************************************************************************
//
//  FUNCTION  : Td_From_VP
//
//  I/P       : dGivenVP : double - The Vapour Pressure, in hPa
//
//  O/P       : double - The dewpoint temperature in degC
//
//  OPERATION : Determine the Dew Point Temperature, given the Vapour
//              Pressure using Wexler (modified to ITS-90 by Hardy)
//              Instead of using an iterative operation, we use the formula
//              published by Hardy
//              see
//                The Proceedings of the Third International Symposium on
//                Humidity & Moisture, Teddington, London, England, April 1998
//                "ITS-90 FORMULATIONS FOR VAPOR PRESSURE, FROSTPOINT
//                TEMPERATURE, DEWPOINT TEMPERATURE, AND
//                ENHANCEMENT FACTORS IN THE RANGE -100 TO +100 C"
//                "its90formulas for Vapour Pressure, Frost Point, Temperature, DewpointT -100to+100 - Hardy.pdf"
//
//              Note : I think the text in the document is a bit confusing.
//                The parameter given mut be Vapour Pressure and NOT
//                Saturated Vapour Pressure (which is temperature dependent only)
//                Dew Point obviously needs to factor in RH, and hence it must be
//                vapour pressure that is used.
//
//              Copy this line for use in spreadsheets
//  =(207.98233 - 20.156028 * LN(C2*100) + 0.46778925 * POWER(LN(C2*100),2) - 0.0000092288067 * POWER(LN(C2*100),3)) / (1 - 0.13319669 * LN(C2*100) + 0.0056577518 * POWER(LN(C2*100),2) - 0.000075172865 * POWER(LN(C2*100),3))
//
//  UPDATED   : 2013-08-16
//
//***************************************************************************\
function Td_From_VP(dGivenVP : Double) : Double;
begin
  if ((dGivenVP < INVALID_TEST) and
      (dGivenVP > 0.0)) then
  begin
    // Convert pressure from hPa to Pa for use in the equation below
    dGivenVP := dGivenVP * 100;
    result := (2.0798233E2
               - 2.0156028E1 * Ln(dGivenVP)
               + 4.6778925E-1 * Power(Ln(dGivenVP),2)
               - 9.2288067E-6 * Power(Ln(dGivenVP),3)) /
              (1
               - 1.3319669E-1 * Ln(dGivenVP)
               + 5.6577518E-3 * Power(Ln(dGivenVP),2)
               - 7.5172865E-5 * Power(Ln(dGivenVP),3));
    result := result + ABS_ZEROT;
  end // if
  else
    result := INVALID_TEST
end; // Td_From_VP

//***************************************************************************
//
//  FUNCTION  : Tf_From_VP
//
//  I/P       : dGivenVP : double - The Vapour Pressure, in hPa
//
//  O/P       : double - The frostpoint temperature in �C
//
//  OPERATION : Determine the Frost Point Temperature, given the Vapour
//              Pressure using Wexler (modified to ITS-90 by Hardy)
//              Instead of using an iterative operation, we use the formula
//              published by Hardy
//              see
//                The Proceedings of the Third International Symposium on
//                Humidity & Moisture, Teddington, London, England, April 1998
//                "ITS-90 FORMULATIONS FOR VAPOR PRESSURE, FROSTPOINT
//                TEMPERATURE, DEWPOINT TEMPERATURE, AND
//                ENHANCEMENT FACTORS IN THE RANGE -100 TO +100 C"
//                "its90formulas for Vapour Pressure, Frost Point, Temperature, DewpointT -100to+100 - Hardy.pdf"
//
// = (2.1257969E2 - 1.0264612E1 * LN(B2) + 1.4354796E-1 * POWER(LN(B2),2)) / (1 - 8.2871619E-2 * LN(B2) + 2.3540411E-3 * POWER(LN(B2),2) - 2.4363951E-5 * POWER(LN(B2),3)) - 273.15
//
//  UPDATED   : 2015-10-01
//
//***************************************************************************\
function Tf_From_VP(dGivenVP : Double) : Double;
begin
  if ((dGivenVP < INVALID_TEST) and
      (dGivenVP > 0.0)) then
  begin
    // Convert pressure from hPa to Pa for use in the equation below
    dGivenVP := dGivenVP * 100;
    result := (2.1257969E2
               - 1.0264612E1 * Ln(dGivenVP)
               + 1.4354796E-1 * Power(Ln(dGivenVP),2)) /
              (1
               - 8.2871619E-2 * Ln(dGivenVP)
               + 2.3540411E-3 * Power(Ln(dGivenVP),2)
               - 2.4363951E-5 * Power(Ln(dGivenVP),3));
    result := result + ABS_ZEROT;
  end // if
  else
    result := INVALID_TEST
end; // Tf_From_VP

//***************************************************************************
//
//  FUNCTION  : VapourPressure
//
//  I/P       : dTemperature : Double - The temperature in �C
//
//              dHumidity : Double  - The relative humidity in %
//
//  O/P       : (double) - The pressure of water vapour in hPa
//
//  OPERATION : Determines the (water) vapour pressure.
//
//              Vapour pressure is that fraction of the ambient pressure that
//              is due to water vapour in the air.   It is given the symbol e.
//              In general, it is small since water vapour makes up a very
//              portion of the air composition.   e at 100% humidity at sea
//              level at 20 degC is 24hPa.
//              (i.e. the SVP at 20 degC at ~1000hPa is 24hPa)
//
//              Vapour Pressure is
//                1) the SVP modified by the humidity, or
//                1) the SVP at Dew Point temperature.
//
//              Well explained in
//                http://www.faqs.org/faqs/meteorology/temp-dewpoint/
//
//  UPDATED   : 2004-10-14
//
//***************************************************************************
function VapourPressure(dTemperature : Double;
                        dHumidity : Double) : Double;
begin
  if ((dTemperature < INVALID_TEST) and
      (dHumidity < INVALID_TEST)) then
  begin
    result := SaturationVapourPressure(dTemperature) * dHumidity / 100.0;
  end // if
  else
    result := INVALID_VALUE;
end; // VapourPressure

//***************************************************************************
//
//  FUNCTION  : MixingRatio
//
//  I/P       : pressure : Double - The pressure in hPa
//
//              temperature : Double - The temperature in degC
//
//              humidity : Double - The relative humidity in %
//
//  O/P       : Double - the mixing ratio in g/kg
//
//  OPERATION : Mixing Ratio is the ratio of the mass of water vapour to
//              the mass of dry air with which the water vapour is associated.
//              It is measured in g/kg since there is normally only a small
//              amount of water vapour in the air.
//
//              It is given the letter r (and sometimes w)
//
//              Typically MR at 20�C at sea level is roughly 14g/kg
//
//              "May be approximated by the specific humidity" says amsetsoc.org
//              (specific humidity = q = r / (1 + r) so I'm not sure how that works)
//
//              Use either
//
//              Well explained in
//                http://www.faqs.org/faqs/meteorology/temp-dewpoint/
//
//  UPDATED   : 2007-03-16
//
//***************************************************************************
function MixingRatio(pressure : Double;
                     temperature : Double;
                     humidity : Double) : Double;
var
  e : Double;

begin
  if ((pressure < INVALID_TEST) and
      (pressure > 0.0) and
      (temperature < INVALID_TEST) and
      (humidity < INVALID_TEST)) then
  begin
//    Use either
//    es := SaturationVapourPressure(dTemperature);
//    ws := 621.97 * es / (dPressure - es);
//    result := ws * dHumidity / 100.0;
//    or
    e := VapourPressure(temperature, humidity);
    result := 621.97 * e / (pressure - e);
  end // if
  else
    result := INVALID_VALUE;
end; // MixingRatio

//***************************************************************************
//
//  FUNCTION  : Td_from_P_MR
//
//  I/P       : pressure : Double - the pressure, in hPa
//
//              mixingRatio : Double - The mixing ratio, in g/m^3
//
//  O/P       : Double - The dew point temperature, in Kelvin
//
//  OPERATION : Calculate the dew point temperature from pressure and mixing ratio
//
//  UPDATED   : 2022-12-12
//
//***************************************************************************
function Td_from_P_MR(pressure : Double;
                      mixingRatio : Double) : Double;
var
  e : Double;

begin
  e := mixingRatio * pressure / (621.97 + mixingRatio);
  Result := Kelvin_From_degC(Td_From_VP(e));
end; // Td_From_P_MR

//***************************************************************************
//
//  FUNCTION  : PrecipitableWater
//
//  I/P       : p1 : Double - starting pressure. in hPa
//
//              t1 : Double - starting temperature. in deg C
//
//              u1 : Double - starting relative humidity, in %
//
//              p2 : Double - ending pressure. in hPa
//
//              t2 : Double - ending temperature. in deg C
//
//              u2 : Double - ending relative humidity, in %
//
//              g : Double - acceleration due to gravity, in m/s^2
//
//  O/P       : Double - in mm
//
//  OPERATION : Calculate the amount of precipitable water between two pressure
//              layers
//
//              https://ntrs.nasa.gov/api/citations/20110016000/downloads/20110016000.pdf
//              modified to accept variable g
//
//  UPDATED   : 2022-04-13
//
//***************************************************************************
function PrecipitableWater(p1 : Double;
                           t1 : Double;
                           u1 : Double;
                           p2 : Double;
                           t2 : Double;
                           u2 : Double;
                           g : Double) : Double;
var
  mr1 : Double;
  mr2 : Double;

begin
  mr1 := MixingRatio(p1, t1, u1);
  mr2 := MixingRatio(p2, t2, u2);
  result := 5 / (g * 100) * (mr2 + mr1) * (p1 - p2);
end; // PrecipitableWater

//***************************************************************************
//
//  FUNCTION  : Td_From_MR_P
//
//  I/P       : dMixingRatio : double
//
//              dPressure : double
//
//  O/P       :
//
//  OPERATION : Return the Dew Point Temperature, given the Mixing Ratio and
//              pressure.
//
//              This function reverses the Mixing Ratio function above, giving
//              Vapour Pressure.   Since we want the Dew Point Temperature,
//              T = Td and so Vapour Pressure = Saturation Vapour Pressure.
//              Then reverse the SVP equation to get the dew point temperature.
//
//  UPDATED   : 2013-07-29
//
//***************************************************************************
function Td_From_MR_P(dMixingRatio : Double;
                      dPressure : Double) : Double;
var
  dSVP : Double;

begin
  if ((dPressure < INVALID_TEST) and
      (dPressure > 0.0) and
      (dMixingRatio < INVALID_TEST)) then
  begin
    dSVP := dMixingRatio * dPressure / (621.97 + dMixingRatio);
    result := Td_From_VP(dSVP);
  end // if
  else
    result := INVALID_VALUE;
end; // Td_From_MR_P

//***************************************************************************
//
//  FUNCTION  : PotTemp_From_T_P
//
//  I/P       : dTemperature : double - The temperature, in Kelvin
//
//              dPressure : double - The pressure, in hPa
//
//  O/P       : double - The potential temperature, in Kelvin
//
//  OPERATION : Calculate the potential temperature given the temperature and
//              pressure.
//
//              The potential temperature (Theta) of a parcel of fluid (gas?) at
//              pressure P (and temperature T) is the temperature that the
//              parcel would acquire if adiabatically (i.e. without exchange of
//              heat with its environment) brought to a standard
//              reference pressure P_{0}, usually 1000 millibars.
//
//              Theta =  T * (Po / P) ^ (R / Cpd)
//
//              where R = specific gas constant for air (287.04 J/(kg�K))
//                    Cpd = specific heat of dry air at constant pressure (1005.7 J/(kg�K))
//
//              Some references give R/Cp = 0.288, whereas it works out at 0.2854
//              with RDGAS = 287.04 and SPECH_DA_CP = 1005.7
//
// http://glossary.ametsoc.org/wiki/Poisson_constant
//              "This exponent is often assumed to be 2/7, the ratio of the gas constant
//               to the specific heat capacity at constant pressure for an ideal diatomic gas."
// http://glossary.ametsoc.org/wiki/Potential_temperature
//
//  UPDATED   : 2013-07-29
//
//***************************************************************************
function PotTemp_From_T_P(dTemperature : Double;
                          dPressure : Double) : Double;
begin
  if ((dPressure < INVALID_TEST) and
      (dPressure > 0.0) and
      (dTemperature < INVALID_TEST)) then
    result := dTemperature * Power(1000.0 / dPressure, RDGAS/SPECH_DA_CP)
  else
    result := INVALID_VALUE;
end; // PotTemp_From_T_P

//***************************************************************************
//
//  FUNCTION  : T_From_PotTemp_P
//
//  I/P       : potentialTemperature : Double - The potential temperature, in Kelvin
//
//              pressure : Double - The pressure, in hPa
//
//  O/P       : double - The temperature, in Kelvin
//
//  OPERATION : Calculate the temperature, given the potential temperature and
//              pressure.
//
//              See the notes in the function PotTemp_From_T_P.
//
//  UPDATED   : 2022-11-02
//
//***************************************************************************
function T_From_PotTemp_P(potentialTemperature : Double;
                          pressure : Double) : Double;
begin
  if ((pressure < INVALID_TEST) and
      (pressure > 0.0) and
      (potentialTemperature < INVALID_TEST)) then
    result := potentialTemperature / Power(1000.0 / pressure, RDGAS/SPECH_DA_CP)
  else
    result := INVALID_VALUE;
end; // T_From_PotTemp_P

//***************************************************************************
//
//  FUNCTION  : VirtualTemperatureK
//
//  I/P       : dVTPressure (double) - the pressure in mB.
//
//              dVTTemperature (double) - the temperature in �C.
//
//              dVTHumidity (double) - the relative humidity in %.
//
//  O/P       : (double) - The absolute virtual temperature in Kelvin.
//
//  OPERATION : Determines the absolute virtual temperature for given
//					    pressure, temperature and humidity.
//
//              This is the theoretical temperature that the air would
//              be at if there was no moisture in the air. If the RH
//              was 0%, the Virtual Temperature and actual temperature
//              would be the same.   Obviously, they will be most
//              different when the RH is 100%.   Moist air is less dense
//              than dry air, so the virtual temperature is higher than
//              the actual temperature.   You can regard Virtual
//              Temperature as a correction for moisture in the air.
//
//					    The equations used were obtained from Dr Bruce
//					    Hewistson at UCT's Dept Environmental and Geographical
//					    Science.   He quoted his source as:
//						  Moisture Calculations (Roy Jenne, NCAR, USA)
//
//              Confirmed in WMO No 175 pg 25, with the one constant changed
//              from 0.379 to 0.37802.

//
//              Another definition : The virtual temperature is the temperature
//              that dry air would have if its pressure and density were equal
//              to those of a given sample of moist air.
//
//  UPDATED   : 2004/10/14
//
//***************************************************************************
function VirtualTemperatureK(dVTPressure : Double;
                             dVTTemperature : Double;
                             dVTHumidity : Double) : Double;
begin
  if ((dVTPressure < INVALID_TEST) and
      (dVTPressure > 0.0) and
      (dVTTemperature < INVALID_TEST) and
      (dVTHumidity < INVALID_TEST)) then
  begin
    // Virtual Temperature
    result := (dVTTemperature - ABS_ZEROT) /
              (1.0 - 0.37802 * VapourPressure(dVTTemperature, dVTHumidity) / dVTPressure);
  end // if
  else
    result := INVALID_VALUE;
end; // VirtualTemperatureK

//***************************************************************************
//
//  FUNCTION  : AirDensity
//
//  I/P       : dADPressure (double) - the pressure in mB.
//
//              dADVertualTemperature (double) - the virtual temperature
//                in Kelvin.
//
//  O/P       : (double) - The air density in grams / cubic metre
//
//  OPERATION : Determines the air density, given the pressure and the
//                virtual temperature.
//
//              Derived as follows:
//
//              Consider the ideal gas law:
//                (1)      P*V = n*R*T
//                         where:  P = pressure
//                                 V = volume
//                                 n = number of moles
//                                 R = gas constant
//                                 T = temperature
//
//              Density is simply the number of molecules of the ideal
//              gas in a certain volume, in this case a molar volume,
//              which may be mathematically expressed as:
//                (2)      D = n / V
//                         where:  D = density
//                                 n = number of molecules
//                                 V = volume
//
//              Then, by combining the previous two equations, the
//              expression for the density becomes:
//                (3)      D = P / (R * T)
//                         where:   D = density, kg/m3
//                                  P = pressure, Pascals
//                                  R = gas constant , J/(kg*degK) = 287.05 for dry air
//                                  T = temperature, Kelvin
//
//  UPDATED   : 2004/10/14
//
//***************************************************************************
function AirDensity(dADPressure : Double;
                    dADVirtualTemperature : Double) : Double;
begin
  if ((dADPressure < INVALID_TEST) and
      (dADPressure > 0.0) and
      (dADVirtualTemperature < INVALID_TEST)) then
  	result := 348.38395 * dADPressure / dADVirtualTemperature
  else
    result := INVALID_VALUE;
end; // AirDensity

//***************************************************************************
//
//  FUNCTION  : U_From_Tdp_T
//
//  I/P       : dDewPoint (double) - The dew point in �C
//
//              dTemperature (double) - The air temperature in %
//
//  O/P       : (double) - The dew point temperature in �C
//
//  OPERATION : This function returns the dew point (celsius) given the
//              temperature (Celsius) and relative humidity (%).
//
//              Definition : This is the temperature to which the air
//              must be cooled before dew condenses from it. At this
//              temperature the actual water vapour content of the air
//              is equal to the saturation water vapour pressure.
//
//					    The equations used were obtained from WMO-No.8 "Guide
//              to Meteorological Instruments and Methods of
//              Observation" Annex 4B
//
//  UPDATED   : 2004/10/14
//
//***************************************************************************
function U_From_Tdp_T(dDewPoint : Double;
                      dTemperature : Double) : Double;
var
  es : Double;
  ed : Double;

begin
  if ((dDewPoint < INVALID_TEST) and
      (dTemperature < INVALID_TEST)) then
  begin
    // Determine the saturation vapour pressure at this temperature
    // Note: the effect of pressure will be cancelled out below, so we may use
    // a constant here.
    es := SaturationVapourPressure(dTemperature);
    ed := SaturationVapourPressure(dDewPoint);
    // Get the humidity
    result := ed / es * 100.0;
  end // if
  else
    result := INVALID_VALUE;
end; // U_From_Tdp_T

//***************************************************************************
//
//  FUNCTION  : AbsoluteHumidity
//
//  I/P       : vapourPressure : Double - The vapour pressure in hPa
//
//              temperature : Double - The temperature in degC
//
//  O/P       : Double - The absolute humidity in grams of water/cubic metre of air
//
//  OPERATION : Return the absolute humidity in grams H2O per cu m of air.
//
//              Reference GILL MaxiMet Manual
//
//  UPDATED   : 2021-01-03
//
//***************************************************************************
function AbsoluteHumidity(vapourPressure : Double;
                          temperature : Double) : Double;
begin
  Result := 2.16679 * (vapourPressure * 100.0) / (temperature - ABS_ZEROT);
end;

//***************************************************************************
//
//  FUNCTION  : DewPoint
//
//  I/P       : dTemperature : Double - The temperature in degC
//
//              dHumidity : Double - The relative humidity in %
//
//  O/P       : Double - The dew point temperature in degC
//
//  OPERATION : Return the dew point (Celsius) given the temperature (Celsius)
//              and relative humidity (%).
//
//  UPDATED   : 2024-09-30
//
//***************************************************************************
function DewPoint(dTemperature : Double;
                  dHumidity : Double) : Double;
var
  vp : Double;

begin
  vp := VapourPressure(dTemperature, dHumidity);
  if (vp < INVALID_TEST) then
  begin
    result := Td_From_VP(vp);
  end // if
  else
  begin
    result := INVALID_VALUE;
  end;
end; // DewPoint

//***************************************************************************
//
//  FUNCTION  : DerivedRH
//
//  I/P       : dDPTemperature : Double - The dew point temperature, in degC
//
//              dTemperature : Double - The temperature, in degC
//
//  O/P       : Double - The relative humidity, in %
//
//  OPERATION : Calculate RH from dew point temperature and temperature
//
//  UPDATED   : 2021-10-11
//
//***************************************************************************
function DerivedRH(dDPTemperature : Double;
                   dTemperature : Double) : Double;
var
  es : Double;
  ed : Double;
//  dTemp : Double;

begin
  if ((dDPTemperature < INVALID_TEST) and
      (dTemperature < INVALID_TEST)) then
  begin
    // Determine the saturation vapour pressures at the temperature and dew point
    es := SaturationVapourPressure(dTemperature);//,STANDARD_SL_PRESSURE);
    ed := SaturationVapourPressure(dDPTemperature);//,STANDARD_SL_PRESSURE);

    result := ed/es * 100.0;
  end // if
  else
    result := INVALID_VALUE;
end; // DerivedRH

//***************************************************************************
//
//  FUNCTION  : FrostPoint
//
//  I/P       : dDPTemperature (double) - The temperature in �C
//
//              dDPHumidity (double) - The relative humidity in %
//
//  O/P       : (double) - The dew point temperature in �C
//
//  OPERATION : Return the frost point (Celsius) given the temperature (Celsius)
//              and relative humidity (%).
//
//  UPDATED   : 2024-09-30
//
//***************************************************************************
function FrostPoint(dTemperature : Double;
                    dHumidity : Double) : Double;
var
  vp : Double;

begin
  vp := VapourPressure(dTemperature, dHumidity);
  if (vp < INVALID_TEST) then
  begin
    result := Tf_From_VP(vp);
  end // if
  else
  begin
    result := INVALID_VALUE;
  end;
end; // FrostPoint

//***************************************************************************
//
//  FUNCTION  : DewPointDepression
//
//  I/P       : dDPTemperature (double) - The temperature in �C
//
//              dDPHumidity (double) - The relative humidity in %
//
//  O/P       : The difference in temperature between the dry-bulb temperature
//              and the dew-point (always +ve)
//
//  OPERATION :
//
//  UPDATED   : 2006/03/13
//
//***************************************************************************
function DewPointDepression(dDPTemperature : Double;
                            dDPHumidity : Double) : Double;
var
  dDP : Double;
begin
  if ((dDPTemperature < INVALID_TEST) and
      (dDPHumidity < INVALID_TEST)) then
  begin
    dDP := DewPoint(dDPTemperature, dDPHumidity);
    if (dDP <= dDPTemperature) then
      result := dDPTemperature - dDP
    else
      result := 0.0;
  end // if
  else
    result := INVALID_VALUE;
end; // DewPointDepression

//***************************************************************************
//
//  FUNCTION  : GetWindFromEndPoints
//
//  I/P       : dFromNorthing (double), dFromEasting (double) - The location
//                of the source point, in metres.
//
//              dToNorthing (double), dToEasting (double) - The location
//                of the destination point, in metres.
//
//  O/P       : dSpeed (double) - in metres per second
//
//              dDirection (double) - in degrees
//
//  OPERATION : dTimePeriod (double) - The time between the two points,
//                in seconds.
//
//  UPDATED   : 2004/10/14
//
//***************************************************************************
procedure GetWindFromEndPoints(var dSpeed : Double;
                               var dDirection : Double;
                               dFromNorthing, dFromEasting : Double;
                               dToNorthing,dToEasting : Double;
                               dTimePeriod : Double);
begin
  // Determine the wind speed by dividing the straight line distance between the
  // two points by the time taken.
  dSpeed := (Sqrt(Power(dToNorthing - dFromNorthing,2) +
                  Power(dToEasting - dFromEasting,2))) / dTimePeriod;

  // Determine the wind direction
  if (dToNorthing - dFromNorthing <> 0) then
  begin
    dDirection := RadToDeg(arctan((dToEasting - dFromEasting) /
                                  (dToNorthing - dFromNorthing)));
    if (dToNorthing > dFromNorthing) then
      dDirection :=  dDirection + 180
    else
      if (dToEasting > dFromEasting) then
        dDirection := dDirection + 360;
  end // if
  else
    if (dToEasting > dFromEasting) then
      dDirection := 270.0
    else
      dDirection := 90.0;
  // Wind direction when the speed is 0, is also 0
  if (dSpeed = 0) then
    dDirection := 0;
end; // GetWindFromEndPoints

//***************************************************************************
//
//  FUNCTION  : GetWindFromComponents
//
//  I/P       : dNorthing (double) - The amount of movement in a North/South
//                direction, in metres
//
//              dEasting (double) - The amount of movement in an East/West
//                direction, in metres
//
//              dTimePeriod (double) - The time period over which the movement
//                has taken place. in seconds
//
//  O/P       : dSpeed (double) - The magnitude of the wind vector, in m/s
//
//              dDirection (double) - The direction of the wind vectore, in degress
//
//  OPERATION : Determine the wind speed and direction given the
//              displacement as northings and eastings, and the time
//              taken to cover this distance.
//
//  UPDATED   :
//
//***************************************************************************
procedure GetWindFromComponents(var dSpeed : Double;
                                var dDirection : Double;
                                dNorthing : Double;
                                dEasting : Double;
                                dTimePeriod : Double);
begin
  // Determine the wind speed by dividing the straight line distance between the
  // two points by the time taken.
  dSpeed := (Sqrt(Power(dNorthing,2) + Power(dEasting,2))) / dTimePeriod;

  // Determine the wind direction
  if (dNorthing <> 0) then
  begin
    dDirection := RadToDeg(arctan(dEasting / dNorthing));
    if (dNorthing > 0) then
      dDirection :=  dDirection + 180
    else
      if (dEasting > 0) then
        dDirection := dDirection + 360;
  end // if
  else
    if (dEasting > 0) then
      dDirection := 270.0
    else
      dDirection := 90.0;
  // Wind direction when the speed is 0, is also 0
  if (dSpeed = 0) then
    dDirection := 0;
end; // GetWindFromComponents

//***************************************************************************
//
//  FUNCTION  : GetComponentsFromWind
//
//  I/P       : dSpeed : double - The speed of the wind in m/s.   (If this is
//                a distance, ensure that dTimePeriod is 1.0)
//
//              dDirection : double - The direction of the wind (ie the bearing
//                from which it is blowing.
//
//              dTimePeriod : double - The time period over which the component
//                offsets must be calculated.
//
//  O/P       : dNorthing : double - The distance moved in a North/South direction
//                under the influence of the given wind
//
//              dEasting : double - The distance moved in a East/West direction
//                under the influence of the given wind
//
//  OPERATION : Resolve a wind vector into its components.
//
//  UPDATED   : 2010-02-09
//
//***************************************************************************
procedure GetComponentsFromWind(var dNorthing : Double;
                                var dEasting : Double;
                                dSpeed : Double;
                                dDirection : Double;
                                dTimePeriod : Double);
begin
  dNorthing := -dSpeed*dTimePeriod * cos(DegToRad(dDirection));
  dEasting := -dSpeed*dTimePeriod * sin(DegToRad(dDirection));
end; // GetComponentsFromWind

//***************************************************************************
//
//  FUNCTION  : HeatIndex
//
//  I/P       : temperature : Double - Air temperature in �C
//
//              humidity : Double - The relative humidity
//
//  O/P       : Double - Heat Index in degrees Celsius
//
//  OPERATION : Determine the Heat Index, given temperature and humidity.
//
//              https://en.wikipedia.org/wiki/Heat_index
//
//  UPDATED   : 2021-01-04
//
//***************************************************************************
function HeatIndex(temperature : Double;
                   humidity : Double) : Double;
const
  c1 = -8.78469475556;
  c2 = 1.61139411;
  c3 = 2.33854883889;
  c4 = -0.14611605;
  c5 = -0.012308094;
  c6 = -0.0164248277778;
  c7 = 0.002211732;
  c8 = 0.00072546;
  c9 = -0.000003582;

begin
  Result := c1 +
            c2 * temperature +
            c3 * humidity+
            c4 * temperature*humidity +
            c5 * Power(temperature, 2) +
            c6 * Power(humidity, 2) +
            c7 * Power(temperature, 2) * humidity +
            c8 * temperature * Power(humidity, 2) +
            c9 * Power(temperature, 2) * Power(humidity, 2);
end; // HeatIndex

//***************************************************************************
//
//  FUNCTION  : WindChill
//
//  I/P       : windSpeed : Double - Wind speed in m/s
//
//              temperature : Double - Air temperature in �C
//
//  O/P       : Double - Wind chill in �C
//
//  OPERATION : Calculate the Wind Chill in Celcius.
//
//              https://www.weather.gov/media/epz/wxcalc/windChill.pdf
//              Wind Chill[�F] = 35.74 +
//                               (0.6215 * T[�F]) -
//                               (35.75 * WS[mph]^0.16) +
//                               (0.4275 * T[�F] * WS[mph]^0.16)
//
//              https://www.calcunation.com/calculator/wind-chill-celsius.php
//              Wind Chill[�C] = 13.12 +
//                               (0.6215 * T[�C]) -
//                               (11.37 * WS[kph]^0.16) +
//                               (0.3965 * T[�C] * WS[kph]^0.16)
//
//  UPDATED   :
//
//***************************************************************************
function WindChill(windSpeed : Double;
                   temperature : Double) : Double;
begin
  Result := 13.12 +
            (0.6215 * temperature) -
            (11.37 * Power(windSpeed*3600.0/1000.0, 0.16)) +
            (0.3965 * temperature * Power(windSpeed*3600.0/1000.0, 0.16));
end; // WindChill

//***************************************************************************
//
//  FUNCTION  : WindChillWattsPerM2
//
//  I/P       : windSpeed : Double - Wind speed in m/s
//
//              temperature : Double - Air temperature in �C
//
//  O/P       : Double - Wind chill in watts per square metre
//
//  OPERATION : Calculate the Wind Chill in watts per square metre
//
//              https://www.weather.gov/media/epz/wxcalc/windChill.pdf
//              Wind Chill [W/m�] = (12.1452 + 11.6222 * SQRT(WS[m/s]) - 1.16222 * WS[m/s]) *
//                                  (33 - T[�C])
//
//  UPDATED   :
//
//***************************************************************************
function WindChillWattsPerM2(windSpeed : Double;
                             temperature : Double) : Double;
begin
  Result := (12.1452 + 11.6222 * Sqrt(windSpeed) - 1.16222 * windSpeed) *
            (33 - temperature);
end; // WindChillWattsPerM2

//***************************************************************************
//
//  FUNCTION  : WetDryTemp2Humidity
//
//  I/P       : dTDyBulb (double) - the dry bulb temperature in �C.
//
//              dTetBulb (double) - the wet bulb temperature in �C.
//
//              dPressure (double) - the pressure in mB.
//
//  O/P       : (double) - The relative humidity, in %
//
//  OPERATION : Determines the relative humidity, given the dry and
//              wet bulb temperatures, and the pressure.
//
//					    The equation used was obtained from WMO-No.8 "Guide
//              to Meteorological Instruments and Methods of
//              Observation" Annex 4B
//              "Psychometric formulae for the Assmann psychrometer"
//
//              Experimental comparison among the psychrometer and the two-pressure humidity generator and the dew point hygrometer
//
//  UPDATED   : 2005/02/22
//
//***************************************************************************
function WetDryTemp2Humidity(dTDryBulb : Double;
                             dTWetBulb : Double;
                             dPressure : Double) : Double;
var
  dEs : Double;  // Saturation Vapor Pressure at Dry Bulb (mb)
  dEw : Double;  // Saturation Vapor Pressure at Wet Bulb (mb)
  dE : Double;   // Actual Vapour Pressure (mb)
begin
  if ((dPressure < INVALID_TEST) and
      (dPressure > 0.0) and
      (dTDryBulb < INVALID_TEST) and
      (dTWetBulb < INVALID_TEST)) then
  begin
    dEs := SaturationVapourPressure(dTDryBulb);
    dEw := SaturationVapourPressure(dTWetBulb);
    dE := dEw - (0.000653 * (1 + 0.000944 * dTWetBulb) * dPressure * (dTDryBulb - dTWetBulb));
    result := 100.0 * (dE / dEs);
  end // if
  else
    result := INVALID_VALUE;
end; // WetDryTemp2Humidity

//***************************************************************************
//
//  FUNCTION  : GetWetBulbTemp
//
//  I/P       : dTDyBulb (double) - the dry bulb temperature in �C.
//
//              dHumidity (double) - the relative humidity in %
//
//              dPressure (double) - the pressure in mB.
//
//  O/P       : (double) - The wet bulb temperature in �C
//
//  OPERATION : Determines the wet bulb temeprature, given the dry bulb
//              temperatures, humidity and the pressure.   The method
//              is iterative, homing in on the final value to an accuracy
//              of better than 0.1�C
//
//					    The equation used was derived from those given in
//              WMO-No.8 "Guide to Meteorological Instruments and Methods
//              of Observation" Annex 4B
//
//  UPDATED   : 2005/02/22
//
//***************************************************************************
function GetWetBulbTemp(dTDryBulb : Double;
                        dHumidity : Double;
                        dPressure : Double) : Double;
var
  dStep : Double;
  dTWetBulb : Double;
  dDerivedHumidity : Double;
begin
  if ((dPressure < INVALID_TEST) and
      (dPressure > 0.0) and
      (dTDryBulb < INVALID_TEST) and
      (dHumidity < INVALID_TEST)) then
  begin
    dStep := 1.0;
    dTWetBulb := dTDryBulb;
    dDerivedHumidity := 100.0;

    dHumidity := Max(dHumidity,0.0);
    dHumidity := Min(dHumidity,100.0);

    while (abs(dDerivedHumidity - dHumidity) > 0.1) do
    begin
      if (dDerivedHumidity > dHumidity) then
        // Adjust the estimated wet bulb temperature downwards if the derived
        // humidity is too high
        dTWetBulb := dTWetBulb - dStep
      else
      begin
        // If the derived humidity overshoots the actual humidity, step back in
        // wet bulb temperature, and approach with smaller increments
        dTWetBulb := dTWetBulb + dStep;
        dStep := dStep / 10.0;
      end; // if

      dDerivedHumidity := WetDryTemp2Humidity(dTDryBulb, dTWetBulb, dPressure);
    end; // while

    result := dTWetBulb;
  end // if
  else
    result := INVALID_VALUE;
end; // WetDryTemp2Humidity

//***************************************************************************
//
//  FUNCTION  : IndexOfRefraction
//
//  I/P       : pressure : Double - in hPa
//
//              vapourPressure : Double - in hPa
//
//              temperature : Double - in degrees C
//
//  O/P       : Double
//
//  OPERATION : Return the atmospheric refractive index at microwave radio frequencies
//
//              Equation obtained from IMS/NASA for SOW205152-13
//
//              Note that the 77.6, -5.6 and 374808 constants appear to vary
//              slightly, depneding on the model used.
//
//              Compare to
//                https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.453-6-199705-S!!PDF-E.pdf
//                https://nvlpubs.nist.gov/nistpubs/jres/50/jresv50n1p39_A1b.pdf
//                https://ntrs.nasa.gov/api/citations/19790018544/downloads/19790018544.pdf (page 426)
//                https://www.fig.net/resources/proceedings/fig_proceedings/fig_2002/Js28/JS28_rueger.pdf
//                1977 Intertropical Convergence Zone Experiment
//                Kwajalein Reference Atmospheres, 1979 page 93
//                IRIG Standards for Range Meteorological Data Reduction 108-72
//
//  UPDATED   : 2022-04-20
//
//***************************************************************************
function IndexOfRefraction(pressure : Double;
                           vapourPressure : Double;
                           temperature : Double) : Double;
var
  temperatureK : Double;

begin
  temperatureK := temperature - ABS_ZEROT;
  result := (77.6 * pressure - 5.6 * vapourPressure + 374808 * vapourPressure/temperatureK) /
            temperatureK;
end; // IndexOfRefraction

//***************************************************************************
//
//  FUNCTION  : T_From_SAT_P
//
//  I/P       : dSaturationAdiabat : double - The saturation adiabat in degC
//
//              dPressure : double - the pressure in hPa.
//
//  O/P       : double - The temperature at which this occurs in degC
//
//  OPERATION : Determines the temperature at which the saturation adiabat
//              occurs, given the pressure.
//
//              The method is iterative, homing in on the final value to an
//              accuracy of better than 0.01degC
//
//					    The equation used was derived from those given in
//              WMO-No.8 "Guide to Meteorological Instruments and Methods
//              of Observation" Annex 4B
//
//              Replace with Bolton equation?
//              https://journals.ametsoc.org/view/journals/mwre/136/7/2007mwr2224.1.xml
//              https://www.nsstc.uah.edu/mips/personnel/kevin/thermo/Chap-6ppt.pdf
//              https://unidata.github.io/MetPy/v0.2/api/thermo.html
//
//  UPDATED   : 2005/02/22
//
//***************************************************************************
function T_From_SAT_P(dSaturationAdiabat : Double;
                      dPressure : Double) : Double;
var
  dStep : Double;
  dEstT : Double;           // in degC
  dDerivedSAT : Double;

begin
  dStep := 100.0;
  dEstT := ABS_ZEROT;
  dDerivedSAT := PotTemp_From_T_P(Kelvin_From_DegC(dEstT), dPressure) /
                 Exp((-2.6518986 * (621.97*SaturationVapourPressure(dEstT))/
                                   (dPressure-SaturationVapourPressure(dEstT)))/ Kelvin_From_DegC(dEstT));
  dDerivedSAT := degC_From_Kelvin(dDerivedSAT);

  while (abs(dDerivedSAT - dSaturationAdiabat) > 0.01) do
  begin
    if (dSaturationAdiabat > dDerivedSAT) then
      // Adjust the estimated temperature downwards if the derived
      // Saturation Adiabat is too high
    begin
      dEstT := dEstT + dStep;
    end
    else
    begin
      // If the derived Saturation Adiabt overshoots the required Saturation
      // Adiabat, step back in estimated temperature, and approach
      // with smaller increments.
      dEstT := dEstT - dStep;
      dStep := dStep / 10.0;
    end; // if

    // Saturation Adiabat = Dry adiabat / thingy
    dDerivedSAT := PotTemp_From_T_P(Kelvin_From_DegC(dEstT), dPressure) /
                   Exp((-2.6518986 * (621.97*SaturationVapourPressure(dEstT))/
                                     (dPressure-SaturationVapourPressure(dEstT)))/ (Kelvin_From_DegC(dEstT)));
    dDerivedSAT := degC_From_Kelvin(dDerivedSAT);
  end; // while


  result := dEstT;
end; // T_From_SAT_P

//***************************************************************************
//
//  FUNCTION  : SAT_From_T_P
//
//  I/P       : temperature : Double - in Kelvin
//
//              pressure : Double - in hPa
//
//  O/P       : Double - The saturated adiabat value, in Kelvin
//
//  OPERATION : Get the saturated adiabat value from temperature and pressure.
//
//  UPDATED   : 2022-12-10
//
//***************************************************************************
function SAT_From_T_P(temperature : Double;
                      pressure : Double) : Double;
begin
  Result := PotTemp_From_T_P(temperature, pressure) /
            Exp((-2.6518986 * (621.97*SaturationVapourPressure(degC_From_Kelvin(temperature)))/
                              (pressure-SaturationVapourPressure(degC_From_Kelvin(temperature)))) /
                (temperature));
end; // SAT_From_T_P

//***************************************************************************
//
//  FUNCTION  : RoughAltitude
//
//  I/P       : dStartAltitude (double) - The altitude above mean sea
//                level, in m, at the bottom of the layer
//
//              dStartPressure (double) - The pressure, in hPa, at the
//                bottom of the layer
//
//              dStartTemperature (double) - The temperature, in �C, at
//                the bottom of the layer
//
//              dStartHumidity (double) - The relative humidity, in %, at
//                the bottom of the layer
//
//              dEndPressure (double) - The pressure, in hPa, at the
//                top of the layer
//
//              dEndTemperature (double) - The temperature, in �C, at
//                the top of the layer
//
//              dEndHumidity (double) - The relative humidity, in %, at
//                the top of the layer
//
//  O/P       : (double) - The altitude above mean sea level, in m, at
//                the top of the layer.
//
//  OPERATION : The PTU hypsometric equation is used to determine the
//              geopotential altitude at the top of a layer, given the PTU
//              values at the top and bottom, and the altitude of the bottom
//              of the layer.
//
//              Various references, including:
// https://maths.ucd.ie/met/msc/fezzik/Phys-Met/Ch03-Slides-2.pdf
//
//  UPDATED   : 2005/06/20
//
//***************************************************************************
function RoughAltitude(dStartAlt : Double;
                       dStartPressure : Double;
                       dStartTemperature : Double;
                       dStartHumidity : Double;
                       dEndPressure : Double;
                       dEndTemperature : Double;
                       dEndHumidity : Double) : Double;
var
  dAveVTemp : Double;
begin
  if ((dStartPressure < INVALID_TEST) and
      (dStartPressure > 0.0) and
      (dStartTemperature < INVALID_TEST) and
      (dStartHumidity < INVALID_TEST) and
      (dEndPressure < INVALID_TEST) and
      (dEndPressure > 0.0) and
      (dEndTemperature < INVALID_TEST) and
      (dEndHumidity < INVALID_TEST)) then
  begin
    // Average virtual temperature from starting to ending point, in Kelvin
    dAveVTemp := (VirtualTemperatureK(dStartPressure,dStartTemperature,dStartHumidity) +
                  VirtualTemperatureK(dEndPressure,dEndTemperature,dEndHumidity)) / 2.0;
    // Single-layer moist hystrostatic height
    result := dStartAlt + (RDGAS / STANDARD_NORMAL_GRAVITY * dAveVTemp * ln(dStartPressure / dEndPressure));
  end // if
  else
    result := INVALID_VALUE;
end; // RoughAltitude

//***************************************************************************
//
//  FUNCTION  : PressureFromdGPM
//
//  I/P       : pressureStart (double) - The known pressure at the starting
//                altitude (in any units, since the output is a ratio of the input).
//
//              gpmStart (double) - The geopotential starting altitude (in m).
//
//              gpmEnd (double) - The geopotential ending altitude (in m).
//
//              TvirtualAverage (double) - The average virtual temperature over
//                the altitude range (in K).
//
//  O/P       : (double) - the pressure at the second altitude
//
//  OPERATION : Calculate the pressure at a gpm altitude, given the altitude
//              and pressure at another gpm altitude, and the average virtual
//              temperature between the points.
//
//              The calculation uses the hypsometric equation and is
//              referenced in WMO No8. Equ 12.12. This uses a fixed gravity
//              (value at 45�). Scientifically one should use a latitude- and
//              altitude-dependent gravity, but WMO has chosen not to do this.
//
//              !! Could it benefit from calculating the gravity at the latitude and altitude,
//              and using the average virtual temperature over the altitude span?!!
//
//  UPDATED   : 2018-02-16
//
//***************************************************************************
function PressureFromdGPM(pressureStart : Double;
                          gpmStart : Double;
                          gpmEnd : Double;
                          TvirtualAverage : Double) : Double;
begin
  if ((pressureStart < INVALID_TEST) and
      (pressureStart > 0.0) and
      (TvirtualAverage < INVALID_TEST) and
      (gpmStart < INVALID_TEST) and
      (gpmEnd < INVALID_TEST)) then
    result := pressureStart /
              exp((STANDARD_NORMAL_GRAVITY * (gpmEnd - gpmStart)) /
                  (RDGAS * TvirtualAverage))
  else
    result := INVALID_VALUE;
end; // PressureFromdAltitude

//***************************************************************************
//
//  FUNCTION  : LookupPressureFromGPM
//
//  I/P       :
//
//  O/P       :
//
//  OPERATION : Given an array of altitudes and their associated pressures,
//              determine the pressure at the given altitude.
//
//  UPDATED   :
//
//***************************************************************************
function LookupPressureFromGPM(aPA : array of TAltPress;
                            dGPM : Double) : Double;
var
  n : Integer;
  dSlope : Double;
  dOffset : Double;
begin
  n := 0;
  if (dGPM <= aPA[0].dAlt) then
    // The altitude is at or below the lowest altitude in the table.
    // Use the lowet two point pairs for approximation
    n := 1
  else
    if (dGPM >= aPA[High(aPA)].dAlt) then
      // The altitude is at or above the highest altitude in the table.
      // Use the highest two point pairs for approximation
      n := High(aPA)
    else
      // Find between which two points the given altitude lies, and then do
      // a straight-line extrapolation on Ln(P) to determine the pressure.
      // (If the table has been set up correctly, it should be found)
      while (dGPM > aPA[n].dAlt) do
        Inc(n);

  // n now contains the upper index of the point pair that will be used to
  // determine the straight-line graph of Alt vs Ln(P)
  dSlope := (Ln(aPA[n].dPress) - Ln(aPA[n-1].dPress)) /
            (aPA[n].dAlt - aPA[n-1].dAlt);
  dOffset := Ln(aPA[n].dPress) - aPA[n].dAlt * dSlope;
  result := Exp(dSlope * dGPM + dOffset);
end; // LookupPressureFromGPM

//***************************************************************************
//
//  FUNCTION  : RegionalPressureAtGeopotential
//
//  I/P       : gpmGround (double) - The geopotential starting altitude.
//
//              gpmAGL (double) - The geopotential ending altitude.
//
//              iRegion (integer) - The WMO region where this calculation
//                is taking place.
//
//  O/P       : (double) - the pressure at the second altitude
//
//  OPERATION : Determine "standard" pressure at a given geopotential altitude.
//
//              Region 1 and 2 have set pressures for given gpm MSL
//              See WMO306 Vol II Region I 1/32.1 and 1/32.3,
//                                Region II 2/32.1 and 2/32.4
//
//
//              For other regions, use the ISA pressure for the given altitude,
//              although some are meant to be "determined nationally"
//              See WMO306 Vol II Region III 3/32.1,
//                                Region IV 4/32.1,
//                                Region V 5/32.1
//
//              Algeria is different to the rest of region 1
//              Argentina uses different approximations for N/S of 40�S
//              Australia has 5(!) regions of latitude
//
//              At the moment, 2008-05-08, I don't know this equation, so am
//              just using standard pressure for this altitude.
//
//
//
//  UPDATED   : 2018-02-16
//
//***************************************************************************
function RegionalPressureAtGeopotential(gpmGround : Double;
                                        gpmAGL : Double;
                                        iRegion : Integer) : Double;
begin
  if ((gpmGround < INVALID_TEST) and
      (gpmAGL < INVALID_TEST)) then
  begin
    case iRegion of
      1 : result := LookupPressureFromGPM(R1_GPM2ALT,gpmGround + gpmAGL);
      2 : result := LookupPressureFromGPM(R2_GPM2ALT,gpmGround + gpmAGL);
      6 : result := LookupPressureFromGPM(R6_GPM2ALT,gpmGround + gpmAGL);
      else
        result := SAPressure(gpmGround + gpmAGL);
    end; // case
  end // if
  else
    result := INVALID_VALUE;
end; // RegionalPressureAtGeopotential

//***************************************************************************
//
//  FUNCTION  : SATemperature
//
//  I/P       : dGeopotentialMSL (double) - The geopotential altitude above
//                mean sea level
//
//  O/P       : (double) - The SA tempertaure for the given altitude in K
//
//  OPERATION : Returns the 1976 US Standard Atmosphere temperature for
//              a given geopotential altitude,
//
//              From 0m MSL to 11000m, lapse rate = -6.5�C/km
//              From 11000m MSL to 20000m, lapse rate = 0�C/km
//              From 20000m MSL to 32000m, lapse rate = 1�C/km
//              From 32000m MSL to 47000m, lapse rate = 2.8�C/km
//
//              see the Fortran program on http://www.pdas.com/atmos.htm
//
//  UPDATED   : 2006/10/27
//
//***************************************************************************
function SATemperature(dGeopotentialMSL : Double) : Double;
begin
  if (dGeopotentialMSL <= SA_BOUNDARIES[1]) then
    result := SA_TEMPERATURES[0] +
              (SA_TLAPSES[0] * dGeopotentialMSL/1000.0)
  else
    if (dGeopotentialMSL <= SA_BOUNDARIES[2]) then
      result := SA_TEMPERATURES[1] +
                (SA_TLAPSES[1] * dGeopotentialMSL/1000.0)
    else
      if (dGeopotentialMSL <= SA_BOUNDARIES[3]) then
        result := SA_TEMPERATURES[2] +
                  (SA_TLAPSES[2] * (dGeopotentialMSL - SA_BOUNDARIES[2])/1000.0)
      else
        result := SA_TEMPERATURES[3] +
                  (SA_TLAPSES[3] * (dGeopotentialMSL - SA_BOUNDARIES[3])/1000.0)
end; // SATemperature

//***************************************************************************
//
//  FUNCTION  : SAPressure
//
//  I/P       : dGeopotentialMSL (double) - The geopotential altitude above
//                mean sea level
//
//  O/P       : (double) - The SA pressure for the given altitude, in hPa
//
//  OPERATION : Returns the 1976 US Standard Atmosphere pressure for
//              a given geopotential altitude,
//
//              From
//                http://en.wikipedia.org/wiki/International_Standard_Atmosphere
//                http://www.answers.com/topic/international-standard-atmosphere
//                http://www.pdas.com/atmos.htm (and the Fortran program)
//                http://homepage.mac.com/gyatt/atmosculator/The%20Standard%20Atmosphere.html
//
//              In a portion of the atmosphere where there is a constant, non-zero
//              lapse rate, the pressure is given as:
//
//              P = Ps * (T / Ts) ^ (g / (L * R))
//
//              In an isothermal portion of the atmosphere, the pressure is given as:
//
//              P = Ps * e ^ (g * (hs - h) / (R * Ts))
//
//              where
//                Ps = pressure at the start of the boundary
//                Ts = temperature (K) at the start of the boundary
//                hs = geopotential at the start of the boundary
//
//              Problem : "The 1976 model is identical with ... the ICAO standard
//                up to 32 km"   I do not know the ICAO above 32km.
//
//  UPDATED   : 2006/12/13
//
//***************************************************************************
function SAPressure(dGeopotentialMSL : Double) : Double;
begin
  if (dGeopotentialMSL <= SA_BOUNDARIES[1]) then
    result := SA_PRATIOS[0] * STANDARD_SL_PRESSURE *
              Power(SATemperature(dGeopotentialMSL) / SA_TEMPERATURES[0],
                    STANDARD_NORMAL_GRAVITY / (-SA_TLAPSES[0]/1000.0 * RDGAS))
  else
    if (dGeopotentialMSL <= SA_BOUNDARIES[2]) then
      result := SA_PRATIOS[1] * STANDARD_SL_PRESSURE *
                Power(BASE_E,
                      STANDARD_NORMAL_GRAVITY * (SA_BOUNDARIES[1] - dGeopotentialMSL) /
                      (RDGAS * SA_TEMPERATURES[1]))
    else
      if (dGeopotentialMSL <= SA_BOUNDARIES[3]) then
        result := SA_PRATIOS[2] * STANDARD_SL_PRESSURE *
                  Power(SATemperature(dGeopotentialMSL) / SA_TEMPERATURES[2],
                        STANDARD_NORMAL_GRAVITY / (-SA_TLAPSES[2]/1000.0 * RDGAS))
      else
        result := SA_PRATIOS[3] * STANDARD_SL_PRESSURE *
                  Power(SATemperature(dGeopotentialMSL) / SA_TEMPERATURES[3],
                        STANDARD_NORMAL_GRAVITY / (-SA_TLAPSES[3]/1000.0 * RDGAS))
end; // SAPressure

//***************************************************************************
//
//  FUNCTION  : SADensity
//
//  I/P       : dGeopotentialMSL (double) - The geopotential altitude above
//                mean sea level
//
//  O/P       : (double) - The SA density (g/m3) for the given altitude
//
//  OPERATION : Returns the 1976 US Standard Atmosphere density for
//              a given geopotential altitude,
//
//              Uses the ideal gas equation
//                P (Pa) = density (kg/m3) * R * Temperature (K)
//
//              From http://en.wikipedia.org/wiki/International_Standard_Atmosphere
//
//  UPDATED   :
//
//***************************************************************************
function SADensity(dGeopotentialMSL : Double) : Double;
begin
  result := SAPressure(dGeopotentialMSL) / (SATemperature(dGeopotentialMSL) * RDGAS) * 100.0 * 1000.0;
end; // SADensity

////***************************************************************************
////
////  FUNCTION  :
////
////  I/P       : sosVirtualTemperature : Double - the virtual temperature [K]
////                at which the speed of sound is required.
////
////  O/P       :
////
////  OPERATION : source : FM6-15 pg 229
////
//// http://hyperphysics.phy-astr.gsu.edu/hbase/Sound/souspe3.html#c1
//// Vsound[m/s] = Sqrt(adiabatic constant * gas constant[J/mol K] * T[K]/
////                    molecular mass of gas[kg/mol]
////
//// adiabatic index = 1.4
//// gas constant = 8.314J/mol K
//// average molecular mass for dry air = 28.95g/mol
//// This gives Vsound[m/s] = 20.05 * Sqrt(T) m/s
////
//// The equation below is defined from the above-derived speed at 0 degC and the
//// step change to speed at 1 degC. It is thus only valid for a small range.
//// v = 331.3m/s + 0.606 * T[in degC]
//// v = 331.3 * sqrt(1 + T[in degC]/273.15)
////
//// Molecular weight of water vapour - 18, compared to 28.95 for dry air.
//// Use vapour pressure to get the average molecular weight?
////
//// Since we are talking about "dry air", I assume that I can use virtual
//// temperature, and that will be satisfactory. (See paragraph 177c in FM6-15)
////
////  UPDATED   :
////
////***************************************************************************
//function SpeedOfSound(sosVirtualTemperature : Double) : Double;
//begin
//  result := 20.05 * sqrt(sosVirtualTemperature);
//end; // SpeedOfSound

// Due to the assumption about virtual tempertaure, and the arrival of the
// equation below (2022-04), I have changed the method of Speed of Sound calculation.

//***************************************************************************
//
//  FUNCTION  : SpeedOfSound
//
//  I/P       : pressure : Double - The pressure, in hPa
//
//              density : Double - the density in g/m^3
//
//  O/P       :
//
//  OPERATION : Calculate the speed of sound
//
//              Source : Wikipedia and IMS/NASA for SOW205152-13
//
//  UPDATED   : 2022-04-20
//
//***************************************************************************
function SpeedOfSound(pressure : Double;
                      density : Double) : Double;
begin
  result := sqrt(1.4028 * (pressure * 0.1) / (density * 0.000001));
end; // SpeedOfSound

//***************************************************************************
//
//  FUNCTION  : ValidGroundTemperature
//
//  I/P       : temperature : Double - Temperature in �C
//
//  O/P       : Boolean - TRUE if the temperature appears to be valid
//
//  OPERATION : Check if the given ground temperature may be considered valid.
//
//  UPDATED   : 2021-05-24
//
//***************************************************************************
function ValidGroundTemperature(temperature : Double) : Boolean;
begin
  Result := (temperature >= MIN_GROUND_TEMPERATURE) and
            (temperature <= MAX_TEMPERATURE);
end; // ValidGroundTemperature

//***************************************************************************
//
//  FUNCTION  : ValidFlightTemperature
//
//  I/P       : temperature : Double - Temperature in �C
//
//  O/P       : Boolean - TRUE if the temperature appears to be valid
//
//  OPERATION : Check if the given flight temperature may be considered valid.
//
//  UPDATED   : 2021-05-24
//
//***************************************************************************
function ValidFlightTemperature(temperature : Double) : Boolean;
begin
  Result := (temperature >= MIN_FLIGHT_TEMPERATURE) and
            (temperature <= MAX_TEMPERATURE);
end; // ValidFlightTemperature

//***************************************************************************
//
//  FUNCTION  :
//
//  I/P       : pressure : Double - Ground level pressure, in hPa
//
//              temperature : Double - Ground level temperature, in degC
//
//              dewPoint : Double - Ground level dew point, in degC
//
//  O/P       : Double - the pressure level of Lifting Condensation Level, in hPa
//
//  OPERATION : Given ground conditions, determine the pressure of the Lifting
//              Condensation Level (LCL).
//
//              The LCL is at the intersection of the dry adiabatic lapse rate
//              line that starts at ground pressure/temperature, and the mixing
//              ratio line, that starts at ground pressure/dew point.
//
//  UPDATED   : 2022-11-02
//
//***************************************************************************
function GetLCLPressure(pressure : Double;
                        temperature : Double;
                        dewPoint : Double) : Double;
var
  mr : Double;
  groundTp : Double;
  p : Double;
  Td : Double;
  T : Double;

begin
  // Get the mixing ratio value at ground pressure and dewpoint.
  mr := MixingRatio(pressure, dewPoint, 100.0);

  // What is the equation for the dry adiabat that passes through ground pressure
  // and ground temperature.

  // Get the ground potential temperature (in K)
  groundTp := PotTemp_From_T_P(temperature - ABS_ZEROT, pressure);
  // The dry adiabt through the ground temperature will follow the curve
  //  T = groundTp / Power((1000.0/p),0.288);

  // Starting at the ground pressure, decrease pressure until the mixing ratio
  // line that started at ground Td crosses the dry adiabat line that started at
  // ground temperature.
  p := pressure;
  Td := Td_From_P_MR(p, mr);
  T := T_From_PotTemp_P(groundTp, p);
  while (Td < T) do
  begin
    p := p - 0.01;
    Td := Td_From_P_MR(p, mr);
    T := T_From_PotTemp_P(groundTp, p);
  end;

  Result := p;
end; // GetLCLPressure

(*
  Water vapour pressure

--------------------------------------------------------------------------------

Water vapour concentration

The relationship between vapour pressure and concentration is defined for any gas by the equation:
p = nRT/V
p is the pressure in Pa, V is the volume in cubic metres, T is the temperature in degrees Kelvin (degrees Celsius + 273.16), n is the quantity of gas expressed in molar mass ( 0.018 kg in the case of water ), R is the gas constant: 8.31 Joules/mol/m3

To convert the water vapour pressure to concentration in kg/m3: ( Kg / 0.018 ) / V = p / RT

kg/m3 = 0.002166 *p / ( t + 273.16 )   where p is the actual vapour pressure



--------------------------------------------------------------------------------

Concentration of water vapour in air

It is sometimes convenient to quote water vapour concentration as kg/kg of dry air.
This is used in air conditioning calculations and is quoted on psychrometric charts.
The following calculations for water vapour concentration in air apply at ground level.

Dry air has a molar mass of 0.028964 kg. It is denser than water vapour, which has a molar mass
of 0.018016 kg. (Ref https://en.wikipedia.org/wiki/Density_of_air) Therefore, humid air is lighter
than dry air. If the total atmospheric pressure is P and the water vapour pressure is p, the
partial pressure of the dry air component is P - p.
The weight ratio of the two components, water vapour and dry air is:

kg water vapour / kg dry air = 0.018 *p / ( 0.029 *(P - p ) )
  = 0.62 *p / (P - p )

At room temperature P - p is nearly equal to P, which at ground level is close to 100,000 Pa,
so, approximately:

kg water vapour / kg dry air = 0.62 *10-5 *p



--------------------------------------------------------------------------------


Thermal properties of damp air

The heat content, usually called the enthalpy, of air rises with increasing water
content. This hidden heat, called latent heat by air conditioning engineers, has to
be supplied or removed in order to change the relative humidity of air, even at a
constant temperature. This is relevant to conservators. The transfer of heat from
an air stream to a wet surface, which releases water vapour to the air stream at
the same time as it cools it, is the basis for psychrometry and many other
microclimatic phenomena. Control of heat transfer can be used to control the
drying and wetting of materials during conservation treatment.

The enthalpy of dry air is not known. Air at zero degrees celsius is defined to have zero enthalpy. The enthalpy, in kJ/kg, at any temperature, t, between 0 and 60C is approximately:

h = 1.007t - 0.026   below zero: h = 1.005t

The enthalpy of liquid water is also defined to be zero at zero degrees celsius. To turn liquid water to vapour at the same temperature requires a very considerable amount of heat energy: 2501 kJ/kg at 0C

At temperature t the heat content of water vapour is:

hw = 2501 + 1.84t

Notice that water vapour, once generated, also requires more heat than dry air to raise its temperature further: 1.84 kJ/kg.C against about 1 kJ/kg.C for dry air.

The enthalpy of moist air, in kJ/kg, is therefore:

h = (1.007*t - 0.026) + g*(2501 + 1.84*t)
g is the water content in kg/kg of dry air

*)

end.



