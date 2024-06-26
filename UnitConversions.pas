unit UnitConversions;

interface

const
// CONVERSION FACTORS
//--------------------------------------------------------------------------
  M_PER_KM = 1000.0;
  M_PER_FT = 0.3048;
  M_PER_MI = 1609.344;
  M_PER_NMI = 1852;
  ATM_PER_MB = 0.0009869233;
  INHG_PER_MB = 0.02952999;         // A non-SI unit, but generally defined for 0°C (also defined as 0.296134 at 60°F)
  MMHG_PER_MB = 0.7500617;          // A non-SI unit, but generally defined for 0°C
  DEGF_PER_DEGC = 9.0/5.0;
  KTS_PER_MPS = 1.943844;           // The US, pre 1954, used 1nm = 1853.248m, which caused a value of 1.94254 knots per m/s (Wikipedia)
  MPH_PER_MPS = 2.236936;
  KPH_PER_MPS = 3.6;
  MILS6400_PER_DEG = 6400.0 / 360.0;
  MILS6000_PER_DEG = 6000.0 / 360.0;
  G_PER_KG = 1000.0;
  G_PER_OZ = 28.34952;
  G_PER_LB = 453.5924;
  GPM3_PER_OZPFT3 = 1001.1539701121;
  GPM3_PER_OZPYD3 = 37.0797766708;

implementation

end.
