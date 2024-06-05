**FREE
// Prototypes
Dcl-PR SJCMAIN050               ExtPgm('SJCMAIN050');
   IntCmdLine                Like(IntCmdLine);
   IntJOB#                   Like(IntJOB#);
   IntLRUNUSR                Like(IntLRUNUSR);
   IntLJOBNAM                Like(IntLJOBNAM);
   IntJOBError               Like(IntJOBError);
End-PR;

begsr CallSbmJob;

  Err = BuildSbmJobCmd(            IntRUNCMD :
  IntJOBNAME:IntJOBD   :IntJOBDLIB:IntJOBQ   :
  IntJOBQLIB:IntJOBPTY :IntOUTPTY :IntPRTDEV :
  IntOUTQ   :IntOUTQLIB:IntRUNUSER:IntPRTTXT :
  IntRTGDTA :IntSYSLIBL:IntCURLIB :IntINLLIBL:
  IntMSGLOGL:IntMSGLOGS:IntMSGLOGT:IntLOGCLPG:
  IntINQMSGR:IntDSPSBMJ:IntMSGQ   :IntMSGQLIB:
  IntCmdLine);

  IntLJOBNAM = IntJOBNAME;
  
  callp SJCMAIN050(
                  IntCmdLine
                  :IntJOB#
                  :IntLRUNUSR
                  :IntLJOBNAM
                  :IntJOBError
                  );

  if %subst(IntJOBError:1:5) = 'Error';                               // -\
    Err = SendErrMessage(ServiceName + 'Job: '  +                     //  I
    %trim(IntLJOBNAM) + '/' + %trim(IntLRUNUSR) +                     //  I
    '/' + IntJOB# +  ' Could not start. '       +                     //  I
    %trim(%subst(IntJOBError:46) ) :'Y');                             //  I
  endif;                                                              // -/

endsr;
//#----------------------------------------------------------------------------
begsr SetDefaults;

  C10JOBNAME = *Blank;
  chain C10JOBNAME SJCCFG10R1;

  DefJOBNAME = C10JOBNAME;
  DefJOBD    = C10JOBD;
  DefJOBDLIB = C10JOBDLIB;
  DefJOBQ    = C10JOBQ;
  DefJOBQLIB = C10JOBQLIB;
  DefRUNUSER = C10RUNUSER;
  DefJOBPTY  = C10JOBPTY;
  DefOUTPTY  = C10OUTPTY;
  DefPRTDEV  = C10PRTDEV;
  DefOUTQ    = C10OUTQ;
  DefOUTQLIB = C10OUTQLIB;
  DefRUNUSER = C10RUNUSER;
  DefPRTTXT  = C10PRTTXT;
  DefRTGDTA  = C10RTGDTA;
  DefSYSLIBL = C10SYSLIBL;
  DefCURLIB  = C10CURLIB;
  DefINLLIBL = C10INLLIBL;
  DefMSGLOGL = C10MSGLOGL;
  DefMSGLOGS = C10MSGLOGS;
  DefMSGLOGT = C10MSGLOGT;
  DefLOGCLPG = C10LOGCLPG;
  DefINQMSGR = C10INQMSGR;
  DefDSPSBMJ = C10DSPSBMJ;
  DefMSGQ    = C10MSGQ;
  DefMSGQLIB = C10MSGQLIB;

endsr;














