evmState = [];
maxPoints = 50;
setupFile = '1ch_fast_ddc_new.setx';
pcvsa = vsaSetup(setupFile);
while true

    cmd = sprintf(':TRACe4:DATA:TABLe? "%s"', "Ch1EVM");
    fprintf(pcvsa, cmd);

    evmPercent = str2double(fscanf(pcvsa));

    % You calculate EVM in dB here
    if ~isnan(evmPercent) && evmPercent > 0
        evmDb = db(evmPercent / 100);
    else
        evmDb = NaN;
    end

    % Function only updates graph
    evmState = updateEVMOscillogram(evmState, evmDb, maxPoints);

end