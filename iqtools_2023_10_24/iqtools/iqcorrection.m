function varargout = iqcorrection(iqdata, fs, varargin)
%
% chMap, fpoints, normalize, useConvolution)
% perform magnitude/phase flatness compensation on a real or complex signal using the
% correction information that is stored in ampCorr.mat
%
% usage: 
%   [result chMap] = iqcorrection(iqdata, fs, 'chMap', chMap)
%          --> apply the corrections to iqdata using provided channel mapping
%     or
%   [cplxCorr perChannelCorr acs pidx] = iqcorrection([], [], 'chMap', chMap);
%          --> get correction information to apply it in the calling function
%     or
%   [cplxCorr perChannelCorr acs] = iqcorrection();
%          --> get correction information for display purposes
%
% where
%   acs     - correction structure as read from ampCorr.mat
%   result  - corrected waveform
%   pidx    - vector with indices into perChannelCorr, corresponding to chMap
%   iqdata  - input waveform. If iqdata = [], then the complex correction and 
%             per_channel correction arrays are returned.
%   fs      - sample rate in Hz
% additional parameters are passed as attribute/value pairs. The following
% attributes are defined:
%   chMap   - channel mapping, (see iqdownload for details)
%   fpoints - number of frequency points for compensation (set to [] to use default)
%   normalize      - if set to 1, scale to -1...+1 after applying correction (default: 1)
%   useConvolution - set to 1 if you want to use convolution algorithm,
%                    otherwise FFT algorithm will be used

% Thomas Dippon, Keysight Technologies 2011-2017
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

arbConfig = [];
normalize = 1;
fpoints = 256;
useConvolution = 0;
chMap = [];
nowarning = 0;
atRateCorrection = 0;
i = 1;
while (i <= nargin - 2)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'arbconfig';      arbConfig = varargin{i+1};
            case 'normalize';      normalize = varargin{i+1};
            case 'useconvolution'; useConvolution = varargin{i+1};
            case 'nowarning';      nowarning = varargin{i+1};
            case {'chmap' 'channelmapping'}; chMap = varargin{i+1};
            case 'atratecorrection'; atRateCorrection = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

% read correction from default location
    [cplxCorr, perChannelCorr, acs] = readCorr();
    % if absolute magnitude correction is used, do not normalize
    if (isfield(acs, 'absMagnitude') && acs.absMagnitude)
        absMagnitude = 1;
        normalize = 0;
