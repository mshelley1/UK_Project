*
* Import data, keep needed vars, and merge.
*  - see 'initial exploration.sas' for checks, etc.
* - import SPSS versions to retain value labels, etc.
*

* Import parent interview data - 31,734 obs, 664 variables;
  proc import
  file = "J:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_interview.sav"
  out = spss_dat
  dbms=spss;
  
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
   if b and not a then output inb;  *2,150 obs - most of these were fathers not interviewd

   * Check elig, participation of those not in interview file;
	  proc freq data=inb; tables AELIG00 ARESP00 ADDRES00;	   
run;

* Identify mothers;
  data mothers;
  set parent_info;
	 	where ADDRES00 = 1; * Mothers who were interviewed;

		run;

		run;
	 
	   
