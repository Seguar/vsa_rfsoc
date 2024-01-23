function iseriallarge(arbConfig, dataRate, sps, data, numSymbols, format, fct, filename, correction, tt, scale, gran)
% Generate long PRBSes on M8195A
% if fct = 'download', waveform will be downloaded to the instrument
% if fct = 'save', waveform will be saved as a binary file
% if fct = 'display', waveform will only be calculated and discarded
% Arguments:
% arbConfig - AWG configuration struct (or [] to use default)
% dataRate - data rate in Hz
% sps - samples per symbol
% data - 'PRBS2^xx-1', xx = 11, 23, 31 (or whatever is added below)
% numSymbols - number of symbols
% format can be 'NRZ' or 'PAM4'
% filename - used in conjunction with fct = 'save'
% correction - set to 1 to apply corrections
% tt - transition time in UI (0...1)
% scale - amplitude scaling 
% gran - granularity

% T.Dippon, Keysight Technologies 2015-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

% use default AWG config if not specified
if (isempty(arbConfig))
    arbConfig = loadArbConfig();
end
fs = sps * dataRate;    % sample rate
switch (lower(data))
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
    case 'prbs2^23-1'
        prbsPoly = [23 5 0];
    case 'prbs2^31-1'
        prbsPoly = [31 3 0];
    otherwise
        errordlg(['unsupported PRBS: ' data]);
        return;
end
if (strcmp(format, 'PAM4'))
    pam4 = 1;
else
    pam4 = 0;
end
chunkSize = 600000;     % number of symbols processed at a time
FIRsize = [];           % size of correction filter
%
if (isempty(numSymbols))
    numSymbols = 2^prbsPoly(1)-1;
end
numSamples = round(numSymbols * sps / gran) * gran;     % round samples to multiple of granularity
sps = numSamples / numSymbols;                          % samples per symbol
s2w = sym2wfm(sps, tt);
% commsrc.pn is no longer supported in MATLAB...
%prbs = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', (pam4+1) * chunkSize);
prbs = comm.PNSequence('Polynomial', prbsPoly, 'InitialConditions', [zeros(1,prbsPoly(1)-1), 1], 'SamplesPerFrame', (pam4+1) * chunkSize);
[~, perChannelCorr] = iqcorrection([]);                 % default correction
if (~isempty(perChannelCorr))
    h = overlapsave.makeFIR(fs, perChannelCorr(:,1), perChannelCorr(:,2), FIRsize);
    ovs = overlapsave(h);                                   % create filter object
else
    correction = 0;
end
sampleCnt = 0;
oldWfm = [];
maxVal = 1;
switch (fct)
    case 'download'
        % don't use iqdownload to reduce overhead
        f = iqopen(arbConfig);
        if (isempty(f))
            return;
        end
        chan = 1;
        segm_num = 1;
        fsDivider = 1;
        xfprintf(f, sprintf('*CLS'));
        xfprintf(f, sprintf(':ABORt'));
        xfprintf(f, sprintf(':INST:DACM SING;:TRAC1:MMOD EXT;:INST:MEM:EXT:RDIV DIV1'));
        xfprintf(f, sprintf(':FREQuency:RASTer %.15g;', fs * fsDivider));
        xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
        xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, numSamples));
    case 'save'
        if (isempty(filename))
            [FileName,PathName,~] = uiputfile({...
                '.bin', 'BIN file (*.bin)'; ...
                '.pbin12', '12-bit packed binary (*.pbin12)'; ...
                }, 'Save Waveform As...');
            if (FileName == 0)
                return;
            end
            filename = fullfile(PathName, FileName);
        end
        f = fopen(filename, 'w');
        if (isempty(f))
            return;
        end
    case 'display'
end
tic;
hMsgBox = waitbar(0, '', 'Name', 'Please wait...', 'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
map = [0 1/3 1 2/3];
while (sampleCnt < numSamples)
    data = prbs.step();
    if (pam4)
       data = map(data(1:2:end)'+2*data(2:2:end)'+1);
    end
    wfm1 = s2w.convert(data);                   % uncorrected waveform
    if (correction)
        wfm2 = [oldWfm; ovs.filter(wfm1)];          % corrected waveform
    else
        wfm2 = [oldWfm; wfm1];
    end
    len = floor(length(wfm2) / gran) * gran;    % use in chunks of granularity
    len = min(len, numSamples - sampleCnt);     % no more than numSamples
    oldWfm = wfm2(len+1:end);                   % save last part for next loop iteration
    wfm2 = wfm2(1:len);
    switch (fct)
        case 'download'
            maxVal = max(maxVal, max(abs(wfm2)));
            if (scale > 1/maxVal)
                msgbox(sprintf('Scale value is too large, causing DAC range overflow. Please reduce "normalized amplitude" value to less than %.3g', 1/maxVal));
                break;
            end
            dacData = int8(round(127 * scale * wfm2));
            cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, sampleCnt);
            xbinblockwrite(f, dacData, 'int8', cmd);
        case 'save'
            maxVal = max(maxVal, max(abs(wfm2)));
            if (scale > 1/maxVal)
                msgbox(sprintf('Scale value is too large, causing DAC range overflow. Please reduce "normalized amplitude" value to less than %.3g', 1/maxVal));
                break;
            end
            if (~isempty(strfind(filename, '.pbin12')))
                a1 = scale * real(wfm2);
                % convert to 12 bit values
                data1 = bitand(4095, int32(round(2047 * a1)));
                % split into 2 rows of 12-bit values
                data1 = reshape(data1, 2, length(data1)/2);
                % combine into vector of 24-bit values
                data2 = bitor(data1(1,:), bitshift(data1(2,:), 12));
                % split into 3 rows of 8-bit values
                data3 = uint8([bitand(data2, 255); bitand(bitshift(data2, -8), 255); bitshift(data2, -16)]);
                % comvert to a single 8-bit vector
                data3 = data3(1:end);
                fwrite(f, data3, 'uint8');
            else
                dacData = int8(round(127 * scale * wfm2));
                fwrite(f, dacData, 'int8');
            end
        case 'display'
    end
    sampleCnt = sampleCnt + len;
    t = toc;
    if getappdata(hMsgBox,'canceling'); break; end
    waitbar(sampleCnt / numSamples, hMsgBox, sprintf('%d samples, %.1f%%, %.1f sec', sampleCnt, sampleCnt / numSamples * 100, t));
end
switch (fct)
    case 'download'
        xquery(f, '*OPC?');
        xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
        xfprintf(f, sprintf(':OUTP%d ON', chan));
        xfprintf(f, sprintf(':INIT:IMM'));
%        xquery(f, ':SYST:ERR?')
        iqclose(f);
        fprintf('scale %g, optimal scale %g\n', scale, 1/maxVal);
    case 'save'
        fclose(f);
        fprintf('scale %g, optimal scale %g\n', scale, 1/maxVal);
    case 'display'
        len = min(1000, length(wfm2));
        iqplot(wfm2(1:len), fs);
        figure(1);
        title('Note: Partial waveform displayed only');
end
delete(hMsgBox);
% fprintf('processed %10d samples, %7.1f sec\n', numSamples, t);

