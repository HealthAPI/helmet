*======================= PROGRAM: PQSASA2.SAS =====================;
*==================================================================
*  Title:  PROGRAM A2 CALCULATES OBSERVED AREA RATES FOR AHRQ
*          PREVENTION QUALITY INDICATORS
*
*  Description:
*          USES PROC SUMMARY TO CALCULATE OBSERVED RATES FOR
*          PREVENTION QUALITY INDICATORS ACROSS STRATIFIERS:
*          PROGRAM USES AREA, AGECAT, SEXCAT AND RACECAT
*
*                >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*===================================================================;


FILENAME CONTROL 'C:\PATHNAME\CONTROL_PQI.SAS'; *<===USER MUST modify;

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
 TITLE3 'AHRQ PREVENTION QUALITY INDICATORS: CALCULATE ADJUSTED AREA RATES';

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR --------------------------------- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT FROM PROGRAM 1.                                   --- ;
 * ---------------------------------------------------------------- ;

 DATA   TEMP0;
 SET    IN1.&INFILE1.;

 %CTY2MA

 RUN;

 PROC   SORT DATA=TEMP0 (KEEP=MAREA) OUT=MAREA NODUPKEY;
 BY     MAREA;
 RUN;

 DATA QIPOP0;
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
 CLASS  MAREA POPCAT AGECAT SEXCAT RACECAT;
 VAR    POP;
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
 * --- PREVENTION QUALITY INDICATORS ADJUSTED RATES ------------- ;
 * -------------------------------------------------------------- ;
 * --- THIS STEP SELECTS THE OBSERVATIONS FROM THE PROGRAM 1 --- ;
 * --- OUTPUT FOR EACH PREVENTION QUALITY INDICATOR IN TURN.  --- ;
 * --- EACH ITERATION PASSES VARIABLES THAT CONTROL THE       --- ;
 * --- COVARIATES FOR THAT PREVENTION QUALITY INDICATOR:      --- ;
 * --- N - OBSERVATION NUMBER FROM THE MEANS AND COVAR FILES  --- ;
 * ---     ALSO IDENTIFIES THE FORMAT USED TO INDEX COVARIATES -- ;
 * --- PQ - THE PREVENTION QUALITY INDICATOR NAME WITHOUT THE --- ;
 *          PREFIX (A)                                        --- ;
 * -------------------------------------------------------------- ;

 %MACRO MOD3(N,PQ,DL);

 * --- THIS SET CREATES TEMP1 WHICH CONTAINS THE DEPENDENT    --- ;
 * --- VARIABLE (TPQ) AND INDEPENDENT VARIABLES USED IN       --- ;
 * --- REGRESSION.  IT APPENDS TO THE DISCHARGE DATA ONE      --- ;
 * --- OBSERVATION PER MAREA AND DEMOGRAPHIC GROUP.            --- ;

 %IF &DL. = 0 %THEN %DO;

 DATA   TEMP_2;
 SET    IN1.&INFILE1.(KEEP=KEY FIPSTCO T&PQ. POPCAT AGECAT SEXCAT RACECAT);

 IF T&PQ. IN (1);

 %CTY2MA

 RUN;

 PROC   SUMMARY DATA=TEMP_2 NWAY;
 CLASS  MAREA POPCAT AGECAT SEXCAT RACECAT;
 VAR    T&PQ.;
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

 IF AGECAT IN (0) THEN PCOUNT = 0;

 N = &N.;

 IF N IN (5) AND AGECAT IN (1) THEN PCOUNT = 0;
 IF N IN (15) AND AGECAT IN (2,3,4) THEN PCOUNT = 0;


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

 IF X THEN T&PQ. = 1;
 ELSE T&PQ. = 0;

 RUN;

 %END;
 %ELSE %DO;

 DATA   TEMP_2;
 SET    IN1.&INFILE1.(KEEP=KEY FIPSTCO T&PQ. POPCAT AGECAT SEXCAT RACECAT);

 IF T&PQ. IN (0,1);

 %CTY2MA

 RUN;

 PROC   SUMMARY DATA=TEMP_2 NWAY;
 CLASS  T&PQ. MAREA POPCAT AGECAT SEXCAT RACECAT;
 VAR    T&PQ.;
 OUTPUT OUT=TEMP_3 N=TCOUNT;
 RUN;

 PROC   SORT DATA=TEMP_3;
 BY     MAREA POPCAT AGECAT SEXCAT RACECAT;
 RUN;

 /* RETAIN ONLY RECORDS WITH A VALID FIPS CODE */;

 DATA   TEMP1;
 MERGE  TEMP_3(IN=X KEEP=MAREA POPCAT AGECAT SEXCAT RACECAT TCOUNT T&PQ.)
        QIPOP(KEEP=MAREA POPCAT AGECAT SEXCAT RACECAT POP);
 BY     MAREA POPCAT AGECAT SEXCAT RACECAT;

 IF X;

 IF POP < 0 THEN PCOUNT = 0;
 ELSE IF TCOUNT > 0 THEN PCOUNT = TCOUNT;
 ELSE PCOUNT = 0;

 N = &N.;

 IF N IN (2) AND AGECAT IN (0) THEN PCOUNT = 0;
 IF N IN (9) AND AGECAT IN (1,2,3,4) THEN PCOUNT = 0;

 IF PCOUNT = 0 THEN DELETE;

 RUN;

 %END;

 DATA   TEMP1;
 LENGTH FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14 
        POVCAT1-POVCAT10 3;
 SET    TEMP1;

 IF SEXCAT IN (2) THEN FEMALE = 1;
 ELSE FEMALE = 0;

 ARRAY ARRY1{14} AGECAT1-AGECAT14;
 ARRAY ARRY2{14} FAGECAT1-FAGECAT14;

 DO I = 1 TO 14;
    ARRY1(I) = 0; ARRY2(I) = 0;
 END;

 N = &N.;

 IF N NOTIN (9) THEN ARRY1(POPCAT-4) = 1;
 IF N NOTIN (9) THEN ARRY2(POPCAT-4) = FEMALE;

 ARRAY ARRY3{10} POVCAT1-POVCAT10;

 DO I = 1 TO 10;
    ARRY3(I) = 0;
 END;

 PVIDX = PUT(MAREA,$POVCAT.);

 IF PVIDX > 0 THEN ARRY3(PVIDX) = 1;

 RUN;

 DATA TEMP1Y;
   SET TEMP1;
   ONE = 1;
 RUN;

 
 * -------------------------------------------------------------- ;
 * --- AGGREGATE POPULATION COUNTS, BY STRATIFIERS            --- ;
 * -------------------------------------------------------------- ;

 PROC   SUMMARY DATA=TEMP1Y;
 CLASS  MAREA AGECAT SEXCAT RACECAT;
 VAR    T&PQ. ONE;
 OUTPUT OUT=ADJ_&PQ. SUM(T&PQ. ONE)=T&PQ. P&PQ.;
 WEIGHT PCOUNT;
 RUN;

 DATA ADJ_&PQ.;
    SET ADJ_&PQ.;
	IF _TYPE_ &TYPELVLA;
	KEEP MAREA AGECAT SEXCAT RACECAT T&PQ. P&PQ. _TYPE_;
 RUN;

 PROC SORT DATA=ADJ_&PQ.;
   BY MAREA AGECAT SEXCAT RACECAT;
 RUN; QUIT;

 PROC   DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP_2 TEMP_3 TEMP_4;
 RUN;

 %MEND;

 %MOD3(1,APQ01,0);
 %MOD3(2,APQ02,1);
 %MOD3(3,APQ03,0);
 %MOD3(5,APQ05,0);
 %MOD3(7,APQ07,0);
 %MOD3(8,APQ08,0);
 %MOD3(10,APQ10,0);
 %MOD3(11,APQ11,0);
 %MOD3(12,APQ12,0);
 %MOD3(13,APQ13,0);
 %MOD3(14,APQ14,0);
 %MOD3(15,APQ15,0);
 %MOD3(16,APQ16,0);
 %MOD3(90,APQ90,0);
 %MOD3(91,APQ91,0);
 %MOD3(92,APQ92,0);


 * --- MERGES THE ADJUSTED DENOMINATOR ADN NUMERATOR FOR EACH PATIENT QUALITY INDICATOR.   - ;
 * --- PREFIX FOR THE ADJUSTED DATA IS RATES IS  ADJ_9ADJUSTED                             - ;

