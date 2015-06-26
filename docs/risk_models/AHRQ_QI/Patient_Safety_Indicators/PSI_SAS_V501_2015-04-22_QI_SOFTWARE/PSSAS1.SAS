*======================================	 PROGRAM: PSSAS1.SAS  =======================================;
*====================================================================================================;
*  Title:  PROGRAM 1 ASSIGNS AHRQ PATIENT SAFETY INDICATORS
*          TO INPATIENT RECORDS
*
*  Description:
*         ASSIGNS THE OUTCOME OF INTEREST AND POPULATION AT RISK
*         INDICATORS TO INPATIENT RECORDS.  ALSO ASSIGNS 
*         COMORBIDITY CATEGORIES.
*
*          		>>>   VERSION 5.0 - MARCH, 2015  <<<
*
*  USER NOTE1: Make sure you have created the format library
*              using PSFMTS.SAS BEFORE running this program.
*
*  USER NOTE2: Version 5.0 The AHRQ QI software does not support the calculation of weighted estimates 
*			   and standard errors using complex sampling designs. Beginning with v4.5A, all references 
*			   to a discharge weight (DISCWT) have been removed from all programs. In order to obtain 
*			   weighted nationally representative estimates, please refer to the technical documentation
*			   on the AHRQ QI website.
*===================================================================================================;
FILENAME CONTROL "C:\PATHNAME\CONTROL_PSI.SAS"; *<==USER MUST modify;

%INCLUDE CONTROL;

 TITLE2 'PROGRAM 1';
 TITLE3 'AHRQ PATIENT SAFETY INDICATORS: ASSIGN PSIS TO INPATIENT DATA';

 * -------------------------------------------------------------- ;
 * --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS THAT --- ; 
 * --- WILL NOT BE INCLUDED IN ANALYSIS BECAUSE KEY VARIABLE  --- ;
 * --- VALUES ARE MISSING								      --- ;
 * -------------------------------------------------------------- ;

 DATA   OUT1.&DELFILE1.
 	(KEEP=KEY HOSPID SEX AGE DX1 MDC YEAR DQTR);
  SET 	IN0.&INFILE0.;
 IF (AGE LT 0) OR  (AGE LT 18 AND MDC NOTIN (14)) OR (SEX LE 0) OR 
	(COMPRESS(DX1) IN ('')) OR (DQTR LE .Z) OR (YEAR LE .Z);
 RUN;


 * -------------------------------------------------------------- ;
 * --- PATIENT SAFETY INDICATOR (PSI) NAMING CONVENTION:      --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PATIENT SAFETY         --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:
                (O) OBSERVED RATES
                (E) EXPECTED RATES
                (R) RISK-ADJUSTED RATES
                (S) SMOOTHED RATES
                (T) NUMERATOR ("TOP")
                (P) POPULATION ("POP")
                (Q) EXCLUSION FLAG BASED ON POA OR PALLATIVE CARE
 * --- THE SECOND LETTER IDENTIFIES THE PSI AS A PROVIDER (P) --- ;
 * --- OR AN AREA (A) LEVEL INDICATOR.  THE                   --- ;
 * --- NEXT TWO CHARACTERS ARE ALWAYS 'PS'. THE LAST TWO      --- ;
 * --- DIGITS ARE THE INDICATOR NUMBER (WITHIN THAT SUBTYPE). --- ;
 * -------------------------------------------------------------- ;

 %MACRO ADDPRDAY; 
    %IF &PRDAY EQ 1 %THEN PRDAY1-PRDAY&NPR. ;
 %MEND;

 %MACRO SETPOA ;
    %*-------------------------------*;
    %* ASSIGN NOPOA AT THE FILE LEVEL*;
    %* BASED ON CONTROL FILE MACRO   *;
    %* USEPOA.                       *;
    %*-------------------------------*;
   %IF &USEPOA.=1 %THEN %DO ;
     NOPOA=0 ;
   %END ;
   %ELSE %IF &USEPOA.=0 %THEN %DO ;
     NOPOA=1 ; 
   %END ; 
 %MEND ; 

 DATA   OUT1.&OUTFILE1. 
    (KEEP=KEY HOSPID FIPST FIPSTCO DRG DRGVER MDC MDRG YEAR DQTR 
          AGECAT POPCAT SEXCAT RACECAT PAYCAT DUALCAT
          LOS TRNSFER MAXDX MAXPR PALLIAFG 
          NOPOUB04 NOPRDAY TRNSOUT ECDDX NOPOA
          CHF VALVE PULMCIRC PERIVASC HTN_C
          PARA NEURO CHRNLUNG DM DMCX
          HYPOTHY RENLFAIL LIVER ULCER AIDS
          LYMPH METS TUMOR ARTH OBESE
          WGHTLOSS BLDLOSS ANEMDEF ALCOHOL DRUG
          PSYCH DEPRESS 
          XHF XALVE XULMCIRC XERIVASC XTN_C
          XARA XEURO XHRNLUNG XM XMCX
          XYPOTHY XENLFAIL XIVER XLCER XIDS
          XYMPH XETS XUMOR XRTH XBESE
          XGHTLOSS XLDLOSS XNEMDEF XLCOHOL XRUG
          XSYCH XEPRESS 
          TPPS02-TPPS04  TPPS04A--TPPS04E TPPS05-TPPS16 TPPS18 TPPS19
          QPPS02-QPPS04  QPPS04A--QPPS04E QPPS05-QPPS16 TAPS21-TAPS27
          PPPS02-PPPS04  PPPS04A--PPPS04E PPPS05-PPPS16 PPPS18 PPPS19);

 SET   IN0.&INFILE0. 
      (KEEP=KEY HOSPID DRG DRGVER MDC SEX AGE AGEDAY PSTCO   
            RACE YEAR DQTR PAY1 PAY2 DNR
            DISP LOS ASOURCE POINTOFORIGINUB04 ATYPE
            DX1-DX&NDX. PR1-PR&NPR. %ADDPRDAY 
            DXPOA1-DXPOA&NDX.);
 *--------------------------------------------------------------- ;
 * ----  POA INDICATOR AT THE DATA SET LEVEL.               ----- ;
 *--------------------------------------------------------------- ;
  ATTRIB NOPOA LENGTH=3 LABEL="NO POA, 1=NO POA AVAILABLE, 0=POA AVAILABLE" ; 
  %SETPOA ;
 * -------------------------------------------------------------- ;
 * --- DIAGNOSIS AND PROCEDURE MACROS       --------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO MDX(FMT);

 (%DO I = 1 %TO &NDX.-1;
  (PUT(DX&I.,&FMT.) = '1') OR
  %END;
  (PUT(DX&NDX.,&FMT.) = '1'))

 %MEND;

 %MACRO MDX1(FMT);

 (PUT(DX1,&FMT.) = '1')

 %MEND;

 %MACRO MDX2(FMT);

 (%DO I = 2 %TO &NDX.-1;
  (PUT(DX&I.,&FMT.) = '1') OR
  %END;
  (PUT(DX&NDX.,&FMT.) = '1'))

 %MEND;

 %MACRO MDX2Q1(FMT);

 (%DO I = 2 %TO &NDX.-1;
  (PUT(DX&I.,$poaxmpt.)='0' AND PUT(DX&I.,&FMT.) = '1' AND DXPOA&I. IN ('N','U',' ','E','1','X')) OR
  %END;
  (PUT(DX&NDX.,$poaxmpt.)='0' AND PUT(DX&NDX.,&FMT.) = '1' AND DXPOA&NDX. IN ('N','U',' ','E','1','X')))

 %MEND;

 %MACRO MDX2Q2(FMT);

 (%DO I = 2 %TO &NDX.-1;
  (PUT(DX&I.,$poaxmpt.)='0' AND PUT(DX&I.,&FMT.) = '1' AND DXPOA&I. IN ('Y','W')) OR
  (PUT(DX&I.,$poaxmpt.)='1' AND PUT(DX&I.,&FMT.) = '1') OR
  %END;
  (PUT(DX&NDX.,$poaxmpt.)='0' AND PUT(DX&NDX.,&FMT.) = '1' AND DXPOA&NDX. IN ('Y','W')) OR
  (PUT(DX&NDX.,$poaxmpt.)='1' AND PUT(DX&NDX.,&FMT.) = '1') )

 %MEND;

 %MACRO MDR(FMT);

 (PUT(PUT(DRG,Z3.),&FMT.) = '1')

 %MEND;

 %MACRO MPR(FMT);

 (%DO I = 1 %TO &NPR.-1;
  (PUT(PR&I.,&FMT.) = '1') OR
  %END;
  (PUT(PR&NPR.,&FMT.) = '1'))

 %MEND;

 %MACRO MPR1(FMT);

 (PUT(PR1,&FMT.) = '1')

 %MEND;

 %MACRO MPR2(FMT);

 (%DO I = 2 %TO &NPR.-1;
  (PUT(PR&I.,&FMT.) = '1') OR
  %END;
  (PUT(PR&NPR.,&FMT.) = '1'))

 %MEND;

 %MACRO MPRCNT(FMT);

    MPRCNT = 0; 
    %DO I = 1 %TO &NPR.;
       IF PUT(PR&I.,&FMT.) = '1'    AND
          PUT(PR&I.,$ORPROC.) = '1' THEN MPRCNT + 1;
    %END;

 %MEND;

 %MACRO MPRDAY(FMT);

    MPRDAY = .;
    %DO I = 1 %TO &NPR.;
       IF PUT(PR&I.,&FMT.) = '1' AND PRDAY&I. GT .Z THEN DO;
          IF MPRDAY LE .Z THEN MPRDAY = PRDAY&I;
          ELSE IF MPRDAY > PRDAY&I. THEN MPRDAY = PRDAY&I;
       END;
    %END;

 %MEND;


%MACRO ORCNT;

    ORCNT = 0;
    %DO I = 1 %TO &NPR.;
       IF PUT(PR&I.,$ORPROC.) = '1' THEN ORCNT + 1;
    %END;

%MEND;

%MACRO ORDAY(FMT);

    ORDAY = .;
    %DO I = 1 %TO &NPR.;
       IF PUT(PR&I.,$ORPROC.) = '1' AND
          PUT(PR&I.,&FMT.)    = '0' THEN DO;
          IF PRDAY&I. GT .Z THEN DO;
             IF ORDAY = . THEN ORDAY = PRDAY&I;
             ELSE IF ORDAY > PRDAY&I. THEN ORDAY = PRDAY&I;
          END;
       END;
    %END;

