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
	   keep APLOIL00 ADDAGB00 ADD06E00 COUNTRY Married education hh_income ACADMO00 APTRDE00 see_friends see_parents ADGEST00 waz_birth waz_recent
			pregnancy_smoke AHCSEX00 AOVWT2 APDEAN00 APTRDE00 treat_now_depression ACNOBA00 Age_First_Solid total_mom_kids parity
			feed_type_3mos birth_weight recent_weight ACBAGE00
			pttype2 MCSID nh2 sptn00;
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

 * Create a few additional that were missed;
	If Age_First_solid=-1 then Age_First_Solid=ACBAGE00;
	Else Age_First_solid=Age_First_Solid/30;

	If parity=0 then Age_parity_0 = ADDAGB00; else Age_parity_0=.;
	If parity>0 then Age_parity_gt0 = ADDAGB00; else Age_parity_gt0=.;

	wt_change = recent_weight - birth_weight;
	waz_change = waz_recent - waz_birth;
run;

  * Get distributions overall ;
	proc univariate data=dat2 outtable=table noprint;
	proc print data=table;
	var _VAR_ _NOBS_  _NMISS_ _MEAN_ _STD_ _MIN_ _MAX_;
	title"";
	proc contents data=dat2 position;
	proc print data=table;run;


*---* Create data set to be used in regression *-----*
* Remove vars with lots of missings;
  data model_dat;
  set dat2 (drop=age_first_solid  ACNOBA00 ACBAGE00 APTRDE00 see_parents);

run;
*-----* Create anayltic sample for Table 1 *----;
* For table 1, need to also drop obs with any missings;
  data table1_dat;
  set model_dat (drop=age_parity_0 age_parity_gt0); * Have to drop and recreate these after getting rid of other missing obs since missing is valid depending on parity value;

  	* Drop rows with any missing vars;
  	  if cmiss(of _all_) then delete;	

	If parity=0 then Age_parity_0 = ADDAGB00; else Age_parity_0=.;
	If parity>0 then Age_parity_gt0 = ADDAGB00; else Age_parity_gt0=.;

run;



/*-----------------------
* Get stats (Table 1);
------------------------*/

  *-------------------------*;
  *----- Continuous  *------*;
  *-------------------------*;
      data t1_cont;
	  set table1_dat; keep pregnancy_smoke_grp ADDAGB00 parity age_parity_0 age_parity_gt0 hh_income ADGEST00  birth_weight recent_weight wt_change waz_birth waz_recent waz_change;

	* Stats for all obs;
	  proc univariate data=t1_cont  (drop=pregnancy_smoke_grp)  outtable=t1c_out noprint;  run;

	* Stats for smoke groups;
	  proc sort data=t1_cont; by pregnancy_smoke_grp;
	  proc univariate data=t1_cont outtable=t1cs_out noprint;
	  by pregnancy_smoke_grp;	  
	  run;

	* Format for output: create four data sets, one each for all and each level of pregnancy_smoke_grp, then merge and print;
	  data t1c_out_all;
	  set t1c_out (keep=_VAR_ _NOBS_ _MEAN_ _STD_);
			rename	_NOBS_=nobs_all 	_MEAN_=mean_all		_STD_=std_all;
			proc sort; by _VAR_;	run;
	  data grp_1;
		set t1cs_out (keep=_VAR_ pregnancy_smoke_grp _NOBS_ _MEAN_ _STD_);
			where pregnancy_smoke_grp=1;
			rename	_NOBS_=nobs_1 	_MEAN_=mean_1	_STD_=std_1;
			drop pregnancy_smoke_grp;
			proc sort; by _VAR_;	run;
		data grp_2;
		set t1cs_out (keep=_VAR_ pregnancy_smoke_grp _NOBS_ _MEAN_ _STD_);
			where pregnancy_smoke_grp=2;
			rename _NOBS_=nobs_2 	_MEAN_=mean_2	_STD_=std_2;
			drop pregnancy_smoke_grp;
			proc sort; by _VAR_;	run;
		data grp_3;
		set t1cs_out (keep=_VAR_ pregnancy_smoke_grp _NOBS_ _MEAN_ _STD_);
			where pregnancy_smoke_grp=3;
			rename	_NOBS_=nobs_3	_MEAN_=mean_3	_STD_=std_3;
			drop pregnancy_smoke_grp;
			proc sort; by _VAR_;	run;

		proc contents data=table1_dat position out=cont;proc print data=cont;run;
		data names;
		set cont (keep=NAME Label);
			rename NAME=_VAR_;
			proc sort; by _VAR_;

		data table_out;
		merge t1c_out_all grp_1 grp_2 grp_3;
		by _VAR_;  
			proc print data=table_out;

  	* ANOVA/p-val for continuous;
		proc anova data=t1_cont outstat=cont_out;
		class pregnancy_smoke_grp;
		model waz_recent--waz_birth wt_change--Age_parity_gt0=pregnancy_smoke_grp;		
	run;
     * Merge with table_out;
	   data cont_out2;
	   set cont_out (keep=_NAME_ PROB _SOURCE_);
	    where _SOURCE_="pregnancy_smoke_grp";
		rename _NAME_=_VAR_;
		drop _SOURCE_;
		proc sort; by _VAR_;
		proc print data=cont_out2;run;

	  data cont_all;
	  merge table_out cont_out2;
	  by _VAR_;
	  proc print data=cont_all;
	  run;

	  
  *-------------------------*;
  *----- Categorical  *------*;
  *-------------------------*;
  data cat_dat;
  set table1_dat (keep=pregnancy_smoke_grp ADD06E00 COUNTRY Married education APLOIL00 treat_now_depression see_friends AHCSEX00 feed_type_3mos);
