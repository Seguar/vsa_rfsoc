clear
close all
clc
clf
%%

% addpath 'C:\Users\sega-\OneDrive\Documents\MATLAB\Packet-Creator-VHT\'
% addpath 'C:\Users\Sergei\Documents\HFIC'
% figure;
set(0,'DefaultFigureWindowStyle','docked')
% plotbrowser
% drawnow
ch = 1;
setupFile = 'ofdm_iq_20_cal.setx'; %1ch_ddc_len.setx iqtools_ofdm_qam16_200 ז
dbmin = 27;
dbmax = 60;
gain = 0; % Pluto gain -89:0
ang_num = 1;
%% Constants
draw_plot = 1;
debug = 0;
pluto = 0;
cutter = 1; % For OFDM sials
bf = 1;
vsa = 1;
Raw_sum_flag = 0;
steering_flag = 1;
bw = 20e6;

fcPluto = 5.7e9;

fc = fcPluto;
fsRfsoc = 125e6;
% dataChan = 2^15; % Samples per channel (buffer size)
% dataChan = 49152; % Samples per channel (buffer size)
dataChan = 2^14; % Samples per channel (buffer size)
% dataChan = 2e4; % Samples per channel (buffer size)
cutInds = 1:dataChan;

% dataChan = 2^17; % Samples per channel (buffer size)
ovp = 0.0; % percent of overlapping samples [0,1]
c = physconst('LightSpeed'); % propagation velocity [m/s]
lambda = c / fcPluto; % wavelength
d = lambda/2; % spacsing antenna elemnts
min_ang = -90; % min scanning angle
max_ang = 90; % max scanning angle
scan_res = 1; % scan resolution
% scan_res = 2.5; % scan resolution
scan_axis = min_ang:scan_res:max_ang; % angles axis
num_elements = 4;
wavelength = physconst('LightSpeed')/fc;
ula = phased.ULA('NumElements',num_elements,'ElementSpacing',d, 'ArrayAxis','y');
yspec_new = zeros(10, length(scan_axis));
weights = zeros(4,1);

blank = zeros(dataChan, 1);
%% AFunctions
cPhSh = @(a) 360*(lambda/2)*sind(a)/lambda; % Calculation of constant phase shift between elements
deg2comp = @(a) exp(1i*deg2rad(a)); % Degrees to complex (1 round) convertion
powCalc = @(x) round(max(db(fftshift(fft(x))))/2, 1); % Power from FFT calculations
splt = @(x) [num2str(fix(x)) '_' num2str(abs(rem(x,1)*10))]; % Separates Numbers Left & Right Of The Decimal

%% Plot
clCnt = 0;
dotsNum = 10;
set(0,'DefaultFigureWindowStyle','docked')
% subplot(2,1,1)
% drawnow
hold on;
grid minor;
axis tight;
yspec = zeros(1, length(scan_axis));
txtPlt = text(0, 0, '', 'Color', 'blue', 'FontSize', 14);
plot_handle = plot(scan_axis, yspec);
ylim([0 1.2])
xlim([min_ang max_ang])

xlabel('\Theta^o');
ylabel('Power_{MVDR}');

% subplot(2,1,2)

%%
fc_v = 0;
sr_v = fsRfsoc;
bw_v = fsRfsoc;
channelCount = 1;
[data_v] = vsaDdc(fc_v, sr_v, bw_v, dataChan, 1, setupFile);
% [data_v] = vsaDdc(fc_v, sr_v, bw_v, 8e3, 1, setupFile);
% [data_v] = vsaDdc(fc_v, sr_v, bw_v, 15e3, 1, setupFile);

%% Pluto tx data
pre_mcs = 16e-6;
fs_Signal = 60e6;
fsPluto = fs_Signal; % Should be same as fs_Signal
zeros_N =  1500; %10e4;     % Zeros between packets

% [packet] = Signal_Gen(fs_Signal);
% sig_org = (packet(:,1)-1j*packet(:,2));
% sig_norm = sig_org/max(abs(sig_org))';
% sig_norm_ = resample(sig_norm, fsRfsoc, fsPluto);
% sigLen = length(sig_norm_);
% sigLen = sigLen - 1000;
% sig_new    = [sig_norm; zeros(zeros_N,1)];
% sig_new_ = resample(sig_new, fsRfsoc, fsPluto);
% fullLen = length(sig_new_);
%
% pre_mcs_points = ceil(pre_mcs/(1/fsRfsoc));
% sigRef = sig_new_(1:pre_mcs_points);

