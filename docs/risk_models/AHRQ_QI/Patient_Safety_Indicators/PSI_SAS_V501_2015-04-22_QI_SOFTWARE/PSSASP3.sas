*======================================= PROGRAM: PSSASP3.SAS =====================================;
*==================================================================================================;
*  TITLE:  PROGRAM P3:  CALCULATES RISK-ADJUSTED PROVIDER
*          RATES FOR AHRQ PATIENT SAFETY INDICATORS
*
*  DESCRIPTION:
*         USES MCMC TO CALCULATE RISK-ADJUSTED RATES FOR
*         PATIENT SAFETY INDICATORS.
*         ADJUSTS FOR: SEX, AGE, DRG, MDC AND COMORBIDITY
*
*             >>>  VERSION 5.0.1 - APRIL 22, 2015  <<<
*
*  USER NOTE: THE AHRQ QI SOFTWARE DOES NOT SUPPORT THE CALCULATION OF WEIGHTED ESTIMATES AND 
			  STANDARD ERRORS USING COMPLEX SAMPLING DESIGNS.  BEGINNING WITH V4.5A, ALL REFERENCES 
			  TO A DISCHARGE WEIGHT (DISCWT) HAVE BEEN REMOVED FROM ALL PROGRAMS.  IN ORDER TO 
			  OBTAIN WEIGHTED NATIONALLY REPRESENTATIVE ESTIMATES, PLEASE REFER TO THE TECHNICAL 
			  DOCUMENTATION ON THE AHRQ QI WEBSITE.
*===================================================================================================;

FILENAME CONTROL 'C:\PATHNAME\CONTROL_PSI.SAS';  *<===USER MUST MODIFY;

%INCLUDE CONTROL;

*---------------------------------------------------------------------*;
*-- MAKCOVAR CREATES THE SETS OF VARIABLES USED FOR RISK ADJUSTMENT --*;
*-- THE USER MUST ENSURE THAT THE CONTROL FILE INCLUDES THE CORRECT --*;
*-- LOCATION FOR THE MAKCOVAR SAS PROGRAM.                          --*;
*---------------------------------------------------------------------*;

%INCLUDE MAKCOVAR;

TITLE2 'PROGRAM P3 PART I';
TITLE3 'AHRQ INPATIENT QUALITY INDICATORS: CALCULATE RISK-ADJUSTED PROVIDER RATES';

 %MACRO MOD3(PS, CV);
 
 DATA   TEMP1 ;

 SET    IN1.&INFILE1.;

 *--  DATA STEP CODE TO CREATE REGRESSION COVARIATES --*;
 
 %MAKEVARS_PSI_&PS. ;

 RUN;                          

*-- CHOSE PARAMETER FILE USED FOR SCORING --*;

%IF &USEPOA=1 %THEN %DO ;

FILENAME RACOEFFS  "&RADIR.\QI50_PSI_&PS._POA.CSV";

%END ;

%IF &USEPOA=0 %THEN %DO ;

FILENAME RACOEFFS  "&RADIR.\QI50_PSI_&PS._NOPOA.CSV";

%END ;

*-- LOAD CSV PARAMTERS & SHAPE DATA  --*;

DATA TEMP1_MODEL ;

LENGTH VARIABLE $10 DF ESTIMATE 8 ;
  INFILE RACOEFFS DSD DLM=',' LRECL=1024;
  INPUT VARIABLE DF ESTIMATE ;
RUN ;

PROC TRANSPOSE DATA=TEMP1_MODEL OUT=TEMP2_MODEL  ;
VAR ESTIMATE ;
RUN ;

DATA MODEL_PS&PS. (KEEP=INTERCEPT XCV1-XCV&CV. _NAME_ _TYPE_) ; 
  SET TEMP2_MODEL  ;

  RENAME COL1=INTERCEPT ;
  %DO I_=1 %TO &CV. ;
  RENAME COL%EVAL(&I_ + 1) = XCV&I_ ;
  %END ;

  _NAME_ = "MHAT" ;
  _TYPE_ = "PARMS" ;

RUN ;

