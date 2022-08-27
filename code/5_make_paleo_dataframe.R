# 5_make_paleo_dataframe.R ----------------------------------------------------------
# R version: Fire Safety (3.2.2, Released 2015-08-14)
# Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
#
# Exract index values for the raster cells in a gridded map of Alaska that contain 
# the locations of the paleofire sites used in the analysis. The, using these location 
# index values, extract the data values from the following raster variables/maps: 
# TempWarm and PAnn, topographic roughness (TR), and vegetation type (veg). For the 
# two climatology variables (TempWarm and PAnn), extract the values for each 30-yr
# climatological time period from 850-1850 CE for each GCM (GISS-E2-R, MPI-ESM-P, and
# MRI-CGCM3). Finally, export these data in the form of RData files, which will
# then be used to inform the brt models generated using '4_brt_training.R' and make
# predictions for each paleofire site for the pat millennium.
# 
# FILE REQUIREMENTS:
#   (1) Climatologies of past1000 data from 850-1850. These data are located in 
#       "..\results\gcm_30yr_climatologies\used_in_analysis\[GCM]\[EXPERIMENT]\"
#
#   (2) Vegetation and Topographic explanatory variables.
#       Located in "..\data\ancillary_data\"
#       These include the following files:
#           * AK_VEG.tif 
#           * TR.tif
#
#   (3) Paleofire metadata containing site code names and latitude and longitude 
#       coordinates. Located in "..\data\paleofire_metadata.csv"
#
# DEPENDENCIES:
#   * gbm package (version 2.1.1, Date/Publication: 2015-03-11)
#   * raster package (version 2.5.8, Date/Publication: 2016-06-02)
#   * rgdal (version 1.1-1, Date/Publication: 2015-11-02)
#
# CITATION:
# Young AM, Higuera PE, Abatzoglou JT, Duffy PA, Hu FS. Consequences of climatic 
#   thresholds for projecting fire activity and ecological change. Global Ecology and 
#   Biogeography. 2019;00:1–12. https://doi.org/10.1111/geb.12872
#
# Created by: Adam Young
# Created on: June 2016
# Edited for publication: November 2018
#
# Contact information: 
#   Adam M. Young, Ph.D. 
#          email: Adam.Young[at]nau.edu
#          ORCID: http://orcid.org/0000-0003-2668-2794
#   Philip E. Higuera, Ph.D.
#          email: philip.higuera[at]umontana.edu
#          ORCID: https://orcid.org/0000-0001-5396-9956

########################### INITIALIZE WORKSPACE ###################################
rm(list = ls()) # CLEAR WORKSPACE 
graphics.off() # DELETE CURRENT GRAPHICS WINDOWS
cat("\14") # CLEAR COMMAND PROMPT

# SET PATHS FOR NEEDED DIRECTORIES 
wdir <- "H:/Young-et-al_2018_Global-Ecology-and-Biogeography"
save_dir <- "results/brt_paleofire_predictions/explanatory_variable_dataframes"

################# LOAD REQUIRED PACKAGES AND DATASETS ###############################
require(raster) # GEOGRAPHIC DATA ANALYSIS AND MODELLING
require(rgdal) # BINDINGS FOR THE GEOSPATIAL DATA ABSTRACTION LIBRARY
require(gbm) # GENERALIZED BOOSTED REGRESSION MODEL

# LOAD VEG AND TOPOGRAPHIC ROUGHNESS DATA. USED AS EXPLANATORY VARIABLES IN MODEL 
# PREDICTIONS
setwd(paste(wdir,"/data/ancillary_data/",sep=""))
akVeg <- raster("AK_VEG.tif") # VEGETATION TYPES IN ALASKA
TR    <- raster("TR.tif") # [meters] EXPLANATORY VARIABLE

akVeg[akVeg==-9999] <- NA

################### INITIALIZE AND DECLARE VALUES FOR ANALYSIS ######################
# STARTING YEARS FOR EACH 30-YR CLIMATOLOGICAL TIME PERIOD IN ANALYSIS.
# E.G., 850-879, 851-880, ...,1820-1849
years    <- 850:1820

# GCMS TO PROCESS FOR PAST MILLENNIUM
gcms     <- c("GISS-E2-R","MPI-ESM-P","MRI-CGCM3")

# COORDINATE REFERENCES STRING IN PROJ.4 LIBRARY FORMAT. NEEDED FOR FORWARD PROJECTION
# OF LAT/LONG INTO METERS EASTING AND NORTHING FOR PALEOFIRE LOCATIONS. 
# EQUAL TO "+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0" 
crs <- as.character(akVeg@crs) 

# IMPORT PALEOFIRE METADATA. CONTAINS NEEDED SITE CODES AND LAT/LONG VALUES FOR
# LOCATIONS.
paleofire_metadata <- read.csv(paste(wdir,"/data/paleofire_metadata.csv",sep=""),
                               header = TRUE)

longlat <- cbind(paleofire_metadata$lon_dd,paleofire_metadata$lat_dd) #LAT/LONG VALUES