offMagic = 300;
% offMagic = 0;
cutCoef = 0.9;
%% CW
sw = dsp.SineWave;
sw.Amplitude = 1;
sw.Frequency = 0;
sw.ComplexOutput = true;
sw.SampleRate = fs_Signal;
sw.SamplesPerFrame = 50000;
txWaveform = sw();
%%
if pluto == 1
    tx = sdrtx('Pluto');
    tx.ShowAdvancedProperties = true;
    tx.CenterFrequency = fcPluto;
    tx.BasebandSampleRate = fsPluto;
    tx.Gain = gain;
    %     release(tx)

    transmitRepeat(tx,sig_new);
    %     transmitRepeat(tx,txWaveform);
end
%% TCP prep
data_size = dataChan * 8;
data_size_bytes = typecast(uint64(data_size), 'uint8');

channels = 8;
raw = zeros(channels, data_size / 8);
% Define the server IP and port (should match the server settings)
server_ip = 'pynq'; % Use the appropriate IP address or hostname
server_port = 4000; % Use the same port number used in the Python server
dataLen = data_size/channels;
%% Main
num = 1;
estimator = phased.MVDREstimator('SensorArray',ula,...
    'OperatingFrequency',fc,'ScanAngles',scan_axis,...
    'DOAOutputPort',true,'NumSignals',1);

