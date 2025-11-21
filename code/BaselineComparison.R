library(tidyverse)
library(haven)

netsz <- read.csv('C:/Users/mmatt/Desktop/UIC/Olu/lld-sal/derivatives/NetworkSizes.csv')
netsz$sub[59:216] <- str_sub(netsz$sub[59:216], 3)
netsz$site <- NA
netsz$site[1:58] <- 'UIC'
netsz$site[59:156] <- 'VUMC'
netsz$site[157:216] <- 'UPMC'

ggplot(netsz, aes(x = Salience, fill = site)) +
  geom_density(alpha = 0.5) +
  labs(title = "Distribution of Salience Network Size by Site",
       x = "Salience Network Size (%)", y = "Density") +
  theme_minimal()

outcomes <- read_sav('C:/Users/mmatt/Desktop/UIC/Olu/lld-sal/data/REM_DATABASE.sav')
colnames(outcomes)[1] <- 'sub'

df <- merge(netsz,outcomes,by="sub",all.x=T)

lm()