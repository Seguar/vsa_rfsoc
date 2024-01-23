function [result, rmsData] = iqskewcalM8199A(varargin)
% Skew calibration for M8199A
% supports non-interleaved mode and interleaved mode
% supports real-time scope & DCA
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
% 'autoscopeampl' - if set to 1, scope amplitude will be determined automatically
% 'debuglevel' - 0=no debug output, value between 1 and 3 - more debug output
% 'restoreScope' - if set to 1 (default), will restore scope settings after
%    calibration is complete
%
% If called without arguments, opens a graphical user interface to specify
% parameters

% T.Dippon, Keysight Technologies 2020
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
result = [];
rmsData = [];
axesHandles = [];
scopeType = 'RTScope';
% averaging on capture
scopeAvg = 4;
% scopeAmpl of the signal (can be a vector)
scopeAmpl = 600e-3;
% AWG channels as a cell array, last one is the trigger channel
awgChannels = {'1' '2' 'unused' 'unused' 'unused'};
% measured channels (must be a cell array of strings. Last entry is the trigger channel
scopeChannels = {'1' '2' 'unused', 'unused', '3'};
% reset the scope
scopeRST = 1;
% reset the AWG
awgRST = 1;
% configuration struct
arbConfig = [];
% sample rate for AWG
fsAWG = [];
% automatic amplitude detection on the scope
autoScopeAmpl = 1;
% set to 1 if Flex DCA software is used
flex = 0;
% restore scope settings after calibration
restoreScope = 1;
% bandwidth used in the scope
scopeBW = [];
% turn SIRC on/off
scopeSIRC = [];
% avoid dialog for reset/use previous/cancel
overwrite = [];
% create a random stream (used for phases & tone deviations)
randStream = RandStream('mt19937ar', 'seed', 12345); 
randStream.reset();
err = [];
% mode: 'skew', 'amplitude', 'skew_and_amplitude'
% mode = 'skew_and_amplitude';
mode = 'skew';
% perform auto-deskew in the scope (so far, only implemented in the DCA)
scopeDeskew = 1;
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
            case 'overwrite';      overwrite = varargin{i+1};
            case 'mode';           mode = varargin{i+1};
            case 'scopedeskew';    scopeDeskew = varargin{i+1};
            case 'arbconfig';      arbConfig = varargin{i+1};
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
hMsgBox = iqwaitbar('Please wait...');

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

if (~contains(arbConfig.model, 'M8199A') && ~contains(arbConfig.model, 'M8199B'))
    errordlg('Skew calibration is only implemented for the M8199A/B. Please select the desired AWG model in the "Instrument Configuration"');
    return;
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

% reset AWG if desired
if (awgRST)
    % don't send a plain *RST command because synchronized systems
    % must be reset in proper order
    arbTmp = arbConfig;
    arbTmp.do_rst = 1;
    iqdownload([], 0, 'arbConfig', arbTmp);
end
if (~isempty(hMsgBox) && hMsgBox.canceling())
    return;
end

% save scope setup
if isequal(scopeFct, @iqreadscope)
    % realtime scope
    fscope = iqopen(arbConfig.visaAddrScope);
    if (isempty(fscope))
        return;
    end
    raw_idn = xquery(fscope, '*IDN?');
    % one of the two save commands should work...  (ignore errors)
    xfprintf(fscope, ':DISK:SAVE:SETUP "c:\temp\temp_setup.set"', 1);
    xfprintf(fscope, ':SAVE:SETUP 0', 1);
else
    % DCA
    fscope = iqopen(arbConfig.visaAddrDCA);
    if (isempty(fscope))
        return;
    end
    raw_idn = xquery(fscope, '*IDN?');
    idn = strsplit(raw_idn,',');
    if (strncmp(idn{2}, '86100C', 6))
        errordlg('86100C is not supported. Please use an N1000A or 86100D');
        return;
    end
    xfprintf(fscope, ':DISK:SETUP:SAVE "c:\temp\temp_setup.setx"');
end

% start deskew process
numChan = length(scopeChannels);
sigLen = 4096;
% decide which case we have
result = 0;
if (strcmp(arbConfig.model, 'M8199A_ILV') || strcmp(arbConfig.model, 'M8199B'))
    [result, rmsData] = skewCal_ILV(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, ...
        scopeAvg, scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, ...
        overwrite, mode, scopeDeskew, sim, scopeType, numTones, awgRST, fcMax, analysisAvg, toneDevType, ...
        memSize, awgTrig, raw_idn);
elseif (strcmp(arbConfig.model, 'M8199A'))
    if (numChan < 2)
        errordlg('Please specify at least 2 channels for skew calibration in non-interleaved mode');
    else
        result = skewCal_NonILV(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, ...
            scopeAvg, scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, overwrite, mode, scopeDeskew);
    end
else
    errordlg(sprintf('unexpected AWG model: %s', arbConfig.model));
end
% restore the scope setup
if (restoreScope)
    if (strcmp(scopeType, 'DCA'))
        FScope = iqopen(arbConfig.visaAddrDCA);
        if (~isempty(FScope))
            xfprintf(FScope, ':DISK:SETUP:RECALL:HCONFIG ON');
            xfprintf(FScope, ':DISK:SETUP:RECALL "c:\temp\temp_setup.setx"');
            iqclose(FScope);
        end
    else
        FScope = iqopen(arbConfig.visaAddrScope);
        if (~isempty(FScope))
            % one of the two should work
            xfprintf(FScope, ':DISK:LOAD "c:\temp\temp_setup.set"', 1);
            xfprintf(FScope, ':RECALL:SETUP 0', 1);
            iqclose(FScope);
        end
    end
end


function skew = findEdgeSkew(sigScope, fsScope, axesHandles)
len = size(sigScope,1);
numChan = size(sigScope,2);
skew = nan(numChan, 1);
% plot captured signal
if (~isempty(axesHandles))
    axes(axesHandles(1));
    cla reset;
else
    figure(1);
    clf;
end
hold on;
for ch = 1:numChan
    sigChan = sigScope(:,ch);
    cmp1 = [];
    cmp2 = [];
    maxVal = max(sigChan);
    minVal = min(sigChan);
    % define thresholds for DAC1 and DAC2
    th1 = (3*maxVal + minVal) / 4;
    th2 = (maxVal + 3*minVal) / 4;
    % find position of rising edges
    cmp1 = find(diff(sigChan > th1)>0) + 1;
    cmp2 = find(diff(sigChan > th2)>0) + 1;
    if (length(cmp1) > 4 || length(cmp2) > 4)
        plot((0:len-1)/fsScope, sigChan, '.-');
        grid on;
        errordlg(sprintf('Ch %d: Too many edges detected. Please check the scope setup', ch));
        return;
    end
    % eliminate the points near the edge of the waveform
    cmp1(cmp1 < 0.24*len) = [];
    cmp1(cmp1 > 0.76*len) = [];
    % should have exactly one left. If there is still more than two, pick the first
    if (isempty(cmp1))
        errordlg(sprintf('Ch %d: Could not find a rising edge within the expected range', ch));
    else
        cmp1 = cmp1(1);
    end
    % eliminate the other edges that are too far away from the first
    cmp2(cmp2 < (cmp1 - 0.26*len)) = [];
    cmp2(cmp2 > (cmp1 + 0.26*len)) = [];
    if (isempty(cmp2))
        errordlg(sprintf('Ch %d: Could not find a rising edge within the expected range', ch));
    else
        cmp2 = cmp2(1);
    end
    % determine the distance (in time) between the rising edges
    if (~isempty(cmp1) && ~isempty(cmp2))
        skew(ch) = (cmp1 - cmp2) / fsScope;
    end
    g = gca();
    col = g.ColorOrder;
    plot((0:len-1)/fsScope, sigChan, '.-', 'Color', col(ch,:));
    plot([0 len-1]/fsScope, [th1 th1], '-.', 'Color', (col(ch,:)+1)/2);
    plot([0 len-1]/fsScope, [th2 th2], ':');
    if (~isempty(cmp1))
        plot([cmp1 cmp1]/fsScope, [minVal maxVal], '-.', 'Color', (col(ch,:)+1)/2);
    end
    if (~isempty(cmp2))
        plot([cmp2 cmp2]/fsScope, [minVal maxVal], ':', 'Color', (col(ch,:)+1)/2);
    end
end
hold off;


function skew = analyzeWfm(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, scopeAvg, scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, overwrite, mode, scopeDeskew, trigFreq)
% capture the square wave signal from the scope and find the skew between
% lower and upper transition
skew = NaN;
duration = 2*sigLen / fsAWG;
if (autoScopeAmpl)
    scopeAmpl = -1;
end
if isequal(scopeFct, @iqreadscope)
    trigDelay = -duration/2;
    trigLevel = 0;
    scopeAvg = 1;  % don't do any averaging because trigger is unreliable
    [sigScope, fsScope] = scopeFct(arbConfig, scopeChannels, 'unused', duration, scopeAvg, scopeAmpl, [], trigDelay, trigLevel);
else
    dataRate = fsAWG;
    spb = 8;
    scopeAvg = 1;
    [sigScope, fsScope] = scopeFct(arbConfig, scopeChannels, [], duration, scopeAvg, scopeAmpl, trigFreq, dataRate, spb, scopeBW, scopeSIRC, scopeDeskew);
end
if (isempty(sigScope))
    return;
end
skew = findEdgeSkew(sigScope, fsScope, axesHandles);
    

    
function [retVal, rmsData] = skewCal_ILV(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, scopeAvg, ...
    scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, overwrite, mode, scopeDeskew, ...
    sim, scopeType, numTones, awgRST, fcMax, analysisAvg, toneDevType, memSize, awgTrig, raw_idn)
retVal = 0;
rmsData = struct();
rmsData.version = 2;
numChan = length(awgChanNums);
hMsgBox.update(0.05, 'Checking connections...'); if hMsgBox.canceling(); return; end
fAWG = iqopen();
if (isempty(fAWG))
    return;
end
if strcmp(arbConfig.model, 'M8199A_ILV')
    swVersion = getSwVersion(fAWG, arbConfig);
else 
   swVersion = 1234567 ;    % dummy SW version for M8199B 
end
if isequal(scopeFct, @iqreadscope)
    fscope = iqopen(arbConfig.visaAddrScope);
else
    fscope = iqopen(arbConfig.visaAddrDCA);
end
if (isempty(fscope))
    return;
end
if (scopeRST)
    xfprintf(fscope, '*RST');
end
xfprintf(fscope, '*CLS');

if (~isempty(strfind(mode, 'skew')))
    skew0 = zeros(numChan, 1);
    skew1 = zeros(numChan, 1);
    
    % reset the interleave skew in M8070
    for k = 1:length(awgChanNums)
        xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), 0));
        if (~isempty(strfind(mode, 'amplitude')))
            xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:AMPL "%s",%g', buildID(arbConfig, awgChanNums(k)), 1));
        end
    end

    % pretend that we are in non-interleaved mode, so that we can address each channel individually
    arbConfigX = arbConfig;
    if strcmp(arbConfig.model, 'M8199A_ILV')
       arbConfigX.model = 'M8199A';
    else
       arbConfigX.model = 'M8199B_NONILV';
    end
    arbConfigX = loadArbConfig(arbConfigX);
    if (isequal(scopeFct, @iqreaddca))
        if (isfield(arbConfigX, 'sampleMarker') && strncmpi(arbConfigX.sampleMarker, 'Sample rate / ', 14))
            arbConfigX.sampleMarker = sprintf('Sample rate / %d', str2double(arbConfigX.sampleMarker(15:end)) / 2);
        end
    end
    if (~isempty(axesHandles))
        axes(axesHandles(2));
        cla reset;
    else
        figure(2);
        clf;
    end
    ax = gca();
    for ch = 1:numChan
        %awgChanNumsX = awgChanNums;
        awgChanNumsX = awgChanNums(ch);
        awgChanNumsX = floor((awgChanNumsX - 1) / 2) * 4 + mod((awgChanNumsX - 1), 2) + 1;
        awgChanNumsX(2,:) = awgChanNumsX + 2;
        awgChanNumsX = [reshape(awgChanNumsX, 1 ,numel(awgChanNumsX))];
        awgChannelsX = cell(1,length(awgChanNumsX));
        for i=1:length(awgChanNumsX)
            awgChannelsX{i} = num2str(awgChanNumsX(i));
        end
        awgChannelsX{end+1} = awgTrig;
        scopeChannelsX = repmat(scopeChannels(ch), 2, 1);
        scopeChannelsX = reshape(scopeChannelsX, 1, numel(scopeChannelsX));
        scopeChannelsX{end+1} = scopeTrig;
        analysisAvgX = 1;
        
        if strcmp(arbConfig.model, 'M8199B')
            result = iqmtcal('arbConfig', arbConfigX, 'scope', scopeType, 'sim', sim, 'scopeAvg', scopeAvg, ...
                'numTones', numTones, 'scopeRST', scopeRST, 'AWGRST', awgRST, ...
                'sampleRate', fsAWG / 2, 'recalibrate', 0, ...
                'autoScopeAmpl', autoScopeAmpl, 'memory', memSize, ...
                'awgChannels', awgChannelsX, 'scopeChannels', scopeChannelsX, ...
                'maxFreq', fcMax, 'analysisAvg', analysisAvgX, 'toneDev', toneDevType, ...
                'amplitude', scopeAmpl, 'axes', axesHandles, ...
                'scopeBW', scopeBW, 'scopeSIRC', scopeSIRC, 'separateTones', 1, ...
                'skewIncluded', 1, 'removeSinc', 0, 'restoreScope', 0);
        else        
            result = iqmtcal('arbConfig', arbConfigX, 'scope', scopeType, 'sim', sim, 'scopeAvg', scopeAvg, ...
                'numTones', numTones, 'scopeRST', scopeRST, 'AWGRST', awgRST, ...
                'sampleRate', fsAWG / 2, 'recalibrate', 0, ...
                'autoScopeAmpl', autoScopeAmpl, 'memory', memSize, ...
                'awgChannels', awgChannelsX, 'scopeChannels', scopeChannelsX, ...
                'maxFreq', min(fcMax, fsAWG / 4), 'analysisAvg', analysisAvgX, 'toneDev', toneDevType, ...
                'amplitude', scopeAmpl, 'axes', axesHandles, ...
                'scopeBW', scopeBW, 'scopeSIRC', scopeSIRC, 'separateTones', 1, ...
                'skewIncluded', 1, 'removeSinc', 0, 'restoreScope', 0);
        end
        if (isempty(result))
            return;
        end
        %dp = result.AbsPhaseResponse_MT(:,2*ch) - result.AbsPhaseResponse_MT(:,2*ch-1);
        dp = result.AbsPhaseResponse_MT(:,1) - result.AbsPhaseResponse_MT(:,2);
        ds = dp / 360 ./ result.Frequency_MT;     % phase is in degrees
        axes(ax);
        plot(result.Frequency_MT, ds * 1e3, '.-'); grid on; xlabel('Frequency (GHz)'); ylabel('Skew (ps)');
        % consider freq > 10 GHz only
        idx = find(result.Frequency_MT >= 10);
        pf = polyfit(result.Frequency_MT(idx), ds(idx), 1); % fit a straight line
        skew1(ch) = pf(2) / 1e9 - 1 / fsAWG;       % frequencies are in GHz; shift 1/2 sample clock for interleave
        rmsVal = rms(ds - mean(ds))*1e3;
        if (rmsVal > 20)
            errordlg(sprintf('Interleave skew measurement result for channel %d failed (rms = %.1f ps). Please verify correct channel assignment.', ch, rmsVal));
            return;
        end
        %fprintf('initial skew ch%d: %.1f ps (rms = %.1f ps)\n', ch, skew1(ch)*1e12, rmsVal);
        legend(sprintf('initial skew ch%d: %.1f ps (rms = %.1f ps)\n', ch, skew1(ch)*1e12, rmsVal));
        
