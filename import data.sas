proc import
file = "J:\UK Project\Data Downloads\UKDA-4683-tab First Survey\tab\mcs1_parent_interview.tab"
out = test
dbms=dlm
replace;
delimiter='09'x;
datarow=2;

run;


proc contents data=test;run;
