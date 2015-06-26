/*
ED Profiling Algorithm program for SAS Version 7 or Version 8.

   Put the following 4 files in the same directory:

     1) This SAS program,
     2) ED Macros.sas,
     3) EDDxs.sd7, and
     4) a SAS version 7 or 8 dataset containing your ED records.
    
   Set the appropriate names in the three %LET statements below.

   Submit the program.
   
   Output will be called "EDOut", and will be written to the same directory as the other files.
   
   NOTE: Your Principal Diagnosis field should be character type, left-justified,
         with leading zeroes and NO embedded decimal
         
*/

/* Set to the full directory path, without quotation marks, where data files are and output will be written */
%let Directory=c:\SomeDirectory; 

/* Set to the name of the SAS version 7 or 8 dataset (WITHOUT the libname) that contains your ED records */
%let EDDataFile=SomeFilename;

/* set to the name of the field that contains Principal Diagnosis */
%let PrinDxVarName=PrinDx;


%include 'ED Macros 2.sas';

libname here v8 "&directory";

data temp;
 set here.&EDDataFile;
 length dxgroup $ 5;
 dxgroup=left(&PrinDxVarName);
 %recode(dxgroup)
run;

proc sort data=temp;
 by dxgroup;
run;

data   here.EDOut;
 merge temp(in=InTemp)
       here.EDDxs(in=InClassified rename=(prindx=dxgroup));
 by dxgroup;
 if InTemp;

 /* Initialize the algorithm classification percentages */

 ne      = 0 ;
 epct    = 0 ;
 edcnpa  = 0 ;
 edcnnpa = 0 ;

 /* Set flags for the 4 special categories */

 injury  = %injury  (dxgroup);
 psych   = %psych   (dxgroup);
 alcohol = %alcohol (dxgroup);
 drug    = %drug    (dxgroup);

 /* Classify the cases not classified above */

 if injury or psych or drug or alcohol then unclassified=0; /* "special" dx */
 else if InClassified then do; /* classified by our docs and/or case file review */
  unclassified=0;
  ne=sum(0,nonemerg);
  epct=sum(0,emergpc);
  edcnpa=%acs(dxgroup) * sum(0,emedpa,emednpa);
  edcnnpa=(not %acs(dxgroup)) * sum(0,emedpa,emednpa);
 end;
 else unclassified=1; /* In none of the above categories */

 drop emednpa emedpa emergpc nonemerg;
 label ne           = "Non-Emergent"
       epct         = "Emergent, Primary Care Treatable"
       edcnpa       = "Emergent, ED Care Needed, Preventable/Avoidable"
       edcnnpa      = "Emergent, ED Care Needed, Not Preventable/Avoidable"
       injury       = "Injury"
       psych        = "Mental Health Related"
       alcohol      = "Alcohol Related"
       drug         = "Drug Related (excluding alcohol)"
       unclassified = "Not in a Special Category, and Not Classified"
 ;
run;
