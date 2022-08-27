% 2_downscaling_gcms_to_2km.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% Bias-correct and downscale GCM data from native resolution to 2-km 
% spatial resolution using the delta-change method. Here, we provide only
% the code to do the downscaling for for 850-879 CE for the GISS-E2-R GCM
% for both mean monthly temperature and total monthly precipitation. 
% 
% FILE REQUIREMENTS:
%   (1) Processed GCM data from the raw GCM files. This processing
%       was done in the MATLAB script 1_organize_gcm_data.m. These
%       files are located in direrctory:
%       ..\results\1_processed_gcm_data_native_resolution\
%
%   (2) PRISM climatologies for Alaska for mean monthly temperature 
%       and total monthly precipitation. These climatologies are at
%       2-km resolution and available for each month. They can be
%       downloaded from
%       http://ckan.snap.uaf.edu/dataset/prism-1961-1990-climatologies/
%       Full citations are availble in the README-data.txt file and in the
%       Supplementary Information of the manuscript. 
%
%   (3) GeoTIFF metadata for processing and export of GCM data. These
%       files are located in directory: '..\data\ancillary_data\' and 
%       include:
%               *geotifInfo_AK_CAN_ak83alb.mat
%               *geotifInfo_AK_mainland_ak83alb.mat
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
% Created on: April 2016
% Edited for publication: November 2018
%
% Contact information:
%   Adam M. Young, Ph.D.
%          email: Adam.Young[at]nau.edu
%          ORCID: http://orcid.org/0000-0003-2668-2794
%   Philip E. Higuera, Ph.D.
%          email: philip.higuera[at]umontana.edu
%          ORCID: https://orcid.org/0000-0001-5396-9956

% INITIALIZE WORKSPACE
clear all; % Clear entire workspace
clc; % Clear command prompt
close all; % Close all open graphics/figure windows

% NAME WORKING DIRECTORY - ***NEEDS TO BE ALTERED BY USER***
wdir = 'H:\Young-et-al_2018_Global-Ecology-and-Biogeography';

% USER DEFINES WHICH GCM AND EXPERIMENT TO DOWNSCALE. THIS COULD
% BE EXPANDED TO RUN THE ENTIRE DOWNSCALING ANALYSIS THROUGH A FOR LOOP FOR
% EACH GCM AND EXPERIMENT.
% gcm OPTIONS = {'GISS-E2-R','MPI-ESM-P','MRI-CGCM3'};
% experiment OPTIONS = {'past1000','historical','rcp85'};
gcm = 'GISS-E2-R'; % GCM to downscale
experiment = 'past1000'; % Experiment to downscale

% FOR THE GCM AND experiment SET ABOVE, THE DOWNSCALING IS DONE FOR EACH
% VARIABLE (tas and pr). HERE, WE SET THE VARIABLES TO PROCESS INCLUDING
% THEIR NAMES IN THE GCM AND PRISM DATA FILES. NEEDED FOR IMPORTING AND
% EXPORTING THE DATA.
vars = {'tas','pr'};
varsunits = {'mean_C','total_mm'};

