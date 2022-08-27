% 10_fig4.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% This code generates Figure 4 in Young et al. Global Ecology and 
% Biogeography. 
%
% Figure 4 Caption: Prediction error in MFI over the 850-1850 CE period, 
% stratified by ecoregion (rows). In the leftmost panel, predictions are 
% summarized by using the unmodified, original relationship between 
% temperature and the probability of fire occurrence. For each ecoregion, 
% relative prediction error was averaged across all lakes, and the boxplots 
% display the distribution of this averaged prediction error for all BRTs 
% and GCMs. In the middle panel, boxplots display the distribution of 
% prediction errors under three relationships that were modified by 
% shifting the threshold value (T1 = +0.50 °C, T2 = +1.00 °C, and T3 = 
% +1.50 °C). In the rightmost panel, boxplots display the distribution of 
% prediction errors under three scenarios where the shape of the 
% relationship was modified (i.e., S1 = Shape 1, S2 = Shape 2, S3 = 
% Shape 3). The right y-axis is the predicted MFI, with the observed MFI in 
% each ecoregion indicated by the horizontal line (rounded to the nearest 
% 50 yr). As a reference, the gray diamond represents the median of the 
% observed prediction error for the original 100 BRTs during the historical 
% period (1950-2009).
%
% FILE REQUIREMENTS:
%    (1) paleofire_metadata.csv - a table containing key metadata for each
%        lake that contains information needed for plotting Fig. 4.
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
% Created on: September 2016
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

% IMPORT PALEOFIRE METADATA FOR EACH SITE USING readtable.m FUNCTION
if ispc
    paleofire_metadata = readtable([wdir,'\data\paleofire_metadata.csv']);
else
    paleofire_metadata = readtable([wdir,'/data/paleofire_metadata.csv']);    
end

ecoregions = paleofire_metadata.ecoregion; % Short names of ecoregions, 
                                           % used to identify which sites
                                           % to select when plotting in
                                           % different panels.
% OBSERVED FIRE ROTATION PERIOD                                            
frpobs = paleofire_metadata.observed_ecoregion_FRP_1950_2009;
% AVERAGE NUMBER OF LAKES PER ECOREGION FROM 850-1850 CE
lk_avg_ff = paleofire_metadata.average_firefreq_ecoregion;

% LOAD RELATIVE PREDICTIONS ERRORS, FROM: '8_calculate_relative_prediction_errors.m'
if ispc
    load([wdir,'\results\5_brt_paleofire_predictions\relative_prediction_errors_0850-1850.mat']);
else
    load([wdir,'/results/5_brt_paleofire_predictions/relative_prediction_errors_0850-1850.mat']);   
end
% ASSIGN DIMENSION VARIABLES IN RELATIVE PREDICTION ERROR ARRAY
lakes = relative_prediction_errors.dim1;
brts  = relative_prediction_errors.dim2;
gcms  = relative_prediction_errors.dim3;
exps  = relative_prediction_errors.dim4;
pred_errors = relative_prediction_errors.error_values;

% SEPARATE THE DIFFERENT SENSITIVITY EXPERIMENTS: (1) THRESHOLD CHANGE AND
% (2) FIRE-TEMPERATURE RELATIONSHIP SHAPE CHANGE
tempvals = exps(2:4);
shapevals = exps(5:7);

% RE-ORGANIZE 
error_vals_allgcms = NaN(length(lakes),length(brts)*length(gcms),length(exps));
for s = 1:length(exps)
    cnt = 1;
    for g = 1:length(gcms)
        error_vals_allgcms(:,cnt:(cnt+99),s) = pred_errors(:,:,g,s);
        cnt = cnt + 100;
    end
end

% CALCULATE HISTORICAL PREDICTION ERRORS **********************************

% IMPORT HISTORICAL PREDICTED PROBABILITIES FROM 1950-2009. THESE
% PREDICTIONS WERE GENERATED USING '4_brt_training.R' AND ARE ONLY FOR THE
% UNMODIFIED ("Original") FIRE-TEMPERATURE RELATIONSHIP. 
if ispc
    hist_preds_at_paleosites = ...
        readtable([wdir,'\results\4_brt_models\historical_predictions_paleosites_1950-2009.csv'], ...
        'ReadRowNames',true);
