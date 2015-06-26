*======================================================================================;
*  Title:  PROGRAM 1 ASSIGN AHRQ PEDIATRIC QUALITY INDICATORS
*          TO INPATIENT RECORDS
*
*  Description:
*         ASSIGNS THE OUTCOME OF INTEREST AND POPULATION AT RISK
*         INDICATORS TO INPATIENT RECORDS. 
*
*              >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*  USER NOTE1: Make sure you have created the format library
*              using PDFMTS.SAS BEFORE running this program.
* 
*  USER NOTE2: Since version 4.5, AHRQ QI SAS software does not explicitly support
*              the calculation of weighted estimates and standard errors using complex
*              sampling designs. References to the variable DISCWT have been removed 
*              from the QI SAS software.
*
*              In order to obtain weighted nationally representative estimates, 
*              additional calculations will need to be performed.  
*              For a more thorough description of weighted AHRQ QI analyses beginning
*              with AHRQ QI SAS Version 4.1, see the technical documentation on the 
*              AHRQ QI website.
*========================================================================================;

FILENAME CONTROL "C:\PATHNAME\CONTROL_PDI.SAS"; *<==USER MUST modify;

%INCLUDE CONTROL;

 TITLE2 'PROGRAM 1';
 TITLE3 'AHRQ PEDIATRIC QUALITY INDICATORS: ASSIGN PDIS TO INPATIENT DATA';

 * -------------------------------------------------------------- ;
 * --- CREATE A PERMANENT DATASET CONTAINING ALL RECORDS THAT --- ; 
 * --- WILL NOT BE INCLUDED IN ANALYSIS BECAUSE KEY VARIABLE  --- ;
 * --- VALUES ARE MISSING				      --- ;
 * -------------------------------------------------------------- ;

 DATA   OUT1.&DELFILE1.
 	(KEEP=KEY HOSPID SEX AGE DX1 MDC YEAR DQTR);
 SET 	IN0.&INFILE0.;
 IF (AGE LT 0) OR (AGE GE 18 OR MDC IN (14)) OR (SEX LE 0) OR 
	(DX1 IN (' ')) OR (DQTR LE .Z) OR (YEAR LE .Z);
 RUN;

 * -------------------------------------------------------------- ;
 * --- PEDIATRIC QUALITY INDICATOR (PDI) NAMING CONVENTION:   --- ;
 * --- THE FIRST LETTER IDENTIFIES THE PEDIATRIC INDICATOR    --- ;
 * --- AS ONE OF THE FOLLOWING:
                (O) OBSERVED RATES
                (E) EXPECTED RATES
                (R) RISK-ADJUSTED RATES
                (S) SMOOTHED RATES
                (T) NUMERATOR ("TOP")
                (P) POPULATION ("POP")
 * --- THE SECOND LETTER IDENTIFIES THE PDI AS A PROVIDER (P) --- ;
 * --- OR AN AREA (A) LEVEL INDICATOR.  THE NEXT TWO          --- ;
 * --- CHARACTERS ARE ALWAYS 'PD'. THE LAST TWO DIGITS ARE    --- ;
 * --- THE INDICATOR NUMBER (WITHIN THAT SUBTYPE).            --- ;
 * -------------------------------------------------------------- ;

 %MACRO ADDPRDAY; 
    %IF &PRDAY EQ 1 %THEN PRDAY1-PRDAY&NPR. ;
 %MEND;

 DATA   OUT1.&OUTFILE1. 
    (KEEP=KEY HOSPID FIPST FIPSTCO DRG DRGVER MDC MDRG YEAR DQTR 
          PAGECAT AGEDCAT POPCAT BWHTCAT SEXCAT CONGCAT RACECAT PAYCAT DUALCAT
          LOS TRNSFER MAXPR NOPOA PALLIAFG
          NOPOUB04 NOPRDAY TRNSOUT  
          TPPD01--TPPD13 TPPS17 QPPD01--QPPD13  
          TPNQ01--TPNQ03 QPNQ01--QPNQ03 
          TAPD14--TAPD18 TAPD90--TAPD92 TAPQ09 
          GPPD01 GPPD02 GPPD08 GPPD10 GPPD11 GPPD12
          HPPD01 HPPD06 HPPD10 MULTIBTH MDX4D STRCABN MULTIPLE
          CCS4   CCS6   CCS21  CCS33  CCS35  CCS38  CCS39  CCS41  CCS42  CCS48
          CCS51  CCS52  CCS56  CCS57  CCS58  CCS62  CCS63  CCS654  CCS661  CCS81
          CCS82  CCS83  CCS85  CCS95  CCS96  CCS98  CCS103 CCS105 CCS106 CCS108
          CCS133 CCS138 CCS151 CCS158 CCS161 CCS210 CCS211 CCS213 CCS214 CCS215
          CCS216 CCS217 CCS219 CCS221 CCS224 CCS227 
          XCS4   XCS6   XCS21  XCS33  XCS35  XCS38  XCS39  XCS41  XCS42  XCS48
          XCS51  XCS52  XCS56  XCS57  XCS58  XCS62  XCS63  XCS654  XCS661  XCS81
          XCS82  XCS83  XCS85  XCS95  XCS96  XCS98  XCS103 XCS105 XCS106 XCS108
          XCS133 XCS138 XCS151 XCS158 XCS161 XCS210 XCS211 XCS213 XCS214 XCS215
          XCS216 XCS217 XCS219 XCS221 XCS224 XCS227 );
 SET   IN0.&INFILE0. 
      (KEEP=KEY HOSPID DRG DRGVER MDC SEX AGE AGEDAY PSTCO 
            RACE YEAR DQTR PAY1 PAY2 DNR
            DISP LOS ASOURCE POINTOFORIGINUB04 ATYPE
            DX1-DX&NDX. PR1-PR&NPR. %ADDPRDAY 
            DXPOA1-DXPOA&NDX.);

 %MACRO SETPOA ;
     %*-------------------------------*;
     %* ASSIGN NOPOA AT THE FILE LEVEL*;
     %* BASED ON CONTROL FILE MACRO.  *;
     %*-------------------------------*;
    %IF &USEPOA.=1 %THEN %DO ;
      NOPOA=0 ;
    %END ;
    %ELSE %IF &USEPOA.=0 %THEN %DO ;
      NOPOA=1 ; 
    %END ; 
 %MEND ; 

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
       IF(PUT(PR&I.,$ORPROC.) = '1') THEN ORCNT + 1;
    %END;

%MEND;

%MACRO ORDAY(FMT);

    ORDAY = .;
    %DO I = 1 %TO &NPR.;
       IF ((PUT(PR&I.,$ORPROC.) = '1')) AND
          PUT(PR&I.,&FMT.)    = '0' THEN DO;
          IF PRDAY&I. GT .Z THEN DO;
             IF ORDAY = . THEN ORDAY = PRDAY&I;
             ELSE IF ORDAY > PRDAY&I. THEN ORDAY = PRDAY&I;
          END;
       END;
    %END;

%MEND;

%MACRO PRCLASS;

    PRCLS1 = 0; PRCLS2 = 0; PRCLS3 = 0; PRCLS4 = 0; 
    PRCIDX = 0;

    %DO I = 1 %TO &NPR.;
       PRCIDX = PUT(PR&I.,$PRCLASS.);
	 IF PR&I. IN ('640') AND 0 <= AGEDAY <= 28 THEN PRCLS2 + 1;
       ELSE IF PRCIDX = 1 THEN PRCLS1 + 1;
       ELSE IF PRCIDX = 2 THEN PRCLS2 + 1;
       ELSE IF PRCIDX = 3 THEN PRCLS3 + 1;
       ELSE IF PRCIDX = 4 THEN PRCLS4 + 1;
    %END;

%MEND;


%MACRO CCS;

   %DO I = 2 %TO &NDX.;
      CCSIDX = 0;
      IF DX&I. NE ' ' AND (POAFG = 0 OR DXPOA&I. IN ('Y','W','E','1'))
      THEN CCSIDX = PUT(DX&I.,$CCS.);
      IF CCSIDX > 0 THEN DO;
         DO J = 1 TO 46;
            IF CCSARRY1(J) = CCSIDX THEN CCSARRY2(J) = 1;
         END;
      END;
   %END;

%MEND;

%MACRO PRPDCNT1;

    MPR1P = 0; MDX2D = 0; MDX3D = 0; MDX4D = 0; MDX5D = 0; 

    %DO I = 1 %TO &NPR.;
       IF PUT(PR&I.,$PRPED1P.) = '1' THEN MPR1P + 1;
    %END;

    %DO I = 1 %TO &NDX.;
       IF PUT(DX&I.,$PRPED2D.) = '1' THEN MDX2D + 1;
       IF PUT(DX&I.,$PRPED3D.) = '1' THEN MDX3D + 1;
       IF PUT(DX&I.,$PRPED4D.) = '1' THEN MDX4D + 1;
       IF PUT(DX&I.,$PRPED5D.) = '1' THEN MDX5D + 1;
    %END;

 %MEND;

 %MACRO PRPDCNT2;

    MPR3AP = 0; MPR3BP = 0; MPR3CP = 0; MPR3DP = 0; 
    MPR3EP = 0; MPR3FP = 0; MPR4P = 0;  MPR5P = 0;  
    MPR6P = 0;  MPR7P = 0;

    %DO I = 1 %TO &NPR.;
       IF (MPR1P > 0 OR MDX2D > 0) AND PUT(PR&I.,$PRPED2P.) = '1' 
       THEN MPR1P + 1;
       IF PUT(PR&I.,$PRPD3AP.) = '1' 
       THEN MPR3AP + 1;
       IF PUT(PR&I.,$PRPD3BP.) = '1' 
       THEN MPR3BP + 1;
       IF PUT(PR&I.,$PRPD3CP.) = '1' 
       THEN MPR3CP + 1;
       IF PUT(PR&I.,$PRPD3DP.) = '1' 
       THEN MPR3DP + 1;
       IF PUT(PR&I.,$PRPD3EP.) = '1' 
       THEN MPR3EP + 1;
       IF PUT(PR&I.,$PRPD3FP.) = '1' 
       THEN MPR3FP + 1;
       IF PUT(PR&I.,$PRPED4P.) = '1' 
       THEN MPR4P + 1;      
       IF PUT(PR&I.,$PRPED5P.) = '1' 
       THEN MPR5P + 1;      
       IF PUT(PR&I.,$PRPED6P.) = '1' 
       THEN MPR6P + 1;
       IF PUT(PR&I.,$PRPED7P.) = '1' 
       THEN MPR7P + 1;
   %END;

