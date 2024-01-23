function result = vsafunc(vsaApp, fct, varargin)
% Send commands and retrieve measurements from the 89600 VSA software.
% This function is not intended to be called directly from the command line,
% but from higher-level scripts (e.g. iqmod_gui.m)
%
% It uses the .NET interface or SCPI to communicate with the VSA software.
% If a running instance can be found, it will be used. Otherwise a new
% instance of VSA is launched (.NET only)
%
% T.Dippon, T.Wychock, Keysight Technologies 2014-2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

result = [];
try
switch fct
    % attach to VSA session. If VSA is not running, start a new session
    % no additional arguments
    case 'open'
        cfg = loadArbConfig();
        if ((isfield(cfg, 'isVSAConnected') && cfg.isVSAConnected ~= 0) || ...
            (~isfield(cfg, 'isVSAConnected') && isfield(cfg, 'visaAddrVSA')))    % use SCPI
            vsaApp = iqopen(cfg.visaAddrVSA);
            if (isempty(vsaApp))
                errordlg({'Can not open connection to VSA software at ' cfg.visaAddrVSA ...
                    'Please check VSA address in configuration window' ...
                    'and make sure it is configured for SCPI access and' ...
                    'manually launch the application'});
            else
                res = xquery(vsaApp, ':SYST:VSA:START?');
                if (~strncmp(res, '1', 1))
                    errordlg({'VSA is not running. Please start it manually'});
                    iqclose(vsaApp);
                    vsaApp = [];
                    return;
                    % automatically starting VSA through SCPI does not seem
                    % to work....
%                     hMsgBox = msgbox({'Starting VSA software...', 'Please wait, this can take up to 1 minute'});
%                     vsaApp.Timeout = 60;
%                     xfprintf(vsaApp, ':SYST:VSA:STARt 1,,,-1,60');
%                     try
%                         close(hMsgBox);
%                     catch
%                     end
                end
                xfprintf(vsaApp, ':SYST:VSA:WIND:SHOW 1,1');
            end
        else
            if isdeployed % Stand-alone mode
                [~, result] = system('path');
                mypath = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
            else % MATLAB mode
                mypath = fullfile(fileparts(which('vsafunc')), 'Interfaces');
            end
            pwdpath = fullfile(pwd, 'Interfaces');
            pathlist = { ...
                mypath ...
                pwdpath ...
                'C:\Program Files\Agilent\89600 Software 2018\89600 VSA Software\Interfaces\' ...
                'C:\Program Files\Agilent\89600 Software 22.2\89600 VSA Software\Interfaces\' ...
                'C:\Program Files\Keysight\89600 Software 19.2\89600 VSA Software\Interfaces\' ...
                'C:\Program Files\Agilent\89600 Software 18.7\89600 VSA Software\Interfaces\' ...
                'C:\Program Files\Keysight\89600 Software 2023\89600 VSA Software'
                };
            asmNameList = { ...
                'Agilent.SA.Vsa.Interfaces.dll' ...
                'Agilent.SA.Vsa.DigitalDemod.Interfaces.dll' ...
                'Agilent.SA.Vsa.CustomOfdm.Interfaces.dll' ...
                'Agilent.SA.Vsa.ChannelQuality.Interfaces.dll' ... %WYCHOCK adds channel quality
                'Agilent.SA.Vsa.HardwareExtensions.Core.Interfaces.dll' ... %richard_soden@keysight.com X-seriesa mixermode
                };
            % for each assembly, check each of the path directories
            for a = 1:length(asmNameList)
                found = 0;
                asmName = asmNameList{a};
                for i = 1:length(pathlist)
                    fullAsmName = fullfile(pathlist{i}, asmName);
                    if (exist(fullAsmName, 'file'))
                        try
                            NET.addAssembly(fullAsmName);
                            found = 1;
                            break;  % if execution is at this point, we found the DLLs
                        catch ex
                            errordlg(sprintf('Error loading VSA Interface DLL\n%s\n%s', fullAsmName, ex.message));
                        end
                    end
                end
                if (~found)
                    errordlg([{'Can''t find VSA Interface DLL ' asmName ' in any of the following directories:' ' '} pathlist]);
                    return;
                end
            end
            import Agilent.SA.Vsa.*;
            % Attach to a running instance of VSA. If there no running instance, 
            % create one.
            vsaApp = ApplicationFactory.Create();
            if (isempty(vsaApp))
                hMsgBox = msgbox({'Starting VSA software...', 'Please wait, this can take up to 1 minute'});
                try
                    vsaApp = ApplicationFactory.Create(true, '', '', -1);
                catch e
                end
                close(hMsgBox);
            end
            if (isempty(vsaApp))
                errordlg('Can''t open VSA Software');
                return;
            end
            % Make VSA visible
            try
                vsaApp.IsVisible = true;
            catch ex
                errordlg('VSA control through .NET does not work properly on this PC. As a workaround, please turn on "Remote VSA control" in the instrument configuration window', 'Error', 'modal');
                throw(ex);
            end
        end
        result = vsaApp;
        assignin('base', 'vsaApp', vsaApp);

%-------------------------------------------------------------------------        
    case 'preset'
        % set VSA default settings
        % argument 1: measurement mode (vector or digdemod) (optional)
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaDisp = vsaApp.Display;
            % Preset to defaults
% don't reset from scratch every time, since it takes a long time and
% switches relays unnecessarily in the scope & spectrum analyzer
%        vsaDisp.Preset;
%        vsaMeas.Preset;
%            vsaMeas.Reset;
            vsaMeas.Pause();
            vsaInput = vsaMeas.Input;
            % apparently, VSA does not like the Trigger command under some circumstances
            try
                vsaInput.Recording.Trigger.Style = Agilent.SA.Vsa.TriggerStyle.Auto;
                vsaInput.Trigger.Style = Agilent.SA.Vsa.TriggerStyle.Auto;
            catch
            end
            if (length(varargin) >= 1)
                switch (lower(varargin{1}))
                    case 'vector'
                        vsaMeas = vsaApp.Measurements.SelectedItem;
                        % I couldn't figure out how to set the measurement type
                        % back to "Vector", so I'll just do a Preset
                        vsaMeas.Preset();
                    case 'digdemod'
                        digDemod = getDigDemod(vsaApp);
                end
            end
        else %----- communicating to VSA through SCPI
            xfprintf(vsaApp, ':INIT:ABOR');
            xfprintf(vsaApp, ':INIT:PAUS');
            xfprintf(vsaApp, ':INP:TRIG:STYLe "Auto"');
            xfprintf(vsaApp, ':INP:REC:TRIG:STYLe "Auto"');
            if (length(varargin) >= 1)
                switch (lower(varargin{1}))
                    case 'vector'
                        xfprintf(vsaApp, ':MEAS:CONF VECT');
                        % :MEAS:CONF VECT apparently does not do switch
                        % back to vector, so let's do a Preset
                        xfprintf(vsaApp, ':SYST:PRES:MEAS');
                    case 'digdemod'
                        xfprintf(vsaApp, ':MEAS:CONF DDEM');
                end
            end
        end
%-------------------------------------------------------------------------        
    case 'autorange'
        % if an argument is given, then set the range to this value
        % otherwise: autorange
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            try
                if (length(varargin) >= 1)
                    range = (varargin{1});
                    vsaAnalog = vsaMeas.Input.Analog;
                    vsaAnalog.RangeInDbm = range;
                else
                    vsaMeas.WaitForMeasurementDone(5000);
                    vsaMeas.Input.Analog.AutoRange;
                    vsaMeas.WaitForMeasurementDone(5000);
                end
            catch
            end
        else %----- communicating to VSA through SCPI
            if (length(varargin) >= 1)
                xfprintf(vsaApp, sprintf(':INP:ANAL:RANG:DBM %g', varargin{1}));
            else
                pause(1); % wait for inputs to settle before calling autorange
                xfprintf(vsaApp, sprintf(':INP:ANAL:RANG:AUTO'));
                opc = 0;
                while (opc == 0)
                    pause(1);
                    opc = str2double(xquery(vsaApp, '*OPC?'));
                end
            end
        end
%-------------------------------------------------------------------------        
    case 'load'
        % load a vector
        % argument 1: data vector
        % argument 2: sampleRate
        % argument 3: add AWGN or not (default: add AWGN)
        Y = reshape(varargin{1}, numel(varargin{1}), 1);
        % create a certain minimum number of samples so that VSA does not
        % complain about a record length being too short
        minLength = 500000;
        if (length(Y) < minLength)
            Y = repmat(Y, ceil(minLength/length(Y)), 1);
        end
        
        if (length(varargin) < 3 || varargin{3} == 1)
            % add a tiny bit of noise to make the VSA display look realistic ;-)
            Y = awgn(Y,300);
        end

        XStart = 0; %#ok<NASGU>
        XDelta = 1/varargin{2}; %#ok<NASGU>
        InputZoom = 1; %#ok<NASGU>
        Y = complex(Y);  % VSA expects a complex-valued vector
        file = fullfile(iqScratchDir(), 'vsatemp.mat');
        
        %check the size of the variable, if it's large, save as -v7.3
        sizeInfo = whos('Y');
        if (sizeInfo.bytes > 1e9)
            save(file, 'Y', 'XStart', 'XDelta', 'InputZoom', '-v7.3');
        else
            save(file, 'Y', 'XStart', 'XDelta', 'InputZoom');
        end
                
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaMeas.Input.Recording.RecallFile(file, 'MAT');
            vsaInput = vsaMeas.Input;
            vsaInput.DataFrom = DataSource.Recording;
    %        vsafunc(vsaApp, 'input', 1);    % set VSA to baseband
        else %----- communicating to VSA through SCPI
            xfprintf(vsaApp, sprintf(':MMEMory:LOAD:RECording "%s","MAT"', file));
            xfprintf(vsaApp, sprintf(':INPUT:DATA REC'));
        end
%-------------------------------------------------------------------------        
    case 'load2'
        % load two vectors
        % argument 1: data vector 1
        % argument 2: data vector 2
        % argument 3: sampleRate
        % argument 4: add AWGN or not (default: add AWGN)
        Y1 = reshape(varargin{1}, numel(varargin{1}), 1);
        Y2 = reshape(varargin{2}, numel(varargin{2}), 1);
        % create a certain minimum number of samples so that VSA does not
        % complain about a record length being too short
        minLength = 500000;
        if (length(Y1) < minLength)
            Y1 = repmat(Y1, ceil(minLength/length(Y1)), 1);
        end
        if (length(Y2) < minLength)
            Y2 = repmat(Y2, ceil(minLength/length(Y2)), 1);
        end
        
        if (length(varargin) < 4 || varargin{4} == 1)
            % add a tiny bit of noise to make the VSA display look realistic ;-)
            Y1 = awgn(Y1,300);
            Y2 = awgn(Y2,300);
        end

        XStart = 0; %#ok<NASGU>
        XDelta = 1/varargin{2}; %#ok<NASGU>
        InputZoom = 1; %#ok<NASGU>
        Y1 = complex(Y1);
        Y2 = complex(Y2);   % VSA expects a complex vector
        file = fullfile(iqScratchDir(), 'vsatemp.mat');
        
        %check the size of the variable, if it's large, save as -v7.3
        sizeInfo = whos('Y1');
        if (sizeInfo.bytes > 1e9)
            save(file, 'Y1', 'Y2', 'XStart', 'XDelta', 'InputZoom', '-v7.3');
        else
            save(file, 'Y1', 'Y2', 'XStart', 'XDelta', 'InputZoom');
        end
                
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaMeas.Input.Recording.RecallFile(file, 'MAT');
            vsaInput = vsaMeas.Input;
            vsaInput.DataFrom = DataSource.Recording;
    %        vsafunc(vsaApp, 'input', 1);    % set VSA to baseband
        else %----- communicating to VSA through SCPI
            xfprintf(vsaApp, sprintf(':MMEMory:LOAD:RECording "%s","MAT"', file));
            xfprintf(vsaApp, sprintf(':INPUT:DATA REC'));
        end