xy <- project(xy = longlat,proj = crs,inv = FALSE) # FORWARD PROJECTION FROM LAT/LONG
                                                   # TO METERS EASTING AND NORTHING 

# EXTRACT THE LINEAR INDEX VALUE FOR THE RASTER CELLS THAT CONTAIN THE PALEOFIRE 
# LOCATIONS. THIS WILL BE A VECTOR OF LENGTH 29 (NUMBER OF PALEOFIRE SITES).
cell_idx <- extract(akVeg,xy,cellnumbers=T)[,1]

# ALLOCATE SPACE TO STORE EXTRACTED TR AND veg VALUES FOR PALEOFIRE LOCATIONS. COLUMN
# NAMES FOR THE MATRIX ARE THE INDIVIDUAL PALEOFIRE SITE CODES. NOTE, THESE TWO VARIABLES 
# ARE STATIC AND WE ARE ASSUMING THEY DO NOT CHANGE OVER TIME. THEREFORE, WE ONLY NEED
# TO STORE THESE VALUES ONCE (TIME PERIOD = 1950-2009) AND THIS TABLE WILL HAVE
# 1 ROW AND 29 COLUMNS (ONE FOR EACH PALEOFIRE SITE CODE).
tr   <- matrix(TR[cell_idx],nrow=1); colnames(tr)  <- paleofire_metadata$code
veg  <- matrix(akVeg[cell_idx],nrow = 1); colnames(veg) <- paleofire_metadata$code

# SAVE TR AND veg DATA AS CSV FILES
write.csv(x = tr,
          file = sprintf("%s/%s/TR_1950-2009.csv",wdir,save_dir),
          row.names = "1950-2009")
write.csv(x = veg,
          file = sprintf("%s/%s/veg_1950-2009.csv",wdir,save_dir),
          row.names = "1950-2009")

# CREATE AN EMPTY VECTOR OF LENGTH ZERO. WILL BE FILLED WITH CHARACTER STRINGS 
# INDICATING THE THIRTY YEAR PERIOD FOR EACH ROW OF THE TABLES STORING THE CLIMATE
# DATA FOR EACH PALEO SITE. 
climate_variable_row_names <- c()

################### CREATE AND EXPORT DATA TABLES TO INFORM BRT MODELS ##############

for (g in 1:length(gcms)){ # For each gcm ...
  
  # ALLOCATE STORAGE FOR EACH CLIMATOLOGICAL VARIABLE (PAnn AND TempWarm). ROWS ARE 
  # 971 OVERLAPPING THIRTY-YEAR PERIODS FROM 850-1850. COLUMNS ARE FOR THE 29
  # PALEOFIRE SITES. THIS STORAGE NEEDS TO BE RESET AND EXPORTED FOR EACH GCM.
  twrm <- matrix(NA,length(years),nrow(longlat)); colnames(twrm) <- paleofire_metadata$code
  pann <- matrix(NA,length(years),nrow(longlat)); colnames(pann) <- paleofire_metadata$code
  
  # SET WORKING DIRECTORY TO THE LOCATION OF THE 30-YR CLIMATOLOGIES
  setwd(paste(wdir,"/results/gcm_30yr_climatologies/used_in_analysis/",gcms[g],"/past1000",sep=""))
  
  for (y in 1:length(years)){ # For each 30-yr period ...
    
    # LOAD IN GEOTIFF DATA FILE FOR TempWarm AND PAnn. STORE AS TEMPORARY VARIABLES
    twrm_i <- raster(sprintf("TempWarm_%s_%04i_%04i.tif",gcms[g],years[y],years[y]+29))
    pann_i <- raster(sprintf("PAnn_%s_%04i_%04i.tif",gcms[g],years[y],years[y]+29))
    
    # IF WE ARE PROCESSING THE FIRST GCM THEN STORE THE CURRENT 30-YR PERIOD AS A
    # CHARACTER STRING. THESE VALUES WILL THEN BE USED TO NAME THE ROWS OF THE DATA
    # TABLES WE ARE CURRENTLY FILLING.
    if (g == 1){
      climate_variable_row_names <- c(climate_variable_row_names,paste(years[y],"-",
                                                                       years[y]+29,sep=""))
    }
    
    # FILL IN THE CURRENT ROW WITH THE EXTRACTED CLIMATOLOGICAL DATA VALUES
    twrm[y,] <- twrm_i[cell_idx]
    pann[y,] <- pann_i[cell_idx]
    
  }
  
  # ADD ROWNAMES TO DATA TABLES
  rownames(twrm) <- climate_variable_row_names  
  rownames(pann) <- climate_variable_row_names
  
  # EXPORT DATA TABLES AS CSV FILES
  write.csv(x = twrm,
            file = sprintf("%s/%s/TempWarm_%s_0850-1850.csv",wdir,save_dir,gcms[g]),
            row.names = TRUE)
  write.csv(x = pann,
            file = sprintf("%s/%s/PAnn_%s_0850-1850.csv",wdir,save_dir,gcms[g]),
            row.names = TRUE)
  
}
# END OF SCRIPT ---------------------------------------------------------------------