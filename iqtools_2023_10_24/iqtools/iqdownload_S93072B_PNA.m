function result = iqdownload_S93072B_PNA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence, run)
% This writes a file that is compatible with the S93072
% It is NOT intended that this function be called directly, only via iqdownload
%
% 2021 Niza Messaoudi- Keysight Technologies
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 
result = [];
len = length(data);

if (fs ~=0 && len/fs > 6.8266e-6)
    errordlg('Waveform is too long. Waveform length must be less than 6.8266e microseconds');
    return;
end
 
    if (~isempty(sequence))
        errordlg('Sorry, S93072B_PNA does not have a sequencer');
        return;
    end
    defaultfilename = 'D:\';
       [FileName, PathName, ~] = uiputfile({...          
            '*.csv', 'ASCII CSV'}, ...          
            'Save Waveform As...', defaultfilename);
        if (FileName ~= 0)
            filename = fullfile(PathName, FileName);
        else
            return
        end

f = fopen(filename, 'w');
if (isempty(f))
    error('cannot open %s', filename);
end
fprintf(f, sprintf('SampleRate = %g\n', fs)); % file
for i=1:length(data)
    fprintf(f, '%g,%g\n', real(data(i)), imag(data(i))); % file
end
fclose(f);

    
