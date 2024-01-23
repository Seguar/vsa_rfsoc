function driver = iqdownload_N824xA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)

%driver = iqdownload_N824xA_MDD(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
 driver = iqdownload_N824xA_MEX(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence);
end


% ==== downloader using N6030MEX ===
function driver = iqdownload_N824xA_MEX(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
    % assume that the N8241A software has been installed in the standard path
    addpath('C:\Program Files\Agilent\N8241A\Matlab');

    % [directory,errorN,errorMsg] = N6030MEX('browse');
    visaAddr = arbConfig.visaAddr;
    [instrumentHandle,errorN,errorMsg] = agt_awg_open('TCPIP', visaAddr);
    driver = instrumentHandle;
    if (errorN ~= 0)
        errordlg(sprintf('Cannot open %s', visaAddr));
        return;
    end
    % handle "test connection" - in this case, fs == 0
    if (fs == 0)
        agt_awg_close(instrumentHandle);
        return;
    end
    [errorN,errorMsg] = agt_awg_abortgeneration(instrumentHandle);
    if (errorN ~= 0)
        errordlg(sprintf('Error calling agt_awg_abortgeneration: %s', errorMsg));
        return;
    end
    % [errorN,errorMsg] = agt_awg_clearwaveform(instrumentHandle);
    % if (errorN ~= 0)
    %     errordlg(sprintf('Error calling agt_awg_clearwaveform: %s', errorMsg));
    %     return;
    % end
    [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputenabled', 'true' );
    [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputmode', 'arb' );
    [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'predistortenabled', 'false' );
    if (isfield(arbConfig, 'outputType'))
        switch lower(arbConfig.outputType)
            case 'single ended'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputconfig', 'se' );
            case 'differential'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputconfig', 'diff' );
            case 'amplified'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputconfig', 'amp' );
            otherwise
                errordlg(sprintf('unexpected outputtype: %s', arbConfig.outputType));
        end
    end
    if (isfield(arbConfig, 'filterSettings'))
        switch lower(arbConfig.filterSettings)
            case 'none'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputfilterenabled', 'false' );
            case '500 mhz'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputbw', 500e6);
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputfilterenabled', 'true' );
            case '250 mhz'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputbw', 250e6);
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputfilterenabled', 'true' );
            otherwise
                errordlg(sprintf('unexpected filterSettings: %s', arbConfig.filterSettings));
        end
    end
    if (isfield(arbConfig, 'amplitude'))
       a = fixlength(arbConfig.amplitude, 2);
       for i = 1:2
           [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputgain', a(i), i );
            if (errorN ~= 0)
                errordlg(sprintf('Error calling agt_awg_setstate outputgain for channel %d: %s', i, errorMsg));
                return;
            end
       end
    end
    if (isfield(arbConfig, 'offset'))
       a = fixlength(arbConfig.offset, 2);
       for i = 1:2
            [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'outputoffset', a(i), i );
            if (errorN ~= 0)
                errordlg(sprintf('Error calling agt_awg_setstate outputoffset for channel %d: %s', i, errorMsg));
                return;
            end
       end
    end
    if (isfield(arbConfig, 'clockSource'))
        switch (arbConfig.clockSource)
            case 'Unchanged'
            case 'IntRef'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'refclksrc', 'int' );
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'clksrc', 'int' );
            case 'AxieRef'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'refclksrc', 'pxi' );
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'clksrc', 'int' );
            case 'ExtRef'
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'refclksrc', 'ext' );
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'clksrc', 'int' );
            case 'ExtClk'
                if (fs ~= arbConfig.clockFreq)
                    errordlg(sprintf('Mismatch between external sample clock frequency (%s) and waveform sample rate (%s)', iqengprintf(arbConfig.clockFreq), iqengprintf(fs)));
                end
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'extclkrate', fs );
                [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'clksrc', 'ext' );
            otherwise error(['unexpected clockSource in arbConfig: ', arbConfig.clockSource]);
        end
    end
    [errorN,errorMsg] = agt_awg_setstate( instrumentHandle, 'samplerate', fs );
    if (errorN ~= 0)
        errordlg(sprintf('Error calling setstate samplerate: %s', errorMsg));
        return;
    end
    % data needs to be one column per channel
    datax = zeros(size(data,1), 2);
    for col = 1:size(channelMapping, 2) / 2
        for ch = find(channelMapping(:, 2*col-1))'
            datax(:,ch) = real(data(:,col));
        end
        for ch = find(channelMapping(:, 2*col))'
            datax(:,ch) = imag(data(:,col));
        end
    end
    [wfmhandle,errorN,errorMsg] = agt_awg_storewaveform(instrumentHandle, datax, 0);
    if (errorN ~= 0)
        errordlg(sprintf('Error calling agt_awg_storewaveform: %s', errorMsg));
        return;
    end
    [errorN,errorMsg] = agt_awg_playwaveform(instrumentHandle, wfmhandle);
    if (errorN ~= 0)
        errordlg(sprintf('Error calling agt_awg_playwaveform: %s', errorMsg));
        return;
    end
    [errorN,errorMsg] = agt_awg_initiategeneration(instrumentHandle);
    if (errorN ~= 0)
        errordlg(sprintf('Error calling agt_awg_initiategeneration: %s', errorMsg));
        return;
    end
    [errorN,errorMsg] = agt_awg_close(instrumentHandle);
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, numel(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end





% ==== downloader using AGN6030.mdd ===
% download an IQ waveform to the N824x
% v1.0 - Vinod Cherian, MathWorks
function driver = iqdownload_N824xA_MDD(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
    driver = [];
    if (~isempty(sequence))
        errordlg('Sequence mode is not yet implemented for the N824xA');
        return;
    end
    initOptions = 'QueryInstrStatus=true, simulate=false';
    try
        driver = icdevice('AGN6030A.mdd',arbConfig.visaAddr,'optionstring',initOptions);
    catch e
        errordlg({'Can''t open N824xA device driver (AGN6030A.mdd):' e.message});
        return;
    end
    connect(driver);
    invoke(driver.Actionstatus,'abortgeneration');
    AGN6030A_VAL_OUTPUT_ARB = 1; % From the driver documentation
    set(driver.Basicoperation,'Output_Mode',AGN6030A_VAL_OUTPUT_ARB);
    set(driver.Arbitrarywaveformoutput,'Enables_predistortion_of_waveforms_during_download_to_improve_signal_quality',false);
    %invoke(driver.Configurationfunctionsarbitraryoutputarbitrarysequence,'cleararbmemory')
    for ch = find(channelMapping(:,1))'
        gen_arb_N824x(arbConfig, driver, ch, real(data), marker1, fs, segmNum);
    end
    for ch = find(channelMapping(:,2))'
        gen_arb_N824x(arbConfig, driver, ch, imag(data), marker2, fs, segmNum);
    end
    set(driver,'RepCapIdentifier','')
    set(driver.Arbitrarywaveformoutput,'Sample_Rate',fs);    
    invoke(driver.Actionstatus,'initiategeneration');
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        disconnect(driver); delete(driver);
    end
end


function gen_arb_N824x(arbConfig, driver, chan, data, marker, fs, segm_num)
    set(driver,'RepCapIdentifier',num2str(chan));
    if (isfield(arbConfig, 'ampType'))
        switch arbConfig.ampType
            % 1 = differential, 0 = single ended, 2 = amplified  
            case 'DC'   
                set(driver.Basicoperation,'Output_Configuration',0);
            case 'DAC' 
                set(driver.Basicoperation,'Output_Configuration',1);
            case 'AC'
                set(driver.Basicoperation,'Output_Configuration',2);
        end
    end
    if (isfield(arbConfig,'amplitude'))
        set(driver.Arbitrarywaveformoutput,'Arbitrary_Waveform_Gain',arbConfig.amplitude(chan));
    end
    waveformHandle = invoke(driver.Configurationfunctionsarbitraryoutputarbitrarywaveform,'createarbwaveform',length(data), data);
    arbGain = 0.25; arbOffset = 0;
    try
        invoke(driver.Configurationfunctionsarbitraryoutputarbitrarywaveform,'configurearbwaveform', num2str(chan),waveformHandle,arbGain,arbOffset);
    catch ex
        errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    return;

    end
    set(driver.Basicoperation,'Output_Enabled',true);
end
