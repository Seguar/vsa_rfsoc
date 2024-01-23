function result = iqdownload_M8199A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence, run)
% Download a waveform to the M8199A
% It is NOT intended that this function be called directly, only via iqdownload
%
% B.Krueger, Th.Dippon, Keysight Technologies 2020
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    global lastFs;
    global gData;
    if (isempty(gData))
        gData = cell(0);
    end
    result = [];
    if (~isempty(sequence))
        errordlg('Sorry, M8199A does not have a sequencer!');
        return;
    end
    
    % open the VISA connection
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    result = f;
    
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
    
    
    %% find out if we are in non-interleaved or interleaved mode
    try
        ilvModeM8070 = str2double(xquery(f, sprintf(':SYST:INST:ILVMode? "%s.System"', arbConfig.M8070ModuleID)));
    catch ex
        iqreset();
        error(['Can not communicate with M8070B. Please try again. ' ...
            'If this does not solve the problem, exit and restart MATLAB. ' ...
            '(Error message: ' ex.message ')']);
    end
    ilvMode = strcmp(arbConfig.model, 'M8199A_ILV');
    
    % later on, we'll treat this as an error. For now, let's ignore and use
    % ilvModeM8070
    if (ilvMode && ~ilvModeM8070)
        fprintf('ILV mode mismatch:  IQtools - %d,  M8070 - %d\n', ilvMode, ilvModeM8070);
    end

    % find out if we are working with a clock module and which identifiers
    % to use to set the sample rate
    [isCMpresent, freqCmd, clkModuleID, clkIdentifier] = getClkCommands(f, arbConfig);
    
    % check if auto-cal is necessary and run it if necessary - only if CM is present
    if (isCMpresent)
        checkAndRunAutoCal(arbConfig, f, fs, run, swVersion, ilvModeM8070);
    end
    
    % handle "special" interleave mode:  IQtools operates in non-ILV mode and M8070 operate in ILV mode.
    % This mode is used to measure interleave skew.
    % Procedure: Interleave the data here and module driver will de-interleave again
    if (~ilvMode && ilvModeM8070)
        fs = 2 * fs;                     % pretend double clock for M8070
        ilvMode = 1;                     % pretend we are in interleave mode
        arbConfig.model = 'M8199A_ILV';  % pretend we are in interleave mode
        % adjust the rate for the sample marker
        if (isfield(arbConfig, 'sampleMarker') && strncmpi(arbConfig.sampleMarker, 'Sample rate / ', 14))
            arbConfig.sampleMarker = sprintf('Sample rate / %d', str2double(arbConfig.sampleMarker(15:end)) * 2);
        end
        % remember data to download per channel
        for i = 1:size(chMap, 1)
            if (~isempty(find(chMap(i,:), 1)))  % check, if this sub-channel receives data
                gData{i} = getData(data, i, chMap);
            end
        end
        k = 1;
        ilvCh = 1;
        newData = zeros(2*size(data,1),1);
        newChMap = zeros(floor(size(chMap,1)/2),2);
        % find channels with "complete" data for both sub-channels and download
        for i = 1:size(chMap, 1)
            if (mod(i-1,4) >= 2)    % skip the secondary channels
                continue;
            end
            % consider download if at least one of the sub-channels is accessed in the current download
            % AND we have data for both sub-channels AND the length of the two data vectors is the same
            if ((~isempty(find(chMap(i,:), 1)) || ~isempty(find(chMap(i+2,:), 1))) && ...
                    length(gData) >= i+2 && ...
                    length(gData{i+2}) == size(data,1) && ...
                    length(gData{i}) == size(data,1))
                tmp = [gData{i}'; gData{i+2}'];   % interleave data from two sub-channels
                newData(:,k) = tmp(1:end);
                newChMap(ilvCh, 2*k-1) = 1;
                newChMap(ilvCh, 2*k) = 0;
                k = k + 1;
            end
            ilvCh = ilvCh + 1;
        end
        data = newData;
        chMap = newChMap;
    end
    
    % allow overprogramming, but set M8070 sample rate no higher than 128 resp. 256 GSa/s
    if (ilvModeM8070)
        fsClk = fs/4;
        fsM8070 = min(fs, 256e9);
    else
        fsClk = fs/2;
        fsM8070 = min(fs, 128e9);
    end
    
    % find out if the sample rate has changed - only on primary module
    fsChanged = 0;
    if (~isfield(arbConfig, 'setupSecondary'))
        fsQry = str2double(xquery(f, sprintf('%s? "%s.%s"', freqCmd, clkModuleID, clkIdentifier)));
        % check if we have a new samplerate
        if (fs ~= 0 && (abs(fsM8070 - fsQry)/fsQry > 1e-13))
            fsChanged = 1;
            fprintf('sample rate changed: %s -> %s\n', iqengprintf(fsQry,15), iqengprintf(fsM8070,15));
            lastFs = fs;
        end
    end
    
    % if Fs is unchanged, stop waveform generation on data channels only (leave Markers running)
    % if Fs is changed, stop channels and marker
    % Starting the right set of channels seems very complicated, so for the
    % time being, simply stop all channels