%MEND;

 * -------------------------------------------------------------- ;
 * --- DEFINE MDC                        ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB MDCNEW LENGTH=3
   LABEL='IMPUTED MDC';

 IF DRGVER LE .Z THEN DO;
    IF      (YEAR IN (1994) AND DQTR IN (4))     THEN DRGVER = 12;
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
 * --- DELETE NON-PEDIATRIC RECORDS AND RECORDS W MISSING VALUES  ;
 * -------------------------------------------------------------- ;
 IF SEX LE 0 THEN DELETE;
 IF AGE LT 0 THEN DELETE;
 IF AGE GE 18 OR MDC IN (14) THEN DELETE;
 IF DX1 IN (' ') THEN DELETE;
 IF DQTR LE .Z THEN DELETE;
 IF YEAR LE .Z THEN DELETE;



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
 ELSE IF (YEAR IN (2009) AND DQTR IN (4)) 	  THEN ICDVER = 27;
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
 * --- DEFINE INFECTION RISK CATEGORIES  ------------------------ ;
 * -------------------------------------------------------------- ;
 ATTRIB DRG1C LENGTH=3
   LABEL='CLEAN';
 ATTRIB DRG2C LENGTH=3
   LABEL='CLEAN CONTAMINATED';
 ATTRIB DRG3C LENGTH=3
   LABEL='POTENTIALLY CONTAMINATED';
 ATTRIB DRG4C LENGTH=3
   LABEL='LIKELY INFECTED';
 ATTRIB DRG9C LENGTH=3
   LABEL='SURGICAL PROCEDURES NOT SPECIFIED';

 DRG1C = PUT(MDRG,DRG1C.);
 DRG2C = PUT(MDRG,DRG2C.);
 DRG3C = PUT(MDRG,DRG3C.);
 DRG4C = PUT(MDRG,DRG4C.);
 DRG9C = PUT(MDRG,DRG9C.);


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
 ATTRIB PAGECAT LENGTH=3
   LABEL='PATIENT AGE';

 SELECT;
   WHEN (0  <= AGE <  1)  PAGECAT = 1;
   WHEN (1  <= AGE <  3)  PAGECAT = 2;
   WHEN (3  <= AGE <  6)  PAGECAT = 3;
   WHEN (6  <= AGE < 13)  PAGECAT = 4;
   WHEN (13 <= AGE < 18)  PAGECAT = 5;
   OTHERWISE PAGECAT = 0;
 END; * SELECT AGE ;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: AGEDAY CATEGORY  ---------------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB AGEDCAT LENGTH=3
   LABEL='PATIENT AGE IN DAYS';

 SELECT;
   WHEN (      AGEDAY <   0)  AGEDCAT = 0;
   WHEN (0  <= AGEDAY <= 28)  AGEDCAT = 1;
   WHEN (29 <= AGEDAY <= 60)  AGEDCAT = 2;
   WHEN (61 <= AGEDAY <= 90)  AGEDCAT = 3;
   WHEN (91 <= AGEDAY      )  AGEDCAT = 4;
   OTHERWISE AGEDCAT = 0;
 END; * SELECT AGEDAY ;


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
 * --- DEFINE STRATIFIER: BIRTH WEIGHT CATEGORY  ---------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB BWHTCAT LENGTH=3
   LABEL='PATIENT BIRTHWEIGHT';

 %MACRO BWHT;

 BWHTCAT = 0;
 %DO I = 1 %TO &NDX.;
    IF PUT(DX&I.,$LW500G.)  = '1'      THEN BWHTCAT = 1;
    ELSE IF PUT(DX&I.,$LW750G.)  = '1' AND (BWHTCAT = 0 OR  BWHTCAT > 2) THEN BWHTCAT = 2;
    ELSE IF PUT(DX&I.,$LW1000G.) = '1' AND (BWHTCAT = 0 OR  BWHTCAT > 3) THEN BWHTCAT = 3;
    ELSE IF PUT(DX&I.,$LW1250G.) = '1' AND (BWHTCAT = 0 OR  BWHTCAT > 4) THEN BWHTCAT = 4;
    ELSE IF PUT(DX&I.,$LW1500G.) = '1' AND (BWHTCAT = 0 OR  BWHTCAT > 5) THEN BWHTCAT = 5;
    ELSE IF PUT(DX&I.,$LW1750G.) = '1' AND (BWHTCAT = 0 OR  BWHTCAT > 6) THEN BWHTCAT = 6;
    ELSE IF PUT(DX&I.,$LW2000G.) = '1' AND (BWHTCAT = 0 OR  BWHTCAT > 7) THEN BWHTCAT = 7;
    ELSE IF PUT(DX&I.,$LW2500G.) = '1' AND (BWHTCAT = 0 OR  BWHTCAT > 8) THEN BWHTCAT = 8;
    ELSE IF PUT(DX&I.,$LW2500P.) = '1' AND (BWHTCAT = 0) THEN BWHTCAT = 9;
 %END;
 
 %MEND;

 %BWHT;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: GESTATIONAL AGE CATEGORY -------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB GESTCAT LENGTH=3
   LABEL='PATIENT GESTATIONAL AGE';

 %MACRO GEST;

 GESTCAT = 0;
 %DO I = 1 %TO &NDX.;
    IF PUT(DX&I.,$GESTC1D.)  = '1'     THEN GESTCAT = 1;
    ELSE IF PUT(DX&I.,$GESTC2D.) = '1' AND (GESTCAT = 0 OR GESTCAT > 2) THEN GESTCAT = 2;
    ELSE IF PUT(DX&I.,$GESTC3D.) = '1' AND (GESTCAT = 0 OR GESTCAT > 3) THEN GESTCAT = 3;
    ELSE IF PUT(DX&I.,$GESTC4D.) = '1' AND (GESTCAT = 0 OR GESTCAT > 4) THEN GESTCAT = 4;
    ELSE IF PUT(DX&I.,$GESTC5D.) = '1' AND (GESTCAT = 0 OR GESTCAT > 5) THEN GESTCAT = 5;
    ELSE IF PUT(DX&I.,$GESTC6D.) = '1' AND (GESTCAT = 0 OR GESTCAT > 6) THEN GESTCAT = 6;
    ELSE IF PUT(DX&I.,$GESTC7D.) = '1' AND (GESTCAT = 0 OR GESTCAT > 7) THEN GESTCAT = 7;
    ELSE IF PUT(DX&I.,$GESTC8D.) = '1' AND (GESTCAT = 0 OR GESTCAT > 8) THEN GESTCAT = 8;
    ELSE IF PUT(DX&I.,$GESTC9D.) = '1' AND (GESTCAT = 0) THEN GESTCAT = 9;
 %END;
 
 %MEND;

 %GEST;


 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIER: CONGENITAL ANAMOLY     ---------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB CONGCAT LENGTH=3
   LABEL='CONGENITAL ANAMOLY';

%MACRO CONG;
CONGCAT = 0;
%DO I = 1 %TO &NDX.;
    IF PUT(DX&I.,$CONGN1D.)  = '1'     THEN CONGCAT = 1;
    ELSE IF PUT(DX&I.,$CONGN2D.) = '1' AND (CONGCAT = 0 OR CONGCAT > 2) THEN CONGCAT = 2;
    ELSE IF PUT(DX&I.,$CONGN3D.) = '1' AND (CONGCAT = 0 OR CONGCAT > 3) THEN CONGCAT = 3;
    ELSE IF PUT(DX&I.,$CONGN4D.) = '1' AND (CONGCAT = 0 OR CONGCAT > 4) THEN CONGCAT = 4;
    ELSE IF PUT(DX&I.,$CONGN5D.) = '1' AND (CONGCAT = 0 OR CONGCAT > 5) THEN CONGCAT = 5;
    ELSE IF PUT(DX&I.,$CONGN6D.) = '1' AND (CONGCAT = 0 OR CONGCAT > 6) THEN CONGCAT = 6;
    ELSE IF PUT(DX&I.,$CONGN7D.) = '1' AND (CONGCAT = 0 OR CONGCAT > 7) THEN CONGCAT = 7;
    ELSE IF PUT(DX&I.,$CONGN8D.) = '1' AND (CONGCAT = 0) THEN CONGCAT = 8;
%END;

%MEND;

