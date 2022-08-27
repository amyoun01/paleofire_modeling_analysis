% 9_fig3.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% This code generates Figure 3 in Young et al. Global Ecology and 
% Biogeography. 
%
% Figure 3 Caption: Prediction errors for each lake in the study area 
% during 850-1850 CE. Dark-colored symbols represent the median prediction 
% error from all 300 predictions for each lake (i.e., all BRTs [n = 100] 
% and GCMs [n = 3]). Confidence bounds represent the 25th to 75th 
% percentiles of prediction errors. Gray dots are prediction errors 
% associated with an individual BRT, GCM, and paleo-record. 
%
% FILE REQUIREMENTS:
%    (1) paleofire_metadata.csv - a table containing key metadata for each
%        lake that contains information needed for plotting Fig. 3.
%
%    (2) relative_prediction errors. These data are located in:
%        '..\results\5_brt_paleofire_predictions\relative_prediction_errors_0850-1850.mat'
%
% DEPENDENCIES:
%   * MATLAB Statistics and Machine Learning Toolbox
%
% CITATION:
% Young AM, Higuera PE, Abatzoglou JT, Duffy PA, Hu FS. Consequences of climatic 
%   thresholds for projecting fire activity and ecological change. Global Ecology and 
%   Biogeography. 2019;00:1?12. https://doi.org/10.1111/geb.12872
%
% Created by: Adam Young
% Created on: August 2016
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

% IMPORT PALEOFIRE METADATA FOR EACH SITE USING readtable.m FUNCTION
if ispc
    paleofire_metadata = readtable([wdir,'\data\paleofire_metadata.csv']);
else
    paleofire_metadata = readtable([wdir,'/data/paleofire_metadata.csv']);    
end
% LIST OF ECOREGIONS WHERE EACH SITE IS LOCATED (SHORT NAME)
ecoregions = paleofire_metadata.ecoregion;
% ORDER OF ECOREGIONS IN WHICH TO PLOT
unique_ecoregions = {'YKF','NTK','SCB','CRB','BFH','BRG','YKD'};
% CALCULATE TempWARM ANOMALY FOR EACH SITE BASED ON THE 1950-2009
% CLIMATOLOGY, DERIVED FROM DOWNSCALED CRU TS3.1 DATA.
twrm_anomaly = paleofire_metadata.TempWarm_CRUTS_1950_2009 - 13.4; % [deg. Celsius]

% LOAD RELATIVE PREDICTIONS ERRORS. CALCULATED AND ORGANIZED USING 
% '8_calculate_relative_prediction_errors.m'
if ispc
    load([wdir,'\results\5_brt_paleofire_predictions\relative_prediction_errors_0850-1850.mat']);
else
    load([wdir,'/results/5_brt_paleofire_predictions/relative_prediction_errors_0850-1850.mat']);   
end

% SET THE VARIABLES THAT DEFINE EACH DIMENSION IN THE 4-D ARRAY JUST
% IMPORTED
lakes = relative_prediction_errors.dim1;
brts = relative_prediction_errors.dim2;
gcms = relative_prediction_errors.dim3;

% DEFINE RELATIVE PREDICTION ERRORS AS THE VARIABLE pred_errors, BUT ONLY 
% FOR THE "Original" PREDICTIONS IN THE FOURTH DIMENSION. THESE ARE THE
% ONLY DATA THAT ARE PLOTTED IN FIG 3.
pred_errors = relative_prediction_errors.error_values(:,:,:,1);

% ALLOCATE SPACE TO A NEW VARIABLE CALLED 'error_vals_allgcms'. THIS
% VARIABLE WILL RE-ORGANIZE RELATIVE PREDICTION ERROR VALUES FOR THE
% UN-MODIFIED RELATIONSHIPS INTO A 2-D MATRIX, WITH ROWS REPRESENTING THE
% 29 PALEOFIRE SITE LOCATIONS AND COLUMNS REPRESENTING THE TOTAL NUMBER OF
% PREDICTIONS MADE ACROSS BRTS AND GCMS (n = 300). 
error_vals_allgcms = NaN(length(lakes),length(brts)*length(gcms));

cnt = 1; % Counting variable used to help fill up empty matrix
for g = 1:length(gcms) % For each gcm ...
    error_vals_allgcms(:,cnt:(cnt+99)) = pred_errors(:,:,g);
    cnt = cnt + 100;
end

error_prctiles = prctile(error_vals_allgcms,[25 50 75],2);

% MAKE FIGURE 3 ***********************************************************

% INITIALIZE FIGURES AND AXIS
figure(3); clf;
set(gcf,'Units','Inches', ...
    'Position',[2 2 4.335 4.335], ...
    'Color','w');
axes('Units','Inches', ...
    'Position',[0.6 0.5 3.7 3.7], ...
    'FontName','Arial', ...
    'FontSize',10, ...
    'LineWidth',3, ...  
    'YColor','k');

% INITIALIZE MARKERS TO BE USED FOR EACH ECOREGION AND THE NAMES OF THE
% ECOREGIONS TO BE LABELED IN A LEGEND
mkr = ['so^hv>d'];
econames= {'Yukon Flats', ...
           'Noatak', ...
           'Kobuk Valley', ...
           'Copper River Basin', ...
           'Brooks Foothills', ...
           'Brooks Range', ...
           'Yukon River Delta'};
       
