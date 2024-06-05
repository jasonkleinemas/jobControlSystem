**FREE


begsr callSbmJob;

  Err = buildSubmitJobCommand(     IntRUNCMD :
  IntJOBNAME:IntJOBD   :IntJOBDLIB:IntJOBQ   :
  IntJOBQLIB:IntJOBPTY :IntOUTPTY :IntPRTDEV :
  IntOUTQ   :IntOUTQLIB:IntRUNUSER:IntPRTTXT :
  IntRTGDTA :IntSYSLIBL:IntCURLIB :IntINLLIBL:
  IntMSGLOGL:IntMSGLOGS:IntMSGLOGT:IntLOGCLPG:
  IntINQMSGR:IntDSPSBMJ:IntMSGQ   :IntMSGQLIB:
  IntCmdLine);

  IntLJOBNAM = IntJOBNAME;

  callp JCSMAIN050(IntCmdLine:IntJOB#:IntLRUNUSR:IntLJOBNAM:IntJOBError);

  if %subst(IntJOBError:1:5) = 'Error';
    Err = 
      SendErrMessage(ServiceName + 'Job: ' + %trim(IntLJOBNAM) +'/'+ %trim(IntLRUNUSR) +'/'+ IntJOB#  +
      ' Could not start. '+ %trim(%subst(IntJOBError:46) ) :'Y');
  endIf;

endsr;
//#----------------------------------------------------------------------------
begsr SetDefaults;

  C10JOBNAME = *Blank;
  chain C10JOBNAME JCSCFG10R1;

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
//#----------------------------------------------------------------------------
/if Not Defined(SetJobCheck)
begsr SetJobCheck;

  IntRUNCMD  = C10RUNCMD;
  IntJOBNAME = SetString(C10JOBNAME:DefJOBNAME);
  IntJOBD    = SetString(C10JOBD   :DefJOBD   );
  IntJOBDLIB = SetString(C10JOBDLIB:DefJOBDLIB);
  IntJOBQ    = SetString(C10JOBQ   :DefJOBQ   );
  IntJOBQLIB = SetString(C10JOBQLIB:DefJOBQLIB);
  IntJOBPTY  = SetString(C10JOBPTY :DefJOBPTY );
  IntOUTPTY  = SetString(C10OUTPTY :DefOUTPTY );
  IntPRTDEV  = SetString(C10PRTDEV :DefPRTDEV );
  IntOUTQ    = SetString(C10OUTQ   :DefOUTQ   );
  IntOUTQLIB = SetString(C10OUTQLIB:DefOUTQLIB);
  IntRUNUSER = SetString(C10RUNUSER:DefRUNUSER);
  IntPRTTXT  = SetString(C10PRTTXT :DefPRTTXT );
  IntRTGDTA  = SetString(C10RTGDTA :DefRTGDTA );
  IntSYSLIBL = SetString(C10SYSLIBL:DefSYSLIBL);
  IntCURLIB  = SetString(C10CURLIB :DefCURLIB );
  IntINLLIBL = SetString(C10INLLIBL:DefINLLIBL);
  IntMSGLOGL = SetString(C10MSGLOGL:DefMSGLOGL);
  IntMSGLOGS = SetString(C10MSGLOGS:DefMSGLOGS);
  IntMSGLOGT = SetString(C10MSGLOGT:DefMSGLOGT);
  IntLOGCLPG = SetString(C10LOGCLPG:DefLOGCLPG);
  IntINQMSGR = SetString(C10INQMSGR:DefINQMSGR);
  IntDSPSBMJ = SetString(C10DSPSBMJ:DefDSPSBMJ);
  IntMSGQ    = SetString(C10MSGQ   :DefMSGQ   );
  IntMSGQLIB = SetString(C10MSGQLIB:DefMSGQLIB);
  IntKILLCMD = C10KILLCMD;
  IntRUNCLAS = C10RUNCLAS;
  IntLJOBNAM = StringToUpper(C10JOBNAME);
  chain IntLJOBNAM JCSWRK10R1;
  IntLRUNUSR = W10LRUNUSR;
  IntJOB#    = W10LJOB#;

  if IntBeg     < DefBeg;
    IntBeg     = DefBeg;
  endIf;
  if IntEnd     < DefBeg;
    IntEnd     = DefBeg;
  endIf;
  if IntBeg     > DefEnd;
    IntBeg     = DefEnd;
  endIf;
  if IntEnd     > DefEnd;
    IntEnd     = DefEnd;
  endIf;

  if IntRUNCMD <> *Blank;
    JobStatus = GetJobStatus(IntLJOBNAM:IntLRUNUSR:IntJOB#);
    CurrentTime6 = %dec(%time());
    if IntLeaveType = 'ENDALL';
      IntBeg     = DefBeg;
      IntEnd     = DefBeg;
    endIf;
    select;
      when IntBeg = IntEnd;                                            // Don't run.
        exsr CheckStop;
      when IntBeg > IntEnd;                                          //  Run at the
        if CurrentTime >= IntBeg     AND                             //   beginign of
        CurrentTime >= DefEnd         OR                              //  the day and
        CurrentTime <= IntEnd     AND                                 //  the end of
        CurrentTime >= DefBeg;                                         // the day.
          exsr CheckStart;
        else;
          exsr CheckStop;
        endIf;
      when IntBeg < IntEnd;                                           // Run Durring
        if CurrentTime >= IntBeg And                                  //  the day.
        CurrentTime <= IntEnd;
          exsr CheckStart;
        else;
          exsr CheckStop;
        endIf;
      other;
    endsl;
  else;
    Err = SendErrMessage(ServiceName + 'Job: ' + %trim(IntJOBNAME) + ' Is missing a command' +' To run.':S10MSGINFO);
  endIf;

endsr;
/endIf
//#----------------------------------------------------------------------------
/if Not Defined(CheckStart)
begsr CheckStart;
  if JobStatus = '*ACTIVE' Or JobStatus = '*JOBQ';                       // Should be running. Do nothing.
  else; 
    Err = SendErrMessage(ServiceName + 'Job: ' + %trim(IntJOBNAME) + ' Is Being started.':S10MSGSTR);
    exsr CallSbmJob;
    W10LJOBNAM = IntLJOBNAM;
    W10LRUNUSR = IntLRUNUSR;
    W10LJOB# = IntJOB#;
    if %found(JCSWRK10);
      update JCSWRK10R1;
    else;
      write JCSWRK10R1;
    endif;
    W10LJOBNAM = *Blank;
    W10LRUNUSR = *Blank;
    W10LJOB# = *Blank;
  endif;

endsr;
/endIf
//#----------------------------------------------------------------------------
/if not defined(CheckStop)
begsr CheckStop;
  if JobStatus = '*ACTIVE' Or JobStatus = '*JOBQ'           // Should Not be running
  ;                                                                      
    IntRUNCMD = IntKILLCMD;
    if IntRUNCMD = *Blank;
      IntRUNCMD = 'ENDJOB JOB(' + IntJOB# + '/' + %trim(IntLRUNUSR) + '/' + %trim(IntLJOBNAM) + ') OPTION(*IMMED)';
    endif;
    Err = SendErrMessage(ServiceName + 'Job: ' + %trim(IntJOBNAME) + ' Is Being stopped.':S10MSGSTP);
    exsr CallSbmJob;
  endif;
endsr;
/endIf
//#----------------------------------------------------------------------------
/if defined(Console)
begsr SetScreenColor;
  ATRPGMNAME = cBlue;
  ATRTITLE1  = cPink;
  ATRSYSNAME = cBlue;
  ATRSCNNAME = cBlue;
  ATRTITLE2  = cPink;
  ATRDATE    = cBlue;
  ATRTIME    = cBlue;
  ATRUSER    = cBlue;
  ATRCMDLINE = cPink;
  ATRFLINE   = cPink;
endsr;
/endIf
//#----------------------------------------------------------------------------
/if defined(Console)
begsr WorkJob;

  chain HIDJOBNAME JCSWRK10R1;
  if %found(JCSWRK10);
    err = callp $$CmdExc$$('WRKJOB JOB(' + W10LJOB#  + '/' +
           %trim(W10LRUNUSR) + '/' +
           %trim(W10LJOBNAM) + ')' );
  endif;
endsr;
//#----------------------------------------------------------------------------
begsr ChangeJob;

  chain HIDJOBNAME JCSWRK10R1;
  if %found(JCSWRK10);
    err = callp $$CmdExc$$('CHGJOB ?*JOB('+ W10LJOB#  +'/'+ %trim(W10LRUNUSR) +'/'+ %trim(W10LJOBNAM) +') '+
           '??JOBPTY() ' + '??OUTPTY() ' + '??PRTDEV() ' + '??RUNPTY() ');
  endIf;
endsr;
/endIf

