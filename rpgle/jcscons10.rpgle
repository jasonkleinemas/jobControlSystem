**FREE
/copy ../cb_rpgle/genericHeaders/controlOptions.rpgle

//
//  30     Subfile Display Indicator
//  33     Subfile Clear Indicator
//  34     Subfile End Indicator
//  35     Subfile Display Control Indicator
//

//**************************************************************
dcl-f JCSDSP01       WORKSTN infds(JCSSFL01Ds)
                             sfile(JCSSFL01:JCSSFL01RR#);
dcl-f JCSCFG10               Usage(*UPDATE:*DELETE:*OUTPUT) Keyed;
dcl-f JCSCFG10L1             Keyed Rename(JCSCFG10R1:JCSCFG10R2);
dcl-f JCSCFG20               Keyed;
dcl-f JCSCFG30L1             Usage(*UPDATE:*DELETE:*OUTPUT) Keyed;
dcl-f JCSSET10               Usage(*UPDATE:*DELETE:*OUTPUT);
dcl-f JCSWRK10               Keyed;


// Prototypes
dcl-pr JCSMAIN005               extPgm('JCSMAIN005');
end-pr;

dcl-pr JCSMAIN007               extPgm('JCSMAIN007');
end-pr;

dcl-pr JCSMAIN008               extPgm('JCSMAIN008');
end-pr;

dcl-pr JCSCONS30                extPgm('JCSCONS30');
   *n                         char(10);
end-pr;

// Prototypes
dcl-pr JCSMAIN050               extPgm('JCSMAIN050');
   *n                char(1000); // Command
   *n                char(   6); // Return Job Number
   *n                char(  10); // Return User Name
   *n                char(  10); // Return Job Name
   *n                char( 100); // Error
end-pr;

/copy ../cb_rpgle/constants/dspfCodes.rpgle
/copy ../cb_rpgle/constants/dspfColors.rpgle
/copy ../cb_rpgle/constants/dspfKeys.rpgle

/copy ../cb_rpgle/genericHeaders/programStatusDataStructure.rpgle
/copy ../cb_rpgle/generalSystemOsHeaders/apiFormatERRC0100.rpgle

/copy cb/jcsmisc_d.rpgle
/copy cb/jcsmisc_d2.rpgle

/define CheckStart
/define SetJobCheck

// Subfile File Level Data Structure
dcl-ds JCSSFL01Ds;
  KeyPressed                   char(1) pos(369);
    SFLRR#                 binDec(4:0) pos(376);                      // RRN of Current Page
    SFLPG#                 binDec(4:0) pos(378);                      // Current Page Number
    SFLREC                 binDec(4:0) pos(380);                      // Not Sure Just Yet
end-ds;

dcl-s IndicatorP         pointer Inz(%addr(*in));
dcl-ds Indicators               based(IndicatorP);
  DisplaySfl                ind pos(30);
  DisplayClr                ind pos(33);
  DisplayEnd                ind pos(34);
  DisplayCTL                ind pos(35);
end-ds;
//dcl-ds dsp01Ind          len(99) qualified;
//  DisplaySfl                ind pos(30);
//  DisplayClr                ind pos(33);
//  DisplayEnd                ind pos(34);
//  DisplayCTL                ind pos(35);
//end-ds;

dcl-c #RECORDS                  10;                                   // # Recds in Page

dcl-s JCSSFL01RR#         packed(4:0) inz;                            // Rel. Rec. Num.
dcl-s JCSSFL01Count       packed(4:0) inz;                            // Counter

dcl-s Err                   char(7);
dcl-s JobStatus             char(10) inz;
dcl-s CurrentDate           date inz;
dcl-s LeaveMain             char(1) inz('N');
dcl-s CancelOption          char(1) inz('N');
dcl-s EntJobName            char(10);
dcl-s EntOption             char(1);
dcl-s Top                    ind inz(*on);
dcl-c SERVICENAME               'Job Contol Service: ';
dcl-ds *n;
  CurrentTime6            zoned(6:0);
  CurrentTime             zoned(4:0) Overlay(CurrentTime6);
end-ds;



dcl-pr APIQMHSNDPM              ExtPgm('QMHSNDPM'); // Send Program Message
  PR_MsgID                 char(7) const;
  PR_MsgFil                char(20) const;
  PR_MsgDta                char(2048) const Options(*VarSize);
  PR_MsgDtaLen              int(10:0) const;
  PR_MsgTyp                char(10) const;
  PR_PgmQ                  char(256) const Options(*VarSize);
  PR_MsgLvl                 int(10:0) const;
  PR_MsgKey                char(4);
  PR_APIErr                char(256) Options(*VarSize);
end-pr;

dcl-pr APIQMHRMVPM              ExtPgm('QMHRMVPM'); //  Remove Program Messages
  PR_PgmQ                  char(256) const Options(*VarSize);
  PR_MsgLvl                 int(10:0) const;
  PR_MsgKey                char(4) const;
  PR_RmvMsg                char(10) const;
  PR_APIErr                char(256) Options(*VarSize);
end-pr;


dcl-s msgId                 char(7);
dcl-s msgLoc                char(20)   inz('TMMMSGF   *LIBL     ');
dcl-s msgRplDta             char(50)   inz(' ');
dcl-s msgRplDtaLen           int(10:0) inz(50);
dcl-s msgType               char(10)   inz('*DIAG');
dcl-s msgQueue              char(276)  inz('*');
dcl-s msgCallStack           int(10:0) inz(0);
dcl-s msgKey                char(4)    inz(' ');
dcl-s msgErr                 int(10:0) inz(0);
dcl-s msgrmv                char(10)   inz('*ALL');

msgQueue   = pgmPsds.procedureName;
OUTPGMNAME = pgmPsds.procedureName;

exsr SetScreenColor;
exsr SetDefaults;

Err = GetJCSSettings;
exsr $Init;
exsr $Load;
//#----------------------------------------------------------------------------
dow LeaveMain = 'N';
  exsr $Display;
  OUTTITLE2  = *Blank;
  OUTCMDLINE = *Blank;
  OUTFLINE   = *Blank;
  select;
    when KeyPressed = cKEY_F03 or KeyPressed = cKEY_F12;
      LeaveMain = 'Y';
    when KeyPressed = cKey_PageDown;
      if Not DisplayEnd;
        exsr $Load;
      endif;
    when KeyPressed = cKEY_F05;
      exsr Refresh;
    when KeyPressed = cKEY_F06;
      callp NewJobDef();
      exsr Refresh;
    when KeyPressed = cKEY_F10;
      callp WorkServerJobs();
    when KeyPressed = cKEY_F11;
      callp MaintMenu();
    when KeyPressed = cKEY_Enter;
      exsr $Process;
    other;
  endsl;
  msgKey = *blanks;
  callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
enddo;

*inLr = *On;
/copy cb/jcsmisc_c.rpgle

//***************************************************************
// Initialize the Subfile
//***************************************************************
begsr $Init;
  err = CheckJCSJob();
  JCSSFL01RR# = 0;
  DisplayClr = *On;
  DisplayCtl = *On;
  write JCSCTL01;
  DisplaySfl = *Off;
  DisplayClr = *Off;
  DisplayEnd = *Off;
  setll *LoVal JCSCFG10R2;
endsr;
//***************************************************************
// Load the Subfile
//***************************************************************
begsr $Load;

  JCSSFL01Count = 0;

  dow Not DisplayEnd and JCSSFL01Count < #Records;
    read JCSCFG10R2;
    *IN34 = %eof();
    if Not %eof(JCSCFG10L1)
    ;
      if C10JOBNAME <> S10JOBNAM1 and
      C10JOBNAME <> S10JOBNAM2 and
      C10JOBNAME <> *Blank;
        C10JOBNAME = %upper(C10JOBNAME);
        chain C10JOBNAME JCSWRK10R1;
        if Not %found(JCSWRK10);
          OUTSTAT = 'Unknown';
        else;
          OUTSTAT = getJobStatus(W10LJOBNAM:W10LRUNUSR:W10LJOB#);
        endif;
        Err = StatusColor(OutSTAT:AtrStat);
        OUTDESC = C10DESC;

        OUTJOBCLAS = GetClassDesc2(C10RUNCLAS);

        if C10ACTIVE = 'A';
          ATRJOBCLAS = cWhite;
        else;
          ATRJOBCLAS = cYellow;
        endif;
        HIDJOBNAME    = %upper(C10JOBNAME);
        JCSSFL01RR#   = JCSSFL01RR#   + 1;
        JCSSFL01COUNT = JCSSFL01COUNT + 1;
        write JCSSFL01;
      endif;
    endif;
  enddo;
  if JCSSFL01RR# > 0;
    DisplaySFL = *On;
  endif;
  CTL01REC# = JCSSFL01RR#;

endsr;
//***************************************************************
// Display the Subfile
//***************************************************************
begsr $Display;

  OUTTITLE1 = centerText(xConSol1:%len(OUTTITLE1));
  OUTTITLE2 = centerText(xConSol2:%len(OUTTITLE2));
  OUTFLINE = centerText(xExt +b1+ xRfr +b1+xNew +b1+ xWrkSrv +b1+ xMaint:%len(OUTFLINE));
  OUTCMDLINE = centerText(xEdt +b1+ xCpy +b1+ xDel +b1+ xDsp +b1+ xRen:%len(OUTCMDLINE));
  OUTSCNNAME = 'JCSCTL02';

//  callp RtvFldLoc('JCSDSP01':'*LIBL':'JCSSFL01':'INOPT':DSPEDT1LIN:DSPEDT1COL);
  write JCSOVLTOP;
  write JCSOVLBOT;
//  write MsgCtl;
  exfmt JCSCTL01;
  CTL01REC# = SFLPG#;

endsr;
//***************************************************************
// Process the Subfile
//***************************************************************
begsr $Process;
  if JCSSFL01RR# > 0;
    readc JCSSFL01;
    dow Not %eof;
      if INOPT <> ' ';
        select;
          when INOPT = '2';
            callp EditJobDef(HIDJOBNAME);
          when INOPT = '3';
            callp CopyJobDef(HIDJOBNAME);
          when INOPT = '4';
            callp DeleteJobDef(HIDJOBNAME);
          when INOPT = '5';
            callp DisplayJobDef(HIDJOBNAME);
          when INOPT = '7';
            callp ReNameJobDef(HIDJOBNAME);
          when INOPT = 'W';
//****              ExSr      WorkJob
          when INOPT = 'C';
//****              ExSr      ChangeJob
          other;
        endsl;
        INOPT = ' ';
        update JCSSFL01;
        write JCSCTL01;
      endif;
      readc JCSSFL01;
    enddo;
    if CancelOption = 'N';
      exsr Refresh;
    endif;
  endif;
endsr;
//***************************************************************
// Initialization Subroutine
//***************************************************************
begsr *INZSR;

endsr;
//#----------------------------------------------------------------------------
begsr Refresh;
  exsr $Init;
  exsr $Load;
  CancelOption  = 'N';
endsr;
//#----------------------------------------------------------------------------\
dcl-proc WorkServerJobs;
  dcl-pi *n;
  end-pi;
  
  callp ClearTopBot05();
  
  OUTSCNNAME = 'JCSMNT03';
  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xCnt:%len(OUTFLINE));
  OUTTITLE2 = centerText(xMntT3:%len(OUTTITLE2));
  OUTCMDLINE = 'Select one of the following:';
  dow 'W' <> 'N';
    OPTMAINT = *Blank;

    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
    exfmt JCSMNT03;
//
    if SetCancelLeave;
      leave;
    endif;
//
    if KeyPressed = cKEY_Enter;
      select;
        when OPTMAINT = %trim('1');
          callp JCSMAIN005();
        when OPTMAINT = %trim('2');
          callp JCSMAIN007();
        when OPTMAINT = %trim('3');
          callp JCSMAIN008();
        other;
          leave;
      endsl;
    endif;
//
  enddo;

end-proc;
//#----------------------------------------------------------------------------
dcl-proc ChangeRunClass;
  dcl-pi ChangeRunClass;
    RunClass                 char(10);
  end-pi;

  callp JCSCONS30(RunClass);

end-proc;
//#----------------------------------------------------------------------------
dcl-proc MaintMenu;
  dcl-pr MaintMenu;
  end-pr;

  callp ClearTopBot05();

  OUTSCNNAME = 'JCSMNT01';

  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xCnt:%len(OUTFLINE));
  OUTTITLE1 = centerText(xMntT1:%len(OUTTITLE2));
  OUTTITLE2 = *Blank;
  dow 'W' <> 'N';
    OUTCMDLINE = 'Select one of the following:';
    OPTMAINT = *Blank;

    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
    exfmt JCSMNT01;

    if SetCancelLeave;
      leave;
    endif;

    if KeyPressed = cKEY_Enter;
      select;
        when OPTMAINT = %trim('1');
          callp Maint1();
        when OPTMAINT = %trim('2');
          callp EditJobDef(S10JOBNAM1);
        when OPTMAINT = %trim('3');
          callp EditJobDef(S10JOBNAM2);
        when OPTMAINT = %trim('4');
          // callp JCSCONS30(); // Need parm fix later
        when OPTMAINT = %trim('5');
        callp EditJobDef(*Blank);
        other;
          leave;
      endsl;
    endif;

  enddo;

