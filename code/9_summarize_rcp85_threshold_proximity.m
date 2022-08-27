% 9_summarize_rcp85_threshold_proximity.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% This code reads in climatological maps for Alaska for four different time 
% periods and classifies each pixel as "Below", "Near", or "Above" the 
% temperature threshoold to burnign (13.4 deg. Celsius). These 
% classifications are then summarized as proportions of total area in each 
% of these three classes. The data are then exported as a .mat file and 
% imported to make Figure 5. The future temperature projections are uncer
% emissions scenario RCP 8.5.
%
% FILE REQUIREMENTS:
%    (1) geotifInfo_AK_mainland.mat - Geographic and projection information
%    for study area in mainland alaska. Located in
%    '..\data\ancillary_data\'
%
%    (2) AK_VEG.tif - Vegetation classification map of study area, used to
%    define spatial mask of study area. Located in
%    '..\data\ancillary_data\'
%
%    (3) TempWarm climatologies for the historical and future time periods.
%    These data are located in
%    '..\results\3_gcm_30yr_climatologies\used_in_analysis\[GCM]\[EXPERIMENT]\'
%    
% DEPENDENCIES:
%   * MATLAB Mapping Toolbox
%   * MATLAB Statistics and Machine Learning Toolbox
%
% CITATION:
% Young AM, Higuera PE, Abatzoglou JT, Duffy PA, Hu FS. Consequences of climatic 
%   thresholds for projecting fire activity and ecological change. Global Ecology and 
%   Biogeography. 2019;00:1?12. https://doi.org/10.1111/geb.12872
%
% Created by: Adam Young
% Created on: December 2016
% Edited for publication: November 2018
%
% Contact information:
%   Adam M. Young, Ph.D.
%          email: Adam.Young[at]nau.edu
%          ORCID: http://orcid.org/0000-0003-2668-2794
%   Philip E. Higuera, Ph.D.
%          email: philip.higuera[at]umontana.edu
%          ORCID: https://orcid.org/0000-0001-5396-9956

% INITIALIZE WORKSPACE ****************************************************
clear all; % clear workspace of variables
clc; % clear command prompt
close all; % close all current figure windows

% WORKING DIRECTORY - ***NEEDS TO BE ALTERED BY USER***
wdir = 'H:\Young-et-al_2018_Global-Ecology-and-Biogeography';

% IMPORT DATA AND INITIALIZE VARIABLES ************************************

% LOAD IN GEOTIFF INFORMATION AND THE VEGETATION MAP FOR ALASKA
if ispc
   cd([wdir,'\data\ancillary_data']);
else
   cd([wdir,'/data/ancillary_data']);
end

load('geotifInfo_AK_mainland_ak83alb.mat');
akmask = geotiffread('AK_VEG.tif');

% USING THE VEGETATION MAP, CREATE A SPATIAL MASK OF THE STUDY AREA FOR
% THIS STUDY (NaN = Not in study area, 1 = in study area).
akmask(akmask==-9999) = NaN;
akmask(isnan(akmask)==false) = 1;

