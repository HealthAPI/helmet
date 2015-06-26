*=============================== PROGRAM: PQSAS1.SAS  ===============================;
*====================================================================================;
*  Title:  PROGRAM 1 ASSIGNS AHRQ PREVENTION QUALITY INDICATORS
*          TO INPATIENT RECORDS
*
*  Description:
*          ASSIGNS THE OUTCOME OF INTEREST FLAGS TO INPATIENT
*          RECORDS
*
*                         >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*  USER NOTE1: Make sure you have created format library 
*              (using PQFMTS.SAS) BEFORE running this program.
*
*  USER NOTE2: The AHRQ QI software does not support the calculation of weighted estimates
*              and standard errors using complex sampling designs. Beginning with v5.0, 
*              all references to a discharge weight (DISCWT) have been removed from all 
*              programs. In order to obtain weighted nationally representative estimates,
*              please refer to the technical documentation on the AHRQ QI website.
*========================================================================================;
FILENAME CONTROL 'C:\PATHNAME\CONTROL_PQI.SAS'; *<===USER MUST modify;

%INCLUDE CONTROL;


 TITLE2 'PROGRAM 1';
 TITLE3 'AHRQ PREVENTION QUALITY INDICATORS: ASSIGN QIS TO INPATIENT DATA';

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
 * --- PREVENTION QUALITY INDICATOR (PQI) NAMING CONVENTION:  --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PREVENTION QUALITY     --- ;
 * --- INDICATOR AS ONE OF THE FOLLOWING:
                (O) OBSERVED RATES
                (E) EXPECTED RATES
                (R) RISK-ADJUSTED RATES
                (S) SMOOTHED RATES
                (T) NUMERATOR ("TOP")
                (P) POPULATION ("POP")
 * --- THE SECOND LETTER REFERS TO THE INDICATOR              --- ;
 * --- SUBTYPE, (A)MBULATORY CARE SENSITIVE CONDITION. THE    --- ;
 * --- NEXT TWO CHARACTERS ARE ALWAYS 'PQ'. THE LAST TWO      --- ;
 * --- DIGITS ARE THE INDICATOR NUMBER (WITHIN THAT SUBTYPE). --- ;
 * -------------------------------------------------------------- ;

