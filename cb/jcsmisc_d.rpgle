**FREE

dcl-s intRUNCMD             char( 300) inz;                            // Command To Run Job
dcl-s intJOBNAME            char(  10) inz;                             // Job Name
dcl-s intJOBD               char(  10) inz;                             // Job Description
dcl-s intJOBDLIB            char(  10) inz;                             // Job Description Lib
dcl-s intJOBQ               char(  10) inz;                             // Job Queue Name
dcl-s intJOBQLIB            char(  10) inz;                             // Job Queue Library
dcl-s intJOBPTY             char(  10) inz;                             // Job Priority On JObq
dcl-s intOUTPTY             char(  10) inz;                             // Job Priority On Outq
dcl-s intPRTDEV             char(  10) inz;                             // Print Device
dcl-s intOUTQ               char(  10) inz;                             // Out Queue Name
dcl-s intOUTQLIB            char(  10) inz;                             // Out Queue Library
dcl-s intRUNUSER            char(  10) inz;                             // User Name
dcl-s intPRTTXT             char(  30) inz;                             // Print Text
dcl-s intRTGDTA             char(  80) inz;                             // Routing Data
dcl-s intSYSLIBL            char(  10) inz;                             // System Library List
dcl-s intCURLIB             char(  10) inz;                             // Current Library
dcl-s intINLLIBL            char(  10) inz;                             // Initial Library List
dcl-s intMSGLOGL            char(   5) inz;                              // Message Log Level
dcl-s intMSGLOGS            char(   6) inz;                              // Message Log Severoty
dcl-s intMSGLOGT            char(   7) inz;                              // Message Logging Text
dcl-s intLOGCLPG            char(   5) inz;                              // Log CL Program Comnd
dcl-s intINQMSGR            char(   8) inz;                              // Inquiry message repl
dcl-s intDSPSBMJ            char(   4) inz;                              // Allow Display wrksbm
dcl-s intMSGQ               char(  10) inz;                             // Message queue
dcl-s intMSGQLIB            char(  10) inz;                             // Message queue Lib
dcl-s intKILLCMD            char( 300) inz;                            // Command To Kill Job
dcl-s intRUNCLAS            char(  10) inz;                             // Run Class Match To
dcl-s intLJOBNAM            char(  10) inz;                             // Last Known Job Name
dcl-s intLRUNUSR            char(  10) inz;                             // Last Known Job User
dcl-s intJOB#               char(   6) inz;                              // Last Known Job #
dcl-s intBeg               zoned( 4:0) inz;                            // Start Run Time
dcl-s intEnd               zoned( 4:0) inz;                            // Stop  Run Time
dcl-s intJOBError           char( 100) inz;                            // What type of error
dcl-s intLeave              char(   1) inz('N');                         // Leave if Y
dcl-s intLeaveType          char(  10) inz;                             // Type of shut down
dcl-s intCmdLine            char(1000) inz;
dcl-s LeaveDataArea         char(  10) inz('JCSLEAVE');                 // Name If data area

dcl-s DefJOBNAME            char(10) inz('*JOBD'   );                 // Job Name
dcl-s DefJOBD               char(10) inz('*USRPRF' );                 // Job Description
dcl-s DefJOBDLIB            char(10) inz(*Blank    );                 // Job Description Lib
dcl-s DefJOBQ               char(10) inz('*JOBD'   );                 // Job Queue Name
dcl-s DefJOBQLIB            char(10) inz(*Blank    );                 // Job Queue Library
dcl-s DefJOBPTY             char(5) inz('*JOBD'   );                  // Job Priority On JObq
dcl-s DefOUTPTY             char(5) inz('*JOBD'   );                  // Job Priority On Outq
dcl-s DefPRTDEV             char(10) inz('*CURRENT');                 // Print Device
dcl-s DefOUTQ               char(10) inz('*CURRENT');                 // Out Queue Name
dcl-s DefOUTQLIB            char(10) inz(*Blank    );                 // Out Queue Library
dcl-s DefRUNUSER            char(10) inz('*CURRENT');                 // User Name
dcl-s DefPRTTXT             char(30) inz('*CURRENT');                 // Print Text
dcl-s DefRTGDTA             char(80) inz('QCMDB'   );                 // Routing Data
dcl-s DefSYSLIBL            char(10) inz('*CURRENT');                 // System Library List
dcl-s DefCURLIB             char(10) inz('*CURRENT');                 // Current Library
dcl-s DefINLLIBL            char(10) inz('*JOBD'   );                 // Initial Library List
dcl-s DefMSGLOGL            char(5) inz('*JOBD'   );                  // Message Log Level
dcl-s DefMSGLOGS            char(6) inz('*JOBD'   );                  // Message Log Severoty
dcl-s DefMSGLOGT            char(7) inz('*JOBD'   );                  // Message Logging Text
dcl-s DefLOGCLPG            char(5) inz('*JOBD'   );                  // Log CL Program Comnd
dcl-s DefINQMSGR            char(8) inz('*JOBD'   );                  // Inquiry message repl
dcl-s DefDSPSBMJ            char(4) inz('*YES'    );                  // Allow Display wrksbm
dcl-s DefMSGQ               char(10) inz('*USRPRF' );                 // Message queue
dcl-s DefMSGQLIB            char(10) inz(*Blank    );                 // Message queue Lib
dcl-s DefKILLCMD            char(300) inz;                            // Command To Kill Job
dcl-s DefRUNCLAS            char(10) inz;                             // Run Class Match To
dcl-s DefLJOBNAM            char(10) inz;                             // Last Known Job Name
dcl-s DefLRUNUSR            char(10) inz;                             // Last Known Job User
dcl-s DefJOB#               char(6) inz;                              // Last Known Job #
dcl-s DefBeg               Zoned(4:0) inz(0000);                      // Start Run Time
dcl-s DefEnd               Zoned(4:0) inz(2400);                      // Stop  Run Time