else
    hist_preds_at_paleosites = ...
        readtable([wdir,'/results/4_brt_models/historical_predictions_paleosites_1950-2009.csv'], ...
        'ReadRowNames',true);
end

% CALCULATE PREDICTION ERRORS FOR HISTORICAL PERIOD USING
hist_preds_frp = ...
    30./table2array(hist_preds_at_paleosites); % Convert historical
                                               % predicted probabilities
                                               % to Fire Rotation Periods.
                                               
% CREATE A MATRIX THE SAME SIZE AS hist_preds_at_paleosites FOR OBSERVED 
% FRPS. 
hist_obsfrp_mtx = repmat(frpobs,1,size(hist_preds_frp,2));
% CALCULATE RELATIVE HISTORICAL PREDICTION ERROR FOR EACH SITE. 
hist_pred_error = ((hist_preds_frp-hist_obsfrp_mtx)./hist_obsfrp_mtx)*100;

% CREATE STRUCTURE FOR AGGREGATED ECOREGION INFO **************************
% THE MAIN PURPSOSE OF THIS STRUCTURE IS TO STORE KEY INFORAMATION FOR
% "AGGREGATED" ECOREGEIONS TO AID IN PLOTTING. HERE, THE ONLY ECOREGIONS 
% WE ARE COMBINING TOGETHER ARE THE "LOW FLAMMABILITY" TUNDRA REGIONS 
% (BROOKS FOOTHILLS, BROOKS RANGE, AND YUKON-KUSKOKWIM DELTA). WE
% AGGREGRATED ONLY THESE ECOREGIONS TOGETHER, JUST FOR FIG. 4, SINCE THERE 
% WERE ONLY 4 LAKES TOTAL AMONG THE THREE ECOREGIONS. 

% CREATE EMPTY STRUCTURE
ecoregion_agg = struct;

% BELOW, MAKE THE STRUCTURE OF LENGTH FIVE, ASSIGNING TWO FIELD NAMES TO
% FOR EACH ELEMENT: 'name' AND 'short_name'.
ecoregion_agg(1).name = {'Yukon Flats'};
ecoregion_agg(1).short_name = {'YKF'};

ecoregion_agg(2).name = {'Noatak'};
ecoregion_agg(2).short_name = {'NTK'};

ecoregion_agg(3).name = [{'Kobuk'};{'Valley'}];
ecoregion_agg(3).short_name = {'SCB'};

ecoregion_agg(4).name = [{'Copper River'};{'Basin'}];
ecoregion_agg(4).short_name = {'CRB'};

ecoregion_agg(5).name = [{'Brooks Foothills,'};{'Brooks Range,'}; ...
                         {'&Yuk. Riv. Delta'}];
ecoregion_agg(5).short_name = {'BFH','BRG','YKD'};                     

% BELOW, FIND THE LAKE INDEXES FOR EACH OF THE FIVE ECOREGIONS IN
% THE STRUCTURE CREATED IMMEDIATELY ABOVE. ASSIGN THESE INDEXES TO A NEW
% FILED IN THE STRCUTURE CALLED 'eco_idx'.
for i = 1:length(ecoregion_agg)
    
    ecoregion_shortname = ecoregion_agg(i).short_name;
    eco_idx = false(length(ecoregions),1);
    
    for e = 1:length(ecoregion_shortname)
        
        idx_e = find(strcmp(ecoregions,char(ecoregion_shortname(e))));
        if isempty(idx_e) == false
           eco_idx(idx_e) = true; 
        end    
        
    end
    
    ecoregion_agg(i).eco_idx = find(eco_idx);
    
end

% MAKE FIGURE 4 ***********************************************************

% INITIALIZE FIGURE
figure(4); clf;
set(gcf,'Units','Inches','Position',[0.5 0.5 4.335 8.203],'Color','w');

% INITIALIZE Y-AXIS PLOTTING PARAMETERS
ylims = [-100 700];
yticks = [0:150:600];
ypos = 6.5:-1.6:-1;

% *************************************************************************
% FIRST: PLOT DISTRIBUTION OF PREDICTION ERRORS FROM UNMODIFIED
% ("Original") BRTS. INCLUDE THE HISTORICAL PREDICTION ERROR AS A REFERENCE
% IN THESE PLOTS (PLOTTING MARKER WILL BE GREY DIAMOND).

