function xbinblockwrite(f, data, format, cmd)
% send a binary block to an instrument
% works like the "old" binblockwrite, but takes visadev and tcp structures
% into account
%
% Thomas Dippon, Keysight Technologies 2022
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

debugScpi = evalin('base', 'exist(''debugScpi'', ''var'') && debugScpi >= 1');
if isvalid(f)
    cf = class(f);
    switch (cf)
        case {'visa', 'tcpip'}   % used prior to MATLAB R2022
            nameFct = @() f.Name;
        case {'visadev.SOCKET', 'visalib.TCPIP'}
            nameFct = @() f.ResourceName;
        case {'tcpclient'}
            nameFct = @() sprintf('%s:%d', f.Address, f.Port);
        otherwise
            error('xbinblockwrite: unexpected data type: %s', cf);
    end
end

if (debugScpi)
    fprintf('%s - %s (%s, %d elements)\n', nameFct(), cmd, format, length(data));
end
switch (cf)
    case {'visa', 'tcpip'}
        f.ByteOrder = 'littleEndian';
        binblockwrite(f, data, format, cmd);
        fprintf(f, '\n');

    case {'visadev.SOCKET', 'visalib.TCPIP', 'tcpclient'}
% it seems that f.writebinblock does not work correctly, so we have to do it on our own...
%         f.EOIMode = 'off';
%         f.write(cmd);
%         f.EOIMode = 'on';
%         f.writebinblock(data, format);
        if (isempty(find(strcmp(format, {'int8','uint8','int16','uint16','int32','uint32'}),1)))
            error('xbinblockwrite: only int8/uint8/int16/uint16 are supported data formats');
        end
        if (~strcmp(class(data), format))
            error('xbinblockwrite: class(data) must be equal to format (%s - %s)', class(data), format);
        end
        if (size(data,1) ~= 1)
            data = data.';
        end
        if (size(data,1) ~= 1)
            error('xbinblockwrite: data must be a vector');
        end
        data8 = typecast(data, 'uint8');
        lenStr = num2str(size(data8,2));
        cmdTmp = [char(sprintf('%s#%d%s', cmd, length(lenStr), lenStr)) char(data8)];
        f.writeline(cmdTmp);
        
end
end
