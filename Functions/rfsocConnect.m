function tcp_client = rfsocConnect(server_ip, server_port, commands)
%% TCP prep
% Define the server IP and port (should match the server settings)
try
    tcp_client = tcpclient(server_ip, server_port, "ConnectTimeout", 10);
catch
    tcp_client = tcpclient('192.168.3.1', server_port, "ConnectTimeout", 10); % USB connection
end
writeline(tcp_client, commands);