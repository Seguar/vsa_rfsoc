function [ status,freqVco ] = setCenterFrequency(  freqCenter,mohawk,varargin  )
% setCenterFrequency.m - Sets Mohawk Output Center Frequency and Power Level

% Rev.09 2018.12.17 Ed Barich
%   Revised for FX3 Processor using SCIPI commands

% Rev.08 2018.07.30 Ed Barich
%   Derived from SetCenterFrequencyAndPower07.m
%   Added optional parameters AuxRfOutON and OutAPwr

% Rev.07 2018.06.25 Ed Barich 
%   Changed writes to LMX2594 to large blocks of data (Caleb's fix for
%   temperature reads interfering with synthesizer writes)

% Rev.06 2018.06.05 Ed Barich 
%   Changed freqDoublerMax to 21GHz

% Rev.05 2018.05.17 Ed Barich
%   MODIFIED FOR FX3 CONTROLLER

% REV.04 2018.05.01 Ed Barich
%   Added freqFund output parameter to this function.

% Rev.03 2018.04.30 Ed Barich
%   Changed freqDoublerMax from 70e9/3 to 3*freqVcoMin

% setCenterFrequencyAndPower    Ed Barich 2017.08.11
%   Derived from setCenterFrequency.m REV.02
%   Adds Output Power setting function

% REV.02    Ed Barich 2 June 2017
%   Revised for Mohawk PROTO2 using LMX2594 VCO/Synthesizer

% INPUTS:
%   freqCenter: Mohawk Output Center Frequency (Hz)
%   mohawk: mohawk object
% OPTIONAL Inputs:
%   AuxRfOutON: =0,AuxRfOut is OFF [default];=1,AuxRfOut is ON
%   OutAPwr:    LM2594 OutputA Power Level [default=31]
% OUTPUTS:
%   status = *OPC? result
%   freqVco = LMX2594 VCO frequency (7.5e9 to 15e9 Hz)

% Optional Input Parameters:
switch nargin
    case 3         % 3 input parameters
        AuxRfOutON = varargin{1};
        OutAPwr = 31;   % Default input value
    case 4         % 3 input parameters
        AuxRfOutON = varargin{1};
        OutAPwr = varargin{2};
    otherwise
        AuxRfOutON = 0; % Default input value
        OutAPwr = 31;   % Default input value
end

disp(['freqCenter = ' num2str(freqCenter)]);

fprintf(mohawk,[':FREQ ' num2str(freqCenter)]);   % Set Mohawk output center frequency

fprintf(mohawk,'*OPC?');  % Command complete query
[status,count,msg] = fscanf(mohawk);    % Get query response

fprintf(mohawk,[':SERV:AUX:OUTP ' num2str(AuxRfOutON)]);   % Set Auxilliary Output State

fprintf(mohawk,'*OPC?');  % Command complete query
[status,count,msg] = fscanf(mohawk);    % Get query response

% Calculate VCO Output Frequency:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

freqVcoMax = 15000e6;       % Maximum VCO output frequency (Hz)
freqVcoMin = 7500e6;        % Minimum VCO output frequency (Hz)
% freqDoublerMax = 3*freqVcoMin;      % Maximum Doubler output frequency (Hz)
freqDoublerMax = 21e9;      % Maximum Doubler output frequency (Hz)
freqTripBand1Max = 30e9;    % Maximum Tripler Band1 frequency (Hz)
freqTripBand2Max = 40e9;    % Maximum Tripler Band2 frequency (Hz)
freqTripBand3Max = 50e9;    % Maximum Tripler Band3 frequency (Hz)
divideEnabled = 0;      % Initialize divider state
CH_DIV = 0;               % Initialize CH_DIV value
if freqCenter < freqVcoMin
    divideEnabled = 1;      % Channel divider ON
    doublerState = 0;       % Doubler state
    triplerState = 0;       % Tripler state
    freqOutMin = [3750000000,1875000000,1250000000,937500000,625000000,...
        468750000,312500000,234375000,156250000,117187500,104166667,...
        78125000,58593750,39062500,29296875,19531250,14648438,9765625]; % Channel divider band minimum frequencies
    for chIndex = 1:length(freqOutMin)
        if freqCenter > freqOutMin(chIndex) % Find the desired channel divider band
            break;
        end
    end
    divideRatioList = [2,4,6,8,12,16,24,32,48,64,72,96,128,192,256,384,512,768];    % Channel divider ratios
    divideRatio = divideRatioList(chIndex); % Divider ratio for selected band
    CH_DIV = chIndex-1;  % CH_DIV is 0 to 17
    freqVco = divideRatio*freqCenter;     % Required VCO output frequency
    freqFund = freqCenter;      % Fundamental output frequency
