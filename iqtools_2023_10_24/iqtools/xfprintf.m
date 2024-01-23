function [retVal, retStr] = xfprintf(f, cmd, ignoreError)
% send a SCPI command <cmd> to an instrument with handle <f>
% works like the "old" xfprintf, but takes visadev and tcp structures
% into account
% set ignoreError=1 to ignore any errors returned by the command
% set debugScpi=1 in MATLAB workspace to log SCPI commands
% set debugNoQuery=1 in the MATLAB workspace to skip :SYST:ERR? queries
%    after each command. This will speed up execution, but carries the risk
%    of not finding potential errors
%
% Thomas Dippon, Keysight Technologies 2022
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

retVal = 0;
debugScpi = evalin('base', 'exist(''debugScpi'', ''var'') && debugScpi >= 1');
debugNoQuery = evalin('base', 'exist(''debugNoQuery'', ''var'') && debugNoQuery >= 1');
ignoreError = exist('ignoreError', 'var') && ignoreError >= 1;
if isvalid(f)
    cf = class(f);
    switch (cf)
        case {'visa', 'tcpip'}  % used prior to MATLAB R2022
            writeFct = @(s) fprintf(f, s);
            queryFct = @(s) query(f, s);
            nameFct = @() f.Name;
        case {'visadev.SOCKET', 'visalib.TCPIP'}
            writeFct = @(s) f.writeline(s);
            queryFct = @(s) f.writeread(s);
            nameFct = @() f.ResourceName;
        case {'tcpclient'}
            writeFct = @(s) f.writeline(s);
            queryFct = @(s) tcpquery(f,s);
            nameFct = @() sprintf('%s:%d', f.Address, f.Port);
        otherwise
            error(sprintf('xfprintf: unexpected data type: %s', cf));
    end
else
    error('xfprintf was called with an invalid instrument handle');
end
if (debugScpi)
    fprintf('%s - %s\n', nameFct(), cmd);
end
writeFct(cmd);
if (debugNoQuery)
    return;
end
rptErr = 0;
while rptErr < 50
    try
        if ((isa(f, 'visadev.SOCKET') || isa(f, 'visalib.TCPIP')) && ~isempty(find(strncmp(f.Model, {'DSO', 'DSA', 'MXR', 'UXR'}, 3), 1)))
            result = queryFct(':SYST:ERR? STRING');
        else
            result = queryFct(':SYST:ERR?');
        end
    catch
        result = [];
    end
    retStr = result;
    if (isempty(result))
        errordlg(sprintf(['The instrument at %s did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'], nameFct()), 'Error');
        iqclose(f);
        retVal = -1;
        return;
    end
    if (sscanf(result, '%d') == 0)  % no error -> return
        break;
    else
        if (debugScpi)
            fprintf('%s - %s --> %s\n', nameFct(), cmd, strtrim(result));
        end
        if (~ignoreError)
            errordlg(sprintf('The instrument at %s returned an error.\nCommand: %s\nError Message: %s', nameFct(), cmd, result));
            retVal = -1;
        end
        rptErr = rptErr + 1;   % make sure we don't loop forever
    end
end
end


function retVal = tcpquery(f, s)
f.writeline(s);
retVal = f.readline();
end