% ALLOCATE SPACE TO STORE FIGURE HANDLES FOR BOXPLOTS 
bx = NaN(7,5);

for e = 1:length(ecoregion_agg) % For each aggregated set of ecoregions ...
    
    % INITIALIZE AXES FOR THE CURRENT PANEL
    axes('Units','Inches', ...
        'Position',[1 5.1353-e+1.36 3.08 1.54]);
    
    % GET THE INDEX OF THE PALEO SITES IN THE ERROR VALUES MATRIX
    eco_idx = ecoregion_agg(e).eco_idx;    
    
    % PLOT BOXPLOT FOR CURRENT ECOREGION, TAKING THE AVERAGE FIRST ACROSS
    % ALL LAKES WITHIN AN ECOREGION FOR EACH BRT AND GCM INSTANCE
    bx(:,e) = boxplot(mean(error_vals_allgcms(eco_idx,:,1)), ...
                      'positions',0.2,'labels',{''});              
    hold on; % HOLD ON SO MORE DATA CAN BE ADDED TO THIS PANEL
    
    % FORMAT AXES OF CURRENT PANEL
    set(gca,...
        'Units','Inches', ...
        'Position',[0.55 ypos(e) 0.4233 1.5], ...
        'YLim',ylims, ...
        'XLim',[0.1 0.3], ...
        'YTick',yticks, ...
        'XTickLabel',{''}, ...
        'XColor','k', ...
        'YColor','k', ...
        'LineWidth',1, ...
        'FontName','Arial', ...
        'FontSize',10, ...
        'box','on');
    
    % ADD LINE WHERE TO HIGHLIGHT WHERE PREDICTION ERROR IS ZERO
    line([0,2],[0 0], ...
        'Color',[0.2 0.2 0.2]','LineWidth',2, ...
        'LineStyle','-');
    
    % ADD REFERENCE POINT FOR THE HISTORICAL PREDICTION ERROR
    hist_error_e = hist_pred_error(eco_idx,:);
    plot(0.2,median(hist_error_e(:)),'kd', ...
        'MarkerSize',10, ...
        'MarkerFaceColor',[0.75 0.75 0.75]);
    
    % ADD PLOT TITLE
    if e == 1
       text(0.2,750,[{'Orig.'}],'FontName','Arial', ...
           'FontSize',10,'HorizontalAlignment','Center');
    end
    
    % ADD YLABEL FOR FIGURE
    if e == 3
        text(-0.125,400,'Relative Prediction Error (%)', ...
            'FontName','Arial', ...
            'FontSize',11, ...
            'Rotation',90, ...
            'HorizontalAlignment','Center');
    end
end

% FINALIZE COLORS/STYLES OF BOXPLOTS JUST PLOTTED
set(bx(1:6,:),'Color','k', ...
    'LineWidth',1, ...
    'LineStyle','-');
set(bx(7,:),'Marker','none');

% *************************************************************************
% NEXT, PLOT THE RESULTS FOR THE SENSITIVITY ANALYSIS WHERE THE TEMPERATURE
% THRESHOLD TO BURNING WAS MODIFIED/SHIFTED.

% ALLOCATE SPACE TO STORE FIGURE HANDLES FOR BOXPLOTS 
bx = NaN(7,length(ecoregion_agg),length(tempvals));

