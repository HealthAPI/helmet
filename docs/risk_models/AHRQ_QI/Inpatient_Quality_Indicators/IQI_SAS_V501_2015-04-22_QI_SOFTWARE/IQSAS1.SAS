*==================================== PROGRAM: IQSAS1.SAS  ====================================;
*==============================================================================================;
*  Title:  PROGRAM 1  ASSIGN AHRQ INPATIENT QUALITY INDICATORS
*          TO INPATIENT RECORDS
*
*  Description:;
*         ASSIGNS THE OUTCOME OF INTEREST AND POPULATION AT RISK
*         INDICATORS TO INPATIENT RECORDS;
*
*          >>>    VERSION 5.0, MARCH 2015     <<<
*
*  USER NOTE1:  Make sure you have created the format library
*              using IQFMTS.SAS BEFORE running this program.
*
*  USER NOTE2: The AHRQ QI software does not support the calculation of weighted estimates
*              and standard errors using complex sampling designs. Beginning with v5.0, 
*              all references to a discharge weight (DISCWT) have been removed from all 
*              programs. In order to obtain weighted nationally representative estimates,
*              please refer to the technical documentation on the AHRQ QI website.
*==============================================================================================;
FILENAME CONTROL 'C:\PATHNAME\CONTROL_IQI.SAS'; *<===USER MUST modify;