%         % Get correct module ID and sub-channel ids 
%         ILVchannel = awgChanNums(ch);
%         moduleID = 1 + ceil(ILVchannel/2); % assuming M8008A is M1
        freqGrid = (0.1:0.1:100);
        id = buildID(arbConfig, awgChanNums(ch));
        % For M8199B, save sub-channel responses in user-cal table
        if strcmp(arbConfig.model, 'M8199B')
            %tbi: automatic buildID for subchannels
            for subCh = 1:2
                mag = abs(result.AmplitudeResponse_MT(:,subCh)) + 20*log10(sinc(result.Frequency_MT*1e9/128e9));
                phase = result.AbsPhaseResponse_MT(:,subCh);
                
                mag_lin = 10.^(-mag/20) ;
                mag_interp = interp1(result.Frequency_MT, mag_lin, freqGrid)';
                phase_interp = interp1(result.Frequency_MT, phase, freqGrid)';
                
                mag_interp = mag_interp(~isnan(mag_interp));
                phase_interp = phase_interp(~isnan(mag_interp));
                freqGrid_final = freqGrid(~isnan(mag_interp))';
                
                listStr = sprintf('%g,%g,%g,', [freqGrid_final, mag_interp, phase_interp]');
                listStr = listStr(1:end-1);
                
                if subCh == 1
                    strApp = 'sub1';
                else
                    strApp = 'sub2';
                end
               
                fAWG = iqopen();
                xfprintf(fAWG, sprintf(':CAL:TABL:DATA "%s","User.frequencyResponse_nonILV_%s","%s"', id, strApp, listStr));
            end
        end
    end
    axes(ax);
    hold off;
    % adjust skew
    hMsgBox.update(0.3, 'Adjusting skew...');
    % adjust delay
    fAWG = iqopen();
    if (isempty(fAWG))
        return;
    end
    for k = 1:length(skew1)
        if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), skew0(k)+skew1(k))))
            return;
        end
    end

    %%
    % fine alignment via tones
    % don't try this for the M8296A - it does not support any :MEAS:... commands
    %
    if (isempty(strfind(raw_idn, 'M8296A')))
        chMap = [zeros(size(arbConfig.channelMask,2), 2)];
        chMap(awgChanNums, 1) = 1;
        tones = (round(fsAWG/4/1e9+4)*1e9):1e9:100e9;
        [sig, ~, ~, ~, chMap] = iqtone('arbConfig', arbConfig, 'sampleRate', fsAWG, 'tone', tones, 'channelMapping', chMap, 'numSamples', sigLen, 'nowarning', 1);
        iqdownload(sig, fsAWG, 'channelMapping', chMap, 'arbConfig', arbConfig);

        if isequal(scopeFct, @iqreadscope)
            fscope = iqopen(arbConfig.visaAddrScope);
            chName = initScopeChannels(fscope, scopeChannels);
            xfprintf(fscope, ':TIM:SCAL 10e-9');
            xfprintf(fscope, ':ACQ:POINTS:AUTO 1');
            xfprintf(fscope, sprintf(':ACQ:BAND %g', round(fsAWG/4/1e9-2)*1e9));
            xfprintf(fscope, ':RUN');
            xfprintf(fscope, ':MEAS:CLEAR');
            for k = 1:length(scopeChannels)
                xfprintf(fscope, sprintf(':%s:DISP ON', chName{k}));
            end
        else
            fscope = iqopen(arbConfig.visaAddrDCA);
            xfprintf(fscope, sprintf(':TIM:UIRange %d', sigLen));
            [chName, scopeChannels, fchan] = initDCAChannels(scopeChannels, fscope);
            for k = 1:length(scopeChannels)
                xfprintf(fscope, sprintf(':%s:DISP ON', scopeChannels{k}));
                xfprintf(fscope, sprintf(':%s:SIRC ON;:%s:SIRC:RESPonse SINC;:%s:SIRC:FBANdwidth %g', ...
                    fchan{k}, fchan{k}, fchan{k}, round(fsAWG/4/1e9-2)*1e9));
            end
        end
        fAWG = iqopen(arbConfig);
        if (~isempty(axesHandles))
            axes(axesHandles(2));
            cla reset;
            hold off;
        else
            figure(2);
            clf;
        end
        ax = gca();

        % define the search range in ps
        if strcmp(arbConfig.model, 'M8199B')
            valList1 = (-2:0.5:2)'; % coarse list, search in 2 ps steps
            valList2 = (-0.5:0.05:0.5)'; % fine list: search around the minimum in 200 fs steps
            valList = repmat([valList1; valList2], 1, numChan);
        else
            valList1 = (-10:2:10)'; % coarse list, search in 2 ps steps
            valList2 = (-2:0.2:2)'; % fine list: search around the minimum in 200 fs steps
            valList = repmat([valList1; valList2], 1, numChan);
        end
        res = NaN(size(valList));
        % V(rms) measurement is only allowed when signal type is turned off
        if isequal(scopeFct, @iqreadscope)
            for k = 1:numChan
                xfprintf(fscope, sprintf(':ANALyze:SIGN:TYPE %s,UNSPecified', chName{k}), 1);
            end
        end
        for i = 1:size(valList,1)
            hMsgBox.update(0.6 + 0.1 * i/size(valList,1), 'Scanning Fine Delay...'); if hMsgBox.canceling(); break; end
            for k = 1:numChan
                val = valList(i,k);
                if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), skew0(k)+skew1(k)+val/2/1e12)))
                    return;
                end
            end
            xquery(fAWG, '*OPC?');  % make sure the skew changes have taken effect
            if ~isequal(scopeFct, @iqreadscope)
                xquery(fscope, ':ACQuire:CDISplay;:ACQuire:SINGle;*OPC?');
            end
            for k = 1:numChan
                if isequal(scopeFct, @iqreadscope)
                    if (xfprintf(fscope, ':SINGLE'))
                        return;
                    end
                    xquery(fscope, '*OPC?');
                    %xquery(fscope, ':PDER?');  % one "dummy" PDER query
                    rpt = 1;
                    while (rpt < 20 && sscanf(xquery(fscope, ':PDER?'), '%d') ~= 1)
                        rpt = rpt + 1;
                        pause(0.2);
                    end
                    x = str2double(xquery(fscope, sprintf(':MEAS:VRMS? DISPLAY,AC,%s', chName{k})));
                else
                    if (xfprintf(fscope, sprintf(':MEAS:OSC:VRMS:SOUR %s; AREA DISP; TYPE AC', scopeChannels{k})))
                        break;
                    end
                    xquery(fscope, sprintf(':MEAS:OSC:VRMS:SOUR %s;*OPC?', scopeChannels{k}));
                    x = str2double(xquery(fscope, sprintf(':MEASure:OSC:VRMS?')));
                end
                if (x > 1e37)
                    xquery(fscope, ':SYST:ERR?');
                    errordlg('scope measurement failed');
                    return;
                end
                res(i,k) = x;
                axes(ax);
                plot(valList/2, 1000*res, '.');
                xlim([min(min(valList/2)) max(max(valList/2))]);
                grid on;
                xlabel('Skew (ps)');
                ylabel('Distortion (mV RMS)');
                drawnow();
                % at the end of the "coarse" list, find the minimum point and
                % modify the rest of the list, so that the area around the
                % minimum will be analyzed in greater detail
                if (i == length(valList1))
                    [minVal, p] = min(res(:,k));
                    if (~isnan(minVal))
                        val = valList(p,k);
                        valList(i+1:end,k) = valList(i+1:end,k) + val;
                    else
                        error('invalid measurement');
                    end
                end
            end
        end
        for k = 1:numChan
            [minVal, p] = min(res(:,k));
            if (~isnan(minVal))
                val = valList(p,k);
                skew = skew0(k)+skew1(k)+val/2/1e12;
    %            fprintf('final skew ch%d: %.1f ps (delta = %.1f ps)\n', k, 1e12*skew, val/2);
                if (swVersion >= 1002075 || strcmp(arbConfig.model, 'M8199B'))
                    % starting with SW version 1.2.75, we have a user cal table
                    calTableName = 'User.ILVSkew';
                    oldSkewStr = xquery(fAWG, sprintf(':CAL:TABL:DATA? "%s","%s","%.12g"', buildID(arbConfig, awgChanNums(k)), calTableName, fsAWG));
                    oldSkew = sscanf(strrep(strrep(oldSkewStr, ',', ' '), '"', ''), '%g');
                    % pos1 = frequency, pos2 = skew
                    newSkew = oldSkew;
                    newSkew(2) = newSkew(2) - skew;
                    newSkewStr = sprintf('%g,', newSkew(:));
                    newSkewStr = newSkewStr(1:end-1);
                    xfprintf(fAWG, sprintf(':CAL:TABL:DATA "%s","%s","%s"', buildID(arbConfig, awgChanNums(k)), calTableName, newSkewStr));
                    % set the property back to zero
                    xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), 0));
                    fprintf('ILVskew %s, old %g, meas %g, new %g\n', buildID(arbConfig, awgChanNums(k)), oldSkew(2), skew, newSkew(2));
                else
                    % in older versions, simply write the parameter
                    if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), skew)))
                        return;
                    end
                end
            end
        end
        rmsData.skew = valList;
        rmsData.rms = res;
    end  % not M8296A
