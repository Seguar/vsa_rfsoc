classdef IQToolsServer < handle
% IQToolsServer Class for external control of IQTools via server
%   This class contains the properties and methods necessary for
%   controlling IQTools via server, with focus on pulses and combining
%   of pulses and general purposes commands
%
% #TODO
% 1.Add correction file loading/management
% 2.Add calibration commands, with different calibration types
%
%
% Tom Wychock, Keysight Technologies 2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 
    
    properties
        
        %% Server properties
        
        Server = struct(...
            ...  % IO Properties
            'IPv4Address', '127.0.0.1',...              % The IPv4 Address of the instrument
            'SocketPort', 30000,...                     % The socket port of the instrument
            'ServerInstance', [],...                    % The server instance                           
            'ModelString', 'IQTools Server',...         % Version prefix, the version itself is from iqversion()
            'UseUDP', false,...                         % Use TCPIP or UDP?
            ...  % Parser state, Error queue and debug
            'CurrentCommand', '',...                    % the currently processed command line
            'ParseNext', '',...                         % the portion of the command line that has not been parsed yet
            'ErrorQueue', {'0'},...                     % The error queue to query        
            'DebugMode', false, ...                     % Debug mode                            
            'CloseImmediate', false);                   % close the connection after each command
                                               
        %% Instrument properties
        
        Instrument = struct(...
            'ArbConfig', [], ...                    % the arbConfig structure used by the server
            'ModeString', 'Vector',...              % The instrument mode
            'SampleRateInHz', 250E6,...             % The sample rate of the source in Hz
            'ChannelMapping', [1 0; 0 1],...        % The channel mapping of the instrument
            'SegmentNumber', 1,...                  % Waveforms are downloaded to this segment number
            'SegmentName', 'IQTools0001',...        % Waveforms are downloaded with this name (if named)
            'InstrumentPathArray', {''},...         % The instruments present in the system
            'FileSaveType', '16-bit I/Q MSB',...    % The file type to save
            'RFFrequency', 0,...                    % The RF Frequency if upconverting
            'RFAmplitude', -120,...                	% The RF Amplitude if upconverting
            'RFOn', 0,...                           % The RF State if upconverting
            'Type', 'SignalGenerator');             % The instrument type                   
                
        %% Calibration properties
        
        Calibration = struct(...
            ...  % Type, span, spacing, wait time
            'ComplexCalibrationType', 'VSAChannel',...          % The type of calibration to perform
            'ComplexCalibrationSpanInHz', 100E6,...             % The frequency span of the calibration in Hz
            'ComplexCalibrationSpacingInHz', 1E6,...            % The frequency spacing of the calibration in Hz
            'ComplexCalibrationSettleTimeInS', 3,...            % The settling time of the calibration in seconds
            'ComplexCalibrationOffsetInHz', 0,...               % The offset frequency to avoid LO feedthru
            'ComplexCalibrationCenterFrequencyInHz', 0,...      % The center frequency of the calibration in Hz
            'Recalibrate', 0,...                                % Calibrate with signals generated using calibrated data?
            'Initialize', 1,...                                 % Calibrate with initialization?
            'AutoRange', 1,...                                  % Autorange during the calibration
            'RangeInDBm', 30,...                                % Calibration range during the calibration
            'CalibrationSavePath', 'AmpCorrTemporary');         % The save path of the calibration
                
        %% Command properties
        
        Scripting = struct(...
            'ScriptCommandCurrent', '',...   % The current command
            'ScriptCommandTable', []);       % The list of commands
    
        %% Correction #TODO: Add correction code
        
        Correction = struct(...
            'UseCorrection', 0,...      % Whether or not to use corrections
            'CorrectionFilePath', '');  % The correction file path
                       
        %% Single pulse properties
        
        % Pulses are created by giving them properties, then commanding the
        % server to create and save/preview the IQ data
        
        PulseGen = struct(...
            ...  % Time
            'PulseDwellInSeconds', 8E-6,...             % The dwell of the iq snippet in seconds
            'PulseWidthInSeconds', 2E-6,...             % The width of the pulse in seconds
            'PulseRiseTimeInSeconds', 20E-9,...         % The rise time of the pulse in seconds
            'PulseFallTimeInSeconds', 20E-9,...         % The fall time of the pulse in seconds
            'PulseDelayInSeconds', 0,...                % The delay time of the pulse in seconds
            ...  % Amplitude, phase, frequency. shaping
            'PulseAmplitudeInDB', 0,...                 % The amplitude in DB
            'PulsePhaseInDegrees', 0,...                % The phase of the signal in degrees
            'PulseFrequencyOffsetInHz', 0,...           % The frequency offset of the signal in Hz
            'PulseShape', 'Raised Cosine',...           % The rise/fall shape of the pulse
            ...  % Modulation
            'PulseModulationType', 'None',...           % The modulation type of the pulse
            'PulseModulationFrequencySpan', 100E6,...   % The modulation frequency span of the pulse
            'PulseFilePathSave', 'PulseTemporary',...   % The file path of the save
            'PulseFrequencyModulationFormula', '0',...  % The frequency modulation formula if custom
            'PulsePhaseModulationFormula', '0',...      % The phase modulation formula if custom
            'PulsePhaseTransitionState', 'coherent',... % The phase change rules
            'PulseNormalize', 1 );                      % 1:scale to DAC full range, 0: use PulseAmplitudeInDB as dBFS 
                                                              
        %% Multi pulse settings, for adding multiple pulses together
        
        % This works by creating an array of pulse structures that contain
        % the properties of a single pulse with the start time, base
        % amplitude, and phase transition rules.
        %
        % When processed, this will output a scaled amplitude output to
        % adjust the source to (the DAC bits might scale to be greater than
        % one, meaning the base amplitude must increase), and a time as
        % well (to save DAC samples).  
        
        PulseCombineGen = struct(...
            'MultiPulseTable', [],...                   % The array of pulse objects for combining etc.
            'MultiPulseStartTimeInSeconds', 0,...       % The start time of the pulse
            'MultiPulseTransitionType', 'coherent',...  % The conversion type
            'MultiPulseBasePulseAmplitudeInDB', 0,...   % When combining, the base amplitude in dBm
            'MultiPulseBasePulsePhaseInDegrees', 0,...  % When combining, the base phase in degrees
            'MultiPulseAmplitudeShiftInDB', 0,...       % When doing the combining, if adding, the new scale
            'MultiPulseProcessFile', [],...             % When doing the combining, if a file is used for processing
            'MultiPulseTimeShiftInS', 0 );              % When doing the combining, if adding, the new time            
                        
        %% Multi-tone parameters
        
        ToneGen = struct(...
            'SampleCount', 0, ...        % number of samples (0 = automatic)
            'StartFrequency', 100e6, ... % start frequency in Hz
            'StopFrequency', 900e6, ...  % stop frequency in Hz
            'ToneCount', 9, ...          % number of tones
            'ToneSpacing', 100e6, ...    % tone spacing
            'NotchFrequency', 0, ...     % notch frequency in Hz
            'NotchSpan', 0, ...          % notch span in Hz
            'NotchDepth', -1000, ...     % notch depth in dB
            'ToneMagnitude', 0, ...      % magnitude in dBFS (if normalize == 0)
            'TonePhase', 'Random', ...   % phase in degrees or 'Random'
            'ToneNormalize', 1, ...      % 1:scale to DAC full range, 0: use magnitude as dBFS
            'dbFS', 0 );                 % will be populated with dBFS after download

        SerialGen = struct(...
            'DataRate', 250e6, ...       % data rate in Baud
            'SampleRate', 0, ...         % sample rate in Hz (0 = automatic)
            'SymbolCount', 128, ...      % number of symbols
            'Data', 'Random', ...        % type of data ('Random', 'PRBS2^7-1', etc.)
            'Format', 'NRZ', ...         % data format ('NRZ' or 'PAM4')
            'Levels', [0 1/3 1 2/3], ... % relative voltage levels in the range 0...1
            'SJFrequency', 20e6, ...     % SJ frequency in Hz
            'SJpp', 0, ...               % SJ peak-peak amplitude
            'RJpp', 0, ...               % (bounded) RJ peak-peak amplitude
            'NoiseFrequency', 0, ...     % Level Noise Frequency (0 = random)
            'NoiseAmplitude', 0, ...     % Level Noise Amplitude relative to data amplitude
            'Isi', 0, ...                % Amount of ISI (0...1)
            'PreCursor', [], ...         % PreCursors (linear)
            'PostCursor', [1], ...       % PostCursors (linear)
            'TransitionTime', 0.3, ...   % Transition Time in UI
            'FilterType', 'Transition Time', ... % calculate waveform based on 'Transition Time', 'Raised Cosine'
            'FilterNSym', 40, ...        % length of pulse shape filter in symbols
            'FilterBeta', 1, ...         % roll-off of pulse shape filter (0...1]
            'JitterShape', 'Sine', ...   % Jitter shape ('Sine', 'Triangle', ...)
            'SSCFrequency', 33e3, ...    % SSC Frequency in Hz
            'SSCDepth', 0, ...           % SSC Depth
            'SymbolShift', 0, ...        % number of symbols to rotate PRBS
            'Amplitude', 1, ...          % Amplitude relative to full scale
            'DutyCycle', 0.5, ...        % Duty Cycle in UI
            'UseM8196ARefClk', 0 );      % 1=use RefClk Out on M8196A to generate clock signal

        MTCal = struct(...
            'ScopeType', 'DCA', ...      % scope type ('DCA' or 'Realtime')
            'AWGChannels', {'1'}, ...    % list of AWG channels
            'ScopeChannels', {'1A'}, ... % list of scope channels
            'AWGTrigger', {'Marker'}, ...% AWG Trigger Channel
            'ScopeTrigger', {'PTB+FP'}, ...% Scope Trigger
            'SampleRate', 0, ...         % sample rate in Hz (0 = use default)
            'MaxTone', 70e9, ...         % max. tone frequency
            'ToneCount', 300, ...        % number of tones
            'ScopeAverage', 4, ...       % scope averages
            'AnalysisAverage', 4, ...    % analysis averages
            'ScopeAmplitude', 800e-3, ...% Scope Ampltiude
            'AutoScopeAmplitude', 1, ... % Automatic Scope Amplitude
            'ScopeBandwidth', 'MAX', ... % scope bandwidth
            'SIRC', 1, ...               % SIRC 
            'ChToChSkew', 0, ...         % include channel-to-channel skew
            'AWGReset', 0, ...           % AWG Reset
            'ScopeReset', 0, ...         % Scope Reset
            'BuildUponPreviousCal', 0, ...       % Build upon previous calibration
            'UseSeparateTonesPerChannel', 0, ... % use separate tones per AWG channel
            'rmsData', [] );             % store result of last skew calibration

    end
    
    methods
        % Constructor
        function obj = IQToolsServer(IPv4AddressIn, SocketPortIn, closeImmediate)
           % Pass in the address and port
           obj.Server.IPv4Address = IPv4AddressIn;
           obj.Server.SocketPort = SocketPortIn;           
           obj.Server.CloseImmediate = closeImmediate;
           obj.Reset();
        end
        
        % Destructor
        function delete(obj)
            % delete the tcpip instance, otherwise the list in instrfind keeps growing
            % disp('Destructor called');
            if (~isempty(obj.Server.ServerInstance))
                delete(obj.Server.ServerInstance);
            end
        end
                
        %% Server methods

        % TCPIP        
        function serverOut = LaunchServerTCPIP(obj)
            % LaunchServerTCPIP Launches a TCPIP server based on the configured port and socket properties
            disp('Launching TCPIP Server...')
            
            obj.Server.ServerInstance = tcpip(obj.Server.IPv4Address, obj.Server.SocketPort,...
            'NetworkRole', 'server');                   
        
            % Return the port
            obj.Server.SocketPort = obj.Server.ServerInstance.RemotePort;
                               
            % Link to IP
            disp(['Server TCPIP IP: ' num2str(obj.Server.ServerInstance.RemoteHost)]);

            % Link to port
            disp(['Server TCPIP port: ' num2str(obj.Server.ServerInstance.RemotePort)]);
            
            % Subscribe to bytes received
            obj.Server.ServerInstance.BytesAvailableFcn = @obj.parseReceivedDataAndReact; 
            
            % Set buffer            
            obj.Server.ServerInstance.InputBufferSize = 4000000;
            obj.Server.ServerInstance.OutputBufferSize = 40000;
            
            % Launch
            disp('Listening for connection...press CTRL+C in the command window to cancel...')
            
            fopen(obj.Server.ServerInstance);                        
            disp('Connected!')
            
            serverOut = obj.Server.ServerInstance;
            obj.Server.UseUDP = false;
        end
        
        
        function CloseServerTCPIP(obj)
           % CloseServerTCPIP   Closes a TCPIP server if launched
           disp('Closing TCPIP Server...')
           fclose(obj.Server.ServerInstance);
           delete(obj.Server.ServerInstance);
           disp('Server closed.')
        end
        
        % UDP
        function serverOut = LaunchServerUDP(obj, remotePort)
            % LaunchServerUDP Launches a UDP server based on the configured port and sockets properties
            disp('Launching UDP Server...')
            
            obj.Server.ServerInstance = udp(obj.Server.IPv4Address,...
                'LocalPort', obj.Server.SocketPort, 'RemotePort', remotePort);                   
        
            % Return the port
            obj.Server.SocketPort = obj.Server.ServerInstance.LocalPort;
                               
            % Link to IP
            disp(['Server UDP IP: ' num2str(obj.Server.ServerInstance.LocalPort)]);

            % Link to port
            disp(['Server UDP Receive port: ' num2str(obj.Server.ServerInstance.LocalPort)]);
            disp(['Server UDP Send port: ' num2str(obj.Server.ServerInstance.RemotePort)]);
            
            % Subscribe to bytes received
            obj.Server.ServerInstance.BytesAvailableFcn = @obj.parseReceivedDataAndReact; 
            
            % Set buffer            
            obj.Server.ServerInstance.InputBufferSize = 4000000;
            obj.Server.ServerInstance.OutputBufferSize = 40000;
            
            % Launch
            fopen(obj.Server.ServerInstance);                        
            disp('Connected!')
            
            serverOut = obj.Server.ServerInstance;
            obj.Server.UseUDP = true;
        end
        
        function CloseServerUDP(obj)
           % CloseServerUDP   Closes a UDP server if launched
           disp('Closing UDP Server...')
           fclose(obj.Server.ServerInstance);
           disp('Server closed.')
        end
        
        % Configuration settings
        function setInstruments(obj, instrumentArrayIn)
            % Set the instruments in the server
            obj.Instrument.InstrumentPathArray = instrumentArrayIn;
        end
                
        function setMode(obj, modeStringIn)
            % don't update the stored arbconfig file, just a local copy
            obj.Instrument.ArbConfig.model = modeStringIn;
            
