%% Modified by Adenine Koo, 2023, University of Wisconsin-Madison
% to read single channel image stacks from infile.nd2 movie
% Original function written by Joe Yeh, 2019

function finfo = nd2finfo(file)

fid = fopen(file, 'r');

% Each data segment begins with these signature bytes
sigbyte = [218, 206, 190, 10];
sigdim = length(sigbyte); % dimension/length of the signature bytes

count = 1;
fs = struct;
signature = fread(fid, sigdim, '*uint8')';
if ~isempty(signature) && sum(signature == sigbyte) == sigdim
    [fs, count, ~] = readHeader(fid, fs, count);
end

% Second segment always begins at 4096
SecondSegStart = 4096;
fseek(fid, SecondSegStart, 'bof');

flag = 0;
while flag == 0
    signature = fread(fid, sigdim, '*uint8')';
    if ~isempty(signature) && sum(signature == sigbyte) == sigdim
        [fs, count, flag] = readHeader(fid, fs, count);
        % Break once it reaches ImageDataSeq segment
        if strfind(fs(count-1).nameAttribute, 'ImageDataSeq')
            break;
        end
    else
        break
    end
end

% In a large file, there is often a seemingly random number of zeros
% between the ImageDataSeq segment and its following segment. Other
% segments usually don't have these randome padding bytes.
% Position the file pointer to the next segment over these padding zeroes
temp = fread(fid, 10000, '*uint8')';
NextSegIdx = strfind(temp, sigbyte);
fseek(fid, fs(count-1).dataStartPos + fs(count-1).dataLength + ...
    NextSegIdx(1)-1, 'bof');

flag = 0;
while flag == 0
    signature = fread(fid, sigdim, '*uint8')';
    if ~isempty(signature) && sum(signature == sigbyte) == sigdim
        [fs, count, flag] = readHeader(fid, fs, count);
    else
        break
    end
end

ImgAttributesIdx = [];
ImgDataSeqIdx = []; % Image data
ImgMetadataIdx = [];
ImgCalibrationIdx = [];
ImgTextInfoIdx = [];
for ii = 1:length(fs)
    if strfind(fs(ii).nameAttribute, 'ImageAttributesLV!')
        ImgAttributesIdx = [ImgAttributesIdx ii];
    elseif strfind(fs(ii).nameAttribute, 'ImageDataSeq')
        ImgDataSeqIdx = [ImgDataSeqIdx ii];
    elseif strfind(fs(ii).nameAttribute, 'ImageMetadataSeqLV')
        ImgMetadataIdx = [ImgMetadataIdx ii];
    elseif strfind(fs(ii).nameAttribute, 'ImageCalibration')
        ImgCalibrationIdx = [ImgCalibrationIdx ii];
    elseif strfind(fs(ii).nameAttribute, 'ImageTextInfo')
        ImgTextInfoIdx = [ImgTextInfoIdx ii];
    end
end

finfo = struct;
finfo.file_structure = fs;

% Note that for an image stack/movie, there are more than one section of
% Image Attributes and Image Metadata data
% This modified version of nd2finfo retrieves only the last section of data
% as these data is not used for Adenine's purpose

% Retrieve image information from the LAST Image Attribute Data Segment
AttIdx = ImgAttributesIdx(end); % change this index if other segment is required
fseek(fid, fs(AttIdx).dataStartPos, 'bof');
ImgAttributes = fread(fid, fs(AttIdx).dataLength, '*char')';
strloc(fid, fs, AttIdx, ImgAttributes, 'uiWidth');
finfo.img_width = fread(fid, 1, '*uint32');
strloc(fid, fs, AttIdx, ImgAttributes, 'uiHeight');
finfo.img_height = fread(fid, 1, '*uint32');
strloc(fid, fs, AttIdx, ImgAttributes, 'uiSequenceCount');
finfo.img_seq_count = fread(fid, 1, '*uint32');

% Retrieve image information from the LAST Image Metadata Data Segment
MetaIdx = ImgMetadataIdx(end); % change this index if other segment is required
fseek(fid, fs(MetaIdx).dataStartPos, 'bof');
Metadata = fread(fid, fs(MetaIdx).dataLength, '*char')';
strloc(fid, fs, MetaIdx, Metadata, 'XPos');
finfo.center_x = fread(fid, 1, 'float64');
strloc(fid, fs, MetaIdx, Metadata, 'YPos');
finfo.center_y = fread(fid, 1, 'float64');
strloc(fid, fs, MetaIdx, Metadata, 'dCalibration');
finfo.calib_factor = fread(fid, 1, 'float64');
strloc(fid, fs, MetaIdx, Metadata, 'dTimeMSec');
finfo.time = fread(fid, 1, 'float64');

ActiveChannelIdx = strfind(Metadata, addsinglespace('ChannelIsActive'));
finfo.ch_count = length(ActiveChannelIdx);

finfo.padding_bytes = fs(ImgDataSeqIdx(1)).dataLength - 8 - ...
    finfo.img_width * finfo.img_height *finfo.ch_count *2;
if finfo.padding_bytes == finfo.img_height * 2
    finfo.padding_style = 1;
elseif finfo.padding_bytes == 0
    finfo.padding_style = 2;
else
    finfo.padding_style = 3;
end

CaliIdx = ImgCalibrationIdx(1);
fseek(fid, fs(CaliIdx).dataStartPos, 'bof');
finfo.meta.img_calib = fread(fid, fs(CaliIdx).dataLength, '*char')';

TextIdx = ImgTextInfoIdx(1);
fseek(fid, fs(TextIdx).dataStartPos, 'bof');
finfo.meta.img_txt = fread(fid, fs(TextIdx).dataLength, '*char')';
finfo.meta.img_meta = Metadata;

fclose('all');

function [attrib, count, flag] = readHeader(fid, attrib, count)
attrib(count).nameLength = fread(fid, 1, 'uint32');
attrib(count).dataLength = fread(fid, 1, 'uint64');
attrib(count).nameAttribute = fread(fid, attrib(count).nameLength, '*char')';
attrib(count).dataStartPos = ftell(fid);
flag = fseek(fid, attrib(count).dataLength, 'cof');
count = count + 1;
end

function strwithSingleSpace = addsinglespace(str)
% Texts in ND2 file has monospace between characters.
% Eg: 'uiWidth' is encoded as 'u i W i d t h  '
% Note the double spaces at the end

% Convert str to char before converting to unicode/ASCII
unicodeValues = double(char(str));

% C = cat(dim, A, B) concatenates B to the end of A along dimension dim
% when A and B have compatible sizes (the lengths of the dimensions match
% except for the operating dimension dim).
% Add a second row of zeroes
addedzeroes = cat(1, unicodeValues, zeros(size(unicodeValues)));

% Reshape the 2-rows array into one row with zero (single space) in between
% characters
% Convert unicode back to char
strwithSingleSpace = char([reshape(addedzeroes, [1, length(unicodeValues)*2]), 0]);
end

function strloc(fid, fs, fsIdx, text, str)
Idx = strfind(text, addsinglespace(str)) + length(addsinglespace(str));
fseek(fid, fs(fsIdx).dataStartPos + Idx(1), 'bof');
end

end % for function nd2finfo