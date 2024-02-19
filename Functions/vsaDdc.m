function [data_v] = vsaDdc(fc_v, sr_v, bw_v, dataLen, channelCount, setupFile)
%% 1. Connect to VSA
asmPath = 'C:\Program Files\Keysight\89600 Software 2024\89600 VSA Software\Examples\DotNET\Interfaces\';
addpath(asmPath)

asmName = 'Agilent.SA.Vsa.Interfaces.dll';
asm = NET.addAssembly(strcat(asmPath, asmName));
import Agilent.SA.Vsa.*;

vsaApp = ApplicationFactory.Create();
if (isempty(vsaApp))
    wasVsaRunning = false;
    vsaApp = ApplicationFactory.Create(true, '', '', -1);
    disp('New')
else
    wasVsaRunning = true;
    disp('Old')
end
% Make VSA visible
vsaApp.IsVisible = true;
% Get interfaces to major items
vsaMeas = vsaApp.Measurements.SelectedItem;
vsaDisp = vsaApp.Display;
vsaFreq = vsaMeas.Frequency;
vsaFreq.Center = fc_v;
vsaFreq.Span = bw_v;
vsaSrc = vsaApp.Sources;

%% 2. Create and Select Direct Data Configuration

hardwareConfigurationName = "DirectDataSource";

hardwareConfiguration = vsaApp.Hardware.Configurations.Item(hardwareConfigurationName);
if (isempty(hardwareConfiguration))
    hardwareConfiguration = vsaApp.Hardware.Configurations.Create(hardwareConfigurationName);
end
instrumentAddress = "USR::Stream";
%
hardwareConfiguration.Groups.Clear();
% %
hardwareConfiguration.Groups.Create(instrumentAddress);
% %
hardwareConfiguration.Groups.ApplyChanges();

%% 3. Set Up the UserInput Properties

userInput = vsaApp.Measurements.SelectedItem.SelectedAnalyzer.Groups.Item(0).UserInput;
if (not(isempty(userInput)) && userInput.Enabled)
    disp('userInput.Enabled')
else
    disp('Please select DirectDataSource Analyzer in VSA software')
    return
end

data_v = userInput.Data;
configName = vsaApp.Measurements.SelectedItem.SelectedAnalyzer.Groups.Item(0).Name;



userInput.Setup.IsImmediateChangesEnabled = false;


userInput.ChannelCount = channelCount;

Mask = NET.createArray('Agilent.SA.Vsa.UserInputChangeBits', 1);
Mask(1) = Agilent.SA.Vsa.UserInputChangeBits.IsRequiredSamplesPositive;
userInput.UserInputChange.Mask = Mask(1);
% userInput.changebits
userInput.Setup.SetFrequencyParameters(true, fc_v, sr_v, bw_v);

userInput.Setup.CaptureSizeMaximum = dataLen;
% userInput.Setup.IsContinuousCapable = false;
userInput.Setup.IsContinuousCapable = true;
userInput.Setup.ApplyChanges();
vsaApp.Title = ['Measurement Demo fc ' num2str(fc_v/1e6) ];
vsaApp.Measurements.SelectedItem.IsContinuous = false;
vsaApp.Measurements.SelectedItem.Restart();
samples = userInput.Data.RequiredSamples;
changed = userInput.UserInputChange.Value;
if not(isempty(instrfind))
    delete(instrfind)
end
format long g
pcvsa = visa('keysight', 'TCPIP0::localhost::hislip_vsa0::INSTR');
fopen(pcvsa)
fprintf(pcvsa, sprintf(':MMEMory:LOAD:SETup "%s"', [pwd '\' setupFile]));