%INCLUDE CONTROL;

 TITLE2 'PROGRAM 1';
 TITLE3 'AHRQ INPATIENT QUALITY INDICATORS: ASSIGN QIS TO INPATIENT DATA';

 * -------------------------------------------------------------- ;
 * --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS THAT --- ; 
 * --- WILL NOT BE INCLUDED IN ANALYSIS BECAUSE KEY VARIABLE  --- ;
 * --- VALUES ARE MISSING								      --- ;
 * -------------------------------------------------------------- ;

 DATA   OUT1.&DELFILE1.
 	(KEEP=KEY HOSPID SEX AGE DX1 MDC YEAR DQTR);
 SET 	IN0.&INFILE0.;
 IF (AGE LT 0) OR (AGE LT 18 AND MDC NOTIN (14)) OR (SEX LE 0) OR 
	(DX1 IN (' ')) OR (DQTR LE .Z) OR (YEAR LE .Z);
 RUN;


 * -------------------------------------------------------------- ;
 * --- INPATIENT QUALITY INDICATOR (IQI) NAMING CONVENTION:   --- ;
 * --- THE FIRST LETTER IDENTIFIES THE INPATIENT QUALITY      --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:
                (O) OBSERVED RATES
                (E) EXPECTED RATES
                (R) RISK-ADJUSTED RATES
                (S) SMOOTHED RATES
                (T) NUMERATOR ("TOP")
                (D) NUMERATOR ("30 DAY")
                (P) POPULATION ("POP")
 * --- THE SECOND LETTER IDENTIFIES THE IQI AS A PROVIDER (P) --- ;
 * --- OR AN AREA (A) LEVEL INDICATOR.  THE                   --- ;
 * --- NEXT TWO CHARACTERS ARE ALWAYS 'IQ'. THE LAST TWO      --- ;
 * --- DIGITS ARE THE INDICATOR NUMBER (WITHIN THAT SUBTYPE). --- ;
 * -------------------------------------------------------------- ;

 %MACRO ADDPRDAY; 
    %IF &PRDAY EQ 1 %THEN PRDAY1-PRDAY&NPR. ;
 %MEND;

 %MACRO ADDAPR;
    %IF &APRDRGFG EQ 1 %THEN &APRDRG &MORTAL &XMORTAL;
 %MEND;
 
 DATA   OUT1.&OUTFILE1.
    (KEEP=KEY HOSPID FIPST FIPSTCO DRG DRGVER MDC YEAR DQTR
          AGECAT POPCAT SEXCAT RACECAT PAYCAT DUALCAT %ADDAPR LOS
          TRNSFER MAXDX MAXPR PCTPOA NOPOA PALLIAFG 
          NOPOUB04 NOPRDAY TRNSOUT ECDDX WHIPPLE RUPTURED STROKE 
          TPIQ01  TPIQ02   TPIQ02A  TPIQ02B TPIQ04  TPIQ04A--TPIQ04D TPIQ05-TPIQ09 
          TPIQ09A  TPIQ09B  TPIQ11  TPIQ11A--TPIQ11D TPIQ12-TPIQ17 
          TPIQ17A--TPIQ17C TPIQ18-TPIQ20 TPIQ30-TPIQ34
          QPIQ08  QPIQ09   QPIQ09A QPIQ09B QPIQ11 QPIQ11A--QPIQ11D QPIQ12-QPIQ17
          QPIQ17A--QPIQ17C QPIQ18-QPIQ20 QPIQ30-QPIQ32 
          DPIQ08   DPIQ09  DPIQ09A DPIQ09B DPIQ11 DPIQ11A--DPIQ11D DPIQ12-DPIQ17 
          DPIQ17A--DPIQ17C DPIQ18-DPIQ20 DPIQ30-DPIQ32 
          TPIQ21-TPIQ25    TAIQ26-TAIQ29 );
 SET   IN0.&INFILE0.
    (KEEP=KEY HOSPID DRG DRGVER MDC SEX AGE PSTCO RACE YEAR DQTR
          PAY1 PAY2 DISP MORT30 LOS ASOURCE POINTOFORIGINUB04 DNR
          DX1-DX&NDX. PR1-PR&NPR. %ADDPRDAY %ADDAPR 
          DXPOA1-DXPOA&NDX.);

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

 ((PUT(DX1,&FMT.) = '1'))

 %MEND;

 %MACRO MDR(FMT);

 (PUT(PUT(DRG,Z3.),&FMT.) = '1')

 %MEND;

 %MACRO MPR(FMT);

 (%DO I = 1 %TO &NPR.-1;
  (PUT(PR&I.,&FMT.) = '1' ) OR
  %END;
  (PUT(PR&NPR.,&FMT.) = '1' ))

 %MEND;


 * -------------------------------------------------------------- ;
 * --- DEFINE MDC                        ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB MDCNEW LENGTH=3
   LABEL='IMPUTED MDC';

 IF DRGVER LE .Z THEN DO;
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
  ELSE IF  YEAR GT 2014 											THEN DRGVER = 32;
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
 

 * ------------------------------------------------------------------------- ;
 * --- DELETE RECORDS WITH MISSING VALUES FOR AGE, SEX, DX1, DQTR, & YEAR -- ;
 * --- DELETE NON ADULT RECORDS                         -------------------- ;
 * ------------------------------------------------------------------------- ;
 IF SEX LE 0 THEN DELETE;
 IF AGE LT 0 THEN DELETE;
 IF AGE LT 18 AND MDC NOTIN (14) THEN DELETE;
 IF DX1 IN (' ') THEN DELETE;
 IF DQTR LE .Z THEN DELETE;
 IF YEAR LE .Z THEN DELETE;


 * -------------------------------------------------------------- ;
 * --- CALCULATE PERCENT POA                            --------- ;
 * -------------------------------------------------------------- ;
 ARRAY ARRY1{&NDX.} DX1-DX&NDX.;
 ARRAY ARRY2{&NDX.} DXPOA1-DXPOA&NDX.;

 MAXDX = 0; ECDDX = 0; 
 PCTPOA = .; CNTPOA = 0; CNTNPOA = 0; NOPOA = 1;
 DO I = 1 TO &NDX.;
    IF ARRY1(I) NOTIN (' ') THEN DO;
       MAXDX + 1;
       IF ARRY2(I) IN ('Y','W','E','1') THEN CNTPOA + 1;
       ELSE IF ARRY2(I) IN ('N','U','0') THEN CNTNPOA + 1;
       IF SUBSTR(ARRY1(I),1,1) IN ('E') THEN ECDDX = 1; 
    END;
 END;
 IF CNTPOA > 0 OR CNTNPOA > 0 THEN DO;
    NOPOA = 0;
    PCTPOA = CNTPOA / MAXDX;
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
 IF (YEAR IN (1994) AND DQTR IN (4))     THEN ICDVER = 12;
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
 ELSE IF (YEAR IN (2009) AND DQTR IN (4))     THEN ICDVER = 27;
 ELSE IF (YEAR IN (2010) AND DQTR IN (1,2,3)) THEN ICDVER = 27;
 ELSE IF (YEAR IN (2010) AND DQTR IN (4))     THEN ICDVER = 28;
 ELSE IF (YEAR IN (2011) AND DQTR IN (1,2,3)) THEN ICDVER = 28;
 ELSE IF (YEAR IN (2011) AND DQTR IN (4))     THEN ICDVER = 29;
 ELSE IF (YEAR IN (2012) AND DQTR IN (1,2,3)) THEN ICDVER = 29;
 ELSE IF (YEAR IN (2012) AND DQTR IN (4))     THEN ICDVER = 30;
 ELSE IF (YEAR IN (2013) AND DQTR IN (1,2,3)) THEN ICDVER = 30;
 ELSE IF (YEAR IN (2013) AND DQTR IN (4))     THEN ICDVER = 31;
 ELSE IF (YEAR IN (2014) AND DQTR IN (1,2,3)) THEN ICDVER = 31;
 ELSE IF (YEAR IN (2014) AND DQTR IN (4))     THEN ICDVER = 32;
 ELSE IF  YEAR GT  2014	                      THEN ICDVER = 32;

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

 ATTRIB DUALCAT LENGTH=3
   LABEL='PATIENT DUAL ELIGIBLE';

 IF (PAY1 IN (1) AND PAY2 IN (2)) OR
    (PAY1 IN (2) AND PAY2 IN (1)) 
 THEN DUALCAT = 1; ELSE DUALCAT = 0;
 

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
 * --- DEFINE PROVIDER LEVEL VOLUME INDICATORS ------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB
 TPIQ01 LENGTH=8
   LABEL='IQI 01 Esophageal Resection Volume (Numerator)'
 TPIQ02 LENGTH=8
   LABEL='IQI 02 Pancreatic Resection Volume (Numerator)'
 TPIQ02A LENGTH=8
   LABEL='IQI 02 Pancreatic Resection Volume Stratum A (Numerator)'
 TPIQ02B LENGTH=8
   LABEL='IQI 02 Pancreatic Resection Volume Stratum B (Numerator)'
 TPIQ04 LENGTH=8
   LABEL='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume (Numerator)'
 TPIQ04A LENGTH=8
   LABEL='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum A (Numerator)'
 TPIQ04B LENGTH=8
   LABEL='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum B (Numerator)'
 TPIQ04C LENGTH=8
   LABEL='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum C (Numerator)'
 TPIQ04D LENGTH=8
   LABEL='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum D (Numerator)'
 TPIQ05 LENGTH=8
   LABEL='IQI 05 Coronary Artery Bypass Graft (CABG) Volume (Numerator)'
 TPIQ06 LENGTH=8
   LABEL='IQI 06 Percutaneous Coronary Intervention (PCI) Volume (Numerator)'
 TPIQ07 LENGTH=8
   LABEL='IQI 07 Carotid Endarterectomy Volume (Numerator)'
;

 * -------------------------------------------------------------- ;
 * --- DEFINE PROVIDER LEVEL MORTALITY INDICATORS --------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB
 TPIQ08 LENGTH=8
   LABEL='IQI 08 Esophageal Resection Mortality Rate (Numerator)'
 TPIQ09 LENGTH=8                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate (Numerator)'
 TPIQ09A LENGTH=8                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate Stratum A (Numerator)'
 TPIQ09B LENGTH=8                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate Stratum B (Numerator)'
 TPIQ11 LENGTH=8
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate (Numerator)'
 TPIQ11A LENGTH=8
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum A (Numerator)'
 TPIQ11B LENGTH=8
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum B (Numerator)'
 TPIQ11C LENGTH=8
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum C (Numerator)'
 TPIQ11D LENGTH=8
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum D (Numerator)'
 TPIQ12 LENGTH=8
   LABEL='IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate (Numerator)'
 TPIQ13 LENGTH=8
   LABEL='IQI 13 Craniotomy Mortality Rate (Numerator)'
 TPIQ14 LENGTH=8
   LABEL='IQI 14 Hip Replacement Mortality Rate (Numerator)'
