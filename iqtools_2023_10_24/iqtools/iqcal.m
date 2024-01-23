function result = iqcal(varargin)
% Generate amplitude correction vector from a multi-tone signal.
% Arguments are given as attrtibute/value pairs. Possible arguments:
%  - offset: frequency offset in Hz that is added to all tones before
%         taking a measurement (use offset when tones are upconverted)
%         if offset is negative, tone frequencies are subtracted
%  - tone: vector of tones at which measurement is performed.
%  - method: one of 'zero span', 'marker', 'list sweep', 'single tone'
%  - update: if set to 0, will not write the ampCorr file. (default = 1)
%  - plot: if set to 0, will not plot the result (default = 1)
%  - recalibrate: If set to 1, the list of frequencies is taken from
%          the existing amplitude correction file (iqampCorrFilename()). The
%          measurement is added to the existing correction in this case.

%% parse optional arguments
result = [];
tone = [];
method = 'zero span';
fs = 0;
correction = 0;
offset = 0;
update = 1;
doPlot = 1;
recalibrate = 0;
hMsgBox = [];
normalize = 0;
magnitude = 0;
chMap = [1 0; 0 1];
arbConfig = [];
handles = [];
usePerChannelCorr = 1;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'arbconfig'; arbConfig = varargin{i+1};
            case 'offset'; offset = varargin{i+1};
            case 'tone'; tone = varargin{i+1};
            case 'magnitude'; magnitude = varargin{i+1};
            case 'method'; method = varargin{i+1};
            case 'samplerate'; fs = varargin{i+1};
            case 'correction'; correction = varargin{i+1};
            case 'update'; update = varargin{i+1};
            case 'chmap'; chMap = varargin{i+1};
            case 'plot'; doPlot = varargin{i+1};
            case 'handles'; handles = varargin{i+1};
            case 'recalibrate'; recalibrate = varargin{i+1};
            case 'perchannelcorr'; usePerChannelCorr = varargin{i+1};
            case 'msgbox'; hMsgBox = varargin{i+1};
            case 'normalize'; normalize = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

% close message box - we do our own
if (~isempty(hMsgBox))
    close(hMsgBox);
end
% make sure tone vector is the correct shape (one column)
if (size(tone,2) > 1)
    tone = tone';
end

% check, if spectrum analyzer is configured
[arbConfig, saConfig] = loadArbConfig();
if (~saConfig.connected)
    errordlg('Please use "Configure Instruments" to configure a spectrum analyzer connection');
    return;
end

chs = find(sum(chMap,2));   % vector of channel numbers on which the signal was downloaded
% if a list of frequencies is specified, use them as a starting point for a
% new correction. Otherwise use existing correction is used as a starting
% point. The measurement is added to the existing correction in this case.
[acs, oldCorr, err] = getOldCorr(arbConfig, tone, chs, recalibrate, usePerChannelCorr);
if (err)
    return;
end

% establish a connection to spectrum analyzer
f = iqopen(saConfig);
if (isempty(f))
    return;
end

hWaitBar = iqwaitbar('Initializing measurement, please wait...');

xfprintf(f, '*CLS');

%% call the appropriate routine for the type of spectrum analyzer
switch (method)
    case 'list sweep'
        list = comp_ListSweep(f, abs(tone + offset));
    case 'marker'
        list = comp_Marker(f, abs(tone + offset), hWaitBar);
    case 'zero span'
        list = comp_ZeroSpan(f, abs(tone + offset), hWaitBar);
    case 'single tone'
        list = comp_SingleTone(f, abs(tone + offset), fs, correction, hWaitBar);
    otherwise
        errordlg(['iqcal: unknown method: ' method]);
           error(['iqcal: unknown method: ' method]);
end
iqclose(f);
try delete(hWaitBar); catch; end

%% calculate the new correction factors
% some sanity check
if (length(list) ~= length(tone) || min(list) < -100 || max(list) > 30)
    errordlg('Measurement aborted or unexpected spectrum analyzer result. Please check Fc parameter.');
    return;
end

if (isfield(acs, 'absMagnitude') && acs.absMagnitude)
    meas = list - acs.absMagnitude;
else
    % calculate deviation from average
    meas = list - sum(list)/length(list);
end
% subtract from previous correction
newCorr = oldCorr - meas;

