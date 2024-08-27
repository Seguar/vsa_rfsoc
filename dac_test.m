clc
close all
clear
%%
% Parameters
numSamples = 500; % Number of samples
Fs = 250e6; % Sampling frequency in Hz
t = (0:numSamples-1)/Fs; % Time vector

% CW Signal Parameters
fc = 4800e6;
freqs = [fc, fc, fc, fc]; % Frequencies of the CW signals in Hz
amplitudes = [1, 0.8, 0.6, 0.4]; % Amplitudes of the CW signals
phases = [0, 0, 0, 0]; % Phases of the CW signals

% IQ Matrix Initialization
IQ_matrix = zeros(4, numSamples); % 4 rows for each CW signal

% Generate CW Signals and store them in the matrix
for i = 1:4
    I = amplitudes(i) * cos(2 * pi * freqs(i) * t + phases(i));
    Q = amplitudes(i) * sin(2 * pi * freqs(i) * t + phases(i));
    IQ_matrix(i, :) = I + 1i * Q; % Store the IQ signal in the matrix
end

% Combine the rows of the matrix to form the final IQ array
IQ = sum(IQ_matrix, 1);

% Plot the real and imaginary parts of the IQ array
figure;
% subplot(2,1,1);
plot(t, real(IQ_matrix));
title('Original');
xlabel('Time (s)');
ylabel('Amplitude');
% hold on
% subplot(2,1,2);
% plot(t, imag(IQ_matrix));
% title('Imaginary Part (Quadrature Component)');
% xlabel('Time (s)');
% ylabel('Amplitude');

% % Plot the constellation
% figure;
% plot(real(IQ), imag(IQ), '.');
% title('IQ Constellation');
% xlabel('In-Phase');
% ylabel('Quadrature');
% grid on;
IQ_matrix = IQ_matrix.';

%% ULA gen
fcAnt = 4800e6;
ula = phased.ULA('NumElements', 4);
num_elements = 4;
c = physconst('LightSpeed');

% ula = antPrep(num_elements, c, fcAnt);
%% DAC gen
% app.dacAngle = app.AngleSpinner.Value;
dacAngle = -45;

beamforming = phased.SteeringVector('SensorArray',ula);
weight = beamforming(fcAnt, dacAngle);
%%
% weight = weight/weight(1);
dphase = rad2deg(angle(weight).')
% dphase = round(unwrap(dphase), 2)
IQ_matrixNew = IQ_matrix.*weight.';
figure;
% subplot(2,1,1);
plot(t, real(IQ_matrixNew));
title('DAC');
xlabel('Time (s)');
ylabel('Amplitude');
%% DOA estimation
estimator = phased.MVDREstimator('SensorArray',ula,...
    'OperatingFrequency',fc,'ScanAngles',-90:90,...
    'DOAOutputPort',true);
[~, estimated_angle] = estimator(IQ_matrixNew'*IQ_matrixNew)
%% DOA Corrections
% [IQ_matrixAdj, weights] = steerBf(IQ_matrix.', dacAngle, ula, fc);
[IQ_matrixAdj, weights] = steerBf(IQ_matrixNew, -estimated_angle, ula, fc);

figure;
% subplot(2,1,1);
plot(t, real(IQ_matrixAdj));
title('DOA corr');
xlabel('Time (s)');
ylabel('Amplitude');