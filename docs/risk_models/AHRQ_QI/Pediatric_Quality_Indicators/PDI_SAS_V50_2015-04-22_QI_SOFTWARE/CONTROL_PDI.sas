* ---------------------------------------------------------------- ;            
 * ---             VERSION 5.0 - MARCH, 2015                   --- ;            
 * --------------------------------------------------------------- ;            
 * The PEDIATRIC Quality Indicator (PDI) module of the AHRQ Quality             
   Indicators software includes the following six programs, in                  
   addition to the programs CONTROL_PDI.SAS and PDFMTS.SAS:                     
        Program 1.   PDSAS1:  Assigns HCUP PEDIATRIC Quality                    
                       Indicators to inpatient records.                         
        Program P2.  PDSASP2:  Calculates observed provider rates               
                       for Pediatric Quality Indicators.                        
        Program G2.  PDSASG2:  Calculates stratified observed provider rates    
                       for Pediatric Quality Indicators.                        
        Program P3.  PDSASP3:  Calculates risk-adjusted provider rates          
                       for Pediatric Quality Indicators.                        
        Program A2.  PDSASA2:  Calculates observed area rates for               
                       Pediatric Quality Indicators.                            
        Program A3.  PDSASA3:  Calculates risk-adjusted area rates for          
                       Pediatric Quality Indicators.                            
                                                                                
******************************************************************* ;           
****************************PLEASE READ**************************** ;           
******************************************************************* ;           
 * The USER MUST modify portions of the following code in order to              
   run this software.  With one exception (see NOTE immediately                 
   following this paragraph), the only changes necessary to run                 
   this software using your data are changes you make in this                   
   program (CONTROL_PDI.SAS).  The modifications you make include such          
   items as specifying the name and location of your input data                 
   set, the year of population data to be used, and the name and                
   location of output data sets.                                                
                                                                                
 * NOTE:  CONTROL_PDI.SAS is written so that you have the option to             
          read in data from and write out data to different                     
          locations.  For example, "LIBNAME IN0" points to the                  
          location or pathname of your input data set for program               
          PDSAS1 and "LIBNAME OUT1" points to the location of the               
          output data set created by the PDSAS1 program.  These                 
          locations can be different.  This pattern of allowing                 
          you to specify the location of each input and output                  
          data set is true for each of the different programs                   
          referenced in CONTROL_PDI.SAS.  However, if you wish to read          
          in and write out all data to the same location you can.               
          The easiest way to do this is to make a global                        
          change in CONTROL_PDI.SAS, changing "C:\PATHNAME" to the              
          location you wish to use.                                             
                                                                                
 * NOTE:  In each of the six programs included with this                        
          package, as well as in the program which generates                    
          formats, there is a line of code that begins with                     
          "FILENAME CONTROL".  The USER MUST include after                      
          "FILENAME CONTROL" the location of the CONTROL_PDI.SAS file.          
                                                                                
 * Generally speaking, a first-time user of this software would                 
   proceed as follows:                                                          
        1.  Modify CONTROL_PDI.SAS.  (MUST be done.)                            
        2.  In the program generating needed formats, i.e., in                  
            PDFMTS.SAS, specify location (path name) of                         
            CONTROL_PDI.SAS. (MUST be done.)                                    
        3.  Run PDFMTS.SAS.  (MUST be done.)                                    
        4.  In Program 1, i.e., in PDSAS1, specify location                     
            of CONTROL_PDI.SAS program.  (MUST be done.)                        
        5.  Run PDSAS1.  (MUST be done.)                                        
        6.  If you want to generate provider-level Pediatric Quality            
            Indicators:                                                         
                a.  In Program P2, i.e., in PDSASP2, specify location           
            of CONTROL_PDI.SAS program.  (MUST be done if going to              
            run Program P2.)                                                    
                b.  Run PDSASP2.  (MUST have already run Program 1.)            
        7.  If you want to generate stratified provider-level Pediatric         
            Quality Indicators:                                                 
                a.  In Program G2, i.e., in PDSASG2, specify location           
            of CONTROL_PDI.SAS program.  (MUST be done if going to              
            run Program G2.)                                                    
                b.  Run PDSASG2.  (MUST have already run Program 1.)            
        8.  If you want to generate risk-adjusted provider-level                
            Pediatric Quality Indicators:                                       
                a.  In Program P3, i.e., in PDSASP3, specify location           
            of CONTROL_PDI.SAS program.  (MUST be done if going to              
            run Program P3.)                                                    
                b.  Run PDSASP3.  (MUST have already run Program 1 and P2.)     
        9.  If you want to generate area-level Pediatric Quality                
            Indicators:                                                         
                a.  In Program A2, i.e., in PDSASA2, specify location           
            of CONTROL_PDI.SAS program.  (MUST be done if going to              
            run Program A2.)                                                    
                b.  Run PDSASA2.  (MUST have already run Program 1.)            
        10. If you want to generate risk-adjusted area-level Pediatric          
            Quality Indicators:                                                 
                a.  In Program A3, i.e., in PDSASA3, specify location           
            of CONTROL_PDI.SAS program.  (MUST be done if going to              
            run Program A3.)                                                    
                b.  Run PDSASA3.  (MUST have already run Program 1 and A2.)     
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
 * NOTE:  In program A2, the user should select                     ;           
 *          the population data for the year that best              ;           
 *          matches the discharge data.  Data are available for     ;           
 *          1995 to 2014.                                           ;           
 * ---------------------------------------------------------------- ;           
