function f = iqdownload_N51xxA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, amplitude, fCenter, segmName)
  % result = iqdownload_N51xxA(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, lOamplitude, lOfCenter, segmName);

% Download IQ to MXG/MXG-X/EXG/ESG/PSG
% Ver 1.1, Robin Wang, Feb 2013
if (~isempty(sequence))
    errordlg('Sequence mode is not available for the Keysight VSG');
    f = [];
    return;
end

f = iqopen(arbConfig);
if (isempty(f))
    return;
end
    
if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
    xfprintf(f, '*RST');
end

% prompt the user for center frequency and power
% defaults are the current settings
% added a conditional for scripting
if (isempty(amplitude) || isempty(fCenter) || isempty(segmName))
    fCenter      = xquery(f, ':freq? ');
    amplitude    = xquery(f, ':power?');
    segmName     = sprintf('IQTools%04d', segmNum); %WBS: needs to have .wfm extension?      % filename for the data in the ARB
    prompt       = {'Amplitude of Signal (dBm):', 'Carrier Frequency (Hz): ', 'Segment Name: '};
    defaultVal   = {sprintf('%g', eval(amplitude)), sprintf('%g', eval(fCenter)), sprintf(segmName)};
    dlg_title    = 'Inputs for VSG';
    user_vals    = inputdlg(prompt, dlg_title, 1, defaultVal);
    drawnow;

    if (isempty(user_vals))
        return;
    end
    
    if (isempty(user_vals{1})) && (isempty(user_vals{2}))
        amplitude = 0;
        fCenter   = 1e9;
        warndlg('The amplitude is set to 0 dBm, and carrier frequency to 1 GHz')
    else
        amplitude = user_vals{1};
        fCenter   = user_vals{2};
    end

    if (isempty(user_vals{1})) && ~(isempty(user_vals{2}))
        amplitude = 0;
        warndlg('The amplitude is set to 0 dBm')
    else     
        amplitude = user_vals{1};
    end

    if ~(isempty(user_vals{1})) && (isempty(user_vals{2}))
        fCenter = 1e9;    
        warndlg('Carrier frequency is set to 1 GHz')
    else
        fCenter = user_vals{2};
    end
    
    if (isempty(user_vals{3}))
        segmName  = sprintf('IQTools%04d', segmNum);
    else     
        segmName  = user_vals{3};
    end
    
end