%    if (fsChanged)
        res = xfprintf(f, sprintf(':ABORT "%s"', arbConfig.M8070ModuleID));
%     else
%         res = xfprintf(f, sprintf(':ABORT "%s",15', arbConfig.M8070ModuleID));
%     end
    % if the ABORT command fails, don't try anything else to avoid tons of error messages
    if (res)
        return;
    end

    % perform instrument reset if it is selected in the configuration
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        if (sum(sum(chMap)) > 0 && (isempty(find(chMap(:,1), 1)) || isempty(find(chMap(:,2), 1))))
            warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                'waveform to only one channel. This will delete the waveform on the' ...
                'other channel. If you want to keep the previous waveform, please' ...
                'un-check the "send *RST" checkbox in the Configuration window.'});
        end
        if (xfprintf(f, '*RST') ~= 0)
            return;
        end
    end
    
    % determine the number of channels per module
    if (ilvModeM8070)
        cpm = 2;
    else
        cpm = 4;
    end
    syncSystem = 0;
    % download to the secondary modules by calling the routine recursively
    for m = 2:4
        va = sprintf('M8070ModuleID%d', m);
        if (size(chMap, 1) > cpm*(m-1) && isfield(arbConfig, va))
            syncSystem = 1;
            arbTmp = arbConfig;
            arbTmp.M8070ModuleID = arbTmp.(va);
            arbTmp.setupSecondary = 1;
            chIdx = find(arbConfig.channelMask);
            if (isfield(arbConfig, 'amplitude'))
                tmp = zeros(1, length(arbConfig.channelMask));
                tmp(chIdx) = fixlength(arbConfig.amplitude, length(chIdx));
                arbTmp.amplitude = tmp(cpm*(m-1)+1:min(cpm*m,size(chMap,1)));
            end
            if (isfield(arbConfig, 'offset'))
                tmp = zeros(1, length(arbConfig.channelMask));
                tmp(chIdx) = fixlength(arbConfig.offset, length(chIdx));
                arbTmp.offset = tmp(cpm*(m-1)+1:min(cpm*m,size(chMap,1)));
            end
            if (isfield(arbConfig, 'peaking') && ~isempty(arbConfig.peaking))
                tmp = zeros(1, length(arbConfig.channelMask));
                tmp(chIdx) = fixlength(arbConfig.peaking, length(chIdx));
                arbTmp.peaking = tmp(cpm*(m-1)+1:cpm*m);
            end
            result = iqdownload_M8199A(arbTmp, fs, data, marker1, marker2, segmNum, keepOpen, chMap(cpm*(m-1)+1:min(cpm*m,size(chMap,1)),:), sequence, run);
        end
    end
    % don't try to download more than <cpm> channels in an given module
    chMap(cpm+1:end,:) = [];
    
    % find out how many channels are licensed, don't donwload anything to
    % an unlicensed channel to avoid error messages
    if (isfield(info, 'Options'))
        % if option 004 is not available, it must be a 2-channel unit
        if isempty(info.Options) || isempty(find(contains(info.Options, '004'), 1))
            if (ilvModeM8070)
                chMap(2:end,:) = [];  % leave channel 1, clear out everything else
            else
                chMap(4:end,:) = [];  % leave channels 1 & 3, clear out everything else
                chMap(2,:) = zeros(1,size(chMap,2));
            end
        end
    end
    
    % check if PSG frequency needs to be updated
    if (fs ~= 0 && ~isfield(arbConfig, 'setupSecondary') && ...
            isfield(arbConfig, 'isPSGConnected') && arbConfig.isPSGConnected ~= 0 && isfield(arbConfig, 'visaAddrPSG'))
        fPSG = iqopen(arbConfig.visaAddrPSG);
        if (isempty(fPSG))
            return;
        end
        try
            fsPSG = str2double(xquery(fPSG, ':FREQ?'));
            if (abs(fsClk - fsPSG)/fsPSG > 1e-13)
                xfprintf(fPSG, sprintf(':FREQ %.15g', fsClk));
            end
            if (fsClk >= 60e9)
                power = 11;
            elseif (fsClk <= 50e9)
                power = 7;
            else
                power = (fsClk-50e9)/(60e9-50e9)*(11-7)+7;
            end
            if (syncSystem) % compensate the insertion loss of the power splitter
                power = power + 6;
            end
            xfprintf(fPSG, sprintf(':POW %.2g', power));
            xfprintf(fPSG, sprintf(':OUTP 1'));     % turn output on
            xquery(fPSG, '*OPC?');
            xquery(fPSG, ':OUTP:SETT?');
            iqclose(fPSG);
        catch
            errordlg('Cannot communicate with PSG - please double check the connection'); 
        end
    end
    
    % set the sample rate except in secondary modules
    if (fs ~= 0 && ~isfield(arbConfig, 'setupSecondary'))
        if (fsChanged)
            xfprintf(f, sprintf('%s "%s.%s",%.15g', freqCmd, clkModuleID, clkIdentifier, fsM8070));
        end
        if (isCMpresent)
            xfprintf(f, sprintf(':OUTP:STAT "%s.RefClkOut16G",1', clkModuleID));
        end
    end
    
    % turn secondary modules
    % (do it in version 1.1, but not in 1.2.  Do it in 1.3, but only if there is no clock module)
    if (isfield(arbConfig, 'setupSecondary') && ...
            ((swVersion >= 1001000 && swVersion < 1002000) || (swVersion >= 1003000 && ~isCMpresent)))
        xfprintf(f, sprintf(':SYST:COUP:FOLL "%s.System",1', arbConfig.M8070ModuleID));
    end
    
    if (strcmp(arbConfig.model, 'M8199A_ILV') && swVersion <= 1000)
        % Interleaved waveform download --> split even and odd samples here.
        % ONLY if software version is 0.1.xxx.  For 0.2.xxx and higher, use
        % the same method as for non-interleaved channels
        for col = 1:size(chMap, 2) / 2
            for ch = find(chMap(:, 2*col-1))'
                tmp = real(data(:,col));
                gen_arb_M8199A(arbConfig, f, ch+2, tmp(2:2:end), segmNum, run, ilvModeM8070, swVersion);
                gen_arb_M8199A(arbConfig, f, ch+0, tmp(1:2:end), segmNum, run, ilvModeM8070, swVersion);
            end
            for ch = find(chMap(:, 2*col))'
                tmp = imag(data(:,col));
                gen_arb_M8199A(arbConfig, f, ch+2, tmp(2:2:end), segmNum, run, ilvModeM8070, swVersion);
                gen_arb_M8199A(arbConfig, f, ch+0, tmp(1:2:end), segmNum, run, ilvModeM8070, swVersion);
            end
        end
    else
        % Non-interleaved waveform download
        for col = 1:size(chMap, 2) / 2
            for ch = find(chMap(:, 2*col-1))'
                gen_arb_M8199A(arbConfig, f, ch, real(data(:,col)), segmNum, run, ilvModeM8070, swVersion);
            end
            for ch = find(chMap(:, 2*col))'
                gen_arb_M8199A(arbConfig, f, ch, imag(data(:,col)), segmNum, run, ilvModeM8070, swVersion);
            end
        end
    end
        
    % if the user selected a certain clock pattern for the sample marker in
    % the instrument configuration window, it takes precedence over the
    % marker information passed to the download routine
    if (isfield(arbConfig, 'sampleMarker'))
        len = size(data,1);
        if (contains(arbConfig.sampleMarker, 'Once'))
            marker1 = [ones(len/2,1); zeros(len/2,1)];
        elseif (contains(arbConfig.sampleMarker, 'unchanged'))
            marker1 = [];
        elseif (contains(arbConfig.sampleMarker, '/'))
            len = 512;
            div = str2double(arbConfig.sampleMarker(strfind(arbConfig.sampleMarker,'/')+1:end));
            if (mod(len, div) ~= 0)
                warndlg('Marker pattern is not periodic');
            end
            marker1 = repmat([ones(div/2,1); zeros(div/2,1)], ceil(len/div), 1);
            marker1 = marker1(1:end);
        end
    end
    if (~isempty(marker1))
        if (strcmp(arbConfig.model, 'M8199A_ILV'))
            downloadMarker(arbConfig, f, marker1(1:2:end));
        else
            downloadMarker(arbConfig, f, marker1);
        end
    end
    
    maxRetry = 5;
    if (run == 1)
        % New SW: Send :INIT:IMM only to the primary module
        if (~isfield(arbConfig, 'setupSecondary') || swVersion < 1001000)
            retryCnt = 1;
            while retryCnt < maxRetry
                if (syncSystem && swVersion >= 1001000 && swVersion < 1002061)
                    % ARM all modules
                    arbConfig.M8070ModuleID1 = arbConfig.M8070ModuleID;
                    for m = 1:4
                        va = sprintf('M8070ModuleID%d', m);
                        if (isfield(arbConfig, va))
                            xfprintf(f, sprintf(':INIT:IMM:ARM "%s"', arbConfig.(va)));
                        end
                    end
                end
                cmd = sprintf(':INIT:IMM "%s"', arbConfig.M8070ModuleID);
                [retVal, retStr] = xfprintf(f, cmd, 1);
                % if :INIT:IMM fails, try to stop/arm/start again. As far as I
                % know, there are two cases when this can happen:
                % a) in multi-module operation, the seconday module does not start
                % b) start/stop of only the data channels does not work and
                %    we have to restart everything (incl. Sample Marker)
                if (retVal ~= 0)
                    if (contains(retStr, 'MCLK PLL'))
                        error(sprintf('%s\n%s\nPlease verify that the AWG module is supplied with a sample clock signal with sufficient amplitude\n', cmd, retStr));
                    end
                    if (retryCnt <= 1)
                        % for now, display a warning - this can be taken out later
                        warndlg(sprintf('%s\n%s - retrying (%d)', cmd, retStr, retryCnt), 'Warning');
                    end
                    % :ABORT all modules
                    arbConfig.M8070ModuleID1 = arbConfig.M8070ModuleID;
                    for m = 1:4
                        va = sprintf('M8070ModuleID%d', m);
                        if (isfield(arbConfig, va))
                            xfprintf(f, sprintf(':ABORT "%s"', arbConfig.(va)));
                        end
                    end
                    retryCnt = retryCnt + 1;
                else
                    break;
                end
            end
            if (retryCnt >= maxRetry)
                error(retStr);
            end
            % check that the system is actually running
            checkRunning(f, arbConfig, swVersion);
        end % setupSecondary
        if (~isfield(arbConfig, 'setupSecondary'))
            % Turn global output on.
            % TBD: find out which moduleID to use. For now, simply hardcoded...
            globalOutputModuleID = 'M1';
            xfprintf(f, sprintf(':OUTP:GLOB "%s.System",1', globalOutputModuleID));
        end
    end
    
    if (~isfield(arbConfig, 'setupSecondary') && (~exist('keepOpen', 'var') || keepOpen == 0))
        iqclose(f);
    end
