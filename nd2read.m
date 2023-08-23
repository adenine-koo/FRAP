%% Modified by Adenine Koo, 2023, University of Wisconsin-Madison
% to read single channel image stacks from infile.nd2 movie
% Original function written by Joe Yeh, 2019

%% For this function to work, user must also have these functions in
% the working directory:
% 1. nd2finfo.m

%% This modified version of nd2read is not tested with images comprising 
% more than one channel --> ChannelNum == 1 for Adenine's purpose

function [Ch1, Ch2, Ch3] = nd2read(file)
finfo = nd2finfo(file);

fid = fopen(file, 'r');
% Find the indices to ImageDataSeq segments from fs/file structure
segofInterest = 'ImageDataSeq';
n = length(segofInterest);
% tf = strncmp(s1, s2, n) compares up to n characters of s1 and s2.
% The function returns 1 (true) if the two are identical and 0 (false)
% otherwise.
ImageDataTF = strncmp(segofInterest, {finfo.file_structure(:).nameAttribute}, 12);
ImageDataIdx = find(ImageDataTF);
% Number of images
ImageNum = sum(ImageDataTF);
ImageWidth = finfo.img_width; % first dimension of the encoded data
ImageHeight = finfo.img_height;
% Number of channel
ChannelNum = finfo.ch_count;

if ChannelNum == 1
    Ch1 = zeros(ImageWidth, ImageHeight, ImageNum, 'uint16');
    Ch2 = NaN;
    Ch3 = NaN;
elseif ChannelNum == 2
    Ch1 = zeros(ImageWidth, ImageHeight, ImageNum, 'uint16');
    Ch2 = Ch1;
    Ch3 = NaN;
elseif ChannelNum == 3
    Ch1 = zeros(ImageWidth, ImageHeight, ImageNum, 'uint16');
    Ch2 = Ch1;
    Ch3 = Ch1;
end % if ChannelNum

for ii = 1:ImageNum
    currentImageIdx = ImageDataIdx(ii);
    % Somehow the data starts at +8 position, not sure why.
    pointerLocation = finfo.file_structure(currentImageIdx).dataStartPos + 8;
    fseek(fid, pointerLocation, 'bof');
    % nd2 encodes pixel values of image row-by-row, ImageWidth is the
    % first dimension of data
    % If there is more than one channel, nd2 groups data by pixels
    % Eg.: [Pixel1Ch1 Pixel1Ch2 Pixel2Ch1 Pixel2Ch2 Pixel3Ch1
    %       Pixel3Ch2];
    if ChannelNum == 1
        for col = 1:ImageHeight
            Ch1(:, col, ii) = fread(fid, ImageWidth, '*uint16');
        end % for col
    elseif ChannelNum == 2
        for col = 1:ImageHeight
            temp = reshape(fread(fid, ChannelNum.*ImageWidth, '*uint16'), [ChannelNum ImageWidth]);
            Ch1(:, col, ii) = temp(1, :);
            Ch2(:, col, ii) = temp(2, :);
        end % for col
    elseif ChannelNum == 3
        for col = 1:ImageHeight
            temp = reshape(fread(fid, ChannelNum.*ImageWidth, '*uint16'), [ChannelNum ImageWidth]);
            Ch1(:, col, ii) = temp(1, :);
            Ch2(:, col, ii) = temp(2, :);
            Ch3(:, col, ii) = temp(3, :);
        end % for col
    end % if ChannelNum
end % for image

fclose(fid);

% permute(A, [2 1]) switches the row and column dimensions of a matrix A.
if exist("Ch1", 'var')
    Ch1 = permute(Ch1, [2 1 3]);
    Ch1 = Ch1.*16;
end

if exist("Ch2", 'var')
    Ch2 = permute(Ch2, [2 1 3]);
    Ch2 = Ch2.*16;
end

if exist("Ch3", 'var')
    Ch3 = permute(Ch3, [2 1 3]);
    Ch3 = Ch3.*16;
end
end % for function nd2read