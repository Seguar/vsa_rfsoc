function result = iqdownload_M8135A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence, run, segmentLength, segmentOffset)
                                    
% Download a waveform to the M8135A
% It is NOT intended that this function be called directly, only via iqdownload
%
% B.Krueger, M. Schulte Keysight Technologies 2023
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS.

%     global lastFs;
%     global gData;
%     if (isempty(gData))
%         gData = cell(0);
%     end
      result = [];
%     if (~isempty(sequence))
%         errordlg('Sorry, M8135A does not have a sequencer!');
%         return;
%     end

    %% Setup connection

    if (~strcmp(arbConfig.connectionType, 'tcpip'))
        error('Please select tcp as a connection type and specify IP and port')
    end
 
    hostname = arbConfig.ip_address;
    port = arbConfig.port;
    
    % check server version
    version = get_api_version(hostname, port);
    version_dac = get_feature_version(hostname, port, 'dac');
    version_dacmemory = get_feature_version(hostname, port, 'dacmemory');
    if version ~= 1
        error('Incompatible USPA server version');
    end
    if version_dac ~= 1
        error('Incompatible dac feature version');
    end
    if version_dacmemory ~= 1
        error('Incompatible dacmemory feature version');
    end

    % if no data or fs=0, this might be a connection test? Quit early.
    if ((isempty(data))|| (fs == 0))
        return
    end
    
    pattern_stop(hostname, port);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % API call for set sample rate (later: include PSG control)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    try
        if ~((get_samplerate(hostname, port) == fs) && checksync(hostname, port))
            set_samplerate(hostname, port, fs);
            sync(hostname, port);
        end
    catch ME
        % should we really rethrow here? Nested errors might get confusing.
        error(['USPA sync failed - Error message:' newline ME.message]);
    end
    
     try  
        if (isfield(arbConfig, 'amplitude'))
            if (arbConfig.amplitude >= 0.35 && arbConfig.amplitude <= 0.9)
                set_swing_mv(hostname, port, arbConfig.amplitude*1000);
            else
                warndlg('Amplitude in Instrument Configuration is out of valid range, automatically set to 800 mV.');
                set_swing_mv(hostname, port, 800);
            end
        end
    catch ME
        % should we really rethrow here? Nested errors might get confusing.
        error(['Setting swing failed - Error message:' newline ME.message]);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % API call for uploading waveform to DAC (in variable data)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    try
        % pattern_load handles the conversion from float
        if (chMap(1) == 1)
            data = real(data);
        else
            data = imag(data);
        end
        pattern_load(hostname, port, data);
        pattern_start(hostname, port);
    catch ME
        % should we really rethrow here? Nested errors might get confusing.
        error(['Pattern download failed - Error message:' newline ME.message]);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Close session again
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % nothing to close since each commands opens and closes the connection.

%     if (~isfield(arbConfig, 'setupSecondary') && (~exist('keepOpen', 'var') || keepOpen == 0))
%         iqclose(f);
%     end
end


function set_samplerate(hostname, port, fs)
    query_checked(hostname, port, gen_command('dac', 'set_samplerate', {fs}));
end

function sync(hostname, port)
    query_checked(hostname, port, gen_command('dac', 'sync'));
    % maybe throw custom error and hide the details, but it is not really needed
    % resp = query(...)
    % if is_error(resp)
    %     error('Sync failed');
    % end
    % handle_error(resp);
end

function pattern_stop(hostname, port)
    query_checked(hostname, port, gen_command('dacmemory', 'pattern_stop'));
end

function pattern_start(hostname, port)
    query_checked(hostname, port, gen_command('dacmemory', 'pattern_start'));
end

function pattern_load(hostname, port, pattern)
    query_checked(hostname, port, gen_command('dacmemory', 'pattern_load', {pattern}));
end

function pattern_load_raw(hostname, port, pattern)
    query_checked(hostname, port, gen_command('dacmemory', 'pattern_load_raw', {pattern}));
end

function version = get_firmware_version(hostname, port)
    data = query_checked(hostname, port, gen_command('dac', 'get_firmware_version'));
    version = data.ret;
end

function actual_swing = set_swing_mv(hostname, port, swing)
    data = query_checked(hostname, port, gen_command('dac', 'set_swing', {swing}));
    actual_swing = data.ret;
end

function version = get_api_version(hostname, port)
    data = query_checked(hostname, port, gen_command('default', 'get_api_version'));
    version = data.ret;
end

function fs = get_samplerate(hostname, port)
    data = query_checked(hostname, port, gen_command('dac', 'get_samplerate'));
    fs = data.ret;
end

function synced = checksync(hostname, port)
    data = query_checked(hostname, port, gen_command('dac', 'checksync'));
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
        resp_str = '';
        byte = 0;
        while (byte ~= newline)
            byte = read(socket, 1);
            resp_str = [resp_str, char(byte)];
        end
    catch ME
        delete(socket);
        rethrow(ME);
    end
    delete(socket);
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