end  % skew mode

%%
% scan amplitude to find optimum - assumes that skew has already been adjusted
% don't attempt this for the M8296A, it does not have support :MEAS:... commands
%
if (~isempty(strfind(mode, 'amplitude')) && isempty(strfind(raw_idn, 'M8296A')))
    if (~isempty(axesHandles))
        axes(axesHandles(1));
        cla reset;
        hold off;
    else
        figure(3);
        clf;
    end
    ax = gca();

    valList1 = (-.5:0.1:.5)';
    valList = repmat(valList1, 1, numChan);
    res = NaN(size(valList));
    for i = 1:size(valList,1)
        hMsgBox.update(0.7 + 0.1 * i/size(valList,1), 'Scanning Amplitude...'); if hMsgBox.canceling(); break; end
        for k = 1:numChan
            val = valList(i,k);
            ampl = 10^(val/10);
            if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:AMPL "%s",%g', buildID(arbConfig, awgChanNums(k)), ampl)))
                return;
            end
        end
        xquery(fAWG, '*OPC?');  % make sure the skew changes have taken effect
        if ~isequal(scopeFct, @iqreadscope)
            xquery(fscope, ':ACQuire:CDISplay;:ACQuire:SINGle;*OPC?');
        end
        for k = 1:numChan
            if isequal(scopeFct, @iqreadscope)
                xfprintf(fscope, ':SINGLE');
                xquery(fscope, '*OPC?');
                %xquery(fscope, ':PDER?');  % one "dummy" PDER query
                rpt = 1;
                while (rpt < 20 && sscanf(xquery(fscope, ':PDER?'), '%d') ~= 1)
                    rpt = rpt + 1;
                    pause(0.1);
                end
                x = str2double(xquery(fscope, sprintf(':MEAS:VRMS? DISPLAY,AC,%s', chName{k})));
            else
                if (xfprintf(fscope, sprintf(':MEAS:OSC:VRMS:SOUR %s; AREA DISP; TYPE AC', scopeChannels{k})))
                    break;
                end
                xquery(fscope, sprintf(':MEAS:OSC:VRMS:SOUR %s;*OPC?', scopeChannels{k}));
                x = str2double(xquery(fscope, sprintf(':MEASure:OSC:VRMS?')));
            end
            if (x > 1e37)
                xquery(fscope, ':SYST:ERR?');
                errordlg('scope measurement failed');
                return;
            end
            res(i,k) = x;
            axes(ax);
            plot(valList, 1000*res, '.');
            xlim([min(min(valList)) max(max(valList))]);
            grid on;
            xlabel('Amplitude mismatch (dB)');
            ylabel('Distortion (mV RMS)');
            drawnow();
        end
    end
    
    % find the minimum (= optimal) value for each channel
    for k = 1:numChan
        [minVal, p] = min(res(:,k));
        if (~isnan(minVal))
            val = valList(p,k);
            ampl = 10^(val/10);
            if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:AMPL "%s",%g', buildID(arbConfig, awgChanNums(k)), ampl)))
                return;
            end
        end
    end
    rmsData.amplitude = valList;
    rmsData.rmsAmpl = res;

    %%
    % reset the scope to full bandwidth
    %
    if isequal(scopeFct, @iqreadscope)
        xfprintf(fscope, sprintf(':ACQ:BAND AUTO'));
        xfprintf(fscope, sprintf(':%s:SCALE 100e-3', chName{1}));
    else
        for k = 1:length(scopeChannels)
            xfprintf(fscope, sprintf(':%s:SIRC ON;:%s:SIRC:RESP FLAT;:%s:SIRC:FBANdwidth %g', ...
                fchan{k}, fchan{k}, fchan{k}, 110e9), 1);
        end
    end
