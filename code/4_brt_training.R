# 4_brt_training.R ------------------------------------------------------------------
# R version: Fire Safety (3.2.2, Released 2015-08-14)
# Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
#
# Train boosted regression tree (brt) models to predict the 30-yr probability of fire
# occurrence using mean temperature of the warmest month (TempWarm), total annual 
# precipitation (PAnn), topographic ruggedness (TR), and vegetation type (veg). There
# are four sets of models trained in this script:
#     (1) "Original" - No added fires to modify the shape of the fire-temperatue 
#                      relationship.
#     (2) "Shape1"   - A 5% increase in fire occurrences is added to the dataset to 
#                      modify the fire-temperature relationship.
#     (3) "Shape3"   - A 10% increase in fire occurrences is added to the dataset to 
#                      modify the fire-temperature relationship.
#     (4) "Shape4"   - A 25% increase in fire occurrences is added to the dataset to 
#                      modify the fire-temperature relationship.
#
# Overall, the training of these BRTs is very similar to that used in 
# Young et al. (2017), except that in this analysis the models are trained using Mean
# total annual precipitation (PAnn) instead of Mean Total Annual P-PET. See Young et 
# al. (2017, Ecography) and Young et al. (In Press, GEB) for more details.
# 
# FILE REQUIREMENTS:
#   (1) Climatologies of training data from 1950-2009. For this training data we used  
#       the same downscaled climate data set used in Young et al. (2017). Specifically,
#       this was the downscaled dataset from the Scenarios Network for Alaska and 
#       Arctic Planning. Citation provided in the README-code.txt file. Details on
#       how training data were sampled are described in Young et al. (2017). These 
#       data are located in "..\data\brt_training_data\"
#
#   (2) Vegetation and Topographic data used as explanatory variables and to help
#       generate spatial masks of the study area. Located in "..\data\vegetation_topography_data\"
#       These include the following files:
#           * AK_VEG.tif 
#           * TR.tif
#           * ecor.tif
#
# DEPENDENCIES:
#   * gbm package (version 2.1.1, Date/Publication: 2015-03-11)
#   * raster package (version 2.5.8, Date/Publication: 2016-06-02)
#   * R.utils (version 2.2.0, Date/Publication: 2015-12-11)
#
# CITATION:
# Young AM, Higuera PE, Abatzoglou JT, Duffy PA, Hu FS. Consequences of climatic 
#   thresholds for projecting fire activity and ecological change. Global Ecology and 
#   Biogeography. 2019;00:1–12. https://doi.org/10.1111/geb.12872
#
# Created by: Adam Young
# Created on: May 2016
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
# SET MAIN WORKING DIRECTORY 
wdir <- "H:/Young-et-al_2018_Global-Ecology-and-Biogeography"
save_directory <- paste(wdir,"/results/4_brt_models/",sep="")
  
################# LOAD REQUIRED PACKAGES AND DATASETS ###############################
require(gbm)     # GENERALIZED BOOSTED REGRESSION MODEL
require(raster)  # GEOGRAPHIC DATA ANALYSIS AND MODELLING
require(rgdal)
require(R.utils)

#LOAD VEGETATION, ECOREGION, AND TOPOGRAPHIC SPATIAL DATA AS VECTORS USING THE
# raster() AND getValues() FUNCTIONS FROM THE raster PACKAGE.
setwd(paste(wdir,"/data/ancillary_data",sep = ""))
mapInfo <- raster("AK_VEG.tif") # GEOGRAPHIC INFORMATION NEEDED FOR EXPORTING GEOTIFF
# FILES
akVeg   <- getValues(mapInfo) # [categorical, 1-5] EXPLANATORY VARIABLE
TR      <- getValues(raster("TR.tif")) # [meters] EXPLANATORY VARIABLE
ecor    <- getValues(raster("ecor.tif")) # [categorical, 1-22]. USED TO MASK OUT
                                         # UNWANTED REGIONS FROM STUDY AREA

# CLASSIFY PIXELS NOT IN STUDY AREA AS 'NA' VALUES
ecor[ecor == -9999] <- NA
akVeg[(akVeg == -9999 | is.na(ecor) == TRUE)] <- NA

