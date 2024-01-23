function [result, fs] = iqreadM8296A(arbConfig, chan, trigChan, duration, avg, maxAmpl, ~, ~, ~)
% read a waveform from M8296A
%
% arguments:
% arbConfig - if empty, use realtime scope address configured in IQTools config
% chan - cell array of scope channels to be captured ('1'...'4')
% trigChan - no supported
% duration - length of capture (in seconds)
% avg - not supported
% maxAmpl - amplitude of the signal (will be used to set Y scale)
%           if set to 0, will not set amplitude
%           if set to -1, will autoscale
% trigDelay - trigger delay (zero if not specified)
% trigLevel - trigger level (zero if not specified)
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
numChan = length(chan);
result = [];
fs = 0;
f = iqopen(arbConfig.visaAddrScope);
if (isempty(f))
    return;
end
xfprintf(f, sprintf('*CLS'));
if (avg > 1)
    errordlg('Averaging is not supported in M8296A');
    return;
end
for i = 1:numChan
    if (maxAmpl > 0)
        a = maxAmpl(min(i,length(maxAmpl)));
        xfprintf(f, sprintf(':VOLT%s %g', chan{i}, a));
    elseif (maxAmpl < 0)
        % t.b.d. autoscale
        xfprintf(f, sprintf(':VOLT%s %g', chan{i}, 800e-3));
    end
    xfprintf(f, sprintf(':INP%s 1', chan{i}));
end

% Determine the sample rate set in the digitizer.
% For the time being, we'll just use whatever is configured as a default
fs = str2double(xquery(f, ':FREQ:RAST?'));
maxpts = 256*1024;
if (duration == 0)
    numPts = maxpts;
else
    numPts = min(maxpts, ceil(duration * fs));
end
% round the number of points up to the next multiple of granularity
gr = 128;
numPtsToRead = ceil(numPts / gr) * gr;
for i = 1:numChan
    xfprintf(f, sprintf(':TRAC%s:DEF %d', chan{i}, numPtsToRead));
end

% Start acquisition and wait until digitizer has triggered and stored waveform in memory
xfprintf(f, ':ABORT');
xfprintf(f, ':INIT:IMM');
retry2 = 30;
while (retry2 > 0 && str2double(xquery(f, ':STAT:OPER:RUN:COND?')) ~= 0)
    pause(0.2);
    retry2 = retry2 - 1;
end
if (retry2 <= 0)
    errordlg('M8296A did not capture a waveform');
    return;
end
% prepare waveform upload
result = zeros(numPtsToRead, numChan);
for i = 1:numChan
    offset = 0;
    chunkSize = 64*1024;
    while (offset < numPtsToRead)
        len = min(chunkSize, numPtsToRead - offset);
        cmd = sprintf(':TRAC%s:DATa:BLOCK? %d,%d', chan{i}, offset, len);
        a = xbinblockread(f, 'float32', cmd);
%         xfprintf(f, cmd);
%         r = fread(f, 1);
%         if (~strcmp(char(r), '#'))
%             error('unexpected binary format');
%         end
%         r = fread(f, 1);
%         nnch = str2double(char(r));
%         r = fread(f, nnch);
%         nch = floor(str2double(char(r))/4);
%         if (nch ~= len)
%             fprintf('binary block contains %d samples - expected %d\n', nch, len);
%         end
%         if (nch > 0)
%             a = fread(f, nch, 'float32');
%         else
%             a = [];
%         end
%         fread(f, 1); % read EOL
        result(offset+1:offset+len, i) = a;
        offset = offset + len;
    end
end
% remove unwanted samples
result(numPts+1:end,:) = [];
iqclose(f);
ylimits = zeros(numChan, 2);
if (nargout == 0)
    figure(1);
    xval = linspace(0, (numPts-1)/fs, numPts);
    for i = 1:numChan
        subplot(numChan, 1, i);
        plot(xval, result(:,i), '.-');
        hGCA = gca();
        ylimits(i, :) = hGCA.YLim;
        title(sprintf('Channel %d', i));
        grid on;
    end
    yl = [min(ylimits(:,1)), max(ylimits(:,2))];
    for i = 1:numChan
        subplot(numChan, 1, i);
        ylim(yl);
    end
end


