*
* Import data, keep needed vars, and merge.
* - see 'initial exploration.sas' for prior checks, etc.
* - import SPSS versions to retain value labels, etc.
* 
* Results in mother_child data sets.
*
;

libname analysis "J:\UK Project\Analysis Data\Data sets";

* Import parent interview data - 31,734 obs, 664 variables;
  proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_interview.sav"
  out = spss_dat
  dbms=spss;
  run;
* Keep needed variables from parent_interview;
  data parent_interview;
  set spss_dat (keep=MCSID APNUM00 AELIG00 ARESP00 ACBAGE00 APFCIN00 APBETI00 APILPR00 APILWM0A APILWM0B APILWM0C
					 APILWM0D APILWM0E APILWM0F APILWM0G APCUPR00 APPRMT00 APLOSA00 APDEAN00 APTRDE00 APHEIG00 APHEIF00
					 APHEII00 APHECM00 APWTBF00 APWBST00 APWBLB00 APWBKG00 APWEIG00 APWEIS00 APWEIP00 APWEIK00 APWEES00 APSMUS0A
                     APSMUS0B APSMUS0C APSMUS0D APSMMA00 APPIOF00 APSMTY00 APSMEV00 APCIPR00 APSMCH00 APWHCH00 APCICH00 APSMKR00
					 APNETA00 APNETP00 APTAXC0A APTAXC0B APTAXC0C APGROA00 APGROP00 APSEPA00 APLFTE00 APACQU00 );

* Import parent derived data;
  proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_derived.sav"
  out = parent_derived
  dbms=spss; 

 * Merge parent_interview and parent_derived;
   proc sort data=parent_interview; by MCSID APNUM00; run;
   proc sort data=parent_derived; by MCSID APNUM00; run;

   data parent_info ina inb;
   merge parent_interview(in=a) parent_derived(in=b);
   by MCSID APNUM00;
   if a and b then output parent_info;
   if a and not b then output ina;  *none;
   if b and not a then output inb;  *2,150 obs - most of these were fathers not interviewd;
run;

* Keep only mothers; 
  data moms;
  set parent_info;
	where ADDRES00 = 1; *18492 mothers;
run;

* Merge father's smoking;
  data fathers;
  set parent_info (keep=MCSID ADDRES00 APSMUS0A);
	where ADDRES00 = 2; 
	rename
		APSMUS0A = APSMUS0A_FATHER;
	drop ADDRES00;
run;

* Check elig, participation of those not in interview file;
	   /*  proc freq data=inb; tables AELIG00 ARESP00 ADDRES00;*/	   

* Check who was interviewed - 99.81% were mothers or fathers;
	/* proc freq data=parent_info; tables ADDRES00 APSMKR00;run; */

* Smoking var info:
	 * APSMUS0A	- First type of tobacco product, current smoking;
	 * thru APMUS0D (fourth type of current smoking);
	 * APSMMA00 - How many cigarettes per day;
	 * APSMTY00 - Smoked in last 2 years;
	 * APSMEV00 - Ever regularly smoked tobacco;
	 * APCIPR00 - Number cig per day before preg;
	 * APSMCH00 - Changed number during pregnancy;
	 * APWHCH00 - Which month changed smoking habits;
	 * APCICH00 - Number smoked per day after change;
	 * APSMKR00 - Anyone smokes in same room as CM;

/*
* Identify mothers and rename smoking vars;
  data mothers;
  set parent_info;
	where ADDRES00 = 1;
	rename
	    APSMUS0A = APSMUS0A_MOTHER 
		APSMMA00 = APSMMA00_MOTHER
		APSMTY00 = APSMTY00_MOTHER
		APSMEV00 = APSMEV00_MOTHER
		APCIPR00 = APCIPR00_MOTHER
		APSMCH00 = APSMCH00_MOTHER
		APWHCH00 = APWHCH00_MOTHER
		APCICH00 = APCICH00_MOTHER
		APSMKR00 = APSMKR00_MOTHER;
run;
	proc freq;
	tables APSMUS0A_MOTHER -- APSMKR00_MOTHER;run; 

* Identify fathers and get smoking vars;
  data fathers;
  set parent_info (keep=MCSID ADDRES00 APSMUS0A -- APSMKR00);
	where ADDRES00 = 2; 
	rename
		APSMUS0A = APSMUS0A_FATHER 
		APSMMA00 = APSMMA00_FATHER
		APSMTY00 = APSMTY00_FATHER
		APSMEV00 = APSMEV00_FATHER
		APCIPR00 = APCIPR00_FATHER
		APSMCH00 = APSMCH00_FATHER
		APWHCH00 = APWHCH00_FATHER
		APCICH00 = APCICH00_FATHER
		APSMKR00 = APSMKR00_FATHER;
run;
	proc freq;
		tables APSMUS0A_FATHER -- APSMKR00_FATHER;run; * APSMUS0A_FATHER is the only without a lot of missing;

* Merge fathers and mothers;
  data parent_combined ina inb;
  merge mothers (in=a) fathers (in=b);
  by MCSID;
  output parent_combined;
  If a and not b then output ina;
  If b and not a then output inb;
  run;
*/

* Merge father smoking info;
  data mothers ina inb;
  merge moms(in=a) fathers(in=b);
  by MCSID;
  if a then output mothers;
  if a and not b then output ina; * 5351 obs;
  if b and not a then output inb; * 41 obs;
  run;

	 
*-----* Child Data *-----*;
* Import cohort member derived data - 18,786 obs;
  proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_cm_derived.sav"
  out = cm_derived
  dbms=spss;
  run;

* Import parent interview about cohort member - 32,165 obs;
  proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_cm_interview.sav"
  out = parent_cm_interview
  dbms=spss;
run;

* Keep only the main parent response;
  data parent_cm_main;
  set parent_cm_interview;
  	where ARESP00=1;
run;


* Merge data that are at the cohort member level;
  proc sort data=cm_derived; by MCSID ACNUM00;  
  proc sort data=parent_cm_main; by MCSID ACNUM00;

  data child_info ina inb;
  merge cm_derived(in=a) parent_cm_main(in=b);
  by MCSID ACNUM00;
  if a and b then output child_info;   * 18,766 obs; 
  if a and not b then output ina; 	   * 20 obs;
  if b and not a then output inb; 	   * 0 obs;
  run;


* Merge child data with parent info;  
  data outdat ina inb;
  merge mothers(in=a) child_info(in=b);
  by MCSID;
  output outdat; 				  * 18,766 obs;
  if a and not b then output ina; * 0 obs;
  if b and not a then output inb; * 28 obs;
  run;

  data analysis.mother_child;
  set outdat;
  run;

 * Save formats from imported data so they can be applied to analysis data set;
   proc format library=analysis.formats;
   options fmtsearch=(analysis.formats work);
   run;