%CONG;


 ATTRIB MULTIBTH LENGTH=3
   LABEL='MULTIPLE BIRTHS';

 MULTIBTH=%MDX($MULTIPD.);


 * -------------------------------------------------------------- ;
 * --- COUNT OR PROCEDURES AND IDENTIFY FIRST OR PROCEDURE ------ ;
 * -------------------------------------------------------------- ;
 ATTRIB ORCNT LENGTH=8
   LABEL='OR PROCEDURE COUNT';

 ATTRIB ORDAY LENGTH=8
   LABEL='OR PROCEDURE DAY';

 %ORCNT;


 * -------------------------------------------------------------- ;
 * --- DEFINE PROCEDURE TYPE ------------------------------------ ;
 * -------------------------------------------------------------- ;

 %PRCLASS;


 * -------------------------------------------------------------- ;
 * --- DEFINE CCS ----------------------------------------------- ;
 * -------------------------------------------------------------- ;

 ARRAY CCSARRY1{46} _temporary_ (
   4   6  21  33  35  38  39  41  42  48
  51  52  56  57  58  62  63  65  67  81
  82  83  85  95  96  98 103 105 106 108
 133 138 151 158 161 210 211 213 214 215
 216 217 219 221 224 227
 );

 ARRAY CCSARRY2{46} 
    CCS4   CCS6   CCS21  CCS33  CCS35  CCS38  CCS39  CCS41  CCS42  CCS48
    CCS51  CCS52  CCS56  CCS57  CCS58  CCS62  CCS63  CCS654  CCS661  CCS81
    CCS82  CCS83  CCS85  CCS95  CCS96  CCS98  CCS103 CCS105 CCS106 CCS108
    CCS133 CCS138 CCS151 CCS158 CCS161 CCS210 CCS211 CCS213 CCS214 CCS215
    CCS216 CCS217 CCS219 CCS221 CCS224 CCS227
 ;

 ARRAY CCSARRY3{46} 
    XCS4   XCS6   XCS21  XCS33  XCS35  XCS38  XCS39  XCS41  XCS42  XCS48
    XCS51  XCS52  XCS56  XCS57  XCS58  XCS62  XCS63  XCS654  XCS661  XCS81
    XCS82  XCS83  XCS85  XCS95  XCS96  XCS98  XCS103 XCS105 XCS106 XCS108
    XCS133 XCS138 XCS151 XCS158 XCS161 XCS210 XCS211 XCS213 XCS214 XCS215
    XCS216 XCS217 XCS219 XCS221 XCS224 XCS227
 ;

 DO J = 1 TO 46;
    CCSARRY2(J) = 0;
    CCSARRY3(J) = .;
 END;

 IF NOPOA = 0 THEN DO;
    POAFG = 1;
    %CCS;
    DO I = 1 TO 46;
       CCSARRY3(I) = CCSARRY2(I);
    END;
 END;
 POAFG = 0;
 %CCS;

 LABEL
    CCS4 = "Mycoses"   
    CCS6 = "Hepatitis"   
    CCS21 = "Cancer of bone and connective tissue"  
    CCS33 = "Cancer of kidney and renal pelvis"  
    CCS35 = "Cancer of brain and nervous system"  
    CCS38 = "Non-Hodgkins lymphoma"  
    CCS39 = "Leukemias"  
    CCS41 = "Cancer, other and unspecified primary"  
    CCS42 = "Secondary malignancies"  
    CCS48 = "Thyroid disorders"
    CCS51 = "Other endocrine disorders"  
    CCS52 = "Nutritional deficiencies"  
    CCS56 = "Cystic fibrosis"  
    CCS57 = "Immunity disorders"  
    CCS58 = "Other nutritional, endocrine, and metabolic disorders"  
    CCS62 = "Coagulation and hemorrhagic disorders"  
    CCS63 = "Diseases of white blood cells"  
    CCS654 = "Mental retardation"  
    CCS661 = "Substance-related mental disorders"  
    CCS81 = "Other hereditary and degenerative nervous system conditions"
    CCS82 = "Paralysis"  
    CCS83 = "Epilepsy, convulsions"  
    CCS85 = "Coma, stupor, and brain damage"  
    CCS95 = "Other nervous system disorders"  
    CCS96 = "Heart valve disorders"  
    CCS98 = "Essential hypertension"  
    CCS103 = "Pulmonary heart disease" 
    CCS105 = "Conduction disorders" 
    CCS106 = "Cardiac dysrhythmias" 
    CCS108 = "Congestive heart failure, nonhypertensive"
    CCS133 = "Other lower respiratory disease" 
    CCS138 = "Esophageal disorders" 
    CCS151 = "Other liver diseases" 
    CCS158 = "Chronic renal failure" 
    CCS161 = "Other diseases of kidney and ureters" 
    CCS210 = "Systemic lupus erythematosus and connective tissue disorders" 
    CCS211 = "Other connective tissue disease" 
    CCS213 = "Cardiac and circulatory congenital anomalies" 
    CCS214 = "Digestive congenital anomalies" 
    CCS215 = "Genitourinary congenital anomalies"
    CCS216 = "Nervous system congenital anomalies" 
    CCS217 = "Other congenital anomalies" 
    CCS219 = "Short gestation, low birth weight, and fetal growth retardation" 
    CCS221 = "Respiratory distress syndrome" 
    CCS224 = "Other perinatal conditions" 
    CCS227 = "Spinal cord injury"
 ;

 LABEL
    XCS4 = "Mycoses"   
    XCS6 = "Hepatitis"   
    XCS21 = "Cancer of bone and connective tissue"  
    XCS33 = "Cancer of kidney and renal pelvis"  
    XCS35 = "Cancer of brain and nervous system"  
    XCS38 = "Non-Hodgkins lymphoma"  
    XCS39 = "Leukemias"  
    XCS41 = "Cancer, other and unspecified primary"  
    XCS42 = "Secondary malignancies"  
    XCS48 = "Thyroid disorders"
    XCS51 = "Other endocrine disorders"  
    XCS52 = "Nutritional deficiencies"  
    XCS56 = "Cystic fibrosis"  
    XCS57 = "Immunity disorders"  
    XCS58 = "Other nutritional, endocrine, and metabolic disorders"  
    XCS62 = "Coagulation and hemorrhagic disorders"  
    XCS63 = "Diseases of white blood cells"  
    XCS654 = "Mental retardation"  
    XCS661 = "Substance-related mental disorders"  
    XCS81 = "Other hereditary and degenerative nervous system conditions"
    XCS82 = "Paralysis"  
    XCS83 = "Epilepsy, convulsions"  
    XCS85 = "Coma, stupor, and brain damage"  
    XCS95 = "Other nervous system disorders"  
    XCS96 = "Heart valve disorders"  
    XCS98 = "Essential hypertension"  
    XCS103 = "Pulmonary heart disease" 
    XCS105 = "Conduction disorders" 
    XCS106 = "Cardiac dysrhythmias" 
    XCS108 = "Congestive heart failure, nonhypertensive"
    XCS133 = "Other lower respiratory disease" 
    XCS138 = "Esophageal disorders" 
    XCS151 = "Other liver diseases" 
    XCS158 = "Chronic renal failure" 
    XCS161 = "Other diseases of kidney and ureters" 
    XCS210 = "Systemic lupus erythematosus and connective tissue disorders" 
    XCS211 = "Other connective tissue disease" 
    XCS213 = "Cardiac and circulatory congenital anomalies" 
    XCS214 = "Digestive congenital anomalies" 
    XCS215 = "Genitourinary congenital anomalies"
    XCS216 = "Nervous system congenital anomalies" 
    XCS217 = "Other congenital anomalies" 
    XCS219 = "Short gestation, low birth weight, and fetal growth retardation" 
    XCS221 = "Respiratory distress syndrome" 
    XCS224 = "Other perinatal conditions" 
    XCS227 = "Spinal cord injury"
 ;

 * -------------------------------------------------------------- ;
 * --- DEFINE PROVIDER LEVEL INDICATORS ------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO LBL;

 ATTRIB
 TPPD01 LENGTH=8
   LABEL='PDI 01 Accidental Puncture or Laceration Rate (Numerator)'
 TPPD02 LENGTH=8
   LABEL='PDI 02 Pressure Ulcer Rate (Numerator)'
 TPPD03 LENGTH=8
   LABEL='PDI 03 Retained Surgical Item or Unretrieved Device Fragment Count (Numerator)'
 TPPD05 LENGTH=8
   LABEL='PDI 05 Iatrogenic Pneumothorax Rate (Numerator)'
 TPPD06 LENGTH=8
   LABEL='PDI 06 RACHS-1 Pediatric Heart Surgery Mortality Rate (Numerator)'
 TPPD07 LENGTH=8
   LABEL='PDI 07 RACHS-1 Pediatric Heart Surgery Volume (Numerator)'
 TPPD08 LENGTH=8
   LABEL='PDI 08 Perioperative Hemorrhage or Hematoma Rate (Numerator)'
 TPPD09 LENGTH=8
   LABEL='PDI 09 Postoperative Respiratory Failure Rate (Numerator)'
 TPPD10 LENGTH=8
   LABEL='PDI 10 Postoperative Sepsis Rate (Numerator)' 
 TPPD11 LENGTH=8
   LABEL='PDI 11 Postoperative Wound Dehiscence Rate (Numerator)'
 TPPD12 LENGTH=8
   LABEL='PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (Numerator)'
 TPPD13 LENGTH=8
   LABEL='PDI 13 Transfusion Reaction Count (Numerator)'
 TPPS17 LENGTH=8
   LABEL='PSI 17 Birth Trauma Rate – Injury to Neonate (Numerator)'
;

 ATTRIB
 TPNQ01 LENGTH=8
   LABEL='NQI 01 Neonatal Iatrogenic Pneumothorax Rate (Numerator)'
 TPNQ02 LENGTH=8
   LABEL='NQI 02 Neonatal Mortality Rate (Numerator)'
 TPNQ03 LENGTH=8
   LABEL='NQI 03 Neonatal Blood Stream Infection Rate (Numerator)'
