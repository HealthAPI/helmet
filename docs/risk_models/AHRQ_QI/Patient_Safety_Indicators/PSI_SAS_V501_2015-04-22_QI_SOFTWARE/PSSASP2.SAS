*======================================= PROGRAM: PSSASP2.SAS ======================================;
*===================================================================================================;
*  Title:  PROGRAM P2 CALCULATES OBSERVED PROVIDER RATES FOR AHRQ
*          PATIENT SAFETY INDICATORS
*
*  Description:;
*         USES PROC SUMMARY TO CALCULATE OBSERVED RATES FOR
*         PATIENT SAFETY INDICATORS ACROSS STRATIFIERS.
*         PROGRAM USES HOSPID, AGECAT, SEXCAT, PAYCAT AND RACECAT.
*
*                  >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*  USER NOTE: The AHRQ QI software does not support the calculation of weighted estimates and 
*              standard errors using complex sampling designs.  Beginning with v4.5A, all references 
*              to a discharge weight (DISCWT) have been removed from all programs.  In order to 
*              obtain weighted nationally representative estimates, please refer to the technical 
*              documentation on the AHRQ QI website.
*===================================================================================================;

FILENAME CONTROL "C:\PATHNAME\CONTROL_PSI.SAS"; *<==USER MUST modify;

%INCLUDE CONTROL;


 TITLE2 'PROGRAM: P2';
 TITLE3 'AHRQ PATIENT SAFETY INDICATORS: CALCULATE OBSERVED PROVIDER RATES';

 * -------------------------------------------------------------- ;
 * --- PROVIDER LEVEL MEANS ON INPATIENT DATA FILE  ------------- ;
 * -------------------------------------------------------------- ;

 PROC   SUMMARY DATA=IN1.&INFILE1.;
 CLASS  HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 VAR    TPPS02-TPPS16 TPPS18 TPPS19;
 OUTPUT OUT=&OUTFILP2.
        SUM (TPPS02-TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05-TPPS16 TPPS18 TPPS19) = 
             TPPS02-TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05-TPPS16 TPPS18 TPPS19
        SUM (PPPS02-PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS05-PPPS16 PPPS18 PPPS19) = 
               PPPS02-PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS05-PPPS16 PPPS18 PPPS19
        MEAN(TPPS02-TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05-TPPS16 TPPS18 TPPS19) = 
             OPPS02-OPPS04 OPPS04A OPPS04B OPPS04C OPPS04D OPPS04E OPPS05-OPPS16 OPPS18 OPPS19;
 RUN;

 PROC   SORT DATA=&OUTFILP2.;
 BY HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 RUN;

 DATA   OUTP2.&OUTFILP2.;
 SET    &OUTFILP2. (WHERE=(_TYPE_ &TYPELVLP))
