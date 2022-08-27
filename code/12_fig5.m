% 12_fig5.m
% MATLAB version: R2017a
% Operating System: Windows 7 Ultimate 64-bit (Service Pack 1)
%
% This code generates Figure 5 in Young et al. Global Ecology and 
% Biogeography. 
%
% Figure 5 Caption: Historical and future distribution of locations in  
% Alaska classified as occurring below, near, or above the 13.4 °C 
% threshold (i.e., within ±2 °C). Bar heights indicate the proportion of 
% Alaska occurring under each classification. Standard deviations (vertical 
% lines) account for potential uncertainty in the value of the temperature 
%  threshold. Specifically, the lower and upper limits to the 
% classification conditions (i.e., 13.4 ± 2 °C) were modified 100 times by 
% adding a random value from a uniform distribution (parameters a = -1 and  
% b = 1). For each random modification, the distribution of the Alaskan  
% landscape occurring below, near, or above the July temperature threshold 
% was reclassified, and the standard deviation was calculated from these 
% 100 reclassifications.
%
% FILE REQUIREMENTS:
%    (1) threshold_proximity_results.mat - File containing summarized and
%    geographic results from identifying the areas of Alaska that lie
%    below, near, or above the 13.4 degree C threshold to burning. This
%    file is located in:
%    '..\results\6_rcp85_proximity_results\threshold_proximity_results.mat'
%
%    (2) geotifInfo_AK_mainland.mat - Geographic and projection information
%    for study area in mainland alaska. Located in:
%    '..\data\ancillary_data\'
%
%    (3) AK_VEG.tif - Vegetation classification map of study area, used to
%    define spatial mask of study area. Located in:
%    '..\data\ancillary_data\'
%
%    (4) ak_shape_noislands_noSE.shp - shapefile containing coastline of
%    Alaska. Used for plotting map of Alaska.
%
%    (5) ecor_outlines.shp - shapefile containing outline of Alaska
%    ecoregions. Used in plotting maps of Alaska.
%    
% DEPENDENCIES:
%   * akaxes.m - Custom written function to ease the plotting of maps of
%   Alaska. Found in '..\code\functions\'
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

addpath([wdir,'\code\functions']);

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

% IMPORT threshold_proximity_results.mat AND SET VARIABLES AND DIMENSION
% VALUES TO DEFINED VARIABLE NAMES
if ispc
   load([wdir,'\results\6_rcp85_proximity_results\threshold_proximity_results.mat']);
else
   load([wdir,'/results/6_rcp85_proximity_results/threshold_proximity_results.mat']); 
end

% METERS EASTING AND NORTHING FOR THE CENTER OF EACH GRID CELL
x_coords = threshold_proximity_results.threshold_proximity_maps.dim2;
y_coords = threshold_proximity_results.threshold_proximity_maps.dim1;

% GCMS USED
gcms = threshold_proximity_results.threshold_proximity_maps.dim3;

% CLIMATOLOGICAL TIME PERIODS
climatologies_to_plot = ...
    threshold_proximity_results.threshold_proximity_maps.dim4;

% MAP OF CLASSIFICATION VALUES OF ALASKA
classification_values = ...
    threshold_proximity_results.threshold_proximity_maps.classification_values;

% SUMMARIZED PROPORTIONAL VALUES 
proportion_values = threshold_proximity_results.summarized_proportions.simulated_proportions;

% INVERSE PROJECTION OF METERS EASTING AND NORTHING VALUES TO LAT AND LONG
% VALUES FOR PLOTTING USING surf.m FUNCTION
[X,Y] = meshgrid(x_coords,y_coords);
[Lat,Lon] = projinv(geotifInfo_AK_mainland,X,Y);

