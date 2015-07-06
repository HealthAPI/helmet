 * ---------------------------------------------------------------- ;
 * ---                 VERSION 5.0 - MARCH, 2015                --- ;
 * ---------------------------------------------------------------- ;
 * The Inpatient Quality Indicator (IQI) module of the AHRQ Quality
   Indicators software includes the following five programs, in
   addition to the programs CONTROL_IQI.SAS and IQFMTS.SAS:
        Program 1.   IQSAS1:  Assigns HCUP Inpatient Quality
                       Indicators to inpatient records.
        Program P2.  IQSASP2:  Calculates observed provider rates
                       for Inpatient Quality Indicators.
        Program P3.  IQSASP3:  Calculates risk-adjusted, smoothed
                       and expected provider rates and merges with 
                       observed provider rates.
        Program A2.  IQSASA2:  Calculates observed area rates for
                       Inpatient Quality Indicators.
        Program A3.  IQSASA3:  Calculates risk-adjusted, smoothed
                       and expected area rates and merges with 
                       observed area rates.

******************************************************************* ;
****************************PLEASE READ**************************** ;
******************************************************************* ;
 * The USER MUST modify portions of the following code in order to
   run this software.  With one exception (see NOTE immediately
   following this paragraph), the only changes necessary to run
   this software using your data are changes you make in this
   program (CONTROL_IQI.SAS). The modifications you make include such
   items as specifying the name and location of your input data
   set, the year of population data to be used, and the name and
   location of output data sets.
 
 * NOTE:  CONTROL_IQI.SAS is written so that you have the option to 
          read in data from and write out data to different 
          locations.  For example, "LIBNAME IN0" points to the 
          location or PATHNAME of your input data set for program
          IQSAS1 and "LIBNAME OUT1" points to the location of the 
          output data set created by the IQSAS1 program.  These 
          locations can be different.  This pattern of allowing 
          you to specify the location of each input and output 
          data set is true for each of the different programs 
          referenced in CONTROL_IQI.SAS.  However, if you wish to read 
          in and write out all data to the same location you can.   
          The easiest way to do this is to make a global 
          change in CONTROL_IQI.SAS, changing "C:\PATHNAME" to the 
          location you wish to use.
 * NOTE:  In each of the five programs included with this
          package, as well as in the program which generates
          formats, there is a line of code that begins with
          "FILENAME CONTROL".  The USER MUST include after
          "FILENAME CONTROL" the location of the CONTROL_IQI.SAS file.

 * Generally speaking, a first-time user of this software would
   proceed as outlined below.  If the input file does not include fields for 
   APR-DRGs, the APR-DRG Grouper software should be run on the discharge data 
   before running the IQI SAS programs:
        1.  Modify CONTROL_IQI.SAS.  (MUST be done.)
        2.  In the program generating needed formats, i.e., in
            IQFMTS.SAS, specify location (path name) of
            CONTROL_IQI.SAS. (MUST be done.)
        3.  Run IQFMTS.SAS.  (MUST be done.)
        4.  In Program 1, i.e., in IQSAS1, specify location
            of CONTROL_IQI.SAS program.  (MUST be done.)
        5.  Run IQSAS1.  (MUST be done.)
        6.  If you want to generate provider-level Inpatient Quality
            Indicators:
                a.  In Program P2, i.e., in IQSASP2, specify location
            of CONTROL_IQI.SAS program.  (MUST be done if going to
            run Program P2.)
                b.  Run IQSASP2.  (MUST have already run Program 1.)
                c.  In Program P3, i.e., in IQSASP3, specify location
            of CONTROL_IQI.SAS program.  (MUST be done if going to
            run Program P3.)
                d.  Run IQSASP3.  (MUST have already run Programs 1
                    and P2.)
        7.  If you want to generate area-level Inpatient Quality
            Indicators:
                a.  In Program A2, i.e., in IQSASA2, specify location
            of CONTROL_IQI.SAS program.  (MUST be done if going to
            run Program A2.)
                b.  Run IQSASA2.  (MUST have already run Program 1.)
                c.  In Program A3, i.e., in IQSASA3, specify location
            of CONTROL_IQI.SAS program.  (MUST be done if going to
            run Program A3.)
                d.  Run IQSASA3.  (MUST have already run Programs
                    1 and A2.)

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
FILENAME POPFILE  'C:\PATHNAME\pop95t14.txt';   *<===USER must modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED AT END OF EACH PGM --- ;
 * ---------------------------------------------------------------- ;
%LET PRINT   = 0;                               *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- COMMENT OUT TO CREATE AN UCOMPRESSED FILE                --- ;
 * ---------------------------------------------------------------- ;
