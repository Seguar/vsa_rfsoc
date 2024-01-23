function [ status ] = setModulationState( state, mohawk )
% setModulationState.m - Sets state of Mohawk RF Output Modulation

% setModulationState.m REV.04 Ed Barich 2019.06.24
%   Removed 2nd colon in ':OUTP: 1', which SCIPI chokes on

% setModulationState.m REV.03 Ed Barich 2018.12.17
%   Revised for FX3 Processor using SCIPI commands

% setModulationState.m REV.02    Ed Barich 2 June 2017
%   Revised for Mohawk PROTO2

% INPUTS:
%   state = [ 0 | 1 | 2 | 3 ];	% 0=RF_On+Mod_Off; 1=RF_On+Mod_On;2=RF_Off+Mod_On;3=RF_Off+Mod_Off
%   mohawk: mohawk object
% OUTPUTS:
%   status = *OPC? result

% Send SCIPI Commands to Mohawk:
switch state
    case 0
        fprintf(mohawk,':OUTP:COMB 0');   % Modulation OFF;
        fprintf(mohawk,':OUTP 1');   % RF Output ON;
    case 1
        fprintf(mohawk,':OUTP:COMB 1');   % Modulation ON;
        fprintf(mohawk,':OUTP 1');   % RF Output ON;
    case 2
        error('parameter value not allowed');
    case 3
        fprintf(mohawk,':OUTP:COMB 0');   % Modulation OFF;
        fprintf(mohawk,':OUTP 0');   % RF Output OFF;    
    otherwise
        error('parameter value not allowed');
end

% status = commandComplete(mohawk);    % Check for Command Complete (*OPC) status
fprintf(mohawk,'*OPC?');  % Command complete query
[status,count,msg] = fscanf(mohawk);    % Get query response

end

