**FREE

/if not defined(sendErrMessage)
/define sendErrMessage

/copy ../cb_rpgle/messages/sendMessage.rpgle

dcl-proc SendErrMessage;
  dcl-pi SendErrMessage   char(  7);
    is_message            char(100) value;
    is_sendInfoMsg        char(  1) value;
  end-pi;

  dcl-s err               char(  7);
  
/if defined(PrintOut_F)
  if %open(Qsysprt);
    Err = PrintOut(Message);
  endif;
/endIf
  if %upper(is_sendInfoMsg) = 'Y' ;
    Err = sendMessage(is_message : '*SYSOPR');
  endif;
  return *Blank;
end-proc;
/endIf