####### IMPORT GEO-REFERENCE LOCATIONS FOR EACH PALEOFIRE SITE ######################
# THIS IS NEEDED TO GENERATE HISTORICAL PREDICTIONS FOR THESE GRID CELLS USING THE 
# UN-MODIFIED (I.E., "Original") BRT MODEL, WHICH ARE LATER USED IN FIGURE 4. 

# COORDINATE REFERENCES STRING IN PROJ.4 LIBRARY FORMAT. NEEDED FOR FORWARD PROJECTION
# OF LAT/LONG INTO METERS EASTING AND NORTHING FOR PALEOFIRE LOCATIONS. 
# EQUAL TO "+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0" 
crs <- as.character(mapInfo@crs) 

# IMPORT PALEOFIRE METADATA. CONTAINS NEEDED SITE CODES AND LAT/LONG VALUES FOR
# LOCATIONS.
paleofire_metadata <- read.csv(paste(wdir,"/data/paleofire_metadata.csv",sep=""),
                               header = TRUE)

longlat <- cbind(paleofire_metadata$lon_dd,paleofire_metadata$lat_dd) #LAT/LONG VALUES

xy <- project(xy = longlat,proj = crs,inv = FALSE) # FORWARD PROJECTION FROM LAT/LONG
                                                   # TO METERS EASTING AND NORTHING 

# EXTRACT THE LINEAR INDEX VALUE FOR THE RASTER CELLS THAT CONTAIN THE PALEOFIRE 
# LOCATIONS. THIS WILL BE A VECTOR OF LENGTH 29 (NUMBER OF PALEOFIRE SITES).
cell_idx <- raster::extract(mapInfo,xy,cellnumbers=T)[,1]

################### INITIALIZE AND DECLARE VALUES FOR ANALYSIS ######################
nmodels <- 100 # NUMBER OF MODELS TO RUN
nobs    <- 8930 # NUMBER OF PIXELS TO RANDOMLY SELECT FROM STUDY DOMAIN TO CONDUCT
                # ANALYSIS. BASED ON ANALYSIS FROM Young et al. 2017. Ecography.

# META-PARAMETERS FOR RUNNING BOOSTED REGRESSION TREE MODELS
n_trees           <- 5000 # NUMBER OF TREES
shrinkage         <- 0.01 # LEARNING RATE (SAME AS SHRINKAGE)
interaction_depth <- 2 # NUMBER OF PAIRWISE INTERACTIONS PER TREE
bag_fraction      <- 0.5 # BAGGING FRACTION
train_frac        <- 1.0 # TRAINING FRACTION
n_minobsinnode    <- 1 # MINIMUM NUMBER OF OBSERVATIONS ALLOWED IN EACH TREE NODE 
cv_folds          <- 5 # NUMBER OF CROSS VALIDATION PARTITIONS
verbose           <- FALSE # REPORT BOOSTED REGRESSION TREE PROGRESS TO COMMAND PROMPT?

############ PARAMETERS FOR MODIFYING THE FIRE-TEMPERATURE RELATIONSHIP #############
t_thresh_lims <- c(7,15) # TEMPERATURE RANGE OVER WHICH TO MODIFY FIRE-TEMPERTURE
                         # RELATIONSHIP [deg. Celsius]
pct <- c(0.00,0.05,0.10,0.25) # PROPORTION OF FIRES TO ADD TO FOR EACH SHAPE
shape_names <- c("Original","Shape1","Shape2","Shape3") # NAME OF MODIFIED RELATIONSHIP
                                                        # SHAPE
shapevals <- c(3,1) # PARAMETER VALUES FOR BETA DENSITY

################### RUN BOOSTED REGRESSION TREE ANALYSIS ############################

