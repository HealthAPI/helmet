/*
The recode macro should be run in order to recode a principal diagnosis
before using that diagnosis field as a BY variable
for merging with findxg or findxacs.
These latter files add four variables,
corresponding to the percentage of emergency department cases
with that diagnosis that have been found to fall into
each of 4 categories:

nonemergent,
emergent/pc-treatable,
ed needed/acs(preventable/avoidable),
ed needed/non-acs(not preventable/avoidable)
*/

%macro recode(dx);

      if &dx in: ('042','043','044')                                              then &dx='042';
 else if &dx =: '0781'                                                            then &dx='0781';
 else if &dx =: '2501'                                                            then &dx='2501';
 else if &dx =: '2780'                                                            then &dx='2780';
 else if &dx =: '4151'                                                            then &dx='4151';
 else if &dx =: '493'                                                             then &dx='493';
 else if &dx =: '5301'                                                            then &dx='5301';
 else if &dx =: '5751'                                                            then &dx='5751';
 else if &dx =: '6860'                                                            then &dx='6860';
 else if &dx =: '7807'                                                            then &dx='7807';
 else if &dx in ('78700','78701','78702','78703')                                 then &dx='7870';
 else if &dx in ('78840','78841','78842','78843')                                 then &dx='7884';
 else if &dx =: '7890'                                                            then &dx='7890';
 else if &dx =: '850'                                                             then &dx='850';
 else if &dx in: ('8540','8541')                                                  then &dx='854';
 else if &dx =: '9898'                                                            then &dx='9898';
 else if &dx =: '9955'                                                            then &dx='9955';
 else if &dx =: '9970'                                                            then &dx='9970';
 else if &dx in ('99810','99811','99812','99813')                                 then &dx='9981';
 else if &dx in: ('v72','V72')                                                    then &dx='V72';

 /* the following groupings are from the dxgroups file, created by the Beth Israel ed docs */
 /* 4/27/01: rearranged so as not to interfere with the acs categorization that follows this */

 else if &dx in ('0049','0085','0088')                                            then &dx='0059';
 else if &dx in ('0389','7907')                                                   then &dx='0381 ';
 else if &dx  = '0579'                                                            then &dx='05700';
 else if &dx in ('0542','0740','5282')                                            then &dx='5280 '; * acs;
 else if &dx in ('0792','0799','07999')                                           then &dx='075  ';
 else if &dx in ('1104','1108','1109','1110')                                     then &dx='1100 ';
 else if &dx in ('1319')                                                          then &dx='13101';
 else if &dx in ('25001')                                                         then &dx='25000';
 else if &dx in ('2510')                                                          then &dx='2512 '; * acs;
 else if &dx in ('28261','28262')                                                 then &dx='28260';
 else if &dx in ('29532','29590','2989')                                          then &dx='29530';
 else if &dx in ('30001','3009','3061','78601')                                   then &dx='30000';
 else if &dx in ('30400','30500','30560','3058','30590')                          then &dx='30390';
 else if &dx in ('30781','3469 ','34690')                                         then &dx='7840';
 else if &dx in ('3559')                                                          then &dx='3549 ';
 else if &dx in ('37200','37203','37214','37230')                                 then &dx='0779 ';
 else if &dx in ('38101')                                                         then &dx='3829 '; * acs;
 else if &dx in ('41090')                                                         then &dx='4111 '; * acs;
 else if &dx in ('436')                                                           then &dx='4359 ';
 else if &dx in ('4549')                                                          then &dx='4540 ';
 else if &dx in ('4553','4556')                                                   then &dx='4550 ';
 else if &dx in ('4558')                                                          then &dx='4552 ';
 else if &dx in ('0340','4620','463')                                             then &dx='462  '; * acs;
 else if &dx in ('460','4658','4659','4660','490')                                then &dx='4660 '; * acs;
 else if &dx in ('4779')                                                          then &dx='4739 ';
 else if &dx in ('4809','486')                                                    then &dx='485  '; * acs;
 else if &dx in ('5210','5225')                                                   then &dx='5220 '; * acs;
 else if &dx in ('5233','5234','5239')                                            then &dx='5231 '; * acs;
 else if &dx in ('53390')                                                         then &dx='5339 ';
 else if &dx in ('53550')                                                         then &dx='53500';
 else if &dx in ('5889')                                                          then &dx='586  ';
 else if &dx in ('5921','5929','5941','7880')                                     then &dx='5920 ';
 else if &dx in ('59780','7887')                                                  then &dx='0980 ';
 else if &dx in ('5959')                                                          then &dx='5990 '; * acs;
 else if &dx in ('6159')                                                          then &dx='6149 ';
 else if &dx in ('61610','6168')                                                  then &dx='6160 ';
 else if &dx in ('6269')                                                          then &dx='6268 ';
 else if &dx in ('64003','64093','64193')                                         then &dx='64000';
 else if &dx in ('64390')                                                         then &dx='64303';
 else if &dx in ('64413')                                                         then &dx='64410';
 else if &dx in ('6809')                                                          then &dx='6806 ';
 else if &dx in ('68102','68110','68111')                                         then &dx='68100';
 else if &dx =: '682' or &dx in ('684','6869')                                    then &dx='682';
 else if &dx in ('6926','6929','7821')                                            then &dx='6918 ';
 else if &dx in ('7079')                                                          then &dx='7071 '; * acs;
 else if &dx in ('70890')                                                         then &dx='7089 ';
 else if &dx in ('71590','71596','71690','71697','71940','71941','71943')         then &dx='71946';
 else if &dx in ('7210','7231')                                                   then &dx='7235 ';
 else if &dx in ('72190','7242','7245')                                           then &dx='7248';
 else if &dx in ('73399')                                                         then &dx='7329 ';
 else if &dx in ('78052')                                                         then &dx='78050';
 else if &dx in ('80702')                                                         then &dx='80700';
 else if &dx in ('81209','81220','81240','81241')                                 then &dx='81200';
 else if &dx in ('81342','81344','81381','81400')                                 then &dx='81341';
 else if &dx in ('81600','81601','81602')                                         then &dx='81500';
 else if &dx in ('8248')                                                          then &dx='8242 ';
 else if &dx in ('82525','8260')                                                  then &dx='82520';
 else if &dx in ('83101')                                                         then &dx='83100';
 else if &dx in ('83209')                                                         then &dx='83200';
 else if &dx in ('8419')                                                          then &dx='8409 ';
 else if &dx in ('84210')                                                         then &dx='84200';
 else if &dx in ('8449')                                                          then &dx='8439 ';
 else if &dx in ('84509','84510')                                                 then &dx='84500';
 else if &dx in ('8469','8479')                                                   then &dx='8460 ';