DATA TEMP2Y;
  MERGE ADJ_APQ01 ADJ_APQ02 ADJ_APQ03 ADJ_APQ05 ADJ_APQ07 ADJ_APQ08 ADJ_APQ10 
        ADJ_APQ11 ADJ_APQ12 ADJ_APQ13 ADJ_APQ14 ADJ_APQ15 ADJ_APQ16 ADJ_APQ90 
        ADJ_APQ91 ADJ_APQ92;
  BY MAREA AGECAT SEXCAT RACECAT;

RUN;

DATA &OUTFILA2.;
 SET TEMP2Y;

 ARRAY PPQ2{16} PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ16 
                PAPQ90-PAPQ92;
 ARRAY TPQ{16} TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ16 
               TAPQ90-TAPQ92;
 ARRAY OPQ{16} OAPQ01-OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ10-OAPQ16 
               OAPQ90-OAPQ92;

 DO J = 1 to 16;
    IF TPQ{J} GT 0 AND PPQ2{J} GT 0 THEN OPQ{J} = TPQ{J} / PPQ2{J};
    ELSE IF PPQ2{J} GT 0 THEN OPQ{J} = 0 ;
 END;

 LABEL
 TAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Numerator)'
 TAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Numerator)'
 TAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Numerator)'
 TAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Numerator)'
 TAPQ07 = 'PQI 07 Hypertension Admission Rate (Numerator)'
 TAPQ08 = 'PQI 08 Heart Failure Admission Rate (Numerator)'
 TAPQ10 = 'PQI 10 Dehydration Admission Rate (Numerator)'
 TAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Numerator)'
 TAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Numerator)'
 TAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Numerator)'
 TAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Numerator)'
 TAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Numerator)'
 TAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Numerator)'
 TAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Numerator)'
 TAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Numerator)'
 TAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Numerator)'
 ;
 LABEL
 PAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Denominator)'
 PAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Denominator)'
 PAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Denominator)'
 PAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Denominator)'
 PAPQ07 = 'PQI 07 Hypertension Admission Rate (Denominator)'
 PAPQ08 = 'PQI 08 Heart Failure Admission Rate (Denominator)'
 PAPQ10 = 'PQI 10 Dehydration Admission Rate (Denominator)'
 PAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Denominator)'
 PAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Denominator)'
 PAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Denominator)'
 PAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Denominator)'
 PAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Denominator)'
 PAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Denominator)'
 PAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Denominator)'
 PAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Denominator)'
 PAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Denominator)'
 ;
 LABEL
 OAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Observed)'
 OAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Observed)'
 OAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Observed)'
 OAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Observed)'
 OAPQ07 = 'PQI 07 Hypertension Admission Rate (Observed)'
 OAPQ08 = 'PQI 08 Heart Failure Admission Rate (Observed)'
 OAPQ10 = 'PQI 10 Dehydration Admission Rate (Observed)'
 OAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Observed)'
 OAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Observed)'
 OAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Observed)'
 OAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Observed)'
 OAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Observed)'
 OAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Observed)'
 OAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Observed)'
 OAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Observed)'
 OAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Observed)'
 _TYPE_ = 'Stratification level                    '
 ;

 DROP J;

 RUN;

 PROC SORT DATA=&OUTFILA2. OUT=OUTA2.&OUTFILA2.;
 BY MAREA AGECAT SEXCAT RACECAT;
 RUN;

