This unit encrypts strings and files, using a standard borland algorithym.  I believe the number of possible variations is 2^96.  I made this unit because the example that is on Borlands TI page is for Pascal, this unit makes slight changes to the Borland string Encryption Algorithyms (So that they will work with Delphi2, and also to be able to use strings bigger than 256 chars), and also adapts them to be able to encrypt entire files (OF any kind).  Just add the unit to your projects uses clause (Must Be in your projects search path).

It is kinda slow:  137K File =  Encrypt 0.267sec Decrypt 0.265sec
		   3,198M File = Encrypt 6.541 sec Decrypt 6.374sec
		   (Includes reading source and writing result. 		   Figures generated on a P100, 32 megs ram).

TO USE:
	function Encrypt(const S: String; Key: Word): String;
	function Decrypt(const S: String; Key: Word): String;
	procedure EncryptFile(INFName, OutFName : String; Key : Word);
	procedure DecryptFile(INFName, OutFName : String; Key : Word);

NB!! Before you start using the unit, change the constants in the Encryptit.pas file to WORD values of your choice (preferably over 256).

I welcome any comments etc, especially if they would improve the speed or security of the unit.  This unit id free, And I take no responsibility for anything at all (especially this unit) ;).

Sean Mathews [killraven@globalserve.net]