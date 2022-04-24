##################################################################################
### Candace Todd
### 4/21/2022
### GOAL: Get a sample of undergraduate-serving 4-year colleges, universities, 
### and professional schools (with 1 school per county)
##################################################################################

# Prepare workspace
rm(list=ls())
library(dplyr)
library(lubridate)
library(data.table)

# Reading in the Data

# HIFLD data
collegesRaw <- fread(input="./Data/Colleges_and_Universities.csv",
                     header=TRUE,
                     sep=",")
# hd2020 survey data
hd <- read.csv("./Data/hd2020.csv")

# ic2020 survey data
ic <- read.csv("./Data/ic2020.csv")


# Join all the college data (ic2020, hd2020, and the HIFLD data)
all_IPEDS_data <- full_join(hd, ic, by='UNITID')
all_IPEDS_data <- full_join(all_IPEDS_data, collegesRaw, by=c("UNITID"="IPEDSID"))

# Check columns that had conflicts
names(all_IPEDS_data)[which(grepl(names(all_IPEDS_data), pattern="\\.(x|y)$"))]

# First we'll deal with conflicts in SECTOR since we actually need this variable
summary(as.factor(all_IPEDS_data$SECTOR.x))
summary(as.factor(all_IPEDS_data$SECTOR.y))

# Note: Since the  ic2020 and hd2020 documentation only mention 9 categories 
# and a brief examination of the data shows that the 'institutions' coded with 0's may just be offices,
# I believe 99 and 0 values should be recoded as NA.
hd[hd$SECTOR==0,][1:5,"INSTNM"]                 # support for the above comment
collegesRaw[collegesRaw$SECTOR==0,][1:5,"NAME"] # support for the above comment



# Filter for the schools that serve full-time undergrads
fourYrSchools <- 
  all_IPEDS_data %>%
  # Sector 1 = 4-year public school
  # Sector 2 = 4-year private non-profit
  # Sector 3 = 4-year private for-profit
  filter(NAICS_DESC=="COLLEGES, UNIVERSITIES, AND PROFESSIONAL SCHOOLS"&
           # FT_UG is a binary variable indicating whether undergrads can be enrolled full time 
           # I'm going to assume a -2 value means NA (as in the data is missing).
           # Schools that don't enroll full-time undergrads have a value of 2.
           FT_UG ==1 &
           # According to the ic2020 data, DISTNCED should refer to whether a school
           # Is a completely online university.
           # From manually checking schools from the data, I believe
           # 1=completely online, 2=otherwise, and not sure what negative values mean
           # (checked Amridge University and Penn State to confirm)
           DISTNCED==2)

# Here we resolve the missingness and mismatching in the sector variable
resolvedSector <-
  fourYrSchools %>%
  # If sector.x is missing
  mutate(SECTOR = ifelse(SECTOR.x %in% c(0,99, NA), 
                         # check if sector.y is missing
                         ifelse(SECTOR.y %in% c(0,99, NA), 
                                # if both are missing, the value is missing
                                NA, 
                                # If just sector.x is missing, use sector.y as the true value
                                SECTOR.y),
                         # if sector.x is not missing, check if sector.y is missing
                         ifelse(SECTOR.y %in% c(0,99, NA),
                                # If sector.y is missing, use sector.x value
                                SECTOR.x,
                                # If sector.y is not missing, check if x==y
                                ifelse(SECTOR.x==SECTOR.y,
                                       # If they are equal, use one of the values
                                       SECTOR.x,
                                       # If they are different, report conflict
                                       "CONFLICT!")
                                )
                         )
         ) %>%
  select(-c(SECTOR.x, SECTOR.y))

summary(as.factor(resolvedSector$SECTOR))
resolvedSector[which(resolvedSector$SECTOR=="CONFLICT!"),c("INSTNM","SECTOR")]
# Only conflict I see is for Aaniiih Nakoda College, which collegeboard lists as a 2-year university so I'm dropping it
# College board link: https://bigfuture.collegeboard.org/college-profile/aaniiih-nakoda-college

# Now we have a data frame of 4-year institutions that enroll undergraduates full time
resolvedSector <- 
  resolvedSector %>%
  filter(SECTOR != "CONFLICT!") %>%
  mutate(SECTOR = as.numeric(SECTOR)) %>%
  filter(SECTOR %in% c(1,2,3))

# Now we want to filter for the largest school in each county

# First we need to fix the counties, some of them can't be coerced to numeric
# (ignore the warning message from the next line)
collegesRaw[which(is.na(as.numeric(collegesRaw$COUNTYFIPS))),c("NAME","COUNTYFIPS")]
# These are colleges for which there actually are no FIPS codes, 
# It is appropriate for their FIPS codes to be NA
resolvedSector <- mutate(resolvedSector, COUNTYFIPS = as.numeric(COUNTYFIPS))

# Note: the FIPS colum from the hd data set refers to the FIPS state code.
# The FIPS county code is represented in the COUNTYCD column. See hd2020.xlsx 
# (the hd2020 survey data dictionary) for details.
table(resolvedSector$COUNTYFIPS==resolvedSector$COUNTYCD)

# There's few enough that I can manually lookup the counties listed and correct the FIPS codes accordingly
# These schools all have conflicting counties so we'll have to manually find their county using their address
resolvedSector[which(resolvedSector$COUNTYFIPS!=resolvedSector$COUNTYCD),c("INSTNM","COUNTYNM","COUNTY","STATE","COUNTYCD","COUNTYFIPS","UNITID")]


