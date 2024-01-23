function [samples, sampleRate, numBits, numSamples, channelMapping, data] = iserial(varargin)
% This function generates a waveform from a digital data stream
% and adds selected distortions
%
% Parameters are passed as property/value pairs. Properties are:
% 'dataRate' - data rate in symbols/s
% 'transitionTime' - rise/fall time in UI (default: 0.5)
% 'numBits' - number of symbols to be generated
% 'symbolShift' - shift the data pattern by this number of symbols
%               this is useful to have uncorrelated PRBS patterns on
%               multiple channels
% 'data' - can be 'clock', 'random', 'MLT-3', 'PAM3', 'PAM4', 'PAM5'
%        'PRBS7', 'PRBS9', 'PRBS11', 'PRBS12', 'PRBS15' or a vector of values in the
%        range [0...1]
% 'format' - 'NRZ' or 'PAM4' --> data format for PRBS'es and Random
% 'noise' - amount of noise added, range [0...1] (default: 0)
% 'noiseFreq' - frequency of the noise in Hz or zero for gaussian noise
% 'isi' - amount of ISI in the range [0...1] (default = 0)
% 'jitterShape' - can be 'sine', 'square', 'ramp', 'triagle', 'noise'
% 'SJfreq' - sinusoidal jitter frequency in Hz (default: no jitter)
% 'SJpp' - sinusoidal jitter in UI
% 'RJpp' - 6-sigma value in UI
% 'sampleRate' - sample rate in Hz (if zero or not specified, the
%                default sample rate for the selected AWG is used
% 'amplitude' - data will be in the range (-ampl...+ampl) + noise
% 'dutyCycle' - will skew the duty cycle (default: 0.5)
% 'correction' - apply frequency/phase response correction
% 'precursor' - list of values in dB (default: empty)
% 'postcursor' - list of values in dB (default: empty)
% 'nowarning' - can be set to 1 to suppress warning messages (default: 0)
% 'normalize' - can be set to 0 to avoid automatic scaling to +/- 1 after freq/phase response corrections (default: 1)
% 'channelMapping' - channel mapping (see iqdownload.m for details)
%
% If called without arguments, opens a graphical user interface to specify
% parameters

% T.Dippon, Keysight Technologies 2011-2017
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

%% if called without arguments, open the GUI
if (nargin == 0)
    iserial_gui;
    return;
end
% set default parameters
arbConfig = [];
samples = [];
sampleRate = 0;
dataRate = 1e9;
rtUI = 0.5;
ftUI = 0.5;
ttProp = 0;
filterType = 'Transition Time';
filterNsym = 20;
filterBeta = 1;
numBits = -1;
numSamples = 0;
symbolShift = 0;
data = 'random';
format = 'NRZ';
fct = 'display';
filename = [];
isi = 0;
jitterShape = 'sine';
SJfreq = 10e6;
SJpp = 0;
RJpp = 0;
noise = 0;
noiseFreq = 20e6;
amplitude = 1;
dutyCycle = 0.5;
preCursor = [];
postCursor = [];
nowarning = 0;
correction = 0;
sscFreq = 0;
sscDepth = 0;
sscShape = 'triangleCenter';
levels = [0 1/3 2/3 1];
normalize = 1;
channelMapping = [1 0];
useM8196RefClk = 0;
% parse input parameters
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'arbconfig';      arbConfig = varargin{i+1}; 
            case 'datarate';       dataRate = varargin{i+1};
            case 'ttproportional'; ttProp = varargin{i+1};
            case 'transitiontime'; tmp = varargin{i+1}; rtUI = tmp(1); ftUI = tmp(end);
            case 'risetime';       rtUI = varargin{i+1};
            case 'falltime';       ftUI = varargin{i+1};
            case 'filtertype';     filterType = varargin{i+1};
            case 'filternsym';     filterNsym = varargin{i+1};
            case 'filterbeta';     filterBeta = varargin{i+1};
            case 'numbits';        numBits = varargin{i+1};
            case 'symbolshift';    symbolShift = varargin{i+1};
            case 'data';           data = varargin{i+1};
            case 'format';         format = varargin{i+1};
            case 'function';       fct = varargin{i+1};
            case 'filename';       filename = varargin{i+1};
            case 'levels';         levels = varargin{i+1};
            case 'isi';            isi = varargin{i+1};
            case 'noisefreq';      noiseFreq = varargin{i+1};
            case 'noise';          noise = varargin{i+1};
            case 'jittershape';    jitterShape = varargin{i+1};
            case 'sjfreq';         SJfreq = varargin{i+1};
            case 'sjpp';           SJpp = varargin{i+1};
            case 'rjpp';           RJpp = varargin{i+1};
            case 'sscfreq';        sscFreq = varargin{i+1};
            case 'sscdepth';       sscDepth = varargin{i+1};
            case 'sscshape';       sscShape = varargin{i+1};
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'amplitude';      amplitude = varargin{i+1};
            case 'dutycycle';      dutyCycle = varargin{i+1};
            case 'precursor';      preCursor = varargin{i+1};
            case 'postcursor';     postCursor = varargin{i+1};
            case 'nowarning';      nowarning = varargin{i+1};
            case 'correction';     correction = varargin{i+1};
            case 'normalize';      normalize = varargin{i+1};
            case 'channelmapping'; channelMapping = varargin{i+1};
            case 'usem8196refclk'; useM8196RefClk = varargin{i+1};
            case 'prbspolyuser' ;   prbsPolyUser = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
% make sure that SJfreq and SJpp have the same length
numSJ = max(length(SJfreq), length(SJpp));
SJfreq = fixlength(SJfreq, numSJ);
SJpp = fixlength(SJpp, numSJ);

if (numBits < 0)
    numBits = length(data);
end

arbConfig = loadArbConfig(arbConfig);
% remember the number of symbols, so that we can output a warning when the
% number of symbols needs to be changed
numBitsOld = numBits;

if (sampleRate ~= 0)    % sample rate is defined by the user
    fsApprox = sampleRate;
    % if sample rate AND data rate are given, round the number of bits
    % to match the granularity requirement
    [~, d] = rat(fsApprox / dataRate / arbConfig.segmentGranularity);
    numBits = ceil(numBits / d) * d;
    if (useM8196RefClk)
        [~,d] = rat(dataRate / (fsApprox/32));
        if (d ~= 1)
            warndlg('With this combination of sample rate and data rate, the RefClkOut signal is not synchronous to the data rate. Please turn on the "Auto" sample rate');
        end
    end
else
    if (~isempty(strfind(arbConfig.model, 'M8199B')))
        f = iqopen(arbConfig);
        % find module driver version
        try
            infJson = xquery(f, sprintf(':SYST:INF:DET:JSON? "%s"', arbConfig.M8070ModuleID));
        catch ex
            iqreset();
            error(['Can not communicate with M8070B. Please try again. ' ...
                'If this does not solve the problem, exit and restart MATLAB. ' ...
                '(Error message: ' ex.message ')']);
        end
        try
            info = jsondecode(infJson);
        catch
            error('Cannot decode module driver information. Please check if all modules in Instrument Configuration are available!');
        end
        if (isfield(info, 'Options'))
            if (~isempty(find(contains(info.Options,'S01'), 1)) && isempty(find(contains(info.Options,'256'), 1))) || (~isempty(find(contains(info.Options,'S02'), 1)) && isempty(find(contains(info.Options,'256'), 1)))
                arbConfig.defaultSampleRate = 224e9;
                arbConfig.maximumSampleRate = 224e9;
            end
        end
    end
    % sample rate automatic --> start with the default sample rate
    fsApprox = arbConfig.defaultSampleRate;
    if (useM8196RefClk)
        % configure RefClk Out
        if (~isempty(strfind(arbConfig.model, 'M8196A')))
            if (strcmp(fct, 'download'))
                f = iqopen(arbConfig);
                if (~isempty(f))
                    xfprintf(f, ':SOUR:ROSC:RANG RANG1;:SOUR:ROSC:SOUR INT;:OUTP:ROSC:SOUR SCLK1');
                    xfprintf(f, ':OUTP:ROSC:SCD 1');
                    iqclose(f);
                end
            end
        else
            errordlg('useM8196ARefClk is only supported with when M8196A is selected');
        end
        % calculate fs and number of symbols
        trigFactor1 = ceil(dataRate / arbConfig.maximumSampleRate * 32);
        trigFactor2 = floor(dataRate / arbConfig.minimumSampleRate * 32);
        fsApprox = dataRate / trigFactor1 * 32;
        if (fsApprox < arbConfig.minimumSampleRate)
            dr1 = trigFactor1 * arbConfig.minimumSampleRate / 32;
            dr2 = trigFactor2 * arbConfig.maximumSampleRate / 32;
            if (abs(dr1 - dataRate) < abs(dr2 - dataRate))
                suggestedDR = dr1;
            else
                suggestedDR = dr2;
            end
            errordlg(sprintf(['This symbol rate can not be generated with the M8196A with RefClkOut being an integer fraction of the symbol rate. ' ...
                'The closest supported data rate is %s GBaud'], iqengprintf(suggestedDR/1e9)));
            return;
        end
        [~, d] = rat(fsApprox / dataRate / arbConfig.segmentGranularity);
        numBits = ceil(numBits / d) * d;
    end
end
% approximate number of samples per bit
spbApprox = fsApprox / dataRate;

if (~ischar(data))    % PTRN or User defined data 
    reqMinBits = ceil(arbConfig.minimumSegmentSize / spbApprox);
    if length(data) < reqMinBits    %% if length is less than required then 
        NoCopies = ceil(reqMinBits/length(data));
        if (iscolumn(data))
            data = repmat(data, NoCopies, 1);
        else
            data = repmat(data, 1, NoCopies);
        end
    end
    maxSymbols = floor(arbConfig.maximumSegmentSize / spbApprox);
    if length(data) > maxSymbols    % if length is exceeded 
        data = data(1:maxSymbols);  % then truncate to adjust the length
    end
    if (numBits ~= length(data))
        if (useM8196RefClk)
            NoCopies = ceil(numBits / length(data));
            if (iscolumn(data))
                data = repmat(data, NoCopies, 1);
            else
                data = repmat(data, 1, NoCopies);
            end
            data = data(1:numBits);
        else
            numBits = length(data);
        end
    end
end

% check if the number of bits is large enough to find a valid sample rate
if (arbConfig.maximumSampleRate == arbConfig.minimumSampleRate)
    factor = 1;
else
    factor = ceil(arbConfig.segmentGranularity / numBits * dataRate / (max(arbConfig.maximumSampleRate) - max(arbConfig.minimumSampleRate)));
end
newFs = round((spbApprox * numBits) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity / numBits * dataRate;
if (factor > 1 && (newFs > max(arbConfig.maximumSampleRate) || newFs < max(arbConfig.minimumSampleRate)))
    if (~ischar(data))
%        errordlg(['waveform too short - adjust number of symbols to at least ' num2str(ceil(arbConfig.minimumSegmentSize * dataRate / max(arbConfig.maximumSampleRate)))]);
        errordlg(['waveform too short - adjust number of symbols to at least ' num2str(numBits*factor)]);
        return;
    end
    numBits = numBits * factor;
end
if (numBits ~= numBitsOld && nowarning == 0)
    hWarnDlg = warndlg(['The number of symbols has been adjusted to ' num2str(numBits) ' to match waveform granularity and sample rate limitations']);
    pause(2);
    try
        delete(hWarnDlg);
    catch
    end
end
% calculate the number of samples to match segment granularity
numSamples = round((spbApprox * numBits) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
% rounding might bring the the sample rate above the maximum
if (numSamples / numBits * dataRate > max(arbConfig.maximumSampleRate))
    numSamples = numSamples - arbConfig.segmentGranularity;
end
% ...or below the minimum
% if (numSamples / numBits * dataRate < max(arbConfig.minimumSampleRate))
%     numSamples = numSamples + arbConfig.segmentGranularity;
% end
if (numSamples < arbConfig.minimumSegmentSize && ~nowarning)
    if (sampleRate == 0)
        minWfmLen = ceil(arbConfig.minimumSegmentSize * dataRate / max(arbConfig.maximumSampleRate));
    else
        minWfmLen = ceil(arbConfig.minimumSegmentSize * dataRate / sampleRate);
    end
    errordlg(['Waveform too short - adjust number of symbols to at least ' iqengprintf(minWfmLen)]);
    return;
end
if (numSamples > arbConfig.maximumSegmentSize && ~nowarning)
    if (sampleRate == 0)
        maxWfmLen = floor(arbConfig.maximumSegmentSize * dataRate / max(arbConfig.minimumSampleRate));
    else
        maxWfmLen = floor(arbConfig.maximumSegmentSize * dataRate / sampleRate);
    end
    errordlg(['Waveform too long - adjust number of symbols to no more than ' iqengprintf(maxWfmLen)]);
    return;
end
% calculate exact spb (will likely be NOT an integer value)
spb = numSamples / numBits;
if (sampleRate == 0)
    sampleRate = spb * dataRate;
end

% for large data sets, perform block-wise operation
if (numSamples > 8000000)
    if (~strcmp(filterType, 'Transition Time'))
        errordlg('Block-wise processing of very large waveforms is only implemented with pulse shape set to "Transition Time"');
        return;
    end
    if (~isempty(preCursor) || (~isempty(postCursor) && ~isequal(postCursor, 1)))
        errordlg('Pre-/Postcursors are currently not supported in conjunction with block-wise processing of very large waveforms');
        return;
    end
    if (SJpp ~= 0 && SJfreq ~= 0 || RJpp ~= 0 || sscDepth ~= 0 || noise ~= 0 || dutyCycle ~= 0.5)
        errordlg('Jitter, noise and duty cycle distortion are currently not supported in conjunction with block-wise processing of very large waveforms');
        return;
    end
    if (ischar(data) && strncmp(data, 'PRBS', 4))
        iseriallarge(arbConfig, dataRate, spb, data, numBits, format, fct, filename, correction, rtUI, amplitude, arbConfig.segmentGranularity);
    else
        errordlg('Block-wise processing of very large waveforms is only supported with PRBS patterns');
    end
    return;
end

% use the same sequence every time so that results are comparable
randStream = RandStream('mt19937ar'); 
reset(randStream);

if (ischar(data))
    prbsPoly = [];
    switch(lower(data))
        case 'clock'
            if (mod(numBits, 2) ~= 0)
                errordlg('Clock pattern requires an even number of bits');
            end
            data = repmat([0 1], 1, ceil(numBits / 2));
        case 'random'
            if (strcmp(format, 'NRZ'))
                data = randStream.randi([0 1], 1, numBits);
            else
                data = levels(randStream.randi([1 length(levels)], 1, numBits));
            end
        case 'mlt-3'
            mltCode = [levels(2) levels(1) levels(2) levels(3)];
            data = mltCode(mod(cumsum(randStream.randi([0 1], 1, numBits)), 4) + 1);
        case 'pam3'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam4'
            prbsPoly = [11 9 0];
            format = 'PAM4';
        case 'pam5'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam6'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam7'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam8'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam16'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam32'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'pam64'
            data = levels(randStream.randi([1 length(levels)], 1, numBits));
        case 'prbs2^7-1'
            prbsPoly = [7 3 0];   % alternative [7 1 0]
        case 'prbs2^9-1'
            prbsPoly = [9 4 0];
        case 'prbs2^10-1'
            prbsPoly = [10 3 0];
        case 'prbs2^11-1'
            prbsPoly = [11 2 0];
        case 'prbs2^12-1'
            prbsPoly = [12 11 8 6 0]; % alternative [12 6 4 1 0]
%         case 'prbs2^12-1'
%             prbsPoly = [12 6 4 1 0]; % alternative [12 11 8 6 0]
        case 'prbs2^13-1'
            prbsPoly = [13 12 11 1 0]; % alternative [13 12 10 9 0];
        case 'prbs2^15-1'
            prbsPoly = [15 1 0];
        case 'doublet'
            if (mod(numBits, 2) ~= 0)
                errordlg('Doublet pattern requires an even number of bits');
                return;
            end
            data = randStream.rand(1,ceil(numBits/2)) < 0.5;
            data(2,:) = 1-data(1,:);
            data = data(1:end);
        case 'jp03b'
            data = repmat([repmat([1 0], 1, 15) repmat([0 1], 1, 16)], 1, ceil(numBits/62));
            data = data(1:numBits);
        case 'linearitytestpattern'
            data = levels(repmat([1 2 3 4 1 4 1 4 3 2], 16, ceil(numBits/160)));
            data = data(1:numBits);
        case 'ssprq'
            data = ssprq(numBits, levels);
        case 'qprbs13'
            data = qprbs13(numBits, levels);
        case 'prbs13q gray coded'
            data = prbs13q(numBits, levels);
        case 'qprbs13 rz'
            if (mod(numBits, 2) ~= 0)
                errordlg('QPRBS13 RZ pattern requires an even number of bits');
            end
            data = qprbs13(ceil(numBits/2), levels);
            data = [data; zeros(1, ceil(numBits/2))];
            data = data(1:numBits);
        case 'qprbs13 r1/2'
            if (mod(numBits, 2) ~= 0)
                errordlg('QPRBS13 R1/2 pattern requires an even number of bits');
            end
            data = qprbs13(ceil(numBits/2), levels);
            data = [data; 0.5 * ones(1, ceil(numBits/2))];
            data = data(1:numBits);
        case 'qprbs13 user defined levels'
            data = qprbs13(numBits, levels);
        case 'dual pam4'
            data1 = floor(4 * randStream.rand(1,numBits)) / 6;
            data2 = floor(4 * randStream.rand(1,numBits)) / 6;
            data = data1 + data2;
        case 'custom pam4 lfsr' 
            data = customLFSR(levels);
        case 'sspr (oif-cei-04.0)'
            data = SSPR(numBits);
        otherwise
            errordlg(['undefined data pattern: ' data]);
            return;
    end
    if (~isempty(prbsPoly))
        if exist('prbsPolyUser', 'var') 
            prbsPoly = prbsPolyUser;
        end
        if (strcmp(format, 'PAM4'))
            h = comm.PNSequence('Polynomial', prbsPoly, 'SamplesPerFrame', 2*numBits, 'InitialConditions', [zeros(1,prbsPoly(1)-1), 1]);
            data = 1 - flipud(h.step())';
%             h = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 2*numBits);
%             data = h.generate()';
%            % apply a gray mapping (00 01 11 10)
%            mapping = [0 1 3 2]+1;
%--- gray mapping is now applied by setting the levels to 0  1/3  1  2/3
%--- this makes it more obvious to the user, that we are using gray coding
            mapping = [0 1 2 3]+1;
            data = levels(mapping(2 * data(1:2:end-1) + data(2:2:end) + 1));
        else
            h = comm.PNSequence('Polynomial', prbsPoly, 'SamplesPerFrame', numBits, 'InitialConditions', [zeros(1,prbsPoly(1)-1), 1]);
            data = h.step()';
%             h = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', numBits);
%             data = h.generate()';
        end
    end
elseif (isvector(data))
    numBits = length(data);
else
    error('unexpected data type');
end
% make sure the data is in the correct format
if (isvector(data) && size(data,1) > 1)
    data = data.';
end
% shift by the specifed number of symbols
data = circshift(data, symbolShift, 2);
% assign variable in base workspace - mainly for testing purposes
assignin('base', 'data', data);

% apply pre/post-cursors
if (~isempty(preCursor) || (~isempty(postCursor) && ~isequal(postCursor, 1)))
    % make sure pre- and postCursor are row-vectors (same "shape" as data)
    preCursor = reshape(preCursor, 1, length(preCursor));
    postCursor = reshape(postCursor, 1, length(postCursor));
    coeff = [preCursor postCursor];
    % normalize filter to keep amplitude -- but maybe that is desired
    % coeff = coeff / sum(coeff);
    len = length(coeff);
    if (length(data) >= len)
        % prepend and append <len> symbols of data to avoid wrap-around artefacts
        data2 = [zeros(1, len) data(end - len + 1:end) data data(1:len) zeros(1, len)];
        % shift data to [-1...+1], apply filter and shift back to [0...1]
        data2 = (filter(coeff, 1, 2*data2-1)+1)/2;
        % throw away the extra symbols that have been prepended and appended
        data = data2(2*len+1:end-2*len);
        % circular shift to compensate filter delay
        lenPre = length(preCursor);
        if (lenPre > 0)
            data = circshift(data, -lenPre);
        end
    else
        errordlg('data vector is too short to apply pre/postcursors');
    end
end

% convert transition time in number of samples
rt = rtUI * spb;
ft = ftUI * spb;
% define jitter as a function of sample position
SJcycles = round(SJfreq * numBits / dataRate);   % jitter cycles
for i = 1:numSJ
    if (SJpp(i) ~= 0 && SJfreq(i) ~= 0 && SJcycles(i) == 0 && ~nowarning)
         warndlg(sprintf(['Number of symbols is too small for the given SJ frequency of %s Hz.\n\n' ...
             'Please increase the number of symbols to at least %d \nor increase SJ frequency to %s\n'], ...
                iqengprintf(SJfreq(i)), ...
                ceil(dataRate / SJfreq(i)), ...
                iqengprintf(dataRate / numBits, 2)), ...
                'Warning', 'modal');
        SJcycles(i) = 1;
        break;
    end
end
% define SJ and RJ functions. The functions will be called with a vector of
% transition times (in units of samples) and are expected to return the
% deviation in units of samples
switch lower(jitterShape)
    case 'sine'; SJfct = @(x,i) SJpp(i) / 2 * spb * sin(SJcycles(i) * 2*pi*x/numSamples);
    case 'square'; SJfct = @(x,i) SJpp(i) / 2 * spb * (2*mod(floor(SJcycles(i) * 2*x/numSamples), 2)-1);
    case 'ramp'; SJfct = @(x,i) SJpp(i) / 2 * spb * (2*mod(SJcycles(i) * x/numSamples, 1)-1);
    case 'triangle'; SJfct = @(x,i) SJpp(i) / 2 * spb * (2*abs(2*mod(SJcycles(i) * x/numSamples, 1)-1)-1);
    case 'noise'; SJfct = @(x,i) SJpp(i) / 2 * spb * (2*rand(1, length(x))-1);
    otherwise; error('unknown jitter shape: "%s"', jitterShape);
end
RJfct = @(x) RJpp / 2 * spb * (sum(randStream.rand(6,length(x)))/6-0.5)*2;
if (noiseFreq == 0)
    noiseFct = @() noise * (sum(randStream.rand(6,numSamples))/6-0.5)*2;
else
    Ncycles = round(noiseFreq * numBits / dataRate);   % noise cycles
    if (noise ~= 0 && noiseFreq ~= 0 && Ncycles == 0 && ~nowarning)
%         warndlg(['Noise frequency too low for the given number of bits. Minimum is: ' ...
%             iqengprintf(dataRate / numBits) ' Hz'], 'Warning', 'modal');
% let's not complain too much and use a single cycle...
        Ncycles = 1;
    end
    noiseFct = @() noise * sin(Ncycles * 2*pi*(1:numSamples)/numSamples);
end
% the transition function will be called with values between 0 and 1 and is
% expected to return a value between 0 and 1
TTfct = @(x,spb) (cos(pi*(x-1))+1)/2;   % raised cosine shape
%TTfct = @(x,spb) x;   % trapezoidal line

% calculate transition deviation caused by SSC
% assume SSC to have "triangle" shape, centered at dataRate
% sscFct receives vector with values between 0 and 1 as input and returns
% a vector with values between -1 and +1
switch lower(sscShape)
    case 'sine'; sscFct = @(x) sin(2*pi*x);
    case 'square'; sscFct = @(x) 2*mod(floor(2*x), 2)-1;
    case 'rampup'; sscFct = @(x) 2*mod(2*x-1/2,1)-1;
    case 'rampdown'; sscFct = @(x) -2*mod(2*x-1/2,1)-1;
    case 'trianglecenter'; sscFct = @(x) (2*mod(2*x-1/2,1)-1) .* (2*mod(floor(2*x-1/2),2)-1);
    case 'triangledown'; sscFct = @(x) (2*mod(2*x-1,1)-1) .* -(2*mod(floor(2*x-1),2)-1);
    case 'triangleup'; sscFct = @(x) (2*mod(2*x-1,1)-1) .* (2*mod(floor(2*x-1),2)-1);
    otherwise; error('unknown SSC shape: "%s"', sscShape);
end
%sscFct = @(x) (2*mod(2*x-1/2,1)-1) .* (2*mod(floor(2*x-1/2),2)-1);      % triangle center
%sscFct = @(x) sin(2*pi*x);                                             % sine wave
sscCycles = round(sscFreq * numBits / dataRate);
if (sscDepth ~= 0 && sscFreq ~= 0 && sscCycles == 0 && ~nowarning)
     warndlg(['SSC frequency is too low for the given number of bits. Minimum is: ' iqengprintf(dataRate / numBits) ' Hz'], 'Warning', 'modal');
     sscCycles = 1;
end
%sscFreqActual = sscCycles * dataRate / numBits;
%fprintf('actual SSC frequency = %s\n', iqengprintf(sscFreqActual, 3));
% deviation from nominal UI period (in fraction of UI)
perDev = 0.5 * sscDepth * sscFct(sscCycles * (0:numBits)/numBits);
% sum of UI periods
cumDev = cumsum(perDev);

% calculate transition positions (start with first half bit to get the
% complete transition, add 1 because of array indices)
dpos = find(diff([data data(1)]));
pt0 = spb * (dpos - 0.5) + 1;   % nominal transition positions (in units of samples)
px0 = spb * (1:numBits);        % nomnial symbol positions (in units of samples)
% add jitter
pt = pt0 + RJfct(pt0);
px = px0 + RJfct(px0);
for i = 1:numSJ
    pt = pt + SJfct(pt0, i);
    px = px + SJfct(px0, i);
end
% add SSC
if (sscDepth ~= 0)
    % SSC deviation in number of samples
    sscDev = spb * interp1((0:numBits) *  spb, cumDev, pt0);
    pt = pt + sscDev;
    sscDev = spb * interp1((0:numBits) *  spb, cumDev, px0);
    px = px + sscDev;
end
% add duty cycle distortion - works for NRZ and PAMn
% method: move the position of rising edge depending on whether the
% direction of voltage change
if (dutyCycle ~= 0.5)
    % extend the data pattern to avoid errors
    datax = [data data(1)];
    % determine which edges are rising edges
    isRisingEdge = (datax(dpos+1) > datax(dpos));
    % move the edge position of rising edges (falling edges stay where they are)
    pt = pt - isRisingEdge * spb * (dutyCycle - 0.5);
    if (~strcmp(filterType, 'Transition Time'))
        errordlg('Duty cycle distortion is only available with pulse shape set to "Transition Time"');
    end
end

% now calculate the actual samples
if (strcmp(filterType, 'Transition Time'))
    samples = calcTime(numSamples, numBits, spb, pt, dpos, data, rt, ft, ttProp, TTfct);
else
    samples = calcFilter(numSamples, numBits, spb, px, data, filterType, filterBeta, filterNsym);
end

% add ISI
tmp = repmat(samples, 1, 2);
tmp = filter([1-isi 0], [1 -1*isi], tmp);
samples = tmp(numSamples+1:end);

% add noise
samples = samples + noiseFct();
%
% apply frequency correction
if (correction)
    nowarning = (strcmp(fct, 'clock'));
    if sampleRate == dataRate
        [samples, channelMapping] = iqcorrection(samples, sampleRate, 'chMap', channelMapping, 'nowarning', nowarning, 'normalize', normalize, 'atratecorrection', 1);
    else
        [samples, channelMapping] = iqcorrection(samples, sampleRate, 'chMap', channelMapping, 'nowarning', nowarning, 'normalize', normalize);
    end
end
% set range to [-ampl...+ampl]
samples = samples * amplitude;

delete(randStream);


function [samples] = calcTime(numSamples, numBits, spb, pt, dpos, data, rt, ft, ttProp, TTfct)
samples = zeros(1,numSamples);
numPts = length(pt);
pt(numPts + 1) = numSamples + rt;   % add one more point at the end to avoid overflow
dpos(end+1) = 1;                    % dito
k = 1;                              % k counts transitions
lev = data(dpos(1)+1);              % start with the first data value
oldlev = data(1);                   % remember the previous level in transitions
if (lev >= oldlev)                  % next edge is rising or falling
    tt = rt;
else
    tt = ft;
end
% make transition time proportional to level change
if (ttProp)
    tt = abs(lev - oldlev) * tt;
end
i = 1;                              % i counts samples
while i <= numSamples
    if (i <= pt(k)-tt/2)            % before transition
        samples(i) = oldlev;        %   set to current level
        i = i + 1;                  %   and go to next sample
    elseif (i >= pt(k)+tt/2)        % after transition
        k = k + 1;                  %   check next transition (don't increment sample ptr!)
        oldlev = lev;               %   remember previous level
        lev = data(mod(dpos(k),numBits)+1);  %   load new level
        if (lev >= oldlev)         % next edge is rising or falling
            tt = rt;
        else
            tt = ft;
        end
        % make transition time proportional to level change
        if (ttProp)
            tt = abs(lev - oldlev) * tt;
        end
    else                            % during the transition
        m = (i - (pt(k)-tt/2)) / tt;
        samples(i) = oldlev + TTfct(m,spb) * (lev - oldlev);
        i = i + 1;
    end
end
% shift from [0...1] to [-1...+1]
samples = (2*samples - 1);



function [samples] = calcFilter(numSamples, ~, spb, px, data, filterType, filterBeta, filterNsym)
debugSerial = evalin('base', 'exist(''debugSerial'', ''var'') && debugSerial >= 1');
filt = [];
filterParams = [];
% for interpolation of the filter kernel
overN = 50;
% since MATLAB 2022, use of fdesign.pulseshaping is replaced by rcosdesign/gaussdesign
newFilterFct = exist('rcosdesign','file');
switch (filterType)
    case 'None'
        filt.Numerator = 1;
    case 'Rectangular'
        filt.Numerator = ones(1, overN) / overN;
    case {'Root Raised Cosine' 'Square Root Raised Cosine' 'RRC'}
        if (newFilterFct)
            filt.Numerator = rcosdesign(filterBeta, filterNsym, overN, 'sqrt');
        else
            filterType = 'Square Root Raised Cosine';
            filterParams = 'Nsym,Beta';
        end
    case {'Raised Cosine' 'RC'}
        if (newFilterFct)
            filt.Numerator = rcosdesign(filterBeta, filterNsym, overN, 'normal');
        else
            filterType = 'Raised Cosine';
            filterParams = 'Nsym,Beta';
        end
    case 'Gaussian'
        warndlg('Gaussian Filter does not work correctly - please choose another filter type');
        if (newFilterFct)
            filt.Numerator = gaussdesign(filterBeta, filterNsym, overN);
        else
            filterType = 'Gaussian';
            filterParams = 'Nsym,BT';
        end
    otherwise
        error(['unknown filter type: ' filterType]);
end
if (isempty(filt))
    try
        fdes = fdesign.pulseshaping(overN, filterType, filterParams, filterNsym, filterBeta);
        filt = design(fdes);
    catch ex
        errordlg({'Error during filter design. Please verify that' ...
            'you have the "Signal Processing Toolbox" installed' ...
            'MATLAB error message:' ex.message}, 'Error');
    end
end
flt = filt.Numerator * overN;
flt = flt / max(flt); % normalize the filter to peak = 1
extSym = 5;  % extend the filter to cover for jitter up to 5 UI
flt = [flt zeros(1,extSym*overN)];
fltLen = length(flt);
fltList = (0:fltLen-1)/overN;
if (size(data,1) ~= 1)
    error('unexpected data vector');
end
% start with end of data pattern for clean wrap around
data = [data(end-filterNsym:end) data];
% adjust px accordingly
lpx = length(px);
px = [px(end-filterNsym:end)-spb*lpx px px(1:filterNsym+extSym)+spb*lpx] + spb*(filterNsym+1);
% plot jitter function
if (debugSerial)
    figure(101); plot(px/spb - (1:length(px)), '.-'); title('TIE vs. symbol#'); xlabel('symbol #'); ylabel('TIE (UI)'); grid on;
end
% move data to the range [-1...+1]
data = 2*data-1;
nsmp = floor(spb*filterNsym);
samples = zeros(1,numSamples + ceil((2*filterNsym+1)*spb));
len = length(data);
if (debugSerial)
    figure(102); clf; hold on;
end
% find out if jitter needs to be applied (if not, algorithm is simpler and faster)
dpx = diff(px);
applyJitter = (max(dpx) - min(dpx) > 1e-9);
for i = 1:len
    x = data(i);
    if (x == 0)
        continue;
    end
    pos = px(i);        % symbol position in units of samples
    posi = ceil(pos);   % integer portion --> used as index into sample array
    posf = posi - pos;  % fractional portion --> used for interpolation
    % points at which to interpolate the pulse shape filter's impulse response
    posList = (posf + (0:nsmp-1))/spb;
    % deal with "streching" or "squeezing" the impulse response in case of jitter
    if (applyJitter)
        fltList = interp1(0:filterNsym+extSym, px(i:i+filterNsym+extSym)-px(i), (0:fltLen-1)/overN)/spb;
        if (max(posList) > max(fltList))
            errordlg(sprintf('Cannot calculate waveform due to excess jitter.\nPlease reduce the jitter to no more than %d UI.', extSym));
            break;
        end
    end
    % interpolate pulse shape filter impulse response at sample locations
    tmp = x * interp1(fltList, flt, posList);
    if (debugSerial)
        p1 = spb*filterNsym;
        p2 = spb*(filterNsym+10);
        idx = i + floor(filterNsym/2);
        delta = 1;
        if (px(idx)+delta >= p1 && px(idx)+delta <= p2)
            figure(102); plot(posi+1:posi+1+nsmp-1, tmp, '.-'); xlim([p1 p2]);
            plot([0 0]+px(idx)+delta, [0 1], 'k:');
            plot([p1 p2], [0 0], 'k:');
            xlabel('sample #');
        end
    end
    if (posi < 0 || posi+1+nsmp-1 > length(samples))
        fprintf('under/overflow - ignoring this sample (i=%d, numSamples=%d posi=%d nsmp=%d end=%d delta=%d)\n', ...
            i, numSamples, posi, nsmp, posi+1+nsmp-1, posi+1+nsmp-1-length(samples));
        continue;
    end
    samples(posi+1:posi+1+nsmp-1) = samples(posi+1:posi+1+nsmp-1) + tmp;
end
% cut center section of samples (throw away filter transitions)
samples = samples(nsmp+1:nsmp+numSamples);
% shift back to have first symbol at the beginning of the waveform
samples = circshift(samples, -floor(nsmp/2));



function data = prbs13q(numBits, levels)
% Matlab script to generate PAM4 PRBS13Q test pattern
if (~exist('numBits', 'var'))
    numBits = 8191;
end
if (~exist('levels', 'var'))
    levels = [0 1/3 1 2/3];
end
z1 = comm.PNSequence('Polynomial', [13 12 11 1 0], 'InitialConditions', [0 0 0 0 0 1 0 1 0 1 0 1 1], 'SamplesPerFrame', 2*numBits, 'Mask', 13);
NRZ = z1.step()';
% z1 = commsrc.pn('Genpoly', [13 12 11 1 0], 'Initialstates', [0 0 0 0 0 1 0 1 0 1 0 1 1], 'Numbitsout', 2*numBits,'Shift',13);
% NRZold = z1.generate()';

% take pairs of bits, weight and add
data = levels(2*NRZ(1:2:end) + NRZ(2:2:end) + 1);


function data = qprbs13(numBits, levels)
% Matlab script to generate PAM4 QPRBS13 test pattern - Paul Forrest
% Date 2/13/2015
%
% Start with 3 and a bit repetitions of PRBS13 to X^13+X^12+X^2+X+1
% polynomial = 319096 bits. Then take each pair of bits, with 1st bit
% weighted at 2x amplitude of 2nd bit and add to get PAM4 symbol. Divide by
% 3 to normalize all values between 0 and 1 
% (PAM4 levels will be 0, 1/3, 2/3, 1)
% In this using the lane0 seed for the starting values of the shift
% registers in the LFSR model
%
% NOTE the taps used in Matlab are different to the polynomial above
% because Matlab defines the LFSR structure differently :) But these are
% the taps to use the generate the sequence of bits per the standard.

if (~exist('numBits', 'var'))
    numBits = 15548;
end
if (~exist('levels', 'var'))
    levels = [0 1/3 2/3 1];
end
% --- commsrc.pn is no longer supported...
% z1 = commsrc.pn('Genpoly', [13 12 11 1 0], 'Initialstates', [0 0 0 0 0 1 0 1 0 1 0 1 1], 'Numbitsout', 8191,'Shift',13);
% % generate 1x sequence of PRBS13 per PAM4 standard, this will be 8191 bits 1:8191 of the 31096 bit NRZ pattern
% NRZ1 = z1.generate()';
% % generate 1x sequence of PRBS13 per PAM4 standard, inverted, this will be 8191 bits 8192:16382 of the 31096 bit NRZ pattern
% NRZ2 = 1 - z1.generate()';
% % generate 1x sequence of PRBS13 per PAM4 standard, this will be 8191 bits 16383:24573 of the 31096 bit NRZ pattern
% NRZ3 = z1.generate()';
% %generate 1x truncated sequence of PRBS13 per PAM4 standard, inverted, this will be 6523 bits 24574:31096 of the 31096 bit NRZ pattern
% NRZ4 = 1 - z1.generate()';
% % add the segments together to get complete NRZ version of the QBPRS13
% NRZold = [NRZ1 NRZ2 NRZ3 NRZ4(1:6523)];

z1 = comm.PNSequence('Polynomial', [13 12 11 1 0], 'InitialConditions', [0 0 0 0 0 1 0 1 0 1 0 1 1], 'SamplesPerFrame', 8191, 'Mask', 13);
NRZ1 = z1.step()';
% generate 1x sequence of PRBS13 per PAM4 standard, inverted, this will be 8191 bits 8192:16382 of the 31096 bit NRZ pattern
NRZ2 = 1 - z1.step()';
% generate 1x sequence of PRBS13 per PAM4 standard, this will be 8191 bits 16383:24573 of the 31096 bit NRZ pattern
NRZ3 = z1.step()';
%generate 1x truncated sequence of PRBS13 per PAM4 standard, inverted, this will be 6523 bits 24574:31096 of the 31096 bit NRZ pattern
NRZ4 = 1 - z1.step()';
% add the segments together to get complete NRZ version of the QBPRS13
NRZ = [NRZ1 NRZ2 NRZ3 NRZ4(1:6523)];

% take pairs of bits, weight and add
data = levels(2*NRZ(1:2:end) + NRZ(2:2:end) + 1);
% adjust length to numBits (in case numBits is not equal to 15548)
data = repmat(data, 1, ceil(numBits / 15548));
data = data(1:numBits);


function mdata = ssprq(numBits, levels)
if (isdeployed)
    [~, result] = system('path');
    path = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else
    path = fileparts(which('iserial'));
end
path = fullfile(path, 'ssprq.csv');
if (~exist('levels', 'var') || length(levels) ~= 4)
    levels = [0 1/3 1 2/3];
end
try
    mdata = csvread(path)';
catch ex
    errordlg(sprintf('Can''t open pattern file: %s', path));
    mdata = [];
end
% undo grey coding and apply user defined coding
invLev = [0 1 3 2];
mdata = levels(invLev(mdata+1)+1);
mdata = repmat(mdata, 1, ceil(numBits / 65535));
mdata = mdata(1:numBits);


function mdata = ssprq_old(numBits, levels)
% generate SSPRQ pattern 
% according to http://www.ieee802.org/3/bs/public/adhoc/logic/oct27_16/anslow_02a_1016_logic.pdf
% verified against: http://www.ieee802.org/3/bs/public/adhoc/smf/16_04_19/anslow_03_0416_smf.csv 
%a = csvread('c:\temp\SSPRQ\anslow_03_0416_smf.csv')';
prbsPoly = [31 3 0];
% generate partial PRBS 31 sequences with defined seed
seed = double(dec2binvec(hex2dec('00000002'), 31));
prbs = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 10924, 'InitialStates', seed(1:31));
data = prbs.generate();
seed = double(dec2binvec(hex2dec('34013FF7'), 31));
prbs = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 10922, 'InitialStates', seed(1:31));
data = [data; prbs.generate()];
seed = double(dec2binvec(hex2dec('0CCCCCCC'), 31));
prbs = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', 10922, 'InitialStates', seed(1:31));
data = [data; prbs.generate()];

