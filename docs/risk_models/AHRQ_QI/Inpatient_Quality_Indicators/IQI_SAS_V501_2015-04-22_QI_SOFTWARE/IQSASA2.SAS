*==================================================================
*  Title:  PROGRAM A2 CALCULATES OBSERVED AREA RATES FOR AHRQ
*          INPATIENT QUALITY INDICATORS
*
*  Description:
*         USES PROC SUMMARY TO CALCULATE OBSERVED RATES FOR
*         INPATIENT QUALITY INDICATORS ACROSS STRATIFIERS:
*         PROGRAM USES AREA, AGECAT, SEXCAT AND RACECAT
*
*          >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*===================================================================;
FILENAME CONTROL 'C:\PATHNAME\CONTROL_IQI.SAS'; *<===USER MUST modify; 

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
 TITLE3 'AHRQ INPATIENT QUALITY INDICATORS: CALCULATE ADJUSTED AREA RATES';

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
 * --- INPATIENT QUALITY INDICATOR ADJUSTED RATES --------------- ;
 * -------------------------------------------------------------- ;
 * --- THIS STEP SELECTS THE OBSERVATIONS FROM THE PROGRAM 1    - ;
 * --- OUTPUT FOR EACH INPATIENT QUALITY INDICATOR IN TURN.      -;
 * --- EACH ITERATION PASSES VARIABLES THAT CONTROL THE          -;
 * --- COVARIATES FOR THAT INPATIENT QUALITY INDICATOR:         - ;
 * --- N - OBSERVATION NUMBER FROM THE MEANS AND COVAR FILES    - ;
 * ---     ALSO IDENTIFIES THE FORMAT USED TO INDEX COVARIATES  - ;
 * --- IQ - THE INPATIENT QUALITY INDICATOR NAME WITHOUT THE    - ;
 * ---      PREFIX (A)                                          - ;
 * --- A - THE NUMBER OF DEMOGRAPHIC CATEGORIES (AGE AND SEX)   - ;
 * --- S - DETERMINES WHETHER AGE*SEX INTERACTIONS ARE NEEDED   - ;
 * -------------------------------------------------------------- ;

 %MACRO MOD3(N,IQ);

 * --- THIS SET CREATES TEMP1 WHICH CONTAINS THE DEPENDENT      - ;
 * --- VARIABLE (TIQ) AND INDEPENDENT VARIABLES USED IN         - ;
 * --- REGRESSION. IT APPENDS TO THE DISCHARGE DATA ONE         - ;
 * --- OBSERVATION PER AREA AND DEMOGRAPHIC GROUP.              - ;

 DATA   TEMP_2;
 SET    IN1.&INFILE1.(KEEP=KEY FIPSTCO T&IQ. POPCAT AGECAT SEXCAT RACECAT);

 IF T&IQ. IN (1);

 %CTY2MA

 RUN;

 PROC   SUMMARY DATA=TEMP_2 NWAY;
 CLASS  MAREA POPCAT AGECAT SEXCAT RACECAT;
 VAR    T&IQ.;
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

 IF N IN (28) AND SEXCAT IN (1) THEN PCOUNT = 0;

 IF AGECAT IN (0) THEN PCOUNT = 0;

 IF N IN (26,27) AND AGECAT IN (1) THEN PCOUNT = 0;

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
 LENGTH FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14 3;
 SET    TEMP_3(IN=X) TEMP_4;

 IF X THEN T&IQ. = 1;
 ELSE T&IQ. = 0;

 IF SEXCAT IN (2) THEN FEMALE = 1;
 ELSE FEMALE = 0;

 ARRAY ARRY1{14} AGECAT1-AGECAT14;
 ARRAY ARRY2{14} FAGECAT1-FAGECAT14;

 DO I = 1 TO 14;
    ARRY1(I) = 0; ARRY2(I) = 0;
 END;

 ARRY1(POPCAT-4) = 1;
 ARRY2(POPCAT-4) = FEMALE;

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
 VAR    T&IQ. ONE;
 OUTPUT OUT=ADJ_&IQ. SUM(T&IQ. ONE)=T&IQ. P&IQ.;
 WEIGHT   PCOUNT;
 RUN;

 DATA   ADJ_&IQ.(KEEP=MAREA AGECAT SEXCAT RACECAT T&IQ. P&IQ. _TYPE_);
 SET    ADJ_&IQ.;

 IF _TYPE_ &TYPELVLA;

 RUN;

 PROC SORT DATA = ADJ_&IQ.;
 BY MAREA AGECAT SEXCAT RACECAT;
 RUN;  QUIT;

