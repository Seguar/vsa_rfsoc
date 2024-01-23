function ENOB = iqenobieee_M8199A_ILV(analyzer, arbConfig, tones, fsAWG, awg_channels, awg_trig, ...
    scopechannels, scopeRST, autoScopeAmpl, scopeAmpl, scopeAvg, analysisAvg, bandwidth, ...
    hMsgBox, axesHandles, oldResults, lgText)
% iqenobieee makes and ENOB measurement over frequency using
% a DCA according to IEEE 1658-2011. 
% 
% As the algorithm requires pattern lock, the DCA needs an external trigger.
% Moreover a timebase reference is used to increase jitter performance. Both
% signals are generated with the AWG along with the test signals. 
% Adapted to M8199A_ILV
%
% B. Krueger, Keysight Technologies, 2021
% 
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 


    % AWG
    visa_addr_awg = arbConfig.visaAddr;
    amplitude = 0.5;   % the single-ended output amplitude in V

    % connections
    dca_meas_channel     = scopechannels{1};   % the channel to which the AWG is connected
    awg_meas_channel     = awg_channels(1);    % the channel to output the measurement signal
    awg_timebase_channel = awg_trig;           % the channel to output the timebase signal
    awg_trigger_channel  = awg_trig;           % the channel to output the trigger signal

    % DCA
    Navg          = scopeAvg;     % some averaging is allowed according to the standard and this value seems to give stable results
    spb           = 16;    % the samples per bit to be acquired
    dca_mem_depth = 16384; % the DCA's available amount of memory
    % ---
    
    debug = 1 ; 
    
    if autoScopeAmpl == 1
        scopeAmplitude = -1 ;
    else
        scopeAmplitude = scopeAmpl ; 
    end
    
 %% MEASUREMENT SECTION
    
    % decide if we use real-time scope or DCA
    if strcmpi(analyzer, 'rts')
        visa_addr_scope = arbConfig.visaAddrScope;
        dca_channel_id = dca_meas_channel;
        scopeFct = @iqreadscope;
        spb = 1 ;
        scopeBW = 'AUTO';
    else
        visa_addr_scope = arbConfig.visaAddrDCA;
        if ~isempty(strfind(dca_meas_channel, 'DIFF'))
            dca_channel_id = dca_meas_channel;
        elseif isempty(strfind(dca_meas_channel, 'FUNC'))  % single-ended channel                                      
            dca_channel_id = strcat('CHAN', dca_meas_channel);
        else
            dca_channel_id = dca_meas_channel;
        end
        scopeFct = @iqreaddca;
        scopeBW = 'MAX';
    end
    
    % Set parameters for scopeFunction 
    scopeChannels = {dca_channel_id} ; 
    
    if (~isempty(hMsgBox))
        hMsgBox.update(0.01, 'Trying to connect to AWG...');
    end
    % initialize the instrument connection
    awg = iqopen(visa_addr_awg);
    awg.Timeout = 30;