for e = 1:length(ecoregion_agg) % For each aggregated set of ecoregions ...
    
    % INITIALIZE AXES FOR THE CURRENT PANEL
    axes('Units','Inches', ...
        'Position',[2.2 5.1353-e+1.36 3.08 1.54]);
    
    % GET THE INDEX OF THE PALEO SITES IN THE ERROR VALUES MATRIX
    eco_idx = ecoregion_agg(e).eco_idx;

    % FOR EACH OF THE DIFFERENT TEMPERATURE CHANGES ...
    for t = 1:length(tempvals)

        % PLOT BOXPLOT FOR CURRENT ECOREGION, TAKING THE AVERAGE FIRST ACROSS
        % ALL LAKES WITHIN AN ECOREGION FOR EACH BRT AND GCM INSTANCE
        bx(:,e,t) = boxplot(mean(error_vals_allgcms(eco_idx,:,t+1)), ...
                            'positions',0.2*t,'labels',{''});                        
        hold on;
        
    end
    
    % ADD GRIDLINES TO PLOT MANUALLY
    line([0.3 0.3],[-100 700], ...
         'Color',[0.5 0.5 0.5], ...
         'LineStyle','-.');
    line([0.5 0.5],[-100 700], ...
         'Color',[0.5 0.5 0.5], ...
         'LineStyle','-.');    
    
    % FORMAT AXES OF CURRENT PANEL
    set(gca,...
        'Units','Inches', ...
        'Position',[1.07 ypos(e) 1.27 1.5], ...
        'YLim',ylims, ...
        'XLim',[0.1 0.7], ...
        'YTick',yticks, ...
        'XTick',0.3:0.2:0.5, ...
        'XTickLabel',{''}, ...
        'YTickLabel',{''}, ...        
        'XColor','k', ...
        'YColor','k', ...
        'LineWidth',1, ...
        'FontName','Arial', ...
        'FontSize',10, ...
        'LineWidth',1, ...
        'box','on');
    
    % ADD LINE WHERE TO HIGHLIGHT WHERE PREDICTION ERROR IS ZERO
    line([0,2],[0 0], ...
        'Color',[0.2 0.2 0.2]','LineWidth',2, ...
        'LineStyle','-');
    
    % ADD PLOT TITLES
    if e == 1
        for t = 1:length(tempvals)
            text(0.2*t,750,sprintf('T%d',t), ...
                'FontName','Arial', ...
                'FontSize',10, ...
                'HorizontalAlignment','Center');
        end
    end
    
end

% FINALIZE COLORS/STYLES OF BOXPLOTS JUST PLOTTED
set(bx(1:6,1:5,:),'Color','k', ...
    'LineWidth',1, ...
    'LineStyle','-');
set(bx(7,1:5,:),'Marker','none');

% *************************************************************************
% FINALLY, PLOT THE RESULTS FOR THE SENSITIVITY ANALYSIS FOR MODIFYING THE
% SHAPES OF THE FIRE-TEMPERATURE RELATIONSHIPS. ADDITIONALLY, CALCULATE AND
% LABEL THE MFI VALUES THAT ARE ASSOCIATED WITH EACH PREDICTION ERROR VALUE
% IN EACH ECOREGION, USED AS A REFERENCE.

% ALLOCATE SPACE TO STORE FIGURE HANDLES FOR BOXPLOTS 
bx = NaN(7,length(ecoregion_agg),length(shapevals));

