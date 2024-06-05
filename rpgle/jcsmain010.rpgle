**FREE
/copy ../cb_rpgle/genericHeaders/controlOptions.rpgle
//
// Starts and maked sure jcsmain020 is running.
//
//***************************************************************
dcl-f JCSSET10               UsrOpn;// qualified;
dcl-f JCSCFG10               Keyed UsrOpn;
dcl-f JCSCFG20               Keyed UsrOpn;
dcl-f JCSWRK10               Usage(*UPDATE:*DELETE:*OUTPUT) Keyed UsrOpn;

dcl-pi *n;
  runStatus               char(   1); // 0 if program is to end.
end-pi;

/copy cb/jcsmisc_d.rpgle
/copy ../cb_rpgle/genericHeaders/programStatusDataStructure.rpgle

/copy ../cb_rpgle/generalSystemOsHeaders/apiFormatERRC0100.rpgle

//dcl-ds ds_set10 likerec(JCSSET10.JCSSET10R1:*input) template;
dcl-s Err                 char(   7) inz;
dcl-s JobStatus           char(  10) inz;
dcl-s CurrentDate         date       inz;
dcl-ds *n;
  CurrentTime6            zoned(6:0);
  CurrentTime             zoned(4:0) Overlay(CurrentTime6);
end-ds;

dcl-c SERVICENAME               'Job Contol Service: ';

exsr inzVars;

exsr openFiles;

exsr main;

exsr closeFiles;

*inLR = *On;
//#----------------------------------------------------------------------------
begsr inzVars;
endsr;
//#----------------------------------------------------------------------------
begsr openFiles;
  if Not %open(JCSSET10);
    open JCSSET10;
  endif;
  if Not %open(JCSCFG10);
    open JCSCFG10;
  endif;
  if Not %open(JCSCFG20);
    open JCSCFG20;
  endif;
  if Not %open(JCSWRK10);
    open JCSWRK10;
  endif;
endsr;
//#----------------------------------------------------------------------------
begsr closeFiles;
  if %open(JCSSET10);
    close JCSSET10;
  endif;
  if %open(JCSCFG10);
    close JCSCFG10;
  endif;
  if %open(JCSCFG20);
    close JCSCFG20;
  endif;
  if %open(JCSWRK10);
    close JCSWRK10;
  endif;
endsr;
//#----------------------------------------------------------------------------
begsr main;
  dow 'Bender' <> 'Nice';
    exsr openFiles;
    exsr setDefaults;
    read JCSSET10R1;
    if not %eof(JCSSET10);
      exsr checkJobs;
    else;
      Err = sendErrMessage(ServiceName  + 'Missing settings in JCSSET10 File.':'Y');
      leave;
    endif;
    exsr closeFiles;
    exsr checkLeave;
    if runStatus = '0' Or intLeave = 'Y';
      leave;
    endif;
    Err = %char(Sleep(S10SLEEPTM));
    exsr CheckLeave;
    if runStatus = '0' Or intLeave = 'Y';
      leave;
    endif;
  enddo;

  Err = SendErrMessage(ServiceName + 'System Shutting down.':S10MSGSTR);
endsr;
//#----------------------------------------------------------------------------
begsr checkJobs;
  chain S10JOBNAM2 JCSCFG10R1;
  if %found(JCSCFG10);
    if C10RUNCLAS <> *Blank;
      chain C10RUNCLAS JCSCFG20R1;
      if %found(JCSCFG20);
        select;
          when dayOfTheWeek() = 1;
            IntBeg = C20MON_BEG;
            IntEnd = C20MON_END;
          when dayOfTheWeek() = 2;
            IntBeg = C20TUE_BEG;
            IntEnd = C20TUE_END;
          when dayOfTheWeek() = 3;
            IntBeg = C20WED_BEG;
            IntEnd = C20WED_END;
          when dayOfTheWeek() = 4;
            IntBeg = C20THR_BEG;
            IntEnd = C20THR_END;
          when dayOfTheWeek() = 5;
            IntBeg = C20FRI_BEG;
            IntEnd = C20FRI_END;
          when dayOfTheWeek() = 6;
            IntBeg = C20SAT_BEG;
            IntEnd = C20SAT_END;
          when dayOfTheWeek() = 7;
            IntBeg = C20SUN_BEG;
            IntEnd = C20SUN_END;
          other;
            IntBeg = DefBeg;
            IntEnd = DefEnd;
        endsl;
      else;
        IntBeg = DefBeg;
        IntEnd = DefEnd;
      endif;
    else;
      IntBeg = DefBeg;
      IntEnd = DefEnd;
    endif;
    exsr setJobCheck;
  endif;

endsr;
//#----------------------------------------------------------------------------
begsr checkStop;
//  This job will only start the monitor.
/Define CheckStop
endsr;
//#----------------------------------------------------------------------------
begsr checkLeave;

  intLeaveType = '*LIBL';
//  callp SMIS05CL(IntLeaveType:LeaveDataArea);

  select;
    when intLeaveType = 'END   '; // End only self
      intLeave = 'Y';
    when intLeaveType = 'ENDALL'; // End only self
      intLeave = 'Y';
    other;                        // Do nothing
  endsl;
endsr;

/copy cb/jcsmisc_c.rpgle
/copy cb/jcsmisc_p.rpgle

//COPY QMISCCOPY,GETDAY_P
//COPY QMISCCOPY,GETTIME_P


//COPY QMISCCOPY,ESCQUOTE_P


/copy cb/sendErrorMessageP.rpgle
/copy ../cb_rpgle/dateTime/dayOfTheWeek.rpgle
/copy ../cb_rpgle/jobs/getJobStatus.rpgle

/copy ../cb_rpgle/jobs/buildSubmitJobCommand.rpgle
