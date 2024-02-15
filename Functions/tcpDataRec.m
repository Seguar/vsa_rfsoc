function rawData = tcpDataRec(tcp_client, data_size, channels)
    data_bytes = read(tcp_client, data_size * 2, 'int8'); %tcp can trnsmit only int8
    % Unpack the received binary data into Int16 array
    data = typecast(data_bytes, 'int16');

    %% Data convert
    dataLen = data_size/channels;
    raw = zeros(channels, dataLen);
    rawData = zeros(dataLen, channels/2);

    for i=1:channels
        raw(i, :) = data(i:channels:end);
    end
    rawc = double(raw);
    idd = 1;
    for n=1:2:channels
        rawData(:, idd) = rawc(n,:) - 1i*rawc(n+1,:);
        idd = idd + 1;
    end