# 6_predict_paleofire.R -------------------------------------------------------------
# R version: Fire Safety (3.2.2, Released 2015-08-14)
# Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
#
# Make predictions for the 30-yr probability of fire occurrence for overlapping thirty
# year periods from 850-1850. Use the previously organized explanatory variable data
# tables (made via "5_make_paleo_dataframe.R") to inform and make these paleofire 
# predictions. Export these predictions as CSV files to be imported into MATLAB where   
# the relative prediction errors will be calculated. Here, there are 7 sets of 
# predictions for each GCM, each characterizing the predictions under different 
# sensitivity analyses. See Young et al. (In Press) for more details regarding 
# these different sensitivity analyses.
#
#     (1) "Original" - No modifications made to the fire-temperature relationship.
#     (2) "Shape1" - A 5% increase in fire occurrences is added to the dataset to 
#                    modify the fire-temperature relationship.
#     (3) "Shape2" - A 10% increase in fire occurrences is added to the dataset to 
#                    modify the fire-temperature relationship.
#     (4) "Shape3" - A 25% increase in fire occurrences is added to the dataset to 
#                    modify the fire-temperature relationship.
#     (5) "T1" - The location of the 13.4 C threshold is decreased by 0.5 deg. C.
#     (6) "T2" - The location of the 13.4 C threshold is decreased by 1.0 deg. C.
#     (7) "T3" - The location of the 13.4 C threshold is decreased by 1.5 deg. C.
#        
# FILE REQUIREMENTS:
#
#   (1) RData files containing the brt models generated from the script 
#       "4_brt_training.R". These files are located in "..\results\4_brt_models\"
#
#   (2) Data tables containing explanatory variables to inform brt models and make 
#       predictions for past millennium. These files are located in 
#       "..\results\5_brt_paleofire_predictions\explanatory_variable_dataframes\"
#
# DEPENDENCIES:
#   * gbm package (version 2.1.1, Date/Publication: 2015-03-11)
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
save_dir <- "results/5_brt_paleofire_predictions/predictions"

################# LOAD REQUIRED PACKAGES AND DATASETS ###############################
require(gbm) # GENERALIZED BOOSTED REGRESSION MODEL

setwd(sprintf("%s/results/5_brt_paleofire_predictions/explanatory_variable_dataframes/",wdir))
tr   <- as.matrix(read.table("TR_1950-2009.csv",header = TRUE,sep = ",",row.names = 1))
veg  <- as.matrix(read.table("veg_1950-2009.csv",header = TRUE,sep = ",",row.names = 1))

################### INITIALIZE AND DECLARE VALUES FOR ANALYSIS ######################
gcms <- c("GISS-E2-R","MPI-ESM-P","MRI-CGCM3")
years <- 850:1820

tempvals         <- c(0.00,0.50,1.00,1.50)
tempchange_names <- c("Original","T1","T2","T3")
shape_names      <- c("Original","Shape1","Shape2","Shape3")

nmodels <- 100

# ORGANIZE TR AND veg DATA INTO MATRICES THE SAME SIZE AS THE CLIMATE DATA TABLES.
tr  <- matrix(rep(tr,length(years)),nrow=length(years),ncol=length(tr),byrow=TRUE)
veg <- matrix(rep(veg,length(years)),nrow=length(years),ncol=length(veg),byrow=TRUE)


