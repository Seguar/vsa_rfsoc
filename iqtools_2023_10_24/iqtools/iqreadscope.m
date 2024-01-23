function [result, fs] = iqreadscope(arbConfig, chan, trigChan, duration, avg, maxAmpl, ~, trigDelay, trigLevel, bandwidth, ~, ~)
% read a waveform from scope
%
% arguments:
% arbConfig - if empty, use realtime scope address configured in IQTools config
% chan - cell array of scope channels to be captured ('1'-'4', 'DIFF1-3', 'DIFF2-4', 'DIFF1-2', 'DIFF3-4', 'REdge1', 'REdge3', 'DIFFREdge', 'FUNCx')
% trigChan - string with trigger channel ('1'-'4', 'AUX' or 'unused')
% duration - length of capture (in seconds)
% avg - number of averages (1 = no averaging)
% maxAmpl - amplitude of the signal (will be used to set Y scale)
%           if set to 0, will not set amplitude
%           if set to -1, will autoscale
% trigDelay - trigger delay (zero if not specified)
% trigLevel - trigger level (zero if not specified)
% bandwidth - scope bandwidth (unchanged if not specified)
%
if (~exist('arbConfig', 'var'))
    arbConfig = [];
end
arbConfig = loadArbConfig(arbConfig);
if ((isfield(arbConfig, 'isScopeConnected') && arbConfig.isScopeConnected == 0) || ~isfield(arbConfig, 'visaAddrScope'))
    error('Scope address is not configured, please use "Instrument Configuration" to set it up');
end
if (~exist('chan', 'var'))
    chan = {'1' '2'};
end
if (ischar(chan))   % single channel, convert to cell
    chan = { chan };
end
if (~iscell(chan))
    error('channels must be specified as cell array');
end
if (~exist('trigChan', 'var'))
    trigChan = 'unused';
end
if (~exist('duration', 'var') || isempty(duration))
    duration = 1e-6;
end
if (~exist('avg', 'var') || isempty(avg) || avg < 1)
    avg = 1;
end
if (~exist('maxAmpl', 'var') || isempty(maxAmpl))
    maxAmpl = 800e-3;
end
if (~exist('trigDelay', 'var') || isempty(trigDelay))
    trigDelay = 0;
end
if (~exist('trigLevel', 'var') || isempty(trigLevel))
    trigLevel = 0;
end
if (~exist('bandwidth', 'var') || isempty(bandwidth) || strcmp(strtrim(bandwidth), ''))
    bandwidth = [];
end
numChan = length(chan);
result = [];
fs = 0;
diffChan = 0;
f = iqopen(arbConfig.visaAddrScope);
if (isempty(f))
    return;
end
model = xquery(f, '*IDN?');
if (~isempty(strfind(model, 'M8131')))
    [result, fs] = iqreadM8131A(arbConfig, chan, trigChan, duration, avg, maxAmpl, 0, trigDelay, trigLevel);
    return;
elseif (~isempty(strfind(model, 'M8296')))
    [result, fs] = iqreadM8296A(arbConfig, chan, trigChan, duration, avg, maxAmpl, 0, trigDelay, trigLevel);
    return;
elseif (~isempty(strfind(model, 'MSO-X 4')))
    model4k = 1;
else
    model4k = 0;
end
% set MXR to 50 Ohm. Factory default is 1 MOhm
if (~isempty(strfind(model, 'MXR')))
    isMXR = 1;
else
    isMXR = 0;
end

xfprintf(f, sprintf('*CLS'));
xfprintf(f, sprintf(':TIMEbase:SCale %g', duration / 10));
xfprintf(f, sprintf(':TIMEbase:REFerence LEFT'));
xfprintf(f, sprintf(':TIMEbase:DELay %g', trigDelay));
%xfprintf(f, sprintf(':STOP'));   % do not stop, otherwise autoscale will not work
%xfprintf(f, sprintf(':ACQuire:BANDwidth MAX'));   % do not set max BW, user might not want that
if (avg > 1)
    if (model4k)
        xfprintf(f, sprintf(':ACQuire:COUNT %d', avg));
    else
        xfprintf(f, sprintf(':ACQuire:AVERage:COUNT %d', avg));
    end
    xfprintf(f, sprintf(':ACQuire:AVERage ON'));