;

 %MACRO LBL;

 LABEL
 TPPS02 = 'PSI 02 Death Rate in Low-Mortality Diagnosis Related Groups (DRGs) (Numerator)'
 TPPS03 = 'PSI 03 Pressure Ulcer Rate (Numerator)'
 TPPS04 = 'PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications (Numerator)'
 TPPS04A= 'PSI 04A Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum A (Numerator)'
 TPPS04B= 'PSI 04B Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum B (Numerator)'
 TPPS04C= 'PSI 04C Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum C (Numerator)'
 TPPS04D= 'PSI 04D Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum D (Numerator)'
 TPPS04E= 'PSI 04E Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum E (Numerator)'
 TPPS05 = 'PSI 05 Retained Surgical Item or Unretrieved Device Fragment Count (Numerator)'
 TPPS06 = 'PSI 06 Iatrogenic Pneumothorax Rate (Numerator)'
 TPPS07 = 'PSI 07 Central Venous Catheter-Related Blood Stream Infection Rate (Numerator)'
 TPPS08 = 'PSI 08 Postoperative Hip Fracture Rate (Numerator)'
 TPPS09 = 'PSI 09 Perioperative Hemorrhage or Hematoma Rate (Numerator)'
 TPPS10 = 'PSI 10 Postoperative Physiologic and Metabolic Derangement Rate (Numerator)'
 TPPS11 = 'PSI 11 Postoperative Respiratory Failure Rate (Numerator)'
 TPPS12 = 'PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate (Numerator)'
 TPPS13 = 'PSI 13 Postoperative Sepsis Rate (Numerator)'
 TPPS14 = 'PSI 14 Postoperative Wound Dehiscence Rate (Numerator)'
 TPPS15 = 'PSI 15 Accidental Puncture or Laceration Rate (Numerator)'
 TPPS16 = 'PSI 16 Transfusion Reaction Count (Numerator)'
 TPPS18 = 'PSI 18 Obstetric Trauma Rate - Vaginal Delivery With Instrument (Numerator)'
 TPPS19 = 'PSI 19 Obstetric Trauma Rate - Vaginal Delivery Without Instrument (Numerator)'

 PPPS02 = 'PSI 02 Death Rate in Low-Mortality Diagnosis Related Groups (DRGs) (Pop)'
 PPPS03 = 'PSI 03 Pressure Ulcer Rate (Pop)'
 PPPS04 = 'PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications (Pop)'
 PPPS04A= 'PSI 04A Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum A (Pop)'
 PPPS04B= 'PSI 04B Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum B (Pop)'
 PPPS04C= 'PSI 04C Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum C (Pop)'
 PPPS04D= 'PSI 04D Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum D (Pop)'
 PPPS04E= 'PSI 04E Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum E (Pop)'
 PPPS05 = 'PSI 05 Retained Surgical Item or Unretrieved Device Fragment Count (Pop)'
 PPPS06 = 'PSI 06 Iatrogenic Pneumothorax Rate (Pop)'
 PPPS07 = 'PSI 07 Central Venous Catheter-Related Blood Stream Infection Rate (Pop)'
 PPPS08 = 'PSI 08 Postoperative Hip Fracture Rate (Pop)'
 PPPS09 = 'PSI 09 Perioperative Hemorrhage or Hematoma Rate (Pop)'
 PPPS10 = 'PSI 10 Postoperative Physiologic and Metabolic Derangement Rate (Pop)'
 PPPS11 = 'PSI 11 Postoperative Respiratory Failure Rate (Pop)'
 PPPS12 = 'PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate (Pop)'
 PPPS13 = 'PSI 13 Postoperative Sepsis Rate (Pop)'
 PPPS14 = 'PSI 14 Postoperative Wound Dehiscence Rate (Pop)'
 PPPS15 = 'PSI 15 Accidental Puncture or Laceration Rate (Pop)'
 PPPS16 = 'PSI 16 Transfusion Reaction Count (Pop)'
 PPPS18 = 'PSI 18 Obstetric Trauma Rate - Vaginal Delivery With Instrument (Pop)'
 PPPS19 = 'PSI 19 Obstetric Trauma Rate - Vaginal Delivery Without Instrument (Pop)'

 OPPS02 = 'PSI 02 Death Rate in Low-Mortality Diagnosis Related Groups (DRGs) (Observed)'
 OPPS03 = 'PSI 03 Pressure Ulcer Rate (Observed)'
 OPPS04 = 'PSI 04 Death Rate among Surgical Inpatients with Serious Treatable Complications (Observed)'
 OPPS04A= 'PSI 04A Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum A (Observed)'
 OPPS04B= 'PSI 04B Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum B (Observed)'
 OPPS04C= 'PSI 04C Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum C (Observed)'
 OPPS04D= 'PSI 04D Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum D (Observed)'
 OPPS04E= 'PSI 04E Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum E (Observed)'
 OPPS05 = 'PSI 05 Retained Surgical Item or Unretrieved Device Fragment Count (Observed)'
 OPPS06 = 'PSI 06 Iatrogenic Pneumothorax Rate (Observed)'
 OPPS07 = 'PSI 07 Central Venous Catheter-Related Blood Stream Infection Rate (Observed)'
 OPPS08 = 'PSI 08 Postoperative Hip Fracture Rate (Observed)'
 OPPS09 = 'PSI 09 Perioperative Hemorrhage or Hematoma Rate (Observed)'
 OPPS10 = 'PSI 10 Postoperative Physiologic and Metabolic Derangement Rate (Observed)'
 OPPS11 = 'PSI 11 Postoperative Respiratory Failure Rate (Observed)'
 OPPS12 = 'PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate (Observed)'
 OPPS13 = 'PSI 13 Postoperative Sepsis Rate (Observed)'
 OPPS14 = 'PSI 14 Postoperative Wound Dehiscence Rate (Observed)'
 OPPS15 = 'PSI 15 Accidental Puncture or Laceration Rate (Observed)'
 OPPS16 = 'PSI 16 Transfusion Reaction Count (Observed)'
 OPPS18 = 'PSI 18 Obstetric Trauma Rate - Vaginal Delivery With Instrument (Observed)'
 OPPS19 = 'PSI 19 Obstetric Trauma Rate - Vaginal Delivery Without Instrument (Observed)'
 _TYPE_ = 'STRATIFICATION LEVEL '
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

   PPPS03 = 'PSI 03 Pressure Ulcer Rate-NO PRDAY (Pop)'
   PPPS08 = 'PSI 08 Postoperative Hip Fracture Rate-NO PRDAY (Pop)'
   PPPS09 = 'PSI 09 Perioperative Hemorrhage or Hematoma Rate-NO PRDAY (Pop)'
   PPPS10 = 'PSI 10 Postoperative Physiologic and Metabolic Derangement Rate-NO PRDAY (Pop)'
   PPPS11 = 'PSI 11 Postoperative Respiratory Failure Rate-NO PRDAY (Pop)'
   PPPS12 = 'PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate-NO PRDAY (Pop)'
   PPPS14 = 'PSI 14 Postoperative Wound Dehiscence Rate-NO PRDAY (Pop)'

   OPPS03 = 'PSI 03 Pressure Ulcer Rate-NO PRDAY (Observed)'
   OPPS08 = 'PSI 08 Postoperative Hip Fracture Rate-NO PRDAY (Observed)'
   OPPS09 = 'PSI 09 Perioperative Hemorrhage or Hematoma Rate-NO PRDAY (Observed)'
   OPPS10 = 'PSI 10 Postoperative Physiologic and Metabolic Derangement Rate-NO PRDAY (Observed)'
   OPPS11 = 'PSI 11 Postoperative Respiratory Failure Rate-NO PRDAY (Observed)'
   OPPS12 = 'PSI 12 Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate-NO PRDAY (Observed)'
   OPPS14 = 'PSI 14 Postoperative Wound Dehiscence Rate-NO PRDAY (Observed)'
 ;
 %END;

 %MEND;

 %LBL;

 DROP _FREQ_ ;

 RUN;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF PROVIDER OBSERVED MEANS FILE ------- ;
 * -------------------------------------------------------------- ;

 PROC   CONTENTS DATA=OUTP2.&OUTFILP2. POSITION;
 RUN;

 
