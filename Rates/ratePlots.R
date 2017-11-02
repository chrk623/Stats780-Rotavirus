for(pkg in c('dplyr', 'ggplot2', 'grid', 'gridExtra')){
  if(!(pkg %in% installed.packages())){
    suppressMessages(
      install.packages(pkg, repos = "https://cran.stat.auckland.ac.nz/")
    )
  }
}

library(dplyr)
library(ggplot2)
library(grid)
library(gridExtra)

createPlot <- function(csvFile, outFile, yLab, rotate = F, ...) {
  toPlot = read.csv(csvFile, header = T) %>%
    mutate(DenomSubTypeLabel = factor(DenomSubTypeLabel),
           Event = if_else(Event == "Intussusception", "Intussusception*", as.character(Event)))
  
  plotObj <- ggplot(data = toPlot, aes(x = DenomSubTypeLabel, y = Rate)) + 
    geom_errorbar(mapping = aes(ymin = Lower_95CI, ymax = Upper_95CI), width = 0.3) + 
    geom_point(shape = 21, fill = "black", ...) + 
    facet_wrap( ~ Event, nrow = 3, scales = "free_y") + 
    theme_bw() +
    labs(title = "Rates of Hospitalisation per 100,000 children", subtitle = paste0("Aged 0 - 72 months old by ", yLab), x = yLab, y = "Rate per 100,000")
  
  if (rotate) {
    plotObj <- plotObj + theme(axis.text.x=element_text(angle=90))
  }
  
  g <- grid.arrange(plotObj, 
                    bottom = textGrob("* Intussusception Rates are for children aged 0 - 36 months only.", 
                                      x = 0, 
                                      hjust = -0.1, 
                                      vjust=0.1, 
                                      gp = gpar(fontface = "italic", fontsize = 8)
                                      )
                    )
  
  ggsave(outFile, plot = g, height = 10, width = 5)
}

createPlot(csvFile = "Year.csv", outFile = "YearPlot.png", yLab = "Year")
createPlot(csvFile = "Age.csv", outFile = "AgePlot.png", yLab = "Age Band", size = 0.75)
createPlot(csvFile = "Ethnicity.csv", outFile = "EthPlot.png", yLab = "Ethnicity", size = 1)
createPlot(csvFile = "Deprivation.csv", outFile = "DepPlot.png", yLab = "Deprivation Index")
createPlot(csvFile = "District.csv", outFile = "DHBPlot.png", yLab = "District Health Board", rotate = T, size = 0.75)