*-- APPLY PROC SCORE TO DATA --* ;                   

 PROC   SCORE DATA=TEMP1 SCORE=MODEL_PS&PS. TYPE=PARMS OUT=TEMP1Y;
 VAR    XCV1-XCV&CV. ;
 RUN;

 %LET DSID=%SYSFUNC(OPEN(TEMP1Y));
 %LET DNUM=%SYSFUNC(ATTRN(&DSID,NOBS));
 %LET DRC=%SYSFUNC(CLOSE(&DSID));

 %IF &DNUM NE 0 %THEN %DO;

 *-- CALCULATE PREDICTED VALUES (EHAT) --* ;
 DATA   TEMP1Y;
 SET    TEMP1Y;

 EHAT = EXP(MHAT)/(1 + EXP(MHAT));
 PHAT = EHAT * (1 - EHAT);

 RUN;

 *-- SUMMARIZE BY VARIOUS CLASSES --*;

 PROC CONTENTS DATA=TEMP1Y ;
 RUN ;

 PROC  SUMMARY DATA=TEMP1Y;
    CLASS HOSPID AGECAT SEXCAT PAYCAT RACECAT;
    VAR   TPPS&PS. EHAT PHAT;
    OUTPUT OUT=RPPS&PS. SUM(TPPS&PS. EHAT PHAT)=TPPS&PS. EHAT PHAT
           SUMWGT(TPPS&PS.)=PPPS&PS.
           N=DENOM;
 RUN;

 *-- APPLY RISK ADJUSTMENT & SMOOTHING --* ;
 DATA   RPPS&PS.(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT _TYPE_
                 EPPS&PS. RPPS&PS. LPPS&PS. UPPS&PS. SPPS&PS. XPPS&PS. VPPS&PS.
				 TPPS&PS. PPPS&PS. OPPS&PS. 
                 );
 SET    RPPS&PS.;

 IF _TYPE_ &TYPELVLP;

 *-- LOAD SIGNAL AND NOISE ARRAYS FROM TEXT FILE --* ;
 %INCLUDE MSXP;

 *-- MAP MEASURE NUM TO ARRAY INDEX SUB_N --* ;
 IF "&PS." = "02"  THEN SUB_N = 1;
 IF "&PS." = "03"  THEN SUB_N = 2;
 IF "&PS." = "04"  THEN SUB_N = 3;
 IF "&PS." = "04A"  THEN SUB_N = 4;
 IF "&PS." = "04B"  THEN SUB_N = 5;
 IF "&PS." = "04C"  THEN SUB_N = 6;
 IF "&PS." = "04D"  THEN SUB_N = 7;
 IF "&PS." = "04E"  THEN SUB_N = 8;
 IF "&PS." = "06"  THEN SUB_N = 9;
 IF "&PS." = "07"  THEN SUB_N = 10;
 IF "&PS." = "08"  THEN SUB_N = 11;
 IF "&PS." = "09"  THEN SUB_N = 12;
 IF "&PS." = "10"  THEN SUB_N = 13;
 IF "&PS." = "11"  THEN SUB_N = 14;
 IF "&PS." = "12"  THEN SUB_N = 15;
 IF "&PS." = "13"  THEN SUB_N = 16;
 IF "&PS." = "14"  THEN SUB_N = 17;
 IF "&PS." = "15"  THEN SUB_N = 18;

 *-- T = NUMERATOR     --* ;
 *-- P = DENOMINATOR   --* ;
 *-- E = EXPECTED      --* ;
 *-- R = RISK ADJUSTED --* ; 
 *-- L = LOWER CI      --* ;
 *-- U = UPPER CI      --* ;
 *-- S = SMOOTHED      --* ;
 *-- X = SMOOTHED SE   --* ;
 *-- V = VARIANCE      --* ; 

 EPPS&PS. = EHAT / PPPS&PS.;
 THAT = TPPS&PS. / PPPS&PS.;
 OPPS&PS. = TPPS&PS. / PPPS&PS.;
 
 IF _TYPE_ IN (0,16) THEN DO;
    RPPS&PS.   = (THAT / EPPS&PS.) * ARRYP3(SUB_N);
    SE&PS.  = (ARRYP3(SUB_N) / EPPS&PS.) * (1 / PPPS&PS.) * SQRT(PHAT);
    VPPS&PS.   = SE&PS.**2;
    SN&PS.  = ARRYP2(SUB_N) / (ARRYP2(SUB_N) + VPPS&PS.);
    SPPS&PS.   = (RPPS&PS. * SN&PS.) + ((1 -  SN&PS.) * ARRYP3(SUB_N));
    XPPS&PS.   = SQRT(ARRYP2(SUB_N)- (SN&PS. * ARRYP2(SUB_N)));
 END;
 ELSE DO;
    RPPS&PS.   = (THAT / EPPS&PS.);
    SE&PS.  = (1 / EPPS&PS.) * (1 / PPPS&PS.) * SQRT(PHAT);
    VPPS&PS.   = .;
    SPPS&PS.   = .;
    XPPS&PS.   = .;
 END;
 
 LPPS&PS.   = RPPS&PS. - (1.96 * SE&PS.);
 IF LPPS&PS. < 0 THEN LPPS&PS. = 0;
 UPPS&PS.   = RPPS&PS. + (1.96 * SE&PS.);

 RUN;

 %END;

 %ELSE %DO;

 DATA   RPPS&PS.;
	HOSPID=.; AGECAT=.; SEXCAT=.; PAYCAT=.; RACECAT=0;_TYPE_=0;
    EPPS&PS=.;RPPS&PS=.;LPPS&PS=.;UPPS&PS=.;SPPS&PS=.;XPPS&PS=.;VPPS&PS=.;
    TPPS&PS=.; PPPS&PS=.; OPPS&PS=.; 
    OUTPUT;
 RUN;

 %END;

 PROC SORT DATA=RPPS&PS.;
   BY HOSPID AGECAT SEXCAT PAYCAT RACECAT _TYPE_ ;
 RUN; QUIT;
   
 PROC   DATASETS NOLIST;
 DELETE TEMP1 TEMP1Y TEMP1_MODEL TEMP2_MODEL;
 RUN;

%MEND MOD3;