%     if (isempty(awg) || (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel')))
%         return;
%     end
    if (isempty(awg) || (~isempty(hMsgBox) && hMsgBox.canceling()))
        return;
    end

    dca = iqopen(visa_addr_scope);
    dca.Timeout = 240;
%     if (isempty(dca) || (~isempty(hMsgBox) && getappdata(hMsgBox, 'cancel')))
%         return;
%     end
    if (isempty(dca) || (~isempty(hMsgBox) && hMsgBox.canceling()))
        return;
    end
    % ---
    
    if (~isempty(hMsgBox))
        hMsgBox.update(0.02, 'Setting up timebase...');
    end
    try
%         
        samples = SineWaveGenerator(fsAWG,tones(1),dca_mem_depth);
       
        arbConfig = loadArbConfig();

        chMap = zeros(size(arbConfig.channelMask,2), 2);
        chMap(awg_meas_channel, 1) = 1;


        % make the measurements
        ENOB     = NaN(length(tones),1);
        SINAD = zeros(length(tones),1);
        ENOB_bk  = zeros(length(tones),1);
        SNR     = zeros(length(tones),1);
        THD     = zeros(length(tones),1);
        SFDR     = zeros(length(tones),1);
        fund_mag     = zeros(length(tones),1);
        spectrum_maxval = NaN(length(tones),1);
        
        ft       = zeros(length(tones),1);
        FSR_set  = 0; % we want to set the FSR to the amplitude measured at the first frequency point
        
        % Set trigger accordingly
        if (isfield(arbConfig, 'sampleMarker'))
            if (contains(arbConfig.sampleMarker, 'Once'))
               % t.b.d.
               trigFreq = fsAWG / 16 ; 
            elseif (contains(arbConfig.sampleMarker, '/'))
                div = str2double(arbConfig.sampleMarker(strfind(arbConfig.sampleMarker,'/')+1:end));
                trigFreq = fsAWG / div ; 
            end
        end
        
        % T.B.D. : for differential channels a de-skew could be done here
        % (with multi-tone signal)
        
        
        % iqreaddca parameters 
        scopeDeskew = 0 ;           % no de-skewing for measurement (only done once at the beginning, with multitone)
        scopeSIRC = 1 ;
        
        for nn = 1:length(tones)

            if (~isempty(hMsgBox))
                if hMsgBox.canceling()
                    break;
                end
                hMsgBox.update((2*nn-1)/(2*length(tones)), 'Downloading waveform to AWG...');
            end
            % generate the test tone
            [samples,ft(nn),fnum(nn),fden(nn)] = SineWaveGenerator(fsAWG,tones(nn),dca_mem_depth);
            iqdownload(samples, fsAWG, 'channelMapping', chMap, 'run', 1);
            % ---

            if (~isempty(hMsgBox))
                if hMsgBox.canceling()
                    break;
                end
%                 waitbar((2*nn)/(2*length(tones)), hMsgBox, 'Reading data from DCA...');
                hMsgBox.update((2*nn)/(2*length(tones)), 'Reading data from scope...');
            end
            
            
            [ydata, fsScope] = scopeFct([], scopeChannels, [], dca_mem_depth / fsAWG, scopeAvg, scopeAmplitude, trigFreq, [], spb*fsAWG/trigFreq, scopeBW, scopeSIRC, scopeDeskew);
                    
            xdata = (0:length(ydata)-1)'/fsScope; 
            
%             fprintf(sprintf('Number of AWG samples = %d \n', length(samples)));
%             fprintf(sprintf('Number of scope samples = %d \n', length(xdata)));
             
            % Remove last sample for odd number of acquired samples, which
            % would result in complex waveform
            if mod(length(xdata), 2) ~= 0
                xdata = xdata(1:end-1);
                ydata = ydata(1:end-1);
            end
            
            % ---
            
            % remove frequency content above the Nyquist frequency
            if ft(nn)>bandwidth % make sure that we do not cut off our tone
                bw_limit = ft(nn); % if the last tone is above the bandwidth, slightly increase the bw
            else
                bw_limit = bandwidth;
            end
            
            Ndca = length(ydata);
            Nawg = length(samples);
            
            %fsDCA = 1/(10*(Nawg/(10*fsAWG))/(Nawg*spb));
            fsDCA = fsScope;    % TD
            faxis = fsDCA*(-Ndca/2:Ndca/2-1)/Ndca;
            
            spectrum = fftshift(fft(ydata)/Ndca);
            spectrum(abs(faxis)>bw_limit) = 1e-15;
            ydata = ifft(fftshift(spectrum))*length(spectrum);
            
            impedance = 50 ; 
            freq_spectrum = (0:length(spectrum)-1)/length(spectrum) * fsScope ;
            spectrum_dbm = 20*log10(abs(ifftshift(spectrum))*sqrt(1000)*sqrt(2)/sqrt(impedance));
            
            spectrum_maxval(nn) = max(spectrum_dbm);
            
            if nn == 1
                 [Amp_DC,~] = DetectAmplitudeAndPhase(fnum(nn),fden(nn)*fsScope/fsAWG,ydata') ; 
            end
            
            [ENOB_bk(nn), SINAD(nn), SNR(nn), THD(nn), SFDR(nn), fund_mag(nn)]=MeasSpectralPerformance(ydata', fnum(nn), fden(nn)*fsScope/fsAWG, fsScope, Amp_DC, bw_limit) ;
            
            %             ---
            
            % fit the measured data to a sine curve according to IEEE 1658-2011 pp. 34
            % using plain MATLAB. On p.98 the standard recommends using a
            % four-parameter fit. For this purpose, the standard suggests on p. 96 
            % to do a three-parameter pre-fit first and then use the results as
            % an initial guess to the four-parameter fit.
            options.TolX        = 1e-9;
            options.TolFun      = 1e-6;
            options.MaxFunEvals = 1500;
            options.MaxIter     = 1000;
            
            % do the three parameter fit
            pguess = [0.5,0.5,1e-3]; % initial guess
            fun = @(p) sum((ydata - (p(1)*cos(2*pi*ft(nn)*xdata)+p(2)*sin(2*pi*ft(nn)*xdata)+p(3))).^2);
            [p,fminres,exitflag(1)] = fminsearch(fun,pguess,options); %#ok<*ASGLU>
            
            % do the four-parameter fit
            qguess = [p ft(nn)]; % use the three-parameter fit result and the computed frequency as the initial guess
            fun2 = @(q) sum((ydata - (q(1)*cos(2*pi*q(4)*xdata)+q(2)*sin(2*pi*q(4)*xdata)+q(3))).^2);
            [p,fminres,exitflag(2)] = fminsearch(fun2,qguess,options); %#ok<*ASGLU>
            % ---

            % make sure that the fminsearch did not terminate prematurely
            if sum(exitflag) == 2
                
                % compute amplitude and phase according to IEEE 1658-2011 p. 35 eq. (15)
                A   = sqrt(p(1)^2+p(2)^2);
    %             phi = atan2(p(1),p(2));
                % ---

                % plot measured and fitted data for verification
                cla(axesHandles(1), 'reset');
                hold(axesHandles(1), 'on');
                plot(axesHandles(1), freq_spectrum*1e-9,spectrum_dbm,'b','Linewidth',2);
                
                xlim(axesHandles(1), [0 bw_limit*1e-9]);
                ylim(axesHandles(1), [-90 10]);
                grid(axesHandles(1), 'on');
%                 legend(axesHandles(1), 'Measured Data', 'Fitted Curve', 'Location', 'NorthEast');
                xlabel(axesHandles(1), 'Frequency [ GHz ] ')
                ylabel(axesHandles(1), 'Mag [ dBm ]')
                title(axesHandles(1), sprintf('Captured spectrum @ %g GHz', ft(nn)*1e-9));
                if debug == 1
                    plot(axesHandles(1), ft(1:nn)*1e-9,spectrum_maxval(1:nn),'-ob','MarkerSize', 4);
                    yyaxis(axesHandles(1), 'right')
                    plot(axesHandles(1), ft(1:nn)*1e-9,SINAD(1:nn),'-ok','MarkerSize', 4);
                    plot(axesHandles(1), ft(1:nn)*1e-9,-THD(1:nn),'--+c','MarkerSize', 4);
                    plot(axesHandles(1), ft(1:nn)*1e-9,SFDR(1:nn),'--s','Color', '#C04040', 'MarkerSize', 4);
                    plot(axesHandles(1), ft(1:nn)*1e-9,SNR(1:nn),'--dr','MarkerSize', 4);
                    ylim(axesHandles(1), [10 60]);
                    yyaxis(axesHandles(1), 'left')
                    legend(axesHandles(1), {'spectrum', 'power', 'SINAD', '-THD', 'SFDR', 'SNR'});
                end
                % ---

                % set the the FSR to the amplitude that we measured at the first
                % frequency point (lowest frequency) to remove any constant
                % attentuation from our measurement
                if FSR_set == 0
                    FSR = 2*A;
                    FSR_set = 1;
                end
                %---

                % compute the ENOB according to IEEE 1658-2011 p. 57 eq. (41),
                % using (30) on p. 52 to calculate the rms noise and distortion
                ENOB(nn) = log2(FSR./( sqrt(12)*sqrt(1/length(ydata)*fun2(p)) ));

                cla(axesHandles(2), 'reset');
                hold(axesHandles(2), 'all');
                leg = {};
                if (~isempty(oldResults))
                    for k = 1:length(oldResults)
                        plot(axesHandles(2), oldResults(k).freqs/1e9, oldResults(k).enobs, '.-', 'linewidth', 2, 'Marker', 'd');
                        leg{end+1} = oldResults(k).legend;
                    end
                end
                plot(axesHandles(2), tones/1e9, ENOB, '.-', 'linewidth', 2, 'Marker', 'd');
                leg{end+1} = lgText;
                legend(axesHandles(2), leg);
                grid(axesHandles(2), 'on');
                xlabel(axesHandles(2), 'Frequency (GHz)');
                ylabel(axesHandles(2), 'ENOB');
                title(axesHandles(2), sprintf('ENOB %g GSa/s, %g V Amplitude, IEEE 1658-2011', fsAWG/1e9, amplitude));
                
            else
                ENOB(nn) = NaN;
                warning('Curve fitting failed: Ignoring the ENOB result');
            end
            
            if debug == 1
%                 fprintf(sprintf('Signal frequency: %.2f GHz \n', ft(nn)*1e-9));
%                 fprintf(sprintf('ENOB: %.1f bits \n', ENOB_bk(nn)));
%                 fprintf(sprintf('SINAD: %.1f dB \n', SINAD(nn)));
%                 fprintf(sprintf('THD: %.1f dB \n', THD(nn)));
%                 fprintf(sprintf('SNR: %.1f dB \n', SNR(nn)));
%                 fprintf(sprintf('SFDR: %.1f dB \n', SFDR(nn)));
%                 fprintf(sprintf('Amplitude: %.0f mV \n', fund_mag(nn)*1e3));
            end
            % ---
            
        end
        ft   = ft(not(isnan(ENOB)));
        ENOB = ENOB(not(isnan(ENOB)));
        
        if debug == 1
            figure ; 
            subplot(2,1,1); hold all ; 
            plot(ft*1e-9, ENOB_bk, 'Displayname', 'ENOB (IEEE 1658-2011)');
%             plot(tones*1e-9, ENOB, 'Displayname', 'ENOB (ms)');
            xlabel('Frequency [GHz]');
            ylabel('ENOB [bits]');
            title('ENOB acc. to IEEE 1658-2011');
            grid on ;
            legend('show');
            subplot(2,1,2) ; hold all ; 
            plot(ft*1e-9, SINAD, 'Displayname', 'SINAD');
            plot(ft*1e-9, -THD, 'Displayname', '-THD');
            plot(ft*1e-9, SFDR, 'Displayname', 'SFDR');
            plot(ft*1e-9, SNR, 'Displayname', 'SNR');
            xlabel('Frequency [GHz]');
            ylabel('[dB]');
            ylim([10 60]);
            title('Spectral performance');
            grid on ;
            legend('show');
        end  
        
        % ---

    catch err
        display(err.message);
        display(err.stack);
    end

    % disconnect from the instruments
    iqclose(awg); % close connection
    delete(awg); % delete VISA object
    iqclose(dca); % close connection
    delete(dca); % delete VISA object
    % ---

    % assign main result variables to base workspace
    assignin('base','ENOB',ENOB);
    assignin('base','ft',ft);
    % --
    
end

function [samples, ft, fnum,fden] = ...
    SineWaveGenerator(fupdate,ftone,dca_mem_depth)

	% This function generates a sine wave vector in Offset binary format
	% (-128...127) according to the IEEE Std 1658-2011
	% - fupdate       = DAC Sample Rate
	% - ftone         = Requested DAC output frequency
    % - dca_mem_depth = DCA memory depth
    %
    % - samples = Test signal vector
    % - ft      = Actual frequency of the test signal

    % Set the back-off decrement. This value is used to make sure that the
    % generated frequencies do not exceed the AWG's Nyquist frequency.
    backOffDecrement = 100e6;
    
	% Set the DAC resolution in bits
	N = 8;

	% Set the pattern length. According to the standard, the pattern length
    % needs to be at least M = pi * 2^N samples. Moreover, we need it to be a
    % multiple of 128. Thus we use 1/4 of the DCA's memory.
    M = dca_mem_depth/4;

	% Calculate the number of cycles of ftone which will fit into the
	% number of samples selected
    % J MUST be > 5 according to the standard or we might encounter measurement
    % errors!
	J = round((ftone/fupdate)*M);

	% Calculate a prime number of cycles to ensure the sinewave selected 
	% uses the full DAC code range, and report the actual frequency.
	J  = Closest_Prime(J);
	ft = fupdate*J/M;
    
    % Make sure that the calculated frequency does not exceed the DAC's Nyquist
    % frequency.
    while ft > fupdate/2
       ftone = ftone-backOffDecrement;
       J     = round((ftone/fupdate)*M);
       J     = Closest_Prime(J);
       ft    = fupdate*J/M;
    end

	% Generate the sinewave according to eq. (28) of the standard document
	n       = 0:M-1;
	samples = round((2^(N-1)-0.35)*cos(2*pi*J*n/M)-0.5);
    
    fnum = J ; 
    fden = M ; 

end

function [samples, ft, fnum,fden] = ...
    SineWaveGenerator_UXR(fupdate,ftone,fs_scope, dca_mem_depth)

	% This function generates a sine wave vector in Offset binary format
	% (-128...127) according to the IEEE Std 1658-2011
	% - fupdate       = DAC Sample Rate
	% - ftone         = Requested DAC output frequency
    % - dca_mem_depth = DCA memory depth
    %
    % - samples = Test signal vector
    % - ft      = Actual frequency of the test signal

    % Set the back-off decrement. This value is used to make sure that the
    % generated frequencies do not exceed the AWG's Nyquist frequency.
    backOffDecrement = 100e6;
    
	% Set the DAC resolution in bits
	N = 8;

	% Set the pattern length. According to the standard, the pattern length
    % needs to be at least M = pi * 2^N samples. Moreover, we need it to be a
    % multiple of 128. Thus we use 1/4 of the DCA's memory.
    M = dca_mem_depth/4;

	% Calculate the number of cycles of ftone which will fit into the
	% number of samples selected
    % J MUST be > 5 according to the standard or we might encounter measurement
    % errors!
	J = round((ftone/fupdate)*M);

	% Calculate a prime number of cycles to ensure the sinewave selected 
	% uses the full DAC code range, and report the actual frequency.
	J  = Closest_Prime(J);
	ft = fupdate*J/M;
    
    % Make sure that the calculated frequency does not exceed the DAC's Nyquist
    % frequency.
    while ft > fupdate/2
       ftone = ftone-backOffDecrement;
       J     = round((ftone/fupdate)*M);
       J     = Closest_Prime(J);
       ft    = fupdate*J/M;
    end

	% Generate the sinewave according to eq. (28) of the standard document
	n       = 0:M-1;
	samples = round((2^(N-1)-0.35)*cos(2*pi*J*n/M)-0.5);
    
    fnum = J ; 
    fden = M ; 

end

function [trig_samples, ftrig] = TriggerGenerator(fupdate)

    % Use exactly one segment, i.e 128 bit
    M = 128;
    % Set the dac resolution
    N = 8;
    % We want to use double the DAC Ref CLK frequency for triggering, which
    % corresponds to eight full cycles.
    J = 8;
    
    % Compute the trigger waveform
    n = 0:M-1;
    trig_samples = round((2^(N-1)-0.35)*cos(2*pi*J*n/M)-0.5);
    
    % Compute the reference frequency to be used as the timebase reference
    ftrig = fupdate*J/M;

end


function Ncycles = Closest_Prime(Ncyc)

	Ncycles = Ncyc;
	if ~isprime(Ncycles)
		
        if Ncycles < 2
            % 2 is the smallest prime number
            Ncycles = 2;
        else
            
            Ncyc_Upper = Ncyc;
            Ncyc_Lower = Ncyc;
            while 1

                % we prefer smaller numbers so try these first
                Ncyc_Lower=Ncyc_Lower-1;
                if isprime(Ncyc_Lower)
                    Ncycles=Ncyc_Lower;
                    break
                end

                Ncyc_Upper=Ncyc_Upper+1;
                if isprime(Ncyc_Upper)
                    Ncycles=Ncyc_Upper;
                    break
                end

            end
            
        end
		
	end

end

function [ENOB_IEEE, SINAD, SNR, THD, SFDR, fund_mag]=MeasSpectralPerformance(data, fnum, fden, fs,Amp_DC, evalBW)
%% DESCRIPTION
% Calculates the ENOB of a sampled signal with a frequency 
% fin = fnum/fden*fs

% Nh = 10 ; % number of harmonics
Nh = min([10, floor(evalBW/(fnum/fden*fs))]);
%% COMMENTS
% BK 2017 10 15 - Written from scratch

if mod(length(data), fden) ~= 0
    %error
    SINAD = 0;
    SNR = 0;
    THD = 0;
else
    if size(data,1)>1
        data=data';
    end
    t = (0:length(data)-1) / fs;
    % Calculate magnitude and phase of fundamental, harmonics and worst spur
    [fund_mag, fund_phase]=DetectAmplitudeAndPhase(fnum,fden,data) ;     
    [harm_mag, harm_phase, THD]=CalculateTHD(data, fnum, fden, Nh) ;
    data_raw = data ; 
    % Remove harmonics 
    for i = 2:length(harm_mag)
       data = data - harm_mag(i)*cos(2*pi*fnum*(i)/fden*fs*t + harm_phase(i)); 
    end
    % Remove worst-case spur
    [spur_freq, spur_mag, spur_phase, SFDR]=CalculateSFDR(data, fnum, fden) ;
    data = data - spur_mag*cos(2*pi*spur_freq*fs*t + spur_phase);            
    % Remove fundamental
    videal = fund_mag*cos(2*pi*fnum/fden*fs*t + fund_phase) ; 
    data = data - videal ; 
    % Calculate SNR / ENOB
    pnoise = var(data) ;
    psig = fund_mag^2/2 ;
    
    pFSR = Amp_DC^2/2 ;
    
    SNR = 10*log10(psig/pnoise);                            % SNR is calculated after removing harmonics + worst-case spur
    % Calculate ENOB
    pnoise = var(data_raw - videal) ; 
    SINAD = 10*log10(psig/pnoise);       % ENOB is calculated from raw data (includes all harmonics & spurs)
    SINAD_IEEE = 10*log10(pFSR/pnoise);
    ENOB_IEEE = (SINAD_IEEE - 1.76)/6.02;
end
end

function [Amplitude,Phase]=DetectAmplitudeAndPhase(fnum,fden,data)

% Complex exponential matching frequency
cexp=exp(-1i*2*pi*fnum/fden*(0:length(data)-1));
cx=2*sum(data.*cexp)/length(data);
Amplitude=abs(cx);
Phase=angle(cx);
end

function [harm_mag, harm_phase, THD]=CalculateTHD(Data, fnum, fden, Nh)
%% DESCRIPTION
% This method calculates total harmonic distortion regarding the first
% Nh harmonics 

%% COMMENTS
% BK 2015 06 05 - Written from scratch

% Time vector for the complex exponential
%t = (0:(length(Data)-1))/(length(Data));
t = (0:(length(Data)-1)) ;
%
harm_mag = zeros(1,Nh);
harm_phase = zeros(1,Nh);

% Complex exponential with 2 periods.
for N = 1:Nh+1
    %cexp = exp(-1i*2*N*fnum/fden*pi*t);
    cexp = exp(-1i*2*N*fnum/fden*pi*t);
    cx=2*sum(Data.*cexp)/length(Data);
    harm_mag(N) =abs(cx);
    harm_phase(N) = angle(cx);
end
THD = 10*log10(sum(harm_mag(2:end).^2) ./ harm_mag(1)^2);
 
end

function [spur_freq, spur_mag, spur_phase, SFDR]=CalculateSFDR(Data, fnum, fden)
%% DESCRIPTION
% This method calculates total harmonic distortion regarding the first
% Nh harmonics 

%% COMMENTS
% BK 2015 06 05 - Written from scratch

% Time vector for the complex exponential
%t = (0:(length(Data)-1))/(length(Data));
t = (0:(length(Data)-1)) ;
%

cexp = exp(-1i*2*fnum/fden*pi*t);
cx=2*sum(Data.*cexp)/length(Data);
fund_mag =abs(cx);

spec = 2*fft(Data)/length(Data) ;
spec = spec(2:end);                 % remove DC

[spec_sorted, idx_sorted] = sort(abs(spec),'descend');

spur_mag = spec_sorted(3);    % the first two elements correspond to the fundamental
spur_phase = angle(spec(idx_sorted(3))); 

% spur_freq = (idx_sorted(3)-1)/(length(Data)); % spur frequency, normalized to fs0
spur_freq = (idx_sorted(3))/(length(Data)); % spur frequency, normalized to fs0

SFDR = 20*log10(fund_mag/spur_mag);

end
