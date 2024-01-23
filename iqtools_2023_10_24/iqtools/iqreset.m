function iqreset()
% reset all instrument connections
%
% Thomas Dippon, Keysight Technologies 2022
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

% g_iqDevList contains a list of all instrument connections - see iqopen()
global g_iqDevList;

% for debugging purposes set useVisaDev in the workspace to the desired
% value. Otherwise, it will be determined based on MATLAB version
if (evalin('base', 'exist(''useVisaDev'', ''var'')'))
    useVisaDev = evalin('base', 'useVisaDev');
else
    v = ver('MATLAB');
    useVisaDev = (v.Release >= '(R2022a)');
end

if (useVisaDev)
    g_iqDevList = [];
else
    instrreset();
end
