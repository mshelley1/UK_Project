* Encoding: UTF-8.
GET FILE   = 'L:\UK Project\Analysis Data\Data sets\model_dat.sav'
    
CSGLM waz_change BY feed_type_3mos pregnancy_smoke_grp Married d_nonwhite
    /PLAN FILE='L:\UK Project\Code\UK_Project\cspaovwt2.csplan'
    /MODEL feed_type_3mos pregnancy_smoke_grp Married d_nonwhite
    /INTERCEPT INCLUDE=YES SHOW=YES
    /STATISTICS PARAMETER TTEST
    /MISSING CLASSMISSING=EXCLUDE
