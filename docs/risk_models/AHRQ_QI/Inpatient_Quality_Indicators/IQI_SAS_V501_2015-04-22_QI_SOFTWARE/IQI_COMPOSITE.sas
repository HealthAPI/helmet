*===================================================================;
*  Title:  IQI COMPOSITE CONSTRUCTS COMPOSITE MEASURES FOR 
*          INPATIENT QUALITY INDICATORS
*
*  Description:
*         CONSTRUCTS TWO COMPOSITE MEASURES BASED ON USER DEFINED
*         WEIGHTS (DEFAULT IS NQF WEIGHTS)
*
*          >>>  VERSION 5.0 - MARCH 2015  <<<
*
*  USER NOTE:  Make sure you have run through IQSASP3.SAS 
*              BEFORE running this program.
*
*===================================================================;
LIBNAME IN1 "c:\pathname";
LIBNAME OUT1 "c:\pathname";
FILENAME MSXC "c:\pathname\MSXIQC50.TXT";
FILENAME MSXCA "c:\pathname\MXIQC50.TXT";

%LET INFILE = IQP3;
%LET OUTFILE = IQC3;
%LET PRINT = 1;

%LET USEPOA = 1;

%MACRO IQC;

%IF &USEPOA. = 0 %THEN %DO;
   %LET MSX = MSXCA;
   %LET ARRY = ARRYP3;
%END;
%ELSE %DO;
   %LET MSX = MSXC;
   %LET ARRY = ARRYP3;
%END;

*===================================================================;
*  MORTALITY FOR FOR SELECTED PROCEDURES                          --;
*  ASSIGN INDICATOR WEIGHTS                                       --;
*    WEIGHTS MUST SUM TO 1.0                                      --;
*===================================================================;
%LET W08 = 0.003674072;
%LET W09 = 0.013290;
%LET W11 = 0.030218;
%LET W12 = 0.15047;
%LET W13 = 0.10921;
%LET W14 = 0.23151;
%LET W30 = 0.38387;
%LET W31 = 0.067745;

*===================================================================;
*  MORTALITY FOR FOR SELECTED CONDITIONS                          --;
*  ASSIGN INDICATOR WEIGHTS                                       --;
*    WEIGHTS MUST SUM TO 1.0                                      --;
*===================================================================;
%LET W15 = 0.1537;
%LET W16 = 0.25529;
%LET W17 = 0.15452;
%LET W18 = 0.13872;
%LET W19 = 0.069469;
%LET W20 = 0.22829;

*===================================================================;
*  COMPUTE COMPOSITE                                              --;
*===================================================================;

DATA OUT1.&OUTFILE.(KEEP=HOSPID COMP1 COMP1VAR COMP1SE COMP1WHT COMP1LB COMP1UB
                                COMP2 COMP2VAR COMP2SE COMP2WHT COMP2LB COMP2UB);
SET IN1.&INFILE.;

%INCLUDE &MSX.;

ARRAY ARRY4{14} 
   RPIQ08 RPIQ09 RPIQ11 RPIQ12 RPIQ13 RPIQ14 RPIQ30 RPIQ31
   RPIQ15 RPIQ16 RPIQ17 RPIQ18 RPIQ19 RPIQ20
;

ARRAY ARRY6{14} 
   VPIQ08 VPIQ09 VPIQ11 VPIQ12 VPIQ13 VPIQ14 VPIQ30 VPIQ31
   VPIQ15 VPIQ16 VPIQ17 VPIQ18 VPIQ19 VPIQ20
;

ARRAY ARRY7{14} 
   APIQ08 APIQ09 APIQ11 APIQ12 APIQ13 APIQ14 APIQ30 APIQ31
   APIQ15 APIQ16 APIQ17 APIQ18 APIQ19 APIQ20
;

ARRAY ARRY12{14} _temporary_
   (&W08. &W09. &W11. &W12. &W13. &W14. &W30. &W31.
    &W15. &W16. &W17. &W18. &W19. &W20.)
;

ARRAY ARRY13{14} 
   PPIQ08 PPIQ09 PPIQ11 PPIQ12 PPIQ13 PPIQ14 PPIQ30 PPIQ31
   PPIQ15 PPIQ16 PPIQ17 PPIQ18 PPIQ19 PPIQ20
;

DO I = 1 TO 8;
   IF ARRY13(I) GE 3 THEN DO;
      ARRY6(I) = ARRY6(I) / (&ARRY.(I) * &ARRY.(I));
      DO J = I TO 8;
         IDX = ARRY10(I,J);
         IF I = J THEN ARRY7(I) = ARRY1(IDX) / (ARRY1(IDX) + ARRY6(I));
      END;
   END;
   ELSE DO;
      DO J = I TO 8;
         IDX = ARRY10(I,J);
         IF I = J THEN ARRY7(I) = 0;
      END;
   END;
