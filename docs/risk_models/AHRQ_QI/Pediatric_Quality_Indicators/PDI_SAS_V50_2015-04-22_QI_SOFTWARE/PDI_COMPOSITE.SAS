*===================================================================;
*  Title:  PDI COMPOSITE CONSTRUCTS COMPOSITE MEASURE FOR 
*          PEDIATRIC QUALITY INDICATORS
*
*  Description:
*         CONSTRUCTS A COMPOSITE MEASURE BASED ON USER DEFINED
*         WEIGHTS (DEFAULT IS NQF WEIGHTS)
*
*          >>>  VERSION 5.0 - MARCH, 2015    <<<
*
*  USER NOTE:  Make sure you have run through PDSASP3.SAS 
*              BEFORE running this program.
*
*===================================================================;
LIBNAME IN1 "C:\PATHNAME";
LIBNAME OUT1 "C:\PATHNAME";
FILENAME MSXC "C:\PATHNAME\MSXPDC50.TXT";
FILENAME MSXCA "C:\PATHNAME\MXPDC50.TXT";

%LET INFILE = PDP3;
%LET OUTFILE = PDC3;
%LET PRINT = 1;

%LET USEPOA = 1;


%MACRO PDC;

%IF &USEPOA. = 0 %THEN %DO;
   %LET MSX = MSXCA;
   %LET ARRY = ARRYP3;
%END;
%ELSE %DO;
   %LET MSX = MSXC;
   %LET ARRY = ARRYP3;
%END;

*===================================================================;
*  PEDIATRIC QUALITY FOR SELECTED INDICATORS                      --;
*  ASSIGN INDICATOR WEIGHTS                                       --;
*    WEIGHTS MUST SUM TO 1.0                                      --;
*===================================================================;
%IF &USEPOA. = 0 %THEN %DO;

%LET W01 = 0.24230;
%LET W02 = 0.041501;
%LET W05 = 0.058717;
%LET W08 = 0.0000;
%LET W09 = 0.0000;
%LET W10 = 0.25208;
%LET W11 = 0.009242479;
%LET W12 = 0.39616;

%END;
%ELSE %DO;

%LET W01 = 0.28497;
%LET W02 = 0.016440;
%LET W05 = 0.065046;
%LET W08 = 0.0000;
%LET W09 = 0.0000;
%LET W10 = 0.25876;
%LET W11 = 0.012152;
%LET W12 = 0.36264;

%END;

*===================================================================;
*  COMPUTE COMPOSITE                                              --;
*===================================================================;

DATA OUT1.&OUTFILE.(KEEP=HOSPID COMP1 COMP1VAR COMP1SE COMP1WHT COMP1LB COMP1UB);
SET IN1.&INFILE.;

%INCLUDE &MSX.;

ARRAY ARRY4{8} 
   RPPD01 RPPD02 RPPD05 RPPD08 RPPD09 RPPD10 RPPD11 RPPD12
;

ARRAY ARRY6{8} 
   VPPD01 VPPD02 VPPD05 VPPD08 VPPD09 VPPD10 VPPD11 VPPD12
;

ARRAY ARRY7{8} 
   APPD01 APPD02 APPD05 APPD08 APPD09 APPD10 APPD11 APPD12
;

ARRAY ARRY12{8} _temporary_
   (&W01. &W02. &W05. &W08. &W09. &W10. &W11. &W12.)
;

ARRAY ARRY13{8} 
   PPPD01 PPPD02 PPPD05 PPPD08 PPPD09 PPPD10 PPPD11 PPPD12
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

COMP1SE  = SQRT(COMP1VAR);
COMP1LB  = COMP1 - 1.96* COMP1SE;
COMP1UB  = COMP1 + 1.96* COMP1SE;



LABEL
  COMP1    = 'PDI 19 Pediatric Patient Safety for Selected Indicators'
  COMP1VAR = 'PDI 19 Pediatric Patient Safety for Selected Indicators (Variance)'
  COMP1SE  = 'PDI 19 Pediatric Patient Safety for Selected Indicators (SE)'
  COMP1WHT = 'PDI 19 Pediatric Patient Safety for Selected Indicators (Weighted Denominator)'
  COMP1LB  = 'PDI 19 Pediatric Patient Safety for Selected Indicators (Lower CL)'
  COMP1UB  = 'PDI 19 Pediatric Patient Safety for Selected Indicators (Upper CL)';

RUN;

%MEND;

%PDC;

%MACRO PRT;

%IF &PRINT. = 1 %THEN %DO;

PROC PRINT DATA=OUT1.&OUTFILE.;
TITLE 'PEDIATRIC QUALITY INDICATOR COMPOSITE';
VAR HOSPID
    COMP1 COMP1VAR COMP1SE COMP1WHT;
RUN;

%END;

%MEND;

%PRT;
