function [ status ] = setReferenceState( state, mohawk )
% setReferenceState.m - Sets state of Mohawk 100MHz Reference

% setReferenceState.m REV.03    Ed Barich 2018.12.17
%   Revised for FX3 Processor using SCIPI commands

% setReferenceState.m REV.02    Ed Barich 2 June 2017
%   Revised for Mohawk PROTO2

% INPUTS:
%   state = [ 0 | 1 ];	% =0, Internal Reference; =1, External Reference
%   mohawk: mohawk object

% OUTPUTS:
%   status = *OPC? result

% Send SCIPI Commands to Mohawk:
if state == 0
    fprintf(mohawk,':ROSC:SOUR INT');   % Use internal reference
%     fprintf(mohawk,[':SERV:REF:DAC ',num2str((2^16)/2)]);  % ADJUST REFERENCE DAC
elseif state == 1
    fprintf(mohawk,':ROSC:SOUR EXT');   % Use external reference    
else
    error('parameter value not allowed');
end

% ComCompStatus = commandComplete(mohawk);    % Check for Command Complete (*OPC) status
fprintf(mohawk,'*OPC?');  % Command complete query
[status,count,msg] = fscanf(mohawk);    % Get query response

% Get Reference Locking State:
fprintf(mohawk,':ROSC:SOUR?');  % Command complete query
[RefLockState,count,msg] = fscanf(mohawk);    % Get query response

status = RefLockState;
end

