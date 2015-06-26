/******************************************************************/
/* Title:       CCS SUMMARY STATISTICS PROGRAM                    */
/*              SOFTWARE, VERSION 1.2                             */
/*                                                                */
/* PROGRAM:     MULTI_CCS_SUMMARY_PROGRAM.SAS                     */
/*                                                                */
/* Description: This program prints a report that shows the number*/
/*              and percent of discharges for each CCS Category.  */
/*              The report works off of the primary diagnosis or  */
/*              the primary procedure and should be used after    */
/*              the Multi-Level CCS DX Categories are assigned by */
/*              the CCS load program (Multi_CCS_Load_Program.sas).*/
/*                                                                */
/******************************************************************/

OPTIONS nodate FormChar='|----|+|---+=|#/\<>*';

LIBNAME  IN1     'C:\SASDATA';                   * Location of input discharge data;
LIBNAME  OUT1    'C:\SASDATA\';                  * Location of output data;
FILENAME INRAW1  'C:\CCS\DXMLABEL-13.CSV';       * Path & name of DX CCS Category Labels file ;
FILENAME INRAW2  'C:\CCS\PRMLABEL-09.CSV';       * Path & name of PR CCS Category Labels file ;

/*******************************************************************/
/*  Macro Variables that must be set to define the characteristics */
/*  of your SAS discharge data. Change these values to indicate    */
/*  the name of your SAS file and whether you want to report on    */
/*  diagnoses and/or procedures.                                   */
/*******************************************************************/
* Input SAS file member name;                                    %LET CORE=NEW_MULTI_CCS;
* Run Report on Primary Diagnosis or Procedure? ('DX'/'PR');     %LET RPT = 'DX';


%Macro CCSFreq;
/******************* CREATE LABEL FORMAT ****************************/
/*  SAS Load the CCS multi-level categories and labels and create a */
/*  SAS format that will be used to print the CCS category label in */
/*  the report.                                                     */
/********************************************************************/
DATA LABELS;
   %if &RPT='DX' %then %do;   
   INFILE INRAW1 DSD DLM=',' END = EOF FIRSTOBS=2;
	%end;
   %else %if &RPT='PR' %then %do; 
	INFILE INRAW2 DSD DLM=',' END = EOF FIRSTOBS=2;
   %end;
	INPUT
	   START      : $9.
		LABEL      : $99.
	;
   RETAIN HLO " ";
   FMTNAME = "$CCSLBL" ;
   TYPE    = "C" ;
   OUTPUT;

   IF EOF THEN DO ;
      START = " " ;
		LABEL = " " ;
      HLO   = "O";
      OUTPUT ;
   END ;
RUN;

PROC FORMAT LIB=WORK  CNTLIN = LABELS ;
RUN;


/************************ GET STATISTICS ****************************/
/*  Run frequencies on your SAS file containing the multi-level DX  */
/*  and/or PR CCS variables. Capture the frequencies into files and */
/*  combine them for reporting. The frequencies use the variable    */
/*  names for the multi-level primary DX/PR that are created in the */
/*  CCS Load program. You may need to change the variable names if  */
/*  you use custom code to create your multi-level CCS variables.   */
/********************************************************************/
PROC FREQ DATA=OUT1.&CORE;
    %if &RPT='DX' %then %do;
	    TABLES L1DCCS1 / MISSING LIST NOPRINT OUT=DXSUM1;
       TABLES L2DCCS1 / MISSING LIST NOPRINT OUT=DXSUM2;
       TABLES L3DCCS1 / MISSING LIST NOPRINT OUT=DXSUM3;
       TABLES L4DCCS1 / MISSING LIST NOPRINT OUT=DXSUM4;
	 %end;
    %else %if &RPT='PR' %then %do;
	    TABLES L1PCCS1 / MISSING LIST NOPRINT OUT=PRSUM1;
       TABLES L2PCCS1 / MISSING LIST NOPRINT OUT=PRSUM2;
       TABLES L3PCCS1 / MISSING LIST NOPRINT OUT=PRSUM3;
	 %end;
RUN;

DATA SUMMARY1 (KEEP=VAR1 COUNT PERCENT);
   SET 
	   %if &RPT='DX' %then %do;
	   DXSUM1 DXSUM2 DXSUM3 DXSUM4 
		%end;
      %else %if &RPT='PR' %then %do;	
		PRSUM1 PRSUM2 PRSUM3
		%end;
		;
	LENGTH VAR1 $9.; 
	%if &RPT='DX' %then %do;
	IF L1DCCS1 NE '' THEN DO;
	   VAR1=L1DCCS1;
		OUTPUT;
   END;
	ELSE IF L2DCCS1 NE '' THEN DO;
	   VAR1=L2DCCS1;
		OUTPUT;
	END;
	ELSE IF L3DCCS1 NE '' THEN DO;
	   VAR1=L3DCCS1;
		OUTPUT;
	END;
	ELSE IF L4DCCS1 NE '' THEN DO;
	   VAR1=L4DCCS1;
		OUTPUT;
	END;
   %end;
	%else %if &RPT='PR' %then %do;
	IF L1PCCS1 NE '' THEN DO;
	   VAR1=L1PCCS1;
	   OUTPUT;
   END;
	ELSE IF L2PCCS1 NE '' THEN DO;
	   VAR1=L2PCCS1;
		OUTPUT;
	END;
	ELSE IF L3PCCS1 NE '' THEN DO;
	   VAR1=L3PCCS1;
		OUTPUT;
	END;
   %end;
RUN;


/************************ MAKE SORT ORDER/LABELS ********************/
/*  Take the file of multi-level CCS frequencies and sort it in     */
/*  proper order. Create CCS Category labels using the format from  */
/*  made earlier. Run Proc Report to get the output.                */
/********************************************************************/
DATA SUMMARY2 ;
   LENGTH SORT1-SORT4 3. 
	CCSLABEL $60. ;
   SET SUMMARY1;
		SORT1=SCAN(VAR1,1);
		SORT2=SCAN(VAR1,2);
		SORT3=SCAN(VAR1,3);
	 	SORT4=SCAN(VAR1,4);
	   CCSLABEL = PUT(VAR1,$CCSLBL.);
RUN;

PROC SORT DATA=SUMMARY2 ;
   BY SORT1 SORT2 SORT3 SORT4 ;
RUN;

PROC REPORT DATA=SUMMARY2 HEADLINE  ;
   COLUMN VAR1 CCSLABEL COUNT PERCENT;
	DEFINE VAR1 / DISPLAY 'CCS Category' ;
	DEFINE CCSLABEL / DISPLAY 'CCS Label';
	DEFINE COUNT / ANALYSIS width=10  'Number of Discharges';
	DEFINE PERCENT / ANALYSIS width=10 FORMAT=4.1 '% of Discharges';
	TITLE1 "CCS SOFTWARE";
	%if &RPT='DX' %then %do;
	   TITLE2 "Diagnosis (CCS category number and name)";
	%end;
	%else %if &RPT='PR' %then %do;
	   TITLE2 "Procedure (CCS category number and name)";
	%end;
RUN;
%Mend CCSFreq;
%CCSFreq;
