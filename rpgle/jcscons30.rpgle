**FREE
/copy ../cb_rpgle/genericHeaders/controlOptions.rpgle
//
//
//  30     Subfile Display Indicator
//  33     Subfile Clear Indicator
//  34     Subfile End Indicator
//  35     Subfile Display Control Indicator
//
//**************************************************************
dcl-f JCSCFG20               Usage(*UPDATE:*DELETE:*OUTPUT) Keyed;
dcl-f JCSDSP03       WORKSTN Infds(JCSSFL02Ds)
                             SFile(JCSSFL02:JCSSFL02RR#);

//Copy QJCSSRC,JCSMISC_D

// Procedure Interface
Dcl-PI *n;
   InClassName           char(10);
End-PI;

/Copy cb/jcsmisc_d2.rpgle

/copy ../cb_rpgle/genericHeaders/programStatusDataStructure.rpgle

/copy ../cb_rpgle/constants/dspfCodes.rpgle
/copy ../cb_rpgle/constants/dspfColors.rpgle
/copy ../cb_rpgle/constants/dspfKeys.rpgle


// Subfile File Level Data Structure
dcl-ds JCSSFL02Ds;
  KeyPressed               Char(1) Pos(369);
    SFLRR#                 BinDec(4:0) Pos(376);                      // RRN of Current Page
    SFLPG#                 BinDec(4:0) Pos(378);                      // Current Page Number
  SFLREC                 BinDec(4:0) Pos(380);                      //// Not Sure Just Yet
end-ds;

dcl-c #RECORDS                  10;                                   // # Recds in Page

dcl-s JCSSFL02RR#         Packed(4:0) Inz;                            // Rel. Rec. Num.
dcl-s JCSSFL02Count       Packed(4:0) Inz;                            // Counter

dcl-s Err                   Char(7);
dcl-s LeaveMain             Char(1) Inz('N');
dcl-s CancelOption          Char(1) Inz('N');

dcl-s IndicatorP         Pointer Inz(%Addr(*In));
dcl-ds Indicators               Based(IndicatorP);
  DisplaySfl                Ind Pos(30);
  DisplayClr                Ind Pos(33);
  DisplayEnd                Ind Pos(34);
  DisplayCTL                Ind Pos(35);
end-ds;



dcl-pr APIQMHSNDPM              ExtPgm('QMHSNDPM');
  PR_MsgID                 Char(7) Const;
  PR_MsgFil                Char(20) Const;
  PR_MsgDta                Char(2048) Const Options(*VarSize);
  PR_MsgDtaLen              Int(10:0) Const;
  PR_MsgTyp                Char(10) Const;
  PR_PgmQ                  Char(256) Const Options(*VarSize);
  PR_MsgLvl                 Int(10:0) Const;
  PR_MsgKey                Char(4);
  PR_APIErr                Char(256) Options(*VarSize);
end-pr;

dcl-pr APIQMHRMVPM              ExtPgm('QMHRMVPM');
  PR_PgmQ                  Char(256) Const Options(*VarSize);
  PR_MsgLvl                 Int(10:0) Const;
  PR_MsgKey                Char(4) Const;
  PR_RmvMsg                Char(10) Const;
  PR_APIErr                Char(256) Options(*VarSize);
end-pr;

dcl-s msgId                 Char(7);
dcl-s msgLoc                Char(20) Inz('TMMMSGF   *LIBL     ');
dcl-s msgRplDta             Char(50) Inz(' ');
dcl-s msgRplDtaLen           Int(10:0) Inz(50);
dcl-s msgType               Char(10) Inz('*DIAG');
dcl-s msgQueue              Char(276) Inz('*');
dcl-s msgCallStack           Int(10:0) Inz(0);
dcl-s msgKey                Char(4) Inz(' ');
dcl-s msgErr                 Int(10:0) Inz(0);
dcl-s msgrmv                Char(10) Inz('*ALL');


msgQueue   = pgmPsds.procedureName;
OUTPGMNAME = pgmPsds.procedureName;
exsr SetScreenColor;
exsr Refresh;

dow LeaveMain = 'N';                                  
  exsr $Display;                                      
  OUTTITLE2  = *Blank;                                
  OUTCMDLINE = *Blank;                                
  OUTFLINE   = *Blank;                                
  select;                                             
    when KeyPressed= cKEY_F03 or KeyPressed= cKEY_F12;
      leave;                                          
    when KeyPressed= cKEY_PageDown;                     
      if Not DisplayEnd;                              
        exsr $Load;                                   
      endif;                                          
    when KeyPressed = cKEY_F06;                       
      callp NewClassDef();                              
      exsr Refresh;                                   
    when KeyPressed = cKEY_F05;                       
      exsr Refresh;                                   
    when KeyPressed = cKEY_Enter;                     
      if JCSSFL02RR# > 0;                             
        exsr $Process;                                
      endif;                                          
    other;                                            
  endsl;                                              
enddo;                                                

*InLr = *On;
//***************************************************************
// Initialize the Subfile
//***************************************************************
begsr $Init;
  JCSSFL02RR# = 0;
  DisplayClr = *On;
  DisplayCtl = *On;
  write JCSCTL02;
  DisplaySfl = *Off;
  DisplayClr = *Off;
  DisplayEnd = *Off;
  callp GetCrrentClass();
endsr;
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
//***************************************************************
// Load the Subfile
//***************************************************************
begsr $Load;
  JCSSFL02Count = 0;
  dow Not DisplayEnd and JCSSFL02Count < #Records;                    
    read JCSCFG20R1;                                                  
    *IN34 = %eof();
    if Not %eof(JCSCFG20);                                            
      CLSOPT        = ' ';                                            
      HIDCLSNAME    = C20RUNCLAS;                                     
      CLSDEC        = C20DESC;                                        
      JCSSFL02RR#   = JCSSFL02RR#   + 1;                              
      JCSSFL02COUNT = JCSSFL02COUNT + 1;                              
      write JCSSFL02;                                                 
    endif;                                                            
  enddo;                                                              
  if JCSSFL02RR# > 0;                                                 
    DisplaySFL = *On;                                                 
  endif;                                                              
  CTL02REC# = JCSSFL02RR#;
endsr;
//***************************************************************
// Display the Subfile
//***************************************************************
begsr $Display;

  if %parms < 1;                                                      
    OUTTITLE1 = centerText(xMaintT1:50);                            //Maint Mode
    OUTFLINE = centerText(xExt +b1+ xRfr +b1+ xNew :%len(OUTFLINE));                        
    OUTCMDLINE = centerText(xEdt +b1+ xCpy +b1+ xDel +b1+ xDsp +b1+ xRen:%len(OUTCMDLINE));                                 
  else;                                                               
    OUTTITLE1 = centerText(xSelectT1:50);                           //Select Mode
    OUTFLINE = centerText(xExt +b1+ xRfr +b1+ xNew +b1+ xCncl:%len(OUTFLINE));                                  
    OUTCMDLINE = centerText(xSelX +b1+ xEdt +b1+ xCpy +b1+ xDsp +b1+ xRen:%len(OUTCMDLINE));                                 
  endif;                                                              
  OUTTITLE2 = centerText(xMainT2:%len(OUTTITLE2));
  OUTSCNNAME = 'JCSCTL02';
  write JCSOVLTOP;
  write JCSOVLBOT;
  //write MsgCtl;
  exfmt JCSCTL02;
  CTL02REC# = SFLPG#;

endsr;
//***************************************************************
// Process the Subfile
//***************************************************************
begsr $Process;
  readc JCSSFL02;
  dow Not %eof;                                                       
    if CLSOPT <> ' ';                                                 
      select;                                                         
        when CLSOPT= 'X' or CLSOPT= 'x';                              
          callp SelectClassDef();                                       
        when CLSOPT= '2';                                             
          callp EditClassDef();                                         
        when CLSOPT= '3';                                             
          callp CopyClassDef();                                         
        when CLSOPT= '4';                                             
          callp DeleteClassDef();                                       
        when CLSOPT= '5';                                             
          callp DisplayClasDef();                                       
        when CLSOPT= '7';                                             
          callp ReNameClassDef();                                       
        other;                                                        
      endsl;                                                          
      CLSOPT = ' ';                                                   
      update JCSSFL02;                                                
      write JCSCTL02;                                                 
    endif;                                                            
    readc JCSSFL02;                                                   
  enddo;                                                              
  if CancelOption = 'N';                                              
    exsr Refresh;                                                     
  endif;                                                              
endsr;
begsr Refresh;
  exsr $Init;
  exsr $Load;
  CancelOption  = 'N';
endsr;
dcl-proc SelectClassDef;
  dcl-pi SelectClassDef;
  end-pi;

  InClassName = HIDCLSNAME;
  LeaveMain   = 'Y';
  CancelOption  = 'Y';

end-proc;
//#----------------------------------------------------------------------------
dcl-proc DisplayClasDef;
  dcl-pi DisplayClasDef;
  end-pi;

  chain HIDCLSNAME JCSCFG20R1;
  OUTSCNNAME = 'JCSDSP1';
  OUTTITLE2 = centerText
  (xDspT2:%len(OUTTITLE2));
  OUTFLINE = centerText(xExt +b1+ xCncl +b1+ xCnt:%len(OUTFLINE));
  CancelOption  = 'Y';

  DSPRUNCLAS = C20RUNCLAS;
  DSPDESC    = C20DESC;
  DSPMON_BEG = MyTime(%char(C20MON_BEG));
  DSPMON_END = MyTime(%char(C20MON_END));
  DSPTUE_BEG = MyTime(%char(C20TUE_BEG));
  DSPTUE_END = MyTime(%char(C20TUE_END));
  DSPWED_BEG = MyTime(%char(C20WED_BEG));
  DSPWED_END = MyTime(%char(C20WED_END));
  DSPTHR_BEG = MyTime(%char(C20THR_BEG));
  DSPTHR_END = MyTime(%char(C20THR_END));
  DSPFRI_BEG = MyTime(%char(C20FRI_BEG));
  DSPFRI_END = MyTime(%char(C20FRI_END));
  DSPSAT_BEG = MyTime(%char(C20SAT_BEG));
  DSPSAT_END = MyTime(%char(C20SAT_END));
  DSPSUN_BEG = MyTime(%char(C20SUN_BEG));
  DSPSUN_END = MyTime(%char(C20SUN_END));

  write JCSOVLTOP;
  write JCSOVLBOT;
  //write MsgCtl;
  exfmt JCSDSP1;

end-proc;
//#----------------------------------------------------------------------------
dcl-proc CopyClassDef;
  dcl-pi CopyClassDef;
  end-pi;
  dcl-s DspErr                Char(10) Inz;
  chain HIDCLSNAME JCSCFG20R1;
  OUTSCNNAME = 'JCSCPY1';
  DSPRUNCLAS = C20RUNCLAS;
  DSPDESC    = C20DESC;
  NewRUNCLAS = *Blank;
  NewDESC    = *Blank;
  ATRRUNCLAS = cNoAttributes;
  ATRDESC    = cNoAttributes;
  OUTTITLE2  = centerText(xCopyT2:%len(OUTTITLE2));
  OUTFLINE   = xExt +b1+ xCncl +b1+ xSav;
  dou 'x' = 'y'                                                       
  ;                                                                   
    write JCSOVLTOP;                                                  
    write JCSOVLBOT;                                                  
    //write MsgCtl;
    exfmt JCSCPY1;                                                    

    ATRRUNCLAS = cNoAttributes;                                       
    ATRDESC    = cNoAttributes;                                       
    callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
    DspErr = *Blank;                                                  

    if KeyPressed= cKEY_F03 or KeyPressed= cKEY_F12;                  
      if KeyPressed= cKEY_F03;                                        
        LeaveMain = 'Y';                                              
      endif;                                                          
      if KeyPressed= cKEY_F12;                                        
        CancelOption  = 'Y';                                          
      endif;                                                          
      leave;                                                          
    endif;                                                            

    if NewDESC = *Blank;                                              
      DspErr = 'NEWDESC';
      ATRDESC = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    ATRDESC                     
///Free
      callp APIQMHSNDPM(*Blank:msgLoc:'Description can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                            
    C20DESC    = DSPDESC;                                             

    if NewRUNCLAS = *Blank;                                           
      DspErr = 'NEWRUNCLAS';
      ATRRUNCLAS = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    ATRRUNCLAS                  
///Free
      callp APIQMHSNDPM(*Blank:msgLoc:'Name can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                            
    C20RUNCLAS = DSPRUNCLAS;                                          

    if DspErr = *Blank and KeyPressed = cKEY_Enter;                   
      chain NewRUNCLAS JCSCFG20R1;                                    
      if %found(JCSCFG20);                                            
        DspErr = 'NEWRUNCLAS';                                        
        callp APIQMHSNDPM(*Blank:msgLoc:'Class name all ready used.':50:msgType:msgQueue:msgCallStack:msgKey:Err);
      else;                                                           
        write JCSCFG20R1;                                             
        leave;                                                        
      endif;                                                          
    else;                                                             
      callp RtvFldLoc('JCSDSP03':'*LIBL':OUTSCNNAME:DspErr:DSPEDT1LIN:DSPEDT1COL);                           
    endif;                                                            

  enddo;                                                             
end-proc;
//#----------------------------------------------------------------------------
dcl-proc DeleteClassDef;
  dcl-pi DeleteClassDef;
  end-pi;
  dcl-s DspErr                Char(10) Inz;
  OUTTITLE2 = centerText
  (xDelT2:%len(OUTTITLE2));
  OUTSCNNAME = 'JCSDLT1';
  OUTFLINE = xExt +b1+ xCncl +b1+ xCnt;
  chain HIDCLSNAME JCSCFG20R1;
  DSPRUNCLAS = C20RUNCLAS;
  DSPDESC    = C20DESC;

  dou 'x' = 'y';                                                      
    write JCSOVLTOP;                                                  
    write JCSOVLBOT;                                                  
    //write MsgCtl;
    exfmt JCSDLT1;                                                    
    if KeyPressed= cKEY_F03 or KeyPressed= cKEY_F12;                  
      if KeyPressed= cKEY_F03;                                        
        LeaveMain = 'Y';                                              
      endif;                                                          
      if KeyPressed= cKEY_F12;                                        
        CancelOption  = 'Y';                                          
      endif;                                                          
      leave;                                                          
    endif;                                                            
    if KeyPressed = cKEY_Enter;                                       
      chain DSPRUNCLAS JCSCFG20R1;                                    
      if %found(JCSCFG20);                                            
        delete JCSCFG20R1;                                            
        leave;                                                        
      endif;                                                          
    endif;                                                            
  enddo;                                                              
end-proc;
//#----------------------------------------------------------------------------
dcl-proc ReNameClassDef;
  dcl-pi ReNameClassDef;
  end-pi;
  dcl-s DspErr                Char(10) Inz;

  OUTTITLE2 = centerText
  (xRenT2:%len(OUTTITLE2));
  OUTSCNNAME = 'JCSCPY1';
  chain HIDCLSNAME JCSCFG20R1;
  DSPRUNCLAS = C20RUNCLAS;
  DSPDESC    = C20DESC;
  NewRUNCLAS = *Blank;
  NewDESC    = C20DESC;
  ATRRUNCLAS = cNoAttributes;
  ATRDESC    = cNoAttributes;
  OUTFLINE = xExt +b1+ xCncl +b1+ xSav;
  callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
  DspErr = *Blank;

  dou 'x' = 'y'                                                       
  ;                                                                   
    write JCSOVLTOP;                                                  
    write JCSOVLBOT;                                                  
    //write MsgCtl;
    exfmt JCSCPY1;                                                    

    if KeyPressed= cKEY_F03 or KeyPressed= cKEY_F12;                  
      if KeyPressed= cKEY_F03;                                        
        LeaveMain = 'Y';                                              
      endif;                                                          
      if KeyPressed= cKEY_F12;                                        
        CancelOption  = 'Y';                                          
      endif;                                                          
      leave;                                                          
    endif;                                                            
    ATRRUNCLAS = cNoAttributes;                                       
    ATRDESC    = cNoAttributes;                                       
    callp APIQMHRMVPM(msgQueue:msgCallStack:msgKey:msgrmv:Err);
    if NewDESC = *Blank;                                              
      DspErr = 'NewDESC';
      ATRDESC = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    ATRDESC                     
///Free
      callp APIQMHSNDPM(*Blank:msgLoc:'Description can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                            

    if NewRUNCLAS = *Blank;                                           
      DspErr = 'NewRUNCLAS';
      ATRRUNCLAS = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    ATRRUNCLAS                  
///Free
      callp APIQMHSNDPM(*Blank:msgLoc:'Name can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                            

    if DspErr = *Blank and KeyPressed = cKEY_Enter;                   
      chain NewRUNCLAS JCSCFG20R1;                                    
      if %found(JCSCFG20);                                            
        callp APIQMHSNDPM(*Blank:msgLoc:'Class name all ready used.':50:msgType:msgQueue:msgCallStack:msgKey:Err);
        DspErr = 'NewRUNCLAS';                                        
        callp RtvFldLoc('JCSDSP03':'*LIBL':OUTSCNNAME:DspErr:DSPEDT1LIN:DSPEDT1COL);                         
        NewRUNCLAS = *Blank;                                          
      else;                                                           
        chain DSPRUNCLAS JCSCFG20R1;                                  
        C20DESC    = NewDESC;                                         
        C20RUNCLAS = NewRUNCLAS;                                      
        update JCSCFG20R1;                                            
        leave;                                                        
      endif;                                                          
    endif;                                                            
  enddo;                                                              
end-proc;
//#----------------------------------------------------------------------------
dcl-proc NewClassDef;
  dcl-pi NewClassDef;
  end-pi;

  dcl-s DspErr                Char(10) Inz;
  OUTTITLE2 =
  centerText(xNewT2:%len(OUTTITLE2));
  OUTSCNNAME = 'JCSEDT1';
  C20RUNCLAS = *Blank;
  C20DESC    = *Blank;
  C20MON_BEG = 0;
  C20MON_END = 0;
  C20TUE_BEG = 0;
  C20TUE_END = 0;
  C20WED_BEG = 0;
  C20WED_END = 0;
  C20THR_BEG = 0;
  C20THR_END = 0;
  C20FRI_BEG = 0;
  C20FRI_END = 0;
  C20SAT_BEG = 0;
  C20SAT_END = 0;
  C20SUN_BEG = 0;
  C20SUN_END = 0;
  ATRRUNCLAS = cNoAttributes;
  ATRDESC    = cNoAttributes;
  ATRMON_BEG = cNoAttributes;
  ATRMON_END = cNoAttributes;
  ATRTUE_BEG = cNoAttributes;
  ATRTUE_END = cNoAttributes;
  ATRWED_BEG = cNoAttributes;
  ATRWED_END = cNoAttributes;
  ATRTHR_BEG = cNoAttributes;
  ATRTHR_END = cNoAttributes;
  ATRFRI_BEG = cNoAttributes;
  ATRFRI_END = cNoAttributes;
  ATRSAT_BEG = cNoAttributes;
  ATRSAT_END = cNoAttributes;
  ATRSUN_BEG = cNoAttributes;
  ATRSUN_END = cNoAttributes;
  OUTFLINE = xExt +b1+ xCncl +b1+ xSav;

  dou 'x' = 'y'                                                       
  ;                                                                   
    DSPRUNCLAS = C20RUNCLAS;                                          
    DSPDESC    = C20DESC;                                             
    DSPMON_BEG = MyTime(%char(C20MON_BEG));                           
    DSPMON_END = MyTime(%char(C20MON_END));                           
    DSPTUE_BEG = MyTime(%char(C20TUE_BEG));                           
    DSPTUE_END = MyTime(%char(C20TUE_END));                           
    DSPWED_BEG = MyTime(%char(C20WED_BEG));                           
    DSPWED_END = MyTime(%char(C20WED_END));                           
    DSPTHR_BEG = MyTime(%char(C20THR_BEG));                           
    DSPTHR_END = MyTime(%char(C20THR_END));                           
    DSPFRI_BEG = MyTime(%char(C20FRI_BEG));                           
    DSPFRI_END = MyTime(%char(C20FRI_END));                           
    DSPSAT_BEG = MyTime(%char(C20SAT_BEG));                           
    DSPSAT_END = MyTime(%char(C20SAT_END));                           
    DSPSUN_BEG = MyTime(%char(C20SUN_BEG));                           
    DSPSUN_END = MyTime(%char(C20SUN_END));                           

    write JCSOVLTOP;                                                  
    write JCSOVLBOT;                                                  
    //write MsgCtl;
    exfmt JCSEDT1;                                                    

    ATRRUNCLAS = cNoAttributes;                                       
    ATRDESC    = cNoAttributes;                                       
    ATRMON_BEG = cNoAttributes;                                       
    ATRMON_END = cNoAttributes;                                       
    ATRTUE_BEG = cNoAttributes;                                       
    ATRTUE_END = cNoAttributes;                                       
    ATRWED_BEG = cNoAttributes;                                       
    ATRWED_END = cNoAttributes;                                       
    ATRTHR_BEG = cNoAttributes;                                       
    ATRTHR_END = cNoAttributes;                                       
    ATRFRI_BEG = cNoAttributes;                                       
    ATRFRI_END = cNoAttributes;                                       
    ATRSAT_BEG = cNoAttributes;                                       
    ATRSAT_END = cNoAttributes;                                       
    ATRSUN_BEG = cNoAttributes;                                       
    ATRSUN_END = cNoAttributes;                                       
    callp APIQMHRMVPM                                                 
           (msgQueue:msgCallStack:msgKey:msgrmv:Err);
    DspErr = *Blank;                                                  

    if KeyPressed= cKEY_F03 or KeyPressed= cKEY_F12;                  
      if KeyPressed= cKEY_F03;                                        
        LeaveMain = 'Y';                                              
      endif;                                                          
      if KeyPressed= cKEY_F12;                                        
        CancelOption  = 'Y';                                          
      endif;                                                          
      leave;                                                          
    endif;                                                            

    C20SUN_END = CheckMyTime                                          
    (DSPSUN_END:'DSPSUN_END':ATRSUN_END:DspErr);                      
    C20SUN_BEG = CheckMyTime                                          
    (DSPSUN_BEG:'DSPSUN_BEG':ATRSUN_BEG:DspErr);                      
    C20SAT_END = CheckMyTime                                          
    (DSPSAT_END:'DSPSAT_END':ATRSAT_END:DspErr);                      
    C20SAT_BEG = CheckMyTime                                          
    (DSPSAT_BEG:'DSPSAT_BEG':ATRSAT_BEG:DspErr);                      
    C20FRI_END = CheckMyTime                                          
    (DSPFRI_END:'DSPFRI_END':ATRFRI_END:DspErr);                      
    C20FRI_BEG = CheckMyTime                                          
    (DSPFRI_BEG:'DSPFRI_BEG':ATRFRI_BEG:DspErr);                      
    C20THR_END = CheckMyTime                                          
    (DSPTHR_END:'DSPTHR_END':ATRTHR_END:DspErr);                      
    C20THR_BEG = CheckMyTime                                          
    (DSPTHR_BEG:'DSPTHR_BEG':ATRTHR_BEG:DspErr);                      
    C20WED_END = CheckMyTime                                          
    (DSPWED_END:'DSPWED_END':ATRWED_END:DspErr);                      
    C20WED_BEG = CheckMyTime                                          
    (DSPWED_BEG:'DSPWED_BEG':ATRWED_BEG:DspErr);                      
    C20TUE_END = CheckMyTime                                          
    (DSPTUE_END:'DSPTUE_END':ATRTUE_END:DspErr);                      
    C20TUE_END = CheckMyTime                                          
    (DSPTUE_END:'DSPTUE_END':ATRTUE_END:DspErr);                      
    C20TUE_BEG = CheckMyTime                                          
    (DSPTUE_BEG:'DSPTUE_BEG':ATRTUE_BEG:DspErr);                      
    C20MON_END = CheckMyTime                                          
    (DSPMON_END:'DSPMON_END':ATRMON_END:DspErr);                      
    C20MON_BEG = CheckMyTime                                          
    (DSPMON_BEG:'DSPMON_BEG':ATRMON_BEG:DspErr);                      

    if DspErr <> *Blank;                                              
      callp APIQMHSNDPM(*Blank:msgLoc:'Bad Time. Must be 0000 or greator and less than 2360.':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                            

    if DSPDESC = *Blank;                                              
      DspErr = 'DSPDESC';
      ATRDESC = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    ATRDESC                     
///Free
      callp APIQMHSNDPM(*Blank:msgLoc:'Description can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                            
    C20DESC    = DSPDESC;                                             

    if DSPRUNCLAS = *Blank;                                           
      DspErr = 'DSPRUNCLAS';
      ATRRUNCLAS = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    ATRRUNCLAS                  
///Free
      callp APIQMHSNDPM(*Blank:msgLoc:'Name can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                            
    C20RUNCLAS = DSPRUNCLAS;                                          

    if DspErr = *Blank and KeyPressed = cKEY_Enter;                   
      write JCSCFG20R1;                                               
      leave;                                                          
    else;                                                             
      callp RtvFldLoc('JCSDSP03':'*LIBL':OUTSCNNAME:DspErr:DSPEDT1LIN:DSPEDT1COL);                           
    endif;                                                            

  enddo;                                                              
end-proc;
//#----------------------------------------------------------------------------
dcl-proc EditClassDef;
  dcl-pi EditClassDef;
  end-pi;

  dcl-s DspErr                Char(10) Inz;

  OUTTITLE2 =
  centerText(xEdtT2:%len(OUTTITLE2));
  OUTSCNNAME = 'JCSEDT1';
  C20RUNCLAS = *Blank;
  C20DESC    = *Blank;
  C20MON_BEG = 0;
  C20MON_END = 0;
  C20TUE_BEG = 0;
  C20TUE_END = 0;
  C20WED_BEG = 0;
  C20WED_END = 0;
  C20THR_BEG = 0;
  C20THR_END = 0;
  C20FRI_BEG = 0;
  C20FRI_END = 0;
  C20SAT_BEG = 0;
  C20SAT_END = 0;
  C20SUN_BEG = 0;
  C20SUN_END = 0;
  ATRRUNCLAS = cNoAttributes;
  ATRDESC    = cNoAttributes;
  ATRMON_BEG = cNoAttributes;
  ATRMON_END = cNoAttributes;
  ATRTUE_BEG = cNoAttributes;
  ATRTUE_END = cNoAttributes;
  ATRWED_BEG = cNoAttributes;
  ATRWED_END = cNoAttributes;
  ATRTHR_BEG = cNoAttributes;
  ATRTHR_END = cNoAttributes;
  ATRFRI_BEG = cNoAttributes;
  ATRFRI_END = cNoAttributes;
  ATRSAT_BEG = cNoAttributes;
  ATRSAT_END = cNoAttributes;
  ATRSUN_BEG = cNoAttributes;
  ATRSUN_END = cNoAttributes;
  OUTFLINE = xExt +b1+ xCncl +b1+ xSav;
  chain HIDCLSNAME JCSCFG20R1;
  dou 'x' = 'y'                                                       
  ;                                                                   
    DSPRUNCLAS = C20RUNCLAS;                                          
    DSPDESC    = C20DESC;                                             
    DSPMON_BEG = MyTime(%char(C20MON_BEG));                           
    DSPMON_END = MyTime(%char(C20MON_END));                           
    DSPTUE_BEG = MyTime(%char(C20TUE_BEG));                           
    DSPTUE_END = MyTime(%char(C20TUE_END));                           
    DSPWED_BEG = MyTime(%char(C20WED_BEG));                           
    DSPWED_END = MyTime(%char(C20WED_END));                           
    DSPTHR_BEG = MyTime(%char(C20THR_BEG));                           
    DSPTHR_END = MyTime(%char(C20THR_END));                           
    DSPFRI_BEG = MyTime(%char(C20FRI_BEG));                           
    DSPFRI_END = MyTime(%char(C20FRI_END));                           
    DSPSAT_BEG = MyTime(%char(C20SAT_BEG));                           
    DSPSAT_END = MyTime(%char(C20SAT_END));                           
    DSPSUN_BEG = MyTime(%char(C20SUN_BEG));                           
    DSPSUN_END = MyTime(%char(C20SUN_END));                           

    write JCSOVLTOP;                                                  
    write JCSOVLBOT;                                                  
    //write MsgCtl;
    exfmt JCSEDT1;                                                    

    ATRRUNCLAS = cNoAttributes;                                      
    ATRDESC    = cNoAttributes;                                      
    ATRMON_BEG = cNoAttributes;                                      
    ATRMON_END = cNoAttributes;                                      
    ATRTUE_BEG = cNoAttributes;                                      
    ATRTUE_END = cNoAttributes;                                      
    ATRWED_BEG = cNoAttributes;                                      
    ATRWED_END = cNoAttributes;                                      
    ATRTHR_BEG = cNoAttributes;                                      
    ATRTHR_END = cNoAttributes;                                      
    ATRFRI_BEG = cNoAttributes;                                      
    ATRFRI_END = cNoAttributes;                                      
    ATRSAT_BEG = cNoAttributes;                                      
    ATRSAT_END = cNoAttributes;                                      
    ATRSUN_BEG = cNoAttributes;                                      
    ATRSUN_END = cNoAttributes;                                      
    callp APIQMHRMVPM                                                
           (msgQueue:msgCallStack:msgKey:msgrmv:Err);
    DspErr = *Blank;                                                 

    if KeyPressed= cKEY_F03 or KeyPressed= cKEY_F12;                 
      if KeyPressed= cKEY_F03;                                        
        LeaveMain = 'Y';                                              
      endif;                                                          
      if KeyPressed= cKEY_F12;                                        
        CancelOption  = 'Y';                                          
      endif;                                                          
      leave;                                                          
    endif;                                                            

    C20SUN_END = CheckMyTime                                          
    (DSPSUN_END:'DSPSUN_END':ATRSUN_END:DspErr);                      
    C20SUN_BEG = CheckMyTime                                          
    (DSPSUN_BEG:'DSPSUN_BEG':ATRSUN_BEG:DspErr);                      
    C20SAT_END = CheckMyTime                                          
    (DSPSAT_END:'DSPSAT_END':ATRSAT_END:DspErr);                      
    C20SAT_BEG = CheckMyTime                                          
    (DSPSAT_BEG:'DSPSAT_BEG':ATRSAT_BEG:DspErr);                      
    C20FRI_END = CheckMyTime                                          
    (DSPFRI_END:'DSPFRI_END':ATRFRI_END:DspErr);                      
    C20FRI_BEG = CheckMyTime                                          
    (DSPFRI_BEG:'DSPFRI_BEG':ATRFRI_BEG:DspErr);                      
    C20THR_END = CheckMyTime                                          
    (DSPTHR_END:'DSPTHR_END':ATRTHR_END:DspErr);                      
    C20THR_BEG = CheckMyTime                                         
    (DSPTHR_BEG:'DSPTHR_BEG':ATRTHR_BEG:DspErr);                     
    C20WED_END = CheckMyTime                                         
    (DSPWED_END:'DSPWED_END':ATRWED_END:DspErr);                     
    C20WED_BEG = CheckMyTime                                         
    (DSPWED_BEG:'DSPWED_BEG':ATRWED_BEG:DspErr);                     
    C20TUE_END = CheckMyTime                                         
    (DSPTUE_END:'DSPTUE_END':ATRTUE_END:DspErr);                     
    C20TUE_END = CheckMyTime                                         
    (DSPTUE_END:'DSPTUE_END':ATRTUE_END:DspErr);                     
    C20TUE_BEG = CheckMyTime                                         
    (DSPTUE_BEG:'DSPTUE_BEG':ATRTUE_BEG:DspErr);                     
    C20MON_END = CheckMyTime                                         
    (DSPMON_END:'DSPMON_END':ATRMON_END:DspErr);                     
    C20MON_BEG = CheckMyTime                                         
    (DSPMON_BEG:'DSPMON_BEG':ATRMON_BEG:DspErr);                     

    if DspErr <> *Blank;                                             
      callp APIQMHSNDPM(*Blank:msgLoc:'Bad Time. Must be 0000 or greator and less than 2360.':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                           

    if DSPDESC = *Blank;                                             
      DspErr = 'DSPDESC';
      ATRDESC = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    ATRDESC                    
///Free
      callp APIQMHSNDPM(*Blank:msgLoc:'Description can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                           
    C20DESC    = DSPDESC;                                            

    if DSPRUNCLAS = *Blank;                                          
      DspErr = 'DSPRUNCLAS';
      ATRRUNCLAS = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    ATRRUNCLAS                 
///Free
      callp APIQMHSNDPM(*Blank:msgLoc:'Name can not be blank':50:msgType:msgQueue:msgCallStack:msgKey:Err);
    endif;                                                          
    C20RUNCLAS = DSPRUNCLAS;                                        

    if DspErr = *Blank and KeyPressed = cKEY_Enter;                 
      update JCSCFG20R1;                                            
      leave;                                                        
    else;                                                           
      callp RtvFldLoc('JCSDSP03':'*LIBL':OUTSCNNAME:DspErr:DSPEDT1LIN:DSPEDT1COL);                         
    endif;                                                          

  enddo;                                                            
end-proc;
//#----------------------------------------------------------------------------
dcl-proc CheckMyTime;
  dcl-pi CheckMyTime         Zoned(4:0);
    MyTime                   Char(5) Value;
    MyFldName                Char(10) Value;
    MyAttribute              Char(1);
    MyErrName                Char(10);
  end-pi;

  MyTime = removeString(MyTime:':');


  if (%int(%subst(MyTime:1:2)) > -1 and %int(%subst(MyTime:1:2)) < 24     ) and // Check Hour                            
     (%int(%subst(MyTime:3:2)) > -1 and %int(%subst(MyTime:3:2)) < 60     );     // Check Minet
    MyAttribute = cNoAttributes;                                      
  else;
    MyAttribute = cYellow_RI;
///End-Free
// >>>>> Not converted: Conversion not currently supported.
//                  BitOn     cYellow_RI    MyAttribute                 
///Free
    MyErrName = MyFldName;                                            
  endif;                                                              

  return %int(%subst(MyTime:1:4));
end-proc;
//#----------------------------------------------------------------------------
dcl-proc Mytime;
  dcl-pi MyTime               Char(5);
    Time                     Char(4) Value;
  end-pi;
//==========================================================================================
// Start of moved field definitions.
//==========================================================================================
//dcl-s 2) + '              Packed(bst(T:im);       // Not sure why this is added
//==========================================================================================
// End of moved field definitions.
//==========================================================================================

  evalr Time = %trim(Time);

  if %subst(Time:1:1) = *Blank;
    Time = %replace('0':Time:1:1);
  endif;
  if %subst(Time:2:1) = *Blank;
    Time = %replace('0':Time:2:1);
  endif;
  if %subst(Time:3:1) = *Blank;
    Time = %replace('0':Time:3:1);
  endif;
  if %subst(Time:4:1) = *Blank;
    Time = %replace('0':Time:4:1);
  endif;
  return %subst(Time:1:2) + ':' + %subst(Time:3:2);
end-proc;
//#----------------------------------------------------------------------------
dcl-proc GetCrrentClass;
  dcl-pi GetCrrentClass;
  end-pi;
  if pgmPsds.numberOfParms > 0;                                                    
    chain InClassName JCSCFG20R1;                                     
    CLSCURDES = C20DESC;                                              
  endif;                                                              
  setll *LoVal JCSCFG20R1;
end-proc;


/copy ../cb_rpgle/text/centerText.rpgle
/copy ../cb_rpgle/text/removeString.rpgle
/copy ../cb_rpgle/generalSystemOsApi/QDFRTVFD.retrieveDisplayFileDescription.rpgle