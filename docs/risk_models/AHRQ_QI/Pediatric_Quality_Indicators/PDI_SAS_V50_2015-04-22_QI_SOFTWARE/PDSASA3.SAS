*==================================================================;
*  Title:  PROGRAM A3 CALCULATES RISK-ADJUSTED AREA RATES FOR
*          AHRQ PEDIATRIC QUALITY INDICATORS
*
*  Description:
*         USES PROC SCORE TO CALCULATE RISK-ADJUSTED RATES FOR PEDIATRIC
*         QUALITY INDICATORS.
*         ADJUSTS FOR: AGE, SEXCAT AND POVCAT.
*
*          >>>  VERSION 5.0 - MARCH, 2015  <<<
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

 * --- THIS DATA STEP READS THE REGRESSION COEFFICIENTS FOR EACH - ;
 * --- COVARIATE.                                              --- ;

 DATA   TEMP2(KEEP=INTERCEP FEMALE AGECAT1-AGECAT4 FAGECAT1-FAGECAT4
                   POVCAT1-POVCAT10  
                   _NAME_ _TYPE_ _LINK_ _LNLIKE_ _STATUS_);
 LENGTH INTERCEP FEMALE AGECAT1-AGECAT4 FAGECAT1-FAGECAT4
        POVCAT1-POVCAT10 _LNLIKE_ 8
        _NAME_ _TYPE_ _LINK_ $8 _STATUS_ $11;
 INFILE COVARA MISSOVER LRECL=500;
 INPUT  N INTERCEP FEMALE AGECAT1-AGECAT4 FAGECAT1-FAGECAT4
        POVCAT1-POVCAT10  
        _NAME_ _TYPE_ _LINK_ _LNLIKE_ _STATUS_;

 IF N = &N.;

 RUN;

 * --- THIS PROC CALCULATES A PREDICTED INPATIENT QUALITY         - ;
 * --- INDICATOR FOR EACH OBSERVATION USING THE ACTUAL COVARIATES - ;
 * --- AND THE ESTIMATED COEFFICIENTS.                            - ;

 PROC   SCORE DATA=TEMP1 SCORE=TEMP2 TYPE=PARMS OUT=TEMP1Y;
 VAR    FEMALE AGECAT1-AGECAT4 FAGECAT1-FAGECAT4
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
 CLASS  MAREA POPCAT SEXCAT RACECAT;
 VAR    T&PD. EHAT PHAT ONE;
 OUTPUT OUT=R&PD. SUM(T&PD. EHAT PHAT ONE)=T&PD. EHAT PHAT P&PD.;
 WEIGHT PCOUNT;
 RUN;

 DATA   R&PD.(KEEP=MAREA POPCAT SEXCAT RACECAT _TYPE_
                   E&PD. R&PD. L&PD. U&PD. S&PD. X&PD.);
 SET    R&PD.;

 IF _TYPE_ &TYPELVLA;

 %INCLUDE MSXA;
 IF &N. = 14 THEN SUB_N = 1;
 IF &N. = 15 THEN SUB_N = 2;
 IF &N. = 16 THEN SUB_N = 3;
 IF &N. = 17 THEN SUB_N = 4;
 IF &N. = 18 THEN SUB_N = 5;
 IF &N. = 90 THEN SUB_N = 6;
 IF &N. = 91 THEN SUB_N = 7;
 IF &N. = 92 THEN SUB_N = 8;
 IF &N. = 60 THEN SUB_N = 9;

 E&PD. = EHAT / P&PD.;
 THAT = T&PD. / P&PD.;

 IF _TYPE_ IN (0,8) THEN DO;
    R&PD.   = (THAT / E&PD.) * ARRYA3(SUB_N);
    SE&PD.  = (ARRYA3(SUB_N) / E&PD.) * (1 / P&PD.) * SQRT(PHAT);
    VAR&PD. = SE&PD.**2;
    SN&PD.  = ARRYA2(SUB_N) / (ARRYA2(SUB_N) + VAR&PD.);
    S&PD.   = (R&PD. * SN&PD.) + ((1 -  SN&PD.) * ARRYA3(SUB_N));
    X&PD.   = SQRT(ARRYA2(SUB_N)- (SN&PD. * ARRYA2(SUB_N)));
 END;
 ELSE DO;
    R&PD.   = (THAT / E&PD.);
    SE&PD.  = (1 / E&PD.) * (1 / P&PD.) * SQRT(PHAT);
    S&PD.   = .;
    X&PD.   = .;
 END;

 L&PD.   = R&PD. - (1.96 * SE&PD.);
 IF L&PD. < 0 THEN L&PD. = 0;
 U&PD.   = R&PD. + (1.96 * SE&PD.);

 IF _TYPE_ IN (0,8) THEN DO; 
     IF L&PD. > 1 THEN L&PD. = 1; 
	 IF U&PD. > 1 THEN U&PD. = 1;
	 IF R&PD. > 1 THEN R&PD. = 1;
 END;

 RUN;

 %end;
 %else %do;

 DATA   R&PD.;
  
    MAREA='';POPCAT=.;SEXCAT=.;RACECAT=.;_TYPE_=0;_FREQ_=0;E&PD=.;R&PD=.;L&PD=.;U&PD=.;P&PD=.;S&PD=.;X&PD=.;
    OUTPUT;
 RUN;

 %end;

 PROC SORT DATA=R&PD.;
   BY MAREA POPCAT SEXCAT RACECAT;
 RUN; QUIT;

 /*PROC   DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP2;
 RUN;*/
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

 * --- MERGES THE MAREA ADJUSTED RATES FOR EACH PEDIATRIC QUALITY - ;
 * --- INDICATOR.  PREFIX FOR THE ADJUSTED RATES IS R(Risk      --- ;
 * --- Adjusted).                                               --- ;

 DATA   RISKADJ;
 MERGE  RAPD14(KEEP=MAREA POPCAT SEXCAT RACECAT EAPD14 RAPD14 LAPD14 UAPD14 SAPD14 XAPD14)
        RAPD15(KEEP=MAREA POPCAT SEXCAT RACECAT EAPD15 RAPD15 LAPD15 UAPD15 SAPD15 XAPD15)
        RAPD16(KEEP=MAREA POPCAT SEXCAT RACECAT EAPD16 RAPD16 LAPD16 UAPD16 SAPD16 XAPD16)
        RAPD17(KEEP=MAREA POPCAT SEXCAT RACECAT EAPD17 RAPD17 LAPD17 UAPD17 SAPD17 XAPD17)
        RAPD18(KEEP=MAREA POPCAT SEXCAT RACECAT EAPD18 RAPD18 LAPD18 UAPD18 SAPD18 XAPD18)
        RAPD90(KEEP=MAREA POPCAT SEXCAT RACECAT EAPD90 RAPD90 LAPD90 UAPD90 SAPD90 XAPD90)
        RAPD91(KEEP=MAREA POPCAT SEXCAT RACECAT EAPD91 RAPD91 LAPD91 UAPD91 SAPD91 XAPD91)
        RAPD92(KEEP=MAREA POPCAT SEXCAT RACECAT EAPD92 RAPD92 LAPD92 UAPD92 SAPD92 XAPD92)
        RAPQ09(KEEP=MAREA POPCAT SEXCAT RACECAT EAPQ09 RAPQ09 LAPQ09 UAPQ09 SAPQ09 XAPQ09);
 BY     MAREA POPCAT SEXCAT RACECAT;

 LABEL
 EAPD14 = 'PDI 14 Asthma Admission Rate (Expected)'
 EAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Expected)'
 EAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Expected)'
 EAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Expected)'
 EAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Expected)'
 EAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Expected)'
 EAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Expected)'
 EAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Expected)'
 EAPQ09 = 'PQI 09 Low Birth Weight Rate (Expected)'
 ;

 LABEL
 RAPD14 = 'PDI 14 Asthma Admission Rate (Risk Adj)'
 RAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Risk Adj)'
 RAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Risk Adj)'
 RAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Risk Adj)'
 RAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Risk Adj)'
 RAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Risk Adj)'
 RAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Risk Adj)'
 RAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Risk Adj)'
 RAPQ09 = 'PQI 09 Low Birth Weight Rate (Risk Adj)'
 ;

 LABEL
 LAPD14 = 'PDI 14 Asthma Admission Rate (Lower CL)'
 LAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Lower CL)'
 LAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Lower CL)'
 LAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Lower CL)'
 LAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Lower CL)'
 LAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Lower CL)'
 LAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Lower CL)'
 LAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Lower CL)'
 LAPQ09 = 'PQI 09 Low Birth Weight Rate (Lower CL)'
 ;

 LABEL
 UAPD14 = 'PDI 14 Asthma Admission Rate (Upper CL)'
 UAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Upper CL)'
 UAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Upper CL)'
 UAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Upper CL)'
 UAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Upper CL)'
 UAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Upper CL)'
 UAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Upper CL)'
 UAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Upper CL)'
 UAPQ09 = 'PQI 09 Low Birth Weight Rate (Upper CL)'
 ;

 LABEL
 SAPD14 = 'PDI 14 Asthma Admission Rate (Smoothed)'
 SAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Smoothed)'
 SAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Smoothed)'
 SAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Smoothed)'
 SAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Smoothed)'
 SAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Smoothed)'
 SAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Smoothed)'
 SAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Smoothed)'
 SAPQ09 = 'PQI 09 Low Birth Weight Rate (Smoothed)'
 ;

 LABEL
 XAPD14 = 'PDI 14 Asthma Admission Rate (Smthe SE)'
 XAPD15 = 'PDI 15 Diabetes Short-Term Complications Admission Rate (Smthe SE)'
 XAPD16 = 'PDI 16 Gastroenteritis Admission Rate (Smthe SE)'
 XAPD17 = 'PDI 17 Perforated Appendix Admission Rate (Smthe SE)'
 XAPD18 = 'PDI 18 Urinary Tract Infection Admission Rate (Smthe SE)'
 XAPD90 = 'PDI 90 Pediatric Quality Overall Composite (Smthe SE)'
 XAPD91 = 'PDI 91 Pediatric Quality Acute Composite (Smthe SE)'
 XAPD92 = 'PDI 92 Pediatric Quality Chronic Composite (Smthe SE)'
 XAPQ09 = 'PQI 09 Low Birth Weight Rate (Smthe SE)'
 ;

 RUN;

