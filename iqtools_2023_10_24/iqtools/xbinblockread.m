function data = xbinblockread(f, format, cmd, endianness)
% read a binary block from an instrument
% works like the "old" binblockread, but takes visadev and tcp structures
% into account
% optionally, an endianness can be overwritten by the caller ('big-endian' or
% 'little-endian')
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
            error('xbinblockread: unexpected data type: %s', cf);
    end
else
    error('xbinblockread called with invalid instrument handle');
end

data = [];
switch (cf)
    case {'visa', 'tcpip'}
        fprintf(f, '%s\n', cmd);
        if (exist('endianness', 'var'))   % caller provided endianness takes precedence
            if (endianness(1) == 'b')
                f.ByteOrder = 'bigEndian';
            else
                f.ByteOrder = 'littleEndian';
            end
        elseif (isa(f, 'tcpip'))
            f.ByteOrder = 'bigEndian';
        else
            f.ByteOrder = 'littleEndian';
        end
        usebinblock = true;
        if (usebinblock)
            data = binblockread(f, format);
            fread(f, 1, 'char');   % read the EOL character, otherwise we get a "query interrupted" error
        else
            x = char(fread(f, 1, 'char'));
            if (~strcmp(x, '#'))
                errordlg('xbinblockread: expected ''#'' as a first character of a binary block');
            else
                llStr = fread(f, 1, 'char');
                if (llStr < '0' || llStr > '9')
                    errordlg('xbinblockread: expected a digit as a second character of a binary block');
                else
                    ll = str2double(llStr);
                    lenStr = fread(f, ll, 'char');
                    len = str2double(lenStr);
                    data = fread(f, len, format);
                    fread(f, 1, 'char');   % read the EOL character, otherwise we get a "query interrupted" error
                end
            end
        end
    case {'visadev.SOCKET', 'visalib.TCPIP', 'tcpclient'}
        f.ByteOrder = 'little-endian';
        if (exist('endianness', 'var'))
            f.ByteOrder = endianness;
        end
        f.writeline(cmd);
        data = f.binblockread(format);
        f.read(1,'char');   % read the EOL character, otherwise we get a "query interrupted" error
end
if (debugScpi)
    fprintf('%s - %s (%s, %d elements, %s, %s)\n', nameFct(), cmd, format, length(data), cf, f.ByteOrder);
end
end
