
#
# Create graphics for vars of interest for presentation: exposures, outcome, gender
#

library(haven)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(tidyr)
library(ggthemes)
library(stringr)

# Read SAS data set, munge the factor vars
  path<-"//cifs.isip01.nas.umd.edu/SPHLFMSCShare/Labs/Shenassa/UK Project/Analysis Data/Data sets/model_dat_nomiss.sas7bdat"
    
  dat<-read_sas(path) %>%
       select(c(current_smoke_grp, waz_change, feed_type_3mos)) %>%
       mutate(current_smoke_grp=as.factor(current_smoke_grp)) %>%
       mutate(feed_type_3mos=as.factor(feed_type_3mos))
  
  dat$current_smoke_grp <- factor(
    dat$current_smoke_grp,
    levels = c(1, 2, 3),
    labels = c("No smoking","1-10 cig/day", "10+ cig/day"))
  
  dat$feed_type_3mos <- factor(
    dat$feed_type_3mos,
    levels = c(1, 2, 3),
    labels = c("Exclusive Breast Feeding","No Breast Feeding", "Mixed Feeding"))
  
# Plot overall waz_change for smoke grps  
    ggplot(dat, aes(x = current_smoke_grp, y = waz_change)) +
    geom_boxplot() +
    stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "red") +
    
    labs(title = "Change in baby's weight by mother's smoking",
         x = "Mother's smoking since baby's birth",
         y = "Change in baby's weight since birth (weight for age Z-score)")
 
# Plot waz_change for smoke grps and feeding type.     
  ggplot(dat, aes(x = current_smoke_grp, y = waz_change)) +
    geom_boxplot() +
    stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "red") +
    facet_wrap(~feed_type_3mos) +
    labs(title = "Change in baby's weight by mother's smoking and feeding method ",
         x = "Mother's smoking since baby's birth",
         y = "Change in baby's weight since birth (weight for age Z-score)") +
    scale_x_discrete(labels=scales::wrap_format(width=10))
  