function state = updateEVMOscillogram(state, evmDb, maxPoints)
% updateEVMOscillogram
% Updates rolling EVM oscillogram with one already calculated EVM dB value.
%
% Inputs:
%   state     - plot/history state. Use [] on first call.
%   evmDb     - newest EVM value already in dB, for example -30
%   maxPoints - number of last points shown on graph, e.g. 10..50
%
% Output:
%   state     - updated state, pass it back on next call

    if nargin < 3
        maxPoints = 50;
    end

    if isempty(state)
        state.sampleCounter = 0;
        state.evmDbHistory = [];

        state.fig = figure('Name', 'Rolling EVM Oscillogram', ...
                           'NumberTitle', 'off');

        state.hPlot = plot(nan, nan, 'LineWidth', 1.5, 'Marker', '.');
        grid on;

        xlabel('Sample number');
        ylabel('EVM, dB');
        title(sprintf('Rolling EVM Oscillogram, last %d samples', maxPoints));

        xlim([1 maxPoints]);

        % -45 dB at the top, 0 dB at the bottom
        ylim([-45 0]);
        set(gca, 'YDir', 'reverse');
    end

    if ~ishandle(state.fig)
        return;
    end

    state.sampleCounter = state.sampleCounter + 1;

    % Save full dB history
    state.evmDbHistory(end + 1) = evmDb;

    % Display only last maxPoints values
    if length(state.evmDbHistory) > maxPoints
        yDisplay = state.evmDbHistory(end - maxPoints + 1:end);
        xDisplay = state.sampleCounter - length(yDisplay) + 1 : state.sampleCounter;
    else
        yDisplay = state.evmDbHistory;
        xDisplay = 1:length(yDisplay);
    end

    set(state.hPlot, ...
        'XData', xDisplay, ...
        'YData', yDisplay);

    % Rolling x-axis
    if state.sampleCounter > maxPoints
        xlim([state.sampleCounter - maxPoints + 1, state.sampleCounter]);
    else
        xlim([1 maxPoints]);
    end

    % Keep fixed reversed EVM axis
    ylim([-45 0]);
    set(gca, 'YDir', 'reverse');

    drawnow limitrate;

end