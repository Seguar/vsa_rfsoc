
function [ mohawk ] = setInitialState( mohawkVisaAddress )
% setInitialState.m - Initializes the Mohawk hardware

% setInitialState.m REV.04    Ed Barich 2019.01.15
%   Includes Mohawk image download to FX3 processor

% setInitialState.m REV.03    Ed Barich 2018.12.17
%   Revised for FX3 Processor using SCIPI commands
%   (This initialization does not do anything except check *OPC result)

% setInitialState.m REV.02    Ed Barich 2 June 2017
%   Revised for Mohawk PROTO2

% INPUTS:
%   mohawkVisaAddress: mohawk VISA address
% OUTPUTS:
%   mohawk: object connected to Mohawk controller

% Open VISA handle to Mohawk DUT
mohawk = visa('agilent',mohawkVisaAddress); % Connect to VISA address
try
    fopen(mohawk);  % Open the USB link to Mohawk
catch
    statusProgFx3 = dos('progfx3');     % Load Mohawk Image
    disp('Waiting for Mohawk image download to finish...');
    pause(5);
    fopen(mohawk);  % Open the USB link to Mohawk
end

% fprintf(mohawk,':SERV:SPUR:DODG 0');   % Turn spur dodging ON or OFF
% fprintf(mohawk,':SERV:OSC:DOUB 0');   % Turn LMX2594 Osc2x ON or OFF

end