;

 ATTRIB
 QPPD01 LENGTH=3
   LABEL='PDI 01 Accidental Puncture or Laceration Rate (POA)'
 QPPD02 LENGTH=3
   LABEL='PDI 02 Pressure Ulcer Rate (POA)'
 QPPD03 LENGTH=3
   LABEL='PDI 03 Retained Surgical Item or Unretrieved Device Fragment Count (POA)'
 QPPD05 LENGTH=3
   LABEL='PDI 05 Iatrogenic Pneumothorax Rate (POA)'
 QPPD06 LENGTH=3
   LABEL='PDI 06 RACHS-1 Pediatric Heart Surgery Mortality Rate (PAL)'
 QPPD08 LENGTH=3
   LABEL='PDI 08 Perioperative Hemorrhage or Hematoma Rate (POA)'
 QPPD09 LENGTH=3
   LABEL='PDI 09 Postoperative Respiratory Failure Rate (POA)'
 QPPD10 LENGTH=3
   LABEL='PDI 010 Postoperative Sepsis Rate (POA)' 
 QPPD11 LENGTH=3
   LABEL='PDI 11 Postoperative Wound Dehiscence Rate (POA)'
 QPPD12 LENGTH=3
   LABEL='PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (POA)'
 QPPD13 LENGTH=3
   LABEL='PDI 13 Transfusion Reaction Count (POA)'
;

 ATTRIB
 QPNQ01 LENGTH=3
   LABEL='NQI 01 Neonatal Iatrogenic Pneumothorax Rate (POA)'
 QPNQ02 LENGTH=3
   LABEL='NQI 02 Neonatal Mortality Rate (PAL)'
 QPNQ03 LENGTH=3
   LABEL='NQI 03 Neonatal Blood Stream Infection Rate (POA)'
;

 * -------------------------------------------------------------- ;
 * --- DEFINE AREA LEVEL INDICATORS ----------------------------- ;
 * -------------------------------------------------------------- ;
 ATTRIB
 TAPD14 LENGTH=8
   LABEL='PDI 14 Asthma Admission Rate (Numerator)'
 TAPD15 LENGTH=8
   LABEL='PDI 15 Diabetes Short-Term Complications Admission Rate (Numerator)'
 TAPD16 LENGTH=8
   LABEL='PDI 16 Gastroenteritis Admission Rate (Numerator)'
 TAPD17 LENGTH=8
   LABEL='PDI 17 Perforated Appendix Admission Rate (Numerator)'
 TAPD18 LENGTH=8
   LABEL='PDI 18 Urinary Tract Infection Admission Rate (Numerator)'
 TAPD90 LENGTH=8
   LABEL='PDI 90 Pediatric Quality Overall Composite (Numerator)'
 TAPD91 LENGTH=8
   LABEL='PDI 91 Pediatric Quality Acute Composite (Numerator)'
 TAPD92 LENGTH=8
   LABEL='PDI 92 Pediatric Quality Chronic Composite (Numerator)'
 TAPQ09 LENGTH=8
   LABEL='PQI 09 Low Birth Weight Rate (Numerator)'
;

 * -------------------------------------------------------------- ;
 * --- RE-LABEL DAY DEPENDENT INDICATORS ------------------------ ;
 * -------------------------------------------------------------- ;
 %IF &PRDAY. = 0 %THEN %DO;

 LABEL
   TPPD02 = 'PDI 02 Pressure Ulcer Rate-NO PRDAY (Numerator)'
   TPPD08 = 'PDI 08 Perioperative Hemorrhage or Hematoma Rate-NO PRDAY (Numerator)'
   TPPD09 = 'PDI 09 Postoperative Respiratory Failure Rate-NO PRDAY (Numerator)'
   TPPD11 = 'PDI 11 Postoperative Wound Dehiscence Rate-NO PRDAY (Numerator)'
 ;
 %END;

 %MEND;

 %LBL;

 * -------------------------------------------------------------- ;
 * --- DEFINE STRATIFIERS AND RISK CLASSES ---------------------- ;
 * -------------------------------------------------------------- ;
  ATTRIB
  GPPD01 LENGTH=3
   LABEL='STRATA FOR PDI 01'
  GPPD02 LENGTH=3
   LABEL='STRATA FOR PDI 02'
  GPPD08 LENGTH=3
   LABEL='STRATA FOR PDI 08'
  GPPD10 LENGTH=3
   LABEL='STRATA FOR PDI 10'
  GPPD11 LENGTH=3
   LABEL='STRATA FOR PDI 11'
  GPPD12 LENGTH=3
   LABEL='STRATA FOR PDI 12'
  HPPD01 LENGTH=3
   LABEL='RISK CLASS FOR PDI 01'
  HPPD10 LENGTH=3
   LABEL='RISK CLASS FOR PDI 10'
 ;

 * -------------------------------------------------------------- ;
 * --- IDENTIFY NEONATES AND NEWBORNS --------------------------- ;
 * -------------------------------------------------------------- ;

   NEONATE = 0;
   IF 0 <= AGEDAY <= 28 THEN NEONATE = 1;
   ELSE IF AGEDAY LE .Z AND AGE = 0 THEN DO;
      IF ATYPE IN (4) OR %MDX($V29D.) OR %MDX($LIVEBND.)
      THEN NEONATE = 1;
   END;

   NEWBORN = 0;
   IF NEONATE THEN DO;
      IF %MDX($LIVEBND.) AND NOT AGEDAY > 0 THEN NEWBORN = 1;
      ELSE IF ATYPE IN (4) AND 
              ((AGEDAY = 0 AND NOT %MDX($LIVEB2D.)) OR
               POINTOFORIGINUB04 IN ('5'))
      THEN NEWBORN = 1;
   END;
 
   NORMAL = 0;
   IF NEWBORN AND 
      ((DRGVER LE 24 AND DRG IN (391)) OR
       (DRGVER GE 25 AND DRG IN (795)))
   THEN NORMAL = 1;

   OUTBORN = 0;
   IF NEONATE AND NOT NEWBORN THEN DO;
      IF (0 <= AGEDAY < 2) OR 
         (ATYPE IN (4) AND 
          (AGEDAY LE .Z OR POINTOFORIGINUB04 IN ('6'))) 
      THEN OUTBORN = 1;
   END;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT PROVIDER LEVEL INDICATORS ---------------------- ;
 * -------------------------------------------------------------- ;

 * --- ACCIDENTAL PUNCTURE OR LACERATION                    --- ;

   IF MEDICDR OR SURGIDR THEN DO;

      TPPD01 = 0; QPPD01 = 0;

      IF %MDX2($TECHNID.) THEN TPPD01 = 1;
      IF %MDX2Q1($TECHNID.) THEN QPPD01 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($TECHNID.) THEN TPPD01 = .;
      IF %MDX2Q2($TECHNID.) THEN QPPD01 = 1;

      *** Exclude spine surgery; 

      IF %MPR($SPINEP.) THEN TPPD01 = .;

      *** Exclude Normal Newborn;

      IF NORMAL THEN TPPD01 = .;

      *** Exclude Neonate < 500g;

      IF NEONATE AND BWHTCAT IN (1) THEN TPPD01 = .;

      *** Set POA flag to missing;

      IF TPPD01 = . OR NOPOA THEN QPPD01 = .;
      IF TPPD01 = 0 AND QPPD01 = 1 THEN QPPD01 = 0;

      *** Stratify by risk category (MDC)
           1 - Eye, ear, nose, mouth, throat, skin, breast and other low-risk procedures
           2 - Thoracic, cardiovascular, and specified neoplastic procedures
           3 - Kidney, and male/female reproductive procedures
           4 - Infectious, immunological, hematological, and ungroupable procedures
           5 - Trauma, orthopedic, and neurologic procedures
           6 - Gastrointestinal, hepatobiliary, and endocrine procedures;

      IF TPPD01 NE . THEN DO;
         IF MDC IN (2,3,9,19,22,23)     THEN GPPD01 = 1;
         ELSE IF MDC IN (4,5,17)        THEN GPPD01 = 2; 
         ELSE IF MDC IN (11,12,13)      THEN GPPD01 = 3; 
         ELSE IF MDC IN (0,16,18,25,99) THEN GPPD01 = 4; 
         ELSE IF MDC IN (1,8,21,24)     THEN GPPD01 = 5; 
         ELSE IF MDC IN (6,7,10)        THEN GPPD01 = 6; 
         ELSE GPPD01 = 9; 
      END;

      *** Risk adjust by risk category (Procedure Type)
           1. No therapeutic procedure with any or no diagnostic procedures
           2. Only minor therapeutic procedure with any or no diagnostic procedures 
           3. One major therapeutic without diagnostic procedure
           4. One major therapeutic with only minor diagnostic procedure(s)
           5. One major therapeutic with major diagnostic procedure(s) 
           6. Two major therapeutic procedures with any or no diagnostic procedures 
           7. Three or more major therapeutic procedures with any or no diagnostic procedures;

      IF TPPD01 NE . THEN DO;
         IF PRCLS2 = 0 AND PRCLS4 = 0                     THEN HPPD01 = 1;
         ELSE IF PRCLS4 = 0                               THEN HPPD01 = 2;
         ELSE IF PRCLS1 = 0 AND PRCLS3 = 0 AND PRCLS4 = 1 THEN HPPD01 = 3;
         ELSE IF PRCLS3 = 0 AND PRCLS4 = 1                THEN HPPD01 = 4;
         ELSE IF PRCLS4 = 1                               THEN HPPD01 = 5;
         ELSE IF PRCLS4 = 2                               THEN HPPD01 = 6;
         ELSE IF PRCLS4 >= 3                              THEN HPPD01 = 7;
         ELSE                                                  HPPD01 = 9;
      END;

   END;


 * --- PRESSURE ULCER                                      --- ;

 %MACRO PD2;

 IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;

      IF MPRDAY <= ORDAY THEN TPPD02 = .;

 END;
 ELSE DO;

      IF %MPR1($DEBRIDP.) THEN TPPD02 = .;

 END;

 %MEND;

   IF MEDICDR OR SURGIDR THEN DO;

      TPPD02 = 0; QPPD02 = 0;
     
 
