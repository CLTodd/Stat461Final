##################################################################################
### Candace Todd
### 5/5/2022
### GOAL: Resample from the sample (didn't incorporate blocks correctly)
##################################################################################
rm(list=ls())
library(dplyr)
library(data.table)

# Load in the data
schools <- readRDS("./Data/cleanSchools")
covid <- data.table(readRDS("./Data/cleanCovid"))

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
  dplyr::select(c("UNITID",
           "INSTNM",
           "county_name",
           "fips_code",
           "STATE",
           "avgCasePerCapita",
           "CNTLAFFI")) %>%
  rename("ipsedID"="UNITID",
         "school"="INSTNM",
         "county"="county_name",
         "fipsCode"="fips_code",
         "state"="STATE",
         "schoolType"="CNTLAFFI") %>%
  mutate(schoolType = ifelse(schoolType==1, "Public", "Private"))

# Block the schools
public <- filter(mergedTrimmed, schoolType=="Public")
private <- filter(mergedTrimmed, schoolType=="Private")

# Randomly sample 280 rows
set.seed(314)
rowsPublic <- sample(1:nrow(public), size=140, replace=FALSE)
rowsPrivate <- sample(1:nrow(private), size=140, replace=FALSE)

publicSample <- mergedTrimmed[rowsPublic,]
privateSample <- mergedTrimmed[rowsPrivate,]

old <-
  readRDS("./Data/finalSampleVerified")

table(publicSample$ipsedID %in% old$ipsedID)
table(privateSample$ipsedID %in% old$ipsedID)
