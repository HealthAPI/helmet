*====================================================================================;
*  Title:  PROGRAM P2 CALCULATES OBSERVED PROVIDER RATES FOR AHRQ
*          PEDIATRIC QUALITY INDICATORS
*
*  Description:;
*         USES PROC SUMMARY TO CALCULATE OBSERVED RATES FOR
*         PEDIATRIC QUALITY INDICATORS ACROSS STRATIFIERS.
*         PROGRAM USES HOSPID, BWHTCAT, AGEDCAT, PAGECAT, SEXCAT, 
*         PAYCAT, RACECAT.
*
*                >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*  USER NOTE: Since version 4.5, AHRQ QI SAS software does not explicitly support
*             the calculation of weighted estimates and standard errors using complex
*             sampling designs. References to the variable DISCWT have been removed
*             from all QI SAS software.
*
*             In order to obtain weighted nationally representative estimates, 
*             additional calculations will need to be performed.  For a more thorough 
*             description of weighted AHRQ QI analyses beginning with AHRQ QI SAS 
*             Version 4.1, see the technical documentation on the AHRQ QI website.
*
*=====================================================================================;

FILENAME CONTROL "C:\PATHNAME\CONTROL_PDI.SAS";  *<===USER MUST modify;

%INCLUDE CONTROL;


TITLE2 'PROGRAM: P2';
 TITLE3 'AHRQ PEDIATRIC QUALITY INDICATORS: CALCULATE OBSERVED PROVIDER RATES';

 * -------------------------------------------------------------- ;
 * --- PROVIDER LEVEL MEANS ON PEDIATRIC DATA FILE  ------------- ;
 * -------------------------------------------------------------- ;

 DATA   TEMP0;
 SET    IN1.&INFILE1.;

 RUN;

 PROC   SUMMARY DATA=TEMP0;
 CLASS  HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;
 VAR    TPPD01-TPPD03 TPPD05-TPPD13 TPNQ01-TPNQ03 TPPS17;
 OUTPUT OUT=&OUTFILP2.
        SUM (TPPD01-TPPD03 TPPD05-TPPD13 TPNQ01-TPNQ03 TPPS17)=
        SUMWGT(TPPD01-TPPD03 TPPD05-TPPD06 TPPD08-TPPD13 TPNQ01-TPNQ03 TPPS17)=
               PPPD01-PPPD03 PPPD05-PPPD06 PPPD08-PPPD13 PPNQ01-PPNQ03 PPPS17
        MEAN(TPPD01-TPPD03 TPPD05-TPPD06 TPPD08-TPPD13 TPNQ01-TPNQ03 TPPS17)=
             OPPD01-OPPD03 OPPD05-OPPD06 OPPD08-OPPD13 OPNQ01-OPNQ03 OPPS17;
 RUN;

 PROC   SORT DATA=&OUTFILP2.;
 BY HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT;
 RUN;

 DATA   OUTP2.&OUTFILP2.;
 SET    &OUTFILP2. (WHERE=(_TYPE_ &TYPELVLP))
