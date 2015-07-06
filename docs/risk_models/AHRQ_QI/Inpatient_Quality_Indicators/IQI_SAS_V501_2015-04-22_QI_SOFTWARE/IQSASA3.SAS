*===================================================================;
*  Title:  PROGRAM A3 CALCULATES RISK-ADJUSTED AREA RATES
*          FOR AHRQ INPATIENT QUALITY INDICATORS
*
*  Description:
*         USES PROC SCORE TO CALCULATE RISK-ADJUSTED RATES FOR
*         INPATIENT QUALITY INDICATORS.
*         ADJUSTS FOR: AGE AND SEXCAT.
*
*          >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*===================================================================;
FILENAME CONTROL 'C:\PATHNAME\CONTROL_IQI.SAS';  *<===USER MUST modify; 

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

 * --- THIS DATA STEP READS THE REGRESSION COEFFICIENTS FOR EACH - ;
 * --- COVARIATE.                                              --- ;

 DATA   TEMP2(KEEP=INTERCEP FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14
                   _NAME_ _TYPE_ _LINK_ _LNLIKE_ _STATUS_);
 LENGTH INTERCEP FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14
        _LNLIKE_ 8
        _NAME_ _TYPE_ _LINK_ $8 _STATUS_ $11;
 INFILE COVARA MISSOVER LRECL=1500;
 INPUT  N INTERCEP FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14
        _NAME_ _TYPE_ _LINK_ _LNLIKE_ _STATUS_;

 IF N = &N.;

 RUN;

 * --- THIS PROC CALCULATES A PREDICTED INPATIENT QUALITY         - ;
 * --- INDICATOR FOR EACH OBSERVATION USING THE ACTUAL COVARIATES - ;
 * --- AND THE ESTIMATED COEFFICIENTS.                            - ;

 PROC   SCORE DATA=TEMP1 SCORE=TEMP2 TYPE=PARMS OUT=TEMP1Y;
 VAR    FEMALE AGECAT1-AGECAT14 FAGECAT1-FAGECAT14;
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
 VAR    T&IQ. EHAT PHAT ONE;
 OUTPUT OUT=R&IQ. SUM(T&IQ. EHAT PHAT ONE)=T&IQ. EHAT PHAT P&IQ.;
 WEIGHT   PCOUNT;
 RUN;

 DATA   R&IQ.(KEEP=MAREA AGECAT SEXCAT RACECAT _TYPE_
                   E&IQ. R&IQ. L&IQ. U&IQ. S&IQ. X&IQ.);
 SET    R&IQ.;

 IF _TYPE_ &TYPELVLA;

 %INCLUDE MSXA;
 IF &N. = 26 THEN SUB_N = 1;
 IF &N. = 27 THEN SUB_N = 2;
 IF &N. = 28 THEN SUB_N = 3;
 IF &N. = 29 THEN SUB_N = 4;

 E&IQ. = EHAT / P&IQ.;
 THAT = T&IQ. / P&IQ.;
 
 IF _TYPE_ IN (0,8) THEN DO;
    R&IQ.   = (THAT / E&IQ.) * ARRYA3(SUB_N);
    SE&IQ.  = (ARRYA3(SUB_N) / E&IQ.) * (1 / P&IQ.) * SQRT(PHAT);
    VAR&IQ. = SE&IQ.**2;
    SN&IQ.  = ARRYA2(SUB_N) / (ARRYA2(SUB_N) + VAR&IQ.);
    S&IQ.   = (R&IQ. * SN&IQ.) + ((1 -  SN&IQ.) * ARRYA3(SUB_N));
    X&IQ.   = SQRT(ARRYA2(SUB_N)- (SN&IQ. * ARRYA2(SUB_N)));
 END;
 ELSE DO;
    R&IQ.   = (THAT / E&IQ.);
    SE&IQ.  = (1 / E&IQ.) * (1 / P&IQ.) * SQRT(PHAT);
    S&IQ.   = .;
    X&IQ.   = .;
 END;

 L&IQ.   = R&IQ. - (1.96 * SE&IQ.);
 IF L&IQ. < 0 THEN L&IQ. = 0;
 U&IQ.   = R&IQ. + (1.96 * SE&IQ.);


 IF _TYPE_ IN (0,8) THEN DO; 
     IF L&IQ. > 1 THEN L&IQ. = 1; 
	 IF U&IQ. > 1 THEN U&IQ. = 1;
	 IF R&IQ. > 1 THEN R&IQ. = 1;
 END;

 RUN;

 %end;
 %else %do;

 DATA   R&IQ.;
    MAREA='';AGECAT=.;SEXCAT=.;RACECAT=.;_TYPE_=0;E&IQ=.;R&IQ=.;L&IQ=.;U&IQ=.;S&IQ=.;X&IQ=.;
    OUTPUT;
 RUN;

 %end;


 PROC SORT DATA=R&IQ.;
   BY MAREA AGECAT SEXCAT RACECAT;
 RUN; QUIT;

 PROC   DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP2;
 RUN;

 %MEND;

 %MOD3(26,AIQ26);
 %MOD3(27,AIQ27);
 %MOD3(28,AIQ28);
 %MOD3(29,AIQ29);

 * --- MERGES THE AREA ADJUSTED RATES FOR EACH INPATIENT        - ;
 * --- QUALITY INDICATOR.  PREFIX FOR THE ADJUSTED RATES IS     - ;
 * --- R(Risk Adjusted).                                        - ;

 DATA   RISKADJ;
 MERGE  RAIQ26(KEEP=MAREA AGECAT SEXCAT RACECAT EAIQ26 RAIQ26 LAIQ26 UAIQ26 SAIQ26 XAIQ26)
        RAIQ27(KEEP=MAREA AGECAT SEXCAT RACECAT EAIQ27 RAIQ27 LAIQ27 UAIQ27 SAIQ27 XAIQ27)
        RAIQ28(KEEP=MAREA AGECAT SEXCAT RACECAT EAIQ28 RAIQ28 LAIQ28 UAIQ28 SAIQ28 XAIQ28)
        RAIQ29(KEEP=MAREA AGECAT SEXCAT RACECAT EAIQ29 RAIQ29 LAIQ29 UAIQ29 SAIQ29 XAIQ29);
 BY     MAREA AGECAT SEXCAT RACECAT;

 LABEL
 EAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Expected)'
 EAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Expected)'
 EAIQ28 = 'IQI 28 Hysterectomy Rate (Expected)'
 EAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Expected)'
 ;             
               
 LABEL         
 RAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Risk Adj)'
 RAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Risk Adj)'
 RAIQ28 = 'IQI 28 Hysterectomy Rate (Risk Adj)'
 RAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Risk Adj)'
 ;             
               
 LABEL         
 LAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Lower CL)'
 LAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Lower CL)'
 LAIQ28 = 'IQI 28 Hysterectomy Rate (Lower CL)'
 LAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Lower CL)'
 ;             
               
 LABEL         
 UAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Upper CL)'
 UAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Upper CL)'
 UAIQ28 = 'IQI 28 Hysterectomy Rate (Upper CL)'
 UAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Upper CL)'
 ;             
               
 LABEL         
 SAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Smoothed)'
 SAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Smoothed)'
 SAIQ28 = 'IQI 28 Hysterectomy Rate (Smoothed)'
 SAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Smoothed)'
 ;             
               
 LABEL         
 XAIQ26 = 'IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Smthe SE)'
 XAIQ27 = 'IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Smthe SE)'
 XAIQ28 = 'IQI 28 Hysterectomy Rate (Smthe SE)'
 XAIQ29 = 'IQI 29 Laminectomy or Spinal Fusion Rate (Smthe SE)'
 ;

 RUN;

