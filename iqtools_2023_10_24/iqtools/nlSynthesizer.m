% nlSynthesizer - Synthesizes a Volterra series from a sytem input and output.
%
%   coefficients = nlSynthesizer(waveIn, waveOut, options) estimates the 
%   Volterra kernel coefficients of order length(options.memory) from the 
%   system input waveform given by a vector waveIn and a system output 
%   waveform given by the vector waveOut. Both waveforms must be provided 
%   in the time-domain. The sample rates of input and output waveform need 
%   to be specified by the parameters options.samplerateIn and
%   options.samplerateOut, respectively. The integer vector options.memory 
%   contains the desired system memories of all considered orders.
%
%   The identified Volterra kernels and other relevant information can be
%   saved to a Matlab mat-file by setting the parameter options.saveKernel 
%   to true. The full path and filename is specified by the parameter
%   options.saveKernelFile.
%
%   There are three visualizers available.
%   (1) The synchronization visualizer displays the synchronization metric
%   between input and output waveform and the synchronized waveforms. The
%   visualizer can be turned on/off by setting the parameter
%   options.vis.sync.active to true/false.
%
%   (2) The signal visualizer displays the input and output waveforms as 
%   well as the emulated output waveform using the identified Volterra 
%   kernels. It also  displays the mean squared error (MSE) between output 
%   waveform and emulated output waveform. The visualizer can be turned 
%   on/off by setting the parameter options.vis.sig.active to true/false.
%
%   (3) The kernel visualizer displays the identified kernel coefficients 
%   up to third order. The visualizer can be turned on/off by setting the 
%   parameter options.vis.kernel.active to true/false.
%
%   Please refer to the user manual for further information.
%
%   Version 1.2 
%
%   Copyright 2019 Fraunhofer Institute for Telecommunications
%   Heinrich Hertz Institute
%   All rights reserved.

function coefficients = nlSynthesizer(waveIn, waveOut, options)

%% parameter checks

validateattributes(waveIn, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'vector', 'real'}, 'nlSynthesizer', 'waveIn');
validateattributes(waveOut, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'vector', 'real'}, 'nlSynthesizer', 'waveOut');
validateattributes(options, {'struct'},{'scalar'}, 'nlSynthesizer', 'options');
if isfield(options, 'memory') % Volterra kernel memory
    validateattributes(options.memory, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'vector', 'real', 'integer', 'nonnegative'}, 'nlSynthesizer', 'memory');
else
    error('nlSynthesizer: undefined field options.memory')
end
if isfield(options, 'resample')
    validateattributes(options.resample, {'logical'},{'scalar', 'finite'}, 'nlSynthesizer', 'options.resample');
else
    options.resample = false;
end
if isfield(options, 'synchronize')
    validateattributes(options.synchronize, {'logical'},{'scalar', 'finite'}, 'nlSynthesizer', 'options.synchronize');
else
    options.synchronize = false;
end
if isfield(options, 'saveKernel')
    validateattributes(options.saveKernel, {'logical'},{'scalar', 'finite'}, 'nlSynthesizer', 'options.saveKernel');
else
    options.saveKernel = false;
end
% Visualizer settings
if isfield(options, 'vis')
    validateattributes(options.vis, {'struct'},{'scalar'}, 'nlSynthesizer', 'options.vis');
else
    options.vis = struct;
end
% synchronization metric visualizer
if isfield(options.vis, 'sync')
    validateattributes(options.vis.sync, {'struct'},{'scalar'}, 'nlSynthesizer', 'options.vis.sync');
else
    options.vis.sync = struct;
end
if isfield(options.vis.sync, 'active')
    validateattributes(options.vis.sync.active, {'logical'},{'scalar', 'finite'}, 'nlSynthesizer', 'options.vis.sync.active');
else
    options.vis.sync.active = false;
end
% emulated output signal visualizer
if isfield(options.vis, 'sig')
    validateattributes(options.vis.sig, {'struct'},{'scalar'}, 'nlSynthesizer', 'options.vis.sig');
