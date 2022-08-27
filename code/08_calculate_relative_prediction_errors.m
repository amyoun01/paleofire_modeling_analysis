% 8_calculate_relative_prediction_errors.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% This code reads in the summarized paleofire predictions generated from
% '7_summarize_paleofire_predictions.m' and calculates the relative
% prediction errors for each paleofire site from 850-1850 CE. The formula
% used to calculate the relative prediction errors is Eqn. 1 in Young et
% al. Global Ecology and Biogeography. 
%
% FILE REQUIREMENTS:
%    (1) paleofire_metadata.csv - a table containing key metadata for each
%        lake that is needed to organize the paleofire predictions. This
%        table is located in '..\data\'
%
%    (2) summarized paleofire predictions. These data are located in:
%        '..\results\5_brt_paleofire_predictions\predicted_fires_summarized_0850-1850.mat'
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

if ispc
    paleofire_metadata = readtable([wdir,'\data\paleofire_metadata.csv']);
    load([wdir,'\results\5_brt_paleofire_predictions\predicted_fires_summarized_0850-1850.mat']);
else
    paleofire_metadata = readtable([wdir,'/data/paleofire_metadata.csv']);
    load([wdir,'/results/5_brt_paleofire_predictions/predicted_fires_summarized_0850-1850.mat']);
end

% RETRIEVE VARIALBES FROM PALEOFIRE METADATA TABLE NEEDED TO CALCULATE
% RELATIVE PREDICTION ERRORS
nfires = paleofire_metadata.n_fires_0850_1850;
avg_ff_ecoregion = paleofire_metadata.average_firefreq_ecoregion;

% SET THE VARIABLES THAT DEFINE EACH DIMENSION IN THE 4-D ARRAY JUST
% IMPORTED
lakes = predicted_fires.dim1; % Paleofire lake sites
brts  = predicted_fires.dim2;  % brt models
gcms  = predicted_fires.dim3;  % gcms
exps  = predicted_fires.dim4;  % sensitivity experiements

% ALLOCATE SPACE TO STORE RELATIVE PREDICTION ERRORS. SAME SIZE AS
% PALEOFIRE PREDICTIONS ARRAY IMPORTED IN AND GENERATED via
% '7_summarize_paleofire_predictions.m'
prediction_errors = NaN(size(predicted_fires.values));

for s = 1:length(exps) % For each sensitivity experiment ...
    for g = 1:length(gcms) % For each gcm ...
        for m = 1:length(brts) % For each brt model ...
            for i = 1:length(lakes) % For each paleofire site ...
                
                % CALCULATE THE OBSERVED AND PREDICTED MFI
                O = 1000/nfires(i);
                P = 1000/predicted_fires.values(i,m,g,s);
                
                % CALCULATE THE OBSERVED AVERAGE MFI FOR EACH ECOREGION
                % (DENOMINATOR IN Eqn. 1 OF YOUNG ET AL. GEB)
                O_bar = 1000./avg_ff_ecoregion(i);
                
                if nfires(i) > 0 % If the number of fires from 850-1850 is 
                                 % greater than 0 then calculate the
                                 % relative prediction error. Multiply
                                 % error value by 100 to make it a
                                 % percentage.
                                 
                    E = ((P-O)/O_bar)*100;
                    prediction_errors(i,m,g,s) = E;
                    
                else % Else, if there are no fires for the current paleo 
                     % site (i.e., O = 0), use the MFI based on the most 
                     % recent fire observed in the analysis. This is only 
                     % for sites in the Brooks foothills and Yukon-Kuskowkim
                     % Delta ecoregions, and we use just the average across 
                     % the sites for each of these ecoregions. Since the 
                     % Yukon-Kuskokwim Delta only has one site this does 
                     % matter if it is the average. For the Brooks Foothills 
                     % there are two sites, both with a MFI of ~6500 yr.
                     % Given the similarity in the MFI for these two sites,
                     % we also just used the average as well.
                    
                    E = ((P-O_bar)/O_bar)*100;
                    prediction_errors(i,m,g,s) = E;
                    
                end
                
            end
        end
    end
end

% CREATE MATLAB STRUCTURE STORING THE DIMENSION DATA AND RELATIVE
% PREDICTION ERROR VALUES. STRUCTURE IS VERY SIMILAR TO THE PREDICTED
% VALUES IMPORTED IN THE BEGINNING OF THIS SCRIPT. 
relative_prediction_errors = struct;
relative_prediction_errors.array_dimensions = predicted_fires.array_dimensions;
relative_prediction_errors.dim1 = lakes;
relative_prediction_errors.dim2 = brts;
relative_prediction_errors.dim3 = gcms;
relative_prediction_errors.dim4 = exps;
relative_prediction_errors.error_values = prediction_errors;

% EXPORT RELATIVE PREDICTION ERRORS
if ispc
    cd([wdir,'\results\5_brt_paleofire_predictions']);
else
    cd([wdir,'/results/5_brt_paleofire_predictions']);
end
save('relative_prediction_errors_0850-1850.mat','relative_prediction_errors');    

% END OF SCRIPT -----------------------------------------------------------
