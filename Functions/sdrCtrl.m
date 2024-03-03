function tx = sdrCtrl(fc, fs, gain, txWaveform, tx)
tx = sdrtx('Pluto');
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
