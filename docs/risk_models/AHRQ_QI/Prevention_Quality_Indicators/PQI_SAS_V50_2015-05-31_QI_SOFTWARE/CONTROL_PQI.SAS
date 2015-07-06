 * ---------------------------------------------------------------- ;
 * ---             VERSION 5.0 - MARCH, 2015                    --- ;
 * ---------------------------------------------------------------- ;
 * The Prevention Quality Indicator (PQI) module of the AHRQ Quality
   Indicators software includes the following three programs, in
   addition to the programs CONTROL_PQI.SAS and PQFMTS.SAS:
        Program 1.   PQSAS1:  Assigns AHRQ Prevention Quality
                        Indicators to inpatient records.
        Program A2.  PQSASA2:  Calculates observed area rates for
                        Prevention Quality Indicators.
        Program A3.  PQSASA3:  Calculates expected, risk-adjusted and
                        smoothed area rates and merges with
                        observed area rates.

******************************************************************* ;
****************************PLEASE READ**************************** ;
******************************************************************* ;
 * The USER MUST modify portions of the following code in order to
   run this software.  With one exception (see NOTE immediately
   following this paragraph), the only changes necessary to run
   this software using your data are changes you make in this
   program (CONTROL_PQI.SAS).  The modifications you make include such
   items as specifying the name and location of your input data
   set, the year of population data to be used, and the name and
   location of output data sets.
 
 * NOTE:  CONTROL_PQI.SAS is written so that you have the option to 
          read in data from and write out data to different 
          locations.  For example, "LIBNAME IN0" points to the 
          location or pathname of your input data set for program
          PQSAS1 and "LIBNAME OUT1" points to the location of the 
          output data set created by the PQSAS1 program.  These 
          locations can be different.  This pattern of allowing 
          you to specify the location of each input and output 
          data set is true for each of the different programs 
          referenced in CONTROL_PQI.SAS.  However, if you wish to read 
          in and write out all data to the same location you can.   
          The easiest way to do this is to make a global 
          change in CONTROL_PQI.SAS, changing "C:\PATHNAME" to the 
          location you wish to use.

 * NOTE:  In each of the three programs included with
          this package, as well as in the program which
          generates formats, there is a line of code that begins
          with "FILENAME CONTROL".  The USER MUST include after
          "FILENAME CONTROL" the location of the CONTROL_PQI.SAS file.

 * Generally speaking, a first-time user of this software would
   proceed as follows:
        1.  Modify CONTROL_PQI.SAS.  (MUST be done.)
        2.  In the program generating needed formats, i.e., in
            PQFMTS.SAS, specify location (path name) of
            CONTROL_PQI.SAS. (MUST be done.)
        3.  Run PQFMTS.SAS.  (MUST be done.)
        4.  In Program 1, i.e., in PQSAS1, specify location
            of CONTROL_PQI.SAS program.  (MUST be done.)
        5.  Run PQSAS1.  (MUST be done.)
        6.  In Program A2, i.e., in PQSASA2, specify location
            of CONTROL_PQI.SAS program.  (MUST be done if going to
            run Program A2.)
        7.  Run PQSASA2.  (MUST have already run Program 1.)
        8.  In Program A3, i.e., in PQSASA3, specify location
            of CONTROL_PQI.SAS program.  (MUST be done if going to
            run Program A3.)
        9.  Run PQSASA3.  (MUST have already run Programs 1 and A2.)


 * ---------------------------------------------------------------- ;
 * ---                       All Programs                       --- ;
 * ---------------------------------------------------------------- ;
TITLE 'TITLE';                                  *<===USER may modify;
LIBNAME LIBRARY 'C:\PATHNAME';                  *<==USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF COUNTY-LEVEL AREAS SHOULD BE CONVERTED TO MAs -- ;
 * ---     0 - County level with U.S. Census FIPS                -- ;
 * ---     1 - County level with Modified FIPS                   -- ;
 * ---     2 - Metro Area level with OMB 1999 definition         -- ;
 * ---     3 - Metro Area level with OMB 2003 definition         -- ;
 * ---------------------------------------------------------------- ;
%LET MALEVL = 0;                                *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * NOTE:  In program A2 and in program A3, the user should select   ;
 *          the population data for the year that best              ;
 *          matches the discharge data.  Data are available for     ;
 *          1995 to 2014.                                           ;
 * ---------------------------------------------------------------- ;
