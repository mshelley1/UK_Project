*
* Run analyses on data set created in "data prep.sas"
*;

libname analysis "L:\UK Project\Analysis Data\Data sets";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

/*PROC CONTENTS DATA=ANALYSIS.ANALYSIS_DAT_2;RUN;*/

data dat1;
set analysis.analysis_dat_3;

	/* Keep vars needed for revised Table 1 */
	   keep APLOIL00 ADDAGB00 NOCMHH ADD06E00 COUNTRY Married education hh_income ACADMO00 APTRDE00 see_friends see_parents ADGEST00 waz_birth waz_recent
			pregnancy_smoke AHCSEX00 AOVWT2 APDEAN00 APTRDE00 treat_now_depression ACNOBA00 Any_Breast_Milk Breast_Milk_Time--Age_First_Solid total_mom_kids parity
			feed_type_3mos Breast_Milk_time_cat first_other_food_cat birth_weight recent_weight ACBAGE00;
			; * BMI of mother vars hadd too many missing (>1000)

	* Drop obs with outlier Z scores and mothers 15 or younger and non-singletons;
	   where abs(waz_recent) < 7  /* leaves 18,773 */ and
	   		 abs(waz_birth) < 7   /* leaves 18,767 */ and
			 ADDAGB00 >= 16		  /* leaves 18,663 */ and
			 ACNOBA00 ne 2 ;
run;
data dat2;
set dat1;

  * Group pregnancy_smoke;
	pregnancy_smoke_grp=.;
	If pregnancy_smoke = 0 then pregnancy_smoke_grp=1;
	Else if 0 < pregnancy_smoke <= 10 then pregnancy_smoke_grp=2;
	Else if 10 < pregnancy_smoke then pregnancy_smoke_grp=3;

  *Indicators for table 1;
	If ADD06E00=. then do;	white=.; mixed_ethnicity=.; indian=.; pakistani_bangladeshi=.; black_blackbrit=.; other_ethnicity=.; end;
	Else do; white=0; mixed_ethnicity=0; indian=0; pakistani_bangladeshi=0; black_blackbrit=0; other_ethnicity=0; end;	
	If ADD06E00=1 then white=1; 
	else If ADD06E00=2 then mixed_ethnicity=1; 
	else If ADD06E00=3 then indian=1; 
	else If ADD06E00=4 then pakistani_bangladeshi=1; 
	else If ADD06E00=5 then black_blackbrit=1; 
	else If ADD06E00=6 then other_ethnicity=1; 

	If COUNTRY=. then do; england=.; wales=.; scotland=.; northIreland=.; end;
	Else do; england=0; wales=0; scotland=0; northIreland=0; end;
	If COUNTRY=1 then england=1;
	else if COUNTRY=2 then wales=1;
	else if COUNTRY=3 then scotland=1;
	else if COUNTRY=4 then northIreland=1;

	If EDUCATION=. then do;	nvq_1_to_3=.; nvq_4_to_5=.; nvq_none_or_abroad=.; end;
	Else do; nvq_1_to_3=0; nvq_4_to_5=0; nvq_none_or_abroad=0; end;
	If EDUCATION=1 then nvq_1_to_3=1;
	else if EDUCATION=2 then nvq_4_to_5=1;
	else if EDUCATION=9 then nvq_none_or_abroad=1;

	health_probs=.;
	If APLOIL00 =1 then health_probs=1;
	Else if APLOIL00 =2 then health_probs=0;

	If see_parents=2 then see_parents=0; 
	If see_friends=2 then see_friends=0;

	If AHCSEX00=1 then male=1; Else if AHCSEX00 ne . then male=0;

	If feed_type_3mos="" then do; mo3_breast_only=.; mo3_mixed=.; mo3_nobreast=.;end;
	Else do; mo3_breast_only=0; mo3_mixed=0; mo3_nobreast=0; end;
	If feed_type_3mos="Exclusive breast fed" then mo3_breast_only=1;
	else if feed_type_3mos="Mixed" then mo3_mixed=1;
	else if feed_type_3mos="No breast feeding" then mo3_nobreast=1;

	If Age_First_solid=-1 then Age_First_Solid=ACBAGE00;
	Else Age_First_solid=Age_First_Solid/30;


* Weight change vars;
	wt_change = recent_weight - birth_weight;
	waz_change = waz_recent - waz_birth;

drop ACNOBA00 feed_type_3mos NOCMHH Any_Breast_Milk Breast_Milk_Time Age_First_Formula Age_First_CowMilk Age_First_OthMilk first_other_food_cat Breast_Milk_Time_cat ACBAGE00;
run;

  * Get distributions overall ;
	proc univariate data=dat2 outtable=table noprint;
	proc print data=table;
	var _VAR_ _NOBS_  _NMISS_ _MEAN_ _STD_ _MIN_ _MAX_;
	title"";
	proc contents data=dat2 position;
RUN;


