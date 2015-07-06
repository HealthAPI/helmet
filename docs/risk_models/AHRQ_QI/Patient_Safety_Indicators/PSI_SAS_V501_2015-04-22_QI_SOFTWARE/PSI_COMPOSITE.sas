*================== PROGRAM: PSI_COMPOSITE.SAS =====================;
*===================================================================;
*  Title:  PSI COMPOSITE CONSTRUCTS COMPOSITE MEASURE FOR 
*          PATIENT SAFETY INDICATORS
*
*  Description:
*         CONSTRUCTS A COMPOSITE MEASURE BASED ON USER DEFINED
*         WEIGHTS (DEFAULT IS NQF WEIGHTS)
*
*          >>>  VERSION 5.0 - MARCH, 2015 <<<
*
*  USER NOTE:  Make sure you have run PSSASP3.SAS 
*              BEFORE running this program.
*
*  
*===================================================================;
LIBNAME IN1 "C:\PATHNAME";
LIBNAME OUT1 "C:\PATHNAME";
FILENAME MSXC "C:\PATHNAME\MSXPSC50.TXT";
FILENAME MSXCA "C:\PATHNAME\MXPSC50.TXT";

%LET INFILE = PSP3;
%LET OUTFILE = PSC3;
%LET PRINT = 1;

%LET USEPOA = 1;

%MACRO PSC;

%IF &USEPOA. = 0 %THEN %DO;
   %LET MSX = MSXCA;
   %LET ARRY = ARRYP3;
%END;
%ELSE %DO;
   %LET MSX = MSXC;
   %LET ARRY = ARRYP3;
%END;

*===================================================================;
*  PATIENT SAFETY FOR SELECTED INDICATORS                         --;
*  ASSIGN INDICATOR WEIGHTS                                       --;
*  WEIGHTS MUST SUM TO 1.0                                      --;
*===================================================================;

%IF &USEPOA. = 0 %THEN %DO;

%LET W03 = 0.32663;
%LET W06 = 0.050252;
%LET W07 = 0.030051;
%LET W08 = 0.003758441;
%LET W09 = 0.0000;
%LET W10 = 0.0000;
%LET W11 = 0.0000;
%LET W12 = 0.28677;
%LET W13 = 0.040466;
%LET W14 = 0.009294217;
%LET W15 = 0.25278;

%END;
%ELSE %DO;

%LET W03 = 0.033006;
%LET W06 = 0.075069;
%LET W07 = 0.037684;
%LET W08 = 0.001796069;
%LET W09 = 0.0000;
%LET W10 = 0.0000;
%LET W11 = 0.0000;
%LET W12 = 0.3379;
%LET W13 = 0.057308;
%LET W14 = 0.018205;
%LET W15 = 0.43903;

%END;

*===================================================================;
*  COMPUTE COMPOSITE                                              --;
*===================================================================;

DATA OUT1.&OUTFILE.(KEEP=HOSPID COMP1 COMP1VAR COMP1SE COMP1WHT COMP1LB COMP1UB);
SET IN1.&INFILE.;

%INCLUDE &MSX.;

ARRAY ARRY4{11} 
   RPPS03 RPPS06 RPPS07 RPPS08 RPPS09 RPPS10
   RPPS11 RPPS12 RPPS13 RPPS14 RPPS15
;

ARRAY ARRY6{11} 
   VPPS03 VPPS06 VPPS07 VPPS08 VPPS09 VPPS10 
   VPPS11 VPPS12 VPPS13 VPPS14 VPPS15
;

ARRAY ARRY7{11} 
   APPS03 APPS06 APPS07 APPS08 APPS09 APPS10 
   APPS11 APPS12 APPS13 APPS14 APPS15
;

ARRAY ARRY12{11} _temporary_
   (&W03. &W06. &W07. &W08. &W09. &W10. 
    &W11. &W12. &W13. &W14. &W15.)
;

ARRAY ARRY13{11} 
   PPPS03 PPPS06 PPPS07 PPPS08 PPPS09 PPPS10 
   PPPS11 PPPS12 PPPS13 PPPS14 PPPS15
;

DO I = 1 TO 11;
   IF ARRY13(I) GE 3 THEN DO;
      ARRY6(I) = ARRY6(I) / (&ARRY.(I) * &ARRY.(I));
      DO J = I TO 11;
         IDX = ARRY10(I,J);
         IF I = J THEN ARRY7(I) = ARRY1(IDX) / (ARRY1(IDX) + ARRY6(I));
      END;
   END;
   ELSE DO;
      DO J = I TO 11;
         IDX = ARRY10(I,J);
         IF I = J THEN ARRY7(I) = 0;
      END;
   END;
END;

COMP1    = 0;
COMP1VAR = 0;
COMP1SE  = 0;
COMP1WHT = 0;

DO I = 1 TO 11;
   IF ARRY13(I) GE 3 THEN DO;
      COMP1 = COMP1 + (ARRY12(I) * (((ARRY4(I) / &ARRY.(I)) * ARRY7(I)) + (1 - ARRY7(I))));
      COMP1WHT = COMP1WHT + (ARRY12(I) * ARRY13(I));
   END;
   ELSE DO;
      COMP1 = COMP1 + ARRY12(I);
      COMP1WHT = COMP1WHT + 0;
   END;
   DO J = I TO 11;
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
  COMP1    = 'PSI 90 Patient Safety for Selected Indicators'
  COMP1VAR = 'PSI 90 Patient Safety for Selected Indicators (Variance)'
  COMP1SE  = 'PSI 90 Patient Safety for Selected Indicators (SE)'
  COMP1WHT = 'PSI 90 Patient Safety for Selected Indicators (Weighted Denominator)'
  COMP1LB  = 'PSI 90 Patient Safety for Selected Indicators (Lower CL)'
  COMP1UB  = 'PSI 90 Patient Safety for Selected Indicators (Upper CL)';

RUN;

%MEND;

%PSC;

%MACRO PRT;

%IF &PRINT. = 1 %THEN %DO;

PROC MEANS DATA=OUT1.&OUTFILE. N MEAN;
TITLE 'PATIENT SAFETY INDICATOR COMPOSITE';
VAR COMP1 COMP1VAR COMP1SE COMP1WHT;
RUN;

%END;

%MEND;

%PRT;
