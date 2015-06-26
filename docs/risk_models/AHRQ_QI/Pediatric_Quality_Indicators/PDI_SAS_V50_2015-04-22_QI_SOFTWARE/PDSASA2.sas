*===================================================================;
*
*  Title:  PROGRAM A2 CALCULATES OBSERVED AREA RATES FOR AHRQ
*          PEDIATRIC QUALITY INDICATORS
*
*  Description:
*         USES PROC SUMMARY TO CALCULATE OBSERVED RATES FOR
*         PEDIATRIC QUALITY INDICATORS ACROSS STRATIFIERS:
*         PROGRAM USES AREA, POPCAT, SEXCAT AND RACECAT
*
*            >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*===================================================================;


FILENAME CONTROL "C:\PATHNAME\CONTROL_PDI.SAS"; *<==USER MUST modify;

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
 TITLE3 'AHRQ PEDIATRIC QUALITY INDICATORS: CALCULATE ADJUSTED AREA RATES';

 * ---------------------------------------------------------------- ;
 * --- ADD POPULATION DENOMINATOR --------------------------------- ;
 * --- THIS STEP DETERMINES WHICH AREAS ARE INCLUDED IN THE     --- ;
 * --- OUTPUT FROM PROGRAM A1.                                  --- ;
 * ---------------------------------------------------------------- ;

 DATA   TEMP0;
 SET    IN1.&INFILE1.;

 %CTY2MA

 RUN;

 PROC   SORT DATA=TEMP0 (KEEP=MAREA) OUT=MAREA NODUPKEY;
 BY     MAREA;
 RUN;

 DATA QIPOP0;
    LENGTH FIPSTCO $5 SEXCAT POPCAT RACECAT 3 
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

    POP = POP_&POPYEAR.;

    IF POPCAT IN (1,2,3,4);

 RUN;

 PROC   SUMMARY DATA=QIPOP0 NWAY;
 CLASS  MAREA POPCAT SEXCAT RACECAT;
 VAR    POP;
 OUTPUT OUT=QIPOP SUM=;
 RUN;

 PROC   SORT DATA=QIPOP;
 BY     MAREA POPCAT SEXCAT RACECAT;
 RUN;

 DATA   QIPOP(KEEP=MAREA POPCAT SEXCAT RACECAT POP);
 MERGE  MAREA(IN=X) QIPOP(IN=Y);
 BY     MAREA;

 IF X AND Y;

 RUN;

 * -------------------------------------------------------------- ;
 * --- PEDIATRIC QUALITY INDICATORS ADJUSTED RATES ------------- ;
 * -------------------------------------------------------------- ;
 * --- THIS STEP SELECTS THE OBSERVATIONS FROM THE PROGRAM A1 --- ;
 * --- OUTPUT FOR EACH PEDIATRIC QUALITY INDICATOR IN TURN.  --- ;
 * --- EACH ITERATION PASSES VARIABLES THAT CONTROL THE       --- ;
 * --- COVARIATES FOR THAT PEDIATRIC QUALITY INDICATOR:      --- ;
 * --- N - OBSERVATION NUMBER FROM THE MEANS AND COVAR FILES  --- ;
 * ---     ALSO IDENTIFIES THE FORMAT USED TO INDEX COVARIATES -- ;
 * --- PD - THE PEDIATRIC QUALITY INDICATOR NAME WITHOUT THE --- ;
 *          PREFIX (A)                                        --- ;
 * -------------------------------------------------------------- ;

 %MACRO MOD3(N,PD,DL);

 * --- THIS SET CREATES TEMP1 WHICH CONTAINS THE DEPENDENT    --- ;
 * --- VARIABLE (TPD) AND INDEPENDENT VARIABLES USED IN       --- ;
 * --- REGRESSION.  IT APPENDS TO THE DISCHARGE DATA ONE      --- ;
 * --- OBSERVATION PER MAREA AND DEMOGRAPHIC GROUP.            --- ;

 %IF &DL. = 0 %THEN %DO;

 DATA   TEMP_2;
 SET    IN1.&INFILE1.(KEEP=KEY FIPSTCO T&PD. POPCAT SEXCAT RACECAT);

 IF T&PD. IN (1);
 IF POPCAT IN (1,2,3,4);

 %CTY2MA

 RUN;

 PROC   SUMMARY DATA=TEMP_2 NWAY;
 CLASS  MAREA POPCAT SEXCAT RACECAT;
 VAR    T&PD.;
 OUTPUT OUT=TEMP_3 N=TCOUNT;
 RUN;

 PROC   SORT DATA=TEMP_3;
 BY     MAREA POPCAT SEXCAT RACECAT;
 RUN;

 /* FOR ZERO, REDUCE THE WEIGHT BY THE NUMERATOR COUNT */;

 DATA   TEMP_4(DROP=TCOUNT N);
 MERGE  QIPOP(IN=X KEEP=MAREA POPCAT SEXCAT RACECAT POP) 
        TEMP_3(KEEP=MAREA POPCAT SEXCAT RACECAT TCOUNT);
 BY     MAREA POPCAT SEXCAT RACECAT;

 IF X;

 N = &N.;

 IF POPCAT IN (1) THEN DO;
    IF N = 14 THEN POP = POP * 0.60; /* AGE < 2 */
    IF N = 15 THEN POP = .;          /* AGE < 6 */
    IF N = 16 THEN POP = POP * 0.95; /* AGEDAY < 90 */
    IF N = 18 THEN POP = POP * 0.95; /* AGEDAY < 90 */
    IF N = 90 THEN POP = .;          /* AGE < 6 */
    IF N = 91 THEN POP = .;          /* AGE < 6 */
    IF N = 92 THEN POP = .;          /* AGE < 6 */
 END;
 ELSE IF POPCAT IN (2) THEN DO;
   IF N = 15 THEN POP = POP * 0.80; /* AGE < 6 */
   IF N = 90 THEN POP = POP * 0.80; /* AGE < 6 */
   IF N = 91 THEN POP = POP * 0.80; /* AGE < 6 */
   IF N = 92 THEN POP = POP * 0.80; /* AGE < 6 */
 END;

 IF TCOUNT > 0 THEN PCOUNT = POP - TCOUNT;
 ELSE PCOUNT = POP;

 IF PCOUNT < 0 THEN PCOUNT = 0;

 IF PCOUNT = 0 THEN DELETE;
 
 RUN;

 /* FOR ONE, RETAIN ONLY RECORDS WITH A VALID FIPS CODE */;

 DATA   TEMP_3(DROP=POP);
 MERGE  TEMP_3(IN=X KEEP=MAREA POPCAT SEXCAT RACECAT TCOUNT)
        QIPOP(KEEP=MAREA POPCAT SEXCAT RACECAT POP);
 BY     MAREA POPCAT SEXCAT RACECAT;

 IF X;

 IF POP < 0 THEN PCOUNT = 0;
 ELSE IF TCOUNT > 0 THEN PCOUNT = TCOUNT;
 ELSE PCOUNT = 0;

 IF PCOUNT = 0 THEN DELETE;
 
 RUN;

 /* COMBINE THE NUMERATOR AND DENOMINATOR */;

 DATA   TEMP1;
 SET    TEMP_3(IN=X) TEMP_4;

 IF X THEN T&PD. = 1;
 ELSE T&PD. = 0;

 RUN;

 %END;
 %ELSE %DO;

 DATA   TEMP_2;
 SET    IN1.&INFILE1.(KEEP=KEY FIPSTCO T&PD. POPCAT SEXCAT RACECAT);

 IF T&PD. IN (0,1);
 IF POPCAT IN (1,2,3,4);

 %CTY2MA

 RUN;

 PROC   SUMMARY DATA=TEMP_2 NWAY;
 CLASS  T&PD. MAREA POPCAT SEXCAT RACECAT;
 VAR    T&PD.;
 OUTPUT OUT=TEMP_3 N=TCOUNT;
 RUN;

 PROC   SORT DATA=TEMP_3;
 BY     MAREA POPCAT SEXCAT RACECAT;
 RUN;

 /* RETAIN ONLY RECORDS WITH A VALID FIPS CODE */;

 DATA   TEMP1;
 MERGE  TEMP_3(IN=X KEEP=MAREA POPCAT SEXCAT RACECAT TCOUNT T&PD.)
        QIPOP(KEEP=MAREA POPCAT SEXCAT RACECAT);
 BY     MAREA POPCAT SEXCAT RACECAT;

 IF X;

 IF TCOUNT > 0 THEN PCOUNT = TCOUNT;
 ELSE PCOUNT = 0;

 IF PCOUNT = 0 THEN DELETE;
 
 RUN;

 %END;

 DATA   TEMP1;
 LENGTH FEMALE AGECAT1-AGECAT4 FAGECAT1-FAGECAT4
        POVCAT1-POVCAT10 3;
 SET    TEMP1;

 IF SEXCAT IN (2) THEN FEMALE = 1;
 ELSE FEMALE = 0;

 ARRAY ARRY1{4} AGECAT1-AGECAT4;
 ARRAY ARRY2{4} FAGECAT1-FAGECAT4;

 DO I = 1 TO 4;
    ARRY1(I) = 0; ARRY2(I) = 0;
 END;

 ARRY1(POPCAT) = 1;
 ARRY2(POPCAT) = FEMALE;

 ARRAY ARRY3{10} POVCAT1-POVCAT10;

 DO I = 1 TO 10;
    ARRY3(I) = 0;
 END;

 PVIDX = PUT(MAREA,$POVCAT.);

 IF PVIDX > 0 THEN ARRY3(PVIDX) = 1;

 RUN;

 
 DATA   TEMP1Y;
 SET    TEMP1;

 ONE = 1;

 RUN;

 PROC   SUMMARY DATA=TEMP1Y;
 CLASS  MAREA POPCAT SEXCAT RACECAT;
 VAR    T&PD. ONE;
 OUTPUT OUT=ADJ_&PD. SUM(T&PD. ONE)=T&PD. P&PD.;
 WEIGHT PCOUNT;
 RUN;

 DATA   ADJ_&PD.(KEEP=MAREA POPCAT SEXCAT RACECAT _TYPE_ T&PD. P&PD.);
 SET    ADJ_&PD.;

 IF _TYPE_ &TYPELVLA;

 RUN;

 PROC SORT DATA=ADJ_&PD.;
     BY MAREA POPCAT SEXCAT RACECAT;
 RUN; QUIT;

 PROC   DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP_2 TEMP_3 TEMP_4;
 RUN;

 %MEND;

 %MOD3(14,APD14,0);
 %MOD3(15,APD15,0);
 %MOD3(16,APD16,0);
 %MOD3(17,APD17,1);
 %MOD3(18,APD18,0);
 %MOD3(90,APD90,0);
 %MOD3(91,APD91,0);
 %MOD3(92,APD92,0);
 %MOD3(60,APQ09,1);

 * --- MERGES THE MAREA ADJUSTED RATES FOR EACH PEDIATRIC QUALITY INDICATOR.  - ;
 * --- PREFIX FOR THE ADJUSTED RATES IS ADJ( Adjusted)                      --- ;
 
