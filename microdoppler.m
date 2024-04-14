%%% This script is used to read the binary file produced by the DCA1000
%%% and Mmwave Studio
%%% Command to run in Matlab GUI -
%readDCA1000('<ADC capture bin file>') function [retVal] = readDCA1000(fileName)
clear
%% global variables
% change based on sensor config
numADCSamples = 128; % number of ADC samples per chirp
numLoops = 256; % number of chirps per frame
numADCBits = 16; % number of ADC bits per sample
numRX = 4; % number of receivers
numLanes = 2; % do not change. number of lanes is always 2
isReal = 0; % set to 1 if real only data, 0 if complex data0
fileName = 'adc_datacollection_64.bin';

%% read file
% read .bin file
fid = fopen(fileName,'r');
adcData = fread(fid, 'int16');
% if 12 or 14 bits ADC per sample compensate for sign extension
if numADCBits ~= 16
    l_max = 2^(numADCBits-1)-1;
    adcData(adcData > l_max) = adcData(adcData > l_max) - 2^numADCBits;
end
fclose(fid);
fileSize = size(adcData, 1);
% real data reshape, filesize = numADCSamples*numChirps
if isReal
    numChirps = fileSize/numADCSamples/numRX;
    LVDS = zeros(1, fileSize);
    %create column for each chirp
    LVDS = reshape(adcData, numADCSamples*numRX, numChirps);
    %each row is data from one chirp
    LVDS = LVDS.';
   else
    % for complex data
    % filesize = 2 * numADCSamples*numChirps
    numChirps = fileSize/2/numADCSamples/numRX;
    LVDS = zeros(1, fileSize/2);
    %combine real and imaginary part into complex data
    %read in file: 2I is followed by 2Q
counter = 1;
for i=1:4:fileSize-1
    LVDS(1,counter) = adcData(i) + sqrt(-1)*adcData(i+2); LVDS(1,counter+1) = adcData(i+1)+sqrt(-1)*adcData(i+3); counter = counter + 2;
end
% create column for each chirp
LVDS = reshape(LVDS, numADCSamples*numRX, numChirps);
%each row is data from one chirp
LVDS = LVDS.';
end
%organize data per RX
adcData = zeros(numRX,numChirps*numADCSamples);
for row = 1:numRX
    for i = 1: numChirps

    adcData(row, (i-1)*numADCSamples+1:i*numADCSamples) = LVDS(i, (row-1)*numADCSamples+1:row*numADCSamples);

end
end
% return receiver data
retVal = adcData;


numFrames = fileSize/(numADCSamples*numLoops*numRX*2); % number of captured frames


mean_adc = mean(adcData,1); % mean of raw data across receivers
data = reshape(mean_adc(1,:),numADCSamples,[]); % reshape data in to ADCxChirp form

%
% Calculate Range-doppler heatmap to construct micro-doppler map
%
udoppler = [];
bin_det = [];

% inefficient but finds the target bin BEFORE plotting of udoppler begins
% to be consistent 
%
for i = numFrames-1
    a = conj(data(1:numADCSamples, 1+(numLoops*i):numLoops+(numLoops*i))); % iterate through frames

    rangeWindow = hamming(size(a,1)); % hamming window for range
    dopplerWindow = hamming(size(a,2)); % hamming window for doppler

    a_windowed = (a .* rangeWindow) .* dopplerWindow'; % apply windowing to signal

    fft2da = fft2(a_windowed); % 2d fft on matrix
    fft2da_shifted = fftshift(fft2da,2); % center frequencies at 0

    [a_avg, target_bin] = max(fft2da_shifted);
    bin_det = [bin_det  target_bin]; % bins with "detections"
    target = mode(bin_det) % target bin = most reoccuring bin
end

for i = 0:(numFrames)-1
   
    a = conj(data(1:numADCSamples, 1+(numLoops*i):numLoops+(numLoops*i))); % iterate through frames

    rangeWindow = hamming(size(a,1)); % hamming window for range
    dopplerWindow = hamming(size(a,2)); % hamming window for doppler

    a_windowed = (a .* rangeWindow) .* dopplerWindow'; % apply windowing to signal

    fft2da = fft2(a_windowed); % 2d fft on matrix
    fft2da_shifted = fftshift(fft2da,2); % center frequencies at 0

    nrows = size(fft2da_shifted,1);
    ncols = size(fft2da_shifted,2);

    mag_a = abs(fft2da_shifted)/(nrows*ncols); % complex magnitude
    mag_a_db = mag2db((mag_a)); % convert to dB

    % [a_avg, target_bin] = max(mag_a);
    % bin_det = [bin_det  target_bin]; % bins with "detections"
    % target = mode(bin_det) % target bin = most reoccuring bin
    
    udoppler = [udoppler mean(mag_a_db(target-2:target+2,:),1)']; % write micro-doppler -> columns doppler profile along chosen range bin

end 
    
    figure(5)
    imagesc([-127 127],0,mag_a_db);
    colorbar
    xlabel('Doppler Bin');
    ylabel('Range Bin');
    title('Range-Doppler Plot');
    

    figure(6)
    imagesc([0 100],[-127 127],udoppler);
    xlabel('Frame');
    ylabel('Doppler Bin');
    title('Micro-doppler plot');


% different visualization of range-doppler (effectively the same)

% figure(7)
% 
%  [axh] = surf([1:numLoops],[1:numADCSamples],mag_a_db);
%  axis([0 numLoops-1 0 numADCSamples-1])
%  view(0,90)
%  grid off
%  shading interp
%  xlabel('Doppler Velocity (m/s)')
%  ylabel('Range(meters)')
%  colorbar
%  title('Range-Doppler heatmap')





