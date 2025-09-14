function [y, w_opt, w_opt_vec] = adaptiveIQCompensation(x, M, w)
    % adaptiveIQCompensation - Compensates for IQ imbalance adaptively.
    %
    % Inputs:
    % x - Signal with IQ imbalance (complex vector)
    % M - Step size matrix (diagonal matrix of size NxN)
    % w - Initial weights vector (complex vector of size N)
    %
    % Outputs:
    % y - Compensated signal (complex vector)
    % w_opt - Optimal weights (complex vector)

    % Length of the input signal
    x = x.';
    N = length(w);
    y = zeros(size(x));
    w_opt = w;
    
    % Adaptive compensation loop
    for n = N:length(x)
        % n
        % Input vector including the conjugate term
        x_vec = x(n:-1:n-N+1).';
        
        % Calculate output using current weights
        y(n) = x(n) + w_opt.'* conj(x_vec);
        
        % Update weights adaptively.
        w_opt = w_opt - M * y(n:-1:n-N+1).' * (y(n));
        w_opt_vec(:,n) = w_opt;
    end
end