%% plot results
if (doPlot)
    figure(10);
    title('Magnitude deviation');
    hold off;  plot(tone, meas, 'r.-');
    hold on; plot(tone, -1 * oldCorr, 'b.-');
    plot(tone, -1 * newCorr, 'k.-'); hold off;
    legend('current', 'previous', 'new');
    xlabel('Frequency (Hz)');
    ylabel('dB');
    grid on;
end

%% update correction file
if (update)
    % save updated correction file
    if (usePerChannelCorr)
        if (~updatePerChannelCorr(acs, chs, tone, newCorr))
            return;
        end
    else
        % use ampCorr structure for calibration
        acs.ampCorr = [tone newCorr];
        save(iqampCorrFilename(), '-struct', 'acs');
    end
end
result = list;
end



function list = comp_ListSweep(f, tone)
% determine power for a list of tones in MXA - using LIST SWEEP
    xfprintf(f, ':INST:SEL SA');
    old_freq = xquery(f, ':FREQ:CENT?');
    old_span = xquery(f, ':FREQ:SPAN?');
    old_bw   = xquery(f, ':BWID?');
    old_vbw  = xquery(f, ':BWID:VID?');
    old_ref  = xquery(f, ':DISP:WIND:TRAC:Y:RLEV?');
    old_pdiv = xquery(f, ':DISP:WIND:TRAC:Y:PDIV?');
    xfprintf(f, ':INIT:CONT OFF');
    xfprintf(f, ':CONF:LIST');
    cmd = sprintf(':LIST:FREQ %g', tone(1));
    for i = 2:length(tone)
        cmd = sprintf('%s,%g', cmd, tone(i));
    end
    xfprintf(f, cmd);
    xfprintf(f, ':LIST:BAND:RES:TYPE FLAT');
    xfprintf(f, ':LIST:BAND:RES 100 kHz');
    xfprintf(f, ':LIST:BAND:VID 100 kHz');
    xfprintf(f, ':LIST:SWE:TIME 40e-3');
    xfprintf(f, ':LIST:TRIG:DEL 0');
    xfprintf(f, ':LIST:DET RMS');
    xfprintf(f, ':LIST:TRIG:SOUR IMM');
    xfprintf(f, ':INIT:LIST');
    res = xquery(f, ':FETCH:LIST?');
 %   disp(res);
    xfprintf(f, ':INIT:SAN');
    xfprintf(f, ':INIT:CONT ON');
    % extract numeric values
    res = strrep(res, ',', ' ');
    list = sscanf(res, '%g');
    % back to continuous sweep mode
    xfprintf(f, sprintf(':FREQ:CENT %s', old_freq));
    xfprintf(f, sprintf(':FREQ:SPAN %s', old_span));
    xfprintf(f, sprintf(':BWID %s', old_bw));
    xfprintf(f, sprintf(':BWID:VID %s', old_vbw));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:RLEV %s', old_ref));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:PDIV %s', old_pdiv));
    xfprintf(f, ':INIT:CONT ON');
end


function list = comp_ZeroSpan(f, tone, hWaitBar)
% determine power for a list of tones using zero span measurement
    bw = abs(min(diff(tone)) / 2);
    span = 0;
    bw = min(bw, 500e3);
    xfprintf(f, ':INST SA');
    old_freq = xquery(f, ':FREQ:CENT?');
    old_span = xquery(f, ':FREQ:SPAN?');
    old_bw   = xquery(f, ':BWID?');
    old_vbw  = xquery(f, ':BWID:VID?');
    old_ref  = xquery(f, ':DISP:WIND:TRAC:Y:RLEV?');
    old_pdiv = xquery(f, ':DISP:WIND:TRAC:Y:PDIV?');
    xfprintf(f, '*RST');
    xfprintf(f, ':INIT:CONT OFF');
    xfprintf(f, sprintf(':FREQ:SPAN %.15g', span));
    if (span == 0)
        xfprintf(f, sprintf(':BWID %g', bw));
    else
        xfprintf(f, ':BWID:AUTO ON');
    end
    xfprintf(f, ':BWID:VID:AUTO ON');
    xfprintf(f, ':DISP:WIND:TRAC:Y:RLEV -10 dBm');
    xfprintf(f, ':DISP:WIND:TRAC:Y:PDIV 10 dB');
    xfprintf(f, ':CALC:MARK1:STAT ON');
    xfprintf(f, ':CALC:MARK1:MODE POS');
    mmeas = nan(length(tone), 1);
    for i = 1:length(tone)
        xfprintf(f, sprintf(':FREQ:CENT %.15g', tone(i)));
        xfprintf(f, ':INIT:IMM');
        while (xquery(f, '*OPC?') == 0)
            pause(0.05); % don't hit it too often
        end
        m1 = getPeak(f);
        % update the progress bar and break the loop if user has pressed
        % the cancel button
        hWaitBar.update(i/length(tone), sprintf('Tone %d / %d (%s)', i, length(tone), iqengprintf(m1)));
        if (hWaitBar.canceling())
            break;
        end
        mmeas(i) = m1;
        if (mmeas < -100)
            break;
        end
    end
    % back to continuous sweep mode
    xfprintf(f, sprintf(':FREQ:CENT %s', old_freq));
    xfprintf(f, sprintf(':FREQ:SPAN %s', old_span));
    xfprintf(f, sprintf(':BWID %s', old_bw));
    xfprintf(f, sprintf(':BWID:VID %s', old_vbw));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:RLEV %s', old_ref));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:PDIV %s', old_pdiv));
    xfprintf(f, ':INIT:CONT ON');
    list = mmeas;
