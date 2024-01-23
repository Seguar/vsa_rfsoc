function iqpicspec(varargin)
%
% Convert an image into an AWG signal that can be viewed as a spectrogram
% Requires sequence functionality in the AWG.
% Works on M8195A in deep memory mode and M8190A in 12- or 14-bit direct mode
%
% Parameters are passed as property/value pairs. Properties are:
% 'filename'   - name of the .JPG file to be converted. A good size is 200x150 pixel
% 'sampleRate' - sample rate of the AWG in Hz (if not specified, the
%                default sample rate for the AWG will be used)
% 'startFreq'  - start frequency (the frequency that will actually be used can
%                deviate from the specified value)
% 'stopFreq'   - stop frequency (the frequency that will actually be used can
%                deviate from the specified value)
% 'duration'   - overall duration of the playback in seconds (default: 30 sec)
% 'numSamples' - number of samples per segment (default: 65536)
% 'dynamic'    - dynamic range in dB. The dynamic range of the image will be
%                mapped to the specified dynamic range in dB. (default: 50)
% 'chMap'      - channel mapping - if startFreq and stopFreq >= 0, defaults to [1 0],
%                which downloads the real part of the signal to channel 1.
%                if either start or stopFreq < 0, then the default is [1 0; 0 1],
%                i.e. real part to channel 1, imaginary part to channel 2
% 'blankLines' - add N blank lines at the end of the image (default: 0)
% 'blankValue' - the "color" of the blank lines, must be between 0 and 1 (default: 0)
% 'invert'     - invert the image
% 'doDownload' - 0:display 1:download (default: 1)

%
% T.Dippon, Keysight Technologies 2020
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS.


if (nargin == 0)
    iqpicspec_gui;
    return;
end
arbConfig = loadArbConfig();
sampleRate = [];
duration = 30;
startFreq = 1e9;
stopFreq = 2e9;
numSamples = 65536;
dynamic = 50;
filename = [];
chMap = [];
blankLines = 0;
blankValue = 0;
invert = 0;
doDownload = 1;
sequenceOnly = 0;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'startfreq';      startFreq = varargin{i+1};
            case 'stopfreq';       stopFreq = varargin{i+1};
            case 'duration';       duration = varargin{i+1};
            case 'numsamples';     numSamples = varargin{i+1};
            case 'dynamic';        dynamic = varargin{i+1};
            case 'arbconfig';      arbConfig = varargin{i+1};
            case 'filename';       filename = varargin{i+1};
            case 'chmap';          chMap = varargin{i+1};
            case 'blanklines';     blankLines = varargin{i+1};
            case 'blankvalue';     blankValue = varargin{i+1};
            case 'invert';         invert = varargin{i+1};
            case 'dodownload';     doDownload = varargin{i+1};
            case 'sequenceonly';   sequenceOnly = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
if (isempty(sampleRate))
    sampleRate = arbConfig.defaultSampleRate;
end
if (isempty(filename))
    filename = fullfile(fileparts(which('iqpicspec.m')), 'example.jpg');
end
if (isempty(chMap))
    if (min(startFreq, stopFreq) < 0)
        chMap = [1 0; 0 1];
    else
        chMap = [1 0];
    end
end
try
    [~, ~, ext] = fileparts(filename);
    pic = imread(filename, ext(2:end));
catch ex
    errordlg(sprintf('Cannot open: %s', filename));
    return;
end
picGrey = double(pic);
% change to greyscale
if (size(picGrey,3) > 1)
    picGrey = sum(picGrey,3) / size(picGrey,3);
end
% scale to [0...1]
maxVal = max(max(picGrey));
minVal = min(min(picGrey));
picGrey = (picGrey - minVal) ./ (maxVal - minVal);
% invert, if requested
if (invert)
    picGrey = 1 - picGrey;
end
% add blanking if desired
if (blankLines > 0)
    picGrey(end+1,:) = repmat(blankValue, 1, size(picGrey,2));
end
% width and height (make sure this is done after the blanking line has been added
width = size(picGrey,2);
height = size(picGrey,1);
% convert to log scale
picLog = 10.^((picGrey - 1)*dynamic/20);

% calculate the center frequency and corresponding frequency bin
fCenter = (stopFreq + startFreq) / 2;
centerBin = round(fCenter / sampleRate * numSamples) + numSamples / 2;
% make sure we use the same number of frequency bins between the points
binStep = round((stopFreq - startFreq) / sampleRate * numSamples / (width - 1));
if (binStep < 1)
    errordlg('Horizontal image resolution is too high. Please reduce horizontal resolution or increase the frequency range');
    return;
end
startBin = round(centerBin - binStep * (width-1) / 2);
stopBin = round(centerBin + binStep * (width-1) / 2);

% signal in frequency domain
fsig = zeros(numSamples, 1);
% array of bin indices
fIdx = startBin:binStep:stopBin;
if (min(fIdx) < 1) || (max(fIdx) > numSamples)
    errordlg('Start/Stop frequency out of range (-Fs/2 ... +Fs/2)');
    return;
end

% check, if display only
if (~doDownload)
    figure(1);
    image(255*picGrey);
    return;
end

% determine a set of phases with low crest factor
bestSig = [];
bestPhasors = [];
bestCrest = 999;
for i = 1:500
    tmpPhasors = exp(1i*rand(width,1)*2*pi);
    fsig(fIdx) = tmpPhasors;
    tmpSig = ifft(fftshift(fsig));
    tmpCrest = max(abs(tmpSig)) / norm(tmpSig) * sqrt(length(tmpSig));
    if (tmpCrest < bestCrest)
        bestCrest = tmpCrest;
        bestPhasors = tmpPhasors;
        bestSig = tmpSig;
    end
end

% scale the waveform such that they never exceed the DAC range
scale = max(max(real(bestSig)), max(imag(bestSig)));
bestPhasors = bestPhasors / scale;

% download to the AWG and create sequence
hMsgBox = iqwaitbar('Downloading, please wait...');
clear seq;
iqseq('delete', []);
userBreak = 0;
loops = round(duration / height / (numSamples / sampleRate));
for row = 1:height
    if (~sequenceOnly)
        fsig(fIdx) = picLog(row,:)' .* bestPhasors;
        sig = ifft(fftshift(fsig));
        iqdownload(sig, sampleRate, 'segmentNumber', row, 'channelMapping', chMap);
        hMsgBox.update(row/height);
        if (hMsgBox.canceling())
            userBreak = 1;
            break;
        end
    end
    seq(row).segmentNumber = row;
    % loop the last waveform segment <blankLines> times
    if (blankLines > 0 && row == height)
        seq(row).segmentLoops = blankLines * loops;
    else
        seq(row).segmentLoops = loops;
    end
end

if (~userBreak)
    seq(1).sequenceInit = 1;
    seq(height).sequenceEnd = 1;
    seq(height).scenarioEnd = 1;
    % define sequence and start AWG
    iqseq('define', seq, 'channelMapping', chMap);
    iqseq('mode', 'STSC', 'channelMapping', chMap);
end
delete(hMsgBox);
