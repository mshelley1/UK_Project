*
* Create derived smoking and feeding variables;
* Note: had to save format catalog from WORK that was generated by import.sas and copy it over to a new catalog in ANALYSIS; 
*;

libname analysis "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Analysis Data\Data sets";
libname refdir "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Data Downloads\WHO reference data";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

*
* Create derived smoking and feeding variables;
* Note: had to save format catalog from WORK that was generated by import.sas and copy it over to a new catalog in ANALYSIS; 
*;

libname analysis "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Analysis Data\Data sets";
libname refdir "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Data Downloads\WHO reference data";

proc format library=analysis.formats;
options fmtsearch=(analysis.formats work);

data mother_child;
set analysis.mother_child_3; 
/*--------------*
 * Smoking Vars *
 *--------------*/
* mothers' prenatal smoking
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

  * Group pregnancy_smoke;
	pregnancy_smoke_grp=.;
	If pregnancy_smoke = 0 then pregnancy_smoke_grp=1;
	Else if 0 < pregnancy_smoke <= 10 then pregnancy_smoke_grp=2;
	Else if 10 < pregnancy_smoke then pregnancy_smoke_grp=3;

  * Smoking in three months after birth (Note: variable about when changed is only during 9 mos of pregnancy - current smoke is probably closest);
	* Current smoking: APSMMA00	Variable label = How many cigarettes per day; 
	If APSMUS0A=1 then current_smoke=0;
	Else current_smoke=APSMMA00;

	current_smoke_grp=.;
	If current_smoke = 0 then current_smoke_grp=1;
	Else if 0 < current_smoke <= 10 then current_smoke_grp=2;
	Else if 10 < current_smoke then current_smoke_grp=3;

/*--------------*
 * Feeding Type *
 *--------------*/
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
		If ACBFEV00=2 or ACBFEA00 in (1,2) then Breast_Milk_Time=0;			* never, or less than one day old last breast milk;
		Else if ACBFEA00=3 then Breast_Milk_Time=ACBFED00;					* time given in days (more than one day old);
		Else if ACBFEA00=4 then Breast_Milk_Time=ACBFEW00*7;				* time given in weeks;
		Else if ACBFEA00=5 then Breast_Milk_Time=ACBFEM00*30;				* time given in months;
		Else if ACBFEA00=6 then Breast_Milk_Time=ACBAGE00*30;				* still breastfeeding, use baby's age in months;

	  * Get age at which first had something other than breast milk. Collapse different time scales of each food type into days;
	  * Age first fomulta;
	    If ACAGDM00=2 then Age_First_Formula=0;  * For formula only: 2=less than one day-> age at first formula=0;
 	    Else if ACAGDM00=3 then Age_First_Formula=ACDMDA00;    *Answer in days->age=days;
	    Else if ACAGDM00=4 then Age_First_Formula=ACDMWK00*7;  *Answer in weeks->age=wks*7;
	    Else if ACAGDM00=5 then Age_First_Formula=ACDMMT00*30; *Answer in months->age=months*30;
	    Else if ACAGDM00=1 then Age_First_Formula=-1;

	 * Convert ages to months;
	   If Age_First_Formula=-1 then Age_First_Formula_cat = 99;
	   Else Age_First_Formula_cat = floor(Age_First_Formula/30);

	   If Breast_Milk_Time=0 then Breast_Milk_Time_cat = 0;
	   Else Breast_Milk_Time_cat = floor(Breast_Milk_Time/30);

	 * Classify feeding types (Breast: 33%, Formula: 62%, Mixed=4%);
	   If 0 <= Breast_Milk_Time_cat < 2 then FeedType="Formula";  												* If breast fed less than two months, then count as formula fed;
	   Else If 0 <= ACBAGE00 - Age_First_Formula_cat < 2 then FeedType="Breast"; 	 							* If Started formula less than two monts ago, then count as breast fed;
	   Else If Breast_Milk_Time_cat > 2 and 99 > Age_First_Formula_cat - ACBAGE00 > 2 then FeedType="Mixed";	* If was breast fed more than one month and formula fed more than one month, then mixed;
	   Else if Breast_Milk_Time > 2 then FeedType="Breast";
	   *Else if . < Age_First_Formula_cat < 99 then FeedType="Formula";
	   Else if ACBFEV00 ne . and ACAGDM00 ne . then FeedType="Formula";


