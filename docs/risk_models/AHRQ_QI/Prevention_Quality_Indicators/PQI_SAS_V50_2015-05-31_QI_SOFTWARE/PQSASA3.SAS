*==================================================================;
*  Title:  PROGRAM A3 CALCULATES RISK-ADJUSTED AREA RATES FOR
*          AHRQ PREVENTION QUALITY INDICATORS
*
*  Description:
*         USES PROC SCORE TO CALCULATE RISK-ADJUSTED RATES FOR PREVENTION
*         QUALITY INDICATORS.
*         ADJUSTS FOR: AGE, SEXCAT AND POVCAT.
*
*                 >>>  VERSION 5.0 - MARCH, 2015   <<<
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

 * --- THIS DATA STEP READS THE REGRESSION COEFFICIENTS FOR EACH - ;
 * --- COVARIATE.                                              --- ;

 DATA   TEMP2(KEEP=INTERCEP FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14
                   POVCAT1-POVCAT10  
                   _NAME_ _TYPE_ _LINK_ _LNLIKE_ _STATUS_);
 LENGTH INTERCEP FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14
        POVCAT1-POVCAT10 _LNLIKE_ 8
        _NAME_ _TYPE_ _LINK_ $8 _STATUS_ $11;
 INFILE COVARA MISSOVER LRECL=1500;
 INPUT  N INTERCEP FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14
        POVCAT1-POVCAT10  
        _NAME_ _TYPE_ _LINK_ _LNLIKE_ _STATUS_;

 IF N = &N.;

 RUN;

 * --- THIS PROC CALCULATES A PREDICTED INPATIENT QUALITY         - ;
 * --- INDICATOR FOR EACH OBSERVATION USING THE ACTUAL COVARIATES - ;
 * --- AND THE ESTIMATED COEFFICIENTS.                            - ;

 PROC   SCORE DATA=TEMP1 SCORE=TEMP2 TYPE=PARMS OUT=TEMP1Y;
 VAR    FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14
        POVCAT1-POVCAT10;
 RUN;

 %let dsid=%sysfunc(open(temp1y));
 %let dnum=%sysfunc(attrn(&dsid,nobs));
 %let drc=%sysfunc(close(&dsid));

 %if &dnum ne 0 %then %do;

 DATA   TEMP1Y;
 SET    TEMP1Y;

 EHAT = EXP(MHAT)/(1 + EXP(MHAT));
 PHAT = EHAT * (1 - EHAT);
 ONE = 1;

 RUN;

 PROC   SUMMARY DATA=TEMP1Y;
 CLASS  MAREA AGECAT SEXCAT RACECAT;
 VAR    T&PQ. EHAT PHAT ONE;
 OUTPUT OUT=R&PQ. SUM(T&PQ. EHAT PHAT ONE)=T&PQ. EHAT PHAT P&PQ.;
 WEIGHT PCOUNT;
 RUN;

 DATA   R&PQ.(KEEP=MAREA AGECAT SEXCAT RACECAT _TYPE_
                   E&PQ. R&PQ. L&PQ. U&PQ. S&PQ. X&PQ.);
 SET    R&PQ.;

 IF _TYPE_ &TYPELVLA;

 %INCLUDE MSXA;
 IF &N. = 1 THEN SUB_N = 1;
 IF &N. = 2 THEN SUB_N = 2;
 IF &N. = 3 THEN SUB_N = 3;
 IF &N. = 5 THEN SUB_N = 4;
 IF &N. = 7 THEN SUB_N = 5;
 IF &N. = 8 THEN SUB_N = 6;
 IF &N. = 10 THEN SUB_N = 7;
 IF &N. = 11 THEN SUB_N = 8;
 IF &N. = 12 THEN SUB_N = 9;
 IF &N. = 13 THEN SUB_N = 10;
 IF &N. = 14 THEN SUB_N = 11;
 IF &N. = 15 THEN SUB_N = 12;
 IF &N. = 16 THEN SUB_N = 13;
 IF &N. = 90 THEN SUB_N = 14;
 IF &N. = 91 THEN SUB_N = 15;
 IF &N. = 92 THEN SUB_N = 16;

 E&PQ. = EHAT / P&PQ.;
 THAT = T&PQ. / P&PQ.;
 
 IF _TYPE_ IN (0,8) THEN DO;
    R&PQ.   = (THAT / E&PQ.) * ARRYA3(SUB_N);
    SE&PQ.  = (ARRYA3(SUB_N) / E&PQ.) * (1 / P&PQ.) * SQRT(PHAT);
    VAR&PQ. = SE&PQ.**2;
    SN&PQ.  = ARRYA2(SUB_N) / (ARRYA2(SUB_N) + VAR&PQ.);
    S&PQ.   = (R&PQ. * SN&PQ.) + ((1 -  SN&PQ.) * ARRYA3(SUB_N));
    X&PQ.   = SQRT(ARRYA2(SUB_N)- (SN&PQ. * ARRYA2(SUB_N)));
 END;
 ELSE DO;
    R&PQ.   = (THAT / E&PQ.);
    SE&PQ.  = (1 / E&PQ.) * (1 / P&PQ.) * SQRT(PHAT);
    S&PQ.   = .;
    X&PQ.   = .;
 END;

 L&PQ.   = R&PQ. - (1.96 * SE&PQ.);
 IF L&PQ. < 0 THEN L&PQ. = 0;
 U&PQ.   = R&PQ. + (1.96 * SE&PQ.);


 IF _TYPE_ IN (0,8) THEN DO;  
     IF L&PQ. > 1 THEN L&PQ. = 1; 
     IF U&PQ. > 1 THEN U&PQ. = 1;
     IF R&PQ. > 1 THEN R&PQ. = 1;
 END;

 RUN;

 %end;
 %else %do;

 DATA   R&PQ.;
    MAREA='';AGECAT=.;SEXCAT=.;RACECAT=.;_TYPE_=0;E&PQ=.;R&PQ=.;L&PQ=.;U&PQ=.;S&PQ=.;X&PQ=.;
    OUTPUT;
 RUN;
 
 %end;


 PROC SORT DATA=R&PQ.;
   BY MAREA AGECAT SEXCAT RACECAT;
 RUN; QUIT;

 PROC   DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP2;
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

 * --- MERGES THE MAREA ADJUSTED RATES FOR EACH PREVENTION QUALITY - ;
 * --- INDICATOR.  PREFIX FOR THE ADJUSTED RATES IS R(Risk      --- ;
 * --- Adjusted).                                               --- ;

 DATA   RISKADJ;
 MERGE  RAPQ01(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ01 RAPQ01 LAPQ01 UAPQ01 SAPQ01 XAPQ01)
        RAPQ02(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ02 RAPQ02 LAPQ02 UAPQ02 SAPQ02 XAPQ02)
        RAPQ03(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ03 RAPQ03 LAPQ03 UAPQ03 SAPQ03 XAPQ03)
        RAPQ05(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ05 RAPQ05 LAPQ05 UAPQ05 SAPQ05 XAPQ05)
        RAPQ07(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ07 RAPQ07 LAPQ07 UAPQ07 SAPQ07 XAPQ07)
        RAPQ08(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ08 RAPQ08 LAPQ08 UAPQ08 SAPQ08 XAPQ08)
        RAPQ10(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ10 RAPQ10 LAPQ10 UAPQ10 SAPQ10 XAPQ10)
        RAPQ11(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ11 RAPQ11 LAPQ11 UAPQ11 SAPQ11 XAPQ11)
        RAPQ12(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ12 RAPQ12 LAPQ12 UAPQ12 SAPQ12 XAPQ12)
        RAPQ13(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ13 RAPQ13 LAPQ13 UAPQ13 SAPQ13 XAPQ13)
        RAPQ14(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ14 RAPQ14 LAPQ14 UAPQ14 SAPQ14 XAPQ14)
        RAPQ15(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ15 RAPQ15 LAPQ15 UAPQ15 SAPQ15 XAPQ15)
        RAPQ16(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ16 RAPQ16 LAPQ16 UAPQ16 SAPQ16 XAPQ16)
        RAPQ90(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ90 RAPQ90 LAPQ90 UAPQ90 SAPQ90 XAPQ90)
        RAPQ91(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ91 RAPQ91 LAPQ91 UAPQ91 SAPQ91 XAPQ91)
        RAPQ92(KEEP=MAREA AGECAT SEXCAT RACECAT EAPQ92 RAPQ92 LAPQ92 UAPQ92 SAPQ92 XAPQ92);
 BY     MAREA AGECAT SEXCAT RACECAT;

 LABEL
 EAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Expected)'
 EAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Expected)'
 EAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Expected)'
 EAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Expected)'
 EAPQ07 = 'PQI 07 Hypertension Admission Rate (Expected)'
 EAPQ08 = 'PQI 08 Heart Failure Admission Rate (Expected)'
 EAPQ10 = 'PQI 10 Dehydration Admission Rate (Expected)'
 EAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Expected)'
 EAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Expected)'
 EAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Expected)'
 EAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Expected)'
 EAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Expected)'
 EAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Expected)'
 EAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Expected)'
 EAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Expected)'
 EAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Expected)'
 ;

 LABEL
 RAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Risk Adj)'
 RAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Risk Adj)'
 RAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Risk Adj)'
 RAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Risk Adj)'
 RAPQ07 = 'PQI 07 Hypertension Admission Rate (Risk Adj)'
 RAPQ08 = 'PQI 08 Heart Failure Admission Rate (Risk Adj)'
 RAPQ10 = 'PQI 10 Dehydration Admission Rate (Risk Adj)'
 RAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Risk Adj)'
 RAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Risk Adj)'
 RAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Risk Adj)'
 RAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Risk Adj)'
 RAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Risk Adj)'
 RAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Risk Adj)'
 RAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Risk Adj)'
 RAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Risk Adj)'
 RAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Risk Adj)'
 ;

 LABEL
 LAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Lower CL)'
 LAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Lower CL)'
 LAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Lower CL)'
 LAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Lower CL)'
 LAPQ07 = 'PQI 07 Hypertension Admission Rate (Lower CL)'
 LAPQ08 = 'PQI 08 Heart Failure Admission Rate (Lower CL)'
 LAPQ10 = 'PQI 10 Dehydration Admission Rate (Lower CL)'
 LAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Lower CL)'
 LAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Lower CL)'
 LAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Lower CL)'
 LAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Lower CL)'
 LAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Lower CL)'
 LAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Lower CL)'
 LAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Lower CL)'
 LAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Lower CL)'
 LAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Lower CL)'
 ;

 LABEL
 UAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Upper CL)'
 UAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Upper CL)'
 UAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Upper CL)'
 UAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Upper CL)'
 UAPQ07 = 'PQI 07 Hypertension Admission Rate (Upper CL)'
 UAPQ08 = 'PQI 08 Heart Failure Admission Rate (Upper CL)'
 UAPQ10 = 'PQI 10 Dehydration Admission Rate (Upper CL)'
 UAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Upper CL)'
 UAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Upper CL)'
 UAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Upper CL)'
 UAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Upper CL)'
 UAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Upper CL)'
 UAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Upper CL)'
 UAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Upper CL)'
 UAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Upper CL)'
 UAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Upper CL)'
 ;

 LABEL
 SAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Smoothed)'
 SAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Smoothed)'
 SAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Smoothed)'
 SAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Smoothed)'
 SAPQ07 = 'PQI 07 Hypertension Admission Rate (Smoothed)'
 SAPQ08 = 'PQI 08 Heart Failure Admission Rate (Smoothed)'
 SAPQ10 = 'PQI 10 Dehydration Admission Rate (Smoothed)'
 SAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Smoothed)'
 SAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Smoothed)'
 SAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Smoothed)'
 SAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Smoothed)'
 SAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Smoothed)'
 SAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Smoothed)'
 SAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Smoothed)'
 SAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Smoothed)'
 SAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Smoothed)'
 ;

 LABEL
 XAPQ01 = 'PQI 01 Diabetes Short-Term Complications Admission Rate (Smthe SE)'
 XAPQ02 = 'PQI 02 Perforated Appendix Admission Rate (Smthe SE)'
 XAPQ03 = 'PQI 03 Diabetes Long-Term Complications Admission Rate (Smthe SE)'
 XAPQ05 = 'PQI 05 Chronic Obstructive Pulmonary Disease (COPD) or Asthma in Older Adults Admission Rate (Smthe SE)'
 XAPQ07 = 'PQI 07 Hypertension Admission Rate (Smthe SE)'
 XAPQ08 = 'PQI 08 Heart Failure Admission Rate (Smthe SE)'
 XAPQ10 = 'PQI 10 Dehydration Admission Rate (Smthe SE)'
 XAPQ11 = 'PQI 11 Bacterial Pneumonia Admission Rate (Smthe SE)'
 XAPQ12 = 'PQI 12 Urinary Tract Infection Admission Rate (Smthe SE)'
 XAPQ13 = 'PQI 13 Angina Without Procedure Admission Rate (Smthe SE)'
 XAPQ14 = 'PQI 14 Uncontrolled Diabetes Admission Rate (Smthe SE)'
 XAPQ15 = 'PQI 15 Asthma in Younger Adults Admission Rate (Smthe SE)'
 XAPQ16 = 'PQI 16 Lower-Extremity Amputation among Patients with Diabetes Rate (Smthe SE)'
 XAPQ90 = 'PQI 90 Prevention Quality Overall Composite (Smthe SE)'
 XAPQ91 = 'PQI 91 Prevention Quality Acute Composite (Smthe SE)'
 XAPQ92 = 'PQI 92 Prevention Quality Chronic Composite (Smthe SE)'
 ;

 RUN;

