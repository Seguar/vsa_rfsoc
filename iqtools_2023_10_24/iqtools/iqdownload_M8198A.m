function result = iqdownload_M8198A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence, run)
% Download a waveform to the M8199A
% It is NOT intended that this function be called directly, only via iqdownload
%
% B.Krueger, Keysight Technologies 2023
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
        errordlg('M8198A sequencing not supported yet.');
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
    if ~isfield(info, 'ProductNumber') || ~strcmp(info.ProductNumber, 'M8198A')
        error('Unexpected product number');
    end
%     
   
    % find out if we are working with a clock module and which identifiers
    % to use to set the sample rate
    [isCMpresent, freqCmd, clkModuleID, clkIdentifier] = getClkCommands(f);

    fsM8070 = min(fs, 128e9);
    
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
    % Stop waveform playback
    res = xfprintf(f, sprintf(':ABORT "%s"', arbConfig.M8070ModuleID));
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
    cpm = 2;    % bk: make version-dependent
    % download to the secondary modules by calling the routine recursively
    for m = 2:4
        va = sprintf('M8070ModuleID%d', m);
        if (size(chMap, 1) > cpm*(m-1) && isfield(arbConfig, va))
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
            result = iqdownload_M8198A(arbTmp, fs, data, marker1, marker2, segmNum, keepOpen, chMap(cpm*(m-1)+1:min(cpm*m,size(chMap,1)),:), sequence, run);
        end
    end
    % don't try to download more than <cpm> channels in an given module
    chMap(cpm+1:end,:) = [];
    
    % find out how many channels are licensed, don't donwload anything to
    % an unlicensed channel to avoid error messages
%     if (isfield(info, 'Options'))
%         % if option 004 is not available, it must be a 2-channel unit
%         if isempty(info.Options) || isempty(find(contains(info.Options, '004'), 1))
%             if (ilvModeM8070)
%                 chMap(2:end,:) = [];  % leave channel 1, clear out everything else
%             else
%                 chMap(4:end,:) = [];  % leave channels 1 & 3, clear out everything else
%                 chMap(2,:) = zeros(1,size(chMap,2));
%             end
%         end
%     end
    
    % TBI: check option model
    
    
    % set the sample rate except in secondary modules
    if (fs ~= 0 && ~isfield(arbConfig, 'setupSecondary'))
        if (fsChanged)
            xfprintf(f, sprintf('%s "%s.%s",%.15g', freqCmd, clkModuleID, clkIdentifier, fsM8070));
        end
        if (isCMpresent)
            xfprintf(f, sprintf(':OUTP:STAT "%s.RefClkOut16G",1', clkModuleID));
        end
    end
   
    % Waveform download
    for col = 1:size(chMap, 2) / 2
        for ch = find(chMap(:, 2*col-1))'
            gen_arb_M8198A(arbConfig, f, ch, real(data(:,col)), segmNum, run);
        end
        for ch = find(chMap(:, 2*col))'
            gen_arb_M8198A(arbConfig, f, ch, imag(data(:,col)), segmNum, run);
        end
    end
        
    % if the user selected a certain clock pattern for the sample marker in
    % the instrument configuration window, it takes precedence over the
    % marker information passed to the download routine
%     if (isfield(arbConfig, 'sampleMarker'))
%         len = size(data,1);
%         if (contains(arbConfig.sampleMarker, 'Once'))
%             marker1 = [ones(len/2,1); zeros(len/2,1)];
%         elseif (contains(arbConfig.sampleMarker, 'unchanged'))
%             marker1 = [];
%         elseif (contains(arbConfig.sampleMarker, '/'))
%             len = 512;
%             div = str2double(arbConfig.sampleMarker(strfind(arbConfig.sampleMarker,'/')+1:end));
%             if (mod(len, div) ~= 0)
%                 warndlg('Marker pattern is not periodic');
%             end
%             marker1 = repmat([ones(div/2,1); zeros(div/2,1)], ceil(len/div), 1);
%             marker1 = marker1(1:end);
%         end
%     end
%     if (~isempty(marker1))
%         downloadMarker(arbConfig, f, marker1);
%     end

    maxRetry = 5;
    if (run == 1)
        % New SW: Send :INIT:IMM only to the primary module
        if (~isfield(arbConfig, 'setupSecondary'))
            retryCnt = 1;
            while retryCnt < maxRetry
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
%             checkRunning(f, arbConfig);
        end % setupSecondary
        if (~isfield(arbConfig, 'setupSecondary'))
            % Turn global output on.
            % TBD: find out which moduleID to use. For now, simply hardcoded...
            globalOutputModuleID = 'M1';
            xfprintf(f, sprintf(':OUTP:GLOB "%s.System",1',globalOutputModuleID));       
        end
    end
    checkRunning(f, arbConfig);
    if (~isfield(arbConfig, 'setupSecondary') && (~exist('keepOpen', 'var') || keepOpen == 0))
        iqclose(f);
    end
end


function [isCMpresent, freqCmd, clkModuleID, clkIdentifier] = getClkCommands(f)
    isCMpresent = true;
    clkModuleID = 'M1';
    freqCmd = ':FREQ';
    clkIdentifier = 'ClkGen';
end


function checkRunning(f, arbConfig, hMsg, pStart, pWidth)
% Wait until the AWG is truly running.  Just waiting for the return of :INIT:IMM is NOT sufficient.

    if (~exist('hMsg', 'var'))
        hMsg = [];
        pStart = 0;
        pWidth = 1;
    end
    retryCnt = 0;
    maxRetry = 50;
    res = str2double(xquery(f, sprintf(':STAT:INST:RUN? "%s"', arbConfig.M8070ModuleID))); % tbi: channel-specific?
    while (res ~= 1 && retryCnt < maxRetry)
        pause(1);
        res = str2double(xquery(f, sprintf(':STAT:INST:RUN? "%s"', arbConfig.M8070ModuleID)));
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
        retStr = 'Timeout while starting signal generation on M8198A. Please double check that the clock and sync signals are properly connected.';
        error(retStr);
    end

end

function gen_arb_M8198A(arbConfig, f, chan, data, segm_num, run)
% download an arbitrary waveform signal to a given channel
    if (isempty(chan) || ~chan)
        return;
    end
    segmentOffset = 0;
    moduleId = arbConfig.M8070ModuleID;
    chanStr = [moduleId '.DataOut' num2str(chan)];
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
% set peaking
        if (isfield(arbConfig, 'peaking') && ~isempty(arbConfig.peaking))
            tmp = fixlength(arbConfig.peaking, chan);
            [retVal, retStr] = xfprintf(f, sprintf(':OUTP:VPCorr "%s",%g', chanStr, tmp(chan)), 1);
            if (retVal ~= 0 && ~contains(retStr, 'cannot be modified'))
                xfprintf(f, sprintf(':OUTP:VPCorr "%s",%g', chanStr, tmp(chan)));
            end
        end
        xfprintf(f, sprintf(':OUTP "%s",1', chanStr));
    end
end

function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end

