function iqinterleavecal(params)
  
% In-system interleaving skew calibration with sampling
% oscilloscope or power meter
%
% Parameters are passed as property/value pairs. Properties are:

%
% If called without arguments, opens a graphical user interface to specify
% parameters

% B.Krueger, Keysight Technologies 2014-2020
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHTS'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. AGILENT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS.

   
   arbConfig = loadArbConfig();
   
   % parameters
   channelsToRead = {'FUNC5', 'FUNC7'};
   meas_type = ['IRR'];
   meas_instr = ['DCA'];
   
   delaySweepRange = (-5:0.2:5)*1e-12;
   
   fs = 240e9;
   channelMapping = [1, 0; 1,0] ;
   
   f = iqopen(arbConfig);
   if (isempty(f))
      return;
   end
   
   f_DCA = iqopen(arbConfig.visaAddrDCA);
   if (isempty(f_DCA))
       return;
   end
   %% Image power measurement
   if strcmp(meas_type, 'IRR')
        
        Navg = 2;           % arbConfig.powerSensorAverages
        Nsamples = 512;
        fmin = 71e9;
        fmax = 100e9;
       % Peform insystem cal
%        if updateFR == 1
%            updateFreqResponse(channel);
%        end
       
       % generateWaveform
       trigFreq = 16e9;    % approx. 10 GHz
       trigFreq = round(trigFreq / fs * Nsamples) * fs / Nsamples;
       % in case we use markers, make sure that we have an integer ratio between Fs and trigFreq
       % round to next power of 2, so that it fits evenly into sigAWG
%         if (strcmpi(awgTrig, 'Marker'))
            trigFreq = fs / (2^round(log2(fs / trigFreq)));
%         end
       
       
       tone = linspace(fmin, fmax, 100);
       magnitude = zeros(1, 100);
       [iqdata, ~, ~, ~, chMap] = iqtone('sampleRate', fs, 'numSamples', Nsamples, ...
            'tone', tone, 'phase', 'Random', 'normalize', 1, ...
            'magnitude', magnitude, 'correction', 1, 'channelMapping', channelMapping);
        
       iqdownload(iqdata, fs, 'channelMapping', chMap, 'segmentNumber', 1);
       f = iqopen(arbConfig);
       
       
       fprintf('Start with skew optimization by measuring image power') ;
        if (strcmp(meas_instr, 'DCA'))     
           % t.b.i. setup DCA (from reset)
           
           % get initial delay values
%            delay_ch1 = GetDelay(f, 1)
%            delay_ch2 = GetDelay(f, 3);
%            delay_ch3 = GetDelay(f, 2);
%            delay_ch4 = GetDelay(f, 4);
           
           % perform sweep on DAC ch 3 to optimize ILV channel 1
           xquery(f_DCA, sprintf(':MEASure:OSCilloscope:VRMS:SOURce1 %s;*OPC?',channelsToRead{1} ));
           for i = 1:length(delaySweepRange)
                SetDelay(f, 3, delaySweepRange(i));
               % Measure image power
               for j = 1:Navg
%                     pause(0.7) % dummy read
                    xquery(f_DCA, ':ACQuire:CDISplay;:ACQuire:SINGle;*OPC?');
                    measuredPower_ch1(i,j) = str2num(xquery(f_DCA, sprintf(':MEASure:OSCilloscope:VRMS?')));
               end
           end
           measuredPower_ch1_mean = mean(measuredPower_ch1, 2);
           
%            % perform sweep on DAC ch 4 to optimize ILV channel 2
           xquery(f_DCA, sprintf(':MEASure:OSCilloscope:VRMS:SOURce1 %s;*OPC?',channelsToRead{2} ));
           for i = 1:length(delaySweepRange)
               SetDelay(f, 4, delaySweepRange(i));
               % Measure image power
               for j = 1:Navg
%                     pause(0.7) % dummy read
                    xquery(f_DCA, ':ACQuire:CDISplay;:ACQuire:SINGle;*OPC?');
                    measuredPower_ch2(i,j) = str2num(xquery(f_DCA, sprintf(':MEASure:OSCilloscope:VRMS?')));
               end
           end
           measuredPower_ch2_mean = mean(measuredPower_ch2, 2);
           
           % Set delays to optimum
           SetDelay(f, 3, delaySweepRange(measuredPower_ch1_mean == min(measuredPower_ch1_mean)))
           SetDelay(f, 4, delaySweepRange(measuredPower_ch2_mean == min(measuredPower_ch2_mean)))
            % Determine optimum delay
            % t.b.i.
            
           % Plot results
           cla(params.axes);
           plot(params.axes, delaySweepRange*1e12, measuredPower_ch1_mean , '.-'); 
           plot(params.axes, delaySweepRange*1e12, measuredPower_ch2_mean , '.-'); 
           title('Image power (in Vrms) vs. delay ');
%            legend('ILV-Channel 1', 'ILV-Channe 2');
           xlabel('Delay [ps]');
           ylabel('Voltage [Vrms]');
           grid on;

        end
   end
end

function initDCA(arbConfig)

end
        
function initPowerMeter(arbConfig)
    % code from first experiments ; not customer-ready!
    if (~isPowerSensorConnected)
        return
    end
    f_PM = iqopen(arbConfig.visaAddrPowerSensor);

%        xfprintf(f_PM,' :TRIGger:SOURce IMMediate' ) ;
   xfprintf(f_PM,' :INITiate:CONTinuous 1;');
   xfprintf(f_PM,' :SENSe3:AVERage:COUNt:AUTO 1');
   xfprintf(f_PM,' :TRIGger:SOURce IMMediate;:INITiate:CONTinuous 1;:SENSe3:MRAT DOUBLE ' ) ;

end

function retVal = GetDelay(f, channel)
 cmd = sprintf(':diagnostic:function? \"GetClockInputStageFineDelay\", \"%d\"', channel);   % stop DATA playback 
 retVal = xquery(f, cmd);
 retVal = str2double(retVal(2:end-2));
%
end

function SetDelay(f, channel, delay)
cmd = sprintf(':diagnostic:function \"SetClockInputStageFineDelay\", \"%d\", \"%1.2e\"', channel, delay);   % stop DATA playback 
xfprintf(f, cmd);

%:diagnostic:function "SetClockInputStageFineDelay", "1", "1e-12"
end

