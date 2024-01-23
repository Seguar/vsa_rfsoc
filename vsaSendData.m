function vsaSendData(data, data_v)
    sendBuffer = zeros(1, length(data)*2);
    sendBuffer(1:2:end) = real(data);
    sendBuffer(2:2:end) = imag(data);
    data_v.Channels.Item(0).ClearData();
    data_v.Channels.Item(0).SendData(single(sendBuffer))