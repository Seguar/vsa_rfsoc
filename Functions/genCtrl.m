function genCtrl(ip, port, state, power, fc, mod)
obj1 = instrfind('Type', 'tcpip', 'RemoteHost', ip, 'RemotePort', port, 'Tag', '');
% Create the tcpip object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    obj1 = tcpip(ip, port);
else
    fclose(obj1);
    obj1 = obj1(1);
end

% Configure instrument object, obj1

set(obj1, 'InputBufferSize', 12800000);

% Configure instrument object, obj1

set(obj1, 'OutputBufferSize', 1920000000);

% Connect to instrument object, obj1.
fopen(obj1);

%% Instrument Configuration and Control

% Communicating with instrument object, obj1.
fprintf(obj1, [':SOURce:FREQuency ' num2str(fc)]);
fprintf(obj1, ['POWer ' num2str(power)]);
if state
    fprintf(obj1, ':OUTput:STATe ON');
else
    fprintf(obj1, ':OUTput:STATe OFF');
end

if mod
    fprintf(obj1, ':OUTput:MODulation:STAte ON');
else
    fprintf(obj1, ':OUTput:MODulation:STATe OFF');
end
%% Disconnect and Clean Up

% The following code has been automatically generated to ensure that any
% object manipulated in TMTOOL has been properly disposed when executed
% as part of a function or script.

% Disconnect all objects.
fclose(obj1);

% Clean up all objects.
delete(obj1);
clear obj1;