%MOD3(02,23) ;
%MOD3(03,125) ; 
%MOD3(04,87) ;
%MOD3(04A,87) ;
%MOD3(04B,87) ;
%MOD3(04C,87) ;
%MOD3(04D,87) ;
%MOD3(04E,87) ;
%MOD3(06,24) ;
%MOD3(07,92) ;
%MOD3(08,2) ;
%MOD3(09,72) ;
%MOD3(10,18) ;
%MOD3(11,86) ;
%MOD3(12,108) ;
%MOD3(13,36) ;
%MOD3(14,15) ;
%MOD3(15,99) ;

  
 * --- MERGES THE AREA ADJUSTED RATES FOR EACH PS. PREFIX FOR THE - ;
 * --- ADJUSTED RATES IS (R) AND EXPECTED RATES IS (E).           - ;

 DATA RISKADJ;
 MERGE RPPS02(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS02 RPPS02 LPPS02 UPPS02 SPPS02 XPPS02 VPPS02 TPPS02 PPPS02 OPPS02)
       RPPS03(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS03 RPPS03 LPPS03 UPPS03 SPPS03 XPPS03 VPPS03 TPPS03 PPPS03 OPPS03)

	   RPPS04 (KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS04   RPPS04   LPPS04   UPPS04   SPPS04   XPPS04   VPPS04   TPPS04   PPPS04   OPPS04)
       RPPS04A(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS04A  RPPS04A  LPPS04A  UPPS04A  SPPS04A  XPPS04A  VPPS04A  TPPS04A  PPPS04A  OPPS04A)
	   RPPS04B(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS04B  RPPS04B  LPPS04B  UPPS04B  SPPS04B  XPPS04B  VPPS04B  TPPS04B  PPPS04B  OPPS04B)
	   RPPS04C(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS04C  RPPS04C  LPPS04C  UPPS04C  SPPS04C  XPPS04C  VPPS04C  TPPS04C  PPPS04C  OPPS04C)
	   RPPS04D(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS04D  RPPS04D  LPPS04D  UPPS04D  SPPS04D  XPPS04D  VPPS04D  TPPS04D  PPPS04D  OPPS04D)
	   RPPS04E(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS04E  RPPS04E  LPPS04E  UPPS04E  SPPS04E  XPPS04E  VPPS04E  TPPS04E  PPPS04E  OPPS04E)

       RPPS06(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS06 RPPS06 LPPS06 UPPS06 SPPS06 XPPS06 VPPS06 TPPS06 PPPS06 OPPS06)
       RPPS07(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS07 RPPS07 LPPS07 UPPS07 SPPS07 XPPS07 VPPS07 TPPS07 PPPS07 OPPS07)
       RPPS08(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS08 RPPS08 LPPS08 UPPS08 SPPS08 XPPS08 VPPS08 TPPS08 PPPS08 OPPS08)
       RPPS09(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS09 RPPS09 LPPS09 UPPS09 SPPS09 XPPS09 VPPS09 TPPS09 PPPS09 OPPS09)
       RPPS10(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS10 RPPS10 LPPS10 UPPS10 SPPS10 XPPS10 VPPS10 TPPS10 PPPS10 OPPS10)
       RPPS11(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS11 RPPS11 LPPS11 UPPS11 SPPS11 XPPS11 VPPS11 TPPS11 PPPS11 OPPS11)
       RPPS12(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS12 RPPS12 LPPS12 UPPS12 SPPS12 XPPS12 VPPS12 TPPS12 PPPS12 OPPS12)
       RPPS13(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS13 RPPS13 LPPS13 UPPS13 SPPS13 XPPS13 VPPS13 TPPS13 PPPS13 OPPS13)
       RPPS14(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS14 RPPS14 LPPS14 UPPS14 SPPS14 XPPS14 VPPS14 TPPS14 PPPS14 OPPS14)
       RPPS15(KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT EPPS15 RPPS15 LPPS15 UPPS15 SPPS15 XPPS15 VPPS15 TPPS15 PPPS15 OPPS15);
 BY HOSPID AGECAT SEXCAT PAYCAT RACECAT;

 LABEL
 PPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (POP)'
 PPPS03 = 'PSI 03 PRESSURE ULCER RATE (POP)'
 PPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (POP)'
 PPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (POP)'
 PPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (POP)'
 PPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (POP)'
 PPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (POP)'
 PPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (POP)'
 PPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (POP)'
 PPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (POP)'
 PPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (POP)'
 PPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (POP)'
 PPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (POP)'
 PPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (POP)'
 PPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (POP)'
 PPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (POP)'
 PPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (POP)'
 PPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (POP)'
 ;

 LABEL
 OPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (OBSERVED)'
 OPPS03 = 'PSI 03 PRESSURE ULCER RATE (OBSERVED)'
 OPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (OBSERVED)'
 OPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (OBSERVED)'
 OPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (OBSERVED)'
 OPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (OBSERVED)'
 OPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (OBSERVED)'
 OPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (OBSERVED)'
 OPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (OBSERVED)'
 OPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (OBSERVED)'
 OPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (OBSERVED)'
 OPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (OBSERVED)'
 OPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (OBSERVED)'
 OPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (OBSERVED)'
 OPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (OBSERVED)'
 OPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (OBSERVED)'
 OPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (OBSERVED)'
 OPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (OBSERVED)'
 ;

 LABEL
 EPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (EXPECTED)'
 EPPS03 = 'PSI 03 PRESSURE ULCER RATE (EXPECTED)'
 EPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (EXPECTED)'
 EPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (EXPECTED)'
 EPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (EXPECTED)'
 EPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (EXPECTED)'
 EPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (EXPECTED)'
 EPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (EXPECTED)'
 EPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (EXPECTED)'
 EPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (EXPECTED)'
 EPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (EXPECTED)'
 EPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (EXPECTED)'
 EPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (EXPECTED)'
 EPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (EXPECTED)'
 EPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (EXPECTED)'
 EPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (EXPECTED)'
 EPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (EXPECTED)'
 EPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (EXPECTED)'
 ;

 LABEL
 RPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (RISK ADJ)'
 RPPS03 = 'PSI 03 PRESSURE ULCER RATE (RISK ADJ)'
 RPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (RISK ADJ)'
 RPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (RISK ADJ)'
 RPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (RISK ADJ)'
 RPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (RISK ADJ)'
 RPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (RISK ADJ)'
 RPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (RISK ADJ)'
 RPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (RISK ADJ)'
 RPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (RISK ADJ)'
 RPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (RISK ADJ)'
 RPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (RISK ADJ)'
 RPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (RISK ADJ)'
 RPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (RISK ADJ)'
 RPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (RISK ADJ)'
 RPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (RISK ADJ)'
 RPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (RISK ADJ)'
 RPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (RISK ADJ)'
 ;

 LABEL
 LPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (LOWER CL)'
 LPPS03 = 'PSI 03 PRESSURE ULCER RATE (LOWER CL)'
 LPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (LOWER CL)'
 LPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (LOWER CL)'
 LPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (LOWER CL)'
 LPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (LOWER CL)'
 LPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (LOWER CL)'
 LPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (LOWER CL)'
 LPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (LOWER CL)'
 LPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (LOWER CL)'
 LPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (LOWER CL)'
 LPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (LOWER CL)'
 LPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (LOWER CL)'
 LPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (LOWER CL)'
 LPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (LOWER CL)'
 LPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (LOWER CL)'
 LPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (LOWER CL)'
 LPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (LOWER CL)'
 ;

 LABEL
 UPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (UPPER CL)'
 UPPS03 = 'PSI 03 PRESSURE ULCER RATE (UPPER CL)'
 UPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (UPPER CL)'
 UPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (UPPER CL)'
 UPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (UPPER CL)'
 UPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (UPPER CL)'
 UPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (UPPER CL)'
 UPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (UPPER CL)'
 UPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (UPPER CL)'
 UPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (UPPER CL)'
 UPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (UPPER CL)'
 UPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (UPPER CL)'
 UPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (UPPER CL)'
 UPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (UPPER CL)'
 UPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (UPPER CL)'
 UPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (UPPER CL)'
 UPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (UPPER CL)'
 UPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (UPPER CL)'
 ;

 LABEL 
 SPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (SMOOTHED)'
 SPPS03 = 'PSI 03 PRESSURE ULCER RATE (SMOOTHED)'
 SPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (SMOOTHED)'
 SPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (SMOOTHED)'
 SPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (SMOOTHED)'
 SPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (SMOOTHED)'
 SPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (SMOOTHED)'
 SPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (SMOOTHED)'
 SPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (SMOOTHED)'
 SPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (SMOOTHED)'
 SPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (SMOOTHED)'
 SPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (SMOOTHED)'
 SPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (SMOOTHED)'
 SPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (SMOOTHED)'
 SPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (SMOOTHED)'
 SPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (SMOOTHED)'
 SPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (SMOOTHED)'
 SPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (SMOOTHED)'
 ;

 LABEL 
 XPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (SMTHE SE)'
 XPPS03 = 'PSI 03 PRESSURE ULCER RATE (SMTHE SE)'
 XPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (SMTHE SE)'
 XPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (SMTHE SE)'
 XPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (SMTHE SE)'
 XPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (SMTHE SE)'
 XPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (SMTHE SE)'
 XPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (SMTHE SE)'
 XPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (SMTHE SE)'
 XPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (SMTHE SE)'
 XPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (SMTHE SE)'
 XPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (SMTHE SE)'
 XPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (SMTHE SE)'
 XPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (SMTHE SE)'
 XPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (SMTHE SE)'
 XPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (SMTHE SE)'
 XPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (SMTHE SE)'
 XPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (SMTHE SE)'
 ;

 LABEL 
 VPPS02 = 'PSI 02 DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS) (VARIANCE)'
 VPPS03 = 'PSI 03 PRESSURE ULCER RATE (VARIANCE)'
 VPPS04 = 'PSI 04 DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS (VARIANCE)'
 VPPS04A= 'PSI 04A DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A (VARIANCE)'
 VPPS04B= 'PSI 04B DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B (VARIANCE)'
 VPPS04C= 'PSI 04C DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C (VARIANCE)'
 VPPS04D= 'PSI 04D DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D (VARIANCE)'
 VPPS04E= 'PSI 04E DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E (VARIANCE)'
 VPPS06 = 'PSI 06 IATROGENIC PNEUMOTHORAX RATE (VARIANCE)'
 VPPS07 = 'PSI 07 CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE (VARIANCE)'
 VPPS08 = 'PSI 08 POSTOPERATIVE HIP FRACTURE RATE (VARIANCE)'
 VPPS09 = 'PSI 09 PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE (VARIANCE)'
 VPPS10 = 'PSI 10 POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE (VARIANCE)'
 VPPS11 = 'PSI 11 POSTOPERATIVE RESPIRATORY FAILURE RATE (VARIANCE)'
 VPPS12 = 'PSI 12 PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE (VARIANCE)'
 VPPS13 = 'PSI 13 POSTOPERATIVE SEPSIS RATE (VARIANCE)'
 VPPS14 = 'PSI 14 POSTOPERATIVE WOUND DEHISCENCE RATE (VARIANCE)'
 VPPS15 = 'PSI 15 ACCIDENTAL PUNCTURE OR LACERATION RATE (VARIANCE)'
 ;

 * -------------------------------------------------------------- ;
 * --- RE-LABEL DAY DEPENDENT INDICATORS ------------------------ ;
 * -------------------------------------------------------------- ;
 %MACRO RELABEL;

 %IF &PRDAY. = 0 %THEN %DO;

 LABEL 
 EPPS03 = 'PRESSURE ULCER RATE-NO PRDAY (EXPECTED)'
 EPPS08 = 'POSTOPERATIVE HIP FRACTURE RATE-NO PRDAY (EXPECTED)'
 EPPS09 = 'PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE-NO PRDAY (EXPECTED)'
 EPPS10 = 'POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE-NO PRDAY (EXPECTED)'
 EPPS11 = 'POSTOPERATIVE RESPIRATORY FAILURE RATE-NO PRDAY (EXPECTED)'
 EPPS12 = 'PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE-NO PRDAY (EXPECTED)'
 EPPS14 = 'POSTOPERATIVE WOUND DEHISCENCE RATE-NO PRDAY (EXPECTED)'
 ;

 LABEL 
 RPPS03 = 'PRESSURE ULCER RATE-NO PRDAY (RISK ADJ)'
 RPPS08 = 'POSTOPERATIVE HIP FRACTURE RATE-NO PRDAY (RISK ADJ)'
 RPPS09 = 'PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE-NO PRDAY (RISK ADJ)'
 RPPS10 = 'POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE-NO PRDAY (RISK ADJ)'
 RPPS11 = 'POSTOPERATIVE RESPIRATORY FAILURE RATE-NO PRDAY (RISK ADJ)'
 RPPS12 = 'PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE-NO PRDAY (RISK ADJ)'
 RPPS14 = 'POSTOPERATIVE WOUND DEHISCENCE RATE-NO PRDAY (RISK ADJ)'
 ;

 LABEL 
 SPPS03 = 'PRESSURE ULCER RATE-NO PRDAY (SMOOTHED)'
 SPPS08 = 'POSTOPERATIVE HIP FRACTURE RATE-NO PRDAY (SMOOTHED)'
 SPPS09 = 'PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE-NO PRDAY (SMOOTHED)'
 SPPS10 = 'POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE-NO PRDAY (SMOOTHED)'
 SPPS11 = 'POSTOPERATIVE RESPIRATORY FAILURE RATE-NO PRDAY (SMOOTHED)'
 SPPS12 = 'PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE-NO PRDAY (SMOOTHED)'
 SPPS14 = 'POSTOPERATIVE WOUND DEHISCENCE RATE-NO PRDAY (SMOOTHED)'
 ;

 %END;
 %MEND RELABEL;
 %RELABEL;

 RUN;

