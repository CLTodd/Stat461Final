# Description of the files in this directory

* *ic2020.xlsx*: Documentation ("Dictionary") for the variabbles in *ic2020.csv* (in Data directory of this repo), data from the 2020 Integrated Postsecondary Education Data System's (IPEDS) 
survey on Educational offerings, organization, services and athletic associations for educational institutions around the country. 
Downloaded from [nces.ed.gov](https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx?year=2020&surveyNumber=1) 
(click the "Dictionary" link in row that has the "IC2020" data file to get a zip file containing this excel sheet).

* *hd2020.xlsx*: Documentation ("Dictionary") for the variabbles in *hd2020.csv* (in Data directory of this repo), data from the 2020 Integrated Postsecondary Education Data System's (IPEDS) 
survey on directory information for educational institutions around the country. Downloaded from [nces.ed.gov](https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx?year=2020&surveyNumber=1) 
(click the "Dictionary" link in row that has the "HD2020" data file to get a zip file containing this excel sheet).

# Important note!

If you're trying to clone this repo and repeat this study on your local machine, you'll need to download the [historical CDC data](https://data.cdc.gov/Public-Health-Surveillance/United-States-COVID-19-County-Level-of-Community-T/nra9-vzzn) directly. It was too large to put it in this repo. Even if the CDC data gets updated with new covid data as stime goes on, the Scripts/cleaningCovid.R script will filter out the irrelavant time periods.