end


function mag = getPeak(f)
% turn marker on in normal mode, perform peak search and return frequency
% and power at the marker location
    xfprintf(f, ':CALC:MARK1:STAT ON');
    xfprintf(f, ':CALC:MARK1:MODE POS');
    %xfprintf(f, ':CALC:MARK1:MAX');
    %freq_s = xquery(f, 'CALC:MARK1:X?');
    mag_s = xquery(f, 'CALC:MARK1:Y?');
    %freq = sscanf(freq_s, '%g');
    mag = sscanf(mag_s, '%g');
%    xfprintf(f, ':CALC:MARK1:STAT OFF');
end


function list = comp_Marker(f, tone, hWaitBar)
% measure power for a list of tones using a marker.
% This routine assumes that the user has set up the
% spectrum analyzer to show the list of tones.
    list = zeros(length(tone), 1);
    span = 1.1 * (max(tone) - min(tone));
    center = (max(tone) + min(tone))/2;
    bw = abs(min(diff(tone)));
    bw = min(bw, 8e6);
    xfprintf(f, ':INST SA');
    old_freq = xquery(f, ':FREQ:CENT?');
    old_span = xquery(f, ':FREQ:SPAN?');
    old_bw   = xquery(f, ':BWID?');
    old_vbw  = xquery(f, ':BWID:VID?');
    old_ref  = xquery(f, ':DISP:WIND:TRAC:Y:RLEV?');
    old_pdiv = xquery(f, ':DISP:WIND:TRAC:Y:PDIV?');
% uncomment this to set the spectrum analyzer center & span
%    xfprintf(f, sprintf(':FREQ:CENT %.15g', center));
%    xfprintf(f, sprintf(':FREQ:SPAN %.15g', span));
    % set the number of points large enough to capture all frequencies
    xfprintf(f, ':SWE:POIN 40001');
    xfprintf(f, ':INST SA');
    xfprintf(f, sprintf(':BWID %g', bw));
    xfprintf(f, ':INIT:CONT OFF');
    xfprintf(f, ':INIT:IMM');
    while (xquery(f, '*OPC?') == 0)
        pause(0.05); % don't hit it too often
    end
    xfprintf(f, ':CALC:MARK1:STAT ON');
    xfprintf(f, ':CALC:MARK1:MODE POS');
    for i = 1:length(tone)
        xfprintf(f, sprintf('CALC:MARK1:X %.15g', tone(i)));
        pause(0.02);
        mag_s = xquery(f, 'CALC:MARK1:Y?');
        mag = sscanf(mag_s, '%g');
        % update the progress bar and break the loop if user has pressed
        % the cancel button
        hWaitBar.update(i/length(tone), sprintf('Tone %d / %d (%s)', i, length(tone), iqengprintf(mag)));
        if (hWaitBar.canceling())
            break;
        end
        list(i) = mag;
        if (list(i) < -100)
            break;
        end
    end
    xfprintf(f, ':CALC:MARK1:STAT OFF');
    % back to continuous sweep mode
    xfprintf(f, sprintf(':FREQ:CENT %s', old_freq));
    xfprintf(f, sprintf(':FREQ:SPAN %s', old_span));
    xfprintf(f, sprintf(':BWID %s', old_bw));
    xfprintf(f, sprintf(':BWID:VID %s', old_vbw));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:RLEV %s', old_ref));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:PDIV %s', old_pdiv));
    xfprintf(f, ':INIT:CONT ON');