% PAM4: out = 3 - in  --> flip odd bits in binary data
datax = mod(data + repmat([1; 0], length(data)/2, 1), 2);
% append flipped data to original data
data2 = [data; datax];
% second sequence with first and last binary bit removed
% in order to match the data in the CSV from Anslow, last chunk must be inverted, don't know why
data = [data2; data(2:end-1); 1-data(end); 1-datax(1:end-1)];
%            % apply a gray mapping (00 01 11 10)
%            mapping = [0 1 3 2]+1;
%--- gray mapping is now applied by setting the levels to 0  1/3  1  2/3
%--- this makes it more obvious to the user, that we are using gray coding
mapping = [0 1 2 3]+1;
mdata = levels(mapping(2 * data(1:2:end-1) + data(2:2:end) + 1));
% adjust length to numBits (in case numBits is not equal to 65535)
mdata = repmat(mdata, 1, ceil(numBits / 65535));
mdata = mdata(1:numBits);


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);

function data = customLFSR(levels)

    s = ones(20,1);     % initial seed of the LFSR
    t = [20 17];        % feedback polynomial x^20 + x^17 + 1
    TMP_LEN = 2^15 ;         
    TMPG_period = 16;

    n=length(s);
    m=length(t);
    seq(1) = s(n);
    pattern = [];

    for k=1:TMP_LEN*TMPG_period-1
        b(1)=xor(s(t(1)), s(t(2)));
        if m>2
            for i=1:m-2
                b(i+1)=xor(s(t(i+2)), b(i));
            end
        end
        j=1:n-1;

        if k == 1 || mod(k-1, TMPG_period) == 0 
            sc4 = bi2de([s(16) s(15)]);
            switch sc4
                case 0
                    pattern(end+1) = 15;
                case 1
                    pattern(end+1) = 5;
                case 2
                    pattern(end+1) = -15;
                case 3
                    pattern(end+1) = -5;
                otherwise
                    pattern(end+1) = 0;
            end

        end
        s(n+1-j)=s(n-j);
        s(1)=b(m-1);
        seq(k+1)=s(n);

    end
    
    data = [pattern, -pattern];
    
    levelsSorted = sort(levels);
    
    data(data == -15) = levelsSorted(1);
    data(data == -5) = levelsSorted(2);
    data(data == 5) = levelsSorted(3);
    data(data == 15) = levelsSorted(4);
    