run;

  * Loop through list of categorical vars, running proc freq for each and creating output data sets;	
	%macro cat_tbl1;
		%local i next_name varn;
		%let varn=ADD06E00 COUNTRY Married education APLOIL00 treat_now_depression see_friends AHCSEX00 feed_type_3mos;
		%put &varn;
		%do i=1 %to %sysfunc(countw(&varn));
			%let next_name = %scan(&varn, &i);
	
			proc freq data=cat_dat NOPRINT;
			tables &next_name * pregnancy_smoke_grp /chisq outpct out=freq_&next_name;
			output out=chisq_&next_name PCHI;
			run;

		   *Separate into different data sets by preg smoke grp and merge by name to create three sets of cols;
			data freq_&next_name._1; 
			set freq_&next_name (drop=PERCENT PCT_ROW rename=(COUNT=COUNT_1 PCT_COL=PCT_COL_1)); where pregnancy_smoke_grp=1;			
				proc sort; by &next_name;
			data freq_&next_name._2;
			set freq_&next_name (drop=PERCENT PCT_ROW rename=(COUNT=COUNT_2 PCT_COL=PCT_COL_2)); where pregnancy_smoke_grp=2;		
				proc sort; by &next_name;
			data freq_&next_name._3;
			set freq_&next_name (drop=PERCENT PCT_ROW rename=(COUNT=COUNT_3 PCT_COL=PCT_COL_3)); where pregnancy_smoke_grp=3;
				proc sort; by &next_name;

			data out;
			merge freq_&next_name._1 freq_&next_name._2 freq_&next_name._3;
			by &next_name;
				drop pregnancy_smoke_grp;				

			data out_&next_name;
			merge out chisq_&next_name;
		
			proc print data=out_&next_name;	run;
		%end;			
	%mend cat_tbl1;

	ods excel file = "L:\UK Project\Exploratory results\Table 1.xlsx" options(sheet_interval='none') ;
	%cat_tbl1;
	ods excel close;


*------------------*;
* Model			   *;
*------------------*;

 data model_dat2;
 *set model_dat (drop=pregnancy_smoke total_mom_kids); 
 set table1_dat;
	* Combine age_parity into a single variable;
		If age_parity_0 ne . then age_parity=age_parity_0;
		Else if age_parity_gt0 ne . then age_parity=age_parity_gt0;

	* Create dummies - treat_now_depression, married go in as-is b/c already 0/1s;
 		*proc freq;
		*tables APLOIL00 APDEAN00 ADD06E00 AHCSEX00 COUNTRY feed_type_3mos education hh_income see_friends treat_now_depression Married parity;
		*format _All_;

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
		
		If hh_income=1 then d_income=1;
		Else if hh_income in (2,3,4) then d_income=0;

		If see_friends=1 then d_seeFriends=1;
		Else if see_friends=2 then d_SeeFriends=0;

run;


* Export data for analysis in SPSS;
  data analysis.model_dat;
  set model_dat2;

  run;

*-------------------------------------------------------------------------------------*
*
* Regressions
*
*-------------------------------------------------------------------------------------*;

proc contents data=table1_dat position;run;
proc contents data=analysis.model_dat position;run;

data model_dat;
set analysis.model_dat
	(keep=MCSID pttype2 sptn00 aovwt2 waz_change pregnancy_smoke_grp ADDAGB00 ADGEST00 ACADMO00 parity d_illness--d_seeFriends Married treat_now_depression);

data model_dat2;
	retain MCSID pttype2 sptn00 aovwt2 waz_change pregnancy_smoke_grp ADDAGB00 ADGEST00 ACADMO00 parity
			d_illness d_depression d_nonwhite d_female d_otherUK d_noBreast_3mos d_degree d_income d_seeFriends Married treat_now_depression;
set model_dat;
run;
proc contents position;run;

* First model;	
	PROC SURVEYREG data=model_dat2;	
	model waz_change=pregnancy_smoke_grp -- treat_now_depression;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;

* Just preg_smoke_grp;
	PROC SURVEYREG data=model_dat2;	
	model waz_change=pregnancy_smoke_grp;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;

run;
proc freq; tables pregnancy_smoke_grp;run;
run;