* else if &dx in ('8509')                                                         then &dx='8501 '; * already rolled into 850, see above;
* else if &dx in ('85400')                                                        then &dx='8540 '; * already rolled into 854, see above;
 else if &dx in ('8709')                                                          then &dx='8708 ';
 else if &dx in ('87261')                                                         then &dx='38420';
 else if &dx in ('8731')                                                          then &dx='8730 ';
 else if &dx in ('87340','87341','87342','87343','87344','87353','87360','87364') then &dx='87320';
 else if &dx in ('8760','8770')                                                   then &dx='8750 ';
 else if &dx in ('88003','88100','8840')                                          then &dx='88000';
 else if &dx in ('8820')                                                          then &dx='88102';
 else if &dx in ('8910')                                                          then &dx='8900 ';
 else if &dx in ('8930')                                                          then &dx='8920 ';
 else if &dx in ('9110','9130','9150','9160','9170','9190')                       then &dx='9100 ';
 else if &dx in ('9189')                                                          then &dx='9181 ';
 else if &dx in ('9195')                                                          then &dx='9194 ';
 else if &dx in ('9196')                                                          then &dx='9156 ';
 else if &dx in ('9212','9213','9219')                                            then &dx='920  ';
 else if &dx in ('9222','9223')                                                   then &dx='9221 ';
 else if &dx in ('92310','92311','92320','9233','9238','9239')                    then &dx='92300';
 else if &dx in ('92401','92411','92420','92421','9243','9245')                   then &dx='92400';
 else if &dx in ('9330')                                                          then &dx='933  ';
 else if &dx in ('938')                                                           then &dx='936  ';
 else if &dx in ('94321','94421','94500','94522','94526','9462','9490')           then &dx='94120';
 else if &dx in ('9700')                                                          then &dx='9691 ';
 else if &dx in ('V709','v709')                                                   then &dx='V708 ';
 
 /* 7/16/01: The following groupings were added by the Washington DC docs */
 
