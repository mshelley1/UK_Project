*
* Run analyses on data set created in "data prep.sas"
* NOTE: all variable creation moved to data prep.sas. See old commits for previous versions.
*-----------------*;
* Potential next steps:
* 1) Explore ACADMO - baby health problems;

libname analysis "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Analysis Data\Data sets";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

/*PROC CONTENTS DATA=ANALYSIS.ANALYSIS_DAT_2;RUN;*/

data dat1;
set analysis.analysis_dat_3 (keep=APLOIL00 ADDAGB00 ADD06E00 COUNTRY Married education hh_income ACADMO00 APTRDE00
			see_friends see_parents ADGEST00 waz_birth waz_recent waz_change d_illness d_seeFriends
			pregnancy_smoke AHCSEX00 AOVWT2 APDEAN00 APTRDE00 treat_now_depression ACNOBA00 Age_First_Solid total_mom_kids parity
			feed_type_3mos birth_weight recent_weight ACBAGE00  ACBAGE00 APSMUS0A APSMUS0B APSMUS0C APSMUS0D APSMMA00
			pttype2 MCSID nh2 sptn00
			Probs_in_pregnancy
			DepStrAnxScale
			d_illness d_depression d_nonwhite d_female d_otherUK d_degree
			pregnancy_smoke_grp current_smoke_grp feed3mo_breast feed3mo_mixed 
			ADMCPO00 poverty);      * Vars like BMI of mother vars were considered but had too many missing - see "analysis.sas";

	* Drop obs with outlier Z scores and mothers 15 or younger and non-singletons;
	   where abs(waz_recent) < 7  /* leaves 18,773 */ and
	   		 abs(waz_birth) < 7   /* leaves 18,767 */ and
			 ADDAGB00 >= 16		  /* leaves 18,663 */ and
			 ACNOBA00 ne 2 ;

	* Collapse some continuous vars;
		health_probs=.;
		If ACADMO00=0 then health_probs=0;
		Else if ACADMO00=1 then health_probs=1;
		Else if ACADMO00=2 then health_probs=2;
		Else if ACADMO00 >= 3 then health_probs=3;

		DSA_grp=.;
		If DepStrAnxScale=0 then DSA_grp=0;
		Else if DepStrAnxScale=1 then DSA_grp=1;
		Else if DepStrAnxScale >= 2 then DSA_grp=2;

run;

*-------------------------------------------------------------------------------------*
* Regressions
*-------------------------------------------------------------------------------------*;

 data model_dat;
	retain MCSID pttype2 sptn00 aovwt2 waz_change waz_birth pregnancy_smoke_grp current_smoke_grp feed_type_3mos ADDAGB00 ADGEST00 health_probs parity 
			treat_now_depression DSA_grp poverty  Married d_illness d_depression d_nonwhite d_female d_otherUK d_degree d_seeFriends;  
set dat1 (keep=MCSID pttype2 sptn00 aovwt2 waz_change waz_birth pregnancy_smoke_grp current_smoke_grp feed_type_3mos ADDAGB00 ADGEST00 parity 
			d_illness d_depression d_nonwhite d_female d_degree d_seeFriends Married d_otherUK
			treat_now_depression DSA_grp health_probs poverty);
/*
			If current_smoke_grp=1 then current_smoke_grp=0;
			Else If current_smoke_grp=2 or current_smoke_grp=3 then current_smoke_grp=1;
		
run;
PROC CONTENTS DATA=model_Dat POSITION;
run;
*/

*-----------------------------------------------*;
* Impute;
*------------------------------------------------*;

* Check for missings and patterns of missing;
/*  proc means data=model_dat_for_impute nmiss;	run;
  proc mi data=model_dat_for_impute nimpute=0;
  	ods select misspattern;
 	*poverty, dep scale, and accadmo had the most missings;*/

* Impute;
  PROC SURVEYIMPUTE data= model_dat ;   *https://www.lexjansen.com/phuse-us/2018/dh/DH04_ppt.pdf*; *https://support.sas.com/resources/papers/proceedings16/SAS3520-2016.pdf;
  class pregnancy_smoke_grp current_smoke_grp feed_type_3mos /*health_probs*/ parity /*treat_now_depression DSA_grp*/ Married poverty d_OtherUK /*d_illness*/ d_nonwhite d_female d_degree /*d_seeFriends*/;
  strata  pttype2;
  cluster  MCSID sptn00;
  weight  aovwt2;
  VAR  parity treat_now_depression DSA_grp Married poverty d_OtherUK d_illness d_nonwhite d_female d_degree d_seeFriends
		ADDAGB00 ADGEST00;
  output out=imputed_dat;
run;

proc mi data=imputed_dat nimpute=0;
  	ods select misspattern;run;
proc means data=imputed_dat nmiss;run;


* Run model on imputed data. ;
  title "*------------* surveyimpute model *-----------------*";
	PROC SURVEYREG data=imputed_dat ;	
	class pregnancy_smoke_grp(ref=first) current_smoke_grp(ref=first) feed_type_3mos(ref=first) /*health_probs*/ parity(ref=first) /*treat_now_depression DSA_grp*/ Married(ref=first)
		  poverty(ref=first) d_OtherUK(ref=first) /*d_illness*/ d_nonwhite(ref=first) d_female(ref=first) d_degree(ref=first) /*d_seeFriends*/;
	model waz_change= pregnancy_smoke_grp current_smoke_grp feed_type_3mos /*health_probs*/ parity /*treat_now_depression DSA_grp*/ Married poverty d_OtherUK /*d_illness*/ d_nonwhite d_female d_degree /*d_seeFriends*/
		ADDAGB00 ADGEST00 /solution;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;