*==================================================================;
*  Title:  PROGRAM A3  PART II:  MERGE AREA RATES FOR HCUP
*          PEDIATRIC QUALITY INDICATORS
*
*  Description:  MERGE RATES FOR PEDIATRIC QUALITY INDICATORS
*
*          >>>  VERSION 5.0, NOV 2014     <<<
*
*===================================================================;

 TITLE2 'PROGRAM A3  PART III';
 TITLE3 'AHRQ PEDIATRIC QUALITY INDICATORS:  AREA-LEVEL MERGED FILES';

 * ---------------------------------------------------------------- ;
 * --- PEDIATRIC QUALITY INDICATOR MERGED RATES                --- ;
 * ---------------------------------------------------------------- ;

 DATA   OUTA3.&OUTFILA3.;
 MERGE  INA2.&INFILEA2.(
             KEEP=MAREA POPCAT SEXCAT RACECAT _TYPE_ 
                  TAPD14-TAPD18 TAPD90-TAPD92 TAPQ09  
                  PAPD14-PAPD18 PAPD90-PAPD92 PAPQ09  
                  OAPD14-OAPD18 OAPD90-OAPD92 OAPQ09)
             RISKADJ(KEEP=MAREA POPCAT SEXCAT RACECAT
                          EAPD14-EAPD18 EAPD90-EAPD92 EAPQ09
                          RAPD14-RAPD18 RAPD90-RAPD92 RAPQ09
                          LAPD14-LAPD18 LAPD90-LAPD92 LAPQ09
                          UAPD14-UAPD18 UAPD90-UAPD92 UAPQ09
                          SAPD14-SAPD18 SAPD90-SAPD92 SAPQ09
                          XAPD14-XAPD18 XAPD90-XAPD92 XAPQ09);
 BY     MAREA POPCAT SEXCAT RACECAT;

 ARRAY ARRY1{9} EAPD14-EAPD18 EAPD90-EAPD92 EAPQ09;
 ARRAY ARRY2{9} RAPD14-RAPD18 RAPD90-RAPD92 RAPQ09;
 ARRAY ARRY3{9} LAPD14-LAPD18 LAPD90-LAPD92 LAPQ09;
 ARRAY ARRY4{9} UAPD14-UAPD18 UAPD90-UAPD92 UAPQ09;
 ARRAY ARRY5{9} SAPD14-SAPD18 SAPD90-SAPD92 SAPQ09;
 ARRAY ARRY6{9} XAPD14-XAPD18 XAPD90-XAPD92 XAPQ09;
 ARRAY ARRY7{9} PAPD14-PAPD18 PAPD90-PAPD92 PAPQ09;

 DO I = 1 TO 9;
   IF ARRY7(I) <= 2 THEN DO;
      ARRY1(I) = .; ARRY2(I) = .; ARRY3(I) = .; ARRY4(I) = .;
      ARRY5(I) = .; ARRY6(I) = .; 
   END;
 END;

 DROP I;

 FORMAT EAPD14 EAPD15 EAPD16 EAPD17 EAPD18 EAPD90 EAPD91 EAPD92 EAPQ09
		LAPD14 LAPD15 LAPD16 LAPD17 LAPD18 LAPD90 LAPD91 LAPD92 LAPQ09
		OAPD14 OAPD15 OAPD16 OAPD17 OAPD18 OAPD90 OAPD91 OAPD92 OAPQ09
		RAPD14 RAPD15 RAPD16 RAPD17 RAPD18 RAPD90 RAPD91 RAPD92 RAPQ09
		SAPD14 SAPD15 SAPD16 SAPD17 SAPD18 SAPD90 SAPD91 SAPD92 SAPQ09
		UAPD14 UAPD15 UAPD16 UAPD17 UAPD18 UAPD90 UAPD91 UAPD92 UAPQ09
		XAPD14 XAPD15 XAPD16 XAPD17 XAPD18 XAPD90 XAPD91 XAPD92 XAPQ09 13.7
		TAPD14 TAPD15 TAPD16 TAPD17 TAPD18 TAPD90 TAPD91 TAPD92 TAPQ09
		PAPD14 PAPD15 PAPD16 PAPD17 PAPD18 PAPD90 PAPD91 PAPD92 PAPQ09 13.0;

 RUN;

 * ---------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF MAREA MERGED MEANS FILE             --- ;
 * ---------------------------------------------------------------- ;

 PROC CONTENTS DATA=OUTA3.&OUTFILA3. POSITION;
 RUN;

 PROC MEANS DATA=OUTA3.&OUTFILA3.(WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN SUM NOLABELS;
 TITLE4  'SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)';
 RUN;

 * ---------------------------------------------------------------- ;
 * --- PRINT AREA MERGED MEANS FILE                             --- ;
 * ---------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT);

 PROC   PRINT DATA=OUTA3.&OUTFILA3. LABEL SPLIT='*';
 VAR    MAREA POPCAT SEXCAT RACECAT 
        TA&PD. PA&PD. OA&PD. EA&PD. RA&PD. LA&PD. UA&PD. SA&PD. XA&PD.;
 LABEL MAREA    = "MAREA"
       POPCAT   = "POPCAT"
       SEXCAT   = "SEXCAT"
       RACECAT  = "RACECAT"
       TA&PD. = "TA&PD.*(Numerator)"
       PA&PD. = "PA&PD.*(Denominator)"
       OA&PD. = "OA&PD.*(Observed)"
       EA&PD. = "EA&PD.*(Expected)"
       RA&PD. = "RA&PD.*(Risk Adj)"
       LA&PD. = "LA&PD.*(Lower CL)"
       UA&PD. = "UA&PD.*(Upper CL)"
       SA&PD. = "SA&PD.*(Smoothed)"
       XA&PD. = "XA&PD.*(Smthe SE)"
       ;
 FORMAT POPCAT POPCAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
	  TA&PD. PA&PD. COMMA13.0
        OA&PD. EA&PD. RA&PD. LA&PD. UA&PD. SA&PD. XA&PD. 8.6;

 TITLE4 "FINAL OUTPUT";
 TITLE5 "Indicator &PD.: &TEXT";
 RUN;

 %MEND PRT;

 %PRT(PD14,Asthma Admission Rate);
 %PRT(PD15,Diabetes Short-Term Complications Admission Rate);
 %PRT(PD16,Gastroenteritis Admission Rate);
 %PRT(PD17,Perforated Appendix Admission Rate);
 %PRT(PD18,Urinary Tract Infection Admission Rate);
 %PRT(PD90,Pediatric Quality Overall Composite);
 %PRT(PD91,Pediatric Quality Acute Composite);
 %PRT(PD92,Pediatric Quality Chronic Composite);
 %PRT(PQ09,Low Birth Weight Rate);

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
 FILE PDTEXTA3 LRECL=2000;
 IF _N_=1 THEN PUT "MAREA" "," "Age"  "," "Sex"  "," "Race"  ","  "Type" ","
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
 "OAPQ09" "," 
 "EAPD14" "," "EAPD15" "," "EAPD16" "," 
 "EAPD17" "," "EAPD18" ","
 "EAPD90" "," "EAPD91" "," "EAPD92" ","
 "EAPQ09" "," 
 "RAPD14" "," "RAPD15" "," "RAPD16" "," 
 "RAPD17" "," "RAPD18" ","
 "RAPD90" "," "RAPD91" "," "RAPD92" ","
 "RAPQ09" "," 
 "LAPD14" "," "LAPD15" "," "LAPD16" "," 
 "LAPD17" "," "LAPD18" ","
 "LAPD90" "," "LAPD91" "," "LAPD92" ","
 "LAPQ09" "," 
 "UAPD14" "," "UAPD15" "," "UAPD16" "," 
 "UAPD17" "," "UAPD18" ","
 "UAPD90" "," "UAPD91" "," "UAPD92" ","
 "UAPQ09" "," 
 "SAPD14" "," "SAPD15" "," "SAPD16" "," 
 "SAPD17" "," "SAPD18" ","
 "SAPD90" "," "SAPD91" "," "SAPD92" ","
 "SAPQ09" "," 
 "XAPD14" "," "XAPD15" "," "XAPD16" "," 
 "XAPD17" "," "XAPD18" ","
 "XAPD90" "," "XAPD91" "," "XAPD92" "," 
 "XAPQ09"  
 ;

 PUT MAREA  $5. "," POPCAT 3. "," SEXCAT 3. "," RACECAT 3. "," _TYPE_ 2. ","
 (TAPD14-TAPD18 TAPD90-TAPD92 TAPQ09) (7.0 ",")
  ","
 (PAPD14-PAPD18 PAPD90-PAPD92 PAPQ09) (13.2 ",")
 ","
 (OAPD14-OAPD18 OAPD90-OAPD92 OAPQ09) (12.10 ",")
 ","
 (EAPD14-EAPD18 EAPD90-EAPD92 EAPQ09) (12.10 ",")
 ","
 (RAPD14-RAPD18 RAPD90-RAPD92 RAPQ09) (12.10 ",")
 ","
 (LAPD14-LAPD18 LAPD90-LAPD92 LAPQ09) (12.10 ",")
 ","
 (UAPD14-UAPD18 UAPD90-UAPD92 UAPQ09) (12.10 ",")
 ","
 (SAPD14-SAPD18 SAPD90-SAPD92 SAPQ09) (12.10 ",")
 ","
 (XAPD14-XAPD18 XAPD90-XAPD92 XAPQ09) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXT;

 %TEXT;