% GET X AND Y COORDINATES (METERS EASTING AND NORTHING FOR MAP OF ALASKA.
% ATTACHED TO EXPORTED .mat FILE AS A FORM OF METADATA.
x_res = geotifInfo_AK_mainland.RefMatrix(2);
y_res = geotifInfo_AK_mainland.RefMatrix(4);
x_coord_values = ((geotifInfo_AK_mainland.BoundingBox(1)+x_res/2): ...
                   x_res:(geotifInfo_AK_mainland.BoundingBox(2)-x_res/2));
y_coord_values = ((geotifInfo_AK_mainland.BoundingBox(4)+y_res/2): ...
                   y_res:(geotifInfo_AK_mainland.BoundingBox(3)-y_res/2))';

% COUNT NUMBER OF PIXELS/CELLS IN STUDY AREA               
ncells_in_mask = nansum(akmask(:));

% INITIALIZE VARIABLES AND VARIABLE LABELS FOR ANALYSIS
gcms = {'GISS-E2-R','MPI-ESM-LR','MRI-CGCM3'};
climatologies_to_plot = {'1971 - 2000','2010 - 2039','2040 - 2069','2070 - 2099'};
experiments_for_each_climatology = {'historical','rcp85','rcp85','rcp85'};
threshold_proximity_labels = {'Below Threshold','Near Threshold','Above Threshold'};

% NUMBER OF SIMULATIONS TO RUN
nsim = 100;

% TEMPERATURE THRESHOLD QUANTIFIED IN YOUNG ET AL. (2017) ECOGRAPHY
twrm_threshold = 13.4; % [deg. Celsius]

% ALLOCATE SPACE TO STORE CLASSIFICATION MAPS AND PROPORTION VALUES FOR
% EACH CLASS.
threshold_prox_classify = NaN(geotifInfo_AK_mainland.Height,...
                              geotifInfo_AK_mainland.Width, ...
                              length(gcms), ...
                              length(climatologies_to_plot));                       
simulated_proportions = NaN(nsim, ...
                            length(threshold_proximity_labels), ...
                            length(gcms), ...
                            length(climatologies_to_plot));
                       
% SET RANDOM SEED FOR REPRODUCIBILITY
rng(123);

% CONDUCT THRESHOLD PROXIMITY ANALYSIS ************************************

for g = 1:length(gcms) % For each gcm ...
        
    for i = 1:length(climatologies_to_plot) % For each climatological 
                                            % period ...
    
        gcm_g = char(gcms(g)); % Current gcm

        % IF GCM IS MPI-ESM-LR BUT THE CLIMATOLOGICAL PERIOD IS FROM THE 
        % historical EXPERIMENT THEN SET THE GCM TO MPI-ESM-P.
        if i == 1 & g == 2
            gcm_g = 'MPI-ESM-P';
        end
        
        % CURRENT EXPERIMENT FOR THE CLIMATOLOGICAL TIME PERIOD
        experiment_i = char(experiments_for_each_climatology(i));
        
        % GET CLIMATOLOGY START AND END YEARS
        climatology_i = char(climatologies_to_plot(i));
        yr_start = str2double(climatology_i(1:4)); 
        yr_end = str2double(climatology_i(8:11));
        
        % IMPORT TempWarm MAPS FOR THE GIVEN GCM, TIME PERIOD, AND
        % EXPERIMENT
        if ispc
            cd(sprintf('%s\\results\\3_gcm_30yr_climatologies\\used_in_analysis\\%s\\%s', ...
                       wdir,gcm_g,experiment_i));
        else
            cd(sprintf('%s//results//3_gcm_30yr_climatologies//used_in_analysis//%s//%s', ...
                       wdir,gcm_g,experiment_i));            
        end
        
        twrm_i = geotiffread(sprintf('TempWarm_%s_%i_%i.tif', ...
                             gcm_g,yr_start,yr_end));
        
        % REMOVE VALUES FROM TempWarm MAP NOT IN STUDY AREA                 
        twrm_i = twrm_i.*akmask;
        
        % ALLOCATE TEMPORARY SPACE FOR THE CLASSIFICATION VALUE MAPS AND
        % THE CALCULATED PROPORTION VALUES
        classification_values_i = zeros(size(twrm_i));
        proportion_values_per_class_i = NaN(nsim,length(threshold_proximity_labels));
        
        for b = 1:nsim % For each simulation ...
            
            % GENERATE TWO RANDOM DRAWS FROM A UNIFORM PROBABILITY
            % DISTRIBUTION (PARAMETERS: [A=-1, B=1])
            uniform_dist_draws = unifrnd(-1,1,2,1);
            
            % SIMULATED LOWER AND UPPER THRESHOLDS THAT DEFINE THE THREE
            % CLASSES BASED ON THIS S
            low_thr = (twrm_threshold - 2) + uniform_dist_draws(1);
            upp_thr = (twrm_threshold + 2) + uniform_dist_draws(2);
            
            % CLASSIFY PROXIMITY TO TEMPERATURE THRESHOLD FOR EACH PIXEL IN
            % STUDY AREA IN ALASKA
            threshold_prox_i = NaN(size(twrm_i)); % Empty grid to store 
                                                  % classification values
            threshold_prox_i(twrm_i>=low_thr & ...
                                      twrm_i<upp_thr) = 0; % Near threshold
            threshold_prox_i(twrm_i<low_thr) = -1; % Below threshold
            threshold_prox_i(twrm_i>=upp_thr) = 1; % Above threshold
            
            % SUMMATION OF CLASSIFICATION MAPS OVER THE 100 SIMULATIONS
            if b == 1
                classification_values_i = threshold_prox_i;
            elseif b > 1
                classification_values_i = ...
                    sum(cat(3,classification_values_i,threshold_prox_i),3);
            end
            
            % CALCULATE PROPORTION OF STUDY AREA IN EACH CLASS FOR EACH
            % SIMULATION
            proportion_values_per_class_i(b,1) = ...
                nansum(nansum(threshold_prox_i==-1))./ncells_in_mask;
            proportion_values_per_class_i(b,2) = ...
                nansum(nansum(threshold_prox_i==0))./ncells_in_mask;
            proportion_values_per_class_i(b,3) = ...
                nansum(nansum(threshold_prox_i==1))./ncells_in_mask;
            
        end
        
        % SUMMARIZE CLASSIFICATION MAPS ACROSS SIMULATIONS. THIS INVOLVES
        % TAKING THE AVERAGE BY DIVIDING BY THE NUMBER OF SIMULATIONS, THEN
        % ROUNDING THIS AVERAGE TO DETERMINE THE CLASSIFICATION OF EACH
        % GRID CELL AS ONE OF THE THREE CLASSES (BELOW, NEAR, OR ABOVE).
        threshold_prox_classify(:,:,g,i) = round(classification_values_i/nsim);
        
        % FILL IN PRE-ALLOCATED SPACE FOR PROPORTIONS FOR EACH SIMUALTION,
        % GCM, AND, TIME PERIOD
        simulated_proportions(:,:,g,i) = proportion_values_per_class_i;
        
    end
end

% GENERATE STRUCTURE OF DATA TO BE EXPORTED *******************************

threshold_proximity_results = struct;
threshold_proximity_results.threshold_proximity_maps = struct;
threshold_proximity_results.summarized_proportions = struct;

threshold_proximity_results.threshold_proximity_maps.array_dimensions = ...
    '(meters_northing, meters_easting,  gcms, climatology_timeperiod)';
threshold_proximity_results.threshold_proximity_maps.dim1 = y_coord_values;
threshold_proximity_results.threshold_proximity_maps.dim2 = x_coord_values;
threshold_proximity_results.threshold_proximity_maps.dim3 = gcms;
threshold_proximity_results.threshold_proximity_maps.dim4 = climatologies_to_plot;
threshold_proximity_results.threshold_proximity_maps.classification_values = ...
    threshold_prox_classify;
threshold_proximity_results.threshold_proximity_maps.units = ...
    '(-1=Below Threshold, 0=Near Threshold, 1=Above Threshold)';

threshold_proximity_results.summarized_proportions.array_dimensions = ...
    '(simulation, classification, gcms, climatology_timeperiod)';
threshold_proximity_results.summarized_proportions.dim1 = (1:100)';
threshold_proximity_results.summarized_proportions.dim2 = ...
    threshold_proximity_labels;
threshold_proximity_results.summarized_proportions.dim3 = gcms;
threshold_proximity_results.summarized_proportions.dim4 = climatologies_to_plot;
threshold_proximity_results.summarized_proportions.simulated_proportions = ...
    simulated_proportions;

% EXPORT SUMMARIZED RCP8.5 DATA TO CREATE FIGURE 5 ************************

if ispc
   cd([wdir,'\results\6_rcp85_proximity_results']); 
else
   cd([wdir,'/results/6_rcp85_proximity_results']); 
end
save('threshold_proximity_results.mat','threshold_proximity_results');

% END OF SCRIPT -----------------------------------------------------------