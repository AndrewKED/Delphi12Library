unit ioports;

interface

FUNCTION PortIn(IOport: WORD): BYTE; ASSEMBLER; REGISTER;
PROCEDURE PortOut(IOport: WORD; Value: BYTE); ASSEMBLER; REGISTER;

implementation

// Note: PortIn and PortOut will work in Windows 95, but will NOT work
// under Windows NT.

FUNCTION PortIn(IOport: WORD): BYTE; ASSEMBLER; REGISTER;
ASM
  MOV DX,AX
  IN AL,DX
END;

PROCEDURE PortOut(IOport: WORD; Value: BYTE); ASSEMBLER; REGISTER;
ASM
  XCHG DX,AX
  OUT DX,AL
END;
end.
 