end % amplitude cal

iqclose(fscope);
iqclose(fAWG);
hMsgBox.update(1, 'Done');
retVal = 1;



function [retVal, rmsData] = skewCal_ILV_squarewave(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, scopeAvg, scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, overwrite, mode, scopeDeskew)
retVal = 0;
rmsData = struct();
rmsData.version = 2;
numChan = length(awgChanNums);
hMsgBox.update(0.05, 'Checking connections...'); if hMsgBox.canceling(); return; end
fAWG = iqopen();
if (isempty(fAWG))
    return;
end
if isequal(scopeFct, @iqreadscope)
    fscope = iqopen(arbConfig.visaAddrScope);
else
    fscope = iqopen(arbConfig.visaAddrDCA);
end
if (isempty(fscope))
    return;
end
if (scopeRST)
    xfprintf(fscope, '*RST');
end
xfprintf(fscope, '*CLS');

if (~isempty(strfind(mode, 'skew')))
    skew0 = zeros(numChan, 1);
    for k = 1:numChan
        skew0(k) = str2double(xquery(fAWG, sprintf(':OUTP:CAL:ILV:SKEW? "%s"', buildID(arbConfig, awgChanNums(k)))));
    end
    % if ~isempty(find(skew0,1))
    %     if (isempty(overwrite))
    %         res = questdlg('Some skew values are already set. Do you want to reset them or use the previous values as a starting point?', ...
    %             'Please select...', 'Reset', 'Use previous', 'Cancel', 'Reset');
    %     else
    %         if (overwrite)
    %             res = 'Reset';
    %         else
    %             res = 'Use previous';
    %         end
    %     end
    %     if (strcmp(res, 'Reset'))
            for k = 1:length(awgChanNums)
                xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), 0));
                if (~isempty(strfind(mode, 'amplitude')))
                    xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:AMPL "%s",%g', buildID(arbConfig, awgChanNums(k)), 1));
                end
            end
            skew0 = zeros(numChan, 1);
    %     end
    %     if (strcmp(res, 'Cancel'))
    %         return;
    %     end
    % end

    % determine the trigger frequency
    if (isequal(scopeFct, @iqreaddca))
        if (isfield(arbConfig, 'sampleMarker') && strncmpi(arbConfig.sampleMarker, 'Sample rate / ', 14))
            trigFreq = fsAWG / str2double(arbConfig.sampleMarker(15:end));
        else
            res = inputdlg('Please enter PTB frequency *or* cancel and set default sample marker frequency in instrument configuration window', 'Enter PRB frequency', 1, {'16e9'});
            if (isempty(res))
                return;
            end
            trigFreq = str2double(res{1});
        end
    else
        % don't need trigger for real-time scope
        trigFreq = 0;
    end
    
    % run auto deskew if:
    % - requested by caller
    % - running on a DCA
    % - at least one channel is a DIFF or FUNC
    doDeskew = 0;
    if scopeDeskew && isequal(scopeFct, @iqreaddca)
        for i = 1:numChan
            if (~isempty(strfind(scopeChannels{i}, 'DIFF')) || ...
                ~isempty(strfind(scopeChannels{i}, 'FUNC')))
               doDeskew = 1;
            end
        end
    end
    if (doDeskew)
        hMsgBox.update(0.05, 'Differential deskew in the DCA'); if hMsgBox.canceling(); return; end
        % use a multi-tone signal for deskew - zero out all other channels
        testSig = iqtone('arbConfig', arbConfig, 'tone', linspace(1e9, 16e9, 10), 'nowarning', 1, 'numSamples', sigLen);
        testSig = [zeros(size(testSig)) testSig];
        % initialize all channels of the AWG
        chMap = [arbConfig.channelMask' zeros(size(arbConfig.channelMask,2), 3)];
        % zero out those that are not being calibrated
        chMap(awgChanNums, 1) = 0;
        % load test wfm into those being calibrated
        chMap(awgChanNums, 3) = 1;
        iqdownload(testSig, fsAWG, 'channelMapping', chMap, 'arbConfig', arbConfig);
        dataRate = fsAWG;
        spb = 8;
        scopeAvg = 1;
        duration = sigLen / fsAWG;
        % call iqreaddca, but don't actually capture the waveform
        [~, ~] = scopeFct(arbConfig, scopeChannels, [], duration, scopeAvg, scopeAmpl, trigFreq, dataRate, spb, scopeBW, scopeSIRC, 2);
        % no need for another deskew on the following uploads
        scopeDeskew = 0;
    end
    
    hMsgBox.update(0.1, 'Downloading test signal to AWG'); if hMsgBox.canceling(); return; end
    generateTestSignal(arbConfig, fsAWG, awgChanNums, sigLen);

    hMsgBox.update(0.2, 'Uploading waveform from scope...'); if hMsgBox.canceling(); return; end
    skew1 = analyzeWfm(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, scopeAvg, scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, overwrite, mode, scopeDeskew, trigFreq);
    % if any of the skew values is NaN, an error has occurred during acquisition
    if ~isempty(find(isnan(skew1), 1))
        return;
    end
    setLegend(awgChanNums, skew1);
    % adjuster for risetime
    skewAdjust = -1e-12;
    skew1 = abs(abs(skew1) - skewAdjust);
    % check if adjustment is needed
    skewAdjIdx = find(skew1 > 2/fsAWG);
    if (~isempty(skewAdjIdx))
        hMsgBox.update(0.3, 'Adjusting skew...');
        % adjust delay
        fAWG = iqopen();
        if (isempty(fAWG))
            return;
        end
        for k = skewAdjIdx'
            if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), skew0(k)+skew1(k))))
                return;
            end
        end
        hMsgBox.update(0.4, 'Verifying...'); if hMsgBox.canceling(); return; end
        skew2 = analyzeWfm(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, scopeAvg, scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, overwrite, mode, scopeDeskew, trigFreq);
        % if any of the skew values is NaN, an error has occurred during acquisition
        if ~isempty(find(isnan(skew2), 1))
            return;
        end
        setLegend(awgChanNums, skew2);
        % if the skew got worse, we need to shift the other channel
        skewAdjIdx = find(skew2 > skew1 + 1e-12);
        if (~isempty(skewAdjIdx))
            % adjust delay
            hMsgBox.update(0.5, 'Shifting in the other direction...'); if hMsgBox.canceling(); return; end
            fAWG = iqopen();
            if (isempty(fAWG))
                return;
            end
            skew1(skewAdjIdx) = -skew1(skewAdjIdx);
            for k = skewAdjIdx'
                if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), skew0(k)+skew1(k))))
                    return;
                end
            end
            hMsgBox.update(0.6, 'Verifying...'); if hMsgBox.canceling(); return; end
            skew3 = analyzeWfm(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, scopeAvg, scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, overwrite, mode, scopeDeskew, trigFreq);
            if ~isempty(find(isnan(skew1), 1))
                return;
            end
            setLegend(awgChanNums, skew3);
        end
    end

    % fine alignment via tones
    chMap = [zeros(size(arbConfig.channelMask,2), 2)];
    chMap(awgChanNums, 1) = 1;
    tones = (round(fsAWG/4/1e9+4)*1e9):1e9:100e9;
    [sig, ~, ~, ~, chMap] = iqtone('arbConfig', arbConfig, 'sampleRate', fsAWG, 'tone', tones, 'channelMapping', chMap, 'numSamples', sigLen, 'nowarning', 1);
    iqdownload(sig, fsAWG, 'channelMapping', chMap, 'arbConfig', arbConfig);

    if isequal(scopeFct, @iqreadscope)
        fscope = iqopen(arbConfig.visaAddrScope);
        chName = initScopeChannels(fscope, scopeChannels);
        xfprintf(fscope, ':TIM:SCAL 10e-9');
        xfprintf(fscope, ':ACQ:POINTS:AUTO 1');
        xfprintf(fscope, sprintf(':ACQ:BAND %g', round(fsAWG/4/1e9-2)*1e9));
        xfprintf(fscope, ':RUN');
        xfprintf(fscope, ':MEAS:CLEAR');
    else
        fscope = iqopen(arbConfig.visaAddrDCA);
        xfprintf(fscope, sprintf(':TIM:UIRange %d', sigLen));
        [chName, scopeChannels, fchan] = initDCAChannels(scopeChannels, fscope);
        for k = 1:length(scopeChannels)
            xfprintf(fscope, sprintf(':%s:SIRC ON;:%s:SIRC:RESPonse SINC;:%s:SIRC:FBANdwidth %g', ...
                fchan{k}, fchan{k}, fchan{k}, round(fsAWG/4/1e9-2)*1e9));
        end
    end
    fAWG = iqopen(arbConfig);
    if (~isempty(axesHandles))
        axes(axesHandles(2));
        cla reset;
        hold off;
    else
        figure(2);
        clf;
    end
    ax = gca();

    % define the search range in ps
    valList1 = (-24:2:24)'; % coarse list, search in 2 ps steps
    valList2 = (-2:0.2:2)'; % fine list: search around the minimum in 200 fs steps
    valList = repmat([valList1; valList2], 1, numChan);
    res = NaN(size(valList));
    % V(rms) measurement is only allowed when signal type is turned off
    if isequal(scopeFct, @iqreadscope)
        for k = 1:numChan
            xfprintf(fscope, sprintf(':ANALyze:SIGN:TYPE %s,UNSPecified', chName{k}), 1);
        end
    end
    for i = 1:size(valList,1)
        hMsgBox.update(0.6 + 0.1 * i/size(valList,1), 'Scanning Fine Delay...'); if hMsgBox.canceling(); break; end
        for k = 1:numChan
            val = valList(i,k);
            if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), skew0(k)+skew1(k)+val/2/1e12)))
                return;
            end
        end
        xquery(fAWG, '*OPC?');  % make sure the skew changes have taken effect
        if ~isequal(scopeFct, @iqreadscope)
            xquery(fscope, ':ACQuire:CDISplay;:ACQuire:SINGle;*OPC?');
        end
        for k = 1:numChan
            if isequal(scopeFct, @iqreadscope)
                if (xfprintf(fscope, ':SINGLE'))
                    return;
                end
                xquery(fscope, '*OPC?');
                %xquery(fscope, ':PDER?');  % one "dummy" PDER query
                rpt = 1;
                while (rpt < 20 && sscanf(xquery(fscope, ':PDER?'), '%d') ~= 1)
                    rpt = rpt + 1;
                    pause(0.1);
                end
                x = str2double(xquery(fscope, sprintf(':MEAS:VRMS? DISPLAY,AC,%s', chName{k})));
            else
                if (xfprintf(fscope, sprintf(':MEAS:OSC:VRMS:SOUR %s; AREA DISP; TYPE AC', scopeChannels{k})))
                    break;
                end
                xquery(fscope, sprintf(':MEAS:OSC:VRMS:SOUR %s;*OPC?', scopeChannels{k}));
                x = str2double(xquery(fscope, sprintf(':MEASure:OSC:VRMS?')));
            end
            if (x > 1e37)
                xquery(fscope, ':SYST:ERR?');
                errordlg('scope measurement failed');
                return;
            end
            res(i,k) = x;
            axes(ax);
            plot(valList, 1000*res, '.');
            xlim([min(min(valList)) max(max(valList))]);
            grid on;
            xlabel('Skew (ps)');
            ylabel('Distortion (mV RMS)');
            drawnow();
            % at the end of the "coarse" list, find the minimum point and
            % modify the rest of the list, so that the area around the
            % minimum will be analyzed in greater detail
            if (i == length(valList1))
                [minVal, p] = min(res(:,k));
                if (~isnan(minVal))
                    val = valList(p,k);
                    valList(i+1:end,k) = valList(i+1:end,k) + val;
                else
                    error('invalid measurement');
                end
            end
        end
    end
    for k = 1:numChan
        [minVal, p] = min(res(:,k));
        if (~isnan(minVal))
            val = valList(p,k);
            xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:SKEW "%s",%g', buildID(arbConfig, awgChanNums(k)), skew0(k)+skew1(k)+val/2/1e12));
        end
    end
    rmsData.skew = valList;
    rmsData.rms = res;