IF ICDVER LE 25 AND %MDX2($DECUBID.) THEN TPPD02 = 1;
IF ICDVER GE 26 AND %MDX2($DECUBID.) AND %MDX2($DECUBVD.) THEN TPPD02 = 1;
IF ICDVER LE 25 AND %MDX2Q1($DECUBID.) THEN QPPD02 = 0;
IF ICDVER GE 26 AND %MDX2Q1($DECUBID.) AND %MDX2Q1($DECUBVD.) THEN QPPD02 = 0;

*** Exclude principal diagnosis; 

IF %MDX1($DECUBID.) THEN TPPD02 = .;
IF ICDVER LE 25 AND %MDX2Q2($DECUBID.) THEN QPPD02 = 1;
IF ICDVER GE 26 AND %MDX2Q2($DECUBID.) AND %MDX2Q2($DECUBVD.) THEN QPPD02 = 1;


      IF SURGIDR AND ORCNT > 0 THEN DO;
 
  *** Exclude if debridement or pedicle graft is the only OR procedure;

         %MPRCNT($DEBRIDP.);
         IF ORCNT = MPRCNT THEN TPPD02 = .;

         *** Exclude if debridement or pedicle graft occurs before or 
             on the same day as the first OR procedure;
         %ORDAY($DEBRIDP.);
         %MPRDAY($DEBRIDP.);
         %PD2;

      END;

      *** Exclude MDC 9;

      IF MDC IN (9) THEN TPPD02 = .;

      *** Exclude LOS < 5, Transfer from Acute Care Facility or LTC;

      IF LOS < 5 OR 
         (ATYPE NOTIN (4) AND
          (ASOURCE IN (2,3) OR
           POINTOFORIGINUB04 IN ('4','5','6'))) 
      THEN TPPD02 = .;

      *** Exclude Neonate;

      IF NEONATE THEN TPPD02 = .;

      *** Set POA flag to missing;

      IF TPPD02 = . OR NOPOA THEN QPPD02 = .;
      IF TPPD02 = 0 AND QPPD02 = 1 THEN QPPD02 = 0;

      *** Stratify by risk category (1 - Low risk, 2 - High risk);

      IF TPPD02 NE . THEN DO;
         IF %MDX($HEMIPID.) OR %MDX($SPIBIFD.) OR %MDX($ANOXBD.) OR  %MPR($CMVENP.) THEN GPPD02 = 2;
         ELSE GPPD02 = 1; 
      END;

   END;


   * --- RETAINED SURGICAL ITEM OR UNRETRIEVED DEVICE FRAGMENT          --- ;

   IF (MEDICDR OR SURGIDR) AND (NOT NOPOA) THEN DO;

      TPPD03 = .; QPPD03 = 0;

      IF %MDX2($FOREIID.) THEN TPPD03 = 1;
      IF %MDX2Q1($FOREIID.) THEN QPPD03 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($FOREIID.) THEN TPPD03 = .;
      IF %MDX2Q2($FOREIID.) THEN QPPD03 = 1;

      *** Exclude normal newborn; 

      IF NORMAL THEN TPPD03 = .;

      *** Exclude Neonate < 500g;
      
      IF NEONATE AND BWHTCAT IN (1) THEN TPPD03 = .;

      *** Set POA flag to missing;

      IF TPPD03 = . OR NOPOA THEN QPPD03 = .;
      IF TPPD03 = 0 AND QPPD03 = 1 THEN QPPD03 = 0;

   END;


   * --- IATROGENIC PNEUMOTHORAX  --- ;

   IF MEDICDR OR SURGIDR THEN DO;

      TPPD05 = 0; QPPD05 = 0;
  
      IF %MDX2($IATROID.) THEN TPPD05 = 1;
      IF %MDX2Q1($IATROID.) THEN QPPD05 = 0;
           
      *** Exclude principal diagnosis; 

      IF %MDX1($IATROID.) THEN TPPD05 = .;
      IF %MDX2Q2($IATROID.) THEN QPPD05 = 1;

      *** Exclude Chest Trauma, Pleural effusion;

      IF %MDX($CTRAUMD.) OR %MDX($PLEURAD.) 
      THEN TPPD05 = .;

      *** Exclude Thoracic surgery, Lung or pleural biopsy,
          Cardiac surgery or Diaphragmatic surgery repair;

      IF %MPR($THORAIP.) OR %MPR($LUNGBIP.) OR %MPR($CARDSIP.) OR 
         %MPR($DIAPHRP.)
      THEN TPPD05 = .;

      *** Exclude normal newborn; 

      IF NORMAL THEN TPPD05 = .;

      *** Exclude Neonate < 500g;
     
      IF NEONATE AND BWHTCAT IN (1) THEN TPPD05 = .;

      IF NEONATE = 1 AND BWHTCAT IN (2,3,4,5,6,7,8) THEN DO;
         TPNQ01 = TPPD05;
         TPPD05 = .;
         QPNQ01 = QPPD05;
         QPPD05 = .;
      END;

      *** Set POA flag to missing;

      IF TPPD05 = . OR NOPOA THEN QPPD05 = .;
      IF TPNQ01 = . OR NOPOA THEN QPNQ01 = .;
      IF TPPD05 = 0 AND QPPD05 = 1 THEN QPPD05 = 0;
      IF TPNQ01 = 0 AND QPNQ01 = 1 THEN QPNQ01 = 0;

 END;


   * --- PEDIATRIC HEART SURGERY MORTALITY  --- ;

   * --- COUNTS THE NUMBER OF CARDIAC SURGERY CODES -------------- ;

   %PRPDCNT1;
   %PRPDCNT2;

   IF MPR1P > 0  THEN DO;

      TPPD06 = 0;

      IF DISP IN (20) THEN TPPD06 = 1;

	  IF PALLIAFG THEN QPPD06 = 1;

   * --- EXCLUDE TRANSCATHETER INTERVENTIONS ------------------------ ;

      PDA = 0;

	  IF (((MDX3D > 0) AND (MDX3D = MDX2D - MDX5D)) AND ((MPR3EP > 0) AND (MPR3EP = MPR1P)))
      THEN PDA = 1;

      IF MPR5P = 0 AND MPR6P > 0 AND (
         MPR3AP = MPR1P OR 
         MPR3BP = MPR1P OR 
         MPR3CP = MPR1P OR 
         MPR3DP = MPR1P OR 
         PDA OR 
         MPR3FP = MPR1P) 
      THEN TPPD06 = .;

      IF MPR5P = 0 AND (MPR4P = MPR1P) 
      THEN TPPD06 = .;

      * --- EXCLUDE HEART TRANSPLANT, UNKNOWN DISPOSITION, PREMATURE INFANTS
            WITH PDA AS ONLY CARDIAC PROCEDURE AND AGE LESS THAN 30 DAYS WITH
            PDA AS ONLY CARDIAC PROCEDURE                          ----- ;

      * --- EXCLUDE ASD OR VSD WITH PDA AS ONLY CARDIAC PROCEDURE  ----- ;

      IF MPR7P > 0 OR DISP LE .Z OR
         (MDX4D AND PDA) OR
         ((AGE = 0 AND AGEDAY <=30) AND PDA) OR
         (MDX5D AND PDA) 
      THEN TPPD06 = .;

      *** Exclude Neonate < 500g;
     
      IF NEONATE AND BWHTCAT IN (1) THEN TPPD06 = .;

      *** Set PAL flag to missing;

      IF TPPD06 = . THEN QPPD06 = .;

   END;

   * --- Risk Categories for Congenital Heart Surgery-1 (RACHS-1) --- ;

