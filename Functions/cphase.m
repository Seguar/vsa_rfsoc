function [weights, fixed_rawData, cal_angs] = cphase(rawData, reference_ant)
% calibrates phases using FFT phase estimation
% takes the maximum of the abs value fo the FFT of the signal 
% and calcultes it's angle, then calcultes the right phase shift with 
% respect to the first rawData vector. 
%
% INPUTS:
% fixed_rawData: 4 X n raw signal matrix
%
% OUTPUTS:
% fixed_rawData: 4 X n aligned signal matrix  
% weights:       4 X 1 weights vector for phase alignement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
max_val = zeros(4,1);
max_idx = zeros(4,1);
for i=1:4
    rawFt = fftshift(fft(rawData(:,i)));
    [max_val(i), max_idx(i)] = max(rawFt);
end

angs = angle(max_val);
cal_angs = angs(reference_ant)-angs;

fixed_rawData(:,1) = rawData(:,1).*exp(1j*cal_angs(1));
fixed_rawData(:,2) = rawData(:,2).*exp(1j*cal_angs(2));
fixed_rawData(:,3) = rawData(:,3).*exp(1j*cal_angs(3));
fixed_rawData(:,4) = rawData(:,4).*exp(1j*cal_angs(4));
weights = exp(1j*cal_angs);
end