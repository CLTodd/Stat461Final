##################################################################################
### Candace Todd
### 4/21/2022
### GOAL: Merge averaged covid data with cleaned school data and select a random sample
##################################################################################

rm(list=ls())

library(data.table)
library(dplyr)

# Read in data
covid <- data.table(readRDS("./Data/cleanCovid"))
schools <- data.table(readRDS("./Data/cleanSchools"))

# Merge data
mergedFull <-
  inner_join(covid,
             schools,
             by=c("fips_code"="COUNTYFIPS"))

# Still have a ton of variables to clean up from the schools data
dim(mergedFull)

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
counties <- readRDS("./Data/countiesWithNegativeCovidRates")
table(counties %in% mergedTrimmed$fipsCode)
# This was a problem before but we retroactively dealt with the negative value in the county that had this issue

# Randomly sample 280 rows
set.seed(16802)
rows <- sample(1:nrow(mergedTrimmed), size=280, replace=FALSE)
mergedTrimmedSample <- mergedTrimmed[rows,]
# of course...
table(counties %in% mergedTrimmedSample$fipsCode)
# Again, this was a problem but it was dealt with

# Save the data
setkey(mergedFull, "UNITID")
saveRDS(mergedFull, "./Data/mergedFull")
fwrite(mergedFull, "./Data/mergedFull.csv")

setkey(mergedTrimmed, "ipsedID")
saveRDS(mergedTrimmed, "./Data/mergedTrimmed")
fwrite(mergedTrimmed, "./Data/mergedTrimmed.csv")

setkey(mergedTrimmedSample, "ipsedID")
saveRDS(mergedTrimmedSample, "./Data/mergedTrimmedSample")
fwrite(mergedTrimmedSample, "./Data/mergedTrimmedSample.csv")
