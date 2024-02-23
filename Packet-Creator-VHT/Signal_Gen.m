function [packet] = Signal_Gen(Fs)

    outputPower     = 10; %[dBm]

    frameLength     = 500; %1e3; % 5e3;
    BW              = 20;%[MHz]
    MCS             = 4; %9
    isDataRand = 1;
    % fname = ['Ms_MCS',num2str(MCS),'_short_ver2'];
    fname = ['Ms_MCS',num2str(MCS)]; 

    %wavaform        = VHT_Creator(MCS, BW, frameLength, Fs/1e6, isDataRand,[pwd '\',num2str(BW),'MHz_',num2str(Fs*1e-6),fname,'.csv']);
    wavaform        = VHT_Creator(MCS, BW, frameLength, Fs/1e6, isDataRand,['']);
    rawSignal       = [zeros(1,1); wavaform(:,1) - 1i.*wavaform(:,2); zeros(floor(length(wavaform(:,1))*0.1),1)];
    refSignal_norm  = rawSignal./rms(rawSignal);
    refSignal       = refSignal_norm.*dBm2V(outputPower);

    packet = wavaform;
    % packet = csvread([num2str(BW),'MHz_',num2str(Fs*1e-6),fname,'.csv']);
    %save([num2str(BW),'MHz',num2str(Fs*1e-6),fname,'.mat'],'packet');

end