*==================================================================;
*  TITLE:  PROGRAM A3  PART II:  MERGE PROVIDER RATES FOR AHRQ
*  PATIENT SAFETY INDICATORS
*
*  DESCRIPTION:  MERGED RATES FOR PATIENT SAFETY INDICATORS
*
*          >>>  VERSION 5.0, NOV 2014 <<<
*
*===================================================================;

TITLE2 'PROGRAM P3 PART II';
TITLE3 'AHRQ PATIENT SAFETY INDICATORS: PROVIDER-LEVEL MERGED FILES';

* ---------------------------------------------------------------- ;
* --- PATIENT SAFETY INDICATOR MERGED RATES                      - ;
* ---------------------------------------------------------------- ;

DATA OUTP3.&OUTFILP3.;
MERGE OUTP2.&OUTFILP2.   
      RISKADJ
   (KEEP=HOSPID AGECAT SEXCAT PAYCAT RACECAT 
         EPPS02 EPPS03 EPPS04 EPPS04A EPPS04B EPPS04C EPPS04D EPPS04E EPPS06-EPPS15 
         RPPS02 RPPS03 RPPS04 RPPS04A RPPS04B RPPS04C RPPS04D RPPS04E RPPS06-RPPS15 
         LPPS02 LPPS03 LPPS04 LPPS04A LPPS04B LPPS04C LPPS04D LPPS04E LPPS06-LPPS15 
         UPPS02 UPPS03 UPPS04 UPPS04A UPPS04B UPPS04C UPPS04D UPPS04E UPPS06-UPPS15 
         SPPS02 SPPS03 SPPS04 SPPS04A SPPS04B SPPS04C SPPS04D SPPS04E SPPS06-SPPS15 
         XPPS02 XPPS03 XPPS04 XPPS04A XPPS04B XPPS04C XPPS04D XPPS04E XPPS06-XPPS15 
		 VPPS02 VPPS03 VPPS04 VPPS04A VPPS04B VPPS04C VPPS04D VPPS04E VPPS06-VPPS15
		 TPPS02 TPPS03 TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS06-TPPS15
		 PPPS02 PPPS03 PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS06-PPPS15
         OPPS02 OPPS03 OPPS04 OPPS04A OPPS04B OPPS04C OPPS04D OPPS04E OPPS06-OPPS15);
 BY HOSPID AGECAT SEXCAT PAYCAT RACECAT;

 %INCLUDE MSXP;

 ARRAY ARRY1{18} EPPS02-EPPS04 EPPS04A EPPS04B EPPS04C EPPS04D EPPS04E EPPS06-EPPS15 ;
 ARRAY ARRY2{18} RPPS02-RPPS04 RPPS04A RPPS04B RPPS04C RPPS04D RPPS04E RPPS06-RPPS15 ;
 ARRAY ARRY3{18} LPPS02-LPPS04 LPPS04A LPPS04B LPPS04C LPPS04D LPPS04E LPPS06-LPPS15 ;
 ARRAY ARRY4{18} UPPS02-UPPS04 UPPS04A UPPS04B UPPS04C UPPS04D UPPS04E UPPS06-UPPS15 ;
 ARRAY ARRY5{18} SPPS02-SPPS04 SPPS04A SPPS04B SPPS04C SPPS04D SPPS04E SPPS06-SPPS15 ;
 ARRAY ARRY6{18} XPPS02-XPPS04 XPPS04A XPPS04B XPPS04C XPPS04D XPPS04E XPPS06-XPPS15 ;
 ARRAY ARRY7{18} VPPS02-VPPS04 VPPS04A VPPS04B VPPS04C VPPS04D VPPS04E VPPS06-VPPS15 ;
 ARRAY ARRY8{18} PPPS02-PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS06-PPPS15 ;

 DO I = 1 TO 18;
    IF ARRY8(I) <= 2 THEN DO;
       ARRY1(I) = .; 
	   ARRY2(I) = .; 
	   ARRY3(I) = .; 
       ARRY4(I) = .;
       ARRY5(I) = .; 
	   ARRY6(I) = .; 
	   ARRY7(I) = .; 
    END;
 END;

 DROP I;

 FORMAT EPPS02 EPPS03 EPPS04 EPPS04A EPPS04B EPPS04C EPPS04D EPPS04E EPPS06 EPPS07 EPPS08 EPPS09 EPPS10 EPPS11 
		EPPS12 EPPS13 EPPS14 EPPS15  

		LPPS02 LPPS03 LPPS04 LPPS04A LPPS04B LPPS04C LPPS04D LPPS04E LPPS06 LPPS07 LPPS08 LPPS09 LPPS10 LPPS11 
		LPPS12 LPPS13 LPPS14 LPPS15  

		OPPS02 OPPS03 OPPS04 OPPS04A OPPS04B OPPS04C OPPS04D OPPS04E OPPS06 OPPS07 OPPS08 OPPS09 OPPS10 OPPS11 
		OPPS12 OPPS13 OPPS14 OPPS15  

		RPPS02 RPPS03 RPPS04 RPPS04A RPPS04B RPPS04C RPPS04D RPPS04E RPPS06 RPPS07 RPPS08 RPPS09 RPPS10 RPPS11
		RPPS12 RPPS13 RPPS14 RPPS15  
	

		SPPS02 SPPS03 SPPS04 SPPS04A SPPS04B SPPS04C SPPS04D SPPS04E SPPS06 SPPS07 SPPS08 SPPS09 SPPS10 SPPS11
		SPPS12 SPPS13 SPPS14 SPPS15  

		UPPS02 UPPS03 UPPS04 UPPS04A UPPS04B UPPS04C UPPS04D UPPS04E UPPS06 UPPS07 UPPS08 UPPS09 UPPS10 UPPS11
		UPPS12 UPPS13 UPPS14 UPPS15  

		VPPS02 VPPS03 VPPS04 VPPS04A VPPS04B VPPS04C VPPS04D VPPS04E VPPS06 VPPS07 VPPS08 VPPS09 VPPS10 VPPS11
		VPPS12 VPPS13 VPPS14 VPPS15  

		XPPS02 XPPS03 XPPS04 XPPS04A XPPS04B XPPS04C XPPS04D XPPS04E XPPS06 XPPS07 XPPS08 XPPS09 XPPS10 XPPS11
		XPPS12 XPPS13 XPPS14 XPPS15   13.7

		TPPS02 TPPS03 TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05 TPPS06 TPPS07 TPPS08 TPPS09 TPPS10
		TPPS11 TPPS12 TPPS13 TPPS14  TPPS15  TPPS16  

		PPPS02 PPPS03 PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS06 PPPS07 PPPS08 PPPS09 PPPS10 PPPS11 
		PPPS12 PPPS13 PPPS14 PPPS15   13.0;
 RUN;