end-proc;
//#----------------------------------------------------------------------------
dcl-proc Maint1;
  dcl-pi Maint1;
  end-pi;

  dcl-s DspErr                char(10) inz;

  callp ClearDisplay();
  callp ClearTopBot05();

  setll *HiVal JCSSET10R1;
  readp JCSSET10R1;

  ATRSLEEPTM = cNoAttributes;
  ATRMSGINFO = cNoAttributes;
  ATRMSGSTR = cNoAttributes;
  ATRMSGSTP = cNoAttributes;
  ATRPRTMSG = cNoAttributes;
  ATRJOBNAM2 = cNoAttributes;
  ATRJOBNAM1 = cNoAttributes;

//  callp RtvFldLoc('JCSDSP01':'*LIBL':'JCSMNT02':'X10SLEEPTM':DSPEDT1LIN:DSPEDT1COL);

  OUTSCNNAME = 'JCSMNT02';
  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xSav:%len(OUTFLINE));
  OUTTITLE2 = centerText(xMntT2:%len(OUTTITLE2));
  OUTCMDLINE = *Blank;
  dow 'W' <> 'N';
    msgKey = *blanks;
    x10SLEEPTM = %char(S10SLEEPTM);
    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
//  write MsgCtl;
    exfmt JCSMNT02;

    if SetCancelLeave;
      leave;
    endif;
