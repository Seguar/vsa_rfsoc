function [data_v, estimator, tcp_client, plot_handle, ula] = rfsocBfPrep(app, dataChan, setupFile, num, scan_res, fc, fsRfsoc)

c = physconst('LightSpeed'); % propagation velocity [m/s]
lambda = c / fc; % wavelength
d = lambda/2; % spacsing antenna elemnts
min_ang = -90; % min scanning angle
max_ang = 90; % max scanning angle
scan_axis = min_ang:scan_res:max_ang; % angles axis
num_elements = 4;
% ula = phased.ULA('NumElements',num_elements,'ElementSpacing',d, 'ArrayAxis','y');
ula = phased.ULA('NumElements',num_elements,'ElementSpacing',d);

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
clf(app.UIAxes);
yspec = zeros(1, length(scan_axis));
plot_handle = plot(app.UIAxes, scan_axis, yspec);

% p1 = pattern(ula,fc,scan_axis,0,'PropagationSpeed',c,'CoordinateSystem','rectangular','Type','directivity', 'Weights',double(ones(4,1)));
% patt_handle = plot(app.UIAxes2 ,app.scan_axis, p1, LineWidth=1.5);

app.UIAxes.XLim = [min_ang max_ang];
app.UIAxes2.XLim = [min_ang max_ang];
app.UIAxes.YLim = [0 1.2];
app.UIAxes.XLabel.String  = ('\Theta^o');
app.UIAxes.YLabel.String  = ('Power_{MVDR}');
app.UIAxes.FontSize = 16;
app.UIAxes2.FontSize = 16;