%MEND;


 * -------------------------------------------------------------- ;
 * --- DEFINE MDC                        ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB MDCNEW LENGTH=3
   LABEL='IMPUTED MDC';

 IF DRGVER = . THEN DO;
    IF (YEAR IN (1994) AND DQTR IN (4))     THEN DRGVER = 12;
    ELSE IF (YEAR IN (1995) AND DQTR IN (1,2,3)) THEN DRGVER = 12;
    ELSE IF (YEAR IN (1995) AND DQTR IN (4))     THEN DRGVER = 13;
    ELSE IF (YEAR IN (1996) AND DQTR IN (1,2,3)) THEN DRGVER = 13;
    ELSE IF (YEAR IN (1996) AND DQTR IN (4))     THEN DRGVER = 14;
    ELSE IF (YEAR IN (1997) AND DQTR IN (1,2,3)) THEN DRGVER = 14;
    ELSE IF (YEAR IN (1997) AND DQTR IN (4))     THEN DRGVER = 15;
    ELSE IF (YEAR IN (1998) AND DQTR IN (1,2,3)) THEN DRGVER = 15;
    ELSE IF (YEAR IN (1998) AND DQTR IN (4))     THEN DRGVER = 16;
    ELSE IF (YEAR IN (1999) AND DQTR IN (1,2,3)) THEN DRGVER = 16;
    ELSE IF (YEAR IN (1999) AND DQTR IN (4))     THEN DRGVER = 17;
    ELSE IF (YEAR IN (2000) AND DQTR IN (1,2,3)) THEN DRGVER = 17;
    ELSE IF (YEAR IN (2000) AND DQTR IN (4))     THEN DRGVER = 18;
    ELSE IF (YEAR IN (2001) AND DQTR IN (1,2,3)) THEN DRGVER = 18;
    ELSE IF (YEAR IN (2001) AND DQTR IN (4))     THEN DRGVER = 19;
    ELSE IF (YEAR IN (2002) AND DQTR IN (1,2,3)) THEN DRGVER = 19;
    ELSE IF (YEAR IN (2002) AND DQTR IN (4))     THEN DRGVER = 20;
    ELSE IF (YEAR IN (2003) AND DQTR IN (1,2,3)) THEN DRGVER = 20;
    ELSE IF (YEAR IN (2003) AND DQTR IN (4))     THEN DRGVER = 21;
    ELSE IF (YEAR IN (2004) AND DQTR IN (1,2,3)) THEN DRGVER = 21;
    ELSE IF (YEAR IN (2004) AND DQTR IN (4))     THEN DRGVER = 22;
    ELSE IF (YEAR IN (2005) AND DQTR IN (1,2,3)) THEN DRGVER = 22;
    ELSE IF (YEAR IN (2005) AND DQTR IN (4))     THEN DRGVER = 23;
    ELSE IF (YEAR IN (2006) AND DQTR IN (1,2,3)) THEN DRGVER = 23;
    ELSE IF (YEAR IN (2006) AND DQTR IN (4))     THEN DRGVER = 24;
    ELSE IF (YEAR IN (2007) AND DQTR IN (1,2,3)) THEN DRGVER = 24;
    ELSE IF (YEAR IN (2007) AND DQTR IN (4))     THEN DRGVER = 25;
    ELSE IF (YEAR IN (2008) AND DQTR IN (1,2,3)) THEN DRGVER = 25;
    ELSE IF (YEAR IN (2008) AND DQTR IN (4))     THEN DRGVER = 26;
    ELSE IF (YEAR IN (2009) AND DQTR IN (1,2,3)) THEN DRGVER = 26;
    ELSE IF (YEAR IN (2009) AND DQTR IN (4)) 	 THEN DRGVER = 27;
    ELSE IF (YEAR IN (2010) AND DQTR IN (1,2,3)) THEN DRGVER = 27;
	ELSE IF (YEAR IN (2010) AND DQTR IN (4)) 	 THEN DRGVER = 28;
  ELSE IF (YEAR IN (2011) AND DQTR IN (1,2,3)) THEN DRGVER = 28;
  ELSE IF (YEAR IN (2011) AND DQTR IN (4)) 	 THEN DRGVER = 29;
	ELSE IF (YEAR IN (2012) AND DQTR IN (1,2,3)) THEN DRGVER = 29;
  ELSE IF (YEAR IN (2012) AND DQTR IN (4)) 	 THEN DRGVER = 30;
	ELSE IF (YEAR IN (2013) AND DQTR IN (1,2,3)) THEN DRGVER = 30;
	ELSE IF (YEAR IN (2013) AND DQTR IN (4))     THEN DRGVER = 31;
	ELSE IF (YEAR IN (2014) AND DQTR IN (1,2,3)) THEN DRGVER = 31;
	ELSE IF (YEAR IN (2014) AND DQTR IN (4))     THEN DRGVER = 32;
  ELSE IF  YEAR GT 2014 											 THEN DRGVER = 32;
 END;

 IF MDC NOTIN (01,02,03,04,05,06,07,08,09,10,
               11,12,13,14,15,16,17,18,19,20,
               21,22,23,24,25)
 THEN DO;
    IF DRGVER LE 24 THEN MDCNEW = PUT(DRG,MDCFMT.);
    ELSE IF DRGVER GE 25 THEN MDCNEW = PUT(DRG,MDCF2T.);
    IF MDCNEW IN (01,02,03,04,05,06,07,08,09,10,
                  11,12,13,14,15,16,17,18,19,20,
                  21,22,23,24,25)
    THEN MDC=MDCNEW;
    ELSE DO;
       IF DRGVER LE 24 AND DRG IN (470) THEN MDC = 0;
       ELSE IF DRGVER GE 25 AND DRG IN (999) THEN MDC = 0;
       ELSE PUT "INVALID MDC KEY: " KEY " MDC " MDC " DRG " DRG DRGVER;
    END;
 END;
 

 * -------------------------------------------------------------- ;
 * --- DELETE RECORDS WITH MISSING VALUES FOR AGE OR SEX OR DX1-- ;
 * --- DELETE NON ADULT RECORDS                         --------- ;
 * -------------------------------------------------------------- ;
 IF SEX LE 0 THEN DELETE;
 IF AGE LT 0 THEN DELETE;
 IF AGE LT 18 AND MDC NOTIN (14) THEN DELETE;
 IF COMPRESS(DX1) IN ('') THEN DELETE;
 IF DQTR LE .Z THEN DELETE;
 IF YEAR LE .Z THEN DELETE;

 * -------------------------------------------------------------- ;
 * --- CALCULATE MAXIMUM DX AND ECODES                  --------- ;
 * -------------------------------------------------------------- ;
 ARRAY ARRY1{&NDX.} DX1-DX&NDX.;

 MAXDX = 0; ECDDX = 0; 

 DO I = 1 TO &NDX.;
    IF ARRY1(I) NOTIN (' ') THEN DO;
       MAXDX + 1;
       IF SUBSTR(ARRY1(I),1,1) IN ('E') THEN ECDDX = 1; 
    END;
 END;

 * -------------------------------------------------------------- ;
 * --- COUNT THE NUMBER OF PR CODES                     --------- ;
 * -------------------------------------------------------------- ;
 ARRAY ARRY3{&NPR.} PR1-PR&NPR.;
 ARRAY ARRY6{&NPR.} PRDAY1-PRDAY&NPR.;

 MAXPR = 0; CNTPRDAY = 0;
 DO I = 1 TO &NPR.;
    IF ARRY3(I) NOTIN (' ') THEN MAXPR + 1;
    IF ARRY6(I) GE 0 THEN CNTPRDAY + 1;
 END;

 IF &PRDAY. EQ 0 OR CNTPRDAY = 0 THEN NOPRDAY = 1;
 ELSE NOPRDAY = 0;

 * -------------------------------------------------------------- ;
 * --- PALLIATIVE CARE   ---------------------------------------- ;
 * -------------------------------------------------------------- ;

 IF %MDX($PALLIAD.) OR DNR IN (1) THEN PALLIAFG = 1;
 ELSE PALLIAFG = 0;


 * -------------------------------------------------------------- ;
 * --- DEFINE FIPS STATE AND COUNTY CODES             ----------- ;
 * -------------------------------------------------------------- ;
 ATTRIB FIPSTCO LENGTH=$5
   LABEL='FIPS STATE COUNTY CODE';
 FIPSTCO = PUT(PSTCO,Z5.);

 ATTRIB FIPST LENGTH=$2
   LABEL='STATE FIPS CODE';
 FIPST = SUBSTR(FIPSTCO,1,2);


 * -------------------------------------------------------------- ;
 * --- DEFINE ICD-9-CM VERSION           ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB ICDVER LENGTH=3
   LABEL='ICD-9-CM VERSION';

 ICDVER = 0;
 IF (YEAR IN (1994) AND DQTR IN (4))          THEN ICDVER = 12;
 ELSE IF (YEAR IN (1995) AND DQTR IN (1,2,3)) THEN ICDVER = 12;
 ELSE IF (YEAR IN (1995) AND DQTR IN (4))     THEN ICDVER = 13;
 ELSE IF (YEAR IN (1996) AND DQTR IN (1,2,3)) THEN ICDVER = 13;
 ELSE IF (YEAR IN (1996) AND DQTR IN (4))     THEN ICDVER = 14;
 ELSE IF (YEAR IN (1997) AND DQTR IN (1,2,3)) THEN ICDVER = 14;
 ELSE IF (YEAR IN (1997) AND DQTR IN (4))     THEN ICDVER = 15;
 ELSE IF (YEAR IN (1998) AND DQTR IN (1,2,3)) THEN ICDVER = 15;
 ELSE IF (YEAR IN (1998) AND DQTR IN (4))     THEN ICDVER = 16;
 ELSE IF (YEAR IN (1999) AND DQTR IN (1,2,3)) THEN ICDVER = 16;
 ELSE IF (YEAR IN (1999) AND DQTR IN (4))     THEN ICDVER = 17;
 ELSE IF (YEAR IN (2000) AND DQTR IN (1,2,3)) THEN ICDVER = 17;
 ELSE IF (YEAR IN (2000) AND DQTR IN (4))     THEN ICDVER = 18;
 ELSE IF (YEAR IN (2001) AND DQTR IN (1,2,3)) THEN ICDVER = 18;
 ELSE IF (YEAR IN (2001) AND DQTR IN (4))     THEN ICDVER = 19;
 ELSE IF (YEAR IN (2002) AND DQTR IN (1,2,3)) THEN ICDVER = 19;
 ELSE IF (YEAR IN (2002) AND DQTR IN (4))     THEN ICDVER = 20;
 ELSE IF (YEAR IN (2003) AND DQTR IN (1,2,3)) THEN ICDVER = 20;
 ELSE IF (YEAR IN (2003) AND DQTR IN (4))     THEN ICDVER = 21;
 ELSE IF (YEAR IN (2004) AND DQTR IN (1,2,3)) THEN ICDVER = 21;
 ELSE IF (YEAR IN (2004) AND DQTR IN (4))     THEN ICDVER = 22;
 ELSE IF (YEAR IN (2005) AND DQTR IN (1,2,3)) THEN ICDVER = 22;
 ELSE IF (YEAR IN (2005) AND DQTR IN (4))     THEN ICDVER = 23;
 ELSE IF (YEAR IN (2006) AND DQTR IN (1,2,3)) THEN ICDVER = 23;
 ELSE IF (YEAR IN (2006) AND DQTR IN (4))     THEN ICDVER = 24;
 ELSE IF (YEAR IN (2007) AND DQTR IN (1,2,3)) THEN ICDVER = 24;
 ELSE IF (YEAR IN (2007) AND DQTR IN (4))     THEN ICDVER = 25;
 ELSE IF (YEAR IN (2008) AND DQTR IN (1,2,3)) THEN ICDVER = 25;
 ELSE IF (YEAR IN (2008) AND DQTR IN (4))     THEN ICDVER = 26;
 ELSE IF (YEAR IN (2009) AND DQTR IN (1,2,3)) THEN ICDVER = 26;
 ELSE IF (YEAR IN (2009) AND DQTR IN (4)) 	  THEN ICDVER = 27;
 ELSE IF (YEAR IN (2010) AND DQTR IN (1,2,3)) THEN ICDVER = 27;
 ELSE IF (YEAR IN (2010) AND DQTR IN (4)) 	  THEN ICDVER = 28;
 ELSE IF (YEAR IN (2011) AND DQTR IN (1,2,3)) THEN ICDVER = 28;
 ELSE IF (YEAR IN (2011) AND DQTR IN (4)) 	  THEN ICDVER = 29;
 ELSE IF (YEAR IN (2012) AND DQTR IN (1,2,3)) THEN ICDVER = 29;
 ELSE IF (YEAR IN (2012) AND DQTR IN (4)) 	  THEN ICDVER = 30;
 ELSE IF (YEAR IN (2013) AND DQTR IN (1,2,3)) THEN ICDVER = 30;
 ELSE IF (YEAR IN (2013) AND DQTR IN (4))     THEN ICDVER = 31;
 ELSE IF (YEAR IN (2014) AND DQTR IN (1,2,3)) THEN ICDVER = 31;
 ELSE IF (YEAR IN (2014) AND DQTR IN (4))     THEN ICDVER = 32;
 ELSE IF  YEAR GT  2014	                      THEN ICDVER = 32;



 * -------------------------------------------------------------- ;
 * --- DEFINE MEDICAL DRGS               ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB MEDICDR LENGTH=3
   LABEL='MEDICAL DRGS';

 IF (DRGVER LE 24 AND %MDR($MEDICDR.)) OR
    (DRGVER GE 25 AND %MDR($MEDIC2R.)) 
 THEN MEDICDR = 1;
 ELSE MEDICDR = 0;


 * -------------------------------------------------------------- ;
 * --- DEFINE SURGICAL DRGS              ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB SURGIDR LENGTH=3
   LABEL='SURGICAL DRGS';

 IF (DRGVER LE 24 AND %MDR($SURGIDR.)) OR
    (DRGVER GE 25 AND %MDR($SURGI2R.)) 
 THEN SURGIDR = 1;
 ELSE SURGIDR = 0;


 * -------------------------------------------------------------- ;
 * --- DEFINE MODIFIED DRGS              ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB MDRG LENGTH=3
   LABEL='MODIFIED DRG';

 IF DRGVER LE 24 THEN MDRG = PUT(PUT(DRG,Z3.),$DRGFMT.);
 IF DRGVER GE 25 THEN MDRG = PUT(PUT(DRG,Z3.),$DRGF2T.);


 * -------------------------------------------------------------- ;
 * --- DEFINE LOW MORT DRGS              ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB LOWMODR LENGTH=3
   LABEL='LOW MORTALITY DRGS';

 LOWMODR = PUT(MDRG,LOWMODR.);


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: PAYER CATEGORY ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB PAYCAT LENGTH=3
   LABEL='PATIENT PRIMARY PAYER';

 SELECT (PAY1);
   WHEN (1)  PAYCAT = 1;
   WHEN (2)  PAYCAT = 2;
   WHEN (3)  PAYCAT = 3;
   WHEN (4)  PAYCAT = 4;
   WHEN (5)  PAYCAT = 5;
   OTHERWISE PAYCAT = 6;
 END; * SELECT PAY1 ;

 ATTRIB DUALCAT LENGTH=3
   LABEL='PATIENT DUAL ELIGIBLE';

 IF (PAY1 IN (1) AND PAY2 IN (2)) OR
    (PAY1 IN (2) AND PAY2 IN (1)) 
 THEN DUALCAT = 1; ELSE DUALCAT = 0;
    

 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: RACE CATEGORY ------------------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB RACECAT LENGTH=3
   LABEL='PATIENT RACE/ETHNICITY';

 SELECT (RACE);
   WHEN (1)  RACECAT = 1;
   WHEN (2)  RACECAT = 2;
   WHEN (3)  RACECAT = 3;
   WHEN (4)  RACECAT = 4;
   WHEN (5)  RACECAT = 5;
   OTHERWISE RACECAT = 6;
 END; * SELECT RACE ;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: AGE CATEGORY  ------------------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB AGECAT LENGTH=3
   LABEL='PATIENT AGE';

 SELECT;
   WHEN (      AGE < 18)  AGECAT = 0;
   WHEN (18 <= AGE < 40)  AGECAT = 1;
   WHEN (40 <= AGE < 65)  AGECAT = 2;
   WHEN (65 <= AGE < 75)  AGECAT = 3;
   WHEN (75 <= AGE     )  AGECAT = 4;
   OTHERWISE AGECAT = 0;
  
 END; * SELECT AGE ;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: SEX CATEGORY  ------------------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB SEXCAT LENGTH=3
   LABEL='PATIENT GENDER';

 SELECT (SEX);
   WHEN (1)  SEXCAT = 1;
   WHEN (2)  SEXCAT = 2;
   OTHERWISE SEXCAT = 0;
 END; * SELECT SEX ;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: POPULATION CATEGORY ------------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB POPCAT LENGTH=3
   LABEL='PATIENT AGE';

 POPCAT=PUT(AGE,AGEFMT.);


 * -------------------------------------------------------------- ;
 * --- COUNT OR PROCEDURES AND IDENTIFY FIRST OR PROCEDURE ------ ;
 * -------------------------------------------------------------- ;
 ATTRIB ORCNT LENGTH=8
   LABEL='OR PROCEDURE COUNT';

 ATTRIB ORDAY LENGTH=8
   LABEL='OR PROCEDURE DAY';

