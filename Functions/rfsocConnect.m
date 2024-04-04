function tcp_client = rfsocConnect(server_ip, server_port, commands)
%% TCP prep
% Define the server IP and port (should match the server settings)
try
    tcp_client = tcpclient(server_ip, server_port, "ConnectTimeout", 1);
catch
    tcp_client = tcpclient('192.168.3.1', server_port, "ConnectTimeout", 1); % USB connection
end
flush(tcp_client,"output")
writeline(tcp_client, commands);