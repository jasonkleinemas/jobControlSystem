/***************************************************************/
/*                                                             */
/* Submit job?                                                 */
/*                                                             */
/***************************************************************/
             PGM        PARM(&CMDLINE &RETJOB# &RETUSER &RETNAME &RETJOBERR)

             DCL        VAR(&RUNCMD)    TYPE(*CHAR) LEN(300)
             DCL        VAR(&CMDLINE)   TYPE(*CHAR) LEN(1000)
             DCL        VAR(&CMDLINEL)  TYPE(*DEC)  LEN(15 5) VALUE(1000)
             DCL        VAR(&RETJOB#)   TYPE(*CHAR) LEN(6)
             DCL        VAR(&RETUSER)   TYPE(*CHAR) LEN(10)
             DCL        VAR(&RETNAME)   TYPE(*CHAR) LEN(10)
             DCL        VAR(&RETJOBERR) TYPE(*CHAR) LEN(100)
             DCL        VAR(&MSGDTA)    TYPE(*CHAR) LEN(100)
             DCL        VAR(&RETCODE7)  TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGID)     TYPE(*CHAR) LEN(7)


             CALL       PGM(QCMDEXC) PARM(&CMDLINE &CMDLINEL)

             MONMSG     MSGID(CPF133A CPF1338 CPF1651) EXEC(DO)

             RCVMSG     MSGTYPE(*LAST) MSGDTA(&MSGDTA) MSGID(&MSGID)

             CHGVAR     VAR(&RETJOBERR) VALUE('Error ' *CAT &MSGDTA + *CAT &RUNCMD)
             GOTO       CMDLBL(END)
             ENDDO
             MONMSG     MSGID(CPF0000)

             RCVMSG     MSGTYPE(*LAST) MSGDTA(&MSGDTA) MSGID(&MSGID)

             CHGVAR     VAR(&RETJOBERR) VALUE(&MSGDTA *CAT &RUNCMD)
END:
             CHGVAR     VAR(&RETNAME) VALUE(%SST(&MSGDTA 1 10))
             CHGVAR     VAR(&RETUSER) VALUE(%SST(&MSGDTA 11 10))
             CHGVAR     VAR(&RETJOB#) VALUE(%SST(&MSGDTA 21 6))

             ENDPGM