%         if (~isempty(ampCorr))
%             ampCorr(:,2) = ampCorr(:,2) - acs.absMagnitude;
%             if (size(ampCorr, 2) > 2)
%                 ampCorr(:,3) = ampCorr(:,3) / 10^(acs.absMagnitude/20);
%             end
%         end
%         if (~isempty(perChannelCorr))
%             for i = 2:size(perChannelCorr, 2)
%                 perChannelCorr(:,i) = perChannelCorr(:,i) / 10^(acs.absMagnitude/20);
%             end
%         end
    else
        absMagnitude = 0;
    end
    % if input waveform is empty, simply return the correction vector (e.g. for display purposes)
    % ampCorr and perChannelCorr have embed, de-embed, do-not-use, cut-off, smoothing already applied.
    % perChannelCorr includes S-parameter corrections.
    if (isempty(iqdata))
        if (isfield(acs, 'AWGChannels') && exist('chMap', 'var') && ~isempty(chMap))
            if (~isvector(acs.AWGChannels) || length(acs.AWGChannels) ~= size(perChannelCorr, 2) - 1)
                errordlg('invalid AWGChannels field in correction file');
                acs.AWGChannels = 1:(size(perChannelCorr, 2) - 1);
            end
            [~, chMapNew] = iqsplitchan(zeros(1, size(chMap, 2) / 2), chMap);
            pidx = zeros(1, size(chMap, 2));
            % now, apply perChannel correction
            for col = 1:size(chMapNew,2)
                % find the channel in this column
                chs = find(chMapNew(:,col), 1);
                if (~isempty(chs))
                    % index into perChannelCorr that matches the desired channel
                    p = find(acs.AWGChannels == chs, 1);
                    if (isempty(p))
                        if (~nowarning)
                            warndlg(sprintf('No frequency/phase response correction data available for channel %d', chs), 'Warning', 'replace');
                        end
                    else
                        pidx(col) = p + 1;
                    end
                end
            end
            % the calling function will need at least an I/Q pair
            if (pidx(2) == 0); pidx(2) = pidx(1); end
            if (pidx(1) == 0); pidx(1) = pidx(2); end
        else
            % legacy mode: use first and second entry
            pidx = [2 3];
            if (size(perChannelCorr, 2) < 3)
                pidx(2) = 2;
            end
        end
        varargout{1} = cplxCorr;
        varargout{2} = perChannelCorr;
        if (nargout >= 3)
            varargout{3} = acs;
        end
        if (nargout >= 4)
            varargout{4} = pidx;
        end
        return;
    end
    % make sure the data is in the correct format (each signal is a column)
    if (size(iqdata,1) < size(iqdata,2))
        iqdata = iqdata.';
    end
    % set the algorithm used for applying corrections. For very long
    % waveforms, convolution is faster than FFT
    if ((exist('useConvolution', 'var') && useConvolution ~= 0) || length(iqdata) > 32000000)
        applyCorr = @applyCONVcorr;
    else
        applyCorr = @applyFFTcorr;
    end
    
    % apply complex correction if it exists
    if (isempty(cplxCorr) || (size(cplxCorr, 1) == 2 && cplxCorr(1,3) == 1 && cplxCorr(2,3) == 1))
        iqresult = iqdata;
    else
        % apply complex correction for non-interleaved signals only
        if (isfield(arbConfig, 'interleaving') && arbConfig.interleaving)
            iqresult = iqdata;
        else
            iqresult = applyCorr(iqdata, fs, cplxCorr(:,1), cplxCorr(:,3), fpoints);
        end
    end
    % if per-channel correction exists, apply it as well
    if (~isempty(perChannelCorr))
        if (isfield(arbConfig, 'interleaving') && arbConfig.interleaving)
            fs = fs / 2;
            iqresult = real(iqresult(:,1));                             % take the real signal
            iqresult = complex(iqresult(1:2:end), iqresult(2:2:end));   % and demux it into real & imaginary, so that correction are applied individually
        end
        if (isfield(acs, 'AWGChannels') && exist('chMap', 'var') && ~isempty(chMap))
            % new style: AWGChannels is included
            if (~isvector(acs.AWGChannels) || length(acs.AWGChannels) ~= size(perChannelCorr, 2) - 1)
                errordlg('invalid AWGChannels field in correction file');
                acs.AWGChannels = 1:(size(perChannelCorr, 2) - 1);
            end
            [iqsplit, chMapNew] = iqsplitchan(iqresult, chMap);
            % now, apply perChannel correction
            for col = 1:size(chMapNew,2)
                % find the channel in this column
                chs = find(chMapNew(:,col), 1);
                if (~isempty(chs))
                    % index into perChannelCorr that matches the desired channel
                    p = find(acs.AWGChannels == chs, 1);
                    if (isempty(p))
                        if (~nowarning)
                            warndlg(sprintf('No frequency/phase response correction data available for channel %d', chs), 'Warning', 'replace');
                        end
                    else
                        % special case: at-rate correction
                        if atRateCorrection
                            sel = 1 ;       % sel = 1 -> TDECQ equalizer algo | sel = 2 -> classical insystem cal correction, but with modification that phase at Nyquist is set to zero  
                            if sel == 1
                                % V1 (TDECQ equalizer)
                                freqVec = perChannelCorr(:,1) ;
                                Correction = 1./perChannelCorr(:,1+p) ;       % per channel correction is inverted measured response

                                fs_sinc = acs.SampleRate;
                                Correction = Correction./sinc(freqVec/fs_sinc);

                                % Parameters
                                OSR = 32 ;
                                dF = 100e6;
                                fmax = 2/3*fs; % to ensure integer divide ratio