* -------------------------------------------------------------- ;
* --- CONTENTS AND MEANS OF PROVIDER-LEVEL MERGED FILE --------- ;
* -------------------------------------------------------------- ;

PROC CONTENTS DATA=OUTP3.&OUTFILP3. POSITION;
RUN; QUIT;


***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA=OUTP3.&OUTFILP3. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX SUM NOLABELS;
   VAR TPPS02 TPPS03 TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05-TPPS16 ;
   TITLE  'SUMMARY OF PATIENT SAFETY QUALITY PROVIDER-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=16';
RUN; QUIT;

PROC MEANS DATA=OUTP3.&OUTFILP3. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX SUM NOLABELS;
   VAR PPPS02 PPPS03 PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS06-PPPS15 ;
   TITLE  'SUMMARY OF PATIENT SAFETY PROVIDER-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=16';
RUN; QUIT;

PROC MEANS DATA=OUTP3.&OUTFILP3. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX MEAN NOLABELS;
   VAR OPPS02 OPPS03 OPPS04 OPPS04A OPPS04B OPPS04C OPPS04D OPPS04E OPPS06-OPPS15 
       EPPS02 EPPS03 EPPS04 EPPS04A EPPS04B EPPS04C EPPS04D EPPS04E EPPS06-EPPS15 
       RPPS02 RPPS03 RPPS04 RPPS04A RPPS04B RPPS04C RPPS04D RPPS04E RPPS06-RPPS15 
       SPPS02 SPPS03 SPPS04 SPPS04A SPPS04B SPPS04C SPPS04D SPPS04E SPPS06-SPPS15 ;
   TITLE  'SUMMARY OF PATIENT SAFETY PROVIDER-LEVEL INDICAOTOR AVERAGE RATES(MEAN) WHEN _TYPE_=16';
