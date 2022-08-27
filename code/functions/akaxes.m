% akaxes.m
%
% Plots the main coastline of Alaska and colors in land areas as a dark
% grey color. Used to create background map of Alaska in making figures.
%
% INPUTS:
%    - position - vector of length 3 that provides the (1) starting point
%    of the axes in the x direction, (2) starting point of the current axes
%    in the y direction, and (3) the width/height of the current axes
%    - latPlot - latitude limits of map
%    - lonPlot - longitude limits of map
%    - shapefile - full directory and filename of the shapefile used to
%    draw coastline of Alaska.
%
% OUTPUT: figure and patch handles.
%
% DEPENDENCIES:
%     (1) From the mapping toolbox:
%       - shaperead.m - read in shapefiles
%       - axesm.m - draw map axes in figure panel
%       - patchesm.m - draw map
%
% CITATION, FILES, AND SELF-AUTHORED FUNCTIONS AVAILABLE FROM ...
%
% Created by: Philip Higuera, modified by Adam Young
% Created on: May 2013
% Edited for publication: December 2018
%
% Contact info: Philip E. Higuera, PhD, philip.higuera[at]umontana.edu
%%
function[h,a] = akaxes(position,latPlot,lonPlot,shapefile) 

[xstart] = position(1);
[ystart] = position(2);
[dxdy]   = position(3); 

% Read in shapefile of Alaska coastline
AK = shaperead(shapefile, ...
               'UseGeoCoords', true);

% Create axes for panel in figure
a = axes('units','centimeters', ...
           'Position',[xstart ystart dxdy dxdy]);

% set up map axes
axesm('tranmerc', ...
      'MapLatLimit',latPlot, ...
      'MapLonLimit',lonPlot, ...
      'Frame','off', ...
      'Grid','off', ...
      'MeridianLabel','off', ...
      'ParallelLabel','off', ...
      'FontSize',10, ...
      'PLineLocation',[55:5:90], ...
      'MLineLocation',[-140:-10:-168]);

% Plot coastline of Alaska, color land area of Alaska grey
h =  patchesm(AK.Lat,AK.Lon, ...
    'LineWidth',0.5, ...
    'EdgeColor','none', ...
    'FaceColor','w'); % grey colormap

% Further format map axes
box off;
axis tight;