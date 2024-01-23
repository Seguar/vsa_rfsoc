function [yval, fs] = iqreaddcatek(arbConfig, chan, ~, duration, avg, maxAmpl, trigFreq)
% read a waveform from Tek DSA8200
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
% trigFreq - trigger frequency in Hz. Zero for once per waveform
%            Non-zero trigger frequency will use PatternLock
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

if (maxAmpl == -2)
    autoScale = 1;
    maxAmpl = 0;
else
    autoScale = 0;
end

if (maxAmpl == -1)
    maxAmpl = 1;      % max value supported by Tek DSA8200
    dp = strfind(chan, 'DIFF');
    if (~isempty([dp{:}]))
        maxAmpl = 2 * maxAmpl;    % for differential ports, double amplitude
    end
end
if (~exist('trigFreq', 'var') || isempty(trigFreq))
    trigFreq = 0;
end
numChan = length(chan);
xfprintf(f, '*CLS; :HEADER OFF');
query(f, '*ESR?');  % clear event status register
raw_idn = xquery(f, '*IDN?');
idn = regexp(raw_idn, ',\s*', 'split');
if (~strcmp(idn{2}, 'DSA8200'))
    errordlg('So far, only DSA8200 is supported');
    return;
end
%--- some basic setup

%--- configure the desired channels
for i = 1:numChan
    if (~isempty(strfind(chan{i}, 'DIFF')))
        xfprintf(f, sprintf(':%s:DMODe ON', chan{i}));
    else
        if (length(chan{i}) <= 2)
            chan{i} = strcat('CH', chan{i}(1));
        end
    end
    ampl = maxAmpl(min(i,length(maxAmpl)));
    if (ampl ~= 0)
        % don't try to set the amplitude higher than the max. supported
        qmax = 1;  % qmax = str2double(xquery(f, sprintf(':%s:SCALE? MAX', chan{i})));
        xfprintf(f, sprintf(':%s:SCALE %g', chan{i}, min(ampl/10, qmax)));
    end
    % Do not set offset to zero. User might want to set it differently
    %    xfprintf(f, sprintf(':%s:YOFFSET %g', chan{i}, 0));
    % Different modules use different ENUMs for setting bandwidth
    % So, let's try out all of them and ignore any errors
    xfprintf(f, sprintf(':SELECT:%s ON', chan{i}));
end

%--- set up timebase and triggering
if (trigFreq ~= 0)
    error('pattern lock not implemented');
end
xfprintf(f, sprintf(':HORIZONTAL:MAIN:POSITION %g', max(24e-9, 0)));
xfprintf(f, sprintf(':HORIZONTAL:MAIN:SCALe %g', duration / 10));

numPts = 4000;
xfprintf(f, sprintf(':HORIZONTAL:MAIN:RECORDLENGTH %d', numPts));

if (autoScale)
    xfprintf(f, ':AUTOSET:HORIZONTAL OFF; TRIGGER OFF; VERTICAL ON; :AUTOSET');
end

if (avg > 1)
    xfprintf(f, sprintf(':ACQuire:MODE AVERAGE'));
else
    xfprintf(f, sprintf(':ACQuire:MODE SAMPLE'));
end
xfprintf(f, ':DATA:START 1');
xfprintf(f, ':DATA:STOP 4000');
xfprintf(f, ':DATA:ENCDG SRIBINARY');
xfprintf(f, ':ACQUIRE:DATA:CLEAR');
xfprintf(f, ':ACQUIRE:STATE ON');

%--- wait until capture has completed. Don't use a blocking wait!!
% xfprintf(f, '*OPC');
% pause(2);
count = round(avg * 2) + 10;
while count > 0
    busy = str2double(xquery(f, ':BUSY?'));
    if (busy == 0)
        break;
    end
    pause(1);
    count = count - 1;
end
if (count <= 0)
    errordlg('Scope timeout during waveform capture. Please make sure that the trigger signal is connected to the front panel trigger input');
    return;
end
yval = zeros(numPts, numChan);

%--- get the waveform from the scope
for i=1:numChan
    rpt = 3;
    while (rpt > 0)
        xfprintf(f, sprintf(':DATA:SOURce %s', chan{i}));
        xfprintf(f, sprintf(':DATA:TIMEBASE MAIN'));
        tmp = xbinblockread(f, 'int32', 'CURVE?');
        rpt = rpt - 1;
        if (~isempty(tmp))
            break;
        end
    end
    if (isempty(tmp))
        errordlg('Could not read trace from scope after 3 tries');
        error('Could not read trace from scope after 3 tries');
    end
    res = xquery(f, ':HEADER OFF; :WFMOUTPRE?');
    p = strsplit(res, ';');
    xInc = str2double(p{8});   % xscale
    xOrig = str2double(p{13}); % xoffset
    yInc = str2double(p{15});  % yscale
    yOrig = str2double(p{16}); % yoffset
    % replace negative overflow by a negative value
    % --- to be done ---
    
    % convert to voltage values
    fs = 1 / xInc;
    xval = (1:numPts) * xInc + xOrig;
    try
        yval(:,i) = tmp * yInc + yOrig;
    catch
    end
end
iqclose(f);
% if called without output arguments, plot the result
if (nargout == 0)
    figure(151);
    plot(xval, yval, '.-');
    yval = [];
end
