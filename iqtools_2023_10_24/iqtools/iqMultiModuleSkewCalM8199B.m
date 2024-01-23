function [] = iqMultiModuleSkewCalM8199B(handles, moduleSkew)
    %% Do some checks
    % Check AWG model
    arbConfig = loadArbConfig();

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
%     
    if isempty(autoCalList)
        errordlg('Select at least two modules in the instrument configuration');
        return;
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

    if modulesValid == 0
        errordlg('Not all modules from instrument configuration are available ; please check ');
        return;
    end

    %% Perform multimodule threshold cal
    if moduleSkew == 0
        if (~isempty(autoCalList))

            % Check if a valid cal data set is already available
            CalRequired = checkCalRequired(f, arbConfig, autoCalList, IDlist);

            if CalRequired == 0
                % Ask if call should be performed
                res = questdlg('The system contains valid cal data. Do you really want to re-calibrate the system?', ...
                'Continue', 'Yes', 'No', 'Yes');
                switch (res)
                    case 'No'
                        return
                    otherwise
                end
            end
            % Define sample rate vector depending on available license
            lic256 = 1 ;
            % find module driver version
            for i = 1:length(autoCalList)+1
                if i == 1
                    try
                        infJson = xquery(f, sprintf(':SYST:INF:DET:JSON? "%s"', arbConfig.M8070ModuleID));
                    catch ex
                        iqreset();
                        error(['Can not communicate with M8070B. Please try again. ' ...
                            'If this does not solve the problem, exit and restart MATLAB. ' ...
                            '(Error message: ' ex.message ')']);
                    end
                else
                    try
                        infJson = xquery(f, sprintf(':SYST:INF:DET:JSON? "%s"', autoCalList{i-1}));
                    catch ex
                        iqreset();
                        error(['Can not communicate with M8070B. Please try again. ' ...
                            'If this does not solve the problem, exit and restart MATLAB. ' ...
                            '(Error message: ' ex.message ')']);
                    end
                end
                try
                    info = jsondecode(infJson);
                catch
                    error('Cannot decode module driver information. Please check if all modules in Instrument Configuration are available!');
                end
                if ~isempty(info.Options) 
                    if (~isempty(find(contains(info.Options,'S01'), 1)) && isempty(find(contains(info.Options,'256'), 1))) || (~isempty(find(contains(info.Options,'S02'), 1)) && isempty(find(contains(info.Options,'256'), 1)))
                        lic256 = 0 ;
                        break;
                    end
                else
                    lic256 = 0 ;
                    break;
                end
            end
            if lic256 == 0
                fs_vec = (100:0.5:112)*1e9;
            else
                fs_vec = (100:0.5:128)*1e9;
            end
            % define sample rate vector (for equal syncIn cables, a step size of 1GS/s should be sufficient 
            
            ilvModeM8070 = 1;
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
            fs_vec_cmp = fs_vec;

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
                StrVec(j,1:2:end) = fs_vec/2;
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
    else
        if isempty(autoCalList)
            errordlg(sprintf('At least two modules required for inter-module skew calibration!'));
            return
        else
            errordlg(sprintf('Module configuration error. Please check instrument configuration!'));
            return
        end
        end
    %% Perform multimodule skew cal
    else
        
        res = questdlg(['Multi-module skew cal is performed. Ensure that channel 1 of each module is connected to the scope. Continue?'], ...
        'Continue', 'Yes', 'No', 'Yes');
        if strcmp(res, 'No')
           return
        end
        
         %% Check if all modules configured in instrument configuration are listed in the insystem cal AWG channels
        list1 = get(handles.popupmenu1AWG, 'String');
        list2 = get(handles.popupmenu2AWG, 'String');
        list3 = get(handles.popupmenu3AWG, 'String');
        list4 = get(handles.popupmenu4AWG, 'String');
        trigList = get(handles.popupmenuTrigAWG, 'String');
        awgChannels = { list1{get(handles.popupmenu1AWG, 'Value')} ...
                        list2{get(handles.popupmenu2AWG, 'Value')} ...
                        list3{get(handles.popupmenu3AWG, 'Value')} ...
                        list4{get(handles.popupmenu4AWG, 'Value')} ...
                        trigList{get(handles.popupmenuTrigAWG, 'Value')}};
   
        list1 = get(handles.popupmenu1Scope, 'String');
        list2 = get(handles.popupmenu2Scope, 'String');
        list3 = get(handles.popupmenu3Scope, 'String');
        list4 = get(handles.popupmenu4Scope, 'String');
        trigList = get(handles.popupmenuTrigScope, 'String');
        scopeChannels = { list1{get(handles.popupmenu1Scope, 'Value')} ...
                          list2{get(handles.popupmenu2Scope, 'Value')} ...
                          list3{get(handles.popupmenu3Scope, 'Value')} ...
                          list4{get(handles.popupmenu4Scope, 'Value')} ...
                          trigList{get(handles.popupmenuTrigScope, 'Value')}};
        
        % Remove unused channels & marker to make some sanity checks
        UsedAwgChannels = awgChannels((~contains(awgChannels,'unused') & ~contains(awgChannels,'Marker')));
        UsedScopeChannels = scopeChannels((~contains(scopeChannels,'unused') & ~contains(scopeChannels,'PTB')));

        if length(UsedAwgChannels) ~= length(UsedScopeChannels) || length(UsedAwgChannels) ~= length(autoCalList)+1
             errordlg('Number of configured channels does not match with number of configured modules ; please ensure to connect one channel per module to one scope channel ');
                return;
        end

        if sum(contains(UsedAwgChannels, '1')) == 0
            errordlg('Channel mapping error! Please include channel 1 of primary module (M2) in the channel mapping.');
                return;
        end
        for i = 1:length(autoCalList)
            if sum(contains(UsedAwgChannels, num2str(2*i+1))) == 0
                errordlg(sprintf('Channel mapping error! Please include channel 1 of %s in the channel mapping',autoCalList{i} ));
                return;
            end
        end
        % Reset Module Skew user cal table and ensure that channel delay is
        % set to 0
        for i = 1:length(autoCalList)
            % Reset user cal table
            xfprintf(f, sprintf(':CAL:TABL:DEL "%s.System","User.moduleskew"', autoCalList{i}));
            % Set GUI channel delay to zero
            channelDelay = str2double(xquery(f,sprintf(':ARM:DELay? "%s.DataOut1"', autoCalList{i}))) ; 
            if channelDelay ~= 0
                xfprintf(f, sprintf(':ARM:DELay "%s.DataOut1", 0', autoCalList{i})) ; 
            else % touch the delay to ensure that the probably changed module skew change is applied
                xfprintf(f, sprintf(':ARM:DELay "%s.DataOut1", 1e-12', autoCalList{i})) ; 
                xfprintf(f, sprintf(':ARM:DELay "%s.DataOut1", 0', autoCalList{i})) ; 
            end
        end
        
        % TBI: reset multimodule skew, toggle delay to ensure that
        % delay is set
        
        % Measure skew
        fs_vec_cal = [200 228 256]*1e9;
        for i = 1:length(fs_vec_cal)
            if get(handles.radiobuttonRTScope, 'Value') == 1
                scope = 'RTScope';
            else
                scope = 'DCA';
            end
            result = iqmtcal('scope', scope, 'sim', 0, 'scopeAvg', 1, ...
                            'numTones', 300, 'scopeRST', 0, 'AWGRST', 0, ...
                            'sampleRate', fs_vec_cal(i), 'recalibrate', 0, ...
                            'autoScopeAmpl', 1, 'memory', 65536, ...
                            'awgChannels', awgChannels, 'scopeChannels', scopeChannels, ...
                            'maxFreq', 70e9, 'analysisAvg', 4, 'toneDev', 'Random', ...
                            'amplitude', 0.8, 'axes', [], ...
                            'scopeBW', 'MAX', 'scopeSIRC', 1, 'separateTones', 0, ...
                            'skewIncluded', 1, 'removeSinc', 0, 'debugLevel', 0, 'restorescope', 0);
            skewMeas = result.skew;
            [~,idxRefChannel ] = find([awgChannels{:}]=='1');
%             autoCalList = {'M3'};
%             autoCalList = {'M3' 'M4' 'M5'}; % for debug purposes
            idxFollowerModules = zeros(1,length(autoCalList));
            for j = 1:length(autoCalList)
                 [~,idxFollowerModules(j) ] = find([awgChannels{:}]==num2str(2*j+1));
            end
            skewModules(i,:) = skewMeas(idxRefChannel)-skewMeas;
        end
        f = iqopen(arbConfig);
        for i = 1:length(autoCalList)
            StrVec = zeros(1,2*length(fs_vec_cal));
            StrVec(1:2:end) = fs_vec_cal;
            StrVec(2:2:end) = -skewModules(:,idxFollowerModules(i));
            ModuleSkewStr = strjoin(compose('%e',StrVec),', ');
            % update user cal table
            cmd = sprintf(':CAL:TABL:DATA "%s.System","User.moduleskew","%s"', autoCalList{i}, ModuleSkewStr);
            xfprintf(f, cmd);
            for chan = 1:2
                channelDelay = str2double(xquery(f,sprintf(':ARM:DELay? "%s.DataOut%.0f"', autoCalList{i}, chan))) ; 
                if channelDelay ~= 0
                    xfprintf(f, sprintf(':ARM:DELay "%s.DataOut%.0f", 0', autoCalList{i},chan)) ; 
                else % touch the delay to ensure that the probably changed module skew change is applied
                    xfprintf(f, sprintf(':ARM:DELay "%s.DataOut%.0f", 1e-12', autoCalList{i},chan)) ; 
                    xfprintf(f, sprintf(':ARM:DELay "%s.DataOut%.0f", 0', autoCalList{i},chan)) ; 
                end
            end
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


