% 7_summarize_paleofire_predictions.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% This code reads in paleofire predictions made with brt models and
% organizes and summarizes them into a MATLAB data structure for effecient
% import and export.
%
% FILE REQUIREMENTS:
%    (1) paleofire_metadata.csv - a table containing key metadata for each
%        lake that is needed to organize the paleofire predictions. This
%        table is located in '..\data\'
%
%    (2) paleofire predictions made via the script '6_predict_paleofire.R'
%        These data are located in:
%        '..\results\5_brt_paleofire_predictions\predictions\'
%
% DEPENDENCIES:
%   * None
%
% CITATION:
% Young AM, Higuera PE, Abatzoglou JT, Duffy PA, Hu FS. Consequences of climatic 
%   thresholds for projecting fire activity and ecological change. Global Ecology and 
%   Biogeography. 2019;00:1?12. https://doi.org/10.1111/geb.12872
%
% Created by: Adam Young
% Created on: June 2016
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

% IMPORT DATA AND INITIALIZE VARIABLES ************************************

% IMPORT PALEOFIRE METADATA TABLE USING readtable.m FUNCTION
if ispc
    paleofire_metadata = readtable([wdir,'\data\paleofire_metadata.csv']);
else
    paleofire_metadata = readtable([wdir,'/data/paleofire_metadata.csv']);
end

years = 850:1820; % First year for each thirty-yr climatological period in 
                  % the brt predictions.
n_paleosites = height(paleofire_metadata); % Get number of paleofire sites 
                                           % (n=29)
nmodels = 100; % Number of brt models (1,2,...,100)
% GCMS USED IN ANALYSIS
gcms = {'GISS-E2-R','MPI-ESM-P','MRI-CGCM3'};
% THE SEVEN DIFFERENT SENSITIVITY EXPERIMENTS
sensitivity_experiments = {'Original', ...
                           'T1','T2','T3', ...
                           'Shape1','Shape2','Shape3'};

% ALLOCATED SPACE TO STORE PREDICTIONS IN A 4-D ARRAY
predfire = NaN(length(years),n_paleosites,nmodels,length(gcms), ...
               length(sensitivity_experiments));

% CHANGE WORKING DIRECTORY TO THE LOCATION WHERE THE BRT PREDICTIONS FOR
% THE PAST MILLENNIUM ARE LOCATED
if ispc
    cd([wdir,'\results\5_brt_paleofire_predictions\predictions']);
else
    cd([wdir,'/results/5_brt_paleofire_predictions/predictions']);    
end

for g = 1:length(gcms) % For each gcm ...
    for s = 1:length(sensitivity_experiments) % For each sensitivity 
                                              % experiment ...
        for i = 1:nmodels % For each brt ...
            
            % SET NAME OF CURRENT FILE TO READ IN AS A CHARACTER VARIABLE
            filename_to_import = sprintf('predfire_%s_%s_%i.csv', ...
                                         char(sensitivity_experiments(s)), ...
                                         char(gcms(g)),i);
                                     
            % READ IN PREDICTION DATA USING csvread.m. CONVERT THE 30-YR
            % PROBABILITY OF FIRE OCCURRENCE VALUE TO THE ANNUAL
            % PROBABILITY OF FIRE OCCURRENCE BY DIVIDING EVER ELEMENT BY
            % 30.
            predfire(:,:,i,g,s) = csvread(filename_to_import,1,1)/30;   
            
        end
    end
end

% CALCULATE THE CUMULATIVE NUMBER OF FIRES PREDICTED FOR EACH PALEOSITE FOR
% EACH SET OF CONDITIONS.
cumsum_predfire = cumsum(predfire);

% KEEP ONLY THE LAST VALUE FROM THE CUMULATIVE SUMMATION VALUES AS THIS IS
% THE TOTAL NUMBER OF FIRES PREDICTED FROM 850-1850 CE.
total_predicted_fires = squeeze(cumsum_predfire(end,:,:,:,:));

% CREATE EMPTY STRUCTURE TO STORE PREDICTED FIRE VALUES. IN THIS STRUCTURE
% ALSO STORE KEY METADATA HIGHLIGHTING WHICH CONDITIONS CHARACTERIZE EACH
% DIMENSION IN MATLAB STRUCTURE.
predicted_fires = struct;
predicted_fires.array_dimensions = '(lakes,brts,gcms,sensitivity_experiments)';
predicted_fires.dim1 = paleofire_metadata.code';
predicted_fires.dim2 = cellstr([repmat('brt_',100,1),num2str((1:100)','%-3i')])';
predicted_fires.dim3 = gcms;
predicted_fires.dim4 = sensitivity_experiments;
predicted_fires.values = total_predicted_fires;

% SET WORKING DIRECTORY TO WHERE THIS MATLAB STRUCTURE WILL BE SAVED
if ispc 
   cd([wdir,'\results\5_brt_paleofire_predictions']); 
else
    cd([wdir,'/results/5_brt_paleofire_predictions']);
end

% SAVE MATLAB STRUCTURE
save('predicted_fires_summarized_0850-1850.mat','predicted_fires');

% END OF SCRIPT -----------------------------------------------------------
