function M = M_k_VHT(k,BW_channel)

if BW_channel == 20
    if (sum(k == 0:6) > 0)
        M = k + 1;
    elseif (sum(k == 7:19) > 0)
        M = k + 2;
    elseif (sum(k == 20:25) > 0)
        M = k + 3;
    elseif (sum(k == 26:31) > 0)
        M = k + 4;
    elseif (sum(k == 32:44) > 0)
        M = k + 5;
    elseif (sum(k == 45:51) > 0)
        M = k + 6;
    end
elseif  BW_channel == 40
    if (sum(k == 0:4) > 0)
        M = k + 1; % -53
    elseif (sum(k == 5:31) > 0)
        M = k + 2; % -25
    elseif (sum(k == 32:44) > 0)
        M = k + 3; % -11
    elseif (sum(k == 45:53) > 0)
        M = k + 4; % -1,0,1
    elseif (sum(k == 54:62) > 0)
        M = k + 7; % 11
    elseif (sum(k == 63:75) > 0)
        M = k + 8; % 25
    elseif (sum(k == 76:102) > 0)
        M = k + 9; % 53
    elseif (sum(k == 103:107) > 0)
        M = k + 10;
    end
elseif  BW_channel == 80
    if (sum(k == 0:18) > 0)
        M = k + 1; % <-103
    elseif (sum(k == 19:45) > 0)
        M = k + 2; % <-75
    elseif (sum(k == 46:80) > 0)
        M = k + 3; % <-39
    elseif (sum(k == 81:107) > 0)
        M = k + 4; % <-11
    elseif (sum(k == 108:116) > 0)
        M = k + 5; % <-1,0,1
    elseif (sum(k == 117:125) > 0)
        M = k + 8; % <-11
    elseif (sum(k == 126:152) > 0)
        M = k + 9; % <-39
    elseif (sum(k == 153:187) > 0)
        M = k + 10; % <-75
    elseif (sum(k == 188:214) > 0)
        M = k + 11; % <-103
    elseif (sum(k == 215:233) > 0)
        M = k + 12;
    end
elseif  BW_channel == 160
    if (sum(k == 0:18) > 0)
        M = k + 1;
    elseif (sum(k == 19:45) > 0)
        M = k + 2;
    elseif (sum(k == 46:80) > 0)
        M = k + 3;
    elseif (sum(k == 81:107) > 0)
        M = k + 4;
    elseif (sum(k == 108:116) > 0)
        M = k + 5;
    elseif (sum(k == 117:125) > 0)
        M = k + 8;
    elseif (sum(k == 126:152) > 0)
        M = k + 9;
    elseif (sum(k == 153:187) > 0)
        M = k + 10;
    elseif (sum(k == 188:214) > 0)
        M = k + 11;
    elseif (sum(k == 215:233) > 0)
        M = k + 12;
    elseif (sum(k == 234:252) > 0)
        M = k + 23;
    elseif (sum(k == 253:279) > 0)
        M = k + 24;
    elseif (sum(k == 280:314) > 0)
        M = k + 25;
    elseif (sum(k == 315:341) > 0)
        M = k + 26;
    elseif (sum(k == 342:350) > 0)
        M = k + 27;
    elseif (sum(k == 351:359) > 0)
        M = k + 30;
    elseif (sum(k == 360:386) > 0)
        M = k + 31;
    elseif (sum(k == 387:421) > 0)
        M = k + 32;
    elseif (sum(k == 422:448) > 0)
        M = k + 33;
    elseif (sum(k == 449:467) > 0)
        M = k + 34;
    end
else
    disp('HT have only 20, 40, 80 and 160 MHz BW!!!');
end;
end