;

 LABEL
 TPPD01 = 'PDI 01 Accidental Puncture or Laceration Rate (Numerator)'
 TPPD02 = 'PDI 02 Pressure Ulcer Rate (Numerator)'
 TPPD03 = 'PDI 03 Retained Surgical Item or Unretrieved Device Fragment Count (Numerator)'
 TPPD05 = 'PDI 05 Iatrogenic Pneumothorax Rate (Numerator)'
 TPPD06 = 'PDI 06 RACHS-1 Pediatric Heart Surgery Mortality Rate (Numerator)'
 TPPD07 = 'PDI 07 RACHS-1 Pediatric Heart Surgery Volume (Numerator)'
 TPPD08 = 'PDI 08 Perioperative Hemorrhage or Hematoma Rate (Numerator)'
 TPPD09 = 'PDI 09 Postoperative Respiratory Failure Rate (Numerator)'
 TPPD10 = 'PDI 10 Postoperative Sepsis Rate (Numerator)'
 TPPD11 = 'PDI 11 Postoperative Wound Dehiscence Rate (Numerator)'
 TPPD12 = 'PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (Numerator)'
 TPPD13 = 'PDI 13 Transfusion Reaction Count (Numerator)'
 TPNQ01 = 'NQI 01 Neonatal Iatrogenic Pneumothorax Rate (Numerator)'
 TPNQ02 = 'NQI 02 Neonatal Mortality Rate (Numerator)'
 TPNQ03 = 'NQI 03 Neonatal Blood Stream Infection Rate (Numerator)'
 TPPS17 = 'PSI 17 Birth Trauma Rate - Injury to Neonate (Numerator)'
 PPPD01 = 'PDI 01 Accidental Puncture or Laceration Rate (Population)'
 PPPD02 = 'PDI 02 Pressure Ulcer Rate (Population)'
 PPPD03 = 'PDI 03 Retained Surgical Item or Unretrieved Device Fragment Count (Population)'
 PPPD05 = 'PDI 05 Iatrogenic Pneumothorax Rate (Population)'
 PPPD06 = 'PDI 06 RACHS-1 Pediatric Heart Surgery Mortality Rate (Population)'
 PPPD08 = 'PDI 08 Perioperative Hemorrhage or Hematoma Rate (Population)'
 PPPD09 = 'PDI 09 Postoperative Respiratory Failure Rate (Population)'
 PPPD10 = 'PDI 10 Postoperative Sepsis Rate (Population)'
 PPPD11 = 'PDI 11 Postoperative Wound Dehiscence Rate (Population)'
 PPPD12 = 'PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (Population)'
 PPPD13 = 'PDI 13 Transfusion Reaction Count (Population)'
 PPNQ01 = 'NQI 01 Neonatal Iatrogenic Pneumothorax Rate (Population)'
 PPNQ02 = 'NQI 02 Neonatal Mortality Rate (Population)'
 PPNQ03 = 'NQI 03 Neonatal Blood Stream Infection Rate (Population)'
 PPPS17 = 'PSI 17 Birth Trauma Rate - Injury to Neonate (Population)'
 OPPD01 = 'PDI 01 Accidental Puncture or Laceration Rate (Observed)'
 OPPD02 = 'PDI 02 Pressure Ulcer Rate (Observed)'
 OPPD03 = 'PDI 03 Retained Surgical Item or Unretrieved Device Fragment Count (Observed)'
 OPPD05 = 'PDI 05 Iatrogenic Pneumothorax Rate (Observed)'
 OPPD06 = 'PDI 06 RACHS-1 Pediatric Heart Surgery Mortality Rate (Observed)'
 OPPD08 = 'PDI 08 Perioperative Hemorrhage or Hematoma Rate (Observed)'
 OPPD09 = 'PDI 09 Postoperative Respiratory Failure Rate (Observed)'
 OPPD10 = 'PDI 10 Postoperative Sepsis Rate (Observed)'
 OPPD11 = 'PDI 11 Postoperative Wound Dehiscence Rate (Observed)'
 OPPD12 = 'PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (Observed)'
 OPPD13 = 'PDI 13 Transfusion Reaction Count (Observed)'
 OPNQ01 = 'NQI 01 Neonatal Iatrogenic Pneumothorax Rate (Observed)'
 OPNQ02 = 'NQI 02 Neonatal Mortality Rate (Observed)'
 OPNQ03 = 'NQI 03 Neonatal Blood Stream Infection Rate (Observed)'
 OPPS17 = 'PSI 17 Birth Trauma Rate - Injury to Neonate (Observed)'
 _TYPE_ = 'STRATIFICATION LEVEL'
;
 DROP _FREQ_ ;

 RUN;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF PROVIDER OBSERVED MEANS FILE ------- ;
 * -------------------------------------------------------------- ;

 PROC   CONTENTS DATA=OUTP2.&OUTFILP2. POSITION;
 RUN;

 *PROC   MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (64))) N NMISS MIN MAX MEAN SUM;
 *TITLE4 "SUMMARY OF PROVIDER-LEVEL RATES (_TYPE_=64)";
 *RUN;

 ***----- TO PRINT VARIABLE LABLES COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;

PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (64))) N NMISS MIN MAX SUM NOLABELS;
   VAR TPPD01-TPPD03 TPPD05-TPPD13 TPNQ01-TPNQ03 TPPS17;
   TITLE  'SUMMARY OF PEDIATRIC PROVIDER-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=64';
RUN; QUIT;

PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (64))) N NMISS MIN MAX SUM NOLABELS;
   VAR PPPD01-PPPD03 PPPD05-PPPD06 PPPD08-PPPD13 PPNQ01-PPNQ03 PPPS17 ;
   TITLE  'SUMMARY OF PEDIATRIC PROVIDER-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=64';
RUN; QUIT;

PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (64))) N NMISS MIN MAX MEAN NOLABELS;
   VAR OPPD01-OPPD03 OPPD05-OPPD06 OPPD08-OPPD13 OPNQ01-OPNQ03 OPPS17;
   TITLE  'SUMMARY OF PEDIATRIC PROVIDER-LEVEL OBSERVED INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=64';
