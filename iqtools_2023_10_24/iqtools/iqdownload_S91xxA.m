function f = iqdownload_S91xxA(arbConfig, fs, data, marker1, marker2, keepOpen, amplitude, fCenter, segmName)
    % Download IQ to S9130A, S910xA, M9415A and M9410A
    % Revision 0.1, Robin Wang,  Nov 2020
    
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    
    % Do a reset if just downloading signals only,  or disable it
    isDoRest = 0;
    if (isDoRest)
        if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
            xfprintf(f, '*RST');
        end
    else
    end
    
    %% Set Output Port, Please revert IsSetOutputPort = 1 if you want to set Output port and download signals only, but VSA connectivity has to be disconnected
    IsSetOutputPort = 0;
    if (IsSetOutputPort)       
        xfprintf(f, 'SYST:PRES:PERS');
        xfprintf(f, 'INIT:CONT OFF');
        xfprintf(f, 'INIT:IMM;*WAI');
        
        if strcmp(arbConfig.model, 'S91xxA_RfOutput')
            xfprintf(f, 'SENS:FEED:RF:PORT:OUTPUT RFO ');
        else
            xfprintf(f, 'SENS:FEED:RF:PORT:INPUT NONE');
            if  strcmp(arbConfig.model, 'S91xxA_RRH1_RFHD1')
                xfprintf(f, 'SENS:FEED:RF:PORT:OUTPUT RRH1RFHD1 ');
                xfprintf(f, 'SENS:FEED:RF:PORT:INPUT RRH1RFHD2');
            elseif strcmp(arbConfig.model, 'S91xxA_RRH1_RFHD2')
                xfprintf(f, 'SENS:FEED:RF:PORT:OUTPUT RRH1RFHD2  ');
                xfprintf(f, 'SENS:FEED:RF:PORT:INPUT RRH1RFHD1');
            end
        end
        
    else
    end
    %% Prompt the user for RF frequency and RF power, download waveform
    if (isempty(amplitude) || isempty(fCenter))
        fCenter      = xquery(f, 'SOUR:FREQ? ');
        amplitude    = xquery(f, 'SOUR:POW?');
        prompt       = {'RF Output Power (dBm):', 'RF Frequency (Hz): ', 'Waveform Name'};
        if isempty(segmName)
            segmName = sprintf('Waveform_%04d', 1);
        else
            segmName = sprintf('Waveform_%04d', segmName);
        end
        defaultVal   = {iqengprintf(eval(amplitude)), iqengprintf(eval(fCenter)), sprintf(segmName)};
        dlg_title    = 'S91xxA RF Output Power and RF Frequency';
        user_vals    = inputdlg(prompt, dlg_title, [1 50], defaultVal, 'on');
        drawnow;
        
        if (isempty(user_vals))
            return;
        end
        amplitude = user_vals{1};
        fCenter   = user_vals{2};
    end
    
    % Download Waveform
    isUseWave = 0;
    downloadSignal(isUseWave, f, data.', segmName, fs, fCenter, amplitude, marker1, marker2);
    
    if (~keepOpen)
        iqclose(f);delete(f);
    end
    
end

function downloadSignal(isUseWave, deviceObject, IQData, ArbFileName, sampleRate, centerFrequency, outputPower, marker1, marker2)
    deviceObject.Timeout = 60;
    xfprintf(deviceObject,'*CLS');
    
    if ~isvector(IQData)
        error('downloadWaveform: invalidInput');
    else
        IQsize = size(IQData);
        % User gave input as column vector. Reshape it to row vector.
        if ~isequal(IQsize(1),1)
            IQData = reshape(IQData,1,IQsize(1));
        end
    end
    
    arbFileName = strcat(ArbFileName,'.mat');
    fileLoadName = [pwd '\' arbFileName];
    
    if (isUseWave)
        % Seperate out the real and imaginary data in the IQ Waveform
        wave = [real(IQData);imag(IQData)];
        wave = wave(:)';
        
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
        
        if (~isempty(marker1) || ~isempty(marker2))
            %Create marker file
            if (~isempty(marker1))
                %Normalize
                marker1 = marker1/(max(marker1));
            else
                marker1 = zeros(length(wave));
            end
            if (~isempty(marker2))
                %Normalize
                marker2 = uint16(2*((marker2/(max(marker2)))));
            else
                marker2 = zeros(length(wave));
            end
            %The markers value is a simple combination of bits. If you want to enable Marker 1 and 2, the value should be 3 (= 1 + 2). See a description on Marker File in X-Series Signal Generators Programming Guide (N5180-90074).
            marker = uint8(marker1 + marker2);
        end
        
        xbinblockwrite(deviceObject,wave,'uint16',['MMEM:DATA "' arbFileName '", ']);
        xbinblockwrite(deviceObject, marker,'uint8',['MEM:DATA "MKR:' ArbFileName '", ']);
        
    else
        IQData = IQData';        
        iqsavewaveform(IQData, sampleRate, 'filename', arbFileName);
        
        fid = fopen(fileLoadName, 'r');
        [wave, count] =fread(fid);
        fclose(fid);
        
        dutFile = strcat('C:\TEMP\', arbFileName);
        retString = xquery(deviceObject, 'MMEM:CAT? "C:\TEMP"');
        if(contains(retString, arbFileName))
            xfprintf(deviceObject,['MMEM:DEL "' dutFile '"']);
        end
        
        xbinblockwrite(deviceObject,wave,'uint8',['MMEM:DATA "' dutFile '", ']);
    end
    
    % Trig 2 Out Device: Source
    xfprintf(deviceObject, 'TRIG2:OUTP:DIR SOUR');
    % Trig 2 Out: Source Per Arb
    xfprintf(deviceObject, 'TRIG2:OUTP PARB');
    % Source Internal Trig Out
    xfprintf(deviceObject, 'TRIG:INT:SOUR:OUTP PARB');
    
    xfprintf(deviceObject,'OUTP OFF');
    xfprintf(deviceObject,'SOUR:RAD:ARB OFF');
    xfprintf(deviceObject,'OUTP:MOD OFF');
    
    % Load and Play back the selected waveform   
    xfprintf(deviceObject, ['SOUR:RAD:ARB:LOAD "' dutFile '"']);
    xfprintf(deviceObject, ['SOUR:RAD:ARB:WAV "' arbFileName '"']);
    
    opcComp = xquery(deviceObject, '*OPC?');
    while str2double(opcComp)~= 1
        pause(0.5);
        opcComp = xquery(deviceObject, '*OPC?');
    end
    
    %
    % xfprintf(deviceObject, ['SOUR:RAD:ARB:RSC ' num2str(scalingFactor)]);
    xfprintf(deviceObject, ['SOUR:RAD:ARB:SCL:RATE  ' num2str(sampleRate)]);
    xfprintf(deviceObject, ['SOUR:FREQ ' num2str(centerFrequency)]);
    xfprintf(deviceObject, ['SOUR:POW ' num2str(outputPower)]);
    
    % Turn on ARB, Modulator, RF Output
    xfprintf(deviceObject, 'SOUR:RAD:ARB ON');
    xfprintf(deviceObject, 'OUTP:MOD ON');
    xfprintf(deviceObject, 'OUTP ON');
    
end