else
    options.vis.sig = struct;
end
if isfield(options.vis.sig, 'active')
    validateattributes(options.vis.sig.active, {'logical'},{'scalar', 'finite'}, 'nlSynthesizer', 'options.vis.sig.active');
else
    options.vis.sig.active = false;
end
% kernel visualizer
if isfield(options.vis, 'kernel')
    validateattributes(options.vis.kernel, {'struct'},{'scalar'}, 'nlSynthesizer', 'options.vis.kernel');
else
    options.vis.kernel = struct;
end
if isfield(options.vis.kernel, 'active')
    validateattributes(options.vis.kernel.active, {'logical'},{'scalar', 'finite'}, 'nlSynthesizer', 'options.vis.kernel.active');
else
    options.vis.kernel.active = false;
end


%% Signal preparation and synchronization

% Ensure that waveforms are column vectors
waveIn = waveIn(:);
waveOut = waveOut(:);
% Number of samples contained in input waveform
nSamplesIn = length(waveIn);

% Resample output waveform prior to synchronization
if options.resample
    % parameter checks
    if isfield(options, 'samplerateIn') % sample rate of the input waveform waveIn
        validateattributes(options.samplerateIn, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'positive'}, 'nlSynthesizer', 'samplerateIn');
    else
        error('nlSynthesizer: undefined field options.samplerateIn')
    end
    if isfield(options, 'samplerateOut') % sample rate of the output waveform waveOut
        validateattributes(options.samplerateOut, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'positive'}, 'nlSynthesizer', 'samplerateOut');
    else
        error('nlSynthesizer: undefined field options.samplerateOut')
    end
    if options.samplerateOut > options.samplerateIn
        % resampling of output waveform
        xfft = fft(waveOut, [], 1) .* (nSamplesIn/length(waveOut)); % Fourier transform of output waveform
        xfft = [xfft(1:ceil(nSamplesIn/2)); xfft(end-floor(nSamplesIn/2)+1:end)];
        
        if mod(nSamplesIn, 2) == 0
            % Correct power contained in Nyquist frequency
            xfft(ceil(nSamplesIn/2+1)) = 2*xfft(ceil(nSamplesIn/2+1));
        end
        waveOut = ifft(xfft, [], 1, 'symmetric'); % resampled time-domain waveform
    elseif options.samplerateOut < options.samplerateIn
        error('nlSynthesizer: The sample rate of the output waveform (%.4g Hz) needs to be larger or equal to the sample rate of the input waveform (%.4g Hz).', options.samplerateOut, options.samplerateIn)
    end
end

% check waveform size
nSamplesOut = length(waveOut);
if nSamplesIn > nSamplesOut
    error('nlSynthesizer: Output waveform needs to cover at least the same time window as the input waveform. Current time window durations are: input waveform: %.4g s (%d samples at %.4g Hz) and output waveform %.4g s (%d samples at %.4g Hz).', nSamplesIn/options.samplerateOut, nSamplesIn, options.samplerateOut, nSamplesOut/options.samplerateOut, nSamplesOut, options.samplerateOut)
end

if options.synchronize
    % synchronization cross-correlation metric
    xcorrResult = ifft( conj( fft( waveIn-mean(waveIn))) .* ...
        fft( waveOut(1:nSamplesIn)-mean(waveOut(1:nSamplesIn))));
    [~, idx]  = max(abs(xcorrResult));
    % Circshift input waveform according to maximum cross-correlation metric
    waveIn = circshift(waveIn, idx-1);
end

% Detect number of waveform repetitions in output waveform
nRepetitions = floor(nSamplesOut/nSamplesIn);
% Number of obsolete samples
nObsSamples = mod(nSamplesOut, nSamplesIn);
% Average output waveform over the number of waveform repetitions
waveOut = mean(reshape(waveOut(1:end-nObsSamples), nSamplesIn, nRepetitions), 2);

if length(waveIn) ~= length(waveOut)
    error('nlSynthesizer: number of samples in input waveform (%d) and output waveform (%d) should be equal.', length(waveIn), length(waveOut))