PROC   DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP_2 TEMP_3 TEMP_4;;
RUN;

 %MEND;

 %MOD3(26,AIQ26);
 %MOD3(27,AIQ27);
 %MOD3(28,AIQ28);
 %MOD3(29,AIQ29);


 * --- MERGES THE ADJUSTED DENOMINATOR AND NUMERATOR FOR EACH INPATIENT QUALITY INDICATOR.    - ;
 * --- PREFIX FOR THE ADJUSTED DATA IS RATES IS  ADJ_ADJUSTED                                 - ;

 DATA TEMP2Y;
   MERGE ADJ_AIQ26 ADJ_AIQ27 ADJ_AIQ28 ADJ_AIQ29;
   BY MAREA AGECAT SEXCAT RACECAT;
 RUN;

 DATA &OUTFILA2.;
 SET TEMP2Y;

 ARRAY PIQ2{4} PAIQ26-PAIQ29 ;
 ARRAY TIQ{4}  TAIQ26-TAIQ29 ;
 ARRAY OIQ{4}  OAIQ26-OAIQ29 ;

 DO J = 1 to 4;
    IF TIQ{J} GT 0 AND PIQ2{J} GT 0 THEN OIQ{J} = TIQ{J} / PIQ2{J};
    ELSE IF PIQ2{J} GT 0 THEN OIQ{J} = 0;
 END;

 LABEL
 TAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Numerator)'
 TAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Numerator)'
 TAIQ28 = 'IQI 28 Hysterectomy Rate (Numerator)'
 TAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Numerator)'
 ;
 LABEL
 PAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Denominator)'
 PAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Denominator)'
 PAIQ28 = 'IQI 28 Hysterectomy Rate (Denominator)'
 PAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Denominator)'
 ;
 LABEL
 OAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Observed)'
 OAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Observed)'
 OAIQ28 = 'IQI 28 Hysterectomy Rate (Observed)'
 OAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Observed)'
 _TYPE_ = 'STRATIFICATION LEVEL                    '
 ;

 DROP J;

 RUN;
/*
 PROC DATASETS NOLIST;
  DELETE MAREA QIPOP QIPOP0 TEMP0 TEMP2Y
         ADJ_AIQ26 ADJ_AIQ27 ADJ_AIQ28 ADJ_AIQ29;
RUN; QUIT;*/

 PROC SORT DATA=&OUTFILA2. OUT=OUTA2.&OUTFILA2.;
 BY MAREA AGECAT SEXCAT RACECAT;
 RUN;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA OBSERVED MEANS FILE ----------- ;
 * -------------------------------------------------------------- ;

 PROC CONTENTS DATA=OUTA2.&OUTFILA2. POSITION;
 RUN;

 ***----- TO PRINT VARIABLE LABLES COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX SUM NOLABELS;
   VAR TAIQ26-TAIQ29 ;
   TITLE  'SUMMARY OF INPATIENT QUALITY AREA-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=8';
RUN; QUIT;

 PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX SUM NOLABELS;
   VAR PAIQ26-PAIQ29 ;
   TITLE  'SUMMARY OF INPATIENT QUALITY AREA-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=8';
RUN; QUIT;

PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN NOLABELS;
   VAR OAIQ26-OAIQ29 ;
   TITLE  'SUMMARY OF INPATIENT QUALITY AREA-LEVEL OBSERVED INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=8';
RUN; QUIT;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA OBSERVED MEANS FILE --------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(IQ,TEXT);

 PROC  PRINT DATA=OUTA2.&OUTFILA2. LABEL SPLIT='*';
 VAR   MAREA AGECAT SEXCAT RACECAT TAIQ&IQ. PAIQ&IQ. OAIQ&IQ. ;
 LABEL MAREA   = "MAREA"
       AGECAT  = "AGECAT"
       SEXCAT  = "SEXCAT"
       RACECAT = "RACECAT"
       TAIQ&IQ.   = "TAIQ&IQ.*(Numerator)"
       PAIQ&IQ.   = "PAIQ&IQ.*(Denominator)"
       OAIQ&IQ.   = "OAIQ&IQ.*(Observed)"
       ;
 FORMAT AGECAT AGECAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
        TAIQ&IQ. PAIQ&IQ. COMMA13.0
        OAIQ&IQ. 8.6
        ;
 TITLE4 "Indicator &IQ.: &TEXT";
 RUN;

 %MEND PRT;

 %PRT(26,Coronary Artery Bypass Graft (CABG) Rate);
 %PRT(27,Percutaneous Coronary Intervention (PCI) Rate);
 %PRT(28,Hysterectomy Rate);
 %PRT(29,Laminectomy or Spinal Fusion Rate);

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
 FILE IQTEXTA2 LRECL=1000;
 IF _N_=1 THEN PUT "MAREA"  "," "Age"  "," "Sex"  "," "Race"  "," "Type" ","
 "TAIQ26" "," "TAIQ27" "," "TAIQ28" "," "TAIQ29" ","
 "PAIQ26" "," "PAIQ27" "," "PAIQ28" "," "PAIQ29" ","
 "OAIQ26" "," "OAIQ27" "," "OAIQ28" "," "OAIQ29";

 PUT MAREA $5. "," AGECAT 3. "," SEXCAT 3. "," RACECAT 3.  "," _TYPE_ 2.  ","
 (TAIQ26-TAIQ29) (7.0 ",")
  ","
 (PAIQ26-PAIQ29) (13.2 ",")
 ","
 (OAIQ26-OAIQ29) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXT;

 %TEXT;
