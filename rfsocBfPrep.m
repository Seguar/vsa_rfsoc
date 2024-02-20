function [data_v, tcp_client, plot_handle, ula] = rfsocBfPrep(app, dataChan, fc, fsRfsoc, c, scan_axis, num_elements)
lambda = c / fc; % wavelength
d = lambda/2; % spacsing antenna elemnts
ula = phased.ULA('NumElements',num_elements,'ElementSpacing',d);
min_ang = scan_axis(1);
max_ang = scan_axis(end);
fc_v = 0;
sr_v = fsRfsoc;
bw_v = fsRfsoc;
[data_v] = vsaDdc(fc_v, sr_v, bw_v, dataChan, 1);

%% TCP prep
% Define the server IP and port (should match the server settings)
server_ip = 'pynq'; % Use the appropriate IP address or hostname
server_port = 4000; % Use the same port number used in the Python server

tcp_client = tcpclient(server_ip, server_port);
curr_data_size = dataChan * 8;
curr_data_size_bytes = typecast(uint64(curr_data_size), 'uint8');
write(tcp_client, curr_data_size_bytes);
%% Graph handles
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