%-------------------------------------------------------------------------        
    case 'fromHW'
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaInput = vsaMeas.Input;
            vsaInput.DataFrom = DataSource.Hardware;
        else
            xfprintf(vsaApp, sprintf(':INPUT:DATA HW'));
        end
%-------------------------------------------------------------------------        
    case 'input'
        % argument 1: center frequency (0 -> IQ, not zero 0 -> baseband)
        % argument 2: channel configuration string
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaInput = vsaMeas.Input;
            types = vsaInput.LogicalChannelTypesSupported;
            % check, if we even have a choice of logical channels
            if (types.Count > 1)
                logicalChTypes = NET.createArray('Agilent.SA.Vsa.LogicalChannelType', 1);
                if (varargin{1} == 0)
                    logicalChTypes(1) = Agilent.SA.Vsa.LogicalChannelType.IQ;
                else
                    logicalChTypes(1) = Agilent.SA.Vsa.LogicalChannelType.Baseband;
                end                
                % added by Tom Wychock tom.wychock@keysight.com
                % if debugVSACustomSetupFile is a valid path, load that file
                % command example: 
                % debugVSACustomSetupFile = 'C:\\Users\\username\\Desktop\\Preset1.setx'
                % to cancel, command: clear debugVSACustomSetupFile
                % if not, then perform as normal
                % this function is for channel setups that are not common
                % If debugVSACustomSetupFile exists or if not from recording, load it
                if (evalin('base', 'exist(''debugVSACustomSetupFile'', ''var'')') && vsaInput.DataFrom == DataSource.Hardware)
                    try
                        vsaApp.RecallSetup(evalin('base', 'debugVSACustomSetupFile'));
                        vsaMeas.Pause();   
                    %If error, set to default state
                    catch ex
                        errordlg('Incorrect File Setup. Presetting to stable state')
                        try
                            vsaInput.ChangeLogicalChannels(logicalChTypes);
                        catch ex
                            % The error message sometimes appears when
                            % trying to connect to a PXA. Since it is not
                            % very useful and the test works nevertheless,
                            % it is commented out
                            % errordlg('Can not set the input channels. Please connect VSA to the appropriate analyzer hardware, then try again.','Error')  
                        end
                    end
                % If debugVSACustomSetupFile doesn't exist, act as it normally would    
                else
                    try
                        % Don't try to change the logical channels on a spectrum analyzer,
                        % where the first logical channel type is RF
                        if (types.Item(0) ~= Agilent.SA.Vsa.LogicalChannelType.RF)
                            vsaInput.ChangeLogicalChannels(logicalChTypes);
                        end
                    catch ex
                        % errordlg('Can not set the input channels. Please connect VSA to the appropriate analyzer hardware, then try again.','Error')  
                    end
                end
            end
        else %----- communicating to VSA through SCPI
            
            % added by Tom Wychock tom.wychock@keysight.com
            % if debugVSACustomSetupFile is a valid path, load that file
            % command example: 
            % debugVSACustomSetupFile = 'C:\\Users\\username\\Desktop\\Preset1.setx'
            % to cancel, command: clear debugVSACustomSetupFile
            % if not, then perform as normal
            % this function is for channel setups that are not common
            % If debugVSACustomSetupFile exists or if not from recording, load it
            
            response = xquery(vsaApp, ':INPUT:DATA?');
            normalSetup = 1;
            if (evalin('base', 'exist(''debugVSACustomSetupFile'', ''var'')') && strncmp(response,'HW',2))
                try
                    errorQuery = xfprintf(vsaApp, sprintf([':MMEMory:LOAD:SETup "' evalin('base', 'debugVSACustomSetupFile') '"']));
                    %If error, set to default state
                    if errorQuery ~= 0
                        throw(ex)
                    end
                    xfprintf(vsaApp, ':INIT:PAUS');
                    normalSetup = 0;
                catch ex
                    errordlg('Incorrect File Setup. Presetting to stable state')
                    % If debugVSACustomSetupFile doesn't exist, act as it normally would
                end
            end
            if (normalSetup)
                if (length(varargin) >= 2)
                    ch = varargin{2};
                    if (varargin{1} == 0)
                        xfprintf(vsaApp, sprintf(':INPut:CHANnel:CONFigure:CUSTom "IQ_%d_%d"', ch(1), ch(2)));
                    else
                        xfprintf(vsaApp, sprintf(':INPut:CHANnel:CONFigure:CUSTom "%d"', ch(1)));
                    end
                else
                    % on a spectrum analyzer, where channel config = RF,
                    % don't try to change it
                    res = xquery(vsaApp, ':INPut:CHANnel:CONFigure?');
                    if (~strncmp(res, 'RF', 2))
                        if (varargin{1} == 0)
                            xfprintf(vsaApp, sprintf(':INPut:CHANnel:CONFigure IQ'));
                        else
                            xfprintf(vsaApp, sprintf(':INPut:CHANnel:CONFigure BB'), 1);  % will be RF for Spectrum Analyzer
                        end
                    end
                end
            end                            
        end
%-------------------------------------------------------------------------        
    case 'start'
        % start measurement
        % argument 1: continuous(1) or single(0) (optional)
        if (length(varargin) >= 1 && varargin{1} ~= 0)
            cont = true;
        else
            cont = false;
        end
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaMeas.IsContinuous = cont;
            vsaMeas.Restart();
            try
                vsaMeas.WaitForMeasurementDone(5000);
            catch
            end
        else
            xfprintf(vsaApp, sprintf(':INIT:CONT %d', cont));
            xfprintf(vsaApp, sprintf(':INIT:RESTART'));
        end
%-------------------------------------------------------------------------        
    case 'stop'
        % stop measurement
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaMeas.Pause();
        else
            xfprintf(vsaApp, sprintf(':INIT:PAUSE'));
        end
%-------------------------------------------------------------------------        
    case 'freq'
        % set center and span
        % argument 1: center frequency
        % argument 2: span (optional)
        % argument 3: points (optional)
        % argument 4: windowType (optional)
        % argument 5: average (optional)
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaFreq = vsaMeas.Frequency;
            vsaFreq.Center = varargin{1};
            if (length(varargin) >= 2)
                vsaFreq.Span = varargin{2};
            end
            if (length(varargin) >= 3)
                vsaFreq.Points = varargin{3};
            end
            if (length(varargin) >= 4)
                switch (varargin{4})
                    case 'flattop'
                        vsaFreq.Window = Agilent.SA.Vsa.WindowType.FlatTop;
                    case 'uniform'
                        vsaFreq.Window = Agilent.SA.Vsa.WindowType.Uniform;
                    otherwise
                        errordlg(sprintf('invalid window: %s', varargin{4}));
                end
            end
            if (length(varargin) >= 5)
                average = vsaMeas.Average;
                if (varargin{5} > 0)
                    average.Style = Agilent.SA.Vsa.AverageStyle.RmsExponential;
                    average.Count = varargin{5};
                    average.IsFast = false;
                    average.IsRepeat = false;
                else
                    average.Style = Agilent.SA.Vsa.AverageStyle.Off;
                end
            end
            if (length(varargin) >= 6)
                vsaTime = vsaMeas.Time;
                vsaTime.Length = varargin{6};
            end
        else %----- communicating to VSA through SCPI
            xfprintf(vsaApp, sprintf(':FREQ:CENT %g', varargin{1}));
            if (length(varargin) >= 2)
                xfprintf(vsaApp, sprintf(':FREQ:SPAN %g', varargin{2}));
            end
            if (length(varargin) >= 3)
                xfprintf(vsaApp, sprintf(':RBW:POINTS %d', varargin{3}));
            end
            if (length(varargin) >= 4)
                xfprintf(vsaApp, sprintf(':RBW:WINDOW "%s"', varargin{4}));
            end
            if (length(varargin) >= 5)
                if (varargin{5} > 0)
                    xfprintf(vsaApp, sprintf(':AVER:STYLE "RmsExponential"'));
                    xfprintf(vsaApp, sprintf(':AVER:COUNT %d', varargin{5}));
                    xfprintf(vsaApp, sprintf(':AVER:FAST 0'));
                    xfprintf(vsaApp, sprintf(':AVER:REPEAT 0'));
                else
                    xfprintf(vsaApp, sprintf(':AVER:STYLE "Off"'));
                end
            end
            if (length(varargin) >= 6)
                xfprintf(vsaApp, sprintf(':TIME:LENGTH %g', varargin{6}));
            end
        end