%LET POPYEAR = 2013;                           *<===USER must modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF POPULATION FILE -------------------------------- ;
 * ---------------------------------------------------------------- ;
FILENAME POPFILE  'C:\PATHNAME\POP95T14.TXT'; *<===USER must modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED AT END OF EACH PGM --- ;
 * ---------------------------------------------------------------- ;
%LET PRINT = 0;                                 *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- COMMENT OUT TO CREATE AN UCOMPRESSED FILE                --- ;
 * ---------------------------------------------------------------- ;
OPTIONS COMPRESS=YES;


 * ---------------------------------------------------------------- ;
 * ---                         Program 1                       --- ;
 * ---------------------------------------------------------------- ;
LIBNAME IN0  'C:\PATHNAME';                     *<==USER MUST modify;
LIBNAME OUT1 'C:\PATHNAME';                     *<==USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- MODIFY INPUT AND OUTPUT FILE                             --- ;
 * ---------------------------------------------------------------- ;
 * --- PROGRAM DEFAULT ASSUMES THERE ARE                        --- ;
 * ---     30 DIAGNOSES (DX1-DX30)                              --- ;
 * ---     30 PROCEDURES (PR1-PR30)                             --- ;
 * ---------------------------------------------------------------- ;
 * --- MODIFY NUMBER OF DIAGNOSES AND PROCEDURES VARIABLES      --- ;
 * --- TO MATCH INPUT DATA                                      --- ;
 * ---------------------------------------------------------------- ;
%LET INFILE0  = sids_yyyy;                          *<==USER MUST modify;
%LET OUTFILE1 = PQ1;                            *<===USER may modify;
%LET NDX = 35;                                  *<===USER may modify;
%LET NPR = 30;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * - CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL    --- ;
 * - NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE       --- ;
 * - VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED AFTER --- ;
 * - RUNNING PQSAS1.											--- ;
 * ---------------------------------------------------------------- ;
%LET DELFILE1  = PQI_DELETED;                   *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---               Program A2 - Observed Rates                --- ;
 * ---------------------------------------------------------------- ;
LIBNAME IN1 'C:\PATHNAME';                     *<===USER MUST modify;
LIBNAME OUTA2 'C:\PATHNAME';                   *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- TYPELEVL indicates the levels (or _TYPE_) of             --- ;
 * --- summarization to be kept in the output.                  --- ;
 * ---                                                          --- ;
 * ---  TYPELEVL      stratification                            --- ;
 * ---  --------  -------------------------                     --- ;
 * ---     0      OVERALL                                       --- ;
 * ---     1                           RACE                     --- ;
 * ---     2                     SEX                            --- ;
 * ---     3                     SEX * RACE                     --- ;
 * ---     4               AGE                                  --- ;
 * ---     5               AGE *       RACE                     --- ;
 * ---     6               AGE * SEX                            --- ;
 * ---     7               AGE * SEX * RACE                     --- ;
 * ---     8       AREA                                         --- ;
 * ---     9       AREA  *             RACE                     --- ;
 * ---    10       AREA  *       SEX                            --- ;
 * ---    11       AREA  *       SEX * RACE                     --- ;
 * ---    12       AREA  * AGE                                  --- ;
 * ---    13       AREA  * AGE *       RACE                     --- ;
 * ---    14       AREA  * AGE * SEX                            --- ;
 * ---    15       AREA  * AGE * SEX * RACE                     --- ;
 * ---                                                          --- ;
 * --- The default TYPELEVL (0,8) will provide an overall       --- :
 * --- total and an area-level totals.                          --- ;
 * ---                                                          --- ;
 * --- WARNING: TYPELEVL MUST INCLUDE 0 (Overall) and 8 (AREA)  --- ;
 * ---          IF YOU WISH TO SUBSEQUENTLY RUN PROGRAM A3.     --- ;
 * ---                                                          --- ;
 * ---------------------------------------------------------------- ;
%LET TYPELVLA = IN (0,8);                       *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF MICRODATA INPUT (OUTPUT FROM PROGRAM 1) AND --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED RATES.                   --- ;
 * ---------------------------------------------------------------- ;
