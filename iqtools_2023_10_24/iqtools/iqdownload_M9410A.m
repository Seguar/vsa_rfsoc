function f = iqdownload_M9410A(arbConfig, fs, iqdata, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, amplitude, fCenter, segmName)
% Download IQ to M9410A
% Ver 0.1, Marc Schweizer, April 7, 2020
% update V0.2 Karim Louertani - Vincent Gillet, April 2022

if (~isempty(sequence))
    errordlg('Sequence mode is not available for the Keysight VSG');
    f = [];
    return;
end

f = iqopen(arbConfig);
if (isempty(f))
    return;
end
% Walt Schulte added 10/11 to set visa object user data to the arb
% used for download
f.UserData = arbConfig.model;

if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
    xfprintf(f, '*RST');
end

% prompt the user for center frequency and power
% defaults are the current settings
% added a conditional for scripting
if (isempty(amplitude) || isempty(fCenter) || isempty(segmName))
    fCenter      = xquery(f, ':SOUR:freq? ');
    amplitude    = xquery(f, ':SOUR:POW?');
    segmName     = sprintf('IQTools%04d', segmNum); %WBS: needs to have .wfm extension?      % filename for the data in the ARB
    prompt       = {'Amplitude of Signal (dBm):', 'Carrier Frequency (Hz): ', 'Segment Name: '};
    defaultVal   = {iqengprintf(eval(amplitude)), iqengprintf(eval(fCenter)), sprintf(segmName)};
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