%INCLUDE PHSRACHS;

   * --- VOLUME PEDIATRIC HEART SURGERY    --- ;

   * --- COUNTS THE NUMBER OF CARDIAC SURGERY CODES -------------- ;

   %PRPDCNT1;
   %PRPDCNT2;

   IF MPR1P > 0  THEN DO;

      TPPD07 = 1;

      * --- EXCLUDE TRANSCATHETER INTERVENTIONS ------------------------ ;

      PDA = 0;

      IF (((MDX3D > 0) AND (MDX3D = (MDX2D - MDX5D))) AND ((MPR3EP > 0) AND (MPR3EP = MPR1P)))
      THEN PDA = 1;

      IF MPR5P = 0 AND MPR6P > 0 AND (
         MPR3AP = MPR1P OR 
         MPR3BP = MPR1P OR 
         MPR3CP = MPR1P OR 
         MPR3DP = MPR1P OR 
         PDA OR 
         MPR3FP = MPR1P) 
      THEN TPPD07 = .;

      IF MPR5P = 0 AND (MPR4P = MPR1P) 
      THEN TPPD07 = .;

   END;


   * --- POSTOPERATIVE HEMORRHAGE OR HEMATOMA                --- ;

   %MACRO PD8;

   IF (&PRDAY. = 1 AND ORDAY NE . AND MPRDAY NE .) THEN DO;

      IF (%MDX2($POHMRI2D.) AND MPRDAY < ORDAY)
      THEN TPPD08 = .;

   END;
   ELSE DO;

      IF (%MDX2($POHMRI2D.) AND %MPR1($HEMIPB.))
      THEN TPPD08 = .;

   END;

   %MEND;

   IF SURGIDR AND ORCNT > 0 AND ATYPE IN (3) THEN DO;

      TPPD08 = 0; QPPD08 = 0;

	  /* Changed for 5.0 */
      IF (%MDX2($POHMRI2D.) AND %MPR($HEMOTH2P.))
      THEN TPPD08 = 1;

	  /* Changed for 5.0 */
      IF (%MDX2Q1($POHMRI2D.) AND %MPR($HEMOTH2P.))   
      THEN QPPD08 = 0;

      *** Exclude principal diagnosis; 

	  /* Changed for 5.0 */
      IF %MDX1($POHMRI2D.) THEN TPPD08 = .;

      /* Changed for 5.0 */
      IF %MDX2Q2($POHMRI2D.) THEN QPPD08 = 1;

      *** Exclude if control of post-operative hemorrhage or Miscellaneous Hemorrhage or
          hematoma-related procedure are the only OR procedures;

      %MPRCNT($HEMIPB.);

      IF ORCNT = MPRCNT THEN TPPD08 = .;

      *** Exclude if control of post-operative hemorrhage or Miscellaneous Hemorrhage or
          hematoma-related procedure occurs before the first OR procedure;

      %ORDAY($HEMIPB.);
      %MPRDAY($HEMIPB.);
      %PD8;

      *** Exclude Neonate < 500g;
     
      IF NEONATE AND BWHTCAT IN (1) THEN TPPD08 = .;


      *** Set POA flag to missing;

      IF TPPD08 = . OR NOPOA THEN QPPD08 = .;

      IF TPPD08 = 0 AND QPPD08 = 1 THEN QPPD08 = 0;


      *** Stratify by risk category (1-Low risk, 2-High risk);

      IF TPPD08 NE . THEN DO;
         IF %MDX($ACGOFD.) OR %MPR($ECMOP.) THEN GPPD08 = 2;
         ELSE GPPD08 = 1;
      END;

   END;

      
   * --- POSTOPERATIVE RESPIRATORY FAILURE                    --- ;

   %MACRO PD9N(FMT,DAYS);

      %MPRDAY(&FMT.);

      IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;

         IF MPRDAY >= ORDAY + &DAYS. THEN TPPD09 = 1;

      END;
      ELSE DO;

         IF %MPR2(&FMT.) THEN TPPD09 = 1;

      END;

   %MEND;

   %MACRO PD9;

      IF (&PRDAY. = 1  AND ORDAY NE . AND MPRDAY NE .) THEN DO;

         IF MPRDAY < ORDAY THEN TPPD09 = .;

      END;
      ELSE DO;

         IF %MPR1($TRACHIP.) THEN TPPD09 = .;

      END;

   %MEND;

   IF SURGIDR AND ORCNT > 0 AND ATYPE IN (3) THEN DO;

      TPPD09 = 0; QPPD09 = 0;

      IF (ICDVER LE 28 AND %MDX2($ACURFID.)) or (ICDVER GE 29 AND %MDX2($ACURF2D.)) THEN TPPD09 = 1;
      IF (ICDVER LE 28 AND %MDX2Q1($ACURFID.)) or (ICDVER GE 29 AND %MDX2Q1($ACURF2D.)) THEN QPPD09 = 0;

 
      *** Include in numerator if reintubation procedure occurs on the same day or
          # days after the first OR procedure;
 
      %ORDAY($BLANK.);
      %PD9N($PR9604P.,1);
      %PD9N($PR9670P.,2);
      %PD9N($PR9671P.,2);
      %PD9N($PR9672P.,0);


	  *** Exclude principal diagnosis; 

      IF (ICDVER LE 28 AND %MDX1($ACURFID.)) or (ICDVER GE 29 AND %MDX1($ACURF2D.)) THEN TPPD09 = .;
      IF (ICDVER LE 28 AND %MDX2Q2($ACURFID.)) or (ICDVER GE 29 AND %MDX2Q2($ACURF2D.)) THEN QPPD09 = 1;


      *** Exclude if tracheostomy procedure is the only OR procedure;

      %MPRCNT($TRACHIP.);
      IF ORCNT = MPRCNT THEN TPPD09 = .;


      *** Exclude if tracheostomy procedure occurs before the 
          first OR procedure;

      %ORDAY($TRACHIP.);
      %MPRDAY($TRACHIP.);
      %PD9;

      *** Exclude Neuromuscular disorders;
 
      IF %MDX($NEUROMD.) THEN TPPD09 = .;

      *** Exclude MDC 4, 5;
 
      IF MDC IN (4,5) THEN TPPD09 = .;

      *** Exclude Craniofacial anomalies;

      IF %MPR($NUCRANP.) OR
         (%MPR($CRANI2P.) AND %MDX($CRANIID.))
      THEN TPPD09 = .;

      *** Exclude Neonate < 500g;
     
      IF NEONATE AND BWHTCAT IN (1) THEN TPPD09 = .;

      *** Exclude Esophageal resection Procedure ;

      IF %MPR($PRESOPP.) OR %MPR($PRESO2P.) 
      THEN TPPD09 = .;

      *** Exclude Lung Cancer Procedure **;

      IF %MPR($LUNGCIP.) THEN TPPD09 = .;

      *** Exclude diagnosis of Degenerative neurological disorder ****;

      IF %MDX($DGNEUID.) THEN TPPD09 = .;


      *** Set POA flag to missing;

      IF TPPD09 = . OR NOPOA THEN QPPD09 = .;
      IF TPPD09 = 0 AND QPPD09 = 1 THEN QPPD09 = 0;

   END;


   * --- POSTOPERATIVE SEPSIS --- ;

      IF SURGIDR AND ORCNT > 0 THEN DO;

      TPPD10 = 0; QPPD10 = 0;

      IF (ICDVER LE 21 AND %MDX2($SEPTIID.)) OR
         (ICDVER GE 22 AND %MDX2($SEPTI2D.))
      THEN TPPD10 = 1;

      IF (ICDVER LE 21 AND %MDX2Q1($SEPTIID.)) OR
         (ICDVER GE 22 AND %MDX2Q1($SEPTI2D.))
      THEN QPPD10 = 0;

      *** Exclude principal diagnosis; 

      IF (ICDVER LE 21 AND %MDX1($SEPTIID.)) OR
         (ICDVER GE 22 AND %MDX1($SEPTI2D.))
      THEN TPPD10 = .;

      IF (ICDVER LE 21 AND %MDX2Q2($SEPTIID.)) OR
         (ICDVER GE 22 AND %MDX2Q2($SEPTI2D.))
      THEN QPPD10 = 1;


      *** Exclude Infection;

      IF %MDX1($INFECID.) THEN TPPD10 = .;

      *** Exclude DRG in surgical class 4;

      IF DRG4C THEN TPPD10 = .;

      *** Exclude Length of stay less then 4 days;

      IF LOS < 4 THEN TPPD10 = .;
     
      *** Exclude Neonate;

      IF NEONATE THEN TPPD10 = .;
 
      *** Set POA flag to missing;

      IF TPPD10 = . OR NOPOA THEN QPPD10 = .;
      IF TPPD10 = 0 AND QPPD10 = 1 THEN QPPD10 = 0;

      *** Stratify by procedure type (1-Low risk to 4-High risk);

      IF TPPD10 NE . THEN DO;
         IF DRG1C THEN DO;
            IF ATYPE IN (3) THEN GPPD10 = 1; ELSE GPPD10 = 2;
         END;
         ELSE IF DRG2C OR DRG3C OR DRG9C THEN DO;
            IF ATYPE IN (3) THEN GPPD10 = 3; ELSE GPPD10 = 4;
         END;
         ELSE IF DRG4C THEN GPPD10 = 5;
         ELSE GPPD10 = 9;
      END;

      *** Risk adjust by risk category (1-Low risk, 2-Intermediate risk, 3-High risk);

      IF TPPD10 NE . THEN DO;
         IF %MDX($IMMUNHD.) OR %MPR($TRANSPP.) THEN HPPD10 = 3;
         ELSE IF %MDX($IMMUITD.) OR (%MDX($HEPFA2D.) AND %MDX($HEPFA3D.)) THEN HPPD10 = 2; 
         ELSE HPPD10 = 1;
      END;

 END;
 

   * --- POSTOPERATIVE WOUND DEHISCENCE --- ;

   %MACRO PD11A;

      IF (&PRDAY. = 1 AND MPRDAYA NE . AND MPRDAYB NE .) THEN DO;

         IF MPRDAYB <= MPRDAYA THEN TPPD11 = .;

      END ;
      ELSE DO;

         IF %MPR1($RECLOIP.) THEN TPPD11 = .;

      END;

   %MEND;

   %MACRO PD11B;

      IF (&PRDAY. = 1 AND MPRDAYA NE . AND MPRDAYB NE .) THEN DO;

         IF MPRDAYB < MPRDAYA THEN TPPD11 = .;

      END;
      ELSE DO;

         IF %MPR1($REPGAST.) THEN TPPD11 = .;

      END;

   %MEND;

   IF ((YEAR < 2004 OR (YEAR = 2004 AND DQTR IN (1,2,3))) AND (%MPR($ABDOMIP.)                   )) OR
      ((YEAR > 2004 OR (YEAR = 2004 AND DQTR IN (4)    )) AND (%MPR($ABDOMIP.) OR %MPR($ABDOM2P.))) 
   THEN DO;

      TPPD11 = 0; QPPD11 = 0;

      IF %MPR($RECLOIP.) THEN TPPD11 = 1;

      *** Exclude if wound reclosure occurs before or on the same
          day as the first abdominopelvic procedure;

      %MPRDAY($ABDOMIP.); MPRDAYA = MPRDAY;
      %MPRDAY($RECLOIP.); MPRDAYB = MPRDAY;
      %PD11A;

      *** Exclude if gastrochiesis OR umbilical hernia repair performed
          before reclosure;
      %MPRDAY($RECLOIP.); MPRDAYA = MPRDAY;
      %MPRDAY($REPGAST.); MPRDAYB = MPRDAY;
      %PD11B;

      *** Exclude High and Intermediate Risk Immunocompromised state;

      IF %MDX($IMMUNHD.) OR %MPR($TRANSPP.) THEN TPPD11 = .;     

      IF %MDX($IMMUITD.) OR (%MDX($HEPFA2D.) AND %MDX($HEPFA3D.)) THEN TPPD11 = .; 

      *** Exclude LOS < 2; 
      IF LOS < 2 THEN TPPD11 = .;

      *** Exclude Neonate < 500g;
     
      IF NEONATE AND BWHTCAT IN (1) THEN TPPD11 = .;

      *** Set POA flag to missing;

      IF TPPD11 = . OR NOPOA THEN QPPD11 = .;
      IF TPPD11 = 0 AND QPPD11 = 1 THEN QPPD11 = 0;

      *** Stratify by procedure type (1-Low risk to 4-High risk);

      IF TPPD11 NE . THEN DO;
         IF DRG1C THEN DO;
            IF ATYPE IN (3) THEN GPPD11 = 1; ELSE GPPD11 = 2;
         END;
         ELSE IF DRG2C OR DRG3C OR DRG9C THEN DO;
            IF ATYPE IN (3) THEN GPPD11 = 3; ELSE GPPD11 = 4;
         END;
         ELSE IF DRG4C THEN GPPD11 = 5;
         ELSE GPPD11 = 9;
      END;

   END;

   * --- CENTRAL VENOUS CATH RELATED BSI                        --- ;

   IF MEDICDR OR SURGIDR THEN DO;

      TPPD12 = 0; QPPD12 = 0;

      IF ((ICDVER LE 24 AND (%MDX2($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX2($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX2($IDTMC3D.))))
      THEN TPPD12 = 1;

	  IF ((ICDVER LE 24 AND (%MDX2Q1($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX2Q1($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX2Q1($IDTMC3D.))))
      THEN QPPD12 = 0;

	   *** Exclude principal diagnosis; 

	  IF ((ICDVER LE 24 AND (%MDX1($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX1($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX1($IDTMC3D.))))
      THEN TPPD12 = .;

	  IF ((ICDVER LE 24 AND (%MDX2Q2($IDTMCID.))) OR 
	     ((ICDVER GE 25 AND ICDVER LE 28) AND (%MDX2Q2($IDTMC2D.))) OR
          (ICDVER GE 29 AND (%MDX2Q2($IDTMC3D.))))
      THEN QPPD12 = 1;


      *** Exclude LOS < 2;
 
      IF LOS < 2 THEN TPPD12 = .;

      *** Exclude Newborn;

      IF NORMAL THEN TPPD12 = .;

      *** Exclude Neonate < 500g;
     
      IF NEONATE AND BWHTCAT IN (1) THEN TPPD12 = .;

      *** Set POA flag to missing;

      IF TPPD12 = . OR NOPOA THEN QPPD12 = .;
      IF TPPD12 = 0 AND QPPD12 = 1 THEN QPPD12 = 0;


      *** Stratify by risk category (1-Low risk, 2-Intermediate risk, 3-High risk);

      IF TPPD12 NE . THEN DO;
         IF %MDX($IMMUNHD.) OR %MPR($TRANSPP.) OR %MDX($CANITD.) THEN GPPD12 = 3;
         ELSE IF %MDX($IMMUITD.) OR (%MDX($HEPFA2D.) AND %MDX($HEPFA3D.)) OR
                 %MDX($ACSCYFD.) OR %MDX($HEMOPHD.) THEN GPPD12 = 2; 
         ELSE GPPD12 = 1;
      END;

  END;


   * --- TRANSFUSION REACTION                                 --- ;

   IF MEDICDR OR SURGIDR THEN DO;

      TPPD13 = .; QPPD13 = .;
 
      IF %MDX2($TRANFID.) THEN TPPD13 = 1;
      IF %MDX2Q1($TRANFID.) THEN QPPD13 = 0;

      *** Exclude principal diagnosis; 

      IF %MDX1($TRANFID.) THEN TPPD13 = .;
      IF %MDX2Q2($TRANFID.) THEN QPPD13 = 1;

      *** Exclude Neonate;

      IF NEONATE THEN TPPD13 = .;

      *** Set POA flag to missing;

      IF TPPD13 = . OR NOPOA THEN QPPD13 = .;
      IF TPPD13 = 0 AND QPPD13 = 1 THEN QPPD13 = 0;

   END;

  
 * -------------------------------------------------------------- ;
 * --- CONSTRUCT OTHER PEDIATRIC INDICATORS   ------------------- ;
 * -------------------------------------------------------------- ;


   * --- BIRTH TRAUMA                                         --- ;

   IF NEWBORN THEN DO;

      TPPS17 = 0;

      IF %MDX($BIRTHID.) THEN TPPS17 = 1;

   *** Exclude Birth weight less than 2000g;

      IF %MDX($PRETEID.) THEN TPPS17 = .;

   *** Exclude Injury to brachial plexus;

      IF %MDX($BRACHID.) THEN TPPS17 = .;

   *** Exclude Osteogenesis imperfecta;

      IF %MDX($OSTEOID.) THEN TPPS17 = .;

   END;


 * -------------------------------------------------------------- ;
 * --- CONSTRUCT NEONATAL INDICATORS   -------------------------- ;
 * -------------------------------------------------------------- ;


   * --- NEONATAL MORTALITY                                   --- ;

      IF NEWBORN OR OUTBORN THEN DO;

         TPNQ02 = 0;

         IF DISP IN (20) THEN TPNQ02 = 1;

         IF PALLIAFG THEN QPNQ02 = 1;

         *** Exclude trisomy 13, trisomy 18, anencephaly, 
             polycystic kidney ;
         IF %MDX($NEOMTDX.) THEN TPNQ02 = .;

         *** Exclude birthweight < 500g;
         IF BWHTCAT IN (1) THEN TPNQ02 = .;

      *** Set PAL flag to missing;

      IF TPNQ02 = . THEN QPNQ02 = .;

      END;


   * --- BLOOD STREAM INFECTION NEONATES                     --- ;

   IF NEWBORN OR OUTBORN THEN DO;

      IF BWHTCAT IN (2,3,4,5)    OR
         GESTCAT IN (2,3,4,5)    OR 
         (BWHTCAT IN (0,6,7,8,9) AND 
         (DISP IN (20) OR %MPR($ORPROC.) OR %MPR($MECHVCD.) OR
         ((0 <= AGEDAY < 2) AND (ATYPE IN (4) AND POINTOFORIGINUB04 IN ('6'))) 
         ))  
      THEN DO;

         ORPROC = %MPR($ORPROC.);
         MECHVCD = %MPR($MECHVCD.);

         TPNQ03 = 0; QPNQ03 = 0;

         IF %MDX2($BSI1DX.) OR 
            (%MDX2($BSI2DX.) AND %MDX2($BSI3DX.)) 
         THEN TPNQ03 = 1;

         IF %MDX2Q1($BSI1DX.) OR 
            (%MDX2Q1($BSI2DX.) AND %MDX2Q1($BSI3DX.)) 
         THEN QPNQ03 = 0;

         *** Exclude principal diagnosis of Sepsis; 

		 IF((ICDVER LE 21 AND %MDX1($SEPTIID.)) OR (ICDVER GE 22 AND %MDX1($SEPTI2D.))) 
             OR %MDX1($BSI3DX.) OR %MDX1($BSI4DX.) THEN TPNQ03 = .;

		 IF ((ICDVER LE 21 AND %MDX2Q2($SEPTIID.)) OR (ICDVER GE 22 AND %MDX2Q2($SEPTI2D.)))
             OR %MDX2Q2($BSI3DX.) OR %MDX2Q2($BSI4DX.) THEN QPNQ03 = 1;

         *** Exclude birthweight < 500g;
         IF BWHTCAT IN (1) THEN TPNQ03 = .;


		 *** Exclude LOS < 7;

		 IF LOS < 7 THEN TPNQ03 = .;

         *** Set POA flag to missing;

         IF TPNQ03 = . OR NOPOA THEN QPNQ03 = .;


         IF TPNQ03 = 0 AND QPNQ03 = 1 THEN QPNQ03 = 0;

      END;

   END;
 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AREA LEVEL INDICATORS -------------------------- ;
 * -------------------------------------------------------------- ;


   * --- PEDIATRIC ASTHMA                  --- ;
   
   IF %MDX1($ACSASTD.) THEN DO;

      TAPD14 = 1;

      *** Exclude Cystic Fibrosis and Anomalies of the Respiratory System;

      IF %MDX($RESPAN.) THEN TAPD14 = .;

      *** Exclude age < 2 years;

      IF AGE < 2 THEN TAPD14 = .;

   END;


   * --- DIABETES SHORT TERM COMPLICATION  --- ;

   IF %MDX1($ACDIASD.) THEN DO;

      TAPD15 = 1;

      *** Exclude age < 6 years;

      IF AGE < 6 THEN TAPD15 = .;

   END;


   * --- PEDIATRIC GASTROENTERITIS         --- ;

   IF %MDX1($ACPGASD.) OR (%MDX2($ACPGASD.) AND %MDX1($ACSDEHD.)) THEN DO;

      TAPD16 = 1;
  
      *** Exclude age <= 90 days;

      IF 0 <= AGEDAY <= 90 OR (AGEDAY < 0 AND NEONATE) THEN TAPD16 = .;

     *** Exclude Gastrointestinal Abnormalities and Bacterial Gastroenteritis ;

     IF %MDX($ACGDISD.) THEN TAPD16 = .; 
     IF %MDX($ACBACGD.) THEN TAPD16 = .;
   
   END;


   * --- PERFORATED APPENDIX               --- ;

   IF %MDX($ACSAP2D.) THEN DO;

      TAPD17 = 0;

      IF %MDX($ACSAPPD.) THEN TAPD17 = 1;

      *** Exclude age < 1 year;

      IF AGE < 1 THEN TAPD17 = .;

   END;


   * --- URINARY INFECTION                 --- ;

   IF %MDX1($ACSUTID.) THEN DO;

      TAPD18 = 1;

      *** Exclude Kidney/Urinary Tract Disorder;

      IF %MDX($KIDNEY.) THEN TAPD18 = .;

      *** Exclude High and Intermediate Risk Immunocompromised state;

      IF %MDX($IMMUNHD.) OR %MPR($TRANSPP.) THEN TAPD18 = .;     

      IF %MDX($IMMUITD.) OR (%MDX($HEPFA2D.) AND %MDX($HEPFA3D.)) THEN TAPD18 = .; 

      *** Exclude age <= 90 days;

      IF 0 <= AGEDAY <= 90 OR (AGEDAY < 0 AND NEONATE) THEN TAPD18 = .;
 
   END;

   * --- LOW BIRTH WEIGHT                  --- ;

   IF NEWBORN THEN DO;

      TAPQ09 = 0;

      IF %MDX($ACSLBWD.) THEN TAPQ09 = 1;

   END;

 * -------------------------------------------------------------- ;
 * --- CONSTRUCT AREA LEVEL COMPOSITE INDICATORS ---------------- ;
 * -------------------------------------------------------------- ;

   * --- OVERALL                          --- ;

   IF TAPD14 = 1 OR TAPD15 = 1 OR TAPD16 = 1 OR TAPD18 = 1 THEN DO;
      TAPD90 = MAX(OF TAPD14 TAPD15 TAPD16 TAPD18);
      IF AGE < 6 THEN TAPD90 = .;
   END;

   * --- ACUTE                            --- ;

   IF TAPD16 = 1 OR TAPD18 = 1 THEN DO;
      TAPD91 = MAX(OF TAPD16 TAPD18);
      IF AGE < 6 THEN TAPD91 = .;
   END;

   * --- CHRONIC                          --- ;

   IF TAPD14 = 1 OR TAPD15 = 1 THEN DO;
      TAPD92 = MAX(OF TAPD14 TAPD15);
      IF AGE < 6 THEN TAPD92 = . ;
   END;


 * -------------------------------------------------------------- ;
 * --- EXCLUDE CASES WITH MISSING VALUES FOR DISP             --- ;
 * -------------------------------------------------------------- ;

 IF (DISP LT 0) THEN DO;
   TPPD06 = .;
   TPNQ02 = .;
 END;

 * -------------------------------------------------------------- ;
 * --- IDENTIFY TRANSFERS --------------------------------------- ;
 * -------------------------------------------------------------- ;

 * --- TRANSFER FROM ANOTHER ACUTE ---------------- ;
 IF ATYPE NOTIN (4) AND
    (ASOURCE IN (2) OR POINTOFORIGINUB04 IN ('4'))
 THEN TRNSFER = 1;
 ELSE TRNSFER = 0;
 IF ASOURCE GT .Z AND POINTOFORIGINUB04 IN (' ') THEN NOPOUB04 = 1;
 ELSE NOPOUB04 = 0;

 * --- TRANSFER TO ANOTHER ACUTE ---------------- ;

 IF DISP IN (2) THEN TRNSOUT = 1;ELSE TRNSOUT = 0;

 * -------------------------------------------------------------- ;
 * --- EXCLUDE TRANSFERS ---------------------------------------- ;
 * -------------------------------------------------------------- ;

 * --- TRANSFER FROM ANOTHER ---------------- ;
 IF ATYPE NOTIN (4) AND
    (ASOURCE IN (2,3) OR POINTOFORIGINUB04 IN ('4','5','6')) 
 THEN DO;
   TAPD14 = .;
   TAPD15 = .;
   TAPD16 = .;
   TAPD17 = .;
   TAPD18 = .;
   TAPD90 = .;
   TAPD91 = .;
   TAPD92 = .;
   TAPQ09 = .;
 END;

 * --- TRANSFER TO ANOTHER ACUTE ------------------ ;
 IF DISP IN (2) THEN DO;
   TPPD06 = .;
   TPNQ02 = .;
END;

IF NOPOA IN (0) THEN DO;

    IF QPPD01 IN (.,1) THEN TPPD01 = .;
    IF QPPD02 IN (.,1) THEN TPPD02 = .;
    IF QPPD05 IN (.,1) THEN TPPD05 = .;
    IF QPPD08 IN (.,1) THEN TPPD08 = .;

    IF QPPD09 IN (.,1) THEN TPPD09 = .;
    IF QPPD10 IN (.,1) THEN TPPD10 = .;
    IF QPPD11 IN (.,1) THEN TPPD11 = .;
    IF QPPD12 IN (.,1) THEN TPPD12 = .;
    IF QPPD13 IN (.,1) THEN TPPD13 = .;

    IF QPNQ01 IN (.,1) THEN TPNQ01 = .;
    IF QPNQ03 IN (.,1) THEN TPNQ03 = .;
 
 END;

 IF QPPD03 IN (.,1) THEN TPPD03 = .; 

 * -------------------------------------------------------------- ;
 * --- LABELS --------------------------------------------------- ;
 * -------------------------------------------------------------- ;

 LABEL
    TRNSFER  = 'TRANSFER FROM ACUTE'
    TRNSOUT  = 'TRANSFER TO ACUTE'
    MAXPR    = 'NUMBER OF PR CODES'
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

***----- TO PRINT VARIABLE LABLES COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS MIN MAX NOLABELS ;
	 VAR KEY DRG DRGVER MDC MDRG YEAR DQTR 
         AGEDCAT PAGECAT POPCAT BWHTCAT SEXCAT CONGCAT RACECAT PAYCAT DUALCAT 
         LOS TRNSFER MAXPR NOPOA NOPOUB04 NOPRDAY TRNSOUT PALLIAFG
         GPPD01 GPPD02 GPPD08 GPPD10 GPPD11 GPPD12
         HPPD01 HPPD06 HPPD10 MULTIBTH MDX4D STRCABN MULTIPLE;
     TITLE4  "CATEGORICAL VARIABLES AND RANGES OF VALUES";
RUN; QUIT;

      
PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM MEAN NOLABELS ;
	 VAR  CCS4   CCS6   CCS21  CCS33  CCS35  CCS38  CCS39  CCS41  CCS42  CCS48
          CCS51  CCS52  CCS56  CCS57  CCS58  CCS62  CCS63  CCS654  CCS661  CCS81
          CCS82  CCS83  CCS85  CCS95  CCS96  CCS98  CCS103 CCS105 CCS106 CCS108
          CCS133 CCS138 CCS151 CCS158 CCS161 CCS210 CCS211 CCS213 CCS214 CCS215
          CCS216 CCS217 CCS219 CCS221 CCS224 CCS227 
          XCS4   XCS6   XCS21  XCS33  XCS35  XCS38  XCS39  XCS41  XCS42  XCS48
          XCS51  XCS52  XCS56  XCS57  XCS58  XCS62  XCS63  XCS654  XCS661  XCS81
          XCS82  XCS83  XCS85  XCS95  XCS96  XCS98  XCS103 XCS105 XCS106 XCS108
          XCS133 XCS138 XCS151 XCS158 XCS161 XCS210 XCS211 XCS213 XCS214 XCS215
          XCS216 XCS217 XCS219 XCS221 XCS224 XCS227  ;
     TITLE "PEDIATRIC INDICATOR CASES CCS COUNTS (=SUM) AND RATES (=MEAN)";
RUN; QUIT;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM NOLABELS ;
     VAR TAPD14--TAPD18 TAPD90--TAPD92 TAPQ09;
    * OUTPUT OUT=STATS1;
     TITLE "PEDIATRIC INDICATOR NUMERATORS FOR AREA-BASED OR COUNT BASED INDICATORS (COUNT =SUM)";
RUN; QUIT;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM MEAN  NOLABELS ;
     VAR TPNQ01--TPNQ03 TPPD01--TPPD13 TPPS17;
    * OUTPUT OUT=STATS2;
     TITLE "PEDIATRIC PROVIDER LEVEL INDICATOR NUMERATOR (=SUM),DENOMINATOR (=N), AND OBSERVED RATE (MEAN) ";
RUN; QUIT;

PROC MEANS DATA = OUT1.&OUTFILE1. N NMISS SUM MEAN NOLABELS ;
     WHERE NOT NOPOA;
     VAR TPPD01--TPPD13  TPNQ01--TPNQ03;
    * OUTPUT OUT=STATS3;
     TITLE1 "PEDIATRIC PROVIDER LEVEL INDICATOR NUMERATORS (=SUM),DENOMINATORS (=N), AND OBSERVED RATE (MEAN) ";
     TITLE2 "WITH POA MODIFIERS";
RUN; QUIT;