PROC DATASETS NOLIST;
  DELETE MAREA QIPOP QIPOP0 TEMP0 TEMP2Y
         ADJ_APQ01 ADJ_APQ02 ADJ_APQ03 ADJ_APQ05 ADJ_APQ07 ADJ_APQ08 ADJ_APQ10 
         ADJ_APQ11 ADJ_APQ12 ADJ_APQ13 ADJ_APQ14 ADJ_APQ15 ADJ_APQ16 ADJ_APQ90
         ADJ_APQ91 ADJ_APQ92;
RUN; QUIT;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA OBSERVED MEANS FILE ----------- ;
 * -------------------------------------------------------------- ;

 PROC CONTENTS DATA=OUTA2.&OUTFILA2. POSITION;
 RUN;

 *PROC MEANS DATA=OUTA2.&OUTFILA2.(WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN SUM NOLABELS;
 *TITLE4 "SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)";
 *RUN;

 ***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA = OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX SUM NOLABELS;
     VAR TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ16 TAPQ90-TAPQ92;
     TITLE  "PATIENT QUALITY AREA-LEVEL INDICATOR OVERALL NUMERATOR WHEN _TYPE_ =8 ";
RUN; QUIT;

PROC MEANS DATA = OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX SUM NOLABELS;
     VAR PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ16 PAPQ90-PAPQ92;
     TITLE  "PATIENT QUALITY AREA-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_ =8";
RUN; QUIT;

PROC MEANS DATA = OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN NOLABELS ;
     VAR OAPQ01-OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ10-OAPQ16 OAPQ90-OAPQ92;
     TITLE  "PATIENT QUALITY AREA-LEVEL INDICATOR AVERAGE OBSERVED RATE (MEAN) WHEN _TYPE_ =8";
RUN; QUIT;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA OBSERVED MEANS FILE --------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);

 PROC  PRINT DATA=OUTA2.&OUTFILA2. LABEL SPLIT='*';
 VAR   MAREA AGECAT SEXCAT RACECAT TAPQ&PQ. PAPQ&PQ. OAPQ&PQ. ;
 LABEL MAREA   = "MAREA"
       AGECAT  = "AGECAT"
       SEXCAT  = "SEXCAT"
       RACECAT = "RACECAT"
       TAPQ&PQ.   = "TAPQ&PQ.*(Numerator)"
       PAPQ&PQ.   = "PAPQ&PQ.*(Denominator)"
       OAPQ&PQ.   = "OAPQ&PQ.*(Observed)"
       ;
 FORMAT AGECAT AGECAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
	  TAPQ&PQ. PAPQ&PQ. COMMA13.0
	  OAPQ&PQ. 8.6
        ;
 TITLE4 "Indicator &PQ.: &TEXT";
 RUN;

 %MEND PRT;

 %PRT(01,Diabetes Short-Term Complications Admission Rate);
 %PRT(02,Perforated Appendix Admission Rate);
 %PRT(03,Diabetes Long-Term Complications Admission Rate);
 %PRT(05,Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate);
 %PRT(07,Hypertension Admission Rate);
 %PRT(08,Heart Failure Admission Rate);
 %PRT(10,Dehydration Admission Rate);
 %PRT(11,Bacterial Pneumonia Admission Rate);
 %PRT(12,Urinary Tract Infection Admission Rate);
 %PRT(13,Angina Without Procedure Admission Rate);
 %PRT(14,Uncontrolled Diabetes Admission Rate);
 %PRT(15,Asthma in Younger Adults Admission Rate);
 %PRT(16,Lower-Extremity Amputation among Patients with Diabetes Rate);
 %PRT(90,Prevention Quality Overall Composite);
 %PRT(91,Prevention Quality Acute Composite);
 %PRT(92,Prevention Quality Chronic Composite);

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
 FILE PQTEXTA2 LRECL=1000;
 IF _N_=1 THEN PUT "MAREA" "," "Age" "," "Sex" "," "Race" "," "Type" ","
 "TAPQ01" "," "TAPQ02" "," "TAPQ03" "," 
 "TAPQ05" "," "TAPQ07" "," "TAPQ08" ","
 "TAPQ10" "," "TAPQ11" "," "TAPQ12" "," 
 "TAPQ13" "," "TAPQ14" "," "TAPQ15" "," "TAPQ16" ","
 "TAPQ90" "," "TAPQ91" "," "TAPQ92" ","
 "PAPQ01" "," "PAPQ02" "," "PAPQ03" "," 
 "PAPQ05" "," "PAPQ07" "," "PAPQ08" ","
 "PAPQ10" "," "PAPQ11" "," "PAPQ12" "," 
 "PAPQ13" "," "PAPQ14" "," "PAPQ15" "," "PAPQ16" ","
 "PAPQ90" "," "PAPQ91" "," "PAPQ92" ","
 "OAPQ01" "," "OAPQ02" "," "OAPQ03" "," 
 "OAPQ05" "," "OAPQ07" "," "OAPQ08" ","
 "OAPQ10" "," "OAPQ11" "," "OAPQ12" "," 
 "OAPQ13" "," "OAPQ14" "," "OAPQ15" "," "OAPQ16" ","
 "OAPQ90" "," "OAPQ91" "," "OAPQ92";

 PUT MAREA $5. "," AGECAT 3. "," SEXCAT 3. "," RACECAT 3. "," _TYPE_ 2. ","
 (TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ16 TAPQ90-TAPQ92) (7.0 ",")
 ","
 (PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ16 PAPQ90-PAPQ92) (13.2 ",") 
 ","
 (OAPQ01-OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ10-OAPQ16 OAPQ90-OAPQ92) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXT;

 %TEXT;

