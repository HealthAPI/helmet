*==================================================================
*  Title:  PROGRAM C2 CALCULATES CONDITION-SPECIFIC RATES FOR 
*          SELECTED AHRQ PREVENTION QUALITY INDICATORS
*
*  Description:
*         USES PROC SUMMARY TO CALCULATE CONDITION-SPECIFIC RATES 
*         FOR PREVENTION QUALITY INDICATORS ACROSS STRATIFIERS:
*         PROGRAM USES FIPST AND AGECCAT
*
*          >>> VERSION 5.0 - MARCH, 2015  <<<
*
*===================================================================;
FILENAME CONTROL 'C:\PATHNAME\CONTROL_PQI.SAS'; *<===USER MUST modify;

%INCLUDE CONTROL;


 TITLE2 'PROGRAM C2';
 TITLE3 'AHRQ PREVENTION QUALITY INDICATORS: CALCULATE CONDITION-SPECIFIC RATES';
 run;

 * -------------------------------------------------------------- ;
 * --- Calculate the Numerators (T prefix) for the CONDITION-     ;
 * --- SPECIFIC rates.                                            ;
 * -------------------------------------------------------------- ;

 PROC   SUMMARY DATA=IN1.&INFILE1. NWAY;
 CLASS  FIPST AGECCAT;
 VAR    TAPQ01 TAPQ03 TAPQ14 TAPQ16;
 OUTPUT OUT=NWAY
        SUM(TAPQ01 TAPQ03 TAPQ14 TAPQ16)=TAPQ01 TAPQ03 TAPQ14 TAPQ16;
 RUN;

 PROC   SORT DATA=NWAY;
 BY     FIPST AGECCAT ;
 RUN;

 * -------------------------------------------------------------- ;
 * --- ADD THE AREA POPULATION DENOMINATORS --------------------- ;
 * -------------------------------------------------------------- ;

 PROC   SORT DATA=NWAY (KEEP=FIPST) OUT=FIPST NODUPKEY;
 BY     FIPST;
 RUN;
 
 * -------------------------------------------------------------- ;
 * --- READ STATE LEVEL POPS                                  --- ;
 * -------------------------------------------------------------- ;

 DATA QIPOP;
    LENGTH FIPST $2 AGECCAT 3 POP 8;
    INFILE POPFILC2 DLM = '09'x MISSOVER;
    INPUT  FIPST AGECCAT POP;
 RUN;
 
 PROC   SUMMARY DATA=QIPOP NWAY ;
 CLASS  FIPST AGECCAT;
 VAR    POP;
 OUTPUT OUT=QIPOPSUM SUM(POP)=;
 RUN;

 PROC   SORT DATA=QIPOPSUM;
 BY     FIPST AGECCAT;
 RUN;

 DATA   QIPOP;
 MERGE  FIPST(IN=X) QIPOPSUM;
 BY     FIPST;
 IF X;
 RUN;

 DATA  NWAY;
 MERGE NWAY QIPOP(KEEP=FIPST AGECCAT POP);
 BY    FIPST AGECCAT;

 IF POP = . THEN
    PUT 'MISSING POPULATION ' FIPST AGECCAT POP;

 ARRAY PPQ{4} PAPQ01 PAPQ03 PAPQ14 PAPQ16;

 DO J = 1 to 4;
    PPQ{J} = POP;
 END;

 IF AGECCAT IN (0) THEN DO;
   TAPQ01 = .; PAPQ01 = .;
   TAPQ03 = .; PAPQ03 = .;
   TAPQ14 = .; PAPQ14 = .;
   TAPQ16 = .; PAPQ16 = .;
 END;

