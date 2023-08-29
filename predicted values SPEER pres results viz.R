
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

# Read SAS pred_data set, munge the factor vars
  path<-"//cifs.isip01.nas.umd.edu/SPHLFMSCShare/Labs/Shenassa/UK Project/Analysis Data/Data sets/outmodel_interaction.sas7bdat"
    
  pred_dat<-read_sas(path) %>%
       select(c(current_smoke_grp, waz_change, feed_type_3mos, d_female, predicted, residuals, stderr)) %>%
       mutate(current_smoke_grp=as.factor(current_smoke_grp)) %>%
       mutate(feed_type_3mos=as.factor(feed_type_3mos))
  
  pred_dat$current_smoke_grp <- factor(
    pred_dat$current_smoke_grp,
    levels = c(1, 2, 3),
    labels = c("No smoking","1-10 cig/day", "10+ cig/day"))
  
  pred_dat$feed_type_3mos <- factor(
    pred_dat$feed_type_3mos,
    levels = c(1, 2, 3),
    labels = c("Exclusive Breast Feeding","No Breast Feeding", "Mixed Feeding"))
  
  pred_dat$d_female <- factor(
    pred_dat$d_female,
    levels = c(0,1),
    labels = c("Male", "Female"))
  
### Predicted v. actual
    ggplot(pred_dat, aes(x=waz_change, y=predicted)) +
      geom_point() +
      coord_cartesian(xlim = c(-6, 6), ylim = c(-6, 6)) +
      geom_abline(slope=1, color="blue") +
      labs(title = "Predicted v. Actual Change in Weight for Age (Z-Score)")
    
    
### Predicted by smoke grps      
    summary_data1 <- pred_dat %>%
      group_by(current_smoke_grp) %>%
      summarize(
        Mean_predicted = mean(predicted),
        SE_predicted = sd(predicted) / sqrt(n())
      )   
    
    ggplot(summary_data1, aes(x = current_smoke_grp, y = Mean_predicted)) +
      geom_point(stat="identity", fill="blue", size=3) +
    geom_errorbar(aes(ymin = Mean_predicted - SE_predicted, ymax = Mean_predicted + SE_predicted),
                  width = 0.2, color = "red", position = position_dodge(width = 0.9)) +
      coord_cartesian(ylim = c(.1, .8)) + 
      labs(
        title = "Mean Predicted Weight Change by Mother's Current Smoking",
        x = "Mother's smoking since baby's birth",
        y = "Change in baby's weight since birth (weight for age Z-score)"
      )
    
### Predicted by smoke grps and feeding type
    summary_data2 <- pred_dat %>%
      group_by(current_smoke_grp, feed_type_3mos) %>%
      summarize(
        Mean_predicted = mean(predicted),
        SE_predicted = sd(predicted) / sqrt(n())
      )   
    
      ggplot(summary_data2, aes(x = current_smoke_grp, y = Mean_predicted)) +
      geom_point(stat="identity", fill="blue", size=3) +
      geom_errorbar(aes(ymin = Mean_predicted - SE_predicted, ymax = Mean_predicted + SE_predicted),
                    width = 0.2, color = "red", position = position_dodge(width = 0.9)) +
#      coord_cartesian(ylim = c(.1, .8)) + 
      facet_wrap(~feed_type_3mos) +
      labs(
        title = "Mean Predicted Weight Change by Feeding Method and Mother's Current Smoking",
        x = "Mother's smoking since baby's birth",
        y = "Change in baby's weight since birth (weight for age Z-score)"
      ) 
    
### Predicted by smoke grps and feeding type and sex
    summary_data3 <- pred_dat %>%
    group_by(current_smoke_grp, feed_type_3mos, d_female) %>%
    summarize(
      Mean_predicted = mean(predicted),
      SE_predicted = sd(predicted) / sqrt(n())
      )   
    
    ggplot(summary_data3, aes(x = current_smoke_grp, y = Mean_predicted)) +
      geom_point(stat="identity", fill="blue", size=3) +
      geom_errorbar(aes(ymin = Mean_predicted - SE_predicted, ymax = Mean_predicted + SE_predicted),
                    width = 0.2, color = "red", position = position_dodge(width = 0.9)) +
      #      coord_cartesian(ylim = c(.1, .8)) + 
      facet_wrap(~feed_type_3mos*d_female, nrow=3, ncol=2) +
      labs(
        title = "Mean Predicted Weight Change by Feeding Method, Mother's Current Smoking, and Baby's Sex",
        x = "Mother's smoking since baby's birth",
        y = "Change in baby's weight since birth (weight for age Z-score)"
      ) 