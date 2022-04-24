##################################################################################
### Candace Todd
### 4/24/2022
### GOAL: Clean data from Chronicle of Higher Ed's vaccine policy list
##################################################################################

# Setup Workspace
rm(list = ls())

library(data.table)
library(dplyr)
library(lubridate)

# Get data
vaxPoliciesRaw <- fread("./Data/data-7G1ie.csv")

# Split college names from their URL
vaxPolicies <-
  vaxPoliciesRaw %>%
  # Giving problematic columns some more conventional names
  rename("State"="State  ^Color denotes 2020 presidential result^",
         "allEmployees" = "All employees  ^(Vaccination required)^",
         "someEmployees" = "Some employees<sup>1</sup> ^(Vaccination required)^",
         "allStudents"="All students  ^(Vaccination required)^",
         "resStudentsOnly"="Only residential students  ^(Vaccination required)^",
         "boosterRequired"="Booster required?",
         "announceDate" = "Announce date",
         "type" = "Type",
         "statePol2020"="state_pol") %>%
  mutate(# Splitting up the school name and the anouncement URL
         school = gsub(pattern="\\[|\\]|\\(.+",
                     replacement="",
                     x=College),
         url = gsub(pattern="^(\\[.+\\]\\()|(\\).*)$",
                    replacement="",
                    x=College),
         announceDate = mdy(announceDate),
         type = factor(type),
         # These next variables were all dashes and checkmarks in the csv,
         # so we recode them appropriately here
         allEmployees = ifelse(allEmployees=="--",0,1),
         someEmployees = ifelse(someEmployees  =="--",0,1),
         allStudents = ifelse(allStudents=="--",0,1),
         resStudentsOnly = ifelse(resStudentsOnly=="--",0,1),
         boosterRequired = ifelse(boosterRequired=="--",0,1)) %>%
  select(-c(College))

str(vaxPolicies$announceDate)

# Not sure why the date for this school didn't parse correctly
# The rest of the parsing 'errors' were missing values
vaxPoliciesRaw[141,c("College", "Announce date")]
vaxPolicies[141,c("school", "announceDate")]
vaxPolicies[[141, "announceDate"]] <- mdy("7/15/2021")
vaxPolicies[141,c("school", "announceDate")]

# save policy data
setkey(vaxPolicies, "school")
saveRDS(vaxPolicies, "./Data/vaxPolicies")
fwrite(vaxPolicies, "./Data/vaxPolicies.csv")