*-----* Create anayltic sample *----;
* Remove vars with lots and obs with any missings;
  data table1_dat;
  set dat2 (drop=APLOIL00 -- APTRDE00 ADD06E00 ACADMO00--COUNTRY pregnancy_smoke education see_parents);
  	* Drop rows with any missing vars;
  	  if cmiss(of _all_) then delete;	

	* Create parity/Age which will result in missings due to unique consturction;
	  If parity=0 then Age_parity_0 = ADDAGB00; else Age_parity_0=.;
	  If parity>0 then Age_parity_gt0 = ADDAGB00; else Age_parity_gt0=.;

run;

* Get stats (Table 1);
  proc sort data=table1_dat;
  by pregnancy_smoke_grp;

  proc contents data=table1_dat;
run;
  
	* Stats for all obs;
	  proc univariate data=table1_dat outtable=table1a noprint;
	/*  proc print data=table1a;  var _VAR_  _NOBS_ _MEAN_ _STD_; */
	  run;

	* Stats for smoke groups;
	  proc univariate data=table1_dat outtable=table1b noprint;
	  by pregnancy_smoke_grp;
	/*  proc print data=table1b;  var _VAR_ pregnancy_smoke_grp _NOBS_ _MEAN_ _STD_; */
	  run;

	* Format for output: create four data sets, one each for all and each level of pregnancy_smoke_grp, then merge and print;
	  data table1_all;
	  set table1a (keep=_VAR_ _NOBS_ _MEAN_ _STD_);
			rename
				_NOBS_=nobs_all 
				_MEAN_=mean_all
				_STD_=std_all;
			proc sort; by _VAR_;	run;
	  data grp_1;
		set table1b (keep=_VAR_ pregnancy_smoke_grp _NOBS_ _MEAN_ _STD_);
			where pregnancy_smoke_grp=1;
			rename
				_NOBS_=nobs_1 
				_MEAN_=mean_1
				_STD_=std_1;
			drop pregnancy_smoke_grp;
			proc sort; by _VAR_;	run;
		data grp_2;
		set table1b (keep=_VAR_ pregnancy_smoke_grp _NOBS_ _MEAN_ _STD_);
			where pregnancy_smoke_grp=2;
			rename
				_NOBS_=nobs_2 
				_MEAN_=mean_2
				_STD_=std_2;
			drop pregnancy_smoke_grp;
			proc sort; by _VAR_;	run;
		data grp_3;
		set table1b (keep=_VAR_ pregnancy_smoke_grp _NOBS_ _MEAN_ _STD_);
			where pregnancy_smoke_grp=3;
			rename
				_NOBS_=nobs_3
				_MEAN_=mean_3
				_STD_=std_3;
			drop pregnancy_smoke_grp;
			proc sort; by _VAR_;	run;

		proc contents data=table1_dat position out=cont;proc print data=cont;run;
		data names;
		set cont (keep=NAME Label);
			rename NAME=_VAR_;
			proc sort; by _VAR_;

		data table_out;
		merge names table1_all grp_1 grp_2 grp_3;
		by _VAR_;
					if _VAR_ = 'ADDAGB00' then sort_num=1;
				   	if _VAR_ = 'parity' then sort_num=2;
					if _VAR_ = 'Age_parity_0' then sort_num=3;
					if _VAR_ = 'Age_parity_gt0' then sort_num=4;
					if _VAR_ = 'white' then sort_num=5;
					if _VAR_ = 'mixed_ethnicity' then sort_num=6;
					if _VAR_ = 'indian' then sort_num=7;
					if _VAR_ = 'pakistani_bangladeshi' then sort_num=8;
					if _VAR_ = 'black_blackbrit' then sort_num=9;
					if _VAR_ = 'other_ethnicity' then sort_num=10;
					if _VAR_ = 'england' then sort_num=11;
					if _VAR_ = 'wales' then sort_num=12;
					if _VAR_ = 'scotland' then sort_num=13;
					if _VAR_ = 'northIreland' then sort_num=14;
					if _VAR_ = 'Married' then sort_num=15;
					if _VAR_ = 'nvq_1_to_3' then sort_num=16;
					if _VAR_ = 'nvq_4_to_5' then sort_num=17;
				   	if _VAR_ = 'nvq_none_or_abroad' then sort_num=18;
					if _VAR_ = 'hh_income' then sort_num=19;
					if _VAR_ = 'health_probs' then sort_num=20;
					if _VAR_ = 'treat_now_depression' then sort_num=21;
					if _VAR_ = 'see_friends' then sort_num=22;
					if _VAR_ = 'male' then sort_num=23;
					if _VAR_ = 'ADGEST00' then sort_num=23.01;
					if _VAR_ = 'Age_First_Solid' then sort_num=23.1;
					if _VAR_ = 'mo3_breast_only' then sort_num=23.2;
					if _VAR_ = 'mo3_mixed' then sort_num=23.3;
					if _VAR_ = 'mo3_nobreast' then sort_num=23.4;
					if _VAR_ = 'birth_weight' then sort_num=24;
					if _VAR_ = 'recent_wegiht' then sort_num=24.1;
					if _VAR_ = 'wt_change' then sort_num=24.2;
					if _VAR_ = 'waz_birth' then sort_num=25;
					if _VAR_ = 'waz_recent' then sort_num=26;
					if _var_ = 'waz_change' then sort_num=27;
			if sort_num ne .;
			proc sort; by sort_num;
			proc print data=table_out;

			
	run;