end



function list = comp_SingleTone(f, tone, fs, correction, hWaitBar)
    bw = abs(min(diff(tone)) / 2);
    span = 0;
    bw = min(bw, 500e3);
    xfprintf(f, ':INST SA');
    old_freq = xquery(f, ':FREQ:CENT?');
    old_span = xquery(f, ':FREQ:SPAN?');
    old_bw   = xquery(f, ':BWID?');
    old_vbw  = xquery(f, ':BWID:VID?');
    old_ref  = xquery(f, ':DISP:WIND:TRAC:Y:RLEV?');
    old_pdiv = xquery(f, ':DISP:WIND:TRAC:Y:PDIV?');
    xfprintf(f, '*RST');
    xfprintf(f, ':INIT:CONT OFF');
    xfprintf(f, sprintf(':FREQ:SPAN %.15g', span));
    if (span == 0)
        xfprintf(f, sprintf(':BWID %g', bw));
    else
        xfprintf(f, ':BWID:AUTO ON');
    end
    xfprintf(f, ':BWID:VID:AUTO ON');
    xfprintf(f, ':DISP:WIND:TRAC:Y:RLEV 0 dBm');
    xfprintf(f, ':DISP:WIND:TRAC:Y:PDIV 10 dB');
    xfprintf(f, ':CALC:MARK1:STAT ON');
    xfprintf(f, ':CALC:MARK1:MODE POS');
    mmeas = nan(length(tone), 1);
    for i = 1:length(tone)
        % download each tone individually
        sig = iqtone('samplerate', fs, 'tone', tone(i), 'correction', correction);
        iqdownload(sig, fs);
        xfprintf(f, sprintf(':FREQ:CENT %.15g', tone(i)));
        xfprintf(f, ':INIT:IMM');
        while (xquery(f, '*OPC?') == 0)
            pause(0.05); % don't hit it too often
        end
        m1 = getPeak(f);
        % update the progress bar and break the loop if user has pressed
        % the cancel button
        hWaitBar.update(i/length(tone), sprintf('Tone %d / %d (%s)', i, length(tone), iqengprintf(m1)));
        if (hWaitBar.canceling())
            break;
        end
        mmeas(i) = m1;
        if (mmeas < -100)
            break;
        end
    end
    % back to continuous sweep mode
    xfprintf(f, sprintf(':FREQ:CENT %s', old_freq));
    xfprintf(f, sprintf(':FREQ:SPAN %s', old_span));
    xfprintf(f, sprintf(':BWID %s', old_bw));
    xfprintf(f, sprintf(':BWID:VID %s', old_vbw));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:RLEV %s', old_ref));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:PDIV %s', old_pdiv));
    xfprintf(f, ':INIT:CONT ON');
    list = mmeas';
end


%%
function [acs, oldCorr, err] = getOldCorr(arbConfig, tone, chs, recalibrate, usePerChannelCorr)
% get starting values for calibration
% NOTE: asme routine as in iqpowersensor.m - should be unified
err = 1;
oldCorr = zeros(length(tone),1);
[ampCorr, perChannelCorr, acs] = iqcorrection([], 0, 'arbConfig', arbConfig);
if (usePerChannelCorr)
    if (~isempty(perChannelCorr) && (recalibrate || isempty(tone)))
        if (isfield(acs, 'AWGChannels') && ~isempty(acs.AWGChannels))
            chanList = acs.AWGChannels;
        else
            chanList = 1:(size(acs.perChannelCorr, 2) - 1);
        end
        chPos = find(findIndex(chs, chanList), 1);
        if (isempty(chPos))
            errordlg('No previous calibration for any of the current channels. Please uncheck "Apply Correction" and try again.');
            return;
        else
            if (~isempty(setdiff(round(tone), round(perChannelCorr(:,1)))))
                errordlg('No previous calibration exists for those frequency points. Please uncheck "Apply Correction" and try again.');
                return;
            end
            % the channel from which previous cal exists
            ch = chs(chPos);
            % find the index of this channel in the previously calibrated channels
            chPos = find(chanList == ch, 1);
            % find the index of tones in the previous calibration
            tidx = findIndex(tone, perChannelCorr(:,1));
            oldCorr = 20*log10(abs(perChannelCorr(tidx, chPos+1)));
        end
    end
