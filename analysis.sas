*
* Run analyses on data set created in "data prep.sas"
*;

libname analysis "K:\UK Project\Analysis Data\Data sets";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

data dat1;
set analysis.analysis_dat_2 (keep=waz_recent wapct_recent APCUPR00--ADDAGI00 ADDACT00 ADDWRK00 ADDBMI00 ACNUM00-- ADERLT00 ADGEST00 ADAGLW00--APALIM00 AHCSEX00 pregnancy_smoke--wapct_birth
									ADD06E00 education ADWKST00 hh_income see_parents see_friends BMI_Range APLOIL00 AOVWT2 Country);
run;

* Pregnancy_smoke will be the "by" variable, so check its distribution first...0:65%, 1-10:18.23%, >10:16.67% ;
  proc freq;
  tables pregnancy_smoke;
  run;

data dat2;
set dat1;
  * Group pregnancy_smoke;
	If pregnancy_smoke = 0 then pregnancy_smoke_grp=1;
	Else if 0 < pregnancy_smoke <= 10 then pregnancy_smoke_grp=2;
	Else if 10 < pregnancy_smoke then pregnancy_smoke_grp=3;

	proc sort data=dat2; by pregnancy_smoke_grp;

	proc contents data=dat2 position; *use this to get variable lables for spreadsheet;
run;

  * Get distributions overall and by pregnacny_smoke_grp;
	proc univariate data=dat2 outtable=table noprint;
	proc print data=table;
	var _VAR_ _NOBS_ _NMISS_ _MEAN_ _STD_ _MIN_ _MAX_;

    proc univariate data=dat2 outtable=table_grp noprint;
	by pregnancy_smoke_grp;	
    proc print data=table_grp;
	var pregnancy_smoke_grp _VAR_ _NOBS_ _NMISS_ _MEAN_ _STD_ _MIN_ _MAX_;

run; 

* Need to remove obs with missings on pregnancy_smoke, Z-score values -- about 900 obs;
  data no_miss;
  set dat2;
  	where pregnancy_smoke ne . and waz_recent ne . and waz_birth ne .;
run;

	* Rerun distributions;
  	  proc univariate data=no_miss outtable=table noprint;
	  proc print data=table;
	  var _VAR_ _NOBS_ _NMISS_ _MEAN_ _STD_ _MIN_ _MAX_;
run;

/* Check variables with big outliers */
   proc univariate data=no_miss;
   	var waz_recent ADDBMI00 pregnancy_smoke;
	run;






/*
  * Create four data sets, one each for the levels of pregnancy_smoke_grp, then merge and print;
	data grp_miss;
	set table; where pregnancy_smoke_grp=.;
		rename _NOBproc sort; by _VAR_;

	data grp_1;
	set table; where pregnancy_smoke_grp=1; proc sort; by _VAR_;
	data grp_2;
	set table; where pregnancy_smoke_grp=2; proc sort; by _VAR_;
	data grp_3;
	set table; where pregnancy_smoke_grp=3; proc sort; by _VAR_;

	data table_out;
	merge grp_miss grp_1 grp_2 grp_3;
	by _VAR_;
*/
