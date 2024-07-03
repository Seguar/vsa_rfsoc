server_ip = 'pynq'; % Use the appropriate IP address or hostname http://192.168.3.1/lab
server_port = 4000; % Use the same port number used in the Python server

dataStream = 0;
fc = 5.2e9; % Center frequency in Hz
fc_d0 = fc;
fc_d1 = fc;
dataChan = 2^14; % Number of samples to be captured
da = 1;
nyquistZone = 1;
nyquistZone_d0 = nyquistZone;
nyquistZone_d1 = nyquistZone;
%%
commands = ['fc ' num2str(fc/1e6) '/' num2str(nyquistZone) '/' ...
    num2str(fc_d0/1e6) '/' num2str(nyquistZone_d0) '/' ...
    num2str(fc_d1/1e6) '/' num2str(nyquistZone_d1) ...
    '# dataChan ' num2str(dataChan*8) '# dataStream ' num2str(dataStream)];

%%
commands = append(commands, ['# da ' num2str(da)]);
tcp_client = rfsocConnect(server_ip, server_port, commands);
% writeline(tcp_client, commands);
commands = ['dataStream ' num2str(dataStream)];

%% Load data to the DACs
% Load data to DAC0
filename = 'C:\Users\Sega\OneDrive - Technion\Desktop\git\vsa_rfsoc\Signals\matlab.mat';

sigInt16 = sigPrepare(filename, 500e6, 500e6, 499e6);
% commands = (['dac0 ' strjoin(arrayfun(@num2str, sigInt16, 'UniformOutput', false), '/');]);

rfsocConnect(server_ip, server_port, commands);