################### MAKE PREDICTIONS FOR PAST MILLENNIUM ############################
for (g in 1:length(gcms)){ # For each gcm ...
  
  gcm_g <- gcms[g] # Set the current gcm as a character string variable
  
  # READ IN CLIMATE DATA TABLES FOR TempWarm AND PAnn.
  setwd(sprintf("%s/results/5_brt_paleofire_predictions/explanatory_variable_dataframes/",wdir))
  twrm <- as.matrix(read.table(sprintf("TempWarm_%s_0850-1850.csv",gcm_g),
                               header = TRUE,sep = ",",row.names=1))
  pann <- as.matrix(read.table(sprintf("PAnn_%s_0850-1850.csv",gcm_g),
                               header = TRUE,sep = ",",row.names=1))
  
  # RECORD ROW NAMES AND COLUMNS OF DATA TABLE FOR EXPORTING PALEOFIRE PREDICTION
  # RESULTS
  if (g == 1){
    row_names <- rownames(twrm)
    col_names <- colnames(twrm)
  }
  
  # SET THE WORKING DIRECTORY TO THE LOCATION OF THE BRT MODELS
  setwd(sprintf("%s/results/4_brt_models/",wdir))
  
  for (t in 1:length(tempvals)){ # For each systematic change in TempWarm (part of 
                                 # the sensitivity analysis in this study) ...
    
    if (t == 1){ # If there are no temperature changes ...
      
      for (s in 1:length(shape_names)){ # Go through each of the modified relationship 
                                        # shapes (Original (i.e. no change), Shape1, 
                                        # Shape2, and Shape3) and make predictions for
                                        # each of the 100 brt models associated with 
                                        # each of these shapes.
        
        for (i in 1:nmodels){ # For each brt ...
          
          # CREATE FILE NAME IN THE FORM OF A CHARACTER STRING WHERE THE PREDICTIONS
          # WILL BE STORED (INCLUDING DIRECTORY PATH)
          savefile <- sprintf("%s/results/5_brt_paleofire_predictions/predictions/predfire_%s_%s_%i.csv",
                              wdir,shape_names[s],gcm_g,i)
          
          # LOAD THE BRT MODEL
          load(paste("brt_",shape_names[s],"_",i,".RData",sep=""))
          
          # CREATE A TEMPORARY DATA FRAME FOR THE EXPLANTORY VARIABLES
          df_i <- data.frame(TempWarm = as.vector(twrm),
                             PAnn     = as.vector(pann),
                             TR       = as.vector(tr),
                             veg      = factor(as.vector(veg)))
          
          # MAKE THE PREDICTIONS USING THE TEMPORARY DATA FRAME JUST CREATED (df_i) 
          # AND THE CURRENT BRT MODEL (brt_i)
          pred_prob_i <- predict.gbm(brt_i,
                                     newdata=df_i,
                                     n.trees=gbm.perf(brt_i,plot.it=F,method="cv"),
                                     type="response")
          
          # RE-ORGANIZE THE PREDICTED PROBABILITIES INTO A DATA TABLE FOR EXPORT
          pred_prob_i <- matrix(pred_prob_i,length(years),ncol(twrm),byrow=F)
          rownames(pred_prob_i) <- rownames(pred_prob_i,do.NULL=FALSE)
          rownames(pred_prob_i) <- row_names
          colnames(pred_prob_i) <- col_names
          
          # EXPORT PREDICTIONS AS A CSV FILE
          write.csv(x=pred_prob_i,file=savefile)
          
        }
        
      }
      
    } else if (t > 1) { # If there is a change in the temperature threshold 
                        # location  ...
      
      twrm_t <- twrm + tempvals[t] # Add that change to the current TempWarm values. 
                                   # Save these modified values as 'twrm_t'
      
      for (i in 1:nmodels){ # Then for each brt model make the predictions for the 
                            # past millennium.

          # CREATE FILE NAME IN THE FORM OF A CHARACTER STRING WHERE THE PREDICTIONS
          # WILL BE STORED                
          savefile <- sprintf("%s/results/5_brt_paleofire_predictions/predictions/predfire_%s_%s_%i.csv",
                              wdir,tempchange_names[t],gcm_g,i) 

          # LOAD THE BRT MODEL        
          load(paste("brt_Original_",i,".RData",sep=""))
        
          # CREATE A TEMPORARY DATA FRAME FOR THE EXPLANTORY VARIABLES
          df_i <- data.frame(TempWarm = as.vector(twrm_t),
                             PAnn     = as.vector(pann),
                             TR       = as.vector(tr),
                             veg      = factor(as.vector(veg)))
          
          # MAKE THE PREDICTIONS USING THE TEMPORARY DATA FRAME JUST CREATED (df_i) 
          # AND THE CURRENT BRT MODEL (brt_i)           
          pred_prob_i <- predict.gbm(brt_i,
                                     newdata=df_i,
                                     n.trees=gbm.perf(brt_i,plot.it=F,method="cv"),
                                     type="response")
        
          # RE-ORGANIZE THE PREDICTED PROBABILITIES INTO A DATA TABLE FOR EXPORT
          pred_prob_i <- matrix(pred_prob_i,length(years),ncol(twrm),byrow=F)
          rownames(pred_prob_i) <- rownames(pred_prob_i,do.NULL=FALSE)
          rownames(pred_prob_i) <- row_names
          colnames(pred_prob_i) <- col_names

          # EXPORT PREDICTIONS AS A CSV FILE
          write.csv(x=pred_prob_i,file=savefile)
        
      }
      
    }
    
  }
  
}

# END OF SCRIPT ---------------------------------------------------------------------