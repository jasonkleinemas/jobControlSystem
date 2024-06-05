**FREE
// Converted from JKLEIN961/SJCSRC(SNDERRMSGD) to JKLEIN961/SJCSRCFREE(SNDERRMSGD).
// Converted with CVTRPGFREE version 1.5.09 on 2024-03-21-18.34.29.674071.
// Go to https://sourceforge.net/projects/cvtrpgfree/ for support and updates.
/If Not Defined(SendErrMessage_D)
/Define SendErrMessage_D
/COPY QMISCCOPY,WRITE0000D
/COPY QMISCCOPY,SNDMSG_D
dcl-pr SendErrMessage       Char(7);
  Message                  Char(100) Value;
  SendInfoMsg              Char(1) Value;

/EndIf
end-pr;

