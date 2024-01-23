function result = iqmtcal(varargin)
% In-system frequency & phase calibration using a real-time or sampling
% oscilloscope
%
% Parameters are passed as property/value pairs. Properties are:
% 'scope' - can be 'RTScope' or 'DCA'
% 'sim' - 0=user real hardware, 1=read from file, 2=offline simulation
% 'scopeavg' - number of averages during scope acquisition
% 'analysisavg' - number of repeated measurements that are averaged
% 'maxfreq' - frequency up to which the calibration will be performed
% 'numtones' - number of frequency points in the calibration
% 'awgchannels' - cell array of AWG channels for which calibration is performed.
%    The last element specifies the trigger channel
%    if Trigger channel = 'unused', no trigger channel is used
% 'scopechannels' - cell array of scope channel represented as strings
%    The last element specifes the trigger channel
%    The number of elements in awgchannels and scopechannels must be the
%    same
% 'amplitude' - amplitude of the signal used for setting up the scope.
% 'skewincluded' - if set to 1, linear phase will calculated to include
%    the skew between channels
% 'axes' - cell array of two axes handles to display the graphs
% 'scoperst' - if set to 1, a *RST command is sent to the scope
% 'awgrst' - if set to 1, a *RST command is sent to the AWG
% 'recalibrate' - if set to 1, will use existing corrections
% 'autoscopeampl' - if set to 1, scope amplitude will be determined automatically
% 'debuglevel' - 0=no debug output, value between 1 and 3 - more debug output
% 'memory' - number of samples used for the test waveform
% 'tonedev' - 'random', 'imd' or 'zero'. Determines the deviation from
%    equidistant tone spacing: 'random' generates a random deviation up to a
%    fixed number of buckets; 'imd' uses a deviation that minimizes IMD
% 'restoreScope' - if set to 1 (default), will restore scope settings after
%    calibration is complete
% 'spui' - samples-per-UI setting for DCA
%
%
% If called without arguments, opens a graphical user interface to specify
% parameters

% T.Dippon, Agilent Technologies 2011-2013, Keysight Technologies 2014-2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED AGILENT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. AGILENT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH AGILENT INSTRUMENTS.

global debugLevel;
if (nargin == 0)
    iqmtcal_gui();
    return;
end
% signal to in-system cal that it is being called from iqmain8070
if (nargin == 1)
    iqmtcal_gui(varargin{1});
    return;
end
result = [];
sim = 0;
axesHandles = [];
scopeType = 'RTScope';
% set to 1 if the signal is normal, -1 for inverted [I Q trigger]
polarity = [1 1 1 1 1];
% averaging on capture
scopeAvg = 4;
% scopeAmpl of the signal
scopeAmpl = 600e-3;
% number of tones
numTones = 200;
% memory size in AWG
memSize = 64*1024;
% max frequency
fcMax = 8e9;
% number of averages during analysis
analysisAvg = 1;
% AWG channels [I Q trigger]
awgChannels = {'1' '2' 'unused' 'unused' 'unused'};
% measured channels (NOTE:  cell array of strings!!!)
scopeChannels = {'1' '2' 'unused', 'unused', '3'};
% set to 1 if skew between I & Q is included in phase response
skewIncluded = 1;
% reset the scope
scopeRST = 1;
% reset the AWG
awgRST = 1;
% use existing calibration as a basis
recalibrate = 0;
% config structure
arbConfig = [];
% AWG sample rate
fsAWG = [];
% automatic amplitude detection on the scope
autoScopeAmpl = 1;
% tone deviation algorithm ('random', 'zero' or 'imd')
toneDevType = 'random';
% remove sin(x)/x in magnitude display
removeSinc = 0;
% use DCA with pattern lock - no signature pattern!!
pattLock = 0;
% set to 1 if Flex DCA software is used
flex = 0;
% restore scope settings after calibration
restoreScope = 1;
% bandwidth used in the scope
scopeBW = [];
% turn SIRC on/off
scopeSIRC = [];
% use a separate set of tones for each channel
separateTones = 0;
% perform auto-deskew in the scope (so far, only implemented in the DCA)
scopeDeskew = 1;
% samples-per-UI for sampling scope
spui = 16;
% function pointer for progress function (iqwaitbar)
progressfct = [];
% create a random stream (used for phases & tone deviations)
randStream = RandStream('mt19937ar', 'seed', 12345); 
randStream.reset();
err = [];
% set debugLevel
debugLevel = 0;
%
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'scope';          scopeType = varargin{i+1};
            case 'sim';            sim = varargin{i+1};
            case 'scopeavg';       scopeAvg = varargin{i+1};
            case 'analysisavg';    analysisAvg = varargin{i+1};
            case 'maxfreq';        fcMax = varargin{i+1};
            case 'numtones';       numTones = varargin{i+1};
            case 'polarity';       polarity = varargin{i+1};
            case 'awgchannels';    awgChannels = varargin{i+1};
            case 'scopechannels';  scopeChannels = varargin{i+1};
            case 'amplitude';      scopeAmpl = varargin{i+1};
            case 'skewincluded';   skewIncluded = varargin{i+1};
            case 'axes';           axesHandles = varargin{i+1};
            case 'scoperst';       scopeRST = varargin{i+1};
            case 'awgrst';         awgRST = varargin{i+1};
            case 'recalibrate';    recalibrate = varargin{i+1};
            case 'samplerate';     fsAWG = varargin{i+1};
            case 'autoscopeampl';  autoScopeAmpl = varargin{i+1};
            case 'scopebw';        scopeBW = varargin{i+1};
            case 'scopesirc';      scopeSIRC = varargin{i+1};
            case 'separatetones';  separateTones = varargin{i+1};
            case 'debuglevel';     debugLevel = varargin{i+1};
            case 'memory';         memSize = varargin{i+1};
            case 'tonedev';        toneDevType = varargin{i+1};
            case 'removesinc';     removeSinc = varargin{i+1};
            case 'restorescope';   restoreScope = varargin{i+1};
            case 'scopedeskew';    scopeDeskew = varargin{i+1};
            case 'arbconfig';      arbConfig = varargin{i+1};
            case 'spui';           spui = varargin{i+1};
            case 'progressfct';    progressfct = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
% if "debugLevel" is set in the workspace, it overwrites the local setting
if (evalin('base', 'exist(''debugLevel'', ''var'')'))
    debugLevel = evalin('base', 'debugLevel');
end

% progress bar
if (~isempty(progressfct))
    hMsgBox = progressfct('Please wait...');
else
    hMsgBox = iqwaitbar('Please wait...');
end

% configuration and sample rate
try
    arbConfig = loadArbConfig(arbConfig);
catch
    errordlg('Can''t open arbConfig. Please configure AWG and scope in the IQtools instrument configuration');
    return;
end
if (isempty(fsAWG))
    fsAWG = arbConfig.defaultSampleRate;
end

% define scope function
switch scopeType
    case 'RTScope'
        scopeFct = @iqreadscope;
    case 'DCA'
        scopeFct = @iqreaddca;
    otherwise
        error('invalid scope type: %s', scopeType);
end

% handle legacy awgChannels format (channels as cell array of numbers)
if (~iscell(awgChannels))
    chNames = {'1', '2', '3', '4', 'unused'};
    av = awgChannels;
    awgChannels = cell(1,length(av));
    for i=1:length(av)
        awgChannels{i} = chNames{av(i)};
    end
end

if (length(scopeChannels) ~= length(awgChannels))
    error('scopeChannels and awgChannels must be same length');
end
% determine scope and AWG channels
scopeTrig = scopeChannels{end};
if (strcmp(scopeTrig, 'PTB+FP'))
    pattLock = 1;
end
scopeChannels = scopeChannels(1:end-1);
awgTrig = awgChannels{end};
awgChannels = awgChannels(1:end-1);
% remove unused channels
p = find(strcmp(scopeChannels, 'unused'));
scopeChannels(p) = [];
awgChannels(p) = [];
% for AWG use channel numbers
awgChanNums = str2double(awgChannels);
% sanity check: all of them must be numbers
if (~isempty(find(isnan(awgChanNums), 1)))
    error('invalid list of AWG channels');
end
numChan = length(scopeChannels);
trigDelay = zeros(1, numChan);
% when talking to hardware, perform some sanity checks first
if (sim == 0)
    %% -------------- initialize AWG
    switch (arbConfig.model)
        case { 'M8195A_Rev1', 'M8195A_1ch', 'M8195A_1ch_mrk', 'M8195A_2ch', 'M8195A_2ch_mrk', 'M8195A_2ch_dupl', 'M8195A_4ch', 'M8195A_2ch_256k', 'M8195A_4ch_256k' 'M8196A' 'M8194A'} % ok
        case { 'MUXDAC' } % ok
