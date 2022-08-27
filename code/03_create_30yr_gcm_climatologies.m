% 3_create_30yr_gcm_climatologies.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% Calculate 30-yr climate normals for a given 30-yr period. In this code
% provided, we only give an example of how to do this using the 30 years
% of downscaled monthly climate data for temperature and precipitation
% generated from the script '2_downscaling_gcms_to_2km.m'. Below, we
% provide the code to run the function 'createClimatologies.m' that will
% generated two climatological grids at 2-km resolution: 
%   
%   (1) Mean Total Annual Precipitation from 0850-0879 CE [units = mm]
%   (2) Mean Temperature of the Warmest Month from 0850-0879 CE [units = deg. Celsius]
%
% These climatologies will be specifically for the GISS-E2-R GCM and 
% past1000 experiment. This code could be generalized in a for loop to run
% through multiple GCMS and/or CMIP5 experiments.
%
% FILE REQUIREMENTS:
%    (1) Monthly gridded climate data for time period of interest in the
%    form of a geotiff file format (.tif). These data are located in:
%    '..\results\2_gcm_data_downscaled_to_2km\[GCM]\[VARIABLE]\[EXPERIMENT]\'
%
%    (2) MATLAB (.mat) file containing GeoTIFF information and spatial 
%    metadata needed for exporting newly created climatology maps: 
%    '..\data\ancillary_data\geotifInfo_AK_mainland_ak83alb.mat'
%
% DEPENDENCIES:
%   * createClimatologies.m - function used to summarize multi-year
%     climate data and create a climatological normal of a gridded
%     dataset. Details regarding this function are described in comments
%     of the createClimatologies.m function, located in:
%     '..\code\functions'
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
clear all; % clear workspace of variables
clc; % clear command prompt
close all; % close all current figure windows

% WORKING DIRECTORY - ***NEEDS TO BE ALTERED BY USER***
wdir = 'H:\Young-et-al_2018_Global-Ecology-and-Biogeography';

% ADD PATH FOR FOLDER THAT CONTAINS createClimatologies.m FUNCTION
addpath([wdir,'\code\functions']);

varname = @(x) inputname(1); % Short function to convert variable name to
                             % a character string, useful for naming
                             % GeoTiff files when exporting.

% LOAD FOR GEOGRAPHIC INFORMATION FOR JUST MAINLAND ALASKA. NEEDED WHEN
% EXPORTING GEOTIFF FILES.
if ispc
    load([wdir,'\data\ancillary_data\geotifInfo_AK_mainland_ak83alb.mat']);
else
    load([wdir,'/data/ancillary_data/geotifInfo_AK_mainland_ak83alb.mat']);
end

% SET WHICH GCM AND EXPERIMENT TO PROCESS
gcm = 'GISS-E2-R';
experiment = 'past1000';

years_for_climatology = [0850:0879]; % Years to create a 30-yr climatology
                                     % for. Here, as an example, are the 
                                     % first thirty years of the past1000
                                     % experimentf for the GISS-E2-R GCM.

% *************************************************************************
%  MEAN TOTAL ANNUAL PRECIPITATION (PAnn)

% SET DIRECTORY OF MONTHLY TEMPERATURE MAPS TO IMPORT (data_directory) AND
% THE DIRECTORY TO STORE THE CLIMATOLOGIES CREATED (save_directory).
if ispc
    data_directory = ...
        sprintf('%s\\results\\2_gcm_data_downscaled_to_2km\\%s\\pr\\%s', ...
        wdir,gcm,experiment);
    
    save_directory = ...
        sprintf('%s\\results\\3_gcm_30yr_climatologies\\example\\%s\\%s', ...
        wdir,gcm,experiment);
else
    data_directory = ...
        sprintf('%s//results//2_gcm_data_downscaled_to_2km//%s//pr//%s', ...
        wdir,gcm,experiment);    
    
    save_directory = ...
        sprintf('%s//results//3_gcm_30yr_climatologies//example//%s//%s', ...
        wdir,gcm,experiment);
end

% THE FOLLOWING ARE PARAMETERS USED IN THE createClimatologies.m FUNCTION.
% FOR MORE DETAILS, PLEASE SEE SCRIPT FOR THIS FUNCTION, LOCATED IN:
% ..\code\functions\createClimatologies.m
strN = '01_0850';
months = 1:12;
func_hand = @(x) sum(x,3);

% RUN createClimatologies.m TO GENERATE CLIMOTOLOGICAL MAP FOR
% PRECIPITATION. CALL THIS NEWLY CREATED VARIABLE PAnn.
PAnn = createClimatologies(data_directory,strN,years_for_climatology, ...
                           months,func_hand);

% CREATE FILENAME OF GEOTIFF TO EXPORT
if ispc
    filename = ...
        sprintf('%s\\%s_%s_%04d_%04d.tif',...
        save_directory,varname(PAnn),gcm, ...
        years_for_climatology(1),years_for_climatology(end));
else
    filename = ...
        sprintf('%s//%s_%s_%04d_%04d.tif',...
        save_directory,varname(PAnn),gcm, ...
        years_for_climatology(1),years_for_climatology(end));    
end

% EXPORT GEOTIFF
geotiffwrite(filename,PAnn,R, ...
             'GeoKeyDirectoryTag',geotifInfo_AK_mainland.GeoTIFFTags.GeoKeyDirectoryTag);

% clear PAnn; % Clear variable from workspace - useful when raster grids to  
%             % export are very large.

% *************************************************************************            
% MEAN TEMPERATURE OF THE WARMEST MONTH (TempWarm)
% BELOW, WE PROVIDE VERY SIMILAR TO THAT ABOVE FOR PRECIPITATION, BUT FOR
% TEMPERATURE. 

% SET LOCATION OF MONTHLY TEMPERATURE MAPS TO IMPORT. SAVE DIRECTORY
% REMAINS THE SAME AS PREVIOUSLY DEFINED.
if ispc
    data_directory = ...
        sprintf('%s\\results\\2_gcm_data_downscaled_to_2km\\%s\\tas\\%s', ...
        wdir,gcm,experiment);
else
    data_directory = ...
        sprintf('%s//results//2_gcm_data_downscaled_to_2km//%s//tas//%s', ...
        wdir,gcm,experiment);    
end

% SET PARAMETERS FOR createClimatologies.m FUNCTION
strN = '01_0850';
months = 1:12;
func_hand = @(x) max(x,[],3);

% RUN createClimatologies.m FOR MEAN TEMPERATURE OF THE WARMEST MONTH
TempWarm = createClimatologies(data_directory,strN,years_for_climatology, ...
                               months,func_hand);

% CREATE FILENAME OF GEOTIFF TO EXPORT
if ispc
    filename = ...
        sprintf('%s\\%s_%s_%04d_%04d.tif',...
        save_directory,varname(TempWarm),gcm, ...
        years_for_climatology(1),years_for_climatology(end));
else
    filename = ...
        sprintf('%s//%s_%s_%04d_%04d.tif',...
        save_directory,varname(TempWarm),gcm, ...
        years_for_climatology(1),years_for_climatology(end));    
end

% EXPORT GEOTIFF
geotiffwrite(filename,TempWarm,geotifInfo_AK_mainland.RefMatrix, ...
             'GeoKeyDirectoryTag',geotifInfo_AK_mainland.GeoTIFFTags.GeoKeyDirectoryTag);

% clear TempWarm;
% END OF SCRIPT -----------------------------------------------------------