else
    xfprintf(f, sprintf(':ACQuire:AVERage OFF'));
end
xfprintf(f, sprintf(':ACQuire:MODE RTIME'));
if (~isempty(bandwidth))
    xfprintf(f, sprintf(':ACQuire:BANDwidth %s', bandwidth));
end
if (~model4k)
    xfprintf(f, sprintf(':ACQuire:RESPonse FLATmag'), 1);
end
% workaround for MSO 4K - it can't autoscale a single channel without
% affecting the others
if (model4k)
    xfprintf(f, sprintf(':CHAN%s:IMPEDANCE FIFTY', chan{1}));
    xfprintf(f, sprintf(':AUTOSCALE CHAN%s', chan{1}));
    maxAmpl = str2double(xquery(f, sprintf(':CHAN%s:RANGe?', chan{1})));
    % reset timebase - autoscale has modified it
    xfprintf(f, sprintf(':TIMEbase:SCale %g', duration / 10));
    xfprintf(f, sprintf(':TIMEbase:REFerence LEFT'));
end

% turn off the default channel in case it is not used - it will be turned
% back on below if it is part of the configuration
xfprintf(f, ':CHAN1:DISP OFF');
for i = 1:numChan
    prefix{i} = 'CHAN';
    if (strncmpi(chan{i}, 'DIFF', 4))
        diffChan = 1;
        if (strcmpi(chan{i}, 'DIFF1-2') || strcmpi(chan{i}, 'DIFF3-4'))
            xfprintf(f, ':ACQ:DIFF:PART ADJ');
        else
            xfprintf(f, ':ACQ:DIFF:PART EOTH', 1); % don't check for errors - some scopes don't know this command
        end
        if (strncmpi(chan{i}, 'DIFFRE', 6))
            chan{i} = '1';      % differential real edge is only available on channel 1
            xfprintf(f, sprintf(':ACQuire:REDGE ON'), 1);
        else                    % differential signalling on a normal channel
            chan{i} = chan{i}(5);
            xfprintf(f, sprintf(':ACQuire:REDGE OFF'), 1);
        end
        xfprintf(f, sprintf(':CHAN%s:DIFF ON', chan{i}));
        if (isMXR)
            % switch the MXR to 50 Ohm. For unknown reasons, this command
            % occasionally returns a -222 error, but it still works
            xfprintf(f, sprintf(':CHAN%s:INP DC50', chan{i}), 1);
        end
        % amplitude values seem to be specified per channel and NOT for the
        % differential channel
        ampl = maxAmpl(min(i,length(maxAmpl))) / 2;
    elseif (strncmpi(chan{i}, 'REdge', 5))  % real edge, single ended
        chan{i} = chan{i}(6);
        xfprintf(f, sprintf(':ACQuire:REDGE ON'), 1);
        ampl = maxAmpl(min(i,length(maxAmpl)));
    elseif (strncmpi(chan{i}, 'FUNC', 4))
        prefix{i} = 'FUNC';
        chan{i} = chan{i}(5:end);
        ampl = maxAmpl(min(i,length(maxAmpl)));
    else                                    % normal channel, single ended
        chan{i} = chan{i}(1);
        if (~model4k)
            xfprintf(f, sprintf(':CHAN%s:DIFF OFF', chan{i}));
            xfprintf(f, sprintf(':ACQuire:REDGE OFF'), 1);
        end
        if (isMXR)
            xfprintf(f, sprintf(':CHAN%s:INP DC50', chan{i}));
        end
        ampl = maxAmpl(min(i,length(maxAmpl)));
    end
    xfprintf(f, sprintf(':%s%s:DISP ON', prefix{i}, chan{i}));
    if (model4k)
        xfprintf(f, sprintf(':CHAN%s:IMPEDANCE FIFTY', chan{i}));
    end
    if (ampl < 0) % autorange, but ignore errors - known bug in scopes
        xfprintf(f, ':RUN');
        xfprintf(f, sprintf(':ACQuire:ADC:CLIPped:CLEar'), 1);
        xfprintf(f, sprintf(':AUTOSCALE:VERT %s%s', prefix{i}, chan{i}), 1);
        xquery(f, '*OPC?');
        % Bug in auto-scale for differential signals, sometimes vertical scaling is arbitrarily set to minScale ; check if ADC is still clipping prevents this
        if (diffChan)
            adcClipped = str2double(xquery(f, sprintf(':CHAN%s:ADC:CLIPped?',chan{i})));
            loopCnt = 0;
            while adcClipped > 0 && loopCnt < 10
                xfprintf(f, sprintf(':AUTOSCALE:VERT %s%s', prefix{i}, chan{i}), 1);
                xquery(f, '*OPC?');
                adcClipped = str2double(xquery(f, sprintf(':CHAN%s:ADC:CLIPped?',chan{i})));
                loopCnt = loopCnt + 1 ;
            end
        end
        ampl = 0;
    end
    if (ampl > 0) % zero means do not set amplitude
        xfprintf(f, sprintf(':%s%s:RANGe %g', prefix{i}, chan{i}, ampl));
        xfprintf(f, sprintf(':%s%s:OFFS %g', prefix{i}, chan{i}, 0));
    end