DATA OUT1.&OUTFILE1.
                 (KEEP=KEY FIPST FIPSTCO DRG DRGVER MDC YEAR DQTR 
                       AGECAT AGECCAT POPCAT SEXCAT RACECAT DUALCAT
                       TAPQ01--TAPQ16 TAPQ90-TAPQ92);
					  
 SET IN0.&INFILE0.
                 (KEEP=KEY DRG DRGVER MDC SEX AGE AGEDAY PSTCO 
                       RACE YEAR DQTR PAY1 PAY2 
                       ASOURCE POINTOFORIGINUB04 ATYPE 
                       DX1-DX&NDX. PR1-PR&NPR.);

 * -------------------------------------------------------------- ;
 * --- DIAGNOSIS AND PROCEDURE MACROS --------------------------- ;
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

 %MACRO MDX2(FMT);

 (%DO I = 2 %TO &NDX.-1;
  (PUT(DX&I.,&FMT.) = '1') OR
  %END;
  (PUT(DX&NDX.,&FMT.) = '1'))

 %MEND;

 %MACRO MPR(FMT);

 (%DO I = 1 %TO &NPR.-1;
  (PUT(PR&I.,&FMT.) = '1') OR
  %END;
  (PUT(PR&NPR.,&FMT.) = '1'))

 %MEND;

 * -------------------------------------------------------------- ;
 * --- DEFINE MDC                        ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB MDCNEW LENGTH=3
   LABEL='IMPUTED MDC';

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
 IF DX1 IN (' ') THEN DELETE;
 IF DQTR LE .Z THEN DELETE;
 IF YEAR LE .Z THEN DELETE;
 
 * -------------------------------------------------------------- ;
 * --- DEFINE ICD-9-CM VERSION           ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB ICDVER LENGTH=3
   LABEL='ICD-9-CM VERSION';

 ICDVER = 0;
 IF      (YEAR IN (1994) AND DQTR IN (4))     THEN ICDVER = 12;
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
 * --- DEFINE FIPS STATE AND COUNTY CODES             ----------- ;
 * -------------------------------------------------------------- ;
 ATTRIB FIPSTCO LENGTH=$5
   LABEL='FIPS STATE COUNTY CODE';
 FIPSTCO = PUT(PSTCO,Z5.);

 ATTRIB FIPST LENGTH=$2
   LABEL='STATE FIPS CODE';
 FIPST = SUBSTR(FIPSTCO,1,2);


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
 * --- DEFINE STRATIFIER: CONDITION SPECIFIC AGE CATEGORY  ------ ;
 * -------------------------------------------------------------- ;
 ATTRIB AGECCAT LENGTH=3
   LABEL='PATIENT AGE';

 SELECT;
   WHEN (      AGE < 18)  AGECCAT = 0;
   WHEN (18 <= AGE < 45)  AGECCAT = 1;
   WHEN (45 <= AGE < 65)  AGECCAT = 2;
   WHEN (65 <= AGE < 75)  AGECCAT = 3;
   WHEN (75 <= AGE     )  AGECCAT = 4;
   OTHERWISE AGECCAT = 0;
 END; * SELECT CONDITION SPECIFIC AGE;


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
 * --- DEFINE AREA LEVEL ACSC INDICATORS ------------------------ ;
 * -------------------------------------------------------------- ;

 LENGTH TAPQ01 TAPQ02 TAPQ03 TAPQ05
        TAPQ07 TAPQ08 TAPQ10 TAPQ11 
        TAPQ12 TAPQ13 TAPQ14 TAPQ15
        TAPQ16 TAPQ90 TAPQ91 TAPQ92 8;

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

 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AREA LEVEL ACSC INDICATORS --------------------- ;
 * -------------------------------------------------------------- ;

   * --- DIABETES SHORT TERM COMPLICATION  --- ;

   IF %MDX1($ACDIASD.) THEN

        TAPQ01 = 1;


   * --- PERFORATED APPENDIX               --- ;

   IF %MDX($ACSAP2D.) THEN DO;

      TAPQ02 = 0;

      IF %MDX($ACSAPPD.) THEN TAPQ02 = 1;

      *** Exclude: MDC 14;
      IF MDC IN (14) THEN TAPQ02 = .;

   END;


   * --- DIABETES LONG TERM COMPLICATION   --- ;

   IF %MDX1($ACDIALD.) THEN

        TAPQ03 = 1;


   * --- COPD                              --- ;

   IF AGE GE 40 THEN DO;
     IF %MDX1($ACCOPDD.)   OR 
        (%MDX1($ACCPD2D.) AND %MDX2($ACCOPDD.))  OR
        %MDX1($ACSASTD.) 

        THEN DO;  TAPQ05 = 1;
    
   *** Exclude Cystic Fibrosis and Anomalies 
          of the Respiratory System;

      IF %MDX($RESPAN.) THEN TAPQ05 = .;
     END;

   END;

   * --- HYPERTENSION                      --- ;

   IF %MDX1($ACSHYPD.) THEN DO;

        TAPQ07 = 1;

      ***Exclude Stage I-IV Kidney Disease
         with dialysis access procedures;
      IF %MDX($ACSHY2D.) AND %MPR($ACSHYPP.)
      THEN TAPQ07 = .;

      *** Exclude Cardiac Procedures;
      IF %MPR($ACSCARP.) THEN TAPQ07 = .;

   END;


   * --- CONGESTIVE HEART FAILURE          --- ;
