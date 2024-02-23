function tcp_client = rfsocConnect(server_ip, server_port, dataChan)
%% TCP prep
% Define the server IP and port (should match the server settings)
tcp_client = tcpclient(server_ip, server_port);
curr_data_size = dataChan * 8;
curr_data_size_bytes = typecast(uint64(curr_data_size), 'uint8');
write(tcp_client, curr_data_size_bytes);