% *************************************************************************
% LOAD IN MAP PROJECTION METADATA TO GENERATE VALUES FOR PROJECTED MAP
% COORDINATES [in meters] FOR THE CENTER OF EACH 2-km GRID CELL.
% -------------------------------------------------------------------------
% LOAD GEOTIFF INFORMATION TO CREATE BOUNDING BOX FOR STUDY AREA IN
% MAINLAND ALASKA. THESE DATA ARE IN THE FORM OF MATLAB DATA STRUCTURES, AND
% THEY ARE USED ALSO USED IN THE geotiffwrite.m FUNCTION USED TO EXPORT THE 
% NEWLY CREATED DOWNSCALED GRIDDED DATA.
if ispc
    cd([wdir,'\data\ancillary_data\']);
else
    cd([wdir,'/data/ancillary_data/']);
end

% LOAD FOR GEOGRAPHIC INFORMATION FOR PRISM DATASETS (AK AND CANADA)
load('geotifInfo_AK_CAN_ak83alb.mat');
% LOAD FOR GEOGRAPHIC INFORMATION FOR JUST MAINLAND ALASKA
load('geotifInfo_AK_mainland_ak83alb.mat');

R = geotifInfo_AK_CAN.RefMatrix; % world file matrix defining extent of
                                 % PRISM data.

% X AND Y RESOLUTIONS FOR PRISM CLIMATE GRID.
res_x = R(2);
res_y = R(4);

% BOUNDING BOX FOR PRISM DATA
bbox_ak_can = geotifInfo_AK_CAN.BoundingBox;
% VECTORS DEFINING THE PROJECTED METERS EASTING (xq) AND NORTHING (yq)
% FOR THE CENTER OF EACH PRISM GRID CELL.
xq = (bbox_ak_can(1)+res_x/2):res_x:((bbox_ak_can(2)-res_x/2));
yq = (bbox_ak_can(4)+res_y/2):res_y:((bbox_ak_can(3)-res_y/2));

% BOUNDING BOX FOR MAINLAND ALASKA DATA
bbox_akmain = geotifInfo_AK_mainland.BoundingBox;
% INDEX FOR ALL THE GRID CELLS IN THE BOUNDING BOX FOR OUR STUDY AREA
% MAINLAND ALASKA.
xprism_idx = find(xq >= bbox_akmain(1) & xq <= bbox_akmain(2));
yprism_idx = find(yq <= bbox_akmain(4) & yq >= bbox_akmain(3));

% CREATE MESHGRID FOR THE METERS EASTING AND NORTHING FOR THE CENTER OF
% EACH PRISM GRID CELL. NEEDED FOR BILINEAR INTEROPOLATION OF GCM
% ANOMLIES.
[X_prism, Y_prism] = meshgrid(xq,yq);
% *************************************************************************

for v = 1:length(vars) % For each variable (tas and pr) ...
    
    % CHANGE CURRENT DIRECTORY TO THE 
    if ispc
        cd(sprintf('%s\\data\\raw_data\\prism\\%s\\',wdir,char(vars(v))));
    else
        cd(sprintf('%s//data//raw_data//prism//%s//',wdir,char(vars(v))));
    end
    
    % ALLOCATE SPACE TO STORE THE PRISM CLIMATOLOGY FOR EACH MONTH JUST FOR
    % MAINLAND ALASKA. THIS WILL BE A TRIMMED MAP OF THE PRIMS 2-km DATA.
    PRISM_climatologies = NaN(geotifInfo_AK_mainland.Height, ... % rows
                              geotifInfo_AK_mainland.Width, ... % columns
                              12); % months
    
    % *********************************************************************
    % DOUBLE CHECK TO MAKE SURE THE SIZE OF THE PRISM GRID MATCHES THE
    % PRE-STORED GEOTIFF INFO IN geotifInfo_AK_CAN_ak83alb.mat FILE. IF THE
    % THE GRID SIZES DIFFER, IMPORT NEW GeoTIFF INFO TO CONDUCT THE
    % DOWNSCALING ANALYSIS. IF SIZES DO DIFFER A WARNING IS ISSUED. 
    gtiff_info_test = geotiffinfo( ...
        sprintf('%s_%s_akcan_prism_01_1961_1990.tif', ...
                char(vars(v)),char(varsunits(v))));
    if gtiff_info_test.Height ~= geotifInfo_AK_CAN.Height | ...
            gtiff_info_test.Width ~= geotifInfo_AK_CAN.Width
       warning(['Downloaded PRISM grid has a different extent than',...
                ' the one used in the original analysis.']);
       geotifInfo_AK_CAN = gtiff_info_test;        
    end
    clear('gtiff_info_test');
    % *********************************************************************
    
    % THIS FOR LOOP WILL RUN THROUGH EACH MONTH, IMPORT THE PRISM GRID, AND
    % THEN ONLY SELECT THE GRID CELLS WITHIN THE BOUNDING BOX FOR MAINLAND
    % ALASKA. THIS TRIMMED MAP WILL THEN BE USED IN THE BIAS-CORRECTING OF
    % THE DOWNSCALED GCM DATA.
    
    for i = 1:12 % For each month ...   
        % READ IN PRISM DATA
        prism_i = geotiffread( ...
                    sprintf('%s_%s_akcan_prism_%02i_1961_1990.tif', ...
                    char(vars(v)),char(varsunits(v)),i));     
        % TRIM PRISM MAP TO JUST STUDY AREA IN MAINLAND ALASKA. ALSO SET
        % DATA TYPE AS DOUBLE FLOATING POINT. DATA IS SINGLE FLOATING POINT
        % WHEN INITIALLY IMPORTED.
        PRISM_climatologies(:,:,i) = double(prism_i(yprism_idx,xprism_idx));
    end
    % SET NaN VALUES IN PRISM DATA. THIS IS THE MINIMUM VALUE IN THE
    % PRISM DATA.
    PRISM_climatologies(PRISM_climatologies==min(PRISM_climatologies(:))) = NaN;
    
    % SET WORKING DIRECTORY TO IMPORT PROCESSED GCM DATA (.mat files). 
    if ispc
        cd(sprintf('%s\\results\\1_processed_gcm_data_native_resolution\\%s\\', ...
            wdir,char(vars(v))));
    else
        cd(sprintf('%s//results//1_processed_gcm_data_native_resolution//%s//', ...
            wdir,char(vars(v))));
    end
    
    % IMPORT PROCESSED MAT FILE FOR historical GCM EXPERIMENT. USE
    % dir.m TO FIND FILE TO IMPORT, USING YEARS PART OF FILENAME AS A 
    % WILDCARD. THIS IS BECAUSE THE YEARS FOR EACH EXPERIMENT DIFFER AMONG
    % GCMS. 
    file_to_import = dir(sprintf('%s_%s_%s_historical_*.mat', ...
                         char(vars(v)),char(varsunits(v)),gcm));
    load(file_to_import.name);

    % *********************************************************************
    % CALCULATE 1961-1990 CLIMATOLOGICAL NORMAL FOR HISTORICAL EXPERIMENT 
    % OF GCM. THIS WILL BE USED TO CALCULATE ANOMALIES AND IT THE SAME TIME
    % PERIOD FOR THE PRISM BASE MAP. THE ANOMALIES ARE THEN SUBSEQUENTLY.
    
    % FIRST - ALLOCATE SPACE TO CALCULATE CLIMATOLOGICAL NORMAL FOR BASE
    % LINE PERIOD FOR EACH MONTH. 
    GCM_historical_climatologies = NaN(size(gcm_data.climate_data,1),12);
    historical_years = gcm_data.years; % 
    yr_idx_1961_1990 = find(historical_years>=1961 & historical_years<=1990);
    for i = 1:12 % For each month ...
        % CALCULATE CLIMATOLOGICAL NORMAL/AVERAGE FOR EACH GRID CELL
        % USING mean.m FUNCTION.
        GCM_historical_climatologies(:,i) = mean(gcm_data.climate_data(:,yr_idx_1961_1990,i),2);
    end
    % *********************************************************************
    
    % LOAD DATA FOR EXPERIMENT AND GCM 
    file_to_import = dir(sprintf('%s_%s_%s_%s_*.mat', ...
                         char(vars(v)),char(varsunits(v)),gcm,experiment));
    load(file_to_import.name);
    experiment_years = gcm_data.years; % Years for GCM data
    x = gcm_data.meters_easting; % X coordinates for center of each grid 
                                 % cell [meters]
    y = gcm_data.meters_northing; % Y coordinates for center of each grid 
                                  % cell [meters]    
    
    % *********************************************************************
    % CONDUCT BIAS CORRECTING AND DOWNSCALING ANALYSIS. 
    % *********************************************************************
    % Calcuate anomalies for each year from 1900-1999 using 1961-1990 as the
    % baseline. Then spatially interpolate anomalies to resolution of 
    % PRISM Climate Data and add/multiply against PRISM Climatologies
    
    for i = 1:12 % For each month ...
        for j = 1:length(experiment_years) % For each year ...
            
            if strcmp(char(vars(v)),'tas') % If current variable is surface air 
                                           % temperature (tas) ...
                                 
                % CALCULATE ANOMALIES FOR GCM DATA. HERE THIS IS THE
                % DIFFERENCE BETWEEN THE GCM OUTPUT AND THE CLIMATOLOGICAL
                % AVERAGE FOR THE BASELINE PERIOD.
                anomalies = gcm_data.climate_data(:,j,i)-GCM_historical_climatologies(:,i);
                
                % FIND ONLY THOSE DATA POINTS IN GCM DATA THAT ARE NOT NaN.
                notnan_idx = find(isnan(anomalies)==false);                
                anomalies = anomalies(notnan_idx);
                
            elseif strcmp(char(vars(v)),'pr') % ..., else if current variable is 
                                              % total monthly precipitation (pr) ... 
                
                % ---------------------------------------------------------
                % BELOW IS VERY SIMILAR CODE TO WHAT IS IMMEDIATELY ABOVE
                % FOR TEMPERATURE (tas). THE MOST IMPORTANT DIFFERENCES FOR
                % PRECIPITATION ARE THE FOLLOWING:
                %
                %   1. Anomalies are calculated by dividng the GCM data for
                %   a given month by the climatological normal (i.e. a 
                %   ratio). This is done to ensure there are no negative 
                %   estimates for precipitation. 
                %   
                %   2. Any anomaly values above the 99.5th percentile were to
                %   set to this 99.5th percentile value. This is to remove  
                %   instances where the denominator has a very low precip value,  
                %   causing an extreme percentage anomaly value. This was 
                %   based off the methods used by the Scenarios Network for
                %   Alaska and Arctic Planning (https://www.snap.uaf.edu/).
                % ---------------------------------------------------------
                
                % CALCULATE ANOMALIES FOR GCM DATA. HERE THIS IS THE
                % RATIO BETWEEN THE GCM OUTPUT AND THE CLIMATOLOGICAL
                % AVERAGE FOR THE BASELINE PERIOD.                
                anomalies = gcm_data.climate_data(:,j,i)./GCM_historical_climatologies(:,i);
                
                % FIND ONLY THOSE DATA POINTS IN GCM DATA THAT ARE NOT NaN.                
                notnan_idx = find(isnan(anomalies)==false);                
                anomalies = anomalies(notnan_idx);
                
                % USE ONLY THOSE DATA POINTS BELOW THE 99.5TH PERCENTILE OF
                % ANOMALY VALUES. 
                quant995 = prctile(anomalies,[99.5]);
                quant995_idx = find(anomalies>quant995);                
                anomalies(quant995_idx) = quant995;
                
            end

            % INTERPOLATE ANOMALY DATA USING BILINEAR ITNERPOLATION.
            % HERE, WE USE TriScatteredInterp.m FUNCTION FOR
            % INTERPOLATION. SPECIFICALLY, THIS PROVIDES A FUNCTION,
            % interp_fx, WHICH IS THEN USED WITH X (METERS EASTING) AND 
            % Y (METERS NORTHING) FROM PRISIM GRID TO INTERPOLATE TO 
            % 2-km RESOLUTION. griddata.m FUNCTION ALSO GIVES THE
            % SAME RESULTS BUT IS MUCH SLOWER.
            interp_fx = TriScatteredInterp(x(notnan_idx), ... % x coords
                                           y(notnan_idx), ... % y coords
                                           anomalies(notnan_idx)); % data values

            % USE FUNCTION CREATED ABOVE (i.e. interp_fx) AND
            % INTERPOLATE GCM ANOMALIES TO 2-km RESOLUTION.
            interpanom = interp_fx(X_prism,Y_prism);
            
            % TRIM THESE INTERPOLATED ANOMALIES TO JUST THE EXTENT OF
            % MAINLAND ALASKA.
            interpanom_trim = interpanom(yprism_idx,xprism_idx);

            % ADD/MULTIPLY THESE INTERPOLATED 2-km ANOMALIES FOR MAINLAND 
            % ALASKA TO THE PRISM BASE MAP (ALSO 2-km RESOLUTION). THE
            % DOWNSCALING FOR TEMPERATURE/PRECIP IS NOW COMPLETE.
            if strcmp(char(vars(v)),'tas')
                GCM_2km = interpanom_trim+PRISM_climatologies(:,:,i);
            elseif strcmp(char(vars(v)),'pr')
                GCM_2km = interpanom_trim.*PRISM_climatologies(:,:,i);                
            end
            % CREATE FILENAME (AND PATH) FOR EXPORTING DOWNSCALED MONTHLY 
            % GCM DATA
            if ispc
                filename = ...
                    sprintf('%s\\results\\2_gcm_data_downscaled_to_2km\\%s\\%s\\%s\\%s_%s_%s_%02i_%04i.tif', ...
                            wdir,gcm,char(vars(v)),experiment,char(vars(v)),char(varsunits(v)),gcm,i,experiment_years(j));
            else
                filename = ...
                    sprintf('%s//results//2_gcm_data_downscaled_to_2km//%s//%s//%s//%s_%s_%s_%02i_%04i.tif', ...
                            wdir,gcm,char(vars(v)),experiment,char(vars(v)),char(varsunits(v)),gcm,i,experiment_years(j));                    
            end

            % EXPORT GEOTIFF
            geotiffwrite(filename,GCM_2km,geotifInfo_AK_mainland.RefMatrix, ...
                'GeoKeyDirectoryTag',geotifInfo_AK_CAN.GeoTIFFTags.GeoKeyDirectoryTag);            
        end
    end
    % *********************************************************************
    % FINISH BIAS CORRECTING AND DOWNSCALING ANALYSIS. 
    % *********************************************************************    
end
% END OF SCRIPT -----------------------------------------------------------