%LET POPYEAR = 2013;                           *<===USER MUST modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF POPULATION FILE -------------------------------- ;           
 * ---------------------------------------------------------------- ;           
FILENAME POPFILE  'C:\PATHNAME\pop95t14.txt'; *<===USER MUST modify;   
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF RACHS-1 FILE ----------------------------------- ;           
 * ---------------------------------------------------------------- ;           
FILENAME PHSRACHS 'C:\PATHNAME\PHS_RACHS1.TXT'; *<==USER MUST modify;   
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- INDICATE IF RECORDS SHOULD BE PRINTED AT END OF EACH PGM --- ;           
 * ---------------------------------------------------------------- ;           
%LET PRINT = 0;                                 *<===USER may modify;           
                                                                                
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
 * ---------------------------------------------------------------- ;           
%LET INFILE0  = SIDS_yyyy;                      *<==USER MUST modify;
%LET OUTFILE1 = PD1;                            *<===USER may modify;
%LET NDX = 35;                                  *<===USER may modify;
%LET NPR = 30;                                  *<===USER may modify;
%LET USEPOA = 1;                                *<===USER may modify;        
                                                                                
                                                                                
 * ---------------------------------------------------------------- ;           
 * - SET PRDAY TO 1 IF DATA AVAILABLE REGARDING NUMBER OF DAYS  --- ;           
 * - FROM ADMISSION TO SECONDARY PROCEDURES                     --- ;           
 * ---------------------------------------------------------------- ;           
%LET PRDAY = 1;                                 *<===USER may modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * - CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL    --- ;           
 * - NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE       --- ;           
 * - VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED AFTER --- ;           
 * - RUNNING PDSAS1.						--- ;                                           
 * ---------------------------------------------------------------- ;           
%LET DELFILE1  = PDI_DELETED;                   *<===USER may modify;           
                                                                                
 * =================================================================;           
 * ============PROVIDER-LEVEL PEDIATRIC QUALITY INDICATORS==========;           
 * =================================================================;           
 * ---                   Program P2-Observed Rates              --- ;           
 * ---------------------------------------------------------------- ;           