*==================================================================;
*  Title:  PROGRAM A3  PART II:  MERGE AREA RATES FOR HCUP
*          INPATIENT QUALITY INDICATORS
*
*  Description:  MERGE RATES FOR INPATIENT QUALITY INDICATORS
*
*          >>>  VERSION 5.0, NOV 2014     <<<
*
*==================================================================;

 TITLE2 'PROGRAM A3  PART II';
 TITLE3 'AHRQ INPATIENT QUALITY INDICATORS: AREA-LEVEL MERGED FILES';

 * ---------------------------------------------------------------- ;
 * --- INPATIENT QUALITY INDICATOR MERGED RATES                   - ;
 * ---------------------------------------------------------------- ;

 DATA   OUTA3.&OUTFILA3.;
 MERGE  INA2.&INFILEA2.(
            KEEP=MAREA AGECAT SEXCAT RACECAT _TYPE_ 
                 TAIQ26-TAIQ29 
                 PAIQ26-PAIQ29 
                 OAIQ26-OAIQ29)
        RISKADJ(
            KEEP=MAREA AGECAT SEXCAT RACECAT
                 EAIQ26-EAIQ29 
                 RAIQ26-RAIQ29 
                 LAIQ26-LAIQ29 
                 UAIQ26-UAIQ29
                 SAIQ26-SAIQ29
                 XAIQ26-XAIQ29);
 BY MAREA AGECAT SEXCAT RACECAT;

 ARRAY ARRY1{4} EAIQ26-EAIQ29;
 ARRAY ARRY2{4} RAIQ26-RAIQ29;
 ARRAY ARRY3{4} LAIQ26-LAIQ29;
 ARRAY ARRY4{4} UAIQ26-UAIQ29;
 ARRAY ARRY5{4} SAIQ26-SAIQ29;
 ARRAY ARRY6{4} XAIQ26-XAIQ29;
 ARRAY ARRY7{4} PAIQ26-PAIQ29;

 DO I = 1 TO 4;
   IF ARRY7(I) <= 2 THEN DO;
      ARRY1(I) = .; ARRY2(I) = .; ARRY3(I) = .; ARRY4(I) = .;
      ARRY5(I) = .; ARRY6(I) = .; 
   END;
 END;

 DROP I;

 FORMAT EAIQ26 EAIQ27 EAIQ28 EAIQ29 
		LAIQ26 LAIQ27 LAIQ28 LAIQ29
		OAIQ26 OAIQ27 OAIQ28 OAIQ29
		RAIQ26 RAIQ27 RAIQ28 RAIQ29
		SAIQ26 SAIQ27 SAIQ28 SAIQ29
		UAIQ26 UAIQ27 UAIQ28 UAIQ29
		XAIQ26 XAIQ27 XAIQ28 XAIQ29 13.7
		TAIQ26 TAIQ27 TAIQ28 TAIQ29
		PAIQ26 PAIQ27 PAIQ28 PAIQ29 13.0;
 RUN;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF AREA MERGED MEANS FILE ------------- ;
 * -------------------------------------------------------------- ;

 PROC CONTENTS DATA=OUTA3.&OUTFILA3. POSITION;
 RUN;

 PROC MEANS DATA=OUTA3.&OUTFILA3. (WHERE=(_TYPE_ IN (8))) N NMISS MIN MAX MEAN SUM NOLABELS;
 TITLE4  'SUMMARY OF AREA-LEVEL RATES (_TYPE_=8)';
 RUN;

 * -------------------------------------------------------------- ;
 * --- PRINT AREA MERGED MEANS FILE ----------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(IQ,TEXT);

 PROC  PRINT DATA=OUTA3.&OUTFILA3. LABEL SPLIT='*';
 VAR   MAREA AGECAT SEXCAT RACECAT 
       TAIQ&IQ. PAIQ&IQ. OAIQ&IQ. EAIQ&IQ. RAIQ&IQ. LAIQ&IQ. UAIQ&IQ. SAIQ&IQ. XAIQ&IQ.;
 LABEL MAREA      = "MAREA"
       AGECAT   = "AGECAT"
       SEXCAT   = "SEXCAT"
       RACECAT  = "RACECAT"
       TAIQ&IQ.   = "TAIQ&IQ.*(Numerator)"
       PAIQ&IQ.   = "PAIQ&IQ.*(Denominator)"
       OAIQ&IQ.   = "OAIQ&IQ.*(Observed)"
       EAIQ&IQ.   = "EAIQ&IQ.*(Expected)"
       RAIQ&IQ.   = "RAIQ&IQ.*(Risk Adj)"
       LAIQ&IQ.   = "LAIQ&IQ.*(Lower CL)"
       UAIQ&IQ.   = "UAIQ&IQ.*(Upper CL)"
       SAIQ&IQ.   = "SAIQ&IQ.*(Smoothed)"
       XAIQ&IQ.   = "XAIQ&IQ.*(Smthe SE)"
       ;

 FORMAT AGECAT AGECAT.   
        SEXCAT SEXCAT.
        RACECAT RACECAT.
	  TAIQ&IQ. PAIQ&IQ. COMMA13.0
        OAIQ&IQ. EAIQ&IQ. RAIQ&IQ. LAIQ&IQ. UAIQ&IQ. SAIQ&IQ. XAIQ&IQ. 8.6
        ;

 TITLE4 "FINAL OUTPUT";
 TITLE5 "Indicator &IQ.: &TEXT";

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
 * --- WRITE SAS OUTPUT DATA SET TO TEXT FILE ------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXT;

 %IF &TEXTA3. = 1  %THEN %DO;

 DATA _NULL_;
 SET OUTA3.&OUTFILA3;
 FILE IQTEXTA3 LRECL=500;
 IF _N_=1 THEN PUT "MAREA" "," "Age"  "," "Sex"  "," "Race" "," "Type" ","
 "TAIQ26" "," "TAIQ27" "," "TAIQ28" "," "TAIQ29" ","
 "PAIQ26" "," "PAIQ27" "," "PAIQ28" "," "PAIQ29" ","
 "OAIQ26" "," "OAIQ27" "," "OAIQ28" "," "OAIQ29" ","
 "EAIQ26" "," "EAIQ27" "," "EAIQ28" "," "EAIQ29" ","
 "RAIQ26" "," "RAIQ27" "," "RAIQ28" "," "RAIQ29" ","
 "LAIQ26" "," "LAIQ27" "," "LAIQ28" "," "LAIQ29" ","
 "UAIQ26" "," "UAIQ27" "," "UAIQ28" "," "UAIQ29" ","
 "SAIQ26" "," "SAIQ27" "," "SAIQ28" "," "SAIQ29" ","
 "XAIQ26" "," "XAIQ27" "," "XAIQ28" "," "XAIQ29"
 ;

 PUT MAREA $5. "," AGECAT 3. "," SEXCAT 3. "," RACECAT 3. "," _TYPE_ 2. ","
 (TAIQ26-TAIQ29) (7.0 ",")
  ","
 (PAIQ26-PAIQ29) (13.2 ",")
 ","
 (OAIQ26-OAIQ29) (12.10 ",")
 ","
 (EAIQ26-EAIQ29) (12.10 ",")
 ","
 (RAIQ26-RAIQ29) (12.10 ",")
 ","
 (LAIQ26-LAIQ29) (12.10 ",")
 ","
 (UAIQ26-UAIQ29) (12.10 ",")
 ","
 (SAIQ26-SAIQ29) (12.10 ",")
 ","
 (XAIQ26-XAIQ29) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXT;

 %TEXT;
