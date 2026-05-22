library(tidyverse)
library(haven)
library(lme4)

key <- read.csv('C:/Users/mmatt/Desktop/UIC/Olu/lld-sal/data/id_key2.csv')
key <- key[,c(1,5)]
netsz <- read.csv('C:/Users/mmatt/Desktop/UIC/Olu/lld-sal/derivatives/NetworkSizes_adjusted.csv')
netsz <- netsz[!is.na(netsz$Salience),]
netsz$sub[1:55] <- paste0('3REM',str_pad(netsz$sub[1:55], 3, pad="0"))
netsz$site <- NA
netsz$site[1:55] <- 'UIC'
netsz$site[56:114] <- 'VUMC'
netsz$site[115:172] <- 'UPMC'

ggplot(netsz, aes(x = Salience, fill = site)) +
  geom_density(alpha = 0.5) +
  labs(title = "Distribution of Salience Network Size by Site",
       x = "Salience Network Size (%)", y = "Density") +
  theme_minimal()

outcomes <- read.csv('C:/Users/mmatt/Desktop/UIC/Olu/lld-sal/data/RembrandtData-MADRS-CGI.csv')

df <- merge(key,outcomes,by="record_id")
colnames(df)[2] <- 'sub'
df <- merge(df,netsz,by="sub",all=T)

#df <- df[df$redcap_event_name=="baselinemonth_0_arm_3" | df$redcap_event_name=="month_8_arm_3" 
#         | df$redcap_event_name=="month_16_arm_3" | df$redcap_event_name=="month_24_arm_3",]
df <- df[df$redcap_event_name=="baselinemonth_0_arm_3",]
df <- df[df$record_id!=331,]
df <- df[df$record_id!=332,]
df <- df[,-c(4,5,6)]
#df <- df[!is.na(df$ma_tot),]

labels <- read.csv('C:/Users/mmatt/Desktop/UIC/Olu/lld-sal/data/DataLabels.csv')
colnames(labels)[1] <- 'record_id'
labels <- labels[grepl("Baseline/Month 0", labels$Event.Name), ]
labels <- labels[,c(1,2,23)]
labels <- unique(labels)
labels <- labels[!is.na(labels$Total),]

# Create the depression status indicator with text labels
labels$Ever_Depressed <- ifelse(
  grepl("Never Depressed", labels$Event.Name),
  0,
  1 )
labels$Event.Name <- NULL


df <- merge(df,labels,'record_id',all=T)

bl_lm <- lmer(ma_tot ~ Salience + (1|site),df)
summary(bl_lm)
plot(df$Salience, df$ma_tot)
abline(a = fixef(bl_lm)[1],
       b = fixef(bl_lm)[2],
       col = "blue", lwd = 2)


bl_log <- glm(Ever_Depressed ~ Salience, 
             data = df, 
             family = binomial(link = "logit"))

# View the results
summary(bl_log)