***----- TO PRINT VARIABLE LABELS COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX SUM NOLABELS;
   VAR TPPS02-TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05-TPPS16 TPPS18 TPPS19;
   TITLE  'SUMMARY OF PATIENT SAFETY PROVIDER-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=16';
RUN; QUIT;

PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX SUM NOLABELS;
   VAR PPPS02-PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS05-PPPS16 PPPS18 PPPS19;
   TITLE  'SUMMARY OF PATIENT SAFETY PROVIDER-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=16';
RUN; QUIT;

PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX MEAN NOLABELS;
   VAR OPPS02-OPPS04 OPPS04A OPPS04B OPPS04C OPPS04D OPPS04E OPPS05-OPPS16 OPPS18 OPPS19;
   TITLE  'SUMMARY OF PATIENT SAFETY PROVIDER-LEVEL INDICAOTOR AVERAGE RATES(MEAN) WHEN _TYPE_=16';
RUN; QUIT;

 * -------------------------------------------------------------- ;
 * --- PRINT PROVIDER OBSERVED MEANS FILE ----------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PS,TEXT);

 PROC  PRINT DATA=OUTP2.&OUTFILP2. LABEL SPLIT='*';
 VAR   HOSPID AGECAT SEXCAT PAYCAT RACECAT TPPS&PS. PPPS&PS. OPPS&PS. ;
 LABEL HOSPID  = "HOSPID"
       AGECAT  = "AGECAT"
       SEXCAT  = "SEXCAT"
       PAYCAT  = "PAYCAT"
       RACECAT = "RACECAT"
       TPPS&PS.   = "TPPS&PS.*(Numerator)"
       PPPS&PS.   = "PPPS&PS.*(Denominator)"
       OPPS&PS.   = "OPPS&PS.*(Observed)"
       ;
 FORMAT AGECAT AGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
        TPPS&PS. PPPS&PS. 13.0 OPPS&PS. 8.6;
 TITLE4 "Indicator &PS.: &TEXT";
 RUN;

 %MEND PRT;

 %PRT(02,Death Rate in Low-Mortality Diagnosis Related Groups (DRGs));
 %IF &PRDAY. = 1 %THEN %DO;
     %PRT(03,Pressure Ulcer Rate);
 %END;
 %ELSE %DO;
     %PRT(03,Pressure Ulcer Rate-NO PRDAY);
 %END;
 %PRT(04,Death Rate among Surgical Inpatients with Serious Treatable Complications);
 %PRT(04A,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum A);
 %PRT(04B,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum B);
 %PRT(04C,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum C);
 %PRT(04D,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum D);
 %PRT(04E,Death Rate among Surgical Inpatients with Serious Treatable Complications Stratum E);
 %PRT(05,Retained Surgical Item or Unretrieved Device Fragment Count);
 %PRT(06,Iatrogenic Pneumothorax Rate);
 %PRT(07,Central Venous Catheter-Related Blood Stream Infection Rate);
 %IF &PRDAY. = 1 %THEN %DO;
     %PRT(08,Postoperative Hip Fracture Rate);
     %PRT(09,Perioperative Hemorrhage or Hematoma Rate);
     %PRT(10,Postoperative Physiologic and Metabolic Derangement Rate);
     %PRT(11,Postoperative Respiratory Failure Rate);
     %PRT(12,Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate);
 %END;
 %ELSE %DO;
     %PRT(08,Postoperative Hip Fracture Rate-NO PRDAY);
     %PRT(09,Perioperative Hemorrhage or Hematoma Rate-NO PRDAY);
     %PRT(10,Postoperative Physiologic and Metabolic Derangement Rate-NO PRDAY);
      %PRT(11,Postoperative Respiratory Failure Rate-NO PRDAY);
     %PRT(12,Perioperative Pulmonary Embolism or Deep Vein Thrombosis Rate-NO PRDAY);
 %END;
 %PRT(13,Postoperative Sepsis Rate);
 %IF &PRDAY. = 1 %THEN %DO;
     %PRT(14,Postoperative Wound Dehiscence Rate);
 %END;
 %ELSE %DO;
     %PRT(14,Postoperative Wound Dehiscence Rate-NO PRDAY);
 %END;
 %PRT(15,Accidental Puncture or Laceration Rate);
 %PRT(16,Transfusion Reaction Count);
 %PRT(18,Obstetric Trauma Rate - Vaginal Delivery With Instrument);
 %PRT(19,Obstetric Trauma Rate - Vaginal Delivery Without Instrument);

 %END;

 %MEND PRT2;

 %PRT2;


 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS ----------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXTP2;

 %IF &TEXTP2. = 1  %THEN %DO;

 DATA _NULL_;
 SET OUTP2.&OUTFILP2.;
 FILE PSTEXTP2 LRECL=1000;
 IF _N_=1 THEN PUT "Hosp Id" "," "Age" "," "Sex" "," "Payer" "," "Race" "," "Type" ","
 "TPPS02" "," "TPPS03" "," "TPPS04" "," "TPPS04A" "," "TPPS04B" "," "TPPS04C" "," "TPPS04D" "," "TPPS04E" ","
 "TPPS05" "," "TPPS06" "," "TPPS07" "," "TPPS08" ","
 "TPPS09" "," "TPPS10" "," "TPPS11" "," "TPPS12" ","
 "TPPS13" "," "TPPS14" "," "TPPS15" "," "TPPS16" ","
 "TPPS18" "," "TPPS19" "," 
 "PPPS02" "," "PPPS03" "," "PPPS04" "," "PPPS04A" "," "PPPS04B" "," "PPPS04C" "," "PPPS04D" "," "PPPS04E" ","
 "PPPS05" "," "PPPS06" "," "PPPS07" "," "PPPS08" ","
 "PPPS09" "," "PPPS10" "," "PPPS11" "," "PPPS12" ","
 "PPPS13" "," "PPPS14" "," "PPPS15" "," "PPPS16" ","
 "PPPS18" "," "PPPS19" "," 
 "OPPS02" "," "OPPS03" "," "OPPS04" "," "OPPS04A" "," "OPPS04B" "," "OPPS04C" "," "OPPS04D" "," "OPPS04E" ","
 "OPPS05" "," "OPPS06" "," "OPPS07" "," "OPPS08" ","
 "OPPS09" "," "OPPS10" "," "OPPS11" "," "OPPS12" ","
 "OPPS13" "," "OPPS14" "," "OPPS15" "," "OPPS16" ","
 "OPPS18" "," "OPPS19" 
 ;

 PUT HOSPID 13. "," AGECAT 3. "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPPS02-TPPS04 TPPS04A TPPS04B TPPS04C TPPS04D TPPS04E TPPS05-TPPS16 TPPS18 TPPS19) (7.0 ",")
  ","
 (PPPS02-PPPS04 PPPS04A PPPS04B PPPS04C PPPS04D PPPS04E PPPS05-PPPS16 PPPS18 PPPS19) (13.2 ",")
 ","
 (OPPS02-OPPS04 OPPS04A OPPS04B OPPS04C OPPS04D OPPS04E OPPS05-OPPS16 OPPS18 OPPS19) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXTP2;

 %TEXTP2;
