function f = iqdownload_33xxx(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence)
% download an IQ waveform to the 335xx & 336xx arbitrary waveform generators
% NOTE: This routine should not be called directly, only via iqdownload
    if (~isempty(sequence))
        errordlg('Sequence mode is not yet implemented for the 335xx/336xx');
        f = [];
        return;
    end
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    % remove anything that goes beyond 2 channels
    channelMapping(3:end,:) = [];
    % find out if we have a one-channel or two channel instrument.
    try
        opts = xquery(f, '*idn?');
    catch ex
        errordlg({'Instrument did not respond to *IDN query. Please try again.'
            'If this does not solve the problem, exit and restart MATLAB'
            ['(Error message: ' ex.message]});
        iqreset();
        return;
    end
    last = regexp(opts, '33[56]\d(\d)', 'tokens');
    % if last digit of model number is odd, it is a 1-channel instrument
    % in this case, simply ignore the data for the second channel
    if (isempty(last) || mod(str2double(last), 2) == 1)
        channelMapping(2,:) = [0 0];
    end
    
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        xfprintf(f, '*rst');
    end
    
    % set the skew - depending on whether it is positive or negative, it
    % has to be set on channel1 or channel2. The other one is always zero.
%     if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
%         if (arbConfig.skew >= 0)
%             xfprintf(f, sprintf(':puls:del1 %.12g', arbConfig.skew));
%             xfprintf(f, sprintf(':puls:del2 %.12g', 0));
%         else
%             xfprintf(f, sprintf(':puls:del1 %.12g', 0));
%             xfprintf(f, sprintf(':puls:del2 %.12g', -1.0 * arbConfig.skew));
%         end
%     end

    for ch = find(channelMapping(:,1))'
        gen_arb_33xxx(arbConfig, f, ch, real(data), marker1, fs, segmNum);
    end
    for ch = find(channelMapping(:,2))'
        gen_arb_33xxx(arbConfig, f, ch, imag(data), marker2, fs, segmNum);
    end
    if (~exist('keepOpen') || keepOpen == 0)
        iqclose(f);
    end
end



function gen_arb_33xxx(arbConfig, f, chan, data, marker, fs, segm_num)
% download an arbitrary waveform signal to a given channel and segment
% number. Set the sampling rate to fs
    xfprintf(f, sprintf(':sour%d:func arb', chan));      % switch to arb mode
    % always extend the waveform to the full memory
    % - not sure if this is necessary -
    orig_segm_len = length(data);
%     if (orig_segm_len <= 1024*1024)
%         data = iqresample(data, 1024*1024);
%         fs = fs * orig_segm_len / (1024*1024);
%     end
    segm_len = length(data);
    if (fs ~= 0 && segm_len ~= 0)
        xfprintf(f, sprintf(':sour%d:func:arb:adv srate', chan));
        xfprintf(f, sprintf(':sour%d:func:arb:srate %.15g', chan, fs));
    end
    % segment definition
    if (segm_len > 0)
        xfprintf(f, sprintf(':sour%d:data:volatile:clear', chan), 1);
        % data is assumed to be -1 ... +1
        data = round(32767 * data);

        % make 16-bit integers
        data = int16(data);

        % download an arbitrary waveform
        cmd = sprintf(':sour%d:data:arb:dac IQtools_ARB,', chan);
        xbinblockwrite(f, data, 'int16', cmd);
        xquery(f, '*opc?');
    end
    if (isfield(arbConfig,'amplitude'))
        xfprintf(f, sprintf(':sour%d:volt %g', chan, arbConfig.amplitude(chan)));    
    end
    if (isfield(arbConfig,'offset'))
        xfprintf(f, sprintf(':sour%d:volt:offs %g', chan, arbConfig.offset(chan)));    
    end
    if (chan == 2)
        % when loading data for the second channel, make sure it runs in
        % sync with channel 1
        xfprintf(f, ':func:arb:sync');
    end
    xfprintf(f, sprintf(':outp%d on', chan));             % turn output on
end