end

if (~isempty(trigChan))
    if (strncmpi(trigChan, 'REdge', 5))
        trigChan = trigChan(6:end);
    end
    trigAuto = 0;
    if (strcmpi(trigChan, 'unused'))    % use the first measured channel as a trigger
        xfprintf(f, sprintf(':TRIGger:EDGE:SOURce CHAN%s', chan{1}));
        xfprintf(f, sprintf(':TRIGger:LEVel CHAN%s,%g', chan{1}, trigLevel));
        trigAuto = 1;
    elseif (strcmp(trigChan, 'AUX'))    % use AUX Trigger
        xfprintf(f, sprintf(':TRIGger:EDGE:SOURce AUX'));
        xfprintf(f, sprintf(':TRIGger:LEVel AUX,%g', trigLevel));
    else                                % regular trigger channel
        xfprintf(f, sprintf(':TRIGger:EDGE:SOURce CHAN%s', trigChan));
        xfprintf(f, sprintf(':TRIGger:LEVel CHAN%s,%g', trigChan, trigLevel));
        ampl = maxAmpl(1);
        if (ampl < 0)   % autorange
            xfprintf(f, sprintf(':CHAN%s:DISP ON', trigChan));
            xfprintf(f, sprintf(':AUTOSCALE:VERT CHAN%s', trigChan));
            xquery(f, '*OPC?');
            ampl = 0;
        end
        if (ampl > 0)   % user-defined range
            xfprintf(f, sprintf(':CHAN%s:RANGe %g', trigChan, maxAmpl(1)));
            xfprintf(f, sprintf(':CHAN%s:OFFS %g', trigChan, 0));
        end
        if (model4k)
            xfprintf(f, sprintf(':CHAN%s:IMPEDANCE FIFTY', trigChan));
        end
        % if the trigger channel is not a channel to be captured, then turn it off
        if (isempty(find(strcmp(trigChan, chan), 1)))
            xfprintf(f, sprintf(':CHAN%s:DISP OFF', trigChan));
        end
    end
    xfprintf(f, sprintf(':TRIGger:MODE EDGE'));
    xfprintf(f, sprintf(':TRIGger:EDGE:SLOPe POS'));
    if (trigAuto)
        xfprintf(f, sprintf(':TRIGger:SWEEP AUTO'));
    else
        xfprintf(f, sprintf(':TRIGger:SWEEP TRIGgered'));
    end
end

xfprintf(f, sprintf(':ACQuire:SRATE MAX'));     
fs = str2double(xquery(f, ':ACQuire:SRATE?'));
numPts = round(duration * fs);
if (~model4k)
    xfprintf(f, sprintf(':ACQuire:POINts %d', numPts));
    xfprintf(f, sprintf(':ACQuire:INTerpolate OFF'));
    % chaning the number of points might change the sample rate, so set it back
    xfprintf(f, sprintf(':ACQuire:SRATE %g', fs));
end

xfprintf(f, ':WAVeform:FORMat WORD');
if (isa(f, 'tcpip'))
    xfprintf(f, ':WAVeform:BYTeorder MSBFIRST');
else
    xfprintf(f, ':WAVeform:BYTeorder LSBFIRST');
end
if (model4k)
    chkCmd1 = 'OPER?';
    chkCmd2 = [];
    mask = 32;
else
    chkCmd1 = 'ADER?';
    if (isMXR)
        chkCmd2 = 'PDER?';
    else
        chkCmd2 = [];
    end
    mask = 1;
    xquery(f, chkCmd1);  % clear acquisition done register
