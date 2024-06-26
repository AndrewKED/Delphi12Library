unit KEDConstants;

interface

const
  INVALID_VALUE = 999999999;    // Enough to be divided by 10E6 and still produce an invalid longitude (note that this is less than 32bits, which may be an issue in BUFR?)
  INVALID_TEST = 999999990;     // Use this as a >= test point (to overcome floating point inaccuracy)

  UNUSED_BYTE = $FF;            // Typical value for an unused/uninitialised byte variable

  DEGREE_SYMBOL = #$00B0;

implementation

end.