else
    % use ampCorr structure for calibration
    if (~isempty(ampCorr) && (recalibrate || isempty(tone)))
        if (~isequal(ampCorr(:,1), tone))
            errordlg('Frequency points must be identical for re-calibration. Please perform initial calibration first.');
            return;
        end
        oldCorr = ampCorr(:,2);
    end
end
err = 0;
end


%%
function result = updatePerChannelCorr(acs, chs, tone, newCorr)
% update perChannelCorr structure and save updated ampCorr file
% NOTE: same routine as in iqpowersensor.m - should be unified
result = 0;
if (~isfield(acs, 'perChannelCorr') || isempty(acs.perChannelCorr))
    % no perChannelCorr available yet
    acs.AWGChannels = chs;
    perChannelCorr = ones(length(tone),length(chs)+1);
    perChannelCorr(:,1) = tone;
    perChannelCorr(:,2:end) = repmat(10.^(newCorr/20), 1, length(chs));
    acs.perChannelCorr = perChannelCorr;
else
    res = questdlg('Do you want to overwrite the existing correction or merge with the existing correction?', 'Overwrite or Merge', 'Overwrite', 'Merge', 'Cancel', 'Overwrite');
    switch (res)
        case 'Merge'
            if (isfield(acs, 'AWGChannels') && ~isempty(acs.AWGChannels))
                chanList = acs.AWGChannels;
            else
                chanList = 1:(size(acs.perChannelCorr, 2) - 1);
            end
            newChan = union(chs, chanList);
            % create new list of tones. To avoid floating point rounding
            % problems, round frequencies to the closes integer Hz
            newFreq = union(round(acs.perChannelCorr(:,1)), round(tone));
            pc = ones(length(newFreq), length(newChan)+1);
            pc(:,1) = newFreq;
            for chIdx = 1:length(newChan)
                ch = newChan(chIdx);
                if (isempty(find(chs == ch, 1)))
                    % channel is only in acs, not in measurement -> interpolate at measured frequencies
                    chPos = find(chanList == ch, 1);
                    %idx = findIndex(round(acs.perChannelCorr(:,1)), newFreq);
                    pc(:, chIdx+1) = interp1(acs.perChannelCorr(:,1), acs.perChannelCorr(:, chPos+1), newFreq, 'linear', 1);
                elseif (isempty(find(chanList == ch, 1)))
                    % channel is only in measurement, not in acs -> interpolate at measured acs frequencies
                    % idx = findIndex(round(tone), newFreq);
                    pc(:, chIdx+1) = interp1(tone, 10.^(newCorr/20), newFreq, 'linear', 1);
                else
                    % channel is in measurement AND in acs
                    chPos = find(chanList == ch, 1);
                    % copy correction values from acs
                    idx = findIndex(round(acs.perChannelCorr(:,1)), newFreq);
                    pc(idx, chIdx+1) = acs.perChannelCorr(:, chPos+1);
                    % copy (or overwrite) correction values from measurement
                    idx = findIndex(round(tone), newFreq);
                    pc(idx, chIdx+1) = 10.^(newCorr/20);
                end
            end
            acs.AWGChannels = newChan;
            acs.perChannelCorr = pc;
        case 'Overwrite'
            acs.AWGChannels = chs;
            perChannelCorr = ones(length(tone),length(chs)+1);
            perChannelCorr(:,1) = tone;
            perChannelCorr(:,2:end) = repmat(10.^(newCorr/20), 1, length(chs));
            acs.perChannelCorr = perChannelCorr;
        otherwise
            return;
    end
end
save(iqampCorrFilename(), '-struct', 'acs');
result = 1;
end


function res = findIndex(s1, s2)
% return position of elements of s1 in s2
% e.g. findIndex([2 3 4], [6 4 2 1 3 0]) returns [3 5 2]
% if an element of s1 is not in s2, the corresponding index is zero
res = zeros(length(s1),1);
for i = 1:length(s1)
    tmp = find(abs(s2 - s1(i)) < 1, 1);
    if (isempty(tmp))
        res(i) = 0;
    else
        res(i) = tmp;
    end
end
end


