library(tidyverse)

netsz <- read.csv('C:/Users/mmatt/Desktop/UIC/Olu/lld-sal/derivatives/NetworkSizes.csv')
netsz$site <- NA
netsz$site[1:58] <- 'UIC'
netsz$site[59:156] <- 'VUMC'
netsz$site[157:216] <- 'UPMC'

ggplot(netsz, aes(x = Salience, fill = site)) +
  geom_density(alpha = 0.5) +
  labs(title = "Distribution of Salience Network Size by Site",
       x = "Salience Network Size (%)", y = "Density") +
  theme_minimal()
