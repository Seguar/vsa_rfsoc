function driver = iqdownload_M5301x(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, chMap, sequence)
% download a waveform to the M5301x
%
% This routine is NOT intended to be called directly from a user script
% It should only be called via iqdownload()
%
% Benjamin Krueger, Keysight Technologies 2023
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 


% keep the driverHandle as a global variable so that the value is kept across
% multiple calls to this function.
global driverHandle;
driver = [];
% set to true to open the soft front panel while the session is connected
openSFP = true;

% clock sources
KTM5301X_VAL_CLOCK_SOURCE_EXTERNAL = 0;
KTM5301X_VAL_CLOCK_SOURCE_INTERNAL = 1;

% sequencing is not supported 
if (~isempty(sequence))
    errordlg('Sequencing is not yet implemented for the M5301x');
    return;
end

% check, if driver has been called before and the device is still connected
if (fs >= 0 && ...
        (~exist('driverHandle', 'var') || ...
         isempty(driverHandle) || ...
         ~isa(driverHandle, 'icdevice') || ...
         ~isvalid(driverHandle) || ...
         ~strcmp(driverHandle.Status, 'open')))
    % this can take quite some time. The dialog box will be closed when
    % hMsgBox goes out-of-scope, i.e. upon return from iqdownload_M5300x()
    hMsgBox = iqwaitbar('Opening M5301x driver, please wait...', 'Please wait...');
    % Create and install the MATLAB Instrument Driver
    mddName = 'KtM5301x_IVI-C.mdd';
    try
        makemid('KtM5301x', fullfile(toolboxdir('instrument'), 'instrument', 'drivers', mddName), 'IVI-C');
    catch
        errordlg('Cannot find IVI-C driver for KtM5301x. Please check that the M5301x software has been installed properly.');
        return;
    end
    hMsgBox.update(0.2);

    % Initialize the instrument device object.  Resource is ignored if option Simulate=true
    resourceName = arbConfig.visaAddr;
    if (contains(resourceName, 'OFFLINE'))
        simulate = 'true';
    else
        simulate = 'false';
    end
    initOptions = strcat('QueryInstrStatus=false, Simulate=', simulate);
    driverHandle = icdevice(mddName, resourceName, 'optionstring', initOptions);
    hMsgBox.update(0.4);

    % Connect to the instrument using the device object created above
    try
        connect(driverHandle);
    catch
        errordlg(sprintf(['Cannot connect to M5301x at %s.' ...
            'Please check the VISA address in the instrument configuration window.' ...
            'Also, make sure that no other software (e.g. the Softfrontpanel) is using the module.'], resourceName));
        return;
    end
    hMsgBox.update(0.6, 'Click Cancel to run without SFP');
    cnt = 0;
    while (cnt < 20 && ~hMsgBox.canceling())
        pause(0.1);
        hMsgBox.update(0.6 + cnt / 20 * 0.2);
        cnt = cnt + 1;
    end
    if (openSFP && ~hMsgBox.canceling())
        hMsgBox.update(0.8, 'Launching SFP, please wait...');
        invoke(driverHandle.InstrumentSpecificSystemSfp, 'SystemSfpOpen');
        driverHandle.InstrumentSpecificSystemSfpAutoRefresh.Enabled = 0;
        driverHandle.InstrumentSpecificSystemSfpAutoRefresh.Period = 0.5;
        driverHandle.InstrumentSpecificSystemSfp.ControlsEnabled = 1;
    end
    try delete(hMsgBox); catch; end
end
driver = driverHandle;

if (fs == 0)
    % fs == 0 means: just connect to the driver, no waveform download
    return;
elseif (fs < 0)
    % fs < 0 means: close the driver
    hMsgBox = iqwaitbar('Closing M5301x driver, please wait...', 'Please wait...');
    try invoke(driverHandle.InstrumentSpecificSystemSfp, 'SystemSfpClose'); catch; end
    try disconnect(driverHandle); catch; end
    delete(driverHandle);
    clear driverHandle;
    try delete(hMsgBox); catch; end
    return;
end 

% set the clock source
if (isfield(arbConfig, 'clockSource'))
    switch (arbConfig.clockSource)
        case 'Unchanged'
            % nothing to do
        case 'IntRef'
            driverHandle.Instrumentspecificclock.CLOCK_SOURCE = KTM5301X_VAL_CLOCK_SOURCE_INTERNAL;
        case 'AxieRef'
            error('unsupported clock mode AxieRef');
        case 'ExtRef'
            driverHandle.Instrumentspecificclock.CLOCK_SOURCE = KTM5301X_VAL_CLOCK_SOURCE_EXTERNAL;
        case 'ExtClk'
            error('unsupported clock mode ExtClk');
        otherwise error(['unexpected clockSource in arbConfig: ', arbConfig.clockSource]);
    end
