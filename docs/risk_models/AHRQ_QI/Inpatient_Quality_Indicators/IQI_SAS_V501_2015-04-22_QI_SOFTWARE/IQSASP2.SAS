*===============================================================================================;
*  Title:  PROGRAM P2 CALCULATES OBSERVED PROVIDER RATES FOR AHRQ
*          INPATIENT QUALITY INDICATORS
*
*  Description:;
*         USES PROC SUMMARY TO CALCULATE OBSERVED RATES FOR
*         INPATIENT QUALITY INDICATORS ACROSS STRATIFIERS.
*         PROGRAM USES HOSPID, AGECAT, SEXCAT, PAYCAT AND RACECAT.
*
*          >>>  VERSION 5.0 - MARCH, 2015   <<<
*
*  USER NOTE: Since version 4.5, AHRQ QI SAS software does not explicitly support the calculation 
*             of weighted estimates and standard errors using complex sampling designs.
*             The variable DISCWT (discharge weight) has been removed from all QI SAS programs.
*
*             In order to obtain weighted nationally representative estimates, additional 
*             calculations will need to be performed.  
*             For a more thorough description of weighted AHRQ QI analyses beginning with 
*             AHRQ QI SAS Version 4.1, see the technical documentation on the AHRQ QI website.
*=================================================================================================;


FILENAME CONTROL 'C:\PATHNAME\CONTROL_IQI.SAS';  *<===USER MUST modify; 

