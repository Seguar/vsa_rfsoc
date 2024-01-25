function [packet] = Signal_Gen(Fs)
    
    % addpath([pwd '\Packet-Creator-VHT']);

    outputPower     = 10; %[dBm]
    % Fs              = 64e9/24/44;%[Hz]
%     Fs              = 640e6;%[Hz]
%     Fs              = 61.44e6;%[Hz]
%     Fs              = 60e6;%[Hz]
%     Fs              = 30e6;%[Hz]
%     Fs              = 62.5e6;%[Hz]
%     Fs              = 150e6;%[Hz]
%     Fs              = 4e9;%[Hz]

    frameLength     = 500; %1e3; % 5e3;
    BW              = 20;%[MHz]
    MCS             = 4; %9
    isDataRand = 1;
    % fname = ['Ms_MCS',num2str(MCS),'_short_ver2'];
    fname = ['Ms_MCS',num2str(MCS)]; 

    %wavaform        = VHT_Creator(MCS, BW, frameLength, Fs/1e6, isDataRand,[pwd '\',num2str(BW),'MHz_',num2str(Fs*1e-6),fname,'.csv']);
    wavaform        = VHT_Creator(MCS, BW, frameLength, Fs/1e6, isDataRand,['']);
    rawSignal       = [zeros(1,1); wavaform(:,1) + 1i.*wavaform(:,2); zeros(floor(length(wavaform(:,1))*0.1),1)];
    refSignal_norm  = rawSignal./rms(rawSignal);
    refSignal       = refSignal_norm.*dBm2V(outputPower);

    % figure
    %     hold on
    %   spectrumAnalyzer(refSignal, Fs, 'r');
    %     xlim([-5000 5000]);
    %     ylim([-90 0]);
%         legend('Ideal Signal');
%         grid minor
%         hold off
    packet = wavaform;
    % packet = csvread([num2str(BW),'MHz_',num2str(Fs*1e-6),fname,'.csv']);
    %save([num2str(BW),'MHz',num2str(Fs*1e-6),fname,'.mat'],'packet');

end