downloadSignal(f, iqdata.', segmName, fs, fCenter, amplitude, marker1, marker2, arbConfig.DACRange, arbConfig.LOIPAddr);

if (~keepOpen)
    iqclose(f);delete(f); 
end

end


function downloadSignal(deviceObject, IQData, ArbFileName, sampleRate, centerFrequency, outputPower, marker1, marker2, scalingFactor, varargin)
% This function downloads IQ Data to the signal generator's non-volatile memory
% This function takes 2 inputs,
% * instrument object
% * The waveform which is a row vector.
% Syntax: downloadWaveform(instrObject, Test_IQData)

% Copyright 2012 The MathWorks, Inc.
% varargin{1} is vector UXG LO IP address

deviceObject.Timeout = 60;
xfprintf(deviceObject,'*CLS');

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
% For now we will just create a .MAT file and load and play this
fileLoadName = [pwd '\' ArbFileName '.mat'];
arbLoadName = ArbFileName;

%For some reason, the iqdata seems to be flipped...so I am reversing it
%here
IQData = imag(IQData) + real(IQData)*j;

iqsavewaveform(IQData, sampleRate, 'filename', strcat(ArbFileName,'.mat'));

% Once we do file transfer like instruments, we will modify
% % Seperate out the real and imaginary data in the IQ Waveform
% wave = [real(IQData);imag(IQData)];
% wave = wave(:)';    % transpose the waveform
% 
% % Scale the waveform if necessary
% tmp = max(abs([max(wave) min(wave)]));
% if (tmp == 0)
%     tmp = 1;
% end
% 
% % ARB binary range is 2's Compliment -32768 to + 32767
% % So scale the waveform to +/- 32767 not 32768
% scale  = 2^15-1;
% scale  = scale/tmp;
% wave   = round(wave * scale);
% modval = 2^16;
% % Get data from double to unsigned int
% wave = uint16(mod(modval + wave, modval));

% Some settings commands to make sure we don't damage the instrument
xfprintf(deviceObject,':OUTPut:STATe OFF');
xfprintf(deviceObject,':SOURce:RADio:ARB:STATe OFF');
xfprintf(deviceObject,':OUTPut:MODulation:STATe OFF');

%%%%%%%%%%%%%%%%% Get waveform directory and verify if already present%%%
Waveforms_available = xquery(deviceObject,'MMEM:CAT?');
Waveform_Directory = xquery(deviceObject,'MMEM:CDIR?');
Instrument_ARBLoad = [Waveform_Directory(2:end-2) '\' ArbFileName '.mat'];

if contains(Waveforms_available,ArbFileName) % delete ARB file on instrument if it exists
     xfprintf(deviceObject,sprintf(':MMEM:DEL "%s"', Instrument_ARBLoad)); 
end

xfprintf(deviceObject,':SOURce:RADio:ARB:DELete:ALL');
%IQ Data
% write the data into the file on insturument %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileID = fopen(fileLoadName, 'r', 'ieee-le');
if fileID == -1, error('Cannot open file: %s', fileLoadName); end
format = 'uint8';
Data = fread(fileID, Inf, format);
fclose(fileID);
data=Data;
xbinblockwrite(deviceObject,data, 'uint8',sprintf(':MMEMory:DATA "%s",', Instrument_ARBLoad))
opcComp = xquery(deviceObject, '*OPC?');




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
%     %Marker Data
%     xbinblockwrite(deviceObject,marker,'uint8',[':MEMory:DATA "MKR1:' ArbFileName '", ']);
%     
% end

% Set the scaling to Scaling range
%xfprintf(deviceObject, [':RADio:ARB:HEADer:SCALe:OVERride "' arbLoadName '",' num2str(scalingFactor)]);

% Set the sample rate (Hz) for the signal.
% You can get this info for the standard signals by looking at the data in the 'waveforms' variable
%xfprintf(deviceObject,[':RADio:ARB:HEADer:SRATe:OVERride "' arbLoadName '",' num2str(sampleRate)]);
xfprintf(deviceObject,[':SOURce:RADio:ARB:SCLOCk:RATe ' num2str(sampleRate)]);

% set center frequency (Hz)
%xfprintf(deviceObject, ['FREQuency:CENTer ' num2str(centerFrequency)]); %WBS: turns LO RF off 
xfprintf(deviceObject, [':SOUR:FREQuency ' num2str(centerFrequency)]);
% set output power (dBm)
xfprintf(deviceObject, [':SOUR:POW ' num2str(outputPower)]);

% make sure output protection is turned on
% xfprintf(deviceObject,':OUTPut:PROTection ON');
% turn off internal AWGN noise generation
% xfprintf(deviceObject,':SOURce:RADio:ARB:NOISe:STATe OFF');

% Play back the selected waveform 

%xfprintf(deviceObject, [':SOURce:RADio:ARB:LOAD "' arbLoadName '"']); 
xfprintf(deviceObject, sprintf(':SOURce:RADio:ARB:LOAD "%s"',Instrument_ARBLoad)); 
%xfprintf(deviceObject, ['RADio:ARB:WAVeform "' arbLoadName '"']);%wbs: command still valid for 250 MHz arb
%WBS: could be xfprintf(deviceObject, [':SOURce:RAD:WARB:WAV "WFM1:'
%ArbFileName '"']); for wideband arb
opcComp = xquery(deviceObject, '*OPC?');
%xfprintf(deviceObject, [':SOUR:RAD:ARB:WAV "' arbLoadName '"']);
xfprintf(deviceObject, sprintf(':SOUR:RAD:ARB:WAV "%s"',Instrument_ARBLoad));

while str2double(opcComp)~= 1
    pause(0.5);
    opcComp = xquery(deviceObject, '*OPC?');
end

% ARB Radio on
xfprintf(deviceObject, ':SOURce:RADio:ARB ON');
% modulator on
xfprintf(deviceObject, ':OUTPut:MODulation:STATe ON');
% RF output on
xfprintf(deviceObject, ':OUTPut:STATe ON');

end

function setAndWait(deviceObject, queryCommand, desiredState, setupCommand)
% Controls the VUXG to set its external LO accordingly
    modeCurrent = xquery(deviceObject, queryCommand);
    if (~strcmp(modeCurrent(1:numel(desiredState)), desiredState))    
        xfprintf(deviceObject, setupCommand);
        opcComp = xquery(deviceObject, '*OPC?');
        while str2double(opcComp)~= 1
            pause(0.5);
            opcComp = xquery(deviceObject, '*OPC?');
        end
    end

end