RUN; QUIT;

* -------------------------------------------------------------- ;
* --- PRINT PROVIDER MERGED FILE ------------------------------- ;
* -------------------------------------------------------------- ;

%MACRO PRT2;

%IF &PRINT. = 1 %THEN %DO;

%MACRO PRT(PS,TEXT,CASE);

PROC PRINT DATA=OUTP3.&OUTFILP3. LABEL SPLIT='*';
%IF &CASE. = 1 %THEN %DO;
VAR HOSPID AGECAT SEXCAT PAYCAT RACECAT 
    TPPS&PS. ;
LABEL HOSPID  = "HOSPID"
      AGECAT  = "AGECAT"
      SEXCAT  = "SEXCAT"
      PAYCAT  = "PAYCAT"
      RACECAT = "RACECAT"
      TPPS&PS. = "TPPS&PS.*(NUMERATOR)"
     
      ;
FORMAT AGECAT AGECAT.
       SEXCAT SEXCAT.
       PAYCAT PAYCAT.
       RACECAT RACECAT.
       TPPS&PS. 13.0 ;
%END;
%ELSE %DO;
VAR HOSPID AGECAT SEXCAT PAYCAT RACECAT
    TPPS&PS. PPPS&PS. OPPS&PS. EPPS&PS. RPPS&PS. LPPS&PS. UPPS&PS. SPPS&PS. XPPS&PS.;
