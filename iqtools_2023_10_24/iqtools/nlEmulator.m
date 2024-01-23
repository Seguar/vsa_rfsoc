%nlEmulator - Emulation of a nonlinear Volterra system.
%
%   waveOut = nlEmulator(waveIn, coefficients, options) filters a 
%   time-domain waveform waveIn by a nonlinear Volterra filter specified by 
%   the structure coefficients as obtained from the function nlSynthesizer. 
%   The distorted time-domain output waveform is returned in the column 
%   vector waveOut.
%
%   waveOut = nlEmulator(waveIn, [], options) allows to load the Volterra 
%   kernel coefficients from a Matlab mat-file by setting the parameter 
%   options.loadKernel to true. The full path and filename is specified by 
%   the parameter options.loadKernelFile.  
%
%   There is a visualizer available. The kernel visualizer displays the 
%   Volterra kernel coefficients used for filtering up to third order. 
%   The visualizer can be turned on/off by setting the parameter 
%   options.vis.kernel.active to true/false. The figure window number can
%   be controlled by the parameter options.vis.kernel.nFigure.
%
%   Please refer to the manual for further information.
%
%   Version 1.2
%
%   Copyright 2019 Fraunhofer Institute for Telecommunications
%   Heinrich Hertz Institute
%   All rights reserved.

function waveOut = nlEmulator(waveIn, coefficients, options)

%% Parameter checks

validateattributes(waveIn, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'vector', 'real'}, 'nlEmulator', 'waveIn');
if isfield(options, 'loadKernel')
    validateattributes(options.loadKernel, {'logical'},{'scalar', 'finite'}, 'nlEmulator', 'options.loadKernel');
else
    options.loadKernel = false;
end
if isempty(coefficients) && options.loadKernel
    if isfield(options, 'loadKernelFile')
        validateattributes(options.loadKernelFile, {'char'}, {'nonempty'}, 'nlEmulator', 'options.loadKernelFile');
    else
        error('nlEmulator: No file specified. Parameter options.loadKernelFile not found.')
    end
    load(options.loadKernelFile);
end
validateattributes(coefficients, {'struct'}, {'nonempty'}, 'coefficients');
validateattributes(coefficients.mIn, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real'}, 'nlEmulator', 'coefficients.mIn')
validateattributes(coefficients.mOut, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real'}, 'nlEmulator', 'coefficients.mOut')
validateattributes(coefficients.stdIn, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'nonzero'}, 'nlEmulator', 'coefficients.stdIn')
validateattributes(coefficients.stdOut, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'nonzero'}, 'nlEmulator', 'coefficients.stdOut')
validateattributes(coefficients.memory, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'vector', 'real', 'integer', 'nonnegative'}, 'nlEmulator', 'coefficients.memory')
validateattributes(coefficients.kernel, {'cell'}, {'nonempty', 'vector', 'numel', length(coefficients.memory)+1}, 'coefficients.kernel');
for iKernel = 1:length(coefficients.memory)+1
    validateattributes(coefficients.kernel{iKernel}, {'numeric'}, {'nonnan', 'finite', 'column', 'real'}, 'nlEmulator', ['coefficients.kernel{',num2str(iKernel),'}'])
    if (iKernel ~= 1) && (coefficients.memory(iKernel-1) > 0)
        if numel(coefficients.kernel{iKernel}) ~= nchoosek(iKernel-1+coefficients.memory(iKernel-1)-1,coefficients.memory(iKernel-1)-1)
            error(['The number of kernel coefficients in the kernel of order ', num2str(iKernel-1), ' does not correspond to its memory length.'])
        end
    end
end
% Kernel visualizer parameter checks
if isfield(options, 'vis')
    validateattributes(options.vis, {'struct'},{'scalar'}, 'nlSynthesizer', 'options.vis');
else
    options.vis = struct;
end
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

%% Waveform preparation