for (p in 1:length(pct)){
  
  # IF WE ARE TRAINING THE "Original" BRT (I.E. NO SHAPE MODIFICATIONS IN THE FIRE-
  # TEMPERATURE RELATIONSHIP), THEN ALLOCATED SPACE TO STORE PREDICTIONS FOR THE
  # HISTORICAL PERIOD (1950-2009) BASED ON THE TRAINING DATA. TRAINING DATA IS
  # GENERATED BELOW. THESE PREDICTIONS ARE USED TO EVALUATE THE MODEL PERFORMANCE IN
  # EACH ECOREGION FOR THE HISTORICAL PERIOD, WHICH IS THEN COMPARED TO 
  if (p == 1){
    pred_hist = matrix(NA,nrow(paleofire_metadata),nmodels);
  }
  
  for (i in 1:nmodels){
    
    # SET SEED FOR REPRODUCIBILITY
    set.seed(i)
    
    # CHANGE DIRECTORY TO WHERE TRAINING/TESTING DATA ARE STORED
    setwd(sprintf("%s//data//brt_training_data//",wdir))
    
    # LOAD TRAINING DATA
    # LOAD FIRE FREQUENCY DATA
    fire <- getValues(raster(paste("train_firefreq_",i,".tif",sep = "")))
    fire[fire > 0] <- 1 # IF FIRE FREQUENCY IS GRETATER THAN 0, SET EQUAL TO 1. THIS WILL
                        # CREATE A PRESENCE ABSENCE MAP OF FIRE IN ALASKA.
    
    # MEAN TEMPERATURE OF THE WARMEST MONTH
    TempWarm <- getValues(raster(paste("train_TempWarm_",i,".tif",sep = ""))) # [degrees C]
    TempWarm[TempWarm == -9999] <- NA # SET MISSING VALUES AS 'NA'
    
    # TOTAL ANNUAL PRECIPITATION
    PAnn <- getValues(raster(paste("train_PAnn_",i,".tif",sep = ""))) # [mm]
    PAnn[PAnn == -9999] <- NA # SET MISSING VALUES AS 'NA'
    
    # CREATE DATA FRAME FOR TRAINING DATA
    train_data <- data.frame(fire     = fire,
                             TempWarm = TempWarm,
                             PAnn     = PAnn,
                             TR       = TR,
                             veg      = factor(akVeg))
    
    all_train_data <- train_data
    
    # COMPLETE CASES AND REMOVE 'NA' OBSERVATIONS FROM DATA FRAMES
    train_data <- train_data[complete.cases(train_data$veg), ]
    
    #********************************************************************************
    # MODIFY SHAPE OF FIRE-TEMPERATURE RELATIONSHIP BY ADDING "PSEUDO" FIRES TO THE 
    # DATASET BETWEEN 7-15 deg. C. 
    
    n_add <- round(sum(train_data$fire)*pct[p]) # NUMBER OF FIRES TO ADD, BASED ON 
                                                # PERCENTAGE VALUE.
    
    # FIND ROWS WHERE TempWarm is between 7 AND 15 deg. C.
    t_thresh_idx <- which((train_data$TempWarm > t_thresh_lims[1] 
                           & train_data$TempWarm <= t_thresh_lims[2]) 
                           & train_data$fire==0)
    
    t_range <- abs(diff(t_thresh_lims)) # RANGE OF TEMPERATURE VALUES 
    # NORMALIZE TEMPERATURE VALUES TO [0,1] SCALE
    t_warm_vals <- sort.int((train_data$TempWarm[t_thresh_idx] - t_thresh_lims[1])/t_range,index.return=TRUE)
    
    # ASSIGN BETA DENSITY VALUE TO EACH RE-SCALED TEMPERATURE VALUE AND MAKE SURE IT 
    # INTEGRATES TO 1. THIS IS NOW A PROBABILITY VALUE ASSIGNED TO EACH OBSERVATION
    #  BETWEEN 7 AND 15 deg. C.
    
    dbeta_density_values <- dbeta(t_warm_vals$x,shapevals[1],shapevals[2])
    sum_dbeta <- sum(dbeta(t_warm_vals$x,shapevals[1],shapevals[2])) 
    
    probs <- dbeta_density_values/sum_dbeta
    
    # SELECT THE PRE-DESIGNATED NUMBER OF OBSERVATIONS TO "SWITCH" A FIRE ABSENCE [0]  
    # TO A FIRE PRESENCE [1] USING THE sample FUNCTION. THE PROBABILITY OF SELECTING 
    # A GIVEN ROW ARE THE PROBABILITY VALUES CALCULATED IMMEDIATELY ABOVE.
    t_train_idx <- sample(t_thresh_idx[t_warm_vals$ix],
                          size = n_add,
                          replace = FALSE,
                          prob = probs)
    
    # SET THESE RANDOMLY SELECTED 0 VALUES TO 1
    train_data$fire[t_train_idx] <- 1
    # *******************************************************************************
    
    # RANDOMLY SELECT PIXELS (POINTS) FOR TRAINING BRTS
    pts_train <- sample(x = 1:nrow(train_data),size = nobs,replace = FALSE)
    
    # *******************************************************************************
    # THE SAMPLING IMMEDIATELY BELOW IS NEEDED TO ENSURE REPRODUCIBILITY OF THE BRTS
    # BASED ON THE RANDOM SEED SET. THIS IS AN ARTIFACT OF THE ORIGINAL SCRIPT USED 
    # TO TRAIN THESE MODELS, WHICH ALSO GENERATED A RANDOM SAMPLE OF TEST/VALIDATION 
    # DATA POINTS, BUT NOT NEEDED IN THIS SCRIPT.
    nuisance_sample <- sample(x = 1:nrow(train_data),size = nobs,replace = FALSE)
    rm(list="nuisance_sample")
    # *******************************************************************************

    # CREATE DATA FRAMES FOR TRAINING DATASET THAT WILL BE USED TO CREATE 
    # BRT.
    FINAL_train_data <- train_data[pts_train,]

    # CONSTRUCT BOOSTED REGRESSION TREE MODEL FROM TRAINING DATASET
    # THIS USES gbm VERSTION 2.1.1. META-PARAMETER VALUES FOR RUNNING BRT CAN BE 
    # FOUND IN INITIALIZATION SECTION OF SCRIPT (ABOVE).
    brt_i <- gbm(fire ~ TempWarm + PAnn + TR + veg, # MODEL FORMULA
                 data              = FINAL_train_data, # DATASET TO USE
                 var.monotone      = NULL, # NO MONONTONICITY RESTRICTIONS
                 distribution      = "bernoulli", # BERNOULLI DISTRIBUTION FOR RESPONSE
                 n.trees           = n_trees, # MAXIMUM NUMBER OF TREES TO TRAIN MODEL
                 shrinkage         = shrinkage, # REGULARIZATION PARAMETER
                 interaction.depth = interaction_depth, # TWO-WAY INTERACTIONS
                 bag.fraction      = bag_fraction, # SUBSAMPLING FRACTION IN EACH ITERATION
                 train.frac        = train_frac, # FRACTION OF SUPPLIED DATA TO USE IN BRT TRAINING
                 n.minobsinnode    = n_minobsinnode, # MINIMUM NUMBER OF OBSERVATIONS
                 cv.folds          = cv_folds, # USE 5-FOLD CROSS VALIDATION
                 verbose           = verbose, # PRINT PROGRESS TO SCREEN? [YES/NO]
                 keep.data         = FALSE) # STORE TRAINING DATA IN GBM RDATA FILE
    
    # CHANGE CURRENT DIRECTORY TO THE DIRECTORY WHERE THE BRT RDATA FILE WILL BE SAVED
    setwd(save_directory)
    
    # IF WE ARE NOT MODIFYING THE SHAPE OF THE RELATIONSHIP, ALSO RECORD THE PREDICTED
    # VALUES FROM THE "Original" BRT MODEL FOR 1950-2009 USING TRAINING DATASET.
    if (p == 1){
      
      # IDENTIFY OPTIMAL NUMBER OF REGRESSION TREES (ITERATIONS) FOR iTH BRT USING THE
      # CV VALIDATION METHOD
      best_iter <- gbm.perf(brt_i,
                            method  = "cv",
                            plot.it = verbose)
      
      # CREATE PREDICTION MAP OF PROBABILITES FOR THE GRID CELLS WHERE EACH PALEOFIRE
      # SITE IN ALASKA IS LOCATED
      pred_hist[,i]  <- predict(object  = brt_i,
                                newdata = all_train_data[cell_idx,],
                                n.trees = best_iter,
                                type    = "response")
      
    }
    
    # SAVE BRT AS A RDATA FILE
    save(brt_i,file = paste("brt_",shape_names[p],"_",i,".RData",sep = ""))

  }
  
  # EXPORT THE TABLE OF PREDICTED PROBABILITIES FOR THE HISTORICAL PERIOD
  if (p == 1){
    colnames(pred_hist) <- paste(rep("brt_",100),as.character(1:100),sep="")
    write.csv(x = pred_hist,paste(wdir,"/results/4_brt_models/historical_predictions_paleosites_1950-2009.csv",sep=""),row.names = paleofire_metadata$code)
  }
  
}
# END OF SCRIPT ---------------------------------------------------------------------