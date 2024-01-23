function [ status ] = setModulationFrequency(  freqMod, mohawk  )
% setModulationFrequency.m - Sets Mohawk Output Modulation Frequency

% Rev.04 2018.06.25 Ed Barich 
%   Revised for FX3 Processor using SCIPI commands

% Rev.03 2018.06.25 Ed Barich 
%   Changed writes to LMX2571 to large blocks of data (Caleb's fix for
%   temperature reads interfering with synthesizer writes)

% setModulationFrequency.m REV.02    Ed Barich 2 June 2017
%   Revised for Mohawk PROTO2, using LMX2571 VCO/Synthesizer

% INPUTS:
%   freqMod: Mohawk Modulation Frequency [range:100KHz-100MHz] (Hz)
%   mohawk: mohawk object
% OUTPUTS:
%   status = *OPC? result

% Send SCIPI Commands to Mohawk:
fprintf(mohawk,[':COMB:FSP ' num2str(2*freqMod)]);   % Tone spacing is twice modulation frequency

% status = commandComplete(mohawk);    % Check for Command Complete (*OPC) status
fprintf(mohawk,'*OPC?');  % Command complete query
[status,count,msg] = fscanf(mohawk);    % Get query response

end

 