end

% scan amplitude to find optimum - assumes that skew has already been adjusted
if (~isempty(strfind(mode, 'amplitude')))
    if (~isempty(axesHandles))
        axes(axesHandles(1));
        cla reset;
        hold off;
    else
        figure(3);
        clf;
    end
    ax = gca();

    valList1 = (-1:0.1:1)';
    valList = repmat(valList1, 1, numChan);
    res = NaN(size(valList));
    for i = 1:size(valList,1)
        hMsgBox.update(0.7 + 0.1 * i/size(valList,1), 'Scanning Amplitude...'); if hMsgBox.canceling(); break; end
        for k = 1:numChan
            val = valList(i,k);
            amp = 10^(val/10);
            if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:AMPL "%s",%g', buildID(arbConfig, awgChanNums(k)), amp)))
                return;
            end
        end
        xquery(fAWG, '*OPC?');  % make sure the skew changes have taken effect
        if ~isequal(scopeFct, @iqreadscope)
            xquery(fscope, ':ACQuire:CDISplay;:ACQuire:SINGle;*OPC?');
        end
        for k = 1:numChan
            if isequal(scopeFct, @iqreadscope)
                xfprintf(fscope, ':SINGLE');
                xquery(fscope, '*OPC?');
                %xquery(fscope, ':PDER?');  % one "dummy" PDER query
                rpt = 1;
                while (rpt < 20 && sscanf(xquery(fscope, ':PDER?'), '%d') ~= 1)
                    rpt = rpt + 1;
                    pause(0.1);
                end
                x = str2double(xquery(fscope, sprintf(':MEAS:VRMS? DISPLAY,AC,%s', chName{k})));
            else
                if (xfprintf(fscope, sprintf(':MEAS:OSC:VRMS:SOUR %s; AREA DISP; TYPE AC', scopeChannels{k})))
                    break;
                end
                xquery(fscope, sprintf(':MEAS:OSC:VRMS:SOUR %s;*OPC?', scopeChannels{k}));
                x = str2double(xquery(fscope, sprintf(':MEASure:OSC:VRMS?')));
            end
            if (x > 1e37)
                xquery(fscope, ':SYST:ERR?');
                errordlg('scope measurement failed');
                return;
            end
            res(i,k) = x;
            axes(ax);
            plot(valList, 1000*res, '.');
            xlim([min(min(valList)) max(max(valList))]);
            grid on;
            xlabel('Amplitude mismatch (dB)');
            ylabel('Distortion (mV RMS)');
            drawnow();
        end
    end
    for k = 1:numChan
        [minVal, p] = min(res(:,k));
        if (~isnan(minVal))
            val = valList(p,k);
            amp = 10^(val/10);
            if (xfprintf(fAWG, sprintf(':OUTP:CAL:ILV:AMPL "%s",%g', buildID(arbConfig, awgChanNums(k)), amp)))
                return;
            end
        end
    end
    rmsData.amplitude = valList;
    rmsData.rmsAmpl = res;
