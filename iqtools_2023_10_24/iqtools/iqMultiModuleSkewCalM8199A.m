function [] = iqMultiModuleSkewCalM8199A(handles)

    % Check AWG model
    arbConfig = loadArbConfig();
    if (isempty(arbConfig) || ~isfield(arbConfig, 'model') || ~contains(arbConfig.model, 'M8199A') && ~contains(arbConfig.model, 'M8199B'))
        errordlg('User Calibration is only available for M8199A & M8199B');
        return;
    end
    % Check module driver version (TBI: change version number, as soon as
    % official module driver is available)
    swVersion = readM8199AModuleDriverVersion(arbConfig);
    % for release
    if contains(arbConfig.model, 'M8199A')
        if (swVersion < 1004000)
            errordlg('User Calibration is only available with M8199A module driver version 1.4 or later');
            return;
        end
    end
    f = iqopen(arbConfig);
    % get all non-primary modules
    IDlist = { '2', '3', '4' }; % referring to arbConfig.M8070ModuleID%s
    autoCalList = {};               % list of module IDs that require calibration
    for i = 1:length(IDlist)
        va = sprintf('M8070ModuleID%s', IDlist{i});
        if (isfield(arbConfig, va))
            moduleID = arbConfig.(va);
            autoCalList{end+1} = moduleID;
        end
    end

    % Check if all configured modules in instrument configuration are available
    % in HW
    modulesValid = 1 ; 
    for i = 1:length(IDlist)
        va = sprintf('M8070ModuleID%s', IDlist{i});
        if (isfield(arbConfig, va))
            moduleID = arbConfig.(va);

            infJson = xquery(f, sprintf(':SYST:INF:DET:JSON? "%s"', moduleID));
            if length(infJson) == 1 % module not available
                modulesValid = 0;
            end
        end
    end

    if (~isempty(autoCalList) && modulesValid)
        
        % Check if a valid cal data set is already available
        CalRequired = checkCalRequired(f, arbConfig, autoCalList, IDlist);
        
        if CalRequired == 0
            % Ask if call should be performed
            res = questdlg(['The system contains valid cal data. Do you really want to re-calibrate the system?'], ...
            'Continue', 'Yes', 'No', 'Yes');
            switch (res)
                case 'No'
                    return
                otherwise
            end
        end
        % define sample rate vector (for equal syncIn cables, a step size of 1GS/s should be sufficient 
        fs_vec = (100:0.5:128)*1e9;
        ilvModeM8070 = str2double(xquery(f, sprintf(':SYST:INST:ILVMode? "%s.System"', arbConfig.M8070ModuleID)));
        StrVec = zeros(length(autoCalList), 2*length(fs_vec));

        if (ilvModeM8070) % Sample rate value for programming M8070
            fs_vec = 2*fs_vec;
        end

        % turn outputs off, :init:imm to ensure that run mode is active
        globalOutputModuleID = 'M1';
        xfprintf(f, sprintf(':OUTP:GLOB "%s.System",0', globalOutputModuleID));
        xfprintf(f, 'INIT:IMM "M2"');
        checkRunning(f, arbConfig);
        durationFreqChange = 15;
        pStart = 0;
        pWidth = 1;
        for i = 1:length(fs_vec)

           if i == 1
               hMsg = iqwaitbar(sprintf(['M8199A multi-module skew threshold alignment. \n'...
                                'This will take around %d minutes. No external equipment or user interaction is required.\n' ...
                                'Please wait...\n'],round(durationFreqChange*length(fs_vec)/60)));
           end

           % set sample rate
           if i == 2
               tic;
           end
           xfprintf(f, sprintf(':SOURce:FREQuency "M1.ClkGen",%f', fs_vec(i)));
           % wait until alignment has finished
           checkRunning(f, arbConfig);
           if i == 2 
              durationFreqChange = toc;
           end
           if i ~=1
                if (hMsg.canceling())
                   return;
               end
               hMsg.update(pStart + (i / length(fs_vec)) * pWidth, sprintf(['M8199A multi-module skew threshold alignment. \n'...
                                'This will take around %d minutes. No external equipment or user interaction is required.\n' ...
                                'Please wait...\n'],round(durationFreqChange*length(fs_vec)/60)));
           end
           AnalogDelayRefChannel(i) = str2double(xquery(f,':source:xskew:threshold:value? "M2.System"'));

           for j = 1:length(autoCalList)
               va = sprintf('M8070ModuleID%s', IDlist{j});
               moduleID = arbConfig.(va);
               AnalogDelayFollower(j,i) = str2double(xquery(f,sprintf(':source:xskew:threshold:value? "%s.System"',moduleID)));
               DeltaAnalogDelayFollowersUnwrapped(j,i) = AnalogDelayRefChannel(i) - AnalogDelayFollower(j,i) ;
               if i == length(fs_vec)
                    infJson = xquery(f, sprintf(':SYST:INF:DET:JSON? "%s"', moduleID));
                    info = jsondecode(infJson);
                    if isfield(info, 'SerialNumber')
                        SNsecondaries{j} = info.SerialNumber;
                    end
               end       
           end
        end

        % Formula was developed in interleaved mode, so ensure that "fs" is
        % always the interleaved one (independent of actual mode)
        if (ilvModeM8070) 
            fs_vec_cmp = fs_vec;
        else
            fs_vec_cmp = fs_vec*2;
        end
        
        for j = 1:length(autoCalList)
            Delta_InterModule_wrapped = DeltaAnalogDelayFollowersUnwrapped(j,:);
            for i = 1:length(fs_vec_cmp)
                fs = fs_vec_cmp(i);
                % Wrap the measured difference at lowest sample rate in the +- fs range 
                if i == 1
                    if Delta_InterModule_wrapped(i) > 1/fs
                        Delta_InterModule_wrapped(i) = Delta_InterModule_wrapped(i)-2/fs;
                    elseif Delta_InterModule_wrapped(i) < -1/fs
                        Delta_InterModule_wrapped(i) = Delta_InterModule_wrapped(i)+2/fs;
                    end 
                else
                    UIshifts = ceil(abs((Delta_InterModule_wrapped(i-1)-Delta_InterModule_wrapped(i)))*fs);
                    % detect number of shifts 
                    if UIshifts ~= 0
                        if mod(UIshifts,2) ~= 0
                            UIshifts = UIshifts - 1;
                        end
                    end
                    shiftDir = sign(Delta_InterModule_wrapped(i-1)-Delta_InterModule_wrapped(i));    % detect shift direction
                    Delta_InterModule_wrapped(i) = Delta_InterModule_wrapped(i) + shiftDir*UIshifts/fs;
                end
            end

            WraparoundThreshold(j,:) = Delta_InterModule_wrapped -1./fs_vec_cmp;

            % Prepare string for writing data into cal-table (convention: only
            % use non-ILV sample rate
            if (ilvModeM8070) 
                StrVec(j,1:2:end) = fs_vec/2;
            else
                StrVec(j,1:2:end) = fs_vec;
            end
            StrVec(j,2:2:end) = WraparoundThreshold(j,:);
        end
        % write data into cal table

        % get SN from primary module
        infJson = xquery(f, ':SYST:INF:DET:JSON? "M2"');
        info = jsondecode(infJson);
        if isfield(info, 'SerialNumber')
            SNprimary = info.SerialNumber;
        end

        for j = 1:length(autoCalList)
            va = sprintf('M8070ModuleID%s', IDlist{j});
            moduleID = arbConfig.(va);

            ThresholdStr = strjoin(compose('%e',StrVec(j,:)),', ');
            cmd = sprintf(':CAL:TABL:DATA "%s.System","User.XModuleSkewAlignmentThreshold","%s"', moduleID, ThresholdStr);
            xfprintf(f, cmd);

            % set reference SN
            cmd = sprintf(':CAL:TABL:DATA "%s.System","User.XModuleReferenceSN","%s"', moduleID, SNprimary);
            xfprintf(f, cmd);
        end
        msgbox('M8199A multi-module cal has finished. Please perform insystem calibration to remove residual channel delay.');
        
        % save the results of the skew alignment cal for debugging
        % purposes.  Ignore any errors in the process...
        try
            file = fullfile(iqScratchDir(), 'iqMultiModuleAlign.mat');
            clear cal;
            cal.version = 1;
            cal.timeStamp = datetime();
            cal.moduleList = autoCalList;
            cal.SNprimary = SNprimary;
            cal.SNsecondaries = SNsecondaries;
            cal.AnalogDelayRefChannel = AnalogDelayRefChannel;
            cal.AnalogDelayFollower = AnalogDelayFollower ;
            cal.DeltaAnalogDelayFollowersUnwrapped = DeltaAnalogDelayFollowersUnwrapped;
            cal.WraparoundThreshold = WraparoundThreshold;
            
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

        
        % Perform channel skew cal
        
%         res = questdlg(['Cal finished. Perform channel skew alignment? (requires scope connection as configured in insystemcal)'], ...
%         'Continue', 'Yes', 'No', 'Yes');
%         switch (res)
%             case 'No'
%                 return
%             otherwise
                % tbi: measure channel skew
                % download waveform
%                 for i = 1:3
%                     switch (i)
%                         case 1
%                             fs_cal = fs_vec(1);
%                         case 2
%                             fs_cal = fs_vec(round(length(fs_vec)/2));
%                         otherwise
%                             fs_cal = fs_vec(end);
%                     end
%                     result = iqmtcal('scope', 'RTScope', 'sim', 0, 'scopeAvg', 1, ...
%                                     'numTones', 300, 'scopeRST', 0, 'AWGRST', 0, ...
%                                     'sampleRate', fs_cal, 'recalibrate', 0, ...
%                                     'autoScopeAmpl', 1, 'memory', 65536, ...
%                                     'awgChannels', { '1' '3' '5' '7' 'unused' }, 'scopeChannels', { '1' '2' '3' '4' 'unused' }, ...
%                                     'maxFreq', 70e9, 'analysisAvg', 4, 'toneDev', 'Random', ...
%                                     'amplitude', 0.8, 'axes', [], ...
%                                     'scopeBW', 'AUTO', 'scopeSIRC', 1, 'separateTones', 0, ...
%                                     'skewIncluded', 1, 'removeSinc', 0, 'debugLevel', 0);
% %                    
% % %                     for ch = 1:length(AWGChannels)
% % %                         calTableName = 'User.skew';
% % %                         oldSkewStr = xquery(f, sprintf(':CAL:TABL:DATA? "%s","%s","%.12g"', buildID(arbConfig, AWGChannels(ch)), calTableName, fsAWG));
% % %                         oldSkew = sscanf(strrep(strrep(oldSkewStr, ',', ' '), '"', ''), '%g');
% % %                         % frequency is in pos 1, skew is in pos 2
% % %                         newSkew = oldSkew;
% % %                         newSkew(2) = newSkew(2) - skew(ch);
% % %                         newSkewStr = sprintf('%g,', newSkew(:));
% % %                         newSkewStr = newSkewStr(1:end-1);
% % %                         xfprintf(f, sprintf(':CAL:TABL:DATA "%s","User.skew","%s"', buildID(arbConfig, AWGChannels(ch)), newSkewStr));
% % %                         % "touch" the user delay to make sure that the new value in the cal table is reflected on the output
% % %                         xfprintf(f, sprintf(':ARM:DEL "%s",%g', buildID(arbConfig, AWGChannels(ch)), 1e-12));
% % %                         xfprintf(f, sprintf(':ARM:DEL "%s",%g', buildID(arbConfig, AWGChannels(ch)), 0));            
                                
                                
%                 end
                 
%         end
        
    else
        if isempty(autoCalList)
            errordlg(sprintf('At least two modules required for inter-module skew calibration!'));
        else
            errordlg(sprintf('Module configuration error. Please check instrument configuration!'));
        end
    end


function checkRunning(f, arbConfig)
% Wait until the AWG is truly running.  Just waiting for the return of :INIT:IMM is NOT sufficient.

    retryCnt = 0;
    maxRetry = 70;
    res = str2double(xquery(f, sprintf(':STAT:INST:RUN? "%s.SampleMrk"', arbConfig.M8070ModuleID)));
    while (res ~= 1 && retryCnt < maxRetry)
        pause(1);
        res = str2double(xquery(f, sprintf(':STAT:INST:RUN? "%s.SampleMrk"', arbConfig.M8070ModuleID)));
        retryCnt = retryCnt + 1;
    end
    if (retryCnt >= maxRetry)
        retStr = 'Timeout while starting signal generation on M8199A. Please double check that the clock and sync signals are properly connected.';
        error(retStr);
    end

function calRequired = checkCalRequired(f, arbConfig, autoCalList, IDlist)

    calRequired = 0 ; 
    % get SN from primary module
    infJson = xquery(f, sprintf(':SYST:INF:DET:JSON? "%s"', 'M2'));
    info = jsondecode(infJson);
    if isfield(info, 'SerialNumber')
        SNprimary = info.SerialNumber;
    end

    for j = 1:length(autoCalList)
        va = sprintf('M8070ModuleID%s', IDlist{j});
        moduleID = arbConfig.(va);

        % get reference SN
        cmd = sprintf(':CAL:TABL:DATA? "%s.System","User.XModuleReferenceSN"', moduleID);
        RefSN = xquery(f, cmd);
        RefSN = RefSN(2:end-2); % remove " " 
        
        if strcmp(RefSN, SNprimary)
            cmd = sprintf(':CAL:TABL:DATA? "%s.System","User.XModuleSkewAlignmentThreshold"', moduleID);
            calData = xquery(f, cmd);
            
            if length(calData) < 10
                calRequired = 1;
            end
        else
           calRequired = 1; 
        end

        
    end


function swVersion = readM8199AModuleDriverVersion(arbConfig)
% find module driver version
try
    f = iqopen(arbConfig);
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
if ~isfield(info, 'ProductNumber') || ~strcmp(info.ProductNumber, 'M8199A') && ~strcmp(info.ProductNumber, 'M8199B')
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

