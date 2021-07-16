*
* Create derived smoking and feeding variables;
* Note: had to save format catalog from WORK that was generated by import.sas and copy it over to a new catalog in ANALYSIS; 

libname analysis "J:\UK Project\Analysis Data\Data sets";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

data mother_child;
set analysis.mother_child;

* Classify mothers' prenatal smoking
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

	pregnancy_smoke=.;
	If APSMUS0A=. and APSMTY00=. and APSMCH00=. and APCIPR00=. and APCICH00=. then smoking_miss = 1; 

	* Not current smoker and not smoke in last two years;
	  If APSMUS0A=1 and APSMTY00=2 then pregnancy_smoke = 0; 
	* Current smoker or smoked in last two years;
	  If (APSMUS0A=1 and APSMTY00=1) OR (APSMUS0A ne 1) then do;
	   	If APSMCH00=2 then pregnancy_smoke=APCIPR00; * No change in smoke during pregnancy -> use amount before pregnancy;
		If APSMCH00=1 and APCICH00 in(0,96,97) then pregnancy_smoke=APCIPR00; * Changed: quit, < 1/day, can't recall -> use amount before pregnancy;
		Else If APSMCH00=1 then pregnancy_smoke=max(of APCIPR00 APCICH00); * Changed: used max of [before pregnancy, # after change];
	  end;

/*	 proc freq; tables pregnancy_smoke*APCIPR00 /norow nocol nopercent missing;run;
	 proc print; var APSMUS0A APSMTY00 APSMCH00 APCIPR00 APCICH00; where pregnancy_smoke=. and  smoking_miss ne 1;run;
*/

* Classify feeding type;
* Feeding variables:
	  * ACBFEV00 - Ever tried to breastfeed (1=yes, 2=no);
	  * ACBFEA00 - Age when CM last had breast milk (1=never, 2=<1day, 3=ans in days, 4=ans in wks, 5=ans in mos, 6=still bf);
	  * ACBFED00 - Age in days when CM last had breast milk;
	  * ACBFEW00 - Age in weeks when CM last had breast milk;
	  * ACBFEM00 - Age in mos when CM last had breast milk;
	  * ACAGDM00 - Age first had formula (1=not had, 2=<1 day, 3=ans in days, 4=ans in wks, 5=ans in mos);
	  * ACDMDA00 - Age in days first had formula ;
	  * ACDMWK00 - Age in weeks first had formula;
	  * ACDMMT00 - Age in months first had formula;
	  * ACAGCM00 - Age first had cows milk (1=not had, 2=ans in days, 3=ans in wks, 4=ans in mos);
	  * ACCMDA00 - Age first had cosw milk (in days?);
	  * ACCMWK00 - Age first had cows milk (in wks?);
	  * ACCMMT00 - Age first had cows milk (in moss?);
	  * ACAGOM00 - Age first had other milk (1=not had, 2=ans in days, 3=ans in wks, 4=ans in mos);
	  * ACOMDA00 - Age first had other milk (in days?);
	  * ACOMWK00 - Age first had other milk (in wks?);
	  * ACOMMT00 - Age first had other milk (in mos?);
	  * ACAGSF00 - Age first had solid food (1=not had, 2=ans in days, 3=ans in wks, 4=ans in mos);
	  * ACSFDA00 - Age first had solid food (in days?);
	  * ACSFWK00 - Age first had solid food (in wks?);
	  * ACSFMT00 - Age first had solid food (in mos?);

	* Determine length of breastfeeding in days;
	  If ACBFEV00=2 OR ACBFEA00=1 then Any_Breast_Milk=0;
	  Else if ACBFEV00=1 and ACBFEA00 >=2 then Any_Breast_Milk=1;

	  If Any_Breast_Milk=1 then do;
		If ACBFEA00=2 then Breast_Milk_Time=0.5;
		Else if ACBFEA00=3 then Breast_Milk_Time=ACBFED00;
		Else if ACBFEA00=4 then Breast_Milk_Time=ACBFEW00*7;
		Else if ACBFEA00=5 then Breast_Milk_Time=ACBFEM00*30;
		Else if ACBFEA00=6 then Breast_Milk_Time=999;   * Replace with child's age in days;
      end;
	  Else if Any_Breast_Milk=0 then Breast_Milk_Time=0;

	* Get age at which first had something other than breast milk. Collapse different time scales of each food type into days;
	  If ACAGDM00=2 then Age_First_Formula=0;  * For formula only: 2=less than one day-> age at first formula=0;
 	  Else if ACAGDM00=3 then Age_First_Formula=ACDMDA00;    *Answer in days->age=days;
	  Else if ACAGDM00=4 then Age_First_Formula=ACDMWK00*7;  *Answer in weeks->age=wks*7;
	  Else if ACAGDM00=5 then Age_First_Formula=ACDMMT00*30; *Answer in months->age=months*30;
	  Else if ACAGDM00=1 then Age_First_Formula=-1;

	  If ACAGCM00=2 then Age_First_CowMilk=ACCMDA00;		* Answer in days->age=days;
	  Else if ACAGCM00=3 then Age_First_CowMilk=ACCMWK00*7; * Answer in days->age=weeks;
	  Else if ACAGCM00=4 then Age_First_CowMilk=ACCMMT00*30; * Answer in days->age=months;
	  Else if ACAGCM00=1 then Age_First_CowMilk=-1;

 	  If ACAGOM00=2 then Age_First_OthMilk=ACOMDA00;
	  Else if ACAGOM00=3 then Age_First_OthMilk=ACOMWK00*7;
	  Else if ACAGCM00=4 then Age_First_OthMilk=ACOMMT00*30;  *Large missing for ACOMMT00 where ACAGCM00=4 (8985/9078);
	  Else if ACAGCM00=1 then Age_First_OthMilk=-1;

	  If ACAGSF00=2 then Age_First_Solid=ACSFDA00;
	  Else if ACAGSF00=3 then Age_First_Solid=ACSFWK00*7;
	  Else if ACAGSF00=4 then Age_First_Solid=ACSFMT00*30;
	  Else if ACAGSF00=1 then Age_First_Solid=-1;

	proc univariate;
	 * var Breast_Milk_Time--Age_First_Solid;
	  var ACBAGE00;
	  histogram; 
	  run;

* Other vars needed
	 * APBIWT00 - Birth weight (unit)
	 * APWTKG00, LB, OU
	 * ADBWGT00 - Derived CM birthweight in kilos;
	 * APPRLM0A...E - Complications during labor;

data analysis_dat;
set mother_child;
   keep
	MCSID CNUM
	/* Parent interview vars */
		APNUM00 AELIG00 ARESP00
		ACBAGE00 
		APFCIN00 APBETI00/**/ APILPR00--APILWM0G APCUPR00 APPRMT00
		APLOSA00--APWEES00 
		APNETA00--APSEPA00
		APLFTE00--APVCQU00 
		smoking_miss pregnancy_smoke /* Created */	
	/* Parent derived vars */
		ADDAGI00


