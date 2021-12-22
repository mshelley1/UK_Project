*
* Import data, keep needed vars, and merge.
* - see 'initial exploration.sas' for prior checks, etc.
* - import SPSS versions to retain value labels, etc.
* 
* Results in mother_child data sets.
*
;

libname analysis "L:\UK Project\Analysis Data\Data sets";

* Import parent interview data - 31,734 obs, 664 variables;
  proc import
  file = "L:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_interview.sav"
  out = spss_dat
  dbms=spss;
  run;
* Keep needed variables from parent_interview;
  data parent_interview;
  set spss_dat;
RUN;

* Import parent derived data;
  proc import
  file = "L:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_derived.sav"
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
  if a then output mothers; * 18,492 mothers;
  if a and not b then output ina; * 5351 obs;
  if b and not a then output inb; * 41 obs;
  run;

	 
*-----* Child Data *-----*;
* Import cohort member derived data - 18,786 obs;
  proc import
  file = "L:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_cm_derived.sav"
  out = cm_derived
  dbms=spss;
  run;


*----* Parent Interview Data *----*;
* Import parent interview about cohort member - 32,165 obs;
  proc import
  file = "L:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_cm_interview.sav"
  out = parent_cm_interview
  dbms=spss;
run;

proc sort data=parent_cm_interview NODUPKEY; by MCSID ACNUM00;
run;
	* Keep only the main parent response or partner only if main is missing;
	  proc sort data=parent_cm_interview; by MCSID ACNUM00;
      data parent_cm_main;
  	  set parent_cm_interview;
	  	where ARESP00=1;

	  data parent_cm_other;
	  set parent_cm_interview;
	  	where ARESP00=2;

	  data parent_cm_out ina inb;
	  merge parent_cm_other (in=b) parent_cm_main (in=a) ; *must be in this order to keep main parent response when child has both parents respond;
	  by MCSID ACNUM00;
	  if a or (b and not a) then output parent_cm_out;
	  if a and not b then output ina; 
	  if b and not a then output inb;
run;

* Merge data that are at the cohort member level;
  proc sort data=cm_derived; by MCSID ACNUM00;  
  proc sort data=parent_cm_out; by MCSID ACNUM00;

  data child_info ina inb;
  merge cm_derived(in=a) parent_cm_out(in=b);
  by MCSID ACNUM00;
  output child_info;
  if a and not b then output ina; 	   * 0 obs;
  if b and not a then output inb; 	   * 0 obs;
  run;


*-----* hhgrid *------*;
* Need for CM sex, dob;
	proc import
	file="L:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_hhgrid.sav"
	out=hhgrid
	dbms=spss;
run;

	* Get natural mothers and how many kids they have;
	  data hhgrid_moms;
	  set hhgrid;
		where AHPSEX00=2 and AHCREL00=7; * person sex is female and rel to CM is natural parent;

		num_mom_kids_at_home=1; * We know they are parent to at least the cohor member;
		array ahrel AHPRELA0--AHPRELK0; * Relationship to all others in household;

		do i=1 to dim(ahrel);
			if ahrel[i] = 7 then num_mom_kids_at_home=num_mom_kids_at_home+1; *If natural parent to anyone else, add one to kid count;
		end;

		keep MCSID  num_mom_kids_at_home;

		proc sort data=hhgrid_moms; by MCSID;
/*		PROC FREQ; TABLES  num_mom_kids_at_home;RUN; */
run;

    data hhgrid_cm;
	set hhgrid (keep=MCSID ACNUM00 AHINTM00--AHCAGE00);
		where MCSID ne "" and ACNUM00 ne .; *Keep only cohort members;

	proc sort data=hhgrid_cm;
		by MCSID ACNUM00;

	* Mrege hhgrid CMs with moms;
		data hhgrid_tmp ina inb;
		merge hhgrid_cm (in=a) hhgrid_moms(in=b);
		by MCSID;
		if a and not b then output ina;
		if b and not a then output inb;
		output hhgrid_tmp;
		run;

run;

* Merge with other child info;
  data outchild ina inb;
  merge child_info(in=a) hhgrid_tmp(in=b);
  by MCSID ACNUM00;
  output outchild;
  if a and not b then output ina; * 0 obs;
  if b and not a then output inb; * 0 obs;
  run;


* Merge child data with parent info;  
  data outdat ina inb;
  merge mothers(in=a) outchild(in=b);
  by MCSID;
  output outdat; 				  * 18,786 obs;
  if a and not b then output ina; * 0 obs;
  if b and not a then output inb; * 48 obs, so 18,738 that match mother/child;
  run;

proc contents data=outdat position; run;

*-----* Longitudinal family file *---------*;
* Need this for weights;
  proc import
  file="L:\UK Project\Data Downloads\UKDA-8172-spss\spss\spss25\mcs_longitudinal_family_file.sav"
  out=long_fam
  dbms=spss;
run;
   proc sort; by MCSID; 

* Merge;
   data outwt ina inb;
   merge outdat(in=a) long_fam(in=b);
   by MCSID;
   if a and b then output outwt;
   if a and not b then output ina; * 0 obs;
   if b and not a then output inb; * 703 obs;
  run;

  proc freq data=outwt; tables num_mom_kids_at_home;run;

*---* Save output data set *---*;
  data analysis.mother_child_3; *Note original data set did not have hhgrid or long_fam attached. Additionall only kept records in both mother and baby originally;
  set outwt;
  run;



 * Save formats from imported data so they can be applied to analysis data set;
   proc format library=analysis.formats;
   options fmtsearch=(analysis.formats work);
   run;