%-------------------------------------------------------------------------        
    case 'trace'
        % set layout and trace contents
        % argument 1: trace layout (2=2, 4=2x2, 6=2x3)
        % argument 2: 'DigDemod' or 'Chirp' (optional) or 'CQM'
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaDisp = vsaApp.Display;
            vsaTraces = vsaDisp.Traces;
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaInput = vsaMeas.Input;
            % added by Tom Wychock tom.wychock@keysight.com
            % if debugVSAChannel is a valid channel, use that channel
            % command example: 
            % debugVSAChannel = 2 
            % to cancel, command: clear debugVSAChannel
            % if not, then perform as normal
            % this function is for channel setups that are not common
            % If debugVSAChannel exists, load it
            if (evalin('base', 'exist(''debugVSAChannel'', ''var'')') && vsaInput.DataFrom == DataSource.Hardware)
                channel = evalin('base', 'debugVSAChannel');
                % Check if channel can be used in setup
                if channel < 0 || channel > vsaApp.Measurements.SelectedItem.Input.LogicalChannels.Count
                    errordlg('Custom Channel not valid. Setting to Channel 1','Error');
                    channel = '1';
                else
                    channel = (num2str(channel));
                end      
            else channel = '1';
            end
            
            switch varargin{1}
                case 1
                    vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,1,1);
                case 2
                    vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,1,2);
                case 4
                    vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.FillAll,2,2);
                    vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,2,2);
                case 6
                    vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.FillAll,2,3);
                    vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,2,3);
            end
            for i = varargin{1}:(vsaTraces.Count - 1)
                tr = vsaTraces.Item(i);
                tr.IsVisible = false;
            end
            if (length(varargin) >= 2)
                switch varargin{2}
                    case 'Tones'
                        tr = vsaTraces.Item(0); tr.DataName = strcat('Spectrum',channel);
                    case 'DigDemod'
                        tr = vsaTraces.Item(0); tr.DataName = strcat('IQ Meas Time',channel);
                        tr = vsaTraces.Item(1); tr.DataName = strcat('Spectrum',channel);     tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                        %tr = vsaTraces.Item(2); tr.DataName = 'Error Vector Time1'; 
                        tr = vsaTraces.Item(2); tr.DataName = strcat('IQ Meas Time',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.EyeI;
                        tr = vsaTraces.Item(3); tr.DataName = strcat('Syms/Errs',channel);
                        if (varargin{1} == 6)
                            tr = vsaTraces.Item(4); tr.DataName = strcat('Ch Frequency Response',channel);
                              tr.Format = Agilent.SA.Vsa.TraceFormatType.Real;
                            tr = vsaTraces.Item(5); tr.DataName = strcat('Ch Frequency Response',channel);
                              tr.Format = Agilent.SA.Vsa.TraceFormatType.Imaginary;
                        end
                    case 'CustomOFDM'
                        tr = vsaTraces.Item(0); tr.DataName = strcat('IQ Meas',channel);
                        tr = vsaTraces.Item(1); tr.DataName = strcat('Spectrum',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                        tr = vsaTraces.Item(2); tr.DataName = strcat('RMS Error Vector Spectrum',channel); 
                        tr = vsaTraces.Item(3); tr.DataName = strcat('OFDM Error Summary',channel);
                        if (varargin{1} == 6)
                            tr = vsaTraces.Item(4); tr.DataName = strcat('Ch Frequency Response',channel);
                              tr.Format = Agilent.SA.Vsa.TraceFormatType.Real;
                            tr = vsaTraces.Item(5); tr.DataName = strcat('Ch Frequency Response',channel);
                              tr.Format = Agilent.SA.Vsa.TraceFormatType.Imaginary;
                        end
                    case 'Chirp'
                        tr = vsaTraces.Item(0); tr.DataName = strcat('Spectrum',channel);  tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                        tr = vsaTraces.Item(1); tr.DataName = strcat('Main Time',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                        tr = vsaTraces.Item(2); tr.DataName = strcat('Main Time',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.UnwrapPhase;
                        tr = vsaTraces.Item(3); tr.DataName = strcat('Main Time',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.GroupDelay;
                    case 'CQM'
                        tr = vsaTraces.Item(0); tr.DataName = strcat('Spectrum',channel);  tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                        tr = vsaTraces.Item(1); tr.DataName = strcat('Stimulus Definition',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                        tr = vsaTraces.Item(2); tr.DataName = strcat('Summary',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.UnwrapPhase;
                        tr = vsaTraces.Item(3); tr.DataName = strcat('Ch Frequency Response',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                        tr = vsaTraces.Item(4); tr.DataName = strcat('Ch Frequency Response',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.Real;
                        tr = vsaTraces.Item(5); tr.DataName = strcat('Ch Frequency Response',channel); tr.Format = Agilent.SA.Vsa.TraceFormatType.Imaginary;                       
                end
            end
        else %----- communicating to VSA through SCPI
            
            % added by Tom Wychock tom.wychock@keysight.com
            % if debugVSAChannel is a valid channel, use that channel
            % command example: 
            % debugVSAChannel = 2 
            % to cancel, command: clear debugVSAChannel
            % if not, then perform as normal
            % this function is for channel setups that are not common
            % If debugVSAChannel exists, load it
            
            response = xquery(vsaApp, ':INPUT:DATA?');
            
            if (evalin('base', 'exist(''debugVSAChannel'', ''var'')') && strcmp(response(1:2),'HW'))
                channel = evalin('base', 'debugVSAChannel');
                % Check if channel can be used in setup by comparing count
                % with channel set
                % Check channel count
                % Find number of channels by finding number of commas in
                % channel string, count is commas count plus 1
                if channel < 0 || channel > length(strfind(xquery(vsaApp, ':INPut:CHANnel:CONFigure:CUSTom?'),','))+1
                    errordlg('Custom Channel not valid. Setting to Channel 1','Error');
                    channel = '1';
                else
                    channel = (num2str(channel));
                end      
            else
                channel = '1';
            end
                
            switch varargin{1}
                case 1
                    xfprintf(vsaApp, ':DISP:LAYOUT 1,1');
                case 2
                    xfprintf(vsaApp, ':DISP:LAYOUT 2,1');
                case 4
                    xfprintf(vsaApp, ':DISP:LAYOUT 2,2');
                case 6
                    xfprintf(vsaApp, ':DISP:LAYOUT 2,3');
            end
            numTr = str2double(xquery(vsaApp, ':TRAC:COUNT?'));
            for i = (varargin{1} + 1):numTr
                xfprintf(vsaApp, sprintf(':TRAC%d:VISIBLE 0', i));
            end
            if (length(varargin) >= 2)
                switch varargin{2}
                    case 'Tones'
                        xfprintf(vsaApp, sprintf(':TRAC1:DATA:NAME "Spectrum%s"', channel));
                        xfprintf(vsaApp, sprintf(':TRAC1:FORMAT "LogMagnitude"'));
                    case 'DigDemod'
                        xfprintf(vsaApp, sprintf(':TRAC1:DATA:NAME "IQ Meas Time%s"', channel));
                        xfprintf(vsaApp, sprintf(':TRAC1:FORMAT "Constellation"'));
                        xfprintf(vsaApp, sprintf(':TRAC2:DATA:NAME "Spectrum%s"', channel));
                        xfprintf(vsaApp, sprintf(':TRAC2:FORMAT "LogMagnitude"'));
                        xfprintf(vsaApp, sprintf(':TRAC3:DATA:NAME "IQ Meas Time%s"', channel));
                        xfprintf(vsaApp, sprintf(':TRAC3:FORMAT "EyeI"'));
                        xfprintf(vsaApp, sprintf(':TRAC4:DATA:NAME "Syms/Errs%s"', channel));
                        if (varargin{1} == 6)
                            xfprintf(vsaApp, sprintf(':TRAC5:DATA:NAME "Ch Frequency Response%s"', channel));
                            xfprintf(vsaApp, sprintf(':TRAC5:FORMAT "Real"'));
                            xfprintf(vsaApp, sprintf(':TRAC6:DATA:NAME "Ch Frequency Response%s"', channel));
                            xfprintf(vsaApp, sprintf(':TRAC6:FORMAT "Imaginary"'));
                        end
                    case 'CustomOFDM'
                        xfprintf(vsaApp, sprintf(':TRAC1:DATA:NAME "IQ Meas Time%s"', channel));
                        xfprintf(vsaApp, sprintf(':TRAC2:DATA:NAME "Spectrum%s"', channel));
                        xfprintf(vsaApp, sprintf(':TRAC2:FORMAT "LogMagnitude"'));
                        xfprintf(vsaApp, sprintf(':TRAC3:DATA:NAME "%s"', strcat('RMS Error Vector Spectrum',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC4:DATA:NAME "%s"', strcat('OFDM Error Summary',channel)));
                        if (varargin{1} == 6)
                            xfprintf(vsaApp, sprintf(':TRAC5:DATA:NAME "Ch Frequency Response%s"', channel));
                            xfprintf(vsaApp, sprintf(':TRAC5:FORMAT "Real"'));
                            xfprintf(vsaApp, sprintf(':TRAC6:DATA:NAME "Ch Frequency Response%s"', channel));
                            xfprintf(vsaApp, sprintf(':TRAC6:FORMAT "Imaginary"'));
                        end
                    case 'Chirp'
                        xfprintf(vsaApp, sprintf(':TRAC1:DATA:NAME "%s"', strcat('Spectrum',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC1:FORMAT "%s"', 'LogMagnitude'));
                        xfprintf(vsaApp, sprintf(':TRAC2:DATA:NAME "%s"', strcat('Main Time',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC2:FORMAT "%s"', 'LogMagnitude'));
                        xfprintf(vsaApp, sprintf(':TRAC3:DATA:NAME "%s"', strcat('Main Time',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC3:FORMAT "%s"', 'UnwrapPhase'));
                        xfprintf(vsaApp, sprintf(':TRAC4:DATA:NAME "%s"', strcat('Main Time',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC4:FORMAT "%s"', 'GroupDelay'));
                    case 'CQM'
                        xfprintf(vsaApp, sprintf(':TRAC1:DATA:NAME "%s"', strcat('Spectrum',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC1:FORMAT "%s"', 'LogMagnitude'));
                        xfprintf(vsaApp, sprintf(':TRAC2:DATA:NAME "%s"', strcat('Stimulus Definition',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC2:FORMAT "%s"', 'LogMagnitude'));
                        xfprintf(vsaApp, sprintf(':TRAC3:DATA:NAME "%s"', strcat('Summary',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC3:FORMAT "%s"', 'UnwrapPhase'));
                        xfprintf(vsaApp, sprintf(':TRAC4:DATA:NAME "%s"', strcat('Ch Frequency Response',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC4:FORMAT "%s"', 'LogMagnitude'));
                        xfprintf(vsaApp, sprintf(':TRAC5:DATA:NAME "%s"', strcat('Ch Frequency Response',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC5:FORMAT "%s"', 'Real'));
                        xfprintf(vsaApp, sprintf(':TRAC6:DATA:NAME "%s"', strcat('Ch Frequency Response',channel)));
                        xfprintf(vsaApp, sprintf(':TRAC6:FORMAT "%s"', 'Imaginary'));                                    
                end
            end
        end
%-------------------------------------------------------------------------        
    case 'autoscale'
        % autoscale the selected traces
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaDisp = vsaApp.Display;
            vsaTraces = vsaDisp.Traces;
            if (length(varargin) < 1)
                items = 1:vsaTraces.Count;
            else
                for i=1:length(varargin)
                    items(i) = varargin{i};
                end
            end
            for i=1:length(items)
                tr = vsaTraces.Item(items(i)-1);
                tr.YScaleAuto();
            end
        else %----- communicating to VSA through SCPI
            % autoscale all traces
            xfprintf(vsaApp, sprintf(':TRAC:Y:AUT'));
            % :TRAC:Y:AUT  *should* do this for all traces, but that does
            % not seem to work reliably, so I'll do it 1 by 1
            numTr = str2double(xquery(vsaApp, ':TRAC:COUNT?'));
            for i = 1:numTr
                vis = str2double(xquery(vsaApp, sprintf(':TRAC%d:VIS?', i)));
                if (vis)
                    xfprintf(vsaApp, sprintf(':TRAC%d:Y:AUT', i));
                end
            end
        end
%-------------------------------------------------------------------------        
    case 'DigDemod'
        % set Digital Demod parameters
        % argument 1: modulation type
        % argument 2: symbol rate
        % argument 3: filter type (optional)
        % argument 4: filter alpha/BT (optional)
        % argument 5: result length (optional)

        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaDemod = getDigDemod(vsaApp);
            customFormat = false; % added by Tom Wychock tom.wychock@keysight.com
            %Set the VSA measurement parameters
            switch varargin{1}                               
                case 'BPSK';   format = Agilent.SA.Vsa.DigitalDemod.Format.Bpsk;
                case 'BPSK_X'; format = Agilent.SA.Vsa.DigitalDemod.Format.Bpsk;
                case 'QPSK';   format = Agilent.SA.Vsa.DigitalDemod.Format.Qpsk;
                case 'OQPSK';  format = Agilent.SA.Vsa.DigitalDemod.Format.OffsetQpsk;
                case '8-PSK';  format = Agilent.SA.Vsa.DigitalDemod.Format.Psk8;
                case 'QAM4';   format = Agilent.SA.Vsa.DigitalDemod.Format.Qpsk;
                case 'QAM16';  format = Agilent.SA.Vsa.DigitalDemod.Format.Qam16;
                case 'QAM32';  format = Agilent.SA.Vsa.DigitalDemod.Format.Qam32;
                case 'QAM64';  format = Agilent.SA.Vsa.DigitalDemod.Format.Qam64;
                case 'QAM128'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam128;
                case 'QAM256'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam256;
                case 'QAM512'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam512;
                case 'QAM1024'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam1024;
                case 'QAM2048'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam2048;
                case 'QAM4096'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam4096;
                case 'APSK16'; format = Agilent.SA.Vsa.DigitalDemod.Format.Apsk16;
                    vsaDemod.ApskRing2Ratio = 2.6;
                case 'APSK32'; format = Agilent.SA.Vsa.DigitalDemod.Format.Apsk32;
                    vsaDemod.ApskRing2Ratio = 2.84;
                    vsaDemod.ApskRing3Ratio = 5.27;
                case 'PAM4'
                    customFormat = true;
                    format = Agilent.SA.Vsa.DigitalDemod.Format.CustomApsk;
                    rings = 2;
                    apskMag = [1 3];
                    apskStat = [2 2];
                    apskPhase = [0 0];    
                case 'PAM8'
                    customFormat = true;
                    format = Agilent.SA.Vsa.DigitalDemod.Format.CustomApsk;
                    rings = 4;
                    apskMag = [1 3 5 7];
                    apskStat = [2 2 2 2];
                    apskPhase = [0 0 0 0];    
                case 'CPM'
                    format = Agilent.SA.Vsa.DigitalDemod.Format.CpmFM;
                    vsaDemod.CpmIndex = Agilent.SA.Vsa.DigitalDemod.CpmIndex.MinimumShiftKeying;
                % added by Tom Wychock tom.wychock@keysight.com
                % using custom APSK, create a QAM8 constellation
                % Custom APSK
                case 'QAM8'
                    customFormat = true;
                    format = Agilent.SA.Vsa.DigitalDemod.Format.CustomApsk;
                    rings = 2;
                    apskMag = [1 2];
                    apskStat = [4 4];
                    apskPhase = [0 45];    
                    
                otherwise; errordlg(['unknown format: ' varargin{1}]);
            end
            try
                vsaDemod.Format = format;
                vsaDemod.SymbolRate = varargin{2};
                vsaDemod.IsFrequencyMirrored = false;                
                vsaDemod.IsPulseSearchEnabled = false;
                
                % added by Tom Wychock tom.wychock@keysight.com
                % using custom APSK, create a QAM8 constellation
                % Custom APSK
                if customFormat
                   for n = 1:rings
                       vsaDemod.CustomApskRings.Item(n-1).IsRingEnabled = true; 
                       vsaDemod.CustomApskRings.Item(n-1).Magnitude = apskMag(n);
                       vsaDemod.CustomApskRings.Item(n-1).NumberOfStates = apskStat(n);
                       vsaDemod.CustomApskRings.Item(n-1).Phase = apskPhase(n);
                   end
                   for n = rings+1:8
                       vsaDemod.CustomApskRings.Item(n-1).IsRingEnabled = false; 
                       vsaDemod.CustomApskRings.Item(n-1).Magnitude = 0;
                       vsaDemod.CustomApskRings.Item(n-1).NumberOfStates = 1;
                       vsaDemod.CustomApskRings.Item(n-1).Phase = 0;
                   end
                end
            catch ex
                if (isprop(ex, 'stack'))
                    msg = sprintf('Error controlling VSA - please try again\n%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
                else
                    msg = sprintf('Error controlling VSA - please try again\n%s', ex.message);
                end
                errordlg(msg);
            end
            if (length(varargin) >= 3)
                switch varargin{3}
                    case {'Root Raised Cosine' 'Square Root Raised Cosine' 'RRC'}
                        mfilter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.RootRaisedCosine;
                        rfilter = Agilent.SA.Vsa.DigitalDemod.ReferenceFilter.RaisedCosine;
                    case {'Raised Cosine' 'RC'}
                        mfilter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.None;
                        rfilter = Agilent.SA.Vsa.DigitalDemod.ReferenceFilter.RaisedCosine;
                    case 'Gaussian'
                        mfilter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.None;
                        rfilter = Agilent.SA.Vsa.DigitalDemod.ReferenceFilter.Gaussian;
                    case 'Rectangular'
                        mfilter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.None;
                        rfilter = Agilent.SA.Vsa.DigitalDemod.ReferenceFilter.Rectangular;
                    case 'None'
                        mfilter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.None;
                        rfilter = Agilent.SA.Vsa.DigitalDemod.ReferenceFilter.RectangularOneSymbolDuration;
                end
                % CPM seems to work best with 3RC filter
                if (format == Agilent.SA.Vsa.DigitalDemod.Format.CpmFM)
                    rfilter = Agilent.SA.Vsa.DigitalDemod.ReferenceFilter.RaisedCosineThreeSymbolDuration;
                end
                vsaDemod.MeasurementFilter = mfilter;
                vsaDemod.ReferenceFilter = rfilter;
            end
            vsaDemod.PointsPerSymbol = 5;
            if (length(varargin) >= 4)
                vsaDemod.FilterAlphaBT = varargin{4};
            end
            if (length(varargin) >= 5)
                vsaDemod.ResultLength = varargin{5};
            end
        else %----- communicating to VSA through SCPI
            xfprintf(vsaApp, ':MEAS:CONF DDEMod');
            switch varargin{1}
                case 'BPSK';   format = 'Bpsk';
                case 'BPSK_X'; format = 'Bpsk';
                case 'QPSK';   format = 'Qpsk';
                case 'OQPSK';  format = 'OffsetQpsk';
                case '8-PSK';  format = 'Psk8';
                case 'QAM4';   format = 'Qpsk';
                case 'QAM16';  format = 'Qam16';
                case 'QAM32';  format = 'Qam32';
                case 'QAM64';  format = 'Qam64';
                case 'QAM128'; format = 'Qam128';
                case 'QAM256'; format = 'Qam256';
                case 'QAM512'; format = 'Qam512';
                case 'QAM1024'; format = 'Qam1024';
                case 'QAM2048'; format = 'Qam2048';
                case 'QAM4096'; format = 'Qam4096';
                case 'APSK16'; format = 'Apsk16';
                    xfprintf(vsaApp, ':DDEM:ADV:APSK:R2Ratio 2.6');
                case 'APSK32'; format = 'Apsk32';
                    xfprintf(vsaApp, ':DDEM:ADV:APSK:R2Ratio 2.84');
                    xfprintf(vsaApp, ':DDEM:ADV:APSK:R3Ratio 5.27');
                case 'PAM4'; format = 'CustomApsk';
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING1:MAGN 1; :DDEM:CAPSk:RING2:MAGN 3');
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING1:STAT 2; :DDEM:CAPSk:RING2:STAT 2');
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING1:ENAB 1; :DDEM:CAPSk:RING2:ENAB 1');
                case 'PAM8'; format = 'CustomApsk';
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING1:MAGN 1; :DDEM:CAPSk:RING2:MAGN 3');
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING3:MAGN 5; :DDEM:CAPSk:RING4:MAGN 7');
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING1:STAT 2; :DDEM:CAPSk:RING2:STAT 2');
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING3:STAT 2; :DDEM:CAPSk:RING4:STAT 2');
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING1:ENAB 1; :DDEM:CAPSk:RING2:ENAB 1');
                    xfprintf(vsaApp, ':DDEM:CAPSk:RING3:ENAB 1; :DDEM:CAPSk:RING4:ENAB 1');
                case 'CPM'; format = 'CpmFM';
                    xfprintf(vsaApp, ':DDEM:ADV:CPMindex "MinimumShiftKeying"');
                
                % added by Tom Wychock tom.wychock@keysight.com
                % using custom APSK, create a QAM8 constellation
                %Custom APSK
                case 'QAM8'  
                    
                    format = 'CustomApsk';
                    
                    rings = 2;
                    apskMag = [1 2];
                    apskStat = [4 4];
                    apskPhase = [0 45];
                    
                    for n = 1:rings
                        xfprintf(vsaApp, [':DDEMod:CAPSk:RING',num2str(n),':ENABle 1']);
                        xfprintf(vsaApp, [':DDEMod:CAPSk:RING',num2str(n),':MAGNitude ',num2str(apskMag(n))]);
                        xfprintf(vsaApp, [':DDEMod:CAPSk:RING',num2str(n),':PHASe ',num2str(apskPhase(n))]);
                        xfprintf(vsaApp, [':DDEMod:CAPSk:RING',num2str(n),':STATes ',num2str(apskStat(n))]);
                    end
                    for n = rings+1:8
                        xfprintf(vsaApp, [':DDEMod:CAPSk:RING',num2str(n),':ENABle 0']);
                        xfprintf(vsaApp, [':DDEMod:CAPSk:RING',num2str(n),':MAGNitude 0']);
                        xfprintf(vsaApp, [':DDEMod:CAPSk:RING',num2str(n),':PHASe 0']);
                        xfprintf(vsaApp, [':DDEMod:CAPSk:RING',num2str(n),':STATes 1']);
                    end
    
                otherwise; errordlg(['unknown format: ' varargin{1}]);
            end
            xfprintf(vsaApp, sprintf(':DDEM:MOD "%s"', format));
            xfprintf(vsaApp, sprintf(':DDEM:SRATe %g', varargin{2}));
            xfprintf(vsaApp, ':FREQ:MIRR 0');
            xfprintf(vsaApp, ':DDEM:SEAR:PULS 0');
            if (length(varargin) >= 3)
                switch varargin{3}
                    case {'Root Raised Cosine' 'Square Root Raised Cosine' 'RRC'}
                        mfilter = 'RootRaisedCosine';
                        rfilter = 'RaisedCosine';
                    case {'Raised Cosine' 'RC'}
                        mfilter = 'None';
                        rfilter = 'RaisedCosine';
                    case 'Gaussian'
                        mfilter = 'None';
                        rfilter = 'Gaussian';
                    case 'Rectangular'
                        mfilter = 'None';
                        rfilter = 'Rectangular';
                    case 'None'
                        mfilter = 'None';
                        rfilter = 'RectangularOneSymbolDuration';
                end
                % CPM seems to work best with 3RC filter
                if (strcmp(format, 'CpmFM'))
                    rfilter = 'RaisedCosineThreeSymbolDuration';
                end
                xfprintf(vsaApp, sprintf(':DDEM:FILT "%s"', mfilter));
                xfprintf(vsaApp, sprintf(':DDEM:FILT:REF "%s"', rfilter));
            end
            xfprintf(vsaApp, ':DDEM:SYMB:POINts 5');
            if (length(varargin) >= 4)
                xfprintf(vsaApp, sprintf(':DDEM:FILT:ABT %g', varargin{4}));
            end
            if (length(varargin) >= 5)
                xfprintf(vsaApp, sprintf(':DDEM:RLEN %g', varargin{5}));
            end
        end
%-------------------------------------------------------------------------        
    case 'trigger'
        % set Trigger
        % argument 1: trigger mode ('FreeRun' or 'Channel')
        % argument 2: Level
        % argument 3: Delay
        % argument 4: Holdoff
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            switch varargin{1}
                case 'FreeRun'; triggerStyle = Agilent.SA.Vsa.TriggerStyle.Auto;
                case 'Channel'; triggerStyle = Agilent.SA.Vsa.TriggerStyle.Level;
                    chan = char(vsaApp.Display.Traces.Item(0).DataName);
                    chan = str2double(chan(end));
                    
            end
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaInput = vsaMeas.Input;
            vsaTrigger = vsaInput.Recording.Trigger;
            vsaTrigger.Channel = chan;
            vsaTrigger.Style = triggerStyle;
            vsaTrigger.Level = varargin{2};
            vsaTrigger.Delay = varargin{3};
            vsaTrigger.Holdoff = varargin{4};
            vsaTrigger = vsaInput.Trigger;
            vsaTrigger.Style = triggerStyle;
            vsaTrigger.Level = varargin{2};
            vsaTrigger.Delay = varargin{3};
            vsaTrigger.Holdoff = varargin{4};
        else %----- communicating to VSA through SCPI
            switch varargin{1}
                case 'FreeRun'; triggerStyle = 'Auto';
                case 'Channel'; triggerStyle = 'Level';
                    
                    %xfprintf(vsaApp, sprintf(':INPut:TRIGger:CHANnel"%s"', triggerStyle));
            end
            xfprintf(vsaApp, sprintf(':INP:TRIG:STYLe "%s"', triggerStyle));
            xfprintf(vsaApp, sprintf(':INP:TRIG:LEV %g', varargin{2}));
            xfprintf(vsaApp, sprintf(':INP:TRIG:DEL %g', varargin{3}));
            xfprintf(vsaApp, sprintf(':INP:TRIG:HOLD %g', varargin{4}));
            xfprintf(vsaApp, sprintf(':INP:REC:TRIG:STYLe "%s"', triggerStyle));
            xfprintf(vsaApp, sprintf(':INP:REC:TRIG:LEV %g', varargin{2}));
            xfprintf(vsaApp, sprintf(':INP:REC:TRIG:DEL %g', varargin{3}));
            xfprintf(vsaApp, sprintf(':INP:REC:TRIG:HOLD %g', varargin{4}));
        end
%-------------------------------------------------------------------------        
    case 'equalizer'
        % set up equalizer
        % argument 1: on/off (1/0)
        % argument 2: filterLength (optional)
        % argument 3: convergence (optional)
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaDemod = getDigDemod(vsaApp);
            try
                vsaDemod.IsEqualized = varargin{1};
                if (varargin{1})
                    vsaDemod.EqualizerMode = Agilent.SA.Vsa.DigitalDemod.EqualizerMode.Run;
                    vsaDemod.EqualizerReset;
                end
                if (length(varargin) >= 2)
                    vsaDemod.EqualizerFilterLength = varargin{2};
                end
                if (length(varargin) >= 3)
                    vsaDemod.EqualizerConvergence = varargin{3};
                end
            catch ex
                if (isprop(ex, 'stack'))
                    msg = sprintf('Error controlling VSA (set EQ) - please try again\n%s\n%s, line %d', ex.message, ex.stack(1).name, ex.stack(1).line);
                else
                    msg = sprintf('Error controlling VSA (set EQ) - please try again\n%s', ex.message);
                end
                errordlg(msg);
            end
        else %----- communicating to VSA through SCPI
            xfprintf(vsaApp, sprintf(':DDEM:COMP:EQU %d', varargin{1}));
            if (length(varargin) >= 2)
                xfprintf(vsaApp, sprintf(':DDEM:COMP:EQU:LENG %d', varargin{2}));
            end
            if (length(varargin) >= 3)
                xfprintf(vsaApp, sprintf(':DDEM:COMP:EQU:CONV %d', varargin{3}));
            end
            xfprintf(vsaApp, sprintf(':DDEM:COMP:EQU:MODE "Run"'));
            xfprintf(vsaApp, sprintf(':DDEM:COMP:EQU:RESET'));
        end
%-------------------------------------------------------------------------        
    case 'readEqData'
        % get equalizer data and write ampCorr file
        % argument 1: add new measurement to existing correction (re-calibration) (Optional)
        % argument 2: carrierOffset to be subtracted from measurements (Optional)
        result = -1;
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaDisp = vsaApp.Display;
            vsaTraces = vsaDisp.Traces;
            tr = vsaTraces.Item(4);
            x = (tr.DoubleData(TraceDataSelect.X, false).double)';
            yreal = (tr.DoubleData(TraceDataSelect.Y, false).double)';
            tr = vsaTraces.Item(5);
            yimag = (tr.DoubleData(TraceDataSelect.Y, false).double)';
        else %----- communicating to VSA through SCPI
            % make sure the equalizer does not change while we read
            hMsg = msgbox('Reading equalizer data from VSA...');
            xfprintf(vsaApp, sprintf(':DDEM:COMP:EQU:MODE "Hold"'));
            xfprintf(vsaApp, sprintf(':FORM REAL64'));
            x = xbinblockread(vsaApp, 'double', sprintf(':TRAC5:DATA:X?'), 'big-endian');
            yreal = xbinblockread(vsaApp, 'double', sprintf(':TRAC5:DATA:Y?'), 'big-endian');
            yimag = xbinblockread(vsaApp, 'double', sprintf(':TRAC6:DATA:Y?'), 'big-endian');
            try
                close(hMsg);
            catch
            end
            if (isempty(x) || isempty(yreal) || isempty(yimag))
                errordlg('Could not read Equalizer data from VSA');
                return;
            end
        end
        
        % shift carrier offset if necessary
        if (length(varargin) >= 2)
            x = x - varargin{2};
        end
        y = 1 ./ complex(yreal, yimag);
        ydB = 20 * log10(abs(y));
        % combine with existing calibration data
        clear acs;
        acs.ampCorr = [x zeros(length(x),1) ones(length(x),1)];
        if (length(varargin) >= 1 && varargin{1} ~= 0)
            % in case of re-calibration, read the old cal values
            try
                % load the full correction file
                acs = load(iqampCorrFilename());
            catch
                clear acs;
            end
            if (isfield(acs, 'ampCorr'))
                % take care of ampCorrMode - flip or reset ampCorr
                % accordingly
                if (isfield(acs, 'ampCorrMode'))
                    ampCorrMode = acs.ampCorrMode;
                else
                    ampCorrMode = -1;   % old style: de-embed
                end
                if (size(acs.ampCorr,2) <= 2)  % no complex correction available
                    acs.ampCorr(:,3) = 10.^(acs.ampCorr(:,2)/20);
                end
                if (ampCorrMode == 1)
                    acs.ampCorr(:,3) = conj(acs.ampCorr(:,3));
                    acs.ampCorr(:,2) = -1 * acs.ampCorr(:,2);
                elseif (ampCorrMode == 0)
                    acs.ampCorr(:,3) = ones(size(acs.ampCorr, 1), 1);
                    acs.ampCorr(:,2) = zeros(size(acs.ampCorr, 1), 1);
                end
                % if the list of frequencies does not match,
                % interpolate the existing correction values
                if (~isequal(acs.ampCorr(:,1), x))
                    % but first check if new frequencies are positive & negative
                    % and old frequencies are only positive
                    if (min(acs.ampCorr(:,1)) >= 0 && min(x) < 0 && max(x) > 0)
                        freq = acs.ampCorr(:,1);
                        if (freq(1) == 0)            % don't duplicate zero-frequency
                            startIdx = 2;
                        else
                            startIdx = 1;
                        end
                        freq = [-1 * flipud(freq); freq(startIdx:end)];
                        mag = [flipud(acs.ampCorr(:,2)); acs.ampCorr(startIdx:end,2)];
                        if (size(acs.ampCorr,2) >= 3)
                            lincorr = [flipud(conj(acs.ampCorr(:,3))); acs.ampCorr(startIdx:end,3)];
                        else
                            lincorr = 10.^(mag/20);
                        end
                        acs.ampCorr = [freq mag lincorr];
                    end
                    % interpolate the existing correction values
                    newCol2 = interp1(acs.ampCorr(:,1), acs.ampCorr(:,2), x, 'pchip', 0);
                    if (size(acs.ampCorr,2) >= 3)
                        newCol3 = interp1(acs.ampCorr(:,1), acs.ampCorr(:,3), x, 'pchip', 1);
                    else
                        newCol3 = 10.^(newCol2/20);
                    end
                    acs.ampCorr = [x newCol2 newCol3];
                end
            else
                acs.ampCorr = [x zeros(length(x),1) ones(length(x),1)];
            end
        end
        % add new corrections to existing ones
        % dB's add up, complex (linear) corrections are multiplied
        acs.ampCorr = [x (acs.ampCorr(:,2)+ydB) (acs.ampCorr(:,3).*y)];
        acs.ampCorrMode = -1;
        % and save
        save(iqampCorrFilename(), '-struct', 'acs');
        result = 0;
%-------------------------------------------------------------------------        
    case 'mtone'
        % measure magnitude of tones
        % argument 1: vector of tones
        % argument 2: fc
        % argument 3: recalibrate
        result = [];
        tones = varargin{1};
        fc = varargin{2};
        recal = varargin{3};
        mag = zeros(length(tones),1);
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaDisp = vsaApp.Display;
            vsaTraces = vsaDisp.Traces;
            tr = vsaTraces.Item(0);
            marker = tr.Markers.Item(0);
            marker.IsVisible = true;
            for i = 1:length(tones)
                marker.XData = tones(i) + fc;
                mag(i) = marker.Y;
            end
            marker.IsVisible = false;
        else %----- communicating to VSA through SCPI
            xfprintf(vsaApp, sprintf(':TRAC1:MARK1:ENAB 1'));
            for i = 1:length(tones)
                xfprintf(vsaApp, sprintf(':TRAC1:MARK1:X %g', tones(i) + fc));
                mag(i) = str2double(xquery(vsaApp, ':TRAC1:MARK1:Y?'));
            end
            xfprintf(vsaApp, sprintf(':TRAC1:MARK1:ENAB 0'));
        end
            
        arbConfig = loadArbConfig();
        usePerChannelCorr = 0;  % store in complex response for now
        chs = [1];   % vector of channel numbers on which the signal was downloaded
        % if a list of frequencies is specified, use them as a starting point for a
        % new correction. Otherwise use existing correction is used as a starting
        % point. The measurement is added to the existing correction in this case.
        [acs, oldCorr, err] = getOldCorr(arbConfig, tones, chs, recal, usePerChannelCorr);
        if (err)
            return;
        end
        
        if (isfield(acs, 'absMagnitude') && acs.absMagnitude)
            meas = mag - acs.absMagnitude;
        else
            % calculate deviation from average
            meas = mag - sum(mag)/length(mag);
        end
        % subtract from previous correction
        newCorr = oldCorr - meas;

        %% update correction file
        update = 1;
        if (update)
            % save updated correction file
            if (usePerChannelCorr)
                if (~updatePerChannelCorr(acs, chs, tones, newCorr))
                    return;
                end
            else
                % use ampCorr structure for calibration
                acs.ampCorr = [tones newCorr];
                save(iqampCorrFilename(), '-struct', 'acs');
            end
        end
        result = 0;
%-------------------------------------------------------------------------        
    case 'bitmap'   %tom.wychock@keysight.com
        % take bitmap of screen and save as .png (compression with jpg
        % causes the screenshots to not look as clean)
        % note, make sure screen is visible or bitmaps will have overlapped
        % windows in them
        % argument 1: file name
        result = [];
        filename = varargin{1}; %Filename
        try
            if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))  %If API
                vsaDisp = vsaApp.Display;

                bitmaptypes = NET.createArray('Agilent.SA.Vsa.BitmapType',1);
                bitmaptypes(1) = Agilent.SA.Vsa.BitmapType.Png;

                vsaDisp.Printer.SaveBitmap(filename,bitmaptypes(1));

            else %----- communicating to VSA through SCPI
                command = sprintf(':MMEMory:STORe:BITMap "%s", "Png"',filename);
                if xfprintf(vsaApp,command) == -1
                    throw(ex)
                end
            end
        catch
            result = -1;
            return;
        end
        
        result = 0;
        
%-------------------------------------------------------------------------
    case 'minimize' %tom.wychock@keysight.com
        % take bitmap of screen
        % argument 1: file name
        result = [];
        try
            if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))  %If API


            else %----- communicating to VSA through SCPI
                xfprintf(vsaApp,':SYSTem:VSA:WINDow:SHOW 2,1');              
            end
        catch
            result = -1;
            return;
        end
        
        result = 0;
        
%-------------------------------------------------------------------------
    case 'maximize' %tom.wychock@keysight.com
        % take bitmap of screen
        % argument 1: file name
        result = [];
        
        try
            if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))  %If API


            else %----- communicating to VSA through SCPI
                xfprintf(vsaApp,':SYSTem:VSA:WINDow:SHOW 3,1');                
            end
        catch
            result = -1;
            return;
        end
        
        result = 0;
        
%-------------------------------------------------------------------------
    case 'defaultview'  %tom.wychock@keysight.com
        % take bitmap of screen
        % argument 1: file name
        result = [];
        try
            if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))  %If API


            else %----- communicating to VSA through SCPI
                xfprintf(vsaApp,':SYSTem:VSA:WINDow:SHOW 1,1');                
            end
        catch
            result = -1;
            return;
        end
        
        result = 0;

%-------------------------------------------------------------------------        
    case 'readEVM'  %tom.wychock@keysight.com
        % read EVM
        result = [];
        try
            if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
                vsaDisp = vsaApp.Display;
                vsaTraces = vsaDisp.Traces;
                tr = vsaTraces.Item(3);

                result = tr.MeasurementData.Summary('EvmRms');

            else %----- communicating to VSA through SCPI
                result = str2num(xquery(vsaApp,':TRACe4:DATA:TABLe? "EvmRms"'));
            end
        catch
            result = -1
            return;
        end
        
%-------------------------------------------------------------------------        
    case 'holdEqualizer'  %tom.wychock@keysight.com
        % hold equalizer
        result = [];
        try
            if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
                vsaDemod = getDigDemod(vsaApp);
                vsaDemod.EqualizerMode = Agilent.SA.Vsa.DigitalDemod.EqualizerMode.Hold
                
            else %----- communicating to VSA through SCPI
                xfprintf(vsaApp, sprintf(':DDEM:COMP:EQU:MODE "Hold"'));
            end
        catch
            result = -1
            return;
        end
        
%-------------------------------------------------------------------------        
    case 'loadSetup'  %tom.wychock@keysight.com
        % loads custom setup file
        result = [];
        filename = varargin{1}; %Filename
        
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaInput = vsaMeas.Input;
            types = vsaInput.LogicalChannelTypesSupported;
            try
                vsaApp.RecallSetup(filename);
                vsaMeas.Pause();   
            catch
                errordlg('Settings File Error.');
                result = -1;
                return;
            end
        else %----- communicating to VSA through SCPI
            try
                if xfprintf(vsaApp, sprintf(':MMEMory:LOAD:SETup "%s"',filename)) == -1  
                   throw(ex)
                end
            catch ex
               errordlg('Settings File Error.');
               result = -1;
               return;
            end
            
        end
        
        result = 0;
        
%-------------------------------------------------------------------------        
    case 'clearPersistance'  %tom.wychock@keysight.com
        % clears persistance on all traces (needed for
        result = [];
        
        
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaInput = vsaMeas.Input;
            try
                for n = 1:vsaApp.Display.Traces.Count
                    vsaApp.Display.Traces.Item(n-1).Spectrogram.Style = Agilent.SA.Vsa.TracePersistence.Off;
                end  
            catch
                result = -1;
                return;
            end    
        else %----- communicating to VSA through SCPI
            try
                numberOfTraces = xquery(vsaApp,':TRACe:COUNt?');
                for n = 1:str2num(numberOfTraces)
                    xfprintf(vsaApp,sprintf(':TRACe%g:SPECtrogram:STYLe OFF',n));
                end
            catch ex
               result = -1;
               return;
            end
            
        end
        
        result = 0;        

%-------------------------------------------------------------------------        
    case 'readPeakToPeak'  %tom.wychock@keysight.com
        % reads peak to peak of selected data type and format
        result = [];
        
        traceName = varargin{1}; %Trace Name
        traceFormat = varargin{2}; %Trace Format
        
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaTraces = vsaApp.Display.Traces;
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaInput = vsaMeas.Input;
            
            try
                %add trace
                vsaTraces.Create();                

                %get count
                traceAdded = vsaTraces.Count-1;

                %set trace to format and style (trace,name,format)
                vsaTraces.Item(traceAdded).DataName = 'Raw Main Time1';
                vsaTraces.Item(traceAdded).Format = TraceFormatType.Real;

                % Pause Measurement
                vsaMeas.Pause();

                % Add markers for max - min
                vsaTraces.Item(traceAdded).Markers.Create();
                vsaTraces.Item(traceAdded).Markers.Create();
                vsaTraces.Item(traceAdded).Markers.Item(0).IsVisible = true;
                vsaTraces.Item(traceAdded).Markers.Item(1).IsVisible = true;
                
                vsaTraces.Item(traceAdded).Markers.Item(0).MoveTo(MarkerMoveType.Minimum);
                vsaTraces.Item(traceAdded).Markers.Item(1).MoveTo(MarkerMoveType.Peak)

                % Calculate max - min
                peakTopeak = vsaTraces.Item(traceAdded).Markers.Item(1).Y - vsaTraces.Item(traceAdded).Markers.Item(0).Y;
                
                % Resume Measurement
                vsaMeas.Resume();

                %remove trace
                vsaTraces.Item(traceAdded).IsVisible = false;
                vsaTraces.Item(traceAdded).DataName = 'No Data';
            catch
                result = -1;
                return;
            end    
        else %----- communicating to VSA through SCPI
            try
                % add trace
                xfprintf(vsaApp,':TRACe:ADD');

                % get count
                traceAdded = str2num(xquery(vsaApp,':TRACe:COUNt?'));

                % set trace to format and style (trace,name,format)
                xfprintf(vsaApp,sprintf(':TRACe%d:DATA:NAME %s',traceAdded,traceName));
                xfprintf(vsaApp,sprintf(':TRACe%d:FORMAT %s',traceAdded,traceFormat));

                % pause measurement (trace)
                xfprintf(vsaApp,':INITiate:PAUSe');

                % Add markers for max - min
                xfprintf(vsaApp,sprintf(':TRACe%d:MARKer1:ENABle 1',traceAdded));
                xfprintf(vsaApp,sprintf(':TRACe%d:MARKer2:ENABle 1',traceAdded));
                xfprintf(vsaApp,sprintf(':TRACe%d:MARKer2:MAXimum',traceAdded));
                xfprintf(vsaApp,sprintf(':TRACe%d:MARKer1:MINimum',traceAdded));

                % Calculate max - min
                peakTopeak = str2num(xquery(vsaApp,sprintf(':TRACe%d:MARKer2:Y?',traceAdded)))-str2num(xquery(vsaApp,sprintf(':TRACe%d:MARKer1:Y?', traceAdded)));

                % Resume Measurement
                xfprintf(vsaApp,':INITiate:RESume');


                %remove trace
                xfprintf(vsaApp,sprintf(':TRACe%d:REMove',traceAdded));
                
            catch ex
               result = -1;
               return;
            end
            
        end
        
        result = peakTopeak;        

                
%-------------------------------------------------------------------------        
    case 'channelQuality'
        % set Channel Quality Measurement Up
        % argument 1: relative frequencies
        % argument 2: magnitudes
        % argument 3: phases
        % argument 4: set up VSA
        % argument 5: use file or no
        
        % Generate the reference file in the channel quality format
        dataArray = [ones(1,length(varargin{1})); varargin{1}; varargin{2}; varargin{3}];
        
        % Save to the local directory if using file
        writeToFile = true;
        
        if (length(varargin) >= 4)
            writeToFile = varargin{5};
        end
        
        % Save to file or create tone definitions to write
        if (writeToFile)
            fileNameLocal = fullfile(iqScratchDir(), 'vsatempChannel.txt');        
            fileID = fopen(fileNameLocal, 'w');
            if (fileID < 0)
                errordlg(sprintf('Can''t open temporary file: %s\n', fileNameLocal));
                return;
            end
            fprintf(fileID,'%u %f %f %f\r\n',dataArray);
            fclose(fileID);            
        end
        
        % If we set up in VSA, do so
        if (varargin{4} == true)       
            if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
                
                % Open instance
                vsaCQM = getCQM(vsaApp);
                
                % Load the file or load the definitions               
                try
                     if (writeToFile)
                         vsaCQM.MultitoneStimulus.Recall(fileNameLocal);
                     else
                         % Get the number of tones
                         toneCount = length(varargin{1});
                         
                         % Get the frequency spacing assuming equal
                         frequencySpacing = dataArray(2,2) - dataArray(2,1);
                         
                         % Set spacing and count
                         vsaCQM.MultitoneStimulus.Configure(frequencySpacing, toneCount);
                         
                         % Set arrays of tone definitions
                         toneDefinitions = NET.createArray('Agilent.SA.Vsa.ChannelQuality.ToneDefinition', toneCount);
                         
                         for (toneIdx = 1:toneCount)
                            toneSet = Agilent.SA.Vsa.ChannelQuality.ToneDefinition;
                            toneSet.IsActive = 1;
                            toneSet.Magnitude = dataArray(3, toneIdx);
                            toneSet.Phase = dataArray(4, toneIdx);                       
                            toneDefinitions(toneIdx) = toneSet;
                         end
                         
                         vsaCQM.MultitoneStimulus.Configure(frequencySpacing, toneDefinitions);
                     end
                catch ex
                    errordlg(sprintf('Error configuring VSA: %s', ex.message));
                    return;
                end
                
                % Turn on phase, frequency offset compensation
                vsaCQM.IsPhaseDriftCompensationEnabled = 1;
                vsaCQM.IsGainDriftCompensationEnabled  = 1;
                vsaCQM.IsFrequencyOffsetCompensationEnabled = 1;
                
                % Turn on averaging, 3
                average = vsaApp.Measurements.SelectedItem.Average;
                average.Style = Agilent.SA.Vsa.AverageStyle.RmsExponential;
                average.Count = 3;
                average.IsFast = false;
                average.IsRepeat = true;
                                
            else %----- communicating to VSA through SCPI
                xfprintf(vsaApp, ':MEAS:CONF CQuality');
                
                % Load the file or define the tones
                if (writeToFile)
                    xfprintf(vsaApp, sprintf(':MEMory:LOAD:CQUality:MTONe "%s"', fileNameLocal));
                else
                    % Dynamically build the tone array
                    toneString = ':CQUality:MTONe:CONF ';
                    
                    % Get the number of tones
                    toneCount = length(varargin{1});

                    % Get the frequency spacing assuming equal
                    frequencySpacing = dataArray(2,2) - dataArray(2,1);
                                        
                    toneString = [toneString num2str(frequencySpacing) ',' num2str(toneCount)];
                    
                    for (toneIdx = 1:toneCount)
                        % Build the substring
                        toneSubstring = [',{', 'true', ',' , num2str(dataArray(3, toneIdx)), ',' , num2str(dataArray(4, toneIdx)) , '}'];
                        toneString = [toneString toneSubstring];
                    end
                     
                    % Send the tone string array
                    xfprintf(vsaApp, toneString);
                end
                
                % Turn on phase, frequency offset compensation
                xfprintf(vsaApp, ':CQUality:COMPensate:PHASe 1;:CQUality:COMPensate:GAIN 1;:CQUality:COMPensate:FREQuency 1');
                
                %Turn on averaging, 3
                xfprintf(vsaApp, sprintf(':AVER:STYLE "RmsExponential";:AVER:COUNT 3;:AVER:FAST 0;:AVER:REPEAT 0'));                                  
            end
        end
%-------------------------------------------------------------------------        
    case 'readEqDataChannel'
        % get equalizer data and write ampCorr file
        % argument 1: add new measurement to existing correction (re-calibration) (Optional)
        % argument 2: frequency array
        % argument 3: carrier offset
        % argument 4: turn averaging on/off
        % argument 5: smooth out the center frequency
        result = -1;
        
        averageOut = true;
        if (length(varargin) >= 4)
            averageOut = varargin{4};
        end
        
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaDisp = vsaApp.Display;
            vsaTraces = vsaDisp.Traces;
            tr = vsaTraces.Item(4);
            x = varargin{2}';
            yreal = (tr.DoubleData(TraceDataSelect.Y, false).double)';
            tr = vsaTraces.Item(5);
            yimag = (tr.DoubleData(TraceDataSelect.Y, false).double)';
            
            % Turn on averaging, 3
            if (averageOut)
                average = vsaApp.Measurements.SelectedItem.Average;
                average.Style = Agilent.SA.Vsa.AverageStyle.RmsExponential;
                average.Count = 3;
                average.IsFast = false;
                average.IsRepeat = true;
            end
            
        else %----- communicating to VSA through SCPI
            % make sure the equalizer does not change while we read
            % hMsg = msgbox('Reading equalizer data from VSA...');
            xfprintf(vsaApp, sprintf(':FORM REAL64'));
            % x = xbinblockread(vsaApp, 'double', sprintf(':TRAC5:DATA:X?'));
            x = varargin{2}';
            yreal = xbinblockread(vsaApp, 'double', sprintf(':TRAC5:DATA:Y?'), 'big-endian');
            yimag = xbinblockread(vsaApp, 'double', sprintf(':TRAC6:DATA:Y?'), 'big-endian');
%             try
%                 close(hMsg);
%             catch
%             end
            if (isempty(x) || isempty(yreal) || isempty(yimag))
                errordlg('Could not read Equalizer data from VSA');
                return;
            end
            
            % Turn on averaging, 3            
            if (averageOut)
                xfprintf(vsaApp, sprintf(':AVER:STYLE "RmsExponential"'));
                xfprintf(vsaApp, sprintf(':AVER:COUNT 3'));
                xfprintf(vsaApp, sprintf(':AVER:FAST 0'));
                xfprintf(vsaApp, sprintf(':AVER:REPEAT 0'));
            end
        end
        
        % shift carrier offset if necessary
%         if (length(varargin) >= 2)
%             x = x + varargin{3};
%         end
%         if (length(varargin) >= 5)
%             if(varargin{5} == true)
%                 res = questdlg('Smooth response? (Works well with large tone counts)','VSA Calibration','Yes','No','Yes');
%                 if (strcmp(res, 'Yes'))
%                     filtc = [ 0.025 0.075 0.1 0.6 0.1 0.075 0.025];
% 
%                     yrealConv = conv(yreal,filtc, 'same');
%                     yimagConv = conv(yimag,filtc, 'same');
% 
%                     yreal(4:end-4) = yrealConv(4:end-4);
%                     yimag(4:end-4) = yimagConv(4:end-4);                  
%                 end
%             end                     
%         end
        
        y = 1 ./ complex(yreal, yimag);
        ydB = 20 * log10(abs(y));
        % combine with existing calibration data
        clear acs;
        acs.ampCorr = [x zeros(length(x),1) ones(length(x),1)];
        if (varargin{1} ~= 0)
            % in case of re-calibration, read the old cal values
            try
                % load the full correction file
                acs = load(iqampCorrFilename());
            catch
                clear acs;
            end
            if (isfield(acs, 'ampCorr'))
                % take care of ampCorrMode - flip or reset ampCorr
                % accordingly
                if (isfield(acs, 'ampCorrMode'))
                    ampCorrMode = acs.ampCorrMode;
                else
                    ampCorrMode = -1;   % old style: de-embed
                end
                if (size(acs.ampCorr,2) <= 2)  % no complex correction available
                    acs.ampCorr(:,3) = 10.^(acs.ampCorr(:,2)/20);
                end
                if (ampCorrMode == 1)
                    acs.ampCorr(:,3) = conj(acs.ampCorr(:,3));
                    acs.ampCorr(:,2) = -1 * acs.ampCorr(:,2);
                elseif (ampCorrMode == 0)
                    acs.ampCorr(:,3) = ones(size(acs.ampCorr, 1), 1);
                    acs.ampCorr(:,2) = zeros(size(acs.ampCorr, 1), 1);
                end
                % if the list of frequencies does not match,
                % interpolate the existing correction values
                if (~isequal(acs.ampCorr(:,1), x))
                    % but first check if new frequencies are positive & negative
                    % and old frequencies are only positive
                    if (min(acs.ampCorr(:,1)) >= 0 && min(x) < 0 && max(x) > 0)
                        freq = acs.ampCorr(:,1);
                        if (freq(1) == 0)            % don't duplicate zero-frequency
                            startIdx = 2;
                        else
                            startIdx = 1;
                        end
                        freq = [-1 * flipud(freq); freq(startIdx:end)];
                        mag = [flipud(acs.ampCorr(:,2)); acs.ampCorr(startIdx:end,2)];
                        if (size(acs.ampCorr,2) >= 3)
                            lincorr = [flipud(conj(acs.ampCorr(:,3))); acs.ampCorr(startIdx:end,3)];
                        else
                            lincorr = 10.^(mag/20);
                        end
                        acs.ampCorr = [freq mag lincorr];
                    end
                    % interpolate the existing correction values
                    newCol2 = interp1(acs.ampCorr(:,1), acs.ampCorr(:,2), x, 'pchip', 0);
                    if (size(acs.ampCorr,2) >= 3)
                        newCol3 = interp1(acs.ampCorr(:,1), acs.ampCorr(:,3), x, 'pchip', 1);
                    else
                        newCol3 = 10.^(newCol2/20);
                    end
                    acs.ampCorr = [x newCol2 newCol3];
                end
            else
                acs.ampCorr = [x zeros(length(x),1) ones(length(x),1)];
            end
        end
        % add new corrections to existing ones
        % dB's add up, complex (linear) corrections are multiplied
        acs.ampCorr = [x (acs.ampCorr(:,2)+ydB) (acs.ampCorr(:,3).*y)];
        acs.ampCorrMode = -1;
        % and save
        save(iqampCorrFilename(), '-struct', 'acs');
        result = 0;
        
%------------------------------------------------------------------------- 
    case 'loadRFCorrection'
        % load RF Correction File
        % argument 1: VSA Channel
        % argument 2: Enabled
        % argument 3: Complex Correction Data
        
        channels = varargin{1};
        enabledStates = varargin{2};
                
        % Create the correction files for each set of correction data
        % If there is correction data...
        if (length(varargin) >= 3)
            correctionInputs = varargin{3};

            if(iscell(correctionInputs))

            else
                correctionInputs = {correctionInputs};
            end
            
            calFile = cell(1,length(correctionInputs));
            for n = 1:length(correctionInputs)
                if(enabledStates(n) == 1)
                    fileName = [pwd '\vsaTempRFCorrChan' num2str(channels(n)) '.cal'];
                    calFile{n} = createCorrectionFile(fileName, correctionInputs{n});
                end
            end
        end
        
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))            
            try
                vsaMeas = vsaApp.Measurements.SelectedItem;
                vsaInputCorrection = vsaMeas.InputCorrections;

                % Load every correction file
                if (length(varargin) >= 3)
                    for n = 1:length(calFile)
                        if(enabledStates(n) == 1)
                            vsaInputCorrection.Item(channels(n)-1).RFExternalCalibrationFile = fileName;
                        end
                    end
                end

                % Enable/Disable every correction file
                for n = 1:length(enabledStates)
                    switch enabledStates(n)
                        case 0
                            enabled = false;
                        case 1
                            enabled = true;                    
                    end            
                    vsaInputCorrection.Item(channels(n)-1).IsRFExternalCorrectionEnabled = false;               
                    vsaInputCorrection.Item(channels(n)-1).IsRFExternalCorrectionEnabled = enabled;               
                end
            catch ex
                errordlg(sprintf('Error configuring VSA: %s\nMake sure the selected channel exists in VSA.', ex.message));
                return;
            end
            
        else %----- communicating to VSA through SCPI
            try
                % Load every correction file
                if (length(varargin) >= 3)
                    for n = 1:length(calFile)
                        if(enabledStates(n) == 1)
                            xfprintf(vsaApp, sprintf(':INPut:CORRection%d:RF:FILE "%s"',channels(n), fileName));
                        end
                    end
                end

                % Enable/Disable every correction file
                for n = 1:length(enabledStates)
                    switch enabledStates(n)
                        case 0
                            enabled = 0;
                        case 1
                            enabled = 1;                    
                    end 
                    xfprintf(vsaApp, sprintf(':INPut:CORRection%d:RF:ENABle %d',channels(n), 0));
                    xfprintf(vsaApp, sprintf(':INPut:CORRection%d:RF:ENABle %d',channels(n), enabled));            
                end
            catch ex
                errordlg(sprintf('Error configuring VSA: %s\nMake sure the selected channel exists in VSA.', ex.message));
                return;
            end
        end
%------------------------------------------------------------------------- 
    case 'loadIFCorrection'
        % load IF Correction File
        % argument 1: VSA Channel
        % argument 2: Enabled
        % argument 3: Complex Correction Data
        
        channels = varargin{1};
        enabledStates = varargin{2};
                
        % Create the correction files for each set of correction data
        % If there is correction data...
        if (length(varargin) >= 3)
            correctionInputs = varargin{3};

            if(iscell(correctionInputs))

            else
                correctionInputs = {correctionInputs};
            end
            
            calFile = cell(1,length(correctionInputs));
            for n = 1:length(correctionInputs)
                if(enabledStates(n) == 1)
                    fileName = [pwd '\vsaTempIFCorrChan' num2str(channels(n)) '.cal'];
                    calFile{n} = createCorrectionFile(fileName, correctionInputs{n});
                end
            end
        end
        
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            try
                vsaMeas = vsaApp.Measurements.SelectedItem;
                vsaInputCorrection = vsaMeas.InputCorrections;

                % Load every correction file
                if (length(varargin) >= 3)
                    for n = 1:length(calFile)
                        if(enabledStates(n) == 1)
                            vsaInputCorrection.Item(channels(n)-1).IFExternalCalibrationFile = fileName;
                        end
                    end
                end

                % Enable/Disable every correction file
                for n = 1:length(enabledStates)
                    switch enabledStates(n)
                        case 0
                            enabled = false;
                        case 1
                            enabled = true;                    
                    end 
                    vsaInputCorrection.Item(channels(n)-1).IsIFExternalCorrectionEnabled = false;  
                    vsaInputCorrection.Item(channels(n)-1).IsIFExternalCorrectionEnabled = enabled;               
                end
            catch ex
                errordlg(sprintf('Error configuring VSA: %s\nMake sure the selected channel exists in VSA.', ex.message));
                return;
            end
            
        else %----- communicating to VSA through SCPI
            try
                % Load every correction file
                if (length(varargin) >= 3)
                    for n = 1:length(calFile)
                        if(enabledStates(n) == 1)
                            xfprintf(vsaApp, sprintf(':INPut:CORRection%d:IF:FILE "%s"',channels(n), fileName));
                        end
                    end
                end

                % Enable/Disable every correction file
                for n = 1:length(enabledStates)
                    switch enabledStates(n)
                        case 0
                            enabled = 0;
                        case 1
                            enabled = 1;                    
                    end 
                    xfprintf(vsaApp, sprintf(':INPut:CORRection%d:IF:ENABle %d',channels(n), 0));
                    xfprintf(vsaApp, sprintf(':INPut:CORRection%d:IF:ENABle %d',channels(n), enabled));            
                end
            catch ex
                errordlg(sprintf('Error configuring VSA: %s\nMake sure the selected channel exists in VSA.', ex.message));
                return;
            end
        end
%-------------------------------------------------------------------------        
    case 'xSeriesMixerMode'  %richard_soden@keysight.com
        % sets the mixer mode of an X series analyzer to Normal or
        % Alternate
        result = [];
        mixMode = char(varargin{1});
        
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            if (strcmp (mixMode, 'Normal'))||(strcmp (mixMode,'Alternate'))
                try
                    if strcmp(mixMode,'Normal')
                        vsaApp.Measurements.SelectedItem.Input.Extensions.Item(0).SetParameter(Agilent.SA.Vsa.InstrumentType.Adc, 'MixerMode', Agilent.SA.Vsa.HardwareExtensions.XSeries.MixerMode.Normal);
                    else
                        vsaApp.Measurements.SelectedItem.Input.Extensions.Item(0).SetParameter(Agilent.SA.Vsa.InstrumentType.Adc, 'MixerMode', Agilent.SA.Vsa.HardwareExtensions.XSeries.MixerMode.Alternate);
                    end
                catch ex
                    errordlg(sprintf('Error configuring XSeries Mixer Mode in VSA: \nMake sure you are connected to XSeries hardware \nand are running ver 22.2 or higher of 89600 VSA\n'));
                end
                
            end
        end
        
        result = 0;  
    
%------------------------------------------------------------------------- 
    case 'loadIFCorrectionFile'
        % load IF Correction File
        % argument 1: .cal file
        result = [];
        
        calFile = varargin{1};
                
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaInputCorrection = vsaMeas.InputCorrections;
                
            if isempty(calFile)
                %turn off filter
                vsaInputCorrection.Item(0).IsIFExternalCorrectionEnabled = 0;
            else
            vsaInputCorrection.Item(0).IFExternalCalibrationFile = calFile;
            vsaInputCorrection.Item(0).IsIFExternalCorrectionEnabled = 1;
            end
            
        
        else
            errordlg(sprintf('Error configuring VSA: %s\nMake sure the selected channel exists in VSA.', ex.message));
            return;
        end
        
        result = 0;

%------------------------------------------------------------------------- 
    case 'bandpower'
        % load IF Correction File
        % argument 1: .cal file
        result = [];
        
        fc = varargin{1};
        band = varargin{2};
                
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaDisp = vsaApp.Display;
            vsaTraces = vsaDisp.Traces;
            
            % Setup a rms Exponential
            vsaMeas.Average.Style = AverageStyle.RmsExponential;
            vsaMeas.Average.Count = 10;
            vsaMeas.Restart();
            pause(2);
                        
            % setup marker
            vsaTraces.SelectedIndex = 1;
            vsaMarker = vsaTraces.SelectedItem.Markers.SelectedItem;
            vsaTraces.SelectedItem.Markers.SelectedIndex= 0;
            vsaMarker.IsVisible = 1;
            vsaMarker.XData = fc;
            vsaMarker.IsBandVisible = 1;
            vsaMarker.BandSpan = band;           
                        
            % pull marker measurement
            result = vsaMarker.BandPowerResult;
            
            % remove markers
            vsaMarker.IsBandVisible = 0;
            vsaMarker.IsVisible = 0;
            
        else
            errordlg(sprintf('Error configuring VSA: %s\nMake sure the selected channel exists in VSA.', ex.message));
            return;
        end
        
 %-------------------------------------------------------------------------         
    case 'setupforradarsound'
        result = [];
        freqMinHz = varargin{1};
        freqMaxHz = varargin{2};
        durationTraceS = varargin{3};
        audioSampleRateHz = varargin{4};
          
        if (isa(vsaApp, 'Agilent.SA.Vsa.Application'))
            % If the measurement isn't vector fix
            vsaMeas = vsaApp.Measurements.SelectedItem;
            if isempty(Agilent.SA.Vsa.VectorMeasurement.CastToExtensionType(vsaMeas.MeasurementExtension))
                vsafunc(vsaApp, 'preset', 'vector');
            end
            
            vsaMeas = vsaApp.Measurements.SelectedItem;
            vsaDisp = vsaApp.Display;
            vsaTraces = vsaDisp.Traces;
            
            % Set up the measurement if the traces don't match
            numTr = vsaTraces.Count;                       
            needsAdd = false;
            if (numTr > 3)
                if vsaTraces.Item(1).DataName ~= System.String('Main Time1')...
                        || vsaTraces.Item(1).Format ~= Agilent.SA.Vsa.TraceFormatType.LogMagnitude...
                        || vsaTraces.Item(3).DataName ~= System.String('Main Time1')...
                        || vsaTraces.Item(3).Format ~= Agilent.SA.Vsa.TraceFormatType.GroupDelay
                    needsAdd = true;
                end                                                
            else
                needsAdd = true;
            end
            
            if needsAdd 
                vsafunc(vsaApp, 'trace', 4, 'Chirp');                
            end
            
            % Now, measure the frequency and magnitude
            % Get the amplitude and frequency offset data
            % Right now assume the traces are using the basic iqpulse visualize

            % Frequency scale is the top and bottom of the trace scale;
            % make it related to the span for now
            frequencyScaleTop = vsaTraces.Item(3).YTop;
            frequencyScaleBottom = vsaTraces.Item(3).YBottom;

            % Log Mag is traces - 2
            amplitudeData = vsaTraces.Item(1).DoubleData(Agilent.SA.Vsa.TraceDataSelect.Y, false).double;

            % Frequency offset is traces
            frequencyOffsetData = vsaTraces.Item(3).DoubleData(Agilent.SA.Vsa.TraceDataSelect.Y, false).double;
            
            % Resample to meet the trace duration
            newSampleCount = audioSampleRateHz * durationTraceS;
            frequencyOffsetData = iqresample(frequencyOffsetData, newSampleCount);
            amplitudeData = iqresample(amplitudeData, newSampleCount);
                       
            % Get the scaler and offset
            receiveFrequencyPerSoundFrequencyInHzPerHz =...
                (frequencyScaleTop - frequencyScaleBottom) / (freqMaxHz - freqMinHz);

            zeroFrequencyToneInHz = (freqMaxHz + freqMinHz) / 2;
            
            %% Scale frequency offset and magnitude
            frequencyOffsetDataScaled = frequencyOffsetData /...
                (receiveFrequencyPerSoundFrequencyInHzPerHz) + zeroFrequencyToneInHz;

            linearAmp = 10.^(amplitudeData./20);

            %% Finally, generate the mag and phase and play the tone
            phaseSignal = 2 * pi * cumsum(frequencyOffsetDataScaled) / audioSampleRateHz;
            soundSignal = linearAmp .* exp(1i * phaseSignal);                      
            sound(real(soundSignal), audioSampleRateHz);
            pause(length(soundSignal)/audioSampleRateHz);
        else
            % If the last two traces are magnitude and group delay, then
            % skip, and otherwise add them
            
            % If the measurement isn't vector fix
            if ~contains(xquery(vsaApp, ':MEAS:CONF?'), 'VECT')
                vsafunc(vsaApp, 'preset', 'vector');
            end
            
            % Get the trace count and the last two traces and if they are
            % not magnitude and group delay, add them
            numTr = str2double(xquery(vsaApp, ':TRAC:COUNT?'));
                        
            needsAdd = false;
            if (numTr > 3)
                if ~contains(xquery(vsaApp, sprintf(':TRAC%d:DATA:NAME?', 2)), 'Main Time1')...
                        || ~contains(xquery(vsaApp, sprintf(':TRAC%d:FORMAT?', 2)), 'LogMagnitude')...
                        || ~contains(xquery(vsaApp, sprintf(':TRAC%d:DATA:NAME?', 4)), 'Main Time1')...
                        || ~contains(xquery(vsaApp, sprintf(':TRAC%d:FORMAT?', 4)), 'GroupDelay')
                    needsAdd = true;
                end                                                
            else
                needsAdd = true;
            end
            
            if needsAdd 
                xfprintf(vsaApp,'*CLS');
                vsafunc(vsaApp, 'trace', 4, 'Chirp');                
            end
            
            % Now, measure the frequency and magnitude
            % Get the amplitude and frequency offset data
            % Right now assume the traces are using the basic iqpulse visualize
            xquery(vsaApp, '*OPC?');
            
            % Frequency scale is the top and bottom of the trace scale;
            % make it related to the span for now
            frequencyScaleTop = str2double(xquery(vsaApp, sprintf(':TRACe%d:Y:SCALe:TOP?', 4)));
            frequencyScaleBottom = str2double(xquery(vsaApp, sprintf(':TRACe%d:Y:SCALe:BOTTom?', 4)));
            
            xfprintf(vsaApp, sprintf(':FORM REAL64'));

            % Log Mag is traces - 2
            amplitudeData = xbinblockread(vsaApp, 'double', sprintf(':TRAC%d:DATA:Y?', 2), 'big-endian');

            % Frequency offset is traces
            frequencyOffsetData = xbinblockread(vsaApp, 'double', sprintf(':TRAC%d:DATA:Y?', 4), 'big-endian');
            
            % Resample to meet the trace duration
            newSampleCount = audioSampleRateHz * durationTraceS;
            frequencyOffsetData = iqresample(frequencyOffsetData, newSampleCount);
            amplitudeData = iqresample(amplitudeData, newSampleCount);
                       
            % Get the scaler and offset
            receiveFrequencyPerSoundFrequencyInHzPerHz =...
                (frequencyScaleTop - frequencyScaleBottom) / (freqMaxHz - freqMinHz);

            zeroFrequencyToneInHz = (freqMaxHz + freqMinHz) / 2;
            
            %% Scale frequency offset and magnitude
            frequencyOffsetDataScaled = frequencyOffsetData /...
                (receiveFrequencyPerSoundFrequencyInHzPerHz) + zeroFrequencyToneInHz;

            linearAmp = 10.^(amplitudeData./20);

            %% Finally, generate the mag and phase and play the tone
            phaseSignal = 2 * pi * cumsum(frequencyOffsetDataScaled) / audioSampleRateHz;
            soundSignal = linearAmp .* exp(1i * phaseSignal);                      
            sound(real(soundSignal), audioSampleRateHz);
            pause(length(soundSignal)/audioSampleRateHz);                        
        end      
        
%-------------------------------------------------------------------------
       
    otherwise
        error(['unknown vsafunc: ' fct]);
end
catch ex
   errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});end
end


function vsaDemod = getDigDemod(vsaApp)
        vsaMeas = vsaApp.Measurements.SelectedItem;
        %switch to VSA Measurement (here I have an Error)
        DigDemodType = Agilent.SA.Vsa.DigitalDemod.MeasurementExtension.ExtensionType;
        DigDemodMeasExt = vsaMeas.SetMeasurementExtension(DigDemodType);
        vsaDemod = Agilent.SA.Vsa.DigitalDemod.MeasurementExtension.CastToExtensionType(DigDemodMeasExt);
        % [Start workaround for Matlab defect]
        vsaDemod.delete;
        DigDemodMeasExt = vsaMeas.SetMeasurementExtension(DigDemodType);
        vsaDemod = Agilent.SA.Vsa.DigitalDemod.MeasurementExtension.CastToExtensionType(DigDemodMeasExt);
        % [End workaround for Matlab defect]
end

function vsaCQM = getCQM(vsaApp)
        vsaMeas = vsaApp.Measurements.SelectedItem;
        %switch to VSA Measurement (here I have an Error)
        CQMType = Agilent.SA.Vsa.ChannelQuality.MeasurementExtension.ExtensionType;
        CQMMeasExt = vsaMeas.SetMeasurementExtension(CQMType);
        vsaCQM = Agilent.SA.Vsa.ChannelQuality.MeasurementExtension.CastToExtensionType(CQMMeasExt);
        % [Start workaround for Matlab defect]
        vsaCQM.delete;
        CQMMeasExt = vsaMeas.SetMeasurementExtension(CQMType);
        vsaCQM = Agilent.SA.Vsa.ChannelQuality.MeasurementExtension.CastToExtensionType(CQMMeasExt);
        % [End workaround for Matlab defect]
end

%Creates a cal file that can be loaded into VSA
function calFileName = createCorrectionFile(fileName, cplxCorrections)
    initialFreq = cplxCorrections(1);
    freqStepSize = cplxCorrections(2)-cplxCorrections(1);

    calFileName = fileName;

    calFileHeader = sprintf(...
    'FileFormat UserCal-1.0');

    calFileHeader = sprintf('%s\r\nTrace Data\r\nYComplex 1\r\nYFormat MA\r\n',calFileHeader);

    calFileHeader = sprintf('%sXDelta\t%d\r\nXStart\t%d\r\nY\r\n',calFileHeader,freqStepSize,initialFreq);

    calFileData = [];
    
    for n = 1:length(cplxCorrections)
        calFileData = sprintf('%s\t%d\t%d\r\n',calFileData,abs(cplxCorrections(n,2)),angle(cplxCorrections(n,2))*180/pi);
    end

    calFile = sprintf('%s%s',calFileHeader,calFileData);

    fileID = fopen(calFileName,'w');

    fprintf(fileID, calFile);

    fclose(fileID);
end



%%
function [acs, oldCorr, err] = getOldCorr(arbConfig, tone, chs, recalibrate, usePerChannelCorr)
% get starting values for calibration
% NOTE: asme routine as in iqcal.m and iqpowersensor.m - should be unified
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