%             % Sets the arbconfig correctly
%             if obj.Server.DebugMode
%                disp('Loading arb config file...') 
%             end
%             
%             arbConfigMod = load(iqarbConfigFilename());
%             arbConfig = arbConfigMod.arbConfig;
%             
%             if ~isfield(arbConfigMod, 'saConfig')
%                 arbConfigMod.('saConfig') = [];
%             end
%             
%             saConfig = arbConfigMod.saConfig;
%             
%             if obj.Server.DebugMode
%                disp('Saving arb config file...') 
%             end
%             
%             arbConfig.model = modeStringIn;
%             save(iqarbConfigFilename(), 'arbConfig', 'saConfig');    
%             
%             if obj.Server.DebugMode
%                disp('File saved.') 
%             end
        end
        
        function Reset(obj)
            % reset server parameters
            obj.Server.ErrorQueue = {'0'};                   % clear the error queue
            obj.Correction.UseCorrection = 0;                % Whether or not to use corrections
            obj.Correction.CorrectionFilePath = '';          % The correction file path
            obj.Instrument.ChannelMapping = [1 0; 0 1];      % The channel mapping of the instrument
            obj.Instrument.SegmentNumber = 1;                % Waveforms are downloaded to this segment
            obj.Instrument.FileSaveType = '16-bit I/Q MSB';  % The file type                
            obj.DefaultPulse();
            obj.DefaultPulseCombo();
            obj.DefaultTone();
            obj.DefaultSerial();
            obj.DefaultMTCal();
            obj.Instrument.ArbConfig = loadArbConfig();      % load the stored arbConfig from file
            obj.Instrument.SampleRateinHz = obj.Instrument.ArbConfig.defaultSampleRate;
        end

        %% Custom command methods
                
        function ExecuteScriptCommandCurrent(obj)
            % ExecuteScriptCommandCurrent   Executes a single command
            if obj.Server.DebugMode
                disp(['Executing:' obj.Scripting.ScriptCommandCurrent])
            end

            % Execute the command and log error if error
            try
                eval(obj.Scripting.ScriptCommandCurrent);
            catch ex
                disp(['Error executing command: ' getReport(ex,'extended')]);
                obj.Server.ErrorQueue{end + 1} = ['Error executing command: ' ex.message];
            end 
        end
                
        function ExecuteCommandList(obj)
            % ExecuteCommandList    Executes the command list
            if obj.Server.DebugMode
                disp('Executing command list')
            end

            % Execute the command list
            try
                if length(obj.Scripting.ScriptCommandTable) > 0  
                    
                    % Get commands
                    commandArray = {obj.Scripting.ScriptCommandTable.command};
                    
                    % Execute each one
                    for commandIdx = 1:length(commandArray)
                        if obj.Server.DebugMode
                            disp(['Executing:' commandArray{commandIdx}])
                        end
                        
                        % Execute command
                        eval(commandArray{commandIdx});
                    end
                end
            catch ex
                disp(['Error executing command list: ' getReport(ex,'extended')]);
                obj.Server.ErrorQueue{end + 1} = ['Error executing command list: ' ex.message];
            end 
            

        end
                
        function DefaultCommand(obj)
            % DefaultCommand    Resets the current command
            obj.Scripting.ScriptCommandCurrent = '';
        end
                
        function DefaultCommandList(obj)
            % DefaultCommandList    Resets the command list
            obj.Scripting.ScriptCommandTable = [];
        end
                
        function commandStructureOut = CreateCommandStructure(obj)
            % CreateCommandStructure    Adds a command to the list (can add structure items if desired)
            commandStructureOut = struct(...
                'command', obj.Scripting.ScriptCommandCurrent);
        end
            
        %% Pulse generation methods
                
        function DefaultPulse(obj)
            % DefaultPulse  Reverts the pulse to default data
                        
            obj.PulseGen.PulseAmplitudeInDB = 0;  % The amplitude in DB
            obj.PulseGen.PulsePhaseInDegrees = 0;  % The phase of the signal in degrees
            obj.PulseGen.PulseFrequencyOffsetInHz = 0;  % The frequency offset of the signal in Hz
            obj.PulseGen.PulseShape = 'Raised Cosine';  % The rise shape of the pulse
            obj.PulseGen.PulseDelayInSeconds = 0;  % The delay time of the pulse in seconds
            obj.PulseGen.PulseModulationType = 'None';  % The modulation type of the pulse
            obj.PulseGen.PulseFilePathSave = 'PulseTemporary';  % The file path of the save
            obj.PulseGen.PulseFrequencyModulationFormula = '0';  % The frequency modulation formula if custom
            obj.PulseGen.PulsePhaseModulationFormula = '0';  % The phase modulation formula if custom
            obj.PulseGen.PulsePhaseTransitionState = 'coherent';  % The phase change rules
            obj.PulseGen.PulseNormalize = 1;  % 1: scale to full DAC range, 0: use PulseAmplitudeInDB as dbFS

            switch obj.Instrument.ModeString
               case {'Vector', 'Vector Internal'}  %
                    obj.Instrument.SampleRateInHz = 250E6;
                    obj.PulseGen.PulseDwellInSeconds = 8E-6;  % The dwell of the iq snippet in seconds
                    obj.PulseGen.PulseWidthInSeconds = 2E-6;  % The width of the pulse in seconds
                    obj.PulseGen.PulseRiseTimeInSeconds = 20E-9;  % The rise time of the pulse in seconds
                    obj.PulseGen.PulseFallTimeInSeconds = 20E-9;  % The fall time of the pulse in seconds
                    
                    obj.PulseGen.PulseModulationFrequencySpan = 100E6;  % The modulation frequency span of the pulse                       
                case {'Wideband Vector'}   % 
                    obj.Instrument.SampleRateInHz = 2E9;  % The sample rate can only be 2 GHz
                    obj.PulseGen.PulseDwellInSeconds = 8E-6;  % The dwell of the iq snippet in seconds
                    obj.PulseGen.PulseWidthInSeconds = 2E-6;  % The width of the pulse in seconds
                    obj.PulseGen.PulseRiseTimeInSeconds = 20E-9;  % The rise time of the pulse in seconds
                    obj.PulseGen.PulseFallTimeInSeconds = 20E-9;  % The fall time of the pulse in seconds

                    obj.PulseGen.PulseModulationFrequencySpan = 500E6;  % The modulation frequency span of the pulse     
                case 'M8190A_12bit'  % M8190A
                    obj.Instrument.SampleRateInHz = 12E9;  % The sample rate can only be 2 GHz
                    obj.PulseGen.PulseDwellInSeconds = 8E-6;  % The dwell of the iq snippet in seconds
                    obj.PulseGen.PulseWidthInSeconds = 2E-6;  % The width of the pulse in seconds
                    obj.PulseGen.PulseRiseTimeInSeconds = 20E-9;  % The rise time of the pulse in seconds
                    obj.PulseGen.PulseFallTimeInSeconds = 20E-9;  % The fall time of the pulse in seconds

                    obj.PulseGen.PulseModulationFrequencySpan = 2E9;  % The modulation frequency span of the pulse 
                    obj.PulseGen.PulseFrequencyOffsetInHz = 2E9;
                case 'M8190A_14bit'  % M8190A
                    obj.Instrument.SampleRateInHz = 8E9;  % The sample rate can only be 2 GHz
                    obj.PulseGen.PulseDwellInSeconds = 8E-6;  % The dwell of the iq snippet in seconds
                    obj.PulseGen.PulseWidthInSeconds = 2E-6;  % The width of the pulse in seconds
                    obj.PulseGen.PulseRiseTimeInSeconds = 20E-9;  % The rise time of the pulse in seconds
                    obj.PulseGen.PulseFallTimeInSeconds = 20E-9;  % The fall time of the pulse in seconds

                    obj.PulseGen.PulseModulationFrequencySpan = 2E9;  % The modulation frequency span of the pulse 
                    obj.PulseGen.PulseFrequencyOffsetInHz = 2E9;
            end            
        end
        
        function DefaultPulseCombo(obj)
            % DefaultPulseCombo Reverts the pulse combining properties to defaults
            
            obj.Correction.UseCorrection = 0;
            obj.PulseCombineGen.MultiPulseStartTimeInSeconds = 0;
            obj.PulseCombineGen.MultiPulseTable = [];
            obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB = 0;
            obj.PulseCombineGen.MultiPulseTransitionType = 'coherent';
            obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees = 0;
            

            obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB = 0;
            obj.PulseCombineGen.MultiPulseTimeShiftInS = 0;
            obj.PulseCombineGen.MultiPulseProcessFile = [];
        end
                
		function pulseStructureOut = CreatePulseStructure(obj)
            % If any of the start time, powers, transition types, or base
            % phases are larger than one, create N pulse structures to that
            % length and do a repeat of everything else
            
            
            if ~iscell(obj.PulseCombineGen.MultiPulseTransitionType)
                obj.PulseCombineGen.MultiPulseTransitionType = {obj.PulseCombineGen.MultiPulseTransitionType};
            end
            
            numPulse = max([length(obj.PulseCombineGen.MultiPulseStartTimeInSeconds)...
                length(obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB)...
                length(obj.PulseCombineGen.MultiPulseTransitionType)...
                length(obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees)]);

            if numPulse == 1
                % CreatePulseStructure  Creates a pulse structure for combining
                pulseStructureOut = struct(...
                                    'startTime', obj.PulseCombineGen.MultiPulseStartTimeInSeconds,...
                                    'basePower', obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB,...
                                    'transitionType', obj.PulseCombineGen.MultiPulseTransitionType,...
                                    'basePhase', obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees,...
                                    'sampleRate', obj.Instrument.SampleRateInHz,...
                                    'PRI', obj.PulseGen.PulseDwellInSeconds,...
                                    'PW', obj.PulseGen.PulseWidthInSeconds,...
                                    'riseTime', obj.PulseGen.PulseRiseTimeInSeconds,...
                                    'fallTime', obj.PulseGen.PulseFallTimeInSeconds,...
                                    'pulseShape', obj.PulseGen.PulseShape,...
                                    'span', obj.PulseGen.PulseModulationFrequencySpan,...
                                    'offset', obj.PulseGen.PulseFrequencyOffsetInHz,...
                                    'amplitude', obj.PulseGen.PulseAmplitudeInDB,...
                                    'fmFormula', obj.PulseGen.PulseFrequencyModulationFormula,...
                                    'pmFormula', obj.PulseGen.PulsePhaseModulationFormula,...
                                    'exactPRI', 0, ...
                                    'modulationType', obj.PulseGen.PulseModulationType,...
                                    'correction', obj.Correction.UseCorrection,...
                                    'delay', obj.PulseGen.PulseDelayInSeconds,...
                                    'phase', obj.PulseGen.PulsePhaseInDegrees,...
                                    'continuousPhase', obj.PulseGen.PulsePhaseTransitionState,...
                                    'channelMapping', obj.Instrument.ChannelMapping);
            else
                % extend all the other parameter vectors to match the number of pulses
                multiPulseStartTimeInSeconds = obj.fixlength(obj.PulseCombineGen.MultiPulseStartTimeInSeconds, numPulse);
                multiPulseBasePulseAmplitudeInDB = obj.fixlength(obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB, numPulse);
                multiPulseBasePulsePhaseInDegrees = obj.fixlength(obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees, numPulse);
                
                if ~iscell(obj.PulseCombineGen.MultiPulseTransitionType)
                    obj.PulseCombineGen.MultiPulseTransitionType = {obj.PulseCombineGen.MultiPulseTransitionType};
                end
                multiPulseTransitionType = obj.fixlength(obj.PulseCombineGen.MultiPulseTransitionType, numPulse);
                
                
                % Create N structures of pulses
                pulseStructureOut = [];
                
                for pulseIdx = 1:numPulse
                    pulseStructureOut = [pulseStructureOut; struct(...
                                    'startTime', multiPulseStartTimeInSeconds(pulseIdx),...
                                    'basePower', multiPulseBasePulseAmplitudeInDB(pulseIdx),...
                                    'transitionType', multiPulseTransitionType(pulseIdx),...
                                    'basePhase', multiPulseBasePulsePhaseInDegrees(pulseIdx),...
                                    'sampleRate', obj.Instrument.SampleRateInHz,...
                                    'PRI', obj.PulseGen.PulseDwellInSeconds,...
                                    'PW', obj.PulseGen.PulseWidthInSeconds,...
                                    'riseTime', obj.PulseGen.PulseRiseTimeInSeconds,...
                                    'fallTime', obj.PulseGen.PulseFallTimeInSeconds,...
                                    'pulseShape', obj.PulseGen.PulseShape,...
                                    'span', obj.PulseGen.PulseModulationFrequencySpan,...
                                    'offset', obj.PulseGen.PulseFrequencyOffsetInHz,...
                                    'amplitude', obj.PulseGen.PulseAmplitudeInDB,...
                                    'fmFormula', obj.PulseGen.PulseFrequencyModulationFormula,...
                                    'pmFormula', obj.PulseGen.PulsePhaseModulationFormula,...
                                    'exactPRI', 0, ...
                                    'modulationType', obj.PulseGen.PulseModulationType,...
                                    'correction', obj.Correction.UseCorrection,...
                                    'delay', obj.PulseGen.PulseDelayInSeconds,...
                                    'phase', obj.PulseGen.PulsePhaseInDegrees,...
                                    'continuousPhase', obj.PulseGen.PulsePhaseTransitionState,...
                                    'channelMapping', obj.Instrument.ChannelMapping)];
                    
                end
            end                       
        end
        
        function x = fixlength(obj, x, len)
        % make a vector with <len> elements by duplicating or cutting <x> as
        % necessary
            if (~isempty(x))
                x = reshape(x, 1, length(x));
                x = repmat(x, 1, ceil(len / length(x)));
                x = x(1:len);
            end
        end
                                          
        %% Tone generation methods
        
        function DefaultTone(obj)
            % DefaultTone - reset tone parameters
            obj.ToneGen.SampleCount = 0;           % number of samples (0 = automatic)
            obj.ToneGen.StartFrequency = 100e6;    % start frequency in Hz
            obj.ToneGen.StopFrequency = 900e6;     % stop frequency in Hz
            obj.ToneGen.ToneCount = 9;             % number of tones
            obj.ToneGen.ToneSpacing = 100e6;       % tone spacing
            obj.ToneGen.NotchFrequency = 0;        % notch frequency in Hz
            obj.ToneGen.NotchSpan = 0;             % notch span in Hz
            obj.ToneGen.NotchDepth = -1000;        % notch depth in dB
            obj.ToneGen.ToneMagnitude = 0;         % magnitude in dBFS (if normalize == 0)
            obj.ToneGen.TonePhase = 'Random';      % phase in degrees or 'Random'
            obj.ToneGen.ToneNormalize = 1;         % 1:scale to DAC full range, 0: use magnitude as dBFS
            obj.ToneGen.dBFS = 0;                  % will be populated with dBFS after download
        end
        
        %% RF Tuning methods
        
        function TuneRF(obj, carrierFrequencyIn, carrierAmplitudeIn, outputOnIn)
           % TuneRF  Tunes a signal to the specific frequency and
           % power, and amplitude
           
           % Since the commands are rather similar and simple, just respond
           % to case structures for now
            switch lower(obj.Instrument.Type)
                case 'signalgenerator'  % Signal generator
                    
                    % Connect
                    arbConfig = loadArbConfig(obj.Instrument.ArbConfig);
                    f = iqopen(arbConfig);
                    if (isempty(f))
                        return;
                    end
                    
                    % Send the commands
                    try
                        fprintf(f, [':SOURce:FREQuency ' num2str(carrierFrequencyIn)]);
                        fprintf(f, [':POWer ' num2str(carrierAmplitudeIn)]);
                        fprintf(f, [':OUTPut:STATe ' num2str(outputOnIn)]);
                    catch
                        
                    end
                    
                    % Close
                    fclose(f);delete(f);  
                    
                otherwise
            end
            
        end
        
        %% Command parsing methods
                
        function parseReceivedDataAndReact(obj, tcpipObj, ~)
            % parseReceivedDataAndReact parses the received data and decides what to do with the commands
            
            % fscanf may not read to the end of line
            % dataIn = strtrim(fscanf(tcpipObj, '%c', tcpipObj.BytesAvailable));
            dataIn = strtrim(fgetl(tcpipObj));
            
            if (obj.Server.DebugMode)
                fprintf('recv: %s\n', dataIn);
            end
            
            if (~isempty(dataIn))
                obj.parseCommandData(dataIn);
            end
            
            if (obj.Server.CloseImmediate && obj.Server.UseUDP == false)
                % close and re-start the TCPIP server
                fclose(obj.Server.ServerInstance);
                fopen(obj.Server.ServerInstance);
            end
        end
        
                
        function sendResponse(obj, s)
            % send a response to a query
            fprintf(obj.Server.ServerInstance, '%s\n', s);
        end
        
                               
        function setget(obj, varName, type)
            % set or get the value of variable <varName> (Note: pass <varName> as a string!)
            % to be done: check for correct data type (<type>)
            
            if (isempty(obj.Server.ParseNext))
                obj.setError('syntax error (expected a "?" or a parameter after a command)');
            else
                switch obj.Server.ParseNext(1)           
                    case ' ' % command
                        val = strtrim(obj.Server.ParseNext);
                        switch type
                            case 'string'
                                % if the argument is not enclosed in quotes, add them
                                if (~isempty(val) && val(1) ~= '''')
                                    val = ['''' val ''''];
                                end
                            case 'cell'
                                % if the argument is not enclosed in {...}, add them
                                if (~isempty(val) && val(1) ~= '{')
                                    val = ['{' val '}'];
                                end
                            case 'double'
                                % if the argument is not enclosed in [...], add them
                                if (~isempty(val) && val(1) ~= '[')
                                    val = ['[' val ']'];
                                end
                        end

                        if (obj.Server.DebugMode)
                            fprintf('setget: %s = %s\n', varName, val);
                        end
                        try
                            % make the variable assignment
                            % (ideally, I'd like to use "assignin", but can't
                            % figure out how to do this with class members)
                            eval([varName '=' val ';']);
                        catch ex
                            obj.setError(['cannot parse parameter: ' ex.message]);
                        end
                    case '?' % query
                        retVal = obj.toString(eval(varName));
                        if (obj.Server.DebugMode)
                            fprintf('setget: %s --> %s\n', varName, retVal);
                        end
                        fprintf(obj.Server.ServerInstance, '%s\n', retVal);
                    otherwise
                        obj.setError('syntax error (expect "?" or " " after command)');
                end % switch
            end % isempty
        end % function
        
                
        function found = parseToken(obj, s)
            % check, if the next token in the command line equals <s>
            % if yes, return true and advance the ParseNext pointer; otherwise return false.
            [token, remainder] = strtok(obj.Server.ParseNext, ':? ');
            % consider a match if delimiter is a ":" and <s> equals the
            % beginning of the next token (e.g. PULS would also match :PULSE)
            found = (~isempty(obj.Server.ParseNext) && obj.Server.ParseNext(1) == ':' && strncmpi(s, token, length(s)));
            % if a match is found, advance ParseNext
            if (found)
                obj.Server.ParseNext = remainder;
            end
        end
        
                
        function arg = parseArguments(obj, numArgs)
            % parse the arguments of a command
            % returns cell array of arguments
            % For now, simply put { } around it and call eval
            % can be made more foolproof and sophisticated...
            try
                arg = eval(['{' obj.Server.ParseNext '}']);
            catch ex
                obj.setError('error parsing arguments');
                arg = '';
            end
            if (length(arg) ~= numArgs)
                obj.setError('wrong number of arguments');
                arg = cell(numArgs, 1);
            end
        end
        
                
        function setError(obj, s)
            % add an error to the error queue
            obj.Server.ErrorQueue{end + 1} = strtrim(strrep(s, newline, ''));
        end
        
                
        function setCommandError(obj)
            % report an "unknown command" error
            obj.setError(['unknown command: ' obj.Server.CurrentCommand]);
        end
        
        
        function setQueryOnlyError(obj)
            % report a "query only" error
            obj.setError('this command is only available as query');
        end
        
        
        function setCommandOnlyError(obj)
            % report a "command only" error
            obj.setError('this command is only available as a command');
        end
        
                                      
        function parseCommandData(obj, dataIn)
            % parseCommandData  Parses the command
                        
            isCommand = false;
            % initialize the parsing process
            obj.Server.CurrentCommand = dataIn;
            obj.Server.ParseNext = dataIn;

            % Check if generic command
            if dataIn(1) == '*'
                % Standard SCPI
                isCommand = obj.parseGenericData(dataIn);              
            else  
                try
                    if obj.parseToken('INST')  % Instrument specific
                      isCommand = obj.parseInstrumentCommands(dataIn);
                    elseif obj.parseToken('GEN')  % Signal generation commands
                      isCommand = obj.parseGenerateCommands(dataIn);
                    elseif obj.parseToken('SYST')  % System level commands
                      isCommand = obj.parseSystemCommands(dataIn);
                    elseif obj.parseToken('SCRIPT')  % Scripting commands
                      isCommand = obj.parseScriptingCommands(dataIn);
                    elseif obj.parseToken('CAL')  % Calibration commands
                      isCommand = obj.parseCalibrationCommands(dataIn);
                    elseif (obj.parseToken('MTC') || obj.parseToken('MTCAL')) % Multi-tone Calibration
                      isCommand = parseMTCalCommands(obj, dataIn);
                    end
                
                catch ex
                    disp(getReport(ex));
                    isCommand = false;
                end
            end
                
            if isCommand ~= true                
                % If the command contains null data, try and modify and
                % test once more
                if any(contains(dataIn, sprintf('\0')))
                    obj.parseCommandData(strrep(dataIn, sprintf('\0'), ''))
                else
                    fprintf('command error: %s\n', dataIn);
                    obj.setCommandError();
                end                
            end
        end
                
        %% Calibration methods
        
        function executeCQMCalibration(obj)
           
            % Generate the tones for a calibration based on the given
            % parameters
            
            % Get the tone count, frequencies, magnitudes
            toneCount =...
                round(obj.Calibration.ComplexCalibrationSpanInHz / obj.Calibration.ComplexCalibrationSpacingInHz) + 1;
            
            toneFrequencies =...
                linspace(-1 * (obj.Calibration.ComplexCalibrationSpanInHz / 2),...
                (obj.Calibration.ComplexCalibrationSpanInHz / 2), toneCount) ;
            
            toneMagnitudes = zeros(1, toneCount);
            
            % Generate an initial array of tones
            [iqdata, freq, magnitude, phase, chMap] = iqtone('sampleRate', obj.Instrument.SampleRateInHz, 'numSamples', 0, ...
            'tone', toneFrequencies, 'phase', 'Parabolic', 'normalize', 1, 'arbConfig', obj.Instrument.ArbConfig, ...
            'magnitude', toneMagnitudes, 'correction', 0, 'channelMapping', obj.Instrument.ChannelMapping);
        
            % If recalibrating
            if obj.Calibration.Recalibrate
                [iqdata, ~, ~, ~, chMap] = iqtone('sampleRate', obj.Instrument.SampleRateInHz, 'numSamples', 0, ...
                'tone', toneFrequencies, 'phase', 'Parabolic', 'normalize', 1, 'arbConfig', obj.Instrument.ArbConfig, ...
                'magnitude', toneMagnitudes, 'correction', 1, 'channelMapping', obj.Instrument.ChannelMapping);
            end
            
            % Download them
            if obj.Calibration.Initialize
                iqdownload(iqdata, obj.Instrument.SampleRateInHz, 'arbConfig', obj.Instrument.ArbConfig, 'channelMapping', chMap,...
                    'segmentNumber', obj.Instrument.SegmentNumber, 'segmname', obj.Instrument.SegmentName,...
                    'loamplitude', obj.Instrument.RFAmplitude, 'lofcenter', obj.Instrument.RFFrequency);
            end
            
            % Perform the calibration
            iqvsacqm('recalibrate', obj.Calibration.Recalibrate,...
                'tone', freq, 'mag', magnitude, 'phase', phase, 'fc', obj.Calibration.ComplexCalibrationCenterFrequencyInHz,...
                'usefile', false, 'initialize', obj.Calibration.Initialize, 'settletime', obj.Calibration.ComplexCalibrationSettleTimeInS,...
                'autorange', obj.Calibration.AutoRange, 'rangeindbm', obj.Calibration.RangeInDBm);            
        end
        
        %% Command documentation methods
        
        function DocumentCommandDataTextFile(obj, filePathIn)
            % DocumentCommandData   Saves the commands to the file in plain text
            
            % First open this file
            fileReadPath = mfilename('fullpath');
            
            if ~endsWith(fileReadPath, '.m')
                fileReadPath = [fileReadPath '.m'];
            end
            
            if obj.Server.DebugMode
                disp(['Reading file: ' fileReadPath])
            end
            
            fileRead = fileread(fileReadPath);
                        
            % Now break the file apart by commands and write to them
            matchStringBreak = 'break';
            matchStringCommands = 'document';
            matchStringName = 'command';
            matchStringType = 'type';
            matchStringDescription = 'description';
            matchStringExample = 'example';
            
            % List of documented commands
            commandDocumentation = regexp(fileRead,...
                ['<' matchStringCommands '>(.*?|\n)*?<\/' matchStringCommands '>'], 'tokens');
            
            % For each, write the markup'd text
            commandDocumentLength = length(commandDocumentation);
            
            if obj.Server.DebugMode
                disp(['Command count: ' num2str(commandDocumentLength)])
            end
            
            if commandDocumentLength > 0
                                
                % Create a file
                fileWrite = fopen(filePathIn, 'w');
                fprintf(fileWrite, ['Command Set' newline newline]);
                
                if obj.Server.DebugMode
                    disp(['Creating file: ' filePathIn])
                end
                
                if obj.Server.DebugMode
                    disp('Documenting commands...')
                end
                
                for commandIndex = 1:commandDocumentLength
                    commandStringDocument = '';
                    
                    % See if there is a break
                    
                    commandBreak = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringBreak '>(.*?|\n)*?<\/' matchStringBreak '>'], 'tokens');
                        
                    if ~isempty(commandBreak)
                        commandStringDocument = ['----------------------------------------'...
                            newline commandBreak{1}{1} newline newline];
                    end
                                   
                    try                    
                        % Get the command
                        commandName = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringName '>(.*?|\n)*?<\/' matchStringName '>'], 'tokens');

                        commandStringDocument = [commandStringDocument 'Command: ' commandName{1}{1} newline];

                        % Then the type
                        commandType = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringType '>(.*?|\n)*?<\/' matchStringType '>'], 'tokens');

                        commandStringDocument = [commandStringDocument 'Type: ' commandType{1}{1} newline];
                        
                        % Then the description
                        commandDescription = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringDescription '>(.*?|\n)*?<\/' matchStringDescription '>'], 'tokens');

                        commandStringDocument = [commandStringDocument 'Description: ' commandDescription{1}{1} newline];
                        
                        % Then the example
                        commandExample = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringExample '>(.*?|\n)*?<\/' matchStringExample '>'], 'tokens');

                        commandStringDocument = [commandStringDocument 'Example: ' commandExample{1}{1} newline newline];
                        
                    catch
                        
                    end
                    
                    if obj.Server.DebugMode
                        disp(commandStringDocument)
                    end
                    
                    % Write to the file
                    fprintf(fileWrite, commandStringDocument);
                end
                
                % Close the file
                fclose(fileWrite);
                
                if obj.Server.DebugMode
                    disp('File document complete')  
                end
                
                disp(['Documented commands saved to ' filePathIn])
            end            
        end
                    
        function DocumentCommandDataHTMLFile(obj)
            % DocumentCommandDataHTMLFile   Saves the commands to the file in plain text
            
%            filePathDocumentationHTML = fullfile(iqScratchDir(), 'IQToolsServerCommands.html');
            filePathDocumentationHTML = fullfile('C:', 'temp', 'IQToolsServerCommands.html');
            
            % First open this file
            fileReadPath = mfilename('fullpath');
            
            if ~endsWith(fileReadPath, '.m')
                fileReadPath = [fileReadPath '.m'];
            end
            
            if obj.Server.DebugMode
                disp(['Reading file: ' fileReadPath]);
            end
            
            fileRead = fileread(fileReadPath);
                        
            % Now break the file apart by commands and write to them
            matchStringBreak = 'break';
            matchStringCommands = 'document';
            matchStringName = 'command';
            matchStringType = 'type';
            matchStringDescription = 'description';
            matchStringExample = 'example';
            
            % List of documented commands
            commandDocumentation = regexp(fileRead,...
                ['<' matchStringCommands '>(.*?|\n)*?<\/' matchStringCommands '>'], 'tokens');
            
            % For each, write the markup'd text
            commandDocumentLength = length(commandDocumentation);
            
            if obj.Server.DebugMode
                disp(['Command count: ' num2str(commandDocumentLength)]);
            end
            
            if commandDocumentLength > 0
                                
                % Create a file
                fileWrite = fopen(filePathDocumentationHTML, 'w');
                fprintf(fileWrite, ['<HTML><HEAD><TITLE>IQTools Server Command Set</TITLE></HEAD>' newline]);
                fprintf(fileWrite, ['<HR><H1>IQTools Server Command Set</H1>' newline]);
                fprintf(fileWrite, ['<H3>' obj.Server.ModelString ' ' iqversion() '</H3>' newline]);
                
                if obj.Server.DebugMode
                    disp(['Creating file: ' filePathDocumentationHTML])
                end
                
                if obj.Server.DebugMode
                    disp('Documenting commands...')
                end
                
                for commandIndex = 1:commandDocumentLength
                    commandStringDocument = '';
                    
                    % See if there is a break                    
                    commandBreak = regexp(commandDocumentation{commandIndex}{1},...
                            ['<' matchStringBreak '>(.*?|\n)*?<\/' matchStringBreak '>'], 'tokens');
                        
                    if ~isempty(commandBreak)
                        commandStringDocument = ['<hr><H2>' commandBreak{1}{1} '</H2>' newline];
                                        
                    else
                        try                    
                            % Get the command
                            commandName = regexp(commandDocumentation{commandIndex}{1},...
                                ['<' matchStringName '>(.*?|\n)*?<\/' matchStringName '>'], 'tokens');

                            commandStringDocument = [commandStringDocument '<P><B>Command: ' strrep(strrep(commandName{1}{1},'<','&#60;'), '>','&#62;') '</B>' newline];

                            % Then the type
                            commandType = regexp(commandDocumentation{commandIndex}{1},...
                                ['<' matchStringType '>(.*?|\n)*?<\/' matchStringType '>'], 'tokens');

                            commandStringDocument = [commandStringDocument '<BR>Type: ' commandType{1}{1} newline];

                            % Then the description
                            commandDescription = regexp(commandDocumentation{commandIndex}{1},...
                                ['<' matchStringDescription '>(.*?|\n)*?<\/' matchStringDescription '>'], 'tokens');

                            commandStringDocument = [commandStringDocument '<BR>Description: ' commandDescription{1}{1} newline];

                            % Then the example
                            commandExample = regexp(commandDocumentation{commandIndex}{1},...
                                ['<' matchStringExample '>(.*?|\n)*?<\/' matchStringExample '>'], 'tokens');

                            commandStringDocument = [commandStringDocument '<BR>Example: ' commandExample{1}{1} newline newline];

                        catch

                        end
                    end
                    
                    if obj.Server.DebugMode
                        disp(commandStringDocument)
                    end
                    
                    % Write to the file
                    fprintf(fileWrite, commandStringDocument);
                end
                
                % Add the last tags
                fprintf(fileWrite, '</HR></HTML>');
                
                % Close the file
                fclose(fileWrite);
                
                % Open the file
                winopen(filePathDocumentationHTML);
                
                if obj.Server.DebugMode
                    disp('File document complete')  
                end
                
                disp(['Documented commands saved to ' filePathDocumentationHTML])
            end            
        end
        
        %% Parse * commands
        
        function isCommand = parseGenericData(obj, dataIn)   
            % parseGenericData  Parses generic commands (*)
            
            % <document>
            % <break>Generic Commands (*)</break>
            % </document>
            
            isCommand = true;
        
            if contains(dataIn, 'IDN?')
                % <document>
                % <command>*IDN?</command>
                % <type>Query Only</type>
                % <description>Returns the name and version of the server</description>
                % <example>*IDN?</example>
                % </document>
                fprintf(obj.Server.ServerInstance, sprintf('%s %s', obj.Server.ModelString, iqversion()));
            elseif contains(dataIn, 'OPC?')
                % <document>
                % <command>*OPC?</command>
                % <type>Query Only</type>
                % <description>Returns a '1' when all operations are complete</description>
                % <example>*OPC?</example>
                % </document>
                fprintf(obj.Server.ServerInstance, '1');
            elseif contains(dataIn, 'RST')
                % <document>
                % <command>*RST</command>
                % <type>Command only</type>
                % <description>Resets the server to its default values</description>
                % <example>*RST</example>
                % </document>
                obj.Reset();
            elseif contains(dataIn, 'CLS')
                % <document>
                % <command>*CLS</command>
                % <type>Command only</type>
                % <description>Clears the error queue</description>
                % <example>*CLS</example>
                % </document>
                obj.Server.ErrorQueue = {'0'};
            else
                isCommand = false;
            end
        end
        
        %% Parse INST commands
        
        function isCommand = parseInstrumentCommands(obj, dataIn)
            % parseInstrumentCommands  Parses instrument commands (:INST)
            
            % <document>
            % <break>Instrument Commands (:INST)</break>
            % </document>
            
            isCommand = true;
        
            if obj.parseToken('MODE')
                if (obj.Server.ParseNext(1) == '?')
                    % <document>
                    % <command>:INST:MODE <Mode String></command>
                    % <type>Command and Query</type>
                    % <description>Gets or sets the server's instrument mode (M8190A_12bit, M8190A_14bit)</description>
                    % <example>:INST:MODE?; :INST:MODE M8190A_12bit</example>
                    % </document>
                    acs = obj.Instrument.ArbConfig;
                    model = acs.model;
                    obj.Instrument.ModeString = model;
                    obj.sendResponse(model);
                else                                % use whatever is being passed
                    obj.Instrument.ModeString = strtrim(obj.Server.ParseNext);
                    obj.setMode(obj.Instrument.ModeString);
                    obj.DefaultPulse()
                end
                
            elseif obj.parseToken('CONFIG')
                % <document>
                % <command>:INST:CONFIG <attr>,<value> </command>
                % <type>Command and Query</type>
                % <description>Gets or sets configuration values. Valid attributes are: 'model', 'visaAddr', </description>
                % <example>:INST:CONFIG? 'model'        :INST:CONFIG 'model','M8196A'</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')  % query
                    obj.Server.ParseNext = obj.Server.ParseNext(2:end);
                    args = obj.parseArguments(1);
                    param = args{1};
                    if (isfield(obj.Instrument.ArbConfig, param))
                        obj.sendResponse(obj.toString(obj.Instrument.ArbConfig.(param)));
                    else
                        obj.setError(['No such field in arbConfig: "' param '"']);
                    end
                else % command
                    args = obj.parseArguments(2);
                    param = args{1};
                    if (isfield(obj.Instrument.ArbConfig, param))
                        value = args{2};
                        obj.Instrument.ArbConfig.(param) = value;
                    else
                        obj.setError(['No such field in arbConfig: "' param '"']);
                    end
                end
                
            elseif obj.parseToken('SCPI')
                % <document>
                % <command>:INST:SCPI <SCPI Command String></command>
                % <type>Command only</type>
                % <description>Sends a SCPI command to the configured instrument</description>
                % <example>:INST:SCPI *RST</example>
                % </document>
                if ~isempty(obj.Instrument.InstrumentPathArray)
                    dataSend = strsplit(dataIn, ':SCPI ');
                    dataSend = dataSend{2};
                    
                    for idx = 1:length(obj.Instrument.InstrumentPathArray)
                        try
                            if ~isempty(obj.Instrument.InstrumentPathArray{idx})
                                % Send the command
                                serverTemp = tcpip(obj.Instrument.InstrumentPathArray{idx}, 5025);
                                serverTemp.InputBufferSize = 10000;
                                serverTemp.OutputBufferSize = 10000;
                                serverTemp.Terminator = {'LF', 'LF'};
                                fopen(serverTemp);
                                fprintf(serverTemp, dataSend);
                                fclose(serverTemp);
                                delete(serverTemp);
                            end
                       catch ex
                           obj.Server.ErrorQueue{end + 1} = ['Error sending SCPI: ' ex.message];                                                  
                       end
                    end                    
                else
                    obj.Server.ErrorQueue{end + 1} = 'Error sending SCPI: No instruments specified';
                end
            elseif obj.parseToken('CHMAP')  % Set the channel mapping
                % <document>
                % <command>:INST:CHMAP <Channel Map String></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the configured instrument's channel mapping</description>
                % <example>:INST:CHMAP?; :INST:CHMAP [1 0; 0 1]</example>
                % </document>
                obj.setget('obj.Instrument.ChannelMapping', 'double');
                if (ischar(obj.Instrument.ChannelMapping))
                    % in case channel mapping was enclosed in quotes
                    obj.Instrument.ChannelMapping = eval(obj.Instrument.ChannelMapping);
                end
            elseif obj.parseToken('SNUM')  % Set/get the segment number
                % <document>
                % <command>:INST:SNUM <segmentNumber></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the segment number into which a waveform is downloaded</description>
                % <example>:INST:SNUM?; :INST:SNUM 1</example>
                % </document>
                obj.setget('obj.Instrument.SegmentNumber', 'double');
            elseif obj.parseToken('SNAME')  % Set/get the segment name
                % <document>
                % <command>:INST:SNAME <segmentName></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the segment name that is used for download</description>
                % <example>:INST:SNAME?; :INST:SNAME 'waveform001'</example>
                % </document>
                obj.setget('obj.Instrument.SegmentName', 'string');
            elseif obj.parseToken('FTYPE')  % Set the file save type
                % <document>
                % <command>:INST:FTYPE <Channel Map String></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the server's file save type</description>
                % <example>:INST:FTYPE?; :INST:FTYPE '16-bit I/Q MSB'</example>
                % </document>
                obj.setget('obj.Instrument.FileSaveType', 'string');
            elseif obj.parseToken('CORR')  % Set the corrections
                % <document>
                % <command>:INST:CORR <0 or 1></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the if corrections are enabled</description>
                % <example>:INST:CORR?; :INST:CORR 1</example>
                % </document>
                obj.setget('obj.Correction.UseCorrection', 'double');
            elseif obj.parseToken('FCORR')  % Set the correction file path
                % <document>
                % <command>:INST:FCORR <File Path></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the correction file path, which overwrites the current file present</description>
                % <example>:INST:FCORR?; :INST:FCORR 'ampCorr.mat'</example>
                % </document>
                obj.setget('obj.Correction.CorrectionFilePath', 'string');
                
                % Load the file
                try
                    copyfile(obj.Correction.CorrectionFilePath, iqampCorrFilename());
                catch ex
                    obj.setError(['cannot load correction file: ' ex.message]);
                end
            elseif obj.parseToken('RFFREQ')  % Set upconverting frequency
                % <document>
                % <command>:INST:RFFREQ <Frequency in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the carrier frequency for the signal if using a signal generator</description>
                % <example>:INST:RFFREQ?; :INST:RFFREQ 4E9</example>
                % </document>
                obj.setget('obj.Instrument.RFFrequency', 'double');
                
                try
                    obj.TuneRF(obj.Instrument.RFFrequency, obj.Instrument.RFAmplitude, obj.Instrument.RFOn)
                catch ex
                    obj.setError(['cannot tune to frequency: ' ex.message]);
                end
            elseif obj.parseToken('RFPOW')  % Set upconverting frequency
                % <document>
                % <command>:INST:RFPOW <Power in dBm></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the carrier power for the signal if using a signal generator</description>
                % <example>:INST:RFPOW?; :INST:RFPOW -20</example>
                % </document>
                obj.setget('obj.Instrument.RFAmplitude', 'double');
                
                try
                    obj.TuneRF(obj.Instrument.RFFrequency, obj.Instrument.RFAmplitude, obj.Instrument.RFOn)
                catch ex
                    obj.setError(['cannot set amplitude: ' ex.message]);
                end
            elseif obj.parseToken('RFON')  % Set upconverting state
                % <document>
                % <command>:INST:RFON <0 or 1></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the carrier output state</description>
                % <example>:INST:RFON?; :INST:RFON 1</example>
                % </document>
                obj.setget('obj.Instrument.RFOn', 'double');
                
                try
                    obj.TuneRF(obj.Instrument.RFFrequency, obj.Instrument.RFAmplitude, obj.Instrument.RFOn)
                catch ex
                    obj.setError(['cannot set amplitude: ' ex.message]);
                end
            else
                isCommand = false;
            end
        end
        
        %% Parse CAL commands
        
        function isCommand = parseCalibrationCommands(obj, dataIn)
            % parseCalibrationCommands  Parses calibration commands (:CAL)
            
            % <document>
            % <break>Calibration Commands (:CAL)</break>
            % </document>
            
            isCommand = true;
        
            if obj.parseToken('TYPE')  % Set the cal type
                % <document>                
                % <command>:CAL:TYPE <Calibration Type></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current calibration type to perform</description>
                % <example>:CAL:TYPE?; :CAL:TYPE vsachannel</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationType', 'string');
            elseif obj.parseToken('FSPAN')  % Set the span
                % <document>                
                % <command>:CAL:FSPAN <Span in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current calibration's frequency span in Hz</description>
                % <example>:CAL:FSPAN?; :CAL:FSPAN 1E9</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationSpanInHz', 'double');
            elseif obj.parseToken('FSPAC')  % Set the spacing
                % <document>                
                % <command>:CAL:FSPAC <Spacing in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current calibration's frequency spacing in Hz</description>
                % <example>:CAL:FSPAC?; :CAL:FSPAC 1E6</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationSpacingInHz', 'double');
            elseif obj.parseToken('FOFFS')  % Set the frequency offset
                % <document>                
                % <command>:CAL:FOFFS <Offset in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current calibration's frequency offset in Hz (useful to avoid LO feedthru)</description>
                % <example>:CAL:FOFFS?; :CAL:FOFFS 10E3</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationOffsetInHz', 'double');
            elseif obj.parseToken('FCENT')  % Set the tune frequency
                % <document>                
                % <command>:CAL:FCENT <Tune Frequency in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current calibration's center frequency in Hz</description>
                % <example>:CAL:FCENT?; :CAL:FCENT 10E9</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationCenterFrequencyInHz', 'double');
            elseif obj.parseToken('TSETT')  % Set the settling time for the measurement
                % <document>                
                % <command>:CAL:TSETT <Cal Measurement Time in S></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current calibration's measurement time in S</description>
                % <example>:CAL:TSETT?; :CAL:TSETT 2.5</example>
                % </document> 
                obj.setget('obj.Calibration.ComplexCalibrationSettleTimeInS', 'double');
            elseif obj.parseToken('FSAV')  % Set the cal save file path
                % <document>                
                % <command>:CAL:FSAV <Calibration file save path></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the file path a calibration file will be saved to</description>
                % <example>:CAL:FSAV?; :CAL:FSAV Cal_Save_FC_1E9</example>
                % </document> 
                obj.setget('obj.Calibration.CalibrationSavePath', 'string');
            elseif obj.parseToken('INIT')  % Set if cal initializes or just tunes and ranges
                % <document>                
                % <command>:CAL:INIT <0 or 1></command>
                % <type>Command and Query</type>
                % <description>Gets or sets whether or not the calibration runs through an initialization</description>
                % <example>:CAL:INIT?; :CAL:INIT 1</example>
                % </document> 
                obj.setget('obj.Calibration.Initialize', 'double'); 
            elseif obj.parseToken('ARANG')  % Set if cal autoranges or not
                % <document>                
                % <command>:CAL:ARANG <0 or 1></command>
                % <type>Command and Query</type>
                % <description>Gets or sets whether or not the calibration autoranges the front end</description>
                % <example>:CAL:ARANG?; :CAL:ARANG 1</example>
                % </document> 
                obj.setget('obj.Calibration.AutoRange', 'double'); 
            elseif obj.parseToken('RANG')  % Set cal manual range
                % <document>                
                % <command>:CAL:RANG <Power in dBm></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the power the calibration will range to</description>
                % <example>:CAL:RANG?; :CAL:RANG -10</example>
                % </document> 
                obj.setget('obj.Calibration.RangeInDBm', 'double'); 
            elseif obj.parseToken('EXE')  % Execute the calibration                
                % <document>
                % <command>:CAL:EXE</command>
                % <type>Command only</type>
                % <description>Performs a calibration based on the parameters defined</description>
                % <example>:CAL:EXE</example>
                % </document>
                isCommand = true;   
                                
                try
                    disp('Calibrating...')
                    obj.executeCQMCalibration()
                    disp('Calibration complete')
                catch ex
                    disp(['Error calibrating: ' ex.message])  
                    obj.Server.ErrorQueue{end + 1} = ['Error calibrating: ' ex.message];
                end  
            elseif obj.parseToken('SAVE')  % Save current calibration data to the defined path
                % <document>
                % <command>:CAL:SAVE</command>
                % <type>Command only</type>
                % <description>Saves the current calibration to the defined path</description>
                % <example>:GEN:PULS:SAVE</example>
                % </document>
                isCommand = true;                    
                try
                    disp('Saving calibration data...')           
                    
                    % Copy the current correction file to the new location
                    copyfile(iqampCorrFilename(), obj.Calibration.CalibrationSavePath);
                    disp('File saved!');

                catch ex
                    disp(['Error saving file: ' ex.message])  
                    obj.Server.ErrorQueue{end + 1} = ['Error saving file: ' ex.message];
                end                
            else
                isCommand = false;
            end
        end
 
        %% Parse SYST Commands
        
        function isCommand = parseSystemCommands(obj, dataIn)
            % parseSystemCommands  Parses system commands (:SYST)
            
            % <document>
            % <break>System Commands (:SYST)</break>
            % </document>
            
            isCommand = true;   
            
            if obj.parseToken('TCPIP')
                if (strncmpi(strtrim(obj.Server.ParseNext), 'CLOS', 4))  % Close the TCPIP server and listen for new connection
                  % <document>
                  % <UDP></UDP>
                  % <command>:SYST:TCPIP CLOSE</command>
                  % <type>Command only</type>
                  % <description>Closes the current TCPIP Server connection and listens again for a new connection</description>
                  % <example>:SYST:TCPIP CLOSE</example>
                  % </document>
                  if obj.Server.UseUDP == false
                      obj.CloseServerTCPIP()
                      % don't re-launch the server from here. This will
                      % be done from IQToolsServer_Launch
                      % obj.LaunchServerTCPIP()
                  end
               end
            elseif obj.parseToken('ERR')  % Return error or the last '0'
                % <document>
                % <command>:SYST:ERR?</command>
                % <type>Query Only</type>
                % <description>Return the last error in the error queue or '0' if no errors are present</description>
                % <example>:SYST:ERR?</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')
                    obj.sendResponse(obj.Server.ErrorQueue{end});
                    if (length(obj.Server.ErrorQueue) > 1)                    
                        obj.Server.ErrorQueue(end) = [];
                    end

                    if obj.Server.DebugMode
                       disp(['Error Queue size: ' num2str(length(obj.Server.ErrorQueue))])
                    end
                else
                    obj.setQueryOnlyError();
                end
                
            elseif obj.parseToken('DEBUG')
                % <document>
                % <command>:SYST:DEBUG <0 or 1></command>
                % <type>Command and Query</type>
                % <description>Gets or sets if debug mode is enabled</description>
                % <example>:SYST:DEBUG?; :SYST:DEBUG 1</example>
                % </document>                
                obj.setget('obj.Server.DebugMode', 'bool');

            else
                isCommand = false;
            end
        end
        
        %% Parse SCRIPT commands
        
        function isCommand = parseScriptingCommands(obj, dataIn)  
            % parseScriptingCommands    Parses scripting commands (:SCRIPT)
            
            % <document>
            % <break>Script Commands (:SCRIPT)</break>
            % </document>
            
            isCommand = false;

            if obj.parseToken('EVAL')  % Runs whatever it gets
                % <document>
                % <command>:SCRIPT:EVAL '<MATLAB syntax expression>'</command>
                % <type>Command and Query</type>
                % <description>Evaluates the expression and/or returns the expression's result</description>
                % <example>:SCRIPT:EVAL? '1 + 1'; :SCRIPT:EVAL 'plot(1:10, 2:2:20);'</example>
                % </document> 
                
                params = obj.Server.ParseNext;
                isQuery = false;
                if (params(1) == '?')
                    isQuery = true;
                    params = params(2:end);
                end
                params = strtrim(params);
                % Run it
                if obj.Server.DebugMode
                    disp(['Executing:' params])
                end
                result = [];
                try
                    if (isQuery)
                        result = eval(params);
                    else
                        % handle both quoted and unquoted commands
                        if (params(1) == '''' && params(end) == '''')
                            params = params(2:end-1);
                        end
                        eval(params);
                    end
                catch ex
                    disp(['Error executing command: ' getReport(ex,'extended')]);
                    obj.setError(['Error executing command: ' ex.message]);
                end
                % return the result of a query to the caller
                if (isQuery)
                    try
                        obj.sendResponse(obj.toString(result));
                    catch ex
                        disp(getReport(ex));
                    end
                end
                isCommand = true;
            elseif obj.parseToken('COMMAND')
                if obj.parseToken('SET')  % Set the current command
                    % <document>
                    % <command>:SCRIPT:COMMAND:SET '<MATLAB syntax expression>'</command>
                    % <type>Command and Query</type>
                    % <description>Gets or sets the command to evaulate with :EXE or add to a list with :LIST:ADD</description>
                    % <example>:SCRIPT:COMMAND:SET?; :SCRIPT:COMMAND:SET 'plot(1:10, 2:2:20);'</example>
                    % </document>                
                    isCommand = true;
                    obj.setget('obj.Scripting.ScriptCommandCurrent', 'cell');
                elseif obj.parseToken('RESET')  % Reset the current command
                    % <document>
                    % <command>:SCRIPT:COMMAND:RESET</command>
                    % <type>Command only</type>
                    % <description>Resets the current set command</description>
                    % <example>:SCRIPT:COMMAND:RESET</example>
                    % </document> 
                    isCommand = true;
                    obj.DefaultCommand();
                elseif obj.parseToken('EXE')  % Execute the current command
                    % <document>
                    % <command>:SCRIPT:COMMAND:EXE</command>
                    % <type>Command only</type>
                    % <description>Executes the current set command</description>
                    % <example>:SCRIPT:COMMAND:EXE</example>
                    % </document> 
                    isCommand = true;
                    obj.ExecuteScriptCommandCurrent();
                end
            elseif obj.parseToken('LIST')
                if obj.parseToken('ADD')  % Add the current command to the command list
                    % <document>
                    % <command>:SCRIPT:LIST:ADD</command>
                    % <type>Command only</type>
                    % <description>Adds the current set command to the list of commands to execute with :LIST:EXE</description>
                    % <example>:SCRIPT:COMMAND:EXE</example>
                    % </document> 
                    isCommand = true;
                    obj.setget('obj.Scripting.ScriptCommandCurrent', 'cell');
                    obj.Scripting.ScriptCommandTable = [obj.Scripting.ScriptCommandTable; obj.CreateCommandStructure()];
                elseif obj.parseToken('RESET')  % Reset the commands
                    % <document>
                    % <command>:SCRIPT:LIST:RESET</command>
                    % <type>Command only</type>
                    % <description>Resets the list of commands</description>
                    % <example>:SCRIPT:COMMAND:RESET</example>
                    % </document> 
                    isCommand = true;
                    obj.DefaultCommandList();              
                elseif obj.parseToken('COUNT')  % Get the length of the command list
                    % <document>
                    % <command>:SCRIPT:LIST:COUNT</command>
                    % <type>Query Only</type>
                    % <description>Gets the number of commands currently in the command list</description>
                    % <example>:SCRIPT:COMMAND:LIST:COUNT?</example>
                    % </document> 
                    if (obj.Server.ParseNext(1) == '?')
                        isCommand = true;
                        fprintf(obj.Server.ServerInstance, num2str(length(obj.Scripting.ScriptCommandTable)));
                    else
                        obj.setQueryOnlyError();
                    end
                elseif obj.parseToken('EXE')  % Run the list of commands
                    % <document>
                    % <command>:SCRIPT:LIST:EXE</command>
                    % <type>Command only</type>
                    % <description>Executes the current list of commands</description>
                    % <example>:SCRIPT:COMMAND:LIST:EXE</example>
                    % </document>
                    isCommand = true;
                    obj.ExecuteCommandList();
                end
            end
        end
        
                
        function result = toString(obj, x)
            % toString    Returns the current command as a string
            switch (class(x))
                case 'char'
                    result = sprintf('''%s''', x);
                case {'double', 'float'}
                    if (isscalar(x))
                        result = sprintf('%g', x);
                    elseif (length(size(x)) > 2)
                        result = sprintf('Error: cannot output arrays with more than 2 dimensions');
                    else
                        result = '[';
                        del = '';
                        for row = 1:size(x,1)
                            for col = 1:size(x,2)
                                result = sprintf('%s%s%g', result, del, x(row,col));
                                del = ',';
                            end
                            del = ';';
                        end
                        result = sprintf('%s]', result);
                    end
                case 'cell'
                    if (length(size(x)) > 2)
                        result = sprintf('Error: cannot output cell arrays with more than 2 dimensions');
                    else
                        result = '';
                        del = '{';
                        for row = 1:size(x,1)
                            for col = 1:size(x,2)
                                result = sprintf('%s%s%s', result, del, obj.toString(x{row,col}));
                                del = ',';
                            end
                            del = ';';
                        end
                        result = sprintf('%s}', result);
                    end
                otherwise
                    result = sprintf('Error: object of class %s', class(x));
            end
        end
                
        %% Parse GENs's (generating pulse data and saving)
        
        function isCommand = parseGenerateCommands(obj, dataIn) 
            % parseGenerateCommands    Parses generation commands (:GEN)
                        
            isCommand = false;
            
            if obj.parseToken('PULS')                
                isCommand = parsePulseGenerateCommands(obj, dataIn);
            elseif obj.parseToken('TONE')
                isCommand = parseToneGenerateCommands(obj, dataIn);
            elseif (obj.parseToken('SER') || obj.parseToken('SERIAL'))
                isCommand = parseSerialGenerateCommands(obj, dataIn);
            end
        end
                
        %% Parse GEN:PULS (generating pulse data and saving)
        
        function isCommand = parsePulseGenerateCommands(obj, dataIn) 
            % parsePulseGenerateCommands    Parses pulse generation commands (:GEN)
            
            % <document>
            % <break>Pulse Generation Commands (:GEN:PULS)</break>
            % </document>
            
            isCommand = false;
        
            if obj.parseToken('COMB')  % Combining commands
                isCommand = obj.parsePulseCombineCommands(dataIn);
            elseif obj.parseToken('SRAT')  % Set the sample rate
                % <document>                
                % <command>:GEN:PULS:SRAT <Sample Rate in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's sample rate in Hz</description>
                % <example>:GEN:PULS:SRAT?; :GEN:PULS:SRAT 2E9</example>
                % </document> 
                isCommand = true;
                obj.setget('obj.Instrument.SampleRateInHz', 'double');
            elseif obj.parseToken('RESET')  % Reset the pulse parameters
                % <document>
                % <command>:GEN:PULS:RESET</command>
                % <type>Command only</type>
                % <description>Resets the current pulse configuration to its default values</description>
                % <example>:GEN:PULS:RESET</example>
                % </document>
                isCommand = true;
                obj.DefaultPulse();
            elseif obj.parseToken('DWEL')  % Set the dwell
                % <document>
                % <command>:GEN:PULS:DWEL <Dwell Time in Seconds></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's dwell time/s (duration/s) in seconds</description>
                % <example>:GEN:PULS:DWEL?; :GEN:PULS:DWEL 100E-6; :GEN:PULS:DWEL [100E-6, 10E-6]</example>
                % </document> 
                isCommand = true;
                obj.setget('obj.PulseGen.PulseDwellInSeconds', 'double');
            elseif obj.parseToken('WIDT')  % Set the width
                % <document>
                % <command>:GEN:PULS:WIDT <Dwell Time in Seconds></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's width/s in seconds</description>
                % <example>:GEN:PULS:WIDT?; :GEN:PULS:WIDT 10E-6; :GEN:PULS:WIDT [10E-6, 1E-6]</example>
                % </document> 
                isCommand = true;
                obj.setget('obj.PulseGen.PulseWidthInSeconds', 'double');               
            elseif obj.parseToken('RISE')  % Set the rise time
                % <document>
                % <command>:GEN:PULS:RISE <Rise Time in Seconds></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's rise time/s in seconds</description>
                % <example>:GEN:PULS:RISE?; :GEN:PULS:RISE 10E-9; :GEN:PULS:RISE [10E-9, 20E-9]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseRiseTimeInSeconds', 'double');
            elseif obj.parseToken('FALL')  % Set the fall time
                % <document>
                % <command>:GEN:PULS:FALL <Fall Time in Seconds></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's fall time/s in seconds</description>
                % <example>:GEN:PULS:FALL?; :GEN:PULS:FALL 10E-9; :GEN:PULS:FALL [10E-9, 20E-9]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFallTimeInSeconds', 'double');
            elseif obj.parseToken('DELA')  % Set the delay from start
                % <document>
                % <command>:GEN:PULS:DELA <Delay Time in Seconds></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's delay time/s in seconds</description>
                % <example>:GEN:PULS:DELA?; :GEN:PULS:DELA 10E-9; :GEN:PULS:DELA [10E-9, 20E-9]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseDelayInSeconds', 'double');
            elseif obj.parseToken('AMP')  % Set the amplitudes
                % <document>
                % <command>:GEN:PULS:AMP <Relative Amplitudes in dB></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's relative amplitude/s in dB</description>
                % <example>:GEN:PULS:AMP?; :GEN:PULS:AMP [0, -6]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseAmplitudeInDB', 'double');
            elseif obj.parseToken('PHAS')  % Set the phases
                % <document>
                % <command>:GEN:PULS:PHAS <Phase in Degrees></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's phase/s in degrees</description>
                % <example>:GEN:PULS:PHAS?; :GEN:PULS:PHAS 90; :GEN:PULS:PHAS [90, 45]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulsePhaseInDegrees', 'double');
            elseif obj.parseToken('FREQOF')  % Set the frequency offsets
                % <document>
                % <command>:GEN:PULS:FREQOF <Frequency Offset in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's frequency offset/s in Hz</description>
                % <example>:GEN:PULS:FREQOF?; :GEN:PULS:FREQOF 10E6; :GEN:PULS:FREQOF [10E6, -50E6]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFrequencyOffsetInHz', 'double');
            elseif obj.parseToken('SHAP')  % Set the pulse shapes
                % <document>
                % <command>:GEN:PULS:SHAP <Pulse Shape String></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's pulse shape/s (Raised Cosine, Trapezodial, Gaussian, Zero signal during rise time)</description>
                % <example>:GEN:PULS:SHAP?; :GEN:PULS:SHAP Raised Cosine</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseShape', 'string');
            elseif obj.parseToken('MOD')  % Set the modulation types
                % <document>
                % <command>:GEN:PULS:MOD <Modulation Type Cell String Array></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's modulation type/s (None, Increasing, Decreasing, V-Shape, Inverted V, Barker-2 +-, Barker-2 ++, Barker-3, Barker-4 ++-+, Barker-4 +++-, Barker-5, Barker-7, Barker-11, Barker-13, Frank-4, Frank-6, FMCW)</description> 
                % <example>:GEN:PULS:MOD?; :GEN:PULS:MOD {'Increasing'}, :GEN:PULS:MOD {'Increasing', 'None'}</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseModulationType', 'cell');
            elseif obj.parseToken('FMOD')  % Set the frequency modulation formula
                % <document>
                % <command>:GEN:PULS:FMOD <MATLAB Syntax Modulation Formula></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's FM modulation formula. Use the variable "x" in the formula, which varies from 0 to 1 throughout the pulse</description> 
                % <example>:GEN:PULS:FMOD?; :GEN:PULS:FMOD cos(pi*(x-1))</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFrequencyModulationFormula', 'string');
            elseif obj.parseToken('FSPA')  % Set the spans
                % <document>
                % <command>:GEN:PULS:FSPA <Frequency Span in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's frequency FM span/s in Hz</description>
                % <example>:GEN:PULS:FSPA?; :GEN:PULS:FSPA 10E6; :GEN:PULS:FSPA [10E6, 50E6]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseModulationFrequencySpan', 'double');
            elseif obj.parseToken('PMOD')  % Set the phase modulation formula
                % <document>
                % <command>:GEN:PULS:PMOD <MATLAB Syntax Modulation Formula></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's PM modulation formula. Use the variable "x" in the formula, which varies from 0 to 1 throughout the pulse</description> 
                % <example>:GEN:PULS:PMOD?; :GEN:PULS:PMOD zeros(1,length(x)))</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulsePhaseModulationFormula', 'string');    
            elseif obj.parseToken('PTRAN')  % Set the phase transition types
                % <document>
                % <command>:GEN:PULS:PTRAN <Phase Transition Type Cell String Array></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's phase transition type/s (Coherent, Continuous, Exact, Bump)</description>
                % <example>:GEN:PULS:PTRAN?; :GEN:PULS:PTRAN {'Continuous'}; GEN:PULS:PTRAN {'Continuous', 'Coherent'}]</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulsePhaseTransitionState', 'cell');  
            elseif obj.parseToken('NORM')  % normalize
                % <document>
                % <command>:GEN:PULS:NORM <0|1></command>
                % <type>Command and Query</type>
                % <description>1: scale to full DAC range, 0: use :GEN:PULS:AMP as dbFS</description>
                % <example>:GEN:PULS:NORM?; :GEN:PULS:NORM 0</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseNormalize', 'double');
            elseif obj.parseToken('FSAV')  % Set the file save path
                % <document>
                % <command>:GEN:PULS:FSAV <File save path></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's file save path</description>
                % <example>:GEN:PULS:FSAV?; :GEN:PULS:FSAV Pulse_10_us</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFilePathSave', 'string');
            elseif obj.parseToken('SAVE')  % Save the single pulse to a file
                % <document>
                % <command>:GEN:PULS:SAVE</command>
                % <type>Command only</type>
                % <description>Calculates the I/Q Data for a pulse defined by its current settings, then saves to its defined path</description>
                % <example>:GEN:PULS:SAVE</example>
                % </document>
                isCommand = true; 
                try
                    disp('Saving waveform...')
                    disp(obj.PulseGen.PulseFilePathSave)
                    disp('Generating waveform IQ...')

                    [iqdata, ~, ~, ~] = obj.calculatePulse();

                    disp('IQ Generated.')
                    disp('Saving file...')

                    iqsavewaveform(iqdata, obj.Instrument.SampleRateInHz,...
                        'filename', obj.PulseGen.PulseFilePathSave,...
                        'filetype', obj.Instrument.FileSaveType)

                    disp(['File saved!' newline]);

                catch ex
                    disp(['Error saving file: ' ex.message])  
                    obj.Server.ErrorQueue{end + 1} = ['Error saving file: ' ex.message];
                end

            elseif obj.parseToken('VSA')  % Preview the single pulse in VSA
                % <document>
                % <command>:GEN:PULS:VSA</command>
                % <type>Command only</type>
                % <description>Calculates the I/Q Data for a pulse defined by its current settings, then loads it to 89601B VSA to preview</description>
                % <example>:GEN:PULS:VSA</example>
                % </document>
                isCommand = true; 
                try
                    disp('Loading waveform to VSA...')
                    disp('Generating waveform IQ...')

                    [iqdata, ~, ~, ~] = obj.calculatePulse();

                    disp('IQ Generated.')
                    disp('Loading to VSA...')

                    vsaApp = vsafunc([], 'open');

                    if (~isempty(vsaApp))
                        vsafunc(vsaApp, 'input', 1);
                        if(isreal(iqdata))
                            iqdata = complex(iqdata); %Added if no mod
                        end

                        vsafunc(vsaApp, 'load', iqdata, obj.Instrument.SampleRateInHz);
                    end

                    disp(['File loaded!' newline]);

                catch ex
                    disp(['Error loading file to VSA: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error loading file to VSA: ' ex.message];
                end            

            elseif obj.parseToken('DOWNLOAD')  % Download to an instrument
                % <document>
                % <command>:GEN:PULS:DOWNLOAD</command>
                % <type>Command only</type>
                % <description>Calculates the I/Q Data for a pulse defined by its current settings, then loads it to the defined instrument</description>
                % <example>:GEN:PULS:DOWNLOAD</example>
                % </document>
                isCommand = true; 
                try
                    disp('Downloading waveform...')
                    disp('Generating waveform IQ...')

                    [iqdata, marker, ~, chMap] = obj.calculatePulse();

                    disp('IQ Generated.')
                    disp('Loading to instrument...')

                    iqdownload(iqdata, obj.Instrument.SampleRateInHz, 'arbConfig', obj.Instrument.ArbConfig, 'channelMapping', chMap,...
                        'segmentNumber', obj.Instrument.SegmentNumber, 'marker', marker, 'segmname', obj.Instrument.SegmentName);

                    disp(['File loaded!' newline]);

                catch ex
                    disp(['Error loading file to instrument: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error loading file to instrument: ' ex.message];
                end   
            else
                isCommand = false;
            end
        end
        
        
        
        function [iqdata, marker, numRepeats, chMap] = calculatePulse(obj)
            [iqdata, marker, numRepeats, chMap] = iqpulse(...
                'sampleRate', obj.Instrument.SampleRateInHz, ...
                'PRI', obj.PulseGen.PulseDwellInSeconds,...
                'PW', obj.PulseGen.PulseWidthInSeconds,...
                'riseTime', obj.PulseGen.PulseRiseTimeInSeconds, ...
                'fallTime', obj.PulseGen.PulseFallTimeInSeconds, ...
                'pulseShape', obj.PulseGen.PulseShape,...
                'span', obj.PulseGen.PulseModulationFrequencySpan, ...
                'offset', obj.PulseGen.PulseFrequencyOffsetInHz, ...
                'amplitude', obj.PulseGen.PulseAmplitudeInDB,...
                'fmFormula', obj.PulseGen.PulseFrequencyModulationFormula,...
                'pmFormula', obj.PulseGen.PulsePhaseModulationFormula, ...
                'exactPRI', 0, ...
                'modulationType', obj.PulseGen.PulseModulationType,...
                'correction', obj.Correction.UseCorrection, ...
                'delay', obj.PulseGen.PulseDelayInSeconds, ...
                'phase', obj.PulseGen.PulsePhaseInDegrees, ...
                'continuousPhase', obj.PulseGen.PulsePhaseTransitionState, ...
                'channelMapping', obj.Instrument.ChannelMapping, ...
                'normalize', obj.PulseGen.PulseNormalize, ...
                'arbConfig', obj.Instrument.ArbConfig);
        end


        
        %% Parse GEN:PULS:COMB's (generating combined pulses and saving)
        
        function isCommand = parsePulseCombineCommands(obj, dataIn)
            % parsePulseCombineCommands    Parses pulse combine generation commands (:GEN:COMB)
            
            % <document>
            % <break>Pulse Combining Generation Commands (:GEN:PULS:COMB)</break>
            % </document>
            
            isCommand = false;

            if obj.parseToken('RESET')  % Reset the pulse array
                % <document>
                % <command>:GEN:PULS:COMB:RESET</command>
                % <type>Command only</type>
                % <description>Resets the current lists of pulses to combine</description>
                % <example>:GEN:PULS:COMB:RESET</example>
                % </document>
%                 if (obj.Server.ParseNext(1) == ' ')
%                     isCommand = true;
%                     obj.DefaultPulseCombo();
%                 else
%                     obj.setCommandOnlyError();
%                 end
%                 
                isCommand = true;
                obj.DefaultPulseCombo();
            elseif obj.parseToken('TSTART')  % Set start time in a combined pulse
                % <document>
                % <command>:GEN:PULS:COMB:TSTART <Start Time in Seconds></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse to combine's start time in seconds</description>
                % <example>:GEN:PULS:COMB:TSTART?; :GEN:PULS:COMB:TSTART 100E-6</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseStartTimeInSeconds', 'double');
            elseif obj.parseToken('AMP')  % Set base amplitude in a combined pulse
                % <document>
                % <command>:GEN:PULS:COMB:AMP <Amplitude in dBm></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse to combine's amplitude in dBm</description>
                % <example>:GEN:PULS:COMB:AMP?; :GEN:PULS:COMB:AMP -20</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseBasePulseAmplitudeInDB', 'double');
            elseif obj.parseToken('PTRAN')  % Set phase transition type
                % <document>
                % <command>:GEN:PULS:COMB:PTRAN <Phase Transition Type String></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse configuration's phase transition type/s (Coherent, Continuous, Exact, Bump)</description>
                % <example>:GEN:PULS:COMB:PTRAN?; :GEN:PULS:COMB:PTRAN Coherent</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseTransitionType', 'string'); 
            elseif obj.parseToken('PHAS')  % Set the phases
                % <document>
                % <command>:GEN:PULS:COMB:PHAS <Phase Offset in Degrees></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse to combine's phase offset in degrees</description>
                % <example>:GEN:PULS:COMB:PHAS?; :GEN:PULS:COMB:PHAS 90</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseBasePulsePhaseInDegrees', 'double');                
            elseif obj.parseToken('ADD')  % Add the current configured pulse to the array
                % <document>
                % <command>:GEN:PULS:COMB:ADD</command>
                % <type>Command only</type>
                % <description>Adds the currently configured pulse combine entry to the list of pulses to combine</description>
                % <example>:GEN:PULS:COMB:ADD</example>
                % </document>
                isCommand = true;
                obj.PulseCombineGen.MultiPulseTable = [obj.PulseCombineGen.MultiPulseTable; obj.CreatePulseStructure()];
            elseif obj.parseToken('COUNT')  % Get the length of the pulse table
                % <document>
                % <command>:GEN:PULS:COMB:COUNT</command>
                % <type>Query Only</type>
                % <description>Gets the number of pulses that will be processed</description>
                % <example>:GEN:PULS:COMB:COUNT?</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')
                    isCommand = true;
                    obj.sendResponse(num2str(length(obj.PulseCombineGen.MultiPulseTable)));
                else
                    obj.setQueryOnlyError();
                end
            elseif obj.parseToken('OFFSETAMP')  % Get the offset amplitude
                % <document>
                % <command>:GEN:PULS:COMB:OFFSETAMP</command>
                % <type>Query Only</type>
                % <description>Gets the amplitude offset of the calculated pulses (if the combined pulses constructively interfere, they may clip the DAC, so the the levels are normalized and managed with an offset)</description>
                % <example>:GEN:PULS:COMB:OFFSETAMP?</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')
                    isCommand = true;
                    obj.sendResponse(num2str(obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB));
                else
                    obj.setQueryOnlyError();
                end
            elseif obj.parseToken('OFFSETTIME')  % Get the offset time
                % <document>
                % <command>:GEN:PULS:COMB:OFFSETTIME</command>
                % <type>Query Only</type>
                % <description>Gets the time offset of the calculated pulses (to save samples, the first pulse can be offset in time to zero)</description>
                % <example>:GEN:PULS:COMB:OFFSETTIME?</example>
                % </document>
                if (obj.Server.ParseNext(1) == '?')
                    isCommand = true;
                    fprintf(obj.Server.ServerInstance, num2str(obj.PulseCombineGen.MultiPulseTimeShiftInS));
                else
                    obj.setQueryOnlyError();
                end
            elseif obj.parseToken('FSAV')
                % <document>
                % <command>:GEN:PULS:COMB:FSAV <File save path></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse combination configuration's file save path</description>
                % <example>:GEN:PULS:COMB:FSAV?; :GEN:PULS:COMB:FSAV Pulse_Combine_100_us</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseGen.PulseFilePathSave', 'string');
                
             elseif obj.parseToken('FPROC')
                % <document>
                % <command>:GEN:PULS:COMB:FPROC <File process path></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current pulse combination configuration's file process file path</description>
                % <example>:GEN:PULS:COMB:FPROC?; :GEN:PULS:COMB:FPROC Pulse_Combine_100_us</example>
                % </document>
                isCommand = true;
                obj.setget('obj.PulseCombineGen.MultiPulseProcessFile', 'string');
                
            elseif obj.parseToken('SAVE')  % Save to a file
                % <document>
                % <command>:GEN:PULS:COMB:SAVE</command>
                % <type>Command only</type>
                % <description>Calculates the I/Q Data for a pulse combination defined by its current settings, then saves to its defined path</description>
                % <example>:GEN:PULS:COMB:SAVE</example>
                % </document>
                isCommand = true;                    
                try
                    [totalSamples,...
                        obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB,...
                        obj.PulseCombineGen.MultiPulseTimeShiftInS, ~] = ...
                        multi_pdw('arbConfig', obj.Instrument.ArbConfig, ...
                            'samplerate', obj.Instrument.SampleRateInHz, ...
                            'pulsetable', obj.PulseCombineGen.MultiPulseTable, ...     
                            'correction', obj.Correction.UseCorrection, ...
                            'normalize', obj.PulseGen.PulseNormalize, ...
                            'function', 'save', ...
                            'filename', obj.PulseGen.PulseFilePathSave, ...
                            'filetype', obj.Instrument.FileSaveType, ...
                            'debugmode', obj.Server.DebugMode, ...
                            'channelMapping', obj.Instrument.ChannelMapping, ...
                            'processFile', obj.PulseCombineGen.MultiPulseProcessFile);

                if obj.Server.DebugMode
                    disp(['Total samples: ' num2str(totalSamples)]); 
                    disp(['Amplitude delta: ' num2str(obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB) ' dB']);   
                    disp(['Time delta: ' num2str(obj.PulseCombineGen.MultiPulseTimeShiftInS) ' s']);  
                end
                                        
                catch ex
                    disp(['Error saving file: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error saving file: ' ex.message];
                end 

            elseif obj.parseToken('VSA')  % Preview the single pulse in VSA
                % <document>
                % <command>:GEN:PULS:COMB:VSA</command>
                % <type>Command only</type>
                % <description>Calculates the I/Q Data for a pulse combination defined by its current settings, then loads it to 89601B VSA to preview</description>
                % <example>:GEN:PULS:COMB:VSA</example>
                % </document>
                isCommand = true;                    
                try
                    [totalSamples,...
                        obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB,...
                        obj.PulseCombineGen.MultiPulseTimeShiftInS, ~] = ...
                        multi_pdw('arbConfig', obj.Instrument.ArbConfig, ...
                            'samplerate', obj.Instrument.SampleRateInHz, ...
                            'pulsetable', obj.PulseCombineGen.MultiPulseTable, ...     
                            'correction', obj.Correction.UseCorrection, ...
                            'normalize', obj.PulseGen.PulseNormalize, ...
                            'function', 'vsa', ...
                            'debugmode', obj.Server.DebugMode, ...
                            'channelMapping', obj.Instrument.ChannelMapping, ...
                            'processFile', obj.PulseCombineGen.MultiPulseProcessFile);
                                        
                if obj.Server.DebugMode
                    disp(['Total samples: ' num2str(totalSamples)]); 
                    disp(['Amplitude delta: ' num2str(obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB) ' dB']);   
                    disp(['Time delta: ' num2str(obj.PulseCombineGen.MultiPulseTimeShiftInS) ' s']);  
                end

                catch ex
                    disp(['Error loading file to VSA: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error loading file to VSA: ' ex.message];
                end
                
            elseif obj.parseToken('DOWNLOAD')  % Download to an instrument
                % <document>
                % <command>:GEN:PULS:COMB:DOWNLOAD</command>
                % <type>Command only</type>
                % <description>Calculates the I/Q Data for a pulse combination defined by its current settings, then loads it to the defined instrument</description>
                % <example>:GEN:PULS:COMB:DOWNLOAD</example>
                % </document>
                isCommand = true;                
                try
                    [totalSamples,...
                        obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB,...
                        obj.PulseCombineGen.MultiPulseTimeShiftInS, ~] = ...
                        multi_pdw('arbConfig', obj.Instrument.ArbConfig, ...
                            'samplerate', obj.Instrument.SampleRateInHz, ...
                            'pulsetable', obj.PulseCombineGen.MultiPulseTable, ...     
                            'correction', obj.Correction.UseCorrection, ...
                            'normalize', obj.PulseGen.PulseNormalize, ...
                            'function', 'download', ...
                            'debugmode', obj.Server.DebugMode, ...
                            'channelMapping', obj.Instrument.ChannelMapping, ...
                            'processFile', obj.PulseCombineGen.MultiPulseProcessFile);
                                        
                if obj.Server.DebugMode
                    disp(['Total samples: ' num2str(totalSamples)]); 
                    disp(['Amplitude delta: ' num2str(obj.PulseCombineGen.MultiPulseAmplitudeShiftInDB) ' dB']);   
                    disp(['Time delta: ' num2str(obj.PulseCombineGen.MultiPulseTimeShiftInS) ' s']);  
                end
                
                disp(['File loaded!' newline]);

                catch ex
                    disp(['Error loading file to instrument: ' getReport(ex,'extended')]);
                    obj.Server.ErrorQueue{end + 1} = ['Error loading file to instrument: ' ex.message];
                end      
            end
        end
        
        
        %% Parse GEN:TONE (generating tones and noise)
        
        function isCommand = parseToneGenerateCommands(obj, ~)
            
            % <document>
            % <break>Multi-tone Generation Commands (:GEN:TONE)</break>
            % </document> 
            
            isCommand = true;
            if obj.parseToken('RESET')
                % <document>
                % <command>:GEN:TONE:RESET</command>
                % <type>Command only</type>
                % <description>Resets the current tone configuration to its default values</description>
                % <example>:GEN:TONE:RESET</example>
                % </document>
                obj.DefaultTone();
            elseif obj.parseToken('SRAT')
                % <document>
                % <command>:GEN:TONE:SRAT <Sample Rate in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current tone configuration's sample rate in Hz.</description>
                % <example>:GEN:TONE:SRAT?;  :GEN:TONE:SRAT 2E9</example>
                % </document> 
                obj.setget('obj.Instrument.SampleRateInHz', 'double');
            elseif obj.parseToken('SAMPLECOUNT')
                % <document>
                % <command>:GEN:TONE:SAMPLECOUNT <number of samples></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the number of samples that are used for waveform calculation. A value of zero will automatically choose the optimal number of samples</description>
                % <example>:GEN:TONE:SAMPLECOUNT?;  :GEN:TONE:SAMPLECOUNT 20480</example>
                % </document> 
                obj.setget('obj.ToneGen.SampleCount', 'int');
            elseif obj.parseToken('START')  % Set/get the start frequency
                % <document>
                % <command>:GEN:TONE:START <start frequency in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the start frequency in Hz. Can also contain a list of start frequencies to generate multiple groups of tones</description>
                % <example>:GEN:TONE:START?; :GEN:TONE:START 100E6; :GEN:TONE:START [100e6, 200e6, 500e6]</example>
                % </document> 
                obj.setget('obj.ToneGen.StartFrequency', 'double');
            elseif obj.parseToken('STOP')  % Set/get the stop frequency
                % <document>
                % <command>:GEN:TONE:STOP <stop frequency in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the stop frequency in Hz. Can also contain a list of stop frequencies to generate multiple groups of tones</description>
                % <example>:GEN:TONE:STOP?; :GEN:TONE:STOP 900E6; :GEN:TONE:STOP [150e6, 250e6, 550e6]</example>
                % </document> 
                obj.setget('obj.ToneGen.StopFrequency', 'double');
            elseif obj.parseToken('COUNT')  % Set/get the number of tones
                % <document>
                % <command>:GEN:TONE:COUNT <numer of tones></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the number of equidistant tones from start to stop frequency. Setting tone count to zero will generate a band-limited white noise signal from start to stop frequency</description>
                % <example>:GEN:TONE:COUNT?; :GEN:TONE:COUNT 9; :GEN:TONE:COUNT [6 11 21]</example>
                % </document> 
                obj.setget('obj.ToneGen.ToneCount', 'double');
            elseif obj.parseToken('SPACING')  % Get the tone spacing
                % <document>
                % <command>:GEN:TONE:SPACING?</command>
                % <type>Query only</type>
                % <description>Get the tone spacing in Hz</description>
                % <example>:GEN:TONE:SPACING?</example>
                % </document> 
%                obj.setget('obj.ToneGen.ToneSpacing', 'double');
                if (obj.Server.ParseNext(1) == '?')
                    if (obj.ToneGen.ToneCount > 1)
                        spacing = (obj.ToneGen.StopFrequency(1) - obj.ToneGen.StartFrequency(1)) / ...
                            (obj.ToneGen.ToneCount - 1);
                    else
                        spacing = 0;
                    end
                    obj.sendResponse(obj.toString(spacing));
                else
                    obj.setQueryOnlyError();
                end
            elseif obj.parseToken('NOTCHFREQ')  % Set/get the notch frequency in Hz
                % <document>
                % <command>:GEN:TONE:NOTCHFREQ <notch frequencies in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the notch frequencies in Hz</description>
                % <example>:GEN:TONE:NOTCHFREQ?; :GEN:TONE:NOTCHFREQ 100e6; :GEN:TONE:NOTCHFREQ [100e6 50e6 100e6]</example>
                % </document> 
                obj.setget('obj.ToneGen.NotchFrequency', 'double');
            elseif obj.parseToken('NOTCHSPAN')  % Set/get the notch frequency in Hz
                % <document>
                % <command>:GEN:TONE:NOTCHSPAN <notch span(s) in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the notch span(s) in Hz</description>
                % <example>:GEN:TONE:NOTCHSPAN?; :GEN:TONE:NOTCHSPAN 100e6; :GEN:TONE:NOTCHSPAN [100e6 50e6 100e6]</example>
                % </document> 
                obj.setget('obj.ToneGen.NotchSpan', 'double');
            elseif obj.parseToken('NOTCHDEPTH')  % Set/get the notch depth in dB
                % <document>
                % <command>:GEN:TONE:NOTCHDEPTH <notch depth in dB></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the notch depth in dB</description>
                % <example>:GEN:TONE:NOTCHDEPTH?; :GEN:TONE:NOTCHDEPTH 30; :GEN:TONE:NOTCHDEPTH [10 20 30]</example>
                % </document> 
                obj.setget('obj.ToneGen.NotchDepth', 'double');
            elseif obj.parseToken('MAG')  % Set the magnitudes
                % <document>
                % <command>:GEN:TONE:MAG <magnitudes in dBFS></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current tone magnitude(s) in dBFS</description>
                % <example>:GEN:TONE:MAG?; :GEN:TONE:MAG -12; :GEN:TONE:MAG [-10 -20 -30]</example>
                % </document> 
                obj.setget('obj.ToneGen.ToneMagnitude', 'double');
            elseif obj.parseToken('PHASE')  % Set the tone phase(s)
                % <document>
                % <command>:GEN:TONE:PHASE <list of phase values in degrees or 'Random'></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current phase(s) in degrees</description>
                % <example>:GEN:TONE:PHASE?; :GEN:TONE:PHASE 'Random'; :GEN:TONE:PHASE [0 90 180 270]</example>
                % </document> 
                obj.setget('obj.ToneGen.TonePhase', 'any');
            elseif obj.parseToken('NORM')  % Set the magnitudes
                % <document>
                % <command>:GEN:TONE:NORM <1|0></command>
                % <type>Command and Query</type>
                % <description>When set to 1 (=default value), waveforms are scaled to use the full DAC range. When set to 0, scaling to full DAC range is only performed if the DAC range is exceeded.</description>
                % <example>:GEN:TONE:MAG?; :GEN:TONE:NORM 0</example>
                % </document> 
                obj.setget('obj.ToneGen.ToneNormalize', 'double');
            elseif obj.parseToken('DBFS')
                % <document>
                % <command>:GEN:TONE:DBFS?</command>
                % <type>Query only</type>
                % <description>Use this command to query the peak value of the waveform in dBFS. Note: this query is only valid after a :GEN:TONE:DOWNLOAD command</description>
                % <example>:GEN:TONE:DBFS?</example>
                % </document> 
                if (obj.Server.ParseNext(1) == '?')                
                    obj.setget('obj.ToneGen.dBFS', 'double');
                else
                    obj.setQueryOnlyError();
                end
            elseif obj.parseToken('DOWNLOAD')  % Set the frequencies
                % <document>
                % <command>:GEN:TONE:DOWNLOAD</command>
                % <type>Command only</type>
                % <description>Calculates the I/Q data for a multi-tone signal defined by its current settings, then loads it to the defined instrument</description>
                % <example>:GEN:TONE:DOWNLOAD</example>
                % </document> 
                try
                    if (obj.ToneGen.ToneCount == 0)
                        arbConfig = loadArbConfig(obj.Instrument.ArbConfig);
                        numSamples = obj.ToneGen.SampleCount;
                        if (numSamples == 0)
                            numSamples = min(10000000, arbConfig.maximumSegmentSize);
                        end
                        numSamples = floor(numSamples / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
                        [iqdata, chMap] = iqnoise('sampleRate', obj.Instrument.SampleRateInHz, 'arbConfig', obj.Instrument.ArbConfig, 'numSamples', numSamples, ...
                            'start', obj.ToneGen.StartFrequency, 'stop', obj.ToneGen.StopFrequency, 'notchFreq', obj.ToneGen.NotchFrequency, ...
                            'notchSpan', obj.ToneGen.NotchSpan, 'notchDepth', obj.ToneGen.NotchDepth, 'correction', obj.Correction.UseCorrection, ...
                            'channelMapping', obj.Instrument.ChannelMapping);
                        iqdownload(iqdata, obj.Instrument.SampleRateInHz, 'arbConfig', obj.Instrument.ArbConfig, 'channelMapping', chMap,...
                            'segmentNumber', obj.Instrument.SegmentNumber, 'segmname', obj.Instrument.SegmentName);
                    else
                        [tone, mag] = obj.calc_tones();
                        [iqdata, ~, ~, ~, chMap] = iqtone('sampleRate', obj.Instrument.SampleRateInHz, 'arbConfig', obj.Instrument.ArbConfig, 'tone', tone, ...
                            'Magnitude', mag, 'Phase', obj.ToneGen.TonePhase, 'normalize', obj.ToneGen.ToneNormalize, ...
                            'Correction', obj.Correction.UseCorrection, 'channelMapping', obj.Instrument.ChannelMapping);
                        iqdownload(iqdata, obj.Instrument.SampleRateInHz, 'arbConfig', obj.Instrument.ArbConfig, 'channelMapping', chMap,...
                            'segmentNumber', obj.Instrument.SegmentNumber, 'segmname', obj.Instrument.SegmentName);
                        
                        % calculate dbFS, but only consider those parts that are in channelMapping
                        scale = 1e-50;
                        chx = sum(chMap, 1);
                        for i = 1:length(chx)/2
                            if (chx(2*i-1))
                                scale = max(scale, max(abs(real(iqdata(:,i)))));
                            end
                            if (chx(2*i))
                                scale = max(scale, max(abs(imag(iqdata(:,i)))));
                            end
                        end
                        scaledB = 20*log10(scale);
                        obj.ToneGen.dBFS = scaledB;
                    end
                catch ex
                    obj.setError(ex.message);
                end
            else
                obj.setCommandError();
            end
        end
        
        
        % calculate a vector of tone frequencies and magnitudes
        % based on start/stop/count/notch
        function [tone, mag] = calc_tones(obj)
            numTones = obj.ToneGen.ToneCount;
            if (numTones == 1)
                tone = obj.ToneGen.StopFrequency;    % can be a single number or a vector!
                numTones = length(tone);
            elseif (numTones > 1)
                tone = [];
                for i = 1:min(length(obj.ToneGen.StartFrequency), length(obj.ToneGen.StopFrequency))
                    tone = [tone linspace(obj.ToneGen.StartFrequency(i), obj.ToneGen.StopFrequency(i), numTones)'];
                end
                tone = tone(1:end)';
                numTones = length(tone);
            end
            mag = zeros(numTones, 1);
            notchFreq = obj.ToneGen.NotchFrequency;
            notchSpan = obj.ToneGen.NotchSpan;
            notchDepth = obj.ToneGen.NotchDepth;
            if (size(notchSpan, 2) > 1)
                notchSpan = notchSpan.';
            end
            if (isempty(notchSpan))
                notchSpan = 0;
            end
            if (length(notchSpan) < length(notchFreq))
                notchSpan = repmat(notchSpan, ceil(length(notchFreq) / length(notchSpan)), 1);
            end
            if (size(notchDepth, 2) > 1)
                notchDepth = notchDepth.';
            end
            if (isempty(notchDepth))
                notchDepth = -3000 * ones(length(notchFreq), 1);
            end
            if (length(notchDepth) < length(notchFreq))
                notchDepth = repmat(notchDepth, ceil(length(notchFreq) / length(notchDepth)), 1);
            end
            for i=1:length(notchFreq)
                idx = (tone >= notchFreq(i) - notchSpan(i)/2 & tone <= notchFreq(i) + notchSpan(i)/2);
                mag(idx) = mag(idx) + notchDepth(i);
            end
            mag0 = obj.ToneGen.ToneMagnitude;
            mag0 = obj.fixlength(mag0, numTones)';
            mag = mag + mag0;
        end
        
        
        
        %% Serial Data Signals
        
        function DefaultSerial(obj)
            obj.SerialGen.DataRate = 250e6;                   % data rate in Baud
            obj.SerialGen.SampleRate = 0;                     % sample rate in Hz (0 = automatic)
            obj.SerialGen.SymbolCount = 128;                  % number of symbols
            obj.SerialGen.Data = 'Random';                    % type of data ('Random', 'PRBS2^7-1', etc.)
            obj.SerialGen.Format = 'NRZ';                     % data format ('NRZ' or 'PAM4')
            obj.SerialGen.Levels = [0 1/3 1 2/3];             % relative voltage levels in the range 0...1
            obj.SerialGen.SJFrequency = 20e6;                 % SJ frequency in Hz
            obj.SerialGen.SJpp = 0;                           % SJ peak-peak amplitude
            obj.SerialGen.RJpp = 0;                           % (bounded) RJ peak-peak amplitude
            obj.SerialGen.NoiseFrequency = 0;                 % Level Noise Frequency (0 = random)
            obj.SerialGen.NoiseAmplitude = 0;                 % Level Noise Amplitude relative to data amplitude
            obj.SerialGen.Isi = 0;                            % Amount of ISI (0...1)
            obj.SerialGen.PreCursor = [];                     % PreCursors (linear)
            obj.SerialGen.PostCursor = [1];                   % PostCursors (linear)
            obj.SerialGen.TransitionTime = 0.3;               % Transition Time in UI
            obj.SerialGen.FilterType = 'Transition Time';     % calculate waveform based on 'Transition Time', 'Raised Cosine'
            obj.SerialGen.FilterNSym = 40;                    % length of pulse shape filter in symbols
            obj.SerialGen.FilterBeta = 1;                     % roll-off of pulse shape filter (0...1]
            obj.SerialGen.JitterShape = 'Sine';               % Jitter shape ('Sine', 'Triangle')
            obj.SerialGen.SSCFrequency = 33e3;                % SSC Frequency in Hz
            obj.SerialGen.SSCDepth = 0;                       % SSC Depth
            obj.SerialGen.SymbolShift = 0;                    % number of symbols to rotate PRBS
            obj.SerialGen.Amplitude = 1;                      % Amplitude relative to full scale
            obj.SerialGen.DutyCycle = 0.5;                    % Duty Cycle in UI
            obj.SerialGen.UseM8196ARefClk = 0;                % 1=use RefClk Out on M8196A to generate clock signal
            obj.SerialGen.prbspolyuser = '';                  % PRBS polynomial 
        end
        
        function isCommand = parseSerialGenerateCommands(obj, ~)
            
            % <document>
            % <break>Serial Data Generation Commands (:GEN:SERIAL)</break>
            % </document> 
            
            isCommand = true;
            if obj.parseToken('RESET')
                % <document>
                % <command>:GEN:SERIAL:RESET</command>
                % <type>Command only</type>
                % <description>Resets the current serial configuration to its default values</description>
                % <example>:GEN:SERIAL:RESET</example>
                % </document>
                obj.DefaultSerial();
            elseif obj.parseToken('SRAT') || obj.parseToken('SAMPLERATE')
                % <document>
                % <command>:GEN:SERIAL:SRAT <Sample Rate in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current serial configuration's sample rate in Hz. Set to zero for automatic sample rate selection.</description>
                % <example>:GEN:SERIAL:SRAT?   :GEN:SERIAL:SRAT 2E9     :GEN:SERIAL:SRAT 0</example>
                % </document> 
                obj.setget('obj.SerialGen.SampleRate', 'double');
            elseif obj.parseToken('DRAT') || obj.parseToken('DATARATE')
                % <document>
                % <command>:GEN:SERIAL:DRAT <baudrate></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the baudrate in symbols per second</description>
                % <example>:GEN:SERIAL:DRAT?   :GEN:SERIAL:DRAT 1e9</example>
                % </document> 
                obj.setget('obj.SerialGen.DataRate', 'double');
            elseif obj.parseToken('SYMBOLCOUNT')
                % <document>
                % <command>:GEN:SERIAL:SYMBOLCOUNT <number of symbols></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the number of symbols</description>
                % <example>:GEN:SERIAL:SYMBOLCOUNT?   :GEN:SERIAL:SYMBOLCOUNT 1024</example>
                % </document> 
                obj.setget('obj.SerialGen.SymbolCount', 'double');
            elseif obj.parseToken('DATA') 
                % <document>
                % <command>:GEN:SERIAL:DATA <type of data></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the type of data to be generated. Valid selections are 'Random', 'PAMx', 'PRBS2^x-1'. Alternatively, a vector of symbols can be specified</description>
                % <example>:GEN:SERIAL:DATA 'PRBS2^11-1'   :GEN:SERIAL:DATA [1 0 1 0 1 0 0 1 0 1 1]</example>
                % </document> 
                obj.setget('obj.SerialGen.Data', 'string');
            elseif obj.parseToken('FORMAT')
                % <document>
                % <command>:GEN:SERIAL:FORMAT <data format></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the data format: 'NRZ' or 'PAM4'</description>
                % <example>:GEN:SERIAL:FORMAT?   :GEN:SERIAL:FORMAT 'PAM4'</example>
                % </document> 
                obj.setget('obj.SerialGen.Format', 'string');
            elseif obj.parseToken('LEVELS') 
                % <document>
                % <command>:GEN:SERIAL:LEVELS <relative voltage levels></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the relative voltage levels for multi-level signals. Must be a vector with values in the range [0...1]. The order indicates the mapping between symbol values and voltage levels</description>
                % <example>:GEN:SERIAL:LEVELS?   :GEN:SERIAL:LEVELS [0 1/3 1 2/3]</example>
                % </document> 
                obj.setget('obj.SerialGen.Levels', 'double');
            elseif obj.parseToken('SJSHAPE')
                % <document>
                % <command>:GEN:SERIAL:SJSHAPE <SJ shape></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the sinusoidal jitter shape. Valid values are 'Sine', 'Square','Triangle','Ramp','Noise'</description>
                % <example>:GEN:SERIAL:SJSHAPE?  :GEN:SERIAL:SJSHAPE 'Sine'</example>
                % </document> 
                obj.setget('obj.SerialGen.SJShape', 'string');
            elseif obj.parseToken('SJFREQUENCY')
                % <document>
                % <command>:GEN:SERIAL:SJFREQUENCY <SJ frequency in Hz></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the sinusoidal jitter frequency in Hz</description>
                % <example>:GEN:SERIAL:SJFREQUENCY?  :GEN:SERIAL:SJFREQUENCY 20e6</example>
                % </document> 
                obj.setget('obj.SerialGen.SJFrequency', 'double');
            elseif obj.parseToken('SJPP')
                % <document>
                % <command>:GEN:SERIAL:SJPP <SJ peak-peak amplitude in UI></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the sinusoidal jitter amplitude in UI</description>
                % <example>:GEN:SERIAL:SJPP?  :GEN:SERIAL:SJPP 0.2</example>
                % </document> 
                obj.setget('obj.SerialGen.SJpp', 'double');
            elseif obj.parseToken('RJPP')
                % <document>
                % <command>:GEN:SERIAL:RJPP <RJ peak-peak amplitude in UI></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the peak-peak random jitter amplitude in UI. Note: this jitter is bounded and not true RJ</description>
                % <example>:GEN:SERIAL:RJPP?  :GEN:SERIAL:RJPP 0.2</example>
                % </document> 
                obj.setget('obj.SerialGen.RJpp', 'double');
            elseif obj.parseToken('NOISEFREQUENCY')
                % <document>
                % <command>:GEN:SERIAL:NOISEFREQUENCY <level noise frequency></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the frequency of level noise in Hz. A value of zero generates random level noise</description>
                % <example>:GEN:SERIAL:NOISEFREQUENCY?  :GEN:SERIAL:NOISEFREQUENCY 10e6</example>
                % </document> 
                obj.setget('obj.SerialGen.NoiseFrequency', 'double');
            elseif obj.parseToken('NOISEAMPLITUDE')
                % <document>
                % <command>:GEN:SERIAL:NOISEAMPLITUDE <level noise amplitude></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the amplitude of level noise relative to the data amplitude</description>
                % <example>:GEN:SERIAL:NOISEAMPLITUDE?  :GEN:SERIAL:NOISEAMPLITUDE 0.2</example>
                % </document> 
                obj.setget('obj.SerialGen.NoiseAmplitude', 'double');
            elseif obj.parseToken('ISI')
                % <document>
                % <command>:GEN:SERIAL:ISI <amount of ISI></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the of ISI. Value must be greater or equal to 0 and less than 1</description>
                % <example>:GEN:SERIAL:ISI?  :GEN:SERIAL:ISI 0.8</example>
                % </document> 
                obj.setget('obj.SerialGen.Isi', 'double');
            elseif obj.parseToken('PRECURSOR')
                % <document>
                % <command>:GEN:SERIAL:PRECURSOR <list of precursors></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the precursors in linear units. An empty list means no precursor</description>
                % <example>:GEN:SERIAL:PRECURSOR?  :GEN:SERIAL:PRECURSOR [0.1 -0.2]</example>
                % </document> 
                obj.setget('obj.SerialGen.PreCursor', 'double');
            elseif obj.parseToken('POSTCURSOR')
                % <document>
                % <command>:GEN:SERIAL:PRECURSOR <list of precursors></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the main cursor and postcursors in linear units. Set to [1] for just the main cursor</description>
                % <example>:GEN:SERIAL:POSTCURSOR?  :GEN:SERIAL:POSTCURSOR [1 0.1 -0.2]</example>
                % </document> 
                obj.setget('obj.SerialGen.PostCursor', 'double');
            elseif obj.parseToken('TTIME') || obj.parseToken('TRANSITIONTIME')
                % <document>
                % <command>:GEN:SERIAL:TTIME <transition time in UI></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the transition time relative to one UI. Must be in the range [0...1]. Note, this is the 0/100 transition time</description>
                % <example>:GEN:SERIAL:TTIME?  :GEN:SERIAL:TTIME 0.3</example>
                % </document> 
                obj.setget('obj.SerialGen.TransitionTime', 'double');
            elseif obj.parseToken('FTYPE') || obj.parseToken('FILTERTYPE')
                % <document>
                % <command>:GEN:SERIAL:FTPYE <filter type></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the filter type: 'Transition Time' or 'Raised Cosine'</description>
                % <example>:GEN:SERIAL:FTYPE?  :GEN:SERIAL:FTYPE 'Transition Time'   :GEN:SERIAL:FTYPE 'Raised Cosine'</example>
                % </document> 
                obj.setget('obj.SerialGen.FilterType', 'string');
            elseif obj.parseToken('FNSYM') || obj.parseToken('FILTERNSYM')
                % <document>
                % <command>:GEN:SERIAL:FNSYM <filter length in symbols></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the filter length in symbols. Only applies to filter type 'Raised Cosine'</description>
                % <example>:GEN:SERIAL:FNSYM?  :GEN:SERIAL:FNSYM 40</example>
                % </document> 
                obj.setget('obj.SerialGen.FilterNSym', 'int');
            elseif obj.parseToken('FBETA') || obj.parseToken('FILTERBETA')
                % <document>
                % <command>:GEN:SERIAL:FBETA <filter roll-off factor></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the filter roll-off factor between 0 and 1. Only applies to filter type 'Raised Cosine'</description>
                % <example>:GEN:SERIAL:FBETA?  :GEN:SERIAL:FBETA 0.5</example>
                % </document> 
                obj.setget('obj.SerialGen.FilterBeta', 'double');
            elseif obj.parseToken('SSCFREQUENCY')
                % <document>
                % <command>:GEN:SERIAL:SSCFREQUENCY <SSC frequency></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the SSC frequency</description>
                % <example>:GEN:SERIAL:SSCFREQUENCY?  :GEN:SERIAL:SSCFREQUENCY 33e3</example>
                % </document> 
                obj.setget('obj.SerialGen.SSCFrequency', 'double');
            elseif obj.parseToken('SSCDEPTH')
                % <document>
                % <command>:GEN:SERIAL:SSCDEPTH <SSC depth></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the SSC depth</description>
                % <example>:GEN:SERIAL:SSCDEPTH?  :GEN:SERIAL:SSCDEPTH 33e3</example>
                % </document> 
                obj.setget('obj.SerialGen.SSCDepth', 'double');
            elseif obj.parseToken('SYMBOLSHIFT')
                % <document>
                % <command>:GEN:SERIAL:SYMBOLSHIFT <symbol shift></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the number of symbols by which a PRBS signal is rotated. This allows different channels to have the sample PRBS polynomial, but still a different waveform</description>
                % <example>:GEN:SERIAL:SYMBOLSHIFT?  :GEN:SERIAL:SYMBOLSHIFT 15</example>
                % </document> 
                obj.setget('obj.SerialGen.SymbolShift', 'int');
            elseif obj.parseToken('AMPLITUDE')
                % <document>
                % <command>:GEN:SERIAL:AMPLITUDE <SSC depth></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the amplitude of the waveform relative to full scale of the DAC. Values must be in the range 0...1</description>
                % <example>:GEN:SERIAL:AMPLITUDE?  :GEN:SERIAL:AMPLITUDE 0.5</example>
                % </document> 
                obj.setget('obj.SerialGen.Amplitude', 'double');
            elseif obj.parseToken('DUTYCYCLE')
                % <document>
                % <command>:GEN:SERIAL:DUTYCYCLE <duty cycle></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the duty cycle of the signal. Valid values are between 0 and 1</description>
                % <example>:GEN:SERIAL:DUTYCYCLE?  :GEN:SERIAL:DUTYCYCLE 0.5</example>
                % </document> 
                obj.setget('obj.SerialGen.DutyCycle', 'double');
            elseif obj.parseToken('PRBSPOLY')
                % <document>
                % <command>:GEN:SERIAL:PRBSPOLY <PRBS polynomial></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the PRBS polynomial. If not provided, iqtools is using the default ones</description>
                % <example>:GEN:SERIAL:PRBSPOLY?  :GEN:SERIAL:PRBSPOLY '[15 1 0]'</example>
                % </document> 
                obj.setget('obj.SerialGen.prbspolyuser', 'string');
            elseif obj.parseToken('DOWNLOAD') 
                % <document>
                % <command>:GEN:SERIAL:DOWNLOAD</command>
                % <type>Command only</type>
                % <description>Calculates the serial data waveform defined by its current settings, then loads it to the AWG</description>
                % <example>:GEN:SERIAL:DOWNLOAD</example>
                % </document> 
                try
                    if isempty(obj.SerialGen.prbspolyuser)
                        [s, fs, nSym, nSamples, chMap] = iserial('dataRate', obj.SerialGen.DataRate, 'sampleRate', obj.SerialGen.SampleRate, ...
                            'numBits', obj.SerialGen.SymbolCount, 'data', obj.SerialGen.Data, 'format', obj.SerialGen.Format, 'function', 'download', ...
                            'levels', obj.SerialGen.Levels, 'SJfreq', obj.SerialGen.SJFrequency, 'SJpp', obj.SerialGen.SJpp, 'RJpp', obj.SerialGen.RJpp, ...
                            'noiseFreq', obj.SerialGen.NoiseFrequency, 'noise', obj.SerialGen.NoiseAmplitude, 'isi', obj.SerialGen.Isi, ...
                            'preCursor', obj.SerialGen.PreCursor, 'postCursor', obj.SerialGen.PostCursor, 'transitionTime', obj.SerialGen.TransitionTime, ...
                            'filterType', obj.SerialGen.FilterType, 'filterNsym', obj.SerialGen.FilterNSym, 'filterBeta', obj.SerialGen.FilterBeta, ...
                            'jitterShape', obj.SerialGen.JitterShape, 'sscFreq', obj.SerialGen.SSCFrequency, 'sscDepth', obj.SerialGen.SSCDepth, ...
                            'symbolShift', obj.SerialGen.SymbolShift, 'amplitude', obj.SerialGen.Amplitude, 'dutyCycle', obj.SerialGen.DutyCycle, ...
                            'correction', obj.Correction.UseCorrection, 'channelMapping', obj.Instrument.ChannelMapping, ...
                            'useM8196RefClk', obj.SerialGen.UseM8196ARefClk, 'arbConfig', obj.Instrument.ArbConfig);
                    else
                        prbsPoly = str2double(regexp(obj.SerialGen.prbspolyuser, '(?<!\d)(\d)+(?!\d)','match'));
                        [s, fs, nSym, nSamples, chMap] = iserial('dataRate', obj.SerialGen.DataRate, 'sampleRate', obj.SerialGen.SampleRate, ...
                            'numBits', obj.SerialGen.SymbolCount, 'data', obj.SerialGen.Data, 'format', obj.SerialGen.Format, 'function', 'download', ...
                            'levels', obj.SerialGen.Levels, 'SJfreq', obj.SerialGen.SJFrequency, 'SJpp', obj.SerialGen.SJpp, 'RJpp', obj.SerialGen.RJpp, ...
                            'noiseFreq', obj.SerialGen.NoiseFrequency, 'noise', obj.SerialGen.NoiseAmplitude, 'isi', obj.SerialGen.Isi, ...
                            'preCursor', obj.SerialGen.PreCursor, 'postCursor', obj.SerialGen.PostCursor, 'transitionTime', obj.SerialGen.TransitionTime, ...
                            'filterType', obj.SerialGen.FilterType, 'filterNsym', obj.SerialGen.FilterNSym, 'filterBeta', obj.SerialGen.FilterBeta, ...
                            'jitterShape', obj.SerialGen.JitterShape, 'sscFreq', obj.SerialGen.SSCFrequency, 'sscDepth', obj.SerialGen.SSCDepth, ...
                            'symbolShift', obj.SerialGen.SymbolShift, 'amplitude', obj.SerialGen.Amplitude, 'dutyCycle', obj.SerialGen.DutyCycle, ...
                            'correction', obj.Correction.UseCorrection, 'channelMapping', obj.Instrument.ChannelMapping, ...
                            'useM8196RefClk', obj.SerialGen.UseM8196ARefClk, 'arbConfig', obj.Instrument.ArbConfig, 'prbspolyuser', prbsPoly );
                    end
                    iqdownload(s, fs, 'arbConfig', obj.Instrument.ArbConfig, 'channelMapping', chMap,...
                        'segmentNumber', obj.Instrument.SegmentNumber, 'segmname', obj.Instrument.SegmentName);
                catch ex
                    obj.setError(ex.message);
                end
            else
                obj.setCommandError();
            end
        end
        
        %% Serial Data Signals
        
        function DefaultMTCal(obj)
            obj.MTCal.ScopeType = 'DCA';        % scope type ('DCA' or 'Realtime')
            obj.MTCal.AWGChannels = {'1'};      % list of AWG channels
            obj.MTCal.ScopeChannels = {'1A'};   % list of scope channels
            obj.MTCal.AWGTrigger = {'Marker'};  % AWG Trigger Channel
            obj.MTCal.ScopeTrigger = {'PTB+FP'};% Scope Trigger
            obj.MTCal.SampleRate = 0;           % sample rate in Hz (0 = use default)
            obj.MTCal.MaxTone = 70e9;           % max. tone frequency
            obj.MTCal.ToneCount = 300;          % number of tones
            obj.MTCal.ScopeAverage = 4;         % scope averages
            obj.MTCal.AnalysisAverage = 4;      % analysis averages
            obj.MTCal.ScopeAmplitude = 800e-3;  % Scope Ampltiude
            obj.MTCal.AutoScopeAmplitude = 1;   % Automatic Scope Amplitude
            obj.MTCal.ScopeBandwidth = 'MAX';   % scope bandwidth
            obj.MTCal.SIRC = 1;                 % SIRC 
            obj.MTCal.ChToChSkew = 0;           % include channel-to-channel skew
            obj.MTCal.AWGReset = 0;             % AWG Reset
            obj.MTCal.ScopeReset = 0;           % Scope Reset
            obj.MTCal.BuildUponPreviousCal = 0; % Build upon previous calibration
            obj.MTCal.UseSeparateTonesPerChannel = 0; % use separate tones per AWG channel
        end
        
        function isCommand = parseMTCalCommands(obj, ~)
            
            % <document>
            % <break>Multi-tone Calibration Commands (:MTCAL:...)</break>
            % </document> 
            
            isCommand = true;
            if obj.parseToken('RESET')
                % <document>
                % <command>:MTCAL:RESET</command>
                % <type>Command only</type>
                % <description>Resets the multi-tone calibration parameters to their default values</description>
                % <example>:MTCAL:RESET</example>
                % </document>
                obj.DefaultMTCal();
            elseif obj.parseToken('STYP')
                % <document>
                % <command>:MTCAL:STYP ["DCA" | "RTScope"]</command>
                % <type>Command and Query</type>
                % <description>Gets or sets the current type of oscilloscope.</description>
                % <example>:MTCAL:STYP 'DCA'</example>
                % </document> 
                obj.setget('obj.MTCal.ScopeType', 'any');
            elseif obj.parseToken('ACHAN')
                % <document>
                % <command>:MTCAL:ACHAN <list of channels></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the list of AWG channels</description>
                % <example>:MTCAL:ACHAN?   :MTCAL:ACHAN '1','2'</example>
                % </document> 
                obj.setget('obj.MTCal.AWGChannels', 'cell');
            elseif obj.parseToken('SCHAN')
                % <document>
                % <command>:MTCAL:SCHAN <list of channels></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the list of scope channels. Must in the same order as AWG channels</description>
                % <example>:MTCAL:SCHAN?   :MTCAL:SCHAN '1A','2A'</example>
                % </document> 
                obj.setget('obj.MTCal.ScopeChannels', 'cell');
            elseif obj.parseToken('ATRIG')
                % <document>
                % <command>:MTCAL:ATRIG <channel></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the AWG channels used for triggering the scope. Can be a channel number or 'Marker' or 'unused'</description>
                % <example>:MTCAL:ATRIG?   :MTCAL:ATRIG 'Marker'</example>
                % </document> 
                obj.setget('obj.MTCal.AWGTrigger', 'any');
            elseif obj.parseToken('STRIG')
                % <document>
                % <command>:MTCAL:STRIG <channel></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the Scope Trigger. In case of realtime scope, can be '1', '2', ... or 'unused'. In case of DCA, can be 'PTB+FP'</description>
                % <example>:MTCAL:STRIG?   :MTCAL:STRIG 'PTB+FP'</example>
                % </document> 
                obj.setget('obj.MTCal.ScopeTrigger', 'any');
            elseif obj.parseToken('SRAT') 
                % <document>
                % <command>:MTCAL:SRAT <sample rate></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the sample rate of the AWG</description>
                % <example>:MTCAL:SRAT?   :MTCAL:SRAT 256e9</example>
                % </document> 
                obj.setget('obj.MTCal.SampleRate', 'double');
            elseif obj.parseToken('FMAX')
                % <document>
                % <command>:MTCAL:FMAX <frequency></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the maximum tone frequency for frequency response calibration'</description>
                % <example>:MTCAL:FMAX?  :MTCAL:FMAX 70e9</example>
                % </document> 
                obj.setget('obj.MTCal.MaxTone', 'any');
            elseif obj.parseToken('TCOUNT')
                % <document>
                % <command>:MTCAL:TCOUNT <number of tones></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the number of tones used for multi-tone calibration</description>
                % <example>:MTCAL:TCOUNT?  :MTCAL:TCOUNT 20e6</example>
                % </document> 
                obj.setget('obj.MTCal.ToneCount', 'double');
            elseif obj.parseToken('SAVG')
                % <document>
                % <command>:MTCAL:SAVG <number of averages></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the number of averages in the scope acquisition. Set to 1 for no averaging</description>
                % <example>:MTCAL:SAVG?  :MTCAL:SAVG 4</example>
                % </document> 
                obj.setget('obj.MTCal.ScopeAverage', 'double');
            elseif obj.parseToken('AAVG')
                % <document>
                % <command>:MTCAL:AAVG <integer></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the number of analysis averages during frequency response calibration</description>
                % <example>:MTCAL:AAVG?  :MTCAL:AAVG 4</example>
                % </document> 
                obj.setget('obj.MTCal.AnalysisAverage', 'double');
            elseif obj.parseToken('SAMPL')
                % <document>
                % <command>:MTCAL:SAMPL <amplitude></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the full-scale amplitude of the scope during frequency reponse calibration. Used only of AUTOAMPL is 0.</description>
                % <example>:MTCAL:SAMPL?  :MTCAL:SAMPL 10e6</example>
                % </document> 
                obj.setget('obj.MTCal.ScopeAmplitude', 'double');
            elseif obj.parseToken('AUTOAMPL')
                % <document>
                % <command>:MTCAL:AUTOAMPL <1|0></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the automatic amplitude setting.  If set to 1, scope will perform a vertical autoscale</description>
                % <example>:MTCAL:AUTOAMPL?  :MTCAL:AUTOAMPL 1</example>
                % </document> 
                obj.setget('obj.MTCal.AutoScopeAmplitude', 'double');
            elseif obj.parseToken('BW')
                % <document>
                % <command>:MTCAL:BW <bandwidth></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the bandwidth of the oscilloscope during frequency response calibration</description>
                % <example>:MTCAL:BW?  :MTCAL:BW 100e9</example>
                % </document> 
                obj.setget('obj.MTCal.ScopeBandwidth', 'double');
            elseif obj.parseToken('SIRC')
                % <document>
                % <command>:MTCAL:SIRC <1|0></command>
                % <type>Command and Query</type>
                % <description>Gets or sets the SIRC status of the DCA during frequency response calibration</description>
                % <example>:MTCAL:SIRC?  :MTCAL:SIRC 1</example>
                % </document> 
                obj.setget('obj.MTCal.SIRC', 'double');
            elseif obj.parseToken('CCSKEW')
                % <document>
                % <command>:MTCAL:CCSKEW <1|0></command>
                % <type>Command and Query</type>
                % <description>Gets or sets whether channel skew will be included in phase measurement</description>
                % <example>:MTCAL:CCSKEW?  :MTCAL:CCSKEW 1</example>
                % </document> 
                obj.setget('obj.MTCal.ChToChSkew', 'double');
            elseif obj.parseToken('ARST')
                % <document>
                % <command>:MTCAL:ARST <1|0></command>
                % <type>Command and Query</type>
                % <description>Gets or sets whether the AWG will be reset before making a frequency response measurement</description>
                % <example>:MTCAL:ARST?  :MTCAL:ARST 1</example>
                % </document> 
                obj.setget('obj.MTCal.AWGReset', 'double');
            elseif obj.parseToken('SRST')
                % <document>
                % <command>:MTCAL:SRST <1|0></command>
                % <type>Command and Query</type>
                % <description>Gets or sets whether the scope will be reset before making a skew calibration or frequency response measurement</description>
                % <example>:MTCAL:SRST?  :MTCAL:SRST 0</example>
                % </document> 
                obj.setget('obj.MTCal.ScopeReset', 'double');
            elseif obj.parseToken('UPREV')
                % <document>
                % <command>:MTCAL:UPREV <1|0></command>
                % <type>Command and Query</type>
                % <description>Gets or sets whether the previous frequency response calibration information will be used as a basis</description>
                % <example>:MTCAL:UPREV?  :MTCAL:UPREV 1</example>
                % </document> 
                obj.setget('obj.MTCal.BuildUponPreviousCal', 'int');
            elseif obj.parseToken('SEP')
                % <document>
                % <command>:MTCAL:SEP <1|0></command>
                % <type>Command and Query</type>
                % <description>Gets or sets whether separate tones will be used per AWG channel for the frequency response calibration</description>
                % <example>:MTCAL:SEP?  :MTCAL:SEP 0</example>
                % </document> 
                obj.setget('obj.MTCal.UseSeparateTonesPerChannel', 'double');
            elseif obj.parseToken('SKEWCAL') 
                % <document>
                % <command>:MTCAL:SKEWCAL</command>
                % <type>Command only</type>
                % <description>Executes a skew calibration based on the parameters set under :MTCAL</description>
                % <example>:MTCAL:SKEWCAL</example>
                % </document> 
                obj.runSkewAmplCal('skew');
            elseif obj.parseToken('SKEWRES') 
                % <document>
                % <command>:MTCAL:SKEWRES? [channel_index]</command>
                % <type>Query only</type>
                % <description>Returns the RMS values of the last SKEWCAL command. Channel_index is used to get the result for the Nth channel in the channel list. The return value consists of a list of value pairs for the selected channel: skew1, rms1, skew2, rms2,... and so on. Skew is in ps, rms Voltage in Volt</description>
                % <example>:MTCAL:SKEWRES? 2</example>
                % </document> 
                obj.returnRmsData('skew', 'rms');
            elseif obj.parseToken('AMPLITUDECAL') 
                % <document>
                % <command>:MTCAL:AMPLITUDECAL</command>
                % <type>Command only</type>
                % <description>Executes an amplitude calibration based on the parameters set under :MTCAL</description>
                % <example>:MTCAL:AMPLITUDECAL</example>
                % </document> 
                obj.runSkewAmplCal('amplitude');
            elseif obj.parseToken('AMPLITUDERES') 
                % <document>
                % <command>:MTCAL:AMPLITUDERES? [channel_index]</command>
                % <type>Query only</type>
                % <description>Returns the RMS values of the last AMPLITUDECAL command. Channel_index is used to get the result for the Nth channel in the channel list. The return value consists of a list of value pairs for the selected channel: ampl1, rms1, ampl2, rms2,... and so on. Amplitude ratios are in dB, rms Voltage in Volt</description>
                % <example>:MTCAL:AMPLTIUDERES? 2</example>
                % </document> 
                obj.returnRmsData('amplitude', 'rmsAmpl');
            elseif obj.parseToken('FREQCAL') 
                % <document>
                % <command>:MTCAL:FREQCAL</command>
                % <type>Command only</type>
                % <description>Executes a frequency response calibration based on the parameters set under :MTCAL</description>
                % <example>:MTCAL:FREQCAL</example>
                % </document> 
                try
                    result = [];
                    arbConfig = loadArbConfig(obj.Instrument.ArbConfig);
                    if (obj.MTCal.SampleRate <= 0)
                        sampleRate = arbConfig.defaultSampleRate;
                    else
                        sampleRate = obj.MTCal.SampleRate;
                    end
                    aChan = obj.MTCal.AWGChannels;
                    while (length(aChan) < 4)
                        aChan{end+1} = 'unused';
                    end
                    aChan{5} = obj.MTCal.AWGTrigger;
                    sChan = obj.MTCal.ScopeChannels;
                    while (length(sChan) < 4)
                        sChan{end+1} = 'unused';
                    end
                    sChan{5} = obj.MTCal.ScopeTrigger;
                    result = iqmtcal('scope', obj.MTCal.ScopeType, 'sim', 0, 'scopeAvg', obj.MTCal.ScopeAverage, ...
                            'numTones', obj.MTCal.ToneCount, 'scopeRST', obj.MTCal.ScopeReset, 'AWGRST', obj.MTCal.AWGReset, ...
                            'sampleRate', sampleRate, 'recalibrate', obj.MTCal.BuildUponPreviousCal, ...
                            'autoScopeAmpl', obj.MTCal.AutoScopeAmplitude, ...  % 'memory', memory, ...
                            'awgChannels', aChan, 'scopeChannels', sChan, ...
                            'maxFreq', obj.MTCal.MaxTone, 'analysisAvg', obj.MTCal.AnalysisAverage, ...  %'toneDev', toneDev, ...
                            'amplitude', obj.MTCal.ScopeAmplitude, 'axes', [], ...
                            'scopeBW', obj.MTCal.ScopeBandwidth, 'scopeSIRC', obj.MTCal.SIRC, 'separateTones', obj.MTCal.UseSeparateTonesPerChannel, ...
                            'skewIncluded', obj.MTCal.ChToChSkew, 'removeSinc', 0, 'debugLevel', 0, 'restoreScope', 1, ...
                            'arbConfig', obj.Instrument.ArbConfig);
                    obj.setError('frequency response calibration not yet implemented');
                catch ex
                    msg = sprintf('%s\n%s', ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]);
                    fprintf('%s\n', msg');
                    obj.setError(ex.message);
                end
                
            else
                obj.setCommandError();
            end
        end

        
        function runSkewAmplCal(obj, mode)
            try
                arbConfig = loadArbConfig(obj.Instrument.ArbConfig);
                if (obj.MTCal.SampleRate <= 0)
                    sampleRate = arbConfig.defaultSampleRate;
                else
                    sampleRate = obj.MTCal.SampleRate;
                end
                aChan = obj.MTCal.AWGChannels;
                while (length(aChan) < 4)
                    aChan{end+1} = 'unused';
                end
                aChan{5} = obj.MTCal.AWGTrigger;
                sChan = obj.MTCal.ScopeChannels;
                while (length(sChan) < 4)
                    sChan{end+1} = 'unused';
                end
                sChan{5} = obj.MTCal.ScopeTrigger;
                [result, rmsData] = iqskewcalM8199A('scope', obj.MTCal.ScopeType, 'sim', 0, 'scopeAvg', obj.MTCal.ScopeAverage, ...
                        'numTones', obj.MTCal.ToneCount, 'scopeRST', obj.MTCal.ScopeReset, 'AWGRST', obj.MTCal.AWGReset, ...
                        'sampleRate', sampleRate, 'recalibrate', obj.MTCal.BuildUponPreviousCal, ...
                        'autoScopeAmpl', obj.MTCal.AutoScopeAmplitude, ...  % 'memory', memory, ...
                        'awgChannels', aChan, 'scopeChannels', sChan, 'mode', mode, ...
                        'maxFreq', obj.MTCal.MaxTone, 'analysisAvg', obj.MTCal.AnalysisAverage, ...  %'toneDev', toneDev, ...
                        'amplitude', obj.MTCal.ScopeAmplitude, 'axes', [], ...
                        'scopeBW', obj.MTCal.ScopeBandwidth, 'scopeSIRC', obj.MTCal.SIRC, 'separateTones', obj.MTCal.UseSeparateTonesPerChannel, ...
                        'skewIncluded', obj.MTCal.ChToChSkew, 'removeSinc', 0, 'debugLevel', 0, 'restoreScope', 1, 'overwrite', 1, ...
                        'arbConfig', obj.Instrument.ArbConfig);
                if (isempty(result) || result ~= 1)
                    obj.setError('skew calibration failed');
                end
                % remember the result for a later query
                obj.MTCal.rmsData = rmsData;
            catch ex
                msg = sprintf('%s\n%s', ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]);
                fprintf('%s\n', msg');
                obj.setError(ex.message);
            end
        end
        
        
        function returnRmsData(obj, xname, yname)
            if (obj.Server.ParseNext(1) == '?')
                arg = str2double(obj.Server.ParseNext(2:end));
                if (isnan(arg) || ~isreal(arg) || ~isscalar(arg))
                    arg = 1;
                end
                str = '';
                if (~isempty(obj.MTCal.rmsData) && obj.MTCal.rmsData.version == 2 && ...
                        isfield(obj.MTCal.rmsData, xname) && isfield(obj.MTCal.rmsData, yname))
                    for i = 1:min(size(obj.MTCal.rmsData.(xname), 1), size(obj.MTCal.rmsData.(yname), 1))
                        if (~isempty(str))
                            del = ';';
                        else
                            del = '';
                        end
                        str = sprintf('%s%s%g;%g', str, del, obj.MTCal.rmsData.(xname)(i,arg), obj.MTCal.rmsData.(yname)(i,arg));
                    end
                end
                obj.sendResponse(str);
            else
                setQueryOnlyError();
            end
        end 

    end
end




