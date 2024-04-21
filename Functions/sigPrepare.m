function sigInt16 = sigPrepare(filename, fs_orig, fs_new, bw)
load(filename)
try
    fs_orig = 1/XDelta;
catch
    fs_orig = fs_orig;
end
Y = resample(Y, fs_new, fs_orig);
try
    Y = filtSig(Y, fs_new, bw);
catch
    Y = filtSig(Y.', fs_new, bw).';
end
sigInt16 = zeros(1, length(Y)*2);
sigInt16(1:2:end) = real(Y)*(2^14 - 1);
sigInt16(2:2:end) = imag(Y)*(2^14 - 1);
sigInt16 = int16(sigInt16);