LABEL
 POP    = 'AREA POPULATION                         '
 TAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Numerator)'
 TAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Numerator)'
 TAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Numerator)'
 TAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Numerator)'
 PAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Denominator)'
 PAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Denominator)'
 PAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Denominator)'
 PAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Denominator)'
        ;

 DROP J _FREQ_ _TYPE_;

 RUN;

 * -------------------------------------------------------------- ;
 * --- AGGREGATE POPULATION COUNTS, BY STRATIFIERS            --- ;
 * -------------------------------------------------------------- ;

 PROC   SUMMARY DATA=NWAY ;
 CLASS  FIPST AGECCAT ;
 VAR    TAPQ01 TAPQ03 TAPQ14 TAPQ16 PAPQ01 PAPQ03 PAPQ14 PAPQ16;
 OUTPUT OUT=&OUTFILC2. SUM=;
 RUN;

 * -------------------------------------------------------------- ;
 * --- CALCULATE CONDITION-SPECIFIC RATES                     --- ;
 *                                                                ;
 * --- DISCHARGES WITH MISSING FIPST DATA HAVE BEEN           --- ;
 * --- EXCLUDED FROM THESE ANALYSIS.                          --- ;
 * -------------------------------------------------------------- ;
 
 DATA   OUTC2.&OUTFILC2. ;
 SET    &OUTFILC2.(WHERE=(_TYPE_ IN (2,3)));

 ARRAY  PPQ{4}  PAPQ01 PAPQ03 PAPQ14 PAPQ16 ;
 ARRAY  TPQ{4}  TAPQ01 TAPQ03 TAPQ14 TAPQ16 ;
 ARRAY  CPQ{4}  CAPQ01 CAPQ03 CAPQ14 CAPQ16 ;


 DO J = 1 to 4;
         IF TPQ{J} GT 0 AND PPQ{J} GT 0 THEN CPQ{J} = TPQ{J} / PPQ{J};
    ELSE IF                 PPQ{J} GT 0 THEN CPQ{J} = 0 ;
 END;

 DROP J _FREQ_ ;

 LABEL
 CAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Condition)'
 CAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Condition)'
 CAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Condition)'
 CAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Condition)'
  _TYPE_ = 'Stratification level                   '
;

 RUN;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA CONDITION-SPECIFIC FILE ------- ;
 * -------------------------------------------------------------- ;

 PROC CONTENTS DATA=OUTC2.&OUTFILC2. POSITION;
 RUN;


 PROC MEANS DATA=OUTC2.&OUTFILC2(WHERE=(_TYPE_ IN (2))) N NMISS MIN MAX MEAN SUM NOLABELS;
 TITLE4 "SUMMARY OF AREA-LEVEL RATES";
 RUN;


 * -------------------------------------------------------------- ;
 * --- PRINT AREA CONDITION-SPECIFIC MEANS FILE ----------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);

 PROC   PRINT DATA=OUTC2.&OUTFILC2. LABEL SPLIT='*';
 VAR    FIPST AGECCAT  TAPQ&PQ. PAPQ&PQ. CAPQ&PQ. ;
 LABEL FIPST      = "FIPST"
       AGECCAT    = "AGECCAT"
       TAPQ&PQ.   = "TAPQ&PQ.*(Numerator)"
       PAPQ&PQ.   = "PAPQ&PQ.*(Denominator)"
       CAPQ&PQ.   = "CAPQ&PQ.*(Condition)"
       ;
 FORMAT AGECCAT AGECCAT.   
	  TAPQ&PQ. PAPQ&PQ. COMMA13.0
	  CAPQ&PQ. 8.6
        ;
 TITLE4 "Indicator  &PQ.: &TEXT";
 RUN;

 %MEND PRT;

 %PRT(01,Diabetes Short-Term Complications Admission Rate);
 %PRT(03,Diabetes Short-Term Complications Admission Rate);
 %PRT(14,Uncontrolled Diabetes Admission Rate);
 %PRT(16,Uncontrolled Diabetes Admission Rate);
 %END;

 %MEND PRT2;

 %PRT2; 


 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS ----------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXT;

 %IF &TEXTC2. = 1  %THEN %DO; 

 DATA _NULL_;
   SET OUTC2.&OUTFILC2;
 FILE PQTEXTC2 LRECL=600;
 IF _N_=1 THEN PUT "FIPST" "," "Age" "," "Type" ","
 "TAPQ01" "," "TAPQ03" "," "TAPQ14" "," "TAPQ16" ","
 "PAPQ01" "," "PAPQ03" "," "PAPQ14" "," "PAPQ16" ","
 "CAPQ01" "," "CAPQ03" "," "CAPQ14" "," "CAPQ16";

 PUT FIPST $2. "," AGECCAT 3. "," _TYPE_ 2. ","
 (TAPQ01 TAPQ03 TAPQ14 TAPQ16) (7.0 ",")
  ","
 (PAPQ01 PAPQ03 PAPQ14 PAPQ16) (13.2 ",") 
 ","
 (CAPQ01 CAPQ03 CAPQ14 CAPQ16) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXT;

 %TEXT;