%ORCNT;


 * -------------------------------------------------------------- ;
 * --- DEFINE PROVIDER LEVEL INDICATORS ------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO LBL;

 ATTRIB
 TPPS02 LENGTH=8
   LABEL='PSI 02 Death Rate in Low-Mortality Diagnosis Related Groups (DRGs) (Numerator)'
 TPPS03 LENGTH=8
   LABEL='PSI 03 Pressure Ulcer Rate (Numerator)'
 TPPS04  LENGTH=8
   LABEL='PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications (Numerator)'
 TPPS04A LENGTH=8
   LABEL='PSI 04A Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum A (Numerator)'
 TPPS04B LENGTH=8
   LABEL='PSI 04B Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum B (Numerator)'
 TPPS04C LENGTH=8
   LABEL='PSI 04C Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum C (Numerator)'
 TPPS04D LENGTH=8
   LABEL='PSI 04E Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum D (Numerator)'
 TPPS04E LENGTH=8
   LABEL='PSI 04E Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum E (Numerator)'
 TPPS05 LENGTH=8
   LABEL='PSI 05 Retained Surgical Item or Unretrieved Device Fragment Count (Numerator)'
 TPPS06 LENGTH=8
   LABEL='PSI 06 Iatrogenic Pneumothorax Rate (Numerator)'
 TPPS07 LENGTH=8
   LABEL='PSI 07 Central Venous Catheter-Related Blood Stream Infection Rate (Numerator)'
 TPPS08 LENGTH=8
   LABEL='PSI 08 Postoperative Hip Fracture Rate (Numerator)'
 TPPS09 LENGTH=8
   LABEL='PSI 09 Perioperative Hemorrhage or Hematoma Rate (Numerator)'
 TPPS10 LENGTH=8
   LABEL='PSI 10 Postoperative Physiologic and Metabolic Derangement Rate (Numerator)'
 TPPS11 LENGTH=8
   LABEL='PSI 11 Postoperative Respiratory Failure Rate (Numerator)'
 TPPS12 LENGTH=8
   LABEL='PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate (Numerator)'
 TPPS13 LENGTH=8
   LABEL='PSI 13 Postoperative Sepsis Rate (Numerator)'
 TPPS14 LENGTH=8
   LABEL='PSI 14 Postoperative Wound Dehiscence Rate (Numerator)'
 TPPS15 LENGTH=8
   LABEL='PSI 15 Accidental Puncture or Laceration Rate (Numerator)'
 TPPS16 LENGTH=8
   LABEL='PSI 16 Transfusion Reaction Count (Numerator)'
 TPPS18 LENGTH=8
   LABEL='PSI 18 Obstetric Trauma Rate - Vaginal Delivery With Instrument (Numerator)'
 TPPS19 LENGTH=8
   LABEL='PSI 19 Obstetric Trauma Rate - Vaginal Delivery Without Instrument (Numerator)'
;

 ATTRIB
 QPPS02 LENGTH=3
   LABEL = 'PSI 02 Death Rate in Low-Mortality Diagnosis Related Groups (DRGs) (PAL) (1=exclude case based on PALLIATIVE CARE)'
 QPPS03 LENGTH=3
   LABEL = 'PSI 03 Pressure Ulcer Rate (POA) (1=exclude case based on POA)'
 QPPS04 LENGTH=3
   LABEL = 'PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications (PAL) (1=exclude case based on PALLIATIVE CARE)'
 QPPS04A LENGTH=3
   LABEL = 'PSI 04A Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum A (PAL) (1=exclude case based on PALLIATIVE CARE)'
 QPPS04B LENGTH=3
   LABEL = 'PSI 04B Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum B (PAL) (1=exclude case based on PALLIATIVE CARE)'
 QPPS04C LENGTH=3
   LABEL = 'PSI 04C Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum C (PAL) (1=exclude case based on PALLIATIVE CARE)'
 QPPS04D LENGTH=3
   LABEL = 'PSI 04D Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum D (PAL) (1=exclude case based on PALLIATIVE CARE)'
 QPPS04E LENGTH=3
   LABEL = 'PSI 04E Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum E (PAL) (1=exclude case based on PALLIATIVE CARE)'
 QPPS05 LENGTH=3
   LABEL = 'PSI 05 Retained Surgical Item or Unretrieved Device Fragment Count (POA) (1=exclude case based on POA)'
 QPPS06 LENGTH=3
   LABEL = 'PSI 06 Iatrogenic Pneumothorax Rate (POA) (1=exclude case based on POA)'
 QPPS07 LENGTH=3
   LABEL = 'PSI 07 Central Venous Catheter-Related Blood Stream Infection Rate (POA) (1=exclude case based on POA)'
 QPPS08 LENGTH=3
   LABEL = 'PSI 08 Postoperative Hip Fracture Rate (POA) (1=exclude case based on POA)'
 QPPS09 LENGTH=3
   LABEL = 'PSI 09 Perioperative Hemorrhage or Hematoma Rate (POA) (1=exclude case based on POA)'
 QPPS10 LENGTH=3
   LABEL = 'PSI 10 Postoperative Physiologic and Metabolic Derangement Rate Rate (POA) (1=exclude case based on POA)'
 QPPS11 LENGTH=3
   LABEL = 'PSI 11 Postoperative Respiratory Failure Rate (POA) (1=exclude based on POA)'
 QPPS12 LENGTH=3
   LABEL = 'PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate (POA) (1=exclude based on POA)'
 QPPS13 LENGTH=3
   LABEL = 'PSI 13 Postoperative Sepsis Rate (POA) (1=exclude based on POA)'
 QPPS14 LENGTH=3
   LABEL = 'PSI 14 Postoperative Wound Dehiscence Rate (POA) (1=exclude based on POA)'
 QPPS15 LENGTH=3
   LABEL = 'PSI 15 Accidental Puncture and Laceration Rate (POA) (1=exclude based on POA)'
 QPPS16 LENGTH=3
   LABEL = 'PSI 16  Transfusion Reaction Count (POA) (1=exclude based on POA)'
