/*
* Import parent interview from mc1;
  proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-tab First Survey\tab\mcs1_parent_interview.tab"
  out = test
  dbms=dlm
  replace;
  delimiter='09'x;
  datarow=2;
run;
proc contents data=test;run;
  * 31734 observations and 664 variables;
*/

* Import data from Andrew (former grad student) to see what variables were used;
  proc import
  file = "J:\UK Project\Data and info from previous use\AB.Millennium\UKDA-4683-spss\spss\spss19\mcs1_parent_interview.sav"
  out = olddat
  dbms=spss;
  run;
proc contents data=olddat; run;
  * 18552 observations and 1734 variables. - different than tab file;

* Import SPSS version of data available on the website;
  proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_interview.sav"
  out = spss_dat
  dbms=spss;
  * 31734 observations and 664 variables - matches the tab file;

* proc contents data=spss_dat;
* proc print data=spss_dat (obs=5);
  * better to use this than tab data because it imports the labels and formats;
  * use format _ALL_  to see values instead of formats.;
 * run;

* Keep needed variables;
  data parent_interview;
  set spss_dat (keep=MCSID APNUM00 AELIG00 ARESP00 ACBAGE00 APFCIN00 APBETI00 APILPR00 APILWM0A APILWM0B APILWM0C
					 APILWM0D APILWM0E APILWM0F APILWM0G APCUPR00 APPRMT00 APLOSA00 APDEAN00 APTRDE00 APHEIG00 APHEIF00
					 APHEII00 APHECM00 APWTBF00 APWBST00 APWBLB00 APWBKG00 APWEIG00 APWEIS00 APWEIP00 APWEIK00 APWEES00 APSMUS0A
                     APSMUS0B APSMUS0C APSMUS0D APSMMA00 APPIOF00 APSMTY00 APSMEV00 APCIPR00 APSMCH00 APWHCH00 APCICH00 APSMKR00
					 APNETA00 APNETP00 APTAXC0A APTAXC0B APTAXC0C APGROA00 APGROP00 APSEPA00 APLFTE00 APACQU00 );
  RUN;

* Check for missings;
  proc means data=parent_interview n nmiss;
  var _numeric_;

  data miss1;
  set parent_interview;
  	miss_n = cmiss(of MCSID -- APACQU00);
run;

proc freq data=miss1;
	tables miss_n;
run;

/*
* Investigate smoking variables and why there are four of them - appear to be subsequent forms of smoking if more than one type;
* See questionaire for info on skip patterns: https://cls.ucl.ac.uk/wp-content/uploads/2017/07/MCS1_CAPI_Questionnaire_Documentation_March_2006_v1.1.pdf;
	proc freq data=parent_interview;
	tables APSMUS0A APSMUS0B APSMUS0C APSMUS0D;
	title "Frequencies of Smoking Variables" ;
	run;

	proc freq data=parent_interview;
	where APSMUS0A = 1;
	tables APSMUS0B APSMUS0C APSMUS0D;
	title 'Check frequencies of smoking variables 2-4 when the first one indicates the respondant doesnt smoke' ;
	run;
	
	proc print data=parent_interview;
	where APSMUS0D NOT IN (., 1);
	var APSMUS0A APSMUS0B APSMUS0C APSMUS0D;
	title 'Values of all smoke variables where the fourth one is not missing' ;
	run;
	
	proc print data=parent_interview;
	where APSMUS0C NOT IN (., 1);
	var APSMUS0A APSMUS0B APSMUS0C APSMUS0D;
	title 'Values of all smoke variables where the third one is not missing' ;
	run;

    proc freq data=parent_interview;
	tables APSMTY00 * APSMUS0A /missing;
	title "Current smoking V. smoked in last two years";
	* 2,219 does not currently smoke but yes to smoke in last 2 yrs | 19,010 to does not currently smoke and hadn't in last two years;
	* All missings on "smoked in last 2 years" have valid answers for current smoking (10,505);
	run;
*/
* Get smoking during pregnancy - these vars non-missing only if current smoke or smoke in last two years;
	* APCIPR00 - Number cig per day before preg;
	* APSMCH00 - Changed number during pregnancy;
	* APWHCH00 - Which month changed smoking habits;
	* APCICH00 - Number smoked per day after change;

* Write to file;
ods html file="J:\UK Project\Exploratory results\smoking check.html";

	 proc freq data=parent_interview;
	 where APSMUS0A in (2,3) OR APSMUS0B in (2,3) OR APSMUS0C in (2,3) OR APSMUS0D in (2,3) OR APSMTY00=1;
	 tables APCIPR00 APSMCH00;
	 title "Of those that currently smoked or have smoked regularly during past two years";

	 proc freq data=parent_interview;
	 where (APSMUS0A in (2,3) OR APSMUS0B in (2,3) OR APSMUS0C in (2,3) OR APSMUS0D in (2,3) OR APSMTY00=1) AND APSMCH00=1;
	 tables APWHCH00 APCICH00;
	 title "Of those that currently smoked or have smoked regularly during past two years and who changed habits during pregnancy";
	 * 85% changed during first trimester;
	run;

ods html close;
run;




* Check other files;
 proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_cm_derived.sav"
  out = cm_derived
  dbms=spss;
  proc contents data=cm_derived;
  run;

  proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_cm_interview.sav"
  out = cm_interview
  dbms=spss;
  proc contents data=cm_interview;
  run;

* Figure out how to merge;
  proc print data=parent_interview (obs=10);
  var MCSID -- ARESP00;
  run;

  * Get derived data to identify mothers;
	proc import
	file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_derived.sav"
	out = parent_derived
	dbms=spss;
	run;

 * Merge parent_interview and parent_derived;
   proc sort data=parent_interview; by MCSID APNUM00;run;
   proc sort data=parent_derived; by MCSID APNUM00;run;

   data parent_info ina inb;
   merge parent_interview(in=a) parent_derived(in=b);
   by MCSID APNUM00;
   if a and b then output parent_info;
   if a and not b then output ina;  *none;
   if b and not a then output inb;  *2,150 obs - most of these were fathers not interviewd;

   * Check elig, participation of those not in interview file;
	  proc freq data=inb;
	     tables AELIG00 ARESP00 ADDRES00;	   
	   run;

   * Identify mothers;
     data mothers;
	 set parent_info;
	 	where ADDRES00 = 1;

		run;
	 
	   