elseif freqCenter <= freqVcoMax
    doublerState = 0;       % Doubler state
    triplerState = 0;       % Tripler state
    freqVco = freqCenter/1;     % Required Synthesizer output frequency
    freqFund = freqVco;         % Fundamental output frequency
elseif freqCenter <= freqDoublerMax
    doublerState = 1;       % Doubler state
    triplerState = 0;       % Tripler state
    freqVco = freqCenter/2;     % Required Synthesizer output frequency
    freqFund = freqVco;         % Fundamental output frequency
elseif freqCenter <= freqTripBand1Max
    doublerState = 0;       % Doubler state
    triplerState = 1;       % Tripler state
    freqVco = freqCenter/3;     % Required Synthesizer output frequency 
    freqFund = freqVco;         % Fundamental output frequency
    %%%%%%%%%%%%%%%%%%%%% Avoid Doubler power hole at 21GHz: %%%%%%%%%
    if freqVco < freqVcoMin
        divideEnabled = 1;      % Channel divider ON
        CH_DIV = 0;  % CH_DIV is divide by 2
        freqVco = 2*freqVco;     % VCO frequency doubled
    else
        divideEnabled = 0;      % Channel divider OFF
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif freqCenter <= freqTripBand2Max
    doublerState = 0;       % Doubler state
    triplerState = 2;       % Tripler state
    freqVco = freqCenter/3;     % Required Synthesizer output frequency
    freqFund = freqVco;         % Fundamental output frequency
elseif freqCenter <= 3*freqVcoMax
    doublerState = 0;       % Doubler state
    triplerState = 4;       % Tripler state
    freqVco = freqCenter/3;     % Required Synthesizer output frequency 
    freqFund = freqVco;         % Fundamental output frequency
elseif freqCenter <= freqTripBand3Max
    doublerState = 1;       % Doubler state
    triplerState = 4;       % Tripler state
    freqVco = freqCenter/6;     % Required Synthesizer output frequency   
    freqFund = freqVco;         % Fundamental output frequency
elseif freqCenter <= 3*freqDoublerMax
    doublerState = 1;       % Doubler state
    triplerState = 0;       % Tripler state
    freqVco = freqCenter/6;     % Required Synthesizer output frequency   
    freqFund = freqVco;         % Fundamental output frequency
elseif freqCenter <= 3*freqTripBand1Max
    doublerState = 0;       % Doubler state
    triplerState = 1;       % Tripler state
    freqVco = freqCenter/9;     % Required Synthesizer output frequency  
    freqFund = freqVco;         % Fundamental output frequency
    %%%%%%%%%%%%%%%%%%%%% Avoid Doubler power hole at 21GHz: %%%%%%%%%
    if freqVco < freqVcoMin
        divideEnabled = 1;      % Channel divider ON
        CH_DIV = 0;  % CH_DIV is divide by 2
        freqVco = 2*freqVco;     % VCO frequency doubled
    else
        divideEnabled = 0;      % Channel divider OFF
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
else
    doublerState = 0;       % Doubler state
    triplerState = 2;       % Tripler state
    freqVco = freqCenter/9;     % Required Synthesizer output frequency
    freqFund = freqVco;         % Fundamental output frequency
end


end