;
 ATTRIB 
 PPPS02 LENGTH=3
   LABEL = 'PSI 02 Death Rate in Low-Mortality Diagnosis Related Groups (DRGs) (Pop)'
 PPPS03 LENGTH=3
   LABEL = 'PSI 03 Pressure Ulcer Rate (Pop)'
 PPPS04 LENGTH=3
   LABEL = 'PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications (Pop)'
 PPPS04A LENGTH=3
   LABEL = 'PSI 04A Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum A (Pop)'
 PPPS04B LENGTH=3
   LABEL = 'PSI 04B Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum B (Pop)'
 PPPS04C LENGTH=3
   LABEL = 'PSI 04C Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum C (Pop)'
 PPPS04D LENGTH=3
   LABEL = 'PSI 04D Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum D (Pop)'
 PPPS04E LENGTH=3
   LABEL = 'PSI 04E Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum E (Pop)'
 PPPS05 LENGTH=3
   LABEL = 'PSI 05 Retained Surgical Item or Unretrieved Device Fragment Count (Pop)'
 PPPS06 LENGTH=3
   LABEL = 'PSI 06 Iatrogenic Pneumothorax Rate (Pop)'
 PPPS07 LENGTH=3
   LABEL = 'PSI 07 Central Venous Catheter-Related Blood Stream Infection Rate (Pop)'
 PPPS08 LENGTH=3
   LABEL = 'PSI 08 Postoperative Hip Fracture Rate (Pop)'
 PPPS09 LENGTH=3
   LABEL = 'PSI 09 Perioperative Hemorrhage or Hematoma Rate (Pop)'
 PPPS10 LENGTH=3
   LABEL = 'PSI 10 Postoperative Physiologic and Metabolic Derangement Rate (Pop)'
 PPPS11 LENGTH=3
   LABEL = 'PSI 11 Postoperative Respiratory Failure Rate (Pop)'
 PPPS12 LENGTH=3
   LABEL = 'PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate (Pop)'
 PPPS13 LENGTH=3
   LABEL = 'PSI 13 Postoperative Sepsis Rate (Pop)'
 PPPS14 LENGTH=3
   LABEL = 'PSI 14 Postoperative Wound Dehiscence Rate (Pop)'
 PPPS15 LENGTH=3
   LABEL = 'PSI 15 Accidental Puncture or Laceration Rate (Pop)'
 PPPS16 LENGTH=3
   LABEL = 'PSI 16 Transfusion Reaction Count (Pop)'
 PPPS18 LENGTH=3
   LABEL = 'PSI 18 Obstetric Trauma Rate - Vaginal Delivery With Instrument (Pop)'
 PPPS19 LENGTH=3
   LABEL = 'PSI 19 Obstetric Trauma Rate - Vaginal Delivery Without Instrument (Pop)'
;
 * -------------------------------------------------------------- ;
 * --- DEFINE AREA LEVEL INDICATORS ----------------------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB
 TAPS21 LENGTH=8
   LABEL='PSI 21 Retained Surgical Item or Unretrieved Device Fragment Rate (Area Numerator)'
 TAPS22 LENGTH=8
   LABEL='PSI 22 Iatrogenic Pneumothorax Rate (Area Numerator)'
 TAPS23 LENGTH=8
   LABEL='PSI 23 Central Venous Catheter-Related Blood Stream Infection Rate (Area Numerator)'
 TAPS24 LENGTH=8
   LABEL='PSI 24 Postoperative Wound Dehiscence Rate (Area Numerator)'
 TAPS25 LENGTH=8
   LABEL='PSI 25 Accidental Puncture or Laceration Rate (Area Numerator)'
 TAPS26 LENGTH=8
   LABEL='PSI 26 Transfusion Reaction Rate (Area Numerator)'
 TAPS27 LENGTH=8
   LABEL='PSI 27 Perioperative Hemorrhage or Hematoma Rate (Area Numerator)'
;

 * -------------------------------------------------------------- ;
 * --- RE-LABEL DAY DEPENDENT INDICATORS ------------------------ ;
 * -------------------------------------------------------------- ;
 %IF &PRDAY. = 0 %THEN %DO;
 LABEL
   TPPS03 = 'PSI 03 Pressure Ulcer Rate-NO PRDAY (Numerator)'
   TPPS08 = 'PSI 08 Postoperative Hip Fracture Rate-NO PRDAY (Numerator)'
   TPPS09 = 'PSI 09 Perioperative Hemorrhage or Hematoma Rate-NO PRDAY (Numerator)'
   TPPS10 = 'PSI 10 Postoperative Physiologic and Metabolic Derangement Rate-NO PRDAY (Numerator)'
   TPPS11 = 'PSI 11 Postoperative Respiratory Failure Rate-NO PRDAY (Numerator)'
   TPPS12 = 'PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate-NO PRDAY (Numerator)'
   TPPS14 = 'PSI 14 Postoperative Wound Dehiscence Rate-NO PRDAY (Numerator)'
 ;
 %END;

 %MEND;

 %LBL;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AHRQ COMORBIDITY     --------------------------- ;
 * -------------------------------------------------------------- ;

 LENGTH
    CHF VALVE PULMCIRC PERIVASC HTN_C
    PARA NEURO CHRNLUNG DM DMCX
    HYPOTHY RENLFAIL LIVER ULCER AIDS
    LYMPH METS TUMOR ARTH OBESE
    WGHTLOSS BLDLOSS ANEMDEF ALCOHOL DRUG
    PSYCH DEPRESS 3;
 
 LENGTH
    XHF XALVE XULMCIRC XERIVASC XTN_C
    XARA XEURO XHRNLUNG XM XMCX
    XYPOTHY XENLFAIL XIVER XLCER XIDS
    XYMPH XETS XUMOR XRTH XBESE
    XGHTLOSS XLDLOSS XNEMDEF XLCOHOL XRUG
    XSYCH XEPRESS 3; 

 ARRAY ARRY4{27}
    CHF VALVE PULMCIRC PERIVASC HTN_C
    PARA NEURO CHRNLUNG DM DMCX
    HYPOTHY RENLFAIL LIVER ULCER AIDS
    LYMPH METS TUMOR ARTH OBESE
    WGHTLOSS BLDLOSS ANEMDEF ALCOHOL DRUG
    PSYCH DEPRESS;
 
 ARRAY ARRY5{27}
    XHF XALVE XULMCIRC XERIVASC XTN_C
    XARA XEURO XHRNLUNG XM XMCX
    XYPOTHY XENLFAIL XIVER XLCER XIDS
    XYMPH XETS XUMOR XRTH XBESE
    XGHTLOSS XLDLOSS XNEMDEF XLCOHOL XRUG
    XSYCH XEPRESS; 

   /*****************************************/
   /*  Declare variables as array elements  */
   /*****************************************/

   ARRAY DX (&NDX.) $  DX1 - DX&NDX.;
   ARRAY DXPOA (&NDX.) $  DXPOA1 - DXPOA&NDX.;

   ARRAY COM1 (30)  CHF      VALVE    PULMCIRC PERIVASC
                    HTN      HTNCX    PARA     NEURO    CHRNLUNG
                    DM       DMCX     HYPOTHY  RENLFAIL LIVER
                    ULCER    AIDS     LYMPH    METS     TUMOR
                    ARTH     COAG     OBESE    WGHTLOSS LYTES
                    BLDLOSS  ANEMDEF  ALCOHOL  DRUG     PSYCH
                    DEPRESS ;

   ARRAY COM2 (30) $ 8 A1-A30
                    ("CHF"     "VALVE"   "PULMCIRC" "PERIVASC" 
                     "HTN"     "HTNCX"   "PARA"     "NEURO"     "CHRNLUNG" 
                     "DM"      "DMCX"    "HYPOTHY"  "RENLFAIL"  "LIVER" 
                     "ULCER"   "AIDS"    "LYMPH"    "METS"      "TUMOR" 
                     "ARTH"    "COAG"    "OBESE"    "WGHTLOSS"  "LYTES" 
                     "BLDLOSS" "ANEMDEF" "ALCOHOL"  "DRUG"      "PSYCH" 
                     "DEPRESS") ; 

 DO J = 1 TO 27;
    ARRY4(J) = 0;
    ARRY5(J) = .;
 END;

 IF (DRGVER LE 24) THEN DO;
    IF NOPOA = 0 THEN DO;
       POAFG = 1;
       %INCLUDE CMBANALY;
       DO I = 1 TO 27;
          ARRY5(I) = ARRY4(I);
       END;
    END;
    POAFG = 0;
    %INCLUDE CMBANALY;
 END;
 ELSE DO;
    IF NOPOA = 0 THEN DO;
       POAFG = 1;
       %INCLUDE CMBANA2Y;
       DO I = 1 TO 27;
          ARRY5(I) = ARRY4(I);
       END;
    END;
    POAFG = 0;
    %INCLUDE CMBANA2Y;
 END;

     LABEL XHF        = 'Congestive heart failure'
           XALVE      = 'Valvular disease'
           XULMCIRC   = 'Pulmonary circulation disease'
           XERIVASC   = 'Peripheral vascular disease'
           XARA       = 'Paralysis'
           XEURO      = 'Other neurological disorders'
           XHRNLUNG   = 'Chronic pulmonary disease'
           XM         = 'Diabetes w/o chronic complications'
           XMCX       = 'Diabetes w/ chronic complications'
           XYPOTHY    = 'Hypothyroidism'
           XENLFAIL   = 'Renal failure'
           XIVER      = 'Liver disease'
           XLCER      = 'Peptic ulcer Disease x bleeding'
           XIDS       = 'Acquired immune deficiency syndrome'
           XYMPH      = 'Lymphoma'
           XETS       = 'Metastatic cancer'
           XUMOR      = 'Solid tumor w/out metastasis'
           XRTH       = 'Rheumatoid arthritis/collagen vas'
           XBESE      = 'Obesity'
           XGHTLOSS   = 'Weight loss'
           XLDLOSS    = 'Chronic blood loss anemia'
           XNEMDEF    = 'Deficiency Anemias'
           XLCOHOL    = 'Alcohol abuse'
           XRUG       = 'Drug abuse'
           XSYCH      = 'Psychoses'
           XEPRESS    = 'Depression'
        ;
 /*        XOAG       = 'Coagulopthy'
           XYTES      = 'Fluid and electrolyte disorders'
 */
 * -------------------------------------------------------------- ;
 * --- CONSTRUCT PROVIDER LEVEL INDICATORS ---------------------- ;
 * -------------------------------------------------------------- ;

   * --- DEATH IN LOW MORTALITY DRGS                          --- ;

   IF LOWMODR THEN DO;

      TPPS02 = 0; QPPS02 = 0;
       
      IF DISP IN (20) THEN TPPS02 = 1;

      IF PALLIAFG THEN QPPS02 = 1;

      *** Exclude Trauma, Immunocompomised state, and cancer;

      IF %MDX($TRAUMID.) OR %MDX($IMMUNID.) OR 
         %MPR($IMMUNIP.) OR %MDX($CANCEID.) 
      THEN TPPS02 = .;

      *** Exclude missing discharge disposition or transfer acute care facility ***; 

      IF DISP LE .Z OR DISP=2 THEN TPPS02 = .;

      *** Set PAL flag to missing;

      IF TPPS02 = . THEN QPPS02 = .;
 
   END;

   * --- PRESSURE ULCER                                      --- ;

 %MACRO PS3;

 IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;

      IF MPRDAY <= ORDAY THEN TPPS03 = .;

 END;
 ELSE DO;

      IF %MPR1($DEBRIDP.) THEN TPPS03 = .;

 END;

 %MEND;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TPPS03 = 0; QPPS03 = 0;
     
