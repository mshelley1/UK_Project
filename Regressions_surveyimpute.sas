*
* Run analyses on data set created in "data prep.sas"
* NOTE: all variable creation moved to data prep.sas. See old commits for previous versions.
*-----------------*;
* Potential next steps:
* 1) Explore ACADMO - baby health problems;

libname analysis "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Analysis Data\Data sets";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

data dat1;
set analysis.analysis_dat_4;

*(keep=MCSID ACNUM00  APLOIL00 ADDAGB00 ADD06E00 COUNTRY Married education hh_income ACADMO00 APTRDE00
			see_friends see_parents ADGEST00 waz_birth waz_recent waz_change d_illness d_seeFriends
			pregnancy_smoke AHCSEX00 AOVWT2 APDEAN00 APTRDE00 treat_now_depression ACNOBA00 Age_First_Solid total_mom_kids parity
			feed_type_3mos birth_weight recent_weight ACBAGE00  ACBAGE00 APSMUS0A APSMUS0B APSMUS0C APSMUS0D APSMMA00
			pttype2 MCSID nh2 sptn00 Probs_in_pregnancy DepStrAnxScale d_illness d_depression d_nonwhite d_female d_otherUK d_degree
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
* Vars for model;
*-------------------------------------------------------------------------------------*;

 data model_dat;
	retain MCSID pttype2 sptn00 aovwt2 waz_change waz_birth pregnancy_smoke_grp current_smoke_grp feed_type_3mos ADDAGB00 ADGEST00 parity 
			 poverty  Married d_nonwhite d_female d_otherUK d_degree ;  
set dat1 (keep=MCSID ACNUM00 pttype2 sptn00 aovwt2 waz_change waz_birth pregnancy_smoke_grp current_smoke_grp feed_type_3mos ADDAGB00 ADGEST00 parity 
			d_nonwhite d_female d_degree  Married d_otherUK poverty);
run;

*-----------------------------------------------*;
* Impute;
*------------------------------------------------*;
* Impute;
  PROC SURVEYIMPUTE data= model_dat seed=135711;   *https://www.lexjansen.com/phuse-us/2018/dh/DH04_ppt.pdf*; *https://support.sas.com/resources/papers/proceedings16/SAS3520-2016.pdf;
  class pregnancy_smoke_grp current_smoke_grp feed_type_3mos parity Married poverty d_OtherUK d_nonwhite d_female d_degree;
  strata  pttype2;
  cluster  MCSID sptn00;
  weight  aovwt2;
  VAR  parity Married poverty d_OtherUK d_nonwhite d_female d_degree ADDAGB00 ADGEST00;
  output out=imputed_dat;
run;

proc mi data=imputed_dat nimpute=0;
  	ods select misspattern;run;
proc means data=imputed_dat nmiss;run;

* Keep only rows that have values for all vars in the models so obs aren't dropped and all models are run on the same set of obs;
  data model_dat_vars;
  set imputed_dat (keep=MCSID ACNUM00 waz_change pregnancy_smoke_grp current_smoke_grp feed_type_3mos  parity Married poverty d_OtherUK d_nonwhite d_female d_degree ADDAGB00 ADGEST00 pttype2 MCSID sptn00 aovwt2);run;

  data model_dat_nomiss;
  set model_dat_vars; 
  	if cmiss(of _all_) then delete;
run;

* Run model on imputed data. ;
  title2 "Updated modles";
  title "*------------* Main Effects Only *-----------------*"; 
	PROC SURVEYREG data=model_dat_nomiss ;	
	class pregnancy_smoke_grp(ref=last) current_smoke_grp(ref=last) feed_type_3mos(ref=last) parity(ref=first) Married(ref=first)
		  poverty(ref=first) d_OtherUK(ref=first) d_nonwhite(ref=first) d_female(ref=first) d_degree(ref=first) ;
	model waz_change= pregnancy_smoke_grp current_smoke_grp feed_type_3mos  parity Married poverty d_OtherUK d_nonwhite d_female d_degree ADDAGB00 ADGEST00 /solution;
	strata  pttype2;
	cluster  MCSID sptn00;
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;

  title "*----------* Interaction terms - no covariates; no main effect  *----------* ";
	PROC SURVEYREG data=model_dat_nomiss ;	
	class  current_smoke_grp (ref=last)
		  feed_type_3mos  (ref=last) ;
	model waz_change= 
  		  current_smoke_grp*feed_type_3mos /solution;
	strata  pttype2;
	cluster  MCSID sptn00; 
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;

  title "*----------* Interaction terms - add covariates, no main effect *----------* ";
	PROC SURVEYREG data=model_dat_nomiss;	
	class current_smoke_grp (ref=last)
		  feed_type_3mos  (ref=last)
		  pregnancy_smoke_grp (ref=last)
		  parity(ref=first)
		  Married(ref=first)
		  poverty(ref=first)
		  d_OtherUK(ref=first)
          d_nonwhite(ref=first)
	      d_female(ref=first)
		  d_degree(ref=first) ;		  
	model waz_change= 
		  pregnancy_smoke_grp parity Married poverty d_OtherUK d_nonwhite d_female d_degree ADDAGB00 ADGEST00 
  		  current_smoke_grp*feed_type_3mos /solution;
	strata  pttype2;
	cluster  MCSID sptn00; 
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;

* Girls v. boys;
  proc sort data=model_dat_nomiss; by d_female;
  title "*------------* By sex *----------------*";
	PROC SURVEYREG data=model_dat_nomiss ;	
	by d_female;
	class current_smoke_grp (ref=last)
		  feed_type_3mos  (ref=last)
		  pregnancy_smoke_grp (ref=last)
		  parity(ref=first)
		  Married(ref=first)
		  poverty(ref=first)
		  d_OtherUK(ref=first)
          d_nonwhite(ref=first)
		  d_degree(ref=first) ;		  
	model waz_change= 
		  pregnancy_smoke_grp parity Married poverty d_OtherUK d_nonwhite d_degree ADDAGB00 ADGEST00 
  		  current_smoke_grp*feed_type_3mos /solution;
	strata  pttype2;
	cluster  MCSID sptn00; 
	weight  aovwt2;
	ods output ParameterEstimates=a_parm_est;
run;
title "";
run;





*--------------------------------------------------------------------------------------------------------*;

*--------------;
* Output tables;
*--------------;

* Merge model_dat_nomiss with other vars. Note: had to eliminate other vars previously in order for cmiss to work properly on model vars only.
  Keep only the row identifiers and get variables from the other data set because model_dat_nomiss contains imputed values which can't go into table 1.;
  data model_dat_nomiss_ids;
  set model_dat_nomiss (keep=MCSID ACNUM00);

  proc sort data=model_dat_nomiss_ids; by MCSID ACNUM00;
  proc sort data=dat1; by MCSID ACNUM00;
  run;
  data table1_dat ina inb;
  merge model_dat_nomiss_ids (in=a)  dat1 (in=b);
  by MCSID ACNUM00;
  if a then output table1_dat;
  if a and not b then output ina;
  if b and not a then output inb;
run;

* Table 1; * Note: put this in a %include file once it works;
  proc contents position data=table1_dat; run;

 * Find vars for dummies
	waz_change 
	waz_birth 
	pregnancy_smoke_grp 
	current_smoke_grp 
	feed_type_3mos 
	ADDAGB00 
	ADGEST00 
	parity 
	poverty 
	Married 
	d_nonwhite 
	d_female 
	d_otherUK 
	d_degree;

  *-------------------------*;
  *----- Continuous  *------*;
  *-------------------------*;
  data t1_cont;
  set table1_dat (keep=pregnancy_smoke_grp waz_change waz_recent waz_birth ADDAGB00 ADGEST00);

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
