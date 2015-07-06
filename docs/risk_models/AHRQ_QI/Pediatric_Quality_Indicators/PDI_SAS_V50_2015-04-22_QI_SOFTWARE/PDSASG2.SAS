*===================================================================;
*  Title:  PROGRAM G2 CALCULATES STRATIFIED OBSERVED PROVIDER RATES 
*          FOR AHRQ PEDIATRIC QUALITY INDICATORS
*
*  Description:;
*         USES PROC SUMMARY TO CALCULATE OBSERVED RATES FOR
*         PEDIATRIC QUALITY INDICATORS ACROSS STRATIFIERS.
*         PROGRAM USES HOSPID, GPPD01, GPPD02, GPPD08, GPPD10,
*         GPPD11, GPPD12.
*
*                  >>>  VERSION 5.0 - MARCH, 2015  <<<
*
*===================================================================;

FILENAME CONTROL "C:\PATHNAME\CONTROL_PDI.SAS";  *<===USER MUST modify;

%INCLUDE CONTROL;


 TITLE2 'PROGRAM: G2';
 TITLE3 'AHRQ PEDIATRIC QUALITY INDICATORS: CALCULATE STRATIFIED OBSERVED PROVIDER RATES';

 * -------------------------------------------------------------- ;
 * --- PROVIDER LEVEL MEANS ON PEDIATRIC DATA FILE  ------------- ;
 * -------------------------------------------------------------- ;

 DATA   TEMP0;
 SET    IN1.&INFILE1.;
 

 RUN;

 PROC   SUMMARY DATA=TEMP0 MISSING;
 CLASS  HOSPID GPPD01 GPPD02 GPPD08 GPPD10 GPPD11 GPPD12;
 VAR    TPPD01 TPPD02 TPPD08 TPPD10 TPPD11 TPPD12;
 OUTPUT OUT=&OUTFILG2.
        SUM (TPPD01 TPPD02 TPPD08 TPPD10 TPPD11 TPPD12)=
        SUMWGT(TPPD01 TPPD02 TPPD08 TPPD10 TPPD11 TPPD12)=PPPD01 PPPD02 PPPD08 PPPD10 PPPD11 PPPD12
        MEAN(TPPD01 TPPD02 TPPD08 TPPD10 TPPD11 TPPD12)=OPPD01 OPPD02 OPPD08 OPPD10 OPPD11 OPPD12;
 RUN;

 PROC   SORT DATA=&OUTFILG2.;
 BY HOSPID GPPD01 GPPD02 GPPD08 GPPD10 GPPD11 GPPD12;
 RUN;

 DATA   OUTG2.&OUTFILG2.;
 SET    &OUTFILG2. (WHERE=(_TYPE_ IN (1,2,4,8,16,32,65,66,68,72,80,96)))
;

 LABEL
 TPPD01 = 'PDI 01 Accidental Puncture or Laceration Rate (Numerator)'
 TPPD02 = 'PDI 02 Pressure Ulcer Rate (Numerator)'
 TPPD08 = 'PDI 08 Perioperative Hemorrhage or Hematoma Rate (Numerator)'
 TPPD10 = 'PDI 10 Postoperative Sepsis Rate (Numerator)'
 TPPD11 = 'PDI 11 Postoperative Wound Dehiscence Rate (Numerator)'
 TPPD12 = 'PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (Numerator)'
 PPPD01 = 'PDI 01 Accidental Puncture or Laceration Rate (Population)'
 PPPD02 = 'PDI 02 Pressure Ulcer Rate (Population)'
 PPPD08 = 'PDI 08 Perioperative Hemorrhage or Hematoma Rate (Population)'
 PPPD10 = 'PDI 10 Postoperative Sepsis Rate (Population)'
 PPPD11 = 'PDI 11 Postoperative Wound Dehiscence Rate (Population)'
 PPPD12 = 'PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (Population)'
 OPPD01 = 'PDI 01 Accidental Puncture or Laceration Rate (Observed)'
 OPPD02 = 'PDI 02 Pressure Ulcer Rate (Observed)'
 OPPD08 = 'PDI 08 Perioperative Hemorrhage or Hematoma Rate (Observed)'
 OPPD10 = 'PDI 10 Postoperative Sepsis Rate (Observed)'
 OPPD11 = 'PDI 11 Postoperative Wound Dehiscence Rate (Observed)'
 OPPD12 = 'PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (Observed)'
 GPPD01 = 'PDI 01 Accidental Puncture or Laceration Rate (Stratified)'
 GPPD02 = 'PDI 02 Pressure Ulcer Rate (Stratified)'
 GPPD08 = 'PDI 08 Perioperative Hemorrhage or Hematoma Rate (Stratified)'
 GPPD10 = 'PDI 10 Postoperative Sepsis Rate (Stratified)' 
 GPPD11 = 'PDI 11 Postoperative Wound Dehiscence Rate (Stratified)'
 GPPD12 = 'PDI 12 Central Venous Catheter-Related Blood Stream Infection Rate (Stratified)'
 _TYPE_ = 'STRATIFICATION LEVEL'
