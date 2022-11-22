
*********************************************************************************************************;
* Will need to come back to this when models are decided to run descriptives for the vars selected;
* Code below was first pass based on initial set of vars. Can be refactored/adapted for final set
*************************************************************************************************************;

*-----* Create anayltic sample for Table 1 *----;
* For table 1, need to also drop obs with any missings;
  data table1_dat;  *16728 obs*;
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