***----------------------------------------------------
   IF (ICDVER LE 19 AND %MDX1($ACSCHFD.)) OR
      (ICDVER GE 20 AND %MDX1($ACSCH2D.)) 
 *************************************************;

   IF %MDX1($ACSCHFD.) THEN DO;

      TAPQ08 = 1;

      *** Exclude Cardiac Procedures;
      IF %MPR($ACSCARP.) THEN TAPQ08 = .;

   END;

   * --- DEHYDRATION                       --- ;

   IF %MDX1($ACSDEHD.) OR  
      (%MDX2($ACSDEHD.) AND (%MDX1($HYPERID.) OR %MDX1($ACPGASD.) OR %MDX1($PHYSIDB.))) 
       THEN DO;       TAPQ10 = 1;

         *** Exclude chronic renal failure ****;
         IF %MDX($CRENLFD.) THEN TAPQ10 = .;

   END;

   * --- BACTERIAL PNEUMONIA               --- ;

   IF %MDX1($ACSBACD.) THEN DO;

      TAPQ11 = 1;

      *** Exclude: Sickle Cell;
      IF %MDX($ACSBA2D.)  THEN TAPQ11 = .;

      *** Exclude Immunocompromised state;
      IF %MDX($IMMUNID.) OR %MPR($IMMUNIP.) 
      THEN TAPQ11 = .;

   END;
      

   * --- URINARY INFECTION                 --- ;

   IF  %MDX1($ACSUTID.) THEN DO;

      TAPQ12 = 1;

      *** Exclude Immunocompromised state and 
          Kidney/Urinary Tract Disorder;
      IF %MDX($IMMUNID.) OR %MPR($IMMUNIP.) OR 
         %MDX($KIDNEY.) 
      THEN TAPQ12 = .;

   END;

   * --- ANGINA                            --- ;

   IF %MDX1($ACSANGD.) THEN DO;

      TAPQ13 = 1;

      *** Exclude Cardiac Procedures;
      IF %MPR($ACSCARP.) THEN TAPQ13 = .;

   END;


   * --- DIABETES UNCONTROLLED             --- ;

   IF %MDX1($ACDIAUD.) THEN

      TAPQ14 = 1;


   * --- ADULT ASTHMA                      --- ;


   IF %MDX1($ACSASTD.) THEN DO;

      TAPQ15 = 1;

      *** Exclude Cystic Fibrosis and Anomalies 
          of the Respiratory System;
      IF %MDX($RESPAN.) THEN TAPQ15 = .;

      IF AGE GE 40 THEN TAPQ15 = .;

   END;


   * --- LOWER EXTREMITY AMPUTATION       --- ;

   IF %MPR($ACSLEAP.) AND %MDX($ACSLEAD.) THEN DO;

      TAPQ16 = 1;

      *** Exclude: MDC 14;
      IF MDC IN (14) THEN TAPQ16 = .;

      *** Exclude: Trauma;
      IF %MDX($ACLEA2D.) THEN TAPQ16 = .;

      *** Exclude: TOE AMPUTATION PROCEDURE;
      IF %MPR($TOEAMIP.) THEN TAPQ16 = .;

   END;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AREA LEVEL COMPOSITE INDICATORS ---------------- ;
 * -------------------------------------------------------------- ;

   * --- OVERALL                          --- ;

   IF TAPQ01 = 1 OR TAPQ03 = 1 OR TAPQ05 = 1 OR TAPQ07 = 1 OR
      TAPQ08 = 1 OR TAPQ10 = 1 OR TAPQ11 = 1 OR TAPQ12 = 1 OR
      TAPQ13 = 1 OR TAPQ14 = 1 OR TAPQ15 = 1 OR TAPQ16 = 1
   THEN 
   TAPQ90 = MAX(OF TAPQ01 TAPQ03 TAPQ05 TAPQ07 
                   TAPQ08 TAPQ10 TAPQ11 TAPQ12
                   TAPQ13 TAPQ14 TAPQ15 TAPQ16);

   * --- ACUTE                            --- ;

   IF TAPQ10 = 1 OR TAPQ11 = 1 OR TAPQ12 = 1 
   THEN 
   TAPQ91 = MAX(OF TAPQ10 TAPQ11 TAPQ12);

   * --- CHRONIC                          --- ;

   IF TAPQ01 = 1 OR TAPQ03 = 1 OR TAPQ05 = 1 OR TAPQ07 = 1 OR
      TAPQ08 = 1 OR TAPQ13 = 1 OR TAPQ14 = 1 OR TAPQ15 = 1 OR
      TAPQ16 = 1
   THEN 
   TAPQ92 = MAX(OF TAPQ01 TAPQ03 TAPQ05 TAPQ07 
                   TAPQ08 TAPQ13 TAPQ14 TAPQ15
                   TAPQ16);

 * -------------------------------------------------------------- ;
 * --- EXCLUDE TRANSFERS ---------------------------------------- ;
 * -------------------------------------------------------------- ;

 * --- TRANSFER FROM ANOTHER ---------------- ;
 IF ASOURCE IN (2,3) OR POINTOFORIGINUB04 IN ('4','5','6')
 THEN DO;
   TAPQ01 = .;
   TAPQ02 = .;
   TAPQ03 = .;
   TAPQ05 = .;
   TAPQ07 = .;
   TAPQ08 = .;
   TAPQ10 = .;
   TAPQ11 = .;
   TAPQ12 = .;
   TAPQ13 = .;
   TAPQ14 = .;
   TAPQ15 = .;
   TAPQ16 = .;
   TAPQ90 = .;
   TAPQ91 = .;
   TAPQ92 = .;
 END;

RUN;

PROC CONTENTS DATA=OUT1.&OUTFILE1. POSITION;
RUN;

***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS MIN MAX NOLABELS ;
	 VAR KEY DRG DRGVER MDC YEAR DQTR 
         AGECAT AGECCAT POPCAT SEXCAT RACECAT DUALCAT;
     TITLE4 "CATEGORICAL VARIABLES AND RANGES OF VALUES";
RUN; QUIT;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM MEAN NOLABELS ;
     VAR TAPQ01-TAPQ03 TAPQ05 TAPQ07-TAPQ08 TAPQ10-TAPQ16 TAPQ90-TAPQ92;
     TITLE "PATIENT QUALITY AREA-LEVEL INDICATOR NUMERATORS FOR AREA-BASED OR COUNT BASED INDICATORS (COUNT =SUM)";
RUN; QUIT;
