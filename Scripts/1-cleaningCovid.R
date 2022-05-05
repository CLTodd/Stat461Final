##################################################################################
### Candace Todd
### 4/21/2022
### GOAL: Clean CDC covid data
##################################################################################

rm(list=ls())

library(data.table)
library(dplyr)
library(lubridate)

# Read in the CDC historical covid data
# Data source: https://data.cdc.gov/Public-Health-Surveillance/United-States-COVID-19-County-Level-of-Community-T/nra9-vzzn
covidDataRaw <- fread("./Data/United_States_COVID-19_County_Level_of_Community_Transmission_Historical_Changes.csv")

# Replace "suppressed" values with NA and remove commas from numbers
# Remove the old version of the variables
covidData <-
  covidDataRaw %>%
  mutate(date = mdy(date),
         # "When the total new case rate metric is greater than zero and less than 10, 
         # this metric is set to "suppressed" rather than including its value 
         # to protect individual privacy." -- I will change these values to 0
         casesPerCapita7DayChange = ifelse(cases_per_100K_7_day_count_change=="suppressed", 0, cases_per_100K_7_day_count_change),
         casesPerCapita7DayChange = as.numeric(gsub("\\,", "", casesPerCapita7DayChange)),
         pctTestsPositive7Days = ifelse(percent_test_results_reported_positive_last_7_days=="suppressed", NA, percent_test_results_reported_positive_last_7_days)) %>%
  dplyr::select(-c(cases_per_100K_7_day_count_change,percent_test_results_reported_positive_last_7_days))

# Somehow there are 15 negative values in here. I have no idea what a negative value would mean and there's no documentation on it that I can find so I hope they go away when we match the counties to schools.
table(covidData$casesPerCapita7DayChange<0)
negIdx <- which(covidData$casesPerCapita7DayChange<0)

# All happening betwen 12/30/20 and 1/15/21
summary(covidData$date[negIdx])

############################################3########## 
# I didn't know how exactly I wanted to handle the negative case counts
# so I avoided dealing with them until I knew I had to and came back to this problem
# Once I made my random selection and confirmed that one of the randomly selected
# Schools resides in a county that had a negative case count. This is a school in county 29147.
negCounties <- covidData$fips_code[negIdx]
df <- covidData[covidData$fips_code%in%negCounties, c("fips_code", "date", "casesPerCapita7DayChange")] %>%
  filter(date>=mdy("12/27/20") & date <= mdy("1/4/21"))

# We see that there was a drop to 0 new cases per capita in a 7 day window starting Dec. 30
# It is impossible to have a 7-day moving average of 0 new cases immediately before and after a non-zero moving average
# So I'm going to assume this was an error and convert this value to a 0
arrange(df[df$fips_code==29147,], date)
covidData[1114441, "casesPerCapita7DayChange"] <- 0

########################
df2 <- covidData[covidData$fips_code==48377, c("fips_code", "date", "casesPerCapita7DayChange")] %>%
  filter(date>=mdy("1/10/21") & date <= mdy("1/20/21"))

arrange(df2, date)
covidData[which(covidData$casesPerCapita7DayChange==-119.332), "casesPerCapita7DayChange"] <- 0
#######################

#########################################################

# Calculate our response for the study: 
# The average new cases-per-day from Sep. 1 to Dec. 1 in a given county
covidDataSummary <-
  covidData %>%
  filter(date >= mdy("09/01/2021") | date < mdy("12/01/2021")) %>%
  group_by(county_name, fips_code, state_name) %>%
  summarise(avgCasePerCapita = mean(casesPerCapita7DayChange, na.rm=TRUE),
                                  count=n())

# The averages we're getting are all based on the exact same number of data points
table(is.na(covidData$casesPerCapita7DayChange))
summary(covidDataSummary$count)
  
saveRDS(covidDataSummary, "./Data/cleanCovid")
fwrite(covidDataSummary, "./Data/cleanCovid.csv")

saveRDS(negCounties, "./Data/countiesWithNegativeCovidRates")