%     

    
function pattern = SSPR(numBits)
    
    % Short stress pattern random pattern generator
    % (according to OIF-CEI-04.0)

    switch numBits
        case 32768
            modLength = 1; 
        case 32762
            modLength = 0;
        otherwise
            modLength = 0;
    end
            
    t = [28 25];                        % feedback polynomial x^28 + x^25 + 1
    
    % Block 1
    %s = dec2binVec(0x0080080, 28);      % seed
    % In some contexts we still use MATLAB R2015b and
    % we have no resources to change this (2022-06-07).
    % Hexadecimal literals require at least R2019b.
    % Use decimal instead:
    s = dec2binVec(524416, 28);         % seed
    l = 5437;                           % pattern length
    seq1 = LFSR(s, t, l);
    
    % Block 2
    seq2 = [1 zeros(1,72)];
   
    % Block 3
    %s = dec2binVec(0xFFFFFFF, 28);
    s = dec2binVec(268435455, 28);
    seq3 = LFSR(s, t, l);
    
    % Block 4
    seq4(1) = 0;
    if modLength == 0
        len = length(seq1) - 3;
    else
        len = length(seq1);
    end
    for i = 1:len
       if seq1(i) == 0
           if seq4(i) == 1
               seq4(i+1) = 0 ;
           else
               seq4(i+1) = 1;
           end
       else
           if seq4(i) == 1
               seq4(i+1) = 1 ;
           else
               seq4(i+1) = 0;
           end
       end
    end
    seq4 = seq4(2:end);
    % Blocks 5..8 are the inverse of blocks 1...4 respectively
    seq5 = ~seq1;
    seq6 = ~seq2;
    seq7 = ~seq3;
    seq8 = ~seq4;
    
    pattern = [seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8];

function ret = dec2binVec(value, digits)
    string = dec2bin(value, digits);
    for i = 1:length(string)
        ret(i) = str2double(string(i));
    end
    ret = fliplr(ret);


function seq = LFSR(seed, polynom, len)
    % linear feeback shift register 
    % (source:
    % https://de.mathworks.com/matlabcentral/fileexchange/66871-lfsr-linear-feedback-shift-register)

    n=length(seed);
    m=length(polynom);
    
    seq(1) = seed(n);
    
    for k=1:len-1
        b(1)=xor(seed(polynom(1)), seed(polynom(2)));
        if m>2
            for i=1:m-2
                b(i+1)=xor(seed(polynom(i+2)), b(i));
            end
        end
        j=1:n-1;

        seed(n+1-j)=seed(n-j);
        seed(1)=b(m-1);
        seq(k+1)=seed(n);

    end