end

% Normalize waveforms to power of 1 for identification (more robust)
stdIn = std(waveIn);    % standard deviation of input waveform
mIn = mean(waveIn);     % mean of input waveform
waveIn = (waveIn-mIn)/stdIn;

stdOut = std(waveOut);  % standard deviation of output waveform
mOut = mean(waveOut);   % mean of output waveform
waveOut = (waveOut-mOut)/stdOut;

% Visualizer for synchronization metric and synchronized waveforms
if options.vis.sync.active && options.synchronize
    % parameter checks
    if isfield(options.vis.sync, 'nFigure')
        validateattributes(options.vis.sync.nFigure, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive'}, 'nlSynthesizer', 'options.vis.sync.nFigure');
    else
        options.vis.sync.nFigure = 1;
    end
    if isfield(options.vis.sync, 'startSample')
        validateattributes(options.vis.sync.startSample, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive', '<=', length(waveIn)-1}, 'nlSynthesizer', 'options.vis.sync.startSample');
    else
        options.vis.sync.startSample = 1;
    end
    if isfield(options.vis.sync, 'nSamples')
        validateattributes(options.vis.sync.nSamples, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive','<=', length(waveIn)-options.vis.sync.startSample+1, '>=', 2}, 'nlSynthesizer', 'options.vis.sync.nSamples');
    else
        options.vis.sync.nSamples = length(waveIn);
    end
    figure(options.vis.sync.nFigure)
    subplot(2,1,1)
    plot(abs(xcorrResult))
    xlabel('lag index')
    ylabel('cross-correlation [a.u.]')
    xlim([1 length(xcorrResult)])
    subplot(2,1,2)
    start = options.vis.sync.startSample;
    stop = start + options.vis.sync.nSamples - 1;
    plot(start:stop, waveIn(start:stop), 'Color', [0 0 0], 'LineWidth', 2); hold on
    plot(start:stop, waveOut(start:stop), 'Color', [0.2 0.4 0.9], 'LineWidth', 2, 'LineStyle', '--')
    hold off
    xlabel('sample index')
    ylabel('amplitude [a.u.]')
    xlim([start stop])
    title('Synchronized input and output signal')
    legend('Input signal', 'Output signal')
end

%% system identification by least squares algorithm 

% calculate number of kernel coefficients for each Volterra order depending
% on specified memories
[~, invalidIdcs] = getNumberOfKernel(options.memory);
orderVec = 1:length(options.memory); % Volterra orders
% initialize index cell array
idcs = cell(length(options.memory), 1); 
% create indices of Volterra kernel coefficients
idcs(~invalidIdcs) = arrayfun(@(a,b) volterraIndices(a,b), orderVec(~invalidIdcs), options.memory(~invalidIdcs), 'uniformOutput', false);
% create expanded matrix from input waveform in order to prepare
% calculation of kernel coefficients by pseudo-inverse
expWaveIn = expandInput(waveIn, options.memory, idcs);

kernelVec = pinv(expWaveIn)*waveOut; % calculate kernel coefficients by using the pseudo-inverse

%% Create output structure

% Rearrange kernel to a more convenient shape
kernel = cell(1,length(options.memory)+1);
kernel{1} = kernelVec(1);

% loop over Volterra orders
start = 2;
for p = 1:length(options.memory)
    if options.memory(p) > 0
        nElements = nchoosek(p+options.memory(p)-1,options.memory(p)-1);
        kernel{p+1} = kernelVec(start:start+nElements-1);
        start = start+nElements;
    else
        kernel{p+1} = zeros(0,1);
    end
end
% generate structure for saving and later use with nlEmulator.m
coefficients.kernel = kernel;
coefficients.memory = options.memory;
coefficients.stdIn = stdIn;
coefficients.mIn = mIn;
coefficients.stdOut = stdOut;
coefficients.mOut = mOut;

% save identified kernel information to file
if options.saveKernel
    % parameter checks
    if isfield(options, 'saveKernelFile')
        validateattributes(options.saveKernelFile, {'char'}, {'nonempty'}, 'nlSynthesizer', 'options.saveKernelFile');
    else
        error('nlSynthesizer: No save file specified. Parameter options.saveKernelFile not found.')
    end
    try
        save(options.saveKernelFile, 'coefficients')
    catch 
        error(['nlSynthesizer: Cannot save kernel to file: ' options.saveKernelFile])
    end
end


%% Visualizers

% Signal visualizer displaying original input waveform, output waveform and
% emulated output waveform
if options.vis.sig.active
    % parameter checks
    if isfield(options.vis.sig, 'nFigure')
        validateattributes(options.vis.sig.nFigure, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive'}, 'nlSynthesizer', 'options.vis.sig.nFigure');
    else
        options.vis.sig.nFigure = 2;
    end
    if isfield(options.vis.sig, 'startSample')
        validateattributes(options.vis.sig.startSample, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive', '<=', length(waveIn)-1}, 'nlSynthesizer', 'options.vis.sig.startSample');
    else
        options.vis.sig.startSample = 1;
    end
    if isfield(options.vis.sig, 'nSamples')
        validateattributes(options.vis.sig.nSamples, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive','<=', length(waveIn)-options.vis.sig.startSample+1, '>=', 2}, 'nlSynthesizer', 'options.vis.sig.nSamples');
    else
        options.vis.sig.nSamples = length(waveIn);
    end
    % initialize start and stop samples    
    start = options.vis.sig.startSample;
    stop = options.vis.sig.nSamples+start-1;
    % calculated emulated waveform from input waveform and identified
    % Volterra system
    waveEmul = expWaveIn*kernelVec;
    % calculate mean squared error between output waveform and emulated output waveform 
    mse = mean((waveOut-waveEmul).^2);
    % plot visualizer
    figure(options.vis.sig.nFigure)
    clf(options.vis.sig.nFigure)
    hold on
    plot(start:stop, waveIn(start:stop),'k-', 'LineWidth', 2); hold on
    plot(start:stop, waveOut(start:stop), 'LineWidth', 3)
    plot(start:stop, waveEmul(start:stop),':', 'LineWidth', 3)    
    hold off
    xlabel('sample index')
    ylabel('normalized signal amplitudes')
    title(['Identification results, MSE = ', num2str(mse)])
    legend('Input signal', 'Output signal', 'Output signal emulated')
    grid on
    box on
end

% Volterra kernel visualizer
if options.vis.kernel.active
    % parameter checks
    if isfield(options.vis.kernel, 'nFigure')
        validateattributes(options.vis.kernel.nFigure, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive'}, 'nlSynthesizer', 'options.vis.kernel.nFigure');
    else
        options.vis.kernel.nFigure = 3;
    end
    if isfield(options.vis.kernel, 'colorMap')
        validateattributes(options.vis.kernel.colorMap, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'real', 'nonnegative', '2d', 'ncols', 3, '>=', 0, '<=', 1}, 'nlSynthesizer', 'options.vis.kernel.nFigure');
    else
        options.vis.kernel.colorMap = jet(64);
    end
    options.vis.kernel.memory = options.memory;
    kernelVisualizer(kernel, options.vis.kernel) % use helper function for visualization
end

%% Helper functions
    
    % Calculates number of kernel coefficients for all specified memories of Volterra orders 
    function [nKernel, invalidIdcs] = getNumberOfKernel(mem)
        invalidIdcs = (mem <= 0);
        ord = 1:length(mem);
        ord(invalidIdcs) = 0;
        mem = mem-1;
        mem(invalidIdcs) = 0;
        nKernel = arrayfun(@(ord, mem) nchoosek(ord+mem, mem), ord, mem);
        nKernel(invalidIdcs) = 0;
    end

    % This function returns all Volterra kernel indices for a given order and
    % memory.
    function indices = volterraIndices(order, mem)
        validateattributes(order, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive'}, 'volterraIndices', 'order');
        validateattributes(mem, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive'}, 'volterraIndices', 'mem');
        % initialize matrix of indices        
        indices = zeros(nchoosek(order+mem-1, mem-1), order);
        
        % Loop over all matrix elements and build index matrix
        for i = 1:nchoosek(order+mem-1, mem-1)-1
            for pos = order:-1:1
                % update indices only if current index is below highest member of alphabet
                if indices(i, pos) < mem-1
                    indices(i+1,:) = indices(i,:);
                    indices(i+1, pos) = indices(i+1, pos)+1;
                    indices(i+1, pos:end) = indices(i+1, pos);
                    break;
                end
            end
        end
        
    end

    % Creates the input vector that is to be inverted for the usage of the LS
    % algorithm. The input sample sequence is assumed to be periodic.
    function samplesOut = expandInput(samplesIn, mem, idcs)
        % create shifted copies of the input sample sequence        
        nCopies = max(mem);
        refIdcs = -fix((mem-1)/2);
        forwardShifts = -fix((nCopies-1)/2);                % forward shifts
        backwardShifts =  fix(nCopies/2);                   % delayed copies
        sampleCell = cell(nCopies, 1);                      % initialize cell array containing shifted copies
        shifts = forwardShifts:backwardShifts;
        % loop over all copies and fill cell array
        for m = 1:nCopies
            sampleCell{m} = circshift(samplesIn, shifts(m));
        end
        
        % get number of kernel coefficients in each order and create empty input matrix
        invalidIdx = (mem <= 0);
        nKernel = cellfun(@(c) size(c,1), idcs);
        nKernel(invalidIdx) = 0;
        % initialize output sample matrix
        samplesOut = ones(length(samplesIn), sum(nKernel)+1);
        
        colCntr = 2;
        % loop over Volterra orders
        for i = 1:length(mem)
            if mem(i) > 0
                indices = idcs{i};
                % loop over each kernel, resulting in all combinations
                for k = 1:nKernel(i)
                    % Calculate cross products depending on Volterra order
                    for l = 1:i
                        samplesOut(:,colCntr) = samplesOut(:,colCntr).*sampleCell{refIdcs(i) - forwardShifts + 1 + indices(k,l)};
                    end
                    colCntr = colCntr + 1;
                end
            end
        end
    end

    
   % Visualize the Volterra kernel coefficients up to 3rd order 
   function kernelVisualizer(kernel, optional)
 
        figCntr = 0;
        % Loop over orders
        % Construct symmetric kernel matrix from out cell structured kernels in order to compute
        % the singular values of the matrices.
        for iOrder = 1:min(length(kernel)-1, 3)
            if optional.memory(iOrder) <= 0
                continue
            end
            
            idxold = volterraIndices(iOrder, optional.memory(iOrder))+1;
            
            for iIdxold = 1:size(idxold,1)
                nPermut = getNoOfPermutations(idxold(iIdxold, :));
                kernel{iOrder+1}(iIdxold) = kernel{iOrder+1}(iIdxold)/nPermut;
            end
            
            idxnew = allPermutations(iOrder, optional.memory(iOrder));
            idxnews = sort(idxnew, 2);
            
            [~, loco] = ismember(idxnews, idxold, 'rows');
            h = reshape(kernel{iOrder+1}(loco), optional.memory(iOrder), []);
            
            maxVal = max(max(abs(h)));
            if maxVal == 0
                maxVal = 1;
            end
            
            % Plot
            figure(optional.nFigure+figCntr);
            clf
            % case selection for each Volterra order
            switch iOrder
                case 1 % 1st order Volterra kernel
                    cmat = colormap(optional.colorMap);
                    cmati = round((h.'/maxVal+1)*(size(cmat,1)-1)/2)+1;
                    ccell = mat2cell(cmat(cmati,:), ones(length(h), 1), 3);
                    
                    hs = stem([0:length(h)-1;NaN(1,length(h))],[h.'/maxVal;NaN(1,length(h))]);
                    colorbar
                    caxis([-1 1])
                    set(hs, {'MarkerFaceColor'}, ccell, {'Color'}, ccell, 'LineWidth', 2)
          
                    xlabel('k_1')
                    ylabel('Magnitude')
                    grid on
                    
                case 2 % 2nd order Volterra kernel
                    imagesc(0:size(h,1)-1, 0:size(h,2)-1, h/maxVal);
                    
                    xlabel('k_1')
                    ylabel('k_2')
                    zlabel('Magnitude')
                    axis square
                    
                    colormap(optional.colorMap)
                    colorbar
                    caxis([-1 1])
                    
                case 3 % 3rd order Volterra kernel
                    % Sphere plot
                    center = idxnew;
                    
                    r = abs(h)/maxVal/2;
                    d = h/maxVal;
                    
                    hold on;
                    [xu,yu,zu] = sphere(10);
                    for iSphere = 1:size(center, 1)
                        x = xu*r(iSphere) + center(iSphere,1);
                        y = yu*r(iSphere) + center(iSphere,2);
                        z = zu*r(iSphere) + center(iSphere,3);
                        c = ones(size(z))*d(iSphere);
                        surf(x,y,z,c, 'EdgeColor', 'none');
                    end
                    hold off;
                    xlabel('k_1')
                    ylabel('k_2')
                    zlabel('k_3')
                    view(3);
                    axis equal;
                    grid on
                    
                    set(gca, 'YTick', 1:optional.memory(iOrder), 'YTickLabel', 0:optional.memory(iOrder)-1, ...
                        'XTick', 1:optional.memory(iOrder), 'XTickLabel', 0:optional.memory(iOrder)-1, ...
                        'ZTick', 1:optional.memory(iOrder), 'ZTickLabel', 0:optional.memory(iOrder)-1)
                    
                    xlim([0.5 optional.memory(iOrder)+0.5])
                    ylim([0.5 optional.memory(iOrder)+0.5])
                    zlim([0.5 optional.memory(iOrder)+0.5])
                    
                    colormap(optional.colorMap)
                    colorbar
                    caxis([-1 1])
            end
            % plot title
            str = ['kernel coefficients of order ', num2str(iOrder), ...
                ', scaled by ', num2str(1/maxVal, '%3.3g')];
            title(str)
            
            figCntr = figCntr + 1;
        end
        
        % calculate the number of possible permutations of a vector
        function nPermut = getNoOfPermutations(vec)
            nPermut = factorial(length(vec));
            for i = 0:max(vec)
                if i == 0
                    nPermut = nPermut/factorial(nnz(vec==i)+1);
                else
                    nPermut = nPermut/factorial(nnz(vec==i));
                end
            end
        end
        
        % calculate matrix containing all indices of a Volterra kernel of
        % a specified order and memory
        function indices = allPermutations(order, memory)
            % catch simple cases
            if memory==1
                indices = ones(1,order);
                return
            elseif order==1
                indices = (1:memory).';
                return
            end
            % build index matrix
            indices = zeros(memory^order,order); % initialize output matrix
            incMatrix =  repmat([-(memory-1); ones(memory-1, 1)], 1, memory^order/memory);   % Matrix containing increment values
            indices(:,order) = incMatrix(:);     % Initialize last column.
            indices(1:memory^(order-1):memory^order,1) = incMatrix(:,1); % Initialize first column.
            if order > 2
                % loop over columns of output index matrix
                for iColumn = 2:order-1
                    rowIndices = 1:memory^(iColumn-1):memory^order; % Row indices for update.
                    incMatrix = repmat([-(memory-1); ones(memory-1, 1)], 1, length(rowIndices)/memory); % Matrix containing increment values 
                    indices(rowIndices,order-iColumn+1) = incMatrix(:); % Update increment values in index matrix.
                end
            end
            indices(1,:) = 1; % replace (-memory-1) by 1.
            indices = cumsum(indices); % calculate output index matrix.
        end
    end

end
