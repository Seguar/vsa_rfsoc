function [ FileID ] = SaveUxaRfCalFile( FileName,Freq,Gain,Phase )
%SaveUxaRfCalFile.m
% Saves RF Response data to an (S2P) RF Correction file that can be read by an xSA Spectrum Analyzer

[~, PtsTotal] = size(Freq);            % Vector size
FileID = fopen(FileName, 'w');

fprintf(FileID, '%s\r\n', '!2-port S-parameter file');
fprintf(FileID, '%s\r\n', '# HZ S DB R 50');

for N = 1:PtsTotal
    Result{N} = [ num2str(Freq(N)) ' 0 0 ' num2str(Gain(N)) ' ' num2str(Phase(N)) ' 0 0 0 0 ' ];
end

% Write the cell array to a text file:

for row = 1:PtsTotal
    fprintf(FileID, '%s\r\n', Result{row});
end

fclose(FileID);

end

