function tx = sdrCtrl(fc, fs, gain, txWaveform, devId)
tx = sdrtx('Pluto', 'RadioID', ['usb:' num2str(devId)]);
tx.ShowAdvancedProperties = true;
tx.CenterFrequency = fc;
tx.BasebandSampleRate = fs;
tx.Gain = gain;

if (size(txWaveform,1) < size(txWaveform,2))
    txWaveform = txWaveform.';
end

if not(isempty(tx))
    transmitRepeat(tx,txWaveform);
end
