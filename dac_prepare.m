% Create IQtools signal with Fs=BW
% Resamble signal to 1 GHz SR with resample/fft
clear
% filename = '1000_100_short.mat';
% filename = 'ofdm100_1000.mat';
filename = 'o100_1000.mat';

load(filename)

dac_max = 2^14 - 1;
Y = Y/max(Y);
sigInt16 = zeros(1, length(Y)*2);
sigInt16(1:2:end) = real(Y)*(dac_max);
sigInt16(2:2:end) = imag(Y)*(dac_max);
sigInt16 = int16(sigInt16);
save(['int16_' filename])
save(['data.mat'])