%INCLUDE CONTROL;


 TITLE2 'PROGRAM: P2';
 TITLE3 'AHRQ INPATIENT QUALITY INDICATORS: CALCULATE OBSERVED PROVIDER RATES';

 * -------------------------------------------------------------- ;
 * --- PROVIDER LEVEL MEANS ON INPATIENT DATA FILE  ------------- ;
 * -------------------------------------------------------------- ;


 PROC   SUMMARY DATA=IN1.&INFILE1.;
 CLASS  HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 VAR    TPIQ01  TPIQ02 TPIQ02A  TPIQ02B TPIQ04 TPIQ04A TPIQ04B TPIQ04C TPIQ04D
        TPIQ05-TPIQ09   TPIQ09A TPIQ09B TPIQ11 TPIQ11A TPIQ11B TPIQ11C TPIQ11D  TPIQ12-TPIQ17
		TPIQ17A TPIQ17B TPIQ17C TPIQ18-TPIQ25  TPIQ30-TPIQ34;
 OUTPUT OUT=&OUTFILP2.
        SUM(TPIQ01  TPIQ02 TPIQ02A TPIQ02B TPIQ04 TPIQ04A TPIQ04B TPIQ04C TPIQ04D TPIQ05-TPIQ09
            TPIQ09A TPIQ09B TPIQ11 TPIQ11A TPIQ11B TPIQ11C TPIQ11D TPIQ12-TPIQ17
            TPIQ17A TPIQ17B TPIQ17C TPIQ18-TPIQ25 TPIQ30-TPIQ34)=
        SUMWGT(TPIQ08  TPIQ09  TPIQ09A TPIQ09B TPIQ11 TPIQ11A TPIQ11B TPIQ11C TPIQ11D TPIQ12-TPIQ17
               TPIQ17A TPIQ17B TPIQ17C TPIQ18-TPIQ25 TPIQ30-TPIQ34)= PPIQ08 PPIQ09 PPIQ09A PPIQ09B PPIQ11 PPIQ11A PPIQ11B PPIQ11C PPIQ11D
                                                                     PPIQ12-PPIQ17 PPIQ17A PPIQ17B PPIQ17C PPIQ18-PPIQ25 PPIQ30-PPIQ34
        MEAN  (TPIQ08 TPIQ09 TPIQ09A TPIQ09B TPIQ11 TPIQ11A TPIQ11B TPIQ11C TPIQ11D TPIQ12-TPIQ17
               TPIQ17A TPIQ17B TPIQ17C TPIQ18-TPIQ25 TPIQ30-TPIQ34)= OPIQ08 OPIQ09 OPIQ09A OPIQ09B OPIQ11 OPIQ11A OPIQ11B OPIQ11C OPIQ11D 
                                                                     OPIQ12-OPIQ17 OPIQ17A OPIQ17B OPIQ17C OPIQ18-OPIQ25 OPIQ30-OPIQ34 ;
 RUN;




 PROC SORT DATA=&OUTFILP2.;
 BY HOSPID AGECAT SEXCAT PAYCAT RACECAT;
 RUN;

 DATA OUTP2.&OUTFILP2.;
   SET &OUTFILP2. (WHERE=(_TYPE_ &TYPELVLP));
    
 LABEL
 TPIQ01   ='IQI 01 Esophageal Resection Volume (Numerator)'
 TPIQ02   ='IQI 02 Pancreatic Resection Volume (Numerator)'
 TPIQ02A  ='IQI 02 Pancreatic Resection Volume Stratum A (Numerator)'
 TPIQ02B  ='IQI 02 Pancreatic Resection Volume Stratum B (Numerator)'
 TPIQ04   ='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume (Numerator)'
 TPIQ04A  ='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum A (Numerator)'
 TPIQ04B  ='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum B (Numerator)'
 TPIQ04C  ='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum C (Numerator)'
 TPIQ04D  ='IQI 04 Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum D (Numerator)'
 TPIQ05   ='IQI 05 Coronary Artery Bypass Graft (CABG) Volume (Numerator)'
 TPIQ06   ='IQI 06 Percutaneous Coronary Intervention (PCI) Volume (Numerator)'
 TPIQ07   ='IQI 07 Carotid Endarterectomy Volume (Numerator)'
 TPIQ08   ='IQI 08 Esophageal Resection Mortality Rate (Numerator)'
 TPIQ09   ='IQI 09 Pancreatic Resection Mortality Rate (Numerator)'
 TPIQ09A  ='IQI 09 Pancreatic Resection Mortality Rate Stratum A (Numerator)'
 TPIQ09B  ='IQI 09 Pancreatic Resection Mortality Rate Stratum B (Numerator)'
 TPIQ11   ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate (Numerator)'
 TPIQ11A  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum A (Numerator)'
 TPIQ11B  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum B (Numerator)'
 TPIQ11C  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum C (Numerator)'
 TPIQ11D  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum D (Numerator)'
 TPIQ12   ='IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate (Numerator)'
 TPIQ13   ='IQI 13 Craniotomy Mortality Rate (Numerator)'
 TPIQ14   ='IQI 14 Hip Replacement Mortality Rate (Numerator)'
 TPIQ15   ='IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate (Numerator)'
 TPIQ16   ='IQI 16 Heart Failure Mortality Rate (Numerator)'
 TPIQ17   ='IQI 17 Acute Stroke Mortality Rate (Numerator)'
 TPIQ17A  ='IQI 17 Acute Stroke Mortality Rate Stratum A (Numerator)'
 TPIQ17B  ='IQI 17 Acute Stroke Mortality Rate Stratum B (Numerator)'
 TPIQ17C  ='IQI 17 Acute Stroke Mortality Rate Stratum C (Numerator)'
 TPIQ18   ='IQI 18 Gastrointestinal Hemorrhage Mortality Rate (Numerator)'
 TPIQ19   ='IQI 19 Hip Fracture Mortality Rate (Numerator)'
 TPIQ20   ='IQI 20 Pneumonia Mortality Rate (Numerator)'
 TPIQ21   ='IQI 21 Cesarean Delivery Rate, Uncomplicated (Numerator)'
 TPIQ22   ='IQI 22 Vaginal Birth After Cesarean (VBAC) Delivery Rate, Uncomplicated (Numerator)'
 TPIQ23   ='IQI 23 Laparoscopic Cholecystectomy Rate (Numerator)'
 TPIQ24   ='IQI 24 Incidental Appendectomy in the Elderly Rate (Numerator)'
 TPIQ25   ='IQI 25 Bilateral Cardiac Catheterization Rate (Numerator)'
 TPIQ30   ='IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate (Numerator)'
 TPIQ31   ='IQI 31 Carotid Endarterectomy Mortality Rate (Numerator)'
 TPIQ32   ='IQI 32 Acute Myocardial Infarction (AMI) Mortality Rate, Without Transfer Cases (Numerator)'
 TPIQ33   ='IQI 33 Primary Cesarean Delivery Rate, Uncomplicated (Numerator)'
 TPIQ34   ='IQI 34 Vaginal Birth After Cesarean (VBAC) Rate, All (Numerator)'

 PPIQ08   ='IQI 08 Esophageal Resection Mortality Rate (Population)'
 PPIQ09   ='IQI 09 Pancreatic Resection Mortality Rate (Population)'
 PPIQ09A  ='IQI 09 Pancreatic Resection Mortality Rate Stratum A (Population)'
 PPIQ09B  ='IQI 09 Pancreatic Resection Mortality Rate Stratum B (Population)'
 PPIQ11   ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate (Population)'
 PPIQ11A  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum A (Population)'
 PPIQ11B  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum B (Population)'
 PPIQ11C  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum C (Population)'
 PPIQ11D  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum D (Population)'
 PPIQ12   ='IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate (Population)'
 PPIQ13   ='IQI 13 Craniotomy Mortality Rate (Population)'
 PPIQ14   ='IQI 14 Hip Replacement Mortality Rate (Population)'
 PPIQ15   ='IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate (Population)'
 PPIQ16   ='IQI 16 Heart Failure Mortality Rate (Population)'
 PPIQ17   ='IQI 17 Acute Stroke Mortality Rate (Population)'
 PPIQ17A  ='IQI 17 Acute Stroke Mortality Rate Stratum A (Population)'
 PPIQ17B  ='IQI 17 Acute Stroke Mortality Rate Stratum B (Population)'
 PPIQ17C  ='IQI 17 Acute Stroke Mortality Rate Stratum C (Population)'
 PPIQ18   ='IQI 18 Gastrointestinal Hemorrhage Mortality Rate (Population)'
 PPIQ19   ='IQI 19 Hip Fracture Mortality Rate (Population)'
 PPIQ20   ='IQI 20 Pneumonia Mortality Rate (Population)'
 PPIQ21   ='IQI 21 Cesarean Delivery Rate, Uncomplicated (Population)'
 PPIQ22   ='IQI 22 Vaginal Birth After Cesarean (VBAC) Delivery Rate, Uncomplicated (Population)'
 PPIQ23   ='IQI 23 Laparoscopic Cholecystectomy Rate (Population)'
 PPIQ24   ='IQI 24 Incidental Appendectomy in the Elderly Rate (Population)'
 PPIQ25   ='IQI 25 Bilateral Cardiac Catheterization Rate (Population)'
 PPIQ30   ='IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate (Population)'
 PPIQ31   ='IQI 31 Carotid Endarterectomy Mortality Rate (Population)'
 PPIQ32   ='IQI 32 Acute Myocardial Infarction (AMI) Mortality Rate, Without Transfer Cases (Population)'
 PPIQ33   ='IQI 33 Primary Cesarean Delivery Rate, Uncomplicated (Population)'
 PPIQ34   ='IQI 34 Vaginal Birth After Cesarean (VBAC) Rate, All (Population)'

 OPIQ08   ='IQI 08 Esophageal Resection Mortality Rate (Observed)'
 OPIQ09   ='IQI 09 Pancreatic Resection Mortality Rate (Observed)'
 OPIQ09A  ='IQI 09 Pancreatic Resection Mortality Rate Stratum A (Observed)'
 OPIQ09B  ='IQI 09 Pancreatic Resection Mortality Rate Stratum B (Observed)'
 OPIQ11   ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate (Observed)'
 OPIQ11A  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum A (Observed)'
 OPIQ11B  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum B (Observed)'
 OPIQ11C  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum C (Observed)'
 OPIQ11D  ='IQI 11 Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum D (Observed)'
 OPIQ12   ='IQI 12 Coronary Artery Bypass Graft (CABG) Mortality Rate (Observed)'
 OPIQ13   ='IQI 13 Craniotomy Mortality Rate (Observed)'
 OPIQ14   ='IQI 14 Hip Replacement Mortality Rate (Observed)'
 OPIQ15   ='IQI 15 Acute Myocardial Infarction (AMI) Mortality Rate (Observed)'
 OPIQ16   ='IQI 16 Heart Failure Mortality Rate (Observed)'
 OPIQ17   ='IQI 17 Acute Stroke Mortality Rate (Observed)'
 OPIQ17A  ='IQI 17 Acute Stroke Mortality Rate Stratum A (Observed)'
 OPIQ17B  ='IQI 17 Acute Stroke Mortality Rate Stratum B (Observed)'
 OPIQ17C  ='IQI 17 Acute Stroke Mortality Rate Stratum C (Observed)'
 OPIQ18   ='IQI 18 Gastrointestinal Hemorrhage Mortality Rate (Observed)'
 OPIQ19   ='IQI 19 Hip Fracture Mortality Rate (Observed)'
 OPIQ20   ='IQI 20 Pneumonia Mortality Rate (Observed)'
 OPIQ21   ='IQI 21 Cesarean Delivery Rate, Uncomplicated (Observed)'
 OPIQ22   ='IQI 22 Vaginal Birth After Cesarean (VBAC) Delivery Rate, Uncomplicated (Observed)'
 OPIQ23   ='IQI 23 Laparoscopic Cholecystectomy Rate (Observed)'
 OPIQ24   ='IQI 24 Incidental Appendectomy in the Elderly Rate (Observed)'
 OPIQ25   ='IQI 25 Bilateral Cardiac Catheterization Rate (Observed)'
 OPIQ30   ='IQI 30 Percutaneous Coronary Intervention (PCI) Mortality Rate (Observed)'
 OPIQ31   ='IQI 31 Carotid Endarterectomy Mortality Rate (Observed)'
 OPIQ32   ='IQI 32 Acute Myocardial Infarction (AMI) Mortality Rate, Without Transfer Cases (Observed)'
 OPIQ33   ='IQI 33 Primary Cesarean Delivery Rate, Uncomplicated (Observed)'
 OPIQ34   ='IQI 34 Vaginal Birth After Cesarean (VBAC) Rate, All (Observed)'
 _TYPE_   ='STRATIFICATION LEVEL'