;

 ATTRIB
 QPIQ08 LENGTH=3
   LABEL='IQI 08 Esophageal Resection Mortality Rate (PAL)'
 QPIQ09 LENGTH=3                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate (PAL)'
 QPIQ09A LENGTH=3                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate Stratum A (PAL)'
 QPIQ09B LENGTH=3                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate Stratum B (PAL)'
 QPIQ11 LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate (PAL)'
 QPIQ11A LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum A (PAL)'
 QPIQ11B LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum B (PAL)'
 QPIQ11C LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum C (PAL)'
 QPIQ11D LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum D (PAL)'
 QPIQ12 LENGTH=3
   LABEL='IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate (PAL)'
 QPIQ13 LENGTH=3
   LABEL='IQI 13 Craniotomy Mortality Rate (PAL)'
 QPIQ14 LENGTH=3
   LABEL='IQI 14 Hip Replacement Mortality Rate (PAL)'
;

 ATTRIB
 DPIQ08 LENGTH=3
   LABEL='IQI 08 Esophageal Resection Mortality Rate (Numerator)'
 DPIQ09 LENGTH=3                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate (Numerator)'
 DPIQ09A LENGTH=3                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate Stratum A (Numerator)'
 DPIQ09B LENGTH=3                           
   LABEL='IQI 09 Pancreatic Resection Mortality Rate Stratum B (Numerator)'
 DPIQ11 LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate (Numerator)'
 DPIQ11A LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum A (Numerator)'
 DPIQ11B LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum B (Numerator)'
 DPIQ11C LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum C (Numerator)'
 DPIQ11D LENGTH=3
   LABEL='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum D (Numerator)'
 DPIQ12 LENGTH=3
   LABEL='IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate (Numerator)'
 DPIQ13 LENGTH=3
   LABEL='IQI 13 Craniotomy Mortality Rate (Numerator)'
 DPIQ14 LENGTH=3
   LABEL='IQI 14 Hip Replacement Mortality Rate (Numerator)'
;

 ATTRIB
 TPIQ15 LENGTH=8
   LABEL='IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate (Numerator)'
 TPIQ16 LENGTH=8
   LABEL='IQI 16 Heart Failure Mortality Rate (Numerator)'
 TPIQ17 LENGTH=8
   LABEL='IQI 17 Acute Stroke Mortality Rate (Numerator)'
 TPIQ17A LENGTH=8
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum A (Numerator)'
 TPIQ17B LENGTH=8
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum B (Numerator)'
 TPIQ17C LENGTH=8
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum C (Numerator)'
 TPIQ18 LENGTH=8
   LABEL='IQI 18 Gastrointestinal Hemorrhage Mortality Rate (Numerator)'
 TPIQ19 LENGTH=8
   LABEL='IQI 19 Hip Fracture Mortality Rate (Numerator)'
 TPIQ20 LENGTH=8
   LABEL='IQI 20 Pneumonia Mortality Rate (Numerator)'
;

 ATTRIB
 QPIQ15 LENGTH=3
   LABEL='IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate (PAL)'
 QPIQ16 LENGTH=3
   LABEL='IQI 16 Heart Failure Mortality Rate (PAL)'
 QPIQ17 LENGTH=3
   LABEL='IQI 17 Acute Stroke Mortality Rate (PAL)'
 QPIQ17A LENGTH=3
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum A (PAL)'
 QPIQ17B LENGTH=3
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum B (PAL)'
 QPIQ17C LENGTH=3
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum C (PAL)'
 QPIQ18 LENGTH=3
   LABEL='IQI 18 Gastrointestinal Hemorrhage Mortality Rate (PAL)'
 QPIQ19 LENGTH=3
   LABEL='IQI 19 Hip Fracture Mortality Rate (PAL)'
 QPIQ20 LENGTH=3
   LABEL='IQI 20 Pneumonia Mortality Rate (PAL)'
;

 ATTRIB
 DPIQ15 LENGTH=3
   LABEL='IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate (Numerator)'
 DPIQ16 LENGTH=3
   LABEL='IQI 16 Heart Failure Mortality Rate (Numerator)'
 DPIQ17 LENGTH=3
   LABEL='IQI 17 Acute Stroke Mortality Rate (Numerator)'
 DPIQ17A LENGTH=3
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum A (Numerator)'
 DPIQ17B LENGTH=3
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum B (Numerator)'
 DPIQ17C LENGTH=3
   LABEL='IQI 17 Acute Stroke Mortality Rate Stratum C (Numerator)'
 DPIQ18 LENGTH=3
   LABEL='IQI 18 Gastrointestinal Hemorrhage Mortality Rate (Numerator)'
 DPIQ19 LENGTH=3
   LABEL='IQI 19 Hip Fracture Mortality Rate (Numerator)'
 DPIQ20 LENGTH=3
   LABEL='IQI 20 Pneumonia Mortality Rate (Numerator)'
;

 * -------------------------------------------------------------- ;
 * --- DEFINE ADDITIONAL PROVIDER LEVEL MORTALITY INDICATORS ---- ;
 * -------------------------------------------------------------- ;
 ATTRIB
 TPIQ30 LENGTH=8
   LABEL='IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate (Numerator)'
 TPIQ31 LENGTH=8
   LABEL='IQI 31 Carotid Endarterectomy Mortality Rate (Numerator)'
 TPIQ32 LENGTH=8
   LABEL='IQI 32 Acute Myocardial Infarction (AMI) Mortality Rate, Without Transfer Cases (Numerator)'
