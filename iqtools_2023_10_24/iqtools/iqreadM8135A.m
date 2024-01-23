function result = iqreadM8135A(arbConfig, fs, numPts)
%iqreadM8135A Read samples from M8135A with mounted ADC.
% arguments:
% arbConfig - configuration
% fs - sample rate to configure the ADC for
% numPts - number of points to get

result = [];

if (~strcmp(arbConfig.connectionType, 'tcpip'))
    error('Please select tcp as a connection type and specify IP and port')
end

hostname = arbConfig.ip_address;
port = arbConfig.port;

% check server version
version = get_api_version(hostname, port);
version_adc = get_feature_version(hostname, port, 'adc');
version_adcmemory = get_feature_version(hostname, port, 'adcmemory');
if version ~= 1
    error('Incompatible USPA server version');
end
if version_adc ~= 1
    error('Incompatible adc feature version');
end
if version_adcmemory ~= 1
    error('Incompatible adcmemory feature version');
end

try
    fs_dac = get_samplerate_dac(hostname, port);
    if (fs_dac == 0)
        error('USPA DAC is not configured yet. Make sure to download a pattern first');
    end
    % for now we only support interconnected USPA ADC and DAC at same rate
    if (~is_near(fs, fs_dac))
        error(['Configured USPA ADC sample rate ' ...
               num2str(fs/1e9) ...
               ' GHz does not match sample rate of USPA DAC ' ...
               num2str(fs_dac/1e9) ...
               ' GHz. Make sure to download a pattern with the same sample rate used for capturing.']);
    end
catch ME
    error(['USPA configuring sample rate failed - Reason:' newline ME.message]);
end

try
    if ~((get_samplerate(hostname, port) == fs) && checksync(hostname, port))
        set_samplerate(hostname, port, fs);
        sync(hostname, port);
    end
catch ME
    % should we really rethrow here? Nested errors might get confusing.
    error(['USPA ADC sync failed - Error message:' newline ME.message]);
end

try
    maxPts = get_size(hostname, port);
    if (numPts <= 0)
        error('Number of points must be greater than zero');
    end
    if (numPts > maxPts)
        error(['Number of points cannot be greater than ' num2str(maxPts)]);
    end
    acquire(hostname, port);
    rawSamples = read_samples(hostname, port, numPts);
catch ME
    % should we really rethrow here? Nested errors might get confusing.
    error(['USPA Pattern upload failed - Reason:' newline ME.message]);
end
% scale raw samples which are 0..63 to -0.2..0.2
samples = (rawSamples / 31.5 - 1.0) * 0.2;
result = samples;

end

function near = is_near(a, b)
    near = abs(a-b) < 1e4*eps(min(abs(a),abs(b)));
end

function size_samples = get_size(hostname, port)
    data = query_checked(hostname, port, gen_command('adcmemory', 'get_size'));
    size_samples = data.ret;
end

function acquire(hostname, port)
    query_checked(hostname, port, gen_command('adcmemory', 'acquire'));
end

function samples = read_samples(hostname, port, numPts)
    data = query_checked(hostname, port, gen_command('adcmemory', 'read_samples', {numPts}));
    samples = data.ret;
end


function set_samplerate(hostname, port, fs)
    query_checked(hostname, port, gen_command('adc', 'set_samplerate', {fs}));
end

function sync(hostname, port)
    query_checked(hostname, port, gen_command('adc', 'sync'));
end

function version = get_firmware_version(hostname, port)
    data = query_checked(hostname, port, gen_command('adc', 'get_firmware_version'));
    version = data.ret;
end

function version = get_api_version(hostname, port)
    data = query_checked(hostname, port, gen_command('default', 'get_api_version'));
    version = data.ret;
end

function fs = get_samplerate(hostname, port)
    data = query_checked(hostname, port, gen_command('adc', 'get_samplerate'));
    fs = data.ret;
end

function fs = get_samplerate_dac(hostname, port)
    data = query_checked(hostname, port, gen_command('dac', 'get_samplerate'));
    fs = data.ret;
end

function synced = checksync(hostname, port)
    data = query_checked(hostname, port, gen_command('adc', 'checksync'));
    synced = data.ret;
end

function features = get_feature_version(hostname, port, feature)
    data = query_checked(hostname, port, gen_command(feature, 'get_feature_version'));
    features = data.ret;
end

function cmd = gen_command(feature, name, args, kwargs)
    arguments
        feature string
        name string% {mustBeText} is not supported in R2019
        args cell = {}
        kwargs struct = struct()
    end
    cmd = struct();
    cmd.feature = string(feature);
    cmd.name = string(name);
    cmd.args = args;
    cmd.kwargs = kwargs;
end

function resp_str = query_raw(hostname, port, command_str)
% We just open the connection for each command so that we do not
% need to keep any sockets or other state.
    socket = tcpclient(hostname, port, 'Timeout', 30);
    try
        write(socket, uint8(command_str));
        % As long as we quit after each command, we can get away with
        % buffering the data without keeping state between query_raw calls.
        % This is important for speed, especially when getting big arrays
        % of samples.
        resp_str = readline_discard(socket);
    catch ME
        delete(socket);
        rethrow(ME);
    end
    delete(socket);
end

function message = readline_discard(socket)
% This function does not keep the buffer so data after the newline is
% thrown away. Readline would make this function obsolete but it is only
% available from 2020b onwards.
    buffer = '';
    message = '';
    while true
        parts = strsplit(buffer, newline);
        message = [message, parts{1}];
        if (~isempty(parts(2:end)))
            return; % we arrived at the separator, throw the rest away
        end
        while true
            % This is needed because read(t) does not block to wait for any
            % number of bytes. We also cannot use read(t, count) because
            % that one will always wait until count bytes are read, instead
            % of reading *up to* count bytes. So we use read(t,1) to at
            % least get the blocking behavior.
            buffer_f = char(read(socket, 1));
            buffer = [buffer_f, char(read(socket))];
            if (~isempty(buffer))
                break;
            end
        end
    end
end

function resp = query(hostname, port, command)
% Send the actual command.
    command_str = [jsonencode(command) newline];
    resp_str = query_raw(hostname, port, command_str);
    resp = jsondecode(resp_str);
end

function data = query_checked(hostname, port, command)
    resp_cmd = query(hostname, port, command);
    handle_error(resp_cmd);
    data = resp_cmd.data;
end

function iserror = is_error(resp)
    iserror = ~isempty(resp.error);
end

function handle_error(resp)
    if isempty(resp.error)
        return
    end
    error_type = resp.error.error;
    error_message = resp.error.message;
    error_message_long = resp.error.message_long;
    error_str = ['Error on remote device (' error_type '): ' error_message];
    if strcmp(error_type, 'MMI64Error')
        error_message_long = 'The server had an error communicating with the hardware';
    end
    if ~isempty(error_message_long)
        error_str = [error_str newline 'Details:' error_message_long];
    end
    error(error_str); 
end