end


function [isCMpresent, freqCmd, clkModuleID, clkIdentifier] = getClkCommands(f, arbConfig)
    % determine where to send the :FREQ:RAST command to
    identifiers = xquery(f, sprintf(':SYST:INF:IDEN?'));
    if (contains(identifiers, 'M1.RefClkOut'))
        % clock module in the system
        isCMpresent = true;
        clkModuleID = 'M1';
        freqCmd = ':FREQ';
    else
        % no clock module
        isCMpresent = false;
        clkModuleID = arbConfig.M8070ModuleID;
        freqCmd = ':FREQ:RAST';
    end
    
    % determine which clock identifier to use
    if (contains(identifiers, sprintf('%s.ClkGen', clkModuleID)))
        clkIdentifier = 'ClkGen';
    else
        clkIdentifier = 'ClkIn';
    end
end


function checkRunning(f, arbConfig, swVersion, hMsg, pStart, pWidth)
% Wait until the AWG is truly running.  Just waiting for the return of :INIT:IMM is NOT sufficient.
if (swVersion >= 1002052)
    if (~exist('hMsg', 'var'))
        hMsg = [];
        pStart = 0;
        pWidth = 1;
    end
    retryCnt = 0;
    maxRetry = 50;
    res = str2double(xquery(f, sprintf(':STAT:INST:RUN? "%s.SampleMrk"', arbConfig.M8070ModuleID)));
    while (res ~= 1 && retryCnt < maxRetry)
        pause(1);
        res = str2double(xquery(f, sprintf(':STAT:INST:RUN? "%s.SampleMrk"', arbConfig.M8070ModuleID)));
        retryCnt = retryCnt + 1;
        if (isempty(hMsg))
            if (retryCnt >= 1)
                hMsg = iqwaitbar('Starting signal generation - please wait');
            end
        else
            if (hMsg.canceling())
                return;
            end
            hMsg.update(pStart + (retryCnt / maxRetry) * pWidth);
        end
    end
    if (retryCnt >= maxRetry)
        retStr = 'Timeout while starting signal generation on M8199A. Please double check that the clock and sync signals are properly connected.';
        error(retStr);
    end
