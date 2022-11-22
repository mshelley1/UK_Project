*
* Run analyses on data set created in "data prep.sas"
*;
*-----------------*;
* Potential next steps:
* 1) Explore ACADMO - baby health problems;

libname analysis "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Analysis Data\Data sets";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

/*PROC CONTENTS DATA=ANALYSIS.ANALYSIS_DAT_2;RUN;*/

data dat1;
set analysis.analysis_dat_3 (keep=APLOIL00 ADDAGB00 ADD06E00 COUNTRY Married education hh_income ACADMO00 APTRDE00 see_friends see_parents ADGEST00 waz_birth waz_recent
			pregnancy_smoke AHCSEX00 AOVWT2 APDEAN00 APTRDE00 treat_now_depression ACNOBA00 Age_First_Solid total_mom_kids parity
			feed_type_3mos birth_weight recent_weight ACBAGE00
			pttype2 MCSID nh2 sptn00
			Probs_in_pregnancy
			DepStrAnxScale
			ADMCPO00);      * Vars like BMI of mother vars were considered but had too many missing - see "analysis.sas";

	* Drop obs with outlier Z scores and mothers 15 or younger and non-singletons;
	   where abs(waz_recent) < 7  /* leaves 18,773 */ and
	   		 abs(waz_birth) < 7   /* leaves 18,767 */ and
			 ADDAGB00 >= 16		  /* leaves 18,663 */ and
			 ACNOBA00 ne 2 ;

/*proc freq; tables APILWM0A--APILWM0G Probs_in_pregnancy;run;*/

  * Group pregnancy_smoke;
	pregnancy_smoke_grp=.;
	If pregnancy_smoke = 0 then pregnancy_smoke_grp=1;
	Else if 0 < pregnancy_smoke <= 10 then pregnancy_smoke_grp=2;
	Else if 10 < pregnancy_smoke then pregnancy_smoke_grp=3;

	* Make dummies;
	  psg_two =.; psg_three=.;
	  If pregnancy_smoke_grp=2 then psg_two=1;   else if pregnancy_smoke_grp ne . then psg_two=0;
	  If pregnancy_smoke_grp=3 then psg_three=1; else if pregnancy_smoke_grp ne . then psg_three=0;

 * Create a few additional that were missed;
	If Age_First_solid=-1 then Age_First_Solid=ACBAGE00;
	Else Age_First_solid=Age_First_Solid/30;

	If parity=0 then Age_parity_0 = ADDAGB00; else Age_parity_0=.;
	If parity>0 then Age_parity_gt0 = ADDAGB00; else Age_parity_gt0=.;

	wt_change = recent_weight - birth_weight;
	waz_change = waz_recent - waz_birth;

  * Combine age_parity into a single variable;
	If age_parity_0 ne . then age_parity=age_parity_0;
	Else if age_parity_gt0 ne . then age_parity=age_parity_gt0;

  * Create dummies;
	IF APLOIL00=1 then d_illness=1;
	Else if APLOIL00=2 then d_illness=0;

	If APDEAN00=1 then d_depression=1;
	Else if APDEAN00=2 then d_depression=0;

	If ADD06E00=1 then d_nonwhite=0;
	Else if ADD06E00 ne . then d_nonwhite=1;

	If AHCSEX00=1 then d_female=0;
	Else if AHCSEX00=2 then d_female=1;

	If COUNTRY=1 then d_otherUK=0;
	Else if COUNTRY ne . then d_otherUK=1;

	If feed_type_3mos="No breast feeding" then d_noBreast_3mos=1;
	Else if feed_type_3mos ne "" then d_noBreast_3mos=0;

	If education in (1,2) then d_degree=1;
	Else if education=9 then d_degree=0;
	
/*	
	If hh_income=1 then d_income=1;
	Else if hh_income in (2,3,4) then d_income=0;
		income_2
		income_3
		income_4
		income_5
*/
	If see_friends=1 then d_seeFriends=1;
	Else if see_friends=2 then d_SeeFriends=0;

	If ADMCPO00=-1 then poverty=.;
	Else poverty=ADMCPO00;
	proc freq; tables poverty;run;
;

run;

*-------------------------------------------------------------------------------------*
* Regressions
*-------------------------------------------------------------------------------------*;

 data model_dat;
	retain MCSID pttype2 sptn00 aovwt2 waz_change /*pregnancy_smoke_grp*/ psg_two psg_three ADDAGB00 ADGEST00 ACADMO00 parity
			d_illness d_depression d_nonwhite d_female d_otherUK d_noBreast_3mos d_degree d_seeFriends Married
			treat_now_depression DepStrAnxScale poverty waz_birth;
set dat1 (keep=MCSID pttype2 sptn00 aovwt2 waz_change pregnancy_smoke_grp psg_two psg_three ADDAGB00 ADGEST00 ACADMO00 parity d_illness--d_seeFriends Married
				treat_now_depression DepStrAnxScale poverty waz_birth);
run;

PROC CONTENTS DATA=model_Dat POSITION;
run;

proc freq data=model_dat;
tables pttype2--waz_birth;run;

