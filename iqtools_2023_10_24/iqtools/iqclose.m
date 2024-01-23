function iqclose(f)
% close an instrument connection
%
% Thomas Dippon, Keysight Technologies 2022
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

if (~isempty(f) && isa(f, 'double'))  % if iqclose was accidently called with file handle
    fclose(f);
elseif ~isempty(f) && isvalid(f)
    cf = class(f);
    switch (cf)
        case {'visa', 'tcpip'}   % used prior to MATLAB R2022
            fclose(f);
        case {'visadev.SOCKET', 'visalib.TCPIP', 'tcpclient'}
            delete(f);
        otherwise
            error('unexpected data type for iqclose: %s', cf);
    end
end
