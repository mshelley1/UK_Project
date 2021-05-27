*
* Create derived smoking variables;
*
;

libname analysis "J:\UK Project\Analysis Data\Data sets";

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

data mother_child;
set analysis.mother_child;
	pregnancy_smoke = .;
	
	If APSMTY00=2 and 
;

Pregnancysmoke=.;

If ‘smoke in the last 2 years’=No & ‘before pregnancy’=. then pregnancysmoke=0;

If smoker and ‘did not change during pregnancy’ then pregnancysmoke=# during pregnancy;

If smoker and ‘changed during pregnancy’ then pregnancysmoke=highest # during pregnancy (APCICH00);
