function tcp_client = rfsocConnect(server_ip, server_port, dataChan)
%% TCP prep
% Define the server IP and port (should match the server settings)
try
    tcp_client = tcpclient(server_ip, server_port, "ConnectTimeout", 5);
catch
    tcp_client = tcpclient('192.168.3.1', server_port, "ConnectTimeout", 5); % USB connection
end
curr_data_size = dataChan * 8;
curr_data_size_bytes = typecast(uint64(curr_data_size), 'uint8');
write(tcp_client, curr_data_size_bytes);