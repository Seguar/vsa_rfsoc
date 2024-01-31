function  savevsarecording_m(fileName, data, sampleFreq, centerFreq, sampleBW)
% savevsarecording(fileName, data, sampleFreq, centerFreq)
% creates an 89600-compatible recording file with user-specified
% complex signal data and sample frequency.
%
% fileName is the desired name of the recording file 
%   and should end in .mat. If the fileName is supplied alone
%   (e.g. 'MyRecording.mat') it is saved in the
%   current directory. You may also supply a complete path 
%   (e.g. 'C:\users\me\Documents\MyRecording.mat').
% data is the signal data samples and should be a complex vector.
% sampleFreq is the sample frequency associated with the data.
% centerFreq is the optional center frequency (default is 0)

% halfSpan = sampleFreq / 1.28 / 2;
halfSpan = sampleBW / 2;
InputCenter = 0;
if nargin > 3
    InputCenter = centerFreq;
end
FreqValidMax = halfSpan + InputCenter;
FreqValidMin = -halfSpan + InputCenter;
InputRange = 1;
InputRefImped = 50;
InputZoom = uint8(1);
XDelta = 1 / sampleFreq;
XDomain = int16(2);
XStart = 0;
XUnit = 'Sec';
YUnit = 'V';

channels = size(data, 2);
if channels > 64
    channels = size(data, 1);
end

for i=1:channels
   eval(['Y' num2str(i) '_' num2str(channels) ' = single(data(:, i));'])
   eval(['FreqValidMax' num2str(i) ' = FreqValidMax;'])
   eval(['InputCenter' num2str(i) ' = InputCenter;'])
   eval(['InputRefImped' num2str(i) ' = InputRefImped;'])
end

clear i
clear v
clear data 
clear sampleBW
clear centerFreq
clear sampleFreq
clear halfSpan
clear channels

save(fileName)