function arduino_prog()
Arduino = [];
if (isempty(Arduino))
    Arduino = serialport("COM14",115200); %Change the COM number according to the available ports
end
    pause(0.8)
try 
    writeline(Arduino,"P")
    pause(0.2)
    while (Arduino.NumBytesAvailable > 0)
        disp(readline(Arduino)) 
    end
catch
    disp("Arduino, not connected")
end
% serialportlist("available")
% Arduino=[]
%% Controllers

RM2       = 5 ; % Rmiller of BB stage 2 OpAmp          0:0      1:5    15:75   Ohm      4Bits
R3        = 3 ; % R3 of BB stage 2 Rauch filter        0:0.25k  1:0.5k 7:2k   Ohm       3Bits
C2        = 2 ; % C2 of BB stage 2 Rauch filter        0:0  1:375f 7:2k   Ohm       3Bits                                                                                                                                                                                                            C2        = 1 ; % C2 of BB stage 2 Rauch filter        0:0      1:350  7:2450 fF         3Bits
C1        = 14 ; % C1 of BB stage 2 Rauch filter        0:0      1:0.5   15:15.5 pF        5Bits
CM2       = 2 ; % Cmiller of BB stage 2 OpAmp          0:0      1:420  7:2940  fF        3Bits
R1        = 0 ; % R1 of BB stage 2 Rauch filter        0:125    1:250 Ohm               1Bits
R2        = 0 ; % R2 of BB stage 2 Rauch filter        0:125    1:250 Ohm               1Bits
CF        = 0 ; % CF of BB stage 1 Rauch TIA           0:0      1:350  7:2450 fF         3Bits
RF        = 4 ; % RF of BB stage 1 rauch TIA           0:250    1:500  15:4000 Ohm      4Bits
CBB       = 15; % CBB of BB stage 1 Rauch TIA          0:0      1:0.5  31:15.5 pF        5Bits
CM        = 4 ; % Cmiller of BB stage 1 OpAmp          0:0      1:420  15:6300  fF       4Bits
RM        = 2 ; % Rmiller of BB stage 1 OpAmp       -   0:0      1:5    15:75 Ohm        4Bits
RX4_DAC_I = 42; % RX4 I DAC for DC offset correction   0:262 1:254 63:-258 mV    6Bit
RX4_DAC_Q = 33; % RX4 Q DAC for DC offset correction   0:262 1:254 63:-258 mV    6Bit
RX3_DAC_I = 41; % RX3 I DAC for DC offset correction   0:262 1:254 63:-258 mV    6Bit
RX3_DAC_Q = 30; % RX3 Q DAC for DC offset correction   0:262 1:254 63:-258 mV    6Bit
RX2_DAC_I = 45; % RX2 I DAC for DC offset correction   0:262 1:254 63:-258 mV    6Bit
RX2_DAC_Q = 34; % RX2 Q DAC for DC offset correction   0:262 1:254 63:-258 mV    6Bit
RX1_DAC_I = 51; % RX1 I DAC for DC offset correction   0:262 1:254 63:-258 mV    6Bit
RX1_DAC_Q = 34 ; % RX1 Q DAC for DC offset correction   0:262 1:254 63:-258 mV    6Bit
VC        = 1 ; % Toggle high frequency mode for the demodulator's divider 0 for LO<=1 GHz, 1 for LO>=1 GHz 1Bit
%% RUN
data1 = strcat(num2str(reshape(int2bit(RM2,4,0)', 1,[])),",",...
               num2str(reshape(int2bit(R3 ,3,0)' , 1,[])),",",...
               num2str(reshape(int2bit(C2 ,3,0)' , 1,[])),",",...
               num2str(reshape(int2bit(C1 ,5,0)' , 1,[])),",",...
               num2str(reshape(int2bit(CM2,3,0)', 1,[])),",",...
               num2str(reshape(int2bit(R1 ,1,0)' , 1,[])),",",...
               num2str(reshape(int2bit(R2 ,1,0)' , 1,[])),",",...
               num2str(reshape(int2bit(CF ,3,0)' , 1,[])),",",...
               num2str(reshape(int2bit(RF ,4,0)' , 1,[])),",",...
               num2str(reshape(int2bit(mod(CBB,8),3,0)', 1,[])));
data1 = strrep(data1,' ','');
data1 = strrep(data1,',','');
disp(["DATA1=" reverse(data1)])

data2 = strcat(num2str(reshape(int2bit(fix(CBB/8),2,0)', 1, [])),",",...
               num2str(reshape(int2bit(CM,       4,0)' , 1, [])),",",...
               num2str(reshape(int2bit(RM,       4,0)' , 1, [])),",",...
               num2str(reshape(int2bit(RX4_DAC_I,6,0)' , 1, [])),",",...
               num2str(reshape(int2bit(RX4_DAC_Q,6,0)' , 1, [])),",",...
               num2str(reshape(int2bit(RX3_DAC_I,6,0)' , 1, [])),",",...
               num2str(reshape(int2bit(mod(RX3_DAC_Q,4),2,0)', 1,[])));
data2 = strrep(data2,' ','');
data2 = strrep(data2,',','');
disp(["DATA2=" reverse(data2)])

data3 = strcat(num2str(reshape(int2bit(fix(RX3_DAC_Q/4),4,0)', 1,[])),",",...
               num2str(reshape(int2bit(RX2_DAC_I,6,0)'       , 1, [])),",",...
               num2str(reshape(int2bit(RX2_DAC_Q,6,0)'       , 1, [])),",",...
               num2str(reshape(int2bit(RX1_DAC_I,6,0)'       , 1, [])),",",...     
               num2str(reshape(int2bit(RX1_DAC_Q,6,0)'       , 1, [])),",",... 
               num2str(reshape(int2bit(VC,       1,0)'       , 1, [])),",",... 
               num2str(reshape(int2bit(0,       1,0)'       , 1, [])));
data3 = strrep(data3,' ','');
data3 = strrep(data3,',','');
disp(["DATA3=" reverse(data3)])


%% Load Data to Arduino
pause(1)
writeline(Arduino,"2")
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end
writeline(Arduino,reverse(data1))
pause(1)
writeline(Arduino,"2")
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end
writeline(Arduino,reverse(data1))
pause(1)
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end
pause(1)

writeline(Arduino,"3")
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end
writeline(Arduino,reverse(data2))
pause(1)
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end
pause(1)
writeline(Arduino,"4")
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end
writeline(Arduino,reverse(data3))
pause(1)
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end
pause(0.5)
writeline(Arduino,"Q")
pause(0.5)
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end

%% Arduino Transmitt
writeline(Arduino,"T")
pause(0.5)
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end
pause(0.5)
while (Arduino.NumBytesAvailable > 0)
    disp(readline(Arduino)) 
end