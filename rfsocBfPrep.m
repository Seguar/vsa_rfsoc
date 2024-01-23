function [data_v, estimator, tcp_client, plot_handle] = rfsocBfPrep(app, dataChan, setupFile, num)

bw = 20e6;
fc = 5.7e9;
fsRfsoc = 125e6;
c = physconst('LightSpeed'); % propagation velocity [m/s]
lambda = c / fc; % wavelength
d = lambda/2; % spacsing antenna elemnts
min_ang = -90; % min scanning angle
max_ang = 90; % max scanning angle
scan_res = 1; % scan resolution
scan_axis = min_ang:scan_res:max_ang; % angles axis
num_elements = 4;
ula = phased.ULA('NumElements',num_elements,'ElementSpacing',d, 'ArrayAxis','y');

fc_v = 0;
sr_v = fsRfsoc;
bw_v = fsRfsoc;
[data_v] = vsaDdc(fc_v, sr_v, bw_v, dataChan, 1, setupFile);

%% TCP prep
data_size = dataChan * 8;
data_size_bytes = typecast(uint64(data_size), 'uint8');

channels = 8;
raw = zeros(channels, data_size / 8);
% Define the server IP and port (should match the server settings)
server_ip = 'pynq'; % Use the appropriate IP address or hostname
server_port = 4000; % Use the same port number used in the Python server
dataLen = data_size/channels;

estimator = phased.MVDREstimator('SensorArray',ula,...
    'OperatingFrequency',fc,'ScanAngles',scan_axis,...
    'DOAOutputPort',true,'NumSignals', num);

tcp_client = tcpclient(server_ip, server_port);
curr_data_size = dataChan * 8;
curr_data_size_bytes = typecast(uint64(curr_data_size), 'uint8');

write(tcp_client, curr_data_size_bytes);

hold on;
grid minor;
axis tight;
yspec = zeros(1, length(scan_axis));
txtPlt = text(0, 0, '', 'Color', 'blue', 'FontSize', 14);
plot_handle = plot(scan_axis, yspec);
% ylim([0 50])
xlim([min_ang max_ang])

xlabel('\Theta^o');
ylabel('Power_{MVDR}');