end

% reset the scope to full bandwidth
if isequal(scopeFct, @iqreadscope)
    xfprintf(fscope, sprintf(':ACQ:BAND AUTO'));
    xfprintf(fscope, sprintf(':%s:SCALE 100e-3', chName{1}));
else
    for k = 1:length(scopeChannels)
        xfprintf(fscope, sprintf(':%s:SIRC ON;:%s:SIRC:RESP FLAT;:%s:SIRC:FBANdwidth %g', ...
            fchan{k}, fchan{k}, fchan{k}, 110e9), 1);
    end
end
iqclose(fscope);
iqclose(fAWG);
hMsgBox.update(1, 'Done');
retVal = 1;


function setLegend(awgChanNums, skew)
if (length(skew) ~= length(awgChanNums))
    return;
end
leg = cell(length(awgChanNums),1);
for k = 1:length(awgChanNums)
    leg{k} = sprintf('chan %d: %.1f ps\n', awgChanNums(k), skew(k)*1e12);
end
legend(leg);


function retVal = skewCal_NonILV(hMsgBox, arbConfig, scopeRST, scopeAmpl, autoScopeAmpl, scopeTrig, scopeAvg, scopeChannels, awgChanNums, scopeFct, fsAWG, sigLen, scopeSIRC, scopeBW, axesHandles, overwrite, mode, scopeDeskew)
retVal = 0;
% for DCA, skew cal is not yet implemented
if isequal(scopeFct, @iqreaddca)
    retVal = 1;
    return;