LABEL HOSPID  = "HOSPID"
      AGECAT  = "AGECAT"
      SEXCAT  = "SEXCAT"
      PAYCAT  = "PAYCAT"
      RACECAT = "RACECAT"
      TPPS&PS. = "TPPS&PS.*(NUMERATOR)"
      PPPS&PS. = "PPPS&PS.*(DENOMINATOR)"
      OPPS&PS. = "OPPS&PS.*(OBSERVED)"
      EPPS&PS. = "EPPS&PS.*(EXPECTED)"
      RPPS&PS. = "RPPS&PS.*(RISK ADJ)"
      LPPS&PS. = "LPPS&PS.*(LOWER CL)"
      UPPS&PS. = "UPPS&PS.*(UPPER CL)"
      SPPS&PS. = "SPPS&PS.*(SMOOTHED)"
      XPPS&PS. = "XPPS&PS.*(SMTHE SE)"
      ;
FORMAT AGECAT AGECAT.
       SEXCAT SEXCAT.
       PAYCAT PAYCAT.
       RACECAT RACECAT.
       TPPS&PS. PPPS&PS. 13.0 OPPS&PS. RPPS&PS. SPPS&PS. EPPS&PS. 8.6;
%END;
TITLE4 "FINAL OUTPUT";
TITLE5 "INDICATOR &PS.: &TEXT";

RUN;

%MEND PRT;

%PRT(02,DEATH RATE IN LOW-MORTALITY DIAGNOSIS RELATED GROUPS (DRGS),0);
%PRT(03,PRESSURE ULCER RATE,0);
%PRT(04,DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS,0);
%PRT(04A,DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM A,0);
%PRT(04B,DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM B,0);
%PRT(04C,DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM C,0);
%PRT(04D,DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM D,0);
%PRT(04E,DEATH RATE AMONG SURGICAL INPATIENTS WITH SERIOUS TREATABLE COMPLICATIONS STRATUM E,0);
%PRT(05,RETAINED SURGICAL ITEM OR UNRETRIEVED DEVICE FRAGMENT COUNT,1);
%PRT(06,IATROGENIC PNEUMOTHORAX RATE,0);
%PRT(07,CENTRAL VENOUS CATHETER-RELATED BLOOD STREAM INFECTION RATE,0);
%PRT(08,POSTOPERATIVE HIP FRACTURE RATE,0);
%PRT(09,PERIOPERATIVE HEMORRHAGE OR HEMATOMA RATE,0);
%PRT(10,POSTOPERATIVE PHYSIOLOGIC AND METABOLIC DERANGEMENT RATE,0);
%PRT(11,POSTOPERATIVE RESPIRATORY FAILURE RATE,0);
%PRT(12,PERIOPERATIVE PULMONARY EMBOLISM OR DEEP VEIN THROMBOSIS RATE,0);
%PRT(13,POSTOPERATIVE SEPSIS RATE,0);
%PRT(14,POSTOPERATIVE WOUND DEHISCENCE RATE,0);
%PRT(15,ACCIDENTAL PUNCTURE OR LACERATION RATE,0);
%PRT(16,TRANSFUSION REACTION COUNT,1);
%END;

%MEND PRT2;

%PRT2;


* -------------------------------------------------------------- ;
* --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
* --- FOR EXPORT INTO SPREADSHEETS ----------------------------- ;
* -------------------------------------------------------------- ;

%MACRO TEXT;

%IF &TEXTP3. = 1 %THEN %DO;

DATA _NULL_;
SET OUTP3.&OUTFILP3;
FILE PSTEXTP3 LRECL=4500;
IF _N_ = 1 THEN PUT
"HOSP ID" "," "AGE" "," "SEX" "," "PAYER" "," "RACE" "," "TYPE" ","
"TPPS02" "," "TPPS03" "," "TPPS04" "," "TPPS04A" "," "TPPS04B" "," "TPPS04C" "," "TPPS04D" "," "TPPS04E" ","
"TPPS05" "," "TPPS06" "," "TPPS07" "," "TPPS08"  "," "TPPS09"  "," "TPPS10"  "," "TPPS11"  "," "TPPS12" ","
"TPPS13" "," "TPPS14" "," "TPPS15" "," "TPPS16"  "," 

