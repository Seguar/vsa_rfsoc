function retVal = xquery(f, cmd)
% send a SCPI query <cmd> to an instrument with handle <f>
% works like the "old" query(), but takes visadev and tcp structures
% into account
% set debugScpi=1 in MATLAB workspace to log SCPI commands
%
% Th.Dippon, Keysight Technologies 2022
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

retVal = 0;
debugScpi = evalin('base', 'exist(''debugScpi'', ''var'') && debugScpi >= 1');
if isvalid(f)
    cf = class(f);
    switch (cf)
        case {'visa', 'tcpip'}   % used prior to MATLAB R2022
            queryFct = @(s) query(f, s);
            nameFct = @() f.Name;
        case {'visadev.SOCKET', 'visalib.TCPIP'}
            queryFct = @(s) f.writeread(s);
            nameFct = @() f.ResourceName;
        case {'tcpclient'}
            queryFct = @(s) tcpquery(f,s);
            nameFct = @() sprintf('%s:%d', f.Address, f.Port);
        otherwise
            error('xquery: unexpected data type: %s', cf);
    end
else
    error('xquery was called with an invalid instrument handle');
end

% send the query
try
    retVal = char(queryFct(cmd));   % cast to char, because some callers don't expect strings
catch ex
    errordlg(sprintf('%s - query failed.\nInstrument: %s\nError message %s', cmd, nameFct(), ex.message));
end
maxChar = 60;
if (debugScpi)
    if (length(retVal) > maxChar)
        rstr = sprintf('%s... (total %d chars)', retVal(1:maxChar), length(retVal));
    else
        rstr = retVal;
    end
    if (ischar(rstr) || isstring(rstr))
        fprintf('%s - %s -> %s\n', nameFct(), cmd, strtrim(rstr));
    else
        fprintf('%s - %s -> %g\n', nameFct(), cmd, rstr);
    end
end
end


function retVal = tcpquery(f, s)
f.writeline(s);
retVal = f.readline();
end
