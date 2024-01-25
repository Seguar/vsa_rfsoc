function [SIG_coded_inv_bits] = legacy_interleaver(SIG_coded_bits, N_cbps, N_bpsc)

% First permutation
k = 0:N_cbps-1; % Original indexes
i = (N_cbps/16).*mod(k,16) + floor(k./16); %First Interleaver

%Second step
s = max(N_bpsc/2,1);
j = s*floor(i./s) + mod(i + N_cbps - floor(16.*i/N_cbps),s);% Second Interleaver
SIG_coded_inv_bits(j+1) = SIG_coded_bits; % Bits Interleave
end