IF ICDVER LE 25 AND %MDX2($DECUBID.) THEN TPPS03 = 1;
IF ICDVER GE 26 AND %MDX2($DECUBID.) AND %MDX2($DECUBVD.) THEN TPPS03 = 1;
IF ICDVER LE 25 AND %MDX2Q1($DECUBID.) THEN QPPS03 = 0;
IF ICDVER GE 26 AND %MDX2Q1($DECUBID.) AND %MDX2Q1($DECUBVD.) THEN QPPS03 = 0;

*** Exclude principal diagnosis; 

IF %MDX1($DECUBID.) THEN TPPS03 = .;
IF ICDVER LE 25 AND %MDX2Q2($DECUBID.) THEN QPPS03 = 1;
IF ICDVER GE 26 AND %MDX2Q2($DECUBID.) AND %MDX2Q2($DECUBVD.) THEN QPPS03 = 1;


      IF SURGIDR AND ORCNT > 0 THEN DO;
 
         *** Exclude if debridement or pedicle graft is the only OR procedure;
         %MPRCNT($DEBRIDP.);
         IF ORCNT = MPRCNT THEN TPPS03 = .;

         *** Exclude if debridement or pedicle graft occurs before or 
             on the same day as the first OR procedure;
         %ORDAY($DEBRIDP.);
         %MPRDAY($DEBRIDP.);
         %PS3;

      END;

      *** Exclude Hemiplegia, Paraplagia, Quadriplagia;

      IF %MDX($HEMIPID.) THEN TPPS03 = .;

      *** Exclude Spina Bifida and Anoxic Brain Damage;

      IF %MDX($SPINABD.) THEN TPPS03 = .;

      *** Exclude MDC 9 and 14;

      IF MDC IN (9, 14) THEN TPPS03 = .;

      *** Exclude LOS < 5, Admitted from Acute Care Facility or LTC;

      IF LOS < 5 OR 
         ASOURCE IN (2,3) OR
         POINTOFORIGINUB04 IN ('4','5','6') THEN TPPS03 = .;

      *** Set POA flag to missing;

      IF TPPS03 = . OR NOPOA THEN QPPS03 = .;
      IF TPPS03 = 0 AND QPPS03 = 1 THEN QPPS03 = 0;

   END;

   * --- DEATH AMONG SURGICAL                                    --- ;

   IF (SURGIDR AND ORCNT > 0)   AND
      (0 <= PRDAY1 <=2 OR ATYPE IN (3)) AND
      (17 < AGE < 90 OR MDC IN (14))    THEN DO;

   IF (ICDVER LE 26 AND (%MDX2($FTR2DX.) AND 
       NOT (%MDX1($FTR2DX.) OR %MDX1($OBEMBOL.))))
      OR
      (ICDVER GE 27 AND (%MDX2($FTR2DXB.) AND 
       NOT (%MDX1($FTR2DXB.) OR %MDX1($OBEMBOL.))))
      OR
      (%MDX2($FTR3DX.) AND 
       NOT (%MDX1($FTR3DX.) OR %MDX1($FTR3EXA.) OR %MDX($FTR3EXB.) OR %MDX($IMMUNID.) OR 
            %MPR($IMMUNIP.) OR MDC IN (4) OR %MPR($LUNGCIP.)))
      OR
      (%MDX2($FTR4DX.) AND 
       NOT (%MDX1($FTR4DX.) OR (%MDX1($INFECID.) OR %MDX($IMMUNID.) OR %MPR($IMMUNIP.)) OR LOS < 4))
      OR
      ((%MDX2($FTR5DX.) OR %MPR($FTR5PR.)) AND 
       NOT (%MDX1($FTR5DX.) OR %MDX1($FTR5EX.) OR %MDX1($HEMORID.) OR %MDX1($TRAUMID.) OR 
            %MDX1($GASTRID.) OR %MPR($LUNGCIP.)OR MDC IN (4,5) ))
      OR
      (%MDX2($FTR6DX.) AND 
       NOT (%MDX1($FTR6DX.) OR %MDX1($FTR6EX.) OR %MDX1($TRAUMID.) OR
            %MDX1($ALCHLSM.) OR MDC IN (6,7)))
   THEN DO;


      TPPS04 = 0;  QPPS04 = 0;

      IF DISP IN (20) THEN TPPS04 = 1;

      IF PALLIAFG THEN QPPS04 = 1;

      *** Exclude Transfers to an acute care facility;

      IF DISP LE .Z OR DISP=2 THEN TPPS04 = .;

      *** Set PAL flag to missing;

      IF TPPS04 = . OR NOPOA THEN QPPS04 = .;
 
   END;

   END;


   * --- DEATH AMONG SURGICAL (STRATIFICATION)                                  --- ;

   IF (SURGIDR AND ORCNT > 0)            AND
      (0 <= PRDAY1 <= 2 OR ATYPE IN (3)) AND
      (17 < AGE < 90 OR MDC IN (14))     THEN DO;

  
	  /** STRATUM - A: DVT/PE ***/
	    IF (ICDVER LE 26 AND (%MDX2($FTR2DX.) AND 
                   NOT (%MDX1($FTR2DX.) OR %MDX1($OBEMBOL.))))
               OR
           (ICDVER GE 27 AND %MDX2($FTR2DXB.)) THEN DO;

	      TPPS04A = 0; 
	      IF DISP IN (20) THEN TPPS04A = 1;

	   *  IF %MDX2Q1($FTR2DXB.) THEN QPPS04A = 0;

	      IF %MDX1($FTR2DXB.) THEN TPPS04A = .;
	      IF %MDX1($OBEMBOL.) THEN TPPS04A = .;

		 *** Exclude Transfers to an acute care facility;

	      IF DISP LE .Z OR DISP=2 THEN TPPS04A = .;

		  IF PALLIAFG THEN QPPS04A = 1;
	      IF TPPS04A = . OR NOPOA THEN QPPS04A = .;

	    END;

	/** STRATUM - B: PNEUMONIA ***/
	   IF %MDX2($FTR3DX.) THEN DO;

	      TPPS04B = 0; 
	      IF DISP IN (20) THEN TPPS04B = 1;

	      IF %MDX1($FTR3DX.)   THEN TPPS04B = .;
	      IF %MDX1($FTR3EXA.)  THEN TPPS04B = .;
	      IF %MDX($FTR3EXB.)   THEN TPPS04B = .;
	      IF %MDX($IMMUNID.)   THEN TPPS04B = .;
	      IF %MPR($IMMUNIP.)   THEN TPPS04B = .;
	      IF MDC IN (4)        THEN TPPS04B = .;
	      IF %MPR($LUNGCIP.)   THEN TPPS04B = .;

		*** Exclude Transfers to an acute care facility;

	      IF DISP LE .Z OR DISP=2 THEN TPPS04B = .;

		  IF PALLIAFG THEN QPPS04B = 1;
	      IF TPPS04B = . OR NOPOA THEN QPPS04B = .;

	   END;


	 /** STRATUM - C: SEPSIS ***/
	   IF %MDX2($FTR4DX.) THEN DO;

	      TPPS04C = 0; 
	      IF DISP IN (20) THEN TPPS04C = 1;

	      IF %MDX1($FTR4DX.) THEN TPPS04C = .;
		  IF %MDX1($INFECID.) THEN TPPS04C = .;
	      IF %MDX($IMMUNID.)  THEN TPPS04C = .;
	      IF %MPR($IMMUNIP.)  THEN TPPS04C = .;
	      IF LOS LT 4 THEN TPPS04C=.;

	 	 *** Exclude Transfers to an acute care facility;

	      IF DISP LE .Z OR DISP=2 THEN TPPS04C = .;

	      IF PALLIAFG THEN QPPS04C = 1;
	      IF TPPS04C = . OR NOPOA THEN QPPS04C = .;

	   END;


	   /** STRATUM - D: SHOCK/CARDIAC ARREST***/

	   IF %MDX2($FTR5DX.) OR %MPR($FTR5PR.) THEN DO;

	      TPPS04D = 0;
	      IF DISP IN (20) THEN TPPS04D = 1;

	      IF %MDX1($FTR5DX.)  THEN TPPS04D = .;
		  IF %MDX1($TRAUMID.) THEN TPPS04D = .;
		  IF %MDX1($HEMORID.) THEN TPPS04D = .;
		  IF %MDX1($GASTRID.) THEN TPPS04D = .;
	      IF %MDX1($FTR5EX.)  THEN TPPS04D = .;
	      IF %MPR($LUNGCIP.)  THEN TPPS04D = .;	       
	      IF MDC IN (4,5)     THEN TPPS04D = .;
	      
	   		 *** Exclude Transfers to an acute care facility;

	      IF DISP LE .Z OR DISP=2 THEN TPPS04D = .;

		 IF PALLIAFG THEN QPPS04D = 1;
	     IF TPPS04D = . OR NOPOA THEN QPPS04D = .;
		 
	   END;


	 /** STRATUM - E: GI HEMORRHAGE/ACUTE ULCER ***/

	   IF %MDX2($FTR6DX.) THEN DO;

	      TPPS04E = 0; 
	      IF DISP IN (20) THEN TPPS04E = 1;

	      IF %MDX1($FTR6DX.)  THEN TPPS04E = .;
	      IF %MDX1($FTR6EX.)  THEN TPPS04E = .;
	      IF %MDX1($TRAUMID.) THEN TPPS04E = .;
	      IF %MDX1($ALCHLSM.) THEN TPPS04E = .;
	      IF MDC IN (6,7)     THEN TPPS04E = .;

		*** Exclude Transfers to an acute care facility;

	      IF DISP LE .Z OR DISP=2 THEN TPPS04E = .;

		  IF PALLIAFG THEN QPPS04E = 1;
	      IF TPPS04E = . OR NOPOA THEN QPPS04E = .;

	   END;

 *-------------------------------------------------------------------*;
 *---  V4.6: MAKE STRATA MUTUALLY EXCLUSIVE AND EXHAUSTIVE        ---*;  
 *-------------------------------------------------------------------*;
	   IF TPPS04D NE . THEN DO;
			           TPPS04C = .;
			           TPPS04B = .;
			           TPPS04A = .;
			           TPPS04E = .;
	   END;

	   ELSE IF TPPS04C NE . THEN DO;
			           TPPS04D = .;
			           TPPS04B = .;
			           TPPS04A = .;
			           TPPS04E = .;
	   END;
       ELSE IF TPPS04B NE . THEN DO;
			           TPPS04D = .;
			           TPPS04C = .;
			           TPPS04A = .;
			           TPPS04E = .;
	   END;

	   ELSE IF TPPS04A NE . THEN DO;
			           TPPS04D = .;
			           TPPS04C = .;
			           TPPS04B = .;
			           TPPS04E = .;
	   END;

	   ELSE IF TPPS04E NE . THEN DO;
			           TPPS04D = .;
			           TPPS04C = .;
			           TPPS04B = .;
			           TPPS04A = .;
	   END;

 /* Write a message to the log if the strata are not exhaustive. */

	   IF (TPPS04 EQ .)  AND 
          ((TPPS04A NE .) OR 
           (TPPS04B NE .) OR 
           (TPPS04C NE .) OR 
           (TPPS04D NE .) OR 
           (TPPS04E NE .)) THEN DO;
		  PUT "ERROR IN STRATUM ASSIGNMENT FOR PSI 4";
		  PUT "Record is not in denominator of the parent measure but is in one or more strata";
		  PUT "KEY: " KEY 
              "TPPS04:"  TPPS04 
              "TPPS04A:" TPPS04A 
              "TPPS04B:" TPPS04B 
              "TPPS04C:" TPPS04C 
              "TPPS04D:" TPPS04D 
              "TPPS04E:" TPPS04E;
	   END;