% SET A CHARACTER STRING CONTAINING THE PATH AND NAME OF THE ALASKA
% COASTLINE SHAPE FILE. USED IN akaxes.m FUNCTION
if ispc
   cd([wdir,'\data\ancillary_data\shapefiles\']); 
   akshp = [pwd,'\ak_shape_noislands_noSE.shp']; 
else
    cd([wdir,'/data/ancillary_data/shapefiles']);
    akshp = [pwd,'/ak_shape_noislands_noSE.shp']; 
end

% ecoshp IS A SHAPEFILE USED IN PLOTTING BELOW TO DRAW OUTLINES OF 
% ECOREGIONS IN STUDY.
ecoshp = shaperead('ecor_outlines.shp','UseGeoCoords',true);

% AXIS PARAMETERS FOR PLOTTING
latPlot = [58 90];
lonPlot = [-168 -140];
dxdy = 1.4*2.54;
xstart = 0.3*2.54;
ystart = 6*2.54;

% COLORMAP FOR FIGURE 5
cmap = [102 102 102;
        255 255 102;
        204 204 204]./255;

% CLASSIFICATION LABELS FOR FIGURE 5    
class_labels = {'Below','Near','Above'};

% MAKE FIGURE 5 ***********************************************************

figure(5); clf;
set(gcf,'Units','Inches','Position',[1 1 6.5 7.75],'Color','w');

for g = 1:length(gcms) % For each gcm ...
    
  % SET GCM NAME AS CHARACTER VARIABLE  
  gcm_g = char(gcms(g));
  
  for i = 1:length(climatologies_to_plot) % For each climtological period ...
      
      % GET CURRENT CLASSIFICTION MAP VALUES AND CLASS PROPORTION VALUES
      classification_values_i = classification_values(:,:,g,i);
      proportion_values_i = proportion_values(:,:,g,i);
      
      % PLOT MAP OF ALASKA USING akaxes.m FUNCTION
      [~,hx] = akaxes( ...
                 [xstart+(i-1)*dxdy+(i-1)*0.25 ystart-((g-1)*dxdy+(g-1)*2.3) dxdy], ... % Position
                 latPlot,lonPlot, ... % Lat and lon limits of map axis
                 akshp); % Shapefile of Alaska to plot
      
      % USE surfm.m FUNCTION TO PLOT CLASSIFICATION MAP OF ALASKA. COLOR IT
      % USING PRE-DEFINED COLORMAP
      surfm(Lat,Lon,classification_values_i.*akmask); colormap(cmap);
      geoshow([ecoshp.Lat],[ecoshp.Lon], ...
          'Color','k', ...
          'LineWidth',1);
      
      % SET CURRENT AXIS LINES FROM BLACK TO WHITE
      set(gca,'YColor','w','XColor','w');
      
      % PLOT THE LABELS FOR EACH CLIMATOLOGICAL TIME PERIODS ACROSS THE TOP
      % OF THE FIGURE (FOR EACH COLUMN)
      if g == 1
          text(0.0061,1.26,sprintf('%s',char(climatologies_to_plot(i))), ...
              'HorizontalAlignment','Center', ...
              'FontName','Arial', ...
              'FontWeight','Normal');
      end
      
      % PLOT THE GCM LABELS ALONG THE SIDE OF THE FIGURE (FOR EACH ROW)
      if i == 1          
          text(-0.13,1.12,sprintf('%s',gcm_g), ...
              'HorizontalAlignment','Center', ...
              'Rotation',90, ...
              'FontName','Arial', ...
              'FontWeight','Normal');
      end
      
      % SET AXES TO MAKE BAR PLOTS SUMMARIZING PROPORTION VALUES
      axes('Units','Centimeters', ...
          'Position',[xstart+(i-1)*dxdy+i*0.25 ystart-((g-1)*dxdy+(g-1)*2.3)-2 3.2 1.7]);
      
      for k = 1:length(class_labels) % For each classification value ...
                                     % (below, near, or above) ...
          
          % FIND THE BAR HEIGHT (MEAN) AND STANDARD DEVIATION OF PROPORTION 
          % VALUES. CONVERT TO A PERCENTAGE VALUE (I.E. *100)
          y_bar = mean(proportion_values_i(:,k))*100; % Bar height of 
                                                      % proportion values
          y_sd  = std(proportion_values_i(:,k),0)*100; % SD of proportion 
                                                       % values
          
          h = bar(k,y_bar); % Plot bar height of classification k
          hold on; % Hold on so we can continue adding to this plot
          
          % SET THE FACECOLOR OF THE CURRENT BAR USING THE PRE-DEFINED
          % COLORMAP
          set(h,'FaceColor',cmap(k,:), ...
              'LineWidth',1);
          
          % ADD A LINE INDICATING THE +/- STANDARD DEVIATION
          line([k k],[y_bar-y_sd y_bar+y_sd], ...
              'Color','k', ...
              'LineWidth',1);
          
          % ADD Y-AXIS LABEL FOR BARPLOT IN BOTTOM LEFT CORNER OF FIGURE
          if g == 3 && i == 1
              
              if k == 1                  
                  text(-0.3,60,'%', ...
                      'FontName','Arial', ...
                      'FontSize',10, ...
                      'FontWeight','Bold', ...
                      'Rotation',270);
              end
              
          end
          
      end
      
      % FORMAT AXES
      set(gca,'YLim',[0 100], ...
          'XLim',[0.4 3.6], ...
          'YGrid','on', ...
          'YTick',0:25:100, ...
          'box','off', ...
          'XTickLabel',{''}, ...
          'FontName','Arial', ...
          'FontSize',8);
      
      % REMOVE Y-TICK LABELS FROM PANELS NOT IN FIRST COLUMN OF FIGURE
      if i > 1
         set(gca,'YTickLabel',{''});
      end
      
      % ADD LEGEND FOR COLOR MAP
      if g == 3 && i == 2
          
          axes('Units','Centimeters', ...
              'Position',[xstart+(i-1)*dxdy+i*0.25 ystart-((g-1)*dxdy+(g-1)*2.3)-4.1 6 2]);
          
          set(gca, ...
              'XLim',[0 10], ...
              'YLim',[0 10], ...
              'box','off', ...
              'XColor','w', ...
              'YColor','w');
          
          p = patch([1.5,1.5,2.5,2.5; 5,5,6 6; 8.5,8.5,9.5,9.5]', ...
                    [4.5,7.5,7.5,4.5; 4.5,7.5,7.5,4.5; 4.5,7.5,7.5,4.5]', ...
                    ones(4,3));
                
          set(p,'FaceColor','flat', ...
                'FaceVertexCData',cmap);
            
          for k = 1:length(class_labels)
            text(2.7+(k-1)*3.5,6,[char(class_labels(k));{'Thresh.'}], ...
                'FontName','Arial',...
                'FontSize',10, ...
                'HorizontalAlignment','Left');
          end
          
      end
  end
  
end

% *************************************************************************
% EXPORT FIGURES IN THREE DIFFERENT FORMATS
if ispc
    savefig([wdir,'\figures\fig\geb_12872-2019-Fig5.fig']);
    print([wdir,'\figures\jpg\geb_12872-2019-Fig5.jpg'],'-djpeg','-r600','-painters');
    print([wdir,'\figures\tif\geb_12872-2019-Fig5.tif'],'-dtiff','-r600','-painters');
else
    savefig([wdir,'/figures/fig/geb_12872-2019-Fig5.fig']);
    print([wdir,'/figures/jpg/geb_12872-2019-Fig5.jpg'],'-djpeg','-r600','-painters');
    print([wdir,'/figures/tif/geb_12872-2019-Fig5.tif'],'-dtiff','-r600','-painters');
end

% END OF SCRIPT -----------------------------------------------------------