;

 ATTRIB
 QPIQ30 LENGTH=3
   LABEL='IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate (PAL)'
 QPIQ31 LENGTH=3
   LABEL='IQI 31 Carotid Endarterectomy Mortality Rate (PAL)'
 QPIQ32 LENGTH=3
   LABEL='IQI 32 Acute Myocardial Infarction (AMI) Mortality Rate, Without Transfer Cases (PAL)'
;

 ATTRIB
 DPIQ30 LENGTH=3
   LABEL='IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate (Numerator)'
 DPIQ31 LENGTH=3
   LABEL='IQI 31 Carotid Endarterectomy Mortality Rate (Numerator)'
 DPIQ32 LENGTH=3
   LABEL='IQI 32 Acute Myocardial Infarction (AMI) Mortality Rate, Without Transfer Cases (Numerator)'
;
 * -------------------------------------------------------------- ;
 * --- DEFINE PROVIDER LEVEL UTILIZATION INDICATORS ------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB
 TPIQ21 LENGTH=8
   LABEL='IQI 21 Cesarean Delivery Rate, Uncomplicated (Numerator)'
 TPIQ22 LENGTH=8
   LABEL='IQI 22 Vaginal Birth After Cesarean (VBAC) Delivery Rate, Uncomplicated (Numerator)'
 TPIQ23 LENGTH=8
   LABEL='IQI 23 Laparoscopic Cholecystectomy Rate (Numerator)'
 TPIQ24 LENGTH=8
   LABEL='IQI 24 Incidental Appendectomy in the Elderly Rate (Numerator)'
 TPIQ25 LENGTH=8
   LABEL='IQI 25 Bilateral Cardiac Catheterization Rate (Numerator)'
;

 * -------------------------------------------------------------- ;
 * --- DEFINE ADDITIONAL PROVIDER LEVEL UTILIZATION INDICATORS -- ;
 * -------------------------------------------------------------- ;
 ATTRIB
 TPIQ33 LENGTH=8
   LABEL='IQI 33 Primary Cesarean Delivery Rate, Uncomplicated (Numerator)'
 TPIQ34 LENGTH=8
   LABEL='IQI 34 Vaginal Birth After Cesarean (VBAC) Rate, All (Numerator)'
;

 * -------------------------------------------------------------- ;
 * --- DEFINE AREA LEVEL UTILIZATION INDICATORS ----------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB
 TAIQ26 LENGTH=8
   LABEL='IQI 26 Coronary Artery Bypass Graft (CABG) Rate (Numerator)'
 TAIQ27 LENGTH=8
   LABEL='IQI 27 Percutaneous Coronary Intervention (PCI) Rate (Numerator)'
 TAIQ28 LENGTH=8
   LABEL='IQI 28 Hysterectomy Rate (Numerator)'
 TAIQ29 LENGTH=8
   LABEL='IQI 29 Laminectomy or Spinal Fusion Rate (Numerator)'