end
end


function checkAndRunAutoCal(arbConfig, f, fs, run, swVersion, ilvModeM8070)
% check if autoCal is needed and execute it if necessary
    if (fs ~= 0 && run ~= 0 && swVersion >= 1002075 && ~isfield(arbConfig, 'autoCalInProgress') && ~isfield(arbConfig, 'setupSecondary'))
        % check if AutoCal is required for any of the AWG modules
        IDlist = { '', '2', '3', '4' }; % referring to arbConfig.M8070ModuleID%s
        autoCalList = {};               % list of module IDs that require calibration
        for i = 1:length(IDlist)
            va = sprintf('M8070ModuleID%s', IDlist{i});
            if (isfield(arbConfig, va))
                moduleID = arbConfig.(va);
                if (checkAutoCalForModule(f, moduleID))
                    autoCalList{end+1} = moduleID;
                end
            end
        end
        % if we need autoCal on at least one module, we have to do it...
        if (~isempty(autoCalList))
            % pick a frequency somewhere in the middle of the valid range
            fs = 114.12345e9;
            fsBase = fs;
            if (ilvModeM8070) % Sample rate value for programming M8070
                fs = 2*fs;
            end
            % load a dummy waveform into all channels and run
            data = zeros(512,1);
            chMap = [arbConfig.channelMask', zeros(length(arbConfig.channelMask), 1)];
            % make sure we don't run into a recursive loop
            arbConfig.autoCalInProgress = 1;
            iqdownload_M8199A(arbConfig, fs, data, [], [], 1, 1, chMap, [], 1);
            % now execute the autoCal procedure
            numRepeat = 10;
            mStr = sprintf('%s, ', autoCalList{:});
            hMsg = iqwaitbar(sprintf(['M8199A module(s) %s need a one-time internal skew alignment threshold calibration.\n' ...
                'This will take about %d minutes. No external equipment or user interaction is required.\n' ...
                'Please wait...\n'], mStr(1:end-2), ceil(numRepeat/2)));
            % delete the whole cal table before making the measurement
            for k = 1:length(autoCalList)
                xfprintf(f, sprintf(':CAL:TABL:DEL "%s.System","User.skewAlignmentThreshold"', autoCalList{k}));
            end
            % array to store the measurement results.  Dim1 = measurement, Dim2 = channel, Dim3 = module
            resList = NaN(numRepeat, 3, length(autoCalList));
            [isCMpresent, freqCmd, clkModuleID, clkIdentifier] = getClkCommands(f, arbConfig);
            for i = 1:numRepeat
                fs = fs + 1e4;
                xfprintf(f, sprintf('%s "%s.%s",%.15g', freqCmd, clkModuleID, clkIdentifier, fs));
                checkRunning(f, arbConfig, swVersion, hMsg, i/(numRepeat+2), 1/(numRepeat+2));
                if (hMsg.canceling())
                    error('skew alignment calibration aborted');
                end
                for k = 1:length(autoCalList)
                    resStr = xquery(f, sprintf(':CAL:MEAS:RES? "%s.System","skewAlignmentThreshold"', autoCalList{k}));
                    errStr = xquery(f, ':SYST:ERR?');
                    res = sscanf(strrep(strrep(resStr, '"', ''), ',', ' '), '%g');
                    if (length(res) ~= 12 || sscanf(errStr, '%d') ~= 0)
                        error('Error during skew alignment threshold calibration. Number of returned results is %d, expected 12', length(res))
                    end
                    resList(i, :, k) = res(5) - res(6:8);
                end
            end
            skewList = zeros(size(resList,2), length(autoCalList));
            for k = 1:length(autoCalList)
                skewList(:,k) = calculateSkewThresholds(resList(:,:,k), fsBase);
                skewListStr = sprintf(',%g', skewList(:,k));
                skewListStr = skewListStr(2:end);  % remote the initial comma
                % sanity check to make sure that the values are reasonable
                % and not all the same value (e.g. 0,0,0)
                if (min(skewList(:,k)) == max(skewList(:,k)))
                    errordlg(sprintf(['An error occurred during the skew alignment threshold calibration. ' ...
                        'Please download another waveform to trigger the skew alignment threshold calibration again. ' ...
                        '(module %s, skewList %s)'], autoCalList{k}, skewListStr));
                    break;
                end
                cmd = sprintf(':CAL:TABL:DATA "%s.System","User.skewAlignmentThreshold","%s"', autoCalList{k}, skewListStr);
                fprintf('Skew Alignment %s\n', cmd);
                xfprintf(f, cmd);
            end
            % save the results of the skew alignment cal for debugging
            % purposes.  Ignore any errors in the process...
            try
                file = fullfile(iqScratchDir(), 'iqSkewAlign.mat');
                clear cal;
                cal.version = 1;
                cal.timeStamp = datetime();
                cal.moduleList = autoCalList;
                cal.rawData = resList;
                cal.skewResults = skewList;
                try 
                    % if the file exists, append new cal data
                    fstr = load(file);
                    fstr.cal(end+1) = cal;
                catch
                    % else start with this one
                    fstr.cal = cal;
                end
                save(file, '-struct', 'fstr');
            catch
            end
        end
    end
end


function autoCal = checkAutoCalForModule(f, moduleID)
% check, if AutoCal is necessary for a certain moduleID
autoCal = 0;
res = xquery(f, sprintf(':CAL:TABL:VALID? "%s.System","Factory.skewAlignmentThreshold"', moduleID));
if (contains(res, 'uncalibrated', 'IgnoreCase', true))
    res = xquery(f, sprintf(':CAL:TABL:VALID? "%s.System","User.skewAlignmentThreshold"', moduleID));
    if (contains(res, 'uncalibrated', 'IgnoreCase', true))
        autoCal = 1;
    end
end
end


function result = calculateSkewThresholds(resList, fs)
result = zeros(1,size(resList,2));
resList = resList - round(resList * fs) / fs;
for i = 1:size(resList,2)
    if (max(resList(:,i)) - min(resList(:,i)) >= 0.5 / fs)
        % if values are not "close together" move values up or down by one
        % sample period
        if (length(find(resList(:,i) >= 0)) > length(find(resList(:,i) < 0)))
            % more positive than negative values
            resList(resList(:,i) < 0, i) = resList(resList(:,i) < 0, i) + 1 / fs;
        else
            % more negative than positive values
            resList(resList(:,i) >= 0, i) = resList(resList(:,i) >= 0, i) - 1 / fs;
        end
    end
    % plausibility check
    if (max(resList(:,i)) - min(resList(:,i)) >= 0.5 / fs)
        s = sprintf(' %.3g', resList(:,i)*fs);
        error(sprintf(['Alignment calibration failed. Please try again. ' ...
            'If the calibration still fails, please contact Keysight support. \n\n' ...
            '(min/max delay readings span more than 0.5 * sample clock period, ch %d:%s)'], i, s));
    end
    result(i) = sum(resList(:,i)) / size(resList,1);
end
end
% private bool EvaluateChannelAlignmentResults(IReadOnlyList<double> deltaDelayReadings, out double targetDeltaDelay)
% {
%     targetDeltaDelay = double.NaN;
% 
%     // "unwrap" delay readings (to get positive/negative values closest to zero)
%     List<double> unwrappedDeltaDelayReadings = new List<double>(deltaDelayReadings.Select(d => d - Math.Round(d * SampleClockRate, 0, MidpointRounding.AwayFromZero) / SampleClockRate));
% 
%     if ((unwrappedDeltaDelayReadings.Max() - unwrappedDeltaDelayReadings.Min()) < 0.5 / SampleClockRate)
%         targetDeltaDelay = unwrappedDeltaDelayReadings.Average();
%     else    // 2 (remaining) zones (slightly above/below 50% sample clock period limits)
%     {
%         // "unwrap" delay readings again by shifting positive/negative delta delay readings towards zone with higher accumulation
%         int numberOfPositiveReadings = unwrappedDeltaDelayReadings.Count(d => d >= 0.0);
%         int numberOfNegativeReadings = unwrappedDeltaDelayReadings.Count(d => d < 0.0);
% 
%         if (numberOfPositiveReadings >= numberOfNegativeReadings)
%         {
%             // add one sample clock period to negative delay readings
%             unwrappedDeltaDelayReadings = unwrappedDeltaDelayReadings.Select(d => (d >= 0.0 ? d : (d + 1.0 / SampleClockRate))).ToList();
%         }
%         else
%         {
%             // subtract one sample clock period from positive delay readings
%             unwrappedDeltaDelayReadings = unwrappedDeltaDelayReadings.Select(d => (d >= 0.0 ? (d - 1.0 / SampleClockRate) : d)).ToList();
%         }
% 
%         // check plausibility
%         if ((unwrappedDeltaDelayReadings.Max() - unwrappedDeltaDelayReadings.Min()) >= 0.5 / SampleClockRate)
%         {
%             Log(LogSeverityType.Critical, $"Failed to evaluate histogram: (Unwrapped) min/max delay readings span more than 0.5 * period of sample clock rate '{BFNumber.ToFormattedNumberString(SampleClockRate)}Sa/s'");
%             Log(LogSeverityType.Critical, $"Unwrapped delay readings {string.Join(", ", unwrappedDeltaDelayReadings)}");
%             return false;
%         }
%     }
% 
%     return true;
% }



function gen_arb_M8199A(arbConfig, f, chan, data, segm_num, run, ilvModeM8070, swVersion)
% download an arbitrary waveform signal to a given channel
    if (isempty(chan) || ~chan)
        return;
    end
    segmentOffset = 0;
    moduleId = arbConfig.M8070ModuleID;
    chanStr = [moduleId '.DataOut' num2str(chan)];
%     fprintf('%s: ', chanStr);
%     fprintf('%4d', round(127*data(1:24)));
%     fprintf('\n');
    segm_len = length(data);
    % Try to delete the segment, but ignore errors if it does not exist
    % Another approach would be to first find out if it exists and only
    % then delete it, but that takes much longer
    if (run >= 0 && segmentOffset == 0)
        xfprintf(f, sprintf(':TRAC:DEL "%s",%d', chanStr, segm_num), 1);
        if (xfprintf(f, sprintf(':TRAC:DEF "%s",%d,%d', chanStr, segm_num, segm_len)))
            return;
        end
    end
    if (segm_len > 0)        
        % scale to DAC values and shift negative values (data is assumed to be -1 ... +1)
        dataSize = 'int8';
        data = int8(round(127 * data));

        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 512000);
                cmd = sprintf(':TRACe:DATA "%s",%d,%d,', chanStr, segm_num, offset + segmentOffset);
                xbinblockwrite(f, data(1+offset:offset+len), dataSize, cmd);
            else
                len = min(segm_len - offset, 5120);
                cmd = sprintf(':TRACe:DATA "%s",%d,%d', chanStr, segm_num, offset + segmentOffset);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        xquery(f, '*OPC?');
        if (~ilvModeM8070 || chan <= 2)
            if (isfield(arbConfig, 'skew'))
                tmp = fixlength(arbConfig.skew, chan);
                xfprintf(f, sprintf(':ARM:DEL "%s",%g', chanStr, tmp(chan)));
            end
            if (isfield(arbConfig, 'ampType'))
                cpl = xquery(f, sprintf(':OUTP:COUP? "%s"', chanStr));
                if (~strncmpi(cpl, arbConfig.ampType, 2))
                    xfprintf(f, sprintf(':OUTP "%s",0', chanStr));
                    xfprintf(f, sprintf(':OUTP:COUP "%s",%s', chanStr, arbConfig.ampType));
                end
            end
            if (isfield(arbConfig, 'amplitude'))
                tmp = fixlength(arbConfig.amplitude, chan);
                xfprintf(f, sprintf(':VOLT:AMPL "%s",%g', chanStr, tmp(chan)));
            end
            if (isfield(arbConfig, 'offset'))
                cpl = xquery(f, sprintf(':OUTP:COUP? "%s"', chanStr));
                if (contains(cpl, 'DC'))
                    tmp = fixlength(arbConfig.offset, chan);
                    xfprintf(f, sprintf(':VOLT:OFFS "%s",%g', chanStr, tmp(chan)));
                end
            end
        end
