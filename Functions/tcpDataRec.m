function rawData = tcpDataRec(tcp_client, data_size, channels)
%TCPDATAREC Read one RFSoC frame from a tcpclient and return complex channels.
%
%   rawData = tcpDataRec(tcp_client, data_size, channels)
%
%   data_size is the number of int16 samples in the frame, not bytes.
%   For the current XM655 first-4-channel format, channels is 8:
%       ch0_I ch0_Q ch1_I ch1_Q ch2_I ch2_Q ch3_I ch3_Q ...
%   The output is [data_size/channels, channels/2] complex double.

    if nargin < 3 || isempty(channels)
        channels = 8;
    end

    data_size = double(data_size);
    channels = double(channels);

    if data_size <= 0 || channels <= 0 || mod(data_size, channels) ~= 0
        error('tcpDataRec:InvalidFrameSize', ...
            'data_size (%g) must be a positive multiple of channels (%g).', ...
            data_size, channels);
    end

    try
        tcp_client.ByteOrder = "little-endian";
    catch
        % Older MATLAB versions may not expose ByteOrder the same way.
    end

    data = readExactInt16(tcp_client, data_size);

    % Vectorized de-interleave:
    % rows: I/Q lanes, columns: time samples.
    raw = reshape(double(data), channels, []);
    rawData = complex(raw(1:2:end, :).', -raw(2:2:end, :).');
end

function data = readExactInt16(tcp_client, nSamples)
% Read exactly nSamples int16 values. TCP can return short reads.
    data = zeros(1, nSamples, 'int16');
    got = 0;

    while got < nSamples
        chunk = read(tcp_client, nSamples - got, 'int16');
        n = numel(chunk);

        if n == 0
            error('tcpDataRec:Timeout', ...
                'Socket timeout: received %d of %d int16 samples.', got, nSamples);
        end

        data(got + (1:n)) = chunk;
        got = got + n;
    end
end