for e = 1:length(ecoregion_agg)
    
    % INITIALIZE AXES FOR THE CURRENT PANEL
    axes('Units','Inches', ...
         'Position',[2.9625 5.5-e 3.08 1.54]);

    % GET THE INDEX OF THE PALEO SITES IN THE ERROR VALUES MATRIX     
    eco_idx = ecoregion_agg(e).eco_idx;

    % FOR EACH OF THE DIFFERENT TEMPERATURE CHANGES ...    
    for s = 1:length(shapevals)
        
        % PLOT BOXPLOT FOR CURRENT ECOREGION, TAKING THE AVERAGE FIRST ACROSS
        % ALL LAKES WITHIN AN ECOREGION FOR EACH BRT AND GCM INSTANCE        
        bx(:,e,s) = boxplot(mean(error_vals_allgcms(eco_idx,:,s+4)), ...
                            'positions',0.2*s,'labels',{''});        
        hold on;

    end
    
    % ADD GRIDLINES TO PLOT MANUALLY
    line([0.3 0.3],[-100 700], ...
         'Color',[0.5 0.5 0.5], ...
         'LineStyle','-.');
    line([0.5 0.5],[-100 700], ...
         'Color',[0.5 0.5 0.5], ...
         'LineStyle','-.');    
    
    % FORMAT AXES OF CURRENT PANEL    
    set(gca,...
        'Units','Inches', ...
        'Position',[2.44 ypos(e) 1.27 1.5], ...
        'YLim',ylims, ...
        'XLim',[0.1 0.7], ...
        'YTick',yticks, ...
        'XTick',0.3:0.2:0.5, ...
        'XTickLabel',{''}, ...
        'YTickLabel',{''}, ...       
        'XColor','k', ...
        'YColor','k', ...
        'LineWidth',1, ...
        'FontName','Arial', ...
        'FontSize',10, ...
        'LineWidth',1, ...
        'box','on');
    
    
    % ADD REFERENCE LINE FOR PREDICTION ERROR VALUES OF ZERO
    line([0,1],[0 0], ...
        'Color',[0.2 0.2 0.2]','LineWidth',2, ...
        'LineStyle','-');
    
    % *********************************************************************
    % BACK CALCULATE FROM RELATIVE PREDICTION ERRORS TO MFI TO PLOT
    % ALONG RIGHT Y-AXIS AS A REFERENCE
    for tk = 1:length(yticks) % For each error value on y-axis in ...
        
        err_tk = (yticks(tk)/100); % Normalize error to [0 1] scale
        eco_mfi = 1000/mean(lk_avg_ff(eco_idx)); % Get observed MFI average 
                                                 % for ecoregion
        % Calculate the MFI associated with a given error value
        mfi_err = (err_tk*eco_mfi)+eco_mfi;
        mfi_err = round(mfi_err/50)*50; % Round MFI to nearest 50 yr
        
        % LABEL MFI VALUES ON RIGHT SIDE OF Y AXES
        if tk > 1
            text(0.75,yticks(tk),sprintf('%3.0f',mfi_err), ...
                'FontName','Arial','FontSize',10);
        else
            text(0.75,yticks(tk),sprintf('%3.0f',mfi_err), ...
                'FontName','Arial','FontSize',10, ...
                'FontWeight','Bold');
        end
        
    end  
    
    % ADD PLOT LABELS
    if e == 1
        for s = 1:length(shapevals)
            text(0.2*s,750,sprintf('S%d',s), ...
                'FontName','Arial', ...
                'FontSize',10, ...
                'HorizontalAlignment','Center');
        end
    end
    
    % ADD Y-LABEL FOR RIGHT SIDE OF Y AXES
    if e == 3
        text(0.95,400,'Predicted \itMFI\rm  (yr)', ...
            'FontName','Arial', ...
            'FontSize',11, ...
            'Rotation',270, ...
            'HorizontalAlignment','Center');
    end

    % ADD LABELS IN EACH PANEL TO IDENTIFY ECOREGIONS
    if e == 1 || e == 2
        text(0.68,620,sprintf('%s',char(ecoregion_agg(e).name)), ...
            'FontName','Arial', ...
            'FontSize',10, ...
            'HorizontalAlignment','Right');
    elseif e == 3
        text(0.68,600,ecoregion_agg(e).name, ...
            'FontName','Arial', ...
            'FontSize',10, ...
            'HorizontalAlignment','Right');
    elseif e == 4
        text(0.68,600,ecoregion_agg(e).name, ...
            'FontName','Arial', ...
            'FontSize',10, ...
            'HorizontalAlignment','Right');
    else
        text(0.68,550,ecoregion_agg(e).name, ...
            'FontName','Arial', ...
            'FontSize',10, ...
            'HorizontalAlignment','Right');
    end
end

% FINALIZE COLORS/STYLES FOR BOXPLOTS
set(bx(1:6,:,:),'Color','k', ...
    'LineWidth',1, ...
    'LineStyle','-');
set(bx(7,:,:),'Marker','none');

% *************************************************************************
% EXPORT FIGURES IN THREE DIFFERENT FORMATS
if ispc
    savefig([wdir,'\figures\fig\geb_12872-2019-Fig4.fig']);
    print([wdir,'\figures\jpg\geb_12872-2019-Fig4.jpg'],'-djpeg','-r600','-painters');
    print([wdir,'\figures\tif\geb_12872-2019-Fig4.tif'],'-dtiff','-r600','-painters');
else
    savefig([wdir,'/figures/fig/geb_12872-2019-Fig4.fig']);
    print([wdir,'/figures/jpg/geb_12872-2019-Fig4.jpg'],'-djpeg','-r600','-painters');
    print([wdir,'/figures/tif/geb_12872-2019-Fig4.tif'],'-dtiff','-r600','-painters');
end

% END OF SCRIPT -----------------------------------------------------------