OPTIONS COMPRESS=YES;

 * ---------------------------------------------------------------- ;
 * ---                         Program 1                        --- ;
 * ---------------------------------------------------------------- ;
LIBNAME IN0  'C:\PATHNAME';                     *<==USER MUST modify;
LIBNAME OUT1  'C:\PATHNAME';                    *<==USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- MODIFY INPUT AND OUTPUT FILE                             --- ;
 * ---------------------------------------------------------------- ;
 * --- PROGRAM DEFAULT ASSUMES THERE ARE                        --- ;
 * ---     30 DIAGNOSES (DX1-DX30)                              --- ;
 * ---     30 PROCEDURES (PR1-PR30)                             --- ;
 * ---------------------------------------------------------------- ;
 * --- MODIFY NUMBER OF DIAGNOSES, PROCEDURES AND RELATED       --- ;
 * --- VARIABLES TO MATCH INPUT DATA                            --- ;
 * Note: If the input file does not include POA data, the QI    --- ;
 *       software will assume the outcome of interest occurred  --- ; 
 *       in the hospital.                                       --- ;
 * ---------------------------------------------------------------- ;
%LET INFILE0  = sids_yyyy;                      *<==USER MUST modify;
%LET OUTFILE1 = IQ1;                            *<===USER may modify;
%LET NDX = 35;                                  *<===USER may modify;
%LET NPR = 30;                                  *<===USER may modify;
%LET USEPOA = 1;                                *<===USER may modify;
 * ---------------------------------------------------------------- ;
 * - SET PRDAY TO 1 IF DATA AVAILABLE REGARDING NUMBER OF DAYS  --- ;
 * - FROM ADMISSION TO SECONDARY PROCEDURES                     --- ;
 * ---------------------------------------------------------------- ;
%LET PRDAY  = 1;                                *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
 * --- IF PLANNING TO GENERATE PROVIDER-LEVEL INPATIENT QUALITY --- ;
 * --- INDICATORS AND IF INPUT DATA SET CONTAINS APR-DRG,       --- ;
 * --- SEVERITY SUBCLASS, AND RISK OF MORTALITY SUBCLASS        --- ;
 * --- VARIABLES, SET FLAG (APRDRGFG) AND SET NAME OF APR-DRG   --- ;
 * --- (APRDRG), SEVERITY SUBCLASS (SEVERE), AND RISK OF        --- ;
 * --- SUBCLASS (MORTAL) VARIABLES.                             --- ;
 * ---------------------------------------------------------------- ;
%LET APRDIR = C:\PATHNAME\AHRQAPRLimitedDLL;   *<=may modify;
%LET APRDRGFG = 1;                              *<===USER may modify;
%LET APRDRG  = APR_DRG;               *<===SET TO 0 IF NOT AVAILABLE;
%LET MORTAL  = APRDRG_RISK_MORTALITY; *<===SET TO 0 IF NOT AVAILABLE;
%LET XMORTAL = XPRDRG_RISK_MORTALITY; *<===SET TO 0 IF NOT AVAILABLE;

 * ---------------------------------------------------------------- ;
 * - CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL    --- ;
 * - NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE       --- ;
 * - VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED AFTER --- ;
 * - RUNNING IQSAS1.											--- ;
 * ---------------------------------------------------------------- ;
%LET DELFILE1  = IQI_DELETED;                   *<===USER may modify;

 * =================================================================;
 * ============PROVIDER-LEVEL INPATIENT QUALITY INDICATORS==========;
 * =================================================================;
 * ---                   Program P2-Observed Rates              --- ;
 * ---------------------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
LIBNAME IN1 'C:\PATHNAME';                     *<===USER MUST modify;
LIBNAME OUTP2 'C:\PATHNAME';                   *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- TYPELVLP indicates the levels (or _TYPE_) of             --- ;
 * --- summarization to be kept in the output.                  --- ;
 * ---                                                          --- ;
 * ---  TYPELVLP      stratification                            --- ;
 * ---  --------  ------------------------------------          --- ;
 * ---     0      overall                                       --- ;
 * ---     1                                      race          --- ;
 * ---     2                              payer                 --- ;
 * ---     3                              payer * race          --- ;
 * ---     4                        sex                         --- ;
 * ---     5                        sex         * race          --- ;
 * ---     6                        sex * payer                 --- ;
 * ---     7                        sex * payer * race          --- ;
 * ---     8                  age                               --- ;
 * ---     9                  age               * race          --- ;
 * ---    10                  age       * payer                 --- ;
 * ---    11                  age       * payer * race          --- ;
 * ---    12                  age * sex                         --- ;
 * ---    13                  age * sex         * race          --- ;
 * ---    14                  age * sex * payer                 --- ;
 * ---    15                  age * sex * payer * race          --- ;
 * ---    16       provider                                     --- ;
 * ---    17       provider                     * race          --- ;
 * ---    18       provider             * payer                 --- ;
 * ---    19       provider             * payer * race          --- ;
 * ---    20       provider       * sex                         --- ;
 * ---    21       provider       * sex         * race          --- ;
 * ---    22       provider       * sex * payer                 --- ;
 * ---    23       provider       * sex * payer * race          --- ;
 * ---    24       provider * age                               --- ;
 * ---    25       provider * age               * race          --- ;
 * ---    26       provider * age       * payer                 --- ;
 * ---    27       provider * age       * payer * race          --- ;
 * ---    28       provider * age * sex                         --- ;
 * ---    29       provider * age * sex         * race          --- ;
 * ---    30       provider * age * sex * payer                 --- ;
 * ---    31       provider * age * sex * payer * race          --- ;
 * ---                                                          --- ;
 * --- The default TYPELVLP (0,16) will provide an overall      --- :
 * --- total and a provider-level total.                        --- ;
 * ---                                                          --- ;
 * ---------------------------------------------------------------- ;
