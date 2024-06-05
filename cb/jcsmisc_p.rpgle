**FREE
dcl-proc SetString;
  dcl-pi SetString            char(50);
    NewVal                    char(50) value;
    OldVal                    char(50) value;
  end-pi;

  dcl-s RetVal                char(50) inz;

  if NewVal <> *Blank;
    RetVal = NewVal;
  else;
    RetVal = OldVal;
  endif;

  return RetVal;
end-proc;
//#----------------------------------------------------------------------------
/if defined(dspfCodes_d)
dcl-proc SelectScreen;
  dcl-pi SelectScreen;
    KeyPressed               char(1) value;
    CurrScreen               zoned(1:0);
    Max#OfScreens            zoned(1:0) value;
  end-pi;

  dcl-s Screen#              zoned(1:0) inz(1);

  if (Max#OfScreens  > *Zero) and (Max#OfScreens >= CurrScreen) and (KeyPressed <> *Blank); 
    if KeyPressed = cKEY_PageDown;                                   // Next Page
      select;
        when CurrScreen < 1;
          Screen# = 1;
        when CurrScreen = Max#OfScreens;
          Screen# = 1;
        other;
          Screen# = CurrScreen + 1;
      endsl;
    else;
      if KeyPressed = cKEY_PageUp;                                    // Pre Page
        select;
          when CurrScreen = 1;
            Screen# = Max#OfScreens;
          when CurrScreen < 1;
            Screen# = Max#OfScreens;
          other;
            Screen# = CurrScreen - 1;
        endsl;
      endif;
    endif;
  else;
    Screen# = CurrScreen;
  endif;
  CurrScreen = Screen#;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc SetCancelLeave;
  dcl-pi SetCancelLeave      ind;
  end-pi;

  if KeyPressed = cKEY_F03 or KeyPressed = cKEY_F12;
    if KeyPressed = cKEY_F03;
      LeaveMain = 'Y';
    endif;
    if KeyPressed = cKEY_F12;
      CancelOption = 'Y';
    endif;
    return *On;
  endif;
  return *Off;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc GetClassDesc;
  dcl-pi GetClassDesc        char(50);
    ClassName                char(10) value;
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
dcl-proc GetClassDesc2;
  dcl-pi GetClassDesc2       char(50);
    ClassName                char(10) value;
  end-pi;
  select;
    when ClassName  = *Blank;
      return 'Runs 24 X 7';
    other;
      chain ClassName JCSCFG20R1;
  endsl;
  return C20DESC;
end-proc;
//#----------------------------------------------------------------------------
dcl-proc ClearTopBot05;
  dcl-pi ClearTopBot05;
  end-pi;

  OUTTITLE2  = *Blank;
  OUTSCNNAME = *blank;
  OUTCMDLINE = *Blank;
  OUTFLINE   = *Blank;

end-proc;
/endIf