end
numChan = length(awgChanNums);
hMsgBox.update(0.1, 'Downloading test signal to AWG'); if hMsgBox.canceling(); return; end
generateTestSignal(arbConfig, fsAWG, awgChanNums, sigLen);
fAWG = iqopen();
if (isempty(fAWG))
    return;
end
% open connection to the scope
fscope = iqopen(arbConfig.visaAddrScope);
if (isempty(fscope))
    return;
end
% reset the channel delays
for k = 1:length(awgChanNums)
    if (xfprintf(fAWG, sprintf(':ARM:DEL "%s",%g', buildID(arbConfig, awgChanNums(k)), 0)))
        return;
    end
end
hMsgBox.update(0.2, 'Configuring scope...'); if hMsgBox.canceling(); return; end
if (scopeRST)
    xfprintf(fscope, '*RST');
end
xfprintf(fscope, '*CLS');
for i = [4 3 2 1]
    xfprintf(fscope, sprintf(':chan%d:disp off', i));
end
chName = initScopeChannels(fscope, scopeChannels);
timescale = 5e-9;
xfprintf(fscope, sprintf(':TIM:REF CENTER'));
xfprintf(fscope, sprintf(':TIM:SCAL %g', timescale));
xfprintf(fscope, sprintf(':TIM:DEL 0'));
trigLev = 0;
xfprintf(fscope, sprintf(':TRIG:LEV %s,%g', chName{1}, trigLev));
xfprintf(fscope, sprintf(':TRIG:EDGE:SOUR %s', chName{1}));
xfprintf(fscope, sprintf(':MEAS:CLEAR'));
% turn averaging off for autoscale
xfprintf(fscope, sprintf(':ACQ:AVER OFF'));
xfprintf(fscope, ':RUN');
res = xquery(fscope, 'ADER?');
if (eval(res) ~= 1)
    % try one more time
    res = xquery(fscope, 'ADER?');
    if (eval(res) ~= 1)
        res = questdlg('Please verify that the scope captures the waveform correctly and press OK','Scope','OK','Cancel','OK');
        if (~strcmp(res, 'OK'))
            iqclose(fscope);
            return;
        end
    end
end
% set amplitude of channels - do this after timebase & trigger setup so
% that autoscale works
scopeAmpl = fixlength(scopeAmpl, numChan);
for i = 1:numChan
    if (autoScopeAmpl)
        xfprintf(fscope, sprintf(':AUTOSCALE:VERT %s', chName{i}));
    elseif scopeAmpl(i) > 0
        xfprintf(fscope, sprintf(':%s:SCAL %g', chName{i}, scopeAmpl(i)/8));
    end
end
% turn on averaging
xfprintf(fscope, sprintf(':ACQ:AVER:COUNT 16'));
xfprintf(fscope, sprintf(':ACQ:AVER ON'));
hMsgBox.update(0.3, 'Coarse skew measurement...'); if hMsgBox.canceling(); return; end
xfprintf(fscope, ':meas:deltatime:def rising,1,middle,rising,1,middle');
xfprintf(fscope, sprintf(':meas:clear'));
if (autoScopeAmpl)
    for i = 1:numChan
        scopeAmpl(i) = str2double(xquery(fscope, sprintf(':%s:SCAL?', chName{i}))) * 8;
    end
end
for i = 1:numChan
    xfprintf(fscope, sprintf(':meas:thresholds:absolute %s,%g,%g,%g', chName{i}, trigLev+scopeAmpl(i)/5, trigLev, trigLev-scopeAmpl(i)/5));
    xfprintf(fscope, sprintf(':meas:thresholds:method %s,absolute', chName{i}));
    if (i > 1)
        xfprintf(fscope, sprintf(':meas:deltatime %s,%s', chName{i}, chName{1}));
    end
end
xfprintf(fscope, sprintf(':meas:stat on'));
result = doScopeMeasurement(fscope, chName, timescale, 1, 1);

maxDiff = max(result) - min(result);
if (maxDiff > 2e-9)
    errordlg('Channel skew is too large to compensate by hardware delay.');
    return;
end
% shift delay such that abs(max(delay)) = abs(min(delay))
result = result - min(result) - maxDiff / 2;
% adjust delays
fAWG = iqopen();
if (isempty(fAWG))
    return;
end
for k = 1:length(awgChanNums)
    if (xfprintf(fAWG, sprintf(':ARM:DEL "%s",%g', buildID(arbConfig, awgChanNums(k)), result(k))))
        return;
    end
end
hMsgBox.update(0.4, 'Fine skew measurement...'); if hMsgBox.canceling(); return; end
timescale = 4e-12;
result2 = doScopeMeasurement(fscope, chName, timescale, 3, 1);
% add to previous result and program it 
result = result - result2;
for k = 1:length(awgChanNums)
    if (xfprintf(fAWG, sprintf(':ARM:DEL "%s",%g', buildID(arbConfig, awgChanNums(k)), result(k))))
        return;
    end
end
result3 = doScopeMeasurement(fscope, chName, timescale, 3, 1);
if (max(abs(result3)) > 0.5e-12)
    warndlg(sprintf('skew not accurately adjusted. Max skew = %g ps', max(abs(result3))/1e-12));
    return;