LIBNAME IN1 'C:\PATHNAME';                     *<===USER MUST modify;
LIBNAME OUTP2 'C:\PATHNAME';                   *<===USER MUST modify;

                                                                                
 * ----------------------------------------------------------------------- ;    
 * --- TYPELVLP indicates the levels (or _TYPE_) of                    --- ;    
 * --- summarization to be kept in the output.                         --- ;    
 * ---                                                                 --- ;    
 * ---  TYPELVLP      stratification                                   --- ;    
 * ---  --------  ---------------------------------------------------- --- ;    
 * ---     0      overall                                              --- ;    
 * ---     1                                                      race --- ;    
 * ---     2                                              payer        --- ;    
 * ---     3                                              payer * race --- ;    
 * ---     4                                        sex                --- ;    
 * ---     5                                        sex         * race --- ;    
 * ---     6                                        sex * payer        --- ;    
 * ---     7                                        sex * payer * race --- ;    
 * ---     8                                  age                      --- ;    
 * ---     9                                  age               * race --- ;    
 * ---    10                                  age       * payer        --- ;    
 * ---    11                                  age       * payer * race --- ;    
 * ---    12                                  age * sex                --- ;    
 * ---    13                                  age * sex         * race --- ;    
 * ---    14                                  age * sex * payer        --- ;    
 * ---    15                                  age * sex * payer * race --- ;    
 * ---    16                         ageday                            --- ;    
 * ---    17                         ageday                     * race --- ;    
 * ---    18                         ageday             * payer        --- ;    
 * ---    19                         ageday             * payer * race --- ;    
 * ---    20                         ageday       * sex                --- ;    
 * ---    21                         ageday       * sex         * race --- ;    
 * ---    22                         ageday       * sex * payer        --- ;    
 * ---    23                         ageday       * sex * payer * race --- ;    
 * ---    24                         ageday * age                      --- ;    
 * ---    25                         ageday * age               * race --- ;    
 * ---    26                         ageday * age       * payer        --- ;    
 * ---    27                         ageday * age       * payer * race --- ;    
 * ---    28                         ageday * age * sex                --- ;    
 * ---    29                         ageday * age * sex         * race --- ;    
 * ---    30                         ageday * age * sex * payer        --- ;    
 * ---    31                         ageday * age * sex * payer * race --- ;    
 * ---    32                  bwht                                     --- ;    
 * ---    33                  bwht                              * race --- ;    
 * ---    34                  bwht                      * payer        --- ;    
 * ---    35                  bwht                      * payer * race --- ;    
 * ---    36                  bwht                * sex                --- ;    
 * ---    37                  bwht                * sex         * race --- ;    
 * ---    38                  bwht                * sex * payer        --- ;    
 * ---    39                  bwht                * sex * payer * race --- ;    
 * ---    40                  bwht          * age                      --- ;    
 * ---    41                  bwht          * age               * race --- ;    
 * ---    42                  bwht          * age       * payer        --- ;    
 * ---    43                  bwht          * age       * payer * race --- ;    
 * ---    44                  bwht          * age * sex                --- ;    
 * ---    45                  bwht          * age * sex         * race --- ;    
 * ---    46                  bwht          * age * sex * payer        --- ;    
 * ---    47                  bwht          * age * sex * payer * race --- ;    
 * ---    48                  bwht * ageday                            --- ;    
 * ---    49                  bwht * ageday                     * race --- ;    
 * ---    50                  bwht * ageday             * payer        --- ;    
 * ---    51                  bwht * ageday             * payer * race --- ;    
 * ---    52                  bwht * ageday       * sex                --- ;    
 * ---    53                  bwht * ageday       * sex         * race --- ;    
 * ---    54                  bwht * ageday       * sex * payer        --- ;    
 * ---    55                  bwht * ageday       * sex * payer * race --- ;    
 * ---    56                  bwht * ageday * age                      --- ;    
 * ---    57                  bwht * ageday * age               * race --- ;    
 * ---    58                  bwht * ageday * age       * payer        --- ;    
 * ---    59                  bwht * ageday * age       * payer * race --- ;    
 * ---    60                  bwht * ageday * age * sex                --- ;    
 * ---    61                  bwht * ageday * age * sex         * race --- ;    
 * ---    62                  bwht * ageday * age * sex * payer        --- ;    
 * ---    63                  bwht * ageday * age * sex * payer * race --- ;    
 * ---    64       provider                                            --- ;    
 * ---    65       provider                                     * race --- ;    
 * ---    66       provider                             * payer        --- ;    
 * ---    67       provider                             * payer * race --- ;    
 * ---    68       provider                       * sex                --- ;    
 * ---    69       provider                       * sex         * race --- ;    
 * ---    70       provider                       * sex * payer        --- ;    
 * ---    71       provider                       * sex * payer * race --- ;    
 * ---    72       provider                 * age                      --- ;    
 * ---    73       provider                 * age               * race --- ;    
 * ---    74       provider                 * age       * payer        --- ;    
 * ---    75       provider                 * age       * payer * race --- ;    
 * ---    76       provider                 * age * sex                --- ;    
 * ---    77       provider                 * age * sex         * race --- ;    
 * ---    78       provider                 * age * sex * payer        --- ;    
 * ---    79       provider                 * age * sex * payer * race --- ;    
 * ---    80       provider        * ageday                            --- ;    
 * ---    81       provider        * ageday                     * race --- ;    
 * ---    82       provider        * ageday             * payer        --- ;    
 * ---    83       provider        * ageday             * payer * race --- ;    
 * ---    84       provider        * ageday       * sex                --- ;    
 * ---    85       provider        * ageday       * sex         * race --- ;    
 * ---    86       provider        * ageday       * sex * payer        --- ;    
 * ---    87       provider        * ageday       * sex * payer * race --- ;    
 * ---    88       provider        * ageday * age                      --- ;    
 * ---    89       provider        * ageday * age               * race --- ;    
 * ---    90       provider        * ageday * age       * payer        --- ;    
 * ---    91       provider        * ageday * age       * payer * race --- ;    
 * ---    92       provider        * ageday * age * sex                --- ;    
 * ---    93       provider        * ageday * age * sex         * race --- ;    
 * ---    94       provider        * ageday * age * sex * payer        --- ;    
 * ---    95       provider        * ageday * age * sex * payer * race --- ;    
 * ---    96       provider * bwht                                     --- ;    
 * ---    97       provider * bwht                              * race --- ;    
 * ---    98       provider * bwht                      * payer        --- ;    
 * ---    99       provider * bwht                      * payer * race --- ;    
 * ---   100       provider * bwht                * sex                --- ;    
 * ---   101       provider * bwht                * sex         * race --- ;    
 * ---   102       provider * bwht                * sex * payer        --- ;    
 * ---   103       provider * bwht                * sex * payer * race --- ;    
 * ---   104       provider * bwht          * age                      --- ;    
 * ---   105       provider * bwht          * age               * race --- ;    
 * ---   106       provider * bwht          * age       * payer        --- ;    
 * ---   107       provider * bwht          * age       * payer * race --- ;    
 * ---   108       provider * bwht          * age * sex                --- ;    
 * ---   109       provider * bwht          * age * sex         * race --- ;    
 * ---   110       provider * bwht          * age * sex * payer        --- ;    
 * ---   111       provider * bwht          * age * sex * payer * race --- ;    
 * ---   112       provider * bwht * ageday                            --- ;    
 * ---   113       provider * bwht * ageday                     * race --- ;    
 * ---   114       provider * bwht * ageday             * payer        --- ;    
 * ---   115       provider * bwht * ageday             * payer * race --- ;    
 * ---   116       provider * bwht * ageday       * sex                --- ;    
 * ---   117       provider * bwht * ageday       * sex         * race --- ;    
 * ---   118       provider * bwht * ageday       * sex * payer        --- ;    
 * ---   119       provider * bwht * ageday       * sex * payer * race --- ;    
 * ---   120       provider * bwht * ageday * age                      --- ;    
 * ---   121       provider * bwht * ageday * age               * race --- ;    
 * ---   122       provider * bwht * ageday * age       * payer        --- ;    
 * ---   123       provider * bwht * ageday * age       * payer * race --- ;    
 * ---   124       provider * bwht * ageday * age * sex                --- ;    
 * ---   125       provider * bwht * ageday * age * sex         * race --- ;    
 * ---   126       provider * bwht * ageday * age * sex * payer        --- ;    
 * ---   127       provider * bwht * ageday * age * sex * payer * race --- ;    
 * ---                                                                 --- ;    
 * --- The default TYPELVLP (0,64) will provide an overall             --- :    
 * --- and provider-level totals.                                      --- ;    
 * ---                                                                 --- ;    
 * ----------------------------------------------------------------------- ;    
