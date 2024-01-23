function f = iqopen(cfg)
% open an instrument connection
% argument is expected to be a struct or a string.
% If it is a struct, the following members are expected:
%  connectionType - 'tcpip' or 'visa', 'visa-tcpip', 'visa-gpib'
%  visaAddr - VISA resource string for all visa-... types
%  ip_address - for tcpip only
%  port - for tcpip only
% If it is a string, it should contain the visa address
% If no argument is given, the configuration from iqconfig is used
%
% Thomas Dippon, Keysight Technologies 2011-2022
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

    f = [];
    % for debugging purposes set useVisaDev in the workspace to the desired
    % value. Otherwise, it will be determined based on MATLAB version
    if (evalin('base', 'exist(''useVisaDev'', ''var'')'))
        useVisaDev = evalin('base', 'useVisaDev');
    else
        v = ver('MATLAB');
        useVisaDev = (v.Release >= '(R2022a)');
    end

    % g_iqDevList contains a list of all instrument connections - see iqopen()
    global g_iqDevList;

% if no argument is supplied, use the default configuration file
    if (~exist('cfg', 'var'))
        cfg = loadArbConfig();
    end
% if a string is supplied, assume that it is a visa address
    if (~isstruct(cfg))
        newCfg.visaAddr = cfg;
        newCfg.connectionType = 'visa';
        cfg = newCfg;
    end
% for M8195A_Rev0, there is no TCPIP connection - just return a non-empty
% value to keep the rest of the code happy...
    if (isfield(cfg, 'model') && ~isempty(strfind(cfg.model, 'M8195A_Rev0')))
        f = 42;
        return;
    end
% assume VISA as the default connection type
    if (~isfield(cfg, 'connectionType'))
        cfg.connectionType = 'visa';
    end
