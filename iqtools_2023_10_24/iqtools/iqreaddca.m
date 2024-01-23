function [yval, fs] = iqreaddca(arbConfig, chan, ~, duration, avg, maxAmpl, trigFreq, dataRate, spb, bandwidth, sirc, doDeskew)
% read a waveform from DCA
%
% arguments:
% arbConfig - if empty, use DCA address configured in IQTools config
% chan - list of scope channels to be captured
% trigChan - not used (will always be front panel)
% duration - length of capture (in seconds)
% avg - number of averages (1 = no averaging)
% maxAmpl - amplitude of the signal (will be used to set Y scale)
%           0 means do not set ampltiude
%           -1 means: use maximum amplitude supported by this instrument
%           -2 means: perform autoscale
% trigFreq - trigger frequency in Hz. Zero for once per waveform. Assumes
%            that the trigger signal is connected to the FP trigger input
%            Non-zero: trigger frequency for PTB. Assumes that Trigger signal 
%            is connected to FP+PTB inputs. Will use PatternLock.
% dataRate - (optional) specifies the data rate that will be used in
%            pattern lock mode. If not given, will use trigFreq as the data rate
% spb -      (optional) samples per bit. If trigFreq and dataRate are
%            specified, spb can be used define how many samples per bit the
%            DCA will use when capturing the waveform. If spb is not
%            specified, the routine will use 128 kSa for the entire
%            waveform (spb will depend on dataRate and duration in that case)
% bandwidth - if empty, will leave scope bandwidth as-is. If non-empty,
%            will set scope bandwidth to the given value. Note that
%            bandwidth must be a string.  This string is directly passed to the
%            :CHAN:BANDWIDTH command. I.e. ENUMs, such as "BAND1" or "HIGH" are
%            possible.  A value of "MAX" will try to set the bandwidth to
%            the maximum available value
% sirc -     if empty, will leave SIRC setting as-is.  If non-empty, will 
%            turn SIRC on (1) or off (0).
% doDeskew - perform auto deskew on differential channels before acquiring
%            the waveform. 0=don't deskew, acquire, 1=run deskew, acquire
%            2=run deskew, do not acquire
%
yval = [];
fs = 1;
if (~exist('arbConfig', 'var'))
    arbConfig = [];
end
arbConfig = loadArbConfig(arbConfig);
if ((isfield(arbConfig, 'isDCAConnected') && arbConfig.isDCAConnected == 0) || ~isfield(arbConfig, 'visaAddrDCA'))
    error('DCA address is not configured, please use "Instrument Configuration" to set it up');
end
hMsgBox = iqwaitbar('Checking connection to DCA...');
f = iqopen(arbConfig.visaAddrDCA);
if (isempty(f))
    return;
end
if (~exist('chan', 'var') || isempty(chan))
    chan = {'1A' '2A'};
end
if (~exist('duration', 'var') || isempty(duration))
    duration = 10e-9;
end
if (~exist('avg', 'var') || isempty(avg) || avg < 1)
    avg = 1;
end
if (~exist('maxAmpl', 'var') || isempty(maxAmpl))
    maxAmpl = -2;        % ampl = -2 means autoscale
end
if (~exist('trigFreq', 'var') || isempty(trigFreq))
    trigFreq = 0;
end
if (~exist('dataRate', 'var') || isempty(dataRate))
    dataRate = trigFreq;
end
if (dataRate ~= 0)
    if (abs(mod(dataRate, trigFreq)) > eps)
        errordlg('dataRate must be an integer multiple of trigFreq');
        error('dataRate must be an integer multiple of trigFreq');
    end
end
if (~exist('spb', 'var') || isempty(spb))
    spb = 0;
end
if (~exist('bandwidth', 'var') || isempty(bandwidth) || strcmp(strtrim(bandwidth), ''))
    bandwidth = [];
end
if (~exist('sirc', 'var'))
    sirc = [];
end
if (~exist('doDeskew', 'var'))
    doDeskew = 0;
