% createClimatologies.m
%
% [fClim] = createClimatologies(files,climatologies,months,fun_handle)
% Description: Calcuates the multiyear average of a given statistic for 
% gridded data. The function will have acess to a directory that contains
% monthly or annual gridded data. The user specifies the
% climatologies to create by providing a vector(s) of years. 
% The input arguements are:
%
% directory = String. Directory where the GeoTiff Files are located
% strN = String. The earliest date (mm_yyyy) of the GeoTiff files located
%   within the directory.
% climatolgies = Numeric. A simple vector or matrix that represents the 
%   time periods to create climatogies for (e.g., 1950:1979).
% months = Numeric. Vector of the months to read in from the direcoty
% func_handle = handl(@). Function Handle that calculates the appropriate
%   funtion on the gridded data sets to create the climatologies.
% verbose - If set to true then the a progress bar will be provided.
%   Default is false.
% missingval - the value that indicates a value is missign in a grid cell.
%   Defualts to using NaN as missingvalue if it is not provided. 
%
% Example of how to set up input variables:
%
% directory = 'C:\GeoTiff\Precipitation'; % Where GeoTiff Files Are Located
% strN = '01_1901'; % The Month and date of the earliest GeoTiff File
% climatologies = [1971:2000; 1981:2010]; % Thirty Year climatolgical 
%                                           periods of interest
% months = 6:8; % Months to use for the climatology
% func_hand = @(x) nansum(x,3); % The numeric function to perform across 
%                                 those months
%
% This example would create a climatology of the average total preciptiation for
% June-July-August during the 30 year periods of 1971-2000 and 1981-2010.
%
% IMPORTANT: EACH FILE NAME MUST INCLUDE AT A MINIMUM THE MONTH AND YEAR IN 
% THE FORM OF 'mm_yyyy'. ALSO EACH
% FILE MUST HAVE A GEOTIFF (.TIF) EXTENSION.
%
% Author: Adam Young
% Date Created: April, 2012
% Edited for publication: January 2016
%%
function[fClim] = createClimatologies(directory,...
    strN,...
    climatologies,...
    months,...
    func_handle, ...
    verbose, ...
    missingval)
% Main Function

if nargin < 6
   verbose = false; 
end

if nargin < 7
   missingval = NaN; 
end

warning off map:geotiffinfo:tiffWarning % Turn GeoTiff Warning Message Off

cd(directory); % Change Directory
files = dir('*tif'); % Create Structure of File Names

% regexp(string,expression) parses the
% input string locating those parts of
% string that match the character pattern
% specified by regular expression,
% (expression). This syntax returns the starting index of each
% match. If no matches are found, regexp returns an empty array
sName = regexp(files(1).name,strN);

gridInfo = geotiffinfo(files(1).name); % Get GeoTiff Info from first .tif
% file in directory.

% Get the dimentsion of the climatologies matrix
sClim = size(climatologies);
% Final output climatology
fClim = zeros(gridInfo.Height,gridInfo.Width,sClim(1)); %

dates = NaN(length(files),2);

for i = 1:length(files)
    if length(months) >= 2
        dates(i,2) = str2double(files(i).name((sName+3):(sName+6)));
        dates(i,1) = str2double(files(i).name((sName):(sName+1)));
    else
        dates(i,2) = str2double(files(i).name((sName):(sName+3)));
    end
end

if verbose == true
    h = waitbar(0,'Creating climatologies...'); % create progress bar
end

for c = 1:sClim(1) % For Each Climatological Period
    cl_y = zeros(gridInfo.Height,gridInfo.Width,...
        sClim(2)); % Holding Matrix For Each Year
    y_i = 0; % Initialize Year Index
    for y = 1:length(climatologies(c,:)) % For Each Year in the climatogical Period
        % Holding Matrix
        month_hold = zeros(gridInfo.Height,gridInfo.Width,length(months));
        m_i = 0; % Initialize Month Index
        for m = 1:length(months) % For Each Month In the Year
            if length(months) > 1
                ind = find(dates(:,1) == months(m) & dates(:,2) == climatologies(c,y));
            else
                ind = find(dates(:,2) == climatologies(c,y));
            end
            m_i = m_i + 1; % Index to the next month
            cl_i = double(geotiffread(files(ind).name)); % Read GeoTiff File
            % Set missing values as NaN if not already
            if isnan(missingval) == false
                cl_i(cl_i == missingval) = NaN;
            end
            month_hold(:,:,m_i) = cl_i; % Set Current Month equal to matrix 
                                        % just imported
        end
        y_i = y_i + 1; % Move On to Next Year in Year For Loop
        cl_y(:,:,y_i) = func_handle(month_hold); % Apply Function Handle to 
                                                 % the monthly data for the 
                                                 % current year
        clear month_hold % Clear month_hold variable from workspace
    end
    cl_y_avg = nanmean(cl_y,3); % Average the climatological period
    cl_y_avg(isnan(cl_y_avg) == true) = missingval;
    fClim(:,:,c) = cl_y_avg; % Averaged Climatolgy Period assigned as 
                             % final climatology
    clear cl_y % Clear cl_y variable from workspace
    if verbose == true
        waitbar(c/sClim(1)) % update progress bar
    end
end % End main loop
if verbose == true
    close(h) % close progress bar
end