%% Copyright: Adenine Koo, 2023, University of Wisconsin-Madison
% Email : skoo8@wisc.edu

% MANUALLY CHANGE BLEACHING FRAME:
% Bleaching frame is set by default at frame #6, this parameter should be
% changed manually depends on user's experimental setting.

%% This function reads the csv outputs containing normalised recovery curve
% from frapNorm.m, perform curve fitting on each curve, estimate,
% tabulate and plot its t-half and mobile fraction.
% This step groups all biological replicates (each with different numbers
% of technical replicates) for a combined analysis. 
% Repeat analysis seperately for each experimental variables 
% (genotype/treatment/etc.).

% Syntax
% expfitting("infile3.txt");

% First argument: infile.txt
% The first line of infile.txt specifies the data folder path to all the 
% normalised csv files (outputs of frapNorm.m) for an experimental
% variable.
% The second line of infile.txt states the variable/group name
% From third line onward, each line corresponds to the normalised recovery
% curves for each biological replicate to be analysed.
% Format of infile.txt:
% C:\Users\sihui\OneDrive - UW-Madison\2022 Fall\esayFRAPcsv
% Short
% 11-Sep-2023-Normalised-S1.csv
% 11-Sep-2023-Normalised-S2.csv
% 11-Sep-2023-Normalised-S3.csv
% 12-Oct-2023-Normalised-S4.csv
% ......

% Output
% 1. Two csv files are generated for estimated t-half and mobile fraction
% from each recovery curve, grouped by column (biological replicate) and
% row (technical replicate), stored in the data folder path (first line of
% infile.txt)
% Output filenames format:
% todaydate-samplename-tHalf.csv; todaydate-samplename-mf.csv
% 2. One png file is generated for each normalised recovery curve with the
% fitted curve plotted on top of it, labelled with estimated t-half and 
% mobile fraction as well as the adjusted R-square value from curve fitting.
% Output filename format: todaydate-samplename[biological replicate#]-
% [technical replicate#].png


function expfitting(inputFile)

% Open the input file for reading
fid = fopen(inputFile, "r");

% Read the first line of infile to get the path to the data folder
datafolderPath = fgetl(fid);
if ~strcmp(datafolderPath(end), "\")
    datafolderPath = strcat(datafolderPath, "\");
end % if ~strcmp

% Read second line for the genotype of the sample
genotype = fgetl(fid);

% Read line by line from the third line of infile.txt and store it as a
% list of csv files in a cell array
% Each csv file stores normalised data output from frapNorm.m
% csv file format:
% Col 1: Time
% Col 2 onward: Each column corresponds to the normalised fluorescent 
%               intensity of the bleached doughnut over time
ff = 1;
while ~feof(fid)
    csvList{ff} = fgetl(fid);
    if ~strcmp(csvList{ff}(end-3:end), ".csv")
        csvList{ff} = strcat(csvList{ff}, ".csv");
    end % if ~strcmp
    ff = ff + 1;
end
fclose(fid);

% MANUALLY CHANGE BLEACHING FRAME HERE!!!
% Bleaching occurred at the sixth frame by default,
% this parameter depends on experimental settings.
bleachedFrame = 6;

% Number of csv files
fileNum = length(csvList);

% Create output csv files for mean t-half and mobile fraction
outfilename_t = strcat(datafolderPath, string(datetime("today")), ...
    "-", genotype, "-tHalf.csv");
outfilename_mf = strcat(datafolderPath, string(datetime("today")), ...
    "-", genotype, "-mf.csv");

% Create output matrices to store t-half and mobile fraction
mf = nan(1, fileNum);
Thalf = nan(1, fileNum);

% Single exponential equation for recovery curve fitting
ft = fittype("a - b*exp(-c*x)");
% % Pre-check the coefficient names and order using the coeffnames function
% % In order a --> b --> c
% coeffnames(ft)

for csv = 1:fileNum
    currentfile = csvList{csv};
    % Create path to data file
    file = strcat(datafolderPath, currentfile);
    data = readmatrix(file);
    
    % Retrieve timestamps from the first column of each csv file
    ts = data(:, 1);

    % Find the number of replicates
    repNum = size(data, 2);

    % For each technical replicate, fit the normalised recovery curve from 
    % the first post-bleaching frame (Frame #6) with single exponential 
    % equation to retrieve coefficients
    for tr = 2:repNum
        trCount = tr - 1;
        recoverycurve = data(:, tr);
        [exp, gof] = fit(ts(bleachedFrame:end, 1), ...
            recoverycurve(bleachedFrame:end), ft, StartPoint = [0.7 1.5 0.05]);
        % mobile fraction = a
        % t-half = In(2)./c
        coeff = coeffvalues(exp);
        mf(trCount, csv) = coeff(1);
        Thalf(trCount, csv) = log(2)./coeff(3) + ts(bleachedFrame, 1);

        % Plot fitted curve
        mf_txt = sprintf("%s = %2.4f", "Mobile Fraction", mf(trCount, csv));
        thalf_txt = sprintf("%s = %2.4f", "T-half", Thalf(trCount, csv));
        figname = sprintf("%s %s%d-%d.png", datetime("today"), genotype, csv, trCount);
        figtitle = sprintf("%s %s%d-%d", "Fitted Curve:", genotype, csv, trCount);
        adjrsq_txt = sprintf("%s = %2.4f", "Adjusted R Squared", gof.adjrsquare);
        
        figure(1)
        plot(exp, ts(bleachedFrame:end, 1), recoverycurve(bleachedFrame:end))
        ylim([0, 1])
        legend("Location", "northeast")
        text(115, 0.2, mf_txt);
        text(115, 0.15, thalf_txt);
        text(115, 0.1, adjrsq_txt);
        ylabel("Mean Intensity - Full Scale Normalization")
        xlabel("Acquisition Time")
        title(figtitle)
        saveas(gcf, figname);
        close;
    end % for tr
end % for csv

% Write data matrix to output file
writematrix(mf, outfilename_mf);
writematrix(Thalf, outfilename_t);
end % for function