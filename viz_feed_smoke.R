install.packages('haven')
install.packages('randomForest')
library(dplyr)
library(ggplot2)
library(haven)
library(randomForest)

indat<-read_sas('//cifs.isip01.nas.umd.edu/SPHLFMSCShare/Labs/Shenassa/UK Project/Analysis Data/Data sets/smoke_feed_viz.sas7bdat')

indat<-mutate(indat, waz_change=waz_recent - waz_birth)
indat<-mutate(indat, cig_now=ifelse(APSMMA00==0|is.na(APSMMA00),0,ifelse(1<=APSMMA00 & APSMMA00<=10,1,2)))
indat<-mutate(indat, cig_preg=ifelse(pregnancy_smoke==0|is.na(pregnancy_smoke),0,ifelse(1<=pregnancy_smoke & pregnancy_smoke<=10,1,2)))
indat<-mutate(indat, APSMMA00=ifelse(is.na(APSMMA00),0,APSMMA00))


ggplot(data=indat, aes(x=waz_recent)) +
    geom_histogram()+facet_wrap(vars(cig_now))


ggplot(data=indat, aes(x=waz_change)) +
  geom_histogram()+facet_wrap(vars(cig_now)) +
  labs(title = 'waz_change ~ cig_now')

ggplot(data=indat, aes(x=waz_change)) +
  geom_histogram()+facet_grid(rows=vars(sex),cols=vars(cig_now)) +
  labs(title='waz_change ~ sex, cig_now')
  
ggplot(data=indat, aes(x=waz_change)) +
  geom_histogram()+facet_grid(rows=vars(sex),cols=vars(feed_type_3mos))+
  labs(title='waz_change ~ sex, feed_type_3mos')

ggplot(data=indat, aes(x=waz_change)) +
  geom_histogram()+facet_grid(rows=vars(cig_now),cols=vars(feed_type_3mos))

ggplot(data=indat, aes(x=waz_change)) +
  geom_histogram()+facet_grid(rows=vars(cig_preg),cols=vars(feed_type_3mos))

par(mfrow=c(1,2))
ggplot(indat, aes(x=APSMMA00, y=waz_change)) +
  geom_point()

ggplot(indat, aes(x=pregnancy_smoke, y=APSMMA00)) +
  geom_point() +
  geom_smooth(method='lm', aes(color=sex, fill=sex))


ggplot(indat, aes(x=feed_type_3mos, y=waz_recent)) +
  geom_boxplot() + facet_wrap(vars(sex))