rng(123); % Random seed initiation to ensure reproducibility of plots which
          % contain a random jittering effect along the x-axis

for e = 1:length(unique_ecoregions) % For each ecoregion ...
    
    % FIND PALEOSITES IN THAT ECOREGION (ROWS IN error_vals_allgcms
    % VARIABLE)
    eco_idx = find(strcmp(ecoregions,char(unique_ecoregions(e))));
    
    for i = 1:(length(brts)*length(gcms)) % For each brt and gcm ...
        
        % FIND X AND Y VALUES TO PLOT. ADD RANDOM VALUE TO X VALUES TO AID
        % IN VISUALIZATION OF PLOTTING IN FIGURE 3 (I.E. SO POINTS ARE NOT
        % OVERLAPPING EACH OTHER ALONG THE X AXIS)
        x = twrm_anomaly(eco_idx) + normrnd(0,0.3,length(eco_idx),1) ;
        y = error_vals_allgcms(eco_idx,i);
        
        % PLOT DATA POINTS x AND y
        plot(x,y, ...
            'LineStyle','none', ...
            'Color',[0.8 0.8 0.8], ...
            'Marker','.', ...
            'MarkerFaceColor',[0.8 0.8 0.8], ...
            'MarkerSize',5);
        hold on; % HOLD ON SO WE CAN ADD TO CURRENT FIGURE
        
    end
end

% HERE, WE GO THROUGH AND JUST PLOT THE MEDIAN AND IQR FOR EACH PALEOSITE.
% WE DO THIS AFTER PLOTTING ALL THE POINTS SO THESE SUMMARY STATISTICS ARE
% ON THE TOP OF THE PLOT.
for e = 1:length(unique_ecoregions) %  For each ecoregion ...
    
    % FIND PALEOSITES IN THAT ECOREGION (ROWS IN error_vals_allgcms
    % VARIABLE    
    eco_idx = find(strcmp(ecoregions,char(unique_ecoregions(e))));
    
    x = twrm_anomaly(eco_idx);
    y_median = error_prctiles(eco_idx,2);
    y_lower_ci = abs(y_median-error_prctiles(eco_idx,1));
    y_upper_ci = abs(y_median-error_prctiles(eco_idx,3));
    
    % PLOT MEDIAN AND IQR VALUES FOR EACH PALEO SITE
    errorbar(x,y_median,y_lower_ci,y_upper_ci, ...
             'Color','k', ...
             'Marker',mkr(e), ...
             'MarkerFaceColor','none', ...
             'MarkerSize',10, ...
             'LineStyle','none', ...
             'LineWidth',1);
end

% ADD LINES TO PLOT DEFINING RELATIVE PREDICTION ERRORS OF 0 AND NO ANOMALY
% IN TempWarm
line([-3 7],[0 0],'Color','k', ...
    'LineStyle','--', ...
    'LineWidth',2); hold on;
line([0 0],[-200 1200],'Color','k', ...
    'LineStyle','--', ...
    'LineWidth',2);

% MODIFY AXES OF CURRENT PLOT
set(gca, ...
    'XLim',[-3 7], ...
    'YLim',[-200 1200], ...
    'YTick',[-150,0,150,300:150:1200], ...
    'FontName','Arial', ...
    'FontSize',10, ...
    'XGrid','on', ...
    'YGrid','on');

% ADD X AND Y LABELS TO CURRENT PLOT
xlabel('Degrees from threshold (\circC)', ...
    'FontName','Arial', ...
    'FontSize',12);
ylabel('Relative prediction error (%)', ...
    'FontName','Arial', ...
    'FontSize',12);

% MAKE LEGEND IN UPPER LEFT HAND CORNER OF PLOT
p = patch([2.5 2.5 6.8 6.8],[640 1170 1170 640],ones(1,4));
set(p,'FaceColor','flat',...
    'FaceVertexCData',[1 1 1]);

for i = 1:length(mkr)
    plot(2.8,1130-(i-1)*75, ...
        'Marker',mkr(i),'Color','k', ...
        'MarkerFaceColor','w'); hold on;
    text(3.1,1130-(i-1)*75,char(econames(i)), ...
        'FontName','Arial', ...
        'FontSize',8);
end

% *************************************************************************
% EXPORT FIGURES IN THREE DIFFERENT FORMATS
if ispc
    savefig([wdir,'\figures\fig\geb_12872-2019-Fig3.fig']);
    print([wdir,'\figures\jpg\geb_12872-2019-Fig3.jpg'],'-djpeg','-r600','-painters');
    print([wdir,'\figures\tif\geb_12872-2019-Fig3.tif'],'-dtiff','-r600','-painters');
else
    savefig([wdir,'/figures/fig/geb_12872-2019-Fig3.fig']);
    print([wdir,'/figures/jpg/geb_12872-2019-Fig3.jpg'],'-djpeg','-r600','-painters');
    print([wdir,'/figures/tif/geb_12872-2019-Fig3.tif'],'-dtiff','-r600','-painters');
end
    
% END OF SCRIPT -----------------------------------------------------------