;
 DROP _FREQ_ ;
RUN;

 * -------------------------------------------------------------- ;
 * --- CONTENTS AND MEANS OF PROVIDER OBSERVED MEANS FILE ------- ;
 * -------------------------------------------------------------- ;

 PROC   CONTENTS DATA=OUTP2.&OUTFILP2. POSITION;
 RUN;

 *PROC   MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX MEAN SUM NOLABELS;
 *TITLE4 "SUMMARY OF PROVIDER-LEVEL RATES (_TYPE_=16)";
 *RUN;

***----- TO PRINT VARIABLE LABLES COMMENT (DELETE) "NOLABELS" FROM PROC MEANS STATEMENTS -------***;
PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX SUM NOLABELS;
   VAR TPIQ01  TPIQ02 TPIQ02A  TPIQ02B TPIQ04 TPIQ04A TPIQ04B TPIQ04C TPIQ04D
       TPIQ05-TPIQ09   TPIQ09A TPIQ09B TPIQ11 TPIQ11A TPIQ11B TPIQ11C TPIQ11D  TPIQ12-TPIQ17
	   TPIQ17A TPIQ17B TPIQ17C TPIQ18-TPIQ25  TPIQ30-TPIQ34;
   TITLE  'SUMMARY OF INPATIENT QUALITY PROVIDER-LEVEL INDICATOR OVERALL NUMERATOR (SUM) WHEN _TYPE_=16';
