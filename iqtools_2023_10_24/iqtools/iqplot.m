function iqplot(miq, sampleRate, varargin)
% plot I/Q time domain waveform, spectrum and spectrogram

% T.Dippon, Agilent Technologies 2011-2013, Keysight Technologies 2014-2023
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

if (~exist('sampleRate', 'var'))
    sampleRate = 1;
    freqStr = 'Frequency';
    timeStr = 'Samples';
else
    freqStr = 'Frequency (Hz)';
    timeStr = 'Time (s)';
end
figureList = [];
figureDx = 100;
figureDy = -100;
figNum = 1;
if (~isempty(find(strcmp(varargin, 'figure'), 1)))
    figNum = varargin{find(strcmp(varargin, 'figure'), 1) + 1};
end
if (size(miq,1) < size(miq,2))
    miq = miq.';
end
if (isempty(miq))
    return;
end
% just visualize the first column of the data - simply ignore additional
% "channels" for now. The user can always un-check some channels to
% visualize other channels
miq = miq(:,1);
points = length(miq);
origPoints = points;
maxpoints = 10000000;
if (points > maxpoints)
    miq = miq(1:maxpoints);
    points = maxpoints;
end
complexData = ~isreal(miq);
re = real(miq);
im = imag(miq);
if (isempty(miq))
    return;
end

%% plot I&Q timedomain signals
if (isempty(find(strcmp(varargin, 'no_timedomain'), 1)))
    f = figure(figNum);
    figureList(end+1) = f;
%    clf(gcf(), 'reset');
    set(gcf(),'Name','I/Q Waveform');
    n = points;
    t = linspace(0, (n-1) / sampleRate, n);
    if (complexData)
        data = [re(1:n) im(1:n)];
    else
        data = re(1:n);
    end
    if (max(t) < 1e-6)
        t = t * 1e9;
        timeStr = strrep(timeStr, '(s)', '(ns)');
    elseif (max(t) < 1e-3)
        t = t * 1e6;
        timeStr = strrep(timeStr, '(s)', '(us)');
    elseif (max(t) < 1)
        t = t * 1e3;
        timeStr = strrep(timeStr, '(s)', '(ms)');
    end
    plot(t, data, '.-');
    % set the y-limits to show 10% more than the waveform
    min_val = min(min(re), min(im));
    max_val = max(max(re), max(im));
    amp = (max_val - min_val) * 0.1;
    if (amp == 0)
        amp = 1;
    end
    ylim([min_val-amp max_val+amp]);
    if (complexData)
        leg = {['I (CF=' sprintf('%.1f', crest(re)) ' dB)'], ['Q (CF=' sprintf('%.1f', crest(im)) ' dB)']};
    else
        leg = {['Data (CF=' sprintf('%.1f', crest(re)) ' dB)']};
    end
    xlabel(timeStr);
    ylabel('AU');
    mrkIdx = find(strcmp(varargin, 'marker'));
    color = 'mcyg';
    if (~isempty(mrkIdx))
        marker = varargin{mrkIdx+1};
        if (~isempty(marker))
            for i=1:4       % max 4 markers will be displayed
                m = bitand(bitshift(floor(marker), -i+1), 1);
                if (~isempty(find(m(1:points), 1)))
                    hold on;
                    plot(t, m(1:points), color(i));
                    leg{end+1} = sprintf('Marker %d', i);
                end
            end
            hold off;
        end
    end
    grid on;
    legend(leg);
end

%% plot the spectrum of the I/Q waveform
% add a minimal amount of noise to avoid negative infinity in spectrum plot
if (isempty(find(strcmp(varargin, 'nospectrum'))))
    miq = awgn(miq, 300);
    faxis = linspace(sampleRate / -2, sampleRate / 2 - sampleRate / points, points);
    % if we have an odd number of points, need to shift freq. axis
    if (mod(points, 2) ~= 0)
        faxis = faxis + sampleRate / points / 2;
    end
    magnitude = 20 * log10(abs(fftshift(fft(miq/points))));

    if (~isempty(find(strcmp(varargin, 'smallspectrum'))))
        % show only the "interesting part" of the spectrum
        x1 = find(magnitude > -90, 1, 'first');
        x2 = find(magnitude > -90, 1, 'last');
        width = round((x2 - x1) * 0.1);
        if (width == 0)
            width = round(0.1 * points);
        end
        p1 = max(x1 - width, 1);
        p2 = min(x2 + width, points);
    else
        p1 = 1;
        p2 = points;
    end
    if (~complexData && p1 < points/2)
        p1 = round(points/2)+1;
    end
    f = figure(figNum+1);
    figureList(end+1) = f;
    set(gcf(),'Name','I/Q Spectrum');
    if (faxis(p2) >= 10e9)
        plot(faxis(p1:p2)/1e9, magnitude(p1:p2), '.-');
        xlabel(strrep(freqStr, 'Hz', 'GHz'));
    elseif (faxis(p2) >= 10e6)
        plot(faxis(p1:p2)/1e6, magnitude(p1:p2), '.-');
        xlabel(strrep(freqStr, 'Hz', 'MHz'));
    else
        plot(faxis(p1:p2), magnitude(p1:p2), '.-');
        xlabel(freqStr);
    end
    ylabel('dB');
    grid;
end