END;

DO I = 9 TO 14;
   IF ARRY13(I) GE 3 THEN DO;
      ARRY6(I) = ARRY6(I) / (&ARRY.(I) * &ARRY.(I));
      DO J = I TO 14;
         IDX = ARRY11(I-8,J-8);
         IF I = J THEN ARRY7(I) = ARRY3(IDX) / (ARRY3(IDX) + ARRY6(I));
      END;
   END;
   ELSE DO;
      DO J = I TO 14;
         IDX = ARRY11(I-8,J-8);
         IF I = J THEN ARRY7(I) = 0;
      END;
   END;
END;

COMP1    = 0;
COMP1VAR = 0;
COMP1SE  = 0;
COMP1WHT = 0;

DO I = 1 TO 8;
   IF ARRY13(I) GE 3 THEN DO;
      COMP1 = COMP1 + (ARRY12(I) * (((ARRY4(I) / &ARRY.(I)) * ARRY7(I)) + (1 - ARRY7(I))));
      COMP1WHT = COMP1WHT + (ARRY12(I) * ARRY13(I));
   END;
   ELSE DO;
      COMP1 = COMP1 + ARRY12(I);
      COMP1WHT = COMP1WHT + 0;
   END;
   DO J = I TO 8;
      IDX = ARRY10(I,J);
      IF I = J THEN COMP1VAR = COMP1VAR 
      + (ARRY12(I) * (ARRY1(IDX) * (1 - ARRY7(I))) * ARRY12(J));
      ELSE COMP1VAR = COMP1VAR 
      + (ARRY12(I) * (ARRY1(IDX) * (1 - ARRY7(I)) * (1 - ARRY7(J))) * ARRY12(J));
   END;
END;

COMP2    = 0;
COMP2VAR = 0;
COMP2SE  = 0;
COMP2WHT = 0;

DO I = 9 TO 14;
   IF ARRY13(I) GE 3 THEN DO;
      COMP2 = COMP2 + (ARRY12(I) * (((ARRY4(I) / &ARRY.(I)) * ARRY7(I)) + (1 - ARRY7(I))));
      COMP2WHT = COMP2WHT + (ARRY12(I) * ARRY13(I));
   END;
   ELSE DO;
      COMP2 = COMP2 + ARRY12(I);
      COMP2WHT = COMP2WHT + 0;
   END;
   DO J = I TO 14;
      IDX = ARRY11(I-8,J-8);
      IF I = J THEN COMP2VAR = COMP2VAR 
      + (ARRY12(I) * (ARRY3(IDX) * (1 - ARRY7(I))) * ARRY12(I));
      ELSE COMP2VAR = COMP2VAR 
      + (ARRY12(I) * (ARRY3(IDX) * (1 - ARRY7(I)) * (1 - ARRY7(J))) * ARRY12(J));
   END;
END;

COMP1SE  = SQRT(COMP1VAR);
COMP2SE  = SQRT(COMP2VAR);
COMP1LB  = COMP1 - 1.96* COMP1SE;
COMP1UB  = COMP1 + 1.96* COMP1SE;
COMP2LB  = COMP2 - 1.96* COMP2SE;
COMP2UB  = COMP2 + 1.96* COMP2SE;


LABEL
  COMP1    = 'IQI 90 Mortality for Selected Procedures'
  COMP1VAR = 'IQI 90 Mortality for Selected Procedures (Variance)'
  COMP1SE  = 'IQI 90 Mortality for Selected Procedures (SE)'
  COMP1WHT = 'IQI 90 Mortality for Selected Procedures (Weighted Denominator)'
  COMP2    = 'IQI 91 Mortality for Selected Conditions'
  COMP2VAR = 'IQI 91 Mortality for Selected Conditions (Variance)'
  COMP2SE  = 'IQI 91 Mortality for Selected Conditions (SE)'
  COMP2WHT = 'IQI 91 Mortality for Selected Conditions (Weighted Denominator)'
  COMP1LB  = 'IQI 90 Mortality for Selected Procedures (Lower CL)'
  COMP1UB  = 'IQI 90 Mortality for Selected Procedures (Upper CL)'
  COMP2LB  = 'IQI 91 Mortality for Selected Conditions (Lower CL)'
  COMP2UB  = 'IQI 91 Mortality for Selected Conditions (Upper CL)';

RUN;

%MEND;

%IQC;

%MACRO PRT;

%IF &PRINT. = 1 %THEN %DO;

PROC PRINT DATA=OUT1.&OUTFILE.;
TITLE 'INPATIENT QUALITY INDICATOR COMPOSITES';
VAR HOSPID
    COMP1 COMP1VAR COMP1SE COMP1WHT
    COMP2 COMP2VAR COMP2SE COMP2WHT;
RUN;

%END;

%MEND;

%PRT;