//
    callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
    ATRSLEEPTM = cNoAttributes;
    ATRMSGINFO = cNoAttributes;
    ATRMSGSTR = cNoAttributes;
    ATRMSGSTP = cNoAttributes;
    ATRPRTMSG = cNoAttributes;
    ATRJOBNAM2 = cNoAttributes;
    ATRJOBNAM1 = cNoAttributes;

    DspErr     = *Blank;

    S10SLEEPTM = %int(x10SLEEPTM);
    if S10SLEEPTM = *zero;
      DspErr     = 'S10SLEEPTM';
      ATRSLEEPTM = cYellow_RI;
      callp APIQMHSNDPM(*Blank:msgLoc:'Valid Values 1 - 99':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;
//
    if S10PRTMSG  <> 'Y' and S10PRTMSG  <> 'N';
      DspErr     = 'S10PRTMSG';
      ATRPRTMSG  = cYellow_RI;
    endif;

    if S10MSGSTP  <> 'Y' and S10MSGSTP  <> 'N';
      DspErr     = 'S10MSGSTP';
      ATRMSGSTP  = cYellow_RI;
    endif;

    if S10MSGSTR  <> 'Y' and S10MSGSTR  <> 'N';
      DspErr     = 'S10MSGSTR';
      ATRMSGSTR  = cYellow_RI;
    endif;

    if S10MSGINFO <> 'Y' and S10MSGINFO <> 'N';
      DspErr     = 'S10MSGINFO';
      ATRMSGINFO = cYellow_RI;
    endif;
//
    if S10JOBNAM2 = *Blank;
      DspErr     = 'S10JOBNAM2';
      ATRJOBNAM2 = cYellow_RI;
      callp APIQMHSNDPM(*Blank:msgLoc:'Cannot be blank.':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;
//
    if S10JOBNAM1 = *Blank;
      DspErr     = 'S10JOBNAM1';
      ATRJOBNAM1 = cYellow_RI;
      callp APIQMHSNDPM(*Blank:msgLoc:'Cannot be blank.': 50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;
//
    if KeyPressed = cKEY_Enter and DspErr = *Blank
    ;
      if %eof(JCSSET10);
        write JCSSET10R1;
      else;
        update JCSSET10R1;
      endif;
      leave;
    else;
//      callp RtvFldLoc('JCSDSP01':'*LIBL':'JCSMNT02':DspErr:DSPEDT1LIN:DSPEDT1COL);
    endif;

  enddo;


end-proc;
//#----------------------------------------------------------------------------
dcl-proc DeleteJobDef;
  dcl-pi DeleteJobDef;
    WrkJobDef                char(10) value;
  end-pi;

  callp ClearTopBot05();
  callp ClearDisplay();
  callp Cfg10LoadDsply(WrkJobDef);

//  callp RtvFldLoc('JCSDSP01':'*LIBL':'JCSDLT1':'FLD001':DSPEDT1LIN:DSPEDT1COL);

  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xDelE:%len(OUTFLINE));
  OUTTITLE2 = centerText(xDelT3:%len(OUTTITLE2));
  OUTSCNNAME = 'JCSDLT1';
  callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
  dow 'W' <> 'N';
    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
    exfmt JCSDLT1;
    if SetCancelLeave;
      leave;
    endif;
    if KeyPressed = cKEY_Enter;
      callp Cfg30Delete(WrkJobDef);
      delete(E) JCSCFG10R1;
      leave;
    endif;
  enddo;
  CancelOption = 'N';
end-proc;
//#----------------------------------------------------------------------------
dcl-proc ReNameJobDef;
  dcl-pi ReNameJobDef;
    WrkJobDef                char(10) value;
  end-pi;

  dcl-s DspErr                char(10) inz;
  dcl-s err                char(10) inz;

  callp ClearTopBot05();
  callp ClearDisplay();
  callp Cfg10LoadDsply(WrkJobDef);

//  callp RtvFldLoc('JCSDSP01':'*LIBL':'JCSCPY1':'DSPJOBNAME':DSPEDT1LIN:DSPEDT1COL);

  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xSav : %len(OUTFLINE));
  OUTTITLE2 = centerText(xRenT3:%len(OUTTITLE2));
  OUTSCNNAME = 'JCSCPY1';
  OLDDESC    = DSPDESC;
  OLDJOBNAME = DSPJOBNAME;
  ATRJOBDESC = cNoAttributes;
  ATRJOBNAME = cNoAttributes;
  callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
  DspErr = *Blank;

  dow 'W' <> 'N';
    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
    exfmt JCSCPY1;
    if SetCancelLeave;
      leave;
    endif;

    ATRJOBDESC = cNoAttributes;
    ATRJOBNAME = cNoAttributes;
    DspErr = *Blank;

    if KeyPressed = cKEY_Enter;
      err = CheckJobName(DspErr);
      err = CheckJobDesc(DspErr);
      err = CheckRunPri(DspErr);
    endif;

    if KeyPressed = cKEY_Enter and DspErr = *Blank;
      chain OLDJOBNAME JCSCFG10R1;
      C10JOBNAME = DspJobName;
      C10DESC    = DspDesc;
      callp Cfg10UpDate();
      callp Cfg30Rename(DSPJOBNAME:DSPJOBNAME);
      leave;
    else;
//      callp RtvFldLoc('JCSDSP01':'*LIBL':OUTSCNNAME:DspErr:DSPEDT1LIN:DSPEDT1COL);
    endif;
  enddo;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc CopyJobDef;
  dcl-pi CopyJobDef;
    WrkJobDef                char(10) value;
  end-pi;
  
  dcl-s err                   char(10) inz;
  dcl-s DspErr                char(10) inz;

  callp ClearTopBot05();
  callp ClearDisplay();
  callp Cfg10LoadDsply(WrkJobDef);

//  callp RtvFldLoc('JCSDSP01':'*LIBL':'JCSCPY1':'DSPJOBNAME':DSPEDT1LIN:DSPEDT1COL);

  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xSav:%len(OUTFLINE));
  OUTTITLE2 = centerText(xCopyT3:%len(OUTTITLE2));
  OUTSCNNAME = 'JCSCPY1';
  OLDDESC    = DSPDESC;
  OLDJOBNAME = DSPJOBNAME;
  ATRJOBDESC = cNoAttributes;
  ATRJOBNAME = cNoAttributes;
  callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);

  callp Cfg10LoadDsply(WrkJobDef);
  dow 'W' <> 'N';
    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
    exfmt JCSCPY1;
    if SetCancelLeave;
      leave;
    endif;

    ATRJOBDESC = cNoAttributes;
    ATRJOBNAME = cNoAttributes;
    callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
    DspErr = *Blank;

    if KeyPressed = cKEY_Enter;
      callp Cfg30Load(OLDJOBNAME);
      err = CheckJobName(DspErr);
      err = CheckJobDesc(DspErr);
      err = CheckRunPri(DspErr);
    endif;

    if KeyPressed = cKEY_Enter and DspErr = *Blank;
      C10JOBNAME = DspJobName;
      C10DESC    = DspDesc;
      callp Cfg10NewSave();
      callp Cfg30Save(DspJobName:DSPJOBRUN);
      leave;
    else;