end
numChan = length(chan);
xfprintf(f, '*CLS');
% find out which SCPI language to use: flex or old DCA style
flex = 1;
raw_idn = xquery(f, '*IDN?');
idn = regexp(raw_idn, ',\s*', 'split');
if (strcmp(idn{1}, 'TEKTRONIX'))
    [yval, fs] = iqreaddcatek(arbConfig, chan, 0, duration, avg, maxAmpl, trigFreq);
    return;
end
if (strncmp(idn{2}, '86100C', 6))
    flex = 0;
end
%--- find out if this a DCA-M  (in this case, some of the PTB commands can not be used
if (flex)
    moduleType = findModuleType(f, chan);
else
    % legacy scope software
    moduleType = xquery(f, ':MODEL? LMODULE');
end
slot86107a = 0;
if (flex)
    for slot = 1:4
        if (strncmp(xquery(f, sprintf(':MODEL? SLOT%d', slot)), '86107A', 6))
            slot86107a = slot;
            break;
        end
    end
else
    if (strncmp(xquery(f, sprintf(':MODEL? RMODULE')), '86107A', 6))
        slot86107a = 3;
    end
end
% if (strncmp(moduleType, 'N109', 4) || strncmp(moduleType, 'N106', 4))
if (strncmp(moduleType, 'N109', 4))
    dcam = 1;
else
    dcam = 0;
end
%--- handle automatic scope amplitude
if (maxAmpl == -2)
    autoScale = 1;
    maxAmpl = 0;
else
    autoScale = 0;
end

if (maxAmpl == -1)
    maxAmpl = 0.8;      % max value supported by 86108B
    dp = strfind(chan, 'DIFF');
    if (~isempty([dp{:}]))
        maxAmpl = 2 * maxAmpl;    % for differential ports, double amplitude
    end
end
%--- some basic setup
hMsgBox.update(0.1, 'Configuring DCA...');
if (hMsgBox.canceling())
    return;
end
xfprintf(f, sprintf(':SYSTem:MODE OSC'));
xfprintf(f, sprintf(':STOP'));
xfprintf(f, sprintf(':TRIG:SOURce:AUTodetect OFF'));
xfprintf(f, sprintf(':TRIG:SOURce FPANEL'));
xfprintf(f, sprintf(':ACQuire:SPUI:MODE AUTomatic'), 1);       % BK: bugfix to avoid record length restriction error.
xfprintf(f, sprintf(':TRIG:PLOC OFF'));
xfprintf(f, '*OPC');
xfprintf(f, '*CLS'); % if the PTB clock does not match, we get an error when turning pattern lock off

% turn off the default channel, in case it is not needed
if (flex)
    xfprintf(f, ':CHAN1A:DISP OFF', 1);
else
    xfprintf(f, ':CHAN1:DISP OFF');
end
%--- configure the desired channels
[chName, chan, fchan, f2chan] = initDCAChannels(chan, f);
for i = 1:numChan
    if (~isempty(strfind(chan{i}, 'DIFF')))
        xfprintf(f, sprintf(':%s:DMODe ON', chan{i}));
    else
        if ((chan{i}(end) == 'A' || chan{i}(end) == 'C') && flex)
            xfprintf(f, sprintf(':DIFF%s:DMODe OFF', chan{i}(5:end)));
        end
    end
    ampl = maxAmpl(min(i,length(maxAmpl)));
    if (flex)
        if (ampl ~= 0)
            % don't try to set the amplitude higher than the max. supported
            qmax = str2double(xquery(f, sprintf(':%s:YSCALE? MAX', chan{i})));
            xfprintf(f, sprintf(':%s:YSCALE %g', chan{i}, min(ampl/8, qmax)));
        end
        % Do not set offset to zero. User might want to set it differently
        %    xfprintf(f, sprintf(':%s:YOFFSET %g', chan{i}, 0));
        if (isempty(bandwidth) || strncmpi(bandwidth, 'max', 3))
            xfprintf(f, sprintf(':%s:BANDwidth:FREQ MAX', fchan{i}), 0);
        elseif (isstrprop(bandwidth(1), 'alpha'))
            xfprintf(f, sprintf(':%s:BANDwidth %s', fchan{i}, bandwidth), 0);
        else
            xfprintf(f, sprintf(':%s:BANDwidth:FREQ %s', fchan{i}, bandwidth), 0);
        end
        if (xfprintf(f, sprintf(':%s:DISP ON', chan{i})))
            errordlg(sprintf('An error occurred when trying to turn on channel "%s". Please check your channel mapping.', chan{i}));
            return;
        end
    else
        if (ampl ~= 0)
            xfprintf(f, sprintf(':%s:SCALE %g', chan{i}(1:5), ampl / 8));
        end
    % Do not set offset to zero. User might want to set it differently
    %    xfprintf(f, sprintf(':%s:OFFSET %g', chan{i}(1:5), 0));
        if (~isempty(bandwidth))
            if (strncmpi(bandwidth, 'max', 3))
                % Different modules use different ENUMs for setting bandwidth
                % So, let's try out all of them and ignore any errors
                xfprintf(f, sprintf(':CHAN%s:BANDwidth HIGH', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND1', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND2', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND3', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND4', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND5', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND6', chan{i}(end-1:end-1)), 1);
                xfprintf(f, sprintf(':CHAN%s:BANDwidth BAND7', chan{i}(end-1:end-1)), 1);
            else
                xfprintf(f, sprintf(':CHAN%s:BANDwidth %s', chan{i}(end-1:end-1), bandwidth), 0);
            end
        end
        xfprintf(f, sprintf(':%s:DISP ON', chan{i}(1:5)));
    end
end
hMsgBox.update(0.2, 'Setting up PTB...');
if (hMsgBox.canceling())
    return;
end

%--- set up timebase and triggering
if (trigFreq ~= 0)
    pattLength = round(dataRate * duration);
    if (flex)
        % built-in PTB
        if (~dcam)  % don't send PTB commands to DCA-M
            if (strncmp(moduleType, '86108B', 6) || strncmp(moduleType, 'N1060', 5))
                % use module-specific PTB in 86108B and N1060
                % assume slot number in the first channel
                slot = chan{1}(5);
                xfprintf(f, sprintf(':PTimebase%s:RSOurce EXTernal', slot));
                xfprintf(f, sprintf(':PTIMebase%s:RFRequency %.15g', slot, trigFreq));
                if (xfprintf(f, sprintf(':PTIMEbase%s:STATe ON', slot)))
                    return;
                end
            elseif (slot86107a > 0)
                if (xfprintf(f, sprintf(':PTIMebase%d:RFRequency %.15g', slot86107a, trigFreq)))
                    return;
                end
                if (xfprintf(f, sprintf(':PTIMEbase%d:STATe ON', slot86107a)))
                    return;
                end
            else
                % otherwise, try to use chassis timebase
                if (~xfprintf(f, sprintf(':TIMebase:PTIMebase:RFRequency %.15g', trigFreq), 1))
                    if (xfprintf(f, sprintf(':TIMebase:PTIMEbase:STATe ON')))
                        return;
                    end
                end
            end
            xquery(f, '*OPC?');
        end
        if (xfprintf(f, sprintf(':TIMEbase:UNITs SECond')))
            return;
        end
        xfprintf(f, sprintf(':TRIG:SOURce FPANEL'));
        if (~dcam)
            xfprintf(f, sprintf(':TRIGger:MODe CLOCk'));
        end
        xfprintf(f, sprintf(':TRIGger:BRATe:AUTodetect OFF'));
        xfprintf(f, sprintf(':TRIGger:PLENgth:AUTodetect OFF'));
        xfprintf(f, sprintf(':TRIGger:DCDRatio:AUTodetect OFF'));
        xfprintf(f, sprintf(':TIMebase:BRATe %.15g', dataRate));
        xfprintf(f, sprintf(':TRIGger:PLENgth %d', pattLength));
        trigRatio = round(dataRate / trigFreq);
        trigRatioStr = 'UNITy';
        if (trigRatio > 1)
            trigRatioStr = sprintf('SUB%d', trigRatio);
        end
        % If samples per bit is specified, use it to calculate the total number of samples
        if (spb ~= 0)
            numPts = spb * pattLength;
        else
            if ~flex
                % otherwise, use a fixed maximum number of samples (128 K)
                numPts = 128*1024;
                % number of samples per bit
                spb = round(numPts / pattLength);
            else
                % set samples-per-ui properly, such that noise
                % representation is accurate 
                targetVirtualSampleRate = 1e12; 
                spb = round(targetVirtualSampleRate / dataRate) ; 
                if mod(spb,2) ~= 0
                    spb = spb + 1;
                end
                numPts = spb * pattLength;
            end
        end
        xfprintf(f, sprintf(':ACQuire:EPATtern OFF'));
        % Reset to integer in case DCD was set to fractional.
        % Ignore errors because earlier Flex Versions didn't understand this command
        xfprintf(f, sprintf(':TRIGger:DCDRatio:TYPE INTEGER'), 1);
        xfprintf(f, sprintf(':TRIGger:DCDRatio %s', trigRatioStr));
        xfprintf(f, sprintf(':MEASure:JITTer:DEFine:SIGNal:AUTodetect OFF'));
        xfprintf(f, sprintf(':MEASure:JITTer:DEFine:SIGNal DATA'));
        xfprintf(f, sprintf(':TRIGger:PLOCk ON'));
        xfprintf(f, '*OPC');
        count = 30;
        while count > 0
            esr = str2double(xquery(f, '*ESR?'));
            if (bitand(esr, 1) ~= 0)
                break;
            end
            pause(1);
            count = count - 1;
        end
        if (count <= 0)
            xfprintf(f, sprintf('*OPC'));
            errordlg('DCA did not acquire pattern lock. Please make sure that the signals are connected correctly');
            return;
        end
        % if sirc is non-empty, set it accordingly - ignore errors if SIRC is not available
        sircResponse = {'FLAT','BESSel','SINC'} ; 
        for i = 1:numChan
            if (sirc)
                xfprintf(f, sprintf(':%s:SIRC ON', fchan{i}), 1);
            else
                xfprintf(f, sprintf(':%s:SIRC OFF', fchan{i}), 1);
            end
            % must set the bandwidth for SIRC mode separately - 
            if (isempty(bandwidth))
                bw = '100e9';
            else
                bw = sscanf(bandwidth, '%g');
                if (isempty(bw))
                    bw = '100e9';
                end
            end
            % Changes BK
            xfprintf(f, sprintf(':%s:SIRC:FBANDWIDTH %s', fchan{i}, bw), 1);
            % Set SIRC response to "Flat" for minimum attenuation
            xfprintf(f, sprintf(':%s:SIRC:RESPonse %s', fchan{i}, sircResponse{1}), 1);
        end
    else
        errordlg('PatternLock not yet implemented in legacy DCA mode');
        return;
    end
else
    if (flex)
        xfprintf(f, sprintf(':TIMebase:PTIMEbase:STATe OFF'));
        xfprintf(f, sprintf(':PTIMEbase:STATe OFF'));
        xfprintf(f, sprintf(':TIMEbase:UNITs SECond'));
        xfprintf(f, sprintf(':TRIG:BWLimit EDGE'));
    else
        xfprintf(f, sprintf(':TRIG:BWLimit LOW'));
    end
end

hMsgBox.update(0.3);
if (hMsgBox.canceling())
    return;
end

xfprintf(f, sprintf(':TRIG:LEVEL %g', 0), 1);
if (~strfind(idn{2}, 'N1000A'))
    xfprintf(f, sprintf(':TRIG:SLOPe POS'));
end
xfprintf(f, sprintf(':TIMEbase:REFerence LEFT'));
xfprintf(f, sprintf(':TIMEbase:SCALe %g', duration / 1000), 1);

if (trigFreq ~= 0)
    if (flex)
%        xfprintf(f, sprintf(':ACQuire:EPATtern ON'));
%         numPts = round(round(numPts / pattLength) * pattLength);
    else
        errordlg('PatternLock not yet implemented in legacy DCA mode');
        error('PatternLock not yet implemented in legacy DCA mode');
    end
else
    if (flex)
        if (xfprintf(f, sprintf(':ACQuire:RSPec RLENgth')))
            return;
        end
        xfprintf(f, sprintf(':ACQuire:RLENgth:MODE MANUAL'));
        xfprintf(f, sprintf(':ACQuire:RLENgth MAX'));
        numPts = str2double(xquery(f, ':ACQuire:RLENgth?'));
        xfprintf(f, sprintf(':ACQuire:WRAP OFF'));
        xfprintf(f, sprintf(':ACQuire:CDISplay'));
    else
        if (xfprintf(f, sprintf(':CDISplay')))
            return;
        end
        numPts = 16384; % MAX value does not work on old DCA
        %xfprintf(f, sprintf(':ACQuire:POINts MAX'));
        %numPts = str2double(xquery(f, ':ACQuire:POINts?'));
        xfprintf(f, sprintf(':ACQuire:POINts %d', numPts));
    end
end
hMsgBox.update(0.4, 'Performing Autoscale...');
if (hMsgBox.canceling())
    return;
end

% perform autoscale with entire pattern still turned off
if (autoScale)
    xfprintf(f, ':AUTOscale');
    xquery(f, '*OPC?');
    % set timebase again
    xfprintf(f, sprintf(':TIMEbase:SCALe %g', duration / 1000), 1);
end
% turn on entire pattern AFTER autoscale
if (trigFreq ~= 0)
    if (flex)
        xfprintf(f, sprintf(':ACQuire:EPATtern ON'));
    end
end
% moved setting SPBit here to avoid record length restriction error
if (spb ~= 0)
    xfprintf(f, sprintf(':ACQuire:SPBit:MODe MANual'));
    xfprintf(f, sprintf(':ACQuire:SPBit %d', spb));
else
    if flex
       xfprintf(f, sprintf(':ACQuire:SPBit:MODe AUTomatic'));
       numPts = str2double(xquery(f, ':ACQuire:RLENgth?')); 
    end
end

%--- perform differential deskew if desired
if (doDeskew > 0)
    hMsgBox.update(0.5, 'Differential Deskew...');
    if (hMsgBox.canceling())
        return;
    end

    for i = 1:numChan
        if (strncmpi(f2chan{i}, 'DIFF', 4))
            xfprintf(f, sprintf(':%s:DSTRacking ON', f2chan{i}));
            xquery(f, '*OPC?');
            if (xfprintf(f, sprintf(':%s:DESKEW', f2chan{i})))
                return;
            end
            xquery(f, '*OPC?');
        end
    end
    if (doDeskew > 1)
        return;
    end
end

%--- set up acquisition limits and run

% in pattern lock, acquire a certain number of patterns to avoid "holes" in
% the waveform. Need 12 patterns to guarantee no holes, but experience
% shows that with only 6 patterns, very few holes remain which will be
% interpolated
numPatt = 6;

% there are several cases to be distinguished:
% PatternLock / averaging / flex or legacy
if (avg > 1)
    if (flex)
        if (trigFreq ~= 0)
            xfprintf(f, ':LTESt:ACQuire:CTYPe PATT');
            xfprintf(f, sprintf(':LTESt:ACQuire:CTYPe:PATT %d', numPatt));
        end
        xfprintf(f, sprintf(':ACQuire:SMOOTHING AVER'));
        xfprintf(f, sprintf(':ACQuire:ECOunt %d', avg));
        xfprintf(f, sprintf(':LTESt:ACQuire:CTYPe:WAVeforms %d', avg));
        xfprintf(f, sprintf(':LTESt:ACQuire:STATe ON'));
        xfprintf(f, sprintf(':ACQuire:RUN'));
    else
        xfprintf(f, sprintf(':ACQuire:AVERAGE ON'));
        xfprintf(f, sprintf(':ACQuire:COUNT %d', avg));
        xfprintf(f, sprintf(':ACQuire:RUNTil WAVEforms,%d', avg));
        xfprintf(f, sprintf(':AEEN 1'));
        xfprintf(f, sprintf(':RUN'));
    end
else
    if (flex)
        xfprintf(f, sprintf(':ACQuire:SMOOTHING NONE'));
        if (trigFreq ~= 0)
            xfprintf(f, ':LTESt:ACQuire:CTYPe PATT');
            xfprintf(f, sprintf(':LTESt:ACQuire:CTYPe:PATT %d', numPatt));
            xfprintf(f, sprintf(':LTESt:ACQuire:STATe ON'));
            xfprintf(f, sprintf(':ACQuire:RUN'));
        else
            xfprintf(f, sprintf(':LTESt:ACQuire:STATe OFF'));
            xfprintf(f, sprintf(':ACQuire:SINGLE'));
        end
    else
        xfprintf(f, sprintf(':ACQuire:AVERAGE OFF'));
        xfprintf(f, sprintf(':AEEN 0'));
%        xfprintf(f, sprintf(':SINGLE'));   % with :SINGLE, ESR? does not work
        xfprintf(f, sprintf(':RUN'));
    end
end

%--- wait until capture has completed. Don't use a blocking wait!!
xfprintf(f, '*OPC');
hMsgBox.update(0, 'Please wait, DCA capture in progress...');
pause(1);
if (trigFreq ~= 0)
    count = round(max(avg, numPatt) * (numPts / 35000));
else
    count = round(avg * 2);
end
% some spare time beyond the nominal timeout
spare = -20 - count;
startCount = count;
userBreak = 0;
while count > spare
    esr = str2double(xquery(f, '*ESR?'));
    if (bitand(esr, 1) ~= 0)
        break;
    end
    hMsgBox.update(mod(startCount - count, startCount)/startCount);
    if (hMsgBox.canceling())
        userBreak = 1;
        break;
    end
    pause(1);
    count = count - 1;
end
delete(hMsgBox);
if (userBreak)
    return;
end
if (count <= spare)
    if (trigFreq ~= 0)
        errordlg('Scope timeout during waveform capture. Please make sure that the trigger signal is connected to the front panel trigger input *and* the Precision Timebase input');
    else
        errordlg('Scope timeout during waveform capture. Please make sure that the trigger signal is connected to the front panel trigger input');
    end
    return;
end
%fprintf('%d samples, %d avg, %d sec, %d sec max., %g (samples * avg) per second\n', numPts, avg, startCount - count, startCount, numPts * avg / (startCount - count));

yval = zeros(numPts, numChan);

%--- get the waveform from the scope
for i=1:numChan
    if (flex)
        xfprintf(f, sprintf(':WAVeform:SOURce %s', chan{i}));
        xOrig = str2double(xquery(f, ':WAVeform:YFORmat:XORigin?'));
        xInc  = str2double(xquery(f, ':WAVeform:YFORmat:XINC?'));
        yOrig = str2double(xquery(f, ':WAVeform:YFORmat:WORD:ENC:YORigin?'));
        yInc  = str2double(xquery(f, ':WAVeform:YFORmat:WORD:ENC:YINC?'));
        tmp = xbinblockread(f, 'int16', ':WAVeform:YFORmat:WORD:YDATA?');
    else
        xfprintf(f, sprintf(':WAVeform:SOURce %s', chan{i}(1:5)));
        xfprintf(f, sprintf(':WAVeform:FORMAT WORD'));
        tmp = xbinblockread(f, ':WAVeform:DATA?', 'int16');
        xOrig = str2double(xquery(f, ':WAVeform:XORigin?'));
        xInc  = str2double(xquery(f, ':WAVeform:XINC?'));
        yOrig = str2double(xquery(f, ':WAVeform:YORigin?'));
        yInc  = str2double(xquery(f, ':WAVeform:YINC?'));
    end
    % check for overflow
    if (~isempty(find(tmp == 32256, 1)) || ~isempty(find(tmp == 32256, 1)))
        warndlg('Signal exceeds scope range. Consider reducing the scope amplitude scale or insert an attenuator in the signal path', 'Scope Amplitude exceeded', 'replace');
    end
    % replace negative overflow by a negative value
    tmp(tmp == 31744) = -32767;
    % find invalid values ("holes" in PTB) 
    tmp(tmp == 31232) = NaN;
    invidx = find(isnan(tmp));
    if (~isempty(invidx))
        %fprintf('%d invalid samples - interpolating\n', length(invidx));
        % fill them by interpolation
        xtmp = tmp; xtmp(invidx) = [];
        xaxs = 1:numPts; xaxs(invidx) = [];
        tmp(invidx) = interp1(xaxs, xtmp, invidx);
    end
    % convert to voltage values
    fs = 1 / xInc;
    xval = (1:numPts) * xInc + xOrig;
    try
        yval(:,i) = tmp * yInc + yOrig;
    catch
    end
end
if (flex)
    xfprintf(f, sprintf(':ACQuire:SMOOTHING NONE'));
    xfprintf(f, sprintf(':LTESt:ACQuire:STATe OFF'));
    xfprintf(f, sprintf(':ACQuire:RUN'));
    if (trigFreq ~= 0)
        xfprintf(f, sprintf(':TIMEbase:SCALe %g', 1/trigFreq));
    end
else
    xfprintf(f, sprintf(':ACQuire:AVERAGE OFF'));
    xfprintf(f, sprintf(':AEEN 0'));
end
iqclose(f);
% if called without output arguments, plot the result
if (nargout == 0)
    figure(151);
    plot(xval, yval, '.-');
    yval = [];
end


function [chName, scopeChannels, fchan, f2chan] = initDCAChannels(scopeChannels, fscope)
% NOTE: Same function as in iqskewcalM8199A.m
%
% input            scopeChan   chName     fchan    f2chan
% -------------------------------------------------------
% xy               CHANxy      CHANxy     CHANxy   CHANxy (where xy = 1A, 2A,..., 1B, 2B, etc.)
% CHANxy           CHANxy      CHANxy     CHANxy   CHANxy
% DIFFxy           DIFFxy      CHANxy     CHANxy   DIFFxy
% FUNCm            FUNCm       CHANpq     CHANpq   CHANxy/DIFFxy (where CHANpq is the channel from which FUNCm is derived)
%
numChan = length(scopeChannels);
chName = scopeChannels;
fchan = scopeChannels;
f2chan = scopeChannels;
for i = 1:numChan
    if (length(scopeChannels{i}) <= 2)              % map 1A to CHAN1A
        scopeChannels{i} = ['CHAN' scopeChannels{i}];
        chName{i} = scopeChannels{i};
        fchan{i} = scopeChannels{i};
        f2chan{i} = scopeChannels{i};
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
            f2chan{i} = FunctionSource;
            chName{i} = ['CHAN' FunctionSource(5:end)];
            fchan{i} = chName{i};
        else
            chName{i} = FunctionSource ; 
            fchan{i} = chName{i};
        end
    end
end


function moduleType = findModuleType(f, chan)
% default behavior: start at slot 1 and search for a module
slot = 1;
searchDir = 1;
% locate a channel that points to a slot number
for i = 1:length(chan)
    if (~strncmpi(chan{i}, 'FUNC', 4))
        slot = str2double(chan{i}(end-1));
        % set search direction backwards because sometimes, the channel
        % number is slot number + 1
        searchDir = -1;
        break;
    end
end
foundModule = false;
while (~foundModule && slot >= 1 && slot <= 8)
    moduleType = xquery(f, sprintf(':MODEL? SLOT%d', slot));
    if (~strncmpi(moduleType, 'Not Present', 11))
        foundModule = true;
        break;
    end
    slot = slot + searchDir;
end
if (~foundModule)
    moduleType = '';
    warndlg('Can''t determine which type of DCA module you are using. Uploading data from scope might not work correctly in this case.');
end


% function a = binread(f, cmd, fmt)
% a = [];
% fprintf(f, cmd);
% r = fread(f, 1);
% if (~strcmp(char(r), '#'))
%     error('unexpected binary format');
% end
% r = fread(f, 1);
% nch = str2double(char(r));
% r = fread(f, nch);
% nch = floor(str2double(char(r))/2);
% if (nch > 0)
%     a = fread(f, nch, fmt);
% else
%     a = [];
% end
% fread(f, 1); % read EOL
% 
% 
% 
% 
% function retVal = xbinread(f, cmd, fmt)
% retVal = binread(f, cmd, fmt);
% if (evalin('base', 'exist(''debugScpi'', ''var'')'))
%     rstr = sprintf('(%d elements)', length(retVal));
%     fprintf('%s - %s -> %s\n', f.Name, cmd, strtrim(rstr));
% end
