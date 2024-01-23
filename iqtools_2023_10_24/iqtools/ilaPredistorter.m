% ilaPredistorter - Synthesizes a pre-distortion filter based on the
% Volterra series.
%
% pdFilter = ilaPredistorter(waveIn, coefficients, options) computes a
%   pre-distortion filter pdFilter which is approximately the inverse of the 
%   Volterra system nlSystem (as obtained from the function nlSynthesizer).
%
% pdFilter = ilaPredistorter(waveIn, [], options) computes a
%   pre-distortion filter pdFilter, where the Volterra system is loaded 
%   from file by setting options.loadKernel to true and specifying the 
%   file in the parameter options.loadKernelFile.
%
% Indirect Learning Architecture (ILA)
%
%              _____ sigDist[n] __________
%  sigIn[n]-->| DPD |----.---->| Volterra |--.-->sigOut[n]
%    (X)       -----  (Y)|      ----------   |     (Z)
%                      + | -z[n] _____       |
%                        +<-----| DPD |------'
%                      = |       --^--
%                        |_________|
%                           e[n]
%
% This function computes a predistorter for a given Volterra system by 
% using an indirect learning architecture. It is assumed that by 
% minimization of e[n] the difference between sigIn and sigOut will also 
% become small. Note that the Volterra filters in DPD are equal and can
% be of desired complexity. 
% Once the adaptation loop has run through and if the filter coefficients 
% converged properly, the returned predistorting filter pdFilter can be 
% used for predistorting the provided Volterra system.
% 
% Input parameters:
%   - waveIn:   Vector of samples that contains the stimulating signal for
%               the ILA.
%   - coefficients: Structure that contains information about the
%                   distorting Volterra system
%   - options.gain: Gain factor in the feedback path. Can be seen as 
%                   additional gain/loss factor, that allows to stay in the 
%                   'invertible' regime of the nonlinear system.
%   - options.memory: Defines the memory of each Volterra kernel for the 
%                     pre-distortion filter.
%   - options.withDc: Toggle 0th order Volterra kernel in pre-distortion
%                     filter.
%   - options.vis.learning.active: Display a visualizer for the learning 
%                                  curve of the algorithm. 
%   - options.vis.learning.nFigure: Defines the figure number for the
%                                   visualizer.
%   - options.lambda: Parameter of the RLS algorithm that defines accuracy 
%                     and invertibility. Should be close to, but smaller than one.
%   - options.delta: Parameter of the RLS algorithm that defines convergence 
%                    speed. Increase value for faster convergence.
%
%   Please refer to the user manual for further information.
%
%   Version 1.2
%
%   Copyright 2019 Fraunhofer Institute for Telecommunications
%   Heinrich Hertz Institute
%   All rights reserved.

function pdFilter = ilaPredistorter(waveIn, coefficients, options)

%% Parameter checks

