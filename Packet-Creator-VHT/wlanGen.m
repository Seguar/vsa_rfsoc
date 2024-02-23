function packet = wlanGen(Fs, frameLength, bw, mcs, isDataRand)
wavaform = VHT_Creator(mcs, bw, frameLength, Fs/1e6, isDataRand,['']);
wavaform = wavaform(:,1) - wavaform(:,2)*1i;
packet = wavaform/max(wavaform);