"PPPS02" "," "PPPS03" "," "PPPS04" "," "PPPS04A" "," "PPPS04B" "," "PPPS04C" "," "PPPS04D" "," "PPPS04E" ","
"PPPS06" "," "PPPS07" "," "PPPS08" "," "PPPS09"  "," "PPPS10"  "," "PPPS11"  "," "PPPS12"  ","
"PPPS13" "," "PPPS14" "," "PPPS15" "," 

"OPPS02" "," "OPPS03" "," "OPPS04" "," "OPPS04A" "," "OPPS04B" "," "OPPS04C" "," "OPPS04D" "," "OPPS04E" ","
"OPPS06" "," "OPPS07" "," "OPPS08" "," "OPPS09"  "," "OPPS10"  "," "OPPS11"  "," "OPPS12"  ","
"OPPS13" "," "OPPS14" "," "OPPS15" ","  

"EPPS02" "," "EPPS03" "," "EPPS04" "," "EPPS04A" "," "EPPS04B" "," "EPPS04C" "," "EPPS04D" "," "EPPS04E" "," 
"EPPS06" "," "EPPS07" "," "EPPS08" "," "EPPS09"  "," "EPPS10"  "," "EPPS11"  "," "EPPS12"  ","  
"EPPS13" "," "EPPS14" "," "EPPS15" "," 

"RPPS02" "," "RPPS03" "," "RPPS04" "," "RPPS04A" "," "RPPS04B" "," "RPPS04C" "," "RPPS04D" "," "RPPS04E" "," "RPPS06" ","
"RPPS07" "," "RPPS08" "," "RPPS09" "," "RPPS10"  "," "RPPS11"  "," "RPPS12"  "," "RPPS13"  "," "RPPS14"  ","
"RPPS15" "," 

"LPPS02" "," "LPPS03" "," "LPPS04" "," "LPPS04A" "," "LPPS04B" "," "LPPS04C" "," "LPPS04D" "," "LPPS04E" "," "LPPS06" "," 
"LPPS07" "," "LPPS08" "," "LPPS09" "," "LPPS10"  "," "LPPS11"  "," "LPPS12"  "," "LPPS13"  "," "LPPS14"  ","
"LPPS15" "," 

"UPPS02" "," "UPPS03" "," "UPPS04" "," "UPPS04A" "," "UPPS04B" "," "UPPS04C" "," "UPPS04D" "," "UPPS04E" "," "UPPS06" ","
"UPPS07" "," "UPPS08" "," "UPPS09" "," "UPPS10"  "," "UPPS11"  "," "UPPS12"  "," "UPPS13"  "," "UPPS14"  ","
"UPPS15" "," 

"SPPS02" "," "SPPS03" "," "SPPS04" "," "SPPS04A" "," "SPPS04B" "," "SPPS04C" "," "SPPS04D" "," "SPPS04E" "," "SPPS06" ","  
"SPPS07" "," "SPPS08" "," "SPPS09" "," "SPPS10"  "," "SPPS11"  "," "SPPS12"  "," "SPPS13"  "," "SPPS14"  ","
"SPPS15" ","  

"XPPS02" "," "XPPS03" "," "XPPS04" "," "XPPS04A" "," "XPPS04B" "," "XPPS04C" "," "XPPS04D" "," "XPPS04E" "," "XPPS06" ","
"XPPS07" "," "XPPS08" "," "XPPS09" "," "XPPS10"  "," "XPPS11"  "," "XPPS12"  "," "XPPS13"  "," "XPPS14"  ","
"XPPS15" ","  
;

PUT HOSPID 13. "," AGECAT 3. "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2. ","
(TPPS02 TPPS03 TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05-TPPS16 ) (7.0  ",")  "," 
(PPPS02 PPPS03 PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS06-PPPS15 ) (13.2 ",")  ","
(OPPS02 OPPS03 OPPS04 OPPS04A OPPS04B OPPS04C OPPS04D OPPS04E OPPS06-OPPS15 ) (12.10 ",") ","
(EPPS02 EPPS03 EPPS04 EPPS04A EPPS04B EPPS04C EPPS04D EPPS04E EPPS06-EPPS15 ) (12.10 ",") ","
(RPPS02 RPPS03 RPPS04 RPPS04A RPPS04B RPPS04C RPPS04D RPPS04E RPPS06-RPPS15 ) (12.10 ",") ","
(LPPS02 LPPS03 LPPS04 LPPS04A LPPS04B LPPS04C LPPS04D LPPS04E LPPS06-LPPS15 ) (12.10 ",") ","
(UPPS02 UPPS03 UPPS04 UPPS04A UPPS04B UPPS04C UPPS04D UPPS04E UPPS06-UPPS15 ) (12.10 ",") ","
(SPPS02 SPPS03 SPPS04 SPPS04A SPPS04B SPPS04C SPPS04D SPPS04E SPPS06-SPPS15 ) (12.10 ",") ","
(XPPS02 XPPS03 XPPS04 XPPS04A XPPS04B XPPS04C XPPS04D XPPS04E XPPS06-XPPS15 ) (12.10 ",")
;

RUN;

%END;

%MEND TEXT;

%TEXT;

