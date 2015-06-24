 %MACRO E2113H1M(INP=, IND=, OUTDATA=, IDVAR=, KEEPVAR=, SEDITS=,
                 DATE_ASOF=, FMNAME=, AGEFMT=, SEXFMT=, 
                 DF_DG=, DF_POSTG=, 
                 AGESEXMAC=AGESEXV2, EDITMAC=V20EDIT1, 
                 LABELMAC=V20H87L1, HIERMAC=V20H87H1, 
                 MULTCCMAC=V21H87M1, SCOREMAC=SCOREVAR);

 %**********************************************************************
 * E2113H1M creates HCC and score variables for each person who is
 * present in a person file.
 * If a person has at least one diagnosis in DIAG file then HCCs are
 * created, otherwise HCCs are set to 0 .
 * Score variables are created using coefficients from 5 final
 * models: Dialysis Continuing Enrollee, Dialysis New Enrollees, 
 * Functioning Graft Community, Functioning Graft Institutional, 
 * Functioning Graft New Enrollee.
 *
 * Assumptions about input files:
 *   - both files are sorted by person ID
 *   - person level file has the following variables:
 *     :&IDVAR  - person ID variable (it is a macro parameter)
 *     :DOB     - date of birth
 *     :SEX     - gender
 *     :OREC    - original reason for entitlement
 *     :MCAID   - Medicaid dummy variable
 *     :NEMCAID - Medicaid dummy variable for new enrollees
 *
 *   - diagnosis level file has the following vars:
 *     :&IDVAR - person ID variable (it is a macro parameter)
 *     :DIAG   - diagnosis
 *
 * Parameters:
 *      INP       - input person dataset
 *      IND       - input diagnosis dataset
 *      OUTDATA   - output dataset
 *      IDVAR     - name of person id variable (HICNO for Medicare data)
 *      KEEPVAR   - variables to keep in output file
 *      SEDITS    - a switch that controls whether to perform MCE edits  
 *                  on ICD9: 1-YES, 0-NO
 *      DATE_ASOF - reference date to calculate age. Set to February 1
 *                  of the payment year for consistency with CMS.
 *      FMNAME    - format name (crosswalk ICD9 to V21 CCs)
 *      AGEFMT    - format name (crosswalk ICD9 to acceptable age range
 *                  in case MCE edits on ICD9 are to be performed)
 *      SEXFMT    - format name (crosswalk ICD9 to acceptable sex in 
 *                  case MCE edits on ICD9 are to be performed)
 *      DF_DG     - normalization factor set by CMS, used to multiply 
 *                  dialysis and transplant scores (currently set to 1 
 *                  by default)
 *      DF_POSTG  - normalization factor set by CMS, used to multiply 
 *                  functioning graft scores (currently set to 1 by 
 *                  default)
 *      AGESEXMAC - external macro name: create age/sex,
 *                  originally disabled, disabled vars
 *      EDITMAC   - external macro name: perform edits to diagnosis
 *      LABELMAC  - external macro name: assign labels to HCCs
 *      HIERMAC   - external macro name: set HCC=0 according to
 *                  hierarchies
 *      MULTCCMAC - external macro name: assign one ICD9 to multiple CCs
 *      SCOREMAC  - external macro name: calculate a score variable
 *
 **********************************************************************;

 %**********************************************************************
 * step1: include external macros;
 **********************************************************************;
 %IF "&AGESEXMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&AGESEXMAC) /SOURCE2; %* create demographic variables;
 %END;
 %IF "&EDITMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&EDITMAC)   /SOURCE2; %* perform edits;
 %END;
 %IF "&LABELMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&LABELMAC)  /SOURCE2; %* hcc labels;
 %END;
 %IF "&HIERMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&HIERMAC)   /SOURCE2; %* hierarchies;
 %END;
 %IF "&MULTCCMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&MULTCCMAC) /SOURCE2; %* multiple CCs;
 %END;
 %IF "&SCOREMAC" ne "" %THEN %DO;
     %INCLUDE IN0(&SCOREMAC)  /SOURCE2; %* calculate score variable;
 %END;

 %**********************************************************************
 * step2: define internal macro variables;
 **********************************************************************;
              %****************************************
               * Macro variables common to all models
               *****************************************;

 %LET N_CC=201;    %*max # of HCCs;

               %****************************************
               * Continuing enrollee dialysis model
               *****************************************;
 %* Age/sex cells used in dialysis CE model, functioning graft community 
  model and functioning graft institutional model;
 %LET AGESEX=%STR(F0_34  F35_44 F45_54 F55_59 F60_64 F65_69
                  F70_74 F75_79 F80_84 F85_89 F90_94 F95_GT
                  M0_34  M35_44 M45_54 M55_59 M60_64 M65_69
                  M70_74 M75_79 M80_84 M85_89 M90_94 M95_GT);

 %* Medicaid and Originally Disabled Interactions with Age and Sex used
  in dialysis CE model and functioning graft community model;
 %LET MOAS = %STR(MCAID_Female_Aged
                  MCAID_Female_NonAged
                  MCAID_Male_Aged
                  MCAID_Male_NonAged
                  OriginallyDisabled_Female
                  OriginallyDisabled_Male);

 %* Originally Disabled Interactions with ESRD and Sex;
 %LET OE = %STR(Originally_ESRD_Female
                Originally_ESRD_Male);

 %* Disease Interactions for dialysis CE model;
 %LET DID = %STR(SEPSIS_CARD_RESP_FAIL
                 CANCER_IMMUNE
                 DIABETES_CHF
                 CHF_COPD
                 COPD_CARD_RESP_FAIL);

 %* Disabled/Disease Interactions for dialysis CE model and functioning 
  graft community model;
 %LET DDC = %STR(NONAGED_HCC6      NONAGED_HCC34
                 NONAGED_HCC46     NONAGED_HCC54
                 NONAGED_HCC55     NONAGED_HCC110
                 NONAGED_HCC176);

 %* Diagnostic categories necessary to create interaction variables;
 %LET DIAG_CAT= CANCER  DIABETES  IMMUNE  CHF     CARD_RESP_FAIL
                COPD    RENAL     COMPL   SEPSIS  PRESSURE_ULCER;

 %* Variables for Dialysis regression;
 %LET MOD_DIAL= %STR(&AGESEX &MOAS &OE &HCCV21_list87 &DID &DDC);

               %****************************************
               * New Enrollee dialysis model
               *****************************************;
 %* Age/sex cells;
 %LET AGESEX_DIAL_NE=%STR(NEF0_34  NEF35_44 NEF45_54 NEF55_59 NEF60_64
                          NEF65_69 NEF70_74 NEF75_79 NEF80_84 NEF85_GT
                          NEM0_34  NEM35_44 NEM45_54 NEM55_59 NEM60_64
                          NEM65_69 NEM70_74 NEM75_79 NEM80_84 NEM85_GT);

 %* Interaction variables;
 %LET MOAS_DIAL_NE = %STR(NEMedicaid_Female_Aged
                          NEMedicaid_Female_NonAged
                          NEMedicaid_Male_Aged
                          NEMedicaid_Male_NonAged
                          ORIGDIS_FEMALE_GE65
                          ORIGDIS_FEMALE_LT65
                          ORIGDIS_MALE_GE65
                          ORIGDIS_MALE_LT65);

 %* Variables for Dialysis New Enrollees regression;
 %LET MOD_DIAL_NE = %STR(&AGESEX_DIAL_NE &MOAS_DIAL_NE);

               %****************************************
               * Community Functioning Graft model
               *****************************************;
 %* Disease Interactions for Functioning graft community model;
 %LET DIC = %STR(SEPSIS_CARD_RESP_FAIL
                 CANCER_IMMUNE
                 DIABETES_CHF
                 CHF_COPD
                 CHF_RENAL
                 COPD_CARD_RESP_FAIL);

 %* Variables for Functioning Graft Community regression;
 %LET MOD_GRAFT_COMM= %STR(&AGESEX &MOAS &HCCV21_list87 &DIC &DDC);

               %****************************************
               * Institutional Functioning Graft model
               *****************************************;
 %* Disabled/Disease Interactions for institutional Functioning graft 
  model;
 %LET DDI = %STR(NONAGED_HCC85       NONAGED_PRESSURE_ULCER
                 NONAGED_HCC161      NONAGED_HCC39
                 NONAGED_HCC77       NONAGED_HCC6);

 %* Disease Interactions for institutional functioning graft model;
 %LET DII = %STR(CHF_COPD COPD_CARD_RESP_FAIL
                 SEPSIS_PRESSURE_ULCER
                 SEPSIS_ARTIF_OPENINGS
                 ART_OPENINGS_PRESSURE_ULCER
                 DIABETES_CHF
                 COPD_ASP_SPEC_BACT_PNEUM
                 ASP_SPEC_BACT_PNEUM_PRES_ULC
                 SEPSIS_ASP_SPEC_BACT_PNEUM
                 SCHIZOPHRENIA_COPD
                 SCHIZOPHRENIA_CHF
                 SCHIZOPHRENIA_SEIZURES);

 %* Variables for Functioning Graft Institutional regression;
 %LET MOD_GRAFT_INST= %STR(&AGESEX MCAID ORIGDS &HCCV21_list87
                           &DII &DDI);

               %***************************************;
               * New Enrollee Functioning Graft model 
               ****************************************;
 %* Age/sex cells;
 %LET NE_AGESEX =%STR(NEF0_34  NEF35_44 NEF45_54 NEF55_59 NEF60_64
                 NEF65 NEF66 NEF67 NEF68 NEF69
                 NEF70_74 NEF75_79 NEF80_84 NEF85_89 NEF90_94 NEF95_GT
                 NEM0_34  NEM35_44 NEM45_54 NEM55_59 NEM60_64
                 NEM65 NEM66 NEM67 NEM68 NEM69
                 NEM70_74 NEM75_79 NEM80_84 NEM85_89 NEM90_94 NEM95_GT);

 %* Interaction variables;
 %LET DEMOG_INTERACT_GRAFT_NE = %STR(
             MCAID_female0_64        MCAID_female65
             MCAID_female66_69       MCAID_female70_74
             MCAID_female75_GT
             MCAID_male0_64          MCAID_male65
             MCAID_male66_69         MCAID_male70_74
             MCAID_male75_GT
             Origdis_female65        Origdis_female66_69
             Origdis_female70_74     Origdis_female75_GT
             Origdis_male65          Origdis_male66_69
             Origdis_male70_74       Origdis_male75_GT);

 %* Variables for Functioning Graft New Enrollee regression;
 %LET MOD_GRAFT_NE= %STR(&NE_AGESEX  &DEMOG_INTERACT_GRAFT_NE);

 %**********************************************************************
 * step3: merge person and diagnosis files outputting one record
 *        per person with score and HCC variables for each input person
 *        level record
 **********************************************************************;

 DATA &OUTDATA(KEEP=&KEEPVAR);
    %****************************************************;
    * step3.1: declaration section;
    %****************************************************;

    %IF "&LABELMAC" ne "" %THEN %&LABELMAC;  *HCC labels;

    %*length of some new variables,
     other demographic vars defined in macro &AGESEXMAC;
    LENGTH CC $4. AGEF   
           &AGESEX &DIAG_CAT &MOAS &OE &DDC &MOAS_DIAL_NE &DIC
           &DDI &DII
           &NE_AGESEX &DEMOG_INTERACT_GRAFT_NE
           NEF85_GT
           NEM85_GT
           NEF65_69
           NEM65_69
           CC1-CC&N_CC
           HCC1-HCC&N_CC        3.;

    %*retain cc vars;
    RETAIN CC1-CC&N_CC 0  AGEF
           ;
    %*arrays;
    ARRAY C(&N_CC)  CC1-CC&N_CC;
    ARRAY HCC(&N_CC) HCC1-HCC&N_CC;
    %*interactions with HCCs;
    ARRAY RV &DIAG_CAT &DIC &DDC &DDI &DII;

    %****************************************************
    * step3.2: bring regression parameters
    ****************************************************;
    IF _N_ = 1 THEN SET INCOEF.HCCCOEFN;

    %****************************************************
    * step3.3: merge
    ****************************************************;
    MERGE &INP(IN=IN1)
          &IND(IN=IN2);
    BY &IDVAR;

    IF IN1 THEN DO;

    %*******************************************************
    * step3.4: for the first record for a person set CC to 0
    ********************************************************;

       IF FIRST.&IDVAR THEN DO;
          %*set ccs to 0;
           DO I=1 TO &N_CC;
            C(I)=0;
           END;
           %* age;
           AGEF =FLOOR((INTCK(
                'MONTH',DOB,&DATE_ASOF)-(DAY(&DATE_ASOF)<DAY(DOB)))/12);
       END;

    %******************************************************
    * step3.5 if there are any diagnoses for a person
    *         then do the following:
    *         - create CC using format specified in FMNAME
    *         - perform ICD9 edits using macro &EDITMAC
    *         - assign additional CC using &MULTCCMAC macro
    *******************************************************;
       IF IN1 & IN2 THEN DO;

           CC = LEFT(PUT(DIAG,$&FMNAME..));

           IF CC NE "-1.0" THEN DO;
              %*perform ICD9 edits;
              %IF "&EDITMAC" ne "" %THEN
                %&EDITMAC(AGE=AGEF, SEX=SEX, ICD9=DIAG);

              IND=INPUT(CC,4.);
              IF 1<= IND <= &N_CC THEN DO;
                C(IND)=1;
                %IF "&MULTCCMAC" ne "" %THEN
                %&MULTCCMAC(ICD9=DIAG);  %*multiple CCs;
              END;
           END;
       END; %*CC creation;  

    %**************************************************************
    * step3.6 for the last record for a person do the
    *         following:
    *         - create demographic variables needed (macro &AGESEXMAC)
    *         - create HCC using hierarchies (macro &HIERMAC)
    *         - create HCC interaction variables
    *         - create HCC and DISABL interaction variables
    *         - set HCCs and interaction vars to zero if there
    *           are no diagnoses for a person
    *         - create 17 score variables
    **************************************************************;
       IF LAST.&IDVAR THEN DO;

           %*****************************
           * demographic vars
           *****************************;
           %*create age/sex cells, originally disabled, disabled vars;
           %IF "&AGESEXMAC" ne "" %THEN
           %&AGESEXMAC(AGEF=AGEF, SEX=SEX, OREC=OREC);

           NEF85_GT = (SEX='2' & AGEF >84);
           NEM85_GT = (SEX='1' & AGEF >84);
           NEF65_69 = SUM(NEF65, NEF66, NEF67, NEF68, NEF69);
           NEM65_69 = SUM(NEM65, NEM66, NEM67, NEM68, NEM69);

           %*medicaid interactions;
           MCAID_Female_Aged     = MCAID*(SEX='2')*(1 - DISABL);
           MCAID_Female_NonAged  = MCAID*(SEX='2')*DISABL;
           MCAID_Male_Aged       = MCAID*(SEX='1')*(1 - DISABL);
           MCAID_Male_NonAged    = MCAID*(SEX='1')*DISABL;

           %* originally disabled interactions with age/sex;
           OriginallyDisabled_Female= ORIGDS*(SEX='2');
           OriginallyDisabled_Male  = ORIGDS*(SEX='1');

           %* originally  ESRD or both originally disabled & ESRD;
           Originally_ESRD_Female   = (OREC IN ('2','3'))*(SEX='2')*
                                      (AGEF >=65);
           Originally_ESRD_Male     = (OREC IN ('2','3'))*(SEX='1')*
                                      (AGEF >=65);

           %*****************************
           * variables for New Enrollees
           *****************************;
           %*Medicaid * AgeSex * Disabled;
           NEMedicaid_Female_Aged     = NEMCAID*(SEX='2')*(1 - DISABL);
           NEMedicaid_Female_NonAged  = NEMCAID*(SEX='2')*DISABL;
           NEMedicaid_Male_Aged       = NEMCAID*(SEX='1')*(1 - DISABL);
           NEMedicaid_Male_NonAged    = NEMCAID*(SEX='1')*DISABL;

           %*Medicaid * AgeSex;
           MCAID_female0_64   =(SEX="2" & NEMCAID & 0<=AGEF <65
                                 & NEF65=0);
           MCAID_female65     =(SEX="2" & NEMCAID & NEF65);
           MCAID_female66_69  =(SEX="2" & NEMCAID
                                 & sum(NEF66,NEF67,NEF68,NEF69));
           MCAID_female70_74  =(SEX="2" & NEMCAID & 70<=AGEF <75);
           MCAID_female75_GT  =(SEX="2" & NEMCAID & AGEF >74);
           MCAID_male0_64     =(SEX="1" & NEMCAID & 0<=AGEF <65
                                 & NEM65=0);
           MCAID_male65       =(SEX="1" & NEMCAID & NEM65);
           MCAID_male66_69    =(SEX="1" & NEMCAID
                                 & sum(NEM66,NEM67,NEM68,NEM69));
           MCAID_male70_74    =(SEX="1" & NEMCAID & 70<=AGEF <75);
           MCAID_male75_GT    =(SEX="1" & NEMCAID & AGEF >74);

           %*Originally Disabled * AgeSex;
           OrigDis_Female_GE65 = (OREC='1')*(AGEF >= 65)*(SEX='2');
           OrigDis_Male_GE65   = (OREC='1')*(AGEF >= 65)*(SEX='1');
           OrigDis_Female_LT65  = (OREC='1')*(AGEF < 65)*(SEX='2');
           OrigDis_Male_LT65    = (OREC='1')*(AGEF < 65)*(SEX='1');

           Origdis_female65     =(SEX='2' & ORIGDS & NEF65);
           Origdis_female66_69  =(SEX='2' & ORIGDS
                                   & sum(NEF66,NEF67,NEF68,NEF69));
           Origdis_female70_74  =(SEX='2' & ORIGDS & 70 <= AGEF <75);
           Origdis_female75_GT  =(SEX='2' & ORIGDS & AGEF >74);

           Origdis_male65       =(SEX='1' & ORIGDS & NEM65 );
           Origdis_male66_69    =(SEX='1' & ORIGDS
                                   & sum(NEM66,NEM67,NEM68,NEM69));
           Origdis_male70_74    =(SEX='1' & ORIGDS & 70 <= AGEF <75);
           Origdis_male75_GT    =(SEX='1' & ORIGDS & AGEF >74);

           IF IN1 & IN2 THEN DO;
               %***************************
               * setting HCCs, hierarchies   
               ***************************;
               CC134=0;
               %IF "&HIERMAC" ne "" %THEN %&HIERMAC;
               %***************************
               * HCC interaction variables
               ***************************;
               %* Functioning graft community model diagnostic categories;
               CANCER         = MAX(HCC8, HCC9, HCC10, HCC11, HCC12);
               DIABETES       = MAX(HCC17, HCC18, HCC19);
               IMMUNE         = HCC47;
               CARD_RESP_FAIL = MAX(HCC82, HCC83, HCC84);
               CHF            = HCC85;
               COPD           = MAX(HCC110, HCC111);
               RENAL          = MAX(HCC134, HCC135, HCC136, HCC137,
                                    HCC138, HCC139, HCC140, HCC141);
               COMPL          = HCC176;
               SEPSIS         = HCC2;
               %*interactions ;
               SEPSIS_CARD_RESP_FAIL =  SEPSIS*CARD_RESP_FAIL;
               CANCER_IMMUNE         =  CANCER*IMMUNE;
               DIABETES_CHF          =  DIABETES*CHF ;
               CHF_COPD              =  CHF*COPD     ;
               CHF_RENAL             =  CHF*RENAL    ;
               COPD_CARD_RESP_FAIL   =  COPD*CARD_RESP_FAIL  ;
               %*interactions with disabled ;
               NONAGED_HCC6   = DISABL*HCC6;   %*Opportunistic Infections;
               NONAGED_HCC34  = DISABL*HCC34;  %*Chronic Pancreatitis;
               NONAGED_HCC46  = DISABL*HCC46;  %*Severe Hematol Disorders;
               NONAGED_HCC54  = DISABL*HCC54;  %*Drug/Alcohol Psychosis;
               NONAGED_HCC55  = DISABL*HCC55;  %*Drug/Alcohol Dependence;
               NONAGED_HCC110 = DISABL*HCC110; %*Cystic Fibrosis;
               NONAGED_HCC176 = DISABL*HCC176; %* added 7/2009;

               %*Functioning graft institutional model;
               PRESSURE_ULCER = MAX(HCC157, HCC158, HCC159, HCC160);
               SEPSIS_PRESSURE_ULCER = SEPSIS*PRESSURE_ULCER;
               SEPSIS_ARTIF_OPENINGS = SEPSIS*(HCC188);
               ART_OPENINGS_PRESSURE_ULCER = (HCC188)*PRESSURE_ULCER;
               DIABETES_CHF = DIABETES*CHF;
               COPD_ASP_SPEC_BACT_PNEUM = COPD*(HCC114);
               ASP_SPEC_BACT_PNEUM_PRES_ULC = (HCC114)*PRESSURE_ULCER;
               SEPSIS_ASP_SPEC_BACT_PNEUM = SEPSIS*(HCC114);
               SCHIZOPHRENIA_COPD = (HCC57)*COPD;
               SCHIZOPHRENIA_CHF= (HCC57)*CHF;
               SCHIZOPHRENIA_SEIZURES = (HCC57)*(HCC79);

               NONAGED_HCC85          = DISABL*(HCC85);
               NONAGED_PRESSURE_ULCER = DISABL*PRESSURE_ULCER;
               NONAGED_HCC161         = DISABL*(HCC161);
               NONAGED_HCC39          = DISABL*(HCC39);
               NONAGED_HCC77          = DISABL*(HCC77);

           END; %*there are some diagnoses for a person;
           ELSE DO;
              DO I=1 TO &N_CC;
                 HCC(I)=0;
              END;
              DO OVER RV;
                 RV=0;
              END;
           END;

           %*to be able to keep normalization factors DF_DG and DF_POSTG in the output file;
           DF_DG = &DF_DG; 
           DF_POSTG = &DF_POSTG;
           LABEL
           DF_DG = "Normalization factor set by CMS, used to multiply dialysis and transplant scores"
           DF_POSTG = "Normalization factor set by CMS, used to multiply functioning graft scores";
          
           %*score calculation;
                                 
           /*********************************/
           /*    dialysis model             */
           /*********************************/;
          %IF "&SCOREMAC" ne "" %THEN %DO;
          %&SCOREMAC(PVAR=SCORE_DIAL, RLIST=&MOD_DIAL, CPREF=DI_);
           %*normalization;
           SCORE_DIAL=&DF_DG*SCORE_DIAL;

           /**********************************/
           /*  dialysis new enrollees model  */
           /**********************************/;
          %&SCOREMAC(PVAR=SCORE_DIAL_NE, RLIST=&MOD_DIAL_NE, CPREF=DNE_);
           %*normalization;
           SCORE_DIAL_NE=&DF_DG*SCORE_DIAL_NE;

           /**********************************/
           /*   transplant scores            */
           /**********************************/;

          SCORE_TRANS_KIDNEY_ONLY_1M    = &DF_DG*TRANSPLANT_KIDNEY_ONLY_1M ;
          SCORE_TRANS_KIDNEY_ONLY_2M    = &DF_DG*TRANSPLANT_KIDNEY_ONLY_2M ;
          SCORE_TRANS_KIDNEY_ONLY_3M    = &DF_DG*TRANSPLANT_KIDNEY_ONLY_3M ;

           /*************************************/
           /* community Functioning graft model */
           /*************************************/;

          %&SCOREMAC(PVAR=_SCORE_GRAFT_COMM, RLIST=&MOD_GRAFT_COMM,
                         CPREF=GC_);

          %*transplant bumps;
          SCORE_GRAFT_COMM_DUR4_9_GE65 =&DF_POSTG*(_SCORE_GRAFT_COMM +
                                        GE65_DUR4_9 * (AGEF >= 65));

          SCORE_GRAFT_COMM_DUR4_9_LT65 =&DF_POSTG*(_SCORE_GRAFT_COMM +
                                        LT65_DUR4_9 * (AGEF < 65)); 

          SCORE_GRAFT_COMM_DUR10PL_GE65 =&DF_POSTG*(_SCORE_GRAFT_COMM +
                                         GE65_DUR10PL * (AGEF >= 65));

          SCORE_GRAFT_COMM_DUR10PL_LT65 =&DF_POSTG*(_SCORE_GRAFT_COMM +
                                         LT65_DUR10PL * (AGEF < 65));

           /*****************************************/
           /* institutional functioning graft model */
           /*****************************************/;

          %&SCOREMAC(PVAR=_SCORE_GRAFT_INST, RLIST=&MOD_GRAFT_INST,
                         CPREF=GI_);

          %*transplant bumps;
          SCORE_GRAFT_INST_DUR4_9_GE65 =&DF_POSTG*(_SCORE_GRAFT_INST +
                                        GE65_DUR4_9 * (AGEF >= 65));

          SCORE_GRAFT_INST_DUR4_9_LT65 =&DF_POSTG*(_SCORE_GRAFT_INST +
                                        LT65_DUR4_9 * (AGEF < 65));

          SCORE_GRAFT_INST_DUR10PL_GE65 =&DF_POSTG*(_SCORE_GRAFT_INST +
                                         GE65_DUR10PL * (AGEF >= 65));

          SCORE_GRAFT_INST_DUR10PL_LT65 =&DF_POSTG*(_SCORE_GRAFT_INST +
                                         LT65_DUR10PL * (AGEF < 65));

           /*****************************************/
           /* new enrollees functioning graft model */
           /*****************************************/;

          %&SCOREMAC(PVAR=_SCORE_GRAFT_NE, RLIST=&MOD_GRAFT_NE,
                         CPREF=GNE_);

          %*transplant bumps;
          SCORE_GRAFT_NE_DUR4_9_GE65 =&DF_POSTG*(_SCORE_GRAFT_NE +
                                      GE65_DUR4_9 * (AGEF >= 65));

          SCORE_GRAFT_NE_DUR4_9_LT65 =&DF_POSTG*(_SCORE_GRAFT_NE +
                                      LT65_DUR4_9 * (AGEF < 65));

          SCORE_GRAFT_NE_DUR10PL_GE65 =&DF_POSTG*(_SCORE_GRAFT_NE +
                                       GE65_DUR10PL * (AGEF >= 65));

          SCORE_GRAFT_NE_DUR10PL_LT65 =&DF_POSTG*(_SCORE_GRAFT_NE +
                                       LT65_DUR10PL * (AGEF < 65));
          %END;
          OUTPUT &OUTDATA;
       END; %*last record for a person;
     END; %*there is a person record;
 RUN;

 %**********************************************************************
 * step4: data checks and proc contents
 ***********************************************************************;
 PROC PRINT U DATA=&OUTDATA(OBS=46);
     TITLE "*** file outputted by ESRD software ***";
 RUN ;
 PROC CONTENTS DATA=&OUTDATA;
 RUN;

 %MEND E2113H1M;
