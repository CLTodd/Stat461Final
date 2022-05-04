##################################################################################
### Candace Todd
### 5/4/2022
### GOAL: Resample from the population
###       (Jordan discovered that 4 of the originally samples schools were closed)
##################################################################################

# Set up workspace
rm(list = ls())

library(data.table)
library(dplyr)

# IPSED IDs of the schools from our original sample that were closed in fall 2021 
closedSchools <- c(101541, 443784, 451820, 474906)

# Download manually cleaned merged data from our google sheets
# if you're interested in taking a look, the Google Sheets we used is open to the public for viewing
# "https://docs.google.com/spreadsheets/d/1biC2ku9HWMwRWg2W1pGK_zJmWvpmqW0N_MzvwEg90_s/edit?usp=sharing"
# Red rows are the schools that ended up being closed

# I downloaded the Google Sheets as a csv, renamed it, and saved it to the data folder 
# this is what I'm reading in here as a data table
sampleMostlyVerified <- 
  data.table(
  read.csv("./Data/mergedPartiallyVerified.csv",
                                 header=TRUE)
  )

setnames(sampleMostlyVerified, "allStudentsCHECK", "vaccine")

setorder(sampleMostlyVerified, ipsedID)

# Save these so we don't pick the same schools again
chosenIPSED <- sampleMostlyVerified$ipsedID

# Remove the closed schools
sampleVerifiedOnly <- 
  sampleMostlyVerified %>%
  filter(!(ipsedID%in%closedSchools)) %>%
  select(ipsedID, county, fipsCode, school, state, # identifying attributes
         avgCasePerCapita, mask, vaccine) # attributes we're interested in
  
# Randomly sample 4 new schools
mergedTrimmed <- readRDS("./Data/mergedTrimmed")
mergedTrimmedNew <- mergedTrimmed[!(mergedTrimmed$ipsedID %in% chosenIPSED),]
set.seed(461)
rows <- sample(1:nrow(mergedTrimmedNew), size=4, replace=FALSE)
newSchools <- mergedTrimmedNew[rows,]
setorder(newSchools, ipsedID)
# None of these schools had information in the vaccine policy data,
# I manually looked the information up.
mergedTrimmed[mergedTrimmed$school%in%newSchools$school,]
# Mask: This column refers to whether there was a policy on campus 
#       requiring ALL students to wear masks indoors. 
#       (other than where federally required like health facilities)
# Vaccine: Refers to whether vaccines were required for ALL 
#          (not including special health/religious exemptions) 
#          students at the school by Sept. 1, 2021
newSchools$mask <- c(0,0,0,0)
newSchools$vaccine <- c(0,0,0,0)

# URLs from which I got the above info, in order of those vectors. Just for safekeeping
#urlMask <- 
#  c("https://web.archive.org/web/20210828122534/https://www.ccu.edu/ccu-cares/",
#    # Even though this is recorded as Morningside "college" in the data set 
#    # I'm assuming that is an error because there is a Morningside "University" in the exact same county
#    "https://www.morningside.edu/campus-life-and-arts/campus-safety/morningside-health-update-coronavirus-covid-19/",
#    # See pages 7 and 8 of the PDF below
#    "https://static1.squarespace.com/static/5cb0ef2ea09a7e1dbb21c096/t/61167da6a32a2d37f7e7472f/1628863915487/student-playbook-fall-2021_v4.pdf",
#    # See the 4:51 and 8:24 marks in the video. Posted on youtube on Sept. 9 but listed as premiering on sept 1 here: https://www.langston.edu/information-and-resources-novel-coronavirus-covid-19
#    "https://www.youtube.com/watch?v=SMmWdKmCEzE")

finalSampleVerified <- rbind(sampleVerifiedOnly, newSchools)

setkey(finalSampleVerified, "ipsedID")
saveRDS(finalSampleVerified, "./Data/finalSampleVerified")
fwrite(finalSampleVerified, "./Data/finalSampleVerified.csv")
