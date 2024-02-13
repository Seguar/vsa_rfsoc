function sigFilt = filtSig(sig, fs, bw)
    fStep = fs/length(sig);
    sigFd = fftshift(fft(sig));
    sigNewLim = round((fs/2-bw)/fStep:(fs/2+bw)/fStep);
    sigNew = zeros(size(sig));
    sigNew(sigNewLim,:) = sigFd(sigNewLim,:);
    sigFilt = ifft(ifftshift(sigNew));