%LET TYPELVLP = IN (0,64);                      *<===USER may modify;        
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF MICRODATA INPUT (OUTPUT FROM PROGRAM 1) AND  --- ;           
 * --- SUMMARY OUTPUT FILE OF OBSERVED PROVIDER RATES.          --- ;           
 * ---------------------------------------------------------------- ;           
%LET INFILE1 = PD1;                             *<===USER may modify;
%LET OUTFILP2 = PDP2;                           *<===USER may modify;       
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;           
 * --- EXPORT INTO A SPREADSHEET.                               --- ;           
 * ---------------------------------------------------------------- ;           
%LET TEXTP2 = 0;                                *<===USER may modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;           
 * --- OF THE FILE.                                             --- ;           
 * ---------------------------------------------------------------- ;           
FILENAME PDTEXTP2 "C:\PATHNAME\PDTEXTP2.TXT";  *<===USER MUST modify;   
                                                                              
                                                          
 * ---------------------------------------------------------------- ;           
 * ---            Program G2-Stratified Observed Rates          --- ;           
 * ---------------------------------------------------------------- ;           
LIBNAME OUTG2 "C:\PATHNAME";             *<==USER MUST modify;          
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF MICRODATA INPUT (OUTPUT FROM PROGRAM 1) AND  --- ;           
 * --- SUMMARY OUTPUT FILE OF STRATIFIED OBSERVED PROVIDER RATES. - ;           
 * ---------------------------------------------------------------- ;           