% if visa address is of the format TCPIPx::ip_address::port::SOCKET,
% treat it as a tcpip connection (MATLAB visa can't use them)
    if (strcmp(cfg.connectionType, 'visa') && ~isempty(strfind(cfg.visaAddr, '::SOCKET')))
        cfg.connectionType = 'tcpip';
        try
            [dummy parts] = regexp(cfg.visaAddr, '::', 'match', 'split');
            cfg.ip_address = parts{2};
            cfg.port = str2double(parts{3});
        catch
            errordlg('incorrectly formed VISA address');
        end
    end

    switch lower(cfg.connectionType)
        case { 'visa', 'visa-tcpip', 'visa-gpib', 'visa-usb', 'visa-pxi' } %  Robin Wang Adds Visa-pxi type
            addr = cfg.visaAddr;
            if (useVisaDev)
                if (~exist('g_iqDevList', 'var'))
                    g_iqDevList = [];
                end
                if (strcmp(cfg.visaAddr, 'list'))  % for debugging, call iqopen('list') to show a list of all stored devices
                    for i=1:length(g_iqDevList)
                        h = g_iqDevList(i).handle;
                        if (~isempty(h) && isvalid(h))
                            fprintf('%s - valid: %s\n', g_iqDevList(i).addr, class(h));
                        else
                            fprintf('%s - invalid\n', g_iqDevList(i).addr);
                        end
                    end
                    return;
                end
                f = [];
                tmp = [];
                % check, if the VISA address is already in the global list
                for i=1:length(g_iqDevList)
                    if (strcmp(g_iqDevList(i).addr, addr))
                        tmp = g_iqDevList(i).handle;
                        if (isvalid(tmp))
%                            fprintf('Note: instrument connection to %s has not been closed properly\n', addr);
                            f = tmp;
                        end
                        break;
                    end
                end
                if (isempty(f))
                    try
                        f = visadev(addr);
                    catch e
                        if (~isempty(strfind(e.message, 'resource was not found')))
                            errordlg(sprintf(['Can''t connect to "%s".\n' ...
                                'Please verify that you specified a valid VISA address.\n\n' ...
                                'Error message:\n%s'], cfg.visaAddr, e.message), 'Error', 'replace');
                        else
                            errordlg({'Error calling visadev(). Please verify that' ...
                                'you have the "Instrument Control Toolbox" installed' ...
                                'MATLAB error message:' e.message}, 'Error', 'replace');
                        end
                        f = [];
                        return;
                    end
                end
                if (~isempty(tmp))              % already in the list --> update the handle
                    g_iqDevList(i).handle = f;
                elseif (isempty(g_iqDevList))   % not in the list & list is empty --> create first element
                    g_iqDevList = struct('addr', addr, 'handle', f);
                else                            % otherwise --> append to the end of the list
                    g_iqDevList(end+1) = struct('addr', addr, 'handle', f);
                end
            else
                % legacy visa() and instrfind() functionality
                i_list = instrfind('Alias', cfg.visaAddr);
                if isempty(i_list)
                    i_list = instrfind('RsrcName', cfg.visaAddr);
                end
                % if no previous connection is available, open a new one
                if isempty(i_list)
                    try
                        f = visa('agilent', cfg.visaAddr);
                    catch e
                        if (~isempty(strfind(e.message, 'Invalid RSRCNAME')))
                            errordlg(sprintf(['Can''t connect to "%s".\n' ...
                                'Please verify that you specified a valid VISA address.\n\n' ...
                                'Error message:\n%s'], cfg.visaAddr, e.message), 'Error', 'replace');
                        else
                            errordlg({'Error calling visadev(). Please verify that' ...
                                'you have the "Instrument Control Toolbox" installed' ...
                                'MATLAB error message:' e.message}, 'Error', 'replace');
                        end
                        f = [];
                    end
                else
                    f = i_list(1);
                end
            end
        case 'tcpip'
            addr = sprintf('%s:%d', cfg.ip_address, cfg.port);
            if (useVisaDev)
                if (~exist('g_iqDevList', 'var'))
                    g_iqDevList = [];
                end
                f = [];
                tmp = [];
                % check, if the VISA address is already in the global list
                for i=1:length(g_iqDevList)
                    if (strcmp(g_iqDevList(i).addr, addr))
                        tmp = g_iqDevList(i).handle;
                        if (isvalid(tmp))
                            fprintf('warning: instrument connection to %s has not been closed properly\n', addr);
                            f = tmp;
                        end
                        break;
                    end
                end
                if (isempty(f))
                    try
                        f = tcpclient(cfg.ip_address, cfg.port);
                    catch e
                        errordlg(sprintf(['Could not open connection to %s.' ...
                            'Please verify that you specified the correct address ' ...
                            'in the "Configure Instrument Connection" dialog.\n' ...
                            'MATLAB error message: %s'], addr, e.message), 'Error');
                        f = [];
                        return;
                    end
                end
                if (~isempty(tmp))              % already in the list --> update the handle
                    g_iqDevList(i).handle = f;
                elseif (isempty(g_iqDevList))   % not in the list & list is empty --> create first element
                    g_iqDevList = struct('addr', addr, 'handle', f);
                else                            % otherwise --> append to the end of the list
                    g_iqDevList(end+1) = struct('addr', addr, 'handle', f);
                end
            else
                i_list = instrfind('Type', 'tcpip', 'RemoteHost', cfg.ip_address, 'RemotePort', cfg.port);
                if isempty(i_list)
                    try
                        useTcpclient = false;
                        if (useTcpclient && exist('tcpclient', 'file'))
                            f = tcpclient(cfg.ip_address, cfg.port);
                        else
                            f = tcpip(cfg.ip_address, cfg.port);
                        end
                    catch e
                        errordlg({'Error calling tcpip(). Please verify that' ...
                            'you have the "Instrument Control Toolbox" installed' ...
                            'MATLAB error message:' e.message}, 'Error');
                        f = [];
                    end
                else
                    f = i_list(1);
                end
            end
        otherwise
            error('usage: invalid connection type');
    end

    if (~isempty(f))
        % Set input & output buffer size and timeout.
        % With visa & tcpip you cannot set those parameters after they are open
        if (~isa(f, 'visa') && ~isa(f, 'tcpip') || strcmp(f.Status, 'closed'))
            f.OutputBufferSize = 30*64e6;
            f.InputBufferSize = 12.8e6;
            if (isfield(cfg, 'timeout'))
                f.Timeout = cfg.timeout;
            else
                f.Timeout = 35;
            end
        end
        % The old visa and tcpip have to be explicitly opened.
        % visadev & tcpclient are already open once they are instatiated
        if ((isa(f, 'visa') || isa(f, 'tcpip')) && strcmp(f.Status, 'closed'))
            try
                fopen(f);
            catch e
                errordlg({'Could not open connection to ' addr ...
                          'Please verify that you specified the correct address' ...
                          'in the "Configure Instrument Connection" dialog.' ...
                          'Verify that you can communicate with the' ...
                          'instrument using the Keysight Connection Expert'}, 'Error');
                f = [];
            end
        end
    end
end