validateattributes(waveIn, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'vector', 'column', 'real'}, 'ilaPredistorter', 'waveIn');
validateattributes(options, {'struct'},{'scalar'}, 'ilaPredistorter', 'options');
validateattributes(options.memory, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'vector', 'real', 'integer', 'nonnegative'}, 'ilaPredistorter', 'options.memory')
validateattributes(options.gain, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'positive'}, 'ilaPredistorter', 'options.gain')
validateattributes(options.lambda, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'positive','<',1}, 'ilaPredistorter', 'options.lambda')
validateattributes(options.delta, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive'}, 'ilaPredistorter', 'options.delta')
if isfield(options, 'withDc')
    validateattributes(options.withDc, {'logical'},{'scalar', 'finite'}, 'ilaPredistorter', 'options.withDc');
else
    options.withDc = true;
end
if isfield(options, 'saveKernel')
    validateattributes(options.saveKernel, {'logical'},{'scalar', 'finite'}, 'ilaPredistorter', 'options.saveKernel');
else
    options.saveKernel = false;
end
if isfield(options, 'loadKernel')
    validateattributes(options.loadKernel, {'logical'},{'scalar', 'finite'}, 'ilaPredistorter', 'options.loadKernel');
else
    options.loadKernel = false;
end
if isempty(coefficients) && options.loadKernel
    if isfield(options, 'loadKernelFile')
        validateattributes(options.loadKernelFile, {'char'}, {'nonempty'}, 'ilaPredistorter', 'options.loadKernelFile');
    else
        error('ilaPredistorter: No file specified. Parameter options.loadKernelFile not found.')
    end
    load(options.loadKernelFile);
end
% visualizer parameter checks
if isfield(options, 'vis')
    validateattributes(options.vis, {'struct'},{'scalar'}, 'ilaPredistorter', 'options.vis');
else
    options.vis = struct;
end
if isfield(options.vis, 'learning')
    validateattributes(options.vis.learning, {'struct'},{'scalar'}, 'ilaPredistorter', 'options.vis.learning');
else
    options.vis.learning = struct;
end
if isfield(options.vis.learning, 'active')
    validateattributes(options.vis.learning.active, {'logical'},{'scalar', 'finite'}, 'ilaPredistorter', 'options.vis.learning.active');
else
    options.vis.learning.active = false;
end
% check input structure containing the Volterra kernel coefficients
validateattributes(coefficients, {'struct'}, {'nonempty'}, 'coefficients');
validateattributes(coefficients.mIn, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real'}, 'ilaPredistorter', 'coefficients.mIn')
validateattributes(coefficients.mOut, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real'}, 'ilaPredistorter', 'coefficients.mOut')
validateattributes(coefficients.stdIn, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'nonzero'}, 'ilaPredistorter', 'coefficients.stdIn')
validateattributes(coefficients.stdOut, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'nonzero'}, 'ilaPredistorter', 'coefficients.stdOut')
validateattributes(coefficients.memory, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'vector', 'real', 'integer', 'nonnegative'}, 'ilaPredistorter', 'coefficients.memory')
validateattributes(coefficients.kernel, {'cell'}, {'nonempty', 'vector', 'numel', length(coefficients.memory)+1},'ilaPredistorter' , 'coefficients.kernel');
for iKernel = 1:length(coefficients.memory)+1
    validateattributes(coefficients.kernel{iKernel}, {'numeric'}, {'nonnan', 'finite', 'column', 'real'}, 'ilaPredistorter', ['coefficients.kernel{',num2str(iKernel),'}'])
    if (iKernel ~= 1) && (coefficients.memory(iKernel-1) > 0)
        if numel(coefficients.kernel{iKernel}) ~= nchoosek(iKernel-1+coefficients.memory(iKernel-1)-1,coefficients.memory(iKernel-1)-1)
            error(['The number of kernel coefficients in the kernel of order ', num2str(iKernel-1), ' does not correspond to its memory length.'])
        end
    end
end

%% Initialize parameters

nSamples = length(waveIn); % number of samples contained in input waveform
% pre-distortion kernel parameters
nPdKernel = getNumberOfKernel(options.memory); % number of coefficients in pre-distortion kernels
pdWinLen = max(options.memory); % maximum memory of pre-distortion kernel
if options.withDc
    pdTotKernel = sum(nPdKernel)+1; % total number of kernel coefficients contained in pre-distortion kernels
else
    pdTotKernel = sum(nPdKernel); % total number of kernel coefficients contained in pre-distortion kernels
end
pdDelay = ceil(pdWinLen/2)-1;
% nonlinear system kernel parameters
nSysKernel = getNumberOfKernel(coefficients.memory); % number of coefficients in nonlinear system kernels
sysWinLen = max(coefficients.memory); % maximum memory of nonlinear system kernel
sysDelay = ceil(sysWinLen/2)-1;
% RLS parameters
delta = options.delta*eye(pdTotKernel); % delta matrix for RLS


%% Waveform preparation

% Create indices of Volterra kernel coefficients for pre-distortion
pdIdcs = arrayfun(@(a,b) volterraIndices(a,b), 1:length(options.memory), options.memory, 'uniformOutput', false);
% Create indices of Volterra kernel coefficients for nonlinear system
sysIdcs = arrayfun(@(a,b) volterraIndices(a,b), 1:length(coefficients.memory), coefficients.memory, 'uniformOutput', false);
% Normalize input waveform according to nonlinear system
waveIn = (waveIn-coefficients.mOut)/coefficients.stdOut;
% Create expanded matrix from input waveform in order to prepare
% fast Volterra filtering by matrix multiplication
expWaveIn = expandInput(waveIn, options.memory, pdIdcs);
% Initilialize vector containing the Volterra coefficients for
% pre-distortion
pdKerVec = zeros(pdTotKernel, 1);
if options.withDc
    pdKerVec(ceil(options.memory(1)/2) + 1) = 1;