%LET OUTFILG2 = PDG2;                           *<===USER may modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;           
 * --- EXPORT INTO A SPREADSHEET.                               --- ;           
 * ---------------------------------------------------------------- ;           
%LET TEXTG2 = 0;                                *<===USER may modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;           
 * --- OF THE FILE.                                             --- ;           
 * ---------------------------------------------------------------- ;           
FILENAME PDTEXTG2 "C:\PATHNAME\PDTEXTG2.TXT";  *<===USER MUST modify;   
                                                                                
                                                                                
 * ---------------------------------------------------------------- ;           
 * ---       Program P3-Risk-Adjusted and Smoothed Rates       --- ;            
 * ---------------------------------------------------------------- ;           
LIBNAME INP2 "C:\PATHNAME";                     *<==USER MUST modify;   
LIBNAME OUTP3 "C:\PATHNAME";                    *<==USER MUST modify;   

* ---------------------------------------------------------------- ;
 * --- SET NAME OF RISK ADJUSTMENT VARIABLE CREATION PROGRAM      - ;
 * ---------------------------------------------------------------- ;

FILENAME MAKCOVAR  "C:\PATHNAME\Makevars_PDI.sas" ;  *<===USER MUST modify;

 * ---------------------------------------------------------------- ;
 * --- SET NAME OF RISK ADJUSTMENT PARAMETERS DIRECTORY           - ;
 * ---------------------------------------------------------------- ;
%LET RADIR = C:\PATHNAME\PDI_GEE_Input_Files ;  *<===USER MUST modify;
                                                                               
 * ---------------------------------------------------------------- ;
 * --- SET NAME OF MSX STATISTICS FILE                            - ;
 * ---   FILE CONTAINS A SET OF TWO ARRAYS.  THE FIRST ARRAY      - ;
 * ---   CONTAINS THE SIGNAL VARIANCE ESTIMATES,                  - ;
 * ---   AND THE SECOND, MEAN PROVIDER RATES FOR EACH PEDIATRIC   - ;
 * ---   QUALITY INDICATOR.                                       - ;
 * --- If you select USEPOA=0 then comment out the POA MSXP file  - ;
 * --- and uncomment the NOPOA MSXP file.                         - ;
 * ---------------------------------------------------------------- ;    
                    
FILENAME MSXP "C:\PATHNAME\MSXPDP50.txt";    *<===USER MUST modify;
*FILENAME MSXP "C:\PATHNAME\MSXPDP50_NOPOA.txt"; *<===USER MAY modify;
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF INPUT RATES FILE (OUTPUT FROM PROGRAM P2) AND--- ;           
 * --- PROVIDER LEVEL OUTPUT FILE.                              --- ;           
 * ---------------------------------------------------------------- ;           
%LET INFILEP2 = PDP2;                           *<===USER may modify;        
%LET OUTFILP3 = PDP3;                           *<===USER may modify;        
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;           
 * --- EXPORT INTO A SPREADSHEET.                               --- ;           
 * ---------------------------------------------------------------- ;           
%LET TEXTP3 = 0;                                *<===USER may modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;           
 * --- OF THE FILE.                                             --- ;           
 * ---------------------------------------------------------------- ;           