tcp_client = tcpclient(server_ip, server_port);
curr_data_size = dataChan * 8;
curr_data_size_bytes = typecast(uint64(curr_data_size), 'uint8');
write(tcp_client, curr_data_size_bytes);
%% Transmit
while(true)
    %% TCP
    if (debug)
        disp('----------------------------')
        tic
    end
    rawData = tcpDataRec(tcp_client, data_size, channels);
    if (debug)
        disp('rec time:')
        toc
    end
    %% Matlab MVDR FUNC
    [yspec, estimated_angle] = estimator(rawData'*rawData);
    %% Angles
    df = cPhSh(-estimated_angle(ang_num));
    an(1) = 1;
    an(2) = deg2comp(df*1);
    an(3) = deg2comp(df*2);
    an(4) = deg2comp(df*3);
    rawDataAdj(:,1) = rawData(:,1)*an(1);
    rawDataAdj(:,2) = rawData(:,2)*an(2);
    rawDataAdj(:,3) = rawData(:,3)*an(3);
    rawDataAdj(:,4) = rawData(:,4)*an(4);
    rawSum = sum(rawDataAdj, 2);

    %% Cutter
    %     offMagic = 8000;
    %     cutCoef = 0.95;
    if not(bf)
        rawSum = rawData(:,ch);
    end
    if (cutter)
        %         [cutInds] = sigCutter(rawSum, sigRef, cutCoef, offMagic, sigLen, cutInds);
        %         [sig, fb_lines, fe_lines, f_len, f_wid] = sigFinder(rawSum, 1, 100);
        %         cutInds = fb_lines(1)-5:fe_lines(end-1)+5;
        % if isempty(fb_lines)
        %     continue
        % end
        % cutInds = fb_lines(2):fe_lines(2);
        [sig, fb_lines, fe_lines, f_len, f_wid] = sigFinder(rawSum, 1, 100);
        if isempty(fb_lines)
            cutInds = 1:dataChan;
%             continue
        else 
        if size(fb_lines) > 1
            n = 2;
        else 
            n = 1;
        end
%         off = 500;
        off = 150;
        cut_b = fb_lines(n)-off;
        cut_e = fe_lines(n)+off;
        if cut_b < 1
            cut_b = 1;
            continue
        end
        if cut_e > dataLen
            cut_e = dataLen;
        end
        cutInds = cut_b:cut_e;
        end


    else cutInds = 1:dataChan;
    end
    steering = rawSum(cutInds);
    
    rawData_no_noise = rawData(cutInds,:);
    %% Matlab MVDR FUNC
    %     maxEig = max(eig(rawData_no_noise'*rawData_no_noise));

    beamformer = phased.MVDRBeamformer('SensorArray',ula,...
        'PropagationSpeed',c,'OperatingFrequency',fc,...
        'Direction',[estimated_angle(ang_num);0],'WeightsOutputPort',true, ...
        'TrainingInputPort',false, 'DiagonalLoadingFactor', 2);
    [bfs,w_est_ang2] = beamformer(rawData);

    dataCut = sum(rawData_no_noise.*w_est_ang2',2);

    %% plot
    if (draw_plot)
        %     subplot(2,1,1)
        %     name = ['Estimated angle = ' num2str(scan_axis(idx))];
        txt = [newline newline '\uparrow' newline num2str(estimated_angle(1)) char(176)];
        %     set(txtPlt, 'String', txt, 'Position', [estimated_angle, max(yspec)]);
        title(['Direction of arrival', '   ||   Estimated angle = ' num2str(estimated_angle(1))]);
        set(plot_handle, 'YData', (yspec)/max((yspec)));
        plot(estimated_angle(1), 1, '.', MarkerSize=30);
        %     set(gca 'Ylim', [-5 1])
        %     legend(name, 'Location', 'none', 'FontSize', 12)
        %     legend('boxoff')
        % Save only dotsNum amount of dots
        h = get(gca, 'Children');
        if clCnt >= dotsNum
            delete(h(dotsNum+1))
        else
            clCnt = clCnt +1;
        end
        %     subplot(2,1,2)
        drawnow limitrate
    end
    df1 = cPhSh(-0);
    an1(1) = 1;
    an1(2) = deg2comp(df1);
    an1(3) = deg2comp(df1);
    an1(4) = deg2comp(df1);
    %     p1 = pattern(ula,fc,scan_axis,0,'PropagationSpeed',c,'CoordinateSystem','rectangular','Type','directivity', 'Weights',double(w_est_ang2));
    %     p2 = pattern(ula,fc,scan_axis,0,'PropagationSpeed',c,'CoordinateSystem','rectangular','Type','directivity', 'Weights',double(an'));
    %     p3 = pattern(ula,fc,scan_axis,0,'PropagationSpeed',c,'CoordinateSystem','rectangular','Type','directivity', 'Weights',double(an1'));
    %     plot(scan_axis, p1, scan_axis, p2, scan_axis, p3, LineWidth=1.5);
    %     xlim([min_ang max_ang])
    %     ylim([-30, 10]);
    %     legend('MVDR', 'Steering', 'Base summation')
    %     xlabel('\Theta^o');
    %     ylabel('Power_{MVDR}');
    %     grid minor;


    %% Save and Play
    angl = splt(estimated_angle(1));
    name = ['Angle_' num2str(angl) '_Power_' num2str(fix(powCalc(dataCut)))];
    %     input('Next measurments')
    % disp(name)
    if (debug)
        disp('DSP time:')
        toc
    end
    %% VSA
    if (vsa)
        %         if (Raw_sum_flag==1)
        %             VSA_load_m((sum(rawData(cutInds,:), 2)), fsRfsoc,pcvsa, ['Raw_Sum_' name], bw)
        %         elseif (steering_flag==1)
        %             VSA_load_m(steering, fsRfsoc,pcvsa, ['Steering_' name], bw)
        %         else
        %             VSA_load_m((rawData(cutInds,4)), fsRfsoc,pcvsa, ['Raw_4ch_' name], bw)
        %         end
        %             input('Next measurments')
        %         samples = userInput.Data.RequiredSamples;
        %         sendDataBlockSize = samples;
        %     sendBuffer = getDataOnce(sendDataBlockSize);
        %     steering = steering(1:sendDataBlockSize*100);
        %         z_num = 5000;
        %         z_num = 35000;
        z_num = 0;
        test_z = zeros(1, z_num);
        buff = zeros(size(rawSum));
        buff(cutInds) = steering;
        steering = buff;
        sendBuffer = zeros(1, length(steering)*2);
        sendBuffer(1:2:end) = real(steering);
        sendBuffer(2:2:end) = imag(steering);
        sendBuffer = [test_z sendBuffer test_z];

        % userInput.Data.SendData(single(sendBuffer));
        data_v.Channels.Item(0).ClearData();
        data_v.Channels.Item(0).SendData(single(sendBuffer))
    end
    %% DEBUG


    if (debug)
        disp('full time:')
        toc
        clf
        buff = zeros(size(rawSum));
        %     figure
        % plot(real(sigRec));
        hold on
        plot(abs(rawSum));
        buff(cutInds) = rawSum(cutInds);
        plot(abs(buff));
        input('')
    end
end


