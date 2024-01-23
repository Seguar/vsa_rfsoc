function rfsocBf(app, vsa, ch, bf, off, gap, cutter, ang_num, estimator, data_v, tcp_client, plot_handle)
% z_num = 0;
test_z = zeros(1, gap);
% ang_num = 1;
%
% cutter = 1; % For OFDM sials
% bf = 1;
% vsa = 1;
% ch = 1;

setupFile = 'ofdm_iq_20_cal.setx'; %1ch_ddc_len.setx iqtools_ofdm_qam16_200
bw = 20e6;
fc = 5.7e9;
fsRfsoc = 125e6;
dataChan = 2^14; % Samples per channel (buffer size)

c = physconst('LightSpeed'); % propagation velocity [m/s]
lambda = c / fc; % wavelength
d = lambda/2; % spacsing antenna elemnts
min_ang = -90; % min scanning angle
max_ang = 90; % max scanning angle
scan_res = 1; % scan resolution
scan_axis = min_ang:scan_res:max_ang; % angles axis
num_elements = 4;
ula = phased.ULA('NumElements',num_elements,'ElementSpacing',d, 'ArrayAxis','y');

%% AFunctions
cPhSh = @(a) 360*(lambda/2)*sind(a)/lambda; % Calculation of constant phase shift between elements
deg2comp = @(a) exp(1i*deg2rad(a)); % Degrees to complex (1 round) convertion

%% Plot



%% TCP prep
data_size = dataChan * 8;
data_size_bytes = typecast(uint64(data_size), 'uint8');

channels = 8;
raw = zeros(channels, data_size / 8);
% Define the server IP and port (should match the server settings)
server_ip = 'pynq'; % Use the appropriate IP address or hostname
server_port = 4000; % Use the same port number used in the Python server
dataLen = data_size/channels;
%% TCP
rawData = tcpDataRec(tcp_client, data_size, channels);
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

if ch>4
    if bf
        rawSum = sum(rawDataAdj, 2);
    else
        rawSum = sum(rawData, 2);
    end
else
    if bf
        rawSum = rawDataAdj(:,ch);
    else
        rawSum = rawData(:,ch);
    end
end

%% Cutter
if (cutter)
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
        %             off = 150;
        cut_b = fb_lines(n)-off;
        cut_e = fe_lines(n)+off;
        if cut_b < 1
            cut_b = 1;
            if size(fb_lines) > 1
                n = 2;
                cut_b = fb_lines(n)-off;
                cut_e = fe_lines(n)+off;
            else

            end
%             continue
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


%% plot
% txt = [newline newline '\uparrow' newline num2str(estimated_angle(1)) char(176)];
title(['Direction of arrival', '   ||   Estimated angle = ' num2str(estimated_angle(1))]);
% set(plot_handle, 'YData', (yspec)/max((yspec)));
set(plot_handle, 'YData', yspec);
% plot(app.UIAxes, estimated_angle(1), 1, '.', MarkerSize=30);

% h = get(gca, 'Children');
% if clCnt >= dotsNum
%     delete(h(dotsNum+1))
% else
%     clCnt = clCnt +1;
% end
drawnow limitrate


%% VSA
if (vsa)
    buff = zeros(size(rawSum));
    buff(cutInds) = steering;
    vsaSendData(buff, data_v)
end