% added marker1 and marker2 to call (DV) to get markers working
downloadSignal(f, data.', segmName, fs, marker1, marker2, fCenter, amplitude, arbConfig.DACRange);

if (~keepOpen)
    iqclose(f);delete(f); 
end
end


function downloadSignal(deviceObject, IQData, ArbFileName, sampleRate, marker1, marker2, centerFrequency, outputPower, scalingFactor, varargin)
% This function downloads IQ Data to the signal generator's non-volatile memory
% This function takes 2 inputs,
% * instrument object
% * The waveform which is a row vector.
% Syntax: downloadWaveform(instrObject, Test_IQData)
% added marker1 and marker2 to call (DV)

marker1 = uint8(marker1);  % added by DV to get markers working.  
                           % Marker is first 4 bits 1 = marker1, 2=marker 
                           %  4 is marker 3 and 8 is marker 4
marker2 = uint8(marker2);  % unused 
% %Create marker file
% if (~isempty(marker1) || ~isempty(marker2))
% 
%     %Marker 1, track the signal
%     if (~isempty(marker1))
%         %Normalize
%         marker1 = marker1/(max(marker1));
%     else
%         marker1 = zeros(length(wave));
%     end
% 
%     %Marker 2, invert to the signal
%     if (~isempty(marker2))
%         %Normalize
%         marker2 = uint16(2*(~(marker2/(max(marker2)))));
%     else
%         marker2 = zeros(length(wave));
%     end
% 
%     marker = uint8(marker1+marker2);
%     
% end

% Copyright 2012 The MathWorks, Inc.
% varargin{1} is vector UXG LO IP address
if ~isvector(IQData)
    error('downloadWaveform: invalidInput');
else
    IQsize = size(IQData); %WBS: if Wideband vector UXG, needs to be > 800 samples
    % User gave input as column vector. Reshape it to row vector.
    if ~isequal(IQsize(1),1)
        IQData = reshape(IQData,1,IQsize(1));
    end
end


%% Download signal
% Seperate out the real and imaginary data in the IQ Waveform
wave = [real(IQData);imag(IQData)];
wave = wave(:)';    % transpose the waveform

% Scale the waveform if necessary
tmp = max(abs([max(wave) min(wave)]));
if (tmp == 0)
    tmp = 1;
end

% ARB binary range is 2's Compliment -32768 to + 32767
% So scale the waveform to +/- 32767 not 32768
scale  = 2^15-1;
scale  = scale/tmp;
wave   = round(wave * scale);
modval = 2^16;
% Get data from double to unsigned int
wave = uint16(mod(modval + wave, modval));
% Since xbinblockwrite uses little-endian (instrument-independent) for 'visa', 'tcpip' connection,
% modify the data accordingly
wave = swapbytes(wave);

% Some settings commands to make sure we don't damage the instrument
xfprintf(deviceObject,':OUTPut:STATe OFF');
xfprintf(deviceObject,':SOURce:RADio:ARB:STATe OFF');
xfprintf(deviceObject,':OUTPut:MODulation:STATe OFF');

% Write the data to the instrument 

% â€œ[:SOURce]:FREQuency:LO:SOURce INTernal|EXTernalâ€?
% initialize SCPI control of LO
% SCPI: â€œ[:SOURce]:FREQuency:LO:CONTrol:SCPI:INITialize ON|OFF|1|0â€?
%

xbinblockwrite(deviceObject,wave,'uint16',[':MEMory:DATA "WFM1:' ArbFileName '", ']);
xbinblockwrite(deviceObject, marker1,'uint8',['MEMory:DATA "MKR1:' ArbFileName '", ']);  % added by DV to get markers working

% scaling factor of 100% leads to lots of DAC range errors, limit to 99%
scalingFactor = min(scalingFactor, 0.99);
% Set the scaling to Scaling range
xfprintf(deviceObject, [':SOURce:RADio:ARB:RSCaling ' num2str(scalingFactor*100)]);

% Set the sample rate (Hz) for the signal.
% You can get this info for the standard signals by looking at the data in the 'waveforms' variable
xfprintf(deviceObject,[':SOURce:RADio:ARB:SCLock:RATE ' num2str(sampleRate)]); 
% set center frequency (Hz)
xfprintf(deviceObject, [':SOURce:FREQuency ' num2str(centerFrequency)]); %WBS: turns LO RF off 
% set output power (dBm)
xfprintf(deviceObject, ['POWer ' num2str(outputPower)]);

% make sure output protection is turned on
% xfprintf(deviceObject,':OUTPut:PROTection ON');
% turn off internal AWGN noise generation
% xfprintf(deviceObject,':SOURce:RADio:ARB:NOISe:STATe OFF');

% Play back the selected waveform 

%WBS: turn on LVDS control of N5193A. "[:SOURce]:FREQuency:LO:CONTrol:FCPort[:STATe] ON|OFF|1|0"
xfprintf(deviceObject, [':SOURce:RAD:ARB:WAV "WFM1:' ArbFileName '"']);%wbs: command still valid for 250 MHz arb
%WBS: could be xfprintf(deviceObject, [':SOURce:RAD:WARB:WAV "WFM1:'
%ArbFileName '"']); for wideband arb
opcComp = xquery(deviceObject, '*OPC?');
while str2double(opcComp)~= 1
    pause(0.5);
    opcComp = xquery(deviceObject, '*OPC?');
end

% ARB Radio on
xfprintf(deviceObject, ':SOURce:RADio:ARB:STATe ON');
% modulator on
xfprintf(deviceObject, ':OUTPut:MODulation:STATe ON');
% RF output on
xfprintf(deviceObject, ':OUTPut:STATe ON');

%Local Mode
xfprintf(deviceObject, 'SYST:COMM:GTL');
end