RUN; QUIT;

PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX SUM NOLABELS;
   VAR PPIQ08 PPIQ09 PPIQ09A PPIQ09B PPIQ11 PPIQ11A PPIQ11B PPIQ11C PPIQ11D
       PPIQ12-PPIQ17 PPIQ17A PPIQ17B PPIQ17C PPIQ18-PPIQ25 PPIQ30-PPIQ34;
   TITLE  'SUMMARY OF INPATIENT QUALITY PROVIDER-LEVEL INDICATOR OVERALL DENOMINATOR (SUM) WHEN _TYPE_=16';
RUN; QUIT;

PROC MEANS DATA=OUTP2.&OUTFILP2. (WHERE=(_TYPE_ IN (16))) N NMISS MIN MAX MEAN NOLABELS;
   VAR OPIQ08 OPIQ09 OPIQ09A OPIQ09B OPIQ11 OPIQ11A OPIQ11B OPIQ11C OPIQ11D 
       OPIQ12-OPIQ17 OPIQ17A OPIQ17B OPIQ17C OPIQ18-OPIQ25 OPIQ30-OPIQ34;
   TITLE  'SUMMARY OF INPATIENT QUALITY PROVIDER-LEVEL INDICATOR AVERAGE RATES(MEAN) WHEN _TYPE_=16';