RUN; QUIT;

 * -------------------------------------------------------------- ;
 * --- PRINT PROVIDER OBSERVED MEANS FILE ----------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT,VOLUME);

 PROC   PRINT DATA=OUTP2.&OUTFILP2. LABEL SPLIT='*';
 %IF &VOLUME=0 %THEN %DO;
 VAR    HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT TP&PD. PP&PD. OP&PD. ;
 LABEL HOSPID  = "HOSPID"
       BWHTCAT = "BWHTCAT"
       AGEDCAT = "AGEDCAT"
       PAGECAT = "PAGECAT"
       SEXCAT  = "SEXCAT"
       PAYCAT  = "PAYCAT"
       RACECAT = "RACECAT"
       TP&PD.   = "TP&PD.*(Numerator)"
       PP&PD.   = "PP&PD.*(Denominator)"
       OP&PD.   = "OP&PD.*(Observed)"
       ;
 FORMAT BWHTCAT BWHTCAT.
        AGEDCAT AGEDCAT.
        PAGECAT PAGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
        TP&PD. PP&PD. 13.0 OP&PD. 8.6;
 %END;
 %ELSE %DO;
 VAR    HOSPID BWHTCAT AGEDCAT PAGECAT SEXCAT PAYCAT RACECAT TP&PD.  ;
 LABEL HOSPID  = "HOSPID"
       BWHTCAT = "BWHTCAT"
       AGEDCAT = "AGEDCAT"
       PAGECAT = "PAGECAT"
       SEXCAT  = "SEXCAT"
       PAYCAT  = "PAYCAT"
       RACECAT = "RACECAT"
       TP&PD.   = "TP&PD.*(Numerator)"
       ;
 FORMAT BWHTCAT BWHTCAT.
        AGEDCAT AGEDCAT.
        PAGECAT PAGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
        TP&PD. 13.0;
 %END;
 TITLE4 "Indicator &PD.: &TEXT";

 RUN;

 %MEND PRT;

 %PRT(PD01,Accidental Puncture or Laceration Rate,0);
 %PRT(PD02,Pressure Ulcer Rate,0);
 %PRT(PD03,Retained Surgical Item or Unretrieved Device Fragment Count,0);
 %PRT(PD05,Iatrogenic Pneumothorax Rate,0);
 %PRT(PD06,RACHS-1 Pediatric Heart Surgery Mortality Rate,0);
 %PRT(PD07,RACHS-1 Pediatric Heart Surgery Volume,1);
 %PRT(PD08,Perioperative Hemorrhage or Hematoma Rate,0);
 %PRT(PD09,Postoperative Respiratory Failure Rate,0);
 %PRT(PD10,Postoperative Sepsis Rate,0);
 %PRT(PD11,Postoperative Wound Dehiscence Rate,0);
 %PRT(PD12,Central Venous Catheter-Related Blood Stream Infection Rate,0);
 %PRT(PD13,Transfusion Reaction Count,0);
 %PRT(NQ01,Neonatal Iatrogenic Pneumothorax Rate,0);
 %PRT(NQ02,Neonatal Mortality Rate,0);
 %PRT(NQ03,Neonatal Blood Stream Infection Rate,0);
 %PRT(PS17,Birth Trauma Rate - Injury to Neonate,0);

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
 FILE PDTEXTP2 LRECL=2000;
 IF _N_=1 THEN PUT "Hosp Id" "," "BWht" "," "AgeD" "," "Age"  "," "Sex"  "," "Payer" "," "Race" "," "Type" ","
 "TPPD01" "," "TPPD02" "," "TPPD03" "," 
 "TPPD05" "," "TPPD06" "," "TPPD07" "," "TPPD08" ","
 "TPPD09" "," "TPPD10" "," "TPPD11" "," "TPPD12" ","
 "TPPD13" "," "TPNQ01" "," "TPNQ02" "," "TPNQ03" "," "TPPS17" "," 
 "PPPD01" "," "PPPD02" "," "PPPD03" "," 
 "PPPD05" "," "PPPD06" ","              "PPPD08" ","
 "PPPD09" "," "PPPD10" "," "PPPD11" "," "PPPD12" ","
 "PPPD13" "," "PPNQ01" "," "PPNQ02" "," "PPNQ03" "," "PPPS17" "," 
 "OPPD01" "," "OPPD02" "," "OPPD03" "," 
 "OPPD05" "," "OPPD06" ","              "OPPD08" ","
 "OPPD09" "," "OPPD10" "," "OPPD11" "," "OPPD12" ","
 "OPPD13" "," "OPNQ01" "," "OPNQ02" "," "OPNQ03" "," "OPPS17" 
 ;

 PUT HOSPID 13. "," BWHTCAT 3. "," AGEDCAT 3. "," PAGECAT 3. "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPPD01-TPPD03 TPPD05-TPPD13 TPNQ01-TPNQ03 TPPS17) (7.0 ",")
  ","
 (PPPD01-PPPD03 PPPD05-PPPD06 PPPD08-PPPD13 PPNQ01-PPNQ03 PPPS17) (13.2 ",")
 ","
 (OPPD01-OPPD03 OPPD05-OPPD06 OPPD08-OPPD13 OPNQ01-OPNQ03 OPPS17) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXTP2;

 %TEXTP2;