proc univariate data=model_dat noprint;
var pttype2--waz_birth;
output out=chk_miss nmiss=;
run;

* First model;	
  title "Original Model";
	PROC SURVEYREG data=model_dat;	
	model waz_change=pregnancy_smoke_grp -- treat_now_depression;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
run;

* Dep/Anx/Str scale;	
  title "New menal health var";
	PROC SURVEYREG data=model_dat (drop=d_depression treat_now_depression);	
	model waz_change=pregnancy_smoke_grp -- DepStrAnxScale ;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
run;

* Poverty;
  title "Poverty var";
	PROC SURVEYREG data=model_dat (drop=d_depression treat_now_depression);	
	model waz_change=psg_two -- DepStrAnxScale poverty;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
run;

* Z_scores at birth;
  title "Z scores at birth as dep var";
	PROC SURVEYREG data=model_dat (drop=d_depression treat_now_depression);	
	model waz_birth=pregnancy_smoke_grp -- DepStrAnxScale;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
run;
  title "Z scores at birth as dep var; preg_smoke_grp as dummies";
	PROC SURVEYREG data=model_dat (drop=d_depression treat_now_depression);	
	model waz_birth=psg_two -- DepStrAnxScale;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
run;
 title "Z scores at birth as dep var - crude model";
	PROC SURVEYREG data=model_dat (drop=d_depression treat_now_depression);	
	model waz_birth=psg_two psg_three;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
run;

 
*-----------------------------------------------*;
* Impute;
*------------------------------------------------*;

* Following outline of UCLA page: https://stats.oarc.ucla.edu/sas/seminars/multiple-imputation-in-sas/mi_new_1/;

* prepare data 0 drop vars not needed, obs where dep var and exposure are missing;
  data model_dat_for_impute;
  set model_dat (drop=waz_birth pregnancy_smoke_grp);
	where waz_change ne . and psg_two ne . and psg_three ne .;

* Check for missings and patterns of missing;
  proc means data=model_dat_for_impute nmiss;	

  proc mi data=model_dat_for_impute nimpute=0;
  ods select misspattern;
 	*poverty, dep scale, and accadmo had the most missings;

* look for aux vars for vars of interest with high missings;
  proc corr data=model_Dat_for_impute;
	* no corr over .4 on the three vars of interest wiht high missings.;
run;

* Impute;
  PROC MI data=model_dat_for_impute out=imputed_dat seed=54321;
  VAR pttype2 psg_two psg_three ADDAGB00 ADGEST00 ACADMO00 parity d_illness d_depression d_nonwhite d_noBreast_3mos 
    d_female d_otherUK d_Degree d_seeFriends Married treat_now_Depression DepStrAnxScale poverty;
run;

proc contents data=imputed_dat position;run;

* Run model on imputed data. Include by to do it separately for each of the imputed data sets. We use surveyreg instead of glm;
  title "Multiple imputation model";
	PROC SURVEYREG data=imputed_dat;	
	model waz_change=psg_two -- poverty;
	by _imputation_;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;

proc contents data=a_parm_Est;
run;

proc print data=a_parm_est (obs=100);run;

* Combine output from model results on the imputed data sets;
  proc mianalyze parms=a_parm_est;
  modeleffects psg_two psg_three ADDAGB00 ADGEST00 ACADMO00 parity d_illness d_nonwhite d_female d_depression d_otheruk d_nobreast_3mos d_degree d_seefriends married treat_now_depression depstranxscale poverty;
run;


  proc mianalyze parms=a_parm_est;run;







PROC MIANALYZE parms(classvar=classval)=model_Dat;
Class /*list categorical vars here and ref category*/ SMOKE YY_DOB MATAGE MATRACE INSUR rMARRIED INFICU BRSTFD PREDEPR;
modeleffects /*list all vars here except outcome and exposure vars*/ SMOKE YY_DOB MATAGE MATRACE INSUR rMARRIED INFICU BRSTFD PREDEPR;
ods output parameterEstimates=imputed_dat;
RUN;



PROC MI data=model_dat out=imputed_dat;
EM ;
VAR pttype2 psg_two psg_three ADDAGB00 ADGEST00 ACADMO00 parity d_illness d_depression d_nonwhite d_noBreast_3mos 
    d_female d_otherUK d_Degree d_seeFriends Married treat_now_Depression DepStrAnxScale poverty;
run;

PROC MIANALYZE parms(classvar=classval)=imputed_dat;
Class pttype2 psg_two psg_three d_illness d_nonwhite d_female d_otherUK d_noBreast_3mos d_degree d_seeFriends Married POVERTY;
modeleffects ACADMO00 ADDAGB00 ADGEST00 parity DepStrAnxScale pttype2 psg_two psg_three d_illness d_nonwhite d_female d_otherUK d_noBreast_3mos d_degree d_seeFriends Married POVERTY;
ods output parameterEstimates=imputed_dat2;
RUN;
run;

/*
* Just preg_smoke_grp;
  title "Preg_smoke_Grp only";
	PROC SURVEYREG data=model_dat;	
	model waz_change=pregnancy_smoke_grp;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
run;
*/

