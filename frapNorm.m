%% Copyright: Adenine Koo, 2023, University of Wisconsin-Madison
% Email : skoo8@wisc.edu

% MANUALLY CHANGE BLEACHING FRAME:
% Bleaching frame is set by default at frame #6, this parameter should be
% changed manually depends on user's experimental setting.

%% This function reads the csv outputs from frapROI2csv.m, normalises the 
% ROI intensity to get a normalised recovery curve for subsequent curve 
% fitting.
% This step is repeated seperately for each group of technical replicates.

% Syntax
% frapNorm("infile2.txt", "outfile.csv");

% First argument: infile.txt
% The first line of infile.txt specifies the data folder path to csv files 
% From second line onward, each line corresponds to a csv file to be
% analysed
% Format of infile.txt:
% C:\Users\skoo8\Videos\230721 FRAP
% 30-Aug-2023-L001.csv
% ...

% Second argument: name of output file
% Format:
% Normalised-L.csv

% Output
% 1. One csv file is generated for all input csv files and stored in the 
% data folder path (first line of infile.txt)
% Col 1: Timestamps info from the first input csv file
% Col 2 onwards: full scale normalised value for ROI2 (bleached doughnut)


function frapNorm(inputFile, outputFile)

% Open the input file for reading
fid = fopen(inputFile, "r");

% Read the first line of infile to get the path to the data folder
datafolderPath = fgetl(fid);
if ~strcmp(datafolderPath(end), "\")
    datafolderPath = strcat(datafolderPath, "\");
end % if ~strcmp

% Read line by line from the second line of infile.txt and store it as a
% list of csv files in a cell array
% csv file format:
% Col 1: Time
% Col 2: ROI1 - Nucleus
% Col 3: ROI2 - Bleached doughnut
% Col 4: ROI3 - Background with the same size as bleached doughnut
ff = 1;
while ~feof(fid)
    csvList{ff} = fgetl(fid);
    if ~strcmp(csvList{ff}(end-3:end), ".csv")
        csvList{ff} = strcat(csvList{ff}, ".csv");
    end % if ~strcmp
    ff = ff + 1;
end
fclose(fid);

% Number of csv files
fileNum = length(csvList);

% Create output csv file for normalised data
outfilename = strcat(datafolderPath, string(datetime("today")), ...
    "-", outputFile);

for csv = 1:fileNum
    currentfile = csvList{csv};
    % Create path to data file
    file = strcat(datafolderPath, currentfile);
    data = readmatrix(file);
    if csv == 1
        dataNum = size(data, 1);
        RO12_fscale = nan(dataNum, fileNum);
        RO12_fscale(:, 1) = data(:, 1);
    end % for if csv
    % Normalisation by subtraction of background intensity (ROI3), at Col 4
    ROI1_norm = data(:, 2) - data(:, 4);
    ROI2_norm = data(:, 3) - data(:, 4);
    % Double normalisation of ROI2 by 
    % 1. Dividing with the average ROI2 pre-bleach intensity
    % 2. Dividing with individual ROI1 intensity at each time point,
    %    and multiplying with average ROI1 pre-bleach intensity
    avgROI1prebleach = mean(ROI1_norm(1:5, 1));
    avgROI2prebleach = mean(ROI2_norm(1:5, 1));
    ROI2_dnorm = (ROI2_norm./avgROI2prebleach).*(avgROI1prebleach./ROI1_norm);
    % Full scale normalisation by
    % 1. Subtracting the first post-bleach ROI2 intensity
    firstpostbleachROI2 = ROI2_dnorm(6, 1);
    RO12_fscale(:, (csv+1)) = (ROI2_dnorm - firstpostbleachROI2)./(1 - firstpostbleachROI2);
end % for csv

% Write data matrix to output file
writematrix(RO12_fscale, outfilename);
end % for function