% set peaking
        if (isfield(arbConfig, 'peaking') && ~isempty(arbConfig.peaking) && swVersion >= 1001000)
            tmp = fixlength(arbConfig.peaking, chan);
            [retVal, retStr] = xfprintf(f, sprintf(':OUTP:VPCorr "%s",%g', chanStr, tmp(chan)), 1);
            if (retVal ~= 0 && ~contains(retStr, 'cannot be modified'))
                xfprintf(f, sprintf(':OUTP:VPCorr "%s",%g', chanStr, tmp(chan)));
            end
        end
        if (~ilvModeM8070 || chan <= 2)
            xfprintf(f, sprintf(':OUTP "%s",1', chanStr));
        end
    end
end


function downloadMarker(arbConfig, f, marker)
    moduleId = arbConfig.M8070ModuleID;
    chanStr{1} = [moduleId '.SampleMrk'];
    chanStr{2} = [moduleId '.SyncMrkA'];
    chanStr{3} = [moduleId '.SyncMrkB'];
    segm_len = length(marker);
    segm_num = 1;
    if (evalin('base', 'exist(''debugMrk'', ''var'')'))
        fprintf('%s %s: ', arbConfig.model, chanStr{1});
        for i = 1:80
            fprintf('%d', marker(i));
        end
        fprintf('\n');
    end
    if (segm_len > 0)        
        for k = 1:3 
            if k == 1 || max(marker) > 1
                xfprintf(f, sprintf(':TRAC:DEL "%s",%d', chanStr{k}, segm_num), 1);
                if (xfprintf(f, sprintf(':TRAC:DEF "%s",%d,%d', chanStr{k}, segm_num, segm_len)))
                    return
                end
                dataSize = 'uint8';
                data = bitshift(bitand(uint8(marker),2^(k-1)),-(k-1)); 
                use_binblockwrite = 1;
                offset = 0;
                while (offset < segm_len)
                    if (use_binblockwrite)
                        len = min(segm_len - offset, 512000);
                        cmd = sprintf(':TRACe:DATA "%s",%d,%d,', chanStr{k}, segm_num, offset);
                        xbinblockwrite(f, data(1+offset:offset+len), dataSize, cmd);
                    else
                        len = min(segm_len - offset, 5120);
                        cmd = sprintf(':TRACe:DATA "%s",%d,%d', chanStr{k}, segm_num, offset);
                        cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                        xfprintf(f, cmd);
                    end
                    offset = offset + len;
                end
                xquery(f, '*OPC?');
                xfprintf(f, sprintf(':VOLT:AMPL "%s",1.0', chanStr{k}));
                xfprintf(f, sprintf(':OUTP "%s",1', chanStr{k}));
            end
        end
    end
end


function result = getData(data, chan, chMap)
% extract the data signal for <chan>, given the channel map <chMap>
result = [];
idx = find(chMap(chan, :));
if (isempty(idx) || length(idx) > 1)
    error('no data for channel %d', chan);
else
    if (mod(idx, 2) == 0)
        result = imag(data(:,idx/2));
    else
        result = real(data(:,(idx+1)/2));
    end
end
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end


function patternString = formatMarkerString(marker)
    patternString = '' ; 
    marker = bitand(marker, 1);
    % AND with '1' (MARKER BIT for two markers)
    for i = 1:length(marker)/8
       curr_byte = 0 ; 
       for bitPos = 1:8
           curr_byte = curr_byte + 2^(bitPos-1)*marker(8*(i-1)+bitPos);
       end
        patternString = strcat(patternString, sprintf(',%d', curr_byte)) ; 
    end
end