/*-----------------------------*
 * Depression, stress, anxiety *
 *-----------------------------*/
   * Depression vars;
		DESYMP1=.; DESYMP2=.; DESYMP3=.; DESYMP4=.; DESYMP5=.; TOTDESYMP=.;
		If APDIFC0A in (61) then DESYMP1=1; Else if APDIFC0A ne . then DESYMP1=0;
		If APLOSA00=1 then DESYMP2=1; Else if APLOSA00 ne . then DESYMP2=0;
		If APDEPR00=1 then DESYMP3=1; Else if APDEPR00 ne . then DESYMP3=0;
		If APPESH00=1 then DESYMP4=1; Else if APPESH00 ne . then DESYMP4=0;
		If APRULI00=2 then DESYMP5=1; Else if APRULI00 ne . then DESYMP5=0;
		TOTDESYMP=sum(DESYMP2--DESYMP5); *DEP1 didn't load on the factor - see "check depression vars.sas";
	* Anxiety vars;
		ANXSYMP1=.; ANXSYMP2=.; ANXSYMP3=.; ANXSYMP4=.; ANXSYMP5=.; TOTANXSYMP=.;
		If APWORR00=1 then ANXSYMP1=1; else if APWORR00 ne . THEN ANXSYMP1=0;
		If APSCAR00=1 then ANXSYMP2=1; else if APSCAR00 ne . THEN ANXSYMP2=0;
		If APUPSE00=1 then ANXSYMP3=1; else if APUPSE00 ne . THEN ANXSYMP3=0;
		If APKEYD00=1 then ANXSYMP4=1; else if APKEYD00 ne . THEN ANXSYMP4=0;
		If APHERA00=1 then ANXSYMP5=1; elsE if APHERA00 ne . THEN ANXSYMP5=0;
		TOTANXSYMP=sum(ANXSYMP2--ANXSYMP5); *Anx1 didn't load on the factor - see "check depression vars.sas";
	* Stress vars;
		STRSYMP1=.; STRSYMP2=.; STRSYMP3=.; TOTSTRSYMP=.;
		If APTIRE00=1 then STRSYMP1=1; else if APTIRE00 ne . THEN STRSYMP1=0;
		If APRAGE00=1 then STRSYMP2=1; else if APRAGE00 ne . THEN STRSYMP2=0;
		If APNERV00=1 then STRSYMP3=1; else if APNERV00 ne . THEN STRSYMP3=0;
		TOTSTRSYMP=sum(STRSYMP2--STRSYMP3); *Str1 didn't load on the factor - see "check depression vars.sas";

	DepStrAnxScale=TOTDESYMP+TOTANXSYMP+TOTSTRSYMP;

/*-----------------------------*
 * Other recodes               *
 *-----------------------------*/

  * Imcome/pay type;
	If APNETA00=. and APGROA00=. then pay_miss="both";
	Else if APNETA00=. and APGROA00 ne . then pay_miss="net";
    Else if APNETA00 ne . and APGROA00=. then pay_miss="gross";
	Else if APNETA00 ne . and APGROA00 ne . then pay_miss="none";
  * Recode education;
	If 1 <= ADACAQ00 <= 3 then education=1;  *1 to 3;
	Else if 4<=ADACAQ00<=5 then education=2; *4 to 5;
	Else if ADACAQ00 ne . then education=9;  *None or overseas;
	Else if ADACAQ00=. then education=.;
  * ADWKST00 corresponds exactly;
  * Recode Income levels (single or family);
    If 2<=APNILP00<=9 or 2<=APNICO00<=9 then hh_income=1; *less than 10,400;
	Else If 10<=APNILP00<=13 or 10<=APNICO00<=13 then hh_income=2; *10400-20800;
	Else If 14<=APNILP00<=16 or 14<=APNICO00<=16 then hh_income=3; *20800-31200;
	Else If 17<=APNILP00<=19 or 17<=APNICO00<=19 then hh_income=4; *greater than 31200;
	Else If APNILP00 ne . or APNICO00 ne . then hh_income=-9; *don't know, refused, etc.;
  * Social Support;
	If APSEMO00 in (1,2,3) then see_parents=1;
	Else if APSEMO00 ne . then see_parents=2;
	If APFRTI00 in (1,2,3,4) then see_friends=1;
	Else if APFRTI00 ne . then see_friends=2;
  * APLOIL00 and APDEAN00 as is;
  * BMI;
	If . < ADBMIPRE < 18.5 then BMI_Range = 1;      *underweidght;
	Else if 18.5 <= ADBMIPRE < 25 then BMI_Range=2; *healthy;
	Else if 25 <= ADBMIPRE < 30 then BMI_Range=3;   *overweight;
	Else if 30 <= ADBMIPRE then BMI_Range=4;		   *obese;
  * Depression;
	If APDEAN00 ne . then do;
		If APTRDE00=1 then treat_now_depression = 1;
		Else treat_now_depression = 0;
	end;
  * Sum up probs in pregnancy;
    Probs_in_pregnancy = n(of APILWM0A--APILWM0G);  * count of non-missing vars;
  * Marital status recode;
	If APFCIN00 in (2, 3) then Married = 1;
	Else if APFCIN00 in (1, 4, 5, 6) then Married = 0;
  * Weight;
	birth_weight = ADBWGT00;
	recent_weight = ADLSTW00; *missing for 542;
	age_weighed = ADAGLW00; *missing for 743;
  * Total number of kids mom has;
    If APOTCH00 = 1 then total_mom_kids = num_mom_kids_at_home + APOTCN00; *APOTCH00 (any other kids not in hh) has 683 missing;
	Else total_mom_kids = num_mom_kids_at_home;
	parity=.;
	If total_mom_kids ne . then do;
		If total_mom_kids=1 then parity=0;
		Else if total_mom_kids=2 then parity=1;
		Else if total_mom_kids > 2 then parity=2;
	end;
  * Age at Parity;
	If parity=0 then Age_parity_0 = ADDAGB00; else Age_parity_0=.;
	If parity>0 then Age_parity_gt0 = ADDAGB00; else Age_parity_gt0=.;


