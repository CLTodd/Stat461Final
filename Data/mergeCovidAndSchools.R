##################################################################################
### Candace Todd
### 4/21/2022
### GOAL: Merge averaged covid data with cleaned school data and select a random sample
##################################################################################

rm(list=ls())

library(data.table)
library(dplyr)

# Read in data
covid <- data.table(readRDS("./Final Project/cleanCovid"))
schools <- data.table(readRDS("./Final Project/cleanSchools"))

# Merge data
mergedFull <-
  inner_join(covid,
             schools,
             by=c("fips_code"="COUNTYFIPS"))

# Still have a ton of variables to clean up from the schools data
dim(merged)

# These are the only variables I expect to be useful
mergedTrimmed <-
  mergedFull %>%
  select(c("UNITID",
          "INSTNM",
          "county_name",
          "fips_code",
          "STATE",
          "avgCasePerCapita")) %>%
  rename("ipsedID"="UNITID",
         "school"="INSTNM",
         "county"="county_name",
         "fipsCode"="fips_code",
         "state"="STATE")

# Three of the counties with negative values are in this data set. 
df <- readRDS("./Final Project/countiesWithNegativeCovidRates")
table(df$fips_code %in% mergedTrimmed$fipsCode)
# This may be a problem

# Randomly sample 280 rows
set.seed(16802)
rows <- sample(1:nrow(mergedTrimmed), size=280, replace=FALSE)
mergedTrimmedSample <- mergedTrimmed[rows,]

# Save the data
setkey(mergedFull, "UNITID")
saveRDS(mergedFull, "./Final Project/mergedFull")
fwrite(mergedFull, "./Final Project/mergedFull.csv")

setkey(mergedTrimmed, "ipsedID")
saveRDS(mergedTrimmed, "./Final Project/mergedTrimmed")
fwrite(mergedTrimmed, "./Final Project/mergedTrimmed.csv")

setkey(mergedTrimmedSample, "ipsedID")
saveRDS(mergedTrimmedSample, "./Final Project/mergedTrimmedSample")
fwrite(mergedTrimmedSample, "./Final Project/mergedTrimmedSample.csv")