end

% download waveforms
chMask = int16(0);
for col = 1:min(size(chMap, 2) / 2, size(data,2))
    for ch = find(chMap(:, 2*col-1))'
        chMask = bitset(chMask, ch);
        downloadWfm(arbConfig, ch, real(data(:,col)), marker1, segmNum);
    end
    for ch = find(chMap(:, 2*col))'
        chMask = bitset(chMask, ch);
        downloadWfm(arbConfig, ch, imag(data(:,col)), marker2, segmNum);
    end
end

% start signal generation for multiple channels
invoke(driverHandle.Instrumentspecificawgmultiple, 'Start', chMask, 0);
checkForErrors();

end


function downloadWfm(arbConfig, ch, data, marker1, segmNum)
global driverHandle;
% trigger modes
KTM5301X_VAL_TRIGGER_MODE_AUTOTRIG = 0; % The waveform does not require any trigger to start, it is launched immediately after AWGStart. 
KTM5301X_VAL_TRIGGER_MODE_SWHVITRIG = 1; % The waveform is triggered by AWGTrigger. 
KTM5301X_VAL_TRIGGER_MODE_EXTTRIG = 2; % The AWG waits for an external trigger. 
KTM5301X_VAL_TRIGGER_MODE_SWHVI_PER_CYCLETRIG = 5; % Identical to SWHVITRIG option, but the trigger is required per each waveform. 
KTM5301X_VAL_TRIGGER_MODE_EXT_PER_CYCLETRIG = 6; % Identical to EXTTRIG option, but the trigger is required per each waveform. 

% playback modes
KTM5301X_VAL_PLAYBACK_MODE_ONE_SHOT = 0;
KTM5301X_VAL_PLAYBACK_MODE_CYCLIC = 1;

chName = invoke(driverHandle.Instrumentspecificchannel, 'GetChannelName', ch - 1, 16);
driverHandle.RepCapIdentifier = chName;
% convert waveform to 16-bit signed integer (data is [-1 ... +1])
dataInt16 = int16(round(32767 * data));
waveformID = int32(segmNum);
invoke(driverHandle.Instrumentspecificchannelarbitrarywaveform, 'ClearWaveformMemory', chName);
invoke(driverHandle.Instrumentspecificchannelarbitrarywaveform, 'CreateInt16', chName, length(dataInt16), dataInt16, waveformID);
driverHandle.Instrumentspecificchannelarbitrarywaveform.PLAYBACK_MODE = KTM5301X_VAL_PLAYBACK_MODE_CYCLIC;
trigMode = KTM5301X_VAL_TRIGGER_MODE_AUTOTRIG;
if (isfield(arbConfig, 'triggerMode'))
    switch (arbConfig.triggerMode)
        case 'SWHVI'; trigMode = KTM5301X_VAL_TRIGGER_MODE_SWHVITRIG;
        case 'External'; trigMode = KTM5301X_VAL_TRIGGER_MODE_EXTTRIG;
        case 'SWHVIPerCycle'; trigMode = KTM5301X_VAL_TRIGGER_MODE_SWHVI_PER_CYCLETRIG;
        case 'ExternalPerCycle'; trigMode = KTM5301X_VAL_TRIGGER_MODE_EXT_PER_CYCLETRIG;
    end
end
startDelay = 0;
numCycles = 0; % infinite
invoke(driverHandle.Instrumentspecificchannel, 'AwgQueueWaveform', chName, trigMode, startDelay, numCycles, waveformID);
% if (isfield(arbConfig,'carrierFrequency'))
%     driverHandle.Instrumentspecificchannelupconverter.LOCAL_OSCILLATOR_FREQUENCY = arbConfig.carrierFrequency;
% end
% Setting the Output Type and starting the AWG is done for all channels together
% driverHandle.Instrumentspecificchannel.OUTPUT_TYPE = getOutputType(arbConfig);
% invoke(driverHandle.Instrumentspecificchannel, 'AwgStart', chName);
driverHandle.Instrumentspecificchannel.Enabled = 1;
end



% Check instrument for errors
function errorNum = checkForErrors()
global driverHandle;
[err, msg] = invoke(driverHandle.Utility, 'ErrorQuery');
% return the first error
errorNum = err;
% check & display further errors
while (err ~= 0)
    disp(['ErrorQuery: ', num2str(err), ', ', msg]);
    [err, msg] = invoke(driverHandle.Utility, 'ErrorQuery');
end
end