end
xfprintf(f, ':SINGLE');
% wait until scope has triggered
retry = 0;
res = str2double(xquery(f, chkCmd1));
done = bitand(mask, uint32(res));
% wait max. 5 sec for a trigger event - otherwise fail (Z592 is particularly slow...)
while (~done && retry < 50)
    pause(0.1);
    done = bitand(mask, uint32(str2double(xquery(f, chkCmd1))));
    retry = retry + 1;
end
if (~done)
    errordlg('Scope did not trigger. Please verify that the connections between AWG and scope matches the configuration');
    iqclose(f);
    return;
end

% another check for the MXR
if (~isempty(chkCmd2))
    retry = 0;
    res = str2double(xquery(f, chkCmd2));
    done = bitand(mask, uint32(res));
    % wait max. 5 sec for completion
    while (~done && retry < 50)
        pause(0.1);
        done = bitand(mask, uint32(str2double(xquery(f, chkCmd2))));
        retry = retry + 1;
    end
    if (~done)
        errordlg('Scope did not trigger. Please verify that the connections between AWG and scope matches the configuration');
        iqclose(f);
        return;
    end
end

% ensure that streaming is off
xfprintf(f, ':WAVeform:STReaming OFF');
xquery(f, '*OPC?');
xfprintf(f, ':SYSTem:HEADer OFF');
% read waveform information from scope
for i = 1:numChan
    xfprintf(f, sprintf(':WAVeform:SOURce %s%s', prefix{i}, chan{i}));
    xquery(f, '*OPC?');
    preStr = xquery(f, ':WAVeform:PREamble?');
    pre = eval(['{' regexprep(char(preStr), '"', '''') '}']);
    if (model4k)
        fields = {'wav_form', 'acq_type', 'wfmpts', 'avgcnt', 'x_increment', 'x_origin', ...
        'x_reference', 'y_increment', 'y_origin', 'y_reference'};
    else
        fields = {'wav_form', 'acq_type', 'wfmpts', 'avgcnt', 'x_increment', 'x_origin', ...
        'x_reference', 'y_increment', 'y_origin', 'y_reference', 'coupling', ...
        'x_display_range', 'x_display_origin', 'y_display_range', ...
        'y_display_origin', 'date', 'time', 'frame_model', 'acq_mode', ...
        'completion', 'x_units', 'y_units', 'max_bw_limit', 'min_bw_limit'};
    end
    try
        prx = cell2struct(pre, fields, 2);
    catch
        err = sprintf(['Reading information from scope failed.\nCmd = ":WAV:PRE?" for %s%s\nReturn value = "%s"\n' ...
            'len(pre)=%d, expected=%d.\n\nPlease reset the scope to Factory Defaults and try again'], ...
            prefix{i}, chan{i}, strtrim(preStr), length(pre), length(fields));
        error(err);
    end
    a = xbinblockread(f, 'int16', ':WAVeform:DATa?');
%     xfprintf(f, ':WAVeform:DATa?');
%     r = fread(f, 1);
%     if (~strcmp(char(r), '#'))
%         error('unexpected binary format');
%     end
%     r = fread(f, 1);
%     nch = str2double(char(r));
%     if (nch == 0)
%         errordlg(sprintf('Error reading waveform from scope.\nBinary block has zero length.\nPlease reset the scope to Factory Defaults and try again.'));
%         break;
%     end
%     r = fread(f, nch);
%     nch = floor(str2double(char(r))/2);
%     if (nch > 0)
%         a = fread(f, nch, 'int16');
%     else
%         a = [];
%     end
%     fread(f, 1); % real EOL
    if (model4k)
        fs = 1/prx.x_increment;
        a = a+32768; a(a>=32768) = a(a>32768) - 65536;
    end
    xval = linspace(prx.x_origin, prx.x_origin + (prx.wfmpts-1)*prx.x_increment, prx.wfmpts);
    yval = a .* prx.y_increment + prx.y_origin;
    result(1:length(yval),i) = yval;  % yval might be shorter than expected
end
xfprintf(f, sprintf('*OPC'));
iqclose(f);
if (nargout == 0)
    figure(1);
    plot(xval, result, '.-');
    grid on;
end