%         case { 'M8198A_Rev0', 'M8198A_Rev0_ILV' } % ok
        case { 'M8199A', 'M8199A_ILV' } % ok
        case { 'M8199B', 'M8199B_NONILV'} %ok  
        case { 'M8198A'} %ok
        case { 'M5301x' } %ok
        case { 'M5300x_baseband' } %ok
        case { 'M8135A' } %ok
        case { 'M5300x_modulated' 'M5300x_std' } %ok
            errordlg('M5300x calibration works in baseband mode only', 'Error', 'replace');
            return;
        case { 'M3201A', 'M3202A','M3201A_CLF', 'M3202A_CLF','M3201A_CLV', 'M3202A_CLV' } % ok
        case { 'M8190A_12bit', 'M8190A_14bit' } % ok
        case { 'M8121A_12bit', 'M8121A_14bit' } % ok
        case { 'M8121A_DUC_x3', 'M8121A_DUC_x12', 'M8121A_DUC_x24', 'M8121A_DUC_x48' }
            errordlg('M8121A calibration works only in 12bit or 14bit direct mode.', 'Error', 'replace');
            return;
        case { 'M8190A_DUC_x3', 'M8190A_DUC_x12', 'M8190A_DUC_x24', 'M8190A_DUC_x48' }
            errordlg('M8190A calibration works only in 12bit or 14bit direct mode.', 'Error', 'replace');
            return;
        otherwise
            warndlg('This function has only been tested with an M8190A / M8195A / M8199 AWGs. It will probably not work with other models', 'Warning', 'replace');
    end
    % RefClk as PTB Trigger is only possible on M8196A
    if (strncmpi(awgTrig, 'RefClk', 6) && (~strcmp(arbConfig.model, 'M8196A') || ~pattLock))
        errordlg('RefClk Out as a trigger is only supported on the M8196A driving the PTB+FP input on a DCA');
        return
    end
    if (~isempty(hMsgBox))
        hMsgBox.update(0.05, 'Trying to connect to AWG...');
    end
    % for M9336, M824xA, M320xA don't try to send SCPI commands
    % Don't perform AWG RST on M8199A because it will undo the skew calibration
    if (isempty(find(strcmp(arbConfig.model, { 'M5301x' 'M5300x_modulated' 'M5300x_baseband' 'M5300x_std' 'M9336A' 'N824xA' 'M3201A' 'M3202A' 'M3201A_CLF', 'M3202A_CLF' 'M3201A_CLV', 'M3202A_CLV'}), 1)))
        if (awgRST)
            % don't send a plain *RST command because synchronized systems
            % must be reset in proper order
            arbTmp = arbConfig;
            arbTmp.do_rst = 1;
            iqdownload([], 0, 'arbConfig', arbTmp, 'keepOpen', true);
        end
        f = iqopen(arbConfig);
        if (isempty(f))
            return;
        end
        if (~isempty(hMsgBox) && hMsgBox.canceling())
            iqclose(f);
            return;
        end
        if (str2double(awgTrig) >= 1)  % trigger on a regular channel
            if (~isempty(strfind(arbConfig.model, 'M8196A')) || ~isempty(strfind(arbConfig.model, 'M8194A')))
                opts = xquery(f, '*opt?');
                if (~isempty(strfind(opts, '001')))
                    validChannels = [1];
                elseif (~isempty(strfind(opts, '002')))
                    if (~isempty(strfind(arbConfig.model, 'M8196A')))
                        validChannels = [1, 4];
                    else
                        validChannels = [1, 2];
                    end
                else
                    validChannels = [1, 2, 3, 4];
                end
                if (isempty(find(str2double(awgTrig) == validChannels, 1)))
                    errordlg(sprintf('Channel %s is not valid for an instrument with option %s', awgTrig, opts));
                    return;
                end
            end
        end
        if (strcmpi(awgTrig, 'Marker'))  % trigger using markers on M8190A & M8195A_1ch & M8196A
            if (~isempty(strfind(arbConfig.model, 'M8190A')))
                trigAmpl = 500e-3;
                trigOffs = 0;
                xfprintf(f, sprintf(':mark1:sample:volt:ampl %g; offs %g', trigAmpl, trigOffs));
                xfprintf(f, sprintf(':mark2:sample:volt:ampl %g; offs %g', trigAmpl, trigOffs));
                xfprintf(f, sprintf(':mark1:sync:volt:ampl %g; offs %g', trigAmpl, trigOffs));
                xfprintf(f, sprintf(':mark2:sync:volt:ampl %g; offs %g', trigAmpl, trigOffs));
            elseif (~isempty(strfind(arbConfig.model, 'M8195A_1ch')) || ...
                    ~isempty(strfind(arbConfig.model, 'M8195A_1ch_mrk')) || ...
                    ~isempty(strfind(arbConfig.model, 'M8195A_2ch_mrk')))
                % todo: send trigger level commands to M8195A
            elseif (~isempty(strfind(arbConfig.model, 'M8196A')))
                opts = xquery(f, '*opt?');
                if (~isempty(strfind(opts, '001')))
                    hasMarkers = 1; validChannels = [1];
                elseif (~isempty(strfind(opts, '002')))
                    hasMarkers = 1; validChannels = [1, 4];
                else
                    hasMarkers = 0; validChannels = [1, 2, 3, 4];
                end
                if (hasMarkers)
                    trigAmpl = 500e-3;
                    trigOffs = -125e-3;
                    xfprintf(f, sprintf(':volt2:ampl %g; offs %g', trigAmpl, trigOffs));
                    xfprintf(f, sprintf(':volt3:ampl %g; offs %g', trigAmpl, trigOffs));
                    xfprintf(f, sprintf(':outp2 on;:outp2 on'));
                end
                chList = setdiff(awgChanNums, validChannels);
                if (~isempty(chList))
                    chListStr = sprintf('%d ', chList);
                    errordlg(sprintf('Channel %sis not valid for an instrument with option %s', chListStr, opts));
                    return;
                end
            elseif (~isempty(strfind(arbConfig.model, 'M8194A')))
                opts = xquery(f, '*opt?');
                if (~isempty(strfind(opts, '001')))
                    hasMarkers = 1; validChannels = [1];
                elseif (~isempty(strfind(opts, '002')))
                    hasMarkers = 1; validChannels = [1, 2];
                else
                    hasMarkers = 0; validChannels = [1, 2, 3, 4];
                end
                if (hasMarkers)
                    xfprintf(f, sprintf(':outp3 on;:outp4 on'));
                    xfprintf(f, sprintf(':volt3:offs 0'));
                    xfprintf(f, sprintf(':volt4:offs 0'));
                end
                chList = setdiff(awgChanNums, validChannels);
                if (~isempty(chList))
                    chListStr = sprintf('%d ', chList);
                    errordlg(sprintf('Channel %sis not valid for an instrument with option %s', chListStr, opts));
                    return;
                end
            elseif (~isempty(strfind(arbConfig.model, 'M8198A_Rev0')) || ~isempty(strfind(arbConfig.model, 'M8198A_Rev0_ILV')))
                % t.b.d.
            elseif (~isempty(strfind(arbConfig.model, 'M8199A')) || ~isempty(strfind(arbConfig.model, 'M8199A_ILV')))
                % t.b.d.
            elseif (~isempty(strfind(arbConfig.model, 'M8199B')) || ~isempty(strfind(arbConfig.model, 'M8199B_NONILV')))
                % t.b.d.
            elseif (~isempty(strfind(arbConfig.model, 'M8198A')))
                % t.b.d.
            else
                errordlg('Markers are only supported on M8190A, M8195A_1ch, M8195A_2ch_mrk, M8195A_2ch_dupl and M8196A/94A/99A/99B', 'Error', 'replace');
                return;
            end
        end
        if (strncmpi(awgTrig, 'RefClk', 6))  % trigger using RefClk Out on M8196A
            xfprintf(f, ':OUTP:ROSC:SCD 1');      % divider = 1 * 32
            xfprintf(f, ':OUTP:ROSC:SOUR SCLK1'); % select clock path
        end