;

 * -------------------------------------------------------------- ;
 * --- CONSTRUCT PROVIDER LEVEL VOLUME INDICATORS --------------- ;
 * -------------------------------------------------------------- ;

   * --- VOLUME ESOPHAGEAL RESECTION       --- ;

   IF (%MPR($PRESOPP.) OR 
      (%MPR($PRESO2P.) AND %MDX($PRESOPD.))) 
   THEN

      TPIQ01 = 1;

  
   * --- VOLUME PANCREATIC RESECTION       --- ;

   IF (%MPR($PRPANCP.) OR %MPR($PRPAN3P.)) THEN DO;

      	TPIQ02 = 1;

	   	IF (%MDX($PRPANCD.)) THEN TPIQ02A = 1 ;

	   	ELSE TPIQ02B = 1 ;

	END;

   	IF %MDX($PRPAN2D.) THEN DO;

		TPIQ02 = .;
     	TPIQ02A = .; 
     	TPIQ02B = .;

	END;


   * --- VOLUME AAA REPAIR                 --- ;

   IF (%MDX($PRAAARD.) OR %MDX($PRAAA2D.)) AND 
      (%MPR($PRAAARP.)  OR %MPR($PRAAA2P.)) THEN

      TPIQ04 = 1;


   * --- VOLUME AAA REPAIR (STRATIFICATION)               --- ;
   * --- stratification priority according to prior probability of death --- ;


        /** OPEN REPAIR - RUPTURED ***/ 
		IF %MPR($PRAAARP.) AND %MDX($PRAAARD.) THEN DO;
		   TPIQ04A = 1;
		END;

		/** ENDOVASCULAR REPAIR  - RUPTURED ***/
		ELSE IF %MPR($PRAAA2P.) AND %MDX($PRAAARD.) THEN DO;
		   TPIQ04C = 1;
		END;

		/** OPEN REPAIR - UNRUPTURED ***/
		ELSE IF %MPR($PRAAARP.) AND %MDX($PRAAA2D.) THEN DO;
		   TPIQ04B = 1;
		END;

	    /** ENDOVASCULAR REPAIR - UNRUPTURED ***/
		ELSE IF %MPR($PRAAA2P.) AND %MDX($PRAAA2D.) THEN DO;
		   TPIQ04D = 1;
		END;


   * --- VOLUME CABG                       --- ;

   IF %MPR($PRCABGP.) THEN

      TPIQ05 = 1;

   * --- VOLUME PTCA                       --- ;

   IF %MPR($PRPTCAP.) THEN

      TPIQ06 = 1;

   * --- VOLUME CAROTID ENDARTERECTOMY     --- ;

   IF %MPR($PRCEATP.) THEN

      TPIQ07 = 1;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT PROVIDER LEVEL MORTALITY INDICATORS ------------ ;
 * -------------------------------------------------------------- ;

   * --- IN-HOSP MORT ESOPHAGEAL RESECTION --- ;

   IF MDC NOTIN (14) AND
      ((%MPR($PRESOPP.) AND (%MDX($PRESOPD.) OR %MDX($PRESO2D.))) OR 
       (%MPR($PRESO2P.) AND %MDX($PRESOPD.))) 
   THEN DO;

      TPIQ08 = 0; QPIQ08 = 0; DPIQ08 = 0;
      IF DISP IN (20) THEN TPIQ08 = 1;
      IF MORT30 THEN DPIQ08 = 1;
      IF PALLIAFG THEN QPIQ08 = 1;

   END;

  
   * --- IN-HOSP MORT PANCREATIC RESECTION --- ;

   IF MDC NOTIN (14) AND (%MPR($PRPANCP.) OR %MPR($PRPAN3P.)) THEN DO;

      TPIQ09 = 0; QPIQ09 = 0; DPIQ09 = 0;
      IF DISP IN (20) THEN TPIQ09 = 1;
      IF MORT30 THEN DPIQ09 = 1;
      IF PALLIAFG THEN QPIQ09 = 1;

	  IF %MDX($PRPANCD.) THEN DO;
			TPIQ09A = 0; QPIQ09A = 0; DPIQ09A = 0;
           	IF DISP IN (20) THEN TPIQ09A = 1;
		   	IF MORT30 THEN DPIQ09A = 1;
		   	IF PALLIAFG THEN QPIQ09A = 1;
	  END;
	  ELSE DO;
	       TPIQ09B = 0; QPIQ09B = 0; DPIQ09B = 0; 
 		   IF DISP IN (20) THEN TPIQ09B = 1;
		   IF MORT30 THEN DPIQ09B = 1;
		   IF PALLIAFG THEN QPIQ09B = 1;
	  END;

	 * ---------------------------------------------- ;
	 * --- EXCLUDE ACUTE PANCREATITIS             --- ;
	 * ---------------------------------------------- ;

      IF %MDX($PRPAN2D.) THEN DO;
		   TPIQ09 = .;
		   TPIQ09A = .;
		   TPIQ09B = .;
	  END;

      WHIPPLE = %MPR($PRPAN2P.);

   END;


   * --- IN-HOSP MORT AAA REPAIR           --- ;

   IF MDC NOTIN (14) AND 
      (%MDX($PRAAARD.) OR %MDX($PRAAA2D.)) AND 
      (%MPR($PRAAARP.) OR %MPR($PRAAA2P.))

      THEN DO;

      TPIQ11 = 0; QPIQ11 = 0; DPIQ11 = 0;

      IF DISP IN (20) THEN TPIQ11 = 1;

      IF MORT30 THEN DPIQ11 = 1;

      IF PALLIAFG THEN QPIQ11 = 1;

      RUPTURED = %MDX($PRAAARD.);

   END;

       
   * --- IN-HOSP MORT AAA REPAIR (STRATIFICATION)          --- ;
   * --- stratification priority according to prior probability of death --- ;
   
   IF MDC NOTIN (14) THEN DO;

      /** OPEN REPAIR- RUPTURED ***/
	   IF %MPR($PRAAARP.) AND %MDX($PRAAARD.) THEN DO;
	      TPIQ11A = 0; QPIQ11A = 0; DPIQ11A = 0;
		  IF DISP IN (20) THEN TPIQ11A = 1;
		  IF MORT30   THEN DPIQ11A = 1;
		  IF PALLIAFG THEN QPIQ11A = 1;
	   END;

	  /** ENDOVASCULAR REPAIR - RUPTURED ***/
	   ELSE IF %MPR($PRAAA2P.) AND %MDX($PRAAARD.) THEN DO;
	         TPIQ11C = 0; QPIQ11C = 0; DPIQ11C = 0;
			 IF DISP IN (20) THEN TPIQ11C = 1;
			 IF MORT30   THEN DPIQ11C = 1;
		     IF PALLIAFG THEN QPIQ11C = 1;
	   END;

	  /** OPEN REPAIR- UNRUPTURED ***/
	   ELSE IF %MPR($PRAAARP.) AND %MDX($PRAAA2D.) THEN DO;
	         TPIQ11B = 0; QPIQ11B = 0; DPIQ11B = 0;
			 IF DISP IN (20) THEN TPIQ11B = 1;
			 IF MORT30   THEN DPIQ11B = 1;
		     IF PALLIAFG THEN QPIQ11B = 1;
	   END;

	  /** ENDOVASCULAR REPAIR  - UNRUPTURED ***/
	   ELSE IF %MPR($PRAAA2P.) AND %MDX($PRAAA2D.) THEN DO;
	         TPIQ11D = 0; QPIQ11D = 0; DPIQ11D = 0;
			 IF DISP IN (20) THEN TPIQ11D = 1;
			 IF MORT30   THEN DPIQ11D = 1;
		     IF PALLIAFG THEN QPIQ11D = 1;
	   END;

	   RUPTURED = %MDX($PRAAARD.);
   END;


   * --- IN-HOSP MORT CABG                 --- ;

   IF MDC NOTIN (14) AND (AGE >= 40) AND
      %MPR($PRCABGP.) 
   THEN DO;

      TPIQ12 = 0; QPIQ12 = 0; DPIQ12 = 0;
      IF DISP IN (20) THEN TPIQ12 = 1;
      IF MORT30 THEN DPIQ12 = 1;
      IF PALLIAFG THEN QPIQ12 = 1;

   END;

   * --- IN-HOSP MORT CRANIOTOMY           --- ;

   IF (DRGVER LE 24 AND %MDR($CRANIOTG.)) OR
      (DRGVER GE 25 AND %MDR($CRANIO2G.)) 
   THEN DO;

      TPIQ13 = 0; QPIQ13 = 0; DPIQ13 = 0;
      IF DISP IN (20) THEN TPIQ13 = 1;
      IF MORT30 THEN DPIQ13 = 1;
      IF PALLIAFG THEN QPIQ13 = 1;

	  *** Exclude Head Trauma;
      IF %MDX1($HTRAUID.) THEN DO;
         TPIQ13 = .; QPIQ13 = .; DPIQ13 = .;
      END;

   END;

   * --- IN-HOSP MORT HIP REPLACEMENT      --- ;

   IF MDC NOTIN (14) AND 
      %MPR($MTHIPRP.) AND %MDX($MTHIPRD.) 
   THEN DO;

      TPIQ14 = 0; QPIQ14 = 0; DPIQ14 = 0;
      IF DISP IN (20) THEN TPIQ14 = 1;
      IF MORT30 THEN DPIQ14 = 1;
      IF PALLIAFG THEN QPIQ14 = 1;

      *** Exclude hip fracture;
      IF %MDX($MTHIPFD.) THEN DO;
         TPIQ14 = .; QPIQ14 = .; DPIQ14 = .;
      END;

   END;

   * --- IN-HOSP MORT AMI                  --- ;

   IF MDC NOTIN (14) AND 
      %MDX1($MRTAMID.) THEN DO;

      TPIQ15 = 0; QPIQ15 = 0; DPIQ15 = 0;
      TPIQ32 = 0; QPIQ32 = 0; DPIQ32 = 0;

      IF DISP IN (20) THEN DO;
         TPIQ15 = 1;
         TPIQ32 = 1;
      END;

      IF MORT30 THEN DO;
         DPIQ15 = 1;
         DPIQ32 = 1;
      END;

      IF PALLIAFG THEN DO;
         QPIQ15 = 1;
         QPIQ32 = 1;
      END;

   END;

   * --- IN-HOSP MORT CHF                  --- ;

   IF MDC NOTIN (14) AND
      %MDX1($MRTCHFD.) 
   THEN DO;

      TPIQ16 = 0; QPIQ16 = 0; DPIQ16 = 0;
      IF DISP IN (20) THEN TPIQ16 = 1;
      IF MORT30 THEN DPIQ16 = 1;
      IF PALLIAFG THEN QPIQ16 = 1;

   END;


    * --- IN-HOSP MORT STROKE               --- ;

   IF MDC NOTIN (14) AND
      ((ICDVER LE 21 AND %MDX1($MRTCVDD.)) OR
       (ICDVER GE 22 AND %MDX1($MRTCV2D.)))
   THEN DO;

      TPIQ17 = 0; QPIQ17 = 0; DPIQ17 = 0;

      IF DISP IN (20) THEN TPIQ17 = 1;
 
      IF MORT30 THEN DPIQ17 = 1;

      IF PALLIAFG THEN QPIQ17 = 1;

      STROKE = 0;
	  IF %MDX1($MRTCV3D.)THEN STROKE = 1;
	  ELSE IF %MDX1($MRTCV4D.)THEN STROKE = 2;

   END;

   * --- IN-HOSP MORT STROKE   (STRATIFICATION)            --- ;
   * --- stratification priority according to prior probability of death ---;

   /* STRATUM 2: INTRACEREBRAL HEMORRHAGIC STROKE */
   IF MDC NOTIN (14) AND %MDX1($MRTCV3D.) THEN DO;

      TPIQ17B = 0; QPIQ17B = 0; DPIQ17B = 0;

      IF DISP IN (20) THEN TPIQ17B = 1;
	  IF MORT30       THEN DPIQ17B = 1;
	  IF PALLIAFG     THEN QPIQ17B = 1;
	  STROKE = 0; 
   END;

   /*  STRATUM 1: SUBARACHNOID HEMORRHAGE  */

   ELSE IF MDC NOTIN (14) AND %MDX1($MRTCV2A.) THEN DO;

      TPIQ17A = 0; QPIQ17A = 0; DPIQ17A = 0;

      IF DISP IN (20) THEN TPIQ17A = 1;
	  IF MORT30       THEN DPIQ17A = 1;
	  IF PALLIAFG     THEN QPIQ17A = 1;
	  STROKE = 0;
    END;

  /* STRATUM 3: ISCHEMIC HEMORRHAGIC STROKE */

   ELSE IF MDC NOTIN (14) AND %MDX1($MRTCV4D.) THEN DO;

      TPIQ17C = 0; QPIQ17C = 0; DPIQ17C = 0;

      IF DISP IN (20) THEN TPIQ17C = 1;
	  IF MORT30       THEN DPIQ17C = 1;
	  IF PALLIAFG     THEN QPIQ17C = 1;
      STROKE = 0;
   END;

   * --- IN-HOSP MORT GI HEMORRHAGE        --- ;

   IF MDC NOTIN (14) AND
      %MDX1($MRTGIHD.) 
   THEN DO;

      TPIQ18 = 0; QPIQ18 = 0; DPIQ18 = 0;
      IF DISP IN (20) THEN TPIQ18 = 1;
      IF MORT30 THEN DPIQ18 = 1;
      IF PALLIAFG THEN QPIQ18 = 1;

   END;

   * --- IN-HOSP MORT HIP FRACTURE         --- ;

   IF MDC NOTIN (14) AND (AGE >= 65) AND
      %MDX1($MTHIPFD.) 
   THEN DO;

      TPIQ19 = 0; QPIQ19 = 0; DPIQ19 = 0;
      IF DISP IN (20) THEN TPIQ19 = 1;
      IF MORT30 THEN DPIQ19 = 1;
      IF PALLIAFG THEN QPIQ19 = 1;

      *** Exclude periprosthetic fracture;
      IF %MDX($MTHIP2D.) THEN DO;
         TPIQ19 = .; QPIQ19 = .; DPIQ19 = .;
      END;

   END;

   * --- IN-HOSP MORT PNEUMONIA            --- ;

   IF MDC NOTIN (14) AND
      %MDX1($MTPNEUD.) 
   THEN DO;

      TPIQ20 = 0; QPIQ20 = 0; DPIQ20 = 0;
      IF DISP IN (20) THEN TPIQ20 = 1;
      IF MORT30 THEN DPIQ20 = 1;
      IF PALLIAFG THEN QPIQ20 = 1;

   END;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT ADDITIONAL PROVIDER LEVEL MORTALITY INDICATORS - ;
 * -------------------------------------------------------------- ;

   * --- IN-HOSP MORTALITY PTCA            --- ;

   IF MDC NOTIN (14) AND (AGE >= 40) AND 
      %MPR($PRPTCAP.) 
   THEN DO;

      TPIQ30 = 0; QPIQ30 = 0; DPIQ30 = 0;
      IF DISP IN (20) THEN TPIQ30 = 1;
      IF MORT30 THEN DPIQ30 = 1;
      IF PALLIAFG THEN QPIQ30 = 1;

   END;

   * --- IN-HOSP MORT CAROTID ENDARTERECTMY--- ;

   IF MDC NOTIN (14) AND 
      %MPR($PRCEATP.) 
   THEN DO;

      TPIQ31 = 0; QPIQ31 = 0; DPIQ31 = 0;
      IF DISP IN (20) THEN TPIQ31 = 1;
       IF MORT30 THEN DPIQ31 = 1;
      IF PALLIAFG THEN QPIQ31 = 1;

   END;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT PROVIDER LEVEL UTILIZATION INDICATORS ---------- ;
 * -------------------------------------------------------------- ;

   * --- CESAREAN SECTION DELIVERY         --- ;

   IF (DRGVER LE 24 AND %MDR($PRBRTHG.)) OR
      (DRGVER GE 25 AND %MDR($PRBRT2G.)) 
   THEN DO;

      TPIQ21 = 0;

      IF (DRGVER LE 24 AND %MDR($PRCSECG.)) OR
         (DRGVER GE 25 AND %MDR($PRCSE2G.)) OR 
         (%MPR($PRCSECP.) AND NOT %MPR($PRCSE2P.)) THEN

         TPIQ21 = 1;

      IF %MDX($PRCSECD.) OR %MPR($PRCSE3P.) THEN

         TPIQ21 = .;

   END;

   * --- VAGINAL BIRTH AFTER C-SECTION     --- ;

   IF ((DRGVER LE 24 AND %MDR($PRBRTHG.))  OR
       (DRGVER GE 25 AND %MDR($PRBRT2G.))) AND
      %MDX($PRVBACD.) 
   THEN DO;

      TPIQ22 = 0;
      TPIQ34 = 0;

   IF (DRGVER LE 24 AND %MDR($PRVAGBG.)) OR
      (DRGVER GE 25 AND %MDR($PRVAG2G.)) 
   THEN DO;

         TPIQ22 = 1;
         TPIQ34 = 1;

      END;

      IF %MDX($PRCSECD.) OR %MPR($PRCSE3P.) THEN

         TPIQ22 = .;

   END;

   * --- LAPAROSCOPIC CHOLECYSTECTOMY      --- ;

   IF MDC NOTIN (14) AND 
      %MPR($PRLAP2P.) AND %MDX($PRLAPOD.) 
   THEN DO;

      TPIQ23 = 0;

      IF %MPR($PRLAPOP.) THEN

         TPIQ23 = 1;

   END;

   * --- INCIDENTAL APPENDECTOMY           --- ;

   IF MDC NOTIN (14) AND (AGE >=65 ) AND 
     %MPR($PRAPP2P.) 
   THEN DO;

      TPIQ24=0;

      IF %MPR($PRAPPNP.) THEN

         TPIQ24 = 1;

      *** Exclude Colectomy or Pelvic Evisceration;

      IF %MPR($PRAPP3P.) THEN

         TPIQ24 = .;

      *** Exclude Cancer adj to Appendix;

      IF %MDX($PRAPPND.) THEN

         TPIQ24 = .;

   END;

   * --- BI-LATERAL CATHETERIZATION        --- ;

   IF MDC NOTIN (14) AND 
      %MPR($PRCAT2P.) AND %MDX($PRCATHD.) 
   THEN DO;

      TPIQ25 = 0;

      IF %MPR($PRCATHP.) AND NOT %MDX($PRCAT2D.) THEN

         TPIQ25 = 1;

   END;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AREA LEVEL UTILIZATION INDICATORS -------------- ;
 * -------------------------------------------------------------- ;

   * --- CORONARY ARTERY BYPASS GRAFT      --- ;

   IF MDC NOTIN (14) AND (AGE >= 40) AND
      %MPR($PRCABGP.) 
   THEN

      TAIQ26 = 1;

   * --- PTCA                              --- ;

   IF MDC NOTIN (14) AND (AGE >= 40) AND 
      %MPR($PRPTCAP.) 
   THEN

      TAIQ27 = 1;

   * --- HYSTERECTOMY                      --- ;

   IF MDC NOTIN (14) AND (SEX=2) AND
      %MPR($PRHYSTP.) 
   THEN DO;

      TAIQ28 = 1;

      * --- EXCLUDE GENITAL CANCER -------------------- ;
      IF %MDX($PRHYS1D.) THEN TAIQ28 = .;

      * --- EXCLUDE PELVIC OR LOWER ABDOMINAL --------- ;
      ELSE IF %MDX($PRHYS2D.) THEN TAIQ28 = .;

   END;

   * --- LAMINECTOMY AND/OR SPINAL FUSION  --- ;

   IF MDC NOTIN (14) AND
      %MPR($PRLAMIP.) 
   THEN

      TAIQ29 = 1;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT ADDIT'L PROVIDER LEVEL UTILIZATION INDICATORS -- ;
 * -------------------------------------------------------------- ;

   IF TPIQ21 NE . AND TPIQ22 EQ . THEN TPIQ33 = TPIQ21;

 * -------------------------------------------------------------- ;
 * --- EXCLUDE CASES WITH MISSING VALUES FOR DISP OR ASOURCE  --- ;
 * -------------------------------------------------------------- ;

 IF (DISP LT 0) THEN DO;
   TPIQ08  = .; QPIQ08   = .; DPIQ08  = .;
   TPIQ09  = .; QPIQ09  = .;  DPIQ09  = .;  
   TPIQ09A = .; QPIQ09A  = .; DPIQ09A = .;  
   TPIQ09B = .; QPIQ09B  = .; DPIQ09B = .;
   TPIQ11  = .; QPIQ11   = .; DPIQ11  = .;
   TPIQ11A = .; QPIQ11A  = .; DPIQ11A = .;  
   TPIQ11B = .; QPIQ11B  = .; DPIQ11B = .;
   TPIQ11C = .; QPIQ11C  = .; DPIQ11C = .;
   TPIQ11D = .; QPIQ11D  = .; DPIQ11D = .;
   TPIQ12  = .; QPIQ12   = .; DPIQ12  = .;
   TPIQ13  = .; QPIQ13   = .; DPIQ13  = .;
   TPIQ14  = .; QPIQ14   = .; DPIQ14  = .;
   TPIQ15  = .; QPIQ15   = .; DPIQ15  = .;
   TPIQ16  = .; QPIQ16   = .; DPIQ16  = .;
   TPIQ17  = .; QPIQ17   = .; DPIQ17  = .;
   TPIQ17A = .; QPIQ17A  = .; DPIQ17A = .;  
   TPIQ17B = .; QPIQ17B  = .; DPIQ17B = .;  
   TPIQ17C = .; QPIQ17C  = .; DPIQ17C = .;  
   TPIQ18  = .; QPIQ18   = .; DPIQ18  = .;
   TPIQ19  = .; QPIQ19   = .; DPIQ19  = .;
   TPIQ20  = .; QPIQ20   = .; DPIQ20  = .;
   TPIQ30  = .; QPIQ30   = .; DPIQ30  = .;
   TPIQ31  = .; QPIQ31   = .; DPIQ31  = .;
   TPIQ32  = .; QPIQ32   = .; DPIQ32  = .;
 END;

 IF (ASOURCE LT 0) AND (POINTOFORIGINUB04 IN (' ')) THEN 
   TPIQ32 = .;

 * -------------------------------------------------------------- ;
 * --- EXCLUDE TRANSFERS ---------------------------------------- ;
 * -------------------------------------------------------------- ;

 * --- TRANSFER FROM ANOTHER ACUTE ---------------- ;
 IF ASOURCE IN (2) OR POINTOFORIGINUB04 IN ('4') THEN DO; 
   TPIQ32 = .;
 END;

 * --- TRANSFER TO ANOTHER ACUTE ------------------ ;
 IF DISP IN (2) THEN DO;
   TPIQ08   = .; QPIQ08  = .; DPIQ08 = .;
   TPIQ09   = .; QPIQ09  = .; DPIQ09  = .;
   TPIQ09A  = .; QPIQ09A = .; DPIQ09A = .;   
   TPIQ09B  = .; QPIQ09B = .; DPIQ09B = .;
   TPIQ11   = .; QPIQ11  = .; DPIQ11  = .;
   TPIQ11A  = .; QPIQ11A = .; DPIQ11A = .;   
   TPIQ11B  = .; QPIQ11B = .; DPIQ11B = .;
   TPIQ11C  = .; QPIQ11C = .; DPIQ11C = .;
   TPIQ11D  = .; QPIQ11D = .; DPIQ11D = .;
   TPIQ12   = .; QPIQ12  = .; DPIQ12  = .;
   TPIQ13   = .; QPIQ13  = .; DPIQ13  = .;
   TPIQ14   = .; QPIQ14  = .; DPIQ14  = .;
   TPIQ15   = .; QPIQ15  = .; DPIQ15  = .;
   TPIQ16   = .; QPIQ16  = .; DPIQ16  = .;
   TPIQ17   = .; QPIQ17 = .;  DPIQ17  = .;
   TPIQ17A  = .; QPIQ17A = .; DPIQ17A = .;  
   TPIQ17B  = .; QPIQ17B = .; DPIQ17B = .;
   TPIQ17C  = .; QPIQ17C = .; DPIQ17C = .;
   TPIQ18   = .; QPIQ18  = .; DPIQ18  = .;
   TPIQ19   = .; QPIQ19  = .; DPIQ19  = .;
   TPIQ20   = .; QPIQ20  = .; DPIQ20  = .;
   TPIQ30   = .; QPIQ30  = .; DPIQ30  = .;
   TPIQ31   = .; QPIQ31  = .; DPIQ31  = .;
   TPIQ32   = .; QPIQ32  = .; DPIQ32  = .;
 END;

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

 * -------------------------------------------------------------- ;
 * --- LABELS --------------------------------------------------- ;
 * -------------------------------------------------------------- ;

 LABEL
    TRNSFER  = 'TRANSFER FROM ACUTE'
    TRNSOUT  = 'TRANSFER TO ACUTE'
    MAXDX    = 'NUMBER OF DX CODES'
    ECDDX    = 'PRESENCE OF ECODES'
    MAXPR    = 'NUMBER OF PR CODES'
    PCTPOA   = 'PERCENT POA'
    NOPOA    = 'NO POA' 
	NOPRDAY  = 'NO PRDAY'
    NOPOUB04 = 'NO POINT OF ORIGIN'
    PALLIAFG = 'PALLIATIVE FLAG'
    WHIPPLE  = 'WHIPPLE PROCEDURE'
    RUPTURED = 'RUPTURED AAA'
    STROKE   = 'STROKE TYPE'
;

RUN;

PROC MEANS DATA=OUT1.&OUTFILE1. N NMISS MIN MAX MEAN SUM;
RUN;

PROC CONTENTS DATA=OUT1.&OUTFILE1. POSITION;
RUN;

PROC PRINT DATA=OUT1.&OUTFILE1.(OBS=24);
TITLE4 "FIRST 24 RECORDS IN OUTPUT DATA SET &OUTFILE1.";
RUN;