;
 DROP _FREQ_ ;

 RUN;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF PROVIDER OBSERVED MEANS FILE ------- ;
 * -------------------------------------------------------------- ;

 PROC   CONTENTS DATA=OUTG2.&OUTFILG2. POSITION;
 RUN;

 %MACRO MNS(PD,T);

 PROC   MEANS DATA=OUTG2.&OUTFILG2. (WHERE=(_TYPE_ IN (&T.))) N NMISS MIN MAX MEAN SUM NOLABELS;
 TITLE4 "SUMMARY OF PROVIDER-LEVEL RATES, PDI &PD.";
 CLASS GPPD&PD.;
 VAR TPPD&PD. PPPD&PD. OPPD&PD.;
 RUN;

 %MEND;

 %MNS(01,96);
 %MNS(02,80);
 %MNS(08,72);
 %MNS(10,68);
 %MNS(11,66);
 %MNS(12,65);

 * -------------------------------------------------------------- ;
 * --- PRINT PROVIDER OBSERVED MEANS FILE ----------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(PD,TEXT,T1,T2);

 PROC   PRINT DATA=OUTG2.&OUTFILG2. LABEL SPLIT='*';
 VAR    HOSPID GPPD&PD. TPPD&PD. PPPD&PD. OPPD&PD. ;
 LABEL HOSPID  = "HOSPID"
       GPPD&PD.   = "GPPD&PD.*(Stratif)"
       TPPD&PD.   = "TPPD&PD.*(Numerator)"
       PPPD&PD.   = "PPPD&PD.*(Denominator)"
       OPPD&PD.   = "OPPD&PD.*(Observed)"
       ;
 FORMAT TPPD&PD. PPPD&PD. 13.0 OPPD&PD. 8.6;
 FORMAT GPPD&PD. GP&PD.CAT.; 
 TITLE4 "Indicator &PD.: &TEXT";
 WHERE _TYPE_ IN (&T1.,&T2.) AND GPPD&PD. NE .;
 RUN;

 %MEND PRT;

 %PRT(01,Accidental Puncture or Laceration Rate,32,96);
 %PRT(02,Pressure Ulcer Rate,16,80);
 %PRT(08,Perioperative Hemorrhage or Hematoma Rate,8,72);
 %PRT(10,Postoperative Sepsis Rate,4,68);
 %PRT(11,Postoperative Wound Dehiscence Rate,2,66);
 %PRT(12,Central Venous Catheter-Related Blood Stream Infection Rate,1,65);

 %END;

 %MEND PRT2;

 %PRT2;

 * -------------------------------------------------------------- ;
 * --- WRITE SAS OUTPUT DATA SET TO COMMA-DELIMITED TEXT FILE --- ;
 * --- FOR EXPORT INTO SPREADSHEETS ----------------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO TEXTG2;

 %IF &TEXTG2. = 1  %THEN %DO;

 DATA _NULL_;
   SET OUTG2.&OUTFILG2.;
 FILE PDTEXTG2 LRECL=2000;
 IF _N_=1 THEN PUT "PedQI" "," "Hosp Id" "," "Stratif" "," "Numerat" "," "Denomin" "," "Rate" "," "Type";

 IF _TYPE_ IN (32,96) AND GPPD01 NE . THEN 
 PUT "01 ," HOSPID 13. "," GPPD01 3. "," TPPD01 7.0 "," PPPD01 13.2 "," OPPD01 12.10 "," _TYPE_ 2.;
 IF _TYPE_ IN (16,80) AND GPPD02 NE . THEN 
 PUT "02 ," HOSPID 13. "," GPPD02 3. "," TPPD02 7.0 "," PPPD02 13.2 "," OPPD02 12.10 "," _TYPE_ 2.;
 IF _TYPE_ IN (8,72) AND GPPD08 NE . THEN 
 PUT "08 ," HOSPID 13. "," GPPD08 3. "," TPPD08 7.0 "," PPPD08 13.2 "," OPPD08 12.10 "," _TYPE_ 2.;
 IF _TYPE_ IN (4,68) AND GPPD10 NE . THEN 
 PUT "10 ," HOSPID 13. "," GPPD10 3. "," TPPD10 7.0 "," PPPD10 13.2 "," OPPD10 12.10 "," _TYPE_ 2.;
 IF _TYPE_ IN (2,66) AND GPPD11 NE . THEN 
 PUT "11 ," HOSPID 13. "," GPPD11 3. "," TPPD11 7.0 "," PPPD11 13.2 "," OPPD11 12.10 "," _TYPE_ 2.;
 IF _TYPE_ IN (1,65) AND GPPD12 NE . THEN 
 PUT "12 ," HOSPID 13. "," GPPD12 3. "," TPPD12 7.0 "," PPPD12 13.2 "," OPPD12 12.10 "," _TYPE_ 2.;

 ;
 RUN;

 %END;

 %MEND TEXTG2;

 %TEXTG2;