RUN; QUIT;

 * -------------------------------------------------------------- ;
 * --- PRINT PROVIDER OBSERVED MEANS FILE ----------------------- ;
 * -------------------------------------------------------------- ;

 %MACRO PRT2;

 %IF &PRINT. = 1 %THEN %DO;

 %MACRO PRT(IQ,TEXT,VOLUME);

 PROC   PRINT DATA=OUTP2.&OUTFILP2. LABEL SPLIT='*';
 %IF &VOLUME=0 %THEN %DO;
 VAR    HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ&IQ. PPIQ&IQ. OPIQ&IQ. ;
 LABEL HOSPID  = "HOSPID"
       AGECAT  = "AGECAT"
       SEXCAT  = "SEXCAT"
       PAYCAT  = "PAYCAT"
       RACECAT = "RACECAT"
       TPIQ&IQ.   = "TPIQ&IQ.*(Numerator)"
       PPIQ&IQ.   = "PPIQ&IQ.*(Denominator)"
       OPIQ&IQ.   = "OPIQ&IQ.*(Observed)"
       ;
 FORMAT TPIQ&IQ. PPIQ&IQ. 13.0 OPIQ&IQ. 8.6;
 %END;
 %ELSE %DO;
 VAR    HOSPID AGECAT SEXCAT PAYCAT RACECAT TPIQ&IQ.  ;
 LABEL HOSPID  = "HOSPID"
       AGECAT  = "AGECAT"
       SEXCAT  = "SEXCAT"
       PAYCAT  = "PAYCAT"
       RACECAT = "RACECAT"
       TPIQ&IQ.   = "TPIQ&IQ.*(Numerator)"
       ;
 FORMAT TPIQ&IQ. 13.0;
 %END;
 FORMAT AGECAT AGECAT.
        SEXCAT SEXCAT.
        PAYCAT PAYCAT.
        RACECAT RACECAT.
   ;
 TITLE4 "Indicator &IQ.: &TEXT";
 RUN;

 %MEND PRT;

 %PRT(01, Esophageal Resection Volume,1);
 %PRT(02, Pancreatic Resection Volume,1);
 %PRT(02A, Pancreatic Resection Volume Stratum A,1);
 %PRT(02B, Pancreatic Resection Volume Stratum B,1);
 %PRT(04, Abdominal Aortic Aneurysm (AAA) Repair Volume,1);
 %PRT(04A, Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum A,1);
 %PRT(04B, Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum B,1);
 %PRT(04C, Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum C,1);
 %PRT(04D, Abdominal Aortic Aneurysm (AAA) Repair Volume Stratum D,1);
 %PRT(05, Coronary Artery Bypass Graft (CABG) Volume,1); 
 %PRT(06, Percutaneous Coronary Intervention (PCI) Volume,1);
 %PRT(07, Carotid Endarterectomy Volume,1);
 %PRT(08, Esophageal Resection Mortality Rate,0);
 %PRT(09, Pancreatic Resection Mortality Rate,0)
 %PRT(09A, Pancreatic Resection Mortality Rate Stratum A,0);
 %PRT(09B, Pancreatic Resection Mortality Rate Stratum B,0)
 %PRT(11, Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate,0);
 %PRT(11A, Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum A,0);
 %PRT(11B, Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum B,0);
 %PRT(11C, Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum C,0);
 %PRT(11D, Abdominal Aortic Aneurysm (AAA) Repair Mortality Rate Stratum D,0);
 %PRT(12, Coronary Artery Bypass Graft (CABG) Mortality Rate,0);
 %PRT(13, Craniotomy Mortality Rate,0);
 %PRT(14, Hip Replacement Mortality Rate,0);
 %PRT(15, Acute Myocardial Infarction (AMI) Mortality Rate,0);
 %PRT(16, Heart Failure Mortality Rate,0);
 %PRT(17, Acute Stroke Mortality Rate,0);
 %PRT(17A, Acute Stroke Mortality Rate Stratum A,0);
 %PRT(17B, Acute Stroke Mortality Rate Stratum B,0);
 %PRT(17C, Acute Stroke Mortality Rate Stratum C,0);
 %PRT(18, Gastrointestinal Hemorrhage Mortality Rate,0);
 %PRT(19, Hip Fracture Mortality Rate,0);
 %PRT(20, Pneumonia Mortality Rate,0);
 %PRT(21, %BQUOTE(Cesarean Delivery Rate, Uncomplicated),0);
 %PRT(22, %BQUOTE(Vaginal Birth After Cesarean (VBAC) Delivery Rate, Uncomplicated),0);
 %PRT(23, Laparoscopic Cholecystectomy Rate,0);
 %PRT(24, Incidental Appendectomy in the Elderly Rate,0);
 %PRT(25, Bilateral Cardiac Catheterization Rate,0);
 %PRT(30, Percutaneous Coronary Intervention (PCI) Mortality Rate,0);
 %PRT(31, Carotid Endarterectomy Mortality Rate,0);
 %PRT(32, %BQUOTE(Acute Myocardial Infarction (AMI) Mortality Rate, Without Transfer Cases),0);
 %PRT(33, %BQUOTE(Primary Cesarean Delivery Rate, Uncomplicated),0);
 %PRT(34, %BQUOTE(Vaginal Birth After Cesarean (VBAC) Rate, All),0);

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
 FILE IQTEXTP2 LRECL=2000;
 IF _N_=1 THEN PUT "Hosp Id" "," "Age"  "," "Sex"  "," "Payer" "," "Race"  "," "Type" ","
 "TPIQ01"  "," "TPIQ02"  "," "TPIQ02A" "," "TPIQ02B" "," "TPIQ04"  ","  
 "TPIQ04A" "," "TPIQ04B" "," "TPIQ04C" "," "TPIQ04D" ","  
 "TPIQ05"  "," "TPIQ06"  "," "TPIQ07"  "," "TPIQ08"  "," "TPIQ09"  ","
 "TPIQ09A" "," "TPIQ09B" "," "TPIQ11"  "," "TPIQ11A" "," "TPIQ11B" "," "TPIQ11C" "," "TPIQ11D" "," 
 "TPIQ12"  "," "TPIQ13"  "," "TPIQ14"  "," "TPIQ15"  "," "TPIQ16"  ","
 "TPIQ17"  "," "TPIQ17A" "," "TPIQ17B" "," "TPIQ17C" "," "TPIQ18"  "," 
 "TPIQ19"  "," "TPIQ20"  "," "TPIQ21"  "," "TPIQ22"  "," "TPIQ23"  "," 
 "TPIQ24"  "," "TPIQ25"  "," "TPIQ30"  "," "TPIQ31"  "," "TPIQ32"  "," 
 "TPIQ33"  "," "TPIQ34"  "," 
 
 "PPIQ08"  "," "PPIQ09"  "," "PPIQ09A" "," "PPIQ09B" "," "PPIQ11" "," 
 "PPIQ11A" "," "PPIQ11B" "," "PPIQ11C" "," "PPIQ11D" "," "PPIQ12" ","
 "PPIQ13"  "," "PPIQ14"  "," "PPIQ15"  "," "PPIQ16"  "," 
 "PPIQ17"  "," "PPIQ17A" "," "PPIQ17B" "," "PPIQ17C" "," "PPIQ18"  "," 
 "PPIQ19"  "," "PPIQ20"  "," "PPIQ21"  "," "PPIQ22"  "," "PPIQ23"  "," 
 "PPIQ24" ","  "PPIQ25"  "," "PPIQ30"  "," "PPIQ31"  "," "PPIQ32" "," 
 "PPIQ33"  "," "PPIQ34"  "," 

 "OPIQ08"  "," "OPIQ09"  "," "OPIQ09A" "," "OPIQ09B" "," "OPIQ11"  "," 
 "OPIQ11A" "," "OPIQ11B" "," "OPIQ11C" "," "OPIQ11D" "," "OPIQ12"  ","
 "OPIQ13"  "," "OPIQ14"  "," "OPIQ15"  "," "OPIQ16"  "," "OPIQ17"  "," 
 "OPIQ17A" "," "OPIQ17B" "," "OPIQ17C" "," "OPIQ18"  "," "OPIQ19"  "," 
 "OPIQ20" ","  "OPIQ21"  "," "OPIQ22"  "," "OPIQ23"  "," "OPIQ24"  ","
 "OPIQ25"  "," "OPIQ30"  "," "OPIQ31"  "," "OPIQ32"  "," 
 "OPIQ33"  "," "OPIQ34" 
 ;

 PUT HOSPID 13. "," AGECAT 3.  "," SEXCAT 3. "," PAYCAT 3. "," RACECAT 3. "," _TYPE_ 2.  ","
 (TPIQ01 TPIQ02 TPIQ02A TPIQ02B TPIQ04 TPIQ04A TPIQ04B TPIQ04C TPIQ04D TPIQ05-TPIQ08 TPIQ09 TPIQ09A TPIQ09B 
  TPIQ11 TPIQ11A TPIQ11B TPIQ11C TPIQ11D TPIQ12-TPIQ17 TPIQ17A TPIQ17B TPIQ17C 
  TPIQ18-TPIQ25 TPIQ30-TPIQ34) (7.0 ",")
 ","
 (PPIQ08 PPIQ09 PPIQ09A PPIQ09B PPIQ11 PPIQ11A PPIQ11B PPIQ11C PPIQ11D PPIQ12-PPIQ17 PPIQ17A PPIQ17B PPIQ17C PPIQ18-PPIQ25 PPIQ30-PPIQ34) (13.2 ",")
 ","
 (OPIQ08 OPIQ09 OPIQ09A OPIQ09B OPIQ11 OPIQ11A OPIQ11B OPIQ11C OPIQ11D OPIQ12-OPIQ17 OPIQ17A OPIQ17B OPIQ17C  OPIQ18-OPIQ25 OPIQ30-OPIQ34) (12.10 ",")
 ;
 RUN;

 %END;

 %MEND TEXTP2;

 %TEXTP2;