/* Ensure that every record in the parent measure is in at least one stratum */

	   IF  (TPPS04 NE .)   AND 
           ((TPPS04A EQ .) AND 
            (TPPS04B EQ .) AND 
            (TPPS04C EQ .) AND 
            (TPPS04D EQ .) AND 
            (TPPS04E EQ .)) THEN DO;
		  PUT "ERROR IN STRATUM ASSIGNMENT FOR PSI 4";
		  PUT "OBS is in denominator of the parent measure but not in any stratum";
		  PUT "KEY: " KEY 
              "TPPS04:"  TPPS04 
              "TPPS04A:" TPPS04A 
              "TPPS04B:" TPPS04B 
              "TPPS04C:" TPPS04C 
              "TPPS04D:" TPPS04D
              "TPPS04E:" TPPS04E;
	   END;

 	END;


   * --- RETAINED SURGICAL ITEM OR UNRETRIEVED DEVICE FRAGMENT               --- ;

   IF (MEDICDR OR SURGIDR) AND (NOT NOPOA) THEN DO;

      TPPS05 = .; QPPS05 = .;

      IF %MDX2($FOREIID.) THEN TPPS05 = 1;
      IF %MDX2Q1($FOREIID.) THEN QPPS05 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($FOREIID.) THEN TPPS05 = .;
      IF %MDX2Q2($FOREIID.) THEN QPPS05 = 1;

      *** Set POA flag to missing;

      IF TPPS05 = . OR NOPOA THEN QPPS05 = .;
      IF TPPS05 = 0 AND QPPS05 = 1 THEN QPPS05 = 0;

   END;

   * --- IATROGENIC PNEUMOTHORAX                              --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TPPS06 = 0; QPPS06 = 0;

      IF %MDX2($IATROID.) THEN TPPS06 = 1;
      IF %MDX2Q1($IATROID.) THEN QPPS06 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($IATROID.) THEN TPPS06 = .;
      IF %MDX2Q2($IATROID.) THEN QPPS06 = 1;

      *** Exclude Chest Trauma, Pleural effusion or MDC 14;

      IF %MDX($CTRAUMD.) OR %MDX($PLEURAD.) OR MDC IN (14)
      THEN TPPS06 = .;

      *** Exclude Thoracic surgery, Lung or pleural biopsy,
          Cardiac surgery or Diaphragmatic surgery repair;

      IF %MPR($THORAIP.) OR %MPR($LUNGBIP.) OR %MPR($CARDSIP.) OR 
         %MPR($DIAPHRP.)
      THEN TPPS06 = .;

       *** Set POA flag to missing;

      IF TPPS06 = . OR NOPOA THEN QPPS06 = .;
      IF TPPS06 = 0 AND QPPS06 = 1 THEN QPPS06 = 0;

  END;

   * --- CENTRAL LINE ASSOCIATED BSI                        --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TPPS07 = 0; QPPS07 = 0; 

	  IF ((ICDVER LE 24 AND (%MDX2($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX2($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX2($IDTMC3D.))))
      THEN TPPS07 = 1;

	  IF ((ICDVER LE 24 AND (%MDX2Q1($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX2Q1($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX2Q1($IDTMC3D.))))
      THEN QPPS07 = 0;

	   *** Exclude principal diagnosis; 

	  IF ((ICDVER LE 24 AND (%MDX1($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX1($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX1($IDTMC3D.))))
      THEN TPPS07= .;

	  IF ((ICDVER LE 24 AND (%MDX2Q2($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX2Q2($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX2Q2($IDTMC3D.))))
      THEN QPPS07= 1;

      *** Exclude Immunocompromised state and Cancer;

      IF %MDX($IMMUNID.) OR %MPR($IMMUNIP.) OR %MDX($CANCEID.)  
      THEN TPPS07 = .;
 
      *** Exclude LOS < 2; 
      IF LOS < 2 THEN TPPS07 = .;

       *** Set POA flag to missing;

      IF TPPS07 = . OR NOPOA THEN QPPS07 = .;
      IF TPPS07 = 0 AND QPPS07 = 1 THEN QPPS07 = 0;

   END;

   * --- POSTOPERATIVE HIP FRACTURE                           --- ;

 %MACRO PS8;

 IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;

      IF MPRDAY <= ORDAY THEN TPPS08 = .;

 END;
 ELSE DO;

      IF %MPR1($HIPFXIP.) THEN TPPS08 = .;

 END;

 %MEND;

   IF SURGIDR AND ORCNT > 0 THEN DO;

      TPPS08 = 0; QPPS08 = 0; 
  
      IF %MDX2($HIPFXID.) THEN TPPS08 = 1;
      IF %MDX2Q1($HIPFXID.) THEN QPPS08 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($HIPFXID.) THEN TPPS08 = .;
      IF %MDX2Q2($HIPFXID.) THEN QPPS08 = 1;

      *** Exclude if hip fracture repair or a related procedure is 
          the only OR procedure;
      %MPRCNT($HIPFXIP.);
      IF ORCNT = MPRCNT THEN TPPS08 = .;

      *** Exclude if hip fracture repair or a related procedure 
          occurs before or on the same day as the first OR procedure;
      %ORDAY($HIPFXIP.);
      %MPRDAY($HIPFXIP.);
      %PS8;

      *** Excludes Seizure, Syncope, Stroke, Coma, Cardiac arrest,
          Poisoning, Trauma, Delirium and other psychoses, Anoxic
          brain injury;

      IF %MDX1($SEIZUID.) OR %MDX1($SYNCOID.) OR %MDX1($STROKID.) OR
         %MDX1($COMAID.)  OR %MDX1($CARDIID.) OR %MDX1($POISOID.) OR
         %MDX1($TRAUMID.) OR %MDX1($DELIRID.) OR %MDX1($ANOXIID.)
      THEN TPPS08 = .;

      *** Excludes Metastatic cancer, Lymphoid malignancy, 
          Bone malignancy, Self-inflicted injury;
 
      IF %MDX($METACID.) OR %MDX($LYMPHID.) OR %MDX($BONEMID.) OR
         %MDX($SELFIID.)
      THEN TPPS08 = .;

      *** Exclude MDC 8 and 14;

      IF MDC IN (8, 14) THEN TPPS08 = .;

       *** Set POA flag to missing;

      IF TPPS08 = . OR NOPOA THEN QPPS08 = .;

      IF TPPS08 = 0 AND QPPS08 = 1 THEN QPPS08 = 0;

   END;

   * --- PERIOPERATIVE HEMORRHAGE OR HEMATOMA                 --- ;


 %MACRO PS9;

 IF (&PRDAY. = 1 AND ORDAY NE . AND MPRDAY NE .) THEN DO;

      IF %MDX2($POHMRI2D.) AND MPRDAY < ORDAY
      THEN TPPS09 = .;

 END;
 ELSE DO;

      IF %MDX2($POHMRI2D.) AND %MPR1($HEMIPB.)
      THEN TPPS09 = .;

 END;

 %MEND;

   IF SURGIDR AND ORCNT > 0 THEN DO;

      TPPS09 = 0; QPPS09 = 0; 

      IF %MDX2($POHMRI2D.) AND 
          (%MPR($HEMOTH2P.)) 
      THEN TPPS09 = 1;

      IF %MDX2Q1($POHMRI2D.) AND 
         (%MPR($HEMOTH2P.)) 
      THEN QPPS09 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($POHMRI2D.) THEN TPPS09 = .;

      IF %MDX2Q2($POHMRI2D.) THEN QPPS09 = 1;

      *** Exclude if control of post-operative hemorrhage or Misclleneous hemorrhage 
          hematoma-related procedure are the only OR procedures; 
      %MPRCNT($HEMIPB.);

      IF ORCNT = MPRCNT THEN TPPS09 = .;

      *** Exclude if control of post-operative hemorrhage or Miscellaneous Hemorrhage or
          hematoma-related procedure occurs before the first OR procedure;
      %ORDAY($HEMIPB.);
 	  %MPRDAY($HEMIPB.);
      %PS9;

      *** Exclude MDC 14;

      IF MDC IN (14) THEN TPPS09 = .;

	  *** Exclude Coagulation Disorders;

      IF %MDX($COAGDID.) THEN TPPS09 = . ;

       *** Set POA flag to missing;

      IF TPPS09 = . OR NOPOA THEN QPPS09 = .;

      IF TPPS09 = 0 AND QPPS09 = 1 THEN QPPS09 = 0;

   END;


   * --- POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENTS --- ;

 %MACRO PS10;

 IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;

      IF %MDX2($PHYSIDB.) AND MPRDAY <= ORDAY THEN TPPS10 = .;

 END;
 ELSE DO;

      IF %MDX2($PHYSIDB.) AND %MPR1($DIALYIP.) THEN TPPS10 = .;

 END;

 %MEND;

   IF SURGIDR AND ORCNT > 0 AND ATYPE IN (3) THEN DO;

      TPPS10 = 0; QPPS10 = 0; 

      IF (%MDX2($PHYSIDB.) AND %MPR($DIALYIP.))
      THEN TPPS10 = 1;

      IF (%MDX2Q1($PHYSIDB.) AND %MPR($DIALYIP.))
      THEN QPPS10 = 0;    

      *** Exclude principal diagnosis; 

      IF %MDX1($PHYSIDB.) THEN TPPS10 = .;
      IF %MDX2Q2($PHYSIDB.) THEN QPPS10 = 1;  

      *** Exclude if dialysis procedure occurs before or on the same
          day as the first OR procedure;
      %ORDAY($DIALYIP.);
      %MPRDAY($DIALYIP.);
      %PS10;

      *** Exclude Acute renal failure and AMI, Cardiac arrhythmia,
          Cardiac arrest, Shock, Hemorrhage, Gastrointestinal
          hemorrhage or Chronic renal failure;

      IF %MDX2($PHYSIDB.) AND (%MDX1($AMIID.) OR %MDX1($CARDRID.) OR
         %MDX1($CARDRID.) OR %MDX1($CARDIID.) OR %MDX1($SHOCKID.) OR
         %MDX1($HEMORID.) OR %MDX1($GASTRID.) OR %MDX1($CRENLFD.))
      THEN TPPS10 = .;

      IF %MDX2($PHYSIDB.) AND (%MDX2Q2($AMIID.) OR %MDX2Q2($CARDRID.) OR
         %MDX2Q2($CARDRID.) OR %MDX2Q2($CARDIID.) OR %MDX2Q2($SHOCKID.) OR
         %MDX2Q2($HEMORID.) OR %MDX2Q2($GASTRID.) OR %MDX2Q2($CRENLFD.))
      THEN QPPS10 = 1;


      *** Exclude MDC 14;

      IF MDC IN (14) THEN TPPS10 = .;

       *** Set POA flag to missing;

      IF TPPS10 = . OR NOPOA THEN QPPS10 = .;
      IF TPPS10 = 0 AND QPPS10 = 1 THEN QPPS10 = 0;

   END;

   * --- PERIOPERATIVE RESPIRATORY FAILURE                    --- ;

 %MACRO PS11N(FMT,DAYS);

    %MPRDAY(&FMT.);

    IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;

       IF MPRDAY >= ORDAY + &DAYS. THEN TPPS11 = 1;

    END;
    ELSE DO;

       IF %MPR2(&FMT.) THEN TPPS11 = 1;

    END;

 %MEND;

 %MACRO PS11;

 IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;

      IF MPRDAY < ORDAY THEN TPPS11 = .;

 END;
 ELSE DO;

      IF %MPR1($TRACHIP.) THEN TPPS11 = .;

 END;

 %MEND;

   IF SURGIDR AND ORCNT > 0 AND ATYPE IN (3) THEN DO;

      TPPS11 = 0; QPPS11 = 0;

      IF (ICDVER LE 28 AND %MDX2($ACURFID.))   or (ICDVER GE 29 AND %MDX2($ACURF2D.))   THEN TPPS11 = 1;
      IF (ICDVER LE 28 AND %MDX2Q1($ACURFID.)) or (ICDVER GE 29 AND %MDX2Q1($ACURF2D.)) THEN QPPS11 = 0;

      *** Include in numerator if reintubation procedure occurs on the same day or
          # days after the first OR procedure;
 
      %ORDAY($BLANK.);
      %PS11N($PR9604P.,1);
      %PS11N($PR9670P.,2);
      %PS11N($PR9671P.,2);
      %PS11N($PR9672P.,0);


	 *** Exclude principal diagnosis; 

      IF (ICDVER LE 28 AND %MDX1($ACURFID.))   or (ICDVER GE 29 AND %MDX1($ACURF2D.))    THEN TPPS11 = .;
      IF (ICDVER LE 28 AND %MDX2Q2($ACURFID.)) or (ICDVER GE 29 AND %MDX2Q2($ACURF2D.))  THEN QPPS11 = 1;

      *** Exclude if tracheostomy procedure is the only OR procedure;

      %MPRCNT($TRACHIP.);
      IF ORCNT = MPRCNT THEN TPPS11 = .;

      *** Exclude if tracheostomy procedure occurs before the 
          first OR procedure;
      %ORDAY($TRACHIP.);
      %MPRDAY($TRACHIP.);
      %PS11;

      *** Exclude Neuromuscular disorders;
 
      IF %MDX($NEUROMD.) THEN TPPS11 = .;

      *** Exclude MDC 4, 5, 14;
 
      IF MDC IN (4,5,14) THEN TPPS11 = .;

      *** Exclude Craniofacial anomalies;
      IF %MPR($NUCRANP.) OR
         (%MPR($CRANI2P.) AND %MDX($CRANIID.)) 
      THEN TPPS11 = .;

      *** Exclude Esophageal resection procedure ***;
      IF %MPR($PRESOPP.) OR %MPR($PRESO2P.) 
      THEN TPPS11 = .;

      *** Exclude Lung Cancer Procedure ***;
      IF %MPR($LUNGCIP.) THEN TPPS11 = .;
   
      *** Exclude diagnosis of degenerative neurological disorder ***;
      IF %MDX($DGNEUID.) THEN TPPS11 = .;

       *** Set POA flag to missing;

      IF TPPS11 = . OR NOPOA THEN QPPS11 = .;
      IF TPPS11 = 0 AND QPPS11 = 1 THEN QPPS11 = 0;

   END;

   * --- PERIOPERATIVE PE OR DVT                              --- ;

 %MACRO PS12;

   IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;
   
        IF MPRDAY <= ORDAY THEN TPPS12 = .;
   
   END;
   ELSE DO;
   
        IF %MPR1($VENACIP.) THEN TPPS12 = .;
        if %MPR($ECMOP.) then TPPS12 = . ; 
   
   END;

 %MEND;

   IF SURGIDR AND ORCNT > 0 THEN DO;

      TPPS12 = 0; QPPS12 = 0;

      IF (ICDVER LE 26 AND %MDX2($DEEPVID.)) OR %MDX2($PULMOID.) THEN TPPS12 = 1;
      IF (ICDVER GE 27 AND %MDX2($DEEPVIB.)) OR %MDX2($PULMOID.) THEN TPPS12 = 1;
      IF %MDX2Q1($DEEPVID.) OR %MDX2Q1($PULMOID.) THEN QPPS12 = 0;

      *** Exclude principal diagnosis; 

      IF (ICDVER LE 26 AND %MDX1($DEEPVID.)) OR %MDX1($PULMOID.) THEN TPPS12 = .;
      IF (ICDVER GE 27 AND %MDX1($DEEPVIB.)) OR %MDX1($PULMOID.) THEN TPPS12 = .;
      IF (ICDVER LE 26 AND %MDX2Q2($DEEPVID.)) OR %MDX2Q2($PULMOID.) THEN QPPS12 = 1;
      IF (ICDVER GE 27 AND %MDX2Q2($DEEPVIB.)) OR %MDX2Q2($PULMOID.) THEN QPPS12 = 1;


      *** Exclude if interruption of vena cava occurs before or on the
          same day as the first OR procedure;;

      %ORDAY($VENACIP.);
      %MPRDAY($VENACIP.);
      %PS12;

     *** Exclude MDC 14;

      IF MDC IN (14) THEN TPPS12 = .;

       *** Set POA flag to missing;

      IF TPPS12 = . OR NOPOA THEN QPPS12 = .;
      IF TPPS12 = 0 AND QPPS12 = 1 THEN QPPS12 = 0;

   END;

   * --- POSTOPERATIVE SEPSIS                                 --- ;

   IF SURGIDR AND ORCNT > 0 AND ATYPE IN (3) THEN DO;

      TPPS13 = 0; QPPS13 = 0;

      IF (ICDVER LE 21 AND %MDX2($SEPTIID.)) OR
         (ICDVER GE 22 AND %MDX2($SEPTI2D.))
      THEN TPPS13 = 1;

      IF (ICDVER LE 21 AND %MDX2Q1($SEPTIID.)) OR
         (ICDVER GE 22 AND %MDX2Q1($SEPTI2D.))
      THEN QPPS13 = 0;

      *** Exclude principal diagnosis; 

      IF (ICDVER LE 21 AND %MDX1($SEPTIID.)) OR
         (ICDVER GE 22 AND %MDX1($SEPTI2D.))
      THEN TPPS13 = .;

      IF (ICDVER LE 21 AND %MDX2Q2($SEPTIID.)) OR
         (ICDVER GE 22 AND %MDX2Q2($SEPTI2D.))
      THEN QPPS13 = 1;

      *** Immunocompromised or Cancer;

      IF %MDX($IMMUNID.) OR %MPR($IMMUNIP.) OR %MDX($CANCEID.)  
      THEN TPPS13 = .;

      *** Exclude Infection;

      IF %MDX1($INFECID.)   THEN TPPS13 = .;

      IF %MDX2Q2($INFECID.)  THEN QPPS13 = 1;
	  
      *** Exclude Length of stay less then 4 days;

      IF LOS < 4 THEN TPPS13 = .;

      *** Exclude MDC 14;

      IF MDC IN (14) THEN TPPS13 = .;

       *** Set POA flag to missing;

      IF TPPS13 = . OR NOPOA THEN QPPS13 = .;
      IF TPPS13 = 0 AND QPPS13 = 1 THEN QPPS13 = 0;

   END;

   * --- POSTOPERATIVE WOUND DEHISCENCE                       --- ;

 %MACRO PS14;

 IF (&PRDAY. = 1 AND MPRDAYA NE . AND MPRDAYB NE .) THEN DO;

      IF MPRDAYB <= MPRDAYA THEN TPPS14 = .;

 END;
 ELSE DO;

      IF %MPR1($RECLOIP.) THEN TPPS14 = .;

 END;

 %MEND;

   IF ((ICDVER LE 21 AND %MPR($ABDOMIP.)) OR
       (ICDVER GE 22 AND (%MPR($ABDOMIP.) OR %MPR($ABDOM2P.)))) 
      
   THEN DO;

      TPPS14 = 0; QPPS14 = 0;

      IF %MPR($RECLOIP.) THEN TPPS14 = 1;

      *** Exclude if wound reclosure occurs before or on the same
          day as the first abdominopelvic procedure;;

      %MPRDAY($ABDOMIP.); MPRDAYA = MPRDAY;
      %MPRDAY($RECLOIP.); MPRDAYB = MPRDAY;
      %PS14;

      *** Exclude Immunocompromised state;

      IF %MDX($IMMUNID.) OR %MPR($IMMUNIP.) 
      THEN TPPS14 = .;
 
      *** Exclude LOS < 2; 
      IF LOS < 2 THEN TPPS14 = .;

     *** Exclude MDC 14;

      IF MDC IN (14) THEN TPPS14 = .;

       *** Set POA flag to missing;

      IF TPPS14 = . OR NOPOA THEN QPPS14 = .;
      IF TPPS14 = 0 AND QPPS14 = 1 THEN QPPS14 = 0;

   END;

   * --- ACCIDENTAL PUNCTURE OR LACERATION                    --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TPPS15 = 0; QPPS15 = 0;

      IF %MDX2($TECHNID.) THEN TPPS15 = 1;
      IF %MDX2Q1($TECHNID.) THEN QPPS15 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($TECHNID.) THEN TPPS15 = .;
      IF %MDX2Q2($TECHNID.) THEN QPPS15 = 1;

      *** Exclude spine surgery; 

      IF %MPR($SPINEP.) THEN TPPS15 = .;

      *** Exclude MDC 14;

      IF MDC IN (14) THEN TPPS15 = .;

       *** Set POA flag to missing;

      IF TPPS15 = . OR NOPOA THEN QPPS15 = .;
      IF TPPS15 = 0 AND QPPS15 = 1 THEN QPPS15 = 0;

   END;

   * --- TRANSFUSION REACTION                                 --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TPPS16 = .; QPPS16 = .;
 
      IF %MDX2($TRANFID.) THEN TPPS16 = 1;
      IF %MDX2Q1($TRANFID.) THEN QPPS16 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($TRANFID.) THEN TPPS16 = .;
      IF %MDX2Q2($TRANFID.) THEN QPPS16 = 1;

       *** Set POA flag to missing;

      IF TPPS16 = . OR NOPOA THEN QPPS16 = .;
      IF TPPS16 = 0 AND QPPS16 = 1 THEN QPPS16 = 0;

   END;

   * --- OB TRAUMA - VAGINAL WITH INSTRUMENTATION             --- ;

   IF ((DRGVER LE 24 AND %MDR($PRVAGBG.))  OR
       (DRGVER GE 25 AND %MDR($PRVAG2G.))) AND 
      %MPR($INSTRIP.)
   THEN DO;

      TPPS18 = 0;

      IF %MDX($OBTRAID.) THEN TPPS18 = 1;

   END;

   * --- OB TRAUMA - VAGINAL WITHOUT INSTRUMENTATION          --- ;

   IF ((DRGVER LE 24 AND %MDR($PRVAGBG.))  OR
       (DRGVER GE 25 AND %MDR($PRVAG2G.))) AND NOT 
      %MPR($INSTRIP.) 
   THEN DO;

      TPPS19 = 0;

      IF %MDX($OBTRAID.) THEN TPPS19 = 1;

   END;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AREA LEVEL INDICATORS -------------------------- ;
 * -------------------------------------------------------------- ;

   * --- RETAINED SURGICAL ITEM OR UNRETRIEVED DEVICE FRAGMENT               --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TAPS21 = .;

      IF %MDX($FOREIID.) THEN TAPS21 = 1;

   END;

   * --- IATROGENIC PNEUMOTHORAX                              --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TAPS22 = 0;

      IF %MDX($IATROID.) THEN TAPS22 = 1;
   
      *** Exclude Chest Trauma, Pleural effusion or MDC 14;

      IF %MDX($CTRAUMD.) OR %MDX($PLEURAD.) OR MDC IN (14)
      THEN TAPS22 = .;

      *** Exclude Thoracic surgery, Lung or pleural biopsy,
          Cardiac surgery or Diaphragmatic surgery repair;

      IF %MPR($THORAIP.) OR %MPR($LUNGBIP.) OR %MPR($CARDSIP.) OR 
         %MPR($DIAPHRP.)
      THEN TAPS22 = .;

   END;

   * --- CENTRAL LINE ASSOCIATED BSI                        --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TAPS23 = 0;

      IF ((ICDVER LE 24 AND (%MDX($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX($IDTMC3D.))))

      THEN TAPS23 = 1;

  
      *** Exclude Immunocompromised state and Cancer;
 
      IF %MDX($IMMUNID.) OR %MPR($IMMUNIP.) OR %MDX($CANCEID.)  
      THEN TAPS23 = .;

   END;

   * --- POSTOPERATIVE WOUND DEHISCENCE                       --- ;

   TAPS24 = 0;

   IF %MPR($RECLOIP.) THEN TAPS24 = 1;

   *** Exclude Immunocompromised state;
   IF %MDX($IMMUNID.) OR %MPR($IMMUNIP.) 
   THEN TAPS24 = .;
 
   *** Exclude MDC 14;

   IF MDC IN (14) THEN TAPS24 = .;

   * --- ACCIDENTAL PUNCTURE OR LACERATION                    --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TAPS25 = 0;

      IF %MDX($TECHNID.) THEN TAPS25 = 1;

      *** Exclude spine surgery; 

      IF %MPR($SPINEP.) THEN TAPS25 = .;

      *** Exclude MDC 14;

      IF MDC IN (14) THEN TAPS25 = .;

   END;

   * --- TRANSFUSION REACTION                                 --- ;

   IF (MEDICDR OR SURGIDR) THEN DO;

      TAPS26 = .;
 
      IF %MDX($TRANFID.) THEN TAPS26 = 1;

   END;

   * --- POSTOPERATIVE HEMORRHAGE OR HEMATOMA                 --- ;

   TAPS27 = 0;

   IF (%MDX($POHMRI2D.) AND %MPR($HEMOTH2P.)) 
   THEN TAPS27 = 1;

   *** Exclude MDC 14;

   IF MDC IN (14) THEN TAPS27 = .;

   *** Exclude Coagulation Disorders;

      IF %MDX($COAGDID.) THEN TAPS27 = . ;


 * -------------------------------------------------------------- ;
 * --- IDENTIFY TRANSFERS --------------------------------------- ;
 * -------------------------------------------------------------- ;

 * --- TRANSFER FROM ANOTHER ACUTE ---------------- ;
 IF ASOURCE IN (2) OR POINTOFORIGINUB04 IN ('4') THEN TRNSFER = 1;
 ELSE TRNSFER = 0;
 IF ASOURCE GT .Z AND POINTOFORIGINUB04 IN (' ') THEN NOPOUB04 = 1;
 ELSE NOPOUB04 = 0;

 * --- TRANSFER TO ANOTHER ACUTE ---------------- ;

 IF DISP IN (2) THEN TRNSOUT = 1;ELSE TRNSOUT = 0;

 * --- Sync QPPS, TPPS and PPPS values ---------------- ;

 IF NOPOA IN (0) THEN DO;
    IF QPPS03 IN (.,1) THEN TPPS03 = .;
    IF QPPS06 IN (.,1) THEN TPPS06 = .;
    IF QPPS07 IN (.,1) THEN TPPS07 = .;
    IF QPPS08 IN (.,1) THEN TPPS08 = .;
    IF QPPS09 IN (.,1) THEN TPPS09 = .;
    IF QPPS10 IN (.,1) THEN TPPS10 = .;
    IF QPPS11 IN (.,1) THEN TPPS11 = .;
    IF QPPS12 IN (.,1) THEN TPPS12 = .;
    IF QPPS13 IN (.,1) THEN TPPS13 = .;
    IF QPPS14 IN (.,1) THEN TPPS14 = .;
    IF QPPS15 IN (.,1) THEN TPPS15 = .;
    IF QPPS16 IN (.,1) THEN TPPS16 = .;
 END;

 IF QPPS05 IN (.,1) THEN TPPS05 = .;

 ARRAY TPPS TPPS02-TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05-TPPS16 TPPS18 TPPS19;
 ARRAY PPPS 3 PPPS02-PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS05-PPPS16 PPPS18 PPPS19;

 DO OVER TPPS;
    IF TPPS GE 0 THEN PPPS = 1;
    ELSE PPPS = .;
 END;

 * -------------------------------------------------------------- ;
 * --- LABELS --------------------------------------------------- ;
 * -------------------------------------------------------------- ;

 LABEL
    TRNSFER  = 'TRANSFER FROM ACUTE'
    TRNSOUT  = 'TRANSFER TO ACUTE'
    MAXDX    = 'NUMBER OF DX CODES'
    ECDDX    = 'PRESENCE OF ECODES'
    MAXPR    = 'NUMBER OF PR CODES'
    NOPOA    = 'NO POA'
    NOPRDAY  = 'NO PRDAY'
    NOPOUB04 = 'NO POINT OF ORIGIN'
    PALLIAFG = 'PALLIATIVE FLAG'
 ;

RUN;



PROC CONTENTS DATA=OUT1.&OUTFILE1. POSITION;
RUN;

PROC PRINT DATA=OUT1.&OUTFILE1. (OBS=24);
TITLE4 "FIRST 24 RECORDS IN OUTPUT DATA SET &OUTFILE1.";
RUN;


***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS MIN MAX NOLABELS ;
	 VAR KEY HOSPID DRG DRGVER MDC MDRG YEAR DQTR 
         AGECAT POPCAT  SEXCAT RACECAT PAYCAT DUALCAT LOS TRNSFER MAXDX 
         MAXPR NOPOA NOPOUB04 NOPRDAY TRNSOUT PALLIAFG;
     TITLE4 "CATEGORICAL VARIABLES AND RANGES OF VALUES";
RUN; QUIT;


PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM MEAN NOLABELS ;
	 VAR CHF VALVE PULMCIRC PERIVASC HTN_C  PARA NEURO CHRNLUNG DM DMCX
      HYPOTHY RENLFAIL LIVER ULCER AIDS  LYMPH METS TUMOR ARTH OBESE
      WGHTLOSS BLDLOSS ANEMDEF ALCOHOL DRUG PSYCH DEPRESS 
      XHF XALVE XULMCIRC XERIVASC XTN_C XARA XEURO XHRNLUNG XM XMCX
      XYPOTHY XENLFAIL XIVER XLCER XIDS XYMPH XETS XUMOR XRTH XBESE
      XGHTLOSS XLDLOSS XNEMDEF XLCOHOL XRUG XSYCH XEPRESS
       /* PALLIAFG*/ ;
     TITLE "PATIENT SAFETY INDICATOR CASES CO-MORBIDITY COUNTS (=SUM) AND RATES (=MEAN)";
RUN; QUIT;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM NOLABELS ;
     VAR TAPS21-TAPS27;
    * OUTPUT OUT=STATS1;
     TITLE "PATIENT SAFETY INDICATOR NUMERATORS FOR AREA-BASED OR COUNT BASED INDICATORS (COUNT =SUM)";
RUN; QUIT;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM MEAN  NOLABELS ;
     VAR TPPS02-TPPS04  TPPS04A--TPPS04E TPPS05-TPPS16 TPPS18 TPPS19;
    * OUTPUT OUT=STATS2;
     TITLE "PATIENT SAFETY PROVIDER LEVEL INDICATOR NUMERATOR (=SUM),DENOMINATOR (=N), AND OBSERVED RATE (MEAN) ";
RUN; QUIT;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM MEAN NOLABELS ;
     WHERE NOT NOPOA;
     VAR TPPS02-TPPS04  TPPS04A--TPPS04E TPPS05-TPPS16;
    * OUTPUT OUT=STATS3;
     TITLE1 "PATIENT SAFETY PROVIDER LEVEL INDICATOR NUMERATORS (=SUM),DENOMINATORS (=N), AND OBSERVED RATE (MEAN) ";
     TITLE2 "WITH POA MODIFIERS";
RUN; QUIT;
