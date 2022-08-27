% 1_organize_gcm_data.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% Import and re-organize raw GCM data from NetCDF files into matlab (.mat) 
% files. These .mat files will be used for spatial downscaling using the
% script '2_downscaling_gcms_to_2km.m'
% 
% FILE REQUIREMENTS:
%   (1) GCM data in the form of netcdf files and downloaded from the 
%       LLNL node of the Earth Grid Federation System 
%       (https://esgf-node.llnl.gov/projects/esgf-llnl/). Metadata for
%       each GCM, including date of download and version numbers, are 
%       provided as csv files in: 
%       '..\data\raw_data\gcms\[GCM]\[VARIABLE]\[EXPERIMENT]\'
%
% DEPENDENCIES:
%   * MATLAB Mapping Toolbox
%
% CITATION:
% Young AM, Higuera PE, Abatzoglou JT, Duffy PA, Hu FS. Consequences of climatic 
%   thresholds for projecting fire activity and ecological change. Global Ecology and 
%   Biogeography. 2019;00:1?12. https://doi.org/10.1111/geb.12872
%
% Created by: Adam Young
% Created on: January 2016
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

% LOAD INFORMATION FOR GEOGRAPHIC PROJECTION: ALASKA 1983 ALBERS. NEEDED
% FOR DELTA-CHANGE DOWNSCALING.
if ispc
    load([wdir,'\data\ancillary_data\geotifInfo_AK_CAN_ak83alb.mat']);
else
    load([wdir,'/data/ancillary_data/geotifInfo_AK_CAN_ak83alb.mat']);
end

% INITIALIZE VARIABLES
SRCNAMES = {'GISS-E2-R','MPI-ESM-P','MRI-CGCM3'}; % Source names of GCMS
EXPNAMES = {'historical','past1000','rcp85'}; % Experiment names 
                                                      % from CMIP5
VARNAMES = {'tas','pr'}; % Variables (surface temperature and precipitation)

% USED IN DATA STRUCTURE THAT IS EXPORTED.
VAR_longname = {'mean monthly surface air temperature', ...
                'total monthly precipitation'};
VARUNITS = {'mean_C','total_mm'};
         
MONTHS = 1:12; % Months to process

% NUMBER OF DAYS IN EACH MONTH, INCLUDING LEAP YEARS.
n_days_month = [31,28,31,30,31,30,31,31,30,31,30,31;  % Standard year [days/month]
                31,29,31,30,31,30,31,31,30,31,30,31]; % Leap year [days/month]
            
for s = 1:length(SRCNAMES) % For each GCM
    for v = 1:length(VARNAMES) % For each climate variable
        for e = 1:length(EXPNAMES) % For each
                        
            SOURCE = char(SRCNAMES(s)); % Get GCM name
            VAR = char(VARNAMES(v)); % Get current variable
            EXPERIMENT = char(EXPNAMES(e)); % Get current gcm experiment
            
            % CONDITIONAL STATEMENT USED TO CHANGE NAME OF GCM MPI-ESM IF
            % FUTURE RCP PROJECTIONS ARE USED.
            if strcmp(SOURCE,'MPI-ESM-P') == true && strcmp(EXPERIMENT,'rcp85')
               SOURCE = 'MPI-ESM-LR'; 
            end            
            
            % READ IN LAT AND LON FOR CURRENT GCM. ONLY NEED TO READ IN THE
            % FIRST FILE FOR EACH GCM, VARIABLE, AND EXPERIMENT - LAT AND
            % LON RESOLUTION IS THE SAME WITHIN EACH GCM.
            if ispc
                cd(sprintf('%s\\data\\raw_data\\gcms\\%s\\%s\\%s', ...
                    wdir,SOURCE,VAR,EXPERIMENT));
            else
                cd(sprintf('%s//data//raw_data//gcms//%s//%s//%s', ...
                    wdir,SOURCE,VAR,EXPERIMENT));                
            end
            
            ncfiles = dir('*nc');
            nc_info = ncinfo(ncfiles(1).name);
            lat = double(ncread(ncfiles(1).name,'lat'));
            lon = double(ncread(ncfiles(1).name,'lon'));
            
            % REORGANIZE GCM GRID BY SCALING THE LONGITUDE FROM -180:180
            % INSTEAD FROM 0:360. THIS IS MORE STANDARD FORMAT FOR
            % LONGITUDE WHEN PROJECTING DATA. 
            lon_gt_180_idx = find(lon>180);
            lon(lon_gt_180_idx) = lon(lon_gt_180_idx) - 360;
            
            [~,IX] = sort(lon); lon = lon(IX);
            [LON,LAT] = meshgrid(lon,lat);
            
            % PROJECT GCM LAT AND LON GRID INTO METERS EASTING AND NORTHING
            % USING AN ALASKA ALBERS EQUAL AREA PROJECTION (1983 DATUM).
            % GEOGRAPHIC METADATA ARE AVAILBLE IN README FILE.
            [x,y] = projfwd(geotifInfo_AK_CAN,LAT(:),LON(:));
            
            % FIND THE REGION OF THE GCM GRID THAT IS WITHIN THE BOUDING
            % BOX FOR AK-CANADA DOWNSCALING REGION DEFINED BY PRISM DATA.
            % CREATE AN INDEX LIST FOR THESE GRID CELLS. 
            % NOTE THAT WE ADD 10E4 METERS TO THE TOP OF THE BOUNDING BOX 
            % FOR THIS SELECTION. THIS WAS DONE BECAUSE THE STUDY AREA 
            % (MAINLAND AK)IS AT THE NORTHERN MOST POINT OF THE BOUNDING 
            % BOX. TO ENSURE DATA WERE INTERPOLATED IN THE SUBSEQUENT 
            % DOWNSCALING ANALYSIS, WE NEED GCM DATA NORTH OF THE BOUNDING 
            % BOX.
            AK_CAN_BoundingBox = geotifInfo_AK_CAN.BoundingBox; 
                               
            locidx = find((x >=  AK_CAN_BoundingBox(1)  & ...
                           x <=  AK_CAN_BoundingBox(2)) & ...
                          (y >=  AK_CAN_BoundingBox(3)  & ...
                           y <= (AK_CAN_BoundingBox(4))+10e+4));
                        
            % FIND WHICH VARIABLE NUMBER IN THE GCM NETCDF FILE IS FOR TIME
            for i = 1:length(nc_info.Dimensions)
                if strcmp(nc_info.Variables(i).Name,'time') == true
                    timedim = i;
                end
            end
            
            % GO THROUGH EACH NETCDF FILE DEFINING THE DATA FOR EACH
            % VARIABLE, EXPERIMENT, AND GCM AND IMPORT DATA. 
            for i = 1:length(ncfiles)
                filei = ncfiles(i).name; % Get file name
                ncinf_i = ncinfo(filei); % Get netcdf metadata
                
                % FOR EACH TIME STEP IN NETCDF FILE READ IN THE jth SLICE
                % OF A 3-D ARRAY. THE FIRST 2 DIMENSIONS OF THE ARAY DEFINE
                % LAT AND LONGITUDE, AND THE 3RD DIMENSION IS FOR EACH TIME
                % STEP. 
                for j = 1:ncinf_i.Variables(timedim).Dimensions.Length 
                    valsi = double(ncread(ncfiles(i).name,VAR,[1,1,j], ...
                                    [Inf,Inf,1]))';
                    valsi = valsi(:,IX); % Re-organize columns in imported 
                                         % data to match the new order of 
                                         % -180:180 degrees longitude, 
                                         % instead of 0:360 degrees longitude. 
                    if i == 1 & j == 1
                        climate_data = valsi(locidx);
                    else
                        climate_data = [climate_data,valsi(locidx)];
                    end
                end
            end
            
            if strcmp(VAR,'tas') == true % If the current variable is 
                                         % temperature ...
                climate_data = climate_data-273.15; % Convert gcm temperature data 
                                                    % from K to Celsius
            else
                climate_data = climate_data.*86400; % Convert gcm precipitation data 
                                                    % from kg m^-2 s^-1 to mm day^-1
            end
            
            % GET START AND END DATES FOR THE CURRENT GCM AND EXPERIMENT 
            % FROM THE RAW DATA FILE NAME. NEEDED BELOW FOR CREATING DATE 
            % VECTORS AND SUBSEQUENTLY INDEXING RELATIVE TIME POINTS NEEDED 
            % IN THE ANALYSIS.
            first_filename_strsplit = regexp(ncfiles(1).name,'_');
            last_filename_strsplit = regexp(ncfiles(end).name,'_');
            
            startDate_str = ...
                ncfiles(1).name((first_filename_strsplit(end)+1): ...
                    (first_filename_strsplit(end)+6));
            endDate_str   = ...
                ncfiles(end).name((last_filename_strsplit(end)+8): ...
                    (last_filename_strsplit(end)+13));
            
            date_start = str2double(startDate_str(1:4));
            date_end   = str2double(endDate_str(1:4));

            startDate = datenum(startDate_str, 'yyyymm'); % Get start year
                                                          % of current
                                                          % experiment and
                                                          % convert to
                                                          % datenum format.
                                                          
            n_months = size(climate_data,2); % Number of total months
            years_months = NaN(n_months,2); % Date vector of two columsn. 
                                            % First column is year and
                                            % second column is month (1-12)
            
            % FILL IN DATE VECTOR 
            for i = 0:(n_months-1)
                dveci = datevec(addtodate(startDate,i,'month'));
                years_months(i+1,:) = dveci(1:2);
            end
                                               
            % INDEX WHICH YEARS ARE NEEDED FOR THE CURRENT EXPERIMENT
            experiment_years_idx = find(years_months(:,1) >= date_start & ...
                                        years_months(:,1) <= date_end);
            
            % CALCULATE WHICH YEARS ARE LEAP YEARS AND NON-LEAP YEARS. FOR
            % USE IN CALCULATING TOTAL MONTHLY PRECIPITATION.
            ndays = NaN(1,size(climate_data,2));
            for i = 1:size(years_months,1)
                yr = years_months(i,1);
                if mod(yr,400) == 0 && mod(yr,4) == 0
                    ndays(i) = n_days_month(2,years_months(i,2));
                elseif mod(yr,4) == 0 && mod(yr,100) ~= 0
                    ndays(i) = n_days_month(2,years_months(i,2));
                else
                    ndays(i) = n_days_month(1,years_months(i,2));
                end
            end
            
            % CREATE AN ARRAY TO STORE ELEMENT 
            ndays = repmat(ndays,size(climate_data,1),1);
            
            % IF THE CURRENT VARIABLE IS PRECIPITATION MULTIPLE THE AVERAGE
            % DAILY RAINFALL BY THE NUMBER OF DAYS IN EACH MONTH USING THE
            % PREVIOUSLY CREATED ndays VARIABLE. 
            if strcmp(VAR,'pr')                
                climate_data = climate_data.*ndays;
            end

            % ALLOCATE SPACE TO RE-ORGANIZE AND STORE CLIMATE DATA.
            nyears = length(experiment_years_idx)/length(MONTHS);
            climate_data_reorganized = NaN(size(climate_data,1),...
                                           nyears,length(MONTHS));
            k = experiment_years_idx(1);
            for n = 1:nyears
                for m = 1:length(MONTHS)
                    climate_data_reorganized(:,n,m) = climate_data(:,k);
                    k = k + 1;
                end
            end
            
            % STORE DATA TO EXPORT IN STRUCTURE FORMAT INCLUDING A VECTOR
            % FOR YEARS/TIME.
            gcm_data = struct; % Empty structure to store data to export
            gcm_data.name = SOURCE; % gcm name
            gcm_data.experiment = EXPERIMENT;
            % Variable longname (mean monthly surface air temperature or
            % or total monthly precipitation)
            gcm_data.climate_variable_longname = char(VAR_longname(v));
            % Variable shortname (tas or pr)
            gcm_data.climate_variable_shortname = VAR;
            % Climate data from GCM
            gcm_data.climate_data = climate_data_reorganized;
            % Variable Units (deg. C or mm)
            gcm_data.climate_variable_units = char(VARUNITS(v));
            gcm_data.years = ...
                unique(years_months(experiment_years_idx,1)); % years. 
                                                              % columns in 
                                                              % export array.
                                                              
            gcm_data.lat = LAT(locidx); % latitude of GCM grid cell
            gcm_data.lon = LON(locidx); % longitude of GCM grid cell
            gcm_data.meters_easting  = x(locidx); % meters easting
            gcm_data.meters_northing = y(locidx); % meters northing
            
            % CREATE STRING VARIABLE CONTAINING SAVE DIRECTORY AND FILE
            % NAME TO EXPORT.
            if ispc
                save_file_directory = ...
                    sprintf('%s\\results\\1_processed_gcm_data_native_resolution\\%s\\%s_%s_%s_%s_%04i-%04i.mat', ...
                    wdir,VAR,VAR,char(VARUNITS(v)),SOURCE,EXPERIMENT,date_start,date_end);
            else
                save_file_directory = ...
                    sprintf('%s//results//1_processed_gcm_data_native_resolution//%s//%s_%s_%s_%s_%04i-%04i.mat', ...
                    wdir,VAR,VAR,char(VARUNITS(v)),SOURCE,EXPERIMENT,date_start,date_end);
            end
            
            % EXPORT PROCESSED GCM DATA AS MATLAB DATA FILE (.mat)
            save(save_file_directory,'gcm_data');
            
        end
    end
end
% END OF SCRIPT -----------------------------------------------------------