else
    pdKerVec(ceil(options.memory(1)/2)) = 1;
    expWaveIn = expWaveIn(:, 2:end);
end
% Initilialize vector containing the Volterra coefficients for
% nonlinear system
sysKerVec = cell2mat(coefficients.kernel.');
% Initialize windowed intermediate and output waveforms
waveIntWin = zeros(1, sysWinLen);
waveOutWin = zeros(1, pdWinLen);
% Initialize intermediate and output waveforms 
waveInt = zeros(nSamples, 1);
waveOut = zeros(nSamples, 1);
% Initialize error vector
err = zeros(nSamples, 1);

%% RLS loop

for iSample = 1:nSamples-(sysWinLen+pdWinLen-1)
    % Circshift intermediate waveform and append newest sample
    waveIntWin = circshift(waveIntWin, [0 1]);
    waveIntWin(1) = expWaveIn(iSample, :)*pdKerVec; % filter input waveform with current pre-distortion filter prototype
    waveInt(iSample) = waveIntWin(1);
    
    % Create expanded vector from intermediate waveform 
    waveIntExp = expandVector(waveIntWin, coefficients.memory, sysIdcs, nSysKernel);
    
    % Circshift output vector and append newest sample
    waveOutWin = circshift(waveOutWin, [0 1]);
    % Filter intermediate signal and compute newest output sample
    waveOutWin(1) = waveIntExp*sysKerVec/options.gain; % filter intermediate waveform with nonlinear system model
    waveOut(iSample) = waveOutWin(1);
    
    if iSample > (pdDelay+sysDelay)
        if options.withDc
            % Create expanded vector from output waveform 
            waveOutExp = expandVector(waveOutWin, options.memory, pdIdcs, nPdKernel);
        else
            % Create expanded vector from output waveform
            waveOutExp = expandVectorNoDc(waveOutWin, options.memory, pdIdcs, nPdKernel);
        end
        % Filter output signal by current pre-distortion prototype filter and compute error signal
        err(iSample) = waveInt(iSample-pdDelay-sysDelay) - waveOutExp*pdKerVec;
        
        % Compute new set of filter coefficients for pre-distortion
        % prototype filter
        const = (delta * waveOutExp.' / options.lambda)/(1 + waveOutExp * delta * waveOutExp.' / options.lambda);
        delta = (delta - const * (waveOutExp * delta)) / options.lambda;                
        pdKerVec = pdKerVec + const*err(iSample);
    end
end

% Rearrange kernel to a more convenient shape
kernel = cell(1,length(options.memory)+1);
if options.withDc
    kernel{1} = pdKerVec(1);
    start = 2;
else
    kernel{1} = 0;
    start = 1;
end
% loop over Volterra orders
for iOrder = 1:length(options.memory)
    if options.memory(iOrder) > 0
        nElements = size(pdIdcs{iOrder}, 1);
        kernel{iOrder+1} = pdKerVec(start:start+nElements-1);
        start = start+nElements;
    end
end

% Initialize output structure containing the pre-distortion Volterra
% kernels
sysStruct = coefficients;
clear coefficients;
coefficients.kernel = kernel;
coefficients.memory = options.memory;
coefficients.stdIn = sysStruct.stdOut;
coefficients.mIn = sysStruct.mOut;
coefficients.stdOut = sysStruct.stdIn;
coefficients.mOut = sysStruct.mIn;
pdFilter = coefficients;

% Save pre-distortion Volterra kernel structure to file
if options.saveKernel
    % parameter checks
    if isfield(options, 'saveKernelFile')
        validateattributes(options.saveKernelFile, {'char'}, {'nonempty'}, 'ilaPredistorter', 'options.saveKernelFile');
    else
        error('ilaPredistorter: No save file specified. Parameter options.saveKernelFile not found.')
    end
    try
        save(options.saveKernelFile, 'coefficients')
    catch 
        error(['ilaPredistorter: Cannot save kernel to file: ' options.saveKernelFile])
    end
end

%% Visualizer

if options.vis.learning.active
    if isfield(options.vis.learning, 'nFigure')
        validateattributes(options.vis.learning.nFigure, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive'}, 'ilaPredistorter', 'options.vis.learning.nFigure');
    else
        options.vis.learning.nFigure = 1;
    end
    hAxes = findobj('Tag', 'ila:learningCurve');
    if isempty(hAxes)
        figure(options.vis.learning.nFigure)
        semilogy(abs(err/coefficients.stdIn).^2); hold on
        semilogy(conv(abs(err/coefficients.stdIn).^2, ones(1,50)/50, 'valid'), 'Color', 'g'); hold off
        title('Learning curve of the ILA')
        xlabel('sample index')
        ylabel('squared error')
    else
        axes(hAxes)
        cla;
        line(1:length(err), abs(err/coefficients.stdIn).^2)
        c = conv(abs(err/coefficients.stdIn).^2, ones(1,50)/50, 'valid');
        line(1:length(c), c, 'Color', 'g')
    end
    legend('error signal', 'error signal (50 samples moving average)')
end

%% Helper functions

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

    % Create expanded vector when 0th order Volterra kernel (DC) is not considered 
    function sigExp = expandVectorNoDc(sig, memory, idcs, nKernel)
        nCopies = max(memory);
        refIdcs = -fix((memory-1)/2);
        forwardShifts = -fix((nCopies-1)/2);
        sigExp = ones(1, sum(nKernel));
        colCntr = 1;
        % Loop over orders
        for i = 1:length(memory)
            if memory(i) > 0
                indices = idcs{i};
                % Then loop over each kernel, resulting in all combinations
                for k = 1:nKernel(i)
                    % Depending on the order, several cross products are necessary
                    for l = 1:i
                        sigExp(colCntr) = sigExp(colCntr).*sig(refIdcs(i) - forwardShifts + 1 + indices(k,l));
                    end
                    colCntr = colCntr + 1;
                end
            end
        end
    end

    % Create expanded vector when 0th order Volterra kernel (DC) is considered 
    function sigExp = expandVector(sig, memory, idcs, nKernel)
        nCopies = max(memory);
        refIdcs = -fix((memory-1)/2);
        forwardShifts = -fix((nCopies-1)/2);
        sigExp = ones(1, sum(nKernel)+1);
        colCntr = 2;
        % Loop over orders
        for i = 1:length(memory)
            if memory(i) > 0
                indices = idcs{i};
                % Then loop over each kernel, resulting in all combinations
                for k = 1:nKernel(i)
                    % Depending on the order, several cross products are necessary
                    for l = 1:i
                        sigExp(colCntr) = sigExp(colCntr).*sig(refIdcs(i) - forwardShifts + 1 + indices(k,l));
                    end
                    colCntr = colCntr + 1;
                end
            end
        end
    end

    % Create expanded matrix 
    function samplesOut = expandInput(samplesIn, mem, idcs)
        % Create shifted copies of the input sample sequence        
        nCopies = max(mem);
        refIdcs = -fix((mem-1)/2);
        forwardShifts = -fix((nCopies-1)/2);                % forward shifts
        backwardShifts =  fix(nCopies/2);                   % delayed copies
        sampleCell = cell(nCopies, 1);                      % initialize cell array containing shifted copies
        shifts = forwardShifts:backwardShifts;
        % Loop over all copies and fill cell array
        for m = 1:nCopies
            sampleCell{m} = circshift(samplesIn, shifts(m));
        end
        
        % Get number of kernel coefficients in each order and create empty input matrix
        invalidIdx = (mem <= 0);
        nKernel = cellfun(@(c) size(c,1), idcs);
        nKernel(invalidIdx) = 0;
        % Initialize output sample matrix
        samplesOut = ones(length(samplesIn), sum(nKernel)+1);
        
        colCntr = 2;
        % Loop over Volterra orders
        for i = 1:length(mem)
            if mem(i) > 0
                indices = idcs{i};
                % Loop over each kernel, resulting in all combinations
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
end
