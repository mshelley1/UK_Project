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
			feed_type_3mos birth_weight recent_weight ACBAGE00;
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
	/*
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
*/
	If Age_First_solid=-1 then Age_First_Solid=ACBAGE00;
	Else Age_First_solid=Age_First_Solid/30;

	If parity=0 then Age_parity_0 = ADDAGB00; else Age_parity_0=.;
	If parity>0 then Age_parity_gt0 = ADDAGB00; else Age_parity_gt0=.;

	wt_change = recent_weight - birth_weight;
	waz_change = waz_recent - waz_birth;

drop ACNOBA00 ACBAGE00 APTRDE00 see_parents;
run;

  * Get distributions overall ;
	proc univariate data=dat2 outtable=table noprint;
	proc print data=table;
	var _VAR_ _NOBS_  _NMISS_ _MEAN_ _STD_ _MIN_ _MAX_;
	title"";
	proc contents data=dat2 position;
RUN;

proc contents data=dat2 position;run;
proc print data=table;run;
*-----* Create anayltic sample *----;
* Remove vars with lots and obs with any missings;
  data table1_dat;
  set dat2 /*(drop=APLOIL00 -- APTRDE00 ADD06E00 ACADMO00--COUNTRY pregnancy_smoke education see_parents)*/
  	  (drop=Age_parity_0 Age_parity_gt0 age_first_solid);

  	* Drop rows with any missing vars;
  	  if cmiss(of _all_) then delete;	
	  	If parity=0 then Age_parity_0 = ADDAGB00; else Age_parity_0=.;
	    If parity>0 then Age_parity_gt0 = ADDAGB00; else Age_parity_gt0=.;
	proc contents data=table1_dat position;
run;


* Get stats (Table 1) for continuous vars;
/*
  proc means data=table1_dat;
  class pregnancy_smoke_grp;
  var ADDAGB00 parity hh_income ADGEST00 age_first_solid birth_weight recent_weight wt_change waz_birth waz_recent waz_change;
  output out=cont_vars mean=  ;
  
  proc print data=cont_vars;
run;

  proc transpose data=cont_vars out=cont_vars_trans (drop=_type_) name=var_name;
  by pregnancy_smoke_grp;	
run;
  proc print data=cont_vars_trans;
  run;
*/  

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

