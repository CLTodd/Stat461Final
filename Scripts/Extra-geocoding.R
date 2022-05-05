##################################################################################
### Candace Todd
### 5/5/2022
### GOAL: Assign longitudes/latitudes according to the FIPS codes
##################################################################################
rm(list=ls())
library(maps)
library(mapdata)
library(data.table)
library(maptools)
library(dplyr)
library(sf)

# Getting long/lat: https://shiandy.com/post/2020/11/02/mapping-lat-long-to-fips/
shape <- read_sf(dsn = "./Data/cb_2018_us_county_5m")
shape$fips <- paste(shape$STATEFP, shape$COUNTYFP, sep="")
coords <- st_coordinates(shape)[,1:2]



usa <- map_data('usa')
ggplot(data=usa, aes(x=long, y=lat, group=group)) + 
  geom_polygon(fill='lightblue') + 
  theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank(),
        axis.title.y=element_blank(), axis.text.y=element_blank(), axis.ticks.y=element_blank()) + 
  ggtitle('U.S. Map') + 
  coord_fixed(1.3) +
  geom_point()