else if &dx = '0380'                                                              then &dx='0381';
else if &dx in ('25060','25061','25081','25082','25083')                          then &dx='25080';
else if &dx = '2740'                                                              then &dx='2749';
else if &dx = '2761'                                                              then &dx='2765';
else if &dx = '2768'                                                              then &dx='2767';
else if &dx = '2910'                                                              then &dx='29181';
else if &dx = '30300'                                                             then &dx='30301';
else if &dx = '30420'                                                             then &dx='30561';
else if &dx = '3080'                                                              then &dx='3089';
else if &dx = '3090'                                                              then &dx='311';
else if &dx = '38100'                                                             then &dx='3814';
else if &dx = '38200'                                                             then &dx='38110';
else if &dx in ('40291','40391','40493')                                          then &dx='4019';
else if &dx in ('41001','41011','41021','41041','41071')                          then &dx='41091';
else if &dx in ('41400','41401')                                                  then &dx='4149';
else if &dx = '4260'                                                              then &dx='42613';
else if &dx = '42732'                                                             then &dx='42731';
else if &dx = '4279'                                                              then &dx='42789';
else if &dx in ('43311','43401','43411','43491')                                  then &dx='4359';
else if &dx = '4554'                                                              then &dx='4552';
else if &dx = '4610'                                                              then &dx='4619';
else if &dx in ('4661','46611')                                                   then &dx='46619';
else if &dx = '4730'                                                              then &dx='4739';
else if &dx = '4770'                                                              then &dx='4781';
else if &dx in ('481','4821','4824','48283','48289')                              then &dx='485';
else if &dx = '53081'                                                             then &dx='5301';
else if &dx in ('53100','53140','53240')                                          then &dx='5339';
else if &dx in ('5400','5401','5409')                                             then &dx='541';
else if &dx = '56081'                                                             then &dx='5609';
else if &dx in ('57400','57410','5750')                                           then &dx='57420';
else if &dx in ('5770','5771')                                                    then &dx='5772';
else if &dx = '5950'                                                              then &dx='5990';
else if &dx = '6089'                                                              then &dx='6084';
else if &dx in ('6142','6143')                                                    then &dx='6149';
else if &dx in ('6331','6338')                                                    then &dx='6339';
else if &dx in ('63491','63492')                                                  then &dx='63490';
else if &dx in ('64183','64313')                                                  then &dx='64303';
else if &dx = '6850'                                                              then &dx='6851';
else if &dx = '71696'                                                             then &dx='71695';
else if &dx = '71949'                                                             then &dx='71947';
else if &dx in ('7213','72210','7241')                                            then &dx='7243';
else if &dx = '72709'                                                             then &dx='72705';
else if &dx in ('7803','78031')                                                   then &dx='78039';
else if &dx = '8024'                                                              then &dx='8028';
else if &dx in ('80700','80703')                                                  then &dx='80701';
else if &dx in ('81201','81305')                                                  then &dx='81200';
else if &dx = '81343'                                                             then &dx='81383';
else if &dx = '82101'                                                             then &dx='82100';
else if &dx in ('82380','82381')                                                  then &dx='82382';
else if &dx in ('8240','8244','8246')                                             then &dx='8242';
else if &dx = '8250'                                                              then &dx='82520';
else if &dx = '83104'                                                             then &dx='83100';
else if &dx = '8408'                                                              then &dx='8409';
else if &dx = '84213'                                                             then &dx='84209';
else if &dx = '8441'                                                              then &dx='8448';
else if &dx = '8471'                                                              then &dx='8472';
else if &dx in ('87200','8728')                                                   then &dx='87201';
else if &dx in ('8738','8748')                                                    then &dx='8744';
else if &dx = '88110'                                                             then &dx='88120';
else if &dx = '8821'                                                              then &dx='8822';
else if &dx in ('8831','8832')                                                    then &dx='8830';
else if &dx = '8921'                                                              then &dx='8920';
else if &dx in ('9104','9114')                                                    then &dx='9105';
else if &dx = '9134'                                                              then &dx='9135';
else if &dx = '9140'                                                              then &dx='9141';
else if &dx in ('9164','9165')                                                    then &dx='9175';
else if &dx = '9180'                                                              then &dx='9181';
else if &dx = '92232'                                                             then &dx='92231';
else if &dx in ('9331','9351')                                                    then &dx='933';
else if &dx = '9404'                                                              then &dx='9409';
else if &dx = '94524'                                                             then &dx='94420';
else if &dx = '9592'                                                              then &dx='9593';
else if &dx in ('9630','9690')                                                    then &dx='9654';
else if &dx = '9694'                                                              then &dx='9691';
else if &dx in ('9985','99859','99889')                                           then &dx='99883';
else if &dx = 'V589'                                                              then &dx='V5889';

