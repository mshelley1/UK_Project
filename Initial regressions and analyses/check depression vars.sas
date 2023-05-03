* Import parent interview data - 31,734 obs, 664 variables;
  proc import
  file = "L:\UK Project\Data Downloads\UKDA-4683-spss First Survey\UKDA-4683-spss\spss\spss25\mcs1_parent_interview.sav"
  out = parent_interview
  dbms=spss;
  run;
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

	* Depression vars;
		DESYMP1=.; DESYMP2=.; DESYMP3=.; DESYMP4=.; DESYMP5=.; TOTDESYMP=.;
		If APDIFC0A in (61) then DESYMP1=1; Else if APDIFC0A ne . then DESYMP1=0;
		If APLOSA00=1 then DESYMP2=1; Else if APLOSA00 ne . then DESYMP2=0;
		If APDEPR00=1 then DESYMP3=1; Else if APDEPR00 ne . then DESYMP3=0;
		If APPESH00=1 then DESYMP4=1; Else if APPESH00 ne . then DESYMP4=0;
		If APRULI00=2 then DESYMP5=1; Else if APRULI00 ne . then DESYMP5=0;
		TOTDESYMP=sum(DESYMP1--DESYMP5);

	* Anxiety vars;
		ANXSYMP1=.; ANXSYMP2=.; ANXSYMP3=.; ANXSYMP4=.; ANXSYMP5=.; TOTANXSYMP=.;
		If APWORR00=1 then ANXSYMP1=1; else if APWORR00 ne . THEN ANXSYMP1=0;
		If APSCAR00=1 then ANXSYMP2=1; else if APSCAR00 ne . THEN ANXSYMP2=0;
		If APUPSE00=1 then ANXSYMP3=1; else if APUPSE00 ne . THEN ANXSYMP3=0;
		If APKEYD00=1 then ANXSYMP4=1; else if APKEYD00 ne . THEN ANXSYMP4=0;
		If APHERA00=1 then ANXSYMP5=1; elsE if APHERA00 ne . THEN ANXSYMP5=0;
		TOTANXSYMP=sum(ANXSYMP1--ANXSYMP5);
	
	* Stress vars;
		STRSYMP1=.; STRSYMP2=.; STRSYMP3=.; TOTSTRSYMP=.;
		If APTIRE00=1 then STRSYMP1=1; else if APTIRE00 ne . THEN STRSYMP1=0;
		If APRAGE00=1 then STRSYMP2=1; else if APRAGE00 ne . THEN STRSYMP2=0;
		If APNERV00=1 then STRSYMP3=1; else if APNERV00 ne . THEN STRSYMP3=0;
		TOTSTRSYMP=sum(STRSYMP1--STRSYMP3);
	RUN;

	* Check freqs for mom's depression and anxiety var;
	  proc freq;
*	  tables APILPR00 APILWM0A APDIFC0A APLOSA00 APDEAN00 APTRDE00 APDEPR00 APPESH00
			 APTIRE00 APRAGE00 APNERV00 APWORR00 APSCAR00 APUPSE00 APKEYD00 APHERA00
			 APRULI00 APWALI00;
*	  tables APDIFC0A APLOSA00 APDEPR00 APPESH00 APRULI00 DESYMP1--TOTDESYMP;
	  tables ANXSYMP1--TOTANXSYMP;
	  tables STRSYMP1--TOTSTRSYMP;

run;


*PROC FACTOR data=moms (keep=DESYMP1--DESYMP5 ANXSYMP1--ANXSYMP5 STRSYMP1--STRSYMP3) simple corr;
PROC FACTOR data=moms (keep=DESYMP1--DESYMP5 ANXSYMP2--ANXSYMP5 STRSYMP2--STRSYMP3) simple corr;
run;

proc corr data=moms (keep=DESYMP1--DESYMP5 ANXSYMP2--ANXSYMP5 STRSYMP2--STRSYMP3) alpha nomiss; run;



PROC PRINT; WHERE TOTDESYMP=-1; VAR APDIFC0A APLOSA00 APDEPR00 APPESH00 APRULI00 DESYMP1--TOTDESYMP;

run;
