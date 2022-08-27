% extract.m
%
% Function that returns linear index values and/or raster data values from
% a gridded/raster map. 
%
% INPUTS:
%    - x-coordinates for the center of each grid cell that needs to be
%    extracted
%    - y-coordinates for the center of each grid cell that needs to be
%    extracted
%    - 3 by 2 GeoReferencing Matrix/worldfile. Provides x and y-coordinate
%    resolution and the x and y coordinate values for the top- and
%    left-most grid cell in matrix.
%    - 2 by 2 bounding box of geographic area. 
%    - A = raster map to extract linear index locations and values for. 
%    Optional input. If it is not provided, a blank map of the same size is
%    generated. 
%
% OUTPUT: none
%
% DEPENDENCIES:
%     (1) none
%
% Created by: Adam M. Young
% Created on: May 2016
% Edited for publication: December 2018
%
% Contact info: Adam M. Young, PhD, Adam.Young[at]nau.edu

function [idx,vals] = extract(x,y,R,bbox,A)

x_res = R(2); % Resolution of grid cell in x direction
y_res = R(4); % Resolution of grid cell in y direction

% Define coordinates for the grid lines of the raster.
x_lines = bbox(1):x_res:bbox(2);
if y_res > 0
    y_res = y_res*-1;
end
y_lines = bbox(4):y_res:bbox(3);

% Generate blank raster map if one is not provided. Used for defining and 
% obtaining linear index values
if nargin < 5
    A = zeros(length((bbox(4)+y_res/2):y_res:(bbox(3)-y_res/2)), ...
              length((bbox(1)+x_res/2):x_res:(bbox(2)-x_res/2)));
end

idx = []; % Empty matrix to store linear index values in

for i = 1:numel(x) % for each pair of coordinate values provided ...
    
    % Find the grid lines of the raster grid where the coordinates are
    % located
    elimlines_x = max(find(x_lines <= x(i)));
    elimlines_y = min(find(y_lines <= y(i)));
    
    % Use sub2ind.m function to find the linear index values for the
    % raster cells where the geographic coordinate points are located
    idx(i) = sub2ind(size(A),elimlines_y-1,elimlines_x);
    
end

vals = A(idx(idx>=0));

end