%                                 fmax = 4/5*fs; % to ensure integer divide ratio
                                FreqR = (dF:dF:fmax) ;
                                tapsPerBit = 1 ; 
                                bitRate = fs;

                                numTaps = 64;
                                preCursors = 4 ;
                                ptsPerBit = 32;
                                length_pattern = numTaps*2 ;

                                BT = 0.7 * length_pattern / ptsPerBit    ; % 3-dB bandwidth-symbol time of Gaussian filter

                                mag_measured = abs(Correction);
                                phase_measured = unwrap(angle(Correction));

                                mag_interp = interp1(freqVec, mag_measured, FreqR);
                                phase_interp = interp1(freqVec, phase_measured, FreqR);

                                mag_interp(isnan(mag_interp)) = 0 ;
                                phase_interp(isnan(phase_interp)) = 0 ;

                                Correction_Interpolated = mag_interp.*exp(1j*phase_interp);

                                Correction_Interpolated(end) = NotComplex(Correction_Interpolated(end) );
                                Correction_Interpolated = [1,Correction_Interpolated];
                                FreqR = [0 , FreqR];
                                Correction_Interpolated_DSB = [Correction_Interpolated , fliplr(conj(Correction_Interpolated(2:end-1)))];


                                IR = real(ifft(Correction_Interpolated_DSB));
                                IR = circshift(IR, round(length(IR)/2));
                                Time = (0:length(IR)-1)/max(FreqR*2);

                                % V4 sinc interpolation to 32-times
                                % oversampled time grid
                                impXInc_Interpolated = (Time(2)-Time(1)); 

                                t1 = (0:length(IR)-1) * impXInc_Interpolated;

                                playtime_t1 = impXInc_Interpolated*length(t1);
                                delta_t2 = 1/fs/OSR;
                                length_t2 = round(playtime_t1/delta_t2);

                                t2 = (0:length_t2-1) * delta_t2;

                                for i = 1:length(t2)
                                    impInterp_sinc(i) = sum(IR.*sinc((t2(i)-t1)/impXInc_Interpolated));
                                end
                                impInterp_sinc = impInterp_sinc/sum(impInterp_sinc);


                                % Gaussian filter
                                h = gaussdesign(BT,ptsPerBit,length_pattern);

                                targetResponse_Gaussian_freq =  (0:length(h)-1)/length(h)*bitRate*ptsPerBit;
                                targetResponse_Gaussian = fft(h);

                                impulseResponseLPF = h' ;
                                impLPFXInc = 1/bitRate*ptsPerBit;


                                targetResponse_Freq = targetResponse_Gaussian_freq;
                                targetResponse = targetResponse_Gaussian;

                               [taps, ~] = Taps(numTaps, tapsPerBit, impInterp_sinc', delta_t2, impulseResponseLPF, impLPFXInc, bitRate, preCursors);

                                perChannelCorrFinal = fft(taps);
                                freqVec = (0:length(taps)-1)'/length(taps)*fs;
                                
%                                 dt = -0.2e-12;
                                
%                                 perChannelCorrFinal = perChannelCorrFinal.*exp(-1j*2*pi*freqTabs*dt);
                            end
                            if sel == 2
                                freqVec = perChannelCorr(:,1) ;
                                perChannelCorrFinal = perChannelCorr(:,1+p) ;
                                
                                fs_sinc = acs.SampleRate;
                                perChannelCorrFinal = perChannelCorrFinal.*sinc(freqVec/fs_sinc);
                                
                                phaseAtNyquist = interp1(freqVec, angle(perChannelCorrFinal), fs/2);
                                dt = phaseAtNyquist/(2*pi*fs/2);
                                phaseAtNyquist_deg = phaseAtNyquist*360/2/pi;
%                                 figure ; plot(freqVec, angle(perChannelCorrFinal));
%                                 figure ; plot(freqVec, angle(perChannelCorrFinal)*360/2/pi);
%                                 dt = dt +400e-15;
                                
                                perChannelCorrFinal = perChannelCorrFinal(freqVec < fs/2);
                                freqVec = freqVec(freqVec < fs/2);
                                
%                                 figure ; subplot(2,1,1);
%                                 plot(freqVec, 20*log10(abs(perChannelCorrFinal)));
%                                 subplot(2,1,2) ; hold all ;
%                                 plot(freqVec, unwrap(angle(perChannelCorrFinal)))

                                % apply constant delay (lin. phase) to set
                                % delay at Nyquist to zero
                                perChannelCorrFinal  = perChannelCorrFinal.*exp(1j*2*pi*freqVec*dt) ;    
                                
%                                 plot(freqVec, unwrap(angle(perChannelCorrFinal)));
                                
                                % Experimental : try pulse shaping (not
                                % working)
                                
                                ptsPerBit = 1;
                                length_pattern = 64 ; 
                                BT = 0.3 * length_pattern / ptsPerBit    ; % 3-dB bandwidth-symbol time of Gaussian filter
                                h = gaussdesign(BT,ptsPerBit,length_pattern);
                                figure ; plot(20*log10(abs(fft(h))))
                                targetResponse_Gaussian_freq =  (0:length(h)-1)/length(h)*bitRate*ptsPerBit;
                                targetResponse_Gaussian = fft(h);

                                impulseResponseLPF = h' ;
                                
                                
                            end
                            iqsplit(:,col) = applyCorr(iqsplit(:,col), fs, freqVec, perChannelCorrFinal, fpoints);
                        else
                            iqsplit(:,col) = applyCorr(iqsplit(:,col), fs, perChannelCorr(:,1), perChannelCorr(:,1+p), fpoints);
                        end
                    end
                end
            end
            % and finally, combine back into complex vectors
            iqresult = complex(real(iqsplit(:,1:2:size(iqsplit,2))), real(iqsplit(:,2:2:size(iqsplit,2))));
            % and use the new channel map
            chMap = chMapNew;
        else
            % legacy mode (no AWGChannels field or no chMap): use columns 2+3 for I+Q
            ires = real(applyCorr(real(iqresult(:,1)), fs, perChannelCorr(:,1), perChannelCorr(:,2), fpoints));
            if (isreal(iqresult))
                iqresult = ires;
            else
                if (size(perChannelCorr,2) >= 3)
                    qres = real(applyCorr(imag(iqresult(:,1)), fs, perChannelCorr(:,1), perChannelCorr(:,3), fpoints));
                else
                    qres = real(applyCorr(imag(iqresult(:,1)), fs, perChannelCorr(:,1), perChannelCorr(:,2), fpoints));
                end
                iqresult = complex(ires, qres);
            end
        end
        % interleaving mode: mux back to original shape
        if (isfield(arbConfig, 'interleaving') && arbConfig.interleaving)
             dacData(1,:) = real(iqresult);
             dacData(2,:) = imag(iqresult);
             iqresult = dacData(:);
        end
    end
    
    % apply non-linear corrections 
    if (isfield(acs, 'nonLinCorr') && isfield(acs.nonLinCorr, 'ampDepPhaseCorr') && acs.nonLinCorr.ampDepPhaseCorr ~= 0)
        % Apply amplitude-dependent phase correction.
        % Parameters are: exponent, ampDepPhase, absPhase and gain
        % Calibration routine is t.b.d.
        %
        % For M8195A at 1 V amplitude, 13 GHz center, try the following parameters
        % acs.nonLinCorr.exponent = 1.0;
        % acs.nonLinCorr.ampDepPhase = 1.0;
        % acs.nonLinCorr.absPhase = 0;
        % acs.nonLinCorr.gain = 0.24;
        % acs.nonLinCorr.ampDepPhaseCorr = 1;
        %
        % For M8195A at 0.5 V amplitude, 13 GHz center, try the following parameters
        % acs.nonLinCorr.exponent = 1;
        % acs.nonLinCorr.ampDepPhase = 0.28;
        % acs.nonLinCorr.absPhase = 0;
        % acs.nonLinCorr.gain = 0;
        % acs.nonLinCorr.ampDepPhaseCorr = 1;

        pow = abs(iqresult).^2;
        pow = pow / max(pow);
        pow = pow .^ acs.nonLinCorr.exponent;
        phi = acs.nonLinCorr.ampDepPhase .* pow - acs.nonLinCorr.absPhase;
        gain = 1 + (acs.nonLinCorr.gain .* pow);
        iqresult = iqresult .* gain .* exp(1i*phi);
        fprintf('Remark: Experimental non-linear correction is enabled \n'); 
    end
    
    % normalize
    if (normalize)
        scale = max(max(max(abs(real(iqresult))), max(abs(imag(iqresult)))));
        iqresult = iqresult ./ scale;
    end
%     if (absMagnitude && scale > 1)
%         warndlg(sprintf(['Absolute Magnitude can''t be achieved. ' ...
%             'Please increase Magnitude Shift in Correction Management window ' ...
%             'by at least %.1f dB.'], 20*log10(scale)), 'Warning', 'replace');
%     end
    if (nargout >= 1)
        varargout{1} = iqresult;
    end
    if (nargout >= 2)
        varargout{2} = chMap;
    end
end


function [ampCorr, perChannelCorr] = applySmoothing(ampCorr, perChannelCorr, smoothing)
    smoothing = round(smoothing);
    if (~isempty(ampCorr))
        for i = 3:2:size(ampCorr, 2)
            if (exist('smooth', 'file'))
                fmag = smooth(20*log10(abs(ampCorr(:,i))), smoothing, 'rlowess');
                fphase = smooth(unwrap(angle(ampCorr(:,i))), smoothing, 'rlowess');
            else
                fmagRS = resample(20*log10(abs(ampCorr(:,i))), 1, smoothing);
                fphaseRS = resample(unwrap(angle(ampCorr(:,i))), 1, smoothing);

                fmag = (interp1(1:smoothing:length(ampCorr(:,1)), fmagRS, 1:length(ampCorr(:,1)), 'spline'));
                fphase = (interp1(1:smoothing:length(ampCorr(:,1)), fphaseRS, 1:length(ampCorr(:,1)), 'spline'));
            end
            ampCorr(:,i-1) = fmag;
            ampCorr(:,i) = 10.^(fmag/20) .* exp(1i * fphase);
        end
    end
    if (~isempty(perChannelCorr))
        for i = 2:size(perChannelCorr, 2)
            if (exist('smooth', 'file'))
                fmag = smooth(20*log10(abs(perChannelCorr(:,i))), smoothing, 'rlowess');
                fphase = smooth(unwrap(angle(perChannelCorr(:,i))), smoothing, 'rlowess');
            else
                fmagRS = resample(20*log10(abs(perChannelCorr(:,i))), 1, smoothing);
                fphaseRS = resample(unwrap(angle(perChannelCorr(:,i))),1, smoothing);

                fmag = (interp1(1:smoothing:length(perChannelCorr(:,1)),fmagRS, 1:length(perChannelCorr(:,1)), 'spline'));
                fphase = (interp1(1:smoothing:length(perChannelCorr(:,1)),fphaseRS, 1:length(perChannelCorr(:,1)), 'spline'));
            end
            perChannelCorr(:,i) = 10.^(fmag/20) .* exp(1i * fphase);
        end
    end
end


% FFT algorithm for frequency/phase correction
function iqresult = applyFFTcorr(iqdata, fs, freq, cplxCorr, ~)
    % for operation outside of first Nyquist band, shift the frequency axis
    % this only applies if corrections are within one Nyquist band
%    if (max(freq) - min(freq) < fs/2)
        band = round(sum(freq) / length(freq) / fs);
%    else
%        band = 0;
%    end
    if (band ~= 0)
        freq = freq - band * fs;
    end
    % if we don't have negative frequencies, mirror them
    if (min(freq) >= 0)
        if (freq(1) == 0)  % don't duplicate zero-frequency
            startIdx = 2;
        else
            startIdx = 1;
        end
        freq = [-1 * flipud(freq); freq(startIdx:end)];
        cplxCorr = [conj(flipud(cplxCorr)); cplxCorr(startIdx:end,:)]; % negative side must use complex conjugate
    end
    % extend the frequency span to +/- fs/2, use the first, resp. last correction value
    if (freq(1) > -fs/2)
        freq     = [-fs/2;        freq];
        cplxCorr = [ cplxCorr(1); cplxCorr];
    end
    if (freq(end) < fs/2)
        freq     = [freq;     fs/2];
        cplxCorr = [cplxCorr; cplxCorr(end)];
    end
    % convert signal to frequency domain
    fdata = fftshift(fft(iqdata));
    % determine frequency points
    points = length(fdata);
    newFreq = linspace(-0.5, 0.5-1/points, points)' * fs;
    % interpolate the correction curve to match the data
    % interpolating complex values does not quite deliver the correct
    % result. It is better to interpolate mag & phase independently
    %corrLin = interp1(freq, cplxCorr, newFreq, 'linear', 1);
    mag = abs(cplxCorr);
    ph = unwrap(angle(cplxCorr));
    newMag = interp1(freq, mag, newFreq, 'linear');
    newPh = interp1(freq, ph, newFreq, 'linear');
    corrLin = newMag .* exp(1i * newPh);
    % apply the correction and convert back to time domain
    iqresult = ifft(fftshift(fdata .* corrLin));
end


function iqresult = applyCONVcorr(iqdata, fs, freq, cplxCorr, fpoints)
% convolution algorithm for frequency/phase correction
    ldspacing = ceil(log2(fs/fpoints / min(diff(freq))));
    % make sure the frequency interval is at least as "fine" as in the
    % amplitude correction file
    if (ldspacing > 0)
        fpoints = fpoints * 2^ldspacing;
    end
    % if the frequency values are above 1st Nyquist, move them down
    if (min(freq) >= fs && max(freq) <= 3*fs/2)     % 3rd Nyquist
        freq = freq - fs;
    end
    if (min(freq) >= fs/2 && max(freq) <= fs)       % 2nd Nyquist
        freq = fs - freq;
        freq = flipud(freq);
        cplxCorr = conj(flipud(cplxCorr));
    end
    % if the amplitude correction files consists of only positive
    % frequencies, assume the same frequency response for negative side
    % if we don't have negative frequencies, mirror them
    if (min(freq) >= 0)
        if (freq(1) == 0)            % don't duplicate zero-frequency
            startIdx = 2;
        else
            startIdx = 1;
        end
        freq = [-1 * flipud(freq); freq(startIdx:end)];
        cplxCorr = [conj(flipud(cplxCorr)); cplxCorr(startIdx:end)];
    end
    % extend the frequency span to +/- fs/2, use the first, resp. last correction value
    if (freq(1) > -fs/2)
        freq     = [-fs/2;        freq];
        cplxCorr = [ cplxCorr(1); cplxCorr];
    end
    if (freq(end) < fs/2)
        freq     = [freq;     fs/2];
        cplxCorr = [cplxCorr; cplxCorr(end)];
    end
    % create a vector of equally spaced frequencies and associated magnitudes
    newfreq = linspace(-fs/2, fs/2 - fs/fpoints, fpoints);
    % interpolate the correction at the new, equidistant frequency points
    % interpolating complex values does not quite deliver the correct
    % result. It is better to interpolate mag & phase independently
%--- old:  newCorr = interp1(freq, cplxCorr, newfreq, 'linear');
    mag = abs(cplxCorr);
    ph = unwrap(angle(cplxCorr));
    newMag = interp1(freq, mag, newfreq, 'linear');
    newPh = interp1(freq, ph, newfreq, 'linear');
    %%%
% TESTING: set undefined frequencies to zero correction
%     newMag(newfreq < -freq(end-1)) = 0;
%     newMag(newfreq > freq(end-1)) = 0;
%     newPh(newfreq < -freq(end-1)) = 0;
%     newPh(newfreq > freq(end-1)) = 0;
    %%%
    newCorr = newMag .* exp(1i * newPh);
    %... and derive a filter using inverse FFT
    ampFilt = fftshift(ifft(fftshift(newCorr)));
    % apply the filter to the signal with wrap-around to assure phase continuity
    len = length(iqdata);
    nfilt = length(ampFilt);
    wrappedIQ = [iqdata(end-mod(nfilt,len)+1:end); repmat(iqdata, 2*floor(nfilt/len)+1, 1); iqdata(1:mod(nfilt,len))];
    tmp = filter(ampFilt, 1, wrappedIQ);
    iqresult = tmp(nfilt+1:nfilt+len);
end


% read the frequency/phase correction from the "ampCorr.mat" file
% returns complex corrections and perChannel corrections.
% cplxCorr is an array with three columns: freq, amplitude in dB, complex
% correction
% perChannelCorr is an array with n+1 columns. First column is frequency
% remaining columns are complex frequency response correction for n
% channels (typically, n=2 for I and Q)
function [cplxCorr, perChannelCorr, acs] = readCorr()
cplxCorr = [];
perChannelCorr = [];
acs = [];
try
    acs = load(iqampCorrFilename());
catch
end
try
%     if (isempty(acs) || ~isfield(acs, 'ampCorr'))   % no correction file at all
%         acs.ampCorr = [0 0 1; 1e9 0 1];
%     end
    if (~isfield(acs, 'sparamCutoff') || ~isreal(acs.sparamCutoff) || acs.sparamCutoff < 0)
        acs.sparamCutoff = 0;       % no cut-off frequency
    end
    if (isfield(acs, 'ampCorr') && ismatrix(acs.ampCorr) && size(acs.ampCorr,1) >= 2 && size(acs.ampCorr,2) >= 2)
        cplxCorr = acs.ampCorr;
    end
    if (~isfield(acs, 'ampCorrMode'))
        acs.ampCorrMode = -1;   % old stype: de-embed
    end
    if (~isempty(cplxCorr))
        if (size(cplxCorr, 2) <= 2)  % no complex correction available
            cplxCorr(:,3) = 10.^(cplxCorr(:,2)/20);
        end
        if (acs.ampCorrMode == 1)
            cplxCorr(:,3) = conj(cplxCorr(:,3));
            cplxCorr(:,2) = -1 * cplxCorr(:,2);
        elseif (acs.ampCorrMode == 0)
            cplxCorr(:,3) = ones(size(cplxCorr, 1), 1);
            cplxCorr(:,2) = zeros(size(cplxCorr, 1), 1);
        end
    end
    % check is we have perChannel corrections
    if (isfield(acs, 'perChannelCorr') && ismatrix(acs.perChannelCorr))
        perChannelCorr = acs.perChannelCorr;
    end
    % check if we use S-Parameter files
    spCorr = readSPfiles(acs);
    % check if any sparameter files are there
    if (size(spCorr, 2) > 0)
        % make sure we have the same number of channels in perChannelCorr
        % and S-parameter corrections
        while (size(spCorr, 2) < size(perChannelCorr, 2) - 1)
            spCorr{size(spCorr, 2) + 1} = spCorr{size(spCorr, 2)};
        end
        if (~isempty(perChannelCorr))
            freq = perChannelCorr(:,1);
        else
            freq = [];
        end
        % frequency list is a union of all perChannelCorr frequency and
        % sparamter frequencies
        for i = 1:size(spCorr, 2)
            if (~isempty(spCorr{i}))
                freq = union(round(freq), round(spCorr{i}(:,1)));
            end
        end
        % just in case...
        freq = sort(freq);
        % extend perChannelCorr left and right with flat response
        pci = perChannelCorr;
        if (~isempty(pci))
            pci = [[min(freq)-1; pci(:,1); max(freq)+1] [pci(1,2:end); pci(:,2:end); pci(end,2:end)]];
        end
        if (~isempty(freq))
            % create new correction array
            perChannelCorr = zeros(length(freq), 1 + size(spCorr, 2));
            perChannelCorr(:,1) = freq;
            % calculate combined correction for each channel
            for i = 1:size(spCorr, 2)
                spi = spCorr{i};
                if (isempty(spi))
                    spi = [freq ones(length(freq),1)];
                end
                % extend with the last value left and right
                spi = [[min(freq)-1; spi(:,1); max(freq)+1] [spi(1,2); spi(:,2); spi(end,2)]];
                spNew = interp1(spi(:,1), spi(:,2), freq, 'linear');
                % check if we have a perChannelCorr for this channel
                if (size(pci, 2) - 1 >= i)
                    pcNew = interp1(pci(:,1), pci(:,i+1), freq, 'linear');
                    % new correction is the product of both
                    perChannelCorr(:,i+1) = spNew .* pcNew;
                else
                    % otherwise, use the Sparameter correction for this channel
                    perChannelCorr(:,i+1) = spNew;
                end
            end
        end
    end
    
    % apply cutoff frequency
    if (acs.sparamCutoff ~= 0)
        if (~isempty(cplxCorr))
            idx = abs(cplxCorr(:,1)) > acs.sparamCutoff;
            cplxCorr(idx,:) = [];
        end
        if (~isempty(perChannelCorr))
            idx = abs(perChannelCorr(:,1)) > acs.sparamCutoff;
            perChannelCorr(idx,:) = [];
        end
    end
    
    % apply smoothing
    if (isfield(acs, 'smoothing') && acs.smoothing ~= 0)
        [cplxCorr, perChannelCorr] = applySmoothing(cplxCorr, perChannelCorr, acs.smoothing);
    end

    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    end
end


function spCorr = readSPfiles(acs)
% read the Sparameter files and return a cell array of complex correction
% structures (arrays with 1st column freq, 2nd column complex correction)
    if (isfield(acs, 'sparamFile'))
        if (ischar(acs.sparamFile))
            acs.sparamFile = { acs.sparamFile }; % old style - only one filename
        end
        if (iscell(acs.sparamFile))
            spCorr = cell(1,size(acs.sparamFile, 2));
            if (isfield(acs, 'sparamMode') && acs.sparamMode ~= 0) % use it?
                for i = 1:size(acs.sparamFile, 2)
                    if (isfield(acs, 'sparamRemoveSkew'))
                        if (i <= length(acs.sparamRemoveSkew))
                            removeSkew = acs.sparamRemoveSkew(i);
                        else
                            removeSkew = acs.sparamRemoveSkew(end);
                        end
                    else
                        removeSkew = 0;
                    end
                    if (isfield(acs, 'sparamWeight'))
                        if (i <= length(acs.sparamWeight))
                            weight = acs.sparamWeight(i);
                        else
                            weight = acs.sparamWeight(end);
                        end
                    else
                        weight = 1;
                    end
                    % one mode for all channels
                    if (i <= length(acs.sparamMode))
                        mode = acs.sparamMode(i);
                    else
                        mode = acs.sparamMode(end);
                    end
                    if (i <= size(acs.selectedSParam, 1))
                        selectedSParam = acs.selectedSParam(i,:);
                    else
                        selectedSParam = acs.selectedSParam(end,:);
                    end
                    spCorr{i} = readSParamFile(acs.sparamFile{i}, mode, selectedSParam, removeSkew, weight, 0);
                end
            end
        else
            errordlg('sparamFile field must be string or cell');
            spCorr = cell(1,0);
        end
    else
        spCorr = cell(1,0);
    end
end


% read an S-parameter file (s2p, s4p, s6p) and convert the selected
% S-Parameter into the "internal" format
% sparamFile - full pathname of S-parameter file
% sparamMode - 0=don't use, 1=embed, -1=de-embed
% selectedSParam - vector with 2 elements, e.g. [2 1] --> S21
% removeSkew - if set to 1, removes linear phase
% mirror - mirror to negative frequencies
% returns 3-column array with columns = frequency, mag(dB), complex corr
function cplxCorr = readSParamFile(sparamFile, sparamMode, selectedSParam, removeSkew, weight, mirror)
cplxCorr = [];
if (isempty(sparamFile))
    return;
end
try
    %sp = reads4p(sparamFile);
    sp = rfdata.data;
    sp = read(sp, sparamFile);
catch ex
    errordlg({'Error reading ' sparamFile ' ' ex.message});
    return;
end
freq = sp.Freq;
corr = squeeze(sp.S_Parameters(selectedSParam(1), selectedSParam(2), :));
if (removeSkew)
    mag = abs(corr);
    phi = unwrap(angle(corr));
    % fit a straight line
    pf = polyfit(freq/1e6, phi, 1);
    % do not shift it - just change the angle
    if (abs(pf(2)) > 30/180*pi)
        warndlg('Phase at DC does not converge to zero. Please check the consistency of the S-parameter file', 'Warning', 'replace');
    end
    pf(2) = 0;
    phi = phi - polyval(pf, freq/1e6);
    corr = mag .* exp(1i * phi);
end
if (weight ~= 1)
    % apply weight separately to magnitude & phase
    % (log magnitude is multiplied by weight, hence linear magnitude must
    % be raised to the power of weight)
    mag = abs(corr) .^ weight;
    phi = unwrap(angle(corr)) .* weight;
    corr = mag .* exp(1i * phi);
end
if (mirror)
    % assume the same behaviour for positive & negative frequencies
    if (freq(1) == 0)            % don't duplicate zero-frequency
        startIdx = 2;
    else
        startIdx = 1;
    end
    freq = [-1 * flipud(freq); freq(startIdx:end)];
    corr = [conj(flipud(corr)); corr(startIdx:end)]; % negative side must use complex conjugate
end
cplxCorr = zeros(length(freq), 2);
cplxCorr(:,1) = freq;
switch sparamMode
    case 1
        cplxCorr(:,2) = corr;
    case -1
        cplxCorr(:,2) = 1 ./ corr;
    case 0
        cplxCorr(:,2) = ones(size(corr));
    otherwise
        error('unexpected embedding mode');
end
end

%% TDECQ equalizer from FlexDCA
function [taps, times] = Taps(numTaps, tapsPerBit, impulse, impXInc, target, targetXInc, bitRate, preCursors )


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % Condition the impulse
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    % Find the peak
    peakIdx = find(impulse == max(impulse));
    % Remove any offset
    impulse = impulse - mean(impulse(1:round(peakIdx/2)));
    % Truncate, precursors UI before, (#taps-precursors) UI after
    UIpts = round(1 / bitRate / impXInc);
    % impulse = impulse((peakIdx - preCursors * UIpts):(peakIdx + (numTaps-preCursors) * UIpts));
    impulse = impulse((peakIdx - preCursors * UIpts):(peakIdx + numTaps * UIpts));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % Create the ideal and measured sequences
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % Random sequence of 100 symbols
    Nsymbols = 2*numTaps;
    sequence = randi([0,3],1,Nsymbols);
    % Sample at 32 samples/bit
    ptsPerBit = 32;
    XInc = 1 / bitRate / ptsPerBit;
    pattern = zeros(1, length(sequence)*ptsPerBit);
    for i = 0:(length(pattern)-1)
        pattern(i+1) = sequence(1 + floor(i / ptsPerBit));
    end


    % Find the peak
    peakIdx = find(target == max(target));
    % Remove any offset
    target = target - mean(target(1:round(peakIdx/2)));
    % Truncate, precursors UI before, (#taps-precursors) UI after
    UIpts = round(1 / bitRate / impXInc);
    % target = target((peakIdx - preCursors * UIpts):(peakIdx + (numTaps-preCursors) * UIpts));
    target = target((peakIdx - preCursors * UIpts):(peakIdx + numTaps * UIpts));


    t1 = (0:length(target)-1) * targetXInc;
    t2 = (1:floor(t1(end) / targetXInc)) * targetXInc;
    target_interp = interp1(t1, target, t2);
    target_interp = target_interp / sum(target_interp);
    ideal = cconv(target_interp(:), pattern(:), length(pattern));
    ideal = ideal - mean(ideal);

    % Measured
    t1 = (0:length(impulse)-1) * impXInc;
    t2 = (1:floor(t1(end) / XInc)) * XInc;
    imp = interp1(t1, impulse, t2);
    imp = imp / sum(imp);
    meas = cconv(imp(:), pattern(:), length(pattern));
    meas = meas - mean(meas);

    % Align
    xc = cconv(ideal-mean(ideal), meas(end:-1:1)-mean(meas),length(meas));
    [~,lag] = max(xc);
    meas = circshift(meas,lag);

    % Solve at various alignments
    bestTaps = [];
    bestSirc = [];
    bestTau = [];
    bestErr = inf;

    tau = 1.0 / bitRate / tapsPerBit;
    ptsPerTau = round(ptsPerBit / tapsPerBit);
    for k = -ptsPerBit/2:ptsPerBit/2

        offset = preCursors * ptsPerBit + k;
   
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        % Come up with a set of linear equations, one for each bit
        % y(t) = a1*x(t) + a2*x(t-tau) + a3*x(t-2*tau) ...
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        Xmatrix = zeros(length(ideal), numTaps);
        for i = 1:length(ideal)
            for tap = (0:numTaps-1)
                prevValueIdx = mod(offset + i - round(ptsPerTau * tap) - 1, length(meas)) + 1;
                Xmatrix(i, tap+1) = meas(prevValueIdx);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        % Now just solve the over-constrained set of equations
        % using the backslash operator, which will to least-
        % squares regression.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        taps = Xmatrix \ ideal;
        sirc = Xmatrix * taps;

        % Track the best one
        err = std(sirc-ideal);
        if (err < bestErr)
            bestTaps = taps;
            bestSirc = sirc;
            bestErr = err;
            bestTau = tau;
        end
    end

    taps = bestTaps / sum(bestTaps);
    sirc = bestSirc;

    times = (0:numTaps-1) * bestTau;

end

function  MagWithSignAry = NotComplex( ComplexAry )

% Force a complex number to be real, but with the same magnitude.
% Allow negative magnitude.

  % size() returns the number if elements in each dimension.
  % !@$!# MatLab treats one dimensional arrays as though they are 2-D arrays
 
  DimList = size(ComplexAry);
  N_Dims = size(DimList,2);
  
  if N_Dims <= 2
    [N_Rows, N_Cols] = size(ComplexAry);
    for Row = N_Rows :-1: 1
      for Col = N_Cols :-1: 1
%       MagWithSignAry(Row,Col) = abs(ComplexAry(Row,Col));
        MagWithSignAry(Row,Col) = sign( real(ComplexAry(Row,Col)) ) * ...
                                         abs(ComplexAry(Row,Col)  );
      end
    end 
  
  elseif N_Dims == 3
    [N_D3, N_Rows, N_Cols] = size(ComplexAry);
    for D3 = N_D3 :-1: 1
      for Row = N_Rows :-1: 1
        for Col = N_Cols :-1: 1
%         MagWithSignAry(D3,Row,Col) = abs(ComplexAry(D3,Row,Col));
          MagWithSignAry(D3,Row,Col) = sign( real(ComplexAry(D3,Row,Col)) ) * ...
                                              abs(ComplexAry(D3,Row,Col)  );
        end
      end
    end
    
  elseif N_Dims == 4
    [N_D4, N_D3, N_Rows, N_Cols] = size(ComplexAry);
    for D4 = N_D4 :-1: 1
      for D3 = N_D3 :-1: 1
        for Row = N_Rows :-1: 1
          for Col = N_Cols :-1: 1
%           MagWithSignAry(D4,D3,Row,Col) = abs(ComplexAry(D4,D3,Row,Col));
            MagWithSignAry(D4,D3,Row,Col) = sign( real(ComplexAry(D4,D3,Row,Col)) ) * ...
                                                   abs(ComplexAry(D4,D3,Row,Col)  );
          end
        end
      end
    end
    
  else
    %('*** Error in *s, %g dimensions not supported',mfilename,N_Dims);
  end

  
end  