FILENAME PDTEXTP3 "C:\PATHNAME\PDTEXTP3.TXT";   *<===USER may modify;    
                                                                                
                                                                                
 * =================================================================;           
 * ============AREA-LEVEL PEDIATRIC quality INDICATORS==============;           
 * =================================================================;           
 * ---                   Program A2-Observed Rates              --- ;           
 * ---------------------------------------------------------------- ;           
LIBNAME OUTA2 "C:\PATHNAME";                   *<==USER MUST modify;     
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- TYPELVLA indicates the levels (or _TYPES_) of            --- ;           
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
 * --- and area-level totals                                    --- ;           
 * ---                                                          --- ;           
 * ---------------------------------------------------------------- ;           
%LET TYPELVLA = IN (0,8);                       *<===USER may modify;       
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF MICRODATA INPUT (OUTPUT FROM PROGRAM 1) AND  --- ;           
 * --- SUMMARY OUTPUT FILE OF OBSERVED AREA RATES.              --- ;           
 * ---------------------------------------------------------------- ;           
%LET OUTFILA2 = PDA2;                           *<===USER may modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;           
 * --- EXPORT INTO A SPREADSHEET.                               --- ;           
 * ---------------------------------------------------------------- ;           
%LET TEXTA2 = 0;                                *<===USER may modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;           
 * --- OF THE FILE.                                             --- ;           
 * ---------------------------------------------------------------- ;           
FILENAME PDTEXTA2 'C:\PATHNAME\PDTEXTA2.TXT';  *<===USER MUST modify;   
                                                                                
 * ---------------------------------------------------------------- ;           
 * ---       Program A3-Risk-Adjusted and Smoothed Rates       --- ;            
 * ---------------------------------------------------------------- ;           
LIBNAME INA2 'C:\PATHNAME';                    *<===USER MUST modify;
LIBNAME OUTA3 'C:\PATHNAME';                   *<===USER MUST modify;         
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF COVARIATE FILE.                                - ;           
 * --- THIS FILE CONTAINS THE REGRESSION COEFFICIENTS FOR EACH    - ;           
 * --- COVARIATE.  THERE IS ONE OBSERVATION PER PEDIATRIC QUALITY - ;           
 * --- INDICATOR.                                                 - ;           
 * ---------------------------------------------------------------- ;           
 * - SET TO COVPDA50 FOR AGE AND GENDER ADJUSTMENT ONLY (DEFAULT) - ;           
 * - SET TO CVPDA50 FOR AGE, GENDER AND SES ADJUSTMENT           - ;            
FILENAME COVARA 'C:\PATHNAME\COVPDA50.TXT';  *<===USER MUST modify;     
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF MSX STATISTICS FILE                            - ;           
 * ---   FILE CONTAINS AN ARRAY OF SIGNAL VARIANCE AND            - ;           
 * ---   POPULATION RATES                                         - ;           
 * ---------------------------------------------------------------- ;           
 * - SET TO MSXPDA50 FOR AGE AND GENDER ADJUSTMENT ONLY (DEFAULT) - ;           
 * - SET TO MXPDA50 FOR AGE, GENDER AND SES ADJUSTMENT           - ;            
FILENAME MSXA 'C:\PATHNAME\MSXPDA50.TXT';    *<===USER MUST modify;     
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- SET NAME OF INPUT RATES FILE (OUTPUT FROM PROGRAM A2) AND--- ;           
 * --- AREA LEVEL OUTPUT FILE.                                  --- ;           
 * ---------------------------------------------------------------- ;           
%LET INFILEA2 = PDA2;                           *<===USER may modify;       
%LET OUTFILA3 = PDA3;                           *<===USER may modify;       
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- INDICATE IF WANT TO CREATE A COMMA-DELIMITED FILE FOR    --- ;           
 * --- EXPORT INTO A SPREADSHEET.                               --- ;           
 * ---------------------------------------------------------------- ;           
%LET TEXTA3 = 0;                                *<===USER may modify;           
                                                                                
 * ---------------------------------------------------------------- ;           
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION - ;           
 * --- OF THE FILE.                                             --- ;           
 * ---------------------------------------------------------------- ;           
FILENAME PDTEXTA3 'C:\PATHNAME\PDTEXTA3.TXT';   *<===USER may modify;   
                                                                                