%LET TYPELVLP = IN (0,16);                      *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF MICRODATA INPUT (OUTPUT FROM PROGRAM 1) AND  --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED PROVIDER RATES.          --- ;
 * ---------------------------------------------------------------- ;
%LET INFILE1 = IQ1;                             *<===USER may modify;
%LET OUTFILP2 = IQP2;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;
 * --- EXPORT INTO A SPREADSHEET.                               --- ;
 * ---------------------------------------------------------------- ;
%LET TEXTP2=0;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;
 * --- OF THE FILE.                                             --- ;
 * ---------------------------------------------------------------- ;
FILENAME IQTEXTP2 'C:\PATHNAME\IQTEXTP2.TXT';  *<===USER MUST modify;


 * ---------------------------------------------------------------- ;
 * ---       Program P3-Risk-Adjusted and Smooothed Rates       --- ;
 * ---------------------------------------------------------------- ;
 * ---------------------------------------------------------------- ;
LIBNAME INP2 'C:\PATHNAME';                    *<===USER MUST modify;
LIBNAME OUTP3 'C:\PATHNAME';                   *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF RISK ADJUSTMENT VARIABLE CREATION PROGRAM      - ;
 * ---------------------------------------------------------------- ;
FILENAME MAKCOVAR  'C:\PATHNAME\MakeVars_IQI.sas' ;  *<==MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF RISK ADJUSTMENT PARAMETERS DIRECTORY           - ;
 * ---------------------------------------------------------------- ;
%LET RADIR = C:\PATHNAME\IQI_GEE_Input_Files;  *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF MSX STATISTICS FILE                            - ;
 * ---   FILE CONTAINS A SET OF TWO ARRAYS.  THE FIRST ARRAY      - ;
 * ---   CONTAINS SECOND SIGNAL VARIANCE ESTIMATES,               - ;
 * ---   AND THE SECOND MEAN PROVIDER RATES FOR EACH INPATIENT    - ;
 * ---   QUALITY INDICATOR.                                       - ;
 * --- If you select USEPOA=0 then comment out the POA MSXP file  - ;
 * --- and uncomment the NOPOA MSXP file.                         - ;
 * ---------------------------------------------------------------- ;
FILENAME MSXP 'C:\PATHNAME\MSXIQP50.TXT';       *<===USER MUST modify;
*FILENAME MSXP 'C:\PATHNAME\MSXIQP50_NOPOA.TXT';*<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF INPUT RATES FILE (OUTPUT FROM PROGRAM P2) AND  - ;
 * --- PROVIDER LEVEL OUTPUT FILE.                                - ;
 * ---------------------------------------------------------------- ;
%LET INFILEP2 = IQP2;                           *<===USER may modify;
%LET OUTFILP3 = IQP3;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF INPUT RATES FILE (OUTPUT FROM PROGRAM P2) AND  - ;
 * --- PROVIDER LEVEL OUTPUT FILE.                                - ;
 * ---------------------------------------------------------------- ;
 * --- INDIVIDUAL MEASURE GRAPH OUTPUT OBSERVED VS RISK ADJUSTED ---;
 * --- Enter Measure Number, Include leading zero if one digit.  ---;
 * --- Enter HOSPID to see results for individual provider.      ---;
 * ---  Leave blank to see result across all providers.          ---;
 * ---------------------------------------------------------------- ;
%LET INDNUM = 15;                               *<===USER may modify;
%LET HOSPID =;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR      - ;
 * --- EXPORT INTO A SPREADSHEET.                                 - ;
 * ---------------------------------------------------------------- ;
%LET TEXTP3=0;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;
 * --- OF THE FILE.                                               - ;
 * ---------------------------------------------------------------- ;