end
iqclose(fAWG);
iqclose(fscope);
hMsgBox.update(1, 'Done');
retVal = 1;


function [chName, scopeChannels, fchan] = initDCAChannels(scopeChannels, fscope)
% NOTE: Same function as in iqreaddca.m
%
% input            scopeChan   chName     fchan
% -------------------------------------------------
% xy               CHANxy      CHANxy     CHANxy  (where xy = 1A, 2A,..., 1B, 2B, etc.)
% CHANxy           CHANxy      CHANxy     CHANxy
% DIFFxy           DIFFxy      CHANxy     CHANxy
% FUNCm            FUNCm       CHANpq     CHANpq  (where CHANpq is the channel from which FUNCm is derived)
%
numChan = length(scopeChannels);
chName = scopeChannels;
fchan = scopeChannels;
for i = 1:numChan
    if (length(scopeChannels{i}) <= 2)              % map 1A to CHAN1A
        scopeChannels{i} = ['CHAN' scopeChannels{i}];
        chName{i} = scopeChannels{i};
        fchan{i} = scopeChannels{i};
    end
    if (strncmpi(scopeChannels{i}, 'DIFF', 4))      % in some cases, we need CHAN1A instead DIFF1A
        chName{i} = ['CHAN' scopeChannels{i}(5:end)];
        fchan{i} = chName{i};
    end
    if (strncmpi(scopeChannels{i}, 'FUNC', 4))      % map FUNCx to CHANx --> done (BK)
        FunctionSource = strtrim(xquery(fscope, sprintf(':%s:OPERand?',scopeChannels{i})));
        while strncmpi(FunctionSource, 'FUNC', 4) 
            FunctionSource = strtrim(xquery(fscope, sprintf(':%s:OPERand?',FunctionSource)));
        end
        if (strncmpi(FunctionSource, 'DIFF', 4))
            chName{i} = ['CHAN' FunctionSource(5:end)];
            fchan{i} = chName{i};
        else
            chName{i} = FunctionSource ; 
            fchan{i} = chName{i};
        end
    end
end


function chName = initScopeChannels(fscope, scopeChannels)
numChan = length(scopeChannels);
chName = cell(numChan,1);
for i = 1:numChan
    prefix = 'CHAN';
    if (strncmpi(scopeChannels{i}, 'DIFF', 4))
        if (strcmpi(scopeChannels{i}, 'DIFF1-2') || strcmpi(scopeChannels{i}, 'DIFF3-4'))
            xfprintf(fscope, ':ACQ:DIFF:PART ADJ');
        else
            xfprintf(fscope, ':ACQ:DIFF:PART EOTH', 1); % don't check for errors - some scopes don't know this command
        end
        if (strncmpi(scopeChannels{i}, 'DIFFRE', 6))
            scopeChannels{i} = '1';      % differential real edge is only available on channel 1
            xfprintf(fscope, sprintf(':ACQuire:REDGE ON'), 1);
        else                    % differential signalling on a normal channel
            scopeChannels{i} = scopeChannels{i}(5);
        end
        xfprintf(fscope, sprintf(':CHAN%s:DIFF ON', scopeChannels{i}));
        % amplitude values seem to be specified per channel and NOT for the
        % differential channel
    elseif (strncmpi(scopeChannels{i}, 'REdge', 5))  % real edge, single ended
        scopeChannels{i} = scopeChannels{i}(6);
        xfprintf(fscope, sprintf(':ACQuire:REDGE ON'), 1);
        %ampl = maxAmpl(min(i,length(maxAmpl)));
    elseif (strncmpi(scopeChannels{i}, 'FUNC', 4))
        prefix = '';
    end
    chName{i} = [prefix scopeChannels{i}];
    xfprintf(fscope, sprintf(':%s%s:DISP ON', prefix, scopeChannels{i}));
end


function id = buildID(arbConfig, chanNum)
% construct the M8070 identifier for a given AWG channel number
id = '';
if (~isscalar(chanNum))
    error('chanNum must be scalar');
end
% number of channels per module
if (strcmp(arbConfig.model, 'M8199A_ILV') || strcmp(arbConfig.model, 'M8199B'))
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


function generateTestSignal(arbConfig, fsAWG, awgChanNums, sigLen)
% generate test signal for coarse alignment (slow square wave)
% column 1: all zeros, column 2: square wave
sig = [zeros(sigLen,1) [ones(sigLen/2,1); -1*ones(sigLen/2,1)]];
% initialize all channels of the AWG
chMap = [arbConfig.channelMask' zeros(size(arbConfig.channelMask,2), 3)];
% zero out those that are not being calibrated
chMap(awgChanNums, 1) = 0;
% load test wfm into those being calibrated
chMap(awgChanNums, 3) = 1;
iqdownload(sig, fsAWG, 'channelMapping', chMap, 'arbConfig', arbConfig);


function result = doScopeMeasurement(fscope, chName, timescale, measDelay, showError)
result = [];
if (~exist('measDelay', 'var'))
    measDelay = 1;
end
if (~exist('showError', 'var'))
    showError = 1;
end
if (exist('timescale', 'var'))
    xfprintf(fscope, sprintf(':tim:scal %g', timescale));
end
doMeasAgain = 1;
while (doMeasAgain)
    xfprintf(fscope, ':CDIS');
    pause(measDelay);
    measStr = xquery(fscope, ':meas:results?');
    measList = str2double(strsplit(measStr, ','));
    result = zeros(length(chName),1);
    doMeasAgain = 0;
    for i = 2:length(chName)
        idx = length(chName)+2-i;
        meas = measList(4 + (i-2)*7);   % mean
        result(idx) = meas;
        if (abs(meas) > 1e37 || abs(measList(1)) > 1e37)
            if (showError)
                errordlg(['Signal edges were not found on the scope. ' ...
                    'Please make sure that you have connected the AWG outputs ' ...
                    'to the scope according to the connection diagram. ' ...
                    '(Measurement result returned was: ' strtrim(sprintf('%g', meas)) ')']);
            end
            result(idx) = NaN;
            return;
        end
        if (abs(measList(3 + (i-2)*7) - measList(2 + (i-2)*7)) > 100e-12)   % max - min
            res = questdlg({'The scope returns delta time measurements with large variations.' ...
                           'Please verify that the slave clock source is set correctly and the' ...
                           'scope shows a steady waveform. Then press OK' },'Scope','OK','Cancel','OK');
            if (~strcmp(res, 'OK'))
                iqclose(fscope);
                return;
            end
            doMeasAgain = 1;
        end
    end
end


function swVersion = getSwVersion(f, arbConfig)
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
    error('Cannot decode module driver information');
end
if ~isfield(info, 'ProductNumber') || ~strcmp(info.ProductNumber, 'M8199A')
    error('Unexpected product number');
end
if isfield(info, 'SoftwareVersion')
    swVersionL = sscanf(info.SoftwareVersion, '%d.%d.%d.%d');
    swVersion = 1000000 * swVersionL(1) + 1000 * swVersionL(2) + swVersionL(3);
else
    swVersionL = [];
    swVersion = -1;
end
if (length(swVersionL) ~= 4)
    error('No software version or unexpected format');
end

    
function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
