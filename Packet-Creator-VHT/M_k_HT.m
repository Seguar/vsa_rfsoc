function M = M_k_HT(k,BW_channel)
if BW_channel == 20
    if (sum(k == 0:6) > 0)
        M = k - 28;
    elseif (sum(k == 7:19) > 0)
        M = k - 27;
    elseif (sum(k == 20:25) > 0)
        M = k - 26;
    elseif (sum(k == 26:31) > 0)
        M = k - 25;
    elseif (sum(k == 32:44) > 0)
        M = k - 24;
    elseif (sum(k == 45:56) > 0)
        M = k - 23;
    end
elseif  BW_channel == 40
    if (sum(k == 0:4) > 0)
        M = k - 58;
    elseif (sum(k == 5:31) > 0)
        M = k - 57;
    elseif (sum(k == 32:44) > 0)
        M = k - 56;
    elseif (sum(k == 45:53) > 0)
        M = k - 55;
    elseif (sum(k == 54:62) > 0)
        M = k - 52;
    elseif (sum(k == 63:75) > 0)
        M = k - 51;
    elseif (sum(k == 76:102) > 0)
        M = k - 50;
    elseif (sum(k == 103:107) > 0)
        M = k - 49;
    end
else
    disp('HT have only 20 and 40 MHz BW!!!');
end;
end