%% plot 3D-spectrogram
if (~isempty(find(strcmp(varargin, 'spectrogram'))))
    width = 512;                        % # of samples for the FFT
    numbins = 512;                      % number of time-slots
    n = min(maxpoints, points);
    if (n >= width)
        % prepend a few samples from the end to visualise the wrap-around
        % scale values to normalize FFT
        miqx = [miq(end-width:end); miq(1:n)] / width;
        data = zeros(numbins, width);
        for i = 1:numbins
            idx = round(1 + (i / numbins * n));
            data(i,:) = 20 * log10(abs(fftshift(fft(miqx(idx : idx + width - 1).' .* window(@blackmanharris, width)'))));
        end
        f = figure(figNum+2);
        figureList(end+1) = f;
        set(figNum+2,'Name','3D-Spectrogram');
        if (complexData)
            [x,y] = meshgrid(linspace(sampleRate / -2, sampleRate / 2, width), linspace(0 / sampleRate, (n+width) / sampleRate, numbins));
        else
            [x,y] = meshgrid(linspace(0, sampleRate / 2, width/2+1), linspace(0 / sampleRate, (n+width) / sampleRate, numbins));
            data = data(:,width/2:end);
        end
        c = data;
        m = max(max(c)) - 70;
        c(c < m) = m;
        if (faxis(p2) >= 10e9)
            surf(x/1e9, y, data, c, 'EdgeColor', 'none');
            xlabel(strrep(freqStr, 'Hz', 'GHz'));
        elseif (faxis(p2) >= 10e6)
            surf(x/1e6, y, data, c, 'EdgeColor', 'none');
            xlabel(strrep(freqStr, 'Hz', 'MHz'));
        else
            surf(x, y, data, c, 'EdgeColor', 'none');
            xlabel(freqStr);
        end
        ylabel(timeStr);
        zlabel('dB');
        view(0,90);
%        view(-36,76);
        colorbar;
    end
end

%% Constellation diagram
if (~isempty(find(strcmp(varargin, 'constellation'))))
    f = figure(figNum+3);
    figureList(end+1) = f;
    set(4, 'Name', 'Constellation');
    plot(miq);
end

%% Eye diagram
oversamplingIdx = find(strcmp(varargin, 'oversampling'));
if (~isempty(oversamplingIdx))
    oversampling = varargin{oversamplingIdx+1};
    f = figure(figNum+4);
    figureList(end+1) = f;
    iqeyeplot(miq, sampleRate, oversampling, 2, figNum+4);
end

%% plot CCDF
if (~isempty(find(strcmp(varargin, 'CCDF'), 1)))
    f = figure(figNum +5);
    figureList(end+1) = f;
    set(gcf(), 'Name','CCDF');
   % The CCDF Function plots the CCDF of the generated Waveform, along with
   % a Normally distributed Gausian CCDF curve for comparison
   %
   % PAPR = peak to average power ratio (crest factor)
   % CCDF = Complimentary Cumulative Distribution Function
   % re     real waveform vector
   % papr  vector of PAPR step values
   % y     CCDF of re and Gauss vs. papr
    
    papr = 0:.25:12; % dB vector of PAPR step values
    % get Waveform PAPR
    y_data_PAPRdB = crest(re(1:points));
        
    % create dB array from Waveform
    y_Power = re(1:points).^2;              % convert Waveform to power
    y_PowerRatio = y_Power/mean(y_Power);   % power/average power
    y_PowerdB = 10*log10(y_PowerRatio);     % Convert to dB
    
    for i = 1:length(papr)
        y_data(i) = length(find(y_PowerdB >= papr(i)))/points;     % Create y_data of Accumulated points crossing PAPR vector
    end
    % Generate a Random distributed waveform for comparison purposes
    % get PAPR of AWGN
    % Create CCDF of AWGN
    rng('default');                     % reset random number generator
    M = points;                         % number of samples same as generated Waveform
    x_gauss = randn(M,1);               % Create random data array
    Pratio = x_gauss.^2;                % power/average power ( AWGN average power = 1)
    AWGN_PdB = 10*log10(Pratio);        % AWGN waveform in dB
    AWGN_PAPRdB = crest(x_gauss);       % Determine PAPR of AWGN Waveform
    
    for i = 1:length(papr)
        y_gauss(i) = length(find( AWGN_PdB > papr(i)))/points;   % Create y_gauss of Accumulated points crossing PAPR vector
    end
    %Plot semi log of both generated Waveform and AWGN CCDF
    semilogy(papr,y_data,papr,y_gauss),grid
    xlabel('dB above average power'),ylabel('Probability (%)')
    title('CCDF'),axis([0 12 1e-5 1]) 
    
    if (complexData)
        leg = {['Data (PAPR=' sprintf('%.1f', y_data_PAPRdB) ' dB)'],['AWGN (PAPR=' sprintf('%.1f', AWGN_PAPRdB) ' dB)']};
    else
           leg = {['Data (PAPR=' sprintf('%.1f', y_data_PAPRdB) ' dB)'],['AWGN (PAPR=' sprintf('%.1f', AWGN_PAPRdB) ' dB)']};
    end
    legend(leg);
end

if (points < origPoints)
    warndlg(sprintf('For performance reasons only the first %d Msamples of the waveform are plotted', maxpoints/1e6));
end

% rearrange figures that are exactly on top of each other
for i = 1:length(figureList)-1
    fi = figureList(i);
    pi = get(fi, 'Position');
    for j = i+1:length(figureList)
        fj = figureList(j);
        pj = get(fj, 'Position');
        if (isequal(pi, pj))
            set(fj, 'Position', [pj(1)+figureDx, pj(2)+figureDy, pj(3), pj(4)]);
        end
    end
end
end


function crestdB = crest(v)
% calculate crest factor of a signal represented in v
% see http://en.wikipedia.org/wiki/Crest_factor
rms = norm(v) / sqrt(length(v));
peak = max(abs(v));
% linear crest factor
crest = peak / rms;
% crest factor in dB
crestdB = 20*log10(peak/rms);
end