* Girls v. boys;
  proc sort data=imputed_dat; by d_female;
  title "*------------* surveyimpute model - boys (d_female=0) v girls (d_female=1) *----------------*";
	PROC SURVEYREG data=imputed_dat ;	
	by d_female;
	class pregnancy_smoke_grp(ref=first) current_smoke_grp(ref=first) feed_type_3mos(ref=first) /*health_probs*/ parity(ref=first) /*treat_now_depression DSA_grp*/ Married(ref=first)
		  poverty(ref=first) d_OtherUK(ref=first) /*d_illness*/ d_nonwhite(ref=first) d_degree(ref=first) /*d_seeFriends*/;
	model waz_change= pregnancy_smoke_grp current_smoke_grp feed_type_3mos /*health_probs*/ parity /*treat_now_depression DSA_grp*/ Married poverty d_OtherUK /*d_illness*/ d_nonwhite  d_degree /*d_seeFriends*/		  
		  ADDAGB00 ADGEST00 /solution;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;

proc print data=a_parm_est;run;


* Intereaction terms;
  title "surveyimpute model - interaction terms";
	PROC SURVEYREG data=imputed_dat ;	
	class pregnancy_smoke_grp(ref=first) current_smoke_grp(ref=first) feed_type_3mos(ref=first) /*health_probs*/ parity(ref=first) /*treat_now_depression DSA_grp*/ Married(ref=first)
		  poverty(ref=first) d_OtherUK(ref=first) /*d_illness*/ d_nonwhite(ref=first) d_female(ref=first) d_degree(ref=first) /*d_seeFriends*/;
	model waz_change= pregnancy_smoke_grp current_smoke_grp feed_type_3mos /*health_probs*/ parity /*treat_now_depression DSA_grp*/ Married poverty d_OtherUK /*d_illness*/ d_nonwhite d_female d_degree /*d_seeFriends*/
		  current_smoke_grp*feed_type_3mos
		  ADDAGB00 ADGEST00 /solution;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;


	* Check, as we are not getting estimates for some of the interaction cats;
		 proc freq data=imputed_dat;
		 where waz_change ne .;
		 tables current_smoke_grp*feed_type_3mos /norow nocol;run; *small Ns in some of the cells;



  title "surveyimpute model - interaction terms";
	PROC SURVEYPHREG data=imputed_dat ;	
	class /*pregnancy_smoke_grp(ref=last)*/
		  current_smoke_grp (ref=last)
		  feed_type_3mos  (ref=last) /PARAM=ref;
/*		  parity(ref=first)
		  Married(ref=first) 
		  poverty(ref=first) 
		  d_OtherUK(ref=first)
		  d_nonwhite(ref=first)
		  d_female(ref=first)
		  d_degree(ref=first) */;
	model waz_change= 
 		 /* pregnancy_smoke_grp*/
		/*  current_smoke_grp*/
		  feed_type_3mos 
/*		  parity
		  Married
		  d_poverty
		  d_OtherUK
		  d_nonwhite
		  d_female
		  d_degree
		  ADDAGB0
		  ADGEST00 */
  		  current_smoke_grp*feed_type_3mos;
	strata  pttype2;
	cluster  MCSID sptn00; 
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;



* Intereaction terms;
title "surveyimpute model - interaction terms";


PROC SURVEYREG data=imputed_dat ;
class pregnancy_smoke_grp(ref=first) current_smoke_grp(ref=first) feed_type_3mos(ref=first) /*health_probs*/ parity(ref=first) /*treat_now_depression DSA_grp*/ Married(ref=first)
 poverty(ref=first) d_OtherUK(ref=first) /*d_illness*/ d_nonwhite(ref=first) d_female(ref=first) d_degree(ref=first) /*d_seeFriends*/ ;
model waz_change= pregnancy_smoke_grp current_smoke_grp feed_type_3mos /*health_probs*/ parity /*treat_now_depression DSA_grp*/ Married poverty d_OtherUK /*d_illness*/ d_nonwhite d_female d_degree /*d_seeFriends*/
 current_smoke_grp*feed_type_3mos
 ADDAGB00 ADGEST00;
strata  pttype2;
cluster  MCSID sptn00;
weight  aovwt2;
ods output ParameterEstimates=a_parm_est;
run;




**** Below did not work ****;

  title "surveyimpute model - interaction terms";
	PROC SURVEYREG data=imputed_dat ;	
	class pregnancy_smoke_grp(ref=last)
		  current_smoke_grp (ref=last)
		  feed_type_3mos  (ref=last)
		  parity(ref=first)
		  Married(ref=first) 
		  poverty(ref=first) 
		  d_OtherUK(ref=first)
		  d_nonwhite(ref=first)
		  d_female(ref=first)
		  d_degree(ref=first) ;
	model waz_change= 
 		  pregnancy_smoke_grp
		/*  current_smoke_grp*/
		 feed_type_3mos 
		  parity
		  Married
		  poverty
		  d_OtherUK
		  d_nonwhite
		  d_female
		  d_degree
		  ADDAGB00
		  ADGEST00
  		  current_smoke_grp*feed_type_3mos / solution;
	strata  pttype2;
	cluster  MCSID sptn00; 
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;

proc freq data=imputed_dat;
tables feed_type_3mos*current_smoke_grp/missing;run;