FILENAME IQTEXTP3 'C:\PATHNAME\IQTEXTP3.TXT';   *<===USER may modify;

* ==================================================================;
* ============AREA-LEVEL INPATIENT QUALITY INDICATORS===============;
* ==================================================================;
* ---                   Program A2-Observed Rates              ---- ;
* ----------------------------------------------------------------- ;
LIBNAME OUTA2 'C:\PATHNAME';                   *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- TYPELVLA indicates the levels (or _TYPE_) of             --- ;
 * --- summarization to be kept in the output.                  --- ;
 * ---                                                          --- ;
 * ---  TYPELVLA      stratification                            --- ;
 * ---  --------  -------------------------                     --- ;
 * ---     0      overall                                       --- ;
 * ---     1                           race                     --- ;
 * ---     2                     sex                            --- ;
 * ---     3                     sex * race                     --- ;
 * ---     4               age                                  --- ;
 * ---     5               age *       race                     --- ;
 * ---     6               age * sex                            --- ;
 * ---     7               age * sex * race                     --- ;
 * ---     8       area                                         --- ;
 * ---     9       area  *             race                     --- ;
 * ---    10       area  *       sex                            --- ;
 * ---    11       area  *       sex * race                     --- ;
 * ---    12       area  * age                                  --- ;
 * ---    13       area  * age *       race                     --- ;
 * ---    14       area  * age * sex                            --- ;
 * ---    15       area  * age * sex * race                     --- ;
 * ---                                                          --- ;
 * --- The default TYPELVLA (0,8) will provide an overall       --- :
 * --- total and an area-level total.                           --- ;
 * ---                                                          --- ;
 * --- WARNING: TYPELVLA MUST INCLUDE 0 (OVERALL) and 8 (AREA)  --- ;
 * ---          IF YOU WISH TO SUBSEQUENTLY RUN PROGRAM A3.     --- ;
 * ---                                                          --- ;
 * ---------------------------------------------------------------- ;
%LET TYPELVLA = IN (0,8);                       *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF MICRODATA INPUT (OUTPUT FROM PROGRAM 1) AND  --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED AREA RATES.              --- ;
 * ---------------------------------------------------------------- ;
%LET OUTFILA2 = IQA2;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;
 * --- EXPORT INTO A SPREADSHEET.                               --- ;
 * ---------------------------------------------------------------- ;
%LET TEXTA2=0;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;
 * --- OF THE FILE.                                             --- ;
 * ---------------------------------------------------------------- ;
FILENAME IQTEXTA2 'C:\PATHNAME\IQTEXTA2.TXT';  *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * ---       Program A3-Risk-Adjusted and Smooothed Rates       --- ;
 * ---------------------------------------------------------------- ;
LIBNAME INA2 'C:\PATHNAME';                    *<===USER MUST modify;
LIBNAME OUTA3 'C:\PATHNAME';                   *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF COVARIATE FILE.                                - ;
 * --- THIS FILE CONTAINS THE REGRESSION COEFFICIENTS FOR EACH    - ;
 * --- COVARIATE.  THERE IS ONE OBSERVATION PER INPATIENT QUALITY - ;
 * --- INDICATOR.                                                 - ;
 * ---------------------------------------------------------------- ;
FILENAME COVARA 'C:\PATHNAME\COVIQA50.TXT';    *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF MSX STATISTICS FILE                            - ;
 * ---   FILE CONTAINS A SET OF THREE ARRAYS.  THE FIRST ARRAY    - ;
 * ---   CONTAINS NOISE ESTIMATES, THE SECOND SIGNAL ESTIMATES,   - ;
 * ---   AND THE THIRD MEAN AREA RATES FOR EACH INPATIENT QUALITY - ;
 * ---   INDICATOR.                                               - ;
 * ---------------------------------------------------------------- ;
FILENAME MSXA 'C:\PATHNAME\MSXIQA50.TXT';      *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF INPUT RATES FILE (OUTPUT FROM PROGRAM A2) AND--- ;
 * --- AREA LEVEL OUTPUT FILE.                                  --- ;
 * ---------------------------------------------------------------- ;
%LET INFILEA2 = IQA2;                           *<===USER may modify;
%LET OUTFILA3 = IQA3;                           *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;
 * --- EXPORT INTO A SPREADSHEET.                               --- ;
 * ---------------------------------------------------------------- ;
%LET TEXTA3=0;                                  *<===USER may modify;

 * ---------------------------------------------------------------- ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;
 * --- OF THE FILE.                                             --- ;
 * ---------------------------------------------------------------- ;
FILENAME IQTEXTA3 'C:\PATHNAME\IQTEXTA3.TXT';   *<===USER may modify;
