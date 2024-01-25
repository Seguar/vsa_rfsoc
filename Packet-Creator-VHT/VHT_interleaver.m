function [VHT_coded_inv_bits] = VHT_interleaver(VHT_coded_bits, N_cbps, N_bpsc,channelBW)

switch channelBW
    case 20
        N_col = 13;
        N_row = 4*N_bpsc;
        N_rot = 11; %MIMO
    case 40
        N_col = 18;
        N_row = 6*N_bpsc;
        N_rot = 29; %MIMO
    case 80
        N_col = 26;
        N_row = 9*N_bpsc;
        N_rot = 58; %MIMO
    case 160
        N_col = 26;
        N_row = 9*N_bpsc;
        N_rot = 58; %MIMO
        N_cbps = N_cbps/2;
end;
% First permutation
k = 0:N_cbps-1; % Original indexes
i = N_row.*mod(k,N_col) + floor(k./N_col); %First Interleaver

%Second step
s = max(N_bpsc/2,1);
j = s*floor(i./s) + mod(i + N_cbps - floor(N_col.*i/N_cbps),s);% Second Interleaver
VHT_coded_inv_bits(j+1) = VHT_coded_bits; % Bits Interleave
end