DATA TEMP2Y;
  MERGE ADJ_APD14 ADJ_APD15 ADJ_APD16 ADJ_APD17 ADJ_APD18 
        ADJ_APD90 ADJ_APD91 ADJ_APD92 ADJ_APQ09;
  BY MAREA POPCAT  SEXCAT RACECAT;
RUN;

 DATA &OUTFILA2.;
 SET TEMP2Y;

 ARRAY PPD2{9} PAPD14-PAPD18 PAPD90-PAPD92 PAPQ09;
 ARRAY TPD{9}  TAPD14-TAPD18 TAPD90-TAPD92 TAPQ09;
 ARRAY OPD{9}  OAPD14-OAPD18 OAPD90-OAPD92 OAPQ09;

 DO J = 1 to 9;
    IF TPD{J} GT 0 AND PPD2{J} GT 0 THEN OPD{J} = TPD{J} / PPD2{J};
    ELSE IF PPD2{J} GT 0 THEN OPD{J} = 0;
 END;

 LABEL
 TAPD14 = 'PDI 14 Asthma Admission Rate (Numerator)'
 TAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Numerator)'
 TAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Numerator)'
 TAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Numerator)'
 TAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Numerator)'
 TAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Numerator)'
 TAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Numerator)'
 TAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Numerator)'
 TAPQ09 = 'PQI 09 Low Birth Weight Rate (Numerator)'
 ;
 LABEL
 PAPD14 = 'PDI 14 Asthma Admission Rate (Population)'
 PAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Population)'
 PAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Population)'
 PAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Population)'
 PAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Population)'
 PAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Population)'
 PAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Population)'
 PAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Population)'
 PAPQ09 = 'PQI 09 Low Birth Weight Rate (Population)'
 ;
 LABEL
 OAPD14 = 'PDI 14 Asthma Admission Rate (Observed)'
 OAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Observed)'
 OAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Observed)'
 OAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Observed)'
 OAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Observed)'
 OAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Observed)'
 OAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Observed)'
 OAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Observed)'
 OAPQ09 = 'PQI 09 Low Birth Weight Rate (Observed)'
 _TYPE_ = 'STRATIFICATION LEVEL'
 ;

 DROP J;

 RUN;

 PROC SORT DATA=&OUTFILA2. OUT=OUTA2.&OUTFILA2.;
 BY MAREA POPCAT SEXCAT RACECAT;
 RUN;