%         if (~isempty(strfind(arbConfig.model, 'M8199A')) || ~isempty(strfind(arbConfig.model, 'M8199A_ILV')))
%             % reset the user delays
%             for k = 1:length(awgChanNums)
%                 xfprintf(f, sprintf(':ARM:DEL "%s",%g', buildID(arbConfig, awgChanNums(k)), 0), 1);
%             end
%         end
        iqclose(f);
    end
    
    %% ------------ initialize scope
    if (~isempty(hMsgBox))
        hMsgBox.update(0.1, 'Trying to connect to scope...');
    end
    if (strcmp(scopeType, 'RTScope'))
        f = iqopen(arbConfig.visaAddrScope);
    else
        f = iqopen(arbConfig.visaAddrDCA);
    end
    if (isempty(f) || (~isempty(hMsgBox) && hMsgBox.canceling()))
        return;
    end
    % make sure the connection to the scope is not locked by VSA
    try
        xfprintf(f, '*CLS');
        xquery(f, ':SYST:ERR?');
    catch ex
        if (strfind(ex.message, 'locked resource'))
            errordlg('Remote access to scope is locked - Please use Control->Disconnect in VSA to unlock remote access to scope');
            return;
        else
            iqreset();
            throw(ex);
        end
    end
    % if it is an old frame with 86118 module, use no more than 16K
    isTek = 0;
    if (strcmp(scopeType, 'DCA'))
        raw_idn = xquery(f, '*IDN?');
        idn = strsplit(raw_idn,',');
        if (strcmp(idn{1}, 'TEKTRONIX'))
            isTek = 1;
        end
        if (strncmp(idn{2}, '86100C', 6))
            flex = 0;
        else
            flex = 1;
        end
        if (isTek)
            memSize = 4096;
            if (restoreScope)
                xfprintf(f, ':SAVE:SETUP "C:\My Documents\TekScope\temp_setup"');
            end
        else
            if (restoreScope)
                if (flex)
                    xfprintf(f, ':DISK:SETUP:SAVE "c:\temp\temp_setup.setx"');
                else
                    xfprintf(f, ':STORE:SETUP 0');
                end
            end
            frame = xquery(f, ':MODEL? FRAME');
            if (~isempty(strfind(frame, '86100C')))
                memSize = 16384;
            end
        end
    else
        if (restoreScope)
            % one of the two save commands should work...
            xfprintf(f, ':DISK:SAVE:SETUP "c:\temp\temp_setup.set"', 1);
            xfprintf(f, ':SAVE:SETUP 0', 1);
        end
    end
    % reset the scope to make sure we have well-defined starting conditions
    if (scopeRST)
        xfprintf(f, '*RST');
    end
    % round memory size to a multiple of the granularity
    memSize = floor(memSize / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
    % now find out the trigger delay, unless we use pattern lock
    if (strcmp(scopeType, 'DCA') || (strcmp(awgTrig, 'unused')))
        if (autoScopeAmpl)
            scopeAmpl = -2;
        end
        polarity = [1 1 1 1 1];
    else
        [trigDelay, polarity, scopeAmpl] = findTrigDelay(arbConfig, awgRST, fsAWG, memSize, scopeFct, awgChanNums, awgTrig, scopeChannels, scopeTrig, scopeAmpl, autoScopeAmpl, scopeBW, scopeSIRC, scopeDeskew, recalibrate, hMsgBox);
        if (isempty(trigDelay))
            return;
        end
        % use the same trigger delay for both channels - the analusis routine
        % will figure out the difference
        trigDelay = repmat(sum(trigDelay)/length(trigDelay), 1, length(trigDelay));
    end
end % if sim == 0

%% ------------ generate test signal
sumMagDev = zeros(numTones, numChan);
sumPhaseDev = zeros(numTones, numChan);
sumDcOffset = zeros(1, numChan);
magResult = zeros(numTones, numChan);
phaseResult = zeros(numTones, numChan);
nonlinear = 0;
% calculate tone deviations
switch lower(toneDevType)
    case 'random'
        % frequency resolution
        fRes = fsAWG / memSize;
        % distance of frequency buckets
        dist = floor(fcMax / numTones / fRes);
        % make sure that random deviation leaves at least 2 buckets between tones
        dev = floor(randStream.rand(numTones, 1) * max(0, min(12, dist) - 2)) + 1;
        dev(end) = 0;
    case 'imd'
        dev = mkDev(numTones);
    case 'zero'
        dev = zeros(numTones, 1);
    case 'non-linear'
        dev = zeros(numTones, 1);
        nonlinear = 1;
    otherwise
        error('unknown tone dev type %s', toneDevType);
end
% filename for debug purposes
filename = fullfile(iqScratchDir(), 'traceMT.mat');
% find <analysisAvg> sets of phases that will be used by calcTones later on
if fcMax <= fsAWG/2 
    [phaseSets, minPeak] = findBestPhaseSets(fsAWG, numTones, fcMax, memSize, dev, randStream, analysisAvg);
else
    [phaseSets, minPeak] = findBestPhaseSets(fsAWG, numTones, fsAWG/2, memSize, dev, randStream, analysisAvg);
end

% if we use separate tones per channel, we have to run the analysis
% <numChan> times to get one complete measurement. Also, in calculating the
% average, we have to divide by another factor of <numChan>
if (separateTones)
    analysisAvg = analysisAvg * numChan;
    corrFactor = numChan;
else
    corrFactor = 1;
end
% this is the "main loop" over analysis averages
outlierCnt = 0;
avg = 0;
while (avg < analysisAvg)
    % generate tones
    if (~isempty(hMsgBox))
        hMsgBox.update(0.2 + 0.7 * (avg+1) / analysisAvg, sprintf('Calculating waveform... (%d/%d)', avg+1, analysisAvg));
    end
    if (nonlinear)
        sigAWG = calcAWGSig(fsAWG, memSize, numChan);
        allTone = (0:numTones-1) * fsAWG/2/numTones;
        tone = allTone;
        phase = zeros(numTones, 1);
    else
        if fcMax <= fsAWG/2 
            [sigAWG, tone, phase, allTone, ~] = calcTones(fsAWG, numTones, fcMax, memSize, dev, numChan, separateTones, avg, phaseSets, minPeak);
        else
            [sigAWG, tone, phase, allTone, ~] = calcTones(fsAWG, numTones, fsAWG/2, memSize, dev, numChan, separateTones, avg, phaseSets, minPeak);
        end
    end
    if (~isempty(hMsgBox) && hMsgBox.canceling())
        break;
    end
    switch (sim)
        case 0 % use hardware
            if (~isempty(hMsgBox))
                hMsgBox.update(0.225 + 0.7 * (avg+1) / analysisAvg, sprintf('Downloading data to AWG... (%d/%d)', avg+1, analysisAvg));
            end
            if (pattLock)
                if (strncmpi(awgTrig, 'RefClk', 6))
                    trigFreq = fsAWG / 32;
                elseif (strncmp(arbConfig.model, 'M8199A', 6) && ...
                        isfield(arbConfig, 'sampleMarker') && strncmpi(arbConfig.sampleMarker, 'Sample rate / ', 14))
                    trigFreq = fsAWG / str2double(arbConfig.sampleMarker(15:end));
                elseif (~isempty(strfind(arbConfig.model, 'M8135A')))
                    trigFreq = fsAWG / 2;
                else
                    trigFreq = 16e9;    % approx. 16 GHz
                    trigFreq = round(trigFreq / fsAWG * length(sigAWG)) * fsAWG / length(sigAWG);
                    % in case we use markers, make sure that we have an integer ratio between Fs and trigFreq
                    % round to next power of 2, so that it fits evenly into sigAWG
                    if (strcmpi(awgTrig, 'Marker'))
                        trigFreq = fsAWG / (2^round(log2(fsAWG / trigFreq)));
                    end
                end
            else
                trigFreq = 0;
            end
            mtdownload(arbConfig, awgRST, fsAWG, sigAWG, trigDelay, awgChanNums, awgTrig, polarity, recalibrate, trigFreq);
            if (~isempty(hMsgBox) && hMsgBox.canceling())
                break;
            end
            if (~isempty(hMsgBox))
                hMsgBox.update(0.25 + 0.7 * (avg+1) / analysisAvg, sprintf('Uploading data from scope... (%d/%d)', avg+1, analysisAvg));
            end
            % perform auto de-skew only in first iteration
            if avg > 0
                scopeDeskew = 0 ;
            end
            if (strcmp(scopeType, 'RTScope'))
                [sigScope, fsScope] = scopeFct(arbConfig, scopeChannels, scopeTrig, memSize / fsAWG, scopeAvg, scopeAmpl, trigFreq, [], [], scopeBW, scopeSIRC, scopeDeskew);
            else
                [sigScope, fsScope] = scopeFct(arbConfig, scopeChannels, scopeTrig, memSize / fsAWG, scopeAvg, scopeAmpl, trigFreq, [], spui, scopeBW, scopeSIRC, scopeDeskew);
            end
            if (~isempty(hMsgBox) && hMsgBox.canceling())
                break;
            end
            if (isempty(sigScope))
                return;
            end
            if (autoScopeAmpl)
                scopeAmpl = 2.1 * max(abs(sigScope));
            end
            % for debugging purposes, save the relevant information
            try
                save(filename, 'fsAWG', 'sigAWG', 'tone', 'phase', 'fsScope', 'sigScope', 'scopeChannels', 'skewIncluded', 'flex');
            catch
            end
        case 1 % load from file
            %hMsgBox_save = hMsgBox;
            axesHandles_save = axesHandles;
            skewIncluded_save = skewIncluded;
            load(filename);
            try
                delete(hMsgBox);
            catch
            end
            skewIncluded = skewIncluded_save;
            axesHandles = axesHandles_save;
            hMsgBox = [];
            analysisAvg = 1;
            numChan = size(sigScope, 2);  
            if (avg == 0)
                sumMagDev = zeros(size(tone, 1), size(sigScope, 2));
                sumPhaseDev = zeros(size(tone, 1), size(sigScope, 2));
                scopeChannels = {'1' '2'};
            end
        case 2 % offline simulation
            [sigScope, fsScope] = simScope(fsAWG, polarity(1) * sigAWG, numChan, [], axesHandles);
        otherwise
            error('unknown simulation level');
    end
    %figure(501); plot((0:size(sigScope,1)-1)/fsScope, sigScope, '.-');
    if (~isempty(hMsgBox))
        hMsgBox.update(0.275 + 0.7 * (avg+1) / analysisAvg, sprintf('Analyzing data... (%d/%d)', avg+1, analysisAvg));
    end
    if (~isempty(hMsgBox) && hMsgBox.canceling())
        break;
    end
    % sanity check: scope sample rate must be > 2x largest frequency
    if (fsScope < 2 * tone(end))
        errordlg({sprintf('Scope sample rate is smaller than 2 x max.tone frequency. Please decrease max tone frequency to less than %s GHz OR reduce memory in "Advanced Settings" (DCA only)', iqengprintf(fsScope/2e9))});
        return;
    end
    % sanity check: check if captured signal has the same format as the
    % generated (not the case when VSA was connected to UXR) ; further QA
    % required before implementation (missing: only run check when connected to UXR)
%     if sum(size(sigScope)) ~= sum(size((sigAWG)))
%         errordlg('Scope capture length does not match data ; Try again with Scope *RST enabled');
%         return;
%     end
    % and analyze the mag & phase response
    if (nonlinear)
        [magDev, phaseDev, system1, skew, dcOffset, err] = analyzeNL(arbConfig, fsScope, sigScope, fsAWG, sigAWG, numTones, skewIncluded, avg);
    else
        % BK: extend to sup-Nyquist by evaluating images above Nyquist
        % (whenever bandwidth is larger than Nyquist)
        if fcMax > fsAWG/2 
            fmax = fcMax ; 
            if avg == 0
                [row_idx, col_idx] = find(fsAWG-tone<fmax) ;
                min_offset = min(row_idx(col_idx == 1));
            end
            images = fsAWG-tone(end:-1:min_offset, :);
            
            tone = [tone ; images] ;
            
            if (avg == 0)
                sumMagDev = zeros(size(tone, 1), size(sigScope, 2));
                sumPhaseDev = zeros(size(tone, 1), size(sigScope, 2));
            end
            
%             tone2 = [tone ; fsAWG-circshift(fliplr(tone(min_offset2:end, :)), size(tone,2),1)] ;
            phase = [phase ; -phase(end:-1:min_offset, :)] ;
            allTone = sort(tone(~isnan(tone))) ; 
            [magDev, phaseDev, skew, dcOffset, err] = analyzeMT(arbConfig, fsScope, sigScope, fsAWG, sigAWG, tone, phase, skewIncluded, avg);
        else
            [magDev, phaseDev, skew, dcOffset, err] = analyzeMT(arbConfig, fsScope, sigScope, fsAWG, sigAWG, tone, phase, skewIncluded, avg);
        end
    end
    % ignore obvious outliers
    isOutlier = 0;
    if (~isempty(find(isnan(phaseDev), 1)))
        isOutlier = 1;
    end
    % with separate tones, only check for outliers when a measurement is complete
    if (~separateTones && avg > 0)
        n = norm(sumPhaseDev/avg*corrFactor - phaseDev) / sqrt(length(phaseDev));
        if (debugLevel >= 1)
            fprintf('avg #%d - deviation from average: %g (expected <= 500)\n', avg+1, n);
        end
        if (isnan(n) || n > 500)
            isOutlier = 1;
        end
    end
    if (isOutlier && sim == 0)
        outlierCnt = outlierCnt + 1;
        if (outlierCnt > 4)
            err = sprintf(['Too many measurement outliers. ' ...
                'Please check the channel assignment, '...
                'reduce the max frequency and the number of frequency steps, ' ...
                'then try again.']);
            break;
        end
        % plot magnitude
        if (~isempty(axesHandles))
            axes(axesHandles(1));
        end
        plot(allTone/1e9, magDev, '.-');
        grid on;
        % plot phase
        if (~isempty(axesHandles))
            axes(axesHandles(2));
        end
        plot(allTone/1e9, phaseDev, '.-');
        grid on;
        if (debugLevel >= 1)
            figure(199);
            plot(tone/1e9, sumPhaseDev/avg - phaseDev, '.-');
            leg = cell(1, numChan);
            grid on;
            for i = 1:numChan
                leg{i} = sprintf('chan %d', awgChanNums(i));
            end
            legend(leg, 'Location', 'Southwest');
            xlabel('Frequency (GHz)');
            ylabel('Phase (degrees)');
            title(sprintf('Outlier #%d (will be ignored)', outlierCnt));
        end
        msgbox(sprintf(['Phase response measurement outlier (#%d). ' ...
            'The measurement will be repeated. ' ...
            'If this happens several times, ' ...
            'please reduce the number of frequency steps and ' ...
            'make sure that the signal is properly scaled on the scope, ' ...
            'then try again'], outlierCnt), ...
            'Measurement outlier', 'replace');
        continue;
    end
    sumMagDev = sumMagDev + magDev;
    sumPhaseDev = sumPhaseDev + phaseDev;
    sumDcOffset = sumDcOffset + dcOffset;
    avg = avg + 1;
    
    % in separateTones mode, update the plots only after one complete
    % measurement is through. Otherwise, the graphs will show zigzags
    if (~separateTones || mod(avg, numChan) == 0)
        magResult = sumMagDev / avg * corrFactor;
        % normalize to first point of first channel
        magResult = magResult - magResult(1,1);
        if (removeSinc)
            fsForSinc = fsAWG;
            if (strcmp(arbConfig.model, 'M8199A_ILV'))
                fsForSinc = fsForSinc/2;
            end
            sinc = 20*log10(sin(pi * allTone / fsForSinc) ./ (pi * allTone / fsForSinc));
            magToPlot = magResult - repmat(sinc, 1, size(sumMagDev, 2));
        else
            magToPlot = magResult;
        end
        % plot magnitude
        if (~isempty(axesHandles))
            axes(axesHandles(1));
            plot(allTone/1e9, magToPlot, '.-', 'linewidth', 2);
            leg = cell(1, numChan);
            grid on;
            for i = 1:numChan
                leg{i} = sprintf('chan %d (DC = %.1f mV)', awgChanNums(i), sumDcOffset(i) / avg * 1e3);
            end
            legend(leg, 'Location', 'Southwest');
            xlabel('Frequency (GHz)');
            ylabel('Magnitude (dB)');
        end

        phaseResult = sumPhaseDev / avg * corrFactor;
        % plot phase
        if (~isempty(axesHandles))
            axes(axesHandles(2));
            plot(allTone/1e9, phaseResult, '.-', 'linewidth', 2);
            leg = cell(1, numChan);
            grid on;
            for i = 1:numChan
                leg{i} = sprintf('chan %d (delay %.1f ps)', awgChanNums(i), (skew(1) - skew(i)) * 1e12);
            end
            legend(leg, 'Location', 'Southwest');
            xlabel('Frequency (GHz)');
            ylabel('Phase (degrees)');
            drawnow;
        end
    end
    scopeDeskew = 0;  % deskew only once
end
delete(randStream);
% if the analysis returns an error, show it.
% otherwise save as default freq/phase response
if (exist('err', 'var') && ~isempty(err))
    errordlg(err, 'Info', 'replace');
else
    clear Cal;
    Cal.Frequency_MT = allTone/1e9;
    Cal.AmplitudeResponse_MT = magResult;
    Cal.AbsPhaseResponse_MT = phaseResult;
    Cal.DCOffset = sumDcOffset / avg;
    Cal.AWGChannels = awgChanNums;
    
    % Changes BK: original (AWG) signal will be returned 
    Cal.sigAWG = sigAWG ; 
    Cal.tone = tone ;
    Cal.phase = phase;
    Cal.SampleRate = fsAWG; % required for at-rate correction
    Cal.skew = skew;
    result = Cal;
end
if (sim == 0 && restoreScope)
    if (strcmp(scopeType, 'DCA'))
        f = iqopen(arbConfig.visaAddrDCA);
        if (isempty(f))
            return;
        end
        if (isTek)
            xfprintf(f, ':RECALL:SETUP "C:\My Documents\TekScope\temp_setup"');
        else
            if (flex)
                xfprintf(f, ':DISK:SETUP:RECALL:HCONFIG ON');
                xfprintf(f, ':DISK:SETUP:RECALL "c:\temp\temp_setup.setx"');
            else
                xfprintf(f, ':RECALL:SETUP 0');
            end
        end
        iqclose(f);
    else
        f = iqopen(arbConfig.visaAddrScope);
        if (isempty(f))
            return;
        end
        % one of the two should work
        xfprintf(f, ':DISK:LOAD "c:\temp\temp_setup.set"', 1);
        xfprintf(f, ':RECALL:SETUP 0', 1);
        iqclose(f);
    end
end



function sigAWG = calcAWGSig(fsAWG, memSize, numChan)
rng(0);                                                 % Initialize random number generator
imax = 32;                                               % Define number of waveform amplitudes
sigAWG = randi(imax, memSize, numChan)-(imax+1)/2;      % Create random integer sequence



function [magDev, phaseDev, systems, skew, dcOffset, err] = analyzeNL(arbConfig, fsScope, sigScope, fsAWG, sigAWG, numTones, skewIncluded, avg)
global debugLevel;
skew = 0;
dcOffset = 0;
err = [];
numChan = size(sigScope, 2);
systems = cell(1,numChan);
magDev = nan(numTones, numChan);
phaseDev = nan(numTones, numChan);
% parameters
opt.synchronize = true;      % align input & output
opt.resample = true;         % resample output
opt.samplerateIn = fsAWG;    % input sample rate
opt.samplerateOut = fsScope; % output sample rate
if (debugLevel >= 1)
    opt.vis.sig.active = true;   % switch emulated output waveform visualizer on/off                            
    opt.vis.sig.nFigure = 2;     % visualizer figure number
    opt.vis.sig.nSamples = 30;   % display the first 30 samples
    opt.vis.sync.active = true;  % visualize sync
    opt.vis.sync.nFigure = 10;   % figure number for sync
    opt.vis.sync.nSamples = 50;  % show first N samples
end
% Parameter definitions for nlSynthesizer function
opt.memory = 2*numTones - 1;

for i = 1:numChan

    % Linear system identification
    system1 = nlSynthesizer(sigAWG, sigScope(:,i), opt);
    %showMagPhase(system1, fsAWG, size(sigAWG,1)/fsAWG, 1, 35, 'System Identification');
    impResp = system1.kernel{2};
    f1 = fft(impResp) * system1.stdOut / system1.stdIn;
    f1(ceil((length(f1))/2+1):end) = [];
    n = length(f1);
    xaxis = linspace(0, fsAWG/2-(fsAWG/2/n), n)';
    phase = 180/pi*angle(f1);
    [phase, ~, ~] = findSkew(arbConfig, phase, size(sigAWG,1)/fsAWG, xaxis, 1, 0, 0);

    irEstimated = system1.kernel{2} ...               % Normalize estimated impulse response with
                  *system1.stdOut/system1.stdIn;    % scaling factors

    if (debugLevel >= 1)
        % Visualize estimated impulse response
        figure(40);
        kEstimated = (-fix((opt.memory-1)/2):fix(opt.memory/2))/fsAWG; % index for estimated impulse response
        plot(kEstimated, irEstimated, ...       % Plot estimated impulse response                    
                'Color', [0.9 0.5 0.1], ...
                'LineStyle', '-', ...
                'Marker', '.', 'MarkerSize', 3)
        title('Estimated impulse response')
        xlabel('time (s)')
        ylabel('Impulse response')
        grid on
    end
    magDev(:,i) = 20*log10(abs(f1));
    phaseDev(:,i) = phase;
    systems{i} = system1;
end


function [trigDelay, polarity, scopeAmpl] = findTrigDelay(arbConfig, awgRST, fsAWG, memSize, scopeFct, awgChanNums, awgTrig, scopeChannels, scopeTrig, scopeAmpl, autoScopeAmpl, scopeBW, scopeSIRC, scopeDeskew, recalibrate, hMsgBox)
global debugLevel;
trigDelay = zeros(1, length(scopeChannels));
polarity = [1 1 1 1 1];
cs = memSize / 8;
sigAWG = 0.8 * [-1*ones(2*cs,1); ones(3*cs,1); -1*ones(cs,1); ones(cs,1); -1*ones(1*cs,1)];
sigAWG = repmat(sigAWG, 1, length(awgChanNums));
if (~isempty(hMsgBox))
    hMsgBox.update(0.15, 'Downloading signature signal...');
end
mtdownload(arbConfig, awgRST, fsAWG, sigAWG, [0 0], awgChanNums, awgTrig, [1 1 1], recalibrate, 0);
if (~isempty(hMsgBox))
    hMsgBox.update(0.2, 'Uploading data from scope...');
end
if (autoScopeAmpl)
    scopeAmpl = -1;   % signal to the scope routine to use automatic amplitude
end
[sigScope, fsScope] = scopeFct(arbConfig, scopeChannels, scopeTrig, memSize / fsAWG, 1, scopeAmpl, [], [], [], scopeBW, scopeSIRC, scopeDeskew);
if (isempty(sigScope))
    trigDelay = [];
    return;
end
if (autoScopeAmpl)
%     if (scopeFct == @iqreaddca)
%         scopeAmpl = -2;
%     else
        scopeAmpl = 2 * max(abs(sigScope));
%     end
end
len = size(sigScope, 1);
numCh = size(sigScope, 2);
mean = sum(sigScope) / len;
sigScope = sigScope - repmat(mean, len, 1);
% use two copies in order find the transitions even in worst case
sigScope2 = repmat(sigScope, 2, 1);
% ssig = (sigScope >= repmat(mean, len, 1));
% dsig = diff([ssig; ssig(1,:)]);
dsig = zeros(2*len, numCh);
for ch = 1:numCh
    % ignore signal levels close to zero (noise / AC coupling)
    upperTh = 0.3 * max(sigScope2(:,ch));
    lowerTh = 0.3 * min(sigScope2(:,ch));
    % find the samples that clearly exceed the noise level
    lowerSig = find(sigScope2(:,ch) < lowerTh);
    upperSig = find(sigScope2(:,ch) > upperTh);
    % find the samples where the signal changes polarity
    while (~isempty(lowerSig) && ~isempty(upperSig))
        lowerMin = min(lowerSig);
        upperMin = min(upperSig);
        dsig(lowerMin, ch) = -1;
        dsig(upperMin, ch) = 1;
        m = max(lowerMin, upperMin);
        lowerSig(lowerSig < m) = [];
        upperSig(upperSig < m) = [];
    end
end
% use only second half of dsig
dsig = dsig(len+1:end,:);
if (debugLevel >= 2)
    figure(150); plot((1:len)/fsScope, [sigScope dsig], '.-');
end
for ch = 1:numCh
    tr = find(dsig(:,ch));
    if (length(tr) ~= 4)
        try delete(hMsgBox); catch; end
        figure(150); plot((1:len)/fsScope, [sigScope dsig], '.-');
        try
            ylim([min(min(sigScope)) max(max(sigScope))]);
        catch
        end
        title('Signature signal');
        errordlg(sprintf(['Signature signal could not be captured correctly. ' ...
            'Please check connection between AWG and scope.\n\n' ...
            '(Expected to capture a signal with 4 transitions, got %d. ' ...
            'See MATLAB figure for details)'], length(tr)));
        trigDelay = [];
        return;
    end
    % convert to time
    trTime = (tr - 1) / fsScope;
    % normalized transitions should be at 2 5 6 7 for no trigger delay
    % in this case, the delta's are        3 1 1
    %        _ _ _   _
    %  _ _ _|     |_| |_
    %
    %      |   |   | |
    % Case A   B   C D
    %
    trNorm = 8 * trTime * fsAWG / memSize;
    trDelta = diff(trNorm);
    dTime = memSize / 8 / fsAWG;    % time for one "bit"
    if (isequal(round(trDelta), [3; 1; 1]))     % case A
        trigDelay(ch) = 2 * dTime - trTime(1);
        polarity(ch) = dsig(tr(1), ch);
    elseif (isequal(round(trDelta), [1; 1; 3])) % case B
        trigDelay(ch) = 2 * dTime - trTime(4);
        polarity(ch) = dsig(tr(4), ch);
    elseif (isequal(round(trDelta), [1; 3; 3])) % case C
        trigDelay(ch) = 2 * dTime - trTime(3);
        polarity(ch) = dsig(tr(3), ch);
    elseif (isequal(round(trDelta), [3; 3; 1])) % case D
        trigDelay(ch) = 2 * dTime - trTime(2);
        polarity(ch) = dsig(tr(2), ch);
    else
        try delete(hMsgBox); catch; end
        errordlg(sprintf(['Signature signal could not be captured correctly. ' ...
            'Please check connection between AWG and scope.\n\n' ...
            '(Unxpected sequence of time deltas: %d %d %d)'], round(trDelta)));
        trigDelay = [];
        return;
    end
end
if (debugLevel >= 2)
    fprintf('trDelta = %d %d %d ', round(trDelta));
    fprintf('trigDelay =');
    fprintf(' %g', trigDelay);
    fprintf(', polarity =');
    fprintf(' %d', polarity);
    fprintf('\n');
end


function mtdownload(arbConfig, awgRST, fs, sig, trigDelay, awgChanNums, awgTrig, polarity, recalibrate, trigFreq)
% initialize all channels of the AWG
chMap = [arbConfig.channelMask' zeros(size(arbConfig.channelMask,2), 1)];
% except those that are being calibrated
chMap(awgChanNums, 1) = 0;
sig0 = zeros(size(sig));
if (strcmpi(awgTrig, 'Marker') && trigFreq ~= 0)
    div = round(fs / trigFreq);
    div2 = floor(div/2);
    marker = repmat(15*[ones(div2,1); zeros(div-div2,1)], length(sig)/div, 1);
else
    marker = [];
end
if (~contains(arbConfig.model, 'M8199') && ~contains(arbConfig.model, 'M8198A'))
    iqdownload(sig0, fs, 'arbConfig', arbConfig, 'channelMapping', chMap, 'marker', marker, 'run', 0);
end
% download a signal plus trigger signal to the AWG - unless marker is used
if (str2double(awgTrig) >= 1)
    % set channel map for trigger download
    chMap = repmat([0 0], 4, 1);
    chMap(str2double(awgTrig), 1) = 1;
    if (trigFreq ~= 0)
        trig = iqtone('sampleRate', fs, 'numSamples', length(sig), 'tone', trigFreq, 'arbConfig', arbConfig);
    else
        trig = polarity(end) * 0.75 * [ones(length(sig)/2, 1); -1*ones(length(sig)/2, 1)];
    end
    iqdownload(trig, fs, 'arbConfig', arbConfig, 'channelMapping', chMap, 'run', 0);
end
% duplicate signal
sig0 = sig;
% set channel map for signal download 
chMap = zeros(size(arbConfig.channelMask,2), 2*length(awgChanNums));
% shift the signal according to trigger delay and set polarity and download
for ch = 1:length(awgChanNums)
    del = round(trigDelay(ch) * fs);
    sig(:,ch) = polarity(ch) * circshift(sig0(:,ch), del);
    chMap(awgChanNums(ch), 2*ch-1) = 1;
end
if (recalibrate)
    [sig, chMap] = iqcorrection(sig, fs, 'chMap', chMap);
end
if (strcmpi(awgTrig, 'Marker') && trigFreq ~= 0)
    div = round(fs / trigFreq);
    div2 = floor(div/2);
    marker = repmat(15*[ones(div2,1); zeros(div-div2,1)], length(sig)/div, 1);
else
    marker = [];
end
iqdownload(sig, fs, 'arbConfig', arbConfig, 'marker', marker, 'channelMapping', chMap);



function [magDev, phaseDev, skew, dcOffset, err] = analyzeMT(arbConfig, fs, sig, fsAWG, sigAWG, origTone, origPhase, skewIncluded, avg)
% analyze the captured waveform. As a "hint", pass original tones & phases
global debugLevel;
err = [];
len = size(sig,1);
numChan = size(sig,2);
skew = zeros(1, numChan);
% use degrees for phase in this function
origPhase = normDeg(origPhase * 180 / pi);
% frequency resolution
fRes = fs / len;
% remove DC offset
dcOffset = sum(sig,1) / len;
sig = sig - repmat(dcOffset, len, 1);
%fprintf('DC offset = %g mV\n', dcOffset * 1000);
% apply window
sig = repmat(gausswin(len, 3), 1, numChan) .* sig;
if (debugLevel >= 2)
    figure(201); plot((-len/2:len/2-1)/fs, sig, '.-');
    grid on;
    title('Captured signal with window function applied');
end
faxis = (0:floor(len/2)-1) * fRes;
% fft
fsig = fft(sig/len);
% only positive side is of interest
fsig = fsig(1:floor(len/2), :);
numTones = size(origTone,1);
%toneDev = zeros(numTones, numChan);
magDev = zeros(numTones, numChan);
phaseDev = zeros(numTones, numChan);
% set an initial skew (for testing purposes only)
skewX = 0;
% look at +/- 2 buckets to find max amplitude
off = 2;
phd = linspace(0, off*2*180, off*2+1)';
for ch = 1:numChan
    mag = 20 * log10(abs(fsig(:,ch)));
    phase = angle(fsig(:,ch)) * 180 / pi;
    if (debugLevel >= 2)
        figure(202+ch);
        if (avg == 0); clf; end
        hold on;
        plot(faxis, mag, '.-');
        maxmag = max(mag);
        ylim([maxmag-20, maxmag]);
        grid on;
        title('magnitude of captured signal');
    end
    %extend arrays to avoid index out of range in extreme cases
    mag = [mag; zeros(100,1)];
    phase = [phase; zeros(100,1)];
    % allow for frequency deviation between analyzer and generator
    pCorr = 0;
    peak0 = [];
    for i = 1:numTones
        if isnan(origTone(i, ch))
            continue;
        end
        % nominally closest tone bucket (zero-based)
        idx = round(origTone(i, ch) / fRes + pCorr);
        % search +/- a few buckets
        idxRange = (-off:off) + idx;
        % avoid array-index out-of-range errors at the left boundary
        idxRange(idxRange<0) = 0;
        % check if the nominal tone bucket is higher than its neighbors
        % (don't check too far away in case there is a close-by signal)
        if (mag(idx)<mag(idx+1) && mag(idx+2)<max(idx+1))
            pMax = 0;
        else
            % find the maximum index (idxRange is zero-based, so add 1)
            [~, pMax] = max(mag(idxRange+1));
            % pMax is the deviation from the nominal tone bucket
            pMax = pMax - off - 1;
        end
        % new peak index (zero-based)
        pIdx = idx + pMax;
        % interpolation to find the exact peak (note: +1 for array index)
        [peakX, peakVal, a] = qint(mag(pIdx), mag(pIdx + 1), mag(pIdx + 2));
        % pIdx is now the floating point zero-based bucket
        pIdx = pIdx + peakX;
        % remember deviation for next tone (in case the generator and
        % analyzer frequencies don't match exactly
        pCorr = pCorr + (pIdx - idx);
        if (debugLevel >= 3)
            fprintf('i =%2d, pIdx =%3d, pCorr = %.3g\n', i, pIdx, pCorr);
        end
        % determine the phase by linear interpolation
        phu = unwrapDeg(phase(idxRange+1) + phd) - phd;
        xph = interp1(-off:off, phu, pIdx - idx);
        xphu = normDeg(xph);
        % shift the unwrapped phase (for display purposes only)
        phu = phu - xph + xphu;
        % compensate original phase with skew
        origPhaseWithSkew = normDeg(origPhase(i, ch) + 360 * skewX * origTone(i, ch));
        % take magnitude of first tone of first channel as a reference
        if (isempty(peak0))
            %peak0 = peakVal;
            peak0 = 0;
        end
%        toneDev(i,k) = (origTone(i, ch) - pIdx * fRes);
        magDev(i,ch) = peakVal - peak0;
        phaseDev(i,ch) = normDeg(xphu - origPhaseWithSkew);
        % show the result
        if (debugLevel >= 3)
            idx2 = -off:0.01:off;
            yline = a * (idx2 + idx - pIdx).^2 + peakVal;
            figure(105); clf; hold on;
            plot([pIdx - idx, pIdx - idx], [-180 180], 'k:');
            plot((-off:off), phase(idxRange + 1), 'r.-');
            plot([-off off], [origPhase(i, ch) origPhase(i, ch)], 'c');
            plot([-off off], [origPhaseWithSkew origPhaseWithSkew], 'b');
            plot([-off off], [xphu xphu], 'm');
            plot((-off:off), mag(idxRange + 1), 'g.-');
            plot(idx2, yline, 'k-');
            plot((-off:off), phu, 'm-');
            ylim([-190 190]);
            legend({sprintf('peak@ %s (i=%d)', iqengprintf(origTone(i, ch)), i), ...
                    sprintf('fft (idx %g)', idx), ...
                    sprintf('origPhase %.0f', origPhase(i, ch)), ...
                    sprintf('orig+skew %.0f', origPhaseWithSkew), ...
                    sprintf('calculate %.0f', xphu), ...
                    sprintf('magnitude (pCorr = %.3g)', pCorr), ...
                    });
            res = questdlg('Continue?');
            if (~strcmp(res, 'Yes'))
                return;
            end
        end
    end % for i = 1:numTones
    if max(origTone(:,ch)) > fsAWG/2
        [phaseDev(:,ch), skew(:,ch), err] = findSkewAtRate(arbConfig, phaseDev(:,ch), length(sigAWG) / fsAWG, origTone(:,ch), ch, skewIncluded, err, fsAWG);
    else
        [phaseDev(:,ch), skew(:,ch), err] = findSkew(arbConfig, phaseDev(:,ch), length(sigAWG) / fsAWG, origTone(:,ch), ch, skewIncluded, err);
    end
end % for ch = 1:numChan



function [phaseDev, skew, err] = findSkew(arbConfig, phaseDev, duration, origTone, ch, skewIncluded, err)
% determine the delay between trigger & signal
global skew0;
global debugLevel;
% remove NaNs from origTone and phaseDev - this happens if we use
% separateTones per channel
phaseDevSave = phaseDev;
idx = isnan(origTone);
origTone(idx) = [];
phaseDev(idx) = [];
% use this number of tones to find a straight line (= delay)
% in case of M8195A, the phase starts to deviate from a straight line at about 10 GHz
cnt = find(origTone > 10e9, 1);
if strcmp(arbConfig.model, 'M8199B')
    cnt_min = 1;
    cnt_max = find(origTone > 10e9, 1);
end

% cnt = find(origTone > 1e9, 1); % investigation on fmax on
% at-rate-correction (BK)
if (isempty(cnt))
    cnt = length(origTone);
end
% in general, use only the first 1/2 of the frequnency range to determine linear phase
% because at high frequencies, the phase often jumps around
cnt = min(cnt, round(1/2*length(origTone)));
numTones = length(origTone);
if (debugLevel >= 3)
    figure(210+ch);
    plot(origTone, phaseDev/360, '.-');
    title(sprintf('Raw phase deviation ch %d', ch));
    ylabel('Phase (Periods)');
end
% Determine the absolute delay by searching one complete waveform duration (+ margin)
% first channel searches over an arbitrary range
skewList = linspace(-duration * 0.51, duration * 0.51, 1001);
[modNum, modChNum] = getModNum(arbConfig, ch);
if (modChNum > 1)
    % for the following channels, assume that the absolute delay is similar
    % and move the search range, to make is less likely to jump from
    % beginning to end
    skewList = skewList - skew0(modNum);
end
nm1 = zeros(length(skewList), 1);
for i = 1:length(skewList)
    skewGuess = skewList(i);
    % linear phase delta in degrees for a given skew
    phdelta = skewGuess * origTone * 360;
    % remove the skew (= linear phase) and unwrap the phase
    phaseDevUnwrap = unwrapDeg(phaseDev + phdelta) - phdelta;
    % fit a straight line to up to a certain frequency
    if strcmp(arbConfig.model, 'M8199B')
       pf = polyfit(origTone(cnt_min:cnt_max) / 1e9, phaseDevUnwrap(cnt_min:cnt_max), 1);  
    else
        pf = polyfit(origTone(1:cnt) / 1e9, phaseDevUnwrap(1:cnt), 1);
    end
    pfy = polyval(pf, origTone / 1e9);
    % best fit is determined by a "smooth" phase response, i.e. by a small
    % norm value
    nm1(i) = norm(diff(phaseDevUnwrap - pfy));
end
[minVal, minIdx] = min(nm1);
% best fit skew
skewGuess = skewList(minIdx);
if (debugLevel >= 2)
    figure(220+ch); clf;
    plot(skewList/1e-9, nm1, '.-');
    title(sprintf('Phase match vs. skew, ch %d', ch));
    xlabel('skew (nsec)');
    ylabel('norm');
    legend(sprintf('skew = %s, norm = %.3g', iqengprintf(skewGuess), minVal));
end
% same calculation as above - with the "best" skew value
phdelta = skewGuess * origTone * 360;
phaseDev = unwrapDeg(phaseDev + phdelta) - phdelta;
pf = polyfit(origTone(1:cnt) / 1e9, phaseDev(1:cnt), 1);
if (debugLevel >= 2)
    figure(240);
    if (ch == 1); clf; end
    hold all;
    plot(origTone/1e9, phaseDev/360, 'o-');
    ipx = [0; origTone/1e9];
    plot(ipx, polyval(pf, ipx)/360);
    legend({'phase', 'interpolation'});
    xlabel('Frequency (GHz)'); ylabel('Phase (Periods)');
    xlim([0 origTone(3)/1e9]);
end
% skew is derived from the slope of the fitting line
skew = pf(1) / 360 / 1e9;
% round the Y-axis crossing to full periods
bx = round(pf(2) / 360) * 360;
if (abs(bx - pf(2)) > 90)
    % don't create a warning because calibration works anyways
    %err = 'Signal appears to be inverted. Measured phase response is most likely incorrect. Please verify connection';
    %warndlg('Signal appears to be inverted. Measured phase response is most likely incorrect. Please verify connection', 'Info', 'replace');
    bx = round(pf(2) / 180) * 180;
end
if (minVal / sqrt(numTones) > 500)
    %err = 'Measured phase response is most likely incorrect. Please verify connection.';
    warndlg('Measured phase response is most likely incorrect. Please verify connection.', 'Info', 'replace');
end
% the linear phase that is removed is determined by the matching line
skewApplied = skew;
if (modChNum == 1)
    skew0(modNum) = skewApplied;        % remember skew for other channels in a global variable
else
    if (skewIncluded)
        skewApplied = skew0(modNum);    % if skew is to be included in phase, then apply the same skew as for channel 1
    end
end
% remove linear phase and integer periods
phaseDev = unwrapDeg(phaseDev - skewApplied * 360 * origTone - bx);
if (debugLevel >= 1)
    fprintf('ch%d, bx=%6.0f, pf(1)=%7.0f, pf(2)=%7.0f, skewGuess =%7.0f ps, skew =%7.0f ps, norm = %.0f\n', ...
        ch, bx/360, pf(1), pf(2), skewGuess * 1e12, skew * 1e12, minVal);
    figure(250);
    if (ch == 1); clf; end
    hold all;
    plot(origTone/1e9, (phaseDev / 360), '.-');
    xlabel('Frequency (GHz)'); ylabel('Phase (Periods)');
end
% re-insert zeros where they have been removed in case of separate tones
phaseDevSave(~idx) = phaseDev;
phaseDev = phaseDevSave;

function [phaseDev, skew, err] = findSkewAtRate(arbConfig, phaseDev, duration, origTone, ch, skewIncluded, err, fsAWG)
% determine the delay between trigger & signal
global skew0;
global debugLevel;
% remove NaNs from origTone and phaseDev - this happens if we use
% separateTones per channel
phaseDevSave = phaseDev;
idx = isnan(origTone);
origTone(idx) = [];
phaseDev(idx) = [];
% use this number of tones to find a straight line (= delay)
% in case of M8195A, the phase starts to deviate from a straight line at about 10 GHz
% cnt = find(origTone > 10e9,1);
cnt = find(origTone > fsAWG/2, 1);
cnt = cnt-1;
cnt_min = find(origTone>10e9,1);
% cnt = find(origTone > 1e9, 1); % investigation on fmax on
% at-rate-correction (BK)
if (isempty(cnt))
    cnt = length(origTone);
end

numTones = length(origTone);
if (debugLevel >= 3)
    figure(210+ch);
    plot(origTone, phaseDev/360, '.-');
    title(sprintf('Raw phase deviation ch %d', ch));
    ylabel('Phase (Periods)');
end
% Determine the absolute delay by searching one complete waveform duration (+ margin)
% first channel searches over an arbitrary range
skewList = linspace(-duration * 0.51, duration * 0.51, 1001);
[modNum, modChNum] = getModNum(arbConfig, ch);
if (modChNum > 1)
    % for the following channels, assume that the absolute delay is similar
    % and move the search range, to make is less likely to jump from
    % beginning to end
    skewList = skewList - skew0(modNum);
end
nm1 = zeros(length(skewList), 1);
for i = 1:length(skewList)
    skewGuess = skewList(i);
    % linear phase delta in degrees for a given skew
    phdelta = skewGuess * origTone * 360;
    % remove the skew (= linear phase) and unwrap the phase
    phaseDevUnwrap = unwrapDeg(phaseDev + phdelta) - phdelta;
    % fit a straight line to up to a certain frequency
    pf = polyfit(origTone(cnt_min:cnt) / 1e9, phaseDevUnwrap(cnt_min:cnt), 1);
    pfy = polyval(pf, origTone / 1e9);
    % best fit is determined by a "smooth" phase response, i.e. by a small
    % norm value
    nm1(i) = norm(diff(phaseDevUnwrap - pfy));
end
[minVal, minIdx] = min(nm1);
% best fit skew
skewGuess = skewList(minIdx);
if (debugLevel >= 2)
    figure(220+ch); clf;
    plot(skewList/1e-9, nm1, '.-');
    title(sprintf('Phase match vs. skew, ch %d', ch));
    xlabel('skew (nsec)');
    ylabel('norm');
    legend(sprintf('skew = %s, norm = %.3g', iqengprintf(skewGuess), minVal));
end
% same calculation as above - with the "best" skew value
phdelta = skewGuess * origTone * 360;
phaseDev = unwrapDeg(phaseDev + phdelta) - phdelta;
pf = polyfit(origTone(cnt_min:cnt) / 1e9, phaseDev(cnt_min:cnt), 1);
if (debugLevel >= 2)
    figure(240);
    if (ch == 1); clf; end
    hold all;
    plot(origTone/1e9, phaseDev/360, 'o-');
    ipx = [0; origTone/1e9];
    plot(ipx, polyval(pf, ipx)/360);
    legend({'phase', 'interpolation'});
    xlabel('Frequency (GHz)'); ylabel('Phase (Periods)');
    xlim([0 origTone(3)/1e9]);
end
% skew is derived from the slope of the fitting line
skew = pf(1) / 360 / 1e9;
% round the Y-axis crossing to full periods
bx = round(pf(2) / 360) * 360;
if (abs(bx - pf(2)) > 90)
    % don't create a warning because calibration works anyways
    %err = 'Signal appears to be inverted. Measured phase response is most likely incorrect. Please verify connection';
    %warndlg('Signal appears to be inverted. Measured phase response is most likely incorrect. Please verify connection', 'Info', 'replace');
    bx = round(pf(2) / 180) * 180;
end
if (minVal / sqrt(numTones) > 500)
    %err = 'Measured phase response is most likely incorrect. Please verify connection.';
    warndlg('Measured phase response is most likely incorrect. Please verify connection.', 'Info', 'replace');
end
% the linear phase that is removed is determined by the matching line
skewApplied = skew;
if (modChNum == 1)
    skew0(modNum) = skewApplied;        % remember skew for other channels in a global variable
else
    if (skewIncluded)
        skewApplied = skew0(modNum);    % if skew is to be included in phase, then apply the same skew as for channel 1
    end
end
% remove linear phase and integer periods
phaseDev = unwrapDeg(phaseDev - skewApplied * 360 * origTone - bx);
if (debugLevel >= 1)
    fprintf('ch%d, bx=%6.0f, pf(1)=%7.0f, pf(2)=%7.0f, skewGuess =%7.0f ps, skew =%7.0f ps, norm = %.0f\n', ...
        ch, bx/360, pf(1), pf(2), skewGuess * 1e12, skew * 1e12, minVal);
    figure(250);
    if (ch == 1); clf; end
    hold all;
    plot(origTone/1e9, (phaseDev / 360), '.-');
    xlabel('Frequency (GHz)'); ylabel('Phase (Periods)');
end
% re-insert zeros where they have been removed in case of separate tones
phaseDevSave(~idx) = phaseDev;
phaseDev = phaseDevSave;


function id = buildID(arbConfig, chanNum)
% construct the M8070 identifier for a given AWG channel number
id = '';
if (~isscalar(chanNum))
    error('chanNum must be scalar');
end
% number of channels per module
if (strcmp(arbConfig.model, 'M8199A_ILV'))
    cpm = 2;
else
    cpm = 4;
end
if (chanNum <= cpm)
    id = sprintf('%s.DataOut%d', arbConfig.M8070ModuleID, chanNum);
else
    modNum = floor((chanNum - 1) / cpm);
    modChNum = chanNum - (cpm * modNum);
    modIDName = sprintf('M8070ModuleID%d', modNum + 1);
    if (isfield(arbConfig, modIDName))
        id = sprintf('%s.DataOut%d', arbConfig.(modIDName), modChNum);
    else
        errordlg(sprintf('Field Name %s not found in buildID', modIDName));
    end
end


function [modNum, modChNum] = getModNum(arbConfig, chanNum)
% construct moduleID and channel within module for a given AWG channel number
% this is only relevant for M8199A while module-module synchronization does
% not work.
if (~isscalar(chanNum))
    error('chanNum must be scalar');
end
modNum = 1;
modChNum = chanNum;
% number of channels per module
switch (arbConfig.model)
    case 'M8199A', cpm = 4;
    case 'M8199A_ILV', cpm = 2;
    otherwise, return;
end

% ok, it is an M8199A, let's find out which software version it is...
f = iqopen(arbConfig);
if (isempty(f))
    return;
end
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
    error('cannot decode module driver information');
end
if ~isfield(info, 'ProductNumber') || ~strcmp(info.ProductNumber, 'M8199A')
    error('unexpected product number');
end
if isfield(info, 'SoftwareVersion')
    swVersionL = sscanf(info.SoftwareVersion, '%d.%d.%d.%d');
    swVersion = 1000000 * swVersionL(1) + 1000 * swVersionL(2) + swVersionL(3);
else
    swVersionL = [];
    swVersion = -1;
end
if (length(swVersionL) ~= 4)
    error('no software version or unexpected format');
end
if (swVersion < 1001000)
    modNum = floor((chanNum - 1) / cpm) + 1;
    modChNum = chanNum - (cpm * (modNum - 1));
end



function y = normDeg(x)
% normalize an angle to the range -180...+180
y = mod(x + 180, 360) - 180;



function p = unwrapDeg(p)
% same as unwrap(), but for angle in degrees
% (code is copied from MATLAB unwrap function)
m = length(p);
% Unwrap phase angles.  Algorithm minimizes the incremental phase variation 
% by constraining it to the range [-180,180]
dp = diff(p,1,1);                % Incremental phase variations
dps = mod(dp+180,360) - 180;     % Equivalent phase variations in [-180,180)
dps(dps==-180 & dp>0,:) = 180;   % Preserve variation sign for 180 vs. -180
dp_corr = dps - dp;              % Incremental phase corrections
dp_corr(abs(dp)<180,:) = 0;      % Ignore correction when incr. variation is < CUTOFF
% Integrate corrections and add to P to produce smoothed phase values
p(2:m,:) = p(2:m,:) + cumsum(dp_corr,1);


function [sig, fs] = simScope(fs, sig, separateTones, delay, axesHandles)
% simulate the effects of capturing the signal
fsScope = 100e9;
sig = repmat(sig, 2, 1);
[p, q] = rat(fsScope / fs);
% resample
sig =  resample(sig, p, q);
fs = fs * p / q;
% make it an arbitrary length and delay the signal by a number of samples
if (~exist('delay', 'var') || isempty(delay))
    delay = 20;
end
% simulate trigger delay
%sig = [sig(delay+1:end); sig(1:delay)];
for k = 1:size(sig, 2)
    sig(:,k) = circshift(sig(:,k), delay);
    delay = delay + 1;
end
% modify mag & phase
sig = modMagPhase(sig, fs, axesHandles);
% add non-linear distortions
%sig = sig + 0.01*(sig.^2);
% add noise
sig = awgn(sig, 30);
% if separate tones, pretent that signals are mixed together to a certain
% percentage
if (separateTones)
    mixPct = 1;
    sigSum = sum(sig, 2) / size(sig, 2);
    for i=1:size(sig, 2)
        sig(:,i) = (1-mixPct) * sig(:,i) + mixPct * sigSum;
    end
end



function result = modMagPhase(sig, fs, axesHandles)
% add some magnitude & phase response to a signal for testing purposes
freq = [0    5  20   40   70 100;   0    5  20   40   70 100;   0    5  20   40   70 100;   0    5  20   40   70 100];
mag  = [0    0  -2   -8  -10 -10;   0   -1  -3   -5  -12 -12;   0    0  -1   -4   -8  -8;   0    0 -.5   -2   -4  -6];
ph   = [0    0   0  -20  -80 -80;   0    0   0  -10  -50 -50;   0    0   0  -10  -60 -60;   0    0   0  -10  -70 -70];
% limit to the number of channels we need (= columns of sig)
freq = freq(1:size(sig,2),:);
mag = mag(1:size(sig,2),:);
ph = ph(1:size(sig,2),:);
% frequency axis for FFT
len = length(sig);
fpts = linspace(-len/2, len/2-1, len) / len * fs;
freq = freq * fs/2 / 100;
if (~isempty(axesHandles))
    axes(axesHandles(1));
    hold off;
    plot(freq'/1e9, mag', '--');
    hold on;
    axesHandles(1).ColorOrderIndex = 1;
    axes(axesHandles(2));
    hold off;
    plot(freq'/1e9, ph', '--');
    hold on;
    axesHandles(2).ColorOrderIndex = 1;
end
freq = [-1 * fliplr(freq) freq(:,2:end)];
mag =  [fliplr(mag) mag(:,2:end)];
ph =   [-1 * fliplr(ph) ph(:,2:end)];
xmag = zeros(size(freq,1), size(sig,1));
xph = zeros(size(freq,1), size(sig,1));
filt = zeros(size(freq,1), size(sig,1));
for i=1:size(freq,1)
    xmag(i,:) = interp1(freq(i,:), mag(i,:), fpts);
    xph(i,:)  = interp1(freq(i,:), ph(i,:), fpts);
    filt(i,:) = 10 .^ (xmag(i,:)' / 20) .* exp(1i * xph(i,:)' * pi / 180);
end
sigfft = fft(sig, [], 1);
filtfft = fftshift(filt.', 1);
result = real(ifft(sigfft .* filtfft, [], 1));



function [sig, tone, phase, allTone, allPhase] = calcTones(fs, numTones, fcMax, memSize, dev, numChan, separateTones, avg, phaseSets, minPeak)
% calculate a multi-tone signal for each channel
% will use the phaseSets and minPeak that have been calculated earlier to
% make sure that all tone sets are scaled by the same amount
%
% sig(memSize x numChan)   --> multitone signal per channel
% tone(numTones x numChan) --> tone frequencies for per channel (some are NaN in case of separateTones)
% phase(numTones x numChan)--> tone phases for per channel (some are NaN in case of separateTones)
% allTone(numTones x 1)    --> all tones
% allPhase(numTones x 1)   --> all phases
global debugLevel;
[toneIdx, allTone] = calcToneIdx(fs, memSize, numTones, dev, fcMax);
% when using separate tones per channel, use a new set of phases only
% at the beginning of one "round" of measurements
if (separateTones)
    % if separate tones per AWG channel are needed, split the "comb" and
    % fill unused tones and phases with NaN
    phaseSetIdx = floor(avg / numChan) + 1;
    allPhase = phaseSets(:,phaseSetIdx);
    len = size(allTone, 1);
    tone = nan(len, numChan);
    phase = nan(len, numChan);
    sig = zeros(memSize, numChan);
    for i = 1:numChan
        % on every iteration through the average loop, rotate the tone
        % assignment, so that after <numChan> iterations, each channel has
        % seen all tones
        startIdx = mod(i+avg-1, numChan)+1;
        idx = startIdx:numChan:len;
        tone(idx,i) = allTone(idx);
        phase(idx,i) = allPhase(idx);
        toneFFT = zeros(memSize, 1);
        toneFFT(toneIdx(idx)) = exp(1j * allPhase(idx));
        toneFFT = [0; toneFFT(1:end-1)];  % first entry is 0 Hz
        sig(:,i) = real(ifft(toneFFT)) / minPeak;
    end
    % since we are using fewer tones, we have some headroom in the DAC range
    % in theory, we have 10*log10(ratio_of_numTones) more power available
    % or 20*log10(ratio_of_numTones) more amplitude --> sqrt(numChan)
    % But for some reason, that is too much. 
    sig = sig * sqrt(sqrt(numChan));
else
    phaseSetIdx = avg + 1;
    allPhase = phaseSets(:,phaseSetIdx);
    toneFFT = zeros(memSize, 1);
    toneFFT(toneIdx) = exp(1i * allPhase);
    toneFFT = [0; toneFFT(1:end-1)];  % first entry is 0 Hz
    sig = real(ifft(toneFFT)) / minPeak;
    sig = repmat(sig, 1, numChan);  % same signal on all channels
    tone = repmat(allTone, 1, numChan);
    phase = repmat(allPhase, 1, numChan);
end
% just in case we have an extreme peak - just clip it
sig(sig>1) = 1;
sig(sig<-1) = -1;
if (debugLevel >= 1)
    maxVals = max(abs(sig));
    fprintf('phaseSetIdx = %d, scale = %g, maxVal =%s\n', phaseSetIdx, minPeak, sprintf(' %-9g', maxVals));
end



function [phaseSets, minPeak] = findBestPhaseSets(fs, numTones, fcMax, memSize, dev, randStream, numSets)
% find <numSets> sets of phases with minimal peak-to-average power ratio
% returns the smallest scaling factor <minPeak> that works for all sets
[toneIdx, ~] = calcToneIdx(fs, memSize, numTones, dev, fcMax);
% initialize the set of phases
phaseSets = zeros(numTones, numSets);
% starting value for searching
minPeak = 999;
% keep the numSets lowest peak values
peakList = repmat(minPeak, numSets, 1);
numTries = 100;
for i = 1:numTries
    phase = (randStream.rand(numTones,1) * 2) * pi;
    toneFFT = zeros(memSize, 1);
    toneFFT(toneIdx) = exp(1i * phase);
    toneFFT = [0; toneFFT(1:end-1)];  % first entry is 0 Hz
    sig = real(ifft(toneFFT));
    peak = max(abs(sig));
    if (peak < minPeak)
        % found a candidate - replace the worst one in the peakList
        [~, maxIdx] = max(peakList);
        peakList(maxIdx) = peak;
        phaseSets(:,maxIdx) = phase;
        minPeak = max(peakList);
    end
end



function [toneIdx, tone] = calcToneIdx(fs, memSize, numTones, dev, fcMax)
% frequency resolution
fRes = fs / memSize;
% % distance of frequency buckets
dist = floor(fcMax / numTones / fRes);
% highest frequency bucket
maxIdx = dist * numTones;
%fprintf('fcMax = %.20g, fRes = %.20g, maxIdx = %d, dist = %d\n', fcMax, fRes, maxIdx, dist);
if (max(dev) - min(dev) >= dist)
    error('maximum deviation is more than tone distance');
end
% calculate tone buckets
toneIdx = linspace(dist, maxIdx, numTones)' + dev;
% verify, if IMDs fall on other tones
%verifyTones(toneIdx, dev, memSize, fRes);
tone = toneIdx * fRes;
% toneIdx(end) = round(memSize/2-dist);
% tone(end) =  toneIdx(end) * fRes;

function verifyTones(toneIdx, dev, memSize, fRes)
% verify that IMDs don't fall on top of tones in a multitone signal
numTones = length(toneIdx);
buckets = zeros(memSize / 2, 1);
buckets(toneIdx) = 200;
for i = 1:numTones
    imdIdx = 2 * toneIdx - toneIdx(i);
    imdIdx(i) = [];
    imdIdx = imdIdx(imdIdx >= 1);
    imdIdx = imdIdx(imdIdx <= memSize / 2);
    xx = (buckets(imdIdx) >= 150);
    xi = find(xx);
    if (~isempty(xi))
        for k = xi'
            p = find(toneIdx == imdIdx(k), 1);
            q = find(toneIdx == ((toneIdx(p) + toneIdx(i)) / 2), 1);
            fprintf('i=%d, p=%d, q=%d, tone(i)=%d / %d, tone(p)=%d / %d, tone(q)=%d / %d\n', i, p, q, toneIdx(i), dev(i), toneIdx(p), dev(p), toneIdx(q), dev(q));
        end
    end
    buckets(imdIdx) = buckets(imdIdx) + 1;
end
figure(3);
stem(linspace(fRes, memSize*fRes/2, memSize/2), buckets, 'filled');


function dev = mkDev(numTones)
% calculate a set of bucket "deviations" for a multitone signal
% such that IMD's don't fall on top of tones
val = 3; % start dev
numD = numTones;  % approx. how many different devs we will need
arr = [];
while length(arr) < numD
  while check([arr; val], 0) ~= 0
      val = val + 1;
  end
  arr = [arr; val];
end
dev = [];
maxIdx = 1;
while length(dev) < numTones
    idx = 1;
    while (check([dev; arr(idx)], 1000) ~= 0)
        idx = idx + 1;
    end
    if (idx > maxIdx)
        maxIdx = idx;
    end
    dev = [dev; arr(idx)];
end
%fprintf('numDevs = %d, maxDev = %d\n', maxIdx, arr(maxIdx));
%fprintf('%d ', dev);
%fprintf('\n');


function result = check(a, o)
l = length(a);
offset = linspace(o, l*o, l)';
a = reshape(a, l, 1) + offset;
a2 = 2*a;
as = repmat(a, 1, l) + repmat(a', l, 1);
for i=1:l
    as(i,i) = 0;
end
inter = intersect(a2, as(1:end));
%disp(inter/2);
result = length(inter);


function [p,y,a] = qint(ym1,y0,yp1) 
%QINT - quadratic interpolation of three adjacent samples
%
% [p,y,a] = qint(ym1,y0,yp1) 
%
% returns the extremum location p, height y, and half-curvature a
% of a parabolic fit through three points. 
% Parabola is given by y(x) = a*(x-p)^2+b, 
% where y(-1)=ym1, y(0)=y0, y(1)=yp1. 

p = (yp1 - ym1)/(2*(2*y0 - yp1 - ym1)); 
y = y0 - 0.25*(ym1-yp1)*p;
a = 0.5*(ym1 - 2*y0 + yp1);