*-----------------*
* Dummies;
*-----------------*;
 		*proc freq;
		*tables APLOIL00 APDEAN00 ADD06E00 AHCSEX00 COUNTRY feed_type_3mos education hh_income see_friends treat_now_depression Married parity;
		*format _All_;

		IF APLOIL00=1 then d_illness=1;
		Else if APLOIL00=2 then d_illness=0;

		If APDEAN00=1 then d_depression=1;
		Else if APDEAN00=2 then d_depression=0;

		If ADD06E00=1 then d_nonwhite=0;
		Else if ADD06E00 ne . then d_nonwhite=1;

		If AHCSEX00=1 then d_female=0;
		Else if AHCSEX00=2 then d_female=1;

		If COUNTRY=1 then d_otherUK=0;
		Else if COUNTRY ne . then d_otherUK=1;

		If feed_type_3mos=3 then d_noBreast_3mos=1;
		Else if feed_type_3mos ne . then d_noBreast_3mos=0;

		If education in (1,2) then d_degree=1;
		Else if education=9 then d_degree=0;
		
		If hh_income=1 then d_income=1;
		Else if hh_income in (2,3,4) then d_income=0;

		If see_friends=1 then d_seeFriends=1;
		Else if see_friends=2 then d_SeeFriends=0;

		psg_2 =.; psg_3=.;
		  If pregnancy_smoke_grp=2 then psg_2=1;   else if pregnancy_smoke_grp ne . then psg_2=0;
		  If pregnancy_smoke_grp=3 then psg_3=1; else if pregnancy_smoke_grp ne . then psg_3=0;
		
		csg_2 =.; csg_3=.;
		  If current_smoke_grp=2 then csg_2=1;   else if current_smoke_grp ne . then csg_2=0;
		  If current_smoke_grp=3 then csg_3=1; else if current_smoke_grp ne . then csg_3=0;

	    If ADMCPO00=-1 then poverty=.;
	     Else poverty=ADMCPO00;

		If feed_type_3mos = 1 then do; feed3mo_breast=1; feed3mo_mixed=0; end;
		If feed_type_3mos = 2 then do; feed3mo_mixed=1; feed3mo_breast=0; end;
		If feed_type_3mos = 3 then do; feed3mo_breast=0; feed3mo_mixed=0; end;


* Recodes to match macro for Z-scores of weight/height;
	agedays=age_weighed;
	If AHCSEX00=1 then sex=1; Else if AHCSEX00=2 then sex=2;
	height=.;

*--------------------------*;
* Z-scores;
*--------------------------*;

* Recent weight;
	data mydata;
	set mother_child (rename=(recent_weight=weight));
		agedays=age_weighed; *for recent weight;

	%include "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Code\UK_Project\WHO-source-code.sas";
*	proc contents data=_whodata position;run;
/*	proc univariate data=_whodata; var waz; histogram waz;title "recent weight for age z";run;*/

	data recent;
	set _whodata(keep=sex wapct waz weight MCSID-- feed3mo_mixed rename=(waz=waz_recent wapct=wapct_recent weight=recent_weight));

run;


* Birth weight;
	data mydata;
	set mother_child (rename=(birth_weight=weight));
		  agedays=0; * agedays should be 0 since at birth;
			
	%include "\\cifs.isip01.nas.umd.edu\SPHLFMSCShare\Labs\Shenassa\UK Project\Code\UK_Project\WHO-source-code.sas";