*==================================================================;
*  Title:  PROGRAM A3  PART II:  MERGE AREA RATES FOR HCUP
*          PREVENTION QUALITY INDICATORS
*
*  Description:  MERGE RATES FOR PREVENTION QUALITY INDICATORS
*
*               >>>  VERSION 5.0 - MARCH, 2015   <<<
*
*===================================================================;

 TITLE2 'PROGRAM A3  PART II';
 TITLE3 'AHRQ PREVENTION QUALITY INDICATORS:  AREA-LEVEL MERGED FILES';

 * ---------------------------------------------------------------- ;
 * --- PREVENTION QUALITY INDICATOR MERGED RATES                --- ;
 * ---------------------------------------------------------------- ;

 DATA   OUTA3.&OUTFILA3.;
 MERGE  INA2.&INFILEA2.(
            KEEP=MAREA AGECAT SEXCAT RACECAT _TYPE_ 
                 TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ16 TAPQ90-TAPQ92
                 PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ16 PAPQ90-PAPQ92 
                 OAPQ01-OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ10-OAPQ16 OAPQ90-OAPQ92)
        RISKADJ(
            KEEP=MAREA AGECAT SEXCAT RACECAT
                 EAPQ01-EAPQ03 EAPQ05 EAPQ07-EAPQ08 EAPQ10-EAPQ16 EAPQ90-EAPQ92
                 RAPQ01-RAPQ03 RAPQ05 RAPQ07-RAPQ08 RAPQ10-RAPQ16 RAPQ90-RAPQ92
                 LAPQ01-LAPQ03 LAPQ05 LAPQ07-LAPQ08 LAPQ10-LAPQ16 LAPQ90-LAPQ92
                 UAPQ01-UAPQ03 UAPQ05 UAPQ07-UAPQ08 UAPQ10-UAPQ16 UAPQ90-UAPQ92
                 SAPQ01-SAPQ03 SAPQ05 SAPQ07-SAPQ08 SAPQ10-SAPQ16 SAPQ90-SAPQ92
                 XAPQ01-XAPQ03 XAPQ05 XAPQ07-XAPQ08 XAPQ10-XAPQ16 XAPQ90-XAPQ92);
 BY     MAREA AGECAT SEXCAT RACECAT;

 ARRAY ARRY1{16} EAPQ01-EAPQ03 EAPQ05 EAPQ07-EAPQ08 EAPQ10-EAPQ16 EAPQ90-EAPQ92;
 ARRAY ARRY2{16} RAPQ01-RAPQ03 RAPQ05 RAPQ07-RAPQ08 RAPQ10-RAPQ16 RAPQ90-RAPQ92;
 ARRAY ARRY3{16} LAPQ01-LAPQ03 LAPQ05 LAPQ07-LAPQ08 LAPQ10-LAPQ16 LAPQ90-LAPQ92;
 ARRAY ARRY4{16} UAPQ01-UAPQ03 UAPQ05 UAPQ07-UAPQ08 UAPQ10-UAPQ16 UAPQ90-UAPQ92;
 ARRAY ARRY5{16} SAPQ01-SAPQ03 SAPQ05 SAPQ07-SAPQ08 SAPQ10-SAPQ16 SAPQ90-SAPQ92;
 ARRAY ARRY6{16} XAPQ01-XAPQ03 XAPQ05 XAPQ07-XAPQ08 XAPQ10-XAPQ16 XAPQ90-XAPQ92;
 ARRAY ARRY7{16} PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ16 PAPQ90-PAPQ92;

 DO I = 1 TO 16;
   IF ARRY7(I) <= 2 THEN DO;
      ARRY1(I) = .; ARRY2(I) = .; ARRY3(I) = .; ARRY4(I) = .;
      ARRY5(I) = .; ARRY6(I) = .; 
   END;
 END;

 DROP I;

 FORMAT EAPQ01 EAPQ02 EAPQ03 EAPQ05 EAPQ07 EAPQ08 EAPQ10 EAPQ11 EAPQ12 
        EAPQ13 EAPQ14 EAPQ15 EAPQ16 EAPQ90 EAPQ91 EAPQ92
        LAPQ01 LAPQ02 LAPQ03 LAPQ05 LAPQ07 LAPQ08 LAPQ10 LAPQ11 LAPQ12
        LAPQ13 LAPQ14 LAPQ15 LAPQ16 LAPQ90 LAPQ91 LAPQ92
        OAPQ01 OAPQ02 OAPQ03 OAPQ05 OAPQ07 OAPQ08 OAPQ10 OAPQ11 OAPQ12
        OAPQ13 OAPQ14 OAPQ15 OAPQ16 OAPQ90 OAPQ91 OAPQ92
        RAPQ01 RAPQ02 RAPQ03 RAPQ05 RAPQ07 RAPQ08 RAPQ10 RAPQ11 RAPQ12
        RAPQ13 RAPQ14 RAPQ15 RAPQ16 RAPQ90 RAPQ91 RAPQ92
        SAPQ01 SAPQ02 SAPQ03 SAPQ05 SAPQ07 SAPQ08 SAPQ10 SAPQ11 SAPQ12
        SAPQ13 SAPQ14 SAPQ15 SAPQ16 SAPQ90 SAPQ91 SAPQ92
        UAPQ01 UAPQ02 UAPQ03 UAPQ05 UAPQ07 UAPQ08 UAPQ10 UAPQ11 UAPQ12
        UAPQ13 UAPQ14 UAPQ15 UAPQ16 UAPQ90 UAPQ91 UAPQ92
        XAPQ01 XAPQ02 XAPQ03 XAPQ05 XAPQ07 XAPQ08 XAPQ10 XAPQ11 XAPQ12
        XAPQ13 XAPQ14 XAPQ15 XAPQ16 XAPQ90 XAPQ91 XAPQ92 13.7
        TAPQ01 TAPQ02 TAPQ03 TAPQ05 TAPQ07 TAPQ08 TAPQ10 TAPQ11 TAPQ12
        TAPQ13 TAPQ14 TAPQ15 TAPQ16 TAPQ90 TAPQ91 TAPQ92 
        PAPQ01 PAPQ02 PAPQ03 PAPQ05 PAPQ07 PAPQ08 PAPQ10 PAPQ11 PAPQ12
        PAPQ13 PAPQ14 PAPQ15 PAPQ16 PAPQ90 PAPQ91 PAPQ92 13.0;

 RUN;

 * ---------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MAREA MERGED MEANS FILE             --- ;
 * ---------------------------------------------------------------- ;

 PROC CONTENTS DATA=OUTA3.&OUTFILA3. POSITION;
 RUN;

 PROC MEANS DATA=OUTA3.&OUTFILA3.(WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN SUM NOLABELS;
 TITLE4 'SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)';
 RUN;

 * ---------------------------------------------------------------- ;
 * --- PRINT AREA MERGED MEANS FILE                             --- ;
 * ---------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PQ,TEXT);

 PROC  PRINT DATA=OUTA3.&OUTFILA3. LABEL SPLIT='*';
 VAR   MAREA AGECAT SEXCAT RACECAT 
       TAPQ&PQ. PAPQ&PQ. OAPQ&PQ. EAPQ&PQ. RAPQ&PQ. LAPQ&PQ. UAPQ&PQ. SAPQ&PQ. XAPQ&PQ.;
 LABEL MAREA    = "MAREA"
       AGECAT   = "AGECAT"
       SEXCAT   = "SEXCAT"
       RACECAT  = "RACECAT"
       TAPQ&PQ. = "TAPQ&PQ.*(Numerator)"
       PAPQ&PQ. = "PAPQ&PQ.*(Denominator)"
       OAPQ&PQ. = "OAPQ&PQ.*(Observed)"
       EAPQ&PQ. = "EAPQ&PQ.*(Expected)"
       RAPQ&PQ. = "RAPQ&PQ.*(Risk Adj)"
       LAPQ&PQ. = "LAPQ&PQ.*(Lower CL)"
       UAPQ&PQ. = "UAPQ&PQ.*(Upper CL)"
       SAPQ&PQ. = "SAPQ&PQ.*(Smoothed)"
       XAPQ&PQ. = "XAPQ&PQ.*(Smthe SE)"
       ;

 FORMAT AGECAT AGECAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
      TAPQ&PQ. PAPQ&PQ. COMMA13.0
        OAPQ&PQ. EAPQ&PQ. RAPQ&PQ. LAPQ&PQ. UAPQ&PQ. SAPQ&PQ. XAPQ&PQ. 8.6;

 TITLE4 "FINAL OUTPUT";
 TITLE5 "Indicator  &PQ.: &TEXT";

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

 %MEND PRT2 ;

 %PRT2;

 * ---------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO TEXT FILE                   --- ;
 * ---------------------------------------------------------------- ;

 %MACRO TEXT;

 %IF &TEXTA3. = 1  %THEN %DO;

 DATA _NULL_;
 SET OUTA3.&OUTFILA3;
 FILE PQTEXTA3 LRECL=2000;
 IF _N_=1 THEN PUT "MAREA" "," "Age"  "," "Sex"  "," "Race"  "," "Type" ","
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
 "OAPQ90" "," "OAPQ91" "," "OAPQ92" ","
 "EAPQ01" "," "EAPQ02" "," "EAPQ03" "," 
 "EAPQ05" "," "EAPQ07" "," "EAPQ08" ","
 "EAPQ10" "," "EAPQ11" "," "EAPQ12" "," 
 "EAPQ13" "," "EAPQ14" "," "EAPQ15" "," "EAPQ16" ","
 "EAPQ90" "," "EAPQ91" "," "EAPQ92" ","
 "RAPQ01" "," "RAPQ02" "," "RAPQ03" "," 
 "RAPQ05" "," "RAPQ07" "," "RAPQ08" ","
 "RAPQ10" "," "RAPQ11" "," "RAPQ12" "," 
 "RAPQ13" "," "RAPQ14" "," "RAPQ15" "," "RAPQ16" ","
 "RAPQ90" "," "RAPQ91" "," "RAPQ92" ","
 "LAPQ01" "," "LAPQ02" "," "LAPQ03" "," 
 "LAPQ05" "," "LAPQ07" "," "LAPQ08" ","
 "LAPQ10" "," "LAPQ11" "," "LAPQ12" "," 
 "LAPQ13" "," "LAPQ14" "," "LAPQ15" "," "LAPQ16" ","
 "LAPQ90" "," "LAPQ91" "," "LAPQ92" ","
 "UAPQ01" "," "UAPQ02" "," "UAPQ03" "," 
 "UAPQ05" "," "UAPQ07" "," "UAPQ08" ","
 "UAPQ10" "," "UAPQ11" "," "UAPQ12" "," 
 "UAPQ13" "," "UAPQ14" "," "UAPQ15" "," "UAPQ16" ","
 "UAPQ90" "," "UAPQ91" "," "UAPQ92" ","
 "SAPQ01" "," "SAPQ02" "," "SAPQ03" "," 
 "SAPQ05" "," "SAPQ07" "," "SAPQ08" ","
 "SAPQ10" "," "SAPQ11" "," "SAPQ12" "," 
 "SAPQ13" "," "SAPQ14" "," "SAPQ15" "," "SAPQ16" ","
 "SAPQ90" "," "SAPQ91" "," "SAPQ92" ","
 "XAPQ01" "," "XAPQ02" "," "XAPQ03" "," 
 "XAPQ05" "," "XAPQ07" "," "XAPQ08" ","
 "XAPQ10" "," "XAPQ11" "," "XAPQ12" ","
 "XAPQ13" "," "XAPQ14" "," "XAPQ15" "," "XAPQ16" ","
 "XAPQ90" "," "XAPQ91" "," "XAPQ92" 
 ;

 PUT MAREA  $5. "," AGECAT 3. "," SEXCAT 3. "," RACECAT 3.  "," _TYPE_ 2.  ","
 (TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ16 TAPQ90-TAPQ92) (7.0 ",")
  ","
 (PAPQ01-PAPQ03 PAPQ05 PAPQ07-PAPQ08 PAPQ10-PAPQ16 PAPQ90-PAPQ92) (13.2 ",")
 ","
 (OAPQ01-OAPQ03 OAPQ05 OAPQ07-OAPQ08 OAPQ10-OAPQ16 OAPQ90-OAPQ92) (12.10 ",")
 ","
 (EAPQ01-EAPQ03 EAPQ05 EAPQ07-EAPQ08 EAPQ10-EAPQ16 EAPQ90-EAPQ92) (12.10 ",")
 ","
 (RAPQ01-RAPQ03 RAPQ05 RAPQ07-RAPQ08 RAPQ10-RAPQ16 RAPQ90-RAPQ92) (12.10 ",")
 ","
 (LAPQ01-LAPQ03 LAPQ05 LAPQ07-LAPQ08 LAPQ10-LAPQ16 LAPQ90-LAPQ92) (12.10 ",")
 ","
 (UAPQ01-UAPQ03 UAPQ05 UAPQ07-UAPQ08 UAPQ10-UAPQ16 UAPQ90-UAPQ92) (12.10 ",")
 ","
 (SAPQ01-SAPQ03 SAPQ05 SAPQ07-SAPQ08 SAPQ10-SAPQ16 SAPQ90-SAPQ92) (12.10 ",")
 ","
 (XAPQ01-XAPQ03 XAPQ05 XAPQ07-XAPQ08 XAPQ10-XAPQ16 XAPQ90-XAPQ92) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXT;

 %TEXT;
