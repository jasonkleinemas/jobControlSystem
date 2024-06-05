**FREE
/COPY QMISCCOPY,HSPEC_H
//
// Controls all the jobs.
//
//***************************************************************
dcl-f JCSSET10               Keyed UsrOpn;
dcl-f JCSCFG10L2             Keyed UsrOpn;
dcl-f JCSCFG20               Keyed UsrOpn;
dcl-f JCSWRK10               Usage(*UPDATE:*DELETE:*OUTPUT) Keyed UsrOpn;
/COPY QMISCCOPY,CPPRINTLOF


// Prototypes
dcl-pr SMIS05CL ExtPgm('SMIS05CL');
   IntLeaveType              like(IntLeaveType);
   LeaveDataArea             like(LeaveDataArea);
end-pr;

/COPY QSJCSRC,JCSMISC_D
/COPY QSJCSRC,SNDERRMSGD
/COPY QMISCCOPY,CPATOI
/COPY QMISCCOPY,CPPSDS
/COPY QMISCCOPY,CPSLEEP
/COPY QMISCCOPY,GETDAY_D
/COPY QMISCCOPY,GETTIME_D
/COPY QMISCCOPY,STRTOUPPED
/COPY QMISCCOPY,WRITE0000D
/COPY QMISCCOPY,GETJOBSTSD
/COPY QMISCCOPY,CPPRINTLOD
/COPY QMISCCOPY,BLDSBMJOBD
/COPY QMISCCOPY,ESCQUOTE_D


dcl-s Err                   Char(7) Inz;
dcl-s JobStatus             Char(10) Inz;
dcl-s CurrentDate           Date Inz;
dcl-ds *N;
  CurrentTime6            Zoned(6:0);
  CurrentTime             Zoned(4:0) Overlay(CurrentTime6);
end-ds;

dcl-c SERVICENAME               'Job Contol Service: ';

exsr InzVars;

exsr OpenFiles;

exsr Main;

exsr CloseFiles;

*InLR = *on;

begsr InzVars;
endsr;
//#----------------------------------------------------------------------------
begsr OpenFiles;
  if Not %open(JCSSET10);  
    open JCSSET10;         
  endif;                   
  if Not %open(JCSCFG10L2);
    open JCSCFG10L2;       
  endif;                   
  if Not %open(JCSCFG20);  
    open JCSCFG20;         
  endif;                   
  if Not %open(JCSWRK10);  
    open JCSWRK10;         
  endif;                   
endsr;
//#----------------------------------------------------------------------------
begsr CloseFiles;
  if %open(JCSSET10);  
    close JCSSET10;    
  endif;               
  if %open(JCSCFG10L2);
    close JCSCFG10L2;  
  endif;               
  if %open(JCSCFG20);  
    close JCSCFG20;    
  endif;               
  if %open(JCSWRK10);  
    close JCSWRK10;    
  endif;               
endsr;
//#----------------------------------------------------------------------------
begsr Main;
  dow 'Bender' <> 'Nice';                       
    exsr OpenFiles;                             
    exsr SetDefaults;                           
    read JCSSET10R1;                            
    if S10PRTMSG = 'Y' or S10PRTMSG = 'y';      
      if Not %open(Qsysprt);                    
        open Qsysprt;                           
      endif;                                    
    endif;                                      
    if Not %eof(JCSSET10);                      
      exsr CheckJobs;                           
    else;                                       
      Err = SendErrMessage(ServiceName + 'Missing settings in JCSSET10 File.':'Y');
      leave;                                    
    endif;                                      
    exsr CloseFiles;                            
    exsr CheckLeave;                            
    if IntLeave = 'Y';                          
      leave;                                    
    endif;                                      
    Err = %char(Sleep(S10SLEEPTM));             
    exsr CheckLeave;                            
    if IntLeave = 'Y';                          
      leave;                                    
    endif;                                      
  enddo;                                        

  Err = SendErrMessage(ServiceName + 'System Shutting down.':S10MSGSTR);
endsr;
//#----------------------------------------------------------------------------
begsr CheckJobs;
  setll *LoVal JCSCFG10R1;
  read JCSCFG10R1;
  dow Not %eof(JCSCFG10L2);                       
    if C10JOBNAME <> S10JOBNAM2;                  
      if C10ACTIVE = 'A' or C10ACTIVE = 'a';      
        if C10RUNCLAS <> *Blank;                  
          chain C10RUNCLAS JCSCFG20R1;            
          if %found(JCSCFG20);                    
            CurrentDate = %dec(%time());          
            select;                               
              when GetDayOfWeek(CurrentDate) = 1; 
                IntBeg = C20MON_BEG;              
                IntEnd = C20MON_END;              
              when GetDayOfWeek(CurrentDate) = 2; 
                IntBeg = C20TUE_BEG;              
                IntEnd = C20TUE_END;              
              when GetDayOfWeek(CurrentDate) = 3; 
                IntBeg = C20WED_BEG;              
                IntEnd = C20WED_END;              
              when GetDayOfWeek(CurrentDate) = 4; 
                IntBeg = C20THR_BEG;              
                IntEnd = C20THR_END;              
              when GetDayOfWeek(CurrentDate) = 5; 
                IntBeg = C20FRI_BEG;              
                IntEnd = C20FRI_END;              
              when GetDayOfWeek(CurrentDate) = 6; 
                IntBeg = C20SAT_BEG;              
                IntEnd = C20SAT_END;              
              when GetDayOfWeek(CurrentDate) = 7; 
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
        exsr SetJobCheck;       
      endif;                    
    endif;                      
    read JCSCFG10R1;            
  enddo;                        

endsr;
//#----------------------------------------------------------------------------
begsr CheckLeave;
  IntLeaveType = '*LIBL';
  callp SMIS05CL(IntLeaveType:LeaveDataArea);
  select;                                          
    when IntLeaveType = 'END   ';                   //End the monitor
      IntLeave = 'Y';                              
    when IntLeaveType = 'ENDALL';                   //End all 'A' ative jobs
      IntLeave = 'Y';                              
    other;                                          //Do nothing
  endsl;                                           
  if IntLeaveType <> *Blank;                   
    Err = SendErrMessage(ServiceName + 'Sevice ending with ' + %trim(IntLeaveType):S10MSGSTR);                               
    exsr OpenFiles;                            
    read JCSSET10R1;                           
    if S10PRTMSG = 'Y' or S10PRTMSG = 'y';     
      if Not %open(Qsysprt);                   
        open Qsysprt;                          
      endif;                                   
    endif;                                     
    if Not %eof(JCSSET10);                     
      exsr CheckJobs;                          
    endif;                                     
    exsr CloseFiles;                           
  endif;                                       
endsr;

/COPY QSJCSRC,JCSMISC_C

/COPY QMISCCOPY,CPPRINTLOO

/COPY QSJCSRC,JCSMISC_P
/COPY QSJCSRC,SNDERRMSGP
/COPY QMISCCOPY,GETDAY_P
/COPY QMISCCOPY,GETTIME_P
/COPY QMISCCOPY,STRTOUPPEP
/COPY QMISCCOPY,WRITE0000P
/COPY QMISCCOPY,GETJOBSTSP
/COPY QMISCCOPY,CPPRINTLOP
/COPY QMISCCOPY,BLDSBMJOBP
/COPY QMISCCOPY,ESCQUOTE_P

