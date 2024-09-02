
% chX it's RX side capture of TX channels 1-4 and all together
% For example:RX ch1 = [TX ch1, TX ch2, TX ch3, TX ch4, TX all]
% chA it's summation from RX beamforming

%% EVM calculations
x = 20;
ch1 = [10, 12, 16, 15, 25];
ch2 = [14, 14, 15, 15, 26];
ch3 = [15, 14, 15, 15, 25];
ch4 = [18, 12, 13, 16, 25];
chA = [20, 17, 20, 20, 30];
evm_expected = x*log10(10.^(ch1/x) + 10.^(ch2/x) + 10.^(ch3/x) + 10.^(ch4/x));
diff_evm = chA - evm_expected
%% Power calculations
x = 20;
ch1 = [29, 29, 35, 32, 42];
ch2 = [30, 30, 35, 31, 43];
ch3 = [32, 30, 31, 31, 42];
ch4 = [35, 30, 30, 32, 43];
chA = [42, 41, 44, 42, 53];
power_expected = x*log10(10.^(ch1/x) + 10.^(ch2/x) + 10.^(ch3/x) + 10.^(ch4/x));
diff_power = chA - power_expected