% Ensure that input waveform is a column vector
waveIn = waveIn(:);
% Normalize input waveform
waveIn = (waveIn-coefficients.mIn)/coefficients.stdIn;
% Calculate number of kernel coefficients for each Volterra order depending
% on specified memories
[~, invalidIdcs] = getNumberOfKernel(coefficients.memory);
orderVec = 1:length(coefficients.memory); % Volterra orders
% Initialize index cell array
idcs = cell(length(coefficients.memory), 1);
% Create indices of Volterra kernel coefficients
idcs(~invalidIdcs) = arrayfun(@(a,b) volterraIndices(a,b), orderVec(~invalidIdcs), coefficients.memory(~invalidIdcs), 'uniformOutput', false);
% Create expanded matrix from input waveform in order to prepare
% fast Volterra filtering by matrix multiplication
expWaveIn = expandInput(waveIn, coefficients.memory, idcs);
% Initilialize vector containing the Volterra coefficients
kernelVec = vertcat(coefficients.kernel{:});
% Volterra filter operation and normalization to the correct output units
waveOut = expWaveIn*kernelVec*coefficients.stdOut + coefficients.mOut;

%% Visualizer

% Volterra kernel visualizer
if options.vis.kernel.active
    % Parameter checks
    if isfield(options.vis.kernel, 'nFigure')
        validateattributes(options.vis.kernel.nFigure, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'scalar', 'real', 'integer', 'positive'}, 'nlSynthesizer', 'options.vis.kernel.nFigure');
    else
        options.vis.kernel.nFigure = 1;
    end
    if isfield(options.vis.kernel, 'colorMap')
        validateattributes(options.vis.kernel.colorMap, {'numeric'}, {'nonnan', 'finite', 'nonempty', 'real', 'nonnegative', '2d', 'ncols', 3, '>=', 0, '<=', 1}, 'nlSynthesizer', 'options.vis.kernel.nFigure');
    else
        options.vis.kernel.colorMap = jet(64);
    end
    options.vis.kernel.memory = coefficients.memory;
    kernelVisualizer(coefficients.kernel, options.vis.kernel)
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
        % Initialize matrix of indices        
        indices = zeros(nchoosek(order+mem-1, mem-1), order);
        
        % Loop over all matrix elements and build index matrix
        for i = 1:nchoosek(order+mem-1, mem-1)-1
            for pos = order:-1:1
                % Update indices only if current index is below highest member of alphabet
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

    % Visualize the Volterra kernel coefficients up to 3rd order 
   function kernelVisualizer(kernel, optional)
 
        figCntr = 0;
        % Loop over orders
        % Construct symmetric kernel matrix from cell structured kernels in order to compute
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
            % Case selection for each Volterra order
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
            % Display title
            str = ['kernel coefficients of order ', num2str(iOrder), ...
                ', scaled by ', num2str(1/maxVal, '%3.3g')];
            title(str)
            
            figCntr = figCntr + 1;
        end
        
        % Calculate the number of possible permutations of a vector
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
        
        % Calculate matrix containing all indices of a Volterra kernel of
        % a specified order and memory
        function indices = allPermutations(order, memory)
            % Catch simple cases
            if memory==1
                indices = ones(1,order);
                return
            elseif order==1
                indices = (1:memory).';
                return
            end
            % Build index matrix
            indices = zeros(memory^order,order); % initialize output matrix
            incMatrix =  repmat([-(memory-1); ones(memory-1, 1)], 1, memory^order/memory);   % matrix containing increment values
            indices(:,order) = incMatrix(:);     % initialize last column.
            indices(1:memory^(order-1):memory^order,1) = incMatrix(:,1); % Initialize first column.
            if order > 2
                % Loop over columns of output index matrix
                for iColumn = 2:order-1
                    rowIndices = 1:memory^(iColumn-1):memory^order; % row indices for update.
                    incMatrix = repmat([-(memory-1); ones(memory-1, 1)], 1, length(rowIndices)/memory); % Matrix containing increment values 
                    indices(rowIndices,order-iColumn+1) = incMatrix(:); % update increment values in index matrix.
                end
            end
            indices(1,:) = 1; % replace (-memory-1) by 1.
            indices = cumsum(indices); % calculate output index matrix.
        end
    end

end