# Website used to look counties by address: https://tools.usps.com/zip-code-lookup.htm?byaddress
# Website used to look up FIPS code by county: https://www.census.gov/library/reference/code-lists/ansi.html#county
resolvedFIPS <- copy(resolvedSector)
resolvedFIPS[resolvedFIPS$UNITID==168847,"COUNTYFIPS"] <- 26155
resolvedFIPS[resolvedFIPS$UNITID==194161,"COUNTYFIPS"] <- 36061
resolvedFIPS[resolvedFIPS$UNITID==196583,"COUNTYFIPS"] <- 36085 # True city was staten island
resolvedFIPS[resolvedFIPS$UNITID==367884,"COUNTYFIPS"] <- 12071 # True city was fort myers
resolvedFIPS[resolvedFIPS$UNITID==438498,"COUNTYFIPS"] <- 51510 # True City was alexandria, address search yielded multiple results but all in the same county
resolvedFIPS[resolvedFIPS$UNITID==442949,"COUNTYFIPS"] <- 41067 # True city was beaverton
# This university has 3 locations: GA, AZ, and TX, but none in IL as listed in this data?
# The street address matches the campus for the AZ location so that's what I'll use
resolvedFIPS[resolvedFIPS$UNITID==445027,"COUNTYFIPS"] <- 04013
resolvedFIPS[resolvedFIPS$UNITID==451820,"COUNTYFIPS"] <- 48021 # True city is Bastrop
# Address listed here is un-findable using the UPS tool,
# University website lists 242 Old New Brunswick Rd Suite 220, Piscataway, NJ 08854 as the address so I used that
resolvedFIPS[resolvedFIPS$UNITID==453215,"COUNTYFIPS"] <- 34023
resolvedFIPS[resolvedFIPS$UNITID==460738,"COUNTYFIPS"] <- 08031 # True city was Denver
resolvedFIPS[resolvedFIPS$UNITID==460871,"COUNTYFIPS"] <- 51059 # True city was vienna
resolvedFIPS[resolvedFIPS$UNITID==465812,"COUNTYFIPS"] <- 49035
resolvedFIPS[resolvedFIPS$UNITID==482431,"COUNTYFIPS"] <- 06071

# Verify that we fixed all the mis-matches
table(resolvedFIPS$COUNTYFIPS==resolvedFIPS$COUNTYCD)

# Now we can address repeat universities within a county

# Get the counties that repeat and the number of schools in them from each county
repeatCounties <- 
  resolvedFIPS %>%
  group_by(COUNTYFIPS) %>%
  summarize(count=n()) %>%
  filter(count>1)  %>%
  arrange(desc(count))
  
# See if we can find the universities with the max population for each
# From the HIFLD data, we have POPULATION, FT_ENROLL and TOT_ENROLL
# We also have C18SZSET from the hd2020 data if POPULATION is missing
resolvedMULTICOUNTY <-
  resolvedFIPS %>%
  mutate(TOT_ENROLL = ifelse(TOT_ENROLL<0, NA, TOT_ENROLL),
         FT_ENROLL = ifelse(FT_ENROLL<0, NA, FT_ENROLL),
         POPULATION = ifelse(POPULATION<0, NA, POPULATION))

summary(resolvedMULTICOUNTY$TOT_ENROLL)

# indices of the schools that have missing populations
# (just showing that the same schools have missingness across all HIFLD variables)
rbind(which(is.na(resolvedMULTICOUNTY$POPULATION)),
      which(is.na(resolvedMULTICOUNTY$TOT_ENROLL)),
      which(is.na(resolvedMULTICOUNTY$FT_ENROLL)))

noPopIdx <-which(is.na(resolvedMULTICOUNTY$POPULATION))
noPopSchools <- resolvedMULTICOUNTY$UNITID[noPopIdx]

# Unfortunately the C18SZSET variable is missing for all of these schools
# (-2 is a missing value)
resolvedMULTICOUNTY$C18SZSET[noPopIdx]
# I don't want to use LOCALE or any other population estimates that are based on the city the school is in
# because a rural area can have a university with a dense student body and vice versa
# So, we'll just leave these values as missing and exclude them from comparisons
# If I had more time I could do a lot more data wrangling and impute some of these missing values

resolvedMULTICOUNTY <-
  resolvedMULTICOUNTY %>%
  group_by(COUNTYFIPS) %>%
  slice_max(order_by=TOT_ENROLL)

######## 4/24/22 ###########################
# While verifying the data I noticed that the following schools made it into the sample that shouldn't have
# because they are not in our desired population
wrongSchools <- c("Ohio State University-Newark Campus") # not a year, only do up to 3 years: https://newark.osu.edu/academics/degrees-at-newark/
wrongIPSEDID <- c(204705)
resolvedMULTICOUNTY <- resolvedMULTICOUNTY[-which(204705 == resolvedMULTICOUNTY$UNITID),]

########################################
  
# Now we only have one school per county for  4-year institutions that enroll undergraduates full time
saveRDS(resolvedMULTICOUNTY, "./Data/cleanSchools")
fwrite(resolvedMULTICOUNTY, "./Data/cleanSchools.csv")
  
  
  
  
  