%% Copyright: Adenine Koo, 2023, University of Wisconsin-Madison
% Email : skoo8@wisc.edu

%% This function stabilises slight "frameshift" during recording 
% by finding the best window that results in the highest correlation of 
% the targetCell from refImage in the currentImage by a buffer size 
% specified by the user

% buffer: the number of pixels used for sliding window
% E.g.: buffer == 5, the function moves the window the size of targetCell 
% one-by-one pixel for a total of 5 pixels from the centre to each 
% direction (up, down, left and right) in currentImage and calculate the 
% correlation between targetCell and the current window

% The function returns the coordinates of the window that results in the
% highest correlation value


function [bestdoughnutYCoor, bestdoughnutXCoor, maxCorr] = ...
    motioncorrect(currentImage, targetCell, doughnutYCoor, doughnutXCoor, buffer)

% test code:
% currentImage = [0 0 0 0 0 0 0 0 0 0;
%                 0 0 0 1 0 0 0 0 0 0;
%                 0 0 1 0 1 0 0 0 0 0;
%                 0 0 0 1 0 0 0 0 0 0;
%                 0 0 0 0 0 0 0 0 0 0;
%                 0 0 0 0 0 0 0 0 0 0];
% doughnutYCoor = [3 5];
% doughnutXCoor = [2 4];
% buffer = 1;

targetWidth = doughnutXCoor(2) - doughnutXCoor(1);
targetHeight = doughnutYCoor(2) - doughnutYCoor(1);

x1 = doughnutXCoor(1) - buffer;
y1 = doughnutYCoor(1) - buffer;
x2 = doughnutXCoor(2) + buffer;
y2 = doughnutYCoor(2) + buffer;

row = x2 - x1 - targetWidth + 1; % numbers of iteration
col = y2 - y1 - targetHeight + 1;

% An array to tabulate all the corr coef calculated from each frame
corrAry = nan(row, col);

% Get the target cell from the reference frame where the cell's pixel 
% region was first identified

% test code:
% targetCell = [0 1 0;
%               1 0 1;
%               0 1 0];
% targetCell = currentImage(doughnutYCoor(1):doughnutYCoor(2), doughnutXCoor(1):doughnutXCoor(2));
for N = 1:row
    y3 = y1 + N - 1; % starting x- and y-coor (each minus (-) 1 as the for loop starts counting at 1)
    y4 = y3 + targetHeight;
    for M = 1:col
        x3 = x1 + M - 1;
        x4 = x3 + targetWidth;
        corrAry(N, M) = corr2(targetCell, currentImage(y3:y4, x3:x4));
    end % for M
end % for N
[maxCorr, maxIdx] = max(corrAry, [], "all"); % the maximum value of the corr coef calculated
% maxIdx is a linear index, counted along the columns.
bestX = ceil(maxIdx./col);
bestY = rem(maxIdx, col);

bestdoughnutYCoor = nan(1, 2);
bestdoughnutXCoor = nan(1, 2);

bestdoughnutYCoor(1) = y1 + bestY - 1;
bestdoughnutXCoor(1) = x1 + bestX - 1;
bestdoughnutYCoor(2) = bestdoughnutYCoor(1) + targetHeight;
bestdoughnutXCoor(2) = bestdoughnutXCoor(1) + targetWidth;

end % for function motioncorrect()