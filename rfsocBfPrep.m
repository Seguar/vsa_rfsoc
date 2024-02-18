function [data_v, estimator, tcp_client, plot_handle, ula] = rfsocBfPrep(app, dataChan, setupFile, num, scan_res, fc, fsRfsoc, doa)

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

switch doa
    case 'MVDR'
        estimator = phased.MVDREstimator('SensorArray',ula,...
            'OperatingFrequency',fc,'ScanAngles',scan_axis,...
            'DOAOutputPort',true,'NumSignals', num);
    case 'MUSIC'
        estimator = phased.MUSICEstimator('SensorArray',ula,...
            'OperatingFrequency',fc,'ScanAngles',scan_axis,...
            'DOAOutputPort',true);
    case 'Beamscan'
         estimator = phased.BeamscanEstimator('SensorArray',ula,...
            'OperatingFrequency',fc,'ScanAngles',scan_axis,...
            'DOAOutputPort',true,'NumSignals', num);       
end

tcp_client = tcpclient(server_ip, server_port);
curr_data_size = dataChan * 8;
curr_data_size_bytes = typecast(uint64(curr_data_size), 'uint8');

write(tcp_client, curr_data_size_bytes);
clf(app.UIAxes);
yspec = zeros(1, length(scan_axis));
plot_handle = plot(app.UIAxes, scan_axis, yspec);

app.UIAxes.XLim = [min_ang max_ang];
app.UIAxes2.XLim = [min_ang max_ang];
app.UIAxes.YLim = [-20 0];
app.UIAxes2.YLim = [-30 0];
app.UIAxes.LineWidth = 1.5;
app.UIAxes2.LineWidth = 1.5;
app.UIAxes.XLabel.String  = ('\Theta^o');
app.UIAxes.YLabel.String  = ('Power');
app.UIAxes2.XLabel.String  = ('\Theta^o');
app.UIAxes2.YLabel.String  = ('Power');
app.UIAxes.FontSize = 16;
app.UIAxes2.FontSize = 16;