%mend recode;

%macro ACS(dx); /* Ambulatory-care sensitive dxs, slightly incomplete since only dx is tested */
(
    substr(&dx,1,3) in

                 ('033','390','391','037','045','345','481','483','485','486',
                  '462','463','465','011','012','013','014','015','016','017',
                  '018','491','492','494','496','493','681','682','683','686',
                  '590','260','261','262','521','522','523','525','528','382',
                  '428','413','614')
                  
                  or
                  
    substr(&dx,1,4) in

                 ('7803','4721','2501','2502','2503','2508','2509',
                  '2500','2512','5589','5990','5999','2765','2680',
                  '2681','4660','4822','4823','4829','5184','4010',
                  '4019','4111','4118','3200','2801','2808','2809',
                  '7834',

                  '7070','7071','7078','7079') /* new skin graft dxs w/o drgs, 4/27/01 */
                  
                  or

    substr(&dx,1,5) in
    
                  ('40201','40211','40291','40210','40290','40200')
)
%mend ACS;

%macro injury(dx); /* injury dxs */
(
    substr(&DX,1,1) IN ('8','9')
 or substr(&dx,1,2) = 'E8'
 or substr(&dx,1,3) in (
 'E90'
 'E91'
 'E92'
 'E93'
 'E94'
 'E96'
 'E97'
 'E98')
)
%mend injury;

%macro psych(dx); /* psychiatric dxs */
(
 substr(&dx,1,3) in (

 '290'
 '293'
 '294'
 '295'
 '296'
 '297'
 '298'
 '299'
 '300'
 '301'
 '302'
 '306'
 '307'
 '308'
 '309'
 '310'
 '311'
 '312'
 '313'
 '314'
 '315'
 '316'
 '317'
 '318'
 '319'
 'E95')
 
 or
 
 substr(&dx,1,4) in (

 '6484'
 'V110'
 'V111'
 'V112'
 'V114'
 'V115'
 'V116'
 'V117'
 'V118'
 'V119'
 'V710'
 'V790')
) 
%mend psych;
 
%macro drug(dx); /* substance abuse dxs not including alchohol-related */
(
 substr(&dx,1,3) in ('292' '304') or
 
 substr(&dx,1,4) in (

 '3052'
 '3053'
 '3054'
 '3055'
 '3056'
 '3057'
 '3058'
 '3059'
 '3576'
 '6483'
 '6555'
 '7795')
 
 or
 
 &dx in (
 
 '76072'
 '76073'
 '76075')
)
%mend drug;

%macro alcohol(dx); /* alcohol-related dxs */
(
 substr(&dx,1,3) in ('291' '303') or
 
 substr(&dx,1,4) in (

 '3050'
 '3575'
 '4255'
 '5353'
 '5710'
 '5712'
 '5713'
 '7903'
 'V704'
 'V113'
 'V791')
 
 or &dx = '76071'

)
%mend alcohol;