//      callp RtvFldLoc('JCSDSP01':'*LIBL':OUTSCNNAME:DspErr:DSPEDT1LIN:DSPEDT1COL);
    endif;
  enddo;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc NewJobDef;
  dcl-pi NewJobDef;
  end-pi;

  dcl-s CurrScreen#          zoned(1:0) Inz(1);
  dcl-s NumOfPage            zoned(1:0) Inz(3);
  dcl-s DspErr                char(10) inz;

  dcl-s ScreenArray           char(10) Dim(9);
  dcl-s FldScrArray           char(10) Dim(9);
  ScreenArray(1) = 'JCSNEW1';
  ScreenArray(2) = 'JCSNEW2';
  ScreenArray(3) = 'JCSNEW3';
  FldScrArray(1) = 'DSPACTIVE';
  FldScrArray(2) = 'DSPJOBD';
  FldScrArray(3) = 'DSPSYSLIBL';

  callp ClearTopBot05();
  callp ClearDisplay();
//  callp RtvFldLoc('JCSDSP01':'*LIBL':ScreenArray(CurrScreen#):'DSPACTIVE':DSPEDT1LIN:DSPEDT1COL);

  ATRDESC    = cNoAttributes;
  ATRJOBNAME = cNoAttributes;
  ATRJOBRUN  = cNoAttributes;

  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xNtPg +b1+ xPrPg +b1+ xSav : %len(OUTFLINE));

  dow 'W' <> 'N';
    INRUNCLASS = *Blank;
    OUTTITLE2 = centerText(xNewT3 + ' ' + %char(CurrScreen#) + '/' + %char(NumOfPage):%len(OUTTITLE2));
    OutScnName = ScreenArray(CurrScreen#);
    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
    select;
      when CurrScreen# = 1;
        exfmt JCSNEW1;
      when CurrScreen# = 2;
        exfmt JCSNEW2;
      when CurrScreen# = 3;
        exfmt JCSNEW3;
      other;
        exfmt JCSNEW1;
    endsl;
    DspErr     = *Blank;
    callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
    ATRACTIVE  = cNoAttributes;
    ATRDESC    = cNoAttributes;
    ATRJOBNAME = cNoAttributes;
    ATRJOBRUN  = cNoAttributes;
    callp SelectScreen(KeyPressed:CurrScreen#:NumOfPage);
    if SetCancelLeave;
      leave;
    endif;
    if KeyPressed = cKEY_Enter;
      if CheckRunPri(DspErr) <> *Blank;
        CurrScreen# = 2;
      endif;
      if CheckJobDesc(DspErr) <> *Blank;
        CurrScreen# = 1;
      endif;
      if CheckJobName(DspErr) <> *Blank;
        CurrScreen# = 1;
      endif;
      if CheckActive(DspErr) <> *Blank;
        CurrScreen# = 1;
      endif;
      if InRunClass <> *Blank;
        callp ChangeRunClass(DSPCLASSD2);
        DSPCLASSDS = GetClassDesc2(DSPCLASSD2);
        if DspErr = *Blank;
          DspErr = '!!!!!';
        endif;
      endif;
    endif;
    if KeyPressed = cKEY_Enter and DspErr = *Blank;
      callp Cfg10NewSave();
      callp Cfg30Save(DSPJOBNAME:DSPJOBRUN);
      leave;
    endif;
//    callp RtvFldLoc('JCSDSP01':'*LIBL':ScreenArray(CurrScreen#):FldScrArray(CurrScreen#):DSPEDT1LIN:DSPEDT1COL);
  enddo;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc EditJobDef;
  dcl-pi EditJobDef;
    WrkJobDef                 char( 10) value;
  end-pi;

  dcl-s CurrScreen#          zoned(1:0) inz(1);
  dcl-s NumOfPage            zoned(1:0) inz(3);
  dcl-s DspErr                char( 10) inz;

  dcl-s ScreenArray           char( 10) dim(9);
  dcl-s FldScrArray           char( 10) dim(9);
  ScreenArray(1) = 'JCSEDT1';
  ScreenArray(2) = 'JCSEDT2';
  ScreenArray(3) = 'JCSEDT3';
  FldScrArray(1) = 'DSPACTIVE';
  FldScrArray(2) = 'DSPJOBD';
  FldScrArray(3) = 'DSPSYSLIBL';

  callp ClearTopBot05();
//  callp RtvFldLoc('JCSDSP01':'*LIBL':ScreenArray(CurrScreen#):'DSPACTIVE':DSPEDT1LIN:DSPEDT1COL);

  DspErr     = *Blank;
  callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
  ATRACTIVE  = cNoAttributes;
  ATRDESC    = cNoAttributes;
  ATRJOBNAME = cNoAttributes;
  ATRJOBRUN  = cNoAttributes;

  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xNtPg +b1+ xPrPg +b1+ xSav:%len(OUTFLINE));

  callp Cfg10LoadDsply(WrkJobDef);
  callp Cfg30Load(WrkJobDef);

  dow 'W' <> 'N';
    INRUNCLASS = *Blank;
    OUTTITLE2 = centerText(xEdtT3 + ' ' + %char(CurrScreen#) + '/' + %char(NumOfPage):%len(OUTTITLE2));
    OutScnName = ScreenArray(CurrScreen#);
    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
    select;
      when CurrScreen# = 1;
        exfmt JCSEDT1;
      when CurrScreen# = 2;
        exfmt JCSEDT2;
      when CurrScreen# = 3;
        exfmt JCSEDT3;
      other;
        exfmt JCSEDT1;
    endsl;
    callp SelectScreen(KeyPressed:CurrScreen#:NumOfPage);
    if SetCancelLeave;
      leave;
    endif;
//
    DspErr     = *Blank;
    callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
    ATRACTIVE  = cNoAttributes;
    ATRDESC    = cNoAttributes;
    ATRJOBNAME = cNoAttributes;
    ATRJOBRUN  = cNoAttributes;

    if KeyPressed = cKEY_Enter;
      if CheckRunPri(DspErr) <> *Blank;
        CurrScreen# = 2;
      endif;
      if CheckJobDesc(DspErr) <> *Blank;
        CurrScreen# = 1;
      endif;
      if CheckActive(DspErr) <> *Blank;
        CurrScreen# = 1;
      endif;
      if InRunClass <> *Blank;
        callp ChangeRunClass(DSPCLASSD2);
        DSPCLASSDS = GetClassDesc2(DSPCLASSD2);
        if DspErr = *Blank;
          DspErr = '!!!!!';
        endif;
      endif;
    endif;
    if KeyPressed = cKEY_Enter and DspErr = *Blank;
      callp Cfg10UpDate();
      callp Cfg30Save(DSPJOBNAME:DSPJOBRUN);
      leave;
    endif;
//    callp RtvFldLoc('JCSDSP01':'*LIBL':ScreenArray(CurrScreen#):FldScrArray(CurrScreen#):DSPEDT1LIN:DSPEDT1COL);
  enddo;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc DisplayJobDef;
  dcl-pi DisplayJobDef;
    WrkJobDef                char(10) value;
  end-pi;
  dcl-s CurrScreen#          zoned(1:0) Inz(1);
  dcl-s NumOfPage            zoned(1:0) Inz(3);

  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xNtPg +b1+ xPrPg +b1+ xCnt:%len(OUTFLINE));
  callp Cfg10LoadDsply(WrkJobDef);
  callp Cfg30Load(WrkJobDef);
  dow 'W' <> 'N';
    OUTTITLE2 = centerText(xNewT3 + ' ' + %char(CurrScreen#) + '/' + %char(NumOfPage):%len(OUTTITLE2));
    write JCSOVLTOP;
    write JCSOVLBOT;
//  write MsgCtl;
    select;
      when CurrScreen# = 1;
        exfmt JCSDSP1;
      when CurrScreen# = 2;
        exfmt JCSDSP2;
      when CurrScreen# = 3;
        exfmt JCSDSP3;
      other;
        exfmt JCSDSP1;
    endsl;
    callp SelectScreen(KeyPressed:CurrScreen#:NumOfPage);
    if SetCancelLeave;
      leave;
    endif;
    if KeyPressed = cKEY_Enter;
      leave;
    endif;
  enddo;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc Cfg10UpDate;
  dcl-pi Cfg10UpDate;
  end-pi;
  if DSPACTIVE = 'Y';
    C10ACTIVE  = 'A';
  else;
    C10ACTIVE  = 'D';
  endif;
  C10RUNCMD  = DspRUNCMD;
  C10DESC    = DSPDESC;
  C10JOBNAME = DspJOBNAME;
  C10JOBD    = DspJOBD;
  C10JOBDLIB = DspJOBDLIB;
  C10JOBQ    = DspJOBQ;
  C10JOBQLIB = DspJOBQLIB;
  C10JOBPTY  = DspJOBPTY;
  C10OUTPTY  = DspOUTPTY;
  C10PRTDEV  = DspPRTDEV;
  C10OUTQ    = DspOUTQ;
  C10OUTQLIB = DspOUTQLIB;
  C10RUNUSER = DspRUNUSER;
  C10PRTTXT  = DspPRTTXT;
  C10RTGDTA  = DspRTGDTA;
  C10SYSLIBL = DspSYSLIBL;
  C10CURLIB  = DspCURLIB;
  C10INLLIBL = DspINLLIBL;
  C10MSGLOGL = DspMSGLOGL;
  C10MSGLOGS = DspMSGLOGS;
  C10MSGLOGT = DspMSGLOGT;
  C10LOGCLPG = DspLOGCLPG;
  C10INQMSGR = DspINQMSGR;
  C10DSPSBMJ = DspDSPSBMJ;
  C10MSGQ    = DspMSGQ;
  C10MSGQLIB = DspMSGQLIB;
  C10KILLCMD = DspKILLCMD;
  C10RunClas = DSPCLASSD2;
  update JCSCFG10R1;
end-proc;
dcl-proc Cfg10NewSave;
  dcl-pi Cfg10NewSave;
  end-pi;
  if DSPACTIVE = 'Y';
    C10ACTIVE  = 'A';
  else;
    C10ACTIVE  = 'D';
  endif;
  C10RUNCMD  = DspRUNCMD;
  C10DESC    = DSPDESC;
  C10JOBNAME = DspJOBNAME;
  C10JOBD    = DspJOBD;
  C10JOBDLIB = DspJOBDLIB;
  C10JOBQ    = DspJOBQ;
  C10JOBQLIB = DspJOBQLIB;
  C10JOBPTY  = DspJOBPTY;
  C10OUTPTY  = DspOUTPTY;
  C10PRTDEV  = DspPRTDEV;
  C10OUTQ    = DspOUTQ;
  C10OUTQLIB = DspOUTQLIB;
  C10RUNUSER = DspRUNUSER;
  C10PRTTXT  = DspPRTTXT;
  C10RTGDTA  = DspRTGDTA;
  C10SYSLIBL = DspSYSLIBL;
  C10CURLIB  = DspCURLIB;
  C10INLLIBL = DspINLLIBL;
  C10MSGLOGL = DspMSGLOGL;
  C10MSGLOGS = DspMSGLOGS;
  C10MSGLOGT = DspMSGLOGT;
  C10LOGCLPG = DspLOGCLPG;
  C10INQMSGR = DspINQMSGR;
  C10DSPSBMJ = DspDSPSBMJ;
  C10MSGQ    = DspMSGQ;
  C10MSGQLIB = DspMSGQLIB;
  C10KILLCMD = DspKILLCMD;
  C10RunClas = DSPCLASSD2;
  write JCSCFG10R1;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc Cfg10LoadDsply;
  dcl-pi Cfg10LoadDsply;
    WrkJobDef                char(10) value;
  end-pi;

  chain WrkJobDef JCSCFG10R1;
  if %found(JCSCFG10);
    DspRUNCMD  = C10RUNCMD;
    DSPDESC    = C10DESC;
    if C10ACTIVE  = 'A';
      DSPACTIVE  = 'Y';
    else;
      DSPACTIVE  = 'N';
    endif;
    DspJOBNAME = C10JOBNAME;
    DspJOBD    = C10JOBD;
    DspJOBDLIB = C10JOBDLIB;
    DspJOBQ    = C10JOBQ;
    DspJOBQLIB = C10JOBQLIB;
    DspJOBPTY  = C10JOBPTY;
    DspOUTPTY  = C10OUTPTY;
    DspPRTDEV  = C10PRTDEV;
    DspOUTQ    = C10OUTQ;
    DspOUTQLIB = C10OUTQLIB;
    DspRUNUSER = C10RUNUSER;
    DspPRTTXT  = C10PRTTXT;
    DspRTGDTA  = C10RTGDTA;
    DspSYSLIBL = C10SYSLIBL;
    DspCURLIB  = C10CURLIB;
    DspINLLIBL = C10INLLIBL;
    DspMSGLOGL = C10MSGLOGL;
    DspMSGLOGS = C10MSGLOGS;
    DspMSGLOGT = C10MSGLOGT;
    DspLOGCLPG = C10LOGCLPG;
    DspINQMSGR = C10INQMSGR;
    DspDSPSBMJ = C10DSPSBMJ;
    DspMSGQ    = C10MSGQ;
    DspMSGQLIB = C10MSGQLIB;
    DspKILLCMD = C10KILLCMD;
    DSPCLASSDS = GetClassDesc2(C10RunClas);
    DSPCLASSD2 = C10RunClas;
  else;
    DspRUNCMD  = *Blank;
    DSPDESC    = *Blank;
    DSPACTIVE  = *Blank;
    DspJOBNAME = *Blank;
    DspJOBD    = *Blank;
    DspJOBDLIB = *Blank;
    DspJOBQ    = *Blank;
    DspJOBQLIB = *Blank;
    DspJOBPTY  = *Blank;
    DspOUTPTY  = *Blank;
    DspPRTDEV  = *Blank;
    DspOUTQ    = *Blank;
    DspOUTQLIB = *Blank;
    DspRUNUSER = *Blank;
    DspPRTTXT  = *Blank;
    DspRTGDTA  = *Blank;
    DspSYSLIBL = *Blank;
    DspCURLIB  = *Blank;
    DspINLLIBL = *Blank;
    DspMSGLOGL = *Blank;
    DspMSGLOGS = *Blank;
    DspMSGLOGT = *Blank;
    DspLOGCLPG = *Blank;
    DspINQMSGR = *Blank;
    DspDSPSBMJ = *Blank;
    DspMSGQ    = *Blank;
    DspMSGQLIB = *Blank;
    DspKILLCMD = *Blank;
    DSPCLASSDS = *Blank;
    DSPCLASSD2 = *Blank;
  endif;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc ClearDisplay;
  dcl-pi ClearDisplay;
  end-pi;

  callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
  DspRUNCMD  = *Blank;
  DSPDESC    = *Blank;
  DSPACTIVE  = *Blank;
  DspJOBNAME = *Blank;
  DspJOBD    = *Blank;
  DspJOBDLIB = *Blank;
  DspJOBQ    = *Blank;
  DspJOBQLIB = *Blank;
  DspJOBPTY  = *Blank;
  DspOUTPTY  = *Blank;
  DspPRTDEV  = *Blank;
  DspOUTQ    = *Blank;
  DspOUTQLIB = *Blank;
  DspRUNUSER = *Blank;
  DspPRTTXT  = *Blank;
  DspRTGDTA  = *Blank;
  DspSYSLIBL = *Blank;
  DspCURLIB  = *Blank;
  DspINLLIBL = *Blank;
  DspMSGLOGL = *Blank;
  DspMSGLOGS = *Blank;
  DspMSGLOGT = *Blank;
  DspLOGCLPG = *Blank;
  DspINQMSGR = *Blank;
  DspDSPSBMJ = *Blank;
  DspMSGQ    = *Blank;
  DspMSGQLIB = *Blank;
  DspKILLCMD = *Blank;
  DSPCLASSDS = *Blank;
  DSPCLASSD2 = *Blank;

  OLDJOBNAME = *Blank;
  OLDDESC    = *Blank;


end-proc;
//#----------------------------------------------------------------------------
dcl-proc Cfg30Load;
  dcl-pi Cfg30Load;
    WrkJobDef                char(10) value;
  end-pi;

  chain WrkJobDef JCSCFG30R;
  if %found(JCSCFG30L1);
    DSPJOBRUN = C30RUNPTY;
  else;
    DSPJOBRUN = *Blank;
  endif;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc Cfg30Save;
  dcl-pi Cfg30Save;
    WrkJobName               char(10) value;
    WrkJobRunPty             char(5) value;
  end-pi;

  chain WrkJobName JCSCFG30R;
  C30JOBNAME = WrkJobName;
  C30RUNPTY  = WrkJobRunPty;
  if %found(JCSCFG30L1);
    update JCSCFG30R;
  else;
    write JCSCFG30R;
  endif;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc Cfg30UpDate;
  dcl-pi Cfg30UpDate;
    WrkJobName               char(10) value;
    WrkJobRunPty             char(5) value;
  end-pi;

  chain WrkJobName JCSCFG30R;
  if %found(JCSCFG30L1);
    C30RUNPTY = WrkJobRunPty;
    update JCSCFG30R;
  endif;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc Cfg30Rename;
  dcl-pi Cfg30Rename;
    NewJobName               char(10) value;
    OldJobName               char(10) value;
  end-pi;

  chain OldJobName JCSCFG30R;
  C30JOBNAME = NewJobName;
  if %found(JCSCFG30L1);
    update JCSCFG30R;
  else;
    write JCSCFG30R;
  endif;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc Cfg30Delete;
  dcl-pi Cfg30Delete;
    WrkJobDef                char(10) value;
  end-pi;

  chain WrkJobDef JCSCFG30R;
  if %found(JCSCFG30L1);
    delete(E) JCSCFG30R;
  endif;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc CheckRunPri;
  dcl-pi CheckRunPri          char(1);
    DspErr                   char(10);
  end-pi;

  dcl-s Error                 char(1) inz;

  DSPJOBRUN = %upper(DSPJOBRUN);
  if DSPJOBRUN = '*SAME' or DSPJOBRUN = *Blank;
    DSPJOBRUN = '*SAME';
  else;
    if %int(DSPJOBRUN) > 10 and
    %int(DSPJOBRUN) < 100;
      DSPJOBRUN = %char(%int(DSPJOBRUN));
    else;
      DspErr = 'DSPJOBRUN';
      ATRJOBRUN = cYellow_RI;
      callp APIQMHSNDPM(*Blank:msgLoc:'Valid Values *SAME or 11 - 99':50:msgType:msgQueue:msgCallStack:msgKey:Err);
      Error = 'E';
    endif;
  endif;
  return Error;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc CheckJobName;
  dcl-pi CheckJobName         char(1);
    DspErr                   char(10);
  end-pi;

  dcl-s Error                 char(1) inz;

  if DSPJOBNAME = *Blank;
    DspErr = 'DSPJOBNAME';
    ATRJOBNAME = cYellow_RI;
    callp APIQMHSNDPM(*Blank:msgLoc:'Name can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    Error = 'E';
  else;
    chain DSPJOBNAME JCSCFG10;
    if %found(JCSCFG10);
      DspErr = 'DSPJOBNAME';
      ATRJOBNAME = cYellow_RI;
      callp APIQMHSNDPM(*Blank:msgLoc:'Name all ready used.':50:msgType:msgQueue:msgCallStack:msgKey:Err);
      Error = 'E';
    endif;
  endif;
  return Error;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc CheckJobDesc;
  dcl-pi CheckJobDesc         char(1);
    DspErr                   char(10);
  end-pi;

  dcl-s Error                 char(1) inz;

  if DSPDESC = *Blank;
    DspErr = 'DSPDESC';
    ATRDESC = cYellow_RI;
    callp APIQMHSNDPM(*Blank:msgLoc:'Description can not be blank': 50:msgType:msgQueue:msgCallStack:msgKey:Err);
    Error = 'E';
  endif;
  return Error;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc CheckActive;
  dcl-pi CheckActive          char(1);
    DspErr                   char(10);
  end-pi;

  dcl-s Error                 char(1) inz;

  if DSPACTIVE <> 'Y' and DSPACTIVE <> 'N';
    DspErr = 'ATRACTIVE';
    ATRACTIVE = cYellow_RI;
    callp APIQMHSNDPM(*Blank:msgLoc:'Must be Y for Active or N for Deactive': 50:msgType:msgQueue:msgCallStack:msgKey:Err);
    Error = 'E';
  endif;
  return Error;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc CheckJCSJob;                                                 // This gets the main
  dcl-pi CheckJCSJob          char(7);                                //  Jobs status.
  end-pi;

  ATRSTARTED = cWhite;
  ATRSTARTE2 = cWhite;

  chain S10JOBNAM2 JCSWRK10R1;
  callp GetJobInfo0400a(W10LJOBNAM:W10LRUNUSR:W10LJOB#:JCSSTATUS:JCSSTARTED);
  if JCSSTATUS = *blank;
    JCSSTATUS = '*DOWN';
  endif;
  Err = StatusColor(JCSSTATUS:ATRSTATUS);

  chain S10JOBNAM1 JCSWRK10R1;
  callp GetJobInfo0400a(W10LJOBNAM:W10LRUNUSR:W10LJOB#:JCSSTATUS2:JCSSTARTE2);
  if JCSSTATUS = *blank;
    JCSSTATUS = '*DOWN';
  endif;
  Err = StatusColor(JCSSTATUS2:ATRSTATUS2);
  setll *LoVal JCSCFG10R1;
  return *Blank;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc StatusColor;                                                 //   Add color code
  dcl-pi StatusColor          char(7);                                //    based on status
    StringT                  char(10) value;
    StringAtr                char(1);
  end-pi;
  select;
    when StringT = '*ACTIVE';
      StringAtr = cGreen;
    when StringT = '*JOBQ';
      StringAtr = cYellow;
    when StringT = '*OUTQ';
      StringAtr = cYellow;
    when StringT = '*ERROR';
      StringAtr = cRed;
    other;
      StringAtr = cWhite;
  endsl;
  return *Blank;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc GetJCSSettings;
  dcl-pi GetJCSSettings       char(7);
  end-pi;

  read(N) JCSSET10R1;

  return *Blank;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc GetDefault;
  dcl-pi GetDefault           char(50);
    ClassName                 char(10) value;
  end-pi;
  select;
    when %upper(C10ACTIVE) <> 'A';
      return 'Not Monitored  Disabled';
    when C10RUNCLAS = *Blank;
      return 'Runs 24 X 7';
    other;
      chain ClassName JCSCFG20R1;
  endsl;
  return C20DESC;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc GetJobInfo0400a;
  dcl-pi GetJobInfo0400a;
    iJobName                  char(10) value;
    iJobUser                  char(10) value;
    iJobNumber                char( 6) value;
    iJobStatus                char(10);
    iJobDate                  char(26);
  end-pi;
/if defined(comment)
  dcl-s JobType               char( 1);
  dcl-s JobSubType            char( 1);
  dcl-s JobDateEntSys         char(26);
  dcl-s JobDateJobAct         char(26);
  dcl-s JobAcctCose           char(15);
  dcl-s JobDescName           char(10);
  dcl-s JobDescLib            char(10);
  dcl-s JobUnitWorkID         char(24);
  dcl-s JobModeName           char( 8);
  dcl-s JobInqMshReply        char(10);
  dcl-s JobLogClPgms          char(10);
  dcl-s JobBrkMsgHndl         char(10);
  dcl-s JobStatMsgHndl        char(10);
  dcl-s JobDevRcvActin        char(13);
  dcl-s JobDDMCnvtHndl        char(10);
  dcl-s JobDateSeparat        char( 1);
  dcl-s JobDateFmt            char( 4);
  dcl-s JobPrintText          char(30);
  dcl-s JobSubmJobName        char(10);
  dcl-s JobSubmUserNam        char(10);
  dcl-s JobSubmJobNum         char( 6);
  dcl-s JobSubmMsgQueu        char(10);
  dcl-s JobSubmMsgLib         char(10);
  dcl-s JobTimeSeparat        char( 1);
  dcl-s JobCodeCharSet       int(10:0);
  dcl-s JobSchedDateTm        char(26);
  dcl-s JobPrintKeyFmt        char(10);
  dcl-s JobSortSeq            char(10);
  dcl-s JobsortSeqLib         char(10);
  dcl-s JobLangID             char( 3);
  dcl-s JobCountryID          char( 2);
  dcl-s JobCompStatus         char( 1);
  dcl-s JobSignedInJob        char( 1);
  dcl-s JobSwitches           char( 8);
  dcl-s JobMsgqFullAct        char(10);
  dcl-s JobMsgqMaxSize       int(10:0);
  dcl-s JobDegCodeChar       int(10:0);
  dcl-s JobRoutingData        char(80);
  dcl-s JobDeciamlFmt         char( 1);
  dcl-s JobCharIDCntl         char(10);
  dcl-s JobServerType         char(30);


  callp GetJobInfo0400(iJobName                :
         iJobUser                :
         iJobNumber              :
         iJobStatus              :
         JobType                 :
         JobSubType              :
         JobDateEntSys           :
         JobDateJobAct           :
         JobAcctCose             :
         JobDescName             :
         JobDescLib              :
         JobUnitWorkID           :
         JobModeName             :
         JobInqMshReply          :
         JobLogClPgms            :
         JobBrkMsgHndl           :
         JobStatMsgHndl          :
         JobDevRcvActin          :
         JobDDMCnvtHndl          :
         JobDateSeparat          :
         JobDateFmt              :
         JobPrintText            :
         JobSubmJobName          :
         JobSubmUserNam          :
         JobSubmJobNum           :
         JobSubmMsgQueu          :
         JobSubmMsgLib           :
         JobTimeSeparat          :
         JobCodeCharSet          :
         JobSchedDateTm          :
         JobPrintKeyFmt          :
         JobSortSeq              :
         JobsortSeqLib           :
         JobLangID               :
         JobCountryID            :
         JobCompStatus           :
         JobSignedInJob          :
         JobSwitches             :
         JobMsgqFullAct          :
         JobMsgqMaxSize          :
         JobDegCodeChar          :
         JobRoutingData          :
         JobDeciamlFmt           :
         JobCharIDCntl           :
         JobServerType           );
  select;
    when iJobStatus = '*ACTIVE';
      iJobDate = JobDateJobAct;
    when iJobStatus = '*JOBQ';
      iJobDate = JobDateEntSys;
    when iJobStatus = '*OUTQ';
      iJobDate = JobDateEntSys;
    other;
  endsl;
/endIf
end-proc;

/copy cb/jcsmisc_p.rpgle
/copy cb/sendErrorMessageP.rpgle

/copy ../cb_rpgle/text/centerText.rpgle
/copy ../cb_rpgle/jobs/getJobStatus.rpgle

/copy ../cb_rpgle/jobs/buildSubmitJobCommand.rpgle
/copy ../cb_rpgle/generalSystemOsApi/QDFRTVFD.retrieveDisplayFileDescription.rpgle
//Copy QMiscCopy,GETJOBINFP

