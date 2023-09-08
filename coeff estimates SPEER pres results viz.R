
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

# Read SAS parameter estimates data for Feed_TypeNum
  n=16797   #Set n for confidence interval calc
  path<-"//cifs.isip01.nas.umd.edu/SPHLFMSCShare/Labs/Shenassa/UK Project/Analysis Data/Data sets/interactparmest.sas7bdat"

  parm_dat<-read_sas(path) %>%
    mutate(CE95_LL=Estimate-1.96*(StdErr/sqrt(n))) %>%   #Confidence intervals
    mutate(CE95_UL=Estimate+1.96*(StdErr/sqrt(n))) %>%
    filter(grepl('current',Parameter)) %>%               #Limit to interaction term, not other covars
    mutate(current_smoking = case_when(                  #Create two new vars, one for smoking and one for feedtype based on paramater name   
      substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "1" ~ 1,
      substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "2" ~ 2,
      substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "3" ~ 3)) %>% 
    mutate(feedtype = case_when(
      substr(Parameter, nchar(Parameter), nchar(Parameter)) == "1" ~ 1,
      substr(Parameter, nchar(Parameter), nchar(Parameter)) == "2" ~ 2,
      substr(Parameter, nchar(Parameter), nchar(Parameter)) == "3" ~ 3))
  
  #Label the factor groups for the graph
  parm_dat$current_smoking <- factor(            
    parm_dat$current_smoking,
    levels = c(1, 2, 3),
    labels = c("No smoking","1-10 cig/day", "10+ cig/day"))
  
  parm_dat$feedtype <- factor(
    parm_dat$feedtype,
    levels = c(1,2,3),
    labels = c("Breastfeeding Only", "Mixed", "Formula Only"))
  
  #Plot  
    ggplot(parm_dat, aes(x = current_smoking, y = Estimate)) +
    geom_point(stat="identity", fill="blue", size=3) +
    geom_errorbar(aes(ymin = CE95_LL, ymax = CE95_UL),
                  width = 0.2, color = "red", position = position_dodge(width = 0.9)) +
    facet_wrap(~feedtype) +
    labs(
        title = "Effect of smoking through feeding type on baby's weight gain",
        x = "Mother's smoking since baby's birth",
        caption="Formula only, 10+ cig/day is the reference category."
      )
    
  
# EverBreastFed: Read SAS parameter estimates data, munge
  n = 16797   #Set n for confidence interval calc
  path<-"//cifs.isip01.nas.umd.edu/SPHLFMSCShare/Labs/Shenassa/UK Project/Analysis Data/Data sets/everbreastinteractparmest.sas7bdat"
  
  eb_parm_dat<-read_sas(path) %>%
    mutate(CE95_LL=Estimate-1.96*(StdErr/sqrt(n))) %>%   #Confidence intervals
    mutate(CE95_UL=Estimate+1.96*(StdErr/sqrt(n))) %>%
    filter(grepl('current',Parameter)) %>%               #Limit to interaction term, not other covars
    mutate(current_smoking = case_when(                  #Create two new vars, one for smoking and one for feedtype based on paramater name   
      substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "1" ~ 1,
      substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "2" ~ 2,
      substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "3" ~ 3)) %>% 
    mutate(feedtype = case_when(
      substr(Parameter, nchar(Parameter), nchar(Parameter)) == "0" ~ 0,
      substr(Parameter, nchar(Parameter), nchar(Parameter)) == "1" ~ 1))
  
 #Label the factor groups for the graph
  eb_parm_dat$current_smoking <- factor(            
    eb_parm_dat$current_smoking,
    levels = c(1, 2, 3),
    labels = c("No smoking","1-10 cig/day", "10+ cig/day"))
  
  eb_parm_dat$feedtype <- factor(
    eb_parm_dat$feedtype,
    levels = c(0,1),
    labels = c("Formula Only","Any Breastfeeding"))
  
  #Plot
    ggplot(eb_parm_dat, aes(x = current_smoking, y = Estimate)) +
    geom_point(stat="identity", fill="blue", size=3) +
    geom_errorbar(aes(ymin = CE95_LL, ymax = CE95_UL),
                  width = 0.2, color = "red", position = position_dodge(width = 0.9)) +
    facet_wrap(~feedtype) +
    labs(
      title = "Effect of smoking through feeding type on baby's weight gain",
      x = "Mother's smoking since baby's birth",
      caption="Formula only, 10+ cig/day is the reference category."
    )
  
    
    
    
# By Sex * EverBreastFed: Read SAS parameter estimates data
    n_female=8180
    n_male=8617
    path<-"//cifs.isip01.nas.umd.edu/SPHLFMSCShare/Labs/Shenassa/UK Project/Analysis Data/Data sets/sexeverbreastinteractparmest.sas7bdat"
    
    s_eb_parm_dat<-read_sas(path) %>%
      mutate(CE95_LL=case_when(
        d_female=="0" ~ Estimate-1.96*(StdErr/sqrt(n_male)),
        d_female=="1" ~ Estimate-1.96*(StdErr/sqrt(n_female)))) %>%   #Confidence intervals
      mutate(CE95_UL=case_when(
        d_female=="0" ~ Estimate+1.96*(StdErr/sqrt(n_male)),
        d_female=="1" ~ Estimate+1.96*(StdErr/sqrt(n_female)))) %>% 
      filter(grepl('current',Parameter)) %>%                          #Limit to interaction term, not other covars
      mutate(current_smoking = case_when(                             #Create two new vars, one for smoking and one for feedtype based on paramater name   
        substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "1" ~ 1,
        substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "2" ~ 2,
        substr(Parameter, nchar(Parameter) - 2, nchar(Parameter) - 2) == "3" ~ 3)) %>% 
      mutate(feedtype = case_when(
        substr(Parameter, nchar(Parameter), nchar(Parameter)) == "0" ~ 0,
        substr(Parameter, nchar(Parameter), nchar(Parameter)) == "1" ~ 1))
    
   #Label the factor groups for the graph
    s_eb_parm_dat$current_smoking <- factor(
      s_eb_parm_dat$current_smoking,
      levels = c(1, 2, 3),
      labels = c("No smoking","1-10 cig/day", "10+ cig/day"))
    s_eb_parm_dat$feedtype <- factor(
      s_eb_parm_dat$feedtype,
      levels = c(0,1),
      labels = c("Formula Only","Any Breastfeeding"))
    s_eb_parm_dat$d_female <- factor(
      s_eb_parm_dat$d_female,
      levels = c(0,1),
      labels = c("Male","Female"))

    
   #Plot
    ggplot(s_eb_parm_dat, aes(x = current_smoking, y = Estimate)) +
      geom_point(stat="identity", fill="blue", size=3) +
      geom_errorbar(aes(ymin = CE95_LL, ymax = CE95_UL),
                    width = 0.2, color = "red", position = position_dodge(width = 0.9)) +
      facet_wrap(~feedtype*d_female) +
      labs(
        title = "Sex differences in effect of smoking through feeding type on baby's weight gain",
        x = "Mother's smoking since baby's birth",
        caption="Formula only, 10+ cig/day is the reference category."
      )
    
    