
library(haven)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(tidyr)

# Read in table 1 continuous vars
  path<-"//cifs.isip01.nas.umd.edu/SPHLFMSCShare/Labs/Shenassa/UK Project/Analysis Data/Data sets/table1_continuous.sas7bdat"
  t1c<-read_sas(path)
  t1c<-mutate(t1c, vdesc=c("Age of Mother", "Gestation Time in Days", "Z-Weight for Age at Birth", "Z-Change in Weight for Age", "Z-Most Recent Weight for Age", "Change in Weight (kgs)"))
    
  long_data <- pivot_longer(t1c, 
                            cols = !c(vname, vdesc),
                            names_to = "stat_name", 
                            values_to = "val")
  
  
  pivot_longer(
    cols = !religion, 
    names_to = "income", 
    values_to = "count"
  
  
  # Create individual plots for each variable
    plots <- lapply(t1c$vdesc, function(variable_name) {
      subset_data <- subset(t1c, vdesc == variable_name)
      p <- ggplot(subset_data, aes(x = labels)) +
        
        geom_point(aes(y = mean_1), stat = "identity", color = "green", alpha = .6, size=3) +
        geom_errorbar(aes(ymin = mean_1 - std_1, ymax = mean_1 + std_1), width = 0.1, position = position_dodge(width = 0.5), color="green") +
        
        geom_point(aes(y = mean_2), stat = "identity", color = "orange", alpha = .6, size=3) +
        geom_errorbar(aes(ymin = mean_2 - std_2, ymax = mean_2 + std_2), width = 0.1, position = position_dodge(width = 0.5), color="orange") +
        
        geom_point(aes(y = mean_3), stat = "identity", color = "red", alpha = .6, size=3) +
        geom_errorbar(aes(ymin = mean_3 - std_3, ymax = mean_3 + std_3), width = 0.1, position = position_dodge(width = 0.5), color="red") +
        
        coord_flip() +
        scale_color_manual(values=c("Non-Smokers"="green", "1-10 cigarettes per day"="orange", "More than 10 cigarettes per day"="red")) +
        theme(legend.position = "top") +
        guides(color = guide_legend(title = "Group Legend")) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
      return(p)
    })
    
    # Arrange the plots in a grid
      grid.arrange(grobs = plots, ncol = 2)  # Adjust ncol as needed
    