PROC DATASETS NOLIST;
  DELETE MAREA QIPOP QIPOP0 TEMP0 TEMP2Y
         ADJ_APD14 ADJ_APD15 ADJ_APD16 ADJ_APD17 ADJ_APD18 
         ADJ_APD90 ADJ_APD92 ADJ_APQ09;
RUN; QUIT;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA OBSERVED MEANS FILE ----------- ;
 * -------------------------------------------------------------- ;

 PROC CONTENTS DATA=OUTA2.&OUTFILA2. POSITION;
 RUN;

 *PROC MEANS DATA=OUTA2.&OUTFILA2.(WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN SUM NOLABELS;
 *TITLE4 "SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)";
 *RUN;

 ***----- TO PRINT VARIABLE LABLES COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX SUM NOLABELS;
   VAR TAPD14-TAPD18 TAPD90-TAPD92 TAPQ09;
   TITLE  'SUMMARY OF PEDIATRIC AREA-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=8';
RUN; QUIT;

PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX SUM NOLABELS;
   VAR PAPD14-PAPD18 PAPD90-PAPD92 PAPQ09 ;
   TITLE  'SUMMARY OF PEDIATRIC AREA-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=8';
RUN; QUIT;

PROC MEANS DATA=OUTA2.&OUTFILA2. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN NOLABELS;
   VAR OAPD14-OAPD18 OAPD90-OAPD92 OAPQ09;
   TITLE  'SUMMARY OF PEDIATRIC AREA-LEVEL OBSERVED INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=8';
RUN; QUIT;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA OBSERVED MEANS FILE --------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT);

 PROC  PRINT DATA=OUTA2.&OUTFILA2. LABEL SPLIT='*';
 VAR   MAREA POPCAT SEXCAT RACECAT TA&PD. PA&PD. OA&PD. ;
 LABEL MAREA    = "MAREA"
       POPCAT   = "POPCAT"
       SEXCAT   = "SEXCAT"
       RACECAT  = "RACECAT"
       TA&PD.   = "TA&PD.*(Numerator)"
       PA&PD.   = "PA&PD.*(Denominator)"
       OA&PD.   = "OA&PD.*(Observed)"
       ;
 FORMAT POPCAT POPCAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
        TA&PD. PA&PD. COMMA13.0
        OA&PD. 8.6
        ;
 TITLE4 "Indicator &PD.: &TEXT";
 RUN;

 %MEND PRT;

 %PRT(PD14,Asthma Admission Rate);
 %PRT(PD15,Diabetes Short-Term Complications Admission Rate);
 %PRT(PD16,Gastroenteritis Admission Rate);
 %PRT(PD17,Perforated Appendix Admission Rate);
 %PRT(PD18,Urinary Tract Infection Admission Rate);
 %PRT(PQ09,Low Birth Weight Rate);

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
 FILE PDTEXTA2 LRECL=1000;
 IF _N_=1 THEN PUT "MAREA"  "," "Age"  "," "Sex"  "," "Race"  "," "Type" ","
 "TAPD14" "," "TAPD15" "," "TAPD16" "," 
 "TAPD17" "," "TAPD18" ","
 "TAPD90" "," "TAPD91" "," "TAPD92" ","
 "TAPQ09" "," 
 "PAPD14" "," "PAPD15" "," "PAPD16" ","
 "PAPD17" "," "PAPD18" ","
 "PAPD90" "," "PAPD91" "," "PAPD92" ","
 "PAPQ09" "," 
 "OAPD14" "," "OAPD15" "," "OAPD16" ","
 "OAPD17" "," "OAPD18" ","
 "OAPD90" "," "OAPD91" "," "OAPD92" ","
 "OAPQ09"  
;

 PUT MAREA $5. "," POPCAT 3. "," SEXCAT 3. "," RACECAT 3.  "," _TYPE_ 2.  ","
 (TAPD14-TAPD18 TAPD90-TAPD92 TAPQ09) (7.0 ",")
 ","
 (PAPD14-PAPD18 PAPD90-PAPD92 PAPQ09) (13.2 ",")
 ","
 (OAPD14-OAPD18 OAPD90-OAPD92 OAPQ09) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXT;

 %TEXT;