/*	proc univariate data=_whodata; var waz; histogram waz;title "birth weight for age z";run;*/

	data birth;
	set _whodata(keep=wapct waz weight MCSID ACNUM00 rename=(waz=waz_birth wapct=wapct_birth weight=birth_weight));
	run;
		
* Merge;
  data out ina inb;
  merge recent(in=a) birth(in=b);
  by MCSID ACNUM00;
  if a and not b then output ina;
  if b and not a then output inb;
  output out;
   
  run;

* Label, clean up and save;
	data analysis_dat;
	set out ;

	If parity=0 then Age_parity_0 = ADDAGB00; else Age_parity_0=.;
	If parity>0 then Age_parity_gt0 = ADDAGB00; else Age_parity_gt0=.;

		wt_change = recent_weight - birth_weight;
		waz_change = waz_recent - waz_birth;

		label 	waz_recent="weight-for-age z based on most recent weight (WHO macro)"
				wapct_recent="weight-for-age percentile based on most recent weight (WHO macro)"
				pregnancy_smoke="number of cigarettes smoked during pregnancy (created)" 
				smoking_miss="indicator if all smoking variables were missing for mother (created)"
				Any_Breast_Milk="indicator if baby had any breast milk (created)"
				Breast_Milk_Time="number of days had breast milk, not necessarily exclusively (created)"
				Age_First_Formula="Age in days first had formula (created)"
				Age_First_CowMilk="Age in days first had cow's milk (created)"
				Age_First_OthMilk="Age in days first had other milk (created)"
				Age_First_Solid="Age in days first had solid food (created)"
				Probs_in_pregnancy="Number of problems during pregnancy (created)"
				Married="Whether currently married (created)"
				birth_weight="Birth weight in kilograms"
				recent_weight="Most recent weight in kilograms"
				age_weighed="Age in days most recently weighed"
				waz_birth="weight-for-age z based on most birth weight (WHO macro)"
				wapct_birth="weight-for-age percentile based on most birth weight (WHO macro)"
				pay_miss="which pay variables are missing"
				education="education level (created from ADACAQ00)"
				hh_income="income level (created from APNILP00 and APNICO00)"
				see_parents="wheter has social support from parents (created from APSEMO00)"
				see_friends="whether has social support from friends (created from APFRTI00)"
				BMI_Range="1=underweight, 2=healthy, 3=overweight, 4=obese (created from ADBMIPRE)"
				treat_now_depression="If mom ever diagnosed, is she currently being treated for depresison (created)"
				total_mom_kids="Total number of natural kids of mom: num_mom_kids_at_home (+ APOTCN00 if not missing) (created)"
				Age_First_Solid_cat="Month first had solid (rounded down)"
				Age_First_Formula_cat="Month first had formula (rounded down)"
				Age_First_CowMilk_cat="Month first had cow milk (rounded down)"
				first_other_food_cat="Month first had other (rounded down)"
				Breast_Milk_Time_cat="Month stopped breast feeding (rounded down)"
				FeedType="Feeding type (breast, mixed, formula)"
				DESYMP1="Most diff 1 st 9 months: baby crying; adjusting;"
				DESYMP2="Felt low/sad since most recent child was born"
				DESYMP3="Often miserable or depressed"
				DESYMP4="Have no one to share feelings with"
				DESYMP5="usually find life�s problems too much"
				TOTDESYMP="total depressive symptomps (2-5)"
				ANXSYMP1="Often worried about things"
				ANXSYMP2="Suddenly scared for no reason"
				ANXSYMP3="Easily upset or irritated"
				ANXSYMP4="Constantly keyed up or jittery"
				ANXSYMP5="Heart often races like mad"
				TOTANXSYMP="Total anxiety symptoms (2-5)"
				STRSYMP1="Tired most of time"
				STRSYMP2="Often violent rage"
				STRSYMP3="Everything gets on nerves"
				TOTSTRSYMP="Total stress symptoms (2-3)"
				Parity="0 is 1 kid |1 is 2 kids | 2 is >2 kids"
				DepStrAnxScale="TotDep + TotAnx + TotStr";
				
/*	proc contents position;run;
	proc freq; tables current_smoke_grp;run; */

*------------------------------------------------------------------*;
* Output a variety needed for anaylsisy;
*------------------------------------------------------------------*;
* All variables and obs;
	data analysis.analysis_dat_6;  * _5: reordered FeedType_3mos | _6: refactored feeding method determination; 
	set analysis_dat;
run;
proc contents data=analysis.analysis_dat_5 position;run;


