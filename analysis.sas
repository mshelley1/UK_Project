*
* Run analyses on data set created in "data prep.sas"
*;

libname analysis "L:\UK Project\Analysis Data\Data sets";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

PROC CONTENTS DATA=ANALYSIS.ANALYSIS_DAT_2;RUN;

data dat1;
set analysis.analysis_dat_2; 

	/* Keep vars needed for revised Table 1 */
	   keep APLOIL00 ADDAGB00 NOCMHH ADD06E00 COUNTRY Married education hh_income ACADMO00 APTRDE00 see_friends see_parents ADGEST00 waz_birth waz_recent
			pregnancy_smoke AHCSEX00 AOVWT2 ADBWGT00 APDEAN00 APTRDE00 treat_now_depression ACNOBA00 Breast_Milk_Time--Age_First_Solid; * BMI of mother vars hadd too many missing (>1000)

	* Drop obs with outlier Z scores and mothers 15 or younger and non-singletons;
	   where abs(waz_recent) < 7  /* leaves 18,773 */ and
	   		 abs(waz_birth) < 7   /* leaves 18,767 */ and
			 ADDAGB00 >= 16		  /* leaves 18,663 */ and
			 ACNOBA00 ne 1 ;
			 ;
run;
 
data dat2;
set dat1;

  * Group pregnancy_smoke;
	pregnancy_smoke_grp=.;
	If pregnancy_smoke = 0 then pregnancy_smoke_grp=1;
	Else if 0 < pregnancy_smoke <= 10 then pregnancy_smoke_grp=2;
	Else if 10 < pregnancy_smoke then pregnancy_smoke_grp=3;

  *Indicators for table 1;
	white=.; mixed=.; indian=.; pakistani_bangladeshi=.; black_blackbrit=.; other=.;
	If ADD06E00=1 then white=1; 
	else If ADD06E00=2 then mixed=1; 
	else If ADD06E00=3 then indian=1; 
	else If ADD06E00=4 then pakistani_bangladeshi=1; 
	else If ADD06E00=5 then black_blackbrit=1; 
	else If ADD06E00=6 then other=1; 

	england=.; wales=.; scotland=.; northIreland=.;
	If COUNTRY=1 then england=1;
	else if COUNTRY=2 then wales=1;
	else if COUNTRY=3 then scotland=1;
	else if COUNTRY=4 then northIreland=1;

	nvq_1_to_3=.; nvq_4_to_5=.; nvq_none_or_abroad=.;
	If EDUCATION=1 then nvq_1_to_3=1;
	If EDUCATION=2 then nvq_4_to_5=1;
	If EDUCATION=9 then nvq_none_or_abroad=1;

	health_probs=.;
	*If ACADMO00 > 0 then health_probs=1;
	If APLOIL00 > 0 then health_probs=1;

	treat_mental=.; 
	If APTRDE00=1 then treat_mental=1; Else if APTRDE00 ne . then treat_mental=0;

	If see_parents=2 then see_parents=0; 
	If see_friends=2 then see_friends=0;

	male=.;
	If AHCSEX00=1 then male=1;

	retain pregnancy_smoke ADDAGB00 white--other england--northIreland married nvq_1_to_3--nvq_none_or_abroad hh_income  health_probs treat_now_depression see_parents see_friends male  ADGEST00;

	proc contents position;run;

  * Get distributions overall ;
	proc univariate data=dat2 outtable=table noprint;
	proc print data=table;
	var _VAR_ _NOBS_  _NMISS_ _MEAN_ _STD_ _MIN_ _MAX_;
	title"";
RUN;


* Create Table 1;
  proc sort data=dat2;
  by pregnancy_smoke_grp;

  proc univariate data=dat2 outtable=table1 noprint;
  by pregnancy_smoke_grp;
  proc print data=table1;
  var _VAR_ pregnancy_smoke_grp _NOBS_ _MEAN_ _STD_;
  run;

  proc freq data=dat2;
  tables pregnancy_smoke_grp*Married /missing;
  run;








	proc sort data=dat2; by pregnancy_smoke_grp;

	proc contents data=dat2 position; *use this to get variable lables for spreadsheet;
run;

  * Get distributions overall and by pregnacny_smoke_grp;
	proc univariate data=dat2 outtable=table noprint;
	proc print data=table;
	var _VAR_ _NOBS_ _NMISS_ _MEAN_ _STD_ _MIN_ _MAX_;
RUN;

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
