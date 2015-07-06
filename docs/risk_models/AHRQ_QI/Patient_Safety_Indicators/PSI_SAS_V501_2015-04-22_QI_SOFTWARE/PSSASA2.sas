*======================= PROGRAM: PSSASA2.SAS =====================;
*==================================================================
*  Title:  PROGRAM A2 CALCULATES OBSERVED AREA RATES FOR AHRQ
*          PATIENT SAFETY INDICATORS
*
*  Description:
*         USES PROC SUMMARY TO CALCULATE OBSERVED RATES FOR
*         PATIENT SAFETY INDICATORS AND PROGRAM A3 CALCULATES 
		  ADJUSTED AREA RATES ACROSS STRATIFIERS:
*         PROGRAM USES AREA, AGECAT, SEXCAT AND RACECAT
*
*          		>>>  VERSION 5.0 - MARCH, 2015  <<<
*===================================================================;
FILENAME CONTROL "C:\PATHNAME\CONTROL_PSI.SAS"; *<==USER MUST modify;

%INCLUDE CONTROL;


 %MACRO CTY2MA;
    %IF &MALEVL EQ 0 %THEN %DO;
        ATTRIB MAREA LENGTH=$5
          LABEL='FIPS STATE COUNTY CODE';
        MAREA = FIPSTCO;
    %END;
    %ELSE %IF &MALEVL EQ 1 %THEN %DO;
        ATTRIB MAREA LENGTH=$5
          LABEL='MODIFIED FIPS';
        MAREA = INPUT(PUT(FIPSTCO,$M1AREA.),$5.);
    %END;
    %ELSE %IF &MALEVL EQ 2 %THEN %DO;
        ATTRIB MAREA LENGTH=$5
          LABEL='OMB 1999 METRO AREA';
        MAREA = INPUT(PUT(FIPSTCO,$M2AREA.),$5.);
    %END;
    %ELSE %IF &MALEVL EQ 3 %THEN %DO;
        ATTRIB MAREA LENGTH=$5
          LABEL='OMB 2003 METRO AREA';
        MAREA = INPUT(PUT(FIPSTCO,$M3AREA.),$5.);
    %END;
 %MEND;

 TITLE2 'PROGRAM A3 PART I';
 TITLE3 'AHRQ PATIENT SAFETY INDICATORS: CALCULATE ADJUSTED AREA RATES';

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR --------------------------------- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE       - ;
 * --- OUTPUT FROM PROGRAM A1.                                    - ;
 * ---------------------------------------------------------------- ;

 DATA   TEMP0;
 SET    IN1.&INFILE1.;

 %CTY2MA

 RUN;

 PROC   SORT DATA=TEMP0 OUT=MAREA(KEEP=MAREA) NODUPKEY;
 BY     MAREA;
 RUN;

 DATA   QIPOP0;
    LENGTH FIPSTCO $5 SEXCAT POPCAT AGECAT RACECAT 3 
           POP_1995 POP_1996 POP_1997 POP_1998 POP_1999
           POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
           POP_2005 POP_2006 POP_2007 POP_2008 POP_2009 
           POP_2010 POP_2011 POP_2012 POP_2013 POP_2014
           POP 8;

    INFILE POPFILE MISSOVER FIRSTOBS=2;

   INPUT FIPSTCO SEXCAT POPCAT RACECAT 
          POP_1995 POP_1996 POP_1997 POP_1998 POP_1999
          POP_2000 POP_2001 POP_2002 POP_2003 POP_2004
          POP_2005 POP_2006 POP_2007 POP_2008 POP_2009
          POP_2010 POP_2011 POP_2012 POP_2013 POP_2014;

    %CTY2MA

    IF POPCAT IN (1,2,3,4)            THEN AGECAT = 0;
    ELSE IF POPCAT IN (5,6,7,8)       THEN AGECAT = 1;
    ELSE IF POPCAT IN (9,10,11,12,13) THEN AGECAT = 2;
    ELSE IF POPCAT IN (14,15)         THEN AGECAT = 3;
    ELSE                                   AGECAT = 4;

    POP = POP_&POPYEAR.;

 RUN;

 PROC   SUMMARY DATA=QIPOP0 NWAY;
 CLASS MAREA POPCAT AGECAT SEXCAT RACECAT;
 VAR POP;
 OUTPUT OUT=QIPOP SUM=;
 RUN;

 PROC   SORT DATA=QIPOP;
 BY     MAREA POPCAT AGECAT SEXCAT RACECAT;
 RUN;

 DATA   QIPOP(KEEP=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 MERGE  MAREA(IN=X) QIPOP(IN=Y);
 BY     MAREA;

 IF X AND Y;

 RUN;

 * -------------------------------------------------------------- ;
 * --- PATIENT SAFETY INDICATOR ADJUSTED RATES --------------- ;
 * -------------------------------------------------------------- ;
 * --- THIS STEP SELECTS THE OBSERVATIONS FROM THE PROGRAM 1    - ;
 * --- OUTPUT FOR EACH PATIENT SAFETY INDICATOR IN TURN.        - ;
 * --- EACH ITERATION PASSES VARIABLES THAT CONTROL THE         - ;
 * --- COVARIATES FOR THAT PATIENT SAFETY INDICATOR:            - ;
 * --- N - OBSERVATION NUMBER FROM THE MEANS AND COVAR FILES    - ;
 * ---     ALSO IDENTIFIES THE FORMAT USED TO INDEX COVARIATES  - ;
 * --- PS - THE PATIENT SAFETY INDICATOR NAME WITHOUT THE       - ;
 * ---      PREFIX (A)                                          - ;
 * -------------------------------------------------------------- ;

 %MACRO MOD3(N,PS);

 * --- THIS SET CREATES TEMP1 WHICH CONTAINS THE DEPENDENT      - ;
 * --- VARIABLE (TPS) AND INDEPENDENT VARIABLES USED IN         - ;
 * --- REGRESSION. IT APPENDS TO THE DISCHARGE DATA ONE         - ;
 * --- OBSERVATION PER AREA AND DEMOGRAPHIC GROUP.              - ;

 DATA   TEMP_2;
 SET    IN1.&INFILE1.(KEEP=KEY FIPSTCO T&PS. POPCAT AGECAT SEXCAT RACECAT);

 IF T&PS. IN (1);

 %CTY2MA

 RUN;

 PROC   SUMMARY DATA=TEMP_2 NWAY;
 CLASS  MAREA POPCAT AGECAT SEXCAT RACECAT;
 VAR    T&PS.;
 OUTPUT OUT=TEMP_3 N=TCOUNT;
 RUN;

 PROC   SORT DATA=TEMP_3;
 BY     MAREA POPCAT AGECAT SEXCAT RACECAT;
 RUN;

 /* FOR ZERO, REDUCE THE WEIGHT BY THE NUMERATOR COUNT */;

 DATA   TEMP_4(DROP=TCOUNT);
 MERGE  QIPOP(IN=X KEEP=MAREA POPCAT AGECAT SEXCAT RACECAT POP) 
        TEMP_3(KEEP=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT);
 BY     MAREA POPCAT AGECAT SEXCAT RACECAT;

 IF X;

 IF TCOUNT > 0 THEN PCOUNT = POP - TCOUNT;
 ELSE PCOUNT = POP;

 IF PCOUNT < 0 THEN PCOUNT = 0;

 N = &N.;

 IF AGECAT IN (0) THEN PCOUNT = 0;

 IF PCOUNT = 0 THEN DELETE;

 RUN;

 /* FOR ONE, RETAIN ONLY RECORDS WITH A VALID FIPS CODE */;

 DATA   TEMP_3(DROP=POP);
 MERGE  TEMP_3(IN=X KEEP=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT)
        QIPOP(KEEP=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 BY     MAREA POPCAT AGECAT SEXCAT RACECAT;

 IF X;

 IF POP < 0 THEN PCOUNT = 0;
 ELSE IF TCOUNT > 0 THEN PCOUNT = TCOUNT;
 ELSE PCOUNT = 0;

 IF PCOUNT = 0 THEN DELETE;

 RUN;

 /* COMBINE THE NUMERATOR AND DENOMINATOR */;

 DATA   TEMP1;
 SET    TEMP_3(IN=X) TEMP_4;
 IF X THEN T&PS. = 1;
 ELSE T&PS. = 0;
 RUN;

 DATA   TEMP1Y;
 SET    TEMP1;
 ONE = 1;
 RUN;

  * -------------------------------------------------------------- ;
 * --- AGGREGATE POPULATION COUNTS, BY STRATIFIERS            --- ;
 * -------------------------------------------------------------- ;

 PROC   SUMMARY DATA=TEMP1Y;
 CLASS  MAREA AGECAT SEXCAT RACECAT;
 VAR    T&PS. ONE;
 OUTPUT OUT=ADJ_&PS. SUM(T&PS. ONE)=T&PS. P&PS.;
 WEIGHT   PCOUNT;
 RUN;

 DATA   ADJ_&PS.;
 SET    ADJ_&PS.;
 IF _TYPE_ &TYPELVLA;
 KEEP MAREA AGECAT SEXCAT RACECAT T&PS. P&PS. _TYPE_;
 RUN;

 PROC SORT DATA = ADJ_&PS.;
 BY MAREA AGECAT SEXCAT RACECAT;
 RUN;  QUIT;

 PROC   DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP_2 TEMP_3 TEMP_4;;
 RUN;

 %MEND;

%MOD3(21,APS21);
%MOD3(22,APS22);
%MOD3(23,APS23);
%MOD3(24,APS24);
%MOD3(25,APS25);
%MOD3(26,APS26);
%MOD3(27,APS27);


 * --- MERGES THE ADJUSTED DENOMINATOR ADN NUMERATOR FOR EACH PATIENT SAFETY INDICATOR.    - ;
 * --- PREFIX FOR THE ADJUSTED DATA IS RATES IS  ADJ_ADJUSTED                                 - ;

 DATA TEMP2Y;
   MERGE ADJ_APS21 ADJ_APS22 ADJ_APS23 ADJ_APS24 
         ADJ_APS25 ADJ_APS26 ADJ_APS27;
   BY MAREA AGECAT SEXCAT RACECAT;
 RUN;

 DATA &OUTFILA2.;
 SET TEMP2Y;


 ARRAY PPS2{7} PAPS21-PAPS27 ;
 ARRAY TPS{7}  TAPS21-TAPS27 ;
 ARRAY OPS{7}  OAPS21-OAPS27 ;

 DO J = 1 to 7;
    IF TPS{J} GT 0 AND PPS2{J} GT 0 THEN OPS{J} = TPS{J} / PPS2{J};
    ELSE IF PPS2{J} GT 0 THEN OPS{J} = 0 ;
 END;

 LABEL
 TAPS21 = 'PSI 21 Retained Surgical Item or Unretrieved Device Fragment Rate (Numerator)'
 TAPS22 = 'PSI 22 Iatrogenic Pneumothorax Rate (Numerator)'
 TAPS23 = 'PSI 23 Central Venous Catheter-Related Blood Stream Infection Rate (Numerator)'
 TAPS24 = 'PSI 24 Postoperative Wound Dehiscence Rate (Numerator)'
 TAPS25 = 'PSI 25 Accidental Puncture or Laceration Rate (Numerator)'
 TAPS26 = 'PSI 26 Transfusion Reaction Rate (Numerator)'
 TAPS27 = 'PSI 27 Perioperative Hemorrhage or Hematoma Rate (Numerator)'
 ;

 LABEL
 PAPS21 = 'PSI 21 Retained Surgical Item or Unretrieved Device Fragment Rate (Denominator)'
 PAPS22 = 'PSI 22 Iatrogenic Pneumothorax Rate (Denominator)'
 PAPS23 = 'PSI 23 Central Venous Catheter-Related Blood Stream Infection Rate (Denominator)'
 PAPS24 = 'PSI 24 Postoperative Wound Dehiscence Rate (Denominator)'
 PAPS25 = 'PSI 25 Accidental Puncture or Laceration Rate (Denominator)'
 PAPS26 = 'PSI 26 Transfusion Reaction Rate (Denominator)'
 PAPS27 = 'PSI 27 Perioperative Hemorrhage or Hematoma Rate (Denominator)'
 ;

 LABEL
 OAPS21 = 'PSI 21 Retained Surgical Item or Unretrieved Device Fragment Rate (Observed)'
 OAPS22 = 'PSI 22 Iatrogenic Pneumothorax Rate (Observed)'
 OAPS23 = 'PSI 23 Central Venous Catheter-Related Blood Stream Infection Rate (Observed)'
 OAPS24 = 'PSI 24 Postoperative Wound Dehiscence Rate (Observed)'
 OAPS25 = 'PSI 25 Accidental Puncture or Laceration Rate (Observed)'
 OAPS26 = 'PSI 26 Transfusion Reaction Rate (Observed)'
 OAPS27 = 'PSI 27 Perioperative Hemorrhage or Hematoma Rate (Observed)'
 _TYPE_ = 'STRATIFICATION LEVEL  '
 ;

 DROP J;

 RUN;

PROC DATASETS NOLIST;
  DELETE MAREA QIPOP QIPOP0 TEMP0 TEMP2Y
         ADJ_APS21 ADJ_APS22 ADJ_APS23 ADJ_APS24 
         ADJ_APS25 ADJ_APS26 ADJ_APS27;
RUN; QUIT;

 PROC SORT DATA=&OUTFILA2. OUT=OUTA2.&OUTFILA2.;
 BY MAREA AGECAT SEXCAT RACECAT;
 RUN;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA OBSERVED MEANS FILE ----------- ;
 * -------------------------------------------------------------- ;

 PROC CONTENTS DATA=OUTA2.&OUTFILA2. POSITION;
 RUN;

 *PROC MEANS DATA=OUTA2.&OUTFILA2.(WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN SUM NOLABELS;
 *TITLE4 "SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)";
 *RUN;

***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX SUM NOLABELS;
   VAR TAPS21-TAPS27 ;
   TITLE  'SUMMARY OF PATIENT SAFETY AREA-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=8';
 RUN; QUIT;

 PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX SUM NOLABELS;
   VAR PAPS21-PAPS27 ;
   TITLE  'SUMMARY OF PATIENT SAFETY AREA-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=8';
 RUN; QUIT;

PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN NOLABELS;
   VAR OAPS21-OAPS27;
   TITLE  'SUMMARY OF PATIENT SAFETY AREA-LEVEL INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=8';
RUN; QUIT;


PROC CONTENTS DATA=OUTA2.&OUTFILA2. POSITION;
RUN;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA OBSERVED MEANS FILE --------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PS,TEXT);

 PROC  PRINT DATA=OUTA2.&OUTFILA2. LABEL SPLIT='*';
 VAR   MAREA AGECAT SEXCAT RACECAT TAPS&PS. PAPS&PS. OAPS&PS. ;
 LABEL MAREA   = "MAREA"
       AGECAT  = "AGECAT"
       SEXCAT  = "SEXCAT"
       RACECAT = "RACECAT"
       TAPS&PS.   = "TAPS&PS.*(Numerator)"
       PAPS&PS.   = "PAPS&PS.*(Denominator)"
       OAPS&PS.   = "OAPS&PS.*(Observed)"
       ;
 FORMAT AGECAT AGECAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
        TAPS&PS. PAPS&PS. COMMA13.0
	  OAPS&PS. 8.6
        ;
 TITLE4 "Indicator &PS.: &TEXT";
 RUN;

 %MEND PRT;

 %PRT(21,Retained Surgical Item or Unretrieved Device Fragment Rate);
 %PRT(22,Iatrogenic Pneumothorax Rate);
 %PRT(23,Central Venous Catheter-Related Blood Stream Infection Rate);
 %PRT(24,Postoperative Wound Dehiscence Rate);
 %PRT(25,Accidental Puncture or Laceration Rate);
 %PRT(26,Transfusion Reaction Rate);
 %PRT(27,Perioperative Hemorrhage or Hematoma Rate);

 %END;

 %MEND PRT2;

 %PRT2; 

 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS ----------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXT;

 %IF &TEXTA2. = 1  %THEN %DO;

 DATA _NULL_;
 SET OUTA2.&OUTFILA2;
 FILE PSTEXTA2 LRECL=1000;
 IF _N_=1 THEN PUT "MAREA" "," "Age" "," "Sex" "," "Race" "," "Type" ","
 "TAPS21" "," "TAPS22" "," "TAPS23" "," "TAPS24" "," "TAPS25" "," "TAPS26" "," "TAPS27" ","
 "PAPS21" "," "PAPS22" "," "PAPS23" "," "PAPS24" "," "PAPS25" "," "PAPS26" "," "PAPS27" ","
 "OAPS21" "," "OAPS22" "," "OAPS23" "," "OAPS24" "," "OAPS25" "," "OAPS26" "," "OAPS27";

 PUT MAREA $5. "," AGECAT 3. "," SEXCAT 3. "," RACECAT 3. "," _TYPE_ 2. ","
 (TAPS21-TAPS27) (7.0 ",")
 ","
 (PAPS21-PAPS27) (13.2 ",")
 ","
 (OAPS21-OAPS27) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXT;

 %TEXT