%LET INFILE1 = PQ1;                             *<===USER may modify;
%LET OUTFILA2 = PQA2;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;
 * --- EXPORT INTO A SPREADSHEET.                               --- ;
 * ---------------------------------------------------------------- ;
%LET TEXTA2=0;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;
 * --- OF THE FILE.                                             --- ;
 * ---------------------------------------------------------------- ;
FILENAME PQTEXTA2 'C:\PATHNAME\PQTEXTA2.TXT';   *<===USER may modify;


 * ---------------------------------------------------------------- ;
 * ---      Program A3 - Risk-Adjusted and Smoothed Rates       --- ;
 * ---------------------------------------------------------------- ;
LIBNAME IN1  'C:\PATHNAME';                    *<===USER MUST modify;
LIBNAME INA2  'C:\PATHNAME';                   *<===USER MUST modify;
LIBNAME OUTA3 'C:\PATHNAME';                   *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF COVARIATE FILE.                                - ;
 * --- THIS FILE CONTAINS THE REGRESSION COEFFICIENTS FOR EACH    - ;
 * --- COVARIATE.  THERE IS ONE OBSERVATION PER PREVENTION        - ;
 * --- QUALITY INDICATOR.                                         - ;
 * ---------------------------------------------------------------- ;
 * - SET TO COVPQA50 FOR AGE AND GENDER ADJUSTMENT ONLY (DEFAULT)- ;
 * - SET TO CVPQA50  FOR AGE, GENDER AND SES ADJUSTMENT          - ;
FILENAME COVARA "C:\PATHNAME\COVPQA50.TXT";   *<===USER MUST MODIFY;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF MSX STATISTICS FILE                            - ;
 * --- FILE CONTAINS A SET OF THREE ARRAYS.  THE FIRST ARRAY      - ;
 * ---   FILE CONTAINS A SET OF TWO ARRAYS.  THE FIRST ARRAY      - ;
 * ---   CONTAINS SIGNAL ESTIMATES AND THE SECOND POPULATION      - ;
 * ---   RATES FOR EACH PREVENTION QUALITY INDICATOR.             - ;
 * ---------------------------------------------------------------- ;
 * - SET TO MSXPQA50.TXT FOR AGE AND GENDER ADJUSTMENT ONLY (DEFAULT)- ;
 * - SET TO MXPQA50.TXT FOR AGE, GENDER AND SES ADJUSTMENT          - ;
FILENAME MSXA "C:\PATHNAME\MSXPQA50.TXT";     *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF INPUT RATES FILE (OUTPUT FROM PROGRAM A2) and--- ;
 * --- AREA LEVEL OUTPUT FILE.                                  --- ;
 * ---------------------------------------------------------------- ;
%LET INFILEA2  = PQA2;                          *<===USER may modify;
%LET OUTFILA3  = PQA3;                          *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;
 * --- EXPORT INTO A SPREADSHEET.                               --- ;
 * ---------------------------------------------------------------- ;
%LET TEXTA3=0;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;
 * --- OF THE FILE.                                             --- ;
 * ---------------------------------------------------------------- ;
FILENAME PQTEXTA3 'C:\PATHNAME\PQTEXTA3.TXT';   *<===USER may modify;


 * ---------------------------------------------------------------- ;
 * ---               Program C2 - Condition-specific Rates      --- ;
 * ---------------------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
 * NOTE:  In program C2, the user should select the file with       ;
 *          population data for the year that best matches the      ;
 *          discharge data.                                         ;
 * ---------------------------------------------------------------- ;
LIBNAME OUTC2 'C:\PATHNAME';                   *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF MICRODATA INPUT (OUTPUT FROM PROGRAM 1) AND --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED RATES.                   --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILC2 = PQC2;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF POPULATION FILE -------------------------------- ;
 * ---------------------------------------------------------------- ;
FILENAME POPFILC2 'C:\PATHNAME\QICTYC14.TXT';   *<===USER must modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;
 * --- EXPORT INTO A SPREADSHEET.                               --- ;
 * ---------------------------------------------------------------- ;
%LET TEXTC2=0;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;
 * --- OF THE FILE.                                             --- ;
 * ---------------------------------------------------------------- ;
FILENAME PQTEXTC2 'C:\PATHNAME\PQTEXTC2.TXT';   *<===USER may modify;
