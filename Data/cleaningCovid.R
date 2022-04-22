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
covidDataRaw <- fread("./Final Project/United_States_COVID-19_County_Level_of_Community_Transmission_Historical_Changes.csv")

# Replace "suppressed" values with NA and remove commas from numbers
# Remove the old version of the variables
covidData <-
  covidDataRaw %>%
  mutate(date = mdy(date),
         casesPerCapita7DayChange = ifelse(cases_per_100K_7_day_count_change=="suppressed", NA, cases_per_100K_7_day_count_change),
         casesPerCapita7DayChange = as.numeric(gsub("\\,", "", casesPerCapita7DayChange)),
         pctTestsPositive7Days = ifelse(percent_test_results_reported_positive_last_7_days=="suppressed", NA, percent_test_results_reported_positive_last_7_days)) %>%
  select(-c(cases_per_100K_7_day_count_change,percent_test_results_reported_positive_last_7_days))

# Somehow there are 15 negative values in here. I have no idea what a negative value would mean and there's no documentation on it that I can find so I hope they go away when we match the counties to schools.
table(covidData$casesPerCapita7DayChange<0)
df <- covidData[which(covidData$casesPerCapita7DayChange<0), "fips_code"]
df

# Calculate our response for the study: 
# The average new cases-per-day from Sep. 1 to Dec. 1 in a given county
# Ignore the other average we calculate, we don't plan on using that
covidDataSummary <-
  covidData %>%
  filter(date >= mdy("09/01/2021") | date < mdy("12/01/2021")) %>%
  group_by(county_name, fips_code, state_name) %>%
  summarise(avgCasePerCapita = mean(casesPerCapita7DayChange, na.rm=TRUE),
            avgPctPositive = mean(pctTestsPositive7Days, na.rm=TRUE))
  
saveRDS(covidDataSummary, "./Final Project/cleanCovid")
fwrite(covidDataSummary, "./Final Project/cleanCovid.csv")

saveRDS(df, "./Final Project/countiesWithNegativeCovidRates")
